class_name PanfletoLogica
extends RefCounted
## Fase 7a2: lógica pura da Panfletagem. Sem tela, sem GameState: a tela lê `estado()` / `pessoas()` e manda `clicar(id)`.
## Referência das contas: jogar_panfleto() de tools/sim/fase7a2_sim.py; números em data/minigames.json.
## Todas as pessoas da rua são sorteadas na criação, com o rng recebido: mesma semente + mesmas entradas = mesmo resultado.

var nivel := 0
var fase := "contagem"  # "contagem" | "jogando" | "fim"
var tempo := 0.0  # segundos de jogo decorridos (sem a contagem)
var aceitos := 0
var erros := 0
var saiu := false

var _c: Dictionary  # bloco flyers do JSON
var _l: Dictionary  # linha do nível
var _contagem := 0.0
var _pessoas: Array = []  # [{id, t, interessado, falso, s0, s1, faixa, tipo, resolvida, aceitou}]
var _livre_ate := 0.0  # mão ocupada até este tempo de jogo
var _eventos: Array = []
var _acc := 0.0

const PASSO := 0.02
const TIPOS_PEDESTRE := 5


func _init(flyers: Dictionary, nivel_jogo: int, rng: RandomNumberGenerator) -> void:
	_c = flyers
	nivel = clampi(nivel_jogo, 0, _c.levels.size() - 1)
	_l = _c.levels[nivel]
	_contagem = float(_c.countdown_s)
	var t := _exp(rng, float(_l.spawn_s))
	var dur := float(_c.duration_s)
	while t < dur:
		var inter := rng.randf() < float(_l.interested)
		var falso := (not inter) and rng.randf() < float(_l.false_tell)
		var s0: float = t + float(_c.cross_s) * rng.randf_range(0.25, 0.55)
		var s1: float = s0 + (float(_l.tell_s) if inter else float(_l.tell_s) * 0.45)
		_pessoas.append({"id": _pessoas.size(), "t": t, "interessado": inter, "falso": falso, "s0": s0, "s1": s1,
			"faixa": rng.randf(), "tipo": rng.randi() % TIPOS_PEDESTRE, "resolvida": false, "aceitou": false})
		t += _exp(rng, float(_l.spawn_s))


# Intervalo exponencial de média `media` (igual ao expovariate do simulador).
static func _exp(rng: RandomNumberGenerator, media: float) -> float:
	return -log(1.0 - rng.randf()) * media


# ---------------- entradas ----------------
## Clique em uma pessoa (id) ou no vazio (id = -1). Devolve "aceitou" | "erro" | "ocupado" | "ignorado".
## Só vale jogando. Mão ocupada (depois de um clique) ignora o clique. Pessoa já resolvida é ignorada sem multa.
func clicar(id: int = -1) -> String:
	if fase != "jogando":
		return "ignorado"
	if tempo < _livre_ate - 1.0e-9:
		return "ocupado"
	if id >= 0 and id < _pessoas.size():
		var p: Dictionary = _pessoas[id]
		if p.resolvida or not _na_rua(p):
			return "ignorado"
		p["resolvida"] = true
		if p.interessado and tempo >= float(p.s0) and tempo <= float(p.s1):
			p["aceitou"] = true
			aceitos += 1
			_livre_ate = tempo + float(_c.give_cooldown_s)
			_eventos.append("aceitou")
			return "aceitou"
	erros += 1
	_livre_ate = tempo + float(_c.miss_cooldown_s)
	_eventos.append("erro")
	return "erro"


## SAIR: encerra já com o que foi feito (vale na contagem também).
func sair() -> void:
	if fase != "fim":
		saiu = true
		fase = "fim"
		_eventos.append("fim")


func passo(delta: float) -> void:
	if fase == "fim" or delta <= 0.0 or not is_finite(delta):
		return
	_acc += delta
	while _acc >= PASSO - 1.0e-12 and fase != "fim":
		_acc -= PASSO
		if fase == "contagem":
			_contagem -= PASSO
			if _contagem <= 1.0e-9:
				fase = "jogando"
			continue
		tempo += PASSO
		if tempo >= float(_c.duration_s) - 1.0e-9:
			fase = "fim"
			_eventos.append("fim")


# ---------------- leitura ----------------
func _na_rua(p: Dictionary) -> bool:
	return tempo >= float(p.t) and tempo < float(p.t) + float(_c.cross_s)


## Sinal da pessoa agora: "" | "interesse" (sinal de verdade) | "falso" (sinal que some na metade; vira "fechada").
## Pessoa sem interesse e sem sinal falso: "" (fone, celular, pressa).
func sinal_de(p: Dictionary) -> String:
	if tempo < float(p.s0):
		return ""
	if p.interessado:
		return "interesse" if tempo <= float(p.s1) else ""
	if p.falso:
		return "falso" if tempo <= float(p.s1) else "fechada"
	return ""


## Pessoas na rua agora: [{id, x (0 a 1 da travessia), faixa (0 a 1, altura), tipo (0..4), sinal, interessado_visual, resolvida, aceitou}].
func pessoas() -> Array:
	var out: Array = []
	if fase == "contagem":
		return out
	for p in _pessoas:
		if _na_rua(p) or (p.aceitou and tempo < float(p.t) + float(_c.cross_s) + 0.5 and tempo >= float(p.t)):
			out.append({"id": p.id, "x": clampf((tempo - float(p.t)) / float(_c.cross_s), 0.0, 1.0), "faixa": p.faixa, "tipo": p.tipo,
				"sinal": sinal_de(p), "resolvida": p.resolvida, "aceitou": p.aceitou})
	return out


func estado() -> Dictionary:
	return {"fase": fase, "contagem": maxf(_contagem, 0.0), "tempo": tempo, "restante": maxf(float(_c.duration_s) - tempo, 0.0),
		"aceitos": aceitos, "erros": erros, "liquidos": liquidos(), "meta": int(_c.goal),
		"mao_ocupada": fase == "jogando" and tempo < _livre_ate - 1.0e-9, "nivel": nivel}


## Eventos desde a última chamada (e esvazia): "aceitou", "erro", "fim".
func pegar_eventos() -> Array:
	var e := _eventos
	_eventos = []
	return e


## Aceitos menos meio ponto por erro, nunca abaixo de 0.
func liquidos() -> float:
	return maxf(0.0, float(aceitos) - float(_c.miss_penalty) * float(erros))


## 0,25 + 0,75 x min(1, líquidos / meta).
func nota() -> float:
	var pis := float(_c.reward.floor)
	return pis + (1.0 - pis) * minf(1.0, liquidos() / float(_c.goal))


## FAMA do prêmio: max(1, arredonda(max(min_fame, parte x FAMA da próxima luta) x nota)).
func fama(prize_fame_proximo: float) -> int:
	var r: Dictionary = _c.reward
	var maxima := maxf(float(r.min_fame), float(r.fame_share) * prize_fame_proximo)
	return maxi(1, int(floor(maxima * nota() + 0.5)))


func resultado() -> Dictionary:
	return {"aceitos": aceitos, "erros": erros, "liquidos": liquidos(), "nota": nota(), "saiu": saiu, "nivel": nivel}
