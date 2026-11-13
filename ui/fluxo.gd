class_name Fluxo
extends Control
## Maestro das telas da Fase 3 por cima da garagem: prévia -> luta (arena) -> vitória/cinturão ou fim de carreira,
## e APOSENTAR (confirmação -> "saiu por cima"). Só liga sinais do GameState às janelas e chama as funções públicas
## dele (`previa()`, `lutar()`, `concluir_luta()`, `aposentar()`, `nova_carreira()`). Nenhuma regra aqui.
##
## Ao abrir o jogo (fase3-api §8): tela de fim pendente -> luta pendente (pula a animação) -> garagem.

signal janela_mudou(aberta: bool)

var tela: TelaLuta
var janela: JanelaBase  # prévia, vitória, fim ou confirmação de aposentar (só uma por vez)

var cartao: CartaoInicio  # "o que você trouxe" (Fase 4): não é janela, não bloqueia o alvo, mas pausa o Metrônomo

var _barra: BarraBaixo
var _tatica_antes := ""
var _cartao_depois_da_arte := false  # NOVA CARREIRA com a escolha da arte pendente: o cartão "o que você trouxe" vem depois


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 360)
	z_index = 3000  # acima da sala (que usa z_index 100 e números até ~2900) e dos painéis
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tela = TelaLuta.new()
	tela.terminou.connect(_ao_terminar_luta)
	add_child(tela)
	GameState.luta_iniciada.connect(_ao_luta_iniciada)
	GameState.fim_de_carreira.connect(_ao_fim_de_carreira)
	GameState.carreira_mudou.connect(_ao_carreira_mudou)
	GameState.nova_carreira_iniciada.connect(_ao_nova_carreira_iniciada)
	GameState.escolha_arte_pedida.connect(_ao_escolha_arte_pedida)
	GameState.dia_da_luta_chegou.connect(_ao_dia_da_luta_chegou)
	GameState.aviso_data.connect(_ao_aviso_data)
	call_deferred("_checar_pendencias")


## Liga os botões LUTAR! e APOSENTAR da barra de baixo.
func ligar(barra: BarraBaixo) -> void:
	_barra = barra
	barra.lutar_pedido.connect(abrir_previa)
	barra.aposentar_pedido.connect(abrir_aposentar)


func ocupado() -> bool:
	return janela != null or tela.visible


# --- Prévia e luta ---

func abrir_previa(do_dia: bool = false) -> void:
	if ocupado() or not GameState.pode_lutar():
		return
	var dados := GameState.previa()
	if dados.is_empty():
		return
	var j := JanelaPrevia.new()
	_abrir(j)
	_tatica_antes = str(dados.tactic)
	j.abrir_com(dados, do_dia)
	j.voltar_pedido.connect(_voltar_da_previa)
	j.lutar_pedido.connect(_lutar)
	j.passar_pedido.connect(abrir_aposentar_do_dia)


# --- Dia da luta (Fase 5.3) ---

## O relógio travou na data: a prévia do dia abre sozinha (sem X, sem Esc, só LUTAR e PASSAR O POSTO). A janela do jogo sem foco
## faz o ícone da barra de tarefas piscar.
func _ao_dia_da_luta_chegou() -> void:
	_pedir_atencao()
	_checar_dia()


func _pedir_atencao() -> void:
	var w := get_window()
	if w != null and not w.has_focus() and DisplayServer.get_name() != "headless":
		DisplayServer.window_request_attention()


## Aviso de 1 dia com a janela sem foco: o ícone também pisca.
func _ao_aviso_data(dias: int) -> void:
	if dias <= int(GameState.lutas.calendario.get("warn_sound_days", 1)):
		_pedir_atencao()


## Abre a prévia do dia se o jogo está no dia e nada mais ocupa a tela (nem a luta, nem o fim da carreira). Também depois de
## fechar qualquer janela: VOLTAR da confirmação de PASSAR O POSTO cai aqui e devolve a prévia do dia, não a sala.
func _checar_dia() -> void:
	if not is_inside_tree() or ocupado() or tela.visible or not GameState.no_dia_da_luta():
		return
	if GameState.tem_fim_pendente() or GameState.tem_luta_pendente() or GameState.escolha_arte_pendente():
		return
	abrir_previa(true)


func abrir_aposentar_do_dia() -> void:
	if janela is JanelaPrevia and (janela as JanelaPrevia).dia_da_luta:
		janela.queue_free()  # a confirmação toma o lugar da prévia do dia; VOLTAR traz ela de volta (`_checar_dia`)
		janela = null
	abrir_aposentar()


# VOLTAR A TREINAR não custa nada e não muda nada: a tática volta para a que era.
func _voltar_da_previa() -> void:
	if _tatica_antes != "" and GameState.tatica != _tatica_antes:
		GameState.definir_tatica(_tatica_antes)
	_fechar()


func _lutar() -> void:
	var info := GameState.lutar()  # decide, salva e emite luta_iniciada (que abre a arena)
	if info.is_empty():
		return
	_fechar()


func _ao_luta_iniciada(info: Dictionary) -> void:
	if janela != null and janela is JanelaPrevia:
		_fechar()
	tela.iniciar(info)
	if _barra != null:
		_barra.definir_janela_aberta(true)
	janela_mudou.emit(true)


func _ao_terminar_luta(resumo: Dictionary) -> void:
	if bool(resumo.get("win", false)):
		_abrir_vitoria(resumo, false)
	# Derrota: `fim_de_carreira` já abriu a tela de fim por cima da arena.


# --- Vitória ---

func _abrir_vitoria(resumo: Dictionary, tocar_som: bool) -> void:
	var j := JanelaVitoria.new()
	_abrir(j)
	j.abrir_com(resumo, tocar_som)
	j.continuar_pedido.connect(_fechar_vitoria.bind(resumo))


## Fecha a vitória. Se foi o chefe do cinturão, a mudança para a academia é AUTOMÁTICA (o prêmio paga a mudança e ainda
## sobra dinheiro): antes o jogador ganhava o prêmio, o prêmio sumia no preço da mudança e ele chegava "sem nada".
func _fechar_vitoria(resumo: Dictionary) -> void:
	if not (janela is JanelaVitoria):
		return  # idempotente: um 2º CONTINUAR não pode fechar a janela de arte que a mudança acabou de abrir
	var jv := janela
	_fechar_tudo()
	if is_instance_valid(jv) and bool(resumo.get("belt", false)) and GameState.pode_mudar():
		GameState.mudar()  # a janela de arte (1ª vez) abre pelo sinal `escolha_arte_pedida`
	abrir_escolha_arte()  # garantia: com a escolha da arte pendente a janela sempre existe (não repete se já está aberta)


# --- Fim de carreira ---

func _ao_fim_de_carreira(fim: Dictionary) -> void:
	_abrir_fim(fim)


func _abrir_fim(fim: Dictionary, reabrindo: bool = false) -> void:
	if janela is JanelaFim:
		return
	if janela != null:
		_fechar()
	var j := JanelaFim.new()
	_abrir(j)
	# Som: a derrota já tocou durante a luta; na aposentadoria e ao reabrir o jogo toca ao abrir. Voltando do mapa: sem som.
	j.abrir_com(fim, not reabrindo and (str(fim.kind) == "retire" or not tela.visible), reabrindo)
	j.nova_carreira_pedido.connect(func() -> void: GameState.nova_carreira())
	j.arvore_pedido.connect(abrir_arvore)


# --- Árvore grande (Fase 5.4): o mapa abre pelo botão da sala (qualquer hora) e pelo botão ÁRVORE da tela de fim ---

func abrir_arvore() -> void:
	if not GameState.pode_abrir_arvore():
		return
	# Depois de uma derrota a arena continua visível por baixo da tela de fim: a tela de fim ainda pode abrir o mapa.
	if tela.visible and not (janela is JanelaFim):
		return
	if janela != null and not (janela is JanelaFim):
		return  # só a tela de fim cede o lugar ao mapa; prévia, vitória e confirmações não
	var j := JanelaMapa.new()
	_abrir(j)
	Dica.limpar()
	j.abrir_com()
	j.fechar_pedido.connect(_fechar_mapa)


## Fecha o mapa (X ou Esc). Quem veio da tela de fim volta para ela (já com o Legado gasto); da sala volta para a sala.
func _fechar_mapa() -> void:
	if not (janela is JanelaMapa):
		return
	if GameState.tem_fim_pendente():
		janela.queue_free()
		janela = null
		_abrir_fim(GameState.fim, true)
	else:
		_fechar()


# --- Cartão "o que você trouxe" (começo da carreira) ---

func _ao_nova_carreira_iniciada(dados: Dictionary) -> void:
	# Fase 5: com as artes liberadas, a escolha da arte vem ANTES do cartão (que mostra "ARTE: BOXE"): o cartão espera a janela.
	_cartao_depois_da_arte = GameState.escolha_arte_pendente()
	if _cartao_depois_da_arte or dados.is_empty():
		return  # sem nós comprados (e sem arte) não há o que mostrar
	_mostrar_cartao(dados)


func _mostrar_cartao(dados: Dictionary) -> void:
	_fechar_cartao()
	cartao = CartaoInicio.new()
	add_child(cartao)
	cartao.abrir_com(dados)
	cartao.fechou.connect(_ao_cartao_fechou)
	GameState.definir_modal(true)  # o Metrônomo pausa enquanto o cartão está na tela


# --- Escolha da arte (Fase 5) ---

## A janela abre na 1ª chegada à academia, no começo de toda carreira com as artes liberadas e ao reabrir o jogo sem ter
## escolhido. Não fecha sozinha nem tem X: só o clique numa arte (`escolher_arte`) a fecha.
func _ao_escolha_arte_pedida(_primeira: bool) -> void:
	abrir_escolha_arte()


func abrir_escolha_arte() -> void:
	if janela is JanelaArte or tela.visible or not GameState.escolha_arte_pendente():
		return
	var j := JanelaArte.new()
	_abrir(j)
	j.abrir_com()
	j.escolheu.connect(_ao_arte_escolhida)


func _ao_arte_escolhida(_arte: String) -> void:
	_fechar()
	if _cartao_depois_da_arte:
		_cartao_depois_da_arte = false
		var dados := GameState.cartao_inicio()  # agora com a arte ("ARTE: BOXE")
		if not dados.is_empty():
			_mostrar_cartao(dados)


## Enquanto o cartão está aberto, o clique (em qualquer lugar) só fecha o cartão: não treina nem aperta botão por baixo.
func _input(event: InputEvent) -> void:
	if cartao != null and is_instance_valid(cartao) and event is InputEventMouseButton and event.pressed:
		cartao.fechar()
		get_viewport().set_input_as_handled()


## O Espaço (garagem) só fecha o cartão. Devolve true se havia cartão aberto.
func fechar_cartao_aberto() -> bool:
	if cartao != null and is_instance_valid(cartao):
		cartao.fechar()
		return true
	return false


func _ao_cartao_fechou() -> void:
	cartao = null
	GameState.definir_modal(janela != null or tela.visible)


func _fechar_cartao() -> void:
	if cartao != null and is_instance_valid(cartao):
		cartao.fechou.disconnect(_ao_cartao_fechou)
		cartao.queue_free()
	cartao = null


# --- Aposentar ---

func abrir_aposentar() -> void:
	if ocupado() or not GameState.pode_aposentar():
		return
	var j := JanelaAposentar.new()
	_abrir(j)
	j.abrir_com(GameState.previa_aposentar())
	j.cancelou.connect(_fechar)
	j.confirmou.connect(func() -> void:
		_fechar()
		GameState.aposentar())


# --- Estado da carreira mudou (nova carreira, carga do save) ---

func _ao_carreira_mudou() -> void:
	if tela.visible and tela.ativa and GameState.luta.is_empty():
		tela.encerrar()  # o estado foi trocado (ex.: RECARREGAR da depuração)
	if janela is JanelaFim and not GameState.tem_fim_pendente():
		_fechar_tudo()  # NOVA CARREIRA: volta para a garagem
	elif janela is JanelaMapa and not GameState.pode_abrir_arvore():
		_fechar_tudo()  # o estado trocou por baixo (ex.: RECARREGAR da depuração) e o mapa não pode mais ficar aberto
	elif janela == null and not tela.visible:
		_checar_pendencias()


# Ordem de abertura: tela de fim pendente -> luta pendente -> garagem normal.
func _checar_pendencias() -> void:
	if janela != null or tela.visible:
		return
	if GameState.tem_fim_pendente():
		_abrir_fim(GameState.fim)
	elif GameState.tem_luta_pendente():
		# Fechou o jogo no meio da luta: o resultado já estava decidido e salvo. Pula a animação.
		var resumo := GameState.concluir_luta()
		if bool(resumo.get("win", false)):
			_abrir_vitoria(resumo, true)
	if janela == null and not tela.visible and GameState.escolha_arte_pendente():
		abrir_escolha_arte()  # fechou o jogo sem escolher a arte: a janela abre de novo antes de tudo
	_checar_dia()  # fechou o jogo no dia da luta: abre direto na prévia do dia


# --- Janelas ---

func _abrir(j: JanelaBase) -> void:
	_fechar_cartao()  # uma janela de verdade abre por cima: o cartão não fica pendurado
	GameState.definir_modal(true)
	if janela != null:
		janela.queue_free()
	janela = j
	add_child(j)
	if _barra != null:
		_barra.definir_janela_aberta(true)
	janela_mudou.emit(true)


func _fechar() -> void:
	if janela != null:
		janela.queue_free()
		janela = null
	GameState.definir_modal(false)
	if not tela.visible and _barra != null:
		_barra.definir_janela_aberta(false)
	janela_mudou.emit(ocupado())
	call_deferred("_checar_dia")  # no dia da luta nenhuma janela devolve a sala: a prévia do dia volta


## Fecha a janela e a arena: volta para a garagem.
func _fechar_tudo() -> void:
	if janela != null:
		janela.queue_free()
		janela = null
	GameState.definir_modal(false)
	tela.encerrar()
	if _barra != null:
		_barra.definir_janela_aberta(false)
	janela_mudou.emit(false)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if janela is JanelaPrevia:
			if not (janela as JanelaPrevia).dia_da_luta:  # a prévia do dia não fecha com Esc
				_voltar_da_previa()
			get_viewport().set_input_as_handled()
		elif janela is JanelaAposentar:
			_fechar()
			get_viewport().set_input_as_handled()
		elif janela is JanelaMapa:
			_fechar_mapa()
			get_viewport().set_input_as_handled()
