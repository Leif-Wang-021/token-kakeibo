import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/opencode_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Kazumi 风格使用历史页：用量/历史/模型共享同一份全局用量数据。
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    if (!_requested &&
        state.session != null &&
        state.usageRows.isEmpty &&
        !state.usageLoading) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppState>().loadUsageData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final state = context.watch<AppState>();
    if (state.session == null) {
      return _LoggedOut(s: s);
    }
    final records = state.allUsage.isNotEmpty
        ? state.allUsage
        : state.usageRows;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.usageTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: s.refresh,
            onPressed: state.usageLoading
                ? null
                : () => state.loadUsageData(force: true),
            icon: state.usageLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.loadUsageData(force: true),
        child: state.usageLoading && records.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.usageError != null && records.isEmpty
            ? _ErrorState(
                onRetry: () {
                  state.loadUsageData(force: true);
                },
              )
            : records.isEmpty
            ? _EmptyState(message: s.usageEmpty)
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _UsageRow(record: records[index], l10n: s),
              ),
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.record, required this.l10n});

  final OcUsageRecord record;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ModelColors.forModel(record.model);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showBreakdown(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateLabel(record.timeCreated),
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_fmt(record.totalInputTokens)} / ${_fmt(record.outputTokens)}',
                    style: TextStyle(fontSize: 13, color: scheme.onSurface),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '\$${record.costUsd.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context) {
    final s = l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.model),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _line(context, s.usageDate, _dateLabel(record.timeCreated)),
            _line(context, s.usageInput, _fmt(record.totalInputTokens)),
            if (record.cacheReadTokens != null)
              _line(
                context,
                s.breakdownCacheRead,
                _fmt(record.cacheReadTokens!),
              ),
            if (record.cacheWrite5mTokens != null ||
                record.cacheWrite1hTokens != null)
              _line(
                context,
                s.breakdownCacheWrite,
                _fmt(
                  (record.cacheWrite5mTokens ?? 0) +
                      (record.cacheWrite1hTokens ?? 0),
                ),
              ),
            _line(context, s.breakdownOutput, _fmt(record.outputTokens)),
            if (record.reasoningTokens != null)
              _line(
                context,
                s.breakdownReasoning,
                _fmt(record.reasoningTokens!),
              ),
            _line(
              context,
              s.usageCost,
              '\$${record.costUsd.toStringAsFixed(4)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime t) {
    final l = t.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _LoggedOut extends StatelessWidget {
  const _LoggedOut({required this.s});

  final L10n s;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s.usageTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            s.loginTitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
