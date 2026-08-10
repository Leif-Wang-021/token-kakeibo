import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/sync_config.dart';
import '../models/theme_preference.dart';
import '../state/app_state.dart';

/// 设置二级页公共 Scaffold（kazumi SettingsDetailScaffold 风格）。
class SettingsDetailScaffold extends StatelessWidget {
  const SettingsDetailScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), scrolledUnderElevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// 外观：语言 + 主题。
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final state = context.watch<AppState>();
    return SettingsDetailScaffold(
      title: s.settingsAppearance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, s.settingsLanguage),
          const SizedBox(height: 8),
          _MenuField<AppLocale>(
            value: state.locale,
            items: {for (final l in AppLocale.values) l.label: l},
            labelOf: (l) => l.label,
            onSelected: (v) => state.setLocale(v),
          ),
          const SizedBox(height: 24),
          _label(context, s.settingsTheme),
          const SizedBox(height: 8),
          _MenuField<AppThemePreference>(
            value: state.themePreference,
            items: {
              s.themeSystem: AppThemePreference.system,
              s.themeLight: AppThemePreference.light,
              s.themeDark: AppThemePreference.dark,
            },
            labelOf: (p) => switch (p) {
              AppThemePreference.system => s.themeSystem,
              AppThemePreference.light => s.themeLight,
              AppThemePreference.dark => s.themeDark,
            },
            onSelected: (v) => state.setThemePreference(v),
          ),
        ],
      ),
    );
  }
}

/// 通用下拉选择字段（MenuAnchor 实现，全局统一，避免 M3 Dropdown 重叠问题）。
class _MenuField<T> extends StatelessWidget {
  const _MenuField({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onSelected,
  });

  final T value;
  final Map<String, T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 6),
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(4),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
        ),
        menuChildren: [
          for (final entry in items.entries)
            MenuItemButton(
              onPressed: () => onSelected(entry.value),
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  entry.value == value ? scheme.primary : scheme.onSurface,
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 14),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(entry.key)),
                  if (entry.value == value) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.check, size: 16, color: scheme.primary),
                  ],
                ],
              ),
            ),
        ],
        builder: (context, controller, child) => InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labelOf(value),
                    style: TextStyle(fontSize: 14, color: scheme.onSurface),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 自动刷新：间隔选择。
class AutoRefreshPage extends StatelessWidget {
  const AutoRefreshPage({super.key});

  static const _options = [0, 5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final state = context.watch<AppState>();
    return SettingsDetailScaffold(
      title: s.settingsAutoRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.refreshDesc, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: RadioGroup<int>(
              groupValue: state.autoRefreshMinutes,
              onChanged: (v) {
                if (v != null) state.setAutoRefreshMinutes(v);
              },
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    RadioListTile<int>(
                      value: _options[i],
                      title: Text(
                        _options[i] == 0
                            ? s.refreshOff
                            : s.refreshMinutes(_options[i]),
                        style: const TextStyle(fontSize: 14),
                      ),
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
}

/// 账户：登录状态 + 退出。
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final state = context.watch<AppState>();
    final session = state.session;
    return SettingsDetailScaffold(
      title: s.settingsAccountInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_circle,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session == null ? s.loginWelcome : s.loginWelcome,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session == null
                            ? 'OpenCode'
                            : '${s.loginWorkspace}: ${session.workspaceId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (session != null)
                  TextButton(
                    onPressed: () async {
                      final ok = await _confirmLogout(context);
                      if (ok == true && context.mounted) {
                        await state.clearSession();
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(s.logoutDone)));
                        }
                      }
                    },
                    child: Text(
                      s.logout,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    final s = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.logout),
        content: Text(s.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
  }
}

/// 额度预警：三个阈值滑块。
class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  late int _rolling;
  late int _weekly;
  late int _monthly;

  @override
  void initState() {
    super.initState();
    final t = context.read<AppState>().alertThresholds;
    _rolling = t.rolling;
    _weekly = t.weekly;
    _monthly = t.monthly;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final state = context.read<AppState>();
    return SettingsDetailScaffold(
      title: s.alertTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.alertSubtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          _thresholdSlider(
            context,
            label: s.alertRolling,
            value: _rolling,
            onChanged: (v) => setState(() => _rolling = v),
          ),
          const SizedBox(height: 16),
          _thresholdSlider(
            context,
            label: s.alertWeekly,
            value: _weekly,
            onChanged: (v) => setState(() => _weekly = v),
          ),
          const SizedBox(height: 16),
          _thresholdSlider(
            context,
            label: s.alertMonthly,
            value: _monthly,
            onChanged: (v) => setState(() => _monthly = v),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                await state.setAlertThresholds(
                  AlertThresholds(
                    rolling: _rolling,
                    weekly: _weekly,
                    monthly: _monthly,
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.alertSaved)));
                }
              },
              child: Text(s.confirm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thresholdSlider(
    BuildContext context, {
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final s = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14)),
              ),
              Text(
                s.alertPercent(value),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 10,
            max: 100,
            divisions: 18,
            label: s.alertPercent(value),
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

/// 开发者选项：测试通知。
class DevPage extends StatelessWidget {
  const DevPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final state = context.read<AppState>();
    return SettingsDetailScaffold(
      title: s.devTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.devTestNotification,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            s.devTestNotificationDesc,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => state.sendTestNotification(),
                    icon: const Icon(Icons.send, size: 16),
                    label: Text(s.devTestNotification),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${s.devModeLabel}: ${state.devMode ? s.devModeDesc : s.devModeDesc}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await state.setDevMode(false);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.devDisable)));
                }
              },
              icon: const Icon(Icons.lock_outline, size: 16),
              label: Text(s.devDisable),
            ),
          ),
        ],
      ),
    );
  }
}

/// WebDAV 多端同步配置页。
class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late final TextEditingController _url;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<AppState>().syncConfig;
    _url = TextEditingController(text: cfg.url);
    _username = TextEditingController(text: cfg.username);
    _password = TextEditingController(text: cfg.password);
    _enabled = cfg.enabled;
  }

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final state = context.watch<AppState>();
    return SettingsDetailScaffold(
      title: s.syncTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.syncSubtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.syncEnabled),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _url,
            decoration: InputDecoration(
              labelText: s.syncUrl,
              hintText: s.syncUrlHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _username,
            decoration: InputDecoration(labelText: s.syncUsername),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: s.syncPassword),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await state.setSyncConfig(
                  WebDavConfig(
                    enabled: _enabled,
                    url: _url.text.trim(),
                    username: _username.text.trim(),
                    password: _password.text,
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.syncSaved)));
                }
              },
              icon: const Icon(Icons.cloud_sync, size: 18),
              label: Text(s.syncSave),
            ),
          ),
          const SizedBox(height: 12),
          if (state.syncConfig.configured) ...[
            OutlinedButton.icon(
              onPressed: state.syncing ? null : () => state.syncNow(),
              icon: state.syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 16),
              label: Text(s.syncNow),
            ),
            const SizedBox(height: 12),
            // 同步状态
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.syncStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.syncError != null
                        ? s.syncFail
                        : state.syncSucceeded
                        ? s.syncDone
                        : state.syncConfig.lastSyncAt == null
                        ? s.syncNever
                        : '${s.syncLastAt} '
                              '${_fmtTime(state.syncConfig.lastSyncAt!)}',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    final l = t.toLocal();
    return '${l.month}/${l.day} ${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}

Widget _label(BuildContext context, String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
