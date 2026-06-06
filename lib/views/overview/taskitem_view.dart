part of overview;

class TaskItemView extends StatelessWidget {
  final TaskItemModel model;
  final String source; // 来源
  final bool enableDrag; // 是否允许拖拽
  final OverviewController? controller; // 控制器引用

  const TaskItemView(
    this.model, {
    super.key,
    required this.source,
    this.enableDrag = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (model.isAllEmpty()) return const SizedBox(height: 30);

    // 如果禁用拖拽，直接返回内容
    if (!enableDrag) {
      return _buildContent(context);
    }

    return LongPressDraggable<Map<String, dynamic>>(
      data: {'model': model, 'source': source},
      feedback: _buildFeedback(context),
      child: _buildContent(context),
    );
  }

  /// 拖动时，跟随手指移动的反馈组件
  Widget _buildFeedback(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    return Material(
      color: Colors.transparent,
      child: Text(model.taskName.value.tr,
              style: Theme.of(context).textTheme.titleMedium)
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

  /// 普通状态下显示内容
  Widget _buildContent(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.transparent, // 保留可点击区域
        borderRadius: BorderRadius.circular(4),
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
    return <Widget>[
      Text(model.taskName.value.tr,
          style: Theme.of(context).textTheme.labelLarge),
      Obx(() {
        if (!enableDrag) {
          return Text(model.nextRun.value,
              style: Theme.of(context).textTheme.labelMedium);
        }
        return DateTimePicker(
            hoverStyle: Theme.of(context).textTheme.labelMedium,
            notHoverStyle: Theme.of(context).textTheme.labelMedium,
            value: model.nextRun.value,
            onChange: (nv) async {
              final ret = await Get.find<ArgsController>()
                  .updateScriptTaskNextRun(
                      model.scriptName, model.taskName.value, nv);
              if (ret) {
                Get.snackbar(I18n.setting_saved.tr, nv,
                    duration: const Duration(seconds: 1));
              }
            });
      })
    ]
        .toColumn(crossAxisAlignment: CrossAxisAlignment.start)
        .paddingOnly(bottom: 5);
  }

  Widget _action(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态切换按钮（钟表/闪电）
        if (controller != null)
          IconButton(
            icon: Icon(
              source == 'waiting'
                  ? Icons.flash_on    // 等待中：闪电图标
                  : Icons.access_time, // 运行中/队列中：钟表图标
              size: 24,
            ),
            onPressed: () async {
              if (source == 'pending') {
                await controller!.onMoveToWaiting(model);
              } else if (source == 'waiting') {
                await controller!.onMoveToPending(model);
              } else if (source == 'running') {
                await controller!.onMoveToWaiting(model);
              }
            },
            tooltip: source == 'pending' 
              ? '立即等待' 
              : source == 'waiting'
                ? '立即运行'
                : '立即等待',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        // 设置按钮（齿轮图标，无边框）
        IconButton(
          icon: const Icon(Icons.settings, size: 24),
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
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
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
                    }));
          },
          tooltip: '设置',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ).paddingOnly(right: 8),
      ],
    );
  }
}
