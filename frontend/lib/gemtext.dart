sealed class GemLine {
  const GemLine();

  factory GemLine.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('text')) {
      return TextLine.fromString(json['text']);
    } else if (json.containsKey('heading')) {
      return HeadingLine.fromJson(json['heading']);
    } else if (json.containsKey('link')) {
      return LinkLine.fromJson(json['link']);
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

  const LinkLine({required this.name, required this.url});

  factory LinkLine.fromJson(Map<String, dynamic> json) =>
      LinkLine(name: json['name'], url: json['url']);
}
