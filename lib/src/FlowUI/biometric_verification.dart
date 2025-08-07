import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Verification/verification.dart';
import '../widgets/biometric_camera_view.dart';

class BiometricVerificationScreen extends StatefulWidget {
  const BiometricVerificationScreen({super.key});

  @override
  State<BiometricVerificationScreen> createState() => _BiometricVerificationScreenState();
}

class _BiometricVerificationScreenState extends State<BiometricVerificationScreen> {
  final _cameraViewKey = GlobalKey<BiometricCameraViewState>();
  bool _isVerifying = false;

  Future<void> _onPictureCaptured(XFile image) async {
    final get = context.read<VerificationProvider>();

    final success = await get.submitBiometricVerification(context, image: image);

    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Verification failed.'),
        backgroundColor: Colors.red,
      ));

      setState(() => _isVerifying = false);
      await _cameraViewKey.currentState?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 600,
                child: BiometricCameraView(
                  key: _cameraViewKey,
                  onPictureCaptured: (image) {
                    if (!_isVerifying) {
                      setState(() => _isVerifying = true);
                    }
                    _onPictureCaptured(image);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
