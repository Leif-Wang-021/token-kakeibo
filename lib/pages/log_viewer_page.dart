import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/context_l10n.dart';
import '../services/app_logger.dart';

/// 本地日志查看页：查看最近日志、复制到剪贴板、打开日志目录。
class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  List<String> _lines = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _lines = AppLogger.recentLines(count: 400));
  }

  Future<void> _copy() async {
    final s = context.l10n;
    await Clipboard.setData(
      ClipboardData(text: _lines.join('\n')),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.logsCopied)),
    );
  }

  Future<void> _openDir() async {
    final path = AppLogger.currentLogPath;
    if (path == null) return;
    try {
      // 打开资源管理器并定位到当前日志文件（Windows）。
      await Process.start('explorer.exe', ['/select,', path]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final logPath = AppLogger.currentLogPath;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.logViewerTitle),
        actions: [
          IconButton(
            tooltip: s.openLogDir,
            onPressed: _openDir,
            icon: const Icon(Icons.folder_open_outlined),
          ),
          IconButton(
            tooltip: s.copyLogs,
            onPressed: _lines.isEmpty ? null : _copy,
            icon: const Icon(Icons.copy_all_outlined),
          ),
          IconButton(
            tooltip: s.refresh,
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
            if (logPath != null)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.secondaryContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text(
                  logPath,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
            Expanded(
              child: _lines.isEmpty
                  ? Center(
                      child: Text(
                        s.noLogs,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _lines.length,
                      itemBuilder: (context, i) {
                        final line = _lines[i];
                        final isError = line.contains('] ERROR');
                        final isWarn = line.contains('] WARN');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            line,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                                                    fontSize: 11,
                                  height: 1.4,
                                  color: isError
                                      ? const Color(0xFFFF3B30)
                                      : isWarn
                                          ? const Color(0xFFFF9F0A)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
    );
  }
}
