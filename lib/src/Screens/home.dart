import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../Verification/verification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController scrollController = ScrollController();

  Future<bool> _showExitConfirmationDialog() async {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit'),
        content: const Text('Are you sure you want to leave the verification process?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Exit'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  Future<void> _startFlow() async {
    final get = context.read<VerificationProvider>();
    final success = await get.startVerificationFlow();
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Failed to start verification flow.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final get = context.watch<VerificationProvider>();
    final settings = get.designSettings?.settings;
    final isStartingFlow = get.isStartingFlow;
    final String paragraph = settings?.effectiveDescription ?? "Loading description...";
    final logoUrl = get.designSettings?.logoUrl;
    final theme = Theme.of(context);

    final buttonStyle = TextButton.styleFrom(
      backgroundColor: settings?.secondaryColor ?? theme.colorScheme.secondary,
      foregroundColor: settings?.buttonTextColor ?? theme.colorScheme.onSecondary,
      textStyle: TextStyle(
        fontFamily: settings?.effectiveFontFamily,
        fontSize: settings?.parsedFontSize ?? 14,
        fontWeight: FontWeight.bold,
      ),
      minimumSize: const Size.fromHeight(50),
    );

    return WillPopScope(
      onWillPop: _showExitConfirmationDialog,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: true,
            title: get.isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(height: 50, width: 120, color: Colors.white),
                  )
                : logoUrl != null
                    ? Image.network(logoUrl, height: 50, errorBuilder: (_, __, ___) => const _DefaultLogo())
                    : const _DefaultLogo(),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _InfoRow(
              icon: Icons.assignment,
              text: 'Submit the required details and upload any necessary documents or images.',
            ),
            const _InfoRow(
              icon: Icons.cloud_upload,
              text: 'Please fill in the required details and provide any necessary documents or photos.',
            ),
            SizedBox(
              height: 200,
              child: Container(
                margin: const EdgeInsets.all(15.0),
                padding: const EdgeInsets.all(3.0),
                child: get.isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                              8,
                              (i) => Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    height: 16,
                                    width: i % 3 == 2 ? 150 : double.infinity,
                                    color: Colors.white,
                                  )),
                        ),
                      )
                    : Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(8.0),
                          child: Text(paragraph),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                style: buttonStyle,
                onPressed: isStartingFlow ? null : _startFlow,
                child: isStartingFlow
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(
                        'Start',
                        style: TextStyle(fontSize: settings?.parsedFontSize ?? 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultLogo extends StatelessWidget {
  const _DefaultLogo();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/logo.png', package: 'idmeta_sdk', height: 37),
        const SizedBox(width: 12),
        const Text('IDMeta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
