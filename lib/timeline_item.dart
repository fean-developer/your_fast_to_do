import 'package:flutter/material.dart';

class TimelineItem {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final List<String> subItems;
  List<bool> subItemsCompleted;
  bool isCompleted;

  TimelineItem({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.subItems,
    this.isCompleted = false,
  }) : subItemsCompleted = List.filled(subItems.length, false);

  void updateCompletion() {
    isCompleted = subItemsCompleted.every((c) => c);
  }
}
