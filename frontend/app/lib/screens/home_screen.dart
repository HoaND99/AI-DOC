import 'package:flutter/material.dart';
import 'upload_and_summarize_page.dart';
import 'summarize_page.dart';
import 'history_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _onSummaryReady(String summary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummarizePage(summary: summary),
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tóm tắt tài liệu AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Tải file lên và tóm tắt'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UploadAndSummarizePage(
                  onSummaryReady: _onSummaryReady,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
