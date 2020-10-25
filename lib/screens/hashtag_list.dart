import 'dart:io';
import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

import '../widgets/app_drawer.dart';
import './hashtag_posts.dart';
import './add_post.dart';
import '../providers/list_provider.dart';
import '../providers/post_provider.dart';
import '../helpers/db_helper.dart';
import '../screens/auth_screen.dart';

class HashTagList extends StatelessWidget {
  static const routeName = '/hashtags';
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _uploadOfflinePosts(BuildContext context) async {
    final offlinePosts =
        await Provider.of<PostProvider>(context).fetchOfflinePosts();
    try {
      offlinePosts.forEach(
        (post) async {
          try {
            final response = await Provider.of<PostProvider>(context).addPost(
              post['text'],
              post['hashtags'].split(' '),
            );
            final jsonResponse = convert.jsonDecode(response.body);
            if (jsonResponse['result'] == 'success') {
              if (post['image'] != '') {
                String _base64EncodedImage =
                    convert.base64Encode(File(post['image']).readAsBytesSync());
                final imageUploadResponse =
                    await Provider.of<PostProvider>(context)
                        .uploadImage(_base64EncodedImage, jsonResponse['id']);
                final jsonImageUploadResponse =
                    convert.jsonDecode(imageUploadResponse.body);
                if (jsonImageUploadResponse['result'] != 'success') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      content: const Text(
                          'Could not upload image of your offline post!'),
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
                try {
                  final file = File(post['image']);
                  await file.delete();
                } catch (error) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      content:
                          const Text('Could not delete images from device!'),
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
            } else {
              Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
              return;
            }
          } catch (error) {
            Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
            return;
          }
        },
      );
      DBHelper.cleanTable('newposts');
      if (offlinePosts.length > 0) {
        final snackBar = SnackBar(
          content: Text('Offline Posts uploaded!'),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text('Could not upload your offline posts!'),
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

  Future<List> _getHashTags(BuildContext context) async {
    try {
      bool isOnline = await DataConnectionChecker().hasConnection;
      if (isOnline) {
        await _uploadOfflinePosts(context);
        final response = await Provider.of<ListProvider>(context).getHashTags();
        return [response, isOnline];
      } else {
        final response =
            await Provider.of<ListProvider>(context).fetchOfflineHashtags();
        return [response, isOnline];
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
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Hash Tags'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(AddPost.routeName);
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: FutureBuilder(
        future: _getHashTags(context),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            List hashTags = snapshot.data[0];
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: hashTags.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  children: [
                    InkWell(
                      splashColor: Colors.blue.withAlpha(30),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          HashTagPosts.routeName,
                          arguments: snapshot.data[1]
                              ? hashTags[index]
                              : hashTags[index]['hashtag'],
                        );
                      },
                      child: Card(
                        elevation: 5,
                        child: ListTile(
                          title: Text(
                            snapshot.data[1]
                                ? '${hashTags[index]}'
                                : '${hashTags[index]['hashtag']}',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushReplacementNamed(AddPost.routeName);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
