import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MotionAiApp());
}

class MotionAiApp extends StatefulWidget {
  const MotionAiApp({super.key});

  @override
  State<MotionAiApp> createState() => _MotionAiAppState();
}

class _MotionAiAppState extends State<MotionAiApp> {
  bool _isImageSelected = false;
  bool _isLoading = false;
  bool _isDone = false;

  void _pickImageFromGallery() {
    setState(() {
      _isImageSelected = true;
      _isDone = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Галерейгаас зураг амжилттай сонгогдлоо!')),
    );
  }

  Future<void> _processAiAnimation() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isLoading = false;
      _isDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AI Амьд Зураг Апп'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.deepPurple, width: 2),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.deepPurple),
                              SizedBox(height: 20),
                              Text('AI зураг боловсруулж байна...\nTүр хүлээгээрэй', textAlign: TextAlign.center),
                            ],
                          )
                        : _isDone
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.movie_creation, size: 80, color: Colors.deepPurple),
                                  SizedBox(height: 15),
                                  Text(
                                    '✨ Таны зураг амьд хөдөлгөөнт дүрс боллоо!',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : _isImageSelected
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image, size: 80, color: Colors.deepPurple),
                                      SizedBox(height: 15),
                                      Text('Сонгосон зураг бэлэн байна', style: TextStyle(fontSize: 16)),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo_library, size: 80, color: Colors.grey),
                                      SizedBox(height: 15),
                                      Text('Утсаасаа зураг сонгоно уу', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                    ],
                                  ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Утсны галерейгаас зураг сонгох'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              ),

              if (_isImageSelected && !_isLoading && !_isDone) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _processAiAnimation,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI-аар амьд хөдөлгөөнд оруулах'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],

              if (_isDone) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isImageSelected = false;
                      _isDone = false;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Шинэ зураг оруулах'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
