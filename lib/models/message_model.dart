import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, weather, marketPrice, disease, scheme }

class ChatMessage {
  final String id;
  final String userId;
  final String sessionId;
  final bool isUser;
  final MessageType type;
  final String? textContent;
  final String? imageUrl;
  final Map<String, dynamic>? structuredData;
  final DateTime timestamp;
  final String? language;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.isUser,
    required this.type,
    this.textContent,
    this.imageUrl,
    this.structuredData,
    this.language,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      sessionId: data['sessionId'] ?? 'default',
      isUser: data['isUser'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      textContent: data['textContent'],
      imageUrl: data['imageUrl'],
      structuredData: data['structuredData'] != null ? Map<String, dynamic>.from(data['structuredData']) : null,
      language: data['language'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'isUser': isUser,
      'type': type.toString().split('.').last,
      'textContent': textContent,
      'imageUrl': imageUrl,
      'structuredData': structuredData != null ? Map<String, dynamic>.from(structuredData!) : null,
      'language': language,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.userText(String userId, String sessionId, String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      sessionId: sessionId,
      isUser: true,
      type: MessageType.text,
      textContent: text,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.userImage(String userId, String sessionId, String imageUrl) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      sessionId: sessionId,
      isUser: true,
      type: MessageType.image,
      imageUrl: imageUrl,
      textContent: 'Image uploaded',
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.aiResponse(
    String userId,
    String sessionId,
    MessageType type,
    String textContent, {
    Map<String, dynamic>? data,
    String? language,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      sessionId: sessionId,
      isUser: false,
      type: type,
      textContent: textContent,
      structuredData: data,
      language: language,
      timestamp: DateTime.now(),
    );
  }
}
