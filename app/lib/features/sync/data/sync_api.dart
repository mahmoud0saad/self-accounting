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

  Future<void> batchCustomizations(List<Map<String, dynamic>> ops) async {
    await _dio.put<void>('/customizations/batch', data: {'ops': ops});
  }

  Future<Map<String, dynamic>> fetchCatalog() async {
    final res = await _dio.get<Map<String, dynamic>>('/catalog');
    return res.data!;
  }

  Future<Map<String, dynamic>> fetchSnapshotState() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/catalog/snapshot-state');
    return res.data!;
  }

  Future<Map<String, dynamic>> createUserCategory({
    required String name,
    required String icon,
    int sortOrder = 100,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/user-categories',
      data: {'name': name, 'icon': icon, 'sortOrder': sortOrder},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> updateUserCategory(
    String id, {
    String? name,
    String? icon,
    int? sortOrder,
    bool? restore,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/user-categories/$id',
      data: {
        if (name != null) 'name': name,
        if (icon != null) 'icon': icon,
        if (sortOrder != null) 'sortOrder': sortOrder,
        if (restore == true) 'restore': true,
      },
    );
    return res.data!;
  }

  Future<void> deleteUserCategory(
    String id, {
    bool force = false,
    bool archive = false,
  }) async {
    await _dio.delete<void>(
      '/user-categories/$id',
      queryParameters: {
        if (force) 'force': 'true',
        if (archive) 'archive': 'true',
      },
    );
  }

  Future<Map<String, dynamic>> createUserTask({
    required String name,
    required String categoryRef,
    required int points,
    required String icon,
    int sortOrder = 0,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/user-tasks',
      data: {
        'name': name,
        'categoryRef': categoryRef,
        'points': points,
        'icon': icon,
        'sortOrder': sortOrder,
      },
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> updateUserTask(
    String id, {
    String? name,
    String? categoryRef,
    int? points,
    String? icon,
    int? sortOrder,
    bool? restore,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/user-tasks/$id',
      data: {
        if (name != null) 'name': name,
        if (categoryRef != null) 'categoryRef': categoryRef,
        if (points != null) 'points': points,
        if (icon != null) 'icon': icon,
        if (sortOrder != null) 'sortOrder': sortOrder,
        if (restore == true) 'restore': true,
      },
    );
    return res.data!;
  }

  Future<void> deleteUserTask(String id, {bool archive = false}) async {
    await _dio.delete<void>(
      '/user-tasks/$id',
      queryParameters: {if (archive) 'archive': 'true'},
    );
  }

  Future<void> upsertCategoryOverride(
    String categoryCode, {
    bool? hidden,
    String? customName,
    String? customIcon,
    int? sortOrder,
  }) async {
    await _dio.put<void>(
      '/user-category-overrides/$categoryCode',
      data: {
        if (hidden != null) 'hidden': hidden,
        if (customName != null) 'customName': customName,
        if (customIcon != null) 'customIcon': customIcon,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );
  }

  Future<void> upsertTaskOverride(
    String taskCode, {
    bool? hidden,
    String? customName,
    int? customPoints,
    String? customIcon,
    String? customCategoryRef,
    int? sortOrder,
  }) async {
    await _dio.put<void>(
      '/user-task-overrides/$taskCode',
      data: {
        if (hidden != null) 'hidden': hidden,
        if (customName != null) 'customName': customName,
        if (customPoints != null) 'customPoints': customPoints,
        if (customIcon != null) 'customIcon': customIcon,
        if (customCategoryRef != null) 'customCategoryRef': customCategoryRef,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );
  }
}
