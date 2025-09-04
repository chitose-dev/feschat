import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  system, // システムメッセージ（参加通知など）
}

class ChatMessageModel {
  final String id;
  final String eventId;
  final String senderUid;
  final String senderNickname;
  final String? senderProfileImageUrl;
  final String content;
  final MessageType type;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isDeleted;

  ChatMessageModel({
    required this.id,
    required this.eventId,
    required this.senderUid,
    required this.senderNickname,
    this.senderProfileImageUrl,
    required this.content,
    this.type = MessageType.text,
    this.imageUrl,
    required this.timestamp,
    this.isDeleted = false,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      senderUid: data['senderUid'] ?? '',
      senderNickname: data['senderNickname'] ?? '',
      senderProfileImageUrl: data['senderProfileImageUrl'],
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
        orElse: () => MessageType.text,
      ),
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'senderUid': senderUid,
      'senderNickname': senderNickname,
      'senderProfileImageUrl': senderProfileImageUrl,
      'content': content,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDeleted': isDeleted,
    };
  }

  ChatMessageModel copyWith({
    String? content,
    String? imageUrl,
    bool? isDeleted,
  }) {
    return ChatMessageModel(
      id: id,
      eventId: eventId,
      senderUid: senderUid,
      senderNickname: senderNickname,
      senderProfileImageUrl: senderProfileImageUrl,
      content: content ?? this.content,
      type: type,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}