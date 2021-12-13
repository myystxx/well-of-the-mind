import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:wotm_app/screens/login-screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key key}) : super(key: key);

  static const String id = 'splash-screen';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splashTransition: SplashTransition.fadeTransition,
      centered: true,
      splash: splashWidget(),
      duration: 3000,
      backgroundColor: Colors.brown[200],
      nextScreen: LoginScreen(),
    );
  }
}

Widget splashWidget() {
  return CircleAvatar(
    radius: 60.0,
    backgroundImage: AssetImage('images/icons/logo.png'),
  );
}
