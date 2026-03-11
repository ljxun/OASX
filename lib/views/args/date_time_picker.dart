// ignore_for_file: must_be_immutable

part of args;

final dateYears = <String>['2025', '2026', '2027', '2028'];
final dateMonths = List.generate(
        12, (index) => (index + 1) < 10 ? '0${index + 1}' : '${index + 1}')
    .toList();
final dateDaysInMonth = List.generate(daysInMonth(),
    (index) => (index + 1) < 10 ? '0${index + 1}' : '${index + 1}').toList();
final dateDaysInWeek =
    List.generate(8, (index) => index < 10 ? '0$index' : '$index').toList();
final dateHours =
    List.generate(24, (index) => index < 10 ? '0$index' : '$index').toList();
final dateMinutes =
    List.generate(60, (index) => index < 10 ? '0$index' : '$index').toList();
final dateSeconds =
    List.generate(60, (index) => index < 10 ? '0$index' : '$index').toList();

final dateTimeData = [
  dateYears,
  dateMonths,
  dateDaysInMonth,
  dateHours,
  dateMinutes,
  dateSeconds,
];
final dateTimeDelta = [
  dateDaysInWeek,
  dateHours,
  dateMinutes,
  dateSeconds,
];
final dateTime = [
  dateHours,
  dateMinutes,
  dateSeconds,
];

int daysInMonth() {
  DateTime now = DateTime.now();
  int year = now.year;
  int month = now.month;
  DateTime lastDayOfMonth =
      DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
  return lastDayOfMonth.day;
}

String ensureTimeDeltaString(dynamic value) {
  if (value is String) {
    // 应该加上一个 格式的验证
    return value;
  } else if (value is int || value is double) {
    return value.toString();
  }
  return '00 00:00:00';
}

// -------------------------------------------------------------------------Base

class DateTimePickerBase extends StatefulWidget {
  String value = '';
  final TextStyle? hoverStyle;
  final TextStyle? notHoverStyle;
  void Function(String value) onChange = (value) {};

  DateTimePickerBase(
      {super.key,
      required this.value,
      required this.onChange,
      this.hoverStyle,
      this.notHoverStyle});

  @override
  State<StatefulWidget> createState() => DateTimePickerBaseState();
}

class DateTimePickerBaseState extends State<DateTimePickerBase> {
  // 占位

  // 鼠标是否在这个区域内
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    final hoverStyle = widget.hoverStyle ??
        TextStyle(color: Theme.of(context).primaryColor, fontSize: 16);
    final notHoverStyle = widget.notHoverStyle ?? const TextStyle(fontSize: 16);
    // 固定高度，防止文字变大时撑开布局
    final baseHeight = (hoverStyle.fontSize ?? 16) * 1.2;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: Text(widget.value, style: _isHover ? hoverStyle : notHoverStyle)
          .scale(
              all: _isHover ? 1.1 : 1.0,
              alignment: Alignment.centerLeft,
              animate: true)
          .animate(const Duration(milliseconds: 120), Curves.easeOut)
          .constrained(height: baseHeight)
          .gestures(onTap: () => showPicker(context, widget.value)),
    );
  }

  // 重写
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      data: dateTimeData,
      suffix: [
        I18n.year.tr,
        I18n.month.tr,
        I18n.day.tr,
        I18n.hour.tr,
        I18n.minute.tr,
        I18n.seconds.tr
      ],
    );
  }
}

// ---------------------------------------------------------------------DateTime
class DateTimePicker extends DateTimePickerBase {
  DateTimePicker(
      {super.key,
      required super.value,
      required super.onChange,
      super.hoverStyle,
      super.notHoverStyle});

  @override
  State<StatefulWidget> createState() => DateTimePickerState();
}

class DateTimePickerState extends DateTimePickerBaseState {
  @override
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      data: dateTimeData,
      selectData: prePrecess(value),
      onConfirm: onConfirm,
      suffix: [
        I18n.year.tr,
        I18n.month.tr,
        I18n.day.tr,
        I18n.hour.tr,
        I18n.minute.tr,
        I18n.seconds.tr
      ],
    );
  }

  dynamic onConfirm(List<dynamic> p, List<int> position) {
    String year = dateTimeData[0][position[0]];
    String month = dateTimeData[1][position[1]];
    String day = dateTimeData[2][position[2]];
    String hour = dateTimeData[3][position[3]];
    String minute = dateTimeData[4][position[4]];
    String seconds = dateTimeData[5][position[5]];
    widget.onChange('$year-$month-$day $hour:$minute:$seconds');
  }

  // 数据的预处理
  List prePrecess(dynamic value) {
    List result = [0, 0, 0, 0, 0, 0];
    // 如果是字符串, 那就分离出2023-10-02T11:11:11
    if (value is String) {
      result = value.split(RegExp(r'\D+'));
    }
    return result;
  }
}

// --------------------------------------------------------------------TimeDelta
class TimeDeltaPicker extends DateTimePickerBase {
  TimeDeltaPicker({super.key, required super.value, required super.onChange});

  @override
  State<StatefulWidget> createState() => TimeDeltaPickerState();
}

class TimeDeltaPickerState extends DateTimePickerBaseState {
  @override
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      data: dateTimeDelta,
      selectData: prePrecess(value),
      onConfirm: onConfirm,
      suffix: [I18n.day.tr, I18n.hour.tr, I18n.minute.tr, I18n.seconds.tr],
    );
  }

  dynamic onConfirm(List<dynamic> p, List<int> position) {
    String day = dateTimeDelta[0][position[0]];
    String hour = dateTimeDelta[1][position[1]];
    String minute = dateTimeDelta[2][position[2]];
    String seconds = dateTimeDelta[3][position[3]];
    widget.onChange('$day $hour:$minute:$seconds');
  }

  // 数据的预处理
  List prePrecess(dynamic value) {
    List result = [0, 0, 0, 0];
    // 如果是字符串, 那就分离出2023-10-02T11:11:11
    if (value is String) {
      result = value.split(RegExp(r'\D+'));
    }
    if (value is double) {
      result = value.toString().split(RegExp(r'\D+'));
    }
    return result;
  }
}

// -------------------------------------------------------------------------Time
class TimePicker extends DateTimePickerBase {
  TimePicker({super.key, required super.value, required super.onChange});

  @override
  State<StatefulWidget> createState() => TimePickerState();
}

class TimePickerState extends DateTimePickerBaseState {
  @override
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      data: dateTime,
      selectData: prePrecess(value),
      onConfirm: onConfirm,
      suffix: [I18n.hour.tr, I18n.minute.tr, I18n.seconds.tr],
    );
  }

  dynamic onConfirm(List<dynamic> p, List<int> position) {
    String hour = dateTime[0][position[0]];
    String minute = dateTime[1][position[1]];
    String seconds = dateTime[2][position[2]];
    widget.onChange('$hour:$minute:$seconds');
  }

  // 数据的预处理
  List prePrecess(dynamic value) {
    List result = [0, 0, 0, 0];
    // 如果是字符串, 那就分离出2023-10-02T11:11:11
    if (value is String) {
      result = value.split(RegExp(r'\D+'));
    }
    return result;
  }
}
