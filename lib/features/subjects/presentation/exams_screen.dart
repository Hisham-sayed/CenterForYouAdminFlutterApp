import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../data/content_model.dart';
import '../data/subject_model.dart';
import '../subjects_controller.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dialog.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final SubjectsController _controller = SubjectsController();

  // Arguments
  List<String> breadcrumbs = [];
  Subject? subject;

  @override
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        breadcrumbs = List<String>.from(args['breadcrumbs'] ?? []);
        if (args['data'] is Subject) {
          subject = args['data'];
          _controller.loadExams(subject?.id ?? '0');
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchExam(String url) async {
    if (url.isEmpty) return;
    
    // Auto-prepend https if missing scheme
    String launchUrlString = url.trim();
    if (!launchUrlString.startsWith('http://') && !launchUrlString.startsWith('https://')) {
      launchUrlString = 'https://$launchUrlString';
    }

    final Uri uri = Uri.parse(launchUrlString);
    try {
      // Direct launch attempt (skip canLaunchUrl which can be flaky)
      final bool launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication, // Force external browser
      );

      if (!launched) {
        throw 'Could not launch $launchUrlString';
      }
    } catch (e) {
      if (!mounted) return;
      // Show Dialog instead of SnackBar for visibility
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error', style: TextStyle(color: AppColors.error)),
          content: Text('Could not open link:\n$launchUrlString\n\nError: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  void _showAddEditDialog({Exam? existingExam}) {
    final TextEditingController textController = TextEditingController(text: existingExam?.title);
    final TextEditingController linkController = TextEditingController(text: existingExam?.link ?? '');
    final subjectId = subject?.id ?? '0';

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: existingExam == null ? 'Add Exam' : 'Edit Exam',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: textController,
              hintText: 'Exam Title',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: linkController,
              hintText: 'Exam Link (Required)',
            ),
          ],
        ),
        onConfirm: () async {
          if (textController.text.isEmpty || linkController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter both title and link.')),
            );
            return;
          }

          bool success = false;
          if (existingExam == null) {
            success = await _controller.addExam(subjectId, textController.text, linkController.text);
          } else {
            success = await _controller.editExam(existingExam.id, subjectId, textController.text, linkController.text);
          }
          
          if (!context.mounted) return;
          if (success) {
            Navigator.pop(context);
          } else {
             if (_controller.hasError) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(_controller.validationSummary)),
               );
             }
          }
        },
      ),
    );
  }

  void _deleteExam(Exam exam) {
    final subjectId = subject?.id ?? '0';
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Delete Exam',
        content: const Text('Are you sure?', style: TextStyle(color: AppColors.textSecondary)),
        confirmText: 'Delete',
        onConfirm: () async {
          final success = await _controller.deleteExam(exam.id, subjectId);
          if (!context.mounted) return;
          if (success) {
             Navigator.pop(context);
          } else {
             if (_controller.hasError) {
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
    return AppScaffold(
      title: 'Exams',
      breadcrumbs: [...breadcrumbs, 'Exams'],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _controller.exams.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exam = _controller.exams[index];
              return Card(
                child: InkWell(
                  onTap: () => _launchExam(exam.link ?? ''),
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
                          child: const Icon(Icons.description, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exam.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (exam.link != null && exam.link!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  exam.link!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Open Exam',
                              icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                              onPressed: () => _launchExam(exam.link ?? ''),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                              onPressed: () => _showAddEditDialog(existingExam: exam),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _deleteExam(exam),
                            ),
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
