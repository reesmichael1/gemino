import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'dart:convert';
import 'dart:io';

import 'contentmodel.dart';
// import 'ipc.dart';
// import 'renderer.dart';
import 'widgets/mainscreen.dart';

void startServer() async {
  // Obviously we need to fix everything about this
  await Process.start("../_build/default/bin/main.exe", []);
}

void main() async {
  startServer();
  runApp(ChangeNotifierProvider(create: (_) => ContentModel(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
    );
  }
}
