import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

class Coordinate extends Struct {
  factory Coordinate.allocate(double x, double y) => malloc<Coordinate>().ref
    ..x = x
    ..y = y;

  @Double()
  double? x;

  @Double()
  double? y;
}

class NativeDetectionResult extends Struct {
  factory NativeDetectionResult.allocate(
          Pointer<Coordinate> topLeft,
          Pointer<Coordinate> topRight,
          Pointer<Coordinate> bottomLeft,
          Pointer<Coordinate> bottomRight) =>
      malloc<NativeDetectionResult>().ref
        ..topLeft = topLeft
        ..topRight = topRight
        ..bottomLeft = bottomLeft
        ..bottomRight = bottomRight;

  Pointer<Coordinate>? topLeft;
  Pointer<Coordinate>? topRight;
  Pointer<Coordinate>? bottomLeft;
  Pointer<Coordinate>? bottomRight;
}

class EdgeDetectionResult {
  EdgeDetectionResult({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  Offset? topLeft;
  Offset? topRight;
  Offset? bottomLeft;
  Offset? bottomRight;
}

typedef DetectEdgesFunction = Pointer<NativeDetectionResult> Function(
    Pointer<Utf8> imagePath);

// ignore: camel_case_types
typedef process_image_function = Int8 Function(
    Pointer<Utf8> imagePath,
    Double topLeftX,
    Double topLeftY,
    Double topRightX,
    Double topRightY,
    Double bottomLeftX,
    Double bottomLeftY,
    Double bottomRightX,
    Double bottomRightY);

typedef ProcessImageFunction = int Function(
    Pointer<Utf8> imagePath,
    double topLeftX,
    double topLeftY,
    double topRightX,
    double topRightY,
    double bottomLeftX,
    double bottomLeftY,
    double bottomRightX,
    double bottomRightY);

// https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart

class EdgeDetection {
  static Future<EdgeDetectionResult> detectEdges(String path) async {
    final DynamicLibrary nativeEdgeDetection = _getDynamicLibrary();

    final DetectEdgesFunction detectEdges = nativeEdgeDetection
        .lookup<NativeFunction<DetectEdgesFunction>>('detect_edges')
        .asFunction<DetectEdgesFunction>();

    final NativeDetectionResult detectionResult =
        detectEdges(path.toNativeUtf8()).ref;

    return EdgeDetectionResult(
        topLeft: Offset(detectionResult.topLeft!.ref.x as double,
            detectionResult.topLeft!.ref.y as double),
        topRight: Offset(detectionResult.topRight!.ref.x as double,
            detectionResult.topRight!.ref.y as double),
        bottomLeft: Offset(detectionResult.bottomLeft!.ref.x as double,
            detectionResult.bottomLeft!.ref.y as double),
        bottomRight: Offset(detectionResult.bottomRight!.ref.x as double,
            detectionResult.bottomRight!.ref.y as double));
  }

  static Future<bool> processImage(
      String path, EdgeDetectionResult result) async {
    final DynamicLibrary nativeEdgeDetection = _getDynamicLibrary();

    final ProcessImageFunction processImage = nativeEdgeDetection
        .lookup<NativeFunction<process_image_function>>('process_image')
        .asFunction<ProcessImageFunction>();

    return processImage(
            path.toNativeUtf8(),
            result.topLeft!.dx,
            result.topLeft!.dy,
            result.topRight!.dx,
            result.topRight!.dy,
            result.bottomLeft!.dx,
            result.bottomLeft!.dy,
            result.bottomRight!.dx,
            result.bottomRight!.dy) ==
        1;
  }

  static DynamicLibrary _getDynamicLibrary() {
    final DynamicLibrary nativeEdgeDetection = Platform.isAndroid
        ? DynamicLibrary.open('libnative_edge_detection.so')
        : DynamicLibrary.process();
    return nativeEdgeDetection;
  }
}
