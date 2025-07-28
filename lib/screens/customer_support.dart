// lib/screens/customer_support/manager_customer_support.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth để lấy User ID

class CustomerSupport extends StatefulWidget {
  final String name;
  const CustomerSupport({
    super.key,
    required this.name,
    required String chatId,
    required String customerId,
  });

  @override
  State<CustomerSupport> createState() => _CustomerSupportState();
}

class _CustomerSupportState extends State<CustomerSupport> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _currentChatId;
  String? _currentUserId;
  bool _isChatLoading =
      true; // Khởi tạo là true, không cần setState ngay lập tức

  @override
  void initState() {
    super.initState();
    _initializeChat(); // Gọi hàm khởi tạo chat
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Hàm mới để quản lý toàn bộ quá trình khởi tạo chat
  void _initializeChat() async {
    debugPrint('>>> _initializeChat: Starting chat initialization.');
    // Không cần setState ở đây vì _isChatLoading đã là true khi khởi tạo State

    // Bước 1: Lấy thông tin người dùng hiện tại
    final user = _auth.currentUser;
    if (user != null) {
      if (mounted) {
        // Kiểm tra mounted trước khi cập nhật _currentUserId
        setState(() {
          _currentUserId = user.uid;
        });
      }
      debugPrint('>>> _initializeChat: Current user ID: $_currentUserId');
    } else {
      debugPrint(
        '>>> _initializeChat: No user currently signed in. _currentUserId is null.',
      );
      // Xử lý trường hợp không có người dùng đăng nhập (ví dụ: chuyển hướng đến màn hình đăng nhập)
      if (mounted) {
        setState(() {
          _isChatLoading = false; // Dừng loading nếu không có người dùng
        });
      }
      return;
    }

    // Bước 2: Tìm hoặc tạo chat ID
    await _findOrCreateChat();

    if (mounted) {
      // Kiểm tra mounted trước khi cập nhật _isChatLoading cuối cùng
      setState(() {
        _isChatLoading = false; // Hoàn thành tải, ẩn loading
      });
    }
    debugPrint(
      '>>> _initializeChat: Chat initialization finished. _currentChatId: $_currentChatId',
    );
  }

  Future<void> _findOrCreateChat() async {
    // Đây là ID của khách hàng mà quản lý đang muốn hỗ trợ
    // Trong ứng dụng thực tế, ID này có thể được truyền vào qua constructor của widget
    // hoặc được chọn từ danh sách các cuộc trò chuyện đang chờ.
    final String customerIdForThisChat = '6YHcpasDKZQIQFacavCgWnTNZca2';

    debugPrint('>>> _findOrCreateChat: Attempting to find/create chat.');
    debugPrint(
      '>>> _findOrCreateChat: _currentUserId (inside findOrCreateChat): $_currentUserId',
    );
    debugPrint(
      '>>> _findOrCreateChat: customerIdForThisChat: $customerIdForThisChat',
    );

    if (_currentUserId == null) {
      debugPrint(
        '>>> _findOrCreateChat: Cannot find or create chat: _currentUserId is null.',
      );
      return;
    }

    try {
      debugPrint(
        '>>> _findOrCreateChat: Querying chats where participants contain $_currentUserId',
      );
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: _currentUserId)
          .get();

      String? foundChatId;
      debugPrint(
        '>>> _findOrCreateChat: Found ${querySnapshot.docs.length} chats containing current user.',
      );

      for (var doc in querySnapshot.docs) {
        final participants = List<String>.from(doc['participants']);
        debugPrint(
          '>>> _findOrCreateChat: Checking chat ${doc.id} with participants: $participants',
        );
        if (participants.contains(customerIdForThisChat)) {
          foundChatId = doc.id;
          debugPrint(
            '>>> _findOrCreateChat: Found matching chat with customer ID: ${doc.id}',
          );
          break;
        }
      }

      if (foundChatId != null) {
        if (mounted) {
          // Kiểm tra mounted
          setState(() {
            _currentChatId = foundChatId;
          });
        }
        debugPrint(
          '>>> _findOrCreateChat: Successfully set _currentChatId to: $_currentChatId',
        );
      } else {
        debugPrint(
          '>>> _findOrCreateChat: No existing chat found with customer. Creating new chat.',
        );
        final newChatDoc = await _firestore.collection('chats').add({
          'participants': [_currentUserId!, customerIdForThisChat],
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          // Kiểm tra mounted
          setState(() {
            _currentChatId = newChatDoc.id;
          });
        }
        debugPrint(
          '>>> _findOrCreateChat: Created new chat with ID: $_currentChatId',
        );
      }
    } catch (e) {
      debugPrint('>>> _findOrCreateChat: Error finding or creating chat: $e');
      // Không cần setState ở đây vì _isChatLoading sẽ được set false ở _initializeChat()
      // hoặc bạn có thể thêm một biến trạng thái lỗi riêng nếu muốn hiển thị thông báo lỗi cụ thể.
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();

    debugPrint('>>> _sendMessage: Text: "$text"');
    debugPrint('>>> _sendMessage: _currentChatId: $_currentChatId');
    debugPrint('>>> _sendMessage: _currentUserId: $_currentUserId');

    if (text.isEmpty || _currentChatId == null || _currentUserId == null) {
      debugPrint(
        '>>> _sendMessage: Cannot send message: Text is empty, chat ID or user ID is null. Returning.',
      );
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(_currentChatId!)
          .collection('messages')
          .add({
            'senderId': _currentUserId,
            'text': text,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });

      await _firestore.collection('chats').doc(_currentChatId!).update({
        'lastMessage': text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      _controller.clear();
      debugPrint(
        '>>> _sendMessage: Message sent successfully. Clearing text field.',
      );
      // Cuộn xuống cuối danh sách tin nhắn
      _scrollController.animateTo(
        0.0, // Đảo ngược danh sách nên 0.0 là cuối
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint('>>> _sendMessage: Error sending message: $e');
    }
  }

  void _markMessageAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'read': true});
      debugPrint(
        '>>> _markMessageAsRead: Message $messageId in chat $chatId marked as read.',
      );
    } catch (e) {
      debugPrint('>>> _markMessageAsRead: Error marking message as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thêm Scaffold để có AppBar
      appBar: AppBar(
        title: Text(
          'Hỗ trợ khách hàng: ${widget.name}',
        ), // Hiển thị tên từ widget.name
        backgroundColor: Colors.red, // Màu sắc AppBar
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  _isChatLoading // Hiển thị loading nếu chat đang được khởi tạo
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : _currentChatId ==
                        null // Nếu không loading mà _currentChatId vẫn null (có lỗi)
                  ? const Center(
                      child: Text(
                        'Không thể tải cuộc trò chuyện. Vui lòng thử lại.',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('chats')
                          .doc(_currentChatId!)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          debugPrint('Stream error: ${snapshot.error}');
                          return Center(
                            child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'Chưa có tin nhắn nào. Bắt đầu cuộc trò chuyện!',
                            ),
                          );
                        }

                        final messages = snapshot.data!.docs;
                        List<Widget> messageBubbles = [];
                        for (var messageDoc in messages) {
                          final messageData =
                              messageDoc.data() as Map<String, dynamic>;
                          final messageText = messageData['text'] as String;
                          final messageSenderId =
                              messageData['senderId'] as String?;
                          final isRead = messageData['read'] as bool? ?? false;
                          final currentUserIsSender =
                              (messageSenderId == _currentUserId);

                          // Đánh dấu tin nhắn là đã đọc nếu nó không phải của người dùng hiện tại và chưa đọc
                          if (!currentUserIsSender && !isRead) {
                            // Sử dụng Future.microtask để tránh lỗi setState trong khi build
                            Future.microtask(
                              () => _markMessageAsRead(
                                _currentChatId!,
                                messageDoc.id,
                              ),
                            );
                          }

                          messageBubbles.add(
                            Align(
                              alignment: currentUserIsSender
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!currentUserIsSender) ...[
                                      const CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.blueGrey,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        constraints: const BoxConstraints(
                                          maxWidth: 280,
                                        ),
                                        decoration: BoxDecoration(
                                          color: currentUserIsSender
                                              ? const Color(
                                                  0xFFB3E5FC,
                                                ) // Màu xanh nhạt cho tin nhắn của mình
                                              : Colors
                                                    .white, // Màu trắng cho tin nhắn của người khác
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: Radius.circular(
                                              currentUserIsSender ? 16 : 4,
                                            ),
                                            bottomRight: Radius.circular(
                                              currentUserIsSender ? 4 : 16,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.2,
                                              ),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              currentUserIsSender
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              messageText,
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (currentUserIsSender)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4.0,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      isRead
                                                          ? 'Đã xem'
                                                          : 'Đã gửi',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      isRead
                                                          ? Icons.done_all
                                                          : Icons.done,
                                                      size: 14,
                                                      color: isRead
                                                          ? Colors.blue
                                                          : Colors.black54,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (currentUserIsSender)
                                      const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView(
                          controller: _scrollController,
                          reverse:
                              true, // Hiển thị tin nhắn mới nhất ở dưới cùng
                          padding: const EdgeInsets.all(12),
                          children: messageBubbles,
                        );
                      },
                    ),
            ),

            // Ô nhập tin nhắn
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Tin nhắn...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (text) {
                          if (!_isChatLoading &&
                              _currentChatId != null &&
                              _currentUserId != null) {
                            _sendMessage();
                          } else {
                            debugPrint(
                              '>>> TextField onSubmitted: Chat not ready to send message.',
                            );
                          }
                        },
                        maxLines: null, // Cho phép nhiều dòng
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (!_isChatLoading &&
                          _currentChatId != null &&
                          _currentUserId != null) {
                        _sendMessage();
                      } else {
                        debugPrint(
                          '>>> Send Button onTap: Chat not ready to send message.',
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red, // Màu nút gửi
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
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
                        size: 28,
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
