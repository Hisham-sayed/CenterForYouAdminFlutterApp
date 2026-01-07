import 'package:flutter/material.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../subjects_controller.dart';
import 'widgets/subject_card.dart';
import '../../../core/constants/app_routes.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final SubjectsController _controller = SubjectsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Subjects Management',
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _controller.categories.length,
            itemBuilder: (context, index) {
              final category = _controller.categories[index];
              return SubjectCard(
                title: category.name,
                icon: Icons.folder_open,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.years,
                    arguments: {
                      'data': category,
                      'breadcrumbs': ['Subjects'],
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
