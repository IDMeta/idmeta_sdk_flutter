library idmeta_sdk_flutter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/api/service.dart';
import 'src/core/repository.dart';
import 'src/idmeta.dart';
import 'src/Verification/verification.dart';
export 'src/widgets/button.dart';

class IdmetaSdk {
  static Future<T?> startVerification<T>({
    required BuildContext context,
    required String userToken,
    required String templateId,
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            Provider(create: (_) => ApiService()),
            ProxyProvider<ApiService, VerificationRepository>(
              update: (_, apiService, __) => VerificationRepository(apiService: apiService),
            ),
            ChangeNotifierProxyProvider<VerificationRepository, VerificationProvider>(
              create: (context) => VerificationProvider(
                repository: context.read<VerificationRepository>(),
                apiService: context.read<ApiService>(),
              )..initialize(userToken: userToken, templateId: templateId),
              update: (_, repository, previousProvider) => previousProvider!,
            ),
          ],
          child: const IdMeta(),
        ),
      ),
    );
  }
}
