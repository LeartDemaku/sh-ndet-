import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/chat_api.dart';
import '../../core/api/me_api.dart';
import '../../core/storage/secure_store.dart';

/// Përzgjedh bazën e serverit.
/// Emulatori Android e sheh kompjuterin si 10.0.2.2, jo localhost.
/// Në iOS Simulator punon 127.0.0.1. Në prodhim përdor vetëm HTTPS.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final chatApiProvider = Provider<ChatApi>((ref) {
  final store = ref.watch(secureStoreProvider);
  return ChatApi(baseUrl: kApiBaseUrl, tokenProvider: store.token);
});

final meApiProvider = Provider<MeApi>((ref) {
  final store = ref.watch(secureStoreProvider);
  return MeApi(baseUrl: kApiBaseUrl, tokenProvider: store.token);
});
