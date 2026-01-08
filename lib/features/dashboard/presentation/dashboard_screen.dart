import 'package:flutter/material.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../dashboard_controller.dart';
import 'widgets/stat_card.dart';
import '../../../../core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller = DashboardController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final stats = _controller.stats;
          
          // Use BaseController.isLoading
          if (_controller.isLoading && stats.totalStudents == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.hasError) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                   const SizedBox(height: 16),
                   Text(_controller.errorMessage!, style: const TextStyle(color: AppColors.error)),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: () => _controller.loadStats(), 
                     // Simple retry isn't exposed directly unless we separate loadStats.
                     // For now, let's just make sure it displays.
                     child: const Text('Retry'),
                   )
                 ],
               ),
             );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive Grid
                    // Responsive Wrap Layout
                    double spacing = 16;
                    double availableWidth = constraints.maxWidth;
                    // Dynamic columns based on width threshold
                    int columns = availableWidth > 900 ? 5 : availableWidth > 600 ? 3 : 2;
                    // Ensure minimum width for cards
                    if (availableWidth < 350) columns = 1;
                    
                    double itemWidth = (availableWidth - (spacing * (columns - 1))) / columns;

                    // Manual list of widgets since it was GridView.count with children
                    List<Widget> children = [
                        StatCard(
                          title: 'Students',
                          value: stats.totalStudents.toString(),
                          icon: Icons.people,
                        ),
                        StatCard(
                          title: 'Subjects',
                          value: stats.totalSubjects.toString(),
                          icon: Icons.library_books,
                        ),
                        StatCard(
                          title: 'Lessons',
                          value: stats.totalLessons.toString(),
                          icon: Icons.play_lesson,
                        ),
                        StatCard(
                          title: 'Videos',
                          value: stats.totalVideos.toString(),
                          icon: Icons.video_library,
                        ),
                        StatCard(
                          title: 'Exams',
                          value: stats.totalExams.toString(),
                          icon: Icons.assignment,
                        ),
                    ];
                    
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: children.map((child) => SizedBox(width: itemWidth, child: child)).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
