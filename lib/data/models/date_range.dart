/// Période de location, bornes incluses au jour près.
class DateRange {
  DateRange(DateTime start, DateTime end)
    : start = DateTime(start.year, start.month, start.day),
      end = DateTime(end.year, end.month, end.day);

  final DateTime start;
  final DateTime end;

  /// Nombre de jours facturés (minimum 1).
  int get days {
    final diff = end.difference(start).inDays;
    return diff <= 0 ? 1 : diff;
  }

  bool get isValid => !end.isBefore(start);

  bool overlaps(DateRange other) =>
      start.isBefore(other.end) && other.start.isBefore(end);

  bool contains(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  DateRange copyWith({DateTime? start, DateTime? end}) =>
      DateRange(start ?? this.start, end ?? this.end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
