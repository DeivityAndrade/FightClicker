extends SceneTree
## QA Fase 4: joga do zero pela UI com entrada sintetica (sem F12), numa janela real.
## Uso: godot --path . --resolution 1280x720 --script res://tests/qa_f4_play.gd -- <prefixo> <semente> <escala> <cps> [max_carreiras]
## Salva em user://test/autoload/ (nunca no save real). Imagens em OUT.

const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa5/"
const PONTO := Vector2(336, 222)

var gs: Node
var cena: Control
var sala
var fluxo
var barra
var pre := "p"
var cps := 4.5
var escala := 3.0
var relogio := 0.0  # tempo de jogo percorrido (s), inclusive telas
var acc_clique := 0.0
var t_compra := 0.0
var t_risco := 0.0
var t_foco := 0.0
var n_clicou := 0
var n_sem_numero := 0
var carreira_atual := 1
var marcos: Array = []
var total_jogo := 0.0
var shots_feitos := {}


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
	var img := root.get_texture().get_image()
	img.save_png(OUT + pre + "_" + nome + ".png")


func shot_uma_vez(nome: String) -> void:
	if not shots_feitos.has(nome):
		shots_feitos[nome] = true
		shot(nome)


func p(s: String) -> void:
	print("QA| ", s)


func marco(s: String) -> void:
	var linha := "[carreira %d, jogo %s, relogio %s] %s" % [carreira_atual, fmt(gs.tempo_jogo), fmt(relogio), s]
	marcos.append(linha)
	p(linha)


func fmt(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


func frames(n: int) -> void:
	for i in n:
		await process_frame


# espera por tempo REAL (s)
func esperar(seg: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < seg * 1000.0:
		await process_frame


func achar_botao(raiz: Node, texto: String) -> Button:
	if raiz is Button and raiz.visible:
		var b := raiz as Button
		if b.text == texto:
			return b
		for c in b.get_children():
			if c is Label and c.text == texto:
				return b
	for c in raiz.get_children():
		var r := achar_botao(c, texto)
		if r != null:
			return r
	return null


func clicar_botao(b: Button) -> void:
	var r := b.get_global_rect()
	clicar(r.get_center())


func numero_novo() -> Object:
	var m = null
	for n in sala._numeros:
		if n.ativo and (m == null or n._t < m._t):
			m = n
	return m


func on_clicou(_g: float, _c: bool, _a: String, _at: String, _t: String) -> void:
	n_clicou += 1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	pre = args[0] if args.size() > 0 else "p"
	var semente := int(args[1]) if args.size() > 1 else 1
	escala = float(args[2]) if args.size() > 2 else 3.0
	cps = float(args[3]) if args.size() > 3 else 4.5
	var max_carreiras := int(args[4]) if args.size() > 4 else 2
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	gs.rng.seed = semente
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	sala = cena.get_node("Sala")
	fluxo = cena.get_node("Fluxo")
	barra = cena.get_node("BarraBaixo")
	gs.clicou.connect(on_clicou)
	await frames(20)
	gs.apagar_save()
	gs.definir_assistido(true)
	await frames(3)
	p("janela=%s escala=%s cps=%s semente=%s carreira=%s legado=%s" % [root.size, escala, cps, semente, gs.numero_carreira(), gs.permanente.legacy_total])
	Engine.time_scale = escala
	await jogar(max_carreiras)
	Engine.time_scale = 1.0
	p("== MARCOS ==")
	for m in marcos:
		p(m)
	p("cliques=%d sem_numero=%d avisos=%s" % [n_clicou, n_sem_numero, gs.avisos])
	quit(0)


func jogar(max_carreiras: int) -> void:
	var ultimo := Time.get_ticks_usec()
	var gastos_fim := 0.0
	var primeira_vitoria_marcada := {}
	var limite_real := Time.get_ticks_msec() + 25 * 60 * 1000
	var tinha_fim := false
	var algoz_ant := ""
	var vit_antes := 0
	while Time.get_ticks_msec() < limite_real:
		await process_frame
		var agora := Time.get_ticks_usec()
		var dt := float(agora - ultimo) / 1e6 * escala
		ultimo = agora
		relogio += dt
		if gs.numero_carreira() != carreira_atual:
			carreira_atual = gs.numero_carreira()
			marco("NOVA CARREIRA iniciada. legado=%d nos=%s metronomo=%d algoz=%s" % [gs.permanente.legacy_total, str(gs.nos_comprados()), gs.nivel_metronomo, gs.algoz()])
			if carreira_atual > max_carreiras:
				return
			vit_antes = 0
		var jan = fluxo.janela
		# --- telas ---
		if jan != null:
			await tratar_janela(jan)
			continue
		if fluxo.tela.visible:
			continue
		if fluxo.cartao != null:
			shot_uma_vez("cartao_c%d" % carreira_atual)
			clicar(PONTO)  # 1 clique fecha o cartao (nao gasta: pode ser o clique que fecha)
			await frames(3)
			continue
		# --- garagem livre ---
		acc_clique += dt * cps
		while acc_clique >= 1.0:
			acc_clique -= 1.0
			var antes := n_clicou
			clicar(PONTO)
			await process_frame
			if n_clicou == antes + 1:
				var n = numero_novo()
				if n == null or n._t > 0.2:
					n_sem_numero += 1
		t_compra += dt
		if t_compra >= 1.0:
			t_compra = 0.0
			comprar_tudo()
		t_foco += dt
		t_risco += dt
		if t_foco >= 60.0:
			t_foco = 0.0
			ajustar_foco()
		if t_risco >= 8.0:
			t_risco = 0.0
			await decidir_luta()
		if gs.tempo_jogo > 62.0 * 60.0 and gs.pode_aposentar():
			marco("62 min sem fim: aposentar")
			await aposentar_clicando()
	marco("TEMPO REAL ESGOTADO")


func ajustar_foco() -> void:
	var opp: Dictionary = gs.proximo_adversario()
	if opp.is_empty() or gs.indice_escada == 0:
		return
	var atr: String = gs.motor.destaque(gs._atributos_array(), gs._array_adversario(opp))
	var mapa := {"strength": "punching_bag", "agility": "jump_rope", "endurance": "treadmill"}
	if gs.aparelho_montado("speed_bag") and gs.foco != "speed_bag" and randf() < 0.5:
		gs.definir_foco("speed_bag")
		return
	if gs.aparelho_montado("grappling_dummy") and gs.foco != "grappling_dummy" and randf() < 0.5:
		gs.definir_foco("grappling_dummy")
		return
	if atr != "" and atr != "strength":
		var alvo: String = mapa[atr]
		gs.definir_foco(alvo if gs.foco == "punching_bag" else "punching_bag")
	else:
		gs.definir_foco("punching_bag")


func comprar_tudo() -> void:
	var tentativas := 0
	var comprou := true
	while comprou and tentativas < 30:
		comprou = false
		tentativas += 1
		for ap in ["treadmill", "jump_rope", "speed_bag", "grappling_dummy"]:
			if not gs.aparelho_existe(ap):
				continue
			if gs.pode_comprar_aparelho(ap) and gs.comprar_aparelho(ap):
				marco("comprou aparelho %s (treino sobrou %s)" % [ap, NumberFormat.fmt(gs.treino)])
				comprou = true
		if gs.pode_comprar_luva():
			var prox: Dictionary = gs.proxima_luva()
			if gs.comprar_luva():
				marco("comprou luva nivel %d" % gs.nivel_luva)
				comprou = true
				continue
		if gs.pode_comprar_metronomo():
			if gs.comprar_metronomo():
				marco("comprou Metronomo nivel %d (money=%d)" % [gs.nivel_metronomo, gs.dinheiro])
				comprou = true
				continue
		if gs.pode_comprar_gerador_pago("gen_paid_1"):
			if gs.comprar_gerador_pago("gen_paid_1"):
				marco("comprou Prof. Nelson #%d" % gs.geradores_pagos["gen_paid_1"])
				comprou = true
				continue
		# treino: melhoria do foco, tio, vizinho, pela razao ganho/custo
		var foco: String = gs.foco
		var m: Dictionary = gs.proxima_melhoria(foco)
		var custo_m: float = float(m.cost) if not m.is_empty() else INF
		var custo_t: float = gs.custo_gerador("retired_uncle")
		var custo_v: float = gs.custo_gerador("neighbor_kid")
		var ganho_m := 0.0
		if not m.is_empty():
			ganho_m = (float(m.multiplier) - 1.0) * gs.por_clique() * cps * 1.2
		var r_m := ganho_m / custo_m if not m.is_empty() else 0.0
		var r_t := 8.0 / custo_t
		var r_v := 1.0 / custo_v
		var melhor := "m" if (r_m >= r_t and r_m >= r_v) else ("t" if r_t >= r_v else "v")
		if melhor == "m" and gs.comprar_melhoria(foco):
			comprou = true
		elif melhor == "t" and gs.comprar_gerador("retired_uncle"):
			comprou = true
			if gs.quantidade_gerador("retired_uncle") == 1:
				marco("comprou o 1o Tio aposentado (renda passiva %s/s, pessoas na garagem=%d)" % [NumberFormat.fmt(gs.producao_total()), gs.pessoas_desenhadas("retired_uncle")])
		elif melhor == "v" and gs.comprar_gerador("neighbor_kid"):
			comprou = true
			if gs.quantidade_gerador("neighbor_kid") == 1:
				marco("comprou o 1o Vizinho (renda passiva %s/s, pessoas na garagem=%d)" % [NumberFormat.fmt(gs.producao_total()), gs.pessoas_desenhadas("neighbor_kid")])


func melhor_tatica() -> String:
	var melhor := ""
	var mp := -1.0
	for t in gs.lutas.taticas:
		var r: Dictionary = gs.risco_tatica(t.id)
		if float(r.chance) > mp:
			mp = float(r.chance)
			melhor = t.id
	return melhor


var perigo_t := 0.0
var mudou_marco := false


func clicar_mudar() -> void:
	for b in cena_painel_atributos().find_children("*", "Button", true, false):
		if not b.disabled and b.visible:
			clicar_botao(b)
			return


func cena_painel_atributos() -> Node:
	return cena.get_node("PainelAtributos")


func decidir_luta() -> void:
	var est: String = gs.estado_escada()
	if est == "move":
		if gs.estado_mudanca() == "ready":
			marco("MUDAR (dinheiro %d)" % gs.dinheiro)
			clicar_mudar()
			await esperar(0.8)
		return
	if est == "end" and gs.pode_aposentar():
		marco("escada da academia completa: aposentar")
		await aposentar_clicando()
		return
	if gs.em_academia() and gs.pode_aposentar() and not gs.proximo_adversario().is_empty():
		var mr: Dictionary = gs.risco_tatica(melhor_tatica())
		if str(mr.label) == "danger":
			perigo_t += 8.0
		else:
			perigo_t = 0.0
		if perigo_t >= 480.0:
			marco("academia: 8 min no vermelho, aposentar (legado %s)" % gs.previa_aposentar().total)
			perigo_t = 0.0
			await aposentar_clicando()
			return
	await decidir_luta_antiga()


func decidir_luta_antiga() -> void:
	if not gs.pode_lutar():
		return
	var opp: Dictionary = gs.proximo_adversario()
	if opp.is_empty():
		# cinturao: aposenta
		if gs.pode_aposentar():
			marco("escada completa: aposentar")
			await aposentar_clicando()
		return
	var t := melhor_tatica()
	var r: Dictionary = gs.risco_tatica(t)
	var rot := str(r.label)
	var quer := false
	if gs.algoz() != "":
		quer = (rot == "easy")  # algoz e quem vem antes: so no verde (dica da tela de fim)
	else:
		quer = (rot == "easy" or rot == "even")
	if not quer:
		return
	gs.definir_tatica(t)
	await abrir_previa_e_lutar(opp, rot)


func abrir_previa_e_lutar(opp: Dictionary, rot: String) -> void:
	var b: Button = barra._lutar
	clicar_botao(b)
	var t0 := Time.get_ticks_msec()
	while fluxo.janela == null and Time.get_ticks_msec() - t0 < 4000:
		await process_frame
	if fluxo.janela == null:
		marco("ERRO: previa nao abriu ao clicar LUTAR!")
		return
	await esperar(1.2)
	marco("previa de %s: risco=%s revenge=%s wait_green=%s" % [opp.id, rot, gs.previa().revenge, gs.previa().wait_green])
	shot_uma_vez("previa_%s_c%d" % [opp.id, carreira_atual])
	var lutar := achar_botao(fluxo.janela, "LUTAR!")
	if lutar == null:
		marco("ERRO: botao LUTAR! da previa nao achado")
		return
	clicar_botao(lutar)
	await frames(5)


func tratar_janela(jan) -> void:
	await esperar(1.0 / maxf(escala, 1.0) + 0.6)
	if jan != fluxo.janela:
		return
	if nome_janela(jan) == "JanelaArte":
		shot_uma_vez("arte_c%d" % carreira_atual)
		marco("JanelaArte aberta (primeira=%s)" % gs.escolha_arte_primeira())
		var alvo := 0 if (carreira_atual % 2) == 1 else 1
		var bs: Array = []
		for b in jan.find_children("*", "Button", true, false):
			if b.visible and b.size.x > 40 and b.size.y < 30:
				bs.append(b)
		clicar_botao(bs[alvo] if bs.size() > alvo else bs[0])
		await frames(5)
		marco("arte escolhida: %s" % gs.arte_id)
	elif nome_janela(jan) == "JanelaVitoria":
		shot_uma_vez("vitoria_c%d_i%d" % [carreira_atual, gs.indice_escada])
		var res: Dictionary = {}
		marco("VITORIA (escada=%d, money=%d, fama=%d, legado em jogo=%d)" % [gs.indice_escada, gs.dinheiro, gs.fama, gs.legado_em_jogo()])
		var b := achar_botao(jan, "CONTINUAR")
		if b != null:
			clicar_botao(b)
		await frames(5)
	elif nome_janela(jan) == "JanelaFim":
		shot_uma_vez("fim_c%d" % carreira_atual)
		var f: Dictionary = gs.fim
		marco("FIM DE CARREIRA kind=%s legado ganho=%s total=%s algoz=%s tempo=%s" % [f.kind, f.legacy_gained, f.legacy_total, gs.algoz(), fmt(gs.tempo_jogo)])
		var textos: Dictionary = gs.textos_fim(f)
		marco("  textos fim: reason=%s | tip=%s | wait_green=%s" % [textos.reason, textos.tip, textos.get("wait_green", "")])
		# a dica do atributo: foco na carreira seguinte (o jogador le a tela)
		var arvore := achar_botao(jan, "ÁRVORE")
		if arvore != null and gs.legado_disponivel() > 0 and max(carreira_atual, 1) < 99:
			clicar_botao(arvore)
			await esperar(1.0)
		else:
			var nc := achar_botao(jan, "NOVA CARREIRA")
			clicar_botao(nc)
			await frames(5)
	elif nome_janela(jan) == "JanelaArvore":
		shot_uma_vez("arvore_c%d" % carreira_atual)
		await comprar_nos_clicando(jan)
		var nc := achar_botao(jan, "NOVA CARREIRA")
		clicar_botao(nc)
		await frames(5)
	else:
		# previa ou confirmacao fora do fluxo: fecha
		var b := achar_botao(jan, "VOLTAR A TREINAR")
		if b != null:
			clicar_botao(b)
		await frames(5)


const ORDEM_DICA := ["body_jab", "career_purse", "body_muscle_memory", "career_scouting", "body_crew",
	"career_crowd", "body_heavy_hands", "career_purse_2", "body_crew_2", "career_good_loser"]


func comprar_nos_clicando(jan) -> void:
	var seguir := true
	var guarda := 0
	while seguir and guarda < 12:
		guarda += 1
		seguir = false
		for id in ORDEM_DICA:
			if gs.estado_no(id) == "buyable":
				var cel: Control = jan._celulas[id].cel
				clicar(cel.get_global_rect().get_center())
				await esperar(0.6)
				marco("comprou no '%s' (legado agora %d)" % [id, gs.legado_disponivel()])
				seguir = true
				break
	shot_uma_vez("arvore_depois_c%d" % carreira_atual)


func aposentar_clicando() -> void:
	clicar_botao(barra._aposentar)
	await esperar(0.8)
	if fluxo.janela != null:
		var b := achar_botao(fluxo.janela, "APOSENTAR")
		if b != null:
			clicar_botao(b)
	await frames(5)


func nome_janela(j) -> String:
	var s = j.get_script()
	return str(s.get_global_name()) if s != null else ""
