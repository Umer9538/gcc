import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSender {
  user,
  bot,
  system,
}

enum MessageType {
  text,
  quickAction,
  suggestion,
  error,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<String>? quickActions;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.type,
    required this.timestamp,
    this.metadata,
    this.quickActions,
    this.isLoading = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'sender': sender.toString(),
      'type': type.toString(),
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'quickActions': quickActions,
      'isLoading': isLoading,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      sender: MessageSender.values.firstWhere(
        (e) => e.toString() == map['sender'],
        orElse: () => MessageSender.bot,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: map['metadata'],
      quickActions: map['quickActions'] != null
          ? List<String>.from(map['quickActions'])
          : null,
      isLoading: map['isLoading'] ?? false,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    MessageType? type,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<String>? quickActions,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      quickActions: quickActions ?? this.quickActions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatConversation {
  final String id;
  final String userId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String title;
  final bool isActive;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.messages,
    required this.createdAt,
    required this.lastMessageAt,
    required this.title,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'messages': messages.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'title': title,
      'isActive': isActive,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      messages: (map['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessageAt: map['lastMessageAt'] is Timestamp
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : DateTime.now(),
      title: map['title'] ?? 'New Conversation',
      isActive: map['isActive'] ?? true,
    );
  }
}

class QuickAction {
  final String id;
  final String label;
  final String command;
  final String icon;
  final String description;

  QuickAction({
    required this.id,
    required this.label,
    required this.command,
    required this.icon,
    required this.description,
  });
}
