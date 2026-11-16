extends SceneTree
## QA 6c2: balao do mentor em cada sala e mentor, mural x pessoas/alvo. Janela real (--position 1950,40).
const CONFIG := "res://data/config.json"
const NO_COVER := Rect2(310, 180, 52, 94)
const UTIL := Rect2(132, 22, 375, 263)
const LOOK := {"skin": "skin_5", "hair_color": "black", "hair_style": "volume", "shorts_color": "yellow", "top": "tank", "top_color": "blue", "headband": "band", "headband_color": "red", "socks": "on"}
const LOOK_J := {"skin": "skin_3", "hair_color": "brown", "hair_style": "bun", "shorts_color": "green", "top": "none", "top_color": "white", "headband": "band", "headband_color": "red", "socks": "none"}
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

func _setup(local: String, quem: String, foco: String) -> void:
	if _cena != null:
		_cena.queue_free()
		_cena = null
	gs.inicializar("user://test/qa_balao/", CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	gs.escola["mentors"] = ["first"] if quem == "first" else []
	gs.discipulo = {"name": "Tati Gancho", "look": LOOK_J.duplicate(), "campaign": 3}
	gs.escola["roster"] = [
		{"campaign": 1, "kind": "first", "name": "John Bullet", "look": null, "end": "retire", "wins": 3, "belt": true, "art": "", "opponent": "", "legacy_gained": 0, "honor": 15},
		{"campaign": 2, "kind": "disciple", "name": "Beto Cruz", "look": LOOK.duplicate(), "end": "defeat", "wins": 3, "belt": true, "art": "", "opponent": "opp_tank", "legacy_gained": 0, "honor": 0}]
	gs.permanente = {"legacy_total": 12, "career_number": 3, "careers_finished": 2, "best_wins": 3, "belts_won": 1, "arts_unlocked": (["boxing", "bjj"] if local == "gym" else []), "last_art": "boxing"}
	gs.atributos = {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
	gs.treino = 1234.0
	if quem == "last":
		gs._gravar_marco("cena_saida_primeiro_mentor", {}, false)
	if local == "gym":
		gs.local_id = "gym"
		gs.cinturao = true
		gs.indice_escada = 4
		gs._gravar_marco("cena_primeira_academia", {}, false)
		gs.arte_id = "boxing"
	if foco != "":
		gs.foco = foco
	gs._recalcular_bonus()
	gs.modal_aberto = false
	_cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_cena)

func _main() -> void:
	gs = root.get_node("GameState")
	await process_frame
	for local in ["garage", "gym"]:
		for quem in ["first", "last"]:
			for foco in ["punching_bag", "treadmill", "jump_rope"]:
				_setup(local, quem, "punching_bag")
				await _esperar(0.6)
				var sala: Node = _cena.get_node("Sala")
				if foco != "punching_bag" and gs.dados.aparelho(foco).is_empty():
					continue
				var tag := "%s/%s/%s" % [local, quem, foco]
				var vis: bool = sala.mentor_visivel()
				_ok(vis, tag + ": mentor visivel (" + str(sala._mentor_quem) + ")")
				var speaker := "first" if quem == "first" else "last"
				for txt in ["foi mais longe que eu\nna garagem. bom.", "esperei muito\npor essa.", "lembro desse. me pegou\nde jeito. voce nao."]:
					gs.fala_pedida.emit(speaker, txt, "ml_t")
					await _esperar(0.2)
					_cena._balao.completar()
					await _esperar(0.1)
					var b: Node = _cena._balao
					if not b.ativo():
						_ok(false, tag + ": balao nao ativo")
						continue
					var r: Rect2 = b.retangulo_total()
					var cab: Array = sala.cabecas_a_evitar(speaker)
					var cobre := false
					for e in cab:
						if r.intersects(e):
							cobre = true
					_ok(not cobre, tag + ": balao sem cobrir cabeca registrada " + str(r))
					_ok(not r.intersects(NO_COVER), tag + ": balao fora do alvo")
					_ok(UTIL.encloses(r), tag + ": balao dentro da sala " + str(r))
					# mentor2, coach e lutador (rects reais)
					var pts := {"coach": sala.ponto_cabeca("coach"), "lutador": sala.cabeca_lutador(), "mentor": sala.cabeca_mentor()}
					if sala.mentor2_visivel():
						pts["mentor2"] = sala.cabeca_mentor2()
					for k in pts:
						var h: Vector2 = pts[k]
						_ok(not r.intersects(Rect2(h.x - 9.0, h.y, 18.0, 18.0)), tag + ": balao nao cobre a cabeca de " + k + " " + str(h))
					b.fechar_agora()
					await _esperar(0.2)
				# mural: nao cobre ninguem nem o alvo
				var mr: Rect2 = sala._mural_rect
				_ok(mr.size != Vector2.ZERO, tag + ": mural presente " + str(mr))
				_ok(not mr.intersects(NO_COVER), tag + ": mural fora do alvo")
				var pessoas := {"coach": sala.ponto_cabeca("coach"), "lutador": sala.cabeca_lutador(), "mentor": sala.cabeca_mentor()}
				if sala.mentor2_visivel():
					pessoas["mentor2"] = sala.cabeca_mentor2()
				for k in pessoas:
					var h2: Vector2 = pessoas[k]
					_ok(not mr.intersects(Rect2(h2.x - 9.0, h2.y, 18.0, 36.0)), tag + ": mural nao cobre " + k + " " + str(h2))
				var foto: Dictionary = gs.foto_antiga()
				print("  foto_antiga: ", foto, " modal=", gs.modal_aberto, " cena_sala=", gs.cena_sala, " escolha_arte=", gs.escolha_arte_pendente())
				if local == "gym" and quem == "first" and foco == "punching_bag":
					# captura
					await RenderingServer.frame_post_draw
					var img := root.get_texture().get_image()
					img.save_png(OS.get_environment("QA_OUT") + "balao_%s_%s.png" % [local, quem])
				break  # um foco basta (o foco muda o lutador, nao o mentor)
	print("FALHAS: ", falhas)
	if _cena != null:
		for p in _cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		_cena.queue_free()
	await _esperar(0.3)
	quit(1 if falhas > 0 else 0)
