/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/widgets/recent_apps_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("keeps the Spanish title and clear button within a narrow row", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale("es"),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: RecentAppsRow(applications: []),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text("Aplicaciones recientes"), findsOneWidget);

    final rowRect = tester.getRect(find.byType(RecentAppsRow));
    final titleRect = tester.getRect(find.text("Aplicaciones recientes"));
    final clearButtonRect = tester.getRect(find.byKey(Key("clear-recent-apps")));
    expect(titleRect.right, lessThanOrEqualTo(rowRect.right));
    expect(clearButtonRect.right, lessThanOrEqualTo(rowRect.right));
  });
}
