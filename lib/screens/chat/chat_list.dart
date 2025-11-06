// lib/screens/customer_support/chat.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sonxemaycantho/screens/chat/customer_support.dart';

// Màn hình hiển thị danh sách các cuộc trò chuyện
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Lấy thông tin người dùng hiện tại
  void _loadCurrentUser() {
    _currentUser = _auth.currentUser;
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    if (_currentUser == null) {
      debugPrint('>>> ChatList: No user signed in.');
      return;
    }
    debugPrint('>>> ChatList: Current user ID: ${_currentUser!.uid}');
  }

  // Lấy tên của người dùng từ Firestore dựa trên UID
  Future<String> _getUserName(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists &&
          userDoc.data() != null &&
          userDoc.data()!['fullName'] != null) {
        return userDoc.data()!['fullName'];
      }

      final customerDoc = await _firestore
          .collection('customers')
          .doc(uid)
          .get();
      if (customerDoc.exists &&
          customerDoc.data() != null &&
          customerDoc.data()!['name'] != null) {
        return customerDoc.data()!['name'];
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy tên người dùng: $e');
    }

    return 'Người dùng không xác định';
  }

  // Hàm xóa cuộc trò chuyện
  Future<void> _deleteChat(String chatId) async {
    try {
      // Xóa tất cả tin nhắn trong subcollection 'messages'
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Sau đó xóa tài liệu cuộc trò chuyện chính
      await _firestore.collection('chats').doc(chatId).delete();
      debugPrint('>>> Đã xóa cuộc trò chuyện: $chatId');
    } catch (e) {
      debugPrint('>>> Lỗi khi xóa cuộc trò chuyện: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: _currentUser!.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chatSnapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${chatSnapshot.error}'));
          }
          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có cuộc trò chuyện nào.'));
          }

          final chatDocs = chatSnapshot.data!.docs;

          return FutureBuilder(
            future: Future.wait(
              chatDocs.map((chatDoc) async {
                final chatData = chatDoc.data() as Map<String, dynamic>;
                final otherParticipantId = chatData['participants'].firstWhere(
                  (id) => id != _currentUser!.uid,
                );

                final chatPartnerName = await _getUserName(otherParticipantId);
                return {
                  'chatDoc': chatDoc,
                  'chatData': chatData,
                  'otherParticipantId': otherParticipantId,
                  'chatPartnerName': chatPartnerName,
                };
              }),
            ),
            builder: (context, AsyncSnapshot<List<dynamic>> futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (futureSnapshot.hasError) {
                return Center(
                  child: Text('Đã xảy ra lỗi: ${futureSnapshot.error}'),
                );
              }
              if (!futureSnapshot.hasData) {
                return const Center(child: Text('Không tìm thấy dữ liệu.'));
              }

              final chatItems = futureSnapshot.data!;

              return ListView.builder(
                itemCount: chatItems.length,
                itemBuilder: (context, index) {
                  final item = chatItems[index];
                  final chatDoc = item['chatDoc'] as DocumentSnapshot;
                  final chatData = item['chatData'] as Map<String, dynamic>;
                  final otherParticipantId =
                      item['otherParticipantId'] as String;
                  final chatPartnerName = item['chatPartnerName'] as String;

                  final lastMessageTimestamp =
                      chatData['lastMessageTimestamp'] as Timestamp?;
                  final lastMessageTime = lastMessageTimestamp != null
                      ? DateFormat(
                          'HH:mm',
                        ).format(lastMessageTimestamp.toDate())
                      : '';

                  return Dismissible(
                    key: Key(chatDoc.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _deleteChat(chatDoc.id);
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.person, color: Colors.white),
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
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        trailing: Text(
                          lastMessageTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerSupport(
                                name: chatPartnerName,
                                chatId: chatDoc.id,
                                customerId: otherParticipantId,
                              ),
                            ),
                          );
                        },
                      ),
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
