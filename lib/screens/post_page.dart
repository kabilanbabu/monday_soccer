import 'package:flutter/material.dart';
import '../model/post_model.dart';
import '../model/user_model.dart';
import '../model/comment_model.dart';
import 'widgets/inherited_widgets/inherited_post_model.dart';
import 'widgets/post_stats.dart';
import 'widgets/post_time_stamp.dart';
import 'widgets/user_details_with_follow.dart';
import 'widgets/comments_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/push_notifications.dart';

class PostPage extends StatefulWidget {
  const PostPage({Key key, @required this.postData, this.userData, this.documentID}) : super(key: key);

  final PostModel postData;
  final UserModel userData;
  final String documentID;

  @override
  State<StatefulWidget> createState() => new _PostPageState();
}

class _PostPageState extends State<PostPage> {

  final _commentFormKey = new GlobalKey<FormState>();
  TextEditingController commentController = TextEditingController();
  List<CommentModel> newCommentsList = [];
  bool _deleted = false;

  var _hasDeleteRight = false;
  void _increaseViewCounter() async {
    if (!_deleted) {
      final newViews = widget.postData.views + 1;
        Firestore.instance
          .collection('posts')
          .document(widget.documentID)
          .updateData({'views': newViews});
    }
  }

  void _deletePost() async {
    _deleted = true;
    Firestore.instance
        .collection('posts')
        .document(widget.documentID)
        .delete();
  }

  void _saveComment() {
    var form = _commentFormKey.currentState;
    if (form.validate()) {
      form.save();
    }

    newCommentsList = widget.postData.comments;

    CommentModel newComment = CommentModel(
        user: widget.userData,
        comment: commentController.text,
        time: DateTime.now(),
    );    

    newCommentsList.add(newComment);

    Map <String, dynamic> commentMap = newComment.toJson();
    commentMap['user'] = commentMap['user'].toJson();

    Firestore.instance
      .collection('posts')
      .document(widget.documentID)
      .updateData({
            'comments': FieldValue.arrayUnion([commentMap]),
            });
    final fcm = PushNotificationsManager();
    fcm.subscribeToTopic(widget.documentID);
    fcm.sendAndRetrieveMessage(title: '${widget.userData.firstName} commented on ${widget.postData.title} ',
      body: newComment.comment, topic: widget.documentID);
    setState(() {
      commentController.text = "";
    });
  }

  @override
  void initState() {
    var admin = widget.userData.admin;
    if (widget.postData.author.id == widget.userData.id || admin) {
      _hasDeleteRight = true;
     }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _increaseViewCounter();
    return Scaffold(
      appBar: AppBar(title: Text(widget.postData.title)),
      body: InheritedPostModel(
        postData: widget.postData,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            _bannerImage(),
            _nonImageContents(),
          ],
        ),
      ),
    );
  }

  Widget _nonImageContents(){
    final PostModel postData = widget.postData;

    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _summary(),
          PostTimeStamp(),
          _mainBody(),
          UserDetailsWithFollow(
            userData: postData.author,
          ),
          SizedBox(height: 8.0),
          CommentsList(commentsList: newCommentsList),
          _addComment(),
          PostStats(hearts: widget.postData.reacts),
          _hasDeleteRight ? _getActionButtons() : new Container(),
        ],
      ),
    );
  }

  Widget _bannerImage() {
    if (widget.postData.imageURL=='assets/swiss_club_logo.png') {
      return Container(
          child: Image.asset(
            widget.postData.imageURL,
            fit: BoxFit.fitWidth,
          ),
        );
    }
    else {  
      return Container(
          child: CachedNetworkImage(
            imageUrl: widget.postData.imageURL,
            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ));
    }
  }

  Widget _summary() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        widget.postData.summary,
        style: Theme.of(context).textTheme.headline1,
      ),
    );
  }

  Widget _mainBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        widget.postData.body,
        style: Theme.of(context).textTheme.bodyText1,
      ),
    );
  }

  Widget _addComment() {    
    final roundedContainer = ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        color: Colors.grey[300],
        child: Row(
          children: <Widget>[
            SizedBox(width: 8.0),
            Expanded(
              child: Form(
              key: _commentFormKey,
              child: Stack(    
                children: <Widget> [
                  Padding(
                  padding: EdgeInsets.only(right: 8.0, left: 8.0),
                    child: TextFormField(
                    controller: commentController,
                    //maxLength: 100,
                    validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                        },
                    //onEditingComplete: _saveComment,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type your comment',
                    ),
                    ),
                  ),
                  ]
                ),
              )
            ),
          ],
        ),
      ),
    );

    final inputBar = Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: roundedContainer,
          ),
          SizedBox(
            width: 5.0,
          ),
          CircleAvatar(
            backgroundColor: Colors.green,
            child: IconButton(
            icon: Icon(Icons.send, color: Colors.white, size: 26.0),
            onPressed: () {
              if (_commentFormKey.currentState.validate()) {
              _saveComment();
            }},
            )
            ),
        ],
      ),
    );    

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: inputBar,
    );
  }

Widget _getActionButtons() {
    return Padding(
      padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 25.0),
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Container(
                child: new RaisedButton(
                  child: new Text("Delete Post"),
                  textColor: Colors.white,
                  color: Colors.red,
                  onPressed: () {
                      setState(() {
                        _deletePost();
                        Navigator.pop(context, true);
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
