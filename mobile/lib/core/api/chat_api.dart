import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatEvent {
  ChatEvent(this.name, this.data);
  final String
  name; // meta | token | triage | emergency | confirm | blocked | error | done
  final Map<String, dynamic> data;
}

/// Klienti SSE. Nuk interpreton përgjigjen: thjesht kalon ngjarjet te kontrolluesi.
class ChatApi {
  ChatApi({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  Stream<ChatEvent> stream(String message, {String? conversationId}) async* {
    final token = await tokenProvider();
    final request = http.Request('POST', Uri.parse('$baseUrl/v1/chat/stream'))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode({
        'message': message,
        'conversation_id': conversationId,
      });

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      // 429 (kufi kërkesash) dhe 401 (token i skaduar) trajtohen te kontrolluesi.
      throw ChatApiException(response.statusCode);
    }

    var event = 'message';
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        final data =
            jsonDecode(line.substring(5).trim()) as Map<String, dynamic>;
        yield ChatEvent(event, data);
      }
    }
  }

  /// Konfirmimi i një veprimi (kujtesë ilaçi) nga serveri.
  /// Klienti nuk dërgon asnjë të dhënë: veprimi ruhet te Redis nga backend-i.
  Future<void> confirmAction(String actionId) async {
    final token = await tokenProvider();
    final resp = await _client.post(
      Uri.parse('$baseUrl/v1/actions/$actionId/confirm'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw ChatApiException(resp.statusCode);
    }
  }

  void dispose() => _client.close();
}

class ChatApiException implements Exception {
  ChatApiException(this.statusCode);
  final int statusCode;

  /// Mesazhi sipas udhëzimit për UX writing ("Gabim 500." -> tekst njerëzor).
  String get userMessage => switch (statusCode) {
    401 => 'Sesi ka skaduar. Hyr përsëri për të vazhduar.',
    429 => 'Shumë pyetje për momentin. Prit pak para se të provosh përsëri.',
    _ =>
      'Nuk u lidhëm. Provo përsëri pas pak. Nëse është urgjente, telefono 194.',
  };

  @override
  String toString() => 'ChatApiException($statusCode)';
}
