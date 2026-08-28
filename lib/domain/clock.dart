import 'local_date.dart';

/// Injectable time source. Recurrence consumes [today], never wall-clock math.
abstract interface class Clock {
  DateTime get nowUtc;
  LocalDate get today;
  String get timeZoneId;
}

/// Production clock. Calendar dates intentionally come from the device's
/// local civil time while persisted revision instants use UTC.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime get nowUtc => DateTime.now().toUtc();

  @override
  LocalDate get today => LocalDate.fromDateTime(DateTime.now());

  @override
  String get timeZoneId => DateTime.now().timeZoneName;
}

/// Mutable deterministic clock for domain and application tests.
final class FakeClock implements Clock {
  factory FakeClock(
    DateTime now, {
    required LocalDate today,
    required String timeZoneId,
  }) => FakeClock._(now.toUtc(), today, timeZoneId);
  FakeClock._(this._nowUtc, this._today, this._timeZoneId);
  DateTime _nowUtc;
  LocalDate _today;
  String _timeZoneId;
  @override
  String get timeZoneId => _timeZoneId;
  @override
  DateTime get nowUtc => _nowUtc;
  @override
  LocalDate get today => _today;

  /// Advances the instant. Callers supply [today] when the local date changes;
  /// it is never inferred from UTC because the fake has no time-zone database.
  void advance(Duration duration, {LocalDate? today}) {
    _nowUtc = _nowUtc.add(duration);
    if (today != null) _today = today;
  }

  void set({
    required DateTime nowUtc,
    required LocalDate today,
    required String timeZoneId,
  }) {
    _nowUtc = nowUtc.toUtc();
    _today = today;
    _timeZoneId = timeZoneId;
  }
}
