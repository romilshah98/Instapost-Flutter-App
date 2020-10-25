import 'dart:convert' as convert;
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

import './hashtag_list.dart';
import '../widgets/app_drawer.dart';
import '../widgets/picker.dart';
import '../providers/post_provider.dart';
import './auth_screen.dart';

class AddPost extends StatefulWidget {
  static const routeName = '/addPost';
  @override
  _AddPostState createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  final _form = GlobalKey<FormState>();
  String _base64EncodedImage;
  bool isLoading = false;
  Map<String, dynamic> _postData = {
    'title': '',
    'hashtags': [],
  };
  File image;

  void _submit() async {
    if (!_form.currentState.validate()) {
      return;
    }
    _form.currentState.save();
    setState(() {
      isLoading = true;
    });
    bool isOnline = await DataConnectionChecker().hasConnection;
    if (!isOnline) {
      File savedImage;
      if (image != null) {
        final appDir = await syspaths.getApplicationDocumentsDirectory();
        final fileName = path.basename(image.path);
        savedImage = await image.copy('${appDir.path}/$fileName');
      }
      final response =
          await Provider.of<PostProvider>(context).addNewPostOffline(
        _postData['title'],
        _postData['hashtags'],
        image == null ? '' : savedImage.path,
      );
      if (response != '') {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(
                'Post added offline and will be uploaded when you restart the app with internet connection!'),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
        Navigator.of(context).pushReplacementNamed(HashTagList.routeName);
        return;
      }
    } else {
      try {
        final response = await Provider.of<PostProvider>(context).addPost(
          _postData['title'],
          _postData['hashtags'],
        );
        final jsonResponse = convert.jsonDecode(response.body);
        if (jsonResponse['result'] == 'success') {
          await _uploadImage(jsonResponse['id']);
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              content: Text(jsonResponse['errors']),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Ok'),
                ),
              ],
            ),
          );
        }
      } catch (error) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: const Text(
                'Something went wrong. Please login try again later!'),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
        Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
        return;
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _uploadImage(int postID) async {
    try {
      if (_base64EncodedImage == null) {
        Navigator.of(context).pushReplacementNamed(HashTagList.routeName);
        return;
      }
      final response = await Provider.of<PostProvider>(context)
          .uploadImage(_base64EncodedImage, postID);
      final jsonResponse = convert.jsonDecode(response.body);
      if (jsonResponse['result'] == 'success') {
        Navigator.of(context).pushReplacementNamed(HashTagList.routeName);
        return;
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(jsonResponse['errors']),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text('Something went wrong. Please try again later!'),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    }
  }

  void pickImage(File pickedImage) {
    image = pickedImage;
    final imageBytes = pickedImage.readAsBytesSync();
    _base64EncodedImage = convert.base64Encode(imageBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Post'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submit,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Form(
                  key: _form,
                  child: Column(
                    children: <Widget>[
                      Picker(pickImage),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Title',
                        ),
                        validator: (value) {
                          value = value.trim();
                          if (value.isEmpty) {
                            return 'Invalid title!';
                          } else if (value.length > 144) {
                            return 'Title is too long!. Max limit is 144';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _postData['title'] = value;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'HashTags',
                        ),
                        validator: (value) {
                          value = value.trim();
                          List listValue = value.split(' ');
                          if (value.isEmpty) {
                            return 'Invalid hashTags!';
                          }
                          for (int index = 0;
                              index < listValue.length;
                              index++) {
                            if (listValue[index].length < 2 ||
                                listValue[index][0] != '#') {
                              return 'Every HashTag should start with # and should be atleast of length 2!';
                            }
                          }
                          return null;
                        },
                        onSaved: (value) {
                          value = value.trim();
                          List listValue = value.split(' ');
                          _postData['hashtags'] = listValue;
                        },
                      ),
                      RaisedButton(
                        child: const Text('Post'),
                        onPressed: _submit,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        color: Theme.of(context).primaryColor,
                        textColor:
                            Theme.of(context).primaryTextTheme.button.color,
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
