class KeyValues {
  static final String sheetCommKey = 'your own key to secure communication with google sheets';
  static const String URL = "your own link to google sheet web app API"; // prod sheet
  
  static const String fcmKey = 'your own key for firebase cloud messaging';
  
  static enc(String eMail) {
    String encoded = "";
    
    // add your own encoding logic if addtl. encoding is desired
    
    encoded = eMail;
    return encoded;
  }
}