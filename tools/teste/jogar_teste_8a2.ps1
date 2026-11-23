# Joga a fase 8a2 (centro de treinamento) num save de TESTE, sem tocar no seu save real.
# Uso:    powershell -ExecutionPolicy Bypass -File tools\teste\jogar_teste_8a2.ps1 -Vale
#   -Vale        academia, James ja vencido nesta campanha, dinheiro de sobra: clique MUDAR para ir ao centro.
#   -Patrocinio  campanha 2, linhagem com o Cinturao do Vale e a chegada ao centro ja feita, 22.000 de Legado guardado,
#                a 2 dias do Tonhao com fama perto de 200 (vencer o Tonhao faz o patrocinador mandar a proposta).
# -Novo recria o save de teste. Sem opcao, abre o save de teste que ja existe (ou cria o -Vale).
# O jogo usa uma pasta propria (APPDATA de teste), entao o save real fica intocado.
param([switch]$Novo, [switch]$Vale, [switch]$Patrocinio)
$godot = "E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
$projeto = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$env:APPDATA = "$env:LOCALAPPDATA\FightclickerTeste8a2"
if (-not $env:APPDATA.Contains("FightclickerTeste")) { Write-Host "APPDATA nao e o de teste. Abortando."; exit 1 }
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
$save = "$env:APPDATA\Godot\app_userdata\Fightclicker\save.json"
if ($Novo -or $Vale -or $Patrocinio -or -not (Test-Path $save)) {
    Write-Host "Criando o save de teste..."
    $extra = @("--", "--vale")
    if ($Patrocinio) { $extra = @("--", "--patrocinio") }
    & $godot --headless --path $projeto --script res://tools/teste/criar_save_8a2.gd @extra
}
& $godot --path $projeto
