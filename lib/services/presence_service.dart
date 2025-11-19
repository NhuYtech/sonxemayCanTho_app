import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cập nhật trạng thái online
  Future<void> updateUserPresence({bool isOnline = true}) async {
    if (_auth.currentUser == null) return;

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Stream để lắng nghe trạng thái của một user
  Stream<DocumentSnapshot> getUserPresence(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Cập nhật trạng thái typing
  Future<void> updateTypingStatus(
    String chatId, {
    bool isTyping = false,
  }) async {
    if (_auth.currentUser == null) return;

    await _firestore.collection('chats').doc(chatId).update({
      'typingUsers.${_auth.currentUser!.uid}': isTyping,
    });
  }

  // Stream để lắng nghe trạng thái typing
  Stream<DocumentSnapshot> getTypingStatus(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }
}
