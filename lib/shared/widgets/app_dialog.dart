import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final String? cancelText;
  final String? confirmText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.cancelText = 'Cancel',
    this.confirmText = 'Save',
    this.onCancel,
    this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: content,
      actions: actions ??
          [
            TextButton(
              onPressed: onCancel ?? () => Navigator.pop(context),
              child: Text(
                cancelText!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : onConfirm,
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(confirmText!),
            ),
          ],
    );
  }
}
