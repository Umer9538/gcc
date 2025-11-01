# 🔐 GCC Connect - Role-Based Access Control (RBAC) Guide

## Overview

GCC Connect implements a comprehensive **Role-Based Access Control (RBAC)** system that manages who can perform which actions in the platform. This ensures security, data privacy, and proper organizational hierarchy.

---

## 🎭 User Roles

### Role Hierarchy (by priority)

| Priority | Role | Description |
|----------|------|-------------|
| 1000 | Super Admin | Full system access, all permissions |
| 900 | Admin | Administrative access, most features |
| 800 | Manager | Management level, team supervision |
| 700 | HR Manager | HR-specific functions |
| 600 | Department Manager | Department-level management |
| 500 | Team Lead | Team coordination |
| 100 | Employee | Basic user access |

Higher priority roles can typically override lower priority role actions.

---

## 📋 Permissions by Feature

### 1. Announcements

| Permission | Super Admin | Admin | Manager | HR Manager | Dept Manager | Team Lead | Employee |
|-----------|-------------|-------|---------|------------|--------------|-----------|----------|
| View Announcements | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create Announcements | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Edit All Announcements | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Delete Announcements | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Manage Targeting | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

**Who Can Create Announcements:**
- ✅ Super Admin - Company-wide announcements
- ✅ Admin - Company-wide announcements
- ✅ Manager - Department/team announcements

**How to Access:**
- Go to Announcements screen
- If you have permission, you'll see:
  - "+" button in the app bar (top right)
  - Floating action button (bottom right)
- Tap either button to create an announcement

---

### 2. Meetings

| Permission | Super Admin | Admin | Manager | HR Manager | Dept Manager | Team Lead | Employee |
|-----------|-------------|-------|---------|------------|--------------|-----------|----------|
| View Meetings | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create Meetings | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Edit All Meetings | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Delete Meetings | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Manage Meeting Rooms | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

**Special Rules:**
- Anyone can create meetings (all employees)
- Only organizer OR admins/managers can edit meetings
- Only organizer can delete their own meetings

---

### 3. Documents

| Permission | Super Admin | Admin | Manager | HR Manager | Dept Manager | Team Lead | Employee |
|-----------|-------------|-------|---------|------------|--------------|-----------|----------|
| View Documents | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Upload Documents | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Delete Documents | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Approve Document Requests | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Manage Categories | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

**Document Access Rules:**
- Documents have `allowedRoles` and `allowedDepartments`
- Users see only documents they're authorized to access
- Empty arrays = public access
- Request system for restricted documents

---

### 4. User Management

| Permission | Super Admin | Admin | Manager | HR Manager | Dept Manager | Team Lead | Employee |
|-----------|-------------|-------|---------|------------|--------------|-----------|----------|
| View User Directory | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Edit User Profiles | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Manage User Roles | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Deactivate Users | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| View User Activity | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |

**Special Rules:**
- All users can view directory
- All users can edit their own profile
- Only HR Manager and Admins can modify other users

---

### 5. Messaging

| Permission | Super Admin | Admin | Manager | HR Manager | Dept Manager | Team Lead | Employee |
|-----------|-------------|-------|---------|------------|--------------|-----------|----------|
| Send Direct Messages | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create Groups | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Manage Groups | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| View All Messages | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

**Rules:**
- All employees can send direct messages
- Team Leads+ can create groups
- Department Managers+ can manage groups

---

### 6. System & Reports

| Permission | Super Admin | Admin | Manager | HR Manager | Dept Manager | Team Lead | Employee |
|-----------|-------------|-------|---------|------------|--------------|-----------|----------|
| View System Logs | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Manage System Settings | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| View Reports | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Export Data | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Manage Workflows | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |

---

### 7. Notifications

| Permission | Super Admin | Admin | Manager | HR Manager | Dept Manager | Team Lead | Employee |
|-----------|-------------|-------|---------|------------|--------------|-----------|----------|
| Send Notifications | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Manage Notification Settings | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |

---

## 🔧 How It Works

### 1. Permission Check Flow

```dart
// 1. Get current user
final currentUser = authProvider.currentUser;

// 2. Check permission
final canCreate = await permissionsService.hasPermission(
  currentUser,
  Permission.createAnnouncements,
);

// 3. Show/hide UI based on permission
if (canCreate) {
  // Show "Create" button
}
```

### 2. Where Permissions Are Defined

**File:** `lib/services/permissions_service.dart`

```dart
// Example: Admin permissions
RolePermissions(
  roleId: 'admin',
  roleName: 'Admin',
  priority: 900,
  permissions: [
    Permission.createAnnouncements,
    Permission.editAllAnnouncements,
    Permission.deleteAnnouncements,
    // ... more permissions
  ],
)
```

### 3. Permission Enum

**All Available Permissions:**

```dart
enum Permission {
  // Documents
  viewDocuments,
  uploadDocuments,
  deleteDocuments,
  approveDocumentRequests,
  manageDocumentCategories,

  // Meetings
  viewMeetings,
  createMeetings,
  editAllMeetings,
  deleteMeetings,
  manageMeetingRooms,

  // Announcements
  viewAnnouncements,
  createAnnouncements,
  editAllAnnouncements,
  deleteAnnouncements,
  manageAnnouncementTargeting,

  // Users
  viewUserDirectory,
  editUserProfiles,
  manageUserRoles,
  deactivateUsers,
  viewUserActivity,

  // Messaging
  sendDirectMessages,
  createGroups,
  manageGroups,
  viewAllMessages,

  // System
  viewSystemLogs,
  manageSystemSettings,
  viewReports,
  exportData,
  manageWorkflows,

  // Notifications
  sendNotifications,
  manageNotificationSettings,
}
```

---

## 🎯 Common Use Cases

### Use Case 1: Manager Wants to Send Announcement

**Scenario:** A department manager wants to announce a team meeting.

**Steps:**
1. Manager logs in
2. Goes to Announcements screen
3. Sees "+" button (because they have `createAnnouncements` permission)
4. Taps "+" button
5. Fills in announcement details
6. Selects target: "Department: Finance"
7. Sends announcement

**Result:** Only Finance department employees see the announcement.

---

### Use Case 2: Employee Wants to Create Announcement

**Scenario:** Regular employee tries to create an announcement.

**Steps:**
1. Employee logs in
2. Goes to Announcements screen
3. **Does NOT see "+" button** (no `createAnnouncements` permission)
4. Can only view announcements

**Result:** Employee cannot create announcements, maintaining organizational hierarchy.

---

### Use Case 3: HR Manager Managing Users

**Scenario:** HR wants to update employee information.

**Steps:**
1. HR Manager logs in
2. Goes to Employee Directory
3. Searches for employee
4. Taps employee profile
5. Sees "Edit" button (because of `editUserProfiles` permission)
6. Updates employee details
7. Saves changes

**Result:** Employee information updated successfully.

---

## 🔒 Security Best Practices

### 1. Client-Side Checks (UI Only)

Current implementation checks permissions on the client side to show/hide UI elements. This is for UX purposes only.

**IMPORTANT:** Always validate permissions on the backend!

### 2. Firebase Security Rules

Add server-side validation in Firestore security rules:

```javascript
// Example: Announcements security rules
match /announcements/{announcementId} {
  // Anyone can read
  allow read: if request.auth != null;

  // Only admins and managers can create
  allow create: if request.auth != null &&
                 (hasRole('admin') || hasRole('manager'));

  // Only admin or author can update/delete
  allow update, delete: if request.auth != null &&
                          (hasRole('admin') ||
                           resource.data.authorId == request.auth.uid);
}

function hasRole(role) {
  return get(/databases/$(database)/documents/users/$(request.auth.uid))
         .data.roles.hasAny([role]);
}
```

### 3. API Endpoint Validation

For any backend API calls, validate permissions server-side:

```dart
// Server-side example (Cloud Functions)
exports.createAnnouncement = functions.https.onCall(async (data, context) {
  // 1. Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated');
  }

  // 2. Get user and check permissions
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();

  const userRoles = userDoc.data().roles;

  if (!userRoles.includes('admin') && !userRoles.includes('manager')) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins and managers can create announcements'
    );
  }

  // 3. Create announcement
  // ... rest of the logic
});
```

---

## 🛠️ Customizing Permissions

### Adding a New Role

**File:** `lib/services/permissions_service.dart`

```dart
// Add to _getDefaultRoles() method
RolePermissions(
  roleId: 'custom_role',
  roleName: 'Custom Role Name',
  description: 'Description of the role',
  priority: 750, // Between Manager (800) and HR Manager (700)
  permissions: [
    Permission.viewDocuments,
    Permission.createMeetings,
    Permission.sendDirectMessages,
    // Add specific permissions
  ],
),
```

### Adding a New Permission

1. **Add to Permission enum:**
```dart
enum Permission {
  // ... existing permissions
  customFeatureAccess, // New permission
}
```

2. **Add to role configurations:**
```dart
RolePermissions(
  roleId: 'admin',
  // ...
  permissions: [
    // ... existing
    Permission.customFeatureAccess, // Add here
  ],
)
```

3. **Use in UI:**
```dart
final canAccess = await permissionsService.hasPermission(
  currentUser,
  Permission.customFeatureAccess,
);

if (canAccess) {
  // Show custom feature
}
```

---

## 📊 Permission Management UI

### For Administrators

Consider building an admin panel to manage permissions dynamically:

```dart
// Example admin screen to modify role permissions
class RoleManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RolePermissions>>(
      stream: permissionsService.getAllRoles(),
      builder: (context, snapshot) {
        // Show list of roles
        // Allow editing permissions
        // Save to Firestore
      },
    );
  }
}
```

---

## 🐛 Troubleshooting

### Issue: Button doesn't appear even though user has correct role

**Solutions:**
1. Check if permission check is async and completes before UI builds
2. Verify user's roles array includes the correct role
3. Check Firestore `role_permissions` collection is initialized
4. Call `permissionsService.initializeDefaultRoles()` once

### Issue: Permission check always returns false

**Solutions:**
1. Verify UserModel.roles is populated correctly
2. Check Firebase authentication is working
3. Ensure role names match exactly (case-sensitive)
4. Initialize default roles: `await permissionsService.initializeDefaultRoles()`

### Issue: Changes to permissions not reflecting

**Solutions:**
1. Restart the app (permissions are cached)
2. Sign out and sign back in
3. Check Firestore console for role_permissions collection
4. Verify permission strings match exactly

---

## 📚 References

- **Permissions Service:** `lib/services/permissions_service.dart`
- **User Model:** `lib/models/user_model.dart`
- **Auth Provider:** `lib/providers/auth_provider.dart`
- **Announcements Screen:** `lib/screens/announcements/announcements_screen.dart`

---

## ✅ Summary

| Feature | RBAC Status |
|---------|------------|
| Announcements | ✅ Fully Implemented |
| Meetings | ✅ Fully Implemented |
| Documents | ✅ Fully Implemented |
| User Management | ✅ Fully Implemented |
| Messaging | ✅ Fully Implemented |
| System Features | ✅ Fully Implemented |
| Notifications | ✅ Fully Implemented |

**Total Permissions:** 49 granular permissions across 6 roles

**Security:** Client-side UI control + Backend validation recommended

---

**Last Updated:** 2024
**Version:** 1.0.0

For questions or issues, refer to the codebase or contact the development team.
