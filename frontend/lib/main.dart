import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

void startServer() async {
  // Obviously we need to fix everything about this
  await Process.start("../_build/default/bin/main.exe", []);
}

void main() async {
  startServer();
  runApp(const MyApp());
}

class LoadUrlMsg {
  final String url;

  LoadUrlMsg(this.url);

  LoadUrlMsg.fromJson(Map<String, dynamic> json)
    : url = json['loadUrl']['url'] as String;

  Map<String, dynamic> toJson() => {
    'loadUrl': {'url': url},
  };
}

class AppExitMsg {
  AppExitMsg();

  String toJson() => 'appExit';
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var boxContents = "";
  String? message;

  final _address = InternetAddress(
    '/run/user/1000/gemmo.sock',
    type: InternetAddressType.unix,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('gemmo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message ?? ""),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 800,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Gemini URI',
                      ),
                      onChanged: (contents) {
                        setState(() {
                          boxContents = contents;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: Text('send message'),
                    onPressed: () async {
                      final socket = await Socket.connect(_address, 0);
                      socket.listen((data) {
                        setState(() {
                          message = String.fromCharCodes(data).trim();
                        });
                      });

                      var msg = LoadUrlMsg(boxContents.trim());
                      String json = jsonEncode(msg);
                      socket.writeln(json);
                    },
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    child: Text('close application'),
                    onPressed: () async {
                      final socket = await Socket.connect(_address, 0);
                      socket.writeln(jsonEncode(AppExitMsg()));
                      exit(0);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
    );
  }
}
