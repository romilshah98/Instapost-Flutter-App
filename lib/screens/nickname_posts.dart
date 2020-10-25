import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

import '../widgets/post.dart';
import '../providers/posts_provider.dart';

class NickNamePosts extends StatelessWidget {
  static const routeName = '/nickNamePosts';

  Future<List> _getPosts(String nickName, BuildContext context) async {
    bool isOnline = await DataConnectionChecker().hasConnection;
    if (isOnline) {
      try {
        final response =
            await Provider.of<Posts>(context).getPostIDsByNickName(nickName);
        return response;
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
        return [];
      }
    } else {
      final response =
          await Provider.of<Posts>(context).getOfflinePostsByNickName(nickName);
      if (response == null || response.length == 0 || response[0]['ids']=='') {
        return [];
      }
      final ids =
          response[0]['ids'].split(',').map((id) => int.parse(id)).toList();
      return ids;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nickName = ModalRoute.of(context).settings.arguments as String;
    return Scaffold(
      appBar: AppBar(
        title: Text('$nickName'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _getPosts(nickName, context),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            List postIDs = snapshot.data;
            if (postIDs.length == 0) {
              return const Center(child: Text('No posts found!'));
            }
            return SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ...(postIDs).map((postID) {
                    return Post(postID);
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
