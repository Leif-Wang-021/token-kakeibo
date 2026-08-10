import 'package:flutter/material.dart';

import '../l10n/context_l10n.dart';
import '../models/opencode_data.dart';

/// Go 套餐用量限制条（照 `opencode.ai/workspace/[workspaceId]/go` 页面）：
/// 滚动用量（5 小时）/ 每周用量 / 每月用量，各带百分比 + 进度条 + 重置时间。
class GoUsageBars extends StatelessWidget {
  const GoUsageBars({super.key, required this.subscription});

  final OcLiteSubscription? subscription;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final sub = subscription;
    if (sub == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: s.goUsageTitle, subtitle: s.goUsageSubtitle),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final bars = [
              _UsageBar(
                label: s.goRollingUsage,
                usage: sub.rollingUsage,
                l10n: s,
              ),
              _UsageBar(
                label: s.goWeeklyUsage,
                usage: sub.weeklyUsage,
                l10n: s,
              ),
              _UsageBar(
                label: s.goMonthlyUsage,
                usage: sub.monthlyUsage,
                l10n: s,
              ),
            ];
            if (maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < bars.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: bars[i]),
                  ],
                ],
              );
            }
            final itemWidth = maxWidth >= 520
                ? (maxWidth - 12) / 2
                : maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final bar in bars) SizedBox(width: itemWidth, child: bar),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.label,
    required this.usage,
    required this.l10n,
  });

  final String label;
  final OcLiteUsage? usage;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final u = usage;
    final percent = u?.usagePercent ?? 0;
    final rateLimited = u?.rateLimited ?? false;
    final accent = rateLimited
        ? const Color(0xFFFF3B30)
        : scheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rateLimited ? accent : scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rateLimited
                ? l10n.goRateLimited
                : '${l10n.goResetsIn} ${l10n.resetTime(u?.resetInSec ?? 0)}',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
