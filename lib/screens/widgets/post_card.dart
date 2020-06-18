import 'package:flutter/material.dart';
import '../../model/common.dart';
import '../../model/post_model.dart';
import '../../model/user_model.dart';
import '../post_page.dart';
import 'inherited_widgets/inherited_post_model.dart';
import 'post_stats.dart';
import 'post_time_stamp.dart';
import 'user_details.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostCard extends StatefulWidget {
  final PostModel postData;
  final UserModel userData;
  final String documentID;

  const PostCard({Key key, @required this.postData, this.userData, this.documentID}) : super(key: key);
  @override
  State<StatefulWidget> createState() => new _PostCardState();
}

class _PostCardState extends State<PostCard> {
  
  @override
  Widget build(BuildContext context) {
    final double aspectRatio = isLandscape(context) ? 6 / 2 : 6 / 3;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => new PostPage(
            postData: widget.postData, 
            userData: widget.userData, 
            documentID: widget.documentID
          )));
      },
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Card(
          elevation: 2,
          child: Container(
            margin: const EdgeInsets.all(4.0),
            padding: const EdgeInsets.all(4.0),
            child: InheritedPostModel(
              postData: widget.postData,
              child: Column(
                children: <Widget>[
                  _post(),
                  Divider(color: Colors.grey),
                  _postDetails(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _post() {
    return Expanded(
      flex: 3,
      child: Row(children: <Widget>[_postImage(), _postTitleSummaryAndTime()]),
    );
  }

  Widget _postTitleSummaryAndTime() {
    final TextStyle titleTheme = Theme.of(context).textTheme.headline2;
    final TextStyle summaryTheme = Theme.of(context).textTheme.bodyText1;
    final String title = widget.postData.title;
    final String summary = widget.postData.summary;
    final int flex = isLandscape(context) ? 5 : 3;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(title, style: titleTheme),
                SizedBox(height: 2.0),
                Text(summary, style: summaryTheme),
              ],
            ),
            PostTimeStamp(alignment: Alignment.centerRight),
          ],
        ),
      ),
    );
  }

  Widget _postImage() {
    if (widget.postData.imageURL=='assets/swiss_club_logo.png') {
      return Expanded(flex: 2, child: Image.asset(widget.postData.imageURL)); 
    }
    else {  
      return Expanded(flex: 2, 
          child:
          Padding(
            padding: EdgeInsets.only(left: 8.0, right: 20.0, top:3.0, bottom: 3.0),
          child: ClipRRect(
              borderRadius: BorderRadius.all(
                const Radius.circular(30.0),
              ),
          child: CachedNetworkImage(
              imageUrl: widget.postData.imageURL,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      colorFilter:
                          ColorFilter.mode(Colors.white, BlendMode.colorBurn)),
                  shape: BoxShape.rectangle
                ),
              ),
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            )
          )
        )
      );
    }
  }


  Widget _postDetails() {
    return Row(
      children: <Widget>[
        Expanded(flex: 1, child: UserDetails(userData: widget.postData.author)),
        Expanded(flex: 1, child: PostStats(hearts: widget.postData.reacts),)
      ],
    );
  }
}

