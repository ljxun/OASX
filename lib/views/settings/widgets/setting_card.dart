import 'package:flutter/material.dart';
import 'package:oasx/views/settings/widgets/setting_item.dart';
import 'package:styled_widget/styled_widget.dart';

class SettingCard extends StatelessWidget {
  final String title;
  final List<SettingItem> items;

  const SettingCard({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Divider(height: 24),
          ...items
              .map(
                (item) => item.padding(bottom: 8),
              )
              .toList(),
        ].toColumn(crossAxisAlignment: CrossAxisAlignment.start),
      ),
    );
  }
}
