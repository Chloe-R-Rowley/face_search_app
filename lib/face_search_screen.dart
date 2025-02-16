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
    _startImageRotation();
  }

  void _startImageRotation() {
    if (_relatedImageUrls.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_relatedImageUrls.isNotEmpty) {
          setState(() {
            _currentImageIndex = (_currentImageIndex + 1) % _relatedImageUrls.length;
          });
        } else {
          _timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _sendImageToBackend(File imageFile) async {
    List<String> sampleImages = [
      'assets/images/srk1.jpg',
      'assets/images/srk2.jpg',
      'assets/images/srk3.jpg',
      'assets/images/srk4.jpg'
    ]; // Dummy sample images

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    // Simulate a delay of 3 seconds before displaying images
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _relatedImageUrls = sampleImages; // Assign dummy images
      _loading = false;
      _currentImageIndex = 0;
    });

    _startImageRotation(); // Start rotating through images
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
              Column(
                children: [
                  const SizedBox(height: 10),
                  _relatedImageUrls[_currentImageIndex].startsWith('http') // Check if it's a network image
                      ? CachedNetworkImage(
                          imageUrl: _relatedImageUrls[_currentImageIndex],
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Image.asset( // Use Image.asset for local images
                          _relatedImageUrls[_currentImageIndex],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}