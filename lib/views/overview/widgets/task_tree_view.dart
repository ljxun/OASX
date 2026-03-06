import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/views/layout/widgets/tree_view.dart';
import 'package:oasx/views/overview/overview_view.dart';

class TaskTreeView extends StatefulWidget {
  final String name;
  const TaskTreeView({Key? key, required this.name}) : super(key: key);

  @override
  State<TaskTreeView> createState() => _TaskTreeViewState();
}

class _TaskTreeViewState extends State<TaskTreeView> {
  Map<String, List<String>> _treeData = {};
  late final OverviewController _overviewController;
  final notTaskList = ['Home'];

  @override
  void initState() {
    super.initState();
    _overviewController = Get.find<OverviewController>(tag: widget.name);
    _fetchTreeData();
  }

  Future<void> _fetchTreeData() async {
    final data = await ApiClient().getScriptMenu();
    if (mounted) {
      setState(() {
        _treeData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_treeData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return TreeView(
      data: _treeData,
      onTap: (taskName) {
        if (taskName == 'Overview') {
          _overviewController.deselectTask();
        } else if (!notTaskList.contains(taskName)) {
          _overviewController.selectTask(taskName);
        }
      },
    );
  }
}
