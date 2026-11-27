# Joga a Ronda 2a2 (o chefe Apagao) num save de TESTE, sem tocar no seu save real.
# Uso:    powershell -ExecutionPolicy Bypass -File tools\teste\jogar_teste_2a2.ps1
#   (sem opcao)  abre o save de teste que ja existe (ou cria um): Apagao liberado, luta parelha.
#   -Novo        recria o save de teste (luta parelha).
#   -Forte       recria com atributos bem maiores: para ver a vitoria, o premio e tentar o desafio ANTES DO APAGAO.
# O capuz aparece uns 5 s depois de abrir a sala. Clique nele, escolha o BECO e o cartao CHEFE.
# O jogo usa uma pasta propria (APPDATA de teste), entao o save real fica intocado.
param([switch]$Novo, [switch]$Forte)
$godot = "E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
$projeto = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$env:APPDATA = "$env:LOCALAPPDATA\FightclickerTeste2a2"
if (-not $env:APPDATA.Contains("FightclickerTeste")) { Write-Host "APPDATA nao e o de teste. Abortando."; exit 1 }
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
$save = "$env:APPDATA\Godot\app_userdata\Fightclicker\save.json"
if ($Novo -or $Forte -or -not (Test-Path $save)) {
    Write-Host "Criando o save de teste..."
    $extra = @()
    if ($Forte) { $extra = @("--", "--forte") }
    & $godot --headless --path $projeto --script res://tools/teste/criar_save_2a2.gd @extra
}
& $godot --path $projeto
