import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Encryption {
  static encrypt.Key generateKeyFromUserIds(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    final keyBytes = utf8.encode(sortedIds.join());
    final digest = sha256.convert(keyBytes);
    return encrypt.Key.fromBase64(base64Encode(digest.bytes));
  }

  static String encryptData(String data, encrypt.Key key) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(data, iv: iv);

    return base64Encode(iv.bytes + encrypted.bytes);
  }

  static String decryptData(String encryptedData, encrypt.Key key) {
    final decoded = base64Decode(encryptedData);

    final iv = encrypt.IV(decoded.sublist(0, 16));
    final encryptedBytes = decoded.sublist(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt64(
        base64Encode(encryptedBytes),
        iv: iv
    );

    return decrypted;
  }
}