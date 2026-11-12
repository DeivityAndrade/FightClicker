extends "res://tests/test_base.gd"
## Fase 4b: aparelhos que chegam (compra, ordem, zera na nova carreira, save v5) e modo assistido (Shift).
## Usa pastas em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String, treino_td: String = TrainingData.CAMINHO_TREINO) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json", treino_td)
	gs.autosave_ativo = false
	gs.dados.box_apparatus = false  # Fase 5.1: estes testes cobrem a compra instantânea (a caixa tem teste próprio)
	gs.dados.box_glove = false
	gs.risco_hud_ativo = false
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


# Avança o jogo em passos de 0.1 s.
func _passar(gs: Node, segundos: float) -> void:
	for i in int(round(segundos * 10.0)):
		gs.tick(0.1)


func rodar_testes() -> void:
	_teste_comeco_e_compra()
	_teste_foco_e_melhorias()
	_teste_nova_carreira()
	_teste_dica_de_fim()
	_teste_save_v5()
	_teste_dados()
	_teste_assistido_ritmo()
	_teste_assistido_mao_parada()
	_teste_assistido_bloqueios()
	_teste_assistido_metronomo()
	_teste_assistido_foco_janela()


func _teste_comeco_e_compra() -> void:
	var gs := _novo("f4b_compra")
	checar_igual(gs.aparelhos_montados(), ["punching_bag"], "começa só com o saco")
	checar_igual(gs.estado_aparelho("treadmill"), "missing", "esteira sem Treino: missing")
	checar_igual(gs.estado_aparelho("jump_rope"), "locked", "corda sem esteira: locked")
	checar_igual(gs.desbloqueio("treadmill").cost, 500.0, "esteira custa 500")
	checar_igual(gs.desbloqueio("jump_rope").cost, 1500.0, "corda custa 1500")
	gs.treino = 499.0
	checar(not gs.comprar_aparelho("treadmill"), "499 não compra a esteira")
	gs.treino = 5000.0
	checar(not gs.comprar_aparelho("jump_rope"), "corda antes da esteira recusada")
	checar_igual(gs.treino, 5000.0, "recusa não mexe no saldo")
	gs.atributos = {"strength": 7.0, "agility": 3.0, "endurance": 1.0}
	var comprados := []
	gs.aparelho_comprado.connect(func(a): comprados.append(a))
	gs.treino = 520.0
	checar_igual(gs.estado_aparelho("treadmill"), "buyable", "520: esteira buyable")
	checar(gs.comprar_aparelho("treadmill"), "compra a esteira")
	checar_igual(gs.treino, 20.0, "desconta exatamente 500")
	checar_igual(gs.atributos, {"strength": 7.0, "agility": 3.0, "endurance": 1.0}, "atributos intactos")
	checar_igual(gs.foco, "treadmill", "foco vai para a esteira")
	checar_igual(comprados, ["treadmill"], "sinal aparelho_comprado")
	checar(not gs.comprar_aparelho("treadmill"), "não compra duas vezes")
	checar_igual(gs.estado_aparelho("treadmill"), "owned", "esteira owned")
	checar_igual(gs.estado_aparelho("jump_rope"), "missing", "corda agora pede só Treino")
	# Salvou na hora: reabrir mantém comprado e descontado uma vez.
	var pasta: String = gs.store.pasta
	var gs2: Node = GameStateScript.new()
	gs2.inicializar(pasta, "res://data/config.json")
	checar_igual([gs2.aparelhos_montados(), gs2.treino, gs2.foco], [["punching_bag", "treadmill"], 20.0, "treadmill"], "compra salva na hora")
	_liberar(gs2)
	gs.treino = 2000.0
	checar(gs.comprar_aparelho("jump_rope"), "compra a corda")
	checar_igual(gs.treino, 500.0, "corda desconta 1500")
	# Bloqueios: luta e tela de fim.
	var gs3 := _novo("f4b_compra_bloq")
	gs3.treino = 900.0
	gs3.luta = {"x": 1}
	checar(not gs3.comprar_aparelho("treadmill"), "recusa durante a luta")
	gs3.luta = {}
	gs3.fim = {"kind": "retire"}
	checar(not gs3.comprar_aparelho("treadmill"), "recusa com a tela de fim")
	_liberar(gs)
	_liberar(gs3)


func _teste_foco_e_melhorias() -> void:
	var gs := _novo("f4b_foco")
	checar(not gs.definir_foco("treadmill"), "foco recusa aparelho não montado")
	checar_igual(gs.foco, "punching_bag", "foco mantido")
	checar(gs.proxima_melhoria("jump_rope").is_empty(), "sem melhoria em aparelho trancado")
	gs.treino = 1.0e6
	checar(not gs.comprar_melhoria("treadmill"), "melhoria recusada em trancado")
	gs.comprar_aparelho("treadmill")
	checar(gs.comprar_melhoria("treadmill"), "depois de montar, compra melhoria")
	var t: Dictionary = gs.textos_trancado("jump_rope")
	checar(str(t.floor_mark).contains("CORDA"), "plaquinha da corda cita CORDA")
	checar(gs.textos_trancado("treadmill").is_empty(), "montado: sem textos de trancado")
	_liberar(gs)


func _teste_nova_carreira() -> void:
	var gs := _novo("f4b_nova")
	gs.treino = 1.0e5
	gs.comprar_aparelho("treadmill")
	gs.comprar_aparelho("jump_rope")
	gs.aposentar()
	checar(gs.nova_carreira(), "nova carreira")
	checar_igual(gs.aparelhos_montados(), ["punching_bag"], "aparelhos zeram")
	checar_igual(gs.foco, "punching_bag", "foco volta ao saco")
	_liberar(gs)


func _teste_dica_de_fim() -> void:
	var gs := _novo("f4b_dica")
	gs._encerrar_carreira("defeat", {}, {"kind": "missing", "attribute": "endurance", "faltaram": 5.0, "tip": 1, "model": 0})
	checar_igual(gs.fim.reason.unlock_tip, "treadmill", "derrota por resistência sem esteira: unlock_tip")
	checar_igual(gs.textos_fim().tip, gs.lista_ui("tip_unlock_treadmill")[1], "dica vem de tip_unlock_treadmill")
	gs.fim = {}
	gs.treino = 1.0e5
	gs.comprar_aparelho("treadmill")
	gs._encerrar_carreira("defeat", {}, {"kind": "missing", "attribute": "endurance", "faltaram": 5.0, "tip": 1, "model": 0})
	checar_igual(gs.fim.reason.unlock_tip, "", "esteira montada: sem unlock_tip")
	checar_igual(gs.textos_fim().tip, gs.lista_ui("tip_endurance")[1], "dica normal")
	gs.fim = {}
	gs._encerrar_carreira("defeat", {}, {"kind": "luck", "attribute": "agility", "faltaram": -1.0, "tip": 0})
	checar_igual(gs.fim.reason.unlock_tip, "", "azar não aponta aparelho")
	gs.fim.reason.erase("unlock_tip")
	checar(gs.textos_fim().has("tip"), "fim sem unlock_tip funciona")
	_liberar(gs)


func _teste_save_v5() -> void:
	checar(SaveStore.VERSAO_ATUAL >= 5, "versão do save é pelo menos 5")
	var pasta := pasta_limpa("f4b_mig")
	var v4 := {"version": 4, "saved_at_unix": 1730000000, "state": {"career": {
		"training": 321.0, "focus": "jump_rope", "upgrades": {"punching_bag": 1, "jump_rope": 1, "treadmill": 0},
		"metronome_level": 0}, "permanent": {"legacy_total": 50}, "ending": null}}
	var f := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(v4))
	f.close()
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	checar_igual(gs.aparelhos_montados(), ["punching_bag", "jump_rope", "treadmill"], "v4 -> v5: 3 aparelhos")
	checar_igual([gs.foco, gs.treino, gs.nivel_melhoria("jump_rope"), gs.permanente.legacy_total], ["jump_rope", 321.0, 1, 50], "foco, treino, melhoria e Legado intactos")
	gs.salvar()
	var doc = JSON.parse_string(FileAccess.get_file_as_string(pasta + "save.json"))
	checar_igual([int(doc.version), doc.state.career.apparatus_owned.size()], [SaveStore.VERSAO_ATUAL, 3], "regravado na versão atual")
	gs.aposentar()
	gs.nova_carreira()
	checar_igual(gs.aparelhos_montados(), ["punching_bag"], "próxima carreira só com o saco")
	# Validação na leitura.
	gs.aplicar_save({"career": {"focus": "treadmill", "apparatus_owned": ["lixo", "treadmill", "treadmill"],
		"upgrades": {"jump_rope": 2}}})
	checar_igual(gs.aparelhos_montados(), ["punching_bag", "treadmill"], "ignora inexistente e repetido; mantém o saco")
	checar_igual(gs.nivel_melhoria("jump_rope"), 0, "melhoria em aparelho não montado vira 0")
	gs.aplicar_save({"career": {"focus": "jump_rope", "apparatus_owned": 5}})
	checar_igual([gs.aparelhos_montados(), gs.foco], [["punching_bag"], "punching_bag"], "campo inválido: só iniciais; foco corrigido")
	_liberar(gs)


func _escrever(p: String, d: Dictionary) -> void:
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()


func _teste_dados() -> void:
	var pasta := pasta_limpa("f4b_dados")
	var p := pasta + "training.json"
	_escrever(p, {"assist": {"interval": 1.0, "still_seconds": 2.0, "first_delay": 0.5}, "default_focus": "b",
		"apparatus": [
			{"id": "a", "attribute": "strength", "unlock": {"cost": 0}},
			{"id": "b", "attribute": "agility", "unlock": {"cost": 10, "requires": ""}},
			{"id": "c", "attribute": "endurance", "unlock": {"cost": 20, "requires": "d"}},
			{"id": "d", "attribute": "endurance", "unlock": {"cost": 30, "requires": "c"}}]})
	var td := TrainingData.carregar(p)
	checar(td.aparelho("a").unlock.is_empty(), "cost inválido: aparelho sem trava")
	checar(td.aparelho("b").unlock.is_empty(), "default_focus com unlock: unlock ignorado")
	checar(td.aparelho("c").unlock.requires == "" or td.aparelho("d").unlock.requires == "", "ciclo de requires quebrado")
	checar_igual(td.aparelho("c").unlock.id, "unlock_c", "id padrão do desbloqueio")
	var gs := _novo("f4b_dados_gs", p)
	checar_igual(gs.assistido_intervalo(), 2.2, "interval <= Metrônomo 1 vira L1 + 1")
	_liberar(gs)
	_escrever(p, {"apparatus": [{"id": "punching_bag", "attribute": "strength"},
		{"id": "treadmill", "attribute": "endurance", "unlock": {"cost": 123, "requires": ""}}],
		"assist": {"interval": 5.0, "still_seconds": 0.0, "first_delay": 1.0}})
	gs = _novo("f4b_dados_gs2", p)
	checar_igual(gs.desbloqueio("treadmill").cost, 123.0, "mudar o custo no JSON muda o preço")
	checar_igual(gs.assistido_intervalo(), 5.0, "mudar o interval no JSON muda o ritmo")
	_liberar(gs)


func _teste_assistido_ritmo() -> void:
	var gs := _novo("f4b_ritmo")
	checar_igual(gs.assistido_estado(), "off", "começa off")
	var estados := []
	gs.assistido_mudou.connect(func(e): estados.append(e))
	gs.definir_assistido(true)
	_passar(gs, 60.0)
	checar_igual(gs.assist_socos_total, 40, "60 s segurando: 40 auto-socos (1 a cada 1,5 s)")
	checar_igual(gs.auto_socos_total, 40, "auto_socos_total também conta")
	checar_igual(estados, ["active"], "sinal só quando muda")
	var gs2 := _novo("f4b_ritmo2")
	gs2.definir_assistido(true)
	_passar(gs2, 0.5)
	checar_igual(gs2.assist_socos_total, 0, "0,5 s: nada")
	_passar(gs2, 0.2)
	checar_igual(gs2.assist_socos_total, 1, "1º soco em 0,6 s")
	_passar(gs2, 1.2)
	checar_igual(gs2.assist_socos_total, 1, "próximo só aos 2,1 s")
	_passar(gs2, 0.4)
	checar_igual(gs2.assist_socos_total, 2, "2º soco")
	var gs3 := _novo("f4b_ritmo3")
	for i in 20:
		gs3.definir_assistido(true)
		_passar(gs3, 0.3)
		gs3.definir_assistido(false)
		_passar(gs3, 0.2)
	checar_igual(gs3.assist_socos_total, 0, "Shift batido rápido: 0 socos")
	var gs4 := _novo("f4b_ritmo4")
	var antes: float = gs4.atributos.strength
	gs4.auto_socar()
	checar(gs4.atributos.strength > antes, "soco automático treina o atributo do foco")
	for g in [gs, gs2, gs3, gs4]:
		_liberar(g)


func _teste_assistido_mao_parada() -> void:
	var gs := _novo("f4b_mao")
	gs.definir_assistido(true)
	for i in 120:  # 30 s clicando a cada 0,25 s
		gs.clicar()
		gs.tick(0.25)
	checar_igual(gs.assist_socos_total, 0, "clicando sem parar: assistido nunca soca")
	checar_igual(gs.assistido_estado(), "waiting", "estado waiting")
	_passar(gs, 0.5)
	checar_igual(gs.assist_socos_total, 0, "0,5 s depois do último clique: ainda nada")
	_passar(gs, 0.7)
	_passar(gs, 0.0)
	checar_igual(gs.assist_socos_total, 1, "1º auto-soco ~1,2 s depois do último clique")
	checar_igual(gs.assistido_estado(), "active", "estado active")
	_liberar(gs)


func _teste_assistido_bloqueios() -> void:
	var gs := _novo("f4b_bloq")
	gs.definir_assistido(true)
	gs.definir_modal(true)
	_passar(gs, 10.0)
	checar_igual(gs.assist_socos_total, 0, "janela aberta: 0 socos")
	gs.definir_modal(false)
	gs.luta = {"x": 1}
	_passar(gs, 10.0)
	checar_igual(gs.assist_socos_total, 0, "luta: 0 socos")
	gs.luta = {}
	gs.fim = {"kind": "retire"}
	_passar(gs, 10.0)
	checar_igual([gs.assist_socos_total, gs.assistido_estado()], [0, "off"], "tela de fim: 0 socos")
	gs.fim = {}
	_passar(gs, 0.5)
	checar_igual(gs.assist_socos_total, 0, "ao voltar, não acumulou socos para depois")
	_liberar(gs)


func _teste_assistido_metronomo() -> void:
	var gs := _novo("f4b_metro")
	gs.definir_assistido(true)
	gs.nivel_metronomo = 1
	_passar(gs, 20.0)
	checar_igual(gs.assist_socos_total, 0, "com Metrônomo o assistido não soca")
	checar_igual(gs.assistido_estado(), "metronome", "estado metronome")
	checar_igual(gs.auto_socos_total, 16, "só os socos do Metrônomo (1,2 s)")
	var gs2 := _novo("f4b_metro2")
	gs2.definir_assistido(true)
	_passar(gs2, 0.5)
	gs2.dinheiro = 1.0e9
	gs2.comprar_metronomo()
	checar_igual(gs2.assistido_estado(), "metronome", "comprar corta o assistido no mesmo quadro")
	_liberar(gs)
	_liberar(gs2)


func _teste_assistido_foco_janela() -> void:
	var gs := _novo("f4b_janela")
	gs.definir_assistido(true)
	gs._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	checar(not gs.assistido_segurando(), "perder o foco da janela solta o Shift")
	_passar(gs, 10.0)
	checar_igual(gs.assist_socos_total, 0, "sem socos depois de perder o foco")
	_liberar(gs)
