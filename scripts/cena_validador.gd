class_name CenaValidador
extends RefCounted
## Validador das cenas por dados (Fase 6b1, formato-dados.md §7). Confere sem abrir o jogo: estrutura, tipos de passo
## (todos os do formato, inclusive os da luta), posições inteiras, `rect` do 2x, falas, sons, tempo preso e fim da cena.
## Arte que ainda não existe (animação, sprite, ponto nomeado) NÃO é erro: vai em `pendencias`, e o teste do tempo
## vira aviso enquanto a duração depender de arte que falta.
##
## Relatório: {id, erros: [String], avisos: [String], pendencias: [String], tempo_preso: float, tempo_exato: bool}

const PASTA_SFX := "res://assets/sfx/"

var dados: CenaDados
var _erros: Array[String] = []
var _avisos: Array[String] = []
var _pend: Array[String] = []
var _cena: Dictionary = {}


static func novo(dados_cena: CenaDados = null) -> CenaValidador:
	var v := CenaValidador.new()
	v.dados = dados_cena if dados_cena != null else CenaDados.novo()
	return v


## Valida todas as cenas de data/cutscenes/ (a pasta de rascunhos fica de fora).
func validar_tudo() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for id in CenaDados.ids_das_cenas():
		r.append(validar_id(id))
	return r


func validar_id(id: String) -> Dictionary:
	var caminho := CenaDados.PASTA + id + ".json"
	return validar_caminho(caminho, id)


## Valida um arquivo qualquer (ex.: um rascunho em data/cutscenes/_rascunhos/). `id_esperado` = nome do arquivo sem .json.
func validar_caminho(caminho: String, id_esperado: String = "") -> Dictionary:
	_erros = []
	_avisos = []
	_pend = []
	_cena = {}
	var esperado := id_esperado if id_esperado != "" else caminho.get_file().get_basename()
	if not FileAccess.file_exists(caminho):
		_erros.append("arquivo não existe: " + caminho)
		return _relatorio(esperado, 0.0, false)
	var bruto = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if not (bruto is Dictionary):
		_erros.append("JSON inválido")
		return _relatorio(esperado, 0.0, false)
	_cena = CenaDados.sem_comentarios(bruto)
	_conferir_cena(esperado)
	var tempo := 0.0
	var exato := false
	if _erros.is_empty():
		var comp := dados.compilar(_cena, {"disciple_name": "Novato", "pontos_local": _pontos_dos_locais()})
		tempo = float(comp.duracao_presa)
		exato = bool(comp.exato)
		for p in dados.pendencias:
			_pend_unico(p)
		var teto := float(_cena.get("max_seconds", 0.0))
		if not bool(_cena.get("blocking", true)) and tempo > 1.0e-6:
			_erros.append("cena sem controle preso prende %.2f s (precisa ser 0)" % tempo)
		if bool(_cena.get("blocking", true)) and tempo > teto + 1.0e-6:
			if exato:
				_erros.append("tempo preso %.2f s passa de max_seconds %.2f" % [tempo, teto])
			else:
				_avisos.append("tempo preso provisório %.2f s passa de max_seconds %.2f (faltam durações de arte)" % [tempo, teto])
	return _relatorio(esperado, tempo, exato)


func _relatorio(id: String, tempo: float, exato: bool) -> Dictionary:
	return {"id": id, "erros": _erros.duplicate(), "avisos": _avisos.duplicate(), "pendencias": _pend.duplicate(),
		"tempo_preso": tempo, "tempo_exato": exato}


func _e(msg: String) -> void:
	_erros.append(msg)


func _pend_unico(msg: String) -> void:
	if not (msg in _pend):
		_pend.append(msg)


# --- Estrutura da cena ---

func _conferir_cena(esperado: String) -> void:
	var c := _cena
	if str(c.get("id", "")) != esperado:
		_e("id '%s' diferente do nome do arquivo '%s'" % [str(c.get("id", "")), esperado])
	if not _inteiro(c.get("version", null)) or int(c.get("version", 0)) < 1:
		_e("version precisa ser inteiro >= 1")
	if typeof(c.get("blocking", null)) != TYPE_BOOL:
		_e("blocking precisa ser true ou false")
	if typeof(c.get("once", null)) != TYPE_BOOL:
		_e("once precisa ser true ou false")
	else:
		var marco := str(c.get("milestone", ""))
		if bool(c.once) and marco == "":
			_e("once: true exige milestone")
		if not bool(c.once) and marco != "":
			_e("once: false não pode ter milestone")
	var reg := str(c.get("register", ""))
	var regs: Dictionary = dados.cfg.get("registers", {})
	if not regs.has(reg):
		_e("register desconhecido: " + reg)
	var maximo = c.get("max_seconds", null)
	if not _numero(maximo) or float(maximo) <= 0.0:
		_e("max_seconds precisa ser número > 0")
	elif regs.has(reg) and float(maximo) > float(regs[reg].get("max_seconds", 1.0e9)):
		_e("max_seconds %.1f passa do limite do registro %s" % [float(maximo), reg])
	_conferir_gatilho()
	_conferir_grants()
	_conferir_palco()
	_conferir_atores()
	_conferir_falas()
	var raiz_passos: Array = []
	if c.has("versions"):
		var v = c.versions
		if not (v is Dictionary) or not (v.get("full", null) is Array) or not (v.get("short", null) is Array):
			_e("versions precisa ter full e short (listas de passos)")
		else:
			if c.has("steps"):
				_e("use steps OU versions, não os dois")
			raiz_passos = v.full + v.short
			_conferir_lista_de_passos(v.full, "versions.full", true)
			_conferir_lista_de_passos(v.short, "versions.short", true)
	elif c.get("steps", null) is Array and not c.steps.is_empty():
		raiz_passos = c.steps
		_conferir_lista_de_passos(c.steps, "steps", true)
	else:
		_e("a cena precisa de steps (lista não vazia) ou versions")
	if not _tem_tipo(raiz_passos, "return_control") and not _tem_tipo(raiz_passos, "start_fight"):
		_e("a cena precisa de return_control ou start_fight")
	if _tem_tipo(raiz_passos, "start_fight") and str(c.get("stage", {}).get("view", "")) != "fight":
		_e("start_fight só em cena com view: fight")
	_conferir_reacoes()
	_conferir_estado_final()
	if typeof(c.get("blocking", null)) == TYPE_BOOL and not bool(c.blocking):
		_conferir_cena_livre(raiz_passos)


func _conferir_gatilho() -> void:
	var g = _cena.get("trigger", null)
	if not (g is Dictionary):
		_e("falta trigger")
		return
	if not (str(g.get("event", "")) in dados.cfg.get("events", [])):
		_e("trigger.event desconhecido: " + str(g.get("event", "")))
	var req = g.get("requires", {})
	if not (req is Dictionary):
		_e("trigger.requires precisa ser dicionário")
		return
	for k in req:
		if not (str(k) in dados.cfg.get("requires", [])):
			_e("trigger.requires chave desconhecida: " + str(k))
	for k in ["milestone_missing", "milestone_present"]:
		if req.has(k) and not (req[k] is Array):
			_e("trigger.requires.%s precisa ser lista" % k)


func _conferir_grants() -> void:
	var g = _cena.get("grants", [])
	if not (g is Array):
		_e("grants precisa ser lista")
		return
	if not g.is_empty() and str(_cena.get("milestone", "")) == "":
		_e("grants só com milestone (o marco grava os grants)")
	for x in g:
		if not (x is Dictionary) or not (str(x.get("type", "")) in dados.cfg.get("grants", [])):
			_e("grant com tipo desconhecido: " + str(x))
			continue
		if str(x.type) in ["mentor_in_room", "mentor_leaves"] and not dados.personagem_valido(str(x.get("character", ""))):
			_e("grant %s com personagem desconhecido: %s" % [str(x.type), str(x.get("character", ""))])
		if str(x.type) == "prop_permanent":
			for k in ["id", "sprite", "point", "location"]:
				if str(x.get(k, "")) == "":
					_e("grant prop_permanent sem " + k)


func _conferir_palco() -> void:
	var s = _cena.get("stage", null)
	if not (s is Dictionary):
		_e("falta stage")
		return
	if not (str(s.get("view", "")) in dados.cfg.get("views", [])):
		_e("stage.view desconhecida: " + str(s.get("view", "")))
	if str(s.get("location", "")) == "":
		_e("stage.location vazio")
	_conferir_retangulo(s.get("window", null), "stage.window")
	var escondidos = s.get("hide", [])
	if not (escondidos is Array):
		_e("stage.hide precisa ser lista")
	else:
		for h in escondidos:
			if not (str(h) in dados.cfg.get("hide_values", [])):
				_e("stage.hide: valor desconhecido: %s" % str(h))
	var props = s.get("props", {})
	if not (props is Dictionary):
		_e("stage.props precisa ser dicionário")
		return
	for id in props:
		var p = props[id]
		var onde := "stage.props." + str(id)
		if not (p is Dictionary):
			_e(onde + " precisa ser dicionário")
			continue
		if p.has("room_object"):
			if not dados.cfg.get("room_objects", {}).has(str(p.room_object)):
				_e("%s: room_object desconhecido: %s" % [onde, str(p.room_object)])
		elif str(p.get("sprite", "")) == "":
			_e(onde + " precisa de sprite ou room_object")
		elif not dados.sprites.has(str(p.sprite)):
			_pend_unico("sprite sem arte: " + str(p.sprite))
		if p.has("pos"):
			_conferir_ponto_inteiro(p.pos, onde + ".pos")
		if p.has("layer"):
			if not (str(p.layer) in dados.cfg.get("layers", [])):
				_e("%s: layer desconhecida: %s" % [onde, str(p.layer)])
			elif str(p.layer) == "sorted" and not _inteiro(p.get("sort_y", null)):
				_e(onde + ": layer sorted exige sort_y inteiro")


func _conferir_atores() -> void:
	var a = _cena.get("actors", {})
	if not (a is Dictionary):
		_e("actors precisa ser dicionário")
		return
	for id in a:
		var x = a[id]
		var onde := "actors." + str(id)
		if not (x is Dictionary):
			_e(onde + " precisa ser dicionário")
			continue
		if not dados.personagem_valido(str(x.get("character", ""))):
			_e("%s: personagem desconhecido: %s" % [onde, str(x.get("character", ""))])
		_conferir_ponto_inteiro(x.get("pos", null), onde + ".pos")
		if x.has("fallback") and not dados.personagem_valido(str(x.fallback)):
			_e("%s: fallback desconhecido: %s" % [onde, str(x.fallback)])
		if x.has("optional") and typeof(x.optional) != TYPE_BOOL:
			_e(onde + ": optional precisa ser true ou false")
		if x.has("from_room") and not (str(x.from_room) in dados.cfg.get("from_room_roles", [])):
			_e("%s: from_room desconhecido: %s" % [onde, str(x.from_room)])
		if x.has("requires"):
			if not (x.requires is Dictionary) or not (str(x.requires.get("owned", "")) != "") or x.requires.size() != 1:
				_e(onde + ": requires só aceita {owned: aparelho}")
		if x.has("facing") and not (str(x.facing) in ["left", "right"]):
			_e(onde + ": facing precisa ser left ou right")
		if x.has("glove") and not _luva_valida(str(x.glove)):
			_e("%s: glove desconhecida: %s" % [onde, str(x.glove)])


func _luva_valida(g: String) -> bool:
	return g in ["glove_old", "none"] or g.begins_with("glove_l")


func _conferir_falas() -> void:
	var l = _cena.get("lines", {})
	if not (l is Dictionary):
		_e("lines precisa ser dicionário")
		return
	for id in l:
		var f = l[id]
		var onde := "lines." + str(id)
		if not (f is Dictionary):
			_e(onde + " precisa ser dicionário")
			continue
		if not _cena.get("actors", {}).has(str(f.get("speaker", ""))):
			_e("%s: speaker não é um ator: %s" % [onde, str(f.get("speaker", ""))])
		var texto := ""
		if f.has("text_key"):
			if not dados.textos.has(str(f.text_key)):
				_e("%s: text_key inexistente em ui_texts.json: %s" % [onde, str(f.text_key)])
				continue
			texto = str(dados.textos[str(f.text_key)])
		else:
			texto = str(f.get("text", ""))
		# Variáveis valem pelo maior nome possível (14 letras do discípulo), para medir o pior caso.
		var medido := dados.texto_da_fala({"text": texto}, {"disciple_name": "xxxxxxxxxxxxxx"})
		for p in dados.dialogos.erros_de_texto(medido):
			_e("%s: %s" % [onde, p])


func _conferir_reacoes() -> void:
	var r = _cena.get("reactions", [])
	if not (r is Array):
		_e("reactions precisa ser lista")
		return
	for x in r:
		if not (x is Dictionary) or not (str(x.get("when", "")) in dados.cfg.get("reaction_events", [])):
			_e("reação com when desconhecido: " + str(x))
			continue
		if str(x.when) == "idle_seconds" and not _numero(x.get("seconds", null)):
			_e("reação idle_seconds sem seconds")
		if not (x.get("steps", null) is Array) or x.steps.is_empty():
			_e("reação sem steps")
			continue
		_conferir_lista_de_passos(x.steps, "reactions.%s" % str(x.when), false)


func _conferir_estado_final() -> void:
	var e = _cena.get("end_state", null)
	if not (e is Dictionary):
		_e("falta end_state")
		return
	_conferir_estado(e, "end_state")


# Estado de cena (end_state e open_screen.state): atores, adereços, câmera, interface e sons.
func _conferir_estado(e: Dictionary, onde: String) -> void:
	var mao: String = str(dados.cfg.get("end_state_hand", "hand_to_game"))
	for id in e.get("actors", {}):
		if not _cena.get("actors", {}).has(str(id)):
			_e("%s.actors: ator desconhecido: %s" % [onde, str(id)])
			continue
		var v = e.actors[id]
		if v is Dictionary:
			if v.has("pos") and not (v.pos is String and v.pos == "mentor_spot"):
				_conferir_posicao_nomeada(v.pos, "%s.actors.%s.pos" % [onde, str(id)])
			if v.has("glove") and not _luva_valida(str(v.glove)):
				_e("%s.actors.%s: glove desconhecida: %s" % [onde, str(id), str(v.glove)])
		elif not (v is String and v == mao):
			_e("%s.actors.%s precisa ser dicionário ou \"%s\"" % [onde, str(id), mao])
	for id in e.get("props", {}):
		if not _cena.get("stage", {}).get("props", {}).has(str(id)):
			_e("%s.props: adereço desconhecido: %s" % [onde, str(id)])
			continue
		var pv = e.props[id]
		if not (pv is Dictionary) and not (pv is String and pv == mao):
			_e("%s.props.%s precisa ser dicionário ou \"%s\"" % [onde, str(id), mao])
		elif pv is Dictionary and str(pv.get("anim", "")) != "":
			_conferir_anim_do_adereco(str(id), str(pv.anim), onde + ".props")
	var cam = e.get("camera", null)
	if cam != null and (not (cam is Dictionary) or not (int(cam.get("scale", 0)) in [1, 2])):
		_e(onde + ".camera.scale precisa ser 1 ou 2")
	var ui = e.get("ui", null)
	if ui != null and not (ui is String):
		_e(onde + ".ui precisa ser texto (show_all, hide_all)")
	var sons = e.get("sounds", null)
	if sons != null:
		if not (sons is Dictionary):
			_e(onde + ".sounds precisa ser {stop, loop}")
		else:
			for k in sons:
				if not (str(k) in ["stop", "loop"]) or not (sons[k] is Array):
					_e("%s.sounds.%s inválido" % [onde, str(k)])
					continue
				for s in sons[k]:
					_conferir_som(str(s), onde + ".sounds")


# --- Passos ---

func _conferir_lista_de_passos(lista: Array, onde: String, topo: bool) -> void:
	for i in lista.size():
		var p = lista[i]
		var nome := "%s[%d]" % [onde, i]
		if not (p is Dictionary):
			_e(nome + " precisa ser dicionário")
			continue
		_conferir_passo(p, nome, topo)


func _tem_tipo(lista: Array, tipo: String) -> bool:
	for p in lista:
		if not (p is Dictionary):
			continue
		if str(p.get("type", "")) == tipo:
			return true
		if p.get("steps", null) is Array and _tem_tipo(p.steps, tipo):
			return true
	return false


func _conferir_passo(p: Dictionary, onde: String, topo: bool) -> void:
	var tipo := str(p.get("type", ""))
	var exec: Array = dados.cfg.get("step_types", {}).get("executed", [])
	var so_valida: Array = dados.cfg.get("step_types", {}).get("validated_only", [])
	if not (tipo in exec) and not (tipo in so_valida):
		_e("%s: tipo de passo desconhecido: '%s'" % [onde, tipo])
		return
	if p.has("wait") and typeof(p.wait) != TYPE_BOOL:
		_e(onde + ": wait precisa ser true ou false")
	if p.has("checkpoint") and str(p.checkpoint) == "":
		_e(onde + ": checkpoint vazio")
	if p.has("if"):
		var c = p["if"]
		var chaves: Array = dados.cfg.get("if_keys", ["last_campaign_end"])
		if not (c is Dictionary) or c.is_empty():
			_e(onde + ": condição if desconhecida")
		else:
			for k in c:
				if not (str(k) in chaves):
					_e("%s: condição if desconhecida: %s" % [onde, str(k)])
			if c.has("location") and not (str(c.location) in dados.cfg.get("locations", [])):
				_e("%s: if.location desconhecido: %s" % [onde, str(c.location)])
	if tipo == "open_screen" and not topo:
		_e(onde + ": open_screen só no nível de cima da cena")
	match tipo:
		"wait":
			if not _numero(p.get("seconds", null)) or float(p.seconds) < 0.0:
				_e(onde + ": wait precisa de seconds >= 0")
		"say":
			var l := str(p.get("line", ""))
			if not _cena.get("lines", {}).has(l):
				_e("%s: fala inexistente: %s" % [onde, l])
			if p.has("mode") and not (str(p.mode) in ["scene", "passive"]):
				_e(onde + ": mode precisa ser scene ou passive")
			for k in ["hold", "cps", "cut_after"]:
				if p.has(k) and (not _numero(p[k]) or float(p[k]) < 0.0):
					_e("%s: %s inválido" % [onde, k])
		"move":
			_ator(p, onde)
			_conferir_posicao_nomeada(p.get("to", null), onde + ".to")
			if p.has("speed") == p.has("seconds"):
				_e(onde + ": move precisa de speed OU seconds")
			elif p.has("speed") and (not _numero(p.speed) or float(p.speed) <= 0.0):
				_e(onde + ": speed inválido")
		"pose":
			_ator(p, onde)
			_conferir_pose(p, onde)
		"face":
			_ator(p, onde)
			if str(p.get("face", "")) == "" and str(p.get("facing", "")) == "":
				_e(onde + ": face precisa de face ou facing")
		"show", "hide":
			var tem_ator := p.has("actor")
			if tem_ator == p.has("prop"):
				_e(onde + ": use actor OU prop")
			elif tem_ator:
				_ator(p, onde)
			else:
				_adereco(str(p.prop), onde)
		"sound":
			var id := str(p.get("id", ""))
			if id == "":
				_e(onde + ": sound sem id")
			else:
				_conferir_som(id, onde)
			for k in ["loop", "stop"]:
				if p.has(k) and typeof(p[k]) != TYPE_BOOL:
					_e("%s: %s precisa ser booleano" % [onde, k])
			if p.has("volume") and (not _numero(p.volume) or float(p.volume) < 0.0 or float(p.volume) > 1.0):
				_e(onde + ": volume fora de 0..1")
		"camera":
			var esc := int(p.get("scale", 0))
			if not (esc in [1, 2]):
				_e(onde + ": scale precisa ser 1 ou 2 (corte seco, sem zoom suave)")
			if esc == 2:
				var r = p.get("rect", null)
				if not (r is Array) or r.size() != 4 or not _todos_inteiros(r) or int(r[2]) != 192 or int(r[3]) != 136:
					_e(onde + ": scale 2 exige rect [x, y, 192, 136]")
			if p.has("pan_to"):
				_conferir_ponto_inteiro(p.pan_to, onde + ".pan_to")
		"frame":
			var w = p.get("window", null)
			if not (w is String and w == "full"):
				_conferir_retangulo(w, onde + ".window")
		"ui":
			if p.has("hide") == p.has("show"):
				_e(onde + ": ui precisa de hide OU show")
			var alvo = p.get("hide", p.get("show", null))
			if alvo is String:
				if alvo != "all":
					_e(onde + ": ui aceita \"all\" ou lista")
			elif alvo is Array:
				for parte in alvo:
					if not (str(parte) in dados.cfg.get("ui_parts", [])):
						_e("%s: parte da interface desconhecida: %s" % [onde, str(parte)])
			else:
				_e(onde + ": ui sem alvo")
		"prop":
			_adereco(str(p.get("id", "")), onde)
			if p.has("visible") and typeof(p.visible) != TYPE_BOOL:
				_e(onde + ": visible precisa ser booleano")
			if p.has("frame") and not _inteiro(p.frame):
				_e(onde + ": frame precisa ser inteiro")
			if p.has("pos"):
				_conferir_ponto_inteiro(p.pos, onde + ".pos")
			if str(p.get("anim", "")) != "":
				_conferir_anim_do_adereco(str(p.id), str(p.anim), onde)
		"fx":
			if str(p.get("sprite", "")) == "":
				_e(onde + ": fx sem sprite")
			elif not dados.sprites.has(str(p.sprite)):
				_pend_unico("sprite sem arte: " + str(p.sprite))
			if p.has("pos"):
				_conferir_ponto_inteiro(p.pos, onde + ".pos")
			elif p.has("actor"):
				_ator(p, onde)
			else:
				_e(onde + ": fx precisa de pos ou actor")
		"shake":
			if not (int(p.get("px", 0)) in [1, 2]) or not _inteiro(p.get("frames", null)) or int(p.get("frames", 0)) < 1:
				_e(onde + ": shake precisa de px 1 ou 2 e frames >= 1")
		"light":
			if str(p.get("id", "")) == "" or typeof(p.get("on", null)) != TYPE_BOOL:
				_e(onde + ": light precisa de id e on (booleano)")
		"name_card":
			_ator(p, onde)
			if not (str(p.get("style", "")) in ["plain", "show"]):
				_e(onde + ": style precisa ser plain ou show")
		"photo":
			if str(p.get("id", "")) == "" or not (str(p.get("wall", "")) in ["garage", "gym"]):
				_e(onde + ": photo precisa de id e wall garage ou gym")
		"open_screen":
			if str(p.get("screen", "")) == "":
				_e(onde + ": open_screen sem screen")
			if p.has("state"):
				if p.state is Dictionary:
					_conferir_estado(p.state, onde + ".state")
				else:
					_e(onde + ": state precisa ser dicionário")
		"return_control", "start_fight":
			pass
		"parallel", "sequence":
			if not (p.get("steps", null) is Array) or p.steps.is_empty():
				_e("%s: %s precisa de steps" % [onde, tipo])
			else:
				_conferir_lista_de_passos(p.steps, onde + ".steps", false)


func _ator(p: Dictionary, onde: String) -> void:
	var a := str(p.get("actor", ""))
	if not _cena.get("actors", {}).has(a):
		_e("%s: ator desconhecido: '%s'" % [onde, a])


func _adereco(id: String, onde: String) -> void:
	if not _cena.get("stage", {}).get("props", {}).has(id):
		_e("%s: adereço desconhecido: '%s'" % [onde, id])


func _conferir_pose(p: Dictionary, onde: String) -> void:
	var anim := str(p.get("anim", ""))
	var ator_id := str(p.get("actor", ""))
	var char_id := str(_cena.get("actors", {}).get(ator_id, {}).get("character", ""))
	if anim == "":
		_e(onde + ": pose sem anim")
		return
	# Só o 1º lutador faz o gesto e os toques do mentor (design §4).
	if anim in dados.cfg.get("gesture_anims", []) and not bool(dados.personagem(char_id).get("can_gesture", false)):
		_e("%s: '%s' não pode ser feita por %s (só o John)" % [onde, anim, char_id])
	if p.has("glove") and not _luva_valida(str(p.glove)):
		_e("%s: glove desconhecida: %s" % [onde, str(p.glove)])
	var faixa = p.get("frames", null)
	if faixa != null and (not (faixa is Array) or faixa.size() != 2 or not _todos_inteiros(faixa) or int(faixa[0]) > int(faixa[1]) or int(faixa[0]) < 0):
		_e(onde + ": frames precisa ser [primeiro, último]")
	for k in ["times", "gap", "hold"]:
		if p.has(k) and (not _numero(p[k]) or float(p[k]) < 0.0):
			_e("%s: %s inválido" % [onde, k])
	var folha := dados.folha_da_pose(char_id, anim)
	# 6c1: papel de elenco (mentor:seat, mentor:last): confere cada personagem possível (John, discípulo, fallback).
	var candidatos := dados.candidatos_do_papel(char_id, _cena.get("actors", {}).get(ator_id, {}))
	if not candidatos.is_empty():
		folha = {}
		for cand in candidatos:
			var fc := dados.folha_da_pose(str(cand), anim)
			if fc.is_empty():
				_pend_unico("animação sem arte: %s/%s" % [str(cand), anim])
			elif folha.is_empty():
				folha = fc
		if folha.is_empty():
			folha = {"sprite": "", "frames": 1 << 30}
	elif folha.is_empty():
		_pend_unico("animação sem arte: %s/%s" % [char_id, anim])
	elif faixa is Array and faixa.size() == 2 and int(faixa[1]) >= int(folha.frames):
		_e("%s: frames [%d,%d] passa dos %d quadros de %s" % [onde, int(faixa[0]), int(faixa[1]), int(folha.frames), str(folha.sprite)])


func _conferir_anim_do_adereco(id: String, anim: String, onde: String) -> void:
	var def: Dictionary = _cena.get("stage", {}).get("props", {}).get(id, {})
	if def.has("room_object"):
		if dados._duracao_objeto_da_sala(str(def.room_object), anim) < 0.0:
			_pend_unico("animação de objeto da sala sem arte: %s/%s" % [str(def.room_object), anim])
	elif dados.duracao_anim_adereco(str(def.get("sprite", "")), anim) < 0.0:
		_pend_unico("animação de adereço sem arte: %s/%s" % [str(def.get("sprite", id)), anim])


func _conferir_som(id: String, onde: String) -> void:
	if not FileAccess.file_exists(PASTA_SFX + id + ".wav"):
		_e("%s: som inexistente: %s" % [onde, id])


# --- Posições e números ---

func _numero(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


func _inteiro(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or (typeof(v) == TYPE_FLOAT and is_finite(v) and is_equal_approx(v, round(v)))


func _todos_inteiros(a: Array) -> bool:
	for x in a:
		if not _inteiro(x):
			return false
	return true


func _conferir_ponto_inteiro(v: Variant, onde: String) -> void:
	if not (v is Array) or v.size() != 2 or not _todos_inteiros(v):
		_e("%s precisa ser [x, y] com números inteiros" % onde)


# Posição: [x, y] inteiros ou nome de ponto (mentor_spot). Ponto nomeado sem definição vira pendência.
func _conferir_posicao_nomeada(v: Variant, onde: String) -> void:
	if v is String:
		if dados.ponto(v).is_empty():
			_pend_unico("ponto nomeado sem definição: " + v)
	else:
		_conferir_ponto_inteiro(v, onde)


func _conferir_retangulo(v: Variant, onde: String) -> void:
	if not (v is Array) or v.size() != 4 or not _todos_inteiros(v) or int(v[2]) <= 0 or int(v[3]) <= 0:
		_e("%s precisa ser [x, y, largura, altura] inteiros" % onde)


# --- 6c1: cena sem controle preso (formato §9 item 19) ---

# Pontos dos dois locais juntos (o validador não tem um local só): seat/stand/coach resolvem se algum local os define.
func _pontos_dos_locais() -> Dictionary:
	var r: Dictionary = {}
	for local in dados.cfg.get("locations", []):
		var p := dados.pontos_do_local(str(local))
		for k in p:
			if not r.has(k):
				r[k] = p[k]
	return r


# `blocking: false`: return_control é o 1º passo, e só valem passos passivos (sem ui, camera, shake, open_screen, gesto).
func _conferir_cena_livre(passos: Array) -> void:
	if passos.is_empty() or not (passos[0] is Dictionary) or str(passos[0].get("type", "")) != "return_control":
		_e("cena sem controle preso: return_control precisa ser o 1º passo")
	var permitidos: Array = dados.cfg.get("free_scene_steps", [])
	_conferir_passos_livres(passos, "steps", permitidos)


func _conferir_passos_livres(lista: Array, onde: String, permitidos: Array) -> void:
	for i in lista.size():
		var p = lista[i]
		if not (p is Dictionary):
			continue
		var nome := "%s[%d]" % [onde, i]
		var tipo := str(p.get("type", ""))
		if not (tipo in permitidos):
			_e("%s: passo '%s' não vale em cena sem controle preso" % [nome, tipo])
		if tipo == "say" and str(p.get("mode", "scene")) != "passive":
			_e(nome + ": em cena sem controle preso a fala precisa ser mode passive")
		if tipo == "pose" and str(p.get("anim", "")) in dados.cfg.get("gesture_anims", []):
			_e(nome + ": gesto do John não vale em cena sem controle preso")
		if p.get("steps", null) is Array:
			_conferir_passos_livres(p.steps, nome + ".steps", permitidos)
