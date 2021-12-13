import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wotm_app/constants.dart';
import 'package:wotm_app/screens/articles-screen.dart';
import 'package:wotm_app/screens/journal-screen.dart';
import 'package:wotm_app/screens/music-screen.dart';
import 'package:wotm_app/tabnavigator.dart';
import 'package:http/http.dart' as http;

const _titleText = 'Dashboard';
const _imageText = 'logo';

class DefaultScreen extends StatefulWidget {
  static const String id = 'main-screen';
  @override
  _DefaultScreenState createState() => _DefaultScreenState();
}

class _DefaultScreenState extends State<DefaultScreen> {
  static void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      print(e);
    }
  }

  /* check logged in user */
  final _auth = FirebaseAuth.instance;
  var loggedInUser;
  String userEmail;
  static var userName;
  static var userKey;

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      userKey = _auth.currentUser.uid;
      if (user != null) {
        loggedInUser = user;
        userEmail = loggedInUser.email.toString();
        userName = userEmail.split("@");
        userName = userName[0];
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();
    getCurrentUser();
  }

  int _currentIndex = 0;

  String _currentPage = "Home";
  List<String> pageKeys = ["Home", "Article", "Meditate", "Journal"];
  Map<String, GlobalKey<NavigatorState>> _navigatorKeys = {
    "Home": GlobalKey<NavigatorState>(),
    "Article": GlobalKey<NavigatorState>(),
    "Meditate": GlobalKey<NavigatorState>(),
    "Journal": GlobalKey<NavigatorState>(),
  };

  void _selectTab(String tabItem, int index) {
    if (tabItem == _currentPage) {
      _navigatorKeys[tabItem].currentState.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentPage = pageKeys[index];
        _currentIndex = index;
      });
    }
  }
  // void onTabTapped(int index) {
  //   setState(() {
  //     _currentIndex = index;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteCurrentTab =
            !await _navigatorKeys[_currentPage].currentState.maybePop();
        if (isFirstRouteCurrentTab) {
          if (_currentPage != "Home") {
            _selectTab("Home", 1);

            return false;
          }
        }
        return isFirstRouteCurrentTab;
      },
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              _buildOffstageNavigator("Home"),
              _buildOffstageNavigator("Article"),
              _buildOffstageNavigator("Meditate"),
              _buildOffstageNavigator("Journal"),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: Colors.brown[200],
            unselectedItemColor: Colors.black.withOpacity(.60),
            selectedFontSize: 12,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            onTap: (int index) {
              _selectTab(pageKeys[index], index);
            },
            currentIndex: _currentIndex,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article_rounded),
                label: 'Read',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: 'Meditate',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.border_color),
                label: 'Journal',
              ),
            ],
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(String tabItem) {
    return Offstage(
        offstage: _currentPage != tabItem,
        child: TabNavigator(
          navigatorKey: _navigatorKeys[tabItem],
          tabItem: tabItem,
        ));
  }
}

class HomeScreen extends StatefulWidget {
  static String name = _DefaultScreenState.userName.toString();
  static String userKey = _DefaultScreenState.userKey.toString();

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static String name = _DefaultScreenState.userName.toString();
  static const QUOTES_API = "https://type.fit/api/quotes";
  int randCount = 1;
  int randIndex = Random().nextInt(50);
  dynamic _data;
  int journalTot;
  int articleTot;

  CollectionReference journals =
      FirebaseFirestore.instance.collection("journals");

  CollectionReference articles =
      FirebaseFirestore.instance.collection("saved_articles");

  @override
  void initState() {
    loadQuotes();
    fetchArticles();
    fetchJournals();
  }

  isQuoteEmpty() {
    return _data == null;
  }

  isArticleEmpty() {
    return articleTot == null;
  }

  isJournalEmpty() {
    return journalTot == null;
  }

  updateQuotes(quotes) {
    setState(() {
      _data = quotes;
    });
  }

  updateArticle(number) {
    setState(() {
      articleTot = number;
    });
  }

  updateJournal(number) {
    setState(() {
      journalTot = number;
    });
  }

  loadQuotes() async {
    var result = await fetchQuotes();
    updateQuotes(result);
  }

  fetchQuotes() async {
    try {
      int startTime = new DateTime.now().millisecond;
      final client = http.Client();
      final response = await client.get(Uri.parse(QUOTES_API));
      int endTime = new DateTime.now().millisecond - startTime;
      print("quotes: $endTime");
      return jsonDecode(response.body);
    } catch (e) {
      print("fail to load API");
    }
  }

  fetchArticles() {
    try {
      int startTime = new DateTime.now().millisecond;
      articles
          .where('user', isEqualTo: HomeScreen.userKey)
          .get()
          .then((querySnapshot) {
        articleTot = querySnapshot.docs.length;
        int endTime = new DateTime.now().millisecond - startTime;
        print("save article in main: $endTime");
        updateArticle(articleTot);
      });
    } catch (e) {
      print('Something went wrong $e');
    }
  }

  fetchJournals() {
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
              .get()
              .then((querySnapshot) {
            journalTot = querySnapshot.docs.length;
            int endTime = new DateTime.now().millisecond - startTime;
            print("journal in main: $endTime");
            updateJournal(journalTot);
          });
        }
      });
    } catch (e) {
      print('Something went wrong $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kBackgroundDecoration(randCount),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          kTitleContainer(_titleText, _imageText),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
              child: ListView(
                children: <Widget>[
                  Text(
                    'Hey $name!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kTitleFont,
                    ),
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        isQuoteEmpty()
                            ? "loading"
                            : '"${_data[randIndex]['text']}"'
                        //'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s,' //TODO: get random quote
                        ,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Text(
                          isQuoteEmpty()
                              ? ""
                              : '"${_data[randIndex]['author']}"',
                          // "author",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontFamily: kBodyFont,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 300.0,),
                          IconButton(onPressed: () {
                            fetchArticles();
                            fetchJournals();
                            setState(() {
                              randIndex = Random().nextInt(50);
                              randCount = Random().nextInt(7);
                            });
                          }, icon: Icon(Icons.refresh),)
                        ],
                      ),
                      SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ArticlesScreen()));
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: Container(
                                color: Colors.white70,
                                padding: EdgeInsets.all(10.0),
                                height: 100.0,
                                width: 125.0,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text("You have save"),
                                      Text(
                                          isArticleEmpty()
                                              ? "?"
                                              : articleTot.toString(),
                                          style: TextStyle(
                                              color: Colors.pink[200],
                                              fontSize: 20.0,
                                              fontFamily: kTitleFont)),
                                      Text("articles"),
                                    ]),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => JournalScreen()));
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: Container(
                                color: Colors.white70,
                                padding: EdgeInsets.all(10.0),
                                height: 100.0,
                                width: 125.0,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text("You have wrote"),
                                      Text(
                                          isJournalEmpty()
                                              ? "?"
                                              : journalTot.toString(),
                                          style: TextStyle(
                                              color: Colors.pink[200],
                                              fontSize: 20.0,
                                              fontFamily: kTitleFont)),
                                      Text("journals"),
                                    ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.0),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Container(
                          color: Colors.white70,
                          padding: EdgeInsets.all(10.0),
                          height: 100.0,
                          width: 250.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "Your monthly\n mood",
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                              SizedBox(width: 50.0),
                              Text("😀",
                                  style: TextStyle(
                                      color: Colors.pink[200],
                                      fontSize: 25.0,
                                      fontFamily: kTitleFont)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
