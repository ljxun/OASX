import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';

class HomeController extends GetxController {
  final ScriptService _scriptService = Get.find<ScriptService>();
  List<ScriptModel> get scriptModels => _scriptService.scriptModelMap.values.toList();
}
