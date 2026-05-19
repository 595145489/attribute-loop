param(
    [string]$TestDir = "res://tests/unit/"
)

$godotExe = $env:GODOT_EXE
if ([string]::IsNullOrWhiteSpace($godotExe)) {
    Write-Error "GODOT_EXE environment variable not set. Check .claude/settings.json."
    exit 1
}

$projectPath = Split-Path -Parent $PSScriptRoot

Write-Host "Running GUT unit tests..."

# Run GUT headlessly with explicit test directory
$gutArgs = @(
    "--headless",
    "--path", $projectPath,
    "-s", "res://addons/gut/gut_cmdln.gd",
    "-gdir=$TestDir",
    "-gexit"
)

$output = @()
& $godotExe @gutArgs 2>&1 | ForEach-Object {
    $output += $_
    Write-Host $_
}

# Parse test results from console output
# GUT 9.6.0 prints results like:
# ---- All tests passed! ----
# or includes test counts in summary

$outputStr = $output -join "`n"

# Check for all tests passed
if ($outputStr -match "All tests passed") {
    # Try to extract test count from summary
    if ($outputStr -match "Tests\s+(\d+)") {
        $totalTests = [int]$matches[1]
        Write-Host "`nResults: $totalTests/$totalTests passed"
    }
    Write-Host "All tests passed."
    exit 0
}

# Check for test failures in output
if ($outputStr -match "(\d+)/(\d+) passed" -or $outputStr -match "Failing Tests\s+(\d+)") {
    Write-Error "Self-test FAILED: Tests did not all pass"
    exit 1
}

# If no tests were found, that's OK for now
if ($outputStr -match "No tests found") {
    Write-Host "No tests found in $TestDir — pass"
    exit 0
}

# Unknown output: fail safe — require an explicit "All tests passed" signal
Write-Error "Self-test FAILED: Could not confirm all tests passed. GUT output did not match any known pattern."
exit 1
