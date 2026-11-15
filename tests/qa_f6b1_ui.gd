extends SceneTree
## QA 6b1: joga a cena de passar o posto na cena principal real (janela), com entrada sintetica.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6b1_ui.gd
## Save SEMPRE em user://test/qa6b1_ui/ (nunca o real).

const PASTA := "user://test/qa6b1_ui/"
const CONFIG := "res://data/config.json"
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa6b1ui/"

var gs: Node
var DV: GDScript
var UT: GDScript
var cena: Node
var falhas := 0
var total := 0


func ok(c: bool, nome: String) -> void:
	total += 1
	if c:
		print("PASS  ", nome)
	else:
		falhas += 1
		print("FAIL  ", nome)


func esperar(s: float) -> void:
	await create_timer(s).timeout


func tecla(k: int, apertada: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = apertada
	Input.parse_input_event(ev)


func segurar(k: int, s: float) -> void:
	tecla(k, true)
	await esperar(s)
	tecla(k, false)
	await esperar(0.05)


func novo_jogo() -> void:
	fechar()
	DirAccess.make_dir_recursive_absolute(OUT.replace("C:/", "C:/"))
	gs.definir_assistido(false)
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 5
	gs.pular_abertura()
	gs.treino = 500.0


func fechar() -> void:
	if cena != null:
		for p in cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		cena.queue_free()
		cena = null
		await process_frame


func abrir() -> void:
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.5)


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


func shot(nome: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(OUT)
	img.save_png(OUT + nome + ".png")


func _initialize() -> void:
	gs = root.get_node("GameState")
	DV = load("res://ui/disc_visual.gd")
	UT = load("res://ui/ui_tema.gd")
	await process_frame
	var so := OS.get_cmdline_user_args()
	if so.has("frames"):
		await cenario_frames()
		await fechar()
		quit(0)
		return
	if so.has("arte"):
		await cenario_arte()
		await fechar()
		quit(1 if falhas > 0 else 0)
		return
	await cenario_fluxo()
	await cenario_pular_botao()
	await cenario_fechar_no_meio()
	await cenario_visual()
	await fechar()
	print("TOTAL %d FALHAS %d" % [total, falhas])
	quit(1 if falhas > 0 else 0)


func receber_pelo_botao() -> bool:
	var fl: Node = cena.get_node("Fluxo")
	var j: Node = fl.janela
	if j == null:
		return false
	var achou := false
	for b in j.find_children("*", "Button", true, false):
		var texto := ""
		for l in b.find_children("*", "Label", true, false):
			texto += str(l.text)
		if texto.to_upper().contains("DISC"):
			b.pressed.emit()
			achou = true
			break
	return achou


func cenario_fluxo() -> void:
	print("== fluxo e ESC ==")
	await novo_jogo()
	await abrir()
	gs.aposentar()
	await esperar(0.8)
	ok(receber_pelo_botao(), "botao do fim chama RECEBER")
	ok(gs.sucessao_estado() == "scene_1", "estado scene_1 depois do botao (%s)" % gs.sucessao_estado())
	var cu := cena_ui()
	await esperar(1.0)
	ok(cu.player.ativa, "cena tocando")
	# ESC curto (0,2 s) nao pula
	await segurar(KEY_ESCAPE, 0.2)
	ok(gs.sucessao_estado() == "scene_1", "ESC curto (0,2 s) nao pula")
	await esperar(0.3)
	# ESPACO 0,3 nao pula
	await segurar(KEY_SPACE, 0.3)
	ok(gs.sucessao_estado() == "scene_1", "ESPACO 0,3 s nao pula")
	# ESC 0,7 s pula
	var t0 := Time.get_ticks_msec()
	tecla(KEY_ESCAPE, true)
	var ate := 0.0
	var t_esc := Time.get_ticks_msec()
	while gs.sucessao_estado() == "scene_1" and ate < 2.0:
		await esperar(0.02)
		ate = float(Time.get_ticks_msec() - t_esc) / 1000.0
	tecla(KEY_ESCAPE, false)
	print("INFO ESC segurado: pulou depois de %.2f s" % ate)
	ok(gs.sucessao_estado() == "creating" and ate < 0.7, "ESC segurado >=0,5 s pula ate a criacao (%.2f s)" % ate)
	await esperar(0.6)
	var tela := janela_criar()
	ok(tela != null, "tela de criacao abriu")
	if tela == null:
		return
	await shot("criacao_abre")
	var mundo: Dictionary = cu.player.mundo()
	ok(bool(mundo.adereços.get("gloves", {}).get("visible", false)), "luvas no saco ao pular")
	# ESC na criacao
	await segurar(KEY_ESCAPE, 0.1)
	await segurar(KEY_ESCAPE, 1.2)
	await segurar(KEY_SPACE, 1.2)
	ok(janela_criar() != null and gs.sucessao_estado() == "creating", "ESC/ESPACO na criacao: nada acontece")
	# nome: 20 chars com numeros
	tela._nome.text = "A1B2C3D4E5F6G7H8I9J0"
	tela._nome.text_changed.emit(tela._nome.text)
	ok(gs.rascunho().name == "ABCDEFGHIJ" and tela._nome.text == "ABCDEFGHIJ", "digitar com numeros: filtrado (%s)" % gs.rascunho().name)
	tela._nome.text = "Ôzé Ção Ãéíóú Zz"
	tela._nome.text_changed.emit(tela._nome.text)
	print("INFO acentos -> '%s' (%d)" % [gs.rascunho().name, gs.rascunho().name.length()])
	ok(gs.rascunho().name.length() <= 14, "acentos: <= 14")
	tela._nome.text = ""
	tela._nome.text_changed.emit("")
	ok(gs.rascunho().name == "", "nome vazio no rascunho")
	tela._confirmar()
	ok(gs.sucessao_estado() == "creating" and gs.rascunho().name != "", "CONFIRMAR com nome vazio: nao passa, volta nome (%s)" % gs.rascunho().name)
	await esperar(0.3)
	await shot("criacao_vazio")
	# SORTEAR repetido 50x
	for i in 50:
		gs.sortear_rascunho()
	# cores: troca com as setas
	var skin0: String = gs.rascunho().look.skin
	tela._trocar("skin", 1)
	ok(gs.rascunho().look.skin != skin0, "seta de pele troca")
	for i in 6:
		tela._trocar("hair_color", -1)
		tela._trocar("shorts_color", 1)
	tela._nome.text = "Dani Cruzado"
	tela._nome.text_changed.emit(tela._nome.text)
	await esperar(0.3)
	var look: Dictionary = gs.rascunho().look.duplicate()
	# CONFIRMAR e parte 2
	var seg0: float = gs.segundos_campanha
	var tt := Time.get_ticks_msec()
	tela._confirmar()
	ok(gs.sucessao_estado() == "scene_2", "CONFIRMAR -> scene_2")
	var t := 0.0
	while gs.sucessao_estado() != "none" and t < 12.0:
		await esperar(0.02)
		t += 0.02
	var real := float(Time.get_ticks_msec() - tt) / 1000.0
	print("INFO parte 2: %.2f s reais ate o controle" % real)
	ok(real <= 6.8, "parte 2 devolve controle em <= 6,5 s (+tolerancia de frames): %.2f" % real)
	ok(janela_criar() == null, "janela de criacao fechou")
	await shot("pos_controle")
	ok(gs.discipulo.name == "Dani Cruzado", "nome gravado")
	ok(gs.segundos_campanha < 0.5 + (real - 0.0) * 0.0 + 0.2, "relogio da campanha so comecou no controle (%.2f)" % gs.segundos_campanha)
	ok(gs.sala_ativa(), "sala ativa")
	# 1o soco vale e John faz os toques com 'isso.'
	var r: Dictionary = gs.clicar()
	ok(not r.is_empty(), "1o soco vale")
	await esperar(0.15)
	var sala: Node = cena.get_node("Sala")
	await shot("toques_isso")
	await esperar(2.5)
	await shot("depois_isso")
	ok(sala.mentor_visivel(), "John sentado como mentor")
	# o visual do discipulo na garagem
	var cam = DV.nome_em_camadas(sala._lutador.nome_sprite)
	ok(cam != "" and sala._lutador.texture == DV.textura(cam, look), "garagem: o lutador usa o visual escolhido (%s)" % sala._lutador.nome_sprite)
	ok(sala._lutador.texture != UT.textura(sala._lutador.nome_sprite), "...e nao a folha padrao")
	# clicar 20 vezes: sem toques novos (1/min)
	var planos := [0]
	gs.toques_mentor_pedidos.connect(func(_p: Dictionary) -> void: planos[0] += 1)
	for i in 20:
		gs.clicar()
		await esperar(0.05)
	ok(planos[0] == 0, "cliques seguintes: sem novos toques")
	# lutar e ver o visual na luta
	var fl: Node = cena.get_node("Fluxo")
	gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
	fl.abrir_previa()
	await esperar(0.4)
	fl.janela.lutar_pedido.emit()
	await esperar(0.6)
	var tl: Node = fl.tela
	var spr: Node = tl._l[0].spr
	var cam2 = DV.nome_em_camadas(spr.nome_sprite)
	ok(cam2 != "" and spr.texture == DV.textura(cam2, look), "luta: lutador com o visual escolhido (%s)" % spr.nome_sprite)
	await shot("luta_visual")
	tl._clock = float(gs.luta.result.t_end) + 1.0
	await esperar(0.4)
	# retrato
	var ret = UT.textura_disc(UT.nome_retrato_jogador())
	ok(ret == DV.textura(DV.nome_em_camadas(UT.nome_retrato_jogador()), look), "retrato: visual escolhido")
	await esperar(1.0)


func cenario_pular_botao() -> void:
	print("== botao PULAR ==")
	await novo_jogo()
	await abrir()
	gs.aposentar()
	await esperar(0.6)
	receber_pelo_botao()
	var cu := cena_ui()
	await esperar(1.2)
	ok(cu._botao.visible, "botao PULAR visivel na parte 1")
	ok(cu._chip.visible and cu._chip.text == "SEGURE ESC: PULAR", "chip: '%s'" % cu._chip.text)
	cu._botao.pressed.emit()
	await esperar(0.35)
	ok(gs.sucessao_estado() == "creating", "PULAR leva a criacao")
	ok(not cu._botao.visible, "botao some na criacao")
	await esperar(0.5)
	var tela := janela_criar()
	ok(tela != null, "tela abriu")
	tela._confirmar()
	await esperar(1.0)
	ok(cu._botao.visible, "botao PULAR visivel na parte 2")
	var tp := Time.get_ticks_msec()
	cu._botao.pressed.emit()
	var t := 0.0
	while gs.sucessao_estado() != "none" and t < 2.0:
		await esperar(0.02)
		t = float(Time.get_ticks_msec() - tp) / 1000.0
	print("INFO pular parte 2: %.2f s" % t)
	ok(t <= 0.35, "PULAR na parte 2: estado S10 em <= 0,3 s (+frames) (%.2f)" % t)
	ok(gs.sala_ativa(), "sala ativa depois de pular")
	await esperar(0.4)
	var r: Dictionary = gs.clicar()
	await esperar(0.3)
	ok(not r.is_empty() and cena.get_node("Sala").mentor_visivel(), "clique vale e John mentor")
	await shot("pulou_s10")
	# ESC curto numa janela (aposentar) nao pula nada: abrir janela de aposentar e ESC curto
	await esperar(0.5)


func cenario_fechar_no_meio() -> void:
	print("== fechar o jogo em cada etapa ==")
	# Etapa 1: parte 1
	await novo_jogo()
	await abrir()
	gs.aposentar()
	await esperar(0.5)
	receber_pelo_botao()
	await esperar(3.0)
	gs.salvar()
	await fechar()
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	ok(gs.sucessao_estado() == "creating" and gs.marco("cena_primeira_sucessao"), "reabrir na parte 1: criacao (%s)" % gs.sucessao_estado())
	await abrir()
	await esperar(1.2)
	var cu := cena_ui()
	ok(janela_criar() != null, "tela de criacao aparece")
	ok(not cu.player.ativa, "a cena grande nao toca de novo")
	await shot("reaberto_criacao")
	var seg: float = gs.segundos_campanha
	await esperar(2.0)
	ok(gs.segundos_campanha == seg, "relogio parado com a criacao reaberta")
	janela_criar()._confirmar()
	await esperar(0.5)
	ok(cu.player.ativa and gs.sucessao_cena() == "chegada_discipulo", "depois do CONFIRMAR toca a chegada curta")
	var tt := Time.get_ticks_msec()
	var t := 0.0
	while gs.sucessao_estado() != "none" and t < 6.0:
		await esperar(0.02)
		t += 0.02
	print("INFO chegada (apos reabrir): %.2f s" % (float(Time.get_ticks_msec() - tt) / 1000.0))
	ok(gs.sucessao_estado() == "none", "chegada curta termina")
	# Etapa 2: parte 2 (depois do CONFIRMAR)
	await novo_jogo()
	await abrir()
	gs.aposentar()
	await esperar(0.5)
	receber_pelo_botao()
	await esperar(0.8)
	cena_ui().player.pular()
	await esperar(0.6)
	var tela := janela_criar()
	gs.definir_rascunho("name", "Zeca Pontaria")
	tela._confirmar()
	await esperar(1.2)
	gs.salvar()
	await fechar()
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	ok(gs.sucessao_estado() == "arriving" and gs.discipulo.name == "Zeca Pontaria", "reabrir na parte 2: arriving com o discipulo (%s)" % gs.sucessao_estado())
	await abrir()
	await esperar(1.0)
	ok(gs.sucessao_estado() == "none" and gs.sala_ativa(), "aplicou o final sem tocar e a campanha segue")
	ok(janela_criar() == null and not cena_ui().player.ativa, "sem tela e sem cena")
	ok(not gs.mentor_cumprimentou, "mentor_greeted continua false")
	var planos: Array = []
	gs.toques_mentor_pedidos.connect(func(p: Dictionary) -> void: planos.append(p))
	gs.clicar()
	ok(planos.size() == 1 and planos[0].cena == "", "1o clique: toques sem fala")
	await esperar(0.12)
	await shot("reaberto_toques_a")
	await esperar(0.2)
	await shot("reaberto_toques_b")
	await esperar(0.8)
	await shot("reaberto_parte2")
	var sala_t: Node = cena.get_node("Sala")
	print("INFO mentor pose: ", sala_t._mentor_pose, " visivel: ", sala_t.mentor_visivel())
	# Etapa 3: depois do return_control
	gs.salvar()
	await fechar()
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	await abrir()
	await esperar(0.6)
	ok(gs.sucessao_estado() == "none" and janela_criar() == null, "depois do return_control: jogo normal")
	# Etapa 4: sucessao seguinte: criacao + chegada curta + fechar na criacao
	gs.aposentar()
	await esperar(0.5)
	receber_pelo_botao()
	await esperar(0.8)
	ok(gs.sucessao_estado() == "creating" and gs.sucessao_cena() == "chegada_discipulo", "2a sucessao abre direto na criacao")
	ok(janela_criar() != null, "tela de criacao aberta")
	await shot("segunda_criacao")
	gs.salvar()
	await fechar()
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	await abrir()
	await esperar(1.0)
	ok(janela_criar() != null and gs.sucessao_estado() == "creating", "fechar na criacao da 2a: reabre na criacao")
	var tc := Time.get_ticks_msec()
	janela_criar()._confirmar()
	var tc_ok := 0.0
	while gs.sucessao_estado() != "none" and tc_ok < 6.0:
		await process_frame
		tc_ok = float(Time.get_ticks_msec() - tc) / 1000.0
	print("INFO chegada 2a sucessao: %.3f s do CONFIRMAR ao controle" % tc_ok)
	ok(tc_ok <= 2.5, "chegada curta <= 2,5 s reais (%.3f)" % tc_ok)
	await esperar(1.0)
	ok(gs.sucessao_estado() == "none", "chegada curta toca e termina")
	await shot("segunda_chegada_fim")


func cenario_visual() -> void:
	print("== visual: todas as cores sem erro ==")
	await novo_jogo()
	await abrir()
	var sala: Node = cena.get_node("Sala")
	var combos := 0
	var distintos := {}
	for skin in gs.disciples.opcoes_ativas("skin"):
		for cab in gs.disciples.opcoes_ativas("hair_color"):
			for cal in gs.disciples.opcoes_ativas("shorts_color"):
				var look: Dictionary = gs.disciples.look_padrao.duplicate()
				look.skin = skin
				look.hair_color = cab
				look.shorts_color = cal
				var tx = DV.textura("fighter_idle_disc_layered", look)
				distintos[tx.get_instance_id()] = 1
				combos += 1
	ok(combos == 180 and distintos.size() == 180, "180 combinacoes geram 180 texturas distintas (%d)" % distintos.size())
	print("INFO cache DiscVisual: %d texturas" % DV._cache.size())


func cenario_arte() -> void:
	print("== fila: arte antes do cartao, sem duas janelas ==")
	await novo_jogo()
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.permanente["legacy_total"] = 30
	gs.escolher_arte("boxing")
	await abrir()
	gs.aposentar()
	await esperar(0.5)
	print("INFO botao=", receber_pelo_botao(), " estado=", gs.sucessao_estado(), " janela=", cena.get_node("Fluxo").janela)
	await esperar(0.8)
	cena_ui().player.pular()
	await esperar(0.7)
	print("INFO estado depois do pular=", gs.sucessao_estado(), " janela=", cena.get_node("Fluxo").janela, " arte pend=", gs.escolha_arte_pendente())
	var tela := janela_criar()
	ok(tela != null, "criacao aberta")
	ok(not gs.escolha_arte_pendente() or gs.sucessao_estado() == "creating", "arte so depois")
	var fl: Node = cena.get_node("Fluxo")
	var tipos := []
	tela._confirmar()
	var t0 := Time.get_ticks_msec()
	var vistos := {}
	while Time.get_ticks_msec() - t0 < 9000:
		await process_frame
		var j: Node = fl.janela
		var nome := "-" if j == null else str(j.get_script().get_global_name())
		var cart: bool = fl.cartao != null
		var chave := "%s|cartao=%s|sucessao=%s" % [nome, str(cart), gs.sucessao_estado()]
		if not vistos.has(chave):
			vistos[chave] = float(Time.get_ticks_msec() - t0) / 1000.0
			print("INFO fila t=%.2f %s" % [vistos[chave], chave])
		if j != null and cart:
			ok(false, "duas janelas ao mesmo tempo: %s + cartao" % nome)
		if nome == "JanelaArte":
			await shot("arte_apos_cena")
			j.escolheu.emit("boxing") if false else null
			break
	await esperar(0.5)
	ok(vistos.keys().any(func(k: String) -> bool: return k.begins_with("JanelaArte")), "a escolha da arte abre depois da cena")
	print("INFO escolha_arte_pendente=", gs.escolha_arte_pendente())


func cenario_frames() -> void:
	await novo_jogo()
	await abrir()
	gs.aposentar()
	await esperar(0.5)
	receber_pelo_botao()
	var t0 := Time.get_ticks_msec()
	var marcas := [1.0, 2.0, 3.0, 3.9, 4.5, 5.1, 5.7, 6.3, 6.9, 7.8, 8.6, 9.2]
	for m in marcas:
		while float(Time.get_ticks_msec() - t0) / 1000.0 < m:
			await process_frame
		await shot("frame_p1_%04.1f" % m)
