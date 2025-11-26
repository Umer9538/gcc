import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum Permission {
  // Document permissions
  viewDocuments,
  uploadDocuments,
  deleteDocuments,
  approveDocumentRequests,
  manageDocumentCategories,

  // Meeting permissions
  viewMeetings,
  createMeetings,
  editAllMeetings,
  deleteMeetings,
  manageMeetingRooms,

  // Announcement permissions
  viewAnnouncements,
  createAnnouncements,
  editAllAnnouncements,
  deleteAnnouncements,
  manageAnnouncementTargeting,

  // User management permissions
  viewUserDirectory,
  editUserProfiles,
  manageUserRoles,
  deactivateUsers,
  viewUserActivity,

  // Messaging permissions
  sendDirectMessages,
  createGroups,
  manageGroups,
  viewAllMessages,

  // System permissions
  viewSystemLogs,
  manageSystemSettings,
  viewReports,
  exportData,
  manageWorkflows,

  // Notification permissions
  sendNotifications,
  manageNotificationSettings,
}

class RolePermissions {
  final String roleId;
  final String roleName;
  final String description;
  final List<Permission> permissions;
  final int priority; // Higher number = higher priority
  final bool isActive;

  RolePermissions({
    required this.roleId,
    required this.roleName,
    required this.description,
    required this.permissions,
    required this.priority,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'roleId': roleId,
      'roleName': roleName,
      'description': description,
      'permissions': permissions.map((p) => p.toString()).toList(),
      'priority': priority,
      'isActive': isActive,
    };
  }

  factory RolePermissions.fromMap(Map<String, dynamic> map) {
    return RolePermissions(
      roleId: map['roleId'] ?? '',
      roleName: map['roleName'] ?? '',
      description: map['description'] ?? '',
      permissions: (map['permissions'] as List<dynamic>?)
          ?.map((p) => Permission.values.firstWhere(
                (e) => e.toString() == p,
                orElse: () => Permission.viewDocuments,
              ))
          .toList() ?? [],
      priority: map['priority'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }
}

class PermissionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize default roles and permissions
  Future<void> initializeDefaultRoles() async {
    final defaultRoles = _getDefaultRoles();

    for (final role in defaultRoles) {
      await _firestore
          .collection('role_permissions')
          .doc(role.roleId)
          .set(role.toMap(), SetOptions(merge: true));
    }
  }

  // Get user permissions based on their roles
  Future<List<Permission>> getUserPermissions(UserModel user) async {
    final Set<Permission> userPermissions = {};

    for (final roleName in user.roles) {
      final rolePermissions = await getRolePermissions(roleName);
      if (rolePermissions != null) {
        userPermissions.addAll(rolePermissions.permissions);
      }
    }

    return userPermissions.toList();
  }

  // Check if user has specific permission
  Future<bool> hasPermission(UserModel user, Permission permission) async {
    final userPermissions = await getUserPermissions(user);
    return userPermissions.contains(permission);
  }

  // Check if user has any of the specified permissions
  Future<bool> hasAnyPermission(UserModel user, List<Permission> permissions) async {
    final userPermissions = await getUserPermissions(user);
    return permissions.any((permission) => userPermissions.contains(permission));
  }

  // Check if user has all of the specified permissions
  Future<bool> hasAllPermissions(UserModel user, List<Permission> permissions) async {
    final userPermissions = await getUserPermissions(user);
    return permissions.every((permission) => userPermissions.contains(permission));
  }

  // Get role permissions by role name
  Future<RolePermissions?> getRolePermissions(String roleName) async {
    final doc = await _firestore
        .collection('role_permissions')
        .where('roleName', isEqualTo: roleName)
        .limit(1)
        .get();

    if (doc.docs.isEmpty) return null;
    return RolePermissions.fromMap(doc.docs.first.data());
  }

  // Get all available roles
  Stream<List<RolePermissions>> getAllRoles() {
    return _firestore
        .collection('role_permissions')
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RolePermissions.fromMap(doc.data()))
            .toList());
  }

  // Update role permissions
  Future<void> updateRolePermissions(RolePermissions rolePermissions) async {
    await _firestore
        .collection('role_permissions')
        .doc(rolePermissions.roleId)
        .set(rolePermissions.toMap());
  }

  // Create new role
  Future<void> createRole(RolePermissions rolePermissions) async {
    await _firestore
        .collection('role_permissions')
        .doc(rolePermissions.roleId)
        .set(rolePermissions.toMap());
  }

  // Delete role
  Future<void> deleteRole(String roleId) async {
    await _firestore
        .collection('role_permissions')
        .doc(roleId)
        .update({'isActive': false});
  }

  // Get permissions for specific feature
  List<Permission> getDocumentPermissions() {
    return [
      Permission.viewDocuments,
      Permission.uploadDocuments,
      Permission.deleteDocuments,
      Permission.approveDocumentRequests,
      Permission.manageDocumentCategories,
    ];
  }

  List<Permission> getMeetingPermissions() {
    return [
      Permission.viewMeetings,
      Permission.createMeetings,
      Permission.editAllMeetings,
      Permission.deleteMeetings,
      Permission.manageMeetingRooms,
    ];
  }

  List<Permission> getAnnouncementPermissions() {
    return [
      Permission.viewAnnouncements,
      Permission.createAnnouncements,
      Permission.editAllAnnouncements,
      Permission.deleteAnnouncements,
      Permission.manageAnnouncementTargeting,
    ];
  }

  List<Permission> getUserManagementPermissions() {
    return [
      Permission.viewUserDirectory,
      Permission.editUserProfiles,
      Permission.manageUserRoles,
      Permission.deactivateUsers,
      Permission.viewUserActivity,
    ];
  }

  List<Permission> getSystemPermissions() {
    return [
      Permission.viewSystemLogs,
      Permission.manageSystemSettings,
      Permission.viewReports,
      Permission.exportData,
      Permission.manageWorkflows,
    ];
  }

  // Check if user can access specific resource
  Future<bool> canAccessDocument(UserModel user, String documentId) async {
    if (await hasPermission(user, Permission.viewDocuments)) {
      return true;
    }
    return false;
  }

  Future<bool> canModifyMeeting(UserModel user, String meetingId, String meetingOrganizerId) async {
    // User can modify if they're the organizer or have edit all meetings permission
    if (user.id == meetingOrganizerId) return true;
    return await hasPermission(user, Permission.editAllMeetings);
  }

  Future<bool> canDeleteAnnouncement(UserModel user, String announcementAuthorId) async {
    // User can delete if they're the author or have delete all announcements permission
    if (user.id == announcementAuthorId) return true;
    return await hasPermission(user, Permission.deleteAnnouncements);
  }

  // Get user's highest priority role
  Future<RolePermissions?> getHighestPriorityRole(UserModel user) async {
    RolePermissions? highestRole;
    int maxPriority = -1;

    for (final roleName in user.roles) {
      final role = await getRolePermissions(roleName);
      if (role != null && role.priority > maxPriority) {
        maxPriority = role.priority;
        highestRole = role;
      }
    }

    return highestRole;
  }

  // Default roles configuration
  List<RolePermissions> _getDefaultRoles() {
    return [
      // Super Admin
      RolePermissions(
        roleId: 'super_admin',
        roleName: 'Super Admin',
        description: 'Full system access',
        priority: 1000,
        permissions: Permission.values, // All permissions
      ),

      // Admin
      RolePermissions(
        roleId: 'admin',
        roleName: 'Admin',
        description: 'Administrative access',
        priority: 900,
        permissions: [
          Permission.viewDocuments,
          Permission.uploadDocuments,
          Permission.deleteDocuments,
          Permission.approveDocumentRequests,
          Permission.viewMeetings,
          Permission.createMeetings,
          Permission.editAllMeetings,
          Permission.deleteMeetings,
          Permission.viewAnnouncements,
          Permission.createAnnouncements,
          Permission.editAllAnnouncements,
          Permission.deleteAnnouncements,
          Permission.manageAnnouncementTargeting,
          Permission.viewUserDirectory,
          Permission.editUserProfiles,
          Permission.manageUserRoles,
          Permission.sendDirectMessages,
          Permission.createGroups,
          Permission.manageGroups,
          Permission.viewReports,
          Permission.manageWorkflows,
          Permission.sendNotifications,
          Permission.manageNotificationSettings,
        ],
      ),

      // Manager
      RolePermissions(
        roleId: 'manager',
        roleName: 'Manager',
        description: 'Management level access',
        priority: 800,
        permissions: [
          Permission.viewDocuments,
          Permission.uploadDocuments,
          Permission.approveDocumentRequests,
          Permission.viewMeetings,
          Permission.createMeetings,
          Permission.editAllMeetings,
          Permission.viewAnnouncements,
          Permission.createAnnouncements,
          Permission.manageAnnouncementTargeting,
          Permission.viewUserDirectory,
          Permission.sendDirectMessages,
          Permission.createGroups,
          Permission.manageGroups,
          Permission.viewReports,
          Permission.sendNotifications,
        ],
      ),

      // HR
      RolePermissions(
        roleId: 'hr',
        roleName: 'HR',
        description: 'Human Resources access',
        priority: 700,
        permissions: [
          Permission.viewDocuments,
          Permission.uploadDocuments,
          Permission.viewMeetings,
          Permission.createMeetings,
          Permission.viewAnnouncements,
          Permission.createAnnouncements,
          Permission.manageAnnouncementTargeting,
          Permission.viewUserDirectory,
          Permission.editUserProfiles,
          Permission.manageUserRoles,
          Permission.sendDirectMessages,
          Permission.createGroups,
          Permission.sendNotifications,
        ],
      ),

      // Employee
      RolePermissions(
        roleId: 'employee',
        roleName: 'Employee',
        description: 'Standard employee access',
        priority: 100,
        permissions: [
          Permission.viewDocuments,
          Permission.uploadDocuments,
          Permission.viewMeetings,
          Permission.createMeetings,
          Permission.viewAnnouncements,
          Permission.viewUserDirectory,
          Permission.sendDirectMessages,
          Permission.createGroups,
        ],
      ),

      // Guest
      RolePermissions(
        roleId: 'guest',
        roleName: 'Guest',
        description: 'Limited access for guests',
        priority: 50,
        permissions: [
          Permission.viewAnnouncements,
          Permission.viewUserDirectory,
          Permission.sendDirectMessages,
        ],
      ),
    ];
  }
}