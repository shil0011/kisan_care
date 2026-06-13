# KisanCare - AI-Powered Farmer's Assistant 🌾

KisanCare is a cutting-edge Flutter application designed to empower farmers with real-time insights, multi-language support, and intelligent AI-driven modules for weather, market prices, and crop health.

## 🚀 Key Features

- **Multi-Language Support**: Fully localized interface and AI responses supporting 14+ Indian languages (Hindi, Telugu, Punjabi, Marathi, etc.).
- **AI-Powered Diagnostics**: Advanced crop disease detection using Gemini Vision AI.
- **Real-time Weather Dashboard**: Detailed forecasts and hyper-local weather alerts for the farmer's specific location.
- **Market Price Tracker**: Live mandi prices and market trends tailored to local crop preferences.
- **Intelligent Assistant**: A voice-enabled AI companion that provides voice summaries and automated advice for daily farming tasks.
- **Government Schemes**: Curated and relevant government schemes for farmers based on their location and crops.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Backend/AI**: [Google Gemini AI (Generative AI)](https://deepmind.google/technologies/gemini/), [Firebase (Auth, Firestore, Functions, Storage)](https://firebase.google.com/)
- **Maps & Location**: [Geolocator & Geocoding](https://pub.dev/packages/geolocator)
- **Voice Support**: [Speech to Text](https://pub.dev/packages/speech_to_text), [Flutter TTS](https://pub.dev/packages/flutter_tts)

## 📦 Setting Up the Project

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Mainakgit0/kisancare.git
   cd kisancare
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Create a Firebase project and add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to their respective directories.
   - Enable Authentication (Email/Google), Firestore, and Storage.

4. **Environment Variables**:
   Update your API keys and configuration in the respective service files or use a `.env` file for:
   - Google Generative AI API Key
   - OpenWeather API Key (if applicable)

5. **Run the Application**:
   ```bash
   flutter run
   ```

## 📸 Screenshots

*(Add screenshots here)*

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
