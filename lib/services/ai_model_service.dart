import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:math' as Math;

class AIModelService {
  static Interpreter? _interpreter;
  static bool _modelLoaded = false;
  static List<String>? _labels;
  static bool _modelLoadFailed = false;

  static Future<void> loadModel() async {
    if (_modelLoadFailed) {
      print("⚠️ Model load previously failed, skipping...");
      return;
    }
    
    try {
      print("🔄 Loading model and labels...");
      
      // Try to load the model from assets first
      try {
        _interpreter = await Interpreter.fromAsset('event_model.tflite');
        print("✅ Model loaded from assets");
      } catch (assetError) {
        print("⚠️ Failed to load from assets: $assetError");
        print("🔄 Trying to copy model to documents directory...");
        
        // Try to copy model to documents directory and load from there
        await _copyModelToDocuments();
        final documentsDir = await getApplicationDocumentsDirectory();
        final modelPath = '${documentsDir.path}/event_model.tflite';
        
        if (await File(modelPath).exists()) {
          _interpreter = await Interpreter.fromFile(File(modelPath));
          print("✅ Model loaded from documents directory");
        } else {
          throw Exception("Model file not found in documents directory");
        }
      }
      
      // Print model info for debugging
      print("📊 Model input tensors:");
      for (int i = 0; i < _interpreter!.getInputTensors().length; i++) {
        final tensor = _interpreter!.getInputTensor(i);
        print("  Input $i: ${tensor.name} - Shape: ${tensor.shape} - Type: ${tensor.type}");
      }
      
      print("📊 Model output tensors:");
      for (int i = 0; i < _interpreter!.getOutputTensors().length; i++) {
        final tensor = _interpreter!.getOutputTensor(i);
        print("  Output $i: ${tensor.name} - Shape: ${tensor.shape} - Type: ${tensor.type}");
      }
      
      // Load labels
      _labels = ['fire', 'accident', 'snake']; // Hardcoded labels as fallback
      print("📝 Labels loaded: $_labels");
      print("✅ Model loaded successfully");
      _modelLoaded = true;
      
      // Test the model
      await testModel();
    } catch (e) {
      print("❌ Failed to load model: $e");
      print("⚠️ Using fallback classification only");
      _modelLoaded = false;
      _modelLoadFailed = true;
      
      // Set fallback labels
      _labels = ['fire', 'accident', 'snake'];
    }
  }

  static Future<void> _copyModelToDocuments() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final modelPath = '${documentsDir.path}/event_model.tflite';
      
      // Check if model already exists in documents
      if (await File(modelPath).exists()) {
        print("✅ Model already exists in documents directory");
        return;
      }
      
      // Copy from assets to documents
      final assetData = await rootBundle.load('assets/event_model.tflite');
      final file = File(modelPath);
      await file.writeAsBytes(assetData.buffer.asUint8List());
      print("✅ Model copied to documents directory");
    } catch (e) {
      print("❌ Failed to copy model: $e");
      throw e;
    }
  }

  static Future<List<Map<String, dynamic>>?> classifyImage(String imagePath) async {
    if (_modelLoadFailed) {
      print("⚠️ Model failed to load, using fallback classification");
      return _fallbackClassification(imagePath);
    }
    
    if (!_modelLoaded) {
      print("⚠️ Model not loaded. Attempting to reload...");
      await loadModel();
      if (!_modelLoaded) {
        print("❌ Model still not loaded after reload attempt");
        return _fallbackClassification(imagePath);
      }
    }
    
    try {
      print("🔍 Starting image classification for: $imagePath");
      
      // Load and preprocess image
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        print("❌ Image file does not exist: $imagePath");
        return null;
      }
      
      final imageBytes = await imageFile.readAsBytes();
      print("📸 Image loaded, size: ${imageBytes.length} bytes");
      
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print("❌ Failed to decode image");
        return null;
      }
      
      print("🖼️ Original image size: ${image.width}x${image.height}");
      
      // Get input tensor shape
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape;
      print("🔢 Input tensor shape: $inputShape");
      
      // Resize image to match model input size (128x128)
      final targetWidth = inputShape[2];
      final targetHeight = inputShape[1];
      final targetChannels = inputShape[3];
      
      print("📏 Resizing image to: ${targetWidth}x${targetHeight}x${targetChannels}");
      final resizedImage = img.copyResize(image, width: targetWidth, height: targetHeight);
      
      // Convert to grayscale if model expects 1 channel
      final processedImage = targetChannels == 1 
          ? img.grayscale(resizedImage)
          : resizedImage;
      
      print("🖼️ Processed image: ${processedImage.width}x${processedImage.height}");
      
      // Convert to float array and normalize
      final input = List.generate(inputShape[0], (batch) => 
        List.generate(inputShape[1], (height) => 
          List.generate(inputShape[2], (width) => 
            List.generate(inputShape[3], (channel) {
              final pixel = processedImage.getPixel(width, height);
              double value;
              
              if (targetChannels == 1) {
                // Grayscale: use any channel (they're all the same)
                value = pixel.r / 255.0;
              } else {
                // RGB: use appropriate channel
                switch (channel) {
                  case 0: value = pixel.r / 255.0; break; // Red
                  case 1: value = pixel.g / 255.0; break; // Green
                  case 2: value = pixel.b / 255.0; break; // Blue
                  default: value = 0.0;
                }
              }
              
              // Apply normalization based on model requirements
              // Most models expect [0,1] range, but some might need [-1,1] or other ranges
              // You might need to adjust this based on how your model was trained
              return value;
            })
          )
        )
      );
      
      print("🔢 Input tensor prepared, shape: ${input.length}x${input[0].length}x${input[0][0].length}x${input[0][0][0].length}");
      
      // Prepare output
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      print("🔢 Output tensor shape: $outputShape");
      
      final output = List.generate(outputShape[0], (i) => 
        List.generate(outputShape[1], (j) => 0.0)
      );
      
      // Run inference
      print("🚀 Running inference...");
      _interpreter!.run(input, output);
      print("✅ Inference completed");
      
      // Postprocess output
      final results = <Map<String, dynamic>>[];
      print("📊 Raw output: ${output[0]}");
      
      // Normalize with softmax to get probabilities
      List<double> logits = List<double>.from(output[0]);
      final maxLogit = logits.reduce((a, b) => a > b ? a : b);
      final expVals = logits.map((v) => MathHelper.exp(v - maxLogit)).toList();
      final expSum = expVals.fold(0.0, (a, b) => a + b);
      final probs = expVals.map((v) => v / (expSum == 0 ? 1 : expSum)).toList();
      
      for (int i = 0; i < probs.length; i++) {
        final confidence = probs[i];
        final label = _labels != null && i < _labels!.length ? _labels![i] : 'Label $i';
        results.add({
          'label': label,
          'confidence': confidence,
        });
        print("  $label: ${(confidence * 100).toStringAsFixed(2)}%");
      }
      
      // Sort by confidence
      results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
      final top1 = results[0];
      final top1Prob = top1['confidence'] as double;
      final top2Prob = results.length > 1 ? results[1]['confidence'] as double : 0.0;
      final margin = top1Prob - top2Prob;
      print("🏆 Top1=${top1['label']} p=${top1Prob.toStringAsFixed(3)} margin=${margin.toStringAsFixed(3)}");
      
      // Thresholding to mark unknown
      const double minConfidence = 0.3; // lowered from 0.6
      const double minMargin = 0.05;    // lowered from 0.15
      
      print("🔍 Thresholds: minConf=$minConfidence, minMargin=$minMargin");
      print("🔍 Top1 confidence: $top1Prob, margin: $margin");
      
      if (top1Prob < minConfidence || margin < minMargin) {
        print("❓ Low confidence or ambiguous prediction -> unknown");
        // Still return the top prediction but mark as uncertain
        return [
          {
            'label': 'Unknown',
            'confidence': top1Prob,
            'original_label': top1['label'], // keep original for debugging
          }
        ];
      }
      
      print("✅ Prediction meets thresholds, returning top results");
      return results.take(2).toList(); // top 2 predictions
    } catch (e, stackTrace) {
      print("❌ Classification error: $e");
      print("📚 Stack trace: $stackTrace");
      return _fallbackClassification(imagePath);
    }
  }

  static List<Map<String, dynamic>> _fallbackClassification(String imagePath) {
    print("🔄 Using fallback classification for: $imagePath");
    
    // Prefer unknown for fallback to avoid wrong auto-guessing
    return [
      {
        'label': 'Unknown',
        'confidence': 0.0,
      }
    ];
  }

  static Future<void> testModel() async {
    if (!_modelLoaded) {
      print("⚠️ Model not loaded for testing");
      return;
    }
    
    try {
      print("🧪 Testing model with random input...");
      
      // Get input tensor shape
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape;
      print("🔢 Test input shape: $inputShape");
      
      // Create random test input
      final testInput = List.generate(inputShape[0], (batch) => 
        List.generate(inputShape[1], (height) => 
          List.generate(inputShape[2], (width) => 
            List.generate(inputShape[3], (channel) {
              // Random values between 0 and 1
              return (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;
            })
          )
        )
      );
      
      // Prepare output
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      final output = List.generate(outputShape[0], (i) => 
        List.generate(outputShape[1], (j) => 0.0)
      );
      
      // Run inference
      _interpreter!.run(testInput, output);
      
      print("🧪 Test output: ${output[0]}");
      print("🧪 Test output sum: ${output[0].fold(0.0, (sum, value) => sum + value)}");
      
      // Check if output is reasonable
      final maxValue = output[0].reduce((a, b) => a > b ? a : b);
      final minValue = output[0].reduce((a, b) => a < b ? a : b);
      print("🧪 Test output range: min=$minValue, max=$maxValue");
      
      if (maxValue > 0 && maxValue <= 1) {
        print("✅ Model test passed - output looks reasonable");
      } else {
        print("⚠️ Model test warning - output values seem unusual");
      }
      
    } catch (e) {
      print("❌ Model test failed: $e");
    }
  }

  static Future<void> disposeModel() async {
    _interpreter?.close();
    _interpreter = null;
    _modelLoaded = false;
    print("✅ Model disposed");
  }
}

// Helper for stable exp without importing dart:math directly in many places
class MathHelper {
  static double exp(double x) => _exp(x);
}

double _exp(double x) {
  return (x == 0) ? 1.0 : (x > 0 ? _expPositive(x) : 1.0 / _expPositive(-x));
}

double _expPositive(double x) {
  // Simple wrapper around dart:math exp
  return Math.exp(x);
}
