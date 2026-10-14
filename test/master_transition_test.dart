import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/core/theme/app_theme.dart';
import 'package:mineral/features/master/screens/master_shell.dart';
import 'package:mineral/features/reports/screens/reports_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';

import 'helpers/backend_api_fixture.dart';

void main() {
  for (final width in [390.0, 1400.0]) {
    testWidgets('rapid master tab switches remain stable at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = testApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MasterShell(api: api),
        ),
      );
      await tester.pumpAndSettle();
      for (final index in [2, 0, 2, 3, 4, 1, 4, 2]) {
        if (width < 1000) {
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .onDestinationSelected!(index);
        } else {
          await tester.tap(find.byType(ListTile).at(index));
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
