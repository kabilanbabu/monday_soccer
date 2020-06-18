import 'package:json_annotation/json_annotation.dart';
part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String nickName;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String image;
  final List<String> position;
  final String clubAccNo;
  final DateTime birthDay;
  final bool admin;

  UserModel({
    this.id,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.email,
    this.image,
    this.nickName,
    this.position,
    this.clubAccNo,
    this.admin,
    this.birthDay,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

}

class Player {
  static final positions = [
                    {
                      "display": "Goalie",
                      "value": "Goalie",
                      "abbr": "GK"
                    },
                    {
                      "display": "Defense",
                      "value": "Defense",
                      "abbr": "DF"
                    },
                    {
                      "display": "Right/Left-Midfield",
                      "value": "Right/Left-Midfield",
                      "abbr": "RLM"
                    },
                    {
                      "display": "Center-Midfield",
                      "value": "Center-Midfield",
                      "abbr": "CM"
                    },
                    {
                      "display": "Striker",
                      "value": "Striker",
                      "abbr": "ST"
                    },
                  ];
  static final strength = ['ok-lah', 'solid', 'ex-pro', 'Messi of age'];
}