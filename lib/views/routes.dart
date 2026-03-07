import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/views/home/home_binding.dart';
import 'package:oasx/views/layout/layout.dart';
import 'package:oasx/views/layout/binding.dart';
import 'package:oasx/views/login/login_view.dart';
import 'package:oasx/views/overview/overview_view.dart';
import 'package:oasx/views/settings/settings_view.dart';
import 'package:oasx/views/server/server_view.dart';
import 'package:oasx/service/script_service.dart';

class Routes {
  /// when the app is opened, this page will be the first to be shown
  static const initial = '/login';

  static final routes = [
    GetPage(
      name: '/login',
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: '/main',
      page: () => const LayoutView(),
      bindings: [
        LayoutBinding(),
        HomeBinding(),
      ],
    ),
    GetPage(
        name: '/overview',
        page: () {
          // 从参数中获取名称
          final args = Get.arguments as Map<String, dynamic>?;
          final name = args?['name'] as String?;
          if (name == null) {
            return const Text("Configuration not found");
          }
          
          // Check if the script model exists
          final scriptService = Get.find<ScriptService>();
          final scriptModel = scriptService.findScriptModel(name);
          if (scriptModel == null) {
            final errorMsg1 = 'ERROR: Script model not found for name: $name';
            final errorMsg2 = 'Available scripts: ${scriptService.scriptModelMap.keys.toList()}';
            print(errorMsg1);
            print(errorMsg2);
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      '找不到配置：$name',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '可用配置：${scriptService.scriptModelMap.keys.join(", ")}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('返回'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // The controller will be created here if not found,
          // and automatically disposed when the page is closed.
          Get.put(tag: name, OverviewController(name: name));
          return Overview(name: name);
        }),
    GetPage(
      name: '/settings',
      page: () => SettingsView(),
    ),
    GetPage(
      name: '/server',
      page: () => const ServerView(),
      binding: BindingsBuilder(() {
        Get.put<ServerController>(ServerController());
      }),
    ),
  ];
}
