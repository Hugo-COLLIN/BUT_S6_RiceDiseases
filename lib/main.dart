import 'package:flutter/material.dart';
import 'package:paddy_disease_classifier/data.dart';
import 'package:paddy_disease_classifier/pages/my_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: appName),
      debugShowCheckedModeBanner: false,
    );
  }
}
