import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadAndSummarizePage extends StatefulWidget {
  final Function(String) onSummaryReady;
  const UploadAndSummarizePage({Key? key, required this.onSummaryReady}) : super(key: key);

  @override
  State<UploadAndSummarizePage> createState() => _UploadAndSummarizePageState();
}

class _UploadAndSummarizePageState extends State<UploadAndSummarizePage> {
  File? _selectedFile;
  String _language = 'vi';
  bool _loading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
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
      Uri.parse('https://aidocvn.xyz/summarize/'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));
    request.fields['language'] = _language;

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        final summary = data['summary'] ?? '';
        if (!mounted) return;
        widget.onSummaryReady(summary);
        Navigator.pop(context); // Đóng trang upload sau khi tóm tắt xong
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tóm tắt thất bại!')), 
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi mạng: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tải lên và tóm tắt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _pickFile,
              child: const Text('Chọn file'),
            ),
            const SizedBox(height: 12),
            if (_selectedFile != null)
              Text('File đã chọn: ${_selectedFile!.path.split(Platform.pathSeparator).last}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_selectedFile != null && !_loading) ? _summarize : null,
              child: _loading ? const CircularProgressIndicator() : const Text('Tóm tắt'),
            ),
          ],
        ),
      ),
    );
  }
}
