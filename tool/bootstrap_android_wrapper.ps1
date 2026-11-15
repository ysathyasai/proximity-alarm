$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$TempProject = Join-Path $Root '.wrapper_bootstrap'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter was not found on PATH. Install Flutter and run flutter doctor first.'
}
if (Test-Path $TempProject) {
    Remove-Item $TempProject -Recurse -Force
}
flutter create --platforms=android --project-name proximity_alarm --org com.example $TempProject
if ($LASTEXITCODE -ne 0) { throw 'flutter create failed while generating Gradle wrapper files.' }

$SourceAndroid = Join-Path $TempProject 'android'
$TargetAndroid = Join-Path $Root 'android'
Copy-Item (Join-Path $SourceAndroid 'gradlew') (Join-Path $TargetAndroid 'gradlew') -Force
Copy-Item (Join-Path $SourceAndroid 'gradlew.bat') (Join-Path $TargetAndroid 'gradlew.bat') -Force
$TargetWrapper = Join-Path $TargetAndroid 'gradle\wrapper'
New-Item -ItemType Directory -Path $TargetWrapper -Force | Out-Null
Copy-Item (Join-Path $SourceAndroid 'gradle\wrapper\gradle-wrapper.jar') (Join-Path $TargetWrapper 'gradle-wrapper.jar') -Force
Remove-Item $TempProject -Recurse -Force
Write-Host 'Gradle wrapper files copied. Next run: flutter pub get; flutter analyze; flutter test; flutter run' -ForegroundColor Green
