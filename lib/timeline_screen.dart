import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'admin_screen.dart';
import 'timeline_item_widget.dart';
import 'timeline_item.dart';


class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  Future<void> saveSubItemsCompletedToJson() async {
    final file = File('lib/timeline_data.json');
    final String jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);

    for (final item in jsonData) {
      if (item['subItems'] is List) {
        for (var i = 0; i < (item['subItems'] as List).length; i++) {
          final sub = item['subItems'][i];
          if (sub is Map) {
            TimelineItem? memItem;
            try {
              memItem = timelineItems.firstWhere((t) => t.title == item['title']);
            } catch (_) {
              memItem = null;
            }
            if (memItem != null) {
              SubItem? memSub;
              try {
                memSub = memItem.subItems.firstWhere((s) => s.subitem == sub['subitem']);
              } catch (_) {
                memSub = null;
              }
              if (memSub != null) {
                sub['completed'] = memSub.completed;
              }
            }
          }
        }
      }
    }
    await file.writeAsString(json.encode(jsonData));
  }
  late List<TimelineItem> timelineItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTimelineData();
  }

  Future<void> loadTimelineData() async {
    final file = File('lib/timeline_data.json');
    final String jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      timelineItems = jsonData.map<TimelineItem>((item) => TimelineItem(
        title: item['title'],
        description: item['description'],
        color: Color(int.parse(item['color'])),
        icon: _iconFromString(item['icon']),
        subItems: TimelineItem.parseSubItems(item['subItems']),
      )).toList();
      isLoading = false;
    });
  }

  IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'flag':
        return Icons.flag;
      case 'sync':
        return Icons.sync;
      case 'edit':
        return Icons.edit;
      case 'trending_up':
        return Icons.trending_up;
      case 'people':
        return Icons.people;
      case 'access_time':
        return Icons.access_time;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  void _openAdminScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AdminScreen(onSave: () => loadTimelineData())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'TO DO projeto',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 238, 95, 0),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openAdminScreen,
            tooltip: 'Administração',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: timelineItems.length,
              itemBuilder: (context, index) {
                return TimelineItemWidget(
                  item: timelineItems[index],
                  itemNumber: index + 1,
                  isLast: index == timelineItems.length - 1,
                  onToggle: () {
                    setState(() {
                      final item = timelineItems[index];
                      item.isCompleted = !item.isCompleted;
                      for (final sub in item.subItems) {
                        sub.completed = item.isCompleted;
                      }
                    });
                  },
                  onSubItemToggle: (subIndex) async {
                    setState(() {
                      final item = timelineItems[index];
                      item.subItems[subIndex].completed = !item.subItems[subIndex].completed;
                      item.updateCompletion();
                    });
                    await saveSubItemsCompletedToJson();
                  },
                );
              }
            )
      );
  }
}
