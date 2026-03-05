part of overview;

class _RunningWidget extends StatelessWidget {
  const _RunningWidget({
    required this.controller,
  });

  final OverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(I18n.running.tr,
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Obx(() {
              final state = controller.scriptModel.state.value;
              final task = controller.scriptModel.runningTask.value;
              final isRun = state == ScriptState.running;
              if (isRun) {
                return TaskItemView(
                  task,
                  source: 'running',
                  enableDrag: false,
                ).constrained(minHeight: 48);
              }
              return Slidable(
                key: ValueKey('${task.scriptName}:${task.taskName.value}'),
                direction: Axis.horizontal,
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.2,
                  children: [
                    SlidableAction(
                      onPressed: (BuildContext slidableContext) async {
                        final ret = await controller.disableScriptTask(task);
                        if (ret) {
                          Get.snackbar(I18n.setting_saved.tr, 'false',
                              duration: const Duration(seconds: 1));
                        } else {
                          Slidable.of(slidableContext)?.close();
                        }
                      },
                      flex: 1,
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.disabled_by_default_outlined,
                      autoClose: false,
                    ),
                  ],
                ),
                child: TaskItemView(
                  task,
                  source: 'running',
                  enableDrag: true,
                ).constrained(minHeight: 48),
              );
            }).clipRect(),
          ],
        ),
      ),
    );
  }
}
