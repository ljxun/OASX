import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/home/home_controller.dart';
import 'package:oasx/views/nav/view_nav.dart';
import 'package:window_manager/window_manager.dart';

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
          body: Obx(() {
            final topArea = SizedBox(
              height: controller.topMargin.value,
              width: double.infinity,
            );
            return Column(
              children: [
                // 桌面端：顶部空白区域可拖动窗口
                PlatformUtils.isDesktop
                    ? DragToMoveArea(child: topArea)
                    : topArea,
                Expanded(
                  child:
                      controller.displayMode.value == HomeDisplayMode.list
                          ? _buildListView(context)
                          : _buildGridView(context),
                ),
              ],
            );
          }),
        ));
  }

  Widget _buildGridView(BuildContext context) {
    final scriptModels = controller.scriptModels;
    final horizontalPadding = controller.horizontalMargin.value;
    final columns = controller.columns.value;
    final cardWidth = controller.cardWidth.value;
    final cardHeight = controller.cardHeight.value;

    final gridDelegate = columns > 0
        ? SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: cardHeight,
          )
        : SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: cardWidth,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: cardHeight,
          ) as SliverGridDelegate;

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: scriptModels.length,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        final scriptModel = scriptModels[index];
        return DragTarget<String>(
          builder: (context, candidateData, rejectedData) {
            return Draggable<String>(
              data: scriptModel.name,
              feedback: Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
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
            final oldIndex = controller.scriptModels
                .indexWhere((m) => m.name == draggedItemName);
            if (oldIndex != -1) {
              controller.onReorder(oldIndex, index);
            }
          },
        );
      },
    );
  }

  Widget _buildListView(BuildContext context) {
    final scriptModels = controller.scriptModels;
    final horizontalPadding = controller.horizontalMargin.value;

    return ReorderableListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: scriptModels.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) newIndex -= 1;
        controller.onReorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final scriptModel = scriptModels[index];
        return Padding(
          key: ValueKey(scriptModel.name),
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(Icons.drag_indicator),
                ),
              ),
              Expanded(child: _buildRowCard(context, scriptModel)),
            ],
          ),
        );
      },
    );
  }

  // 行模式：名称、任务状态、时间在同一行显示
  Widget _buildRowCard(BuildContext context, ScriptModel scriptModel) {
    final titleStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16);
    final subtitleStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13);
    final isSelected = controller.selectedScripts.contains(scriptModel.name);

    return GestureDetector(
      onTap: () => _onCardTap(scriptModel),
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
          elevation: isSelected ? 8.0 : 1.0,
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : null,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        scriptModel.name,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _getTaskStatusAndName(scriptModel),
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _buildRowTimeInfo(scriptModel, subtitleStyle),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary)
                    else if (!controller.isSelectionModeActive.value)
                      IconButton(
                        icon: const Icon(Icons.power_settings_new_rounded),
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
              ),
              _buildStatusLine(scriptModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowTimeInfo(ScriptModel scriptModel, TextStyle? style) {
    final onlyWaiting = scriptModel.waitingTaskList.isNotEmpty &&
        scriptModel.runningTask.value.taskName.value.isEmpty &&
        scriptModel.pendingTaskList.isEmpty;
    if (!onlyWaiting) return const SizedBox.shrink();
    if (scriptModel.state.value == ScriptState.running) {
      return _CountdownTimer(
        targetTime: scriptModel.waitingTaskList.first.nextRun.value,
        style: style,
      );
    }
    return Text(
      scriptModel.waitingTaskList.first.nextRun.value,
      style: style,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _onCardTap(ScriptModel scriptModel) {
    if (controller.isSelectionModeActive.value) {
      controller.toggleSelection(scriptModel.name);
    } else {
      final navController = Get.find<NavCtrl>();
      final scriptIndex =
          navController.navNameList.indexOf(scriptModel.name);
      if (scriptIndex != -1) {
        navController.switchScript(scriptIndex);
      }
    }
  }

  void _showLayoutSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Obx(() {
              final isGrid =
                  controller.displayMode.value == HomeDisplayMode.grid;
              return ListView(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(I18n.layout_settings.tr,
                          style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: Text(I18n.restore_default.tr),
                        onPressed: controller.resetLayout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(I18n.display_mode.tr)),
                      SegmentedButton<HomeDisplayMode>(
                        segments: [
                          ButtonSegment(
                            value: HomeDisplayMode.grid,
                            icon: const Icon(Icons.grid_view_rounded),
                            label: Text(I18n.grid_view.tr),
                          ),
                          ButtonSegment(
                            value: HomeDisplayMode.list,
                            icon: const Icon(Icons.view_agenda_outlined),
                            label: Text(I18n.list_view.tr),
                          ),
                        ],
                        selected: {controller.displayMode.value},
                        onSelectionChanged: (v) {
                          controller.displayMode.value = v.first;
                          controller.saveLayout();
                        },
                      ),
                    ],
                  ),
                  if (isGrid) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text(I18n.columns_per_row.tr)),
                        DropdownButton<int>(
                          value: controller.columns.value,
                          items: [
                            DropdownMenuItem(
                                value: 0, child: Text(I18n.auto_fit.tr)),
                            for (var i = 1; i <= 6; i++)
                              DropdownMenuItem(value: i, child: Text('$i')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            controller.columns.value = v;
                            controller.saveLayout();
                          },
                        ),
                      ],
                    ),
                    if (controller.columns.value == 0)
                      _buildSliderTile(
                        context,
                        label: I18n.card_width.tr,
                        value: controller.cardWidth.value,
                        min: 200,
                        max: 600,
                        onChanged: (v) => controller.cardWidth.value = v,
                        onChangeEnd: (_) => controller.saveLayout(),
                      ),
                    _buildSliderTile(
                      context,
                      label: I18n.card_height.tr,
                      value: controller.cardHeight.value,
                      min: 100,
                      max: 400,
                      onChanged: (v) => controller.cardHeight.value = v,
                      onChangeEnd: (_) => controller.saveLayout(),
                    ),
                  ],
                  _buildSliderTile(
                    context,
                    label: I18n.top_margin.tr,
                    value: controller.topMargin.value,
                    min: 0,
                    max: 100,
                    onChanged: (v) => controller.topMargin.value = v,
                    onChangeEnd: (_) => controller.saveLayout(),
                  ),
                  _buildSliderTile(
                    context,
                    label: I18n.horizontal_margin.tr,
                    value: controller.horizontalMargin.value,
                    min: 0,
                    max: 300,
                    onChanged: (v) => controller.horizontalMargin.value = v,
                    onChangeEnd: (_) => controller.saveLayout(),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 240,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min) ~/ 10,
            label: value.round().toString(),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        SizedBox(width: 40, child: Text(value.round().toString())),
      ],
    );
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
    return Obx(() {
      if (controller.isSelectionModeActive.value) {
        return const SizedBox.shrink();
      }
      final expanded = controller.isFabExpanded.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'add_config',
                        tooltip: I18n.config_add.tr,
                        onPressed: () => controller.addConfig(context),
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton.small(
                        heroTag: 'multi_select',
                        tooltip: '多选',
                        onPressed: controller.enterSelectionMode,
                        child: const Icon(Icons.check_box_outlined),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton.small(
                        heroTag: 'layout_settings',
                        tooltip: I18n.layout_settings.tr,
                        onPressed: () => _showLayoutSettings(context),
                        child: const Icon(Icons.tune),
                      ),
                      const SizedBox(height: 10),
                      Obx(() => FloatingActionButton.small(
                            heroTag: 'refresh',
                            tooltip: I18n.refresh.tr,
                            onPressed: controller.isRefreshing.value
                                ? null
                                : () => controller.reconnect(),
                            child: controller.isRefreshing.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  )
                                : const Icon(Icons.refresh),
                          )),
                      const SizedBox(height: 10),
                      FloatingActionButton.small(
                        heroTag: 'settings',
                        tooltip: I18n.setting.tr,
                        onPressed: () => Get.toNamed('/settings'),
                        child: const Icon(Icons.settings),
                      ),
                      const SizedBox(height: 10),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          FloatingActionButton(
            heroTag: 'fab_toggle',
            onPressed: () => controller.isFabExpanded.toggle(),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: expanded ? 0.125 : 0,
              child: Icon(expanded ? Icons.close : Icons.menu),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCard(BuildContext context, ScriptModel scriptModel,
      {bool isDragging = false}) {
    final titleStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18);
    final subtitleStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14);
    final isSelected = controller.selectedScripts.contains(scriptModel.name);

    return GestureDetector(
      onTap: () => _onCardTap(scriptModel),
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
