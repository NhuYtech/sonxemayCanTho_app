// lib/screens/customer_support/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sonxemaycantho/screens/customer_support.dart'; // Đảm bảo import đúng đường dẫn cho CustomerSupport

class ChatList extends StatefulWidget {
  final String managerName; // Tên của quản lý hiện tại
  const ChatList({super.key, required this.managerName});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Tải thông tin người dùng hiện tại
  void _loadCurrentUser() {
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      debugPrint('>>> ChatList: No user signed in.');
      // Xử lý trường hợp không có người dùng đăng nhập, có thể chuyển hướng
      // hoặc hiển thị thông báo lỗi.
      setState(() {
        _isLoading = false;
      });
      return;
    }
    debugPrint('>>> ChatList: Current user ID: ${_currentUser!.uid}');
    setState(() {
      _isLoading = false;
    });
  }

  // Hàm để lấy tên người dùng (khách hàng hoặc nhân viên) từ UID
  Future<String> _getUserName(String uid) async {
    if (uid == _currentUser?.uid) {
      return widget.managerName; // Nếu là chính quản lý, trả về tên quản lý
    }
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        return userDoc['name'] ?? 'Người dùng ẩn danh';
      }
      // Fallback nếu không tìm thấy trong 'users', có thể thử 'customers'
      DocumentSnapshot customerDoc = await _firestore
          .collection('customers')
          .doc(uid)
          .get();
      if (customerDoc.exists) {
        return customerDoc['name'] ?? 'Khách hàng ẩn danh';
      }
      return 'Người dùng không xác định';
    } catch (e) {
      debugPrint('Error fetching user name for $uid: $e');
      return 'Lỗi tải tên';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(0xFFC1473B),
          ), // Màu loading cũng theo theme
        ),
      );
    }

    if (_currentUser == null) {
      return const Center(
        child: Text(
          'Vui lòng đăng nhập để xem danh sách chat.',
          style: TextStyle(color: Color(0xFFC1473B)), // Màu chữ cũng theo theme
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách cuộc trò chuyện',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B), // Đã thay đổi màu nền ở đây
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lấy tất cả các cuộc trò chuyện mà người dùng hiện tại là một participant
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: _currentUser!.uid)
            .orderBy(
              'lastMessageTimestamp',
              descending: true,
            ) // Sắp xếp theo tin nhắn cuối cùng
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFFC1473B),
                ), // Màu loading cũng theo theme
              ),
            );
          }
          if (snapshot.hasError) {
            debugPrint('Stream error: ${snapshot.error}');
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có cuộc trò chuyện nào.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              DocumentSnapshot chatDoc = chats[index];
              Map<String, dynamic> chatData =
                  chatDoc.data() as Map<String, dynamic>;

              List<String> participants = List<String>.from(
                chatData['participants'],
              );
              // Tìm ID của người tham gia khác (khách hàng)
              String otherParticipantId = participants.firstWhere(
                (uid) => uid != _currentUser!.uid,
                orElse: () => _currentUser!.uid, // Fallback nếu chỉ có một mình
              );

              // Lấy tên của người tham gia khác
              return FutureBuilder<String>(
                future: _getUserName(otherParticipantId),
                builder: (context, nameSnapshot) {
                  String chatPartnerName =
                      nameSnapshot.data ?? 'Đang tải tên...';
                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                    chatPartnerName = 'Đang tải tên...';
                  } else if (nameSnapshot.hasError) {
                    chatPartnerName = 'Lỗi tải tên';
                  }

                  // Định dạng thời gian tin nhắn cuối cùng
                  String lastMessageTime = '';
                  if (chatData['lastMessageTimestamp'] is Timestamp) {
                    Timestamp timestamp = chatData['lastMessageTimestamp'];
                    DateTime dateTime = timestamp.toDate();
                    lastMessageTime = DateFormat(
                      'HH:mm dd/MM',
                    ).format(dateTime);
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 4.0,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(
                          0xFFC1473B,
                        ).withOpacity(0.1), // Màu avatar cũng theo theme
                        child: Icon(
                          Icons.person,
                          color: const Color(
                            0xFFC1473B,
                          ), // Màu icon avatar cũng theo theme
                          size: 30,
                        ),
                      ),
                      title: Text(
                        chatPartnerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      subtitle: Text(
                        chatData['lastMessage'] ?? 'Chưa có tin nhắn nào.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      trailing: Text(
                        lastMessageTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      onTap: () {
                        // Chuyển đến màn hình chat chi tiết
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerSupport(
                              name: chatPartnerName, // Tên khách hàng
                              chatId: chatDoc.id, // ID cuộc trò chuyện
                              customerId:
                                  otherParticipantId, // ID của khách hàng
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
