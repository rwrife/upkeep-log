import 'dart:async';

import 'package:flutter/material.dart';
import 'package:upkeep_log/application/upkeep_workflow.dart';
import 'package:upkeep_log/domain/domain.dart';

/// Root widget for the local-first Upkeep Log application.
class UpkeepLogApp extends StatelessWidget {
  const UpkeepLogApp({required this.workflow, super.key});

  final UpkeepWorkflow workflow;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Upkeep Log',
      theme: _theme(Brightness.light, const Color(0xFF2E6F5E)),
      darkTheme: _theme(Brightness.dark, const Color(0xFF74C7AD)),
      themeMode: ThemeMode.system,
      home: WorkflowScreen(workflow: workflow),
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
  const WorkflowScreen({required this.workflow, super.key});

  final UpkeepWorkflow workflow;

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> {
  WorkflowSnapshot? _snapshot;
  Object? _error;
  Future<void> Function()? _retryOperation;
  bool _loading = true;
  int _page = 0;
  int _idCounter = 0;
  Object? _pendingSnooze;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
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
      if (mounted) setState(() => _snapshot = value);
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
            _ => _setupPage(snapshot),
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
    final List<TaskOccurrence> values = snapshot
        .inBucket(OccurrenceBucket.completed)
        .reversed
        .toList();
    if (values.isEmpty) {
      return const _EmptyState(
        title: 'No completed work yet',
        body: 'Completed upkeep and its scheduled and actual dates will appear here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: values.map((TaskOccurrence occurrence) {
        final TaskTemplate task = snapshot.taskFor(occurrence);
        final Completion? completion = snapshot.completionFor(occurrence);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(task.name),
            subtitle: Text(
              completion == null
                  ? 'Completed • scheduled ${occurrence.scheduledDate}'
                  : 'Completed ${completion.actualDate} • scheduled ${completion.scheduledDate}'
                        '${completion.notes == null ? '' : '\n${completion.notes}'}'
                        '${completion.parts == null ? '' : '\nParts: ${completion.parts}'}'
                        '${completion.cost == null ? '' : '\nCost: ${_formatMoney(completion.cost!)}'}',
            ),
            isThreeLine: completion?.notes != null || completion?.parts != null,
          ),
        );
      }).toList(),
    );
  }

  Widget _setupPage(WorkflowSnapshot snapshot) {
    final HomeProfile home = snapshot.primaryHome!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _setupHeader('Home profile', () => _editHome(null), 'Add home'),
        ...snapshot.homes.map(
          (HomeProfile value) => ListTile(
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
              'Starts ${value.startDate} • ${_recurrenceLabel(value.recurrence)}',
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
    final _TaskResult? result = await showDialog<_TaskResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _TaskDialog(
        today: snapshot.today,
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
    );
    await _run(
      () => existing == null
          ? widget.workflow.createTask(task)
          : widget.workflow.updateTask(task),
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
    this.roomId,
    this.assetId,
  });
  final String name;
  final LocalDate startDate;
  final RecurrencePolicy recurrence;
  final String? roomId;
  final String? assetId;
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({
    required this.today,
    required this.rooms,
    required this.assets,
    required this.existing,
  });
  final LocalDate today;
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
  late _RecurrenceKind _kind = _existingKind;
  late bool _actualAnchor =
      widget.existing?.recurrence.anchor ==
      RecurrenceAnchor.actualCompletionDate;
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
  const _CompletionDialog({required this.today});
  final LocalDate today;

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _date = TextEditingController(
    text: widget.today.toIso8601String(),
  );
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _parts = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _currency = TextEditingController(text: 'USD');

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
    title: const Text('Complete upkeep'),
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
      FilledButton(onPressed: _save, child: const Text('Record completion')),
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
