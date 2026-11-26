class_name RondaLogica
extends RefCounted
## Ronda Noturna, noite "Estátua no telhado" (kind stealth_scare): lógica pura, sem tela e sem GameState.
## Referência das contas: classe Ronda de tools/sim/ronda_sim.py (mesma ordem dentro do passo). Números: data/ronda.json.
## Os ciclos do ladrão saem todos na criação (rng recebido) ou vêm injetados (testes): mesma lista + mesmas entradas = mesmo resultado.
## A tela lê `estado()`, manda `apertar()`/`soltar()` e escuta `pegar_eventos()`; quem faz o tempo passar é o tick do GameState
## (chama `avancar(dt)`; a UI não chama). Os testes chamam `passo(dt, segurando, apertou)` direto.

var fase := "contagem"  # "contagem" | "jogando" | "fim"
var t := 0.0  # segundos da noite decorridos (sem a contagem)
var ocorrencia := 0  # índice da ocorrência atual
var sustos := 0
var vistos := 0
var saiu := false
var historico: Array = []  # todos os eventos [nome, ocorrência, t] (testes e QA)

var _c: Dictionary  # bloco da noite
var _cont := 0.0
var _oc := "intro"  # "intro" | "jogando" | "susto" | "visto"
var _oc_t := 0.0
var _dist := 0.0
var _lad := "trabalha"  # "trabalha" | "aviso" | "olhando"
var _lad_t := 0.0
var _lad_dur := 0.0
var _ci := 0
var _ciclos: Array = []  # [ocorrência][ciclo] = [tempo de trabalho, aviso falso]
var _pend: Array = []  # eventos ainda não lidos pela UI (nomes)
var _btn := false
var _aperto := false
var _hold_perto := 0.0  # s segurando sem parar perto do fim do muro (só para a dica "SOLTE E CLIQUE!")

const PASSO_MAX := 1.0 / 60.0  # quadro grande é fatiado: o "visto" nunca pula um instante
const CICLOS := 40


func _init(cfg: Dictionary, rng: RandomNumberGenerator = null, ciclos: Array = []) -> void:
	_c = cfg
	_cont = float(cfg.countdown_s)
	if ciclos.is_empty():
		for o in cfg.occurrences:
			var lst: Array = []
			for _i in CICLOS:
				var gap: float = rng.randf_range(float(o.gap_min), float(o.gap_max)) if rng != null else (float(o.gap_min) + float(o.gap_max)) * 0.5
				lst.append([gap, (rng.randf() < float(o.fake_warn)) if rng != null else false])
			ciclos.append(lst)
	_ciclos = ciclos
	_nova_ocorrencia()


func _nova_ocorrencia() -> void:
	_oc = "intro"
	_oc_t = 0.0
	_dist = 0.0
	_lad = "trabalha"
	_lad_t = 0.0
	_ci = 0
	_lad_dur = float(_ciclos[ocorrencia][0][0]) if ocorrencia < _ciclos.size() else 0.0


func _evento(nome: String) -> void:
	historico.append([nome, ocorrencia, snappedf(t, 0.0001)])
	_pend.append(nome)


func _gap(i: int, ci: int) -> float:
	var l: Array = _ciclos[i]
	return float(l[mini(ci, l.size() - 1)][0])


func _falso(i: int, ci: int) -> bool:
	var l: Array = _ciclos[i]
	return bool(l[mini(ci, l.size() - 1)][1])


func _ladrao(dt: float) -> void:
	var o: Dictionary = _c.occurrences[ocorrencia]
	_lad_t += dt
	while _lad_t >= _lad_dur - 1.0e-9:
		_lad_t -= _lad_dur
		if _lad == "trabalha":
			_lad = "aviso"
			_lad_dur = float(o.warn_s)
			_evento("aviso")
		elif _lad == "aviso":
			if _falso(ocorrencia, _ci):
				_ci += 1
				_lad = "trabalha"
				_lad_dur = _gap(ocorrencia, _ci)
				_evento("aviso_falso")
			else:
				_lad = "olhando"
				_lad_dur = float(o.look_s)
				_evento("olhou")
		else:
			_ci += 1
			_lad = "trabalha"
			_lad_dur = _gap(ocorrencia, _ci)


## Olhando de verdade: depois da tolerância do começo do OLHANDO.
func olhando_valendo() -> bool:
	return _lad == "olhando" and _lad_t > float(_c.grace_s) + 1.0e-9


func _visto() -> void:
	_oc = "visto"
	_oc_t = 0.0
	vistos += 1
	_evento("visto")


## Um passo de `dt` s. `segurando` = botão pressionado; `apertou` = borda de descida do botão neste quadro.
## Depois da regra, mede há quanto tempo o botão está segurado perto do fim do muro (D2: só alimenta a dica, nunca a regra).
func passo(dt: float, segurando: bool, apertou: bool) -> void:
	_passo_regra(dt, segurando, apertou)
	if segurando and fase == "jogando" and _oc == "jogando" and _dist >= float(_c.scare_zone) - 1.0e-9:
		_hold_perto += dt
	else:
		_hold_perto = 0.0


func _passo_regra(dt: float, segurando: bool, apertou: bool) -> void:
	if fase == "fim":
		return
	if fase == "contagem":
		_cont -= dt
		if _cont <= 1.0e-9:
			fase = "jogando"
		return
	t += dt
	if t >= float(_c.night_s) - 1.0e-9:
		fase = "fim"
		_evento("fim_tempo")
		return
	if _oc == "susto" or _oc == "visto":
		_oc_t += dt
		var dur := float(_c.scare_anim_s) if _oc == "susto" else float(_c.seen_anim_s)
		if _oc_t >= dur - 1.0e-9:
			ocorrencia += 1
			if ocorrencia >= _c.occurrences.size():
				fase = "fim"
				_evento("fim")
			else:
				_nova_ocorrencia()
				_evento("proxima")
		return
	if _oc == "intro":
		_oc_t += dt
		if _oc_t >= float(_c.intro_s) - 1.0e-9:
			_oc = "jogando"
		return
	_ladrao(dt)
	if apertou and _dist >= float(_c.scare_zone) - 1.0e-9:
		if olhando_valendo():
			_visto()
		else:
			_oc = "susto"
			_oc_t = 0.0
			sustos += 1
			_evento("susto")
		return
	if segurando and _dist < 1.0:
		_dist = minf(1.0, _dist + float(_c.advance_per_s) * dt)
		if olhando_valendo():
			_visto()


# ---------------- entradas da UI ----------------
## Botão desceu (mouse ou espaço). Perto do fim do muro, este aperto é o SUSTO.
func apertar() -> void:
	if not _btn:
		_aperto = true
	_btn = true


func soltar() -> void:
	_btn = false


## O tick do GameState chama todo quadro: fatia `dt` e usa o botão guardado.
func avancar(dt: float) -> void:
	var resto := dt
	var primeiro := true
	while resto > 1.0e-9 and fase != "fim":
		var d := minf(resto, PASSO_MAX)
		resto -= d
		var ap := _aperto and primeiro
		if primeiro:
			_aperto = false
			primeiro = false
		passo(d, _btn, ap)


## SAIR: a noite acaba na hora; sustos já feitos contam, o bônus de ronda limpa só com todos.
func sair() -> void:
	if fase == "fim":
		return
	saiu = true
	fase = "fim"
	_evento("sair")


# ---------------- leitura ----------------
func estado() -> Dictionary:
	var o: Dictionary = _c.occurrences[mini(ocorrencia, _c.occurrences.size() - 1)]
	var jogando := fase == "jogando" and _oc == "jogando"
	return {"fase": fase, "contagem": maxf(_cont, 0.0), "restante": maxf(float(_c.night_s) - t, 0.0),
		"ocorrencia": ocorrencia, "id": str(o.id), "oc_fase": _oc, "distancia": _dist,
		"perto": jogando and _dist >= float(_c.scare_zone) - 1.0e-9,
		"ladrao": _lad, "ladrao_frac": clampf(_lad_t / _lad_dur, 0.0, 1.0) if _lad_dur > 0.0 else 0.0,
		"sustos": sustos, "vistos": vistos, "segurando": _btn, "total": _c.occurrences.size(),
		# D2: segurou perto por hold_hint_s sem soltar = a tela mostra "SOLTE E CLIQUE!" (some ao soltar, no SUSTO, no VISTO e no fim)
		"segurando_perto_s": _hold_perto, "hold_hint_s": float(_c.get("hold_hint_s", 0.6)),
		"dica_soltar": jogando and _hold_perto >= float(_c.get("hold_hint_s", 0.6)) - 1.0e-9}


## Eventos desde a última leitura (nomes): aviso, aviso_falso, olhou, susto, visto, proxima, fim, fim_tempo, sair.
func pegar_eventos() -> Array:
	var r := _pend.duplicate()
	_pend.clear()
	return r


## Lenda da ronda: piso + 1 por SUSTO + bônus com todos os SUSTOS (vale no SAIR também).
func lenda() -> int:
	var L: Dictionary = _c.legend
	var v := int(L.floor) + int(L.per_scare) * sustos
	if sustos >= _c.occurrences.size():
		v += int(L.clean_bonus)
	return v


func resultado() -> Dictionary:
	return {"sustos": sustos, "vistos": vistos, "feitas": sustos + vistos, "lenda": lenda()}
