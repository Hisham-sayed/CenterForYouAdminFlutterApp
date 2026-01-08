import 'package:flutter/material.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../subjects/subjects_controller.dart';
import '../../subjects/data/subject_model.dart';
import '../data/year_model.dart';
import '../../subjects/presentation/widgets/subject_card.dart';
import '../../../core/constants/app_routes.dart';

class YearsTermsScreen extends StatefulWidget {
  final bool isYears; // true for Years screen, false for Terms screen

  const YearsTermsScreen({super.key, this.isYears = true});

  @override
  State<YearsTermsScreen> createState() => _YearsTermsScreenState();
}

class _YearsTermsScreenState extends State<YearsTermsScreen> {
  // We can reuse SubjectsController or create a specific one.
  // For simplicity, we just use the methods from SubjectsController here locally 
  // or instantiate it. 
  final SubjectsController _controller = SubjectsController();
  
  // Arguments
  SubjectCategory? category;
  AcademicYear? year;
  List<String> breadcrumbs = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is Map<String, dynamic>) {
      final data = args['data'];
      breadcrumbs = List<String>.from(args['breadcrumbs'] ?? []);
      
      if (widget.isYears && data is SubjectCategory) {
        category = data;
      } else if (!widget.isYears && data is AcademicYear) {
        year = data;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isYears ? (category?.name ?? 'Years') : (year?.name ?? 'Terms');
    final items = widget.isYears 
        ? _controller.getYearsForCategory(category?.id ?? '') 
        : _controller.getTermsForYear(year?.id ?? '');

    // Current full path for this screen (passed breadcrumbs + this title)
    // Actually typically the breadcrumb shows the path TO current.
    // The "Title" of the AppScaffold IS the current screen name.
    // The "Breadcrumbs" usually excludes current or includes it at the end.
    // Layout: Breadcrumbs are the title replacement.
    // So we should pass [Ancestors..., Current] to AppScaffold.
    
    final fullBreadcrumbs = [...breadcrumbs, title];

    return AppScaffold(
      title: title,
      breadcrumbs: fullBreadcrumbs,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate item width based on available space to behave like a Grid
            // typically 2 columns on mobile, more on tablet
            double spacing = 16;
            double availableWidth = constraints.maxWidth;
            int columns = availableWidth > 600 ? 4 : 2;
            double itemWidth = (availableWidth - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final String name = widget.isYears ? (item as AcademicYear).name : (item as AcademicTerm).name;
                final IconData icon = widget.isYears ? Icons.calendar_today : Icons.school;

                return SizedBox(
                  width: itemWidth,
                  child: SubjectCard(
                    title: name,
                    icon: icon,
                    onTap: () {
                      if (widget.isYears) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.terms,
                          arguments: {
                            'data': item,
                            'breadcrumbs': fullBreadcrumbs,
                          },
                        );
                      } else {
                        Navigator.pushNamed(
                          context, 
                          AppRoutes.subjectsList,
                          arguments: {
                            'data': item, // This is AcademicTerm
                            'breadcrumbs': fullBreadcrumbs,
                            'isTerm': true, 
                          }
                        );
                      }
                    },
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
