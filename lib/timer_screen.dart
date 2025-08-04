import 'package:flutter/material.dart';
import 'package:your_fast_to_do/components/custom_app_bar.dart';
import 'dashboard_screen.dart';
import 'timeline_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'timeline_item.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';


class TimerCirclePainter extends CustomPainter {
  final double percent;
  TimerCirclePainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final fgPaint = Paint()
      ..shader = LinearGradient(colors: [Colors.purple, Colors.blue]).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Background circle
    canvas.drawCircle(center, radius, bgPaint);
    // Foreground arc
    final sweep = 2 * math.pi * percent;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi/2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TimerScreen extends StatefulWidget {
  final SubItem subItem;
  final VoidCallback onSave;
  const TimerScreen({super.key, required this.subItem, required this.onSave});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Future<File> _getTimelineFile() async {
    final dir = await getApplicationDocumentsDirectory();
    print('📦 Caminho dos documentos: ${dir.path} 📦');
    final file = File('${dir.path}/timeline_data.json');
    if (!await file.exists()) {
      // Copia dos assets se não existir
      final assetData = await DefaultAssetBundle.of(context).loadString('lib/timeline_data.json');
      await file.writeAsString(assetData);
    }
    return file;
  }
  bool _disposed = false;
  Future<void> _stopAndComplete() async {
    if (isRunning && startTime != null) {
      setState(() {
        isRunning = false;
        timers.add(TimerEntry(start: startTime!, end: DateTime.now()));
        startTime = null;
      });
    }
    await _saveTimersToJson(markCompleted: true);
    widget.onSave();
    if (mounted) {
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TimelineScreen()),
        );
      });
    }
  }
  bool isRunning = false;
  DateTime? startTime;
  Duration elapsed = Duration.zero;
  List<TimerEntry> timers = [];
  // Removido campo _ticker, não é necessário
  late final ValueNotifier<int> _tick;
  @override
  void initState() {
    super.initState();
    timers = List.from(widget.subItem.timers);
    _tick = ValueNotifier<int>(0);
    _startTicker();
  }

  void _startTicker() {
    Future.doWhile(() async {
      if (!mounted || _disposed) return false;
      if (isRunning) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted || _disposed) return false;
        _tick.value++;
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      return !(_disposed);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _tick.dispose();
    super.dispose();
  }


  void _start() {
    setState(() {
      isRunning = true;
      startTime = DateTime.now();
    });
    _tick.value++;
  }

  void _pause() async {
    if (isRunning && startTime != null) {
      setState(() {
        isRunning = false;
        timers.add(TimerEntry(start: startTime!, end: DateTime.now()));
        startTime = null;
      });
      await _saveTimersToJson();
      widget.onSave();
      _tick.value++;
    }
  }

  Future<void> _saveTimersToJson({bool markCompleted = false}) async {
    final file = await _getTimelineFile();
    final String jsonString = await file.readAsString();
    final List<dynamic> jsonData = json.decode(jsonString);

    for (final item in jsonData) {
      if (item['subItems'] is List) {
        for (var i = 0; i < (item['subItems'] as List).length; i++) {
          final sub = item['subItems'][i];
          if ((sub is String && sub == widget.subItem.subitem) ||
              (sub is Map && sub['subitem'] == widget.subItem.subitem)) {
            final subMap = {
              'subitem': widget.subItem.subitem,
              'timers': timers.map((t) => t.toJson()).toList(),
            };
            // Se todos os checkboxes estiverem desmarcados (timers vazio), completed = false
            if (timers.isEmpty) {
              subMap['completed'] = false;
            } else if (markCompleted) {
              subMap['completed'] = true;
            } else if (sub is Map && sub.containsKey('completed')) {
              subMap['completed'] = sub['completed'];
            }
            (item['subItems'] as List)[i] = subMap;
          }
        }
      }
    }
    await file.writeAsString(json.encode(jsonData));
  }

  void _resume() {
    setState(() {
      isRunning = true;
      startTime = DateTime.now();
    });
    _tick.value++;
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
  }

  Duration _totalElapsed() {
    Duration total = Duration.zero;
    for (final t in timers) {
      total += t.end.difference(t.start);
    }
    if (isRunning && startTime != null) {
      total += DateTime.now().difference(startTime!);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'To Do'
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 270,
                  height: 270,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _tick,
                        builder: (context, _, __) {
                          final total = _totalElapsed();
                          final percent = (total.inSeconds % 60) / 60;
                          return CustomPaint(
                            size: const Size(270, 270),
                            painter: TimerCirclePainter(percent: percent),
                          );
                        },
                      ),
                      Positioned.fill(
                        child: Center(
                          child: ValueListenableBuilder<int>(
                            valueListenable: _tick,
                            builder: (context, _, __) {
                              final d = _totalElapsed();
                              final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
                              final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
                              final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(min, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  Text(sec, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  Text(ms, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w400)),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.grey.shade500, size: 28),
                    tooltip: 'Resetar',
                    onPressed: () {
                      setState(() {
                        timers.clear();
                        startTime = null;
                        isRunning = false;
                      });
                    },
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: Icon(isRunning ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 32),
                    tooltip: isRunning ? 'Pausar' : 'Iniciar',
                    onPressed: isRunning ? _pause : _start,
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: Icon(Icons.stop, color: Colors.redAccent, size: 32),
                    tooltip: 'Parar',
                    onPressed: _stopAndComplete,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Histórico de execuções:', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: timers.isEmpty
                    ? const Center(child: Text('Nenhuma execução registrada.', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: timers.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[300]),
                        itemBuilder: (context, idx) {
                          final t = timers[idx];
                          final duration = t.end.difference(t.start);
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.timer, color: Colors.blue, size: 20),
                            ),
                            title: Text(
                              _formatDuration(duration),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
