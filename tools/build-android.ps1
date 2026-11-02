param(
    [string]$BuildRoot = (Join-Path $env:TEMP ('hungry-student-' + [guid]::NewGuid().ToString('N'))),
    [string[]]$FlutterArguments = @()
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$resolvedBuildRoot = [IO.Path]::GetFullPath($BuildRoot)
if ($resolvedBuildRoot -match '[^\x00-\x7F]') { throw 'Use an ASCII-only BuildRoot path.' }
if (Test-Path -LiteralPath $resolvedBuildRoot) { throw 'BuildRoot must be a new directory to preserve existing files.' }
if ($resolvedBuildRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'BuildRoot must be outside the source project.'
}
New-Item -ItemType Directory -Path $resolvedBuildRoot | Out-Null
# Copy only; no /MIR or deletion. Keep the requested original directory intact.
& robocopy $projectRoot $resolvedBuildRoot /E /XD .git .dart_tool .gradle build node_modules .idea /XF *.iml /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) { throw 'Could not copy the project.' }
Push-Location -LiteralPath $resolvedBuildRoot
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
    & flutter build apk --debug @FlutterArguments
    if ($LASTEXITCODE -ne 0) { throw "Build failed. See the working copy: $resolvedBuildRoot" }
    $apk = Join-Path $resolvedBuildRoot 'build/app/outputs/flutter-apk/app-debug.apk'
    $output = Join-Path $projectRoot 'output/android'
    New-Item -ItemType Directory -Force -Path $output | Out-Null
    Copy-Item -LiteralPath $apk -Destination (Join-Path $output 'app-debug.apk')
    Write-Output "APK: $(Join-Path $output 'app-debug.apk')"
    Write-Output "ASCII working copy: $resolvedBuildRoot"
} finally { Pop-Location }
