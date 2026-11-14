extends "res://tests/test_base.gd"
## Testa o GameState: tick independente de FPS, dados de data/, limites, autosave.

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String, caminho_config: String = "res://data/config.json") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), caminho_config)
	return gs


func rodar_testes() -> void:
	_teste_fps()
	_teste_config_de_data()
	_teste_config_invalida()
	_teste_botoes()
	_teste_autosave()
	_teste_salvar_e_recarregar()
	_teste_fechar_pelo_x()
	_teste_delta_invalido()
	_teste_texto_apagar_futuro()


# B2: delta NaN/infinito/negativo é ignorado e o autosave continua funcionando.
func _teste_delta_invalido() -> void:
	var gs := _novo("gs_delta")
	gs.pular_abertura()  # Fase 6a: a abertura grava o marco no 1º tick; aqui só o autosave conta
	var salvos := [0]
	gs.salvo.connect(func(_h: String) -> void: salvos[0] += 1)
	var antes: float = gs.treino
	for d in [NAN, INF, -INF, -1.0, 0.0]:
		gs.tick(d)
	checar_igual(gs.treino, antes, "delta inválido não muda o treino")
	checar(gs.autosave_ativo, "autosave segue ativo após delta inválido")
	gs.tick(gs.config.autosave_intervalo_segundos + 1.0)
	checar_igual(salvos[0], 1, "autosave ainda dispara após delta NaN")
	gs.free()


# B3: diálogo de apagar avisa quando o save é de versão mais nova.
func _teste_texto_apagar_futuro() -> void:
	var gs := _novo("gs_apagar_futuro")
	checar(not gs.texto_confirmar_apagar().contains("mais nova"), "save normal: texto comum")
	escrever(gs.store.caminho(), '{"version": 999, "state": {}}')
	gs.carregar_save()
	checar(gs.store.bloqueado, "save futuro bloqueado")
	checar(gs.texto_confirmar_apagar().contains("mais nova"), "save futuro: diálogo avisa")
	gs.free()


# Critério 10: 30, 60 e 144 FPS (e frames irregulares) dão o mesmo treino em 10 s.
func _teste_fps() -> void:
	var resultados := {}
	for fps in [30, 60, 144]:
		var gs := _novo("gs_fps")
		gs.autosave_ativo = false
		gs.geradores["neighbor_kid"] = 3  # 3 Treino/s
		for i in 10 * fps:
			gs.tick(1.0 / fps)
		resultados[fps] = gs.treino
		gs.free()
	var esperado := 30.0
	for fps in resultados:
		checar(absf(resultados[fps] - esperado) < 1e-6, "10 s a %d FPS = %s (esperado %s)" % [fps, resultados[fps], esperado])

	var gs2 := _novo("gs_fps")
	gs2.autosave_ativo = false
	gs2.geradores["neighbor_kid"] = 3
	var tempo := 0.0
	var passos := [0.005, 0.033, 0.1, 0.016, 0.25]
	var i := 0
	while tempo < 10.0 - 1e-9:
		var d: float = minf(passos[i % passos.size()], 10.0 - tempo)
		gs2.tick(d)
		tempo += d
		i += 1
	checar(absf(gs2.treino - esperado) < 1e-6, "10 s com frames irregulares = %s" % gs2.treino)
	gs2.free()


# A configuração vem do arquivo de dados; chaves antigas da Fase 1 são ignoradas.
func _teste_config_de_data() -> void:
	var pasta := pasta_limpa("gs_config")
	var cfg := pasta.path_join("config.json")
	escrever(cfg, '{"autosave_intervalo_segundos": 12, "treino_por_segundo_teste": 5, ' +
		'"treino_botao_teste": 1, "multiplicador_debug": 10, "ui_atualizacoes_por_segundo": 10, ' +
		'"debug_unidades_gerador": 4}')
	var gs := _novo("gs_config_save", cfg)
	gs.autosave_ativo = false
	checar_igual(gs.config.autosave_intervalo_segundos, 12.0, "autosave lido do arquivo de dados")
	checar_igual(gs.config.debug_unidades_gerador, 4.0, "debug_unidades_gerador lido do arquivo")
	checar_igual(gs.producao_total(), 0.0, "sem geradores o passivo é 0 (chave antiga ignorada)")
	gs.tick(10.0)
	checar_igual(gs.treino, 0.0, "10 s sem geradores = 0 de treino")
	gs.free()

	var real := GameConfig.carregar()
	checar_igual(real.autosave_intervalo_segundos, 30.0, "data/config.json: autosave 30 s")
	checar_igual(real.debug_unidades_gerador, 10.0, "data/config.json: 10 unidades de depuração")


func _teste_config_invalida() -> void:
	var pasta := pasta_limpa("gs_config_ruim")
	var c1 := GameConfig.carregar(pasta.path_join("nao_existe.json"))
	checar_igual(c1, GameConfig.PADROES, "config ausente usa padrões")
	escrever(pasta.path_join("ruim.json"), "{lixo")
	checar_igual(GameConfig.carregar(pasta.path_join("ruim.json")), GameConfig.PADROES, "config inválida usa padrões")
	escrever(pasta.path_join("parcial.json"), '{"multiplicador_debug": -4, "autosave_intervalo_segundos": 12}')
	var c3 := GameConfig.carregar(pasta.path_join("parcial.json"))
	checar_igual(c3.multiplicador_debug, 1000.0, "valor negativo recusado")
	checar_igual(c3.autosave_intervalo_segundos, 12.0, "valor válido aceito")


func _teste_botoes() -> void:
	var gs := _novo("gs_botoes")
	gs.autosave_ativo = false
	gs.clicar()
	checar(gs.treino >= 1.0, "clique soma ao menos 1")
	gs.treino = 1.0
	gs.debug_multiplicar_saldo()
	checar_igual(gs.treino, 1000.0, "x1000 multiplica o saldo")
	var forca_antes: float = gs.atributos.strength
	for i in 200:
		gs.debug_multiplicar_saldo()
	checar_igual(gs.atributos.strength, forca_antes, "depuração não mexe em atributo")
	checar(is_finite(gs.treino) and gs.treino > 1.0e300, "x1000 repetido não vira infinito")
	gs.geradores["neighbor_kid"] = 5
	gs.tick(1.0)
	checar(is_finite(gs.treino), "tick no limite continua finito")
	checar(NumberFormat.fmt(gs.treino) == "1.80e308", "formatação no limite")
	gs.free()


# Critério 6: autosave dispara pelo intervalo de data/.
func _teste_autosave() -> void:
	var gs := _novo("gs_autosave")
	gs.pular_abertura()  # Fase 6a: idem
	var intervalo: float = gs.config.autosave_intervalo_segundos
	var salvos := [0]
	gs.salvo.connect(func(_h: String) -> void: salvos[0] += 1)
	for i in int(intervalo * 60.0) - 6:
		gs.tick(1.0 / 60.0)
	checar_igual(salvos[0], 0, "sem autosave antes do intervalo")
	for i in 12:
		gs.tick(1.0 / 60.0)
	checar_igual(salvos[0], 1, "autosave ao completar o intervalo")
	checar(FileAccess.file_exists(gs.store.caminho()), "autosave gravou o arquivo")
	checar(gs.ultimo_save_texto != "nenhum", "horário do último save atualizado")
	gs.free()


# Critério 5 (lógica): salvar e reabrir mantém o treino.
func _teste_salvar_e_recarregar() -> void:
	var gs := _novo("gs_reabrir")
	gs.autosave_ativo = false
	gs.geradores["neighbor_kid"] = 2
	gs.tick(12.5)
	var valor: float = gs.treino
	gs.salvar()
	var pasta: String = gs.store.pasta
	gs.free()
	var gs2: Node = GameStateScript.new()
	gs2.inicializar(pasta, "res://data/config.json")
	checar_igual(gs2.treino, valor, "reabrir mantém o treino")
	checar(gs2.avisos.is_empty(), "reabrir sem avisos")
	gs2.free()


# Critério 5: fechar pelo X salva antes de sair. Dentro de --script o GameState
# escolhe sozinho a pasta de testes (proteção extra do save real).
func _teste_fechar_pelo_x() -> void:
	pasta_limpa("autoload")
	var gs: Node = GameStateScript.new()
	root.add_child(gs)  # roda _ready como o autoload faria
	checar_igual(gs.store.pasta, GameStateScript.PASTA_SAVE_TESTES, "em teste, GameState usa a pasta de testes")
	checar(not auto_accept_quit, "fechar pelo X passa pelo GameState")
	gs.geradores["neighbor_kid"] = 1
	gs.tick(3.0)
	gs.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	var r := SaveStore.new(GameStateScript.PASTA_SAVE_TESTES).carregar()
	checar_igual(r.status, SaveStore.Status.OK, "fechar pelo X gravou o save")
	checar(absf(float(r.estado.career.get("training", -1.0)) - gs.treino) < 1e-9, "valor salvo ao fechar = valor atual")
	gs.queue_free()
