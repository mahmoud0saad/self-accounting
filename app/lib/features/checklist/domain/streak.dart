/// Streak counters computed across the available history window.
///
/// `windowDays` is the number of `DayCompletion` entries actually fed into
/// the calculator — used by the UI to decide whether to append the
/// "(last 30 days)" honesty qualifier (D5).
class Streak {
  const Streak({
    required this.current,
    required this.longest,
    required this.windowDays,
  });

  final int current;
  final int longest;
  final int windowDays;

  static const empty = Streak(current: 0, longest: 0, windowDays: 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Streak &&
          other.current == current &&
          other.longest == longest &&
          other.windowDays == windowDays;

  @override
  int get hashCode => Object.hash(current, longest, windowDays);

  @override
  String toString() =>
      'Streak(current: $current, longest: $longest, window: $windowDays)';
}
