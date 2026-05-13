/// Selectable time-range for the Dashboard's charts (Phase 4 D2).
enum DashboardRange {
  week7(7),
  month30(30),
  days90(90);

  const DashboardRange(this.days);

  /// Number of calendar days covered by this range, inclusive of today.
  final int days;
}
