class EodSummarySettings {
  const EodSummarySettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  static const int thresholdPercent = 50;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EodSummarySettings &&
          other.enabled == enabled &&
          other.hour == hour &&
          other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);
}
