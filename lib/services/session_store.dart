import 'dart:convert';
import 'dart:io';

import '../models/opencode_session.dart';
import 'app_logger.dart';

/// opencode 登录态持久化：数据目录下 opencode_session.json。
class SessionStore {
  SessionStore(this.directory);

  final Directory directory;

  File get _file =>
      File('${directory.path}${Platform.pathSeparator}opencode_session.json');

  Future<OpenCodeSession?> load() async {
    try {
      if (!await _file.exists()) return null;
      final raw = await _file.readAsString();
      final map = jsonDecode(raw) as Map;
      final session =
          OpenCodeSession.fromJson(Map<String, dynamic>.from(map));
      return session.isValid ? session : null;
    } catch (e) {
      AppLogger.w('load opencode session failed: $e');
      return null;
    }
  }

  Future<void> save(OpenCodeSession session) async {
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(session.toJson()),
      flush: true,
    );
    AppLogger.i(
      'opencode session saved: ws=${session.workspaceId} '
      'cookie=${session.cookie.length}ch',
    );
  }

  Future<void> clear() async {
    try {
      if (await _file.exists()) await _file.delete();
      AppLogger.i('opencode session cleared');
    } catch (e) {
      AppLogger.w('clear opencode session failed: $e');
    }
  }
}
