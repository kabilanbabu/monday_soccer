import 'package:intl/intl.dart';
import 'comment_model.dart';
import 'user_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_model.g.dart';

@JsonSerializable()
class PostModel {
  final String id, title, summary, body, imageURL;
  final DateTime postTime;
  final int reacts, views;
  final UserModel author;
  final List heartedBy;
  final List<CommentModel> comments;

  PostModel({
    this.id,
    this.title,
    this.summary,
    this.body,
    this.imageURL,
    this.author,
    this.postTime,
    this.reacts,
    this.views,
    this.heartedBy,
    this.comments,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => _$PostModelFromJson(json);
  Map<String, dynamic> toJson() => _$PostModelToJson(this);
  

  String get postTimeFormatted => DateFormat.yMMMMEEEEd().format(postTime);
}
