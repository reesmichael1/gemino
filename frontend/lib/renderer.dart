import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../gemtext.dart';

class Renderer {
  Renderer({required this.theme});

  final ThemeData theme;

  TextStyle _h1Style() {
    return theme.textTheme.headlineLarge!;
  }

  TextStyle _h2Style() {
    return theme.textTheme.headlineMedium!;
  }

  TextStyle _h3Style() {
    return theme.textTheme.headlineSmall!;
  }

  TextStyle _headingStyle(int level) {
    if (level == 1) {
      return _h1Style();
    } else if (level == 2) {
      return _h2Style();
    } else if (level == 3) {
      return _h3Style();
    } else {
      throw Exception('unrecognized heading level: $level');
    }
  }

  TextStyle _textStyle() {
    return theme.textTheme.bodyLarge!;
  }

  TextStyle _linkStyle() {
    return _textStyle().copyWith(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    );
  }

  Widget renderContents(List<GemLine> lines) {
    return ListView(
      children:
          lines
              .map(
                (line) => switch (line) {
                  TextLine(contents: final contents) => Text(
                    contents,
                    style: _textStyle(),
                  ),
                  HeadingLine(level: final level, text: final text) => Text(
                    text,
                    style: _headingStyle(level),
                  ),
                  LinkLine(name: final name, url: final url) => Text.rich(
                    TextSpan(
                      text: name,
                      style: _linkStyle(),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              debugPrint('clicked $url');
                            },
                    ),
                  ),
                },
              )
              .toList(),
    );
  }
}
