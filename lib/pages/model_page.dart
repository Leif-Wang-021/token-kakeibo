import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../state/app_state.dart';
import '../widgets/model_consumption.dart';

/// Kazumi 风格模型消耗页：按模型汇总 token 用量。
class ModelPage extends StatefulWidget {
  const ModelPage({super.key});

  @override
  State<ModelPage> createState() => _ModelPageState();
}

class _ModelPageState extends State<ModelPage> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    if (!_requested &&
        state.session != null &&
        state.allUsage.isEmpty &&
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
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (state.session == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    s.loginTitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ModelConsumption(
                records: state.allUsage,
                refreshing: state.usageLoading,
                onRefresh: () => state.loadUsageData(force: true),
              ),
          ],
        ),
      ),
    );
  }
}
