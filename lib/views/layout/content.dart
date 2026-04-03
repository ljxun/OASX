import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_getx_widget.dart';

import 'package:oasx/views/args/args_view.dart';
import 'package:oasx/views/home/home_view.dart';
import 'package:oasx/views/home/tool_view.dart';
import 'package:oasx/views/home/updater_view.dart';
import 'package:oasx/views/nav/view_nav.dart';
import 'package:oasx/views/overview/overview_view.dart';

Widget content() {
  return GetX<NavCtrl>(builder: (controller) {
    // 确保状态同步，如果 navNameList 为空则显示加载中
    if (controller.navNameList.value.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // 如果是首页，直接返回完整的 HomeView，不使用导航栏框架
    if (controller.selectedScript.value == 'Home' && 
        controller.selectedMenu.value == 'Home') {
      return const HomeView();
    }
    
    return switch ([
      controller.selectedScript.value,
      controller.selectedMenu.value
    ]) {
      // ignore: prefer_const_constructors, unused_local_variable
      [String name, 'Overview'] => Overview(),
      _ => Args(
        scriptName: controller.selectedScript.value,
        taskName: controller.selectedMenu.value,
      ),
    };
  });
}
