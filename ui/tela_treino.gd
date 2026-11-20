class_name TelaTreino
extends Control
## Fase 7a2: base das telas do treino fora de hora (Choque e Panfletagem). Tela própria, 640x360, por cima da sala: cenário, HUD
## fixo (título, tempo, SAIR, dica de controle), contagem "PREPARAR / VAI!" e a tela de prêmio no fim.
## A UI só lê `GameState.treino_jogo().estado()` e manda as entradas; quem faz o tempo passar é o tick do GameState (a UI NÃO chama
## `passo`). Nenhuma regra aqui: pontos, fôlego, avisos e prêmio vêm prontos da lógica.
## As subclasses (TelaChoque, TelaPanfleto) montam o mundo, o resto do HUD e reagem aos eventos.

const TELA := Vector2(640, 360)
const Z_MUNDO := 100
const Z_HUD := 500

var kind := ""
var info: Dictionary = {}
var sfx: Sfx
var jogo = null  # ChoqueLogica | PanfletoLogica (do GameState)
var premio: Dictionary = {}
var janela: JanelaPremioTreino

var _mundo: Node2D  # cenário, lutadores, pedestres, efeitos (posição livre de propósito; treme)
var _hud: Control  # parte fixa: não treme
var _caixa_tempo: Panel
var _rotulo_tempo: Label
var _botao_sair: Button
var _dica: Label
var _centro: Label  # PREPARAR / VAI!
var _flash: ColorRect
var _fase := ""
var _shake_t := 0.0
var _shake_dur := 0.1
var _shake_amp := 0
var _tween_centro: Tween
var _tween_flash: Tween
var _rng := RandomNumberGenerator.new()  # só enfeite (direção da tremida, falas da rua); o jogo nunca usa este


# ---------------------------------------------------------------- o que as subclasses preenchem
func _chave_layout() -> String:
	return "spar"


func _nome_fundo() -> String:
	return "spar_bg"


func _titulo() -> String:
	return ""


func _dica_texto() -> String:
	return ""


func _caixa_do_tempo() -> Array:
	return [296, 4, 48, 18]


func _montar_mundo() -> void:
	pass


func _montar_hud() -> void:
	pass


func _atualizar(_e: Dictionary, _delta: float) -> void:
	pass


func _evento(_ev: String, _e: Dictionary) -> void:
	pass


func _ao_info() -> void:
	pass


func _ao_clique_mundo(_p: Vector2) -> void:
	pass


func _ao_soltar() -> void:
	pass


func _ao_tecla(_event: InputEventKey) -> void:
	pass


# ---------------------------------------------------------------- montagem
func layout() -> Dictionary:
	var l = UiTema.manifest().get("minigame_layout", {}).get(_chave_layout(), {})
	return l if l is Dictionary else {}


static func retangulo(a: Array) -> Rect2:
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))


func abrir(info_: Dictionary) -> void:
	info = info_
	kind = str(info.get("kind", ""))
	position = Vector2.ZERO
	size = TELA
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_rng.randomize()
	sfx = Sfx.new()
	add_child(sfx)
	jogo = GameState.treino_jogo()
	_montar()
	set_process(true)


## O resto da resposta do IR (o boato do Osmar na Panfletagem).
func definir_info(info_: Dictionary) -> void:
	info = info_
	_ao_info()


func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.color = UiTema.INK
	fundo.size = TELA
	add_child(fundo)
	_mundo = Node2D.new()
	_mundo.z_index = Z_MUNDO
	UiTema.alinhar(_mundo, "ignore")
	add_child(_mundo)
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = UiTema.textura(_nome_fundo())
	bg.z_index = -100
	_mundo.add_child(bg)
	_montar_mundo()
	_hud = Control.new()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.size = TELA
	_hud.z_index = Z_HUD
	add_child(_hud)
	_montar_hud_comum()
	_montar_hud()
	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = TELA
	_flash.z_index = 800
	add_child(_flash)
	_atualizar(jogo.estado() if jogo != null else {}, 0.0)


func _montar_hud_comum() -> void:
	var L := layout()
	# Título do treino, em cima à esquerda.
	UiTema.rotulo(_hud, _titulo(), UiTema.Y1, 8, 8, 0, HORIZONTAL_ALIGNMENT_LEFT, true, true)
	# Caixa do tempo: "21 S" no meio do cartão.
	var tb := retangulo(L.get("timer_box", _caixa_do_tempo()))
	_caixa_tempo = UiTema.painel(_hud, "ui_card", tb)
	var area := UiTema.area_nove("ui_card", tb.size)
	_rotulo_tempo = UiTema.rotulo_centrado(_caixa_tempo, area, "", UiTema.WHITE, 1, false, "center_h")
	# SAIR: em qualquer momento, leva o prêmio do que já fez.
	var sb := retangulo(L.get("exit_button", [8, 334, 48, 18]))
	_botao_sair = UiTema.botao(_hud, sb)
	UiTema.botao_conteudo(_botao_sair, UiTema.txt("mini_exit", "SAIR"), UiTema.WHITE, 1)
	_botao_sair.pressed.connect(_sair)
	# Dica de controle: uma linha, no pé da tela, com contorno (lê sobre o tatame e o asfalto).
	var tc: Array = L.get("tip_center", [320, 343])
	_dica = UiTema.rotulo(_hud, _dica_texto(), UiTema.CREAM, 0, float(tc[1]) - 5.0, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	_dica.size = Vector2(TELA.x, 12.0)
	UiTema.alinhar(_dica, "center_h")
	# PREPARAR / VAI! no meio, grande.
	_centro = UiTema.rotulo_centrado(_hud, Rect2(0, 130, TELA.x, 28), UiTema.txt("mini_ready", "PREPARAR"), UiTema.Y2, 2, true, "center_h")


# ---------------------------------------------------------------- andamento
func _process(delta: float) -> void:
	if jogo == null or not is_instance_valid(self):
		return
	if janela == null and GameState.treino_jogo() != jogo:
		return  # o estado trocou por baixo (a sala já voltou); o Fluxo fecha a tela
	var e: Dictionary = jogo.estado()
	_atualizar_tempo(e)
	_atualizar_fase(e)
	_atualizar(e, delta)
	for ev in jogo.pegar_eventos():
		_evento(str(ev), e)
	_atualizar_tremida(delta)
	if str(e.fase) == "fim" and janela == null:
		_concluir()


func _atualizar_tempo(e: Dictionary) -> void:
	var restante := float(e.get("restante", 0.0))
	var n := int(ceil(restante - 1.0e-6)) if str(e.fase) != "fim" else 0
	var texto := UiTema.txt("mini_time", "{n} S", {"n": n})
	if _rotulo_tempo.text != texto:
		_rotulo_tempo.text = texto
	_botao_sair.visible = str(e.fase) != "fim" and janela == null


func _atualizar_fase(e: Dictionary) -> void:
	var fase := str(e.fase)
	if fase == _fase:
		return
	_fase = fase
	if _tween_centro != null and _tween_centro.is_valid():
		_tween_centro.kill()
	match fase:
		"contagem":
			_centro.text = UiTema.txt("mini_ready", "PREPARAR")
			_centro.modulate.a = 1.0
			_centro.visible = true
		"jogando":
			_centro.text = UiTema.txt("mini_go", "VAI!")
			_centro.modulate.a = 1.0
			_centro.visible = true
			sfx.sino_inicio()
			_tween_centro = create_tween()
			_tween_centro.tween_interval(0.45)
			_tween_centro.tween_property(_centro, "modulate:a", 0.0, 0.25)
			_tween_centro.tween_callback(func() -> void: _centro.visible = false)
		_:
			_centro.visible = false


# ---------------------------------------------------------------- fim, SAIR e prêmio
func _sair() -> void:
	if janela != null:
		return
	_concluir()


## Aplica e mostra o prêmio (uma vez). `treino_concluir()` encerra o minigame se ainda estava rodando (SAIR).
func _concluir() -> void:
	if janela != null or jogo == null:
		return
	premio = GameState.treino_concluir()
	if premio.is_empty():
		return
	_ao_soltar()
	_centro.visible = false
	_botao_sair.visible = false
	var meta := int(jogo.estado().get("meta", 10))
	janela = JanelaPremioTreino.new()
	add_child(janela)
	janela.abrir_com(premio, meta)
	janela.voltar_pedido.connect(_voltar)
	if str(premio.get("kind", "")) == "spar" and bool(premio.get("venceu", false)):
		sfx.vitoria()
	else:
		sfx.moeda()


## VOLTAR: devolve a sala. O Fluxo fecha esta tela quando o GameState avisa (`treino_fora_mudou("")`).
func _voltar() -> void:
	GameState.treino_voltar()


# ---------------------------------------------------------------- entradas
func _gui_input(event: InputEvent) -> void:
	if janela != null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_ao_clique_mundo(event.position)
		accept_event()


func _input(event: InputEvent) -> void:
	if janela != null or not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_ao_soltar()
	elif event is InputEventKey and event.keycode == KEY_SPACE:
		_ao_tecla(event)
		get_viewport().set_input_as_handled()  # o Espaço nunca chega ao treino da garagem


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_ao_soltar()  # perdeu o foco com o botão apertado: larga (senão o Jiu-jitsu fica puxando sozinho)


# ---------------------------------------------------------------- efeitos comuns
func _tremer(amp: int, dur: float) -> void:
	if amp >= _shake_amp or _shake_t <= 0.0:
		_shake_amp = amp
		_shake_dur = dur
		_shake_t = dur


func _atualizar_tremida(delta: float) -> void:
	if _shake_t > 0.0:
		_shake_t -= delta
		var amp := 0
		if _shake_t > 0.0:
			amp = maxi(1, int(round(float(_shake_amp) * _shake_t / _shake_dur)))
		_mundo.position = Vector2(_rng.randi_range(-amp, amp), _rng.randi_range(-amp, amp)) if amp > 0 else Vector2.ZERO
	elif _mundo.position != Vector2.ZERO:
		_mundo.position = Vector2.ZERO


func _piscar(cor: Color, alfa: float, dur: float = 0.16) -> void:
	if _tween_flash != null and _tween_flash.is_valid():
		_tween_flash.kill()
	_flash.color = Color(cor, alfa)
	_tween_flash = create_tween()
	_tween_flash.tween_property(_flash, "color:a", 0.0, dur)


## Texto que sobe e some (ENCOSTOU!, ACEITOU!, NÃO, VALEU): centrado em `p` (coordenadas do mundo), com contorno.
func _flutuar(texto: String, cor: Color, p: Vector2, escala: int = 1, subida: float = 16.0, dur: float = 0.85) -> void:
	var l := UiTema.rotulo(_mundo, texto, cor, 0, 0, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	l.size = Vector2(220.0, 12.0)
	l.scale = Vector2(escala, escala)
	l.z_index = 900
	var x0 := roundf(p.x - 110.0 * float(escala))
	l.position = Vector2(x0, roundf(p.y))
	var tw := l.create_tween().set_parallel(true)
	tw.tween_method(func(t: float) -> void: l.position.y = roundf(p.y - subida * t), 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, dur * 0.4).set_delay(dur * 0.6)
	tw.chain().tween_callback(l.queue_free)


## Um quadro de uma folha de sprites (a folha do manifest tem os quadros lado a lado) como textura de recorte.
static func quadro(nome: String, indice: int) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = UiTema.textura(nome)
	var q := UiTema.tamanho_quadro(nome)
	a.region = Rect2(q.x * float(indice), 0.0, q.x, q.y)
	return a


## TextureRect de um quadro da folha, no lugar pedido.
static func imagem_quadro(pai: Node, nome: String, indice: int, x: float, y: float) -> TextureRect:
	var t := TextureRect.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.texture = quadro(nome, indice)  # a textura já é só o quadro: o tamanho mínimo é o do quadro, não o da folha inteira
	t.position = Vector2(x, y)
	t.size = UiTema.tamanho_quadro(nome)
	pai.add_child(t)
	return t


## Sprite do manifest animado em loop (todos os quadros).
func _tocar_loop(spr: AnimSprite, nome: String, fps_padrao: float = 6.0) -> void:
	if spr.nome_sprite == nome and spr.esta_tocando():
		return
	spr.definir(nome)
	var n := int(UiTema.sprite(nome).get("frames", 1))
	var seq: Array = []
	for i in n:
		seq.append(i)
	spr.tocar(seq, float(UiTema.sprite(nome).get("fps", fps_padrao)), true)


func _sombra(nome: String, p: Vector2, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.texture = UiTema.textura(nome)
	s.offset = -UiTema.pivo(nome)
	s.position = p + Vector2(0, -1)
	s.z_index = z
	_mundo.add_child(s)
	return s


func _existe(nome: String) -> bool:
	return not UiTema.sprite(nome).is_empty()
