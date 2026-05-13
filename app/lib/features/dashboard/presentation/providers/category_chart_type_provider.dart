import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/category_chart_type.dart';

class CategoryChartTypeNotifier extends Notifier<CategoryChartType> {
  @override
  CategoryChartType build() => CategoryChartType.horizontalBars;

  void select(CategoryChartType type) {
    if (state != type) state = type;
  }
}

final categoryChartTypeProvider =
    NotifierProvider<CategoryChartTypeNotifier, CategoryChartType>(
      CategoryChartTypeNotifier.new,
    );
