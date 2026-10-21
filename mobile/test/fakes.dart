import 'package:shendetplus/core/storage/secure_store.dart';

/// Ruajtës i thjeshtë në memorie për testet (pa plugin-in e platformës).
class FakeSecureStore extends SecureStore {
  FakeSecureStore({this.tokenValue});

  String? tokenValue;

  @override
  Future<String?> token() async => tokenValue;

  @override
  Future<void> saveToken(String value) async => tokenValue = value;

  @override
  Future<String?> conversationId() async => null;

  @override
  Future<void> saveConversationId(String value) async {}

  @override
  Future<void> clear() async => tokenValue = null;
}
