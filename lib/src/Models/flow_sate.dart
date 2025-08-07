import 'package:flutter/foundation.dart';

@immutable
class VerificationFlowState {
  final String? userToken;
  final String? templateId;
  final String? verificationId;

  final List<String> allSteps;
  final int currentStepIndex;
  final List<int> history;

  final Map<String, dynamic> collectedData;
  final Map<String, Map<String, dynamic>> toolSettings;

  const VerificationFlowState({
    required this.userToken,
    required this.templateId,
    required this.verificationId,
    required this.allSteps,
    required this.currentStepIndex,
    required this.history,
    required this.collectedData,
    required this.toolSettings,
  });

  factory VerificationFlowState.initial() {
    return const VerificationFlowState(
      userToken: null,
      templateId: null,
      verificationId: null,
      allSteps: [],
      currentStepIndex: 0,
      history: [],
      collectedData: {},
      toolSettings: {},
    );
  }

  VerificationFlowState copyWith({
    String? userToken,
    String? templateId,
    String? verificationId,
    List<String>? allSteps,
    int? currentStepIndex,
    List<int>? history,
    Map<String, dynamic>? collectedData,
    Map<String, Map<String, dynamic>>? toolSettings,
  }) {
    return VerificationFlowState(
      userToken: userToken ?? this.userToken,
      templateId: templateId ?? this.templateId,
      verificationId: verificationId ?? this.verificationId,
      allSteps: allSteps ?? this.allSteps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      history: history ?? this.history,
      collectedData: collectedData ?? this.collectedData,
      toolSettings: toolSettings ?? this.toolSettings,
    );
  }

  bool get isFirstStep => history.isEmpty;
  bool get isLastStep => currentStepIndex >= allSteps.length - 1;
  String? get currentStepKey =>
      allSteps.isNotEmpty && currentStepIndex < allSteps.length ? allSteps[currentStepIndex] : null;

  bool get isDocumentVerificationMultiSide => toolSettings['document_verification']?['multiSide'] as bool? ?? false;
  bool get isDocumentVerificationManualScan =>
      toolSettings['document_verification']?['manualDocumentUpload'] as bool? ?? false;
}
