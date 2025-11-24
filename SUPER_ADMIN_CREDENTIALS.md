# 🔑 Super Admin Account Setup

## Quick Setup (2 Minutes)

### Step 1: Register Account Through App

1. **Open the app**: http://localhost:59814
2. **Click "Sign Up"** (or navigate to registration page)
3. **Fill in the registration form** with these details:

```
First Name:    Super
Last Name:     Administrator
Email:         admin@gcc.com
Phone:         +966500000000
Department:    Administration
Position:      Super Admin
Password:      GCC@Admin2024
```

4. **Click "Create Account"**
5. The account will be created as an **Employee** (this is normal!)

---

### Step 2: Upgrade to Super Admin (Firebase Console)

1. **Open Firebase Console**: https://console.firebase.google.com/

2. **Select your project** (GCC Connect project)

3. **Go to Firestore Database** (left sidebar → Firestore Database)

4. **Navigate to users collection**:
   - Click on `users` collection
   - Find the document with email `admin@gcc.com`
   - Click on that document

5. **Edit the roles field**:
   - Find the field called `roles`
   - It currently shows: `["employee"]`
   - Click the **pencil icon** (edit)
   - Change it to: `["super_admin"]`
   - Click **Update**

---

### Step 3: Login as Super Admin

1. **Go back to the app**: http://localhost:59814

2. **Completely refresh** the browser page (Ctrl+Shift+R or Cmd+Shift+R)

3. **Login with**:
   - Email: `admin@gcc.com`
   - Password: `GCC@Admin2024`

4. **You should now see**:
   - 🟣 Purple "Super Admin Dashboard"
   - Welcome card with "Super Administrator" badge
   - Statistics showing user counts
   - Management cards (User Management, Announcements, etc.)

---

## ✅ Your Super Admin Credentials

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 Email:    admin@gcc.com
🔑 Password: GCC@Admin2024
🔗 URL:      http://localhost:59814
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

⚠️ **Keep these credentials secure!**

---

## Alternative: Quick Firestore JSON

If you prefer to create the user directly in Firestore, here's the document structure:

**Collection**: `users`
**Document ID**: (Generate from Firebase Auth UID)

```json
{
  "id": "YOUR_FIREBASE_AUTH_UID",
  "email": "admin@gcc.com",
  "firstName": "Super",
  "lastName": "Administrator",
  "fullName": "Super Administrator",
  "department": "Administration",
  "position": "Super Admin",
  "phoneNumber": "+966500000000",
  "roles": ["super_admin"],
  "createdAt": "2024-01-15T10:00:00.000Z",
  "lastLogin": "2024-01-15T10:00:00.000Z",
  "isActive": true,
  "profileImageUrl": ""
}
```

But first you need to create the account in Firebase Auth with email/password!

---

## 🎯 What You Can Do as Super Admin

Once logged in as Super Admin, you can:

### 1. User Management
- View all users
- Search and filter users
- Edit user roles (promote to Admin, HR, Manager)
- Assign multiple roles to users

### 2. Announcements
- Create announcements
- Target specific departments/roles
- Edit and delete announcements

### 3. Dashboard
- View user statistics
- See recent activity
- Monitor system usage

### 4. Future Features
- System settings
- Reports & Analytics
- Audit logs

---

## 🔍 Verification Checklist

After logging in, verify you have Super Admin access:

- [ ] Dashboard shows purple header "Super Admin Dashboard"
- [ ] Welcome card shows "Super Administrator" title
- [ ] See statistics cards (Total Users, Super Admins, etc.)
- [ ] See "User Management" card
- [ ] See "Announcements" card
- [ ] Can click "User Management" and see all users
- [ ] Can edit other users' roles

---

## ❓ Troubleshooting

**Problem**: Still seeing regular dashboard after changing role

**Solution**:
1. Make sure the `roles` field is exactly: `["super_admin"]` (lowercase!)
2. Completely close the browser tab
3. Open a new tab and navigate to http://localhost:59814
4. Clear browser cache (Ctrl+Shift+Delete)
5. Login again

**Problem**: Can't find user in Firestore

**Solution**:
1. Make sure you completed registration in the app first
2. Check Firebase Auth (left sidebar → Authentication)
3. Find the user's UID there
4. Look for that UID in Firestore users collection

**Problem**: Firestore document doesn't exist

**Solution**:
1. The registration might have failed
2. Check browser console for errors
3. Try registering again
4. Check Firebase Auth to confirm account exists

---

## 📞 Need Help?

If you encounter any issues:
1. Check browser console (F12) for errors
2. Check Flutter app console for errors
3. Verify Firebase connection
4. Ensure Firestore security rules allow the operation

---

**Created**: January 2024
**App URL**: http://localhost:59814
**Firebase Console**: https://console.firebase.google.com/
