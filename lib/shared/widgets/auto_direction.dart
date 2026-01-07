import 'package:flutter/material.dart';
import '../../core/utils/text_utils.dart';

class AutoDirection extends StatelessWidget {
  final String text;
  final Widget child;

  const AutoDirection({
    super.key,
    required this.text,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final direction = TextUtils.getDirection(text);
    return Directionality(
      textDirection: direction,
      child: child,
    );
  }
}
