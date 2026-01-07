import 'package:flutter/material.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../core/constants/app_routes.dart';
import '../users_controller.dart';
import '../data/user_model.dart';
import '../../subjects/subjects_controller.dart';
import '../../subjects/data/subject_model.dart';
import '../../years_terms/data/year_model.dart';

class AddSubjectToUserScreen extends StatefulWidget {
  const AddSubjectToUserScreen({super.key});

  @override
  State<AddSubjectToUserScreen> createState() => _AddSubjectToUserScreenState();
}

class _AddSubjectToUserScreenState extends State<AddSubjectToUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final UsersController _usersController = UsersController();
  final SubjectsController _subjectsController = SubjectsController();
  
  bool _isLoading = false;
  bool _userFound = false;
  User? _foundUser;

  // Selection State
  SubjectCategory? _selectedCategory;
  AcademicYear? _selectedYear;
  AcademicTerm? _selectedTerm;
  final Set<String> _selectedSubjectIds = {}; // Store IDs instead of Subject objects

  @override
  void initState() {
    super.initState();
    // Categories are loaded in constructor of SubjectsController, but we can trigger refresh if needed
  }

  Future<void> _checkUser() async {
    setState(() => _isLoading = true);
    final user = await _usersController.checkUser(_emailController.text.trim());
    setState(() {
      _isLoading = false;
      if (user != null) {
        _userFound = true;
        _foundUser = user;
        
        // Pre-fill logic
        _selectedSubjectIds.clear();
        if (user.hasEnrolledSubjects) {
          _selectedSubjectIds.addAll(user.enrolledSubjectIds.map((e) => e.toString()));
        }
      } else {
        _userFound = false;
        _foundUser = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    });
  }

  Future<void> _onSave() async {
    if (_foundUser == null) return;
    
    final List<String> subjectIds = _selectedSubjectIds.toList();
    // Use verified PUT endpoint (unless user strictly requests POST, but PUT is verified)
    final bool result = await _usersController.addSubjectToUser(_foundUser!.id, subjectIds);
    
    int successCount = 0;
    if (result) successCount = subjectIds.length;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated $successCount subjects for user')),
    );
    // Since sidebar uses pushReplacement, pop() causes black screen (empty stack).
    // Navigate to users list instead.
    Navigator.pushReplacementNamed(context, AppRoutes.users);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Add/Update Subjects to User',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage student enrollments by entering their email address',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Check User Card
            Card(
              color: const Color(0xFF1A1F2C), // Dark Card Base
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Email Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _emailController,
                          hintText: 'Enter student email',
                          prefixIcon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _checkUser,
                            icon: _isLoading 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                              : const Icon(Icons.search, color: Colors.black),
                            label: const Text('Check User', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Result Section (Hidden until user found)
            if (_userFound && _foundUser != null) ...[
              const SizedBox(height: 24),
              
              // User Details Card
              Card(
                color: const Color(0xFF1A1F2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundUser!.name,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 16),
                                const SizedBox(width: 8),
                                Text(_foundUser!.email, style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                            if (_foundUser!.phoneNumber != null && _foundUser!.phoneNumber!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 16),
                                    const SizedBox(width: 8),
                                    Text(_foundUser!.phoneNumber!, style: const TextStyle(color: AppColors.textSecondary)),
                                  ],
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Hierarchy Selection Card
              Card(
                color: const Color(0xFF1A1F2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                   side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Subjects',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Category Selection
                      _buildSectionHeader('CATEGORY'),
                      const SizedBox(height: 12),
                      ListenableBuilder(
                        listenable: _subjectsController,
                        builder: (context, _) => _buildSelectionGrid(
                          _subjectsController.categories.map((e) => e.name).toList(),
                          _selectedCategory?.name,
                          (val) {
                            setState(() {
                              _selectedCategory = _subjectsController.categories.firstWhere((e) => e.name == val);
                              _selectedYear = null; 
                              _selectedTerm = null;
                              // Do NOT clear _selectedSubjectIds here to preserve selection
                              _subjectsController.subjects = []; // Clear subjects view
                            });
                          }
                        ),
                      ),

                      // Year Selection
                      if (_selectedCategory != null) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('YEAR'),
                        const SizedBox(height: 12),
                        _buildSelectionGrid(
                          _subjectsController.getYearsForCategory(_selectedCategory!.id).map((e) => e.name).toList(),
                          _selectedYear?.name,
                          (val) {
                            setState(() {
                              _selectedYear = _subjectsController.getYearsForCategory(_selectedCategory!.id).firstWhere((e) => e.name == val);
                              _selectedTerm = null; 
                              _subjectsController.subjects = [];
                            });
                          }
                        ),
                      ],

                       // Term Selection
                      if (_selectedYear != null) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('TERM'),
                        const SizedBox(height: 12),
                        _buildSelectionGrid(
                          _subjectsController.getTermsForYear(_selectedYear!.id).map((e) => e.name).toList(),
                          _selectedTerm?.name,
                          (val) {
                            setState(() {
                              _selectedTerm = _subjectsController.getTermsForYear(_selectedYear!.id).firstWhere((e) => e.name == val);
                              _subjectsController.loadSubjects(_selectedTerm!.id);
                            });
                          }
                        ),
                      ],

                      const SizedBox(height: 32),
                      
                      // Available Subjects
                      ListenableBuilder(
                        listenable: _subjectsController,
                        builder: (context, _) {
                            final subjects = _subjectsController.subjects;
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AVAILABLE SUBJECTS (${subjects.length})',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  if (subjects.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), style: BorderStyle.solid),
                                        color: Colors.transparent,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            _subjectsController.isLoading 
                                                ? 'Loading subjects...' 
                                                : 'Select a category, year, and term to view subjects',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ...subjects.map((subject) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildSubjectCheckbox(subject),
                                    )),
                                ],
                            );
                        }
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _selectedSubjectIds.isNotEmpty ? _onSave : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 20),
                              SizedBox(width: 8),
                              Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSelectionGrid(List<String> items, String? selectedItem, Function(String) onSelect) {
    return Column(
      children: items.map((item) {
        final isSelected = item == selectedItem;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onSelect(item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFF11141C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectCheckbox(Subject subject) {
    final isSelected = _selectedSubjectIds.contains(subject.id);
    // Check if subject is originally enrolled for special styling? 
    // The requirement says "UI must clearly distinguish Already enrolled subjects".
    // We can do this if we keep the original list separate.
    bool wasEnrolled = false;
    if (_foundUser != null && _foundUser!.hasEnrolledSubjects) {
       wasEnrolled = _foundUser!.enrolledSubjectIds.contains(int.tryParse(subject.id) ?? -1);
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSubjectIds.remove(subject.id);
          } else {
            _selectedSubjectIds.add(subject.id);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF11141C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.primary,
                  width: 2,
                ),
              ),
              child: isSelected 
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (wasEnrolled)
                    const Text(
                       'Previously Enrolled',
                       style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
