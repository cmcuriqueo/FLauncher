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

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:flauncher/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v2.dart' as v2;
import 'generated_migrations/schema_v3.dart' as v3;
import 'generated_migrations/schema_v4.dart' as v4;
import 'generated_migrations/schema_v5.dart' as v5;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  RawValuesInsertable appRow({bool includeClassName = false}) => RawValuesInsertable({
        "package_name": Variable("me.efesser.flauncher"),
        "name": Variable("FLauncher"),
        if (includeClassName) "class_name": Variable(".MainActivity"),
        "version": Variable("0.0.1"),
        "icon": Variable(Uint8List.fromList([0x01])),
        "banner": Variable(Uint8List.fromList([0x02])),
      });

  Future<void> verifyMigratedData(QueryExecutor executor) async {
    final db = v5.DatabaseAtV5(executor);
    final app = await db.customSelect("SELECT * FROM apps").getSingle();
    final category = await db.customSelect("SELECT * FROM categories").getSingle();
    final appsCategory = await db.customSelect("SELECT * FROM apps_categories").getSingle();

    expect(app.read<String>("package_name"), "me.efesser.flauncher");
    expect(app.read<String>("name"), "FLauncher");
    expect(app.read<String>("version"), "0.0.1");
    expect(app.read<Uint8List>("icon"), Uint8List.fromList([0x01]));
    expect(app.read<Uint8List>("banner"), Uint8List.fromList([0x02]));
    expect(app.read<bool>("hidden"), false);
    expect(app.read<bool>("sideloaded"), false);
    expect(category.read<int>("id"), 1);
    expect(category.read<String>("name"), "Applications");
    expect(category.read<int>("order"), 0);
    expect(category.read<int>("sort"), 0);
    expect(category.read<int>("type"), 1);
    expect(category.read<int>("columns_count"), 6);
    expect(category.read<int>("row_height"), 110);
    expect(appsCategory.read<String>("app_package_name"), "me.efesser.flauncher");
    expect(appsCategory.read<int>("category_id"), 1);
    expect(appsCategory.read<int>("order"), 0);
    await db.close();
  }

  test("upgrade from v1 to v6", () async {
    final schema = await verifier.schemaAt(1);

    final oldDb = v1.DatabaseAtV1(schema.newConnection().executor);
    await oldDb.into(oldDb.apps).insert(appRow(includeClassName: true));
    final categoryId = await oldDb
        .into(oldDb.categories)
        .insert(RawValuesInsertable({"name": Variable("Applications"), "order": Variable(0)}));
    await oldDb.into(oldDb.appsCategories).insert(RawValuesInsertable({
          "category_id": Variable(categoryId),
          "app_package_name": Variable("me.efesser.flauncher"),
          "order": Variable(0),
        }));
    await oldDb.close();

    final db = FLauncherDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    await db.close();

    await verifyMigratedData(schema.newConnection().executor);
  });

  test("upgrade from v2 to v6", () async {
    final schema = await verifier.schemaAt(2);

    final oldDb = v2.DatabaseAtV2(schema.newConnection().executor);
    await oldDb.into(oldDb.apps).insert(appRow());
    final categoryId = await oldDb
        .into(oldDb.categories)
        .insert(RawValuesInsertable({"name": Variable("Applications"), "order": Variable(0)}));
    await oldDb.into(oldDb.appsCategories).insert(RawValuesInsertable({
          "category_id": Variable(categoryId),
          "app_package_name": Variable("me.efesser.flauncher"),
          "order": Variable(0),
        }));
    await oldDb.close();

    final db = FLauncherDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    await db.close();

    await verifyMigratedData(schema.newConnection().executor);
  });

  test("upgrade from v3 to v6", () async {
    final schema = await verifier.schemaAt(3);

    final oldDb = v3.DatabaseAtV3(schema.newConnection().executor);
    await oldDb.into(oldDb.apps).insert(appRow());
    final categoryId = await oldDb
        .into(oldDb.categories)
        .insert(RawValuesInsertable({"name": Variable("Applications"), "order": Variable(0)}));
    await oldDb.into(oldDb.appsCategories).insert(RawValuesInsertable({
          "category_id": Variable(categoryId),
          "app_package_name": Variable("me.efesser.flauncher"),
          "order": Variable(0),
        }));
    await oldDb.close();

    final db = FLauncherDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    await db.close();

    await verifyMigratedData(schema.newConnection().executor);
  });

  test("upgrade from v4 to v6", () async {
    final schema = await verifier.schemaAt(4);

    final oldDb = v4.DatabaseAtV4(schema.newConnection().executor);
    await oldDb.into(oldDb.apps).insert(appRow());
    final categoryId = await oldDb
        .into(oldDb.categories)
        .insert(RawValuesInsertable({"name": Variable("Applications"), "type": Variable(1), "order": Variable(0)}));
    await oldDb.into(oldDb.appsCategories).insert(RawValuesInsertable({
          "category_id": Variable(categoryId),
          "app_package_name": Variable("me.efesser.flauncher"),
          "order": Variable(0),
        }));
    await oldDb.close();

    final db = FLauncherDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    await db.close();

    await verifyMigratedData(schema.newConnection().executor);
  });

  test("upgrade from v5 to v6", () async {
    final schema = await verifier.schemaAt(5);

    final oldDb = v5.DatabaseAtV5(schema.newConnection().executor);
    await oldDb.into(oldDb.apps).insert(appRow());
    await oldDb.close();

    final db = FLauncherDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    await db.close();

    final migratedDb = v5.DatabaseAtV5(schema.newConnection().executor);
    final app = await migratedDb.customSelect("SELECT * FROM apps").getSingle();
    expect(app.read<String>("package_name"), "me.efesser.flauncher");
    expect(app.read<bool>("favorite"), false);
    await migratedDb.close();
  });
}
