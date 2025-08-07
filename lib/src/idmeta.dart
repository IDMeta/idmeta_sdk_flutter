import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Verification/verification.dart';
import 'Screens/flow.dart';
import 'Screens/home.dart';
import 'Screens/success.dart';

class IdMeta extends StatelessWidget {
  const IdMeta({super.key});

  @override
  Widget build(BuildContext context) {
    final get = context.watch<VerificationProvider>();

    final Widget currentScreen;
    if (get.isFlowCompleted) {
      currentScreen = const CompleteVerif();
    } else if (get.flowState.allSteps.isNotEmpty) {
      currentScreen = const FlowScreen();
    } else {
      currentScreen = const HomePage();
    }
    return Theme(
      data: _buildDynamicTheme(context, get),
      child: currentScreen,
    );
  }

  ThemeData _buildDynamicTheme(BuildContext context, VerificationProvider provider) {
    final settings = provider.designSettings?.settings;

    final primary = settings?.primaryColor ?? Colors.white;
    final secondary = settings?.secondaryColor ?? Colors.blue;
    final buttonFontColor = settings?.buttonTextColor ?? Colors.white;
    final textFontColor = settings?.textColor ?? Colors.black;
    final fontSize = settings?.parsedFontSize ?? 14.0;
    final fontFamily = settings?.effectiveFontFamily ?? 'Arial';

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: primary,
      fontFamily: fontFamily,
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          fontSize: fontSize,
          color: textFontColor,
          fontFamily: fontFamily,
        ),
      ),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: primary,
        background: primary,
        error: Colors.red,
        onPrimary: buttonFontColor,
        onSecondary: buttonFontColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: buttonFontColor,
          textStyle: TextStyle(
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: buttonFontColor,
          textStyle: TextStyle(
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: buttonFontColor,
          side: BorderSide.none,
          textStyle: TextStyle(
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: primary,
        surfaceTintColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          color: textFontColor.withOpacity(0.7),
          fontSize: fontSize,
          fontFamily: fontFamily,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: secondary, width: 2.0),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        hintStyle: TextStyle(
          color: textFontColor.withOpacity(0.5),
          fontSize: fontSize,
          fontFamily: fontFamily,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
