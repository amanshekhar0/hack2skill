import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaani_seva/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VaaniSevaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
