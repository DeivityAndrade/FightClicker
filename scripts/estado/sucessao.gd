extends RefCounted
## Fases 6b1/6b2: passar o posto, discípulo, rascunho, mentores e toques do John.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


## "none" | "scene_1" | "creating" | "scene_2" | "arriving". Fora de "none" a carreira está congelada.
func sucessao_estado() -> String:
	return gs.sucessao


## Id da cena que a sucessão toca agora ("primeira_sucessao" ou "chegada_discipulo"); "" fora da sucessão.
## Depois de abrir um save no meio, a primeira_sucessao vira chegada_discipulo (a cena grande nunca repete).
func sucessao_cena() -> String:
	return str(_handover().get("scene", ""))


func _handover() -> Dictionary:
	var h = gs.escola.get("handover", null)
	return h if h is Dictionary else {}


## Rascunho da tela de criação: {name, look}. {} fora da criação.
func rascunho() -> Dictionary:
	var h := _handover()
	return h.draft.duplicate(true) if h.get("draft", null) is Dictionary else {}


## Linhas da tela de criação (6b2) com o rascunho atual: ver DiscipulosData.linhas_tela(). `apagada` = cor da peça em "sem".
func linhas_tela_criacao() -> Array:
	var d := rascunho()
	return gs.disciples.linhas_tela(d.get("look", {}) if d.get("look", null) is Dictionary else {})


## Nome sem espaços nas pontas e sem repetidos, só com as letras que a fonte desenha ("" se não sobrar nenhuma).
func limpar_nome(texto: String) -> String:
	return gs.disciples.limpar_nome(texto)


## O discípulo da campanha: {name, look, campaign}. {} na campanha do John.
func discipulo_atual() -> Dictionary:
	return gs.discipulo.duplicate(true)


## Nome de quem está lutando: "John Bullet" ou o nome do discípulo. A interface aplica `.to_upper()`.
func nome_lutador() -> String:
	if gs.lutador_atual() == "first":
		return str(gs.dialogos.cast.get("first", {}).get("name", "John Bullet"))
	return str(gs.discipulo.get("name", gs.disciples.nome_padrao))


## Título do resumo de fim de campanha: "RESUMO DE {NOME}".
func titulo_resumo() -> String:
	return gs.preencher(gs.texto_ui("sum_title_named", "RESUMO DE {nome}"), {"nome": nome_lutador().to_upper()})


## Visual do lutador atual (9 campos). {} no John (ele usa as folhas dele).
func visual_lutador() -> Dictionary:
	if gs.lutador_atual() == "first":
		return {}
	var l = gs.discipulo.get("look", null)
	return l.duplicate(true) if l is Dictionary else gs.disciples.look_padrao.duplicate()


## Cores de um visual (padrão: o do lutador atual): {campo: {id, slots, colors (hex), tokens}}. O John devolve {}.
func cores_visual(look: Dictionary = {}) -> Dictionary:
	var l := look if not look.is_empty() else visual_lutador()
	return gs.disciples.cores(l) if not l.is_empty() else {}


## Quem a sala desenha de mentor agora (design 6c1 §4.1; garagem, e academia depois do marco da cena). Só com discípulo jogando.
## Cada item: {id "first"|"last", role "seat"|"stand", spot (nome do ponto), point [x, y], pose, glove, facing, campaign,
## name, look}. Com o John na escola: ele sentado (`seat`) e, se houver, o último que passou o posto em pé (`stand`).
## Depois da saída do John (marco da saída): só o último, sentado, e o `stand` vazio.
func mentores_na_sala() -> Array:
	var r: Array = []
	if gs.lutador_atual() != "disciple":
		return r
	var pontos = gs._casa._spots_do_local()
	if pontos.is_empty():
		return r
	var seat_p = gs.ponto_do_local("seat")
	if mentor_sentado():
		r.append({"id": "first", "role": "seat", "spot": str(pontos.seat), "point": seat_p, "pose": "sit_rest", "glove": "none",
			"facing": "right", "campaign": int(gs.escola.get("first_fighter_campaign", 1)), "name": str(gs.dialogos.cast.get("first", {}).get("name", "John Bullet")),
			"look": {}})
		var s := segundo_mentor()
		if not s.is_empty():
			r.append({"id": "last", "role": "stand", "spot": s.ponto_nome, "point": s.ponto, "pose": s.pose, "glove": s.glove,
				"facing": s.facing, "campaign": s.campaign, "name": s.nome, "look": s.look})
	elif gs.marco(gs._casa._marco_da_saida()) and not seat_p.is_empty():
		var e := segundo_mentor_entrada()
		if not e.is_empty():
			var apos: Dictionary = gs.disciples.mentores_cfg.get("after_first_leaves", {})
			var look = e.get("look", null)
			r.append({"id": "last", "role": "seat", "spot": str(pontos.seat), "point": seat_p, "pose": str(apos.get("pose", "sit_rest")),
				"glove": str(apos.get("glove", "none")), "facing": "right", "campaign": int(e.get("campaign", 0)), "name": str(e.get("name", "")),
				"look": gs.disciples.validar_look(look) if look is Dictionary else gs.disciples.look_padrao.duplicate()})
	return r


## Entrada do roster do segundo mentor (design 6b2 §4.1): a última `kind == "disciple"` com fim em `passed_ends`.
## {} se não há. Sem as condições de sala (para testes e para a 6c).
func segundo_mentor_entrada() -> Dictionary:
	var fins: Array = gs.disciples.mentores_cfg.get("passed_ends", ["defeat", "retire", "unknown"])
	var lista: Array = gs.escola.get("roster", [])
	for i in range(lista.size() - 1, -1, -1):
		var e = lista[i]
		if e is Dictionary and str(e.get("kind", "")) == "disciple" and str(e.get("end", "unknown")) in fins:
			return e.duplicate(true)
	return {}


## Consulta da UI: o segundo mentor em pé agora, ou {}. Vale nos dois locais (garagem; academia depois do marco da cena),
## só com o John sentado (requires_mentor). Escondido nas cenas de `hidden_during_scenes` (a grande da sucessão e a da academia).
## Devolve {nome, look (9 campos), ponto ([x, y] do manifest), pose, glove, facing ("right" | "left", virado para o saco),
## campaign, ponto_nome}. Sem alvo no clique, sem fala (design 6b2 §4.4).
func segundo_mentor() -> Dictionary:
	var cfg: Dictionary = gs.disciples.mentores_cfg.get("second_mentor", {})
	if not bool(cfg.get("enabled", false)) or not mentor_sentado():
		return {}
	if not (str(cfg.get("requires_mentor", "first")) in gs.escola.get("mentors", [])) or not (gs.local_id in cfg.get("locations", ["garage"])):
		return {}
	var escondidas: Array = cfg.get("hidden_during_scenes", [])
	if gs.sucessao != "none" and str(_handover().get("scene", "")) in escondidas:
		return {}
	if gs.cena_sala != "" and gs.cena_sala in escondidas:
		return {}
	var e := segundo_mentor_entrada()
	if e.is_empty():
		return {}
	var nome_ponto = str(gs._casa._spots_do_local().get("stand", ""))
	var p = gs.ponto_do_local("stand")
	if nome_ponto == "" or p.size() != 2:
		return {}
	var bag_x := float(cfg.get("bag_x", 320))
	var lado := "right" if float(p[0]) < bag_x else "left"
	var look = e.get("look", null)
	return {"nome": str(e.get("name", "")), "look": gs.disciples.validar_look(look) if look is Dictionary else gs.disciples.look_padrao.duplicate(),
		"ponto": [int(p[0]), int(p[1])], "ponto_nome": nome_ponto, "pose": str(cfg.get("pose", "stand_bare")),
		"glove": str(cfg.get("glove", "none")), "facing": lado, "campaign": int(e.get("campaign", 0))}


## O John está sentado no caixote do local atual (desenhado e com os toques valendo)? Só com discípulo jogando, o John na escola
## e o local com os pontos de mentor liberados (garagem; academia depois do marco da cena).
func mentor_sentado() -> bool:
	if gs.lutador_atual() != "disciple" or not ("first" in gs.escola.get("mentors", [])):
		return false
	return not gs._casa._spots_do_local().is_empty() and not gs.ponto_do_local("seat").is_empty()


## Lista da escola: quem passou o posto, em ordem (cópia). Ver design §3.4.
func escola_lista() -> Array:
	return gs.escola.get("roster", []).duplicate(true)


func _discipulo_padrao() -> Dictionary:
	return {"name": gs.disciples.nome_padrao, "look": gs.disciples.look_padrao.duplicate(), "campaign": gs.numero_carreira()}


## RECEBER NOVO DISCÍPULO (substitui a chamada da interface a nova_carreira()). Só com a tela de fim pendente.
## Zera a campanha (mesma conta de hoje) e segura o começo: cartão, escolha da arte e fala da derrota só saem em
## sucessao_terminou(). Primeira sucessão: grava o marco e os grants já aqui. No "começo do John" (save antigo,
## campanha nova == campanha do John) é a NOVA CAMPANHA de sempre, sem tela e sem cena.
func receber_discipulo() -> bool:
	if gs.fim.is_empty() or gs.sucessao != "none":
		return false
	gs._casa._interromper_saida()  # 6c1: RECEBER termina a saída do John na hora
	var nova = gs.numero_carreira() + 1
	if nova <= int(gs.escola.get("first_fighter_campaign", 1)):
		return gs.nova_carreira()
	gs._reiniciar_campanha()
	var ctx = {"milestones": gs.escola.milestones, "campaign": nova, "campaigns_finished": int(gs.permanente.get("careers_finished", 0)),
		"location": gs.local_id, "calm": true}
	var cena_id := CenaDados.escolher_cena("handover_started", ctx)
	if cena_id == "":
		cena_id = str(gs.disciples.passagem.get("short_scene", "chegada_discipulo"))
	var cena := CenaDados.carregar_cena(cena_id)
	var grande := str(cena.get("milestone", "")) != ""
	gs.escola["handover"] = {"stage": "creating", "campaign": nova, "scene": cena_id,
		"draft": gs.disciples.sortear(gs._rng_sucessao, gs.escola.roster)}
	gs.sucessao = "scene_1" if grande else "creating"
	gs.sucessao_retomada = false
	gs._cena_grande_ativa = grande
	if grande:
		# O marco e o que ele dá são gravados no COMEÇO da cena: pular ou fechar o jogo dão o mesmo save.
		gs._escola._gravar_marco(str(cena.milestone), {}, false)
		_aplicar_grants(cena.get("grants", []))
	gs.salvar()
	gs._tempo_autosave = 0.0
	gs._emitir_tudo(false)
	gs.permanente_mudou.emit()
	gs.sucessao_mudou.emit(gs.sucessao)
	gs.rascunho_mudou.emit()
	return true


func _aplicar_grants(grants: Array) -> void:
	var mentores: Array = gs.escola.mentors
	for g in grants:
		if not (g is Dictionary):
			continue
		var quem := "first" if str(g.get("character", "")).begins_with("first_fighter") else ""
		if quem == "":
			continue
		if str(g.get("type", "")) == "mentor_in_room" and not (quem in mentores):
			mentores.append(quem)
		elif str(g.get("type", "")) == "mentor_leaves":
			mentores.erase(quem)


## O player chegou no passo `open_screen` (cena grande): a tela de criação abre. scene_1 -> creating.
func sucessao_tela_aberta() -> void:
	if gs.sucessao == "scene_1":
		gs.sucessao = "creating"
		gs.sucessao_mudou.emit(gs.sucessao)


## Sorteia TUDO de novo no rascunho (botão SORTEAR). Só com a tela aberta.
func sortear_rascunho() -> bool:
	var h := _handover()
	if gs.sucessao != "creating" or h.is_empty():
		return false
	h["draft"] = gs.disciples.sortear(gs._rng_sucessao, gs.escola.roster, str(h.get("draft", {}).get("name", "")))
	gs.rascunho_mudou.emit()
	return true


## Troca um campo do rascunho: "name" (texto digitado; a interface já recusa o que a fonte não desenha) ou um campo do
## look (skin, hair_color, shorts_color... só opções ligadas). Não salva (vai no autosave).
func definir_rascunho(campo: String, valor: String) -> bool:
	var h := _handover()
	if gs.sucessao != "creating" or h.is_empty() or not (h.get("draft", null) is Dictionary):
		return false
	var d: Dictionary = h.draft
	if campo == "name":
		d["name"] = gs.disciples.filtrar_digitacao(valor)
	elif d.look.has(campo) and valor in gs.disciples.opcoes_ativas(campo):
		d.look[campo] = valor
	else:
		return false
	gs.rascunho_mudou.emit()
	return true


## CONFIRMAR. Nome vazio: o campo volta a um nome sorteado e não confirma (false). Senão grava o discípulo, o estado
## `arriving` no save, e a sucessão segue: scene_2 (a cena grande continua) ou arriving (chegada curta).
func confirmar_discipulo() -> bool:
	var h := _handover()
	if gs.sucessao != "creating" or h.is_empty():
		return false
	var d: Dictionary = h.draft
	var nome = gs.disciples.limpar_nome(str(d.get("name", "")))
	if nome == "":
		d["name"] = gs.disciples.sortear_nome(gs._rng_sucessao, gs.escola.roster)
		gs.rascunho_mudou.emit()
		return false
	gs.discipulo = {"name": nome, "look": gs.disciples.validar_look(d.get("look", {})), "campaign": gs.numero_carreira()}
	h["stage"] = "arriving"
	gs.sucessao = "scene_2" if gs._cena_grande_ativa else "arriving"
	gs.salvar()
	gs._tempo_autosave = 0.0
	gs.carreira_mudou.emit()
	gs.sucessao_mudou.emit(gs.sucessao)
	return true


## A cena devolveu o controle (return_control) ou foi pulada: a campanha começa. Apaga o `handover`, salva e emite o
## começo (nova_carreira_iniciada, escolha_arte_pedida se pendente, gatilho after_defeat). O relógio anda a partir daqui.
func sucessao_terminou() -> bool:
	if gs.sucessao != "scene_2" and gs.sucessao != "arriving":
		return false
	var h := _handover()
	gs._reacao_cena = str(h.get("scene", "")) if gs._cena_grande_ativa else ""
	gs._cena_grande_ativa = false
	gs.escola["handover"] = null
	gs.sucessao = "none"
	gs.sucessao_retomada = false
	gs.salvar()
	gs._tempo_autosave = 0.0
	gs.sucessao_mudou.emit("none")
	gs._checar_sala()
	gs._emitir_inicio_da_campanha()
	return true


# Depois de validar a escola: o que o save diz sobre uma sucessão em andamento.
func _aplicar_handover_da_carga() -> void:
	gs.sucessao = "none"
	gs.sucessao_retomada = false
	gs._cena_grande_ativa = false
	gs._reacao_cena = ""
	var h := _handover()
	if h.is_empty():
		return
	gs.sucessao_retomada = true
	if str(h.stage) == "creating":
		gs.sucessao = "creating"
		# A parte 1 não toca de novo: a cena grande vira a chegada curta (fecha na criação; ao confirmar, chegada).
		if str(CenaDados.carregar_cena(str(h.scene)).get("milestone", "")) != "":
			h["scene"] = str(gs.disciples.passagem.get("short_scene", "chegada_discipulo"))
	else:
		gs.sucessao = "arriving"
		var d: Dictionary = h.get("draft", {})
		gs.discipulo = {"name": str(d.get("name", gs.disciples.nome_padrao)), "look": d.get("look", {}), "campaign": gs.numero_carreira()}


# career.disciple: {name, look, campaign}. Na campanha do John é {}. Faltando nas outras: o Novato padrão, com aviso
# (na tela de criação ainda não existe e não é erro).
func _validar_discipulo(v: Variant, havia_save: bool) -> Dictionary:
	if gs.lutador_atual() == "first":
		return {}
	if gs.sucessao == "creating":
		return {}
	if gs.sucessao == "arriving" and not gs.discipulo.is_empty():
		var nome_seguro = gs.disciples.limpar_nome(str(gs.discipulo.get("name", "")))
		return {"name": nome_seguro if nome_seguro != "" else gs.disciples.nome_padrao,
			"look": gs.disciples.validar_look(gs.discipulo.get("look", {})), "campaign": gs.numero_carreira()}
	if v is Dictionary:
		var nome = gs.disciples.limpar_nome(str(v.get("name", "")))
		var avisos: Array = []
		var look = gs.disciples.validar_look(v.get("look", null), avisos)
		if nome == "" or not avisos.is_empty():
			gs._avisar("Discípulo salvo com dados inválidos: campos trocados pelo padrão.")
		return {"name": nome if nome != "" else gs.disciples.nome_padrao, "look": look,
			"campaign": maxi(1, gs._inteiro_valido(v.get("campaign", gs.numero_carreira()), 1.0e9))}
	if havia_save:
		gs._avisar("Save sem o discípulo: o Novato padrão foi criado.")
	return _discipulo_padrao()


# Campos novos da escola (6b1): handover, mentors e roster. Ausente ou inválido: padrão (com aviso se havia save).
func _validar_escola_6b(s: Dictionary, r: Dictionary) -> void:
	var primeiro: int = int(r.first_fighter_campaign)
	var ms = s.get("mentors", [])
	if ms is Array:
		for m in ms:
			if str(m) == "first" and not ("first" in r.mentors):
				r.mentors.append("first")
	elif s.has("mentors"):
		gs._avisar("Mentores da escola inválidos: zerados.")
	var lista = s.get("roster", [])
	if lista is Array:
		for e in lista:
			var ok := _validar_entrada_da_lista(e)
			if not ok.is_empty():
				r.roster.append(ok)
	elif s.has("roster"):
		gs._avisar("Lista da escola inválida: zerada.")
	var h = s.get("handover", null)
	if h == null:
		return
	var camp = gs._inteiro_valido(h.get("campaign", 0), 1.0e9) if h is Dictionary else 0
	if not (h is Dictionary) or not (str(h.get("stage", "")) in ["creating", "arriving"]) or not gs.fim.is_empty() \
			or camp != gs.numero_carreira() or camp <= primeiro:
		gs._avisar("Sucessão salva inválida: descartada.")
		return
	var d = h.get("draft", {})
	var avisos: Array = []
	var nome: String = gs.disciples.limpar_nome(str(d.get("name", ""))) if d is Dictionary else ""
	if nome == "":
		nome = gs.disciples.sortear_nome(gs._rng_sucessao, r.roster)
	var cena_id := str(h.get("scene", ""))
	if CenaDados.carregar_cena(cena_id).is_empty():
		cena_id = str(gs.disciples.passagem.get("short_scene", "chegada_discipulo"))
	r["handover"] = {"stage": str(h.stage), "campaign": camp, "scene": cena_id,
		"draft": {"name": nome, "look": gs.disciples.validar_look(d.get("look", null) if d is Dictionary else null, avisos)}}


func _validar_entrada_da_lista(e: Variant) -> Dictionary:
	if not (e is Dictionary):
		return {}
	var tipo := str(e.get("kind", ""))
	if not (tipo in ["first", "disciple"]):
		return {}
	var fim_tipo := str(e.get("end", "unknown"))
	var olhar = e.get("look", null)
	var look_ok = null
	if tipo == "disciple":
		look_ok = gs.disciples.validar_look(olhar) if olhar is Dictionary else gs.disciples.look_padrao.duplicate()
	return {"campaign": maxi(1, gs._inteiro_valido(e.get("campaign", 1), 1.0e9)), "kind": tipo,
		"name": gs.disciples.limpar_nome(str(e.get("name", ""))) if tipo == "disciple" else str(e.get("name", "")),
		"look": look_ok,
		"end": fim_tipo if fim_tipo in ["defeat", "retire", "unknown"] else "unknown",
		"wins": clampi(int(gs._numero_ou(e.get("wins", -1), -1.0)), -1, 1000000),
		"belt": typeof(e.get("belt", false)) == TYPE_BOOL and e.get("belt", false),
		"art": str(e.get("art", "")), "opponent": str(e.get("opponent", "")),
		"legacy_gained": gs._inteiro_valido(e.get("legacy_gained", 0), 1.0e15),
		"honor": gs._inteiro_valido(e.get("honor", 0), 1.0e15) if fim_tipo == "retire" else 0}


# Uma entrada na lista da escola para a campanha que acabou de encerrar (no mesmo salvar() do Legado).
func _registrar_na_lista_da_escola(tipo: String, snap: Dictionary, ganho: int, honra_ganha: int = 0) -> void:
	var primeiro = int(gs.escola.get("first_fighter_campaign", 1))
	if gs.numero_carreira() < primeiro:
		return  # campanhas de antes do John não entram
	var e_john = gs.numero_carreira() == primeiro
	gs.escola.roster.append({"campaign": gs.numero_carreira(), "kind": "first" if e_john else "disciple", "name": nome_lutador(),
		"look": null if e_john else visual_lutador(), "end": tipo, "wins": gs.indice_escada, "belt": gs.cinturao, "art": gs.arte_id,
		"opponent": str(snap.get("opponent", "")) if tipo == "defeat" else "", "legacy_gained": ganho,
		"honor": honra_ganha})


# 1º clique da campanha: grava mentor_greeted na hora e pede os toques (se o intervalo de 60 s deixar).
func _toques_do_primeiro_clique() -> void:
	if gs.mentor_cumprimentou or gs.lutador_atual() != "disciple":
		return
	gs.mentor_cumprimentou = true
	if bool(gs.disciples.toques.get("on_first_click", true)):
		_pedir_toques("first_click")
	gs._reacao_cena = ""


# Pede os dois toques sem luva do John. Devolve o plano (e emite toques_mentor_pedidos) ou {} se não vale:
# sem John sentado, sala parada, desligado nos dados ou dentro do intervalo (descartado, nunca guardado).
# Plano: {momento ("first_click"|"win_return"), version "short", start 0, duration, taps [t1, t2], tap_sound, anim, guard,
# cena (id da cena que cuida da animação: a interface NÃO repete os toques), com_fala}.
func _pedir_toques(momento: String) -> Dictionary:
	var cfg: Dictionary = gs.disciples.toques
	if not bool(cfg.get("enabled", true)) or not mentor_sentado() or not gs.sala_ativa():
		return {}
	if gs._t_real - gs._toque_ultimo < float(cfg.get("cooldown_seconds", 60.0)):
		return {}
	gs._toque_ultimo = gs._t_real
	var g: Dictionary = gs.dialogos.gesture
	var primeiro := float(g.get("short_tap_at", 0.11))
	var duracao := float(g.get("short_seconds", 0.44))
	var guarda := float(cfg.get("first_click_guard_seconds", 0.5)) if momento == "first_click" else 0.0
	var cena = gs._reacao_cena if momento == "first_click" else ""
	var plano := {"momento": momento, "version": "short", "start": 0.0, "duration": duracao,
		"taps": [primeiro, primeiro + float(cfg.get("tap_interval", 0.22))],
		"tap_sound": str(cfg.get("sound", "tap_fist")), "anim": str(cfg.get("anim", "mentor_first_taps")),
		"guard": guarda, "cena": cena, "com_fala": cena != ""}
	gs._toques = {"momento": momento, "inicio": gs._t_real, "ate": gs._t_real + duracao, "guarda": guarda}
	gs.toques_mentor_pedidos.emit(plano)
	return plano


# Cancela os toques. `forcar` ignora a guarda do 1º clique (janela, luta, mudança de local).
func _cancelar_toques(forcar: bool) -> void:
	if gs._toques.is_empty():
		return
	if not forcar and gs._t_real - float(gs._toques.inicio) < float(gs._toques.guarda):
		return
	gs._toques = {}
	gs.toques_mentor_cancelados.emit()


func _toques_apos_vitoria(resumo: Dictionary) -> void:
	if bool(resumo.get("win", false)) and not resumo.has("retire") and mentor_sentado() \
			and bool(gs.disciples.toques.get("enabled", true)) and bool(gs.disciples.toques.get("on_win_return", true)):
		gs._toque_vitoria = 0.0


func _tick_toques(delta: float, ativa: bool) -> void:
	if not gs._toques.is_empty():
		if not gs._casa._toques_valem_aqui() or not ativa:
			_cancelar_toques(true)
		elif gs._t_real >= float(gs._toques.ate):
			gs._toques = {}
	if gs._toque_vitoria >= 0.0:
		if not gs._casa._toques_valem_aqui() or not gs.luta.is_empty():
			gs._toque_vitoria = -1.0  # lutar de novo ou mudar de local cancela
		elif ativa:
			gs._toque_vitoria += delta
			if gs._toque_vitoria >= float(gs.disciples.toques.get("win_return_delay_seconds", 1.0)):
				gs._toque_vitoria = -1.0
				_pedir_toques("win_return")
