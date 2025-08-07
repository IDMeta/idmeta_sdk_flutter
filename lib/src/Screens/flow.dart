import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Verification/verification.dart';
import 'package:provider/provider.dart';
import '../api/flow_maps.dart';

class FlowScreen extends StatelessWidget {
  const FlowScreen({super.key});

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit'),
        content:
            const Text('Are you sure you want to leave the verification process? Your progress will not be saved.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Exit')),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final get = context.read<VerificationProvider>();

    if (!get.flowState.isFirstStep) {
      get.previousScreen();

      return false;
    }

    return _showExitConfirmationDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final get = context.watch<VerificationProvider>();
    final flowState = get.flowState;
    final settings = get.designSettings?.settings;

    final String? currentStepKey = flowState.currentStepKey;
    final String displayName = apiPlanDisplayNames[currentStepKey] ?? 'Verification Step';

    final Widget? screenWidget = apiScreenMapping[currentStepKey];

    final theme = Theme.of(context).copyWith(
        primaryColor: settings?.primaryColor,
        appBarTheme: AppBarTheme(
          foregroundColor: settings?.textColor ?? Colors.black,
        ),
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: settings?.effectiveFontFamily,
              bodyColor: settings?.textColor,
            ));

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          leading: !flowState.isFirstStep
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _onWillPop(context),
                )
              : null,
          title: Text(displayName, style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryColor,
              ),
              child: const Text('Exit', style: TextStyle(fontSize: 14)),
              onPressed: () async {
                if (await _showExitConfirmationDialog(context)) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        ),
        body: _buildBody(context, screenWidget, currentStepKey),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Widget? screenWidget, String? currentStepKey) {
    if (screenWidget == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
              const SizedBox(height: 20),
              const Text(
                'Workflow Step Not Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "The step '$currentStepKey' could not be loaded. Please contact support.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return screenWidget;
  }
}
