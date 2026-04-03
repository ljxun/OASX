import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/views/nav/view_nav.dart';
import 'package:oasx/views/overview/overview_view.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../../translation/i18n_content.dart';

// 第一级 节点
class TreeNode1 extends StatefulWidget {
  final String title;
  final void Function(String title)? onTap;
  final List<String> children;

  const TreeNode1(
      {super.key,
      required this.title,
      required this.onTap,
      required this.children});

  @override
  TreeNode1State createState() => TreeNode1State();
}

class TreeNode1State extends State<TreeNode1> {
  // 判断是否没有后续节点
  bool get _isLeaf {
    return widget.children.isEmpty || widget.children == [];
  }

  // 判断是否已经打开
  bool _isExpanded = false;

  // 鼠标是否在这个区域内
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    Icon icon = _isExpanded
        ? const Icon(Icons.expand_more)
        : const Icon(Icons.chevron_right);
    Text title = _isHover
        ? Text(widget.title.tr, style: const TextStyle(color: Colors.blue))
        : Text(widget.title.tr);
    return Column(
      children: [
        MouseRegion(
                // 鼠标进入的时候 高亮
                onEnter: (event) {
                  setState(() {
                    _isHover = true;
                  });
                },
                // 鼠标离开的时候 正常
                onExit: (event) {
                  setState(() {
                    _isHover = false;
                  });
                },
                child: buildChild(context, title, icon))
            // .alignment(Alignment.centerLeft)
            .constrained(width: 180)
            .alignment(Alignment.topLeft),
        if (_isExpanded && !_isLeaf)
          Column(
            children: widget.children
                .map((e) => TreeNode1(
                      title: e,
                      onTap: widget.onTap,
                      children: const [],
                    ))
                .toList(),
          ),
      ],
    );
  }

  final notTaskList = ['Overview', 'Home', 'Script', 'Restart', 'GlobalGame'];

  Widget buildChild(BuildContext context, Text title, Icon icon) {
    if (_isLeaf && !notTaskList.contains(widget.title)) {
      return Obx(() {
        return LongPressDraggable<Map<String, dynamic>>(
          data: {
            'model': TaskItemModel(
                Get.find<NavCtrl>().selectedScript.value, widget.title, ''),
            'source': 'treeNode'
          },
          feedback: _buildFeedback(context),
          child: GestureDetector(
            onSecondaryTapUp: (_) => _showCopyDialog(context),
            child: TextButton(
              style: ButtonStyle(
                padding:
                    WidgetStateProperty.all(const EdgeInsets.only(left: 20)),
                alignment: Alignment.centerLeft,
              ),
              onPressed: onPressed,
              child: title,
            ),
          ),
        );
      });
    }
    return _isLeaf
        ? TextButton(
            style: ButtonStyle(
              padding:
                  MaterialStateProperty.all(const EdgeInsets.only(left: 20)),
              alignment: Alignment.centerLeft,
            ),
            onPressed: onPressed,
            child: title)
        : TextButton.icon(
            style: const ButtonStyle(alignment: Alignment.centerLeft),
            onPressed: onPressed,
            icon: icon,
            label: title);
  }

  void Function()? onPressed() {
    widget.onTap!(widget.title);
    setState(() => _isExpanded = !_isExpanded);
    return null;
  }

  Widget _buildFeedback(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    return Material(
      color: Colors.transparent,
      child:
          Text(widget.title.tr, style: Theme.of(context).textTheme.titleMedium)
              .decorated(
                color: themeService.isDarkMode
                    ? Colors.blueGrey.shade700
                    : Colors.blueGrey.shade100,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
              )
              .width(150)
              .height(30)
              .paddingAll(8)
              .opacity(0.8),
    );
  }

  // 显示复制对话框
  void _showCopyDialog(BuildContext context) {
    final navController = Get.find<NavCtrl>();
    final currentScript = navController.selectedScript.value;
    final currentTask = widget.title;
    
    // 获取所有配置列表（排除当前配置和首页）
    final configList = navController.navNameList.value
        .where((name) => name != currentScript && name != 'Home')
        .toList();
    
    // 如果没有可复制的配置，直接返回
    if (configList.isEmpty) {
      Get.snackbar(
        '提示',
        '没有其他可复制的配置',
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    // 已选中的配置
    final selectedConfigs = <String>{}.obs;
    
    Get.defaultDialog(
      title: '复制到...',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: configList.map((configName) {
          return Obx(() => CheckboxListTile(
            value: selectedConfigs.contains(configName),
            onChanged: (value) {
              if (value == true) {
                selectedConfigs.add(configName);
              } else {
                selectedConfigs.remove(configName);
              }
            },
            title: Text(configName.tr),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ));
        }).toList(),
      ),
      textConfirm: I18n.confirm.tr,
      textCancel: I18n.cancel.tr,
      onConfirm: () async {
        if (selectedConfigs.isNotEmpty) {
          final model = TaskItemModel(
            currentScript,
            currentTask,
            '',
            groupName: null,
          );
          
          // 复制到所有选中的配置，等待所有操作完成
          int successCount = 0;
          for (final targetConfig in selectedConfigs) {
            final result = await navController.copyTask(model, targetConfig);
            if (result) {
              successCount++;
            }
          }
          
          // 关闭对话框
          Get.back();
          
          // 显示复制结果
          if (successCount > 0) {
            String tipMsg = '${model.scriptName}-[${model.taskName.value.tr}] -> $selectedConfigs';
            Get.snackbar(
              I18n.copy_success.tr,
              '$tipMsg 成功复制 $successCount/${selectedConfigs.length} 个配置',
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          Get.back();
        }
      },
      onCancel: () => Get.back(),
    );
  }
}

// 第二级 节点 ------------------------------------------------------------------
// class TreeNode2 extends StatefulWidget {
//   final String title;
//   final void Function(String title)? onTap;

//   const TreeNode2({super.key, required this.title, required this.onTap});

//   @override
//   TreeNode2State createState() => TreeNode2State();
// }

// class TreeNode2State extends State<TreeNode1> {
//   @override
//   Widget build(BuildContext context) {}
// }
