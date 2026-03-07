library overview;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/component/blur_loading_overlay.dart';
import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/component/log/log_widget.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/utils/time_utils.dart';
import 'package:oasx/views/args/args_view.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/views/overview/widgets/task_tree_view.dart';

import 'package:styled_widget/styled_widget.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:oasx/translation/i18n_content.dart';

part '../../controller/overview/overview_controller.dart';
part '../../controller/overview/taskitem_model.dart';
part './taskitem_view.dart';
part './widgets/pending_task_widget.dart';
part './widgets/waiting_task_widget.dart';
part './widgets/running_task_widget.dart';
part './widgets/task_scheduler_widget.dart';

class Overview extends StatelessWidget {
  final String name;
  const Overview({Key? key, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final overviewController = Get.find<OverviewController>(tag: name);

    return Scaffold(
      appBar: buildPlatformAppBar(context),
      body: Obx(() {
        if (context.mediaQuery.orientation == Orientation.portrait) {
          return buildPortraitLayout();
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column (Task Tree - always visible)
            SizedBox(
              width: 200,
              child: DragTarget<Map<String, dynamic>>(
                builder: (context, candidateData, rejectedData) {
                  bool isHovering = candidateData.isNotEmpty;
                  return Card(
                    margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                    clipBehavior: Clip.antiAlias,
                    color: isHovering
                        ? Colors.red.withOpacity(0.2)
                        : Theme.of(context).cardColor,
                    child: TaskTreeView(name: name),
                  );
                },
                onWillAccept: (data) {
                  return data != null &&
                      (data['source'] == 'pending' ||
                          data['source'] == 'waiting');
                },
                onAccept: (data) {
                  final task = data['model'] as TaskItemModel;
                  overviewController.disableScriptTask(task);
                },
              ),
            ),
            // Right Content Area (Switches between default and args)
            Expanded(
              child: overviewController.selectedTaskName.value == null
                  ? _buildDefaultContent(overviewController)
                  : Args(overviewController: overviewController),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDefaultContent(OverviewController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Center Column
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              children: [
                _SchedulerWidget(controller: controller),
                _RunningWidget(controller: controller),
                _PendingWidget(controller: controller),
                Expanded(
                  child: _WaitingWidget(controller: controller),
                ),
              ],
            ),
          ),
        ),
        // Right Column
        Expanded(
          flex: 5,
          child: LogWidget(
            key: ValueKey(controller.hashCode),
            controller: controller,
            title: I18n.log.tr,
            enableCollapse: false,
          ).marginOnly(right: 10, bottom: 10),
        ),
      ],
    );
  }

  Widget buildPortraitLayout() {
    final overviewController = Get.find<OverviewController>(tag: name);
    return SingleChildScrollView(
      child: <Widget>[
        _SchedulerWidget(controller: overviewController),
        TaskTreeView(name: name),
        _RunningWidget(controller: overviewController),
        _PendingWidget(controller: overviewController),
        _WaitingWidget(controller: overviewController)
            .constrained(maxHeight: 200),
        Args(overviewController: overviewController),
        LogWidget(
                key: ValueKey(overviewController.hashCode),
                controller: overviewController,
                title: I18n.log.tr,
                enableCollapse: false)
            .constrained(maxHeight: 500)
            .marginOnly(left: 10, top: 10, right: 10)
      ].toColumn(),
    );
  }
}
