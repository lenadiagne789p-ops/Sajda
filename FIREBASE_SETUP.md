# Firebase Client Code Setup - Sajda App

This guide will help you deploy your Firestore security rules and indexes to your Firebase project.

## Prerequisites

✅ Firebase project already connected in Dreamflow  
✅ Firebase Authentication enabled (Email/Password & Google Sign-In)  
✅ Cloud Firestore database created

## Files Generated

The following Firebase configuration files have been created in your project root:

1. **`firestore.rules`** - Security rules that control access to your Firestore database
2. **`firestore.indexes.json`** - Composite indexes for efficient queries
3. **`firebase.json`** - Firebase project configuration

## What's Included

### Firebase Client Integration

Your app now includes:

- ✅ **FirestoreService** (`lib/services/firestore_service.dart`) - Complete Firestore data layer
- ✅ **Hybrid StorageService** - Automatically uses Firestore when authenticated, local storage otherwise
- ✅ **User Model** - Updated with Firestore Timestamp support
- ✅ **Auth Integration** - Syncs user profile with Firestore on sign-in/sign-up

### Data Collections

The following Firestore collections are configured:

| Collection | Access | Description |
|------------|--------|-------------|
| `users/{userId}` | Private | User profile and progress |
| `daily_actions/{userId}/actions/{actionId}` | Private | Daily Islamic actions tracking |
| `badges/{userId}/unlocked/{badgeId}` | Private | Unlocked spiritual badges |
| `streaks/{userId}/user_streaks/{streakId}` | Private | Prayer and worship streaks |
| `reminders/{userId}/user_reminders/{reminderId}` | Private | Prayer reminders |
| `quran_reading/{userId}` | Private | Quran reading progress |
| `prayer_completion/{userId}/dates/{dateId}` | Private | Daily prayer completion |
| `leaderboard/{userId}` | Public Read | Global leaderboard |

## Deployment Steps

### Option 1: Deploy via Firebase Console (Recommended for Dreamflow)

Since Dreamflow doesn't provide direct terminal access, follow these steps:

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com
   - Select your project: `vb216y6zl5b5b5yrmy6qpaylmmpgjf`

2. **Deploy Security Rules**
   - Navigate to **Firestore Database** > **Rules** tab
   - Copy the contents of `firestore.rules` (from project root)
   - Paste into the Firebase Console rules editor
   - Click **Publish**

3. **Deploy Indexes**
   - Navigate to **Firestore Database** > **Indexes** tab
   - Click **Add Index** for each index in `firestore.indexes.json`:
   
   **Index 1 - Leaderboard:**
   - Collection: `leaderboard`
   - Fields:
     - `totalHassanat` - Descending
     - `name` - Ascending
   - Query scope: Collection
   
   **Index 2 - Actions:**
   - Collection: `actions`
   - Fields:
     - `date` - Descending
     - `isCompleted` - Ascending
   - Query scope: Collection group
   
   **Index 3 - Streaks:**
   - Collection: `user_streaks`
   - Fields:
     - `isActive` - Descending
     - `currentStreak` - Descending
   - Query scope: Collection group

4. **Verify Deployment**
   - Rules status should show "Published" with a green checkmark
   - Indexes should show "Enabled" status (may take a few minutes to build)

### Option 2: Deploy via Firebase CLI (If You Have Local Access)

If you've downloaded the code and have Firebase CLI installed:

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (select existing project)
firebase init firestore

# Deploy rules and indexes
firebase deploy --only firestore:rules,firestore:indexes
```

## Testing Your Setup

After deploying, test the integration:

1. **Sign In with Google or Email**
   - Open your app in Dreamflow Preview
   - Navigate to Profile > Sign In
   - Sign in with Google or create an email account

2. **Verify Data Sync**
   - Complete an action (e.g., mark a prayer as done)
   - Check Firebase Console > Firestore Database
   - You should see your user document and action data

3. **Check Security Rules**
   - Try accessing data in Firestore Console
   - Only the authenticated user's data should be accessible

## Security Rules Overview

### Private Collections (User-Owned)
All user data is private by default:
- Only the authenticated user can read/write their own data
- User ID must match the document owner ID

### Public Read Collections
Only the leaderboard is publicly readable:
- All authenticated users can view the leaderboard
- Users can only update their own leaderboard entry

## Common Issues & Solutions

### Issue: "Missing or insufficient permissions"

**Cause:** Security rules haven't been deployed or user isn't authenticated

**Solution:**
1. Verify rules are published in Firebase Console
2. Ensure user is signed in (check `auth.FirebaseAuth.instance.currentUser`)
3. Confirm user is accessing their own data (userId matches)

### Issue: "The query requires an index"

**Cause:** Composite index hasn't been created yet

**Solution:**
1. Click the link in the error message (opens Firebase Console)
2. Click "Create Index"
3. Wait for the index to build (1-5 minutes typically)

### Issue: Data not syncing after sign-in

**Cause:** Cache not cleared or user document not created

**Solution:**
1. Sign out and sign in again
2. Check Firestore Console for user document
3. Clear app data in browser DevTools > Application > Storage

## Data Migration

If you had local data before implementing Firestore:

1. **Automatic Migration:** The app automatically uses Firestore when authenticated
2. **Manual Export:** Local data remains in SharedPreferences
3. **Fresh Start:** New users start with default data in Firestore

## Monitoring & Analytics

Track your Firestore usage:

1. **Firestore Dashboard**
   - https://console.firebase.google.com/project/vb216y6zl5b5b5yrmy6qpaylmmpgjf/firestore

2. **Usage Metrics**
   - Reads/Writes per day
   - Storage size
   - Active users

3. **Free Tier Limits**
   - 50,000 document reads/day
   - 20,000 document writes/day
   - 20,000 document deletes/day
   - 1 GB storage

## Next Steps

1. ✅ Deploy security rules and indexes (follow steps above)
2. ✅ Test authentication flow
3. ✅ Verify data sync in Firestore Console
4. ✅ Monitor usage in Firebase Console
5. ✅ Optional: Set up Firebase Cloud Functions for advanced features

## Support

For Firebase-specific issues:
- Firebase Documentation: https://firebase.google.com/docs/firestore
- Firebase Support: https://firebase.google.com/support

For Dreamflow-specific issues:
- Use the "Submit Feedback" button in Dreamflow

---

**Important:** Remember to check the deployment status in the Firebase UI panel (left sidebar) after publishing rules and indexes!
