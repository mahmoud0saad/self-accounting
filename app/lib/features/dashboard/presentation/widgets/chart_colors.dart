import 'package:flutter/material.dart';

/// 5-bin completion palette shared by the Phase 3 history strip and the
/// Phase 4 dashboard heatmap (D16).
///
/// Bins (per `requirements.md` §3.6 of Phase 3, lifted unchanged):
///
/// | Bin | Range            | Color                            |
/// |-----|------------------|----------------------------------|
/// | 0   | fraction == 0    | surfaceContainerHighest          |
/// | 1   | 0 < f < 0.25     | primary @ alpha 0.20             |
/// | 2   | 0.25 ≤ f < 0.50  | primary @ alpha 0.40             |
/// | 3   | 0.50 ≤ f < 0.75  | primary @ alpha 0.65             |
/// | 4   | f ≥ 0.75         | primary (full)                   |
Color completionBinColor(double fraction, ColorScheme scheme) {
  if (fraction <= 0.0) return scheme.surfaceContainerHighest;
  if (fraction < 0.25) return scheme.primary.withValues(alpha: 0.20);
  if (fraction < 0.50) return scheme.primary.withValues(alpha: 0.40);
  if (fraction < 0.75) return scheme.primary.withValues(alpha: 0.65);
  return scheme.primary;
}
