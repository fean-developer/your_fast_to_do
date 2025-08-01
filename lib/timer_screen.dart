import 'package:flutter/material.dart';
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
    if (mounted) Navigator.of(context).pop();
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
    final file = File('lib/timeline_data.json');
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
            if (markCompleted) {
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
      appBar: AppBar(
        title: Text(widget.subItem.subitem),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _tick,
                      builder: (context, _, __) {
                        final total = _totalElapsed();
                        final percent = (total.inSeconds % 3600) / 3600;
                        return CustomPaint(
                          size: const Size(180, 180),
                          painter: TimerCirclePainter(percent: percent),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: Center(
                        child: ValueListenableBuilder<int>(
                          valueListenable: _tick,
                          builder: (context, _, __) => Text(
                            _formatDuration(_totalElapsed()),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isRunning ? _pause : _start,
                  child: Text(isRunning ? 'Pausar' : 'Iniciar'),
                ),
                const SizedBox(width: 16),
                if (!isRunning && timers.isNotEmpty)
                  ElevatedButton(
                    onPressed: _resume,
                    child: const Text('Continuar'),
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _stopAndComplete,
                  child: const Text('Parar'),
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
              child: ListView.builder(
                itemCount: timers.length,
                itemBuilder: (context, idx) {
                  final t = timers[idx];
                  return ListTile(
                    leading: Icon(Icons.timer),
                    title: Text(
                      '${t.start.toLocal().toString().substring(0, 19)} - ${t.end.toLocal().toString().substring(0, 19)}',
                    ),
                    subtitle: Text('Duração: ${_formatDuration(t.end.difference(t.start))}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
