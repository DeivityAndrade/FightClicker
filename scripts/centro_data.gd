class_name CentroData
extends RefCounted
## Fase 8a2: conteúdo do centro de treinamento (data/center.json): gerador que só existe no centro, 5ª melhoria dos aparelhos
## (só comprável no centro) e patrocínio. A região e os nós da árvore entram pelo FightData. Arquivo ausente = jogo da 8a1.
## Campo ruim sai com aviso (mesma regra de sempre).

const CAMINHO := "res://data/center.json"

var ativo := false
var local := ""  # id do local a que o conteúdo pertence ("center")
var geradores: Array[Dictionary] = []  # como em TrainingData.geradores
var melhorias: Dictionary = {}  # id do aparelho -> Array[Dictionary] (melhorias extras, na ordem; entram depois das de training.json)
var patrocinio: Dictionary = {}  # {} = sem patrocínio


static func carregar(caminho: String = CAMINHO) -> CentroData:
	var d := CentroData.new()
	if FileAccess.file_exists(caminho):
		d._ler(TrainingData._ler_json(caminho))
	return d


## Confere contra os dados já lidos (local existe, aparelhos existem, ids únicos). Sem local válido o centro fica desligado.
func validar(dados: TrainingData, academia: GymData) -> void:
	if not ativo:
		return
	if academia.local(local).is_empty():
		push_warning("CentroData: local '%s' não existe em locations.json: centro desligado." % local)
		ativo = false
		geradores = []
		melhorias = {}
		patrocinio = {}
		return
	var ids := {}
	for ap in dados.todos_aparelhos():
		for m in ap.upgrades:
			ids[m.id] = true
	for ap_id in melhorias.keys():
		var ap := dados.aparelho(str(ap_id))
		if ap.is_empty():
			push_warning("CentroData: melhoria para aparelho '%s' inexistente: ignorada." % ap_id)
			melhorias.erase(ap_id)
			continue
		var ok: Array = []
		for m in melhorias[ap_id]:
			if ids.has(m.id):
				push_warning("CentroData: melhoria '%s' repete um id: ignorada." % m.id)
				continue
			ids[m.id] = true
			ok.append(m)
		melhorias[ap_id] = ok
	for g in geradores.duplicate():
		if not dados.gerador(str(g.id)).is_empty():
			push_warning("CentroData: gerador '%s' repete um id de generators.json: ignorado." % g.id)
			geradores.erase(g)


func gerador(id: String) -> Dictionary:
	for g in geradores:
		if g.id == id:
			return g
	return {}


## Melhorias extras do aparelho (só valem no centro).
func melhorias_do(aparelho_id: String) -> Array:
	return melhorias.get(aparelho_id, [])


func _ler(dados: Dictionary) -> void:
	local = str(dados.get("location", ""))
	if local == "":
		push_warning("CentroData: center.json sem `location`: centro desligado.")
		return
	ativo = true
	var t := TrainingData.new()
	var ids := {}
	var lg = dados.get("generators", [])
	if lg is Array:
		for item in lg:
			if not (item is Dictionary):
				continue
			var id := str(item.get("id", ""))
			if id.is_empty() or ids.has(id):
				push_warning("CentroData: gerador com id vazio ou repetido ('%s') ignorado." % id)
				continue
			ids[id] = true
			var g := t._montar_gerador(item, id)
			g["location"] = str(item.get("location", local))
			geradores.append(g)
	var lm = dados.get("apparatus_upgrades", [])
	if lm is Array:
		var ids_m := {}
		for item in lm:
			if not (item is Dictionary):
				continue
			var ap_id := str(item.get("apparatus", ""))
			var mid := str(item.get("id", ""))
			if ap_id == "" or mid == "" or ids_m.has(mid):
				push_warning("CentroData: melhoria com aparelho/id vazio ou repetido ('%s') ignorada." % mid)
				continue
			ids_m[mid] = true
			var m := t._montar_melhoria(item, mid)
			m["location"] = str(item.get("location", local))
			if not melhorias.has(ap_id):
				melhorias[ap_id] = []
			melhorias[ap_id].append(m)
	patrocinio = _ler_patrocinio(dados.get("sponsor", null))


func _ler_patrocinio(v: Variant) -> Dictionary:
	if not (v is Dictionary):
		return {}
	var id := str(v.get("id", ""))
	if id == "":
		push_warning("CentroData: patrocínio sem id: desligado.")
		return {}
	var nome := TrainingData._txt(v, "name", id)
	return {
		"id": id,
		"requires_regional_belts": int(TrainingData._num(v, "requires_regional_belts", 1.0, 0.0, 1.0e6, "sponsor.")),
		"fame_at_least": int(TrainingData._num(v, "fame_at_least", 200.0, 0.0, 1.0e12, "sponsor.")),
		"prize_share": TrainingData._num(v, "prize_share", 0.5, 0.0, 5.0, "sponsor."),
		"name": nome, "short_name": TrainingData._txt(v, "short_name", nome),
		"brand_sprite": TrainingData._txt(v, "brand_sprite", ""),
		"offer_title": TrainingData._txt(v, "offer_title", ""), "offer_line": TrainingData._txt(v, "offer_line", ""),
		"accept_button": TrainingData._txt(v, "accept_button", "ASSINAR"), "close_button": TrainingData._txt(v, "close_button", "AGORA NÃO"),
		"win_line": TrainingData._txt(v, "win_line", "PATROCÍNIO {marca}: +${n}"),
	}
