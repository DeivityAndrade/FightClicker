class_name PularAbertura
extends Control
## Indicador "esc: pular" da abertura (Fase 6a): chip no canto de baixo à direita da sala. Segurar ESC por
## `opening.skip_hold_seconds` (0,5 s) pula a abertura inteira; o anel enche enquanto isso. Soltou antes: volta a zero.
## O ESC que já fecha janelas (Fluxo) não conflita: a contagem só vale se o aperto começou com a sala livre.

const DIREITA := 507.0
const BASE_Y := 285.0
const ALTURA := 16.0

var fluxo: Fluxo
var _fundo: NinePatchRect
var _anel: AnimSprite
var _texto: Label
var _segurando := false
var _valido := false
var _t := 0.0
var _w := 0.0
var _ativo_estilo := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2300
	visible = false
	var txt := UiTema.txt("skip_hint", "pular").to_lower()
	var larg := UiTema.largura_visivel(txt)
	_w = 41.0 + larg + 5.0
	size = Vector2(_w, ALTURA)
	position = Vector2(DIREITA - _w, BASE_Y - ALTURA)
	_fundo = UiTema.nine_patch(self, "ui_skip_chip", Rect2(0, 0, _w, ALTURA))
	_anel = AnimSprite.new()
	_anel.definir("ui_skip_ring")
	_anel.position = Vector2(3, 3)
	add_child(_anel)
	UiTema.textura_rect(self, "icon_key_esc", 16, 3)
	_texto = UiTema.rotulo(self, txt, UiTema.G2, 41, 3, 0, HORIZONTAL_ALIGNMENT_LEFT, false)
	GameState.abertura_mudou.connect(_ao_estado)
	_ao_estado(GameState.abertura_estado())


func _ao_estado(estado: String) -> void:
	visible = estado == "playing"
	if not visible:
		_zerar()


func _zerar() -> void:
	_segurando = false
	_valido = false
	_t = 0.0
	_estilo(false)
	_anel.parar(0)


func _estilo(ativo: bool) -> void:
	if ativo == _ativo_estilo:
		return
	_ativo_estilo = ativo
	_fundo.texture = UiTema.textura("ui_skip_chip_active" if ativo else "ui_skip_chip")
	_texto.add_theme_color_override("font_color", UiTema.WHITE if ativo else UiTema.G2)


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or event.keycode != KEY_ESCAPE or event.echo:
		return
	if event.pressed:
		# Aperto com janela, prévia ou luta aberta é do Fluxo (fechar a janela): não conta para pular.
		_valido = not (fluxo != null and (fluxo.ocupado() or fluxo.cartao != null))
		_segurando = _valido
		_t = 0.0
	else:
		_zerar()


func _process(delta: float) -> void:
	if not visible:
		return
	if _segurando and fluxo != null and fluxo.ocupado():
		_zerar()
		return
	if not _segurando:
		return
	_t += delta
	var alvo := maxf(0.05, float(GameState.dialogos.opening.get("skip_hold_seconds", 0.5)))
	_estilo(true)
	_anel.parar(clampi(int(round(8.0 * _t / alvo)), 0, 8))
	if _t >= alvo:
		_zerar()
		GameState.pular_abertura()
