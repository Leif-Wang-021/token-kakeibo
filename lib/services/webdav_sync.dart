import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/sync_config.dart';
import 'app_logger.dart';

/// WebDAV 同步客户端：把 settings.json + opencode_session.json
/// 上传/下载到用户的 WebDAV 目录，实现多端同步。
///
/// 文件路径：{url}/token_kakeibo/settings.json 与 session.json
/// （url 为 WebDAV 根目录，如 https://webdav.example.com/dav/）。
class WebDavSync {
  WebDavSync({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _basePath = 'token_kakeibo';

  String _dir(WebDavConfig cfg) {
    var url = cfg.url.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return '$url/$_basePath';
  }

  Uri _fileUri(WebDavConfig cfg, String name) =>
      Uri.parse('${_dir(cfg)}/$name');

  Map<String, String> _headers(WebDavConfig cfg, {bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${cfg.username}:${cfg.password}'))}',
      };

  /// 创建目录（WebDAV MKCOL，忽略已存在错误）。
  Future<void> _ensureDir(WebDavConfig cfg) async {
    final uri = Uri.parse('${_dir(cfg)}/');
    try {
      final req = http.Request('MKCOL', uri);
      req.headers['Authorization'] = _headers(cfg)['Authorization']!;
      final resp = await _client.send(req).then(http.Response.fromStream);
      if (resp.statusCode == 405 || resp.statusCode == 301) {
        // 已存在（或需要重定向），继续
      } else if (resp.statusCode >= 400) {
        // 部分 WebDAV 不支持 MKCOL，尝试 PUT 直接创建
      }
    } catch (e) {
      AppLogger.w('webdav mkcol failed (ignored): $e');
    }
  }

  /// 上传单个 JSON 文件（PUT）。
  Future<void> putFile(
    WebDavConfig cfg,
    String name,
    Map<String, dynamic> data,
  ) async {
    await _ensureDir(cfg);
    final resp = await _client.put(
      _fileUri(cfg, name),
      headers: _headers(cfg),
      body: const JsonEncoder.withIndent('  ').convert(data),
    );
    if (resp.statusCode >= 300) {
      throw WebDavException('上传 $name 失败（HTTP ${resp.statusCode}）');
    }
    AppLogger.i('webdav uploaded: $name');
  }

  /// 下载单个 JSON 文件（GET），不存在返回 null。
  Future<Map<String, dynamic>?> getFile(WebDavConfig cfg, String name) async {
    final resp = await _client.get(
      _fileUri(cfg, name),
      headers: _headers(cfg),
    );
    if (resp.statusCode == 404 || resp.statusCode == 405) return null;
    if (resp.statusCode >= 300) {
      throw WebDavException('下载 $name 失败（HTTP ${resp.statusCode}）');
    }
    final v = jsonDecode(utf8.decode(resp.bodyBytes));
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  /// 测试连接：GET 目录（或 PROPFIND）。
  Future<bool> testConnection(WebDavConfig cfg) async {
    try {
      final req = http.Request('PROPFIND', Uri.parse('${_dir(cfg)}/'));
      req.headers['Authorization'] = _headers(cfg)['Authorization']!;
      req.headers['Depth'] = '0';
      final resp = await _client.send(req).then(http.Response.fromStream);
      return resp.statusCode < 400 || resp.statusCode == 404;
    } catch (e) {
      AppLogger.w('webdav test failed: $e');
      return false;
    }
  }
}

class WebDavException implements Exception {
  WebDavException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 本地数据目录辅助：settings.json 与 session.json 的文件路径。
class SyncFiles {
  SyncFiles(this.directory);

  final Directory directory;

  File get settingsFile =>
      File('${directory.path}${Platform.pathSeparator}settings.json');

  File get sessionFile =>
      File('${directory.path}${Platform.pathSeparator}opencode_session.json');

  Future<Map<String, dynamic>?> readJson(File file) async {
    try {
      if (!await file.exists()) return null;
      final v = jsonDecode(await file.readAsString());
      return v is Map ? Map<String, dynamic>.from(v) : null;
    } catch (_) {
      return null;
    }
  }
}
