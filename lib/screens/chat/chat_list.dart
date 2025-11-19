import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonxemaycantho/screens/chat/customer_support.dart';
import '../../services/chat_service.dart';
import '../../models/chat_room.dart';

/// Màn hình hiển thị danh sách các cuộc trò chuyện
class ChatList extends StatefulWidget {
  final String managerName;
  const ChatList({super.key, required this.managerName});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final ChatService _chatService = ChatService();
  final Map<String, String> _userNameCache = {};

  /// Lấy tên người dùng với cache
  Future<String> _getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    final name = await _chatService.getUserName(userId);
    _userNameCache[userId] = name;
    return name;
  }

  /// Xóa cuộc trò chuyện
  Future<void> _deleteRoom(String roomId) async {
    try {
      await _chatService.deleteRoom(roomId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa cuộc trò chuyện')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;

    if (currentUserId == null) {
      return const Center(child: Text('Vui lòng đăng nhập để sử dụng chat'));
    }

    return Scaffold(
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getUserRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có cuộc trò chuyện nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final rooms = snapshot.data!;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final otherUserId = room.getOtherParticipant(currentUserId);
              final unreadCount = room.unreadCount[currentUserId] ?? 0;
              final hasUnread = unreadCount > 0;

              return FutureBuilder<String>(
                future: _getUserName(otherUserId),
                builder: (context, nameSnapshot) {
                  final chatPartnerName = nameSnapshot.data ?? 'Đang tải...';

                  return Dismissible(
                    key: Key(room.roomId),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận xóa'),
                          content: const Text(
                            'Bạn có chắc muốn xóa cuộc trò chuyện này?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Xóa',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      _deleteRoom(room.roomId);
                    },
                    child: Card(
                      elevation: hasUnread ? 4 : 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: hasUnread
                            ? const BorderSide(color: Colors.blue, width: 2)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: hasUnread
                                  ? Colors.blue
                                  : const Color(0xFFC1473B),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            if (hasUnread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          chatPartnerName,
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: Text(
                          room.lastMessage.isEmpty
                              ? 'Chưa có tin nhắn nào.'
                              : room.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? Colors.black87
                                : Colors.grey[600],
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(room.lastTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnread
                                    ? Colors.blue
                                    : Colors.grey[500],
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (hasUnread) const SizedBox(height: 4),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerSupport(
                                name: chatPartnerName,
                                roomId: room.roomId,
                                otherUserId: otherUserId,
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
