import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'api_config.dart';

class ApiClient {
  ApiClient._();

  static final http.Client _client = _createClient();

  static http.Client _createClient() {
    // For development and specialized server environments (like misconfigured SNI),
    // we use a custom HttpClient that bypasses SSL certificate validation.
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    
    return IOClient(httpClient);
  }

  static Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    final Map<String, String> finalHeaders = {
      'Accept': 'application/json',
      ...?headers,
    };
    
    return _client
        .get(uri, headers: finalHeaders)
        .timeout(ApiConfig.timeout, onTimeout: () {
      throw TimeoutException('Request timed out after ${ApiConfig.timeout.inSeconds}s');
    });
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    final Map<String, String> finalHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    return _client
        .post(uri, headers: finalHeaders, body: body, encoding: encoding)
        .timeout(ApiConfig.timeout, onTimeout: () {
      throw TimeoutException('Request timed out after ${ApiConfig.timeout.inSeconds}s');
    });
  }
}
