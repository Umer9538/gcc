// Firebase Admin SDK script to create Super Admin account
// Run with: node create_admin.js

const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const firestore = admin.firestore();

async function createSuperAdmin() {
  console.log('🚀 Creating Super Admin Account...\n');

  const email = 'admin@gcc.com';
  const password = 'GCC@Admin2024';
  const userData = {
    firstName: 'Super',
    lastName: 'Administrator',
    fullName: 'Super Administrator',
    department: 'Administration',
    position: 'Super Admin',
    phoneNumber: '+966500000000',
  };

  try {
    // Step 1: Create or get Firebase Auth user
    console.log('Step 1: Creating Firebase Auth user...');
    let userRecord;

    try {
      // Try to create new user
      userRecord = await auth.createUser({
        email: email,
        password: password,
        displayName: userData.fullName,
      });
      console.log('✅ Auth user created:', userRecord.uid);
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log('⚠️  User already exists, getting existing user...');
        userRecord = await auth.getUserByEmail(email);
        console.log('✅ Found existing user:', userRecord.uid);

        // Update password
        await auth.updateUser(userRecord.uid, { password: password });
        console.log('✅ Password updated');
      } else {
        throw error;
      }
    }

    const userId = userRecord.uid;

    // Step 2: Create/Update Firestore document
    console.log('\nStep 2: Creating Firestore user document...');
    await firestore.collection('users').doc(userId).set({
      id: userId,
      email: email,
      firstName: userData.firstName,
      lastName: userData.lastName,
      fullName: userData.fullName,
      department: userData.department,
      position: userData.position,
      phoneNumber: userData.phoneNumber,
      roles: ['super_admin'], // Super Admin role
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      profileImageUrl: '',
    }, { merge: true });
    console.log('✅ Firestore document created/updated');

    // Step 3: Verify
    console.log('\nStep 3: Verifying account...');
    const userDoc = await firestore.collection('users').doc(userId).get();
    const firestoreData = userDoc.data();

    console.log('\n═══════════════════════════════════════════════════════');
    console.log('🎉 SUCCESS! Super Admin Account Created');
    console.log('═══════════════════════════════════════════════════════');
    console.log('');
    console.log('📋 ACCOUNT DETAILS:');
    console.log(`   UID:        ${userId}`);
    console.log(`   Name:       ${firestoreData.fullName}`);
    console.log(`   Email:      ${firestoreData.email}`);
    console.log(`   Roles:      ${firestoreData.roles.join(', ')}`);
    console.log(`   Department: ${firestoreData.department}`);
    console.log(`   Position:   ${firestoreData.position}`);
    console.log('');
    console.log('🔑 LOGIN CREDENTIALS:');
    console.log(`   Email:    ${email}`);
    console.log(`   Password: ${password}`);
    console.log('');
    console.log('🔗 Login URL: http://localhost:59814');
    console.log('');
    console.log('⚠️  IMPORTANT:');
    console.log('   1. Refresh your browser');
    console.log('   2. Login with the credentials above');
    console.log('   3. You should see the Super Admin Dashboard');
    console.log('═══════════════════════════════════════════════════════');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.code) {
      console.error('Error Code:', error.code);
    }
    process.exit(1);
  }

  process.exit(0);
}

// Run the function
createSuperAdmin();
