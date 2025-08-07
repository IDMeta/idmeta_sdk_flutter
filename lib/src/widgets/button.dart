import 'package:flutter/material.dart';
import '../../idmeta_sdk.dart';

class IdmetaVerificationButton extends StatelessWidget {
  final String userToken;
  final String templateId;
  final Widget? child;
  final ButtonStyle? style;

  const IdmetaVerificationButton({
    super.key,
    required this.userToken,
    required this.templateId,
    this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: () {
        IdmetaSdk.startVerification(
          context: context,
          userToken: userToken,
          templateId: templateId,
        );
      },
      child: child ?? const Text('Start Verification'),
    );
  }
}
