import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

final syncApiProvider = Provider<SyncApi>((ref) => SyncApi(ref.watch(dioProvider)));

class SyncApi {
  SyncApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchLogs({
    required String from,
    required String to,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/logs',
      queryParameters: {'from': from, 'to': to},
    );
    return res.data!
        .cast<Map<String, dynamic>>();
  }

  Future<void> batchUpsert(List<Map<String, dynamic>> items) async {
    await _dio.put<void>('/logs/batch', data: {'items': items});
  }
}
