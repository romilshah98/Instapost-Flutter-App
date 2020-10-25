import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Picker extends StatefulWidget {
  final void Function(File pickedImage) pickImage;
  Picker(this.pickImage);
  @override
  _PickerState createState() => _PickerState();
}

class _PickerState extends State<Picker> {
  File _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      widget.pickImage(_image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 40,
          backgroundImage: _image != null ? FileImage(_image) : null,
        ),
        FlatButton.icon(
          onPressed: getImage,
          icon: Icon(Icons.image),
          label: Text('Add Image'),
        ),
      ],
    );
  }
}
