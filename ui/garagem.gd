extends Control
## Tela principal: a garagem. Junta sala, HUD, painéis, barra de baixo, depuração e o cursor-luva.
## Atualiza por sinais; valores que mudam todo frame (saldo) são aplicados a ~10 Hz.
## Não tem regra de jogo: só lê o GameState e chama as ações públicas dele.

@onready var _sala: Sala = $Sala
@onready var _hud: Hud = $Hud
@onready var _esq: PainelAtributos = $PainelAtributos
@onready var _prox: PainelProxima = $PainelProxima
@onready var _dir: PainelLoja = $PainelLoja
@onready var _barra: BarraBaixo = $BarraBaixo
@onready var _fluxo: Fluxo = $Fluxo
@onready var _debug: DebugOverlay = $DebugOverlay

var _botao_mapa: BotaoMapa
var _balao: Balao
var _convite: BalaoConvite  # 7a2: balão do convite do Osmar (IR)
var _convite_espera := 0.0  # se o balão não coube sem cobrir alguém, tenta de novo daqui a pouco
var _faixa: FaixaAviso
var _cursor: AnimSprite
var _sujo := true
var _mouse_escondido := false
var _so_sala := false  # tecla H: some a interface, ficam a sala, o Treino e o LUTAR
var _cena_ui: CenaUi
var cena_forcada := false  # gancho dos testes: age como se houvesse cena em andamento


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _tema()
	move_child($FaixaAssistido, _barra.get_index() + 1)  # 6d3: o botão SEGURAR mora na faixa de baixo: tem de receber o clique antes dela

	# Fase 6d: a descrição dos itens da loja/melhorias aparece no balão colado ao cursor (Dica, pelo próprio PainelLoja);
	# a caixa de informação do painel de atributos fica só para a dica de cada atributo.
	# Botão de foco trancado (aparelho não comprado): não treina nem troca o foco, só abre o painel no cartão dele.
	_sala.mural_clicado.connect(func() -> void: _fluxo.abrir_mural())  # 6c2: o mural da parede abre a janela do mural
	_sala.envelope_clicado.connect(func() -> void: _fluxo.abrir_patrocinio())  # 8a2: o envelope PROPOSTA abre o contrato
	_sala.capuz_clicado.connect(func() -> void: _fluxo.ir_para_ronda())  # Ronda: o capuz no prego abre a Ronda Noturna
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
	_cursor.set_meta("ui_align_motivo", "cursor da luva: segue o mouse, então passa por qualquer ponto (e fora da tela quando o mouse sai)")
	add_child(_cursor)

	_botao_mapa = BotaoMapa.new()  # Fase 5.4: o mapa da árvore fica atrás deste botão (118,22), brilha quando há compra
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


## 7a2: o balão do convite só existe com a sala livre e o estado pedindo; enquanto a caixa de equipamento anima abrindo ele espera
## (o estado abre a caixa de uma vez, só a UI sabe da animação).
func _atualizar_convite(delta: float) -> void:
	if _convite == null:
		return
	var tipo := GameState.convite_visivel()
	var livre := tipo != "" and not _fluxo.ocupado() and not _sala.caixa_abrindo() and not cena_forcada and not _balao.ativo()
	if not livre:
		if _convite.ativo():
			_convite.esconder()
		return
	if _convite.ativo() and _convite.kind == tipo:
		return
	_convite_espera -= delta
	if _convite_espera > 0.0:
		return
	var falas: Array = GameState.lista_ui("invite_" + tipo)
	if falas.is_empty():
		return
	var idx := int(float(GameState.convite.get("open_since", 0.0))) % falas.size()  # determinístico: o convite não sorteia nada
	if not _convite.mostrar(tipo, str(falas[idx]), _sala.ponto_cabeca("coach"), _sala.cabecas_a_evitar("coach")):
		_convite_espera = 0.5


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
	_prox.bloco.atualizar()
	_dir.atualizar()
	_barra.atualizar()


func _process(delta: float) -> void:
	# O painel fecha sozinho durante as cenas (a cena do posto, a chegada à academia, a saída do John) e volta como estava.
	var em_cena := cena_forcada or GameState.cena_sala != "" or GameState.sucessao_estado() != "none" or (_cena_ui != null and _cena_ui.player != null and _cena_ui.player.ativa)
	_dir.forcar_fechado(em_cena)
	Balao.limite_direito = minf(_dir.borda_esquerda() - 6.0, 636.0) if _dir.esta_aberto() else 636.0
	if _so_sala:
		_aplicar_so_sala()
	_sala.janela_aberta = _fluxo.ocupado()  # caixa não recebe clique com janela, prévia ou luta por cima
	_atualizar_convite(delta)
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


## L abre/fecha a loja, E a equipe (aba TREINO), H mostra só a sala (some a interface, ficam o Treino e o LUTAR).
func _atalho_painel(tecla: int) -> bool:
	var aba := ""
	match tecla:
		KEY_L:
			aba = PainelLoja.ABA_LOJA
		KEY_E:
			aba = PainelLoja.ABA_TREINO
		KEY_H:
			definir_so_sala(not _so_sala)
			return true
		_:
			return false
	if _so_sala:
		definir_so_sala(false)  # O1: L ou E tira do "só a sala" e abre o painel na aba pedida
		_dir.abrir(aba)
	else:
		_dir.alternar(aba)  # O2: mesma aba aberta fecha; outra aba só troca e continua aberto
	return true


func definir_so_sala(ativo: bool) -> void:
	_so_sala = ativo
	_hud.modo_so_sala(ativo)
	_barra.modo_so_sala(ativo)
	if not ativo:
		for n in [_esq, _prox, _botao_mapa, _dir]:
			(n as CanvasItem).visible = true


func esta_so_sala() -> bool:
	return _so_sala


func _aplicar_so_sala() -> void:
	for n in [_esq, _prox, _botao_mapa, _dir]:
		(n as CanvasItem).visible = false


# Teclas 1 a 4 trocam o foco (a 4ª só existe na carreira com arte) (atalho para trocar sem mexer o mouse).
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE:
		_tecla_espaco(event)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _fluxo.ocupado():
			return  # prévia, luta ou janela aberta: os atalhos da garagem ficam quietos
		if not _debug.visible and not GameState.acoes_bloqueadas() and _atalho_painel(event.keycode):
			get_viewport().set_input_as_handled()
			return
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
	# 7a2: o balão do convite do Osmar (IR). O Osmar com o balão aberto também vale como IR.
	_convite = BalaoConvite.new()
	add_child(_convite)
	_convite.ir_pedido.connect(_fluxo.ir_para_treino)
	_sala.osmar_convite.connect(func() -> void:
		if _convite.ativo():
			_fluxo.ir_para_treino())
	_sala.clique_vazio.connect(_balao.completar)
	# Fase 6b1: a cena de passar o posto (palco na sala, faixas pretas, PULAR, balão e a tela de criação do discípulo).
	var cena_ui := CenaUi.new()
	cena_ui.sala = _sala
	cena_ui.fluxo = _fluxo
	cena_ui.balao = _balao
	cena_ui.alvos = [_hud, _esq, _prox, _dir, _barra, _botao_mapa, _faixa, $FaixaAssistido]
	add_child(cena_ui)
	_cena_ui = cena_ui


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
		# 6d3: clicar na sala não fecha o painel; só a aba/seta ou L/E na mesma aba.
