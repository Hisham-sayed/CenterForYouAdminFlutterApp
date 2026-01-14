import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../data/subject_model.dart';
import '../../../../shared/widgets/app_form_field.dart';
import '../../../../core/architecture/base_controller.dart';

class SubjectDialog extends StatefulWidget {
  final Subject? subject;
  final Future<bool> Function(String title, File? image) onSave;
  final BaseController controller;

  const SubjectDialog({
    super.key,
    this.subject,
    required this.onSave,
    required this.controller,
  });

  @override
  State<SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<SubjectDialog> {
  late TextEditingController _titleController;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.subject?.title ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true) return;
    
    // Controller handles loading state notification, but dialog creates a local loading UI?
    // Actually BaseController has isLoading. We should use it?
    // But SubjectDialog was cleaner managing its own simplistic loading.
    // However, since we pass controller, we can use its loading state if desired, 
    // OR just rely on the await.
    // The issue is: if safeCall is used in parent, controller.isLoading becomes true.
    // If we listen to controller (which AppFormField does), we might want to listen here too for button state.
    
    // Call the provided onSave function
    final success = await widget.onSave(_titleController.text, _selectedImage);
      
    if (mounted && success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.subject != null;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isLoading = widget.controller.isLoading;

        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            isEdit ? 'Edit Subject' : 'Add Subject',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400, 
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: isLoading ? null : _pickImage,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : (isEdit && widget.subject!.imageUrl.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      widget.subject!.imageUrl.startsWith('http')
                                          ? widget.subject!.imageUrl
                                          : '${ApiService.baseUrl}/${widget.subject!.imageUrl}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, color: AppColors.primary, size: 32),
                                      SizedBox(height: 8),
                                      Text('Add Image', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title Field using AppFormField
                    AppFormField(
                      controller: widget.controller,
                      fieldName: 'Title', // backend field name
                      textEditingController: _titleController,
                      hintText: 'Subject Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                  ) 
                : const Text('Save'),
            ),
          ],
        );
      }
    );
  }
}
