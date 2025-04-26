import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../contentmodel.dart';
import '../ipc.dart';

class UrlBar extends StatelessWidget {
  UrlBar({super.key});

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentModel>(
      builder: (context, model, child) {
        controller.text = model.url;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: model.canGoBack() ? model.historyBack : null,
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: model.canGoForwards() ? model.historyForward : null,
            ),
            SizedBox(width: 8),
            Flexible(
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'URL',
                ),
                controller: controller,
                onSubmitted: (url) {
                  model.updateUrl(url);
                  urlSubmit(
                    url,
                    (resp) => Provider.of<ContentModel>(
                      context,
                      listen: false,
                    ).handleServerResponse(context, resp, true),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
