class_name RondaData
extends RefCounted
## Ronda Noturna do Gato Preto: lê e valida data/ronda.json (capuz, tipos de noite, lenda). Arquivo ausente = `vazio`
## (o jogo segue como a 8a2: sem capuz, sem lenda). A região e os nós da árvore entram pelo FightData.
## Número fora da faixa volta ao padrão com aviso; tipo de noite com `kind` desconhecido sai com aviso.

const CAMINHO := "res://data/ronda.json"
const KINDS := ["stealth_scare"]  # lógicas de noite que existem (gancho do futuro: lutas contra bandidos)

var vazio := true
var abertura := {"requires_milestone": "black_cat_rumor_heard", "campaigns_after_rumor": 1, "min_campaign": 3, "no_rumor_from_campaign": 5}
var capuz := {"first_after_s": 180.0, "interval_s": 240.0, "spot_by_location": {}, "hover_text": "hood_hover", "night_choice": "first_available"}
var ordem: Array[String] = []  # night_order (só as noites válidas)
var noites: Dictionary = {}  # id -> bloco (números já validados)
var niveis: Array[int] = [1, 12, 30, 52, 80]
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
		capuz["interval_s"] = _num(h, "interval_s", 240.0, 1.0, 1.0e6, "hood.")
		var sp = h.get("spot_by_location", {})
		capuz["spot_by_location"] = sp.duplicate() if sp is Dictionary else {}
		capuz["hover_text"] = str(h.get("hover_text", "hood_hover"))
		capuz["night_choice"] = str(h.get("night_choice", "first_available"))
	var nn = d.get("nights", {})
	var ordem_bruta = d.get("night_order", [])
	if nn is Dictionary and ordem_bruta is Array:
		for id in ordem_bruta:
			var b = nn.get(str(id), null)
			if not (b is Dictionary):
				_aviso("night_order: noite '%s' não existe." % id)
				continue
			var n := _noite(str(id), b)
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
			_aviso("legend.levels inválido (precisa crescer): padrão 1/12/30/52/80.")
		var rc = lg.get("clipping_text_by_level", [])
		for x in (rc if rc is Array else []):
			recortes.append(str(x))
		camadas = (lg.get("street_layers_by_level", []) as Array).duplicate(true) if lg.get("street_layers_by_level", []) is Array else []
	vazio = ordem.is_empty()


func _noite(id: String, b: Dictionary) -> Dictionary:
	var kind := str(b.get("kind", ""))
	if not (kind in KINDS):
		_aviso("noite '%s' com kind desconhecido ('%s'): ignorada." % [id, kind])
		return {}
	var p := "nights.%s." % id
	var r := {"id": id, "kind": kind, "name": str(b.get("name", "")), "tip": str(b.get("tip", "")),
		"requires": (b.get("requires", {}) as Dictionary).duplicate() if b.get("requires", {}) is Dictionary else {},
		"countdown_s": _num(b, "countdown_s", 2.0, 0.0, 60.0, p), "night_s": _num(b, "night_s", 34.0, 1.0, 600.0, p),
		"intro_s": _num(b, "intro_s", 0.8, 0.0, 60.0, p), "advance_per_s": _num(b, "advance_per_s", 0.25, 0.01, 10.0, p),
		"scare_zone": _num(b, "scare_zone", 0.8, 0.0, 1.0, p), "grace_s": _num(b, "grace_s", 0.2, 0.0, 5.0, p),
		"scare_anim_s": _num(b, "scare_anim_s", 1.6, 0.0, 60.0, p), "seen_anim_s": _num(b, "seen_anim_s", 1.2, 0.0, 60.0, p)}
	var oc: Array = []
	var lista = b.get("occurrences", [])
	for item in (lista if lista is Array else []):
		if not (item is Dictionary) or str(item.get("id", "")) == "":
			continue
		var q := p + "occurrences."
		var a := _num(item, "gap_min", 2.0, 0.1, 60.0, q)
		var z := _num(item, "gap_max", 3.0, 0.1, 60.0, q)
		if a > z:
			var t := a
			a = z
			z = t
		oc.append({"id": str(item.id), "spot": str(item.get("spot", "")), "name": str(item.get("name", "")), "gap_min": a, "gap_max": z,
			"warn_s": _num(item, "warn_s", 0.8, 0.0, 10.0, q), "look_s": _num(item, "look_s", 1.2, 0.0, 10.0, q),
			"fake_warn": _num(item, "fake_warn", 0.0, 0.0, 1.0, q)})
	if oc.is_empty():
		_aviso("noite '%s' sem ocorrências: ignorada." % id)
		return {}
	r["occurrences"] = oc
	var lg = b.get("legend", {})
	r["legend"] = {"floor": int(_num(lg if lg is Dictionary else {}, "floor", 1.0, 0.0, 100.0, p + "legend.")),
		"per_scare": int(_num(lg if lg is Dictionary else {}, "per_scare", 1.0, 0.0, 100.0, p + "legend.")),
		"clean_bonus": int(_num(lg if lg is Dictionary else {}, "clean_bonus", 1.0, 0.0, 100.0, p + "legend."))}
	return r


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
