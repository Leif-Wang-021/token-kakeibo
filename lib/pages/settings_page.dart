import 'package:flutter/material.dart';

import '../l10n/context_l10n.dart';
import 'about_page.dart';
import 'settings_subpages.dart' hide AboutPage;

/// Kazumi 风格设置主页：分组标题 + 圆角分裂卡片。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SafeArea(
      top: true,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeader(title: s.navSettings),
                  _Group(
                    title: s.settingsGroupAccount,
                    children: [
                      _CategoryTile(
                        icon: Icons.account_circle_rounded,
                        title: s.settingsAccountInfo,
                        desc: s.settingsAccountInfoDesc,
                        onTap: () => _push(context, const AccountPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Group(
                    title: s.settingsGroupGeneral,
                    children: [
                      _CategoryTile(
                        icon: Icons.palette_rounded,
                        title: s.settingsAppearance,
                        desc: s.settingsAppearanceDesc,
                        onTap: () => _push(context, const AppearancePage()),
                      ),
                      _CategoryTile(
                        icon: Icons.autorenew_rounded,
                        title: s.settingsAutoRefresh,
                        desc: s.settingsAutoRefreshDesc,
                        onTap: () => _push(context, const AutoRefreshPage()),
                      ),
                      _CategoryTile(
                        icon: Icons.notifications_active_rounded,
                        title: s.settingsAlert,
                        desc: s.settingsAlertDesc,
                        onTap: () => _push(context, const AlertPage()),
                      ),
                      _CategoryTile(
                        icon: Icons.cloud_sync_rounded,
                        title: s.settingsSync,
                        desc: s.settingsSyncDesc,
                        onTap: () => _push(context, const SyncPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Group(
                    title: s.settingsGroupAbout,
                    children: [
                      _CategoryTile(
                        icon: Icons.info_rounded,
                        title: s.settingsAbout,
                        desc: s.settingsAboutDesc,
                        onTap: () => _push(context, const AboutPage()),
                      ),
                    ],
                  ),
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
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

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
        _SplitGroup(children: children),
      ],
    );
  }
}

class _SplitGroup extends StatelessWidget {
  const _SplitGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          _SplitRow(
            first: i == 0,
            last: i == children.length - 1,
            child: children[i],
          ),
        ],
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.first,
    required this.last,
    required this.child,
  });

  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final outer = 24.0;
    final inner = 4.0;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(first ? outer : inner),
          bottom: Radius.circular(last ? outer : inner),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
