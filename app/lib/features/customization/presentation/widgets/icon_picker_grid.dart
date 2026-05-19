import 'package:flutter/material.dart';

import '../../../../core/icons/curated_icon_data.dart';
import '../../../../core/icons/curated_icons.dart';

class IconPickerGrid extends StatelessWidget {
  const IconPickerGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: kCuratedIcons.length,
      itemBuilder: (context, index) {
        final code = kCuratedIcons[index];
        final isSelected = code == selected;
        return Material(
          color: isSelected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(code),
            child: Icon(
              curatedIconData(code),
              color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}
