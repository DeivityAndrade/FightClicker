extends "res://tests/test_base.gd"
## QA 7a2: Panfletagem (enfeite, dificuldade, premio por nivel) e escolha de convite por carreira.

const GS := preload("res://scripts/game_state.gd")


func rodar_testes() -> void:
	var mg := MinigamesData.carregar()
	# 1) o enfeite fixo da tela e (id*7+tipo)%3 e nao depende do interesse: correlacao
	var com_sem := [0, 0]  # [interessados entre sem_interesse, total sem_interesse]
	var com_walk := [0, 0]
	for s in 200:
		var r := RandomNumberGenerator.new()
		r.seed = s
		var p := PanfletoLogica.new(mg.flyers, 3, r)
		for q in p._pessoas:
			var sem: bool = (int(q.id) * 7 + int(q.tipo)) % 3 != 0
			var a: Array = com_sem if sem else com_walk
			a[1] += 1
			if q.interessado:
				a[0] += 1
	var f1: float = float(com_sem[0]) / com_sem[1]
	var f2: float = float(com_walk[0]) / com_walk[1]
	print("INFO  interessados entre 'fone/celular': %.3f; entre 'andando normal': %.3f" % [f1, f2])
	checar(absf(f1 - f2) < 0.03, "enfeite fixo nao entrega quem esta interessado antes do sinal")
	# 2) pessoas() nao vaza 'interessado' nem 'falso'
	var r2 := RandomNumberGenerator.new()
	r2.seed = 9
	var p2 := PanfletoLogica.new(mg.flyers, 5, r2)
	p2.passo(12.0)
	var vaza := false
	for q in p2.pessoas():
		if q.has("interessado") or q.has("falso"):
			vaza = true
	checar(not vaza, "pessoas() nao expoe interesse/falso")
	# 3) jogador que le o sinal x afobado x parado, por nivel
	for nv in [0, 3, 5]:
		var tot := {"le": 0.0, "afobado": 0.0}
		var erros := {"le": 0.0, "afobado": 0.0}
		for s in 100:
			var r := RandomNumberGenerator.new()
			r.seed = 500 + s
			var a := PanfletoLogica.new(mg.flyers, nv, r)
			r = RandomNumberGenerator.new()
			r.seed = 500 + s
			var b := PanfletoLogica.new(mg.flyers, nv, r)
			a.passo(2.0)
			b.passo(2.0)
			var t := 0.0
			while a.fase != "fim":
				for q in a.pessoas():
					if q.sinal == "interesse" and not q.resolvida:
						a.clicar(q.id)
				for q in b.pessoas():
					if not q.resolvida:
						b.clicar(q.id)
				a.passo(0.05)
				b.passo(0.05)
			tot.le += a.liquidos()
			tot.afobado += b.liquidos()
			erros.le += a.erros
			erros.afobado += b.erros
		print("INFO  nivel %d: le sinal %.1f liquidos (%.1f erros) | clica em todos %.1f (%.1f erros)" % [nv, tot.le / 100, erros.le / 100, tot.afobado / 100, erros.afobado / 100])
		checar(tot.le > tot.afobado, "nivel %d: ler o sinal rende mais que clicar em todos" % nv)
	# 4) FAMA por proximo adversario, jogador perfeito e piso
	var g: Node = GS.new()
	g.inicializar(pasta_limpa("qa_pf"), "res://data/config.json")
	g.autosave_ativo = false
	g.lutas.calendario["seconds_per_day"] = 0.0
	g.pular_abertura()
	g._gravar_marco("garage_saved", {}, false)
	var pisos := [1, 2, 4, 6, 8, 13]
	var tetos := [5, 8, 15, 25, 30, 50]
	for i in 6:
		g.indice_escada = i
		g.convite["open"] = "flyers"
		g.convite["open_since"] = g.convite.room_s
		g.tick(0.01)
		g._balao = {}
		g.convite_ir()
		var j = g.treino_jogo()
		j.passo(2.0)
		j.aceitos = 14
		j.fase = "fim"
		var p: Dictionary = g.treino_concluir()
		g.treino_voltar()
		checar_igual(p.fama, tetos[i], "adversario %d: FAMA cheia" % i)
		g.indice_escada = i
		g.convite["open"] = "flyers"
		g.convite["open_since"] = g.convite.room_s
		g.tick(0.01)
		g._balao = {}
		g.convite_ir()
		var pf2: Dictionary = g.treino_concluir()
		g.treino_voltar()
		checar_igual(pf2.fama, pisos[i], "adversario %d: piso" % i)
	g.aguardar_motivo()
	g.free()
	# 5) 1a carreira sem arte nem garage_saved, depois com garage_saved
	var h: Node = GS.new()
	h.inicializar(pasta_limpa("qa_pf2"), "res://data/config.json")
	h.autosave_ativo = false
	h.lutas.calendario["seconds_per_day"] = 0.0
	h.pular_abertura()
	for i in 4000:
		h.tick(0.1)
		h._balao = {}
		h._gesto = {}
	checar_igual(h.convite.open, "", "1a carreira antes do cinturao: nenhum convite em 400 s")
	h._gravar_marco("garage_saved", {}, false)
	for i in 4000:
		h.tick(0.1)
		h._balao = {}
		h._gesto = {}
	var visto: String = h.convite.open
	checar_igual(visto, "flyers", "depois do garage_saved sem arte: so Panfletagem")
	h.aguardar_motivo()
	h.free()
