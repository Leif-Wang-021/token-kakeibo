import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/context_l10n.dart';
import '../services/app_paths.dart';
import '../services/app_info.dart';
import '../services/app_logger.dart';
import '../services/update_service.dart';
import '../state/app_state.dart';
import 'log_viewer_page.dart';
import 'settings_subpages.dart' show DevPage, SettingsDetailScaffold;

/// 仿 Kazumi 关于页：开源 / 外部链接 / 存储与日志 / 应用更新 / 开发者。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _versionTapCount = 0;
  DateTime? _lastVersionTap;
  bool _checkingUpdate = false;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final state = context.watch<AppState>();
    return SettingsDetailScaffold(
      title: s.aboutTitle,
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
                value: 'GitHub',
                onTap: () => _openUrl(kProjectHomeUrl),
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
                value: kAppVersion,
                onTap: _handleVersionTap,
              ),
              _AboutTile(
                icon: Icons.update_rounded,
                title: s.updateCheck,
                description: s.updateCheckDesc,
                value: _checkingUpdate ? s.updateChecking : null,
                onTap: _checkingUpdate ? () {} : _checkUpdate,
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
      final uri = Uri.parse(url);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
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
      applicationVersion: kAppVersion,
      applicationLegalese: 'GNU General Public License v3.0',
    );
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final release = await UpdateService().fetchLatest();
      if (!mounted) return;
      setState(() => _checkingUpdate = false);
      _showUpdateResult(release);
    } catch (e) {
      AppLogger.e('check update failed: $e');
      if (!mounted) return;
      setState(() => _checkingUpdate = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.updateFailed)));
    }
  }

  void _showUpdateResult(ReleaseInfo release) {
    final s = context.l10n;
    final hasUpdate = UpdateService.isNewer(release.tagName, kAppVersion);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(hasUpdate ? s.updateAvailable : s.updateNoUpdate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogLine(s.updateCurrent, kAppVersion),
              const SizedBox(height: 8),
              _dialogLine(
                s.updateLatest,
                release.tagName.isEmpty ? release.name : release.tagName,
              ),
              if (hasUpdate && release.body != null) ...[
                const SizedBox(height: 12),
                Text(
                  s.updateReleaseNotes,
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(release.body!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.close),
          ),
          if (hasUpdate)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openUrl(release.htmlUrl);
              },
              child: Text(s.updateOpenRelease),
            ),
        ],
      ),
    );
  }

  Widget _dialogLine(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: TextStyle(color: scheme.onSurfaceVariant)),
        Expanded(child: Text(value)),
      ],
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
