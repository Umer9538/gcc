import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final Map<String, int> unreadCount;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }
}

class GroupConversationModel {
  final String id;
  final String name;
  final String description;
  final List<String> participants;
  final String createdBy;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final DateTime createdAt;

  GroupConversationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.participants,
    required this.createdBy,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'participants': participants,
      'createdBy': createdBy,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'createdAt': createdAt,
    };
  }

  factory GroupConversationModel.fromMap(Map<String, dynamic> map) {
    return GroupConversationModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdBy: map['createdBy'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Get user conversations (1-on-1 chats)
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          print('Conversations snapshot: ${snapshot.docs.length} conversations');
          final conversations = snapshot.docs
              .map((doc) {
                print('Conversation doc: ${doc.data()}');
                return ConversationModel.fromMap(doc.data());
              })
              .toList();

          // Sort in memory instead of Firestore query
          conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

          return conversations;
        });
  }

  // Get user group conversations
  Stream<List<GroupConversationModel>> getUserGroupConversations(String userId) {
    return _firestore
        .collection('group_conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          print('Group conversations snapshot: ${snapshot.docs.length} groups');
          final groups = snapshot.docs
              .map((doc) {
                print('Group doc: ${doc.data()}');
                return GroupConversationModel.fromMap(doc.data());
              })
              .toList();

          // Sort in memory instead of Firestore query
          groups.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });

          return groups;
        });
  }

  // Get messages for a conversation
  Stream<List<MessageModel>> getConversationMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
          print('Firestore snapshot received: ${snapshot.docs.length} documents');
          final messages = snapshot.docs
              .map((doc) {
                print('Message doc: ${doc.data()}');
                return MessageModel.fromMap(doc.data());
              })
              .toList();

          // Sort in memory instead of Firestore query
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          return messages;
        });
  }

  // Generate conversation ID for 1-on-1 chat
  String getConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return sortedIds.join('_');
  }

  // Send message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
  }) async {
    final String messageId = _uuid.v4();
    final now = DateTime.now();

    final message = MessageModel(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: type,
      timestamp: now,
      isRead: false,
      replyToId: replyToId,
    );

    // Start a batch write
    final batch = _firestore.batch();

    // Add the message
    final messageRef = _firestore.collection('messages').doc(messageId);
    batch.set(messageRef, message.toMap());

    // Update or create the conversation
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    batch.set(conversationRef, {
      'id': conversationId,
      'participants': [senderId, receiverId],
      'lastMessage': content,
      'lastMessageTime': now,
      'lastMessageSenderId': senderId,
      'unreadCount': {
        senderId: 0,
        receiverId: FieldValue.increment(1),
      },
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    // Mark all unread messages in this conversation as read
    final QuerySnapshot unreadMessages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadMessages.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Update conversation unread count
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    batch.update(conversationRef, {
      'unreadCount.$userId': 0,
    });

    await batch.commit();
  }

  // Get total unread count for user
  Future<int> getUnreadMessageCount(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    int totalUnread = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final unreadCount = data['unreadCount'] as Map<String, dynamic>? ?? {};
      totalUnread += (unreadCount[userId] as int? ?? 0);
    }

    return totalUnread;
  }

  // Create group conversation
  Future<String> createGroupConversation({
    required String name,
    required String description,
    required List<String> participants,
    required String createdBy,
  }) async {
    final String groupId = _uuid.v4();
    final now = DateTime.now();

    final group = GroupConversationModel(
      id: groupId,
      name: name,
      description: description,
      participants: participants,
      createdBy: createdBy,
      createdAt: now,
      lastMessage: '',
      lastMessageTime: now,
      unreadCount: {for (String userId in participants) userId: 0},
    );

    await _firestore.collection('group_conversations').doc(groupId).set(group.toMap());
    return groupId;
  }

  // Legacy methods to maintain compatibility
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Future<String> createOneOnOneChat({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
  }) async {
    final String chatId = _generateChatId([currentUserId, otherUserId]);

    final existingChat = await _firestore.collection('chats').doc(chatId).get();
    if (existingChat.exists) {
      return chatId;
    }

    final chat = ChatModel(
      id: chatId,
      name: '$currentUserName, $otherUserName',
      participantIds: [currentUserId, otherUserId],
      participantNames: [currentUserName, otherUserName],
      type: ChatType.oneOnOne,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('chats').doc(chatId).set(chat.toMap());
    return chatId;
  }

  Future<String> createGroupChat({
    required String name,
    required List<String> participantIds,
    required List<String> participantNames,
  }) async {
    final String chatId = _uuid.v4();

    final chat = ChatModel(
      id: chatId,
      name: name,
      participantIds: participantIds,
      participantNames: participantNames,
      type: ChatType.group,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('chats').doc(chatId).set(chat.toMap());
    return chatId;
  }

  Future<void> markMessageAsRead(String messageId, String userId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> markChatMessagesAsRead(String chatId, String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final WriteBatch batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }

    await batch.commit();
  }

  String _generateChatId(List<String> participantIds) {
    final sortedIds = List<String>.from(participantIds)..sort();
    return sortedIds.join('_');
  }

  Future<ChatModel?> getChatById(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (!doc.exists) return null;
    return ChatModel.fromMap(doc.data()!);
  }

  Future<void> addParticipantToGroupChat(String chatId, String userId, String userName) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participantIds': FieldValue.arrayUnion([userId]),
      'participantNames': FieldValue.arrayUnion([userName]),
    });
  }

  Future<void> removeParticipantFromGroupChat(String chatId, String userId, String userName) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participantIds': FieldValue.arrayRemove([userId]),
      'participantNames': FieldValue.arrayRemove([userName]),
    });
  }

  // Group messaging methods
  Future<void> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
  }) async {
    final String messageId = _uuid.v4();
    final now = DateTime.now();

    final message = MessageModel(
      id: messageId,
      conversationId: groupId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: type,
      timestamp: now,
      isRead: false,
      replyToId: replyToId,
    );

    // Start a batch write
    final batch = _firestore.batch();

    // Add the message
    final messageRef = _firestore.collection('messages').doc(messageId);
    batch.set(messageRef, message.toMap());

    // Update the group conversation
    final groupRef = _firestore.collection('group_conversations').doc(groupId);

    // Get the current group data to calculate unread counts
    final groupDoc = await groupRef.get();
    if (groupDoc.exists) {
      final groupData = GroupConversationModel.fromMap(groupDoc.data()!);
      final updatedUnreadCount = <String, int>{};

      // Set unread count to 0 for sender and increment for others
      for (String participantId in groupData.participants) {
        if (participantId == senderId) {
          updatedUnreadCount[participantId] = 0;
        } else {
          updatedUnreadCount[participantId] = (groupData.unreadCount[participantId] ?? 0) + 1;
        }
      }

      batch.update(groupRef, {
        'lastMessage': content,
        'lastMessageTime': now,
        'lastMessageSenderId': senderId,
        'unreadCount': updatedUnreadCount,
      });
    }

    await batch.commit();
  }

  Future<void> markGroupMessageAsRead(String groupId, String messageId, String userId) async {
    // Mark the specific message as read
    await _firestore.collection('messages').doc(messageId).update({
      'isRead': true,
    });

    // Update the group conversation unread count
    final groupRef = _firestore.collection('group_conversations').doc(groupId);
    final groupDoc = await groupRef.get();

    if (groupDoc.exists) {
      final groupData = GroupConversationModel.fromMap(groupDoc.data()!);
      final updatedUnreadCount = Map<String, int>.from(groupData.unreadCount);
      updatedUnreadCount[userId] = 0;

      await groupRef.update({
        'unreadCount': updatedUnreadCount,
      });
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<void> updateGroupConversation({
    required String groupId,
    String? name,
    String? description,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    if (updates.isNotEmpty) {
      await _firestore.collection('group_conversations').doc(groupId).update(updates);
    }
  }

  Future<void> addParticipantToGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupRef = _firestore.collection('group_conversations').doc(groupId);
    final groupDoc = await groupRef.get();

    if (groupDoc.exists) {
      final groupData = GroupConversationModel.fromMap(groupDoc.data()!);
      final updatedParticipants = List<String>.from(groupData.participants);
      final updatedUnreadCount = Map<String, int>.from(groupData.unreadCount);

      if (!updatedParticipants.contains(userId)) {
        updatedParticipants.add(userId);
        updatedUnreadCount[userId] = 0;

        await groupRef.update({
          'participants': updatedParticipants,
          'unreadCount': updatedUnreadCount,
        });
      }
    }
  }

  Future<void> removeParticipantFromGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupRef = _firestore.collection('group_conversations').doc(groupId);
    final groupDoc = await groupRef.get();

    if (groupDoc.exists) {
      final groupData = GroupConversationModel.fromMap(groupDoc.data()!);
      final updatedParticipants = List<String>.from(groupData.participants);
      final updatedUnreadCount = Map<String, int>.from(groupData.unreadCount);

      updatedParticipants.remove(userId);
      updatedUnreadCount.remove(userId);

      await groupRef.update({
        'participants': updatedParticipants,
        'unreadCount': updatedUnreadCount,
      });
    }
  }
}