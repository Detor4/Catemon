import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cat_detector_app/main.dart';

void main() {
  testWidgets('App starts on home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // flutter_animate uses Future.delayed for entrance delays; advance past them.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Catemon'), findsOneWidget);
    expect(find.text('Kolleksiya'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsWidgets);

    // Tear down the animated widgets so repeating tickers are disposed.
    await tester.pumpWidget(const SizedBox());
  });
}
