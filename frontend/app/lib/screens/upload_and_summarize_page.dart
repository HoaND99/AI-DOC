import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UploadAndSummarizePage extends StatefulWidget {
  final String selectedLanguage;

  const UploadAndSummarizePage({Key? key, required this.selectedLanguage}) : super(key: key);

  @override
  State<UploadAndSummarizePage> createState() => _UploadAndSummarizePageState();
}

class _UploadAndSummarizePageState extends State<UploadAndSummarizePage> {
  late String _currentLanguage;
  String summaryText = "";
  bool isLoading = false;
  XFile? pickedImage;
  PlatformFile? pickedFile;
  String? apiUrl = 'https://aidocvn.xyz/summarize/';
  String? exportUrl = 'https://aidocvn.xyz/export-summary/';

  final Map<String, String> languageMap = {
    'English': 'en',
    'Vietnamese': 'vi',
    'French': 'fr',
    'Chinese': 'zh',
    'Japanese': 'ja',
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.selectedLanguage;
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        pickedImage = photo;
        pickedFile = null;
      });
    }
  }

  Future<void> _pickGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        pickedImage = image;
        pickedFile = null;
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        pickedFile = result.files.first;
        pickedImage = null;
      });
    }
  }

  Future<void> _summarize() async {
    setState(() {
      isLoading = true;
      summaryText = "";
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl!));
      request.fields['language'] = languageMap[_currentLanguage] ?? 'en';

      if (pickedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('file', pickedImage!.path));
      } else if (pickedFile != null && pickedFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath('file', pickedFile!.path!));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn file tài liệu hoặc ảnh!")),
        );
        setState(() => isLoading = false);
        return;
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          summaryText = data['summary'] ?? "";
          isLoading = false;
        });
        _saveToHistory(summaryText);
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tóm tắt thất bại! Chi tiết: ${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Có lỗi xảy ra: $e")),
      );
    }
  }

  Future<void> _saveToHistory(String summary) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    final entry = jsonEncode({
      'summary': summary,
      'datetime': DateTime.now().toIso8601String(),
    });
    history.add(entry);
    await prefs.setStringList('history', history);
  }

  Future<void> _copySummary() async {
    await Clipboard.setData(ClipboardData(text: summaryText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Đã sao chép")));
  }

  Future<void> _shareSummary() async {
    await Share.share(summaryText, subject: 'Tóm tắt tài liệu');
  }

  Future<void> _downloadSummary(String format) async {
    if (summaryText.isEmpty) return;

    try {
      var request = http.MultipartRequest('POST', Uri.parse(exportUrl!));
      request.fields['summary'] = summaryText;
      request.fields['export_format'] = format;

      var streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final bytes = await streamedResponse.stream.toBytes();
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/summary.$format';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        await OpenFile.open(filePath);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tải file thất bại!")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      children: [
        if (summaryText.isNotEmpty || isLoading)
          Card(
            margin: const EdgeInsets.only(bottom: 18, top: 12),
            color: Theme.of(context).cardTheme.color,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("KẾT QUẢ TÓM TẮT",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 12),
                        Text(summaryText),
                        const Divider(),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.copy), onPressed: _copySummary),
                            IconButton(icon: const Icon(Icons.share), onPressed: _shareSummary),
                            IconButton(
                              icon: const Icon(Icons.download),
                              tooltip: "Tải về DOCX",
                              onPressed: () => _downloadSummary('docx'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_outlined),
                              tooltip: "Tải về TXT",
                              onPressed: () => _downloadSummary('txt'),
                            ),
                          ],
                        )
                      ],
                    ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt, size: 32, color: Colors.blue),
              tooltip: "Chụp ảnh",
              onPressed: Platform.isAndroid || Platform.isIOS ? _pickCamera : null,
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.image, size: 32, color: Colors.green),
              tooltip: "Chọn ảnh từ thư viện",
              onPressed: _pickGallery,
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.insert_drive_file, size: 32, color: Colors.deepPurple),
              tooltip: "Chọn file tài liệu",
              onPressed: _pickDocument,
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _currentLanguage,
          items: const [
            'English',
            'Vietnamese',
            'French',
            'Chinese',
            'Japanese',
          ].map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
          decoration: InputDecoration(
            labelText: "Ngôn ngữ tóm tắt",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _currentLanguage = val;
                summaryText = "";
              });
            }
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.summarize),
          label: const Text("Tóm tắt"),
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size(120, 50),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: isLoading ? null : _summarize,
        ),
      ],
    );
  }
}
