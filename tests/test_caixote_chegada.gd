extends "res://tests/test_base.gd"
## Bug do dono: numa campanha nova (2a, 3a...) o John aparece sentado num caixote que sumiu.
## Causa: na cena chegada_discipulo (esconde só player e crew) a sala desenhava o mentor mas escondia o caixote.


func rodar_testes() -> void:
	var gs: Node = root.get_node("GameState")
	gs.inicializar(pasta_limpa("caixote_chegada"), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	var sala: Control = load("res://ui/sala.gd").new()
	root.add_child(sala)
	await process_frame
	for n in [2, 3, 4]:
		gs.aposentar()
		checar(gs.receber_discipulo(), "sucessao %d: receber discipulo" % (n - 1))
		gs.sucessao_tela_aberta()
		checar(gs.confirmar_discipulo(), "sucessao %d: confirmar" % (n - 1))
		gs.sucessao_terminou()
		# A sala do jogo (sem cena): quem senta tem caixote.
		sala._atualizar_mentor()
		var sentado: bool = not gs.papel_da_sala("seat").is_empty()
		checar(sentado, "carreira %d: alguem sentado no caixote" % n)
		checar(sala._caixote.visible, "carreira %d: caixote visivel na sala normal" % n)
		# A cena curta de chegada: esconde player e crew, o mentor continua desenhado.
		sala.cena_iniciar(["player", "crew"])
		checar(sala._mentor.visible == sentado, "carreira %d: chegada: mentor desenhado" % n)
		checar(sala._caixote.visible, "carreira %d: chegada: o caixote aparece junto do mentor" % n)
		sala.cena_palco_liberado()
		checar(sala._caixote.visible, "carreira %d: depois da cena o caixote continua" % n)
	sala.free()
