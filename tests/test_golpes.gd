extends "res://tests/test_base.gd"
## Testa o catálogo de golpes (data/moves.json) e a escolha visual de golpe nos eventos da luta:
## dados reais, arquivos ruins, determinismo, respeito ao tipo de evento e, principalmente, que escolher golpe
## NUNCA muda o resultado da luta (só os campos `move*` entram nos eventos; os antigos ficam iguais).

const GameStateScript := preload("res://scripts/game_state.gd")


func rodar_testes() -> void:
	_teste_dados_reais()
	_teste_arquivos_ruins()
	_teste_escolha()
	_teste_eventos_da_luta()


func _teste_dados_reais() -> void:
	var m := MovesData.carregar()
	checar(m.golpes.size() >= 5, "catálogo tem os golpes do boxe")
	for id in ["jab", "heavy", "hook", "uppercut", "body_shot"]:
		checar(m.golpes.has(id), "golpe %s existe" % id)
	var base := m.disponiveis("boxing")
	checar(base.has("jab") and base.has("uppercut") and base.has("body_shot"), "boxe: golpes base liberados")
	checar_igual(m.disponiveis("estilo_que_nao_existe").size(), 0, "estilo desconhecido não tem golpes")
	for a in ["jab", "heavy", "hook", "uppercut", "body_shot"]:
		checar(a in m.anims_de_ataque(), "%s conta como animação de ataque" % a)


func _teste_arquivos_ruins() -> void:
	var m0 := MovesData.carregar("res://data/nao_existe.json")
	checar_igual(m0.golpes.size(), 0, "arquivo ausente: sem golpes, sem travar")
	DirAccess.make_dir_recursive_absolute(RAIZ_TESTES + "golpes/")
	var caminho := RAIZ_TESTES + "golpes/ruim.json"
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"styles": {"x": {"name": "X", "moves": ["bom", "sem_anim", "kinds_ruins", "bom", "fantasma"]}, "y": 5},
		"moves": {
			"bom": {"style": "x", "anim": "soco", "kinds": ["jab", "esquiva"]},
			"sem_anim": {"style": "x", "kinds": ["jab"]},
			"kinds_ruins": {"style": "x", "anim": "chute", "kinds": ["nada"]},
			"texto": "isto não é um golpe",
		}}))
	f.close()
	var m := MovesData.carregar(caminho)
	checar_igual(m.golpes.keys(), ["bom"], "só o golpe válido sobra")
	checar_igual(m.golpes.bom.kinds, ["jab"], "kind inválido é descartado")
	checar_igual(m.estilos.x.moves, ["bom"], "estilo lista só golpes existentes, sem repetir")
	checar(not m.estilos.has("y"), "estilo com formato inválido é ignorado")


func _teste_escolha() -> void:
	var m := MovesData.carregar()
	var ids := m.disponiveis("boxing")
	var igual := true
	var respeita := true
	var variou := {}
	for i in 200:
		var a := m.escolher(ids, "jab", 12345, i)
		if a != m.escolher(ids, "jab", 12345, i):
			igual = false
		if a == "" or not ("jab" in m.golpes[a].kinds):
			respeita = false
		variou[a] = true
		var c := m.escolher(ids, "crit", 99, i)
		if c == "" or not ("crit" in m.golpes[c].kinds):
			respeita = false
	checar(igual, "mesma semente e evento: mesmo golpe")
	checar(respeita, "o golpe sempre cabe no tipo do evento (jab/crit)")
	checar(variou.size() >= 2, "há variedade entre os acertos normais")
	checar_igual(m.escolher(ids, "dodge", 1, 0), "", "esquiva não usa golpe")
	checar_igual(m.escolher([], "jab", 1, 0), "", "sem golpes disponíveis: vazio (a tela usa o antigo)")
	var sem_repetir := true
	var ant := ""
	for i in 100:
		var g := m.escolher(ids, "jab", 7, i, ant)
		if g == ant and ant != "":
			sem_repetir = false
		ant = g
	checar(sem_repetir, "não repete o mesmo golpe duas vezes seguidas")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.aparelhos_montados_ids = ["punching_bag", "jump_rope", "treadmill"]
	return gs


func _teste_eventos_da_luta() -> void:
	var gs := _novo("golpes_eventos")
	gs.atributos = {"strength": 3000.0, "agility": 3000.0, "endurance": 3000.0}
	var info: Dictionary = gs.lutar()
	var ev: Array = info.events
	checar(ev.size() > 0, "a luta tem eventos")
	var campos := true
	var coerente := true
	var temp_golpe := false
	for e in ev:
		for chave in ["move", "move_anim", "defender_move_anim"]:
			if not e.has(chave):
				campos = false
		if e.kind == "dodge" and (e.move != "" or e.move_anim != ""):
			coerente = false
		if e.kind != "dodge":
			if e.move == "" or not gs.golpes.golpes.has(e.move) or e.move_anim != gs.golpes.golpes[e.move].anim:
				coerente = false
			elif e.move != "jab" and e.move != "heavy":
				temp_golpe = true
		if e.defender_move_anim != "" and e.defender_anim != "hit":
			coerente = false  # reação especial só quando o golpe acerta (não em bloqueio/esquiva)
		if not (e.attack_anim in ["jab", "heavy"]):
			coerente = false  # o campo antigo continua valendo como fallback
	checar(campos, "eventos trazem move, move_anim e defender_move_anim")
	checar(coerente, "campos de golpe coerentes com o tipo do evento")
	checar(temp_golpe or ev.size() < 4, "aparecem golpes além de jab/heavy")
	# Determinismo e resultado intocado: recalcular a mesma luta dá os mesmos golpes e o mesmo resultado.
	var de_novo: Dictionary = gs.luta_atual()
	var mesmos: bool = de_novo.events.size() == ev.size()
	for i in mini(ev.size(), de_novo.events.size()):
		if de_novo.events[i].move != ev[i].move:
			mesmos = false
	checar(mesmos, "recalcular a luta repete os mesmos golpes")
	checar_igual(de_novo.result, info.result, "resultado da luta igual ao recalculado")
	gs.aguardar_motivo()  # o motivo da derrota/vitória roda em segundo plano: espera antes de liberar
	gs.free()
