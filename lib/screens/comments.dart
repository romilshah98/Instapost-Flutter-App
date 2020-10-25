import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/post_provider.dart';

class Comments extends StatefulWidget {
  final int postID;
  final List comments;
  final bool isOnline;

  Comments({this.postID, this.comments, this.isOnline});

  @override
  _CommentsState createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment(int postID) async {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
    FocusScope.of(context).unfocus();
    try {
      final response = await Provider.of<PostProvider>(context).addComment(
        postID,
        _commentController.text,
      );
      final jsonResponse = convert.jsonDecode(response.body);
      if (jsonResponse['result'] != 'success') {
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
      } else {
        setState(() {
          widget.comments.add(_commentController.text);
        });
      }
      _commentController.clear();
    } catch (error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text(
              'Something went wrong. Please check you internet connection or login and try again later!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          widget.comments.length == 0
              ? Center(child: const Text('No comments yet! Add a one!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: widget.comments.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: [
                        Card(
                          elevation: 5,
                          child: ListTile(
                            title: Text(
                                '${widget.isOnline ? widget.comments[index] : widget.comments[index]['comment']}'),
                          ),
                        ),
                        if (index == widget.comments.length - 1)
                          const SizedBox(
                            height: 55,
                          ),
                      ],
                    );
                  },
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              height: 55,
              width: 50,
              child: Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add Comment',
                        ),
                        validator: (value) {
                          value = value.trim();
                          if (value.isEmpty) {
                            return 'Invalid Comment!';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        _addComment(widget.postID);
                      },
                    ),
                  ],
                ),
              ),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
