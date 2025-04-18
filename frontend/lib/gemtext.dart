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

sealed class ServerResponse {
  const ServerResponse();

  factory ServerResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('content')) {
      return ContentResponse.fromJson(json);
    } else if (json.containsKey('error')) {
      return ErrorResponse.fromJson(json);
    } else {
      throw Exception('unrecognized server response: $json');
    }
  }
}

class ErrorResponse implements ServerResponse {
  final String msg;

  ErrorResponse({required this.msg});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      ErrorResponse(msg: json['error']);
}

class ContentResponse implements ServerResponse {
  final int status;
  final String mime;
  final List<GemLine> lines;

  ContentResponse({
    required this.status,
    required this.mime,
    required this.lines,
  });

  factory ContentResponse.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>;
    final lines =
        (content['lines'] as List)
            .map((item) => GemLine.fromJson(item))
            .toList();

    return ContentResponse(
      lines: lines,
      status: json['content']['status'],
      mime: json['content']['mime'],
    );
  }
}
