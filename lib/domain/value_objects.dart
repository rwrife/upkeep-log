/// A monetary amount stored exactly in the currency's integer minor units.
final class Money {
  factory Money({required int minorUnits, required String currency}) {
    _currency(currency);
    return Money._(minorUnits, currency);
  }
  const Money._(this.minorUnits, this.currency);

  final int minorUnits;
  final String currency;

  static String _currency(String value) {
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'currency',
        'Expected three uppercase letters',
      );
    }
    return value;
  }
}

/// A user's wall-clock reminder intent, deliberately separate from due dates.
final class ReminderIntent {
  factory ReminderIntent({
    required int hour,
    required int minute,
    required String timeZoneId,
  }) {
    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        timeZoneId.trim().isEmpty) {
      throw ArgumentError('Invalid reminder wall-clock/time-zone intent');
    }
    return ReminderIntent._(hour, minute, timeZoneId);
  }
  const ReminderIntent._(this.hour, this.minute, this.timeZoneId);
  final int hour;
  final int minute;
  final String timeZoneId;
}
