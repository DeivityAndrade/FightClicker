extends SceneTree
## "Foto" determinística do jogo, para provar que uma refatoração não mudou comportamento.
## Uso: godot --headless --path E:\Fightclicker --script res://tools/refatoracao/foto.gd -- --out=C:\caminho\foto.txt
## Roda (1) a simulação de qa_f6a_sim, (2) um robô com sementes fixas (hash do save a cada 100 passos)
## e (3) uma partida roteirizada; grava tudo num texto. Duas execuções têm que dar o mesmo arquivo.
## Só usa pastas dentro de user://test/ (nunca o save real).

const GS := preload("res://scripts/game_state.gd")
const PASSOS := 3000
var _out: PackedStringArray = []
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	await process_frame
	_sim()
	_robo()
	_roteiro()
	var caminho := "user://test/foto.txt"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			caminho = a.substr(6)
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string("\n".join(_out) + "\n")
	f.close()
	quit(0)


func _novo(nome: String) -> Node:
	var gs: Node = GS.new()
	var pasta := "user://test/foto_%s/" % nome
	DirAccess.make_dir_recursive_absolute(pasta)
	for f in DirAccess.get_files_at(pasta):
		DirAccess.remove_absolute(pasta + f)
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.rng.seed = 1234
	gs._rng_evento.seed = 11
	gs._rng_fala.seed = 22
	gs._rng_sucessao.seed = 33
	return gs


func _fim(gs: Node) -> void:
	gs.aguardar_motivo()
	gs.aguardar_falta()
	gs.free()


# --- 1) simulação de tests/qa_f6a_sim.gd ---
func _sim() -> void:
	var gs := _novo("sim")
	_out.append("## SIM")
	var t := 0.0
	var lutas := 0
	while t < 1200.0:
		gs.tick(0.1)
		t += 0.1
		gs.clicar()
		if gs.no_dia_da_luta() and gs.luta.is_empty() and gs.fim.is_empty():
			gs.lutar()
			var r: Dictionary = gs.concluir_luta()
			lutas += 1
			_out.append("luta@%.0f win=%s" % [t, str(r.get("win"))])
			if not gs.fim.is_empty():
				_out.append("fim@%.0f" % t)
				gs.nova_carreira()
		if int(round(t * 10)) % 3000 == 0:
			_out.append("t=%.0f treino=%.3f dinheiro=%.3f dia=%s" % [t, gs.treino, gs.dinheiro, str(gs.fight_day)])
	_out.append("LUTAS %d hash=%d" % [lutas, JSON.stringify(gs.para_save()).hash()])
	_fim(gs)


# --- 2) robô (cópia do tests/test_soak_jogo.gd, com sementes fixas) ---
func _robo() -> void:
	_out.append("## ROBO")
	for ep in 2:
		var gs := _novo("robo%d" % ep)
		_rng.seed = 7000 + ep
		gs.rng.seed = 100 + ep
		for i in PASSOS:
			_passo(gs)
			if i % 100 == 99:
				var j := JSON.stringify(gs.para_save())
				_out.append("ep%d passo %d hash=%d treino=%s fim=%s suc=%s" % [ep, i + 1, j.hash(), str(gs.treino), str(not gs.fim.is_empty()), gs.sucessao])
		_fim(gs)


func _passo(gs: Node) -> void:
	if gs.cena_sala != "":
		gs.cena_sala_terminou()
		return
	if gs.escolha_arte_pendente():
		gs.escolher_arte(["boxing", "bjj"][_rng.randi() % 2])
		return
	if not gs.fim.is_empty():
		gs.nova_carreira()
		return
	if gs.sucessao != "none":
		gs.sucessao_tela_aberta()
		if gs.sucessao == "scene_2" or gs.sucessao == "arriving":
			gs.sucessao_terminou()
		return
	if not gs.luta.is_empty():
		gs.concluir_luta()
		return
	var r := _rng.randf()
	if r < 0.35:
		for k in _rng.randi_range(1, 30):
			gs.clicar()
	elif r < 0.60:
		gs.tick([0.1, 0.5, 1.0, 5.0, 30.0][_rng.randi() % 5])
	elif r < 0.70:
		match _rng.randi() % 7:
			0:
				for g in gs.dados.geradores:
					gs.comprar_gerador(str(g.id))
			1:
				for ap in gs.dados.aparelhos:
					gs.comprar_melhoria(str(ap.id))
			2:
				for ap in gs.dados.aparelhos:
					gs.comprar_aparelho(str(ap.id))
			3:
				gs.comprar_luva()
			4:
				gs.comprar_metronomo()
			5:
				gs.comprar_crew_click()
			6:
				gs.comprar_no("body_jab")
	elif r < 0.78:
		gs.pegar_evento_dourado()
	elif r < 0.90:
		if gs.pode_lutar():
			if _rng.randf() < 0.8:
				var f := 2000.0 * float(1 + gs.indice_escada) * float(1 + _rng.randi() % 40)
				gs.atributos = {"strength": f, "agility": f * 0.5, "endurance": f}
			gs.lutar()
	elif r < 0.93:
		var aps: Array = gs.dados.aparelhos
		if not aps.is_empty():
			gs.definir_foco(str(aps[_rng.randi() % aps.size()].id))
	elif r < 0.935:
		gs.aposentar()
	else:
		gs.tick(60.0)


# --- 3) partida roteirizada + leituras ---
const LEITURAS := ["mural", "mural_na_sala", "hall_lista", "honra", "honra_total", "arvore_mapa", "arvore_ramos", "arvore_nos",
	"nos_comprados", "bonus_ativos", "resumo_legado", "cartao_inicio", "caixas", "luvas_abertas", "aparelhos_montados",
	"aparelhos_da_carreira", "textos_fim", "nome_lutador", "texto_hud_lutador", "titulo_resumo", "visual_lutador",
	"mentores_na_sala", "escola_lista", "retratos_com_selo", "teto_retratos", "mult_escola", "texto_hud_local",
	"texto_hud_arte", "texto_traco_luta", "texto_divisao", "texto_reserva", "info_proxima",
	"risco_proxima", "previa", "legado_em_jogo", "legado_se_perder", "previa_aposentar", "estado_escada", "dia_campanha",
	"dias_para_luta", "producao_total", "por_clique", "por_auto_soco", "metronomo_atual", "proximo_metronomo", "local_atual",
	"loja_estado", "artes_liberadas", "estilo_arte", "estado_mudanca", "reserva_mudanca", "ponto_do_coach", "foto_antiga",
	"papel_da_sala", "coach_presente", "assento_visivel", "recorde_da_escola", "voz_do_mentor", "mentor_do_caixote",
	"simbolo_na_entrada", "rascunho", "discipulo_atual", "sucessao_estado", "calendario_ligado", "campanha_completa",
	"proxima_luva", "proximo_adversario", "tem_luta_pendente", "tem_fim_pendente", "pode_lutar", "pode_aposentar",
	"lutador_atual", "marco", "abertura_estado", "tem_balao", "saida_devida", "saida_tocando", "mentor_sentado",
	"segundo_mentor", "tempo_morto", "dica_aposentar", "tatica_efetiva", "numero_carreira", "luta_atual", "pode_comprar_luva"]


func _ler(gs: Node, etapa: String) -> void:
	_out.append("# leituras @ " + etapa)
	var sem_arg := {}
	for m in gs.get_method_list():
		if (m.args as Array).size() - (m.default_args as Array).size() == 0:
			sem_arg[m.name] = true
	for n in LEITURAS:
		if not sem_arg.has(n):
			continue  # precisa de argumento: fora da foto
		var v: Variant = gs.call(n)
		_out.append("%s = %s" % [n, JSON.stringify(v) if (v is Dictionary or v is Array) else str(v)])
	_out.append("estado = " + JSON.stringify(gs.para_save()))


func _roteiro() -> void:
	_out.append("## ROTEIRO")
	var gs := _novo("roteiro")
	gs.pular_abertura()
	gs.dados.crit_chance = 0.0
	for i in 300:
		gs.clicar()
	gs.tick(5.0)
	for g in gs.dados.geradores:
		gs.comprar_gerador(str(g.id))
	for ap in gs.dados.aparelhos:
		gs.comprar_melhoria(str(ap.id))
		gs.comprar_aparelho(str(ap.id))
	gs.comprar_luva()
	gs.comprar_metronomo()
	gs.comprar_crew_click()
	for k in 60:
		gs.tick(0.5)
		gs.clicar()
	_ler(gs, "garagem")
	for k in 3:
		gs.atributos = {"strength": 1.0e6, "agility": 1.0e6, "endurance": 1.0e6}
		gs.dinheiro += 5000.0
		gs.definir_tatica("aggressive" if k % 2 == 0 else "")
		gs.lutar()
		_out.append("luta %d = %s" % [k, JSON.stringify(gs.concluir_luta())])
	_ler(gs, "apos 3 lutas")
	_out.append("aposentar = " + JSON.stringify(gs.aposentar()))
	_ler(gs, "fim de carreira")
	gs.comprar_hall("hall_box")
	_out.append("receber = " + str(gs.receber_discipulo()))
	gs.sucessao_tela_aberta()
	gs.sortear_rascunho()
	_out.append("confirmar = " + str(gs.confirmar_discipulo()))
	gs.sucessao_terminou()
	for k in 30:
		gs.tick(0.5)
	_ler(gs, "discipulo")
	gs.escola["honor"] = 200
	gs.escola["honor_total"] = 200
	gs.indice_escada = 2
	gs.aposentar()
	for n in ["hall_box", "hall_glove", "hall_fund", "hall_wall"]:
		_out.append("hall %s = %s" % [n, str(gs.comprar_hall(n))])
	_ler(gs, "hall")
	_out.append("nova = " + str(gs.nova_carreira()))
	gs.tick(3.0)
	_ler(gs, "nova carreira")
	gs.salvar()
	var txt := FileAccess.get_file_as_string("user://test/foto_roteiro/save.json")
	var rx := RegEx.create_from_string("\"saved_at_unix\":\\s*[0-9]+")
	_out.append("SAVE " + rx.sub(txt, "\"saved_at_unix\": 0", true))
	_fim(gs)
