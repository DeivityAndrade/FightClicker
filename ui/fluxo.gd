class_name Fluxo
extends Control
## Maestro das telas da Fase 3 por cima da garagem: prévia -> luta (arena) -> vitória/cinturão ou fim de carreira,
## e APOSENTAR (confirmação -> "saiu por cima"). Só liga sinais do GameState às janelas e chama as funções públicas
## dele (`previa()`, `lutar()`, `concluir_luta()`, `aposentar()`, `nova_carreira()`). Nenhuma regra aqui.
##
## Ao abrir o jogo (fase3-api §8): tela de fim pendente -> luta pendente (pula a animação) -> garagem.

signal janela_mudou(aberta: bool)
## ID4: o menu principal escolheu e o Fluxo já agiu. `acao`: "continuar" | "novo_jogo" | "sair" | "copia_falhou" (o save foi mantido, o menu segue aberto).
signal menu_escolheu(acao: String)

## Script do menu (UI/UX). Se não existir, o jogo abre direto na sala, como antes. Variável para os testes trocarem por um menu falso.
var caminho_menu := "res://ui/menu_principal.gd"
var acao_sair := Callable()  # só para testes: no lugar de fechar o jogo no SAIR
var menu: Control  # o menu principal enquanto aberto (contrato: docs/fases/identidade-id4-contrato.md)

var tela: TelaLuta
var janela: JanelaBase  # prévia, vitória, fim ou confirmação de aposentar (só uma por vez)

var cartao: CartaoInicio  # "o que você trouxe" (Fase 4): não é janela, não bloqueia o alvo, mas pausa o Metrônomo

var ronda: TelaRonda  # Ronda Noturna: a tela do minigame enquanto o jogador está na rua à noite
var treino: TelaTreino  # 7a2: a tela do minigame (Choque ou Panfletagem) enquanto o jogador está no treino fora de hora

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
	GameState.treino_fora_mudou.connect(_ao_treino_fora)
	GameState.ronda_mudou.connect(_ao_ronda)
	if _menu_automatico():
		mostrar_menu()  # ID4: o menu vem primeiro; as pendências esperam ele fechar
	call_deferred("_checar_pendencias")


## Liga os botões LUTAR! e APOSENTAR da barra de baixo.
func ligar(barra: BarraBaixo) -> void:
	_barra = barra
	if menu != null:
		barra.definir_janela_aberta(true)  # o menu abriu antes da barra ser ligada
	barra.lutar_pedido.connect(abrir_previa)
	barra.aposentar_pedido.connect(abrir_aposentar)


func ocupado() -> bool:
	return janela != null or tela.visible or treino != null or ronda != null or menu != null


# --- ID4: menu principal (abre antes de tudo; CONTINUAR / NOVO JOGO / SAIR) ---

## O menu abre sozinho ao iniciar o jogo, exceto em testes e ferramentas (`--script`) e com `--sem-menu`.
func _menu_automatico() -> bool:
	var args := OS.get_cmdline_args()
	return not ("--script" in args or "-s" in args or "--sem-menu" in OS.get_cmdline_user_args() or "--sem-menu" in args)


## Abre o menu. Devolve false (e nada muda) se o script do menu não existe ou não segue o contrato.
func mostrar_menu() -> bool:
	if menu != null:
		return true
	if not ResourceLoader.exists(caminho_menu):
		return false
	var script = load(caminho_menu)
	if not (script is GDScript) or not (script as GDScript).can_instantiate():
		return false
	var novo = (script as GDScript).new()
	if not (novo is Control) or not novo.has_signal("escolheu"):
		if novo is Node:
			novo.free()
		return false
	menu = novo
	menu.escolheu.connect(_ao_menu_escolheu)
	GameState.definir_menu_aberto(true)  # jogo parado, nada salvo, nenhuma janela por baixo
	Dica.limpar()
	_fechar_cartao()
	add_child(menu)
	if _barra != null:
		_barra.definir_janela_aberta(true)
	janela_mudou.emit(true)
	return true


func _ao_menu_escolheu(acao: String) -> void:
	if menu == null:
		return
	match acao:
		"sair":
			if acao_sair.is_valid():
				acao_sair.call()  # gancho dos testes (não podem fechar o processo)
			else:
				get_tree().quit()  # sem salvar: nada mudou desde que o menu abriu
			menu_escolheu.emit(acao)
			return
		"novo_jogo":
			if GameState.tem_save():
				GameState.novo_jogo_com_copia()
				if GameState.tem_save():
					menu_escolheu.emit("copia_falhou")  # a cópia falhou: o save foi mantido e o menu continua
					return
			else:
				GameState.apagar_save()  # sem save: só zera o estado (a abertura toca)
		"continuar":
			pass
		_:
			return
	_fechar_menu()
	menu_escolheu.emit(acao)


func _fechar_menu() -> void:
	if menu == null:
		return
	menu.queue_free()
	menu = null
	GameState.definir_menu_aberto(false)
	if _barra != null and janela == null and not tela.visible:
		_barra.definir_janela_aberta(false)
	janela_mudou.emit(ocupado())
	call_deferred("_checar_pendencias")  # fim pendente, luta pendente, escolha de arte, prévia do dia


# --- Fase 7a2: treino fora de hora (IR no balão do Osmar -> Choque ou Panfletagem -> prêmio -> VOLTAR) ---

## Clicou em IR (ou no Osmar com o balão aberto). O GameState consome o convite e abre o minigame; a tela nasce pelo sinal
## `treino_fora_mudou` e aqui recebe o resto (o boato do Osmar, que só vem na resposta do IR).
func ir_para_treino() -> void:
	if ocupado() or GameState.convite_visivel() == "":
		return
	var info := GameState.convite_ir()
	if info.is_empty():
		return
	if treino == null:
		_abrir_treino(str(info.get("kind", "")))
	treino.definir_info(info)


func _ao_treino_fora(estado: String) -> void:
	if estado == "":
		_fechar_treino()
	elif treino == null:
		_abrir_treino(estado)  # o IR veio de outro lugar (teste, atalho): a tela abre igual, sem o boato


func _abrir_treino(estado: String) -> void:
	if estado == "" or treino != null:
		return
	if GameState.treino_jogo() == null:
		return
	Dica.limpar()
	_fechar_cartao()
	treino = TelaChoque.new() if estado == "spar" else TelaPanfleto.new()
	add_child(treino)
	treino.abrir({"kind": estado, "art": GameState.arte_id, "rumor_text": ""})
	if _barra != null:
		_barra.definir_janela_aberta(true)
	janela_mudou.emit(true)


func _fechar_treino() -> void:
	if treino == null:
		return
	treino.queue_free()
	treino = null
	if _barra != null and janela == null and not tela.visible:
		_barra.definir_janela_aberta(false)
	janela_mudou.emit(ocupado())


# --- Ronda Noturna (clique no capuz -> "Estátua no telhado" -> prêmio -> VOLTAR) ---

var _esperando_info_ronda := false

## Clicou no capuz no prego. O GameState abre a noite e congela o jogo; a tela nasce com a resposta do IR (camadas da rua, nomes).
func ir_para_ronda(noite: String = "", bandido: String = "") -> bool:
	if ocupado():
		return false
	if noite == "" and bool(GameState.capuz_info().get("hideout", false)):
		abrir_esconderijo()  # 2a1: com a briga aberta o capuz leva ao Esconderijo (nada muda no jogo até escolher o IR)
		return true
	_esperando_info_ronda = true
	var info := GameState.ronda_ir(noite, bandido)
	_esperando_info_ronda = false
	if info.is_empty():
		return false
	if ronda == null:
		_abrir_ronda(info)
	return true


func _ao_ronda(id: String) -> void:
	if id == "":
		_fechar_ronda()
		# 2a1: a noite de briga acabou por baixo (a trava de 120 s no prêmio devolveu a sala): a arena e a janela saem junto.
		if janela is JanelaPremioBriga or (tela.visible and str(tela.luta.get("night", "")) == "alley"):
			_fechar_tudo()
	elif ronda == null and not _esperando_info_ronda:
		_abrir_ronda({})  # a Ronda abriu por outro caminho (teste, atalho): a tela abre igual, com a rua do nível


# --- Ronda 2a1: Esconderijo (o capuz com a briga aberta), ficha do Dossiê e a noite de briga ---

func abrir_esconderijo(dados: Dictionary = {}) -> void:
	if ocupado():
		return
	var j := TelaEsconderijo.new()
	_abrir(j)
	Dica.limpar()
	j.abrir_com(dados)
	j.voltar_pedido.connect(_fechar)  # VOLTAR: fecha a tela, nada gravado, o capuz continua no prego
	j.ir_pedido.connect(_ir_do_esconderijo)
	j.ficha_pedida.connect(_abrir_ficha)


func _ir_do_esconderijo(noite: String, bandido: String) -> void:
	if not (janela is TelaEsconderijo):
		return
	janela.queue_free()
	janela = null
	GameState.definir_modal(false)
	if not ir_para_ronda(noite if noite != "" else "scare", bandido):
		abrir_esconderijo()  # a noite não abriu (fora de ordem, sem capuz): o Esconderijo volta


func _abrir_ficha(bandido: String) -> void:
	if not (janela is TelaEsconderijo):
		return
	var fichas: Array = GameState.dossie().duplicate()
	var chefe: Dictionary = GameState.esconderijo().get("boss", {})
	if not chefe.is_empty() and bool(chefe.get("known", false)):
		fichas.append(chefe)  # 2a2: a ficha do chefe (id no lugar de bandit)
	for f in fichas:
		if str(f.get("bandit", f.get("id", ""))) == bandido:
			var j := JanelaFicha.new()
			_abrir(j)
			j.abrir_com(f)
			j.fechar_pedido.connect(func() -> void:
				if janela == j:
					janela.queue_free()
					janela = null
					abrir_esconderijo())
			return


## Fim da aproximação: a prévia da noite (a tela da Ronda avisa depois do letreiro do SUSTO / VISTO).
func _abrir_previa_briga() -> void:
	if janela != null or ronda == null:
		return
	var dados := GameState.briga_previa()
	if dados.is_empty():
		return
	var j := JanelaPreviaBriga.new()
	_abrir(j)
	j.abrir_com(dados)
	j.sair_pedido.connect(_sair_da_briga)
	j.lutar_pedido.connect(_lutar_briga)


## SAIR na prévia: nada gravado, a sala volta e o capuz continua no prego.
func _sair_da_briga() -> void:
	if janela != null:
		janela.queue_free()
		janela = null
	GameState.definir_modal(false)
	GameState.ronda_concluir()  # {left: true}: já devolve a sala (ronda_mudou("") fecha a tela da Ronda)
	_fechar_ronda()
	if _barra != null and not tela.visible:
		_barra.definir_janela_aberta(false)
	janela_mudou.emit(ocupado())


func _lutar_briga(tatica_id: String) -> void:
	var info := GameState.briga_lutar(tatica_id)  # grava tudo agora e devolve a luta para a arena
	if info.is_empty():
		return
	if janela != null:
		janela.queue_free()
		janela = null
	if ronda != null:
		ronda.visible = false
	tela.iniciar(info)
	if _barra != null:
		_barra.definir_janela_aberta(true)
	janela_mudou.emit(true)


func _abrir_premio_briga(premio: Dictionary) -> void:
	var j := JanelaPremioBriga.new()
	_abrir(j)
	j.abrir_com(premio)
	j.voltar_pedido.connect(_voltar_da_briga)


func _voltar_da_briga() -> void:
	GameState.ronda_voltar()  # devolve a sala (a tela da Ronda fecha pelo sinal)
	_fechar_ronda()
	_fechar_tudo()


func _abrir_ronda(info: Dictionary) -> void:
	if ronda != null or GameState.ronda_jogo() == null:
		return
	Dica.limpar()
	_fechar_cartao()
	ronda = TelaRonda.new()
	add_child(ronda)
	ronda.previa_pedida.connect(_abrir_previa_briga)
	ronda.abrir(info)
	if _barra != null:
		_barra.definir_janela_aberta(true)
	janela_mudou.emit(true)


func _fechar_ronda() -> void:
	if ronda == null:
		return
	ronda.queue_free()
	ronda = null
	if _barra != null and janela == null and not tela.visible:
		_barra.definir_janela_aberta(false)
	janela_mudou.emit(ocupado())


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
	if str(resumo.get("night", "")) == "alley":
		_abrir_premio_briga(resumo.get("prize", {}))  # noite de briga: vitória ou derrota, a janela do prêmio da noite
		return
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
	j.nova_carreira_pedido.connect(func() -> void: GameState.receber_discipulo())
	j.arvore_pedido.connect(abrir_arvore)
	j.mural_pedido.connect(abrir_mural)


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



# --- Fase 6c2: o mural da escola (parede da sala em qualquer hora; botão MURAL da tela de fim, onde o hall compra) ---

func abrir_mural() -> void:
	if janela != null and not (janela is JanelaFim):
		return  # só a tela de fim cede o lugar ao mural
	if tela.visible and not (janela is JanelaFim):
		return
	if janela == null and (GameState.sucessao_estado() != "none" or GameState.cena_sala != "" or GameState.acoes_bloqueadas()):
		return
	var do_fim := janela is JanelaFim
	var j := JanelaMural.new()
	_abrir(j)
	Dica.limpar()
	j.abrir_com(do_fim)
	j.fechar_pedido.connect(_fechar_mural)


## Fecha o mural (X ou Esc). Quem veio da tela de fim volta para ela (com o saldo de Honra novo); da sala volta para a sala.
func _fechar_mural() -> void:
	if not (janela is JanelaMural):
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
	dados = _com_mural(dados)
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
		var dados := _com_mural(GameState.cartao_inicio())  # agora com a arte ("ARTE: BOXE")
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


# --- Fase 6b1: tela "RECEBER NOVO DISCÍPULO" (a cena de passar o posto pede; só sai pelo CONFIRMAR) ---

func abrir_criar_discipulo() -> void:
	if janela is TelaCriarDiscipulo or GameState.sucessao_estado() != "creating":
		return
	var j := TelaCriarDiscipulo.new()
	_abrir(j)
	j.abrir_com()
	j.confirmou.connect(func() -> void:
		if janela == j:
			janela = null
			j.queue_free()
			GameState.definir_modal(tela.visible)
			if _barra != null and not tela.visible:
				_barra.definir_janela_aberta(false)
			janela_mudou.emit(ocupado()))


# --- 8a2: contrato do patrocinador (o envelope PROPOSTA no chão da sala) ---

## Abre o contrato. Só com a sala livre e a oferta em aberto ("offered"). ASSINAR grava o contrato (GameState); AGORA NÃO só fecha:
## o envelope continua no chão até o fim da campanha.
func abrir_patrocinio() -> void:
	if ocupado() or GameState.patrocinio_estado != "offered" or GameState.acoes_bloqueadas():
		return
	var p: Dictionary = GameState.patrocinio()
	if p.is_empty():
		return
	var j := JanelaPatrocinio.new()
	_abrir(j)
	Dica.limpar()
	j.abrir_com(p)
	j.fechou.connect(func() -> void:
		if janela == j:
			_fechar())
	j.assinou.connect(func() -> void:
		if GameState.assinar_patrocinio():
			j.mostrar_assinado()
		else:
			_fechar())


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
	if treino != null and GameState.treino_fora == "":
		_fechar_treino()  # nova carreira ou carga do save com o minigame aberto: a sala volta
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
	if janela != null or tela.visible or menu != null:
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
		elif janela is JanelaAposentar or janela is TelaEsconderijo:
			_fechar()
			get_viewport().set_input_as_handled()
		elif janela is JanelaFicha:
			janela.fechar_pedido.emit()
			get_viewport().set_input_as_handled()
		elif janela is JanelaPatrocinio:
			_fechar()  # Esc = AGORA NÃO
			get_viewport().set_input_as_handled()
		elif janela is JanelaMural:
			_fechar_mural()
			get_viewport().set_input_as_handled()
		elif janela is JanelaMapa:
			_fechar_mapa()
			get_viewport().set_input_as_handled()


## 6c2: a linha "O MURAL: +N% DE TREINO" do cartão de início (só com bônus). Sem nós nem arte o cartão nasce só com ela.
func _com_mural(dados: Dictionary) -> Dictionary:
	var pct := int(GameState.mural().get("bonus_pct", 0))
	if pct <= 0:
		return dados
	var d := dados.duplicate()
	if d.is_empty():
		d = {"title": GameState.preencher(GameState.texto_ui("career_card_title_named", "{nome}: O QUE VOCÊ TROUXE"),
			{"nome": GameState.nome_lutador().to_upper()}), "nodes": [], "art": "", "art_text": ""}
	d["mural_text"] = UiTema.txt("start_card_mural", "O MURAL: +{pct}% DE TREINO", {"pct": pct})
	return d
