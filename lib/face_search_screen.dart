//face_search_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FaceSearchApp extends StatefulWidget {
  const FaceSearchApp({super.key});

  @override
  State<FaceSearchApp> createState() => _FaceSearchAppState();
}

class _FaceSearchAppState extends State<FaceSearchApp> {
  late File? _selectedImage = null; // Initialize _selectedImage to null
  late List<String> _relatedImageUrls = []; // Initialize _relatedImageUrls to an empty list
  bool _loading = false;
  String _errorMessage = '';
  int _currentImageIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _relatedImageUrls.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _startImageRotation() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _relatedImageUrls.length;
      });
    });
  }

  Future<void> _sendImageToBackend(File imageFile) async {
    final url = Uri.parse('http://10.0.2.2:3000/process-image'); // Dummy API endpoint

    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });

      final response = await http.post(
        url,
        body: {
          'imageData': imageFile.readAsBytesSync().toString(),
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final List<String> relatedImageUrls = List<String>.from(responseBody['relatedImages']);

        setState(() {
          _relatedImageUrls = relatedImageUrls;
          _loading = false;
          _currentImageIndex = 0;
        });

        _startImageRotation(); // Start rotating through related images
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch related images. Please try again later.';
          _loading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $error';
        _loading = false;
      });
    }
  }

  Future<void> _getImage() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
        _loading = false;
      });
      // Send the selected image to the backend API for processing
      _sendImageToBackend(_selectedImage!);
    } else {
      setState(() {
        _loading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Search App'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: _selectedImage == null
                    ? const Center(
                        child: Icon(
                          Icons.image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      )
                    : ClipRect(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _getImage,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Select Image',
                        style: TextStyle(fontSize: 18),
                      ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              if (_relatedImageUrls.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: _relatedImageUrls[_currentImageIndex],
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}