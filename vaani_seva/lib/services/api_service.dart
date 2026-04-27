import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/prediction_request.dart';
import '../models/prediction_response.dart';

class ApiService {
  static const String _rawBaseUrl = 'https://volatilisable-demetrice-unchambered.ngrok-free.dev';
  static String get _baseUrl => _rawBaseUrl.endsWith('/') 
      ? _rawBaseUrl.substring(0, _rawBaseUrl.length - 1) 
      : _rawBaseUrl;
      
  static const Duration _timeout = Duration(seconds: 15);

  static const String _geminiApiKey = ''; // ADD YOUR KEY HERE FOR LOCAL TESTING

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static Future<String?> generateGuideDirectly(PredictionRequest request, String schemeName) async {
    try {
      final prompt = """
      You are an AI assistant for VAANI SEVA, helping rural citizens apply for government schemes.
      Generate a simple, step-by-step guide for the scheme: $schemeName.
      User Details: Age: ${request.age}, Income: ${request.income}, Land: ${request.landSize}.
      The guide should be in ${request.language ?? 'English'} and very easy to understand for an uneducated person.
      """;

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}]
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      return null;
    } catch (e) {
      print('Direct Gemini Error: $e');
      return null;
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'), headers: _headers)
          .timeout(_timeout);
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
      
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

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
      final response = await http.post(
        Uri.parse('$_baseUrl/parse_voice'),
        headers: _headers,
        body: jsonEncode({"text": text}),
      ).timeout(_timeout);

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
      final response = await http
          .get(Uri.parse('$_baseUrl/schemes'), headers: _headers)
          .timeout(_timeout);
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
      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate_guide'),
            headers: _headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

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
