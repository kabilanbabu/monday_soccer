import 'package:flutter/material.dart';
import '../../model/common.dart';
import '../../model/user_model.dart';
import 'inherited_widgets/inherited_user_model.dart';
import 'package:firebase_image/firebase_image.dart';

class UserDetails extends StatelessWidget {
  final UserModel userData;

  const UserDetails({Key key, @required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InheritedUserModel(
      userData: userData,
      child: Container(
        child: Row(children: <Widget>[_UserImage(), _UserNameAndEmail()]),
      ),
    );
  }
}

class _UserNameAndEmail extends StatelessWidget {
  const _UserNameAndEmail({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserModel userData = InheritedUserModel.of(context).userData;
    final TextStyle nameTheme = Theme.of(context).textTheme.subtitle1;
    //final TextStyle emailTheme = Theme.of(context).textTheme.body1;
    final int flex = isLandscape(context) ? 10 : 5;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(userData.firstName, style: nameTheme),
          ],
        ),
      ),
    );
  }
}

class _UserImage extends StatelessWidget {
  const _UserImage({Key key}) : super(key: key);
  
  String getInitials(UserModel player) {
    String initials = player.firstName.substring(0,1) + player.lastName.substring(0,1);
    return initials.toUpperCase();
  }
  
  getPlayerThumbnail(UserModel user) {
        if (user.image != null) {
         var _playerThumbnail = 'gs://swissclubmondaysoccer.appspot.com/profilepics/thumbs/${user.id}_200x200'; 
         var _thumb = FirebaseImage(_playerThumbnail);
           return CircleAvatar(
                  backgroundImage: _thumb,
                  maxRadius: 20,
                );
      } else {
        return CircleAvatar(
          backgroundColor: Colors.blueGrey,
          child: Text(getInitials(user), style: TextStyle(fontWeight: FontWeight.bold)),
          maxRadius: 20);
      }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel userData = InheritedUserModel.of(context).userData;
    return getPlayerThumbnail(userData);
  }
}
