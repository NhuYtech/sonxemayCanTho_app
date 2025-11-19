import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, system, warning }

class ChatMessage {
  final String messageId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool seen;
  final String? imageUrl;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.seen = false,
    this.imageUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: _parseMessageType(data['type']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seen: data['seen'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }

  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    if (type is String) {
      switch (type.toLowerCase()) {
        case 'text':
          return MessageType.text;
        case 'image':
          return MessageType.image;
        case 'system':
          return MessageType.system;
        case 'warning':
          return MessageType.warning;
        default:
          return MessageType.text;
      }
    }
    return MessageType.text;
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'seen': seen,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  // Helper to create different message types
  static ChatMessage createTextMessage({
    required String messageId,
    required String senderId,
    required String content,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      messageId: messageId,
      senderId: senderId,
      content: content,
      type: MessageType.text,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  static ChatMessage createImageMessage({
    required String messageId,
    required String senderId,
    required String imageUrl,
    String? caption,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      messageId: messageId,
      senderId: senderId,
      content: caption ?? 'Đã gửi một hình ảnh',
      type: MessageType.image,
      timestamp: timestamp ?? DateTime.now(),
      imageUrl: imageUrl,
    );
  }

  static ChatMessage createSystemMessage({
    required String messageId,
    required String content,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      messageId: messageId,
      senderId: 'system',
      content: content,
      type: MessageType.system,
      timestamp: timestamp ?? DateTime.now(),
      seen: true,
    );
  }

  static ChatMessage createWarningMessage({
    required String messageId,
    required String content,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      messageId: messageId,
      senderId: 'system',
      content: content,
      type: MessageType.warning,
      timestamp: timestamp ?? DateTime.now(),
      seen: true,
    );
  }
}
