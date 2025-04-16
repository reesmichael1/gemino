import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class Message {
  final String kind;
  final List<String> args;

  Message(this.kind, this.args);

  Message.fromJson(Map<String, dynamic> json)
    : kind = json['kind'] as String,
      args = json['args'];

  Map<String, dynamic> toJson() => {'kind': kind, 'args': args};
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
                        hintText: 'Send message to the server',
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

                      var msg = Message('duplicate', [boxContents.trim()]);
                      String json = jsonEncode(msg);
                      socket.writeln(json);
                    },
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    child: Text('close application'),
                    onPressed: () async {
                      final socket = await Socket.connect(_address, 0);
                      var msg = Message('close', []);
                      String json = jsonEncode(msg);
                      socket.writeln(json);
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
