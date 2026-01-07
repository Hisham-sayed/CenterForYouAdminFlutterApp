import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../error/exceptions.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://center-for-you.runasp.net';
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // GET Request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    Uri uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
    }

    try {
      final response = await _client.get(uri, headers: _headers);
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client.post(
        uri, 
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
       throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
       throw NetworkException(e.toString());
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client.put(
        uri, 
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
       throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
       throw NetworkException(e.toString());
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client.delete(uri, headers: _headers);
      return _handleResponse(response);
    } on SocketException {
       throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
       throw NetworkException(e.toString());
    }
  }

  // Multipart POST Request
  Future<dynamic> postMultipart(String endpoint, Map<String, String> fields, {File? file, String fileField = 'file'}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    // Add headers
    request.headers.addAll(_headers);
    // Remove Content-Type as MultipartRequest sets it automatically with boundary
    request.headers.remove('Content-Type'); 

    // Add fields
    request.fields.addAll(fields);

    // Add file if present
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

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
       throw NetworkException();
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
      
      if (response.statusCode == 401) {
        throw ServerException(statusCode: 401, responseData: errorData);
      }
      
      throw ServerException(
        statusCode: response.statusCode,
        responseData: errorData,
      );
    }
  }
}
