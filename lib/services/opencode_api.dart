
import 'package:http/http.dart' as http;

import '../models/opencode_data.dart';
import 'app_logger.dart';
import 'seroval.dart';

/// opencode.ai console 的 server-function RPC 客户端。
///
/// 端点：`POST https://opencode.ai/_server`，函数 ID 走 `X-Server-Id` 请求头。
/// 鉴权：登录后 WebView2 提取的 session cookie（同源请求自动携带）。
/// 请求体：seroval cross-JSON（见 [Seroval]）。
class OpenCodeApi {
  OpenCodeApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const baseUrl = 'https://opencode.ai';
  static final _serverPath = '$baseUrl/_server';

  // server function id（从 production bundle 提取，2026-08）。
  static const getCostsId =
      '15702f3a12ff8bff357f8c2aa154a17e65b746d5f6b96adc9002c86ee0c15205';
  static const getUsageInfoId =
      'bfd684bfc2e4eed05cd0b518f5e4eafd3f3376e3938abb9e536e7c03df831e5c';
  static const queryBillingInfoId =
      'c83b78a614689c38ebee981f9b39a8b377716db85c1fd7dbab604adc02d3313d';
  static const querySessionInfoId =
      '9bc4808361cdaee17059a8d3822b36ee8c9a0d93f1adc289fa1926998e3c9768';

  /// Go 套餐用量（5h/周/月限制）——`workspace/[workspaceId]/go` 页面数据源。
  static const queryLiteSubscriptionId =
      'c7389bd0e731f80f49593e5ee53835475f4e28594dd6bd83eb229bab753498cd';

  static int _instance = 0;

  /// 按月成本聚合 + 密钥列表（Cost 柱状图数据源）。
  Future<OcCostData> getCosts({
    required String cookie,
    required String workspaceId,
    required int year,
    required int month, // 0-based
    required String tzOffset, // "+08:00" 格式
  }) async {
    final result = await _rpc(
      getCostsId,
      cookie,
      [workspaceId, year, month, tzOffset],
    );
    if (result is! Map) {
      throw ApiException('getCosts 响应格式异常：$result');
    }
    return OcCostData.fromJson(Map<String, dynamic>.from(result));
  }

  /// Usage History 分页数据（每页 50 条，按时间倒序）。
  Future<List<OcUsageRecord>> getUsageInfo({
    required String cookie,
    required String workspaceId,
    required int page,
  }) async {
    final result = await _rpc(
      getUsageInfoId,
      cookie,
      [workspaceId, page],
    );
    if (result is! List) {
      throw ApiException('getUsageInfo 响应格式异常：$result');
    }
    return result
        .whereType<Map>()
        .map((e) => OcUsageRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 计费信息（余额 / 月度用量），失败时返回 null（不阻塞主流程）。
  Future<OcBilling?> getBilling({
    required String cookie,
    required String workspaceId,
  }) async {
    try {
      final result =
          await _rpc(queryBillingInfoId, cookie, [workspaceId]);
      if (result is! Map) return null;
      return OcBilling.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      AppLogger.w('getBilling failed: $e');
      return null;
    }
  }

  /// 会话有效性验证：返回 isAdmin / isBeta。
  Future<Map<String, dynamic>?> checkSession({
    required String cookie,
    required String workspaceId,
  }) async {
    try {
      final result =
          await _rpc(querySessionInfoId, cookie, [workspaceId]);
      if (result is! Map) return null;
      return Map<String, dynamic>.from(result);
    } catch (e) {
      AppLogger.w('checkSession failed: $e');
      return null;
    }
  }

  /// Go 套餐用量限制（5h/周/月），失败返回 null（不阻塞主流程）。
  Future<OcLiteSubscription?> getLiteSubscription({
    required String cookie,
    required String workspaceId,
  }) async {
    try {
      final result = await _rpc(
        queryLiteSubscriptionId,
        cookie,
        [workspaceId],
      );
      if (result is! Map) return null;
      return OcLiteSubscription.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      AppLogger.w('getLiteSubscription failed: $e');
      return null;
    }
  }

  /// 核心 RPC：POST /_server（与浏览器完全一致）。
  ///
  /// 实测确认（2026-08-10，浏览器 Copy as cURL 逆向）：
  /// - URL 不带 ?id=（函数 ID 走 X-Server-Id 头）
  /// - body = JSON.stringify(Mo(args))（wrapped seroval），数组 node 含 l 字段
  /// - 请求头：Content-Type: application/json + X-Server-Id + X-Server-Instance
  /// - 响应：JS 模式（text/javascript，crossSerialize 表达式流）
  Future<dynamic> _rpc(String id, String cookie, List<Object?> args) async {
    final body = Seroval.encodeArgs(args);
    AppLogger.i(
      'rpc $id args=${args.map((a) => a.toString().length > 40 ? '${a.toString().substring(0, 40)}…' : a)}',
    );
    final resp = await _client.post(
      Uri.parse(_serverPath),
      headers: {
        'Content-Type': 'application/json',
        'X-Server-Id': id,
        'X-Server-Instance': 'server-fn:${_instance++}',
        'Cookie': cookie,
      },
      body: body,
    );
    final contentType = resp.headers['content-type'] ?? '';
    AppLogger.i('rpc $id -> http ${resp.statusCode} ct=$contentType');
    if (resp.statusCode != 200) {
      AppLogger.w('rpc $id http ${resp.statusCode}: ${resp.body}');
      throw ApiException('请求失败（HTTP ${resp.statusCode}）');
    }
    try {
      final result = Seroval.decodeBody(resp.bodyBytes, contentType);
      if (result is String) {
        // 服务端返回了无法解析的内容
        final snippet = result.length > 300
            ? '${result.substring(0, 300)}…'
            : result;
        throw ApiException('响应格式异常：$snippet');
      }
      return result;
    } on SerovalError catch (e) {
      AppLogger.w('rpc $id server error: ${e.message}');
      throw ApiException(e.message);
    }
  }
}

/// API 异常（友好提示）。
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 工具：把 cookie map 拼成 header 字符串。
String buildCookieHeader(Map<String, String> cookies) =>
    cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
