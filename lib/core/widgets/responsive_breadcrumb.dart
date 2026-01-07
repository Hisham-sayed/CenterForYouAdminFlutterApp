import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ResponsiveBreadcrumb extends StatelessWidget {
  final List<String> items;

  const ResponsiveBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        
        // Try calculating full width
        // We can't easily calculate exact text width without Paint or TextPainter layout
        // So we will use a naive approach or just standard text overflow logic.
        // The prompt specifically asks to:
        // "If the path fits... Display it normally"
        // "If the path exceeds... Collapse the middle items... Keep The current level, The direct parent level"

        // Let's assume we construct the string first
        // If we just use a Row with Flexible/Expanded, Flutter handles truncation for us
        // But we want specific intelligent truncation "Middle Ellipsis".
        
        // Strategy:
        // 1. Always show the Last Item (Current Level)
        // 2. Always show the Second to Last Item (Parent Level)
        // 3. Always show the First Item? Prompt example: "... -> Parent -> Current"
        // Wait, prompt says: "Example: … ← كلية تجارة ← إدارة المواد"
        // Which means: Ellipsis -> Parent -> Current.
        // It drops the ancestors completely replaced by "...".
        
        // We can check if "Full String" fits.
        
        // Helper to estimate text width (approximate is fine for UI logic usually, but exact is better)
        // Using TextPainter is expensive in build, but feasible for simple strings.
        
        final fullTextSpan = TextSpan(
          text: items.join(' > '),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal), // Approximate AppBar style
        );
        
        final textPainter = TextPainter(
          text: fullTextSpan,
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        final bool fits = textPainter.width < maxWidth;

        if (fits || items.length < 3) {
          // Render Full Path
          return _buildBreadcrumbRow(items);
        } else {
          // Render Collapsed Path
          // ... > Parent > Current
          final List<String> collapsedItems = [
            '...',
            items[items.length - 2],
            items.last
          ];
          return _buildBreadcrumbRow(collapsedItems, isCollapsed: true);
        }
      },
    );
  }

  Widget _buildBreadcrumbRow(List<String> itemsToRender, {bool isCollapsed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < itemsToRender.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
            ),
          Flexible(
            flex: i == itemsToRender.length - 1 ? 2 : 1, // Current item gets more space priority
            child: Text(
              itemsToRender[i],
              style: TextStyle(
                color: i == itemsToRender.length - 1 ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 16,
                fontWeight: i == itemsToRender.length - 1 ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ],
    );
  }
}
