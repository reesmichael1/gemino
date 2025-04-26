import 'package:flutter/material.dart';

import 'ipc.dart';
import 'renderer.dart';
import 'widgets/inputprompter.dart';

class ContentModel extends ChangeNotifier {
  Widget? _contents;
  String? _url;
  List<String> _urlStack = [];
  int? _ix;
  bool needsLoad = false;

  Widget get contents => _contents ?? SizedBox();
  String get url => _url ?? "";

  void updateContents(Widget contents) {
    _contents = contents;
    notifyListeners();
  }

  void updateUrl(String url) {
    _url = url;
    if (_ix != null) {
      _urlStack = _urlStack.take(_ix! + 1).toList();
      if (_urlStack.last != url) {
        _urlStack.add(url);
        _ix = _ix! + 1;
      }
    } else {
      _urlStack.add(url);
      _ix = 0;
    }
    notifyListeners();
  }

  void historyForward() {
    _ix = _ix! + 1;
    _url = _urlStack[_ix!];
    needsLoad = true;
    notifyListeners();
  }

  void historyBack() {
    _ix = _ix! - 1;
    _url = _urlStack[_ix!];
    needsLoad = true;
    notifyListeners();
  }

  bool canGoBack() {
    return (_ix != null) && (_ix! > 0);
  }

  bool canGoForwards() {
    return (_ix != null) && (_ix! < _urlStack.length - 1);
  }

  void handleServerResponse(
    BuildContext context,
    ServerResponse response,
    bool newUrl,
  ) {
    switch (response) {
      case SuccessResponse(lines: final lines, url: final url):
        _contents = Renderer(
          theme: Theme.of(context),
        ).renderContents(context, lines);
        if (newUrl) {
          updateUrl(url);
        } else {
          _url = url;
        }
      case InputResponse(prompt: final prompt):
        showInputPrompter(context, prompt, url);
      case ErrorResponse(msg: final msg):
        _contents = Text('error: $msg');
    }

    notifyListeners();
  }
}
