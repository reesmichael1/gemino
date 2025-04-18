import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'gemtext.dart';
import 'renderer.dart';

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

class RenderArea extends StatelessWidget {
  const RenderArea({super.key, required this.contents});

  final List<Widget> contents;

  @override
  Widget build(BuildContext context) {
    return Flexible(child: ListView(children: contents));
  }
}

class UrlBar extends StatelessWidget {
  const UrlBar({super.key, required this.urlSubmit});

  final void Function(String)? urlSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter Gemini URI',
            ),
            onSubmitted: (url) => urlSubmit!(url),
          ),
        ),
      ],
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Widget> contents = [];

  final _address = InternetAddress(
    '/run/user/1000/gemmo.sock',
    type: InternetAddressType.unix,
  );

  @override
  void initState() {
    super.initState();
  }

  urlSubmit(String url) async {
    final socket = await Socket.connect(_address, 0);
    socket.listen((data) {
      final json = String.fromCharCodes(data).trim();
      final response = ServerResponse.fromJson(jsonDecode(json));

      setState(() {
        contents = switch (response) {
          ContentResponse() => renderContents(response.lines),
          ErrorResponse(msg: final msg) => [Text('error: $msg')],
        };
      });
    });

    final msg = LoadUrlMsg(url);
    String json = jsonEncode(msg);
    socket.writeln(json);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('gemmo')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              UrlBar(urlSubmit: urlSubmit),
              SizedBox(height: 10),
              RenderArea(contents: contents),
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
