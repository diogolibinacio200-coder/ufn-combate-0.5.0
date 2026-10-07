param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [string]$WindowsReleaseTemplate = '',
    [string]$SignedRuntime = '',
    [string]$Output = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$enginePath = (Resolve-Path -LiteralPath $Godot).Path
function Invoke-GodotChecked([string[]]$EngineArguments) {
    $engineLog = & $enginePath @EngineArguments 2>&1
    $exitCode = $LASTEXITCODE
    $engineLog | Write-Output
    if ($exitCode -ne 0 -or ($engineLog -join "`n") -match 'SCRIPT ERROR:|ERROR:') {
        throw 'A engine reportou erro durante a importação ou exportação.'
    }
}
if (-not $Output) { $Output = Join-Path (Split-Path -Parent $projectRoot) 'Windows\UFNCombate.exe' }
$outputPath = [IO.Path]::GetFullPath($Output)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputPath) | Out-Null
$presetPath = Join-Path $projectRoot 'export_presets.cfg'
$originalPreset = [IO.File]::ReadAllText($presetPath)
try {
    if ($WindowsReleaseTemplate) {
        $templatePath = (Resolve-Path -LiteralPath $WindowsReleaseTemplate).Path.Replace('\','/')
        $customPreset = $originalPreset.Replace('custom_template/release=""', 'custom_template/release="' + $templatePath + '"')
        [IO.File]::WriteAllText($presetPath, $customPreset, [Text.UTF8Encoding]::new($false))
    }
    Invoke-GodotChecked @('--headless','--path',$projectRoot,'--editor','--import','--quit')
    if ($SignedRuntime) {
        $runtimePath = (Resolve-Path -LiteralPath $SignedRuntime).Path
        if ((Get-AuthenticodeSignature -LiteralPath $runtimePath).Status -ne 'Valid') { throw 'O runtime deve ter assinatura Authenticode válida.' }
        $packPath = [IO.Path]::ChangeExtension($outputPath, '.pck')
        Invoke-GodotChecked @('--headless','--path',$projectRoot,'--export-pack','Windows Desktop',$packPath)
        Copy-Item -LiteralPath $runtimePath -Destination $outputPath -Force
    } else {
        Invoke-GodotChecked @('--headless','--path',$projectRoot,'--export-release','Windows Desktop',$outputPath)
    }
    if (-not (Test-Path -LiteralPath $outputPath)) { throw 'Executável não encontrado.' }
    Write-Host "Build criada: $outputPath"
} finally {
    [IO.File]::WriteAllText($presetPath, $originalPreset, [Text.UTF8Encoding]::new($false))
}
