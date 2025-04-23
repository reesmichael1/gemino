import 'package:flutter/material.dart';

import 'ipc.dart';
import 'renderer.dart';
import 'widgets/inputprompter.dart';

class ContentModel extends ChangeNotifier {
  Widget? _contents;
  String? _url;

  Widget get contents => _contents ?? SizedBox();
  String get url => _url ?? "";

  void updateContents(Widget contents) {
    _contents = contents;
    notifyListeners();
  }

  void updateUrl(String url) {
    _url = url;
    notifyListeners();
  }

  void handleServerResponse(BuildContext context, ServerResponse response) {
    switch (response) {
      case SuccessResponse():
        _contents = Renderer(
          theme: Theme.of(context),
        ).renderContents(context, response.lines);
      case InputResponse(prompt: final prompt):
        showInputPrompter(context, prompt, url);
      case ErrorResponse(msg: final msg):
        _contents = Text('error: $msg');
    }

    notifyListeners();
  }
}
