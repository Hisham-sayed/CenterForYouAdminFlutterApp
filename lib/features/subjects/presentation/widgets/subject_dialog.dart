import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../data/subject_model.dart';

class SubjectDialog extends StatefulWidget {
  final Subject? subject;
  final Future<bool> Function(String title, File? image) onSave;

  const SubjectDialog({
    super.key,
    this.subject,
    required this.onSave,
  });

  @override
  State<SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<SubjectDialog> {
  late TextEditingController _titleController;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
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
    
    setState(() => _isLoading = true);

    try {
      // Call the provided onSave function
      final success = await widget.onSave(_titleController.text, _selectedImage);
      
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
        } else {
          // If failure, stop loading so user can try again or cancel
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.subject != null;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        isEdit ? 'Edit Subject' : 'Add Subject',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400, // Limit width for large screens
        ),
        child: SingleChildScrollView(
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
                    
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isLoading,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Subject Name',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.textSecondary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                      ),
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
             ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black, // Assuming primary is bright
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading 
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
}
