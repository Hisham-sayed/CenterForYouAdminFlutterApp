import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/users/presentation/users_list_screen.dart';
import 'features/subjects/presentation/subjects_screen.dart';
import 'features/years_terms/presentation/years_terms_screen.dart';
import 'features/subjects/presentation/subject_detail_screen.dart';
import 'features/subjects/presentation/exams_screen.dart';
import 'features/subjects/presentation/lessons_screen.dart';
import 'features/subjects/presentation/videos_screen.dart';
import 'features/users/presentation/add_subject_to_user_screen.dart';
import 'features/device_management/presentation/device_management_screen.dart';
import 'features/graduation/presentation/graduation_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/subjects/presentation/subjects_list_screen.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'core/widgets/auth_lifecycle_guard.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    
    // Catch Flutter Errors (Layout, Rendering, etc.)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Here we could log to a service like Sentry/Firebase
      debugPrint('Flutter Error: ${details.exception}');
    };

    // Catch Platform Errors (Async, Native, etc.)
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform Error: $error');
      // Return true to prevent app crash if possible
      return true;
    };

    runApp(const AdminApp());
  }, (error, stack) {
    debugPrint('Zone Error: $error');
    // Log fatal errors here
  });
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Admin Hub',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
      ],
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      builder: (context, child) {
        return AuthLifecycleGuard(
          navigatorKey: navigatorKey,
          child: child!,
        );
      },
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.dashboard: (context) => const DashboardScreen(),
        AppRoutes.users: (context) => const UsersListScreen(),
        AppRoutes.subjects: (context) => const SubjectsScreen(),
        AppRoutes.subjectsList: (context) => const SubjectsListScreen(),
        AppRoutes.years: (context) => const YearsTermsScreen(isYears: true),
        AppRoutes.terms: (context) => const YearsTermsScreen(isYears: false),
        AppRoutes.subjectDetail: (context) => const SubjectDetailScreen(),
        AppRoutes.exams: (context) => const ExamsScreen(),
        AppRoutes.lessons: (context) => const LessonsScreen(),
        AppRoutes.videos: (context) => const VideosScreen(),
        AppRoutes.addSubjectToUser: (context) => const AddSubjectToUserScreen(),
        AppRoutes.deviceManagement: (context) => const DeviceManagementScreen(),
        AppRoutes.graduation: (context) => const GraduationPartiesScreen(),
      },
      // Handle unknown routes/placeholders
      onGenerateRoute: (settings) {
         return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text('Not Found')),
               body: Center(child: Text('Route ${settings.name} not found')),
            ),
         );
      },
    );
  }
}
