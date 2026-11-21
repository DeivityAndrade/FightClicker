# Joga a fase 7b2 num save de TESTE, sem tocar no seu save real.
# Uso:    powershell -ExecutionPolicy Bypass -File tools\teste\jogar_teste_7b2.ps1
# Recomeçar do zero (recria o save de teste):   ... jogar_teste_7b2.ps1 -Novo
# O jogo usa uma pasta própria (APPDATA de teste), então o save real fica intocado.
param([switch]$Novo)
$godot = "E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
$projeto = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$env:APPDATA = "$env:LOCALAPPDATA\FightclickerTeste7b2"
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
$save = "$env:APPDATA\Godot\app_userdata\Fightclicker\save.json"
if ($Novo -or -not (Test-Path $save)) {
    Write-Host "Criando o save de teste..."
    & $godot --headless --path $projeto --script res://tools/teste/criar_save_7b2.gd
}
& $godot --path $projeto
