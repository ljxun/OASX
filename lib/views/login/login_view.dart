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
    final theme = Theme.of(context);
    final contentBackgroundColor = theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200];

    return Scaffold(
      backgroundColor: contentBackgroundColor,
      appBar: buildPlatformAppBar(context),
      floatingActionButton: PlatformUtils.isWindows ? _serverButton() : null,
      body: Center(
        child: SingleChildScrollView(
          child: _loginCard(context),
        ),
      ),
    );
  }

  Widget _loginCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: _loginForm(context),
      ),
    ).constrained(maxWidth: 400);
  }

  Widget _loginForm(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: <Widget>[
        _adminTitle(context),
        const SizedBox(height: 24),
        _addressField(),
        const SizedBox(height: 16),
        _usernameField(),
        const SizedBox(height: 16),
        _passwordField(),
        const SizedBox(height: 32),
        _signinButton(),
      ].toColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
      ),
    );
  }

  Widget _adminTitle(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Text(
      'Admin Login',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: theme.colorScheme.primary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _usernameField() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'username',
      initialValue: loginController.username.value,
      decoration: _inputDecoration('Username', Icons.person_outline),
    );
  }

  Widget _passwordField() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'password',
      initialValue: loginController.password.value,
      decoration: _inputDecoration('Password', Icons.lock_outline),
      obscureText: true,
    );
  }

  Widget _addressField() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'address',
      initialValue: loginController.address.value,
      decoration: _inputDecoration('Address', Icons.http_outlined),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
    );
  }

  Widget _signinButton() {
    LoginController loginController = Get.find<LoginController>();
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () async {
        if (_formKey.currentState?.saveAndValidate() ?? false) {
          await loginController.toMain(data: _formKey.currentState!.value);
        }
      },
      child: const Text('Login', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _serverButton() {
    return FloatingActionButton(
      heroTag: 'SERVER',
      child: const Icon(Icons.developer_board_rounded),
      onPressed: () {
        Get.toNamed('/server');
      },
    );
  }
}
