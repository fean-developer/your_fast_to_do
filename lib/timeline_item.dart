import 'package:flutter/material.dart';



class TimelineItem {
  String title;
  String description;
  Color color;
  IconData icon;
  List<SubItem> subItems;
  bool isCompleted;

  TimelineItem({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.subItems,
    this.isCompleted = false,
  });

  void updateCompletion() {
    isCompleted = subItems.every((s) => s.completed);
  }

  static List<SubItem> parseSubItems(dynamic raw) {
    if (raw is List) {
      return raw.map<SubItem>((item) {
        if (item is String) {
          return SubItem(subitem: item, timers: [], completed: false);
        } else if (item is Map<String, dynamic> || item is Map) {
          return SubItem(
            subitem: item['subitem'] ?? '',
            timers: (item['timers'] as List?)?.map<TimerEntry>((t) => TimerEntry.fromJson(t)).toList() ?? [],
            completed: item['completed'] == true,
          );
        } else {
          return SubItem(subitem: '', timers: [], completed: false);
        }
      }).toList();
    }
    return [];
  }
}

class SubItem {
  String subitem;
  List<TimerEntry> timers;
  bool completed;

  SubItem({required this.subitem, required this.timers, this.completed = false});
}

class TimerEntry {
  DateTime start;
  DateTime end;

  TimerEntry({required this.start, required this.end});

  factory TimerEntry.fromJson(Map<String, dynamic> json) {
    return TimerEntry(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
    );
  }

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };
}
