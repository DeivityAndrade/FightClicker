extends RefCounted
## Fase 6c1: chegada à academia, elenco da sala e saída do John.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs  # o GameState (autoload)


func _init(g) -> void:
	gs = g


func _ler_json_dados(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var v = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return v if v is Dictionary else {}


func _marco_da_chegada() -> String:
	return str(gs.escola_cfg.get("gym_arrival", {}).get("milestone", "cena_primeira_academia"))


func _marco_da_saida() -> String:
	return str(gs.escola_cfg.get("mentor_leave", {}).get("milestone", "cena_saida_primeiro_mentor"))


## Id da cena de chegada se o MUDAR atual é a 1ª chegada à academia (marco ausente); "" nos outros casos.
func _cena_da_chegada() -> String:
	var cfg: Dictionary = gs.escola_cfg.get("gym_arrival", {})
	if cfg.is_empty() or gs.local_id != str(cfg.get("location", "gym")) or gs.marco(_marco_da_chegada()):
		return ""
	return str(cfg.get("scene", "primeira_academia"))


## A cena da chegada terminou (return_control ou PULAR): devolve o relógio e abre a escolha da arte, se pendente.
func cena_sala_terminou() -> void:
	if gs.cena_sala == "":
		return
	gs.cena_sala = ""
	gs._cena_sala_t = 0.0
	gs._checar_sala()
	if gs.escolha_arte_pendente():
		gs.escolha_arte_pedida.emit(gs.escolha_arte_primeira())


## Quem a chegada à academia usa (formato §9 item 16): {fighter "first"|"disciple", box "first"|"last_passed"|"neighbor",
## box_look (look do último, {} nos outros)}. A cena resolve os atores pelo papel; isto é para a interface e os testes.
func elenco_primeira_academia() -> Dictionary:
	var m := papel_do_elenco("mentor:seat")
	var caixa := "neighbor"
	if not m.is_empty():
		caixa = "first" if str(m.id) == "first" else "last_passed"
	return {"fighter": gs.lutador_atual(), "box": caixa, "box_look": m.get("look", {}) if caixa == "last_passed" else {}}


# {id "first"|"last", character, look, name} de um dos papéis de cena; {} se ninguém ocupa o papel.
func papel_do_elenco(papel: String) -> Dictionary:
	if papel == "mentor:seat":
		for quem in gs.escola_cfg.get("gym_arrival", {}).get("box_carrier_order", ["first", "last_passed"]):
			if str(quem) == "first" and gs.lutador_atual() == "disciple" and "first" in gs.escola.get("mentors", []):
				return _papel_john()
			if str(quem) == "last_passed" and gs.marco(_marco_da_saida()):
				var u := _papel_ultimo()
				if not u.is_empty():
					return u
		return {}
	if papel == "mentor:last":
		return _papel_ultimo()
	return {}


func _papel_john() -> Dictionary:
	return {"id": "first", "character": "first_fighter", "look": {}, "name": str(gs.dialogos.cast.get("first", {}).get("name", "John Bullet"))}


# O último que passou o posto (a entrada do roster), com o look validado.
func _papel_ultimo() -> Dictionary:
	var e = gs.segundo_mentor_entrada()
	if e.is_empty():
		return {}
	var look = e.get("look", null)
	return {"id": "last", "character": "current_player", "name": str(e.get("name", "")),
		"look": gs.disciples.validar_look(look) if look is Dictionary else gs.disciples.look_padrao.duplicate()}


# {seat, stand} (nomes dos pontos) do local atual, ou {} se ali não há mentor desenhado (academia sem o marco da cena).
func _spots_do_local() -> Dictionary:
	var s = gs.disciples.mentores_cfg.get("spots_by_location", {}).get(gs.local_id, {})
	if not (s is Dictionary) or s.is_empty():
		return {}
	var req := str(s.get("requires_milestone", ""))
	if req != "" and not gs.marco(req):
		return {}
	return {"seat": str(s.get("seat", "")), "stand": str(s.get("stand", ""))}


func _cena_dados_pontos() -> CenaDados:
	if gs._pontos_cena == null:
		gs._pontos_cena = CenaDados.novo()
	return gs._pontos_cena


## Ponto ([x, y]) do papel `seat` ou `stand` no local atual; [] se não há (manifest com reserva em data/cena_player.json).
func ponto_do_local(papel: String) -> Array:
	var p := _spots_do_local()
	if p.is_empty():
		return []
	return _cena_dados_pontos().ponto(str(p.get(papel, "")))


## {seat_spot, stand_spot, coach_spot} do local atual: o que a cena usa para `seat_spot` etc. (formato §9 item 22).
func pontos_do_local() -> Dictionary:
	return _cena_dados_pontos().pontos_do_local(gs.local_id, gs.disciples.mentores_cfg.get("spots_by_location", {}), gs.escola_cfg.get("coach_presence", {}))


## Ponto onde o Osmar é desenhado no local atual ([] se não aparece ali).
func ponto_do_coach() -> Array:
	var c = gs.escola_cfg.get("coach_presence", {}).get(gs.local_id, null)
	if not (c is Dictionary):
		return []
	var req := str(c.get("requires_milestone", ""))
	if req != "" and not gs.marco(req):
		return []
	return _cena_dados_pontos().ponto_caminho(str(c.get("spot", "")))


## O Osmar está desenhado no local atual? Só fala quem está desenhado (design §3.2). Garagem: sempre; academia: depois do marco.
func coach_presente() -> bool:
	if gs.escola_cfg.is_empty():
		return gs.local_id == "garage"
	return not ponto_do_coach().is_empty()


## A foto antiga do local atual: {spot [x, y], object_text (chave de objects), tilted} ou {} se não aparece (design §2).
func foto_antiga() -> Dictionary:
	var c = gs.escola_cfg.get("old_photo", {}).get(gs.local_id, null)
	if not (c is Dictionary):
		return {}
	var req := str(c.get("requires_milestone", ""))
	if req != "" and not gs.marco(req):
		return {}
	var p := _cena_dados_pontos().ponto_caminho(str(c.get("spot", "")))
	if p.is_empty():
		return {}
	return {"spot": p, "object_text": str(c.get("object_text", "")), "tilted": bool(c.get("tilted", false))}


## O caixote de sentar está desenhado no local atual (com ou sem gente sentada)? Garagem: desde a 1ª sucessão. Academia: desde o marco.
func assento_visivel() -> bool:
	var c = gs.disciples.mentores_cfg.get("seat_prop", {}).get(gs.local_id, null)
	if not (c is Dictionary):
		return false
	var req := str(c.get("requires_milestone", ""))
	if req != "" and not gs.marco(req):
		return false
	var s = gs.disciples.mentores_cfg.get("spots_by_location", {}).get(gs.local_id, {})
	return s is Dictionary and not _cena_dados_pontos().ponto(str(s.get("seat", ""))).is_empty()


## Quem a sala desenha num papel (`seat`, `stand`, `coach`): {id, point, facing, pose, look, name} ou {}.
## Durante a saída do John vale o que a sala desenhava ANTES dela (a cena assume o desenho).
func papel_da_sala(papel: String) -> Dictionary:
	if papel == "coach":
		var p := ponto_do_coach()
		if p.is_empty():
			return {}
		return {"id": "coach", "point": p, "facing": "right", "pose": "idle", "look": {}, "glove": "none",
			"name": str(gs.dialogos.cast.get("coach", {}).get("name", "Osmar Brandão"))}
	var lista: Array = gs._saida_elenco.get("mentores", []) if gs._saida_tocando else gs.mentores_na_sala()
	for m in lista:
		if str(m.get("role", "")) == papel:
			return m
	return {}


func _toques_valem_aqui() -> bool:
	return gs.mentor_sentado() and gs.local_id in gs.disciples.toques.get("locations", ["garage"])


# 1ª vitória de um discípulo na academia com o John ainda na escola: arma a saída (no save do prêmio, sem salvar aqui).
func _marcar_vitoria_na_academia(oponente: String) -> void:
	var cfg: Dictionary = gs.escola_cfg.get("mentor_leave", {})
	if cfg.is_empty() or gs.lutador_atual() != "disciple" or gs.local_id != str(cfg.get("win_location", "gym")):
		return
	if not ("first" in gs.escola.get("mentors", [])):
		return
	gs._gravar_marco(str(cfg.get("win_milestone", "disciple_gym_win")), {"opponent": oponente}, false)


# Chamado só com sala ativa e arte escolhida: depois de `after_art_seconds` de arte, o gatilho art_choice sai uma vez.
func _tick_comentario_da_arte() -> void:
	if gs._arte_comentada:
		return
	var cfg: Dictionary = gs.escola_cfg.get("art_comment", {})
	if cfg.is_empty():
		gs._arte_comentada = true
		return
	if gs.arte_segundos >= float(cfg.get("after_art_seconds", 60.0)):
		gs._arte_comentada = true
		gs.disparar_gatilho(str(cfg.get("trigger", "art_choice")))


## A saída do John está devida? (design §6.1) John na escola, discípulo jogando, saída ainda não feita e a
## 1ª vitória na academia OU a campanha de reserva (campanha do John + offset).
func saida_devida() -> bool:
	var cfg: Dictionary = gs.escola_cfg.get("mentor_leave", {})
	if cfg.is_empty() or not ("first" in gs.escola.get("mentors", [])) or gs.lutador_atual() != "disciple" or gs.marco(_marco_da_saida()):
		return false
	if gs.marco(str(cfg.get("win_milestone", "disciple_gym_win"))):
		return true
	return gs.numero_carreira() >= int(gs.escola.get("first_fighter_campaign", 1)) + int(cfg.get("reserve_campaign_offset", 3))


## A saída do John está tocando agora.
func saida_tocando() -> bool:
	return gs._saida_tocando


# Roda a cada quadro com a sala calma: pede a saída no 1º momento calmo com o John desenhado (design §6.2).
func _tick_saida(ativa: bool) -> void:
	var cfg: Dictionary = gs.escola_cfg.get("mentor_leave", {})
	if gs._saida_tocando:
		# Trava de segurança: se ninguém avisar o fim (sem interface), a saída acaba sozinha um pouco depois do teto.
		if gs._t_real - gs._saida_inicio > float(cfg.get("max_seconds", 14.0)) + 3.0:
			saida_terminou()
		return
	if not ativa or not saida_devida() or not gs._balao.is_empty() or not gs._gesto.is_empty() or not gs._toques.is_empty():
		return
	if gs._toque_vitoria >= 0.0 or gs._calma < float(cfg.get("settle_seconds", 2.0)) or not gs.mentor_sentado():
		return
	_iniciar_saida()


func _iniciar_saida() -> void:
	var cfg: Dictionary = gs.escola_cfg.mentor_leave
	var cena := CenaDados.carregar_cena(str(cfg.get("scene", "saida_primeiro_mentor")))
	gs._saida_elenco = {"mentores": gs.mentores_na_sala()}  # o que a sala desenhava, antes de o John sair da lista
	# O marco e o que a cena dá são gravados no COMEÇO: fechar o jogo no meio dá o mesmo save.
	gs._gravar_marco(_marco_da_saida(), {}, false)
	gs._sucessao._aplicar_grants(cena.get("grants", [{"type": "mentor_leaves", "character": "first_fighter"}]))
	gs._saida_tocando = true
	gs._saida_inicio = gs._t_real
	gs.salvar()
	gs.saida_mentor_pedida.emit()


## A saída acabou (a cena terminou ou foi interrompida): conta como comentário (intervalo de 60 s) e solta a vaga.
func saida_terminou() -> void:
	if not gs._saida_tocando:
		return
	gs._saida_tocando = false
	gs._saida_elenco = {}
	gs._ultimo_comentario = gs._t_real


# Janela, luta, MUDAR, tela de fim ou RECEBER: a cena aplica o end_state na hora e fecha os balões (sinal).
func _interromper_saida() -> void:
	if not gs._saida_tocando:
		return
	gs.saida_mentor_interrompida.emit()
	saida_terminou()


## O CenaPlayer avisa que uma cena sem controle preso acabou sozinha.
func cena_livre_terminou(id: String) -> void:
	if id == str(gs.escola_cfg.get("mentor_leave", {}).get("scene", "saida_primeiro_mentor")):
		saida_terminou()
