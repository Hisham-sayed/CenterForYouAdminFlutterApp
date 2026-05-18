import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../users_controller.dart';
import '../data/user_model.dart';
import '../../../../core/utils/random_password_generator.dart';

class AddEditStudentScreen extends StatefulWidget {
  final User? student;

  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final UsersController _controller = UsersController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int? _selectedCategory;
  final Map<int, String> _categories = {
    0: 'كلية',
    1: 'معهد',
    2: 'معادلة'
  };
  bool _isLoadingDetails = false;

  bool get _isEdit => widget.student != null;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameController.text = widget.student!.name;
      _emailController.text = widget.student!.email;
      _phoneController.text = widget.student!.phoneNumber ?? '';
      _selectedCategory = widget.student!.category;
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingDetails = true);
    try {
      final details = await _controller.getStudentDetails(widget.student!.id);
      if (details != null && mounted) {
        setState(() {
          _selectedCategory = details.category ?? _selectedCategory;
          if (_nameController.text.isEmpty) _nameController.text = details.name;
          if (_phoneController.text.isEmpty) _phoneController.text = details.phoneNumber ?? '';
        });
      }
    } catch (e) {
      debugPrint('Failed to load student details: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'category': _selectedCategory,
    };

    if (!_isEdit) {
      data['password'] = _passwordController.text; // no trim for password just in case
    }

    bool success = false;
    if (_isEdit) {
      success = await _controller.editStudent(widget.student!.id, data);
    } else {
      success = await _controller.addStudent(data);
    }

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Student updated successfully' : 'Student added successfully')),
      );
      Navigator.pop(context, true); // return true to indicate success
    } else {
      if (_controller.hasError) {
        final msg = _controller.validationErrors?.isNotEmpty == true 
            ? _controller.validationSummary 
            : _controller.errorMessage ?? 'An error occurred';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Student' : 'Add Student',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                hintText: 'Ahmed Ali (Name)',
                prefixIcon: Icons.person_outline,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                hintText: 'ahmed@example.com (Email)',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (!val.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                hintText: '01012345678 (Phone)',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (!_isEdit) ...[
                AppTextField(
                  controller: _passwordController,
                  hintText: 'StrongPassword123! (Password)',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.copy_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          if (_passwordController.text.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: _passwordController.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password copied to clipboard')),
                            );
                          }
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _passwordController.text = RandomPasswordGenerator.generate();
                            _obscurePassword = false; // Reveal so admin can see it
                          });
                        },
                        child: const Text('Generate', style: TextStyle(color: AppColors.primary)),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (val.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Category',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              if (_isEdit)
                 Text(
                   'Debug -> raw header category: ${widget.student!.category} | fetched: $_selectedCategory', 
                   style: const TextStyle(color: Colors.white24, fontSize: 10)
                 ),
              const SizedBox(height: 8),
              if (_isLoadingDetails)
                 const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
              else
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   decoration: BoxDecoration(
                     color: const Color(0xFF11141C),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                   ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCategory,
                    dropdownColor: const Color(0xFF1A1F2C),
                    hint: const Text('Select Category', style: TextStyle(color: AppColors.textSecondary)),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: _categories.entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _controller.isLoading ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _controller.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : Text(
                              _isEdit ? 'Save Changes' : 'Add Student',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
