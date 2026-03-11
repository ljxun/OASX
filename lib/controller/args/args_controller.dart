part of args;

class ArgsController extends GetxController {
  final groups = Rx<List<GroupsModel>>([]);
  final groupsName = Rx<List<String>>([]);
  final groupsData = Rx<Map<String, GroupsModel>>({});
  static const String schedulerGroup = 'scheduler';
  static const String nextRunArg = 'next_run';
  static const String enableArg = 'enable';

  // Store the current context
  String currentConfig = '';
  String currentTask = '';

  @override
  void onInit() {
    super.onInit();
  }

  void loadModel(Map<String, dynamic> json) {
    groups.value = [];
    json.forEach((key, value) {
      groups.value.add(GroupsModel(groupName: key, members: value));
    });
  }

  void loadModelfromStr(String json) {
    loadModel(jsonDecode(json));
  }

  /// 加载groups数据
  Future<void> loadGroups({String config = "", String task = ""}) async {
    // Store the context when loading
    currentConfig = config;
    currentTask = task;

    // 清空缓存数据
    groupsName.value = [];
    groupsData.value = {};
    List<String> groupsNameTemp = [];

    var json = await ApiClient().getScriptTask(config, task);
    // 更新groupsData
    // 更新groupsName
    for (var entry in json.entries) {
      groupsNameTemp.add(entry.key);
      List<ArgumentModel> arguments = [];
      for (var argument in entry.value) {
        arguments.add(ArgumentModel.fromJson(argument));
      }
      groupsData.value[entry.key] =
          GroupsModel(groupName: entry.key, members: arguments);
    }
    groupsName.value = groupsNameTemp;
  }

  Future<dynamic> getArgValue(
      String config, String task, String group, String argument) {
    if (groupsData.value.isEmpty) {
      loadGroups(config: config, task: task);
    }
    return groupsData.value[group]!.members
        .map((e) => e as ArgumentModel)
        .firstWhere((element) => element.title == argument)
        .value;
  }

  Future<bool> setArgument(String? config, String? task, String group,
      String argument, String type, var value) async {
    // Use the stored context if the arguments are null or empty
    config ??= currentConfig;
    task ??= currentTask;

    if (config.isEmpty || task.isEmpty) {
      // Still need a fallback or error handling if the context was never set
      printError(info: "ArgsController: config or task is empty on save.");
      return false;
    }

    final ret = await ApiClient()
        .putScriptArg(config, task, group, argument, type, value);
    // 设置的是调度器的内容,则自动更新调度器
    if (ret && group == schedulerGroup) {
      await Get.find<WebSocketService>().send(config, 'get_schedule');
    }
    return ret;
  }

  Future<bool> updateScriptTaskNextRun(
      String config, String task, String nextRun) async {
    return await setArgument(
        config, task, schedulerGroup, nextRunArg, 'next_run', nextRun);
  }

  Future<bool> updateScriptTask(String config, String task, bool enable) async {
    return await setArgument(
        config, task, schedulerGroup, enableArg, 'boolean', enable);
  }
}

class GroupsModel {
  final String groupName;
  List<dynamic> members;

  /// 把 json对象转化为 model
  GroupsModel({required this.groupName, required this.members});

  String getGroupName() => groupName;
}

class ArgumentModel {
  final String title;
  dynamic value;
  final String type;

  final String? description;

  final List<String>? enumEnum;
  final dynamic minimum;
  final dynamic maximum;
  final dynamic defaultValue;

  ArgumentModel(
    this.enumEnum,
    this.minimum,
    this.maximum,
    this.defaultValue,
    this.description, {
    required this.title,
    required this.value,
    required this.type,
  });

  factory ArgumentModel.fromJson(Map<String, dynamic> json) {
    dynamic value = json['value'];
    String type = json['type'] as String;

    if (type == 'time_delta' && (value is int || value is double)) {
      Duration duration = Duration(seconds: value.toInt());
      int day0 = duration.inDays;
      int hour0 = duration.inHours.remainder(24);
      int minute0 = duration.inMinutes.remainder(60);
      int second = duration.inSeconds.remainder(60);

      String day = day0 < 10 ? '0$day0' : '$day0';
      String hour = hour0 < 10 ? '0$hour0' : '$hour0';
      String minute = minute0 < 10 ? '0$minute0' : '$minute0';
      String seconds = second < 10 ? '0$second' : '$second';
      value = '$day $hour:$minute:$seconds';
    }

    return ArgumentModel(
        List<String>.from(json["enumEnum"]?.map((x) => x) ?? []),
        json['minimum'],
        json['maximum'],
        json['defaultValue'],
        json['description'],
        title: json['name'] as String,
        value: value,
        type: type);
  }

  set setValue(dynamic newValue) => value = newValue;
}
