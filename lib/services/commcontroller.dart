import 'package:http/http.dart' as http;
import '../model/commtosheet.dart';
import 'keys.dart';

/// CommController is a class which does work of saving data in Google Sheets using 
/// HTTP GET request on Google App Script Web URL and parses response and sends result callback.
class CommController {
  // Callback function to give response of status of current request.
  final void Function(Object) callback; //return function of gscript API response for statusrequest
  
  // Google App Script Web URL.
  static const String URL = KeyValues.URL;
  
  // Success Status Message
  static const STATUS_SUCCESS = "SUCCESS";

  // Default Constructor
  CommController(this.callback);

  /// Async function which parses [commtosheet] parameters
  /// and sends HTTP GET request on [URL]. On successful response, [callback] is called and returned.
  void commWithSheet(CommToSheet commToSheet) async {
    try {
      await http.get(
        URL + commToSheet.toParams()
      ).then((response){
        callback(response.body); // return JSON object callback
      });    
    } catch (e) {
      print(e);
    }
  }
}