import 'package:flutter/material.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../data/content_model.dart';
import '../data/subject_model.dart';
import '../subjects_controller.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_form_field.dart';
import '../../../../shared/widgets/auto_direction.dart';
import '../../../../shared/widgets/app_dialog.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final SubjectsController _controller = SubjectsController();
  bool _isFirstLoad = true;

  // Arguments
  List<String> breadcrumbs = [];
  Subject? subject;

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
      breadcrumbs = List<String>.from(args['breadcrumbs'] ?? []);
      if (args['data'] is Subject) {
        subject = args['data'];
        _controller.loadLessons(subject?.id ?? '0').whenComplete(() {
          if (mounted) {
            setState(() {
              _isFirstLoad = false;
            });
          }
        });
      }
    }
  }

  void _showAddEditDialog({Lesson? existingLesson, int? index}) {
    final TextEditingController textController = TextEditingController(text: existingLesson?.title);
    final subjectId = subject?.id ?? '0';

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: existingLesson == null ? 'Add Lesson Folder' : 'Edit Folder',
        content: AppFormField(
          controller: _controller,
          fieldName: 'Title',
          textEditingController: textController,
          hintText: 'Folder Name',
        ),
        onConfirm: () async {
          bool success = false;
          if (existingLesson == null) {
            success = await _controller.addLesson(subjectId, textController.text);
          } else {
            success = await _controller.editLesson(existingLesson.id, subjectId, textController.text);
          }
          
          if (!context.mounted) return;
          if (success) {
            Navigator.pop(context);
          } else {
             if (_controller.hasError && !_controller.hasValidationErrors) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(_controller.validationSummary)),
               );
             }
          }
        },
      ),
    );
  }

  void _deleteLesson(Lesson lesson) {
    final subjectId = subject?.id ?? '0';
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Delete Folder',
        content: const Text('Are you sure? This will delete all videos inside.', 
            style: TextStyle(color: AppColors.textSecondary)),
        confirmText: 'Delete',
        onConfirm: () async {
          final success = await _controller.deleteLesson(lesson.id, subjectId);
          if (!context.mounted) return;
          if (success) {
            Navigator.pop(context);
          } else {
             if (_controller.hasError && !_controller.hasValidationErrors) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(_controller.validationSummary)),
               );
             }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullBreadcrumbs = [...breadcrumbs, 'Lessons'];

    return AppScaffold(
      title: 'Lessons',
      breadcrumbs: fullBreadcrumbs,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.create_new_folder, color: Colors.black),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_isFirstLoad || _controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.signal_wifi_off, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      _controller.errorMessage ?? 'Connection Error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                         setState(() { _isFirstLoad = true; });
                         _controller.loadLessons(subject?.id ?? '0').whenComplete(() {
                            if (mounted) setState(() { _isFirstLoad = false; });
                         });
                      },
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }

          if (_controller.lessons.isEmpty) {
            return const Center(child: Text('No lessons found', style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _controller.lessons.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lesson = _controller.lessons[index];
              return Card(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context, 
                      AppRoutes.videos, 
                      arguments: {
                         'data': lesson,
                         'breadcrumbs': fullBreadcrumbs,
                      }
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.folder, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AutoDirection(
                            text: lesson.title,
                            child: Text(
                              lesson.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                              onPressed: () => _showAddEditDialog(existingLesson: lesson),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _deleteLesson(lesson),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
