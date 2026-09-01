import 'dart:convert';

import 'package:crypto/crypto.dart';

String hashPin(String pin) {
  return sha256.convert(utf8.encode(pin)).toString();
}

bool verifyPin({required String pin, required String pinHash}) {
  return hashPin(pin) == pinHash;
}

String redactToken(String? token) {
  if (token == null || token.isEmpty) return '(none)';
  if (token.length <= 8) return '***';
  return '${token.substring(0, 4)}…${token.substring(token.length - 4)}';
}
