part of overview;

class TaskItemView extends StatelessWidget {
  final TaskItemModel model;
  final String source; // 来源
  final bool enableDrag; // 是否允许拖拽

  const TaskItemView(
    this.model, {
    super.key,
    required this.source,
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    if (model.isAllEmpty()) return const SizedBox(height: 50);

    // 如果禁用拖拽，直接返回内容
    if (!enableDrag) {
      return _buildContent(context);
    }

    return LongPressDraggable<Map<String, dynamic>>(
      data: {'model': model, 'source': source},
      feedback: _buildFeedback(context),
      childWhenDragging: Opacity(opacity: 0.5, child: _buildContent(context)),
      child: _buildContent(context),
    );
  }

  /// 拖动时，跟随手指移动的反馈组件
  Widget _buildFeedback(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4.0,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              model.taskName.value.tr,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ).width(250),
    );
  }

  /// 普通状态下显示内容
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _name(context),
          _action(context),
        ],
      ),
    );
  }

  Widget _name(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          model.taskName.value.tr,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Obx(() {
          if (!enableDrag) {
            return Text(
              model.nextRun.value,
              style: theme.textTheme.bodySmall,
            );
          }
          return DateTimePicker(
            hoverStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
            notHoverStyle: theme.textTheme.bodySmall!,
            value: model.nextRun.value,
            onChange: (nv) async {
              final ret = await Get.find<ArgsController>()
                  .updateScriptTaskNextRun(
                      model.scriptName, model.taskName.value, nv);
              if (ret) {
                Get.snackbar(I18n.setting_saved.tr, nv,
                    duration: const Duration(seconds: 1));
              }
            },
          );
        }),
      ],
    );
  }

  Widget _action(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: I18n.setting.tr,
      onPressed: () async {
        double maxWidth = min(750, Get.width * 0.9);
        double maxHeight = Get.height * 0.7;
        final argsController = Get.find<ArgsController>();
        Get.defaultDialog(
          title: '${model.taskName.value.tr}${I18n.setting.tr}',
          content: FutureBuilder<void>(
            future: argsController.loadGroups(
                config: model.scriptName, task: model.taskName.value),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Args(
                  scriptName: model.scriptName,
                  taskName: model.taskName.value,
                  groupDraggable: false,
                ).constrained(
                  minWidth: maxWidth,
                  minHeight: maxHeight,
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                );
              }
            },
          ),
        );
      },
    );
  }
}
