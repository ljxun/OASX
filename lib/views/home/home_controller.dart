import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

enum HomeDisplayMode { grid, list }

class HomeController extends GetxController {
  final ScriptService _scriptService = Get.find<ScriptService>();
  final _storage = GetStorage();
  List<ScriptModel> get scriptModels =>
      _scriptService.scriptModelMap.values.toList();

  final RxList<String> selectedScripts = <String>[].obs;
  final RxBool isSelectionModeActive = false.obs;

  static double get _defaultCardWidth => PlatformUtils.isMobile ? 400.0 : 350.0;
  static const double _defaultCardHeight = 200.0;

  final displayMode = HomeDisplayMode.grid.obs;
  final columns = 0.obs; // 0 = 按卡片宽度自动计算
  late final cardWidth = _defaultCardWidth.obs;
  final cardHeight = _defaultCardHeight.obs;

  @override
  void onInit() {
    _loadLayout();
    super.onInit();
  }

  void _loadLayout() {
    final raw = _storage.read(StorageKey.homeLayout.name);
    if (raw is! String || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      displayMode.value =
          map['mode'] == 'list' ? HomeDisplayMode.list : HomeDisplayMode.grid;
      columns.value = (map['columns'] as num?)?.toInt() ?? 0;
      cardWidth.value = (map['cardWidth'] as num?)?.toDouble() ?? cardWidth.value;
      cardHeight.value =
          (map['cardHeight'] as num?)?.toDouble() ?? cardHeight.value;
    } catch (_) {}
  }

  void saveLayout() {
    _storage.write(
        StorageKey.homeLayout.name,
        jsonEncode({
          'mode': displayMode.value == HomeDisplayMode.list ? 'list' : 'grid',
          'columns': columns.value,
          'cardWidth': cardWidth.value,
          'cardHeight': cardHeight.value,
        }));
  }

  void resetLayout() {
    displayMode.value = HomeDisplayMode.grid;
    columns.value = 0;
    cardWidth.value = _defaultCardWidth;
    cardHeight.value = _defaultCardHeight;
    saveLayout();
  }

  void enterSelectionMode() {
    isSelectionModeActive.value = true;
    selectedScripts.assignAll(scriptModels.map((m) => m.name).toList());
  }

  void exitSelectionMode() {
    isSelectionModeActive.value = false;
    selectedScripts.clear();
  }

  void toggleSelection(String scriptName) {
    if (selectedScripts.contains(scriptName)) {
      selectedScripts.remove(scriptName);
    } else {
      selectedScripts.add(scriptName);
    }
  }

  void startSelected() {
    for (var name in selectedScripts) {
      _scriptService.startScript(name);
    }
    exitSelectionMode();
  }

  void stopSelected() {
    for (var name in selectedScripts) {
      _scriptService.stopScript(name);
    }
    exitSelectionMode();
  }

  void onReorder(int oldIndex, int newIndex) {
    _scriptService.reorderScripts(oldIndex, newIndex);
  }

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

  Future<void> reconnect() async {
    Get.snackbar('提示', '正在重新连接...',
        duration: const Duration(milliseconds: 2000));
    final wsService = Get.find<WebSocketService>();
    for (var name in _scriptService.scriptModelMap.keys) {
      wsService.connect(name: name, force: true);
    }
  }
}
