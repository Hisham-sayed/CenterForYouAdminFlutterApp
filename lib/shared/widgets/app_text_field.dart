import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import '../../core/utils/text_utils.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  TextDirection _textDirection = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!.addListener(_handleControllerChange);
      _handleControllerChange(); // Initial check
    }
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller!.removeListener(_handleControllerChange);
    }
    super.dispose();
  }

  void _handleControllerChange() {
    final text = widget.controller!.text;
    _updateDirection(text);
  }

  void _handleChanged(String value) {
    _updateDirection(value);
    widget.onChanged?.call(value);
  }

  void _updateDirection(String text) {
    if (text.isEmpty) return; // Keep previous or default
    final direction = TextUtils.getDirection(text);
    if (direction != _textDirection) {
      setState(() {
        _textDirection = direction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onChanged: _handleChanged,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textDirection: _textDirection,
      validator: widget.validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: AppColors.textSecondary) : null,
        errorText: widget.errorText, // Use the error text here
        errorStyle: const TextStyle(color: AppColors.error), 
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
    );
  }
}
