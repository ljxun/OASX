library args;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:get/get.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/views/nav/view_nav.dart';
import 'package:oasx/views/overview/overview_view.dart';
import 'package:styled_widget/styled_widget.dart';
import 'dart:convert';
import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'dart:async';

import 'package:oasx/api/api_client.dart';

import '../../translation/i18n_content.dart';

part './group_view.dart';
part './date_time_picker.dart';
part '../../controller/args/args_controller.dart';

class Args extends StatelessWidget {
  const Args(
      {Key? key, this.scriptName, this.taskName, this.groupDraggable = true})
      : super(key: key);
  final String? scriptName;
  final String? taskName;
  final bool groupDraggable;

  @override
  Widget build(BuildContext context) {
    return GetX<ArgsController>(builder: (controller) {
      final navController = Get.find<NavCtrl>();
      final selectedScript = navController.selectedScript.value;
      final selectedTask = navController.selectedMenu.value;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: ExpansionTileGroup(
          spaceBetweenItem: 16,
          children: controller.groupsName.value.map((name) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: ExpansionTileItem(
                initiallyExpanded: true,
                title: <Widget>[
                  if (groupDraggable)
                    Draggable<Map<String, dynamic>>(
                      data: {
                        'model': TaskItemModel(
                            scriptName ?? selectedScript,
                            taskName ?? selectedTask,
                            '',
                            groupName: name),
                        'source': 'argsViewGroup'
                      },
                      feedback: _buildFeedback(context, name),
                      child: const Icon(Icons.drag_indicator_outlined),
                    ),
                  const SizedBox(width: 8),
                  Text(name.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ].toRow(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min),
                children: _children(name),
              ),
            );
          }).toList(),
        ).constrained(maxWidth: 700, minWidth: 100),
      ).alignment(Alignment.topCenter);
    });
  }

  List<Widget> _children(String groupName) {
    ArgsController controller = Get.find();
    GroupsModel groupsModel = controller.groupsData.value[groupName]!;
    return groupsModel.members.map((_) {
      final index = groupsModel.members.indexOf(_);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ArgumentView(
          scriptName: scriptName,
          taskName: taskName,
          setArgument: controller.setArgument,
          getGroupName: groupsModel.getGroupName,
          index: index,
        ),
      );
    }).toList();
  }

  Widget _buildFeedback(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4.0,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator_outlined),
            const SizedBox(width: 8),
            Text(title.tr, style: theme.textTheme.titleMedium),
          ],
        ),
      ).width(200),
    );
  }
}

class ArgumentView extends StatefulWidget {
  final void Function(String? config, String? task, String group,
      String argument, String type, dynamic value) setArgument;
  final String Function() getGroupName;
  final int index;
  final String? scriptName;
  final String? taskName;

  const ArgumentView(
      {required this.setArgument,
      required this.getGroupName,
      required this.index,
      Key? key,
      this.scriptName,
      this.taskName})
      : super(key: key);

  @override
  _ArgumentViewState createState() => _ArgumentViewState();
}

class _ArgumentViewState extends State<ArgumentView> {
  Timer? timer;

  ArgumentModel get model {
    ArgsController controller = Get.find();
    GroupsModel? groupsModel =
        controller.groupsData.value[widget.getGroupName()];
    return groupsModel!.members[widget.index];
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 500;

    Widget content = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _title()),
              const SizedBox(width: 16),
              SizedBox(width: 220, child: _form()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_title(), const SizedBox(height: 8), _form()]);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: content,
    );
  }

  Widget _title() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SelectableText(
        model.title.tr,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      if (model.description != null && model.description!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: SelectableText(
            model.description!.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ]);
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
    );
  }

  Widget _form() {
    switch (model.type) {
      case "boolean":
        return CheckboxListTile(
          title: Text(model.title.tr, style: Theme.of(context).textTheme.bodyMedium),
          value: model.value,
          onChanged: onCheckboxChanged,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
      case "string":
      case "multi_line":
        return TextFormField(
          initialValue: model.value.toString(),
          maxLines: model.type == "multi_line" ? null : 1,
          decoration: _inputDecoration(null),
          onChanged: (value) {
            timer?.cancel();
            timer = Timer(const Duration(milliseconds: 1000),
                () => onStringChanged(value));
          },
        );
      case "number":
      case "integer":
        return TextFormField(
          initialValue: model.value.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                model.type == "integer" ? RegExp('[-0-9]') : RegExp('[-0-9.]')),
          ],
          decoration: _inputDecoration(null),
          onChanged: (value) {
            timer?.cancel();
            timer = Timer(const Duration(milliseconds: 1000),
                () => onNumberChanged(value));
          },
        );
      case "enum":
        return DropdownButtonFormField<String>(
          decoration: _inputDecoration(null),
          value: model.value.toString(),
          items: model.enumEnum!
              .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                  value: e.toString(),
                  child: Text(
                    e.toString().tr,
                    overflow: TextOverflow.ellipsis,
                  )))
              .toList(),
          onChanged: onEnumChanged,
        );
      case "date_time":
        return DateTimePicker(
          value: model.value,
          onChange: onDateTimeChanged,
        );
      case "time_delta":
        return TimeDeltaPicker(
          value: ensureTimeDeltaString(model.value),
          onChange: onTimeDeltaChanged,
        );
      case "time":
        return TimePicker(
          value: model.value,
          onChange: onTimeChanged,
        );
      default:
        return SelectableText(model.value.toString());
    }
  }

  void onCheckboxChanged(bool? value) {
    setState(() {
      widget.setArgument(widget.scriptName, widget.taskName,
          widget.getGroupName(), model.title, 'boolean', value);
      model.value = value;
    });
    showSnakbar(value);
  }

  void onStringChanged(String? value) {
    widget.setArgument(widget.scriptName, widget.taskName,
        widget.getGroupName(), model.title, 'string', value);
    showSnakbar(value);
  }

  void onNumberChanged(String? value) {
    widget.setArgument(widget.scriptName, widget.taskName,
        widget.getGroupName(), model.title, 'number', value);
    showSnakbar(value);
  }

  void onEnumChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(widget.scriptName, widget.taskName,
          widget.getGroupName(), model.title, 'enum', value);
    });
    showSnakbar(value);
  }

  void onDateTimeChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(widget.scriptName, widget.taskName,
          widget.getGroupName(), model.title, 'date_time', value);
    });
    showSnakbar(value);
  }

  void onTimeDeltaChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(widget.scriptName, widget.taskName,
          widget.getGroupName(), model.title, 'time_delta', value);
    });
    showSnakbar(value);
  }

  void onTimeChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(widget.scriptName, widget.taskName,
          widget.getGroupName(), model.title, 'time', value);
    });
    showSnakbar(value);
  }

  void showSnakbar(dynamic value) {
    Get.snackbar(I18n.setting_saved.tr, "$value",
        duration: const Duration(seconds: 1));
  }
}
