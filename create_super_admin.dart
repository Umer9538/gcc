import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to create the first Super Admin account
/// Run this file with: dart run create_super_admin.dart

void main() async {
  print('🚀 Creating Super Admin Account...\n');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized\n');

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // Super Admin Credentials
    const email = 'admin@gcc.com';
    const password = 'GCC@Admin2024';
    const firstName = 'Super';
    const lastName = 'Administrator';
    const fullName = 'Super Administrator';
    const department = 'Administration';
    const position = 'Super Admin';
    const phoneNumber = '+966500000000';

    print('📧 Email: $email');
    print('🔑 Password: $password\n');

    // Step 1: Create Firebase Auth user
    print('Step 1: Creating Firebase Auth account...');
    UserCredential userCredential;

    try {
      userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Auth account created: ${userCredential.user?.uid}\n');
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        print('⚠️  Account already exists, signing in...');
        userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Signed in: ${userCredential.user?.uid}\n');
      } else {
        throw e;
      }
    }

    final userId = userCredential.user!.uid;

    // Step 2: Create/Update Firestore user document with Super Admin role
    print('Step 2: Creating Firestore user document...');
    await firestore.collection('users').doc(userId).set({
      'id': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'department': department,
      'position': position,
      'phoneNumber': phoneNumber,
      'roles': ['super_admin'], // Super Admin role
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'isActive': true,
      'profileImageUrl': '',
    });
    print('✅ Firestore document created\n');

    // Step 3: Verify the account
    print('Step 3: Verifying account...');
    final userDoc = await firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    print('✅ Account verified:');
    print('   Name: ${userData?['fullName']}');
    print('   Email: ${userData?['email']}');
    print('   Roles: ${userData?['roles']}');
    print('   Department: ${userData?['department']}\n');

    print('═══════════════════════════════════════════════════════');
    print('🎉 SUCCESS! Super Admin Account Created');
    print('═══════════════════════════════════════════════════════');
    print('');
    print('📋 YOUR CREDENTIALS:');
    print('   Email:    $email');
    print('   Password: $password');
    print('');
    print('🔗 Login at: http://localhost:59814');
    print('');
    print('⚠️  IMPORTANT: Keep these credentials secure!');
    print('═══════════════════════════════════════════════════════');

  } catch (e, stackTrace) {
    print('❌ Error creating Super Admin account:');
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
