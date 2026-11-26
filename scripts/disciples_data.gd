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
var passagem_tela: Dictionary = {}  # bloco `screen` (linhas da tela de criação)
var nomes: Array[String] = []
var nome_padrao := "Novato"
var erros: Array[String] = []
var liberado: Callable = Callable()  # Ronda 2a1: Callable(requires: String) -> bool; quem decide se um estilo com `requires` já foi ganho


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
	passagem_tela = _dic(raiz.get("screen", {}))
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


## Opção de estilo (Ronda 2a1): tem `requires` ("black_cat_style:<id>"). Nunca entra no sorteio; só aparece na tela depois de liberada.
func tem_requisito(campo: String, id: String) -> bool:
	return str(_opcao(campo, id).get("requires", "")) != ""


## O estilo desta opção já foi ganho? (sem `liberado` configurado = nunca)
func opcao_liberada(campo: String, id: String) -> bool:
	var req := str(_opcao(campo, id).get("requires", ""))
	return req != "" and liberado.is_valid() and bool(liberado.call(req))


## Marca da opção (ex.: "cat" nos estilos da noite) ou "".
func marca_da_opcao(campo: String, id: String) -> String:
	return str(_opcao(campo, id).get("mark", ""))


## Ids ligados (`enabled`) de um campo, na ordem do arquivo; no fim da lista, os estilos com `requires` já liberados.
func opcoes_ativas(campo: String) -> Array[String]:
	var r: Array[String] = []
	for o in opcoes(campo):
		if bool(o.get("enabled", false)) and not o.has("requires"):
			r.append(str(o.id))
	for o in opcoes(campo):
		if o.has("requires") and opcao_liberada(campo, str(o.id)):
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
		if x is String and opcao_existe(campo, x) and (not tem_requisito(campo, x) or opcao_liberada(campo, x)):
			r[campo] = x
		else:
			r[campo] = look_padrao[campo]
			if v is Dictionary:
				avisos.append("look: campo %s ausente ou inválido" % campo)
	return r


## Liga todas as opções (contexto de teste da 6b2: a arte pode ainda não ter entrado). Só em memória.
## Estilos com `requires` (Ronda 2a1) ficam de fora: só o jogo os libera.
func ligar_todas_as_opcoes() -> void:
	for campo in campos:
		for o in opcoes(campo):
			if not o.has("requires"):
				o["enabled"] = true


func _opcao(campo: String, id: String) -> Dictionary:
	for o in opcoes(campo):
		if str(o.get("id", "")) == id:
			return o
	return {}


## Cores efetivas do visual inteiro, as 9 peças: {campo: {id, slots, colors (hex), tokens}}. Campo de forma (corte,
## parte de cima, faixa) vem só com o id (slots e cores vazios). O meião copia as cores do campo `source` (pele ou
## calção) pelos nomes de `source_slots`. A cor de uma peça "sem" continua sendo a guardada (a UI decide mostrar).
func cores(look: Dictionary) -> Dictionary:
	var r := {}
	for campo in campos:
		var id := str(look.get(campo, look_padrao.get(campo, "")))
		var o := _opcao(campo, id)
		var slots: Array = _dic(campos[campo]).get("slots", []).duplicate()
		if o.has("source"):
			r[campo] = _cores_do_meiao(campo, id, o, look, slots)
		else:
			r[campo] = {"id": id, "slots": slots, "colors": o.get("colors", []).duplicate(), "tokens": o.get("tokens", []).duplicate()}
	return r


# Meião: pega, na cor da origem (pele/calção do mesmo look), as cores dos slots pedidos.
func _cores_do_meiao(campo: String, id: String, o: Dictionary, look: Dictionary, slots: Array) -> Dictionary:
	var origem := str(o.get("source", ""))
	var oid := str(look.get(origem, look_padrao.get(origem, "")))
	var oo := _opcao(origem, oid)
	var oslots: Array = _dic(campos.get(origem, {})).get("slots", [])
	var cores_o: Array = []
	var tokens_o: Array = []
	for nome in o.get("source_slots", []):
		var i := oslots.find(str(nome))
		if i >= 0 and i < oo.get("colors", []).size():
			cores_o.append(oo.colors[i])
			if i < oo.get("tokens", []).size():
				tokens_o.append(oo.tokens[i])
	return {"id": id, "slots": slots, "colors": cores_o, "tokens": tokens_o}


# --- Tela de criação ---

## Linhas da tela na ordem de `screen.rows`, já com a coluna: [{field, label, kind, chips, depends_on, coluna (1|2),
## apagada, opcoes (ids ligados)}]. `apagada` = a peça pai está em "none" (a seta não faz nada; o valor fica guardado).
func linhas_tela(look: Dictionary = {}) -> Array:
	var tela := _dic(passagem_tela)
	var por_coluna := maxi(1, int(tela.get("rows_per_column", 6)))
	var r: Array = []
	var i := 0
	for linha in tela.get("rows", []):
		if not (linha is Dictionary):
			continue
		var campo := str(linha.get("field", ""))
		var pai := str(linha.get("depends_on", ""))
		var apagada := pai != "" and str(look.get(pai, look_padrao.get(pai, "none"))) == "none"
		r.append({"field": campo, "label": str(linha.get("label", "")), "kind": str(linha.get("kind", "")),
			"chips": int(linha.get("chips", 0)), "depends_on": pai, "coluna": 1 + i / por_coluna, "apagada": apagada,
			"opcoes": opcoes_ativas(campo) if campo != "name" else ([] as Array[String]),
			"marcas": _marcas_do_campo(campo) if campo != "name" else {}})
		i += 1
	return r


## {id: marca} das opções do campo que têm marca (ex.: {"night": "cat"}); a tela põe o ícone nas liberadas.
func _marcas_do_campo(campo: String) -> Dictionary:
	var r := {}
	for o in opcoes(campo):
		if str(o.get("mark", "")) != "":
			r[str(o.id)] = str(o.mark)
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
		_sortear_campo(rng, look, str(campo))
	var ultimo := _look_do_ultimo_discipulo(roster)
	# Calção diferente do último (1 novo sorteio).
	if bool(sorteio_cfg.get("avoid_same_shorts_as_last", false)) and not ultimo.is_empty() \
			and look.get("shorts_color", "") == ultimo.get("shorts_color", ""):
		_sortear_campo(rng, look, "shorts_color", str(ultimo.get("shorts_color", "")))
	# Cabeça (corte e cor do cabelo) diferente do último (1 novo sorteio do corte).
	if bool(sorteio_cfg.get("avoid_same_hair_as_last", false)) and not ultimo.is_empty() \
			and look.get("hair_style", "") == ultimo.get("hair_style", "") and look.get("hair_color", "") == ultimo.get("hair_color", ""):
		_sortear_campo(rng, look, "hair_style", str(ultimo.get("hair_style", "")))
	_evitar_pares(rng, look)
	return {"name": sortear_nome(rng, roster, nome_atual), "look": look}


## Sorteia um campo com os pesos (`weight`, ausente = 1) entre as opções ligadas. Sem opção ligada: não mexe.
func _sortear_campo(rng: RandomNumberGenerator, look: Dictionary, campo: String, excluir: String = "") -> void:
	var ativas: Array = []
	var total := 0.0
	for o in opcoes(campo):
		if bool(o.get("enabled", false)) and not o.has("requires") and (excluir == "" or str(o.get("id", "")) != excluir):
			ativas.append(o)
			total += maxf(0.0, float(o.get("weight", 1)))
	if ativas.is_empty():
		return
	if total <= 0.0:
		look[campo] = str(ativas[rng.randi() % ativas.size()].id)
		return
	var x := rng.randf() * total
	for o in ativas:
		x -= maxf(0.0, float(o.get("weight", 1)))
		if x < 0.0:
			look[campo] = str(o.id)
			return
	look[campo] = str(ativas[ativas.size() - 1].id)


## Pares feios (`avoid_pairs`): até `max_rerolls` rodadas pela lista inteira; se ainda bater, fica (nunca trava).
func _evitar_pares(rng: RandomNumberGenerator, look: Dictionary) -> void:
	var pares: Array = sorteio_cfg.get("avoid_pairs", [])
	for _rodada in int(sorteio_cfg.get("max_rerolls", 8)):
		var mexeu := false
		for par in pares:
			if par is Dictionary and _bate(look, par.get("if", {})) and _bate(look, par.get("and", {})):
				_sortear_campo(rng, look, str(par.get("reroll", "")))
				mexeu = true
		if not mexeu:
			return


func _bate(look: Dictionary, cond: Variant) -> bool:
	if not (cond is Dictionary) or cond.is_empty():
		return false
	for campo in cond:
		if str(look.get(campo, "")) != str(cond[campo]):
			return false
	return true


## Algum par da lista bate com este look? (para os testes)
func par_feio(look: Dictionary) -> bool:
	for par in sorteio_cfg.get("avoid_pairs", []):
		if par is Dictionary and _bate(look, par.get("if", {})) and _bate(look, par.get("and", {})):
			return true
	return false


func _look_do_ultimo_discipulo(roster: Array) -> Dictionary:
	for i in range(roster.size() - 1, -1, -1):
		var e = roster[i]
		if e is Dictionary and str(e.get("kind", "")) == "disciple" and e.get("look", null) is Dictionary:
			return e.look
	return {}
