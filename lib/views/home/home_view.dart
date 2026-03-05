import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/home/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  // Helper to get the main status line
  String _getTaskStatusAndName(ScriptModel scriptModel) {
    if (scriptModel.runningTask.value.taskName.value.isNotEmpty) {
      return '运行中 - ${scriptModel.runningTask.value.taskName.value.tr}';
    }
    if (scriptModel.pendingTaskList.isNotEmpty) {
      return '队列中 - ${scriptModel.pendingTaskList.first.taskName.value.tr}';
    }
    if (scriptModel.waitingTaskList.isNotEmpty) {
      return '等待中 - ${scriptModel.waitingTaskList.first.taskName.value.tr}';
    }
    return '空闲'.tr;
  }

  // Helper to get the time, only for waiting tasks
  Widget _getTaskTime(BuildContext context, ScriptModel scriptModel) {
    if (scriptModel.waitingTaskList.isNotEmpty &&
        scriptModel.runningTask.value.taskName.value.isEmpty &&
        scriptModel.pendingTaskList.isEmpty) {
      final task = scriptModel.waitingTaskList.first;
      return Text(
        task.nextRun.value,
        style: Theme.of(context).textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox.shrink(); // Return an empty widget if not applicable
  }

  void _showContextMenu(
      BuildContext context, Offset position, String scriptName) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 5, position.dy + 5),
      items: [
        PopupMenuItem(
          child: Text(I18n.rename.tr),
          onTap: () => controller.renameConfig(scriptName),
        ),
        PopupMenuItem(
          child: Text(I18n.delete.tr, style: const TextStyle(color: Colors.red)),
          onTap: () => controller.deleteConfig(scriptName),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_config',
            onPressed: () => controller.addConfig(context),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'settings',
            onPressed: () => Get.toNamed('/settings'),
            child: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                '阴阳师助手',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 100.0), // Side margins set to 100
                itemCount: controller.scriptModels.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350, // Increased to make 3 columns the default on most screens
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.0,
                ),
                itemBuilder: (context, index) {
                  final scriptModel = controller.scriptModels[index];
                  return GestureDetector(
                    onTap: () => Get.toNamed('/overview/${scriptModel.name}'),
                    onSecondaryTapDown: (details) {
                      if (PlatformUtils.isMobile) return;
                      _showContextMenu(
                          context, details.globalPosition, scriptModel.name);
                    },
                    onLongPressStart: (details) {
                      if (!PlatformUtils.isMobile) return;
                      _showContextMenu(
                          context, details.globalPosition, scriptModel.name);
                    },
                    child: Card(
                      child: Obx(
                        () => Center(
                          child: ListTile(
                            title: Text(scriptModel.name,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getTaskStatusAndName(scriptModel),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                _getTaskTime(context, scriptModel),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusIndicator(scriptModel.state.value),
                                IconButton(
                                  icon: const Icon(
                                      Icons.power_settings_new_rounded),
                                  isSelected: scriptModel.state.value ==
                                      ScriptState.running,
                                  onPressed: () =>
                                      controller.toggleScript(scriptModel.name),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ScriptState state) {
    return switch (state) {
      ScriptState.running => const SpinKitChasingDots(
          color: Colors.green,
          size: 22,
        ),
      ScriptState.inactive =>
        const Icon(Icons.donut_large, size: 26, color: Colors.grey),
      ScriptState.warning =>
        const SpinKitDoubleBounce(color: Colors.orange, size: 26),
      ScriptState.updating => const Icon(Icons.browser_updated_rounded,
          size: 26, color: Colors.blue),
    };
  }
}
