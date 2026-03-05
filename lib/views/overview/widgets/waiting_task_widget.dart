part of overview;

class _WaitingWidget extends StatelessWidget {
  const _WaitingWidget({
    required this.controller,
  });

  final OverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero, // This is the last item, so no bottom margin
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(I18n.waiting.tr,
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Expanded(
              child: DragTarget<Map<String, dynamic>>(
                onWillAcceptWithDetails: (details) {
                  if (details.data.isEmpty ||
                      details.data.length != 2 ||
                      details.data['source'] == null ||
                      details.data['model'] == null) {
                    return false;
                  }
                  final source = details.data['source'] as String;
                  return source != 'waiting';
                },
                onAcceptWithDetails: (details) async {
                  final model = details.data['model'] as TaskItemModel;
                  await controller.onMoveToWaiting(model);
                },
                builder: (context, candidateData, rejectedData) {
                  return Obx(() {
                    return BlurLoadingOverlay(
                      loading: controller.isWaitingLoading.value,
                      child: ListView.builder(
                        itemCount:
                            controller.scriptModel.waitingTaskList.length,
                        itemBuilder: (context, index) {
                          final model =
                              controller.scriptModel.waitingTaskList[index];
                          return Slidable(
                            key: ValueKey(
                                '${model.scriptName}:${model.taskName.value}'),
                            direction: Axis.horizontal,
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              extentRatio: 0.2,
                              children: [
                                SlidableAction(
                                  onPressed: (BuildContext
                                      slidableContext) async {
                                    final ret = await controller
                                        .disableScriptTask(model);
                                    if (ret) {
                                      Get.snackbar(
                                          I18n.setting_saved.tr, 'false',
                                          duration:
                                              const Duration(seconds: 1));
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
                              model,
                              source: 'waiting',
                            ),
                          );
                        },
                      ).clipRect().decorated(
                          border: Border.all(
                            color: candidateData.isNotEmpty
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8)),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
