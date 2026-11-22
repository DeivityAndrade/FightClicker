# Joga a fase 8a1 (liga regional) num save de TESTE, sem tocar no seu save real.
# Uso:    powershell -ExecutionPolicy Bypass -File tools\teste\jogar_teste_8a1.ps1
# Recomecar do zero (recria o save de teste):   ... jogar_teste_8a1.ps1 -Novo
# Mesmo save com a 2a passiva do Boxe (Contragolpista) liberada e escolhida:   ... jogar_teste_8a1.ps1 -Novo -Contragolpista
# O save: academia, a 2 dias da luta contra o Kid, Boxe (Mao rapida), atributos de sobra para vencer o Kid e entrar na liga.
# O jogo usa uma pasta propria (APPDATA de teste), entao o save real fica intocado.
param([switch]$Novo, [switch]$Contragolpista)
$godot = "E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
$projeto = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$env:APPDATA = "$env:LOCALAPPDATA\FightclickerTeste8a1"
if (-not $env:APPDATA.Contains("FightclickerTeste")) { Write-Host "APPDATA nao e o de teste. Abortando."; exit 1 }
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
$save = "$env:APPDATA\Godot\app_userdata\Fightclicker\save.json"
if ($Novo -or $Contragolpista -or -not (Test-Path $save)) {
    Write-Host "Criando o save de teste..."
    $extra = @()
    if ($Contragolpista) { $extra = @("--", "--contragolpista") }
    & $godot --headless --path $projeto --script res://tools/teste/criar_save_8a1.gd @extra
}
& $godot --path $projeto
