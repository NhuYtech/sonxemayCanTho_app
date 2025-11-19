import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== ROOM OPERATIONS ====================

  /// Create or get existing chat room
  Future<String> createOrGetRoom(String otherUserId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Sort IDs to ensure consistent room ID
    final participants = [currentUserId!, otherUserId]..sort();
    final roomId = '${participants[0]}_${participants[1]}';

    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      // Create new room
      await roomRef.set({
        'participants': participants,
        'lastMessage': '',
        'lastTime': FieldValue.serverTimestamp(),
        'unreadCount': {participants[0]: 0, participants[1]: 0},
        'typingUsers': {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return roomId;
  }

  /// Get all rooms for current user
  Stream<List<ChatRoom>> getUserRooms() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          // Sort in memory instead of using orderBy
          final rooms = snapshot.docs
              .map((doc) => ChatRoom.fromFirestore(doc))
              .toList();
          rooms.sort((a, b) => b.lastTime.compareTo(a.lastTime));
          return rooms;
        });
  }

  /// Delete a room and all its messages
  Future<void> deleteRoom(String roomId) async {
    final batch = _firestore.batch();

    // Delete all messages
    final messagesSnapshot = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .get();

    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete room
    batch.delete(_firestore.collection('rooms').doc(roomId));

    await batch.commit();
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Send a message
  Future<void> sendMessage({
    required String roomId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final roomData = roomDoc.data()!;
    final participants = List<String>.from(roomData['participants']);
    final otherUserId = participants.firstWhere((id) => id != currentUserId);

    // Add message to subcollection
    final messageRef = roomRef.collection('messages').doc();
    await messageRef.set({
      'senderId': currentUserId,
      'content': content,
      'type': type.name,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    // Update room metadata
    final unreadCount = Map<String, int>.from(roomData['unreadCount'] ?? {});
    unreadCount[otherUserId] = (unreadCount[otherUserId] ?? 0) + 1;

    await roomRef.update({
      'lastMessage': content,
      'lastTime': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
    });
  }

  /// Get messages stream for a room
  Stream<List<ChatMessage>> getRoomMessages(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  /// Mark messages as seen when user opens chat
  Future<void> markMessagesAsSeen(String roomId) async {
    if (currentUserId == null) return;

    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);
      final roomDoc = await roomRef.get();

      if (!roomDoc.exists) return;

      // Get all messages
      final messagesSnapshot = await roomRef.collection('messages').get();

      // Update unseen messages in batch
      final batch = _firestore.batch();
      int updatedCount = 0;

      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String?;
        final seen = data['seen'] as bool? ?? false;

        // Mark as seen if it's from another user and not seen yet
        if (senderId != currentUserId && !seen) {
          batch.update(doc.reference, {'seen': true});
          updatedCount++;
        }
      }

      // Reset unread count for current user
      batch.update(roomRef, {'unreadCount.$currentUserId': 0});

      await batch.commit();
      debugPrint('Marked $updatedCount messages as seen in room $roomId');
    } catch (e) {
      debugPrint('Error marking messages as seen: $e');
    }
  }

  // ==================== TYPING INDICATOR ====================

  /// Update typing status
  Future<void> setTyping(String roomId, bool isTyping) async {
    if (currentUserId == null) return;

    await _firestore.collection('rooms').doc(roomId).update({
      'typingUsers.$currentUserId': isTyping,
    });
  }

  /// Get typing status stream
  Stream<bool> getTypingStatus(String roomId, String otherUserId) {
    return _firestore.collection('rooms').doc(roomId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return false;
      final data = snapshot.data()!;
      final typingUsers = data['typingUsers'] as Map<String, dynamic>?;
      return typingUsers?[otherUserId] ?? false;
    });
  }

  // ==================== HELPER FUNCTIONS ====================

  /// Get user name from Firestore
  Future<String> getUserName(String userId) async {
    try {
      // Try users collection first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['fullName'] ?? 'Unknown User';
      }

      // Try accounts collection
      final accountDoc = await _firestore
          .collection('accounts')
          .doc(userId)
          .get();
      if (accountDoc.exists) {
        return accountDoc.data()?['fullName'] ?? 'Unknown User';
      }

      // Try customers collection
      final customerDoc = await _firestore
          .collection('customers')
          .doc(userId)
          .get();
      if (customerDoc.exists) {
        return customerDoc.data()?['name'] ?? 'Unknown User';
      }

      return 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  /// Get total unread count for current user
  Future<int> getTotalUnreadCount() async {
    if (currentUserId == null) return 0;

    final snapshot = await _firestore
        .collection('rooms')
        .where('participants', arrayContains: currentUserId)
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
      total += (unreadCount?[currentUserId] as int?) ?? 0;
    }

    return total;
  }

  /// Stream total unread count
  Stream<int> getTotalUnreadCountStream() {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
            total += (unreadCount?[currentUserId] as int?) ?? 0;
          }
          return total;
        });
  }
}
