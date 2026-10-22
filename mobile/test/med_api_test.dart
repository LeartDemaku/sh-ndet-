import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shendetplus/core/api/me_api.dart';

void main() {
  test('deleteMedication dërgon DELETE dhe përdor tokenin', () async {
    late http.Request captured;
    final api = MeApi(
      baseUrl: 'http://api.test',
      tokenProvider: () async => 'token-test',
      client: MockClient((request) async {
        captured = request;
        return http.Response('{"status":"deleted"}', 200);
      }),
    );

    await api.deleteMedication('med-123');

    expect(captured.method, 'DELETE');
    expect(
      captured.url.toString(),
      'http://api.test/v1/me/medications/med-123',
    );
    expect(captured.headers['authorization'], 'Bearer token-test');
    api.dispose();
  });

  test(
    'deleteMedication kthen gabim të lexueshëm kur ilaçi nuk gjendet',
    () async {
      final api = MeApi(
        baseUrl: 'http://api.test',
        tokenProvider: () async => 'token-test',
        client: MockClient(
          (_) async => http.Response(
            '{"detail":"Ilaçi nuk u gjet."}',
            404,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      await expectLater(
        api.deleteMedication('missing'),
        throwsA(
          isA<MeApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.userMessage, 'userMessage', 'Ilaçi nuk u gjet.'),
        ),
      );
      api.dispose();
    },
  );
}
