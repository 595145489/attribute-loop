# One-click Godot Web export.
# Usage: powershell -File scripts/export_web.ps1
# Prerequisites: Godot 4 in PATH; Web export templates installed in editor.

param (
    [switch]$Release
)

$projectPath = Resolve-Path (Join-Path $PSScriptRoot "..")
$outputDir  = Join-Path $projectPath "exports/web"
$outputFile = Join-Path $outputDir "index.html"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$mode = if ($Release) { "--export-release" } else { "--export-debug" }
Write-Host "Exporting to $outputFile ($mode)..."
godot --headless --path $projectPath $mode "Web" $outputFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Export complete. Files in: $outputDir"
    Write-Host ""
    Write-Host "To deploy to itch.io:"
    Write-Host "  1. Zip the exports/web/ folder"
    Write-Host "  2. Upload on itch.io (Kind = HTML, enable SharedArrayBuffer)"
} else {
    Write-Host "Export FAILED (exit code $LASTEXITCODE). Check that Web templates are installed."
    exit 1
}
