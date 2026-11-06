# Plan: Galería de wallpapers desde repo git

Fecha: 2026-11-06 10:10
Rama: `feat/wallpaper-repo` (desde `master`)

## Objetivo
Agregar una fuente de wallpapers online sin API key: un repo git propio
(`cmcuriqueo/flauncher-wallpapers`) que sirve un `manifest.json` + imágenes
vía `raw.githubusercontent.com`.

## Diseño
- `lib/wallpaper_repo_service.dart` (clase plana, `http.Client` inyectable):
  - `fetchWallpapers()`: GET del manifest, parsea a `List<RepoWallpaper>`.
  - `downloadWallpaper(wallpaper)`: GET de la imagen → bytes.
- `lib/widgets/settings/repo_wallpaper_panel_page.dart`:
  - StatefulWidget, `FutureBuilder` con grilla 2-col estilo panel local.
  - Estado de error (ícono + mensaje l10n) y loading.
  - `Image.network` con `errorBuilder` (fallback, y evita excepciones en tests).
  - Al seleccionar: descarga bytes → `WallpaperService.setLocalWallpaper`.
- Ruta registrada en `settings_panel.dart`; botón "Online gallery" (ícono nube)
  en `wallpaper_panel_page.dart`, debajo de "Local".
- l10n: `wallpaperRepo`, `wallpaperRepoError` (en/es).
- Test: `test/widgets/settings/repo_wallpaper_panel_page_test.dart` con
  `_FakeWallpaperRepoService` (sin red) + `MockWallpaperService`.

## Pasos
- [x] 1. Rama `feat/wallpaper-repo`.
- [x] 2. `WallpaperRepoService` + modelo `RepoWallpaper`.
- [x] 3. Panel + ruta + botón + l10n.
- [x] 4. Test del panel.
- [x] 5. `flutter analyze` + format 120 + suite (67 ok, 60 fallos preexistentes).
- [x] 6. README + commit, push, PR.

## Riesgos / notas
- El repo ya existe: https://github.com/cmcuriqueo/flauncher-wallpapers
  (10 wallpapers, 328 KB, manifest v1).
- No se tocó `WallpaperService`: se reusa `setLocalWallpaper(bytes)`.
- Agregar wallpapers = pushear imagen + entrada al manifest del repo.
