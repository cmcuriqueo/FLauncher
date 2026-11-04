# Plan: Hero contextual (spec §3, sección destacada)

Fecha: 2026-11-04 13:26
Rama: `feat/contextual-hero` (desde `master`)

## Objetivo
Implementar la sección destacada del spec: "Tarjeta panorámica de gran formato (16:9)
con información contextual o multimedia del elemento resaltado en la fila inferior".

## Diseño
- Nuevo `FocusedAppService` (ChangeNotifier): guarda la `App` actualmente enfocada.
  Se registra como Provider en `FLauncherApp`.
- `AppCard` y `FavoriteAppCard` reportan el foco al service (post-frame, solo cuando
  ganan foco y la app cambia).
- Nuevo widget `ContextualHero` en la home, entre el header y la fila de Favoritos:
  - Altura fija ~200dp, ancho completo, radius `TvTokens.radiusCard`.
  - Muestra banner de la app (o ícono si no hay banner) + nombre + versión,
    con scrim en gradiente para legibilidad.
  - Transición con `AnimatedSwitcher` (fade, `TvTokens.focusDuration`).
  - Si nada está enfocado todavía, muestra placeholder sutil (o nada: ocupa 0).
- IgnorePointer total: el hero no es interactivo, no roba foco D-pad.

## Pasos

- [x] 1. Crear rama `feat/contextual-hero` desde `master`.
- [x] 2. `lib/providers/focused_app_service.dart` + registro en `flauncher_app.dart`.
- [x] 3. Reportar foco desde `AppCard` y `FavoriteAppCard` (post-frame).
- [x] 4. Widget `ContextualHero` + montarlo en `flauncher.dart`.
- [x] 5. `flutter analyze` + format 120.
- [x] 6. README + commit, push, PR: https://github.com/cmcuriqueo/FLauncher/pull/7

## Riesgos / notas
- No notificar durante build: usar `addPostFrameCallback`.
- El hero no debe interferir con la navegación D-pad (IgnorePointer / sin Focus).
