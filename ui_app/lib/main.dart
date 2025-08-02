import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DINOv2 Search',
      debugShowCheckedModeBanner: false,
      home: const UploadPage(),
    );
  }
}

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  Uint8List? _imageBytes;
  List<String> _resultImages = [];
  bool _loading = false;

  Future<void> _pickImageAndSend() async {
    setState(() {
      _resultImages = [];
      _loading = true;
    });

    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((_) async {
      final file = input.files!.first;
      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final data = reader.result as Uint8List;
      setState(() => _imageBytes = data);

      final uri = Uri.parse('http://127.0.0.1:8000/search');

      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          data,
          filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final decoded = jsonDecode(body);

      final imagePaths = (decoded['results'] as List)
          .map<String>((e) => e['image_path'] as String)
          .toList();

      setState(() {
        _resultImages = imagePaths;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔍 DINOv2 Image Search')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _pickImageAndSend,
                icon: const Icon(Icons.image_search),
                label: const Text('Chọn ảnh & tìm kiếm'),
              ),
              const SizedBox(height: 16),
              if (_imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_imageBytes!, height: 200),
                ),
              const SizedBox(height: 20),
              if (_loading) const CircularProgressIndicator(),
              if (_resultImages.isNotEmpty) ...[
                const Text('Ảnh tương tự:', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _resultImages.map((path) {
                    final fullUrl = 'http://127.0.0.1:8000/images/$path';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(fullUrl, height: 150),
                    );
                  }).toList(),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}
