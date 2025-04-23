import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../contentmodel.dart';
import '../gemtext.dart';
import '../ipc.dart';

sealed class _RenderBox {}

class _QuoteBox extends _RenderBox {
  _QuoteBox({required this.contents});

  final List<Widget> contents;
}

class _PreformatBox extends _RenderBox {
  _PreformatBox({required this.lines});

  final List<Widget> lines;
}

class _TextBox extends _RenderBox {
  _TextBox({required this.contents});

  final Widget contents;
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
      decorationColor: Colors.blue,
    );
  }

  TextStyle _externLinkStyle() {
    return _textStyle().copyWith(color: Colors.red);
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
      _PreformatBox(lines: final lines) => Container(
        padding: EdgeInsets.all(16),
        color: Colors.grey.withAlpha(25),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        ),
      ),
      _TextBox(contents: final contents) => contents,
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

  _RenderBox _renderBoxFromGemLine(BuildContext context, GemLine line) {
    return switch (line) {
      TextLine(contents: final contents) => _TextBox(
        contents: Text(contents, style: _textStyle()),
      ),
      HeadingLine(text: final text, level: final level) => _TextBox(
        contents: Text(text, style: _headingStyle(level)),
      ),
      LinkLine(name: final name, url: final path, scheme: final scheme) => () {
        if (scheme == "gemini") {
          return _TextBox(
            contents: Text.rich(
              TextSpan(
                text: name,
                style: _linkStyle(),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () {
                        linkClick(
                          Provider.of<ContentModel>(context, listen: false).url,
                          path,
                          (resp) => Provider.of<ContentModel>(
                            context,
                            listen: false,
                          ).handleServerResponse(context, resp),
                        );
                      },
              ),
            ),
          );
        } else {
          return _TextBox(
            contents: Text.rich(
              TextSpan(text: 'EXTERN LINK: $name', style: _externLinkStyle()),
            ),
          );
        }
      }(),
      ListLine(contents: final contents) => _TextBox(
        contents: Text('\u2022 $contents', style: _textStyle()),
      ),
      _ => throw Exception(''),
    };
  }

  List<_RenderBox> _convertToRenderBox(
    BuildContext context,
    List<GemLine> block,
  ) {
    return switch (block[0]) {
      TextLine() || HeadingLine() || LinkLine() || ListLine() =>
        block.map((l) => _renderBoxFromGemLine(context, l)).toList(),
      QuoteLine() => [
        _QuoteBox(contents: _extractText(block).map((l) => Text(l)).toList()),
      ],
      PreformatLine(lines: final lines) => [
        _PreformatBox(
          lines:
              lines
                  .map((l) => Text(l, style: GoogleFonts.spaceMono()))
                  .toList(),
        ),
      ],
    };
  }

  List<_RenderBox> _groupIntoBoxes(BuildContext context, List<GemLine> lines) {
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
        grouped.map((block) => _convertToRenderBox(context, block)).toList();

    return nested.expand((i) => i).toList();
  }

  Widget renderContents(BuildContext context, List<GemLine> lines) {
    final List<_RenderBox> grouped = _groupIntoBoxes(context, lines);
    return ListView(
      children: grouped.map((box) => _convertRenderBox(box)).toList(),
    );
  }
}
