class_name MovesData
extends RefCounted
## Golpes das lutas lidos de data/moves.json. Genérico: o mesmo catálogo serve ao jogador e aos adversários
## (cada lutador tem um estilo; o estilo lista os golpes). A escolha é SÓ VISUAL e determinística: usa a semente
## da luta e o número do evento, nunca o sorteio da simulação, então não muda nenhum resultado.
## Mesma regra dos outros dados: campo ruim é ignorado e avisa no console; nunca derruba o jogo.

const CAMINHO := "res://data/moves.json"
const KINDS := ["jab", "crit", "counter"]

var golpes: Dictionary = {}  # id -> {id, style, name, anim, kinds, unlock, defender_anim}
var estilos: Dictionary = {}  # id do estilo -> {name, moves: Array[String]}


static func carregar(caminho: String = CAMINHO) -> MovesData:
	var m := MovesData.new()
	var bruto := _ler(caminho)
	var est: Dictionary = bruto.get("styles", {}) if bruto.get("styles", {}) is Dictionary else {}
	var gol: Dictionary = bruto.get("moves", {}) if bruto.get("moves", {}) is Dictionary else {}
	for id in gol:
		var g: Variant = gol[id]
		if not (g is Dictionary) or str(id) == "":
			push_warning("MovesData: golpe '%s' ignorado (formato inválido)." % str(id))
			continue
		var anim := str(g.get("anim", ""))
		var kinds: Array = []
		for k in g.get("kinds", []):
			if str(k) in KINDS:
				kinds.append(str(k))
		if anim == "" or kinds.is_empty():
			push_warning("MovesData: golpe '%s' ignorado (sem anim ou sem kinds válidos)." % str(id))
			continue
		m.golpes[str(id)] = {
			"id": str(id), "style": str(g.get("style", "")), "name": str(g.get("name", id)), "anim": anim,
			"kinds": kinds, "unlock": str(g.get("unlock", "base")), "defender_anim": str(g.get("defender_anim", "")),
		}
	for id in est:
		var e: Variant = est[id]
		if not (e is Dictionary):
			continue
		var lista: Array[String] = []
		for gid in e.get("moves", []):
			if m.golpes.has(str(gid)) and not (str(gid) in lista):
				lista.append(str(gid))
		m.estilos[str(id)] = {"name": str(e.get("name", id)), "moves": lista}
	return m


static func _ler(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		push_warning("MovesData: %s não existe; sem golpes extras." % caminho)
		return {}
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	return v if v is Dictionary else {}


## Todas as ações (nomes de anim) que contam como ataque: a tela usa para pôr o atacante na frente.
func anims_de_ataque() -> Array[String]:
	var r: Array[String] = ["jab", "heavy"]
	for id in golpes:
		var a := str(golpes[id].anim)
		if not (a in r):
			r.append(a)
	return r


## Golpes do estilo que o lutador já tem: os "base" e os cujo `unlock` (id de nó da árvore) está em `liberados`.
func disponiveis(estilo: String, liberados: Array = []) -> Array[String]:
	var r: Array[String] = []
	if not estilos.has(estilo):
		return r
	for gid in estilos[estilo].moves:
		var u := str(golpes[gid].unlock)
		if u == "base" or u in liberados:
			r.append(gid)
	return r


## Escolhe o golpe de um evento `kind` entre `ids`. Determinístico (semente + índice do evento). `anterior`
## evita repetir o mesmo golpe duas vezes seguidas quando há outra opção. "" = nenhum serve (a tela usa o antigo).
func escolher(ids: Array, kind: String, semente: int, indice: int, anterior: String = "") -> String:
	var cand: Array[String] = []
	for gid in ids:
		if golpes.has(gid) and kind in golpes[gid].kinds:
			cand.append(str(gid))
	if cand.is_empty():
		return ""
	if cand.size() > 1 and anterior in cand:
		cand.erase(anterior)
	var h := ((semente * 73856093) ^ ((indice + 1) * 19349663)) & 0x7fffffff
	return cand[h % cand.size()]
