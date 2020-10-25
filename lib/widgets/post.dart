import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

import '../screens/comments.dart';
import '../providers/post_provider.dart';
import './ratebar.dart';

class Post extends StatelessWidget {
  final int postID;
  Post(this.postID);
  Future _getPost(int postID, BuildContext context) async {
    bool isOnline = await DataConnectionChecker().hasConnection;
    if (isOnline) {
      try {
        final response =
            await Provider.of<PostProvider>(context).getPost(postID);
        if (response[0]['result'] != 'success') {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              content: Text(response['errors']),
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
        } else {
          return [response, isOnline];
        }
      } catch (error) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content:
                const Text('Something went wrong. Please try again later!'),
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
    } else {
      final response =
          await Provider.of<PostProvider>(context).getOfflinePost(postID);
      final comments =
          await Provider.of<PostProvider>(context).getComments(postID);
      final imagePath = response[0]['image'];
      if (imagePath == '') {
        return [response[0], isOnline, -1, comments];
      }
      final image = File(imagePath);
      return [response[0], isOnline, image.readAsBytesSync(), comments];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getPost(postID, context),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final post =
              snapshot.data[1] ? snapshot.data[0][0]['post'] : snapshot.data[0];
          final image =
              snapshot.data[1] ? snapshot.data[0][1] : snapshot.data[2];
          return Stack(
            children: <Widget>[
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.face),
                          Text(
                            'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    image != -1
                        ? Container(
                            width: double.infinity,
                            child: Image.memory(
                              image,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            height: 150,
                            width: 150,
                            color: Colors.white,
                          ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              snapshot.data[1]
                                  ? RateBar(
                                      postID,
                                      post['ratings-average'] == -1
                                          ? 0.0
                                          : post['ratings-average'],
                                      post['ratings-count'],
                                    )
                                  : RateBar(
                                      postID,
                                      post['ratings_average'] == -1
                                          ? 0.0
                                          : post['ratings_average'],
                                      post['ratings_count'],
                                    ),
                              GestureDetector(
                                child: Icon(Icons.comment),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Comments(
                                          postID: post['id'],
                                          comments: snapshot.data[1]
                                              ? post['comments']
                                              : snapshot.data[3],
                                          isOnline: snapshot.data[1]),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Text(
                            '${post['text']}',
                            style: const TextStyle(fontSize: 15),
                          ),
                          Text(
                            snapshot.data[1]
                                ? '${post['hashtags'].join(' ')}'
                                : '${post['hashtags']}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
