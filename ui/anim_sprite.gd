class_name AnimSprite
extends Sprite2D
## Sprite de folha horizontal (quadros lado a lado) dirigido pelo manifest.
## Pivô vira `offset`, posição é a da sala. Animação por troca de quadros (pixel inteiro).

var nome_sprite := ""

var _seq: Array = [0]
var _fps := 10.0
var _loop := false
var _t := 0.0
var _i := 0
var _ao_fim := Callable()
var _tocando := false


func _init() -> void:
	centered = false
	set_process(false)


## Troca a folha (textura, nº de quadros e pivô). Não mexe na posição.
func definir(nome: String) -> void:
	if nome == nome_sprite:
		return
	nome_sprite = nome
	var s := UiTema.sprite(nome)
	hframes = maxi(1, int(s.get("frames", 1)))
	texture = UiTema.textura(nome)
	offset = -UiTema.pivo(nome)
	frame = 0
	_tocando = false
	set_process(false)


func tocar(seq: Array, fps: float, em_loop: bool = false, ao_fim: Callable = Callable()) -> void:
	_seq = seq
	_fps = maxf(fps, 0.1)
	_loop = em_loop
	_ao_fim = ao_fim
	_t = 0.0
	_i = 0
	_tocando = seq.size() > 1 or ao_fim.is_valid()
	frame = clampi(int(seq[0]), 0, hframes - 1)
	set_process(_tocando)


## Para num quadro fixo.
func parar(quadro: int = 0) -> void:
	_tocando = false
	_ao_fim = Callable()
	set_process(false)
	frame = clampi(quadro, 0, hframes - 1)


func esta_tocando() -> bool:
	return _tocando


func _process(delta: float) -> void:
	_t += delta
	var dur := 1.0 / _fps
	while _t >= dur and _tocando:
		_t -= dur
		_i += 1
		if _i >= _seq.size():
			if _loop:
				_i = 0
			else:
				_tocando = false
				set_process(false)
				var cb := _ao_fim
				_ao_fim = Callable()
				if cb.is_valid():
					cb.call()
				return
		frame = clampi(int(_seq[_i]), 0, hframes - 1)
