import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database.dart';
import 'data/repositories.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'screens/input_screen.dart';
import 'screens/log_screen.dart';
import 'screens/tasks_screen.dart';
import 'services/logger_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppDatabase? database;
  try {
    database = await AppDatabase.open();
    LoggerService.configure(IsarLogRepository(database.isar));
  } catch (error, stackTrace) {
    await LoggerService.instance.error(
      'Local database initialization failed; using in-memory storage',
      error: error,
      stackTrace: stackTrace,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        if (database != null) appDatabaseProvider.overrideWithValue(database),
        loggerServiceProvider.overrideWithValue(LoggerService.instance),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SourceInstallerShell(),
    );
  }
}

class SourceInstallerShell extends StatelessWidget {
  const SourceInstallerShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.link), text: l10n.analyzeTab),
              Tab(icon: const Icon(Icons.download), text: l10n.tasksTab),
              Tab(icon: const Icon(Icons.list_alt), text: l10n.logTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [InputScreen(), TasksScreen(), LogScreen()],
        ),
      ),
    );
  }
}
