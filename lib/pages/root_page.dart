import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../state/app_state.dart';
import 'dashboard_page.dart';
import 'history_page.dart';
import 'model_page.dart';
import 'settings_page.dart';

/// Kazumi 风格根导航：窄屏底部四导航，宽屏左侧 NavigationRail。
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;

  Future<void> _openSearch() async {
    final state = context.read<AppState>();
    final models = state.allUsage.map((r) => r.model).toSet().toList()..sort();
    final result = await showSearch<String>(
      context: context,
      delegate: _ModelSearchDelegate(models, context.l10n.searchModels),
    );
    if (result != null && mounted) {
      setState(() => _index = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final pages = <Widget>[
      const DashboardPage(),
      const HistoryPage(),
      const ModelPage(),
      const SettingsPage(),
    ];
    final labels = [s.navUsage, s.navHistory, s.navModels, s.navSettings];
    final icons = <IconData, IconData>{
      Icons.home_outlined: Icons.home,
      Icons.timeline_outlined: Icons.timeline,
      Icons.donut_small_outlined: Icons.donut_small,
      Icons.settings_outlined: Icons.settings,
    };
    final destinations = [
      for (var i = 0; i < labels.length; i++)
        NavigationRailDestination(
          icon: Icon(icons.keys.elementAt(i)),
          selectedIcon: Icon(icons.values.elementAt(i)),
          label: Text(labels[i]),
        ),
    ];

    if (wide) {
      final borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      );
      return Scaffold(
        backgroundColor: scheme.surfaceContainer,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: scheme.surfaceContainer,
              groupAlignment: 1,
              leading: FloatingActionButton(
                elevation: 0,
                heroTag: null,
                onPressed: _openSearch,
                child: const Icon(Icons.search),
              ),
              labelType: NavigationRailLabelType.selected,
              destinations: destinations,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: IndexedStack(index: _index, children: pages),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(
              icon: Icon(icons.keys.elementAt(i)),
              selectedIcon: Icon(icons.values.elementAt(i)),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}

class _ModelSearchDelegate extends SearchDelegate<String> {
  _ModelSearchDelegate(this.models, this._label);

  final List<String> models;
  final String _label;

  @override
  String get searchFieldLabel => _label;

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      tooltip: context.l10n.close,
      onPressed: () => close(context, ''),
      icon: const Icon(Icons.close),
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, ''),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final q = query.trim().toLowerCase();
    final matches = models
        .where((m) => q.isEmpty || m.toLowerCase().contains(q))
        .toList();
    if (matches.isEmpty) {
      return Center(child: Text(context.l10n.empty));
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(Icons.memory),
        title: Text(matches[index]),
        onTap: () => close(context, matches[index]),
      ),
    );
  }
}
