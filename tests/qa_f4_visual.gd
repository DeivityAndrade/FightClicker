extends SceneTree
## QA Fase 4: verificacoes visuais em janela real (1280x720). Save de teste. Imagens em OUT.
## Uso: godot --path . --resolution 1280x720 --script res://tests/qa_f4_visual.gd -- <secoes: m c t l g>

const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa4/"
const PONTO := Vector2(336, 222)

var gs: Node
var cena: Control
var sala
var fluxo
var barra


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


func shot(nome: String) -> void:
	root.get_texture().get_image().save_png(OUT + nome + ".png")


func p(s: String) -> void:
	print("QA| ", s)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func esperar(seg: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < seg * 1000.0:
		await process_frame


func achar_botao(raiz: Node, texto: String) -> Button:
	if raiz is Button and raiz.visible:
		for c in raiz.get_children():
			if c is Label and c.text == texto:
				return raiz
		if raiz.text == texto:
			return raiz
	for c in raiz.get_children():
		var r := achar_botao(c, texto)
		if r != null:
			return r
	return null


func clicar_botao(b: Button) -> void:
	clicar(b.get_global_rect().get_center())


func reiniciar() -> void:
	gs.apagar_save()
	await frames(3)
	gs.autosave_ativo = false


func _initialize() -> void:
	var secoes := "mctlg"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		secoes = args[0]
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	sala = cena.get_node("Sala")
	fluxo = cena.get_node("Fluxo")
	barra = cena.get_node("BarraBaixo")
	await frames(20)
	await reiniciar()
	if "m" in secoes:
		await sec_metronomo()
	if "c" in secoes:
		await sec_cartao()
	if "t" in secoes:
		await sec_tempo_lutar()
	if "l" in secoes:
		await sec_luvas()
	if "f" in secoes:
		await sec_folhas()
	if "g" in secoes:
		await sec_garagem_cheia()
	quit(0)


func sec_metronomo() -> void:
	p("== M: Metronomo ==")
	await reiniciar()
	gs.dinheiro = 100000.0
	# loja: abre aba LOJA e compra pelo botao real
	var aba := achar_botao(cena, "LOJA")
	if aba != null:
		clicar_botao(aba)
		await frames(5)
	await esperar(0.5)
	shot("m_loja_antes")
	var painel = cena.get_node("PainelLoja")
	var btn_antes := 0
	var botao_m: Button = null
	for b in painel.find_children("*", "Button", true, false):
		for l in b.find_children("*", "Label", true, false):
			if str(l.text).contains("SOCO A CADA"):
				botao_m = b
	var textos := []
	for l in painel.find_children("*", "Label", true, false):
		if l.visible and (str(l.text).contains("SOCO A CADA") or str(l.text).contains("METR")):
			textos.append(l.text)
	p("textos da loja sobre Metronomo: %s" % str(textos))
	# compra pelo clique no botao do item (procura botao cujo pai contem o texto)
	var alvo: Button = null
	for l in painel.find_children("*", "Label", true, false):
		if l.visible and str(l.text).contains("SOCO A CADA"):
			var no: Node = l
			while no != null and no != painel:
				for b in no.find_children("*", "Button", true, false):
					if b.visible:
						alvo = b
				if alvo != null:
					break
				no = no.get_parent()
			break
	p("botao do Metronomo achado=%s nivel=%d money=%d" % [alvo != null, gs.nivel_metronomo, gs.dinheiro])
	if alvo != null:
		clicar_botao(alvo)
		await frames(5)
	p("apos clique no botao: nivel=%d money=%d" % [gs.nivel_metronomo, gs.dinheiro])
	await esperar(0.6)
	shot("m_loja_nivel1")
	# 6 s observando: auto-socos, tremida, tamanho do numero
	gs.dinheiro = 100000.0
	var n0: int = gs.auto_socos_total
	var t0 := Time.get_ticks_msec()
	var max_shake := 0.0
	var vistos_num := 0
	var escala_auto := 0.0
	var escala_clique := 0.0
	while Time.get_ticks_msec() - t0 < 6000:
		await process_frame
		max_shake = maxf(max_shake, float(sala._shake_t))
		for n in sala._numeros:
			if n.ativo:
				vistos_num += 1
				escala_auto = maxf(escala_auto, n._principal.scale.x)
				if n._principal.modulate.a < 1.0 or n._principal.self_modulate.a < 1.0:
					pass
	var n1: int = gs.auto_socos_total
	p("nivel 1 (2.0 s): auto-socos em 6 s = %d (esperado ~3); max _shake_t=%.3f (esperado 0); escala maxima do numero auto=%.2f" % [n1 - n0, max_shake, escala_auto])
	shot("m_garagem_nivel1")
	# clique do jogador: escala e tremida
	clicar(PONTO)
	await frames(2)
	p("clique do jogador: _shake_t=%.3f" % float(sala._shake_t))
	for n in sala._numeros:
		if n.ativo and n._t < 0.1:
			escala_clique = maxf(escala_clique, n._principal.scale.x)
	p("escala do numero do jogador=%.2f" % escala_clique)
	# nivel 3: socos/s medidos
	while gs.comprar_metronomo():
		pass
	gs.dinheiro = 0
	n0 = gs.auto_socos_total
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	p("nivel %d: auto-socos em 10 s = %d (%.2f/s, max 1,5)" % [gs.nivel_metronomo, gs.auto_socos_total - n0, (gs.auto_socos_total - n0) / 10.0])
	shot("m_garagem_nivel3")
	# modal: abre previa -> 0 socos
	gs.atributos["strength"] = 500.0
	clicar_botao(barra._lutar)
	await esperar(1.0)
	n0 = gs.auto_socos_total
	await esperar(3.0)
	p("com a previa aberta por 3 s: auto-socos=%d (esperado 0)" % [gs.auto_socos_total - n0])
	shot("m_previa_aberta")
	var voltar := achar_botao(fluxo.janela, "VOLTAR A TREINAR") if fluxo.janela != null else null
	if voltar != null:
		clicar_botao(voltar)
		await frames(5)
	n0 = gs.auto_socos_total
	await esperar(3.0)
	p("depois de VOLTAR A TREINAR, 3 s: auto-socos=%d (esperado ~4)" % [gs.auto_socos_total - n0])


func sec_cartao() -> void:
	p("== C: cartao 'o que voce trouxe' + Metronomo ==")
	await reiniciar()
	gs.permanente["legacy_total"] = 1000
	gs.aposentar()
	await frames(10)
	for id in ["body_jab", "body_muscle_memory", "career_purse", "career_scouting", "body_crew"]:
		gs.comprar_no(id)
	var jan = fluxo.janela
	p("janela depois de aposentar: %s" % (jan.get_script().get_global_name() if jan != null else "nenhuma"))
	var b := achar_botao(jan, "NOVA CARREIRA") if jan != null else null
	if b != null:
		clicar_botao(b)
	var n0: int = gs.auto_socos_total
	var t0 := Time.get_ticks_msec()
	var cartao_visto := false
	var t_cartao_fim := -1.0
	var socos_sob_cartao := 0
	var primeiro_soco := -1.0
	while Time.get_ticks_msec() - t0 < 6000:
		await process_frame
		var agora := (Time.get_ticks_msec() - t0) / 1000.0
		if fluxo.cartao != null:
			cartao_visto = true
			socos_sob_cartao = gs.auto_socos_total - n0
			if agora > 0.3 and not FileAccess.file_exists(OUT + "c_cartao.png"):
				shot("c_cartao")
		elif cartao_visto and t_cartao_fim < 0.0:
			t_cartao_fim = agora
		if primeiro_soco < 0.0 and gs.auto_socos_total > n0:
			primeiro_soco = agora
	p("cartao visto=%s; sumiu aos %.2f s (<= 2 s); auto-socos enquanto o cartao estava aberto=%d (esperado 0); 1o auto-soco aos %.2f s; metronomo nivel=%d" % [cartao_visto, t_cartao_fim, socos_sob_cartao, primeiro_soco, gs.nivel_metronomo])
	shot("c_depois_cartao")
	# cartao fecha com 1 clique?
	await reiniciar()
	gs.permanente["legacy_total"] = 1000
	gs.aposentar()
	gs.comprar_no("body_jab")
	await frames(10)
	b = achar_botao(fluxo.janela, "NOVA CARREIRA")
	clicar_botao(b)
	await frames(15)
	p("cartao aberto? %s" % (fluxo.cartao != null))
	var cl0: int = gs.treino
	clicar(PONTO)
	await frames(5)
	p("apos 1 clique: cartao aberto? %s; treino mudou=%s" % [fluxo.cartao != null, gs.treino != cl0])
	# resumo da garagem: rotulo
	var achou := false
	for l in cena.find_children("*", "Label", true, false):
		if l.visible and str(l.text).begins_with("LEGADO: ") and str(l.text).contains("NÓS"):
			achou = true
			p("rotulo do resumo: '%s' em %s" % [l.text, l.get_global_rect()])
	p("rotulo de resumo achado=%s" % achou)


func sec_tempo_lutar() -> void:
	p("== T: criterio 33 (tempo do clique em LUTAR!) ==")
	for cenario in ["vitoria", "derrota", "vitoria", "derrota", "vitoria", "derrota"]:
		await reiniciar()
		if cenario == "vitoria":
			for a in ["strength", "agility", "endurance"]:
				gs.atributos[a] = 3000.0
		else:
			for a in ["strength", "agility", "endurance"]:
				gs.atributos[a] = 20.0
		await frames(5)
		clicar_botao(barra._lutar)
		await esperar(1.0)
		var lutar := achar_botao(fluxo.janela, "LUTAR!")
		var r := lutar.get_global_rect().get_center()
		var t0 := Time.get_ticks_usec()
		clicar(r)
		var maxdt := 0.0
		var ult := t0
		var t_inicio := -1.0
		for i in 120:
			await process_frame
			var agora := Time.get_ticks_usec()
			maxdt = maxf(maxdt, float(agora - ult) / 1000.0)
			ult = agora
			if t_inicio < 0.0 and fluxo.tela.visible:
				t_inicio = float(agora - t0) / 1000.0
		p("%s: resultado=%s; do clique ate a arena=%.1f ms; maior quadro nos 120 seguintes=%.1f ms" % [cenario, "win" if gs.luta.get("result", {}).get("win", false) else "lose", t_inicio, maxdt])
		await esperar(0.2)
		# deixa a luta terminar e limpa
		var lim := Time.get_ticks_msec() + 30000
		while (fluxo.tela.visible or fluxo.janela != null) and Time.get_ticks_msec() < lim:
			await process_frame
			if fluxo.janela != null:
				var c := achar_botao(fluxo.janela, "CONTINUAR")
				if c != null:
					clicar_botao(c)
				break


func sec_luvas() -> void:
	p("== L: luvas ==")
	await reiniciar()
	gs.dinheiro = 100000.0
	gs.nivel_metronomo = 2
	gs.atributos["strength"] = 400.0
	mover(PONTO)
	for nivel in [0, 1, 2, 3]:
		gs.nivel_luva = nivel
		gs.luva_mudou.emit(nivel, gs.sufixo_luva())
		await esperar(1.2)
		clicar(PONTO)
		await frames(4)
		p("luva nivel %d sufixo='%s' cursor='%s'" % [nivel, gs.sufixo_luva(), cena._cursor.nome_sprite])
		shot("l_garagem_luva%d" % nivel)


func sec_garagem_cheia() -> void:
	p("== G: garagem cheia + lutas por adversario (folhas de contato) ==")
	await reiniciar()
	gs.geradores["neighbor_kid"] = 40
	gs.geradores["retired_uncle"] = 40
	gs.geradores_pagos["gen_paid_1"] = 5
	gs.nivel_metronomo = 3
	gs.nivel_luva = 2
	gs.luva_mudou.emit(2, gs.sufixo_luva())
	gs.economia_mudou.emit()
	gs.gerador_mudou.emit("neighbor_kid", 40)
	gs.gerador_mudou.emit("retired_uncle", 40)
	await esperar(1.5)
	shot("g_garagem_cheia")
	# luta contra cada adversario: folha de contato (4 colunas x 3 linhas, a cada 0,3 s)
	for k in 4:
		await reiniciar()
		for a in ["strength", "agility", "endurance"]:
			gs.atributos[a] = [300.0, 2.0e3, 3.0e4, 4.0e5][k]
		gs.indice_escada = k
		gs.nivel_luva = [0, 1, 2, 3][k]
		gs.luva_mudou.emit(gs.nivel_luva, gs.sufixo_luva())
		gs.carreira_mudou.emit()
		await esperar(0.5)
		gs.definir_tatica("aggressive")
		var info: Dictionary = gs.lutar()
		var folha := Image.create(1280 * 2, 720 * 2, false, Image.FORMAT_RGBA8)
		var i := 0
		var t0 := Time.get_ticks_msec()
		var prox := 700.0
		while i < 12 and Time.get_ticks_msec() - t0 < 25000:
			await process_frame
			if Time.get_ticks_msec() - t0 >= prox:
				prox += 450.0
				var img := root.get_texture().get_image()
				img.convert(Image.FORMAT_RGBA8)
				folha.blit_rect(img, Rect2i(0, 0, 1280, 720), Vector2i((i % 2) * 1280, (i / 2 % 2) * 720))
				if i < 4:
					img.save_png(OUT + "g_luta%d_f%02d.png" % [k, i])
				i += 1
		p("luta %d contra %s: win=%s frames capturados=%d" % [k, str(gs.luta.get("opponent", "?")), gs.luta.get("result", {}).get("win", "?"), i])
		await esperar(3.0)
		if fluxo.janela != null:
			var c := achar_botao(fluxo.janela, "CONTINUAR")
			if c != null:
				clicar_botao(c)
			else:
				var nc := achar_botao(fluxo.janela, "NOVA CARREIRA")
				if nc != null:
					clicar_botao(nc)
		await frames(5)


# Folhas de contato ampliadas: lutas (4 adversarios x 12 quadros) e jab na garagem (3 luvas).
func sec_folhas() -> void:
	p("== F: folhas de contato ==")
	var tile := Rect2i(210, 200, 220, 130)
	for k in 4:
		await reiniciar()
		for a in ["strength", "agility", "endurance"]:
			gs.atributos[a] = [300.0, 2.0e3, 3.0e4, 4.0e5][k]
		gs.indice_escada = k
		gs.nivel_luva = [1, 2, 1, 2][k]
		gs.luva_mudou.emit(gs.nivel_luva, gs.sufixo_luva())
		gs.carreira_mudou.emit()
		await esperar(0.4)
		gs.definir_tatica("aggressive")
		gs.lutar()
		var folha := Image.create(tile.size.x * 2 * 4, tile.size.y * 2 * 4, false, Image.FORMAT_RGBA8)
		var i := 0
		var t0 := Time.get_ticks_msec()
		var prox := 1600.0
		while i < 16 and Time.get_ticks_msec() - t0 < 25000:
			await process_frame
			if Time.get_ticks_msec() - t0 >= prox:
				prox += 130.0
				var img := root.get_texture().get_image()
				img.convert(Image.FORMAT_RGBA8)
				var c := img.get_region(tile)
				c.resize(tile.size.x * 2, tile.size.y * 2, Image.INTERPOLATE_NEAREST)
				folha.blit_rect(c, Rect2i(0, 0, c.get_width(), c.get_height()), Vector2i((i % 4) * c.get_width(), (i / 4) * c.get_height()))
				i += 1
		folha.save_png(OUT + "f_luta%d.png" % k)
		await esperar(4.0)
		if fluxo.janela != null:
			var cb := achar_botao(fluxo.janela, "CONTINUAR")
			if cb != null:
				clicar_botao(cb)
			else:
				var nc := achar_botao(fluxo.janela, "NOVA CARREIRA")
				if nc != null:
					clicar_botao(nc)
		await frames(5)
	# jab na garagem
	await reiniciar()
	gs.atributos["strength"] = 400.0
	var tile2 := Rect2i(250, 190, 150, 110)
	for nivel in [0, 1, 2]:
		gs.nivel_luva = nivel
		gs.luva_mudou.emit(nivel, gs.sufixo_luva())
		await esperar(1.0)
		var folha2 := Image.create(tile2.size.x * 3 * 4, tile2.size.y * 3 * 2, false, Image.FORMAT_RGBA8)
		for i in 8:
			clicar(PONTO)
			await process_frame
			await process_frame
			var img := root.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			var c := img.get_region(tile2)
			c.resize(tile2.size.x * 3, tile2.size.y * 3, Image.INTERPOLATE_NEAREST)
			folha2.blit_rect(c, Rect2i(0, 0, c.get_width(), c.get_height()), Vector2i((i % 4) * c.get_width(), (i / 4) * c.get_height()))
			await process_frame
		folha2.save_png(OUT + "f_jab_luva%d.png" % nivel)
