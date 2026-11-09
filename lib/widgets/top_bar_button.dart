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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TopBarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  TopBarButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<TopBarButton> createState() => _TopBarButtonState();
}

class _TopBarButtonState extends State<TopBarButton> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: focused ? Colors.white.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: focused ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: Focus(
        canRequestFocus: false,
        onKey: (_, event) => _onKey(_focusNode, event),
        child: IconButton(
          focusNode: _focusNode,
          tooltip: widget.tooltip,
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(minWidth: 48, minHeight: 48),
          splashRadius: 24,
          icon: Icon(widget.icon),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
