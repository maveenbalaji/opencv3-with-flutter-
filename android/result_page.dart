import 'dart:typed_data';
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final Uint8List firstProcessedImage;
  final Uint8List secondProcessedImage;
  final String result;

  ResultPage({
    required this.firstProcessedImage,
    required this.secondProcessedImage,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fingerprint Comparison Result'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.memory(
                firstProcessedImage,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
              SizedBox(width: 20),
              Image.memory(
                secondProcessedImage,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            result,
            style: TextStyle(fontSize: 22, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
