class_name MenuBarra
extends Control
## Controle deslizante das OPÇÕES (volume geral e de efeitos). Só desenho e entrada: guarda um valor de 0 a 1 em passos de 5% e avisa
## quem montou (`mudou` enquanto arrasta ou aperta seta, `soltou` ao largar o mouse). Mouse: clicar ou arrastar. Teclado: o menu chama `passo()`.
## Trilho ink com miolo asfalto, cheio vermelho (luz r2 em cima) e alça de papel; com foco a alça fica `white`.

signal mudou(v: float)
signal soltou

const LARGURA := 220.0
const ALTURA := 9.0
const ALCA := 6.0  # largura da alça (ink por fora, papel por dentro)
const PASSO := 0.05

var valor := 1.0:
	set(v):
		valor = clampf(roundf(v * 20.0) / 20.0, 0.0, 1.0)
		queue_redraw()
var focado := false:
	set(f):
		focado = f
		queue_redraw()
var _arrastando := false


func _init() -> void:
	size = Vector2(LARGURA, ALTURA)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	draw_rect(Rect2(0, 0, LARGURA, ALTURA), UiTema.INK)
	draw_rect(Rect2(1, 1, LARGURA - 2.0, ALTURA - 2.0), UiTema.D1)
	var xa := roundf(valor * (LARGURA - ALCA))
	if xa > 0.0:
		draw_rect(Rect2(1, 1, xa + ALCA / 2.0, ALTURA - 2.0), UiTema.R1)
		draw_rect(Rect2(1, 1, xa + ALCA / 2.0, 1), UiTema.R2)
	draw_rect(Rect2(xa, 0, ALCA, ALTURA), UiTema.INK)
	draw_rect(Rect2(xa + 1.0, 1, ALCA - 2.0, ALTURA - 2.0), UiTema.WHITE if focado else UiTema.CREAM)


## Anda `n` passos (negativo = esquerda) e avisa.
func passo(n: int) -> void:
	var antes := valor
	valor = valor + PASSO * n
	if not is_equal_approx(antes, valor):
		mudou.emit(valor)
	soltou.emit()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		_arrastando = ev.pressed
		if ev.pressed:
			_do_mouse(ev.position.x)
		else:
			soltou.emit()
		accept_event()
	elif ev is InputEventMouseMotion and _arrastando:
		_do_mouse(ev.position.x)
		accept_event()


func _do_mouse(x: float) -> void:
	var antes := valor
	valor = (x - ALCA / 2.0) / (LARGURA - ALCA)
	if not is_equal_approx(antes, valor):
		mudou.emit(valor)
