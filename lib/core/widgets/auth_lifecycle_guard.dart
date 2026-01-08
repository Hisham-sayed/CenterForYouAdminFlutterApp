import 'package:flutter/material.dart';
import '../../features/auth/auth_controller.dart';
import '../../core/services/api_service.dart';
import '../constants/app_routes.dart';
import 'dart:async';

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

class _AuthLifecycleGuardState extends State<AuthLifecycleGuard> with WidgetsBindingObserver {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen for global 401 events
    _authSubscription = ApiService().onUnauthorized.listen((_) {
      _redirectToLogin();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateSession();
    }
  }

  Future<void> _validateSession() async {
    final auth = AuthController();
    final isValid = await auth.checkAuth();
    
    if (!isValid) {
        _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    // Prevent duplicate navigations if already validating or on login
    // For now simple pushReplacement is enough
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
