class_name FightData
extends RefCounted
## Definições da Fase 3 lidas de data/*.json: combate, táticas, risco, adversários, loja e Legado.
## Mesma regra da Fase 2: campo faltando, tipo errado ou fora da faixa usa o padrão e avisa no console;
## campo desconhecido é ignorado; item com id vazio ou repetido é ignorado.

const CAMINHO_LUTAS := "res://data/fights.json"
const CAMINHO_ADVERSARIOS := "res://data/opponents.json"
const CAMINHO_LOJA := "res://data/shop.json"
const CAMINHO_CARREIRA := "res://data/career.json"
const CAMINHO_ARVORE := "res://data/skill_tree.json"

# Tipos de efeito da árvore (Fase 4). Tipo desconhecido: nó ignorado.
const TIPOS_EFEITO := ["click_bonus", "passive_bonus", "money_bonus", "fame_bonus", "defeat_share_bonus", "metronome_start", "preview_percent", "art_rule_bonus"]
# Intervalo mínimo do Metrônomo (garante <= 1,5 soco/s mesmo com dado errado) e máximo.
const METRONOMO_INTERVALO_MIN := 0.667
const METRONOMO_INTERVALO_MAX := 60.0

# chave -> [padrão, mínimo, máximo]
const PADRAO_COMBATE := {
	"general_share": [0.10, 0.0, 1.0],
	"life_base": [100.0, 0.0, 1.0e12], "life_per_endurance": [5.0, 0.0, 1.0e12],
	"damage_base": [10.0, 0.0, 1.0e12], "damage_per_strength": [1.0, 0.0, 1.0e12],
	"reduction_max": [0.5, 0.0, 1.0],
	"crit_base": [0.05, 0.0, 1.0], "crit_gain": [0.50, 0.0, 1.0], "crit_multiplier": [2.0, 0.0, 1.0e6],
	"dodge_base": [0.03, 0.0, 1.0], "dodge_gain": [0.50, 0.0, 1.0], "dodge_cap": [0.75, 0.0, 1.0],
	"damage_spread": [0.15, 0.0, 1.0],
	"first_attack": [0.9, 0.0, 1.0e6], "attack_interval": [1.8, 0.001, 1.0e6], "counter_delay": [0.5, 0.0, 1.0e6],
	"time_limit": [16.0, 0.0, 1.0e6], "min_ko_time": [5.0, 0.0, 1.0e6], "round_length": [6.0, 0.001, 1.0e6],
	"intro_seconds": [1.5, 0.0, 1.0e6], "outro_seconds": [1.5, 0.0, 1.0e6],
}
const PADRAO_TATICAS := [
	{"id": "aggressive", "damage_mult": 1.35, "taken_mult": 1.25, "pierce": 0.5, "counter_mult": 0.0, "crit_guard": 0.0},
	{"id": "defensive", "damage_mult": 0.85, "taken_mult": 0.85, "crit_guard": 1.0, "block": true},
	{"id": "counter", "damage_mult": 0.90, "dodge_mult": 2.0, "counter_mult": 1.0},
]
const PADRAO_TATICA := "defensive"
const PADRAO_ADVERSARIOS := [
	{"id": "opp_warmup", "strength": 1200, "agility": 100, "endurance": 800, "prize_money": 50, "prize_fame": 10, "belt": false},
	{"id": "opp_strong", "strength": 27000, "agility": 1400, "endurance": 5400, "prize_money": 150, "prize_fame": 30, "belt": false},
	{"id": "opp_fast", "strength": 20000, "agility": 110000, "endurance": 6000, "prize_money": 800, "prize_fame": 60, "belt": false},
	{"id": "opp_tank", "strength": 78000, "agility": 58000, "endurance": 490000, "prize_money": 1000, "prize_fame": 100, "belt": true},
]
const PADRAO_GERADORES_PAGOS := [
	{"id": "gen_paid_1", "base_cost": 50, "growth": 1.6, "production": 25, "draw_thresholds": [1, 4]},
]
const PADRAO_LUVAS := [
	{"id": "glove_l1", "cost": 120, "click_multiplier": 2},
	{"id": "glove_l2", "cost": 500, "click_multiplier": 2},
]
const PADRAO_CARREIRA := {"legacy_per_fame": 2.0, "belt_legacy_bonus": 100, "defeat_share": 0.5,
	"retire_share": 1.0, "retire_belt_bonus_share": 0.5}

var combate: Dictionary = {}
var taticas: Array[Dictionary] = []
var tatica_padrao := PADRAO_TATICA
var risco: Dictionary = {}
var motivo: Dictionary = {}
var adversarios: Array[Dictionary] = []
var geradores_pagos: Array[Dictionary] = []
var luva_id := "glove_shop"
var luva_base: Dictionary = {}
var luvas: Array[Dictionary] = []
var carreira: Dictionary = {}
# Fase 4
var ramos: Array[Dictionary] = []  # {id, name}
var arvore: Array[Dictionary] = []  # nós válidos, na ordem do arquivo
var metronomo: Dictionary = {}  # {id, name, description, appears_as, levels: [...]} (levels vazio = sem Metrônomo)


static func carregar(caminho_lutas: String = CAMINHO_LUTAS, caminho_adversarios: String = CAMINHO_ADVERSARIOS,
		caminho_loja: String = CAMINHO_LOJA, caminho_carreira: String = CAMINHO_CARREIRA, caminho_arvore: String = CAMINHO_ARVORE) -> FightData:
	var d := FightData.new()
	d._ler_lutas(TrainingData._ler_json(caminho_lutas))
	d._ler_adversarios(TrainingData._ler_json(caminho_adversarios))
	d._ler_loja(TrainingData._ler_json(caminho_loja))
	d._ler_carreira(TrainingData._ler_json(caminho_carreira))
	d._ler_arvore(TrainingData._ler_json(caminho_arvore))
	return d


func tatica(id: String) -> Dictionary:
	for t in taticas:
		if t.id == id:
			return t
	return {}


func adversario(id: String) -> Dictionary:
	for a in adversarios:
		if a.id == id:
			return a
	return {}


## Índice do adversário que dá o cinturão (o 1º com `belt`), -1 se nenhum. Cinturão = a escada passou dele.
func indice_cinturao() -> int:
	for i in adversarios.size():
		if adversarios[i].belt:
			return i
	return -1


## Índice do 1º adversário que só luta em `local_id` (ex.: "gym"), -1 se nenhum.
func indice_primeiro_do_local(local_id: String) -> int:
	for i in adversarios.size():
		if adversarios[i].location == local_id:
			return i
	return -1


func indice_adversario(id: String) -> int:
	for i in adversarios.size():
		if adversarios[i].id == id:
			return i
	return -1


func gerador_pago(id: String) -> Dictionary:
	for g in geradores_pagos:
		if g.id == id:
			return g
	return {}


# --- Combate, táticas, risco, motivo ---

func _ler_lutas(dados: Dictionary) -> void:
	var c = dados.get("combat", {})
	if not (c is Dictionary):
		c = {}
	for chave in PADRAO_COMBATE:
		var p: Array = PADRAO_COMBATE[chave]
		combate[chave] = TrainingData._num(c, chave, p[0], p[1], p[2], "combat.")
	# Relações entre campos: se quebrarem, o bloco volta aos padrões.
	if not (combate.time_limit > combate.min_ko_time and combate.min_ko_time > 0.0):
		push_warning("FightData: time_limit deve ser > min_ko_time > 0; usando os padrões de tempo.")
		combate.time_limit = PADRAO_COMBATE.time_limit[0]
		combate.min_ko_time = PADRAO_COMBATE.min_ko_time[0]

	var lista = dados.get("tactics", [])
	if not (lista is Array):
		lista = []
	var ids := {}
	for item in lista:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids.has(id):
			push_warning("FightData: tática com id vazio ou repetido ('%s') ignorada." % id)
			continue
		ids[id] = true
		taticas.append(_montar_tatica(item, id))
	if taticas.is_empty():
		push_warning("FightData: nenhuma tática válida, usando as padrões.")
		for item in PADRAO_TATICAS:
			taticas.append(_montar_tatica(item, item.id))

	var padrao := str(dados.get("default_tactic", PADRAO_TATICA))
	if tatica(padrao).is_empty():
		if dados.has("default_tactic"):
			push_warning("FightData: default_tactic '%s' não existe, usando o padrão." % padrao)
		padrao = PADRAO_TATICA if not tatica(PADRAO_TATICA).is_empty() else taticas[0].id
	tatica_padrao = padrao

	var r = dados.get("risk", {})
	if not (r is Dictionary):
		r = {}
	risco = {
		"samples": int(_inteiro_faixa(r, "samples", 200, 20, 2000, "risk.")),
		"easy_min": TrainingData._num(r, "easy_min", 0.90, 0.0, 1.0, "risk."),
		"even_min": TrainingData._num(r, "even_min", 0.40, 0.0, 1.0, "risk."),
		"hud_refresh_seconds": TrainingData._num(r, "hud_refresh_seconds", 1.0, 0.05, 3600.0, "risk."),
	}
	if risco.easy_min <= risco.even_min:
		push_warning("FightData: risk.easy_min deve ser > risk.even_min; usando 0.90 / 0.40.")
		risco.easy_min = 0.90
		risco.even_min = 0.40

	var m = dados.get("reason", {})
	if not (m is Dictionary):
		m = {}
	motivo = {
		"delta_share": TrainingData._num(m, "delta_share", 0.25, 0.0, 1.0e6, "reason."),
		"delta_min": TrainingData._num(m, "delta_min", 10.0, 0.0, 1.0e12, "reason."),
		"target": TrainingData._num(m, "target", 0.90, 0.0, 1.0, "reason."),
		"search_steps": int(_inteiro_faixa(m, "search_steps", 14, 1, 40, "reason.")),
		"search_max_share": TrainingData._num(m, "search_max_share", 16.0, 0.0, 1.0e6, "reason."),
		"tactic_tip_gap": TrainingData._num(m, "tactic_tip_gap", 0.25, 0.0, 1.0, "reason."),
		"lead_ratio": TrainingData._num(m, "lead_ratio", 2.0, 1.0, 1.0e6, "reason."),
		# Pós-QA (design §16.5)
		"search_opp_share": TrainingData._num(m, "search_opp_share", 4.0, 0.0, 1.0e6, "reason."),
		"luck_min": TrainingData._num(m, "luck_min", 0.90, 0.0, 1.0, "reason."),
		"far_min_ratio": TrainingData._num(m, "far_min_ratio", 2.0, 1.0, 1.0e9, "reason."),
		"stat_life_min_pct": TrainingData._num(m, "stat_life_min_pct", 10.0, 0.0, 100.0, "reason."),
		"stat_stronger_min_ratio": TrainingData._num(m, "stat_stronger_min_ratio", 1.2, 1.0, 1.0e9, "reason."),
		"stat_stronger_x_ratio": TrainingData._num(m, "stat_stronger_x_ratio", 2.0, 1.0, 1.0e9, "reason."),
		"stat_stronger_cap_ratio": TrainingData._num(m, "stat_stronger_cap_ratio", 10.0, 1.0, 1.0e9, "reason."),
		"stat_dodge_min_pct": TrainingData._num(m, "stat_dodge_min_pct", 20.0, 0.0, 100.0, "reason."),
		"stat_dodge_min_attacks": TrainingData._num(m, "stat_dodge_min_attacks", 3.0, 0.0, 1000.0, "reason."),
		"stat_crits_min": TrainingData._num(m, "stat_crits_min", 2.0, 0.0, 1000.0, "reason."),
	}


func _montar_tatica(item: Dictionary, id: String) -> Dictionary:
	var t := {"id": id, "name": TrainingData._txt(item, "name", id.to_upper()), "hint": TrainingData._txt(item, "hint", "")}
	for chave in ["damage_mult", "taken_mult", "dodge_mult"]:
		t[chave] = _opcional(item, chave, 1.0, 0.0, 1.0e6, id)
	t["counter_mult"] = _opcional(item, "counter_mult", 0.0, 0.0, 1.0e6, id)
	for chave in ["pierce", "crit_guard", "dodge_bonus"]:
		t[chave] = _opcional(item, chave, 0.0, 0.0, 1.0, id)
	t["block"] = item.get("block", false) == true
	return t


# Campo opcional de tática: ausente usa o padrão em silêncio; inválido avisa.
func _opcional(d: Dictionary, chave: String, padrao: float, minimo: float, maximo: float, id: String) -> float:
	if not d.has(chave):
		return padrao
	return TrainingData._num(d, chave, padrao, minimo, maximo, id + ".")


static func _inteiro_faixa(d: Dictionary, chave: String, padrao: int, minimo: int, maximo: int, prefixo: String) -> float:
	var v := TrainingData._num(d, chave, float(padrao), float(minimo), float(maximo), prefixo)
	if v != floorf(v):
		push_warning("FightData: '%s%s' deve ser inteiro, usando %d." % [prefixo, chave, padrao])
		return float(padrao)
	return v


# --- Adversários ---

func _ler_adversarios(dados: Dictionary) -> void:
	var lista = dados.get("opponents", [])
	if not (lista is Array):
		lista = []
	var ids := {}
	for item in lista:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids.has(id):
			push_warning("FightData: adversário com id vazio ou repetido ('%s') ignorado." % id)
			continue
		ids[id] = true
		adversarios.append(_montar_adversario(item, id, _padrao_adversario(id)))
	_avisar_ordem_de_locais()
	if adversarios.is_empty():
		push_warning("FightData: nenhum adversário válido, usando os padrões.")
		for item in PADRAO_ADVERSARIOS:
			adversarios.append(_montar_adversario(item, item.id, item))


# Fase 5: adversário de outro local antes de um da garagem trava a escada na garagem.
func _avisar_ordem_de_locais() -> void:
	var viu_outro := false
	for a in adversarios:
		if a.location != "garage":
			viu_outro = true
		elif viu_outro:
			push_warning("FightData: adversário da garagem ('%s') depois de um de outro local: a escada fica travada." % a.id)


func _padrao_adversario(id: String) -> Dictionary:
	for p in PADRAO_ADVERSARIOS:
		if p.id == id:
			return p
	return {"strength": 0, "agility": 0, "endurance": 0, "prize_money": 0, "prize_fame": 0}


func _montar_adversario(item: Dictionary, id: String, pad: Dictionary) -> Dictionary:
	var a := {"id": id}
	for chave in ["strength", "agility", "endurance", "prize_money", "prize_fame"]:
		a[chave] = TrainingData._num(item, chave, float(pad.get(chave, 0)), 0.0, 1.0e300, id + ".")
	a["belt"] = item.get("belt", false) == true
	a["location"] = TrainingData._txt(item, "location", "garage")  # Fase 5: onde ele luta; ausente = garagem
	for chave in ["name", "description", "profile", "entry", "wins_line", "loses_line"]:
		a[chave] = TrainingData._txt(item, chave, id if chave == "name" else "")
	return a


# --- Loja ---

func _ler_loja(dados: Dictionary) -> void:
	var lista = dados.get("paid_generators", [])
	if not (lista is Array):
		lista = []
	var ids := {}
	for item in lista:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids.has(id):
			push_warning("FightData: gerador pago com id vazio ou repetido ('%s') ignorado." % id)
			continue
		ids[id] = true
		geradores_pagos.append(_montar_gerador_pago(item, id))
	if geradores_pagos.is_empty():
		push_warning("FightData: nenhum gerador pago válido, usando os padrões.")
		for item in PADRAO_GERADORES_PAGOS:
			geradores_pagos.append(_montar_gerador_pago(item, item.id))

	var g = dados.get("gloves", {})
	if not (g is Dictionary):
		g = {}
	luva_id = TrainingData._txt(g, "id", "glove_shop")
	var base = g.get("base", {})
	if not (base is Dictionary):
		base = {}
	luva_base = {"id": TrainingData._txt(base, "id", "glove_old"), "name": TrainingData._txt(base, "name", "Luva velha"),
		"sprite_suffix": str(base.get("sprite_suffix", "")), "click_multiplier": 1.0, "cost": 0.0, "level": 0,
		"description": TrainingData._txt(base, "description", "")}
	var niveis = g.get("levels", [])
	if not (niveis is Array):
		niveis = []
	var ids_luva := {}
	for item in niveis:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids_luva.has(id):
			push_warning("FightData: luva com id vazio ou repetido ('%s') ignorada." % id)
			continue
		ids_luva[id] = true
		luvas.append(_montar_luva(item, id, luvas.size() + 1, _padrao_luva(id)))
	if luvas.is_empty():
		push_warning("FightData: nenhuma luva válida, usando as padrões.")
		for item in PADRAO_LUVAS:
			luvas.append(_montar_luva(item, item.id, luvas.size() + 1, item))
	_ler_metronomo(dados.get("metronome", {}))


func _padrao_luva(id: String) -> Dictionary:
	for p in PADRAO_LUVAS:
		if p.id == id:
			return p
	return {"cost": 120.0, "click_multiplier": 2.0}


func _montar_luva(item: Dictionary, id: String, nivel: int, pad: Dictionary) -> Dictionary:
	return {
		"id": id, "level": nivel,
		"cost": TrainingData._num(item, "cost", float(pad.cost), 1.0e-12, 1.0e300, id + "."),
		"click_multiplier": TrainingData._num(item, "click_multiplier", float(pad.click_multiplier), 1.0, 1.0e300, id + "."),
		"sprite_suffix": str(item.get("sprite_suffix", "")),
		"name": TrainingData._txt(item, "name", id), "description": TrainingData._txt(item, "description", ""),
	}


func _montar_gerador_pago(item: Dictionary, id: String) -> Dictionary:
	var pad := {"base_cost": 50.0, "growth": 1.6, "production": 25.0}
	for p in PADRAO_GERADORES_PAGOS:
		if p.id == id:
			pad = p
	var limites: Array[int] = []
	var ok: bool = item.get("draw_thresholds", [1]) is Array and not item.get("draw_thresholds", [1]).is_empty()
	if ok:
		var anterior := 0
		for x in item.get("draw_thresholds", [1]):
			if (typeof(x) != TYPE_FLOAT and typeof(x) != TYPE_INT) or float(x) != floorf(float(x)) or int(x) <= anterior:
				ok = false
				break
			anterior = int(x)
			limites.append(anterior)
	if not ok:
		push_warning("FightData: draw_thresholds inválido em '%s', usando [1]." % id)
		limites = [1]
	return {
		"id": id,
		"base_cost": TrainingData._num(item, "base_cost", float(pad.base_cost), 1.0e-12, 1.0e300, id + "."),
		"growth": TrainingData._num(item, "growth", float(pad.growth), 1.0, 10.0, id + "."),
		"production": TrainingData._num(item, "production", float(pad.production), 0.0, 1.0e300, id + "."),
		"draw_thresholds": limites,
		"name": TrainingData._txt(item, "name", id),
		"description": TrainingData._txt(item, "description", ""),
		"appears_as": TrainingData._txt(item, "appears_as", ""),
	}


# --- Legado ---

func _ler_carreira(dados: Dictionary) -> void:
	carreira = {
		"legacy_per_fame": TrainingData._num(dados, "legacy_per_fame", 2.0, 0.0, 1.0e6, "career."),
		"belt_legacy_bonus": TrainingData._num(dados, "belt_legacy_bonus", 100.0, 0.0, 1.0e12, "career."),
		"defeat_share": TrainingData._num(dados, "defeat_share", 0.5, 0.0, 1.0e6, "career."),
		"retire_share": TrainingData._num(dados, "retire_share", 1.0, 0.0, 1.0e6, "career."),
		"retire_belt_bonus_share": TrainingData._num(dados, "retire_belt_bonus_share", 0.5, 0.0, 1.0e6, "career."),
		# Fase 5: segundos de PERIGOSO na academia até aparecer a dica "APOSENTAR AGORA LEVA {n} DE LEGADO"
		"gym_retire_hint_seconds": TrainingData._num(dados, "gym_retire_hint_seconds", 300.0, 0.0, 1.0e6, "career."),
	}
	# Regra "aposentar rende mais que perder" não pode quebrar por dado.
	if carreira.defeat_share >= carreira.retire_share:
		push_warning("FightData: defeat_share deve ser < retire_share; usando 0.5 / 1.0.")
		carreira.defeat_share = 0.5
		carreira.retire_share = 1.0


# --- Fase 4: Metrônomo (loja) ---

func _ler_metronomo(m: Variant) -> void:
	metronomo = {"id": "metronome", "name": "Metrônomo", "description": "", "appears_as": "", "levels": []}
	if not (m is Dictionary):
		return  # sem bloco: sem Metrônomo na loja
	metronomo.id = TrainingData._txt(m, "id", "metronome")
	metronomo.name = TrainingData._txt(m, "name", "Metrônomo")
	metronomo.description = TrainingData._txt(m, "description", "")
	metronomo.appears_as = TrainingData._txt(m, "appears_as", "")
	var lista = m.get("levels", [])
	if not (lista is Array):
		lista = []
	var ids := {}
	var anterior := INF
	var niveis: Array = []
	for item in lista:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids.has(id):
			push_warning("FightData: nível do Metrônomo com id vazio ou repetido ('%s') ignorado." % id)
			continue
		var custo = item.get("cost", null)
		var intervalo = item.get("interval", null)
		if (typeof(custo) != TYPE_FLOAT and typeof(custo) != TYPE_INT) or not is_finite(float(custo)) or float(custo) <= 0.0:
			push_warning("FightData: nível '%s' do Metrônomo com custo inválido: ignorado." % id)
			continue
		if (typeof(intervalo) != TYPE_FLOAT and typeof(intervalo) != TYPE_INT) or not is_finite(float(intervalo)):
			push_warning("FightData: nível '%s' do Metrônomo com intervalo inválido: ignorado." % id)
			continue
		var iv := float(intervalo)
		if iv < METRONOMO_INTERVALO_MIN or iv > METRONOMO_INTERVALO_MAX:
			push_warning("FightData: intervalo %s do Metrônomo '%s' fora de [%s, %s]: recortado." % [str(iv), id,
				str(METRONOMO_INTERVALO_MIN), str(METRONOMO_INTERVALO_MAX)])
			iv = clampf(iv, METRONOMO_INTERVALO_MIN, METRONOMO_INTERVALO_MAX)
		if iv >= anterior:
			push_warning("FightData: nível '%s' do Metrônomo não é mais rápido que o anterior: ignorado." % id)
			continue
		ids[id] = true
		anterior = iv
		niveis.append({"id": id, "level": niveis.size() + 1, "cost": float(custo), "interval": iv,
			"name": TrainingData._txt(item, "name", id), "description": TrainingData._txt(item, "description", ""),
			"appears_as": TrainingData._txt(item, "appears_as", "")})
	metronomo.levels = niveis


# --- Fase 4: árvore de habilidades ---

func no_da_arvore(id: String) -> Dictionary:
	for n in arvore:
		if n.id == id:
			return n
	return {}


func ramo(id: String) -> Dictionary:
	for r in ramos:
		if r.id == id:
			return r
	return {}


func _ler_arvore(dados: Dictionary) -> void:
	var rs = dados.get("branches", [])
	if not (rs is Array):
		rs = []
	for item in rs:
		if item is Dictionary and not str(item.get("id", "")).is_empty() and ramo(str(item.id)).is_empty():
			ramos.append({"id": str(item.id), "name": TrainingData._txt(item, "name", str(item.id).to_upper()),
				"requires_arts_unlocked": item.get("requires_arts_unlocked", false) == true})
	if ramos.is_empty():
		push_warning("FightData: skill_tree.json sem ramos válidos: árvore vazia.")
		return
	var lista = dados.get("nodes", [])
	if not (lista is Array):
		lista = []
	var ids := {}
	for item in lista:
		if not (item is Dictionary):
			continue
		var id := str(item.get("id", ""))
		if id.is_empty() or ids.has(id):
			push_warning("FightData: nó da árvore com id vazio ou repetido ('%s') ignorado." % id)
			continue
		var r := str(item.get("branch", ""))
		if ramo(r).is_empty():
			push_warning("FightData: nó '%s' com ramo desconhecido ('%s'): ignorado." % [id, r])
			continue
		var custo = item.get("cost", null)
		if (typeof(custo) != TYPE_FLOAT and typeof(custo) != TYPE_INT) or not is_finite(float(custo)) or float(custo) < 1.0 \
				or float(custo) != floorf(float(custo)):
			push_warning("FightData: nó '%s' com custo inválido (inteiro >= 1): ignorado." % id)
			continue
		var ef = item.get("effect", null)
		if not (ef is Dictionary) or not (str(ef.get("type", "")) in TIPOS_EFEITO):
			push_warning("FightData: nó '%s' com efeito desconhecido: ignorado." % id)
			continue
		var valor = ef.get("value", null)
		if (typeof(valor) != TYPE_FLOAT and typeof(valor) != TYPE_INT) or not is_finite(float(valor)) or float(valor) < 0.0:
			push_warning("FightData: nó '%s' com valor de efeito inválido: ignorado." % id)
			continue
		ids[id] = true
		arvore.append({
			"id": id, "branch": r, "requires": str(item.get("requires", "")), "cost": int(custo),
			"requires_art": str(item.get("requires_art", "")),
			"effect_type": str(ef.type), "effect_value": float(valor),
			"name": TrainingData._txt(item, "name", id), "description": TrainingData._txt(item, "description", ""),
			"effect_text": TrainingData._txt(item, "effect_text", ""), "icon": TrainingData._txt(item, "icon", ""),
		})
	# `requires`: tem de existir, ser do mesmo ramo e não formar ciclo; senão vira "" (nó raiz).
	for n in arvore:
		if n.requires == "":
			continue
		var pai := no_da_arvore(n.requires)
		if pai.is_empty() or pai.branch != n.branch or n.requires == n.id:
			push_warning("FightData: 'requires' de '%s' inválido ('%s'): vira vazio." % [n.id, n.requires])
			n.requires = ""
	for n in arvore:
		var passos := 0
		var atual: Dictionary = n
		while atual.requires != "" and passos <= arvore.size():
			atual = no_da_arvore(atual.requires)
			passos += 1
		if passos > arvore.size():
			push_warning("FightData: ciclo em 'requires' de '%s': vira vazio." % n.id)
			n.requires = ""
