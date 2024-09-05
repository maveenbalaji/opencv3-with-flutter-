import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_3/factory/pathfrom.dart';
import 'package:opencv_3/opencv_3.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fingerprint Recognition',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;

  MyHomePage({required this.camera});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? _controller;
  File? _firstImage;
  File? _secondImage;
  Uint8List? _firstImageBytes;
  Uint8List? _secondImageBytes;
  Uint8List? _firstProcessedImage;
  Uint8List? _secondProcessedImage;
  String _result = '';
  bool _visible = false;
  bool _isTakingPicture = false;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture(bool isFirstImage) async {
    if (!_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final file = await _controller!.takePicture();
      setState(() {
        if (isFirstImage) {
          _firstImage = File(file.path);
        } else {
          _secondImage = File(file.path);
        }
        _isTakingPicture = false;
      });
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<void> _pickImage(bool isFirstImage) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isFirstImage) {
          _firstImage = File(pickedFile.path);
        } else {
          _secondImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<Uint8List?> preprocessImage(String imagePath) async {
    try {
      // Apply morphological transformation
      Uint8List? processedImage = await Cv2.morphologyEx(
        pathFrom: CVPathFrom.GALLERY_CAMERA,
        pathString: imagePath,
        operation: Cv2.MORPH_CLOSE,
        kernelSize: [5, 5],
      );

      return processedImage;
    } catch (e) {
      print("Error in preprocessing image: ${e.toString()}");
      return null;
    }
  }

  Future<bool> compareFingerprints(
      Uint8List firstImage, Uint8List secondImage) async {
    if (firstImage.length != secondImage.length) {
      return false;
    }

    int diff = 0;
    for (int i = 0; i < firstImage.length; i++) {
      if (firstImage[i] != secondImage[i]) {
        diff++;
      }
    }

    return diff < (firstImage.length * 0.05); // Example threshold
  }

  Future<void> _processAndCompareFingerprints() async {
    if (_firstImage != null && _secondImage != null) {
      setState(() {
        _visible = true;
      });

      final firstImageBytes = await preprocessImage(_firstImage!.path);
      final secondImageBytes = await preprocessImage(_secondImage!.path);

      if (firstImageBytes != null && secondImageBytes != null) {
        bool match =
            await compareFingerprints(firstImageBytes, secondImageBytes);
        setState(() {
          _firstProcessedImage = firstImageBytes;
          _secondProcessedImage = secondImageBytes;
          _result =
              match ? 'Image  match!' : ' Image  do not match.';
        });
      } else {
        setState(() {
          _result = 'Error in processing images.';
        });
      }

      setState(() {
        _visible = false;
      });
    } else {
      setState(() {
        _result = 'Please capture or choose two  images.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Image  Recognition')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Image  Recognition'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            child: CameraPreview(_controller!),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _takePicture(true),
            child: Text('Capture First Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _pickImage(true),
            child: Text('Choose First Image from Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _takePicture(false),
            child: Text('Capture Second Image '),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _pickImage(false),
            child: Text('Choose Second Image from Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _processAndCompareFingerprints,
            child: Text('Compare Image '),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 10),
          if (_firstImage != null || _secondImage != null)
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _firstImage != null
                      ? Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.blueAccent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.file(
                            _firstImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 80, height: 80, color: Colors.grey[300]),
                  SizedBox(width: 10),
                  _secondImage != null
                      ? Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.blueAccent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.file(
                            _secondImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 80, height: 80, color: Colors.grey[300]),
                ],
              ),
            ),
          if (_firstProcessedImage != null || _secondProcessedImage != null)
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _firstProcessedImage != null
                      ? Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.greenAccent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.memory(
                            _firstProcessedImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 80, height: 80, color: Colors.grey[300]),
                  SizedBox(width: 10),
                  _secondProcessedImage != null
                      ? Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.greenAccent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.memory(
                            _secondProcessedImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 80, height: 80, color: Colors.grey[300]),
                ],
              ),
            ),
          SizedBox(height: 20),
          Text(
            _result,
            style: TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
          if (_visible) CircularProgressIndicator(),
        ],
      ),
    );
  }
}
