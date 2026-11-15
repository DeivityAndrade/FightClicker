class_name DiscipulosData
extends RefCounted
## Dados do discípulo (Fase 6b1): regras do nome, visual (look), opções e cores, sorteio, toques do mentor.
## Lê data/disciples.json (Designer) e o banco de nomes que ele aponta (data/nomes_discipulos.json, Roteirista).
## Só dados e funções puras: o estado do jogo mora no GameState.

const CAMINHO := "res://data/disciples.json"

var nome_cfg: Dictionary = {}
var look_padrao: Dictionary = {}
var campos: Dictionary = {}
var sorteio_cfg: Dictionary = {}
var passagem: Dictionary = {}  # bloco `handover` do JSON (ids das telas, cenas e do marco)
var toques: Dictionary = {}  # bloco `mentor_taps`
var mentores_cfg: Dictionary = {}  # bloco `room_mentors`
var nomes: Array[String] = []
var nome_padrao := "Novato"
var erros: Array[String] = []


static func carregar(caminho: String = CAMINHO) -> DiscipulosData:
	var d := DiscipulosData.new()
	d._ler(caminho)
	return d


func _ler(caminho: String) -> void:
	var raiz := _json(caminho)
	if raiz.is_empty():
		erros.append("disciples.json ausente ou inválido")
		return
	nome_cfg = _dic(raiz.get("name", {}))
	look_padrao = _dic(raiz.get("default_look", {}))
	campos = _dic(raiz.get("fields", {}))
	sorteio_cfg = _dic(raiz.get("random", {}))
	passagem = _dic(raiz.get("handover", {}))
	toques = _dic(raiz.get("mentor_taps", {}))
	mentores_cfg = _dic(raiz.get("room_mentors", {}))
	var banco := _json(str(raiz.get("names_file", "")))
	if banco.is_empty():
		erros.append("banco de nomes ausente ou inválido")
	else:
		for n in banco.get("nomes", []):
			nomes.append(str(n))
		nome_padrao = str(banco.get("nome_padrao", nome_padrao))
	for campo in look_padrao:
		if not campos.has(campo):
			erros.append("campo do look sem opções: " + str(campo))
		elif not opcao_existe(campo, str(look_padrao[campo])):
			erros.append("padrão do look fora das opções: " + str(campo))


func _json(caminho: String) -> Dictionary:
	if caminho == "" or not FileAccess.file_exists(caminho):
		return {}
	var v = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return v if v is Dictionary else {}


func _dic(v: Variant) -> Dictionary:
	return v if v is Dictionary else {}


# --- Opções do visual ---

func opcoes(campo: String) -> Array:
	return _dic(campos.get(campo, {})).get("options", [])


func opcao_existe(campo: String, id: String) -> bool:
	for o in opcoes(campo):
		if str(o.get("id", "")) == id:
			return true
	return false


## Ids ligados (`enabled`) de um campo, na ordem do arquivo.
func opcoes_ativas(campo: String) -> Array[String]:
	var r: Array[String] = []
	for o in opcoes(campo):
		if bool(o.get("enabled", false)):
			r.append(str(o.id))
	return r


## Look tolerante: campo ausente ou id desconhecido vira o padrão (e entra em `avisos`). Um id desligado é aceito.
func validar_look(v: Variant, avisos: Array = []) -> Dictionary:
	var origem: Dictionary = v if v is Dictionary else {}
	if not (v is Dictionary):
		avisos.append("look ausente ou inválido")
	var r := {}
	for campo in look_padrao:
		var x = origem.get(campo, null)
		if x is String and opcao_existe(campo, x):
			r[campo] = x
		else:
			r[campo] = look_padrao[campo]
			if v is Dictionary:
				avisos.append("look: campo %s ausente ou inválido" % campo)
	return r


## Cores de cada campo do look: {campo: {id, slots, colors, tokens}}. Campo sem cores (6b2 desligado) fica de fora.
func cores(look: Dictionary) -> Dictionary:
	var r := {}
	for campo in campos:
		var id := str(look.get(campo, look_padrao.get(campo, "")))
		for o in opcoes(campo):
			if str(o.get("id", "")) == id and o.has("colors"):
				r[campo] = {"id": id, "slots": _dic(campos[campo]).get("slots", []).duplicate(),
					"colors": o.colors.duplicate(), "tokens": o.get("tokens", []).duplicate()}
	return r


# --- Nome ---

func max_letras() -> int:
	return int(nome_cfg.get("max_chars", 14))


func _letra_valida(c: String) -> bool:
	return str(nome_cfg.get("allowed_letters", "")).contains(c)


## Filtro da digitação (a cada tecla): tira o que a fonte não desenha e limita o tamanho, sem mexer nos espaços.
func filtrar_digitacao(texto: String) -> String:
	var saida := ""
	for i in texto.length():
		var c := texto[i]
		if c == " " or _letra_valida(c):
			saida += c
		if saida.length() >= max_letras():
			break
	return saida


## Corta o texto ao que a fonte desenha (letras e espaço), tira os espaços das pontas, junta os repetidos e limita
## o tamanho. Devolve "" se sobrar menos que `min_letters` letras.
func limpar_nome(texto: String) -> String:
	var saida := ""
	var ultimo_espaco := true  # true no começo: não deixa espaço na ponta esquerda
	for i in texto.length():
		var c := texto[i]
		if c == " " or c == "\t" or c == " ":
			if not ultimo_espaco and bool(nome_cfg.get("allow_space", true)):
				saida += " "
				ultimo_espaco = true
		elif _letra_valida(c):
			saida += c
			ultimo_espaco = false
	saida = saida.strip_edges()
	if saida.length() > max_letras():
		saida = saida.substr(0, max_letras()).strip_edges()
	var letras := 0
	for i in saida.length():
		if saida[i] != " ":
			letras += 1
	return saida if letras >= int(nome_cfg.get("min_letters", 1)) else ""


# --- Sorteio ---

## Nome do banco, sem os `avoid_recent` últimos da lista da escola nem o nome do rascunho atual.
## Se não sobrar nenhum, sorteia na lista inteira.
func sortear_nome(rng: RandomNumberGenerator, roster: Array, atual: String = "") -> String:
	if nomes.is_empty():
		return nome_padrao
	var evitar: Array[String] = []
	var n := int(nome_cfg.get("avoid_recent", 5))
	for i in range(maxi(0, roster.size() - n), roster.size()):
		var e = roster[i]
		if e is Dictionary:
			evitar.append(str(e.get("name", "")))
	if atual != "":
		evitar.append(atual)
	var livres: Array[String] = []
	for nome in nomes:
		if not (nome in evitar):
			livres.append(nome)
	var lista: Array[String] = livres if not livres.is_empty() else nomes
	return lista[rng.randi() % lista.size()]


## Rascunho novo: {name, look}. Cada campo de `random.fields` sorteia entre as opções ligadas; o calção não repete o
## do último discípulo da lista da escola (um novo sorteio).
func sortear(rng: RandomNumberGenerator, roster: Array, nome_atual: String = "") -> Dictionary:
	var look := look_padrao.duplicate()
	for campo in sorteio_cfg.get("fields", []):
		var ativas := opcoes_ativas(str(campo))
		if not ativas.is_empty():
			look[campo] = ativas[rng.randi() % ativas.size()]
	if bool(sorteio_cfg.get("avoid_same_shorts_as_last", false)):
		var ultimo := _look_do_ultimo_discipulo(roster)
		var ativas_c := opcoes_ativas("shorts_color")
		if not ultimo.is_empty() and look.get("shorts_color", "") == ultimo.get("shorts_color", "") and ativas_c.size() > 1:
			look["shorts_color"] = ativas_c[rng.randi() % ativas_c.size()]
	return {"name": sortear_nome(rng, roster, nome_atual), "look": look}


func _look_do_ultimo_discipulo(roster: Array) -> Dictionary:
	for i in range(roster.size() - 1, -1, -1):
		var e = roster[i]
		if e is Dictionary and str(e.get("kind", "")) == "disciple" and e.get("look", null) is Dictionary:
			return e.look
	return {}
