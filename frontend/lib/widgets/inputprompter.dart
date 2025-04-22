import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../contentmodel.dart';
import '../ipc.dart';

class InputPrompter extends StatelessWidget {
  const InputPrompter({super.key, required this.prompt, required this.url});
  final String prompt;
  final String url;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(prompt),
          TextField(
            onSubmitted: (contents) {
              sendInput(contents, url, (resp) {
                Provider.of<ContentModel>(
                  context,
                  listen: false,
                ).handleServerResponse(context, resp);
                Navigator.pop(context);
              });
            },
          ),
        ],
      ),
    );
  }
}

void showInputPrompter(BuildContext context, String prompt, String url) {
  showDialog(
    context: context,
    builder: (context) {
      return InputPrompter(prompt: prompt, url: url);
    },
  );
}
