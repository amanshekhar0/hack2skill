import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/prediction_request.dart';
import '../models/prediction_response.dart';

class ApiService {
  /// Build-time configurable:
  /// `flutter build web --dart-define=API_BASE_URL=https://your-backend.example`
  static const String _rawBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'https://volatilisable-demetrice-unchambered.ngrok-free.dev');
  static String get _baseUrl => _rawBaseUrl.endsWith('/') 
      ? _rawBaseUrl.substring(0, _rawBaseUrl.length - 1) 
      : _rawBaseUrl;
      
  // Render/hosted backends can cold-start and Gemini can be slow.
  // Use longer timeouts on web to avoid false "offline mode".
  static Duration get _timeout => kIsWeb ? const Duration(seconds: 60) : const Duration(seconds: 25);
  static Duration get _aiTimeout => kIsWeb ? const Duration(seconds: 120) : const Duration(seconds: 60);

  static Future<http.Response> _withRetry(
    Future<http.Response> Function() request, {
    required Duration timeout,
    int retries = 1,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        return await request().timeout(timeout);
      } catch (e) {
        lastError = e;
        if (attempt >= retries) rethrow;
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
    throw lastError ?? Exception('Request failed');
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Only needed for ngrok tunnels.
    if (_baseUrl.contains('ngrok')) {
      headers['ngrok-skip-browser-warning'] = 'true';
    }

    return headers;
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await _withRetry(
        () => http.get(Uri.parse('$_baseUrl/health'), headers: _headers),
        timeout: _timeout,
        retries: 1,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<PredictionResponse?> predict(PredictionRequest request) async {
    try {
      final url = '$_baseUrl/predict';
      print('Calling API: $url');
      print('Request Body: ${jsonEncode(request.toJson())}');
      
      final response = await _withRetry(
        () => http.post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(request.toJson()),
        ),
        timeout: _timeout,
        retries: 1,
      );

      print('API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PredictionResponse.fromJson(data);
      } else {
        print('API error: ${response.body}');
      }
      return null;
    } on TimeoutException {
      print('API Timeout');
      return null;
    } on SocketException {
      print('API Socket Exception');
      return null;
    } catch (e) {
      print('API Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> parseSpeech(String text) async {
    try {
      final response = await _withRetry(
        () => http.post(
          Uri.parse('$_baseUrl/parse_voice'),
          headers: _headers,
          body: jsonEncode({"text": text}),
        ),
        timeout: _aiTimeout,
        retries: 0,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Voice Parse API Error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSchemes() async {
    try {
      final response = await _withRetry(
        () => http.get(Uri.parse('$_baseUrl/schemes'), headers: _headers),
        timeout: _timeout,
        retries: 1,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<String?> generateGuide(PredictionRequest request) async {
    try {
      final response = await _withRetry(
        () => http.post(
          Uri.parse('$_baseUrl/generate_guide'),
          headers: _headers,
          body: jsonEncode(request.toJson()),
        ),
        timeout: _aiTimeout,
        retries: 0,
      );

      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      }
      return null;
    } catch (e) {
      print('Guide Generation API Error: $e');
      return null;
    }
  }
}
