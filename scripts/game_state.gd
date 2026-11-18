extends Node
## Estado central do jogo (autoload "GameState"): a carreira da garagem.
## Guarda saldo de Treino, atributos, foco, geradores e melhorias; roda o tick passivo e o autosave.
## A UI só escuta os sinais e chama as ações. Contrato: docs/fases/fase2-api.md.
##
## Regra da fase: todo treino ganho (clique ou passivo) soma ao mesmo tempo no saldo e no
## atributo do aparelho em foco. Gastar saldo nunca reduz atributo.

signal treino_mudou(valor: float)
signal atributo_mudou(atributo: String, valor: float)
signal foco_mudou(aparelho: String)
signal clicou(ganho: float, critico: bool, aparelho: String, atributo: String, texto_critico: String)
signal gerador_mudou(gerador: String, quantidade: int)
signal melhoria_comprada(aparelho: String, melhoria: String, nivel: int)
signal economia_mudou()
signal carreira_mudou()
signal salvo(horario_texto: String)
signal avisos_mudaram(avisos: Array[String])
signal carregado(status: int)
# --- Fase 3 (contrato: docs/fases/fase3-api.md) ---
signal dinheiro_mudou(valor: float)
signal fama_mudou(valor: int)
signal escada_mudou()  # indice_escada, cinturão ou Legado em jogo mudaram
signal tatica_mudou(tatica: String)
signal luva_mudou(nivel: int, sprite_suffix: String)
signal gerador_pago_mudou(gerador: String, quantidade: int)
signal luta_iniciada(luta: Dictionary)  # resultado já decidido e salvo; a UI só anima
signal luta_resolvida(resumo: Dictionary)  # vitória aplicada ou fim de carreira criado
signal fim_de_carreira(fim: Dictionary)  # tela de fim pendente (derrota ou aposentadoria)
signal risco_proxima_mudou(adversario: String, rotulo: String)  # HUD "PRÓXIMA: nome + risco"
signal permanente_mudou()
# --- Fase 4 (contrato: docs/fases/fase4-api.md) ---
signal auto_socou(ganho: float, critico: bool, aparelho: String, atributo: String, texto_critico: String)
signal metronomo_mudou(nivel: int)  # compra, nova carreira, carga do save
signal arvore_mudou()  # nó comprado (Legado e skill_nodes mudaram)
signal no_revelado(ids: Array)  # Fase 5.4: nós que ficaram à vista com a última compra (a UI anima)
signal nova_carreira_iniciada(cartao: Dictionary)  # só em NOVA CARREIRA (não na carga do save)
signal aparelho_comprado(aparelho: String)  # Fase 4b: aparelho montado (a UI faz a chegada)
signal evento_dourado(duracao: float)  # o cinturão dourado aparece na sala: clicar nele liga o FRENESI
signal frenesi_mudou(restante: float)  # FRENESI ligado (segundos restantes) ou desligado (0)
signal bolsa_paga(ganho: float)  # Fase 5.2: a bolsa da torcida foi clicada (treino já somado)
signal crew_click_mudou(comprado: bool)  # Fase 5.2: Grito da equipe comprado, NOVA CARREIRA ou carga do save
signal assistido_mudou(estado: String)  # "off" | "waiting" | "active" | "metronome"
# --- Fase 5 (contrato: docs/fases/fase5-api.md) ---
signal local_mudou(local: String)  # MUDAR, NOVA CARREIRA ou carga do save
signal arte_mudou(arte: String)  # escolha da arte, NOVA CARREIRA ("" = sem arte) ou carga do save
signal escolha_arte_pedida(primeira: bool)  # a janela de escolha da arte deve abrir (1ª chegada, início de carreira, reabrir o jogo)
# Fase 5.1: caixa de equipamento
signal caixa_criada(item: String, tipo: String)  # compra: caixa nova (tipo "apparatus" | "glove")
signal caixa_batida(item: String, batidas: int)  # cada clique na caixa (1, 2, 3); o 3º vem seguido de caixa_aberta
signal caixa_aberta(item: String, tipo: String)  # 3º clique: item já aplicado e salvo (a UI só anima)
signal caixas_mudaram()  # lista de caixas trocada de uma vez (carga do save, NOVA CARREIRA)
signal dia_mudou(dia: int)  # Fase 5.3: o relógio da campanha virou o dia
signal aviso_data(dias: int)  # faixa de aviso: dias que faltam (uma vez ao passar de warn_days e uma ao passar de warn_sound_days)
signal dia_da_luta_chegou()  # o relógio travou no dia da luta: abrir a prévia do dia
signal campanha_completa_mudou()  # venceu o último adversário (ou carga/nova carreira mudou o estado)
signal sala_ativa_mudou(ativa: bool)  # a condição única de tick mudou

# Fase 6a: falas, abertura, marcos da escola e gesto (contrato da UI em docs/fases/fase6a-api.md)
signal fala_pedida(speaker: String, text: String, id: String)  # mostrar o balão (speaker = "first" | "coach")
signal fala_cancelada(id: String)  # fechar o balão na hora (janela abriu, luta começou, abertura pulada)
signal comentario(line_id: String)  # um comentário começou (também com os balões escondidos)
signal marco_gravado(id: String)  # marco da escola gravado (a parede da garagem pode mudar)
signal abertura_mudou(estado: String)  # "pending" | "playing" | "over"
signal gesto_pedido(plano: Dictionary)  # tocar o gesto do 1º lutador (plano: ver pedir_gesto)
signal gesto_cancelado()  # clique ou janela: parar o gesto e cortar o som dele

# Fase 6b1: passar o posto (contrato da UI em docs/fases/fase6b1-api.md)
signal sucessao_mudou(estado: String)  # "none" | "scene_1" | "creating" | "scene_2" | "arriving"
signal rascunho_mudou()  # nome ou visual do rascunho mudou (sorteio, troca de campo, nome corrigido)
signal toques_mentor_pedidos(plano: Dictionary)  # o John sentado faz os dois toques sem luva (plano: ver _pedir_toques)
signal toques_mentor_cancelados()  # clique, janela, luta ou mudança de local: parar a pose e cortar o 2º toque

# Fase 6c1 (Casa nova): chegada à academia e saída do John (contrato: docs/fases/fase6c1-api.md)
signal cena_sala_pedida(id: String)  # a cena de uma vez na vida deve tocar agora (relógio parado até cena_sala_terminou)
signal saida_mentor_pedida()  # a saída do John começa (cena sem controle preso); marco e `mentor_leaves` já salvos
signal saida_mentor_interrompida()  # janela, luta, MUDAR, tela de fim ou RECEBER: a cena aplica o end_state na hora

# Fase 6c2 (Mais longe que eu): Honra, hall e mural (contrato: docs/fases/fase6c2-api.md)
signal honra_mudou(honor: int)  # saldo de Honra mudou (fim de campanha por vontade, compra no hall, carga do save)
signal hall_mudou()  # nó do hall comprado ou carga do save
signal previa_falta_pronta(texto: String)  # a linha "FALTA ~N DE ATRIBUTO" da prévia ficou pronta (calculada em segundo plano)

const CAMINHO_CONFIG := "res://data/config.json"
# Pasta usada quando o autoload sobe dentro de um teste (--script): nunca o save real.
const PASTA_SAVE_TESTES := "user://test/autoload/"
# Limite técnico do float (precisão dupla), para nunca virar infinito.
const VALOR_MAXIMO := 1.7976931348623157e308

var treino := 0.0  # saldo de Treino
var atributos: Dictionary = {}  # id do atributo -> float (nunca diminui)
var foco := ""  # id do aparelho em foco
var geradores: Dictionary = {}  # id do gerador -> quantidade (int)
var niveis_melhoria: Dictionary = {}  # id do aparelho -> nível comprado (int)
# Fase 3: resto do bloco `career` do save
var geradores_pagos: Dictionary = {}  # id do gerador pago -> quantidade (int)
var nivel_luva := 0  # 0 = luva velha
var dinheiro := 0.0
var fama := 0
var indice_escada := 0  # vitórias da carreira (= próximo adversário); == nº de adversários: acabou
var cinturao := false
var tatica := ""  # última tática escolhida
var tempo_jogo := 0.0  # segundos de jogo desta carreira
var dinheiro_ganho := 0.0  # soma dos prêmios da carreira
var luta: Dictionary = {}  # career.fight: luta decidida e ainda não aplicada ({} = nenhuma)
# Evento dourado (estilo "biscoito dourado"): de vez em quando um cinturão dourado aparece por alguns segundos; quem clica nele
# ganha o FRENESI: treino multiplicado nos CLIQUES e nos auto-socos por alguns segundos (não multiplica a renda da equipe: só rende para quem clica).
# Não é salvo (é passageiro) e não conta enquanto uma janela/luta estiver aberta.
# Valores vindos de data/training.json -> golden_event (carregados em inicializar, junto com `dados`).
var FRENESI_MULT := 7.0
var FRENESI_DURACAO := 12.0
var EVENTO_DURACAO := 7.0
var EVENTO_ESPERA_MIN := 45.0
var EVENTO_ESPERA_MAX := 90.0
var frenesi_restante := 0.0
var evento_dourado_restante := 0.0  # > 0: o cinturão dourado está na sala esperando o clique
var evento_dourado_tipo := "frenzy"  # Fase 5.2: "frenzy" (luva x7) | "crew" (bolsa da torcida), sorteado ao aparecer
var crew_click_comprado := false  # Fase 5.2: career.crew_click (Grito da equipe)
var _evento_espera := -1.0
var _rng_evento := RandomNumberGenerator.new()  # próprio: não mexe nos sorteios de crítico (testes determinísticos)
var nivel_metronomo := 0  # Fase 4: 0 = sem Metrônomo (career.metronome_level)
var local_id := ""  # Fase 5: career.location ("garage" | "gym")
var arte_id := ""  # Fase 5: career.art ("" = sem arte)
var arte_segundos := 0.0  # Fase 5: career.art_seconds, tempo de carreira desde a escolha da arte
# Bloco `permanent` do save
var permanente: Dictionary = {}
# `ending` do save: tela de fim pendente ({} = nenhuma)
var fim: Dictionary = {}

var config: Dictionary = {}
var dados: TrainingData
var academia: GymData  # Fase 5: locais e artes (data/locations.json, data/arts.json)
var lutas: FightData  # adversários, táticas, loja, Legado (data/fights|opponents|shop|career.json)
var motor: Luta  # simulação da luta
var golpes: MovesData  # golpes das lutas por estilo (data/moves.json): jogador e adversários usam o mesmo catálogo
var risco_hud_ativo := true  # testes podem desligar o recálculo periódico do HUD
var rng := RandomNumberGenerator.new()
var store: SaveStore
var ultimo_save_unix := 0
var ultimo_save_texto := "nenhum"
var avisos: Array[String] = []
var autosave_ativo := true

var _tempo_autosave := 0.0
var _tempo_risco := 0.0
var _chave_risco := ""
var _risco_hud := {"adversario": "", "rotulo": "", "tatica": ""}
var _motivo_tarefa := -1  # id da tarefa em segundo plano (-1 = nenhuma)
var _motivo_fundo: Dictionary = {}
var _motivo_seed := 0
var _motivo_cache: Dictionary = {}  # motivo da derrota da luta atual (calculado sob demanda)
# Fase 4
var modal_aberto := false  # a UI marca true com prévia, confirmação, vitória ou cartão abertos: o Metrônomo pausa
var _bonus: Dictionary = {}  # bônus da árvore da carreira em andamento (recalculado em nova carreira e carga)
var _acc_metronomo := 0.0  # tempo acumulado até o próximo auto-soco (não vai para o save)
var auto_socos_total := 0  # depuração/QA: auto-socos dados desde que o jogo abriu
var assist_socos_total := 0  # QA: auto-socos do modo assistido (também contam em auto_socos_total)
var aparelhos_montados_ids: Array = []  # career.apparatus_owned, na ordem da compra
var caixas_lista: Array = []  # Fase 5.1: career.boxes = [{item, kind, hits}], na ordem da compra
var _segurando := false  # Shift/botão SEGURAR pressionado (não vai para o save)
var _acc_assist := 0.0
var _ocioso := 1.0e9  # segundos desde o último clicar() do jogador
var _estado_assist := "off"
var _assist_interval := 3.0
# Tempo morto (debug/QA): garagem livre, próximo adversário perigoso na melhor tática e nada da loja cabe no dinheiro
var _morto_atual := 0.0
var _morto_max := 0.0
var _morto_total := 0.0
var _perigoso_melhor := false
var _chave_melhor := ""
var _tempo_melhor := 0.0
var segundos_campanha := 0.0  # Fase 5.3: career.campaign_seconds, relógio da campanha (só anda com sala_ativa)
var fight_day := -1  # Fase 5.3: career.fight_day, data da próxima luta (-1 = sem próxima luta)
var _dia_anterior := 1
var _aviso_data_chave := -2  # fight_day cujos avisos já foram dados
var _aviso_feito := {"warn": false, "sound": false}
var _dia_chegou_emitido := false
var _sala_antes := true
var _estilo: Dictionary = {}  # Fase 5: arte -> soma dos nós ESTILO comprados (art_rule_bonus)
var nos_ativos_ids: Array = []  # Fase 5.4: foto dos nós que valem NESTA campanha (career.active_nodes)

# Fase 6a: escola (fora do reset da carreira), falas e gesto
const MARCOS_VERSAO := 1
var escola: Dictionary = {}  # state.school: first_fighter_campaign, milestones, lines_seen, last_end
var gestos_calcados: Array = []  # career.gestured_gloves: níveis de luva que já tiveram o gesto de calçar
var dialogos: DialogosData
var baloes_escondidos := false  # opção de teste (aceite 3): nada de balão, mas marcos e lines_seen valem igual
var _t_real := 0.0  # tempo real desde que o jogo abriu (conta luta e janela; não vai para o save)
var _ultimo_comentario := -1.0e9
var _calma := 0.0  # segundos seguidos de sala ativa
var _parado := 0.0  # segundos de sala ativa sem clique (zera no clique; começa em 0 ao carregar)
var _gatilhos_quadro: Array = []  # gatilhos chegados neste quadro: [{id, params}]
var _vaga: Dictionary = {}  # a única vaga de espera: {id, params, prio, espera}
var _balao: Dictionary = {}  # balão na tela: {id, ate}
var _abertura := "pending"
var _abertura_t := 0.0
var _abertura_idx := 0
var _abertura_proxima := 0.0
var _gesto: Dictionary = {}  # gesto tocando: {momento, ate}
var _gestos_parada := 0
var _proximo_gesto_parada := 20.0
var _idle_comentou := false
var _garagem_retomada := false
var _derrota_rearmada := false  # 1ª derrota já disparada nesta sessão (nova_carreira ou carga)
var _fala_recusada := false  # a UI recusou o balão que acabou de ser pedido
var _metro_prev := 0
var _crew_prev := false
var _rng_fala := RandomNumberGenerator.new()

# Fase 6b1: passar o posto, discípulo e John mentor
var disciples: DiscipulosData  # data/disciples.json + banco de nomes
var discipulo: Dictionary = {}  # career.disciple {name, look, campaign}; {} = campanha do John (ou criação em andamento)
var mentor_cumprimentou := false  # career.mentor_greeted: os toques do 1º clique da campanha já foram dados
var sucessao := "none"  # "none" | "scene_1" | "creating" | "scene_2" | "arriving" (só em memória; o save guarda school.handover)
var sucessao_retomada := false  # true quando o estado veio de um save aberto no meio (a cena grande não toca)
var _pontos_cena: CenaDados = null  # só para ler pontos nomeados do manifest (mentor_2_spot)
var _cena_grande_ativa := false  # a primeira_sucessao tocou NESTA sessão (a reação do 1º clique está armada)
var _rng_sucessao := RandomNumberGenerator.new()  # próprio: não mexe em crítico, luta nem calendário
var _toques: Dictionary = {}  # toques tocando: {momento, inicio, ate, guarda}
var _toque_ultimo := -1.0e9  # _t_real do início do último toque (intervalo de 60 s)
var _toque_vitoria := -1.0  # >= 0: segundos de sala ativa desde a vitória; -1 = nada pendente

# Fase 6c1 (nada disto vai para o save: o que importa fica nos marcos da escola)
var escola_cfg: Dictionary = {}  # data/escola.json
var hall_cfg: Dictionary = {}  # data/hall.json (6c2): Honra, bônus do retrato e nós do hall
var _falta_tarefa := -1  # tarefa em segundo plano da linha "o que mais falta" da prévia (-1 = nenhuma)
var _falta_fundo: Dictionary = {}
var _falta_cache: Dictionary = {}  # {chave, texto}
var cena_sala := ""  # "" | "primeira_academia": a cena de chegada está tocando (relógio e cliques parados)
var _saida_tocando := false  # a saída do John está tocando agora
var _saida_inicio := 0.0  # _t_real do começo da saída
var _saida_elenco: Dictionary = {}  # {seat, stand, coach}: quem a sala desenhava no começo da saída
var _cena_sala_t := 0.0  # segundos reais da cena da academia (trava de segurança se a interface nunca avisar o fim)
var _academia_rearmada := false  # a cl_primeira_academia já foi (re)disparada nesta sessão
var _arte_comentada := false  # o comentário da arte desta campanha já saiu (ou não vale mais)
var _reacao_cena := ""  # cena que armou a reação do 1º clique ("primeira_sucessao"); "" = toques sem fala
var _falta_chave_atual := ""

# Módulos (scripts/estado/): a lógica de cada assunto mora lá e trabalha nas variáveis acima.
const _Depuracao := preload("res://scripts/estado/depuracao.gd")
var _depur := _Depuracao.new(self)


func _ready() -> void:
	rng.randomize()
	inicializar(_pasta_save_inicial(), CAMINHO_CONFIG)
	# Fechar pelo X passa por _notification, que salva antes de sair.
	get_tree().set_auto_accept_quit(false)


func _process(delta: float) -> void:
	tick(delta)
	_finalizar_motivo(true, false)  # recolhe sem travar o quadro
	_finalizar_falta(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		definir_assistido(false)  # perder o foco da janela = soltar o Shift
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_finalizar_motivo(false)  # o save recalcula sob demanda se faltar
		salvar()
		get_tree().quit()


## Prepara o estado: lê data/ e carrega o save da pasta indicada.
## Os caminhos dos JSON de treino/geradores/textos existem para testes de dados.
func inicializar(pasta_save: String, caminho_config: String,
		caminho_treino: String = TrainingData.CAMINHO_TREINO,
		caminho_geradores: String = TrainingData.CAMINHO_GERADORES,
		caminho_textos: String = TrainingData.CAMINHO_TEXTOS, dados_lutas: FightData = null,
		dados_academia: GymData = null, dados_dialogos: DialogosData = null, dados_discipulos: DiscipulosData = null) -> void:
	config = GameConfig.carregar(caminho_config)
	disciples = dados_discipulos if dados_discipulos != null else DiscipulosData.carregar()
	escola_cfg = _ler_json_dados("res://data/escola.json")
	hall_cfg = _ler_json_dados("res://data/hall.json")
	_rng_sucessao.randomize()
	dialogos = dados_dialogos if dados_dialogos != null else DialogosData.carregar()
	_rng_fala.randomize()
	_ligar_gatilhos_de_fala()
	dados = TrainingData.carregar(caminho_treino, caminho_geradores, caminho_textos)
	FRENESI_MULT = dados.golden_frenzy_mult
	FRENESI_DURACAO = dados.golden_frenzy_seconds
	EVENTO_DURACAO = dados.golden_visible_seconds
	EVENTO_ESPERA_MIN = dados.golden_wait_min
	EVENTO_ESPERA_MAX = dados.golden_wait_max
	academia = dados_academia if dados_academia != null else GymData.carregar()
	academia.validar_aparelhos(dados)
	local_id = academia.local_padrao
	lutas = dados_lutas if dados_lutas != null else FightData.carregar()
	motor = Luta.new(lutas)
	golpes = MovesData.carregar()
	store = SaveStore.new(pasta_save)
	_ajustar_assist()
	carregar_save()


## Tick passivo: produção proporcional ao tempo real, não ao FPS.
func tick(delta: float) -> void:
	# Ignora delta inválido (NaN, infinito, zero ou negativo) sem tocar no acumulador do autosave.
	if not is_finite(delta) or delta <= 0.0:
		return
	# Com a tela de fim pendente (ou a sucessão em andamento, Fase 6b1) a carreira está congelada: nada produz, o tempo não anda.
	if fim.is_empty() and sucessao == "none" and cena_sala == "":  # 6c1: a cena da academia também congela a carreira
		tempo_jogo += delta
		_ocioso += delta
		_tick_risco(delta)
		# Fase 5.3: UMA condição (sala_ativa) liga relógio, equipe, Metrônomo, assistido, ouro e arte.
		# `dt` é o tempo de sala deste quadro (menor que delta se o relógio travou no dia da luta).
		var dt := _avancar_relogio(delta)
		if dt > 0.0:
			var producao := producao_total()
			if producao > 0.0:
				_ganhar(producao * dt)
			if arte_id != "":
				arte_segundos += dt
				_tick_comentario_da_arte()
			_depur._tick_tempo_morto(dt)
			_tick_metronomo(dt)
			_tick_evento_dourado(dt)
		_tick_assistido(dt)
		_verificar_calendario()
	_checar_sala()
	_tick_falas(delta)
	if autosave_ativo:
		_tempo_autosave += delta
		if _tempo_autosave >= config.autosave_intervalo_segundos:
			_tempo_autosave = 0.0
			salvar()


## A ÚNICA condição de tick: relógio da campanha, equipe, Metrônomo, assistido, clique, luva dourada e Jiu-jitsu
## só andam com ela. Perder foco ou minimizar NÃO desliga; janela, luta, escolha da arte e dia da luta sim.
func sala_ativa() -> bool:
	return fim.is_empty() and sucessao == "none" and cena_sala == "" and luta.is_empty() and not escolha_arte_pendente() and not modal_aberto and not no_dia_da_luta()


func calendario_ligado() -> bool:
	return float(lutas.calendario.get("seconds_per_day", 0.0)) > 0.0


func _segundos_por_dia() -> float:
	return float(lutas.calendario.get("seconds_per_day", 0.0))


## Dia da campanha (começa em 1). Sem calendário: sempre 1.
func dia_campanha() -> int:
	if not calendario_ligado():
		return 1
	return 1 + int(floor((segundos_campanha + 1.0e-6) / _segundos_por_dia()))


## Depois do último adversário (Kid): "Campanha completa", sem data nem relógio.
func campanha_completa() -> bool:
	return escada_completa()


## Dias que faltam para a próxima luta (0 = é hoje); -1 sem calendário ou sem próxima luta.
func dias_para_luta() -> int:
	if not calendario_ligado() or fight_day <= 0 or campanha_completa():
		return -1
	return maxi(0, fight_day - dia_campanha())


## true quando o relógio chegou na data da próxima luta (e o adversário luta neste local).
## Se o adversário pede outra sala (Tonhão com o jogador na garagem), o relógio segue sem travar.
func no_dia_da_luta() -> bool:
	if not calendario_ligado() or fight_day <= 0 or estado_escada() != "fight":
		return false
	return segundos_campanha >= _alvo_relogio() - 1.0e-6


func _alvo_relogio() -> float:
	return float(fight_day - 1) * _segundos_por_dia()


func _prep_do_indice(i: int) -> int:
	if i < 0 or i >= lutas.adversarios.size():
		return 14
	return int(lutas.adversarios[i].get("prep_days", 14)) + int(_b("prep_days_bonus"))


## Data da próxima luta contada a partir do dia de hoje (-1 se a escada acabou).
func _data_da_proxima_luta() -> int:
	if escada_completa():
		return -1
	return dia_campanha() + _prep_do_indice(indice_escada)


## Avança o relógio com a regra única. Devolve o tempo de sala usado (0 com a sala parada).
func _avancar_relogio(delta: float) -> float:
	if not sala_ativa():
		return 0.0
	if not calendario_ligado() or campanha_completa():
		return delta
	if estado_escada() == "move":
		return delta  # B3: a próxima luta é em outro local; o relógio não conta até chegar lá
	var dt := delta
	if fight_day > 0 and estado_escada() == "fight":
		var restante := _alvo_relogio() - segundos_campanha
		if restante <= delta:
			dt = maxf(restante, 0.0)
			segundos_campanha = _alvo_relogio()  # trava exatamente no dia
			return dt
	segundos_campanha += dt
	return dt


# Emite dia, avisos e chegada do dia (cada aviso uma vez por data).
func _verificar_calendario() -> void:
	if not calendario_ligado():
		return
	var dia := dia_campanha()
	if dia != _dia_anterior:
		_dia_anterior = dia
		dia_mudou.emit(dia)
	if fight_day != _aviso_data_chave:
		_aviso_data_chave = fight_day
		_aviso_feito = {"warn": false, "sound": false}
		_dia_chegou_emitido = false
	var dias := dias_para_luta()
	if dias > 0:
		var w := int(lutas.calendario.warn_days)
		var s := int(lutas.calendario.warn_sound_days)
		# B2: no máximo um aviso por verificação; o limiar mais próximo alcançado marca os anteriores
		if s > 0 and dias <= s and not _aviso_feito.sound:
			_aviso_feito.sound = true
			_aviso_feito.warn = true
			aviso_data.emit(dias)
		elif w > 0 and dias <= w and not _aviso_feito.warn:
			_aviso_feito.warn = true
			aviso_data.emit(dias)
	elif dias == 0 and fight_day > 0 and not _aviso_feito.sound:
		# B2: tick grande saltou direto para o dia: avisa uma vez com o último limiar (1 dia)
		var s2 := int(lutas.calendario.warn_sound_days)
		_aviso_feito.sound = true
		_aviso_feito.warn = true
		if s2 > 0:
			aviso_data.emit(s2)
	if no_dia_da_luta():
		if not _dia_chegou_emitido:
			_dia_chegou_emitido = true
			dia_da_luta_chegou.emit()
	else:
		_dia_chegou_emitido = false


func _checar_sala() -> void:
	var a := sala_ativa()
	if a != _sala_antes:
		_sala_antes = a
		if not a:
			_fechar_para_janela()  # Fase 6a: nunca fica balão (nem gesto da sala) por baixo de janela ou luta
			_interromper_saida()  # 6c1: janela, luta, tela de fim ou dia da luta terminam a saída do John na hora
		sala_ativa_mudou.emit(a)


## Atributo do aparelho (nos aparelhos de arte, o de maior fatia: para cor e ícone). A conta real é `divisao_aparelho`.
func atributo_do_aparelho(aparelho_id: String) -> String:
	return str(dados.aparelho(aparelho_id).get("attribute", ""))


## Como o treino do aparelho se divide nos atributos: {atributo: fração} (soma 1). Aparelho comum: 100% num atributo.
func divisao_aparelho(aparelho_id: String) -> Dictionary:
	var ap := dados.aparelho(aparelho_id)
	var d = ap.get("split", {})
	if d is Dictionary and not d.is_empty():
		return d
	var a := str(ap.get("attribute", ""))
	return {a: 1.0} if a != "" else {}


func multiplicador_aparelho(aparelho_id: String) -> float:
	var m := 1.0
	var ap := dados.aparelho(aparelho_id)
	var nivel := nivel_melhoria(aparelho_id)
	for i in nivel:
		m *= float(ap.upgrades[i].multiplier)
	return m


## Treino por clique MANUAL normal (sem crítico) com o foco atual: base x aparelho x luva x árvore x local x (1 + Boxe).
func por_clique() -> float:
	return _base_soco() * (1.0 + bonus_arte_clique()) + bonus_crew_click()


## Treino por auto-soco (Metrônomo e assistido): igual ao clique, mas sem o bônus do Boxe.
func por_auto_soco() -> float:
	return _base_soco()


func _base_soco() -> float:
	return dados.base_training * multiplicador_aparelho(foco) * multiplicador_luva() * (1.0 + _b("click_bonus")) * mult_local() * mult_escola()


## Fator que a equipe recebe: (1 + árvore) x local x (1 + Jiu-jitsu).
func _fator_equipe() -> float:
	return (1.0 + _b("passive_bonus")) * mult_local() * (1.0 + bonus_arte_equipe()) * mult_escola() * (1.0 + _hall_valor("crew_mult"))


## Treino/s vindo de todos os geradores (da garagem e pagos).
func producao_total() -> float:
	var total := 0.0
	for g in dados.geradores:
		total += producao_gerador(g.id)
	for g in lutas.geradores_pagos:
		total += producao_gerador(g.id)
	return total


## Aceita id de gerador da garagem ou pago.
func producao_gerador(gerador_id: String) -> float:
	var g := _def_gerador(gerador_id)
	if g.is_empty():
		return 0.0
	return float(g.production) * quantidade_gerador(gerador_id) * _fator_equipe()


## Aceita id de gerador da garagem ou pago.
func quantidade_gerador(gerador_id: String) -> int:
	if not lutas.gerador_pago(gerador_id).is_empty():
		return int(geradores_pagos.get(gerador_id, 0))
	return int(geradores.get(gerador_id, 0))


func _def_gerador(gerador_id: String) -> Dictionary:
	var g := dados.gerador(gerador_id)
	return g if not g.is_empty() else lutas.gerador_pago(gerador_id)


## Custo da próxima unidade (já em 3 dígitos significativos).
func custo_gerador(gerador_id: String) -> float:
	var g := dados.gerador(gerador_id)
	if g.is_empty():
		return INF
	return Economia.custo_gerador(g.base_cost, g.growth, quantidade_gerador(gerador_id))


func pode_comprar_gerador(gerador_id: String) -> bool:
	return not dados.gerador(gerador_id).is_empty() and Economia.pode_pagar(treino, custo_gerador(gerador_id))


## Quantas pessoas desenhar na sala (limite só de desenho; comprar nunca é bloqueado).
func pessoas_desenhadas(gerador_id: String) -> int:
	var g := _def_gerador(gerador_id)
	if g.is_empty():
		return 0
	var q := quantidade_gerador(gerador_id)
	var n := 0
	for limite in g.draw_thresholds:
		if limite <= q:
			n += 1
	return n


func nivel_melhoria(aparelho_id: String) -> int:
	return int(niveis_melhoria.get(aparelho_id, 0))


## Próxima melhoria do aparelho, ou {} se a linha está completa.
func proxima_melhoria(aparelho_id: String) -> Dictionary:
	var ap := dados.aparelho(aparelho_id)
	if ap.is_empty() or not aparelho_montado(aparelho_id):
		return {}
	var nivel := nivel_melhoria(aparelho_id)
	if nivel >= ap.upgrades.size():
		return {}
	return ap.upgrades[nivel]


func pode_comprar_melhoria(aparelho_id: String) -> bool:
	var m := proxima_melhoria(aparelho_id)
	return not m.is_empty() and Economia.pode_pagar(treino, m.cost)


## Sprite do aparelho: maior visual_level entre as melhorias compradas (0 se nenhuma).
func nivel_visual(aparelho_id: String) -> int:
	var ap := dados.aparelho(aparelho_id)
	var v := 0
	for i in mini(nivel_melhoria(aparelho_id), ap.get("upgrades", []).size()):
		v = maxi(v, int(ap.upgrades[i].visual_level))
	return v


## Qualquer texto de data/ui_texts.json pela chave (padrão se faltar).
func texto_ui(chave: String, padrao: String = "") -> String:
	return str(dados.ui.get(chave, padrao))


## Texto do efeito de uma melhoria, ex.: "x3 POR CLIQUE: SACO".
func texto_efeito_melhoria(melhoria: Dictionary) -> String:
	var alvo := ""
	for ap in dados.todos_aparelhos():
		for m in ap.upgrades:
			if m.id == melhoria.get("id", ""):
				alvo = str(ap.focus_label[1]).to_upper()
	var modelo: String = dados.ui.get("upgrade_effect", "x{mult} POR CLIQUE: {alvo}")
	return modelo.replace("{mult}", NumberFormat.fmt(float(melhoria.get("multiplier", 1.0)))).replace("{alvo}", alvo)


## Um clique no alvo central. Soma no saldo e no atributo do foco; emite `clicou`.
func clicar() -> Dictionary:
	_ocioso = 0.0  # mão mexendo, mesmo se a ação for recusada
	registrar_clique()  # Fase 6a: cancela o gesto e zera a "sala parada"
	if acoes_bloqueadas() or not sala_ativa():
		return {}
	_toques_do_primeiro_clique()
	return _socar(false)


## Um auto-soco do Metrônomo: o MESMO caminho do clique (aparelho em foco, luva, árvore, crítico, treino no
## atributo), mas emite `auto_socou` em vez de `clicou` (a UI não treme a tela e usa número menor).
## Normalmente chamado pelo tique do Metrônomo; público para testes.
func auto_socar() -> Dictionary:
	if acoes_bloqueadas() or not sala_ativa():
		return {}
	auto_socos_total += 1
	return _socar(true)


func _socar(auto: bool) -> Dictionary:
	var aparelho_id := foco
	var atributo := atributo_do_aparelho(aparelho_id)
	var critico := rng.randf() < dados.crit_chance
	var ganho := (por_auto_soco() if auto else por_clique()) * (dados.crit_multiplier if critico else 1.0) * mult_frenesi()
	var texto := ""
	if critico:
		var textos: Array = dados.aparelho(aparelho_id).crit_texts
		texto = str(textos[rng.randi() % textos.size()])
	_ganhar(ganho)
	var info := {"ganho": ganho, "critico": critico, "aparelho": aparelho_id,
		"atributo": atributo, "texto_critico": texto, "auto": auto}
	if auto:
		auto_socou.emit(ganho, critico, aparelho_id, atributo, texto)
	else:
		clicou.emit(ganho, critico, aparelho_id, atributo, texto)
	return info


## 7 enquanto o FRENESI está ligado, 1 nos outros casos.
func mult_frenesi() -> float:
	return FRENESI_MULT if frenesi_restante > 0.0 else 1.0


## O jogador clicou no evento dourado. Tipo "frenzy": liga o FRENESI. Tipo "crew" (bolsa da torcida): paga
## `valor_bolsa()` de uma vez, sem FRENESI e sem crítico. false se não havia evento (ou se há janela aberta).
func pegar_evento_dourado() -> bool:
	if evento_dourado_restante <= 0.0 or modal_aberto or acoes_bloqueadas():
		return false
	evento_dourado_restante = 0.0
	if evento_dourado_tipo == "crew":
		var ganho := valor_bolsa()
		_ganhar(ganho)
		bolsa_paga.emit(ganho)
		return true
	frenesi_restante = FRENESI_DURACAO
	frenesi_mudou.emit(frenesi_restante)
	return true


## Quanto a bolsa da torcida paga agora: max(crew_seconds x renda_sem_mao, crew_floor_clicks x por_clique).
func valor_bolsa() -> float:
	return maxf(dados.golden_crew_seconds * renda_sem_mao(), dados.golden_crew_floor_clicks * por_clique())


## Treino/s sem a mão: equipe + auto-socos do Metrônomo (sem crítico e sem FRENESI).
func renda_sem_mao() -> float:
	return producao_total() + socos_por_segundo_metronomo() * por_auto_soco()


## Extra do Grito da equipe em cada clique da mão: crew_share x equipe/s (0 sem a melhoria). Não vale no auto-soco.
func bonus_crew_click() -> float:
	if not crew_click_comprado or lutas.crew_click.is_empty():
		return 0.0
	return crew_share_efetivo() * producao_total()


## Segundos da equipe por clique com o Grito: loja + nó "Grito mais alto" (Fase 5.4).
func crew_share_efetivo() -> float:
	return float(lutas.crew_click.get("crew_share", 0.0)) + _b("crew_click_bonus")


## "CLIQUE +123 (1 S DA EQUIPE)": o que o Grito da equipe soma agora em cada clique.
func texto_efeito_crew_click() -> String:
	return preencher(texto_ui("shop_crew_click_effect", "CLIQUE +{n} (1 S DA EQUIPE)"),
		{"n": NumberFormat.fmt(crew_share_efetivo() * producao_total())})


func pode_comprar_crew_click() -> bool:
	return not lutas.crew_click.is_empty() and not crew_click_comprado and loja_estado(float(lutas.crew_click.cost)) == "ok"


func comprar_crew_click() -> bool:
	if acoes_bloqueadas() or not pode_comprar_crew_click():
		return false
	_gastar_dinheiro(float(lutas.crew_click.cost))
	crew_click_comprado = true
	crew_click_mudou.emit(true)
	economia_mudou.emit()
	return true


func _tick_evento_dourado(delta: float) -> void:
	if frenesi_restante > 0.0:
		frenesi_restante = maxf(0.0, frenesi_restante - delta)
		if frenesi_restante == 0.0:
			frenesi_mudou.emit(0.0)
	if evento_dourado_restante > 0.0:
		evento_dourado_restante = maxf(0.0, evento_dourado_restante - delta)  # ninguém clicou: o cinturão some
		return
	if modal_aberto or acoes_bloqueadas():
		return  # luta ou janela aberta: o relógio do próximo evento espera
	if _evento_espera < 0.0:
		_evento_espera = _rng_evento.randf_range(EVENTO_ESPERA_MIN, EVENTO_ESPERA_MAX)
	_evento_espera -= delta
	if _evento_espera <= 0.0:
		_evento_espera = -1.0
		evento_dourado_tipo = "crew" if dados.golden_crew_chance >= 1.0 or (dados.golden_crew_chance > 0.0 and _rng_evento.randf() < dados.golden_crew_chance) else "frenzy"
		evento_dourado_restante = EVENTO_DURACAO
		evento_dourado.emit(EVENTO_DURACAO)


## Troca o foco (grátis, instantâneo). Retorna false se o aparelho não existe.
func definir_foco(aparelho_id: String) -> bool:
	if dados.aparelho(aparelho_id).is_empty() or not aparelho_montado(aparelho_id):
		return false
	if aparelho_id != foco:
		foco = aparelho_id
		foco_mudou.emit(foco)
		economia_mudou.emit()
	return true


func comprar_gerador(gerador_id: String) -> bool:
	if acoes_bloqueadas() or not pode_comprar_gerador(gerador_id):
		return false
	_gastar(custo_gerador(gerador_id))
	geradores[gerador_id] = quantidade_gerador(gerador_id) + 1
	gerador_mudou.emit(gerador_id, geradores[gerador_id])
	economia_mudou.emit()
	return true


## Compra o próximo nível de melhoria do aparelho.
func comprar_melhoria(aparelho_id: String) -> bool:
	if acoes_bloqueadas() or not pode_comprar_melhoria(aparelho_id):
		return false
	var m := proxima_melhoria(aparelho_id)
	_gastar(m.cost)
	niveis_melhoria[aparelho_id] = nivel_melhoria(aparelho_id) + 1
	melhoria_comprada.emit(aparelho_id, m.id, niveis_melhoria[aparelho_id])
	economia_mudou.emit()
	return true


func aparelho_montado(aparelho_id: String) -> bool:
	return aparelho_id in aparelhos_montados_ids


## Fase 5: aparelhos que existem nesta carreira, na ordem de `dados`: os de toda carreira e o da arte escolhida (se houver).
## A UI percorre esta lista (botões de foco, cartões da aba TREINO, teclas 1..4).
func aparelhos_da_carreira() -> Array:
	var r: Array = dados.aparelhos.duplicate()
	for ap in dados.aparelhos_arte:
		if arte_id != "" and str(ap.art) == arte_id:
			r.append(ap)
	return r


## true se o aparelho existe nesta carreira (os de arte só existem na carreira da arte dele).
func aparelho_existe(aparelho_id: String) -> bool:
	var ap := dados.aparelho(aparelho_id)
	return not ap.is_empty() and (str(ap.art) == "" or str(ap.art) == arte_id)


## Ids dos aparelhos montados, na ordem da compra.
func aparelhos_montados() -> Array:
	return aparelhos_montados_ids.duplicate()


## Aparelhos sem `unlock` (sempre montados, vêm de graça em toda carreira).
func _aparelhos_iniciais() -> Array:
	var r: Array = []
	for ap in dados.aparelhos:
		if ap.unlock.is_empty():
			r.append(ap.id)
	return r


## {id, cost, requires, name, description, arrives_as} ou {} se o aparelho já vem montado.
func desbloqueio(aparelho_id: String) -> Dictionary:
	return dados.aparelho(aparelho_id).get("unlock", {})


## Nome curto para frases ("ESTEIRA"): o unlock.name, ou o nome do aparelho.
func nome_curto_aparelho(aparelho_id: String) -> String:
	var u := desbloqueio(aparelho_id)
	return str(u.get("name", dados.aparelho(aparelho_id).get("name", aparelho_id)))


## "owned" | "boxed" (comprado, na caixa) | "buyable" | "missing" | "locked" (inexistente = "locked") | "absent" (aparelho de outra arte: não existe aqui).
func estado_aparelho(aparelho_id: String) -> String:
	if dados.aparelho(aparelho_id).is_empty():
		return "locked"
	if not aparelho_existe(aparelho_id):
		return "absent"
	if aparelho_montado(aparelho_id):
		return "owned"
	if tem_caixa(aparelho_id):
		return "boxed"  # Fase 5.1: comprado, esperando abrir (não treina, não recebe foco)
	var u := desbloqueio(aparelho_id)
	var req := str(u.get("requires", ""))
	if req != "" and not aparelho_montado(req):
		return "locked"
	return "buyable" if Economia.pode_pagar(treino, float(u.cost)) else "missing"


func pode_comprar_aparelho(aparelho_id: String) -> bool:
	return not acoes_bloqueadas() and estado_aparelho(aparelho_id) == "buyable"


## Compra o aparelho com Treino: foco vai para ele e salva na hora.
func comprar_aparelho(aparelho_id: String) -> bool:
	if not pode_comprar_aparelho(aparelho_id):
		return false
	_gastar(float(desbloqueio(aparelho_id).cost))
	if dados.box_apparatus:
		# Fase 5.1: chega numa caixa; só monta, foca e treina quando abrir
		_criar_caixa(aparelho_id, "apparatus")
		salvar()
		caixa_criada.emit(aparelho_id, "apparatus")
		economia_mudou.emit()
		return true
	_montar_aparelho(aparelho_id)
	salvar()
	aparelho_comprado.emit(aparelho_id)
	foco_mudou.emit(foco)
	economia_mudou.emit()
	return true


# Monta o aparelho e (se `focus_on_open`) leva o foco para ele. Não salva nem emite sinais.
func _montar_aparelho(aparelho_id: String) -> void:
	if not aparelho_montado(aparelho_id):
		aparelhos_montados_ids.append(aparelho_id)
	if dados.box_focus_on_open:
		foco = aparelho_id


## Textos prontos de um aparelho não montado (vazio se montado). Chaves: price (n TREINO), after (DEPOIS DA X),
## floor_mark (plaquinha), focus_locked (botão de foco), attr_locked (painel de atributos).
func textos_trancado(aparelho_id: String) -> Dictionary:
	var u := desbloqueio(aparelho_id)
	if u.is_empty() or aparelho_montado(aparelho_id) or not aparelho_existe(aparelho_id):
		return {}
	var nome := nome_curto_aparelho(aparelho_id).to_upper()
	var req := str(u.requires)
	var anterior := nome_curto_aparelho(req).to_upper() if req != "" else ""
	var n := NumberFormat.fmt(float(u.cost))
	var trancado := req != "" and not aparelho_montado(req)
	return {
		"price": preencher(texto_ui("unlock_price", "{n} TREINO"), {"n": n}),
		"after": preencher(texto_ui("unlock_after", "DEPOIS DA {nome}"), {"nome": anterior}) if trancado else "",
		"floor_mark": preencher(texto_ui("floor_mark_after", "{nome} — DEPOIS DA {anterior}"), {"nome": nome, "anterior": anterior}) \
			if trancado else preencher(texto_ui("floor_mark_price", "{nome} — {n} TREINO"), {"nome": nome, "n": n}),
		"focus_locked": preencher(texto_ui("focus_locked_after", "DEPOIS DA {nome}"), {"nome": anterior}) \
			if trancado else preencher(texto_ui("focus_locked_price", "{n}"), {"n": n}),
		"attr_locked": preencher(texto_ui("attr_locked", "COMPRE A {nome} PARA TREINAR"), {"nome": nome}),
	}


## Chamado pela UI: true enquanto o Shift (ou o botão SEGURAR) estiver pressionado, false ao soltar
## e quando a janela perde o foco. Nada disso vai para o save.
func definir_assistido(segurando: bool) -> void:
	_segurando = segurando
	if not segurando:
		_acc_assist = _assist_primeiro()
	_atualizar_estado_assist()


## true se o Shift/botão está pressionado (mesmo sem efeito agora).
func assistido_segurando() -> bool:
	return _segurando


## "off" | "waiting" (segurando, mão ainda mexendo) | "active" (socando) | "metronome" (Metrônomo >= 1: assistido some).
func assistido_estado() -> String:
	if nivel_metronomo >= 1:
		return "metronome"
	if not _segurando or not sala_ativa():
		return "off"
	return "active" if _mao_parada() else "waiting"


func assistido_disponivel() -> bool:
	return nivel_metronomo == 0


## Segundos entre auto-socos do assistido (já validado contra o Metrônomo 1).
func assistido_intervalo() -> float:
	return _assist_interval


func _mao_parada() -> bool:
	return _ocioso >= dados.assist_still_seconds - 1.0e-9


func _assist_primeiro() -> float:
	return _assist_interval - minf(dados.assist_first_delay, _assist_interval)


# Intervalo nunca igual ou mais rápido que o Metrônomo 1.
func _ajustar_assist() -> void:
	_assist_interval = dados.assist_interval
	if lutas != null and lutas.metronomo.levels.size() > 0:
		var l1 := float(lutas.metronomo.levels[0].interval)
		if _assist_interval <= l1:
			_assist_interval = l1 + 1.0
			push_warning("GameState: assist.interval <= Metrônomo 1 (%s s): usando %s s." % [str(l1), str(_assist_interval)])
	_acc_assist = _assist_primeiro()


func _atualizar_estado_assist() -> void:
	var novo := assistido_estado()
	if novo != _estado_assist:
		_estado_assist = novo
		assistido_mudou.emit(novo)


func _tick_assistido(delta: float) -> void:
	if assistido_estado() == "active":
		_acc_assist += delta
		var n := 0
		while _acc_assist >= _assist_interval - 1.0e-9 and n < 3:
			_acc_assist -= _assist_interval
			if not auto_socar().is_empty():
				assist_socos_total += 1
			n += 1
		if _acc_assist >= _assist_interval:
			_acc_assist = fmod(_acc_assist, _assist_interval)
	else:
		_acc_assist = _assist_primeiro()
	_atualizar_estado_assist()


## true durante a luta (resultado decidido, ainda não aplicado) e com a tela de fim pendente:
## a garagem não aceita clique nem compra.
## Fase 5: a janela de escolha da arte aberta também bloqueia (sem clique, Metrônomo, assistido, compra ou luta).
func acoes_bloqueadas() -> bool:
	return _bloqueio_base() or no_dia_da_luta()  # Fase 5.3: no dia só LUTAR e PASSAR O POSTO funcionam


func _bloqueio_base() -> bool:
	return not luta.is_empty() or not fim.is_empty() or sucessao != "none" or cena_sala != "" or escolha_arte_pendente()


func tem_luta_pendente() -> bool:
	return not luta.is_empty()


func tem_fim_pendente() -> bool:
	return not fim.is_empty()


func numero_carreira() -> int:
	return int(permanente.get("career_number", 1))


## true quando o jogador venceu todos os adversários da escada (inclusive os da academia).
func escada_completa() -> bool:
	return indice_escada >= lutas.adversarios.size()


## Próximo adversário que dá para enfrentar AGORA ({} se a escada acabou ou se ele só luta em outro local:
## na garagem, depois do cinturão, o Tonhão pede a mudança). Formato: ver FightData (_montar_adversario).
func proximo_adversario() -> Dictionary:
	if escada_completa():
		return {}
	var opp: Dictionary = lutas.adversarios[indice_escada]
	return opp if _local_permite(opp) else {}


# Adversário sem `location` (garagem) luta em qualquer local; os de outro local só nele.
func _local_permite(opp: Dictionary) -> bool:
	return str(opp.location) == academia.local_padrao or str(opp.location) == local_id


## true se o próximo adversário só luta em outro local (a UI mostra o MUDAR / "PRÓXIMA: MUDE PARA A ACADEMIA").
func precisa_mudar() -> bool:
	return not escada_completa() and not _local_permite(lutas.adversarios[indice_escada])


## "fight" (tem adversário), "move" (precisa mudar de local) ou "end" (escada completa).
func estado_escada() -> String:
	if escada_completa():
		return "end"
	return "move" if precisa_mudar() else "fight"


func pode_lutar() -> bool:
	return not proximo_adversario().is_empty() and not _bloqueio_base()


func pode_aposentar() -> bool:
	return not _bloqueio_base()


## Legado em jogo (o "pote"): derivado da fama e do cinturão, não é salvo.
func legado_em_jogo() -> int:
	var c: Dictionary = lutas.carreira
	return int(floor(fama * c.legacy_per_fame + 1.0e-9)) + (int(c.belt_legacy_bonus) if cinturao else 0)


## Legado que a derrota daria agora.
func legado_se_perder() -> int:
	return _com_bonus_legado(int(floor(legado_em_jogo() * parte_derrota() + 1.0e-9)))


## Fase 5.4: Legado ganho = floor(base x (1 + nó "Caderno do velho")). Vale em qualquer fim de campanha.
func _com_bonus_legado(base: int) -> int:
	return int(floor(base * (1.0 + _b("legacy_bonus")) + 1.0e-9))


## Fração do pote que a derrota leva: `defeat_share` + bônus da árvore, sempre abaixo de `retire_share`.
func parte_derrota() -> float:
	var c: Dictionary = lutas.carreira
	var s := float(c.defeat_share) + _b("defeat_share_bonus")
	var teto := float(c.retire_share) - 0.05
	if s > teto:
		s = maxf(float(c.defeat_share), teto)
	return s


## Aposentar agora: {pote, base, bonus, total, cinturao, zero}. `bonus` só com cinturão.
func previa_aposentar() -> Dictionary:
	var c: Dictionary = lutas.carreira
	var pote := legado_em_jogo()
	var base := int(floor(pote * c.retire_share + 1.0e-9))
	var bonus := int(floor(pote * c.retire_belt_bonus_share + 1.0e-9)) if cinturao else 0
	var total := _com_bonus_legado(base + bonus)
	return {"pote": pote, "base": base, "bonus": bonus, "total": total, "cinturao": cinturao,
		"notebook": total - (base + bonus), "zero": base + bonus == 0,
		"honor": honra_da_saida(indice_escada, cinturao), "wins": indice_escada}


func _atributos_array() -> Array:
	return [atributos.get("strength", 0.0), atributos.get("agility", 0.0), atributos.get("endurance", 0.0)]


func _array_adversario(opp: Dictionary) -> Array:
	return [opp.strength, opp.agility, opp.endurance]


func multiplicador_luva() -> float:
	var m := 1.0
	for i in mini(luvas_abertas(), lutas.luvas.size()):
		m *= float(lutas.luvas[i].click_multiplier)
	return m


## Luva equipada: {id, level, name, sprite_suffix, click_multiplier}. Nível 0 = luva velha.
## A UI troca cursor, mão da garagem e mão da luta por `sprite_suffix` (ex.: "" ou "_glove_l1").
func luva_equipada() -> Dictionary:
	var n := luvas_abertas()
	if n <= 0 or n > lutas.luvas.size():
		return lutas.luva_base
	return lutas.luvas[n - 1]


func sufixo_luva() -> String:
	return str(luva_equipada().sprite_suffix)


## Próxima luva da linha, ou {} se completou. Fase 5.1: com a luva anterior ainda na caixa ela NÃO está à venda
## (`pode_comprar_luva` é false e `luva_em_caixa()` é true): a UI mostra `shop_glove_boxed`.
func proxima_luva() -> Dictionary:
	return {} if nivel_luva >= lutas.luvas.size() else lutas.luvas[nivel_luva]


func pode_comprar_luva() -> bool:
	var l := proxima_luva()
	return not l.is_empty() and not luva_em_caixa() and loja_estado(float(l.cost)) == "ok"


func comprar_luva() -> bool:
	if acoes_bloqueadas() or not pode_comprar_luva():
		return false
	var l := proxima_luva()
	_gastar_dinheiro(l.cost)
	nivel_luva += 1  # glove_level conta as luvas COMPRADAS (abertas + a da caixa)
	if dados.box_glove:
		_criar_caixa(str(l.id), "glove")
		salvar()
		caixa_criada.emit(str(l.id), "glove")
	else:
		luva_mudou.emit(nivel_luva, sufixo_luva())
	economia_mudou.emit()
	return true


func custo_gerador_pago(gerador_id: String) -> float:
	var g := lutas.gerador_pago(gerador_id)
	if g.is_empty():
		return INF
	return Economia.custo_gerador(g.base_cost, g.growth, quantidade_gerador(gerador_id))


func pode_comprar_gerador_pago(gerador_id: String) -> bool:
	return not lutas.gerador_pago(gerador_id).is_empty() and loja_estado(custo_gerador_pago(gerador_id)) == "ok"


func comprar_gerador_pago(gerador_id: String) -> bool:
	if acoes_bloqueadas() or not pode_comprar_gerador_pago(gerador_id):
		return false
	_gastar_dinheiro(custo_gerador_pago(gerador_id))
	geradores_pagos[gerador_id] = quantidade_gerador(gerador_id) + 1
	gerador_pago_mudou.emit(gerador_id, geradores_pagos[gerador_id])
	economia_mudou.emit()
	return true


## Texto do efeito de uma luva ("x2 POR CLIQUE") ou de um gerador pago ("+25/S").
func texto_efeito_loja(item: Dictionary) -> String:
	if item.has("click_multiplier"):
		return preencher(texto_ui("shop_glove_effect", "x{mult} POR CLIQUE"),
			{"mult": NumberFormat.fmt(float(item.click_multiplier))})
	return preencher(texto_ui("shop_generator_effect", "+{n}/S"),
		{"n": NumberFormat.fmt(float(item.get("production", 0.0)) * _fator_equipe())})


func metronomo_niveis() -> int:
	return lutas.metronomo.levels.size()


## Definição do nível atual ({} se 0).
func metronomo_atual() -> Dictionary:
	if nivel_metronomo <= 0 or nivel_metronomo > metronomo_niveis():
		return {}
	return lutas.metronomo.levels[nivel_metronomo - 1]


## Próximo nível à venda: {id, level, cost, interval, name, description, appears_as}, ou {} se completo/sem Metrônomo.
func proximo_metronomo() -> Dictionary:
	return {} if nivel_metronomo >= metronomo_niveis() else lutas.metronomo.levels[nivel_metronomo]


## Segundos entre auto-socos no nível atual (0 = sem Metrônomo).
func intervalo_metronomo() -> float:
	return float(metronomo_atual().get("interval", 0.0))


func socos_por_segundo_metronomo() -> float:
	var i := intervalo_metronomo()
	return 1.0 / i if i > 0.0 else 0.0


func pode_comprar_metronomo() -> bool:
	var n := proximo_metronomo()
	return not n.is_empty() and loja_estado(float(n.cost)) == "ok"


func comprar_metronomo() -> bool:
	if acoes_bloqueadas() or not pode_comprar_metronomo():
		return false
	_gastar_dinheiro(proximo_metronomo().cost)
	nivel_metronomo += 1
	_acc_metronomo = 0.0
	metronomo_mudou.emit(nivel_metronomo)
	_atualizar_estado_assist()
	economia_mudou.emit()
	return true


## "1 SOCO A CADA 2.0 S" para um nível (ex.: proximo_metronomo()).
func texto_efeito_metronomo(nivel_def: Dictionary) -> String:
	return preencher(texto_ui("shop_metronome_effect", "1 SOCO A CADA {s} S"),
		{"s": String.num(float(nivel_def.get("interval", 0.0)), 1)})


## true quando o Metrônomo pode socar agora: garagem na tela (sem luta, sem tela de fim, sem janela da UI).
func metronomo_ativo() -> bool:
	return nivel_metronomo > 0 and sala_ativa()


## API da UI (Fase 5.3): chamar com true quando QUALQUER janela abre (prévia, confirmação, vitória, cartão,
## futuras opções) e false quando fecha. Janela aberta = sala parada (relógio, equipe, Metrônomo, clique...).
## Toda janela passa por `Fluxo._abrir`, que já chama isto.
func definir_modal(aberto: bool) -> void:
	modal_aberto = aberto
	_atualizar_estado_assist()
	_checar_sala()


# Acumula tempo só com o alvo livre; no máximo 3 socos por quadro (nunca acumula socos para depois).
func _tick_metronomo(delta: float) -> void:
	if not metronomo_ativo():
		return
	var intervalo := intervalo_metronomo()
	if intervalo <= 0.0:
		return
	_acc_metronomo += delta
	var n := 0
	while _acc_metronomo >= intervalo and n < 3:
		_acc_metronomo -= intervalo
		auto_socar()
		n += 1
	if _acc_metronomo >= intervalo:
		_acc_metronomo = fmod(_acc_metronomo, intervalo)


func definir_tatica(tatica_id: String) -> bool:
	if lutas.tatica(tatica_id).is_empty():
		return false
	if tatica_id != tatica:
		tatica = tatica_id
		tatica_mudou.emit(tatica)
		atualizar_risco_hud()
	return true


## Risco de uma tática contra o próximo adversário: {label: "easy"|"even"|"hard", chance}.
## `chance` é só para testes e depuração: a tela NÃO mostra a porcentagem (Fase 4).
func risco_tatica(tatica_id: String = "") -> Dictionary:
	var opp := proximo_adversario()
	if opp.is_empty():
		return {}
	var t := tatica if tatica_id == "" else tatica_id
	var p := motor.chance(_atributos_array(), _array_adversario(opp), t)
	return {"label": motor.rotulo(p), "chance": p}


## Dados da janela de prévia (calcula as 3 táticas: ~600 lutas). Não muda nada no jogo.
func previa() -> Dictionary:
	var opp := proximo_adversario()
	if opp.is_empty():
		return {}
	var jog := _atributos_array()
	var adv := _array_adversario(opp)
	var riscos := {}
	var com_porcentagem := tem_previa_detalhada()
	for t in lutas.taticas:
		riscos[t.id] = risco_tatica(t.id)
		riscos[t.id]["percent"] = _porcentagem(riscos[t.id].chance)
	var rotulo: String = riscos[tatica].label if riscos.has(tatica) else ""
	return {
		"opponent": opp.duplicate(), "you": {"strength": jog[0], "agility": jog[1], "endurance": jog[2]},
		"tactic": tatica, "risks": riscos, "risk": rotulo,
		"lead": motor.destaque(jog, adv),
		"stake_win": texto_stake_win(opp),
		"stake_belt": opp.belt,
		# Fase 4
		"stake_lose": texto_stake_lose(),
		"show_percent": com_porcentagem,
		"percent": int(riscos[tatica].percent) if riscos.has(tatica) else 0,
		"percent_text": preencher(texto_ui("preview_percent", "{n}%"), {"n": int(riscos[tatica].percent)}) if riscos.has(tatica) else "",
		"revenge": e_algoz(opp.id),
		"wait_green": esperar_verde(opp.id, rotulo),
		# Fase 5: traço de luta da arte ("BOXE: +10% DE DANO"); "" sem arte
		"art": arte_id,
		"art_fight_text": texto_traco_luta(arte_id),
		# Fase 6c2: nó "Caderno de recordes" (fora do verde); "" até ficar pronto (sinal previa_falta_pronta)
		"missing_line": _linha_o_que_falta(opp, jog, adv, rotulo),
	}


## Texto "SE VENCER: $75 (+50%) + 15 FAMA (+50%)" com o bônus da árvore (sem "(+0%)").
func texto_stake_win(opp: Dictionary) -> String:
	var din := NumberFormat.fmt(premio_dinheiro(opp))
	var fam := NumberFormat.fmt(float(premio_fama(opp)))
	var pd := int(round(100.0 * _b("money_bonus")))
	var pf := int(round(100.0 * _b("fame_bonus")))
	if pd > 0:
		din += " " + preencher(texto_ui("stake_bonus", "(+{n}%)"), {"n": pd})
	var texto := preencher(texto_ui("stake_win"), {"n": [din, fam]})
	if pf > 0:  # o bônus da fama vem depois da palavra FAMA
		texto += " " + preencher(texto_ui("stake_bonus", "(+{n}%)"), {"n": pf})
	return texto


## Texto de "perder encerra a carreira": o padrão (50%) ou o percentual real com `career_good_loser`.
func texto_stake_lose() -> String:
	var padrao := float(lutas.carreira.defeat_share)
	if absf(parte_derrota() - padrao) < 1.0e-9:
		return texto_ui("stake_lose")
	return preencher(texto_ui("stake_lose_pct"), {"n": int(round(100.0 * parte_derrota()))})


# Porcentagem mostrada: arredonda para baixo, para nunca mostrar mais do que o rótulo promete.
func _porcentagem(chance: float) -> int:
	return int(floor(chance * 100.0 + 1.0e-9))


## Dinheiro da vitória contra `opp` com o bônus da árvore.
func premio_dinheiro(opp: Dictionary) -> float:
	return float(opp.prize_money) * (1.0 + _b("money_bonus"))


## Fama da vitória contra `opp` com o bônus da árvore (inteiro, arredondado).
func premio_fama(opp: Dictionary) -> int:
	return int(floor(float(opp.prize_fame) * (1.0 + _b("fame_bonus")) + 0.5))


func tem_previa_detalhada() -> bool:
	return _b("preview_percent") > 0.0


## `permanent.revenge_opponent`: id do adversário que encerrou a última carreira ("" = sem marca).
func algoz() -> String:
	return str(permanente.get("revenge_opponent", ""))


func e_algoz(adversario_id: String) -> bool:
	return adversario_id != "" and adversario_id == algoz()


## Alavanca L1 (decisão D2): "ESPERE FICAR VERDE" contra o algoz e contra todo adversário antes dele na escada,
## enquanto o rótulo da tática escolhida não é "easy". Só texto: não bloqueia nada.
func esperar_verde(adversario_id: String, rotulo: String) -> bool:
	var a := algoz()
	if a == "" or adversario_id == "" or rotulo == "easy" or rotulo == "":
		return false
	var i_alvo := lutas.indice_adversario(adversario_id)
	var i_algoz := lutas.indice_adversario(a)
	return i_alvo >= 0 and i_algoz >= 0 and i_alvo <= i_algoz


## Para o bloco "PRÓXIMA" do HUD: marca de revanche e dica do verde do próximo adversário.
func info_proxima() -> Dictionary:
	var opp := proximo_adversario()
	if opp.is_empty():  # `move`: precisa mudar de local; `end`: escada completa
		return {"revenge": false, "wait_green": false, "move": precisa_mudar(), "end": escada_completa()}
	var r: Dictionary = _risco_hud
	var rotulo: String = r.rotulo if r.adversario == opp.id else ""
	return {"revenge": e_algoz(opp.id), "wait_green": esperar_verde(opp.id, rotulo), "move": false, "end": false}


## Último risco calculado para o HUD: {adversario, rotulo ("easy"|"even"|"hard"|""), tatica}.
func risco_proxima() -> Dictionary:
	return _risco_hud.duplicate()


## Recalcula o risco do HUD (200 lutas) e emite `risco_proxima_mudou` se mudou.
func atualizar_risco_hud() -> void:
	var opp := proximo_adversario()
	if opp.is_empty():
		_definir_risco_hud("", "")
		return
	_chave_risco = _chave_estado_risco()
	_definir_risco_hud(opp.id, motor.rotulo_rapido(_atributos_array(), _array_adversario(opp), tatica))


func _definir_risco_hud(adversario: String, rotulo: String) -> void:
	var mudou: bool = _risco_hud.adversario != adversario or _risco_hud.rotulo != rotulo
	_risco_hud = {"adversario": adversario, "rotulo": rotulo, "tatica": tatica}
	if mudou:
		risco_proxima_mudou.emit(adversario, rotulo)


func _chave_estado_risco() -> String:
	return "%d|%s|%s|%s|%s" % [indice_escada, tatica, atributos.get("strength", 0.0), atributos.get("agility", 0.0),
		atributos.get("endurance", 0.0)]


# No máximo 1 vez por `hud_refresh_seconds` e só se algum atributo (ou a tática) mudou.
func _tick_risco(delta: float) -> void:
	if not risco_hud_ativo or not luta.is_empty():
		return
	_tempo_risco += delta
	if _tempo_risco < float(lutas.risco.hud_refresh_seconds):
		return
	_tempo_risco = 0.0
	if _chave_estado_risco() != _chave_risco:
		atualizar_risco_hud()


## LUTAR: simula a luta inteira, grava `career.fight` e salva ANTES da animação. Devolve o mesmo que
## `luta_atual()` ({} se não pode lutar). A UI só anima a lista de eventos.
func lutar() -> Dictionary:
	if not pode_lutar():
		return {}
	_reacao_cena = ""  # lutar antes do 1º clique: a reação da cena se perde, os toques seguem a regra comum
	_interromper_saida()
	var opp := proximo_adversario()
	var jog := _atributos_array()
	var semente := int(rng.randi())
	var res := motor.lutar(jog, _array_adversario(opp), tatica, semente, false)
	luta = {"opponent": opp.id, "tactic": tatica, "seed": semente,
		"player": {"strength": jog[0], "agility": jog[1], "endurance": jog[2]},
		"result": _resultado_salvo(res)}
	_motivo_cache = {}
	salvar()
	# O motivo (busca cara, ~100-200 ms) é calculado em segundo plano em TODA luta (custo igual na
	# vitória e na derrota); na vitória é descartado. Fica salvo antes de concluir_luta().
	_iniciar_motivo_fundo()
	var info := luta_atual()
	luta_iniciada.emit(info)
	return info


# Segundo plano: só lê dados (motor, lutas) e escreve em `_motivo_fundo`; o resultado é recolhido na thread principal.
func _iniciar_motivo_fundo() -> void:
	_finalizar_motivo(false)
	var snap := luta.duplicate(true)
	_motivo_fundo = {}
	_motivo_tarefa = WorkerThreadPool.add_task(func() -> void: _motivo_fundo = _calcular_motivo(snap))
	_motivo_seed = int(snap.seed)


## Recolhe o motivo calculado em segundo plano. Com `esperar`, bloqueia até terminar (só no fim da luta/testes).
## Se a luta atual é derrota, guarda o motivo em luta["reason"] e salva.
func _finalizar_motivo(guardar: bool, esperar: bool = true) -> void:
	if _motivo_tarefa < 0:
		return
	if not esperar and not WorkerThreadPool.is_task_completed(_motivo_tarefa):
		return
	WorkerThreadPool.wait_for_task_completion(_motivo_tarefa)
	_motivo_tarefa = -1
	var pronto := _motivo_fundo
	_motivo_fundo = {}
	if guardar and not luta.is_empty() and not luta.result.win and int(luta.seed) == _motivo_seed \
			and not pronto.is_empty():
		luta["reason"] = pronto
		salvar()


## Espera o cálculo em segundo plano e deixa o motivo salvo (usado pelos testes e pelo fechamento).
func aguardar_motivo() -> void:
	_finalizar_motivo(true)


func _resultado_salvo(res: Dictionary) -> Dictionary:
	return {"win": res.win, "ko": res.ko, "t_ko": res.t_ko, "t_end": res.t_end, "round": res.round,
		"pct_player": res.pct_player, "pct_opponent": res.pct_opponent}


## Luta em andamento recalculada da semente (determinística): eventos, tempos e resultado.
## Formato completo em docs/fases/fase3-api.md. {} se não há luta.
func luta_atual() -> Dictionary:
	if luta.is_empty():
		return {}
	var opp := lutas.adversario(luta.opponent)
	var p: Dictionary = luta.player
	var jog := [p.strength, p.agility, p.endurance]
	var res := motor.lutar(jog, _array_adversario(opp), luta.tactic, int(luta.seed), true)
	var salvo: Dictionary = luta.result
	if bool(salvo.win) != bool(res.win) or bool(salvo.ko) != bool(res.ko):
		push_warning("GameState: a luta salva não bate com a simulação (dados mudaram?); vale o resultado salvo.")
	return _montar_info_luta(opp, res, salvo)


func _montar_info_luta(opp: Dictionary, res: Dictionary, salvo: Dictionary) -> Dictionary:
	var c: Dictionary = lutas.combate
	var tj := lutas.tatica(str(luta.tactic))
	var neutra := Luta.NEUTRA
	var taticas_lado := [tj if not tj.is_empty() else neutra, neutra]
	var eventos: Array = []
	var vmax: Array = res.life_max
	var n: int = res.events.size()
	# Golpes (só visual, nunca muda o resultado): cada lado usa os golpes do seu estilo. Jogador = boxe por enquanto;
	# `liberados` é o gancho para a árvore de habilidades liberar golpes (ids de nós) no futuro.
	var liberados: Array = []
	var golpes_lado: Array = [golpes.disponiveis("boxing", liberados), golpes.disponiveis(str(opp.get("style", "boxing")))]
	var golpe_anterior: Array = ["", ""]
	var semente_golpes := int(luta.seed)
	for i in n:
		var e: Dictionary = res.events[i]
		var alvo: int = 1 - int(e.who)
		var def_t: Dictionary = taticas_lado[alvo]
		var fator_crit: float = 1.0 + (float(c.crit_multiplier) - 1.0) * (1.0 - float(def_t.crit_guard))
		var tipo: String = e.type
		var kind := "jab"
		if tipo == "dodge":
			kind = "dodge"
		elif e.counter:
			kind = "counter"
		elif tipo == "crit" and fator_crit > 1.0 + 1.0e-9:
			kind = "crit"
		var bloqueou: bool = tipo != "dodge" and bool(def_t.block)
		var d_anim := "dodge" if tipo == "dodge" else ("block" if bloqueou else "hit")
		var lado := int(e.who)
		var golpe_id := ""
		var golpe_anim := ""
		var reacao := ""
		if kind != "dodge":
			golpe_id = golpes.escolher(golpes_lado[lado], kind, semente_golpes, i, str(golpe_anterior[lado]))
			if golpe_id != "":
				golpe_anterior[lado] = golpe_id
				golpe_anim = str(golpes.golpes[golpe_id].anim)
				if d_anim == "hit":
					reacao = str(golpes.golpes[golpe_id].defender_anim)
		eventos.append({
			"t": e.t, "who": e.who, "target": alvo, "type": tipo, "counter": e.counter,
			"kind": kind, "attack_anim": "heavy" if kind == "crit" or kind == "counter" else "jab",
			"move": golpe_id, "move_anim": golpe_anim, "defender_move_anim": reacao,
			"defender_anim": d_anim, "blocked": bloqueou,
			"damage": e.damage, "life_after": e.life_after, "life_pct_after": e.life_after / vmax[alvo],
			"round": int(floor(float(e.t) / float(c.round_length))) + 1,
			"ko": bool(salvo.ko) and i == n - 1,
		})
	var perdedor := -1
	if salvo.ko:
		perdedor = 1 if salvo.win else 0
	var t_ko := float(salvo.t_ko)
	var grogue := {}
	if salvo.ko and t_ko < float(c.min_ko_time):
		grogue = {"who": perdedor, "from": t_ko, "to": float(c.min_ko_time)}
	return {
		"opponent": opp.id, "tactic": luta.tactic, "seed": int(luta.seed), "player": luta.player.duplicate(),
		"events": eventos, "result": salvo.duplicate(), "grogue": grogue, "loser": perdedor,
		"life_max": {"player": vmax[0], "opponent": vmax[1]},
		"intro_seconds": c.intro_seconds, "outro_seconds": c.outro_seconds,
		"screen_seconds": float(c.intro_seconds) + float(salvo.t_end) + float(c.outro_seconds),
		"counts": res.counts,
	}


## Fim da animação (ou luta pendente ao reabrir): aplica o resultado UMA vez e salva.
## Vitória: prêmio. Derrota: Legado + tela de fim. Devolve o resumo ({} se não havia luta).
func concluir_luta() -> Dictionary:
	if luta.is_empty():
		return {}
	_finalizar_motivo(true)  # garante o motivo pronto e salvo antes de aplicar o resultado
	var snap := luta.duplicate(true)
	var opp := lutas.adversario(snap.opponent)
	var resumo := {}
	if snap.result.win:
		var pote_antes := legado_em_jogo()
		luta = {}
		var premio := premio_dinheiro(opp)
		var premio_f := premio_fama(opp)
		dinheiro = clampf(dinheiro + premio, 0.0, VALOR_MAXIMO)
		dinheiro_ganho += premio
		fama += premio_f
		indice_escada += 1
		if opp.belt:
			cinturao = true
		# Fase 6a: marcos da escola, gravados no mesmo save do prêmio. A garagem só é salva por vitória AO VIVO
		# sobre o adversário do cinturão (qualquer lutador da escola); nunca por belts_won.
		var recorde := int(permanente.best_wins) > 0 and indice_escada > int(permanente.best_wins)
		var primeira_vitoria := _gravar_marco("first_school_win", {}, false)
		var garagem_salva := false
		if opp.belt:
			garagem_salva = _gravar_marco("garage_saved", {"opponent": str(opp.id), "by_first": lutador_atual() == "first"}, false)
		# 6c1: a 1ª vitória de um discípulo na academia, com o John ainda na escola, arma a saída dele (mesmo save do prêmio).
		_marcar_vitoria_na_academia(str(opp.id))
		# Revanche: vencer o algoz limpa a marca (no mesmo save do prêmio).
		var revanche := e_algoz(opp.id)
		if revanche:
			permanente["revenge_opponent"] = ""
		# Fase 5.3: a próxima data conta do dia em que esta luta aconteceu (-1 depois do Kid).
		fight_day = _data_da_proxima_luta()
		if escada_completa():
			campanha_completa_mudou.emit()
		var proximo := proximo_adversario()
		var fala_mentor := _fala_do_mentor(opp)  # 6c2: só pede; quem fala é o gatilho mentor_won
		resumo = {"win": true, "mentor_line": fala_mentor, "fight_day": fight_day, "opponent": opp.id, "money": premio, "fame": premio_f,
			"legacy_gain": legado_em_jogo() - pote_antes, "legacy_run": legado_em_jogo(), "belt": opp.belt,
			"next": proximo.get("id", ""), "next_name": proximo.get("name", ""), "revenge": revanche,
			"record": recorde, "first_school_win": primeira_vitoria, "garage_saved": garagem_salva,
			"revenge_line": preencher(texto_ui("victory_revenge_line"), {"nome": opp.name}) if revanche else ""}
		dinheiro_mudou.emit(dinheiro)
		fama_mudou.emit(fama)
		escada_mudou.emit()
		economia_mudou.emit()
		salvar()
		if revanche:
			permanente_mudou.emit()
		atualizar_risco_hud()
	else:
		var motivo := motivo_da_luta(snap)
		luta = {}
		_encerrar_carreira("defeat", snap, motivo)
		resumo = {"win": false, "fim": fim.duplicate(true)}
	_motivo_cache = {}
	luta_resolvida.emit(resumo)
	return resumo


## Motivo da derrota (design §7): {attribute, faltaram, who, round, model, tip, stat, better_tactic}.
## Calcula até ~9.000 lutas simuladas: chame durante a animação. Resultado fica em cache.
func motivo_da_luta(snap: Dictionary = {}) -> Dictionary:
	if snap.is_empty():
		snap = luta
		_finalizar_motivo(true)  # já pronto em segundo plano (a animação dura segundos)
		snap = luta
	if snap.is_empty():
		return {}
	var pronto = snap.get("reason", null)
	if pronto is Dictionary and not pronto.is_empty():
		return pronto  # calculado em lutar()
	if not _motivo_cache.is_empty() and _motivo_cache.get("seed") == int(snap.seed):
		return _motivo_cache
	_motivo_cache = _calcular_motivo(snap)
	return _motivo_cache


func _calcular_motivo(snap: Dictionary) -> Dictionary:
	var opp := lutas.adversario(snap.opponent)
	var p: Dictionary = snap.player
	var jog := [p.strength, p.agility, p.endurance]
	var adv := _array_adversario(opp)
	var tat := str(snap.tactic)
	var seed_i := int(snap.seed)
	var chances := motor.chances_por_tatica(jog, adv)
	var usada: float = chances.get(tat, 0.0)
	var m := motor.explicar(jog, adv, tat, seed_i, usada)
	var res: Dictionary = m.res
	var faltaram := -1.0
	if m.faltaram >= 0.0:
		faltaram = Economia.teto3(m.faltaram)
	var melhor := ""
	var minimo := usada + float(lutas.motivo.tactic_tip_gap) - 1.0e-12
	for t in lutas.taticas:
		if t.id != tat and chances[t.id] >= minimo and (melhor == "" or chances[t.id] > chances[melhor]):
			melhor = t.id
	if m.kind == "luck":
		melhor = ""  # azar nunca culpa a tática
	return {
		"seed": seed_i, "kind": m.kind, "attribute": m.attribute, "faltaram": faltaram, "far_n": m.far_n,
		"who": "ko" if res.ko else "points", "round": res.round,
		"model": (seed_i / 3) % 2, "tip": seed_i % 3,
		"stat": m.stat,
		"better_tactic": melhor,
	}


## APOSENTAR (só entre lutas): soma o Legado e cria a tela de fim "saiu por cima". Devolve o `fim`.
func aposentar() -> Dictionary:
	if not pode_aposentar():
		return {}
	_encerrar_carreira("retire", {}, {})
	luta_resolvida.emit({"win": true, "retire": true, "fim": fim.duplicate(true)})
	return fim.duplicate(true)


# Soma o Legado e os recordes, cria `fim` e salva, tudo num único save.
func _encerrar_carreira(tipo: String, snap: Dictionary, motivo: Dictionary) -> void:
	var ganho := legado_se_perder() if tipo == "defeat" else int(previa_aposentar().total)
	var caderno := ganho - (int(floor(legado_em_jogo() * parte_derrota() + 1.0e-9)) if tipo == "defeat" else int(previa_aposentar().total) - int(previa_aposentar().notebook))
	permanente["legacy_total"] = int(permanente.legacy_total) + ganho
	# Revanche: a derrota marca quem venceu; a aposentadoria limpa a marca (mesmo save do Legado).
	permanente["revenge_opponent"] = str(snap.get("opponent", "")) if tipo == "defeat" else ""
	permanente["careers_finished"] = int(permanente.careers_finished) + 1
	permanente["best_wins"] = maxi(int(permanente.best_wins), indice_escada)
	if cinturao:
		permanente["belts_won"] = int(permanente.belts_won) + 1
	var motivo_fim := motivo.duplicate()
	# 6c2: Honra só por saída voluntária com vitórias; nunca multiplicada; no mesmo salvar() do Legado.
	var honra_ganha := honra_da_saida(indice_escada, cinturao) if tipo == "retire" else 0
	escola["honor"] = honra() + honra_ganha
	escola["honor_total"] = honra_total() + honra_ganha
	_interromper_saida()  # 6c1: o fim da campanha termina a saída do John na hora
	escola["last_end"] = {"kind": tipo, "campaign": numero_carreira()}  # Fase 6a: o comentário da derrota usa isto
	if tipo == "defeat":
		motivo_fim["unlock_tip"] = _aparelho_da_dica(motivo)
	fim = {
		"kind": tipo, "career_number": numero_carreira(), "legacy_gained": ganho, "legacy_notebook": caderno,
		"legacy_total": int(permanente.legacy_total), "honor_gained": honra_ganha,
		"opponent": str(snap.get("opponent", "")), "tactic": str(snap.get("tactic", tatica)),
		"seed": int(snap.get("seed", 0)), "player": snap.get("player", {}).duplicate(),
		"result": snap.get("result", {}).duplicate(), "reason": motivo_fim,
		"summary": {"wins": indice_escada, "belts": 1 if cinturao else 0, "fame": fama,
			"money_earned": dinheiro_ganho, "play_seconds": tempo_jogo, "art": arte_id, "location": local_id},
	}
	_registrar_na_lista_da_escola(tipo, snap, ganho, honra_ganha)
	salvar()
	if honra_ganha > 0:
		honra_mudou.emit(honra())
	permanente_mudou.emit()
	fim_de_carreira.emit(fim.duplicate(true))


## NOVA CARREIRA (só com a tela de fim pendente): zera `career`, mantém `permanent`, soma 1 em
## "Carreira N". Volta direto para a garagem.
func nova_carreira() -> bool:
	if fim.is_empty():
		return false
	_reiniciar_campanha()
	# Caminho direto (sem a tela de criação): o discípulo, se houver, é o padrão. A interface usa receber_discipulo().
	if lutador_atual() == "disciple" and discipulo.is_empty():
		discipulo = _discipulo_padrao()
	salvar()
	_tempo_autosave = 0.0
	_emitir_tudo(false)
	permanente_mudou.emit()
	_emitir_inicio_da_campanha()
	return true


# Zera a carreira e soma 1 em "Carreira N" (sem salvar nem emitir). Fase 6b1: usado por nova_carreira() e receber_discipulo().
func _reiniciar_campanha() -> void:
	# Fase 5.4: a foto dos nós (o que vale nesta campanha) é tirada aqui, ANTES de zerar (a data usa "+1 dia").
	nos_ativos_ids = permanente.get("skill_nodes", []).duplicate()
	arte_id = ""
	_recalcular_bonus()
	_zerar_carreira()
	permanente["career_number"] = int(permanente.career_number) + 1
	fim = {}
	discipulo = {}
	mentor_cumprimentou = false
	_aplicar_inicio_da_arvore()
	_aplicar_inicio_do_hall()
	nivel_metronomo = mini(int(_b("metronome_start")), metronomo_niveis())


# O começo da campanha, na ordem da 6a: cartão, escolha da arte (a UI trata "arte antes do cartão") e a fala da derrota.
func _emitir_inicio_da_campanha() -> void:
	nova_carreira_iniciada.emit(cartao_inicio())
	# Com as artes liberadas, a escolha vem ANTES do cartão (a UI abre a janela e depois mostra `cartao_inicio()`).
	if escolha_arte_pendente():
		escolha_arte_pedida.emit(escolha_arte_primeira())
	# Fase 6a: depois de uma derrota o treinador comenta no 1º momento calmo da campanha nova.
	var fim_anterior = escola.get("last_end", null)
	if fim_anterior is Dictionary and str(fim_anterior.get("kind", "")) == "defeat" \
			and int(fim_anterior.get("campaign", 0)) == numero_carreira() - 1:
		disparar_gatilho("after_defeat")
		_derrota_rearmada = true


func _zerar_carreira() -> void:
	gestos_calcados = []
	frenesi_restante = 0.0
	evento_dourado_restante = 0.0
	_evento_espera = -1.0
	treino = 0.0
	atributos = {}
	for id in dados.atributos:
		atributos[id] = 0.0
	aparelhos_montados_ids = _aparelhos_iniciais()
	caixas_lista = []  # Fase 5.1: caixa fechada some com a carreira, sem reembolso
	foco = dados.default_focus
	geradores = {}
	for g in dados.geradores:
		geradores[g.id] = 0
	niveis_melhoria = {}
	for ap in dados.todos_aparelhos():
		niveis_melhoria[ap.id] = 0
	geradores_pagos = {}
	for g in lutas.geradores_pagos:
		geradores_pagos[g.id] = 0
	# Fase 5: toda carreira começa na garagem e sem arte (a janela de arte vem logo depois, se já liberou)
	local_id = academia.local_padrao
	arte_id = ""
	arte_segundos = 0.0
	_atualizar_traco()
	segundos_campanha = 0.0
	_arte_comentada = true  # sem arte ainda: o comentário volta a valer quando ela for escolhida
	nivel_luva = 0
	crew_click_comprado = false
	dinheiro = 0.0
	fama = 0
	indice_escada = 0
	fight_day = _data_da_proxima_luta()  # Dia 1 + folga do primeiro adversário
	cinturao = false
	tatica = lutas.tatica_padrao
	tempo_jogo = 0.0
	dinheiro_ganho = 0.0
	luta = {}
	nivel_metronomo = 0
	_acc_metronomo = 0.0
	_acc_assist = _assist_primeiro()
	_morto_atual = 0.0
	_morto_max = 0.0
	_morto_total = 0.0
	_chave_melhor = ""
	_finalizar_motivo(false)
	_motivo_cache = {}


# Soma, por tipo, dos efeitos dos nós ATIVOS da campanha (aditivo dentro do tipo; ver design §3.5).
# Fase 5.4: lê `nos_ativos_ids` (a foto), nunca `skill_nodes`; nó com `requires_art` só vale jogando aquela arte.
func _recalcular_bonus() -> void:
	var ids: Array = nos_ativos_ids
	_bonus = bonus_de(ids, arte_id)
	# Fase 5: nós ESTILO valem só para a arte deles (`requires_art`).
	_estilo = {}
	for id in ids:
		var n: Dictionary = lutas.no_da_arvore(str(id))
		if not n.is_empty() and n.effect_type == "art_rule_bonus" and n.requires_art != "":
			_estilo[n.requires_art] = float(_estilo.get(n.requires_art, 0.0)) + float(n.effect_value)


## Bônus (por tipo de efeito) de uma lista de ids de nós. Tipos: somas (click, passive, money, fame, defeat_share,
## crew_click, gym_training, art_fight, legacy, prep_days, art_rule) e maior valor (metronome_start, preview_percent,
## rope_installed). `arte` "*" = sem filtro de arte; senão só entram nós sem `requires_art` ou da arte dada.
func bonus_de(ids: Array, arte: String = "*") -> Dictionary:
	var b := {}
	for t in FightData.TIPOS_EFEITO:
		b[t] = 0.0
	for id in ids:
		var n: Dictionary = lutas.no_da_arvore(str(id))
		if n.is_empty():
			continue
		if arte != "*" and n.requires_art != "" and n.requires_art != arte:
			continue
		var t: String = n.effect_type
		if t == "start_generator":
			continue  # lido por _aplicar_inicio_da_arvore
		if t == "metronome_start" or t == "preview_percent" or t == "rope_installed":
			b[t] = maxf(float(b[t]), float(n.effect_value))
		else:
			b[t] = float(b[t]) + float(n.effect_value)
	return b


## Efeitos que agem no começo da campanha (depois de zerar): corda montada e geradores de saída.
func _aplicar_inicio_da_arvore() -> void:
	if _b("rope_installed") > 0.0 and not dados.aparelho("jump_rope").is_empty() and not aparelho_montado("jump_rope"):
		aparelhos_montados_ids.append("jump_rope")  # sem caixa e sem foco novo
	for id in nos_ativos_ids:
		var n: Dictionary = lutas.no_da_arvore(str(id))
		if n.is_empty() or n.effect_type != "start_generator" or not geradores.has(n.effect_target):
			continue
		geradores[n.effect_target] = maxi(int(geradores[n.effect_target]), int(n.effect_value))


func _b(tipo: String) -> float:
	return float(_bonus.get(tipo, 0.0))


## Bônus ativos da carreira em andamento (cópia, para a UI e os testes).
func bonus_ativos() -> Dictionary:
	return _bonus.duplicate()


func nos_comprados() -> Array:
	return permanente.get("skill_nodes", []).duplicate()


func tem_no(id: String) -> bool:
	return id in permanente.get("skill_nodes", [])


func legado_disponivel() -> int:
	return int(permanente.get("legacy_total", 0))


## Estado de um nó para a tela ANTIGA (abas): "owned", "buyable", "missing" (falta Legado) ou "locked" (escondido no mapa).
## Id inexistente: "". O mapa novo usa `estado_mapa`.
func estado_no(id: String) -> String:
	var e := estado_mapa(id)
	if e == "" or e == "owned":
		return e
	if e == "hidden":
		return "locked"
	return "buyable" if legado_disponivel() >= int(lutas.no_da_arvore(id).cost) else "missing"


## Fase 5.4: estado de um nó no mapa: "owned" (comprado), "visible" (à vista: raiz ou vizinho de comprado, trava aberta)
## ou "hidden". Calculado de skill_nodes + travas (não vai para o save). Id inexistente: "".
func estado_mapa(id: String) -> String:
	var n: Dictionary = lutas.no_da_arvore(id)
	if n.is_empty():
		return ""
	if tem_no(id):
		return "owned"
	if not trava_aberta(str(n.lock)):
		return "hidden"
	if n.root:
		return "visible"
	for v in n.neighbors:
		if tem_no(str(v)):
			return "visible"
	return "hidden"


## Trava de região/nó: "" sempre; "gym" com alguma arte liberada (um discípulo já chegou à academia); "art:<id>" com a arte liberada.
func trava_aberta(trava: String) -> bool:
	if trava == "":
		return true
	if trava == "gym":
		return not permanente.get("arts_unlocked", []).is_empty()
	if trava.begins_with("art:"):
		return trava.substr(4) in permanente.get("arts_unlocked", [])
	return false


## Lista de nós na ordem do arquivo. Cada item: {id, branch, branch_name, requires, requires_name, cost, name,
## description, effect_text (já com número), icon, effect_type, effect_value, state, missing (Legado que falta, 0 se nenhum)}.
## Fase 5: ramos que a aba mostra ([{id, name}]). O ramo ESTILO só aparece com alguma arte liberada.
func arvore_ramos() -> Array:
	var r: Array = []
	for b in lutas.ramos:
		if not b.requires_arts_unlocked or not artes_liberadas().is_empty():
			r.append({"id": b.id, "name": b.name})
	return r


func arvore_nos() -> Array:
	var lista: Array = []
	var visiveis: Array = arvore_ramos().map(func(b): return b.id)
	for n in lutas.arvore:
		if not (n.branch in visiveis):
			continue
		var item: Dictionary = n.duplicate()
		# Fase 5: nó de arte diz "SÓ VALE JOGANDO DE BOXE"
		item["art_only_text"] = preencher(texto_ui("tree_style_art_only", "SÓ VALE JOGANDO DE {nome}"),
			{"nome": str(academia.arte(n.requires_art).get("name", "")).to_upper()}) if n.requires_art != "" else ""
		item["branch_name"] = str(lutas.ramo(n.branch).get("name", n.branch))
		item["requires_name"] = str(lutas.no_da_arvore(n.requires).get("name", "")) if n.requires != "" else ""
		item["effect_text"] = texto_efeito_no(n)
		item["state"] = estado_no(n.id)
		item["missing"] = maxi(0, int(n.cost) - legado_disponivel()) if item.state == "missing" else 0
		lista.append(item)
	return lista


## Texto do efeito com {pct} = round(100 x valor) e {n} = valor.
func texto_efeito_no(n: Dictionary) -> String:
	var v := float(n.get("effect_value", 0.0))
	var vn := str(int(v)) if v == floorf(v) else String.num(v)
	return preencher(str(n.get("effect_text", "")), {"pct": int(round(100.0 * v)), "n": vn})


## Fase 5.4: a árvore abre em qualquer momento, menos na luta, no dia da luta, na escolha da arte e com caixa
## no meio da abertura (já tem batida). Com a tela de fim pendente abre sempre.
func pode_abrir_arvore() -> bool:
	if not luta.is_empty():
		return false
	if not fim.is_empty():
		return true
	if no_dia_da_luta() or escolha_arte_pendente():
		return false
	for b in caixas_lista:
		if int(b.hits) > 0:
			return false
	return true


## Compat: "a árvore está aberta" (mesma regra de `pode_abrir_arvore`).
func arvore_aberta() -> bool:
	return pode_abrir_arvore()


## À vista, com Legado para pagar e mapa aberto.
func pode_comprar_no(id: String) -> bool:
	return pode_abrir_arvore() and pode_pagar_no(id)


## Igual a `pode_comprar_no`, sem olhar se o mapa está aberto (o brilho do botão usa isto).
func pode_pagar_no(id: String) -> bool:
	return estado_mapa(id) == "visible" and legado_disponivel() >= int(lutas.no_da_arvore(id).cost)


## true se existe nó à vista que o Legado paga: o botão da sala brilha (mesmo com o mapa fechado).
func ha_no_compravel() -> bool:
	for n in lutas.arvore:
		if pode_pagar_no(n.id):
			return true
	return false


## Quantos nós à vista o Legado paga agora ("{n} NÓS PARA COMPRAR").
func nos_compraveis() -> int:
	var c := 0
	for n in lutas.arvore:
		if pode_pagar_no(n.id):
			c += 1
	return c


func _ids_a_vista() -> Array:
	var r: Array = []
	for n in lutas.arvore:
		if estado_mapa(n.id) != "hidden":
			r.append(n.id)
	return r


## Compra o nó: desconta o Legado exato, grava o nó e salva (um save só). Recusa (nada muda) com o mapa fechado,
## nó já comprado, escondido ou Legado insuficiente. Os bônus valem a partir da PRÓXIMA campanha (`nos_ativos_ids`).
func comprar_no(id: String) -> bool:
	if not pode_comprar_no(id):
		return false
	var n: Dictionary = lutas.no_da_arvore(id)
	var antes := _ids_a_vista()
	permanente["legacy_total"] = maxi(0, int(permanente.legacy_total) - int(n.cost))
	var nos: Array = permanente.get("skill_nodes", [])
	nos.append(id)
	permanente["skill_nodes"] = nos
	permanente["tree_last_node"] = id
	# O `fim` pendente mostra o Legado total: mantém igual ao disponível.
	if not fim.is_empty():
		fim["legacy_total"] = int(permanente.legacy_total)
	var novos: Array = []
	for x in _ids_a_vista():
		if not (x in antes):
			novos.append(x)
	salvar()
	arvore_mudou.emit()
	permanente_mudou.emit()
	if not novos.is_empty():
		no_revelado.emit(novos)
	return true


## Nós que valem na campanha atual (a foto de `career.active_nodes`).
func nos_ativos() -> Array:
	return nos_ativos_ids.duplicate()


## Mapa inteiro para a UI (o `docs/fases/fase5.4-api.md` descreve cada chave). A UI desenha só o que não é "hidden".
func arvore_mapa() -> Array:
	var lista: Array = []
	for n in lutas.arvore:
		if n.region == "" or lutas.regiao(n.region).is_empty():
			continue  # nó antigo sem região (arquivo v1)
		var estado := estado_mapa(n.id)
		var item: Dictionary = n.duplicate(true)
		item["state"] = estado
		item["region_name"] = str(lutas.regiao(n.region).get("name", ""))
		item["effect_text"] = texto_efeito_no(n)
		item["can_buy"] = pode_comprar_no(n.id)
		item["affordable"] = pode_pagar_no(n.id)
		item["missing"] = maxi(0, int(n.cost) - legado_disponivel()) if estado == "visible" else 0
		item["active"] = n.id in nos_ativos_ids
		item["next_campaign"] = estado == "owned" and not (n.id in nos_ativos_ids)  # etiqueta VALE NA PRÓXIMA CAMPANHA
		item["needs_shout"] = n.effect_type == "crew_click_bonus" and not crew_click_comprado
		item["art_only_text"] = preencher(texto_ui("tree_style_art_only", "SÓ VALE JOGANDO DE {nome}"),
			{"nome": str(academia.arte(n.requires_art).get("name", "")).to_upper()}) if n.requires_art != "" else ""
		lista.append(item)
	return lista


## Dados gerais do mapa: {unit_px, regions: [{id, name, icon, lock, open}], last_node, legacy, open, can_buy_count}.
func arvore_mapa_info() -> Dictionary:
	var regs: Array = []
	for r in lutas.regioes:
		regs.append({"id": r.id, "name": r.name, "icon": r.icon, "lock": r.lock, "open": trava_aberta(str(r.lock))})
	var ultimo := str(permanente.get("tree_last_node", ""))
	return {"unit_px": float(lutas.mapa_arvore.get("unit_px", 40.0)), "regions": regs, "last_node": ultimo,
		"legacy": legado_disponivel(), "open": pode_abrir_arvore(), "can_buy_count": nos_compraveis()}


## Lista dos nós ativos (ordem da compra): [{id, name, effect_text, icon}]. Cartão de início e resumo da garagem.
func resumo_legado() -> Dictionary:
	var itens: Array = []
	for id in nos_ativos_ids:
		var n: Dictionary = lutas.no_da_arvore(str(id))
		if not n.is_empty():
			itens.append({"id": n.id, "name": n.name, "effect_text": texto_efeito_no(n), "icon": n.icon})
	return {"count": itens.size(), "nodes": itens,
		"label": preencher(texto_ui("legacy_nodes_label", "LEGADO: {n} NÓS"), {"n": itens.size()})}


## Cartão "o que você trouxe" ({} sem nós): {title, career, nodes}. A UI mostra por até 1,8 s.
func cartao_inicio() -> Dictionary:
	var r := resumo_legado()
	if r.count == 0 and arte_id == "":
		return {}
	# Fase 5: `art` / `art_text` ("ARTE: BOXE") só depois da escolha (a UI chama de novo ao fechar a janela de arte)
	return {"title": preencher(texto_ui("career_card_title_named", "{nome}: O QUE VOCÊ TROUXE"), {"nome": nome_lutador().to_upper()}),
		"career": numero_carreira(), "name": nome_lutador(), "nodes": r.nodes, "art": arte_id,
		"art_text": preencher(texto_ui("career_card_art", "ARTE: {nome}"), {"nome": nome_arte(arte_id).to_upper()}) if arte_id != "" else ""}


## Multiplicador global de treino do local atual (garagem 1,0; academia 2,0), lido de data/locations.json.
func mult_local() -> float:
	var m := float(academia.local(local_id).get("training_mult", 1.0))
	if m != 1.0:
		m *= 1.0 + _b("gym_training_bonus")  # Fase 5.4: Ventilador novo (só fora da garagem)
	return m


## Local atual: {id, name, ambience, training_mult, apparatus_suffix, ...}. O sufixo vai nos sprites dos aparelhos básicos.
func local_atual() -> Dictionary:
	return academia.local(local_id)


func sufixo_aparelhos() -> String:
	return str(local_atual().get("apparatus_suffix", ""))


## true se o treino está multiplicado por causa do local (a UI mostra `texto_hud_local()`).
func em_academia() -> bool:
	return mult_local() != 1.0


## "ACADEMIA: TREINO x2" fora da garagem, "" na garagem.
func texto_hud_local() -> String:
	if not em_academia():
		return ""
	return preencher(texto_ui("hud_location_mult", "ACADEMIA: TREINO x{mult}"), {"mult": NumberFormat.fmt(mult_local())})


## Dados do botão MUDAR ({} se não há para onde mudar: já está lá). Chaves: id, location, cost, name, mult, button,
## description, title, price_text, effect_text, keeps_text, per_career_text, state ("locked" sem cinturão,
## "missing" sem dinheiro, "ready").
func mudanca() -> Dictionary:
	var d := academia.destino_mudanca()
	if d.is_empty() or d.id == local_id:
		return {}
	var custo := float(d.move.cost)
	return {
		"id": d.move.id, "location": d.id, "cost": custo, "name": d.name, "mult": d.training_mult,
		"button": d.move_button if d.move_button != "" else texto_ui("move_button", "MUDAR"),
		"description": d.move_description,
		"title": texto_ui("move_title"), "price_text": preencher(texto_ui("move_price", "${n}"), {"n": NumberFormat.fmt(custo)}),
		"effect_text": preencher(texto_ui("move_effect"), {"mult": NumberFormat.fmt(float(d.training_mult))}),
		"keeps_text": texto_ui("move_keeps"), "per_career_text": texto_ui("move_per_career"),
		"state": estado_mudanca(),
	}


## "none" (nada a comprar), "locked" (falta o cinturão: o botão não existe), "missing" (cinturão sem o dinheiro: apagado) ou "ready".
func estado_mudanca() -> String:
	var d := academia.destino_mudanca()
	if d.is_empty() or d.id == local_id:
		return "none"
	if not cinturao:
		return "locked"
	return "ready" if Economia.pode_pagar(dinheiro, float(d.move.cost)) else "missing"


func pode_mudar() -> bool:
	return estado_mudanca() == "ready" and not acoes_bloqueadas()


## MUDAR: desconta o preço uma vez, vai para o local, e na 1ª vez libera todas as artes e pede a escolha. Salva na hora.
## Mudar nunca tira nada (geradores, melhorias, aparelhos, luva, Metrônomo, Treino, atributos ficam).
func mudar() -> bool:
	if not pode_mudar():
		return false
	var d := academia.destino_mudanca()
	_gastar_dinheiro(float(d.move.cost))
	_interromper_saida()  # 6c1: trocar de local no meio da saída do John a termina na hora
	var estava_parado := estado_escada() == "move"
	local_id = str(d.id)
	_reacao_cena = ""
	if estava_parado and calendario_ligado():
		fight_day = _data_da_proxima_luta()  # B3: chegou ao novo local, folga cheia a partir de hoje
	var primeira: bool = permanente.arts_unlocked.is_empty() and not academia.artes.is_empty()
	if primeira:
		permanente["arts_unlocked"] = academia.ids_artes()
	# 6c1: a 1ª chegada à academia toca a cena. O marco entra no MESMO salvar() da mudança (fechar o jogo no meio não repete).
	var cena_id := _cena_da_chegada()
	if cena_id != "":
		_gravar_marco(str(escola_cfg.gym_arrival.milestone), {}, false)
		cena_sala = cena_id
		_cena_sala_t = 0.0
		_cancelar_toques(true)
		_checar_sala()
	_chave_melhor = ""
	salvar()
	local_mudou.emit(local_id)
	if primeira:
		permanente_mudou.emit()
	escada_mudou.emit()
	economia_mudou.emit()
	atualizar_risco_hud()
	if escolha_arte_pendente():
		escolha_arte_pedida.emit(escolha_arte_primeira())
	if local_id == "gym":
		_academia_rearmada = true
		disparar_gatilho("gym_arrival")  # Fase 6a: só a chegada pelo MUDAR (a carga e o NOVA CAMPANHA não passam aqui)
	if cena_id != "":
		cena_sala_pedida.emit(cena_id)  # a escolha da arte espera o fim da cena (cena_sala_terminou)
	return true


## Dinheiro que a LOJA não pode gastar: o preço da mudança, entre o cinturão e a mudança (0 nos outros casos).
func reserva_mudanca() -> float:
	if not cinturao:
		return 0.0
	var d := academia.destino_mudanca()
	if d.is_empty() or d.id == local_id:
		return 0.0
	return float(d.move.cost)


## Estado de uma compra em dinheiro: "ok", "money" (falta dinheiro) ou "reserve" (deixaria menos que a reserva da mudança).
func loja_estado(custo: float) -> String:
	if not Economia.pode_pagar(dinheiro, custo):
		return "money"
	if dinheiro - custo < reserva_mudanca() * (1.0 - Economia.EPS):
		return "reserve"
	return "ok"


## "GUARDE $1.00K PARA A MUDANÇA" (ou a versão curta "GUARDE $1.00K"). A UI mostra no item recusado por "reserve".
func texto_reserva(curto: bool = false) -> String:
	var chave := "move_reserve_short" if curto else "move_reserve"
	return preencher(texto_ui(chave, "GUARDE ${n} PARA A MUDANÇA"), {"n": NumberFormat.fmt(reserva_mudanca())})


## Artes liberadas para sempre (ids), na ordem do arquivo.
func artes_liberadas() -> Array:
	return permanente.get("arts_unlocked", []).duplicate()


func nome_arte(id: String) -> String:
	return str(academia.arte(id).get("name", ""))


## true quando a janela de escolha da arte deve estar aberta: artes liberadas, carreira viva e sem arte escolhida.
## Cobre a 1ª chegada, o início de toda carreira e reabrir o jogo sem ter escolhido. Enquanto vale, `acoes_bloqueadas()`.
func escolha_arte_pendente() -> bool:
	return arte_id == "" and fim.is_empty() and sucessao == "none" and cena_sala == "" and not permanente.get("arts_unlocked", []).is_empty()


## true na escolha da 1ª chegada (nunca escolheu arte): subtítulo `art_sub_first`.
func escolha_arte_primeira() -> bool:
	return str(permanente.get("last_art", "")) == ""


## Subtítulo da janela: "AS DUAS ARTES FICAM LIBERADAS PARA SEMPRE" na 1ª vez, "CARREIRA n: ESCOLHA A ARTE" depois.
func subtitulo_escolha_arte() -> String:
	if escolha_arte_primeira():
		return texto_ui("art_sub_first")
	return preencher(texto_ui("art_sub_career_named", "{nome}: ESCOLHA A ARTE"), {"nome": nome_lutador().to_upper()})


## Cartões da janela de escolha: [{id, name, tagline, rule_text, fight_text, icon, apparatus, apparatus_name, last, last_text}].
## `last` = a arte da carreira anterior (já vem marcada). Textos com os números já preenchidos (com o nó ESTILO, se houver).
func artes_para_escolha() -> Array:
	var r: Array = []
	var ultima := str(permanente.get("last_art", ""))
	for a in academia.artes:
		if not (a.id in permanente.get("arts_unlocked", [])):
			continue
		var eh_ultima: bool = a.id == ultima
		r.append({
			"id": a.id, "name": a.name, "tagline": a.tagline, "icon": a.icon,
			"rule_text": texto_regra_arte(a.id), "fight_text": texto_traco_luta(a.id),
			"apparatus": a.apparatus, "apparatus_name": nome_curto_aparelho(a.apparatus).to_upper() if a.apparatus != "" else "",
			"last": eh_ultima,
			"last_text": preencher(texto_ui("art_last", "ÚLTIMA: {nome}"), {"nome": str(a.name).to_upper()}) if eh_ultima else "",
		})
	return r


## Escolhe a arte da carreira (1 clique). Vale a carreira inteira: não existe função de troca. Só com a escolha pendente
## e uma arte liberada. Salva na hora; zera `art_seconds`; guarda `last_art`.
func escolher_arte(id: String) -> bool:
	if not escolha_arte_pendente() or academia.arte(id).is_empty() or not (id in permanente.arts_unlocked):
		return false
	arte_id = id
	arte_segundos = 0.0
	_arte_comentada = false
	permanente["last_art"] = id
	_recalcular_bonus()  # Fase 5.4: nós da arte passam a valer
	_atualizar_traco()
	_chave_melhor = ""
	salvar()
	arte_mudou.emit(arte_id)
	permanente_mudou.emit()
	economia_mudou.emit()
	atualizar_risco_hud()
	return true


## Soma dos nós ESTILO comprados da arte (0 ou 0,5): o efeito da regra dela fica x(1 + estilo).
func estilo_arte(id: String) -> float:
	return float(_estilo.get(id, 0.0))


## Bônus do Boxe no clique MANUAL (0,50; com o nó 0,75). 0 sem arte ou com outra arte.
func bonus_arte_clique() -> float:
	var a := academia.arte(arte_id)
	if a.is_empty() or a.rule.type != "manual_click_bonus":
		return 0.0
	return float(a.rule.value) * (1.0 + estilo_arte(arte_id))


## Bônus do Jiu-jitsu na equipe: (1 + estilo) x min(teto, começo + por_minuto x minutos de arte). 0 sem a arte.
func bonus_arte_equipe() -> float:
	var a := academia.arte(arte_id)
	if a.is_empty() or a.rule.type != "crew_time_bonus":
		return 0.0
	var r: Dictionary = a.rule
	return (1.0 + estilo_arte(arte_id)) * minf(float(r.cap), float(r.start) + float(r.per_minute) * arte_segundos / 60.0)


## true quando o bônus da equipe chegou no teto (a UI mostra "(MÁX.)").
func arte_no_teto() -> bool:
	var a := academia.arte(arte_id)
	if a.is_empty() or a.rule.type != "crew_time_bonus":
		return false
	var r: Dictionary = a.rule
	return float(r.start) + float(r.per_minute) * arte_segundos / 60.0 >= float(r.cap) - 1.0e-9


## Texto do HUD da arte: "BOXE: +50% NO SEU CLIQUE", "JIU-JITSU: EQUIPE +48%" (ou "... (MÁX.)"). "" sem arte.
## O do Jiu-jitsu muda com o tempo: a UI pode ler 1 vez por segundo.
func texto_hud_arte() -> String:
	var a := academia.arte(arte_id)
	if a.is_empty():
		return ""
	var pct := 0
	var chave := "hud_art_" + arte_id
	if a.rule.type == "manual_click_bonus":
		pct = int(round(100.0 * bonus_arte_clique()))
	elif a.rule.type == "crew_time_bonus":
		pct = int(round(100.0 * bonus_arte_equipe()))
		if arte_no_teto() and dados.ui.has(chave + "_max"):
			chave += "_max"
	return preencher(texto_ui(chave, ""), {"pct": pct})


## Texto da regra da arte para a janela de escolha: "+50% TREINO NO CLIQUE DA SUA MÃO", "EQUIPE +20% (SOBE 12% POR MINUTO ATÉ 100%)".
func texto_regra_arte(id: String) -> String:
	var a := academia.arte(id)
	if a.is_empty():
		return ""
	var e := 1.0 + estilo_arte(id)
	var r: Dictionary = a.rule
	var vars := {}
	if r.type == "manual_click_bonus":
		vars = {"pct": int(round(100.0 * float(r.value) * e))}
	elif r.type == "crew_time_bonus":
		vars = {"pct": int(round(100.0 * float(r.start) * e)), "rate": int(round(100.0 * float(r.per_minute) * e)),
			"cap": int(round(100.0 * float(r.cap) * e))}
	return preencher(str(a.rule_text), vars)


## Texto do traço de luta da arte: "BOXE: +10% DE DANO", "JIU-JITSU: -10% DE DANO RECEBIDO". "" sem arte.
func texto_traco_luta(id: String) -> String:
	var a := academia.arte(id)
	if a.is_empty():
		return ""
	var f: Dictionary = a.fight
	var extra := 0.0  # Fase 5.4: nós ativos da arte (Contragolpe / Base firme), valem também na janela de escolha
	for nid in nos_ativos_ids:
		var n: Dictionary = lutas.no_da_arvore(str(nid))
		if not n.is_empty() and n.effect_type == "art_fight_bonus" and n.requires_art == id:
			extra += float(n.effect_value)
	var pct := 0
	if absf(float(f.damage_mult) - 1.0) > 1.0e-9:
		pct = int(round((float(f.damage_mult) * (1.0 + extra) - 1.0) * 100.0))
	elif absf(float(f.taken_mult) - 1.0) > 1.0e-9:
		pct = int(round((1.0 - float(f.taken_mult) * maxf(0.0, 1.0 - extra)) * 100.0))
	return preencher(str(a.fight_text), {"pct": pct})


## Texto "FOR 40% / AGI 45% / RES 15%" do aparelho de arte ("" para os de toda carreira).
func texto_divisao(aparelho_id: String) -> String:
	var ap := dados.aparelho(aparelho_id)
	if ap.is_empty() or str(ap.art) == "":
		return ""
	var d: Dictionary = ap.split
	return preencher(texto_ui("focus_split", "FOR {f}% / AGI {a}% / RES {r}%"), {
		"f": int(round(100.0 * float(d.get("strength", 0.0)))), "a": int(round(100.0 * float(d.get("agility", 0.0)))),
		"r": int(round(100.0 * float(d.get("endurance", 0.0))))})


# O traço de luta da arte entra na tática do jogador (luta e prévia usam a mesma função, no motor).
func _atualizar_traco() -> void:
	var f: Dictionary = academia.arte(arte_id).get("fight", {})
	var dano := float(f.get("damage_mult", 1.0))
	var recebido := float(f.get("taken_mult", 1.0))
	var extra := _b("art_fight_bonus")  # Fase 5.4: Contragolpe / Base firme (só da arte jogada)
	if dano != 1.0:
		dano *= 1.0 + extra
	if recebido != 1.0:
		recebido *= maxf(0.0, 1.0 - extra)
	motor.traco = {"damage_mult": dano, "taken_mult": recebido}


## Tática do jogador já com o traço da arte (cópia). Útil para testes e para a UI mostrar números.
func tatica_efetiva(tatica_id: String = "") -> Dictionary:
	return motor.aplicar_traco(lutas.tatica(tatica) if tatica_id == "" else lutas.tatica(tatica_id))


## Bloco PRÓXIMA LUTA: {show, text, legacy, seconds}. `show` = o adversário da academia está PERIGOSO (na melhor das 3 táticas)
## há >= `gym_retire_hint_seconds` (career.json) seguidos. `legacy` = o Legado que aposentar agora leva (mesmo cálculo da confirmação).
## Os segundos não vão para o save (reabrir o jogo zera a contagem).
func dica_aposentar() -> Dictionary:
	var legado := int(previa_aposentar().total)
	var dias := dias_para_luta()
	var limite := int(lutas.calendario.get("retire_hint_days", 3))
	var vermelho := str(_risco_hud.rotulo) == "hard" and str(_risco_hud.adversario) == str(proximo_adversario().get("id", "x"))
	var mostrar := fim.is_empty() and luta.is_empty() and limite > 0 and dias >= 0 and dias <= limite \
		and vermelho and legado > 0
	return {"show": mostrar, "legacy": legado, "days": dias,
		"text": preencher(texto_ui("retire_hint", "PASSAR O POSTO AGORA LEVA {n} DE LEGADO"), {"n": legado})}


## Troca {chave} por valores. Valor em Array: troca uma ocorrência por item, na ordem (ex.: "{n}" duas vezes).
static func preencher(modelo: String, vars: Dictionary = {}) -> String:
	var s := modelo
	for chave in vars:
		var ph := "{%s}" % chave
		var v = vars[chave]
		if v is Array:
			for item in v:
				var i := s.find(ph)
				if i < 0:
					break
				s = s.substr(0, i) + str(item) + s.substr(i + ph.length())
		else:
			s = s.replace(ph, str(v))
	return s


## Lista de textos de uma chave de ui_texts.json (ex.: variações das dicas). [] se não for lista.
func lista_ui(chave: String) -> Array:
	var v = dados.ui.get(chave, [])
	return v if v is Array else []


## Textos prontos (sentence case, a UI aplica to_upper) da tela de fim. Chaves:
## title, who, reason, stat, tip, tip_tactic, support, tactic_name. Vazios quando não se aplicam.
func textos_fim(f: Dictionary = {}) -> Dictionary:
	if f.is_empty():
		f = fim
	if f.is_empty():
		return {}
	if f.kind == "retire":
		var belt: bool = int(f.summary.get("belts", 0)) > 0
		return {"title": texto_ui("retire_title"), "who": "", "reason": "", "stat": "", "tip": "", "tip_tactic": "",
			"support": texto_ui("retire_line_belt" if belt else "retire_line"), "tactic_name": "", "wait_green": "",
			"tip_extra": _dica_extra(f)}
	var r: Dictionary = f.reason
	var opp := lutas.adversario(str(f.opponent))
	var nome: String = opp.get("name", str(f.opponent))
	var atributo := str(r.get("attribute", "strength"))
	var res: Dictionary = f.result
	var quem := ""
	if bool(res.get("ko", false)):
		quem = preencher(texto_ui("end_who_ko"), {"nome": nome, "n": int(r.get("round", 1))})
	else:
		quem = preencher(texto_ui("end_who_points"), {"nome": nome})
	var modelos := lista_ui("reason_" + atributo)
	var st: Dictionary = r.get("stat", {})
	var texto_stat := _texto_estatistica(st)
	var principal := ""
	var faltaram := float(r.get("faltaram", -1.0))
	var semente := int(r.get("seed", 0))
	# Fim salvo antes da correção não tem `kind`: "faltaram" existe = missing; senão a estatística vira o motivo.
	var kind := str(r.get("kind", "missing" if faltaram >= 0.0 else "legacy"))
	match kind:
		"luck":
			atributo = "luck"
			var l := lista_ui("reason_luck")
			principal = str(l[semente % l.size()]) if not l.is_empty() else ""
		"far":
			principal = preencher(texto_ui("reason_far"), {"n": int(r.get("far_n", 2))})
		"far_plain":
			principal = texto_ui("reason_far_plain")
		"missing":
			if modelos.size() >= 2:
				principal = preencher(str(modelos[int(r.get("model", 0)) % 2]), {"n": NumberFormat.fmt(faltaram)})
		_:
			principal = texto_stat  # sem "faltaram": a estatística da luta vira o motivo
			texto_stat = ""
	var tip_ap := str(r.get("unlock_tip", ""))
	var dicas := lista_ui(("tip_unlock_" + tip_ap) if tip_ap != "" and kind != "luck" else ("tip_" + atributo))
	if dicas.is_empty() and tip_ap != "" and kind != "luck":
		dicas = [preencher(texto_ui("tip_unlock", "COMPRE A {nome} CEDO NA PRÓXIMA CARREIRA"), {"nome": nome_curto_aparelho(tip_ap).to_upper()})]
	var dica := str(dicas[int(r.get("tip", 0)) % dicas.size()]) if not dicas.is_empty() else ""
	var dica_t := ""
	var tt := str(r.get("better_tactic", ""))
	var pool := lista_ui("tip_tactic")
	if kind == "luck":
		tt = ""
	if tt != "" and not pool.is_empty():
		dica_t = str(pool[int(r.get("tip", 0)) % pool.size()])
	return {"title": texto_ui("end_defeat_title"), "who": quem, "reason": principal, "stat": texto_stat,
		"tip": dica, "tip_tactic": dica_t, "support": texto_ui("end_support_line_disc", texto_ui("end_support_line")),
		"tactic_name": str(lutas.tatica(tt).get("name", "")),
		"wait_green": "" if kind == "luck" else texto_ui("tip_wait_green"),
		"tip_extra": _dica_extra(f)}


# Fase 5 (opcional para a UI): dica extra do fim de carreira. Derrota na academia -> `tip_gym_loss`; derrota jogando de
# uma arte -> `tip_art_<arte>`; aposentou com o cinturão sem lutar na academia -> `tip_move_belt`. "" nos outros casos.
func _dica_extra(f: Dictionary) -> String:
	var s: Dictionary = f.get("summary", {})
	var lista: Array = []
	var indice := int(f.get("career_number", 1))
	if f.kind == "retire":
		# Só se encerrou com o cinturão ainda na garagem (a mudança é automática depois do cinturão).
		if int(s.get("belts", 0)) > 0 and str(s.get("location", "")) == academia.local_padrao:
			lista = lista_ui("tip_move_belt")
	else:
		var opp := lutas.adversario(str(f.get("opponent", "")))
		indice = int(f.get("reason", {}).get("tip", 0))
		if not opp.is_empty() and str(opp.location) != academia.local_padrao:
			lista = lista_ui("tip_gym_loss")
		elif str(s.get("art", "")) != "":
			lista = lista_ui("tip_art_" + str(s.art))
	return str(lista[indice % lista.size()]) if not lista.is_empty() else ""


func _texto_estatistica(st: Dictionary) -> String:
	var kind := str(st.get("kind", ""))
	var n := int(st.get("n", 0))
	var k := int(st.get("k", 0))
	match kind:
		"life_taken":
			var t := _modelo_reason("reason_endurance", 2, {"n": n, "k": k})
			if k == 1:  # singular: "1 GOLPE"
				t = t.replace(" 1 GOLPES", " 1 GOLPE").replace(" 1 golpes", " 1 golpe")
			return t
		"stronger":
			# Fim salvo antes da correção podia ter n fora de 20-99: sem texto.
			return _modelo_reason("reason_strength", 2, {"n": n}) if n >= 20 and n < 100 else ""
		"stronger_x":
			return preencher(texto_ui("stat_stronger_x"), {"n": n})
		"stronger_cap":
			return preencher(texto_ui("stat_stronger_cap"), {"n": n})
		"dodged":
			return _modelo_reason("reason_agility", 2, {"n": n})
		"crits":
			return _modelo_reason("reason_agility", 3, {"n": n, "k": k})
		"points":
			return preencher(texto_ui("stat_points"), {"n": n, "k": k})
		"luck_odds":
			return preencher(texto_ui("stat_luck_odds"), {"n": n})
		"luck_rare":
			return texto_ui("stat_luck_rare")
	return ""


func _modelo_reason(chave: String, i: int, vars: Dictionary) -> String:
	var l := lista_ui(chave)
	return preencher(str(l[i]), vars) if l.size() > i else ""


func salvar() -> bool:
	if store.bloqueado:
		_avisar("Save não gravado: o arquivo no disco é de uma versão mais nova do jogo.")
		return false
	var unix := store.salvar(para_save())
	if unix < 0:
		_avisar("Falha ao gravar o save.")
		return false
	ultimo_save_unix = unix
	ultimo_save_texto = Time.get_time_string_from_system()
	_tempo_autosave = 0.0
	salvo.emit(ultimo_save_texto)
	return true


func carregar_save() -> void:
	var r := store.carregar()
	aplicar_save(r.estado)
	ultimo_save_unix = r.saved_at_unix
	ultimo_save_texto = _horario_local(ultimo_save_unix) if ultimo_save_unix > 0 else "nenhum"
	_tempo_autosave = 0.0
	avisos.clear()
	if r.mensagem != "":
		avisos.append(r.mensagem)
	avisos_mudaram.emit(avisos)
	carregado.emit(r.status)


## Texto do diálogo de confirmação de "Apagar save" (avisa se o save é de versão mais nova).
func texto_confirmar_apagar() -> String:
	if store != null and store.bloqueado:
		return "Este save é de uma versão mais nova do jogo. Apagar mesmo assim?"
	return "Apagar o save e o backup e começar do zero?"


func apagar_save() -> void:
	store.apagar()
	aplicar_save({})
	ultimo_save_unix = 0
	ultimo_save_texto = "nenhum"
	_tempo_autosave = 0.0
	avisos.clear()
	avisos_mudaram.emit(avisos)


## Campos do estado que vão para o save (v7). Produção e custos não são salvos (vêm de data/).
func para_save() -> Dictionary:
	return {
		"career": {
			"metronome_level": nivel_metronomo,
			"location": local_id,
			"art": arte_id,
			"art_seconds": arte_segundos,
			"apparatus_owned": aparelhos_montados_ids.duplicate(),
			"boxes": caixas_lista.duplicate(true),
			"training": treino,
			"attributes": atributos.duplicate(),
			"focus": foco,
			"generators": geradores.duplicate(),
			"upgrades": niveis_melhoria.duplicate(),
			"paid_generators": geradores_pagos.duplicate(),
			"glove_level": nivel_luva,
			"crew_click": crew_click_comprado,
			"money": dinheiro,
			"fame": fama,
			"ladder_index": indice_escada,
			"belt": cinturao,
			"tactic": tatica,
			"play_seconds": tempo_jogo,
			"campaign_seconds": segundos_campanha,
			"fight_day": fight_day,
			"active_nodes": nos_ativos_ids.duplicate(),
			"gestured_gloves": gestos_calcados.duplicate(),
			"disciple": discipulo.duplicate(true) if not discipulo.is_empty() else null,
			"mentor_greeted": mentor_cumprimentou,
			"money_earned": dinheiro_ganho,
			"fight": luta.duplicate(true) if not luta.is_empty() else null,
		},
		"permanent": permanente.duplicate(),
		"ending": fim.duplicate(true) if not fim.is_empty() else null,
		"school": escola.duplicate(true),
	}


## Aplica um estado lido do save (formato v7). Campo faltando ou inválido recebe o padrão.
func aplicar_save(estado: Dictionary) -> void:
	var c = estado.get("career", {})
	if not (c is Dictionary):
		c = {}
	treino = _numero_valido(c.get("training", 0.0))

	atributos = {}
	var a = c.get("attributes", {})
	for id in dados.atributos:
		atributos[id] = _numero_valido(a.get(id, 0.0)) if a is Dictionary else 0.0

	# Fase 5: permanent primeiro (as artes liberadas validam a arte da carreira), depois local e arte
	permanente = _validar_permanente(estado.get("permanent", null))
	_validar_local_e_arte(c)
	aparelhos_montados_ids = _validar_aparelhos(c.get("apparatus_owned", null), not c.is_empty())
	var f := str(c.get("focus", ""))
	foco = f if aparelho_montado(f) else dados.default_focus
	if f != "" and not aparelho_montado(f):
		_avisar("Foco em aparelho não montado: voltou para o padrão.")

	geradores = {}
	var gs = c.get("generators", {})
	for g in dados.geradores:
		var q = gs.get(g.id, 0) if gs is Dictionary else 0
		geradores[g.id] = _inteiro_valido(q, 1.0e9)

	niveis_melhoria = {}
	var us = c.get("upgrades", {})
	for ap in dados.todos_aparelhos():
		var n = us.get(ap.id, 0) if us is Dictionary else 0
		niveis_melhoria[ap.id] = _inteiro_valido(n, float(ap.upgrades.size()))
		if niveis_melhoria[ap.id] > 0 and not aparelho_montado(ap.id):
			niveis_melhoria[ap.id] = 0
			_avisar("Melhoria em aparelho não montado: zerada.")

	# Fase 3
	geradores_pagos = {}
	var gp = c.get("paid_generators", {})
	for g in lutas.geradores_pagos:
		var q = gp.get(g.id, 0) if gp is Dictionary else 0
		geradores_pagos[g.id] = _inteiro_valido(q, 1.0e9)
	nivel_luva = _inteiro_valido(c.get("glove_level", 0), float(lutas.luvas.size()))
	crew_click_comprado = typeof(c.get("crew_click", false)) == TYPE_BOOL and c.get("crew_click", false) and not lutas.crew_click.is_empty()
	caixas_lista = _validar_caixas(c.get("boxes", null))
	dinheiro = _numero_valido(c.get("money", 0.0))
	fama = _inteiro_valido(c.get("fame", 0), 1.0e15)
	indice_escada = _inteiro_valido(c.get("ladder_index", 0), float(lutas.adversarios.size()))
	# O cinturão é consequência de a escada ter passado do adversário que o dá (Fase 5: o Muralha, não o fim da escada).
	var i_cint := lutas.indice_cinturao()
	cinturao = i_cint >= 0 and indice_escada > i_cint
	_corrigir_local_pela_escada()
	var t := str(c.get("tactic", ""))
	tatica = t if not lutas.tatica(t).is_empty() else lutas.tatica_padrao
	tempo_jogo = _numero_valido(c.get("play_seconds", 0.0))
	dinheiro_ganho = _numero_valido(c.get("money_earned", 0.0))
	luta = _validar_luta(c.get("fight", null))
	# Fase 5.3: relógio e data. Data ausente ou inválida = folga cheia a partir do dia de hoje.
	segundos_campanha = _numero_valido(c.get("campaign_seconds", 0.0))
	var fd := -1
	if not escada_completa():
		var bruto = c.get("fight_day", null)
		fd = _inteiro_valido(bruto, 1.0e9) if (typeof(bruto) == TYPE_FLOAT or typeof(bruto) == TYPE_INT) else 0
		if fd <= 0 or fd > dia_campanha() + 999:
			fd = _data_da_proxima_luta()
	fight_day = fd
	_dia_anterior = dia_campanha()
	_aviso_data_chave = -2
	_dia_chegou_emitido = false
	nos_ativos_ids = _validar_ativos(c.get("active_nodes", null))
	_recalcular_bonus()
	_atualizar_traco()
	nivel_metronomo = _inteiro_valido(c.get("metronome_level", 0), float(metronomo_niveis()))
	_acc_metronomo = 0.0
	_acc_assist = _assist_primeiro()
	_chave_melhor = ""
	fim = _validar_fim(estado.get("ending", null))
	# Fase 6a: escola (depois de permanente e fim: o padrão depende deles) e estado volátil das falas
	gestos_calcados = _validar_gestos(c.get("gestured_gloves", []))
	escola = _validar_escola(estado.get("school", null), not estado.is_empty())
	for b in caixas_lista:  # 6c2: o hall pode ter baixado os cliques da caixa
		b["hits"] = mini(int(b.hits), maxi(0, cliques_para_abrir() - 1))
	# Fase 6b1: passar o posto. O estado da sucessão vem do save (school.handover); o discípulo depois dele.
	_aplicar_handover_da_carga()
	discipulo = _validar_discipulo(c.get("disciple", null), not c.is_empty())
	var greeted = c.get("mentor_greeted", true)  # ausente = true: save sem o campo não dispara toques no meio da campanha
	mentor_cumprimentou = typeof(greeted) != TYPE_BOOL or greeted
	_reiniciar_falas()
	_finalizar_motivo(false)
	_motivo_cache = {}

	_emitir_tudo()


# Luta salva: adversário inexistente (ou fora da vez) ou formato ruim é descartada, sem vitória nem derrota.
func _validar_luta(v: Variant) -> Dictionary:
	if v == null:
		return {}
	if not (v is Dictionary):
		_avisar("Luta salva inválida: descartada.")
		return {}
	var opp := lutas.adversario(str(v.get("opponent", "")))
	var r = v.get("result", null)
	var p = v.get("player", null)
	if opp.is_empty() or lutas.indice_adversario(opp.id) != indice_escada or not (r is Dictionary) or not (p is Dictionary) 			or not r.has("win") or not _local_permite(opp):
		_avisar("Luta salva com adversário inexistente ou dados inválidos: descartada.")
		return {}
	var tt := str(v.get("tactic", ""))
	var motivo_salvo = v.get("reason", null)
	var luta_ok := {
		"opponent": opp.id, "tactic": tt if not lutas.tatica(tt).is_empty() else lutas.tatica_padrao,
		"seed": _inteiro_valido(v.get("seed", 0), 4294967295.0),
		"player": {"strength": _numero_valido(p.get("strength", 0.0)), "agility": _numero_valido(p.get("agility", 0.0)),
			"endurance": _numero_valido(p.get("endurance", 0.0))},
		"result": {"win": r.win == true, "ko": r.get("ko", false) == true, "t_ko": _numero_ou(r.get("t_ko", -1.0), -1.0),
			"t_end": _numero_valido(r.get("t_end", 0.0)), "round": _inteiro_valido(r.get("round", 0), 1000.0),
			"pct_player": _numero_valido(r.get("pct_player", 0.0)), "pct_opponent": _numero_valido(r.get("pct_opponent", 0.0))},
	}
	# Motivo calculado em lutar(); ausente (save antigo) = calculado sob demanda.
	if motivo_salvo is Dictionary and not motivo_salvo.is_empty():
		luta_ok["reason"] = motivo_salvo.duplicate(true)
	return luta_ok


func _validar_permanente(v: Variant) -> Dictionary:
	var p: Dictionary = v if v is Dictionary else {}
	var r := {
		"legacy_total": _inteiro_valido(p.get("legacy_total", 0), 1.0e15),
		"career_number": maxi(1, _inteiro_valido(p.get("career_number", 1), 1.0e9)),
		"careers_finished": _inteiro_valido(p.get("careers_finished", 0), 1.0e9),
		"best_wins": _inteiro_valido(p.get("best_wins", 0), 1.0e9),
		"belts_won": _inteiro_valido(p.get("belts_won", 0), 1.0e9),
		"skill_nodes": _validar_nos(p.get("skill_nodes", [])),
		"revenge_opponent": _validar_algoz(p.get("revenge_opponent", "")),
		"arts_unlocked": _validar_artes_liberadas(p.get("arts_unlocked", [])),
		"last_art": _validar_arte_id(p.get("last_art", "")),
	}
	r["tree_last_node"] = _validar_ultimo_no(p.get("tree_last_node", ""), r.skill_nodes)  # Fase 5.4
	return r


# Nós salvos: ignora id inexistente ou repetido e nó cujo `requires` não está na lista (com aviso).
func _validar_nos(v: Variant) -> Array:
	var saida: Array = []
	if not (v is Array):
		return saida
	for x in v:
		var id := str(x)
		if lutas.no_da_arvore(id).is_empty() or id in saida:
			_avisar("Nó da árvore salvo inválido ou repetido (%s): ignorado." % id)
			continue
		saida.append(id)
	var mudou := true
	while mudou:
		mudou = false
		for id in saida.duplicate():
			var pai: String = lutas.no_da_arvore(id).requires
			if pai != "" and not (pai in saida):
				_avisar("Nó da árvore salvo sem o anterior (%s): ignorado." % id)
				saida.erase(id)
				mudou = true
	return saida


func _validar_algoz(v: Variant) -> String:
	var id := str(v) if v is String else ""
	return id if not lutas.adversario(id).is_empty() else ""


# Tela de fim pendente: tipo desconhecido ou formato ruim vira "nenhuma".
func _validar_fim(v: Variant) -> Dictionary:
	if v == null:
		return {}
	if not (v is Dictionary) or not (str(v.get("kind", "")) in ["defeat", "retire"]):
		_avisar("Tela de fim salva inválida: descartada.")
		return {}
	var s = v.get("summary", {})
	if not (s is Dictionary):
		s = {}
	var r = v.get("result", {})
	var rs = v.get("reason", {})
	var pl = v.get("player", {})
	return {
		"kind": str(v.kind), "career_number": maxi(1, _inteiro_valido(v.get("career_number", 1), 1.0e9)),
		"legacy_gained": _inteiro_valido(v.get("legacy_gained", 0), 1.0e15),
		"legacy_notebook": _inteiro_valido(v.get("legacy_notebook", 0), 1.0e15),
		"legacy_total": _inteiro_valido(v.get("legacy_total", 0), 1.0e15),
		"honor_gained": _inteiro_valido(v.get("honor_gained", 0), 1.0e15),
		"opponent": str(v.get("opponent", "")), "tactic": str(v.get("tactic", "")),
		"seed": _inteiro_valido(v.get("seed", 0), 4294967295.0),
		"player": pl.duplicate(true) if pl is Dictionary else {},
		"result": r.duplicate(true) if r is Dictionary else {},
		"reason": rs.duplicate(true) if rs is Dictionary else {},
		"summary": {"wins": _inteiro_valido(s.get("wins", 0), 1.0e9), "belts": _inteiro_valido(s.get("belts", 0), 1.0e9),
			"fame": _inteiro_valido(s.get("fame", 0), 1.0e15), "money_earned": _numero_valido(s.get("money_earned", 0.0)),
			"play_seconds": _numero_valido(s.get("play_seconds", 0.0)), "art": _validar_arte_id(s.get("art", "")),
			"location": str(s.get("location", ""))},
	}


# Soma ganho ao saldo e ao atributo do foco.
func _ganhar(valor: float) -> void:
	if is_nan(valor) or valor <= 0.0:
		return
	# Fase 5: o aparelho da arte divide o ganho nos 3 atributos (o saldo recebe o valor inteiro).
	var divisao := divisao_aparelho(foco)
	for atributo in divisao:
		var parte: float = valor * float(divisao[atributo])
		if parte <= 0.0:
			continue
		atributos[atributo] = clampf(float(atributos.get(atributo, 0.0)) + parte, 0.0, VALOR_MAXIMO)
		atributo_mudou.emit(atributo, atributos[atributo])
	_definir_treino(treino + valor)


# Gasta saldo (nunca fica negativo; atributo não é tocado).
func _gastar(custo: float) -> void:
	_definir_treino(maxf(0.0, treino - custo))


# Gasta dinheiro (nunca fica negativo).
func _gastar_dinheiro(custo: float) -> void:
	dinheiro = maxf(0.0, dinheiro - custo)
	dinheiro_mudou.emit(dinheiro)


# Mantém o treino sempre finito e não negativo.
func _definir_treino(valor: float) -> void:
	if is_nan(valor):
		push_warning("GameState: treino virou NaN, valor mantido.")
		return
	treino = clampf(valor, 0.0, VALOR_MAXIMO)
	treino_mudou.emit(treino)


# Número finito e >= 0, senão 0.
func _numero_valido(v: Variant) -> float:
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return 0.0
	var x := float(v)
	if not is_finite(x):
		return 0.0
	return clampf(x, 0.0, VALOR_MAXIMO)


# Número finito (aceita negativo, ex.: -1 = "não há"); senão o padrão.
func _numero_ou(v: Variant, padrao: float) -> float:
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return padrao
	var x := float(v)
	return x if is_finite(x) else padrao


# Inteiro entre 0 e maximo (floor; inválido ou negativo vira 0).
func _inteiro_valido(v: Variant, maximo: float) -> int:
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return 0
	var x := float(v)
	if not is_finite(x):
		return 0
	return int(clampf(floorf(x), 0.0, maximo))


func _emitir_tudo(pedir_arte: bool = true) -> void:
	_metro_prev = nivel_metronomo  # Fase 6a: carga e NOVA CAMPANHA não contam como compra
	_crew_prev = crew_click_comprado
	treino_mudou.emit(treino)
	for id in atributos:
		atributo_mudou.emit(id, atributos[id])
	foco_mudou.emit(foco)
	dinheiro_mudou.emit(dinheiro)
	fama_mudou.emit(fama)
	tatica_mudou.emit(tatica)
	luva_mudou.emit(luvas_abertas(), sufixo_luva())
	caixas_mudaram.emit()
	metronomo_mudou.emit(nivel_metronomo)
	crew_click_mudou.emit(crew_click_comprado)
	local_mudou.emit(local_id)
	arte_mudou.emit(arte_id)
	_atualizar_estado_assist()
	escada_mudou.emit()
	economia_mudou.emit()
	carreira_mudou.emit()
	honra_mudou.emit(honra())
	hall_mudou.emit()
	campanha_completa_mudou.emit()
	if risco_hud_ativo:
		atualizar_risco_hud()
	_verificar_calendario()  # reabrir com Faltam <= 3 mostra a faixa uma vez; no dia, abre a prévia do dia
	_checar_sala()
	if pedir_arte and escolha_arte_pendente():
		escolha_arte_pedida.emit(escolha_arte_primeira())


func _avisar(mensagem: String) -> void:
	if mensagem in avisos:
		return
	push_warning("GameState: " + mensagem)
	avisos.append(mensagem)
	avisos_mudaram.emit(avisos)


# Pasta do save: "--save-dir=..." na linha de comando, pasta de testes em --script, ou a real.
func _pasta_save_inicial() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="):
			return arg.trim_prefix("--save-dir=")
	var args := OS.get_cmdline_args()
	if "--script" in args or "-s" in args:
		return PASTA_SAVE_TESTES
	return SaveStore.PASTA_REAL


func _horario_local(unix: int) -> String:
	var bias_s: int = Time.get_time_zone_from_system().get("bias", 0) * 60
	return Time.get_time_string_from_unix_time(unix + bias_s)


## Caixas fechadas, na ordem da compra: [{item, kind, hits}]. Cópia (mexer nela não muda o jogo).
func caixas() -> Array:
	return caixas_lista.duplicate(true)


## true se o item (id de aparelho ou de luva) está numa caixa fechada.
func tem_caixa(item: String) -> bool:
	return _indice_caixa(item) >= 0


## A caixa do item ({item, kind, hits}) ou {} se não há.
func caixa(item: String) -> Dictionary:
	var i := _indice_caixa(item)
	return caixas_lista[i].duplicate() if i >= 0 else {}


## Cliques que ainda faltam para abrir a caixa do item (0 se não há caixa).
func cliques_faltando(item: String) -> int:
	var i := _indice_caixa(item)
	return maxi(0, cliques_para_abrir() - int(caixas_lista[i].hits)) if i >= 0 else 0


## true se há uma luva esperando na caixa (a próxima só fica à venda depois de abrir).
func luva_em_caixa() -> bool:
	for b in caixas_lista:
		if b.kind == "glove":
			return true
	return false


## Luvas que já valem (abertas): glove_level menos a que está na caixa.
func luvas_abertas() -> int:
	return maxi(0, nivel_luva - (1 if luva_em_caixa() else 0))


## Um clique na caixa (só o mouse; Espaço nunca chama isto). Soma 1 batida; na última abre.
## Não treina, não dá crítico e não mexe em `_ocioso`. false se não há caixa ou a janela/luta bloqueia.
func bater_caixa(item: String) -> bool:
	var i := _indice_caixa(item)
	if i < 0 or acoes_bloqueadas():
		return false
	caixas_lista[i]["hits"] = int(caixas_lista[i].hits) + 1
	var batidas := int(caixas_lista[i].hits)
	caixa_batida.emit(item, batidas)  # inclusive a última (a UI treme 1, 2, 3 px); depois vem caixa_aberta
	if batidas >= cliques_para_abrir():
		abrir_caixa(item)
	return true


## Abre a caixa já (o 3º clique chama isto; público para testes). Aplica o item, foca (aparelho) e salva.
func abrir_caixa(item: String) -> bool:
	var i := _indice_caixa(item)
	if i < 0:
		return false
	var tipo := str(caixas_lista[i].kind)
	caixas_lista.remove_at(i)
	if tipo == "apparatus":
		_montar_aparelho(item)
	salvar()
	caixa_aberta.emit(item, tipo)
	if tipo == "apparatus":
		aparelho_comprado.emit(item)
		foco_mudou.emit(foco)
	else:
		luva_mudou.emit(luvas_abertas(), sufixo_luva())
	economia_mudou.emit()
	return true


func _indice_caixa(item: String) -> int:
	for i in caixas_lista.size():
		if caixas_lista[i].item == item:
			return i
	return -1


func _criar_caixa(item: String, tipo: String) -> void:
	caixas_lista.append({"item": item, "kind": tipo, "hits": 0})


# Lê career.boxes: ausente/inválido = []. Descarta entrada inexistente, repetida, de aparelho já montado ou de
# outra arte, e luva que não é exatamente a última comprada. Corrige kind pelo item e prende hits em 0..clicks-1.
func _validar_caixas(v: Variant) -> Array:
	var r: Array = []
	if not (v is Array):
		return r
	var max_hits := maxi(0, dados.box_clicks_to_open - 1)
	for x in v:
		if not (x is Dictionary):
			_avisar("Caixa salva inválida: ignorada.")
			continue
		var item := str(x.get("item", ""))
		var tipo := ""
		if not dados.aparelho(item).is_empty():
			tipo = "apparatus"
		elif _indice_luva(item) >= 0:
			tipo = "glove"
		if tipo == "":
			_avisar("Caixa de item desconhecido ('%s'): ignorada." % item)
			continue
		if _indice_caixa_em(r, item) >= 0:
			_avisar("Caixa repetida ('%s'): ignorada." % item)
			continue
		if tipo == "apparatus":
			if desbloqueio(item).is_empty() or aparelho_montado(item) or not aparelho_existe(item):
				_avisar("Caixa de aparelho inválido ('%s'): ignorada." % item)
				continue
		elif _indice_luva(item) != nivel_luva - 1:
			_avisar("Caixa de luva fora de lugar ('%s'): ignorada." % item)
			continue
		var h = x.get("hits", 0)
		var hits := 0
		if typeof(h) == TYPE_FLOAT or typeof(h) == TYPE_INT:
			hits = int(clampf(floorf(float(h)) if is_finite(float(h)) else 0.0, 0.0, float(max_hits)))
		r.append({"item": item, "kind": tipo, "hits": hits})
	return r


func _indice_caixa_em(lista: Array, item: String) -> int:
	for i in lista.size():
		if lista[i].item == item:
			return i
	return -1


func _indice_luva(item: String) -> int:
	for i in lutas.luvas.size():
		if str(lutas.luvas[i].id) == item:
			return i
	return -1


# Lista de aparelhos montados: ignora inexistente/repetido (com aviso) e sempre inclui os sem `unlock`.
func _validar_aparelhos(v: Variant, avisar_ausente: bool = true) -> Array:
	var r: Array = []
	if v is Array:
		for x in v:
			var id := str(x)
			if dados.aparelho(id).is_empty() or id in r:
				_avisar("Aparelho salvo inválido ou repetido ('%s'): ignorado." % id)
				continue
			if not aparelho_existe(id):  # Fase 5: aparelho de outra arte (ou de arte sem arte escolhida)
				_avisar("Aparelho de outra arte no save ('%s'): removido." % id)
				continue
			r.append(id)
	elif avisar_ausente:
		_avisar("Aparelhos montados ausentes no save: só os iniciais.")
	for id in _aparelhos_iniciais():
		if not (id in r):
			r.insert(0, id)
	return r


# Aparelho que treina o atributo decisivo da derrota, se não estiver montado ("" se montado ou sorte).
func _aparelho_da_dica(motivo: Dictionary) -> String:
	if str(motivo.get("kind", "")) == "luck":
		return ""
	var atributo := str(motivo.get("attribute", ""))
	for ap in dados.aparelhos:  # só os aparelhos de toda carreira (o da arte não entra na conta)
		if ap.attribute == atributo:
			return "" if aparelho_montado(ap.id) else str(ap.id)
	return ""


# career.location e career.art: inexistente volta ao padrão (arte fora das liberadas vira ""), tudo com aviso.
func _validar_local_e_arte(c: Dictionary) -> void:
	var l := str(c.get("location", ""))
	if academia.local(l).is_empty():
		if c.has("location"):
			_avisar("Local salvo inexistente ('%s'): voltou para o padrão." % l)
		l = academia.local_padrao
	local_id = l
	var a := str(c.get("art", ""))
	if a != "" and (academia.arte(a).is_empty() or not (a in permanente.arts_unlocked)):
		_avisar("Arte salva inexistente ou não liberada ('%s'): ignorada." % a)
		a = ""
	arte_id = a
	arte_segundos = _numero_valido(c.get("art_seconds", 0.0)) if a != "" else 0.0
	_atualizar_traco()


# Escada além do 1º adversário de outro local com a carreira na garagem (save editado): vai para esse local.
func _corrigir_local_pela_escada() -> void:
	for i in lutas.adversarios.size():
		var loc := str(lutas.adversarios[i].location)
		if loc != academia.local_padrao:
			if indice_escada > i and local_id == academia.local_padrao and not academia.local(loc).is_empty():
				_avisar("Escada passou do 1º adversário de '%s' na garagem: carreira movida para lá." % loc)
				local_id = loc
			return


func _validar_artes_liberadas(v: Variant) -> Array:
	var r: Array = []
	if not (v is Array):
		return r
	for x in v:
		var id := str(x)
		if academia.arte(id).is_empty() or id in r:
			_avisar("Arte liberada inválida ou repetida ('%s'): ignorada." % id)
			continue
		r.append(id)
	return r


func _validar_arte_id(v: Variant) -> String:
	var id := str(v) if v is String else ""
	return id if not academia.arte(id).is_empty() else ""


# Fase 5.4: último nó comprado (centro do mapa). Id desconhecido ou não comprado volta para o último de skill_nodes ("" se não há).
func _validar_ultimo_no(v: Variant, nos: Array) -> String:
	var id := str(v) if v is String else ""
	if id != "" and id in nos:
		return id
	return str(nos[-1]) if not nos.is_empty() else ""


# Fase 5.4: career.active_nodes. Ausente (save antigo) = cópia de skill_nodes; senão só ids conhecidos, comprados e sem repetição.
func _validar_ativos(v: Variant) -> Array:
	var nos: Array = permanente.get("skill_nodes", [])
	if not (v is Array):
		return nos.duplicate()
	var r: Array = []
	for x in v:
		var id := str(x)
		if id in nos and not (id in r) and not lutas.no_da_arvore(id).is_empty():
			r.append(id)
	return r


## Quem está jogando: "first" (John Bullet, a campanha dele) ou "disciple" (discípulo padrão, das seguintes).
func lutador_atual() -> String:
	return "first" if numero_carreira() <= int(escola.get("first_fighter_campaign", 1)) else "disciple"


## true se o marco da escola já foi gravado (prologue_seen, first_school_win, garage_saved, garage_saved_seen...).
func marco(id: String) -> bool:
	var m = escola.get("milestones", {})
	return m is Dictionary and m.has(id)


## Dados do marco ({campaign, version, ...}); {} se não existe.
func dados_marco(id: String) -> Dictionary:
	return escola.milestones[id].duplicate() if marco(id) else {}


## "pending" (ainda não tocou), "playing" ou "over".
func abertura_estado() -> String:
	return _abertura


## Segundos de sala ativa sem clique (zera no clique; começa em 0 ao abrir o jogo). Não conta janela nem luta.
func segundos_ocioso() -> float:
	return _parado


## true com balão na tela (comentário ou abertura).
func tem_balao() -> bool:
	return not _balao.is_empty()


## Descrição da luva inicial: "o par do John" no 1º lutador, a descrição padrão nos outros.
func descricao_luva_inicial() -> String:
	if lutador_atual() == "first":
		return texto_ui("glove_start_desc", dialogos.texto_objeto("starter_glove_desc"))
	return texto_ui("glove_start_desc_disc", str(lutas.luva_base.get("description", "")))


# Grava um marco (id desconhecido também). false se já existia. `salvar_agora`: false quando quem chama salva em seguida.
func _gravar_marco(id: String, extra: Dictionary = {}, salvar_agora: bool = true) -> bool:
	if marco(id):
		return false
	var m := {"campaign": numero_carreira(), "version": MARCOS_VERSAO}
	for k in extra:
		m[k] = extra[k]
	escola["milestones"][id] = m
	if salvar_agora:
		salvar()
	marco_gravado.emit(id)
	return true


## Pula a abertura (ESC segurado 0,5 s): mesmo estado final de terminar. Em "pending" só grava o marco.
func pular_abertura() -> void:
	if _abertura == "pending":
		_gravar_marco("prologue_seen")
		_abertura = "over"
		_ultimo_comentario = _t_real
		abertura_mudou.emit(_abertura)
	elif _abertura == "playing":
		_terminar_abertura(true)


func _iniciar_abertura() -> void:
	if dialogos.opening.get("lines", []).is_empty():
		pular_abertura()
		return
	_abertura = "playing"
	_abertura_t = 0.0
	_abertura_idx = 0
	_abertura_proxima = float(dialogos.opening.get("first_line_at", 1.5))
	_gravar_marco("prologue_seen")  # em t = 0, antes do gesto e de qualquer balão: fechar o jogo não repete nada
	abertura_mudou.emit(_abertura)
	pedir_gesto("opening")


func _tick_abertura(delta: float) -> void:
	_abertura_t += delta
	if _abertura_t >= float(dialogos.opening.get("max_seconds", 20.0)):
		_terminar_abertura(false)  # o balão que está escrevendo termina sozinho
		return
	var ids: Array = dialogos.opening.get("lines", [])
	if _abertura_idx < ids.size():
		if _balao.is_empty() and _gesto.is_empty() and sala_ativa() and _abertura_t >= _abertura_proxima:
			var l := dialogos.linha(str(ids[_abertura_idx]))
			if not l.is_empty() and str(l.speaker) == "coach" and not coach_presente():
				return  # sem Osmar desenhado neste local: espera voltar a um onde ele esteja (o teto de 20 s encerra)
			_abertura_idx += 1
			if not l.is_empty():
				_mostrar_fala(l, false)
	elif _balao.is_empty():
		_terminar_abertura(false)


func _terminar_abertura(pulada: bool) -> void:
	_abertura = "over"
	if pulada:
		_cancelar_balao()
		cancelar_gesto()
	_ultimo_comentario = _t_real  # o fim da abertura conta como comentário
	abertura_mudou.emit(_abertura)


## Um gatilho de comentário chegou (id de data/dialogos.json > triggers). Resolvido no próximo tick: se a sala não
## está calma, só os gatilhos `defer` ficam na vaga única; os outros somem. Público para os testes.
func disparar_gatilho(id: String, params: Dictionary = {}) -> void:
	if dialogos.gatilho(id).is_empty():
		return
	_gatilhos_quadro.append({"id": id, "params": params})


## A UI avisa que o balão sumiu (leitura acabou). Sem isso o jogo libera sozinho depois do tempo previsto.
func fala_terminada(id: String) -> void:
	if str(_balao.get("id", "")) == id:
		_limpar_balao()


func _ctx_falas(params: Dictionary) -> Dictionary:
	return {"campaign": numero_carreira(), "first_campaign": int(escola.get("first_fighter_campaign", 1)),
		"lutador": lutador_atual(), "location": local_id, "milestones": escola.get("milestones", {}),
		"lines_seen": escola.get("lines_seen", {}), "params": params,
		"mentor_kind": str(params.get("mentor_kind", ""))}


func _mostrar_fala(l: Dictionary, como_comentario: bool, params: Dictionary = {}) -> bool:
	var falante := str(l.speaker)
	var voz := str(dialogos.personagem(falante).get("voice", falante))
	if falante == DialogosData.FALANTE_MENTOR:
		# 6c2: "mentor" vira quem está sentado no caixote: "first" (o John, voz dele) ou "last" (discípulo; voz de mentor_voice)
		var m := mentor_do_caixote()
		if m.is_empty():
			return false
		falante = str(m.id)
		voz = "first"
	var texto := dialogos.texto_balao(l, params)
	var dur := float(dialogos.tempo_fala(texto, voz).total)
	_balao = {"id": str(l.id), "ate": _t_real + dur + float(dialogos.comments.get("balloon_safety_seconds", 1.0))}
	# A UI pode recusar o balão (sem espaço) chamando fala_recusada() dentro do sinal: aí nada é gravado.
	_fala_recusada = false
	if not baloes_escondidos:
		fala_pedida.emit(falante, texto, str(l.id))
	if _fala_recusada:
		_fala_recusada = false
		_balao = {}
		_calma = 0.0  # tenta de novo só depois de uma nova calma
		if como_comentario and l.repeat == "once":
			_guardar_vaga({"id": str(l.trigger), "params": {}}, dialogos.prioridade(l), true)
		return false
	if como_comentario:
		_ultimo_comentario = _t_real
		escola["lines_seen"][str(l.id)] = numero_carreira()
		if l.repeat == "once":
			salvar()  # única: salva na hora (a repetível vai no autosave)
		comentario.emit(str(l.id))
	return true


## A UI não conseguiu mostrar o balão pedido por `fala_pedida`: a fala não conta como vista (a única fica pendente).
## Chamar dentro do tratador do sinal (ou antes de qualquer outra coisa).
func fala_recusada(id: String) -> void:
	if str(_balao.get("id", "")) == id:
		_fala_recusada = true


func _limpar_balao() -> void:
	_balao = {}
	if _abertura == "playing":
		_abertura_proxima = _abertura_t + float(dialogos.opening.get("gap_between", 0.3))


func _cancelar_balao() -> void:
	if _balao.is_empty():
		return
	var id := str(_balao.id)
	_limpar_balao()
	fala_cancelada.emit(id)


# Janela, luta, tela de fim ou escolha da arte: o balão fecha na hora e o gesto "da sala" para.
func _fechar_para_janela() -> void:
	_cancelar_balao()
	_cancelar_toques(true)
	if not _gesto.is_empty() and str(_gesto.momento) in ["opening", "glove", "idle"]:
		cancelar_gesto()


func _tick_falas(delta: float) -> void:
	if cena_sala != "":
		_cena_sala_t += delta
		if _cena_sala_t > float(escola_cfg.get("gym_arrival", {}).get("max_locked_seconds", 15.0)) * 2.0:
			cena_sala_terminou()  # sem interface para avisar o fim: o relógio não fica parado para sempre
	_t_real += delta
	var ativa := sala_ativa()
	if ativa:
		_calma += delta
		_parado += delta
	else:
		_calma = 0.0
	if not _balao.is_empty() and _t_real >= float(_balao.ate):
		_limpar_balao()
	if not _gesto.is_empty() and _t_real >= float(_gesto.ate):
		_gesto = {}
	_tick_toques(delta, ativa)
	if _abertura == "pending":
		if ativa and coach_presente():  # o Osmar só abre a escola onde está desenhado
			_iniciar_abertura()
	elif _abertura == "playing":
		_tick_abertura(delta)
	if _abertura == "over":
		_tick_sala_parada(ativa)
		# A parede muda quando a sala é desenhada na garagem depois do marco; o comentário vem junto.
		if ativa and local_id == "garage" and marco("garage_saved") and not marco("garage_saved_seen"):
			_gravar_marco("garage_saved_seen")
			disparar_gatilho("garage_saved_return")
		elif ativa and local_id == "garage" and marco("garage_saved_seen") and not _garagem_retomada and not escola.lines_seen.has("cl_garagem_salva"):
			disparar_gatilho("garage_saved_return")  # fechou o jogo antes da fala: ela nunca se perde
		if ativa and local_id == "garage" and marco("garage_saved_seen"):
			_garagem_retomada = true
		# Fechou o jogo logo após NOVA CAMPANHA da derrota: rearma a 1ª derrota (a fala nunca se perde)
		if ativa and local_id == "garage" and not _derrota_rearmada:
			_derrota_rearmada = true
			var fim_ant = escola.get("last_end", null)
			if fim_ant is Dictionary and str(fim_ant.get("kind", "")) == "defeat" \
					and int(fim_ant.get("campaign", 0)) == numero_carreira() - 1 and not escola.lines_seen.has("cl_primeira_derrota"):
				disparar_gatilho("after_defeat")
		# 6c1: fechou o jogo antes da cl_primeira_academia (ou save antigo que só viu a cena agora): a fala nunca se perde
		if ativa and local_id == "gym" and not _academia_rearmada and marco(_marco_da_chegada()) and coach_presente():
			_academia_rearmada = true
			if not escola.lines_seen.has("cl_primeira_academia"):
				disparar_gatilho("gym_arrival")
		_tick_saida(ativa)
	_resolver_gatilhos(delta)


func _resolver_gatilhos(delta: float) -> void:
	if not _vaga.is_empty() and sala_ativa() and not _saida_tocando:  # 6c1: a vaga não envelhece durante a saída do John
		_vaga["espera"] = float(_vaga.espera) + delta
		if float(_vaga.espera) > float(dialogos.comments.get("defer_max_seconds", 15.0)) and not bool(_vaga.get("persiste", false)):
			_vaga = {}  # fala única (persiste) nunca é perdida: fica até o próximo espaço livre
	var novos := _gatilhos_quadro
	_gatilhos_quadro = []
	if novos.is_empty() and _vaga.is_empty():
		return
	var grupo := novos.duplicate()
	if not _vaga.is_empty():
		grupo.append({"id": _vaga.id, "params": _vaga.params, "vaga": true})
	var calma_base := sala_ativa() and _abertura == "over" and _balao.is_empty() and not _saida_tocando \
		and _calma >= float(dialogos.comments.get("settle_seconds", 2.0))
	if not calma_base:
		# Sem sala calma: só os `defer` esperam (uma vaga, vence a de maior prioridade); o resto é descartado.
		for g in novos:
			if bool(dialogos.gatilho(str(g.id)).get("defer", false)):
				var m := _melhor_do_grupo([g])
				if not m.is_empty():
					_guardar_vaga(g, dialogos.prioridade(m.linha), m.linha.repeat == "once")
		return
	var melhor := _melhor_do_grupo(grupo)
	if melhor.is_empty():
		if not _vaga.is_empty():
			_vaga = {}  # nada mais a dizer (a fala já tocou ou a condição mudou)
		return
	var g_ganho: Dictionary = melhor.g
	if (not _gesto.is_empty() or not _toques.is_empty()) and bool(dialogos.comments.get("after_gesture", true)):
		# "O gesto antes da fala": espera ele acabar (ou ser cancelado) na vaga.
		if not g_ganho.has("vaga"):
			_guardar_vaga(g_ganho, dialogos.prioridade(melhor.linha), melhor.linha.repeat == "once")
		return
	var l: Dictionary = melhor.linha
	var filler := dialogos.prioridade(l) <= int(dialogos.comments.get("filler_max_priority", 4))
	var intervalo := float(dialogos.comments.get("gap_filler_seconds" if filler else "gap_min_seconds", 60.0))
	# Prioridade 9 ou mais (garagem salva, 1ª derrota): só precisa de espaço livre, sem o intervalo de 60 s.
	if dialogos.prioridade(l) < 9 and _t_real - _ultimo_comentario < intervalo:
		# 6c1: o comentário da arte (uma vez por campanha) nunca se perde só pelo intervalo: espera na vaga até poder falar.
		if not g_ganho.has("vaga") and str(g_ganho.id) == str(escola_cfg.get("art_comment", {}).get("trigger", "art_choice")):
			_guardar_vaga(g_ganho, dialogos.prioridade(l), true)
		return  # sem intervalo: o novo some; a vaga (se for ela) segue esperando até vencer o tempo dela
	if g_ganho.has("vaga"):
		_vaga = {}
	_mostrar_fala(l, true, g_ganho.params)


func _melhor_do_grupo(grupo: Array) -> Dictionary:
	var todas: Array = []
	var dono := {}
	var osmar := coach_presente()
	for g in grupo:
		for l in dialogos.candidatas(str(g.id), _ctx_falas(g.params)):
			if str(l.speaker) == "coach" and not osmar:
				continue  # 6c1: só fala quem está desenhado neste local (nunca balão sem personagem embaixo)
			if str(l.speaker) == DialogosData.FALANTE_MENTOR and mentor_do_caixote().is_empty():
				continue  # 6c2: sem mentor sentado, nenhuma fala de mentor
			todas.append(l)
			dono[str(l.id)] = g
	var melhor := dialogos.melhor(todas, _ctx_falas({}), _rng_fala)
	if melhor.is_empty():
		return {}
	return {"linha": melhor, "g": dono[str(melhor.id)]}


func _guardar_vaga(g: Dictionary, prio: int, persiste: bool = false) -> void:
	if _vaga.is_empty() or prio > int(_vaga.prio):
		_vaga = {"id": str(g.id), "params": g.params, "prio": prio, "espera": 0.0, "persiste": persiste}


# Fio entre os sinais que já existem e os gatilhos (design §1.4).
func _ligar_gatilhos_de_fala() -> void:
	var pares: Array = [[caixa_criada, _fala_caixa_criada], [melhoria_comprada, _fala_melhoria],
		[metronomo_mudou, _fala_metronomo], [crew_click_mudou, _fala_crew], [caixa_aberta, _fala_caixa_aberta],
		[luta_resolvida, _fala_luta_resolvida], [aviso_data, _fala_aviso_data], [luta_resolvida, _toques_apos_vitoria]]
	for par in pares:
		var sinal: Signal = par[0]
		var rotina: Callable = par[1]
		if not sinal.is_connected(rotina):
			sinal.connect(rotina)


func _fala_caixa_criada(item: String, tipo: String) -> void:
	disparar_gatilho("big_purchase", {"what": tipo, "item": item})


func _fala_melhoria(aparelho: String, _melhoria: String, nivel: int) -> void:
	var total: int = dados.aparelho(aparelho).get("upgrades", []).size()
	if total > 0 and nivel >= total:
		disparar_gatilho("big_purchase", {"what": "upgrade_max", "item": aparelho})


func _fala_metronomo(nivel: int) -> void:
	if _metro_prev == 0 and nivel >= 1:
		disparar_gatilho("big_purchase", {"what": "metronome", "item": "metronome"})
	_metro_prev = nivel


func _fala_crew(comprado: bool) -> void:
	if comprado and not _crew_prev:
		disparar_gatilho("big_purchase", {"what": "crew_click", "item": "crew_click"})
	_crew_prev = comprado


func _fala_caixa_aberta(item: String, tipo: String) -> void:
	disparar_gatilho("box_opened", {"kind": tipo, "item": item})
	if tipo == "glove":
		disparar_gatilho("glove_new", {"item": item})
		pedir_gesto("glove", luvas_abertas())


func _fala_luta_resolvida(resumo: Dictionary) -> void:
	var fm = resumo.get("mentor_line", {})
	if bool(resumo.get("win", false)) and not resumo.has("retire") and fm is Dictionary and not fm.is_empty():
		disparar_gatilho("mentor_won", fm)  # 6c2: o mentor comenta; a fight_won do Osmar não sai nesta vitória
	elif bool(resumo.get("win", false)) and not resumo.has("retire"):
		disparar_gatilho("fight_won", {"revenge": bool(resumo.get("revenge", false)), "record": bool(resumo.get("record", false)),
			"opponent": str(resumo.get("opponent", ""))})


func _fala_aviso_data(dias: int) -> void:
	if dias == int(lutas.calendario.get("warn_days", 3)):
		var proximo: Dictionary = {} if escada_completa() else lutas.adversarios[indice_escada]
		disparar_gatilho("fight_near", {"opponent": str(proximo.get("id", ""))})


## Pede o gesto. `momento`: "opening", "fight_intro", "victory", "glove" (com `nivel`) ou "idle". Devolve o plano
## (e emite `gesto_pedido`) ou {} se não vale: discípulo nunca faz; luva já festejada; sala não ativa (glove, idle).
## A UI chama "fight_intro" no começo da animação da luta e "victory" quando começa o `outro`;
## "opening", "glove" e "idle" o GameState chama sozinho. Plano: {momento, version ("full"|"short"), start, duration,
## rip_at (-1 no curto), taps [t1, t2] (t2 - t1 = tap_interval), rip_sound, tap_sound, pose_at (só na vitória)}.
func pedir_gesto(momento: String, nivel: int = -1) -> Dictionary:
	if lutador_atual() != "first":
		return {}
	var g: Dictionary = dialogos.gesture
	var inicio := 0.0
	match momento:
		"opening":
			inicio = float(g.get("opening_start", 0.3))
		"fight_intro":
			inicio = float(g.get("fight_intro_start", 0.3))
		"victory":
			inicio = float(g.get("victory_short_start", 0.15))
		"glove":
			if nivel < 1 or nivel in gestos_calcados or not sala_ativa():
				return {}
			gestos_calcados.append(nivel)  # cancelado pelo clique também conta como feito
			inicio = float(g.get("glove_start", 0.3))
		"idle":
			if not sala_ativa() or not _balao.is_empty() or not _gesto.is_empty():
				return {}
		_:
			return {}
	var curto := momento == "victory" or momento == "idle"
	var primeiro := float(g.get("short_tap_at", 0.11) if curto else g.get("full_tap_at", 0.56))
	var sons: Dictionary = g.get("sounds", {})
	var plano := {"momento": momento, "version": "short" if curto else "full", "start": inicio,
		"duration": float(g.get("short_seconds", 0.44) if curto else g.get("full_seconds", 0.89)),
		"rip_at": -1.0 if curto else float(g.get("rip_at", 0.11)),
		"taps": [primeiro, primeiro + float(g.get("tap_interval", 0.22))],
		"rip_sound": str(sons.get("rip", "strap_rip")), "tap_sound": str(sons.get("tap", "tap_glove")),
		"pose_at": float(g.get("victory_pose_at", 0.6)) if momento == "victory" else -1.0}
	_gesto = {"momento": momento, "ate": _t_real + inicio + float(plano.duration)}
	gesto_pedido.emit(plano)
	return plano


## Qualquer clique do jogador (saco, botão, fora do alvo): cancela o gesto e zera a "sala parada".
## `clicar()` já chama isto; a UI chama nos outros cliques.
func registrar_clique() -> void:
	_cancelar_toques(false)  # Fase 6b1: qualquer clique cancela os toques do mentor (com a guarda do 1º clique)
	_toque_vitoria = -1.0  # e desiste dos toques que esperavam a volta da vitória
	_parado = 0.0
	_gestos_parada = 0
	_proximo_gesto_parada = float(dialogos.gesture.get("idle_first_seconds", 20.0))
	_idle_comentou = false
	cancelar_gesto()


func cancelar_gesto() -> void:
	if _gesto.is_empty():
		return
	_gesto = {}
	gesto_cancelado.emit()


# Sala parada: gesto curto aos 20 s, depois a cada 30 a 60 s (no máximo 3 por parada); comentário "parado" aos 45 s.
func _tick_sala_parada(ativa: bool) -> void:
	if not ativa:
		return
	var g: Dictionary = dialogos.gesture
	if lutador_atual() == "first" and _gestos_parada < int(g.get("idle_max_per_stop", 3)) and _parado >= _proximo_gesto_parada \
			and _balao.is_empty() and _gesto.is_empty():
		if not pedir_gesto("idle").is_empty():
			_gestos_parada += 1
			_proximo_gesto_parada = _parado + _rng_fala.randf_range(float(g.get("idle_repeat_min", 30.0)), float(g.get("idle_repeat_max", 60.0)))
	if not _idle_comentou and _parado >= float(dialogos.comments.get("idle_comment_seconds", 45.0)):
		_idle_comentou = true
		disparar_gatilho("idle")


# Zera o que é só de sessão (balão, vaga, intervalo, gesto) e decide o estado da abertura. Carga e "Apagar save".
func _reiniciar_falas() -> void:
	if not _balao.is_empty():
		fala_cancelada.emit(str(_balao.id))
	_balao = {}
	_gesto = {}
	_toques = {}
	_toque_ultimo = -1.0e9
	_toque_vitoria = -1.0
	_vaga = {}
	_gatilhos_quadro = []
	_ultimo_comentario = -1.0e9
	_calma = 0.0
	_parado = 0.0
	_gestos_parada = 0
	_proximo_gesto_parada = float(dialogos.gesture.get("idle_first_seconds", 20.0))
	_idle_comentou = false
	_garagem_retomada = false
	_derrota_rearmada = false
	cena_sala = ""  # 6c1: nada do que é só de sessão sobra depois de carregar
	_saida_tocando = false
	_saida_elenco = {}
	_academia_rearmada = false
	_arte_comentada = arte_id == "" or arte_segundos >= float(escola_cfg.get("art_comment", {}).get("after_art_seconds", 60.0))
	_abertura_t = 0.0
	_abertura_idx = 0
	_abertura = "over" if marco("prologue_seen") else "pending"
	abertura_mudou.emit(_abertura)


func _validar_gestos(v: Variant) -> Array:
	var r: Array = []
	if not (v is Array):
		return r
	for x in v:
		if typeof(x) != TYPE_FLOAT and typeof(x) != TYPE_INT:
			continue
		var n := int(x)
		if n >= 1 and n <= lutas.luvas.size() and not (n in r):
			r.append(n)
	return r


# state.school: ausente ou inválido recebe o padrão da migração (campanha atual, ou a próxima se há fim pendente).
func _validar_escola(v: Variant, havia_save: bool) -> Dictionary:
	var padrao_primeiro := numero_carreira() + (1 if not fim.is_empty() else 0)
	var s: Dictionary = {}
	if v is Dictionary:
		s = v
	elif v != null:
		_avisar("Bloco da escola inválido: recriado pelo padrão.")
	elif havia_save:
		push_warning("GameState: save sem o bloco da escola: recriado pelo padrão.")
	var r := {"first_fighter_campaign": padrao_primeiro, "milestones": {}, "lines_seen": {}, "last_end": null,
		"handover": null, "mentors": [], "roster": [], "honor": 0, "honor_total": 0, "hall_nodes": []}
	var f = s.get("first_fighter_campaign", null)
	if (typeof(f) == TYPE_INT or typeof(f) == TYPE_FLOAT) and is_finite(float(f)) and float(f) >= 1.0 and float(f) < 1.0e9:
		r["first_fighter_campaign"] = int(f)
	elif f != null:
		_avisar("Campanha do 1º lutador inválida: padrão aplicado.")
	var marcos = s.get("milestones", {})
	if marcos is Dictionary:
		for id in marcos:
			var m = marcos[id]
			var extra := {}
			var camp := 1
			var ver := MARCOS_VERSAO
			if m is Dictionary:
				extra = m.duplicate(true)
				camp = maxi(1, _inteiro_valido(m.get("campaign", 1), 1.0e9))
				ver = maxi(1, _inteiro_valido(m.get("version", MARCOS_VERSAO), 1.0e6))
			extra["campaign"] = camp
			extra["version"] = ver
			r["milestones"][str(id)] = extra
	elif s.has("milestones"):
		_avisar("Marcos da escola inválidos: zerados.")
	var vistas = s.get("lines_seen", {})
	if vistas is Dictionary:
		for id in vistas:
			if typeof(vistas[id]) == TYPE_INT or typeof(vistas[id]) == TYPE_FLOAT:
				var n := _inteiro_valido(vistas[id], 1.0e9)
				if n >= 1:
					r["lines_seen"][str(id)] = n
	elif s.has("lines_seen"):
		_avisar("Falas vistas inválidas: zeradas.")
	var le = s.get("last_end", null)
	if le is Dictionary and str(le.get("kind", "")) in ["defeat", "retire"]:
		r["last_end"] = {"kind": str(le.kind), "campaign": maxi(1, _inteiro_valido(le.get("campaign", 1), 1.0e9))}
	elif not fim.is_empty():
		r["last_end"] = {"kind": str(fim.kind), "campaign": int(fim.career_number)}
	_validar_escola_6b(s, r)
	_validar_escola_6c2(s, r)
	return r


## "none" | "scene_1" | "creating" | "scene_2" | "arriving". Fora de "none" a carreira está congelada.
func sucessao_estado() -> String:
	return sucessao


## Id da cena que a sucessão toca agora ("primeira_sucessao" ou "chegada_discipulo"); "" fora da sucessão.
## Depois de abrir um save no meio, a primeira_sucessao vira chegada_discipulo (a cena grande nunca repete).
func sucessao_cena() -> String:
	return str(_handover().get("scene", ""))


func _handover() -> Dictionary:
	var h = escola.get("handover", null)
	return h if h is Dictionary else {}


## Rascunho da tela de criação: {name, look}. {} fora da criação.
func rascunho() -> Dictionary:
	var h := _handover()
	return h.draft.duplicate(true) if h.get("draft", null) is Dictionary else {}


## Linhas da tela de criação (6b2) com o rascunho atual: ver DiscipulosData.linhas_tela(). `apagada` = cor da peça em "sem".
func linhas_tela_criacao() -> Array:
	var d := rascunho()
	return disciples.linhas_tela(d.get("look", {}) if d.get("look", null) is Dictionary else {})


## Nome sem espaços nas pontas e sem repetidos, só com as letras que a fonte desenha ("" se não sobrar nenhuma).
func limpar_nome(texto: String) -> String:
	return disciples.limpar_nome(texto)


## O discípulo da campanha: {name, look, campaign}. {} na campanha do John.
func discipulo_atual() -> Dictionary:
	return discipulo.duplicate(true)


## Nome de quem está lutando: "John Bullet" ou o nome do discípulo. A interface aplica `.to_upper()`.
func nome_lutador() -> String:
	if lutador_atual() == "first":
		return str(dialogos.cast.get("first", {}).get("name", "John Bullet"))
	return str(discipulo.get("name", disciples.nome_padrao))


## Texto do HUD no lugar de "Carreira N": só o nome, em maiúsculas.
func texto_hud_lutador() -> String:
	return preencher(texto_ui("hud_disciple", "{nome}"), {"nome": nome_lutador().to_upper()})


## Título do resumo de fim de campanha: "RESUMO DE {NOME}".
func titulo_resumo() -> String:
	return preencher(texto_ui("sum_title_named", "RESUMO DE {nome}"), {"nome": nome_lutador().to_upper()})


## Visual do lutador atual (9 campos). {} no John (ele usa as folhas dele).
func visual_lutador() -> Dictionary:
	if lutador_atual() == "first":
		return {}
	var l = discipulo.get("look", null)
	return l.duplicate(true) if l is Dictionary else disciples.look_padrao.duplicate()


## Cores de um visual (padrão: o do lutador atual): {campo: {id, slots, colors (hex), tokens}}. O John devolve {}.
func cores_visual(look: Dictionary = {}) -> Dictionary:
	var l := look if not look.is_empty() else visual_lutador()
	return disciples.cores(l) if not l.is_empty() else {}


## Quem a sala desenha de mentor agora (design 6c1 §4.1; garagem, e academia depois do marco da cena). Só com discípulo jogando.
## Cada item: {id "first"|"last", role "seat"|"stand", spot (nome do ponto), point [x, y], pose, glove, facing, campaign,
## name, look}. Com o John na escola: ele sentado (`seat`) e, se houver, o último que passou o posto em pé (`stand`).
## Depois da saída do John (marco da saída): só o último, sentado, e o `stand` vazio.
func mentores_na_sala() -> Array:
	var r: Array = []
	if lutador_atual() != "disciple":
		return r
	var pontos := _spots_do_local()
	if pontos.is_empty():
		return r
	var seat_p := ponto_do_local("seat")
	if mentor_sentado():
		r.append({"id": "first", "role": "seat", "spot": str(pontos.seat), "point": seat_p, "pose": "sit_rest", "glove": "none",
			"facing": "right", "campaign": int(escola.get("first_fighter_campaign", 1)), "name": str(dialogos.cast.get("first", {}).get("name", "John Bullet")),
			"look": {}})
		var s := segundo_mentor()
		if not s.is_empty():
			r.append({"id": "last", "role": "stand", "spot": s.ponto_nome, "point": s.ponto, "pose": s.pose, "glove": s.glove,
				"facing": s.facing, "campaign": s.campaign, "name": s.nome, "look": s.look})
	elif marco(_marco_da_saida()) and not seat_p.is_empty():
		var e := segundo_mentor_entrada()
		if not e.is_empty():
			var apos: Dictionary = disciples.mentores_cfg.get("after_first_leaves", {})
			var look = e.get("look", null)
			r.append({"id": "last", "role": "seat", "spot": str(pontos.seat), "point": seat_p, "pose": str(apos.get("pose", "sit_rest")),
				"glove": str(apos.get("glove", "none")), "facing": "right", "campaign": int(e.get("campaign", 0)), "name": str(e.get("name", "")),
				"look": disciples.validar_look(look) if look is Dictionary else disciples.look_padrao.duplicate()})
	return r


## Entrada do roster do segundo mentor (design 6b2 §4.1): a última `kind == "disciple"` com fim em `passed_ends`.
## {} se não há. Sem as condições de sala (para testes e para a 6c).
func segundo_mentor_entrada() -> Dictionary:
	var fins: Array = disciples.mentores_cfg.get("passed_ends", ["defeat", "retire", "unknown"])
	var lista: Array = escola.get("roster", [])
	for i in range(lista.size() - 1, -1, -1):
		var e = lista[i]
		if e is Dictionary and str(e.get("kind", "")) == "disciple" and str(e.get("end", "unknown")) in fins:
			return e.duplicate(true)
	return {}


## Consulta da UI: o segundo mentor em pé agora, ou {}. Vale nos dois locais (garagem; academia depois do marco da cena),
## só com o John sentado (requires_mentor). Escondido nas cenas de `hidden_during_scenes` (a grande da sucessão e a da academia).
## Devolve {nome, look (9 campos), ponto ([x, y] do manifest), pose, glove, facing ("right" | "left", virado para o saco),
## campaign, ponto_nome}. Sem alvo no clique, sem fala (design 6b2 §4.4).
func segundo_mentor() -> Dictionary:
	var cfg: Dictionary = disciples.mentores_cfg.get("second_mentor", {})
	if not bool(cfg.get("enabled", false)) or not mentor_sentado():
		return {}
	if not (str(cfg.get("requires_mentor", "first")) in escola.get("mentors", [])) or not (local_id in cfg.get("locations", ["garage"])):
		return {}
	var escondidas: Array = cfg.get("hidden_during_scenes", [])
	if sucessao != "none" and str(_handover().get("scene", "")) in escondidas:
		return {}
	if cena_sala != "" and cena_sala in escondidas:
		return {}
	var e := segundo_mentor_entrada()
	if e.is_empty():
		return {}
	var nome_ponto := str(_spots_do_local().get("stand", ""))
	var p := ponto_do_local("stand")
	if nome_ponto == "" or p.size() != 2:
		return {}
	var bag_x := float(cfg.get("bag_x", 320))
	var lado := "right" if float(p[0]) < bag_x else "left"
	var look = e.get("look", null)
	return {"nome": str(e.get("name", "")), "look": disciples.validar_look(look) if look is Dictionary else disciples.look_padrao.duplicate(),
		"ponto": [int(p[0]), int(p[1])], "ponto_nome": nome_ponto, "pose": str(cfg.get("pose", "stand_bare")),
		"glove": str(cfg.get("glove", "none")), "facing": lado, "campaign": int(e.get("campaign", 0))}


## O John está sentado no caixote do local atual (desenhado e com os toques valendo)? Só com discípulo jogando, o John na escola
## e o local com os pontos de mentor liberados (garagem; academia depois do marco da cena).
func mentor_sentado() -> bool:
	if lutador_atual() != "disciple" or not ("first" in escola.get("mentors", [])):
		return false
	return not _spots_do_local().is_empty() and not ponto_do_local("seat").is_empty()


## Lista da escola: quem passou o posto, em ordem (cópia). Ver design §3.4.
func escola_lista() -> Array:
	return escola.get("roster", []).duplicate(true)


func _discipulo_padrao() -> Dictionary:
	return {"name": disciples.nome_padrao, "look": disciples.look_padrao.duplicate(), "campaign": numero_carreira()}


## RECEBER NOVO DISCÍPULO (substitui a chamada da interface a nova_carreira()). Só com a tela de fim pendente.
## Zera a campanha (mesma conta de hoje) e segura o começo: cartão, escolha da arte e fala da derrota só saem em
## sucessao_terminou(). Primeira sucessão: grava o marco e os grants já aqui. No "começo do John" (save antigo,
## campanha nova == campanha do John) é a NOVA CAMPANHA de sempre, sem tela e sem cena.
func receber_discipulo() -> bool:
	if fim.is_empty() or sucessao != "none":
		return false
	_interromper_saida()  # 6c1: RECEBER termina a saída do John na hora
	var nova := numero_carreira() + 1
	if nova <= int(escola.get("first_fighter_campaign", 1)):
		return nova_carreira()
	_reiniciar_campanha()
	var ctx := {"milestones": escola.milestones, "campaign": nova, "campaigns_finished": int(permanente.get("careers_finished", 0)),
		"location": local_id, "calm": true}
	var cena_id := CenaDados.escolher_cena("handover_started", ctx)
	if cena_id == "":
		cena_id = str(disciples.passagem.get("short_scene", "chegada_discipulo"))
	var cena := CenaDados.carregar_cena(cena_id)
	var grande := str(cena.get("milestone", "")) != ""
	escola["handover"] = {"stage": "creating", "campaign": nova, "scene": cena_id,
		"draft": disciples.sortear(_rng_sucessao, escola.roster)}
	sucessao = "scene_1" if grande else "creating"
	sucessao_retomada = false
	_cena_grande_ativa = grande
	if grande:
		# O marco e o que ele dá são gravados no COMEÇO da cena: pular ou fechar o jogo dão o mesmo save.
		_gravar_marco(str(cena.milestone), {}, false)
		_aplicar_grants(cena.get("grants", []))
	salvar()
	_tempo_autosave = 0.0
	_emitir_tudo(false)
	permanente_mudou.emit()
	sucessao_mudou.emit(sucessao)
	rascunho_mudou.emit()
	return true


func _aplicar_grants(grants: Array) -> void:
	var mentores: Array = escola.mentors
	for g in grants:
		if not (g is Dictionary):
			continue
		var quem := "first" if str(g.get("character", "")).begins_with("first_fighter") else ""
		if quem == "":
			continue
		if str(g.get("type", "")) == "mentor_in_room" and not (quem in mentores):
			mentores.append(quem)
		elif str(g.get("type", "")) == "mentor_leaves":
			mentores.erase(quem)


## O player chegou no passo `open_screen` (cena grande): a tela de criação abre. scene_1 -> creating.
func sucessao_tela_aberta() -> void:
	if sucessao == "scene_1":
		sucessao = "creating"
		sucessao_mudou.emit(sucessao)


## Sorteia TUDO de novo no rascunho (botão SORTEAR). Só com a tela aberta.
func sortear_rascunho() -> bool:
	var h := _handover()
	if sucessao != "creating" or h.is_empty():
		return false
	h["draft"] = disciples.sortear(_rng_sucessao, escola.roster, str(h.get("draft", {}).get("name", "")))
	rascunho_mudou.emit()
	return true


## Troca um campo do rascunho: "name" (texto digitado; a interface já recusa o que a fonte não desenha) ou um campo do
## look (skin, hair_color, shorts_color... só opções ligadas). Não salva (vai no autosave).
func definir_rascunho(campo: String, valor: String) -> bool:
	var h := _handover()
	if sucessao != "creating" or h.is_empty() or not (h.get("draft", null) is Dictionary):
		return false
	var d: Dictionary = h.draft
	if campo == "name":
		d["name"] = disciples.filtrar_digitacao(valor)
	elif d.look.has(campo) and valor in disciples.opcoes_ativas(campo):
		d.look[campo] = valor
	else:
		return false
	rascunho_mudou.emit()
	return true


## CONFIRMAR. Nome vazio: o campo volta a um nome sorteado e não confirma (false). Senão grava o discípulo, o estado
## `arriving` no save, e a sucessão segue: scene_2 (a cena grande continua) ou arriving (chegada curta).
func confirmar_discipulo() -> bool:
	var h := _handover()
	if sucessao != "creating" or h.is_empty():
		return false
	var d: Dictionary = h.draft
	var nome := disciples.limpar_nome(str(d.get("name", "")))
	if nome == "":
		d["name"] = disciples.sortear_nome(_rng_sucessao, escola.roster)
		rascunho_mudou.emit()
		return false
	discipulo = {"name": nome, "look": disciples.validar_look(d.get("look", {})), "campaign": numero_carreira()}
	h["stage"] = "arriving"
	sucessao = "scene_2" if _cena_grande_ativa else "arriving"
	salvar()
	_tempo_autosave = 0.0
	carreira_mudou.emit()
	sucessao_mudou.emit(sucessao)
	return true


## A cena devolveu o controle (return_control) ou foi pulada: a campanha começa. Apaga o `handover`, salva e emite o
## começo (nova_carreira_iniciada, escolha_arte_pedida se pendente, gatilho after_defeat). O relógio anda a partir daqui.
func sucessao_terminou() -> bool:
	if sucessao != "scene_2" and sucessao != "arriving":
		return false
	var h := _handover()
	_reacao_cena = str(h.get("scene", "")) if _cena_grande_ativa else ""
	_cena_grande_ativa = false
	escola["handover"] = null
	sucessao = "none"
	sucessao_retomada = false
	salvar()
	_tempo_autosave = 0.0
	sucessao_mudou.emit("none")
	_checar_sala()
	_emitir_inicio_da_campanha()
	return true


# Depois de validar a escola: o que o save diz sobre uma sucessão em andamento.
func _aplicar_handover_da_carga() -> void:
	sucessao = "none"
	sucessao_retomada = false
	_cena_grande_ativa = false
	_reacao_cena = ""
	var h := _handover()
	if h.is_empty():
		return
	sucessao_retomada = true
	if str(h.stage) == "creating":
		sucessao = "creating"
		# A parte 1 não toca de novo: a cena grande vira a chegada curta (fecha na criação; ao confirmar, chegada).
		if str(CenaDados.carregar_cena(str(h.scene)).get("milestone", "")) != "":
			h["scene"] = str(disciples.passagem.get("short_scene", "chegada_discipulo"))
	else:
		sucessao = "arriving"
		var d: Dictionary = h.get("draft", {})
		discipulo = {"name": str(d.get("name", disciples.nome_padrao)), "look": d.get("look", {}), "campaign": numero_carreira()}


# career.disciple: {name, look, campaign}. Na campanha do John é {}. Faltando nas outras: o Novato padrão, com aviso
# (na tela de criação ainda não existe e não é erro).
func _validar_discipulo(v: Variant, havia_save: bool) -> Dictionary:
	if lutador_atual() == "first":
		return {}
	if sucessao == "creating":
		return {}
	if sucessao == "arriving" and not discipulo.is_empty():
		var nome_seguro := disciples.limpar_nome(str(discipulo.get("name", "")))
		return {"name": nome_seguro if nome_seguro != "" else disciples.nome_padrao,
			"look": disciples.validar_look(discipulo.get("look", {})), "campaign": numero_carreira()}
	if v is Dictionary:
		var nome := disciples.limpar_nome(str(v.get("name", "")))
		var avisos: Array = []
		var look := disciples.validar_look(v.get("look", null), avisos)
		if nome == "" or not avisos.is_empty():
			_avisar("Discípulo salvo com dados inválidos: campos trocados pelo padrão.")
		return {"name": nome if nome != "" else disciples.nome_padrao, "look": look,
			"campaign": maxi(1, _inteiro_valido(v.get("campaign", numero_carreira()), 1.0e9))}
	if havia_save:
		_avisar("Save sem o discípulo: o Novato padrão foi criado.")
	return _discipulo_padrao()


# Campos novos da escola (6b1): handover, mentors e roster. Ausente ou inválido: padrão (com aviso se havia save).
func _validar_escola_6b(s: Dictionary, r: Dictionary) -> void:
	var primeiro: int = int(r.first_fighter_campaign)
	var ms = s.get("mentors", [])
	if ms is Array:
		for m in ms:
			if str(m) == "first" and not ("first" in r.mentors):
				r.mentors.append("first")
	elif s.has("mentors"):
		_avisar("Mentores da escola inválidos: zerados.")
	var lista = s.get("roster", [])
	if lista is Array:
		for e in lista:
			var ok := _validar_entrada_da_lista(e)
			if not ok.is_empty():
				r.roster.append(ok)
	elif s.has("roster"):
		_avisar("Lista da escola inválida: zerada.")
	var h = s.get("handover", null)
	if h == null:
		return
	var camp := _inteiro_valido(h.get("campaign", 0), 1.0e9) if h is Dictionary else 0
	if not (h is Dictionary) or not (str(h.get("stage", "")) in ["creating", "arriving"]) or not fim.is_empty() \
			or camp != numero_carreira() or camp <= primeiro:
		_avisar("Sucessão salva inválida: descartada.")
		return
	var d = h.get("draft", {})
	var avisos: Array = []
	var nome: String = disciples.limpar_nome(str(d.get("name", ""))) if d is Dictionary else ""
	if nome == "":
		nome = disciples.sortear_nome(_rng_sucessao, r.roster)
	var cena_id := str(h.get("scene", ""))
	if CenaDados.carregar_cena(cena_id).is_empty():
		cena_id = str(disciples.passagem.get("short_scene", "chegada_discipulo"))
	r["handover"] = {"stage": str(h.stage), "campaign": camp, "scene": cena_id,
		"draft": {"name": nome, "look": disciples.validar_look(d.get("look", null) if d is Dictionary else null, avisos)}}


func _validar_entrada_da_lista(e: Variant) -> Dictionary:
	if not (e is Dictionary):
		return {}
	var tipo := str(e.get("kind", ""))
	if not (tipo in ["first", "disciple"]):
		return {}
	var fim_tipo := str(e.get("end", "unknown"))
	var olhar = e.get("look", null)
	var look_ok = null
	if tipo == "disciple":
		look_ok = disciples.validar_look(olhar) if olhar is Dictionary else disciples.look_padrao.duplicate()
	return {"campaign": maxi(1, _inteiro_valido(e.get("campaign", 1), 1.0e9)), "kind": tipo,
		"name": disciples.limpar_nome(str(e.get("name", ""))) if tipo == "disciple" else str(e.get("name", "")),
		"look": look_ok,
		"end": fim_tipo if fim_tipo in ["defeat", "retire", "unknown"] else "unknown",
		"wins": clampi(int(_numero_ou(e.get("wins", -1), -1.0)), -1, 1000000),
		"belt": typeof(e.get("belt", false)) == TYPE_BOOL and e.get("belt", false),
		"art": str(e.get("art", "")), "opponent": str(e.get("opponent", "")),
		"legacy_gained": _inteiro_valido(e.get("legacy_gained", 0), 1.0e15),
		"honor": _inteiro_valido(e.get("honor", 0), 1.0e15) if fim_tipo == "retire" else 0}


# Uma entrada na lista da escola para a campanha que acabou de encerrar (no mesmo salvar() do Legado).
func _registrar_na_lista_da_escola(tipo: String, snap: Dictionary, ganho: int, honra_ganha: int = 0) -> void:
	var primeiro := int(escola.get("first_fighter_campaign", 1))
	if numero_carreira() < primeiro:
		return  # campanhas de antes do John não entram
	var e_john := numero_carreira() == primeiro
	escola.roster.append({"campaign": numero_carreira(), "kind": "first" if e_john else "disciple", "name": nome_lutador(),
		"look": null if e_john else visual_lutador(), "end": tipo, "wins": indice_escada, "belt": cinturao, "art": arte_id,
		"opponent": str(snap.get("opponent", "")) if tipo == "defeat" else "", "legacy_gained": ganho,
		"honor": honra_ganha})


# 1º clique da campanha: grava mentor_greeted na hora e pede os toques (se o intervalo de 60 s deixar).
func _toques_do_primeiro_clique() -> void:
	if mentor_cumprimentou or lutador_atual() != "disciple":
		return
	mentor_cumprimentou = true
	if bool(disciples.toques.get("on_first_click", true)):
		_pedir_toques("first_click")
	_reacao_cena = ""


# Pede os dois toques sem luva do John. Devolve o plano (e emite toques_mentor_pedidos) ou {} se não vale:
# sem John sentado, sala parada, desligado nos dados ou dentro do intervalo (descartado, nunca guardado).
# Plano: {momento ("first_click"|"win_return"), version "short", start 0, duration, taps [t1, t2], tap_sound, anim, guard,
# cena (id da cena que cuida da animação: a interface NÃO repete os toques), com_fala}.
func _pedir_toques(momento: String) -> Dictionary:
	var cfg: Dictionary = disciples.toques
	if not bool(cfg.get("enabled", true)) or not mentor_sentado() or not sala_ativa():
		return {}
	if _t_real - _toque_ultimo < float(cfg.get("cooldown_seconds", 60.0)):
		return {}
	_toque_ultimo = _t_real
	var g: Dictionary = dialogos.gesture
	var primeiro := float(g.get("short_tap_at", 0.11))
	var duracao := float(g.get("short_seconds", 0.44))
	var guarda := float(cfg.get("first_click_guard_seconds", 0.5)) if momento == "first_click" else 0.0
	var cena := _reacao_cena if momento == "first_click" else ""
	var plano := {"momento": momento, "version": "short", "start": 0.0, "duration": duracao,
		"taps": [primeiro, primeiro + float(cfg.get("tap_interval", 0.22))],
		"tap_sound": str(cfg.get("sound", "tap_fist")), "anim": str(cfg.get("anim", "mentor_first_taps")),
		"guard": guarda, "cena": cena, "com_fala": cena != ""}
	_toques = {"momento": momento, "inicio": _t_real, "ate": _t_real + duracao, "guarda": guarda}
	toques_mentor_pedidos.emit(plano)
	return plano


# Cancela os toques. `forcar` ignora a guarda do 1º clique (janela, luta, mudança de local).
func _cancelar_toques(forcar: bool) -> void:
	if _toques.is_empty():
		return
	if not forcar and _t_real - float(_toques.inicio) < float(_toques.guarda):
		return
	_toques = {}
	toques_mentor_cancelados.emit()


func _toques_apos_vitoria(resumo: Dictionary) -> void:
	if bool(resumo.get("win", false)) and not resumo.has("retire") and mentor_sentado() \
			and bool(disciples.toques.get("enabled", true)) and bool(disciples.toques.get("on_win_return", true)):
		_toque_vitoria = 0.0


func _tick_toques(delta: float, ativa: bool) -> void:
	if not _toques.is_empty():
		if not _toques_valem_aqui() or not ativa:
			_cancelar_toques(true)
		elif _t_real >= float(_toques.ate):
			_toques = {}
	if _toque_vitoria >= 0.0:
		if not _toques_valem_aqui() or not luta.is_empty():
			_toque_vitoria = -1.0  # lutar de novo ou mudar de local cancela
		elif ativa:
			_toque_vitoria += delta
			if _toque_vitoria >= float(disciples.toques.get("win_return_delay_seconds", 1.0)):
				_toque_vitoria = -1.0
				_pedir_toques("win_return")


func _ler_json_dados(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var v = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return v if v is Dictionary else {}


func _marco_da_chegada() -> String:
	return str(escola_cfg.get("gym_arrival", {}).get("milestone", "cena_primeira_academia"))


func _marco_da_saida() -> String:
	return str(escola_cfg.get("mentor_leave", {}).get("milestone", "cena_saida_primeiro_mentor"))


## Id da cena de chegada se o MUDAR atual é a 1ª chegada à academia (marco ausente); "" nos outros casos.
func _cena_da_chegada() -> String:
	var cfg: Dictionary = escola_cfg.get("gym_arrival", {})
	if cfg.is_empty() or local_id != str(cfg.get("location", "gym")) or marco(_marco_da_chegada()):
		return ""
	return str(cfg.get("scene", "primeira_academia"))


## A cena da chegada terminou (return_control ou PULAR): devolve o relógio e abre a escolha da arte, se pendente.
func cena_sala_terminou() -> void:
	if cena_sala == "":
		return
	cena_sala = ""
	_cena_sala_t = 0.0
	_checar_sala()
	if escolha_arte_pendente():
		escolha_arte_pedida.emit(escolha_arte_primeira())


## Quem a chegada à academia usa (formato §9 item 16): {fighter "first"|"disciple", box "first"|"last_passed"|"neighbor",
## box_look (look do último, {} nos outros)}. A cena resolve os atores pelo papel; isto é para a interface e os testes.
func elenco_primeira_academia() -> Dictionary:
	var m := papel_do_elenco("mentor:seat")
	var caixa := "neighbor"
	if not m.is_empty():
		caixa = "first" if str(m.id) == "first" else "last_passed"
	return {"fighter": lutador_atual(), "box": caixa, "box_look": m.get("look", {}) if caixa == "last_passed" else {}}


# {id "first"|"last", character, look, name} de um dos papéis de cena; {} se ninguém ocupa o papel.
func papel_do_elenco(papel: String) -> Dictionary:
	if papel == "mentor:seat":
		for quem in escola_cfg.get("gym_arrival", {}).get("box_carrier_order", ["first", "last_passed"]):
			if str(quem) == "first" and lutador_atual() == "disciple" and "first" in escola.get("mentors", []):
				return _papel_john()
			if str(quem) == "last_passed" and marco(_marco_da_saida()):
				var u := _papel_ultimo()
				if not u.is_empty():
					return u
		return {}
	if papel == "mentor:last":
		return _papel_ultimo()
	return {}


func _papel_john() -> Dictionary:
	return {"id": "first", "character": "first_fighter", "look": {}, "name": str(dialogos.cast.get("first", {}).get("name", "John Bullet"))}


# O último que passou o posto (a entrada do roster), com o look validado.
func _papel_ultimo() -> Dictionary:
	var e := segundo_mentor_entrada()
	if e.is_empty():
		return {}
	var look = e.get("look", null)
	return {"id": "last", "character": "current_player", "name": str(e.get("name", "")),
		"look": disciples.validar_look(look) if look is Dictionary else disciples.look_padrao.duplicate()}


# {seat, stand} (nomes dos pontos) do local atual, ou {} se ali não há mentor desenhado (academia sem o marco da cena).
func _spots_do_local() -> Dictionary:
	var s = disciples.mentores_cfg.get("spots_by_location", {}).get(local_id, {})
	if not (s is Dictionary) or s.is_empty():
		return {}
	var req := str(s.get("requires_milestone", ""))
	if req != "" and not marco(req):
		return {}
	return {"seat": str(s.get("seat", "")), "stand": str(s.get("stand", ""))}


func _cena_dados_pontos() -> CenaDados:
	if _pontos_cena == null:
		_pontos_cena = CenaDados.novo()
	return _pontos_cena


## Ponto ([x, y]) do papel `seat` ou `stand` no local atual; [] se não há (manifest com reserva em data/cena_player.json).
func ponto_do_local(papel: String) -> Array:
	var p := _spots_do_local()
	if p.is_empty():
		return []
	return _cena_dados_pontos().ponto(str(p.get(papel, "")))


## {seat_spot, stand_spot, coach_spot} do local atual: o que a cena usa para `seat_spot` etc. (formato §9 item 22).
func pontos_do_local() -> Dictionary:
	return _cena_dados_pontos().pontos_do_local(local_id, disciples.mentores_cfg.get("spots_by_location", {}), escola_cfg.get("coach_presence", {}))


## Ponto onde o Osmar é desenhado no local atual ([] se não aparece ali).
func ponto_do_coach() -> Array:
	var c = escola_cfg.get("coach_presence", {}).get(local_id, null)
	if not (c is Dictionary):
		return []
	var req := str(c.get("requires_milestone", ""))
	if req != "" and not marco(req):
		return []
	return _cena_dados_pontos().ponto_caminho(str(c.get("spot", "")))


## O Osmar está desenhado no local atual? Só fala quem está desenhado (design §3.2). Garagem: sempre; academia: depois do marco.
func coach_presente() -> bool:
	if escola_cfg.is_empty():
		return local_id == "garage"
	return not ponto_do_coach().is_empty()


## A foto antiga do local atual: {spot [x, y], object_text (chave de objects), tilted} ou {} se não aparece (design §2).
func foto_antiga() -> Dictionary:
	var c = escola_cfg.get("old_photo", {}).get(local_id, null)
	if not (c is Dictionary):
		return {}
	var req := str(c.get("requires_milestone", ""))
	if req != "" and not marco(req):
		return {}
	var p := _cena_dados_pontos().ponto_caminho(str(c.get("spot", "")))
	if p.is_empty():
		return {}
	return {"spot": p, "object_text": str(c.get("object_text", "")), "tilted": bool(c.get("tilted", false))}


## O caixote de sentar está desenhado no local atual (com ou sem gente sentada)? Garagem: desde a 1ª sucessão. Academia: desde o marco.
func assento_visivel() -> bool:
	var c = disciples.mentores_cfg.get("seat_prop", {}).get(local_id, null)
	if not (c is Dictionary):
		return false
	var req := str(c.get("requires_milestone", ""))
	if req != "" and not marco(req):
		return false
	var s = disciples.mentores_cfg.get("spots_by_location", {}).get(local_id, {})
	return s is Dictionary and not _cena_dados_pontos().ponto(str(s.get("seat", ""))).is_empty()


## Quem a sala desenha num papel (`seat`, `stand`, `coach`): {id, point, facing, pose, look, name} ou {}.
## Durante a saída do John vale o que a sala desenhava ANTES dela (a cena assume o desenho).
func papel_da_sala(papel: String) -> Dictionary:
	if papel == "coach":
		var p := ponto_do_coach()
		if p.is_empty():
			return {}
		return {"id": "coach", "point": p, "facing": "right", "pose": "idle", "look": {}, "glove": "none",
			"name": str(dialogos.cast.get("coach", {}).get("name", "Osmar Brandão"))}
	var lista: Array = _saida_elenco.get("mentores", []) if _saida_tocando else mentores_na_sala()
	for m in lista:
		if str(m.get("role", "")) == papel:
			return m
	return {}


func _toques_valem_aqui() -> bool:
	return mentor_sentado() and local_id in disciples.toques.get("locations", ["garage"])


# 1ª vitória de um discípulo na academia com o John ainda na escola: arma a saída (no save do prêmio, sem salvar aqui).
func _marcar_vitoria_na_academia(oponente: String) -> void:
	var cfg: Dictionary = escola_cfg.get("mentor_leave", {})
	if cfg.is_empty() or lutador_atual() != "disciple" or local_id != str(cfg.get("win_location", "gym")):
		return
	if not ("first" in escola.get("mentors", [])):
		return
	_gravar_marco(str(cfg.get("win_milestone", "disciple_gym_win")), {"opponent": oponente}, false)


# Chamado só com sala ativa e arte escolhida: depois de `after_art_seconds` de arte, o gatilho art_choice sai uma vez.
func _tick_comentario_da_arte() -> void:
	if _arte_comentada:
		return
	var cfg: Dictionary = escola_cfg.get("art_comment", {})
	if cfg.is_empty():
		_arte_comentada = true
		return
	if arte_segundos >= float(cfg.get("after_art_seconds", 60.0)):
		_arte_comentada = true
		disparar_gatilho(str(cfg.get("trigger", "art_choice")))


## A saída do John está devida? (design §6.1) John na escola, discípulo jogando, saída ainda não feita e a
## 1ª vitória na academia OU a campanha de reserva (campanha do John + offset).
func saida_devida() -> bool:
	var cfg: Dictionary = escola_cfg.get("mentor_leave", {})
	if cfg.is_empty() or not ("first" in escola.get("mentors", [])) or lutador_atual() != "disciple" or marco(_marco_da_saida()):
		return false
	if marco(str(cfg.get("win_milestone", "disciple_gym_win"))):
		return true
	return numero_carreira() >= int(escola.get("first_fighter_campaign", 1)) + int(cfg.get("reserve_campaign_offset", 3))


## A saída do John está tocando agora.
func saida_tocando() -> bool:
	return _saida_tocando


# Roda a cada quadro com a sala calma: pede a saída no 1º momento calmo com o John desenhado (design §6.2).
func _tick_saida(ativa: bool) -> void:
	var cfg: Dictionary = escola_cfg.get("mentor_leave", {})
	if _saida_tocando:
		# Trava de segurança: se ninguém avisar o fim (sem interface), a saída acaba sozinha um pouco depois do teto.
		if _t_real - _saida_inicio > float(cfg.get("max_seconds", 14.0)) + 3.0:
			saida_terminou()
		return
	if not ativa or not saida_devida() or not _balao.is_empty() or not _gesto.is_empty() or not _toques.is_empty():
		return
	if _toque_vitoria >= 0.0 or _calma < float(cfg.get("settle_seconds", 2.0)) or not mentor_sentado():
		return
	_iniciar_saida()


func _iniciar_saida() -> void:
	var cfg: Dictionary = escola_cfg.mentor_leave
	var cena := CenaDados.carregar_cena(str(cfg.get("scene", "saida_primeiro_mentor")))
	_saida_elenco = {"mentores": mentores_na_sala()}  # o que a sala desenhava, antes de o John sair da lista
	# O marco e o que a cena dá são gravados no COMEÇO: fechar o jogo no meio dá o mesmo save.
	_gravar_marco(_marco_da_saida(), {}, false)
	_aplicar_grants(cena.get("grants", [{"type": "mentor_leaves", "character": "first_fighter"}]))
	_saida_tocando = true
	_saida_inicio = _t_real
	salvar()
	saida_mentor_pedida.emit()


## A saída acabou (a cena terminou ou foi interrompida): conta como comentário (intervalo de 60 s) e solta a vaga.
func saida_terminou() -> void:
	if not _saida_tocando:
		return
	_saida_tocando = false
	_saida_elenco = {}
	_ultimo_comentario = _t_real


# Janela, luta, MUDAR, tela de fim ou RECEBER: a cena aplica o end_state na hora e fecha os balões (sinal).
func _interromper_saida() -> void:
	if not _saida_tocando:
		return
	saida_mentor_interrompida.emit()
	saida_terminou()


## O CenaPlayer avisa que uma cena sem controle preso acabou sozinha.
func cena_livre_terminou(id: String) -> void:
	if id == str(escola_cfg.get("mentor_leave", {}).get("scene", "saida_primeiro_mentor")):
		saida_terminou()


# Campos novos da escola (v13): saldo, total e nós do hall. Inválido vira 0/vazio; saldo nunca passa do total.
func _validar_escola_6c2(s: Dictionary, r: Dictionary) -> void:
	r["honor"] = _inteiro_valido(s.get("honor", 0), 1.0e15)
	r["honor_total"] = maxi(_inteiro_valido(s.get("honor_total", 0), 1.0e15), int(r.honor))
	var lista = s.get("hall_nodes", [])
	if lista is Array:
		for x in lista:
			var id := str(x)
			if _no_do_hall(id).is_empty() or id in r.hall_nodes:
				_avisar("Nó do hall salvo inválido ou repetido (%s): ignorado." % id)
				continue
			r.hall_nodes.append(id)
	elif s.has("hall_nodes"):
		_avisar("Nós do hall inválidos: zerados.")


## Saldo de Honra (a moeda do hall; nunca compra Legado).
func honra() -> int:
	return int(escola.get("honor", 0))


## Honra ganha na vida inteira (nunca desce).
func honra_total() -> int:
	return int(escola.get("honor_total", 0))


## A fórmula (só dados): honra de uma saída voluntária com `wins` vitórias. Derrota nunca passa por aqui.
func honra_da_saida(wins: int, belt: bool) -> int:
	var h: Dictionary = hall_cfg.get("honor", {})
	if wins < int(h.get("min_wins", 1)):
		return 0
	var por: Array = h.get("per_win", [])
	var total := 0
	for i in wins:
		if por.is_empty():
			break
		total += int(por[mini(i, por.size() - 1)])
	if belt:
		total += int(h.get("belt_bonus", 0))
	return total


## Entradas do roster com selo (saíram por cima: honor > 0).
func retratos_com_selo() -> int:
	var n := 0
	for e in escola.get("roster", []):
		if int(e.get("honor", 0)) > 0:
			n += 1
	return n


## Quantos retratos contam: 5, ou 8 com o nó hall_wall.
func teto_retratos() -> int:
	return int(hall_cfg.get("portrait", {}).get("max_portraits", 5)) + int(_hall_valor("portrait_cap_plus"))


## Fator de TODO o treino (clique, Metrônomo, assistido e equipe): 1 + 2% por retrato com selo, até o teto.
func mult_escola() -> float:
	var por := float(hall_cfg.get("portrait", {}).get("per_portrait", 0.0))
	return 1.0 + por * float(mini(retratos_com_selo(), teto_retratos()))


func _no_do_hall(id: String) -> Dictionary:
	for n in hall_cfg.get("hall", {}).get("nodes", []):
		if str(n.get("id", "")) == id:
			return n
	return {}


## Soma dos valores dos nós do hall comprados com esse tipo de efeito.
func _hall_valor(tipo: String) -> float:
	var v := 0.0
	for id in escola.get("hall_nodes", []):
		var n := _no_do_hall(str(id))
		if not n.is_empty() and str(n.effect.type) == tipo:
			v += float(n.effect.value)
	return v


func tem_no_hall(id: String) -> bool:
	return id in escola.get("hall_nodes", [])


## Cliques para abrir uma caixa: o dado menos o nó hall_box (mínimo 1).
func cliques_para_abrir() -> int:
	return maxi(1, dados.box_clicks_to_open - int(_hall_valor("box_clicks_minus")))


## Lista fixa do hall: [{id, name, cost, effect_text, state "owned"|"buyable"|"missing"|"closed", missing}].
## "closed" = fora da tela de fim (só consulta); "missing" = faltam `missing` de Honra.
func hall_lista() -> Array:
	var r: Array = []
	for n in hall_cfg.get("hall", {}).get("nodes", []):
		var id := str(n.id)
		var custo := int(n.cost)
		var falta := maxi(0, custo - honra())
		var estado := "owned"
		if not tem_no_hall(id):
			estado = "closed" if fim.is_empty() else ("buyable" if falta == 0 else "missing")
		r.append({"id": id, "name": texto_ui("%s_name" % id, str(n.get("name", id))),
			"cost": custo, "effect_text": texto_ui("%s_desc" % id, str(n.get("effect_text", ""))),
			"state": estado, "missing": 0 if estado == "owned" else falta})
	return r


func pode_comprar_hall(id: String) -> bool:
	var n := _no_do_hall(id)
	return not n.is_empty() and not fim.is_empty() and not tem_no_hall(id) and honra() >= int(n.cost)


## Compra um nó: só com a tela de fim pendente, sem reembolso, desconta a Honra exata, um salvar() só.
func comprar_hall(id: String) -> bool:
	if not pode_comprar_hall(id):
		return false
	escola["honor"] = honra() - int(_no_do_hall(id).cost)
	escola["hall_nodes"].append(id)
	salvar()
	honra_mudou.emit(honra())
	hall_mudou.emit()
	return true


# Efeitos de começo de campanha (depois de zerar): Treino inicial e Luva de lona já aberta (sem caixa, sem gesto).
func _aplicar_inicio_do_hall() -> void:
	var t := _hall_valor("start_training")
	if t > 0.0:
		treino += t
	var g := int(_hall_valor("start_glove"))
	if g > 0:
		nivel_luva = clampi(maxi(nivel_luva, g), 0, lutas.luvas.size())
		for n in range(1, nivel_luva + 1):
			if not (n in gestos_calcados):
				gestos_calcados.append(n)


# Linha "FALTA ~N DE ATRIBUTO" da prévia (nó hall_notes). Calcula em segundo plano; "" até ficar pronta.
func _linha_o_que_falta(opp: Dictionary, jog: Array, adv: Array, rotulo: String) -> String:
	if not tem_no_hall("hall_notes") or rotulo == "easy" or rotulo == "":
		return ""
	var chave := "%s|%s|%s" % [str(opp.id), tatica, str(jog)]
	if str(_falta_cache.get("chave", "")) == chave:
		return str(_falta_cache.texto)
	_falta_chave_atual = chave
	if _falta_tarefa < 0:
		var tat := tatica
		var j := jog.duplicate()
		var a := adv.duplicate()
		_falta_fundo = {}
		_falta_tarefa = WorkerThreadPool.add_task(func() -> void: _falta_fundo = _calcular_falta(j, a, tat, chave))
	return ""


func _calcular_falta(jog: Array, adv: Array, tat: String, chave: String) -> Dictionary:
	# Mesmo atributo que a prévia realça em vermelho (`destaque`); sem realce, o do motivo da derrota.
	var atr := motor.destaque(jog, adv)
	var falta := -1.0
	if atr != "":
		falta = motor.falta_para(jog, adv, tat, Luta.ATRIBUTOS.find(atr))
	else:
		var m := motor.motivo(jog, adv, tat)
		atr = str(m.attribute)
		falta = float(m.faltaram)
	var texto := ""
	if falta >= 0.0:  # -1 = nem 16x o total basta: sem número, sem linha
		texto = preencher(texto_ui("preview_missing_line", "FALTA ~{n} DE {atributo}"),
			{"n": NumberFormat.fmt(Economia.teto3(falta)), "atributo": str(dados.atributo_info(atr).name).to_upper()})
	return {"chave": chave, "texto": texto}


## Recolhe a linha calculada em segundo plano. Com `esperar`, bloqueia até terminar.
func _finalizar_falta(esperar: bool) -> void:
	if _falta_tarefa < 0:
		return
	if not esperar and not WorkerThreadPool.is_task_completed(_falta_tarefa):
		return
	WorkerThreadPool.wait_for_task_completion(_falta_tarefa)
	_falta_tarefa = -1
	var pronto := _falta_fundo
	_falta_fundo = {}
	if pronto.is_empty():
		return
	_falta_cache = pronto
	if str(pronto.chave) == _falta_chave_atual:
		previa_falta_pronta.emit(str(pronto.texto))


## Espera a linha "o que mais falta" ficar pronta (testes e fechamento).
func aguardar_falta() -> void:
	_finalizar_falta(true)


## Dados da janela do mural. `entries` na ordem do roster (o John é a 1ª): {campaign, kind, name, look, art, wins, belt,
## end, end_key, end_text, opponent, opponent_name, sealed, honor, symbol, extra_key, career_text, wins_text, art_text}.
func mural() -> Dictionary:
	var cfg: Dictionary = escola_cfg.get("mural", {})
	var fins: Dictionary = cfg.get("end_texts", {})
	var itens: Array = []
	for e in escola.get("roster", []):
		var fim_tipo := str(e.get("end", "unknown"))
		var honra_e := int(e.get("honor", 0))
		var chave := str(fins.get("unknown", ""))
		if fim_tipo == "retire":
			chave = str(fins.get("retire_sealed", "")) if honra_e > 0 else str(fins.get("retire_plain", ""))
		elif fim_tipo == "defeat":
			chave = str(fins.get("defeat", ""))
		var oponente := str(e.get("opponent", ""))
		var nome_op := str(lutas.adversario(oponente).get("name", "")) if oponente != "" else ""
		var wins := int(e.get("wins", -1))
		var extra := ""
		if str(e.get("kind", "")) == "first" and marco(str(cfg.get("first_left_milestone", ""))):
			extra = str(cfg.get("first_left_text", ""))
		var arte := str(e.get("art", ""))
		var wins_texto := ""
		if wins < 0:
			wins_texto = texto_ui(str(cfg.get("wins_unknown_text", "mural_wins_unknown")), "?")
		elif wins == 1:
			wins_texto = texto_ui("mural_wins_one", "1 VITÓRIA")
		else:
			wins_texto = preencher(texto_ui("mural_wins", "{n} VITÓRIAS"), {"n": wins})
		itens.append({"campaign": int(e.campaign), "kind": str(e.kind), "name": str(e.name), "look": e.get("look", null),
			"art": arte, "wins": wins, "belt": bool(e.get("belt", false)), "end": fim_tipo, "end_key": chave,
			"end_text": preencher(texto_ui(chave), {"adversario": nome_op.to_upper()}) if (chave != str(fins.get("defeat", "")) or nome_op != "")
				else texto_ui("mural_end_defeat_unknown", "PAROU NUMA LUTA"),
			"opponent": oponente, "opponent_name": nome_op, "sealed": honra_e > 0, "honor": honra_e,
			"symbol": simbolo_na_entrada(e), "extra_key": extra,
			"career_text": preencher(texto_ui("mural_career", "CARREIRA {n}"), {"n": int(e.campaign)}),
			"wins_text": wins_texto,
			"art_text": nome_arte(arte).to_upper() if arte != "" else texto_ui("mural_art_none", "—")})
	var contam := mini(retratos_com_selo(), teto_retratos())
	var por := float(hall_cfg.get("portrait", {}).get("per_portrait", 0.0))
	var pct := int(round(100.0 * por * contam))
	return {"entries": itens, "honor": honra(), "sealed": retratos_com_selo(), "counted": contam, "cap": teto_retratos(),
		"bonus_pct": pct, "columns": int(cfg.get("columns", 5)), "rows_per_page": int(cfg.get("rows_per_page", 2)),
		"bonus_line": preencher(texto_ui("mural_bonus_line"), {"n": retratos_com_selo(), "c": contam, "cap": teto_retratos(), "pct": pct})}


## O mural na sala atual: {spot [x, y] ou [] (ponto ainda sem arte), spot_name, object_text (chave de objects)}; {} onde não aparece.
## Abre a qualquer hora em que a sala está ativa (a UI decide); nada vai para o save.
func mural_na_sala() -> Dictionary:
	var cfg: Dictionary = escola_cfg.get("mural", {})
	if cfg.is_empty() or not cfg.get("spot_by_location", {}).has(local_id):
		return {}
	var req := str(cfg.get("requires_milestone_by_location", {}).get(local_id, ""))
	if req != "" and not marco(req):
		return {}
	var nome := str(cfg.spot_by_location[local_id])
	return {"spot": _cena_dados_pontos().ponto_caminho(nome), "spot_name": nome, "object_text": str(cfg.get("object_text", "mural"))}


## Campanha do 1º cinturão amador da escola (o menor entre o marco da garagem salva, o roster e a campanha atual); 0 = nenhuma.
func campanha_do_simbolo() -> int:
	var cfg: Dictionary = escola_cfg.get("school_symbol", {})
	var melhor := 0
	var marco_id := str(cfg.get("from_milestone", "garage_saved"))
	if marco(marco_id):
		melhor = int(dados_marco(marco_id).get("campaign", 0))
	if bool(cfg.get("also_roster_belt", true)):
		for e in escola.get("roster", []):
			if bool(e.get("belt", false)) and (melhor <= 0 or int(e.campaign) < melhor):
				melhor = int(e.campaign)
	if cinturao and (melhor <= 0 or numero_carreira() < melhor):
		melhor = numero_carreira()
	return melhor


## O lutador atual usa o símbolo no peito? Discípulo (nunca o John) de campanha >= `campanha_do_simbolo()`.
func simbolo_no_lutador() -> bool:
	var c := campanha_do_simbolo()
	return lutador_atual() == "disciple" and c > 0 and numero_carreira() >= c


## Uma entrada do roster usa o símbolo? Vale para o mural e para o mentor sentado/em pé (use `campaign` do mentor).
func simbolo_na_entrada(e: Dictionary) -> bool:
	var c := campanha_do_simbolo()
	return str(e.get("kind", "")) == "disciple" and c > 0 and int(e.get("campaign", 0)) >= c


## O mentor sentado no caixote agora: {id "first"|"last", name, campaign, kind "first"|"disciple"} ou {}.
func mentor_do_caixote() -> Dictionary:
	for m in mentores_na_sala():
		if str(m.get("role", "")) == "seat":
			return {"id": str(m.id), "name": str(m.name), "campaign": int(m.campaign), "kind": "first" if str(m.id) == "first" else "disciple"}
	return {}


## Timbre do mentor para a voz: {base_hz, cps, vowel_order, vowel_steps}. O John usa a voz `first`; discípulo: escola.json.
func voz_do_mentor(kind: String, campanha: int) -> Dictionary:
	if kind == "first":
		return dialogos.voices.get("first", {}).duplicate()
	var v: Dictionary = escola_cfg.get("mentor_voice", {})
	var passos: Array = v.get("steps", [0])
	var hz := float(v.get("base_hz", 200)) + float(v.get("step_hz", 14)) * float(passos[campanha % maxi(1, passos.size())])
	return {"base_hz": hz, "cps": float(v.get("cps", 26)), "vowel_order": str(v.get("vowel_order", "uoaei")),
		"vowel_steps": v.get("vowel_steps", [0, 2, 4, 5, 7])}


## Maior número de vitórias de uma entrada do roster (wins -1 = desconhecido não conta).
func recorde_da_escola() -> int:
	var m := 0
	for e in escola.get("roster", []):
		m = maxi(m, int(e.get("wins", -1)))
	return m


func _entrada_da_campanha(campanha: int) -> Dictionary:
	for e in escola.get("roster", []):
		if int(e.campaign) == campanha:
			return e
	return {}


# O teto por grupo: já tocou alguma fala do grupo nesta campanha (lines_seen == campanha atual)?
func _grupo_de_fala_usado(grupo: String) -> bool:
	var caps: Dictionary = escola_cfg.get("mentor_lines", {}).get("caps", {})
	for l in dialogos.linhas:
		if str(l.trigger) != "mentor_won":
			continue
		var k := str(l.conditions.get("mentor_line", ""))
		if str(caps.get(k, k)) == grupo and int(escola.lines_seen.get(str(l.id), -1)) == numero_carreira():
			return true
	return false


# Vitória sobre `opp` (indice_escada já somado): qual fala o mentor do caixote pede? {} = nenhuma.
# Ordem revanche > recorde > mais longe que eu; no máximo uma. Devolve os params de mentor_won.
func _fala_do_mentor(opp: Dictionary) -> Dictionary:
	var cfg: Dictionary = escola_cfg.get("mentor_lines", {})
	var mentor := mentor_do_caixote()
	if cfg.is_empty() or mentor.is_empty() or dialogos.gatilho(str(cfg.get("trigger", "mentor_won"))).is_empty():
		return {}
	var minha := _entrada_da_campanha(int(mentor.campaign))
	var caps: Dictionary = cfg.get("caps", {})
	for k in cfg.get("order", []):
		var params := {"line": k, "mentor_line": k, "adversario": str(opp.name), "mentor": "", "own": false, "mentor_kind": mentor.kind}
		match str(k):
			"revanche":
				var achou := {}
				for e in escola.get("roster", []):
					if str(e.get("end", "")) == "defeat" and str(e.get("opponent", "")) == str(opp.id):
						if achou.is_empty() or (int(e.campaign) == int(mentor.campaign) and str(e.kind) == str(minha.get("kind", ""))):
							achou = e
				if achou.is_empty():
					continue
				params["mentor"] = str(achou.name)
				params["own"] = not minha.is_empty() and int(achou.campaign) == int(minha.campaign)
			"recorde":
				var rec := recorde_da_escola()
				if rec < int(cfg.get("record_min_wins", 1)) or indice_escada <= rec:
					continue
			"mais_longe":
				if minha.is_empty() or int(minha.get("wins", -1)) < 0 or indice_escada <= int(minha.wins):
					continue
			_:
				continue
		if _grupo_de_fala_usado(str(caps.get(k, k))):
			continue
		if dialogos.candidatas("mentor_won", _ctx_falas(params)).is_empty():
			continue  # sem fala escrita para este caso: não gasta a vitória nem cala o Osmar
		return params
	return {}


# ===== Repasses para scripts/estado/depuracao.gd =====
## Métrica de tempo morto da carreira: {atual, maximo, total} em segundos. Tempo morto = garagem livre, próximo
func tempo_morto() -> Dictionary: return _depur.tempo_morto()
## Menor preço da loja agora (próximo Prof. Nelson, próxima luva, próximo nível do Metrônomo), em dinheiro.
func menor_preco_loja() -> float: return _depur.menor_preco_loja()
## Veja depuracao.gd.
func debug_disponivel() -> bool: return _depur.debug_disponivel()
## Multiplica só o saldo (nunca os atributos).
func debug_multiplicar_saldo() -> void: _depur.debug_multiplicar_saldo()
## Soma unidades de cada gerador de graça.
func debug_somar_geradores() -> void: _depur.debug_somar_geradores()
