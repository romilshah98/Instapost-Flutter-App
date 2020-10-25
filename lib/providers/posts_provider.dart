import 'dart:convert' as convert;
import 'dart:core';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../helpers/db_helper.dart';

class Posts with ChangeNotifier {
  Future<List> getPostIDsByHashTag(String hashtag) async {
    try {
      final String encodedHashtag = hashtag.replaceAll('#', '%23');
      final response = await http.get(
          "https://bismarck.sdsu.edu/api/instapost-query/hashtags-post-ids?hashtag=$encodedHashtag");
      final jsonResponse = convert.jsonDecode(response.body);
      DBHelper.insert('hashtagPosts', {
        'hashtag': hashtag,
        'ids': jsonResponse['ids'].map((id) => id.toString()).join(',')
      });
      return jsonResponse['ids'];
    } catch (error) {
      throw (error);
    }
  }

  Future<List> getPostIDsByNickName(String nickName) async {
    try {
      final response = await http.get(
          "https://bismarck.sdsu.edu/api/instapost-query/nickname-post-ids?nickname=$nickName");
      final jsonResponse = convert.jsonDecode(response.body);
      DBHelper.insert('nicknamePosts', {
        'nickname': nickName,
        'ids': jsonResponse['ids'].map((id) => id.toString()).join(',')
      });
      return jsonResponse['ids'];
    } catch (error) {
      throw (error);
    }
  }

  Future getOfflinePostsByHashtag(String hashtag) async {
    try {
      final hashtagList = await DBHelper.getData(
        'hashtagposts',
        ['hashtag', 'ids'],
        'hashtag="$hashtag"',
      );
      return hashtagList;
    } catch (error) {
      return [];
    }
  }

  Future getOfflinePostsByNickName(String nickname) async {
    try {
      final nicknameList = await DBHelper.getData(
        'nicknameposts',
        ['nickname', 'ids'],
        'nickname="$nickname"',
      );
      return nicknameList;
    } catch (error) {
      return [];
    }
  }
}
