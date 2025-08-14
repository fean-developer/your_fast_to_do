// Chart: total time spent per day in current month
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:your_fast_to_do/admin_screen.dart';
import 'package:your_fast_to_do/float_button.dart';
import 'timeline_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Utilitário para leitura/escrita do JSON
Future<String> loadTimelineJson() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/timeline_data.json');
  if (await file.exists()) {
    return await file.readAsString();
  } else {
    // Fallback para asset se não existir
    return await rootBundle.loadString('lib/timeline_data.json');
  }
}

Future<void> saveTimelineJson(String jsonString) async {
  if (kIsWeb) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timeline_data', jsonString);
  } else {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/timeline_data.json');
    await file.writeAsString(jsonString);
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h}h ${m}m ${s}s';
  }

  Widget _timePerformanceChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: FutureBuilder<String>(
            future: loadTimelineJson(),
            builder: (context, snapshot) {
              Map<int, int> secondsPerDay = {};
              final now = DateTime.now();
              if (snapshot.hasData) {
                final List<dynamic> data = json.decode(snapshot.data!);
                for (final topic in data) {
                  final subItems = topic['subItems'] as List;
                  for (final sub in subItems) {
                    if (sub is Map && sub['timers'] is List) {
                      for (final t in sub['timers']) {
                        if (t['start'] != null && t['end'] != null) {
                          final start = DateTime.tryParse(
                            t['start'].toString(),
                          );
                          final end = DateTime.tryParse(t['end'].toString());
                          if (start != null &&
                              end != null &&
                              end.month == now.month &&
                              end.year == now.year) {
                            final seconds = end.difference(start).inSeconds;
                            secondsPerDay[end.day] =
                                (secondsPerDay[end.day] ?? 0) + seconds;
                          }
                        }
                      }
                    }
                  }
                }
              }
              List<FlSpot> spots = [];
              for (int d = 1; d <= 31; d++) {
                spots.add(FlSpot(d.toDouble(), (secondsPerDay[d] ?? 0) / 60.0));
              }
              double maxY = 0;
              if (spots.isNotEmpty) {
                maxY =
                    spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 10;
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Colors.grey[200], strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 5,
                        getTitlesWidget: (v, meta) {
                          return Text(
                            '${v.toInt()} min',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 5,
                        getTitlesWidget: (v, meta) {
                          if (v % 5 == 0) {
                            return Text(
                              '${v.toInt()}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (value) {
                        return const Color.fromARGB(255, 0, 255, 234);
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color.fromARGB(255, 58, 66, 183),
                      barWidth: 4,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.deepPurple.withOpacity(0.18),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxY,
                ),
              );
            },
          ),
        );
      },
    );
  }

  int totalTasks = 0;
  int totalSubItems = 0;
  int completedTasks = 0;
  int inProgressTasks = 0;
  int notStartedTasks = 0;
  Duration totalTimeSpent = Duration.zero;
  Duration avgTimePerTask = Duration.zero;
  bool isLoading = true;
  int completedThisMonth = 0;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final String jsonString = await loadTimelineJson();
    final List<dynamic> data = json.decode(jsonString);
    int subItemsCount = 0;
    int completed = 0;
    int inProgress = 0;
    int notStarted = 0;
    Duration totalSpent = Duration.zero;
    int tasksWithTime = 0;
    final now = DateTime.now();
    int completedMonth = 0;
    List<DateTime> allStarts = [];
    List<DateTime> allEnds = [];
    for (final topic in data) {
      final subItems = topic['subItems'] as List;
      subItemsCount += subItems.length;
      bool allCompleted = true;
      bool anyStarted = false;
      for (final sub in subItems) {
        final isCompleted = sub is Map && (sub['completed'] == true);
        final timers = sub is Map && sub['timers'] is List
            ? sub['timers'] as List
            : [];
        if (timers.isNotEmpty) {
          anyStarted = true;
          for (final t in timers) {
            if (t['start'] != null && t['end'] != null) {
              final start = DateTime.tryParse(t['start'].toString());
              final end = DateTime.tryParse(t['end'].toString());
              if (start != null && end != null) {
                totalSpent += end.difference(start);
                tasksWithTime++;
                allStarts.add(start);
                allEnds.add(end);
                if (end.month == now.month && end.year == now.year) {
                  completedMonth++;
                }
              }
            }
          }
        }
        if (!isCompleted) {
          allCompleted = false;
        }
      }
      if (allCompleted && subItems.isNotEmpty) {
        completed++;
      } else if (anyStarted) {
        inProgress++;
      } else {
        notStarted++;
      }
    }
    allStarts.sort();
    allEnds.sort();
    setState(() {
      startDate = allStarts.isNotEmpty ? allStarts.first : null;
      endDate = allEnds.isNotEmpty ? allEnds.last : null;
      totalTasks = data.length;
      totalSubItems = subItemsCount;
      completedTasks = completed;
      inProgressTasks = inProgress;
      notStartedTasks = notStarted;
      totalTimeSpent = totalSpent;
      avgTimePerTask = tasksWithTime > 0
          ? Duration(seconds: totalSpent.inSeconds ~/ tasksWithTime)
          : Duration.zero;
      completedThisMonth = completedMonth;
      isLoading = false;
    });
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return '${_monthName(dt.month)} ${dt.day < 10 ? '0' : ''}${dt.day} ${dt.year}';
  }

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 250, 121, 0),
        foregroundColor: const Color.fromARGB(255, 252, 252, 252),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _modernStatCard(
                                'Total Tasks',
                                totalTasks,
                                Icons.list_alt,
                                Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: _modernStatCard(
                                'Completed',
                                completedTasks,
                                Icons.check_circle,
                                Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: _modernStatCard(
                                'In Progress',
                                inProgressTasks,
                                Icons.timelapse,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: _modernStatCard(
                                'Not Started',
                                notStartedTasks,
                                Icons.hourglass_empty,
                                Colors.redAccent,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _modernStatCard(
                                'Total Tasks',
                                totalTasks,
                                Icons.list_alt,
                                Colors.deepPurple,
                              ),
                            ),
                            Expanded(
                              child: _modernStatCard(
                                'Completed',
                                completedTasks,
                                Icons.check_circle,
                                Colors.teal,
                              ),
                            ),
                            Expanded(
                              child: _modernStatCard(
                                'In Progress',
                                inProgressTasks,
                                Icons.timelapse,
                                Colors.orange,
                              ),
                            ),
                            Expanded(
                              child: _modernStatCard(
                                'Not Started',
                                notStartedTasks,
                                Icons.hourglass_empty,
                                Colors.redAccent,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Status Mensal',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Este mês',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            completedThisMonth.toString(),
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 120,
                                        child: _fakeLineChart(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Tasks Available',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 170,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            PieChart(
                                              PieChartData(
                                                startDegreeOffset: 180,
                                                sectionsSpace: 0,
                                                centerSpaceRadius: 64,
                                                sections: [
                                                  PieChartSectionData(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      245,
                                                      105,
                                                      12,
                                                    ),
                                                    value: completedTasks
                                                        .toDouble(),
                                                    title: '',
                                                    radius: 20,
                                                  ),
                                                  PieChartSectionData(
                                                    color: Colors.grey[300],
                                                    value:
                                                        ((totalTasks -
                                                                completedTasks)
                                                            .toDouble()),
                                                    title: '',
                                                    radius: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${((completedTasks / (totalTasks == 0 ? 1 : totalTasks)) * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 32,
                                                    color: const Color.fromARGB(
                                                      255,
                                                      245,
                                                      105,
                                                      12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Start Date',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(startDate),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'End Date',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(endDate),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Status Mensal',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Este mês',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            completedThisMonth.toString(),
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 120,
                                        child: _fakeLineChart(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Tasks Available',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 170,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            PieChart(
                                              PieChartData(
                                                startDegreeOffset: 180,
                                                sectionsSpace: 0,
                                                centerSpaceRadius: 64,
                                                sections: [
                                                  PieChartSectionData(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      245,
                                                      105,
                                                      12,
                                                    ),
                                                    value: completedTasks
                                                        .toDouble(),
                                                    title: '',
                                                    radius: 20,
                                                  ),
                                                  PieChartSectionData(
                                                    color: Colors.grey[300],
                                                    value:
                                                        ((totalTasks -
                                                                completedTasks)
                                                            .toDouble()),
                                                    title: '',
                                                    radius: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${((completedTasks / (totalTasks == 0 ? 1 : totalTasks)) * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 32,
                                                    color: const Color.fromARGB(
                                                      255,
                                                      245,
                                                      105,
                                                      12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Start Date',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(startDate),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'End Date',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(endDate),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Gestão do Tempo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDuration(totalTimeSpent),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tempo médio por tarefa: ${_formatDuration(avgTimePerTask)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(height: 180, child: _timePerformanceChart()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // FloatMenuButton flutuando no canto inferior direito
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminScreen(onSave: _loadStats),
            ),
          ).then((_) {
            // Recarregar os dados após voltar da tela de administração
            _loadStats();
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Item',
        backgroundColor: Color.fromARGB(255, 250, 121, 0),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 250, 121, 0),
        notchMargin: 5,
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.timeline, size: 24,color: Colors.white,),
              onPressed: () {
                // Navegar para a tela de timeline
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TimelineScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.admin_panel_settings, size: 24, color: Colors.white),
              onPressed: () {
                // Navegar para a tela de administração
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminScreen(onSave: _loadStats),
                  ),
                ).then((_) {
                  // Recarregar os dados após voltar da tela de administração
                  _loadStats();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernStatCard(String label, int value, IconData icon, Color color) {
    return SizedBox(
      width: 220,
      height: 150,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        value.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: color,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        label,
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fakeLineChart() {
    // Gráfico de linha real: evolução de tarefas concluídas por dia do mês
    // Agrupa por dia do mês
    return FutureBuilder<String>(
      future: loadTimelineJson(),
      builder: (context, snapshot) {
        Map<int, int> completedPerDay = {};
        final now = DateTime.now();
        if (snapshot.hasData) {
          final List<dynamic> data = json.decode(snapshot.data!);
          for (final topic in data) {
            final subItems = topic['subItems'] as List;
            for (final sub in subItems) {
              if (sub is Map && sub['timers'] is List) {
                for (final t in sub['timers']) {
                  if (t['end'] != null) {
                    final end = DateTime.tryParse(t['end'].toString());
                    if (end != null &&
                        end.month == now.month &&
                        end.year == now.year) {
                      completedPerDay[end.day] =
                          (completedPerDay[end.day] ?? 0) + 1;
                    }
                  }
                }
              }
            }
          }
        }
        List<FlSpot> spots = [];
        for (int d = 1; d <= 31; d++) {
          spots.add(FlSpot(d.toDouble(), (completedPerDay[d] ?? 0).toDouble()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 28),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 28),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blueAccent,
                barWidth: 4,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blueAccent.withOpacity(0.2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
