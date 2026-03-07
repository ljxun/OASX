import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MultiSelectDialog extends StatefulWidget {
  final List<String> allScripts;
  final String currentScript;

  const MultiSelectDialog({
    Key? key,
    required this.allScripts,
    required this.currentScript,
  }) : super(key: key);

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  final List<String> _selectedScripts = [];

  @override
  Widget build(BuildContext context) {
    final availableScripts =
        widget.allScripts.where((s) => s != widget.currentScript).toList();

    return AlertDialog(
      title: const Text('复制到...'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableScripts.length,
          itemBuilder: (context, index) {
            final scriptName = availableScripts[index];
            final isSelected = _selectedScripts.contains(scriptName);
            return CheckboxListTile(
              title: Text(scriptName),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedScripts.add(scriptName);
                  } else {
                    _selectedScripts.remove(scriptName);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: null),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Get.back(result: _selectedScripts),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
