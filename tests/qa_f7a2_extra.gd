extends "res://tests/test_base.gd"
## QA 7a2: cenarios que os testes do Programador nao cobrem. Pastas em user://test/, nunca o save real.

const GS := preload("res://scripts/game_state.gd")


func _novo(nome: String, arte: String = "", calendario: bool = false, garagem: bool = false) -> Node:
	var gs: Node = GS.new()
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
	if garagem:
		gs._gravar_marco("garage_saved", {}, false)
	return gs


func _lib(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _andar(g: Node, s: float, limpa_balao: bool = true) -> void:
	for i in int(round(s / 0.1)):
		g.tick(0.1)
		if limpa_balao:
			g._balao = {}
			g._gesto = {}


func rodar_testes() -> void:
	_estados_que_bloqueiam()
	_dia_da_luta_nao_abre()
	_academia_sem_osmar()
	_tela_de_premio_parada()
	_nada_nasce_no_minigame()
	_sair_em_todo_instante()
	_entradas_abusivas()
	_ir_duas_vezes()
	_save_sujo()
	_aquecido_honesto()
	_premio_extremo()
	_choque_niveis_e_ritmo()


func _estados_que_bloqueiam() -> void:
	var g := _novo("qa_bloq", "boxing", false, true)
	_andar(g, 310.0)
	checar_igual(g.convite_visivel(), "spar", "base: convite aberto aos 310 s")
	var rs: float = g.convite.room_s
	g.cena_sala = "primeira_academia"
	_andar(g, 4.0)
	checar_igual(g.convite.room_s, rs, "cena_sala: relogio do convite parado")
	checar_igual(g.convite_visivel(), "", "cena_sala: balao escondido")
	g.cena_sala = ""
	g.fim = {"x": 1}
	_andar(g, 4.0)
	checar_igual(g.convite_visivel(), "", "fim pendente: sem balao")
	checar_igual(g.convite.room_s, rs, "fim pendente: relogio parado")
	g.fim = {}
	g.sucessao = "choose"
	_andar(g, 4.0)
	checar_igual(g.convite_visivel(), "", "sucessao: sem balao")
	checar_igual(g.convite.room_s, rs, "sucessao: relogio parado")
	g.sucessao = "none"
	g._saida_tocando = true
	checar_igual(g.convite_visivel(), "", "saida do John: sem balao")
	g._saida_tocando = false
	g._toques = {"momento": "x"}
	checar_igual(g.convite_visivel(), "", "toque do Osmar em curso: sem balao")
	g._toques = {}
	g._gesto = {"momento": "glove"}
	checar_igual(g.convite_visivel(), "", "gesto de calcar: sem balao")
	g._gesto = {}
	checar_igual(g.convite_visivel(), "spar", "tudo livre: o mesmo balao volta")
	_lib(g)
	# nova campanha zera o aberto
	var h := _novo("qa_bloq2", "boxing", false, true)
	_andar(h, 310.0)
	h.convite["warm"] = true
	h._zerar_carreira()
	checar(h.convite.open == "" and not h.convite.warm and h.convite.room_s == 0.0, "_zerar_carreira zera convite e AQUECIDO")
	_lib(h)


func _dia_da_luta_nao_abre() -> void:
	var g := _novo("qa_dia", "boxing", true, true)
	g.convite["next_at"] = 10.0
	g.convite["room_s"] = 9.0
	g.segundos_campanha = float(g.fight_day - 1) * 30.0 + 0.01
	g.tick(0.1)
	g._balao = {}
	checar(g.no_dia_da_luta(), "no dia da luta")
	_andar(g, 5.0)
	checar_igual(g.convite.open, "", "no dia da luta o convite NAO abre mesmo vencido o relogio (room_s=%.2f)" % g.convite.room_s)
	_lib(g)


func _academia_sem_osmar() -> void:
	var g := _novo("qa_gym", "boxing", false, true)
	g.local_id = "gym"
	g.tick(0.1)
	var r0: float = g.convite.room_s
	_andar(g, 400.0)
	var presente: bool = g.coach_presente()
	if not presente:
		checar_igual(g.convite.room_s, r0, "academia sem a cena: Osmar ausente, relogio do convite parado")
		checar_igual(g.convite.open, "", "academia sem a cena: nenhum convite")
	else:
		print("INFO  coach presente na academia neste estado")
	_lib(g)


func _tela_de_premio_parada() -> void:
	var g := _novo("qa_park", "boxing", true, true)
	g.geradores[str(g.dados.geradores[0].id)] = 30
	g.convite["open"] = "spar"
	g.convite["open_since"] = g.convite.room_s
	g.tick(0.01)
	g._balao = {}
	g.convite_ir()
	var j = g.treino_jogo()
	j.sair()
	var seg: float = g.segundos_campanha
	var t0: float = g.treino
	var prod: float = g.producao_total()
	g.treino_concluir()
	var t1: float = g.treino
	_andar(g, 100.0)
	var ganho: float = (g.treino - t1) / maxf(prod, 1.0e-9)
	print("INFO  tela de premio parada 100 s: equipe produziu %.1f s de producao (prod=%.2f) com treino_fora='%s'" % [ganho, prod, g.treino_fora])
	checar(ganho <= 5.0, "tela de premio parada nao deve render producao gratis (rendeu %.1f s)" % ganho)
	checar_igual(g.segundos_campanha, seg, "relogio da campanha continua parado na tela de premio")
	_lib(g)


func _nada_nasce_no_minigame() -> void:
	var g := _novo("qa_nasce", "boxing", true, true)
	g.convite["open"] = "flyers"
	g.convite["open_since"] = g.convite.room_s
	g.tick(0.01)
	g._balao = {}
	var oc0: float = g._ocioso
	g.convite_ir()
	var visto := false
	for i in 400:
		g.tick(0.1)
		if not g._balao.is_empty() or not g._gesto.is_empty() or g.cena_sala != "":
			visto = true
	checar(not visto, "durante o minigame nenhuma fala/gesto/cena nasce")
	print("INFO  _ocioso antes %.1f depois %.1f" % [oc0, g._ocioso])
	g.treino_concluir()
	g.treino_voltar()
	g.tick(0.1)
	checar(g._balao.is_empty() and g._gesto.is_empty(), "ao voltar da sala nao dispara fala/gesto ocioso acumulado (balao=%s gesto=%s)" % [str(g._balao), str(g._gesto)])
	_lib(g)


func _sair_em_todo_instante() -> void:
	for arte in ["boxing", "bjj"]:
		for t in [0.0, 1.0, 2.0, 2.02, 10.0, 29.98, 30.0, 31.0]:
			var g := _novo("qa_sair", arte, false, true)
			g.convite["open"] = "spar"
			g.convite["open_since"] = g.convite.room_s
			g.tick(0.01)
			g._balao = {}
			g.convite_ir()
			if t > 0.0:
				g.tick(t)
			var p: Dictionary = g.treino_concluir()
			checar(not p.is_empty() and p.treino > 0.0 and p.nota >= 0.25 and p.nota <= 1.0, "%s SAIR em %.2f s: premio >0 (treino %.2f nota %.2f)" % [arte, t, p.get("treino", -1.0), p.get("nota", -1.0)])
			g.treino_voltar()
			checar(g.sala_ativa() and g.treino_fora == "", "%s SAIR em %.2f: sala devolvida" % [arte, t])
			_lib(g)
	for t in [0.0, 1.0, 2.5, 20.0, 31.0]:
		var h := _novo("qa_sair2", "", false, true)
		h.convite["open"] = "flyers"
		h.convite["open_since"] = h.convite.room_s
		h.tick(0.01)
		h._balao = {}
		h.convite_ir()
		if t > 0.0:
			h.tick(t)
		var p: Dictionary = h.treino_concluir()
		checar(p.get("fama", 0) >= 1, "panfletagem SAIR em %.1f: FAMA >= 1" % t)
		h.treino_voltar()
		_lib(h)


func _entradas_abusivas() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var mg := MinigamesData.carregar()
	for arte in ["boxing", "bjj"]:
		var c := ChoqueLogica.new(mg.spar, arte, 5, r)
		c.apertar()
		c.soltar()
		c.soltar()
		c.passo(NAN)
		c.passo(-5.0)
		c.passo(INF)
		c.passo(0.0)
		c.apertar()
		c.apertar()
		c.passo(1.0e9)
		checar(c.fase == "fim", "%s: passo gigante termina sem travar" % arte)
		var pts := c.pontos
		c.apertar()
		c.passo(5.0)
		c.sair()
		checar(c.pontos == pts and c.fase == "fim", "%s: entradas depois do fim nao mudam nada" % arte)
		var e := c.estado()
		checar(is_finite(e.barra) and e.folego >= 0.0 and e.folego <= 1.0 and absf(e.barra) <= 1.0, "%s: barra e folego finitos e na faixa" % arte)
		# spam apertar/soltar no mesmo quadro
		var d := ChoqueLogica.new(mg.spar, arte, 0, r)
		d.passo(2.1)
		for i in 5000:
			d.apertar()
			d.soltar()
		d.passo(0.02)
		checar(absf(d.estado().barra) <= 1.0 and d.pontos < 50, "%s: 5000 cliques no mesmo quadro nao quebram (barra %.2f pontos %d)" % [arte, d.estado().barra, d.pontos])
	var p := PanfletoLogica.new(mg.flyers, 5, r)
	p.passo(2.1)
	for i in 100:
		p.clicar(-1)
		p.clicar(999999)
		p.clicar(-77)
	p.passo(NAN)
	p.passo(1.0e9)
	checar(p.fase == "fim" and p.liquidos() >= 0.0, "panfletagem: cliques invalidos e passo gigante ok")
	checar(p.clicar(0) == "ignorado", "panfletagem: clique depois do fim ignorado")
	checar(p.fama(0.0) >= 1 and p.fama(1.0e18) >= 1, "FAMA >=1 com prize_fame 0 e gigante (%d)" % p.fama(1.0e18))
	checar(p.fama(NAN) >= 0, "FAMA com NaN nao quebra")
	# nivel fora da faixa
	var q := PanfletoLogica.new(mg.flyers, 99, r)
	var cq := ChoqueLogica.new(mg.spar, "", -4, r)
	checar(q.nivel == 5 and cq.nivel == 0, "nivel fora da faixa e recortado")


func _ir_duas_vezes() -> void:
	var g := _novo("qa_ir2", "boxing", false, true)
	g.convite["open"] = "spar"
	g.convite["open_since"] = g.convite.room_s
	g.tick(0.01)
	g._balao = {}
	var a: Dictionary = g.convite_ir()
	var b: Dictionary = g.convite_ir()
	checar(not a.is_empty() and b.is_empty(), "segundo IR devolve vazio (sem convite)")
	var j = g.treino_jogo()
	var p1: Dictionary = g.treino_concluir()
	g.treino_voltar()
	g.treino_voltar()
	checar(g.treino_concluir().is_empty(), "concluir depois de voltar devolve vazio")
	checar(g.treino_jogo() == null, "sem jogo depois de voltar")
	var t: float = g.treino
	g.treino_concluir()
	checar_igual(g.treino, t, "concluir depois de voltar nao paga de novo")
	_lib(g)




func _save_sujo() -> void:
	var variantes := {
		"nulo": "null", "lista": "[1,2]", "string": "\"x\"", "negativos": "{\"room_s\":-5,\"next_at\":-1,\"open\":\"spar\",\"open_since\":-3,\"last\":\"flyers\",\"warm\":true}",
		"enorme": "{\"room_s\":1e400,\"next_at\":1e300,\"open\":\"flyers\",\"open_since\":1e300,\"last\":7,\"warm\":\"yes\"}",
		"tipos": "{\"room_s\":\"9\",\"next_at\":[],\"open\":{},\"open_since\":null,\"last\":true,\"warm\":1}",
		"open_since_futuro": "{\"room_s\":10,\"next_at\":5,\"open\":\"flyers\",\"open_since\":999,\"last\":\"flyers\",\"warm\":false}"}
	for nome in variantes:
		var g := _novo("qa_sujo_" + nome, "boxing", false, true)
		g.salvar()
		var pasta: String = "user://test/qa_sujo_" + nome + "/"
		var arquivos := DirAccess.get_files_at(pasta)
		var alvo := ""
		for f in arquivos:
			if f == "save.json":
				alvo = pasta + f
		if alvo == "":
			print("INFO  sem save.json em ", pasta, " -> ", arquivos)
			_lib(g)
			continue
		var txt := FileAccess.get_file_as_string(alvo)
		var js = JSON.parse_string(txt)
		js.state.career["training_invite"] = JSON.parse_string(variantes[nome])
		escrever(alvo, JSON.stringify(js))
		_lib(g)
		var h: Node = GS.new()
		h.inicializar(pasta, "res://data/config.json")
		h.autosave_ativo = false
		var c: Dictionary = h.convite
		var ok: bool = typeof(c.room_s) == TYPE_FLOAT and is_finite(c.room_s) and c.room_s >= 0.0 and is_finite(float(c.next_at)) and float(c.next_at) >= 0.0 \
			and c.open in ["", "spar", "flyers"] and c.last in ["", "spar", "flyers"] and typeof(c.warm) == TYPE_BOOL and float(c.open_since) <= float(c.room_s) + 1e-9
		checar(ok, "save sujo '%s' carrega com convite valido: %s" % [nome, str(c)])
		for i in 20:
			h.tick(0.1)
		var s: String = JSON.stringify(h.convite)
		checar(s.find("inf") < 0 and s.find("nan") < 0, "save sujo '%s': tick segue estavel" % nome)
		_lib(h)
	# save "antigo": sem o campo, e sem o marco
	var a := _novo("qa_antigo", "boxing", false, true)
	a.salvar()
	var alvo2 := "user://test/qa_antigo/save.json"
	if FileAccess.file_exists(alvo2):
		var js2 = JSON.parse_string(FileAccess.get_file_as_string(alvo2))
		js2.state.career.erase("training_invite")
		escrever(alvo2, JSON.stringify(js2))
		_lib(a)
		var b: Node = GS.new()
		b.inicializar("user://test/qa_antigo/", "res://data/config.json")
		checar(b.convite.next_at == 300.0 and b.convite.open == "", "save sem training_invite abre com padroes")
		_lib(b)
	else:
		_lib(a)


func _aquecido_honesto() -> void:
	var g := _novo("qa_hon", "boxing", false, true)
	var opp: Dictionary = g.proximo_adversario()
	var adv: Array = g._array_adversario(opp)
	# acha um estado "amarelo" (chance entre 25% e 75%) escalando os atributos
	var base := [1.0, 1.0, 1.0]
	var f := 0.05
	var tat: String = g.tatica
	var achou := false
	for k in 400:
		f *= 1.03
		base = [opp.strength * f, opp.agility * f, opp.endurance * f]
		var c: float = g.motor.chance(base, adv, tat)
		if k % 40 == 0:
			print("INFO  f=%.3f chance=%.3f" % [f, c])
		if c > 0.40 and c < 0.65:
			achou = true
			break
	checar(achou, "achei estado amarelo para a simulacao")
	g.atributos = {"strength": base[0], "agility": base[1], "endurance": base[2]}
	var prev_sem: Dictionary = g.previa()
	g.convite["warm"] = true
	var prev_com: Dictionary = g.previa()
	var ch_sem: float = prev_sem.risks[tat].chance
	var ch_com: float = prev_com.risks[tat].chance
	print("INFO  prev sem %.3f com %.3f ganho %s linha '%s'" % [ch_sem, ch_com, str(prev_com.get("warm_gain")), prev_com.get("warm_line", "")])
	var n := 1500
	var v_sem := 0
	var v_com := 0
	var m := 1.03
	var com := [base[0] * m, base[1] * m, base[2] * m]
	for s in n:
		if g.motor.lutar(base, adv, tat, 1000 + s, false).win:
			v_sem += 1
		if g.motor.lutar(com, adv, tat, 1000 + s, false).win:
			v_com += 1
	var r_sem := float(v_sem) / n
	var r_com := float(v_com) / n
	print("INFO  taxa real sem %.3f (prevista %.3f) com %.3f (prevista %.3f)" % [r_sem, ch_sem, r_com, ch_com])
	checar(absf(r_sem - ch_sem) < 0.05, "sem AQUECIDO a taxa real bate com a previa (%.3f x %.3f)" % [r_sem, ch_sem])
	checar(absf(r_com - ch_com) < 0.05, "com AQUECIDO a taxa real bate com a previa (%.3f x %.3f)" % [r_com, ch_com])
	var ganho_real := 100.0 * (r_com - r_sem)
	checar(absf(ganho_real - float(prev_com.warm_gain)) < 6.0, "'+N NA CHANCE' (%d) ~ ganho real medido (%.1f)" % [prev_com.warm_gain, ganho_real])
	# todas as taticas: warm_gains = diferenca de risks
	for t in g.lutas.taticas:
		var d := int(prev_com.risks[t.id].percent) - int(prev_sem.risks[t.id].percent)
		checar(d == int(prev_com.warm_gains[t.id]) or absf(d - int(prev_com.warm_gains[t.id])) <= 1, "warm_gains[%s]=%d ~ diferenca das previas %d" % [t.id, prev_com.warm_gains[t.id], d])
	# gasto na luta; nao soma
	g.atributos = {"strength": 5.0e6, "agility": 5.0e6, "endurance": 5.0e6}
	g.convite["warm"] = true
	g.lutar()
	checar(not g.aquecido(), "gasto na luta")
	checar(absf(g.luta.player.strength - 5.0e6 * 1.03) < 1.0, "luta registrou x1,03 uma vez (nao x1,0609)")
	g.concluir_luta()
	_lib(g)


func _premio_extremo() -> void:
	var g := _novo("qa_ext", "bjj", false, true)
	g.treino = 1.0e300
	g.geradores[str(g.dados.geradores[0].id)] = 1000000
	g.convite["open"] = "spar"
	g.convite["open_since"] = g.convite.room_s
	g.tick(0.01)
	g._balao = {}
	g.convite_ir()
	g.tick(35.0)
	var p: Dictionary = g.treino_concluir()
	checar(is_finite(g.treino) and is_finite(float(p.treino)), "premio com valores gigantes fica finito (treino=%s)" % str(g.treino))
	g.treino_voltar()
	# fama no teto
	g.fama = int(1.0e15) - 1
	g.convite["open"] = "flyers"
	g.convite["open_since"] = g.convite.room_s
	g.convite["next_at"] = 0.0
	g.tick(0.01)
	g._balao = {}
	g.convite_ir()
	g.tick(35.0)
	g.treino_concluir()
	checar(g.fama <= int(1.0e15), "FAMA limitada ao teto (%d)" % g.fama)
	_lib(g)
	# sem equipe e sem cliques
	var h := _novo("qa_zero", "boxing", false, true)
	h.convite["open"] = "spar"
	h.convite["open_since"] = h.convite.room_s
	h.tick(0.01)
	h._balao = {}
	h.convite_ir()
	var q: Dictionary = h.treino_concluir()
	checar(q.treino > 0.0 and is_finite(q.treino), "sem equipe, comeco de jogo: piso positivo (%f)" % q.treino)
	_lib(h)


func _choque_niveis_e_ritmo() -> void:
	var mg := MinigamesData.carregar()
	for arte in ["boxing", "bjj"]:
		var linhas := []
		for nv in 6:
			# ritmo "medio": 4 por segundo, le tudo (guarda/solta na rajada), contragolpe na pausa
			var tot := 0
			var venc := 0
			for s in 60:
				var r := RandomNumberGenerator.new()
				r.seed = 777 + s
				var c := ChoqueLogica.new(mg.spar, arte, nv, r)
				var t := 0.0
				c.passo(2.0)
				while c.fase != "fim" and t < 40.0:
					var e := c.estado()
					var acao := ""
					if arte == "boxing":
						if e.padrao == "burst":
							c.apertar()
						elif int(t * 4.3) != int((t - 0.02) * 4.3):
							c.soltar()
							c.apertar()
						elif e.padrao != "burst":
							c.soltar()
					else:
						if e.padrao == "burst":
							c.soltar()
						elif e.padrao == "pause" or e.padrao == "feint" and e.momento == "ativo":
							c.apertar()
						elif fmod(t, 1.5) < 1.0:
							c.apertar()
						else:
							c.soltar()
					c.passo(0.02)
					t += 0.02
				tot += c.pontos
				if c.venceu():
					venc += 1
			linhas.append("n%d: %.1f pts, venceu %d%%" % [nv, tot / 60.0, int(100.0 * venc / 60.0)])
		print("INFO  ", arte, " (jogador simples que le avisos) -> ", ", ".join(linhas))
	checar(true, "relatorio de niveis impresso")
