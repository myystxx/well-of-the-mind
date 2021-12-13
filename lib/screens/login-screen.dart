import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wotm_app/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main-screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key key}) : super(key: key);

  static const String id = 'login-screen';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  String userEmail;
  String userPassword;
  bool _isNewUser = false; //set default screen as login

  checkNewUser(isNewUser) {
    setState(() {
      _isNewUser = isNewUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 50.0, vertical: 35.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: CircleAvatar(
                      backgroundImage: AssetImage('images/icons/logo.png'),
                      radius: 30.0,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      _isNewUser ? "Let's Register!" : "Let's Log In!",
                      style: TextStyle(
                        fontFamily: kTitleFont,
                        fontSize: 30.0,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text("Email", style: TextStyle(
                            fontWeight: FontWeight.w500
                          ),),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                  hintText: "Email",
                                  hoverColor: Colors.pink,
                                  hintStyle: TextStyle(
                                    fontSize: 12.0,
                                  )),
                              keyboardType: TextInputType.emailAddress,
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                userEmail = value;
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Text("Password", style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                  hintText: "Password (min. 6 characters)",
                                  hintStyle: TextStyle(
                                    fontSize: 12.0,
                                  )),
                              obscureText: true,
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                userPassword = value;
                              },
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async => _isNewUser
                            ? await registerUser()
                            : await loginUser(),
                        child: _isNewUser ? Text('Register') : Text('Login'),
                      ),
                      TextButton(
                        onPressed: () {
                          _isNewUser ? checkNewUser(false) : checkNewUser(true);
                        },
                        child: Text(
                          _isNewUser
                              ? 'Already have an account? Login here!'
                              : 'Don\'t have an account? Register here!',
                          style: TextStyle(
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> loginUser() async {
    checkNewUser(false);
    try {
      final user = await _auth.signInWithEmailAndPassword(
          email: userEmail, password: userPassword);
      if (user != null) {
        Navigator.pushNamed(context, DefaultScreen.id);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> registerUser() async {
    try {
      final newUser = await _auth.createUserWithEmailAndPassword(
          email: userEmail, password: userPassword);
      if (newUser != null) {
        Navigator.pushNamed(context, DefaultScreen.id);
      }
    } catch (e) {
      print(e);
    }
  }
}
