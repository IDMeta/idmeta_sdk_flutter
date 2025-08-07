import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../Models/settings.dart';
import 'package:http_parser/http_parser.dart';

class ApiEndpoints {
  static const String baseUrl = 'https://integrate.idmetagroup.com/api';
  static String getDesignSettings(String templateId) => '$baseUrl/user/api-trust-flow/get-design-settings/$templateId';
  static const String createVerification = '$baseUrl/v1/verification/create-verification';
  static const String docVerification = '$baseUrl/v1/verification/document_verification';
  static const String finalizeVerification = '$baseUrl/v1/verification/finalize-verification';
  static const String biometricRegistration = '$baseUrl/v1/verification/biometricsregistration';
  static const String biometricVerification = '$baseUrl/v1/verification/biometricsverification';
  static const String faceCompare = '$baseUrl/v1/verification/biometricsfacecompare';
  static const String amlVerification = '$baseUrl/v1/verification/aml';
  static const String dukcapilVerification = '$baseUrl/v1/verification/dukcapil';
  static const String dukcapilFaceMatch = '$baseUrl/v1/verification/dukcapilfacematch';
  static const String philippinesDrivingLicense = '$baseUrl/v1/verification/philippines/drivinglicense';
  static const String philippinesSocialSecurity = '$baseUrl/v1/verification/philippines/socialsecurity';
  static const String australiaPassport = '$baseUrl/v1/verification/australia/passport';
  static const String qrVerification = '$baseUrl/v1/verification/qr_code_verification';
  static const String smsSend = '$baseUrl/v1/verification/sms-verification/send';
  static const String smsVerify = '$baseUrl/v1/verification/sms-verification/verify';
  static const String philippinesPrc = '$baseUrl/v1/verification/philippines/prc';
  static const String emailSend = '$baseUrl/v1/verification/email-verification/send';
  static const String emailVerify = '$baseUrl/v1/verification/email-verification/verify';
  static const String customDocument = '$baseUrl/v1/verification/customdocument';
  static const String philippinesNbiClearance = '$baseUrl/v1/verification/philippines/nbiclearance';
  static const String philippinesNationalPolice = '$baseUrl/v1/verification/philippines/nationalpolice';
  static const String voiceLiveness = '$baseUrl/v1/verification/biometrics/voiceliveness';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'API Error: $message (Status Code: $statusCode)';
}

class ApiService {
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _sendMultipartRequest(
    String endpoint, {
    required String userToken,
    required Map<String, String> fields,
    List<http.MultipartFile>? files,
  }) async {
    final url = Uri.parse(endpoint);
    final request = http.MultipartRequest('POST', url)
      ..headers['accept'] = 'application/json'
      ..headers['authorization'] = userToken.startsWith('Bearer ') ? userToken : 'Bearer $userToken'
      ..fields.addAll(fields);
    if (files != null) request.files.addAll(files);

    try {
      final response = await _client.send(request).timeout(const Duration(seconds: 90));
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      print(jsonResponse);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final bool isLogicalFailure =
            jsonResponse['status'] == false || (jsonResponse['result']?['status'] == 'failed');
        final errorMessage = jsonResponse['result']?['message'] ?? jsonResponse['message'] ?? 'Verification failed';

        if (isLogicalFailure) {
          final isRegistrationDuplicate = endpoint.contains(ApiEndpoints.biometricRegistration) &&
              (errorMessage.contains('Account already exists') || errorMessage.contains('already registered'));

          if (!isRegistrationDuplicate) {
            throw ApiException(errorMessage, statusCode: response.statusCode);
          }

          debugPrint("Handled known case: Biometric account already exists. Treating as success.");
        }
        return jsonResponse;
      } else {
        throw ApiException(
          jsonResponse['message'] ?? 'An unknown API error occurred.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No Internet connection.');
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> _sendJsonRequest(String endpoint,
      {required String userToken, required Map<String, dynamic> body}) async {
    final url = Uri.parse(endpoint);
    final headers = {
      'accept': 'application/json',
      'authorization': userToken.startsWith('Bearer ') ? userToken : 'Bearer $userToken',
      'Content-Type': 'application/json',
    };
    try {
      final response =
          await _client.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 90));
      final jsonResponse = jsonDecode(response.body);
      print(jsonResponse);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (jsonResponse['status'] == false || (jsonResponse['result']?['status'] == 'failed')) {
          throw ApiException(jsonResponse['message'] ?? jsonResponse['result']?['message'] ?? 'Verification failed',
              statusCode: response.statusCode);
        }
        return jsonResponse;
      } else {
        throw ApiException(jsonResponse['message'] ?? 'An unknown API error occurred.',
            statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException('No Internet connection.');
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<DesignSettings> getDesignSettings({required String templateId}) async {
    final url = Uri.parse(ApiEndpoints.getDesignSettings(templateId));
    try {
      final response =
          await _client.get(url, headers: {'accept': 'application/json'}).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return DesignSettings.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException('Failed to load design settings', statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException('No Internet connection.');
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> createVerification({required String userToken, required String templateId}) async {
    return _sendMultipartRequest(ApiEndpoints.createVerification,
        userToken: userToken, fields: {'template_id': templateId});
  }

  Future<Map<String, dynamic>> finalizeVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
  }) async {
    return _sendMultipartRequest(
      ApiEndpoints.finalizeVerification,
      userToken: userToken,
      fields: {
        'template_id': templateId,
        'verification_id': verificationId,
      },
    );
  }

  Future<Map<String, dynamic>> documentVerification(
      {required String userToken,
      required String templateId,
      required String verificationId,
      required File imageFile1,
      File? imageFile2}) async {
    final files = [await http.MultipartFile.fromPath('imageFrontSide', imageFile1.path)];
    if (imageFile2 != null) {
      files.add(await http.MultipartFile.fromPath('imageBackSide', imageFile2.path));
    }
    return _sendMultipartRequest(ApiEndpoints.docVerification,
        userToken: userToken, fields: {'template_id': templateId, 'verification_id': verificationId}, files: files);
  }

  Future<Map<String, dynamic>> amlVerification({
    required String userToken,
    required String verificationId,
    required String name,
    String? dob,
    String? gender,
    String? threshold,
  }) async {
    final body = <String, dynamic>{
      'verification_id': verificationId,
      'name': name,
      'datasets': ['PEP', 'SAN', 'RRE', 'INS', 'DD', 'POI', 'REL'],
      'countries': ['ID', 'PL', 'MY', 'US', 'AU', 'SG'],
    };
    if (dob != null && dob.isNotEmpty) body['dob'] = dob;
    if (gender != null && gender.isNotEmpty) body['gender'] = gender;

    if (threshold != null) {
      body['threshold'] = threshold;
    }

    return _sendJsonRequest(ApiEndpoints.amlVerification, userToken: userToken, body: body);
  }

  Future<Map<String, dynamic>> biometricRegistration(
      {required String userToken,
      required String templateId,
      required String verificationId,
      required String username,
      required XFile imageFile}) async {
    return _sendMultipartRequest(ApiEndpoints.biometricRegistration,
        userToken: userToken,
        fields: {'username': username, 'template_id': templateId, 'verification_id': verificationId},
        files: [await http.MultipartFile.fromPath('image', imageFile.path)]);
  }

  Future<Map<String, dynamic>> biometricVerification(
      {required String userToken,
      required String templateId,
      required String verificationId,
      required XFile imageFile}) async {
    return _sendMultipartRequest(ApiEndpoints.biometricVerification,
        userToken: userToken,
        fields: {'template_id': templateId, 'verification_id': verificationId},
        files: [await http.MultipartFile.fromPath('image', imageFile.path)]);
  }

  Future<Map<String, dynamic>> faceCompare(
      {required String userToken,
      required String templateId,
      required String verificationId,
      required XFile imageFile1,
      XFile? imageFile2,
      Uint8List? imageFile2Bytes}) async {
    final files = [await http.MultipartFile.fromPath('image1', imageFile1.path)];
    if (imageFile2 != null) {
      files.add(await http.MultipartFile.fromPath('image2', imageFile2.path));
    } else if (imageFile2Bytes != null) {
      files.add(http.MultipartFile.fromBytes('image2', imageFile2Bytes, filename: 'image2.jpeg'));
    }
    return _sendMultipartRequest(ApiEndpoints.faceCompare,
        userToken: userToken, fields: {'template_id': templateId, 'verification_id': verificationId}, files: files);
  }

  Future<Map<String, dynamic>> dukcapilVerification(
      {required String userToken,
      required String verificationId,
      required String name,
      required String dob,
      required String nik,
      required String templateId}) async {
    return _sendJsonRequest(ApiEndpoints.dukcapilVerification, userToken: userToken, body: {
      "name": name,
      "date_of_birth": dob,
      "nik": nik,
      "template_id": templateId,
      "verification_id": verificationId
    });
  }

  Future<Map<String, dynamic>> dukcapilFaceMatch({
    required String userToken,
    required String verificationId,
    required String name,
    required String dob,
    required String nik,
    required File imageFile,
    required String templateId,
  }) async {
    return _sendMultipartRequest(
      ApiEndpoints.dukcapilFaceMatch,
      userToken: userToken,
      fields: {
        'template_id': templateId,
        'verification_id': verificationId,
        'nik': nik,
        'name': name,
        'date_of_birth': dob,
      },
      files: [await http.MultipartFile.fromPath('selfie_image', imageFile.path)],
    );
  }

  Future<Map<String, dynamic>> philippinesDrivingLicense(
      {required String userToken,
      required String verificationId,
      required String licenseNumber,
      required String expiryDate,
      required String serialNumber,
      required String templateId}) async {
    return _sendJsonRequest(ApiEndpoints.philippinesDrivingLicense, userToken: userToken, body: {
      "template_id": templateId,
      "verification_id": verificationId,
      "licenseNumber": licenseNumber,
      "expirationDate": expiryDate,
      "serialNumber": serialNumber,
    });
  }

  Future<Map<String, dynamic>> philippinesSocialSecurity(
      {required String userToken,
      required String verificationId,
      required String sssNumber,
      required String templateId}) async {
    return _sendJsonRequest(ApiEndpoints.philippinesSocialSecurity, userToken: userToken, body: {
      "template_id": templateId,
      "verification_id": verificationId,
      "crnSsNumber": sssNumber,
    });
  }

  Future<Map<String, dynamic>> australiaPassport(
      {required String userToken,
      required String verificationId,
      required String lastName,
      required String givenName,
      required String dob,
      required String gender,
      required String passportNumber,
      required String templateId}) async {
    return _sendJsonRequest(ApiEndpoints.australiaPassport, userToken: userToken, body: {
      "family_name": lastName,
      "given_name": givenName,
      "dob": dob,
      "gender": gender,
      "travel_document_number": passportNumber,
      "template_id": templateId,
      "verification_id": verificationId
    });
  }

  Future<Map<String, dynamic>> _sendUrlEncodedRequest(
    String endpoint, {
    required String userToken,
    required Map<String, String> body,
  }) async {
    final url = Uri.parse(endpoint);
    final headers = {
      'accept': 'application/json',
      'authorization': userToken.startsWith('Bearer ') ? userToken : 'Bearer $userToken',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    try {
      final response = await _client.post(url, headers: headers, body: body).timeout(const Duration(seconds: 90));
      final jsonResponse = jsonDecode(response.body);

      return jsonResponse;
    } on SocketException {
      throw ApiException('No Internet connection.');
    }
  }

  Future<Map<String, dynamic>> verifyQrCode({
    required String userToken,
    required String templateId,
    required String verificationId,
    required Map<String, dynamic> qrPayload,
  }) async {
    Map<String, String> _flattenMap(Map<String, dynamic> map) {
      final flatMap = <String, String>{};
      map.forEach((key, value) {
        flatMap[key] = value.toString();
      });
      return flatMap;
    }

    final Map<String, String> body = _flattenMap(qrPayload);
    body['template_id'] = templateId;
    body['verification_id'] = verificationId;

    return _sendUrlEncodedRequest(
      ApiEndpoints.qrVerification,
      userToken: userToken,
      body: body,
    );
  }

  Future<Map<String, dynamic>> smsSendOtp({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String phoneNumber,
    required String countryCode,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.smsSend,
      userToken: userToken,
      body: {
        "phone_number": phoneNumber,
        "country_code": countryCode,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  Future<Map<String, dynamic>> smsVerifyOtp({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String otp,
    required String referenceId,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.smsVerify,
      userToken: userToken,
      body: {
        "otp": otp,
        "ref_id": referenceId,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  Future<Map<String, dynamic>> phPrcVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String profession,
    String? firstName,
    String? lastName,
    String? licenseNo,
    String? dateOfBirth,
  }) async {
    final body = <String, dynamic>{
      "template_id": templateId,
      "verification_id": verificationId,
      "profession": profession,
    };

    if (firstName != null && lastName != null) {
      body["firstName"] = firstName;
      body["lastName"] = lastName;
    } else if (licenseNo != null && dateOfBirth != null) {
      body["licenseNo"] = licenseNo;
      body["dateOfBirth"] = dateOfBirth;
    }

    return _sendJsonRequest(
      ApiEndpoints.philippinesPrc,
      userToken: userToken,
      body: body,
    );
  }

  Future<Map<String, dynamic>> emailSendOtp({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String email,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.emailSend,
      userToken: userToken,
      body: {
        "email": email,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  Future<Map<String, dynamic>> emailVerifyOtp({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String otp,
    required String referenceId,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.emailVerify,
      userToken: userToken,
      body: {
        "otp": otp,
        "ref_id": referenceId,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  Future<Map<String, dynamic>> customDocumentVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required File documentFile,
  }) async {
    return _sendMultipartRequest(ApiEndpoints.customDocument, userToken: userToken, fields: {
      "template_id": templateId,
      "verification_id": verificationId,
    }, files: [
      await http.MultipartFile.fromPath('document', documentFile.path)
    ]);
  }

  Future<Map<String, dynamic>> phNbiClearance({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String clearanceNo,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.philippinesNbiClearance,
      userToken: userToken,
      body: {
        "template_id": templateId,
        "verification_id": verificationId,
        "clearanceNo": clearanceNo,
      },
    );
  }

  Future<Map<String, dynamic>> phNationalPolice({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String surname,
    required String clearanceNo,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.philippinesNationalPolice,
      userToken: userToken,
      body: {
        "template_id": templateId,
        "verification_id": verificationId,
        "surname": surname,
        "clearanceNo": clearanceNo,
      },
    );
  }

  Future<Map<String, dynamic>> voiceLivenessVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required File audioFile,
  }) async {
    return _sendMultipartRequest(ApiEndpoints.voiceLiveness, userToken: userToken, fields: {
      "template_id": templateId,
      "verification_id": verificationId,
    }, files: [
      await http.MultipartFile.fromPath('audio', audioFile.path, contentType: MediaType('audio', 'wav')),
    ]);
  }
}
