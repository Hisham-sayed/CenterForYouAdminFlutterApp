import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../users_controller.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/info_row.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/random_password_generator.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final UsersController _controller = UsersController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  int? _selectedCategoryFilter;
  final Map<int, String> _categories = {
    0: 'كلية',
    1: 'معهد',
    2: 'معادلة'
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _controller.fetchUsers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
    _controller.dispose(); 
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_controller.isLoading && !_controller.isLoadMoreRunning) {
        _controller.fetchUsers(
          isLoadMore: true, 
          searchKey: _searchController.text,
          category: _selectedCategoryFilter,
        );
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _controller.fetchUsers(
        searchKey: _searchController.text,
        category: _selectedCategoryFilter,
      );
    });
  }

  void _onCategoryFilterChanged(int? newCategory) {
    if (_selectedCategoryFilter == newCategory) return;
    setState(() {
      _selectedCategoryFilter = newCategory;
    });
    _controller.fetchUsers(
      searchKey: _searchController.text,
      category: _selectedCategoryFilter,
    );
  }

  void _showChangePasswordDialog(BuildContext context, dynamic user) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F2C),
            title: Text('Change Password for ${user.name}', style: const TextStyle(color: Colors.white)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: passwordController,
                    hintText: 'New Password',
                    obscureText: obscurePassword,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.copy_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            if (passwordController.text.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: passwordController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password copied to clipboard')),
                              );
                            }
                          },
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              passwordController.text = RandomPasswordGenerator.generate();
                              obscurePassword = false;
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                     Navigator.pop(ctx);
                     final success = await _controller.changeStudentPassword(user.id, passwordController.text);
                     if (!context.mounted) return;
                     if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Password changed successfully')),
                        );
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text(_controller.errorMessage ?? 'Failed to change password')),
                        );
                     }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                child: const Text('Change'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Students List',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.addEditStudent);
          if (result == true) {
             _controller.fetchUsers(
               searchKey: _searchController.text,
               category: _selectedCategoryFilter,
             );
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search by email or name...',
                  prefixIcon: Icons.search,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedCategoryFilter == null,
                          onSelected: (selected) {
                            if (selected) _onCategoryFilterChanged(null);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _selectedCategoryFilter == null ? Colors.black : Colors.white,
                          ),
                          backgroundColor: const Color(0xFF11141C),
                        ),
                      ),
                      ..._categories.entries.map((entry) {
                        final isSelected = _selectedCategoryFilter == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) _onCategoryFilterChanged(entry.key);
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                            backgroundColor: const Color(0xFF11141C),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                if (_controller.isLoading && _controller.filteredUsers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.hasError && _controller.filteredUsers.isEmpty) {
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
                               _controller.fetchUsers(
                                 searchKey: _searchController.text,
                                 category: _selectedCategoryFilter,
                               );
                            },
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (_controller.filteredUsers.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No students found',
                    icon: Icons.people_outline,
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _controller.filteredUsers.length + (_controller.isLoadMoreRunning ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _controller.filteredUsers.length) {
                       return const Center(child: Padding(
                         padding: EdgeInsets.all(8.0),
                         child: CircularProgressIndicator(),
                       ));
                    }
                    final user = _controller.filteredUsers[index];
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          collapsedIconColor: AppColors.textSecondary,
                          // ... existing ExpansionTile content ...
                          title: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600, 
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            user.email,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  Divider(color: Colors.grey.withValues(alpha: 0.1)),
                                  InfoRow(
                                    icon: Icons.email_outlined, 
                                    label: 'Email', 
                                    value: user.email,
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: user.email));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Email copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  InfoRow(
                                    icon: Icons.phone_outlined, 
                                    label: 'Phone', 
                                    value: user.phoneNumber ?? 'N/A',
                                    onTap: user.phoneNumber != null ? () {
                                      Clipboard.setData(ClipboardData(text: user.phoneNumber!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Phone number copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.addSubjectToUser,
                                              arguments: user,
                                            );
                                          },
                                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
                                          label: const Text(
                                            'Add Subjects',
                                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            // Confirm dialog with loading state
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (ctx) => AppDialog(
                                                title: 'Remove All Subjects',
                                                content: Text(
                                                  'Are you sure you want to remove all subjects for ${user.name}?',
                                                  style: const TextStyle(color: AppColors.textSecondary),
                                                ),
                                                controller: _controller,
                                                confirmText: 'Remove',
                                                loadingText: 'Removing...',
                                                onConfirm: () async {
                                                  final success = await _controller.deleteAllSubjects(user.id);
                                                  if (!context.mounted || !ctx.mounted) return;
                                                  if (success) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('All subjects removed successfully'),
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                                    Navigator.pop(ctx);
                                                  } else {
                                                    if (_controller.hasError) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text(_controller.errorMessage ?? 'Failed to remove subjects')),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.delete_sweep, color: AppColors.error, size: 18),
                                          label: const Text(
                                            'Remove All',
                                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.error, width: 1.5),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                             final result = await Navigator.pushNamed(
                                               context, 
                                               AppRoutes.addEditStudent, 
                                               arguments: user
                                             );
                                              if (result == true) {
                                                _controller.fetchUsers(
                                                  searchKey: _searchController.text,
                                                  category: _selectedCategoryFilter,
                                                );
                                             }
                                          },
                                          icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 18),
                                          label: const Text(
                                            'Edit Profile',
                                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            _showChangePasswordDialog(context, user);
                                          },
                                          icon: const Icon(Icons.lock_reset_outlined, color: Colors.amber, size: 18),
                                          label: const Text(
                                            'Password',
                                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.amber, width: 1.5),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (ctx) => AppDialog(
                                            title: 'Delete User',
                                            content: Text(
                                              'Are you sure you want to permanently delete ${user.name}? This action cannot be undone and all related user data will be lost.',
                                              style: const TextStyle(color: AppColors.textSecondary),
                                            ),
                                            controller: _controller,
                                            confirmText: 'Delete Permanently',
                                            loadingText: 'Deleting...',
                                            onConfirm: () async {
                                              final success = await _controller.deleteUser(user.email);
                                              if (!context.mounted || !ctx.mounted) return;
                                              if (success) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('User deleted successfully'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                                Navigator.pop(ctx);
                                              } else {
                                                if (_controller.hasError) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(_controller.errorMessage ?? 'Failed to delete user')),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.person_remove, color: AppColors.error, size: 18),
                                      label: const Text(
                                        'Delete User',
                                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.error, width: 1.5),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
// Removed _UserListCard class as it is replaced by inline ExpansionTile logic
