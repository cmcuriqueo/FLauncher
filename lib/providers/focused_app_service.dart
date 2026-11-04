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

import 'package:flauncher/database.dart';
import 'package:flutter/foundation.dart';

/// Tracks the app currently focused on the home screen so the contextual hero
/// can display its banner and metadata.
class FocusedAppService extends ChangeNotifier {
  App? _focusedApp;

  App? get focusedApp => _focusedApp;

  void setFocusedApp(App app) {
    if (_focusedApp?.packageName == app.packageName) {
      return;
    }
    _focusedApp = app;
    notifyListeners();
  }
}
