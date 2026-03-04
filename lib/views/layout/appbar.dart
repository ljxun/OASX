import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:window_manager/window_manager.dart';

import 'package:oasx/views/layout/title.dart';
import 'package:oasx/utils/platform_utils.dart';

/// 统一入口：根据平台返回合适的 AppBar
PreferredSizeWidget buildPlatformAppBar(BuildContext context, {
  bool isCollapsed = false,
  VoidCallback? onMenuPressed,
  List<Widget>? actions,
}) {
  final platform = PlatformUtils.platfrom();
  return switch (platform) {
    PlatformType.windows => _windowAppbar(
      context,
      onMenuPressed: isCollapsed ? onMenuPressed : null,
      actions: actions,
    ),
    PlatformType.linux => _desktopAppbar(actions: actions),
    PlatformType.macOS => _desktopAppbar(actions: actions),
    PlatformType.android => _mobileTabletAppbar(actions: actions),
    PlatformType.iOS => _mobileTabletAppbar(actions: actions),
    PlatformType.web => _webAppbar(),
    _ => _webAppbar(),
  };
}

/// Windows 特殊标题栏
PreferredSizeWidget _windowAppbar(BuildContext context, {VoidCallback? onMenuPressed, List<Widget>? actions}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(50),
    child: WindowCaption(
      brightness: Theme.of(context).brightness,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          if (onMenuPressed != null)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            ),
          getTitle(),
          const Spacer(),
          if (actions != null) ...actions,
        ],
      ),
    ),
  );
}

/// 桌面 (Linux / macOS)
PreferredSizeWidget _desktopAppbar({List<Widget>? actions}) {
  return AppBar(
    title: getTitle(),
    actions: actions,
  );
}

/// Web
PreferredSizeWidget _webAppbar() {
  return PreferredSize(
    preferredSize: const Size.fromHeight(90),
    child: getTitle().padding(left: 16, top: 10, bottom: 10),
  );
}

/// 移动端 (Android / iOS)
PreferredSizeWidget _mobileTabletAppbar({List<Widget>? actions}) {
  return AppBar(
    title: getTitle(),
    actions: actions,
  );
}
