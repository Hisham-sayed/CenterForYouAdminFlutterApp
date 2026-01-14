import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/architecture/base_controller.dart';

/// A reusable dialog widget that supports reactive loading states.
/// 
/// When [controller] is provided, the dialog will automatically:
/// - Disable both Cancel and Confirm buttons during loading
/// - Show a spinner with [loadingText] on the Confirm button
/// - Re-enable buttons when loading completes
/// 
/// This prevents double-tap issues and provides clear user feedback.
class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final String? cancelText;
  final String? confirmText;
  final String? loadingText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final BaseController? controller;
  /// Legacy static loading flag (use [controller] for reactive loading)
  final bool isLoading;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.cancelText = 'Cancel',
    this.confirmText = 'Save',
    this.loadingText,
    this.onCancel,
    this.onConfirm,
    this.controller,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // If controller is provided, wrap in ListenableBuilder for reactive updates
    if (controller != null) {
      return ListenableBuilder(
        listenable: controller!,
        builder: (context, _) => _buildDialog(context, controller!.isLoading),
      );
    }
    // Fallback to static isLoading flag
    return _buildDialog(context, isLoading);
  }

  Widget _buildDialog(BuildContext context, bool loading) {
    final displayText = loading 
        ? (loadingText ?? 'Processing...') 
        : confirmText!;

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
              onPressed: loading ? null : (onCancel ?? () => Navigator.pop(context)),
              child: Text(
                cancelText!,
                style: TextStyle(
                  color: loading 
                      ? AppColors.textSecondary.withValues(alpha: 0.5) 
                      : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: loading ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.black54,
              ),
              child: loading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(displayText),
                      ],
                    )
                  : Text(displayText),
            ),
          ],
    );
  }
}
