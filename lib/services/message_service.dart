import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/message.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Lưu token FCM khi user đăng nhập
  Future<void> saveFcmToken(String userId) async {
    final token = await _fcm.getToken();
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }

  // Gửi tin nhắn mới
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final timestamp = DateTime.now();

    // Transaction để đảm bảo tính nhất quán của dữ liệu
    await _firestore.runTransaction((transaction) async {
      // Tạo tin nhắn mới
      final messageRef = _firestore.collection('messages').doc();
      final message = Message(
        id: messageRef.id,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: timestamp,
      );

      // Lấy chat document
      final chatId = getChatId(senderId, receiverId);
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await transaction.get(chatRef);

      if (!chatDoc.exists) {
        // Tạo chat mới nếu chưa tồn tại
        transaction.set(chatRef, {
          'participants': [senderId, receiverId],
          'lastMessage': content,
          'lastMessageTimestamp': timestamp,
          'hasUnreadMessages': true,
          'unreadCount': {receiverId: 1, senderId: 0},
        });
      } else {
        // Cập nhật chat hiện có
        final unreadCount =
            (chatDoc.data()?['unreadCount'] as Map<String, dynamic>?) ?? {};
        unreadCount[receiverId] = (unreadCount[receiverId] ?? 0) + 1;

        transaction.update(chatRef, {
          'lastMessage': content,
          'lastMessageTimestamp': timestamp,
          'hasUnreadMessages': true,
          'unreadCount': unreadCount,
        });
      }

      // Lưu tin nhắn
      transaction.set(messageRef, message.toMap());
    });

    // Gửi notification
    await _sendNotification(receiverId, content);
  }

  // Đánh dấu tin nhắn đã đọc
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // Cập nhật trạng thái unread trong chat
      final chatRef = _firestore.collection('chats').doc(chatId);

      transaction.update(chatRef, {
        'hasUnreadMessages': false,
        'unreadCount.$userId': 0,
      });

      // Đánh dấu tất cả tin nhắn là đã đọc
      final messagesQuery = await _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messagesQuery.docs) {
        transaction.update(doc.reference, {'isRead': true});
      }
    });
  }

  // Helper method để tạo chat ID
  String getChatId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Gửi notification qua FCM
  Future<void> _sendNotification(
    String receiverId,
    String messageContent,
  ) async {
    try {
      // Lấy FCM token của người nhận
      final userDoc = await _firestore
          .collection('users')
          .doc(receiverId)
          .get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        // Gửi notification qua FCM
        await FirebaseMessaging.instance.sendMessage(
          to: fcmToken,
          data: {'type': 'message', 'content': messageContent},
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Stream để lắng nghe tin nhắn mới
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Stream để lắng nghe số tin nhắn chưa đọc
  Stream<DocumentSnapshot> getChatUnreadCount(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }
}
