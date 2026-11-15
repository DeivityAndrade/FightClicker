class_name CenaPlayer
extends Node
## Player de cenas por dados (Fase 6b1). Toca a linha do tempo compilada por CenaDados e AVISA a interface por sinais:
## ele não desenha nada. Executa só os passos que a 6b1 usa (wait, say, move, pose, face, show/hide, sound, camera, ui,
## prop, shake, open_screen, return_control, parallel, sequence, reactions e end_state); os outros tipos do formato
## só passam pelo validador e saem em `passo_ignorado`. Contrato completo: docs/fases/fase6b1-api.md.
##
## Uso: var p := CenaPlayer.new(GameState); add_child(p); p.iniciar(GameState.sucessao_cena()).
## Em testes: p.ler_teclado = false e p.avancar(delta) à mão.

## Um passo para a interface executar (pose, move, say, face, show, hide, sound, camera, ui, prop, shake).
## Campos comuns: tipo, t. O resto vem do passo (ver a API). `origem_estado` = true quando veio de um estado aplicado.
signal evento(ev: Dictionary)
## Um estado inteiro (open_screen.state ao pular, end_state, estado do checkpoint) foi aplicado de uma vez.
## `origem`: "tela" | "final" | "checkpoint" | "inicio".
signal estado_aplicado(estado: Dictionary, origem: String)
## A cena chegou no open_screen: abrir a tela (a cena fica parada até o jogo sair de "creating").
signal tela_pedida(tela: String, estado: Dictionary)
signal controle_devolvido()
signal cena_iniciada(id: String)
signal cena_terminada(pulada: bool)
## Progresso de segurar ESC/ESPAÇO (0..1), para o anel do botão PULAR. 0 ao soltar.
signal pular_progresso(p: float)
signal reacao_iniciada(quando: String)
signal reacao_terminada(quando: String)
signal reacao_cancelada(quando: String)
signal reacoes_descartadas()
signal passo_ignorado(tipo: String)

const EPS := 1.0e-6

var gs: Node
var dados: CenaDados
var cena: Dictionary = {}
var comp: Dictionary = {}
var ativa := false  # a linha do tempo principal está tocando (ou parada na tela)
var ler_teclado := true  # _process lê ESC/ESPAÇO; testes desligam
var automatico := true  # _process chama avancar(delta); testes desligam

var _seg := 0
var _t := 0.0
var _i := 0
var _esperando_tela := false
var _devolveu := false
var _hold := 0.0
var _armadas: Array = []
var _corredores: Array = []  # reações tocando: {quando, eventos, t, i, dur}
var _mundo: Dictionary = {}
var _ignorados: Dictionary = {}


func _init(p_gs: Node = null, p_dados: CenaDados = null) -> void:
	gs = p_gs
	dados = p_dados


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if automatico:
		avancar(delta)
	if ler_teclado:
		segurar_pular(Input.is_key_pressed(KEY_ESCAPE) or Input.is_key_pressed(KEY_SPACE), delta)


# --- Início ---

## Começa a cena `id`. Com `desde_checkpoint` ("depois_criar"), aplica o estado da tela e toca dali em diante.
## false se a cena não existe ou o checkpoint não existe.
func iniciar(id: String, desde_checkpoint: String = "") -> bool:
	_parar_tudo()
	if dados == null:
		dados = CenaDados.novo(gs.dialogos if gs != null else null, gs.dados.ui if gs != null else {})
	cena = CenaDados.carregar_cena(id)
	if cena.is_empty():
		push_warning("CenaPlayer: cena inexistente: " + id)
		return false
	comp = dados.compilar(cena, _contexto())
	_mundo = _mundo_inicial()
	_seg = 0
	_t = 0.0
	_i = 0
	_devolveu = false
	_esperando_tela = false
	if desde_checkpoint != "":
		if not comp.checkpoints.has(desde_checkpoint):
			push_warning("CenaPlayer: checkpoint inexistente: %s/%s" % [id, desde_checkpoint])
			return false
		var cp: Dictionary = comp.checkpoints[desde_checkpoint]
		_seg = int(cp.seg)
		_t = float(cp.t)
		while _i < comp.eventos.size() and (int(comp.eventos[_i].seg) < _seg or (int(comp.eventos[_i].seg) == _seg and float(comp.eventos[_i].t) < _t - EPS)):
			_i += 1
		ativa = true
		cena_iniciada.emit(id)
		_aplicar_estado(cp.get("state", {}), "checkpoint")
	else:
		ativa = true
		cena_iniciada.emit(id)
		estado_aplicado.emit(_mundo.duplicate(true), "inicio")
	_ligar_gs()
	return true


func _contexto() -> Dictionary:
	if gs == null:
		return {}
	var fim_anterior = gs.escola.get("last_end", null)
	return {"last_campaign_end": str(fim_anterior.get("kind", "")) if fim_anterior is Dictionary else "",
		"milestones": gs.escola.get("milestones", {}), "disciple_name": str(gs.nome_lutador()).to_lower()}


## Estado do palco ao abrir a tela de uma cena, SEM tocar a cena: serve para abrir um save que fechou na tela de criação.
## Devolve {tela, estado, palco, atores} ou {} se a cena não tem tela.
func estado_da_tela(id: String) -> Dictionary:
	if dados == null:
		dados = CenaDados.novo(gs.dialogos if gs != null else null, gs.dados.ui if gs != null else {})
	var c := CenaDados.carregar_cena(id)
	if c.is_empty():
		return {}
	var k := dados.compilar(c, _contexto())
	if k.telas.is_empty():
		return {}
	return {"tela": str(k.telas[0].tela), "estado": k.telas[0].state, "palco": c.get("stage", {}), "atores": c.get("actors", {})}


## Aplica o `end_state` da cena `id` sem tocá-la (abrir um save que fechou na chegada) e devolve o controle.
func aplicar_final_sem_tocar(id: String) -> bool:
	if not iniciar(id):
		return false
	_aplicar_final()
	return true


func _mundo_inicial() -> Dictionary:
	var m := {"atores": {}, "adereços": {}, "camera": {"scale": 1}, "ui": "show_all", "sons_em_laco": [], "liberados": []}
	for id in cena.get("actors", {}):
		var a: Dictionary = cena.actors[id]
		m.atores[id] = {"pos": a.get("pos", [0, 0]), "facing": a.get("facing", "right"), "anim": a.get("anim", "idle"),
			"glove": a.get("glove", ""), "visible": bool(a.get("visible", true))}
	for id in cena.get("stage", {}).get("props", {}):
		var p: Dictionary = cena.stage.props[id]
		m["adereços"][id] = {"visible": bool(p.get("visible", true)), "anim": p.get("anim", ""), "frame": p.get("frame", null)}
	return m


## Pivôs, camadas e ordem de desenho dos adereços da porta (manifest). A interface segue isto, não os números da cena.
func desenho_da_garagem() -> Dictionary:
	if dados == null:
		dados = CenaDados.novo(gs.dialogos if gs != null else null, gs.dados.ui if gs != null else {})
	return dados.desenho_da_garagem()


## Espelho do que está em cena agora: {atores {id: {pos, facing, anim, glove, visible}}, adereços, camera, ui,
## sons_em_laco, liberados}. A interface pode ler a qualquer momento (ex.: ao montar os nós).
func mundo() -> Dictionary:
	return _mundo.duplicate(true)


func _ligar_gs() -> void:
	if gs == null:
		return
	if not gs.toques_mentor_pedidos.is_connected(_ao_pedir_toques):
		gs.toques_mentor_pedidos.connect(_ao_pedir_toques)
	if not gs.toques_mentor_cancelados.is_connected(_ao_cancelar_toques):
		gs.toques_mentor_cancelados.connect(_ao_cancelar_toques)
	if not gs.sucessao_mudou.is_connected(_ao_mudar_sucessao):
		gs.sucessao_mudou.connect(_ao_mudar_sucessao)


func _parar_tudo() -> void:
	ativa = false
	_corredores.clear()
	_armadas.clear()
	_esperando_tela = false
	_hold = 0.0


# --- Relógio ---

func avancar(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	_tick_reacoes(delta)
	if not ativa or _esperando_tela:
		return
	_t += delta
	while _i < comp.eventos.size() and int(comp.eventos[_i].seg) == _seg and float(comp.eventos[_i].t) <= _t + EPS:
		var ev: Dictionary = comp.eventos[_i]
		_i += 1
		_executar(ev)
		if _esperando_tela or not ativa:
			return
	var proximo_no_trecho: bool = _i < comp.eventos.size() and int(comp.eventos[_i].seg) == _seg
	if not proximo_no_trecho and _seg == comp.segmentos.size() - 1 and _t >= float(comp.segmentos[_seg].duracao) - EPS:
		_terminar(false)


## A tela (criação) fechou: a cena segue do trecho seguinte. Também acontece sozinha quando o jogo sai de "creating".
func tela_fechada() -> void:
	if not _esperando_tela:
		return
	_esperando_tela = false
	_seg += 1
	_t = 0.0


func _ao_mudar_sucessao(estado: String) -> void:
	if _esperando_tela and estado in ["scene_2", "arriving"]:
		tela_fechada()


# --- Execução dos passos ---

func _executar(ev: Dictionary) -> void:
	var tipo := str(ev.tipo)
	match tipo:
		"open_screen":
			_esperando_tela = true
			if gs != null:
				gs.sucessao_tela_aberta()
			tela_pedida.emit(str(ev.tela), ev.get("state", {}))
		"return_control":
			_devolver_controle()
		"pose", "move", "face", "show", "hide", "sound", "camera", "ui", "prop", "shake", "say":
			_espelhar(ev)
			evento.emit(ev)
		_:
			if not _ignorados.has(tipo):
				_ignorados[tipo] = true
				push_warning("CenaPlayer: passo '%s' ainda não é executado (só validado)." % tipo)
			passo_ignorado.emit(tipo)


func _espelhar(ev: Dictionary) -> void:
	var tipo := str(ev.tipo)
	var a: Dictionary = _mundo.atores.get(str(ev.get("ator", "")), {})
	match tipo:
		"pose":
			if not a.is_empty():
				a["anim"] = str(ev.anim)
				if str(ev.get("facing", "")) != "":
					a["facing"] = str(ev.facing)
				if str(ev.get("glove", "")) != "":
					a["glove"] = str(ev.glove)
		"move":
			if not a.is_empty():
				a["pos"] = ev.to
				a["anim"] = str(ev.anim)
				if str(ev.get("facing", "")) != "":
					a["facing"] = str(ev.facing)
		"face":
			if not a.is_empty() and str(ev.get("facing", "")) != "":
				a["facing"] = str(ev.facing)
		"show", "hide":
			if str(ev.get("ator", "")) != "":
				if not a.is_empty():
					a["visible"] = tipo == "show"
			elif _mundo["adereços"].has(str(ev.get("adereco", ""))):
				_mundo["adereços"][str(ev.adereco)]["visible"] = tipo == "show"
		"prop":
			var p: Dictionary = _mundo["adereços"].get(str(ev.id), {})
			if not p.is_empty():
				if ev.get("visible", null) != null:
					p["visible"] = bool(ev.visible)
				if str(ev.get("anim", "")) != "":
					p["anim"] = str(ev.anim)
				if ev.get("frame", null) != null:
					p["frame"] = ev.frame
		"camera":
			_mundo["camera"] = {"scale": int(ev.scale), "rect": ev.get("rect", [])}
		"ui":
			_mundo["ui"] = "hide_all" if ev.get("hide", null) != null else "show_all"
		"sound":
			var laco: Array = _mundo["sons_em_laco"]
			var id := str(ev.id)
			if bool(ev.get("stop", false)):
				laco.erase(id)
			elif bool(ev.get("loop", false)) and not (id in laco):
				laco.append(id)


# Aplica um estado de uma vez (ao pular até a tela, ao pular até o fim, ao começar do checkpoint).
func _aplicar_estado(e: Dictionary, origem: String) -> void:
	var mao: String = str(dados.cfg.get("end_state_hand", "hand_to_game"))
	for id in e.get("actors", {}):
		var v = e.actors[id]
		var a: Dictionary = _mundo.atores.get(str(id), {})
		if v is Dictionary:
			for k in v:
				a[str(k)] = v[k]
			if v.get("pos", null) is String:  # ponto nomeado (mentor_spot) vira [x, y]
				a["pos"] = dados.ponto(str(v.pos))
		elif v is String and v == mao:
			if not (str(id) in _mundo.liberados):
				_mundo.liberados.append(str(id))
	for id in e.get("props", {}):
		var v = e.props[id]
		var p: Dictionary = _mundo["adereços"].get(str(id), {})
		if v is Dictionary:
			for k in v:
				p[str(k)] = v[k]
		elif v is String and v == mao:
			if not (("prop:" + str(id)) in _mundo.liberados):
				_mundo.liberados.append("prop:" + str(id))
	if e.has("camera"):
		_mundo["camera"] = e.camera
	if e.has("ui"):
		_mundo["ui"] = str(e.ui)
	var sons = e.get("sounds", {})
	estado_aplicado.emit(e.duplicate(true), origem)
	if sons is Dictionary:
		for s in sons.get("stop", []):
			_mundo["sons_em_laco"].erase(str(s))
			evento.emit({"tipo": "sound", "id": str(s), "stop": true, "loop": false, "volume": 1.0, "fade": 0.0, "t": 0.0, "origem_estado": true})
		for s in sons.get("loop", []):
			if not (str(s) in _mundo["sons_em_laco"]):
				_mundo["sons_em_laco"].append(str(s))
			evento.emit({"tipo": "sound", "id": str(s), "stop": false, "loop": true, "volume": 0.5, "fade": 0.0, "t": 0.0, "origem_estado": true})


func _devolver_controle() -> void:
	if _devolveu:
		return
	_devolveu = true
	# Reações armadas ANTES de devolver: o 1º clique vale no mesmo quadro.
	_armadas = comp.reacoes.duplicate(true)
	_mundo["ui"] = "show_all"
	controle_devolvido.emit()
	if gs != null:
		gs.sucessao_terminou()


func _terminar(pulada: bool) -> void:
	if not ativa:
		return
	ativa = false
	cena_terminada.emit(pulada)


# --- Pular ---

## O jogador pode pular agora? (cena de controle preso, antes do return_control, fora da tela de criação).
func pode_pular() -> bool:
	return ativa and bool(cena.get("blocking", true)) and not _devolveu and not _esperando_tela


## ESC ou ESPAÇO segurado: soma o tempo; ao chegar em `skip.hold_seconds` (0,5 s) pula. Soltar zera.
func segurar_pular(segurando: bool, delta: float) -> void:
	if not segurando or not pode_pular():
		if _hold > 0.0:
			_hold = 0.0
			pular_progresso.emit(0.0)
		return
	var alvo := float(dados.cfg.get("skip", {}).get("hold_seconds", 0.5))
	_hold += delta
	pular_progresso.emit(clampf(_hold / alvo, 0.0, 1.0))
	if _hold >= alvo - EPS:
		_hold = 0.0
		pular_progresso.emit(0.0)
		pular()


## PULAR (botão ou tecla segurada). Antes da tela de criação: vai até ela com o estado dela. Depois dela: aplica o
## `end_state` e devolve o controle (as reações continuam armadas). Na tela de criação não faz nada.
func pular() -> bool:
	if not pode_pular():
		return false
	if _seg < comp.telas.size():
		# Há uma tela à frente neste trecho: vai até ela.
		var tela: Dictionary = comp.telas[_seg]
		_aplicar_estado(tela.state, "tela")
		while _i < comp.eventos.size() and not (int(comp.eventos[_i].seg) == _seg and str(comp.eventos[_i].tipo) == "open_screen"):
			_i += 1
		if _i < comp.eventos.size():
			var ev: Dictionary = comp.eventos[_i]
			_i += 1
			_t = float(ev.t)
			_executar(ev)
		return true
	_aplicar_final()
	return true


func _aplicar_final() -> void:
	_aplicar_estado(cena.get("end_state", {}), "final")
	_mundo["camera"] = {"scale": 1}
	if not _devolveu:
		_devolver_controle()
	_terminar(true)


# --- Reações ---

func _ao_pedir_toques(plano: Dictionary) -> void:
	# O toque do 1º clique É a reação da cena: a cena toca (e a interface não repete os toques sozinha).
	if str(plano.get("cena", "")) != str(comp.get("id", "-")) or str(plano.get("momento", "")) != "first_click":
		return
	_disparar_reacao("first_click")


func _ao_cancelar_toques() -> void:
	for r in _corredores.duplicate():
		_cancelar_corredor(r)


func _disparar_reacao(quando: String) -> void:
	for r in _armadas:
		if str(r.when) == quando:
			if bool(r.once):
				_armadas.erase(r)
			_corredores.append({"quando": quando, "eventos": r.eventos, "t": 0.0, "i": 0, "dur": float(r.duracao)})
			reacao_iniciada.emit(quando)
			_tick_corredor(_corredores.back(), 0.0)
			return


func _tick_reacoes(delta: float) -> void:
	if gs != null and not _armadas.is_empty():
		var local := str(cena.get("stage", {}).get("location", ""))
		if not gs.luta.is_empty() or (local != "" and gs.local_id != local):
			_armadas.clear()  # luta ou troca de local antes do 1º clique: a sala fica no end_state
			reacoes_descartadas.emit()
		else:
			for r in _armadas.duplicate():
				if str(r.when) == "idle_seconds" and gs.sala_ativa() and gs.segundos_ocioso() >= float(r.seconds):
					_disparar_reacao("idle_seconds")
	for r in _corredores.duplicate():
		_tick_corredor(r, delta)


func _tick_corredor(r: Dictionary, delta: float) -> void:
	r.t += delta
	while r.i < r.eventos.size() and float(r.eventos[r.i].t) <= r.t + EPS:
		var ev: Dictionary = r.eventos[r.i]
		r.i += 1
		_executar(ev)
	if r.i >= r.eventos.size() and r.t >= r.dur - EPS:
		_corredores.erase(r)
		reacao_terminada.emit(str(r.quando))


# Cancelar: para os passos que faltam, mas deixa a pose de descanso (a que fica em laço) como estava prevista.
func _cancelar_corredor(r: Dictionary) -> void:
	_corredores.erase(r)
	for k in range(r.i, r.eventos.size()):
		var ev: Dictionary = r.eventos[k]
		if str(ev.tipo) == "pose" and bool(ev.get("loop", false)):
			_executar(ev)
	reacao_cancelada.emit(str(r.quando))
