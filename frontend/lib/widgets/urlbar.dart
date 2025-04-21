import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../contentmodel.dart';
import '../ipc.dart';

class UrlBar extends StatelessWidget {
  const UrlBar({super.key});

  @override
  Widget build(BuildContext context) {
    var model = context.watch<ContentModel>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'URL',
            ),
            onSubmitted: (url) {
              model.updateUrl(url);
              urlSubmit(
                url,
                (resp) => Provider.of<ContentModel>(
                  context,
                  listen: false,
                ).handleServerResponse(context, resp),
              );
            },
          ),
        ),
      ],
    );
  }
}
