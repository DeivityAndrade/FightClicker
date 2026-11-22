extends SceneTree
## QA 8a1: lutas REAIS (relogio de verdade, sem pular o tempo) com capturas: cinturao erguido, fala de depois do James (caido/cansado/de pe),
## sinais das passivas, balao contra letreiros/HUD. Janela: --resolution 1280x720 --position 1950,40 --max-fps 30.
## Uso: godot --path <pasta> --resolution 1280x720 --position 1950,40 --max-fps 30 --script res://tests/qa_f8a1_real.gd -- --saida <pasta> [--so a,b]
const PASTA := "user://test/qa8a1real/"
const TODAS := ["boxing", "bjj", "muay_thai"]
var gs: Node
var _cena: Control = null
var saida := ""
var so: Array = []
var falhas := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		if args[i] == "--saida" and i + 1 < args.size():
			saida = args[i + 1]
			i += 1
		elif args[i] == "--so" and i + 1 < args.size():
			so = Array(args[i + 1].split(","))
			i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(saida)
	gs = root.get_node("GameState")
	await process_frame
	await _rodar()
	print("QA_REAL falhas=", falhas)
	await create_timer(0.4).timeout
	quit(1 if falhas > 0 else 0)


func _quer(n: String) -> bool:
	return so.is_empty() or n in so


func _ok(c: bool, msg: String) -> void:
	print(("PASS  " if c else "FAIL  ") + msg)
	if not c:
		falhas += 1


func _esp(s: float) -> void:
	await create_timer(s).timeout


func _adv(i: int) -> Dictionary:
	return gs.lutas.adversarios[i]


func _arr_adv(idx: int) -> Array:
	var o := _adv(idx)
	var a: Array = [o.strength, o.agility, o.endurance]
	if not (o.get("passive", {}) as Dictionary).is_empty():
		a.append(o.passive)
	return a


func _atr(opp: Dictionary, f: Array) -> Dictionary:
	return {"strength": opp.strength * f[0], "agility": opp.agility * f[1], "endurance": opp.endurance * f[2]}


func _montar(arte: String, idx: int, passiva: int, rival: Dictionary) -> void:
	if _cena != null:
		for p in _cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		_cena.queue_free()
		_cena = null
	gs.definir_assistido(false)
	gs.inicializar(PASTA, "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 1
	gs.pular_abertura()
	gs.atributos = {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
	gs.treino = 800.0
	gs.permanente = {"legacy_total": 12, "career_number": 2, "careers_finished": 1, "best_wins": 2, "belts_won": 0, "arts_unlocked": [], "last_art": ""}
	gs._recalcular_bonus()
	gs.indice_escada = idx
	gs.cinturao = true
	gs.local_id = "gym"
	gs.permanente["arts_unlocked"] = TODAS.duplicate()
	gs.permanente["last_art"] = arte
	gs.arte_id = arte
	gs.arte_segundos = 0.0
	gs._atualizar_traco()
	gs.aparelhos_montados_ids = ["punching_bag", "treadmill", "jump_rope"] + (["kick_bag"] if arte == "muay_thai" else [])
	gs.foco = "kick_bag" if arte == "muay_thai" else "punching_bag"
	gs.permanente["passive_wins"] = {arte: 3}
	gs.permanente["passives_unlocked"] = [arte]
	gs.permanente["last_passive"] = {arte: passiva}
	gs.passiva_carreira = passiva
	gs._academia._atualizar_passiva()
	gs.risco_hud_ativo = false
	gs.escola["rival"] = rival.duplicate()
	gs.rival_spoke = {"before": true, "after": false} if rival.get("pular_antes", false) else {"before": false, "after": false}


## Procura um resultado do motor (mesma luta que o jogo vai sortear com `gs.rng.seed = k`).
func _achar(idx: int, tat: String, pred: Callable, fatores: Array = []) -> Dictionary:
	var opp := _adv(idx)
	var lista: Array = fatores if not fatores.is_empty() else [[1.0, 1.0, 1.0], [1.2, 1.2, 1.2], [0.9, 0.9, 0.9], [1.5, 0.8, 1.5],
		[0.8, 1.5, 0.8], [1.2, 1.5, 1.0], [1.0, 1.0, 1.5], [1.5, 1.0, 1.0], [1.5, 1.5, 1.0], [2.0, 2.0, 1.0], [0.8, 0.8, 0.8], [1.1, 1.1, 1.1],
		[0.6, 0.6, 0.6], [0.4, 0.4, 0.4], [3.0, 3.0, 3.0]]
	for f in lista:
		var atr := _atr(opp, f)
		for k in range(1, 400):
			var r := RandomNumberGenerator.new()
			r.seed = k
			var res: Dictionary = gs.motor.lutar([atr.strength, atr.agility, atr.endurance], _arr_adv(idx), tat, int(r.randi()), true)
			if bool(pred.call(res)):
				return {"atr": atr, "k": k, "res": res}
	return {}


func _abrir_luta(arte: String, idx: int, tat: String, ach: Dictionary, rival: Dictionary = {}, passiva: int = 1) -> Node:
	_montar(arte, idx, passiva, rival)
	gs.atributos = ach.atr.duplicate()
	gs.definir_tatica(tat)
	_cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_cena)
	await process_frame
	await _esp(0.5)
	gs.rng.seed = int(ach.k)
	var fluxo: Node = _cena.get_node("Fluxo")
	fluxo.abrir_previa()
	await _esp(0.3)
	fluxo.janela.lutar_pedido.emit()
	await _esp(0.15)
	return fluxo.tela


func _snap(nome: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(saida.path_join(nome + ".png"))
	print("CAP ", nome)


func _pular_pre(tela: Node) -> void:
	if tela._pre == "entrada":
		tela._finalizar_entrada()
	if tela._pre == "falas":
		tela._encerrar_falas()


func _rect_ou_vazio(sp: Sprite2D) -> Rect2:
	if sp == null or not sp.visible or sp.texture == null or sp.modulate.a < 0.05:
		return Rect2()
	var tam: Vector2 = sp.texture.get_size() * sp.global_scale
	return Rect2(sp.global_position - tam / 2.0, tam)


## Confere programaticamente o balao ativo contra HUD, letreiros e sinais. Devolve texto de problemas.
func _conferir_balao(tela: Node) -> String:
	var b: Node = tela._balao
	if not b.ativo():
		return "sem balao"
	var r: Rect2 = b.retangulo_total()
	var p := ""
	if r.position.y < 46.0:
		p += " cobre HUD(y=%.0f)" % r.position.y
	if not Rect2(0, 0, 640, 360).encloses(r):
		p += " fora da tela"
	var caixas: Dictionary = {"ko": tela._banner_ko, "spin": tela._banner_spin, "sub": tela._banner_sub_img}
	for k in tela._opp_sinais:
		caixas["sinal_" + str(k)] = tela._opp_sinais[k]
	for k in tela._banners_fim:
		caixas["fim_" + str(k)] = tela._banners_fim[k]
	for k in caixas:
		var rr := _rect_ou_vazio(caixas[k])
		if rr.size != Vector2.ZERO and rr.intersects(r):
			p += " sobrepoe " + str(k)
	for lb in [tela._banner, tela._banner_sub]:
		if lb.visible and lb.text != "" and lb.modulate.a > 0.05:
			if Rect2(lb.global_position, lb.get_combined_minimum_size() * lb.scale).intersects(r):
				p += " sobrepoe texto '%s'" % lb.text
	return "r=%s%s" % [str(r), p if p != "" else " OK"]


# ---------------------------------------------------------------------------------------------
func _rodar() -> void:
	# (a) cinturao erguido depois de vencer o James, nas 3 artes
	for arte in TODAS:
		if not _quer("belt_" + arte):
			continue
		_montar(arte, 9, 1, {})
		var ach := _achar(9, "aggressive", func(r: Dictionary) -> bool: return bool(r.win))
		if arte != "boxing":
			ach = _achar(9, "defensive", func(r: Dictionary) -> bool: return bool(r.win))
		_ok(not ach.is_empty(), "achei vitoria contra o James com %s" % arte)
		if ach.is_empty():
			continue
		var tela: Node = await _abrir_luta(arte, 9, "aggressive" if arte == "boxing" else "defensive", ach, {"met": 1, "school_wins": 0, "james_wins": 1, "pular_antes": true})
		_pular_pre(tela)
		var feito := 0
		var guarda := 0.0
		while not tela.finalizada and guarda < 70.0:
			await process_frame
			guarda += 0.034
			if tela._outro == 1 and tela._balao.ativo() and tela._balao.texto_completo() and not _quer("nada"):
				pass
			if tela._cinturao != null and tela._cinturao.visible and feito == 0:
				feito = 1
				await _esp(1.0)
				print("BELT ", arte, " estado jogador=", tela._l[0].estado, " sprite=", tela._l[0].spr.nome_sprite, " cinturao pos=", tela._cinturao.position, " base=", tela._l[0].base)
				await _snap("belt_%s_1" % arte)
				await _esp(1.5)
				await _snap("belt_%s_2" % arte)
				feito = 2
		_ok(feito >= 1, "%s: o cinturao apareceu na luta real" % arte)
	# (b) fala de depois quando o James PERDE: por K.O. e por pontos; e quando VENCE
	var casos := [
		["depois_ko", "aggressive", func(r: Dictionary) -> bool: return bool(r.win) and bool(r.ko)],
		["depois_pontos", "defensive", func(r: Dictionary) -> bool: return bool(r.win) and not bool(r.ko)],
		["depois_venceu", "aggressive", func(r: Dictionary) -> bool: return not bool(r.win)],
	]
	for c in casos:
		if not _quer(str(c[0])):
			continue
		_montar("boxing", 9, 1, {})
		var ach: Dictionary = _achar(9, c[1], c[2])
		if ach.is_empty() and c[0] != "depois_venceu":
			ach = _achar(9, "counter", c[2])
		_ok(not ach.is_empty(), "%s: achei a luta" % c[0])
		if ach.is_empty():
			continue
		print("LUTA ", c[0], " finish=", ach.res.get("finish", ""), " ko=", ach.res.get("ko", false), " t_end=", ach.res.get("t_end", 0), " win=", ach.res.win)
		var tela: Node = await _abrir_luta("boxing", 9, c[1], ach, {"met": 0, "school_wins": 0, "james_wins": 0})
		_pular_pre(tela)
		var visto := false
		var guarda := 0.0
		while not tela.finalizada and guarda < 70.0:
			await process_frame
			guarda += 0.034
			if tela._outro == 1 and tela._balao.ativo() and tela._balao.texto_completo() and not visto:
				visto = true
				var info := "James estado=%s sprite=%s frame=%d pos=%s | %s" % [tela._l[1].estado, tela._l[1].spr.nome_sprite, tela._l[1].spr.frame, tela._l[1].spr.position, _conferir_balao(tela)]
				print("DEPOIS ", c[0], ": ", info)
				await _snap(str(c[0]))
		_ok(visto, "%s: a fala de depois tocou" % c[0])
	# (c) sinais em lutas reais
	var sinais := [
		["sinal_bigorna", "boxing", 6, "aggressive", "block", 1],
		["sinal_estaca", "bjj", 7, "aggressive", "block", 2],
		["sinal_sabao", "muay_thai", 8, "defensive", "block", 2],
		["sinal_james", "boxing", 9, "aggressive", "closed", 1],
	]
	for s in sinais:
		if not _quer(str(s[0])):
			continue
		_montar(str(s[1]), int(s[2]), int(s[5]), {})
		var ach := _achar(int(s[2]), str(s[3]), func(r: Dictionary) -> bool: return int(r.get("opp_blocks", 0)) >= 1 or s[0] == "sinal_james")
		if ach.is_empty():
			ach = _achar(int(s[2]), str(s[3]), func(r: Dictionary) -> bool: return true)
		var tela: Node = await _abrir_luta(str(s[1]), int(s[2]), str(s[3]), ach, {"met": 1, "school_wins": 0, "james_wins": 1, "pular_antes": true}, int(s[5]))
		_pular_pre(tela)
		var n := 0
		var guarda := 0.0
		var vistos := {}
		while not tela.finalizada and guarda < 70.0:
			await process_frame
			guarda += 0.034
			for k in tela._opp_sinais:
				var sp: Sprite2D = tela._opp_sinais[k]
				if sp.visible and sp.modulate.a > 0.6 and not vistos.has(k):
					vistos[k] = true
					await _esp(0.15)
					n += 1
					await _snap("%s_%s" % [s[0], k])
					print("SINAL ", s[0], " ", k, " t=%.2f" % tela._clock, " | ", _conferir_balao(tela) if tela._balao.ativo() else "sem balao")
			if tela._outro == 1 or tela._clock > 12.0:
				break
		print("SINAIS ", s[0], " vistos=", vistos.keys())
