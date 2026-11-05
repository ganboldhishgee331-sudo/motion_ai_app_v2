import 'dart:async';
import 'dart:convert';
import 'dart:io';
​import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
​void main() {
WidgetsFlutterBinding.ensureInitialized();
runApp(const MotionAiApp());
}
​class MotionAiApp extends StatelessWidget {
const MotionAiApp({super.key});
​@override
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
​class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});
​@override
State<HomeScreen> createState() => _HomeScreenState();
}
​class _HomeScreenState extends State<HomeScreen> {
final ImagePicker _picker = ImagePicker();
final TextEditingController _apiKeyController = TextEditingController();
​File? _selectedImage;
String? _videoUrl;
VideoPlayerController? _videoController;
​bool _isLoading = false;
bool _isDownloading = false;
String _statusMessage = '';
​static const String _apiUrl = 'https://api.replicate.com/v1/predictions';
static const String _modelVersion =
'3f042780e94de337e4701a61d137750d7a1b612261dec6955b22d1f03ab2894c';
​String get _apiToken => _apiKeyController.text.trim();
​@override
void dispose() {
_videoController?.dispose();
_apiKeyController.dispose();
super.dispose();
}
​void _showMessage(String message) {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(message)),
);
}
​Future<void> _pickImage() async {
try {
final XFile? pickedFile = await _picker.pickImage(
source: ImageSource.gallery,
imageQuality: 85,
);
​if (pickedFile == null || !mounted) return;
​await _videoController?.dispose();
_videoController = null;
​setState(() {
_selectedImage = File(pickedFile.path);
_videoUrl = null;
_statusMessage = 'Зураг амжилттай сонгогдлоо.';
});
} catch (e) {
_showMessage('Зураг сонгоход алдаа гарлаа: $e');
}
}
​Future<void> _showApiKeyDialog() async {
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
controller: apiKeyController,
obscureText: true,
decoration: const InputDecoration(
border: OutlineInputBorder(),
labelText: 'API Token',
hintText: 'r8...',
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
​String _getMimeType(String path) {
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
​Future<void> _generateVideo() async {
if (_isLoading) return;
​if (_selectedImage == null) {
_showMessage('Эхлээд зураг сонгоно уу.');
return;
}
​if (_apiToken.isEmpty) {
_showApiKeyDialog();
return;
}
​setState(() {
_isLoading = true;
_videoUrl = null;
_statusMessage = 'Зургийг AI сервер рүү илгээж байна...';
});
​try {
final bytes = await _selectedImage!.readAsBytes();
final mimeType = _getMimeType(_selectedImage!.path);
final base64Image = 'data:mimeType;base64,{base64Encode(bytes)}';
​final response = await http
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
​if (response.statusCode != 200 && response.statusCode != 201) {
throw Exception(
'API алдаа ({response.statusCode}):{response.body}',
);
}
​final data = jsonDecode(response.body);
final pollUrl = data['urls']?['get'];
​if (pollUrl == null) {
throw Exception('Серверээс шалгах холбоос ирсэнгүй.');
}
​await _pollResult(pollUrl.toString());
} catch (e) {
if (!mounted) return;
setState(() {
_isLoading = false;
_statusMessage = 'Алдаа гарлаа: $e';
});
_showMessage('Видео үүсгэхэд алдаа гарлаа.');
}
}
​Future<void> _pollResult(String pollUrl) async {
for (int attempt = 1; attempt <= 60; attempt++) {
await Future.delayed(const Duration(seconds: 4));
​if (!mounted) return;
​final response = await http
.get(
Uri.parse(pollUrl),
headers: {
'Authorization': 'Bearer $_apiToken',
},
)
.timeout(const Duration(seconds: 30));
​if (response.statusCode != 200) {
throw Exception(
'Төлөв шалгахад алдаа гарлаа: ${response.statusCode}',
);
}
​final data = jsonDecode(response.body);
final status = data['status'];
​if (mounted) {
setState(() {
_statusMessage = 'AI видео боловсруулж байна... $attempt/60';
});
}
​if (status == 'succeeded') {
final output = data['output'];
String? resultUrl;
​if (output is List && output.isNotEmpty) {
resultUrl = output.first.toString();
} else if (output is String) {
resultUrl = output;
}
​if (resultUrl == null || resultUrl.isEmpty) {
throw Exception('Видео үүссэн боловч холбоос олдсонгүй.');
}
​if (!mounted) return;
​setState(() {
_videoUrl = resultUrl;
_isLoading = false;
_statusMessage = 'Видео амжилттай үүслээ!';
});
​await _initializeVideoPlayer(resultUrl);
return;
}
​if (status == 'failed' || status == 'canceled') {
throw Exception(
'AI видео үүсгэлт амжилтгүй боллоо: ${data['error']}',
);
}
}
​throw Exception('Видео боловсруулах хугацаа дууслаа.');
}
​Future<void> _initializeVideoPlayer(String url) async {
try {
await _videoController?.dispose();
​final controller = VideoPlayerController.networkUrl(Uri.parse(url));
_videoController = controller;
​await controller.initialize();
controller.setLooping(true);
controller.play();
​if (!mounted) return;
setState(() {});
} catch (e) {
_showMessage('Видео тоглуулагч эхлүүлэхэд алдаа гарлаа: $e');
}
}
​Future<void> _downloadVideo() async {
if (_videoUrl == null || _isDownloading) return;
​setState(() {
_isDownloading = true;
});
​try {
_showMessage('Видеог татаж байна...');
final response = await http.get(Uri.parse(_videoUrl!));
​final dir = await getApplicationDocumentsDirectory();
final filePath =
'{dir.path}/motion_ai_{DateTime.now().millisecondsSinceEpoch}.mp4';
​final file = File(filePath);
await file.writeAsBytes(response.bodyBytes);
​_showMessage('Видео амжилттай хадгалагдлаа: $filePath');
} catch (e) {
_showMessage('Татахад алдаа гарлаа: $e');
} finally {
if (mounted) {
setState(() {
_isDownloading = false;
});
}
}
}
​@override
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
),
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
border: Border.all(
color: Colors.deepPurpleAccent.withOpacity(0.5),
),
),
child: ClipRRect(
borderRadius: BorderRadius.circular(16),
child: _videoController != null &&
_videoController!.value.isInitialized
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
Icon(Icons.image_outlined,
size: 64, color: Colors.grey),
SizedBox(height: 8),
Text(
'Галерейгаас зургаа сонгоно уу',
style: TextStyle(color: Colors.grey),
),
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
style: const TextStyle(
color: Colors.tealAccent,
fontWeight: FontWeight.w500,
),
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
onPressed: _isDownloading ? null : _downloadVideo,
icon: const Icon(Icons.download),
label: Text(
_isDownloading ? 'Татаж байна...' : 'Видеог MP4-өөр Хадгалах'),
style: OutlinedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 14),
side: const BorderSide(color: Colors.tealAccent),
),
),
),
],
],
),
),
);
}
}
