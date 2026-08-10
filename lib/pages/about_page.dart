import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../services/app_paths.dart';
import '../state/app_state.dart';
import 'log_viewer_page.dart';
import 'settings_subpages.dart' show DevPage;

/// 仿 Kazumi 关于页：开源 / 外部链接 / 存储与日志 / 应用更新 / 开发者。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _versionTapCount = 0;
  DateTime? _lastVersionTap;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(s.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AboutSection(
                    title: s.aboutOpenSource,
                    children: [
                      _AboutTile(
                        icon: Icons.gavel_rounded,
                        title: s.aboutLicense,
                        description: s.aboutLicenseDesc,
                        onTap: () => _showLicense(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AboutSection(
                    title: s.aboutExternal,
                    children: [
                      _AboutTile(
                        icon: Icons.home_rounded,
                        title: s.aboutProjectHome,
                        description: s.aboutProjectHomeDesc,
                        value: 'OpenCode',
                        onTap: () => _openUrl('https://opencode.ai'),
                      ),
                      _AboutTile(
                        icon: Icons.insights_rounded,
                        title: s.aboutOpenUsage,
                        description: s.aboutOpenUsageDesc,
                        onTap: () => _openUsage(state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AboutSection(
                    title: s.aboutData,
                    children: [
                      _AboutTile(
                        icon: Icons.folder_open_rounded,
                        title: s.aboutDataDir,
                        description: s.aboutDataDirDesc,
                        onTap: _openDataDir,
                      ),
                      _AboutTile(
                        icon: Icons.receipt_long_rounded,
                        title: s.aboutLogs,
                        description: s.aboutLogsDesc,
                        onTap: () => _push(context, const LogViewerPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AboutSection(
                    title: s.aboutUpdate,
                    children: [
                      _AboutTile(
                        icon: Icons.system_update_rounded,
                        title: s.aboutCurrentVersion,
                        value: '1.2.0',
                        onTap: _handleVersionTap,
                      ),
                    ],
                  ),
                  if (state.devMode) ...[
                    const SizedBox(height: 12),
                    _AboutSection(
                      title: s.aboutDevSection,
                      children: [
                        _AboutTile(
                          icon: Icons.developer_mode_rounded,
                          title: s.devTitle,
                          description: s.devModeDesc,
                          onTap: () => _push(context, const DevPage()),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _openUsage(AppState state) {
    final id = state.session?.workspaceId;
    _openUrl(
      id == null
          ? 'https://opencode.ai'
          : 'https://opencode.ai/workspace/$id/usage',
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      await Process.start('explorer.exe', [url]);
    } catch (_) {}
  }

  Future<void> _openDataDir() async {
    try {
      final dir = await AppPaths.dataDirectory();
      await Process.start('explorer.exe', [dir.path]);
    } catch (_) {}
  }

  void _showLicense(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: context.l10n.appTitle,
      applicationVersion: '1.2.0',
      applicationLegalese: 'GNU General Public License v3.0',
    );
  }

  void _handleVersionTap() {
    final now = DateTime.now();
    if (_lastVersionTap != null &&
        now.difference(_lastVersionTap!) > const Duration(seconds: 2)) {
      _versionTapCount = 0;
    }
    _lastVersionTap = now;
    _versionTapCount++;
    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      context.read<AppState>().setDevMode(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.aboutDevOpened)));
    }
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _AboutGroup(children: children),
      ],
    );
  }
}

class _AboutGroup extends StatelessWidget {
  const _AboutGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(i == 0 ? 24 : 4),
                bottom: Radius.circular(i == children.length - 1 ? 24 : 4),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: children[i],
          ),
        ],
      ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.description,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: scheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              Text(
                value!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
