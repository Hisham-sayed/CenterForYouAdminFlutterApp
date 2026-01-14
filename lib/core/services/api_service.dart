import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../error/exceptions.dart';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central network layer that handles all API communication.
/// 
/// ## Authentication Lifecycle (Production-Grade)
/// 
/// **Golden Rule:** Access token expiration is a network concern, not a session concern.
/// Session validity belongs to the refresh token ONLY.
/// 
/// ### Key Principles:
/// - **Access Token:** Short-lived, used only to authorize API requests. Expiration does NOT end user session.
/// - **Refresh Token:** Long-lived, sole authority of session validity. Session ends ONLY if:
///   1. Refresh token expires
///   2. Refresh token is rejected by backend (emits [onUnauthorized])
///   3. User explicitly logs out
/// 
/// ### This class is the ONLY authority that can end a session.
/// UI, controllers, and app lifecycle events must NEVER trigger logout.
/// 
/// ### Token Refresh Strategy:
/// - Refresh happens ONLY when an authenticated API request is made
/// - Triggered by HTTP 401 or local expiration check
/// - NO timers, NO background jobs, NO app startup/resume refresh
/// - No request → No refresh → No logout
/// 
/// ### Network Errors:
/// - NEVER invalidate tokens on network failure
/// - NEVER trigger logout on SocketException, Timeout, etc.
/// - User stays logged in until refresh token is definitively rejected by backend
class ApiService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://center-for-you.runasp.net';
  
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
  /// Key principle: Access Token Expiration ≠ Logout
  /// Logout ONLY when refresh token is definitively invalid (backend rejects it)
  Future<dynamic> _performRequest(Future<http.Response> Function() requestCall) async {
    // 1. Proactive Token Refresh (Optional Optimization - NO LOGOUT)
    // If we know access token is expired, try refresh first to avoid a 401 round-trip
    // But if refresh fails here, we just proceed with the request (let 401 handle it)
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      final isTokenValid = await TokenStorage().isAccessTokenValid();
      if (!isTokenValid) {
        debugPrint('ApiService: Access token expired. Attempting proactive refresh...');
        try {
          await _tryRefreshToken();
          // If refresh succeeds, great! If it fails, we just proceed.
        } catch (e) {
          // If network error during proactive refresh, just proceed with request
          // The request itself will fail with NetworkException if offline
          debugPrint('ApiService: Proactive refresh failed (will proceed): $e');
        }
      }
    }

    // 2. Perform Request
    try {
      final response = await requestCall().timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        debugPrint('ApiService: 401 received. Attempting refresh...');
        // Attempt Refresh on 401
        try {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            // Retry original request with new token
            debugPrint('ApiService: Retrying request after successful refresh...');
            final retryResponse = await requestCall().timeout(const Duration(seconds: 30));
            return _handleResponse(retryResponse);
          } else {
            // Refresh failed because backend rejected refresh token (session truly expired)
            debugPrint('ApiService: Refresh token rejected. Session expired.');
            _unauthorizedController.add(null);
            rethrow;
          }
        } on SocketException {
          // Network error during refresh -> NOT a logout, just network issue
          debugPrint('ApiService: Network error during refresh. NOT logging out.');
          throw NetworkException();
        } on TimeoutException {
          // Timeout during refresh -> NOT a logout, just network issue
          debugPrint('ApiService: Timeout during refresh. NOT logging out.');
          throw NetworkException('Request timed out');
        }
      }
      rethrow;
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final tokenStorage = TokenStorage();
      final currentRefreshToken = await tokenStorage.getRefreshToken();
      final currentAccessToken = await tokenStorage.getAccessToken(); 

      if (currentRefreshToken == null || currentAccessToken == null) {
        return false;
      }

      final uri = Uri.parse('$baseUrl/auth/refresh-token');
      debugPrint('ApiService: Refreshing token...');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': currentAccessToken,
          'refreshToken': currentRefreshToken,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        if (body['isSuccess'] == true && body['hasData'] == true) {
           final data = body['data'];
           final newAccess = data['token'];
           final newRefresh = data['refreshToken'];
           // Handle potential backend typo "expirseIn"
           final expiresInSeconds = data['expiresIn'] ?? data['expirseIn']; 
           final refreshTokenExpirationStr = data['refreshTokenExpiration'];

           if (newAccess != null && newRefresh != null && expiresInSeconds != null && refreshTokenExpirationStr != null) {
             // Calculate Expirations
             final now = DateTime.now();
             // expiresIn is in seconds usually.
             final accessTokenExpiration = now.add(Duration(seconds: expiresInSeconds is int ? expiresInSeconds : int.parse(expiresInSeconds.toString())));
             final refreshTokenExpiration = DateTime.parse(refreshTokenExpirationStr);

             // Update local state
             setToken(newAccess);
             // Update storage
             await tokenStorage.saveTokens(
               accessToken: newAccess, 
               refreshToken: newRefresh,
               accessTokenExpiration: accessTokenExpiration,
               refreshTokenExpiration: refreshTokenExpiration,
             );
             debugPrint('ApiService: Token refreshed successfully.');
             return true;
           }
        }
      }
      debugPrint('ApiService: Refresh failed with status ${response.statusCode}');
      return false;
    } on SocketException {
      rethrow; 
    } on TimeoutException {
      rethrow; 
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
    
    // Check if we are logging in (skip proactive refresh)
    if (endpoint.contains('/login') || endpoint.contains('/refresh-token')) {
       return _performBasicRequest(() => _client.post(
          uri, 
          headers: _headers,
          body: body != null ? json.encode(body) : null,
      ));
    }
    
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

  /// Basic request wrapper for internal use (Login/Refresh) that bypasses proactive checks
  Future<dynamic> _performBasicRequest(Future<http.Response> Function() requestCall) async {
      try {
        final response = await requestCall().timeout(const Duration(seconds: 30));
        return _handleResponse(response);
      } on SocketException {
        throw NetworkException();
      } on TimeoutException {
        throw NetworkException('Request timed out');
      } catch (e) {
        if (e is ServerException || e is NetworkException) rethrow;
        throw NetworkException(e.toString());
      }
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
      
      throw ServerException(
        statusCode: response.statusCode,
        responseData: errorData,
      );
    }
  }
}
