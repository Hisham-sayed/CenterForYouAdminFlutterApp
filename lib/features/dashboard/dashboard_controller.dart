import 'package:flutter/material.dart';
import 'data/dashboard_stats_model.dart';
// We haven't created this yet but might need it, actually removing import for now.

import '../../core/services/api_service.dart';

import '../../core/architecture/base_controller.dart';

class DashboardController extends BaseController {
  DashboardStats stats = const DashboardStats();

  DashboardController() {
    loadStats();
  }

  Future<void> loadStats() async {
    await safeCall(() async {
      final response = await ApiService().get('/admin-dashboard');

      if (response != null && response['isSuccess'] == true && response['hasData'] == true) {
        final data = response['data'];
        
        stats = DashboardStats(
          totalStudents: data['usersCount'] ?? 0,
          totalSubjects: data['subjectsCount'] ?? 0,
          totalLessons: data['lessonsCount'] ?? 0,
          totalVideos: data['videosCount'] ?? 0,
          totalExams: data['examsCount'] ?? 0,
          studentGrowth: 0.0,
        );
      }
    });
  }
}
