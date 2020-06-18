// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostModel _$PostModelFromJson(Map<String, dynamic> json) {
  return PostModel(
    id: json['id'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    body: json['body'] as String,
    imageURL: json['imageURL'] as String,
    author: json['author'] == null
        ? null
        : UserModel.fromJson(json['author'] as Map<String, dynamic>),
    postTime: json['postTime'] == null
        ? null
        : DateTime.parse(json['postTime'] as String),
    reacts: json['reacts'] as int,
    views: json['views'] as int,
    heartedBy: json['heartedBy'] as List,
    comments: (json['comments'] as List)
        ?.map((e) =>
            e == null ? null : CommentModel.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$PostModelToJson(PostModel instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'summary': instance.summary,
      'body': instance.body,
      'imageURL': instance.imageURL,
      'postTime': instance.postTime?.toIso8601String(),
      'reacts': instance.reacts,
      'views': instance.views,
      'author': instance.author,
      'heartedBy': instance.heartedBy,
      'comments': instance.comments,
    };
