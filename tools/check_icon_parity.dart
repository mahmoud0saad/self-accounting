// Verifies api/src/tasks/icons.constants.ts matches app/lib/core/icons/curated_icons.dart.
// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync() &&
      File('${root.path}/app/pubspec.yaml').existsSync()) {
    // Run from repo root or app/ — find repo root.
  }

  String findRepoRoot() {
    var dir = root;
    while (true) {
      if (File('${dir.path}/api/src/tasks/icons.constants.ts').existsSync()) {
        return dir.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError('Could not find repo root');
      }
      dir = parent;
    }
  }

  final repo = findRepoRoot();
  final tsPath = '$repo/api/src/tasks/icons.constants.ts';
  final dartPath = '$repo/app/lib/core/icons/curated_icons.dart';

  final ts = File(tsPath).readAsStringSync();
  final dart = File(dartPath).readAsStringSync();

  final tsIcons = _extractFromTs(ts);
  final dartIcons = _extractFromDart(dart);

  final tsSet = tsIcons.toSet();
  final dartSet = dartIcons.toSet();

  if (tsSet.length != tsIcons.length) {
    print('ERROR: duplicate icons in TypeScript list');
    exit(1);
  }
  if (dartSet.length != dartIcons.length) {
    print('ERROR: duplicate icons in Dart list');
    exit(1);
  }

  final onlyTs = tsSet.difference(dartSet);
  final onlyDart = dartSet.difference(tsSet);

  if (onlyTs.isNotEmpty || onlyDart.isNotEmpty) {
    print('ERROR: icon lists diverged');
    if (onlyTs.isNotEmpty) {
      print('  Only in TS: ${onlyTs.join(', ')}');
    }
    if (onlyDart.isNotEmpty) {
      print('  Only in Dart: ${onlyDart.join(', ')}');
    }
    exit(1);
  }

  if (tsIcons.length != dartIcons.length) {
    print('ERROR: same set but different order/count (${tsIcons.length} vs ${dartIcons.length})');
    exit(1);
  }

  for (var i = 0; i < tsIcons.length; i++) {
    if (tsIcons[i] != dartIcons[i]) {
      print('ERROR: order mismatch at $i: ${tsIcons[i]} vs ${dartIcons[i]}');
      exit(1);
    }
  }

  print('OK: ${tsIcons.length} curated icons in sync');
}

List<String> _extractFromTs(String content) {
  final match = RegExp(r'export const CURATED_ICONS = \[([\s\S]*?)\] as const')
      .firstMatch(content);
  if (match == null) {
    throw StateError('CURATED_ICONS not found in TS');
  }
  return RegExp(r"'([^']+)'")
      .allMatches(match.group(1)!)
      .map((m) => m.group(1)!)
      .toList();
}

List<String> _extractFromDart(String content) {
  final match =
      RegExp(r'const List<String> kCuratedIcons = \[([\s\S]*?)\];').firstMatch(content);
  if (match == null) {
    throw StateError('kCuratedIcons not found in Dart');
  }
  return RegExp(r"'([^']+)'")
      .allMatches(match.group(1)!)
      .map((m) => m.group(1)!)
      .toList();
}
