class UserPreferences {
  final String userId;
  final String language;
  final DateTime updatedAt;

  UserPreferences({
    required this.userId,
    required this.language,
    required this.updatedAt,
  });

  factory UserPreferences.fromFirestore(Map<String, dynamic> data) {
    return UserPreferences(
      userId: data['userId'] ?? '',
      language: data['language'] ?? 'English',
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'language': language,
      'updatedAt': updatedAt,
    };
  }
}

class SupportedLanguages {
  static const List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'हिन्दी (Hindi)', 'code': 'hi'},
    {'name': 'বাংলা (Bengali)', 'code': 'bn'},
    {'name': 'తెలుగు (Telugu)', 'code': 'te'},
    {'name': 'मराठी (Marathi)', 'code': 'mr'},
    {'name': 'தமிழ் (Tamil)', 'code': 'ta'},
    {'name': 'ગુજરાતી (Gujarati)', 'code': 'gu'},
    {'name': 'ಕನ್ನಡ (Kannada)', 'code': 'kn'},
    {'name': 'ଓଡ଼ିଆ (Odia)', 'code': 'or'},
    {'name': 'മലയാളം (Malayalam)', 'code': 'ml'},
    {'name': 'ਪੰਜਾਬੀ (Punjabi)', 'code': 'pa'},
    {'name': 'অসমীয়া (Assamese)', 'code': 'as'},
    {'name': 'मैथिली (Maithili)', 'code': 'mai'},
    {'name': 'ಸಂಸ್ಕೃತ (Sanskrit)', 'code': 'sa'},
    {'name': 'नेपाली (Nepali)', 'code': 'ne'},
  ];
}
