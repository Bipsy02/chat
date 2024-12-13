import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chat/pages/loginPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(
    null, //App icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic alerts',
        defaultColor: Colors.deepPurple,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
      // Add more channels if needed for different types of notifications
    ],
    debug: true, // Set to false in production
  );

  // Request notification permissions
  await AwesomeNotifications().requestPermissionToSendNotifications();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Set up notification listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
    );
  }

  // Static methods for notification handling
  static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Handle notification tap action
    print('Notification action received: ${receivedAction.payload}');
  }

  static Future<void> _onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Called when a notification is created
    print('Notification created: ${receivedNotification.id}');
  }

  static Future<void> _onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Called when a notification is displayed
    print('Notification displayed: ${receivedNotification.id}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}