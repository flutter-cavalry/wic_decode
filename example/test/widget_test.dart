import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wic_decode_example/main.dart';

void main() {
  testWidgets('Example app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
