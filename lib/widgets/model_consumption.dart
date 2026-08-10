import 'package:flutter/material.dart';

import '../l10n/context_l10n.dart';
import '../models/opencode_data.dart';
import '../theme/app_theme.dart';

/// 单模型的 token 汇总。
class ModelTokenSummary {
  const ModelTokenSummary({
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheTokens,
  });

  final String model;
  final int inputTokens;
  final int outputTokens;
  final int cacheTokens;

  int get totalTokens => inputTokens + outputTokens + cacheTokens;
}

/// 从用量记录聚合出按模型的 token 汇总（可过滤时间范围）。
List<ModelTokenSummary> aggregateByModel(
  List<OcUsageRecord> records, {
  DateTime? since,
}) {
  final map = <String, _Acc>{};
  for (final r in records) {
    if (since != null && r.timeCreated.isBefore(since)) continue;
    final acc = map.putIfAbsent(r.model, () => _Acc());
    acc.input += r.inputTokens;
    acc.output += r.outputTokens;
    acc.cache +=
        (r.cacheReadTokens ?? 0) +
        (r.cacheWrite5mTokens ?? 0) +
        (r.cacheWrite1hTokens ?? 0);
  }
  final list =
      map.entries
          .map(
            (e) => ModelTokenSummary(
              model: e.key,
              inputTokens: e.value.input,
              outputTokens: e.value.output,
              cacheTokens: e.value.cache,
            ),
          )
          .toList()
        ..sort((a, b) => b.totalTokens.compareTo(a.totalTokens));
  return list;
}

class _Acc {
  int input = 0;
  int output = 0;
  int cache = 0;
}

/// 模型消耗明细（旧版 _ModelConsumption 样式）：
/// 每行 = 色点（模型色）+ 模型名 + 细进度条（350ms 过渡）+ token 数
/// （输入+输出 主数字 + 橙色缓存）+ 百分比；顶部切换 本月 / 全部。
class ModelConsumption extends StatefulWidget {
  const ModelConsumption({
    super.key,
    required this.records,
    this.onRefresh,
    this.refreshing = false,
  });

  final List<OcUsageRecord> records;
  final VoidCallback? onRefresh;
  final bool refreshing;

  @override
  State<ModelConsumption> createState() => _ModelConsumptionState();
}

class _ModelConsumptionState extends State<ModelConsumption> {
  bool _thisMonth = true;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final summaries = aggregateByModel(
      widget.records,
      since: _thisMonth ? monthStart : null,
    );
    final total = summaries.fold<int>(0, (a, m) => a + m.totalTokens);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionTitle(
                title: s.modelConsumptionTitle,
                subtitle: s.modelConsumptionSubtitle,
              ),
            ),
            if (widget.onRefresh != null) ...[
              IconButton(
                tooltip: s.refresh,
                onPressed: widget.refreshing ? null : widget.onRefresh,
                icon: widget.refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
            ],
            _SegmentSwitch(
              thisMonth: _thisMonth,
              onChanged: (v) => setState(() => _thisMonth = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (summaries.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                s.empty,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final m in summaries)
                  _ModelRow(summary: m, total: total, l10n: s),
              ],
            ),
          ),
      ],
    );
  }
}

class _SegmentSwitch extends StatelessWidget {
  const _SegmentSwitch({required this.thisMonth, required this.onChanged});

  final bool thisMonth;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Seg(
            label: s.mcThisMonth,
            selected: thisMonth,
            onTap: () => onChanged(true),
          ),
          _Seg(
            label: s.mcAll,
            selected: !thisMonth,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.summary,
    required this.total,
    required this.l10n,
  });

  final ModelTokenSummary summary;
  final int total;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ModelColors.forModel(summary.model);
    final percent = total <= 0 ? 0.0 : summary.totalTokens / total;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 190,
            child: Text(
              summary.model,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 14),
          // 细进度条（350ms 过渡动画）
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percent),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: dark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                  valueColor: AlwaysStoppedAnimation(
                    color.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 110,
            child: Text(
              '${(percent * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 14),
          // token 数：输入+输出 主数字（固定宽右对齐）
          SizedBox(
            width: 130,
            child: Text(
              _fmt(summary.inputTokens + summary.outputTokens),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 橙色缓存（固定宽占位，无缓存也保留空间 → 各行列完全对齐）
          SizedBox(
            width: 110,
            child: summary.cacheTokens > 0
                ? Text(
                    '+${_fmt(summary.cacheTokens)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFFF9F0A),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
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
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
