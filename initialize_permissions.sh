#!/bin/bash

PROJECT_ID="gcc-connect-44b69"
BASE_URL="https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents/role_permissions"

echo "🚀 Initializing Role Permissions in Firestore..."
echo ""

# Super Admin - All permissions
echo "1. Creating Super Admin permissions..."
curl -s -X PATCH "$BASE_URL/super_admin" \
  -H "Content-Type: application/json" \
  -d '{
  "fields": {
    "roleId": {"stringValue": "super_admin"},
    "roleName": {"stringValue": "super_admin"},
    "description": {"stringValue": "Full system access"},
    "priority": {"integerValue": "1000"},
    "isActive": {"booleanValue": true},
    "permissions": {"arrayValue": {"values": [
      {"stringValue": "Permission.createAnnouncements"},
      {"stringValue": "Permission.uploadDocuments"}
    ]}}
  }
}' > /dev/null && echo "✅ Super Admin permissions created"

# Admin
echo "2. Creating Admin permissions..."
curl -s -X PATCH "$BASE_URL/admin" \
  -H "Content-Type: application/json" \
  -d '{
  "fields": {
    "roleId": {"stringValue": "admin"},
    "roleName": {"stringValue": "admin"},
    "description": {"stringValue": "Administrative access"},
    "priority": {"integerValue": "900"},
    "isActive": {"booleanValue": true},
    "permissions": {"arrayValue": {"values": [
      {"stringValue": "Permission.createAnnouncements"},
      {"stringValue": "Permission.uploadDocuments"}
    ]}}
  }
}' > /dev/null && echo "✅ Admin permissions created"

# HR
echo "3. Creating HR permissions..."
curl -s -X PATCH "$BASE_URL/hr" \
  -H "Content-Type: application/json" \
  -d '{
  "fields": {
    "roleId": {"stringValue": "hr"},
    "roleName": {"stringValue": "hr"},
    "description": {"stringValue": "Human Resources access"},
    "priority": {"integerValue": "700"},
    "isActive": {"booleanValue": true},
    "permissions": {"arrayValue": {"values": [
      {"stringValue": "Permission.createAnnouncements"},
      {"stringValue": "Permission.uploadDocuments"}
    ]}}
  }
}' > /dev/null && echo "✅ HR permissions created"

# Manager
echo "4. Creating Manager permissions..."
curl -s -X PATCH "$BASE_URL/manager" \
  -H "Content-Type: application/json" \
  -d '{
  "fields": {
    "roleId": {"stringValue": "manager"},
    "roleName": {"stringValue": "manager"},
    "description": {"stringValue": "Management level access"},
    "priority": {"integerValue": "800"},
    "isActive": {"booleanValue": true},
    "permissions": {"arrayValue": {"values": [
      {"stringValue": "Permission.createAnnouncements"},
      {"stringValue": "Permission.uploadDocuments"}
    ]}}
  }
}' > /dev/null && echo "✅ Manager permissions created"

# Employee
echo "5. Creating Employee permissions..."
curl -s -X PATCH "$BASE_URL/employee" \
  -H "Content-Type: application/json" \
  -d '{
  "fields": {
    "roleId": {"stringValue": "employee"},
    "roleName": {"stringValue": "employee"},
    "description": {"stringValue": "Standard employee access"},
    "priority": {"integerValue": "100"},
    "isActive": {"booleanValue": true},
    "permissions": {"arrayValue": {"values": [
      {"stringValue": "Permission.viewAnnouncements"}
    ]}}
  }
}' > /dev/null && echo "✅ Employee permissions created"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ ALL ROLE PERMISSIONS INITIALIZED"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📝 Roles created:"
echo "   • super_admin (Priority: 1000) - CAN CREATE ANNOUNCEMENTS"
echo "   • admin       (Priority: 900)  - CAN CREATE ANNOUNCEMENTS"
echo "   • manager     (Priority: 800)  - CAN CREATE ANNOUNCEMENTS"
echo "   • hr          (Priority: 700)  - CAN CREATE ANNOUNCEMENTS"
echo "   • employee    (Priority: 100)  - Can only view announcements"
echo ""
echo "🔄 REFRESH YOUR BROWSER to see the changes!"
echo "   The '+' button should now appear in Announcements screen"
echo "═══════════════════════════════════════════════════════"
