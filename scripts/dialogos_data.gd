class_name DialogosData
extends RefCounted
## Fase 6a: falas do treinador e do 1º lutador, textos de objeto, vozes e regras de espaçamento (data/dialogos.json).
## Mesma regra de sempre: dado inválido avisa no console; fala inválida é DESLIGADA e o resto carrega.
## Só dados e funções puras: quem decide quando falar é o GameState.

const CAMINHO := "res://data/dialogos.json"
const COLUNAS_MAX := 26  # caracteres por linha do balão
const LINHAS_MAX := 2
# Caracteres que a fonte 5x7 do balão desenha (minúsculas; só estas minúsculas acentuadas).
const FONTE_BALAO := "abcdefghijklmnopqrstuvwxyzáâãçéêíóõú0123456789 .,;:!?'\"-()"
const REPETICOES: Array[String] = ["once", "rest"]
const CONDICOES: Array[String] = ["fighter", "first_fighter_done", "location", "milestone_present", "milestone_missing",
	"after_line", "revenge", "record", "opponent", "item", "kind", "what", "campaign_min"]

var cast: Dictionary = {}
var school_name := ""
var voices: Dictionary = {}
var typing: Dictionary = {}
var comments: Dictionary = {}
var gesture: Dictionary = {}
var triggers: Dictionary = {}
var opening: Dictionary = {}
var objects: Dictionary = {}
var linhas: Array[Dictionary] = []  # TODAS as falas lidas (as desligadas têm enabled = false)
var erros: Array[String] = []  # avisos do validador (também vão para o console)


static func carregar(caminho: String = CAMINHO) -> DialogosData:
	var d := DialogosData.new()
	d._ler(TrainingData._ler_json(caminho))
	return d


## A fala pelo id ({} se não existe).
func linha(id: String) -> Dictionary:
	for l in linhas:
		if l.id == id:
			return l
	return {}


func gatilho(id: String) -> Dictionary:
	return triggers.get(id, {})


## Prioridade da fala: a dela, ou a do gatilho.
func prioridade(l: Dictionary) -> int:
	return int(l.get("priority", int(gatilho(str(l.trigger)).get("priority", 3))))


## Texto para o balão: {first}/{coach}/{school} viram o apelido curto (minúsculo).
func texto_balao(l: Dictionary) -> String:
	return _trocar(str(l.text), true)


## Texto de objeto da parede ou da interface (nome completo). `campo`: text, title, footer, text_alt, title_alt.
func texto_objeto(chave: String, campo: String = "text") -> String:
	var o = objects.get(chave, {})
	return _trocar(str(o.get(campo, "")), false) if o is Dictionary else ""


func _trocar(t: String, curto: bool) -> String:
	for papel in ["first", "coach"]:
		var p: Dictionary = cast.get(papel, {})
		t = t.replace("{%s}" % papel, str(p.get("short" if curto else "name", "")))
	return t.replace("{school}", school_name)


## Cor da plaquinha e nome curto de quem fala ({name, short, color, voice}).
func personagem(papel: String) -> Dictionary:
	return cast.get(papel, {})


## Tempo de um balão: escrever (letras / velocidade da voz + pausas) e ler (`hold`). {write, hold, total}.
## O fim da fala não tem pausa; `...` pausa por ponto; ',' ';' ':' e '.' '!' '?' pausam depois do sinal.
func tempo_fala(texto: String, voz: String) -> Dictionary:
	var cps := float(voices.get(voz, {}).get("cps", 28.0))
	var n := 0
	var pausas := 0.0
	var t := texto.replace("\n", "")
	var tamanho := t.length()
	for i in tamanho:
		n += 1
		if i == tamanho - 1:
			continue
		var c := t[i]
		if c in [",", ";", ":"]:
			pausas += float(typing.get("pause_comma", 0.12))
		elif c in [".", "!", "?"]:
			var no_meio_de_reticencias: bool = (c == "." and ((i > 0 and t[i - 1] == ".") or t[i + 1] == "."))
			pausas += float(typing.get("pause_ellipsis_dot", 0.13)) if no_meio_de_reticencias else float(typing.get("pause_stop", 0.28))
	var escrita := float(n) / maxf(cps, 1.0) + pausas
	var leitura := maxf(float(typing.get("hold_min", 1.2)), float(typing.get("hold_per_char", 0.06)) * n)
	return {"write": escrita, "hold": leitura, "total": escrita + leitura}


## Duração total de uma fala (id) do ponto de vista do balão. 0 se não existe.
func duracao_fala(id: String) -> float:
	var l := linha(id)
	if l.is_empty():
		return 0.0
	return float(tempo_fala(texto_balao(l), str(cast.get(l.speaker, {}).get("voice", l.speaker))).total)


## Duração prevista da abertura: soma dos balões, `gap_between` entre eles, a partir de `first_line_at`.
func duracao_abertura() -> float:
	var t := float(opening.get("first_line_at", 1.5))
	var ids: Array = opening.get("lines", [])
	for i in ids.size():
		t += duracao_fala(str(ids[i]))
		if i < ids.size() - 1:
			t += float(opening.get("gap_between", 0.3))
	return t


## Letras somadas dos balões da abertura (o orçamento é de 140).
func letras_abertura() -> int:
	var n := 0
	for id in opening.get("lines", []):
		n += texto_balao(linha(str(id))).replace("\n", "").length()
	return n


## Erros de um texto de balão (vazio = ok): mais de 2 linhas, linha > 26, linha começando com pontuação,
## travessão, maiúscula acentuada ou caractere fora da fonte.
func erros_de_texto(texto: String) -> Array[String]:
	var r: Array[String] = []
	if texto.strip_edges() == "":
		r.append("texto vazio")
		return r
	if "—" in texto or "–" in texto:
		r.append("travessão")
	var partes := texto.split("\n")
	if partes.size() > LINHAS_MAX:
		r.append("mais de %d linhas" % LINHAS_MAX)
	for p in partes:
		if p.length() > COLUNAS_MAX:
			r.append("linha com %d caracteres (máx. %d): %s" % [p.length(), COLUNAS_MAX, p])
		if p.length() > 0 and p[0] in [".", ",", ";", ":", "!", "?"]:
			r.append("linha começando com pontuação: " + p)
		if p != p.to_lower():
			r.append("maiúscula no balão: " + p)
	for c in texto:
		# Maiúscula e travessão já foram acusados acima.
		if c == "\n" or c in FONTE_BALAO or c == "—" or c == "–" or c != c.to_lower():
			continue
		r.append("caractere fora da fonte: " + c)
	return r


# --- Escolha ---

## Falas disponíveis para um gatilho agora. `ctx`: {campaign, first_campaign, lutador, location, milestones,
## lines_seen, params}. Já aplica `enabled`, condições, `once`/descanso e o teto de falas repetíveis do gatilho.
func candidatas(gatilho_id: String, ctx: Dictionary) -> Array[Dictionary]:
	var campanha := int(ctx.get("campaign", 1))
	var vistas: Dictionary = ctx.get("lines_seen", {})
	var teto := int(gatilho(gatilho_id).get("campaign_cap", 0))
	var repetiveis_hoje := 0
	for l in linhas:
		if l.trigger == gatilho_id and l.repeat == "rest" and vistas.has(l.id) and int(vistas[l.id]) == campanha:
			repetiveis_hoje += 1
	var r: Array[Dictionary] = []
	for l in linhas:
		if l.trigger != gatilho_id or not bool(l.get("enabled", true)):
			continue
		if not _condicoes_ok(l, ctx):
			continue
		if l.repeat == "once":
			if vistas.has(l.id):
				continue
		else:
			if teto > 0 and repetiveis_hoje >= teto:
				continue
			if vistas.has(l.id) and campanha - int(vistas[l.id]) <= int(l.get("rest_campaigns", 1)):
				continue
		r.append(l)
	return r


## A melhor: maior prioridade; empate, nunca tocada primeiro; depois sorteio. {} se não há.
func melhor(lista: Array, ctx: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if lista.is_empty():
		return {}
	var vistas: Dictionary = ctx.get("lines_seen", {})
	var top := -1
	for l in lista:
		top = maxi(top, prioridade(l))
	var grupo: Array = []
	for l in lista:
		if prioridade(l) == top:
			grupo.append(l)
	var novas: Array = []
	for l in grupo:
		if not vistas.has(l.id):
			novas.append(l)
	if not novas.is_empty():
		grupo = novas
	# Empate de prioridade: a fala "única" (a primeira vez de algo) vem antes das repetíveis.
	var unicas: Array = []
	for l in grupo:
		if l.repeat == "once":
			unicas.append(l)
	if not unicas.is_empty():
		grupo = unicas
	return grupo[rng.randi() % grupo.size()]


func _condicoes_ok(l: Dictionary, ctx: Dictionary) -> bool:
	var c: Dictionary = l.get("conditions", {})
	var p: Dictionary = ctx.get("params", {})
	var marcos: Dictionary = ctx.get("milestones", {})
	var vistas: Dictionary = ctx.get("lines_seen", {})
	var campanha := int(ctx.get("campaign", 1))
	for k in c:
		var v = c[k]
		match str(k):
			"fighter":
				if str(ctx.get("lutador", "")) != str(v):
					return false
			"first_fighter_done":
				if (campanha > int(ctx.get("first_campaign", 1))) != bool(v):
					return false
			"location":
				if str(ctx.get("location", "")) != str(v):
					return false
			"milestone_present":
				for m in v:
					if not marcos.has(str(m)):
						return false
			"milestone_missing":
				for m in v:
					if marcos.has(str(m)):
						return false
			"after_line":
				if not vistas.has(str(v)) or int(vistas[str(v)]) >= campanha:
					return false
			"revenge", "record":
				if bool(p.get(k, false)) != bool(v):
					return false
			"opponent", "item", "kind", "what":
				if str(p.get(k, "")) != str(v):
					return false
			"campaign_min":
				if campanha < int(v):
					return false
	return true


# --- Leitura e validação ---

func _ler(d: Dictionary) -> void:
	cast = _dic(d.get("cast"))
	school_name = str(d.get("school_name", ""))
	voices = _dic(d.get("voices"))
	typing = _dic(d.get("typing"))
	comments = _dic(d.get("comments"))
	gesture = _dic(d.get("gesture"))
	triggers = _dic(d.get("triggers"))
	opening = _dic(d.get("opening"))
	objects = _dic(d.get("objects"))
	var lista = d.get("lines", [])
	if not (lista is Array):
		_erro("'lines' deve ser uma lista.")
		lista = []
	var ids := {}
	for x in lista:
		if not (x is Dictionary):
			_erro("fala inválida (não é objeto): ignorada.")
			continue
		var l: Dictionary = x.duplicate(true)
		l["id"] = str(l.get("id", ""))
		l["speaker"] = str(l.get("speaker", ""))
		l["text"] = str(l.get("text", ""))
		l["trigger"] = str(l.get("trigger", ""))
		l["repeat"] = str(l.get("repeat", ""))
		l["enabled"] = l.get("enabled", true) == true
		if not (l.get("conditions", null) is Dictionary):
			l["conditions"] = {}
		var motivo := _validar_linha(l, ids)
		if motivo != "":
			_erro("fala '%s' desligada: %s" % [l.id, motivo])
			l["enabled"] = false
		if l.id != "":
			ids[l.id] = true
		linhas.append(l)
	for id in opening.get("lines", []):
		if linha(str(id)).is_empty():
			_erro("abertura: fala '%s' não existe." % id)
	# Orçamento da abertura (design §5.2): ≤ 140 letras e ≤ max_seconds.
	if not linha("open_1").is_empty():
		var teto := float(opening.get("max_seconds", 20.0))
		if duracao_abertura() > teto or letras_abertura() > 140:
			_erro("abertura passa do orçamento (%.1f s, %d letras; máx. %.0f s e 140 letras)." % [duracao_abertura(), letras_abertura(), teto])


func _validar_linha(l: Dictionary, ids: Dictionary) -> String:
	if l.id == "":
		return "sem id"
	if ids.has(l.id):
		return "id repetido"
	if not cast.has(l.speaker):
		return "speaker desconhecido (%s)" % l.speaker
	if l.trigger != "opening" and not triggers.has(l.trigger):
		return "gatilho desconhecido (%s)" % l.trigger
	if not (l.repeat in REPETICOES):
		return "repeat deve ser once ou rest"
	for k in l.conditions:
		if not (str(k) in CONDICOES):
			return "condição desconhecida (%s)" % k
	var e := erros_de_texto(texto_balao(l))
	if not e.is_empty():
		return str(e[0])
	return ""


func _dic(v: Variant) -> Dictionary:
	return v.duplicate(true) if v is Dictionary else {}


func _erro(msg: String) -> void:
	erros.append(msg)
	push_warning("DialogosData: " + msg)
