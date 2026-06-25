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
  /// Callback receives (title, image, sectionValue).
  /// sectionValue is the raw int: 0=None, 1=Taxation, 2=Institutions.
  final Future<bool> Function(String title, File? image, int sectionValue) onSave;
  final BaseController controller;
  final String? yearId;

  const SubjectDialog({
    super.key,
    this.subject,
    required this.onSave,
    required this.controller,
    this.yearId,
  });

  @override
  State<SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<SubjectDialog> {
  late TextEditingController _titleController;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Section _selectedSection;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.subject?.title ?? '');
    _selectedSection = widget.subject?.section ?? Section.taxation;
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
    
    // Compute the raw section int to send to the backend.
    // Year 6 = use the dropdown selection (1 or 2).
    // All other years = always send 0 (None) so the backend doesn't default incorrectly.
    final int sectionValue = widget.yearId == '6' ? _selectedSection.value : 0;
    
    final success = await widget.onSave(_titleController.text, _selectedImage, sectionValue);
      
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.subject != null ? 'Subject updated successfully' : 'Subject added successfully'),
          backgroundColor: Colors.green,
        ),
      );
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
                    if (widget.yearId == '6') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Section>(
                        value: _selectedSection,
                        decoration: InputDecoration(
                          labelText: 'الشعبة',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.textSecondary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: const [
                          DropdownMenuItem(value: Section.taxation, child: Text('ضرائب')),
                          DropdownMenuItem(value: Section.institutions, child: Text('مؤسسات')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSection = value;
                            });
                          }
                        },
                      ),
                    ],
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
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.black54,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isLoading 
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                      ),
                      SizedBox(width: 8),
                      Text('Saving...'),
                    ],
                  ) 
                : const Text('Save'),
            ),
          ],
        );
      }
    );
  }
}
