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

var _botao_mapa: BotaoMapa
var _balao: Balao
var _faixa: FaixaAviso
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
	GameState.mural_updated.connect(func(_s: String) -> void: _atualizar_mural())
	_atualizar_mural()

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

	_botao_mapa = BotaoMapa.new()  # Fase 5.4: o mapa da árvore fica atrás deste botão (132,22), brilha quando há compra
	add_child(_botao_mapa)
	_botao_mapa.pressed.connect(_fluxo.abrir_arvore)
	add_child(Dica.new())  # Fase 5.1: dica flutuante do nível 3 (hover)
	_faixa = FaixaAviso.new()
	add_child(_faixa)  # Fase 5.3: faixa de aviso da data (3 dias e 1 dia)
	_montar_fala()
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
	_atualizar_mural()


## Fase 6c2: mural na academia. Lê estado e texto do GameState; mostra/esconde os filhos do nó Mural.
func _atualizar_mural() -> void:
	var mural: Control = get_node_or_null("Mural")
	if mural == null:
		return
	var est := GameState.mural_estado()
	var visivel := est != "" and GameState.local_id == "gym"
	mural.visible = visivel
	if not visivel:
		return
	# Esconde todos os estados visuais primeiro
	for child in mural.get_children():
		if child is ColorRect:
			child.visible = false
	# Mostra o estado correspondente
	match est:
		"empty":
			mural.get_node_or_null("Empty").visible = true if mural.has_node("Empty") else false
		"john_only":
			mural.get_node_or_null("JohnOnly").visible = true if mural.has_node("JohnOnly") else false
		"john_left":
			mural.get_node_or_null("JohnLeft").visible = true if mural.has_node("JohnLeft") else false
		"with_disciple":
			mural.get_node_or_null("WithDisciple").visible = true if mural.has_node("WithDisciple") else false
		"symbol_unlocked":
			mural.get_node_or_null("SymbolUnlocked").visible = true if mural.has_node("SymbolUnlocked") else false
		"mural_upgraded":
			mural.get_node_or_null("MuralUpgraded").visible = true if mural.has_node("MuralUpgraded") else false
	var lbl: Label = mural.get_node_or_null("TextoMural")
	if lbl != null:
		lbl.text = GameState.mural_texto()


func _process(_delta: float) -> void:
	_sala.janela_aberta = _fluxo.ocupado()  # caixa não recebe clique com janela, prévia ou luta por cima
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


# --- Fase 6a: balão de fala, dica "esc: pular" e cliques ---

func _montar_fala() -> void:
	_balao = Balao.new()
	add_child(_balao)
	var chip := PularAbertura.new()
	chip.fluxo = _fluxo
	add_child(chip)
	GameState.fala_pedida.connect(_ao_fala_pedida)
	GameState.fala_cancelada.connect(func(id: String) -> void: _balao.cancelar(id))
	_balao.falando.connect(_sala.definir_falando)
	_sala.clique_vazio.connect(_balao.completar)
	# Fase 6b1: a cena de passar o posto (palco na sala, faixas pretas, PULAR, balão e a tela de criação do discípulo).
	var cena_ui := CenaUi.new()
	cena_ui.sala = _sala
	cena_ui.fluxo = _fluxo
	cena_ui.balao = _balao
	cena_ui.alvos = [_hud, _esq, _dir, _barra, _botao_mapa, _faixa, $FaixaAssistido]
	add_child(cena_ui)


## O GameState pediu uma fala: o balão nasce preso à cabeça de quem fala (nunca cobre o alvo; sem espaço, a fala some).
func _ao_fala_pedida(speaker: String, texto: String, id: String) -> void:
	if _fluxo.ocupado():
		return  # janela por cima: nunca há balão por baixo dela (o GameState também cancela)
	var faixa_y := -1.0
	if _faixa != null and _faixa.visible:
		faixa_y = _faixa.position.y + _faixa.size.y
	if not _balao.mostrar(id, speaker, texto, _sala.ponto_cabeca(speaker), faixa_y, _sala.cabecas_a_evitar(speaker)):
		GameState.fala_recusada(id)  # a fala única não conta como vista


## Todo clique de mouse conta como "o jogador mexeu": cancela o gesto e zera a sala parada (clicar() já faz o mesmo no alvo).
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameState.registrar_clique()
