import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

import '../providers/auth_provider.dart';
import '../screens/hashtag_list.dart';

enum Mode { Signup, Login }

class AuthCard extends StatefulWidget {
  const AuthCard({
    Key key,
  }) : super(key: key);

  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  Mode _mode = Mode.Login;
  bool _isLoading = false;
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _passwordController.dispose();
  }

  Map<String, String> _loginData = {
    'email': '',
    'password': '',
  };

  Map<String, String> _signupData = {
    'email': '',
    'password': '',
    'firstName': '',
    'lastName': '',
    'nickName': '',
  };

  void _submit() {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
    setState(() {
      _isLoading = true;
    });
    if (_mode == Mode.Login) {
      _authenticateUser();
    } else {
      _registerUser();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _switchMode() {
    if (_mode == Mode.Login) {
      setState(() {
        _mode = Mode.Signup;
      });
    } else {
      setState(() {
        _mode = Mode.Login;
      });
    }
  }

  void _registerUser() async {
    try {
      final response =
          await Provider.of<AuthProvider>(context, listen: false).registerUser(
        _signupData['email'],
        _signupData['password'],
        _signupData['firstName'],
        _signupData['lastName'],
        _signupData['nickName'],
      );
      if (response['result'] == "success") {
        _storeUserDetails(_signupData['email'], _signupData['password']);
        Navigator.of(context).pushReplacementNamed(HashTagList.routeName);
        return;
      } else {
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
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text(
              'Something went wrong. Please check you internet connection and try again later!'),
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

  void _authenticateUser() async {
    try {
      final response = await Provider.of<AuthProvider>(context, listen: false)
          .authenticateUser(
        _loginData['email'],
        _loginData['password'],
      );
      if (response['result']) {
        _storeUserDetails(
          _loginData['email'],
          _loginData['password'],
        );
        Navigator.of(context).pushReplacementNamed(HashTagList.routeName);
        return;
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: const Text('Your email or password is incorrect'),
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
          content: const Text(
              'Something went wrong. Please check you internet connection and try again later!'),
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

  void _storeUserDetails(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('Email', email);
    prefs.setString('Password', password);
  }

  Future _isAlreadyLoggedIn() async {
    bool isOnline = await DataConnectionChecker().hasConnection;
    if (!isOnline) {
      Navigator.of(context).pushReplacementNamed(HashTagList.routeName);
      return;
    }
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    String _email = _prefs.getString('Email') ?? "";
    String _password = _prefs.getString('Password') ?? "";
    try {
      final response = await Provider.of<AuthProvider>(context, listen: false)
          .authenticateUser(
        _email,
        _password,
      );
      if (response['result']) {
        Navigator.of(context).pushReplacementNamed(HashTagList.routeName);
        return;
      }
    } catch (error) {
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return FutureBuilder(
      future: _isAlreadyLoggedIn(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
            child: Container(
              height: _mode == Mode.Signup ? 300 : 250,
              constraints: BoxConstraints(
                minHeight: _mode == Mode.Signup ? 310 : 260,
              ),
              width: deviceSize.width * 0.75,
              padding: const EdgeInsets.all(15),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'E-Mail',
                          icon: Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: Icon(
                              Icons.email,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          value = value.trim();
                          if (value.isEmpty ||
                              !value.contains('@') ||
                              !value.contains('.')) {
                            return 'Invalid email!';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _mode == Mode.Login
                              ? _loginData['email'] = value
                              : _signupData['email'] = value;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          icon: Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Icon(
                              Icons.lock,
                            ),
                          ),
                        ),
                        obscureText: true,
                        controller: _passwordController,
                        validator: (value) {
                          value = value.trim();
                          if (value.isEmpty || value.length < 3) {
                            return 'Password is too short!';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _mode == Mode.Login
                              ? _loginData['password'] = value
                              : _signupData['password'] = value;
                        },
                      ),
                      if (_mode == Mode.Signup)
                        Column(
                          children: [
                            TextFormField(
                              enabled: _mode == Mode.Signup,
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                                icon: Padding(
                                  padding: EdgeInsets.only(top: 15.0),
                                  child: Icon(
                                    Icons.lock,
                                  ),
                                ),
                              ),
                              obscureText: true,
                              validator: _mode == Mode.Signup
                                  ? (value) {
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match!';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                                icon: Padding(
                                  padding: EdgeInsets.only(top: 15.0),
                                  child: Icon(
                                    Icons.person,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                value = value.trim();
                                if (value.isEmpty) {
                                  return 'Invalid First Name!';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _signupData['firstName'] = value;
                              },
                            ),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Last Name',
                                icon: Padding(
                                  padding: EdgeInsets.only(top: 15.0),
                                  child: Icon(
                                    Icons.person,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                value = value.trim();
                                if (value.isEmpty) {
                                  return 'Invalid Last Name!';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _signupData['lastName'] = value;
                              },
                            ),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Nick Name',
                                icon: Padding(
                                  padding: EdgeInsets.only(top: 15.0),
                                  child: Icon(
                                    Icons.person,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                value = value.trim();
                                if (value.isEmpty) {
                                  return 'Invalid Nick Name!';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _signupData['nickName'] = value;
                              },
                            ),
                          ],
                        ),
                      const SizedBox(
                        height: 20,
                      ),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        RaisedButton(
                          child:
                              Text(_mode == Mode.Login ? 'LOGIN' : 'SIGN UP'),
                          onPressed: _submit,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 8),
                          color: Theme.of(context).primaryColor,
                          textColor:
                              Theme.of(context).primaryTextTheme.button.color,
                        ),
                      FlatButton(
                        child: Text(
                            ' ${_mode == Mode.Login ? 'Not a user SIGNUP' : 'Already a user LOGIN'} INSTEAD'),
                        onPressed: _switchMode,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 4),
                        textColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const Center(
              child: CircularProgressIndicator(
            backgroundColor: Colors.white,
          ));
        }
      },
    );
  }
}
