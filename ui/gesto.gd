class_name Gesto
extends Node
## Relógio do gesto "fecho e dois toques" (Fase 6a). Recebe o plano de GameState.pedir_gesto() e dispara, em tempo real,
## o começo da animação, o `strap_rip`, os dois toques (0,22 s exatos entre eles, por temporizador e não por quadro) e o fim.
## Quem desenha (Sala ou TelaLuta) só passa os callbacks. `cancelar()` corta tudo no mesmo quadro.

var plano: Dictionary = {}
var _t := 0.0
var _eventos: Array = []
var _i := 0
var _comecou := false
var _cb: Dictionary = {}


## cb: {comecar(plano), rip(), toque(n), fim()}
func iniciar(p: Dictionary, cb: Dictionary) -> void:
	plano = p
	_cb = cb
	_t = 0.0
	_i = 0
	_comecou = false
	var ini := float(p.get("start", 0.0))
	_eventos = [[ini, "comecar", 0]]
	if float(p.get("rip_at", -1.0)) >= 0.0:
		_eventos.append([ini + float(p.rip_at), "rip", 0])
	var taps: Array = p.get("taps", [])
	for n in taps.size():
		_eventos.append([ini + float(taps[n]), "toque", n])
	_eventos.append([ini + float(p.get("duration", 0.5)), "fim", 0])
	_eventos.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	set_process(true)


func ativo() -> bool:
	return not plano.is_empty()


## A animação já começou (passou o atraso `start`)?
func animando() -> bool:
	return ativo() and _comecou


func cancelar() -> void:
	plano = {}
	_eventos = []
	set_process(false)


func _process(delta: float) -> void:
	_t += delta
	while _i < _eventos.size() and float(_eventos[_i][0]) <= _t:
		var e: Array = _eventos[_i]
		_i += 1
		var nome := str(e[1])
		if nome == "comecar":
			_comecou = true
		var f: Callable = _cb.get(nome, Callable())
		if nome == "fim":
			plano = {}
			set_process(false)
		if f.is_valid():
			if nome == "comecar":
				f.call(plano)
			elif nome == "toque":
				f.call(int(e[2]))
			else:
				f.call()
		if plano.is_empty():
			return
