extends SceneTree
## QA 6d item 1: toca as cenas com o discipulo montado na criacao e captura quadros ampliados.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_cenas.gd -- p=1,2 [so=...]
##   p=A,B : indices (LOOKS) do 1o discipulo (vira mentor) e do 2o (joga). APPDATA temporario! Save de teste em user://test/qa6d/
## so= lista (virgula) de blocos: s1,cria,s2,gar,s2b,gym,saida,luta,mural,gsaida (padrao: todos)
const PASTA := "user://test/qa6d/"
const CONFIG := "res://data/config.json"
const LOOKS := [
	{},
	{"skin": "skin_1", "hair_color": "black", "hair_style": "buzz", "shorts_color": "green", "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_5", "hair_color": "blond", "hair_style": "bun", "shorts_color": "blue", "top": "tank", "top_color": "white", "headband": "band", "headband_color": "red", "socks": "on"},
	{"skin": "skin_1", "hair_color": "platinum", "hair_style": "volume", "shorts_color": "black", "top": "tee", "top_color": "black", "headband": "band", "headband_color": "black", "socks": "on"},
	{"skin": "skin_5", "hair_color": "black", "hair_style": "short", "shorts_color": "white", "top": "tee", "top_color": "white", "headband": "band", "headband_color": "white", "socks": "on"},
	{"skin": "skin_3", "hair_color": "copper", "hair_style": "bun", "shorts_color": "purple", "top": "none", "top_color": "white", "headband": "band", "headband_color": "yellow", "socks": "on"},
	{"skin": "skin_2", "hair_color": "dark_brown", "hair_style": "volume", "shorts_color": "yellow", "top": "tank", "top_color": "yellow", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_4", "hair_color": "brown", "hair_style": "buzz", "shorts_color": "green", "top": "tee", "top_color": "green", "headband": "band", "headband_color": "green", "socks": "on"},
]
var gs: Node
var cena: Node
var out := ""
var tag := ""
var so: Array = []
var falhas := 0
var A := 1
var B := 2

func ok(c: bool, n: String) -> void:
	if not c: falhas += 1
	print("PASS  " if c else "FAIL  ", n)

func esperar(s: float) -> void:
	await create_timer(s).timeout

func quer(b: String) -> bool:
	return so.is_empty() or so.has(b)

func fechar() -> void:
	if cena != null:
		for p in cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		cena.queue_free()
		cena = null
		await process_frame

func novo_jogo() -> void:
	await fechar()
	gs.definir_assistido(false)
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 11
	gs.pular_abertura()
	gs.treino = 500.0

func abrir() -> void:
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.7)

func cena_ui() -> Node:
	for c in cena.get_children():
		if c.get_script() != null and str(c.get_script().get_global_name()) == "CenaUi":
			return c
	return null

func janela_criar() -> Node:
	var fl: Node = cena.get_node("Fluxo")
	if fl.janela != null and fl.janela.get_script() != null and str(fl.janela.get_script().get_global_name()) == "TelaCriarDiscipulo":
		return fl.janela
	return null

func cap() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func recorte(img: Image, r: Rect2i, k: int) -> Image:
	var c := img.get_region(r)
	c.resize(r.size.x * k, r.size.y * k, Image.INTERPOLATE_NEAREST)
	return c

func folha(quadros: Array, cols: int, nome: String) -> void:
	if quadros.is_empty(): return
	var w: int = quadros[0].get_width()
	var h: int = quadros[0].get_height()
	var rows := int(ceil(quadros.size() / float(cols)))
	var s := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	s.fill(Color(0.1, 0.1, 0.1))
	for i in quadros.size():
		s.blit_rect(quadros[i], Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	s.save_png(out + tag + "_" + nome + ".png")

# regiao da sala onde ficam os atores (porta em x=423, chao ate y~275)
const SALA := Rect2i(128, 96, 352, 192)

## Captura ate `cond` ficar falso (ou `max` s), a cada `passo`, e salva folhas de `lote` quadros.
func gravar(nome: String, cond: Callable, passo: float, maximo: float, regiao: Rect2i = SALA, k: int = 2, lote: int = 6, cols: int = 2) -> void:
	var Q: Array = []
	var t := 0.0
	while cond.call() and t < maximo:
		var img: Image = await cap()
		Q.append(recorte(img, regiao, k))
		await esperar(passo)
		t += passo
	var i := 0
	while i < Q.size():
		folha(Q.slice(i, i + lote), cols, "%s_%02d" % [nome, i / lote])
		i += lote
	print("gravado ", nome, " quadros=", Q.size(), " t=", t)

func foto(nome: String, regiao: Rect2i = Rect2i(0, 0, 640, 360), k: int = 2) -> void:
	var img: Image = await cap()
	recorte(img, regiao, k).save_png(out + tag + "_" + nome + ".png")

func aplicar_look(i: int) -> void:
	for campo in LOOKS[i]:
		var okk: bool = gs.definir_rascunho(campo, str(LOOKS[i][campo]))
		if not okk:
			print("AVISO definir_rascunho(", campo, ",", LOOKS[i][campo], ") recusado")

func olhar_discipulo(nome: String) -> void:
	# a tela de criacao: monta o look e fotografa
	var tela := janela_criar()
	ok(tela != null, "tela de criacao aberta (%s)" % nome)
	gs.definir_rascunho("name", nome)

func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6d_qa_"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("p="):
			var pp := a.substr(2).split(",")
			A = int(pp[0]); B = int(pp[1])
		elif a.begins_with("so="):
			so = Array(a.substr(3).split(","))
	tag = "p%d%d" % [A, B]
	await process_frame
	print("viewport ", root.get_texture().get_size())
	await novo_jogo()
	await abrir()
	gs.aposentar()
	await esperar(0.8)
	# ===== 1a sucessao =====
	ok(gs.receber_discipulo(), "RECEBER")
	if quer("s1"):
		await gravar("s1", func() -> bool: return gs.sucessao_estado() == "scene_1", 0.5, 30.0)
	else:
		var t := 0.0
		while gs.sucessao_estado() == "scene_1" and t < 40.0:
			await esperar(0.1); t += 0.1
	ok(gs.sucessao_estado() == "creating", "chegou na criacao (%s)" % gs.sucessao_estado())
	await esperar(0.8)
	aplicar_look(A)
	await esperar(0.5)
	print("rascunho A: ", gs.rascunho())
	if quer("cria"):
		await foto("cria_a", Rect2i(0, 0, 640, 360), 2)
	gs.definir_rascunho("name", "Aurelio")
	var tela := janela_criar()
	tela._confirmar()
	await esperar(0.05)
	if quer("s2"):
		await gravar("s2", func() -> bool: return gs.sucessao_estado() != "none", 0.3, 14.0, SALA, 2, 8, 2)
	else:
		var t2 := 0.0
		while gs.sucessao_estado() != "none" and t2 < 14.0:
			await esperar(0.1); t2 += 0.1
	await esperar(0.5)
	ok(gs.sucessao_estado() == "none", "S10: controle devolvido")
	var sala: Node = cena.get_node("Sala")
	if quer("gar"):
		await foto("gar_a_parado", Rect2i(0, 0, 640, 360), 2)
		gs.clicar()
		await gravar("gar_a_toques", func() -> bool: return true, 0.12, 1.2, SALA, 2, 12, 3)
		for i in 4:
			gs.clicar()
			await esperar(0.06)
		await gravar("gar_a_soco", func() -> bool: return true, 0.1, 1.0, SALA, 2, 12, 3)
		await esperar(2.0)
		await foto("gar_a_depois", Rect2i(0, 0, 640, 360), 2)
	# ===== 2a sucessao (A vira mentor em pe) =====
	gs.atributos = {"strength": 50.0, "agility": 50.0, "endurance": 50.0}
	gs.treino = 800.0
	await esperar(0.3)
	gs.aposentar()
	await esperar(0.8)
	ok(gs.receber_discipulo(), "RECEBER 2a")
	await esperar(1.0)
	ok(gs.sucessao_estado() == "creating", "2a: criacao direta (%s)" % gs.sucessao_estado())
	aplicar_look(B)
	await esperar(0.5)
	print("rascunho B: ", gs.rascunho())
	if quer("cria"):
		await foto("cria_b", Rect2i(0, 0, 640, 360), 2)
	gs.definir_rascunho("name", "Bruno")
	var tela2 := janela_criar()
	tela2._confirmar()
	await esperar(0.05)
	if quer("s2b"):
		await gravar("s2b_chegada", func() -> bool: return gs.sucessao_estado() != "none", 0.15, 8.0, SALA, 2, 8, 2)
	else:
		var t3 := 0.0
		while gs.sucessao_estado() != "none" and t3 < 10.0:
			await esperar(0.1); t3 += 0.1
	await esperar(0.6)
	ok(gs.sucessao_estado() == "none", "chegada curta terminou")
	print("mentores_na_sala: ", gs.mentores_na_sala())
	if quer("gar"):
		await foto("gar_b_mentores", Rect2i(0, 0, 640, 360), 2)
		await foto("gar_b_mentores_x4", Rect2i(200, 150, 220, 130), 4)
		# clique do discipulo B + 2o mentor
		for i in 3:
			gs.clicar()
			await esperar(0.07)
		await gravar("gar_b_soco", func() -> bool: return true, 0.1, 1.0, SALA, 2, 12, 3)
		# aparelhos (corda / esteira) se existirem
		for foco in ["jump_rope", "treadmill"]:
			if gs.definir_foco(foco):
				await esperar(0.6)
				gs.clicar()
				await gravar("gar_b_" + foco, func() -> bool: return true, 0.1, 1.0, SALA, 2, 12, 3)
		gs.definir_foco("punching_bag")
	# ===== academia: chegada com saco e caixote =====
	if quer("gym"):
		gs.cinturao = true
		gs.dinheiro = 1.0e9
		gs.mudar()
		ok(gs.cena_sala == "primeira_academia", "cena da academia pedida")
		await gravar("gym_chegada", func() -> bool: return gs.cena_sala != "", 0.25, 30.0, SALA, 2, 8, 2)
		await esperar(1.0)
		var fl: Node = cena.get_node("Fluxo")
		if fl.janela != null and fl.janela.has_method("_escolher"):
			fl.janela._escolher(gs.academia.ids_artes()[0])
		await esperar(1.5)
		await foto("gym_depois", Rect2i(0, 0, 640, 360), 2)
		await foto("gym_depois_x3", Rect2i(150, 130, 300, 160), 3)
		print("mentores gym: ", gs.mentores_na_sala())
		for i in 4:
			gs.clicar()
			await esperar(0.06)
		await gravar("gym_soco", func() -> bool: return true, 0.1, 1.0, SALA, 2, 12, 3)
	# ===== saida do John na academia =====
	if quer("saida"):
		gs._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
		var ts := 0.0
		while not gs.saida_tocando() and ts < 40.0:
			await esperar(0.25); ts += 0.25
		ok(gs.saida_tocando(), "saida (academia) tocando apos %.1fs" % ts)
		await gravar("saida_gym", func() -> bool: return gs.saida_tocando(), 0.3, 25.0, SALA, 2, 8, 2)
		await esperar(1.0)
		print("mentores apos saida: ", gs.mentores_na_sala())
		await foto("saida_gym_depois", Rect2i(0, 0, 640, 360), 2)
		await foto("saida_gym_depois_x3", Rect2i(150, 130, 300, 160), 3)
	# ===== luta =====
	if quer("luta"):
		await luta_ganha()
		await luta_perdida()
	# ===== mural =====
	if quer("mural"):
		var fl2: Node = cena.get_node("Fluxo")
		if fl2.janela == null:
			fl2.abrir_mural()
			await esperar(0.8)
			await foto("mural", Rect2i(0, 0, 640, 360), 2)
			fl2._fechar_mural()
			await esperar(0.3)
	await fechar()
	# ===== saida na garagem (jogo novo, sem academia) =====
	if quer("gsaida"):
		await novo_jogo()
		await abrir()
		await sucessoes_rapidas()
		gs._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
		var tg := 0.0
		while not gs.saida_tocando() and tg < 40.0:
			await esperar(0.25); tg += 0.25
		ok(gs.saida_tocando(), "saida (garagem) tocando apos %.1fs" % tg)
		await gravar("saida_gar", func() -> bool: return gs.saida_tocando(), 0.3, 25.0, SALA, 2, 8, 2)
		await esperar(1.0)
		print("mentores apos saida gar: ", gs.mentores_na_sala())
		await foto("saida_gar_depois", Rect2i(0, 0, 640, 360), 2)
		await foto("saida_gar_depois_x3", Rect2i(150, 130, 300, 160), 3)
		await fechar()
	print("FALHAS ", falhas)
	quit(1 if falhas > 0 else 0)

func sucessoes_rapidas() -> void:
	# 1a e 2a sucessao sem tocar quadro a quadro: pula a cena
	for par in [[A, "Aurelio"], [B, "Bruno"]]:
		gs.atributos = {"strength": 50.0, "agility": 50.0, "endurance": 50.0}
		gs.aposentar()
		await esperar(0.6)
		gs.receber_discipulo()
		await esperar(0.8)
		if gs.sucessao_estado() == "scene_1":
			cena_ui().player.pular()
			await esperar(0.8)
		aplicar_look(par[0])
		gs.definir_rascunho("name", par[1])
		var tl := janela_criar()
		if tl != null:
			tl._confirmar()
		var t := 0.0
		while gs.sucessao_estado() != "none" and t < 12.0:
			await esperar(0.1); t += 0.1
		await esperar(0.6)

func luta_ganha() -> void:
	var fl: Node = cena.get_node("Fluxo")
	gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
	fl.abrir_previa()
	await esperar(0.6)
	await foto("previa", Rect2i(0, 0, 640, 360), 2)
	if fl.janela == null:
		print("AVISO: previa nao abriu")
		return
	fl.janela.lutar_pedido.emit()
	await esperar(0.5)
	var tl: Node = fl.tela
	var vistos := {}
	var Q: Array = []
	var t := 0.0
	while tl.visible and t < 40.0:
		var img: Image = await cap()
		if int(t * 10) % 2 == 0:
			Q.append(recorte(img, Rect2i(0, 0, 640, 360), 1))
		vistos[str(tl._l[0].spr.nome_sprite)] = vistos.get(str(tl._l[0].spr.nome_sprite), 0) + 1
		await esperar(0.1)
		t += 0.1
		if gs.luta.is_empty() == false and t > 1.0 and tl._clock > float(gs.luta.result.t_end) + 0.5:
			break
	var i := 0
	while i < Q.size():
		folha(Q.slice(i, i + 12), 3, "luta_ganha_%02d" % (i / 12))
		i += 12
	print("poses vistas na luta ganha: ", vistos)
	await esperar(1.0)
	await foto("luta_fim", Rect2i(0, 0, 640, 360), 2)
	fl.tela.visible = fl.tela.visible
	print("luta ganha t=", t)
	var guard := 0
	while fl.janela != null and guard < 20:
		guard += 1
		if fl.janela.has_signal("continuar_pedido"):
			fl.janela.continuar_pedido.emit()
		else:
			break
		await esperar(0.5)

func luta_perdida() -> void:
	var fl: Node = cena.get_node("Fluxo")
	gs.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
	await esperar(0.5)
	if fl.janela != null:
		print("AVISO: janela aberta antes da luta perdida: ", fl.janela.get_script().get_global_name())
		return
	fl.abrir_previa()
	await esperar(0.6)
	if fl.janela == null:
		print("AVISO: previa 2 nao abriu")
		return
	fl.janela.lutar_pedido.emit()
	await esperar(0.5)
	var tl: Node = fl.tela
	var vistos := {}
	var Q: Array = []
	var t := 0.0
	while tl.visible and t < 40.0:
		var img: Image = await cap()
		if int(t * 10) % 2 == 0:
			Q.append(recorte(img, Rect2i(0, 0, 640, 360), 1))
		vistos[str(tl._l[0].spr.nome_sprite)] = vistos.get(str(tl._l[0].spr.nome_sprite), 0) + 1
		await esperar(0.1)
		t += 0.1
		if not gs.luta.is_empty() and t > 1.0 and tl._clock > float(gs.luta.result.t_end) + 0.5:
			break
	var i := 0
	while i < Q.size():
		folha(Q.slice(i, i + 12), 3, "luta_perdida_%02d" % (i / 12))
		i += 12
	print("poses vistas na luta perdida: ", vistos)
	await esperar(1.5)
	await foto("luta_perdida_fim", Rect2i(0, 0, 640, 360), 2)
