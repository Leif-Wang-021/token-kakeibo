import 'dart:io';

import 'package:flutter/foundation.dart';

/// 本地日志：每次应用启动写入一个独立文件，
/// 目录结构 `logs/yyyy-MM-dd/session-yyyyMMdd-HHmmss-<毫秒>.log`，
/// 自动清理 14 天以前的会话日志。
class AppLogger {
  AppLogger._();

  static AppLogger? _instance;
  static const _keepDays = 14;

  final List<String> _buffer = [];
  File? _file;

  static AppLogger get instance =>
      _instance ??= AppLogger._().._fallback();

  static void init(Directory dataDir) {
    try {
      final logsRoot = Directory(
        '${dataDir.path}${Platform.pathSeparator}logs',
      );
      if (!logsRoot.existsSync()) logsRoot.createSync(recursive: true);
      _cleanupOldSessions(logsRoot);

      final now = DateTime.now();
      final dayDir = Directory(
        '${logsRoot.path}${Platform.pathSeparator}'
        '${_fmt(now.year)}-${_p(now.month)}-${_p(now.day)}',
      );
      if (!dayDir.existsSync()) dayDir.createSync(recursive: true);

      final stamp = '${_fmt(now.year)}${_p(now.month)}${_p(now.day)}'
          '-${_p(now.hour)}${_p(now.minute)}${_p(now.second)}'
          '-${now.millisecond.toString().padLeft(3, '0')}';
      final file = File(
        '${dayDir.path}${Platform.pathSeparator}session-$stamp.log',
      );
      _instance = AppLogger._().._attach(file);
      _instance!._writeHeader();
    } catch (e) {
      debugPrint('AppLogger init failed: $e');
      _instance = AppLogger._().._fallback();
    }
  }

  static void _cleanupOldSessions(Directory logsRoot) {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: _keepDays));
      final entries = logsRoot.listSync(followLinks: false);
      for (final entry in entries) {
        if (entry is! Directory) continue;
        final day = DateTime.tryParse(entry.path.split(Platform.pathSeparator).last);
        if (day != null && day.isBefore(cutoff)) {
          entry.deleteSync(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('AppLogger cleanup failed: $e');
    }
  }

  void _attach(File file) {
    _file = file;
  }

  void _fallback() {
    // 无法写文件时仅在控制台输出
  }

  void _writeHeader() {
    final file = _file;
    if (file == null) return;
    final now = DateTime.now();
    final lines = [
      '========== Token家计薄 会话开始 ==========',
      '时间：${_fullTimestamp(now)}',
      '系统：${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      '运行时：${Platform.version.split('\n').first}',
      '==========================================',
    ];
    try {
      file.writeAsStringSync(
        '${lines.join(Platform.lineTerminator)}${Platform.lineTerminator}',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('AppLogger header failed: $e');
    }
  }

  static void i(String message) => instance._write('INFO', message);

  static void w(String message) => instance._write('WARN', message);

  static void e(String message) => instance._write('ERROR', message);

  void _write(String level, String message) {
    final line = '[${_fullTimestamp(DateTime.now())}] $level $message';
    _buffer.add(line);
    if (_buffer.length > 200) _buffer.removeAt(0);
    debugPrint(line);

    final file = _file;
    if (file == null) return;
    try {
      file.writeAsStringSync(
        '$line${Platform.lineTerminator}',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('AppLogger write failed: $e');
    }
  }

  static String _fmt(int v) => v.toString().padLeft(4, '0');

  static String _p(int v) => v.toString().padLeft(2, '0');

  static String _fullTimestamp(DateTime now) =>
      '${now.year}-${_p(now.month)}-${_p(now.day)} '
      '${_p(now.hour)}:${_p(now.minute)}:${_p(now.second)}.'
      '${now.millisecond.toString().padLeft(3, '0')}';

  /// 最近若干条日志（供设置页展示）。
  static List<String> recentLines({int count = 20}) {
    final lines = instance._buffer;
    return lines.length <= count ? lines : lines.sublist(lines.length - count);
  }

  /// 当前会话日志文件路径（供“查看日志/打开日志目录”使用）。
  static String? get currentLogPath => instance._file?.path;
}
