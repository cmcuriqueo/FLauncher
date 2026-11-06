# Plan: Liquid glass polish (highlight especular + glow de foco)

Fecha: 2026-11-06 09:39
Rama: `feat/liquid-glass-polish` (desde `master`)

## Objetivo
Segunda iteración del rediseño glassmorphism ("liquid glass", estilo iOS 26):
dar a las cards un brillo especular superior y un foco con halo luminoso,
y terminar de pulir strings hardcodeados del panel de info de app.

## Diseño
- `glass.dart`: nuevo widget `SpecularHighlight` (IgnorePointer): gradiente
  blanco vertical muy sutil en el borde superior, con opacidad animable.
  Pensado para apilarse en el `Stack` de las cards sin costar BackdropFilter
  (los cards son muchos; el blur real se reserva para paneles únicos).
- `AppCard`:
  - Reemplaza el gradiente superior fijo por `SpecularHighlight` animado
    (más visible al enfocar).
  - Sombra de foco con halo blanco/accent (ya existe via TvTokens.focusShadow).
- `FavoriteAppCard`: agrega `SpecularHighlight` + overlay de atenuación cuando
  no está enfocado, para igualar el lenguaje visual de `AppCard`.
- `ContextualHero`: agrega `SpecularHighlight` y sombra de reposo.
- `ApplicationInfoPanel`: strings "Add/Remove from favorites", "Force stop" y
  snackbar pasan a l10n (`app_en.arb`, `app_es.arb`).

## Pasos
- [x] 1. Rama `feat/liquid-glass-polish`.
- [x] 2. `SpecularHighlight` en `glass.dart`.
- [x] 3. Aplicar en `AppCard`, `FavoriteAppCard`, `ContextualHero`.
- [x] 4. Keys l10n: `addToFavorites`, `removeFromFavorites`, `forceStop`,
  `forceStopped` (en + es) y regen.
- [x] 5. `flutter analyze` + format 120 + tests.
- [ ] 6. README + commit, push, PR.

## Riesgos / notas
- No usar BackdropFilter por card: en TV hardware el costo es alto; el efecto
  se logra con gradientes y sombras.
- No tocar `TvTokens.focusCurve` (cubierto por `test/tv_theme_test.dart`).
