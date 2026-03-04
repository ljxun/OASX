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
}) {
  final platform = PlatformUtils.platfrom();
  const double appBarHeight = 60.0;
  final Color appBarColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[850]! : Colors.blue;
  final Color titleColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white;

  return switch (platform) {
    PlatformType.windows => _windowAppbar(
      context,
      onMenuPressed: isCollapsed ? onMenuPressed : null,
      height: appBarHeight,
      color: appBarColor,
      titleColor: titleColor,
    ),
    PlatformType.linux => _desktopAppbar(
      height: appBarHeight,
      color: appBarColor,
      titleColor: titleColor,
    ),
    PlatformType.macOS => _desktopAppbar(
      height: appBarHeight,
      color: appBarColor,
      titleColor: titleColor,
    ),
    PlatformType.android => _mobileTabletAppbar(
      height: appBarHeight,
      color: appBarColor,
      titleColor: titleColor,
    ),
    PlatformType.iOS => _mobileTabletAppbar(
      height: appBarHeight,
      color: appBarColor,
      titleColor: titleColor,
    ),
    PlatformType.web => _webAppbar(
      height: appBarHeight,
      color: appBarColor,
      titleColor: titleColor,
    ),
    _ => _webAppbar(
      height: appBarHeight,
      color: appBarColor,
      titleColor: titleColor,
    ),
  };
}

/// Windows 特殊标题栏
PreferredSizeWidget _windowAppbar(BuildContext context, {VoidCallback? onMenuPressed, required double height, required Color color, required Color titleColor}) {
  return PreferredSize(
    preferredSize: Size.fromHeight(height),
    child: WindowCaption(
      brightness: Theme.of(context).brightness,
      backgroundColor: color,
      title: Row(
        children: [
          if (onMenuPressed != null)
            IconButton(
              icon: Icon(Icons.menu, color: titleColor),
              onPressed: onMenuPressed,
            ),
          DefaultTextStyle(
            style: TextStyle(color: titleColor, fontSize: 20),
            child: getTitle(),
          ),
        ],
      ),
    ),
  );
}

/// 桌面 (Linux / macOS)
PreferredSizeWidget _desktopAppbar({required double height, required Color color, required Color titleColor}) {
  return AppBar(
    toolbarHeight: height,
    backgroundColor: color,
    titleTextStyle: TextStyle(color: titleColor, fontSize: 20),
    title: getTitle(),
    elevation: 4,
  );
}

/// Web
PreferredSizeWidget _webAppbar({required double height, required Color color, required Color titleColor}) {
  return PreferredSize(
    preferredSize: Size.fromHeight(height),
    child: AppBar(
      toolbarHeight: height,
      backgroundColor: color,
      titleTextStyle: TextStyle(color: titleColor, fontSize: 20),
      title: getTitle(),
      elevation: 4,
    ).padding(left: 16, top: 10, bottom: 10),
  );
}

/// 移动端 (Android / iOS)
PreferredSizeWidget _mobileTabletAppbar({required double height, required Color color, required Color titleColor}) {
  return AppBar(
    toolbarHeight: height,
    backgroundColor: color,
    titleTextStyle: TextStyle(color: titleColor, fontSize: 20),
    title: getTitle(),
    elevation: 4,
  );
}
