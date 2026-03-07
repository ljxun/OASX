import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/views/dialog/multi_select_dialog.dart';
import 'package:oasx/views/nav/view_nav.dart';
import 'package:oasx/views/overview/overview_view.dart';
import 'package:styled_widget/styled_widget.dart';

class TreeNode1 extends StatefulWidget {
  final String title;
  final void Function(String title)? onTap;
  final List<String> children;
  final int level;
  final String? selectedTask;

  const TreeNode1({
    super.key,
    required this.title,
    required this.onTap,
    required this.children,
    this.level = 0,
    this.selectedTask,
  });

  @override
  TreeNode1State createState() => TreeNode1State();
}

class TreeNode1State extends State<TreeNode1> {
  bool get _isLeaf => widget.children.isEmpty;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNodeTile(),
        if (_isExpanded && !_isLeaf) _buildChildNodes(),
      ],
    );
  }

  Widget _buildNodeTile() {
    final indent = 20.0 * widget.level;
    final isSelected = widget.title == widget.selectedTask;

    final tile = ListTile(
      contentPadding: EdgeInsets.only(left: indent + 16.0, right: 8.0),
      leading: _isLeaf ? null : _buildExpansionIcon(),
      title: Text(widget.title.tr),
      onTap: _handlePress,
      dense: true,
      visualDensity: VisualDensity.compact,
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
    );

    if (_isLeaf) {
      return GestureDetector(
        onSecondaryTapUp: (details) => _showContextMenu(context, details.globalPosition),
        child: Obx(() {
          return LongPressDraggable<Map<String, dynamic>>(
            data: {
              'model': TaskItemModel(
                Get.find<NavCtrl>().selectedScript.value,
                widget.title,
                '',
              ),
              'source': 'treeNode'
            },
            feedback: _buildFeedback(context),
            child: tile,
          );
        }),
      );
    }
    return tile;
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          child: const Text('复制到...'),
          onTap: _handleCopy,
        ),
      ],
    );
  }

  Future<void> _handleCopy() async {
    final scriptService = Get.find<ScriptService>();
    final currentScript = Get.find<NavCtrl>().selectedScript.value;
    final allScripts = scriptService.scriptModelMap.keys.toList();

    final List<String>? selectedScripts = await Get.dialog(
      MultiSelectDialog(
        allScripts: allScripts,
        currentScript: currentScript,
      ),
    );

    if (selectedScripts != null && selectedScripts.isNotEmpty) {
      for (final destScript in selectedScripts) {
        await ApiClient().copyTask(widget.title, destScript, currentScript);
      }
      Get.snackbar('成功', '任务已复制到 ${selectedScripts.join(', ')}');
    }
  }

  Widget _buildExpansionIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return RotationTransition(
          turns: child.key == const ValueKey('icon_add')
              ? Tween<double>(begin: -0.25, end: 0).animate(animation)
              : Tween<double>(begin: 0.25, end: 0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _isExpanded
          ? const Icon(Icons.remove, key: ValueKey('icon_remove'), size: 20)
          : const Icon(Icons.add, key: ValueKey('icon_add'), size: 20),
    );
  }

  Widget _buildChildNodes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.children
          .map((e) => TreeNode1(
                title: e,
                onTap: widget.onTap,
                children: const [],
                level: widget.level + 1,
                selectedTask: widget.selectedTask,
              ))
          .toList(),
    );
  }

  void _handlePress() {
    if (_isLeaf) {
      widget.onTap?.call(widget.title);
    } else {
      setState(() => _isExpanded = !_isExpanded);
    }
  }

  Widget _buildFeedback(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    return Material(
      color: Colors.transparent,
      child: Text(widget.title.tr, style: Theme.of(context).textTheme.titleMedium)
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
}
