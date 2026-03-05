part of overview;

class _PendingWidget extends StatelessWidget {
  const _PendingWidget({
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
            Text(I18n.pending.tr,
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            SizedBox( // Give the list a fixed height
              height: 140,
              child: DragTarget<Map<String, dynamic>>(
                onWillAcceptWithDetails: (details) {
                  if (details.data.isEmpty ||
                      details.data.length != 2 ||
                      details.data['source'] == null ||
                      details.data['model'] == null) {
                    return false;
                  }
                  final source = details.data['source'] as String;
                  return source != 'pending';
                },
                onAcceptWithDetails: (details) async {
                  final model = details.data['model'] as TaskItemModel;
                  await controller.onMoveToPending(model);
                },
                builder: (context, candidateData, rejectedData) {
                  return Obx(() {
                    return BlurLoadingOverlay(
                      loading: controller.isPendingLoading.value,
                      child: ListView.builder(
                        itemCount:
                            controller.scriptModel.pendingTaskList.length,
                        itemBuilder: (context, index) {
                          final model =
                              controller.scriptModel.pendingTaskList[index];
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
                              source: 'pending',
                            ),
                          );
                        },
                      ).clipRect().decorated(
                          border: Border.all(
                            color: candidateData.isNotEmpty
                                ? Colors.green
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
