import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String _email;
  String _password;

  String get email {
    return _email;
  }

  String get password {
    return _password;
  }

  Future registerUser(String email, String password, String firstName,
      String lastName, String nickName) async {
    try {
      final response = await http.get(
          "https://bismarck.sdsu.edu/api/instapost-upload/newuser?firstname=$firstName&lastname=$lastName&nickname=$nickName&email=$email&password=$password");
      final jsonResponse = convert.jsonDecode(response.body);
      if (jsonResponse['result']=="success") {
        _email = email;
        _password = password;
        notifyListeners();
      }
      return jsonResponse;
    } catch (error) {
      throw (error);
    }
  }

  Future authenticateUser(String email, String password) async {
    try {
      final response = await http.get(
          "https://bismarck.sdsu.edu/api/instapost-query/authenticate?email=$email&password=$password");
      final jsonResponse = convert.jsonDecode(response.body);
      if (jsonResponse['result']) {
        _email = email;
        _password = password;
        notifyListeners();
      }
      return jsonResponse;
    } catch (error) {
      throw (error);
    }
  }
}
