import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:math' as math;
import '../constants.dart';
import 'main-screen.dart';

class ArticleView extends StatefulWidget {
  final url;
  final title;

  ArticleView(this.url, this.title);

  @override
  _ArticleViewState createState() => _ArticleViewState(this.url, this.title);
}

class _ArticleViewState extends State<ArticleView> {
  var _url;
  var _title;
  final String uid = HomeScreen.userKey;
  final _key = UniqueKey(); //creating a unique session for each url
  bool _isSaved = false;

  static String collectionDbName = 'saved_articles';

  CollectionReference dbInstance =
      FirebaseFirestore.instance.collection(collectionDbName);

  _ArticleViewState(this._url, this._title);

  final textController = TextEditingController();

  updateSavedState(isSaved) {
    setState(() {
      _isSaved = isSaved;
    });
  }

  void _showAction(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'How did you relate to this article?\nTell your future self!',
            style: TextStyle(
              fontFamily: kTitleFont,
              fontSize: 14.0,
            ),
          ),
          content: Padding(
            padding: EdgeInsets.all(10.0),
            child: TextField(controller: textController, maxLines: 3,),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                textController.clear();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black12),
              ),
            ),
            TextButton(
              onPressed: () =>
                  _saveArticle(uid, _url, _title, textController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  _saveArticle(uid, url, title, description) {
    updateSavedState(true);
    Navigator.of(context).pop();
    dbInstance.add({
      'user': uid,
      'title': title,
      'url': url,
      'description': description
    }).then((_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Successfully Saved')));
      textController.clear();
    }).catchError((onError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(onError)));
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[200],
      ),
      body: Column(
        children: [
          Expanded(
            child: WebView(
                key: _key,
                javascriptMode: JavascriptMode.unrestricted,
                initialUrl: _url),
          ),
        ],
      ),
      floatingActionButton: ActionButton(
        onPressed: () => _showAction(context),
        icon: _isSaved ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
      ),
    );
  }
}
