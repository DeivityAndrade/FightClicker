# Roda todos os testes automáticos do Fightclicker (headless, sem abrir janela).
# Uso:  powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1
# Os testes usam user://test/ e NUNCA tocam o save real; o guarda confere isso no fim.

param(
	[string]$Godot = "E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
)

$projeto = Split-Path -Parent $PSScriptRoot
$falhas = 0

function Rodar([string[]]$argumentos) {
	$saida = & $Godot --headless --path $projeto @argumentos 2>&1 | ForEach-Object { "$_" }
	$codigo = $LASTEXITCODE
	$saida | Out-Host
	# Erro de script interrompe um teste sem mudar o código de saída: conta como falha.
	if ($saida | Where-Object { $_ -match "SCRIPT ERROR|Parse Error|^ERROR:" }) {
		Write-Host "FAIL  erro de script/engine no console" -ForegroundColor Red
		return 1
	}
	return $codigo
}

# Importa o projeto se o cache ainda não existe.
if (-not (Test-Path (Join-Path $projeto ".godot\global_script_class_cache.cfg"))) {
	Write-Host "Importando projeto..."
	& $Godot --headless --path $projeto --import | Out-Null
}

# 1) Foto do save real antes de tudo.
if ((Rodar @("--script", "res://tests/test_real_save_guard.gd", "--", "--antes")) -ne 0) { $falhas++ }

# 2) Todos os tests/test_*.gd (menos a base e o guarda).
$testes = Get-ChildItem (Join-Path $projeto "tests") -Filter "test_*.gd" |
	Where-Object { $_.Name -ne "test_base.gd" -and $_.Name -ne "test_real_save_guard.gd" } |
	Sort-Object Name
foreach ($t in $testes) {
	if ((Rodar @("--script", "res://tests/$($t.Name)")) -ne 0) {
		$falhas++
		Write-Host "!! FALHOU: $($t.Name)" -ForegroundColor Red
	}
}

# 3) Cena principal por 120 frames, com save de teste, procurando erros no console.
Write-Host "== cena principal (--quit-after 120) =="
$saida = & $Godot --headless --path $projeto --quit-after 120 -- --save-dir=user://test/cena_principal/ 2>&1 | Out-String
$erros = $saida -split "`n" | Where-Object { $_ -match "ERROR|SCRIPT ERROR|Parse Error" }
if ($LASTEXITCODE -ne 0 -or $erros) {
	$falhas++
	Write-Host "FAIL  cena principal com erros:" -ForegroundColor Red
	$erros | ForEach-Object { Write-Host "  $_" }
} else {
	Write-Host "PASS  cena principal roda 120 frames sem erros"
}

# 4) Confere que o save real do dono continua igual.
if ((Rodar @("--script", "res://tests/test_real_save_guard.gd", "--", "--depois")) -ne 0) { $falhas++ }

Write-Host ""
if ($falhas -eq 0) {
	Write-Host "TODOS OS TESTES PASSARAM" -ForegroundColor Green
	exit 0
} else {
	Write-Host "$falhas GRUPO(S) DE TESTE FALHARAM" -ForegroundColor Red
	exit 1
}
