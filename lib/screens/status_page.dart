import 'package:flutter/material.dart';
import 'package:monday_soccer/model/user_model.dart';
import '../services/commcontroller.dart';
import '../model/commtosheet.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; 
import '../services/authentication.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../services/keys.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:firebase_image/firebase_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class StatusPage extends StatefulWidget {
  StatusPage({Key key, this.title, this.auth, this.user, this.logoutCallback, this.gameDay})
      : super(key: key);

  final String title;
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final UserModel user;
  final String gameDay;

  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  
  List<String> _sheetResponse = List(); //currently only used for a list of players
  
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading;
  String _totalPlayers;

  // TextField Controllers
  TextEditingController dateController = TextEditingController();
  TextEditingController appController = TextEditingController();
  TextEditingController userInfoController = TextEditingController();
  TextEditingController timesPlayedController = TextEditingController();

  var fireUsers = Firestore.instance.collection("users");
  List<UserModel> playerFireData = [];

  void _displayStatus(response) {
    setState(() {
      _sheetResponse = response;
      _isLoading = false;
    });
  }

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }
  
  void _requestStatusfromSheet() {
      // object to request status from Google Sheets
      CommToSheet statusfromSheet = CommToSheet(
        "statusrequest", 
        "gameDay=" + base64Url.encode(utf8.encode(dateController.text)) + // changing date to base64
        "&key=" + KeyValues.sheetCommKey
      );

      CommController commController = CommController((Object response) async {
        Map <String, dynamic> _statusjson = jsonDecode(response); // Map object of the JSON response from Gscript app (StatusPLayers)
        List<String> _players = List(); // List of players
  
        _players = _statusjson.entries.map((entry) => "${entry.key}").toList(); //only load key values of JSON object from gscript app
        _totalPlayers = _players.length.toString();

        for (int i = 0; i<_players.length; i = i + 10) { // get 10 records at a time (FireStore limitation) - should limitation be removed in future just pass entire list through
          int iPlus10 = 0;
          (i + 10) < _players.length ? iPlus10 = i + 10 : iPlus10 = _players.length;
          await addFireUserData(_players.sublist(i, iPlus10));
        }

        _displayStatus(_players);

        if (CommController.STATUS_SUCCESS == "SUCCESS") {
          _scaffoldKey.currentState.hideCurrentSnackBar();
          _isLoading = false;
        } else {
          _showSnackbar("Error Occurred!");
        }
      });

      setState(() {
        _showSnackbar("Players for GameDay Loading...");
        _isLoading = true;
      }); 
        
      commController.commWithSheet(statusfromSheet);
  }

  addFireUserData(List batchOf10) async {
      UserModel userData;
      List userIDs = [];
      batchOf10.forEach((element) { 
        userIDs.add(element.split(";")[0]); // required to split user ID from the gScript response
      });
      var result = await fireUsers
        .where("id", whereIn: userIDs)
        .getDocuments();
      result.documents.forEach((res) {
        userData = UserModel.fromJson(res.data);
        if (userData.id != '') { playerFireData.add(userData); }
      });
  }

 // Method to show snackbar with 'message'.
  _showSnackbar(String message) {
      final snackBar = SnackBar(content: Text(message));
      _scaffoldKey.currentState.showSnackBar(snackBar); 
  }

// for date selector
  DateTime selectedDate = DateTime.now(); 

  Future<Null> _selectDate(BuildContext context) async {
    final currentYear = DateTime.now().year;
    final firstDate = DateTime(currentYear, 1);
    final lastDate = DateTime.now().add(Duration(days: 180));
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: firstDate, 
        lastDate: lastDate);
        final gameDayFormatter = new DateFormat('dd MMM, yyyy');
        dateController.text = gameDayFormatter.format(picked);
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
        playerFireData =[];
        _requestStatusfromSheet();
      });
  }
// end date selector

  @override
    void initState() {
      dateController.text = widget.gameDay;
      _isLoading = false;
      super.initState();
      WidgetsBinding.instance
    .addPostFrameCallback((_) => _requestStatusfromSheet());
  }

////////
/// UI Part
////////
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
              floating: true,
              snap: true,
            ),

            SliverList(

            delegate: SliverChildListDelegate([
                SizedBox(height: 5.0),
                calendarButton(),
                dateForm(),
                !_isLoading ? listOfPlayers() : Text(''),
                !_isLoading ? totalPlayers() : _showCircularProgress()
                ])
            )
        ])
      )
    );
  }

  Widget calendarButton() {
    return Column(
      children: <Widget>[
      new RaisedButton(
        shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
              side: BorderSide(color: Colors.red),),  
      onPressed: () => _selectDate(context),
      color: Colors.red[300],
      textColor: Colors.white,
      child: Text('Select another Game Day',
            style: new TextStyle(fontSize: 18.0,)),
      )
    ]);
  }

  Widget dateForm() {
    return Form( // date selector form
      key: _formKey,
      child:
        Padding(padding: EdgeInsets.only(left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: dateController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Game Day'
              ),
            ),
          ],
        ),
      ) 
    );
  }

  Widget listOfPlayers() {

    getPlayerName(index) {
      List<String> _player = _sheetResponse[index].split(";");
      final userID = _player[0];
      String nickName;
      String fullName = '${_player[1]} ${_player[2]}';
      if (userID != '') {
        var _playerFireData = playerFireData.singleWhere((player) => player.id == userID);
        nickName = _playerFireData.nickName;
        if (nickName != '') { fullName = fullName + ' ($nickName)'; }
      } 
      
      return fullName;
    }

    getPlayerNotInFirebase(index) {
      List<String> _player = _sheetResponse[index].split(";");
      return UserModel(
        id: _player[0],
        firstName: _player[1], 
        lastName: _player[2],
      );
    }

    getPlayerID(index) {
      List<String> _player = _sheetResponse[index].split(";");
      return _player[0];
    }
    
    String getInitials(UserModel player) {
      String initials = player.firstName.substring(0,1) + player.lastName.substring(0,1);
      return initials.toUpperCase();
    }

    getPositions(index) {
      final _playerID = getPlayerID(index);
      var _playerFireData = playerFireData.singleWhere((player) => player.id == _playerID, orElse: () => getPlayerNotInFirebase(index));

      List<Widget> positions = [];
      if (_playerFireData.position != null) {
        for (int i=0; i < _playerFireData.position.length; i++) {
          var _abbreviation = Player.positions.singleWhere((position) => position['value'] == _playerFireData.position[i]);
          positions.add(CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Text(_abbreviation['abbr'], style: Theme.of(context).textTheme.bodyText1),
            maxRadius: 15));
        }
      }
      else {
        positions.add(Container(width: 0, height: 0));
      }

      return Wrap(children: positions, );
    }

    getPlayerThumbnail(index) {
      final _playerID = getPlayerID(index);
      var _playerFireData = playerFireData.singleWhere((player) => player.id == _playerID, orElse: () => getPlayerNotInFirebase(index));

      var _thumb;
      if (_playerFireData.image != null) {
         var _playerThumbnail = 'gs://swissclubmondaysoccer.appspot.com/profilepics/thumbs/${_playerID}_200x200'; 
         _thumb = FirebaseImage(_playerThumbnail);
           return CircleAvatar(
                  backgroundImage: _thumb,
                  maxRadius: 25,
                );
      } else {
        return CircleAvatar(
          backgroundColor: Colors.blueGrey,
          child: Text(getInitials(_playerFireData), style: TextStyle(fontWeight: FontWeight.bold)),
          maxRadius: 25);
      }
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child:
    ListView.builder(
      shrinkWrap: true, 
      physics: ClampingScrollPhysics(),
      itemCount: _sheetResponse.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: getPlayerThumbnail(index),
            title: Text(getPlayerName(index),
                style: Theme.of(context).textTheme.headline3,
            ),
            trailing: getPositions(index),
          )
        );
      } 
    ),);
  }

  Widget totalPlayers() {
    return Card(
          child: ListTile(
            leading: Icon(FlutterIcons.soccer_field_mco, size: 50.0),
            title: Text('Total of $_totalPlayers players signed up',
              style: Theme.of(context).textTheme.headline2,
          )),
        );
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container();
  }
}
