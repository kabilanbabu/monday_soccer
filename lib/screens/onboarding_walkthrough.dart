import 'package:flutter/material.dart';
import "package:flutter_swiper/flutter_swiper.dart";
import "../model/walkthrough.dart";
import 'package:shared_preferences/shared_preferences.dart';
import '../root_page.dart';
import 'widgets/custom_flat_button.dart';
import '../services/authentication.dart';

class WalkthroughScreen extends StatefulWidget {
  final SharedPreferences prefs;
  
  final List<Walkthrough> pages = [
    Walkthrough(
        image: Image.asset('assets/swiss_club_logo.png'),
        title: "Welcome to the\nSwiss Club Monday Social Soccer App",
        description:
            "Your one stop shop to signing up for game nights, see recent announcements and connect to other players.\n\n"
            "Please note this app is only for members of the Singapore Swiss Club Monday Night Soccer group.\n\n"
            "If you'd like to join, please reach out to andreas.kalkum@gmail.com",
    ),
    Walkthrough(
      icon: Icons.account_circle,
      title: "Let's get you settled",
      description:
          "The next pages help you to create a new user for this app & set up your player profile or sign in with a previously created user.\n\n"
          "Please use the email address that you have been receiving soccer invitations with. "
          "If you want to use a different email address, you will need to contact the admins first.\n\n"
          "If this is your first time using this app, type in the email address and a new password and click \"create user\".",
    ),
  ];

  WalkthroughScreen({this.prefs});

  @override
  _WalkthroughScreenState createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  bool _allowSwipe = true;
  bool _toggle = true;
  int _moveSteps = 0;
  SwiperController _controller = SwiperController();

  void toggleWalkThrough() {
    setState(() {
      _allowSwipe = false;
      _toggle = !_toggle;
      _toggle ? _moveSteps = 3 : _moveSteps = 2;
    });
  }

  Future<void> move(steps) async {
    _controller.move(steps);
  }
  

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => move(_moveSteps));
    return Scaffold(
      body: Swiper.children(
        autoplay: false,
        physics: _allowSwipe ? null : NeverScrollableScrollPhysics(),
        controller: _controller,
        index: 0,
        loop: false,
        pagination: new SwiperPagination(
          margin: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 40.0),
          builder: new DotSwiperPaginationBuilder(
              color: Colors.black12,
              activeColor: Colors.black54,
              size: 6.5,
              activeSize: 8.0),
        ),
        control: _allowSwipe ? SwiperControl(
                                iconPrevious: null,
                                iconNext: Icons.navigate_next,
                              ) 
                              : null,
        children: _getPages(context),
      ),
    );
  }

  List<Widget> _getPages(BuildContext context) {
    List<Widget> widgets = [];
    for (int i = 0; i < widget.pages.length; i++) {
      Walkthrough page = widget.pages[i];
      widgets.add(
        new Container(
          color: Colors.white,
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 70.0),
                child: (page.icon != null) ? 
                  Icon( //if icon is define show icon otherwise show image
                    page.icon,
                    size: 125.0,
                    color: Colors.blueGrey,
                  )
                :
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 110.0,
                    child: page.image,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 50.0, right: 50.0, left: 50.0),
                child: Text(
                  page.title,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    decoration: TextDecoration.none,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w700,
                    fontFamily: "OpenSans",
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  page.description,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    decoration: TextDecoration.none,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w300,
                    fontFamily: "OpenSans",
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: page.extraWidget,
              )
            ],
          ),
        ),
      );
    }
    widgets.add(RootPage(
      auth: new Auth(),
      toggleWalkThrough: toggleWalkThrough
    ));
    widgets.add(AllSet(
      toggleWalkThrough: toggleWalkThrough,
      prefs: widget.prefs,
    ));

    return widgets;
  }
}
  
class AllSet extends StatelessWidget {
    final Function() toggleWalkThrough;
    final SharedPreferences prefs;
    AllSet({this.toggleWalkThrough, @required this.prefs});
    
    @override
    Widget build(BuildContext context) {
      //WidgetsBinding.instance.addPostFrameCallback((_) => toggleWalkThrough());
      return Container(
        color: Colors.blueGrey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.code,
                size: 125.0,
                color: Colors.white,
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 50.0, right: 15.0, left: 15.0),
                child: Text(
                  "You're all set!",
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.none,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w700,
                    fontFamily: "OpenSans",
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 20.0, right: 15.0, left: 15.0),
                child: CustomFlatButton(
                  title: "Enter the App",
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  textColor: Colors.white,
                  onPressed: () {
                    prefs.setBool('accessed_before', true);
                    Navigator.of(context).pushNamed("/root");
                  },
                  splashColor: Colors.black12,
                  borderColor: Colors.white,
                  borderWidth: 2,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }
}