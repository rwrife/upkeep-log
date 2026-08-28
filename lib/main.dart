import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:upkeep_log/adapters/database/drift_upkeep_repository.dart';
import 'package:upkeep_log/adapters/database/upkeep_database.dart';
import 'package:upkeep_log/adapters/platform_storage_path.dart';
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
  runApp(
    UpkeepLogApp(
      workflow: UpkeepWorkflow(
        DriftUpkeepRepository(database),
        clock: const SystemClock(),
      ),
    ),
  );
}
