import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../users/users_controller.dart';


class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final UsersController _controller = UsersController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _udidController = TextEditingController();
  void _updateDevice() async {
    if (_emailController.text.isEmpty || _udidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Controller handles loading state
    final success = await _controller.updateDeviceId(_emailController.text.trim(), _udidController.text.trim());
    
    if (mounted) {
       if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device ID Updated Successfully')),
          );
          _emailController.clear();
          _udidController.clear();
       } else if (_controller.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_controller.errorMessage ?? 'Failed to update Device ID')),
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Device Management',
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reset User Device',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'User Email',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppFormField(
                      controller: _controller,
                      fieldName: 'email', // Logical field name
                      textEditingController: _emailController,
                      hintText: 'Enter user email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                     const Text(
                      'New Device ID (UDID)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppFormField(
                      controller: _controller,
                      fieldName: 'deviceId', // Logical field name
                      textEditingController: _udidController,
                      hintText: 'Enter new UDID',
                      prefixIcon: Icons.smartphone,
                    ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Device IDs are securely hashed. Resetting will allow the user to login from a new device.',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'Update Device ID',
                            isLoading: _controller.isLoading,
                            onPressed: _updateDevice,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
