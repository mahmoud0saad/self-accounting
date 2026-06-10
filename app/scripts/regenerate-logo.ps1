# Regenerates assets/logo.png from assets/logo.svg
# Run from the app folder: .\scripts\regenerate-logo.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$svgPath = Join-Path $root "assets\logo.svg"
$outPath = Join-Path $root "assets\logo.png"
$rawPath = Join-Path $root "assets\logo_embedded.png"

if (-not (Test-Path $svgPath)) {
    Write-Error "Missing $svgPath"
}

$svg = Get-Content $svgPath -Raw
if ($svg -notmatch 'href="data:image/png;base64,([^"]+)"') {
    Write-Error "No embedded PNG found in logo.svg. Export logo.png manually (see docs/logo-assets.md)."
}

$bytes = [Convert]::FromBase64String($matches[1])
[IO.File]::WriteAllBytes($rawPath, $bytes)

Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile($rawPath)
try {
    $size = 1024
    $canvas = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($canvas)
    $g.Clear([System.Drawing.Color]::White)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $scale = [Math]::Min($size / $src.Width, $size / $src.Height) * 0.75
    $newW = [int]($src.Width * $scale)
    $newH = [int]($src.Height * $scale)
    $x = ($size - $newW) / 2
    $y = ($size - $newH) / 2
    $g.DrawImage($src, $x, $y, $newW, $newH)
    $canvas.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $canvas.Dispose()
    Write-Host "Created $outPath ($newW x $newH on ${size}x${size} canvas)"
}
finally {
    $src.Dispose()
    if (Test-Path $rawPath) { Remove-Item $rawPath }
}
