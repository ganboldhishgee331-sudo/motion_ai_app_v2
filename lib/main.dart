
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MotionAiApp());
}

class MotionAiApp extends StatelessWidget {
  const MotionAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motion AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurple,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  String? _videoUrl;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  String _statusMessage = '';
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _apiKeyController = TextEditingController();

  String get _apiToken {
    const envToken = String.fromEnvironment('REPLICATE_API_TOKEN');
    if (envToken.isNotEmpty) return envToken;
    return _apiKeyController.text.trim();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _videoUrl = null;
        _videoController?.dispose();
        _videoController = null;
        _statusMessage = '';
      });
    }
  }

  Future<void> _generateVideo() async {
    if (_selectedImage == null) {
      _showSnackBar('Импортлох зургаа эхлээд сонгоно уу.');
      return;
    }

    final token = _apiToken;
    if (token.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Зургийг сервер рүү илгээж байна...';
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final response = await http.post(
        Uri.parse('https://api.replicate.com/v1/predictions'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version': '3f042780e94de337e4701a61d137750d7a1b612261dec6955b22d1f03ab2894c',
          'input': {
            'input_image': base64Image,
            'motion_bucket_id': 127,
            'cond_aug': 0.02,
            'decoding_t': 14,
            'frames_per_second': 6,
          }
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw Exception(err['detail'] ?? 'API хүсэлт амжилтгүй боллоо');
      }

      final jsonResponse = jsonDecode(response.body);
      String getUrl = jsonResponse['urls']['get'];

      await _pollResult(getUrl, token);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Алдаа гарлаа: $e';
      });
      _showSnackBar('Алдаа: $e');
    }
  }

  Future<void> _pollResult(String pollUrl, String token) async {
    int attempts = 0;
    while (attempts < 60) {
      await Future.delayed(const Duration(seconds: 4));
      attempts++;

      setState(() {
        _statusMessage = 'AI видео боловсруулж байна ($attempts/60)...';
      });

      final response = await http.get(
        Uri.parse(pollUrl),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'succeeded') {
          final dynamic output = data['output'];
          String? resultUrl;
          if (output is List && output.isNotEmpty) {
            resultUrl = output.first.toString();
          } else if (output is String) {
            resultUrl = output;
          }

          if (resultUrl != null && resultUrl.isNotEmpty) {
            setState(() {
              _videoUrl = resultUrl;
              _isLoading = false;
              _statusMessage = 'Видео амжилттай үүслээ!';
            });
            _initializeVideoPlayer(resultUrl);
            return;
          }
        } else if (status == 'failed' || status == 'canceled') {
          throw Exception('AI видео үүсгэлт амжилтгүй боллоо: ${data['error']}');
        }
      }
    }
    throw Exception('Боловсруулах хугацаа дууслаа.');
  }

  Future<void> _initializeVideoPlayer(String url) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.play();
    setState(() {});
  }

  Future<void> _downloadVideo() async {
    if (_videoUrl == null) return;

    try {
      _showSnackBar('Видеог татаж байна...');
      final response = await http.get(Uri.parse(_videoUrl!));
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/generated_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      _showSnackBar('Видео амжилттай хадгалагдлаа: $filePath');
    } catch (e) {
      _showSnackBar('Видео хадгалахад алдаа гарлаа: $e');
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replicate API Key Оруулна уу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Replicate API түлхүүр заавал шаардлагатай.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'r8_xxxxxxxxxxxxxxxxxxxx',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Цуцлах'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_apiKeyController.text.trim().isNotEmpty) {
                _generateVideo();
              }
            },
            child: const Text('Үргэлжлүүлэх'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion AI - Image to Video'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            onPressed: _showApiKeyDialog,
            tooltip: 'API Key тохируулах',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _videoController != null && _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.contain)
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Галерейгаас зургаа сонгоно уу', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w500),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Зураг Сонгох'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateVideo,
                    icon: const Icon(Icons.movie_creation_outlined),
                    label: const Text('Видео Үүсгэх'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                  ),
                ),
              ],
            ),
            if (_videoUrl != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _downloadVideo,
                  icon: const Icon(Icons.download),
                  label: const Text('Видеог MP4-өөр Хадгалах'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.tealAccent),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
