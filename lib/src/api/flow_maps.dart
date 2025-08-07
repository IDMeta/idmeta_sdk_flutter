import 'package:flutter/material.dart';
import '../FlowUI/au_passport_screen.dart';
import '../FlowUI/biometric_face_compare.dart';
import '../FlowUI/biometric_registeration.dart';
import '../FlowUI/biometric_verification.dart';
import '../FlowUI/custom_document_screen.dart';
import '../FlowUI/dukcapil_face_match_screen.dart';
import '../FlowUI/dukcapil_verification_screen.dart';
import '../FlowUI/email_verification_screen.dart';
import '../FlowUI/ph_driving_license_screen.dart';
import '../FlowUI/ph_national_police_screen.dart';
import '../FlowUI/ph_nbi_clearance_screen.dart';
import '../FlowUI/ph_prc_screen.dart';
import '../FlowUI/ph_social_security_screen.dart';
import '../FlowUI/aml_verification_screen.dart';
import '../FlowUI/document_verification_screen.dart';
import '../FlowUI/qr_verification_screen.dart';
import '../FlowUI/sms_verification_screen.dart';
import '../FlowUI/voice_liveness_screen.dart';

final Map<String, Widget> apiScreenMapping = {
  'document_verification': const DocumentVerificationScreen(),
  'biometrics_face_compare': const BioFaceCompareScreen(),
  'biometrics_registration': const BiometricRegistrationScreen(),
  'biometrics_verification': const BiometricVerificationScreen(),
  'business_aml': const AmlVerificationScreen(),
  'dukcapil': const DukcapilVerificationScreen(),
  'dukcapil_facematch': const DukcapilFaceMatchScreen(),
  'philippines_driving_license': const PhDrivingLicenseScreen(),
  'philippines_social_security': const PhSocialSecurityScreen(),
  'australia_passport': const AuPassportScreen(),
  'qr_verification': const QrVerificationScreen(),
  'sms_verification': const SmsVerificationScreen(),
  'philippines_prc': const PhPrcScreen(),
  'email_verification': const EmailVerificationScreen(),
  'custom_document': const CustomDocumentScreen(),
  'philippines_nbi_clearance': const PhNbiClearanceScreen(),
  'philippines_national_police': const PhNationalPoliceScreen(),
  'biometrics_voice_liveness': const VoiceLivenessScreen(),
};

final Map<String, String> apiPlanDisplayNames = {
  'document_verification': 'Document Verification',
  'biometrics_face_compare': 'Biometric Face Comparison',
  'biometrics_registration': 'Biometric Registration',
  'biometrics_verification': 'Biometric Verification',
  'business_aml': 'AML Verification',
  'sms_verification': 'SMS Verification',
  'custom_document': 'Custom Document',
  'dukcapil_facematch': 'Dukcapil Face Match',
  'dukcapil': 'Dukcapil Verification',
  'philippines_nbi_clearance': 'Philippines NBI Clearance',
  'philippines_national_police': 'Philippines National Police',
  'philippines_prc': 'Philippines PRC',
  'philippines_driving_license': 'Philippines Driving License',
  'australia_passport': 'Australia Passport',
  'biometrics_voice_liveness': 'Biometric Voice Liveness',
  'email_verification': 'Email Verification',
  'philippines_social_security': 'Philippines Social Security',
  'qr_verification': 'Qr Verification',
};
