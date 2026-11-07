class_name GymData
extends RefCounted
## Fase 5: locais de treino (garagem, academia) e artes marciais, lidos de data/locations.json e data/arts.json.
## Mesma regra de sempre: campo faltando, tipo errado ou fora da faixa usa o padrão e avisa no console;
## item com id vazio ou repetido é ignorado.

const CAMINHO_LOCAIS := "res://data/locations.json"
const CAMINHO_ARTES := "res://data/arts.json"

const REGRAS: Array[String] = ["manual_click_bonus", "crew_time_bonus"]
const PADRAO_LOCAL := "garage"

var local_padrao := PADRAO_LOCAL
var locais: Array[Dictionary] = []
var artes: Array[Dictionary] = []


static func carregar(caminho_locais: String = CAMINHO_LOCAIS, caminho_artes: String = CAMINHO_ARTES) -> GymData:
	var d := GymData.new()
	d._ler_locais(TrainingData._ler_json(caminho_locais))
	d._ler_artes(TrainingData._ler_json(caminho_artes))
	return d


func local(id: String) -> Dictionary:
	for l in locais:
		if l.id == id:
			return l
	return {}


func arte(id: String) -> Dictionary:
	for a in artes:
		if a.id == id:
			return a
	return {}


func ids_artes() -> Array:
	var r: Array = []
	for a in artes:
		r.append(a.id)
	return r


## Local que se compra (o 1º com bloco `move`); {} se nenhum.
func destino_mudanca() -> Dictionary:
	for l in locais:
		if not l.move.is_empty():
			return l
	return {}


## Confere as artes contra os aparelhos do treino: arte cujo aparelho não existe (ou não é dela) fica sem aparelho.
func validar_aparelhos(dados: TrainingData) -> void:
	for a in artes:
		if a.apparatus == "":
			continue
		var ap := dados.aparelho(a.apparatus)
		if ap.is_empty() or str(ap.art) != a.id:
			push_warning("GymData: aparelho '%s' da arte '%s' não existe ou não tem art='%s': arte sem aparelho." % [a.apparatus, a.id, a.id])
			a["apparatus"] = ""


# --- Locais ---

func _ler_locais(dados: Dictionary) -> void:
	var lista = dados.get("locations", [])
	if not (lista is Array):
		lista = []
	var ids := {}
	for item in lista:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids.has(id):
			push_warning("GymData: local com id vazio ou repetido ('%s') ignorado." % id)
			continue
		ids[id] = true
		locais.append(_montar_local(item, id))
	if locais.is_empty():
		push_warning("GymData: nenhum local válido, usando só a garagem.")
		locais.append(_montar_local({"id": PADRAO_LOCAL}, PADRAO_LOCAL))
	var padrao := str(dados.get("default_location", PADRAO_LOCAL))
	if local(padrao).is_empty():
		if dados.has("default_location"):
			push_warning("GymData: default_location '%s' não existe, usando o 1º local." % padrao)
		padrao = str(locais[0].id)
	local_padrao = padrao


func _montar_local(item: Dictionary, id: String) -> Dictionary:
	var mult := 1.0
	if item.has("training_mult"):
		mult = TrainingData._num(item, "training_mult", 1.0, 1.0e-9, 1.0e6, id + ".")
		if mult <= 0.0:
			mult = 1.0
	var mv := {}
	var bruto = item.get("move", null)
	if bruto is Dictionary:
		var custo = bruto.get("cost", null)
		if (typeof(custo) != TYPE_FLOAT and typeof(custo) != TYPE_INT) or not is_finite(float(custo)) or float(custo) < 0.0:
			push_warning("GymData: move.cost inválido em '%s': o local não pode ser comprado." % id)
		else:
			if str(bruto.get("currency", "money")) != "money":
				push_warning("GymData: move.currency de '%s' deve ser 'money' (só $ nesta fase): usando 'money'." % id)
			if str(bruto.get("requires", "belt")) != "belt":
				push_warning("GymData: move.requires de '%s' deve ser 'belt': usando 'belt'." % id)
			var mid := str(bruto.get("id", ""))
			mv = {"id": mid if mid != "" else "move_" + id, "cost": float(custo), "currency": "money", "requires": "belt"}
	return {
		"id": id, "training_mult": mult,
		"apparatus_suffix": str(item.get("apparatus_suffix", "")),
		"move": mv,
		"name": TrainingData._txt(item, "name", id),
		"ambience": TrainingData._txt(item, "ambience", ""),
		"move_button": TrainingData._txt(item, "move_button", ""),
		"move_description": TrainingData._txt(item, "move_description", ""),
	}


# --- Artes ---

func _ler_artes(dados: Dictionary) -> void:
	var lista = dados.get("arts", [])
	if not (lista is Array):
		lista = []
	var ids := {}
	for item in lista:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids.has(id):
			push_warning("GymData: arte com id vazio ou repetido ('%s') ignorada." % id)
			continue
		ids[id] = true
		artes.append(_montar_arte(item, id))


func _montar_arte(item: Dictionary, id: String) -> Dictionary:
	var regra := {"type": ""}
	var r = item.get("rule", null)
	if r is Dictionary and str(r.get("type", "")) in REGRAS:
		regra["type"] = str(r.type)
		if r.type == "manual_click_bonus":
			regra["value"] = _recortar(r, "value", 0.0, 0.0, 5.0, id + ".rule.")
		else:
			regra["start"] = _recortar(r, "start", 0.0, 0.0, 10.0, id + ".rule.")
			regra["per_minute"] = _recortar(r, "per_minute", 0.0, 0.0, 1.0, id + ".rule.")
			regra["cap"] = _recortar(r, "cap", 0.0, 0.0, 10.0, id + ".rule.")
			if regra.start > regra.cap:
				push_warning("GymData: rule.start de '%s' maior que o teto: igualado." % id)
				regra["start"] = regra.cap
	else:
		push_warning("GymData: arte '%s' sem regra válida (rule.type): arte sem regra." % id)
	var luta := {"damage_mult": 1.0, "taken_mult": 1.0}
	var f = item.get("fight", null)
	if f is Dictionary:
		for chave in ["damage_mult", "taken_mult"]:
			if f.has(chave):
				luta[chave] = _recortar(f, chave, 1.0, 0.5, 2.0, id + ".fight.")
	return {
		"id": id, "apparatus": str(item.get("apparatus", "")), "rule": regra, "fight": luta,
		"name": TrainingData._txt(item, "name", id), "tagline": TrainingData._txt(item, "tagline", ""),
		"rule_text": TrainingData._txt(item, "rule_text", ""), "fight_text": TrainingData._txt(item, "fight_text", ""),
		"icon": TrainingData._txt(item, "icon", ""),
	}


# Número finito recortado para [minimo, maximo]; ausente ou inválido usa o padrão (com aviso).
static func _recortar(d: Dictionary, chave: String, padrao: float, minimo: float, maximo: float, prefixo: String) -> float:
	var v = d.get(chave, null)
	if (typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT) or not is_finite(float(v)):
		push_warning("GymData: '%s%s' ausente ou inválido, usando padrão %s." % [prefixo, chave, str(padrao)])
		return padrao
	var x := clampf(float(v), minimo, maximo)
	if x != float(v):
		push_warning("GymData: '%s%s' (%s) fora de [%s, %s]: recortado." % [prefixo, chave, str(v), str(minimo), str(maximo)])
	return x
