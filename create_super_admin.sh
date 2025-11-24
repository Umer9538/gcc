#!/bin/bash

# Firebase project details
PROJECT_ID="gcc-connect-44b69"
API_KEY="AIzaSyBvZ6O-B7rHmycjy63SPNQkLzVam-5eohs"

# Super Admin credentials
EMAIL="admin@gcc.com"
PASSWORD="GCC@Admin2024"

echo "🚀 Creating Super Admin Account..."
echo ""

# Step 1: Create Firebase Auth user
echo "Step 1: Creating Firebase Auth account..."
SIGNUP_RESPONSE=$(curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"returnSecureToken\": true
  }")

# Check if user already exists
if echo "$SIGNUP_RESPONSE" | grep -q "EMAIL_EXISTS"; then
  echo "⚠️  Account already exists, signing in..."

  # Sign in to get the token and user ID
  SIGNIN_RESPONSE=$(curl -s -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$API_KEY" \
    -H 'Content-Type: application/json' \
    -d "{
      \"email\": \"$EMAIL\",
      \"password\": \"$PASSWORD\",
      \"returnSecureToken\": true
    }")

  USER_ID=$(echo "$SIGNIN_RESPONSE" | grep -o '"localId":"[^"]*' | cut -d'"' -f4)
  ID_TOKEN=$(echo "$SIGNIN_RESPONSE" | grep -o '"idToken":"[^"]*' | cut -d'"' -f4)

  if [ -z "$USER_ID" ]; then
    echo "❌ Failed to sign in. Please check if the password is correct."
    echo "Response: $SIGNIN_RESPONSE"
    exit 1
  fi

  echo "✅ Signed in successfully"
else
  # Extract user ID and token from signup response
  USER_ID=$(echo "$SIGNUP_RESPONSE" | grep -o '"localId":"[^"]*' | cut -d'"' -f4)
  ID_TOKEN=$(echo "$SIGNUP_RESPONSE" | grep -o '"idToken":"[^"]*' | cut -d'"' -f4)

  if [ -z "$USER_ID" ]; then
    echo "❌ Failed to create account"
    echo "Response: $SIGNUP_RESPONSE"
    exit 1
  fi

  echo "✅ Auth account created"
fi

echo "   User ID: $USER_ID"
echo ""

# Step 2: Create Firestore document with Super Admin role
echo "Step 2: Creating Firestore user document..."

# Use Firebase CLI to add the document
firebase firestore:set "users/$USER_ID" \
  --project "$PROJECT_ID" \
  --data '{
    "id": "'$USER_ID'",
    "email": "admin@gcc.com",
    "firstName": "Super",
    "lastName": "Administrator",
    "fullName": "Super Administrator",
    "department": "Administration",
    "position": "Super Admin",
    "phoneNumber": "+966500000000",
    "roles": ["super_admin"],
    "isActive": true,
    "profileImageUrl": "",
    "createdAt": {"_seconds": '$(date +%s)', "_nanoseconds": 0},
    "lastLogin": {"_seconds": '$(date +%s)', "_nanoseconds": 0}
  }' 2>&1

if [ $? -eq 0 ]; then
  echo "✅ Firestore document created"
else
  echo "⚠️  Firestore command failed, trying alternative method..."

  # Try using REST API
  curl -s -X PATCH \
    "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents/users/$USER_ID?updateMask.fieldPaths=id&updateMask.fieldPaths=email&updateMask.fieldPaths=firstName&updateMask.fieldPaths=lastName&updateMask.fieldPaths=fullName&updateMask.fieldPaths=department&updateMask.fieldPaths=position&updateMask.fieldPaths=phoneNumber&updateMask.fieldPaths=roles&updateMask.fieldPaths=isActive&updateMask.fieldPaths=profileImageUrl" \
    -H "Authorization: Bearer $ID_TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{
      "fields": {
        "id": {"stringValue": "'$USER_ID'"},
        "email": {"stringValue": "admin@gcc.com"},
        "firstName": {"stringValue": "Super"},
        "lastName": {"stringValue": "Administrator"},
        "fullName": {"stringValue": "Super Administrator"},
        "department": {"stringValue": "Administration"},
        "position": {"stringValue": "Super Admin"},
        "phoneNumber": {"stringValue": "+966500000000"},
        "roles": {"arrayValue": {"values": [{"stringValue": "super_admin"}]}},
        "isActive": {"booleanValue": true},
        "profileImageUrl": {"stringValue": ""}
      }
    }' > /dev/null

  echo "✅ Firestore document created via REST API"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "🎉 SUCCESS! Super Admin Account Created"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📋 YOUR CREDENTIALS:"
echo "   Email:    admin@gcc.com"
echo "   Password: GCC@Admin2024"
echo ""
echo "🔗 Login URL: http://localhost:59814"
echo ""
echo "📝 NEXT STEPS:"
echo "   1. Refresh your browser (Ctrl+Shift+R or Cmd+Shift+R)"
echo "   2. Login with the credentials above"
echo "   3. You should see the purple Super Admin Dashboard!"
echo ""
echo "═══════════════════════════════════════════════════════"
