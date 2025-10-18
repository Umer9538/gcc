import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import 'permissions_service.dart';
import 'notification_service.dart';

class SecurityEvent {
  final String id;
  final String userId;
  final String userName;
  final SecurityEventType type;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;
  final SecurityLevel severity;

  SecurityEvent({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.description,
    this.metadata = const {},
    required this.timestamp,
    this.ipAddress = '',
    this.userAgent = '',
    this.severity = SecurityLevel.low,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'type': type.toString(),
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'severity': severity.toString(),
    };
  }

  factory SecurityEvent.fromMap(Map<String, dynamic> map) {
    return SecurityEvent(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: SecurityEventType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SecurityEventType.other,
      ),
      description: map['description'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      ipAddress: map['ipAddress'] ?? '',
      userAgent: map['userAgent'] ?? '',
      severity: SecurityLevel.values.firstWhere(
        (e) => e.toString() == map['severity'],
        orElse: () => SecurityLevel.low,
      ),
    );
  }
}

enum SecurityEventType {
  login,
  logout,
  failedLogin,
  passwordChange,
  roleChange,
  permissionDenied,
  documentAccess,
  documentUpload,
  documentDelete,
  meetingCreate,
  meetingDelete,
  announcementCreate,
  announcementDelete,
  userCreated,
  userDeactivated,
  suspiciousActivity,
  dataExport,
  configurationChange,
  other,
}

enum SecurityLevel {
  low,
  medium,
  high,
  critical,
}

class SecurityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PermissionsService _permissionsService = PermissionsService();
  final NotificationService _notificationService = NotificationService();

  // Log security event
  Future<void> logSecurityEvent({
    required String userId,
    required String userName,
    required SecurityEventType type,
    required String description,
    Map<String, dynamic> metadata = const {},
    String ipAddress = '',
    String userAgent = '',
    SecurityLevel severity = SecurityLevel.low,
  }) async {
    final eventId = _generateEventId();

    final event = SecurityEvent(
      id: eventId,
      userId: userId,
      userName: userName,
      type: type,
      description: description,
      metadata: metadata,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      severity: severity,
    );

    await _firestore
        .collection('security_events')
        .doc(eventId)
        .set(event.toMap());

    // Alert administrators for high severity events
    if (severity == SecurityLevel.high || severity == SecurityLevel.critical) {
      await _alertAdministrators(event);
    }

    // Check for suspicious patterns
    await _checkSuspiciousActivity(userId, type);
  }

  // Check if user has permission and log access attempt
  Future<bool> checkPermissionAndLog({
    required UserModel user,
    required Permission permission,
    required String resource,
    String ipAddress = '',
    String userAgent = '',
  }) async {
    final hasPermission = await _permissionsService.hasPermission(user, permission);

    if (!hasPermission) {
      await logSecurityEvent(
        userId: user.id,
        userName: user.fullName,
        type: SecurityEventType.permissionDenied,
        description: 'Permission denied for ${permission.toString()} on $resource',
        metadata: {
          'permission': permission.toString(),
          'resource': resource,
        },
        ipAddress: ipAddress,
        userAgent: userAgent,
        severity: SecurityLevel.medium,
      );
    }

    return hasPermission;
  }

  // Validate document access
  Future<bool> validateDocumentAccess({
    required UserModel user,
    required String documentId,
    required String action,
    String ipAddress = '',
    String userAgent = '',
  }) async {
    Permission requiredPermission;
    SecurityEventType eventType;

    switch (action) {
      case 'view':
        requiredPermission = Permission.viewDocuments;
        eventType = SecurityEventType.documentAccess;
        break;
      case 'upload':
        requiredPermission = Permission.uploadDocuments;
        eventType = SecurityEventType.documentUpload;
        break;
      case 'delete':
        requiredPermission = Permission.deleteDocuments;
        eventType = SecurityEventType.documentDelete;
        break;
      default:
        requiredPermission = Permission.viewDocuments;
        eventType = SecurityEventType.documentAccess;
    }

    final hasAccess = await checkPermissionAndLog(
      user: user,
      permission: requiredPermission,
      resource: 'document:$documentId',
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    if (hasAccess) {
      await logSecurityEvent(
        userId: user.id,
        userName: user.fullName,
        type: eventType,
        description: 'Document $action: $documentId',
        metadata: {
          'documentId': documentId,
          'action': action,
        },
        ipAddress: ipAddress,
        userAgent: userAgent,
      );
    }

    return hasAccess;
  }

  // Log authentication events
  Future<void> logAuthenticationEvent({
    required String userId,
    required String userName,
    required bool successful,
    String ipAddress = '',
    String userAgent = '',
  }) async {
    await logSecurityEvent(
      userId: userId,
      userName: userName,
      type: successful ? SecurityEventType.login : SecurityEventType.failedLogin,
      description: successful ? 'User logged in' : 'Failed login attempt',
      metadata: {
        'successful': successful,
      },
      ipAddress: ipAddress,
      userAgent: userAgent,
      severity: successful ? SecurityLevel.low : SecurityLevel.medium,
    );
  }

  // Track role changes
  Future<void> logRoleChange({
    required String userId,
    required String userName,
    required List<String> oldRoles,
    required List<String> newRoles,
    required String changedBy,
    String ipAddress = '',
    String userAgent = '',
  }) async {
    await logSecurityEvent(
      userId: userId,
      userName: userName,
      type: SecurityEventType.roleChange,
      description: 'User roles changed from $oldRoles to $newRoles by $changedBy',
      metadata: {
        'oldRoles': oldRoles,
        'newRoles': newRoles,
        'changedBy': changedBy,
      },
      ipAddress: ipAddress,
      userAgent: userAgent,
      severity: SecurityLevel.high,
    );
  }

  // Get security events for user
  Stream<List<SecurityEvent>> getUserSecurityEvents(String userId) {
    return _firestore
        .collection('security_events')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SecurityEvent.fromMap(doc.data()))
            .toList());
  }

  // Get all security events (admin only)
  Stream<List<SecurityEvent>> getAllSecurityEvents({
    SecurityLevel? minSeverity,
    SecurityEventType? eventType,
    int limit = 100,
  }) {
    Query query = _firestore
        .collection('security_events')
        .orderBy('timestamp', descending: true);

    if (eventType != null) {
      query = query.where('type', isEqualTo: eventType.toString());
    }

    return query
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      var events = snapshot.docs
          .map((doc) => SecurityEvent.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      if (minSeverity != null) {
        final severityIndex = SecurityLevel.values.indexOf(minSeverity);
        events = events.where((event) {
          final eventSeverityIndex = SecurityLevel.values.indexOf(event.severity);
          return eventSeverityIndex >= severityIndex;
        }).toList();
      }

      return events;
    });
  }

  // Get security statistics
  Future<Map<String, dynamic>> getSecurityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final snapshot = await _firestore
        .collection('security_events')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .get();

    final events = snapshot.docs
        .map((doc) => SecurityEvent.fromMap(doc.data()))
        .toList();

    final stats = <String, dynamic>{
      'totalEvents': events.length,
      'loginAttempts': events.where((e) => e.type == SecurityEventType.login || e.type == SecurityEventType.failedLogin).length,
      'failedLogins': events.where((e) => e.type == SecurityEventType.failedLogin).length,
      'permissionDenials': events.where((e) => e.type == SecurityEventType.permissionDenied).length,
      'documentAccesses': events.where((e) => e.type == SecurityEventType.documentAccess).length,
      'highSeverityEvents': events.where((e) => e.severity == SecurityLevel.high || e.severity == SecurityLevel.critical).length,
    };

    // Calculate success rate
    final totalLogins = stats['loginAttempts'] as int;
    final failedLogins = stats['failedLogins'] as int;
    stats['loginSuccessRate'] = totalLogins > 0 ? ((totalLogins - failedLogins) / totalLogins * 100).toStringAsFixed(1) : '100.0';

    return stats;
  }

  // Check for suspicious activity patterns
  Future<void> _checkSuspiciousActivity(String userId, SecurityEventType eventType) async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    // Check for rapid consecutive failed logins
    if (eventType == SecurityEventType.failedLogin) {
      final recentFailedLogins = await _firestore
          .collection('security_events')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: SecurityEventType.failedLogin.toString())
          .where('timestamp', isGreaterThan: oneHourAgo)
          .get();

      if (recentFailedLogins.docs.length >= 5) {
        await logSecurityEvent(
          userId: userId,
          userName: 'System',
          type: SecurityEventType.suspiciousActivity,
          description: 'Multiple failed login attempts detected',
          metadata: {
            'failedAttempts': recentFailedLogins.docs.length,
            'timeframe': '1 hour',
          },
          severity: SecurityLevel.high,
        );
      }
    }

    // Check for unusual permission denials
    if (eventType == SecurityEventType.permissionDenied) {
      final recentDenials = await _firestore
          .collection('security_events')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: SecurityEventType.permissionDenied.toString())
          .where('timestamp', isGreaterThan: oneHourAgo)
          .get();

      if (recentDenials.docs.length >= 10) {
        await logSecurityEvent(
          userId: userId,
          userName: 'System',
          type: SecurityEventType.suspiciousActivity,
          description: 'Multiple permission denials detected',
          metadata: {
            'denials': recentDenials.docs.length,
            'timeframe': '1 hour',
          },
          severity: SecurityLevel.medium,
        );
      }
    }
  }

  // Alert administrators about critical security events
  Future<void> _alertAdministrators(SecurityEvent event) async {
    try {
      // Get all admin users
      final adminSnapshot = await _firestore
          .collection('users')
          .where('roles', arrayContains: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in adminSnapshot.docs) {
        final adminUser = UserModel.fromMap(doc.data());
        await _notificationService.sendNotificationToUser(
          userId: adminUser.id,
          title: 'Security Alert',
          body: 'High severity security event: ${event.description}',
          type: NotificationType.general,
          priority: NotificationPriority.urgent,
          data: {
            'eventId': event.id,
            'severity': event.severity.toString(),
            'type': event.type.toString(),
          },
        );
      }
    } catch (e) {
      print('Failed to alert administrators: $e');
    }
  }

  // Generate unique event ID
  String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(timestamp + DateTime.now().toString());
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // Clean up old security events (should be called periodically)
  Future<void> cleanupOldEvents({int retentionDays = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    final oldEvents = await _firestore
        .collection('security_events')
        .where('timestamp', isLessThan: cutoffDate)
        .get();

    final batch = _firestore.batch();
    for (final doc in oldEvents.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Export security events for audit purposes
  Future<List<Map<String, dynamic>>> exportSecurityEvents({
    DateTime? startDate,
    DateTime? endDate,
    List<SecurityEventType>? eventTypes,
  }) async {
    Query query = _firestore.collection('security_events');

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query
        .orderBy('timestamp', descending: true)
        .get();

    var events = snapshot.docs
        .map((doc) => SecurityEvent.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    if (eventTypes != null && eventTypes.isNotEmpty) {
      events = events.where((event) => eventTypes.contains(event.type)).toList();
    }

    return events.map((event) => event.toMap()).toList();
  }
}