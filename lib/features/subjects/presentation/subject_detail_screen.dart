import 'package:flutter/material.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/constants/app_routes.dart';
import '../data/subject_model.dart'; 
import 'widgets/subject_card.dart';

class SubjectDetailScreen extends StatelessWidget {
  const SubjectDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String title = 'Subject Content';
    List<String> breadcrumbs = [];
    Subject? subject;
    
    if (args is Map<String, dynamic>) {
      if (args['data'] is Subject) {
        subject = args['data'];
        title = subject?.title ?? 'Subject';
      } else {
        title = args['data'].toString();
      }
      breadcrumbs = List<String>.from(args['breadcrumbs'] ?? []);
    } else if (args is String) {
      title = args;
    }

    final fullBreadcrumbs = [...breadcrumbs, title];

    return AppScaffold(
      title: title,
      breadcrumbs: fullBreadcrumbs,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  SubjectCard(
                    title: 'Exams',
                    icon: Icons.description_outlined,
                    onTap: () => Navigator.pushNamed(
                      context, 
                      AppRoutes.exams,
                      arguments: {
                        'data': subject, // Pass Subject object
                        'breadcrumbs': fullBreadcrumbs,
                      }
                    ),
                  ),
                  SubjectCard(
                    title: 'Lessons',
                    icon: Icons.video_library_outlined,
                    onTap: () => Navigator.pushNamed(
                      context, 
                      AppRoutes.lessons,
                      arguments: {
                        'data': subject, // Pass Subject object
                        'breadcrumbs': fullBreadcrumbs,
                      }
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
