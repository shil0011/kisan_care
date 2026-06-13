import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messageCount,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'New Chat',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
      messageCount: data['messageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'messageCount': messageCount,
    };
  }

  ChatSession copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    int? messageCount,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}
