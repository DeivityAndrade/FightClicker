class_name TrainingData
extends RefCounted
## Definições da garagem lidas de data/*.json (clique, aparelhos, melhorias, geradores, textos).
## Campo faltando, com tipo errado ou fora da faixa usa o padrão e avisa no console.
## Campo desconhecido é ignorado. Item com id vazio ou repetido é ignorado.

const CAMINHO_TREINO := "res://data/training.json"
const CAMINHO_GERADORES := "res://data/generators.json"
const CAMINHO_TEXTOS := "res://data/ui_texts.json"

const ATRIBUTOS: Array[String] = ["strength", "agility", "endurance"]

# Padrões do design (usados se o arquivo faltar ou o campo for inválido).
const PADRAO_CLIQUE := {"base_training": 1.0, "crit_chance": 0.10, "crit_multiplier": 3.0}
const PADRAO_FOCO := "punching_bag"
const PADRAO_EVENTO := {"wait_min": 60.0, "wait_max": 100.0, "visible_seconds": 7.0, "frenzy_mult": 7.0, "frenzy_seconds": 6.0}
const PADRAO_CAIXA := {"clicks_to_open": 3, "open_seconds": 1.2, "shake_seconds": 0.15, "idle_wobble_every_seconds": 4.0}
const PADRAO_ASSIST :={"interval": 3.0, "still_seconds": 1.0, "first_delay": 1.0}
const PADRAO_APARELHOS := [
	{"id": "punching_bag", "attribute": "strength", "upgrades": [
		{"id": "bag_patch", "cost": 300, "multiplier": 3}, {"id": "bag_sand", "cost": 5000, "multiplier": 5}]},
	{"id": "jump_rope", "attribute": "agility", "upgrades": [
		{"id": "rope_laundry", "cost": 300, "multiplier": 3}, {"id": "rope_handles", "cost": 5000, "multiplier": 5}]},
	{"id": "treadmill", "attribute": "endurance", "upgrades": [
		{"id": "treadmill_oil", "cost": 300, "multiplier": 3}, {"id": "treadmill_belt", "cost": 5000, "multiplier": 5}]},
]
const PADRAO_GERADORES := [
	{"id": "neighbor_kid", "base_cost": 60, "growth": 1.25, "production": 1, "draw_thresholds": [1, 10, 25]},
	{"id": "retired_uncle", "base_cost": 2500, "growth": 1.25, "production": 8, "draw_thresholds": [1, 10]},
]

var base_training := 1.0
var crit_chance := 0.10
var crit_multiplier := 3.0
var default_focus := PADRAO_FOCO
var assist_interval := 3.0
var assist_still_seconds := 1.0
var assist_first_delay := 1.0
# Evento dourado (luva dourada): bloco "golden_event" de training.json
var golden_wait_min := 45.0
var golden_wait_max := 90.0
var golden_visible_seconds := 7.0
var golden_frenzy_mult := 7.0
var golden_frenzy_seconds := 12.0
# Fase 5.2: bolsa da torcida (variante do evento dourado). crew_chance 0 = só a luva x7 (jogo da 5.1).
var golden_crew_chance := 0.0
var golden_crew_seconds := 45.0
var golden_crew_floor_clicks := 40.0
var golden_frenzy_sprite := "event_golden_glove"
var golden_crew_sprite := "event_golden_crew"
# Fase 5.1: caixa de equipamento (bloco "box" de training.json)
var box_clicks_to_open := 3
var box_open_seconds := 1.2
var box_shake_px: Array = [1, 2, 3]
var box_shake_seconds := 0.15
var box_idle_wobble_every := 4.0
var box_apparatus := true  # applies_to.apparatus_unlock: false = aparelho novo instantâneo (Fase 5)
var box_glove := true  # applies_to.glove: false = luva instantânea
var box_focus_on_open := true
## Aparelhos de toda carreira (sem `art`), na ordem do arquivo. É o que a UI de hoje percorre.
var aparelhos: Array[Dictionary] = []
## Fase 5: aparelhos assinatura das artes (com `art`), na ordem do arquivo. Só existem na carreira dessa arte.
var aparelhos_arte: Array[Dictionary] = []
var geradores: Array[Dictionary] = []
var atributos: Array[String] = ATRIBUTOS.duplicate()
var ui: Dictionary = {}

var _atributo_info: Dictionary = {}


static func carregar(caminho_treino: String = CAMINHO_TREINO, caminho_geradores: String = CAMINHO_GERADORES,
		caminho_textos: String = CAMINHO_TEXTOS) -> TrainingData:
	var d := TrainingData.new()
	d._ler_treino(_ler_json(caminho_treino))
	d._ler_geradores(_ler_json(caminho_geradores))
	d.ui = _ler_json(caminho_textos)
	return d


## Qualquer aparelho (de toda carreira ou de arte) pelo id.
func aparelho(id: String) -> Dictionary:
	for a in aparelhos:
		if a.id == id:
			return a
	for a in aparelhos_arte:
		if a.id == id:
			return a
	return {}


## Todos os aparelhos: os de toda carreira e depois os de arte.
func todos_aparelhos() -> Array[Dictionary]:
	var r: Array[Dictionary] = aparelhos.duplicate()
	r.append_array(aparelhos_arte)
	return r


func gerador(id: String) -> Dictionary:
	for g in geradores:
		if g.id == id:
			return g
	return {}


func atributo_info(id: String) -> Dictionary:
	return _atributo_info.get(id, {"name": id, "hint": ""})


# --- Leitura ---

static func _ler_json(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		push_warning("TrainingData: '%s' não encontrado, usando padrões." % caminho)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(caminho)) != OK or not (json.data is Dictionary):
		push_warning("TrainingData: '%s' com JSON inválido, usando padrões." % caminho)
		return {}
	return json.data


func _ler_treino(dados: Dictionary) -> void:
	var clique = dados.get("click", {})
	if not (clique is Dictionary):
		clique = {}
	base_training = _num(clique, "base_training", PADRAO_CLIQUE.base_training, 1.0e-12, 1.0e300, "click.")
	crit_chance = _num(clique, "crit_chance", PADRAO_CLIQUE.crit_chance, 0.0, 1.0, "click.")
	crit_multiplier = _num(clique, "crit_multiplier", PADRAO_CLIQUE.crit_multiplier, 1.0, 1.0e300, "click.")

	# Textos dos atributos.
	var attrs = dados.get("attributes", {})
	for id in ATRIBUTOS:
		var info = attrs.get(id, {}) if attrs is Dictionary else {}
		if not (info is Dictionary):
			info = {}
		_atributo_info[id] = {"name": _txt(info, "name", id), "hint": _txt(info, "hint", "")}

	# Aparelhos e melhorias.
	var lista = dados.get("apparatus", [])
	if not (lista is Array):
		lista = []
	var ids_aparelho := {}
	var ids_melhoria := {}
	for item in lista:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids_aparelho.has(id):
			push_warning("TrainingData: aparelho com id vazio ou repetido ('%s') ignorado." % id)
			continue
		var attr := str(item.get("attribute", ""))
		# Fase 5: `split` (treina os 3 atributos numa proporção) no lugar de `attribute`.
		var split := _ler_split(item.get("split", null), id)
		if split.is_empty() and not (attr in ATRIBUTOS):
			push_warning("TrainingData: aparelho '%s' sem atributo nem split válido ignorado." % id)
			continue
		ids_aparelho[id] = true
		var ap := _montar_aparelho(item, id, attr, ids_melhoria, split)
		if str(ap.art) != "":
			aparelhos_arte.append(ap)
		else:
			aparelhos.append(ap)
	if aparelhos.is_empty():
		push_warning("TrainingData: nenhum aparelho válido, usando os padrões.")
		for item in PADRAO_APARELHOS:
			aparelhos.append(_montar_aparelho(item, item.id, item.attribute, {}))

	# Fase 4b: desbloqueios (depois de ler todos, para validar `requires`) e foco inicial sem trava.
	_validar_desbloqueios(lista)

	# Foco inicial (nunca um aparelho de arte: ele só existe em carreira com arte).
	var foco := str(dados.get("default_focus", PADRAO_FOCO))
	if aparelho(foco).is_empty() or str(aparelho(foco).art) != "":
		if dados.has("default_focus"):
			push_warning("TrainingData: default_focus '%s' não existe ou é de arte, usando o padrão." % foco)
		foco = PADRAO_FOCO if not aparelhos.filter(func(a): return a.id == PADRAO_FOCO).is_empty() else aparelhos[0].id
	if not aparelho(foco).get("unlock", {}).is_empty():
		push_warning("TrainingData: default_focus '%s' tem unlock: o unlock foi ignorado." % foco)
		aparelho(foco)["unlock"] = {}
	default_focus = foco
	_ler_assist(dados.get("assist", null))
	_ler_evento_dourado(dados.get("golden_event", null))
	_ler_caixa(dados.get("box", null))


# Fase 4b: ritmo do modo assistido. O intervalo ainda é comparado com o Metrônomo 1 no GameState.
func _ler_assist(v: Variant) -> void:
	var a: Dictionary = v if v is Dictionary else {}
	if v == null or not (v is Dictionary):
		push_warning("TrainingData: bloco 'assist' ausente, usando padrões.")
	assist_interval = _num(a, "interval", PADRAO_ASSIST.interval, 0.5, 60.0, "assist.")
	assist_still_seconds = _num(a, "still_seconds", PADRAO_ASSIST.still_seconds, 0.0, 10.0, "assist.")
	assist_first_delay = _num(a, "first_delay", PADRAO_ASSIST.first_delay, 0.0, assist_interval, "assist.")


# Luva dourada: espera entre eventos, tempo na tela, multiplicador e duração do frenesi.
func _ler_evento_dourado(v: Variant) -> void:
	var e: Dictionary = v if v is Dictionary else {}
	if not (v is Dictionary):
		push_warning("TrainingData: bloco 'golden_event' ausente, usando padrões.")
	golden_wait_min = _num(e, "wait_min", PADRAO_EVENTO.wait_min, 1.0, 3600.0, "golden_event.")
	golden_wait_max = _num(e, "wait_max", PADRAO_EVENTO.wait_max, 1.0, 3600.0, "golden_event.")
	golden_visible_seconds = _num(e, "visible_seconds", PADRAO_EVENTO.visible_seconds, 1.0, 60.0, "golden_event.")
	golden_frenzy_mult = _num(e, "frenzy_mult", PADRAO_EVENTO.frenzy_mult, 1.0, 1000.0, "golden_event.")
	golden_frenzy_seconds = _num(e, "frenzy_seconds", PADRAO_EVENTO.frenzy_seconds, 1.0, 600.0, "golden_event.")
	golden_crew_chance = _num(e, "crew_chance", 0.0, 0.0, 1.0, "golden_event.")
	golden_crew_seconds = _num(e, "crew_seconds", 45.0, 1.0, 3600.0, "golden_event.")
	golden_crew_floor_clicks = _num(e, "crew_floor_clicks", 40.0, 0.0, 100000.0, "golden_event.")
	golden_frenzy_sprite = _txt(e, "frenzy_sprite", "event_golden_glove")
	golden_crew_sprite = _txt(e, "crew_sprite", "event_golden_crew")
	if golden_wait_max < golden_wait_min:
		push_warning("TrainingData: golden_event.wait_max < wait_min; usando os padrões de espera.")
		golden_wait_min = PADRAO_EVENTO.wait_min
		golden_wait_max = PADRAO_EVENTO.wait_max


# Preenche aparelho.unlock = {id, cost, requires, name, description, arrives_as} ou {} (sempre montado).
func _validar_desbloqueios(lista: Array) -> void:
	var ids_unlock := {}
	var brutos := {}
	for item in lista:
		if item is Dictionary:
			brutos[str(item.get("id", ""))] = item
	for ap in todos_aparelhos():
		ap["unlock"] = {}
		var bruto: Dictionary = brutos.get(ap.id, {})
		if not bruto.has("unlock"):
			continue
		var u = bruto.unlock
		if not (u is Dictionary):
			push_warning("TrainingData: unlock de '%s' não é objeto, ignorado." % ap.id)
			continue
		var custo = u.get("cost", null)
		if (typeof(custo) != TYPE_FLOAT and typeof(custo) != TYPE_INT) or not is_finite(float(custo)) or float(custo) < 1.0:
			push_warning("TrainingData: unlock.cost inválido em '%s': aparelho fica sem trava." % ap.id)
			continue
		var uid := str(u.get("id", ""))
		if uid.is_empty() or ids_unlock.has(uid):
			if not uid.is_empty():
				push_warning("TrainingData: unlock.id repetido ('%s'), usando o padrão." % uid)
			uid = "unlock_" + ap.id
		ids_unlock[uid] = true
		ap["unlock"] = {"id": uid, "cost": float(custo), "requires": str(u.get("requires", "")),
			"name": _txt(u, "name", ap.name), "description": _txt(u, "description", ""),
			"arrives_as": _txt(u, "arrives_as", "")}
	# `requires`: precisa existir, não ser ele mesmo e não formar ciclo.
	for ap in todos_aparelhos():
		if ap.unlock.is_empty():
			continue
		var req: String = ap.unlock.requires
		if req.is_empty():
			continue
		var ruim: bool = req == ap.id or aparelho(req).is_empty()
		var atual := req
		var passos := 0
		while not ruim and not atual.is_empty() and passos <= aparelhos.size() + aparelhos_arte.size():
			var prox: Dictionary = aparelho(atual).get("unlock", {})
			atual = str(prox.get("requires", ""))
			if atual == ap.id:
				ruim = true
			passos += 1
		if ruim:
			push_warning("TrainingData: unlock.requires '%s' de '%s' inválido (inexistente, próprio ou ciclo): vira ''." % [req, ap.id])
			ap.unlock["requires"] = ""


# Fase 5: {strength, agility, endurance} -> fração (soma 1). {} se ausente ou inválido; soma != 1 normaliza com aviso.
func _ler_split(v: Variant, id: String) -> Dictionary:
	if not (v is Dictionary):
		return {}
	var s := {}
	var soma := 0.0
	for a in ATRIBUTOS:
		var x = v.get(a, 0.0)
		if (typeof(x) != TYPE_FLOAT and typeof(x) != TYPE_INT) or not is_finite(float(x)) or float(x) < 0.0:
			push_warning("TrainingData: split de '%s' inválido (%s): ignorado." % [id, a])
			return {}
		s[a] = float(x)
		soma += float(x)
	if soma <= 0.0:
		push_warning("TrainingData: split de '%s' soma 0: ignorado." % id)
		return {}
	if absf(soma - 1.0) > 1.0e-9:
		push_warning("TrainingData: split de '%s' soma %s: normalizado para 1." % [id, str(soma)])
		for a in ATRIBUTOS:
			s[a] = s[a] / soma
	return s


func _montar_aparelho(item: Dictionary, id: String, attr: String, ids_melhoria: Dictionary, split: Dictionary = {}) -> Dictionary:
	if split.is_empty():
		split = {attr: 1.0}
	else:
		# `attribute` = o atributo de maior fatia (a UI de hoje usa para cor e ícone); empate: o primeiro.
		var melhor := ""
		for a in ATRIBUTOS:
			if split.get(a, 0.0) > 0.0 and (melhor == "" or split[a] > split[melhor]):
				melhor = a
		attr = melhor
	var rotulo = item.get("focus_label", [])
	if not (rotulo is Array) or rotulo.size() < 2:
		rotulo = [str(_atributo_info.get(attr, {}).get("name", attr)).to_upper(), id.to_upper()]
	var crit = item.get("crit_texts", [])
	var crit_ok: Array[String] = []
	if crit is Array:
		for c in crit:
			crit_ok.append(str(c))
	if crit_ok.is_empty():
		crit_ok.append("CRÍTICO!")
	var melhorias: Array[Dictionary] = []
	var lista = item.get("upgrades", [])
	if lista is Array:
		for m in lista:
			if not (m is Dictionary):
				continue
			var mid := str(m.get("id", ""))
			if mid.is_empty() or ids_melhoria.has(mid):
				push_warning("TrainingData: melhoria com id vazio ou repetido ('%s') ignorada." % mid)
				continue
			ids_melhoria[mid] = true
			melhorias.append(_montar_melhoria(m, mid))
	return {
		"id": id,
		"attribute": attr,
		"split": split,
		"art": _txt(item, "art", ""),
		"name": _txt(item, "name", id),
		"focus_label": [str(rotulo[0]), str(rotulo[1])],
		"first_hint": _txt(item, "first_hint", ""),
		"crit_texts": crit_ok,
		"upgrades": melhorias,
	}


func _montar_melhoria(m: Dictionary, mid: String) -> Dictionary:
	var pad := _padrao_melhoria(mid)
	var visual := 0
	if m.has("visual_level"):
		var v = m.visual_level
		if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and (float(v) == 0.0 or float(v) == 1.0):
			visual = int(v)
		else:
			push_warning("TrainingData: visual_level inválido em '%s', usando 0." % mid)
	return {
		"id": mid,
		"cost": _num(m, "cost", pad.cost, 1.0e-12, 1.0e300, mid + "."),
		"multiplier": _num(m, "multiplier", pad.multiplier, 1.0, 1.0e300, mid + "."),
		"visual_level": visual,
		"name": _txt(m, "name", mid),
		"description": _txt(m, "description", ""),
	}


func _padrao_melhoria(mid: String) -> Dictionary:
	for a in PADRAO_APARELHOS:
		for m in a.upgrades:
			if m.id == mid:
				return m
	return {"cost": 300.0, "multiplier": 3.0}


func _ler_geradores(dados: Dictionary) -> void:
	var lista = dados.get("generators", [])
	if not (lista is Array):
		lista = []
	var ids := {}
	for item in lista:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids.has(id):
			push_warning("TrainingData: gerador com id vazio ou repetido ('%s') ignorado." % id)
			continue
		ids[id] = true
		geradores.append(_montar_gerador(item, id))
	if geradores.is_empty():
		push_warning("TrainingData: nenhum gerador válido, usando os padrões.")
		for item in PADRAO_GERADORES:
			geradores.append(_montar_gerador(item, item.id))


func _montar_gerador(item: Dictionary, id: String) -> Dictionary:
	var pad := {"base_cost": 60.0, "growth": 1.25, "production": 1.0}
	for p in PADRAO_GERADORES:
		if p.id == id:
			pad = p
	return {
		"id": id,
		"base_cost": _num(item, "base_cost", pad.base_cost, 1.0e-12, 1.0e300, id + "."),
		"growth": _num(item, "growth", pad.growth, 1.0, 10.0, id + "."),
		"production": _num(item, "production", pad.production, 0.0, 1.0e300, id + "."),
		"draw_thresholds": _limites(item.get("draw_thresholds", [1]), id),
		"name": _txt(item, "name", id),
		"description": _txt(item, "description", ""),
		"appears_as": _txt(item, "appears_as", ""),
	}


# Lista de inteiros crescente, cada um >= 1. Senão [1].
func _limites(v: Variant, id: String) -> Array[int]:
	var saida: Array[int] = []
	var ok: bool = v is Array and not v.is_empty()
	if ok:
		var anterior := 0
		for x in v:
			if (typeof(x) != TYPE_FLOAT and typeof(x) != TYPE_INT) or float(x) != floorf(float(x)) \
					or int(x) <= anterior:
				ok = false
				break
			anterior = int(x)
			saida.append(anterior)
	if not ok:
		push_warning("TrainingData: draw_thresholds inválido em '%s', usando [1]." % id)
		return [1]
	return saida


# --- Auxiliares ---

# Número finito dentro de [minimo, maximo]; senão o padrão, com aviso.
static func _num(d: Dictionary, chave: String, padrao: float, minimo: float, maximo: float, prefixo: String) -> float:
	if not d.has(chave):
		push_warning("TrainingData: '%s%s' ausente, usando padrão %s." % [prefixo, chave, str(padrao)])
		return float(padrao)
	var v = d[chave]
	if (typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT) or not is_finite(float(v)) \
			or float(v) < minimo or float(v) > maximo:
		push_warning("TrainingData: valor inválido em '%s%s' (%s), usando padrão %s." % [prefixo, chave, str(v), str(padrao)])
		return float(padrao)
	return float(v)


static func _txt(d: Dictionary, chave: String, padrao: String) -> String:
	var v = d.get(chave, null)
	return v if v is String and not (v as String).is_empty() else padrao


# Fase 5.1: caixa de equipamento. Bloco ausente = padrões (caixa ligada para aparelho e luva).
func _ler_caixa(v: Variant) -> void:
	var b: Dictionary = v if v is Dictionary else {}
	if not (v is Dictionary):
		push_warning("TrainingData: bloco 'box' ausente, usando padrões.")
	box_clicks_to_open = int(_num(b, "clicks_to_open", PADRAO_CAIXA.clicks_to_open, 1.0, 20.0, "box."))
	box_open_seconds = _num(b, "open_seconds", PADRAO_CAIXA.open_seconds, 0.1, 5.0, "box.")
	box_shake_seconds = _num(b, "shake_seconds", PADRAO_CAIXA.shake_seconds, 0.01, 2.0, "box.")
	box_idle_wobble_every = _num(b, "idle_wobble_every_seconds", PADRAO_CAIXA.idle_wobble_every_seconds, 0.5, 60.0, "box.")
	box_shake_px = []
	var px = b.get("shake_px", null)
	if px is Array:
		for x in px:
			if (typeof(x) == TYPE_FLOAT or typeof(x) == TYPE_INT) and is_finite(float(x)) and float(x) >= 0.0:
				box_shake_px.append(int(x))
	if box_shake_px.is_empty():
		box_shake_px = [1, 2, 3]
	var ap = b.get("applies_to", {})
	if not (ap is Dictionary):
		ap = {}
	box_apparatus = ap.get("apparatus_unlock", true) != false
	box_glove = ap.get("glove", true) != false
	box_focus_on_open = b.get("focus_on_open", true) != false
