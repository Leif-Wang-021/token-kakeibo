import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/context_l10n.dart';
import '../models/opencode_data.dart';
import '../theme/app_theme.dart';

/// 单日单栈的一个模型段。
class _StackSegment {
  const _StackSegment(this.model, this.costUsd, this.color);

  final String model;
  final double costUsd;
  final Color color;
}

/// 单日三根柱（regular / sub / lite 各一），每根内部按模型堆叠。
class _DayBars {
  _DayBars(this.date);

  final DateTime date;
  final List<_StackSegment> regular = [];
  final List<_StackSegment> sub = [];
  final List<_StackSegment> lite = [];

  List<_StackSegment> stackOf(_StackKind kind) => switch (kind) {
    _StackKind.regular => regular,
    _StackKind.sub => sub,
    _StackKind.lite => lite,
  };

  double get maxStack =>
      math.max(_sum(regular), math.max(_sum(sub), _sum(lite)));

  static double _sum(List<_StackSegment> stack) =>
      stack.fold(0.0, (a, s) => a + s.costUsd);
}

enum _StackKind { regular, sub, lite }

/// 按 opencode 网页复刻的成本堆叠柱状图（fl_chart 实现，布局/刻度自适应）。
///
/// - x 轴：当月每天；每天最多三根柱（regular / 订阅 / Go），柱内按模型堆叠
/// - 模型颜色：网页 MODEL_COLORS 固定色表 + 哈希兜底
/// - 订阅栈 50% 透明度 + 实线边框；Go 栈 35% 透明度 + 虚线边框
/// - y 轴 `$1.2k` / `$0.5`；tooltip `模型: $0.02`
class CostBarChart extends StatelessWidget {
  const CostBarChart({
    super.key,
    required this.rows,
    required this.year,
    required this.month, // 1-based
    required this.selectedModel,
    required this.selectedKey,
  });

  /// 当月全部成本行（筛选前）。
  final List<OcCostRow> rows;

  final int year;
  final int month; // 1-based

  final String? selectedModel;
  final String? selectedKey;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final filtered = rows
        .where(
          (r) =>
              (selectedKey == null || r.keyId == selectedKey) &&
              (selectedModel == null || r.model == selectedModel),
        )
        .toList();

    final allDays = _buildDays(year, month, filtered);
    final days = allDays
        .where(
          (d) => d.regular.isNotEmpty || d.sub.isNotEmpty || d.lite.isNotEmpty,
        )
        .toList();
    if (days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            s.costEmpty,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final maxCost = days.fold<double>(0, (m, d) => math.max(m, d.maxStack));
    final yMax = _niceCeil(maxCost == 0 ? 1 : maxCost);
    final dayCount = days.length;

    final gridColor = scheme.outlineVariant;
    final muted = scheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 640.0;
        // fl_chart 对柱状图 x 轴会为每个 bar 生成标题，interval 在
        // BarChart 的水平轴不生效；这里在 getTitlesWidget 中主动抽稀。
        final labelInterval = switch (availableWidth) {
          < 340 => 5,
          < 520 => 3,
          < 760 => 2,
          _ => 1,
        };
        final plotWidth = math.max(80.0, availableWidth - 60.0);
        final compactBars = availableWidth < 760;
        final barWidth = compactBars
            ? math.min(22.0, math.max(5.0, plotWidth / dayCount * 0.72))
            : math.min(16.0, math.max(3.0, plotWidth / dayCount / 3 - 1.5));
        return BarChart(
          key: ValueKey<String>(
            '$labelInterval-$compactBars-${(barWidth * 2).round()}',
          ),
          BarChartData(
            minY: 0,
            maxY: yMax,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.surfaceContainerHighest,
                tooltipBorder: BorderSide(color: scheme.outlineVariant),
                tooltipPadding: const EdgeInsets.all(10),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final seg = _segmentAt(
                    days,
                    group.x,
                    rodIndex,
                    compact: compactBars,
                  );
                  if (seg == null) return null;
                  final suffix = rodIndex == 2
                      ? s.costGoSuffix
                      : rodIndex == 1
                      ? ' (${s.costSubscriptionShort})'
                      : '';
                  return BarTooltipItem(
                    '${seg.model}$suffix',
                    TextStyle(
                      color: scheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: '\n${L10n.chartTooltip(rod.toY - rod.fromY)}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yMax / 5,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: gridColor, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: yMax / 5,
                  getTitlesWidget: (value, meta) {
                    if (value < 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        L10n.chartYTick(value),
                        textAlign: TextAlign.right,
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: labelInterval.toDouble(),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= dayCount) {
                      return const SizedBox.shrink();
                    }
                    final isEdge = idx == 0 || idx == dayCount - 1;
                    if (!isEdge && idx % labelInterval != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        s.chartDayLabel(days[idx].date),
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < dayCount; i++)
                BarChartGroupData(
                  x: i,
                  barRods: _rodsFor(days[i], barWidth, compact: compactBars),
                ),
            ],
          ),
        );
      },
    );
  }

  List<BarChartRodData> _rodsFor(
    _DayBars day,
    double barWidth, {
    required bool compact,
  }) {
    if (compact) {
      final stacks = <(int, List<_StackSegment>)>[
        (0, day.regular),
        (1, day.sub),
        (2, day.lite),
      ];
      var bottom = 0.0;
      final items = <BarChartRodStackItem>[];
      for (final (rodIndex, stack) in stacks) {
        final opacity = switch (rodIndex) {
          1 => 0.5,
          2 => 0.35,
          _ => 1.0,
        };
        for (final seg in stack) {
          final fromY = bottom;
          bottom += seg.costUsd;
          items.add(
            BarChartRodStackItem(
              fromY,
              bottom,
              seg.color.withValues(alpha: opacity),
            ),
          );
        }
      }
      if (items.isEmpty) return const [];
      return [
        BarChartRodData(
          toY: bottom,
          width: barWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          rodStackItems: items,
          borderSide: BorderSide.none,
        ),
      ];
    }

    final rods = <BarChartRodData>[];
    final stacks = [(0, day.regular), (1, day.sub), (2, day.lite)];
    for (final (rodIndex, stack) in stacks) {
      if (stack.isEmpty) continue;
      final opacity = switch (rodIndex) {
        1 => 0.5,
        2 => 0.35,
        _ => 1.0,
      };
      final borderColor = switch (rodIndex) {
        1 => stack.first.color,
        2 => stack.first.color.withValues(alpha: 0.7),
        _ => Colors.transparent,
      };
      var bottom = 0.0;
      rods.add(
        BarChartRodData(
          toY: stack.fold(0.0, (a, seg) => a + seg.costUsd),
          width: barWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          rodStackItems: [
            for (final seg in stack)
              BarChartRodStackItem(
                bottom,
                bottom = bottom + seg.costUsd,
                seg.color.withValues(alpha: opacity),
              ),
          ],
          borderSide: borderColor == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: borderColor, width: 1),
        ),
      );
    }
    return rods;
  }

  _StackSegment? _segmentAt(
    List<_DayBars> days,
    int dayIdx,
    int rodIndex, {
    required bool compact,
  }) {
    if (dayIdx < 0 || dayIdx >= days.length) return null;
    final day = days[dayIdx];
    if (compact) {
      final candidates = [
        day.regular,
        day.sub,
        day.lite,
      ].where((s) => s.isNotEmpty).map((s) => s.last).toList();
      if (candidates.isEmpty) return null;
      candidates.sort((a, b) => b.costUsd.compareTo(a.costUsd));
      return candidates.first;
    }
    final stack = switch (rodIndex) {
      1 => day.sub,
      2 => day.lite,
      _ => day.regular,
    };
    if (stack.isEmpty) return null;
    // tooltip 显示该柱的最后一层（成本最高层近似），简单起见显示栈顶段。
    return stack.last;
  }

  List<_DayBars> _buildDays(int year, int month, List<OcCostRow> rows) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final map = <String, _DayBars>{};
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      map[key] = _DayBars(date);
    }
    for (final row in rows) {
      final day = map[row.date];
      if (day == null) continue;
      final segment = _StackSegment(
        row.model,
        row.costUsd,
        ModelColors.forModel(row.model),
      );
      switch (row.plan) {
        case OcPlan.sub:
          day.sub.add(segment);
        case OcPlan.lite:
          day.lite.add(segment);
        case OcPlan.regular:
          day.regular.add(segment);
      }
    }
    for (final d in map.values) {
      d.regular.sort((a, b) => a.model.compareTo(b.model));
      d.sub.sort((a, b) => a.model.compareTo(b.model));
      d.lite.sort((a, b) => a.model.compareTo(b.model));
    }
    return map.values.toList();
  }

  /// 网页 Chart.js 风格 y 轴上限：取 1/2/2.5/5 × 10^n。
  double _niceCeil(double v) {
    if (v <= 0) return 1;
    final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final n in [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (n * exp >= v) return n * exp;
    }
    return 10 * exp;
  }
}
