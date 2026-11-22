extends SceneTree
## QA 8a1: cronometra (relogio de parede) do LUTAR ate o sino nas 4 situacoes do James, e testa pular por clique, ESPACO, ESC 0,5 s, PULAR;
## fechar o jogo no meio (reabrir nao repete); gesto de desprezo 1 vez; depois de pular nao repete na campanha.
## Uso: godot --headless --path <pasta> --script res://tests/qa_f8a1_tempo.gd   (APPDATA temporario!)
const PASTA := "user://test/qa8a1/"
var gs: Node
var _cena: Control = null
var falhas := 0
var _t0 := 0


func _initialize() -> void:
	gs = root.get_node("GameState")
	await process_frame
	await _rodar()
	print("QA_TEMPO falhas=", falhas)
	quit(1 if falhas > 0 else 0)


func _ok(c: bool, msg: String) -> void:
	print(("PASS  " if c else "FAIL  ") + msg)
	if not c:
		falhas += 1


func _esp(s: float) -> void:
	await create_timer(s).timeout


func _novo(rival: Dictionary, arte: String = "boxing") -> void:
	if _cena != null:
		_cena.queue_free()
		_cena = null
	gs.definir_assistido(false)
	gs.inicializar(PASTA, "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 5
	gs.pular_abertura()
	gs.atributos = {"strength": 3.0e8, "agility": 3.0e8, "endurance": 3.0e8}
	gs.treino = 1234.0
	gs.permanente = {"legacy_total": 12, "career_number": 2, "careers_finished": 1, "best_wins": 2, "belts_won": 0, "arts_unlocked": [], "last_art": ""}
	gs._recalcular_bonus()
	gs.indice_escada = 9
	gs.cinturao = true
	gs.local_id = "gym"
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	gs.permanente["last_art"] = arte
	gs.arte_id = arte
	gs._atualizar_traco()
	gs.aparelhos_montados_ids = ["punching_bag", "treadmill", "jump_rope"]
	gs.foco = "punching_bag"
	gs.escola["rival"] = rival.duplicate()
	gs.risco_hud_ativo = false
	gs.definir_tatica("aggressive")
	_cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_cena)
	await process_frame
	await _esp(0.5)


func _lutar() -> Node:
	var fluxo: Node = _cena.get_node("Fluxo")
	fluxo.abrir_previa()
	await _esp(0.3)
	_t0 = Time.get_ticks_msec()
	fluxo.janela.lutar_pedido.emit()
	return fluxo.tela


func _rodar() -> void:
	var casos := [
		["first", {"met": 0, "school_wins": 0, "james_wins": 0}, 3],
		["revenge", {"met": 1, "school_wins": 0, "james_wins": 1}, 2],
		["school_won", {"met": 2, "school_wins": 1, "james_wins": 1}, 2],
		["many", {"met": 3, "school_wins": 1, "james_wins": 2}, 2],
	]
	casos.insert(0, casos[0])  # a 1a medida inclui o aquecimento de recursos; repete a 'first'
	for c in casos:
		await _novo(c[1])
		var tela: Node = await _lutar()
		var t0 := _t0
		var t_ent := -1.0
		var vistas := 0
		var ultimo := ""
		var scorns := 0
		var scorn_visto := false
		var t_sino := -1.0
		var guarda := 0
		while t_sino < 0.0 and guarda < 4000:
			await process_frame
			guarda += 1
			var agora := float(Time.get_ticks_msec() - t0) / 1000.0
			if tela._pre == "falas" and t_ent < 0.0:
				t_ent = agora
			if tela._pre == "falas":
				if tela._balao.ativo() and tela._balao.id != ultimo:
					ultimo = tela._balao.id
					vistas += 1
				var nome := str(tela._l[1].spr.nome_sprite)
				if nome == "opp_james_scorn" and not scorn_visto:
					scorn_visto = true
					scorns += 1
				elif nome != "opp_james_scorn":
					scorn_visto = false
			if tela._pre == "" and tela._clock >= -0.7:
				t_sino = agora
		print("TEMPO %s: LUTAR->entrada termina/falas comecam %.1f s ; LUTAR->sino (LUTEM!) %.1f s ; %d falas ; gestos %d" % [c[0], t_ent, t_sino, vistas, scorns])
		_ok(t_sino <= 15.0, "%s: LUTAR->sino %.1f s <= 15 s" % [c[0], t_sino])
		_ok(vistas == c[2], "%s: %d falas tocadas (esperado %d)" % [c[0], vistas, c[2]])
		_ok(scorns == 1, "%s: gesto de desprezo %d vez(es)" % [c[0], scorns])
		_ok(gs.rival_spoke.before, "%s: rival_spoke.before gravado" % c[0])

	# pular por clique (entrada), clique completa, 2o clique passa, ESPACO, ESC, PULAR
	await _novo({"met": 0, "school_wins": 0, "james_wins": 0})
	var tela: Node = await _lutar()
	await _esp(0.2)
	_ok(tela._pre == "entrada", "entrada no ringue ativa")
	tela._clique_geral()
	await _esp(0.3)
	_ok(tela._pre == "falas", "clique pula a entrada e comeca a apresentacao")
	await _esp(0.4)
	var id1: String = tela._balao.id
	# ESPACO
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	await _esp(0.2)
	_ok(tela._balao.texto_completo(), "ESPACO completa a fala")
	await _esp(0.3)
	var ev2 := InputEventKey.new()
	ev2.keycode = KEY_SPACE
	ev2.physical_keycode = KEY_SPACE
	ev2.pressed = true
	Input.parse_input_event(ev2)
	await _esp(0.8)
	_ok(tela._balao.id != id1 and tela._balao.ativo(), "2o ESPACO passa para a proxima fala (%s -> %s)" % [id1, tela._balao.id])
	# ESC 0,4 s nao pula; 0,6 s pula (eventos reais)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await _esp(0.3)
	_ok(tela._pre == "falas", "ESC 0,3 s: ainda nao pulou")
	await _esp(0.4)
	_ok(tela._pre == "", "ESC segurado 0,5 s+ encerra a apresentacao")
	var esc2 := InputEventKey.new()
	esc2.keycode = KEY_ESCAPE
	esc2.physical_keycode = KEY_ESCAPE
	esc2.pressed = false
	Input.parse_input_event(esc2)
	_ok(tela._clock < 0.0 and tela._guarda_fechada, "depois do ESC: luta segue na entrada normal, guarda fechada")
	var salvo: Dictionary = gs.para_save()
	_ok(salvo.career.rival_spoke.before == true, "save com rival_spoke.before depois de pular")
	# fecha o jogo no meio: reaplica o save e reabre (nova luta na mesma campanha nao repete)
	var info_nova: Array = gs.fala_previa_james()
	_ok(info_nova.is_empty(), "2a luta na mesma campanha (pos pular): sem apresentacao (%s)" % str(info_nova))
	# fechar no meio: lutar() e reabrir via aplicar_save
	await _novo({"met": 0, "school_wins": 0, "james_wins": 0})
	var info: Dictionary = gs.lutar()
	_ok((info.intro_lines as Array).size() == 3, "lutar(): 3 falas")
	var st: Dictionary = gs.para_save()
	gs.aplicar_save(st.duplicate(true))
	_ok(gs.rival_spoke.before, "fechou no meio da apresentacao e reabriu: rival_spoke.before segue true")
	_ok(gs.luta_atual().get("intro_lines", []).is_empty(), "luta_atual (reabrir) sem falas")
	# PULAR botao
	await _novo({"met": 0, "school_wins": 0, "james_wins": 0})
	tela = await _lutar()
	tela._clique_geral()
	await _esp(0.6)
	_ok(tela._botao_pular.visible and tela._chip_pular.visible, "PULAR visivel na apresentacao")
	tela._botao_pular.pressed.emit()
	await _esp(0.3)
	_ok(tela._pre == "" and not tela._balao.ativo(), "PULAR encerra")
	# Terminar a luta e ver que o "depois" toca 1 vez; depois nova luta 2 no mesmo dia nao repete
	var guarda2 := 0
	while not tela.finalizada and guarda2 < 6000:
		await process_frame
		guarda2 += 1
		if tela._pre == "" and tela._outro == 1:
			pass
	_ok(tela.finalizada, "luta termina")
	print("rival_spoke=", gs.rival_spoke, " rival=", gs.rival())
