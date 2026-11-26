class_name RondaData
extends RefCounted
## Ronda Noturna do Gato Preto: lê e valida data/ronda.json (capuz, tipos de noite, lenda). Arquivo ausente = `vazio`
## (o jogo segue como a 8a2: sem capuz, sem lenda). A região e os nós da árvore entram pelo FightData.
## Número fora da faixa volta ao padrão com aviso; tipo de noite com `kind` desconhecido sai com aviso.

const CAMINHO := "res://data/ronda.json"
const KINDS := ["stealth_scare", "alley_fight"]  # lógicas de noite que existem (SUSTO e briga de beco da Ronda 2a1)
const DESAFIOS := ["surprise", "early_finish", "clean_win", "surprise_early"]  # tipos de desafio dos bandidos
const REQUISITOS := ["legend_level", "milestone"]  # chaves aceitas em `requires` da briga
const REQUISITOS_CHEFE := ["legend_level", "all_bandits", "regional_belts_min"]  # chaves aceitas em `requires` do chefe (2a2)

var vazio := true
var abertura := {"requires_milestone": "black_cat_rumor_heard", "campaigns_after_rumor": 1, "min_campaign": 3, "no_rumor_from_campaign": 5}
var capuz := {"first_after_s": 180.0, "interval_s": 300.0, "spot_by_location": {}, "hover_text": "hood_hover", "night_choice": "first_available", "hideout_from": ""}
var ordem: Array[String] = []  # night_order (só as noites válidas)
var noites: Dictionary = {}  # id -> bloco (números já validados)
var niveis: Array[int] = [1, 10, 24, 42, 64]
var recortes: Array[String] = []  # chave de texto por nível (0..5)
var camadas: Array = []  # camadas da rua por nível (0..5)
var avisos: Array[String] = []


static func carregar(caminho: String = CAMINHO) -> RondaData:
	var r := RondaData.new()
	if not FileAccess.file_exists(caminho):
		return r
	var bruto = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if not (bruto is Dictionary):
		r._aviso("ronda.json ilegível: sem Ronda.")
		return r
	r._ler(bruto)
	return r


func _aviso(m: String) -> void:
	avisos.append(m)
	push_warning("RondaData: " + m)


## Número da chave na faixa; ausente/ruim = padrão (com aviso); fora da faixa é recortado.
func _num(d: Dictionary, chave: String, padrao: float, lo: float, hi: float, prefixo: String = "") -> float:
	var v = d.get(chave, null)
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT or not is_finite(float(v)):
		_aviso("%s%s ausente ou inválido: padrão %s." % [prefixo, chave, str(padrao)])
		return padrao
	return clampf(float(v), lo, hi)


func _ler(d: Dictionary) -> void:
	var o = d.get("opening", {})
	if o is Dictionary:
		abertura["requires_milestone"] = str(o.get("requires_milestone", abertura.requires_milestone))
		abertura["campaigns_after_rumor"] = int(_num(o, "campaigns_after_rumor", 1.0, 0.0, 99.0, "opening."))
		abertura["min_campaign"] = int(_num(o, "min_campaign", 3.0, 1.0, 999.0, "opening."))
		# Rede de segurança (decisão do dono): sem o boato até a campanha anterior, o capuz aparece a partir desta. Opcional.
		abertura["no_rumor_from_campaign"] = int(clampf(float(o.get("no_rumor_from_campaign", 5.0)), 1.0, 999.0)) if typeof(o.get("no_rumor_from_campaign", 5)) in [TYPE_INT, TYPE_FLOAT] else 5
	var h = d.get("hood", {})
	if h is Dictionary:
		capuz["first_after_s"] = _num(h, "first_after_s", 180.0, 1.0, 1.0e6, "hood.")
		capuz["interval_s"] = _num(h, "interval_s", 300.0, 1.0, 1.0e6, "hood.")
		var sp = h.get("spot_by_location", {})
		capuz["spot_by_location"] = sp.duplicate() if sp is Dictionary else {}
		capuz["hover_text"] = str(h.get("hover_text", "hood_hover"))
		capuz["night_choice"] = str(h.get("night_choice", "first_available"))
		capuz["hideout_from"] = str(h.get("hideout_from", ""))  # 2a1: noite que, disponível, faz o capuz abrir o Esconderijo
	var nn = d.get("nights", {})
	var ordem_bruta = d.get("night_order", [])
	if nn is Dictionary and ordem_bruta is Array:
		for id in ordem_bruta:
			var b = nn.get(str(id), null)
			if not (b is Dictionary):
				_aviso("night_order: noite '%s' não existe." % id)
				continue
			var n := _noite(str(id), b, nn)
			if n.is_empty():
				continue
			noites[str(id)] = n
			ordem.append(str(id))
	var lg = d.get("legend", {})
	if lg is Dictionary:
		var lv = lg.get("levels", null)
		var ok: Array[int] = []
		if lv is Array:
			for x in lv:
				if typeof(x) in [TYPE_INT, TYPE_FLOAT] and int(x) > (ok[-1] if not ok.is_empty() else 0):
					ok.append(int(x))
				else:
					ok = []
					break
		if not ok.is_empty():
			niveis = ok
		else:
			_aviso("legend.levels inválido (precisa crescer): padrão 1/10/24/42/64.")
		var rc = lg.get("clipping_text_by_level", [])
		for x in (rc if rc is Array else []):
			recortes.append(str(x))
		camadas = (lg.get("street_layers_by_level", []) as Array).duplicate(true) if lg.get("street_layers_by_level", []) is Array else []
	vazio = ordem.is_empty()


func _noite(id: String, b: Dictionary, todas: Dictionary = {}) -> Dictionary:
	var kind := str(b.get("kind", ""))
	if not (kind in KINDS):
		_aviso("noite '%s' com kind desconhecido ('%s'): ignorada." % [id, kind])
		return {}
	if kind == "alley_fight":
		return _noite_beco(id, b, todas.get("scare", {}) if todas.get("scare", {}) is Dictionary else {})
	var p := "nights.%s." % id
	var r := {"id": id, "kind": kind, "name": str(b.get("name", "")), "tip": str(b.get("tip", "")),
		"requires": (b.get("requires", {}) as Dictionary).duplicate() if b.get("requires", {}) is Dictionary else {},
		"countdown_s": _num(b, "countdown_s", 2.0, 0.0, 60.0, p), "night_s": _num(b, "night_s", 34.0, 1.0, 600.0, p),
		"intro_s": _num(b, "intro_s", 0.8, 0.0, 60.0, p), "advance_per_s": _num(b, "advance_per_s", 0.25, 0.01, 10.0, p),
		"scare_zone": _num(b, "scare_zone", 0.8, 0.0, 1.0, p), "grace_s": _num(b, "grace_s", 0.2, 0.0, 5.0, p),
		"scare_anim_s": _num(b, "scare_anim_s", 1.6, 0.0, 60.0, p), "seen_anim_s": _num(b, "seen_anim_s", 1.2, 0.0, 60.0, p),
		"hold_hint_s": _quieto(b, "hold_hint_s", 0.6, 0.0, 60.0)}  # D2: opcional (ausente = 0,6 s), sem aviso
	var oc: Array = []
	var lista = b.get("occurrences", [])
	for item in (lista if lista is Array else []):
		if not (item is Dictionary) or str(item.get("id", "")) == "":
			continue
		oc.append(_ocorrencia(item, p + "occurrences."))
	if oc.is_empty():
		_aviso("noite '%s' sem ocorrências: ignorada." % id)
		return {}
	r["occurrences"] = oc
	var lg = b.get("legend", {})
	r["legend"] = {"floor": int(_num(lg if lg is Dictionary else {}, "floor", 1.0, 0.0, 100.0, p + "legend.")),
		"per_scare": int(_num(lg if lg is Dictionary else {}, "per_scare", 1.0, 0.0, 100.0, p + "legend.")),
		"clean_bonus": int(_num(lg if lg is Dictionary else {}, "clean_bonus", 1.0, 0.0, 100.0, p + "legend."))}
	return r


## Número opcional: ausente ou ruim = padrão, sem aviso; fora da faixa é recortado.
func _quieto(d: Dictionary, chave: String, padrao: float, lo: float, hi: float) -> float:
	var v = d.get(chave, null)
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT or not is_finite(float(v)):
		return padrao
	return clampf(float(v), lo, hi)


## Uma ocorrência (ladrão/bandido): ciclo gap -> aviso -> olhando. Mesmo formato na Ronda 1 e na aproximação da briga.
func _ocorrencia(item: Dictionary, q: String) -> Dictionary:
	var a := _num(item, "gap_min", 2.0, 0.1, 60.0, q)
	var z := _num(item, "gap_max", 3.0, 0.1, 60.0, q)
	if a > z:
		var t := a
		a = z
		z = t
	return {"id": str(item.id), "spot": str(item.get("spot", "")), "name": str(item.get("name", "")), "gap_min": a, "gap_max": z,
		"warn_s": _num(item, "warn_s", 0.8, 0.0, 10.0, q), "look_s": _num(item, "look_s", 1.2, 0.0, 10.0, q),
		"fake_warn": _num(item, "fake_warn", 0.0, 0.0, 1.0, q)}


## Noite de briga de beco (Ronda 2a1): aproximação com os tempos da `scare` (`scare_b`) + bandidos. Sem bandido válido = ignorada.
func _noite_beco(id: String, b: Dictionary, scare_b: Dictionary) -> Dictionary:
	var p := "nights.%s." % id
	var rq: Dictionary = {}
	var ok_rq := true
	var rb = b.get("requires", {})
	if rb is Dictionary:
		for k in rb:
			if not (str(k) in REQUISITOS):
				_aviso("%srequires.%s desconhecido: noite indisponível." % [p, str(k)])
				ok_rq = false
		rq = {"legend_level": int(_quieto(rb, "legend_level", 0.0, 0.0, 99.0)), "milestone": str(rb.get("milestone", ""))}
	else:
		ok_rq = false
	var r := {"id": id, "kind": "alley_fight", "name": str(b.get("name", "")), "tip": str(b.get("tip", "")), "requires": rq, "disponivel": ok_rq,
		"countdown_s": _num(b, "countdown_s", 2.0, 0.0, 60.0, p), "approach_s": _num(b, "approach_s", 8.0, 1.0, 120.0, p),
		"prize_s": _num(b, "prize_s", 3.0, 0.0, 60.0, p),
		"intro_s": _quieto(scare_b, "intro_s", 0.8, 0.0, 60.0), "advance_per_s": _quieto(scare_b, "advance_per_s", 0.25, 0.01, 10.0),
		"scare_zone": _quieto(scare_b, "scare_zone", 0.8, 0.0, 1.0), "grace_s": _quieto(scare_b, "grace_s", 0.2, 0.0, 5.0),
		"scare_anim_s": _quieto(scare_b, "scare_anim_s", 1.6, 0.0, 60.0), "seen_anim_s": _quieto(scare_b, "seen_anim_s", 1.2, 0.0, 60.0),
		"hold_hint_s": _quieto(scare_b, "hold_hint_s", 0.6, 0.0, 60.0)}
	r["night_s"] = r.approach_s
	var lg = b.get("legend", {})
	var lgd: Dictionary = lg if lg is Dictionary else {}
	r["legend"] = {"floor": int(_num(lgd, "floor", 1.0, 0.0, 100.0, p + "legend.")), "per_scare": int(_num(lgd, "per_scare", 1.0, 0.0, 100.0, p + "legend.")),
		"win": int(_num(lgd, "win", 2.0, 0.0, 100.0, p + "legend.")), "clean_bonus": 0}
	var bandidos: Array = []
	var vistos: Array[String] = []
	var lista = b.get("bandits", [])
	for item in (lista if lista is Array else []):
		var bd := _bandido(item, p + "bandits.", vistos)
		if not bd.is_empty():
			bandidos.append(bd)
			vistos.append(str(bd.id))
	if bandidos.is_empty():
		_aviso("noite '%s' sem bandidos válidos: ignorada." % id)
		return {}
	r["bandits"] = bandidos
	r["boss"] = _chefe(b.get("boss", null), p + "boss.", vistos)  # 2a2: {} = sem chefe (a ficha "???" da 2a1 continua)
	r["occurrences"] = bandidos.map(func(x: Dictionary) -> Dictionary: return x.approach)
	return r


func _bandido(item: Variant, p: String, vistos: Array[String]) -> Dictionary:
	if not (item is Dictionary) or str(item.get("id", "")) == "" or str(item.id) in vistos:
		_aviso("%s: bandido sem id ou repetido: ignorado." % p)
		return {}
	var id := str(item.id)
	var q := "%s%s." % [p, id]
	var ap = item.get("approach", null)
	var f := _quieto(item, "strength", 0.0, 0.0, 1.0e15)
	var a := _quieto(item, "agility", 0.0, 0.0, 1.0e15)
	var r := _quieto(item, "endurance", 0.0, 0.0, 1.0e15)
	if not (ap is Dictionary) or f <= 0.0 or a <= 0.0 or r <= 0.0:
		_aviso("%s: sem aproximação ou atributo não positivo: bandido ignorado." % q)
		return {}
	var ap2: Dictionary = (ap as Dictionary).duplicate()
	if str(ap2.get("id", "")) == "":
		ap2["id"] = id
	var d := {"id": id, "approach": _ocorrencia(ap2, q + "approach."), "name": str(item.get("name", "")), "nickname": str(item.get("nickname", "")),
		"profile": str(item.get("profile", "")), "strength": f, "agility": a, "endurance": r,
		"passive": (item.get("passive", {}) as Dictionary).duplicate(true) if item.get("passive", {}) is Dictionary else {},
		"clipping": str(item.get("clipping", "")), "style": {}, "challenge": {}, "dossier": {}}
	var ds = item.get("dossier", {})
	if ds is Dictionary:
		d["dossier"] = {"portrait": str(ds.get("portrait", "")), "rap_sheet": str(ds.get("rap_sheet", "")),
			"headline": str(ds.get("headline", "")), "witness": str(ds.get("witness", ""))}
	var ch = item.get("challenge", null)
	if ch is Dictionary and str(ch.get("type", "")) in DESAFIOS:
		d["challenge"] = {"type": str(ch.type), "text": str(ch.get("text", "")),
			"max_round": int(_quieto(ch, "max_round", 2.0, 1.0, 9.0)), "min_life": _quieto(ch, "min_life", 0.6, 0.0, 1.0)}
		var st = item.get("style", null)
		if st is Dictionary and str(st.get("id", "")) != "":
			d["style"] = {"id": str(st.id), "field": str(st.get("field", "")), "option": str(st.get("option", ""))}
	else:
		_aviso("%s: desafio ausente ou com tipo desconhecido: bandido sem desafio e sem estilo." % q)
	return d


## O chefe (2a2): um bandido com extras (arena, letreiro, apagão, troféu, título, camada do menu). Ausente/ruim = {}.
func _chefe(item: Variant, p: String, vistos: Array[String]) -> Dictionary:
	if item == null:
		return {}
	var d := _bandido(item, p, vistos)
	if d.is_empty():
		return {}
	var rq := {"legend_level": 0, "all_bandits": false, "regional_belts_min": 0}
	var ok_rq := true
	var rb = item.get("requires", null)
	if rb is Dictionary:
		for k in rb:
			if not (str(k) in REQUISITOS_CHEFE):
				_aviso("%srequires.%s desconhecido: chefe indisponível." % [p, str(k)])
				ok_rq = false
		rq = {"legend_level": int(_quieto(rb, "legend_level", 0.0, 0.0, 99.0)), "all_bandits": bool(rb.get("all_bandits", false)),
			"regional_belts_min": int(_quieto(rb, "regional_belts_min", 0.0, 0.0, 999.0))}
	else:
		ok_rq = false
	d["requires"] = rq
	d["disponivel"] = ok_rq
	d["arena"] = str(item.get("arena", "arena_alley"))
	d["entrance_banner"] = str(item.get("entrance_banner", ""))
	d["entrance_s"] = _quieto(item, "entrance_s", 1.5, 0.0, 30.0)
	var bo = item.get("blackout", {})
	var bod: Dictionary = bo if bo is Dictionary else {}
	d["blackout"] = {"after_round": int(_quieto(bod, "after_round", 2.0, 1.0, 99.0)), "dark_s": _quieto(bod, "dark_s", 1.0, 0.0, 10.0), "visual_only": true}
	var tr = item.get("trophy", {})
	var trd: Dictionary = tr if tr is Dictionary else {}
	d["trophy"] = {"id": str(trd.get("id", "")), "slot": int(_quieto(trd, "slot", 0.0, 0.0, 3.0)), "sprite": str(trd.get("sprite", "")),
		"sprite_rare": str(trd.get("sprite_rare", "")), "name": str(trd.get("name", "")), "name_rare": str(trd.get("name_rare", ""))}
	d["press_title"] = str(item.get("press_title", ""))
	d["menu_layer"] = str(item.get("menu_layer", ""))
	return d


## Termina a validação com os dados do jogo: passiva do bandido (a mesma regra da liga) e estilo (a opção tem de existir no
## disciples.json, com `requires` igual a "black_cat_style:<id>"). Inválido = sem passiva / sem estilo, com aviso.
func validar_com(lutas: FightData, disc: DiscipulosData) -> void:
	var beco: Dictionary = noites.get("alley", {})
	var todos: Array = beco.get("bandits", []).duplicate()
	if not beco.get("boss", {}).is_empty():
		todos.append(beco.boss)
	for b in todos:
		if not b.passive.is_empty() and lutas != null:
			b["passive"] = lutas._validar_passiva_adv(b.passive, str(b.id))
		var st: Dictionary = b.style
		if st.is_empty() or disc == null:
			continue
		var o: Dictionary = disc._opcao(str(st.field), str(st.option))
		if o.is_empty() or str(o.get("requires", "")) != "black_cat_style:%s" % st.id:
			_aviso("bandido '%s': estilo '%s' não existe no disciples.json (ou o requires não bate): sem estilo." % [b.id, st.id])
			b["style"] = {}


## Bloco da aproximação de um bandido, no formato que a RondaLogica lê (1 ocorrência, night_s = approach_s). {} se o id não existe.
func cfg_aproximacao(bandido_id: String) -> Dictionary:
	var beco: Dictionary = noites.get("alley", {})
	var todos: Array = beco.get("bandits", []).duplicate()
	if not beco.get("boss", {}).is_empty():
		todos.append(beco.boss)
	for b in todos:
		if str(b.id) == bandido_id:
			var c := beco.duplicate()
			c["occurrences"] = [b.approach]
			c["night_s"] = beco.approach_s
			return c
	return {}


## Nível (0 a niveis.size()) de uma lenda.
func nivel_de(lenda: int) -> int:
	var n := 0
	for x in niveis:
		if lenda >= x:
			n += 1
	return n


## Chave de texto do recorte do nível (nível 0 = o de sempre).
func chave_recorte(nivel: int) -> String:
	if nivel >= 0 and nivel < recortes.size():
		return recortes[nivel]
	return "black_cat_clipping"
