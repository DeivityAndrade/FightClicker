extends "res://tests/test_base.gd"
## Soak: um jogador aleatório joga MUITO pela API pública (cliques, tempo, compras, foco, evento dourado, lutas, aposentadoria,
## novas carreiras, escolha de arte, cena da academia) e a cada passo conferem-se regras que nunca podem quebrar: números finitos,
## sem valores negativos nos saldos, e o save sempre volta igual (para_save -> aplicar_save -> para_save).

const EPISODIOS := 4
const PASSOS := 2500

var gs: Node
var _rng := RandomNumberGenerator.new()
var _cobertura := {}
var _parado := {}  # estado em que o robô travou -> quantas vezes


func rodar_testes() -> void:
	gs = root.get_node("GameState")
	for ep in EPISODIOS:
		_episodio(ep)
	print("cobertura do soak: ", _cobertura)
	checar(int(_cobertura.get("carreira_max", 0)) >= 2 and int(_cobertura.get("escada_max", 0)) >= 2, "o robô realmente avançou no jogo (carreiras e escada)")
	checar(_parado.is_empty(), "o robô nunca ficou preso num estado sem saída: %s" % str(_parado))


func _episodio(ep: int) -> void:
	_rng.seed = 7000 + ep
	gs.inicializar(pasta_limpa("soak_%d" % ep), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.rng.seed = 100 + ep
	var inval := 0
	var sem_progresso := 0
	var ultimo := ""
	var lutas := 0
	var carreiras := 0
	for i in PASSOS:
		_passo()
		_cobertura["escada_max"] = maxi(int(_cobertura.get("escada_max", 0)), gs.indice_escada)
		_cobertura["dia_max"] = maxi(int(_cobertura.get("dia_max", 0)), gs.dia_campanha())
		var p := _problema()
		if p != "":
			inval += 1
			if inval <= 3:
				checar(false, "episódio %d passo %d: %s" % [ep, i, p])
		var estado := "%s|%s|%s|%s|%s" % [str(gs.fim.is_empty()), gs.sucessao, gs.cena_sala, str(gs.luta.is_empty()), str(gs.modal_aberto)]
		sem_progresso = sem_progresso + 1 if estado == ultimo and not gs.fim.is_empty() else 0
		ultimo = estado
		if i % 400 == 399:
			var ida: Dictionary = gs.para_save()
			var json_ida := JSON.stringify(ida)
			gs.aplicar_save(JSON.parse_string(json_ida))
			var volta := JSON.stringify(gs.para_save())
			if volta != json_ida:  # a ordem das chaves pode mudar (inofensivo): só conta se o CONTEÚDO mudou
				var difs: Array = []
				_diferencas(JSON.parse_string(json_ida), JSON.parse_string(volta), "save", difs)
				if not difs.is_empty():
					checar(false, "episódio %d passo %d: o save não voltou igual: %s" % [ep, i, str(difs.slice(0, 6))])
					inval += 1
	checar(inval == 0, "episódio %d sem violações em %d passos" % [ep, PASSOS])
	_cobertura["carreira_max"] = maxi(int(_cobertura.get("carreira_max", 0)), gs.numero_carreira())
	_cobertura["escada_max"] = maxi(int(_cobertura.get("escada_max", 0)), gs.indice_escada)
	_cobertura["dia_max"] = maxi(int(_cobertura.get("dia_max", 0)), gs.dia_campanha())


## Caminhos que mudaram entre dois dicionários (para o diagnóstico do round-trip do save).
func _diferencas(a: Variant, b: Variant, caminho: String, saida: Array) -> void:
	if a is Dictionary and b is Dictionary:
		for k in a:
			if not b.has(k):
				saida.append("%s.%s sumiu (era %s)" % [caminho, str(k), str(a[k]).left(40)])
			else:
				_diferencas(a[k], b[k], caminho + "." + str(k), saida)
		for k in b:
			if not a.has(k):
				saida.append("%s.%s apareceu (%s)" % [caminho, str(k), str(b[k]).left(40)])
	elif a is Array and b is Array and (a as Array).size() == (b as Array).size():
		for i in (a as Array).size():
			_diferencas(a[i], b[i], "%s[%d]" % [caminho, i], saida)
	elif str(a) != str(b):
		saida.append("%s: %s -> %s" % [caminho, str(a).left(40), str(b).left(40)])


func _passo() -> void:
	# Destrava estados que só a interface destravaria.
	if gs.cena_sala != "":
		gs.cena_sala_terminou()
		return
	if gs.escolha_arte_pendente():
		gs.escolher_arte(["boxing", "bjj"][_rng.randi() % 2])
		return
	if not gs.fim.is_empty():
		if not gs.nova_carreira():
			_parado["fim_sem_nova_carreira"] = int(_parado.get("fim_sem_nova_carreira", 0)) + 1
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
		_comprar_algo()
	elif r < 0.78:
		gs.pegar_evento_dourado()
	elif r < 0.90:
		if gs.pode_lutar():
			if _rng.randf() < 0.8:  # fortalece o lutador para o robô ganhar e avançar na escada (academia, cinturão, artes...)
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


func _comprar_algo() -> void:
	var a := _rng.randi() % 7
	match a:
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
			for ap in gs.dados.aparelhos:
				gs.comprar_no("body_jab")


## Devolve "" se estiver tudo certo, senão a primeira regra quebrada.
func _problema() -> String:
	for campo in ["treino", "dinheiro", "legado", "fama"]:
		var v: Variant = gs.get(campo)
		if v is float or v is int:
			if is_nan(float(v)) or is_inf(float(v)):
				return "%s não é finito (%s)" % [campo, str(v)]
			if float(v) < -1.0e-6:
				return "%s negativo (%s)" % [campo, str(v)]
	for k in gs.atributos:
		var v := float(gs.atributos[k])
		if is_nan(v) or is_inf(v) or v < 0.0:
			return "atributo %s inválido (%s)" % [str(k), str(v)]
	return _achar_nao_finito(gs.para_save(), "save")


func _achar_nao_finito(v: Variant, caminho: String) -> String:
	if v is float:
		if is_nan(v) or is_inf(v):
			return "%s não é finito" % caminho
	elif v is Dictionary:
		for k in v:
			var r := _achar_nao_finito(v[k], caminho + "." + str(k))
			if r != "":
				return r
	elif v is Array:
		for i in (v as Array).size():
			var r := _achar_nao_finito(v[i], "%s[%d]" % [caminho, i])
			if r != "":
				return r
	return ""
