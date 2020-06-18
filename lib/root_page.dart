import 'package:flutter/material.dart';
import 'screens/login_signup_page.dart';
//import 'login_signup_page_wopw.dart';
import 'services/authentication.dart';
import 'screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/player_profile.dart';

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class RootPage extends StatefulWidget {
  RootPage({this.auth, this.seen, this.toggleWalkThrough});

  final BaseAuth auth;
  final seen;
  final Function() toggleWalkThrough;

  @override
  State<StatefulWidget> createState() => new _RootPageState();
}

class _RootPageState extends State<RootPage> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  String _userId = "";

  @override
  void initState() {
    super.initState();
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) {
          _userId = user?.uid;
        }
        authStatus =
            user?.uid == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
      });
    });
  }

  void loginCallback() {
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        _userId = user.uid.toString();
      });
    });
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  void logoutCallback() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      _userId = "";
    });
  }

  void _saveUserId(String userId) async { // saving the userID for future use in the app
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  Widget buildWaitingScreen() {
    return Scaffold(
      body: Container(),
    );
  }



  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return buildWaitingScreen();
        break;
      case AuthStatus.NOT_LOGGED_IN:
        //return new LoginPage(); // for version without password
        return new LoginSignupPage( // for version with email & password
          auth: widget.auth,
          loginCallback: loginCallback,
          toggleWalkThrough: widget.toggleWalkThrough,
          walkThrough: widget.seen ?? false ? false : true
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (_userId.length > 0 && _userId != null) {
          _saveUserId (_userId);
          if (widget.seen ?? false) {
            return new HomePage(
              title: "Monday Soccer",
              userId: _userId,
              auth: widget.auth,
              logoutCallback: logoutCallback
            );
          }
          else {
            return ProfilePage(
              title: "Set up your profile",
              userId: _userId,
              auth: widget.auth,
              logoutCallback: logoutCallback,
              walkThrough: true,
              toggleWalkThrough: widget.toggleWalkThrough,
            );
          }
        } else
          return buildWaitingScreen();
        break;
      default:
        return buildWaitingScreen();
    }
  }
}
