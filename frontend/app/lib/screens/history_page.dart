import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatefulWidget {
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('history') ?? [];
    setState(() {
      history = items
          .map((e) => Map<String, dynamic>.from(jsonDecode(e)))
          .toList()
          .reversed
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(child: Text("Chưa có lịch sử tóm tắt nào."));
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, idx) {
        final item = history[idx];
        return Card(
          margin: EdgeInsets.only(bottom: 14),
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            title: Text(item["datetime"] ?? "",
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item["summary"] ?? "",
                maxLines: 3, overflow: TextOverflow.ellipsis),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        title: Text("Tóm tắt"),
                        content: Text(item["summary"] ?? ""),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Đóng"))
                        ],
                      ));
            },
          ),
        );
      },
    );
  }
}
