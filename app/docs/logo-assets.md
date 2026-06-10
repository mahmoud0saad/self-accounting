# Logo assets — how to update Raqeeb branding

This app uses two logo files:

| File | Used for |
|------|----------|
| `assets/logo.svg` | In-app UI (sign-in, sign-up via `AppLogo`) |
| `assets/logo.png` | Launcher icon, splash screen, Play Store hi-res icon |

When you change `logo.svg`, regenerate `logo.png` and the native icons.

---

## Quick workflow (after editing `logo.svg`)

From the `app` folder:

```powershell
# 1) Regenerate logo.png (Windows PowerShell)
.\scripts\regenerate-logo.ps1

# 2) Regenerate launcher icons
dart run flutter_launcher_icons

# 3) Regenerate splash (optional — needs flutter_native_splash temporarily)
flutter pub add --dev flutter_native_splash
dart run flutter_native_splash:create
flutter pub remove flutter_native_splash
```

Then reinstall or rebuild the app to see changes on the home screen:

```bash
flutter run
# or for Play Store:
flutter build appbundle --release
```

---

## Step 1 — Regenerate `logo.png`

Our `logo.svg` embeds a PNG inside the SVG (`data:image/png;base64,...`). The script extracts that image, centers it on a white 1024×1024 canvas, and saves `assets/logo.png`.

### Option A — PowerShell script (recommended on Windows)

Run from the `app` directory:

```powershell
.\scripts\regenerate-logo.ps1
```

### Option B — Manual PowerShell (one-liner)

```powershell
$svg = Get-Content "assets\logo.svg" -Raw
if ($svg -match 'href="data:image/png;base64,([^"]+)"') {
  $bytes = [Convert]::FromBase64String($matches[1])
  $raw = "assets\logo_embedded.png"
  [IO.File]::WriteAllBytes($raw, $bytes)
  Add-Type -AssemblyName System.Drawing
  $src = [System.Drawing.Image]::FromFile($raw)
  $size = 1024
  $canvas = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($canvas)
  $g.Clear([System.Drawing.Color]::White)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $scale = [Math]::Min($size / $src.Width, $size / $src.Height) * 0.85
  $newW = [int]($src.Width * $scale)
  $newH = [int]($src.Height * $scale)
  $g.DrawImage($src, ($size - $newW) / 2, ($size - $newH) / 2, $newW, $newH)
  $canvas.Save("assets\logo.png", [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $canvas.Dispose(); $src.Dispose()
  Remove-Item $raw
  Write-Host "Created assets\logo.png"
}
```

### Option C — External tools

If your SVG is a normal vector file (no embedded PNG), export manually:

- **Figma / Illustrator / Inkscape** → Export PNG at **1024×1024**, white background, logo centered with ~15% padding.
- Save as `assets/logo.png`.

---

## Step 2 — Regenerate launcher icons

Config lives in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/logo.png
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: assets/logo.png
```

Run:

```bash
dart run flutter_launcher_icons
```

This updates:

- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Android adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

---

## Step 3 — Regenerate splash screen (optional)

Splash config is also in `pubspec.yaml` under `flutter_native_splash`.

`flutter_native_splash` is a **dev-only** generator. Add it, run create, then remove it so release builds do not fail:

```bash
flutter pub add --dev flutter_native_splash
dart run flutter_native_splash:create
flutter pub remove flutter_native_splash
flutter pub get
```

This updates Android `launch_background.xml`, iOS `LaunchImage`, and web splash assets.

---

## What updates automatically

- **Sign-in / sign-up screens** use `assets/logo.svg` directly — no extra step after editing the SVG (hot restart is enough).

---

## Play Store hi-res icon

Google Play Console asks for a **512×512 PNG**. Use the generated `assets/logo.png` (1024×1024) — upload it as-is or resize to 512×512 in any image editor.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Script says "No embedded PNG found" | Your SVG may be pure vector; export PNG manually (Option C). |
| Home screen icon unchanged | Uninstall the app, then `flutter run` or rebuild release. |
| Release build fails on `flutter_native_splash` | Remove the package after `dart run flutter_native_splash:create` and run `flutter pub get`. |
| iOS App Store rejects icon | Add `remove_alpha_ios: true` under `flutter_launcher_icons` in `pubspec.yaml`, then rerun `dart run flutter_launcher_icons`. |
