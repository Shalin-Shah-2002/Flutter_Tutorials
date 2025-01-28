To schedule a notification in Flutter using Firebase Cloud Messaging (FCM), you need to use Firebase Functions or a backend service (like Node.js) to schedule the notification, as FCM doesn't provide built-in scheduling. Here's a step-by-step guide:

---

### **1. Set Up Your Backend (Node.js Example)**
In your Node.js backend, use `node-cron` or a similar library to schedule notifications.

#### Install Dependencies
```bash
npm install firebase-admin node-cron body-parser
```

#### Backend Code
```javascript
const admin = require('firebase-admin');
const cron = require('node-cron');
const bodyParser = require('body-parser');
const express = require('express');
const app = express();

app.use(bodyParser.json());

// Initialize Firebase Admin SDK
admin.initializeApp({
    credential: admin.credential.cert(require('./path-to-your-firebase-adminsdk.json')),
});

// Schedule Notification Endpoint
app.post('/schedule-notification', (req, res) => {
    const { token, title, body, scheduleTime } = req.body;

    const notificationTime = new Date(scheduleTime).getTime();
    const currentTime = Date.now();

    if (notificationTime <= currentTime) {
        return res.status(400).send({ message: 'Scheduled time must be in the future.' });
    }

    // Schedule the notification
    const delay = notificationTime - currentTime;

    setTimeout(async () => {
        const message = {
            notification: { title, body },
            token: token,
        };

        try {
            const response = await admin.messaging().send(message);
            console.log('Notification sent:', response);
        } catch (error) {
            console.error('Error sending notification:', error);
        }
    }, delay);

    res.status(200).send({ message: 'Notification scheduled successfully.' });
});

// Run Server
const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
```

#### How It Works:
1. The `schedule-notification` endpoint accepts the `token`, `title`, `body`, and `scheduleTime` (ISO format) from the request.
2. Calculates the delay time (`notificationTime - currentTime`).
3. Uses `setTimeout` to delay the notification sending.

---

### **2. Trigger Notifications from Your Flutter App**
Send a POST request to the backend with the notification details.

#### Example Flutter Code
Add the `http` package to your `pubspec.yaml`:
```yaml
dependencies:
  http: ^0.15.0
```

Flutter Request Example:
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> scheduleNotification(
    String token, String title, String body, DateTime scheduleTime) async {
  final url = Uri.parse('http://your-backend-url.com/schedule-notification');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'token': token,
      'title': title,
      'body': body,
      'scheduleTime': scheduleTime.toIso8601String(),
    }),
  );

  if (response.statusCode == 200) {
    print('Notification scheduled successfully');
  } else {
    print('Failed to schedule notification: ${response.body}');
  }
}
```

---

### **3. Example Workflow**
1. **Get FCM Token in Flutter**:
   ```dart
   String? token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

2. **Schedule Notification**:
   ```dart
   await scheduleNotification(
       '<FCM Token>',
       'Reminder',
       'This is your scheduled notification.',
       DateTime.now().add(Duration(hours: 1)), // 1 hour from now
   );
   ```

---

### **4. Alternative: Local Scheduling**
If you only need notifications within the device (no backend needed), you can use the `flutter_local_notifications` package.

#### Add Dependency
```yaml
dependencies:
  flutter_local_notifications: ^14.0.0
```

#### Initialize Notifications
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(settings);
}
```

#### Schedule a Local Notification
```dart
Future<void> scheduleLocalNotification(
    String title, String body, DateTime scheduledTime) async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails('channel_id', 'channel_name',
          channelDescription: 'channel_description');

  const NotificationDetails details =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    title,
    body,
    scheduledTime,
    details,
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
```

---

### When to Use Each Approach
- **Backend Scheduling (Node.js)**: For notifications that need to be sent to multiple users/devices.
- **Local Scheduling (flutter_local_notifications)**: For reminders or notifications specific to the device.

Let me know which approach you prefer, and I can assist further!