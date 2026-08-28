import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart'
    hide TaskTemplate;
import 'package:upkeep_log/application/upkeep_workflow.dart';
import 'package:upkeep_log/domain/domain.dart';
import 'package:upkeep_log/presentation/upkeep_log_app.dart';

void main() {
  late UpkeepDatabase database;
  late UpkeepWorkflow workflow;
  var sequence = 0;

  setUp(() {
    database = UpkeepDatabase(NativeDatabase.memory());
    workflow = UpkeepWorkflow(
      DriftUpkeepRepository(database),
      clock: FakeClock(
        DateTime.utc(2026, 4, 10, 12),
        today: LocalDate(2026, 4, 10),
        timeZoneId: 'UTC',
      ),
      idFactory: (String kind) => '$kind-${sequence++}',
    );
  });

  tearDown(() => database.close());

  testWidgets('launches to an accessible local-first first-run state', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
    await tester.pumpAndSettle();

    expect(find.text('Upkeep Log'), findsOneWidget);
    expect(find.text('Start your local upkeep log'), findsOneWidget);
    expect(find.textContaining('No account or network'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Start your local upkeep log')),
      findsOneWidget,
    );
    expect(find.text('Create home profile'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('create to due to complete workflow records all details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create home profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Home name'),
      'My home',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Task name'),
      'Change filter',
    );
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Due'));
    await tester.pumpAndSettle();
    expect(find.text('Change filter'), findsOneWidget);
    expect(find.textContaining('Due today'), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp('Change filter.*Due today')),
      findsOneWidget,
    );

    await tester.tap(find.text('Complete Change filter'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes (optional)'),
      'Replaced on time',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Parts used (optional)'),
      '20x20 filter',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cost (optional)'),
      '12.99',
    );
    await tester.tap(find.text('Record completion'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Completed 2026-04-10'), findsOneWidget);
    expect(find.textContaining('Replaced on time'), findsOneWidget);
    expect(find.textContaining('Parts: 20x20 filter'), findsOneWidget);
    expect(find.textContaining('Cost: USD 12.99'), findsOneWidget);
  });

  testWidgets('validation survives narrow layout and large text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create home profile'));
    await tester.tap(find.text('Create home profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('This field is required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('early and late completions show domain-derived next dates', (
    WidgetTester tester,
  ) async {
    await workflow.saveHome(HomeProfile(id: 'h', name: 'Home'));
    await workflow.createTask(
      TaskTemplate(
        id: 'early',
        homeId: 'h',
        name: 'Early task',
        startDate: LocalDate(2026, 4, 15),
        recurrence: FixedDayRecurrence(30),
      ),
    );
    await workflow.createTask(
      TaskTemplate(
        id: 'late',
        homeId: 'h',
        name: 'Late task',
        startDate: LocalDate(2026, 4, 1),
        recurrence: FixedDayRecurrence(
          30,
          anchor: RecurrenceAnchor.actualCompletionDate,
        ),
      ),
    );
    await tester.pumpWidget(UpkeepLogApp(workflow: workflow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Early task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record completion'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Scheduled 2026-05-15'), findsOneWidget);

    await tester.tap(find.text('Due'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Late task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record completion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Scheduled 2026-05-10'), findsOneWidget);
  });
}
