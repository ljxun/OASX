import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class SettingItem extends StatelessWidget {
  final Widget left;
  final Widget right;
  final VoidCallback? onTap;

  const SettingItem({
    super.key,
    required this.left,
    required this.right,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = <Widget>[
      DefaultTextStyle(
        style: theme.textTheme.bodyLarge!,
        child: left,
      ),
      const Spacer(),
      right,
    ]
        .toRow(
          crossAxisAlignment: CrossAxisAlignment.center,
        )
        .padding(horizontal: 16, vertical: 12);

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}
