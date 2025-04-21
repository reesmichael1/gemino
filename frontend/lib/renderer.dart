import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../gemtext.dart';

sealed class _RenderBox {}

class _QuoteBox extends _RenderBox {
  _QuoteBox({required this.contents});

  final List<Widget> contents;
}

class _TextBox extends _RenderBox {
  _TextBox({required this.contents});

  final Widget contents;
}

class _LinkBox extends _RenderBox {
  _LinkBox({required this.name, required this.url});

  final String name;
  final String url;
}

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

  Widget _convertRenderBox(_RenderBox box) {
    return switch (box) {
      _QuoteBox(contents: final contents) => Container(
        padding: EdgeInsets.all(16),
        color: Colors.grey.withAlpha(50),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contents,
        ),
      ),
      _TextBox(contents: final contents) => contents,
      _LinkBox(name: final name, url: final url) => Text.rich(
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
    };
  }

  List<String> _extractText(List<GemLine> block) {
    return block
        .map(
          (line) => switch (line) {
            TextLine(contents: final contents) => contents,
            QuoteLine(contents: final contents) => contents,
            _ => throw Exception('non-text line encountered inside block'),
          },
        )
        .toList();
  }

  _RenderBox _renderBoxFromGemLine(GemLine line) {
    return switch (line) {
      TextLine(contents: final contents) => _TextBox(
        contents: Text(contents, style: _textStyle()),
      ),
      HeadingLine(text: final text, level: final level) => _TextBox(
        contents: Text(text, style: _headingStyle(level)),
      ),
      LinkLine(name: final name, url: final url) => _TextBox(
        contents: Text.rich(
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
      ),
      ListLine(contents: final contents) => _TextBox(
        contents: Text('\u2022 $contents', style: _textStyle()),
      ),
      _ => throw Exception(''),
    };
  }

  List<_RenderBox> _convertToRenderBox(List<GemLine> block) {
    return switch (block[0]) {
      TextLine() ||
      HeadingLine() ||
      LinkLine() ||
      ListLine() => block.map(_renderBoxFromGemLine).toList(),
      QuoteLine() => [
        _QuoteBox(contents: _extractText(block).map((l) => Text(l)).toList()),
      ],
    };
  }

  List<_RenderBox> _groupIntoBoxes(List<GemLine> lines) {
    // Group lines by "similar types" so that we can group like lines
    // (i.e., quoted or preformatted lines) together in the styling
    if (lines.isEmpty) {
      return [];
    }

    List<List<GemLine>> grouped = [];
    List<GemLine> currentGroup = [];

    GemLine previous = lines[0];
    currentGroup.add(previous);

    for (int i = 1; i < lines.length; i++) {
      GemLine current = lines[i];
      if (current.runtimeType == previous.runtimeType) {
        currentGroup.add(current);
      } else {
        grouped.add(currentGroup);
        currentGroup = [current];
      }

      previous = current;
    }

    if (currentGroup.isNotEmpty) {
      grouped.add(currentGroup);
    }

    final List<List<_RenderBox>> nested =
        grouped.map((block) => _convertToRenderBox(block)).toList();

    return nested.expand((i) => i).toList();
  }

  Widget renderContents(List<GemLine> lines) {
    final List<_RenderBox> grouped = _groupIntoBoxes(lines);
    return ListView(
      children: grouped.map((box) => _convertRenderBox(box)).toList(),
    );
  }
}
