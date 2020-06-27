import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../services/keys.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
//   print('Background message');
//   if (message.containsKey('data')) {
//     // Handle data message
//     final dynamic data = message['data'];
//     print(data);
//   }
  
//   if (message.containsKey('notification')) {
//     // Handle notification message
//     final dynamic notification = message['notification'];
//     print(notification);
//   }
//   //FlutterAppBadger.updateBadgeCount(1);
//   return Future<void>.value();
// }

class PushNotificationsManager {

  // PushNotificationsManager._();

  // factory PushNotificationsManager() => _instance;

  // static final PushNotificationsManager _instance = PushNotificationsManager._();

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging(); 
  bool _initialized = false;

  static FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  _initLocalNotifications() {
    var initializationSettingsAndroid = new AndroidInitializationSettings('@mipmap/ic_logo_push');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future _showNotification(Map<String, dynamic> message) async {
    var pushTitle;
    var pushText;
    //var action;

    if (Platform.isAndroid) {
      var nodeData = message['data'];
      pushTitle = nodeData['title'];
      pushText = nodeData['body'];
      //action = nodeData['action'];
    } else {
      pushTitle = message['notification']['title'];
      pushText = message['notification']['body'];
      //action = message['action'];
    }
    print("AppPushs params pushTitle : $pushTitle");
    print("AppPushs params pushText : $pushText");
    //print("AppPushs params pushAction : $action");

    // @formatter:off
    var platformChannelSpecificsAndroid = new AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        'your channel description',
        playSound: false,
        enableVibration: false,
        importance: Importance.Max,
        priority: Priority.High);
    // @formatter:on
    var platformChannelSpecificsIos = new IOSNotificationDetails(presentSound: false);
    var platformChannelSpecifics = new NotificationDetails(platformChannelSpecificsAndroid, platformChannelSpecificsIos);

    new Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
        0,
        pushTitle,
        pushText,
        platformChannelSpecifics,
        payload: 'No_Sound',
      );
    });
  }

  Future<void> init() async {
    if (!_initialized) {
      _initLocalNotifications();
      // For iOS request permission first.
      firebaseMessaging.requestNotificationPermissions();
      firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          _showNotification(message);
          print("onMessage: $message");
          var toast = message.values.iterator.current;
          print(toast);
 
        },

       // onBackgroundMessage: myBackgroundMessageHandler, // not working reliably yet
        
        onLaunch: (Map<String, dynamic> message) async {
          print("onLaunch: $message");
          FlutterAppBadger.removeBadge();
        },
        onResume: (Map<String, dynamic> message) async {
          print("onResume: $message");
          FlutterAppBadger.removeBadge();
        },
      );
      firebaseMessaging.subscribeToTopic("all");

      // For testing purposes print the Firebase Messaging token
      String token = await firebaseMessaging.getToken();
      print("FirebaseMessaging token: $token");
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('deviceToken', token);
      });
      _initialized = true;
    }
  }

  Future<void> subscribeToTopic(topic) async {
    firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(topic) async {
    firebaseMessaging.unsubscribeFromTopic(topic);
  }

 // Replace with server token from firebase console settings.
  final String serverToken = KeyValues.fcmKey;

  Future<Map<String, dynamic>> sendAndRetrieveMessage({String title, String body, String topic = "all"}) async {
    await firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(sound: true, badge: true, alert: true, provisional: false),
    );

    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
      <String, dynamic>{
        'notification': <String, dynamic>{
          'body': body,
          'title': title,
          'badge': 1,  
          //'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'priority': 'high',
        'data': <String, dynamic>{
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'id': '1',
          'status': 'done'
        },
        //'content_available': true, // if set true seems to result in background message invoking onResume
        'to': '/topics/$topic',
      },
      ),
    );

    final Completer<Map<String, dynamic>> completer =
      Completer<Map<String, dynamic>>();

    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        completer.complete(message);
      },
    );

    return completer.future;
  }

}