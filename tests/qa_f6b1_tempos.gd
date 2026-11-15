extends "res://tests/test_base.gd"
## QA 6b1: mede os tempos reais da linha do tempo do CenaPlayer (parte 1, parte 2, chegada curta), o pular e a reacao.
const GS := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GS.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	return gs


func _jog(gs: Node) -> Dictionary:
	var p := CenaPlayer.new(gs)
	p.ler_teclado = false
	p.automatico = false
	var f := {"tela": -1.0, "controle": -1.0, "fim": -1.0, "t": 0.0, "eventos": [], "say": []}
	p.tela_pedida.connect(func(_a: String, _b: Dictionary) -> void: f.tela = f.t)
	p.controle_devolvido.connect(func() -> void: f.controle = f.t)
	p.cena_terminada.connect(func(_x: bool) -> void: f.fim = f.t)
	p.evento.connect(func(ev: Dictionary) -> void:
		f.eventos.append([f.t, ev.tipo, ev.get("id", ev.get("anim", ""))])
		if ev.tipo == "say":
			f.say.append([f.t, ev.get("line", ""), ev.get("mode", "")]))
	return {"p": p, "f": f}


func _avanca(j: Dictionary, ate: String, maximo: float = 60.0) -> void:
	var t := 0.0
	while j.f[ate] < 0.0 and t < maximo:
		j.p.avancar(0.02)
		j.f.t += 0.02
		t += 0.02


func rodar_testes() -> void:
	# Cena grande
	var gs := _novo("qa6b1_tempos")
	gs.aposentar()
	gs.receber_discipulo()
	var j := _jog(gs)
	j.p.iniciar(gs.sucessao_cena())
	_avanca(j, "tela")
	var t_parte1: float = j.f.tela
	print("INFO parte 1 chega na tela em %.2f s" % t_parte1)
	checar(t_parte1 > 0.0 and t_parte1 <= 9.5, "parte 1 <= 9,5 s (%.2f)" % t_parte1)
	gs.confirmar_discipulo()
	var t0: float = j.f.t
	_avanca(j, "controle")
	var t_parte2: float = j.f.controle - t0
	print("INFO parte 2 devolve controle em %.2f s" % t_parte2)
	checar(j.f.controle > 0.0 and t_parte2 <= 6.5, "parte 2 <= 6,5 s (%.2f)" % t_parte2)
	checar(t_parte1 + t_parte2 <= 16.0, "presos totais <= 16 s (%.2f)" % (t_parte1 + t_parte2))
	print("INFO falas: ", j.f.say)
	var rest := 0.0
	for k in 600:
		j.p.avancar(0.02)
		rest += 0.02
	print("INFO cena termina %.2f s depois do controle? fim=%.2f controle=%.2f" % [rest, j.f.fim, j.f.controle])
	# quantas vezes tocam "door_roll"/"lamp_hum" etc
	var contagem := {}
	for e in j.f.eventos:
		if e[1] == "sound":
			contagem[e[2]] = int(contagem.get(e[2], 0)) + 1
	print("INFO sons: ", contagem)
	j.p.free()
	gs.aguardar_motivo()
	gs.free()

	# Chegada curta
	var g2 := _novo("qa6b1_tempos2")
	g2.aposentar()
	g2.receber_discipulo()
	g2.sucessao_tela_aberta()
	g2.confirmar_discipulo()
	g2.sucessao_terminou()
	g2.aposentar()
	checar(g2.receber_discipulo(), "2ª sucessão")
	checar_igual(g2.sucessao_cena(), "chegada_discipulo", "chegada curta")
	checar_igual(g2.sucessao_estado(), "creating", "abre direto na criação")
	var j2 := _jog(g2)
	j2.p.iniciar(g2.sucessao_cena())
	_avanca(j2, "tela")
	g2.confirmar_discipulo()
	var tt: float = j2.f.t
	j2.p.iniciar(g2.sucessao_cena(), "depois_criar")
	_avanca(j2, "controle")
	print("INFO chegada: controle em %.2f s" % (j2.f.controle - tt))
	checar(j2.f.controle - tt <= 2.5, "chegada curta <= 2,5 s (%.2f)" % (j2.f.controle - tt))
	var falas: int = j2.f.say.size()
	checar_igual(falas, 0, "chegada sem fala")
	j2.p.free()
	# 3a sucessão: de novo chegada, sem cena grande, sem novo marco
	g2.aguardar_motivo()
	g2.free()
