```markdown
# idmeta_sdk_flutter
IDMeta Flutter SDK for identity verification.  
This is a **beta version** for initial testing and integration.

---

## Installation

Add the package directly from Git in your `pubspec.yaml`:

```yaml
dependencies:
  idmeta_sdk_flutter:
    git:
      url: https://github.com/C4SI-0/idmeta_sdk_flutter.git
      ref: main
```

Then run:

```bash
flutter pub get
```

---

## Usage

Import the package:

```dart
import 'package:idmeta_sdk_flutter/idmeta_sdk_flutter.dart';
```

Use the `IdmetaVerificationButton` widget to start the verification flow:

```dart
import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/idmeta_sdk_flutter.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IDMeta Verification Example'),
      ),
      body: Center(
        child: IdmetaVerificationButton(
          userToken: 'Your Token Here',
          templateId: 'Flow/Template ID',
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text('Start My Verification'),
          ),
        ),
      ),
    );
  }
}
```

---

### Parameters

| Parameter    | Type   | Description                                      |
|-------------|--------|--------------------------------------------------|
| `userToken` | String | The user token for the verification flow.       |
| `templateId`| String | The ID of the verification template to use.     |
| `style`     | ButtonStyle | Optional styling for the button.             |
| `child`     | Widget | The content displayed inside the button.       |


---
### Notes

- Supports **Flutter >=3.16.0** and **Dart >=3.2.0 <4.0.0**.  
- Use `IdmetaVerificationButton` to start the verification flow with minimal setup.
```