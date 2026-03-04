import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/home/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  String _getTaskSummary(ScriptModel scriptModel) {
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
      body: Obx(
        () => GridView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: controller.scriptModels.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400, // 每个格子的最大宽度
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3, // 调整宽高比
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
                      title:
                          Text(scriptModel.name, overflow: TextOverflow.ellipsis),
                      subtitle: Text(_getTaskSummary(scriptModel),
                          overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusIndicator(scriptModel.state.value),
                          IconButton(
                            icon: const Icon(Icons.power_settings_new_rounded),
                            isSelected:
                                scriptModel.state.value == ScriptState.running,
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
