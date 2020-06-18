/// CommToSheet is a data class which stores data fields for spreadsheet communication.
class CommToSheet {
  String _app; // instruction to the app
  String _param; // parameter, eg. date or player email

  CommToSheet(this._app, this._param);

  // Method to make GET parameters.
  String toParams() => "?app=$_app&$_param";
}