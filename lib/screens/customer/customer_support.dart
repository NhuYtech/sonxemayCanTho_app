import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth để lấy User ID
// XÓA DÒNG NÀY: Vì Header đã được cung cấp bởi AppBar của ManagerHome
// import 'package:sonxemaycantho/widgets/header.dart'; // Import widget Header

class ManagerCustomerSupport extends StatefulWidget {
  final String name;
  const ManagerCustomerSupport({super.key, required this.name});

  @override
  State<ManagerCustomerSupport> createState() => _ManagerCustomerSupportState();
}

class _ManagerCustomerSupportState extends State<ManagerCustomerSupport> {
  // Khởi tạo Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Khởi tạo Firebase Auth instance để lấy thông tin người dùng hiện tại
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Để cuộn xuống tin nhắn mới nhất

  // Biến để lưu trữ ID của cuộc trò chuyện hiện tại
  String? _currentChatId;
  String? _currentUserId; // ID của người dùng (manager) hiện tại

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    // Gọi hàm để tìm hoặc tạo chat ID khi màn hình khởi tạo
    _findOrCreateChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Lấy thông tin người dùng hiện tại
  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      debugPrint('Current user ID: $_currentUserId');
    } else {
      debugPrint('No user currently signed in.');
      // Xử lý trường hợp không có người dùng đăng nhập (ví dụ: chuyển hướng đến màn hình đăng nhập)
    }
  }

  // Hàm để tìm hoặc tạo chat ID
  Future<void> _findOrCreateChat() async {
    // Đây là logic giả định để xác định chatId.
    // Trong một ứng dụng thực tế, bạn sẽ cần một cách phức tạp hơn để quản lý các cuộc trò chuyện.
    // Ví dụ:
    // 1. Nếu đây là trang CSKH tổng hợp, bạn sẽ hiển thị danh sách các cuộc trò chuyện
    //    và người quản lý sẽ chọn một cuộc trò chuyện để tham gia.
    // 2. Hoặc, nếu một khách hàng bắt đầu cuộc trò chuyện, bạn sẽ tạo một chatId duy nhất
    //    liên kết với khách hàng đó và người quản lý sẽ được thông báo.

    // Để đơn giản cho ví dụ này, chúng ta sẽ sử dụng một customerId cố định
    // Trong thực tế, 'customer_id_for_this_chat' sẽ là ID của khách hàng đang được hỗ trợ
    final String customerIdForThisChat =
        '6YHcpasDKZQIQFacavCgWnTNZca2'; // Thay bằng ID khách hàng thực tế (ví dụ từ Firebase Console)

    if (_currentUserId == null) {
      debugPrint('Cannot find or create chat: Current user ID is null.');
      return;
    }

    try {
      // Tìm kiếm cuộc trò chuyện giữa manager và khách hàng này
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: _currentUserId)
          .get();

      String? foundChatId;
      for (var doc in querySnapshot.docs) {
        final participants = List<String>.from(doc['participants']);
        if (participants.contains(customerIdForThisChat)) {
          foundChatId = doc.id;
          break;
        }
      }

      if (foundChatId != null) {
        setState(() {
          _currentChatId = foundChatId;
        });
        debugPrint('Found existing chat with ID: $_currentChatId');
      } else {
        // Nếu không tìm thấy, tạo một cuộc trò chuyện mới
        final newChatDoc = await _firestore.collection('chats').add({
          'participants': [
            _currentUserId!,
            customerIdForThisChat,
          ], // Sử dụng _currentUserId! sau khi kiểm tra null
          'lastMessage': '',
          'lastMessageTimestamp':
              FieldValue.serverTimestamp(), // Thêm trường này
          'status': 'open', // Trạng thái cuộc trò chuyện
          'createdAt': FieldValue.serverTimestamp(), // Thêm trường này
        });
        setState(() {
          _currentChatId = newChatDoc.id;
        });
        debugPrint('Created new chat with ID: $_currentChatId');
      }
    } catch (e) {
      debugPrint('Error finding or creating chat: $e');
    }
  }

  // Gửi tin nhắn lên Firestore
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _currentChatId == null || _currentUserId == null) {
      debugPrint(
        'Cannot send message: Text is empty, chat ID or user ID is null.',
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
            'read': false, // Mặc định là chưa đọc khi gửi
          });

      // Cập nhật lastMessage và timestamp trong document chat chính
      await _firestore.collection('chats').doc(_currentChatId!).update({
        'lastMessage': text,
        'lastMessageTimestamp':
            FieldValue.serverTimestamp(), // Cập nhật trường này
      });

      _controller.clear();
      // Cuộn xuống cuối danh sách tin nhắn sau khi gửi
      _scrollController.animateTo(
        0.0, // Cuộn về đầu danh sách (do reverse: true)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Xử lý lỗi (ví dụ: hiển thị thông báo cho người dùng)
    }
  }

  // Hàm đánh dấu tin nhắn là đã đọc
  void _markMessageAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'read': true});
      debugPrint('Message $messageId in chat $chatId marked as read.');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // XÓA WIDGET SCAFFOLD NÀY:
    // Màn hình này sẽ được đặt trong body của Scaffold khác (ManagerHome),
    // nên không cần Scaffold riêng để tránh trùng lặp AppBar.
    return SafeArea(
      child: Column(
        children: [
          // XÓA DÒNG NÀY: Header đã có ở ManagerHome
          // Header(
          //   name: widget.name,
          //   backgroundColor: const Color(
          //     0xFFC1473B,
          //   ), // Màu đỏ đậm bạn đã chỉ định
          // ),

          // Nội dung tin nhắn
          Expanded(
            child: _currentChatId == null
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ) // Hiển thị loading khi đang tìm/tạo chat
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chats')
                        .doc(_currentChatId!)
                        .collection('messages')
                        .orderBy(
                          'timestamp',
                          descending: true,
                        ) // Sắp xếp tin nhắn mới nhất ở trên cùng (do reverse: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
                        final isRead =
                            messageData['read'] as bool? ??
                            false; // Lấy trạng thái đã đọc
                        final currentUserIsSender =
                            (messageSenderId == _currentUserId);

                        // Đánh dấu tin nhắn là đã đọc nếu nó không phải của người dùng hiện tại và chưa được đọc
                        if (!currentUserIsSender && !isRead) {
                          // Sử dụng Future.microtask để tránh lỗi "setState during build"
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
                                mainAxisSize: MainAxisSize
                                    .min, // Giúp Row không chiếm hết chiều rộng
                                crossAxisAlignment: CrossAxisAlignment
                                    .end, // Canh dưới cho avatar và bubble
                                children: [
                                  // Avatar cho tin nhắn đến (không phải của người gửi hiện tại)
                                  if (!currentUserIsSender) ...[
                                    const CircleAvatar(
                                      radius: 16, // Kích thước avatar
                                      backgroundColor:
                                          Colors.blueGrey, // Màu nền avatar
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ), // Icon người dùng
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ), // Khoảng cách giữa avatar và bubble
                                  ],
                                  // Nội dung tin nhắn
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
                                              ) // Màu xanh nhạt cho tin nhắn gửi đi
                                            : Colors
                                                  .white, // Màu trắng cho tin nhắn đến
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(
                                            currentUserIsSender ? 16 : 4,
                                          ), // Góc dưới trái ít bo hơn cho tin nhắn đến
                                          bottomRight: Radius.circular(
                                            currentUserIsSender ? 4 : 16,
                                          ), // Góc dưới phải ít bo hơn cho tin nhắn gửi đi
                                        ),
                                        boxShadow: [
                                          // Thêm bóng đổ nhẹ
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: currentUserIsSender
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            messageText,
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (currentUserIsSender) // Chỉ hiển thị trạng thái đã xem cho tin nhắn của mình
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    isRead
                                                        ? 'Đã xem'
                                                        : 'Đã gửi', // Hiển thị "Đã xem" hoặc "Đã gửi"
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    isRead
                                                        ? Icons.done_all
                                                        : Icons
                                                              .done, // Icon 2 tick nếu đã xem, 1 tick nếu đã gửi
                                                    size: 14,
                                                    color: isRead
                                                        ? Colors.blue
                                                        : Colors
                                                              .black54, // Màu xanh nếu đã xem
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Khoảng cách cho tin nhắn gửi đi
                                  if (currentUserIsSender)
                                    const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView(
                        controller: _scrollController, // Gán ScrollController
                        reverse: true, // Hiển thị tin nhắn mới nhất ở dưới cùng
                        padding: const EdgeInsets.all(12),
                        children: messageBubbles,
                      );
                    },
                  ),
          ),

          // Ô nhập tin nhắn
          // Thay đổi cấu trúc để tách TextField và IconButton
          Padding(
            padding: const EdgeInsets.all(
              12.0,
            ), // Padding cho toàn bộ phần nhập tin nhắn
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end, // Canh chỉnh theo đáy
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        30,
                      ), // Bo tròn nhiều hơn
                      boxShadow: [
                        // Thêm bóng đổ
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
                        border: InputBorder.none, // Bỏ border của TextField
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ), // Điều chỉnh padding bên trong TextField
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null, // Cho phép nhiều dòng
                      keyboardType: TextInputType.multiline, // Bàn phím đa dòng
                    ),
                  ),
                ),
                const SizedBox(width: 12), // Khoảng cách giữa ô nhập và nút gửi
                // Nút gửi riêng biệt
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12), // Padding cho icon
                    decoration: BoxDecoration(
                      color: Colors.red, // Màu đỏ cho nút gửi
                      shape: BoxShape.circle, // Hình tròn
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
                    ), // Icon gửi màu trắng
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
