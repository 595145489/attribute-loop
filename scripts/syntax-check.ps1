# Read hook event from stdin
$inputJson = $input | Out-String
if ([string]::IsNullOrWhiteSpace($inputJson)) { exit 0 }

try {
    $event = $inputJson | ConvertFrom-Json
} catch {
    exit 0
}

# Extract file path from tool input
$filePath = $event.tool_input.file_path
if ([string]::IsNullOrWhiteSpace($filePath)) { exit 0 }

# Only check .gd files
if (-not $filePath.EndsWith(".gd")) { exit 0 }

# Resolve to absolute path
$absPath = $filePath
if (-not [System.IO.Path]::IsPathRooted($absPath)) {
    $absPath = Join-Path (Get-Location) $filePath
}

# Verify file exists
if (-not (Test-Path $absPath)) { exit 0 }

# Run syntax check
$godotExe = $env:GODOT_EXE
if ([string]::IsNullOrWhiteSpace($godotExe)) {
    Write-Error "GODOT_EXE environment variable not set"
    exit 1
}

$result = & $godotExe --headless --check-only $absPath 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Error "GDScript syntax error in $filePath :`n$result"
    exit 1
}

exit 0
