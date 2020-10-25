import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/hashtag_list.dart';
import '../screens/nickname_list.dart';
import '../screens/auth_screen.dart';
import '../screens/add_post.dart';

class AppDrawer extends StatelessWidget {
  void _clearSharedPreferenceData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            title: const Text('Welcome to InstaPost'),
            automaticallyImplyLeading: false,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('Create new post'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(AddPost.routeName);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Text(
              '#',
              style: TextStyle(fontSize: 24),
            ),
            title: const Text('Hashtags'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(HashTagList.routeName);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.supervised_user_circle),
            title: const Text('Nicknames'),
            onTap: () {
              Navigator.of(context)
                  .pushReplacementNamed(NickNameList.routeName);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.power_settings_new),
            title: const Text('Logout'),
            onTap: () {
              _clearSharedPreferenceData();
              Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
            },
          ),
        ],
      ),
    );
  }
}
