import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './screens/hashtag_list.dart';
import './screens/nickname_list.dart';
import './screens/auth_screen.dart';
import './screens/hashtag_posts.dart';
import './screens/nickname_posts.dart';
import './screens/add_post.dart';
import './providers/posts_provider.dart';
import './providers/list_provider.dart';
import './providers/auth_provider.dart';
import './providers/post_provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = new MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => Posts(),
        ),
        ChangeNotifierProvider(
          create: (_) => ListProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PostProvider>(
          create: (_) => PostProvider('', ''),
          update: (ctx, authProvider, prevState) =>
              PostProvider(authProvider.email, authProvider.password),
        ),
      ],
      child: MaterialApp(
        title: 'Insta Post',
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
        home: AuthScreen(),
        routes: {
          HashTagList.routeName: (ctx) => HashTagList(),
          NickNameList.routeName: (ctx) => NickNameList(),
          NickNamePosts.routeName: (ctx) => NickNamePosts(),
          HashTagPosts.routeName: (ctx) => HashTagPosts(),
          AddPost.routeName: (ctx) => AddPost(),
        },
      ),
    );
  }
}
