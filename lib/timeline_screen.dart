import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
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

 Future<File> _getTimelineFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/timeline_data.json');
    if (!await file.exists()) {
      // Copia dos assets se não existir
      final assetData = await DefaultAssetBundle.of(context).loadString('lib/timeline_data.json');
      await file.writeAsString(assetData);
    }
    return file;
  }

  Future<void> saveSubItemsCompletedToJson() async {
    final file = await _getTimelineFile();
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
    final file = await _getTimelineFile();
    final String jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      timelineItems = jsonData.map<TimelineItem>((item) {
        final timelineItem = TimelineItem(
          title: item['title'],
          description: item['description'],
          color: Color(int.parse(item['color'])),
          icon: _iconFromString(item['icon']),
          subItems: TimelineItem.parseSubItems(item['subItems']),
        );
        timelineItem.updateCompletion();
        return timelineItem;
      }).toList();
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
        title: const Text('To Do', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 250, 121, 0),
        foregroundColor: const Color.fromARGB(255, 252, 252, 252),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.white),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
              // Força reload ao voltar do dashboard
              loadTimelineData();
            },
            tooltip: 'Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
                  onReload: () async {
                    await loadTimelineData();
                  },
                );
              },
            ),
    );
  }
}
