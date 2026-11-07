extends "res://tests/test_base.gd"
## Guarda do save real do dono para a bateria inteira.
##   -- --antes   : tira a "foto" do save real e guarda em user://test/
##   -- --depois  : compara o save real com a foto (falha se mudou)
## O runner (tools/run_tests.ps1) chama --antes no início e --depois no fim.

const ARQUIVO_FOTO := "user://test/foto_save_real.json"


func rodar_testes() -> void:
	var args := OS.get_cmdline_user_args()
	checar(SaveStore.PASTA_REAL != RAIZ_TESTES and not SaveStore.PASTA_REAL.begins_with(RAIZ_TESTES),
		"pasta real e pasta de testes são diferentes")
	if "--antes" in args:
		DirAccess.make_dir_recursive_absolute(RAIZ_TESTES)
		escrever(ARQUIVO_FOTO, JSON.stringify(foto_save_real()))
		checar(FileAccess.file_exists(ARQUIVO_FOTO), "foto do save real guardada")
	elif "--depois" in args:
		checar(FileAccess.file_exists(ARQUIVO_FOTO), "foto do save real existe")
		var antes = JSON.parse_string(ler(ARQUIVO_FOTO))
		var agora = JSON.parse_string(JSON.stringify(foto_save_real()))
		checar(antes == agora, "save real do dono igual antes e depois da bateria inteira")
		if antes != agora:
			print("  antes: %s\n  agora: %s" % [str(antes), str(agora)])
		print("  (save real: %s)" % ProjectSettings.globalize_path(SaveStore.PASTA_REAL.path_join(SaveStore.NOME_ARQUIVO)))
	else:
		print("  sem --antes/--depois: só a checagem automática da base")
