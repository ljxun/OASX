import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/overview/overview_view.dart';

class HomeController extends GetxController {
  final ScriptService _scriptService = Get.find<ScriptService>();
  List<ScriptModel> get scriptModels =>
      _scriptService.scriptModelMap.values.toList();

  void toggleScript(String scriptName) {
    final script = _scriptService.findScriptModel(scriptName);
    if (script == null) return;

    if (script.state.value == ScriptState.running) {
      _scriptService.stopScript(scriptName);
    } else {
      _scriptService.startScript(scriptName);
    }
  }

  Future<void> addConfig(BuildContext context) async {
    String newName = await ApiClient().getNewConfigName();
    final template = 'template'.obs;
    List<String> configAll = await ApiClient().getConfigAll();
    Get.defaultDialog(
        title: I18n.config_add.tr,
        middleText: '',
        onConfirm: () async {
          await ApiClient().configCopy(newName, template.value);
          Get.find<ScriptService>().addScriptModel(newName);
          Get.back();
        },
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(I18n.new_name.tr),
            TextFormField(
                initialValue: newName,
                onChanged: (value) {
                  newName = value;
                }),
            Text(I18n.config_copy_from_exist.tr),
            Obx(() {
              return DropdownButton<String>(
                value: template.value,
                menuMaxHeight: 300,
                items: configAll
                    .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                        value: e.toString(),
                        child: Text(
                          e.toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                        )))
                    .toList(),
                onChanged: (value) {
                  template.value = value.toString();
                },
              );
            }),
          ],
        ));
  }

  Future<void> deleteConfig(String name) async {
    final canDelete = await _tryCloseScriptWithReason(
        name, 'delete script[$name] config file');
    if (!canDelete) return;
    Get.defaultDialog(
      title: I18n.delete.tr,
      textConfirm: I18n.confirm.tr,
      textCancel: I18n.cancel.tr,
      middleText: '${I18n.delete_confirm.tr} "$name"?',
      onConfirm: () async {
        if (!await ApiClient().deleteConfig(name)) return;
        Get.find<ScriptService>().deleteScriptModel(name);
        Get.back();
      },
      onCancel: () {},
    );
  }

  Future<void> renameConfig(String oldName) async {
    final canRename = await _tryCloseScriptWithReason(
        oldName, 'rename script[$oldName] config file');
    if (!canRename) return;

    String newName = oldName;
    final formKey = GlobalKey<FormState>();
    Get.defaultDialog(
      title: I18n.rename.tr,
      textConfirm: I18n.confirm.tr,
      textCancel: I18n.cancel.tr,
      content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: I18n.new_name.tr,
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return I18n.name_cannot_empty.tr;
              }
              if (['Home', 'home'].contains(value)) {
                return I18n.name_invalid.tr;
              }
              if (oldName == value ||
                  _scriptService.scriptModelMap.keys.contains(value)) {
                return I18n.name_duplicate.tr;
              }
              return null;
            },
            onChanged: (v) => newName = v,
          )),
      onConfirm: () async {
        if (!(formKey.currentState?.validate() ?? false)) {
          return;
        }
        if (!await ApiClient().renameConfig(oldName, newName)) return;
        Get.find<ScriptService>().deleteScriptModel(oldName);
        Get.find<ScriptService>().addScriptModel(newName);
        Get.back();
      },
      onCancel: () {},
    );
  }

  Future<bool> _tryCloseScriptWithReason(
      String scriptName, String reason) async {
    try {
      final wsService = Get.find<WebSocketService>();
      final scriptModel = Get.find<ScriptService>().findScriptModel(scriptName);
      if (scriptModel != null &&
          scriptModel.state.value == ScriptState.running) {
        Get.snackbar(I18n.tip.tr, I18n.config_update_tip.tr,
            duration: const Duration(milliseconds: 2000));
        return false;
      }
      await wsService.close(scriptName);
    } catch (e) {
      if (e.toString().contains('not found')) {
        return true;
      }
      return false;
    }
    return true;
  }
}
