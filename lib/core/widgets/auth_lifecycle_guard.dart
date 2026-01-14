import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../constants/app_routes.dart';
import 'dart:async';

/// AuthLifecycleGuard listens for session expiry events from ApiService.
/// 
/// Key Principle: Redirect to login ONLY when:
/// - Refresh token is definitively rejected by backend (onUnauthorized event)
/// - User explicitly logs out
/// 
/// DO NOT redirect on:
/// - Access token expiration (handled by refresh)
/// - Network errors
/// - App resume (let actual API calls determine validity)
class AuthLifecycleGuard extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const AuthLifecycleGuard({
    super.key, 
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<AuthLifecycleGuard> createState() => _AuthLifecycleGuardState();
}

class _AuthLifecycleGuardState extends State<AuthLifecycleGuard> {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    
    // Listen for global 401 events (only when refresh token is definitively rejected)
    _authSubscription = ApiService().onUnauthorized.listen((_) {
      debugPrint('AuthLifecycleGuard: Received onUnauthorized. Redirecting to login.');
      _redirectToLogin();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // REMOVED: didChangeAppLifecycleState / _validateSession
  // Per spec: No background validation. Session validity is determined by actual API usage.
  // If refresh token is expired, the first API call will trigger onUnauthorized.

  void _redirectToLogin() {
    widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
