import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart';
import 'package:upkeep_log/adapters/platform_attachment_picker.dart';
import 'package:upkeep_log/adapters/platform_reminder_adapter.dart';
import 'package:upkeep_log/adapters/platform_storage_path.dart';
import 'package:upkeep_log/adapters/private_attachment_store.dart';
import 'package:upkeep_log/application/attachment_service.dart';
import 'package:upkeep_log/application/reminder_coordinator.dart';
import 'package:upkeep_log/application/upkeep_workflow.dart';
import 'package:upkeep_log/domain/domain.dart';
import 'package:upkeep_log/presentation/upkeep_log_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory support = Directory(await applicationSupportPath());
  await support.create(recursive: true);
  final File databaseFile = File('${support.path}/upkeep-log.sqlite');
  final UpkeepDatabase database = UpkeepDatabase(
    NativeDatabase.createInBackground(databaseFile),
  );
  final DriftUpkeepRepository repository = DriftUpkeepRepository(database);
  const SystemClock clock = SystemClock();
  final ReminderCoordinator reminders = ReminderCoordinator(
    repository: repository,
    adapter: const PlatformReminderAdapter(),
    clock: clock,
  );
  var attachmentCounter = 0;
  runApp(
    UpkeepLogApp(
      workflow: UpkeepWorkflow(repository, clock: clock, reminders: reminders),
      attachments: AttachmentService(
        repository: repository,
        store: PrivateAttachmentStore(support),
        picker: const PlatformAttachmentPicker(),
        idFactory: (String kind) =>
            '$kind-${DateTime.now().toUtc().microsecondsSinceEpoch}-${attachmentCounter++}',
      ),
    ),
  );
}
