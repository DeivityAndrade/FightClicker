class_name Sala
extends Control
## A sala da garagem montada pelos sprites e posições do manifest, mais o juice do clique.
## Só lê o estado (sinais do GameState) e chama GameState.clicar()/definir_foco().
## Coordenadas internas = coordenadas da tela base 640x360 (o nó "Mundo" compensa a posição da sala).

const AREA_ANTIGA := Rect2(128, 18, 384, 272)  # sala de antes da 6d2 (só se o manifest ainda não tiver room_rect largo)
const ALVO := Rect2(312, 182, 48, 90)  # área clicável central (manifest.click_area)
const PONTO_PADRAO := Vector2(336, 222)
const POOL_NUMEROS := 24
const NUMEROS_FOLGA := 6.0  # 6d: espaço vertical entre os números de um mesmo clique
const NUMEROS_MAX_POR_CLIQUE := 3  # 6d: no máximo 3 números por clique (um por atributo que subiu)
const ESCALA_GRANDE_A_PARTIR := 0.75  # 6d: ganho >= 75% do maior sai grande (2x); abaixo disso, pequeno (1x)
const POOL_FX := 6
# Deslocamentos em x dos números sucessivos: espalham a coluna quando se clica rápido.
const DESVIOS_X := [-30, 30, 0]
const Z_NUMEROS := 900
const Z_FX := 800

const SACO := "punching_bag"
const CORDA := "jump_rope"
const ESTEIRA := "treadmill"
const PERA := "speed_bag"  # Fase 5: aparelho do Boxe
const BONECO := "grappling_dummy"  # Fase 5: aparelho do Jiu-jitsu
const SACO_CHUTE := "kick_bag"  # 7b1: saco comprido do Muay Thai (o lutador chuta: fighter_low_kick, quadro 64x72, mesmo pivô do foco_saco)
const BR0 := Color("3b2622")  # caneta da plaquinha de papelão (direcao-visual §3)

## Clique na sala que nao pegou nada (fora do alvo, de caixa e de aparelho): completa o balao que esta escrevendo (Fase 6a).
signal clique_vazio

## Clique no mural da parede (Fase 6c2): o Fluxo abre a janela do mural.
signal mural_clicado

## 8a2: clique no envelope PROPOSTA no chão: o Fluxo abre a janela do contrato.
signal envelope_clicado

## 7a2: clique no Osmar com o balão do convite aberto (o Garagem decide se vai).
signal osmar_convite

## Ronda: o capuz no prego foi clicado (a sala só avisa; o Fluxo abre a tela da Ronda).
signal capuz_clicado

var sfx: Sfx
var _area := area()  # 6d2: a sala ocupa a tela (manifest.room_rect = 0,18,640,312)
var _mural: AnimSprite  # mural da escola na parede (garagem e academia), ao lado da foto
var _mural_rect := Rect2()  # área clicável e do hover (vazio = não desenhado)
var _mural_chave := ""
var dica_ativa := false  # mostra a seta que aponta o alvo (primeira vez)

var _mundo: Node2D
var _corrente: Corrente
var _seta: Seta
var _lampada: AnimSprite
var _bg: Sprite2D  # garage_bg ou gym_bg (Fase 5)
var _bg_nome := ""
var _tubos: Array[AnimSprite] = []  # tubos da academia (a luz da garagem é a lâmpada)
var _pera: AnimSprite  # speed_bag: na parede (descanso) ou em pé no centro (foco)
var _boneco: AnimSprite  # grappling_dummy: no canto (descanso) ou sentado no centro (foco)
var _chute: AnimSprite  # 7b1: kick_bag, saco comprido do Muay Thai: deitado no canto (descanso) ou pendurado no gancho do centro (foco)
var _corrente_chute: Corrente  # corrente do saco comprido (da viga, y 33, ate o gancho em 336,190)
var _local_anterior := ""
var _chegada_pendente := false  # festa da chegada na academia: espera a janela de arte fechar
var _saco: AnimSprite
var _corda_prego: AnimSprite
var _esteira: AnimSprite
var _lutador: AnimSprite
var _corda_giro: AnimSprite  # corda NA FRENTE do lutador (por cima do corpo)
var _corda_costas: AnimSprite  # corda ATRÁS do lutador (por baixo do corpo)
# Pular corda: laço de 6 quadros (um giro completo: atrás, acima da cabeça, na frente por cima do corpo, sob os pés,
# atrás de novo, aterrissa). Enquanto o jogador clica, o laço CONTINUA (a corda nunca para no meio); passado o tempo sem
# clique, o giro termina e o lutador assenta no quadro 6 (corda frouxa na frente). Sprites: tools/art/golpes.json (rope).
const CORDA_QUADROS := [0, 1, 2, 3, 4, 5]
const CORDA_FPS := 24.0
const CORDA_REPOUSO := 6
const CORDA_FOLGA_MS := 480  # sem clique por este tempo = a corda assenta
var _corda_girando := false
var _corda_ultimo_clique := 0
var _sombra_lutador: Sprite2D
var _pessoas: Dictionary = {}  # gerador -> Array[{sprite, sombra, visivel}]
var _fx_impacto: Array[AnimSprite] = []
var _fx_critico: Array[AnimSprite] = []
var _fx_poeira: Array[AnimSprite] = []
var _numeros: Array[Numero] = []
var _fx_i := 0
var _desvio_i := 0
var _desvio_auto := 0
var _ordem := 0
var _metronomo: AnimSprite  # prop da prateleira (Fase 4): some no nível 0, oscila no andamento do Metrônomo
var _acc_m := 0.0  # tempo desde o último auto-soco (só para sincronizar o pêndulo; o tique de verdade é do GameState)
var _socos_m := 0

var _pos_clique := PONTO_PADRAO
var _corrida := 0.0  # tempo restante de corrida na esteira
var _shake_t := 0.0
var _shake_dur := 0.1
var _shake_amp := 1
var _proxima_piscada := 6.0
var _rng := RandomNumberGenerator.new()
var _montado := false

# Fase 6a: Osmar na garagem, gesto do 1Âº lutador e parede da memÃ³ria.
const OSMAR_FOLHAS := {"idle": "coach_idle", "look": "coach_look", "talk": "coach_talk"}
const NO_COVER := Rect2(310, 180, 52, 94)
var _osmar: AnimSprite
var _sombra_osmar: Sprite2D
var _osmar_estado := ""
var _coach_falando := false
var _gesto: Gesto
var _gesto_sprite := ""
var _parede: Dictionary = {}  # objeto -> {sprite, rect, dica}
var _recorte: AnimSprite  # 7a2: recorte de jornal do vulto (garagem e academia, campanha 2 em diante)
var _recorte_rect := Rect2()  # área do hover (vazio = não desenhado)
var _recorte_zoom: TextureRect  # dica de zoom: o recorte grande, só com o mouse em cima
var _cartaz: AnimSprite  # 8a1: cartaz da Liga Regional do Vale (academia, depois de abrir a liga)
var _cartaz_rect := Rect2()
var _cartaz_zoom: TextureRect
var _clipvale: AnimSprite  # 8a2: o recorte do Vale emoldurado (parede do centro)
var _clipvale_rect := Rect2()
var _clipvale_zoom: TextureRect
var _envelope: AnimSprite  # 8a2: envelope PROPOSTA no chão (garagem, academia e centro) enquanto o patrocínio está "offered"
var _envelope_rect := Rect2()
var _capuz: AnimSprite  # Ronda: o capuz no prego (parede; hover com o texto do capuz; clique abre a Ronda)
var _capuz_rect := Rect2()
var _capuz_sobre := false
var _capuz_clicavel := false
var _capuz_t := 0.0
var _prox_brilho_envelope := 3.0
var _patro_anterior := ""

# 6d2: aparelho que não foi comprado é invisível (sem fita, silhueta nem cadeado): comprou = só a caixa; abriu = o aparelho.
var _caixas: Dictionary = {}  # item -> CaixaSala
var _revelar: Dictionary = {}  # aparelho que acabou de sair da caixa e ainda não "nasceu"
var janela_aberta := false  # a Garagem avisa: árvore, aposentar, prévia ou luta por cima (a caixa não recebe clique)
var _fx_poeira_chegada: AnimSprite
var _fx_brilho_chegada: AnimSprite
var _fx_poeira_pequena: AnimSprite

# Fase 6b1: palco da cena de passar o posto, John mentor sentado no caixote e câmera da cena.
const MENTOR_FOLHA := "john_sit_rest"
const MENTOR_TOQUES := "mentor_first_taps"
var cena: CenaSala
var _cena_ativa := false  # a cena manda na sala: foco no saco, jogador/gente/Osmar escondidos conforme `stage.hide`
var _cena_oculta: Array = []
var _caixote_cena := false  # a cena já mostrou o caixote (antes do fim dela o caixote não existe)
var _mentor: AnimSprite
var _mentor_sombra: Sprite2D
var _caixote: Sprite2D
var _mentor_visivel := false
var _mentor2: AnimSprite  # Fase 6b2: o último que passou o posto, parado no canto (sem clique, gesto nem fala)
var _mentor2_sombra: Sprite2D
var _mentor2_visivel := false
var _mentor2_chave := ""
var _mentor2_nome := ""
var _dica_m2 := false  # a dica do 2º mentor está ancorada na parede
const DICA_M2_X := 138  # x da borda esquerda da dica (dentro da sala útil)
var _mentor_pose := ""
# Fase 6c1: quem está no caixote (John ou o último que passou o posto), foto antiga da academia, saco da cena e cena sem controle preso.
var _mentor_quem := ""  # "first" | "last" (quem a sala desenha sentado)
var _mentor_chave := ""
var _mentor_look: Dictionary = {}
var _mentor_campanha := 0
var _cena_livre := false  # a saída do John: o jogador continua no controle, só o stage.hide vale
var _saco_da_cena := false  # o saco só aparece na cena da academia quando ela o pendura
var _toques_id := 0
var _cam_escala := 1
var _cam_rect := _area


## Retângulo da sala na tela (manifest.room_rect). Sem o campo, a sala de antes da 6d2.
static func area() -> Rect2:
	var r: Array = UiTema.manifest().get("room_rect", [])
	if r.size() == 4:
		return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	return AREA_ANTIGA


func _ready() -> void:
	_rng.randomize()
	position = _area.position
	size = _area.size
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	sfx = Sfx.new()
	add_child(sfx)
	_montar()
	GameState.clicou.connect(_ao_clicar)
	GameState.foco_mudou.connect(func(_a: String) -> void: _aplicar_layout())
	GameState.melhoria_comprada.connect(_ao_melhorar)
	GameState.gerador_mudou.connect(_ao_gerador)
	GameState.gerador_pago_mudou.connect(_ao_gerador_pago)
	GameState.luva_mudou.connect(_ao_luva)
	GameState.carreira_mudou.connect(_ao_carreira)
	GameState.auto_socou.connect(_ao_auto_socou)
	GameState.evento_dourado.connect(_ao_evento_dourado)
	GameState.frenesi_mudou.connect(_ao_frenesi_mudou)
	GameState.bolsa_paga.connect(_ao_bolsa_paga)
	GameState.metronomo_mudou.connect(_ao_metronomo)
	GameState.caixa_criada.connect(_ao_caixa_criada)
	GameState.caixa_batida.connect(_ao_caixa_batida)
	GameState.caixa_aberta.connect(_ao_caixa_aberta)
	GameState.caixas_mudaram.connect(_sincronizar_caixas)
	GameState.economia_mudou.connect(func() -> void:
		_sincronizar_caixas())
	GameState.local_mudou.connect(_ao_local)
	_patro_anterior = GameState.patrocinio_estado
	GameState.patrocinio_mudou.connect(_ao_patrocinio)  # 8a2: envelope, cartaz com a marca, aviso da proposta
	GameState.arte_mudou.connect(_ao_arte)
	GameState.capuz_mudou.connect(func(_n: String) -> void: _atualizar_capuz())  # Ronda
	GameState.lenda_mudou.connect(func(_n: int) -> void: _atualizar_recorte())  # Ronda: o recorte troca de manchete e de desenho
	GameState.gesto_pedido.connect(_ao_gesto_pedido)
	GameState.gesto_cancelado.connect(_ao_gesto_cancelado)
	GameState.marco_gravado.connect(func(_id: String) -> void:
		_atualizar_parede()
		_atualizar_osmar()
		_atualizar_mentor())
	GameState.abertura_mudou.connect(func(_e: String) -> void: _atualizar_osmar())
	GameState.toques_mentor_pedidos.connect(_ao_toques_pedidos)
	GameState.toques_mentor_cancelados.connect(_ao_toques_cancelados)
	GameState.sucessao_mudou.connect(func(_e: String) -> void: _atualizar_mentor())
	_local_anterior = GameState.local_id
	_aplicar_layout()
	_atualizar_pessoas(false)
	_aplicar_metronomo()
	_sincronizar_caixas()
	_montado = true


# --- Montagem ---

func _montar() -> void:
	_mundo = Node2D.new()
	_mundo.position = -_area.position
	_mundo.z_index = 100  # os z negativos do fundo ficam acima do ColorRect da tela
	add_child(_mundo)

	_bg = _novo_estatico("garage_bg", -100)
	_bg_nome = "garage_bg"
	# Metrônomo na prateleira do fundo: depois do fundo e antes das pessoas (nada passa na frente dele).
	_metronomo = _novo_anim("metronome_l1", "", -60)
	_metronomo.position = UiTema.pos("metronome_l1")
	_metronomo.visible = false
	_corrente = Corrente.new()
	_corrente.textura = UiTema.textura("bag_chain_tile")
	_corrente.z_index = -35
	_mundo.add_child(_corrente)

	_seta = Seta.new()
	_seta.z_index = 700
	_mundo.add_child(_seta)

	_lampada = _novo_anim("lamp", "", -50)
	_lampada.position = UiTema.pos("lamp")
	for chave in ["tubo_esq", "tubo_dir"]:
		var tubo := _novo_anim("gym_tube", chave, -50)
		tubo.visible = false
		_tubos.append(tubo)

	_corda_prego = _novo_anim("rope_l0_idle", "prego", -40)
	_saco = _novo_anim("bag_l0_idle", "centro", 0)
	_esteira = _novo_anim("treadmill_l0_idle", "centro", 0)
	_lutador = _novo_anim(_f("fighter_idle"), "", 0)
	_lutador.position = UiTema.pos("fighter_idle", "foco_saco")
	_corda_giro = _novo_anim("rope_l0_swing", "foco_corda", 0)
	_corda_giro.visible = false
	_corda_costas = _novo_anim("rope_l0_swing_back", "foco_corda", 0)
	_corda_costas.visible = false
	# Aparelhos das artes (Fase 5): só são desenhados na carreira da arte e depois de comprados.
	_pera = _novo_anim("speed_bag_l0_wall", "parede", -40)
	_pera.visible = false
	_boneco = _novo_anim("grappling_dummy_l0_rest", "canto", 0)
	_boneco.visible = false
	_chute = _novo_anim("kick_bag_l0_rest", "canto", 0)
	_chute.visible = false
	_corrente_chute = Corrente.new()
	_corrente_chute.textura = UiTema.textura("bag_chain_tile")
	_corrente_chute.z_index = -34
	_corrente_chute.visible = false
	_mundo.add_child(_corrente_chute)

	_sombra_lutador = Sprite2D.new()
	_sombra_lutador.texture = UiTema.textura("floor_shadow")
	_mundo.add_child(_sombra_lutador)

	for gid in _ids_geradores():
		var lista: Array = []
		var nomes: Array = UiTema.manifest().get("by_data_id", {}).get(gid, {}).get("people", [])
		for n in nomes:
			var sp := _novo_anim(str(n), "", 0)
			sp.position = UiTema.pos(str(n))
			sp.z_index = int(sp.position.y)
			sp.tocar([0, 1, 2, 3], float(UiTema.sprite(str(n)).get("fps", 5.0)), true)
			var sombra := Sprite2D.new()
			sombra.texture = UiTema.textura("floor_shadow")
			sombra.position = sp.position + Vector2(0, -1)
			sombra.z_index = sp.z_index - 1
			_mundo.add_child(sombra)
			sp.visible = false
			sombra.visible = false
			lista.append({"sprite": sp, "sombra": sombra, "visivel": false})
		_pessoas[gid] = lista

	for i in POOL_FX:
		_fx_impacto.append(_novo_fx("fx_impact"))
		_fx_critico.append(_novo_fx("fx_crit"))
		_fx_poeira.append(_novo_fx("fx_dust"))

	for i in POOL_NUMEROS:
		_numeros.append(Numero.new(_mundo))

	_fx_poeira_chegada = _novo_fx("fx_arrive_dust")
	_fx_brilho_chegada = _novo_fx("fx_arrive_sparkle")
	_fx_poeira_pequena = _novo_fx("fx_arrive_dust_small")
	_montar_osmar()
	_montar_parede()
	_gesto = Gesto.new()
	add_child(_gesto)
	_montar_mentor()
	cena = CenaSala.new()
	cena.sala = self
	_mundo.add_child(cena)


func _novo_estatico(nome: String, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.texture = UiTema.textura(nome)
	s.position = UiTema.pos(nome)
	s.z_index = z
	_mundo.add_child(s)
	return s


func _novo_anim(nome: String, chave_pos: String, z: int) -> AnimSprite:
	var a := AnimSprite.new()
	a.definir(nome)
	if chave_pos != "":
		a.position = UiTema.pos(nome, chave_pos)
	a.z_index = z
	_mundo.add_child(a)
	return a


func _novo_fx(nome: String) -> AnimSprite:
	var a := _novo_anim(nome, "", Z_FX)
	a.visible = false
	return a


# --- Layout por foco e nível visual ---

func _aplicar_layout() -> void:
	_aplicar_local()
	var foco := _foco()
	var nb := GameState.nivel_visual(SACO)
	var nr := GameState.nivel_visual(CORDA)
	var ne := GameState.nivel_visual(ESTEIRA)

	# Saco: no centro (foco) ou à esquerda. Na academia os aparelhos básicos usam o sprite com sufixo _gym (_n).
	var nome_saco := _n("bag_l%d_idle" % nb) if foco == SACO else _n("bag_l%d_side" % nb)
	var chave := "centro" if foco == SACO else "lado_esquerdo"
	_matar_balanco_saco()
	_saco.definir(nome_saco)
	_saco.position = UiTema.pos(nome_saco, chave)
	_saco.z_index = int(_saco.position.y) + int(UiTema.sprite(nome_saco).get("sort_y_offset", 0))
	_saco.tocar([0, 1, 2, 3], 3.0, true)
	_corrente.x = _saco.position.x - 1.0
	_corrente.y_fim = _saco.position.y
	_corrente.queue_redraw()

	# Corda: no prego (sem foco) ou em uso pelo lutador.
	_corda_prego.definir(_n("rope_l%d_idle" % nr))
	_corda_prego.position = UiTema.pos(_n("rope_l%d_idle" % nr), "prego")
	_corda_prego.visible = foco != CORDA and GameState.aparelho_montado(CORDA)  # 6d2: sem corda, nada no prego
	_corda_giro.visible = false
	_corda_costas.visible = false

	# Esteira: no centro (foco) ou à direita.
	var nome_esteira := _n("treadmill_l%d_idle" % ne) if foco == ESTEIRA else _n("treadmill_l%d_side" % ne)
	var chave_e := "centro" if foco == ESTEIRA else "lado_direito"
	_esteira.definir(nome_esteira)
	_esteira.position = UiTema.pos(nome_esteira, chave_e)
	_esteira.z_index = int(_esteira.position.y)
	_esteira.parar(0)
	_esteira.visible = GameState.aparelho_montado(ESTEIRA)  # 6d2: sem esteira, nada no chão
	_corrida = 0.0

	_aplicar_arte(PERA, foco)
	_aplicar_arte(BONECO, foco)
	_aplicar_arte(SACO_CHUTE, foco)
	_pose_repouso()
	_esconder_reveladas()
	_ocultar_da_cena()


# Lutador parado conforme o foco.
func _pose_repouso() -> void:
	var foco := _foco()
	# Voltar à pose parada encerra qualquer giro da corda: o fim do giro (que zerava a marca) não vai mais chegar.
	_corda_girando = false
	_corda_giro.visible = false
	_corda_costas.visible = false
	match foco:
		SACO, PERA, BONECO, SACO_CHUTE:  # a pera, o boneco e o saco de chute usam o fighter_idle no ponto do saco (303,272)
			_lutador.definir(_f("fighter_idle"))
			_lutador.position = UiTema.pos("fighter_idle", "foco_saco")
			_lutador.z_index = int(_lutador.position.y)
			_lutador.tocar([0, 1, 2, 3], 4.0, true)
		CORDA:
			# Parado segurando a corda: quadro de aterrissagem + corda frouxa na frente, mesmo pivô.
			_lutador.definir(_f("fighter_rope"))
			_lutador.position = UiTema.pos("fighter_rope", "foco_corda")
			_lutador.z_index = int(_lutador.position.y)
			_lutador.parar(CORDA_REPOUSO)
			var nr := GameState.nivel_visual(CORDA)
			_corda_giro.definir(_n("rope_l%d_swing" % nr))
			_corda_giro.position = UiTema.pos(_n("rope_l%d_swing" % nr), "foco_corda")
			_corda_giro.z_index = _lutador.z_index + 1
			_corda_giro.parar(CORDA_REPOUSO)
			_corda_giro.visible = true
			_corda_costas.definir(_n("rope_l%d_swing_back" % nr))
			_corda_costas.position = UiTema.pos(_n("rope_l%d_swing_back" % nr), "foco_corda")
			_corda_costas.z_index = _lutador.z_index - 1
			_corda_costas.parar(CORDA_REPOUSO)
			_corda_costas.visible = true
		_:
			_lutador.definir(_f("fighter_run"))
			_lutador.position = UiTema.pos("fighter_run", "foco_esteira")
			_lutador.z_index = _esteira.z_index + 1
			_lutador.parar(0)
			var ne := GameState.nivel_visual(ESTEIRA)
			_esteira.definir(_n("treadmill_l%d_idle" % ne))
			_esteira.position = UiTema.pos(_n("treadmill_l%d_idle" % ne), "centro")
			_esteira.parar(0)
	_sombra_lutador.visible = foco != ESTEIRA
	_sombra_lutador.position = _lutador.position + Vector2(0, -1)
	_sombra_lutador.z_index = _lutador.z_index - 1


## Nome do sprite com o sufixo do local (academia: "_gym", se existir no manifest).
func _n(base: String) -> String:
	return UiTema.com_local(base)


## Fundo e luz do local atual (manifest.by_data_id[local]): garagem = garage_bg + lâmpada; academia = gym_bg + 2 tubos.
func _aplicar_local() -> void:
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get(GameState.local_id, {})
	var nome := str(info.get("bg", "garage_bg"))
	if nome != _bg_nome and not UiTema.sprite(nome).is_empty():
		_bg_nome = nome
		_bg.texture = UiTema.textura(nome)
		_bg.position = UiTema.pos(nome)
	var tubos := str(info.get("light", "lamp")) == "gym_tube"
	_lampada.visible = not tubos and not bool(info.get("no_lamp", false))  # 8a2: no centro o fundo já tem os painéis de LED (sem lâmpada)
	for t in _tubos:
		t.visible = tubos
	_atualizar_osmar()
	_atualizar_parede()


## Pera (Boxe) e boneco (Jiu-jitsu): só existem na carreira da arte e depois de comprados. No foco ficam no centro
## (em pé / sentado); fora dele, a pera na parede e o boneco deitado no canto. Aparelho de outra arte: nada é desenhado.
func _aplicar_arte(id: String, foco: String) -> void:
	var a: AnimSprite = _anim_do(id)
	var base := "speed_bag" if id == PERA else ("kick_bag" if id == SACO_CHUTE else "grappling_dummy")
	var existe := GameState.estado_aparelho(id) == "owned" or false
	a.visible = existe
	if id == SACO_CHUTE:
		_corrente_chute.visible = existe and foco == id
	if not existe:
		return
	var n := GameState.nivel_visual(id)
	if foco == id:
		var nome := _n("%s_l%d_idle" % [base, n])  # 8a2: o centro tem a versão _center também no foco
		a.definir(nome)
		a.position = UiTema.pos(nome, "centro")
		a.z_index = int(UiTema.sprite(nome).get("sort_y", a.position.y))
		if id == PERA:
			a.tocar([0, 1], 2.0, true)  # balanço leve
		elif id == SACO_CHUTE:
			a.tocar([0, 1, 2, 3], 3.0, true)  # balanço lento do saco pendurado
			_corrente_chute.x = a.position.x - 1.0
			_corrente_chute.y_fim = a.position.y
			_corrente_chute.queue_redraw()
		else:
			a.parar(0)
	else:
		var nome := _n("%s_l%d_%s" % [base, n, "wall" if id == PERA else "rest"])
		a.definir(nome)
		a.position = UiTema.pos(nome, "parede" if id == PERA else "canto")
		a.z_index = int(UiTema.sprite(nome).get("z", -40)) if id == PERA else int(UiTema.sprite(nome).get("sort_y", 270))
		a.parar(0)


func _atualizar_pessoas(animar: bool) -> void:
	for gid in _pessoas:
		var n := GameState.pessoas_desenhadas(gid)
		var lista: Array = _pessoas[gid]
		for i in lista.size():
			var d: Dictionary = lista[i]
			var deve := n > i
			if deve == d.visivel:
				continue
			d.visivel = deve
			d.sprite.visible = deve
			d.sombra.visible = deve
			if deve and animar:
				_entrada_pessoa(d.sprite)


func _entrada_pessoa(sp: AnimSprite) -> void:
	var y0 := sp.position.y
	sp.position.y = y0 - 14.0
	sp.modulate = Color(2.2, 2.2, 2.2)
	var tw := sp.create_tween()
	tw.set_parallel(true)
	tw.tween_property(sp, "position:y", y0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(sp, "modulate", Color.WHITE, 0.4)
	_poeira(Vector2(sp.position.x + 3.0, y0 - 2.0))


# --- Entrada do mouse ---

func _gui_input(event: InputEvent) -> void:
	if GameState.sucessao_estado() != "none" or GameState.cena_sala != "":
		accept_event()  # Fase 6b1 e 6c1 (chegada à academia): durante a cena e a criação do discípulo a sala não recebe clique (a campanha está parada)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not ALVO.has_point(event.position + position):
			GameState.registrar_clique()  # clique fora do alvo: cancela o gesto e zera a sala parada
		_clique_em(event.position + position)
		accept_event()
	elif event is InputEventMouseMotion:
		_hover_em(event.position + position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_sair_hover()


func _clique_em(p: Vector2) -> void:
	if _evento_rect.size != Vector2.ZERO and _evento_rect.has_point(p):
		var era_bolsa := _evento_tipo == "crew"
		if GameState.pegar_evento_dourado():
			_esconder_evento()  # na bolsa, o aviso já saiu pelo sinal bolsa_paga (_ao_bolsa_paga)
			if not era_bolsa:
				var n := _pegar_numero()
				_ordem += 1
				n.definir_z(Z_NUMEROS + 1500 + _ordem % 900)
				n.iniciar(UiTema.txt("frenzy_start", "FRENESI X{n}!", {"n": int(GameState.FRENESI_MULT)}), UiTema.Y1, true, "", p + Vector2(0, -10), 1.0, 26.0)
			sfx.compra()
			_tremer(1, 0.12)
		return
	if ALVO.has_point(p):
		_pos_clique = p
		GameState.clicar()
		return
	# 8a2: o envelope PROPOSTA no chão abre o contrato (qualquer hora com a sala livre; fechar a janela não tira o envelope).
	if _envelope != null and _envelope.visible and _envelope_rect.has_point(p):
		if caixa_liberada():
			sfx.foco()
			envelope_clicado.emit()
		return
	# Ronda: o capuz no prego abre a Ronda (só com a sala livre: o GameState diz se está clicável).
	if _capuz != null and _capuz.visible and _capuz_rect.has_point(p):
		if bool(GameState.capuz_info().get("clickable", false)) and caixa_liberada():
			sfx.foco()
			capuz_clicado.emit()
		return
	# 6c2: o mural da parede abre a janela do mural (qualquer hora com a sala livre).
	if _mural != null and _mural.visible and _mural_rect.has_point(p):
		if caixa_liberada():
			sfx.foco()
			mural_clicado.emit()
		return
	# Caixa da escola: o clique vai só para a caixa (não treina). Nunca com janela aberta; Espaço nunca chega aqui.
	var cx := _caixa_em(p)
	if cx != "":
		_bater_caixa(cx)
		return
	# Clique em aparelho lateral só troca o foco (não gera treino). 6d2: aparelho não comprado não existe na sala.
	for ap in GameState.aparelhos_da_carreira():
		var id := str(ap.id)
		if GameState.aparelho_montado(id) and id != GameState.foco and _area_lateral(id).has_point(p):
			GameState.definir_foco(id)
			sfx.foco()
			return
	if not NO_COVER.has_point(p):
		clique_vazio.emit()  # nada foi pego: completa o balão que está escrevendo


## Treino pelo teclado (Espaço): igual a um clique no alvo central (mesmo `GameState.clicar()`, mesmo número flutuante,
## animação, som e tremida), no ponto padrão do alvo. Devolve false se o jogo recusou (luta, fim de carreira).
func treinar_pelo_teclado() -> bool:
	_pos_clique = PONTO_PADRAO
	return not GameState.clicar().is_empty()


## O sprite que representa o aparelho na sala.
func _anim_do(id: String) -> AnimSprite:
	match id:
		SACO:
			return _saco
		CORDA:
			return _corda_prego
		PERA:
			return _pera
		BONECO:
			return _boneco
		SACO_CHUTE:
			return _chute
	return _esteira


func _area_lateral(id: String) -> Rect2:
	var s: AnimSprite = _anim_do(id)
	var tam := UiTema.tamanho_quadro(s.nome_sprite)
	return Rect2(s.position - UiTema.pivo(s.nome_sprite), tam)


# --- Juice do clique ---

func _ao_clicar(ganho: float, critico: bool, aparelho: String, atributo: String, texto: String) -> void:
	var p := _pos_clique
	_pos_clique = PONTO_PADRAO
	var partes := ganhos_por_atributo(ganho, aparelho)
	if partes.size() > 1:
		_mostrar_numeros_divididos(p, partes, critico, texto)  # 6d: um número por atributo que subiu
	else:
		_mostrar_numero(p, ganho, critico, atributo, texto)
	_reagir(aparelho, critico)
	_tremer(2 if critico else 1, 0.16 if critico else 0.07)
	sfx.golpe(aparelho, critico)
	if critico:
		_piscar_luz(true)


func _mostrar_numero(p: Vector2, ganho: float, critico: bool, atributo: String, texto: String) -> void:
	var n := _pegar_numero()
	var nome := str(GameState.dados.atributo_info(atributo).get("name", atributo)).to_upper()
	var dx := float(DESVIOS_X[_desvio_i % DESVIOS_X.size()])
	_desvio_i += 1
	var larg := UiTema.largura("+%s %s!" % [NumberFormat.fmt(ganho), nome]) * (2.0 if critico else 1.0)
	var x := _x_do_numero(p.x + dx, larg)
	var y := clampf(p.y - 6.0, _area.position.y + 40.0, _area.end.y - 8.0)
	_ordem += 1
	# Mais recente por cima; crítico sempre acima dos normais (z fica abaixo do cursor, 4000).
	n.definir_z(Z_NUMEROS + (1000 if critico else 0) + _ordem % 900)
	if critico:
		# 6d3: o crítico grande (2x) leva o nome inteiro do atributo ("+3 RESISTÊNCIA!"); o x é limitado pela largura real.
		n.iniciar("+%s %s!" % [NumberFormat.fmt(ganho), nome], UiTema.R3, true, texto, Vector2(x, y - 4.0), 0.85, 34.0)
	else:
		n.iniciar("+%s %s" % [NumberFormat.fmt(ganho), nome], UiTema.cor_atributo(atributo).lerp(UiTema.WHITE, 0.55 if atributo == "strength" else 0.25),
			false, "", Vector2(x, y), 0.55, 30.0)
	_afastar_antigos(n, critico)


## 6d3: x do número sem passar da borda da sala: o mínimo de antes (60) ou metade da largura real do texto + 4.
func _x_do_numero(x: float, largura: float) -> float:
	var m := maxf(60.0, largura / 2.0 + 4.0)
	return clampf(x, _area.position.x + m, _area.end.x - m)


## Fase 6d: quanto cada atributo subiu neste clique: [{atributo, ganho}] do maior para o menor (empate: ordem do jogo),
## só os que subiram (e aparecem na tela com valor), no máximo 3. A conta é a mesma do GameState (ganho x fração da `divisao_aparelho`); aparelho de
## um atributo só devolve 1 item (e a sala usa o número de sempre).
static func ganhos_por_atributo(ganho: float, aparelho: String) -> Array:
	var div: Dictionary = GameState.divisao_aparelho(aparelho)
	var ordem: Array = GameState.dados.atributos
	var lista: Array = []
	for a in div:
		var g := ganho * float(div[a])
		if g > 0.0 and NumberFormat.fmt(g) != "0":  # fatia que aparece como "+0" não conta como "subiu" na tela
			lista.append({"atributo": str(a), "ganho": g})
	lista.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		if not is_equal_approx(float(x.ganho), float(y.ganho)):
			return float(x.ganho) > float(y.ganho)
		return ordem.find(x.atributo) < ordem.find(y.atributo))
	return lista.slice(0, NUMEROS_MAX_POR_CLIQUE)


## Escala (inteira, para não borrar o pixel art) de cada número: o maior e os quase iguais a ele saem grandes (2x),
## os menores ficam pequenos (1x).
static func escala_do_ganho(ganho: float, maior: float) -> float:
	return 2.0 if maior > 0.0 and ganho / maior >= ESCALA_GRANDE_A_PARTIR else 1.0


## Aparelho de vários atributos (Jiu-jitsu etc.): um número por atributo, na cor dele, empilhados subindo do ponto do
## clique (o maior embaixo, perto do clique). No crítico o maior leva o vermelho, o "!" e a frase de sabor.
func _mostrar_numeros_divididos(p: Vector2, partes: Array, critico: bool, texto: String) -> void:
	var maior := float(partes[0].ganho)
	var escalas: Array[float] = []
	var altura_total := 0.0
	for i in partes.size():
		var e := escala_do_ganho(float(partes[i].ganho), maior)
		escalas.append(e)
		altura_total += 7.0 * e + (NUMEROS_FOLGA if i > 0 else 0.0)
	var dx := float(DESVIOS_X[_desvio_i % DESVIOS_X.size()])
	_desvio_i += 1
	var larg_max := 0.0
	for i in partes.size():
		var nm := str(GameState.dados.atributo_info(partes[i].atributo).get("name", partes[i].atributo)).to_upper()
		larg_max = maxf(larg_max, UiTema.largura("+%s %s!" % [NumberFormat.fmt(float(partes[i].ganho)), nm]) * escalas[i] + (36.0 if i > 0 else 0.0))
	var x := _x_do_numero(p.x + dx, larg_max)
	var y := clampf(p.y - 6.0, _area.position.y + 40.0 + altura_total, _area.end.y - 8.0)
	var y_i := y - (4.0 if critico else 0.0)
	_ordem += 1
	for i in partes.size():
		var n := _pegar_numero()
		var a: String = partes[i].atributo
		var nome_a := str(GameState.dados.atributo_info(a).get("name", a)).to_upper()  # 6d3: nome inteiro, não a sigla
		var rotulo := "+%s %s" % [NumberFormat.fmt(float(partes[i].ganho)), nome_a]
		n.definir_z(Z_NUMEROS + (1000 if critico else 0) + (_ordem * 3 + (partes.size() - i)) % 900)
		var xi := x + (0.0 if i == 0 else (-18.0 if i % 2 == 1 else 18.0))
		if i > 0:
			y_i -= (7.0 * escalas[i - 1] + 7.0 * escalas[i]) / 2.0 + NUMEROS_FOLGA
		if critico and i == 0:
			n.iniciar(rotulo + "!", UiTema.R3, true, texto if partes.size() == 1 else "", Vector2(xi, y_i), 0.85, 34.0)
		else:
			var cor := UiTema.cor_atributo(a).lerp(UiTema.WHITE, 0.55 if a == "strength" else 0.25)
			# A frase do crítico fica no topo da pilha (a linha extra nasce acima do número que a leva).
			var frase := texto if critico and i == partes.size() - 1 else ""
			n.iniciar(rotulo, cor, false, frase, Vector2(xi, y_i), 0.6 if escalas[i] > 1.0 else 0.5, 30.0, 1.0, escalas[i])
		_afastar_antigos(n, critico and i == 0)


## Empurra para cima os números antigos que ficariam sob o novo (crítico empurra tudo; normal só os normais).
func _afastar_antigos(novo: Numero, critico: bool) -> void:
	afastar(_numeros, novo, critico)


## Mesma regra para a garagem e para a arena: o número novo fica por cima e os que estavam embaixo dele sobem
## (mais de um, em cascata, para nenhum ficar encavalado).
static func afastar(numeros: Array, novo: Numero, critico: bool) -> void:
	for _volta in 10:
		var mexeu := false
		for i in numeros.size():
			var a: Numero = numeros[i]
			if not a.ativo:
				continue
			for j in range(i + 1, numeros.size()):
				var b: Numero = numeros[j]
				if not b.ativo:
					continue
				var com_novo := a == novo or b == novo
				var outro: Numero = b if a == novo else a
				# Garagem: o número normal não empurra os grandes (crítico fica no lugar do clique).
				if com_novo and not critico and outro.grande:
					continue
				if not a.retangulo().grow(2.0).intersects(b.retangulo()):  # a fonte de contorno ocupa 1 px a mais em cada lado
					continue
				# O novo nunca se mexe; entre dois antigos, o mais velho (mais adiantado) sobe.
				var sobe: Numero = outro if com_novo else (a if a.progresso() > b.progresso() else b)
				var fica: Numero = novo if com_novo else (b if sobe == a else a)
				sobe.empurrar(sobe.retangulo().end.y - fica.retangulo().position.y + 3.0)
				mexeu = true
		if not mexeu:
			return


# --- Metrônomo (Fase 4) ---

## O pêndulo e o prop da prateleira seguem o nível atual (0 = sem Metrônomo, sem prop).
func _aplicar_metronomo() -> void:
	var nivel := GameState.nivel_metronomo
	_metronomo.visible = nivel > 0
	if nivel <= 0:
		return
	_metronomo.definir("metronome_l%d" % clampi(nivel, 1, 3))  # acima de 3 níveis no data/: usa o l3
	_metronomo.position = UiTema.pos("metronome_l1")


func _ao_metronomo(nivel: int) -> void:
	_acc_m = 0.0
	_socos_m = 0
	var apareceu := not _metronomo.visible and nivel > 0
	_aplicar_metronomo()
	if not _montado or nivel <= 0:
		return
	sfx.moeda()
	_metronomo.modulate = Color(2.6, 2.6, 2.6)
	_metronomo.create_tween().tween_property(_metronomo, "modulate", Color.WHITE, 0.5)
	var topo := _metronomo.position + Vector2(0, -34)
	var nome := str(GameState.metronomo_atual().get("name", GameState.lutas.metronomo.get("name", ""))).to_upper()
	_mostrar_texto(topo, nome, UiTema.Y1)
	if apareceu:
		_critico_fx(_metronomo.position + Vector2(0, -12))


## Auto-soco: o mesmo golpe do clique, só que mais leve. O lutador soca (jab com a luva do cursor), o número é curto
## e transparente, o som é baixo e a tela NÃO treme.
func _ao_auto_socou(ganho: float, critico: bool, aparelho: String, atributo: String, _texto: String) -> void:
	_acc_m = 0.0
	_socos_m += 1
	var n := _pegar_numero()
	var dx := float([-26, 26, -12, 12][_desvio_auto % 4])
	_desvio_auto += 1
	var x := clampf(PONTO_PADRAO.x + dx, _area.position.x + 60.0, _area.end.x - 60.0)
	_ordem += 1
	n.definir_z(Z_NUMEROS - 300 + _ordem % 300)  # abaixo de qualquer número do jogador
	var cor := UiTema.cor_atributo(atributo).lerp(UiTema.WHITE, 0.25)
	var texto := "+%s" % NumberFormat.fmt(ganho)
	if critico:
		texto += "!"
		cor = UiTema.R3
	n.iniciar(texto, cor, false, "", Vector2(x, PONTO_PADRAO.y - 14.0), 0.5, 22.0, 0.6)
	_afastar_antigos(n, false)
	_reagir(aparelho, false)
	sfx.golpe_auto(aparelho)


func _pegar_numero() -> Numero:
	var melhor: Numero = _numeros[0]
	for n in _numeros:
		if not n.ativo:
			return n
		if n.progresso() > melhor.progresso():
			melhor = n
	return melhor


func _reagir(aparelho: String, critico: bool) -> void:
	if _gesto != null and _gesto.ativo():
		_gesto.cancelar()
		sfx.cortar_rip()
	_gesto_sprite = ""
	var nb := GameState.nivel_visual(SACO)
	match aparelho:
		SACO:
			# Treino variado: jab com as duas mãos e, de vez em quando, uppercut e golpe lateral (COMBO_SACO).
			var golpe := _proximo_golpe_saco()
			_lutador.definir(_f(golpe))
			_tocar_golpe_saco(golpe)
			_saco.definir(_n("bag_l%d_hit" % nb))
			_saco.tocar([0, 1, 2, 3], 14.0, false, _saco_repouso)
			_balancar_saco(golpe, critico)
			var hp: Array = UiTema.sprite(golpe).get("hit_point", [323, 222])
			_impacto(Vector2(float(hp[0]), float(hp[1])), critico)
		PERA:
			# A pera é bem mais rápida que o saco (5 quadros a 18 fps); o lutador usa o soco normal.
			var np_ := GameState.nivel_visual(PERA)
			_lutador.definir(_f("fighter_punch"))
			_lutador.tocar([1, 2, 3], 18.0, false, _pose_repouso)
			_pera.definir(_n("speed_bag_l%d_hit" % np_))
			_pera.tocar([0, 1, 2, 3, 4], 18.0, false, _pera_repouso)
			_impacto(_ponto_impacto(_pera.nome_sprite, "speed_bag", Vector2(325, 218)), critico)
		SACO_CHUTE:
			# 7b1: chute baixo inteiro a cada clique (6 quadros a 18 fps), canela no ponto de impacto do manifest (326,250).
			# Sem a folha (manifest sem fighter_low_kick), cai no soco de sempre. O objeto do saco comprido é desenhado pela sala (UI/UX).
			var chute := _f("fighter_low_kick")
			if UiTema.sprite(chute).is_empty():
				chute = _f("fighter_punch")
				_lutador.definir(chute)
				_lutador.tocar([1, 2, 3], 18.0, false, _pose_repouso)
			else:
				_lutador.definir(chute)
				_lutador.tocar([0, 1, 2, 3, 4, 5], 18.0, false, _pose_repouso)
			var nk := GameState.nivel_visual(SACO_CHUTE)
			_chute.definir(_n("kick_bag_l%d_hit" % nk))
			_chute.tocar([0, 1, 2, 3], 12.0, false, _chute_repouso)
			var hc: Array = UiTema.sprite(chute).get("hit_point", [326, 250])
			_impacto(Vector2(float(hc[0]), float(hc[1])), critico)
		BONECO:
			# O boneco amassa, tomba e volta (3 quadros a 12 fps). Sem pose de grappling nesta fase: o lutador soca.
			var nd_ := GameState.nivel_visual(BONECO)
			_lutador.definir(_f("fighter_punch"))
			_lutador.tocar([1, 2, 3], 18.0, false, _pose_repouso)
			_boneco.definir(_n("grappling_dummy_l%d_hit" % nd_))
			_boneco.tocar([0, 1, 2], 12.0, false, _boneco_repouso)
			_impacto(_ponto_impacto(_boneco.nome_sprite, "grappling_dummy", Vector2(330, 232)), critico)
		CORDA:
			_corda_ultimo_clique = Time.get_ticks_msec()
			if not _corda_girando:
				_corda_girando = true
				_girar_corda()
			_poeira(UiTema.pos("fx_dust", "corda"))
			if critico:
				_critico_fx(Vector2(336, 232))
		ESTEIRA:
			_lutador.definir(_f("fighter_run"))
			var ne := GameState.nivel_visual(ESTEIRA)
			_esteira.definir(_n("treadmill_l%d_run" % ne))
			if not _esteira.esta_tocando():
				_esteira.tocar([0, 1, 2, 3], 12.0, true)
			if not _lutador.esta_tocando():
				_lutador.tocar([0, 1, 2, 3], 12.0, true)
			_corrida = 0.4
			_poeira(UiTema.pos("fx_dust", "esteira"))
			if critico:
				_critico_fx(Vector2(334, 232))


## Sequência dos golpes no saco: jab direita, jab esquerda, jab direita, jab esquerda, uppercut, jab direita,
## jab esquerda, golpe lateral. Só visual (o ganho do clique não muda). Sprites: tools/art/golpes.json (garage).
const COMBO_SACO := ["fighter_punch", "fighter_punch_b", "fighter_punch", "fighter_punch_b", "fighter_uppercut",
	"fighter_punch", "fighter_punch_b", "fighter_hook"]
var _i_combo := 0
# Evento dourado: o cinturão dourado aparece num ponto sorteado da sala por alguns segundos; clicar liga o FRENESI (x7).
var _evento_spr: AnimSprite
var _evento_rect := Rect2()
var _evento_tipo := "frenzy"  # Fase 5.2: "frenzy" (luva x7) ou "crew" (bolsa da torcida)
var _tween_evento: Tween
var _tween_ouro: Tween
var _rotulo_frenesi: Label
# Reação do saco por golpe: o uppercut o levanta, o golpe lateral o balança para o lado. A corrente acompanha.
var _tween_saco: Tween
var _saco_base := Vector2.ZERO
var _saco_dir := Vector2.ZERO
var _saco_k := 0.0:
	set(v):
		_saco_k = v
		if _saco != null:
			_saco.position = _saco_base + _saco_dir * v
			_corrente.x = _saco_base.x - 1.0 + _saco_dir.x * v * 0.5
			_corrente.y_fim = _saco_base.y + _saco_dir.y * v
			_corrente.queue_redraw()


## Próximo golpe do combo. Se a arte de algum golpe não existir (manifest mexido), cai no jab de sempre.
func _proximo_golpe_saco() -> String:
	var g: String = COMBO_SACO[_i_combo % COMBO_SACO.size()]
	_i_combo += 1
	return g if not UiTema.sprite(g).is_empty() else "fighter_punch"


## Evento dourado: a luva dourada aparece num ponto sorteado, flutua por alguns segundos e espera o clique.
func _ao_evento_dourado(duracao: float) -> void:
	if GameState.modal_aberto:
		return
	# Fase 5.2: o tipo já foi sorteado antes do sinal; o sprite vem dos dados (bolsa da torcida x luva x7).
	_evento_tipo = GameState.evento_dourado_tipo
	var sprite_evento: String = GameState.dados.golden_crew_sprite if _evento_tipo == "crew" else GameState.dados.golden_frenzy_sprite
	if _evento_spr == null:
		_evento_spr = _novo_anim(sprite_evento, "", 950)
	else:
		_evento_spr.definir(sprite_evento)
	var x := _rng.randf_range(maxf(_area.position.x + 50.0, 150.0), minf(_area.end.x - 70.0, 430.0))  # nunca atrás dos painéis (esquerdo e direito)
	var y := _rng.randf_range(_area.position.y + 40.0, _area.position.y + 150.0)
	_evento_spr.position = Vector2(x, y)
	_evento_spr.visible = true
	_evento_spr.modulate = Color.WHITE
	_evento_spr.scale = Vector2.ONE
	_evento_spr.tocar([0, 1, 2], 6.0, true)
	_evento_rect = Rect2(x - 18.0, y - 18.0, 36.0, 34.0)
	if _tween_evento != null and _tween_evento.is_valid():
		_tween_evento.kill()
	_tween_evento = create_tween().set_loops()  # flutua até sumir
	_tween_evento.tween_property(_evento_spr, "position:y", y - 3.0, 0.4).set_trans(Tween.TRANS_SINE)
	_tween_evento.tween_property(_evento_spr, "position:y", y + 3.0, 0.4).set_trans(Tween.TRANS_SINE)
	sfx.foco()


## Bolsa da torcida clicada: aviso dourado (tamanho 1x, cabe na sala) subindo do ponto onde ela estava. Sem FRENESI.
func _ao_bolsa_paga(ganho: float) -> void:
	var centro := _evento_rect.get_center() if _evento_rect.size != Vector2.ZERO else PONTO_PADRAO
	var n := _pegar_numero()
	_ordem += 1
	n.definir_z(Z_NUMEROS + 1500 + _ordem % 900)
	var x := clampf(centro.x, _area.position.x + 100.0, minf(_area.end.x - 100.0, 410.0))
	n.iniciar(UiTema.txt("golden_crew_toast", "", {"n": NumberFormat.fmt(ganho)}), UiTema.Y1, false, "", Vector2(x, centro.y - 6.0), 1.5, 24.0)


## Dica de hover da bolsa da torcida: quanto ela paga agora. A luva x7 não tem dica.
func _texto_bolsa() -> String:
	return UiTema.txt("golden_crew_hover", "", {"nome": UiTema.txt("golden_crew_name", "Bolsa da torcida"),
		"n": NumberFormat.fmt(GameState.valor_bolsa())})


func _esconder_evento() -> void:
	_evento_rect = Rect2()
	if _tween_evento != null and _tween_evento.is_valid():
		_tween_evento.kill()
	if _evento_spr != null:
		_evento_spr.visible = false


func _ao_frenesi_mudou(restante: float) -> void:
	if _rotulo_frenesi == null:
		_rotulo_frenesi = UiTema.rotulo_centrado(self, Rect2(_area.position.x, _area.position.y + 2.0, _area.size.x, 9.0), "", UiTema.Y1, 1, false, "ignore")
		UiTema.ignorar(_rotulo_frenesi, "aviso do FRENESI: texto com o tempo restante, muda a cada segundo", true)
		_rotulo_frenesi.z_index = 980
	_rotulo_frenesi.visible = restante > 0.0
	# Durante o FRENESI o lutador (e as luvas) brilham em dourado, pulsando.
	if _tween_ouro != null and _tween_ouro.is_valid():
		_tween_ouro.kill()
	if restante > 0.0:
		_tween_ouro = create_tween().set_loops()
		_tween_ouro.tween_property(_lutador, "modulate", Color(1.5, 1.2, 0.5), 0.25).set_trans(Tween.TRANS_SINE)
		_tween_ouro.tween_property(_lutador, "modulate", Color(1.15, 1.0, 0.7), 0.25).set_trans(Tween.TRANS_SINE)
	else:
		_lutador.modulate = Color.WHITE


func _balancar_saco(golpe: String, critico: bool) -> void:
	var dir := Vector2.ZERO
	var picos := []
	match golpe:
		"fighter_uppercut":
			dir = Vector2(0, -5)
			picos = [[1.0, 0.06], [-0.25, 0.13], [0.0, 0.12]]
		"fighter_hook":
			dir = Vector2(7, 0)
			picos = [[1.0, 0.07], [-0.55, 0.13], [0.25, 0.11], [0.0, 0.1]]
		_:
			return
	_matar_balanco_saco()
	_saco_base = _saco.position
	_saco_dir = dir * (1.5 if critico else 1.0)
	_saco_k = 0.0
	_tween_saco = create_tween()
	for pico in picos:
		_tween_saco.tween_property(self, "_saco_k", float(pico[0]), float(pico[1])).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween_saco.tween_callback(func() -> void: _saco_k = 0.0)


func _matar_balanco_saco() -> void:
	if _tween_saco != null and _tween_saco.is_valid():
		_tween_saco.kill()
		_saco_dir = Vector2.ZERO
		if _saco != null and _saco_base != Vector2.ZERO:
			_saco.position = _saco_base
			_corrente.x = _saco_base.x - 1.0
			_corrente.y_fim = _saco_base.y
			_corrente.queue_redraw()


## Toca o golpe no lutador. O jab da mão da frente (o original) continua nos quadros 1-3 a 18 fps, como sempre foi. Os
## golpes novos têm quadros de movimento do corpo todo: tocam inteiros, na velocidade do manifest (contato no quadro 2).
func _tocar_golpe_saco(golpe: String) -> void:
	if golpe == "fighter_punch":
		_lutador.tocar([1, 2, 3], 18.0, false, _pose_repouso)
		return
	var sp := UiTema.sprite(golpe)
	var quadros: Array = range(int(sp.get("frames", 4)))
	_lutador.tocar(quadros, float(sp.get("fps", 24.0)), false, _pose_repouso)


## Um giro completo da corda (corpo + camada da frente + camada de trás, no mesmo ritmo).
func _girar_corda() -> void:
	var nr := GameState.nivel_visual(CORDA)
	_lutador.definir(_f("fighter_rope"))
	_lutador.tocar(CORDA_QUADROS, CORDA_FPS, false, _fim_giro_corda)
	_corda_giro.definir(_n("rope_l%d_swing" % nr))
	_corda_giro.visible = true
	_corda_giro.z_index = _lutador.z_index + 1
	_corda_giro.tocar(CORDA_QUADROS, CORDA_FPS)
	_corda_costas.definir(_n("rope_l%d_swing_back" % nr))
	_corda_costas.visible = true
	_corda_costas.z_index = _lutador.z_index - 1
	_corda_costas.tocar(CORDA_QUADROS, CORDA_FPS)


## Fim de um giro: se ainda há cliques recentes, o próximo giro começa na hora (rotação contínua); senão, assenta.
func _fim_giro_corda() -> void:
	if GameState.foco == CORDA and Time.get_ticks_msec() - _corda_ultimo_clique < CORDA_FOLGA_MS:
		_girar_corda()
		return
	_corda_girando = false
	_pose_repouso()


func _saco_repouso() -> void:
	var nb := GameState.nivel_visual(SACO)
	var nome := _n("bag_l%d_idle" % nb) if GameState.foco == SACO else _n("bag_l%d_side" % nb)
	_saco.definir(nome)
	_saco.tocar([0, 1, 2, 3], 3.0, true)


func _pera_repouso() -> void:
	_pera.definir(_n("speed_bag_l%d_idle" % GameState.nivel_visual(PERA)))
	_pera.tocar([0, 1], 2.0, true)


func _chute_repouso() -> void:
	_chute.definir(_n("kick_bag_l%d_idle" % GameState.nivel_visual(SACO_CHUTE)))
	_chute.tocar([0, 1, 2, 3], 3.0, true)


func _boneco_repouso() -> void:
	_boneco.definir(_n("grappling_dummy_l%d_idle" % GameState.nivel_visual(BONECO)))
	_boneco.parar(0)


## Ponto do efeito de impacto: `hit_point` do sprite do golpe; senão o `fx_pos` do manifest do aparelho; senão o padrão.
func _ponto_impacto(sprite_nome: String, aparelho: String, padrao: Vector2) -> Vector2:
	var hp: Array = UiTema.sprite(sprite_nome).get("hit_point", [])
	if hp.is_empty():
		hp = UiTema.manifest().get("by_data_id", {}).get(aparelho, {}).get("fx_pos", [padrao.x, padrao.y])
	return Vector2(float(hp[0]), float(hp[1]))


func _impacto(p: Vector2, critico: bool) -> void:
	_tocar_fx(_fx_impacto[_fx_i % POOL_FX], p)
	_fx_i += 1
	if critico:
		_critico_fx(p)


func _critico_fx(p: Vector2) -> void:
	_tocar_fx(_fx_critico[_fx_i % POOL_FX], p)
	_fx_i += 1


func _poeira(p: Vector2) -> void:
	_tocar_fx(_fx_poeira[_fx_i % POOL_FX], p)
	_fx_i += 1


func _tocar_fx(a: AnimSprite, p: Vector2) -> void:
	a.position = p
	a.visible = true
	var quadros: Array = [0, 1, 2, 3] if a.hframes > 3 else [0, 1, 2]
	a.tocar(quadros, 15.0, false, func() -> void: a.visible = false)


func _tremer(amp: int, dur: float) -> void:
	# Só aumenta: um clique fraco não corta a tremida de um crítico em andamento.
	if _shake_t <= 0.0 or amp >= _shake_amp:
		_shake_amp = amp
		_shake_dur = dur
		_shake_t = dur


# --- Reações a compras ---

func _ao_melhorar(aparelho: String, _melhoria: String, nivel: int) -> void:
	_aplicar_layout()
	sfx.compra()
	var alvo: Node2D = _anim_do(aparelho)
	if aparelho == CORDA and GameState.foco == CORDA:
		alvo = _lutador
	alvo.modulate = Color(2.5, 2.5, 2.5)
	alvo.create_tween().tween_property(alvo, "modulate", Color.WHITE, 0.45)
	var ups: Array = GameState.dados.aparelho(aparelho).get("upgrades", [])
	if nivel >= 1 and nivel <= ups.size():
		var dy := -8
		match aparelho:
			CORDA:
				dy = -4
			ESTEIRA:
				dy = -58
			PERA, BONECO, SACO_CHUTE:
				dy = -60 if GameState.foco == aparelho else 48  # em foco: acima do aparelho; senão logo abaixo do descanso
		_mostrar_texto(alvo.position + Vector2(0, dy), str(ups[nivel - 1].get("name", "")).to_upper(), UiTema.Y1)
	_critico_fx(alvo.position + Vector2(0, 30 if aparelho == SACO else (-30 if aparelho in [PERA, BONECO, SACO_CHUTE] and GameState.foco == aparelho else -10)))


func _mostrar_texto(p: Vector2, texto: String, cor: Color) -> void:
	var n := _pegar_numero()
	n.iniciar(texto, cor, false, "", Vector2(clampf(p.x, _area.position.x + 80.0, _area.end.x - 80.0), maxf(p.y, 60.0)), 1.1, 18.0)


func _ao_gerador(_gerador: String, _qtd: int) -> void:
	_atualizar_pessoas(true)
	sfx.compra()


## Prof. Nelson (gerador pago): entra na sala e o dinheiro faz barulho de moeda.
func _ao_gerador_pago(_gerador: String, _qtd: int) -> void:
	_atualizar_pessoas(true)
	sfx.moeda()


## Luva de loja comprada: o lutador da sala troca de luva na hora (o cursor troca na Garagem) e a mão brilha.
func _ao_luva(_nivel: int, _sufixo: String) -> void:
	if not _montado:
		return
	_pose_repouso()
	sfx.moeda()
	_lutador.modulate = Color(2.4, 2.4, 2.4)
	_lutador.create_tween().tween_property(_lutador, "modulate", Color.WHITE, 0.5)
	_critico_fx(_lutador.position + Vector2(16, -30))


# Nome do sprite do lutador com a luva equipada ("fighter_idle" + "_glove_l1").
func _f(base: String) -> String:
	return UiTema.com_luva(base)


func _ids_geradores() -> Array:
	var ids: Array = []
	for g in GameState.dados.geradores:
		ids.append(g.id)
	for g in GameState.lutas.geradores_pagos:
		ids.append(g.id)
	for g in GameState.centro.geradores:  # 8a2: Alunos da Raízes (só desenhados no centro: pessoas_desenhadas() fora dele é 0)
		ids.append(g.id)
	return ids


func _ao_carreira() -> void:
	_atualizar_mural()
	if _montado:
		_chegada_pendente = false
		_local_anterior = GameState.local_id
		_aplicar_layout()
		_atualizar_pessoas(false)
		_sincronizar_caixas()


## Luz da sala: lâmpada da garagem (crítico: balança; de vez em quando pisca) ou tubo da direita da academia (falha).
func _piscar_luz(forte: bool) -> void:
	if GameState.local_id == "center":
		return  # 8a2: o centro não tem lâmpada nem tubo (a falha do LED é opcional e não foi feita)
	if GameState.local_id != "gym" or _tubos.is_empty():
		if not _lampada.esta_tocando():
			_lampada.tocar([1, 0, 1, 0] if forte else [2, 0], 10.0 if forte else 12.0)
		return
	var tubo: AnimSprite = _tubos[_tubos.size() - 1]
	if not tubo.esta_tocando():
		tubo.tocar([1, 0, 1, 0], 12.0, false, func() -> void: tubo.parar(0))


# --- Fase 5: mudança para a academia e escolha da arte ---

## MUDAR (ou NOVA CARREIRA, ou carregar um save): o layout já troca o fundo e os sprites. Garagem -> academia ganha a festa
## da chegada (corte seco, poeira, tremida e o letreiro "BEM-VINDO À BOA ESQUINA!"). Se a janela de arte vem junto, a festa
## espera ela fechar (por baixo do escurecimento ninguém veria).
func _ao_local(local: String) -> void:
	var antes := _local_anterior
	_local_anterior = local
	if not _montado:
		return
	_aplicar_layout()
	_atualizar_pessoas(false)
	if antes == "gym" and local == "center" and GameState.cena_sala == "":  # 8a2: o centro não tem cena: corte seco, poeira e o letreiro
		_festa_academia("move_arrived_center", "BEM-VINDO AO CENTRO RAÍZES!")
		return
	if antes != "gym" and local == "gym" and GameState.cena_sala == "":  # 6c1: a cena da 1ª chegada já é a festa da academia
		_chegada_pendente = true
		if not GameState.escolha_arte_pendente():
			_festa_academia()


func _ao_arte(arte: String) -> void:
	if not _montado:
		return
	_aplicar_layout()  # a marca de fita (e a plaquinha) do aparelho da arte aparecem; sem arte, somem
	if arte != "" and _chegada_pendente:
		_festa_academia()


func _festa_academia(chave_texto: String = "move_arrived", padrao: String = "BEM-VINDO À BOA ESQUINA!") -> void:
	_chegada_pendente = false
	_mundo.modulate = Color(2.4, 2.4, 2.4)
	_mundo.create_tween().tween_property(_mundo, "modulate", Color.WHITE, 0.4)
	_tocar_chegada(_fx_poeira_chegada, Vector2(336, 240), 6)
	_tremer(2, 0.14)
	sfx.queda()
	var n := _pegar_numero()
	_ordem += 1
	n.definir_z(Z_NUMEROS + 1000 + _ordem % 900)
	n.iniciar(UiTema.txt(chave_texto, padrao), UiTema.Y1, true, "", Vector2(336, 140), 2.0, 12.0)


# --- Fase 5.1: dicas de hover e a caixa da escola ---

## Mouse se mexeu na sala: caixa, mentor 2 ou objeto da parede sob ele mostram a dica.
func _hover_em(p: Vector2) -> void:
	var sobre_mentor2 := false
	var tip := ""
	var cx := _caixa_em(p)
	if _evento_rect.size != Vector2.ZERO and _evento_rect.has_point(p) and _evento_tipo == "crew":
		tip = _texto_bolsa()
	elif cx != "":
		tip = _texto_caixa(cx)
	elif _envelope != null and _envelope.visible and _envelope_rect.has_point(p):
		tip = str(GameState.patrocinio().get("envelope", "PROPOSTA"))  # 8a2
	elif _capuz_dica(p) != "":
		tip = _capuz_dica(p)
	elif _mentor2_visivel and _cam_escala == 1 and _area_mentor2().has_point(p):
		tip = UiTema.txt("disc_mentor2_hint", "{nome}: já passou o posto.", {"nome": _mentor2_nome})
		sobre_mentor2 = true
	elif _texto_parede(p) != "":
		tip = _texto_parede(p)
	_ancorar_dica_mentor2(sobre_mentor2)
	_capuz_hover(_capuz_dica(p) != "")
	_zoom_recorte(_recorte != null and _recorte.visible and _recorte_rect.has_point(p) and cx == "")
	_zoom_cartaz(_cartaz != null and _cartaz.visible and _cartaz_rect.has_point(p) and cx == "")
	_zoom_clipvale(_clipvale != null and _clipvale.visible and _clipvale_rect.has_point(p) and cx == "")
	if tip != "":
		Dica.pedir(tip)
	else:
		Dica.limpar()


## B2: a dica do 2º mentor fica na parede, 52 px acima da cabeça dele (acima das cabeças da equipe), nunca no tronco dele.
func _ancorar_dica_mentor2(sobre: bool) -> void:
	if Dica.instancia == null:
		return
	if sobre:
		Dica.instancia.ancora_fixa = Vector2(float(DICA_M2_X) - 10.0, cabeca_mentor2().y - 64.0)
		_dica_m2 = true
	elif _dica_m2:
		Dica.instancia.ancora_fixa = Vector2(-1, -1)
		_dica_m2 = false


func _sair_hover() -> void:
	_capuz_hover(false)
	_zoom_recorte(false)
	_zoom_cartaz(false)
	_zoom_clipvale(false)
	_ancorar_dica_mentor2(false)
	Dica.limpar()


# --- A caixa da escola ---

func _slot_caixa(item: String) -> Vector2:
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("box", {})
	var slot := str(info.get("slot_by_item", {}).get(item, ""))
	var s: Array = UiTema.manifest().get("layout", {}).get("box_slots", {}).get(slot, [336, 270])
	return Vector2(float(s[0]), float(s[1]))


func _sprite_caixa(item: String) -> String:
	return str(UiTema.manifest().get("by_data_id", {}).get("box", {}).get("sprite_by_item", {}).get(item, "box_small"))


## Cria/atualiza/remove as caixas da sala conforme o GameState (carga do save, nova carreira, compra, abertura).
func _sincronizar_caixas() -> void:
	for item in _caixas.keys():
		if not is_instance_valid(_caixas[item]):
			_caixas.erase(item)
	var itens: Dictionary = {}
	for c in GameState.caixas():
		itens[str(c.item)] = c
	for item in _caixas.keys():
		var cx: CaixaSala = _caixas[item]
		if not itens.has(item) and not cx.abrindo:
			cx.queue_free()
			_caixas.erase(item)
	for item in itens:
		if not _caixas.has(item):
			_criar_caixa(item, int(itens[item].hits), false)
		else:
			(_caixas[item] as CaixaSala).definir_batidas(int(itens[item].hits))


func _criar_caixa(item: String, hits: int, chegada: bool) -> CaixaSala:
	var cx := CaixaSala.new()
	_mundo.add_child(cx)
	cx.iniciar(item, _sprite_caixa(item), _slot_caixa(item), hits, _caixas.size())
	_caixas[item] = cx
	cx.sumiu.connect(func(i: String) -> void:
		if _caixas.get(i) == cx:
			_caixas.erase(i))
	if chegada:
		cx.cair()
	return cx


## Compra: a caixa cai no slot. Nenhum clique de treino é gasto.
func _ao_caixa_criada(item: String, _tipo: String) -> void:
	if not _montado:
		return
	if _caixas.has(item):
		return
	_criar_caixa(item, 0, true)
	sfx.queda()


## Caixa sob o ponto (coordenadas da tela base) ou "".
func _caixa_em(p: Vector2) -> String:
	for item in _caixas.keys():
		if not is_instance_valid(_caixas[item]):
			_caixas.erase(item)
	for item in _caixas:
		var cx: CaixaSala = _caixas[item]
		if not cx.abrindo and cx.area().has_point(p):
			return item
	return ""


func _texto_caixa(item: String) -> String:
	var ui: Dictionary = GameState.dados.ui
	var rotulo := str(ui.get("box_label", {}).get(item, ""))
	var carimbo := str(ui.get("box_stamp", {}).get(item, ""))
	var falta := GameState.cliques_faltando(item)
	var dica := GameState.texto_ui("box_hover_closed") if falta >= GameState.cliques_para_abrir() \
		else GameState.preencher(GameState.texto_ui("box_hover_left"), {"n": falta})
	return "%s\n%s\n%s" % [rotulo, carimbo, dica]


## 7a2: alguma caixa de equipamento está animando a abertura (ou o aparelho ainda "nasce"): o balão do convite espera.
## O estado abre a caixa de uma vez; só a UI sabe da animação.
func caixa_abrindo() -> bool:
	if not _revelar.is_empty():
		return true
	for item in _caixas:
		var cx = _caixas[item]
		if is_instance_valid(cx) and cx.abrindo:
			return true
	return false


## Janela aberta por cima (árvore, aposentar, prévia, luta...) ou jogo bloqueado: o clique não vai para a caixa.
func caixa_liberada() -> bool:
	return not janela_aberta and not GameState.modal_aberto and not GameState.acoes_bloqueadas()


func _bater_caixa(item: String) -> void:
	if not caixa_liberada():
		return
	GameState.bater_caixa(item)


func _ao_caixa_batida(item: String, batidas: int) -> void:
	if not _caixas.has(item):
		return
	var cx: CaixaSala = _caixas[item]
	cx.bater(batidas)
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("box", {})
	var clique: Dictionary = info.get("clicks", [{}, {}, {}])[clampi(batidas - 1, 0, 2)]
	var topo := cx.topo()
	_efeito_caixa(str(clique.get("fx", "")), topo)
	var frases: Array = GameState.lista_ui("box_click")
	if batidas - 1 < frases.size():
		_mostrar_texto(topo + Vector2(0, -6.0 - 10.0 * float(batidas - 1)), str(frases[batidas - 1]).to_upper(), UiTema.Y2)
	if batidas >= 3:
		_tremer(1, 0.12)
		sfx.compra()
	else:
		sfx.foco()
		_tremer(1, 0.05)


## Efeito de caixa (lascas, estouro, brilho): sprite avulso que toca uma vez e some.
func _efeito_caixa(nome: String, p: Vector2) -> void:
	if nome == "" or UiTema.sprite(nome).is_empty():
		return
	var a := _novo_anim(nome, "", Z_FX + 20)
	a.position = p
	var n := int(UiTema.sprite(nome).get("frames", 1))
	var quadros: Array = []
	for i in n:
		quadros.append(i)
	a.tocar(quadros, float(UiTema.sprite(nome).get("fps", 14.0)), false, func() -> void: a.queue_free())


## 3º clique: o item já vale no GameState. Estouro, caixa vazia some piscando e o item aparece (≤ 1,2 s no total).
func _ao_caixa_aberta(item: String, tipo: String) -> void:
	if not _montado:
		return
	var cx: CaixaSala = _caixas.get(item)
	if cx != null:
		cx.abrir()
		# B3: o "ABRIU!" do 3º clique sobe primeiro; o "CHEGOU" entra depois do estouro e mais alto, sem empilhar.
		var chegou := GameState.preencher(GameState.texto_ui("box_arrived"),
			{"item": str(GameState.dados.ui.get("box_label", {}).get(item, item))}).to_upper()
		var topo_chegou := cx.topo() + Vector2(0, -44)
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			if is_inside_tree():
				_mostrar_texto(topo_chegou, chegou, UiTema.Y1))
	if tipo == "apparatus":
		_revelar[item] = true
		_aplicar_layout()
		get_tree().create_timer(0.3).timeout.connect(func() -> void: _revelar_item(item))


func _revelar_item(item: String) -> void:
	if not _revelar.has(item):
		return
	_revelar.erase(item)
	if not is_inside_tree():
		return
	_aplicar_layout()
	var alvo: Node2D = _anim_do(item)
	if item == CORDA and GameState.foco == CORDA:
		alvo = _lutador
	alvo.modulate = Color(2.5, 2.5, 2.5)
	alvo.create_tween().tween_property(alvo, "modulate", Color.WHITE, 0.45)
	_critico_fx(alvo.position + Vector2(0, -10))
	sfx.compra()
	var py := alvo.position.y
	alvo.position.y = py - 8.0
	alvo.create_tween().tween_property(alvo, "position:y", py, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Em cada passada do layout, o aparelho que acabou de sair da caixa espera o item "nascer" (0,3 s).
func _esconder_reveladas() -> void:
	for item in _revelar:
		var a: AnimSprite = _anim_do(str(item))
		a.visible = false


## Caixa de equipamento: sprite de 4 quadros (fechada, rachada 1, rachada 2, aberta), espera balançando e brilhando.
class CaixaSala extends Node2D:
	signal sumiu(item: String)

	var item := ""
	var spr: AnimSprite
	var batidas := 0
	var abrindo := false
	var pivo := Vector2.ZERO
	var _click := Rect2()
	var _topo := Vector2.ZERO
	var _glint_offset := Vector2.ZERO
	var _t := 0.0
	var _defasagem := 0.0
	var _shake: Tween
	var _ocupada := false

	func iniciar(id: String, nome_sprite: String, p: Vector2, hits: int, indice: int) -> void:
		item = id
		pivo = p
		position = p
		z_index = int(p.y) + 5
		spr = AnimSprite.new()
		spr.definir(nome_sprite)
		add_child(spr)
		var s := UiTema.sprite(nome_sprite)
		var cr: Array = s.get("click_rect", [-16, -27, 32, 29])
		_click = Rect2(p + Vector2(float(cr[0]), float(cr[1])), Vector2(float(cr[2]), float(cr[3])))
		var tc: Array = s.get("top_center_offset", [0, -25])
		_topo = p + Vector2(float(tc[0]), float(tc[1]))
		var go: Dictionary = UiTema.manifest().get("by_data_id", {}).get("box", {}).get("idle", {}).get("glint_offset", {})
		var g: Array = go.get(nome_sprite, [11, -22])
		_glint_offset = Vector2(float(g[0]), float(g[1]))
		_defasagem = float(indice) * 1.3
		definir_batidas(hits)

	func definir_batidas(n: int) -> void:
		batidas = n
		spr.parar(clampi(n, 0, 2))

	func area() -> Rect2:
		return _click

	func topo() -> Vector2:
		return _topo

	## Cai de 24 px acima em passos de 1/24 s (chegada da compra).
	func cair() -> void:
		_ocupada = true
		var tw := create_tween()
		for dy in [-24.0, -12.0, -3.0, 0.0, 1.0, 0.0]:
			tw.tween_callback(func() -> void: spr.position.y = dy)
			tw.tween_interval(1.0 / 24.0)
		tw.tween_callback(func() -> void: _ocupada = false)

	## Tremida e quadro novo: 1º clique 1 px, 2º 2 px, 3º 3 px (lista shake_x do manifest).
	func bater(n: int) -> void:
		batidas = n
		spr.parar(clampi(n, 0, 3))
		var lista: Array = UiTema.manifest().get("by_data_id", {}).get("box", {}).get("clicks", [{}, {}, {}])
		var info: Dictionary = lista[clampi(n - 1, 0, 2)]
		var xs: Array = info.get("shake_x", [-1, 1, 0])
		var passo := 1.0 / maxf(1.0, float(info.get("shake_fps", 30)))
		if _shake != null and _shake.is_valid():
			_shake.kill()
		_ocupada = true
		_shake = create_tween()
		for x in xs:
			_shake.tween_callback(func() -> void: spr.position = Vector2(float(x), 0.0))
			_shake.tween_interval(passo)
		_shake.tween_callback(func() -> void:
			spr.position = Vector2.ZERO
			_ocupada = false)

	## Aberta: quadro 3 na hora; depois de 0,6 s some piscando por 0,3 s e a caixa é liberada.
	func abrir() -> void:
		abrindo = true
		spr.parar(3)
		var tw := create_tween()
		tw.tween_interval(0.6)
		for i in 3:
			tw.tween_callback(func() -> void: spr.visible = false)
			tw.tween_interval(0.05)
			tw.tween_callback(func() -> void: spr.visible = true)
			tw.tween_interval(0.05)
		tw.tween_callback(func() -> void:
			sumiu.emit(item)
			queue_free())

	func _process(delta: float) -> void:
		if abrindo or _ocupada or spr == null:
			return
		_t += delta
		var fase := fmod(_t + _defasagem, 4.0)
		if fase < 0.34:  # balança 1 px (4 quadros a 12 fps)
			var xs := [1, 0, -1, 0]
			spr.position.x = float(xs[int(fase * 12.0) % 4])
		else:
			spr.position.x = 0.0
		if fase < delta and _t > 0.5:
			var par := get_parent()
			if par != null:
				var a := AnimSprite.new()
				a.definir("fx_box_glint")
				a.position = pivo + _glint_offset
				a.z_index = z_index + 2
				par.add_child(a)
				a.tocar([0, 1, 2, 3], 8.0, false, func() -> void: a.queue_free())


# --- Fase 6a: Osmar, gesto do 1º lutador, parede da memória ---

## Osmar Brandão: só na garagem, num ponto próprio (manifest.original_trainer.pos). Parado, olhando a parede ou falando.
func _montar_osmar() -> void:
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("original_trainer", {})
	var p: Array = info.get("pos", [196, 236])
	var pos_o := Vector2(float(p[0]), float(p[1]))
	_sombra_osmar = Sprite2D.new()
	_sombra_osmar.texture = UiTema.textura("floor_shadow")
	_sombra_osmar.position = pos_o + Vector2(0, -1)
	_sombra_osmar.z_index = int(pos_o.y) - 1
	_mundo.add_child(_sombra_osmar)
	_osmar = _novo_anim("coach_idle", "", int(pos_o.y))
	_osmar.position = pos_o
	_atualizar_osmar()


## Folha do Osmar: falando enquanto o balão dele escreve; na abertura ele olha a parede entre as falas.
func _atualizar_osmar() -> void:
	if _osmar == null:
		return
	# 6c1: o Osmar é desenhado onde a escola diz (garagem sempre; academia depois do marco da cena), no ponto do local.
	var pt: Array = GameState.ponto_do_coach()
	var presente := pt.size() == 2
	var palco := not ("coach" in _cena_oculta)  # na cena o Osmar é um ator do palco
	_osmar.visible = presente and palco
	_sombra_osmar.visible = presente and palco
	if not presente:
		return
	var pos_o := Vector2(float(pt[0]), float(pt[1]))
	if _osmar.position != pos_o:
		_osmar.position = pos_o
		_osmar.z_index = int(pos_o.y)
		_sombra_osmar.position = pos_o + Vector2(0, -1)
		_sombra_osmar.z_index = int(pos_o.y) - 1
	var estado := "idle"
	if _coach_falando:
		estado = "talk"
	elif GameState.abertura_estado() == "playing":
		estado = "look"
	var folha := str(OSMAR_FOLHAS[estado])
	var sufixo := GameState.sufixo_aparelhos()
	if sufixo != "" and not UiTema.sprite(folha + sufixo).is_empty():
		folha += sufixo  # academia: a luz dos tubos (coach_idle_gym, coach_talk_gym)
	elif sufixo != "" and estado == "look":
		folha = "coach_idle" + sufixo if not UiTema.sprite("coach_idle" + sufixo).is_empty() else folha
	if folha == _osmar_estado:
		return
	_osmar_estado = folha
	_osmar.definir(folha)
	_osmar.tocar([0, 1, 2, 3], float(UiTema.sprite(_osmar.nome_sprite).get("fps", 3.0)), true)


## O balão avisa quem está escrevendo (a Garagem liga os dois).
func definir_falando(speaker: String, sim: bool) -> void:
	if speaker != "coach":
		return
	_coach_falando = sim
	_atualizar_osmar()


## 6c2: quem fala é o mentor do caixote? "last" (discípulo sentado) sempre; "first" só quando o lutador atual NÃO é o John
## (aí o John que fala está sentado no caixote; na Carreira 1 "first" é o lutador).
func fala_do_mentor(speaker: String) -> bool:
	return speaker == "mentor" or speaker == "last" or (speaker == "first" and GameState.lutador_atual() != "first")


## Cabeça do lutador (quem treina na sala), como no balão de "first".
func cabeca_lutador() -> Vector2:
	var a2: Array = UiTema.manifest().get("by_data_id", {}).get("first_fighter", {}).get("head_anchor", {}).get("garage", [1, -65])
	var pe: Vector2
	match _foco():
		CORDA:
			pe = UiTema.pos("fighter_idle", "foco_corda")
		ESTEIRA:
			pe = UiTema.pos("fighter_run", "foco_esteira")
		_:
			pe = UiTema.pos("fighter_idle", "foco_saco")
	return pe + Vector2(float(a2[0]), float(a2[1]))


## Ponto logo acima da cabeça de quem fala (head_anchor do manifest, relativo ao pivô; não treme com o soco).
func ponto_cabeca(speaker: String) -> Vector2:
	var info: Dictionary = UiTema.manifest().get("by_data_id", {})
	if speaker == "coach":
		var o: Dictionary = info.get("original_trainer", {})
		var a: Array = o.get("head_anchor", [1, -63])
		var p: Array = GameState.ponto_do_coach()
		if p.size() != 2:
			p = o.get("pos", [196, 236])
		return Vector2(float(p[0]) + float(a[0]), float(p[1]) + float(a[1]))
	if fala_do_mentor(speaker):
		return cabeca_mentor()
	return cabeca_lutador()


## Cabeças dos OUTROS personagens que o balão de `speaker` não pode cobrir (além da zona do alvo).
func cabecas_a_evitar(speaker: String) -> Array:
	var mentor_fala := fala_do_mentor(speaker)
	var lista: Array = []
	if speaker != "coach" and GameState.coach_presente():
		var hc := ponto_cabeca("coach")
		lista.append(Rect2(hc.x - 9.0, hc.y, 18.0, 18.0))
	if speaker == "coach" or mentor_fala:
		var h := cabeca_lutador()  # o balão do Osmar e o do mentor nunca cobrem a cabeça de quem treina
		lista.append(Rect2(h.x - 9.0, h.y, 18.0, 18.0))
	# Fase 6b1: o John sentado no caixote também é alguém que o balão não pode cobrir (regra do §22.2).
	if _mentor_visivel and not mentor_fala:
		var m := cabeca_mentor()
		lista.append(Rect2(m.x - 9.0, m.y, 18.0, 18.0))
	# Fase 6b2: o segundo mentor parado no canto também não pode ficar sob o balão de ninguém.
	if _mentor2_visivel:
		var m2 := cabeca_mentor2()
		lista.append(Rect2(m2.x - 9.0, m2.y, 18.0, 18.0))
	return lista


# Gesto "fecho e dois toques" (só o John): momentos da sala = abertura, luva nova e sala parada.
func _ao_gesto_pedido(plano: Dictionary) -> void:
	if str(plano.get("momento", "")) in ["fight_intro", "victory"]:
		return  # esses são da arena (TelaLuta)
	if GameState.lutador_atual() != "first" or GameState.foco == ESTEIRA:
		GameState.cancelar_gesto()
		return
	_gesto.iniciar(plano, {
		"comecar": _gesto_comecar,
		"rip": func() -> void: sfx.strap_rip(),
		"toque": _gesto_toque,
		"fim": _gesto_fim,
	})


func _gesto_comecar(plano: Dictionary) -> void:
	var nome := _f("fighter_gesture_short" if str(plano.version) == "short" else "fighter_gesture")
	if UiTema.sprite(nome).is_empty():
		return
	_gesto_sprite = nome
	_corda_girando = false  # o gesto toma o lutador: o giro da corda em andamento acabou
	_corda_giro.visible = false
	_corda_costas.visible = false
	_lutador.definir(nome)
	_lutador.position = UiTema.pos(nome, "foco_corda" if GameState.foco == CORDA else "foco_saco")
	var n := int(UiTema.sprite(nome).get("frames", 4))
	var seq: Array = []
	for i in n:
		seq.append(i)
	_lutador.tocar(seq, float(UiTema.sprite(nome).get("fps", 9.0)), false)
	_sombra_lutador.position = _lutador.position + Vector2(0, -1)


func _gesto_toque(n: int) -> void:
	sfx.tap_glove()
	if _gesto_sprite == "":
		return
	var pts: Array = UiTema.sprite(_gesto_sprite).get("tap_points", [[3, -47]])
	var tp: Array = pts[mini(n, pts.size() - 1)]
	_impacto(_lutador.position + Vector2(float(tp[0]) + 14.0, float(tp[1])), false)


func _gesto_fim() -> void:
	if _gesto_sprite != "":
		_gesto_sprite = ""
		_pose_repouso()


## Qualquer clique cancela o gesto no mesmo quadro: corta o strap_rip (o 2º toque não toca) e volta à guarda.
func _ao_gesto_cancelado() -> void:
	if _gesto != null:
		_gesto.cancelar()
	sfx.cortar_rip()
	if _gesto_sprite != "":
		_gesto_sprite = ""
		_pose_repouso()


## Parede da memória: objetos do garage_story_wall conforme os marcos da escola. Só na garagem.
func _montar_parede() -> void:
	var obj: Dictionary = UiTema.manifest().get("by_data_id", {}).get("garage_story_wall", {}).get("objects", {})
	var ordem := ["notice_debt", "form", "photo_old", "clipping", "photo_team", "school_symbol"]
	for k in ordem:
		var o: Dictionary = obj.get(k, {})
		if o.is_empty():
			continue
		var nome := str(o.get("sprite", o.get("sprite_before", "")))
		var s := AnimSprite.new()
		s.definir(nome)
		var p: Array = o.pos
		s.position = Vector2(float(p[0]), float(p[1]))
		s.z_index = -45 + ordem.find(k)  # a ordem do manifest decide quem fica por cima
		_mundo.add_child(s)
		_parede[k] = {"sprite": s, "dados": o}
	# 6c1: a foto antiga na academia (torta, no gym_photo_spot); só desenhada onde a escola diz (foto_antiga()).
	if not UiTema.sprite("wall_photo_old_gym").is_empty():
		var sf := AnimSprite.new()
		sf.definir("wall_photo_old_gym")
		sf.z_index = -45 + ordem.find("photo_old")
		sf.visible = false
		_mundo.add_child(sf)
		_parede["photo_old_gym"] = {"sprite": sf, "dados": {}}
	# 7a2: recorte de jornal do vulto (garagem e academia); a folha e o ponto vêm de recorte_gato_preto() e do manifest.
	_recorte = AnimSprite.new()
	_recorte.visible = false
	_recorte.z_index = -45 + ordem.find("photo_old")
	_mundo.add_child(_recorte)
	# 6c2: o mural da escola (garagem e academia); a folha e o ponto vêm de mural_na_sala() e do manifest.
	_mural = AnimSprite.new()
	_mural.visible = false
	_mural.z_index = -45 + ordem.find("photo_old")
	_mundo.add_child(_mural)
	# 8a1: cartaz da liga regional, em cima da porta da academia (o ponto e o sprite vêm do manifest; só aparece a partir do marco).
	_cartaz = AnimSprite.new()
	_cartaz.visible = false
	_cartaz.z_index = -45 + ordem.find("photo_old")
	_mundo.add_child(_cartaz)
	# 8a2: recorte do Vale emoldurado (centro) e o envelope PROPOSTA (camada do chão, abaixo de quem passa).
	_clipvale = AnimSprite.new()
	_clipvale.visible = false
	_clipvale.z_index = -45 + ordem.find("photo_old")
	_mundo.add_child(_clipvale)
	_envelope = AnimSprite.new()
	_envelope.visible = false
	_envelope.z_index = -10
	_mundo.add_child(_envelope)
	# Ronda: o capuz no prego, na camada da parede.
	_capuz = AnimSprite.new()
	_capuz.visible = false
	_capuz.z_index = -42
	_mundo.add_child(_capuz)
	_atualizar_parede()


## Mural na parede: só onde a escola diz (mural_na_sala()); o quadro vem do tamanho do roster (manifest frame_by_roster).
func _atualizar_mural() -> void:
	if _mural == null:
		return
	var m: Dictionary = GameState.mural_na_sala() if not ("wall_objects" in _cena_oculta) else {}
	var spot: Array = m.get("spot", [])
	if m.is_empty() or spot.size() != 2:
		_mural.visible = false
		_mural_rect = Rect2()
		_mural_chave = ""
		return
	var gym := str(m.get("spot_name", "")) != "mural_spot"  # 8a2: academia e centro usam o mural largo (wall_mural_gym / wall_mural_center)
	var nome := UiTema.com_local("wall_mural") if gym else "wall_mural"
	var info: Dictionary = UiTema.manifest().get("layout", {}).get("gym_mural_spot_info" if gym else "mural_spot_info", {})
	var minimos: Array = info.get("frame_by_roster", {}).get("min_entries", [1, 2, 4, 8])
	var n := GameState.escola_lista().size()
	var quadro := 0
	for i in minimos.size():
		if n >= int(minimos[i]):
			quadro = i
	var chave := "%s|%d|%s" % [nome, quadro, str(spot)]
	_mural.visible = true
	if chave == _mural_chave:
		return
	_mural_chave = chave
	_mural.definir(nome)
	_mural.position = Vector2(float(spot[0]), float(spot[1]))
	_mural.parar(quadro)
	var cr: Array = info.get("click_rect", [spot[0], spot[1], 54, 22])
	_mural_rect = Rect2(float(cr[0]), float(cr[1]), float(cr[2]), float(cr[3]))


## Ronda: ficha do recorte do local atual no manifest (sprite_by_level / zoom_by_level).
func _info_recorte() -> Dictionary:
	var chave := "clipping_spot_info"
	if GameState.local_id == "gym":
		chave = "gym_clipping_spot_info"
	elif GameState.local_id == "center":
		chave = "center_clipping_black_cat_spot_info"
	var d = UiTema.manifest().get("layout", {}).get(chave, {})
	return d if d is Dictionary else {}


## Nome da folha do recorte (ou do zoom) para o nível da lenda; sem lista no manifest, a folha de sempre (nível 0).
func _folha_por_nivel(campo: String, padrao: String) -> String:
	var lista = _info_recorte().get(campo, [])
	var n := int(GameState.lenda().get("level", 0))
	if lista is Array and n < lista.size() and not UiTema.sprite(str(lista[n])).is_empty():
		return str(lista[n])
	return padrao


## 7a2: recorte de jornal do vulto no ponto de `recorte_gato_preto()`; sem ele (campanha 1, sem o marco), nada é desenhado.
## Ronda: a folha troca pelo nível da lenda (sprite_by_level).
func _atualizar_recorte() -> void:
	if _recorte == null:
		return
	var r: Dictionary = GameState.recorte_gato_preto() if not ("wall_objects" in _cena_oculta) else {}
	var spot: Array = r.get("spot", [])
	var nome := _folha_por_nivel("sprite_by_level", UiTema.com_local("wall_clipping_black_cat"))  # garagem, academia (_gym) ou centro (_center)
	if r.is_empty() or spot.size() != 2 or UiTema.sprite(nome).is_empty():
		_recorte.visible = false
		_recorte_rect = Rect2()
		return
	_recorte.definir(nome)
	_recorte.position = Vector2(float(spot[0]), float(spot[1]))
	_recorte.parar(0)
	_recorte.visible = true
	_recorte_rect = Rect2(_recorte.position, UiTema.tamanho_quadro(nome))


## Ronda: o capuz no prego do local atual. Fica desenhado com janela/fala (aí sem hover e sem clique); só some quando o GameState diz.
func _atualizar_capuz() -> void:
	if _capuz == null:
		return
	var c: Dictionary = GameState.capuz_info() if not ("wall_objects" in _cena_oculta) else {}
	var spot: Array = c.get("spot", [])
	var nome := UiTema.com_local("hood_on_nail")
	if c.is_empty() or spot.size() != 2 or UiTema.sprite(nome).is_empty():
		_capuz.visible = false
		_capuz_rect = Rect2()
		_capuz_clicavel = false
		return
	_capuz.definir(nome)
	_capuz.position = Vector2(float(spot[0]), float(spot[1]))
	var info = UiTema.manifest().get("layout", {}).get(str(c.get("spot_name", "")) + "_info", {})
	var cr: Array = info.get("click_rect", [spot[0] - 10, spot[1] - 1, 20, 24]) if info is Dictionary else [spot[0] - 10, spot[1] - 1, 20, 24]
	_capuz_rect = Rect2(float(cr[0]), float(cr[1]), float(cr[2]), float(cr[3]))
	_capuz_clicavel = bool(c.get("clickable", false))
	_capuz.visible = true
	_capuz.parar(1 if (_capuz_sobre and _capuz_clicavel) else 0)


## Texto do hover do capuz sob o ponto (só com o capuz clicável: sem clique não há hover), ou "".
func _capuz_dica(p: Vector2) -> String:
	if _capuz == null or not _capuz.visible or not _capuz_rect.has_point(p):
		return ""
	var c: Dictionary = GameState.capuz_info()
	return str(c.get("hover_text", "")) if bool(c.get("clickable", false)) and caixa_liberada() else ""


## Quadro 1 (hover) enquanto o mouse está em cima do capuz clicável.
func _capuz_hover(sobre: bool) -> void:
	_capuz_sobre = sobre
	if _capuz != null and _capuz.visible:
		_capuz.parar(1 if sobre else 0)


## Dica de zoom do recorte: a imagem grande ao lado dele, só enquanto o mouse está em cima (nunca cobre a zona do alvo).
func _zoom_recorte(sobre: bool) -> void:
	var nome_zoom := _folha_por_nivel("zoom_by_level", "ui_clipping_black_cat_zoom")  # Ronda: o zoom também sobe com a lenda
	if not sobre or _recorte_rect.size == Vector2.ZERO or UiTema.sprite(nome_zoom).is_empty():
		if _recorte_zoom != null:
			_recorte_zoom.visible = false
		return
	if _recorte_zoom == null:
		_recorte_zoom = UiTema.textura_rect(self, nome_zoom, 0, 0)
		_recorte_zoom.z_index = 3000
		UiTema.ignorar(_recorte_zoom, "recorte ampliado ao lado do mural: posição calculada a partir do recorte, por cima da sala")
	_recorte_zoom.texture = UiTema.textura(nome_zoom)
	_recorte_zoom.size = UiTema.tamanho_quadro(nome_zoom)
	var q := UiTema.tamanho_quadro(nome_zoom)
	var x := _recorte_rect.end.x + 6.0
	var y := clampf(_recorte_rect.position.y - 8.0, 22.0, 178.0 - q.y)
	if x + q.x > 500.0:
		x = _recorte_rect.position.x - 6.0 - q.x
	_recorte_zoom.position = Vector2(x, y) - position  # o Sala não está na origem (room_rect começa em y 18)
	_recorte_zoom.visible = true


## 8a1: o cartaz da liga regional na academia, a partir do marco `regional_league_opened` (a fala do Osmar abre junto).
## 8a2: a partir do 1º Cinturão do Vale da linhagem (recorte_do_vale() não vazio) o cartaz troca para a versão VENCIDA (42x58: adesivo do R,
## recorte preso com fita); o quadro 1 traz a marca do patrocinador (contrato assinado).
func _atualizar_cartaz() -> void:
	if _cartaz == null:
		return
	var info: Dictionary = UiTema.manifest().get("layout", {}).get("gym_league_poster_spot_info", {})
	var spot: Array = UiTema.manifest().get("layout", {}).get("gym_league_poster_spot", [])
	var vale: Dictionary = GameState.recorte_do_vale()
	var vencido := not vale.is_empty() and not UiTema.sprite(str(info.get("sprite_won", ""))).is_empty()
	var nome := str(info.get("sprite_won", "")) if vencido else str(info.get("sprite", "wall_poster_league_regional_gym"))
	var ver := GameState.local_id == "gym" and (vencido or GameState.marco(str(info.get("requires_milestone", "regional_league_opened")))) 		and not ("wall_objects" in _cena_oculta) and spot.size() == 2 and not UiTema.sprite(nome).is_empty()
	_cartaz.visible = ver
	if not ver:
		_cartaz_rect = Rect2()
		return
	_cartaz.definir(nome)
	_cartaz.position = Vector2(float(spot[0]), float(spot[1]))
	_cartaz.parar(1 if vencido and str(vale.get("brand", "")) != "" else 0)
	_cartaz_rect = Rect2(_cartaz.position, UiTema.tamanho_quadro(nome))


## Um quadro de uma folha como textura (o TextureRect de folha mostraria os quadros lado a lado).
func _textura_quadro(nome: String, quadro: int) -> Texture2D:
	var a := AtlasTexture.new()
	a.atlas = UiTema.textura(nome)
	var q := UiTema.tamanho_quadro(nome)
	a.region = Rect2(q.x * quadro, 0, q.x, q.y)
	return a


## Dica de zoom do cartaz: a imagem grande ao lado dele, só com o mouse em cima (nunca cobre a zona do alvo: y máximo 178).
func _zoom_cartaz(sobre: bool) -> void:
	var info: Dictionary = UiTema.manifest().get("layout", {}).get("gym_league_poster_spot_info", {})
	var vale: Dictionary = GameState.recorte_do_vale()
	var nome := str(info.get("zoom", "ui_poster_league_regional_zoom"))
	var quadro := 0
	if not vale.is_empty() and not UiTema.sprite("ui_poster_league_regional_won_zoom").is_empty():
		nome = "ui_poster_league_regional_won_zoom"
		quadro = 1 if str(vale.get("brand", "")) != "" else 0
	if not sobre or _cartaz_rect.size == Vector2.ZERO or UiTema.sprite(nome).is_empty():
		if _cartaz_zoom != null:
			_cartaz_zoom.visible = false
		return
	if _cartaz_zoom == null:
		_cartaz_zoom = TextureRect.new()
		_cartaz_zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cartaz_zoom.stretch_mode = TextureRect.STRETCH_KEEP
		_cartaz_zoom.z_index = 3000
		add_child(_cartaz_zoom)
		UiTema.ignorar(_cartaz_zoom, "cartaz ampliado ao lado do mural: posição calculada a partir do cartaz, por cima da sala")
	var q := UiTema.tamanho_quadro(nome)
	_cartaz_zoom.texture = _textura_quadro(nome, quadro)
	_cartaz_zoom.size = q
	var x := _cartaz_rect.end.x + 6.0
	var y := clampf(_cartaz_rect.position.y - 8.0, 22.0, 178.0 - q.y)
	if x + q.x > 500.0:
		x = _cartaz_rect.position.x - 6.0 - q.x
	_cartaz_zoom.position = Vector2(x, y) - position  # o Sala não está na origem (room_rect começa em y 18)
	_cartaz_zoom.visible = true


## 8a2: o recorte do jornal do Vale emoldurado na parede do centro (D10), no ponto center_clipping_spot; só depois do 1º Cinturão do Vale.
func _atualizar_clipvale() -> void:
	if _clipvale == null:
		return
	var info: Dictionary = UiTema.manifest().get("layout", {}).get("center_clipping_spot_info", {})
	var spot: Array = UiTema.manifest().get("layout", {}).get("center_clipping_spot", [])
	var nome := str(info.get("sprite", "wall_clipping_regional_framed"))
	var ver := GameState.local_id == "center" and not GameState.recorte_do_vale().is_empty() and not ("wall_objects" in _cena_oculta) 		and spot.size() == 2 and not UiTema.sprite(nome).is_empty()
	_clipvale.visible = ver
	if not ver:
		_clipvale_rect = Rect2()
		return
	_clipvale.definir(nome)
	_clipvale.position = Vector2(float(spot[0]), float(spot[1]))
	_clipvale.parar(0)
	_clipvale_rect = Rect2(_clipvale.position, UiTema.tamanho_quadro(nome))


## Zoom do recorte do Vale (ui_clipping_regional_zoom, 124x92) ao lado dele, só com o mouse em cima.
func _zoom_clipvale(sobre: bool) -> void:
	var nome := "ui_clipping_regional_zoom"
	if not sobre or _clipvale_rect.size == Vector2.ZERO or UiTema.sprite(nome).is_empty():
		if _clipvale_zoom != null:
			_clipvale_zoom.visible = false
		return
	if _clipvale_zoom == null:
		_clipvale_zoom = TextureRect.new()
		_clipvale_zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_clipvale_zoom.stretch_mode = TextureRect.STRETCH_KEEP
		_clipvale_zoom.texture = UiTema.textura(nome)
		_clipvale_zoom.size = UiTema.tamanho_quadro(nome)
		_clipvale_zoom.z_index = 3000
		add_child(_clipvale_zoom)
		UiTema.ignorar(_clipvale_zoom, "recorte do Vale ampliado: posição calculada a partir do recorte, por cima da sala")
	var q := UiTema.tamanho_quadro(nome)
	var x := _clipvale_rect.end.x + 6.0
	var y := clampf(_clipvale_rect.position.y - 8.0, 22.0, 178.0 - q.y)
	if x + q.x > 500.0:
		x = _clipvale_rect.position.x - 6.0 - q.x
	_clipvale_zoom.position = Vector2(x, y) - position
	_clipvale_zoom.visible = true


## 8a2: o patrocínio mudou. Quando a proposta chega (de "" para "offered", jogando) sai um aviso curto sobre o alvo, 1 vez, sem travar o
## treino, e o envelope já nasce brilhando.
func _ao_patrocinio(estado: String) -> void:
	var chegou := estado == "offered" and _patro_anterior != "offered"
	_patro_anterior = estado
	_atualizar_parede()
	if not chegou or not _montado or _envelope == null or not _envelope.visible:
		return
	_prox_brilho_envelope = 6.0
	_envelope.tocar([0, 1, 2, 1, 0, 1, 2, 1, 0, 0], 6.0, false, func() -> void: _envelope.parar(0))
	var n := _pegar_numero()
	_ordem += 1
	n.definir_z(Z_NUMEROS + 1000 + _ordem % 900)
	n.iniciar(UiTema.txt("sponsor_arrived", "CHEGOU UMA PROPOSTA PARA A RAÍZES"), UiTema.Y1, true, "", Vector2(336, 120), 2.5, 12.0)
	sfx.compra()


## 8a2: o envelope PROPOSTA no chão (mesmo ponto nos 3 locais) enquanto o patrocínio está "offered" (a oferta não some ao fechar a janela).
func _atualizar_envelope() -> void:
	if _envelope == null:
		return
	var info: Dictionary = UiTema.manifest().get("layout", {}).get("sponsor_envelope_spot_info", {})
	var spot: Array = UiTema.manifest().get("layout", {}).get("sponsor_envelope_spot", [])
	var nome := str(info.get("sprite", "sponsor_envelope"))
	var ver := GameState.patrocinio_estado == "offered" and not _cena_ativa and spot.size() == 2 and not UiTema.sprite(nome).is_empty()
	_envelope.visible = ver
	if not ver:
		_envelope_rect = Rect2()
		return
	if _envelope.nome_sprite != nome:
		_envelope.definir(nome)
		_envelope.parar(0)
	_envelope.position = Vector2(float(spot[0]), float(spot[1]))
	var cr: Array = info.get("click_rect", [spot[0] - 10, spot[1] - 13, 20, 15])
	_envelope_rect = Rect2(float(cr[0]), float(cr[1]), float(cr[2]), float(cr[3]))


func _atualizar_parede() -> void:
	_atualizar_capuz()
	_atualizar_cartaz()
	_atualizar_clipvale()
	_atualizar_envelope()
	_atualizar_mural()
	_atualizar_recorte()
	if _parede.is_empty():
		return
	var garagem := GameState.local_id == "garage" and not ("wall_objects" in _cena_oculta)
	var salva := GameState.marco("garage_saved_seen")
	var foto: Dictionary = GameState.foto_antiga() if GameState.local_id != "garage" and not ("wall_objects" in _cena_oculta) else {}
	for k in _parede:
		var d: Dictionary = _parede[k]
		var s: AnimSprite = d.sprite
		var o: Dictionary = d.dados
		var ver := garagem
		if k == "photo_old_gym":
			s.visible = not foto.is_empty()
			if not foto.is_empty():
				var fp: Array = foto.spot
				s.position = Vector2(float(fp[0]), float(fp[1]))
				s.parar(1 if (bool(foto.get("tilted", true)) or GameState.local_id == "center") else 0)  # 8a2: no centro ela está sempre torta, de propósito
			continue
		match k:
			"notice_debt":
				ver = ver and not salva
			"clipping":
				ver = ver and GameState.marco("first_school_win")
			"photo_team", "school_symbol":
				ver = ver and salva
			"form":
				s.definir(str(o.sprite_after if salva else o.sprite_before))
		s.visible = ver


## Texto da dica de um objeto da parede sob o ponto (coordenadas da tela base), ou "".
func _texto_parede(p: Vector2) -> String:
	if _cartaz != null and _cartaz.visible and _cartaz_rect.has_point(p):
		var dc: DialogosData = GameState.dialogos
		var vale: Dictionary = GameState.recorte_do_vale()
		if not vale.is_empty():  # 8a2: cartaz vencido: título, "RAÍZES LEVA O CINTURÃO DO VALE COM {NOME}" e, assinado, "APOIO: {MARCA}"
			var linhas := "%s
%s" % [str(vale.poster.title), str(vale.poster.text)]
			if str(vale.poster.sponsor_line) != "":
				linhas += "
" + str(vale.poster.sponsor_line)
			return linhas
		return "%s
%s" % [dc.texto_objeto("regional_poster", "title"), dc.texto_objeto("regional_poster")]
	if _clipvale != null and _clipvale.visible and _clipvale_rect.has_point(p):
		var rv: Dictionary = GameState.recorte_do_vale()
		if not rv.is_empty():
			return "%s
%s
%s" % [str(rv.clipping.title), str(rv.clipping.text), str(rv.clipping.footer)]
	if _recorte != null and _recorte.visible and _recorte_rect.has_point(p):
		return GameState.texto_ui(str(GameState.recorte_gato_preto().get("object_text", "black_cat_clipping")), "")
	if _mural != null and _mural.visible and _mural_rect.has_point(p):
		var dm: DialogosData = GameState.dialogos
		var chave_m := str(GameState.mural_na_sala().get("object_text", "mural"))
		return "%s
%s" % [dm.texto_objeto(chave_m, "title"), dm.texto_objeto(chave_m)]
	var ordem := ["school_symbol", "photo_team", "clipping", "photo_old_gym", "photo_old", "form", "notice_debt"]
	for k in ordem:
		if not _parede.has(k):
			continue
		var s: AnimSprite = _parede[k].sprite
		if not s.visible:
			continue
		var r := Rect2(s.position, UiTema.tamanho_quadro(s.nome_sprite))
		if not r.has_point(p):
			continue
		var d: DialogosData = GameState.dialogos
		match k:
			"photo_old_gym":
				return d.texto_objeto(str(GameState.foto_antiga().get("object_text", "old_photo_gym")))
			"notice_debt":
				return "%s\n%s" % [d.texto_objeto("debt_notice", "title"), d.texto_objeto("debt_notice", "text")]
			"form":
				return d.texto_objeto("entry_form_after" if GameState.marco("garage_saved_seen") else "entry_form_before")
			"photo_old":
				return d.texto_objeto("old_photo")
			"clipping":
				return "%s\n%s\n%s" % [d.texto_objeto("clipping", "title"), d.texto_objeto("clipping"), d.texto_objeto("clipping", "footer")]
			"photo_team":
				return d.texto_objeto("team_photo")
			"school_symbol":
				return d.texto_objeto("garage_saved_seal", "title")
	return ""


# --- Quadro a quadro ---

func _process(delta: float) -> void:
	_capuz_t -= delta
	if _capuz_t <= 0.0:
		_capuz_t = 0.25
		if _capuz != null and _capuz.visible and bool(GameState.capuz_info().get("clickable", false)) != _capuz_clicavel:
			_atualizar_capuz()  # janela/fala abriu ou fechou: o capuz ganha ou perde o hover e o clique
	if _evento_rect.size != Vector2.ZERO and (GameState.evento_dourado_restante <= 0.0 or GameState.modal_aberto):
		_esconder_evento()  # venceu o tempo, alguém pegou ou abriu uma janela/luta
	if _rotulo_frenesi != null and _rotulo_frenesi.visible:
		_rotulo_frenesi.text = UiTema.txt("frenzy_label", "FRENESI X{n}  {s}S", {"n": int(GameState.FRENESI_MULT), "s": int(ceil(GameState.frenesi_restante))})
	# Tremida: pixel inteiro, decai até zero.
	if _shake_t > 0.0:
		_shake_t -= delta
		var amp := 0
		if _shake_t > 0.0:
			amp = int(ceil(float(_shake_amp) * _shake_t / _shake_dur))
		var o := Vector2.ZERO
		if amp > 0:
			o = Vector2(_rng.randi_range(-amp, amp), _rng.randi_range(-amp, amp))
		_mundo.position = _cam_base() + o
	elif _mundo.position != _cam_base():
		_mundo.position = _cam_base()
	_atualizar_mentor()
	_ocultar_da_cena()
	UiTema.aplicar_visual_disc(_lutador)  # Fase 6b1: pele, cabelo e calção escolhidos (folha em camadas com troca de cor)

	# Esteira: corre enquanto houver cliques recentes.
	if _corrida > 0.0:
		_corrida -= delta
		if _corrida <= 0.0 and GameState.foco == ESTEIRA:
			_pose_repouso()

	# 8a2: o envelope brilha de vez em quando (chama atenção sem pedir nada).
	if _envelope != null and _envelope.visible:
		_prox_brilho_envelope -= delta
		if _prox_brilho_envelope <= 0.0:
			_prox_brilho_envelope = _rng.randf_range(4.0, 7.0)
			if not _envelope.esta_tocando():
				_envelope.tocar([0, 0, 0, 1, 2, 1], 4.0, false, func() -> void: _envelope.parar(0))

	# Lâmpada pisca de vez em quando.
	_proxima_piscada -= delta
	if _proxima_piscada <= 0.0:
		_proxima_piscada = _rng.randf_range(6.0, 10.0)
		_piscar_luz(false)

	# Pêndulo: 8 quadros = um vai-e-volta = 2 auto-socos (manifest.by_data_id.metronome.sync). Com o alvo bloqueado
	# (janela, luta, tela de fim) o tempo não anda e o pêndulo congela no quadro em que está.
	if _metronomo.visible:
		var intervalo := GameState.intervalo_metronomo()
		if intervalo > 0.0:
			if GameState.metronomo_ativo():
				_acc_m = minf(_acc_m + delta, intervalo * 0.999)
			_metronomo.frame = int(4.0 * (float(_socos_m % 2) + _acc_m / intervalo)) % 8

	for n in _numeros:
		if n.ativo:
			n.passo(delta)

	_seta.visible = dica_ativa and not _cena_ativa
	if dica_ativa:
		_seta.passo(delta)


# --- Peças internas ---

## Corrente do saco: repete o tile da viga até o gancho.
class Corrente extends Node2D:
	var textura: Texture2D
	var x := 335.0
	var y_ini := 33.0
	var y_fim := 183.0

	func _draw() -> void:
		if textura == null:
			return
		var h := float(textura.get_height())
		var y := y_ini
		while y < y_fim:
			draw_texture(textura, Vector2(x, y))
			y += h


## Número flutuante reaproveitável (pool): um rótulo principal e, no crítico, uma linha de texto acima.
class Numero extends RefCounted:
	var ativo := false
	var _t := 0.0
	var _dur := 0.6
	var _subida := 26.0
	var _origem := Vector2.ZERO
	var _alt := 0.0
	var _alfa := 1.0
	var _sumir := 1.0  # 7b2: 1 = normal; cai para 0 quando um letreiro de fim limpa a área (ver `sumir_com`)
	var _gen := 0  # conta os usos do número (um fade atrasado não apaga um número reaproveitado)
	var _raiz: Node2D
	var _principal: Label
	var _extra: Label

	func _init(pai: Node2D) -> void:
		_raiz = Node2D.new()
		_raiz.z_index = Sala.Z_NUMEROS
		_raiz.visible = false
		pai.add_child(_raiz)
		_principal = _novo_rotulo(_raiz)
		_extra = _novo_rotulo(_raiz)

	func _novo_rotulo(pai: Node) -> Label:
		var l := UiTema.rotulo(pai, "", UiTema.WHITE, -100, 0, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
		l.custom_minimum_size = Vector2(200, 14)
		l.size = Vector2(200, 14)
		l.pivot_offset = Vector2(100, 7)
		return l

	var grande := false

	func definir_z(z: int) -> void:
		_raiz.z_index = z

	func retangulo() -> Rect2:
		var esc := _principal.scale.x
		var larg: float = UiTema.largura(_principal.text) * esc
		var alt := 7.0 * esc
		return Rect2(_raiz.position.x - larg / 2.0, _raiz.position.y - alt / 2.0, larg, alt)

	func empurrar(dy: float) -> void:
		_origem.y -= dy
		_raiz.position.y -= dy

	func progresso() -> float:
		return _t / _dur if ativo else 2.0

	func iniciar(texto: String, cor: Color, grande: bool, linha_extra: String, origem: Vector2,
			dur: float, subida: float, alfa: float = 1.0, escala: float = 0.0) -> void:
		ativo = true
		_gen += 1
		_sumir = 1.0
		_t = 0.0
		_dur = dur
		_subida = subida
		_alfa = alfa
		_origem = origem
		_principal.text = texto
		_principal.add_theme_color_override("font_color", cor)
		self.grande = grande
		_principal.scale = Vector2(escala, escala) if escala > 0.0 else (Vector2(2, 2) if grande else Vector2.ONE)
		_extra.visible = linha_extra != ""
		_extra.text = linha_extra
		_extra.add_theme_color_override("font_color", UiTema.Y2)
		_alt = 14.0 if grande else 0.0
		_raiz.visible = true
		_raiz.modulate = Color(1, 1, 1, alfa)
		passo(0.0)

	func passo(delta: float) -> void:
		_t += delta
		var p := _t / _dur
		if p >= 1.0:
			ativo = false
			_raiz.visible = false
			return
		# Sobe rápido no começo e desacelera; some nos últimos 35%.
		var subiu := _subida * (1.0 - pow(1.0 - p, 1.6))
		_raiz.position = Vector2(floorf(_origem.x), floorf(_origem.y - subiu))
		_principal.position = Vector2(-100, -7)
		_extra.position = Vector2(-100, -7 - 15.0 - _alt)
		_raiz.modulate.a = _alfa * (1.0 if p < 0.65 else 1.0 - (p - 0.65) / 0.35) * _sumir

	## Letreiro de fim: `p` de 0 a 1 apaga o número (a 1 ele sai de cena). `gen` é o uso que estava na tela quando o fade começou.
	func sumir_com(p: float, gen: int) -> void:
		if not ativo or gen != _gen:
			return
		_sumir = 1.0 - clampf(p, 0.0, 1.0)
		_raiz.modulate.a = minf(_raiz.modulate.a, _alfa * _sumir)
		if p >= 1.0:
			ativo = false
			_raiz.visible = false


## Seta que balança sobre o alvo central até o primeiro clique.
class Seta extends Node2D:
	var _t := 0.0
	var _desloc := 0

	func passo(delta: float) -> void:
		_t += delta
		var d := int(round(sin(_t * 7.0) * 2.0))
		if d != _desloc:
			_desloc = d
			queue_redraw()

	func _draw() -> void:
		var cx := 336
		var topo := 150 + _desloc
		for i in 6:
			draw_rect(Rect2(cx - 6 + i - 1, topo + i * 2 - 1, 13 - 2 * i + 2, 4), UiTema.INK)
		for i in 6:
			draw_rect(Rect2(cx - 5 + i, topo + i * 2, 11 - 2 * i, 2), UiTema.Y1)


## Efeito de poeira da chegada na academia (quadros 0..n-1 a 12 fps).
func _tocar_chegada(a: AnimSprite, p: Vector2, quadros: int) -> void:
	a.position = p
	a.visible = true
	var seq: Array = []
	for i in quadros:
		seq.append(i)
	a.tocar(seq, 12.0, false, func() -> void: a.visible = false)


# --- Fase 6b1: cena de passar o posto, câmera, John mentor sentado no caixote e os toques ---

## Em cena a sala usa o saco no centro (o palco da cena); fora dela, o foco de verdade.
func _foco() -> String:
	return SACO if _cena_ativa else GameState.foco


func _cam_base() -> Vector2:
	return -_cam_rect.position * float(_cam_escala)


## A cena assume a sala. `oculta` = stage.hide da cena (player, crew, mentors, coach).
## `livre` (6c1, saída do John): o jogador segue no controle; a sala só esconde o que o `stage.hide` pede (foco, câmera e layout ficam).
func cena_iniciar(oculta: Array, livre: bool = false) -> void:
	_cena_livre = livre
	_cena_ativa = not livre
	_cena_oculta = oculta.duplicate()
	_caixote_cena = false
	_saco_da_cena = false
	if not livre:
		_aplicar_layout()
	_atualizar_osmar()
	_atualizar_mentor()
	_atualizar_parede()
	_ocultar_da_cena()


## A saída do John acabou (sozinha ou interrompida): a sala redesenha Osmar e mentores pelo que o jogo diz agora.
func cena_livre_encerrada() -> void:
	if not _cena_livre:
		return
	_cena_livre = false
	_cena_oculta = []
	_atualizar_osmar()
	_atualizar_mentor()
	_atualizar_parede()


## Saco da sala na cena da academia: só aparece quando a cena o pendura.
func cena_saco_visivel(sim: bool) -> void:
	_saco_da_cena = sim


## Passo `fx` da cena: hoje só a poeira da chegada do saco (fx_arrive_dust_small); outros ids são ignorados.
func cena_fx(sprite: String, pos: Array) -> void:
	if sprite == "fx_arrive_dust_small" and pos.size() == 2 and _fx_poeira_pequena != null:
		_tocar_chegada(_fx_poeira_pequena, Vector2(float(pos[0]), float(pos[1])), 6)


## O controle voltou ao jogador (return_control): a sala é do jogo de novo (as peças da porta ficam no palco até a cena acabar).
func cena_palco_liberado() -> void:
	if not _cena_ativa:
		return
	_cena_ativa = false
	_cena_oculta = []
	_saco_da_cena = false
	_lutador.visible = true
	_saco.visible = true
	_corrente.visible = true
	for gid in _pessoas:
		for d in _pessoas[gid]:
			d.sprite.visible = d.visivel
			d.sombra.visible = d.visivel
	for cx in _caixas.values():
		if is_instance_valid(cx):
			(cx as CanvasItem).visible = true
	_aplicar_layout()
	_aplicar_metronomo()
	_sincronizar_caixas()
	_atualizar_osmar()
	_atualizar_mentor()
	cena_camera(1, [])


func cena_caixote(sim: bool) -> void:
	_caixote_cena = sim
	_atualizar_mentor()


## Corte seco de câmera: escala 2 numa janela (rect na base 640x360) ou volta ao 1x.
func cena_camera(escala: int, rect: Array) -> void:
	_cam_escala = maxi(1, escala)
	_cam_rect = Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3])) if _cam_escala > 1 and rect.size() == 4 else _area
	_mundo.scale = Vector2(_cam_escala, _cam_escala)
	_mundo.position = _cam_base()


func cena_tremer(px: int, seg: float) -> void:
	_tremer(px, seg)


## Saco do palco: "hit" (folha bag_l0_hit) ou "idle" (quadro parado).
func cena_saco(anim: String, quadro: int) -> void:
	if anim == "hit":
		_saco.definir(_n("bag_l0_hit"))
		_saco.position = UiTema.pos(_n("bag_l0_hit"), "centro")
		_saco.tocar([0, 1, 2, 3], 12.0, false)
	else:
		_saco.definir(_n("bag_l0_idle"))
		_saco.position = UiTema.pos(_n("bag_l0_idle"), "centro")
		_saco.parar(maxi(0, quadro))


func cena_lampada(anim: String) -> void:
	if anim == "swing":
		_lampada.tocar([1, 0, 1, 0], 6.0, false, func() -> void: _lampada.parar(0))
	else:
		_lampada.parar(0)


func _ocultar_da_cena() -> void:
	if not _cena_ativa and not _cena_livre:
		return
	if _cena_ativa:
		_seta.visible = false
	if "apparatus" in _cena_oculta:  # 6c1: a academia da chegada começa sem aparelho (o saco volta quando a cena o pendura)
		_saco.visible = _saco_da_cena
		_corrente.visible = _saco_da_cena
		_esteira.visible = false
		_corda_prego.visible = false
		_pera.visible = false
		_boneco.visible = false
		_metronomo.visible = false
	if "boxes" in _cena_oculta:
		for cx in _caixas.values():
			if is_instance_valid(cx):
				(cx as CanvasItem).visible = false
	if "wall_objects" in _cena_oculta:
		for k in _parede:
			(_parede[k].sprite as CanvasItem).visible = false
	if _cena_ativa:
		for t in _tubos:  # o tubo da direita da cena (apagado) é do palco: os tubos da sala voltam com ela
			t.visible = false
	if "player" in _cena_oculta:
		_lutador.visible = false
		_sombra_lutador.visible = false
		_corda_giro.visible = false
		_corda_costas.visible = false
	if "crew" in _cena_oculta:
		for gid in _pessoas:
			for d in _pessoas[gid]:
				d.sprite.visible = false
				d.sombra.visible = false


func _montar_mentor() -> void:
	_mentor_sombra = Sprite2D.new()
	_mentor_sombra.texture = UiTema.textura("floor_shadow")
	_mentor_sombra.visible = false
	_mundo.add_child(_mentor_sombra)
	_caixote = Sprite2D.new()
	_caixote.centered = false
	_caixote.texture = UiTema.textura("garage_crate")
	_caixote.visible = false
	_mundo.add_child(_caixote)
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("mentor_spot", {})
	var c: Dictionary = info.get("crate", {})
	var cp: Array = c.get("pos", [238, 232])  # canto superior esquerdo do caixote (já inclui o pivô)
	_caixote.position = Vector2(float(cp[0]), float(cp[1]))
	_caixote.z_index = int(c.get("sort_y", 250))
	_mentor = _novo_anim(MENTOR_FOLHA, "", 0)
	_mentor.position = ponto_mentor()
	_mentor.z_index = int(_mentor.position.y)
	_mentor.visible = false
	_mentor_sombra.position = _mentor.position + Vector2(0, -1)
	_mentor_sombra.z_index = _mentor.z_index - 1
	_mentor2_sombra = Sprite2D.new()
	_mentor2_sombra.texture = UiTema.textura("floor_shadow")
	_mentor2_sombra.visible = false
	_mundo.add_child(_mentor2_sombra)
	_mentor2 = _novo_anim("disciple_stand_bare", "", 0)
	_mentor2.visible = false
	_mentor2.position = ponto_mentor2()
	_mentor2.z_index = int(_mentor2.position.y)
	_mentor2_sombra.position = _mentor2.position + Vector2(0, -1)
	_mentor2_sombra.z_index = _mentor2.z_index - 1


## Pés do segundo mentor: manifest.layout.mentor_2_spot.
func ponto_mentor2() -> Vector2:
	var p: Array = GameState.ponto_do_local("stand")  # 6c1: o ponto do local (garagem ou academia)
	if p.size() != 2:
		p = UiTema.manifest().get("layout", {}).get("mentor_2_spot", [150, 262])
	return Vector2(float(p[0]), float(p[1]))


## Ponto logo acima da cabeça do segundo mentor: head_anchor da folha dele (medido com o corte mais alto).
func cabeca_mentor2() -> Vector2:
	var nome := _mentor2.nome_sprite if _mentor2 != null and _mentor2.nome_sprite != "" else "disciple_stand_bare"
	var a: Array = UiTema.sprite(nome).get("head_anchor", [1, -65])
	return ponto_mentor2() + Vector2(float(a[0]), float(a[1]))


func mentor2_visivel() -> bool:
	return _mentor2_visivel


## Retângulo do corpo do segundo mentor (para a dica ao passar o mouse; ele não é alvo de clique).
func _area_mentor2() -> Rect2:
	var o: Array = UiTema.manifest().get("layout", {}).get("mentor_2_spot_info", {}).get("occupies", [138, 197, 25, 67])
	return Rect2(float(o[0]), float(o[1]), float(o[2]), float(o[3]))


## Pés do mentor sentado: manifest.layout.mentor_spot.
func ponto_mentor() -> Vector2:
	var p: Array = GameState.ponto_do_local("seat")  # 6c1: o ponto do local (garagem ou academia)
	if p.size() != 2:
		p = UiTema.manifest().get("layout", {}).get("mentor_spot", [254, 252])
	return Vector2(float(p[0]), float(p[1]))


## Ponto logo acima da cabeça do mentor sentado: head_anchor da folha dele (john_sit_rest, ou disciple_sit_rest para o último).
func cabeca_mentor() -> Vector2:
	var a: Array = UiTema.sprite(_folha_mentor()).get("head_anchor", [1, -56])
	return ponto_mentor() + Vector2(float(a[0]), float(a[1]))


func _folha_mentor() -> String:
	if _mentor_quem == "last" and not UiTema.sprite("disciple_sit_rest").is_empty():
		return "disciple_sit_rest"
	return MENTOR_FOLHA


func mentor_visivel() -> bool:
	return _mentor_visivel


func _atualizar_mentor() -> void:
	if _mentor == null:
		return
	# 6c1: quem a sala desenha vem de mentores_na_sala() (garagem e academia, antes e depois da saída do John):
	# `role "seat"` no caixote (John, ou o último que passou o posto depois da saída) e `role "stand"` em pé.
	var seat := {}
	var stand := {}
	if not ("mentors" in _cena_oculta):
		for m in GameState.mentores_na_sala():
			if str(m.get("role", "")) == "seat":
				seat = m
			elif str(m.get("role", "")) == "stand":
				stand = m
	_atualizar_mentor2(stand)
	# O caixote fica com ou sem gente sentada (assento_visivel); na cena grande ele só aparece quando a cena o pousa.
	var tex_caixote := UiTema.com_local("garage_crate")
	var caixote := ((GameState.assento_visivel() or not seat.is_empty()) and not _cena_ativa) or _caixote_cena  # quem senta sempre tem o caixote
	if _caixote.visible != caixote:
		_caixote.visible = caixote
	if caixote and _caixote.texture != UiTema.textura(tex_caixote):
		_caixote.texture = UiTema.textura(tex_caixote)
	if caixote and UiTema.sprite(tex_caixote).has("pos"):  # 8a2: o caixote vai para o ponto do local (garagem 216,250; academia e centro 116,234)
		_caixote.position = UiTema.pos(tex_caixote)
		_caixote.z_index = int(UiTema.sprite(tex_caixote).get("sort_y", 250))
	var deve := not seat.is_empty()
	var chave := ""
	if deve:
		chave = "%s|%s|%s|%s" % [seat.get("id", ""), JSON.stringify(seat.get("look", {})), str(seat.get("point", [])), GameState.simbolo_na_entrada({"kind": "disciple", "campaign": int(seat.get("campaign", 0))}) if str(seat.get("id", "")) == "last" else false]
	if deve != _mentor_visivel or chave != _mentor_chave:
		_mentor_visivel = deve
		_mentor_chave = chave
		_mentor.visible = deve
		_mentor_sombra.visible = deve
		if deve:
			_mentor_quem = str(seat.get("id", "first"))
			_mentor_look = seat.get("look", {})
			_mentor_campanha = int(seat.get("campaign", 0))
			_mentor.position = ponto_mentor()
			_mentor.z_index = int(_mentor.position.y)
			_mentor_sombra.position = _mentor.position + Vector2(0, -1)
			_mentor_sombra.z_index = _mentor.z_index - 1
			_mentor_repouso()


## Segundo mentor (6b2): parado em `stand_bare`, sem luvas, com o visual que tinha, virado para o saco. Sem clique nem fala.
## `d` = o item `role "stand"` de mentores_na_sala(), ou {}.
func _atualizar_mentor2(d: Dictionary) -> void:
	if d.is_empty():
		if _mentor2_visivel:
			_mentor2_visivel = false
			_mentor2.visible = false
			_mentor2_sombra.visible = false
			_mentor2_chave = ""
			_mentor2_nome = ""
		return
	var folha := "disciple_" + str(d.get("pose", "stand_bare"))
	if str(d.get("facing", "right")) == "left" and str(UiTema.sprite(folha).get("left_variant", "")) != "":
		folha = str(UiTema.sprite(folha).left_variant)  # folha própria da esquerda, sem espelhar
	var look: Dictionary = d.get("look", {})
	var chave := folha + "|" + JSON.stringify(look) + "|" + str(d.get("point", [])) + "|" + str(GameState.simbolo_na_entrada({"kind": "disciple", "campaign": int(d.get("campaign", 0))}))
	if chave != _mentor2_chave:
		_mentor2_chave = chave
		_mentor2.position = ponto_mentor2()
		_mentor2.z_index = int(_mentor2.position.y)
		_mentor2_sombra.position = _mentor2.position + Vector2(0, -1)
		_mentor2_sombra.z_index = _mentor2.z_index - 1
		_mentor2.definir(folha)
		_mentor2.texture = DiscVisual.textura(folha, look, GameState.simbolo_na_entrada({"kind": "disciple", "campaign": int(d.get("campaign", 0))}))
		_mentor2.tocar([0, 1, 2, 3], float(UiTema.sprite(folha).get("fps", 4.0)), true)
	_mentor2_nome = str(d.get("name", ""))
	if not _mentor2_visivel:
		_mentor2_visivel = true
		_mentor2.visible = true
		_mentor2_sombra.visible = true


func _mentor_repouso() -> void:
	_mentor_pose = "rest"
	var folha := _folha_mentor()
	_mentor.definir(folha)
	if folha != MENTOR_FOLHA:
		_mentor.texture = DiscVisual.textura(folha, _mentor_look, GameState.simbolo_na_entrada({"kind": "disciple", "campaign": _mentor_campanha}))  # o último que passou o posto: o visual dele
	_mentor.position = ponto_mentor()
	_mentor.tocar([0, 1, 2, 3], float(UiTema.sprite(folha).get("fps", 3.0)), true)


func _mentor_toques_pose() -> void:
	if _mentor_quem != "first":
		return  # os toques são só do John
	_mentor_pose = "taps"
	_mentor.definir(MENTOR_TOQUES)
	_mentor.position = ponto_mentor()
	_mentor.tocar([0, 1, 2, 3], float(UiTema.sprite(MENTOR_TOQUES).get("fps", 9.0)), false)


## A cena (reação do 1º clique) manda o John do palco: depois do return_control ele é o mentor da sala.
func cena_mentor_pose(anim: String) -> void:
	_atualizar_mentor()
	if not _mentor_visivel:
		return
	if anim == MENTOR_TOQUES:
		_mentor_toques_pose()
	else:
		_mentor_repouso()


func _ao_toques_pedidos(plano: Dictionary) -> void:
	if str(plano.get("cena", "")) != "" or not _mentor_visivel or _mentor_quem != "first":
		return  # o 1º clique logo depois da cena grande é da reação da cena (CenaPlayer)
	_toques_id += 1
	var id := _toques_id
	var t0 := Time.get_ticks_msec()
	var ini := float(plano.get("start", 0.0))
	if ini > 0.0:
		await get_tree().create_timer(ini).timeout
		if id != _toques_id:
			return
	_mentor_toques_pose()
	var taps: Array = plano.get("taps", [0.11, 0.33])
	for n in taps.size():
		var falta := ini + float(taps[n]) - float(Time.get_ticks_msec() - t0) / 1000.0
		if falta > 0.0:
			await get_tree().create_timer(falta).timeout
		if id != _toques_id:
			return
		sfx.por_id(str(plano.get("tap_sound", "tap_fist")), 1.0)
		var pts: Array = UiTema.sprite(MENTOR_TOQUES).get("tap_points", [[5, -30]])
		var tp: Array = pts[mini(n, pts.size() - 1)]
		_impacto(_mentor.position + Vector2(float(tp[0]), float(tp[1])), false)
	var resto := ini + float(plano.get("duration", 0.44)) - float(Time.get_ticks_msec() - t0) / 1000.0
	if resto > 0.0:
		await get_tree().create_timer(resto).timeout
	if id == _toques_id and _mentor_visivel:
		_mentor_repouso()


func _ao_toques_cancelados() -> void:
	_toques_id += 1  # o 2º toque (ainda no temporizador) não toca mais
	if _mentor_pose == "taps" and _mentor_visivel:
		_mentor_repouso()
