extends "res://tests/test_base.gd"
## Fase 7a2 (Treino fora de hora): dados, lógica do Choque e da Panfletagem (determinística com semente), convite do Osmar,
## relógio parado fora da sala, prêmios, AQUECIDO (prévia honesta), save e Gato Preto.
## Referência: docs/fases/fase7a2-design.md e tools/sim/fase7a2_sim.py. Tudo em pastas de user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")

var mg: MinigamesData


func rodar_testes() -> void:
	mg = MinigamesData.carregar()
	_teste_dados()
	_teste_choque_deterministico()
	_teste_choque_mecanica()
	_teste_choque_jj()
	_teste_panfleto()
	_teste_convite_frequencia()
	_teste_convite_escolha()
	_teste_convite_esconde_e_fecha()
	_teste_ir_nao_custa()
	_teste_premios()
	_teste_aquecido()
	_teste_save()
	_teste_gato_preto()
	_teste_arquivo_ausente()


# ---------------- ajuda ----------------
func _novo(nome: String, arte: String = "", calendario: bool = false, garagem_salva: bool = false) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	if not calendario:
		gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	if arte != "":
		gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		gs.escolher_arte(arte)
	if garagem_salva:
		gs._gravar_marco("garage_saved", {}, false)
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


# Avança `s` segundos em passos de 0,1 s, sem deixar balão de fala por cima (as falas não são o assunto deste teste).
func _andar(g: Node, s: float) -> void:
	var n := int(round(s / 0.1))
	for i in n:
		g.tick(0.1)
		g._balao = {}
		g._gesto = {}


func _equipe(g: Node) -> void:
	g.geradores[str(g.dados.geradores[0].id)] = 20


func _rng(semente: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	return r


# ---------------- dados ----------------
func _teste_dados() -> void:
	checar(not mg.vazio, "minigames.json carregado")
	checar_igual(mg.spar.levels.size(), 6, "Choque tem 6 níveis")
	checar_igual(mg.flyers.levels.size(), 6, "Panfletagem tem 6 níveis")
	checar_igual(mg.invite.first_after_s, 300.0, "1º convite aos 300 s")
	checar_igual(mg.invite.interval_s, 240.0, "convite a cada 240 s")
	checar(mg.spar.levels[5].warn_s < mg.spar.levels[0].warn_s, "o aviso encurta com o nível")
	# faixa e linhas a menos
	var tmp := "user://test/minigames_ruim.json"
	DirAccess.make_dir_recursive_absolute("user://test/")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MinigamesData.CAMINHO))
	d.invite.interval_s = 99999999.0
	d.spar.levels = [d.spar.levels[0], d.spar.levels[1]]
	d.flyers.erase("goal")
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	var r := MinigamesData.carregar(tmp)
	checar_igual(r.invite.interval_s, 36000.0, "número fora da faixa é recortado")
	checar_igual(r.spar.levels.size(), 6, "menos de 6 linhas repete a última")
	checar_igual(r.spar.levels[5].warn_s, r.spar.levels[1].warn_s, "a linha repetida é a última")
	checar(r.flyers.is_empty() and not r.spar.is_empty() and not r.vazio, "campo faltando desliga só a Panfletagem")


# ---------------- Choque ----------------
func _jogar_ritmo(arte: String, nivel: int, semente: int, cps: float) -> int:
	var c := ChoqueLogica.new(mg.spar, arte, nivel, _rng(semente))
	c.passo(mg.spar.countdown_s + 0.05)
	var prox := 0.0
	var t := 0.0
	while c.fase == "jogando":
		if t >= prox:
			c.apertar()
			c.soltar()
			prox += 1.0 / cps
		c.passo(0.02)
		t += 0.02
	return c.pontos


func _teste_choque_deterministico() -> void:
	var a := _jogar_ritmo("boxing", 3, 42, 4.3)
	var b := _jogar_ritmo("boxing", 3, 42, 4.3)
	checar_igual(a, b, "Choque: mesma semente e mesmas entradas = mesmo resultado")
	var r1 := ChoqueLogica.new(mg.spar, "boxing", 2, _rng(7)).roteiro()
	var r2 := ChoqueLogica.new(mg.spar, "boxing", 2, _rng(7)).roteiro()
	checar(r1 == r2 and not r1.is_empty(), "roteiro de padrões igual com a mesma semente")
	var r3 := ChoqueLogica.new(mg.spar, "boxing", 2, _rng(8)).roteiro()
	checar(r1 != r3, "semente diferente muda o roteiro")
	# dura 30 s fixos depois de 2 s de contagem
	var c := ChoqueLogica.new(mg.spar, "boxing", 0, _rng(1))
	c.passo(1.9)
	checar_igual(c.fase, "contagem", "contagem de 2 s")
	c.passo(0.2)
	checar_igual(c.fase, "jogando", "depois da contagem joga")
	c.passo(29.8)
	checar_igual(c.fase, "jogando", "ainda joga aos 29,9 s")
	c.passo(0.3)
	checar_igual(c.fase, "fim", "acaba aos 30 s")
	# SAIR na contagem dá 0 pontos e a nota do piso
	var s := ChoqueLogica.new(mg.spar, "bjj", 0, _rng(1))
	s.sair()
	checar(s.fase == "fim" and s.saiu and s.pontos == 0 and absf(s.nota() - 0.25) < 1.0e-9 and not s.venceu(), "SAIR antes de começar: piso 0,25")


func _primeiro(c: ChoqueLogica, tipo: String) -> Dictionary:
	for p in c.roteiro():
		if p.tipo == tipo:
			return p
	return {}


# Cria um Choque cujo 1º padrão é `tipo` (procura uma semente).
func _com_primeiro(arte: String, tipo: String, nivel: int = 0) -> ChoqueLogica:
	for sem in 500:
		var c := ChoqueLogica.new(mg.spar, arte, nivel, _rng(sem))
		var r := c.roteiro()
		if not r.is_empty() and r[0].tipo == tipo:
			return c
	return null


func _ir_ate(c: Object, t: float) -> void:
	# anda até o tempo de JOGO `t` (a contagem passa antes)
	if c.fase == "contagem":
		c.passo(mg.spar.countdown_s + 0.021)
	while c.tempo < t - 1.0e-9 and c.fase == "jogando":
		c.passo(0.02)


func _teste_choque_mecanica() -> void:
	# afobado perde para quem clica com calma (fôlego)
	var calmo := 0.0
	var afobado := 0.0
	for s in 30:
		calmo += _jogar_ritmo("boxing", 0, 100 + s, 4.3)
		afobado += _jogar_ritmo("boxing", 0, 100 + s, 9.0)
	checar(calmo > afobado, "Boxe: 9 cliques/s rende menos que 4,3/s (fôlego): %.1f x %.1f" % [calmo / 30.0, afobado / 30.0])
	# o clique gasta fôlego e a força cai
	var c := ChoqueLogica.new(mg.spar, "boxing", 0, _rng(3))
	c.passo(2.05)
	var f0: float = c.estado().forca
	c.apertar()
	c.soltar()
	checar(c.estado().forca < f0, "clique gasta fôlego")
	# clique na pausa vale x2
	var p := _com_primeiro("boxing", "pause")
	checar(p != null, "achei uma semente com pausa primeiro")
	var pa := _primeiro(p, "pause")
	_ir_ate(p, pa.i + 0.1)
	var e1 := p.estado()
	checar(e1.padrao == "pause" and e1.momento == "ativo" and e1.x2, "na pausa: ativa e x2")
	var b0: float = p.barra
	p.apertar()
	var dp: float = p.barra - b0
	var esperado: float = mg.spar.variants.boxing.push_per_click * e1.forca * mg.spar.counter_mult
	checar(absf(dp - esperado) < 1.0e-9, "clique na pausa empurra x2 (%.4f)" % dp)
	var n := _com_primeiro("boxing", "pause")
	n.passo(2.05)
	var e2 := n.estado()
	var b1: float = n.barra
	n.apertar()
	var dn: float = n.barra - b1
	checar(absf(dn - mg.spar.variants.boxing.push_per_click * e2.forca) < 1.0e-9, "clique normal empurra x1")
	# guarda anula a rajada
	var g1 := _com_primeiro("boxing", "burst")
	var g2 := _com_primeiro("boxing", "burst")
	var bu := _primeiro(g1, "burst")
	_ir_ate(g1, bu.i + 0.05)
	_ir_ate(g2, bu.i + 0.05)
	g1.apertar()  # segura (guarda)
	g1.passo(0.25)  # 0,2 s de segurar já vira guarda
	var antes: float = g1.barra
	var ant2: float = g2.barra
	g1.passo(0.4)
	g2.passo(0.65)
	checar(g1.estado().guarda, "segurar 0,2 s vira guarda")
	checar(absf(g1.barra - antes) < 1.0e-9, "guarda na rajada: ela não empurra nada")
	checar(g2.barra < ant2 - 0.3 or g2.pontos_dele > 0, "sem guarda a rajada empurra (%.2f)" % (g2.barra - ant2))
	# a finta vira branca na metade do aviso
	var ft := _com_primeiro("boxing", "feint")
	if ft == null:
		for nv in range(1, 6):
			ft = _com_primeiro("boxing", "feint", nv)
			if ft != null:
				break
	var fp := _primeiro(ft, "feint")
	_ir_ate(ft, fp.a + 0.1 * ft.estado().get("aviso_frac", 0.0) + 0.05)
	checar_igual(ft.estado().sinal, "red", "finta: começa vermelha")
	_ir_ate(ft, fp.a + (fp.i - fp.a) * 0.6)
	checar_igual(ft.estado().sinal, "white", "finta: vira branca na metade do aviso")
	var evs: Array = ft.pegar_eventos()
	checar("finta_virou" in evs and "aviso_feint" in evs, "eventos da finta")
	# aviso da rajada: vermelho, e a pausa avisa branco
	var rb := _com_primeiro("boxing", "burst")
	_ir_ate(rb, _primeiro(rb, "burst").a + 0.1)
	checar(rb.estado().momento == "aviso" and rb.estado().sinal == "red", "rajada avisa em vermelho")
	# 6 níveis lidos do JSON: o aviso real do roteiro
	for nv in 6:
		var cn := ChoqueLogica.new(mg.spar, "boxing", nv, _rng(5))
		var bn := _primeiro(cn, "burst")
		if not bn.is_empty():
			checar(absf((bn.i - bn.a) - mg.spar.levels[nv].warn_s) < 1.0e-9, "nível %d: aviso da rajada = %.2f" % [nv, mg.spar.levels[nv].warn_s])


func _teste_choque_jj() -> void:
	var c := _com_primeiro("bjj", "burst")
	var d := _com_primeiro("bjj", "burst")
	var bu := _primeiro(c, "burst")
	_ir_ate(c, bu.i + 0.05)
	_ir_ate(d, bu.i + 0.05)
	d.apertar()  # d segura durante a puxada forte
	var b0: float = c.barra
	var d0: float = d.barra
	c.passo(0.4)
	d.passo(0.4)
	checar(absf(c.barra - b0) < 1.0e-9, "JJ solto na puxada forte: ele não puxa nada")
	checar(d.barra < d0 - 0.2 or d.barra != d0, "JJ segurando na puxada forte: ela puxa")
	# fôlego: segurar gasta (x2 na puxada forte), soltar recupera
	var e := ChoqueLogica.new(mg.spar, "bjj", 0, _rng(9))
	e.passo(2.05)
	e.apertar()
	e.passo(1.0)
	var f1: float = e.folego
	checar(f1 < 1.0, "JJ segurando gasta fôlego")
	e.soltar()
	e.passo(1.0)
	checar(e.folego > f1, "JJ solto recupera fôlego")
	# segurar o tempo todo perde para o ritmo
	var tudo := 0
	var ritmo := 0
	for s in 20:
		tudo += _jj_segurando(s, true)
		ritmo += _jj_segurando(s, false)
	checar(ritmo >= tudo, "JJ: segurar sempre não rende mais que o ritmo")
	# pausa vale x2 no JJ
	var p := _com_primeiro("bjj", "pause")
	var pa := _primeiro(p, "pause")
	_ir_ate(p, pa.i + 0.05)
	var forca: float = p.estado().forca
	var antes: float = p.barra
	p.apertar()
	p.passo(0.1)
	var ganho: float = p.barra - antes
	var esperado: float = mg.spar.variants.bjj.pull_per_s * forca * mg.spar.counter_mult * 0.1
	checar(absf(ganho - esperado) < 0.02, "JJ: segurar na pausa puxa x2 (%.3f ~ %.3f)" % [ganho, esperado])


func _jj_segurando(semente: int, sempre: bool) -> int:
	var c := ChoqueLogica.new(mg.spar, "bjj", 2, _rng(300 + semente))
	c.passo(2.05)
	var t := 0.0
	while c.fase == "jogando":
		var ph := fmod(t, 3.0)
		var seg := sempre or ph < 2.0
		var rajada: bool = c.estado().padrao == "burst"
		if rajada and not sempre:
			seg = false
		if seg and not c.estado().segurando:
			c.apertar()
		elif not seg and c.estado().segurando:
			c.soltar()
		c.passo(0.02)
		t += 0.02
	return c.pontos


# ---------------- Panfletagem ----------------
func _panf(nivel: int, semente: int) -> PanfletoLogica:
	return PanfletoLogica.new(mg.flyers, nivel, _rng(semente))


func _primeira_pessoa(j: PanfletoLogica, filtro: Callable) -> Dictionary:
	for p in j._pessoas:
		if filtro.call(p):
			return p
	return {}


func _andar_panf(j: PanfletoLogica, t: float) -> void:
	if j.fase == "contagem":
		j.passo(mg.flyers.countdown_s + 0.021)
	while j.tempo < t - 1.0e-9 and j.fase == "jogando":
		j.passo(0.02)


func _teste_panfleto() -> void:
	checar(_panf(0, 5)._pessoas.size() == _panf(0, 5)._pessoas.size() and _panf(0, 5)._pessoas[0].t == _panf(0, 5)._pessoas[0].t, "Panfletagem determinística")
	var j := _panf(0, 11)
	var p := _primeira_pessoa(j, func(x): return x.interessado and x.s1 < 25.0)
	_andar_panf(j, p.s0 + 0.05)
	checar_igual(j.sinal_de(p), "interesse", "interessado dá o sinal")
	checar_igual(j.clicar(p.id), "aceitou", "clicar em quem dá o sinal: ACEITOU")
	checar_igual(j.aceitos, 1, "+1")
	checar_igual(j.clicar(-1), "ocupado", "mão ocupada 0,35 s depois de entregar")
	j.passo(0.4)
	checar(not j.estado().mao_ocupada, "mão livre depois de 0,35 s")
	# erro: meio ponto, nunca abaixo de 0, 0,8 s de mão ocupada
	var k := _panf(0, 12)
	_andar_panf(k, 3.0)
	checar_igual(k.clicar(-1), "erro", "clique no vazio é erro")
	checar_igual(k.erros, 1, "1 erro")
	checar_igual(k.liquidos(), 0.0, "nunca abaixo de 0")
	k.passo(0.7)
	checar_igual(k.clicar(-1), "ocupado", "0,8 s de mão ocupada depois do erro")
	k.passo(0.15)
	checar_igual(k.clicar(-1), "erro", "livre depois de 0,8 s")
	k.aceitos = 4
	k.erros = 2
	checar(absf(k.liquidos() - 3.0) < 1.0e-9, "4 aceitos e 2 erros = 3 líquidos")
	# sinal falso some na metade (45% do sinal) e termina em cara fechada
	var m := _panf(5, 21)
	var f := _primeira_pessoa(m, func(x): return x.falso)
	checar(not f.is_empty(), "nível 5 tem sinal falso")
	_andar_panf(m, f.s0 + 0.05)
	checar_igual(m.sinal_de(f), "falso", "sinal falso aparece")
	checar(absf((f.s1 - f.s0) - mg.flyers.levels[5].tell_s * 0.45) < 1.0e-9, "sinal falso dura 45% do sinal de verdade")
	_andar_panf(m, f.s1 + 0.05)
	checar_igual(m.sinal_de(f), "fechada", "sinal falso some e termina fechado")
	var falsos0 := _primeira_pessoa(_panf(0, 21), func(x): return x.falso)
	checar(falsos0.is_empty(), "nível 0 não tem sinal falso")
	# clicar em quem não quer ou fora do sinal = erro, e a pessoa fica resolvida
	var n := _panf(0, 31)
	var q := _primeira_pessoa(n, func(x): return not x.interessado)
	_andar_panf(n, q.t + 0.5)
	checar_igual(n.clicar(q.id), "erro", "clicar em quem não quer = NÃO, VALEU")
	n.passo(1.0)
	checar_igual(n.clicar(q.id), "ignorado", "pessoa já resolvida: sem multa dupla")
	# 30 s e SAIR
	var o := _panf(2, 1)
	o.passo(2.05)
	o.passo(30.1)
	checar_igual(o.fase, "fim", "Panfletagem acaba aos 30 s")
	var s := _panf(2, 1)
	s.sair()
	checar(s.fase == "fim" and absf(s.nota() - 0.25) < 1.0e-9, "SAIR antes de começar: piso")
	# FAMA exata pela tabela do design (aceitos 0, 5, 10, 12)
	var esperado := {10: [1, 3, 5, 5], 30: [2, 5, 8, 8], 60: [4, 9, 15, 15], 100: [6, 16, 25, 25], 120: [8, 19, 30, 30], 200: [13, 31, 50, 50]}
	var ok := true
	for pf in esperado:
		var i := 0
		for ac in [0, 5, 10, 12]:
			var jj := _panf(0, 1)
			jj.aceitos = ac
			if jj.fama(float(pf)) != esperado[pf][i]:
				ok = false
				print("  fama %d aceitos %d: %d (esperado %d)" % [pf, ac, jj.fama(float(pf)), esperado[pf][i]])
			i += 1
	checar(ok, "FAMA da Panfletagem pela fórmula (pisos 1/2/4/6/8/13; tetos 5/8/15/25/30/50)")


# ---------------- convite ----------------
func _teste_convite_frequencia() -> void:
	var g := _novo("f7a2_freq", "boxing")
	var primeiro := -1.0
	var segundo := -1.0
	var sumiu := -1.0
	var t := 0.0
	while t < 700.0:
		g.tick(0.1)
		g._balao = {}
		t += 0.1
		var ab: String = g.convite.open
		if ab != "" and primeiro < 0.0:
			primeiro = float(g.convite.room_s)
		elif ab == "" and primeiro >= 0.0 and sumiu < 0.0:
			sumiu = float(g.convite.room_s)
		elif ab != "" and sumiu >= 0.0 and segundo < 0.0:
			segundo = float(g.convite.room_s)
	checar(primeiro >= 299.9 and primeiro <= 300.3, "1º convite aos 300 s de sala (%.1f)" % primeiro)
	checar(sumiu - primeiro >= 59.9 and sumiu - primeiro <= 60.4, "ignorado some em 60 s de sala (%.1f)" % (sumiu - primeiro))
	checar(segundo - primeiro >= 239.9 and segundo - primeiro <= 240.3, "o seguinte vem 240 s depois do anterior (%.1f)" % (segundo - primeiro))
	_liberar(g)
	# sem arte e sem o marco: nunca aparece (1ª carreira antes do cinturão)
	var h := _novo("f7a2_sem")
	_andar(h, 700.0)
	checar_igual(h.convite.open, "", "sem arte e sem garage_saved: nenhum convite")
	_liberar(h)


func _teste_convite_escolha() -> void:
	var g := _novo("f7a2_esc", "boxing", false, true)
	var seq: Array = []
	var vistos := 0
	var t := 0.0
	while t < 1300.0 and seq.size() < 4:
		g.tick(0.1)
		g._balao = {}
		t += 0.1
		if g.convite.open != "" and vistos == 0:
			seq.append(g.convite.open)
			vistos = 1
		elif g.convite.open == "":
			vistos = 0
	checar_igual(seq, ["spar", "flyers", "spar", "flyers"], "1º é o Choque e depois alterna")
	_liberar(g)
	# só um elegível
	var a := _novo("f7a2_so_flyers", "", false, true)
	_andar(a, 305.0)
	checar_igual(a.convite.open, "flyers", "sem arte: só Panfletagem")
	_liberar(a)
	var b := _novo("f7a2_so_spar", "bjj")
	_andar(b, 305.0)
	checar_igual(b.convite.open, "spar", "sem garage_saved: só Choque")
	_liberar(b)
	# AQUECIDO guardado: Panfletagem
	var w := _novo("f7a2_warm", "boxing", false, true)
	w.convite["warm"] = true
	_andar(w, 305.0)
	checar_igual(w.convite.open, "flyers", "AQUECIDO guardado: o Osmar chama a Panfletagem")
	_liberar(w)


func _teste_convite_esconde_e_fecha() -> void:
	var g := _novo("f7a2_fecha", "boxing", false, true)
	_andar(g, 305.0)
	checar_igual(g.convite_visivel(), "spar", "balão visível aos 305 s")
	var rs: float = g.convite.room_s
	# janela: escondido e o tempo dele para (a sala não anda)
	g.definir_modal(true)
	_andar(g, 100.0)
	checar_igual(g.convite_visivel(), "", "com janela aberta o balão fica escondido")
	checar_igual(g.convite.room_s, rs, "o relógio do convite para com janela")
	g.definir_modal(false)
	checar_igual(g.convite_visivel(), "spar", "a janela fecha: o mesmo balão volta")
	# fala na tela: escondido e o tempo do balão não corre
	g._balao = {"id": "x", "ate": 1.0e12}
	var desde: float = g.convite.room_s - g.convite.open_since
	for i in 1000:
		g.tick(0.1)
	checar_igual(g.convite_visivel(), "", "com balão de fala o convite se esconde")
	checar_igual(g.convite.open, "spar", "e continua aberto (não é cancelado)")
	checar(absf((g.convite.room_s - g.convite.open_since) - desde) < 0.5, "o tempo de visibilidade não corre escondido")
	g._balao = {}
	# MUDAR fecha em silêncio
	g.local_id = "gym"
	g.tick(0.1)
	checar_igual(g.convite.open, "", "mudar de local fecha o convite")
	_liberar(g)
	# dia da luta fecha
	var h := _novo("f7a2_dia", "boxing", true, true)
	h.convite["open"] = "spar"
	h.convite["open_since"] = h.convite.room_s
	h.tick(0.1)
	h._balao = {}
	checar_igual(h.convite.open, "spar", "convite aberto antes do dia da luta")
	h.segundos_campanha = float(h.fight_day - 1) * 30.0 - 0.05
	h.tick(0.2)
	checar(h.no_dia_da_luta(), "chegou o dia da luta")
	checar_igual(h.convite.open, "", "o dia da luta fecha o convite")
	checar_igual(h.convite_visivel(), "", "e não há balão")
	_liberar(h)
	# luta em andamento: nada abre
	var k := _novo("f7a2_luta", "boxing", false, true)
	k.atributos = {"strength": 1.0e6, "agility": 1.0e6, "endurance": 1.0e6}
	k.lutar()
	var r0: float = k.convite.room_s
	_andar(k, 400.0)
	checar_igual(k.convite.room_s, r0, "com luta em andamento o relógio do convite não anda")
	checar_igual(k.convite.open, "", "e nenhum convite abre")
	_liberar(k)


func _abrir_convite(g: Node, tipo: String) -> void:
	g.convite["open"] = tipo
	g.convite["open_since"] = g.convite.room_s
	g.tick(0.01)
	g._balao = {}


func _teste_ir_nao_custa() -> void:
	var g := _novo("f7a2_ir", "boxing", true, true)
	_equipe(g)
	g.foco = "speed_bag" if g.aparelho_montado("speed_bag") else g.foco
	_abrir_convite(g, "spar")
	checar_igual(g.convite_visivel(), "spar", "convite visível")
	var seg: float = g.segundos_campanha
	var prod: float = g.producao_total()
	checar(prod > 0.0, "equipe produzindo")
	var t0: float = g.treino
	var info: Dictionary = g.convite_ir()
	checar(info.get("kind", "") == "spar" and info.get("level", -1) == 0 and info.get("variant", "") == "boxing", "IR devolve o minigame")
	checar_igual(g.convite.open, "", "IR consome o convite")
	checar(not g.sala_ativa() and g.treino_fora == "spar", "fora da sala: sala_ativa falso")
	var j = g.treino_jogo()
	checar(j is ChoqueLogica, "a lógica do Choque está pronta")
	_andar(g, 20.0)
	checar_igual(g.segundos_campanha, seg, "relógio da campanha parado")
	checar(absf((g.treino - t0) - prod * 20.0) < 1.0e-6 * maxf(1.0, prod * 20.0), "treino sobe exatamente produção x tempo (%.4f)" % (g.treino - t0))
	_andar(g, 15.0)
	checar_igual(j.fase, "fim", "o tick faz o minigame correr até o fim")
	var rs: float = g.convite.room_s
	var p: Dictionary = g.treino_concluir()
	checar(p.pontos == 0 and p.nota == 0.25 and p.treino > 0.0, "sem fazer nada: piso > 0")
	checar_igual(g.treino_concluir(), p, "concluir de novo devolve o mesmo (nada em dobro)")
	# parado na tela de prêmio: a equipe não produz e o relógio não anda
	var t_premio: float = g.treino
	_andar(g, 100.0)
	checar_igual(g.treino, t_premio, "100 s na tela de prêmio: 0 de produção")
	checar_igual(g.segundos_campanha, seg, "e o relógio da campanha continua parado")
	checar_igual(g.treino_fora, "spar", "a tela de prêmio segue aberta (trava de 120 s ainda não venceu)")
	g.treino_voltar()
	checar(g.treino_fora == "" and g.sala_ativa(), "VOLTAR devolve a sala")
	checar(g.convite.next_at >= rs + 60.0 - 1.0e-6, "depois de jogar: pelo menos 60 s de sala até o próximo")
	_liberar(g)
	# SAIR no meio, em qualquer hora
	var h := _novo("f7a2_sair", "bjj", false, true)
	_abrir_convite(h, "flyers")
	h.convite_ir()
	_andar(h, 5.0)
	var q: Dictionary = h.treino_concluir()
	checar(q.kind == "flyers" and q.saiu and q.fama >= 1, "SAIR no meio: leva o piso de FAMA")
	h.treino_voltar()
	_liberar(h)


# ---------------- prêmios ----------------
func _teste_premios() -> void:
	for arte in ["boxing", "bjj"]:
		for pontos in [0, 1, 3, 5]:
			var g := _novo("f7a2_prem_" + arte + str(pontos), arte, false, true)
			_equipe(g)
			_abrir_convite(g, "spar")
			g.convite_ir()
			var j: ChoqueLogica = g.treino_jogo()
			j.passo(2.05)
			j.pontos = pontos
			var ref: float = g.producao_total() + 3.0 * g.por_clique()
			var nota := 0.25 + 0.75 * minf(1.0, float(pontos) / 3.0)
			var t0: float = g.treino
			var antes: Dictionary = g.atributos.duplicate()
			var p: Dictionary = g.treino_concluir()
			var esp := 20.0 * ref * nota
			checar(absf(p.treino - esp) < 1.0e-6 * esp and absf((g.treino - t0) - esp) < 1.0e-6 * esp, "%s %d pontos: 20 x ref x nota = %.2f" % [arte, pontos, esp])
			var div: Dictionary = g.divisao_aparelho(str(g.academia.arte(arte).apparatus))
			var soma := 0.0
			var ok := true
			for id in div:
				var d: float = g.atributos[id] - antes[id]
				soma += d
				if absf(d - esp * float(div[id])) > 1.0e-6 * esp:
					ok = false
			checar(ok and absf(soma - esp) < 1.0e-6 * esp, "%s: o prêmio vai pela divisão do aparelho da arte" % arte)
			checar_igual(p.venceu, pontos >= 3, "%s %d pontos: VENCEU = %s" % [arte, pontos, str(pontos >= 3)])
			g.treino_voltar()
			_liberar(g)
	# FAMA da Panfletagem entra no saldo e depende do próximo adversário
	var h := _novo("f7a2_fama", "boxing", false, true)
	_abrir_convite(h, "flyers")
	h.convite_ir()
	h.treino_jogo().aceitos = 10
	var f0: int = h.fama
	var p: Dictionary = h.treino_concluir()
	var pf: float = h.lutas.adversarios[0].prize_fame
	checar_igual(p.fama, maxi(1, int(floor(maxf(5.0, 0.25 * pf) + 0.5))), "FAMA cheia = 1/4 da FAMA da luta (mín. 5)")
	checar_igual(h.fama, f0 + p.fama, "a FAMA entra no saldo")
	h.treino_voltar()
	_liberar(h)


# ---------------- AQUECIDO ----------------
func _pct(g: Node, c: float) -> int:
	return int(g._textos._porcentagem(c))


func _teste_aquecido() -> void:
	var g := _novo("f7a2_warm_previa", "boxing", false, true)
	g.atributos = {"strength": 900.0, "agility": 70.0, "endurance": 600.0}
	var sem: Dictionary = g.previa()
	checar(not sem.has("warm") and not sem.has("warm_line"), "sem AQUECIDO a prévia não ganha chave nenhuma")
	g.convite["warm"] = true
	var com: Dictionary = g.previa()
	checar(com.get("warm", false) and str(com.get("warm_line", "")).begins_with("AQUECIDO"), "com AQUECIDO a prévia mostra a linha: " + str(com.get("warm_line", "")))
	var opp: Dictionary = g.proximo_adversario()
	var adv: Array = g._array_adversario(opp)
	var cru := [900.0, 70.0, 600.0]
	var m := 1.03
	var q := [900.0 * m, 70.0 * m, 600.0 * m]
	var tat: String = g.tatica
	var chance_com: float = g.motor.chance_detalhada(q, adv, tat).chance
	var chance_sem: float = g.motor.chance_detalhada(cru, adv, tat).chance
	checar(absf(com.risks[tat].chance - chance_com) < 1.0e-12, "prévia: a chance mostrada é a do motor com atributos x1,03")
	checar(absf(g.risco_tatica(tat).chance - g.motor.chance(q, adv, tat)) < 1.0e-12, "risco do HUD e prévia usam a mesma conta")
	checar_igual(com.warm_gain, _pct(g, chance_com) - _pct(g, chance_sem), "+N NA CHANCE = chance com - chance sem")
	checar_igual(com.warm_pct, 3, "+3% nos atributos")
	checar(com.you.strength == 900.0, "a prévia continua mostrando os atributos de verdade")
	checar(com.risks[tat].chance >= sem.risks[tat].chance, "AQUECIDO nunca piora a chance")
	# lutar gasta; a luta salva os atributos x1,03
	g.atributos = {"strength": 9.0e6, "agility": 9.0e6, "endurance": 9.0e6}
	checar(g.aquecido(), "AQUECIDO guardado")
	var l: Dictionary = g.lutar()
	checar(not l.is_empty(), "lutou")
	checar(absf(g.luta.player.strength - 9.0e6 * 1.03) < 1.0, "a luta usa os atributos x1,03")
	checar(not g.aquecido() and not g.convite.warm, "o AQUECIDO é gasto quando a luta começa")
	g.concluir_luta()
	_liberar(g)
	# vencer guarda; vencer de novo não soma; escada completa não dá; nova campanha zera
	var h := _novo("f7a2_warm_guarda", "boxing", false, true)
	_abrir_convite(h, "spar")
	h.convite_ir()
	h.treino_jogo().pontos = 3
	var p: Dictionary = h.treino_concluir()
	checar(p.venceu and p.aquecido and h.aquecido(), "vencer o Choque guarda o AQUECIDO")
	h.treino_voltar()
	h.convite["open"] = "spar"
	h.convite["open_since"] = h.convite.room_s
	h.tick(0.01)
	h._balao = {}
	h.convite_ir()
	h.treino_jogo().pontos = 3
	var p2: Dictionary = h.treino_concluir()
	checar(p2.venceu and not p2.aquecido and p2.aquecido_ja, "com ele guardado, vencer de novo não soma")
	h.treino_voltar()
	h._zerar_carreira()
	checar(not h.aquecido() and h.convite.next_at == 300.0 and h.convite.room_s == 0.0, "nova campanha zera o convite e o AQUECIDO")
	_liberar(h)
	var k := _novo("f7a2_warm_fim", "boxing", false, true)
	k.indice_escada = k.lutas.adversarios.size()
	_abrir_convite(k, "spar")
	k.convite_ir()
	k.treino_jogo().pontos = 3
	var p3: Dictionary = k.treino_concluir()
	checar(p3.venceu and p3.sem_luta and not p3.aquecido and not k.aquecido(), "sem luta marcada o Choque não dá AQUECIDO")
	k.treino_voltar()
	_liberar(k)


# ---------------- save ----------------
func _teste_save() -> void:
	var pasta := pasta_limpa("f7a2_save")
	var g: Node = GameStateScript.new()
	g.inicializar(pasta, "res://data/config.json")
	g.autosave_ativo = false
	g.risco_hud_ativo = false
	g.permanente["arts_unlocked"] = ["boxing"]
	g.escolher_arte("boxing")
	g.convite = {"room_s": 123.5, "next_at": 400.0, "open": "spar", "open_since": 100.0, "last": "spar", "warm": true}
	g.salvar()
	var estado: Dictionary = g.para_save()
	checar(estado.career.has("training_invite"), "o save leva career.training_invite")
	checar_igual(int(g.store.carregar().estado.get("version", 13)), 13, "continua v13")
	_liberar(g)
	var h: Node = GameStateScript.new()
	h.inicializar(pasta, "res://data/config.json")
	h.autosave_ativo = false
	checar(h.convite.room_s == 123.5 and h.convite.next_at == 400.0 and h.convite.open == "spar" and h.convite.last == "spar" and h.convite.warm, "convite volta igual do save")
	# save sujo: tudo vira padrão
	var sujo: Dictionary = h.para_save()
	sujo.career["training_invite"] = {"room_s": "abc", "next_at": -5, "open": "zzz", "open_since": "x", "last": 7, "warm": "sim"}
	h.aplicar_save(sujo)
	checar(h.convite.room_s == 0.0 and h.convite.next_at == 300.0 and h.convite.open == "" and h.convite.last == "" and not h.convite.warm, "save sujo: padrões")
	sujo.career["training_invite"] = [1, 2]
	h.aplicar_save(sujo)
	checar(h.convite.next_at == 300.0, "campo do tipo errado: padrões")
	# warm sem arte não vale; open sem elegibilidade vira ""
	var estado2: Dictionary = h.para_save()
	estado2.career["art"] = ""
	estado2.career["training_invite"] = {"room_s": 10, "next_at": 50, "open": "spar", "open_since": 5, "last": "", "warm": true}
	h.aplicar_save(estado2)
	checar(not h.convite.warm and h.convite.open == "", "AQUECIDO sem arte e convite do Choque sem arte são descartados")
	# save antigo (sem o campo)
	var antigo: Dictionary = h.para_save()
	antigo.career.erase("training_invite")
	h.aplicar_save(antigo)
	checar(h.convite.next_at == 300.0 and h.convite.room_s == 0.0 and h.convite.open == "", "save antigo abre com os padrões")
	# fechar no meio do minigame: ao reabrir, sala, sem prêmio, convite consumido
	var pasta2 := pasta_limpa("f7a2_save_meio")
	var m: Node = GameStateScript.new()
	m.inicializar(pasta2, "res://data/config.json")
	m.autosave_ativo = false
	m.risco_hud_ativo = false
	m.lutas.calendario["seconds_per_day"] = 0.0
	m.pular_abertura()
	m.permanente["arts_unlocked"] = ["boxing"]
	m.escolher_arte("boxing")
	_abrir_convite(m, "spar")
	m.convite_ir()
	var treino_antes: float = m.treino
	var fama_antes: int = m.fama
	_liberar(m)
	var n: Node = GameStateScript.new()
	n.inicializar(pasta2, "res://data/config.json")
	n.autosave_ativo = false
	checar(n.treino_fora == "" and n.convite.open == "" and n.sala_ativa(), "reabriu no meio do minigame: sala, sem convite")
	checar(n.treino == treino_antes and n.fama == fama_antes and not n.convite.warm, "sem prêmio e nada em dobro")
	_liberar(n)
	h.free()


# ---------------- Gato Preto ----------------
func _teste_gato_preto() -> void:
	var g := _novo("f7a2_gato", "boxing", false, true)
	checar(g.recorte_gato_preto().is_empty(), "campanha 1: sem recorte")
	g.permanente["career_number"] = 2
	g.escola["first_fighter_campaign"] = 1
	var rc: Dictionary = g.recorte_gato_preto()
	checar(rc.get("spot", []) == [304.0, 100.0] and rc.get("object_text", "") == "black_cat_clipping", "campanha 2 na garagem: recorte em 304,100 (%s)" % str(rc))
	g.local_id = "gym"
	checar(g.recorte_gato_preto().is_empty(), "academia sem a cena: sem recorte")
	g._gravar_marco("cena_primeira_academia", {}, false)
	checar_igual(g.recorte_gato_preto().get("spot", []), [340.0, 60.0], "academia depois da cena: recorte em 340,60")
	g.local_id = "garage"
	checar(g.texto_ui("black_cat_clipping") != "" and g.texto_ui("black_cat_rumor") != "" and g.texto_ui("warm_preview_line") != "", "chaves de texto do Roteirista existem")
	# sem ponto no manifest o recorte não aparece, mas as condições valem
	_abrir_convite(g, "flyers")
	var info: Dictionary = g.convite_ir()
	checar(str(info.rumor_text) != "", "1ª Panfletagem da campanha 2 com garage_saved: boato do Osmar")
	checar(g.marco("black_cat_rumor_heard"), "grava o marco do boato")
	g.treino_concluir()
	g.treino_voltar()
	_abrir_convite(g, "flyers")
	var info2: Dictionary = g.convite_ir()
	checar_igual(str(info2.rumor_text), "", "o boato sai uma vez só")
	g.treino_concluir()
	g.treino_voltar()
	_liberar(g)
	var h := _novo("f7a2_gato1", "boxing", false, true)
	_abrir_convite(h, "flyers")
	checar_igual(str(h.convite_ir().rumor_text), "", "campanha 1: sem boato")
	h.treino_concluir()
	h.treino_voltar()
	_liberar(h)
	# o Choque nunca conta o boato
	var k := _novo("f7a2_gato_spar", "boxing", false, true)
	k.permanente["career_number"] = 2
	_abrir_convite(k, "spar")
	checar_igual(str(k.convite_ir().rumor_text), "", "o boato só sai na Panfletagem")
	k.treino_concluir()
	k.treino_voltar()
	_liberar(k)


func _teste_arquivo_ausente() -> void:
	var r := MinigamesData.carregar("res://data/nao_existe.json")
	checar(r.vazio, "arquivo ausente = sem convites")
	var g := _novo("f7a2_vazio", "boxing", false, true)
	g.minigames = r
	_andar(g, 700.0)
	checar_igual(g.convite.open, "", "sem arquivo nenhum convite aparece")
	_liberar(g)
