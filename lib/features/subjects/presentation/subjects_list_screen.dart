import 'package:flutter/material.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../data/subject_model.dart';
import 'widgets/subject_dialog.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../subjects_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/app_network_image.dart';

import '../../../../shared/widgets/error_snackbar.dart';
import '../../../../shared/widgets/inline_error_text.dart';
import '../../../../shared/widgets/app_form_field.dart';
import '../../../../shared/widgets/auto_direction.dart';

class SubjectsListScreen extends StatefulWidget {
  const SubjectsListScreen({super.key});

  @override
  State<SubjectsListScreen> createState() => _SubjectsListScreenState();
}

class _SubjectsListScreenState extends State<SubjectsListScreen> {
  final SubjectsController _controller = SubjectsController();
  bool _initialized = false;
  bool _isFirstLoad = true;

  // Arguments
  dynamic termData;
  List<String> breadcrumbs = [];
  String screenTitle = 'Subjects';

  @override
    void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        termData = args['data'];
        breadcrumbs = List<String>.from(args['breadcrumbs'] ?? []);
        
        // Load Subjects for this term
        String termId = '1';
        try {
          screenTitle = (termData as dynamic).name;
          termId = (termData as dynamic).id;
        } catch (e) {
          screenTitle = 'Subjects';
        }
        
        _controller.loadSubjects(termId).whenComplete(() {
          if (mounted) {
            setState(() {
              _isFirstLoad = false;
            });
          }
        });
        _initialized = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddEditDialog({Subject? existingSubject}) {
    String termId = '1';
    try {
      termId = (termData as dynamic).id;
    } catch (_) {}

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental close while loading is implicit in dialog, but explicit property good too
      builder: (context) => SubjectDialog(
        subject: existingSubject,
        onSave: (title, image) async {
          bool success;
          if (existingSubject == null) {
            success = await _controller.addSubject(termId, title, image: image);
          } else {
            success = await _controller.editSubject(existingSubject.id, termId, title, image: image);
          }

          if (!success && mounted) {
             // Show error if failed
             ErrorSnackBar.show(context, _controller.errorMessage ?? 'An error occurred');
          }
          return success;
        },
      ),
    );
  }

  void _deleteSubject(Subject subject) {
    String termId = '1';
    try {
       termId = (termData as dynamic).id;
    } catch (_) {}
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Subject', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to delete this subject?', 
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final success = await _controller.deleteSubject(subject.id, termId);
              if (!context.mounted) return;
              if (success) {
                Navigator.pop(context);
              } else {
                 if (_controller.hasError && !_controller.hasValidationErrors) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_controller.errorMessage ?? 'Failed to delete subject.')),
                   );
                 }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullBreadcrumbs = [...breadcrumbs, screenTitle];

    return AppScaffold(
      title: screenTitle,
      breadcrumbs: fullBreadcrumbs,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
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
                         String termId = '1';
                         try { termId = (termData as dynamic).id; } catch (_) {}
                         _controller.loadSubjects(termId).whenComplete(() {
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
          
          if (_controller.subjects.isEmpty) {
             return const Center(child: Text('No subjects found', style: TextStyle(color: AppColors.textSecondary)));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _controller.subjects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subject = _controller.subjects[index];
              return Card(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context, 
                      AppRoutes.subjectDetail, 
                      arguments: {
                         'data': subject, 
                         'breadcrumbs': fullBreadcrumbs,
                      }
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(
                            imagePath: subject.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AutoDirection(
                            text: subject.title,
                            child: Text(
                              subject.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                              onPressed: () => _showAddEditDialog(existingSubject: subject),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _deleteSubject(subject),
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
