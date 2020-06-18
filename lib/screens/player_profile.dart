import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/user_model.dart';
import 'take_picture.dart';
import 'dart:convert';
import '../services/keys.dart';
import '../services/commcontroller.dart';
import '../model/commtosheet.dart';
import 'package:flutter/services.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter_native_image/flutter_native_image.dart';
import 'dart:io';
//import 'package:shared_preferences/shared_preferences.dart';


class ProfilePage extends StatefulWidget {
  ProfilePage ({Key key, this.title, this.auth, this.userId, this.logoutCallback, @required this.walkThrough, this.toggleWalkThrough})
      : super(key: key);

  final String title;
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;
  final walkThrough;
  final Function() toggleWalkThrough;

  @override
  _ProfilePage createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  bool _status = true;
  bool _firstTime = true;
  UserModel userData;
  String profilePicURL;
  var profilePic;
  var documentID;
  bool hasNewPic = false;

  // TextField Controllers
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController nickNameController = TextEditingController();
  TextEditingController accNoController = TextEditingController();
  TextEditingController birthDayController = TextEditingController();
  var birthDay;

  List _myPosition;                 
  final formKey = new GlobalKey<FormState>();
  final positionFormKey = new GlobalKey<FormState>();

  final FocusNode myFocusNode = FocusNode();

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

  void initiateUserDatafromGSheet() async {
    var eMail;
    try {
        widget.auth.getCurrentUser().then((user) {
          eMail = user.email;

        CommToSheet playerInfoRequest = CommToSheet(
          "playerInfo",
          "player=" + base64Url.encode(utf8.encode(KeyValues.enc(eMail))) +
          "&key=" + KeyValues.sheetCommKey,
        );
        // method to handle the request and its response
        CommController commController = CommController((Object playerInfo) {
            Map <String, dynamic> _playerInfo = jsonDecode(playerInfo); // Map object of the JSON response from Gscript app (StatusPLayers)

            final _firstName = _playerInfo['firstName'];
            final _lastName = _playerInfo['lastName'];
            
            if ((firstNameController.text == '') || (lastNameController.text == '')) {
              setState(() {
                firstNameController.text = _firstName;
                lastNameController.text = _lastName;
                UserModel gUserData = UserModel(
                  firstName: _firstName,
                  lastName: _lastName,
                  id: user.uid
                );
                Firestore.instance.collection('users').document(gUserData.id).updateData(gUserData.toJson());
              });
            }
          });
        //issuing the request
        commController.commWithSheet(playerInfoRequest);
        });
      }
        catch (e) {
        print(e);
      }
  }

  void writeUserDatatoGSheet(eMail, lastName, firstName, userId) async {
    String storedKey = KeyValues.sheetCommKey;
      CommToSheet writeUserData = CommToSheet(
        "updateProfileData",
        "key=$storedKey&email=" + base64Url.encode(utf8.encode(KeyValues.enc(eMail.toString().toLowerCase()))) + 
        "&lastName=" + base64Url.encode(utf8.encode(lastName)) + 
        "&firstName=" + base64Url.encode(utf8.encode(firstName)) +
        "&userID=" + base64Url.encode(utf8.encode(userId)) 
      );

      // method to handle the request and its response
      CommController commController = CommController((Object writeUserData) {
          List<dynamic> _response = jsonDecode(writeUserData); // List object of the JSON response from Gscript app
          _response.toString();
          print(_response);
      });
      //issuing the request
      commController.commWithSheet(writeUserData);
  }

  void _saveProfileData() {
    firstNameController.text = firstNameController.text.trim();
    lastNameController.text = lastNameController.text.trim();
    emailController.text = emailController.text.trim();
    phoneNumberController.text = phoneNumberController.text.trim();
    nickNameController.text = nickNameController.text.trim();
    accNoController.text = accNoController.text.trim();
    var form = positionFormKey.currentState;
    if (form.validate()) {
      form.save();
    }

    Firestore.instance
      .collection('users')
      .document(documentID)
      .updateData({
        'firstName': firstNameController.text, 
        'lastName': lastNameController.text, 
        'email': emailController.text, 
        'phoneNumber': phoneNumberController.text,
        'position': _myPosition,
        'nickName': nickNameController.text,
        'clubAccNo': accNoController.text,
        'birthDay': birthDay?.toIso8601String(),
        });
      writeUserDatatoGSheet(emailController.text, lastNameController.text, firstNameController.text, widget.userId);
  }

  void _navToTakePicture() async {
    profilePic = null;
    profilePic = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => new TakePicture(
            title: 'Take Your Profile Picture',
            userId: widget.userId,
            userDocumentID: documentID,
            //auth: widget.auth,
            //logoutCallback: widget.logoutCallback,
          )),
    );
    if (profilePic != null) {
      _saveProfilePicture(profilePic);
      setState(() {   
         hasNewPic = true;
      });
    }
  }

  Future<void> _saveProfilePicture(_imageFile) async {
    String filename = widget.userId;
    var file = _imageFile;
    StorageReference storageReference;
    storageReference = FirebaseStorage.instance.ref().child("profilepics/$filename");

    final StorageUploadTask uploadTask = storageReference.putFile(file);
    final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
    final String url = (await downloadUrl.ref.getDownloadURL());
    await DefaultCacheManager().emptyCache();
    _saveProfilePicURL(url);
    
    StorageReference thumbStorageReference;
    thumbStorageReference = FirebaseStorage.instance.ref().child("profilepics/thumbs/${filename}_200x200");
    ImageProperties properties = await FlutterNativeImage.getImageProperties(file.path);
    File thumb = await FlutterNativeImage.compressImage(_imageFile.path, quality: 70, 
      targetWidth: 200, 
      targetHeight: (properties.height * 200 / properties.width).round());
    final StorageUploadTask thumbUploadTask = thumbStorageReference.putFile(thumb);
    final StorageTaskSnapshot thumbComplete = (await thumbUploadTask.onComplete);
    thumbComplete != null ? print('Thumb uploaded') : print('Error uploading thumb');
  }

  void _saveProfilePicURL(_url) {
    Firestore.instance
      .collection('users')
      .document(documentID)
      .updateData({
        'image': _url, 
        });
  }

  _showProfilePic() {
    String picURL = 'https://firebasestorage.googleapis.com/v0/b/swissclubmondaysoccer.appspot.com/o/profilepics%2F'
      + widget.userId
      + '?alt=media&token=a9b993e5-6402-4685-bdf7-0494a2d9c561';
    
    if (hasNewPic) {
      //imageCache.evict(FileImage(profilePic)); // clear cache in take picture instead
      return new Container(
        width: 140.0,
        height: 140.0,
        decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: new DecorationImage(
          image: FileImage(profilePic),
          fit: BoxFit.cover,
          )
        )
      );
    }
    else if (profilePicURL != null) {
          return new Container(
              width: 140.0,
              height: 140.0,
              child:CachedNetworkImage(
                imageUrl: picURL,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        colorFilter:
                            ColorFilter.mode(Colors.white, BlendMode.colorBurn)),
                    shape: BoxShape.circle
                  ),
                ),
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
          )
        );
    }
    else {
      return new Container(
        width: 140.0,
        height: 140.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: new DecorationImage(
            image: ExactAssetImage('assets/as.png'),
            fit: BoxFit.cover,
          )
        )
      );
    }
  }

  initUser() async {
    if (_firstTime) { 
      userData = await getUserData();
      firstNameController.text = userData.firstName;
      lastNameController.text = userData.lastName;
      emailController.text = userData.email;
      phoneNumberController.text = userData.phoneNumber;
      profilePicURL = userData.image;
      nickNameController.text = userData.nickName;
      accNoController.text = userData.clubAccNo;
      _myPosition = userData.position;    
      birthDay = userData.birthDay;
      final dateFormatter = new DateFormat('dd MMM, yyyy');
      birthDay != null ? birthDayController.text = dateFormatter.format(birthDay) : birthDayController.text = '';  
      _firstTime = false;
      if (widget.walkThrough) { 
        initiateUserDatafromGSheet();
      } 
    }         
  }

  @override
  void initState() {
    _status = widget.walkThrough ? false : true; // enforce saving data if on walkthrough, display as default in other cases
    _myPosition = [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false, 
      resizeToAvoidBottomInset: true, 
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarColor: Colors.transparent, // transparent status bar
          systemNavigationBarColor: Colors.black, // navigation bar color
          statusBarIconBrightness: Brightness.light, // status bar icons' color
          systemNavigationBarIconBrightness: Brightness.light, //navigation bar icons' color
        ),
        child:   
      FutureBuilder<void>(
        future: initUser(), // async work
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return mainProfilePage();
          }
          else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      )
      )
    );
  }
      
  Widget mainProfilePage() {
    return CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text(widget.title),
            floating: true,
            snap: true,
            pinned: false,
          ),

          SliverList(
            delegate: SliverChildListDelegate([
                SizedBox(height: 15.0,),
                profilePicture(),
                SizedBox(height: 15.0,),
                coreProfileData(),
            ])
          )
        ]);
  }
                      
  Widget profilePicture() {                  
     return new Stack(fit: StackFit.loose, children: <Widget>[
                        new Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                             _showProfilePic(),
                          ],
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 90.0, right: 100.0),
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new CircleAvatar(
                                  backgroundColor: Colors.red,
                                  radius: 25.0,
                                  child:                                   
                                    new IconButton(
                                    icon: Icon(Icons.camera_alt),
                                    color: Colors.white,
                                    onPressed: _navToTakePicture
                                  ),
                                )
                              ],
                            )),
                      ]);
  }

  Widget coreProfileData() {
             return new Container(
                color: Color(0xffFFFFFF),
                child: Form(
                key: formKey,
                autovalidate: true,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 25.0),
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 25.0),
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              new Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  new Text(
                                    'Player Profile Info',
                                    style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              new Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _status ? _getEditIcon() : new Container(),
                                ],
                              )
                            ],
                          )),

                      Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 5.0),
                          child: new Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  child: TextFormField(
                                    controller: firstNameController,
                                    enabled: !_status,
                                     validator: (value) {
                                        if (value.isEmpty) {
                                          return 'Please enter a first name';
                                        }
                                        return null;
                                        },
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      labelStyle: TextStyle(color: Colors.black54),
                                      hintText: 'Enter your first name',
                                    ),
                                )),
                                flex: 2,
                              ),
                              Expanded(
                                child: Container(
                                  child: TextFormField(
                                    controller: lastNameController,
                                    enabled: !_status,
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return 'Please enter a first name';
                                        }
                                        return null;
                                        },
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      labelStyle: TextStyle(color: Colors.black54),
                                      hintText: 'Enter your last name',
                                    ),
                                )),
                                flex: 2,
                              ),
                            ],
                          )),
                        
                        Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 5.0),
                          child: new Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  child: TextFormField(
                                    controller: nickNameController,
                                    enabled: !_status,
                                    decoration: InputDecoration(
                                      labelText: 'Nickname',
                                      labelStyle: TextStyle(color: Colors.black54),
                                      hintText: '(Optional)',
                                    ),
                                )),
                                flex: 2,
                              ),
                              Expanded(
                                child: Container(
                                  child: TextFormField(
                                    controller: accNoController,
                                    enabled: !_status,
                                    decoration: InputDecoration(
                                      labelText: 'Swiss Club Acc No.',
                                      labelStyle: TextStyle(color: Colors.black54),
                                      hintText: 'Enter your acc. no.',
                                    ),
                                )),
                                flex: 2,
                              ),
                            ],
                          )),

                        Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 5.0),
                          child: new Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Expanded(child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  TextFormField(
                                    controller: emailController,
                                    enabled: false,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      labelStyle: TextStyle(color: Colors.black54),
                                      hintText: 'Enter your email address',
                                    ),
                                  ),
                                ],
                              )),

                            ],
                          )),

                        Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 5.0),
                          child: new Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  child:  TextFormField(
                                    controller: phoneNumberController,
                                    enabled: !_status,
                                    keyboardType: TextInputType.phone,
                                    validator: (String value) {
                                        String pattern = r'^(\+|00|)[1-9][0-9 \-\(\)\.]{7,}$';
                                        RegExp regExp = new RegExp(pattern);
                                        if (value.length == 0) {
                                              return 'Please enter mobile number';
                                        }
                                        else if (!regExp.hasMatch(value)) {
                                              return 'Please enter valid mobile number';
                                        }
                                        return null;
                                        },
                                    decoration: InputDecoration(
                                      labelText: 'Mobile Number',
                                      labelStyle: TextStyle(color: Colors.black54),
                                      hintText: 'Enter mobile number',
                                    ),
                                  ),),
                                flex: 2,
                              ),
                              Expanded(
                                child: Container(
                                  child: TextFormField(
                                    controller: birthDayController,
                                    onTap: () => _selectDate(context),
                                    enabled: !_status,
                                    decoration: InputDecoration(
                                      labelText: 'Birthday',
                                      labelStyle: TextStyle(color: Colors.black54),
                                      hintText: 'Enter your birthday',
                                    ),
                                )),
                                flex: 2,
                              ),
                            ],
                          )),

                      playerPosition(),
                      !_status ? _getActionButtons() : new Container(),
                    ],
                  ),
                )
                )
             );
  }

  // for date selector
  DateTime selectedDate = DateTime.now();


  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        initialEntryMode: DatePickerEntryMode.input,
        initialDatePickerMode: DatePickerMode.year,
        firstDate: DateTime(1940, 1),
        lastDate: DateTime.now(),
        helpText: 'Enter your birthday',
      );
    final dateFormatter = new DateFormat('dd MMM, yyyy');
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
        birthDay = picked;
        birthDayController.text = dateFormatter.format(picked);
      });
  }
// end date selector

  Widget playerPosition() {
    return Center(
        child: Form(
          key: positionFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(left: 13.0, right: 25.0, top: 5.0),
                child: AbsorbPointer( 
                  absorbing: _status,
                  child: MultiSelectFormField(
                    autovalidate: false,
                    titleText: 'My Preferred Positions',
                    validator: (value) {
                      if (value == null || value.length == 0) {
                        return 'Please select one or more options';
                      }
                      return null;
                    },
                    dataSource: Player.positions,
                    textField: 'display',
                    valueField: 'value',
                    okButtonLabel: 'OK',
                    cancelButtonLabel: 'CANCEL',
                    hintText: 'Please choose one or more',
                    initialValue: _myPosition,
                    onSaved: (value) {
                      if (value == null) return;
                        _myPosition = value;
                    },
                    fillColor: Colors.white,
                  )
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    myFocusNode.dispose();
    super.dispose();
  }

  Widget _getActionButtons() {
    return Padding(
      padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 15.0),
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Container(
                child: new RaisedButton(
                  child: new Text("Save"),
                  textColor: Colors.white,
                  color: Colors.green,
                  onPressed: () {
                    if (formKey.currentState.validate()) {
                      setState(() {
                        _status = true;
                        _saveProfileData();
                        if (widget.walkThrough){
                          widget.toggleWalkThrough();
                        }
                        FocusScope.of(context).requestFocus(new FocusNode());
                    });
                  }
                },
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(20.0)),
              )),
            ),
            flex: 2,
          ),
          !widget.walkThrough ? Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Container(
                  child: new RaisedButton(
                child: new Text("Cancel"),
                textColor: Colors.white,
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    _status = true;
                    FocusScope.of(context).requestFocus(new FocusNode());
                  });
                },
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(20.0)),
              )) ,
            ),
            flex: 2,
          ): Container(width:0, height:0),
        ],
      ),
    );
  }

  Widget _getEditIcon() {
    return new GestureDetector(
      child: new CircleAvatar(
        backgroundColor: Colors.red,
        radius: 14.0,
        child: new Icon(
          Icons.edit,
          color: Colors.white,
          size: 16.0,
        ),
      ),
      onTap: () {
        setState(() {
          _status = false;
        });
      },
    );
  }
}