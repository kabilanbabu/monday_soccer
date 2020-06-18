# monday_soccer

A Flutter app for the Singapore Swiss Club Monday Soccer group. 

## Download official apps
<a href="https://apps.apple.com/us/app/swiss-club-monday-soccer/id1512167771?mt=8"> <img alt='Download in Appstore' src='https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2020-06-16&kind=iossoftware&bubble=ios_apps' width=145/>
</a>
<a href='https://play.google.com/store/apps/details?id=com.holmesnine.monday_soccer&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'><img alt='Get it on Google Play' src='https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png' width=145/>
</a>

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

written by andreas.kalkum@gmail.com

# monday_soccer
# monday_soccer
