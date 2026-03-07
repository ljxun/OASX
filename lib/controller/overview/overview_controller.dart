part of overview;

class OverviewController extends GetxController with LogMixin {
  String name;
  final scriptService = Get.find<ScriptService>();
  late final ScriptModel scriptModel;
  final isWaitingLoading = false.obs;
  final isPendingLoading = false.obs;

  final selectedTaskName = Rx<String?>(null);

  OverviewController({required this.name}) {
    // Initialize scriptModel in constructor to handle null case
    final model = scriptService.findScriptModel(name);
    if (model == null) {
      print('ERROR in OverviewController: ScriptModel not found for name: $name');
      print('Available scripts: ${scriptService.scriptModelMap.keys.toList()}');
      Get.snackbar('错误', '找不到脚本配置：$name');
      throw Exception('找不到脚本配置：$name');
    }
    scriptModel = model;
  }

  @override
  void onInit() {
    super.onInit();
  }

  @override
  Future<void> onClose() async {
    // close log
    super.onClose();
  }

  void selectTask(String taskName) {
    selectedTaskName.value = taskName;
    if (!Get.isRegistered<ArgsController>()) {
      Get.put(ArgsController());
    }
    final argsController = Get.find<ArgsController>();
    argsController.loadGroups(config: name, task: taskName);
  }

  void deselectTask() {
    selectedTaskName.value = null;
  }

  Future<void> toggleScript() async {
    if (scriptModel.state.value != ScriptState.running) {
      scriptService.startScript(name);
      // clearLog();
    } else {
      scriptService.stopScript(name);
    }
  }

  Future<void> onMoveToPending(TaskItemModel model) async {
    isPendingLoading.value = true;
    final nextRun =
        formatDateTime(DateTime.now().subtract(const Duration(minutes: 1)));
    final argsController = Get.find<ArgsController>();
    final updateRet =
        await argsController.updateScriptTask(name, model.taskName.value, true);
    if (!updateRet) {
      Get.snackbar(I18n.error.tr, 'Enable task fail',
          duration: const Duration(seconds: 2));
      isWaitingLoading.value = false;
      return;
    }
    final syncRet = await argsController.updateScriptTaskNextRun(
        name, model.taskName.value, nextRun);
    if (updateRet && syncRet) {
      Get.snackbar(I18n.tip.tr, I18n.success.tr,
          duration: const Duration(seconds: 2));
    } else {
      Get.snackbar(I18n.error.tr, '', duration: const Duration(seconds: 2));
    }
    isPendingLoading.value = false;
  }

  Future<void> onMoveToWaiting(TaskItemModel model) async {
    isWaitingLoading.value = true;
    final updateRet = await Get.find<ArgsController>()
        .updateScriptTask(name, model.taskName.value, true);
    if (!updateRet) {
      Get.snackbar(I18n.error.tr, 'Enable task fail',
          duration: const Duration(seconds: 2));
      isWaitingLoading.value = false;
      return;
    }
    final syncRet = await ApiClient().syncNextRun(name, model.taskName.value);
    if (updateRet && syncRet) {
      Get.snackbar(I18n.tip.tr, I18n.success.tr,
          duration: const Duration(seconds: 2));
    } else {
      Get.snackbar(I18n.error.tr, '', duration: const Duration(seconds: 2));
    }
    isWaitingLoading.value = false;
  }

  Future<bool> disableScriptTask(TaskItemModel model) async {
    final ret = await Get.find<ArgsController>()
        .updateScriptTask(model.scriptName, model.taskName.value, false);
    return ret;
  }
}
