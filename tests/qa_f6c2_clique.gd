extends SceneTree
## QA 6c2: clique real no mural da parede (garagem/academia), Esc, janelas, tela de fim.
const CONFIG := "res://data/config.json"
const LOOK := {"skin": "skin_5", "hair_color": "black", "hair_style": "volume", "shorts_color": "yellow", "top": "tank", "top_color": "blue", "headband": "band", "headband_color": "red", "socks": "on"}
var gs: Node
var _cena: Control
var falhas := 0

func _init() -> void:
	_main.call_deferred()
func _esperar(s: float) -> void:
	await create_timer(s).timeout
func _ok(c: bool, msg: String) -> void:
	print(("PASS  " if c else "FAIL  ") + msg)
	if not c:
		falhas += 1
func _setup(local: String, n_roster: int) -> void:
	if _cena != null:
		for p in _cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		_cena.queue_free()
		_cena = null
		await _esperar(0.2)
	gs.inicializar("user://test/qa_clique/", CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	gs.escola["mentors"] = ["first"]
	gs.discipulo = {"name": "Tati Gancho", "look": LOOK.duplicate(), "campaign": 3}
	var ros: Array = [{"campaign": 1, "kind": "first", "name": "John Bullet", "look": null, "end": "retire", "wins": 3, "belt": true, "art": "", "opponent": "", "legacy_gained": 0, "honor": 15}]
	for i in n_roster - 1:
		ros.append({"campaign": i + 2, "kind": "disciple", "name": "Disc %d" % (i + 2), "look": LOOK.duplicate(), "end": "defeat", "wins": 2, "belt": false, "art": "", "opponent": "opp_tank", "legacy_gained": 0, "honor": 0})
	gs.escola["roster"] = ros if n_roster > 0 else []
	gs.permanente = {"legacy_total": 12, "career_number": 3, "careers_finished": 2, "best_wins": 3, "belts_won": 1, "arts_unlocked": (["boxing", "bjj"] if local == "gym" else []), "last_art": "boxing"}
	gs.atributos = {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
	gs.treino = 1234.0
	if local == "gym":
		gs.local_id = "gym"
		gs.cinturao = true
		gs.indice_escada = 4
		gs._gravar_marco("cena_primeira_academia", {}, false)
	gs.arte_id = "boxing"
	gs.modal_aberto = false
	_cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_cena)
	await _esperar(0.6)

func _clicar(p: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = p * 2.0
	ev.global_position = ev.position
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _esperar(0.4)

func _e(n: Node, nome: String) -> bool:
	return n != null and n.get_script() != null and str(n.get_script().resource_path).ends_with(nome + ".gd")

func _tecla(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _esperar(0.4)

func _main() -> void:
	gs = root.get_node("GameState")
	await process_frame
	for local in ["garage", "gym"]:
		await _setup(local, int(OS.get_environment("QA_N")) if OS.get_environment("QA_N") != "" else 3)
		var fl: Node = _cena.get_node("Fluxo")
		var sala: Node = _cena.get_node("Sala")
		var mr: Rect2 = sala._mural_rect
		var centro := mr.position + mr.size / 2.0
		await _clicar(centro)
		_ok(_e(fl.janela, "janela_mural"), local + ": clique no mural abre a janela")
		if OS.get_environment("QA_SHOT") != "":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("QA_SHOT") + local + ".png")
		await _tecla(KEY_ESCAPE)
		_ok(not (_e(fl.janela, "janela_mural")) and not gs.acoes_bloqueadas(), local + ": Esc fecha o mural e libera o jogo (janela=%s)" % str(fl.janela))
		# clique nas bordas do rect
		await _clicar(mr.position + Vector2(1, 1))
		_ok(_e(fl.janela, "janela_mural"), local + ": canto de cima do mural abre")
		await _tecla(KEY_ESCAPE)
		# janela da loja aberta: nao abre o mural
		fl.abrir_previa()
		await _esperar(0.3)
		var antes: Node = fl.janela
		await _clicar(centro)
		_ok(fl.janela == antes, local + ": com a previa aberta o clique no mural nao abre outra janela")
		fl.fechar_tudo() if fl.has_method("fechar_tudo") else fl._fechar_tudo()
		await _esperar(0.3)
		# tecla repetida: clique duplo rapido nao empilha
		await _clicar(centro)
		await _clicar(centro)
		var n_mural := 0
		for c in _cena.find_children("*", "", true, false):
			if _e(c, "janela_mural"):
				n_mural += 1
		_ok(n_mural == 1, local + ": clique duplo: 1 janela de mural (%d)" % n_mural)
		await _tecla(KEY_ESCAPE)
		# hover texto
		var t: String = sala._texto_parede(centro)
		_ok(t.begins_with("MURAL"), local + ": hover = " + t.replace("\n", " / "))
		# fim pendente: botao MURAL abre e volta ao fim
		gs.indice_escada = 2
		gs.aposentar()
		await _esperar(0.5)
		_ok(_e(fl.janela, "janela_fim"), local + ": tela de fim aberta")
		fl.abrir_mural()
		await _esperar(0.4)
		_ok(_e(fl.janela, "janela_mural"), local + ": MURAL do fim abre")
		fl._fechar_mural()
		await _esperar(0.4)
		_ok(_e(fl.janela, "janela_fim"), local + ": fechar o mural volta para o fim")
		# comprar o hall pelo botao
		gs.escola["honor"] = 100
		fl.abrir_mural()
		await _esperar(0.4)
		var botoes: Array = fl.janela.find_children("*", "Button", true, false)
		var comprou := false
		for b in botoes:
			if b is Button and not b.disabled and b.visible and b.get_parent() != null and str(b.name).begins_with("Hall"):
				comprou = true
		print("  botoes hall: ", botoes.map(func(b): return str(b.name)).filter(func(nm): return nm.begins_with("Hall") or nm.begins_with("Comprar")))
		fl._fechar_mural()
		await _esperar(0.3)
	print("FALHAS: ", falhas)
	if _cena != null:
		for p in _cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		_cena.queue_free()
	await _esperar(0.3)
	quit(1 if falhas > 0 else 0)
