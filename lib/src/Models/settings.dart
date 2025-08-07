import 'package:flutter/material.dart';

Color parseHexColor(String? hexString, {required Color fallback}) {
  if (hexString == null || hexString.isEmpty) return fallback;
  try {
    final buffer = StringBuffer();

    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    debugPrint('Could not parse color: $hexString. Error: $e');
    return fallback;
  }
}

DateTime? tryParseDateTime(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  return DateTime.tryParse(dateString);
}

class DesignSettings {
  final int? id;
  final int? templateId;
  final String? logoUrl;
  final Settings? settings;
  final int? isActive;
  final String? fileName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DesignSettings({
    this.id,
    this.templateId,
    this.logoUrl,
    this.settings,
    this.isActive,
    this.fileName,
    this.createdAt,
    this.updatedAt,
  });

  factory DesignSettings.fromJson(Map<String, dynamic> json) {
    return DesignSettings(
      id: json['id'],
      templateId: json['template_id'],
      logoUrl: (json['logo'] is String && json['logo'].isNotEmpty) ? json['logo'] : null,
      settings: json['settings'] is Map<String, dynamic> ? Settings.fromJson(json['settings']) : null,
      isActive: json['is_active'],
      fileName: json['file_name'],
      createdAt: tryParseDateTime(json['created_at']),
      updatedAt: tryParseDateTime(json['updated_at']),
    );
  }
}

class Settings {
  final String? fontSize;
  final String? fontFamily;
  final String? description;
  final String? primaryColorHex;
  final String? textFontColorHex;
  final String? secondaryColorHex;
  final String? buttonFontColorHex;

  const Settings({
    this.fontSize,
    this.fontFamily,
    this.description,
    this.primaryColorHex,
    this.textFontColorHex,
    this.secondaryColorHex,
    this.buttonFontColorHex,
  });

  Color get primaryColor => parseHexColor(primaryColorHex, fallback: Colors.blue);
  Color get textColor => parseHexColor(textFontColorHex, fallback: Colors.black);
  Color get secondaryColor => parseHexColor(secondaryColorHex, fallback: Colors.blueAccent);
  Color get buttonTextColor => parseHexColor(buttonFontColorHex, fallback: Colors.white);

  double get parsedFontSize {
    final size = fontSize?.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(size ?? '14.0') ?? 14.0;
  }

  String get effectiveFontFamily => (fontFamily?.isNotEmpty ?? false) ? fontFamily! : 'Arial';

  String get effectiveDescription {
    return description ??
        "By clicking 'Start' I consent to Company and its service provider, IDMeta, obtaining and disclosing a scan of my face geometry and barcode of my ID for the purpose of verifying my identity...";
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      fontSize: json['fontSize']?.toString(),
      fontFamily: json['fontFamily']?.toString(),
      description: json['description']?.toString(),
      primaryColorHex: json['primaryColor']?.toString(),
      textFontColorHex: json['textFontColor']?.toString(),
      secondaryColorHex: json['secondaryColor']?.toString(),
      buttonFontColorHex: json['buttonFontColor']?.toString(),
    );
  }
}
