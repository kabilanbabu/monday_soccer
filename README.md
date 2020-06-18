# monday_soccer

A Flutter app for the Singapore Swiss Club Monday Soccer group. 

Features:
- Onboarding workflow / walkthrough
- Personal login with Firebase email & pw auth
- Overview of signed up players on game days
- Ability to sign up or opt out for game days
- some basic statistics
- Ability to create posts, and comment on such posts (stored on Firebase)
- Push notification support
- Player profile stored on Firebase
- Crashlytics support

Connects to google spreadsheet / WebApp as backend
uses Firebase Authentication, Firestore real time db, and Firebase storage

The app uses a set of keys and an additional encoding logic which is stored in /lib/services/keys.dart (not part of this libary). The structure of keys.dart can be taken from /lib/services/keys_template.dart

Furthermore, the app utilizes a google sheet web app. The code of this web app is currently not on GitHub. If interested, pls reach out to me.

<a href="https://apps.apple.com/us/app/swiss-club-monday-soccer/id1512167771?mt=8" style="display:inline-block;overflow:hidden;background:url(https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2020-06-16&kind=iossoftware&bubble=ios_apps) no-repeat;width:135px;height:40px;"></a>

written by andreas.kalkum@gmail.com

# monday_soccer
# monday_soccer
