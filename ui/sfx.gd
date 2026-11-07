class_name Sfx
extends Node
## Sons placeholder (assets/sfx/*.wav, sintetizados por tools/sfx/make_sfx.gd).
## Pool de players (vários sons ao mesmo tempo, a 8+ cliques/s), variação de amostra e de tom.

const PASTA := "res://assets/sfx/"
const VOZES := 10

var _fluxos: Dictionary = {}  # nome base -> Array[AudioStream]
var _ultimo: Dictionary = {}  # nome base -> último índice tocado
var _vozes: Array[AudioStreamPlayer] = []
var _proxima := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for base in ["punch_", "rope_", "step_"]:
		_fluxos[base] = _carregar_variacoes(base)
	_fluxos["punch_crit"] = _carregar_variacoes("punch_crit")
	_fluxos["buy"] = _carregar_variacoes("buy")
	_fluxos["focus"] = _carregar_variacoes("focus")
	for base in ["hit_heavy", "whoosh", "block", "ko", "bell_start", "bell_end", "crowd", "win", "lose", "coin"]:
		_fluxos[base] = _carregar_variacoes(base)
	for i in VOZES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_vozes.append(p)


func golpe(aparelho: String, critico: bool) -> void:
	match aparelho:
		"jump_rope":
			_tocar("rope_", -7.0, 0.07)
		"treadmill":
			_tocar("step_", -6.0, 0.06)
		_:
			_tocar("punch_", -5.0, 0.04)
	if critico:
		_tocar("punch_crit", -4.0, 0.03)


## Auto-soco do Metrônomo: o mesmo som do clique, bem mais baixo (o soco do jogador é o mais pesado).
func golpe_auto(aparelho: String) -> void:
	match aparelho:
		"jump_rope":
			_tocar("rope_", -15.0, 0.07)
		"treadmill":
			_tocar("step_", -14.0, 0.06)
		_:
			_tocar("punch_", -14.0, 0.05)


## Moedinha/clique da árvore: compra de um nó.
func no_aprendido() -> void:
	_tocar("buy", -3.0, 0.02)
	_tocar("coin", -9.0, 0.02)


func compra() -> void:
	_tocar("buy", -6.0, 0.02)


func foco() -> void:
	_tocar("focus", -10.0, 0.03)


func _carregar_variacoes(base: String) -> Array:
	var lista: Array = []
	if ResourceLoader.exists(PASTA + base + ".wav"):
		lista.append(load(PASTA + base + ".wav"))
	for i in range(1, 8):
		var caminho := "%s%s%d.wav" % [PASTA, base, i]
		if ResourceLoader.exists(caminho):
			lista.append(load(caminho))
	return lista


func _tocar(base: String, volume_db: float, variacao_tom: float) -> void:
	var lista: Array = _fluxos.get(base, [])
	if lista.is_empty():
		return
	# Nunca repete a mesma amostra duas vezes seguidas.
	var idx := _rng.randi() % lista.size()
	if lista.size() > 1 and idx == int(_ultimo.get(base, -1)):
		idx = (idx + 1 + _rng.randi() % (lista.size() - 1)) % lista.size()
	_ultimo[base] = idx
	var p := _vozes[_proxima]
	_proxima = (_proxima + 1) % _vozes.size()
	p.stream = lista[idx]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + _rng.randf_range(-variacao_tom, variacao_tom)
	p.play()


# --- Fase 3: sons da luta e das telas (todos sintetizados por tools/sfx/make_sfx.gd) ---

## Golpe que acerta na luta: o soco da Fase 2; o forte (crítico, contra-golpe) soma um baque grave.
func golpe_luta(forte: bool, bloqueado: bool = false) -> void:
	_tocar("punch_", -7.0 if bloqueado else -4.0, 0.05)
	if forte:
		_tocar("hit_heavy", -3.0, 0.03)
		_tocar("punch_crit", -6.0, 0.03)


func esquiva() -> void:
	_tocar("whoosh", -8.0, 0.08)


func bloqueio() -> void:
	_tocar("block", -5.0, 0.05)


func queda() -> void:
	_tocar("ko", -2.0, 0.02)


func sino_inicio() -> void:
	_tocar("bell_start", -6.0, 0.0)


func sino_fim() -> void:
	_tocar("bell_end", -6.0, 0.0)


func publico(volume_db: float = -14.0) -> void:
	_tocar("crowd", volume_db, 0.04)


func vitoria() -> void:
	_tocar("win", -6.0, 0.0)


func derrota() -> void:
	_tocar("lose", -6.0, 0.0)


func moeda() -> void:
	_tocar("coin", -7.0, 0.02)
