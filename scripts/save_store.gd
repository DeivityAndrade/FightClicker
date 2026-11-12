class_name SaveStore
extends RefCounted
## Grava e lê o save em JSON, com versão, migração, backup e proteção contra corrupção.
## A pasta é escolhida na criação: o jogo usa PASTA_REAL, os testes usam user://test/...
##
## Formato atual (versão 8, Fase 5.2): igual ao v7 mais career.crew_click (Grito da equipe comprado, bool).
## Versão 7 (Fase 5.1): igual ao v6 mais career.boxes (caixas de equipamento fechadas: [{item, kind, hits}]);
## career.glove_level passa a contar as luvas COMPRADAS (abertas + a que está na caixa).
## Versão 6 (Fase 5): igual ao v5 mais career.location, career.art, career.art_seconds,
## permanent.arts_unlocked, permanent.last_art e ending.summary.art.
## Versão 5 (Fase 4b): igual ao v4 mais career.apparatus_owned e ending.reason.unlock_tip.
## Versão 4 (Fase 4): igual ao v3 mais career.metronome_level, permanent.skill_nodes e
## permanent.revenge_opponent; o Legado passou para a escala x10.
## Versão 3 (Fase 3):
##   { "version": 3, "saved_at_unix": 1730000000,
##     "state": { "career": {...}, "permanent": {...}, "ending": null | {...} } }
## Versão 2 (Fase 2): state = { "career": { training, attributes, focus, generators, upgrades } }.
## Versão 1 (Fase 1): state = { "treino": X }.

const VERSAO_ATUAL := 8
# Fator de conversão do Legado na migração v3 -> v4 (reescala do design; é formato, não balanceamento).
const ESCALA_LEGADO_V4 := 10
# Migração v5 -> v6: dinheiro mínimo de quem já tem o cinturão (= preço da mudança na v6). É formato, não lê data/:
# na v5 o prêmio podia ter sido gasto depois do cinturão, quando ainda não existia mudança.
const MIGRACAO_V6_DINHEIRO_MUDANCA := 1000
const PASTA_REAL := "user://"
const NOME_ARQUIVO := "save.json"

enum Status {
	NOVO,             # não havia save: jogo novo
	OK,               # save principal carregado
	BACKUP,           # principal ausente/corrompido, backup carregado
	CORROMPIDO_NOVO,  # principal e backup ruins: jogo novo (arquivos guardados para análise)
	FUTURO,           # save de versão mais nova: não abre e não grava por cima
}

# Uma função por salto de versão: versão de origem -> nome do método.
const MIGRACOES := {
	0: "_migrar_0_para_1",
	1: "_migrar_1_para_2",
	2: "_migrar_2_para_3",
	3: "_migrar_3_para_4",
	4: "_migrar_4_para_5",
	5: "_migrar_5_para_6",
	6: "_migrar_6_para_7",
	7: "_migrar_7_para_8",
}

var pasta: String
## true quando o save no disco é de versão futura: salvar() recusa gravar.
var bloqueado := false


func _init(p_pasta: String = PASTA_REAL) -> void:
	pasta = p_pasta


func caminho() -> String:
	return pasta.path_join(NOME_ARQUIVO)


func caminho_backup() -> String:
	return caminho() + ".bak"


func caminho_temporario() -> String:
	return caminho() + ".tmp"


## Lê o save. Retorna { status, estado (Dictionary), saved_at_unix (int), mensagem (String) }.
func carregar() -> Dictionary:
	bloqueado = false
	var principal := _ler(caminho())
	if principal.estado == "ok":
		return _resultado(Status.OK, principal)
	if principal.estado == "futuro":
		return _futuro(principal)

	var backup := _ler(caminho_backup())

	if principal.estado == "ausente":
		if backup.estado == "ok":
			return _resultado(Status.BACKUP, backup, "Save principal não encontrado: carregado o backup.")
		if backup.estado == "futuro":
			return _futuro(backup)
		if backup.estado == "corrompido":
			_guardar_corrompido(caminho_backup())
		return _resultado(Status.NOVO, {})

	# Principal corrompido: guarda para análise (nunca apaga) e tenta o backup.
	var guardado := _guardar_corrompido(caminho())
	if backup.estado == "ok":
		return _resultado(Status.BACKUP, backup,
			"Save corrompido (guardado como %s): carregado o backup." % guardado.get_file())
	if backup.estado == "futuro":
		return _futuro(backup)
	if backup.estado == "corrompido":
		_guardar_corrompido(caminho_backup())
	return _resultado(Status.CORROMPIDO_NOVO, {},
		"Save e backup corrompidos (guardado como %s): começando jogo novo." % guardado.get_file())


## Grava o estado. Retorna o horário Unix gravado, ou -1 se não gravou.
## Ordem segura: grava .tmp -> confere -> save atual vira .bak -> .tmp vira save.
func salvar(estado: Dictionary) -> int:
	if bloqueado:
		return -1
	DirAccess.make_dir_recursive_absolute(pasta)
	var agora := int(Time.get_unix_time_from_system())
	var doc := {"version": VERSAO_ATUAL, "saved_at_unix": agora, "state": estado}
	var texto := JSON.stringify(doc, "\t", true, true)

	var f := FileAccess.open(caminho_temporario(), FileAccess.WRITE)
	if f == null:
		push_warning("SaveStore: não foi possível criar %s" % caminho_temporario())
		return -1
	f.store_string(texto)
	f.close()
	# Confere que o temporário ficou legível antes de mexer no save atual.
	if _ler(caminho_temporario()).estado != "ok":
		push_warning("SaveStore: arquivo temporário ilegível, save atual mantido.")
		return -1

	var dir := DirAccess.open(pasta)
	if dir == null:
		return -1
	if FileAccess.file_exists(caminho()):
		if FileAccess.file_exists(caminho_backup()):
			dir.remove(caminho_backup().get_file())
		if dir.rename(caminho().get_file(), caminho_backup().get_file()) != OK:
			push_warning("SaveStore: não foi possível criar o backup.")
			return -1
	if dir.rename(caminho_temporario().get_file(), caminho().get_file()) != OK:
		push_warning("SaveStore: não foi possível substituir o save.")
		return -1
	return agora


## Apaga save, backup e temporário (os arquivos corrompidos guardados ficam).
func apagar() -> void:
	var dir := DirAccess.open(pasta)
	if dir != null:
		for p in [caminho(), caminho_backup(), caminho_temporario()]:
			if FileAccess.file_exists(p):
				dir.remove(p.get_file())
	bloqueado = false


# --- Leitura e migração ---

# Retorna { estado: "ok"|"ausente"|"corrompido"|"futuro", doc, versao }.
func _ler(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {"estado": "ausente"}
	var texto := FileAccess.get_file_as_string(p)
	if texto.strip_edges().is_empty():
		return {"estado": "corrompido"}
	var json := JSON.new()
	if json.parse(texto) != OK or not (json.data is Dictionary):
		return {"estado": "corrompido"}
	var doc: Dictionary = json.data

	# Save sem "version" é do formato 0 (antes do versionamento).
	var versao := 0
	if doc.has("version"):
		var v = doc["version"]
		if (typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT) or not is_finite(float(v)) \
				or float(v) != floorf(float(v)) or float(v) < 0.0:
			return {"estado": "corrompido"}
		# Compara como float: valores gigantes estourariam o int() e virariam "corrompido".
		if float(v) > float(VERSAO_ATUAL):
			return {"estado": "futuro", "versao": float(v)}
		versao = int(v)

	var migrado = _migrar(doc, versao)
	if migrado == null:
		return {"estado": "corrompido"}
	return {"estado": "ok", "doc": migrado, "versao": versao}


# Aplica as migrações em cadeia até a versão atual. Retorna null se faltar algum passo.
func _migrar(doc: Dictionary, versao: int) -> Variant:
	var atual := doc
	while versao < VERSAO_ATUAL:
		if not MIGRACOES.has(versao):
			push_warning("SaveStore: sem migração da versão %d." % versao)
			return null
		atual = call(MIGRACOES[versao], atual)
		versao += 1
		atual["version"] = versao
	return atual


# v0 (antes do versionamento): JSON plano, ex.: { "treino": 42 }.
func _migrar_0_para_1(doc: Dictionary) -> Dictionary:
	return {
		"version": 1,
		"saved_at_unix": 0,
		"state": {"treino": doc.get("treino", 0.0)},
	}


# v1 (Fase 1): state = { "treino": X }. Vira a carreira da Fase 2: o treino vira o saldo,
# os atributos começam em 0 (na Fase 1 não havia foco) e o resto fica no padrão.
func _migrar_1_para_2(doc: Dictionary) -> Dictionary:
	var estado = doc.get("state", {})
	var treino := 0.0
	if estado is Dictionary:
		var t = estado.get("treino", 0.0)
		if (typeof(t) == TYPE_FLOAT or typeof(t) == TYPE_INT) and is_finite(float(t)):
			treino = maxf(float(t), 0.0)
	return {
		"version": 2,
		"saved_at_unix": doc.get("saved_at_unix", 0),
		"state": {"career": {
			"training": treino,
			"attributes": {"strength": 0.0, "agility": 0.0, "endurance": 0.0},
			"focus": "punching_bag",
			"generators": {},
			"upgrades": {},
		}},
	}


# v2 (Fase 2): a carreira vira a "Carreira 1" sem perder nada; campos novos no padrão e o
# bloco permanente começa zerado.
func _migrar_2_para_3(doc: Dictionary) -> Dictionary:
	var estado = doc.get("state", {})
	var carreira := {}
	if estado is Dictionary and estado.get("career") is Dictionary:
		carreira = (estado.career as Dictionary).duplicate(true)
	for chave in ["training", "attributes", "focus", "generators", "upgrades"]:
		if not carreira.has(chave):
			carreira[chave] = {} if chave in ["attributes", "generators", "upgrades"] else (0.0 if chave == "training" else "")
	carreira["paid_generators"] = {}
	carreira["glove_level"] = 0
	carreira["money"] = 0.0
	carreira["fame"] = 0
	carreira["ladder_index"] = 0
	carreira["belt"] = false
	carreira["tactic"] = "defensive"
	carreira["play_seconds"] = 0.0
	carreira["money_earned"] = 0.0
	carreira["fight"] = null
	return {
		"version": 3,
		"saved_at_unix": doc.get("saved_at_unix", 0),
		"state": {
			"career": carreira,
			"permanent": {"legacy_total": 0, "career_number": 1, "careers_finished": 0, "best_wins": 0, "belts_won": 0},
			"ending": null,
		},
	}


# v3 (Fase 3) -> v4 (Fase 4): Legado e Legado do `ending` pendente x10; nenhum nó; sem marca de revanche; Metrônomo 0.
# A carreira em andamento (inclusive luta pendente) fica intacta.
func _migrar_3_para_4(doc: Dictionary) -> Dictionary:
	var novo := doc.duplicate(true)
	var estado = novo.get("state", {})
	if not (estado is Dictionary):
		estado = {}
	var carreira = estado.get("career", {})
	if not (carreira is Dictionary):
		carreira = {}
	carreira["metronome_level"] = 0
	estado["career"] = carreira
	var perm = estado.get("permanent", {})
	if not (perm is Dictionary):
		perm = {}
	perm["legacy_total"] = _vezes_escala(perm.get("legacy_total", 0))
	perm["skill_nodes"] = []
	perm["revenge_opponent"] = ""
	estado["permanent"] = perm
	var fim = estado.get("ending", null)
	if fim is Dictionary:
		fim["legacy_gained"] = _vezes_escala(fim.get("legacy_gained", 0))
		fim["legacy_total"] = _vezes_escala(fim.get("legacy_total", 0))
		estado["ending"] = fim
	novo["state"] = estado
	return novo


# v4 (Fase 4) -> v5 (Fase 4b): a carreira em andamento ganha os 3 aparelhos (ids estáveis, não lê data/).
# Nada novo em permanent; ending.reason.unlock_tip ausente vale "".
func _migrar_4_para_5(doc: Dictionary) -> Dictionary:
	var novo := doc.duplicate(true)
	var estado = novo.get("state", {})
	if not (estado is Dictionary):
		estado = {}
	var carreira = estado.get("career", {})
	if not (carreira is Dictionary):
		carreira = {}
	carreira["apparatus_owned"] = ["punching_bag", "jump_rope", "treadmill"]
	estado["career"] = carreira
	novo["state"] = estado
	return novo


# v5 (Fase 4b) -> v6 (Fase 5): a carreira em andamento continua na garagem e sem arte, com tudo o que tinha.
# Nenhuma arte desbloqueada. Quem já tem o cinturão (career.belt) fica com pelo menos $1.000 para o MUDAR.
func _migrar_5_para_6(doc: Dictionary) -> Dictionary:
	var novo := doc.duplicate(true)
	var estado = novo.get("state", {})
	if not (estado is Dictionary):
		estado = {}
	var carreira = estado.get("career", {})
	if not (carreira is Dictionary):
		carreira = {}
	carreira["location"] = "garage"
	carreira["art"] = ""
	carreira["art_seconds"] = 0.0
	if carreira.get("belt", false) == true:
		var m = carreira.get("money", 0.0)
		var dinheiro := float(m) if (typeof(m) == TYPE_FLOAT or typeof(m) == TYPE_INT) and is_finite(float(m)) else 0.0
		if dinheiro < MIGRACAO_V6_DINHEIRO_MUDANCA:
			carreira["money"] = float(MIGRACAO_V6_DINHEIRO_MUDANCA)
	estado["career"] = carreira
	var perm = estado.get("permanent", {})
	if not (perm is Dictionary):
		perm = {}
	perm["arts_unlocked"] = []
	perm["last_art"] = ""
	estado["permanent"] = perm
	novo["state"] = estado
	return novo


# v6 (Fase 5) -> v7 (Fase 5.1): só acrescenta career.boxes = []. Save antigo não vira caixa:
# o que está em apparatus_owned e glove_level continua montado e valendo.
func _migrar_6_para_7(doc: Dictionary) -> Dictionary:
	var novo := doc.duplicate(true)
	var estado = novo.get("state", {})
	if not (estado is Dictionary):
		estado = {}
	var carreira = estado.get("career", {})
	if not (carreira is Dictionary):
		carreira = {}
	carreira["boxes"] = []
	estado["career"] = carreira
	novo["state"] = estado
	return novo


func _vezes_escala(v: Variant) -> Variant:
	if (typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT) or not is_finite(float(v)):
		return 0
	return int(round(clampf(float(v), 0.0, 1.0e14) * ESCALA_LEGADO_V4))


# --- Auxiliares ---

func _resultado(status: Status, lido: Dictionary, mensagem: String = "") -> Dictionary:
	var estado := {}
	var unix := 0
	if lido.has("doc"):
		var doc: Dictionary = lido.doc
		if doc.get("state") is Dictionary:
			estado = doc["state"]
		var t = doc.get("saved_at_unix", 0)
		if (typeof(t) == TYPE_FLOAT or typeof(t) == TYPE_INT) and is_finite(float(t)) and float(t) > 0.0:
			unix = int(t)
	if mensagem != "":
		push_warning("SaveStore: " + mensagem)
	return {"status": status, "estado": estado, "saved_at_unix": unix, "mensagem": mensagem}


func _futuro(lido: Dictionary) -> Dictionary:
	bloqueado = true
	return _resultado(Status.FUTURO, {},
		"Save de uma versão mais nova do jogo (v%s; este jogo lê até v%d): não foi aberto e não será sobrescrito." \
		% [String.num(lido.versao, 0) if lido.versao < 1.0e15 else str(lido.versao), VERSAO_ATUAL])


# Renomeia um arquivo corrompido para análise. Retorna o novo caminho.
func _guardar_corrompido(p: String) -> String:
	var base := "%s.corrompido-%d" % [p, int(Time.get_unix_time_from_system())]
	var destino := base
	var n := 1
	while FileAccess.file_exists(destino):
		destino = "%s-%d" % [base, n]
		n += 1
	var dir := DirAccess.open(pasta)
	if dir == null or dir.rename(p.get_file(), destino.get_file()) != OK:
		push_warning("SaveStore: não foi possível renomear o arquivo corrompido %s" % p)
		return p
	return destino


# v7 (Fase 5.1) -> v8 (Fase 5.2): só acrescenta career.crew_click = false (Grito da equipe não comprado).
func _migrar_7_para_8(doc: Dictionary) -> Dictionary:
	var novo := doc.duplicate(true)
	var estado = novo.get("state", {})
	if not (estado is Dictionary):
		estado = {}
	var carreira = estado.get("career", {})
	if not (carreira is Dictionary):
		carreira = {}
	carreira["crew_click"] = false
	estado["career"] = carreira
	novo["state"] = estado
	return novo
