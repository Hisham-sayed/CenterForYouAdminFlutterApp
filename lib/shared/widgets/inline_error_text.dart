import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class InlineErrorText extends StatelessWidget {
  final String? errorText;

  const InlineErrorText(this.errorText, {super.key});

  @override
  Widget build(BuildContext context) {
    if (errorText == null || errorText!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        errorText!,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
