import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/views/home/home_view.dart';
import 'package:oasx/views/nav/view_nav.dart';
import 'package:oasx/views/layout/content.dart';
import 'package:oasx/utils/platform_utils.dart';

class DesktopLayoutView extends StatefulWidget {
  const DesktopLayoutView({Key? key}) : super(key: key);

  @override
  DesktopLayoutViewState createState() => DesktopLayoutViewState();
}

class DesktopLayoutViewState extends State<DesktopLayoutView> {
  static const double collapseBreakpoint = 900;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCollapsed = constraints.maxWidth < collapseBreakpoint;

        if (isCollapsed) {
          // 小屏模式：显示 Drawer
          return Scaffold(
            key: _scaffoldKey,
            appBar: buildPlatformAppBar(
              context,
              isCollapsed: true,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            drawer: const Drawer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Nav(),
                  TreeMenuView(),
                ],
              ),
            ),
            body: Center(child: content()),
          );
        } else {
          // 大屏模式：根据当前页面决定是否显示导航栏
          return GetX<NavCtrl>(builder: (controller) {
            // 如果是首页，不显示导航栏
            if (controller.selectedScript.value == 'Home' &&
                controller.selectedMenu.value == 'Home') {
              return Scaffold(
                appBar: buildPlatformAppBar(context),
                body: const HomeView(),
              );
            }
            
            // 其他页面显示导航栏
            return Scaffold(
              appBar: buildPlatformAppBar(context),
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Nav(),
                  const TreeMenuView(),
                  Expanded(
                    child: Center(child: content()),
                  ),
                ],
              ),
            );
          });
        }
      },
    );
  }
}