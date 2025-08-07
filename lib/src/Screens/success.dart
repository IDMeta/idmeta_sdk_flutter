import 'package:flutter/material.dart';

class CompleteVerif extends StatelessWidget {
  const CompleteVerif({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async => false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Text('Verification Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Thank you for completing the verification\nProcess',
                    textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15)),
              ],
            ),
            Image.asset(
              'assets/checked.png',
              package: 'idmeta_sdk_flutter',
              width: 150,
              height: 150,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: TextButton.styleFrom(),
                  child: const Text(
                    'Finish',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
