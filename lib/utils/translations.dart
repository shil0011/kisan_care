class Translations {
  static String tr(String key, String lang) {
    // Quick lookup table: key -> {langContains -> translation}
    final _t = _translations[key];
    if (_t == null) return key;

    for (final entry in _t.entries) {
      if (lang.contains(entry.key)) return entry.value;
    }
    return key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'Today\'s Weather': {
      'Hindi': 'आज का मौसम', 'Marathi': 'आजचे हवामान', 'Telugu': 'నేటి వాతావరణం', 'Bengali': 'আজকের আবহাওয়া',
      'Tamil': 'இன்றைய வானிலை', 'Gujarati': 'આજનું હવામાન', 'Kannada': 'ಇಂದಿನ ಹವಾಮಾನ', 'Malayalam': 'ഇന്നത്തെ കാലാവസ്ഥ',
      'Punjabi': 'ਅੱਜ ਦਾ ਮੌਸਮ',
    },
    'Tomato Market Price': {
      'Hindi': 'टमाटर का मंडी भाव', 'Marathi': 'टोमॅटो बाजार भाव', 'Telugu': 'టమాటా మార్కెట్ ధర', 'Bengali': 'টমেটোর বাজারদর',
      'Tamil': 'தக்காளி சந்தை விலை', 'Gujarati': 'ટામેટા બજાર ભાવ', 'Kannada': 'ಟೊಮೆಟೊ ಮಾರುಕಟ್ಟೆ ಬೆಲೆ', 'Malayalam': 'തക്കാളി വിപണി വില',
      'Punjabi': 'ਟਮਾਟਰ ਦਾ ਮੰਡੀ ਭਾਅ',
    },
    'Check my crop': {
      'Hindi': 'मेरी फसल जाँचें', 'Marathi': 'माझे पीक तपासा', 'Telugu': 'నా పంటను తనిఖీ చేయండి', 'Bengali': 'আমার ফসল পরীক্ষা করুন',
      'Tamil': 'என் பயிரை சரிபார்க்க', 'Gujarati': 'મારો પાક તપાસો', 'Kannada': 'ನನ್ನ ಬೆಳೆ ಪರಿಶೀಲಿಸಿ', 'Malayalam': 'എന്റെ വിള പരിശോധിക്കുക',
      'Punjabi': 'ਮੇਰੀ ਫਸਲ ਦੀ ਜਾਂਚ ਕਰੋ',
    },
    'Weather update for': {
      'Hindi': 'मौसम अपडेट:', 'Marathi': 'हवामान अपडेट:', 'Telugu': 'వాతావరణ నవీకరణ:', 'Punjabi': 'ਮੌਸਮ ਅੱਪਡੇਟ:',
    },
    'Current temperature is': {
      'Hindi': 'वर्तमान तापमान है', 'Marathi': 'सध्याचे तापमान आहे', 'Telugu': 'ప్రస్తుత ఉష్ణోగ్రత', 'Punjabi': 'ਮੌਜੂదా ਤਾਪਮਾਨ ਹੈ',
    },
    'degrees Celsius': {
      'Hindi': 'डिग्री सेल्सियस', 'Marathi': 'अंश सेल्सिअस', 'Telugu': 'డిగ్రీల సెల్సియస్', 'Punjabi': 'ਡਿਗਰੀ ਸੈਲਸੀਅਸ',
    },
    'Conditions are': {
      'Hindi': 'स्थितियाँ हैं', 'Marathi': 'स्थिती आहे', 'Telugu': 'పరిస్థితులు', 'Punjabi': 'ਹਾਲਾਤ ਹਨ',
    },
    'Humidity is': {
      'Hindi': 'नमी है', 'Marathi': 'आर्द्रता आहे', 'Telugu': 'తేమ', 'Punjabi': 'ਨਮੀ ਹੈ',
    },
    'percent': {
      'Hindi': 'प्रतिशत', 'Marathi': 'टक्के', 'Telugu': 'శాతం', 'Punjabi': 'ਪ੍ਰਤੀਸ਼ਤ',
    },
    'Wind speed is': {
      'Hindi': 'हवा की गति है', 'Marathi': 'वाऱ्याचा वेग आहे', 'Telugu': 'గాలి వేగం', 'Punjabi': 'ਹਵਾ ਦੀ ਗਤੀ ਹੈ',
    },
    'kilometers per hour': {
      'Hindi': 'किलोमीटर प्रति घंटा', 'Marathi': 'किलोमीटर प्रति तास', 'Telugu': 'కిలోమీటర్ల/గంట', 'Punjabi': 'ਕਿਲੋਮੀਟਰ ਪ੍ਰਤੀ ਘੰਟਾ',
    },
    'Market price update for': {
      'Hindi': 'मंडी भाव अपडेट:', 'Marathi': 'बाजार भाव अपडेट:', 'Telugu': 'మార్కెట్ ధర నవీకరణ:', 'Punjabi': 'ਮਾਰਕੀਟ ਕੀਮਤ ਅੱਪਡੇਟ:',
    },
    'Average price is': {
      'Hindi': 'औसत भाव है', 'Marathi': 'सरासरी भाव आहे', 'Telugu': 'సగటు ధర', 'Punjabi': 'ਔਸਤ ਕੀਮਤ ਹੈ',
    },
    'Rupees': {
      'Hindi': 'रुपये', 'Marathi': 'रुपये', 'Telugu': 'రూపాయలు', 'Punjabi': 'ਰੁਪਏ',
    },
    'per quintal': {
      'Hindi': 'प्रति क्विंटल', 'Marathi': 'प्रति क्विंटल', 'Telugu': 'క్వింటాల్ కు', 'Punjabi': 'ਪ੍ਰਤੀ ਕੁਇੰਟਲ',
    },
    'Prices range from': {
      'Hindi': 'भाव की सीमा है', 'Marathi': 'किमतीची श्रेणी आहे', 'Telugu': 'ధరలు ఈ మధ్య ఉన్నాయి', 'Punjabi': 'ਕੀਮਤਾਂ ਦੀ ਰੇਂਜ ਹੈ',
    },
    'to': {
      'Hindi': 'से', 'Marathi': 'ते', 'Telugu': 'నుండి', 'Punjabi': 'ਤੋਂ',
    },
    'Nearby markets': {
      'Hindi': 'आसपास की मंडियां', 'Marathi': 'जवळच्या बाजारपेठा', 'Telugu': 'సమీప మార్కెట్లు', 'Punjabi': 'ਨੇੜਲੇ ਬਾਜ਼ਾਰ',
    },
    'at': {
      'Hindi': 'में', 'Marathi': 'मध्ये', 'Telugu': 'వద్ద', 'Punjabi': 'ਵਿੱਚ',
    },
    'Crop disease detection results': {
      'Hindi': 'फसल रोग पहचान परिणाम', 'Marathi': 'पीक रोग ओळख परिणाम', 'Telugu': 'పంట వ్యాధి గుర్తింపు ఫలితాలు', 'Punjabi': 'ਫਸਲ ਰੋਗ ਪਛਾਣ ਨਤੀਜੇ',
    },
    'Diagnosis': {
      'Hindi': 'निदान', 'Marathi': 'निदान', 'Telugu': 'రోగ నిర్ధారణ', 'Punjabi': 'ਨਿਦਾਨ',
    },
    'Confidence level': {
      'Hindi': 'विश्वास स्तर', 'Marathi': 'आत्मविश्वास पातळी', 'Telugu': 'విశ్వాస స్థాయి', 'Punjabi': 'ਭਰੋਸੇ ਦਾ ਪੱਧਰ',
    },
    'Description': {
      'Hindi': 'विवरण', 'Marathi': 'वर्णन', 'Telugu': 'వివరణ', 'Punjabi': 'ਵਰਣਨ',
    },
    'Recommended remedies': {
      'Hindi': 'सुझाए गए उपाय', 'Marathi': 'शिफारस केलेले उपाय', 'Telugu': 'సిఫార్సు చేయబడిన నివారణలు', 'Punjabi': 'ਸਿਫਾਰਸ਼ ਕੀਤੇ ਉਪਾਅ',
    },
    'Remedy': {
      'Hindi': 'उपाय', 'Marathi': 'उपाय', 'Telugu': 'నివారణ', 'Punjabi': 'ਉਪਾਅ',
    },
    'Here are': {
      'Hindi': 'ये रही', 'Marathi': 'येथे आहेत', 'Telugu': 'ఇవీ', 'Punjabi': 'ਇਹ ਹਨ',
    },
    'government schemes for farmers': {
      'Hindi': 'किसानों के लिए सरकारी योजनाएं', 'Marathi': 'शेतकऱ्यांसाठी सरकारी योजना', 'Telugu': 'రైతుల కోసం ప్రభుత్వ పథకాలు', 'Punjabi': 'ਕਿਸਾਨਾਂ ਲਈ ਸਰਕਾਰੀ ਸਕੀਮਾਂ',
    },
    'Weather Dashboard': {
      'Hindi': 'मौसम डैशबोर्ड', 'Marathi': 'हवामान डॅशबोर्ड', 'Telugu': 'వాతావరణ డ్యాష్‌బోర్డ్',
      'Bengali': 'আবহাওয়া ড্যাশবোর্ড', 'Tamil': 'வானிலை டாஷ்போர்டு', 'Gujarati': 'હવામાન ડેશબોર્ડ',
      'Kannada': 'ಹವಾಮಾನ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್', 'Odia': 'ପାଣିପାଗ ଡ୍ୟାସବୋର୍ଡ', 'Malayalam': 'കാലാവസ്ഥ ഡാഷ്ബോർഡ്',
      'Punjabi': 'ਮੌਸਮ ਡੈਸ਼ਬੋਰਡ', 'Assamese': 'বতৰৰ ডেশ্ববৰ্ড', 'Maithili': 'मौसम डैशबोर्ड', 'Nepali': 'मौसम ड्यासबोर्ड',
    },
    'Error fetching weather data': {
      'Hindi': 'मौसम डेटा लोड करने में त्रुटि', 'Marathi': 'हवामान डेटा लोड करताना त्रुटी',
      'Telugu': 'వాతావరణ డేటా లోడ్ చేయడంలో లోపం', 'Bengali': 'আবহাওয়ার ডেটা লোড করতে ত্রুটি',
      'Tamil': 'வானிலை தரவை ஏற்றுவதில் பிழை', 'Gujarati': 'હવામાન ડેટા મેળવવામાં ભૂલ',
      'Kannada': 'ಹವಾಮಾನ ಡೇಟಾವನ್ನು ಪಡೆಯುವಲ್ಲಿ ದೋಷ', 'Odia': 'ପାଣିପାଗ ତଥ୍ୟ ଆଣିବାରେ ତ୍ରୁଟି',
      'Malayalam': 'കാലാവസ്ഥ ഡാറ്റ ലോഡുചെയ്യുന്നതിൽ പിശക്', 'Punjabi': 'ਮੌਸਮ ਡਾਟਾ ਲਿਆਉਣ ਵਿੱਚ ਗਲਤੀ',
    },
    'Market Insights': {
      'Hindi': 'बाज़ार की जानकारी', 'Marathi': 'बाजार अंतर्दृष्टी', 'Telugu': 'మార్కెట్ అంతర్దృష్టులు',
      'Bengali': 'বাজারের অন্তর্দৃষ্টি', 'Tamil': 'சந்தை பகுப்பாய்வு', 'Gujarati': 'બજારની આંતરદૃષ્ટિ',
      'Kannada': 'ಮಾರುಕಟ್ಟೆ ಒಳನೋಟಗಳು', 'Odia': 'ବଜାର ସୂଚନା', 'Malayalam': 'വിപണി വിവരങ്ങൾ',
      'Punjabi': 'ਮਾਰਕੀਟ ਜਾਣਕਾਰੀ', 'Assamese': 'বজাৰৰ অন্তৰ্দৃষ্টি', 'Maithili': 'बजार जानकारी', 'Nepali': 'बजार जानकारी',
    },
    'Market Insight': {
      'Hindi': 'बाज़ार की जानकारी', 'Marathi': 'बाजार अंतर्दृष्टी', 'Telugu': 'మార్కెట్ అంతర్దృష్టి',
      'Bengali': 'বাজারের অন্তর্দৃষ্টি', 'Tamil': 'சந்தை பகுப்பாய்வு', 'Gujarati': 'બજારની આંતરદૃષ્ટિ',
    },
    'Search crop prices...': {
      'Hindi': 'फसल की कीमतें खोजें...', 'Marathi': 'पिकांच्या किमती शोधा...', 'Telugu': 'పంట ధరలను శోధించండి...',
      'Bengali': 'ফসলের দাম অনুসন্ধান করুন...', 'Tamil': 'பயிர் விலைகளை தேடு...', 'Gujarati': 'પાકના ભાવ શોધો...',
      'Kannada': 'ಬೆಳೆ ಬೆಲೆಗಳನ್ನು ಹುಡುಕಿ...', 'Odia': 'ଫସଲ ମୂଲ୍ୟ ଖୋଜନ୍ତୁ...', 'Malayalam': 'വിളകളുടെ വില തിരയുക...',
      'Punjabi': 'ਫਸਲ ਦੀਆਂ ਕੀਮਤਾਂ ਖੋਜੋ...',
    },
    'No data found': {
      'Hindi': 'कोई डेटा नहीं मिला', 'Marathi': 'कोणताही डेटा आढळला नाही', 'Telugu': 'ఏ డేటా కనుగొనబడలేదు',
      'Bengali': 'তথ্য পাওয়া যায়নি', 'Tamil': 'தரவு கிடைக்கவில்லை', 'Gujarati': 'કોઈ ડેટા મળ્યો નથી',
      'Kannada': 'ಯಾವುದೇ ಡೇಟಾ ಕಂಡುಬಂದಿಲ್ಲ', 'Odia': 'କୌଣସି ତଥ୍ୟ ମିଳିଲା ନାହିଁ', 'Malayalam': 'ഡാറ്റ ലഭ്യമല്ല',
      'Punjabi': 'ਕੋਈ ਡਾਟਾ ਨਹੀਂ ਮਿਲਿਆ',
    },
    'Government Schemes': {
      'Hindi': 'सरकारी योजनाएं', 'Marathi': 'सरकारी योजना', 'Telugu': 'ప్రభుత్వ పథకాలు',
      'Bengali': 'সরকারি প্রকল্প', 'Tamil': 'அரசு திட்டங்கள்', 'Gujarati': 'સરકારી યોજનાઓ',
      'Kannada': 'ಸರ್ಕಾರಿ ಯೋಜನೆಗಳು', 'Odia': 'ସରକାରୀ ଯୋଜନା', 'Malayalam': 'സർക്കാർ പദ്ധതികൾ',
      'Punjabi': 'ਸਰਕਾਰੀ ਸਕੀਮਾਂ', 'Assamese': 'চৰকাৰী আঁচনিসমূহ', 'Maithili': 'सरकारी योजना', 'Nepali': 'सरकारी योजनाहरू',
    },
    'No schemes loaded.': {
      'Hindi': 'कोई योजना लोड नहीं हुई।', 'Marathi': 'कोणत्याही योजना लोड केल्या नाहीत.',
      'Telugu': 'పథకాలు లోడ్ కాలేదు.', 'Bengali': 'কোনো প্রকল্প লোড হয়নি।',
      'Tamil': 'எந்த திட்டங்களும் ஏற்றப்படவில்லை.', 'Gujarati': 'કોઈ યોજના લોડ થઈ નથી.',
      'Kannada': 'ಯಾವುದೇ ಯೋಜನೆಗಳು ಲೋಡ್ ಆಗಿಲ್ಲ.', 'Odia': 'କୌଣସି ଯୋଜନା ଲୋଡ୍ ହୋଇନାହିଁ |',
      'Malayalam': 'പദ്ധതികളൊന്നും ലോഡുചെയ്തില്ല.', 'Punjabi': 'ਕੋਈ ਸਕੀਮ ਲੋਡ ਨਹੀਂ ਹੋਈ।',
    },
    // Bottom nav labels
    'Assistant': {
      'Hindi': 'सहायक', 'Marathi': 'सहाय्यक', 'Telugu': 'సహాయకుడు', 'Bengali': 'সহায়ক',
      'Tamil': 'உதவியாளர்', 'Gujarati': 'સહાયક', 'Kannada': 'ಸಹಾಯಕ', 'Odia': 'ସହାୟକ',
      'Malayalam': 'സഹായി', 'Punjabi': 'ਸਹਾਇਕ',
    },
    'Weather': {
      'Hindi': 'मौसम', 'Marathi': 'हवामान', 'Telugu': 'వాతావరణం', 'Bengali': 'আবহাওয়া',
      'Tamil': 'வானிலை', 'Gujarati': 'હવામાન', 'Kannada': 'ಹವಾಮಾನ', 'Odia': 'ପାଣିପାଗ',
      'Malayalam': 'കാലാവസ്ഥ', 'Punjabi': 'ਮੌਸਮ',
    },
    'Market': {
      'Hindi': 'बाज़ार', 'Marathi': 'बाजार', 'Telugu': 'మార్కెట్', 'Bengali': 'বাজার',
      'Tamil': 'சந்தை', 'Gujarati': 'બજાર', 'Kannada': 'ಮಾರುಕಟ್ಟೆ', 'Odia': 'ବଜାର',
      'Malayalam': 'വിപണി', 'Punjabi': 'ਮਾਰਕੀਟ',
    },
    'Crop Health': {
      'Hindi': 'फसल स्वास्थ्य', 'Marathi': 'पीक आरोग्य', 'Telugu': 'పంట ఆరోగ్యం', 'Bengali': 'ফসলের স্বাস্থ্য',
      'Tamil': 'பயிர் ஆரோக்கியம்', 'Gujarati': 'પાક સ્વાસ્થ્ય', 'Kannada': 'ಬೆಳೆ ಆರೋಗ್ಯ', 'Odia': 'ଫସଲ ସ୍ୱାସ୍ଥ୍ୟ',
      'Malayalam': 'വിള ആരോഗ്യം', 'Punjabi': 'ਫਸਲ ਸਿਹਤ',
    },
    'Schemes': {
      'Hindi': 'योजनाएं', 'Marathi': 'योजना', 'Telugu': 'పథకాలు', 'Bengali': 'প্রকল্প',
      'Tamil': 'திட்டங்கள்', 'Gujarati': 'યોજનાઓ', 'Kannada': 'ಯೋಜನೆಗಳು', 'Odia': 'ଯୋଜନା',
      'Malayalam': 'പദ്ധതികൾ', 'Punjabi': 'ਸਕੀਮਾਂ',
    },
    'View all crops': {
      'Hindi': 'सभी फसलें देखें', 'Marathi': 'सर्व पिके पहा', 'Telugu': 'అన్ని పంటలు చూడండి',
      'Bengali': 'সব ফসল দেখুন', 'Tamil': 'அனைத்து பயிர்களையும் காண்க',
    },
    'Language': {
      'Hindi': 'भाषा', 'Marathi': 'भाषा', 'Telugu': 'భాష', 'Bengali': 'ভাষা',
      'Tamil': 'மொழி', 'Gujarati': 'ભાષા', 'Kannada': 'ಭಾಷೆ', 'Odia': 'ଭାଷା',
      'Malayalam': 'ഭാഷ', 'Punjabi': 'ਭਾਸ਼ਾ',
    },
    'Crop Disease Detection': {
      'Hindi': 'फसल रोग पहचान', 'Marathi': 'पीक रोग ओळख', 'Telugu': 'పంట వ్యాధి గుర్తింపు',
      'Bengali': 'ফসলের রোগ নির্ণয়', 'Tamil': 'பயிர் நோய் கண்டறிதல்', 'Gujarati': 'પાક રોગની ઓળખ',
      'Kannada': 'ಬೆಳೆ ರೋಗ ಪತ್ತೆಹಚ್ಚುವಿಕೆ', 'Odia': 'ଫସଲ ରୋଗ ନିର୍ଣ୍ଣୟ', 'Malayalam': 'വിള രോഗ നിർണയം',
    },
    'Upload a photo of your affected crop leaf to diagnose the issue immediately.': {
      'Hindi': 'समस्या का तुरंत निदान करने के लिए अपनी प्रभावित फसल की पत्ती की एक तस्वीर अपलोड करें।',
      'Marathi': 'समस्येचे त्वरित निदान करण्यासाठी तुमच्या प्रभावित पिकाच्या पानाचा फोटो अपलोड करा.',
      'Telugu': 'సమస్యను వెంటనే నిర్ధారించడానికి ప్రభావితమైన మీ పంట ఆకు ఫోటోను అప్‌లోడ్ చేయండి.',
    },
    'Upload Image': {
      'Hindi': 'छवि अपलोड करें', 'Marathi': 'इमेज अपलोड करा', 'Telugu': 'చిత్రాన్ని అప్‌లోడ్ చేయండి',
      'Bengali': 'ছবি আপলোড করুন', 'Tamil': 'படம் பதிவிறக்கம்',
    },
    'Scan Another': {
      'Hindi': 'दूसरा स्कैन करें', 'Marathi': 'दुसरे स्कॅन करा', 'Telugu': 'మరొకటి స్కాన్ చేయండి',
      'Bengali': 'অন্যটি স্ক্যান করুন', 'Tamil': 'மற்றொன்றை ஸ்கேன் செய்யவும்',
    },
    'Camera': {
      'Hindi': 'कैमरा', 'Marathi': 'कॅमेरा', 'Telugu': 'కెమెరా',
    },
    'Gallery': {
      'Hindi': 'गैलरी', 'Marathi': 'गॅलरी', 'Telugu': 'గ్యాలరీ',
    },
    'Check Market Prices': {
      'Hindi': 'बाजार भाव जांचें', 'Marathi': 'बाजारभाव तपासा', 'Telugu': 'మార్కెట్ ధరలను నవీకరించండి',
    },
    'Select a crop to view real-time prices near you': {
      'Hindi': 'अपने आस-पास वास्तविक समय की कीमतें देखने के लिए एक फसल चुनें',
      'Marathi': 'तुमच्या जवळील रिअल-टाइम किमती पाहण्यासाठी पीक निवडा',
    },
    // Crop names
    'Tomato': {
      'Hindi': 'टमाटर', 'Marathi': 'टोमॅटो', 'Telugu': 'టమాటా', 'Bengali': 'টমেটো',
      'Tamil': 'தக்காளி', 'Gujarati': 'ટામેટાં', 'Kannada': 'ಟೊಮೇಟೊ', 'Malayalam': 'തക്കാളി', 'Punjabi': 'ਟਮਾਟਰ',
    },
    'Potato': {
      'Hindi': 'आलू', 'Marathi': 'बटाटा', 'Telugu': 'బంగాళాదుంప', 'Bengali': 'আলু',
      'Tamil': 'உருளைக்கிழங்கு', 'Gujarati': 'બટાકા', 'Kannada': 'ಆಲೂಗಡ್ಡೆ', 'Malayalam': 'ഉരുളക്കിഴങ്ങ്', 'Punjabi': 'ਆਲੂ',
    },
    'Onion': {
      'Hindi': 'प्याज', 'Marathi': 'कांदा', 'Telugu': 'ఉల్లిపాయ', 'Bengali': 'পেঁয়াজ',
      'Tamil': 'வெங்காயம்', 'Gujarati': 'ડુંગળી', 'Kannada': 'ಈರುಳ್ಳಿ', 'Malayalam': 'ഉള്ളി', 'Punjabi': 'ਪਿਆਜ਼',
    },
    'Wheat': {
      'Hindi': 'गेहूं', 'Marathi': 'गहू', 'Telugu': 'గోధుమ', 'Bengali': 'গম',
      'Tamil': 'கோதுமை', 'Gujarati': 'ઘઉં', 'Kannada': 'ಗೋಧಿ', 'Malayalam': 'ഗോതമ്പ്', 'Punjabi': 'ਕਣਕ',
    },
    'Rice': {
      'Hindi': 'चावल', 'Marathi': 'तांदूळ', 'Telugu': 'బియ్యం', 'Bengali': 'চাল',
      'Tamil': 'அரிசி', 'Gujarati': 'ચોખા', 'Kannada': 'ಅಕ್ಕಿ', 'Malayalam': 'അരി', 'Punjabi': 'ਚੌਲ',
    },
    'Cotton': {
      'Hindi': 'कपास', 'Marathi': 'कापूस', 'Telugu': 'పత్తి', 'Bengali': 'তুলা',
      'Tamil': 'பருத்தி', 'Gujarati': 'કપાસ', 'Kannada': 'ಹತ್ತಿ', 'Malayalam': 'പരുത്തി', 'Punjabi': 'ਕਪਾਹ',
    },
    'Soybean': {
      'Hindi': 'सोयाबीन', 'Marathi': 'सोयाबीन', 'Telugu': 'సోయాబీన్', 'Bengali': 'সয়াবিন',
      'Tamil': 'சோயா', 'Gujarati': 'સોયાબીન', 'Kannada': 'ಸೋಯಾಬೀನ್', 'Malayalam': 'സോയാബീൻ', 'Punjabi': 'ਸੋਇਆਬੀਨ',
    },
    'Maize': {
      'Hindi': 'मक्का', 'Marathi': 'मका', 'Telugu': 'మొక్కజొన్న', 'Bengali': 'ভুট্টা',
      'Tamil': 'சோளம்', 'Gujarati': 'મકાઈ', 'Kannada': 'ಜೋಳ', 'Malayalam': 'ചോളം', 'Punjabi': 'ਮੱਕੀ',
    },
    'Chilli': {
      'Hindi': 'मिर्च', 'Marathi': 'मिरची', 'Telugu': 'మిరపకాయ', 'Bengali': 'মরিচ',
      'Tamil': 'மிளகாய்', 'Gujarati': 'મરચું', 'Kannada': 'ಮೆಣಸಿನಕಾಯಿ', 'Malayalam': 'മുളക്', 'Punjabi': 'ਮਿਰਚ',
    },
    'Sugarcane': {
      'Hindi': 'गन्ना', 'Marathi': 'ऊस', 'Telugu': 'చెరకు', 'Bengali': 'আখ',
      'Tamil': 'கரும்பு', 'Gujarati': 'શેરડી', 'Kannada': 'ಕಬ್ಬು', 'Malayalam': 'കരിമ്പ്', 'Punjabi': 'ਗੰਨਾ',
    },
    'Banana': {
      'Hindi': 'केला', 'Marathi': 'केळी', 'Telugu': 'అరటి', 'Bengali': 'কলা',
      'Tamil': 'வாழைப்பழம்', 'Gujarati': 'કેળું', 'Kannada': 'ಬಾಳೆಹಣ್ಣು', 'Malayalam': 'വാഴപ്പഴം', 'Punjabi': 'ਕੇਲਾ',
    },
    'Turmeric': {
      'Hindi': 'हल्दी', 'Marathi': 'हळद', 'Telugu': 'పసుపు', 'Bengali': 'হলুদ',
      'Tamil': 'மஞ்சள்', 'Gujarati': 'હળદર', 'Kannada': 'ಅರಿಶಿನ', 'Malayalam': 'മഞ്ഞൾ', 'Punjabi': 'ਹਲਦੀ',
    },
    'Groundnut': {
      'Hindi': 'मूंगफली', 'Marathi': 'शेंगदाणा', 'Telugu': 'వేరుశెనగ', 'Bengali': 'চিনাবাদাম',
      'Tamil': 'நிலக்கடலை', 'Gujarati': 'મગફળી', 'Kannada': 'ಕಡಲೆಕಾಯಿ', 'Malayalam': 'നിലക്കടല', 'Punjabi': 'ਮੂੰਗਫਲੀ',
    },
    'Mustard': {
      'Hindi': 'सरसों', 'Marathi': 'मोहरी', 'Telugu': 'ఆవాలు', 'Bengali': 'সরিষা',
      'Tamil': 'கடுகு', 'Gujarati': 'સરસવ', 'Kannada': 'ಸಾಸಿವೆ', 'Malayalam': 'കടുക്', 'Punjabi': 'ਸਰ੍ਹੋਂ',
    },
    'Gram': {
      'Hindi': 'चना', 'Marathi': 'हरभरा', 'Telugu': 'శనగలు', 'Bengali': 'ছোলা',
      'Tamil': 'கடலை', 'Gujarati': 'ચણા', 'Kannada': 'ಕಡಲೆ', 'Malayalam': 'കടല', 'Punjabi': 'ਚਣਾ',
    },
    'Coriander': {
      'Hindi': 'धनिया', 'Marathi': 'कोथिंबीर', 'Telugu': 'కొత్తిమీర', 'Bengali': 'ধনে',
      'Tamil': 'கொத்தமல்லி', 'Gujarati': 'ધાણા', 'Kannada': 'ಕೊತ್ತಂಬರಿ', 'Malayalam': 'മല്ലി', 'Punjabi': 'ਧਨੀਆ',
    },
  };
}
