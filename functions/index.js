/**
 * Cloud Function: sendUpdateNotification
 * 
 * This function sends a push notification to all app users subscribed to the "all" topic
 * when a new version is available.
 * 
 * SETUP:
 * 1. Initialize Firebase Functions in your project root:
 *    $ cd your-flutter-project
 *    $ firebase init functions
 * 
 * 2. Install dependencies:
 *    $ cd functions
 *    $ npm install firebase-admin firebase-functions
 * 
 * 3. Set the API key environment variable:
 *    $ firebase functions:config:set update.api_key="your-secret-key"
 * 
 * 4. Deploy:
 *    $ firebase deploy --only functions
 * 
 * USAGE:
 * POST https://your-region-your-project.cloudfunctions.net/sendUpdateNotification
 * Headers:
 *   x-api-key: your-secret-key
 * Body:
 *   {
 *     "versionName": "1.4.2",
 *     "versionCode": 42,
 *     "message": "Bug fixes and performance improvements"
 *   }
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendUpdateNotification = functions.https.onRequest(async (req, res) => {
    // CORS headers for development
    res.set('Access-Control-Allow-Origin', '*');

    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type, x-api-key');
        return res.status(204).send('');
    }

    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed. Use POST.' });
    }

    // Validate API key
    const apiKey = req.headers['x-api-key'];
    const expectedKey = functions.config().update?.api_key;

    if (!expectedKey || apiKey !== expectedKey) {
        console.warn('Unauthorized attempt to send update notification');
        return res.status(403).json({ error: 'Unauthorized' });
    }

    // Parse request body
    const { versionName, versionCode, message, forceUpdate = false } = req.body;

    if (!versionName || !versionCode) {
        return res.status(400).json({
            error: 'Missing required fields',
            required: ['versionName', 'versionCode'],
            optional: ['message', 'forceUpdate']
        });
    }

    // Build notification payload
    const notificationPayload = {
        notification: {
            title: 'Update Available',
            body: message || `Version ${versionName} is now available. Tap to update.`,
        },
        data: {
            type: 'update',
            versionCode: String(versionCode),
            versionName: String(versionName),
            forceUpdate: String(forceUpdate),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        topic: 'all',
        android: {
            priority: 'high',
            notification: {
                channelId: 'update_channel',
                priority: 'high',
                defaultVibrateTimings: true,
                icon: 'ic_notification',
            },
        },
    };

    try {
        const response = await admin.messaging().send(notificationPayload);

        console.log('Update notification sent successfully:', {
            messageId: response,
            versionName,
            versionCode,
        });

        return res.status(200).json({
            success: true,
            messageId: response,
            versionName,
            versionCode,
        });
    } catch (error) {
        console.error('Error sending update notification:', error);
        return res.status(500).json({
            success: false,
            error: error.message,
        });
    }
});

/**
 * Alternative: Firestore trigger function
 * 
 * Automatically sends notification when "app_config/android_update" document is updated.
 * Uncomment and deploy if you prefer this approach.
 */
/*
exports.onUpdateConfigChanged = functions.firestore
  .document('app_config/android_update')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Only send notification if version code increased
    if (newData.latest_version_code <= oldData.latest_version_code) {
      console.log('Version code not increased, skipping notification');
      return null;
    }

    const notification = {
      notification: {
        title: 'Update Available',
        body: newData.update_message || `Version ${newData.latest_version_name} is now available.`,
      },
      data: {
        type: 'update',
        versionCode: String(newData.latest_version_code),
        versionName: String(newData.latest_version_name),
      },
      topic: 'all',
    };

    try {
      const response = await admin.messaging().send(notification);
      console.log('Auto notification sent for version:', newData.latest_version_name);
      return response;
    } catch (error) {
      console.error('Error sending auto notification:', error);
      throw error;
    }
  });
*/
