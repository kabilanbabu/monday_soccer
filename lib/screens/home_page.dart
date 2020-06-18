import 'package:flutter/material.dart';
import '../services/commcontroller.dart';
import '../services/animation.dart';
import '../model/commtosheet.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; 
import 'package:flutter/services.dart';
import 'widgets/post_card.dart';
import '../model/post_model.dart';
import '../model/user_model.dart';
import 'player_profile.dart';
import '../services/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'status_page.dart';
import 'create_post.dart';
import '../services/keys.dart';
import 'package:animations/animations.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/push_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';


const double _fabDimension = 56.0;

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final String title;
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _signUp = GlobalKey<State>();
  final _optOut = GlobalKey<State>();
  final _showPlayers = GlobalKey<State>();
  UserModel userData;
  var documentID;
  bool _lockNav = true;
  
  // TextField Controllers
  TextEditingController dateController = TextEditingController();
  TextEditingController appController = TextEditingController();
  TextEditingController userInfoController = TextEditingController();
  TextEditingController timesPlayedController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();

  ContainerTransitionType _transitionType = ContainerTransitionType.fade;

  // Display variables
  String timesPlayed = '0';
  String userEmail = '';
  String userFullName = '';
  String firstName = '';
  String lastName = '';
  String totalPlayers = '';

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  Map<String, Image> profileThumbs;

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  // void _savePrefs(accessedBefore) async { // only needed if onboarding status reset menu item is activated
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('accessed_before', accessedBefore);
  // }

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  Future<UserModel> getUserData() async {
      UserModel userData;
      var result = await Firestore.instance
      .collection("users")
      .where("id", isEqualTo: widget.userId)
      .getDocuments();
      result.documents.forEach((res) {
        userData = UserModel.fromJson(res.data);
        documentID = res.documentID;
      });
      return userData;
  }
  
  void _requestUserInfofromSheet() {
   // function to request player Info from Google Sheet
      try {
        widget.auth.getCurrentUser().then((user) {
          userEmail = user.email;

        CommToSheet playerInfoRequest = CommToSheet(
          "playerInfo",
          "player=" + base64Url.encode(utf8.encode(KeyValues.enc(userEmail))) +
          "&key=" + KeyValues.sheetCommKey
        );

        // method to handle the request and its response
        CommController commController = CommController((Object playerInfo) {
            Map <String, dynamic> _playerInfo = jsonDecode(playerInfo); // Map object of the JSON response from Gscript app (StatusPLayers)

            firstName = _playerInfo['firstName'];
            lastName = _playerInfo['lastName'];
            var _timesPlayed = _playerInfo['timesPlayed'];
    
            setState(() {
              userInfoController.text = "Hello $firstName $lastName";
              timesPlayed = '$_timesPlayed';
              userFullName = '$firstName $lastName';
            });
          });
        //issuing the request
        commController.commWithSheet(playerInfoRequest);
      });
        
      } catch (e){
          print(e);
      }

  }

  void _requestStatusfromSheet(String gameDay) {
      // object to request status from Google Sheets
      CommToSheet statusfromSheet = CommToSheet(
        "statusrequest", 
        "gameDay=" + base64Url.encode(utf8.encode(gameDay)) + // changing date to base64
        "&key=" + KeyValues.sheetCommKey
      );

      CommController commController = CommController((Object response) {
 
        Map <String, dynamic> _statusjson = jsonDecode(response); // Map object of the JSON response from Gscript app (StatusPLayers)
        List<String> _players = List(); // List of players

        _players = _statusjson.entries.map((entry) => "${entry.key}").toList(); //only load key values of JSON object from gscript app
        totalPlayers = _players.length.toString();
        setState(() {});
      });

      commController.commWithSheet(statusfromSheet);
  }

  nextGameDay() {// calc next Monday from today
    var dayOfWeek = 1;
    DateTime date = DateTime.now();
    var nextMonday = date.add(Duration(days: (7-date.weekday % 7 + dayOfWeek) %7)); 
    // in Gscript (d.getDate() + ((7-d.getDay())%7+1) % 7)
    final gameDayFormatter = new DateFormat('dd MMM, yyyy');
    
    var nextGameDay = gameDayFormatter.format(nextMonday);
    
    return nextGameDay;
  }

  void _signUpPlayer() {
    final _nextGameDay = nextGameDay();
    var signUpParameters = "name=" + base64Url.encode(utf8.encode(firstName))
       + "&player=" + base64Url.encode(utf8.encode(KeyValues.enc(userEmail)))
       + "&inout=1&gameday=" + base64Url.encode(utf8.encode(_nextGameDay));
    final fcm = PushNotificationsManager(); 

    CommToSheet signUp = CommToSheet( // paramters for the webapp
      "subscribe",
      signUpParameters,
    );

    // method to handle the request and its response
    CommController commController = CommController((Object response) {
        Map <String, dynamic> _response = jsonDecode(response); // Map object of the JSON response from Gscript app (response)
        
        switch(_response['response']) { 
          case 'success': { 
              fcm.subscribeToTopic(_nextGameDay.replaceAll(new RegExp(r"\s+\b|\b\s|,"), "")); // remove , and whitespace from gameday for topic
             _showSnackbar("Signed up successfully");
          } 
          break; 
          case 'already_subscribed_success': { 
              _showSnackbar("Already signed up");
          } 
          break; 
          case 'already_subscribed': { 
              _showSnackbar("Already signed up");
          } 
          break; 
          case 'waitlisted': { 
              _showSnackbar("You have been waitlisted");
          } 
          break; 
          case 'waitlisted_already_subscribed': { 
              _showSnackbar("Still on waitlist");
          } 
          break; 
          case 'signup_error': { 
              _showSnackbar("Error occured when trying to sign up");
          } 
          break; 
          default: { 
              _showSnackbar("Error occured");
          } 
          break; 
        }
        setState(() {
          _requestUserInfofromSheet();
          _requestStatusfromSheet(_nextGameDay);     
        });
    });
    _showSnackbar("Signing $firstName up...");    //issuing the request
    commController.commWithSheet(signUp);
  }

  void _optOutPlayer() {
    final _nextGameDay = nextGameDay();
    var optOutParameters = "name=" + base64Url.encode(utf8.encode(firstName))
       + "&player=" + base64Url.encode(utf8.encode(KeyValues.enc(userEmail)))
       + "&inout=0&gameday=" + base64Url.encode(utf8.encode(_nextGameDay));

    final fcm = PushNotificationsManager(); 

    CommToSheet optOut = CommToSheet( // paramters for the webapp
      "subscribe",
      optOutParameters,
    );

    // method to handle the request and its response
    CommController commController = CommController((Object response) {
        Map <String, dynamic> _response = jsonDecode(response); // Map object of the JSON response from Gscript app (response)
        switch(_response['response']) { 
          case 'success': { 
            fcm.unsubscribeFromTopic(_nextGameDay.replaceAll(new RegExp(r"\s+\b|\b\s|,"), "")); // remove , and whitespace from gameday for topic
             _showSnackbar("Opted out successfully");
          } 
          break; 
          case 'signup_error': { 
              _showSnackbar("Error occured when trying to opt out!");
          } 
          break; 
          case 'already_subscribed': { 
              _showSnackbar("Already opted out");
          } 
          break; 
          default: { 
              _showSnackbar("Error occured");
          } 
          break; 
        }
        setState(() {
          _requestUserInfofromSheet();
          _requestStatusfromSheet(_nextGameDay);
        });
    });
        //issuing the request
    _showSnackbar("Opting $firstName out..."); 
    commController.commWithSheet(optOut);
  }

  _navToPlayerList() {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => new StatusPage(
            title: "Signed Up Players",
            user: userData,
            auth: widget.auth,
            logoutCallback: widget.logoutCallback,
            gameDay: nextGameDay()
          )),
    );
  } 

  _navToCreatePost() {
    return OpenContainer(
          transitionType: _transitionType,
          openBuilder: (BuildContext context, VoidCallback _) {
            return CreatePostPage(
            title: "Create a Post",
            user: userData,
            logoutCallback: widget.logoutCallback,
            );
          },
          closedElevation: 6.0,
          closedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(_fabDimension / 2),
            ),
          ),
          closedColor: Theme.of(context).colorScheme.secondary,
          closedBuilder: (BuildContext context, VoidCallback openContainer) {
            return SizedBox(
              height: _fabDimension,
              width: _fabDimension,
              child: Center(
                child: Icon(
                  Icons.add_comment,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              )
            );
          }
        );
  }

  _navToPlayerProfile() {
    Navigator.pop(context);
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => new ProfilePage(
            title: "Set up your profile",
            userId: widget.userId,
            auth: widget.auth,
            logoutCallback: widget.logoutCallback,
            walkThrough: false,
          )),
    );
  } 

  _aboutBoxChildren() {
    final TextStyle textStyle = Theme.of(context).textTheme.bodyText1;
    final List<Widget> aboutBoxChildren = <Widget>[
      SizedBox(height: 24),
      RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
                style: textStyle,
                text: 'Swiss Club Monday Soccer \n'
                      'Your one stop shop to signing up for game nights, '
                      'see recent announcements and connect to other players. \n'
                      'Please note this app is only for members of the Singapore Swiss Club Monday Night Soccer group. '
                      'If you\'d like to join, please reach out to '),
            TextSpan(
                style: textStyle.copyWith(color: Theme.of(context).accentColor),
                text: 'andreas.kalkum@gmail.com'),
            TextSpan(style: textStyle, text: '.'),
          ],
        ),
      ),
    ];
    return aboutBoxChildren;
  } 

  daysUntilGameDay() {
    var dayOfWeek = 1;
    DateTime date = DateTime.now();
    var nextMonday = date.add(Duration(days: (7-date.weekday % 7 + dayOfWeek) % 7)); 

    var difference = nextMonday.difference(DateTime.now());
    var daysUntil = (difference.inHours / 24).round();
    if (difference.inHours < 23) { daysUntil = 0; }// today is nextMonday
    return daysUntil;
  }

  void _refreshState() {
    _showSnackbar("Refreshing Data...");
    setState(() {
          timesPlayed = '0';
          totalPlayers = '';
          _requestUserInfofromSheet(); //show user data right away
          _requestStatusfromSheet(nextGameDay()); // save number of total players
        });
  }

  initUser() async {
    await getUserData().then((user) {
      userData = user;
      _lockNav = false;
      fullNameController.text = '${userData.firstName} ${userData.lastName}';
    });
  }

  @override
    void initState() {
      initUser();
      _requestUserInfofromSheet(); //show user data right away
      _requestStatusfromSheet(nextGameDay()); // save number of total players
      _initPackageInfo();
       // allow Navigation to news after all data has been loaded only
      super.initState();
      WidgetsBinding.instance
    .addPostFrameCallback((_) => _showSnackbar("Data Loading..."));
  }

  _showSnackbar(String message) {
      final snackBar = SnackBar(content: Text(message));
      _scaffoldKey.currentState.showSnackBar(snackBar); 
  }


////////////  
//////////// Start of the UI part
////////////
  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      key: _scaffoldKey,  
      resizeToAvoidBottomPadding: false,
      
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarColor: Colors.transparent, // transparent status bar
          systemNavigationBarColor: Colors.black, // navigation bar color
          statusBarIconBrightness: Brightness.light, // status bar icons' color
          systemNavigationBarIconBrightness: Brightness.light, //navigation bar icons' color
        ),
        child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text(widget.title),
            /*actions: <Widget>[
              new FlatButton(
                  child: new Text('Logout',
                      style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                  onPressed: signOut)
              ],*/
            //backgroundColor: Colors.white,
            
            floating: true,
            snap: true,
            pinned: false,
          ),

          SliverList(
            delegate: SliverChildListDelegate([

            SizedBox(height: 30.0,),
            playerCount(),
            SizedBox(height: 30.0,),
            playerName(),
            SizedBox(height: 30.0,),
            gameDay(),
            SizedBox(height: 30.0,),
            actionButtons(),
            SizedBox(height: 30.0,),
            AbsorbPointer( 
              absorbing: _lockNav,
              child: showNewsList(),
            )
            ]),
          )
        ]),
      ),
      floatingActionButton: _navToCreatePost(),

      drawer: Drawer(
        child: menuItems(),
      ),
    );
  }

  Widget menuItems() {
    return ListView(
    // Important: Remove any padding from the ListView.
      padding: EdgeInsets.zero,
      children: <Widget>[
        Container(
        height: 100.0,
          child:DrawerHeader(
            child: Text('Swiss Club Monday Soccer',
            style: Theme.of(context).textTheme.headline4,
            ),
            decoration: BoxDecoration(
              color: Colors.red[200],
            ),
          ),
        ),
        SizedBox (height: 10),
        ListTile(
          leading: Icon(Icons.home),
          title: Text('Home',
          style: Theme.of(context).textTheme.headline4,),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.edit),
          title: Text('Edit Player Profile',
          style: Theme.of(context).textTheme.headline4,),
          onTap: () {
            _navToPlayerProfile();
          },
        ),
        // ListTile(
        //   leading: Icon(Icons.warning),
        //   title: Text('!!! For Testing: Reset onboarding status !!!',
        //   style: Theme.of(context).textTheme.headline4,),
        //   onTap: () {
        //      _savePrefs(false);
        //      _showSnackbar('Onboard status set to false');
        //   },
        // ),
        ListTile(
          leading: Icon(Icons.refresh),
          title: Text('Refresh Data',
          style: Theme.of(context).textTheme.headline4,),
          onTap: () {
            _refreshState();
             Navigator.pop(context);
          },
         ),
        AboutListTile(
          icon: Icon(Icons.info_outline),
          child: Text('About', style: Theme.of(context).textTheme.headline4),
          applicationIcon: Container(width: 70.0, height: 70.0, child: Image.asset('assets/swissclubsoccer.png')),
          applicationName: _packageInfo.appName,
          applicationVersion: 'Version ${_packageInfo.version}',
          applicationLegalese: '© 2020 Andreas Kalkum',
          aboutBoxChildren: _aboutBoxChildren(),
        ),
        ListTile(
          leading: Icon(Icons.exit_to_app),
          title: Text('Logout',
          style: Theme.of(context).textTheme.headline4,),
          onTap: () {
            signOut();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget playerCount() {
    var timesPlayedNo = int.parse(timesPlayed);
    var circleColor;
    var circleoutsideColor;

    if (timesPlayedNo > 10) {
      circleColor = Colors.amber;
      circleoutsideColor = Colors.amberAccent;
    }
    else if (timesPlayedNo > 5) {
      circleColor = Colors.grey;
      circleoutsideColor = Colors.grey[300];
    }
    else {
      circleColor = Colors.brown;
      circleoutsideColor = Colors.brown[200];
    }
    
    return new GestureDetector(
        onTap: () { 
          _refreshState();
        },
        
        child: Container(  // Top Widget circle with times played number
                width: 175,
                height: 175,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  border: Border.all(width: 3, color: circleoutsideColor),
                  shape: BoxShape.circle,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(  // Top Widget circle with times played number
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 8, color: circleColor),
                    shape: BoxShape.circle,
                  ),
                  child: Align(
                            alignment: Alignment.center,
                            child: Column( 
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:<Widget>[
                              new AnimatedCount (count: int.parse(timesPlayed), duration: new Duration(milliseconds: 1200)), 
                            Text(
                              'times played',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyText2
                              )
                            ]
                          ),
                    )))
        )
      );
  }


  Widget playerName() {
    return new Column(children:<Widget>[
      TextField(
        //'$userFullName',
        controller: fullNameController,
        enabled: false,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headline1,
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
      ),
    ],
    );
  }

  Widget gameDay() {
  final gameDay = nextGameDay();
  final daysUntil = daysUntilGameDay();
  String daysUntilText;
  daysUntil == 1 ? daysUntilText = 'Day Until' : daysUntilText = 'Days Until';
  String playersText = 'Players Signed Up';
  if (totalPlayers != '') {
    int.parse(totalPlayers) == 1 ? playersText = 'Player Signed Up': playersText = 'Players Signed Up';
  }
  return new Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    crossAxisAlignment: CrossAxisAlignment.center,
    children:<Widget>[
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children:<Widget>[
      Text(
          gameDay.substring(0,6),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline1
        ),
        
        Text(
          'Next Game Day',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyText2
        )
      ],),
      Container(
        width: 2,
        height: 24,
        color: Color(0xff717374),
        
      ),Column(children:<Widget>[
        Text(
        '$daysUntil',
        textAlign: TextAlign.center,
        style: daysUntil == 0 ? Theme.of(context).textTheme.headline6 : Theme.of(context).textTheme.headline1
      ),
      Text(
        '$daysUntilText',
        textAlign: TextAlign.center,
        style:Theme.of(context).textTheme.bodyText2
      )],),
      Container(
        width: 2,
        height: 24,
        color: Color(0xff717374),
        
      ),
      GestureDetector(
        onTap: () { 
          _refreshState();
        },
        child: 
          Column(children:<Widget>[
            totalPlayers == '' ? 
            SpinKitThreeBounce(color: Color(0xff717374), size: 25)
            : Text(
            '$totalPlayers',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline1
          ),
        
          Text(
            '$playersText',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText2
          )]),
      )],
    );  
  }

    Widget actionButtons() {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
    
      children: <Widget>[
        RaisedButton(
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(25.0),
            side: BorderSide(color: Colors.blue)),
          key: _signUp,
          color: Colors.blue[400],
          textColor: Colors.white,
          onPressed:_signUpPlayer,
          child: Text('Sign Up',
            style: new TextStyle(fontSize: 18.0,)),

          ),
          
          RaisedButton(
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(25.0),
            side: BorderSide(color: Colors.red)),  
          key: _optOut,
          color: Colors.red[400],
          textColor: Colors.white,
          onPressed:_optOutPlayer,
          child: Text('Opt Out',
            style: new TextStyle(fontSize: 18.0,)),
          ),
          
          RaisedButton(
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(25.0),
            side: BorderSide(color: Colors.grey)),
          key: _showPlayers,
          color: Colors.grey[500],
          textColor: Colors.white,
          onPressed:_navToPlayerList,
          child: Text('Players',
            style: new TextStyle(fontSize: 18.0,)),
          ),
      ]);
  }
  
  
  Widget showNewsList() {
    PostModel post;
    
    return  MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child:    
    StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection("posts")
          .orderBy("postTime", descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Text('Loading...');
        final int postCount = snapshot.data.documents.length;
        return ListView.builder(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemCount: postCount,
          itemBuilder: (_, int index) {
            final DocumentSnapshot document = snapshot.data.documents[index];
            post = PostModel.fromJson(document.data);
            return PostCard(postData: post, userData: userData, documentID: document.documentID);
          },
        );
      },
    ));
  }
}
