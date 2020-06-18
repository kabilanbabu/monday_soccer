import 'package:flutter/material.dart';
import 'dart:async';
import 'services/authentication.dart';
import 'root_page.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_walkthrough.dart';
import 'services/push_notifications.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final fcm = PushNotificationsManager();
  FlutterError.onError = Crashlytics.instance.recordFlutterError;
  fcm.init();
  Crashlytics.instance.enableInDevMode = true;
  SharedPreferences.getInstance().then((prefs) {
    runZoned(() {
        runApp(MyApp(prefs: prefs));
    }, onError: Crashlytics.instance.recordError);
  });
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  MyApp({this.prefs});
  
 
  @override
  Widget build(BuildContext context) {
    //prefs.setBool('accessed_before', false); // only for debbugging the onboarding flow
    return MaterialApp( 
      title: 'Monday Soccer',
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        '/walkthrough': (BuildContext context) => new WalkthroughScreen(),
        '/root': (BuildContext context) => new RootPage(auth: new Auth(), seen:true),
      },
      theme: ThemeData(
         primarySwatch: Colors.blueGrey,
         textTheme: TextTheme(
          headline1: TextStyle(fontSize: 20.0, fontFamily: 'SF Pro', fontWeight: FontWeight.bold, color: Color(0xff717374)),
          headline6: TextStyle(fontSize: 20.0, fontFamily: 'SF Pro', fontWeight: FontWeight.bold, color: Colors.lightBlue), // for highlighting gameday
          headline2: TextStyle(fontSize: 16.0, fontFamily: 'SF Pro', fontWeight: FontWeight.bold, color: Color(0xff717374)),
          headline3: TextStyle(fontSize: 16.0, fontFamily: 'SF Pro', color: Color(0xff717374)),
          bodyText1: TextStyle(fontSize: 13.0, fontFamily: 'SF Pro', color: Color(0xff717374)),
          bodyText2: TextStyle(fontSize: 11.0, fontFamily: 'SF Pro', color: Color(0xff717374)),
          subtitle1: TextStyle(fontSize: 14.0, fontFamily: 'SF Pro', color: Color(0xff717374)),
          subtitle2: TextStyle(fontSize: 11.0, fontFamily: 'SF Pro', color: Colors.red[400]), // timestamp on cards
          headline4: TextStyle(fontSize: 16.0, fontFamily: 'SF Pro', color: Colors.black), //menu items
          headline5: TextStyle(fontSize: 13.0, fontFamily: 'SF Pro', color: Colors.black), // comments
        ),
      ),
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarColor: Colors.transparent, // transparent status bar
          systemNavigationBarColor: Colors.black, // navigation bar color
          statusBarIconBrightness: Brightness.light, // status bar icons' color
          systemNavigationBarIconBrightness: Brightness.light, //navigation bar icons' color
        ),
        child: _handleCurrentScreen()
      ),
    );
  }

  Widget _handleCurrentScreen() {   
      bool seen = (prefs.getBool('accessed_before') ?? false);
      if (seen) {
        return new RootPage(auth: new Auth(), seen: seen);
      } else {
        return new WalkthroughScreen(prefs: prefs);
      }
  }
}



