import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class SummarizePage extends StatefulWidget {
  const SummarizePage({super.key});

  @override
  State<SummarizePage> createState() => _SummarizePageState();
}

class _SummarizePageState extends State<SummarizePage> {
  String _summary = '';
  bool _loading = false;
  String? _fileName;

  Future<void> _pickAndUpload() async {
    setState(() {
      _loading = true;
      _summary = '';
    });
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result == null) {
      setState(() => _loading = false);
      return;
    }
    final file = File(result.files.single.path!);
    _fileName = result.files.single.name;
    final uri = Uri.parse('http://127.0.0.1:8080/summarize');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final resp = await request.send();
    if (resp.statusCode == 200) {
      final body = await resp.stream.bytesToString();
      final data = jsonDecode(body);
      setState(() {
        _summary = data['summary'];
        _loading = false;
      });
      // TODO: Save history
    } else {
      setState(() {
        _summary = 'Error: ${resp.statusCode}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tóm tắt tài liệu',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(
                _loading ? 'Đang xử lý...' : 'Chọn file & Tóm tắt',
              ),
              onPressed: _loading ? null : _pickAndUpload,
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Text(
                'File: $_fileName',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _summary.isEmpty
                      ? const Center(child: Text('Chưa có nội dung'))
                      : SingleChildScrollView(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_summary),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}