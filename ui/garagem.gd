extends Control
## Tela principal: a garagem. Junta sala, HUD, painéis, barra de baixo, depuração e o cursor-luva.
## Atualiza por sinais; valores que mudam todo frame (saldo) são aplicados a ~10 Hz.
## Não tem regra de jogo: só lê o GameState e chama as ações públicas dele.

@onready var _sala: Sala = $Sala
@onready var _hud: Hud = $Hud
@onready var _esq: PainelAtributos = $PainelAtributos
@onready var _dir: PainelLoja = $PainelLoja
@onready var _barra: BarraBaixo = $BarraBaixo
@onready var _fluxo: Fluxo = $Fluxo
@onready var _debug: DebugOverlay = $DebugOverlay

var _cursor: AnimSprite
var _sujo := true
var _mouse_escondido := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _tema()

	_dir.info_mudou.connect(_esq.mostrar_info)
	# Marca de fita no chão/parede e botão de foco trancado: nenhum dos dois treina nem troca o foco, só apontam a compra.
	_sala.marca_clicada.connect(_apontar_compra)
	_barra.compra_pedida.connect(_apontar_compra)

	GameState.treino_mudou.connect(func(_v: float) -> void: _sujo = true)
	GameState.atributo_mudou.connect(func(_a: String, _v: float) -> void: _sujo = true)
	GameState.economia_mudou.connect(_atualizar_tudo)
	GameState.carreira_mudou.connect(_atualizar_tudo)

	var timer := Timer.new()
	timer.wait_time = 1.0 / maxf(1.0, float(GameState.config.get("ui_atualizacoes_por_segundo", 10)))
	timer.timeout.connect(_ao_timer)
	add_child(timer)
	timer.start()

	_cursor = AnimSprite.new()
	_cursor.definir(UiTema.nome_cursor())
	_cursor.z_index = 4000
	_cursor.visible = false
	add_child(_cursor)

	_fluxo.ligar(_barra)
	# A luva equipada troca o cursor, a mão do lutador na garagem (Sala) e na luta (TelaLuta) pelo mesmo sufixo.
	GameState.luva_mudou.connect(func(_n: int, _s: String) -> void: _cursor.definir(UiTema.nome_cursor()))
	GameState.carreira_mudou.connect(func() -> void: _cursor.definir(UiTema.nome_cursor()))
	GameState.luta_iniciada.connect(func(_l: Dictionary) -> void: _atualizar_tudo())
	GameState.luta_resolvida.connect(func(_r: Dictionary) -> void: _atualizar_tudo())
	GameState.fim_de_carreira.connect(func(_f: Dictionary) -> void: _atualizar_tudo())
	_fluxo.janela_mudou.connect(func(_a: bool) -> void: _atualizar_tudo())

	_atualizar_tudo()


## Abre a aba TREINO e faz o cartão de compra do aparelho piscar. A compra em si acontece só ali.
func _apontar_compra(aparelho: String) -> void:
	_dir.destacar_compra(aparelho)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Tema com a fonte pixel para qualquer controle padrão (tooltips, janelas).
func _tema() -> Theme:
	var t := Theme.new()
	t.default_font = UiTema.fonte()
	t.default_font_size = UiTema.TAMANHO_FONTE
	return t


func _ao_timer() -> void:
	if _sujo:
		_atualizar_tudo()


func _atualizar_tudo() -> void:
	_sujo = false
	_hud.atualizar()
	_esq.atualizar()
	_dir.atualizar()
	_barra.atualizar()


func _process(_delta: float) -> void:
	_sala.dica_ativa = _barra.dica_ativa()
	# Sobre a sala: esconde o cursor do sistema e desenha a luva (mesma arte da mão do lutador).
	var sobre := get_viewport().gui_get_hovered_control() == _sala
	if sobre != _mouse_escondido:
		_mouse_escondido = sobre
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if sobre else Input.MOUSE_MODE_VISIBLE
	_cursor.visible = sobre
	if sobre:
		_cursor.position = get_local_mouse_position().floor()
		_cursor.frame = 1 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 0


## Espaço treina como um clique no alvo. Só vale no APERTO (segurar não repete), na garagem livre: sem janela,
## luta, tela de fim nem depuração (F12) por cima. O Espaço é sempre consumido aqui, então nunca vira `ui_accept`
## (que apertaria um botão com foco); além disso nenhum botão da garagem aceita foco (`FOCUS_NONE`).
func _tecla_espaco(event: InputEventKey) -> void:
	get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	if _fluxo.fechar_cartao_aberto():
		return  # com o cartão "o que você trouxe" aberto, o Espaço só fecha o cartão
	if _fluxo.ocupado() or _debug.visible or GameState.acoes_bloqueadas():
		return
	_sala.treinar_pelo_teclado()


# Teclas 1 a 4 trocam o foco (a 4ª só existe na carreira com arte) (atalho para trocar sem mexer o mouse).
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE:
		_tecla_espaco(event)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _fluxo.ocupado():
			return  # prévia, luta ou janela aberta: os atalhos da garagem ficam quietos
		var i: int = event.keycode - KEY_1
		var lista: Array = GameState.aparelhos_da_carreira()
		if i >= 0 and i < lista.size():
			# A ordem visível (SACO, ESTEIRA, CORDA e o aparelho da arte) é a de aparelhos_da_carreira(). Aparelho que
			# ainda não chegou: definir_foco recusa e a tecla não faz nada.
			if GameState.definir_foco(lista[i].id):
				_sala.sfx.foco()
			get_viewport().set_input_as_handled()
