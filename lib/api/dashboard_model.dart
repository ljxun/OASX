class DashboardModel {
  final Map<String, ConfigStatus> configs;

  DashboardModel({required this.configs});

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      configs: (json['configs'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, ConfigStatus.fromJson(value)),
      ),
    );
  }
}

class ConfigStatus {
  final bool isRunning;
  final String latestTask;
  final String taskStatus;

  ConfigStatus({
    required this.isRunning,
    required this.latestTask,
    required this.taskStatus,
  });

  factory ConfigStatus.fromJson(Map<String, dynamic> json) {
    return ConfigStatus(
      isRunning: json['is_running'],
      latestTask: json['latest_task'],
      taskStatus: json['task_status'],
    );
  }
}
