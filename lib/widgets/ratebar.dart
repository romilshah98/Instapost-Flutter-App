import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../providers/post_provider.dart';

class RateBar extends StatefulWidget {
  final int postID;
  final double ratings;
  final int ratingsCount;
  RateBar(this.postID, this.ratings, this.ratingsCount);

  @override
  _RateBarState createState() => _RateBarState();
}

class _RateBarState extends State<RateBar> {
  double ratings = 0;
  int ratingsCount = 0;

  @override
  initState() {
    ratings = widget.ratings;
    ratingsCount = widget.ratingsCount;
    super.initState();
  }

  void _ratePost(int postID, int rating, BuildContext context) async {
    try {
      final response =
          await Provider.of<PostProvider>(context).ratePost(postID, rating);
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
        Scaffold.of(context).hideCurrentSnackBar();
        final snackBar = SnackBar(
          content: Text('Ratings Added!'),
        );
        Scaffold.of(context).showSnackBar(snackBar);
        double newRatings =
            (ratings * ratingsCount + rating) / (ratingsCount + 1);
        int newRatingsCount = ratingsCount + 1;
        setState(() {
          ratings = newRatings;
          ratingsCount = newRatingsCount;
        });
      }
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
    return Row(
      children: [
        RatingBar(
          initialRating: 0,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 20,
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {
            int ratings = rating.toInt();
            _ratePost(
              widget.postID,
              ratings,
              context,
            );
          },
        ),
        Text(
          ' Avg. ${double.parse(ratings.toStringAsFixed(2))}/5',
        ),
      ],
    );
  }
}
