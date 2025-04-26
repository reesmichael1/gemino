import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../contentmodel.dart';
import '../ipc.dart';
import 'urlbar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            UrlBar(),
            SizedBox(height: 16),
            Expanded(
              child: Consumer<ContentModel>(
                builder: (context, model, child) {
                  if (model.needsLoad) {
                    model.needsLoad = false;
                    urlSubmit(
                      model.url,
                      (resp) => Provider.of<ContentModel>(
                        context,
                        listen: false,
                      ).handleServerResponse(context, resp, false),
                    );
                  }
                  return SelectionArea(child: model.contents);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
