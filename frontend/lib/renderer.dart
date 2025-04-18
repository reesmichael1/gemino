import 'package:flutter/material.dart';
import 'gemtext.dart';

List<Widget> renderContents(List<GemLine> lines) {
  return lines
      .map(
        (line) => switch (line) {
          TextLine(contents: final contents) => Text(contents),
          HeadingLine(text: final text) => Text(text),
          LinkLine(name: final name) => Text(name),
        },
      )
      .toList();
}
