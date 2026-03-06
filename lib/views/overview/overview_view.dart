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

    Widget buildDefaultLayout() {
      final theme = Theme.of(context);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column
          Container(
            width: 200,
            margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TaskTreeView(name: name),
          ),
          // Center Column
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  _SchedulerWidget(controller: overviewController),
                  _RunningWidget(controller: overviewController),
                  _PendingWidget(controller: overviewController),
                  Expanded(
                    child: _WaitingWidget(controller: overviewController),
                  ),
                ],
              ),
            ),
          ),
          // Right Column
          Expanded(
            flex: 5,
            child: LogWidget(
              key: ValueKey(overviewController.hashCode),
              controller: overviewController,
              title: I18n.log.tr,
              enableCollapse: false,
            ).marginOnly(right: 10, bottom: 10),
          ),
        ],
      );
    }

    Widget buildTaskSelectedLayout() {
      final theme = Theme.of(context);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column
          Container(
            width: 200,
            margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TaskTreeView(name: name),
          ),
          // Right Column (Args View)
          const Expanded(
            child: Args(),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: buildPlatformAppBar(context),
      body: Obx(() {
        final isTaskSelected = overviewController.selectedTaskName.value != null;
        if (context.mediaQuery.orientation == Orientation.landscape && isTaskSelected) {
          return buildTaskSelectedLayout();
        }
        return context.mediaQuery.orientation == Orientation.portrait
            ? buildPortraitLayout()
            : buildDefaultLayout();
      }),
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
        _WaitingWidget(controller: overviewController).constrained(maxHeight: 200),
        const Args(),
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
