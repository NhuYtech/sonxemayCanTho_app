import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import '../../models/chat_message.dart';

class CustomerChatScreen extends StatefulWidget {
  final String customerName;
  const CustomerChatScreen({super.key, required this.customerName});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen>
    with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _roomId;
  String? _managerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Mark messages as seen when user is actively viewing
    if ((state == AppLifecycleState.resumed ||
            state == AppLifecycleState.inactive) &&
        _roomId != null &&
        mounted) {
      _chatService.markMessagesAsSeen(_roomId!);
    }
  }

  void _initializeChat() async {
    try {
      if (_chatService.currentUserId == null) {
        debugPrint('User not authenticated');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập để chat')),
          );
        }
        return;
      }

      debugPrint('Finding manager...');
      // Find manager
      final managerSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'manager')
          .limit(1)
          .get();

      if (managerSnapshot.docs.isEmpty) {
        debugPrint('Không tìm thấy manager');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy quản lý. Vui lòng thử lại sau.'),
            ),
          );
        }
        return;
      }

      _managerId = managerSnapshot.docs.first.id;
      debugPrint('Manager ID: $_managerId');

      // Create or get room with manager
      debugPrint('Creating/getting room...');
      _roomId = await _chatService.createOrGetRoom(_managerId!);
      debugPrint('Room ID: $_roomId');

      // Mark messages as seen initially and when new messages arrive
      await _chatService.markMessagesAsSeen(_roomId!);

      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Chat initialized successfully');
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
      }
    }
  }

  // Gửi tin nhắn
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _roomId == null) return;

    try {
      await _chatService.sendMessage(
        roomId: _roomId!,
        content: text,
        type: MessageType.text,
      );

      _controller.clear();
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint('Lỗi khi gửi tin nhắn: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể gửi tin nhắn: $e')));
      }
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
                  : _roomId == null
                  ? const Center(child: Text('Không thể kết nối với cửa hàng'))
                  : StreamBuilder<List<ChatMessage>>(
                      stream: _chatService.getRoomMessages(_roomId!),
                      builder: (context, snapshot) {
                        // Mark as seen when new data arrives
                        if (snapshot.hasData && _roomId != null && mounted) {
                          // Use post-frame callback to avoid calling setState during build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _chatService.markMessagesAsSeen(_roomId!);
                            }
                          });
                        }

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
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Bắt đầu cuộc trò chuyện với cửa hàng.',
                            ),
                          );
                        }

                        final messages = snapshot.data!;
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final currentUserIsSender =
                                message.senderId == _chatService.currentUserId;
                            final timeString = DateFormat(
                              'HH:mm',
                            ).format(message.timestamp);

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
                                        message.content,
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
                                            color: message.seen
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
