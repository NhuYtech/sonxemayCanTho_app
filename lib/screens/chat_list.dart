import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
import 'package:sonxemaycantho/screens/customer_support.dart';

class ChatList extends StatefulWidget {
  final String managerName;
  const ChatList({super.key, required this.managerName});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isLoading = true;
  final Map<String, String> _userNamesCache = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    _currentUser = _auth.currentUser;
    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _getUserName(String uid) async {
    if (_userNamesCache.containsKey(uid)) return _userNamesCache[uid]!;

    if (uid == _currentUser?.uid) {
      _userNamesCache[uid] = widget.managerName;
      return widget.managerName;
    }

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        final name = userDoc['name'] ?? 'Người dùng ẩn danh';
        _userNamesCache[uid] = name;
        return name;
      }

      DocumentSnapshot customerDoc = await _firestore
          .collection('customers')
          .doc(uid)
          .get();
      if (customerDoc.exists) {
        final name = customerDoc['name'] ?? 'Khách hàng ẩn danh';
        _userNamesCache[uid] = name;
        return name;
      }

      _userNamesCache[uid] = 'Người dùng không xác định';
      return 'Người dùng không xác định';
    } catch (e) {
      _userNamesCache[uid] = 'Lỗi tải tên';
      return 'Lỗi tải tên';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC1473B)),
      );
    }

    if (_currentUser == null) {
      return const Center(
        child: Text('Vui lòng đăng nhập để xem danh sách chat.'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header tự làm
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            color: const Color(0xFFC1473B),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Đoạn tin nhắn',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Thanh tìm kiếm
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {},
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Danh sách chat
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('participants', arrayContains: _currentUser!.uid)
                  .orderBy('lastMessageTimestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC1473B)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Không có cuộc trò chuyện nào.'),
                  );
                }

                final chats = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index].data() as Map<String, dynamic>;
                    final chatId = chats[index].id;
                    final participants = List<String>.from(
                      chat['participants'],
                    );
                    final otherId = participants.firstWhere(
                      (uid) => uid != _currentUser!.uid,
                    );

                    return FutureBuilder<String>(
                      future: _getUserName(otherId),
                      builder: (context, nameSnapshot) {
                        final name = nameSnapshot.data ?? 'Đang tải...';
                        final message =
                            chat['lastMessage'] ?? 'Chưa có tin nhắn';
                        if (chat['lastMessageTimestamp'] is Timestamp) {}

                        return Column(
                          children: [
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundImage: AssetImage(
                                  'assets/avatar.png',
                                ), // Đặt avatar bạn muốn
                                radius: 24,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerSupport(
                                      name: name,
                                      chatId: chatId,
                                      customerId: otherId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // bottomNavigationBar: BottomNavigationBar(
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color(0xFFC1473B),
      //   unselectedItemColor: Colors.grey,
      //   currentIndex: 2,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
      //     BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Danh sách'),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.chat_bubble),
      //       label: 'Tin nhắn',
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
      //   ],
      //   onTap: (index) {
      //     // TODO: Điều hướng nếu cần
      //   },
      // ),
    );
  }
}
