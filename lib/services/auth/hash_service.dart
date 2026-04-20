import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashService {
  /// Hashes a password using SHA-256.
  static String hashPassword(String password) {
    var bytes = utf8.encode(password); // data being hashed
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
