class_name FaixaAssistido
extends Control
## Treino assistido (Fase 4b): faixa de baixo da sala, no meio, com o indicador (chip) do estado e o botão SEGURAR.
## Captura o Shift (aperto sem eco / soltura) e o botão do mouse e só chama `GameState.definir_assistido()`:
## true enquanto QUALQUER um dos dois estiver pressionado, false quando os dois estão soltos. Perder o foco da
## janela solta tudo. Nenhuma regra aqui (intervalo, mão parada, Metrônomo): o GameState decide o estado.
##
## Estados do chip (`GameState.assistido_estado()`): off = dica fixa, waiting = segurando mas a mão ainda mexe,
## active = socando (pulsa a cada auto-soco), metronome = Metrônomo >= 1 (só o chip, sem botão).

const FAIXA := Rect2(128, 273, 384, 17)  # abaixo dos pés do lutador, dentro da sala (que vai de y 18 a 290)
const ALTURA_CHIP := 13
const LARG_BOTAO := 64
const ALTURA_BOTAO := 15
const FOLGA := 4.0  # entre o chip e o botão
const PULSO := 0.15
const CORES := {"g2": UiTema.G2, "y1": UiTema.Y1, "gr3": UiTema.GR3, "white": UiTema.WHITE}

var _chip: Control
var _chip_fundo: NinePatchRect
var _chip_icone: TextureRect
var _chip_texto: Label
var _botao: Button
var _botao_icone: TextureRect
var _botao_texto: Label
var _chave := ""
var _pulso_t := 0.0
var _shift_esq := false
var _shift_dir := false
var _mouse := false
var _enviado := false  # último valor passado ao GameState
var _botao_afundado := false
var _info: Dictionary = {}


func _ready() -> void:
	position = FAIXA.position
	size = FAIXA.size
	z_index = 950  # acima da sala (z 100 + números) e abaixo das janelas do Fluxo (3000)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("ui_margens", "h")  # chip + botão formam um grupo com a mesma folga à esquerda e à direita
	_info = UiTema.manifest().get("by_data_id", {}).get("assist", {})

	_chip = Control.new()
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.set_meta("ui_margens", "h")  # ícone + texto com a mesma margem dos dois lados do chip
	add_child(_chip)
	_chip_fundo = UiTema.nine_patch(_chip, "ui_assist_chip_hint", Rect2(0, 0, 40, ALTURA_CHIP))
	_chip_icone = UiTema.textura_rect(_chip, "icon_key_shift", 3, 2)
	_chip_texto = UiTema.rotulo(_chip, "", UiTema.G2, 15, 1)
	UiTema.alinhar(_chip, "left")  # a posição do grupo (chip + botão) é calculada em _atualizar(); o verificador confere pelas margens
	UiTema.alinhar(_chip_fundo, "left")
	UiTema.alinhar(_chip_icone, "left")
	UiTema.alinhar(_chip_texto, "left")

	_montar_botao()
	GameState.assistido_mudou.connect(func(_e: String) -> void: _atualizar())
	GameState.auto_socou.connect(_ao_auto_socou)
	GameState.carreira_mudou.connect(_atualizar)
	GameState.metronomo_mudou.connect(func(_n: int) -> void: _atualizar())
	_atualizar()


func _montar_botao() -> void:
	var b := UiTema.botao(self, Rect2(0, 1, LARG_BOTAO, ALTURA_BOTAO), "ui_button_hold_normal")
	_botao = b
	var botao_info: Dictionary = _info.get("button", {})
	var normal := str(botao_info.get("normal", "ui_button_hold_normal"))
	b.add_theme_stylebox_override("pressed", UiTema.estilo(str(botao_info.get("pressed", "ui_button_hold_pressed"))))
	b.add_theme_stylebox_override("disabled", UiTema.estilo(normal))
	b.add_theme_stylebox_override("hover", UiTema.estilo(normal))
	_botao_texto = UiTema.botao_conteudo(b, UiTema.txt("assist_button", "SEGURAR"), UiTema.WHITE, 1,
		str(botao_info.get("icon", "icon_key_shift")), 3.0)
	_botao_icone = b.get_meta("icone")
	UiTema.alinhar(b, "center")
	b.button_down.connect(func() -> void:
		_mouse = true
		_enviar())
	b.button_up.connect(func() -> void:
		_mouse = false
		_enviar())


# --- Entrada: Shift e botão ---

## Shift: só o aperto (sem a repetição automática da tecla presa) liga, e a soltura desliga. O evento não é consumido.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_SHIFT:
		var k := event as InputEventKey
		if k.echo:
			return
		# Cada lado separado: soltar um Shift com o outro ainda apertado continua segurando.
		if k.location == KEY_LOCATION_RIGHT:
			_shift_dir = k.pressed
		else:
			_shift_esq = k.pressed
		_enviar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		soltar_tudo()


## Alt-tab com o Shift (ou o botão) pressionado: conta como soltar. O GameState também trata o foco da janela.
func soltar_tudo() -> void:
	_shift_esq = false
	_shift_dir = false
	_mouse = false
	_enviar()


func _enviar() -> void:
	var segurando := _shift_esq or _shift_dir or _mouse
	if segurando != _enviado:
		_enviado = segurando
		GameState.definir_assistido(segurando)
	_atualizar()


## Para o verificador e os testes: o botão SEGURAR/Shift pressionado conforme o GameState.
func segurando() -> bool:
	return _shift_esq or _shift_dir or _mouse


# --- Visual ---

func _ao_auto_socou(_g: float, _c: bool, _a: String, _b: String, _t: String) -> void:
	if GameState.assistido_estado() == "active":
		pulsar()


## Pulso de 0,15 s no chip "ASSISTIDO" a cada auto-soco do assistido.
func pulsar(duracao: float = PULSO) -> void:
	_pulso_t = duracao
	_atualizar()


func _process(delta: float) -> void:
	if _pulso_t > 0.0:
		_pulso_t -= delta
	_atualizar()  # barato: só refaz o que mudou (chave); pega o "waiting" -> "active" que passa com o tempo
	# Sem o clique no botão, mas ele solto fora dele: garante que o botão não fique preso.
	if _mouse and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_mouse = false
		_enviar()


func _atualizar() -> void:
	if _chip == null:
		return
	var estado := GameState.assistido_estado()
	var pulso := _pulso_t > 0.0 and estado == "active"
	var afundado := GameState.assistido_segurando() and estado != "metronome"
	var chave := "%s|%s|%s" % [estado, str(pulso), str(afundado)]
	if chave == _chave:
		return
	_chave = chave

	var estilos: Dictionary = _info.get("states", {})
	var icones: Dictionary = _info.get("icons", {})
	var chaves: Dictionary = _info.get("text_keys", {})
	var estilo := str(_info.get("pulse", "ui_assist_chip_active_pulse")) if pulso else str(estilos.get(estado, "ui_assist_chip_hint"))
	var cor_nome := str(UiTema.sprite(estilo).get("text_color", "g2"))
	var texto := UiTema.txt(str(chaves.get(estado, "assist_hint")))
	# A dica longa só cede à curta se o grupo (chip + botão) não coubesse na faixa.
	if estado == "off" and 18.0 + UiTema.largura_visivel(texto) + FOLGA + LARG_BOTAO > FAIXA.size.x - 8.0:
		texto = UiTema.txt("assist_hint_short")

	_chip_fundo.texture = UiTema.textura(estilo)
	_chip_icone.texture = UiTema.textura(str(icones.get(estado, "icon_key_shift")))
	_chip_texto.text = texto
	_chip_texto.reset_size()
	_chip_texto.add_theme_color_override("font_color", CORES.get(cor_nome, UiTema.WHITE))
	var vis := ceilf(UiTema.largura_visivel(texto))
	var w_chip := 18.0 + vis  # margem 3 + ícone 9 + folga 3 + texto + margem 3
	_chip.size = Vector2(w_chip, ALTURA_CHIP)
	_chip_fundo.size = _chip.size

	var com_botao := estado != "metronome"
	_botao.visible = com_botao
	_afundar_botao(afundado)
	var grupo := w_chip + (FOLGA + LARG_BOTAO if com_botao else 0.0)
	var x0 := floorf((FAIXA.size.x - grupo) / 2.0)
	_chip.position = Vector2(x0, floorf((FAIXA.size.y - ALTURA_CHIP) / 2.0))
	_botao.position = Vector2(x0 + w_chip + FOLGA, floorf((FAIXA.size.y - ALTURA_BOTAO) / 2.0))


## Botão pressionado (mouse ou Shift): afunda 1 px e fica verde = assistindo. O conteúdo desce junto.
func _afundar_botao(afundado: bool) -> void:
	if afundado == _botao_afundado:
		return
	_botao_afundado = afundado
	var info_botao: Dictionary = _info.get("button", {})
	var estilo := str(info_botao.get("pressed", "ui_button_hold_pressed")) if afundado \
		else str(info_botao.get("normal", "ui_button_hold_normal"))
	_botao.add_theme_stylebox_override("normal", UiTema.estilo(estilo))
	var d := 1.0 if afundado else -1.0
	_botao_icone.position.y += d
	_botao_texto.position.y += d
	_botao_texto.add_theme_color_override("font_color", UiTema.GR3 if afundado else UiTema.WHITE)
