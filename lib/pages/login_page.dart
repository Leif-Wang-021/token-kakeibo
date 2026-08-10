import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_win_floating/webview_win_floating.dart' as wwf;

import '../l10n/context_l10n.dart';
import '../models/opencode_session.dart';
import '../services/app_logger.dart';
import '../state/app_state.dart';

/// OpenCode 应用内登录页（Windows WebView2）。
///
/// 流程：WebView2 打开 opencode.ai → 用户 GitHub/Google 登录 →
/// 登录成功跳转到 `/workspace/[workspaceId]/...` → 自动提取 workspace ID 与
/// session cookie（含 httpOnly）→ 调 checkSession 验证 → 保存会话。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  wwf.WinWebViewController? _winController;
  String? _currentUrl;
  bool _detected = false;
  bool _busy = false;
  String _status = '';
  final _workspaceController = TextEditingController();
  Timer? _autoDetectTimer;

  static final _workspaceRe = RegExp(r'/workspace/(wrk_[A-Za-z0-9]+)');

  /// WebView2 用户数据目录：与旧登录页一致，登录态（cookie）可持久。
  static String _winWebViewDataFolder() {
    final base = Platform.environment['LOCALAPPDATA'] ??
        File(Platform.resolvedExecutable).parent.path;
    return '$base${Platform.pathSeparator}token_kakeibo'
        '${Platform.pathSeparator}webview2';
  }

  @override
  void initState() {
    super.initState();
    _status = context.l10n.loginWaiting;
    final controller = wwf.WinWebViewController(
      params: wwf.WindowsWebViewControllerCreationParams(
        userDataFolder: _winWebViewDataFolder(),
      ),
    );
    unawaited(() async {
      await controller.setJavaScriptMode(wf.JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        wwf.WinNavigationDelegate(
          onUrlChange: (change) {
            _currentUrl = change.url;
            _maybeDetectWorkspace();
          },
        ),
      );
      await controller.loadRequest(Uri.parse('https://opencode.ai/auth'));
    }());
    _winController = controller;
    _autoDetectTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _maybeDetectWorkspace(),
    );
  }

  @override
  void dispose() {
    _autoDetectTimer?.cancel();
    _workspaceController.dispose();
    super.dispose();
  }

  /// 从 URL 识别 workspace ID（登录成功后跳转）。
  void _maybeDetectWorkspace() {
    final url = _currentUrl;
    if (url == null || _detected) return;
    final m = _workspaceRe.firstMatch(url);
    if (m == null) return;
    final ws = m.group(1)!;
    AppLogger.i('opencode workspace detected: $ws url=$url');
    setState(() {
      _detected = true;
      _workspaceController.text = ws;
      _status = context.l10n.loginSuccess;
    });
    unawaited(_captureSession(ws));
  }

  /// 提取 cookie（全域）→ 验证 → 保存会话。
  ///
  /// openauth 的会话 cookie 可能落在 opencode.ai 或 auth.opencode.ai 子域，
  /// 因此提取全部 cookie（请求侧只发给 opencode.ai，多余 cookie 无害）。
  Future<void> _captureSession(String workspaceId) async {
    if (_busy) return;
    if (!mounted) return;
    final state = context.read<AppState>();
    setState(() => _busy = true);
    try {
      final cookie = await _winController?.getCookies();
      if (!mounted) return;
      AppLogger.i(
        'opencode cookie captured: ${cookie?.length ?? 0}ch '
        'head=${_cookieHead(cookie)}',
      );
      // 全量 cookie（base64），用于排查服务端拒绝原因。
      try {
        AppLogger.i(
          'opencode cookie b64: ${base64Encode(utf8.encode(cookie ?? ''))}',
        );
      } catch (_) {}
      if (cookie == null || cookie.length < 20) {
        AppLogger.w('opencode cookie empty or too short');
        setState(() {
          _busy = false;
          _status = context.l10n.loginFailed;
          _detected = false;
        });
        return;
      }
      final session = OpenCodeSession(
        cookie: cookie,
        workspaceId: workspaceId,
        savedAt: DateTime.now(),
      );
      // 验证会话有效（querySessionInfo 返回非空即有效）。
      final info = await state.api.checkSession(
        cookie: cookie,
        workspaceId: workspaceId,
      );
      if (!mounted) return;
      if (info == null) {
        AppLogger.w('opencode session invalid for $workspaceId');
        setState(() {
          _busy = false;
          _status = context.l10n.loginFailed;
          _detected = false;
        });
        return;
      }
      await state.setSession(session);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.loginSuccess)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      AppLogger.e('opencode capture session failed: $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _status = context.l10n.loginFailed;
          _detected = false;
        });
      }
    }
  }

  /// cookie 值的前 80 字符（可打印部分），用于日志排查。
  static String _cookieHead(String? cookie) {
    if (cookie == null) return '<null>';
    final s = cookie
        .split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join('; ');
    if (s.isEmpty) return '<empty>';
    final head = s.length > 80 ? s.substring(0, 80) : s;
    return head.replaceAll(RegExp(r'[^ -~]'), '?');
  }

  /// 手动完成：用输入框中的 workspace ID。
  Future<void> _finishManually() async {
    final ws = _workspaceController.text.trim();
    if (ws.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loginWorkspaceIdLabel)),
      );
      return;
    }
    await _captureSession(ws);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.loginTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _winController == null
                ? const Center(child: CircularProgressIndicator())
                : wwf.WinWebViewWidget(controller: _winController!),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.loginWorkspaceIdLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _workspaceController,
                        decoration: InputDecoration(
                          hintText: 'wrk_…',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _busy ? null : _finishManually,
                      child: Text(s.confirm),
                    ),
                  ],
                ),
                if (_busy) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.loginWaiting,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
                if (_status.isNotEmpty && !_busy) ...[
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
