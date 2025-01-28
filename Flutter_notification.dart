Building a full notification system that integrates Firebase (for backend notifications) and Node.js (for server-side control) into a Flutter app is an extensive process. Below is a **step-by-step guide**, covering all parts of this system:

---

### **Overview**

1. **Firebase Setup**: Set up Firebase Cloud Messaging (FCM) for your project.
2. **Node.js Backend**: Build a server to send notifications.
3. **Flutter App**: Configure your Flutter app to receive notifications.
4. **Implement Features**: Test sending notifications and handle them in the app.

---

### **Step 1: Firebase Setup**
#### 1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/).
   - Create a new project and enable Cloud Messaging.

#### 2. **Add Firebase to Your Flutter App**
   - Add your app's Android and iOS package details to the Firebase project.
   - Download the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS).

#### 3. **Add Firebase SDK to Flutter**
Update `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_messaging: ^14.0.0
```

Run:
```bash
flutter pub get
```

#### 4. **Configure Firebase in Flutter**
Update your `main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated when setting up Firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notification',
      home: HomeScreen(),
    );
  }
}
```

#### 5. **Configure FCM in Android**
- Add this in `android/app/build.gradle`:
  ```gradle
  implementation platform('com.google.firebase:firebase-bom:31.0.3')
  implementation 'com.google.firebase:firebase-messaging'
  ```

- Ensure `google-services.json` is in `android/app/`.

- Add the following permission to `AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
  ```

#### 6. **Configure FCM in iOS**
- Add the `GoogleService-Info.plist` file to your Xcode project.
- Enable notifications in `Info.plist`:
  ```xml
  <key>UIBackgroundModes</key>
  <array>
    <string>remote-notification</string>
  </array>
  ```

---

### **Step 2: Node.js Backend**
#### 1. **Initialize a Node.js Project**
```bash
mkdir fcm-server
cd fcm-server
npm init -y
```

#### 2. **Install Required Packages**
```bash
npm install firebase-admin express body-parser
```

#### 3. **Set Up Firebase Admin SDK**
1. Go to the Firebase Console > Project Settings > Service Accounts.
2. Generate a new private key and download the JSON file.
3. Place this file in your project directory as `firebase-adminsdk.json`.

#### 4. **Write Notification Logic**
Create a file `index.js`:
```javascript
const express = require('express');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(require('./firebase-adminsdk.json')),
});

const PORT = 3000;

// API to send notifications
app.post('/send-notification', async (req, res) => {
  const { token, title, body } = req.body;

  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    res.status(200).send({ message: 'Notification sent', response });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
```

#### 5. **Run the Server**
```bash
node index.js
```

The server listens on port 3000 for notification requests.

---

### **Step 3: Flutter App Configuration**
#### 1. **Initialize Firebase Messaging**
Update your `HomeScreen` in Flutter to handle notifications.

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  void _initializeFCM() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission();

    // Get the FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Handle notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a notification: ${message.notification?.body}');
      // Show alert or update UI
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FCM Notifications')),
      body: Center(
        child: Text('Waiting for notifications...'),
      ),
    );
  }
}
```

---

### **Step 4: Test Notifications**
#### **1. Test with Node.js**
Use an API client like Postman to send notifications to the device:
1. Endpoint:
   ```
   POST http://localhost:3000/send-notification
   ```
2. Body:
   ```json
   {
     "token": "<device_FCM_token>",
     "title": "Hello!",
     "body": "This is a test notification."
   }
   ```

#### **2. Flutter App Response**
- The app will display the notification in the console.
- You can customize how notifications are displayed (e.g., show alerts).

---

### **Step 5: Handle Background Notifications**
Add this to your `main.dart` to handle notifications when the app is in the background:
```dart
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background notification: ${message.notification?.title}');
}
```

---

### **Summary**
- Firebase is used to manage and send notifications.
- Node.js handles server-side notification requests.
- Flutter receives and processes notifications, even in the background.

Let me know if you'd like a detailed explanation of any specific part!