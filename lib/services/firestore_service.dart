import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get chat history stream for a specific session
  Stream<List<ChatMessage>> getChatHistory(String sessionId, {int limit = 50}) {
    return _firestore
        .collection('messages')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          print('📚 [Firestore] Loading ${snapshot.docs.length} messages for session: $sessionId');
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final message = ChatMessage.fromFirestore(doc);
            
            // Debug structured data retrieval
            if (data['type'] == 'marketPrice' || message.structuredData != null) {
              print('   • Retrieved message ${doc.id}: type=${data['type']}, hasStructuredData=${data['structuredData'] != null}');
              if (data['structuredData'] != null) {
                print('     • Raw structuredData: ${data['structuredData']}');
                print('     • Parsed structuredData: ${message.structuredData}');
              }
            }
            
            return message;
          }).toList();
        });
  }

  // Get all messages for a user (across all sessions) - for migration/backup
  Stream<List<ChatMessage>> getAllUserMessages(String userId, {int limit = 100}) {
    return _firestore
        .collection('messages')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Save a message to the messages collection
  Future<void> saveMessage(ChatMessage message) async {
    try {
      final data = message.toFirestore();
      print('💾 [Firestore] Saving message:');
      print('   • Message ID: ${message.id}');
      print('   • Message type: ${message.type}');
      print('   • Has structuredData: ${message.structuredData != null}');
      if (message.structuredData != null) {
        print('   • StructuredData keys: ${message.structuredData!.keys.toList()}');
        print('   • StructuredData content: ${message.structuredData}');
      }
      print('   • Firestore data keys: ${data.keys.toList()}');
      print('   • Firestore structuredData: ${data['structuredData']}');
      
      await _firestore.collection('messages').doc(message.id).set(data);
      print('   ✅ Message saved successfully to Firestore');
    } catch (e) {
      print('   Failed to save message: $e');
      throw Exception('Failed to save message: $e');
    }
  }

  // Clear all messages in a specific session
  Future<void> clearSession(String sessionId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('messages')
        .where('sessionId', isEqualTo: sessionId)
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Clear all messages for a user (across all sessions)
  Future<void> clearAllUserMessages(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('messages')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).set(
      data,
      SetOptions(merge: true),
    );
  }
}
