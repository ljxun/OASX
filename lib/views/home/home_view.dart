import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return Obx(
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
          return Card(
            child: Obx(
              () => Center(
                child: ListTile(
                  title: Text(scriptModel.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_getTaskSummary(scriptModel),
                      overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusIndicator(scriptModel.state.value),
                      IconButton(
                        icon: const Icon(Icons.power_settings_new_rounded),
                        isSelected: scriptModel.state.value == ScriptState.running,
                        onPressed: () =>
                            controller.toggleScript(scriptModel.name),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
