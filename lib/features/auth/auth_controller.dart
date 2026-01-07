import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
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
        
        // Store Token in ApiService
        ApiService().setToken(token);
        
        // Persist Token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
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
        // If ApiService didn't throw but returned failure (rare with current logic), throw manually to trigger error handler
        throw Exception(response != null ? response['message'] ?? 'Login failed' : 'Unknown error');
      }
    });
  }

  Future<bool> checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check for token existence
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
         return false;
      }
      
      // 2. Set token
      ApiService().setToken(token);

      // 3. Validate Token by calling a protected endpoint
      // fetching dashboard stats is a cheap way to verify the token is valid
      // If this throws 401, catch block will handle it
      await ApiService().get('/admin-dashboard');

      // 4. Update local state if successful
      userId = prefs.getString('user_id');
      userName = prefs.getString('user_name');
      userEmail = prefs.getString('user_email');
      isAuthenticated = true;
      notifyListeners();
      return true;

    } catch (e) {
       // If any error (401, network, etc.), assume invalid session for startup safety
       debugPrint('Auth Validation Error: $e');
       await logout(); // Clear everything
       return false;
    }
  }

  Future<void> logout() async {
    isAuthenticated = false;
    ApiService().setToken(''); 
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}
