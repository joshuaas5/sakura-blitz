param(
    [string]$Godot = (Join-Path $PSScriptRoot '../../tools/godot/Godot_v4.7.2-stable_win64_console.exe'),
    [string]$AndroidSdk = 'C:/android-sdk'
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$artifactDir = Join-Path $projectRoot 'export/android'
$apkPath = Join-Path $artifactDir 'SakuraBlitz-0.7.1-test.apk'
New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
if (-not (Test-Path -LiteralPath $Godot)) { throw "Godot not found: $Godot" }
$buildTools = Get-ChildItem -LiteralPath (Join-Path $AndroidSdk 'build-tools') -Directory |
    Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
if (-not $buildTools) { throw 'Android build-tools were not found.' }
# Uses the local Godot debug keystore. No publishing/release credentials are read.
& $Godot --headless --path $projectRoot --export-debug 'Android Test APK' $apkPath *> (Join-Path $artifactDir 'build.log')
if ($LASTEXITCODE -ne 0) { throw 'APK export failed. See export/android/build.log.' }
if (Select-String -LiteralPath (Join-Path $artifactDir 'build.log') -Pattern 'SCRIPT ERROR:|Parse Error:' -Quiet) {
    throw 'APK export reported a script error. See export/android/build.log.'
}
$signer = Join-Path $buildTools.FullName 'apksigner.bat'
& $signer verify --verbose $apkPath *> (Join-Path $artifactDir 'signature-verification.txt')
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
& (Join-Path $buildTools.FullName 'zipalign.exe') -c -P 16 -v 4 $apkPath *> (Join-Path $artifactDir 'alignment-verification.txt')
if ($LASTEXITCODE -ne 0) { throw 'APK alignment verification failed.' }
& (Join-Path $buildTools.FullName 'aapt.exe') dump badging $apkPath *> (Join-Path $artifactDir 'package-info.txt')
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect APK manifest.' }
$apkHash = Get-FileHash -LiteralPath $apkPath -Algorithm SHA256
($apkHash.Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetFileName($apkPath)) |
    Set-Content -LiteralPath (Join-Path $artifactDir 'SHA256SUMS.txt') -Encoding ascii
Get-Item -LiteralPath $apkPath | Select-Object FullName, Length, LastWriteTime
Get-Content -LiteralPath (Join-Path $artifactDir 'signature-verification.txt')
