extends SceneTree
## QA Fase 2: joga a garagem com entrada sintetica (mouse/teclado) numa janela real.
## Uso: godot --path . --resolution 1280x720 --script res://tests/qa_play.gd -- <prefixo> [secoes]
## Salva em user://test/autoload/ (nunca no save real). Screenshots em OUT.

const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/d03e7314839aa25e/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa2/"
const PONTO := Vector2(336, 222)

var gs: Node
var cena: Control
var sala
var pre := "x"
var soma_clicou := 0.0
var n_clicou := 0
var n_crit := 0
var ultimo: Dictionary = {}


func win(p: Vector2) -> Vector2:
	return root.get_final_transform() * p


func mover(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = win(p)
	ev.global_position = ev.position
	Input.parse_input_event(ev)


func clicar(p: Vector2) -> void:
	mover(p)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = win(p)
	ev.global_position = ev.position
	ev.pressed = true
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(ev)
	var ev2 := ev.duplicate() as InputEventMouseButton
	ev2.pressed = false
	ev2.button_mask = 0
	Input.parse_input_event(ev2)


func tecla(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := ev.duplicate() as InputEventKey
	ev2.pressed = false
	Input.parse_input_event(ev2)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(nome: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(OUT + pre + "_" + nome + ".png")


func on_clicou(g: float, c: bool, a: String, at: String, t: String) -> void:
	soma_clicou += g
	n_clicou += 1
	if c:
		n_crit += 1
	ultimo = {"g": g, "c": c, "a": a, "at": at, "t": t}


# Numero ativo mais recente (menor _t)
func numero_novo() -> Object:
	var m = null
	for n in sala._numeros:
		if n.ativo and (m == null or n._t < m._t):
			m = n
	return m


func ativos() -> int:
	var k := 0
	for n in sala._numeros:
		if n.ativo:
			k += 1
	return k


func p(s: String) -> void:
	print("QA| ", s)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	pre = args[0] if args.size() > 0 else "x"
	var secoes := args[1] if args.size() > 1 else "abcdefghijk"
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	sala = cena.get_node("Sala")
	gs.clicou.connect(on_clicou)
	await frames(30)
	p("janela=%s final_transform=%s modo=%s debug_build=%s" % [root.size, root.get_final_transform(), DisplayServer.window_get_mode(), OS.is_debug_build()])
	p("tela=%s dpi=%s" % [DisplayServer.screen_get_size(), DisplayServer.screen_get_dpi()])
	p("avisos=%s treino=%s atributos=%s foco=%s" % [gs.avisos, gs.treino, gs.atributos, gs.foco])
	shot("a_inicio")

	if "b" in secoes:
		await secao_b()
	if "c" in secoes:
		await secao_c()
	if "d" in secoes:
		await secao_d()
	if "e" in secoes:
		await secao_e()
	if "f" in secoes:
		await secao_f()
	if "g" in secoes:
		await secao_g()
	if "h" in secoes:
		await secao_h()
	if "i" in secoes:
		await secao_i()
	if "j" in secoes:
		await secao_j()
	quit(0)


# B: 20 cliques, numero = ganho = delta de saldo e atributo
func secao_b() -> void:
	p("== B: 20 cliques ==")
	gs.apagar_save()
	await frames(5)
	var t0: float = gs.treino
	var a0: float = gs.atributos["strength"]
	soma_clicou = 0.0
	n_clicou = 0
	var sem_numero := 0
	var desc := 0
	for i in 20:
		clicar(PONTO)
		await process_frame
		await process_frame
		var n = numero_novo()
		if n == null or n._t > 0.1:
			sem_numero += 1
		else:
			var esperado := "+%s FORÇA" % NumberFormat.fmt(ultimo.g)
			var txt: String = n._principal.text
			if not txt.begins_with(esperado):
				desc += 1
				p("  texto divergente: '%s' esperado '%s'" % [txt, esperado])
		await frames(4)
	p("cliques registrados=%d (esperado 20) soma ganhos=%s  delta saldo=%s delta forca=%s sem_numero=%d divergentes=%d" % [n_clicou, soma_clicou, gs.treino - t0, gs.atributos["strength"] - a0, sem_numero, desc])
	p("hint ativo apos clique=%s" % cena.get_node("BarraBaixo").dica_ativa())
	shot("b_apos20")


# C: 10 cliques/s por 10 s, FPS, numero por clique, sobreposicao
func secao_c() -> void:
	p("== C: 10 cliques/s por 10 s ==")
	n_clicou = 0
	n_crit = 0
	var sem_numero := 0
	var t_ini := Time.get_ticks_msec()
	var max_ativos := 0
	var dts: Array = []
	var ult := Time.get_ticks_msec()
	var prox := t_ini
	var shots := 0
	while Time.get_ticks_msec() - t_ini < 10000:
		await process_frame
		var agora := Time.get_ticks_msec()
		dts.append(agora - ult)
		ult = agora
		if agora >= prox:
			prox += 100
			var antes := n_clicou
			clicar(PONTO)
			await process_frame
			if n_clicou == antes + 1:
				var n = numero_novo()
				if n == null or n._t > 0.1:
					sem_numero += 1
			else:
				p("  clique nao registrado")
		max_ativos = max(max_ativos, ativos())
		if shots < 4 and agora - t_ini > 2000 + shots * 2000:
			shot("c_rajada%d" % shots)
			shots += 1
	var soma := 0.0
	var mx := 0
	for d in dts:
		soma += d
		mx = max(mx, d)
	p("cliques=%d criticos=%d sem_numero=%d max_numeros_ativos=%d frames=%d dt_medio=%.1fms dt_max=%dms fps_engine=%s" % [n_clicou, n_crit, sem_numero, max_ativos, dts.size(), soma / dts.size(), mx, Engine.get_frames_per_second()])


# D: 200 cliques, proporcao de critico, a 1 clique por 2 frames
func secao_d() -> void:
	p("== D: 200 cliques, crit ==")
	n_clicou = 0
	n_crit = 0
	var vistos_crit := 0
	for i in 200:
		clicar(PONTO)
		await process_frame
		if ultimo.c:
			var n = numero_novo()
			if n != null and n._principal.text.ends_with("!") and n._principal.scale.x == 2.0:
				vistos_crit += 1
			if vistos_crit == 1 and not FileAccess.file_exists(OUT + pre + "_d_crit.png"):
				await frames(3)
				shot("d_crit")
		await process_frame
	p("cliques=%d criticos=%d (esperado ~20, faixa 9-31) crit_com_numero_grande_e_exclamacao=%d ultimo=%s" % [n_clicou, n_crit, vistos_crit, ultimo])
	# chance alterada em runtime (equivale a mudar data/): 100% e 0%
	gs.dados.crit_chance = 1.0
	n_crit = 0
	n_clicou = 0
	for i in 10:
		clicar(PONTO)
		await process_frame
		await process_frame
	p("chance=1.0: criticos=%d/%d" % [n_crit, n_clicou])
	gs.dados.crit_chance = 0.0
	n_crit = 0
	n_clicou = 0
	for i in 10:
		clicar(PONTO)
		await process_frame
		await process_frame
	p("chance=0.0: criticos=%d/%d" % [n_crit, n_clicou])
	gs.dados.crit_chance = 0.1


# E: foco por botoes, teclas, aparelho lateral; mesmo ponto
func secao_e() -> void:
	p("== E: foco ==")
	var barra = cena.get_node("BarraBaixo")
	# botoes de foco: posicoes da barra (y 290+14..48, x 134+i*128)
	var posicoes := [Vector2(134 + 60, 290 + 30), Vector2(134 + 128 + 60, 290 + 30), Vector2(134 + 256 + 60, 290 + 30)]
	var ids := ["punching_bag", "jump_rope", "treadmill"]
	var atrs := ["strength", "agility", "endurance"]
	# por botao
	for i in [1, 2, 0, 1]:
		var a0: float = gs.atributos[atrs[i]]
		var t0: float = gs.treino
		clicar(posicoes[i])
		await frames(3)
		var foco_ok: bool = gs.foco == ids[i]
		mover(PONTO)
		await frames(2)
		clicar(PONTO)
		await frames(3)
		p("botao %d: foco=%s ok=%s  atributo %s +%s  saldo +%s  ultimo=%s" % [i + 1, gs.foco, foco_ok, atrs[i], gs.atributos[atrs[i]] - a0, gs.treino - t0, ultimo])
		await frames(5)
		shot("e_foco_%s" % ids[i])
	# por tecla
	for k in [KEY_3, KEY_2, KEY_1]:
		var i: int = k - KEY_1
		tecla(k)
		await frames(3)
		var a0: float = gs.atributos[atrs[i]]
		clicar(PONTO)
		await frames(3)
		p("tecla %d: foco=%s esperado=%s  atributo +%s" % [i + 1, gs.foco, ids[i], gs.atributos[atrs[i]] - a0])
	# aparelho lateral
	gs.definir_foco("punching_bag")
	await frames(3)
	for id in ["jump_rope", "treadmill", "punching_bag"]:
		var area: Rect2 = sala._area_lateral(id)
		var ctr := area.get_center()
		var t0: float = gs.treino
		n_clicou = 0
		clicar(ctr)
		await frames(3)
		p("lateral %s area=%s: foco=%s cliques_gerados=%d delta_saldo=%s" % [id, area, gs.foco, n_clicou, gs.treino - t0])
		await frames(5)
		shot("e_lateral_%s" % id)
	# clique perto do alvo mas fora (borda)
	gs.definir_foco("punching_bag")
	await frames(2)
	n_clicou = 0
	clicar(Vector2(311, 222))
	await frames(2)
	clicar(Vector2(361, 222))
	await frames(2)
	clicar(Vector2(336, 181))
	await frames(2)
	clicar(Vector2(336, 273))
	await frames(2)
	p("cliques fora do alvo (4 pontos logo fora) gerados=%d (esperado 0)" % n_clicou)
	clicar(Vector2(312, 182))
	await frames(2)
	clicar(Vector2(359, 271))
	await frames(2)
	p("cliques nos cantos dentro do alvo gerados=%d (esperado 2)" % n_clicou)
	# passivo desvia com o foco
	gs.geradores["neighbor_kid"] = 5
	gs.economia_mudou.emit()
	var d0 := {}
	for a in atrs:
		d0[a] = gs.atributos[a]
	gs.definir_foco("jump_rope")
	await create_timer(2.0).timeout
	var d1 := {}
	for a in atrs:
		d1[a] = gs.atributos[a] - d0[a]
	p("passivo 5/s por 2 s com foco corda: delta=%s" % d1)
	gs.definir_foco("treadmill")
	for a in atrs:
		d0[a] = gs.atributos[a]
	await create_timer(2.0).timeout
	d1 = {}
	for a in atrs:
		d1[a] = gs.atributos[a] - d0[a]
	p("depois de trocar p/ esteira, 2 s: delta=%s" % d1)
	gs.geradores["neighbor_kid"] = 0
	gs.economia_mudou.emit()
	gs.definir_foco("punching_bag")


# F: comprar sem saldo
func secao_f() -> void:
	p("== F: compra sem saldo ==")
	gs.apagar_save()
	await frames(5)
	gs.treino = 10.0
	gs.economia_mudou.emit()
	await frames(15)
	var painel = cena.get_node("PainelLoja")
	var snap := [gs.treino, gs.geradores.duplicate(), gs.niveis_melhoria.duplicate()]
	for g in ["neighbor_kid", "retired_uncle"]:
		p("comprar_gerador(%s) com 10 de saldo -> %s" % [g, gs.comprar_gerador(g)])
	for a in ["punching_bag", "jump_rope", "treadmill"]:
		p("comprar_melhoria(%s) -> %s" % [a, gs.comprar_melhoria(a)])
	p("comprar_gerador('x')=%s comprar_melhoria('x')=%s" % [gs.comprar_gerador("x"), gs.comprar_melhoria("x")])
	p("estado igual? saldo=%s ger=%s niv=%s" % [gs.treino, gs.geradores, gs.niveis_melhoria])
	# clique real em botao CHAMAR e MELHORAR (desabilitados)
	var b1: Button = painel._gens["neighbor_kid"].botao
	var pos_b1 := b1.get_global_rect().get_center()
	clicar(pos_b1)
	await frames(3)
	p("clique no botao CHAMAR sem saldo: botao disabled=%s saldo=%s qtd=%s" % [b1.disabled, gs.treino, gs.geradores])
	shot("f_sem_saldo")
	# saldo exato do preco / 1 abaixo
	gs.treino = 59.999999999
	p("saldo 59.999999999 pode_comprar vizinho=%s" % gs.pode_comprar_gerador("neighbor_kid"))
	gs.treino = 59.9
	p("saldo 59.9 pode_comprar vizinho=%s" % gs.pode_comprar_gerador("neighbor_kid"))
	gs.treino = 60.0
	gs.treino_mudou.emit(60.0)
	await frames(15)
	var antes: float = gs.treino
	clicar(pos_b1)
	await frames(3)
	p("saldo 60 compra via botao: saldo=%s qtd=%s saldo>=0=%s" % [gs.treino, gs.geradores, gs.treino >= 0.0])
	gs.treino = 0.0
	gs.geradores.clear()
	gs.niveis_melhoria.clear()
	gs.carreira_mudou.emit()


# G: comprar tudo ate MAXIMO via botoes, dados quantidade, pessoas
func secao_g() -> void:
	p("== G: comprar tudo ==")
	var painel = cena.get_node("PainelLoja")
	gs.treino = 1e12
	gs.economia_mudou.emit()
	await frames(15)
	shot("g_rico_antes")
	# melhorias por botao ate MAX
	for rodada in 3:
		for a in ["punching_bag", "jump_rope", "treadmill"]:
			var b: Button = painel._ups[a].botao
			var r := b.get_global_rect()
			if b.disabled:
				continue
			clicar(r.get_center())
			await frames(4)
			shot("g_melhoria_%s_n%d" % [a, gs.niveis_melhoria.get(a, 0)])
	p("niveis=%s" % gs.niveis_melhoria)
	for a in ["punching_bag", "jump_rope", "treadmill"]:
		var b: Button = painel._ups[a].botao
		p("  %s botao disabled=%s texto='%s' efeito='%s' nivel='%s' mult=%s nivel_visual=%s" % [a, b.disabled, painel._ups[a].esq.text, painel._ups[a].efeito.text, painel._ups[a].nivel.text, gs.multiplicador_aparelho(a), gs.nivel_visual(a)])
		p("  comprar_melhoria alem do maximo=%s saldo=%s" % [gs.comprar_melhoria(a), gs.treino])
	await frames(10)
	shot("g_maximo")
	# todos os aparelhos em max: cada foco com sprites nivel 1
	for a in ["jump_rope", "treadmill", "punching_bag"]:
		gs.definir_foco(a)
		await frames(10)
		shot("g_nivel1_foco_%s" % a)
	# geradores: 1, 9, 10, 24, 25, 200 unidades
	gs.treino = 1e30
	gs.economia_mudou.emit()
	var marcos := [1, 10, 25, 50]
	var comprados := 0
	for m in marcos:
		while gs.quantidade_gerador("neighbor_kid") < m:
			var cj: float = gs.custo_gerador("neighbor_kid")
			var s0: float = gs.treino
			if not gs.comprar_gerador("neighbor_kid"):
				p("  compra recusada inesperada em %d" % gs.quantidade_gerador("neighbor_kid"))
				break
		while gs.quantidade_gerador("retired_uncle") < min(m, 25):
			gs.comprar_gerador("retired_uncle")
		await frames(15)
		p("vizinhos=%d tios=%d desenhados v=%d t=%d  /s=%s" % [gs.quantidade_gerador("neighbor_kid"), gs.quantidade_gerador("retired_uncle"), gs.pessoas_desenhadas("neighbor_kid"), gs.pessoas_desenhadas("retired_uncle"), gs.producao_total()])
		shot("g_pessoas_%d" % m)
	# 200 via debug
	for i in 20:
		gs.debug_somar_geradores()
	await frames(15)
	p("apos debug x20: vizinhos=%d tios=%d desenhados v=%d t=%d /s=%s custo viz=%s custo tio=%s" % [gs.quantidade_gerador("neighbor_kid"), gs.quantidade_gerador("retired_uncle"), gs.pessoas_desenhadas("neighbor_kid"), gs.pessoas_desenhadas("retired_uncle"), gs.producao_total(), gs.custo_gerador("neighbor_kid"), gs.custo_gerador("retired_uncle")])
	shot("g_200")
	gs.treino = 1e30
	var ok = gs.comprar_gerador("neighbor_kid")
	p("compra com 250 vizinhos=%s; saldo apos=%s" % [ok, gs.treino])
	# numero grande no HUD
	gs.treino = 9.99e14
	gs.atributos["strength"] = 1.5e20
	gs.economia_mudou.emit()
	await frames(15)
	shot("g_numeros_grandes")


# H: F11 / F12
func secao_h() -> void:
	p("== H: F11/F12 ==")
	var ov = cena.get_node("DebugOverlay")
	p("debug visivel inicial=%s overlay.visible=%s" % [root.get_node("AppControls").debug_visivel, ov.visible])
	tecla(KEY_F12)
	await frames(5)
	p("apos F12: debug_visivel=%s overlay.visible=%s" % [root.get_node("AppControls").debug_visivel, ov.visible])
	shot("h_f12")
	# botoes de debug via clique
	var t0: float = gs.treino
	gs.treino = 100.0
	gs.atributos["agility"] = 5.0
	var ag: float = gs.atributos["agility"]
	var b: Button = ov.get_child(2) as Button
	for c in ov.get_children():
		if c is Button:
			p("  botao debug em %s" % c.get_global_rect())
	tecla(KEY_F12)
	await frames(3)
	p("apos 2o F12: overlay.visible=%s" % ov.visible)
	gs.debug_multiplicar_saldo()
	p("debug_multiplicar_saldo: saldo=%s atributo agilidade=%s (nao deve mudar de %s)" % [gs.treino, gs.atributos["agility"], ag])
	tecla(KEY_F11)
	await frames(30)
	p("apos F11: modo=%s janela=%s final_transform=%s" % [DisplayServer.window_get_mode(), root.size, root.get_final_transform()])
	await frames(10)
	shot("h_f11")
	clicar(PONTO)
	await frames(4)
	p("clique em tela cheia gerou clique? ultimo=%s" % ultimo)
	var antes := n_clicou
	clicar(PONTO)
	await frames(4)
	p("clique em tela cheia registrado=%s" % (n_clicou == antes + 1))
	tecla(KEY_F11)
	await frames(30)
	p("apos 2o F11: modo=%s janela=%s" % [DisplayServer.window_get_mode(), root.size])


# I: cursor
func secao_i() -> void:
	p("== I: cursor ==")
	mover(Vector2(300, 100))
	await frames(5)
	var cur = cena._cursor
	p("sobre a sala: cursor.visible=%s mouse_mode=%s pos=%s" % [cur.visible, Input.mouse_mode, cur.position])
	shot("i_cursor_sala")
	mover(Vector2(580, 100))
	await frames(5)
	p("sobre painel: cursor.visible=%s mouse_mode=%s" % [cur.visible, Input.mouse_mode])
	mover(Vector2(300, 320))
	await frames(5)
	p("sobre barra: cursor.visible=%s mouse_mode=%s" % [cur.visible, Input.mouse_mode])
	mover(Vector2(300, 100))
	await frames(3)
	p("luva cursor sprite=%s luva da mao=%s" % [cur.nome_sprite, "ver fighter_*"])


# J: salvar no X
func secao_j() -> void:
	p("== J ==")
