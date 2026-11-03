import 'package:flauncher/tv_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("palette matches the design guide", () {
    expect(TvTokens.bgDark, Color(0xFF0F1216));
    expect(TvTokens.bgCardDefault, Color(0xFF1A1E24));
    expect(TvTokens.bgCardFocus, Color(0xFFFFFFFF));
    expect(TvTokens.textPrimary, Color(0xFFF1F3F5));
    expect(TvTokens.textSecondary, Color(0xFF9E9E9E));
    expect(TvTokens.textFocus, Color(0xFF000000));
    expect(TvTokens.focusStroke, Color(0xFF3D82F6));
  });

  test("geometry tokens", () {
    expect(TvTokens.radiusCard, 12);
    expect(TvTokens.focusScale, 1.10);
    expect(TvTokens.overscanHorizontal, greaterThanOrEqualTo(48));
    expect(TvTokens.overscanVertical, greaterThanOrEqualTo(27));
    expect(TvTokens.favoriteIconSize, 80);
    expect(TvTokens.heroAspectRatio, 16 / 9);
  });

  test("focus animation stays within 150-200ms and decelerates", () {
    expect(TvTokens.focusDuration.inMilliseconds, greaterThanOrEqualTo(150));
    expect(TvTokens.focusDuration.inMilliseconds, lessThanOrEqualTo(200));
    expect(TvTokens.focusCurve, Curves.decelerate);
  });

  test("focusTransform scales only on focus", () {
    expect(TvTokens.focusTransform(false), Matrix4.identity());
    expect(TvTokens.focusTransform(true).entry(0, 0), 1.10);
    expect(TvTokens.focusTransform(true).entry(1, 1), 1.10);
    expect(TvTokens.focusTransform(true).entry(2, 2), 1.0);
  });

  test("cardDecoration switches surface, stroke and shadow between states", () {
    final resting = TvTokens.cardDecoration(false);
    final focused = TvTokens.cardDecoration(true);

    expect(resting.color, TvTokens.bgCardDefault);
    expect(focused.color, TvTokens.bgCardFocus);
    expect((focused.border as Border).top.color, TvTokens.focusStroke);
    expect((focused.border as Border).top.width, TvTokens.focusStrokeWidth);
    expect(focused.boxShadow, isNot(equals(resting.boxShadow)));
  });
}
