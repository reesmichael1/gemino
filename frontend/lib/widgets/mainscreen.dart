import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../contentmodel.dart';
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
            Expanded(
              child: Consumer<ContentModel>(
                builder: (context, model, child) => model.contents,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
