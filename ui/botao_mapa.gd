class_name BotaoMapa
extends Button
## Botão da árvore na sala (Fase 5.4): 22x22 em (132,22), na parede lateral, igual na garagem e na academia. Fica quieto e
## pequeno; só brilha (2 quadros a 2 fps) quando existe nó à vista que o Legado paga (`GameState.ha_no_compravel()`).
## Passar o mouse mostra a dica "ÁRVORE" + quantos nós dá para comprar. Fica apagado quando o mapa não abre agora
## (luta, dia da luta, escolha da arte, caixa na metade): `GameState.pode_abrir_arvore()`. Nenhuma regra aqui.

const POSICAO := Vector2(118, 22)  # 6d2: ao lado dos atributos em miniatura
const TAMANHO := Vector2(22, 22)

var _img: TextureRect
var _brilha := false
var _abre := true
var _t := 0.0
var _tempo_leitura := 0.0
var _estilo := ""


func _ready() -> void:
	name = "BotaoMapa"
	position = POSICAO
	size = TAMANHO
	z_index = 1000  # acima da sala (mundo z 100) e abaixo das janelas (Fluxo z 3000)
	focus_mode = Control.FOCUS_NONE
	# Tema C: botão quadrado de asfalto (c_btn_normal) com o ícone do mapa; pisca no vermelho de foco quando há nó para comprar.
	UiTema.aplicar_estilo_botao(self, "c_btn_normal")
	var q := UiTema.tamanho_quadro("icon_skill_map")
	var a := UiTema.area_botao(self)
	_img = UiTema.textura_rect(self, "icon_skill_map", roundf(a.position.x + (a.size.x - q.x) / 2.0), UiTema.y_imagem(a, q.y))
	_img.set_meta("y_base", _img.position.y)
	mouse_entered.connect(func() -> void: Dica.pedir(texto_dica(), self))
	mouse_exited.connect(Dica.limpar)
	pressed.connect(Dica.limpar)
	GameState.arvore_mudou.connect(_ler)
	GameState.permanente_mudou.connect(_ler)
	GameState.carreira_mudou.connect(_ler)
	_ler()
	_desenhar()


func texto_dica() -> String:
	var n := GameState.nos_compraveis()
	var titulo := UiTema.txt("tree_button", "ÁRVORE")
	# 6d2: a segunda linha só existe quando há o que comprar.
	if n == 1:
		return titulo + "\n" + UiTema.txt("map_button_tip_one", "1 NÓ")
	if n > 1:
		return titulo + "\n" + UiTema.txt("map_button_tip_many", "{n} NÓS", {"n": n})
	return titulo


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
	var apertado := get_draw_mode() in [DRAW_PRESSED, DRAW_HOVER_PRESSED]
	var aceso := _brilha and int(_t * 2.0) % 2 == 1 and get_draw_mode() == DRAW_NORMAL  # 2 quadros a 2 fps
	var estilo := "c_btn_foco" if aceso else "c_btn_normal"
	if estilo != _estilo:
		_estilo = estilo
		add_theme_stylebox_override("normal", UiTema.estilo(estilo))
	_img.position.y = float(_img.get_meta("y_base")) + (2.0 if apertado else 0.0)  # a face desce 2 px ao apertar
	modulate = Color.WHITE if _abre else Color(0.62, 0.6, 0.66)
