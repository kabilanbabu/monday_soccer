import 'package:flutter/material.dart';
import '../services/commcontroller.dart';
import '../model/commtosheet.dart';
import '../services/authentication.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/keys.dart';

class LoginSignupPage extends StatefulWidget {
  LoginSignupPage({this.auth, this.loginCallback, this.toggleWalkThrough, this.walkThrough = false});

  final BaseAuth auth;
  final VoidCallback loginCallback;
  final Function toggleWalkThrough;
  final bool walkThrough;

  @override
  State<StatefulWidget> createState() => new _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = new GlobalKey<FormState>();

  String _email;
  String _defaultEmail;
  String _password;
  String _errorMessage;
  List<String> emailsinSheet =[];
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _isLoginForm;
  bool _isLoading;
  bool _firstTime;

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void _getMasterListEmails() {
       //SharedPreferences.getInstance().then((prefs) { // only for debug purposes to reset the sharedpref email
       //  prefs.setString('email', "");
       //});
    SharedPreferences.getInstance().then((prefs) {
        _defaultEmail = prefs.getString('email') ?? '';
        emailController.text = _defaultEmail;
        (_defaultEmail == '') ? _isLoginForm = false : toggleFormMode();
      });

    String storedKey = KeyValues.sheetCommKey;
        CommToSheet emailRequest = CommToSheet(
          "reqEmails",
          "parameter=" + storedKey,
        );

        // method to handle the request and its response
        CommController commController = CommController((Object emailRequest) {
            List<dynamic> _emailsinSheet = jsonDecode(emailRequest); // List object of the JSON response from Gscript app
            
            _emailsinSheet.forEach((_eMail) {
              emailsinSheet.add(_eMail.toString().toLowerCase());
            });      
        });
        //issuing the request
        commController.commWithSheet(emailRequest);
       
  }

    _checkifEmailisinMasterSheet(_email)  {
      _email = _email.toLowerCase();
      if (emailsinSheet.contains(_email)) {
        return true;
      } else {
        return false;
      }
  }

  _createUserinFireBase(_email, userId) {
    _email = _email.toLowerCase();
    UserModel _userModel = UserModel(
      id: "$userId",
      email: "$_email",
      admin: false,
    );
    Map <String, dynamic> _user = _userModel.toJson();

    Firestore.instance
      .collection('users')
      .document(userId).setData(_user);

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('email', _email);
    });
  }

  // Perform login or signup
  void validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      String userId = "";
      try {
        if (_isLoginForm) { //log in user
          userId = await widget.auth.signIn(_email, _password);
          print('Signed in: $userId');
        } else { //create user
          if (_checkifEmailisinMasterSheet(_email)) {
            userId = await widget.auth.signUp(_email, _password);
            _createUserinFireBase(_email, userId);
            widget.auth.signIn(_email, _password);
            _isLoginForm = true;
          }
          else {
            setState(() {
              _isLoading = false;
              _errorMessage = "This eMail is not listed in our Master Sheet - please contact the group Admins to sign up";
              _formKey.currentState.reset();
          });
        }
          //widget.auth.sendEmailVerification();
          //_showVerifyEmailSentDialog();
          print('Signed up user: $userId');
        }
        setState(() {
          _isLoading = false;
        });

        if (userId.length > 0 && userId != null && _isLoginForm) {
          widget.loginCallback();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          if (_errorMessage == "The email address is already in use by another account.") { // if accounts exist try to log in
            _isLoginForm = true;
            validateAndSubmit();
          }
          //_errorMessage = "$_errorMessage Did you want to sign in instead?";}
          _formKey.currentState.reset();
        });
      }

      //widget.toggleWalkThrough();

      SharedPreferences.getInstance().then((prefs) { // set email address as default for next login
        prefs.setString('email', _email);
      });
    }
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    _isLoginForm = false;
    _firstTime = true;
    _getMasterListEmails();
    super.initState();
  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  void toggleFormMode() {
    resetForm();
    setState(() {
      _isLoginForm = !_isLoginForm;
      emailController.text = _defaultEmail;
      passwordController.text = _password;
    });
  }

  toggleWalkThrough() async {
    if (_firstTime) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (widget.walkThrough) { 
          widget.toggleWalkThrough();
      }
      _firstTime = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Monday Soccer'),
        ),
        body: FutureBuilder<void>(
        future: toggleWalkThrough(), // async work
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
                children: <Widget>[
                  _showForm(),
                  _showCircularProgress(),
                ],
              );
          }
          else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        }));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else {    
      return Container(
        height: 0.0,
        width: 0.0,
      );
    }
  }

//  void _showVerifyEmailSentDialog() {
//    showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        // return object of type Dialog
//        return AlertDialog(
//          title: new Text("Verify your account"),
//          content:
//              new Text("Link to verify account has been sent to your email"),
//          actions: <Widget>[
//            new FlatButton(
//              child: new Text("Dismiss"),
//              onPressed: () {
//                toggleFormMode();
//                Navigator.of(context).pop();
//              },
//            ),
//          ],
//        );
//      },
//    );
//  }

  Widget _showForm() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        color: Colors.white,
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              showLogo(),
              showEmailInput(),
              showPasswordInput(),
              showPrimaryButton(),
              showSecondaryButton(),
              showErrorMessage(),
            ],
          ),
        ));
  }

  Widget showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new Text(
        _errorMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 18.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w600),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 90.0,
          child: Image.asset('assets/swiss_club_logo.png'),
        ),
      ),
    );
  }

  Widget showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
      child: new TextFormField(
        controller: emailController,
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        controller: passwordController,
        decoration: new InputDecoration(
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => _password = value.trim(),
      ),
    );
  }

  Widget showSecondaryButton() {
    return new FlatButton(
        child: new Text(
            _isLoginForm ? 'No account yet? - Press here to create an account instead' : 'Have an account already? Press here to sign in instead',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
            padding: EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
            
        onPressed: toggleFormMode);
  }

  Widget showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.red[300],
            child: new Text(_isLoginForm ? 'Login' : 'Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: validateAndSubmit,
          ),
        ));
  }
}
