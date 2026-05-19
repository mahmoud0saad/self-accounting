// Verifies api/src/challenges/seed-templates.ts matches
// app/lib/features/challenges/data/challenge_template_seed.dart.
// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  String findRepoRoot() {
    var dir = Directory.current;
    while (true) {
      if (File('${dir.path}/api/src/challenges/seed-templates.ts').existsSync()) {
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
  final tsPath = '$repo/api/src/challenges/seed-templates.ts';
  final dartPath =
      '$repo/app/lib/features/challenges/data/challenge_template_seed.dart';

  final ts = File(tsPath).readAsStringSync();
  final dart = File(dartPath).readAsStringSync();

  final tsTemplates = _extractTsTemplates(ts);
  final dartTemplates = _extractDartTemplates(dart);

  if (tsTemplates.length != dartTemplates.length) {
    print(
      'ERROR: template count mismatch (${tsTemplates.length} TS vs ${dartTemplates.length} Dart)',
    );
    exit(1);
  }

  final tsCodes = tsTemplates.map((t) => t['code']!).toList()..sort();
  final dartCodes = dartTemplates.map((t) => t['code']!).toList()..sort();
  if (tsCodes.join(',') != dartCodes.join(',')) {
    print('ERROR: template codes differ');
    print('  TS:   $tsCodes');
    print('  Dart: $dartCodes');
    exit(1);
  }

  for (final code in tsCodes) {
    final a = tsTemplates.firstWhere((t) => t['code'] == code);
    final b = dartTemplates.firstWhere((t) => t['code'] == code);
    for (final key in [
      'sourceKind',
      'sourceRef',
      'goalCount',
      'defaultSortOrder',
    ]) {
      if (a[key] != b[key]) {
        print('ERROR: $code.$key: TS=${a[key]} Dart=${b[key]}');
        exit(1);
      }
    }
  }

  print('OK: ${tsCodes.length} challenge templates in sync');
}

List<Map<String, String>> _extractTsTemplates(String content) {
  final out = <Map<String, String>>[];
  final blockRe = RegExp(
    r"\{\s*code:\s*'([^']+)'[\s\S]*?sourceKind:\s*'([^']+)'[\s\S]*?sourceRef:\s*'([^']+)'[\s\S]*?goalCount:\s*(\d+)[\s\S]*?defaultSortOrder:\s*(\d+)",
  );
  for (final m in blockRe.allMatches(content)) {
    out.add({
      'code': m.group(1)!,
      'sourceKind': m.group(2)!,
      'sourceRef': m.group(3)!,
      'goalCount': m.group(4)!,
      'defaultSortOrder': m.group(5)!,
    });
  }
  return out;
}

List<Map<String, String>> _extractDartTemplates(String content) {
  final out = <Map<String, String>>[];
  final blockRe = RegExp(
    r"code:\s*'([^']+)'[\s\S]*?sourceKind:\s*'([^']+)'[\s\S]*?sourceRef:\s*'([^']+)'[\s\S]*?goalCount:\s*(\d+)[\s\S]*?defaultSortOrder:\s*(\d+)",
  );
  for (final m in blockRe.allMatches(content)) {
    out.add({
      'code': m.group(1)!,
      'sourceKind': m.group(2)!,
      'sourceRef': m.group(3)!,
      'goalCount': m.group(4)!,
      'defaultSortOrder': m.group(5)!,
    });
  }
  return out;
}
