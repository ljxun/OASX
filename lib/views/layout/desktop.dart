import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/views/home/home_view.dart';
import 'package:oasx/views/layout/appbar.dart';

class DesktopLayoutView extends StatelessWidget {
  const DesktopLayoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformAppBar(context),
      body: const HomeView(),
    );
  }
}
