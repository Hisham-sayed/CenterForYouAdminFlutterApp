import 'package:flutter/material.dart';
import '../../features/auth/auth_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';

import '../widgets/responsive_breadcrumb.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final List<String>? breadcrumbs;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    bool showBreadcrumbs = breadcrumbs != null && breadcrumbs!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: showBreadcrumbs 
          ? ResponsiveBreadcrumb(items: breadcrumbs!)
          : Text(title),
        actions: actions,
        leading: showBreadcrumbs
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            )
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: AppColors.primary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      ),
      drawer: const _AppDrawer(),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                // Drawer Header
                Container(
                  padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Admin Hub',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation Items
                const SizedBox(height: 10),
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: AppRoutes.dashboard,
                ),
                _DrawerItem(
                  icon: Icons.people_outline,
                  label: 'Students',
                  route: AppRoutes.users,
                ),
                _DrawerItem(
                  icon: Icons.library_books_outlined,
                  label: 'Subjects',
                  route: AppRoutes.subjects,
                ),
                _DrawerItem(
                  icon: Icons.celebration, // Party popper alternative
                  label: 'Graduation Parties',
                  route: AppRoutes.graduation,
                ),
                _DrawerItem(
                   icon: Icons.person_add_outlined,
                   label: 'Add Subject to User',
                   route: AppRoutes.addSubjectToUser,
                ),
                _DrawerItem(
                   icon: Icons.smartphone,
                   label: 'Device Management',
                   route: AppRoutes.deviceManagement,
                ),
                const Spacer(),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    await AuthController().logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context, 
                        AppRoutes.login, 
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = ModalRoute.of(context)?.settings.name == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          } else {
            Navigator.pop(context); // Close drawer
          }
        },
      ),
    );
  }
}
