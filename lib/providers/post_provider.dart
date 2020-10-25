import 'dart:io';
import 'dart:typed_data';
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as syspaths;

import '../helpers/db_helper.dart';

class PostProvider extends ChangeNotifier {
  String _email = '';
  String _password = '';

  PostProvider(this._email, this._password);

  Future getPost(int postID) async {
    try {
      final response = await http.get(
          'https://bismarck.sdsu.edu/api/instapost-query/post?post-id=$postID');
      final jsonResponse = convert.jsonDecode(response.body);
      if (jsonResponse['result'] == 'success') {
        _addPostOffline(jsonResponse['post']);
        if (jsonResponse['post']['image'] != -1) {
          final decodedImage = await _getImage(jsonResponse['post']['image']);
          return [jsonResponse, decodedImage];
        }
      }
      return [jsonResponse, -1];
    } catch (error) {
      throw (error);
    }
  }

  Future<void> _addPostOffline(post) async {
    final imagePath =
        post['image'] == -1 ? '' : await saveImageOffline(post['image']);
    DBHelper.insert('posts', {
      'id': post['id'],
      'text': post['text'],
      'ratings_count': post['ratings-count'],
      'ratings_average': post['ratings-average'],
      'image': imagePath,
      'hashtags': post['hashtags'].join(' '),
    });
    post['comments'].forEach((comment) => {
          DBHelper.insert('comments', {
            'postID': post['id'],
            'comment': comment,
          })
        });
  }

  Future<String> saveImageOffline(imageID) async {
    try {
      final response = await http.get(
          'https://bismarck.sdsu.edu/api/instapost-query/image?id=$imageID');
      final jsonResponse = convert.jsonDecode(response.body);
      final Uint8List decodedImage =
          convert.base64Decode(jsonResponse['image']);
      final appDir = (await syspaths.getApplicationDocumentsDirectory()).path;
      File file = File("$appDir/" + '$imageID' + ".jpg");
      await file.writeAsBytes(decodedImage);
      return file.path;
    } catch (error) {
      return '';
    }
  }

  Future getOfflinePost(int postID) async {
    final posts = await DBHelper.getData(
      'posts',
      [
        'id',
        'text',
        'ratings_count',
        'ratings_average',
        'image',
        'hashtags',
      ],
      'id=$postID',
    );
    return posts;
  }

  Future<List> getComments(int postID) async {
    final comments = DBHelper.getData(
      'comments',
      ['comment'],
      'postID=$postID',
    );
    return comments;
  }

  Future _getImage(int imageID) async {
    try {
      final response = await http.get(
          'https://bismarck.sdsu.edu/api/instapost-query/image?id=$imageID');
      final jsonResponse = convert.jsonDecode(response.body);
      final Uint8List decodedImage =
          convert.base64Decode(jsonResponse['image']);
      return decodedImage;
    } catch (error) {
      return -1;
    }
  }

  Future addPost(
    String text,
    List hashtags,
  ) async {
    try {
      final response = await http.post(
        'https://bismarck.sdsu.edu/api/instapost-upload/post',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: convert.jsonEncode({
          "email": _email,
          "password": _password,
          "text": text,
          "hashtags": hashtags,
        }),
      );
      return response;
    } catch (error) {
      throw (error);
    }
  }

  Future addNewPostOffline(String text, List hashtags, String image) async {
    try {
      DBHelper.insert('newposts',
          {'text': text, 'hashtags': hashtags.join(' '), 'image': image});
      return 'Post Added!';
    } catch (error) {
      throw (error);
    }
  }

  Future<List<Map<String, dynamic>>> fetchOfflinePosts() async {
    final posts =
        await DBHelper.getData('newposts', ['text', 'hashtags', 'image'], null);
    return posts;
  }

  Future uploadImage(String base64EncodedImage, int postID) async {
    try {
      final response = await http.post(
        'https://bismarck.sdsu.edu/api/instapost-upload/image',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: convert.jsonEncode({
          "email": _email,
          "password": _password,
          "image": base64EncodedImage,
          "post-id": postID,
        }),
      );
      return response;
    } catch (error) {
      throw (error);
    }
  }

  Future ratePost(int postID, int rating) async {
    try {
      final response = await http.post(
        'https://bismarck.sdsu.edu/api/instapost-upload/rating',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: convert.jsonEncode({
          'email': _email,
          'password': _password,
          'rating': rating,
          'post-id': postID,
        }),
      );
      return response;
    } catch (error) {
      throw (error);
    }
  }

  Future addComment(int postID, String comment) async {
    try {
      final response = await http.post(
        'https://bismarck.sdsu.edu/api/instapost-upload/comment',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: convert.jsonEncode({
          'email': _email,
          'password': _password,
          'comment': comment,
          'post-id': postID,
        }),
      );
      return response;
    } catch (error) {
      throw (error);
    }
  }
}
