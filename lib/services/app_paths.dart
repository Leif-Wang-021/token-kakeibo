import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 数据目录：统一放在系统用户数据目录（Windows: %LOCALAPPDATA%），
/// 与安装目录分离 —— 卸载 / 覆盖安装 / 换安装目录都不会丢账户与设置。
/// 首次运行会把旧位置（安装目录 appdata/ 或 %APPDATA%）的数据迁移过来。
class AppPaths {
  AppPaths._();

  static Future<Directory> dataDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Web 端暂不支持本地文件存储');
    }

    final dir = Directory(
      Platform.isWindows
          ? '${Platform.environment['LOCALAPPDATA'] ?? _exeDirectory().path}'
              '${Platform.pathSeparator}token_kakeibo'
          : '${(await getApplicationSupportDirectory()).path}'
              '${Platform.pathSeparator}token_kakeibo',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 可执行文件所在目录（安装版为安装目录，开发版为 build 输出目录）。
  static Directory _exeDirectory() =>
      File(Platform.resolvedExecutable).parent;

  /// 旧版数据目录（%APPDATA%/…/token_kakeibo），用于一次性迁移。
  static Future<Directory> legacyDataDirectory() async {
    final base = await getApplicationSupportDirectory();
    return Directory(
      '${base.path}${Platform.pathSeparator}token_kakeibo',
    );
  }

  /// 旧版 Windows 数据目录：安装目录下的 appdata/（v1.1.0 及之前）。
  /// 覆盖安装 / 卸载时可能被清掉，现已迁移到 LOCALAPPDATA。
  static Directory installDirAppData() =>
      Directory('${_exeDirectory().path}${Platform.pathSeparator}appdata');

  /// 若新目录为空而旧位置（安装目录 appdata 或 %APPDATA% legacy）有数据，
  /// 把旧数据整体迁移过去（先迁移更贴近的安装目录 appdata，再迁 legacy）。
  static Future<void> migrateLegacyDataIfNeeded(Directory target) async {
    if (Platform.isAndroid || Platform.isMacOS) return;
    final hasNewData = target
        .listSync(followLinks: false)
        .any((e) => e is File && e.path.endsWith('.json'));
    if (hasNewData) return;

    final candidates = <Directory>[];
    if (Platform.isWindows) {
      final installAppData = installDirAppData();
      if (await installAppData.exists()) candidates.add(installAppData);
    }
    final legacy = await legacyDataDirectory();
    if (await legacy.exists()) candidates.add(legacy);

    for (final src in candidates) {
      final items = src.listSync(followLinks: false);
      if (items.isEmpty) continue;
      for (final item in items) {
        final dest = File(
          '${target.path}${Platform.pathSeparator}${item.uri.pathSegments.last}',
        );
        if (item is Directory) {
          await _copyDirectory(item, Directory(dest.path));
        } else if (item is File) {
          await item.copy(dest.path);
        }
      }
      // 只迁移一次：迁移完成后给安装目录里的旧数据改名，避免下次再迁
      if (Platform.isWindows && src.path == installDirAppData().path) {
        try {
          final marker = File('${src.path}${Platform.pathSeparator}.migrated');
          await marker.writeAsString('migrated to LOCALAPPDATA at '
              '${DateTime.now().toIso8601String()}');
        } catch (_) {}
      }
    }
  }

  static Future<void> _copyDirectory(Directory src, Directory dst) async {
    if (!await dst.exists()) await dst.create(recursive: true);
    await for (final entity in src.list(followLinks: false)) {
      final destPath =
          '${dst.path}${Platform.pathSeparator}${entity.uri.pathSegments.last}';
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destPath));
      } else if (entity is File) {
        await entity.copy(destPath);
      }
    }
  }
}
