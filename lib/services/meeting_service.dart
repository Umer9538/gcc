import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/meeting_model.dart';
import 'notification_service.dart';

class MeetingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();

  Stream<List<MeetingModel>> getUserMeetings(String userId) {
    return _firestore
        .collection('meetings')
        .where('attendeeIds', arrayContains: userId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<MeetingModel>> getMeetingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) {
    Query query = _firestore
        .collection('meetings')
        .where('startTime', isGreaterThanOrEqualTo: startDate)
        .where('startTime', isLessThanOrEqualTo: endDate);

    if (userId != null) {
      query = query.where('attendeeIds', arrayContains: userId);
    }

    return query
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<String> createMeeting({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String organizerId,
    required String organizerName,
    required List<String> attendeeIds,
    required List<String> attendeeNames,
    DateTime? reminderTime,
  }) async {
    final String meetingId = _uuid.v4();

    final meeting = MeetingModel(
      id: meetingId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      organizerId: organizerId,
      organizerName: organizerName,
      attendeeIds: [...attendeeIds, organizerId],
      attendeeNames: [...attendeeNames, organizerName],
      createdAt: DateTime.now(),
      reminderTime: reminderTime,
    );

    await _firestore
        .collection('meetings')
        .doc(meetingId)
        .set(meeting.toMap());

    // Send notification to attendees about new meeting
    try {
      await _notificationService.sendMeetingNotification(
        meetingId: meetingId,
        title: title,
        attendeeIds: attendeeIds,
        notifType: 'created',
        meetingTime: startTime,
      );

      // Schedule reminder if specified
      if (reminderTime != null) {
        await _scheduleMeetingReminder(
          meetingId: meetingId,
          title: title,
          attendeeIds: [...attendeeIds, organizerId],
          reminderTime: reminderTime,
          meetingTime: startTime,
        );
      }
    } catch (e) {
      print('Failed to send meeting notifications: $e');
    }

    return meetingId;
  }

  Future<void> updateMeeting(String meetingId, Map<String, dynamic> updates) async {
    final meeting = await getMeetingById(meetingId);
    if (meeting != null) {
      await _firestore.collection('meetings').doc(meetingId).update(updates);

      // Send notification about meeting update
      try {
        await _notificationService.sendMeetingNotification(
          meetingId: meetingId,
          title: meeting.title,
          attendeeIds: meeting.attendeeIds,
          notifType: 'updated',
          meetingTime: meeting.startTime,
        );
      } catch (e) {
        print('Failed to send meeting update notification: $e');
      }
    }
  }

  Future<void> deleteMeeting(String meetingId) async {
    final meeting = await getMeetingById(meetingId);
    if (meeting != null) {
      await _firestore.collection('meetings').doc(meetingId).delete();

      // Send cancellation notification to attendees
      try {
        await _notificationService.sendMeetingNotification(
          meetingId: meetingId,
          title: meeting.title,
          attendeeIds: meeting.attendeeIds,
          notifType: 'cancelled',
          meetingTime: meeting.startTime,
        );
      } catch (e) {
        print('Failed to send meeting cancellation notification: $e');
      }
    }
  }

  Future<MeetingModel?> getMeetingById(String meetingId) async {
    final doc = await _firestore.collection('meetings').doc(meetingId).get();
    if (!doc.exists) return null;
    return MeetingModel.fromMap(doc.data()!);
  }

  Future<void> updateMeetingStatus(String meetingId, MeetingStatus status) async {
    await _firestore.collection('meetings').doc(meetingId).update({
      'status': status.toString(),
    });
  }

  // Stream for today's meetings (real-time updates)
  Stream<List<MeetingModel>> getTodaysMeetingsStream(String userId) {
    final DateTime today = DateTime.now();
    final DateTime startOfDay = DateTime(today.year, today.month, today.day);
    final DateTime endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection('meetings')
        .where('attendeeIds', arrayContains: userId)
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThanOrEqualTo: endOfDay)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data()))
            .toList());
  }

  // Future version for compatibility
  Future<List<MeetingModel>> getTodaysMeetings(String userId) async {
    final DateTime today = DateTime.now();
    final DateTime startOfDay = DateTime(today.year, today.month, today.day);
    final DateTime endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final QuerySnapshot snapshot = await _firestore
        .collection('meetings')
        .where('attendeeIds', arrayContains: userId)
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThanOrEqualTo: endOfDay)
        .orderBy('startTime')
        .get();

    return snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream for upcoming meetings (real-time updates)
  Stream<List<MeetingModel>> getUpcomingMeetingsStream(String userId) {
    final DateTime now = DateTime.now();

    return _firestore
        .collection('meetings')
        .where('attendeeIds', arrayContains: userId)
        .where('startTime', isGreaterThan: now)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data()))
            .toList());
  }

  // Future version for compatibility
  Future<List<MeetingModel>> getUpcomingMeetings(String userId, {int limit = 5}) async {
    final DateTime now = DateTime.now();

    final QuerySnapshot snapshot = await _firestore
        .collection('meetings')
        .where('attendeeIds', arrayContains: userId)
        .where('startTime', isGreaterThan: now)
        .orderBy('startTime')
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream for past meetings (real-time updates)
  Stream<List<MeetingModel>> getPastMeetingsStream(String userId) {
    final DateTime now = DateTime.now();
    final DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return _firestore
        .collection('meetings')
        .where('attendeeIds', arrayContains: userId)
        .where('startTime', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .where('startTime', isLessThan: now)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeetingModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> _scheduleMeetingReminder({
    required String meetingId,
    required String title,
    required List<String> attendeeIds,
    required DateTime reminderTime,
    required DateTime meetingTime,
  }) async {
    await _firestore.collection('meeting_reminders').doc(meetingId).set({
      'meetingId': meetingId,
      'title': title,
      'attendeeIds': attendeeIds,
      'reminderTime': reminderTime,
      'meetingTime': meetingTime,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendMeetingReminders() async {
    final now = DateTime.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);

    final QuerySnapshot reminders = await _firestore
        .collection('meeting_reminders')
        .where('isActive', isEqualTo: true)
        .where('reminderTime', isLessThan: nextMinute)
        .get();

    for (var doc in reminders.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final meetingId = data['meetingId'] as String;
      final title = data['title'] as String;
      final attendeeIds = List<String>.from(data['attendeeIds']);
      final meetingTime = (data['meetingTime'] as Timestamp).toDate();

      try {
        await _notificationService.sendMeetingNotification(
          meetingId: meetingId,
          title: title,
          attendeeIds: attendeeIds,
          notifType: 'reminder',
          meetingTime: meetingTime,
        );

        await doc.reference.update({'isActive': false});
      } catch (e) {
        print('Failed to send meeting reminder: $e');
      }
    }
  }

  Future<List<MeetingModel>> getMeetingsInRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('meetings')
        .where('attendeeIds', arrayContains: userId)
        .where('startTime', isGreaterThanOrEqualTo: start)
        .where('startTime', isLessThanOrEqualTo: end)
        .orderBy('startTime')
        .get();

    return snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCalendarEvents(String userId) async {
    final meetings = await getUpcomingMeetings(userId, limit: 100);

    return meetings.map((meeting) => {
      'id': meeting.id,
      'title': meeting.title,
      'description': meeting.description,
      'start': meeting.startTime.toIso8601String(),
      'end': meeting.endTime.toIso8601String(),
      'location': meeting.location,
      'organizer': meeting.organizerName,
      'attendees': meeting.attendeeNames,
      'status': meeting.status.toString(),
    }).toList();
  }
}