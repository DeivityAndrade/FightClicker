class_name Dica
extends Control
## Dica flutuante (Fase 5.1, nível 3 de leitura): aparece ao passar o mouse e some ao sair. Várias linhas (\n),
## texto em maiúsculas, no tamanho txt_body. Nunca é texto fixo: só existe enquanto o mouse está sobre algo.
## Uso: Dica.pedir("texto") no mouse_entered e Dica.limpar() no mouse_exited.

static var instancia: Dica = null

var _fundo: NinePatchRect
var _caixa: Control
var _texto := ""
var ancora_fixa := Vector2(-1, -1)  # só para o verificador: fixa a dica num ponto da tela


func _ready() -> void:
	instancia = self
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 3600
	visible = false
	UiTema.alinhar(self, "ignore")  # flutua junto do mouse: posição livre de propósito
	set_anchors_preset(Control.PRESET_TOP_LEFT)


func _exit_tree() -> void:
	if instancia == self:
		instancia = null


static func pedir(texto: String) -> void:
	if instancia != null:
		instancia.mostrar(texto)


static func limpar() -> void:
	if instancia != null:
		instancia.esconder()


func mostrar(texto: String) -> void:
	var t := texto.to_upper()
	if t == "":
		esconder()
		return
	if t != _texto:
		_texto = t
		_montar()
	visible = true
	_seguir()


func esconder() -> void:
	visible = false
	_texto = ""
	if _caixa != null:
		_caixa.queue_free()
		_caixa = null


func texto_atual() -> String:
	return _texto if visible else ""


func _montar() -> void:
	if _caixa != null:
		_caixa.queue_free()
	_caixa = Control.new()
	_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caixa)
	var linhas := _texto.split("\n")
	var larg := 0.0
	for l in linhas:
		larg = maxf(larg, UiTema.largura_visivel(l))
	var w := ceilf(larg) + 12.0
	var h := float(linhas.size()) * 9.0 + 7.0
	_caixa.size = Vector2(w, h)
	size = _caixa.size
	UiTema.painel(_caixa, "ui_card", Rect2(0, 0, w, h))
	for i in linhas.size():
		var cor := UiTema.WHITE if i == 0 and linhas.size() > 1 else UiTema.G3
		UiTema.rotulo(_caixa, linhas[i], cor, 6, 2 + i * 9)


func _process(_d: float) -> void:
	if visible:
		_seguir()


func _seguir() -> void:
	if _caixa == null:
		return
	var m: Vector2 = ancora_fixa if ancora_fixa.x >= 0.0 else (get_parent().get_local_mouse_position() if get_parent() is Control else Vector2.ZERO)
	var x: float = m.x + 10.0
	var y: float = m.y + 12.0
	if x + size.x > 636.0:
		x = m.x - size.x - 6.0
	if y + size.y > 356.0:
		y = m.y - size.y - 6.0
	position = Vector2(maxf(2.0, floorf(x)), maxf(2.0, floorf(y)))
