
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: const Color(0xFF10111B),
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
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
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _apiKeyController =
      TextEditingController();

  File? _selectedImage;

  String? _videoUrl;

  VideoPlayerController? _videoController;

  bool _isLoading = false;
  bool _isDownloading = false;

  String _statusMessage = '';

  static const String _apiUrl =
      'https://api.replicate.com/v1/predictions';

  static const String _modelVersion =
      '3f042780e94de337e4701a61d137750d7a1b612261dec6955b22d1f03ab2894c';

  String get _apiToken => _apiKeyController.text.trim();

  @override
  void dispose() {
    _videoController?.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  // ЗУРАГ СОНГОХ

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      await _videoController?.dispose();
      _videoController = null;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _videoUrl = null;
        _statusMessage = 'Зураг амжилттай сонгогдлоо.';
      });
    } catch (e) {
      _showMessage('Зураг сонгоход алдаа гарлаа: $e');
    }
  }

  // API KEY ОРУУЛАХ

  Future<void> _showApiKeyDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Replicate API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Видео үүсгэхийн тулд Replicate API түлхүүр шаардлагатай.',
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'API Token',
                  hintText: 'r8_...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Болих'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                if (_apiToken.isNotEmpty) {
                  _generateVideo();
                }
              },
              child: const Text('Хадгалах'),
            ),
          ],
        );
      },
    );
  }

  // ЗУРГИЙН ТӨРӨЛ ТОДОРХОЙЛОХ

  String _getMimeType(String path) {
    final extension = path.toLowerCase().split('.').last;

    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // VIDEO ҮҮСГЭХ

  Future<void> _generateVideo() async {
    if (_isLoading) return;

    if (_selectedImage == null) {
      _showMessage('Эхлээд зураг сонгоно уу.');
      return;
    }

    if (_apiToken.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _videoUrl = null;
      _statusMessage = 'Зургийг AI сервер рүү илгээж байна...';
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();

      final mimeType = _getMimeType(_selectedImage!.path);

      final base64Image =
          'data:$mimeType;base64,${base64Encode(bytes)}';

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Bearer $_apiToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'version': _modelVersion,
              'input': {
                'input_image': base64Image,
                'motion_bucket_id': 127,
                'cond_aug': 0.02,
                'decoding_t': 14,
                'frames_per_second': 6,
              },
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          'API алдаа (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body);

      final pollUrl = data['urls']?['get'];

      if (pollUrl == null) {
        throw Exception('Серверээс шалгах холбоос ирсэнгүй.');
      }

      await _pollResult(pollUrl.toString());

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _statusMessage = 'Алдаа гарлаа: $e';
      });

      _showMessage('Видео үүсгэхэд алдаа гарлаа.');
    }
  }

  // AI ҮҮСГЭЛТ ШАЛГАХ

  Future<void> _pollResult(String pollUrl) async {
    for (int attempt = 1; attempt <= 60; attempt++) {
      await Future.delayed(const Duration(seconds: 4));

      if (!mounted) return;

      final response = await http
          .get(
            Uri.parse(pollUrl),
            headers: {
              'Authorization': 'Bearer $_apiToken',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Төлөв шалгахад алдаа гарлаа: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      final status = data['status'];

      if (mounted) {
        setState(() {
          _statusMessage =
              'AI видео боловсруулж байна... $attempt/60';
        });
      }

      if (status == 'succeeded') {
        final output = data['output'];

        String? resultUrl;

        if (output is List && output.isNotEmpty) {
          resultUrl = output.first.toString();
        } else if (output is String) {
          resultUrl = output;
        }

        if (resultUrl == null || resultUrl.isEmpty) {
          throw Exception('Видео үүссэн боловч холбоос олдсонгүй.');
        }

        if (!mounted) return;

        setState(() {
          _videoUrl = resultUrl;
          _isLoading = false;
          _statusMessage = 'Видео амжилттай үүслээ!';
        });

        await _initializeVideoPlayer(resultUrl);

        return;
      }

      if (status == 'failed' || status == 'canceled') {
        throw Exception(
          'AI видео үүсгэлт амжилтгүй боллоо: ${data['error']}',
        );
      }
    }

    throw Exception('Видео боловсруулах хугацаа дууслаа.');
  }

  // VIDEO PLAYER

  Future<void> _initializeVideoPlayer(String url) async {
    try {
      await _videoController?.dispose();

      final controller =
          VideoPlayerController.networkUrl(Uri.parse(url));

      _videoController = controller;

      await controller.initialize();

      if (!mounted || _videoController !=
