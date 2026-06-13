import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_session_model.dart';
import '../models/message_model.dart';

class ChatSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat session
  Future<ChatSession> createNewSession(String userId) async {
    final now = DateTime.now();
    final sessionData = {
      'userId': userId,
      'title': 'New Chat',
      'createdAt': Timestamp.fromDate(now),
      'lastMessageAt': Timestamp.fromDate(now),
      'messageCount': 0,
    };

    final docRef = await _firestore.collection('chat_sessions').add(sessionData);
    
    return ChatSession(
      id: docRef.id,
      userId: userId,
      title: 'New Chat',
      createdAt: now,
      lastMessageAt: now,
      messageCount: 0,
    );
  }

  // Get all chat sessions for a user
  Stream<List<ChatSession>> getUserSessions(String userId) {
    return _firestore
        .collection('chat_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSession.fromFirestore(doc))
            .toList());
  }

  // Update session when a new message is added
  Future<void> updateSessionOnNewMessage(String sessionId, String firstUserMessage) async {
    final sessionRef = _firestore.collection('chat_sessions').doc(sessionId);
    
    // Get current session data
    final sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) return;
    
    final currentData = sessionDoc.data()!;
    final currentMessageCount = currentData['messageCount'] ?? 0;
    
    // Generate title from first user message if it's still "New Chat"
    String title = currentData['title'] ?? 'New Chat';
    if (title == 'New Chat' && firstUserMessage.isNotEmpty) {
      title = _generateTitleFromMessage(firstUserMessage);
    }
    
    await sessionRef.update({
      'title': title,
      'lastMessageAt': Timestamp.fromDate(DateTime.now()),
      'messageCount': currentMessageCount + 1,
    });
  }

  // Generate a title from the first message
  String _generateTitleFromMessage(String message) {
    // Clean and truncate the message for title
    String title = message.trim();
    
    // Remove common prefixes
    final prefixes = ['tell me', 'what is', 'how to', 'can you', 'please'];
    for (final prefix in prefixes) {
      if (title.toLowerCase().startsWith(prefix)) {
        title = title.substring(prefix.length).trim();
        break;
      }
    }
    
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    // Truncate to reasonable length
    if (title.length > 30) {
      title = '${title.substring(0, 30)}...';
    }
    
    return title.isEmpty ? 'New Chat' : title;
  }

  // Delete a chat session and all its messages
  Future<void> deleteSession(String sessionId) async {
    final batch = _firestore.batch();
    
    // Delete all messages in the session
    final messagesQuery = await _firestore
        .collection('messages')
        .where('sessionId', isEqualTo: sessionId)
        .get();
    
    for (final doc in messagesQuery.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete the session
    batch.delete(_firestore.collection('chat_sessions').doc(sessionId));
    
    await batch.commit();
  }

  // Get a specific session
  Future<ChatSession?> getSession(String sessionId) async {
    final doc = await _firestore.collection('chat_sessions').doc(sessionId).get();
    if (!doc.exists) return null;
    return ChatSession.fromFirestore(doc);
  }

  // Update session title manually
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    await _firestore.collection('chat_sessions').doc(sessionId).update({
      'title': newTitle,
    });
  }
}
