import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tokeni ruhet me flutter_secure_storage (Keychain/Keystore), KURRË në SharedPreferences.
///
/// Përjashtim vetëm për pamjen paraprake në web: kur faqja hapet në rrjetin
/// lokal me `http://192.168.x.x` (jo secure context), browser-i nuk e lejon
/// WebCrypto dhe flutter_secure_storage hedh gabim. Në atë rast — vetëm në web —
/// përdoret një vend ruajtjeje rezervë në SharedPreferences, që telefoni ta
/// shohë aplikacionin. Në HTTPS/localhost dhe në aplikacionin mobil kjo rrugë
/// nuk aktivizohet kurrë.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kToken = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kConversation = 'conversation_id';

  static String _webKey(String key) => 'dev_web_secure_$key';

  Future<String?> token() => _read(_kToken);

  Future<void> saveToken(String value) => _write(_kToken, value);

  Future<void> saveConversationId(String value) =>
      _write(_kConversation, value);

  Future<String?> conversationId() => _read(_kConversation);

  Future<void> clear() async {
    await _delete(_kToken);
    await _delete(_kRefresh);
    await _delete(_kConversation);
  }

  Future<String?> _read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
    } catch (_) {
      if (!kIsWeb) rethrow;
    }
    if (!kIsWeb) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_webKey(key));
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      if (kIsWeb) {
        // Pastro çdo mbetje nga rruga rezervë, që të mos ketë dy kopje.
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_webKey(key));
      }
    } catch (_) {
      if (!kIsWeb) rethrow;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webKey(key), value);
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      if (!kIsWeb) rethrow;
    }
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_webKey(key));
    }
  }
}
