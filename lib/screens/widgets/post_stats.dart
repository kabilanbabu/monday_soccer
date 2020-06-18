import 'package:flutter/material.dart';
import '../../model/post_model.dart';
import '../widgets/inherited_widgets/inherited_post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/push_notifications.dart';

class PostStats extends StatefulWidget {
  final int hearts;

  const PostStats({Key key, this.hearts}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => new _PostStatsState();
  
}


class _PostStatsState extends State<PostStats> {
  
  var _heartsIcon;
  dynamic _hearts;
  dynamic _setState = false;
  var newHearts = 0;
  var _newHeartsIcon;
  
  Future<String> getUserId() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
  }

  _setHeartsIcon()async{
      final PostModel postData = InheritedPostModel.of(context).postData;
      if  (_setState) {
        _hearts = newHearts;
        _heartsIcon = _newHeartsIcon;
      }
        else {
        final userId = await getUserId();
          if (postData.heartedBy.contains(userId)) {
            _heartsIcon = Icons.favorite;
          }
          else {
            _heartsIcon = Icons.favorite_border;
          }
          _hearts = widget.hearts;
          _setState = false;
      }
  }

  void _heartOrUnheart () async {
      final PostModel postData = InheritedPostModel.of(context).postData;
      var result = await Firestore.instance
          .collection("posts")
          .where("id", isEqualTo: postData.id)
          .getDocuments();
      
      bool postHearted = false;

      final userId = await getUserId();
      var documentID = '';
      final fcm = PushNotificationsManager(); 

      result.documents.forEach((res) {
        if (res.data['heartedBy'].contains(userId)) {
          postHearted = true;
        }
      });
      
      if (postHearted) {
        result.documents.forEach((res) { // remove Heart
          newHearts = res.data['reacts'] - 1;
          Firestore.instance
            .collection('posts')
            .document(res.documentID)
            .updateData({'heartedBy': FieldValue.arrayRemove([userId]), 'reacts': newHearts});
            documentID = res.documentID;
          });
        fcm.unsubscribeFromTopic(documentID);
        _newHeartsIcon = Icons.favorite_border;
      } else {

        result.documents.forEach((res) { // set Heart
          newHearts = res.data['reacts'] + 1;
          Firestore.instance
            .collection('posts')
            .document(res.documentID)
            .updateData({'heartedBy': FieldValue.arrayUnion([userId]), 'reacts': newHearts});
            documentID = res.documentID;
        });
        fcm.subscribeToTopic(documentID);
        _newHeartsIcon = Icons.favorite;
      }
     
      setState((){
            _setState = true;
           });
    }

  @override
  Widget build(BuildContext context) {
    
    return FutureBuilder<void>(
        future: _setHeartsIcon(), // async work
        builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.done) {
            return _showStats();
          }
          else {
            // Otherwise, display a loading indicator.
            return _showStats();
          }
         },
    );
  }

  Widget _showStats(){
    
    final PostModel postData = InheritedPostModel.of(context).postData;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        
        _showStat(
            _heartsIcon,
            _hearts,
            Colors.red[300],
            _heartOrUnheart
            ),

        _showStat(
          Icons.comment,
          postData.comments.length,
          Colors.blueGrey,
          null
        ),    

        _showStat(
          Icons.remove_red_eye,
          postData.views,
          Colors.blueGrey,
          null
        ),
      ],
    );
  }

  Widget _showStat(IconData icon, int number,Color color, Function buttonAction) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 2.0),
          child: IconButton(icon: Icon(icon), color: color,  onPressed: buttonAction,
          enableFeedback: true,),
        ),
        Text(number.toString()),
      ],
    );
  }
}
