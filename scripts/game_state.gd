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
signal nova_carreira_iniciada(cartao: Dictionary)  # só em NOVA CARREIRA (não na carga do save)
signal aparelho_comprado(aparelho: String)  # Fase 4b: aparelho montado (a UI faz a chegada)
signal evento_dourado(duracao: float)  # o cinturão dourado aparece na sala: clicar nele liga o FRENESI
signal frenesi_mudou(restante: float)  # FRENESI ligado (segundos restantes) ou desligado (0)
signal assistido_mudou(estado: String)  # "off" | "waiting" | "active" | "metronome"
# --- Fase 5 (contrato: docs/fases/fase5-api.md) ---
signal local_mudou(local: String)  # MUDAR, NOVA CARREIRA ou carga do save
signal arte_mudou(arte: String)  # escolha da arte, NOVA CARREIRA ("" = sem arte) ou carga do save
signal escolha_arte_pedida(primeira: bool)  # a janela de escolha da arte deve abrir (1ª chegada, início de carreira, reabrir o jogo)

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
# ganha o FRENESI: treino x7 nos CLIQUES e nos auto-socos por 12 s (não multiplica a renda da equipe: só rende para quem clica).
# Não é salvo (é passageiro) e não conta enquanto uma janela/luta estiver aberta.
const FRENESI_MULT := 7.0
const FRENESI_DURACAO := 12.0
const EVENTO_DURACAO := 7.0
const EVENTO_ESPERA_MIN := 45.0
const EVENTO_ESPERA_MAX := 90.0
var frenesi_restante := 0.0
var evento_dourado_restante := 0.0  # > 0: o cinturão dourado está na sala esperando o clique
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
var _perigo_gym := 0.0  # Fase 5: segundos seguidos com o adversário da academia PERIGOSO (não vai para o save)
var _estilo: Dictionary = {}  # Fase 5: arte -> soma dos nós ESTILO comprados (art_rule_bonus)


func _ready() -> void:
	rng.randomize()
	inicializar(_pasta_save_inicial(), CAMINHO_CONFIG)
	# Fechar pelo X passa por _notification, que salva antes de sair.
	get_tree().set_auto_accept_quit(false)


func _process(delta: float) -> void:
	tick(delta)
	_finalizar_motivo(true, false)  # recolhe sem travar o quadro


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
		dados_academia: GymData = null) -> void:
	config = GameConfig.carregar(caminho_config)
	dados = TrainingData.carregar(caminho_treino, caminho_geradores, caminho_textos)
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
	# Com a tela de fim pendente a carreira está congelada (nada produz, o tempo não anda).
	if fim.is_empty():
		var producao := producao_total()
		if producao > 0.0:
			_ganhar(producao * delta)
		tempo_jogo += delta
		if arte_id != "":
			arte_segundos += delta  # o relógio da arte anda junto com o da carreira (inclusive em luta)
		_tick_risco(delta)
		_tick_metronomo(delta)
		_tick_assistido(delta)
		_tick_tempo_morto(delta)
		_tick_evento_dourado(delta)
	if autosave_ativo:
		_tempo_autosave += delta
		if _tempo_autosave >= config.autosave_intervalo_segundos:
			_tempo_autosave = 0.0
			salvar()


# --- Consultas ---

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
	return _base_soco() * (1.0 + bonus_arte_clique())


## Treino por auto-soco (Metrônomo e assistido): igual ao clique, mas sem o bônus do Boxe.
func por_auto_soco() -> float:
	return _base_soco()


func _base_soco() -> float:
	return dados.base_training * multiplicador_aparelho(foco) * multiplicador_luva() * (1.0 + _b("click_bonus")) * mult_local()


## Fator que a equipe recebe: (1 + árvore) x local x (1 + Jiu-jitsu).
func _fator_equipe() -> float:
	return (1.0 + _b("passive_bonus")) * mult_local() * (1.0 + bonus_arte_equipe())


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


# --- Ações ---

## Um clique no alvo central. Soma no saldo e no atributo do foco; emite `clicou`.
func clicar() -> Dictionary:
	_ocioso = 0.0  # mão mexendo, mesmo se a ação for recusada
	if acoes_bloqueadas():
		return {}
	return _socar(false)


## Um auto-soco do Metrônomo: o MESMO caminho do clique (aparelho em foco, luva, árvore, crítico, treino no
## atributo), mas emite `auto_socou` em vez de `clicou` (a UI não treme a tela e usa número menor).
## Normalmente chamado pelo tique do Metrônomo; público para testes.
func auto_socar() -> Dictionary:
	if acoes_bloqueadas():
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


## O jogador clicou no cinturão dourado: liga o FRENESI. false se não havia cinturão (ou se há janela aberta).
func pegar_evento_dourado() -> bool:
	if evento_dourado_restante <= 0.0 or modal_aberto or acoes_bloqueadas():
		return false
	evento_dourado_restante = 0.0
	frenesi_restante = FRENESI_DURACAO
	frenesi_mudou.emit(frenesi_restante)
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


# --- Fase 4b: aparelhos que chegam ---

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


## "owned" | "buyable" | "missing" | "locked" (inexistente = "locked") | "absent" (aparelho de outra arte: não existe aqui).
func estado_aparelho(aparelho_id: String) -> String:
	if dados.aparelho(aparelho_id).is_empty():
		return "locked"
	if not aparelho_existe(aparelho_id):
		return "absent"
	if aparelho_montado(aparelho_id):
		return "owned"
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
	aparelhos_montados_ids.append(aparelho_id)
	foco = aparelho_id
	salvar()
	aparelho_comprado.emit(aparelho_id)
	foco_mudou.emit(foco)
	economia_mudou.emit()
	return true


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


# --- Fase 4b: modo assistido (só com o Shift pressionado) ---

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
	if not _segurando or modal_aberto or acoes_bloqueadas():
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
	_ocioso += delta
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


# --- Fase 3: estado e consultas ---

## true durante a luta (resultado decidido, ainda não aplicado) e com a tela de fim pendente:
## a garagem não aceita clique nem compra.
## Fase 5: a janela de escolha da arte aberta também bloqueia (sem clique, Metrônomo, assistido, compra ou luta).
func acoes_bloqueadas() -> bool:
	return not luta.is_empty() or not fim.is_empty() or escolha_arte_pendente()


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
	return not proximo_adversario().is_empty() and not acoes_bloqueadas()


func pode_aposentar() -> bool:
	return not acoes_bloqueadas()


## Legado em jogo (o "pote"): derivado da fama e do cinturão, não é salvo.
func legado_em_jogo() -> int:
	var c: Dictionary = lutas.carreira
	return int(floor(fama * c.legacy_per_fame + 1.0e-9)) + (int(c.belt_legacy_bonus) if cinturao else 0)


## Legado que a derrota daria agora.
func legado_se_perder() -> int:
	return int(floor(legado_em_jogo() * parte_derrota() + 1.0e-9))


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
	return {"pote": pote, "base": base, "bonus": bonus, "total": base + bonus, "cinturao": cinturao,
		"zero": base + bonus == 0}


func _atributos_array() -> Array:
	return [atributos.get("strength", 0.0), atributos.get("agility", 0.0), atributos.get("endurance", 0.0)]


func _array_adversario(opp: Dictionary) -> Array:
	return [opp.strength, opp.agility, opp.endurance]


# --- Fase 3: loja (dinheiro) ---

func multiplicador_luva() -> float:
	var m := 1.0
	for i in mini(nivel_luva, lutas.luvas.size()):
		m *= float(lutas.luvas[i].click_multiplier)
	return m


## Luva equipada: {id, level, name, sprite_suffix, click_multiplier}. Nível 0 = luva velha.
## A UI troca cursor, mão da garagem e mão da luta por `sprite_suffix` (ex.: "" ou "_glove_l1").
func luva_equipada() -> Dictionary:
	if nivel_luva <= 0 or nivel_luva > lutas.luvas.size():
		return lutas.luva_base
	return lutas.luvas[nivel_luva - 1]


func sufixo_luva() -> String:
	return str(luva_equipada().sprite_suffix)


## Próxima luva à venda, ou {} se completou a linha.
func proxima_luva() -> Dictionary:
	return {} if nivel_luva >= lutas.luvas.size() else lutas.luvas[nivel_luva]


func pode_comprar_luva() -> bool:
	var l := proxima_luva()
	return not l.is_empty() and loja_estado(float(l.cost)) == "ok"


func comprar_luva() -> bool:
	if acoes_bloqueadas() or not pode_comprar_luva():
		return false
	_gastar_dinheiro(proxima_luva().cost)
	nivel_luva += 1
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


# --- Fase 4: Metrônomo (loja, dinheiro) ---

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
	return nivel_metronomo > 0 and not modal_aberto and not acoes_bloqueadas()


## Chamado pela UI quando uma janela (prévia, confirmação, vitória, cartão) abre ou fecha.
func definir_modal(aberto: bool) -> void:
	modal_aberto = aberto
	_atualizar_estado_assist()


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


# --- Fase 3: táticas, prévia e risco ---

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


# --- Fase 4: bônus da árvore (prêmios) ---

## Dinheiro da vitória contra `opp` com o bônus da árvore.
func premio_dinheiro(opp: Dictionary) -> float:
	return float(opp.prize_money) * (1.0 + _b("money_bonus"))


## Fama da vitória contra `opp` com o bônus da árvore (inteiro, arredondado).
func premio_fama(opp: Dictionary) -> int:
	return int(floor(float(opp.prize_fame) * (1.0 + _b("fame_bonus")) + 0.5))


func tem_previa_detalhada() -> bool:
	return _b("preview_percent") > 0.0


# --- Fase 4: revanche e "espere ficar verde" ---

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


# --- Fase 3: a luta ---

## LUTAR: simula a luta inteira, grava `career.fight` e salva ANTES da animação. Devolve o mesmo que
## `luta_atual()` ({} se não pode lutar). A UI só anima a lista de eventos.
func lutar() -> Dictionary:
	if not pode_lutar():
		return {}
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
		# Revanche: vencer o algoz limpa a marca (no mesmo save do prêmio).
		var revanche := e_algoz(opp.id)
		if revanche:
			permanente["revenge_opponent"] = ""
		var proximo := proximo_adversario()
		resumo = {"win": true, "opponent": opp.id, "money": premio, "fame": premio_f,
			"legacy_gain": legado_em_jogo() - pote_antes, "legacy_run": legado_em_jogo(), "belt": opp.belt,
			"next": proximo.get("id", ""), "next_name": proximo.get("name", ""), "revenge": revanche,
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


# --- Fase 3: fim de carreira, Legado e nova carreira ---

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
	permanente["legacy_total"] = int(permanente.legacy_total) + ganho
	# Revanche: a derrota marca quem venceu; a aposentadoria limpa a marca (mesmo save do Legado).
	permanente["revenge_opponent"] = str(snap.get("opponent", "")) if tipo == "defeat" else ""
	permanente["careers_finished"] = int(permanente.careers_finished) + 1
	permanente["best_wins"] = maxi(int(permanente.best_wins), indice_escada)
	if cinturao:
		permanente["belts_won"] = int(permanente.belts_won) + 1
	var motivo_fim := motivo.duplicate()
	if tipo == "defeat":
		motivo_fim["unlock_tip"] = _aparelho_da_dica(motivo)
	fim = {
		"kind": tipo, "career_number": numero_carreira(), "legacy_gained": ganho,
		"legacy_total": int(permanente.legacy_total),
		"opponent": str(snap.get("opponent", "")), "tactic": str(snap.get("tactic", tatica)),
		"seed": int(snap.get("seed", 0)), "player": snap.get("player", {}).duplicate(),
		"result": snap.get("result", {}).duplicate(), "reason": motivo_fim,
		"summary": {"wins": indice_escada, "belts": 1 if cinturao else 0, "fame": fama,
			"money_earned": dinheiro_ganho, "play_seconds": tempo_jogo, "art": arte_id},
	}
	salvar()
	permanente_mudou.emit()
	fim_de_carreira.emit(fim.duplicate(true))


## NOVA CARREIRA (só com a tela de fim pendente): zera `career`, mantém `permanent`, soma 1 em
## "Carreira N". Volta direto para a garagem.
func nova_carreira() -> bool:
	if fim.is_empty():
		return false
	_zerar_carreira()
	permanente["career_number"] = int(permanente.career_number) + 1
	fim = {}
	# Os bônus da árvore passam a valer aqui (e a Memória muscular devolve o Metrônomo nível 1).
	_recalcular_bonus()
	nivel_metronomo = mini(int(_b("metronome_start")), metronomo_niveis())
	salvar()
	_tempo_autosave = 0.0
	_emitir_tudo(false)
	permanente_mudou.emit()
	nova_carreira_iniciada.emit(cartao_inicio())
	# Com as artes liberadas, a escolha vem ANTES do cartão (a UI abre a janela e depois mostra `cartao_inicio()`).
	if escolha_arte_pendente():
		escolha_arte_pedida.emit(escolha_arte_primeira())
	return true


func _zerar_carreira() -> void:
	frenesi_restante = 0.0
	evento_dourado_restante = 0.0
	_evento_espera = -1.0
	treino = 0.0
	atributos = {}
	for id in dados.atributos:
		atributos[id] = 0.0
	aparelhos_montados_ids = _aparelhos_iniciais()
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
	_perigo_gym = 0.0
	nivel_luva = 0
	dinheiro = 0.0
	fama = 0
	indice_escada = 0
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


# --- Fase 4: árvore de habilidades ---

# Soma, por tipo, dos efeitos dos nós comprados (aditivo dentro do tipo; ver design §3.5).
func _recalcular_bonus() -> void:
	var ids: Array = permanente.get("skill_nodes", [])
	_bonus = bonus_de(ids)
	# Fase 5: nós ESTILO valem só para a arte deles (`requires_art`).
	_estilo = {}
	for id in ids:
		var n: Dictionary = lutas.no_da_arvore(str(id))
		if not n.is_empty() and n.effect_type == "art_rule_bonus" and n.requires_art != "":
			_estilo[n.requires_art] = float(_estilo.get(n.requires_art, 0.0)) + float(n.effect_value)


## Bônus (por tipo de efeito) de uma lista de ids de nós. Tipos: click_bonus, passive_bonus, money_bonus, fame_bonus,
## defeat_share_bonus (somas), metronome_start (maior valor), preview_percent (maior valor).
func bonus_de(ids: Array) -> Dictionary:
	var b := {}
	for t in FightData.TIPOS_EFEITO:
		b[t] = 0.0
	for id in ids:
		var n: Dictionary = lutas.no_da_arvore(str(id))
		if n.is_empty():
			continue
		var t: String = n.effect_type
		if t == "metronome_start" or t == "preview_percent":
			b[t] = maxf(float(b[t]), float(n.effect_value))
		else:
			b[t] = float(b[t]) + float(n.effect_value)
	return b


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


## Estado de um nó para a tela: "owned" (comprado), "buyable" (comprável), "missing" (falta Legado) ou
## "locked" (trancado pelo nó anterior). Id inexistente: "".
func estado_no(id: String) -> String:
	var n: Dictionary = lutas.no_da_arvore(id)
	if n.is_empty():
		return ""
	if tem_no(id):
		return "owned"
	if n.requires != "" and not tem_no(n.requires):
		return "locked"
	if n.requires_art != "" and not (n.requires_art in artes_liberadas()):
		return "locked"  # Fase 5: nó ESTILO pede a arte liberada
	return "buyable" if legado_disponivel() >= int(n.cost) else "missing"


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


## A árvore só abre/compra com a tela de fim pendente (entre carreiras).
func arvore_aberta() -> bool:
	return not fim.is_empty()


func pode_comprar_no(id: String) -> bool:
	return arvore_aberta() and estado_no(id) == "buyable"


## Compra o nó: desconta o Legado exato, grava o nó e salva (um save só). Recusa (nada muda) sem tela de fim pendente,
## nó já comprado, anterior não comprado ou Legado insuficiente. Os bônus valem a partir da NOVA CARREIRA.
func comprar_no(id: String) -> bool:
	if not pode_comprar_no(id):
		return false
	var n: Dictionary = lutas.no_da_arvore(id)
	permanente["legacy_total"] = maxi(0, int(permanente.legacy_total) - int(n.cost))
	var nos: Array = permanente.get("skill_nodes", [])
	nos.append(id)
	permanente["skill_nodes"] = nos
	# O `fim` pendente mostra o Legado total: mantém igual ao disponível.
	fim["legacy_total"] = int(permanente.legacy_total)
	salvar()
	arvore_mudou.emit()
	permanente_mudou.emit()
	return true


## Lista dos nós ativos (ordem da compra): [{id, name, effect_text, icon}]. Cartão de início e resumo da garagem.
func resumo_legado() -> Dictionary:
	var itens: Array = []
	for id in permanente.get("skill_nodes", []):
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
	return {"title": preencher(texto_ui("career_card_title", "CARREIRA {n} — O QUE VOCÊ TROUXE:"), {"n": numero_carreira()}),
		"career": numero_carreira(), "nodes": r.nodes, "art": arte_id,
		"art_text": preencher(texto_ui("career_card_art", "ARTE: {nome}"), {"nome": nome_arte(arte_id).to_upper()}) if arte_id != "" else ""}


# --- Fase 5: academia, mudança, artes marciais (contrato: docs/fases/fase5-api.md) ---

## Multiplicador global de treino do local atual (garagem 1,0; academia 2,0), lido de data/locations.json.
func mult_local() -> float:
	return float(academia.local(local_id).get("training_mult", 1.0))


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


# --- A mudança ---

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
	local_id = str(d.id)
	var primeira: bool = permanente.arts_unlocked.is_empty() and not academia.artes.is_empty()
	if primeira:
		permanente["arts_unlocked"] = academia.ids_artes()
	_chave_melhor = ""
	_perigo_gym = 0.0
	salvar()
	local_mudou.emit(local_id)
	if primeira:
		permanente_mudou.emit()
	escada_mudou.emit()
	economia_mudou.emit()
	atualizar_risco_hud()
	if escolha_arte_pendente():
		escolha_arte_pedida.emit(escolha_arte_primeira())
	return true


# --- Reserva da mudança na LOJA ---

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


# --- Artes ---

## Artes liberadas para sempre (ids), na ordem do arquivo.
func artes_liberadas() -> Array:
	return permanente.get("arts_unlocked", []).duplicate()


func nome_arte(id: String) -> String:
	return str(academia.arte(id).get("name", ""))


## true quando a janela de escolha da arte deve estar aberta: artes liberadas, carreira viva e sem arte escolhida.
## Cobre a 1ª chegada, o início de toda carreira e reabrir o jogo sem ter escolhido. Enquanto vale, `acoes_bloqueadas()`.
func escolha_arte_pendente() -> bool:
	return arte_id == "" and fim.is_empty() and not permanente.get("arts_unlocked", []).is_empty()


## true na escolha da 1ª chegada (nunca escolheu arte): subtítulo `art_sub_first`.
func escolha_arte_primeira() -> bool:
	return str(permanente.get("last_art", "")) == ""


## Subtítulo da janela: "AS DUAS ARTES FICAM LIBERADAS PARA SEMPRE" na 1ª vez, "CARREIRA n: ESCOLHA A ARTE" depois.
func subtitulo_escolha_arte() -> String:
	if escolha_arte_primeira():
		return texto_ui("art_sub_first")
	return preencher(texto_ui("art_sub_career", "CARREIRA {n}: ESCOLHA A ARTE"), {"n": numero_carreira()})


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
	permanente["last_art"] = id
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
	var pct := 0
	if absf(float(f.damage_mult) - 1.0) > 1.0e-9:
		pct = int(round(absf(float(f.damage_mult) - 1.0) * 100.0))
	elif absf(float(f.taken_mult) - 1.0) > 1.0e-9:
		pct = int(round(absf(1.0 - float(f.taken_mult)) * 100.0))
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
	motor.traco = {"damage_mult": float(f.get("damage_mult", 1.0)), "taken_mult": float(f.get("taken_mult", 1.0))}


## Tática do jogador já com o traço da arte (cópia). Útil para testes e para a UI mostrar números.
func tatica_efetiva(tatica_id: String = "") -> Dictionary:
	return motor.aplicar_traco(lutas.tatica(tatica) if tatica_id == "" else lutas.tatica(tatica_id))


# --- Dica de aposentar na academia ---

## Bloco PRÓXIMA LUTA: {show, text, legacy, seconds}. `show` = o adversário da academia está PERIGOSO (na melhor das 3 táticas)
## há >= `gym_retire_hint_seconds` (career.json) seguidos. `legacy` = o Legado que aposentar agora leva (mesmo cálculo da confirmação).
## Os segundos não vão para o save (reabrir o jogo zera a contagem).
func dica_aposentar() -> Dictionary:
	var legado := int(previa_aposentar().total)
	var mostrar := fim.is_empty() and luta.is_empty() and _perigo_gym >= float(lutas.carreira.gym_retire_hint_seconds)
	return {"show": mostrar, "legacy": legado, "seconds": _perigo_gym,
		"text": preencher(texto_ui("gym_retire_hint", "APOSENTAR AGORA LEVA {n} DE LEGADO"), {"n": legado})}


# --- Fase 4: tempo morto (depuração/QA; não vai para o save) ---

## Métrica de tempo morto da carreira: {atual, maximo, total} em segundos. Tempo morto = garagem livre, próximo
## adversário PERIGOSO na melhor das 3 táticas e nada da loja cabe no dinheiro. Só atualiza com `risco_hud_ativo`.
func tempo_morto() -> Dictionary:
	return {"atual": _morto_atual, "maximo": _morto_max, "total": _morto_total}


## Menor preço da loja agora (próximo Prof. Nelson, próxima luva, próximo nível do Metrônomo), em dinheiro.
func menor_preco_loja() -> float:
	var m := INF
	for g in lutas.geradores_pagos:
		m = minf(m, custo_gerador_pago(g.id))
	var l := proxima_luva()
	if not l.is_empty():
		m = minf(m, float(l.cost))
	var mt := proximo_metronomo()
	if not mt.is_empty():
		m = minf(m, float(mt.cost))
	return m


func _tick_tempo_morto(delta: float) -> void:
	var morto := false
	var perigo_gym := false
	var opp := proximo_adversario()
	if risco_hud_ativo and luta.is_empty() and not opp.is_empty():
		_atualizar_melhor_risco(delta)
		morto = _perigoso_melhor and dinheiro < menor_preco_loja()
		perigo_gym = _perigoso_melhor and str(opp.location) != academia.local_padrao
	# Fase 5: segundos seguidos com o adversário da academia PERIGOSO (base da dica de aposentar)
	_perigo_gym = _perigo_gym + delta if perigo_gym else 0.0
	if morto:
		_morto_atual += delta
		_morto_total += delta
		_morto_max = maxf(_morto_max, _morto_atual)
	else:
		_morto_atual = 0.0


# "Perigoso na melhor das 3 táticas": recalcula só quando atributos ou escada mudam, no máximo 1 vez por refresh do HUD.
func _atualizar_melhor_risco(delta: float) -> void:
	_tempo_melhor += delta
	var chave := "%d|%s|%s|%s" % [indice_escada, atributos.get("strength", 0.0), atributos.get("agility", 0.0),
		atributos.get("endurance", 0.0)]
	if chave == _chave_melhor:
		return
	if _chave_melhor != "" and _tempo_melhor < float(lutas.risco.hud_refresh_seconds):
		return
	_tempo_melhor = 0.0
	_chave_melhor = chave
	var opp := proximo_adversario()
	var algum_ok := false
	for t in lutas.taticas:
		if motor.passa(_atributos_array(), _array_adversario(opp), t.id, int(lutas.risco.samples), float(lutas.risco.even_min)):
			algum_ok = true
			break
	_perigoso_melhor = not algum_ok

# --- Fase 3: textos montados ---

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
		"tip": dica, "tip_tactic": dica_t, "support": texto_ui("end_support_line"),
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
		var i_cint := lutas.indice_cinturao()
		var primeiro_gym := lutas.indice_primeiro_do_local(academia.destino_mudanca().get("id", "")) if not academia.destino_mudanca().is_empty() else -1
		if int(s.get("belts", 0)) > 0 and primeiro_gym >= 0 and int(s.get("wins", 0)) <= primeiro_gym and i_cint >= 0:
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


# --- Depuração (só em build de debug; a UI mostra com F12) ---

func debug_disponivel() -> bool:
	return OS.is_debug_build()


## Multiplica só o saldo (nunca os atributos).
func debug_multiplicar_saldo() -> void:
	if not debug_disponivel():
		return
	_definir_treino(maxf(treino, 1.0) * config.multiplicador_debug)
	economia_mudou.emit()


## Soma unidades de cada gerador de graça.
func debug_somar_geradores() -> void:
	if not debug_disponivel():
		return
	for g in dados.geradores:
		geradores[g.id] = quantidade_gerador(g.id) + int(config.debug_unidades_gerador)
		gerador_mudou.emit(g.id, geradores[g.id])
	economia_mudou.emit()


# --- Save ---

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


## Campos do estado que vão para o save (v6). Produção e custos não são salvos (vêm de data/).
func para_save() -> Dictionary:
	return {
		"career": {
			"metronome_level": nivel_metronomo,
			"location": local_id,
			"art": arte_id,
			"art_seconds": arte_segundos,
			"apparatus_owned": aparelhos_montados_ids.duplicate(),
			"training": treino,
			"attributes": atributos.duplicate(),
			"focus": foco,
			"generators": geradores.duplicate(),
			"upgrades": niveis_melhoria.duplicate(),
			"paid_generators": geradores_pagos.duplicate(),
			"glove_level": nivel_luva,
			"money": dinheiro,
			"fame": fama,
			"ladder_index": indice_escada,
			"belt": cinturao,
			"tactic": tatica,
			"play_seconds": tempo_jogo,
			"money_earned": dinheiro_ganho,
			"fight": luta.duplicate(true) if not luta.is_empty() else null,
		},
		"permanent": permanente.duplicate(),
		"ending": fim.duplicate(true) if not fim.is_empty() else null,
	}


## Aplica um estado lido do save (formato v6). Campo faltando ou inválido recebe o padrão.
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
	_recalcular_bonus()
	nivel_metronomo = _inteiro_valido(c.get("metronome_level", 0), float(metronomo_niveis()))
	_acc_metronomo = 0.0
	_acc_assist = _assist_primeiro()
	_chave_melhor = ""
	fim = _validar_fim(estado.get("ending", null))
	_perigo_gym = 0.0
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
	return {
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
		"legacy_total": _inteiro_valido(v.get("legacy_total", 0), 1.0e15),
		"opponent": str(v.get("opponent", "")), "tactic": str(v.get("tactic", "")),
		"seed": _inteiro_valido(v.get("seed", 0), 4294967295.0),
		"player": pl.duplicate(true) if pl is Dictionary else {},
		"result": r.duplicate(true) if r is Dictionary else {},
		"reason": rs.duplicate(true) if rs is Dictionary else {},
		"summary": {"wins": _inteiro_valido(s.get("wins", 0), 1.0e9), "belts": _inteiro_valido(s.get("belts", 0), 1.0e9),
			"fame": _inteiro_valido(s.get("fame", 0), 1.0e15), "money_earned": _numero_valido(s.get("money_earned", 0.0)),
			"play_seconds": _numero_valido(s.get("play_seconds", 0.0)), "art": _validar_arte_id(s.get("art", ""))},
	}


# --- Auxiliares ---

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
	treino_mudou.emit(treino)
	for id in atributos:
		atributo_mudou.emit(id, atributos[id])
	foco_mudou.emit(foco)
	dinheiro_mudou.emit(dinheiro)
	fama_mudou.emit(fama)
	tatica_mudou.emit(tatica)
	luva_mudou.emit(nivel_luva, sufixo_luva())
	metronomo_mudou.emit(nivel_metronomo)
	local_mudou.emit(local_id)
	arte_mudou.emit(arte_id)
	_atualizar_estado_assist()
	escada_mudou.emit()
	economia_mudou.emit()
	carreira_mudou.emit()
	if risco_hud_ativo:
		atualizar_risco_hud()
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


# --- Fase 4b: validações e dica ---

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


# --- Fase 5: validações do save ---

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
