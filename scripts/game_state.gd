class_name EstadoJogo
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

# Fase 7a2 (Treino fora de hora): convite do seu Osmar, Choque e Panfletagem (contrato: docs/codigo/mapa.md)
signal convite_mudou(tipo: String)  # o balão do convite apareceu ("spar" | "flyers") ou sumiu/escondeu ("")
signal treino_fora_mudou(estado: String)  # o jogador foi para o minigame ("spar" | "flyers") ou voltou para a sala ("")
signal aquecido_mudou(ativo: bool)  # AQUECIDO guardado ou gasto (ícone perto do HUD da luta)

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
var passiva_carreira := 1  # 7b2: career.art_passive (1 = 1ª passiva da arte, 2 = a 2ª; vale a carreira inteira)
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

# Fase 7a2: treino fora de hora
var minigames: MinigamesData  # data/minigames.json (vazio = sem convites)
var convite: Dictionary = {}  # career.training_invite: {room_s, next_at, open, open_since, last, warm}
var treino_fora := ""  # "" | "spar" | "flyers": o jogador está no minigame (sala_ativa falso, só a equipe produz). Não vai para o save
var _treino_jogo = null  # ChoqueLogica | PanfletoLogica em andamento
var _treino_premio: Dictionary = {}
var _treino_fim_t := 0.0
var _convite_vis := ""
var _convite_local := ""
var _rng_treino := RandomNumberGenerator.new()  # próprio: o minigame nunca mexe nos sorteios do jogo

# Módulos (scripts/estado/): a lógica de cada assunto mora lá e trabalha nas variáveis acima.
const _Depuracao := preload("res://scripts/estado/depuracao.gd")
const _Textos := preload("res://scripts/estado/textos.gd")
const _HonraMural := preload("res://scripts/estado/honra_mural.gd")
const _CasaNova := preload("res://scripts/estado/casa_nova.gd")
const _Sucessao := preload("res://scripts/estado/sucessao.gd")
const _EscolaFalas := preload("res://scripts/estado/escola_falas.gd")
const _Aparelhos := preload("res://scripts/estado/aparelhos.gd")
const _Calendario := preload("res://scripts/estado/calendario.gd")
const _Arvore := preload("res://scripts/estado/arvore.gd")
const _AcademiaArtes := preload("res://scripts/estado/academia_artes.gd")
const _LojaGeradores := preload("res://scripts/estado/loja_geradores.gd")
const _Carreira := preload("res://scripts/estado/carreira.gd")
const _LutaEstado := preload("res://scripts/estado/luta.gd")
const _SaveValidacao := preload("res://scripts/estado/save_validacao.gd")
const _TreinoFora := preload("res://scripts/estado/treino_fora.gd")
var _treino := _TreinoFora.new(self)
var _depur := _Depuracao.new(self)
var _textos := _Textos.new(self)
var _honra := _HonraMural.new(self)
var _casa := _CasaNova.new(self)
var _sucessao := _Sucessao.new(self)
var _escola := _EscolaFalas.new(self)
var _aparelhos := _Aparelhos.new(self)
var _calendario := _Calendario.new(self)
var _arvore := _Arvore.new(self)
var _academia := _AcademiaArtes.new(self)
var _loja := _LojaGeradores.new(self)
var _carreira := _Carreira.new(self)
var _luta := _LutaEstado.new(self)
var _save := _SaveValidacao.new(self)


func _ready() -> void:
	rng.randomize()
	inicializar(_save._pasta_save_inicial(), CAMINHO_CONFIG)
	# Fechar pelo X passa por _notification, que salva antes de sair.
	get_tree().set_auto_accept_quit(false)


func _process(delta: float) -> void:
	tick(delta)
	_luta._finalizar_motivo(true, false)  # recolhe sem travar o quadro
	_honra._finalizar_falta(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		definir_assistido(false)  # perder o foco da janela = soltar o Shift
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_luta._finalizar_motivo(false)  # o save recalcula sob demanda se faltar
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
	escola_cfg = _casa._ler_json_dados("res://data/escola.json")
	hall_cfg = _casa._ler_json_dados("res://data/hall.json")
	_rng_sucessao.randomize()
	dialogos = dados_dialogos if dados_dialogos != null else DialogosData.carregar()
	_rng_fala.randomize()
	_escola._ligar_gatilhos_de_fala()
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
	minigames = MinigamesData.carregar()
	_rng_treino.randomize()
	_treino.zerar()
	store = SaveStore.new(pasta_save)
	_aparelhos._ajustar_assist()
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
		_luta._tick_risco(delta)
		# Fase 5.3: UMA condição (sala_ativa) liga relógio, equipe, Metrônomo, assistido, ouro e arte.
		# `dt` é o tempo de sala deste quadro (menor que delta se o relógio travou no dia da luta).
		var dt := _calendario._avancar_relogio(delta)
		_treino.tick(delta, dt)  # 7a2: relógio do convite (ou, no minigame, só a equipe produzindo)
		if dt > 0.0:
			var producao := producao_total()
			if producao > 0.0:
				_ganhar(producao * dt)
			if arte_id != "":
				arte_segundos += dt
				_casa._tick_comentario_da_arte()
			_depur._tick_tempo_morto(dt)
			_loja._tick_metronomo(dt)
			_loja._tick_evento_dourado(dt)
		_aparelhos._tick_assistido(dt)
		_calendario._verificar_calendario()
	_calendario._checar_sala()
	_escola._tick_falas(delta)
	_treino.atualizar_visivel()
	if autosave_ativo:
		_tempo_autosave += delta
		if _tempo_autosave >= config.autosave_intervalo_segundos:
			_tempo_autosave = 0.0
			salvar()


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


# Soma ganho ao saldo e ao atributo do foco.
func _ganhar(valor: float, aparelho_id: String = "") -> void:
	if is_nan(valor) or valor <= 0.0:
		return
	# Fase 5: o aparelho da arte divide o ganho nos 3 atributos (o saldo recebe o valor inteiro).
	# 7a2: `aparelho_id` vazio = o foco; o prêmio do Choque passa o aparelho da arte.
	var divisao := divisao_aparelho(foco if aparelho_id == "" else aparelho_id)
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


func _avisar(mensagem: String) -> void:
	if mensagem in avisos:
		return
	push_warning("GameState: " + mensagem)
	avisos.append(mensagem)
	avisos_mudaram.emit(avisos)


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

# ===== Repasses para scripts/estado/textos.gd =====
## Qualquer texto de data/ui_texts.json pela chave (padrão se faltar).
func texto_ui(chave: String, padrao: String = "") -> String: return _textos.texto_ui(chave, padrao)
## Texto do efeito de uma melhoria, ex.: "x3 POR CLIQUE: SACO".
func texto_efeito_melhoria(melhoria: Dictionary) -> String: return _textos.texto_efeito_melhoria(melhoria)
## "CLIQUE +123 (1 S DA EQUIPE)": o que o Grito da equipe soma agora em cada clique.
func texto_efeito_crew_click() -> String: return _textos.texto_efeito_crew_click()
## Textos prontos de um aparelho não montado (vazio se montado). Chaves: price (n TREINO), after (DEPOIS DA X),
func textos_trancado(aparelho_id: String) -> Dictionary: return _textos.textos_trancado(aparelho_id)
## Texto do efeito de uma luva ("x2 POR CLIQUE") ou de um gerador pago ("+25/S").
func texto_efeito_loja(item: Dictionary) -> String: return _textos.texto_efeito_loja(item)
## "1 SOCO A CADA 2.0 S" para um nível (ex.: proximo_metronomo()).
func texto_efeito_metronomo(nivel_def: Dictionary) -> String: return _textos.texto_efeito_metronomo(nivel_def)
## Texto "SE VENCER: $75 (+50%) + 15 FAMA (+50%)" com o bônus da árvore (sem "(+0%)").
func texto_stake_win(opp: Dictionary) -> String: return _textos.texto_stake_win(opp)
## Texto de "perder encerra a carreira": o padrão (50%) ou o percentual real com `career_good_loser`.
func texto_stake_lose() -> String: return _textos.texto_stake_lose()
## Texto do efeito com {pct} = round(100 x valor) e {n} = valor.
func texto_efeito_no(n: Dictionary) -> String: return _textos.texto_efeito_no(n)
## "ACADEMIA: TREINO x2" fora da garagem, "" na garagem.
func texto_hud_local() -> String: return _textos.texto_hud_local()
## "GUARDE $1.00K PARA A MUDANÇA" (ou a versão curta "GUARDE $1.00K"). A UI mostra no item recusado por "reserve".
func texto_reserva(curto: bool = false) -> String: return _textos.texto_reserva(curto)
## Subtítulo da janela: "AS DUAS ARTES FICAM LIBERADAS PARA SEMPRE" na 1ª vez, "CARREIRA n: ESCOLHA A ARTE" depois.
func subtitulo_escolha_arte() -> String: return _textos.subtitulo_escolha_arte()
## Texto do HUD da arte: "BOXE: +50% NO SEU CLIQUE", "JIU-JITSU: EQUIPE +48%" (ou "... (MÁX.)"). "" sem arte.
func texto_hud_arte() -> String: return _textos.texto_hud_arte()
## Texto da regra da arte para a janela de escolha: "+50% TREINO NO CLIQUE DA SUA MÃO", "EQUIPE +20% (SOBE 12% POR MINUTO ATÉ 100%)".
func texto_regra_arte(id: String) -> String: return _textos.texto_regra_arte(id)
## Nome antigo de texto_passiva (o traço +10%/-10% saiu na 7a1). "" sem arte.
func texto_traco_luta(id: String) -> String: return _textos.texto_passiva(id)
## Texto da passiva de luta da arte (cartão da janela de escolha). "" sem arte.
func texto_passiva(id: String, passiva: int = 1) -> String: return _textos.texto_passiva(id, passiva)
## Texto "FOR 40% / AGI 45% / RES 15%" do aparelho de arte ("" para os de toda carreira).
func texto_divisao(aparelho_id: String) -> String: return _textos.texto_divisao(aparelho_id)
## Bloco PRÓXIMA LUTA: {show, text, legacy, seconds}. `show` = o adversário da academia está PERIGOSO (na melhor das 3 táticas)
func dica_aposentar() -> Dictionary: return _textos.dica_aposentar()
## Lista de textos de uma chave de ui_texts.json (ex.: variações das dicas). [] se não for lista.
func lista_ui(chave: String) -> Array: return _textos.lista_ui(chave)
## Textos prontos (sentence case, a UI aplica to_upper) da tela de fim. Chaves:
func textos_fim(f: Dictionary = {}) -> Dictionary: return _textos.textos_fim(f)
## Texto do diálogo de confirmação de "Apagar save" (avisa se o save é de versão mais nova).
func texto_confirmar_apagar() -> String: return _textos.texto_confirmar_apagar()
## Texto do HUD no lugar de "Carreira N": só o nome, em maiúsculas.
func texto_hud_lutador() -> String: return _textos.texto_hud_lutador()

# ===== Repasses para scripts/estado/honra_mural.gd =====
## Saldo de Honra (a moeda do hall; nunca compra Legado).
func honra() -> int: return _honra.honra()
## Honra ganha na vida inteira (nunca desce).
func honra_total() -> int: return _honra.honra_total()
## A fórmula (só dados): honra de uma saída voluntária com `wins` vitórias. Derrota nunca passa por aqui.
func honra_da_saida(wins: int, belt: bool) -> int: return _honra.honra_da_saida(wins, belt)
## Entradas do roster com selo (saíram por cima: honor > 0).
func retratos_com_selo() -> int: return _honra.retratos_com_selo()
## Quantos retratos contam: 5, ou 8 com o nó hall_wall.
func teto_retratos() -> int: return _honra.teto_retratos()
## Fator de TODO o treino (clique, Metrônomo, assistido e equipe): 1 + 2% por retrato com selo, até o teto.
func mult_escola() -> float: return _honra.mult_escola()
## Veja honra_mural.gd.
func tem_no_hall(id: String) -> bool: return _honra.tem_no_hall(id)
## Cliques para abrir uma caixa: o dado menos o nó hall_box (mínimo 1).
func cliques_para_abrir() -> int: return _honra.cliques_para_abrir()
## Lista fixa do hall: [{id, name, cost, effect_text, state "owned"|"buyable"|"missing"|"closed", missing}].
func hall_lista() -> Array: return _honra.hall_lista()
## Veja honra_mural.gd.
func pode_comprar_hall(id: String) -> bool: return _honra.pode_comprar_hall(id)
## Compra um nó: só com a tela de fim pendente, sem reembolso, desconta a Honra exata, um salvar() só.
func comprar_hall(id: String) -> bool: return _honra.comprar_hall(id)
## Espera a linha "o que mais falta" ficar pronta (testes e fechamento).
func aguardar_falta() -> void: _honra.aguardar_falta()
## Dados da janela do mural. `entries` na ordem do roster (o John é a 1ª): {campaign, kind, name, look, art, wins, belt,
func mural() -> Dictionary: return _honra.mural()
## O mural na sala atual: {spot [x, y] ou [] (ponto ainda sem arte), spot_name, object_text (chave de objects)}; {} onde não aparece.
func mural_na_sala() -> Dictionary: return _honra.mural_na_sala()
## Campanha do 1º cinturão amador da escola (o menor entre o marco da garagem salva, o roster e a campanha atual); 0 = nenhuma.
func campanha_do_simbolo() -> int: return _honra.campanha_do_simbolo()
## O lutador atual usa o símbolo no peito? Discípulo (nunca o John) de campanha >= `campanha_do_simbolo()`.
func simbolo_no_lutador() -> bool: return _honra.simbolo_no_lutador()
## Uma entrada do roster usa o símbolo? Vale para o mural e para o mentor sentado/em pé (use `campaign` do mentor).
func simbolo_na_entrada(e: Dictionary) -> bool: return _honra.simbolo_na_entrada(e)
## O mentor sentado no caixote agora: {id "first"|"last", name, campaign, kind "first"|"disciple"} ou {}.
func mentor_do_caixote() -> Dictionary: return _honra.mentor_do_caixote()
## Timbre do mentor para a voz: {base_hz, cps, vowel_order, vowel_steps}. O John usa a voz `first`; discípulo: escola.json.
func voz_do_mentor(kind: String, campanha: int) -> Dictionary: return _honra.voz_do_mentor(kind, campanha)
## Maior número de vitórias de uma entrada do roster (wins -1 = desconhecido não conta).
func recorde_da_escola() -> int: return _honra.recorde_da_escola()

# ===== Repasses para scripts/estado/casa_nova.gd =====
## A cena da chegada terminou (return_control ou PULAR): devolve o relógio e abre a escolha da arte, se pendente.
func cena_sala_terminou() -> void: _casa.cena_sala_terminou()
## Quem a chegada à academia usa (formato §9 item 16): {fighter "first"|"disciple", box "first"|"last_passed"|"neighbor",
func elenco_primeira_academia() -> Dictionary: return _casa.elenco_primeira_academia()
## {id "first"|"last", character, look, name} de um dos papéis de cena; {} se ninguém ocupa o papel.
func papel_do_elenco(papel: String) -> Dictionary: return _casa.papel_do_elenco(papel)
## Ponto ([x, y]) do papel `seat` ou `stand` no local atual; [] se não há (manifest com reserva em data/cena_player.json).
func ponto_do_local(papel: String) -> Array: return _casa.ponto_do_local(papel)
## {seat_spot, stand_spot, coach_spot} do local atual: o que a cena usa para `seat_spot` etc. (formato §9 item 22).
func pontos_do_local() -> Dictionary: return _casa.pontos_do_local()
## Ponto onde o Osmar é desenhado no local atual ([] se não aparece ali).
func ponto_do_coach() -> Array: return _casa.ponto_do_coach()
## O Osmar está desenhado no local atual? Só fala quem está desenhado (design §3.2). Garagem: sempre; academia: depois do marco.
func coach_presente() -> bool: return _casa.coach_presente()
## A foto antiga do local atual: {spot [x, y], object_text (chave de objects), tilted} ou {} se não aparece (design §2).
func foto_antiga() -> Dictionary: return _casa.foto_antiga()
## O caixote de sentar está desenhado no local atual (com ou sem gente sentada)? Garagem: desde a 1ª sucessão. Academia: desde o marco.
func assento_visivel() -> bool: return _casa.assento_visivel()
## Quem a sala desenha num papel (`seat`, `stand`, `coach`): {id, point, facing, pose, look, name} ou {}.
func papel_da_sala(papel: String) -> Dictionary: return _casa.papel_da_sala(papel)
## A saída do John está devida? (design §6.1) John na escola, discípulo jogando, saída ainda não feita e a
func saida_devida() -> bool: return _casa.saida_devida()
## A saída do John está tocando agora.
func saida_tocando() -> bool: return _casa.saida_tocando()
## A saída acabou (a cena terminou ou foi interrompida): conta como comentário (intervalo de 60 s) e solta a vaga.
func saida_terminou() -> void: _casa.saida_terminou()
## Janela, luta, MUDAR, tela de fim ou RECEBER: a cena aplica o end_state na hora e fecha os balões (sinal).
func _interromper_saida() -> void: _casa._interromper_saida()
## O CenaPlayer avisa que uma cena sem controle preso acabou sozinha.
func cena_livre_terminou(id: String) -> void: _casa.cena_livre_terminou(id)

# ===== Repasses para scripts/estado/sucessao.gd =====
## "none" | "scene_1" | "creating" | "scene_2" | "arriving". Fora de "none" a carreira está congelada.
func sucessao_estado() -> String: return _sucessao.sucessao_estado()
## Id da cena que a sucessão toca agora ("primeira_sucessao" ou "chegada_discipulo"); "" fora da sucessão.
func sucessao_cena() -> String: return _sucessao.sucessao_cena()
## Rascunho da tela de criação: {name, look}. {} fora da criação.
func rascunho() -> Dictionary: return _sucessao.rascunho()
## Linhas da tela de criação (6b2) com o rascunho atual: ver DiscipulosData.linhas_tela(). `apagada` = cor da peça em "sem".
func linhas_tela_criacao() -> Array: return _sucessao.linhas_tela_criacao()
## Nome sem espaços nas pontas e sem repetidos, só com as letras que a fonte desenha ("" se não sobrar nenhuma).
func limpar_nome(texto: String) -> String: return _sucessao.limpar_nome(texto)
## O discípulo da campanha: {name, look, campaign}. {} na campanha do John.
func discipulo_atual() -> Dictionary: return _sucessao.discipulo_atual()
## Nome de quem está lutando: "John Bullet" ou o nome do discípulo. A interface aplica `.to_upper()`.
func nome_lutador() -> String: return _sucessao.nome_lutador()
## Título do resumo de fim de campanha: "RESUMO DE {NOME}".
func titulo_resumo() -> String: return _sucessao.titulo_resumo()
## Visual do lutador atual (9 campos). {} no John (ele usa as folhas dele).
func visual_lutador() -> Dictionary: return _sucessao.visual_lutador()
## Cores de um visual (padrão: o do lutador atual): {campo: {id, slots, colors (hex), tokens}}. O John devolve {}.
func cores_visual(look: Dictionary = {}) -> Dictionary: return _sucessao.cores_visual(look)
## Quem a sala desenha de mentor agora (design 6c1 §4.1; garagem, e academia depois do marco da cena). Só com discípulo jogando.
func mentores_na_sala() -> Array: return _sucessao.mentores_na_sala()
## Entrada do roster do segundo mentor (design 6b2 §4.1): a última `kind == "disciple"` com fim em `passed_ends`.
func segundo_mentor_entrada() -> Dictionary: return _sucessao.segundo_mentor_entrada()
## Consulta da UI: o segundo mentor em pé agora, ou {}. Vale nos dois locais (garagem; academia depois do marco da cena),
func segundo_mentor() -> Dictionary: return _sucessao.segundo_mentor()
## O John está sentado no caixote do local atual (desenhado e com os toques valendo)? Só com discípulo jogando, o John na escola
func mentor_sentado() -> bool: return _sucessao.mentor_sentado()
## Lista da escola: quem passou o posto, em ordem (cópia). Ver design §3.4.
func escola_lista() -> Array: return _sucessao.escola_lista()
## RECEBER NOVO DISCÍPULO (substitui a chamada da interface a nova_carreira()). Só com a tela de fim pendente.
func receber_discipulo() -> bool: return _sucessao.receber_discipulo()
## O player chegou no passo `open_screen` (cena grande): a tela de criação abre. scene_1 -> creating.
func sucessao_tela_aberta() -> void: _sucessao.sucessao_tela_aberta()
## Sorteia TUDO de novo no rascunho (botão SORTEAR). Só com a tela aberta.
func sortear_rascunho() -> bool: return _sucessao.sortear_rascunho()
## Troca um campo do rascunho: "name" (texto digitado; a interface já recusa o que a fonte não desenha) ou um campo do
func definir_rascunho(campo: String, valor: String) -> bool: return _sucessao.definir_rascunho(campo, valor)
## CONFIRMAR. Nome vazio: o campo volta a um nome sorteado e não confirma (false). Senão grava o discípulo, o estado
func confirmar_discipulo() -> bool: return _sucessao.confirmar_discipulo()
## A cena devolveu o controle (return_control) ou foi pulada: a campanha começa. Apaga o `handover`, salva e emite o
func sucessao_terminou() -> bool: return _sucessao.sucessao_terminou()
## Pede os dois toques sem luva do John. Devolve o plano (e emite toques_mentor_pedidos) ou {} se não vale:
func _pedir_toques(momento: String) -> Dictionary: return _sucessao._pedir_toques(momento)
## Veja sucessao.gd.
func _toques_apos_vitoria(resumo: Dictionary) -> void: _sucessao._toques_apos_vitoria(resumo)

# ===== Repasses para scripts/estado/escola_falas.gd =====
## Quem está jogando: "first" (John Bullet, a campanha dele) ou "disciple" (discípulo padrão, das seguintes).
func lutador_atual() -> String: return _escola.lutador_atual()
## true se o marco da escola já foi gravado (prologue_seen, first_school_win, garage_saved, garage_saved_seen...).
func marco(id: String) -> bool: return _escola.marco(id)
## Dados do marco ({campaign, version, ...}); {} se não existe.
func dados_marco(id: String) -> Dictionary: return _escola.dados_marco(id)
## "pending" (ainda não tocou), "playing" ou "over".
func abertura_estado() -> String: return _escola.abertura_estado()
## Segundos de sala ativa sem clique (zera no clique; começa em 0 ao abrir o jogo). Não conta janela nem luta.
func segundos_ocioso() -> float: return _escola.segundos_ocioso()
## true com balão na tela (comentário ou abertura).
func tem_balao() -> bool: return _escola.tem_balao()
## Descrição da luva inicial: "o par do John" no 1º lutador, a descrição padrão nos outros.
func descricao_luva_inicial() -> String: return _escola.descricao_luva_inicial()
## Grava um marco (id desconhecido também). false se já existia. `salvar_agora`: false quando quem chama salva em seguida.
func _gravar_marco(id: String, extra: Dictionary = {}, salvar_agora: bool = true) -> bool: return _escola._gravar_marco(id, extra, salvar_agora)
## Pula a abertura (ESC segurado 0,5 s): mesmo estado final de terminar. Em "pending" só grava o marco.
func pular_abertura() -> void: _escola.pular_abertura()
## Um gatilho de comentário chegou (id de data/dialogos.json > triggers). Resolvido no próximo tick: se a sala não
func disparar_gatilho(id: String, params: Dictionary = {}) -> void: _escola.disparar_gatilho(id, params)
## A UI avisa que o balão sumiu (leitura acabou). Sem isso o jogo libera sozinho depois do tempo previsto.
func fala_terminada(id: String) -> void: _escola.fala_terminada(id)
## A UI não conseguiu mostrar o balão pedido por `fala_pedida`: a fala não conta como vista (a única fica pendente).
func fala_recusada(id: String) -> void: _escola.fala_recusada(id)
## Pede o gesto. `momento`: "opening", "fight_intro", "victory", "glove" (com `nivel`) ou "idle". Devolve o plano
func pedir_gesto(momento: String, nivel: int = -1) -> Dictionary: return _escola.pedir_gesto(momento, nivel)
## Qualquer clique do jogador (saco, botão, fora do alvo): cancela o gesto e zera a "sala parada".
func registrar_clique() -> void: _escola.registrar_clique()
## Veja escola_falas.gd.
func cancelar_gesto() -> void: _escola.cancelar_gesto()
## Zera o que é só de sessão (balão, vaga, intervalo, gesto) e decide o estado da abertura. Carga e "Apagar save".
func _reiniciar_falas() -> void: _escola._reiniciar_falas()

# ===== Repasses para scripts/estado/aparelhos.gd =====
## Veja aparelhos.gd.
func aparelho_montado(aparelho_id: String) -> bool: return _aparelhos.aparelho_montado(aparelho_id)
## Fase 5: aparelhos que existem nesta carreira, na ordem de `dados`: os de toda carreira e o da arte escolhida (se houver).
func aparelhos_da_carreira() -> Array: return _aparelhos.aparelhos_da_carreira()
## true se o aparelho existe nesta carreira (os de arte só existem na carreira da arte dele).
func aparelho_existe(aparelho_id: String) -> bool: return _aparelhos.aparelho_existe(aparelho_id)
## Ids dos aparelhos montados, na ordem da compra.
func aparelhos_montados() -> Array: return _aparelhos.aparelhos_montados()
## {id, cost, requires, name, description, arrives_as} ou {} se o aparelho já vem montado.
func desbloqueio(aparelho_id: String) -> Dictionary: return _aparelhos.desbloqueio(aparelho_id)
## Nome curto para frases ("ESTEIRA"): o unlock.name, ou o nome do aparelho.
func nome_curto_aparelho(aparelho_id: String) -> String: return _aparelhos.nome_curto_aparelho(aparelho_id)
## "owned" | "boxed" (comprado, na caixa) | "buyable" | "missing" | "locked" (inexistente = "locked") | "absent" (aparelho de outra arte: não existe aqui).
func estado_aparelho(aparelho_id: String) -> String: return _aparelhos.estado_aparelho(aparelho_id)
## Veja aparelhos.gd.
func pode_comprar_aparelho(aparelho_id: String) -> bool: return _aparelhos.pode_comprar_aparelho(aparelho_id)
## Compra o aparelho com Treino: foco vai para ele e salva na hora.
func comprar_aparelho(aparelho_id: String) -> bool: return _aparelhos.comprar_aparelho(aparelho_id)
## Monta o aparelho e (se `focus_on_open`) leva o foco para ele. Não salva nem emite sinais.
func _montar_aparelho(aparelho_id: String) -> void: _aparelhos._montar_aparelho(aparelho_id)
## Chamado pela UI: true enquanto o Shift (ou o botão SEGURAR) estiver pressionado, false ao soltar
func definir_assistido(segurando: bool) -> void: _aparelhos.definir_assistido(segurando)
## true se o Shift/botão está pressionado (mesmo sem efeito agora).
func assistido_segurando() -> bool: return _aparelhos.assistido_segurando()
## "off" | "waiting" (segurando, mão ainda mexendo) | "active" (socando) | "metronome" (Metrônomo >= 1: assistido some).
func assistido_estado() -> String: return _aparelhos.assistido_estado()
## Veja aparelhos.gd.
func assistido_disponivel() -> bool: return _aparelhos.assistido_disponivel()
## Segundos entre auto-socos do assistido (já validado contra o Metrônomo 1).
func assistido_intervalo() -> float: return _aparelhos.assistido_intervalo()
## Caixas fechadas, na ordem da compra: [{item, kind, hits}]. Cópia (mexer nela não muda o jogo).
func caixas() -> Array: return _aparelhos.caixas()
## true se o item (id de aparelho ou de luva) está numa caixa fechada.
func tem_caixa(item: String) -> bool: return _aparelhos.tem_caixa(item)
## A caixa do item ({item, kind, hits}) ou {} se não há.
func caixa(item: String) -> Dictionary: return _aparelhos.caixa(item)
## Cliques que ainda faltam para abrir a caixa do item (0 se não há caixa).
func cliques_faltando(item: String) -> int: return _aparelhos.cliques_faltando(item)
## true se há uma luva esperando na caixa (a próxima só fica à venda depois de abrir).
func luva_em_caixa() -> bool: return _aparelhos.luva_em_caixa()
## Luvas que já valem (abertas): glove_level menos a que está na caixa.
func luvas_abertas() -> int: return _aparelhos.luvas_abertas()
## Um clique na caixa (só o mouse; Espaço nunca chama isto). Soma 1 batida; na última abre.
func bater_caixa(item: String) -> bool: return _aparelhos.bater_caixa(item)
## Abre a caixa já (o 3º clique chama isto; público para testes). Aplica o item, foca (aparelho) e salva.
func abrir_caixa(item: String) -> bool: return _aparelhos.abrir_caixa(item)
## Veja aparelhos.gd.
func _criar_caixa(item: String, tipo: String) -> void: _aparelhos._criar_caixa(item, tipo)
## Aparelho que treina o atributo decisivo da derrota, se não estiver montado ("" se montado ou sorte).
func _aparelho_da_dica(motivo: Dictionary) -> String: return _aparelhos._aparelho_da_dica(motivo)

# ===== Repasses para scripts/estado/calendario.gd =====
## A ÚNICA condição de tick: relógio da campanha, equipe, Metrônomo, assistido, clique, luva dourada e Jiu-jitsu
func sala_ativa() -> bool: return _calendario.sala_ativa()
## Veja calendario.gd.
func calendario_ligado() -> bool: return _calendario.calendario_ligado()
## Veja calendario.gd.
func _segundos_por_dia() -> float: return _calendario._segundos_por_dia()
## Dia da campanha (começa em 1). Sem calendário: sempre 1.
func dia_campanha() -> int: return _calendario.dia_campanha()
## Depois do último adversário (Kid): "Campanha completa", sem data nem relógio.
func campanha_completa() -> bool: return _calendario.campanha_completa()
## Dias que faltam para a próxima luta (0 = é hoje); -1 sem calendário ou sem próxima luta.
func dias_para_luta() -> int: return _calendario.dias_para_luta()
## true quando o relógio chegou na data da próxima luta (e o adversário luta neste local).
func no_dia_da_luta() -> bool: return _calendario.no_dia_da_luta()
## Veja calendario.gd.
func _alvo_relogio() -> float: return _calendario._alvo_relogio()
## Data da próxima luta contada a partir do dia de hoje (-1 se a escada acabou).
func _data_da_proxima_luta() -> int: return _calendario._data_da_proxima_luta()

# ===== Repasses para scripts/estado/arvore.gd =====
## Soma, por tipo, dos efeitos dos nós ATIVOS da campanha (aditivo dentro do tipo; ver design §3.5).
func _recalcular_bonus() -> void: _arvore._recalcular_bonus()
## Bônus (por tipo de efeito) de uma lista de ids de nós. Tipos: somas (click, passive, money, fame, defeat_share,
func bonus_de(ids: Array, arte: String = "*") -> Dictionary: return _arvore.bonus_de(ids, arte)
## Veja arvore.gd.
func _b(tipo: String) -> float: return _arvore._b(tipo)
## Bônus ativos da carreira em andamento (cópia, para a UI e os testes).
func bonus_ativos() -> Dictionary: return _arvore.bonus_ativos()
## Veja arvore.gd.
func nos_comprados() -> Array: return _arvore.nos_comprados()
## Veja arvore.gd.
func tem_no(id: String) -> bool: return _arvore.tem_no(id)
## Veja arvore.gd.
func legado_disponivel() -> int: return _arvore.legado_disponivel()
## Estado de um nó para a tela ANTIGA (abas): "owned", "buyable", "missing" (falta Legado) ou "locked" (escondido no mapa).
func estado_no(id: String) -> String: return _arvore.estado_no(id)
## Fase 5.4: estado de um nó no mapa: "owned" (comprado), "visible" (à vista: raiz ou vizinho de comprado, trava aberta)
func estado_mapa(id: String) -> String: return _arvore.estado_mapa(id)
## Trava de região/nó: "" sempre; "gym" com alguma arte liberada (um discípulo já chegou à academia); "art:<id>" com a arte liberada.
func trava_aberta(trava: String) -> bool: return _arvore.trava_aberta(trava)
## Lista de nós na ordem do arquivo. Cada item: {id, branch, branch_name, requires, requires_name, cost, name,
func arvore_ramos() -> Array: return _arvore.arvore_ramos()
## Veja arvore.gd.
func arvore_nos() -> Array: return _arvore.arvore_nos()
## Fase 5.4: a árvore abre em qualquer momento, menos na luta, no dia da luta, na escolha da arte e com caixa
func pode_abrir_arvore() -> bool: return _arvore.pode_abrir_arvore()
## Compat: "a árvore está aberta" (mesma regra de `pode_abrir_arvore`).
func arvore_aberta() -> bool: return _arvore.arvore_aberta()
## À vista, com Legado para pagar e mapa aberto.
func pode_comprar_no(id: String) -> bool: return _arvore.pode_comprar_no(id)
## Igual a `pode_comprar_no`, sem olhar se o mapa está aberto (o brilho do botão usa isto).
func pode_pagar_no(id: String) -> bool: return _arvore.pode_pagar_no(id)
## true se existe nó à vista que o Legado paga: o botão da sala brilha (mesmo com o mapa fechado).
func ha_no_compravel() -> bool: return _arvore.ha_no_compravel()
## Quantos nós à vista o Legado paga agora ("{n} NÓS PARA COMPRAR").
func nos_compraveis() -> int: return _arvore.nos_compraveis()
## Compra o nó: desconta o Legado exato, grava o nó e salva (um save só). Recusa (nada muda) com o mapa fechado,
func comprar_no(id: String) -> bool: return _arvore.comprar_no(id)
## Nós que valem na campanha atual (a foto de `career.active_nodes`).
func nos_ativos() -> Array: return _arvore.nos_ativos()
## Mapa inteiro para a UI (o `docs/fases/fase5.4-api.md` descreve cada chave). A UI desenha só o que não é "hidden".
func arvore_mapa() -> Array: return _arvore.arvore_mapa()
## Dados gerais do mapa: {unit_px, regions: [{id, name, icon, lock, open}], last_node, legacy, open, can_buy_count}.
func arvore_mapa_info() -> Dictionary: return _arvore.arvore_mapa_info()

# ===== Repasses para scripts/estado/academia_artes.gd =====
## Multiplicador global de treino do local atual (garagem 1,0; academia 2,0), lido de data/locations.json.
func mult_local() -> float: return _academia.mult_local()
## Local atual: {id, name, ambience, training_mult, apparatus_suffix, ...}. O sufixo vai nos sprites dos aparelhos básicos.
func local_atual() -> Dictionary: return _academia.local_atual()
## Veja academia_artes.gd.
func sufixo_aparelhos() -> String: return _academia.sufixo_aparelhos()
## true se o treino está multiplicado por causa do local (a UI mostra `texto_hud_local()`).
func em_academia() -> bool: return _academia.em_academia()
## Dados do botão MUDAR ({} se não há para onde mudar: já está lá). Chaves: id, location, cost, name, mult, button,
func mudanca() -> Dictionary: return _academia.mudanca()
## "none" (nada a comprar), "locked" (falta o cinturão: o botão não existe), "missing" (cinturão sem o dinheiro: apagado) ou "ready".
func estado_mudanca() -> String: return _academia.estado_mudanca()
## Veja academia_artes.gd.
func pode_mudar() -> bool: return _academia.pode_mudar()
## MUDAR: desconta o preço uma vez, vai para o local, e na 1ª vez libera todas as artes e pede a escolha. Salva na hora.
func mudar() -> bool: return _academia.mudar()
## Dinheiro que a LOJA não pode gastar: o preço da mudança, entre o cinturão e a mudança (0 nos outros casos).
func reserva_mudanca() -> float: return _academia.reserva_mudanca()
## Estado de uma compra em dinheiro: "ok", "money" (falta dinheiro) ou "reserve" (deixaria menos que a reserva da mudança).
func loja_estado(custo: float) -> String: return _academia.loja_estado(custo)
## Artes liberadas para sempre (ids), na ordem do arquivo.
func artes_liberadas() -> Array: return _academia.artes_liberadas()
## Veja academia_artes.gd.
func nome_arte(id: String) -> String: return _academia.nome_arte(id)
## true quando a janela de escolha da arte deve estar aberta: artes liberadas, carreira viva e sem arte escolhida.
func escolha_arte_pendente() -> bool: return _academia.escolha_arte_pendente()
## true na escolha da 1ª chegada (nunca escolheu arte): subtítulo `art_sub_first`.
func escolha_arte_primeira() -> bool: return _academia.escolha_arte_primeira()
## Cartões da janela de escolha: [{id, name, tagline, rule_text, fight_text, icon, apparatus, apparatus_name, last, last_text}].
func artes_para_escolha() -> Array: return _academia.artes_para_escolha()
## Escolhe a arte da carreira (1 clique). Vale a carreira inteira: não existe função de troca. Só com a escolha pendente
## 7b2: `passiva` 0 = a marcada por padrão (a última escolhida, se vale), 1 ou 2; a 2ª só com a meta batida (senão devolve false).
func escolher_arte(id: String, passiva: int = 0) -> bool: return _academia.escolher_arte(id, passiva)
## 7b2: opções de passiva do cartão da arte [{n, name, fight_text, icon, locked, locked_text, selected, progress}].
func passivas_do_cartao(arte_id: String) -> Array: return _academia.passivas_do_cartao(arte_id)
## 7b2: meta da 2ª passiva da arte: {art, has, n, m, finish, finish_text, text, liberada} (text = "2/3 K.O. DE EMBALO").
func progresso_passiva(arte_id: String) -> Dictionary: return _academia.progresso_passiva(arte_id)
## 7b2: a 2ª passiva da arte já foi liberada (para sempre)?
func passiva_liberada(arte_id: String) -> bool: return _academia.passiva_liberada(arte_id)
## 7b2: conta uma vitória pela 1ª passiva (a luta já chama isto sozinha em concluir_luta); devolve {} se não contou.
func contar_vitoria_passiva(finish: String) -> Dictionary: return _academia.contar_vitoria_passiva(finish)
## Soma dos nós ESTILO comprados da arte (0 ou 0,5): o efeito da regra dela fica x(1 + estilo).
func estilo_arte(id: String) -> float: return _academia.estilo_arte(id)
## Bônus do Boxe no clique MANUAL (0,50; com o nó 0,75). 0 sem arte ou com outra arte.
func bonus_arte_clique() -> float: return _academia.bonus_arte_clique()
## 7b1: crítico do clique manual {chance, mult}; o Muay Thai tem 20% e x4,1 (sem arte: 10% e x3).
func bonus_arte_critico() -> Dictionary: return _academia.bonus_arte_critico()
## 7b1: vitória contra o adversário libera as artes com `unlock` (Muay Thai: o Kid). Devolve os ids novos (a luta já chama isto sozinha).
func liberar_artes_por_vitoria(adversario_id: String) -> Array: return _academia.liberar_por_vitoria(adversario_id)
## Bônus do Jiu-jitsu na equipe: (1 + estilo) x min(teto, começo + por_minuto x minutos de arte). 0 sem a arte.
func bonus_arte_equipe() -> float: return _academia.bonus_arte_equipe()
## true quando o bônus da equipe chegou no teto (a UI mostra "(MÁX.)").
func arte_no_teto() -> bool: return _academia.arte_no_teto()
## O traço de luta da arte entra na tática do jogador (luta e prévia usam a mesma função, no motor).
func _atualizar_passiva() -> void: _academia._atualizar_passiva()
func _atualizar_traco() -> void: _academia._atualizar_passiva()  # nome antigo (testes e ferramentas)
## Tática do jogador já com o traço da arte (cópia). Útil para testes e para a UI mostrar números.
func tatica_efetiva(tatica_id: String = "") -> Dictionary: return _academia.tatica_efetiva(tatica_id)

# ===== Repasses para scripts/estado/loja_geradores.gd =====
## Atributo do aparelho (nos aparelhos de arte, o de maior fatia: para cor e ícone). A conta real é `divisao_aparelho`.
func atributo_do_aparelho(aparelho_id: String) -> String: return _loja.atributo_do_aparelho(aparelho_id)
## Como o treino do aparelho se divide nos atributos: {atributo: fração} (soma 1). Aparelho comum: 100% num atributo.
func divisao_aparelho(aparelho_id: String) -> Dictionary: return _loja.divisao_aparelho(aparelho_id)
## Veja loja_geradores.gd.
func multiplicador_aparelho(aparelho_id: String) -> float: return _loja.multiplicador_aparelho(aparelho_id)
## Treino por clique MANUAL normal (sem crítico) com o foco atual: base x aparelho x luva x árvore x local x (1 + Boxe).
func por_clique() -> float: return _loja.por_clique()
## Treino por auto-soco (Metrônomo e assistido): igual ao clique, mas sem o bônus do Boxe.
func por_auto_soco() -> float: return _loja.por_auto_soco()
## Veja loja_geradores.gd.
func _base_soco() -> float: return _loja._base_soco()
## Fator que a equipe recebe: (1 + árvore) x local x (1 + Jiu-jitsu).
func _fator_equipe() -> float: return _loja._fator_equipe()
## Treino/s vindo de todos os geradores (da garagem e pagos).
func producao_total() -> float: return _loja.producao_total()
## Aceita id de gerador da garagem ou pago.
func producao_gerador(gerador_id: String) -> float: return _loja.producao_gerador(gerador_id)
## Aceita id de gerador da garagem ou pago.
func quantidade_gerador(gerador_id: String) -> int: return _loja.quantidade_gerador(gerador_id)
## Custo da próxima unidade (já em 3 dígitos significativos).
func custo_gerador(gerador_id: String) -> float: return _loja.custo_gerador(gerador_id)
## Veja loja_geradores.gd.
func pode_comprar_gerador(gerador_id: String) -> bool: return _loja.pode_comprar_gerador(gerador_id)
## Quantas pessoas desenhar na sala (limite só de desenho; comprar nunca é bloqueado).
func pessoas_desenhadas(gerador_id: String) -> int: return _loja.pessoas_desenhadas(gerador_id)
## Veja loja_geradores.gd.
func nivel_melhoria(aparelho_id: String) -> int: return _loja.nivel_melhoria(aparelho_id)
## Próxima melhoria do aparelho, ou {} se a linha está completa.
func proxima_melhoria(aparelho_id: String) -> Dictionary: return _loja.proxima_melhoria(aparelho_id)
## Veja loja_geradores.gd.
func pode_comprar_melhoria(aparelho_id: String) -> bool: return _loja.pode_comprar_melhoria(aparelho_id)
## Sprite do aparelho: maior visual_level entre as melhorias compradas (0 se nenhuma).
func nivel_visual(aparelho_id: String) -> int: return _loja.nivel_visual(aparelho_id)
## Um clique no alvo central. Soma no saldo e no atributo do foco; emite `clicou`.
func clicar() -> Dictionary: return _loja.clicar()
## Um auto-soco do Metrônomo: o MESMO caminho do clique (aparelho em foco, luva, árvore, crítico, treino no
func auto_socar() -> Dictionary: return _loja.auto_socar()
## 7 enquanto o FRENESI está ligado, 1 nos outros casos.
func mult_frenesi() -> float: return _loja.mult_frenesi()
## O jogador clicou no evento dourado. Tipo "frenzy": liga o FRENESI. Tipo "crew" (bolsa da torcida): paga
func pegar_evento_dourado() -> bool: return _loja.pegar_evento_dourado()
## Quanto a bolsa da torcida paga agora: max(crew_seconds x renda_sem_mao, crew_floor_clicks x por_clique).
func valor_bolsa() -> float: return _loja.valor_bolsa()
## Treino/s sem a mão: equipe + auto-socos do Metrônomo (sem crítico e sem FRENESI).
func renda_sem_mao() -> float: return _loja.renda_sem_mao()
## Extra do Grito da equipe em cada clique da mão: crew_share x equipe/s (0 sem a melhoria). Não vale no auto-soco.
func bonus_crew_click() -> float: return _loja.bonus_crew_click()
## Segundos da equipe por clique com o Grito: loja + nó "Grito mais alto" (Fase 5.4).
func crew_share_efetivo() -> float: return _loja.crew_share_efetivo()
## Veja loja_geradores.gd.
func pode_comprar_crew_click() -> bool: return _loja.pode_comprar_crew_click()
## Veja loja_geradores.gd.
func comprar_crew_click() -> bool: return _loja.comprar_crew_click()
## Troca o foco (grátis, instantâneo). Retorna false se o aparelho não existe.
func definir_foco(aparelho_id: String) -> bool: return _loja.definir_foco(aparelho_id)
## Veja loja_geradores.gd.
func comprar_gerador(gerador_id: String) -> bool: return _loja.comprar_gerador(gerador_id)
## Compra o próximo nível de melhoria do aparelho.
func comprar_melhoria(aparelho_id: String) -> bool: return _loja.comprar_melhoria(aparelho_id)
## Veja loja_geradores.gd.
func multiplicador_luva() -> float: return _loja.multiplicador_luva()
## Luva equipada: {id, level, name, sprite_suffix, click_multiplier}. Nível 0 = luva velha.
func luva_equipada() -> Dictionary: return _loja.luva_equipada()
## Veja loja_geradores.gd.
func sufixo_luva() -> String: return _loja.sufixo_luva()
## Próxima luva da linha, ou {} se completou. Fase 5.1: com a luva anterior ainda na caixa ela NÃO está à venda
func proxima_luva() -> Dictionary: return _loja.proxima_luva()
## Veja loja_geradores.gd.
func pode_comprar_luva() -> bool: return _loja.pode_comprar_luva()
## Veja loja_geradores.gd.
func comprar_luva() -> bool: return _loja.comprar_luva()
## Veja loja_geradores.gd.
func custo_gerador_pago(gerador_id: String) -> float: return _loja.custo_gerador_pago(gerador_id)
## Veja loja_geradores.gd.
func pode_comprar_gerador_pago(gerador_id: String) -> bool: return _loja.pode_comprar_gerador_pago(gerador_id)
## Veja loja_geradores.gd.
func comprar_gerador_pago(gerador_id: String) -> bool: return _loja.comprar_gerador_pago(gerador_id)
## Veja loja_geradores.gd.
func metronomo_niveis() -> int: return _loja.metronomo_niveis()
## Definição do nível atual ({} se 0).
func metronomo_atual() -> Dictionary: return _loja.metronomo_atual()
## Próximo nível à venda: {id, level, cost, interval, name, description, appears_as}, ou {} se completo/sem Metrônomo.
func proximo_metronomo() -> Dictionary: return _loja.proximo_metronomo()
## Segundos entre auto-socos no nível atual (0 = sem Metrônomo).
func intervalo_metronomo() -> float: return _loja.intervalo_metronomo()
## Veja loja_geradores.gd.
func socos_por_segundo_metronomo() -> float: return _loja.socos_por_segundo_metronomo()
## Veja loja_geradores.gd.
func pode_comprar_metronomo() -> bool: return _loja.pode_comprar_metronomo()
## Veja loja_geradores.gd.
func comprar_metronomo() -> bool: return _loja.comprar_metronomo()
## true quando o Metrônomo pode socar agora: garagem na tela (sem luta, sem tela de fim, sem janela da UI).
func metronomo_ativo() -> bool: return _loja.metronomo_ativo()
## API da UI (Fase 5.3): chamar com true quando QUALQUER janela abre (prévia, confirmação, vitória, cartão,
func definir_modal(aberto: bool) -> void: _loja.definir_modal(aberto)

# ===== Repasses para scripts/estado/carreira.gd =====
## true durante a luta (resultado decidido, ainda não aplicado) e com a tela de fim pendente:
func acoes_bloqueadas() -> bool: return _carreira.acoes_bloqueadas()
## Veja carreira.gd.
func tem_luta_pendente() -> bool: return _carreira.tem_luta_pendente()
## Veja carreira.gd.
func tem_fim_pendente() -> bool: return _carreira.tem_fim_pendente()
## Veja carreira.gd.
func numero_carreira() -> int: return _carreira.numero_carreira()
## true quando o jogador venceu todos os adversários da escada (inclusive os da academia).
func escada_completa() -> bool: return _carreira.escada_completa()
## Próximo adversário que dá para enfrentar AGORA ({} se a escada acabou ou se ele só luta em outro local:
func proximo_adversario() -> Dictionary: return _carreira.proximo_adversario()
## true se o próximo adversário só luta em outro local (a UI mostra o MUDAR / "PRÓXIMA: MUDE PARA A ACADEMIA").
func precisa_mudar() -> bool: return _carreira.precisa_mudar()
## "fight" (tem adversário), "move" (precisa mudar de local) ou "end" (escada completa).
func estado_escada() -> String: return _carreira.estado_escada()
## Veja carreira.gd.
func pode_lutar() -> bool: return _carreira.pode_lutar()
## Veja carreira.gd.
func pode_aposentar() -> bool: return _carreira.pode_aposentar()
## Legado em jogo (o "pote"): derivado da fama e do cinturão, não é salvo.
func legado_em_jogo() -> int: return _carreira.legado_em_jogo()
## Legado que a derrota daria agora.
func legado_se_perder() -> int: return _carreira.legado_se_perder()
## Fração do pote que a derrota leva: `defeat_share` + bônus da árvore, sempre abaixo de `retire_share`.
func parte_derrota() -> float: return _carreira.parte_derrota()
## Aposentar agora: {pote, base, bonus, total, cinturao, zero}. `bonus` só com cinturão.
func previa_aposentar() -> Dictionary: return _carreira.previa_aposentar()
## APOSENTAR (só entre lutas): soma o Legado e cria a tela de fim "saiu por cima". Devolve o `fim`.
func aposentar() -> Dictionary: return _carreira.aposentar()
## Soma o Legado e os recordes, cria `fim` e salva, tudo num único save.
func _encerrar_carreira(tipo: String, snap: Dictionary, motivo: Dictionary) -> void: _carreira._encerrar_carreira(tipo, snap, motivo)
## NOVA CARREIRA (só com a tela de fim pendente): zera `career`, mantém `permanent`, soma 1 em
func nova_carreira() -> bool: return _carreira.nova_carreira()
## Veja carreira.gd.
func _zerar_carreira() -> void: _carreira._zerar_carreira()
## Lista dos nós ativos (ordem da compra): [{id, name, effect_text, icon}]. Cartão de início e resumo da garagem.
func resumo_legado() -> Dictionary: return _carreira.resumo_legado()
## Cartão "o que você trouxe" ({} sem nós): {title, career, nodes}. A UI mostra por até 1,8 s.
func cartao_inicio() -> Dictionary: return _carreira.cartao_inicio()

# ===== Repasses para scripts/estado/luta.gd =====
## Veja luta.gd.
func _atributos_array() -> Array: return _luta._atributos_array()
## Veja luta.gd.
func _array_adversario(opp: Dictionary) -> Array: return _luta._array_adversario(opp)
## Veja luta.gd.
func definir_tatica(tatica_id: String) -> bool: return _luta.definir_tatica(tatica_id)
## Risco de uma tática contra o próximo adversário: {label: "easy"|"even"|"hard", chance}.
func risco_tatica(tatica_id: String = "") -> Dictionary: return _luta.risco_tatica(tatica_id)
## Dados da janela de prévia (calcula as 3 táticas: ~600 lutas). Não muda nada no jogo.
func previa() -> Dictionary: return _luta.previa()
## Dinheiro da vitória contra `opp` com o bônus da árvore.
func premio_dinheiro(opp: Dictionary) -> float: return _luta.premio_dinheiro(opp)
## Fama da vitória contra `opp` com o bônus da árvore (inteiro, arredondado).
func premio_fama(opp: Dictionary) -> int: return _luta.premio_fama(opp)
## Veja luta.gd.
func tem_previa_detalhada() -> bool: return _luta.tem_previa_detalhada()
## `permanent.revenge_opponent`: id do adversário que encerrou a última carreira ("" = sem marca).
func algoz() -> String: return _luta.algoz()
## Veja luta.gd.
func e_algoz(adversario_id: String) -> bool: return _luta.e_algoz(adversario_id)
## Alavanca L1 (decisão D2): "ESPERE FICAR VERDE" contra o algoz e contra todo adversário antes dele na escada,
func esperar_verde(adversario_id: String, rotulo: String) -> bool: return _luta.esperar_verde(adversario_id, rotulo)
## Para o bloco "PRÓXIMA" do HUD: marca de revanche e dica do verde do próximo adversário.
func info_proxima() -> Dictionary: return _luta.info_proxima()
## Último risco calculado para o HUD: {adversario, rotulo ("easy"|"even"|"hard"|""), tatica}.
func risco_proxima() -> Dictionary: return _luta.risco_proxima()
## Recalcula o risco do HUD (200 lutas) e emite `risco_proxima_mudou` se mudou.
func atualizar_risco_hud() -> void: _luta.atualizar_risco_hud()
## Veja luta.gd.
func _definir_risco_hud(adversario: String, rotulo: String) -> void: _luta._definir_risco_hud(adversario, rotulo)
## LUTAR: simula a luta inteira, grava `career.fight` e salva ANTES da animação. Devolve o mesmo que
func lutar() -> Dictionary: return _luta.lutar()
## Espera o cálculo em segundo plano e deixa o motivo salvo (usado pelos testes e pelo fechamento).
func aguardar_motivo() -> void: _luta.aguardar_motivo()
## Luta em andamento recalculada da semente (determinística): eventos, tempos e resultado.
func luta_atual() -> Dictionary: return _luta.luta_atual()
## Prefixo do cenário da luta contra `adversario_id` (7a1): "arena" (borracharia) ou "arena_league" (liga da academia).
func arena_da_luta(adversario_id: String) -> String: return _luta.arena_da_luta(adversario_id)
## Fim da animação (ou luta pendente ao reabrir): aplica o resultado UMA vez e salva.
func concluir_luta() -> Dictionary: return _luta.concluir_luta()
## Motivo da derrota (design §7): {attribute, faltaram, who, round, model, tip, stat, better_tactic}.
func motivo_da_luta(snap: Dictionary = {}) -> Dictionary: return _luta.motivo_da_luta(snap)

# ===== Repasses para scripts/estado/save_validacao.gd =====
## Veja save_validacao.gd.
func salvar() -> bool: return _save.salvar()
## Veja save_validacao.gd.
func carregar_save() -> void: _save.carregar_save()
## Veja save_validacao.gd.
func apagar_save() -> void: _save.apagar_save()
## Campos do estado que vão para o save (v7). Produção e custos não são salvos (vêm de data/).
func para_save() -> Dictionary: return _save.para_save()
## Aplica um estado lido do save (formato v7). Campo faltando ou inválido recebe o padrão.
func aplicar_save(estado: Dictionary) -> void: _save.aplicar_save(estado)
## Veja save_validacao.gd.
func _emitir_tudo(pedir_arte: bool = true) -> void: _save._emitir_tudo(pedir_arte)

# ===== Repasses para scripts/estado/treino_fora.gd (7a2) =====
## Tipo do convite que a UI desenha agora ("" = nenhum balão): "spar" (Choque) | "flyers" (Panfletagem).
func convite_visivel() -> String: return _treino.convite_visivel()
## {kind, restante_s, proximo_em_s} do balão visível; {} sem balão.
func convite_info() -> Dictionary: return _treino.convite_info()
## Clicou em IR: consome o convite, salva e abre o minigame. {kind, art, level, variant, rumor_text, countdown_s, duration_s} ({} sem convite).
func convite_ir() -> Dictionary: return _treino.convite_ir()
## O minigame em andamento (ChoqueLogica | PanfletoLogica) ou null; o tick do GameState faz o tempo passar.
func treino_jogo() -> Variant: return _treino.treino_jogo()
## Fim do jogo ou SAIR: aplica e salva o prêmio e o devolve (chamar de novo devolve o mesmo).
func treino_concluir() -> Dictionary: return _treino.treino_concluir()
## VOLTAR: fecha a tela de prêmio e devolve a sala (relógio volta a andar).
func treino_voltar() -> void: _treino.treino_voltar()
## Nível do minigame agora (índice da escada, 0 a 5).
func nivel_treino() -> int: return _treino.nivel_treino()
## AQUECIDO guardado para a próxima luta.
func aquecido() -> bool: return _treino.aquecido()
## Fator dos atributos na luta (1,03 com AQUECIDO, senão 1).
func mult_aquecido() -> float: return _treino.mult_aquecido()
## O recorte de jornal do local atual: {spot, object_text} ou {} (Gato Preto, 7a2).
func recorte_gato_preto() -> Dictionary: return _treino.recorte_gato_preto()
