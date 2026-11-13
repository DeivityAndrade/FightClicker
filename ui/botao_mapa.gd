class_name BotaoMapa
extends Button
## Botão da árvore na sala (Fase 5.4): 22x22 em (132,22), na parede lateral, igual na garagem e na academia. Fica quieto e
## pequeno; só brilha (2 quadros a 2 fps) quando existe nó à vista que o Legado paga (`GameState.ha_no_compravel()`).
## Passar o mouse mostra a dica "ÁRVORE" + quantos nós dá para comprar. Fica apagado quando o mapa não abre agora
## (luta, dia da luta, escolha da arte, caixa na metade): `GameState.pode_abrir_arvore()`. Nenhuma regra aqui.

const POSICAO := Vector2(132, 22)
const TAMANHO := Vector2(22, 22)

var _img: TextureRect
var _atlas: AtlasTexture
var _brilha := false
var _abre := true
var _t := 0.0
var _tempo_leitura := 0.0


func _ready() -> void:
	name = "BotaoMapa"
	position = POSICAO
	size = TAMANHO
	z_index = 1000  # acima da sala (mundo z 100) e abaixo das janelas (Fluxo z 3000)
	focus_mode = Control.FOCUS_NONE
	flat = true
	for estilo in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(estilo, StyleBoxEmpty.new())
	_img = TextureRect.new()
	_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_img.stretch_mode = TextureRect.STRETCH_KEEP
	_img.size = TAMANHO
	_atlas = AtlasTexture.new()
	_img.texture = _atlas
	add_child(_img)
	mouse_entered.connect(func() -> void: Dica.pedir(texto_dica()))
	mouse_exited.connect(Dica.limpar)
	pressed.connect(Dica.limpar)
	GameState.arvore_mudou.connect(_ler)
	GameState.permanente_mudou.connect(_ler)
	GameState.carreira_mudou.connect(_ler)
	_ler()
	_desenhar()


func texto_dica() -> String:
	var n := GameState.nos_compraveis()
	var linha2 := UiTema.txt("map_button_tip_none", "NADA PARA COMPRAR AGORA")
	if n == 1:
		linha2 = UiTema.txt("map_button_tip_one", "1 NÓ PARA COMPRAR")
	elif n > 1:
		linha2 = UiTema.txt("map_button_tip_many", "{n} NÓS PARA COMPRAR", {"n": n})
	return UiTema.txt("tree_button", "ÁRVORE") + "\n" + linha2


func brilhando() -> bool:
	return _brilha


func _ler() -> void:
	_brilha = GameState.ha_no_compravel()
	_abre = GameState.pode_abrir_arvore()
	_desenhar()


func _process(delta: float) -> void:
	_t += delta
	_tempo_leitura += delta
	if _tempo_leitura >= 0.2:  # o estado da sala muda sem sinal (caixa, dia da luta): relê 5 vezes por segundo
		_tempo_leitura = 0.0
		_brilha = GameState.ha_no_compravel()
		_abre = GameState.pode_abrir_arvore()
	_desenhar()


func _desenhar() -> void:
	var nome := "ui_map_button_normal"
	var quadro := 0
	match get_draw_mode():
		DRAW_PRESSED, DRAW_HOVER_PRESSED:
			nome = "ui_map_button_pressed"
		DRAW_HOVER:
			nome = "ui_map_button_hover"
		_:
			if _brilha:
				nome = "ui_map_button_glow"
				quadro = int(_t * 2.0) % 2
	var folha := UiTema.textura(nome)
	if _atlas.atlas != folha or _atlas.region.position.x != float(quadro * 22):
		_atlas.atlas = folha
		_atlas.region = Rect2(quadro * 22, 0, 22, 22)
	modulate = Color.WHITE if _abre else Color(0.62, 0.6, 0.66)
