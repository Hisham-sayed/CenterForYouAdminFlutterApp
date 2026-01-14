import 'package:flutter/material.dart';
import '../../core/architecture/base_controller.dart';
import 'app_text_field.dart';

class AppFormField extends StatelessWidget {
  final BaseController controller;
  final String fieldName;
  final TextEditingController textEditingController;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AppFormField({
    super.key,
    required this.controller,
    required this.fieldName,
    required this.textEditingController,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final error = controller.getFieldError(fieldName);
       
        return AppTextField(
          controller: textEditingController,
          hintText: hintText,
          prefixIcon: prefixIcon,
          obscureText: obscureText,
          keyboardType: keyboardType,
          errorText: error, 
          validator: validator,
        );
      },
    );
  }
}
