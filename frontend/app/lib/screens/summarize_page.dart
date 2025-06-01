import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class SummarizePage extends StatefulWidget {
  final String summary;
  const SummarizePage({super.key, required this.summary});

  @override
  _SummarizePageState createState() => _SummarizePageState();
}

class _SummarizePageState extends State<SummarizePage> {
  bool _downloading = false;

  Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return null;
    }
  }

  Future<void> downloadSummaryFile({
    required String summary,
    required String exportFormat,
    String apiUrl = "https://doc-summarizer-103815638383.us-central1.run.app/export-summary/",
  }) async {
    setState(() {
      _downloading = true;
    });

    try {
      // Lấy thông tin Android version
      int sdkInt = 0;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        sdkInt = androidInfo.version.sdkInt ?? 0;
      }

      // Chỉ xin quyền storage nếu Android < 11 (API < 30)
      if (Platform.isAndroid && sdkInt < 30) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần cấp quyền lưu file để tải về.')),
          );
          setState(() => _downloading = false);
          return;
        }
      }

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['summary'] = summary;
      request.fields['export_format'] = exportFormat;

      var response = await request.send();
      if (response.statusCode == 200) {
        String filename = "summary.$exportFormat";
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null && contentDisposition.contains('filename=')) {
          filename = contentDisposition.split('filename=')[1].replaceAll('"', '').trim();
        }

        final downloadsDirectory = await _getDownloadDirectory();
        if (downloadsDirectory == null) {
          throw Exception("Không tìm thấy thư mục lưu file.");
        }
        final file = File('${downloadsDirectory.path}/$filename');
        await response.stream.pipe(file.openWrite());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu: ${file.path}'),
            action: SnackBarAction(
              label: 'Mở',
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );

        // Gợi ý chia sẻ file ra ngoài
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Chia sẻ file"),
            content: Text("Bạn muốn chia sẻ file này ra ngoài không?\n\nĐường dẫn:\n${file.path}"),
            actions: [
              TextButton(
                onPressed: () {
                  Share.shareXFiles([XFile(file.path)], text: 'Tóm tắt tài liệu của bạn!');
                  Navigator.pop(ctx);
                },
                child: const Text("Chia sẻ"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Đóng"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải file (status ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải file: $e')),
      );
    }

    setState(() {
      _downloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryText = widget.summary;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kết quả tóm tắt"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: summaryText.isEmpty
            ? const Center(child: Text("Không có nội dung tóm tắt"))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Kết quả tóm tắt:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: TextFormField(
                        initialValue: summaryText,
                        maxLines: null,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _downloading
                            ? null
                            : () => downloadSummaryFile(
                                  summary: summaryText,
                                  exportFormat: "docx",
                                ),
                        icon: const Icon(Icons.download),
                        label: const Text("Tải về .docx"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _downloading
                            ? null
                            : () => downloadSummaryFile(
                                  summary: summaryText,
                                  exportFormat: "txt",
                                ),
                        icon: const Icon(Icons.download),
                        label: const Text("Tải về .txt"),
                      ),
                    ],
                  ),
                  if (_downloading) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
      ),
    );
  }
}
