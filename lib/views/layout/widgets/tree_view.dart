import 'package:flutter/material.dart';
import './tree_node.dart';

class TreeView extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(String title)? onTap;

  const TreeView({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: data.entries
          .map((entry) => TreeNode1(
                title: entry.key,
                onTap: onTap,
                children: List<String>.from(entry.value),
              ))
          .toList(),
    );
  }
}
