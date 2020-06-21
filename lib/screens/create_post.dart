import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/user_model.dart';
import 'take_picture.dart';
import 'package:flutter/services.dart';
import '../model/post_model.dart';
import '../services/push_notifications.dart';

class CreatePostPage extends StatefulWidget {
  CreatePostPage ({Key key, this.title, this.user, this.logoutCallback})
      : super(key: key);

  final String title;
  final VoidCallback logoutCallback;
  final UserModel user;

  @override
  _CreatePostPage createState() => _CreatePostPage();
}

class _CreatePostPage extends State<CreatePostPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  UserModel userData = UserModel(firstName: "Test");
  bool hasBanner = false;
  var postBanner;

  var documentID;
  // TextField Controllers
  TextEditingController titleController = TextEditingController();
  TextEditingController summaryController = TextEditingController();
  TextEditingController bodyController = TextEditingController();
                
  final _formKey = new GlobalKey<FormState>();
  
  final FocusNode myFocusNode = FocusNode();

  Future<UserModel> getUserData() async {
      UserModel userData;
      var result = await Firestore.instance
      .collection("users")
      .where("id", isEqualTo: widget.user.id)
      .getDocuments();
      result.documents.forEach((res) {
        userData = UserModel.fromJson(res.data);
        documentID = res.documentID;
      });
      return userData;
  }

  void _savePostData() async {
    var form = _formKey.currentState;
    if (form.validate()) {
      form.save();
    }

  // List<CommentModel> demoComments = DemoValues.comments; // for debug

    final PostModel postData = PostModel(
        author: widget.user, 
        title: titleController.text, 
        summary: summaryController.text, 
        body: bodyController.text,
        postTime: DateTime.now(),
        imageURL: 'assets/swiss_club_logo.png',
        heartedBy: [''],
        comments: [],
        reacts: 0,
        views: 0
    );
    
    // transform PostModel to Map / List objects that Firestore can handle
    Map <String, dynamic> postMap = postData.toJson();
    postMap['author'] = postMap['author'].toJson();  // transform author from UserModel

    // postMap['comments'] = postMap['comments'].map((comment) => comment.toJson()).toList(); // transform Comment from CommentModel
    // for (int i=0; i < postMap['comments'].length; i++) { // transform user within each comment to map
    //   postMap['comments'][i]['user'] = postMap['comments'][i]['user'].toJson();
    // }

    final fcm = PushNotificationsManager(); 

    Firestore.instance
      .collection('posts')
      .add(postMap).then((doc) async {
          documentID = doc.documentID;
          var bannerURL;
          if (hasBanner) {
            bannerURL = await _savePostBanner(postBanner, documentID);
          }
          doc.updateData({
            'id': documentID,
            'imageURL': hasBanner ? bannerURL : 'assets/swiss_club_logo.png',
            });
            fcm.sendAndRetrieveMessage(title: 'New post from ${postData.author.firstName}', body: postData.title);
            fcm.subscribeToTopic(documentID);
        }).catchError((error) {
          print(error);
        });
  }

  _showPostBanner() {
    if (hasBanner) {
      return FileImage(postBanner);
    }
    else {
      return ExactAssetImage('assets/swiss_club_logo.png');
    }
  }

  void _navToTakePicture() async {
    postBanner = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => new TakePicture(
            title: 'Select or take a post picture',
            userId: widget.user.id,
            userDocumentID: documentID,
          )),
    );
    if (postBanner != null) {
      hasBanner = true;
      setState((){});
    }
  }

  Future<String> _savePostBanner(_imageFile, documentID) async {
    String filename = documentID;
    var file = _imageFile;
    StorageReference storageReference;
    storageReference = FirebaseStorage.instance.ref().child("postpics/$filename");

    final StorageUploadTask uploadTask = storageReference.putFile(file);
    final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
    final String url = (await downloadUrl.ref.getDownloadURL());
    return url;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false, 
      resizeToAvoidBottomInset: true, 
      key: _scaffoldKey,  
      appBar: AppBar(title: Text(widget.title)),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarColor: Colors.transparent, // transparent status bar
          systemNavigationBarColor: Colors.black, // navigation bar color
          statusBarIconBrightness: Brightness.light, // status bar icons' color
          systemNavigationBarIconBrightness: Brightness.light, //navigation bar icons' color
        ),

        child: Form(
          key: _formKey,
          autovalidate: true,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              _bannerImage(),
              _nonImageContents(),
              _getActionButtons(),
            ],
          ),
      )
    ),
    );
  }

  Widget _nonImageContents(){
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _title(),
          _summary(),
          _mainBody(),
          SizedBox(height: 8.0),
        ],
      ),
    );
  }

  Widget _bannerImage() {                  
     return new Stack(fit: StackFit.loose, children: <Widget>[
        new Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Container(
                width: 200.0,
                height: 200.0,
                child: new Image(
                    image: _showPostBanner(),
                    fit: BoxFit.cover,
                  ),
                ),
          ],
        ),
        Padding(
            padding: EdgeInsets.only(top: 180.0, right: 0.0),
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
                ),
              ],
            )),
      ]);
  }
  
  Widget _title() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: TextFormField(
        controller: titleController,
        maxLengthEnforced: true,
        maxLength: 25,
        enabled: true,
        keyboardType: TextInputType.text,
        style: Theme.of(context).textTheme.headline2,
        validator: (value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
              },
        decoration: InputDecoration(
          labelText: 'Title',
          labelStyle: TextStyle(color: Colors.black54),
          hintText: 'Enter the title for your post',
        ),
      ),
    );
  }

  Widget _summary() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: TextFormField(
        controller: summaryController,
        enabled: true,
        keyboardType: TextInputType.multiline,
        maxLengthEnforced: true,
        maxLength: 75,
        minLines: 1,
        maxLines: 3,
        style: Theme.of(context).textTheme.headline3,
        validator: (value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
              },
        decoration: InputDecoration(
          labelText: 'Summary',
          labelStyle: TextStyle(color: Colors.black54),
          hintText: 'Enter a summary for your post',
        ),
      ),
    );
  }

  Widget _mainBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: bodyController,
        enabled: true,
        keyboardType: TextInputType.multiline,
        minLines: 4,
        maxLines: 10,
        style: Theme.of(context).textTheme.bodyText1,
        decoration: InputDecoration(
          labelText: 'Post body',
          labelStyle: TextStyle(color: Colors.black54),
          hintText: 'Enter your main body',
        ),
    ));
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
                    if (_formKey.currentState.validate()) {
                      setState(() {
                        _savePostData();
                        FocusScope.of(context).requestFocus(new FocusNode());
                        //final snackBar = SnackBar(content: Text('Post saved'));
                        //_scaffoldKey.currentState.showSnackBar(snackBar); 
                        Navigator.pop(context, true);
                    });
                  }
                },
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(20.0)),
              )),
            ),
            flex: 2,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Container(
                  child: new RaisedButton(
                child: new Text("Cancel"),
                textColor: Colors.white,
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    FocusScope.of(context).requestFocus(new FocusNode());
                    Navigator.pop(context, false);
                  });
                },
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(20.0)),
              )),
            ),
            flex: 2,
          ),
        ],
      ),
    );
  }
}

