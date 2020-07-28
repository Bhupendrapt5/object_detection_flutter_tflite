import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
// ignore: unused_import
// import 'package:image/image.dart' as img;

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
  final _imagePicker = ImagePicker();
  bool _isBusy = false;
  List _recognition;

  @override
  void initState() {
    super.initState();
    _isBusy = true;
    _loadModel();
  }

  Future _loadModel() async {
    Tflite.close();
    try {
      String res;
      if (_model == yolo) {
        res = await Tflite.loadModel(
          model: 'assets/tflite/yolov2_tiny.tflite',
          labels: 'assets/tflite/yolov2_tiny.txt',
        );
      } 
      else {
        res = await Tflite.loadModel(
          model: 'assets/tflite/ssd_mobilenet.tflite',
          labels: 'assets/tflite/ssd_mobilenet.txt',
        );
      }
      setState(() {
        _isBusy = false;
        
      });
      print(res);
    } on PlatformException {
      print('Failde to load the model');
    }
  }

  _selectFromImagePicker() async {
    var image = await _imagePicker.getImage(
      source: ImageSource.camera,
    );
    if (image == null) return;
    final pickedImage = File(image.path);
    setState(() {
      _isBusy = true;
    });
    predictImage(pickedImage);
  }

  predictImage(File image) async {
    if (image == null) return;
    switch (_model) {
      case ssd:
        await ssdMobileNet(image);
        break;
      case yolo:
        await yolov2Tiny(image);
        break;
    }
    FileImage(image).resolve(ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          _imageWidth = info.image.width.toDouble();
          _imageHeight = info.image.height.toDouble();
        },
      ),
    );
    setState(() {
      _imageFile = image;
      _isBusy = false;
    });
  }

  Future yolov2Tiny(File image) async {
    //* To draw boxes around object
    var recognition = await Tflite.detectObjectOnImage(
      path: image.path,
      model: 'YOLO',
      threshold: 0.3,
      imageMean: 0.0,
      imageStd: 255.0,
      numResultsPerClass: 1,
    );
    setState(() {
      _recognition = recognition;
    });
  }

  Future ssdMobileNet(File image) async {
    //* To draw boxes around object
    var recognition = await Tflite.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1,
    );
    setState(() {
      _recognition = recognition;
    });
  }

  List<Widget> _renderBoxes(Size size) {
    //* If recongnition is empty, return [] list
    if (_recognition == null) return [];

    //* If Image Height or Width is empty, return [] list
    if (_imageHeight == null || _imageWidth == null) return [];

    double factorX = size.width;
    double factorY = _imageHeight / _imageHeight * size.width;

    Color _color = Colors.green;

    return _recognition
        .map(
          (re) => Positioned(
            left: re['rect']['x'] * factorX,
            top: re['rect']['y'] * factorY,
            width: re['rect']['w'] * factorX,
            height: re['rect']['h'] * factorY,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _color,
                  width: 3,
                ),
              ),
              child: Text(
                '${re['detectedClass']} ${(re['confidenceInClass'] * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  background: Paint()..color = _color,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];

    stackChildren.add(
      Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        child: _imageFile == null
            ? Text('No image Selected')
            : Image.file(_imageFile),
      ),
    );

    stackChildren.addAll(
      _renderBoxes(size),
    );
    if (_isBusy) {
      stackChildren.add(
        Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Object Detection'),
      ),
      body: Stack(
        children: stackChildren,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectFromImagePicker,
        child: Icon(Icons.image),
        tooltip: 'Pick Image',
      ),
    );
  }
}
