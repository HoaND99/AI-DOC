import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('history') ?? [];
    final result = list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    setState(() {
      _history = result.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử tóm tắt')),
      body: _history.isEmpty
          ? const Center(child: Text("Chưa có lịch sử"))
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return ListTile(
                  title: Text(item['file'] ?? 'File'),
                  subtitle: Text(item['summary'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(item['time']?.substring(0, 19).replaceAll('T', ' ') ?? ''),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(item['file'] ?? 'File'),
                        content: SingleChildScrollView(child: Text(item['summary'] ?? '')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
