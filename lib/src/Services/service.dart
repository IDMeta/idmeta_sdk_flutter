import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../FlowUI/Utils/detector.dart';
import 'input_converter.dart';

enum FaceDetectionStatus { noFaceDetected, faceTooSmall, holdStill, captureReady }

class FaceDetectionState {
  final FaceDetectionStatus status;
  final CustomPaint? customPaint;
  FaceDetectionState(this.status, {this.customPaint});
}

class CameraPropertiesState {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final double currentExposure;
  final double minExposure;
  final double maxExposure;

  CameraPropertiesState({
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.currentExposure,
    required this.minExposure,
    required this.maxExposure,
  });
}

class FaceCameraService {
  CameraController? _controller;
  CameraController? get cameraController => _controller;

  List<CameraDescription> _cameras = [];
  int _cameraIndex = -1;

  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions(enableLandmarks: true));
  bool _isProcessingImage = false;
  bool _canProcess = true;
  bool _isSwitchingCamera = false;

  double _currentZoom = 1.0;
  double _currentExposure = 0.0;

  Rect? _lastFaceRect;
  int _stableFrameCount = 0;
  final int _requiredStableFrames = 10;
  final double _allowedMovement = 15.0;
  final double _minFaceArea = 15000.0;

  final StreamController<FaceDetectionState> _faceDetectionController = StreamController.broadcast();
  Stream<FaceDetectionState> get faceDetectionStream => _faceDetectionController.stream;

  final StreamController<CameraPropertiesState> _propertiesController = StreamController.broadcast();
  Stream<CameraPropertiesState> get propertiesStream => _propertiesController.stream;

  final StreamController<String> _errorController = StreamController.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  final StreamController<bool> _isSwitchingController = StreamController.broadcast();
  Stream<bool> get isSwitchingStream => _isSwitchingController.stream;

  bool get canSwitchCameras => _cameras.length > 1;

  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  Future<void> initialize(CameraLensDirection initialDirection) async {
    if (_isDisposed) return;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception("No cameras found on this device.");
      _cameraIndex = _cameras.indexWhere((cam) => cam.lensDirection == initialDirection);
      if (_cameraIndex == -1) _cameraIndex = 0;
      await _startLiveFeed();
    } catch (e) {
      debugPrint("FaceCameraService Initialization Error: $e");
      if (!_errorController.isClosed) _errorController.add(e.toString());
    }
  }

  Future<void> _startLiveFeed() async {
    if (_isDisposed || _cameraIndex == -1) return;

    final oldController = _controller;
    if (oldController != null) {
      await oldController.stopImageStream().catchError((_) {});
      await oldController.dispose();
    }

    final camera = _cameras[_cameraIndex];

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      debugPrint("Error initializing camera controller: $e");
      if (!_errorController.isClosed) _errorController.add("Failed to initialize camera.");
      return;
    }

    _currentZoom = 1.0;
    _currentExposure = 0.0;

    await _updateAndBroadcastProperties();

    _canProcess = true;
    _stableFrameCount = 0;
    _lastFaceRect = null;

    await _controller!.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) {
    if (_isDisposed || !_canProcess || _isProcessingImage) return;
    _isProcessingImage = true;

    final inputImage = inputImageFromCameraImage(image, _controller!, _cameras[_cameraIndex]);
    if (inputImage == null) {
      _isProcessingImage = false;
      return;
    }

    _faceDetector.processImage(inputImage).then((faces) {
      _handleFaceDetectionResult(faces, inputImage);
      _isProcessingImage = false;
    }).catchError((_) {
      _isProcessingImage = false;
    });
  }

  void _handleFaceDetectionResult(List<Face> faces, InputImage inputImage) {
    if (_isDisposed) return;

    FaceDetectionStatus currentStatus = FaceDetectionStatus.noFaceDetected;

    if (faces.isNotEmpty) {
      final face = faces.first;
      final currentRect = face.boundingBox;

      if (_lastFaceRect != null && (currentRect.center - _lastFaceRect!.center).distance < _allowedMovement) {
        _stableFrameCount++;
      } else {
        _stableFrameCount = 0;
      }

      _lastFaceRect = currentRect;

      if ((currentRect.width * currentRect.height) < _minFaceArea) {
        currentStatus = FaceDetectionStatus.faceTooSmall;
        _stableFrameCount = 0;
      } else if (_stableFrameCount < _requiredStableFrames) {
        currentStatus = FaceDetectionStatus.holdStill;
      } else {
        currentStatus = FaceDetectionStatus.captureReady;
      }
    } else {
      _stableFrameCount = 0;
      _lastFaceRect = null;
    }

    final painter = FaceDetectorPainter(
      faces,
      inputImage.metadata!.size,
      inputImage.metadata!.rotation,
      _cameras[_cameraIndex].lensDirection,
    );

    if (!_faceDetectionController.isClosed) {
      _faceDetectionController.add(FaceDetectionState(currentStatus, customPaint: CustomPaint(painter: painter)));
    }
  }

  Future<void> _updateAndBroadcastProperties() async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;

    try {
      final props = await Future.wait([
        _controller!.getMinZoomLevel(),
        _controller!.getMaxZoomLevel(),
        _controller!.getMinExposureOffset(),
        _controller!.getMaxExposureOffset(),
      ]);

      if (!_propertiesController.isClosed) {
        _propertiesController.add(CameraPropertiesState(
          minZoom: props[0],
          maxZoom: props[1],
          minExposure: props[2],
          maxExposure: props[3],
          currentZoom: _currentZoom,
          currentExposure: _currentExposure,
        ));
      }
    } catch (e) {
      debugPrint("Could not update camera properties: $e");
    }
  }

  Future<XFile?> takePicture() async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      return null;
    }
    _canProcess = false;
    await _controller!.pausePreview();
    await _controller!.stopImageStream();
    return await _controller!.takePicture();
  }

  Future<void> switchCamera() async {
    if (_isDisposed || !canSwitchCameras || _isSwitchingCamera) return;

    _isSwitchingCamera = true;
    if (!_isSwitchingController.isClosed) _isSwitchingController.add(true);

    try {
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      await _startLiveFeed();
    } catch (e) {
      debugPrint("Error switching camera: $e");
      if (!_errorController.isClosed) _errorController.add(e.toString());
    } finally {
      _isSwitchingCamera = false;
      if (!_isSwitchingController.isClosed) _isSwitchingController.add(false);
    }
  }

  Future<void> setZoomLevel(double zoom) async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;
    _currentZoom = zoom;
    await _controller!.setZoomLevel(zoom);
    await _updateAndBroadcastProperties();
  }

  Future<void> setExposureOffset(double exposure) async {
    if (_isDisposed || _controller == null || !_controller!.value.isInitialized) return;
    _currentExposure = exposure;
    await _controller!.setExposureOffset(exposure);
    await _updateAndBroadcastProperties();
  }

  Future<void> pause() async {
    if (_isDisposed || _controller == null || !_controller!.value.isStreamingImages) return;
    _canProcess = false;
    await _controller!.stopImageStream();
  }

  Future<void> resume() async {
    if (_isDisposed || _controller == null || _controller!.value.isStreamingImages) return;

    _canProcess = true;
    await _controller!.startImageStream(_processCameraImage);
  }

  void dispose() {
    _isDisposed = true;
    _canProcess = false;
    _controller?.dispose();
    _faceDetector.close();
    _faceDetectionController.close();
    _propertiesController.close();
    _errorController.close();
    _isSwitchingController.close();
  }
}
