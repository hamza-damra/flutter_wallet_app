# flutter_wallet_app

A Flutter wallet application for tracking income and expenses.

## Getting Started

This project is a Flutter application for personal finance management.

### Prerequisites

- Flutter SDK (^3.10.4)
- Firebase project with Android app configured
- Android Studio or VS Code

### Installation

1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase (see below)
4. Run `flutter run`

---

## Push Update Feature

This app includes a **Push Update** feature that notifies users when a new version is available and prompts them to download and install it manually.

### How It Works

1. **Remote Config**: Version information is stored in Firebase Remote Config
2. **FCM Push Notifications**: Users are notified via push when a new version is released
3. **Update Dialog**: When the user taps the notification or opens the app, they see an update dialog
4. **Manual Install**: The user is directed to download the APK from a provided HTTPS URL

### Firebase Remote Config Setup

1. Go to [Firebase Console](https://console.firebase.google.com) → Your Project → Remote Config

2. Add the following parameters:

   | Parameter Key | Type | Default Value | Description |
   |---------------|------|---------------|-------------|
   | `latest_version_name` | String | `1.0.0` | Display version (e.g., "1.4.2") |
   | `latest_version_code` | Number | `1` | Android versionCode/buildNumber |
   | `apk_url` | String | `` | Direct HTTPS link to APK download |
   | `force_update` | Boolean | `false` | If true, user cannot skip update |
   | `update_message` | String | `A new version is available with bug fixes and improvements.` | Message shown in dialog |
   | `min_supported_version_code` | Number | `1` | Minimum version code required (below this = forced update) |

3. Click **Publish changes**

### Hosting Your APK

You need a stable HTTPS link for your APK. Options include:

1. **GitHub Releases** (Recommended for free tier):
   - Go to your GitHub repo → Releases → Create new release
   - Upload the APK file
   - Use the direct download link: `https://github.com/your-username/your-repo/releases/download/v1.0.0/app-release.apk`

2. **Firebase Hosting**:
   - Deploy APK to Firebase Hosting
   - Use the hosting URL

3. **Google Cloud Storage / AWS S3**:
   - Upload APK to bucket with public read access
   - Use the direct link

4. **Your own web server**:
   - Host the APK on any HTTPS server

⚠️ **Important**: The APK URL must be HTTPS for security.

### Sending Update Notifications

#### Option 1: Firebase Console (Manual)

1. Go to [Firebase Console](https://console.firebase.google.com) → Your Project → Cloud Messaging
2. Click **New Campaign** → **Notifications**
3. Enter notification details:
   - **Title**: "Update Available" (or "تحديث متوفر" for Arabic)
   - **Body**: "A new version is available. Tap to update."
4. Target: Topic → Enter `all`
5. Additional options → Custom data:
   ```
   Key: type
   Value: update
   ```
6. Click **Review** → **Publish**

#### Option 2: Cloud Function (Automated)

Deploy a Cloud Function to send notifications programmatically:

```javascript
// functions/index.js
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * HTTP Cloud Function to send update notification to all users
 * 
 * Call: POST https://your-region-your-project.cloudfunctions.net/sendUpdateNotification
 * Body: { "versionName": "1.4.2", "versionCode": 42, "message": "Bug fixes and improvements" }
 */
exports.sendUpdateNotification = require('firebase-functions')
  .https.onRequest(async (req, res) => {
    // Basic auth check (replace with your method)
    const authKey = req.headers['x-api-key'];
    if (authKey !== process.env.UPDATE_API_KEY) {
      return res.status(403).send('Unauthorized');
    }

    const { versionName, versionCode, message } = req.body;

    if (!versionName || !versionCode) {
      return res.status(400).send('Missing versionName or versionCode');
    }

    const notification = {
      notification: {
        title: 'Update Available',
        body: message || `Version ${versionName} is now available. Tap to update.`,
      },
      data: {
        type: 'update',
        versionCode: String(versionCode),
        versionName: versionName,
      },
      topic: 'all',
    };

    try {
      const response = await admin.messaging().send(notification);
      console.log('Update notification sent:', response);
      return res.status(200).json({ success: true, messageId: response });
    } catch (error) {
      console.error('Error sending notification:', error);
      return res.status(500).json({ success: false, error: error.message });
    }
  });
```

Deploy: `firebase deploy --only functions:sendUpdateNotification`

#### Option 3: Server-side Script

Use this cURL command to send notifications from any server:

```bash
# Get your Server Key from Firebase Console → Project Settings → Cloud Messaging
curl -X POST "https://fcm.googleapis.com/fcm/send" \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "/topics/all",
    "notification": {
      "title": "Update Available",
      "body": "Version 1.4.2 is now available with bug fixes and improvements."
    },
    "data": {
      "type": "update"
    }
  }'
```

### Release Checklist

When releasing a new version:

1. ✅ Update version in `pubspec.yaml`:
   ```yaml
   version: 1.4.2+42  # versionName+versionCode
   ```

2. ✅ Build release APK:
   ```bash
   flutter build apk --release
   ```

3. ✅ Upload APK to your hosting (GitHub Releases, etc.)

4. ✅ Update Firebase Remote Config:
   - `latest_version_name` → "1.4.2"
   - `latest_version_code` → 42
   - `apk_url` → Your new APK download URL
   - `update_message` → What's new in this version
   - `force_update` → false (or true for critical updates)

5. ✅ Send push notification to `all` topic

### Testing the Update Feature

1. **Test without real update**:
   - Set `latest_version_code` in Remote Config higher than your installed version
   - Launch the app — update dialog should appear

2. **Test forced update**:
   - Set `force_update` to true OR
   - Set `min_supported_version_code` higher than installed version
   - User won't be able to dismiss the dialog

3. **Test skip version**:
   - Check "Don't remind me for this version"
   - Click "Later"
   - Restart app — dialog should not appear for this version

4. **Test FCM**:
   - Send a test notification from Firebase Console with `type: update` in custom data
   - Tap the notification — update check should trigger

### Troubleshooting

1. **Dialog not appearing**:
   - Check Remote Config values are published
   - Ensure `apk_url` is not empty and starts with `https://`
   - Check app logs with `flutter logs`

2. **Notifications not received**:
   - Ensure app has notification permission (Settings → Apps → My Wallet → Notifications)
   - Verify FCM is initialized (check logs for "PushNotificationService: Initialized")
   - Ensure app is subscribed to topic "all"

3. **APK download not opening**:
   - Verify the URL is accessible and valid HTTPS
   - Check if browser can open external URLs

---

## Other Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Remote Config Documentation](https://firebase.google.com/docs/remote-config/get-started?platform=flutter)
