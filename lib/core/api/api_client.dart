import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function();

class BaleApiException implements Exception {
  const BaleApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  static const _configuredBaseUrl = String.fromEnvironment('BALE_API_URL');
  static const _emulatorBaseUrl = 'http://10.0.2.2:4000/api/v1';
  static const _productionBaseUrl = 'https://api.balebelajar.com/api/v1';

  ApiClient({
    http.Client? httpClient,
    TokenProvider? tokenProvider,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider,
        baseUrl = baseUrl ?? _defaultBaseUrl;

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kDebugMode) return _emulatorBaseUrl;
    return _productionBaseUrl;
  }

  final http.Client _httpClient;
  final TokenProvider? _tokenProvider;
  final String baseUrl;

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<dynamic> delete(String path) {
    return _send('DELETE', path);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final token = await _tokenProvider?.call();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    late final http.StreamedResponse response;
    try {
      response = await _httpClient.send(
        http.Request(method, uri)
          ..headers.addAll(headers)
          ..body = body == null ? '' : jsonEncode(body),
      );
    } on SocketException catch (error) {
      throw BaleApiException(
        kDebugMode
            ? 'Tidak bisa terhubung ke server (${error.message}).'
            : 'Tidak bisa terhubung ke server. Periksa koneksi internet.',
      );
    } on HandshakeException catch (_) {
      throw const BaleApiException(
        'Koneksi aman ke server gagal. Periksa tanggal perangkat dan sertifikat server.',
      );
    } on http.ClientException catch (error) {
      throw BaleApiException(
        kDebugMode
            ? 'Tidak bisa menghubungi API: ${error.message}'
            : 'Tidak bisa terhubung ke server. Periksa koneksi internet.',
      );
    }
    final text = await response.stream.bytesToString();
    final decoded = text.isEmpty ? null : jsonDecode(text);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BaleApiException(
        _readMessage(decoded) ?? 'Koneksi ke server gagal.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  String? _readMessage(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final message = decoded['message'];
    if (message is String) return message;
    if (message is List) return message.join(', ');
    return null;
  }
}
