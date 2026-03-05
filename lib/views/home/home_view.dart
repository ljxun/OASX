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
              () {
                final scriptModels = controller.scriptModels;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 100.0),
                  itemCount: scriptModels.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                  ),
                  itemBuilder: (context, index) {
                    final scriptModel = scriptModels[index];
                    
                    return DragTarget<String>(
                      builder: (context, candidateData, rejectedData) {
                        return Draggable<String>(
                          data: scriptModel.name,
                          // The widget being dragged now has a Material ancestor to ensure correct theming,
                          // and the card itself provides the rounded shape for the shadow.
                          feedback: Material(
                            type: MaterialType.transparency,
                            child: SizedBox(
                              width: 350,
                              child: _buildCard(context, scriptModel, isDragging: true),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: _buildCard(context, scriptModel),
                          ),
                          child: _buildCard(context, scriptModel),
                        );
                      },
                      onWillAccept: (data) => data != scriptModel.name,
                      onAccept: (draggedItemName) {
                        final oldIndex = scriptModels.indexWhere((m) => m.name == draggedItemName);
                        final newIndex = index;
                        if (oldIndex != -1) {
                          controller.onReorder(oldIndex, newIndex);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Refactored to remove the outer Material widget and simplify the structure.
  Widget _buildCard(BuildContext context, ScriptModel scriptModel, {bool isDragging = false}) {
    return GestureDetector(
      onTap: () => Get.toNamed('/overview/${scriptModel.name}'),
      onSecondaryTapDown: (details) {
        if (PlatformUtils.isMobile) return;
        _showContextMenu(context, details.globalPosition, scriptModel.name);
      },
      onLongPressStart: (details) {
        if (!PlatformUtils.isMobile) return;
        _showContextMenu(context, details.globalPosition, scriptModel.name);
      },
      child: Obx(
        () => Card(
          elevation: isDragging ? 8.0 : 1.0, // Elevation is now controlled directly on the Card
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(scriptModel.name, overflow: TextOverflow.ellipsis),
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
                  trailing: IconButton(
                    icon: const Icon(Icons.power_settings_new_rounded),
                    isSelected: scriptModel.state.value == ScriptState.running,
                    onPressed: () => controller.toggleScript(scriptModel.name),
                  ),
                ),
              ),
              _buildStatusLine(scriptModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLine(ScriptModel scriptModel) {
    final state = scriptModel.state.value;

    switch (state) {
      case ScriptState.running:
        return LinearProgressIndicator(
          backgroundColor: Colors.green.withOpacity(0.2),
          color: Colors.green,
          minHeight: 4,
        );
      case ScriptState.inactive:
        if (scriptModel.waitingTaskList.isNotEmpty || scriptModel.pendingTaskList.isNotEmpty) {
          return LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.transparent,
            color: Colors.amber,
            minHeight: 4,
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}
