import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../helpers/db_helper.dart';

class ListProvider extends ChangeNotifier {
  Future<List> getHashTags() async {
    try {
      final response = await http
          .get("https://bismarck.sdsu.edu/api/instapost-query/hashtags");
      final jsonResponse = convert.jsonDecode(response.body);
      await DBHelper.cleanTable('hashtags');
      jsonResponse['hashtags'].forEach((hashtag) => {
            DBHelper.insert('hashtags', {'hashtag': hashtag})
          });
      return jsonResponse['hashtags'];
    } catch (error) {
      throw (error);
    }
  }

  Future<List> getNicknames() async {
    try {
      final response = await http
          .get("https://bismarck.sdsu.edu/api/instapost-query/nicknames");
      final jsonResponse = convert.jsonDecode(response.body);
      await DBHelper.cleanTable('nickNames');
      jsonResponse['nicknames'].forEach((nickname) => {
            DBHelper.insert('nickNames', {'nickname': nickname})
          });
      return jsonResponse['nicknames'];
    } catch (error) {
      throw (error);
    }
  }

  Future<List<Map<String, dynamic>>> fetchOfflineHashtags() async {
    final datalist = await DBHelper.getData('hashtags', ['hashtag'], null);
    return datalist;
  }

  Future<List<Map<String, dynamic>>> fetchOfflineNickNames() async {
    final datalist = await DBHelper.getData('nickNames', ['nickname'], null);
    return datalist;
  }
}
