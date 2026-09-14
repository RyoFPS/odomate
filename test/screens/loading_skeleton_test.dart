import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/widgets/loading_skeleton.dart';

void main() {
  testWidgets('loading skeleton uses the active dark surface color', (
    tester,
  ) async {
    const color = Color(0xFF303030);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          colorScheme: ThemeData.dark().colorScheme.copyWith(
            surfaceContainerHighest: color,
          ),
        ),
        home: const Scaffold(body: LoadingSkeleton()),
      ),
    );

    expect(
      find.byWidgetPredicate((widget) =>
          widget is ColoredBox && widget.color == color),
      findsWidgets,
    );
  });
}
