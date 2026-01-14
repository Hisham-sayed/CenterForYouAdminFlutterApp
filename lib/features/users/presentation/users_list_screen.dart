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
        _controller.fetchUsers(isLoadMore: true, searchKey: _searchController.text);
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _controller.fetchUsers(searchKey: _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Students List',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Search by email or name...',
              prefixIcon: Icons.search,
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
                               _controller.fetchUsers(searchKey: _searchController.text);
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
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          // Confirm dialog
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Remove All Subjects'),
                                              content: Text('Are you sure you want to remove all subjects for ${user.name}?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, true), 
                                                  child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await _controller.deleteAllSubjects(user.id);
                                            setState(() {}); // Rebuild to show updated status
                                          }
                                        },
                                        icon: const Icon(Icons.delete_sweep, color: AppColors.error),
                                        label: const Text(
                                          'Remove all subjects',
                                          style: TextStyle(color: AppColors.error),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppColors.error),
                                        ),
                                      ),
                                    ],
                                  )
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
