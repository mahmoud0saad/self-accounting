import '../../../core/time/day_key.dart';
import '../domain/day_completion.dart';

/// Read-side history surface. Returns one [DayCompletion] per calendar day in
/// the inclusive range `[start, end]`, with `completedPoints == 0` and
/// `fardMet == false` for days that have no `daily_logs` rows yet.
abstract class HistoryRepository {
  Future<List<DayCompletion>> readRange(DayKey start, DayKey end);

  Stream<List<DayCompletion>> watchRange(DayKey start, DayKey end);
}
