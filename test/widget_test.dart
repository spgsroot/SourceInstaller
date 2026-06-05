import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:source_installer/main.dart';

void main() {
  testWidgets('SourceInstaller shell smoke test in English', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp(locale: Locale('en'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('SourceInstaller'), findsOneWidget);
    expect(find.text('Analyze'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('Resource URL'), findsOneWidget);
    expect(find.text('Start analysis'), findsOneWidget);
    expect(find.text('Bulk download limit'), findsOneWidget);
    expect(find.text('No limit'), findsOneWidget);
  });

  testWidgets('SourceInstaller shell smoke test in Russian', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp(locale: Locale('ru'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('SourceInstaller'), findsOneWidget);
    expect(find.text('Анализ'), findsOneWidget);
    expect(find.text('Задачи'), findsOneWidget);
    expect(find.text('Лог'), findsOneWidget);
    expect(find.text('URL ресурса'), findsOneWidget);
    expect(find.text('Начать анализ'), findsOneWidget);
    expect(find.text('Лимит массовой загрузки'), findsOneWidget);
    expect(find.text('Без лимита'), findsOneWidget);
  });
}
