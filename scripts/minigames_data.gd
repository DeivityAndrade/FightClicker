class_name MinigamesData
extends RefCounted
## Fase 7a2: lê e valida data/minigames.json (convite do Osmar, Choque, Panfletagem, semente do Gato Preto).
## Arquivo ausente ou ilegível = `vazio` (o jogo segue sem convites, igual à 7a1).
## Número fora da faixa é recortado; campo faltando desliga só o bloco dele (Choque ou Panfletagem).

const CAMINHO := "res://data/minigames.json"
const NIVEIS := 6

var vazio := true
var invite: Dictionary = {}
var nivel_max := 5
var ref_clicks_per_s := 3.0
var spar: Dictionary = {}  # {} = Choque desligado
var flyers: Dictionary = {}  # {} = Panfletagem desligada
var black_cat: Dictionary = {}
var avisos: Array[String] = []


static func carregar(caminho: String = CAMINHO) -> MinigamesData:
	var r := MinigamesData.new()
	if not FileAccess.file_exists(caminho):
		return r
	var bruto = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if not (bruto is Dictionary):
		r.avisos.append("minigames.json ilegível: sem convites.")
		return r
	r._ler(bruto)
	return r


func _ler(d: Dictionary) -> void:
	invite = _bloco_convite(d.get("invite", null))
	if invite.is_empty():
		avisos.append("minigames.json: bloco invite inválido: sem convites.")
		return
	var nv = d.get("level", {})
	nivel_max = clampi(int(nv.get("max", 5)) if nv is Dictionary else 5, 0, 99)
	var rr = d.get("reward_ref", {})
	ref_clicks_per_s = clampf(float(rr.get("ref_clicks_per_s", 3.0)) if rr is Dictionary else 3.0, 0.0, 100.0)
	spar = _bloco_choque(d.get("spar", null))
	flyers = _bloco_panfleto(d.get("flyers", null))
	var gc = d.get("black_cat_seed", {})
	black_cat = gc if gc is Dictionary else {}
	vazio = spar.is_empty() and flyers.is_empty()


# ---- ajuda ----
# Número da chave recortado na faixa; ausente ou não numérico vira NAN (o bloco inteiro é recusado).
func _n(d: Dictionary, chave: String, lo: float, hi: float) -> float:
	var v = d.get(chave, null)
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return NAN
	var x := float(v)
	if not is_finite(x):
		return NAN
	return clampf(x, lo, hi)


# Copia as chaves numéricas pedidas {chave: [lo, hi]} de `d`; devolve {} se alguma faltar.
func _numeros(d: Dictionary, faixas: Dictionary) -> Dictionary:
	var r := {}
	for k in faixas:
		var x := _n(d, str(k), float(faixas[k][0]), float(faixas[k][1]))
		if is_nan(x):
			avisos.append("minigames.json: '%s' ausente ou inválido." % k)
			return {}
		r[k] = x
	return r


func _niveis(v: Variant, faixas: Dictionary) -> Array:
	if not (v is Array) or v.is_empty():
		return []
	var out: Array = []
	for item in v:
		if not (item is Dictionary):
			return []
		var n := _numeros(item, faixas)
		if n.is_empty():
			return []
		out.append(n)
	while out.size() < NIVEIS:
		out.append(out[-1].duplicate())  # menos de 6 linhas: repete a última
	return out


func _bloco_convite(v: Variant) -> Dictionary:
	if not (v is Dictionary):
		return {}
	var r := _numeros(v, {"first_after_s": [0.1, 36000.0], "interval_s": [0.1, 36000.0], "visible_s": [0.1, 36000.0],
		"min_after_return_s": [0.0, 36000.0]})
	if r.is_empty():
		return {}
	var kinds = v.get("kinds", {})
	r["kinds"] = kinds if kinds is Dictionary else {}
	return r


func _bloco_choque(v: Variant) -> Dictionary:
	if not (v is Dictionary):
		return {}
	var r := _numeros(v, {"countdown_s": [0.0, 120.0], "duration_s": [0.1, 120.0], "points_goal": [1.0, 99.0],
		"reset_s": [0.0, 120.0], "counter_mult": [1.0, 100.0], "read_mult": [0.0, 1.0], "hold_is_guard_s": [0.0, 5.0]})
	if r.is_empty():
		return {}
	r["points_goal"] = int(r["points_goal"])
	var vs = v.get("variants", null)
	if not (vs is Dictionary) or not (vs.get("boxing", null) is Dictionary) or not (vs.get("bjj", null) is Dictionary):
		return {}
	var bx := _numeros(vs.boxing, {"push_per_click": [0.001, 1.0], "breath_cost_per_click": [0.0, 1.0],
		"breath_recover_per_s": [0.0, 10.0], "weak_min": [0.0, 1.0]})
	var jj := _numeros(vs.bjj, {"pull_per_s": [0.001, 10.0], "breath_drain_per_s": [0.0, 10.0],
		"breath_recover_per_s": [0.0, 10.0], "weak_min": [0.0, 1.0], "burst_hold_drain_mult": [1.0, 20.0]})
	if bx.is_empty() or jj.is_empty():
		return {}
	r["variants"] = {"boxing": bx, "bjj": jj}
	var lv := _niveis(v.get("levels", null), {"base_push": [0.0, 5.0], "burst_push": [0.0, 10.0], "burst_s": [0.1, 20.0],
		"warn_s": [0.1, 20.0], "pause_s": [0.1, 20.0], "pause_warn_s": [0.1, 20.0], "feint_pause_s": [0.1, 20.0],
		"gap_min": [0.1, 60.0], "gap_max": [0.1, 60.0], "w_burst": [0.0, 100.0], "w_pause": [0.0, 100.0], "w_feint": [0.0, 100.0]})
	if lv.is_empty():
		return {}
	for l in lv:
		l["gap_max"] = maxf(l.gap_max, l.gap_min)
	r["levels"] = lv
	var rw = v.get("reward", null)
	var rr := _numeros(rw, {"max_seconds": [0.0, 600.0], "floor": [0.0, 1.0]}) if rw is Dictionary else {}
	var w = v.get("warm", null)
	var ww := _numeros(w, {"attr_bonus": [0.0, 1.0]}) if w is Dictionary else {}
	if rr.is_empty() or ww.is_empty():
		return {}
	r["reward"] = rr
	r["warm"] = ww
	return r


func _bloco_panfleto(v: Variant) -> Dictionary:
	if not (v is Dictionary):
		return {}
	var r := _numeros(v, {"countdown_s": [0.0, 120.0], "duration_s": [0.1, 120.0], "goal": [1.0, 999.0],
		"give_cooldown_s": [0.0, 10.0], "miss_cooldown_s": [0.0, 10.0], "miss_penalty": [0.0, 10.0], "cross_s": [0.5, 60.0]})
	if r.is_empty():
		return {}
	r["goal"] = int(r["goal"])
	var lv := _niveis(v.get("levels", null), {"spawn_s": [0.05, 60.0], "interested": [0.0, 1.0], "tell_s": [0.1, 20.0],
		"false_tell": [0.0, 1.0]})
	if lv.is_empty():
		return {}
	r["levels"] = lv
	var rw = v.get("reward", null)
	var rr := _numeros(rw, {"fame_share": [0.0, 10.0], "min_fame": [0.0, 1.0e6], "floor": [0.0, 1.0]}) if rw is Dictionary else {}
	if rr.is_empty():
		return {}
	r["reward"] = rr
	return r
