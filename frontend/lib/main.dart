import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'contentmodel.dart';
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
    final data = MediaQuery.of(context);
    return MaterialApp(
      home: MediaQuery(
        // This might not be necessary, but I have a HiDPI screen
        // and this makes life more pleasant during development
        data: data.copyWith(textScaler: TextScaler.linear(1.3)),
        child: MainScreen(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
    );
  }
}
