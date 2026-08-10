import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/opencode_data.dart';
import '../models/opencode_session.dart';
import '../services/app_logger.dart';
import '../state/app_state.dart';
import '../widgets/cost_bar_chart.dart';
import '../widgets/go_usage_bars.dart';
import 'login_page.dart';

/// 用量主页：Go 套餐用量条 + 月度成本柱状图。
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  OcCostData? _cost;
  bool _costLoading = false;
  String? _costError;

  int _year = DateTime.now().year;
  int _month = DateTime.now().month; // 1-based
  String? _selectedModel;
  String? _selectedKey;

  AppState? _state;
  OpenCodeSession? _lastSession;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    if (_state != state || _lastSession != state.session) {
      _state = state;
      _lastSession = state.session;
      state.onAutoRefresh = () {
        if (mounted) _refreshAll();
      };
      if (state.session != null) {
        unawaited(_refreshAll());
      }
    }
  }

  @override
  void dispose() {
    _state = null;
    super.dispose();
  }

  Future<void> _refreshAll() async {
    final state = _state;
    if (state == null) return;
    final session = state.session;
    if (session == null) return;
    await Future.wait([
      state.loadUsageData(force: true),
      _loadCost(force: true),
    ]);
  }

  Future<void> _loadCost({bool force = false}) async {
    final state = _state;
    if (state == null || _costLoading) return;
    final session = state.session;
    if (session == null) return;
    setState(() {
      _costLoading = true;
      _costError = null;
    });
    try {
      final cost = await state.loadCostCached(
        year: _year,
        month: _month,
        force: force,
      );
      if (!mounted) return;
      setState(() {
        _cost = cost;
        _costLoading = false;
      });
    } catch (e) {
      AppLogger.w('load cost failed: $e');
      if (!mounted) return;
      setState(() {
        _costLoading = false;
        _costError = e.toString();
      });
    }
  }

  void _prevMonth() {
    if (_month == 1) {
      _month = 12;
      _year -= 1;
    } else {
      _month -= 1;
    }
    _loadCost();
  }

  void _nextMonth() {
    if (_month == 12) {
      _month = 1;
      _year += 1;
    } else {
      _month += 1;
    }
    _loadCost();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = context.l10n;
    if (state.session == null) {
      return SafeArea(child: _LoginPrompt(s: s));
    }
    return SafeArea(
      top: true,
      bottom: false,
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: _refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _PageHeader(s: s, onRefresh: _refreshAll),
            if (_costError != null)
              _ErrorBanner(
                message: s.error,
                onRetry: () => _loadCost(force: true),
              ),
            const SizedBox(height: 12),
            GoUsageBars(subscription: state.liteSubscription),
            const SizedBox(height: 28),
            _CostSection(
              cost: _cost,
              year: _year,
              month: _month,
              loading: _costLoading,
              selectedModel: _selectedModel,
              selectedKey: _selectedKey,
              onPrevMonth: _prevMonth,
              onNextMonth: _nextMonth,
              onSelectModel: (m) => setState(() => _selectedModel = m),
              onSelectKey: (k) => setState(() => _selectedKey = k),
              onRefresh: _refreshAll,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.s, required this.onRefresh});

  final L10n s;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.appTagline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.refresh,
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.s});

  final L10n s;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle_outlined,
                  size: 34,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.loginTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                s.loginSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                  if (ok == true && context.mounted) {
                    // 会话已保存，Dashboard 会因 AppState 变化重建。
                  }
                },
                icon: const Icon(Icons.login),
                label: Text(s.loginOpenBrowser),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).colorScheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: danger),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}

class _CostSection extends StatelessWidget {
  const _CostSection({
    required this.cost,
    required this.year,
    required this.month,
    required this.loading,
    required this.selectedModel,
    required this.selectedKey,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectModel,
    required this.onSelectKey,
    required this.onRefresh,
  });

  final OcCostData? cost;
  final int year;
  final int month;
  final bool loading;
  final String? selectedModel;
  final String? selectedKey;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<String?> onSelectModel;
  final ValueChanged<String?> onSelectKey;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = cost;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: s.costTitle, subtitle: s.costSubtitle),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MonthPicker(
              label: s.monthLabel(year, month),
              onPrev: onPrevMonth,
              onNext: onNextMonth,
            ),
            _FilterDropdown<String?>(
              label: selectedModel ?? s.costAllModels,
              items: {s.costAllModels: null, for (final m in _models) m: m},
              onSelected: onSelectModel,
            ),
            _FilterDropdown<String?>(
              label: _keyLabel(s),
              items: {
                s.costAllKeys: null,
                for (final k in cost?.keys ?? const <OcKey>[])
                  k.displayName: k.id,
              },
              onSelected: onSelectKey,
            ),
            IconButton(
              tooltip: s.refresh,
              onPressed: loading ? null : onRefresh,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 400,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: c == null
              ? Center(
                  child: Text(
                    loading ? s.loading : s.costEmpty,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : CostBarChart(
                  rows: c.usage,
                  year: year,
                  month: month,
                  selectedModel: selectedModel,
                  selectedKey: selectedKey,
                ),
        ),
      ],
    );
  }

  List<String> get _models {
    final rows = cost?.usage ?? const <OcCostRow>[];
    return rows.map((r) => r.model).toSet().toList()..sort();
  }

  String _keyLabel(L10n s) {
    if (selectedKey == null) return s.costAllKeys;
    final found = cost?.keys.where((k) => k.id == selectedKey).firstOrNull;
    if (found == null) return s.costAllKeys;
    return found.deleted
        ? '${found.displayName} ${s.costDeletedSuffix}'
        : found.displayName;
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final Map<String, T> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(4),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
      ),
      menuChildren: [
        for (final entry in items.entries)
          MenuItemButton(
            onPressed: () => onSelected(entry.value),
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(
                entry.value == null
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
              textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13)),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(entry.key, overflow: TextOverflow.ellipsis),
                ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: scheme.onSurface),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down, size: 16, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MonthButton(icon: Icons.chevron_left, onTap: onPrev),
          SizedBox(
            width: 150,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
          _MonthButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(icon, size: 16, color: scheme.onSurface),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
