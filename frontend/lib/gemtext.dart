sealed class GemLine {
  const GemLine();

  factory GemLine.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('text')) {
      return TextLine.fromString(json['text']);
    } else if (json.containsKey('heading')) {
      return HeadingLine.fromJson(json['heading']);
    } else if (json.containsKey('link')) {
      return LinkLine.fromJson(json['link']);
    } else if (json.containsKey('list')) {
      return ListLine.fromJson(json);
    } else if (json.containsKey('quote')) {
      return QuoteLine.fromJson(json);
    } else if (json.containsKey('pre')) {
      return PreformatLine.fromJson(json['pre']);
    } else {
      throw Exception('Unknown line type: $json');
    }
  }
}

class TextLine implements GemLine {
  final String contents;

  const TextLine({required this.contents});

  factory TextLine.fromString(String contents) => TextLine(contents: contents);
}

class HeadingLine implements GemLine {
  final int level;
  final String text;

  const HeadingLine({required this.level, required this.text});

  factory HeadingLine.fromJson(Map<String, dynamic> json) =>
      HeadingLine(level: json['level'], text: json['text']);
}

class LinkLine implements GemLine {
  final String name;
  final String url;
  final String scheme;

  const LinkLine({required this.name, required this.url, required this.scheme});

  factory LinkLine.fromJson(Map<String, dynamic> json) =>
      LinkLine(name: json['name'], url: json['url'], scheme: json['scheme']);
}

class ListLine implements GemLine {
  final String contents;

  const ListLine({required this.contents});

  factory ListLine.fromJson(Map<String, dynamic> json) =>
      ListLine(contents: json['list']);
}

class QuoteLine implements GemLine {
  final String contents;

  const QuoteLine({required this.contents});

  factory QuoteLine.fromJson(Map<String, dynamic> json) =>
      QuoteLine(contents: json['quote']);
}

class PreformatLine implements GemLine {
  final List<String> lines;

  // We should also support the alt text here eventually
  const PreformatLine({required this.lines});

  factory PreformatLine.fromJson(Map<String, dynamic> json) =>
      PreformatLine(lines: json['lines'].cast<String>());
}
