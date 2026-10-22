import 'dart:convert';

import 'package:http/http.dart' as http;

/// Klienti për të dhënat e përdoruesit (Ekrani 6 · Privatësia + Ekrani 5 · Ilaçet).
class MeApi {
  MeApi({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  MeApiException _error(http.Response resp) {
    String? detail;
    try {
      final data = jsonDecode(utf8.decode(resp.bodyBytes));
      if (data is Map<String, dynamic>) {
        final d = data['detail'];
        if (d is String && d.trim().isNotEmpty) {
          detail = d.trim();
        } else if (d is Map && d['message'] is String) {
          detail = '${d['message']}'.trim();
        }
      }
    } catch (_) {
      // Përgjigje jo-JSON: përdoret mesazhi standard sipas statusit.
    }
    return MeApiException(resp.statusCode, detail: detail);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final resp = await _client.get(_uri(path), headers: await _headers());
    if (resp.statusCode != 200) throw _error(resp);
    return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchMe() => _get('/v1/me');

  Future<List<Map<String, dynamic>>> fetchMedications() async {
    final data = await _get('/v1/me/medications');
    return List<Map<String, dynamic>>.from(data['medications'] as List);
  }

  /// Fshirja e një ilaçi dhe e të gjitha kujtesave të tij.
  Future<void> deleteMedication(String id) async {
    final resp = await _client.delete(
      _uri('/v1/me/medications/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
    );
    if (resp.statusCode != 200) throw _error(resp);
  }

  Future<Map<String, dynamic>> exportData() => _get('/v1/me/export');

  Future<void> setConsent(String kind, {required bool granted}) async {
    final resp = await _client.put(
      _uri('/v1/me/consents/$kind'),
      headers: await _headers(),
      body: jsonEncode({'granted': granted}),
    );
    if (resp.statusCode != 200) throw _error(resp);
  }

  Future<void> deleteAccount() async {
    final resp = await _client.delete(
      _uri('/v1/me'),
      headers: await _headers(),
      body: jsonEncode({'confirm': true}),
    );
    if (resp.statusCode != 200) throw _error(resp);
  }

  /// Hyrje për përdorues që kanë llogari (Hapi 5: identiteti — regjistrim, hyrje, JWT).
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final resp = await _client.post(
      _uri('/v1/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (resp.statusCode != 200) throw _error(resp);
    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return '${data['access_token']}';
  }

  /// Regjistrimi nuk kthen më token: llogaria aktivizohet pas kodit të emailit.
  Future<RegisterResult> register({
    required String email,
    required String password,
    required bool acceptTerms,
    required bool acceptHealthData,
  }) async {
    final resp = await _client.post(
      _uri('/v1/auth/register'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'country': 'XK',
        'accept_terms': acceptTerms,
        'accept_health_data': acceptHealthData,
      }),
    );
    if (resp.statusCode != 201) throw _error(resp);
    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return RegisterResult(
      email: data['email'] as String? ?? email,
      emailSent: data['email_sent'] == true,
      expiresIn: (data['expires_in'] as num?)?.toInt() ?? 600,
      resendAfter: (data['resend_after'] as num?)?.toInt() ?? 60,
    );
  }

  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    final resp = await _client.post(
      _uri('/v1/auth/verify-email'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    if (resp.statusCode != 200) throw _error(resp);
    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return '${data['access_token']}';
  }

  Future<ResendResult> resendVerification({required String email}) async {
    final resp = await _client.post(
      _uri('/v1/auth/resend-verification'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (resp.statusCode != 202) throw _error(resp);
    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return ResendResult(
      emailSent: data['email_sent'] == true,
      expiresIn: (data['expires_in'] as num?)?.toInt() ?? 600,
      resendAfter: (data['resend_after'] as num?)?.toInt() ?? 60,
      message: data['message'] as String?,
    );
  }

  void dispose() => _client.close();
}

class RegisterResult {
  const RegisterResult({
    required this.email,
    required this.emailSent,
    required this.expiresIn,
    required this.resendAfter,
  });

  final String email;
  final bool emailSent;
  final int expiresIn;
  final int resendAfter;
}

class ResendResult {
  const ResendResult({
    required this.emailSent,
    required this.expiresIn,
    required this.resendAfter,
    this.message,
  });

  final bool emailSent;
  final int expiresIn;
  final int resendAfter;
  final String? message;
}

class MeApiException implements Exception {
  MeApiException(this.statusCode, {this.detail});
  final int statusCode;
  final String? detail;

  String get userMessage {
    final d = detail?.trim();
    if (d != null && d.isNotEmpty) return d;
    return switch (statusCode) {
      401 => 'Sesi ka skaduar. Hyr përsëri.',
      409 => 'Ky email është i regjistruar.',
      422 => 'Të dhënat nuk janë të plota. Plotëso fushat e kërkuara.',
      429 => 'Shumë kërkesa. Provo përsëri pas një minute.',
      _ => 'Nuk u lidhëm. Provo përsëri pas pak.',
    };
  }

  @override
  String toString() => 'MeApiException($statusCode)';
}
