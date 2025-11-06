import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CustomerChatScreen extends StatefulWidget {
  final String customerName;
  const CustomerChatScreen({super.key, required this.customerName});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  User? _currentUser;
  String? _chatId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    _currentUser = user;

    final managerSnapshot = await _firestore
        .collection('accounts')
        .where('role', isEqualTo: 'manager')
        .limit(1)
        .get();

    if (managerSnapshot.docs.isEmpty) {
      debugPrint('Không tìm thấy manager');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final managerId = managerSnapshot.docs.first.id;

    // Tìm cuộc trò chuyện hiện có
    final chatSnapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUser!.uid)
        .get();

    // Tìm cuộc trò chuyện với manager
    for (var doc in chatSnapshot.docs) {
      final participants = doc.data()['participants'] as List<dynamic>;
      if (participants.contains(managerId)) {
        _chatId = doc.id;
        break;
      }
    }

    // Nếu không tìm thấy, tạo cuộc trò chuyện mới
    if (_chatId == null) {
      final newChatDoc = await _firestore.collection('chats').add({
        'participants': [_currentUser!.uid, managerId],
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      _chatId = newChatDoc.id;
    }

    // Đánh dấu tin nhắn của manager là đã đọc
    if (_chatId != null) {
      _markMessagesAsRead();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Phương thức mới để đánh dấu tin nhắn của manager là đã đọc
  void _markMessagesAsRead() async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _currentUser!.uid)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.update({'read': true});
      }
      debugPrint('>>> Đã đánh dấu tin nhắn là đã đọc.');
    } catch (e) {
      debugPrint('>>> Lỗi khi đánh dấu tin nhắn là đã đọc: $e');
    }
  }

  // Gửi tin nhắn
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chatId == null || _currentUser == null) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
            'senderId': _currentUser!.uid,
            'text': text,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false, // Thêm trường này để theo dõi trạng thái đọc
          });

      await _firestore.collection('chats').doc(_chatId).update({
        'lastMessage': text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'hasUnreadMessages':
            true, // Thông báo có tin nhắn mới cho người quản lý
      });

      _controller.clear();
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint('Lỗi khi gửi tin nhắn: $e');
    }
  }

  // Xây dựng giao diện
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('chats')
                          .doc(_chatId)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'Bắt đầu cuộc trò chuyện với cửa hàng.',
                            ),
                          );
                        }
                        final messages = snapshot.data!.docs;
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final messageData =
                                messages[index].data() as Map<String, dynamic>;
                            final currentUserIsSender =
                                messageData['senderId'] == _currentUser?.uid;
                            final timestamp =
                                messageData['timestamp'] as Timestamp?;
                            final timeString = timestamp != null
                                ? DateFormat('HH:mm').format(timestamp.toDate())
                                : '';
                            return Align(
                              alignment: currentUserIsSender
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: currentUserIsSender
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      constraints: const BoxConstraints(
                                        maxWidth: 280,
                                      ),
                                      decoration: BoxDecoration(
                                        color: currentUserIsSender
                                            ? const Color(0xFFB3E5FC)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            // ignore: deprecated_member_use
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        messageData['text'],
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeString,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (currentUserIsSender)
                                          Icon(
                                            Icons.done_all,
                                            size: 16,
                                            color:
                                                (messageData['read'] as bool? ??
                                                    false)
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.red.withOpacity(0.4),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
