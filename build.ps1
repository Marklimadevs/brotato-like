# build.ps1 — exporta o projeto pro CrazyGames com versionamento automático.
#
# Uso:
#   .\build.ps1 patch    # bump de 0.0.1 para 0.0.2
#   .\build.ps1 minor    # bump de 0.1.5 para 0.2.0
#   .\build.ps1 major    # bump de 0.5.2 para 1.0.0
#   .\build.ps1          # sem bump, rebuilda na versão atual
#
# Output:
#   Builds/Web/CrazyGames-vX.Y.Z/  (index.html, .js, .wasm, .pck — pasta pronta pra upload)
#
# Pré-requisitos:
#   - Godot 4.6.2 em $GODOT_PATH abaixo (ou adiciona no PATH e ajusta)
#   - Templates de export 4.6.2.stable instalados

$ErrorActionPreference = "Stop"

# ===== CONFIG =====
$GODOT_PATH = "C:\Users\Mark\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"
$PROJECT_DIR = $PSScriptRoot
$VERSION_FILE = Join-Path $PROJECT_DIR "VERSION"
$EXPORT_PRESET = "Web (CrazyGames)"
$BUILDS_DIR = Join-Path $PROJECT_DIR "Builds"

# ===== VERSION BUMP =====
$bumpType = $args[0]
$currentVersion = (Get-Content $VERSION_FILE -Raw).Trim()
$parts = $currentVersion.Split(".")
if ($parts.Length -ne 3) {
    Write-Error "VERSION file inválido: '$currentVersion'. Esperado MAJOR.MINOR.PATCH"
    exit 1
}
[int]$major = $parts[0]
[int]$minor = $parts[1]
[int]$patch = $parts[2]

switch ($bumpType) {
    "patch" { $patch++ }
    "minor" { $minor++; $patch = 0 }
    "major" { $major++; $minor = 0; $patch = 0 }
    "" {} # no bump
    $null {} # no bump
    default {
        Write-Error "Bump inválido: '$bumpType'. Use: patch | minor | major | (vazio)"
        exit 1
    }
}

$newVersion = "$major.$minor.$patch"
if ($bumpType -in @("patch","minor","major")) {
    Set-Content -Path $VERSION_FILE -Value $newVersion -NoNewline
    Write-Host "Bump: $currentVersion -> $newVersion" -ForegroundColor Yellow
} else {
    Write-Host "Versão atual (sem bump): $newVersion" -ForegroundColor Cyan
}

# ===== PREPARE OUTPUT DIR =====
$exportDir = Join-Path $BUILDS_DIR "Web\CrazyGames-v$newVersion"
$exportFile = Join-Path $exportDir "index.html"

if (Test-Path $exportDir) {
    Write-Host "Limpando export anterior em $exportDir" -ForegroundColor DarkGray
    Remove-Item -Path $exportDir -Recurse -Force
}
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

# ===== UPDATE export_path NO export_presets.cfg =====
# Aponta o preset Web (CrazyGames) pra essa pasta nova com versão
$presetsFile = Join-Path $PROJECT_DIR "export_presets.cfg"
$presetsContent = Get-Content $presetsFile -Raw
$relExportPath = "Builds/Web/CrazyGames-v$newVersion/index.html"
$newPresetsContent = $presetsContent -replace `
    'export_path="Builds/Web/[^"]+"', `
    "export_path=`"$relExportPath`""
Set-Content -Path $presetsFile -Value $newPresetsContent -NoNewline

# ===== EXPORT VIA GODOT CLI =====
Write-Host ""
Write-Host "Exportando '$EXPORT_PRESET' para $exportFile ..." -ForegroundColor Cyan

# Workaround pro Godot precisar abrir o projeto antes de --export-release
# (carrega os assets, reimporta o que precisar)
$godotArgs = @(
    "--headless"
    "--path", $PROJECT_DIR
    "--export-release", $EXPORT_PRESET
    $exportFile
)

& $GODOT_PATH @godotArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Godot export falhou com exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# ===== VERIFY OUTPUT =====
$expectedFiles = @("index.html", "index.js", "index.wasm", "index.pck")
$missing = $expectedFiles | Where-Object { -not (Test-Path (Join-Path $exportDir $_)) }
if ($missing.Count -gt 0) {
    Write-Error "Export incompleto. Arquivos faltando: $($missing -join ', ')"
    exit 1
}
$wasmSize = [math]::Round((Get-Item (Join-Path $exportDir "index.wasm")).Length / 1MB, 1)
Write-Host "Export OK ($wasmSize MB de WASM)" -ForegroundColor Green

# ===== DONE =====
$totalSize = [math]::Round((Get-ChildItem $exportDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  Build v$newVersion pronto" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Pasta: $exportDir" -ForegroundColor White
Write-Host "  Tamanho total: $totalSize MB" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Próximo passo: arrasta a pasta inteira em https://developer.crazygames.com" -ForegroundColor Yellow
Write-Host ""
