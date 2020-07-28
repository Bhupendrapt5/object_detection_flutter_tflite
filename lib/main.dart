import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart';

void main() {
  runApp(MyApp());
}

const String ssd = 'SSD MobileNet';
const String yolo = 'Tiny YOLOv2';

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What\'s That?',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: TfliteHome(),
    );
  }
}

class TfliteHome extends StatefulWidget {
  @override
  _TfliteHomeState createState() => _TfliteHomeState();
}

class _TfliteHomeState extends State<TfliteHome> {
  String _model = ssd;
  File _imageFile;
  double _imageHeight;
  double _imageWidth;
  ImagePicker _imagePicker;
  bool _isBusy = false;
  _selectFromImagePicker() async {
    var image = await _imagePicker.getImage(
      source: ImageSource.gallery,
    );
    if(image ==null) return;

    setState(() {
      _isBusy = true;
    });
    predictImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Object Detection'),
      ),
      body: Center(
        child: Text('Hello World'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectFromImagePicker,
        child: Icon(Icons.image),
        tooltip: 'Pick Image',
      ),
    );
  }
}
