import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';

class HomeController extends GetxController {
  final ScriptService _scriptService = Get.find<ScriptService>();
  List<ScriptModel> get scriptModels => _scriptService.scriptModelMap.values.toList();

  void toggleScript(String scriptName) {
    final script = _scriptService.findScriptModel(scriptName);
    if (script == null) return;

    if (script.state.value == ScriptState.running) {
      _scriptService.stopScript(scriptName);
    } else {
      _scriptService.startScript(scriptName);
    }
  }
}
