library login;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/controller/settings.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/server/server_view.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/utils/platform_utils.dart';

part './login_binding.dart';
part '../../controller/login/login_controller.dart';

class LoginView extends StatelessWidget {
  LoginView({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformAppBar(context),
      floatingActionButton: PlatformUtils.isWindows ? _serverButton() : null,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      body: _login(context),
    );
  }

  Widget _login(BuildContext context) {
    List<double> maxWidthHigh = switch (Theme.of(context).platform) {
      TargetPlatform.windows => [400, 500],
      TargetPlatform.linux => [400, 500],
      TargetPlatform.macOS => [400, 500],
      _ => [],
    };
    return FormBuilder(
      key: _formKey,
      child: <Widget>[_address(), _signin()]
          .toColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center),
    )
        .padding(vertical: 10)
        .constrained(
            maxHeight: maxWidthHigh.isNotEmpty ? maxWidthHigh[0] : 500,
            maxWidth: maxWidthHigh.isNotEmpty ? maxWidthHigh[1] : 400)
        .alignment(Alignment.center);
  }

  Widget _address() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'address',
      initialValue: loginController.address.value,
      decoration: const InputDecoration(
        labelText: 'Address',
        hintText: 'e.g. 127.0.0.1:8080',
        prefixIcon: Icon(Icons.dns_outlined),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Address is required';
        }
        if (!RegExp(r'^\d+\.\d+\.\d+\.\d+:\d+$').hasMatch(val)) {
          return 'Format: [ip]:[port]';
        }
        return null;
      },
    ).padding(horizontal: 20, top: 20);
  }

  Widget _signin() {
    LoginController loginController = Get.find<LoginController>();
    return ElevatedButton(
      onPressed: () async => {
        if (_formKey.currentState?.saveAndValidate() ?? false)
          {await loginController.toMain(data: _formKey.currentState!.value)}
      },
      child: const Text('Connect'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
    ).padding(horizontal: 20, top: 40);
  }

  Widget _serverButton() {
    return FloatingActionButton(
        heroTag: 'SERVER',
        child: const Icon(Icons.developer_board_rounded),
        onPressed: () {
          Get.toNamed('/server');
        });
  }
}
