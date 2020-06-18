import 'package:flutter/material.dart';
import '../services/commcontroller.dart';
import '../model/commtosheet.dart';
import 'dart:convert' as convert;

  // TextField Controllers
  TextEditingController dateController = TextEditingController();
  TextEditingController appController = TextEditingController();

void main() => _submitForm();

void _submitForm() {

 
      appController.text = "statusrequest"; // replace later with some UI feature
      dateController.text = "16 Mar, 2020";

      CommToSheet commToSheet = CommToSheet(
        appController.text, 
        convert.base64Url.encode(convert.utf8.encode(dateController.text)), // changing date to base64
      );

      CommController commController = CommController((Object response) {
          print (response);
          //print (response)
        }
      );
      
      commController.commWithSheet(commToSheet);
  }
