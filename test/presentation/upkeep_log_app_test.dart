import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/presentation/upkeep_log_app.dart';

void main() {
  testWidgets('launches to an honest local-first empty state', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(const UpkeepLogApp());

    expect(find.text('Upkeep Log'), findsOneWidget);
    expect(find.text('No upkeep tasks yet'), findsOneWidget);
    expect(
      find.text('No account or network connection is required.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('No upkeep tasks yet')),
      findsOneWidget,
    );

    semantics.dispose();
  });

  testWidgets('empty state fits a narrow phone viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const UpkeepLogApp());
    await tester.pumpAndSettle();

    expect(find.text('No upkeep tasks yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
