import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_dropzone_platform_interface/flutter_dropzone_platform_interface.dart'; // Import this for DropzoneFileInterface

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DINOv2 Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: Colors.blueAccent,
          surface: Colors.white,
          onSurface: Colors.black87,
          background: Colors.white,
          onBackground: Colors.black87,
          error: Colors.redAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          centerTitle: true,
          elevation: 4,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.deepPurple,
          inactiveTrackColor: Colors.deepPurple.withOpacity(0.3),
          thumbColor: Colors.deepPurple,
          overlayColor: Colors.deepPurple.withOpacity(0.2),
          valueIndicatorColor: Colors.deepPurple,
          valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
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
  List<SearchResult> _resultImages = [];
  bool _loading = false;
  int _topK = 5;
  // final String serverUrl = "http://localhost:8000"; // http://localhost:8000 run not docker
  final String serverUrl = "";

  late DropzoneViewController dropzoneController;
  bool isDragging = false;
  Key _dropzoneKey = UniqueKey(); // Thêm một Key động

  // Hàm để reset trạng thái và "làm mới" dropzone
  void _resetDropzone() {
    setState(() {
      _imageBytes = null;
      _resultImages = [];
      _loading = false;
      isDragging = false;
      _dropzoneKey = UniqueKey(); // Tạo một Key mới để buộc DropzoneView xây dựng lại
    });
  }

  // Hàm xử lý việc gửi ảnh lên server
  Future<void> _processAndSendImage(Uint8List data, String filename) async {
    setState(() {
      _resultImages = []; // Xóa kết quả cũ
      _loading = true;
      _imageBytes = data; // Cập nhật ảnh truy vấn
    });

    final uri = Uri.parse('$serverUrl/search?k=$_topK');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        data,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(body);
        final searchResults = (decoded['results'] as List)
            .map<SearchResult>((e) => SearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _resultImages = searchResults;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _resultImages = [];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi từ server: ${response.statusCode} - $body'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _resultImages = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      });
    }
  }

  // Hàm xử lý chọn ảnh truyền thống (cho nút "Tải ảnh lên")
  Future<void> _pickImageAndSend() async {
    _resetDropzone(); // Reset dropzone khi chọn ảnh bằng nút
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((_) async {
      final file = input.files!.first;
      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final data = reader.result as Uint8List;
      await _processAndSendImage(data, file.name ?? 'image.jpeg');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DINOv2 Image Similarity Search')),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Tải ảnh lên"),
                    onPressed: _pickImageAndSend, // Đã có reset bên trong hàm
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Số lượng ảnh tương tự (Top K):",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _topK.toDouble(),
                                min: 1,
                                max: 20,
                                divisions: 19,
                                label: _topK.round().toString(),
                                onChanged: (double value) {
                                  setState(() => _topK = value.round());
                                },
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                '$_topK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  if (_imageBytes != null) ...[
                    // Hiển thị ảnh truy vấn
                    Text(
                      "Ảnh truy vấn:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 3,
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          _imageBytes!,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 250,
                              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                              child: Center(
                                child: Icon(Icons.broken_image, size: 60, color: Theme.of(context).colorScheme.error),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Thêm khoảng cách
                    // Nút để reset và cho phép kéo thả ảnh khác
                    FilledButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text("Xóa ảnh và chọn lại"),
                      onPressed: _resetDropzone, // Nút này sẽ gọi hàm reset
                    ),
                  ] else ...[
                    // Vùng kéo thả khi chưa có ảnh
                    Stack(
                      children: [
                        Positioned.fill(
                          child: DropzoneView(
                            key: _dropzoneKey, // Gán key động vào DropzoneView
                            operation: DragOperation.copy,
                            cursor: CursorType.grab,
                            onCreated: (ctrl) => dropzoneController = ctrl,
                            onHover: () {
                              setState(() => isDragging = true);
                            },
                            onLeave: () {
                              setState(() => isDragging = false);
                            },
                            mime: const ['image/jpeg', 'image/png', 'image/gif', 'image/bmp', 'image/webp'],
                            onDrop: (dynamic file) async {
                              setState(() => isDragging = false);
                              // Ngay lập tức reset dropzone khi có file được thả
                              // Điều này đảm bảo dropzone sẵn sàng cho lần kéo thả tiếp theo
                              _resetDropzone();

                              if (file is DropzoneFileInterface) {
                                if (file.size > 0) {
                                  final bytes = await dropzoneController.getFileData(file);
                                  final filename = file.name;
                                  await _processAndSendImage(bytes, filename ?? 'image.jpeg');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tệp ảnh không có dữ liệu (kích thước 0 byte).'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } else if (file is html.File) {
                                if (file.type.startsWith('image/')) {
                                  if (file.size > 0) {
                                    final reader = html.FileReader();
                                    reader.readAsArrayBuffer(file);
                                    await reader.onLoad.first;
                                    final bytes = reader.result as Uint8List;
                                    await _processAndSendImage(bytes, file.name ?? 'image.jpeg');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Tệp ảnh không có dữ liệu (kích thước 0 byte).'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                      content: Text('Vui lòng kéo thả một tệp ảnh hợp lệ (JPEG, PNG, GIF, BMP, WebP).'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                    content: Text('Định dạng kéo thả không hợp lệ. Vui lòng kéo thả một tệp ảnh.'),
                                    backgroundColor:Theme.of(context).colorScheme.error,
                                  ),
                                );
                              }
                            },
                            onError: (ev) {
                              print('Dropzone Error: $ev');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi kéo thả: $ev'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            },
                          ),
                        ),
                        DottedBorder(
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(15),
                          padding: EdgeInsets.zero,
                          color: isDragging
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          strokeWidth: 2,
                          dashPattern: const [8, 4],
                          child: Container(
                            height: 250,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDragging
                                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                                  : Theme.of(context).colorScheme.surface.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isDragging ? Icons.cloud_upload : Icons.photo_library_outlined,
                                  size: 70,
                                  color: isDragging
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isDragging ? "Thả ảnh vào đây để tải lên" : "Kéo ảnh vào đây hoặc chọn ảnh",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDragging
                                        ? Theme.of(context).colorScheme.secondary
                                        : Theme.of(context).colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            VerticalDivider(
                width: 48,
                thickness: 1.5,
                indent: 10,
                endIndent: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            Expanded(
              child: _loading
                  ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              )
                  : _resultImages.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_search, size: 90, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                    const SizedBox(height: 18),
                    Text(
                      "Chưa có kết quả nào được tìm thấy.",
                      style: TextStyle(fontSize: 19, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Hãy chọn một ảnh để bắt đầu tìm kiếm!",
                      style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1,
                ),
                itemCount: _resultImages.length,
                itemBuilder: (context, index) {
                  final result = _resultImages[index]; // Lấy đối tượng SearchResult
                  final fullUrl = '$serverUrl/images/${result.imagePath}'; // Lấy imagePath từ result

                  return Card( // Sử dụng Card để có shadow và bo góc tốt hơn
                    elevation: 5, // Độ nổi của card
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Bo góc cho card
                    ),
                    clipBehavior: Clip.antiAlias, // Quan trọng để bo góc ảnh bên trong card
                    child: Stack( // Sử dụng Stack để chồng ảnh và text lên nhau
                      fit: StackFit.expand, // Mở rộng Stack để lấp đầy Card
                      children: [
                        // 1. Ảnh kết quả (nằm dưới cùng trong Stack)
                        Image.network(
                          fullUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                              child: Center(
                                child: Icon(Icons.broken_image, size: 50, color: Theme.of(context).colorScheme.error),
                              ),
                            );
                          },
                        ),
                        // 2. Overlay hiển thị khoảng cách (nằm trên ảnh)
                        Positioned( // Đặt widget Text ở vị trí cụ thể trong Stack
                          bottom: 0, // Dưới cùng
                          left: 0, // Sát lề trái
                          right: 0, // Sát lề phải
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            color: Colors.black.withOpacity(0.6), // Nền màu đen trong suốt để chữ dễ đọc
                            child: Text(
                              // Hiển thị khoảng cách, làm tròn đến 4 chữ số thập phân
                              'Distance: ${result.distance.toStringAsFixed(4)}',
                              style: const TextStyle(
                                color: Colors.white, // Chữ màu trắng
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center, // Căn giữa chữ
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Đặt class này ở cuối file main.dart, ngoài các class widget chính
class SearchResult {
  final String imagePath;
  final double distance;

  SearchResult({required this.imagePath, required this.distance});

  // Factory constructor để tạo đối tượng SearchResult từ Map JSON
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      imagePath: json['image_path'] as String,
      // Sử dụng 'num' để xử lý cả int và double từ JSON, sau đó chuyển về double
      distance: (json['distance'] as num).toDouble(),
    );
  }
}