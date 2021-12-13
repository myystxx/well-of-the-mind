import 'package:flutter/material.dart';
import 'package:wotm_app/screens/articles-screen.dart';
import 'package:wotm_app/screens/journal-screen.dart';
import 'package:wotm_app/screens/main-screen.dart';
import 'package:wotm_app/screens/music-screen.dart';

class TabNavigatorRoutes {
  static const String root = '/';
  static const String detail = '/detail';
}

class TabNavigator extends StatelessWidget {
  TabNavigator({this.navigatorKey, this.tabItem});
  final GlobalKey<NavigatorState> navigatorKey;
  final String tabItem;

  @override
  Widget build(BuildContext context) {

    Widget child ;
    if(tabItem == "Home")
      child = HomeScreen();
    else if(tabItem == "Article")
      child = ArticlesScreen();
    else if(tabItem == "Meditate")
      child = MusicScreen();
    else if(tabItem == "Journal")
      child = JournalScreen();

    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
            builder: (context) => child
        );
      },
    );
  }
}