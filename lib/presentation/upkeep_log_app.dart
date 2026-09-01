import 'dart:async';

import 'package:flutter/material.dart';
import 'package:upkeep_log/application/attachment_service.dart';
import 'package:upkeep_log/application/data_portability.dart';
import 'package:upkeep_log/application/history.dart';
import 'package:upkeep_log/application/reminder_coordinator.dart';
import 'package:upkeep_log/application/upkeep_workflow.dart';
import 'package:upkeep_log/domain/domain.dart';

/// Root widget for the local-first Upkeep Log application.
class UpkeepLogApp extends StatelessWidget {
  const UpkeepLogApp({
    required this.workflow,
    this.attachments,
    this.portability,
    this.dataTransfer,
    super.key,
  });

  final UpkeepWorkflow workflow;
  final AttachmentService? attachments;
  final DataPortability? portability;
  final DataTransfer? dataTransfer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Upkeep Log',
      theme: _theme(Brightness.light, const Color(0xFF2E6F5E)),
      darkTheme: _theme(Brightness.dark, const Color(0xFF74C7AD)),
      themeMode: ThemeMode.system,
      home: WorkflowScreen(
        workflow: workflow,
        attachments: attachments,
        portability: portability,
        dataTransfer: dataTransfer,
      ),
    );
  }

  ThemeData _theme(Brightness brightness, Color seed) => ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(brightness: brightness, seedColor: seed),
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({
    required this.workflow,
    this.attachments,
    this.portability,
    this.dataTransfer,
    super.key,
  });

  final UpkeepWorkflow workflow;
  final AttachmentService? attachments;
  final DataPortability? portability;
  final DataTransfer? dataTransfer;

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen>
    with WidgetsBindingObserver {
  WorkflowSnapshot? _snapshot;
  Object? _error;
  Future<void> Function()? _retryOperation;
  bool _loading = true;
  int _page = 0;
  int _idCounter = 0;
  Object? _pendingSnooze;
  String _historyText = '';
  String? _historyAssetId;
  String? _historyRoomId;
  HistoryStatus _historyStatus = HistoryStatus.all;
  LocalDate? _historyFrom;
  LocalDate? _historyTo;
  Future<LocalStorageSummary>? _storageSummary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _storageSummary = widget.portability?.storageSummary();
    unawaited(_reload());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading) {
      unawaited(_reload());
    }
  }

  String _id(String kind) =>
      '$kind-${DateTime.now().toUtc().microsecondsSinceEpoch}-${_idCounter++}';

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final WorkflowSnapshot value = await widget.workflow.load();
      final Future<LocalStorageSummary>? storage = widget.portability
          ?.storageSummary();
      if (mounted) {
        setState(() {
          _snapshot = value;
          _storageSummary = storage;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
      _retryOperation = null;
      await _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _retryOperation = operation;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save. Your entered values are retained for retry: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final WorkflowSnapshot? snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upkeep Log'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reload local data',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(child: _body(snapshot)),
      bottomNavigationBar: snapshot == null || snapshot.homes.isEmpty
          ? null
          : NavigationBar(
              selectedIndex: _page,
              onDestinationSelected: (int value) =>
                  setState(() => _page = value),
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.today_outlined),
                  selectedIcon: Icon(Icons.today),
                  label: 'Due',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_outlined),
                  selectedIcon: Icon(Icons.event),
                  label: 'Upcoming',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Completed',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Setup',
                ),
                NavigationDestination(
                  icon: Icon(Icons.privacy_tip_outlined),
                  selectedIcon: Icon(Icons.privacy_tip),
                  label: 'Data',
                ),
              ],
            ),
    );
  }

  Widget _body(WorkflowSnapshot? snapshot) {
    if (_loading && snapshot == null) {
      return Center(
        child: Semantics(
          label: 'Loading upkeep from this device',
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (snapshot == null) {
      return _ErrorState(error: _error, onRetry: _reload);
    }
    if (snapshot.homes.isEmpty) return _firstHome(snapshot);
    return Column(
      children: <Widget>[
        if (_error != null || _retryOperation != null)
          MaterialBanner(
            content: Text(
              _retryOperation == null
                  ? 'Local load failed: $_error'
                  : 'Local save failed. Your entered values are retained: $_error',
            ),
            actions: <Widget>[
              if (_retryOperation != null)
                TextButton(
                  onPressed: () => _run(_retryOperation!),
                  child: const Text('Retry save'),
                ),
              TextButton(
                onPressed: () => setState(() {
                  _error = null;
                  _retryOperation = null;
                }),
                child: Text(
                  _retryOperation == null
                      ? 'Dismiss'
                      : 'Discard retained draft',
                ),
              ),
            ],
          ),
        Expanded(
          child: switch (_page) {
            0 => _duePage(snapshot),
            1 => _occurrenceList(
              snapshot,
              snapshot.inBucket(OccurrenceBucket.upcoming),
              emptyTitle: 'Nothing upcoming',
              emptyBody: 'Future upkeep will appear here after you create a recurring task.',
            ),
            2 => _completedPage(snapshot),
            3 => _setupPage(snapshot),
            _ => _dataPage(snapshot),
          },
        ),
      ],
    );
  }

  Widget _firstHome(WorkflowSnapshot snapshot) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ExcludeSemantics(
              child: Icon(Icons.home_repair_service_outlined, size: 64),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                'Start your local upkeep log',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create a home profile, then add rooms, assets, and upkeep tasks. '
              'No account or network connection is required.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _editHome(null),
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('Create home profile'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _duePage(WorkflowSnapshot snapshot) {
    final List<TaskOccurrence> overdue = snapshot.inBucket(
      OccurrenceBucket.overdue,
    );
    final List<TaskOccurrence> due = snapshot.inBucket(OccurrenceBucket.due);
    final List<TaskOccurrence> snoozed = snapshot.inBucket(
      OccurrenceBucket.snoozed,
    );
    if (<TaskOccurrence>[...overdue, ...due, ...snoozed].isEmpty) {
      return _EmptyState(
        title: 'No upkeep due',
        body: 'You are caught up. Add or review tasks in Setup.',
        actionLabel: 'Open setup',
        onAction: () => setState(() => _page = 3),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        ..._section(snapshot, 'Overdue', overdue, Icons.warning_amber_rounded),
        ..._section(snapshot, 'Due today', due, Icons.today),
        ..._section(snapshot, 'Snoozed', snoozed, Icons.snooze),
      ],
    );
  }

  List<Widget> _section(
    WorkflowSnapshot snapshot,
    String title,
    List<TaskOccurrence> values,
    IconData icon,
  ) {
    if (values.isEmpty) return const <Widget>[];
    return <Widget>[
      Semantics(
        header: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title, ${values.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      ...values.map((TaskOccurrence value) => _occurrenceCard(snapshot, value)),
    ];
  }

  Widget _occurrenceList(
    WorkflowSnapshot snapshot,
    List<TaskOccurrence> values, {
    required String emptyTitle,
    required String emptyBody,
  }) {
    if (values.isEmpty) return _EmptyState(title: emptyTitle, body: emptyBody);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: values
          .map((TaskOccurrence value) => _occurrenceCard(snapshot, value))
          .toList(),
    );
  }

  Widget _occurrenceCard(WorkflowSnapshot snapshot, TaskOccurrence occurrence) {
    final TaskTemplate task = snapshot.taskFor(occurrence);
    final OccurrenceBucket bucket = classifyOccurrence(
      occurrence,
      snapshot.today,
    );
    final String status = switch (bucket) {
      OccurrenceBucket.overdue => 'Overdue',
      OccurrenceBucket.due => 'Due today',
      OccurrenceBucket.upcoming => 'Upcoming',
      OccurrenceBucket.snoozed => 'Snoozed until ${occurrence.visibleDate}',
      OccurrenceBucket.completed => 'Completed',
    };
    return Semantics(
      container: true,
      label: '${task.name}. $status. Scheduled ${occurrence.scheduledDate}.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(task.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Icon(_bucketIcon(bucket), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$status • Scheduled ${occurrence.scheduledDate}',
                    ),
                  ),
                ],
              ),
              if (occurrence.state == OccurrenceState.pending) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () => _complete(occurrence),
                      icon: const Icon(Icons.check),
                      label: Text('Complete ${task.name}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _snooze(occurrence),
                      icon: const Icon(Icons.snooze),
                      label: Text('Snooze ${task.name}'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _completedPage(WorkflowSnapshot snapshot) {
    final List<HistoryEntry> values = snapshot.history(
      HistoryFilter(
        assetId: _historyAssetId,
        roomId: _historyRoomId,
        taskText: _historyText,
        completedFrom: _historyFrom,
        completedTo: _historyTo,
        status: _historyStatus,
      ),
    );
    if (snapshot.completions.isEmpty) {
      return const _EmptyState(
        title: 'No completed work yet',
        body: 'Completed upkeep and its scheduled and actual dates will appear here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search task text',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (String value) => setState(() => _historyText = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            DropdownButton<String?>(
              value: _historyAssetId,
              hint: const Text('All assets'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(child: Text('All assets')),
                ...snapshot.assets.map(
                  (Asset value) => DropdownMenuItem<String?>(
                    value: value.id,
                    child: Text(value.name),
                  ),
                ),
              ],
              onChanged: (String? value) =>
                  setState(() => _historyAssetId = value),
            ),
            DropdownButton<String?>(
              value: _historyRoomId,
              hint: const Text('All rooms'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(child: Text('All rooms')),
                ...snapshot.rooms.map(
                  (Room value) => DropdownMenuItem<String?>(
                    value: value.id,
                    child: Text(value.name),
                  ),
                ),
              ],
              onChanged: (String? value) =>
                  setState(() => _historyRoomId = value),
            ),
            DropdownButton<HistoryStatus>(
              value: _historyStatus,
              items: const <DropdownMenuItem<HistoryStatus>>[
                DropdownMenuItem(
                  value: HistoryStatus.all,
                  child: Text('All statuses'),
                ),
                DropdownMenuItem(
                  value: HistoryStatus.completed,
                  child: Text('Completed, uncorrected'),
                ),
                DropdownMenuItem(
                  value: HistoryStatus.corrected,
                  child: Text('Corrected'),
                ),
              ],
              onChanged: (HistoryStatus? value) =>
                  setState(() => _historyStatus = value!),
            ),
            OutlinedButton.icon(
              onPressed: _editDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                _historyFrom == null && _historyTo == null
                    ? 'Completion dates'
                    : '${_historyFrom ?? 'Any'} – ${_historyTo ?? 'Any'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('${values.length} results • newest completion first'),
        if (values.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No history matches these local filters.'),
          ),
        ...values.map(_historyCard),
      ],
    );
  }

  Widget _historyCard(HistoryEntry entry) {
    final Completion completion = entry.completion;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(entry.task.name),
        subtitle: Text(
          '${entry.asset?.name ?? 'No asset'}${entry.room == null ? '' : ' • ${entry.room!.name}'}\n'
          'Completed ${completion.actualDate} • scheduled ${completion.scheduledDate}\n'
          '${completion.notes ?? 'No notes'}'
          '${completion.parts == null ? '' : '\nParts: ${completion.parts}'}'
          '${completion.cost == null ? '' : '\nCost: ${_formatMoney(completion.cost!)}'}\n'
          'Revision ${completion.revision} • ${completion.revisedAtUtc.toIso8601String()}',
        ),
        isThreeLine: true,
        onTap: () => _completionDetail(entry),
      ),
    );
  }

  Widget _setupPage(WorkflowSnapshot snapshot) {
    final HomeProfile home = snapshot.primaryHome!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (widget.workflow.reminders != null) _reminderStatusTile(),
        if (widget.workflow.reminders != null) const Divider(),
        _setupHeader('Home profile', () => _editHome(null), 'Add home'),
        ...snapshot.homes.expand(
          (HomeProfile value) => <Widget>[
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(value.name),
              subtitle: value.addressLabel == null
                  ? null
                  : Text(value.addressLabel!),
              trailing: IconButton(
                tooltip: 'Edit ${value.name}',
                onPressed: () => _editHome(value),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
            if (widget.attachments != null)
              FutureBuilder<int>(
                future: widget.attachments!.storageUsed(value.id),
                builder: (BuildContext context, AsyncSnapshot<int> total) =>
                    ListTile(
                      leading: const Icon(Icons.storage_outlined),
                      title: Text('Private attachment storage — ${value.name}'),
                      subtitle: Text(
                        total.hasData
                            ? 'Total: ${_formatBytes(total.data!)}'
                            : 'Calculating total…',
                      ),
                      trailing: TextButton(
                        onPressed: () => _cleanupAttachments(value),
                        child: Text('Clean up ${value.name}'),
                      ),
                    ),
              ),
          ],
        ),
        const Divider(),
        _setupHeader('Rooms', () => _editRoom(home, null), 'Add room'),
        if (snapshot.rooms.isEmpty) const ListTile(title: Text('No rooms yet')),
        ...snapshot.rooms.map(
          (Room value) => ListTile(
            leading: const Icon(Icons.meeting_room_outlined),
            title: Text(value.name),
            trailing: IconButton(
              tooltip: 'Edit ${value.name}',
              onPressed: () => _editRoom(home, value),
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
        ),
        const Divider(),
        _setupHeader(
          'Assets',
          () => _editAsset(home, snapshot, null),
          'Add asset',
        ),
        if (snapshot.assets.isEmpty)
          const ListTile(title: Text('No assets yet')),
        ...snapshot.assets.map(
          (Asset value) => ListTile(
            leading: const Icon(Icons.handyman_outlined),
            title: Text(value.name),
            subtitle: const Text('Open chronological asset history'),
            onTap: () => _assetDetail(snapshot, value),
            trailing: IconButton(
              tooltip: 'Edit ${value.name}',
              onPressed: () => _editAsset(home, snapshot, value),
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
        ),
        const Divider(),
        _setupHeader(
          'Upkeep tasks',
          () => _editTask(home, snapshot, null),
          'Add task',
        ),
        if (snapshot.tasks.isEmpty) const ListTile(title: Text('No tasks yet')),
        ...snapshot.tasks.map(
          (TaskTemplate value) => ListTile(
            leading: const Icon(Icons.task_alt_outlined),
            title: Text(value.name),
            subtitle: Text(
              'Starts ${value.startDate} • ${_recurrenceLabel(value.recurrence)}'
              '${value.paused ? ' • Paused' : ''}'
              '${value.reminder == null ? ' • Reminder off' : ' • Reminder ${_twoDigits(value.reminder!.hour)}:${_twoDigits(value.reminder!.minute)} ${value.reminder!.timeZoneId}'}',
            ),
            trailing: Wrap(
              children: <Widget>[
                IconButton(
                  tooltip: 'Edit ${value.name}',
                  onPressed: () => _editTask(home, snapshot, value),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete ${value.name}',
                  onPressed: () => _deleteTask(value),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dataPage(WorkflowSnapshot snapshot) {
    final bool available =
        widget.portability != null && widget.dataTransfer != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Privacy & data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upkeep Log stores its database and attachments only in app-private storage. It has no account, analytics, ads, or network sync.',
        ),
        if (widget.portability != null)
          FutureBuilder<LocalStorageSummary>(
            future: _storageSummary,
            builder: (context, storage) {
              if (storage.hasError) {
                return const ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Local storage usage unavailable'),
                );
              }
              if (!storage.hasData) {
                return const ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Calculating local storage usage…'),
                );
              }
              final LocalStorageSummary value = storage.data!;
              final Map<String, String> names = <String, String>{
                for (final home in snapshot.homes) home.id: home.name,
              };
              final String homes = value.attachmentBytesByHome.entries
                  .map(
                    (entry) =>
                        '${names[entry.key] ?? entry.key}: ${_formatBytes(entry.value)}',
                  )
                  .join(' • ');
              return Semantics(
                label:
                    'Local storage ${_formatBytes(value.totalBytes)}, database ${_formatBytes(value.databaseBytes)}, attachments ${_formatBytes(value.attachmentBytes)}',
                child: ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: Text(
                    'Local storage: ${_formatBytes(value.totalBytes)}',
                  ),
                  subtitle: Text(
                    'Database: ${_formatBytes(value.databaseBytes)} • Attachments: ${_formatBytes(value.attachmentBytes)}${homes.isEmpty ? '' : '\n$homes'}',
                  ),
                ),
              );
            },
          ),
        const ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: Text('Notifications'),
          subtitle: Text(
            'Requested only when you explicitly enable a reminder. Manage status in Setup.',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.camera_alt_outlined),
          title: Text('Camera and photos'),
          subtitle: Text(
            'Access begins only when you choose Attach. Document selection needs no broad storage permission.',
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.table_view_outlined),
          title: const Text('Export CSV history'),
          subtitle: const Text(
            'UTF-8 CSV with stable IDs, date-only fields, costs, and correction revisions.',
          ),
          enabled: available,
          onTap: available ? () => _exportCsv() : null,
        ),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Export full backup'),
          subtitle: const Text(
            'ZIP with versioned JSON and checksum-verified attachments.',
          ),
          enabled: available,
          onTap: available ? _exportBackup : null,
        ),
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: const Text('Restore backup'),
          subtitle: const Text(
            'Creates and verifies a local recovery copy, offers it through the share sheet, validates the selected backup in staging, then replaces local data atomically.',
          ),
          enabled: available,
          onTap: available ? _restoreBackup : null,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Exports can contain private addresses, serial numbers in names or notes, costs, notes, and photos. Review them before sharing.',
          ),
        ),
        const Divider(),
        Semantics(
          header: true,
          child: Text(
            'Selected history exports',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...snapshot.homes.map(
          (home) => ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text('Export ${home.name} history'),
            subtitle: const Text('CSV limited to this home.'),
            enabled: available,
            onTap: available ? () => _exportCsv(homeId: home.id) : null,
          ),
        ),
        ...snapshot.assets.map(
          (asset) => ListTile(
            leading: const Icon(Icons.handyman_outlined),
            title: Text('Export ${asset.name} history'),
            subtitle: const Text('CSV limited to this asset.'),
            enabled: available,
            onTap: available ? () => _exportCsv(assetId: asset.id) : null,
          ),
        ),
        const Divider(),
        ...snapshot.homes.map(
          (home) => ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text('Delete ${home.name} data'),
            subtitle: const Text(
              'Permanently removes this home, all history, and private attachments.',
            ),
            enabled: available,
            onTap: available ? () => _deleteHomeData(home) : null,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever),
          title: const Text('Full reset'),
          subtitle: const Text(
            'Permanently removes every home, history record, and attachment.',
          ),
          textColor: Theme.of(context).colorScheme.error,
          iconColor: Theme.of(context).colorScheme.error,
          enabled: available,
          onTap: available ? _resetAllData : null,
        ),
      ],
    );
  }

  Future<void> _exportCsv({String? homeId, String? assetId}) async {
    try {
      final bytes = await widget.portability!.exportCsv(
        homeId: homeId,
        assetId: assetId,
      );
      final result = await widget.dataTransfer!.exportFile(
        suggestedName: 'upkeep-history.csv',
        mediaType: 'text/csv',
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.status == TransferStatus.cancelled
                ? 'CSV export cancelled.'
                : 'CSV prepared for export.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('CSV export failed: $error')));
      }
    }
  }

  Future<void> _exportBackup() async {
    if (!await _confirm(
      'Export private backup?',
      'The ZIP can contain addresses, costs, notes, serials, and photos. Store and share it carefully.',
      'Export backup',
    )) {
      return;
    }
    try {
      final bytes = await widget.portability!.createBackup();
      final result = await widget.dataTransfer!.exportFile(
        suggestedName: 'upkeep-log-backup.zip',
        mediaType: 'application/zip',
        bytes: bytes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.status == TransferStatus.cancelled
                  ? 'Backup export cancelled.'
                  : 'Backup prepared for export.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Backup failed: $error')));
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (!await _confirm(
      'Restore and replace local data?',
      'A verified local pre-restore recovery copy will be prepared and offered through the share sheet first. Android cannot confirm that another app retained the offered file, so save it explicitly if you want a copy outside Upkeep Log. The selected backup must pass all schema, reference, path, size, and checksum checks.',
      'Continue',
    )) {
      return;
    }
    try {
      final before = await widget.portability!.createBackup();
      final backup = await widget.dataTransfer!.exportFile(
        suggestedName: 'upkeep-pre-restore-backup.zip',
        mediaType: 'application/zip',
        bytes: before,
      );
      if (backup.status == TransferStatus.cancelled || backup.path == null) {
        return;
      }
      final selected = await widget.dataTransfer!.importBackup();
      if (selected.status == TransferStatus.cancelled ||
          selected.path == null) {
        return;
      }
      final report = await widget.portability!.restorePaths(
        selected.path!,
        preRestoreBackupPath: backup.path!,
      );
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored ${report.homeCount} homes and ${report.attachmentCount} attachments. ${report.conflictCount} existing home IDs were replaced.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Restore failed: $error')));
      }
    }
  }

  Future<void> _deleteHomeData(HomeProfile home) async {
    if (!await _confirm(
      'Permanently delete ${home.name}?',
      'This removes its tasks, completed history, and private attachments. Export a backup first if needed.',
      'Delete home data',
    )) {
      return;
    }
    try {
      await widget.portability!.deleteHomeData(home.id);
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
      }
    }
  }

  Future<void> _resetAllData() async {
    if (!await _confirm(
      'Permanently reset Upkeep Log?',
      'Every home, task, completion revision, and attachment on this device will be removed. Export a backup first if needed.',
      'Reset all data',
    )) {
      return;
    }
    try {
      await widget.portability!.resetAllData();
      setState(() => _page = 0);
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Reset failed: $error')));
      }
    }
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Widget _reminderStatusTile() {
    final ReminderStatus? status = widget.workflow.reminderStatus;
    return ListTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: const Text('Local reminders'),
      subtitle: Text(
        status?.message ?? 'Checking notification availability. Due lists remain the source of truth.',
      ),
      trailing: status?.permission == ReminderPermission.denied
          ? TextButton(
              onPressed: () => widget.workflow.openReminderSettings(),
              child: const Text('Open notification settings'),
            )
          : null,
    );
  }

  Widget _setupHeader(String title, VoidCallback action, String actionLabel) =>
      Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          TextButton.icon(
            onPressed: action,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      );

  Future<void> _editHome(HomeProfile? existing) async {
    final _NameAddressResult? result = await showDialog<_NameAddressResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _NameAddressDialog(
        title: existing == null ? 'Create home profile' : 'Edit home profile',
        initialName: existing?.name ?? '',
        initialAddress: existing?.addressLabel ?? '',
      ),
    );
    if (result == null) return;
    await _run(
      () => widget.workflow.saveHome(
        HomeProfile(
          id: existing?.id ?? _id('home'),
          name: result.name,
          addressLabel: _emptyToNull(result.address),
        ),
      ),
    );
  }

  Future<void> _editRoom(HomeProfile home, Room? existing) async {
    final String? name = await _nameDialog(
      title: existing == null ? 'Add room' : 'Edit room',
      initial: existing?.name ?? '',
    );
    if (name == null) return;
    await _run(
      () => widget.workflow.saveRoom(
        Room(id: existing?.id ?? _id('room'), homeId: home.id, name: name),
      ),
    );
  }

  Future<void> _editAsset(
    HomeProfile home,
    WorkflowSnapshot snapshot,
    Asset? existing,
  ) async {
    final _AssetResult? result = await showDialog<_AssetResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          _AssetDialog(rooms: snapshot.rooms, existing: existing),
    );
    if (result == null) return;
    await _run(
      () => widget.workflow.saveAsset(
        Asset(
          id: existing?.id ?? _id('asset'),
          homeId: home.id,
          roomId: result.roomId,
          name: result.name,
        ),
      ),
    );
  }

  Future<void> _editTask(
    HomeProfile home,
    WorkflowSnapshot snapshot,
    TaskTemplate? existing,
  ) async {
    final String reminderTimeZoneId =
        existing?.reminder?.timeZoneId ??
        await widget.workflow.reminderTimeZoneId();
    if (!mounted) return;
    final _TaskResult? result = await showDialog<_TaskResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _TaskDialog(
        today: snapshot.today,
        timeZoneId: reminderTimeZoneId,
        rooms: snapshot.rooms,
        assets: snapshot.assets,
        existing: existing,
      ),
    );
    if (result == null) return;
    final TaskTemplate task = TaskTemplate(
      id: existing?.id ?? _id('task'),
      homeId: home.id,
      roomId: result.roomId,
      assetId: result.assetId,
      name: result.name,
      startDate: result.startDate,
      recurrence: result.recurrence,
      reminder: result.reminder,
      paused: result.paused,
    );
    final bool explicitlyEnabledReminder =
        result.reminder != null && existing?.reminder == null;
    await _run(
      () => existing == null
          ? widget.workflow.createTask(
              task,
              requestReminderPermission: explicitlyEnabledReminder,
            )
          : widget.workflow.updateTask(
              task,
              requestReminderPermission: explicitlyEnabledReminder,
            ),
    );
  }

  Future<void> _complete(TaskOccurrence occurrence) async {
    final _CompletionResult? result = await showDialog<_CompletionResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          _CompletionDialog(today: _snapshot!.today),
    );
    if (result == null) return;
    await _run(
      () => widget.workflow.complete(
        occurrence: occurrence,
        actualDate: result.actualDate,
        notes: result.notes,
        parts: result.parts,
        cost: result.cost,
      ),
    );
  }

  Future<void> _snooze(TaskOccurrence occurrence) async {
    final String? text = await _nameDialog(
      title: 'Snooze upkeep',
      label: 'Show again on (YYYY-MM-DD)',
      initial: occurrence.visibleDate.addDays(1).toIso8601String(),
      validator: _dateValidator,
    );
    if (text == null || !mounted) return;
    final Object token = Object();
    _pendingSnooze = token;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: const Text('Snooze scheduled. Undo before it is saved.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (_pendingSnooze == token) _pendingSnooze = null;
          },
        ),
      ),
    );
    await Future<void>.delayed(const Duration(seconds: 4));
    if (_pendingSnooze != token || !mounted) return;
    _pendingSnooze = null;
    await _run(() => widget.workflow.snooze(occurrence, LocalDate.parse(text)));
  }

  Future<void> _deleteTask(TaskTemplate task) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete upkeep task?'),
        content: Text(
          'Delete ${task.name} and its occurrence history? This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete task'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => widget.workflow.deleteTask(task.id));
    }
  }

  Future<void> _editDateRange() async {
    final String? from = await _nameDialog(
      title: 'Completion date range',
      label: 'From (YYYY-MM-DD, optional)',
      initial: _historyFrom?.toString() ?? '',
      validator: _optionalDateValidator,
    );
    if (from == null || !mounted) return;
    final String? to = await _nameDialog(
      title: 'Completion date range',
      label: 'To (YYYY-MM-DD, optional)',
      initial: _historyTo?.toString() ?? '',
      validator: _optionalDateValidator,
    );
    if (to == null || !mounted) return;
    setState(() {
      _historyFrom = from.trim().isEmpty ? null : LocalDate.parse(from);
      _historyTo = to.trim().isEmpty ? null : LocalDate.parse(to);
    });
  }

  Future<void> _assetDetail(WorkflowSnapshot snapshot, Asset asset) async {
    final List<HistoryEntry> entries = snapshot.history(
      HistoryFilter(assetId: asset.id),
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: Text(asset.name)),
          body: entries.isEmpty
              ? const _EmptyState(
                  title: 'No asset history',
                  body: 'Completed work linked to this asset will appear here.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Text(
                      'Chronological timeline',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ...entries.map(_historyCard),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _completionDetail(HistoryEntry entry) async {
    final List<Completion> revisions = await widget.workflow
        .completionRevisions(entry.completion.id);
    final List<AttachmentMetadata> metadata = await widget.workflow.repository
        .attachmentsForCompletion(entry.completion.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(entry.task.name),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Scheduled ${entry.completion.scheduledDate}'),
                const SizedBox(height: 12),
                Text(
                  'Revision history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...revisions.reversed.map((Completion value) {
                  final Completion? previous = value.revision <= 1
                      ? null
                      : revisions[value.revision - 2];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Revision ${value.revision}${value == revisions.last ? ' • current' : ' • previous'}',
                    ),
                    subtitle: Text(_revisionValues(value, previous)),
                  );
                }),
                Text(
                  'Private attachments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (metadata.isEmpty) const Text('No attachments'),
                ...metadata.map(
                  (AttachmentMetadata value) =>
                      _attachmentTile(value, dialogContext),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          if (widget.attachments != null)
            PopupMenuButton<AttachmentSource>(
              tooltip: 'Attach a private file',
              onSelected: (AttachmentSource source) {
                Navigator.pop(dialogContext);
                unawaited(_attach(entry, source));
              },
              itemBuilder: (_) => const <PopupMenuEntry<AttachmentSource>>[
                PopupMenuItem(
                  value: AttachmentSource.camera,
                  child: Text('Take photo'),
                ),
                PopupMenuItem(
                  value: AttachmentSource.photoLibrary,
                  child: Text('Choose photo'),
                ),
                PopupMenuItem(
                  value: AttachmentSource.document,
                  child: Text('Choose document'),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[Icon(Icons.attach_file), Text('Attach')],
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _correctCompletion(entry.completion);
            },
            child: const Text('Correct completion'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _attachmentTile(AttachmentMetadata value, BuildContext dialogContext) {
    if (widget.attachments == null) {
      return ListTile(title: Text(value.caption ?? value.mediaType));
    }
    return FutureBuilder<AttachmentInspection>(
      future: widget.attachments!.inspect(value),
      builder: (BuildContext context, AsyncSnapshot<AttachmentInspection> state) {
        final AttachmentInspection? inspection = state.data;
        final String health = inspection == null
            ? 'Checking…'
            : inspection.health.name;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            inspection?.health == AttachmentHealth.available
                ? Icons.attachment
                : Icons.warning_amber,
          ),
          title: Text(value.caption ?? value.mediaType),
          subtitle: Text(
            '$health${inspection == null ? '' : ' • ${_formatBytes(inspection.bytes)}'}',
          ),
          trailing: IconButton(
            tooltip:
                'Remove attachment metadata and its unreferenced private file',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final bool confirmed =
                  await showDialog<bool>(
                    context: dialogContext,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Remove attachment?'),
                      content: const Text(
                        'This removes the attachment from this completion and '
                        'deletes its private copy when nothing else references it.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Remove attachment'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!confirmed || !dialogContext.mounted) return;
              Object? removalError;
              var metadataRemoved = false;
              try {
                await widget.attachments!.removeMetadata(value);
                metadataRemoved = true;
              } catch (error) {
                removalError = error;
                try {
                  metadataRemoved =
                      !(await widget.workflow.repository.attachments()).any(
                        (AttachmentMetadata item) => item.id == value.id,
                      );
                } catch (_) {
                  // The removal error is the useful failure to report. A
                  // failed status check only means the outcome is uncertain.
                }
              }
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              await _reload();
              if (!mounted) return;
              final String message;
              if (removalError == null) {
                message =
                    'Attachment removed from history and private storage.';
              } else if (metadataRemoved) {
                message =
                    'Attachment removed from history, but its private file could not be fully cleaned up: $removalError';
              } else {
                message =
                    'Could not remove the attachment. It may still appear in history: $removalError';
              }
              ScaffoldMessenger.of(this.context)
                  .showSnackBar(SnackBar(content: Text(message)));
            },
          ),
        );
      },
    );
  }

  Future<void> _attach(HistoryEntry entry, AttachmentSource source) async {
    final String? caption = await _nameDialog(
      title: 'Attach privately',
      label: 'Caption (optional)',
      initial: '',
      validator: (_) => null,
    );
    if (caption == null || !mounted) return;
    AttachmentMetadata? attached;
    await _run(() async {
      attached = await widget.attachments!.attach(
        homeId: entry.home.id,
        completionId: entry.completion.id,
        source: source,
        caption: caption,
      );
    });
    if (mounted && attached == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No attachment was added. The selection was cancelled or access was denied.',
          ),
        ),
      );
    }
  }

  Future<void> _correctCompletion(Completion current) async {
    final _CompletionResult? result = await showDialog<_CompletionResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _CompletionDialog(
        today: current.actualDate,
        initial: current,
        title: 'Correct completion',
        submitLabel: 'Append correction',
      ),
    );
    if (result == null) return;
    await _run(
      () => widget.workflow.reviseCompletion(
        current: current,
        actualDate: result.actualDate,
        notes: result.notes,
        parts: result.parts,
        cost: result.cost,
      ),
    );
  }

  Future<void> _cleanupAttachments(HomeProfile home) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Clean up attachments for ${home.name}?'),
            content: Text(
              'Only unreferenced files for ${home.name} will be removed. '
              'Files linked to maintenance history will be kept.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clean up files'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    try {
      final int removed = await widget.attachments!.cleanup(home.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cleanup removed ${_formatBytes(removed)} of unreferenced files. Referenced files were kept.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not finish attachment cleanup for ${home.name}. Some unreferenced files may remain: $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<String?> _nameDialog({
    required String title,
    required String initial,
    String label = 'Name',
    String? Function(String?)? validator,
  }) => showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => _SingleFieldDialog(
      title: title,
      label: label,
      initial: initial,
      validator: validator,
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text(
            'Could not load local upkeep',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.task_alt, size: 48),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
          if (onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class _SingleFieldDialog extends StatefulWidget {
  const _SingleFieldDialog({
    required this.title,
    required this.label,
    required this.initial,
    this.validator,
  });
  final String title;
  final String label;
  final String initial;
  final String? Function(String?)? validator;

  @override
  State<_SingleFieldDialog> createState() => _SingleFieldDialogState();
}

class _SingleFieldDialogState extends State<_SingleFieldDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        validator: widget.validator ?? _requiredValidator,
        onFieldSubmitted: (_) => _save(),
      ),
    ),
    actions: <Widget>[
      TextButton(onPressed: _cancel, child: const Text('Cancel')),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );

  void _save() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  Future<void> _cancel() async {
    if (_controller.text == widget.initial || await _confirmDiscard(context)) {
      if (mounted) Navigator.pop(context);
    }
  }
}

class _NameAddressResult {
  const _NameAddressResult(this.name, this.address);
  final String name;
  final String address;
}

class _NameAddressDialog extends StatefulWidget {
  const _NameAddressDialog({
    required this.title,
    required this.initialName,
    required this.initialAddress,
  });
  final String title;
  final String initialName;
  final String initialAddress;

  @override
  State<_NameAddressDialog> createState() => _NameAddressDialogState();
}

class _NameAddressDialogState extends State<_NameAddressDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.initialAddress,
  );

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Home name'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Address label (optional)',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(onPressed: _cancel, child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              _NameAddressResult(_name.text.trim(), _address.text.trim()),
            );
          }
        },
        child: const Text('Save'),
      ),
    ],
  );

  Future<void> _cancel() async {
    final bool unchanged =
        _name.text == widget.initialName &&
        _address.text == widget.initialAddress;
    if (unchanged || await _confirmDiscard(context)) {
      if (mounted) Navigator.pop(context);
    }
  }
}

class _AssetResult {
  const _AssetResult(this.name, this.roomId);
  final String name;
  final String? roomId;
}

class _AssetDialog extends StatefulWidget {
  const _AssetDialog({required this.rooms, required this.existing});
  final List<Room> rooms;
  final Asset? existing;

  @override
  State<_AssetDialog> createState() => _AssetDialogState();
}

class _AssetDialogState extends State<_AssetDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late String? _roomId = widget.existing?.roomId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Add asset' : 'Edit asset'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Asset name'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _roomId,
              decoration: const InputDecoration(labelText: 'Room (optional)'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No room'),
                ),
                ...widget.rooms.map(
                  (Room room) => DropdownMenuItem<String?>(
                    value: room.id,
                    child: Text(room.name),
                  ),
                ),
              ],
              onChanged: (String? value) => setState(() => _roomId = value),
            ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(onPressed: _cancel, child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _AssetResult(_name.text.trim(), _roomId));
          }
        },
        child: const Text('Save'),
      ),
    ],
  );

  Future<void> _cancel() async {
    final bool unchanged =
        _name.text == (widget.existing?.name ?? '') &&
        _roomId == widget.existing?.roomId;
    if (unchanged || await _confirmDiscard(context)) {
      if (mounted) Navigator.pop(context);
    }
  }
}

enum _RecurrenceKind { oneTime, days, weeks, months, years }

class _TaskResult {
  const _TaskResult({
    required this.name,
    required this.startDate,
    required this.recurrence,
    required this.reminder,
    required this.paused,
    this.roomId,
    this.assetId,
  });
  final String name;
  final LocalDate startDate;
  final RecurrencePolicy recurrence;
  final ReminderIntent? reminder;
  final bool paused;
  final String? roomId;
  final String? assetId;
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({
    required this.today,
    required this.timeZoneId,
    required this.rooms,
    required this.assets,
    required this.existing,
  });
  final LocalDate today;
  final String timeZoneId;
  final List<Room> rooms;
  final List<Asset> assets;
  final TaskTemplate? existing;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _date = TextEditingController(
    text: (widget.existing?.startDate ?? widget.today).toIso8601String(),
  );
  late final TextEditingController _interval = TextEditingController(
    text: _existingInterval.toString(),
  );
  late final TextEditingController _reminderHour = TextEditingController(
    text: (widget.existing?.reminder?.hour ?? 9).toString(),
  );
  late final TextEditingController _reminderMinute = TextEditingController(
    text: (widget.existing?.reminder?.minute ?? 0).toString().padLeft(2, '0'),
  );
  late _RecurrenceKind _kind = _existingKind;
  late bool _actualAnchor =
      widget.existing?.recurrence.anchor ==
      RecurrenceAnchor.actualCompletionDate;
  late bool _reminderEnabled = widget.existing?.reminder != null;
  late bool _paused = widget.existing?.paused ?? false;
  late String? _roomId = widget.existing?.roomId;
  late String? _assetId = widget.existing?.assetId;

  _RecurrenceKind get _existingKind => switch (widget.existing?.recurrence) {
    FixedDayRecurrence() => _RecurrenceKind.days,
    WeeklyRecurrence() => _RecurrenceKind.weeks,
    MonthlyRecurrence() => _RecurrenceKind.months,
    YearlyRecurrence() => _RecurrenceKind.years,
    _ => _RecurrenceKind.oneTime,
  };
  int get _existingInterval => switch (widget.existing?.recurrence) {
    FixedDayRecurrence(:final days) => days,
    WeeklyRecurrence(:final intervalWeeks) => intervalWeeks,
    MonthlyRecurrence(:final intervalMonths) => intervalMonths,
    YearlyRecurrence(:final intervalYears) => intervalYears,
    _ => 1,
  };

  @override
  void dispose() {
    _name.dispose();
    _date.dispose();
    _interval.dispose();
    _reminderHour.dispose();
    _reminderMinute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.existing == null ? 'Add upkeep task' : 'Edit upkeep task',
    ),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Task name'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _date,
                decoration: const InputDecoration(
                  labelText: 'First due date (YYYY-MM-DD)',
                ),
                validator: _dateValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_RecurrenceKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Repeats'),
                items: _RecurrenceKind.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(switch (value) {
                          _RecurrenceKind.oneTime => 'One time',
                          _RecurrenceKind.days => 'Every number of days',
                          _RecurrenceKind.weeks => 'Every number of weeks',
                          _RecurrenceKind.months => 'Every number of months',
                          _RecurrenceKind.years => 'Every number of years',
                        }),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _kind = value!;
                  if (_kind == _RecurrenceKind.oneTime) _actualAnchor = false;
                }),
              ),
              if (_kind != _RecurrenceKind.oneTime) ...<Widget>[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _interval,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeat interval',
                  ),
                  validator: (String? value) =>
                      int.tryParse(value ?? '') == null || int.parse(value!) < 1
                      ? 'Enter a positive whole number'
                      : null,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _actualAnchor,
                  onChanged: (bool? value) =>
                      setState(() => _actualAnchor = value ?? false),
                  title: const Text(
                    'Schedule next date from actual completion',
                  ),
                  subtitle: const Text(
                    'Otherwise the original calendar schedule is preserved.',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _paused,
                onChanged: (bool value) => setState(() => _paused = value),
                title: const Text('Pause this task'),
                subtitle: const Text(
                  'Paused tasks stay in your log but do not schedule reminders.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _reminderEnabled,
                onChanged: (bool value) =>
                    setState(() => _reminderEnabled = value),
                title: const Text('Enable a local reminder'),
                subtitle: const Text(
                  'A convenience aid only; delivery may be delayed or suppressed by the operating system.',
                ),
              ),
              if (_reminderEnabled) ...<Widget>[
                const Text(
                  'Notification permission is requested only after you save this enabled reminder. Due lists keep working if access is denied.',
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _reminderHour,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Reminder hour (0–23)',
                        ),
                        validator: (String? value) =>
                            _integerRangeValidator(value, 0, 23),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _reminderMinute,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minute (0–59)',
                        ),
                        validator: (String? value) =>
                            _integerRangeValidator(value, 0, 59),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Saved time zone: ${widget.timeZoneId}'),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _roomId,
                decoration: const InputDecoration(labelText: 'Room (optional)'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem(value: null, child: Text('No room')),
                  ...widget.rooms.map(
                    (Room room) => DropdownMenuItem(
                      value: room.id,
                      child: Text(room.name),
                    ),
                  ),
                ],
                onChanged: (String? value) => setState(() => _roomId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _assetId,
                decoration: const InputDecoration(
                  labelText: 'Asset (optional)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem(value: null, child: Text('No asset')),
                  ...widget.assets.map(
                    (Asset asset) => DropdownMenuItem(
                      value: asset.id,
                      child: Text(asset.name),
                    ),
                  ),
                ],
                onChanged: (String? value) => setState(() => _assetId = value),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(onPressed: _cancel, child: const Text('Cancel')),
      FilledButton(onPressed: _save, child: const Text('Save task')),
    ],
  );

  void _save() {
    if (!_form.currentState!.validate()) return;
    final int interval = int.parse(_interval.text);
    final RecurrenceAnchor anchor = _actualAnchor
        ? RecurrenceAnchor.actualCompletionDate
        : RecurrenceAnchor.scheduledDate;
    final RecurrencePolicy recurrence = switch (_kind) {
      _RecurrenceKind.oneTime => const OneTimeRecurrence(),
      _RecurrenceKind.days => FixedDayRecurrence(interval, anchor: anchor),
      _RecurrenceKind.weeks => WeeklyRecurrence(
        intervalWeeks: interval,
        anchor: anchor,
      ),
      _RecurrenceKind.months => MonthlyRecurrence(
        intervalMonths: interval,
        anchor: anchor,
      ),
      _RecurrenceKind.years => YearlyRecurrence(
        intervalYears: interval,
        anchor: anchor,
      ),
    };
    Navigator.pop(
      context,
      _TaskResult(
        name: _name.text.trim(),
        startDate: LocalDate.parse(_date.text),
        recurrence: recurrence,
        reminder: _reminderEnabled
            ? ReminderIntent(
                hour: int.parse(_reminderHour.text),
                minute: int.parse(_reminderMinute.text),
                timeZoneId: widget.timeZoneId,
              )
            : null,
        paused: _paused,
        roomId: _roomId,
        assetId: _assetId,
      ),
    );
  }

  Future<void> _cancel() async {
    final TaskTemplate? existing = widget.existing;
    final bool unchanged =
        _name.text == (existing?.name ?? '') &&
        _date.text == (existing?.startDate ?? widget.today).toIso8601String() &&
        _interval.text == _existingInterval.toString() &&
        _kind == _existingKind &&
        _actualAnchor ==
            (existing?.recurrence.anchor ==
                RecurrenceAnchor.actualCompletionDate) &&
        _reminderEnabled == (existing?.reminder != null) &&
        _reminderHour.text == (existing?.reminder?.hour ?? 9).toString() &&
        _reminderMinute.text ==
            (existing?.reminder?.minute ?? 0).toString().padLeft(2, '0') &&
        _paused == (existing?.paused ?? false) &&
        _roomId == existing?.roomId &&
        _assetId == existing?.assetId;
    if (unchanged || await _confirmDiscard(context)) {
      if (mounted) Navigator.pop(context);
    }
  }
}

class _CompletionResult {
  const _CompletionResult({
    required this.actualDate,
    required this.notes,
    required this.parts,
    required this.cost,
  });
  final LocalDate actualDate;
  final String notes;
  final String parts;
  final Money? cost;
}

class _CompletionDialog extends StatefulWidget {
  const _CompletionDialog({
    required this.today,
    this.initial,
    this.title = 'Complete upkeep',
    this.submitLabel = 'Record completion',
  });
  final LocalDate today;
  final Completion? initial;
  final String title;
  final String submitLabel;

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _date = TextEditingController(
    text: (widget.initial?.actualDate ?? widget.today).toIso8601String(),
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.initial?.notes ?? '',
  );
  late final TextEditingController _parts = TextEditingController(
    text: widget.initial?.parts ?? '',
  );
  late final TextEditingController _cost = TextEditingController(
    text: widget.initial?.cost == null
        ? ''
        : _moneyInput(widget.initial!.cost!),
  );
  late final TextEditingController _currency = TextEditingController(
    text: widget.initial?.cost?.currency ?? 'USD',
  );

  @override
  void dispose() {
    _date.dispose();
    _notes.dispose();
    _parts.dispose();
    _cost.dispose();
    _currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _date,
                decoration: const InputDecoration(
                  labelText: 'Actual completion date (YYYY-MM-DD)',
                ),
                validator: _dateValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _parts,
                decoration: const InputDecoration(
                  labelText: 'Parts used (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cost,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cost (optional)',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return RegExp(r'^\d+(\.\d{1,2})?$')
                                .hasMatch(value.trim())
                            ? null
                            : 'Use 0.00 format';
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _currency,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      validator: (String? value) =>
                          RegExp(r'^[A-Z]{3}$')
                              .hasMatch(value?.trim().toUpperCase() ?? '')
                          ? null
                          : 'Use 3 letters',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(onPressed: _cancel, child: const Text('Cancel')),
      FilledButton(onPressed: _save, child: Text(widget.submitLabel)),
    ],
  );

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      _CompletionResult(
        actualDate: LocalDate.parse(_date.text),
        notes: _notes.text,
        parts: _parts.text,
        cost: _cost.text.trim().isEmpty
            ? null
            : Money(
                minorUnits: _minorUnits(_cost.text.trim()),
                currency: _currency.text.trim().toUpperCase(),
              ),
      ),
    );
  }

  Future<void> _cancel() async {
    final bool unchanged =
        _date.text == widget.today.toIso8601String() &&
        _notes.text.isEmpty &&
        _parts.text.isEmpty &&
        _cost.text.isEmpty &&
        _currency.text == 'USD';
    if (unchanged || await _confirmDiscard(context)) {
      if (mounted) Navigator.pop(context);
    }
  }
}

Future<bool> _confirmDiscard(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('Your changes in this form have not been saved.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard changes'),
          ),
        ],
      ),
    ) ??
    false;

String? _requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

String? _dateValidator(String? value) {
  try {
    LocalDate.parse(value?.trim() ?? '');
    return null;
  } on FormatException {
    return 'Enter a valid date as YYYY-MM-DD';
  }
}

String? _integerRangeValidator(String? value, int minimum, int maximum) {
  final int? parsed = int.tryParse(value?.trim() ?? '');
  return parsed == null || parsed < minimum || parsed > maximum
      ? 'Enter $minimum–$maximum'
      : null;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String? _optionalDateValidator(String? value) =>
    value == null || value.trim().isEmpty ? null : _dateValidator(value);

String? _emptyToNull(String value) =>
    value.trim().isEmpty ? null : value.trim();

int _minorUnits(String value) {
  final List<String> pieces = value.split('.');
  return int.parse(pieces.first) * 100 +
      (pieces.length == 1 ? 0 : int.parse(pieces.last.padRight(2, '0')));
}

String _formatMoney(Money value) {
  final int absolute = value.minorUnits.abs();
  final String amount =
      '${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
  return '${value.currency} ${value.minorUnits < 0 ? '-' : ''}$amount';
}

String _moneyInput(Money value) {
  final int absolute = value.minorUnits.abs();
  return '${value.minorUnits < 0 ? '-' : ''}${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
}

String _revisionValues(Completion value, Completion? previous) {
  String shown(String label, Object? current, Object? old) => previous == null
      ? '$label: ${current ?? 'None'}'
      : '$label: ${current ?? 'None'} (previously ${old ?? 'None'})';
  return <String>[
    shown('Actual', value.actualDate, previous?.actualDate),
    shown('Notes', value.notes, previous?.notes),
    shown('Parts', value.parts, previous?.parts),
    shown(
      'Cost',
      value.cost == null ? null : _formatMoney(value.cost!),
      previous?.cost == null ? null : _formatMoney(previous!.cost!),
    ),
    'Revised ${value.revisedAtUtc.toIso8601String()}',
  ].join('\n');
}

String _recurrenceLabel(RecurrencePolicy value) => switch (value) {
  OneTimeRecurrence() => 'one time',
  FixedDayRecurrence(:final days) => 'every $days day${days == 1 ? '' : 's'}',
  WeeklyRecurrence(:final intervalWeeks) =>
    'every $intervalWeeks week${intervalWeeks == 1 ? '' : 's'}',
  MonthlyRecurrence(:final intervalMonths) =>
    'every $intervalMonths month${intervalMonths == 1 ? '' : 's'}',
  YearlyRecurrence(:final intervalYears) =>
    'every $intervalYears year${intervalYears == 1 ? '' : 's'}',
};

IconData _bucketIcon(OccurrenceBucket value) => switch (value) {
  OccurrenceBucket.overdue => Icons.warning_amber_rounded,
  OccurrenceBucket.due => Icons.today,
  OccurrenceBucket.upcoming => Icons.event_outlined,
  OccurrenceBucket.snoozed => Icons.snooze,
  OccurrenceBucket.completed => Icons.check_circle_outline,
};
