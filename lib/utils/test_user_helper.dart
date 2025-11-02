import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Helper class to create test users with specific roles
/// USE ONLY FOR DEVELOPMENT/TESTING - REMOVE IN PRODUCTION
class TestUserHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Update current user's role
  static Future<void> updateCurrentUserRole(List<String> roles) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No user is currently logged in');
      return;
    }

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'roles': roles,
      });
      print('✅ Successfully updated user ${currentUser.email} with roles: $roles');
      print('🔄 Please restart the app for changes to take effect');
    } catch (e) {
      print('❌ Error updating user role: $e');
    }
  }

  /// Make current user an Admin
  static Future<void> makeCurrentUserAdmin() async {
    await updateCurrentUserRole(['admin']);
  }

  /// Make current user a Manager
  static Future<void> makeCurrentUserManager() async {
    await updateCurrentUserRole(['manager']);
  }

  /// Make current user both Admin and Manager
  static Future<void> makeCurrentUserAdminAndManager() async {
    await updateCurrentUserRole(['admin', 'manager']);
  }

  /// Make current user an Employee
  static Future<void> makeCurrentUserEmployee() async {
    await updateCurrentUserRole(['employee']);
  }

  /// Get current user's roles
  static Future<List<String>> getCurrentUserRoles() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No user is currently logged in');
      return [];
    }

    try {
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!doc.exists) {
        print('❌ User document not found');
        return [];
      }

      final roles = List<String>.from(doc.data()?['roles'] ?? []);
      print('✅ Current user ${currentUser.email} has roles: $roles');
      return roles;
    } catch (e) {
      print('❌ Error getting user roles: $e');
      return [];
    }
  }

  /// Print current user info (for debugging)
  static Future<void> printCurrentUserInfo() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No user is currently logged in');
      return;
    }

    print('\n========================================');
    print('📧 Email: ${currentUser.email}');
    print('🆔 UID: ${currentUser.uid}');

    try {
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        print('👤 Name: ${data['firstName']} ${data['lastName']}');
        print('🏢 Department: ${data['department']}');
        print('💼 Position: ${data['position']}');
        print('🎭 Roles: ${data['roles']}');
      }
    } catch (e) {
      print('❌ Error getting user data: $e');
    }
    print('========================================\n');
  }

  /// Create a complete test admin user
  static Future<void> createTestAdmin({
    required String email,
    required String password,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Create Firestore user document
      final userModel = UserModel(
        id: uid,
        email: email,
        firstName: 'Test',
        lastName: 'Admin',
        fullName: 'Test Admin',
        department: 'Administration',
        position: 'Administrator',
        phoneNumber: '+1234567890',
        roles: ['admin'],
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());

      print('✅ Test Admin created successfully!');
      print('📧 Email: $email');
      print('🔑 Password: $password');
      print('🎭 Role: Admin');
    } catch (e) {
      print('❌ Error creating test admin: $e');
    }
  }

  /// Create a complete test manager user
  static Future<void> createTestManager({
    required String email,
    required String password,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Create Firestore user document
      final userModel = UserModel(
        id: uid,
        email: email,
        firstName: 'Test',
        lastName: 'Manager',
        fullName: 'Test Manager',
        department: 'Operations',
        position: 'Manager',
        phoneNumber: '+1234567890',
        roles: ['manager'],
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());

      print('✅ Test Manager created successfully!');
      print('📧 Email: $email');
      print('🔑 Password: $password');
      print('🎭 Role: Manager');
    } catch (e) {
      print('❌ Error creating test manager: $e');
    }
  }
}

// ==========================================
// HOW TO USE IN YOUR APP
// ==========================================
//
// Option 1: Check current user's roles
// await TestUserHelper.printCurrentUserInfo();
// await TestUserHelper.getCurrentUserRoles();
//
// Option 2: Update current user to admin
// await TestUserHelper.makeCurrentUserAdmin();
//
// Option 3: Update current user to manager
// await TestUserHelper.makeCurrentUserManager();
//
// Option 4: Create new test users
// await TestUserHelper.createTestAdmin(
//   email: 'admin@test.com',
//   password: 'admin123',
// );
//
// await TestUserHelper.createTestManager(
//   email: 'manager@test.com',
//   password: 'manager123',
// );
//
// ⚠️ IMPORTANT: Remove this file before deploying to production!
// ==========================================
