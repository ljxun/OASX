library server;

import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/component/log/log_widget.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:oasx/views/login/login_view.dart';
import 'package:process_run/shell.dart';
import 'dart:io';
import 'package:styled_widget/styled_widget.dart';
import 'package:code_editor/code_editor.dart';

import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/controller/settings.dart';

part './deploy_view.dart';
part '../../controller/server/server_controller.dart';

class ServerView extends StatelessWidget {
  const ServerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentBackgroundColor = theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200];

    return Scaffold(
      backgroundColor: contentBackgroundColor,
      appBar: buildPlatformAppBar(context),
      floatingActionButton: startServerButton(),
      body: _body(),
    );
  }

  Widget _body() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      ServerController serverController = Get.find<ServerController>();
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              context: context,
              title: I18n.root_path_server.tr,
              child: path(context),
              initiallyExpanded: true,
            ),
            const SizedBox(height: 16),
            _buildCard(
              context: context,
              title: I18n.setup_deploy.tr,
              child: deploy(constraints.maxHeight - 200, context),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: LogWidget(
                key: ValueKey(serverController.hashCode),
                controller: serverController,
                title: I18n.setup_log.tr,
              ).constrained(height: constraints.maxHeight - 200),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          )
        ],
      ),
    );
  }

  Widget path(BuildContext context) {
    return GetX<ServerController>(builder: (controller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  controller.rootPathServer.value,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  String? selectedDirectory =
                      await FilePicker.platform.getDirectoryPath();
                  if (selectedDirectory == null) {
                    return;
                  }
                  controller.updateRootPathServer(selectedDirectory);
                },
                child: Text(I18n.select_root_path_server.tr),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              controller.rootPathAuthenticated.value
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.rootPathAuthenticated.value
                      ? I18n.root_path_correct.tr
                      : I18n.root_path_incorrect.tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(I18n.root_path_server_help.tr, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    });
  }

  Widget deploy(double maxHeight, BuildContext context) {
    return code(maxHeight - 50);
  }

  Widget startServerButton() {
    return GetX<ServerController>(builder: (controller) {
      if (controller.rootPathAuthenticated.value) {
        return FloatingActionButton(
            child: Obx(() => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: controller.isDeployLoading.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.auto_mode_rounded),
                )),
            onPressed: () {
              if (controller.isDeployLoading.value) return;
              controller.run();
            });
      } else {
        return const SizedBox.shrink();
      }
    });
  }

  Widget code(double maxHeight) {
    final theme = Theme.of(Get.context!);
    return GetX<ServerController>(builder: (controller) {
      FileEditor file = FileEditor(
        name: "deploy.yaml",
        language: "yaml",
        code: controller.deployContent.value,
      );
      EditorModel model = EditorModel(
        files: [file],
        styleOptions: EditorModelStyleOptions(
          heightOfContainer: maxHeight,
          editorColor: theme.colorScheme.surface.withOpacity(0.5),
        ),
      );
      return CodeEditor(
        model: model,
        formatters: const ["yaml"],
        onSubmit: (String language, String value) {
          controller.writeDeploy(value);
        },
      );
    });
  }
}
