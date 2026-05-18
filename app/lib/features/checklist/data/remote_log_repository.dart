import 'package:dio/dio.dart';

import '../../../core/time/day_key.dart';

class RemoteLogRepository {
  RemoteLogRepository(this._dio);

  final Dio _dio;

  Future<void> upsert({
    required DayKey day,
    required String taskId,
    required bool completed,
    required DateTime updatedAt,
  }) async {
    await _dio.put<void>(
      '/logs',
      data: {
        'date': day.toIsoDate(),
        'taskId': taskId,
        'completed': completed,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<List<RemoteLogRecord>> fetchRange({
    required DayKey from,
    required DayKey to,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/logs',
      queryParameters: {'from': from.toIsoDate(), 'to': to.toIsoDate()},
    );
    final data = response.data ?? [];
    return data
        .map((e) => RemoteLogRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class RemoteLogRecord {
  RemoteLogRecord({
    required this.date,
    required this.taskId,
    required this.completed,
    required this.updatedAt,
  });

  final String date;
  final String taskId;
  final bool completed;
  final DateTime updatedAt;

  factory RemoteLogRecord.fromJson(Map<String, dynamic> json) {
    return RemoteLogRecord(
      date: json['date'].toString().substring(0, 10),
      taskId: json['taskId'] as String,
      completed: json['completed'] as bool,
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
    );
  }
}
