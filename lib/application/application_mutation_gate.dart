import 'dart:async';

/// Serializes mutations and snapshots that must observe the repository and
/// app-private attachment tree as one logical unit.
final class ApplicationMutationGate {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) async {
    final Future<void> previous = _tail;
    final Completer<void> released = Completer<void>();
    _tail = released.future;
    await previous;
    try {
      return await action();
    } finally {
      released.complete();
    }
  }
}
