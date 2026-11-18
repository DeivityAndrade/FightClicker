extends SceneTree
## QA 6d: chegada a academia SEM o John (o ultimo que passou o posto traz o caixote). Mesmo harness de qa_f6d_cenas.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_cenas.gd -- p=1,2 [so=...]
##   p=A,B : indices (LOOKS) do 1o discipulo (vira mentor) e do 2o (joga). APPDATA temporario! Save de teste em user://test/qa6d/
## so= lista (virgula) de blocos: s1,cria,s2,gar,s2b,gym,saida,luta,mural,gsaida (padrao: todos)
const PASTA := "user://test/qa6dg/"
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

func sucessao_rapida(i: int, nome: String) -> void:
	gs.atributos = {"strength": 50.0, "agility": 50.0, "endurance": 50.0}
	gs.aposentar()
	await esperar(0.6)
	gs.receber_discipulo()
	await esperar(0.8)
	if gs.sucessao_estado() == "scene_1":
		cena_ui().player.pular()
		await esperar(0.8)
	aplicar_look(i)
	gs.definir_rascunho("name", nome)
	var tl := janela_criar()
	if tl != null:
		tl._confirmar()
	var t := 0.0
	while gs.sucessao_estado() != "none" and t < 12.0:
		await esperar(0.1); t += 0.1
	await esperar(0.6)

func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6d_qa_"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("p="):
			var pp := a.substr(2).split(",")
			A = int(pp[0]); B = int(pp[1])
	tag = "g%d%d" % [A, B]
	await process_frame
	await novo_jogo()
	await abrir()
	await sucessao_rapida(A, "Aurelio")
	await sucessao_rapida(B, "Bruno")
	await sucessao_rapida(3 if A != 3 else 4, "Caio")
	print("campanha ", gs.numero_carreira(), " saida_devida=", gs.saida_devida())
	var t := 0.0
	while not gs.saida_tocando() and t < 40.0:
		await esperar(0.25); t += 0.25
	print("saida tocando=", gs.saida_tocando(), " t=", t)
	await gravar("saida_gar_c4", func() -> bool: return gs.saida_tocando(), 0.3, 25.0, SALA, 2, 8, 2)
	await esperar(1.0)
	print("mentores: ", gs.mentores_na_sala())
	await foto("gar_sem_john", Rect2i(0, 0, 640, 360), 2)
	gs.cinturao = true
	gs.dinheiro = 1.0e9
	gs.mudar()
	print("cena gym: ", gs.cena_sala, " elenco=", gs.elenco_primeira_academia())
	await gravar("gym_chegada_sem_john", func() -> bool: return gs.cena_sala != "", 0.25, 30.0, SALA, 2, 8, 2)
	await esperar(1.5)
	var fl: Node = cena.get_node("Fluxo")
	if fl.janela != null and fl.janela.has_method("_escolher"):
		fl.janela._escolher(gs.academia.ids_artes()[0])
	await esperar(1.5)
	await foto("gym_sem_john", Rect2i(0, 0, 640, 360), 2)
	await fechar()
	quit(0)
