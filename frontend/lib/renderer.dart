import 'package:flutter/material.dart';
import 'gemtext.dart';

class Renderer {
  Renderer({required this.theme});

  final ThemeData theme;

  TextStyle h1Style() {
    return theme.textTheme.headlineLarge!;
  }

  TextStyle h2Style() {
    return theme.textTheme.headlineMedium!;
  }

  TextStyle h3Style() {
    return theme.textTheme.headlineSmall!;
  }

  TextStyle headingStyle(int level) {
    if (level == 1) {
      return h1Style();
    } else if (level == 2) {
      return h2Style();
    } else if (level == 3) {
      return h3Style();
    } else {
      throw Exception('unrecognized heading level: $level');
    }
  }

  TextStyle textStyle() {
    return theme.textTheme.bodyLarge!;
  }

  TextStyle linkStyle() {
    return textStyle().copyWith(
      color: Color.from(alpha: 1.0, blue: 1.0, red: 0.0, green: 0.0),
      decoration: TextDecoration.underline,
    );
  }

  List<Widget> renderContents(List<GemLine> lines) {
    return lines
        .map(
          (line) => switch (line) {
            TextLine(contents: final contents) => Text(
              contents,
              style: textStyle(),
            ),
            HeadingLine(level: final level, text: final text) => Text(
              text,
              style: headingStyle(level),
            ),
            LinkLine(name: final name) => Text(name, style: linkStyle()),
          },
        )
        .toList();
  }
}
