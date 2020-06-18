import 'package:flutter/material.dart';
import '../../model/comment_model.dart';
import '../widgets/inherited_widgets/inherited_post_model.dart';
import '../widgets/user_details_with_follow.dart';

class CommentsListKeyPrefix {
  static final String singleComment = "Comment";
  static final String commentUser = "Comment User";
  static final String commentText = "Comment Text";
  static final String commentDivider = "Comment Divider";
}

class CommentsList extends StatelessWidget {
  const CommentsList({Key key, this.commentsList}) : super(key: key);
  final List<CommentModel> commentsList;

  @override
  Widget build(BuildContext context) {
    List<CommentModel> comments;
    String commentText;
    commentsList == [] ? comments = commentsList : comments = InheritedPostModel.of(context).postData.comments;
    comments.length == 1 ? commentText = "${comments.length.toString()} Comment" : commentText = "${comments.length.toString()} Comments";
    

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ExpansionTile(
        leading: Icon(Icons.comment),
        initiallyExpanded: true,
        title: Text(commentText, style: Theme.of(context).textTheme.headline2),
        children: List<Widget>.generate(
          comments.length,
          (int index) => _SingleComment(
            key: ValueKey("${CommentsListKeyPrefix.singleComment} $index"),
            index: index,
          ),
        ),
      ),
    );
  }
}

class _SingleComment extends StatelessWidget {
  final int index;

  const _SingleComment({Key key, @required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CommentModel commentData =
        InheritedPostModel.of(context).postData.comments[index];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UserDetailsWithFollow(
            key: ValueKey("${CommentsListKeyPrefix.commentUser} $index"),
            userData: commentData.user,
          ),
          Padding(
            padding: EdgeInsets.only(top: 5.0, left: 44.0, ),
            child: 
            Text(
              commentData.comment,
              key: ValueKey("${CommentsListKeyPrefix.commentText} $index"),
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.headline5,
            ),
          ),
          Divider(
            key: ValueKey("${CommentsListKeyPrefix.commentDivider} $index"),
            color: Colors.black45,
          ),
        ],
      ),
    );
  }
}