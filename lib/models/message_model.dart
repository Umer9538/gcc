import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final String? chatId; // Legacy field for compatibility
  final String? conversationId; // New field for conversations
  final MessageType type;
  final DateTime timestamp;
  final List<String> readBy;
  final bool isRead;
  final String? replyToId;

  MessageModel({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    this.chatId,
    this.conversationId,
    this.type = MessageType.text,
    required this.timestamp,
    this.readBy = const [],
    this.isRead = false,
    this.replyToId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      'chatId': chatId,
      'conversationId': conversationId,
      'type': type.toString(),
      'timestamp': timestamp,
      'readBy': readBy,
      'isRead': isRead,
      'replyToId': replyToId,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      chatId: map['chatId'],
      conversationId: map['conversationId'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      readBy: List<String>.from(map['readBy'] ?? []),
      isRead: map['isRead'] ?? false,
      replyToId: map['replyToId'],
    );
  }
}

class ChatModel {
  final String id;
  final String name;
  final List<String> participantIds;
  final List<String> participantNames;
  final ChatType type;
  final String? lastMessageId;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.name,
    required this.participantIds,
    required this.participantNames,
    required this.type,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageTime,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'type': type.toString(),
      'lastMessageId': lastMessageId,
      'lastMessageContent': lastMessageContent,
      'lastMessageTime': lastMessageTime,
      'createdAt': createdAt,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: List<String>.from(map['participantNames'] ?? []),
      type: ChatType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ChatType.oneOnOne,
      ),
      lastMessageId: map['lastMessageId'],
      lastMessageContent: map['lastMessageContent'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

enum MessageType {
  text,
  file,
  image,
}

enum ChatType {
  oneOnOne,
  group,
}