import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:wotm_app/emotion-utils.dart';
import 'package:wotm_app/screens/main-screen.dart';
import '../constants.dart';

const _titleText = 'Journal';
const _imageText = 'journal';

class JournalScreen extends StatefulWidget {
  const JournalScreen({Key key}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static String collectionDbName = 'journals';

  CollectionReference journals =
      FirebaseFirestore.instance.collection(collectionDbName);

  TextEditingController _textController;

  List _emotions = ['😀', '😞', '😩', '😥'];
  List _labels = ['Happy', 'Sad', 'Tired', 'Worried'];
  List _prompts = [
    "Write down one thing you are grateful for today.",
    "What makes you feel the happiest?",
    "Tell yourself one thing you are proud of.",
    "How was your day?",
    "A goal you want to accomplish today.",
    "What is a dream you want to accomplish?",
    "If you can have a superpower, what would it be?",
    "What would you wish to tell your future self?",
  ];

  var _userJournals;
  var _userSavedJournal;
  String _message = "Journal";
  bool _show = false;
  // bool _isToday = true;
  bool _completed = false; //to check if user has completed today's journal
  int _index = 0;
  Random random;
  String _details;
  var inputDate = DateTime.now();
  String _selectedEmoji;
  String _todayPrompt;

  static const loadingJournalMsg = "Generating Journal...";

  // get button colour
  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      // MaterialState.hovered,
      // MaterialState.focused,
      // MaterialState.selected,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.brown[200];
    }
    return Colors.white;
  }

  title(title) {
    return Text(
      title,
      textAlign: TextAlign.start,
      style: TextStyle(
          fontSize: 12.0, fontWeight: FontWeight.w700, fontFamily: kBodyFont),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  subtitle(subTitle) {
    return Text(
      subTitle,
      textAlign: TextAlign.start,
      style:
          TextStyle(color: Colors.black, fontSize: 12.0, fontFamily: kBodyFont),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    updatePrompt();
    updateJournalMsg(loadingJournalMsg);
    retrieveEntry();
  }

  // allowUpdate(isToday) {
  //   setState(() {
  //     _isToday = isToday;
  //   });
  // }

  updatePrompt() {
    random = new Random();
    _index = random.nextInt(7);
    setState(() {
      _todayPrompt = _prompts[_index];
    });
  }

  updateJournalMsg(message) {
    setState(() {
      _message = message;
    });
  }

  update(show) {
    setState(() {
      _show = show;
    });
  }

  updateJournalState(completed) {
    setState(() {
      _completed = completed;
    });
  }

  isJournalEmpty() {
    return _userSavedJournal == null;
  }

  @override
  void dispose() {
    _textController.clear();
    _textController.dispose();
    super.dispose();
  }

  //store
  storeEntry(collection) {
    updateJournalState(true);
    collection.add({
      'emotion': _selectedEmoji,
      'details': _details,
      'prompt': _todayPrompt,
      'month': inputDate.month,
      'timestamp': inputDate,
    }).then((_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Successfully Saved')));
      _textController.clear();
      retrieveEntry();
    }).catchError((onError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(onError)));
    });
  }

  checkFirstEntry() {
    if (HomeScreen.userKey != null) {
      try {
        journals
            .where('userid', isEqualTo: HomeScreen.userKey)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            _userJournals =
                journals.doc(querySnapshot.docs.first.id).collection('list');
            storeEntry(_userJournals);
          } else {
            print('This is your first entry!\nAwesome');
            journals.add({'userid': HomeScreen.userKey});
            checkFirstEntry();
          }
        });
      } catch (e) {
        print('Something went wrong $e');
        print("fail");
      }
    } else {
      print('User does not exist');
    }
  }

  //retrieve entry
  retrieveEntry() {
    try {
      int startTime = new DateTime.now().millisecond;
      journals
          .where('userid', isEqualTo: HomeScreen.userKey)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isEmpty) {
          displayDialog(context, 'No journals found!');
        } else {
          journals
              .doc(querySnapshot.docs.first.id)
              .collection('list')
              .orderBy('timestamp', descending: true)
              .get()
              .then((querySnapshot) {
            _userSavedJournal = querySnapshot.docs;
            int endTime = new DateTime.now().millisecond - startTime;
            print("journal: $endTime");
            update(true);
          });
        }
      });
    } catch (e) {
      print('Something went wrong $e');
    }
  }

  // loadJournal(journal) async {
  //   Navigator.push(context,
  //       MaterialPageRoute(builder: (context) => PastJournals(journal)));
  // }

  viewJournals() {
    return StaggeredGridView.countBuilder(
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        itemCount: _userSavedJournal.length,
        itemBuilder: (BuildContext context, index) {
          var doc = _userSavedJournal[index];
          DateTime dt = (doc['timestamp'] as Timestamp).toDate();
          String dtString = dt.toString();
          return ClipRRect(
            borderRadius: BorderRadius.circular(30.0),
            child: Container(
              color: Colors.white70,
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              padding: EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 30.0,
                        width: 30.0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.0, vertical: 3.0),
                          child: doc['emotion'] != null
                              ? Text(
                                  getEmoticon(doc['emotion']),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20.0,
                                  ),
                                )
                              : Icon(Icons.face),
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Text(dtString.split(' ').first),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        title(doc['prompt']),
                        doc['details'] != null
                            ? Expanded(child: subtitle(doc['details']))
                            : Expanded(child: subtitle("You wrote nothing")),
                        // Expanded(
                        //   child: viewUpdateButton(dt),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        staggeredTileBuilder: (index) {
          return StaggeredTile.count(1, index.isEven ? 1.0 : 0.8);
        });
  }

  //build the emoticon
  Widget emotionChoices(List _emotions, List _labels) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _emotions.length,
      itemBuilder: (BuildContext context, int index) {
        return TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith(getColor),
          ),
          onPressed: () {
            _selectedEmoji = getEmoticon(_emotions[index]);
          },
          child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Text(
                    _emotions[index],
                    style: TextStyle(
                      fontFamily: kBodyFont,
                      fontWeight: FontWeight.w400,
                      fontSize: 40.0,
                    ),
                  ),
                  Text(
                    _labels[index],
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: kBodyFont,
                      fontWeight: FontWeight.w400,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              )),
        );
      },
    );
  }

  ListView journalForm() {
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.all(10.0),
      children: <Widget>[
        Text(
          ' How are you Feeling?',
          style: TextStyle(
            fontFamily: kTitleFont,
            fontSize: 20,
          ),
        ),
        Container(
          height: 120.0,
          width: 400.0,
          child: emotionChoices(_emotions, _labels),
        ),
        Card(
          color: Colors.pink[200],
          margin: EdgeInsets.all(50.0),
          elevation: 5.0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _prompts[_index],
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                    iconSize: 30.0,
                    tooltip: "Change prompt",
                    color: Colors.white70,
                    icon: Icon(Icons.shuffle_rounded),
                    onPressed: () => updatePrompt()),
              ],
            ),
          ),
        ),
        TextField(
          maxLines: 5,
          controller: _textController,
          decoration: InputDecoration(
            fillColor: Colors.pinkAccent,
            hintText: "Write here...",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _details = value;
          },
        ),
        SizedBox(height: 20.0),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 100.0),
          height: 40.0,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith(getColor),
            ),
            onPressed: () => checkFirstEntry(),
            child: Text(
              "Submit",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  completeJournal() {
    return Column(
      // shrinkWrap: true,
      // padding: EdgeInsets.all(8.0),
      children: [
        Card(
          color: Colors.pink[200],
          margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          elevation: 5.0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'You have completed today\'s journal!',
              softWrap: true,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            updateJournalState(false);
            updatePrompt();
          },
          child: Text("Write another entry"),
        ),
        Expanded(
          child: body(),
        ),
      ],
    );
  }

  body() {
    return !_show
        ? Column(
            children: <Widget>[
              Text(_message),
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              )
            ],
          )
        : viewJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kBackgroundDecoration(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 30.0),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20.0,
                  backgroundImage: AssetImage('images/icons/$_imageText.png'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    _titleText,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontFamily: kTitleFont,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80.0,
                ),
                ActionButton(
                  onPressed: () => _completed
                      ? updateJournalState(false)
                      : updateJournalState(true),
                  icon: _completed
                      ? Icon(
                          Icons.edit,
                          color: Colors.white,
                        )
                      : Icon(
                          Icons.book,
                          color: Colors.white,
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _completed ? completeJournal() : journalForm(),
          ),
        ],
      ),
    );
  }
}
