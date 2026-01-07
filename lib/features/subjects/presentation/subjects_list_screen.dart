import 'package:flutter/material.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../data/subject_model.dart';
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
        
        _controller.loadSubjects(termId);
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
    final TextEditingController textController = TextEditingController(text: existingSubject?.title);
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    String termId = '1';
    try {
      termId = (termData as dynamic).id;
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(existingSubject == null ? 'Add Subject' : 'Edit Subject', 
              style: const TextStyle(color: AppColors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() {
                        selectedImage = File(image.path);
                      });
                    }
                  },
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : existingSubject != null && existingSubject.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  existingSubject.imageUrl.startsWith('http')
                                      ? existingSubject.imageUrl
                                      : '${ApiService.baseUrl}/${existingSubject.imageUrl}',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: AppColors.primary),
                                  SizedBox(height: 4),
                                  Text('Add Image', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                AppFormField(
                  controller: _controller,
                  fieldName: 'Title',
                  textEditingController: textController,
                  hintText: 'Subject Name',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool success = false;
                  if (existingSubject == null) {
                    success = await _controller.addSubject(termId, textController.text, image: selectedImage);
                  } else {
                    success = await _controller.editSubject(existingSubject.id, termId, textController.text);
                    // Note: Edit subject with image is not yet supported in controller/API based on previous code
                  }
                  
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                  } else {
                     if (_controller.errorMessage != null) {
                        ErrorSnackBar.show(context, _controller.errorMessage!);
                     }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
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
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete subject.')),
                );
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
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (_controller.subjects.isEmpty) {
             return const Center(child: Text('No subjects found', style: TextStyle(color: AppColors.textSecondary)));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _controller.subjects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subject = _controller.subjects[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    child: AppNetworkImage(
                      imagePath: subject.imageUrl,
                      width: 50,
                      height: 50,
                      borderRadius: 8,
                    ), 
                  ),
                  title: AutoDirection(
                    text: subject.title,
                    child: Text(
                      subject.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: Row(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
