import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/core/theme/app_theme.dart';
import 'package:mineral/features/master/screens/master_shell.dart';
import 'package:mineral/features/orders/screens/orders_screen.dart';
import 'package:mineral/features/orders/models/work_order_api_models.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'helpers/backend_api_fixture.dart';

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('master overview and reports fit $width with live backend data', (
      tester,
    ) async {
      final originalShadows = debugDisableShadows;
      addTearDown(() => debugDisableShadows = originalShadows);
      if (const bool.fromEnvironment('MASTER_UI_PREVIEW')) {
        await tester.runAsync(() async {
          final font = File('C:/Windows/Fonts/segoeui.ttf');
          if (font.existsSync()) {
            await (FontLoader('Ahem')..addFont(
                  Future.value(ByteData.sublistView(font.readAsBytesSync())),
                ))
                .load();
            await (FontLoader('Roboto')..addFont(
                  Future.value(ByteData.sublistView(font.readAsBytesSync())),
                ))
                .load();
          }
          final material = File(
            'C:/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          );
          if (material.existsSync()) {
            await (FontLoader('MaterialIcons')..addFont(
                  Future.value(
                    ByteData.sublistView(material.readAsBytesSync()),
                  ),
                ))
                .load();
          }
          await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
                rootBundle.load(
                  'packages/lucide_icons_flutter/assets/lucide.ttf',
                ),
              ))
              .load();
          debugDisableShadows = false;
        });
      }
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/work-orders/board') {
            return jsonResponse(
              boardJson()
                ..['counters'] = {
                  'issued': 14,
                  'completed': 9,
                  'overdue': 2,
                  'equipmentInDowntime': 1,
                },
            );
          }
          if (request.url.path == '/api/references/executors') {
            return jsonResponse([
              {
                ...executorJson(),
                'fullName':
                    'Test Employee With A Very Long Name For Mobile Layout',
              },
            ]);
          }
          if (request.url.path == '/api/reports/shift') {
            return jsonResponse({
              'issued': 14,
              'completed': 9,
              'overdue': 2,
              'closed': 7,
              'rejected': 1,
              'cancelled': 0,
              'inProgress': 3,
              'load': [
                {
                  'id': 7,
                  'fullName':
                      'Test Employee With A Very Long Name For Mobile Layout',
                  'assigned': 3,
                  'completed': 2,
                  'activeNow': 1,
                },
              ],
              'workload': {'executorsOnShift': 4, 'busy': 3, 'free': 1},
              'downtime': {
                'equipmentInDowntimeNow': 1,
                'orders': 2,
                'minutes': 90,
              },
              'aiSummary': 'Backend summary retained in the report.',
            });
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('master-preview'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme().copyWith(
              appBarTheme: buildAppTheme().appBarTheme.copyWith(
                titleTextStyle: buildAppTheme().appBarTheme.titleTextStyle
                    ?.copyWith(fontFamily: 'Roboto'),
              ),
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MasterShell(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Команда на смене'), findsOneWidget);
      expect(find.text('Рейтинг исполнителей'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _preview(tester, 'overview-${width.toInt()}');
      await tester.tap(find.text('Отчёты'));
      await tester.pumpAndSettle();
      expect(find.text('14'), findsOneWidget);
      final kpiTop = tester
          .getTopLeft(find.byKey(const ValueKey('report-kpi-issued')))
          .dy;
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('report-kpi-completed')))
            .dy,
        kpiTop,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('report-kpi-overdue'))).dy,
        kpiTop,
      );
      expect(
        find.textContaining('Backend summary retained in the report.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _preview(tester, 'reports-${width.toInt()}');
      debugDisableShadows = originalShadows;
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('master order cards fit long names and enlarged text at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final json = orderJson();
      json['description'] =
          'Long repair description with equipment and production area details that must remain readable';
      json['equipment'] = {
        ...json['equipment'] as Map,
        'name': 'Equipment With A Very Long Inventory Name',
      };
      json['assignee'] = {
        ...json['assignee'] as Map,
        'fullName': 'Test Employee With A Very Long Name',
      };
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: const TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ApiOrderCard(
                    order: WorkOrderApiModel.fromJson(json),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Test Employee With A Very Long Name'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('MASTER_UI_PREVIEW')) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('master-preview')),
    );
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory('docs/master-previews').create(recursive: true);
    await File(
      'docs/master-previews/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}
