import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/l10n.dart';
import 'models/theme_preference.dart';
import 'pages/root_page.dart';
import 'state/app_state.dart';
import 'theme/wafu_theme.dart';

class TokenKakeiboApp extends StatefulWidget {
  const TokenKakeiboApp({super.key});

  @override
  State<TokenKakeiboApp> createState() => _TokenKakeiboAppState();
}

class _TokenKakeiboAppState extends State<TokenKakeiboApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // “系统”主题跟随系统亮暗变化时立即刷新
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final appTitle = L10n(state.locale).appTitle;
        return MaterialApp(
          key: ValueKey<String>(
            '${state.locale.name}-${state.themePreference.name}',
          ),
          title: appTitle,
          debugShowCheckedModeBanner: false,
          locale: state.locale.locale,
          supportedLocales: AppLocale.values.map((l) => l.locale).toList(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: WafuTheme.light(),
          darkTheme: WafuTheme.dark(),
          themeMode: switch (state.themePreference) {
            AppThemePreference.system =>
              platformBrightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
            AppThemePreference.light => ThemeMode.light,
            AppThemePreference.dark => ThemeMode.dark,
          },
          home: const RootPage(),
        );
      },
    );
  }
}
