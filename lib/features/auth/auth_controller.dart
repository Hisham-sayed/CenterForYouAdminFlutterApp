import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/services/token_storage.dart';
import '../../core/architecture/base_controller.dart';

class AuthController extends BaseController {
  bool isAuthenticated = false;
  
  // User Data
  String? userId;
  String? userName;
  String? userEmail;

  Future<bool> login(String email, String password) async {
    return await safeCall(() async {
      final response = await ApiService().post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
          'deviceId': 'admin',
        },
      );

      if (response != null && response['isSuccess'] == true && response['hasData'] == true) {
        final data = response['data'];
        final token = data['token'];
        final refreshToken = data['refreshToken']; 
        // Handle potential backend typo "expirseIn"
        final expiresInSeconds = data['expiresIn'] ?? data['expirseIn'];
        final refreshTokenExpirationStr = data['refreshTokenExpiration'];
        
        // Store Token in ApiService
        ApiService().setToken(token);
        
        // Persist Tokens with Expiration
        if (token != null && refreshToken != null && expiresInSeconds != null && refreshTokenExpirationStr != null) {
           final now = DateTime.now();
           final accessTokenExpiration = now.add(Duration(seconds: expiresInSeconds is int ? expiresInSeconds : int.parse(expiresInSeconds.toString())));
           final refreshTokenExpiration = DateTime.parse(refreshTokenExpirationStr);

           await TokenStorage().saveTokens(
             accessToken: token, 
             refreshToken: refreshToken,
             accessTokenExpiration: accessTokenExpiration,
             refreshTokenExpiration: refreshTokenExpiration,
           );
        } else {
           // Fallback if backend response format is unexpected, though we strictly expect it based on prompt
           // We might throw or log error, but for now we proceed (maybe without exp times tokens won't work proactively)
           // But saveTokens NOW requires the dates. So we must provide something or fail.
           // Let's assume response is correct as per spec. If not, safeCall catches generic exceptions.
           if (expiresInSeconds == null || refreshTokenExpirationStr == null) {
              throw const FormatException('Missing expiration data in login response');
           }
        }
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['id'] ?? '');
        await prefs.setString('user_name', data['name'] ?? '');
        await prefs.setString('user_email', data['email'] ?? '');

        // Update Local State
        userId = data['id'];
        userName = data['name'];
        userEmail = data['email'];
        isAuthenticated = true;
      } else {
        isAuthenticated = false;
        throw Exception(response != null ? response['message'] ?? 'Login failed' : 'Unknown error');
      }
    });
  }

  /// Check if user session is valid.
  /// Key principle: Session is valid as long as REFRESH TOKEN is valid.
  /// Access token expiration does NOT mean logout.
  Future<bool> checkAuth() async {
    try {
      final tokenStorage = TokenStorage();
      
      // 1. Check Refresh Token Validity - This is the ONLY session indicator
      final isRefreshTokenValid = await tokenStorage.isRefreshTokenValid();
      if (!isRefreshTokenValid) {
        debugPrint('AuthController: Refresh token expired or missing. Session invalid.');
        // DO NOT call logout() here - per spec, AuthController must NOT trigger logout
        // UI (SplashScreen) handles navigation to login when this returns false
        // Tokens remain in storage but are expired - will be overwritten on next login
        return false;
      }
      
      // 2. Load Access Token (may be expired, that's OK - ApiService will refresh it)
      final token = await tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        ApiService().setToken(token);
      }
      
      // 3. Restore User Data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id');
      userName = prefs.getString('user_name');
      userEmail = prefs.getString('user_email');
      
      // 4. If we have user data and valid refresh token, user is authenticated
      // The first actual API call will handle access token refresh if needed
      if (userId != null && userId!.isNotEmpty) {
        isAuthenticated = true;
        notifyListeners();
        debugPrint('AuthController: Session restored. User: $userEmail');
        return true;
      }
      
      // No user data found (edge case - tokens exist but no user data)
      debugPrint('AuthController: No user data found despite valid tokens.');
      return false;

    } catch (e) {
      debugPrint('AuthController: checkAuth error: $e');
      // On any error, assume we need to verify on next API call
      // Do NOT logout here - let actual API usage determine session validity
      return false;
    }
  }

  Future<void> logout() async {
    isAuthenticated = false;
    ApiService().setToken(''); 
    
    await TokenStorage().clearTokens();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}
