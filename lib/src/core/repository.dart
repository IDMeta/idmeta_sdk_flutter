import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../Models/flow_sate.dart';
import '../api/service.dart';

class VerificationRepository {
  final ApiService _apiService;
  VerificationFlowState _flowState = VerificationFlowState.initial();
  VerificationFlowState get flowState => _flowState;

  VerificationRepository({required ApiService apiService}) : _apiService = apiService;

  void initialize({required String userToken, required String templateId}) {
    _flowState = VerificationFlowState.initial().copyWith(userToken: userToken, templateId: templateId);
  }

  Future<void> startVerification() async {
    if (_flowState.userToken == null || _flowState.templateId == null) {
      throw Exception('Repository not initialized.');
    }
    final response =
        await _apiService.createVerification(userToken: _flowState.userToken!, templateId: _flowState.templateId!);
    _updateStateFromVerificationResponse(response);
  }

  void _updateStateFromVerificationResponse(Map<String, dynamic> response) {
    final verificationId = response['verification']?['id']?.toString();
    if (verificationId == null) throw ApiException('Verification ID not found in response.');

    List<String> plans = (response['plans'] as List? ?? []).map((p) => p['plan'].toString()).toList();
    Map<String, Map<String, dynamic>> toolSettings = {};
    if (response['tool_settings'] is List) {
      for (var setting in (response['tool_settings'] as List)) {
        if (setting is Map<String, dynamic> && setting['plan'] is String) {
          toolSettings[setting['plan']] = setting['config'] ?? {};
        }
      }
    }

    _handleAutomatedSteps(plans, toolSettings);

    _flowState = _flowState.copyWith(
      verificationId: verificationId,
      allSteps: plans,
      toolSettings: toolSettings,
      currentStepIndex: 0,
      history: [],
    );
  }

  void _handleAutomatedSteps(List<String> plans, Map<String, Map<String, dynamic>> toolSettings) {
    const autoCheckPlans = {
      'business_aml': 'autoRunAml',
      'dukcapil': 'autoRunDukcapil',
      'dukcapil_facematch': 'autoRunDukcapilFace',
      'philippines_driving_license': 'autoRunPhDriving',
      'philippines_social_security': 'autoRunPhSocialSecurity',
      'australia_passport': 'autoRunAustraliaPassport',
    };

    if (plans.contains('document_verification')) {
      for (final entry in autoCheckPlans.entries) {
        final planKey = entry.key;
        final configFlag = entry.value;
        if (plans.contains(planKey)) {
          toolSettings['document_verification'] = {...toolSettings['document_verification'] ?? {}, configFlag: true};
          debugPrint("Configuration found to automate '$planKey' step post-document verification.");
        }
      }
    }
  }

  Future<void> submitDocument(File front, File? back) async {
    final response = await _apiService.documentVerification(
        userToken: _flowState.userToken!,
        templateId: _flowState.templateId!,
        verificationId: _flowState.verificationId!,
        imageFile1: front,
        imageFile2: back);

    _updateStateFromDocumentResponse(response);
    await _runAllAutomatedChecksPostDocument();
  }

  void _updateStateFromDocumentResponse(Map<String, dynamic> response) {
    final rawResult = response['result'];
    final isExtraction = rawResult?['data']?['extractionResult'] != null;
    final extractionResult = isExtraction ? rawResult['data']['extractionResult'] : rawResult['result'];

    if (extractionResult != null) {
      final newData = Map<String, dynamic>.from(_flowState.collectedData);

      String? getField(String key) {
        if (isExtraction) return extractionResult[key]?['latin']?.toString();
        return extractionResult[key]?.toString();
      }

      newData['fullName'] = getField('fullName');
      newData['firstName'] = getField('firstName');
      newData['lastName'] = getField('lastName');
      newData['docNumber'] = getField('documentNumber');
      newData['sex'] = getField('sex');
      newData['faceImageBase64'] = extractionResult['faceImageBase64']?.toString();

      if (extractionResult['mrzData'] != null) {
        newData['mrzData'] = extractionResult['mrzData'];
      }

      final dob = extractionResult['dateOfBirth'];
      if (dob is Map && dob['year'] != null) {
        newData['dob'] = DateFormat('yyyy-MM-dd').format(DateTime(dob['year'], dob['month'], dob['day']));
      }
      final doe = extractionResult['dateOfExpiry'];
      if (doe is Map && doe['year'] != null) {
        newData['doe'] = DateFormat('yyyy-MM-dd').format(DateTime(doe['year'], doe['month'], doe['day']));
      }

      _flowState = _flowState.copyWith(collectedData: newData);
    }
  }

  Future<void> _runAllAutomatedChecksPostDocument() async {
    final docSettings = _flowState.toolSettings['document_verification'] ?? {};
    final data = _flowState.collectedData;
    List<String> plansToProcess = List.from(_flowState.allSteps);

    if (plansToProcess.contains('business_aml') && docSettings['autoRunAml'] == true) {
      final String? name = data['fullName'] ?? data['firstName'];
      if (name != null && name.isNotEmpty) {
        try {
          await submitAmlData(name: name, dob: data['dob'], gender: data['sex'] ?? 'any');
          debugPrint("✅ Automated AML check successful.");
          plansToProcess.remove('business_aml');
        } catch (e) {
          debugPrint("⚠️ Automated AML check failed: $e.");
        }
      }
    }

    if (plansToProcess.contains('dukcapil') && docSettings['autoRunDukcapil'] == true) {
      final String? name = data['fullName'] ?? data['firstName'];
      final String? nik = data['docNumber'];
      final String? dob = data['dob'];
      if (name != null && name.isNotEmpty && nik != null && dob != null && nik.length == 16) {
        try {
          await submitDukcapilData(name: name, nik: nik, dob: dob);
          debugPrint("✅ Automated Dukcapil check successful.");
          plansToProcess.remove('dukcapil');
        } catch (e) {
          debugPrint("⚠️ Automated Dukcapil check failed: $e.");
        }
      } else {
        debugPrint("⚠️ Invalid data for Dukcapil check.");
      }
    }

    if (plansToProcess.contains('dukcapil_facematch') && docSettings['autoRunDukcapilFace'] == true) {
      debugPrint("⚠️ Dukcapil Face Match cannot be automated post-document scan without a live selfie.");
    }

    if (plansToProcess.contains('philippines_driving_license') && docSettings['autoRunPhDriving'] == true) {
      final String? licenseNo = data['docNumber'];
      if (licenseNo != null && licenseNo.replaceAll("-", "").length == 11) {
        try {
          await submitPhDrivingLicenseData(licenseNumber: licenseNo, expiryDate: data['doe'] ?? "", serialNumber: "");
          debugPrint("✅ Automated PH Driving License check successful.");
          plansToProcess.remove('philippines_driving_license');
        } catch (e) {
          debugPrint("⚠️ Automated PH Driving License check failed: $e.");
        }
      } else {
        debugPrint("⚠️ Invalid format for PH Driving License.");
      }
    }

    if (plansToProcess.contains('philippines_social_security') && docSettings['autoRunPhSocialSecurity'] == true) {
      final String? sssNo = data['docNumber'];
      if (sssNo != null && sssNo.replaceAll("-", "").length == 10) {
        try {
          await submitPhSocialSecurityData(sssNumber: sssNo);
          debugPrint("✅ Automated PH Social Security check successful.");
          plansToProcess.remove('philippines_social_security');
        } catch (e) {
          debugPrint("⚠️ Automated PH Social Security check failed: $e.");
        }
      } else {
        debugPrint("⚠️ Invalid format for SSS number.");
      }
    }

    if (plansToProcess.contains('australia_passport') && docSettings['autoRunAustraliaPassport'] == true) {
      final mrzData = data['mrzData'] as Map<String, dynamic>?;
      if (mrzData != null && mrzData['documentType'] == 'PASSPORT') {
        try {
          await submitAuPassportData(
            lastName: data['lastName'] ?? "",
            givenName: data['firstName'] ?? "",
            dob: data['dob'] ?? "",
            gender: data['sex'] ?? "X",
            passportNumber: data['docNumber'] ?? "",
          );
          debugPrint("✅ Automated Australia Passport check successful.");
          plansToProcess.remove('australia_passport');
        } catch (e) {
          debugPrint("⚠️ Automated Australia Passport check failed: $e.");
        }
      } else {
        debugPrint("⚠️ Document is not a passport, skipping check.");
      }
    }

    debugPrint("Original plans: ${_flowState.allSteps}");
    debugPrint("Final remaining manual plans: $plansToProcess");

    _flowState = _flowState.copyWith(allSteps: plansToProcess);
  }

  Future<void> submitAmlData({required String name, String? dob, String? gender}) async {
    final amlSettings = _flowState.toolSettings['business_aml'] ?? {};
    final threshold = amlSettings['threshold']?.toString();

    await _apiService.amlVerification(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      name: name,
      dob: dob,
      gender: gender,
      threshold: threshold,
    );
  }

  Future<void> submitFaceCompare({required XFile liveSelfie, XFile? manualImage2}) async {
    final documentFaceBase64 = _flowState.collectedData['faceImageBase64'] as String?;
    Uint8List? documentFaceBytes;
    if (documentFaceBase64 != null && manualImage2 == null) {
      documentFaceBytes = base64Decode(documentFaceBase64);
    }
    await _apiService.faceCompare(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      imageFile1: liveSelfie,
      imageFile2: manualImage2,
      imageFile2Bytes: documentFaceBytes,
    );
  }

  Future<void> submitBiometricVerification({required XFile image}) async {
    await _apiService.biometricVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      imageFile: image,
    );
  }

  Future<void> submitBiometricRegistration({required String username, required XFile image}) async {
    await _apiService.biometricRegistration(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      username: username,
      imageFile: image,
    );
  }

  Future<void> submitDukcapilData({required String name, required String dob, required String nik}) async {
    await _apiService.dukcapilVerification(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      name: name,
      dob: dob,
      nik: nik,
    );
  }

  Future<void> submitDukcapilFaceMatchData(
      {required String name, required String dob, required String nik, required File image}) async {
    await _apiService.dukcapilFaceMatch(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      name: name,
      dob: dob,
      nik: nik,
      imageFile: image,
    );
  }

  Future<void> submitPhDrivingLicenseData(
      {required String licenseNumber, required String expiryDate, required String serialNumber}) async {
    await _apiService.philippinesDrivingLicense(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      licenseNumber: licenseNumber,
      expiryDate: expiryDate,
      serialNumber: serialNumber,
    );
  }

  Future<void> submitPhSocialSecurityData({required String sssNumber}) async {
    await _apiService.philippinesSocialSecurity(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      sssNumber: sssNumber,
    );
  }

  Future<void> submitAuPassportData(
      {required String lastName,
      required String givenName,
      required String dob,
      required String gender,
      required String passportNumber}) async {
    await _apiService.australiaPassport(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      lastName: lastName,
      givenName: givenName,
      dob: dob,
      gender: gender,
      passportNumber: passportNumber,
    );
  }

  Future<void> submitQrCode({required Map<String, dynamic> qrPayload}) async {
    await _apiService.verifyQrCode(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      qrPayload: qrPayload,
    );
  }

  Future<void> submitPhPrcData({
    required String profession,
    String? firstName,
    String? lastName,
    String? licenseNo,
    String? dob,
  }) async {
    await _apiService.phPrcVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      profession: profession,
      firstName: firstName,
      lastName: lastName,
      licenseNo: licenseNo,
      dateOfBirth: dob,
    );
  }

  Future<String> sendEmailOtp({required String email}) async {
    final response = await _apiService.emailSendOtp(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      email: email,
    );

    final referenceId = response['result']?['status']?['code']?.toString();
    if (referenceId == null) {
      throw ApiException("Could not get OTP from the server.", statusCode: 200);
    }
    return referenceId;
  }

  Future<void> verifyEmailOtp({required String otp, required String referenceId}) async {
    await _apiService.emailVerifyOtp(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      otp: otp,
      referenceId: referenceId,
    );
  }

  Future<String> sendSmsOtp({required String phoneNumber, required String countryCode}) async {
    final response = await _apiService.smsSendOtp(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      phoneNumber: phoneNumber,
      countryCode: countryCode,
    );

    final referenceId = response['result']?['otp_result']?['reference_id'] as String?;
    if (referenceId == null) {
      throw ApiException("Could not get OTP reference ID from the server.", statusCode: 200);
    }
    return referenceId;
  }

  Future<void> verifySmsOtp({required String otp, required String referenceId}) async {
    await _apiService.smsVerifyOtp(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      otp: otp,
      referenceId: referenceId,
    );
  }

  Future<void> submitCustomDocument({required File documentFile}) async {
    await _apiService.customDocumentVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      documentFile: documentFile,
    );
  }

  Future<void> submitPhNbiClearance({required String clearanceNo}) async {
    await _apiService.phNbiClearance(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      clearanceNo: clearanceNo,
    );
  }

  Future<void> submitPhNationalPolice({required String surname, required String clearanceNo}) async {
    await _apiService.phNationalPolice(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      surname: surname,
      clearanceNo: clearanceNo,
    );
  }

  Future<void> submitVoiceLiveness({required File audioFile}) async {
    await _apiService.voiceLivenessVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      audioFile: audioFile,
    );
  }

  Future<void> finalizeVerification() async {
    if (_flowState.userToken == null || _flowState.templateId == null || _flowState.verificationId == null) {
      throw Exception('Cannot finalize verification: Missing required IDs.');
    }

    await _apiService.finalizeVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
    );
    debugPrint("✅ Verification finalized successfully via repository.");
  }

  void nextStep() {
    if (!_flowState.isLastStep) {
      final newHistory = List<int>.from(_flowState.history)..add(_flowState.currentStepIndex);

      _flowState = _flowState.copyWith(currentStepIndex: _flowState.currentStepIndex + 1, history: newHistory);
    } else {
      debugPrint("End of flow reached.");
    }
  }

  void previousStep() {
    if (_flowState.history.isNotEmpty) {
      final lastIndex = _flowState.history.removeLast();
      _flowState = _flowState.copyWith(currentStepIndex: lastIndex, history: _flowState.history);
    }
  }
}
