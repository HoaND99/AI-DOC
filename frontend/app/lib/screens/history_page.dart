import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Đây chỉ là template, bạn thay bằng code đọc từ SharedPreferences/history thực tế
    final List<String> summaries = [
      'Tóm tắt 1 ...',
      'Tóm tắt 2 ...'
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử tóm tắt')),
      body: ListView.builder(
        itemCount: summaries.length,
        itemBuilder: (context, index) => ListTile(
          title: Text('Summary ${index + 1}'),
          subtitle: Text(summaries[index]),
        ),
      ),
    );
  }
}
