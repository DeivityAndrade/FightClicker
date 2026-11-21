class_name ChoqueLogica
extends RefCounted
## Fase 7a2: lógica pura do Choque (sparring em cabo de guerra). Sem tela, sem GameState: a tela só lê `estado()` e manda
## `apertar()` / `soltar()`. Referência das contas: jogar_choque() de tools/sim/fase7a2_sim.py; números em data/minigames.json.
##  Boxe: apertar = clique (empurra); segurar >= hold_is_guard_s = guarda (anula a rajada).
##  Jiu-jitsu: segurar = puxa; soltar = não puxa (e anula a puxada forte dele).
##  Muay Thai (7b1): batida a cada `beat_s`; clique a até `window_s` de uma batida ainda não usada = NO TEMPO (combo +1; o 3º vira
##  CHUTE); clique fora do tempo = empurrão fraco e o combo zera; segurar = guarda, como o Boxe. Referência: jogar_choque_mt (fase7b1_sim.py).
## O roteiro de padrões (rajada/pausa/finta) é sorteado inteiro na criação, com o rng recebido: com a mesma semente e as
## mesmas entradas o resultado é idêntico. Depois disso a lógica não sorteia nada.

const PASSO := 0.02  # passo fixo da conta (igual ao simulador)

var arte := "boxing"  # "boxing" | "bjj" | "muay_thai"
var nivel := 0
var fase := "contagem"  # "contagem" | "jogando" | "fim"
var barra := 0.0  # -1 (ele te encostou) .. +1 (você encostou ele)
var folego := 1.0
var pontos := 0
var pontos_dele := 0
var tempo := 0.0  # segundos de jogo decorridos (sem a contagem)
var saiu := false  # terminou por SAIR antes do tempo
var combo := 0  # Muay Thai: cliques no tempo seguidos (volta a 0 no chute, no clique errado e a cada ponto)
var chutes := 0  # Muay Thai: chutes dados (3º clique no tempo)
var no_tempo := 0
var fora_do_tempo := 0

var _c: Dictionary  # bloco spar do JSON
var _v: Dictionary  # variante (boxing | bjj | muay_thai)
var _usadas := {}  # Muay Thai: batidas já aproveitadas (k -> true)
var _l: Dictionary  # linha do nível
var _contagem := 0.0
var _roteiro: Array = []  # [{tipo, a, i, f}]: aviso de a até i, ativo de i até f
var _acc := 0.0
var _congelado := 0.0
var _seg := false
var _seg_t := 0.0
var _anunciado := -1  # último padrão com aviso já anunciado
var _virou := -1  # última finta já virada
var _ativo_anunciado := -1
var _eventos: Array = []


func _init(spar: Dictionary, arte_id: String, nivel_jogo: int, rng: RandomNumberGenerator) -> void:
	_c = spar
	arte = arte_id if arte_id in ["boxing", "bjj", "muay_thai"] and _c.variants.has(arte_id) else "boxing"
	_v = _c.variants[arte]
	nivel = clampi(nivel_jogo, 0, _c.levels.size() - 1)
	_l = _c.levels[nivel]
	_contagem = float(_c.countdown_s)
	_sortear_roteiro(rng)


func _sortear_roteiro(rng: RandomNumberGenerator) -> void:
	var t := rng.randf_range(_l.gap_min, _l.gap_max)
	var total: float = _l.w_burst + _l.w_pause + _l.w_feint
	while t < float(_c.duration_s) and total > 0.0:
		var r := rng.randf() * total
		var tipo := "feint"
		if r < _l.w_burst:
			tipo = "burst"
		elif r < _l.w_burst + _l.w_pause:
			tipo = "pause"
		var aviso: float = _l.pause_warn_s if tipo == "pause" else _l.warn_s
		var ativo: float = _l.burst_s if tipo == "burst" else (_l.pause_s if tipo == "pause" else _l.feint_pause_s)
		_roteiro.append({"tipo": tipo, "a": t, "i": t + aviso, "f": t + aviso + ativo})
		t += aviso + ativo + rng.randf_range(_l.gap_min, _l.gap_max)


# ---------------- entradas ----------------
## Boxe: um clique (e começa a segurar). JJ: começa a puxar. Ignorado na contagem, no fim e no reinício depois do ponto.
func apertar() -> void:
	if fase != "jogando":
		return
	if _seg:
		return
	_seg = true
	_seg_t = 0.0
	if arte == "muay_thai" and _congelado <= 0.0:
		_clique_muay_thai()
	elif arte == "boxing" and _congelado <= 0.0:
		var pausa := _padrao_ativo_tipo() in ["pause", "feint"]
		barra += float(_v.push_per_click) * _forca() * (float(_c.counter_mult) if pausa else 1.0)
		folego = maxf(0.0, folego - float(_v.breath_cost_per_click))
		_eventos.append("contragolpe" if pausa else "clique")
		_checar_ponto()


## Muay Thai: um clique. A batida k cai em k x beat_s desde o fim da contagem (k >= 1); `tempo` é o relógio do jogo.
func _clique_muay_thai() -> void:
	var pausa := _padrao_ativo_tipo() in ["pause", "feint"]
	var mult := float(_c.counter_mult) if pausa else 1.0
	var forca := _forca()
	var beat := float(_v.beat_s)
	var k := int(round(tempo / beat))
	if k >= 1 and absf(tempo - float(k) * beat) <= float(_v.window_s) and not _usadas.has(k):
		_usadas[k] = true
		combo += 1
		no_tempo += 1
		if combo >= int(_v.combo_kick):
			barra += float(_v.push_kick) * forca * mult
			folego = maxf(0.0, folego - float(_v.breath_cost_per_click) - float(_v.breath_cost_kick))
			combo = 0
			chutes += 1
			_eventos.append("chute")
		else:
			barra += float(_v.push_on_beat) * forca * mult
			folego = maxf(0.0, folego - float(_v.breath_cost_per_click))
			_eventos.append("no_tempo")
	else:
		fora_do_tempo += 1
		combo = 0
		barra += float(_v.push_off_beat) * forca * mult
		folego = maxf(0.0, folego - float(_v.breath_cost_per_click))
		_eventos.append("fora_do_tempo")
	if pausa:
		_eventos.append("contragolpe")
	_checar_ponto()


## Larga o botão (Boxe: fim da guarda; JJ: solta).
func soltar() -> void:
	_seg = false
	_seg_t = 0.0


## SAIR: encerra já, com os pontos de agora (vale na contagem também: 0 pontos).
func sair() -> void:
	if fase != "fim":
		saiu = true
		_terminar()


## Avança o tempo (a conta anda em passos fixos de 0,02 s).
func passo(delta: float) -> void:
	if fase == "fim" or delta <= 0.0 or not is_finite(delta):
		return
	_acc += delta
	while _acc >= PASSO - 1.0e-12 and fase != "fim":
		_acc -= PASSO
		_um_passo()


func _um_passo() -> void:
	if fase == "contagem":
		_contagem -= PASSO
		if _contagem <= 1.0e-9:
			fase = "jogando"
		return
	_avisos()
	if _congelado > 0.0:
		_congelado -= PASSO
		tempo += PASSO
		_checar_fim()
		return
	var tipo := _padrao_ativo_tipo()
	var rajada := tipo == "burst"
	var pausa := tipo in ["pause", "feint"]
	var empurra: float = _l.base_push
	if rajada:
		empurra = _l.burst_push
	elif pausa:
		empurra = 0.0
	if _seg:
		_seg_t += PASSO
	if arte != "bjj":  # Boxe e Muay Thai: clicar; a guarda anula a rajada
		folego = minf(1.0, folego + float(_v.breath_recover_per_s) * PASSO)
		if rajada and guardando():
			empurra *= float(_c.read_mult)
	else:
		if _seg:
			barra += float(_v.pull_per_s) * _forca() * (float(_c.counter_mult) if pausa else 1.0) * PASSO
			folego = maxf(0.0, folego - float(_v.breath_drain_per_s) * (float(_v.burst_hold_drain_mult) if rajada else 1.0) * PASSO)
		else:
			folego = minf(1.0, folego + float(_v.breath_recover_per_s) * PASSO)
			if rajada:
				empurra *= float(_c.read_mult)
	barra -= empurra * PASSO
	tempo += PASSO
	_checar_ponto()
	_checar_fim()


func _checar_ponto() -> void:
	if barra >= 1.0 or barra <= -1.0:
		combo = 0  # Muay Thai: ponto marcado ou sofrido zera o combo
	if barra >= 1.0:
		pontos += 1
		barra = 0.0
		_congelado = float(_c.reset_s)
		_eventos.append("ponto_jogador")
	elif barra <= -1.0:
		pontos_dele += 1
		barra = 0.0
		_congelado = float(_c.reset_s)
		_eventos.append("ponto_dele")


func _checar_fim() -> void:
	if tempo >= float(_c.duration_s) - 1.0e-9:
		_terminar()


func _terminar() -> void:
	fase = "fim"
	_seg = false
	_eventos.append("fim")


# Eventos de aviso: uma vez por padrão (aviso, virada da finta, começo do efeito).
func _avisos() -> void:
	for k in range(maxi(_anunciado, 0), _roteiro.size()):
		var p: Dictionary = _roteiro[k]
		if tempo < float(p.a):
			break
		if k > _anunciado and tempo >= float(p.a):
			_anunciado = k
			_eventos.append("aviso_" + str(p.tipo))
		if p.tipo == "feint" and k > _virou and tempo >= float(p.a) + float(_l.warn_s) * 0.5:
			_virou = k
			_eventos.append("finta_virou")
		if k > _ativo_anunciado and tempo >= float(p.i):
			_ativo_anunciado = k
			_eventos.append("inicio_" + str(p.tipo))


# ---------------- leitura ----------------
func _forca() -> float:
	return float(_v.weak_min) + (1.0 - float(_v.weak_min)) * folego


## Boxe e Muay Thai: segurando há tempo de guarda. JJ: sempre false (lá segurar é puxar).
func guardando() -> bool:
	return arte != "bjj" and _seg and _seg_t >= float(_c.hold_is_guard_s)


func _padrao_em(t: float) -> Dictionary:
	for p in _roteiro:
		if float(p.a) <= t and t < float(p.f):
			return p
		if float(p.a) > t:
			break
	return {}


func _padrao_ativo_tipo() -> String:
	var p := _padrao_em(tempo)
	if p.is_empty() or tempo < float(p.i):
		return ""
	return str(p.tipo)


## Tudo que a tela precisa, num quadro.
## padrao: "" | "burst" | "pause" | "feint" (qual padrão está no ar, em aviso ou ativo); momento: "" | "aviso" | "ativo".
## sinal: "" | "red" | "white" (cor do "!" no aviso: rajada vermelho, pausa branco, finta vermelho que vira branco na metade).
func estado() -> Dictionary:
	var p := _padrao_em(tempo) if fase == "jogando" else {}
	var padrao := "" if p.is_empty() else str(p.tipo)
	var momento := ""
	var sinal := ""
	var frac := 0.0
	if not p.is_empty():
		if tempo < float(p.i):
			momento = "aviso"
			frac = clampf((tempo - float(p.a)) / maxf(float(p.i) - float(p.a), 1.0e-6), 0.0, 1.0)
			sinal = "white" if p.tipo == "pause" else ("red" if (p.tipo == "burst" or frac < 0.5) else "white")
		else:
			momento = "ativo"
	return {"fase": fase, "contagem": maxf(_contagem, 0.0), "tempo": tempo, "restante": maxf(float(_c.duration_s) - tempo, 0.0),
		"barra": barra, "folego": folego, "forca": _forca(), "pontos": pontos, "pontos_dele": pontos_dele,
		"meta": int(_c.points_goal), "congelado": _congelado > 0.0, "padrao": padrao, "momento": momento, "sinal": sinal,
		"aviso_frac": frac, "x2": momento == "ativo" and padrao in ["pause", "feint"] and _congelado <= 0.0,
		"guarda": guardando(), "segurando": _seg, "arte": arte, "nivel": nivel,
		# Muay Thai: combo (0-2), chutes, batida (período, fração dentro da batida 0..1, próxima batida em s) e se agora vale "no tempo"
		"combo": combo, "chutes": chutes, "beat_s": _beat(), "batida_frac": _batida_frac(), "proxima_batida_s": _proxima_batida(),
		"na_janela": _na_janela()}


func _beat() -> float:
	return float(_v.get("beat_s", 0.0))


## Fração (0..1) do tempo dentro da batida atual; 0 fora do Muay Thai ou fora do jogo.
func _batida_frac() -> float:
	if arte != "muay_thai" or fase != "jogando":
		return 0.0
	return fposmod(tempo, _beat()) / _beat()


## Segundos até a próxima batida (a 1ª cai em beat_s). -1 fora do Muay Thai.
func _proxima_batida() -> float:
	if arte != "muay_thai" or fase != "jogando":
		return -1.0
	return _beat() - fposmod(tempo, _beat())


## Um clique agora contaria "no tempo"? (batida ainda não usada a até window_s de distância)
func _na_janela() -> bool:
	if arte != "muay_thai" or fase != "jogando" or _congelado > 0.0:
		return false
	var k := int(round(tempo / _beat()))
	return k >= 1 and absf(tempo - float(k) * _beat()) <= float(_v.window_s) and not _usadas.has(k)


## Eventos desde a última chamada (e esvazia): "clique", "contragolpe", "ponto_jogador", "ponto_dele", "aviso_burst",
## "aviso_pause", "aviso_feint", "finta_virou", "inicio_burst", "inicio_pause", "inicio_feint", "fim".
## Muay Thai troca "clique" por "no_tempo", "chute" (3º no tempo) e "fora_do_tempo" ("contragolpe" também sai na pausa).
func pegar_eventos() -> Array:
	var e := _eventos
	_eventos = []
	return e


func roteiro() -> Array:
	return _roteiro.duplicate(true)


## 0,25 + 0,75 x min(1, pontos / meta): o piso vale só por ir.
func nota() -> float:
	var pis := float(_c.reward.floor)
	return pis + (1.0 - pis) * minf(1.0, float(pontos) / float(_c.points_goal))


## VENCEU = pontos >= meta e mais pontos que ele.
func venceu() -> bool:
	return pontos >= int(_c.points_goal) and pontos > pontos_dele


func resultado() -> Dictionary:
	return {"pontos": pontos, "pontos_dele": pontos_dele, "venceu": venceu(), "nota": nota(), "saiu": saiu, "arte": arte, "nivel": nivel,
		"chutes": chutes, "no_tempo": no_tempo, "fora_do_tempo": fora_do_tempo}
