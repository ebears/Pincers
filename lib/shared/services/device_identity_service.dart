import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _privateKeyKey = 'device_ed25519_private_key';
const _publicKeyKey = 'device_ed25519_public_key';
const _deviceIdKey = 'device_id';

/// Manages a persistent Ed25519 device identity used for OpenClaw gateway
/// device authentication. Keys are generated on first use and stored in
/// secure storage.
class DeviceIdentityService {
  static const _storage = FlutterSecureStorage();
  static final _ed25519 = Ed25519();

  String? _deviceId;
  List<int>? _publicKeyBytes;
  SimpleKeyPair? _keyPair;

  String get deviceId {
    assert(_deviceId != null, 'Call ensureInitialized() first');
    return _deviceId!;
  }

  /// Base64url-encoded 32-byte Ed25519 public key.
  String get publicKeyBase64Url {
    assert(_publicKeyBytes != null, 'Call ensureInitialized() first');
    return base64Url.encode(_publicKeyBytes!).replaceAll('=', '');
  }

  /// Load or generate the device Ed25519 keypair.
  Future<void> ensureInitialized() async {
    if (_keyPair != null) return;

    final privB64 = await _storage.read(key: _privateKeyKey);
    final pubB64 = await _storage.read(key: _publicKeyKey);

    if (privB64 != null && pubB64 != null) {
      final privBytes = base64Decode(privB64);
      final pubBytes = base64Decode(pubB64);
      _publicKeyBytes = pubBytes;
      _deviceId = await _storage.read(key: _deviceIdKey);
      _keyPair = SimpleKeyPairData(
        privBytes,
        publicKey: SimplePublicKey(pubBytes, type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );
    } else {
      final keyPair = await _ed25519.newKeyPair();
      final pubKey = await keyPair.extractPublicKey();
      _publicKeyBytes = List<int>.from(pubKey.bytes);

      final privData = await keyPair.extract();
      final privBytes = privData.bytes;

      // Device ID = hex(SHA256(publicKeyBytes))
      _deviceId = sha256.convert(_publicKeyBytes!).toString();

      await _storage.write(
          key: _privateKeyKey, value: base64Encode(privBytes));
      await _storage.write(
          key: _publicKeyKey, value: base64Encode(_publicKeyBytes!));
      await _storage.write(key: _deviceIdKey, value: _deviceId!);

      _keyPair = keyPair;
    }
  }

  /// Build the device auth object for the connect request.
  ///
  /// The signature covers a v2 payload:
  /// `v2|deviceId|clientId|clientMode|role|scopes|signedAtMs|token|nonce`
  Future<Map<String, dynamic>> buildDeviceAuth({
    required String clientId,
    required String clientMode,
    required String role,
    required List<String> scopes,
    required String token,
    required String nonce,
  }) async {
    final signedAt = DateTime.now().millisecondsSinceEpoch;

    final payload =
        'v2|$_deviceId|$clientId|$clientMode|$role|${scopes.join(',')}|$signedAt|$token|$nonce';

    final signature = await _ed25519.sign(
      utf8.encode(payload),
      keyPair: _keyPair!,
    );

    return {
      'id': _deviceId!,
      'publicKey': publicKeyBase64Url,
      'signature': base64Url.encode(signature.bytes).replaceAll('=', ''),
      'signedAt': signedAt,
      'nonce': nonce,
    };
  }
}
