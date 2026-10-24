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

import 'package:flauncher/actions.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/material.dart';

class RightPanelDialog extends StatelessWidget {
  final Widget child;
  final double width;

  RightPanelDialog({
    required this.child,
    this.width = 250,
  });

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(),
        insetPadding: EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerRight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Glass.radiusLarge),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 40, offset: Offset(0, 16))],
            ),
            child: GlassContainer(
              radius: Glass.radiusLarge,
              blur: 36,
              opacity: 0.08,
              padding: EdgeInsets.all(20),
              width: width,
              height: double.infinity,
              child: Actions(actions: {BackIntent: BackAction(context)}, child: child),
            ),
          ),
        ),
      );
}
