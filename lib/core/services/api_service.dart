import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../error/exceptions.dart';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiService {
  static const String baseUrl = 'https://center-for-you.runasp.net';
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  String? _accessToken;
  
  // Stream for 401 events (when refresh fails)
  final _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  void setToken(String token) {
    _accessToken = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  /// Internal helper to perform requests with retry logic
  Future<dynamic> _performRequest(Future<http.Response> Function() requestCall) async {
    try {
      final response = await requestCall();
      return _handleResponse(response);
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        // Attempt Refresh
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
           // Retry original request with new token
           try {
             final retryResponse = await requestCall();
             return _handleResponse(retryResponse);
           } catch (retryError) {
             // If retry fails again, just throw
             rethrow;
           }
        } else {
           // Refresh failed, notify unauthorized
           _unauthorizedController.add(null);
           rethrow; 
        }
      }
      rethrow;
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final tokenStorage = TokenStorage();
      final currentRefreshToken = await tokenStorage.getRefreshToken();
      final currentAccessToken = await tokenStorage.getAccessToken(); // Or use _accessToken

      if (currentRefreshToken == null || currentAccessToken == null) {
        return false;
      }

      // We explicitly use a fresh client or just standard headers excluding the old auth?
      // Actually usually refresh endpoint doesn't need Bearer token sometimes, OR it needs it.
      // The prompt usage implies sending them in body.
      // We should NOT use _performRequest here to avoid infinite loops.
      
      final uri = Uri.parse('$baseUrl/auth/refresh-token');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': currentAccessToken,
          'refreshToken': currentRefreshToken,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        if (body['isSuccess'] == true && body['hasData'] == true) {
           final data = body['data'];
           final newAccess = data['token'];
           final newRefresh = data['refreshToken'];
           
           if (newAccess != null && newRefresh != null) {
             // Update local state
             setToken(newAccess);
             // Update storage
             await tokenStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
             return true;
           }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Token Refresh Failed: $e');
      return false;
    }
  }

  // GET Request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    Uri uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
    }
    return _performRequest(() => _client.get(uri, headers: _headers));
  }

  // POST Request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    // Special check: Login shouldn't auto-refresh if it fails with 401 (invalid credentials)
    // But login usually returns 400 or 401 for bad params. 
    // Generally standard "refresh" logic only applies if we *thought* we were logged in.
    
    // However, simplistic wrapper is fine for now. 
    // If login endpoint returns 401, it means bad creds. 
    // _tryRefreshToken will likely fail or be skipped if we don't have tokens yet.
    
    return _performRequest(() => _client.post(
        uri, 
        headers: _headers,
        body: body != null ? json.encode(body) : null,
    ));
  }

  // PUT Request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return _performRequest(() => _client.put(
        uri, 
        headers: _headers,
        body: body != null ? json.encode(body) : null,
    ));
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return _performRequest(() => _client.delete(uri, headers: _headers));
  }

  // Generic Multipart Request
  Future<dynamic> _multipartRequest(String method, String endpoint, Map<String, String> fields, {File? file, String fileField = 'file'}) async {
    return _performRequest(() async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final request = http.MultipartRequest(method, uri);
        request.headers.addAll(_headers);
        request.headers.remove('Content-Type'); 
        request.fields.addAll(fields);
        if (file != null) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            fileField,
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
        final streamedResponse = await request.send();
        return http.Response.fromStream(streamedResponse);
    });
  }

  // Multipart POST Request
  Future<dynamic> postMultipart(String endpoint, Map<String, String> fields, {File? file, String fileField = 'file'}) async {
    return _multipartRequest('POST', endpoint, fields, file: file, fileField: fileField);
  }

  // Multipart PUT Request
  Future<dynamic> putMultipart(String endpoint, Map<String, String> fields, {File? file, String fileField = 'file'}) async {
    return _multipartRequest('PUT', endpoint, fields, file: file, fileField: fileField);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      dynamic errorData;
      try {
        errorData = json.decode(response.body);
      } catch (_) {
        errorData = response.body;
      }
      
      // We throw a specific ServerException with statusCode
      // The _performRequest wrapper catches this specific one to check for 401
      throw ServerException(
        statusCode: response.statusCode,
        responseData: errorData,
      );
    }
  }
}
