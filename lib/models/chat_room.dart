import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String roomId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastTime;
  final Map<String, int> unreadCount;
  final Map<String, bool>? typingUsers;

  ChatRoom({
    required this.roomId,
    required this.participants,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    this.typingUsers,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      roomId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastTime: (data['lastTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      typingUsers: data['typingUsers'] != null
          ? Map<String, bool>.from(data['typingUsers'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastTime': Timestamp.fromDate(lastTime),
      'unreadCount': unreadCount,
      'typingUsers': typingUsers ?? {},
    };
  }

  // Get other participant ID
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // Check if user has unread messages
  bool hasUnreadMessages(String userId) {
    return (unreadCount[userId] ?? 0) > 0;
  }
}
