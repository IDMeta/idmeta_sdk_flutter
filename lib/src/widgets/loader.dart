import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Shimmer(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey, Colors.white],
              stops: [0.4, 0.5, 0.6],
            ),
            period: Duration(seconds: 2),
            child: Icon(
              Icons.fact_check,
              size: 64,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Verifying...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

void showLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Loader(),
  );
}

void hideLoader(BuildContext context) {
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
