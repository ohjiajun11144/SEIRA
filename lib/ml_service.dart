import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class MLService {
  late tfl.Interpreter _interpreter;
  late List<String> _labels;

  Future<void> init() async {
    _interpreter = await tfl.Interpreter.fromAsset('assets/event_model.tflite');
    _labels = await _loadLabels('assets/labels.txt');

    // Optional: print IO info to logcat while debugging
    // final inT = _interpreter.getInputTensor(0);
    // final outT = _interpreter.getOutputTensor(0);
    // print('INPUT  shape=${inT.shape} type=${inT.type}');
    // print('OUTPUT shape=${outT.shape} type=${outT.type}');
  }

  /// Run for FLOAT32 input models: input shape [1,H,W,3], values preprocessed to 0..1 or -1..1 as your model expects.
  Future<List<MapEntry<String, double>>> runFloat(
      Float32List inputNHWC,
      List<int> inputShapeNHWC,
      ) async {
    // Create input/output tensors
    final input = _asByteBuffer(inputNHWC);
    final outTensor = _interpreter.getOutputTensor(0);

    final outputBuffer = _emptyBufferForTensor(outTensor);

    // Inference
    _interpreter.run(input, outputBuffer);

    // Read float32 output
    final scores = outputBuffer.asFloat32List();
    return _topK(scores, _labels, 3);
  }

  /// Run for QUANTIZED UINT8 input models: input shape [1,H,W,3], values 0..255
  Future<List<MapEntry<String, double>>> runUint8(
      Uint8List inputNHWC,
      List<int> inputShapeNHWC,
      ) async {
    final input = _asByteBuffer(inputNHWC);
    final outTensor = _interpreter.getOutputTensor(0);

    final outputBuffer = _emptyBufferForTensor(outTensor);
    _interpreter.run(input, outputBuffer);

    // Dequantize output if needed
    if (outTensor.type == tfl.TfLiteType.uint8) {
      final raw = outputBuffer.asUint8List();
      final scale = outTensor.params.scale;
      final zero = outTensor.params.zeroPoint;
      final scores = List<double>.generate(raw.length, (i) => scale * (raw[i] - zero));
      return _topK(scores, _labels, 3);
    } else if (outTensor.type == tfl.TfLiteType.float32) {
      final scores = outputBuffer.asFloat32List();
      return _topK(scores, _labels, 3);
    } else {
      throw StateError('Unsupported output type: ${outTensor.type}');
    }
  }

  void dispose() => _interpreter.close();

  // ---- helpers ----
  Future<List<String>> _loadLabels(String assetPath) async {
    final raw = await tfl.ResourceFileUtil.loadString(assetPath);
    return raw.split('\n').where((s) => s.trim().isNotEmpty).toList();
  }

  // Convert typed lists to ByteBuffer (what Interpreter.run expects)
  ByteBuffer _asByteBuffer(Float32List data) => data.buffer;
  ByteBuffer _asByteBuffer(Uint8List data) => data.buffer;

  // Allocate an empty buffer for a given tensor (supports uint8/float32)
  ByteBuffer _emptyBufferForTensor(tfl.Tensor tensor) {
    final elemCount = tensor.shape.reduce((a, b) => a * b);
    switch (tensor.type) {
      case tfl.TfLiteType.float32:
        return Float32List(elemCount).buffer;
      case tfl.TfLiteType.uint8:
        return Uint8List(elemCount).buffer;
      default:
        throw StateError('Unsupported tensor type: ${tensor.type}');
    }
  }

  List<MapEntry<String, double>> _topK(
      List<double> scores,
      List<String> labels,
      int k,
      ) {
    final n = (scores.length < labels.length) ? scores.length : labels.length;
    final pairs = List.generate(n, (i) => MapEntry(labels[i], scores[i]));
    pairs.sort((a, b) => b.value.compareTo(a.value));
    return pairs.take(k).toList();
  }
}
