// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:io';

/// Whether the code runs inside `flutter test`.
bool get isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');
