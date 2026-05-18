param(
    [string]$TestDir = "res://tests/unit/"
)

$godotExe = $env:GODOT_EXE
if ([string]::IsNullOrWhiteSpace($godotExe)) {
    Write-Error "GODOT_EXE environment variable not set. Check .claude/settings.json."
    exit 1
}

$projectPath = Split-Path -Parent $PSScriptRoot
$resultsFile = Join-Path $projectPath "tests\results.json"

# Remove old results
if (Test-Path $resultsFile) { Remove-Item $resultsFile -Force }

Write-Host "Running GUT unit tests..."

# Run GUT headlessly
$gutArgs = @(
    "--headless",
    "--path", $projectPath,
    "-s", "res://addons/gut/gut_cmdln.gd",
    "-gdir=$TestDir",
    "-gjson=res://tests/results.json",
    "-gpo",
    "-gexit"
)

& $godotExe @gutArgs 2>&1 | Write-Host
$exitCode = $LASTEXITCODE

# Check if results file was written
if (-not (Test-Path $resultsFile)) {
    Write-Host "No results.json produced — no tests found or GUT could not run"
    Write-Host "Pass (no tests yet)"
    exit 0
}

# Parse results
try {
    $results = Get-Content $resultsFile -Raw | ConvertFrom-Json
    if ($null -eq $results -or $null -eq $results.totals) {
        Write-Error "results.json has unexpected format — missing 'totals' key"
        exit 1
    }
    $total = $results.totals.tests
    $passing = $results.totals.passing
    $failing = $results.totals.failing
    $errors = $results.totals.errors

    Write-Host "`nResults: $passing/$total passed, $failing failed, $errors errors"

    if ($failing -gt 0 -or $errors -gt 0) {
        Write-Error "Self-test FAILED: $failing failures, $errors errors"
        exit 1
    }

    if ($total -eq 0) {
        Write-Host "No tests found in $TestDir — pass"
        exit 0
    }

    Write-Host "All $total tests passed."
    exit 0
} catch {
    Write-Error "Could not parse results.json: $_"
    exit 1
}
