import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

import 'package:window_manager/window_manager.dart';
import 'package:your_fast_to_do/dashboard_screen.dart';
import 'package:your_fast_to_do/timeline_screen.dart';

class AdminScreen extends StatefulWidget {
  final VoidCallback onSave;
  const AdminScreen({super.key, required this.onSave});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/timeline_data.json');
    String jsonString;
    if (await file.exists()) {
      jsonString = await file.readAsString();
    } else {
      // Fallback para asset se não existir
      jsonString = await DefaultAssetBundle.of(context).loadString('lib/timeline_data.json');
    }
    setState(() {
      data = json.decode(jsonString);
      isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/timeline_data.json');
    await file.writeAsString(json.encode(data));
    widget.onSave();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TimelineScreen()),
    );
  }

  void _addTopic() {
    setState(() {
      data.add({
        "title": "Novo Item",
        "description": "Descrição do item",
        "color": "0xFF2B7A78",
        "icon": "flag",
        "subItems": ["Novo subitem"]
      });
    });
  }

  void _removeTopic(int index) {
    setState(() {
      data.removeAt(index);
    });
  }

  void _addSubItem(int topicIndex) {
    setState(() {
      data[topicIndex]["subItems"].add("Novo subitem");
    });
  }

  void _removeSubItem(int topicIndex, int subIndex) {
    setState(() {
      data[topicIndex]["subItems"].removeAt(subIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 250, 121, 0),
        foregroundColor: const Color.fromARGB(255, 252, 252, 252),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveData,
            tooltip: 'Salvar',
          ),
          IconButton(
          icon: const Icon(Icons.dashboard, color: Colors.white),
          tooltip: 'Voltar para Dashboard',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => DashboardScreen()),
            );
          },
        ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTopic,
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Item',
      ),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, topicIndex) {
          final topic = data[topicIndex];
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: topic["title"],
                          decoration: const InputDecoration(labelText: 'Título do Item'),
                          onChanged: (v) => topic["title"] = v,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeTopic(topicIndex),
                        tooltip: 'Remover Item',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Subitens:'),
                  ...List.generate(topic["subItems"].length, (subIndex) => Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: topic["subItems"][subIndex] is String
                                  ? topic["subItems"][subIndex]
                                  : topic["subItems"][subIndex]["subitem"] ?? '',
                              decoration: InputDecoration(labelText: 'Subitem ${subIndex + 1}'),
                              onChanged: (v) {
                                if (topic["subItems"][subIndex] is String) {
                                  topic["subItems"][subIndex] = v;
                                } else if (topic["subItems"][subIndex] is Map) {
                                  topic["subItems"][subIndex]["subitem"] = v;
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSubItem(topicIndex, subIndex),
                            tooltip: 'Remover Subitem',
                          ),
                        ],
                      )),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addSubItem(topicIndex),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Subitem'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
