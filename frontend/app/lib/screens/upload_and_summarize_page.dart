import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Hàm lưu lịch sử tóm tắt
Future<void> saveHistory(String fileName, String summary) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now().toIso8601String();
  final entry = {
    'file': fileName,
    'summary': summary,
    'time': now,
  };
  final list = prefs.getStringList('history') ?? [];
  list.add(jsonEncode(entry));
  await prefs.setStringList('history', list);
}

class UploadAndSummarizePage extends StatefulWidget {
  final Function(String) onSummaryReady;
  const UploadAndSummarizePage({super.key, required this.onSummaryReady});

  @override
  State<UploadAndSummarizePage> createState() => _UploadAndSummarizePageState();
}

class _UploadAndSummarizePageState extends State<UploadAndSummarizePage> {
  File? _selectedFile;
  String _language = "vi";
  bool _loading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _summarize() async {
    if (_selectedFile == null) return;
    setState(() {
      _loading = true;
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://doc-summarizer-103815638383.us-central1.run.app/summarize/'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));
    request.fields['language'] = _language;

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        final summary = data['summary'] ?? '';
        // Lưu lịch sử trước khi chuyển màn hình
        await saveHistory(_selectedFile?.path?.split("/")?.last ?? "", summary);
        widget.onSummaryReady(summary);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: Không thể tóm tắt tài liệu (status ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi mạng: $e')),
      );
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tóm tắt tài liệu")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(_selectedFile == null ? "Chọn file" : "Đổi file"),
              onPressed: _pickFile,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Ngôn ngữ tóm tắt:"),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _language,
                  items: const [
                    DropdownMenuItem(value: "vi", child: Text("Tiếng Việt")),
                    DropdownMenuItem(value: "en", child: Text("English")),
                    DropdownMenuItem(value: "fr", child: Text("Français")),
                    DropdownMenuItem(value: "zh", child: Text("中文")),
                    DropdownMenuItem(value: "ja", child: Text("日本語")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _language = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_selectedFile != null && !_loading) ? _summarize : null,
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
                  : const Text("Tóm tắt"),
            ),
          ],
        ),
      ),
    );
  }
}
