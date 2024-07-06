import 'package:audio_app/loginScreen.dart';
import 'package:audio_app/signInScreen.dart';
import 'package:audio_app/splashScreen.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(), // Show SplashScreen initially
      routes: {
        '/login': (context) => LoginScreen(), // Route for LoginScreen
        '/signIn' : (context) => SignInScreen(),
      },
    );
  }
}


