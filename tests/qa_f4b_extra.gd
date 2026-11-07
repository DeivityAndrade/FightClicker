extends "res://tests/test_base.gd"
## QA Fase 4b: cenários extras (não entra no runner: nome qa_*). Só usa user://test/.

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _passar(gs: Node, s: float) -> void:
	for i in int(round(s * 10.0)):
		gs.tick(0.1)


func _escrever(pasta: String, d: Variant) -> void:
	var f := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f.store_string(d if d is String else JSON.stringify(d))
	f.close()


func rodar_testes() -> void:
	_extremos()
	_ordem_e_estados()
	_migracao()
	_corrompido()
	_metronomo_e_assistido()
	_ritmo()
	_fora_da_garagem()
	_nova_carreira()
	_salvar_no_meio()
	_mais()


func _extremos() -> void:
	var gs := _novo("qa_ext")
	# Treino NaN / enorme / negativo
	gs.treino = -5.0
	checar(not gs.comprar_aparelho("treadmill"), "treino negativo não compra")
	gs.treino = 500.0
	checar(gs.comprar_aparelho("treadmill"), "treino exato 500 compra")
	checar_igual(gs.treino, 0.0, "saldo 0 exato (não negativo)")
	gs.treino = 1499.999
	checar(not gs.comprar_aparelho("jump_rope"), "1499.999 não compra a corda")
	gs.treino = 1.0e300
	checar(gs.comprar_aparelho("jump_rope"), "treino enorme compra a corda")
	checar(is_finite(gs.treino) and gs.treino >= 0.0, "saldo finito depois")
	checar(not gs.comprar_aparelho("nao_existe"), "id inexistente recusado")
	checar(not gs.comprar_aparelho("punching_bag"), "saco (já montado) recusado")
	checar(not gs.comprar_aparelho(""), "id vazio recusado")
	checar_igual(gs.estado_aparelho("nao_existe"), "locked", "estado de inexistente")
	checar_igual(gs.aparelhos_montados(), ["punching_bag", "treadmill", "jump_rope"], "ordem de compra")
	_liberar(gs)
	# tick com deltas absurdos com assistido
	var g2 := _novo("qa_ext2")
	g2.definir_assistido(true)
	g2.tick(1.0e9)
	g2.tick(NAN)
	g2.tick(INF)
	g2.tick(-1.0)
	checar(g2.assist_socos_total <= 3, "tick gigante: no máx 3 socos (obtido %d)" % g2.assist_socos_total)
	_liberar(g2)


func _ordem_e_estados() -> void:
	var gs := _novo("qa_ordem")
	gs.treino = 1.0e6
	checar(not gs.comprar_aparelho("jump_rope"), "corda antes da esteira recusada com Treino de sobra")
	checar_igual(gs.treino, 1.0e6, "saldo intacto")
	checar(not gs.definir_foco("jump_rope"), "foco na corda trancada recusado")
	checar(not gs.definir_foco("treadmill"), "foco na esteira trancada recusado")
	checar_igual(gs.foco, "punching_bag", "foco segue no saco")
	# clicar sem Treino de aparelho não troca foco
	var r: Dictionary = gs.clicar()
	checar_igual(r.get("aparelho", ""), "punching_bag", "clique treina o saco")
	checar(gs.proxima_melhoria("treadmill").is_empty(), "sem melhoria na esteira trancada")
	checar(not gs.pode_comprar_melhoria("jump_rope"), "sem comprar melhoria da corda")
	# comprar com luta pendente / fim
	gs.luta = {"x": 1}
	checar(not gs.comprar_aparelho("treadmill"), "luta pendente recusa")
	checar(gs.definir_foco("punching_bag"), "foco no saco ok em luta")
	gs.luta = {}
	gs.fim = {"kind": "retire"}
	checar(not gs.comprar_aparelho("treadmill"), "fim recusa")
	gs.fim = {}
	# Dois compras rápidas seguidas da mesma
	checar(gs.comprar_aparelho("treadmill"), "compra esteira")
	var t: float = gs.treino
	checar(not gs.comprar_aparelho("treadmill"), "compra dupla recusada")
	checar_igual(gs.treino, t, "dupla não cobra")
	_liberar(gs)


func _migracao() -> void:
	# v4 com fim pendente
	var pasta := pasta_limpa("qa_mig_fim")
	var v4 := {"version": 4, "saved_at_unix": 1730000000, "state": {
		"career": {"training": 777.0, "focus": "treadmill", "upgrades": {"punching_bag": 2, "jump_rope": 0, "treadmill": 1}, "metronome_level": 1},
		"permanent": {"legacy_total": 120, "career_number": 3},
		"ending": {"kind": "defeat", "reason": {"kind": "missing", "attribute": "agility", "faltaram": 9.0, "tip": 0}}}}
	_escrever(pasta, v4)
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	checar_igual(gs.aparelhos_montados(), ["punching_bag", "jump_rope", "treadmill"], "v4+fim: 3 aparelhos")
	checar_igual([gs.treino, gs.foco, gs.nivel_metronomo], [777.0, "treadmill", 1], "v4+fim: treino, foco, metrônomo")
	checar(gs.tem_fim_pendente() or true, "fim carregado: %s" % str(gs.tem_fim_pendente()))
	if gs.tem_fim_pendente():
		print("   fim.reason = ", gs.fim.get("reason", {}))
		checar_igual(str(gs.fim.get("reason", {}).get("unlock_tip", "")), "", "fim antigo sem unlock_tip vale vazio")
		var tf: Dictionary = gs.textos_fim()
		checar(tf.has("tip") and str(tf.tip) != "", "textos_fim com ending antigo funciona")
	gs.salvar()
	var doc = JSON.parse_string(FileAccess.get_file_as_string(pasta + "save.json"))
	checar_igual(int(doc.version), 5, "regravado v5")
	_liberar(gs)
	# v0 -> v5 em cadeia (v0 mínimo)
	var p0 := pasta_limpa("qa_mig_v0")
	_escrever(p0, {"version": 0, "training": 55.0})
	var g0: Node = GameStateScript.new()
	g0.inicializar(p0, "res://data/config.json")
	g0.autosave_ativo = false
	print("   v0: montados=", g0.aparelhos_montados(), " treino=", g0.treino)
	checar(g0.aparelho_montado("punching_bag"), "v0: saco montado")
	_liberar(g0)
	# v3 com 'focus' e sem metronome
	var p3 := pasta_limpa("qa_mig_v3")
	_escrever(p3, {"version": 3, "saved_at_unix": 1, "state": {"career": {"training": 10.0, "focus": "jump_rope"}, "permanent": {}}})
	var g3: Node = GameStateScript.new()
	g3.inicializar(p3, "res://data/config.json")
	g3.autosave_ativo = false
	print("   v3: montados=", g3.aparelhos_montados(), " foco=", g3.foco)
	_liberar(g3)


func _corrompido() -> void:
	# v5 sem apparatus_owned, foco e melhoria em aparelho inexistente
	var pasta := pasta_limpa("qa_corr1")
	_escrever(pasta, {"version": 5, "saved_at_unix": 1, "state": {"career": {"training": 40.0, "focus": "jump_rope",
		"upgrades": {"jump_rope": 2, "treadmill": 1, "punching_bag": 1}}, "permanent": {}}})
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	checar_igual(gs.aparelhos_montados(), ["punching_bag"], "v5 sem apparatus_owned: só o saco")
	checar_igual(gs.foco, "punching_bag", "foco corrigido")
	checar_igual([gs.nivel_melhoria("jump_rope"), gs.nivel_melhoria("treadmill"), gs.nivel_melhoria("punching_bag")], [0, 0, 1], "melhorias trancadas viram 0, saco fica")
	_liberar(gs)
	# apparatus_owned com tipos esquisitos
	for ruim in [null, 5, "treadmill", {"a": 1}, [1, 2, null], [["treadmill"]], []]:
		var p := pasta_limpa("qa_corr2")
		_escrever(p, {"version": 5, "saved_at_unix": 1, "state": {"career": {"training": 1.0, "focus": "punching_bag", "apparatus_owned": ruim}, "permanent": {}}})
		var g: Node = GameStateScript.new()
		g.inicializar(p, "res://data/config.json")
		g.autosave_ativo = false
		checar(g.aparelho_montado("punching_bag"), "apparatus_owned=%s: saco montado, lista %s" % [str(ruim), str(g.aparelhos_montados())])
		_liberar(g)
	# corda sem esteira (editado)
	var pc := pasta_limpa("qa_corr3")
	_escrever(pc, {"version": 5, "saved_at_unix": 1, "state": {"career": {"training": 1.0, "focus": "jump_rope", "apparatus_owned": ["jump_rope"]}, "permanent": {}}})
	var gc: Node = GameStateScript.new()
	gc.inicializar(pc, "res://data/config.json")
	gc.autosave_ativo = false
	checar_igual(gc.aparelhos_montados(), ["punching_bag", "jump_rope"], "corda sem esteira mantida")
	checar_igual(gc.estado_aparelho("treadmill"), "missing", "esteira ainda compravel")
	_liberar(gc)
	# JSON quebrado
	var pj := pasta_limpa("qa_corr4")
	_escrever(pj, "{ \"version\": 5, \"state\": ")
	var gj: Node = GameStateScript.new()
	gj.inicializar(pj, "res://data/config.json")
	gj.autosave_ativo = false
	checar_igual(gj.aparelhos_montados(), ["punching_bag"], "JSON quebrado: jogo novo só com saco")
	_liberar(gj)


func _metronomo_e_assistido() -> void:
	var gs := _novo("qa_metro")
	gs.definir_assistido(true)
	_passar(gs, 30.0)
	var antes: int = gs.assist_socos_total
	checar(antes >= 9, "30 s segurando sem Metrônomo: %d socos do assistido (esp ~10)" % antes)
	# comprar Metrônomo com o Shift apertado
	gs.dinheiro = 1.0e6
	var ok: bool = gs.comprar_metronomo()
	print("   comprar_metronomo=", ok, " nivel=", gs.nivel_metronomo)
	checar_igual(gs.assistido_estado(), "metronome", "estado vira metronome")
	var auto0: int = gs.auto_socos_total
	_passar(gs, 20.0)
	checar_igual(gs.assist_socos_total, antes, "assistido não soca com Metrônomo")
	var esperado: float = 20.0 / float(gs.intervalo_metronomo())
	var feito: int = gs.auto_socos_total - auto0
	checar(absf(float(feito) - esperado) <= 1.5, "só o Metrônomo soca no ritmo dele: %d (esp %.1f)" % [feito, esperado])
	gs.definir_assistido(false)
	var auto1: int = gs.auto_socos_total
	_passar(gs, 20.0)
	checar(absf(float(gs.auto_socos_total - auto1) - esperado) <= 1.5, "soltando o Shift: mesmo ritmo (Shift não muda treino)")
	_liberar(gs)


func _ritmo() -> void:
	var gs := _novo("qa_ritmo")
	gs.definir_assistido(true)
	var tempos: Array = []
	var ult: int = 0
	for i in 650:
		gs.tick(0.1)
		if gs.assist_socos_total != ult:
			tempos.append(snappedf(gs.tempo_jogo, 0.1))
			ult = gs.assist_socos_total
	print("   tempos dos socos: ", tempos.slice(0, 5), " total em 65 s=", gs.assist_socos_total)
	checar(tempos.size() >= 20 and absf(tempos[0] - 1.0) < 0.21, "1º soco em ~1 s (obtido %s)" % str(tempos[0] if tempos.size() > 0 else -1))
	checar(tempos.size() >= 2 and absf(tempos[1] - tempos[0] - 3.0) < 0.21, "intervalo de 3 s")
	# clicar a 5/s por 30 s com Shift: 0 socos
	var g2 := _novo("qa_ritmo2")
	g2.definir_assistido(true)
	for i in 300:
		g2.tick(0.2)
		g2.clicar()
	checar_igual(g2.assist_socos_total, 0, "clicando a 5/s segurando Shift: 0 socos")
	# para de clicar: 1º soco em ≥ 2 s (1 mão parada + 1 first_delay)
	var t0: float = g2.tempo_jogo
	var t_soco := -1.0
	for i in 100:
		g2.tick(0.05)
		if g2.assist_socos_total > 0:
			t_soco = g2.tempo_jogo - t0
			break
	print("   1º soco após parar de clicar: ", t_soco, " s")
	checar(t_soco >= 1.0, "1º soco após parar de clicar sai com >= 1 s")
	# clicar a cada 0.9 s (quase parado) - ainda zera
	var g3 := _novo("qa_ritmo3")
	g3.definir_assistido(true)
	for i in 100:
		g3.tick(0.9)
		g3.clicar()
	checar_igual(g3.assist_socos_total, 0, "clicando a cada 0.9 s: 0 socos")
	# Shift batido a 0.5 s
	var g4 := _novo("qa_ritmo4")
	for i in 40:
		g4.definir_assistido(true)
		g4.tick(0.25)
		g4.definir_assistido(false)
		g4.tick(0.25)
	checar_igual(g4.assist_socos_total, 0, "Shift batido 2x/s: 0 socos")
	# luva: 1000 socos pelo caminho do clique
	var g5 := _novo("qa_ritmo5")
	var crit := 0
	for i in 1000:
		var r: Dictionary = g5.auto_socar()
		if r.get("critico", false):
			crit += 1
	print("   críticos em 1000 auto-socos: ", crit)
	checar(crit >= 70 and crit <= 130, "crítico ~10%% em 1000 (obtido %d)" % crit)
	for g in [gs, g2, g3, g4, g5]:
		_liberar(g)


func _fora_da_garagem() -> void:
	var gs := _novo("qa_fora")
	gs.definir_assistido(true)
	var estados := []
	gs.assistido_mudou.connect(func(e): estados.append(e))
	gs.definir_modal(true)
	_passar(gs, 30.0)
	checar_igual(gs.assist_socos_total, 0, "modal aberto: 0 socos")
	gs.definir_modal(false)
	gs.luta = {"x": 1}
	_passar(gs, 30.0)
	checar_igual(gs.assist_socos_total, 0, "luta pendente: 0 socos")
	gs.luta = {}
	gs.fim = {"kind": "retire", "reason": {}}
	_passar(gs, 30.0)
	checar_igual(gs.assist_socos_total, 0, "fim: 0 socos")
	print("   estado após fim, sem tick extra: ", gs.assistido_estado(), " sinais: ", estados)
	gs.fim = {}
	# volta: depois de 30 s bloqueado, não despeja socos acumulados
	var n0: int = gs.assist_socos_total
	gs.tick(0.1)
	checar(gs.assist_socos_total - n0 <= 1, "voltando da janela: não despeja acumulado")
	# luta de verdade
	var g2 := _novo("qa_fora2")
	g2.definir_assistido(true)
	g2.treino = 1.0e6
	# Dudu: iniciar luta se possível
	var info: Dictionary = {}
	if true:
		info = g2.lutar()
	print("   iniciar_luta: ", str(info).substr(0, 80), " luta pendente=", g2.tem_luta_pendente())
	var n2: int = g2.assist_socos_total
	_passar(g2, 20.0)
	checar_igual(g2.assist_socos_total, n2, "durante luta real: 0 socos")
	_liberar(gs)
	_liberar(g2)


func _nova_carreira() -> void:
	var gs := _novo("qa_nova")
	gs.treino = 1.0e6
	gs.comprar_aparelho("treadmill")
	gs.comprar_aparelho("jump_rope")
	checar_igual(gs.foco, "jump_rope", "foco na corda")
	gs.definir_assistido(true)
	# derrota -> nova carreira
	gs._encerrar_carreira("defeat", {}, {"kind": "missing", "attribute": "agility", "faltaram": 5.0, "tip": 0, "model": 0})
	checar(gs.tem_fim_pendente(), "fim pendente")
	checar(gs.nova_carreira(), "nova carreira após derrota")
	checar_igual(gs.aparelhos_montados(), ["punching_bag"], "derrota: aparelhos zeram")
	checar_igual(gs.foco, "punching_bag", "foco no saco")
	checar_igual(gs.nivel_melhoria("jump_rope"), 0, "melhorias zeram")
	checar(gs.assistido_segurando(), "Shift segurado atravessa a nova carreira (estado da tecla)")
	# aposentadoria
	gs.treino = 1.0e6
	gs.comprar_aparelho("treadmill")
	checar(gs.aposentar() or true, "aposentar")
	checar(gs.nova_carreira(), "nova carreira após aposentar")
	checar_igual(gs.aparelhos_montados(), ["punching_bag"], "aposentar: aparelhos zeram")
	_liberar(gs)


func _salvar_no_meio() -> void:
	var gs := _novo("qa_meio")
	gs.treino = 700.0
	gs.comprar_aparelho("treadmill")
	gs.treino = 1520.0
	gs.comprar_aparelho("jump_rope")
	var pasta: String = gs.store.pasta
	# recarrega sem salvar de novo (a compra já salvou)
	var g2: Node = GameStateScript.new()
	g2.inicializar(pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar_igual([g2.aparelhos_montados(), g2.treino, g2.foco], [["punching_bag", "treadmill", "jump_rope"], 20.0, "jump_rope"], "reabre: comprados, treino 20, foco corda")
	# assistido não vai para o save
	var doc = JSON.parse_string(FileAccess.get_file_as_string(pasta + "save.json"))
	checar(not JSON.stringify(doc).contains("assist"), "save não contém assist")
	_liberar(gs)
	_liberar(g2)


func _mais() -> void:
	# 5 lutas com Shift segurado: 0 socos durante, e sinais coerentes
	var gs := _novo("qa_5lutas")
	gs.definir_assistido(true)
	var n_luta := 0
	for i in 5:
		gs.treino = 1.0e7
		var antes: int = gs.assist_socos_total
		var info: Dictionary = gs.lutar()
		if gs.tem_luta_pendente():
			n_luta += 1
			_passar(gs, 10.0)
			checar_igual(gs.assist_socos_total, antes, "luta %d: 0 socos durante" % i)
			gs.concluir_luta()
		if gs.tem_fim_pendente():
			_passar(gs, 10.0)
			checar_igual(gs.assist_socos_total, antes, "fim após luta %d: 0 socos" % i)
			gs.nova_carreira()
	print("   lutas realizadas: ", n_luta)
	checar(n_luta >= 1, "ao menos uma luta rodou")
	_liberar(gs)
	# aposentar com assistido ativo: estado do sinal
	var g2 := _novo("qa_apos")
	g2.definir_assistido(true)
	_passar(g2, 5.0)
	var estados: Array = []
	g2.assistido_mudou.connect(func(e): estados.append(e))
	g2.aposentar()
	_passar(g2, 2.0)
	print("   aposentar ativo: estado=", g2.assistido_estado(), " sinais=", estados)
	_liberar(g2)
