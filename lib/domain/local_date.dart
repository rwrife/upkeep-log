/// An immutable Gregorian calendar date with no time or time-zone component.
final class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day) {
    final DateTime value = DateTime.utc(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      throw ArgumentError.value(toIso8601String(), 'date', 'Invalid date');
    }
  }

  factory LocalDate.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw FormatException('Expected YYYY-MM-DD', value);
    }
    try {
      return LocalDate(
        int.parse(value.substring(0, 4)),
        int.parse(value.substring(5, 7)),
        int.parse(value.substring(8, 10)),
      );
    } on ArgumentError {
      throw FormatException('Invalid calendar date', value);
    }
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);
  int get weekday => _utc.weekday;
  LocalDate addDays(int days) =>
      LocalDate.fromDateTime(_utc.add(Duration(days: days)));
  factory LocalDate.fromDateTime(DateTime value) =>
      LocalDate(value.year, value.month, value.day);

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);
  bool operator <(LocalDate other) => compareTo(other) < 0;
  bool operator <=(LocalDate other) => compareTo(other) <= 0;
  bool operator >(LocalDate other) => compareTo(other) > 0;
  bool operator >=(LocalDate other) => compareTo(other) >= 0;

  String toIso8601String() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  String toString() => toIso8601String();
  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;
  @override
  int get hashCode => Object.hash(year, month, day);
}
