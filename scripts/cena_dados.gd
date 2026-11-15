class_name CenaDados
extends RefCounted
## Cenas por dados (Fase 6b1): lê data/cutscenes/<id>.json e "compila" os passos numa linha do tempo plana de eventos
## com tempo, que o CenaPlayer toca e o CenaValidador confere. Nada visual aqui. Formato: docs/cutscenes/formato-dados.md v1.1.
##
## Evento compilado: {seg, t, tipo, ...campos do passo}. `seg` é o trecho (cada open_screen abre um novo trecho, com t = 0);
## `t` é o começo em segundos dentro do trecho. Passos com `wait: false` não adiantam o relógio do passo seguinte.

const PASTA := "res://data/cutscenes/"
const CAMINHO_CFG := "res://data/cena_player.json"
const CAMINHO_MANIFESTO := "res://assets/sprites/manifest.json"
const CAMINHO_TEXTOS := "res://data/ui_texts.json"

static var _manifesto_cache: Dictionary = {}  # o manifest é grande: lido uma vez por execução

var cfg: Dictionary = {}
var textos: Dictionary = {}
var dialogos: DialogosData
var sprites: Dictionary = {}  # manifest.sprites
var layout: Dictionary = {}  # manifest.layout
## O que a compilação não conseguiu resolver por falta de arte (anim, sprite, ponto): vira pendência, não erro.
var pendencias: Array[String] = []


static func novo(dados_dialogos: DialogosData = null, dados_textos: Dictionary = {}) -> CenaDados:
	var c := CenaDados.new()
	c.cfg = _ler_json(CAMINHO_CFG)
	c.textos = dados_textos if not dados_textos.is_empty() else _ler_json(CAMINHO_TEXTOS)
	c.dialogos = dados_dialogos if dados_dialogos != null else DialogosData.carregar()
	if _manifesto_cache.is_empty():
		_manifesto_cache = _ler_json(CAMINHO_MANIFESTO)
	c.sprites = _manifesto_cache.get("sprites", {}) if _manifesto_cache.get("sprites", {}) is Dictionary else {}
	c.layout = _manifesto_cache.get("layout", {}) if _manifesto_cache.get("layout", {}) is Dictionary else {}
	return c


static func _ler_json(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var v = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return v if v is Dictionary else {}


## Tira toda chave que começa com `_` (comentário), em qualquer profundidade.
static func sem_comentarios(v: Variant) -> Variant:
	if v is Dictionary:
		var r := {}
		for k in v:
			if str(k).begins_with("_"):
				continue
			r[k] = sem_comentarios(v[k])
		return r
	if v is Array:
		var a: Array = []
		for x in v:
			a.append(sem_comentarios(x))
		return a
	return v


# --- Arquivos ---

## Ids das cenas (arquivos de data/cutscenes/, sem a pasta de rascunhos), em ordem alfabética.
static func ids_das_cenas() -> Array[String]:
	var r: Array[String] = []
	for arq in DirAccess.get_files_at(PASTA):
		if arq.ends_with(".json"):
			r.append(arq.get_basename())
	r.sort()
	return r


## A cena sem comentários, ou {} se o arquivo não existe ou não é JSON válido.
static func carregar_cena(id: String) -> Dictionary:
	var caminho := PASTA + id + ".json"
	if not FileAccess.file_exists(caminho):
		return {}
	var v = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return sem_comentarios(v) if v is Dictionary else {}


# --- Gatilhos ---

## `requires` da cena confere com o contexto? ctx: {milestones: Dictionary, campaign, campaigns_finished, location, opponent, calm}.
## Chaves desconhecidas não bloqueiam (o validador acusa).
static func requisitos_ok(requires: Dictionary, ctx: Dictionary) -> bool:
	var marcos: Dictionary = ctx.get("milestones", {})
	for m in requires.get("milestone_missing", []):
		if marcos.has(str(m)):
			return false
	for m in requires.get("milestone_present", []):
		if not marcos.has(str(m)):
			return false
	if requires.has("campaign_min") and int(ctx.get("campaign", 1)) < int(requires.campaign_min):
		return false
	if requires.has("campaigns_finished_min") and int(ctx.get("campaigns_finished", 0)) < int(requires.campaigns_finished_min):
		return false
	if requires.has("location") and str(ctx.get("location", "")) != str(requires.location):
		return false
	if requires.has("opponent") and str(ctx.get("opponent", "")) != str(requires.opponent):
		return false
	if requires.has("calm") and bool(requires.calm) and not bool(ctx.get("calm", true)):
		return false
	return true


## Id da primeira cena (em ordem alfabética) cujo gatilho é `evento` e cujos requisitos conferem. "" se nenhuma.
static func escolher_cena(evento: String, ctx: Dictionary) -> String:
	for id in ids_das_cenas():
		var cena := carregar_cena(id)
		var g = cena.get("trigger", {})
		if g is Dictionary and str(g.get("event", "")) == evento and requisitos_ok(g.get("requires", {}), ctx):
			return id
	return ""


# --- Textos e elenco ---

## Texto da fala (`text_key` de ui_texts.json, ou `text` direto), com {disciple_name}, {first_name} e {school_name}.
func texto_da_fala(fala: Dictionary, vars: Dictionary = {}) -> String:
	var t := str(textos.get(str(fala.get("text_key", "")), fala.get("text", "")))
	var primeiro := str(dialogos.cast.get("first", {}).get("name", "John Bullet"))
	t = t.replace("{first_name}", str(vars.get("first_name", primeiro)))
	t = t.replace("{school_name}", str(vars.get("school_name", dialogos.school_name)))
	t = t.replace("{disciple_name}", str(vars.get("disciple_name", "")))
	return t


func personagem(id: String) -> Dictionary:
	var c = cfg.get("characters", {}).get(id, {})
	return c if c is Dictionary else {}


## true para um id de elenco que o formato aceita (inclusive mentor:N e opp_<id>).
func personagem_valido(id: String) -> bool:
	if not personagem(id).is_empty():
		return true
	for prefixo in cfg.get("character_patterns", []):
		if id.begins_with(str(prefixo)) and id.length() > str(prefixo).length():
			return true
	return false


## Voz do balão do ator (first, coach, disciple).
func voz_do_ator(cena: Dictionary, ator: String) -> String:
	var char_id := str(cena.get("actors", {}).get(ator, {}).get("character", ""))
	return str(personagem(char_id).get("voice", "first"))


## Ponto nomeado → [x, y]. Procura em data/cena_player.json e em manifest.layout.points. [] se não existe.
func ponto(nome: String) -> Array:
	# O manifest manda (layout.<nome>, ex.: mentor_spot); data/cena_player.json é o reserva.
	var q = layout.get(nome, null)
	if q is Array and q.size() == 2:
		return q
	var p = cfg.get("points", {}).get(nome, null)
	if p is Array and p.size() == 2:
		return p
	return []


## Como a interface desenha a cena da porta: manifest.by_data_id.garage_door_scene (pivô, camadas, ordem). {} se não existe.
## Regras: a porta tem pivô (0,12) e quadro de 84x68; a sombra de pés (garage_door_shadow) vem DEPOIS da luz do dia.
func desenho_da_garagem() -> Dictionary:
	var d = _manifesto_cache.get("by_data_id", {}).get("garage_door_scene", {}) if _manifesto_cache.get("by_data_id", {}) is Dictionary else {}
	return d.duplicate(true) if d is Dictionary else {}


func resolver_posicao(v: Variant) -> Array:
	if v is Array and v.size() == 2:
		return [int(v[0]), int(v[1])]
	if v is String:
		var p := ponto(v)
		return [int(p[0]), int(p[1])] if not p.is_empty() else []
	return []


# --- Duração das animações (manifest) ---

## Folha do manifest de uma pose: {sprite, frames, fps} ou {} se a arte ainda não existe.
func folha_da_pose(personagem_id: String, anim: String) -> Dictionary:
	var mapa = _manifesto_cache.get("scene_anims", {})
	if mapa is Dictionary and mapa.has(personagem_id) and mapa[personagem_id] is Dictionary and mapa[personagem_id].has(anim):
		var s := str(mapa[personagem_id][anim])
		if sprites.has(s):
			return _folha(s)
	# Reserva em data/cena_player.json (sprite_aliases): liga o nome lógico a uma folha que já existe.
	var alias = cfg.get("sprite_aliases", {}).get(personagem_id, {})
	if alias is Dictionary and alias.has(anim) and sprites.has(str(alias[anim])):
		return _folha(str(alias[anim]))
	var prefixo := str(personagem(personagem_id).get("sprite_prefix", ""))
	for cand in [prefixo + "_" + anim, anim]:
		if prefixo != "" or cand == anim:
			if sprites.has(cand):
				return _folha(cand)
	return {}


func _folha(sprite: String) -> Dictionary:
	var s: Dictionary = sprites[sprite]
	return {"sprite": sprite, "frames": int(s.get("frames", 1)),
		"fps": float(s.get("fps", cfg.get("timing", {}).get("default_fps", 10.0)))}


## Duração de uma animação de adereço (mapa `anim` do sprite no manifest). -1 se a arte ainda não existe.
func duracao_anim_adereco(sprite: String, anim: String) -> float:
	if not sprites.has(sprite):
		return -1.0
	var s: Dictionary = sprites[sprite]
	var mapa = s.get("anim", {})
	if not (mapa is Dictionary) or not mapa.has(anim):
		return -1.0
	var a = mapa[anim]
	var fps := float(s.get("fps", cfg.get("timing", {}).get("default_fps", 10.0)))
	var n := 0
	if a is Array:
		n = a.size()
	elif a is Dictionary:
		n = a.get("frames", []).size() if a.get("frames", []) is Array else 0
		fps = float(a.get("fps", fps))
	return float(n) / maxf(fps, 1.0) if n > 1 else 0.0  # um quadro só = pose parada, sem duração


# --- Compilação ---

## Compila a cena. `ctx` (opcional): {last_campaign_end, milestones, disciple_name}. Devolve:
## {id, eventos, segmentos [{duracao}], duracao_presa, exato, retorno {seg, t}, telas [{seg, t, tela, checkpoint, state}],
##  checkpoints {nome: {seg, t, state}}, reacoes [{when, once, seconds, eventos, duracao}], falas {id: {speaker, text, voice}}}
func compilar(cena: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	pendencias = []
	var passos: Array = _passos_da_cena(cena, ctx)
	var estado := {"eventos": [], "pos": {}, "exato": true, "seg": 0, "cena": cena, "ctx": ctx, "ordem": 0}
	for id in cena.get("actors", {}):
		var a: Dictionary = cena.actors[id]
		estado.pos[id] = resolver_posicao(a.get("pos", [0, 0]))
	var segmentos: Array = []
	var telas: Array = []
	var checkpoints := {}
	var retorno := {}
	var t := 0.0
	for p in passos:
		if not (p is Dictionary) or not _passa_condicao(p, ctx):
			continue
		var tipo := str(p.get("type", ""))
		if str(p.get("checkpoint", "")) != "":
			checkpoints[str(p.checkpoint)] = {"seg": estado.seg + (1 if tipo == "open_screen" else 0),
				"t": 0.0 if tipo == "open_screen" else t, "state": p.get("state", {}) if tipo == "open_screen" else {}}
		if tipo == "open_screen":
			_emitir(estado, t, "open_screen", {"tela": str(p.get("screen", "")), "checkpoint": str(p.get("checkpoint", "")),
				"state": p.get("state", {})})
			telas.append({"seg": estado.seg, "t": t, "tela": str(p.get("screen", "")),
				"checkpoint": str(p.get("checkpoint", "")), "state": p.get("state", {})})
			segmentos.append({"duracao": t})
			estado.seg += 1
			t = 0.0
			continue
		if tipo == "return_control":
			retorno = {"seg": estado.seg, "t": t}
		var fim_t := _passo(p, t, estado)
		if bool(p.get("wait", true)):
			t = fim_t
	segmentos.append({"duracao": t})
	# O tempo preso = soma dos trechos até o return_control (sem esperar o jogador na tela).
	var presa := 0.0
	if not retorno.is_empty():
		for i in retorno.seg:
			presa += float(segmentos[i].duracao)
		presa += float(retorno.t)
	else:
		for s in segmentos:
			presa += float(s.duracao)
	var falas := {}
	for id in cena.get("lines", {}):
		var l: Dictionary = cena.lines[id]
		falas[id] = {"speaker": str(l.get("speaker", "")), "text": texto_da_fala(l, {"disciple_name": str(ctx.get("disciple_name", ""))}),
			"voice": voz_do_ator(cena, str(l.get("speaker", "")))}
	var reacoes: Array = []
	for r in cena.get("reactions", []):
		if not (r is Dictionary):
			continue
		var er := {"eventos": [], "pos": estado.pos.duplicate(true), "exato": true, "seg": 0, "cena": cena, "ctx": ctx, "ordem": 0}
		var tr := 0.0
		for p in r.get("steps", []):
			if p is Dictionary and _passa_condicao(p, ctx):
				var f := _passo(p, tr, er)
				if bool(p.get("wait", true)):
					tr = f
		if not er.exato:
			estado.exato = false
		reacoes.append({"when": str(r.get("when", "")), "once": bool(r.get("once", true)),
			"seconds": float(r.get("seconds", 0.0)), "eventos": er.eventos, "duracao": tr})
	var eventos: Array = estado.eventos
	eventos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.seg != b.seg:
			return a.seg < b.seg
		if not is_equal_approx(float(a.t), float(b.t)):
			return float(a.t) < float(b.t)
		return int(a.ordem) < int(b.ordem))
	return {"id": str(cena.get("id", "")), "eventos": eventos, "segmentos": segmentos, "duracao_presa": presa,
		"exato": estado.exato, "retorno": retorno, "telas": telas, "checkpoints": checkpoints, "reacoes": reacoes, "falas": falas}


# Passos a tocar: `steps`, ou `versions.short`/`versions.full` (short quando o marco da cena já existe).
func _passos_da_cena(cena: Dictionary, ctx: Dictionary) -> Array:
	var v = cena.get("versions", null)
	if v is Dictionary:
		var marco_ja: bool = str(cena.get("milestone", "")) != "" and ctx.get("milestones", {}).has(str(cena.get("milestone", "")))
		var escolhida = v.get("short" if marco_ja else "full", [])
		return escolhida if escolhida is Array else []
	var s = cena.get("steps", [])
	return s if s is Array else []


func _passa_condicao(passo: Dictionary, ctx: Dictionary) -> bool:
	var c = passo.get("if", null)
	if not (c is Dictionary):
		return true
	if c.has("last_campaign_end") and str(ctx.get("last_campaign_end", "")) != str(c.last_campaign_end):
		return false
	return true


func _emitir(estado: Dictionary, t: float, tipo: String, campos: Dictionary) -> void:
	var ev := campos.duplicate(true)
	ev["seg"] = estado.seg
	ev["t"] = t
	ev["tipo"] = tipo
	ev["ordem"] = estado.ordem
	estado.ordem += 1
	estado.eventos.append(ev)


## Compila um passo começando em `t`. Devolve o instante em que ele termina (o chamador decide se espera).
func _passo(p: Dictionary, t: float, estado: Dictionary) -> float:
	var tipo := str(p.get("type", ""))
	var cena: Dictionary = estado.cena
	match tipo:
		"wait":
			return t + float(p.get("seconds", 0.0))
		"say":
			return _say(p, t, estado)
		"move":
			return _move(p, t, estado)
		"pose":
			return _pose(p, t, estado)
		"face":
			_emitir(estado, t, "face", {"ator": str(p.get("actor", "")), "face": str(p.get("face", "")), "facing": str(p.get("facing", ""))})
			return t
		"show", "hide":
			_emitir(estado, t, tipo, {"ator": str(p.get("actor", "")), "adereco": str(p.get("prop", ""))})
			return t
		"sound":
			_emitir(estado, t, "sound", {"id": str(p.get("id", "")), "volume": float(p.get("volume", 1.0)),
				"loop": bool(p.get("loop", false)), "stop": bool(p.get("stop", false)), "fade": float(p.get("fade", 0.0))})
			return t
		"camera":
			var seg_cam := float(p.get("seconds", 0.0))
			_emitir(estado, t, "camera", {"scale": int(p.get("scale", 1)), "rect": p.get("rect", []), "pan_to": p.get("pan_to", []), "seconds": seg_cam})
			return t + seg_cam
		"ui":
			var seg_ui := float(p.get("seconds", 0.0))
			_emitir(estado, t, "ui", {"hide": p.get("hide", null), "show": p.get("show", null), "seconds": seg_ui})
			return t + seg_ui
		"prop":
			return _prop(p, t, estado)
		"shake":
			var dur := float(p.get("frames", 1)) / maxf(float(cfg.get("timing", {}).get("shake_fps", 30.0)), 1.0)
			_emitir(estado, t, "shake", {"px": int(p.get("px", 1)), "frames": int(p.get("frames", 1)), "seconds": dur})
			return t + dur
		"return_control":
			_emitir(estado, t, "return_control", {})
			return t
		"parallel":
			var fim_p := t
			for c in p.get("steps", []):
				if c is Dictionary and _passa_condicao(c, estado.ctx):
					var e := _passo(c, t, estado)
					if bool(c.get("wait", true)):
						fim_p = maxf(fim_p, e)
			return fim_p
		"sequence":
			var tt := t
			for c in p.get("steps", []):
				if c is Dictionary and _passa_condicao(c, estado.ctx):
					var e2 := _passo(c, tt, estado)
					if bool(c.get("wait", true)):
						tt = e2
			return tt
		"frame", "name_card":
			var seg_f := float(p.get("seconds", 0.0))
			_emitir(estado, t, tipo, p.duplicate(true))
			return t + seg_f
		"fx", "light", "photo", "start_fight":
			_emitir(estado, t, tipo, p.duplicate(true))
			return t
		_:
			return t
	return t


func _say(p: Dictionary, t: float, estado: Dictionary) -> float:
	var cena: Dictionary = estado.cena
	var id := str(p.get("line", ""))
	var fala: Dictionary = cena.get("lines", {}).get(id, {})
	var texto := texto_da_fala(fala, {"disciple_name": str(estado.ctx.get("disciple_name", ""))})
	var voz := voz_do_ator(cena, str(fala.get("speaker", "")))
	var tempo := dialogos.tempo_fala(texto, voz)
	var dur := float(tempo.write) + float(p.get("hold", tempo.hold))
	if p.has("cps"):
		dur = float(texto.replace("\n", "").length()) / maxf(float(p.cps), 1.0) + float(p.get("hold", tempo.hold))
	if p.has("cut_after"):
		dur = float(p.cut_after)
	_emitir(estado, t, "say", {"line": id, "ator": str(fala.get("speaker", "")), "mode": str(p.get("mode", "scene")),
		"text": texto, "voice": voz, "cps": float(p.get("cps", 0.0)), "cut_after": float(p.get("cut_after", 0.0)), "seconds": dur})
	return t + dur


func _move(p: Dictionary, t: float, estado: Dictionary) -> float:
	var ator := str(p.get("actor", ""))
	var destino := resolver_posicao(p.get("to", null))
	var origem: Array = estado.pos.get(ator, [])
	if destino.is_empty():
		pendencias.append("ponto não resolvido: %s" % str(p.get("to", "")))
		estado.exato = false
		destino = origem
	var dur := 0.0
	if p.has("seconds"):
		dur = float(p.seconds)
	elif not origem.is_empty() and not destino.is_empty():
		var vel := float(p.get("speed", cfg.get("timing", {}).get("default_walk_speed", 48.0)))
		dur = Vector2(float(destino[0] - origem[0]), float(destino[1] - origem[1])).length() / maxf(vel, 1.0)
	estado.pos[ator] = destino
	_emitir(estado, t, "move", {"ator": ator, "to": destino, "seconds": dur, "anim": str(p.get("anim", "walk")), "facing": str(p.get("facing", ""))})
	return t + dur


func _pose(p: Dictionary, t: float, estado: Dictionary) -> float:
	var cena: Dictionary = estado.cena
	var ator := str(p.get("actor", ""))
	var anim := str(p.get("anim", ""))
	var char_id := str(cena.get("actors", {}).get(ator, {}).get("character", ""))
	var folha := folha_da_pose(char_id, anim)
	var fps := float(folha.get("fps", cfg.get("timing", {}).get("default_fps", 10.0)))
	var base := 0.0
	var faixa = p.get("frames", null)
	if faixa is Array and faixa.size() == 2:
		base = float(int(faixa[1]) - int(faixa[0]) + 1) / maxf(fps, 1.0)
	elif not folha.is_empty():
		base = float(folha.frames) / maxf(fps, 1.0)
	else:
		base = float(cfg.get("timing", {}).get("default_pose_seconds", 0.5))
		estado.exato = false
		pendencias.append("animação sem arte: %s/%s" % [char_id, anim])
	var vezes := maxi(1, int(p.get("times", 1)))
	var dur := base * vezes + float(p.get("gap", 0.0)) * (vezes - 1)
	if bool(p.get("loop", false)):
		dur = 0.0  # laço não tem fim: só vale o `hold`
	dur += float(p.get("hold", 0.0))
	var campos := {"ator": ator, "anim": anim, "loop": bool(p.get("loop", false)), "times": vezes, "gap": float(p.get("gap", 0.0)),
		"hold": float(p.get("hold", 0.0)), "face": str(p.get("face", "")), "facing": str(p.get("facing", "")),
		"frames": faixa if faixa is Array else [], "glove": str(p.get("glove", "")), "slow": bool(p.get("slow", false)), "seconds": dur}
	_emitir(estado, t, "pose", campos)
	return t + dur


func _prop(p: Dictionary, t: float, estado: Dictionary) -> float:
	var cena: Dictionary = estado.cena
	var id := str(p.get("id", ""))
	var def: Dictionary = cena.get("stage", {}).get("props", {}).get(id, {})
	var dur := 0.0
	var anim := str(p.get("anim", ""))
	if anim != "" and not p.has("frame"):
		var sprite := str(def.get("sprite", ""))
		if def.has("room_object"):
			dur = _duracao_objeto_da_sala(str(def.room_object), anim)
			sprite = str(def.room_object)
		else:
			dur = duracao_anim_adereco(sprite, anim)
		if dur < 0.0:
			dur = float(cfg.get("timing", {}).get("default_prop_anim_seconds", 0.5))
			estado.exato = false
			pendencias.append("animação de adereço sem arte: %s/%s" % [sprite if sprite != "" else id, anim])
	_emitir(estado, t, "prop", {"id": id, "visible": p.get("visible", null), "anim": anim, "frame": p.get("frame", null),
		"pos": p.get("pos", []), "layer": str(p.get("layer", "")), "seconds": dur})
	return t + dur


# Objetos da sala que a cena pode controlar (data/cena_player.json > room_objects): ou uma folha por animação
# ({"hit": "bag_l0_hit"}) ou uma folha só com o mapa `anim` ({"sprite": "lamp"}). -1 se a arte não existe.
func _duracao_objeto_da_sala(objeto: String, anim: String) -> float:
	var m = cfg.get("room_objects", {}).get(objeto, {})
	if not (m is Dictionary):
		return -1.0
	if m.has(anim) and sprites.has(str(m[anim])):
		var f := _folha(str(m[anim]))
		return float(f.frames) / maxf(float(f.fps), 1.0)
	if m.has("sprite"):
		return duracao_anim_adereco(str(m.sprite), anim)
	return -1.0
