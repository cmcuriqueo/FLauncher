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

import 'dart:async';

import 'package:flauncher/database.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/focused_app_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/ticker_model.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/color_helpers.dart';
import 'package:flauncher/widgets/focus_keyboard_listener.dart';
import 'package:flauncher/tv_theme.dart';
import 'package:flauncher/widgets/glass.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _validationKeys = [LogicalKeyboardKey.select, LogicalKeyboardKey.enter, LogicalKeyboardKey.gameButtonA];

class AppCard extends StatefulWidget {
  final Category category;
  final App application;
  final bool autofocus;
  final void Function(AxisDirection) onMove;
  final VoidCallback onMoveEnd;

  AppCard({
    Key? key,
    required this.category,
    required this.application,
    required this.autofocus,
    required this.onMove,
    required this.onMoveEnd,
  }) : super(key: key);

  @override
  _AppCardState createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  bool _moving = false;
  MemoryImage? _imageProvider;
  late final AnimationController _animation = AnimationController(
    vsync: Provider.of<TickerModel>(context, listen: false).tickerProvider ?? this,
    duration: Duration(
      milliseconds: 800,
    ),
  );
  Color _lastBorderColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _animation.addStatusListener((animationStatus) {
      switch (animationStatus) {
        case AnimationStatus.completed:
          _animation.reverse();
          break;
        case AnimationStatus.dismissed:
          _animation.forward();
          break;
        case AnimationStatus.forward:
        case AnimationStatus.reverse:
          // nothing to do
          break;
      }
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  ImageProvider _cachedMemoryImage(Uint8List bytes) {
    if (!listEquals(bytes, _imageProvider?.bytes)) {
      _imageProvider = MemoryImage(bytes);
    }
    return _imageProvider!;
  }

  @override
  Widget build(BuildContext context) => FocusKeyboardListener(
        onPressed: (key) => _onPressed(context, key),
        onLongPress: (key) => _onLongPress(context, key),
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          if (focused) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<FocusedAppService>().setFocusedApp(widget.application);
              }
            });
          }
          return AspectRatio(
            aspectRatio: TvTokens.heroAspectRatio,
            child: AnimatedContainer(
              duration: TvTokens.focusDuration,
              curve: TvTokens.focusCurve,
              transformAlignment: Alignment.center,
              transform: _scaleTransform(focused),
              decoration: BoxDecoration(
                borderRadius: _borderRadius,
                boxShadow: focused ? TvTokens.focusShadow : TvTokens.restShadow,
              ),
              child: Material(
                color: Glass.fill(0.10),
                borderRadius: _borderRadius,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    InkWell(
                      autofocus: widget.autofocus,
                      focusColor: Colors.transparent,
                      onTap: () => _onPressed(context, null),
                      onLongPress: () => _onLongPress(context, null),
                      child: widget.application.banner != null
                          ? Ink.image(image: _cachedMemoryImage(widget.application.banner!), fit: BoxFit.cover)
                          : Padding(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Ink.image(
                                      image: _cachedMemoryImage(widget.application.icon!),
                                      height: double.infinity,
                                    ),
                                  ),
                                  Flexible(
                                    flex: 3,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        widget.application.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (_moving) ..._arrows(),
                    IgnorePointer(
                      child: AnimatedOpacity(
                        duration: TvTokens.focusDuration,
                        curve: TvTokens.focusCurve,
                        opacity: focused ? 0 : 0.14,
                        child: Container(color: Colors.black),
                      ),
                    ),
                    SpecularHighlight(
                      borderRadius: _borderRadius,
                      opacity: focused ? 1 : 0.5,
                      duration: TvTokens.focusDuration,
                    ),
                    _focusRing(focused),
                  ],
                ),
              ),
            ),
          );
        },
      );

  static final BorderRadius _borderRadius = TvTokens.cardBorderRadius;

  Widget _focusRing(bool focused) => Selector<SettingsService, bool>(
        selector: (_, settingsService) => settingsService.appHighlightAnimationEnabled,
        builder: (context, appHighlightAnimationEnabled, __) {
          if (appHighlightAnimationEnabled && focused) {
            _animation.forward();
            return AnimatedBuilder(
              animation: _animation,
              builder: (context, child) =>
                  _ring(focused, _lastBorderColor = computeBorderColor(_animation.value, _lastBorderColor)),
            );
          }
          _animation.stop();
          return _ring(focused, Colors.white);
        },
      );

  Widget _ring(bool focused, Color color) => IgnorePointer(
        child: AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          decoration: BoxDecoration(
            borderRadius: _borderRadius,
            border: Border.all(
              color: focused ? color.withOpacity(0.95) : Glass.stroke(0.12),
              width: focused ? TvTokens.focusStrokeWidth : 1,
            ),
          ),
        ),
      );

  Matrix4 _scaleTransform(bool focused) => TvTokens.focusTransform(!_moving && focused);

  List<Widget> _arrows() => [
        _arrow(Alignment.centerLeft, Icons.keyboard_arrow_left),
        _arrow(Alignment.topCenter, Icons.keyboard_arrow_up),
        _arrow(Alignment.bottomCenter, Icons.keyboard_arrow_down),
        _arrow(Alignment.centerRight, Icons.keyboard_arrow_right),
      ];

  Widget _arrow(Alignment alignment, IconData icon) => Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.55),
              border: Border.all(color: Glass.stroke(0.4)),
            ),
            child: Icon(
              icon,
              size: 16,
            ),
          ),
        ),
      );

  KeyEventResult _onPressed(BuildContext context, LogicalKeyboardKey? key) {
    if (_moving) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Scrollable.ensureVisible(context,
          alignment: 0.1, duration: TvTokens.scrollDuration, curve: TvTokens.scrollCurve));
      if (key == LogicalKeyboardKey.arrowLeft) {
        widget.onMove(AxisDirection.left);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        widget.onMove(AxisDirection.up);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        widget.onMove(AxisDirection.right);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        widget.onMove(AxisDirection.down);
      } else if (_validationKeys.contains(key)) {
        setState(() => _moving = false);
        widget.onMoveEnd();
      }
      return KeyEventResult.handled;
    } else if (_validationKeys.contains(key)) {
      context.read<AppsService>().launchApp(widget.application);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onLongPress(BuildContext context, LogicalKeyboardKey? key) {
    if (!_moving && (key == null || longPressableKeys.contains(key))) {
      _showPanel(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _showPanel(BuildContext context) async {
    final result = await showDialog<ApplicationInfoPanelResult>(
      context: context,
      builder: (context) => ApplicationInfoPanel(
        category: widget.category,
        application: widget.application,
      ),
    );
    if (result == ApplicationInfoPanelResult.reorderApp) {
      setState(() => _moving = true);
    }
  }
}
