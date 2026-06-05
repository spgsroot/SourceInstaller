import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/log_entry.dart';
import '../providers/app_providers.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  static const _maxEntries = 500;

  final _entries = <LogEntry>[];
  final _scrollController = ScrollController();
  StreamSubscription<LogEntry>? _subscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final logger = ref.read(loggerServiceProvider);
      final recent = await logger.recent();
      if (!mounted) return;
      setState(() => _replaceEntries(recent));
      _subscription = logger.stream.listen((entry) {
        if (!mounted) return;
        setState(() => _addEntry(entry));
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_entries.isEmpty) {
      return Center(child: Text(l10n.logEmpty));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _entries.length,
      itemBuilder: (context, index) => _LogRow(entry: _entries[index]),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _replaceEntries(List<LogEntry> entries) {
    _entries
      ..clear()
      ..addAll(
        entries.length > _maxEntries
            ? entries.sublist(entries.length - _maxEntries)
            : entries,
      );
  }

  void _addEntry(LogEntry entry) {
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.level) {
      AppLogLevel.error => Colors.red,
      AppLogLevel.warning => Colors.orange,
      AppLogLevel.success => Colors.green,
      AppLogLevel.info => Colors.grey,
      AppLogLevel.debug => Colors.blueGrey,
    };

    return ListTile(
      dense: true,
      leading: Icon(Icons.circle, size: 10, color: color),
      title: Text(entry.message),
      subtitle: Text(
        '${entry.timestamp.toIso8601String()} • ${entry.displayLevel}${entry.source == null ? '' : ' • ${entry.source}'}',
      ),
    );
  }
}
