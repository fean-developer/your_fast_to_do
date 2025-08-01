import 'package:flutter/material.dart';
import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

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
    final file = File('lib/timeline_data.json');
    final String jsonString = await file.readAsString();
    setState(() {
      data = json.decode(jsonString);
      isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final file = File('lib/timeline_data.json');
    await file.writeAsString(json.encode(data));
    widget.onSave();
    if (mounted) Navigator.of(context).pop();
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
        title: const Text('Administração do TO DO'),
        backgroundColor: const Color.fromARGB(255, 238, 95, 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveData,
            tooltip: 'Salvar',
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
                              initialValue: topic["subItems"][subIndex],
                              decoration: InputDecoration(labelText: 'Subitem ${subIndex + 1}'),
                              onChanged: (v) => topic["subItems"][subIndex] = v,
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
