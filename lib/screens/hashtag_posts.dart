import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

import '../widgets/post.dart';
import '../providers/posts_provider.dart';

class HashTagPosts extends StatelessWidget {
  static const routeName = '/hashTagPosts';

  Future<List> _getPosts(String hashtag, BuildContext context) async {
    bool isOnline = await DataConnectionChecker().hasConnection;
    if (isOnline) {
      try {
        final response =
            await Provider.of<Posts>(context).getPostIDsByHashTag(hashtag);
        return response;
      } catch (error) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text('Something went wrong. Please try again later!'),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
                child: Text('Ok'),
              ),
            ],
          ),
        );
        return [];
      }
    } else {
      final response =
          await Provider.of<Posts>(context).getOfflinePostsByHashtag(hashtag);
      if (response == null || response.length == 0) {
        return [];
      }
      final ids =
          response[0]['ids'].split(',').map((id) => int.parse(id)).toList();
      return ids;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hashtag = ModalRoute.of(context).settings.arguments as String;
    return Scaffold(
      appBar: AppBar(
        title: Text('$hashtag'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _getPosts(hashtag, context),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            List postIDs = snapshot.data;
            if (postIDs.length == 0)
              return Center(
                child: Text('No posts found!'),
              );
            return SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ...(postIDs).map((postID) {
                    return Card(child: Post(postID));
                  }),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
