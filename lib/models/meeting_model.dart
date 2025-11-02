import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingModel {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String organizerId;
  final String organizerName;
  final List<String> attendeeIds;
  final List<String> attendeeNames;
  final MeetingStatus status;
  final DateTime createdAt;
  final DateTime? reminderTime;

  MeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.organizerId,
    required this.organizerName,
    required this.attendeeIds,
    required this.attendeeNames,
    this.status = MeetingStatus.scheduled,
    required this.createdAt,
    this.reminderTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'attendeeIds': attendeeIds,
      'attendeeNames': attendeeNames,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
    };
  }

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      attendeeIds: List<String>.from(map['attendeeIds'] ?? []),
      attendeeNames: List<String>.from(map['attendeeNames'] ?? []),
      status: MeetingStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => MeetingStatus.scheduled,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reminderTime: map['reminderTime'] != null
          ? (map['reminderTime'] as Timestamp).toDate()
          : null,
    );
  }
}

enum MeetingStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}