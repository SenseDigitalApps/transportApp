// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future permissionSearch(List<String> listPermissions) async {
  // Add your function code here!
  for (String permission in listPermissions) {
    if (permission.startsWith("modulo")) {
      FFAppState().modulesPermissions.add(permission);
    }
  }

}
