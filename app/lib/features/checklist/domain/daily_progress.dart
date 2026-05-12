import 'task.dart';

class DailyProgress {
  const DailyProgress({
    required this.completedPoints,
    required this.totalPoints,
    required this.completedTasks,
    required this.totalTasks,
    required this.fraction,
  });

  final int completedPoints;
  final int totalPoints;
  final int completedTasks;
  final int totalTasks;
  final double fraction;

  int get percentInt => (fraction * 100).round();

  factory DailyProgress.from(List<Task> tasks, Map<String, bool> state) {
    final totalPoints = tasks.fold<int>(0, (sum, t) => sum + t.points);
    var completedPoints = 0;
    var completedTasks = 0;
    for (final t in tasks) {
      if (state[t.id] == true) {
        completedPoints += t.points;
        completedTasks += 1;
      }
    }
    final fraction = totalPoints == 0 ? 0.0 : completedPoints / totalPoints;
    return DailyProgress(
      completedPoints: completedPoints,
      totalPoints: totalPoints,
      completedTasks: completedTasks,
      totalTasks: tasks.length,
      fraction: fraction,
    );
  }
}
