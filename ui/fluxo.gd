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
	call_deferred("_checar_pendencias")


## Liga os botões LUTAR! e APOSENTAR da barra de baixo.
func ligar(barra: BarraBaixo) -> void:
	_barra = barra
	barra.lutar_pedido.connect(abrir_previa)
	barra.aposentar_pedido.connect(abrir_aposentar)


func ocupado() -> bool:
	return janela != null or tela.visible


# --- Prévia e luta ---

func abrir_previa() -> void:
	if ocupado() or not GameState.pode_lutar():
		return
	var dados := GameState.previa()
	if dados.is_empty():
		return
	var j := JanelaPrevia.new()
	_abrir(j)
	_tatica_antes = str(dados.tactic)
	j.abrir_com(dados)
	j.voltar_pedido.connect(_voltar_da_previa)
	j.lutar_pedido.connect(_lutar)


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
	j.continuar_pedido.connect(_fechar_tudo)


# --- Fim de carreira ---

func _ao_fim_de_carreira(fim: Dictionary) -> void:
	_abrir_fim(fim)


func _abrir_fim(fim: Dictionary) -> void:
	if janela is JanelaFim:
		return
	if janela != null:
		_fechar()
	var j := JanelaFim.new()
	_abrir(j)
	# Som: a derrota já tocou durante a luta; na aposentadoria e ao reabrir o jogo toca ao abrir.
	j.abrir_com(fim, str(fim.kind) == "retire" or not tela.visible)
	j.nova_carreira_pedido.connect(func() -> void: GameState.nova_carreira())
	j.arvore_pedido.connect(abrir_arvore)


# --- Árvore de habilidades (Fase 4): só entre carreiras, pelo botão ÁRVORE da tela de fim ---

func abrir_arvore() -> void:
	if not GameState.arvore_aberta():
		return
	var j := JanelaArvore.new()
	_abrir(j)
	j.abrir_com()
	j.nova_carreira_pedido.connect(func() -> void: GameState.nova_carreira())


# --- Cartão "o que você trouxe" (começo da carreira) ---

func _ao_nova_carreira_iniciada(dados: Dictionary) -> void:
	if dados.is_empty():
		return  # sem nós comprados não há o que mostrar
	_fechar_cartao()
	cartao = CartaoInicio.new()
	add_child(cartao)
	cartao.abrir_com(dados)
	cartao.fechou.connect(_ao_cartao_fechou)
	GameState.definir_modal(true)  # o Metrônomo pausa enquanto o cartão está na tela


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
	if (janela is JanelaFim or janela is JanelaArvore) and not GameState.tem_fim_pendente():
		_fechar_tudo()  # NOVA CARREIRA: volta para a garagem
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
			_voltar_da_previa()
			get_viewport().set_input_as_handled()
		elif janela is JanelaAposentar:
			_fechar()
			get_viewport().set_input_as_handled()
