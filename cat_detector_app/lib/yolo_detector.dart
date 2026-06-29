import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import 'detection.dart';

class CatCutoutMeta {
  const CatCutoutMeta({
    required this.image,
    required this.confidence,
  });

  final img.Image image;
  final double confidence;
}

class _Letterbox {
  const _Letterbox({
    required this.scale,
    required this.padX,
    required this.padY,
    required this.input,
  });

  final double scale;
  final double padX;
  final double padY;
  final Float32List input;
}

class _SegmentCandidate {
  const _SegmentCandidate({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.confidence,
    required this.maskCoeffs,
  });

  final double cx;
  final double cy;
  final double w;
  final double h;
  final double confidence;
  final Float32List maskCoeffs;

  double get x1 => cx - w / 2;
  double get y1 => cy - h / 2;
  double get x2 => cx + w / 2;
  double get y2 => cy + h / 2;
}

class YoloDetector {
  YoloDetector({
    this.inputSize = 320,
    this.confThreshold = 0.8,
    this.iouThreshold = 0.45,
    this.catClassId = 0,
    this.maskThreshold = 0.5,
  });

  final int inputSize;
  final double confThreshold;
  final double iouThreshold;
  final int catClassId;
  final double maskThreshold;
  static const int _maskCoeffs = 32;
  static const int _protoSize = 80;

  OrtSession? _session;

  bool get isReady => _session != null;

  Future<void> load() async {
    OrtEnv.instance.init();
    final rawAssetFile = await rootBundle.load('assets/best.onnx');
    final bytes = rawAssetFile.buffer.asUint8List();
    _session = OrtSession.fromBuffer(bytes, OrtSessionOptions());
  }

  void dispose() {
    _session?.release();
    _session = null;
  }

  Future<List<Detection>> detectFromInput(
    Float32List input,
    int frameWidth,
    int frameHeight,
  ) async {
    final outputs = await _runInference(input);
    if (outputs == null) return const [];
    try {
      return _candidatesToDetections(
        _parseCandidates(outputs.$1),
        frameWidth,
        frameHeight,
      );
    } finally {
      _releaseOutputs(outputs.$3);
    }
  }

  Future<img.Image?> extractBestCatCutout(
    img.Image source, {
    Detection? preferredTarget,
  }) async {
    final meta = await extractBestCatCutoutWithMeta(
      source,
      preferredTarget: preferredTarget,
    );
    return meta?.image;
  }

  Future<CatCutoutMeta?> extractBestCatCutoutWithMeta(
    img.Image source, {
    Detection? preferredTarget,
  }) async {
    final letterbox = _letterboxImage(source);
    final outputs = await _runInference(letterbox.input);
    if (outputs == null) return null;

    try {
      final candidates = _parseCandidates(outputs.$1);
      if (candidates.isEmpty) return null;

      final protos = _flattenProtos(outputs.$2);
      final best = _selectBestCandidate(
        candidates,
        protos,
        preferredTarget: preferredTarget,
      );
      final mask320 = _buildMask320(protos, best);
      final cutout = _applyMaskToSource(
        source: source,
        mask320: mask320,
        letterbox: letterbox,
        candidate: best,
      );
      return CatCutoutMeta(
        image: cutout,
        confidence: best.confidence,
      );
    } finally {
      _releaseOutputs(outputs.$3);
    }
  }

  Future<List<Detection>> detect(img.Image frame) async {
    final frameWidth = frame.width;
    final frameHeight = frame.height;
    final resized = img.copyResize(
      frame,
      width: inputSize,
      height: inputSize,
    );
    return detectFromInput(_preprocess(resized), frameWidth, frameHeight);
  }

  Future<(Object?, Object?, List<OrtValue?>)?> _runInference(
    Float32List input,
  ) async {
    final session = _session;
    if (session == null) return null;

    final inputTensor = OrtValueTensor.createTensorWithDataList(
      input,
      [1, 3, inputSize, inputSize],
    );

    List<OrtValue?>? outputs;
    try {
      outputs = await session.runAsync(
        OrtRunOptions(),
        {'images': inputTensor},
      );
      if (outputs == null || outputs.length < 2) return null;
      return (outputs[0]?.value, outputs[1]?.value, outputs);
    } finally {
      inputTensor.release();
    }
  }

  void _releaseOutputs(List<OrtValue?> outputs) {
    for (final output in outputs) {
      output?.release();
    }
  }

  _Letterbox _letterboxImage(img.Image source) {
    final scale = math.min(
      inputSize / source.width,
      inputSize / source.height,
    );
    final newW = (source.width * scale).round();
    final newH = (source.height * scale).round();
    final padX = (inputSize - newW) / 2;
    final padY = (inputSize - newH) / 2;

    final canvas = img.Image(width: inputSize, height: inputSize);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(
      canvas,
      img.copyResize(source, width: newW, height: newH),
      dstX: padX.round(),
      dstY: padY.round(),
    );

    return _Letterbox(
      scale: scale,
      padX: padX,
      padY: padY,
      input: _preprocess(canvas),
    );
  }

  Float32List _preprocess(img.Image image) {
    final size = inputSize;
    final input = Float32List(3 * size * size);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = image.getPixel(x, y);
        final offset = y * size + x;
        input[offset] = pixel.r / 255.0;
        input[size * size + offset] = pixel.g / 255.0;
        input[2 * size * size + offset] = pixel.b / 255.0;
      }
    }
    return input;
  }

  List<_SegmentCandidate> _parseCandidates(Object? rawOutput) {
    if (rawOutput is! List || rawOutput.isEmpty) return const [];

    final batch = rawOutput[0];
    if (batch is! List || batch.length < 5) return const [];

    final numClasses = batch.length - 4 - _maskCoeffs;
    if (numClasses < 1) return const [];

    final cxRow = batch[0];
    final cyRow = batch[1];
    final wRow = batch[2];
    final hRow = batch[3];
    if (cxRow is! List) return const [];

    final classRows = <List>[];
    for (int c = 0; c < numClasses; c++) {
      final row = batch[4 + c];
      if (row is! List) return const [];
      classRows.add(row);
    }

    final maskStart = 4 + numClasses;
    final maskRows = <List>[];
    for (int m = 0; m < _maskCoeffs; m++) {
      final row = batch[maskStart + m];
      if (row is! List) return const [];
      maskRows.add(row);
    }

    final candidates = <_SegmentCandidate>[];
    for (int i = 0; i < classRows[0].length; i++) {
      var bestClass = 0;
      var bestScore = _asDouble(classRows[0][i]);
      for (int c = 1; c < numClasses; c++) {
        final score = _asDouble(classRows[c][i]);
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }

      if (bestClass != catClassId || bestScore < confThreshold) continue;

      final coeffs = Float32List(_maskCoeffs);
      for (int m = 0; m < _maskCoeffs; m++) {
        coeffs[m] = _asDouble(maskRows[m][i]);
      }

      candidates.add(
        _SegmentCandidate(
          cx: _asDouble(cxRow[i]),
          cy: _asDouble(cyRow[i]),
          w: _asDouble(wRow[i]),
          h: _asDouble(hRow[i]),
          confidence: bestScore,
          maskCoeffs: coeffs,
        ),
      );
    }

    return _nonMaxSuppressionCandidates(candidates);
  }

  List<Detection> _candidatesToDetections(
    List<_SegmentCandidate> candidates,
    int frameWidth,
    int frameHeight,
  ) {
    if (candidates.isEmpty) return const [];

    final scaleX = frameWidth / inputSize;
    final scaleY = frameHeight / inputSize;

    return candidates
        .map(
          (candidate) => Detection(
            left: ((candidate.x1 * scaleX) / frameWidth).clamp(0.0, 1.0),
            top: ((candidate.y1 * scaleY) / frameHeight).clamp(0.0, 1.0),
            right: ((candidate.x2 * scaleX) / frameWidth).clamp(0.0, 1.0),
            bottom: ((candidate.y2 * scaleY) / frameHeight).clamp(0.0, 1.0),
            confidence: candidate.confidence,
          ),
        )
        .toList();
  }

  Float32List _flattenProtos(Object? rawProto) {
    final flat = Float32List(_maskCoeffs * _protoSize * _protoSize);
    if (rawProto is! List || rawProto.isEmpty) return flat;

    final batch = rawProto[0];
    if (batch is List && batch.isNotEmpty && batch[0] is List) {
      var index = 0;
      for (int c = 0; c < _maskCoeffs; c++) {
        final channel = batch[c];
        if (channel is! List) continue;
        for (int y = 0; y < _protoSize; y++) {
          final row = channel[y];
          if (row is! List) continue;
          for (int x = 0; x < _protoSize; x++) {
            flat[index++] = _asDouble(row[x]);
          }
        }
      }
      return flat;
    }

    _flattenNested(batch, flat, 0);
    return flat;
  }

  int _flattenNested(Object? node, Float32List flat, int index) {
    if (node is num && index < flat.length) {
      flat[index++] = node.toDouble();
      return index;
    }
    if (node is List) {
      for (final child in node) {
        index = _flattenNested(child, flat, index);
        if (index >= flat.length) break;
      }
    }
    return index;
  }

  Float32List _buildMask320(Float32List protos, _SegmentCandidate candidate) {
    final mask80 = Float32List(_protoSize * _protoSize);
    for (int y = 0; y < _protoSize; y++) {
      for (int x = 0; x < _protoSize; x++) {
        var sum = 0.0;
        final protoOffset = y * _protoSize + x;
        for (int c = 0; c < _maskCoeffs; c++) {
          sum += candidate.maskCoeffs[c] *
              protos[c * _protoSize * _protoSize + protoOffset];
        }
        mask80[protoOffset] = _sigmoid(sum);
      }
    }

    final mask320 = Float32List(inputSize * inputSize);
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        if (x < candidate.x1 ||
            x >= candidate.x2 ||
            y < candidate.y1 ||
            y >= candidate.y2) {
          continue;
        }

        final mx = x / 4;
        final my = y / 4;
        mask320[y * inputSize + x] = _sampleMask80(mask80, mx, my);
      }
    }
    return mask320;
  }

  double _sampleMask80(Float32List mask80, double x, double y) {
    final x0 = x.floor().clamp(0, _protoSize - 1);
    final y0 = y.floor().clamp(0, _protoSize - 1);
    final x1 = (x0 + 1).clamp(0, _protoSize - 1);
    final y1 = (y0 + 1).clamp(0, _protoSize - 1);
    final tx = x - x0;
    final ty = y - y0;

    final v00 = mask80[y0 * _protoSize + x0];
    final v10 = mask80[y0 * _protoSize + x1];
    final v01 = mask80[y1 * _protoSize + x0];
    final v11 = mask80[y1 * _protoSize + x1];

    final top = v00 + (v10 - v00) * tx;
    final bottom = v01 + (v11 - v01) * tx;
    return top + (bottom - top) * ty;
  }

  img.Image _applyMaskToSource({
    required img.Image source,
    required Float32List mask320,
    required _Letterbox letterbox,
    required _SegmentCandidate candidate,
  }) {
    final rgba = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 4,
    );

    var minX = source.width;
    var minY = source.height;
    var maxX = 0;
    var maxY = 0;

    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final lx = x * letterbox.scale + letterbox.padX;
        final ly = y * letterbox.scale + letterbox.padY;
        if (lx < 0 ||
            ly < 0 ||
            lx >= inputSize - 1 ||
            ly >= inputSize - 1 ||
            lx < candidate.x1 ||
            lx >= candidate.x2 ||
            ly < candidate.y1 ||
            ly >= candidate.y2) {
          rgba.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }

        final alpha = _sampleMask320(mask320, lx, ly);
        if (alpha < maskThreshold) {
          rgba.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }

        final pixel = source.getPixel(x, y);
        final alphaByte = (alpha * 255).round().clamp(0, 255);
        rgba.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          alphaByte,
        );

        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (maxX <= minX || maxY <= minY) return rgba;

    return img.copyCrop(
      rgba,
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
  }

  double _sampleMask320(Float32List mask320, double x, double y) {
    final x0 = x.floor().clamp(0, inputSize - 1);
    final y0 = y.floor().clamp(0, inputSize - 1);
    final x1 = (x0 + 1).clamp(0, inputSize - 1);
    final y1 = (y0 + 1).clamp(0, inputSize - 1);
    final tx = x - x0;
    final ty = y - y0;

    final v00 = mask320[y0 * inputSize + x0];
    final v10 = mask320[y0 * inputSize + x1];
    final v01 = mask320[y1 * inputSize + x0];
    final v11 = mask320[y1 * inputSize + x1];

    final top = v00 + (v10 - v00) * tx;
    final bottom = v01 + (v11 - v01) * tx;
    return top + (bottom - top) * ty;
  }

  double _sigmoid(double value) => 1 / (1 + math.exp(-value));

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  _SegmentCandidate _selectBestCandidate(
    List<_SegmentCandidate> candidates,
    Float32List protos, {
    Detection? preferredTarget,
  }) {
    if (candidates.length == 1) return candidates.first;

    _SegmentCandidate? best;
    var bestScore = double.negativeInfinity;

    for (final candidate in candidates) {
      final maskQuality = _maskQualityScore(protos, candidate);
      final areaScore =
          (candidate.w * candidate.h) / (inputSize * inputSize);

      var score = candidate.confidence * 0.55 +
          maskQuality * 0.30 +
          areaScore.clamp(0.0, 0.35) * 0.15;

      if (preferredTarget != null) {
        final overlap =
            _candidateIoUNormalized(candidate, preferredTarget);
        score += overlap * 0.45;
      }

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best ?? candidates.first;
  }

  double _maskQualityScore(Float32List protos, _SegmentCandidate candidate) {
    final mask320 = _buildMask320(protos, candidate);
    final xStart = candidate.x1.ceil().clamp(0, inputSize - 1);
    final yStart = candidate.y1.ceil().clamp(0, inputSize - 1);
    final xEnd = candidate.x2.floor().clamp(0, inputSize);
    final yEnd = candidate.y2.floor().clamp(0, inputSize);

    var sum = 0.0;
    var count = 0;
    for (int y = yStart; y < yEnd; y++) {
      for (int x = xStart; x < xEnd; x++) {
        sum += mask320[y * inputSize + x];
        count++;
      }
    }
    if (count == 0) return 0;
    return sum / count;
  }

  double _candidateIoUNormalized(
    _SegmentCandidate candidate,
    Detection target,
  ) {
    final left = candidate.x1 / inputSize;
    final top = candidate.y1 / inputSize;
    final right = candidate.x2 / inputSize;
    final bottom = candidate.y2 / inputSize;

    final x1 = math.max(left, target.left);
    final y1 = math.max(top, target.top);
    final x2 = math.min(right, target.right);
    final y2 = math.min(bottom, target.bottom);

    final intersection = (x2 - x1).clamp(0.0, 1.0) * (y2 - y1).clamp(0.0, 1.0);
    if (intersection <= 0) return 0;

    final areaA = (right - left) * (bottom - top);
    final areaB = (target.right - target.left) * (target.bottom - target.top);
    final union = areaA + areaB - intersection;
    if (union <= 0) return 0;
    return intersection / union;
  }

  List<_SegmentCandidate> _nonMaxSuppressionCandidates(
    List<_SegmentCandidate> candidates,
  ) {
    final sorted = List<_SegmentCandidate>.from(candidates)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <_SegmentCandidate>[];
    for (final candidate in sorted) {
      var overlaps = false;
      for (final existing in kept) {
        if (_candidateIou(candidate, existing) > iouThreshold) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) kept.add(candidate);
    }
    return kept;
  }

  double _candidateIou(_SegmentCandidate a, _SegmentCandidate b) {
    final x1 = math.max(a.x1, b.x1);
    final y1 = math.max(a.y1, b.y1);
    final x2 = math.min(a.x2, b.x2);
    final y2 = math.min(a.y2, b.y2);

    final intersection = (x2 - x1).clamp(0.0, double.infinity) *
        (y2 - y1).clamp(0.0, double.infinity);
    if (intersection <= 0) return 0;

    final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
    final union = areaA + areaB - intersection;
    if (union <= 0) return 0;
    return intersection / union;
  }
}
