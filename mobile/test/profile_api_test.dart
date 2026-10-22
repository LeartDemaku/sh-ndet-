import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shendetplus/core/api/me_api.dart';

void main() {
  test('register dërgon emrin, mbiemrin dhe pëlqimet', () async {
    late http.Request captured;
    final api = MeApi(
      baseUrl: 'http://api.test',
      tokenProvider: () async => 'token-test',
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'email': 'leart@example.com',
            'email_sent': false,
            'expires_in': 600,
            'resend_after': 60,
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await api.register(
      firstName: 'Leart',
      lastName: 'Demaku',
      email: 'leart@example.com',
      password: 'TestFjalekalim123!',
      acceptTerms: true,
      acceptHealthData: true,
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.method, 'POST');
    expect(captured.url.toString(), 'http://api.test/v1/auth/register');
    expect(body['first_name'], 'Leart');
    expect(body['last_name'], 'Demaku');
    expect(body['accept_terms'], isTrue);
    expect(body['accept_health_data'], isTrue);
    api.dispose();
  });

  test('deleteConversation përdor tokenin dhe URL-në e saktë', () async {
    late http.Request captured;
    final api = MeApi(
      baseUrl: 'http://api.test',
      tokenProvider: () async => 'token-test',
      client: MockClient((request) async {
        captured = request;
        return http.Response('{"status":"deleted"}', 200);
      }),
    );

    await api.deleteConversation('conv-123');

    expect(captured.method, 'DELETE');
    expect(
      captured.url.toString(),
      'http://api.test/v1/me/conversations/conv-123',
    );
    expect(captured.headers['authorization'], 'Bearer token-test');
    api.dispose();
  });

  test('deleteAllConversations dhe deleteAllMedications', () async {
    final requests = <http.Request>[];
    final api = MeApi(
      baseUrl: 'http://api.test',
      tokenProvider: () async => 'token-test',
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('{"status":"deleted","count":2}', 200);
      }),
    );

    await api.deleteAllConversations();
    await api.deleteAllMedications();

    expect(requests[0].method, 'DELETE');
    expect(requests[0].url.path, '/v1/me/conversations');
    expect(requests[1].method, 'DELETE');
    expect(requests[1].url.path, '/v1/me/medications');
    api.dispose();
  });

}
