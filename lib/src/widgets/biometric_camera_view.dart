import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/service.dart';
import '../Verification/verification.dart';

class BiometricCameraView extends StatefulWidget {
  final Function(XFile image) onPictureCaptured;
  final VoidCallback? onCaptureFailed;
  final double? height;

  const BiometricCameraView({
    super.key,
    required this.onPictureCaptured,
    this.onCaptureFailed,
    this.height,
  });

  @override
  BiometricCameraViewState createState() => BiometricCameraViewState();
}

class BiometricCameraViewState extends State<BiometricCameraView> with WidgetsBindingObserver {
  final _cameraService = FaceCameraService();
  List<StreamSubscription>? _subscriptions;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isSwitchingCamera = false;
  String _instructionText = '';
  String? _errorText;
  CustomPaint? _customPaint;
  CameraPropertiesState? _cameraProps;
  bool get _isInteractionDisabled =>
      _isCapturing || _isSwitchingCamera || context.read<VerificationProvider>().isLoading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscriptions?.forEach((s) => s.cancel());
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _cameraService.isDisposed) return;
    if (state == AppLifecycleState.resumed) {
      _cameraService.resume();
    } else {
      _cameraService.pause();
    }
  }

  Future<void> resumeCamera() async {
    if (mounted) {
      setState(() => _isCapturing = false);
      await _cameraService.resume();
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _isCameraInitialized = false;
      _errorText = null;
    });
    _subscriptions ??= [
      _cameraService.faceDetectionStream.listen(_onFaceDetectionStateChanged),
      _cameraService.propertiesStream.listen((props) => setState(() => _cameraProps = props)),
      _cameraService.errorStream.listen((error) => setState(() => _errorText = error)),
      _cameraService.isSwitchingStream.listen((isSwitching) {
        if (mounted) setState(() => _isSwitchingCamera = isSwitching);
      }),
    ];
    await _cameraService.initialize(CameraLensDirection.front);
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  void _onFaceDetectionStateChanged(FaceDetectionState state) {
    if (!mounted || _isInteractionDisabled) return;
    setState(() {
      _customPaint = state.customPaint;
      switch (state.status) {
        case FaceDetectionStatus.noFaceDetected:
          _instructionText = 'Align your face in the frame';
          break;
        case FaceDetectionStatus.faceTooSmall:
          _instructionText = 'Move closer';
          break;
        case FaceDetectionStatus.holdStill:
          _instructionText = 'Hold still...';
          break;
        case FaceDetectionStatus.captureReady:
          _instructionText = 'Perfect!';
          _autoCapture();
          break;
      }
    });
  }

  Future<void> _autoCapture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    final image = await _cameraService.takePicture();

    if (image != null && mounted) {
      setState(() => _isCapturing = false);
      widget.onPictureCaptured(image);
    } else if (mounted) {
      widget.onCaptureFailed?.call();
      await resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorText != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Error: $_errorText', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _initialize, child: const Text('Try Again')),
        ]),
      );
    }
    if (!_isCameraInitialized || _isSwitchingCamera) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          CameraPreview(_cameraService.cameraController!),
          if (_customPaint != null) _customPaint!,
          _buildUIOverlay(),
          if (_isCapturing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ]),
      ),
    );
  }

  Widget _buildUIOverlay() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: Text(_instructionText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        if (_cameraService.canSwitchCameras)
          Positioned(
            top: 10,
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
              onPressed: _isInteractionDisabled ? null : _cameraService.switchCamera,
            ),
          ),
        if (_cameraProps != null)
          Positioned(
            bottom: 0,
            left: 20,
            right: 20,
            child: Slider(
              value: _cameraProps!.currentZoom,
              min: _cameraProps!.minZoom,
              max: _cameraProps!.maxZoom,
              activeColor: Colors.white,
              inactiveColor: Colors.white30,
              onChanged: _isInteractionDisabled ? null : _cameraService.setZoomLevel,
            ),
          ),
      ],
    );
  }
}
