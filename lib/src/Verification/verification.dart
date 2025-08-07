import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/service.dart';
import '../Models/flow_sate.dart';
import '../Models/settings.dart';
import '../core/repository.dart';
import '../widgets/loader.dart';

class VerificationProvider with ChangeNotifier {
  final VerificationRepository _repository;
  final ApiService _apiService;

  VerificationProvider({required VerificationRepository repository, required ApiService apiService})
      : _repository = repository,
        _apiService = apiService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool _isStartingFlow = false;
  bool get isStartingFlow => _isStartingFlow;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _isFlowCompleted = false;
  bool get isFlowCompleted => _isFlowCompleted;

  DesignSettings? _designSettings;
  DesignSettings? get designSettings => _designSettings;
  VerificationFlowState get flowState => _repository.flowState;

  Future<T> _runTask<T>(Future<T> Function() task) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      return await task();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void initialize({required String userToken, required String templateId}) {
    _repository.initialize(userToken: userToken, templateId: templateId);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _designSettings = await _apiService.getDesignSettings(templateId: flowState.templateId!);
    } catch (e) {
      _errorMessage = "Failed to load initial settings.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startVerificationFlow() async {
    _isStartingFlow = true;
    notifyListeners();
    try {
      await _repository.startVerification();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isStartingFlow = false;
      notifyListeners();
    }
  }

  Future<bool> submitDocument(BuildContext context, {required File front, File? back}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitDocument(front, back));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitFaceCompare(BuildContext context, {required XFile liveSelfie, XFile? manualImage2}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitFaceCompare(liveSelfie: liveSelfie, manualImage2: manualImage2));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitBiometricRegistration(BuildContext context,
      {required String username, required XFile image}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitBiometricRegistration(username: username, image: image));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitBiometricVerification(BuildContext context, {required XFile image}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitBiometricVerification(image: image));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAmlData(BuildContext context, {required String name, String? dob, String? gender}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAmlData(name: name, dob: dob, gender: gender));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitDukcapilData(BuildContext context,
      {required String name, required String dob, required String nik}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitDukcapilData(name: name, dob: dob, nik: nik));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitDukcapilFaceMatchData(BuildContext context,
      {required String name, required String dob, required String nik, required File image}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitDukcapilFaceMatchData(name: name, dob: dob, nik: nik, image: image));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhDrivingLicenseData(BuildContext context,
      {required String licenseNumber, required String expiryDate, required String serialNumber}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhDrivingLicenseData(
          licenseNumber: licenseNumber, expiryDate: expiryDate, serialNumber: serialNumber));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhSocialSecurityData(BuildContext context, {required String sssNumber}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhSocialSecurityData(sssNumber: sssNumber));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuPassportData(BuildContext context,
      {required String lastName,
      required String givenName,
      required String dob,
      required String gender,
      required String passportNumber}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuPassportData(
          lastName: lastName, givenName: givenName, dob: dob, gender: gender, passportNumber: passportNumber));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhPrcData(BuildContext context,
      {required String profession, String? firstName, String? lastName, String? licenseNo, String? dob}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhPrcData(
          profession: profession, firstName: firstName, lastName: lastName, licenseNo: licenseNo, dob: dob));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitQrCode(BuildContext context, {required Map<String, dynamic> qrPayload}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitQrCode(qrPayload: qrPayload));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<String?> sendSmsOtp(BuildContext context, {required String phoneNumber, required String countryCode}) async {
    showLoader(context);
    try {
      return await _runTask(() => _repository.sendSmsOtp(phoneNumber: phoneNumber, countryCode: countryCode));
    } catch (_) {
      return null;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> verifySmsOtp(BuildContext context, {required String otp, required String referenceId}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.verifySmsOtp(otp: otp, referenceId: referenceId));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<String?> sendEmailOtp(BuildContext context, {required String email}) async {
    showLoader(context);
    try {
      return await _runTask(() => _repository.sendEmailOtp(email: email));
    } catch (_) {
      return null;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> verifyEmailOtp(BuildContext context, {required String otp, required String referenceId}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.verifyEmailOtp(otp: otp, referenceId: referenceId));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitCustomDocument(BuildContext context, {required File documentFile}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitCustomDocument(documentFile: documentFile));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhNbiClearance(BuildContext context, {required String clearanceNo}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhNbiClearance(clearanceNo: clearanceNo));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhNationalPolice(BuildContext context,
      {required String surname, required String clearanceNo}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhNationalPolice(surname: surname, clearanceNo: clearanceNo));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitVoiceLiveness(BuildContext context, {required File audioFile}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitVoiceLiveness(audioFile: audioFile));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> finalizeVerification(BuildContext context) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.finalizeVerification());
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  void nextScreen(BuildContext context) {
    if (flowState.isLastStep) {
      debugPrint("Last step completed. Finalizing verification...");
      finalizeVerification(context).then((success) {
        if (!context.mounted) return;
        if (success) {
          _isFlowCompleted = true;
          notifyListeners();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage ?? 'Failed to finalize verification.'),
            backgroundColor: Colors.red,
          ));
        }
      });
    } else {
      _repository.nextStep();
      notifyListeners();
    }
  }

  void previousScreen() {
    _repository.previousStep();
    notifyListeners();
  }
}
