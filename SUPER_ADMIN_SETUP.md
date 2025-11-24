# Super Admin Setup Guide

## Overview
The GCC Connect app now has a dedicated Super Admin system where:
- **All new registrations** create Employee accounts by default
- **Super Admin** has a special dashboard with full management capabilities
- **Only Super Admin** can manage user roles and promote users to Admin/HR/Manager

## Creating the First Super Admin Account

Since you need at least one Super Admin to manage the system, you have two options:

### Option 1: Create via Firebase Console (Recommended)

1. **Register a normal account** through the app:
   - Go to the registration page
   - Fill in your details
   - This will create an account with `employee` role

2. **Upgrade to Super Admin via Firebase Console**:
   - Open [Firebase Console](https://console.firebase.google.com/)
   - Select your GCC project
   - Go to **Firestore Database**
   - Navigate to the `users` collection
   - Find your user document (by email)
   - Click on the document
   - Find the `roles` field (it should be an array with `["employee"]`)
   - Click **Edit field**
   - Change it to: `["super_admin"]`
   - Click **Update**

3. **Restart the app**:
   - Completely close and restart the Flutter app
   - Login with your account
   - You should now see the Super Admin Dashboard!

### Option 2: Manual Firestore Edit

If you prefer, you can manually create the user document in Firestore:

```json
{
  "id": "your-firebase-auth-uid",
  "email": "admin@gcc.com",
  "fullName": "Super Administrator",
  "firstName": "Super",
  "lastName": "Administrator",
  "department": "Administration",
  "position": "Super Admin",
  "phoneNumber": "+1234567890",
  "roles": ["super_admin"],
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLogin": "2024-01-01T00:00:00.000Z",
  "isActive": true
}
```

## Super Admin Capabilities

Once you have Super Admin access, you can:

### 1. View Dashboard Statistics
- Total users count
- Count by role (Super Admin, Admin, HR, Manager, Employee)
- Recent activity tracking

### 2. User Management
- **View all users** with search and filter
- **Edit user roles** - promote/demote users
- **Assign multiple roles** to users
- View user details and activity

### 3. Announcement Management
- Create announcements visible to all users
- Target specific departments or roles
- Full CRUD operations on announcements

### 4. Access All Features
- Super Admin has access to ALL app features
- Can navigate between Super Admin Dashboard and regular features
- Bottom navigation works the same way

## User Role Hierarchy

```
Super Admin (Full Control)
    ↓
Admin (Can manage announcements, users)
    ↓
HR (Can manage announcements, employee data)
    ↓
Manager (Can manage team, announcements)
    ↓
Employee (Basic access)
```

## Managing Users as Super Admin

1. **Login as Super Admin**
2. **Dashboard** → Click "User Management" card
3. **Search/Filter** users by name, role, department
4. **Click Edit** icon next to any user
5. **Select roles** using checkboxes:
   - You can assign multiple roles
   - At least one role must be selected
6. **Save** changes

The user's permissions will update immediately!

## Important Notes

- ⚠️ **Only create ONE Super Admin initially**
- ✅ Use Super Admin dashboard to promote other users
- 🔒 Keep Super Admin credentials secure
- 📋 Employee accounts are created automatically during registration
- 🎯 Super Admin can create more Super Admins if needed

## Testing the Setup

1. Create a Super Admin account (using Option 1 above)
2. Login as Super Admin
3. You should see:
   - Purple "Super Admin Dashboard" instead of regular dashboard
   - Welcome card with "Super Administrator" badge
   - Statistics cards showing user counts
   - Management cards for User Management and Announcements
   - Recent activity log

4. Test User Management:
   - Click "User Management"
   - Search for a user
   - Edit their role
   - Verify the role was updated in Firestore

5. Test Announcements:
   - Click "Announcements"
   - Create a new announcement
   - Verify employees can see it

## Troubleshooting

**Q: I don't see the Super Admin Dashboard after updating my role**
- Make sure you completely closed and restarted the app
- Verify the `roles` field in Firestore is exactly `["super_admin"]` (lowercase)
- Check that you're logged in with the correct account

**Q: User Management button doesn't appear**
- Verify your user document has `"super_admin"` in the roles array
- Restart the app
- Check browser console for any errors

**Q: Can't edit user roles**
- Ensure you're logged in as Super Admin
- Check Firestore security rules allow Super Admin to update users
- Verify internet connection

## Next Steps

After setting up your Super Admin account:

1. ✅ Create additional admin accounts (promote employees to Admin/HR)
2. ✅ Set up announcements for your organization
3. ✅ Configure user roles based on your org structure
4. ✅ Test all features as different role types

---

**Need Help?** Check the console logs for any errors or contact the development team.
