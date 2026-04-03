import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/home/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

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
    return '与服务端断联'.tr;
  }

  Widget _getTaskTime(BuildContext context, ScriptModel scriptModel, TextStyle? style) {
    if (scriptModel.waitingTaskList.isNotEmpty &&
        scriptModel.runningTask.value.taskName.value.isEmpty &&
        scriptModel.pendingTaskList.isEmpty) {
      final task = scriptModel.waitingTaskList.first;
      return Text(
        task.nextRun.value,
        style: style,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox.shrink();
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
    return Obx(() => Scaffold(
          appBar: controller.isSelectionModeActive.value
              ? _buildMultiSelectAppBar(context)
              : null,
          floatingActionButton: _buildFloatingActionButtons(context),
          body: Column(
            children: [
              if (!controller.isSelectionModeActive.value)
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
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.7,
                      ),
                      itemBuilder: (context, index) {
                        final scriptModel = scriptModels[index];
                        return DragTarget<String>(
                          builder: (context, candidateData, rejectedData) {
                            return Draggable<String>(
                              data: scriptModel.name,
                              feedback: Material(
                                type: MaterialType.transparency,
                                child: SizedBox(
                                  width: 350,
                                  child: _buildCard(context, scriptModel,
                                      isDragging: true),
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
                            final oldIndex = controller.scriptModels
                                .indexWhere((m) => m.name == draggedItemName);
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
        ));
  }

  AppBar _buildMultiSelectAppBar(BuildContext context) {
    return AppBar(
      title: Text('已选择 ${controller.selectedScripts.length} 项'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: controller.exitSelectionMode,
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('全部启动'),
          onPressed: controller.startSelected,
        ),
        TextButton.icon(
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('全部停止'),
          onPressed: controller.stopSelected,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.isSelectionModeActive.value
              ? []
              : [
                  FloatingActionButton(
                    heroTag: 'add_config',
                    onPressed: () => controller.addConfig(context),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: 'multi_select',
                    onPressed: controller.enterSelectionMode,
                    child: const Icon(Icons.check_box_outlined),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: 'refresh',
                    onPressed: () => controller.reconnect(),
                    child: const Icon(Icons.refresh),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: 'settings',
                    onPressed: () => Get.toNamed('/settings'),
                    child: const Icon(Icons.settings),
                  ),
                ],
        ));
  }

  Widget _buildCard(BuildContext context, ScriptModel scriptModel,
      {bool isDragging = false}) {
    final titleStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18);
    final subtitleStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14);
    final isSelected = controller.selectedScripts.contains(scriptModel.name);

    return GestureDetector(
      onTap: () {
        if (controller.isSelectionModeActive.value) {
          controller.toggleSelection(scriptModel.name);
        } else {
          // 使用查询参数而不是路径参数传递名称
          Get.toNamed('/overview', arguments: {'name': scriptModel.name});
        }
      },
      onSecondaryTapDown: (details) {
        if (PlatformUtils.isMobile) return;
        _showContextMenu(context, details.globalPosition, scriptModel.name);
      },
      onLongPress: () {
        if (PlatformUtils.isMobile) {
          controller.enterSelectionMode();
          controller.toggleSelection(scriptModel.name);
        }
      },
      child: Obx(
        () => Card(
          elevation: isDragging || isSelected ? 8.0 : 1.0,
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : null,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  scriptModel.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                              ),
                              if (!controller.isSelectionModeActive.value)
                                IconButton(
                                  icon: const Icon(
                                      Icons.power_settings_new_rounded),
                                  color: switch (scriptModel.state.value) {
                                    ScriptState.running => Colors.green,
                                    ScriptState.warning => Colors.amber,
                                    _ => null,
                                  },
                                  onPressed: () =>
                                      controller.toggleScript(scriptModel.name),
                                ),
                            ],
                          ),
                          const Spacer(flex: 1),
                          Text(
                            _getTaskStatusAndName(scriptModel),
                            style: subtitleStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (scriptModel.waitingTaskList.isNotEmpty &&
                              scriptModel.runningTask.value.taskName.value
                                  .isEmpty &&
                              scriptModel.pendingTaskList.isEmpty) ...[
                            _getTaskTime(context, scriptModel, subtitleStyle),
                            const SizedBox(height: 4),
                            if (scriptModel.state.value ==
                                ScriptState.running)
                              _CountdownTimer(
                                targetTime: scriptModel
                                    .waitingTaskList.first.nextRun.value,
                                style: subtitleStyle,
                              ),
                          ],
                          if (scriptModel.pendingTaskList.isNotEmpty) ...[
                            Text(
                              '队列中 - ${scriptModel.pendingTaskList.first.taskName.value.tr}',
                              style: subtitleStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                  _buildStatusLine(scriptModel),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLine(ScriptModel scriptModel) {
    final state = scriptModel.state.value;
    final runningTask = scriptModel.runningTask.value;
    final pendingTaskList = scriptModel.pendingTaskList;
    final waitingTaskList = scriptModel.waitingTaskList;

    // Service exception - show yellow/orange line
    if (state == ScriptState.warning) {
      return LinearProgressIndicator(
        value: 1.0,
        backgroundColor: Colors.amber.withOpacity(0.2),
        color: Colors.amber,
        minHeight: 4,
      );
    }

    // Service is running
    if (state == ScriptState.running) {
      // Check if there's an active running task
      final hasRunningTask = runningTask.taskName.value.isNotEmpty;
      
      if (hasRunningTask) {
        // Running task - green marquee animation
        return LinearProgressIndicator(
          value: null,
          backgroundColor: Colors.green.withOpacity(0.2),
          color: Colors.green,
          minHeight: 4,
        );
      }
      
      // No running task, check if there are pending or waiting tasks
      final hasPendingTasks = pendingTaskList.isNotEmpty;
      final hasWaitingTasks = waitingTaskList.isNotEmpty;
      
      if (hasPendingTasks || hasWaitingTasks) {
        // Waiting task - green static line
        return LinearProgressIndicator(
          value: 1.0,
          backgroundColor: Colors.green.withOpacity(0.2),
          color: Colors.green,
          minHeight: 4,
        );
      }
    }

    // Default - no status line
    return const SizedBox(height: 4);
  }
}

class _CountdownTimer extends StatefulWidget {
  final String targetTime;
  final TextStyle? style;
  const _CountdownTimer({required this.targetTime, this.style});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  @override
  void didUpdateWidget(covariant _CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetTime != oldWidget.targetTime) {
      _updateRemaining();
    }
  }

  void _updateRemaining() {
    try {
      final target = DateTime.parse(widget.targetTime.trim());
      final now = DateTime.now();

      setState(() {
        _remaining = target.difference(now);
      });
    } catch (e) {
      setState(() => _remaining = Duration.zero);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '已超时';
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final days = duration.inDays;
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (days > 0) {
      return '$days 天 $hours:$minutes:$seconds 后执行';
    } else {
      return '$hours:$minutes:$seconds 后执行';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remaining),
      style: widget.style,
      overflow: TextOverflow.ellipsis,
    );
  }
}
