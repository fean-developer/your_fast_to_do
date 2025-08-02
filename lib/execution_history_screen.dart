import 'package:flutter/material.dart';
import 'package:your_fast_to_do/dashboard_screen.dart';
import 'timeline_item.dart';
import 'timeline_screen.dart';

class ExecutionHistoryScreen extends StatelessWidget {
  final SubItem subItem;
  const ExecutionHistoryScreen({super.key, required this.subItem});

  @override
  Widget build(BuildContext context) {
    final timers = subItem.timers;
    // Agrupa execuções por data
    final Map<String, List<TimerEntry>> grouped = {};
    for (final t in timers) {
      final key = '${t.start.day.toString().padLeft(2, '0')}/${t.start.month.toString().padLeft(2, '0')}/${t.start.year}';
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Execução', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 243, 121, 6),
        foregroundColor: const Color.fromARGB(255, 252, 252, 252),
        
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.white),
            tooltip: 'Voltar para Dashboard',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => DashboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.task, color: Colors.white),
            tooltip: 'Voltar para To Do',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => TimelineScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: timers.isEmpty
          ? const Center(child: Text('Nenhuma execução registrada.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.keys.length,
              itemBuilder: (context, groupIdx) {
                final dateKey = grouped.keys.elementAt(groupIdx);
                final entries = grouped[dateKey]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(dateKey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                    ),
                    ...entries.map((t) {
                      final duration = t.end.difference(t.start);
                      return Card(
                        elevation: 0,
                        color: Colors.blue[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.play_arrow, color: Colors.green, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Início às ${_formatTime(t.start)}', style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.stop, color: Colors.red, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Fim às ${_formatTime(t.end)}', style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.timer, color: Colors.blue, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Duração: ${_formatDurationFull(duration)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
    );
  }

  String _formatTime(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}:${twoDigits(dt.second)}';
  }

  String _formatDurationFull(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String result = '';
    if (h > 0) result += '${h} hora${h > 1 ? 's' : ''} ';
    if (m > 0) result += '${m} minuto${m > 1 ? 's' : ''} ';
    if (s > 0 || result.isEmpty) result += '${s} segundo${s > 1 ? 's' : ''}';
    return result.trim();
  }
}
