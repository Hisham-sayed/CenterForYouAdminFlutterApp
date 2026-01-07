import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/main.dart';

void main() {
  testWidgets('AdminApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AdminApp());
    
    // Trigger a frame to allow async data (if any) to settle, though currently mocks have delays.
    // simpler test: verify it builds without error.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
