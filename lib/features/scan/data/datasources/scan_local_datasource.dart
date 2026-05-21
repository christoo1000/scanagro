import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:agro_ai_doctor/features/scan/data/models/crop_diagnosis_model.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

abstract class ScanLocalDataSource {
  Future<CropDiagnosisModel> diagnoseImage(File image);
  void close();
}

class ScanLocalDataSourceImpl implements ScanLocalDataSource {
  static const _modelPath = 'assets/models/model.tflite';
  static const _classesPath = 'assets/models/classes.json';
  static const _inputSize = 224;
  static const _confidenceThreshold = 0.5;
  static const _imageNetMean = [0.485, 0.456, 0.406];
  static const _imageNetStd = [0.229, 0.224, 0.225];

  Interpreter? _interpreter;
  List<String>? _classes;

  @override
  Future<CropDiagnosisModel> diagnoseImage(File image) async {
    final interpreter = await _loadInterpreter();
    final classes = await _loadClasses();
    final input = await _preprocessImage(image);
    final output = List.generate(1, (_) => List<double>.filled(classes.length, 0));

    interpreter.run(input, output);

    final probabilities = _softmax(output.first);
    final predictedIndex = _argMax(probabilities);
    final confidence = double.parse(probabilities[predictedIndex].toStringAsFixed(4));
    final disease = classes[predictedIndex];
    final severity = _severityFromConfidence(confidence);
    final recommendation = _recommendationFor(disease, confidence);

    return CropDiagnosisModel.fromLocalPrediction(
      disease: disease,
      confidence: confidence,
      severity: severity,
      isConfident: confidence >= _confidenceThreshold,
      recommendation: recommendation,
      imagePath: image.path,
    );
  }

  @override
  void close() {
    _interpreter?.close();
    _interpreter = null;
  }

  Future<Interpreter> _loadInterpreter() async {
    final existing = _interpreter;
    if (existing != null) return existing;

    final options = InterpreterOptions()..threads = 2;
    final interpreter = await Interpreter.fromAsset(_modelPath, options: options);
    final inputShape = interpreter.getInputTensor(0).shape;

    if (inputShape.length != 4 ||
        inputShape[0] != 1 ||
        inputShape[1] != 3 ||
        inputShape[2] != _inputSize ||
        inputShape[3] != _inputSize) {
      interpreter.close();
      throw StateError('Unexpected TFLite input shape: $inputShape');
    }

    _interpreter = interpreter;
    return interpreter;
  }

  Future<List<String>> _loadClasses() async {
    final existing = _classes;
    if (existing != null) return existing;

    final rawJson = await rootBundle.loadString(_classesPath);
    final decoded = json.decode(rawJson);

    if (decoded is! List || decoded.any((item) => item is! String)) {
      throw StateError('Invalid classes.json format.');
    }

    _classes = decoded.cast<String>();
    return _classes!;
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw StateError('Could not decode selected image.');
    }

    final resized = img.copyResize(
      decodedImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = List.generate(
      1,
      (_) => List.generate(
        3,
        (_) => List.generate(
          _inputSize,
          (_) => List<double>.filled(_inputSize, 0),
        ),
      ),
    );

    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        final red = pixel.r / 255.0;
        final green = pixel.g / 255.0;
        final blue = pixel.b / 255.0;

        input[0][0][y][x] = (red - _imageNetMean[0]) / _imageNetStd[0];
        input[0][1][y][x] = (green - _imageNetMean[1]) / _imageNetStd[1];
        input[0][2][y][x] = (blue - _imageNetMean[2]) / _imageNetStd[2];
      }
    }

    return input;
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(max);
    final expValues = logits.map((value) => exp(value - maxLogit)).toList();
    final sumExp = expValues.fold<double>(0, (sum, value) => sum + value);
    return expValues.map((value) => value / sumExp).toList();
  }

  int _argMax(List<double> values) {
    var bestIndex = 0;
    var bestValue = values.first;

    for (var index = 1; index < values.length; index++) {
      if (values[index] > bestValue) {
        bestIndex = index;
        bestValue = values[index];
      }
    }

    return bestIndex;
  }

  String _severityFromConfidence(double confidence) {
    if (confidence > 0.8) return 'high';
    if (confidence >= 0.5) return 'medium';
    return 'low';
  }

  String _recommendationFor(String disease, double confidence) {
    if (confidence < _confidenceThreshold) {
      return 'Prediction confidence is low. Capture a clearer leaf image and confirm with field inspection.';
    }

    if (disease.endsWith('_healthy')) {
      return 'Crop appears healthy based on the uploaded image.';
    }

    return 'Prediction is confident enough for triage. Confirm symptoms before treatment decisions.';
  }
}
