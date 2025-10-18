import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<UserModel>> getUsersByDepartment(String department) {
    return _firestore
        .collection('users')
        .where('department', isEqualTo: department)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .get();

    final List<UserModel> users = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    return users.where((user) {
      final String searchQuery = query.toLowerCase();
      return user.firstName.toLowerCase().contains(searchQuery) ||
          user.lastName.toLowerCase().contains(searchQuery) ||
          user.fullName.toLowerCase().contains(searchQuery) ||
          user.email.toLowerCase().contains(searchQuery) ||
          user.department.toLowerCase().contains(searchQuery) ||
          user.position.toLowerCase().contains(searchQuery);
    }).toList();
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(userId).update(updates);
  }

  Future<void> updateProfileImage(String userId, String imageUrl) async {
    await _firestore.collection('users').doc(userId).update({
      'profileImageUrl': imageUrl,
    });
  }

  Future<List<String>> getDepartments() async {
    final QuerySnapshot snapshot = await _firestore.collection('users').get();
    final Set<String> departments = <String>{};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['department'] != null) {
        departments.add(data['department']);
      }
    }

    return departments.toList()..sort();
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('roles', arrayContains: role)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserModel>> getAllUsersExcept(String excludeUserId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.id != excludeUserId)
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }
}