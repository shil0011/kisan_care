const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();

// Initialize Gemini AI
// TODO: Set your Gemini API key in Firebase environment: firebase functions:config:set gemini.api_key="YOUR_KEY"
const genAI = new GoogleGenerativeAI(functions.config().gemini?.api_key || 'YOUR_GEMINI_API_KEY');

/**
 * Main Query Handler - Orchestrates AI agents based on intent
 */
exports.handleQuery = functions.https.onCall(async (data, context) => {
  try {
    const { userId, queryType, content, imageUrl } = data;

    // Validate input
    if (!userId || !queryType || !content) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    // Log the query to Firestore
    await db.collection('users').doc(userId).collection('queryLogs').add({
      queryType,
      content,
      imageUrl: imageUrl || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    let response;

    if (queryType === 'image') {
      // Disease Detection Agent
      response = await handleDiseaseDetection(imageUrl, content);
    } else {
      // Classify intent for text queries
      const intent = await classifyIntent(content);
      
      switch (intent) {
        case 'weather':
          response = await handleWeatherQuery(content);
          break;
        case 'market_price':
          response = await handleMarketPriceQuery(content);
          break;
        case 'govt_scheme':
          response = await handleGovtSchemeQuery(content);
          break;
        default:
          response = await handleGeneralChat(content);
      }
    }

    // Log the response
    await db.collection('users').doc(userId).collection('responseLogs').add({
      query: content,
      response,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return response;
  } catch (error) {
    console.error('Error in handleQuery:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Classify user intent using Gemini
 */
async function classifyIntent(query) {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
    
    const prompt = `Classify the following farmer's query into ONE of these categories: weather, market_price, govt_scheme, general_chat.
    
Query: "${query}"

Rules:
- Use "weather" for queries about weather, rain, temperature, climate
- Use "market_price" for queries about crop prices, selling, market rates
- Use "govt_scheme" for queries about government schemes, subsidies, loans, insurance
- Use "general_chat" for all other queries

Respond with ONLY the category name, nothing else.`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const intent = response.text().trim().toLowerCase();
    
    return intent;
  } catch (error) {
    console.error('Intent classification error:', error);
    return 'general_chat';
  }
}

/**
 * Weather Query Handler
 */
async function handleWeatherQuery(query) {
  try {
    // TODO: Integrate with IMD Weather API
    // For now, return mock data
    // const location = extractLocationFromQuery(query);
    // const weatherData = await fetchIMDWeather(location);
    
    return {
      type: 'weather',
      data: {
        location: 'Pune, Maharashtra',
        currentTemp: '28',
        summary: 'Partly cloudy with a chance of showers in the afternoon. Good conditions for most crops.',
        forecast: [
          { day: 'Mon', temp: '29', condition: 'sunny' },
          { day: 'Tue', temp: '30', condition: 'cloudy' },
          { day: 'Wed', temp: '27', condition: 'rainy' },
        ],
      },
    };
  } catch (error) {
    console.error('Weather query error:', error);
    return { type: 'text', data: { response: 'Sorry, I could not fetch weather information.' } };
  }
}

/**
 * Market Price Query Handler with Gemini Analysis
 */
async function handleMarketPriceQuery(query) {
  try {
    // Extract crop name from query
    const cropName = await extractCropName(query);
    
    // TODO: Fetch real data from OGD API
    // const priceData = await fetchOGDMarketData(cropName);
    
    // Mock data for demonstration
    const mockPriceData = {
      crop: cropName || 'Tomato',
      currentPrice: '₹2,400 / quintal',
      priceHistory: [2100, 2200, 2300, 2400],
      lastWeekPrice: 2286,
    };

    // Use Gemini for predictive analysis
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
    const analysisPrompt = `You are an agricultural market analyst. Analyze this market data:
    
Crop: ${mockPriceData.crop}
Current Price: ${mockPriceData.currentPrice}
Last Week Average: ₹${mockPriceData.lastWeekPrice} / quintal
Price Trend: ${mockPriceData.priceHistory.join(', ')}

Provide:
1. Brief trend analysis (1-2 sentences)
2. Recommendation for farmers (sell now, hold, or wait)

Keep response clear and actionable for farmers.`;

    const result = await model.generateContent(analysisPrompt);
    const response = await result.response;
    const analysis = response.text();
    
    const trendPercent = ((mockPriceData.currentPrice.match(/\d+/)[0] - mockPriceData.lastWeekPrice) / mockPriceData.lastWeekPrice * 100).toFixed(1);
    
    return {
      type: 'market_price',
      data: {
        cropName: mockPriceData.crop,
        currentPrice: mockPriceData.currentPrice,
        trend: `Up ${trendPercent}% from last week`,
        trendDirection: trendPercent > 0 ? 'up' : 'down',
        trendPercent: `${Math.abs(trendPercent)}%`,
        analysis,
      },
    };
  } catch (error) {
    console.error('Market price query error:', error);
    return { type: 'text', data: { response: 'Sorry, I could not fetch market price information.' } };
  }
}

/**
 * Government Scheme Query Handler
 */
async function handleGovtSchemeQuery(query) {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
    
    // TODO: Implement RAG with government scheme database
    const prompt = `You are an expert on Indian agricultural government schemes. 
    
Farmer's query: "${query}"

Provide information about the most relevant government scheme. Include:
1. Scheme name
2. Brief summary (2-3 sentences)
3. Key benefits (2-3 points)
4. Basic eligibility criteria

Format your response as JSON with keys: title, summary, benefits (array), eligibility.
Respond ONLY with valid JSON, no other text.`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    let schemeData;
    
    try {
      schemeData = JSON.parse(response.text());
    } catch {
      // Fallback if JSON parsing fails
      schemeData = {
        title: 'PM-KISAN Scheme',
        summary: 'Direct income support to farmers. ₹6000 per year in three installments.',
        benefits: ['Direct bank transfer', 'No middlemen', 'All landholding farmers eligible'],
        eligibility: 'All landholding farmer families',
      };
    }
    
    return {
      type: 'scheme',
      data: schemeData,
    };
  } catch (error) {
    console.error('Govt scheme query error:', error);
    return { type: 'text', data: { response: 'Sorry, I could not fetch scheme information.' } };
  }
}

/**
 * Disease Detection Handler (Vision Model)
 */
async function handleDiseaseDetection(imageUrl, query) {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-pro-vision' });
    
    // Fetch image from URL
    const imageResponse = await axios.get(imageUrl, { responseType: 'arraybuffer' });
    const imageBase64 = Buffer.from(imageResponse.data).toString('base64');
    
    const prompt = `You are an expert plant pathologist. Analyze this crop image and identify any diseases.

Provide:
1. Disease name (or "Healthy" if no disease)
2. Confidence level (0-100)
3. Brief description
4. 2-3 recommended remedies

Format as JSON: { "diagnosis": "name", "confidence": number, "description": "text", "remedies": ["remedy1", "remedy2"] }
Respond ONLY with valid JSON.`;

    const result = await model.generateContent([
      prompt,
      { inlineData: { mimeType: 'image/jpeg', data: imageBase64 } },
    ]);
    
    const response = await result.response;
    let diseaseData;
    
    try {
      diseaseData = JSON.parse(response.text());
    } catch {
      // Fallback
      diseaseData = {
        diagnosis: 'Unable to analyze',
        confidence: 50,
        description: 'Image quality may be low. Please try with a clearer image.',
        remedies: ['Retake photo in better lighting', 'Consult local agricultural expert'],
      };
    }
    
    return {
      type: 'disease',
      data: diseaseData,
    };
  } catch (error) {
    console.error('Disease detection error:', error);
    return {
      type: 'text',
      data: { response: 'Sorry, I could not analyze the image. Please try again.' },
    };
  }
}

/**
 * General Chat Handler
 */
async function handleGeneralChat(query) {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
    
    const prompt = `You are KisanCare, an AI assistant for Indian farmers. 
    
Farmer's query: "${query}"

Provide a helpful, clear, and concise response. Keep it practical and farmer-friendly.
Limit response to 3-4 sentences.`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    
    return {
      type: 'text',
      data: { response: response.text() },
    };
  } catch (error) {
    console.error('General chat error:', error);
    return {
      type: 'text',
      data: { response: 'I apologize, but I encountered an error. Please try rephrasing your question.' },
    };
  }
}

/**
 * Helper: Extract crop name from query
 */
async function extractCropName(query) {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
    const prompt = `Extract ONLY the crop name from this query: "${query}". 
    If no crop is mentioned, respond with "Tomato". Respond with ONLY the crop name, nothing else.`;
    
    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text().trim();
  } catch {
    return 'Tomato';
  }
}
