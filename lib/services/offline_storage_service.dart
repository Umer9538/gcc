import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/meeting_model.dart';
import '../models/announcement_model.dart';
import '../models/message_model.dart';

class OfflineStorageService {
  static Database? _database;
  static const String _databaseName = 'gcc_connect_offline.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        department TEXT NOT NULL,
        position TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        profileImageUrl TEXT,
        roles TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        lastLogin TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meetings(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        location TEXT NOT NULL,
        organizerId TEXT NOT NULL,
        organizerName TEXT NOT NULL,
        attendeeIds TEXT NOT NULL,
        attendeeNames TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        reminderTime TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE announcements(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        authorId TEXT NOT NULL,
        authorName TEXT NOT NULL,
        targetGroups TEXT NOT NULL,
        targetDepartments TEXT NOT NULL,
        priority TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        expiryDate TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        readBy TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        senderId TEXT NOT NULL,
        senderName TEXT NOT NULL,
        chatId TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        readBy TEXT NOT NULL,
        replyToId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chats(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        participantIds TEXT NOT NULL,
        participantNames TEXT NOT NULL,
        type TEXT NOT NULL,
        lastMessageId TEXT,
        lastMessageContent TEXT,
        lastMessageTime TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'department': user.department,
        'position': user.position,
        'phoneNumber': user.phoneNumber,
        'profileImageUrl': user.profileImageUrl,
        'roles': jsonEncode(user.roles),
        'isActive': user.isActive ? 1 : 0,
        'createdAt': user.createdAt.toIso8601String(),
        'lastLogin': user.lastLogin.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserModel>> getCachedUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');

    return List.generate(maps.length, (i) {
      return UserModel(
        id: maps[i]['id'],
        email: maps[i]['email'],
        firstName: maps[i]['firstName'],
        lastName: maps[i]['lastName'],
        department: maps[i]['department'],
        position: maps[i]['position'],
        phoneNumber: maps[i]['phoneNumber'],
        profileImageUrl: maps[i]['profileImageUrl'],
        roles: List<String>.from(jsonDecode(maps[i]['roles'])),
        isActive: maps[i]['isActive'] == 1,
        createdAt: DateTime.parse(maps[i]['createdAt']),
        lastLogin: DateTime.parse(maps[i]['lastLogin']),
      );
    });
  }

  Future<void> saveMeeting(MeetingModel meeting) async {
    final db = await database;
    await db.insert(
      'meetings',
      {
        'id': meeting.id,
        'title': meeting.title,
        'description': meeting.description,
        'startTime': meeting.startTime.toIso8601String(),
        'endTime': meeting.endTime.toIso8601String(),
        'location': meeting.location,
        'organizerId': meeting.organizerId,
        'organizerName': meeting.organizerName,
        'attendeeIds': jsonEncode(meeting.attendeeIds),
        'attendeeNames': jsonEncode(meeting.attendeeNames),
        'status': meeting.status.toString(),
        'createdAt': meeting.createdAt.toIso8601String(),
        'reminderTime': meeting.reminderTime?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MeetingModel>> getCachedMeetings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('meetings');

    return List.generate(maps.length, (i) {
      return MeetingModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'],
        startTime: DateTime.parse(maps[i]['startTime']),
        endTime: DateTime.parse(maps[i]['endTime']),
        location: maps[i]['location'],
        organizerId: maps[i]['organizerId'],
        organizerName: maps[i]['organizerName'],
        attendeeIds: List<String>.from(jsonDecode(maps[i]['attendeeIds'])),
        attendeeNames: List<String>.from(jsonDecode(maps[i]['attendeeNames'])),
        status: MeetingStatus.values.firstWhere(
          (e) => e.toString() == maps[i]['status'],
        ),
        createdAt: DateTime.parse(maps[i]['createdAt']),
        reminderTime: maps[i]['reminderTime'] != null
            ? DateTime.parse(maps[i]['reminderTime'])
            : null,
      );
    });
  }

  Future<void> saveAnnouncement(AnnouncementModel announcement) async {
    final db = await database;
    await db.insert(
      'announcements',
      {
        'id': announcement.id,
        'title': announcement.title,
        'content': announcement.content,
        'authorId': announcement.authorId,
        'authorName': announcement.authorName,
        'targetGroups': jsonEncode(announcement.targetGroups),
        'targetDepartments': jsonEncode(announcement.targetDepartments),
        'priority': announcement.priority.toString(),
        'createdAt': announcement.createdAt.toIso8601String(),
        'expiryDate': announcement.expiryDate?.toIso8601String(),
        'isActive': announcement.isActive ? 1 : 0,
        'readBy': jsonEncode(announcement.readBy),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AnnouncementModel>> getCachedAnnouncements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('announcements');

    return List.generate(maps.length, (i) {
      return AnnouncementModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
        authorId: maps[i]['authorId'],
        authorName: maps[i]['authorName'],
        targetGroups: List<String>.from(jsonDecode(maps[i]['targetGroups'])),
        targetDepartments: List<String>.from(jsonDecode(maps[i]['targetDepartments'])),
        priority: AnnouncementPriority.values.firstWhere(
          (e) => e.toString() == maps[i]['priority'],
        ),
        createdAt: DateTime.parse(maps[i]['createdAt']),
        expiryDate: maps[i]['expiryDate'] != null
            ? DateTime.parse(maps[i]['expiryDate'])
            : null,
        isActive: maps[i]['isActive'] == 1,
        readBy: List<String>.from(jsonDecode(maps[i]['readBy'])),
      );
    });
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('users');
    await db.delete('meetings');
    await db.delete('announcements');
    await db.delete('messages');
    await db.delete('chats');
  }

  Future<void> syncDataWhenOnline() async {
    final db = await database;

    await db.rawQuery('''
      SELECT * FROM meetings
      WHERE date(startTime) >= date('now')
    ''');
  }
}