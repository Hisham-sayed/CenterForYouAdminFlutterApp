import 'package:flutter/material.dart';
import '../../features/auth/auth_controller.dart';
import '../constants/app_routes.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        // If session is invalid, use the navigator key to redirect
        // Check if we are already safely possibly on login to avoid loops?
        // simple pushReplacementNamed is safer to clean stack
        widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
