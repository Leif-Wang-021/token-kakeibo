import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/app_paths.dart';
import 'services/notification_service.dart';
import 'services/session_store.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _registerLicenses();
    final directory = await AppPaths.dataDirectory();
    await AppPaths.migrateLegacyDataIfNeeded(directory);
    await NotificationService.instance.init();
    final state = AppState(store: SessionStore(directory));
    await state.load();
    runApp(
      ChangeNotifierProvider.value(
        value: state,
        child: const TokenKakeiboApp(),
      ),
    );
  } catch (e, st) {
    _writeCrashLog(e, st);
    rethrow;
  }
}

Future<void> _registerLicenses() async {
  try {
    final gpl = await rootBundle.loadString('assets/licenses/GPL-3.0.txt');
    final ofl = await rootBundle.loadString(
      'assets/licenses/NotoSerifSC-OFL.txt',
    );
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(['Token家计薄'], gpl);
    });
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(['Noto Serif SC'], ofl);
    });
  } catch (e) {
    debugPrint('license registration failed: $e');
  }
}

void _writeCrashLog(Object error, StackTrace stack) {
  try {
    final tmp = Directory.systemTemp;
    final file = File(
      '${tmp.path}${Platform.pathSeparator}token_kakeibo_crash.log',
    );
    file.writeAsStringSync(
      '${DateTime.now()}\n$error\n$stack\n',
      mode: FileMode.append,
    );
  } catch (_) {}
}
