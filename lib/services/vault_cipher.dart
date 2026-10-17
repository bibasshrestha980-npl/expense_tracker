import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// A random 256-bit recovery key, never uploaded or persisted by the app.
class VaultCipher {
  final SecretKey _key;
  final _aes = AesGcm.with256bits();
  VaultCipher._(this._key);
  static Future<String> generateKey() async => base64UrlEncode(
    await (await AesGcm.with256bits().newSecretKey()).extractBytes(),
  );
  factory VaultCipher.fromRecoveryKey(String value) {
    final bytes = base64Url.decode(value.trim());
    if (bytes.length != 32) throw const FormatException('Invalid recovery key');
    return VaultCipher._(SecretKey(bytes));
  }
  Future<Map<String, dynamic>> seal(
    Map<String, dynamic> data,
    String context,
  ) async {
    final box = await _aes.encrypt(
      utf8.encode(jsonEncode(data)),
      secretKey: _key,
      aad: utf8.encode('pocket:v1:$context'),
    );
    return {
      'v': 1,
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  Future<Map<String, dynamic>> open(
    Map<String, dynamic> data,
    String context,
  ) async {
    if (data['v'] != 1) {
      throw const FormatException('Unsupported vault version');
    }
    final clear = await _aes.decrypt(
      SecretBox(
        base64Decode(data['ciphertext'] as String),
        nonce: base64Decode(data['nonce'] as String),
        mac: Mac(base64Decode(data['mac'] as String)),
      ),
      secretKey: _key,
      aad: utf8.encode('pocket:v1:$context'),
    );
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(clear)) as Map);
  }
}
