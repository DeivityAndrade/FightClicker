class_name Sala
extends Control
## A sala da garagem montada pelos sprites e posições do manifest, mais o juice do clique.
## Só lê o estado (sinais do GameState) e chama GameState.clicar()/definir_foco().
## Coordenadas internas = coordenadas da tela base 640x360 (o nó "Mundo" compensa a posição da sala).

const AREA := Rect2(128, 18, 384, 272)
const ALVO := Rect2(312, 182, 48, 90)  # área clicável central (manifest.click_area)
const PONTO_PADRAO := Vector2(336, 222)
const POOL_NUMEROS := 24
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
const BR0 := Color("3b2622")  # caneta da plaquinha de papelão (direcao-visual §3)

## Clique na marca de fita (ou na plaquinha) de um aparelho que ainda não chegou: a garagem abre a aba TREINO.
signal marca_clicada(aparelho: String)

var sfx: Sfx
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

# Fase 4b: marcas de fita no lugar dos aparelhos que faltam e a chegada deles.
var _marcas: Dictionary = {}  # aparelho -> {fita, fantasma, placa, extras, chave, rect, m}
var _chegando := ""  # aparelho que está caindo/sendo pendurado agora ("" = nenhum)
var _impactou := false  # a marca já sumiu (quadro de impacto)?
var _tween_chegada: Tween
var _fx_poeira_chegada: AnimSprite
var _fx_brilho_chegada: AnimSprite
var _fx_poeira_pequena: AnimSprite


func _ready() -> void:
	_rng.randomize()
	position = AREA.position
	size = AREA.size
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
	GameState.metronomo_mudou.connect(_ao_metronomo)
	GameState.aparelho_comprado.connect(_ao_aparelho_comprado)
	GameState.economia_mudou.connect(_atualizar_marcas)
	GameState.local_mudou.connect(_ao_local)
	GameState.arte_mudou.connect(_ao_arte)
	_local_anterior = GameState.local_id
	_aplicar_layout()
	_atualizar_pessoas(false)
	_aplicar_metronomo()
	_montado = true


# --- Montagem ---

func _montar() -> void:
	_mundo = Node2D.new()
	_mundo.position = -AREA.position
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
	_montar_marcas()


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
	if _chegando != "":
		return  # o aparelho novo está caindo: a chegada termina com _aplicar_layout()
	_aplicar_local()
	var foco := GameState.foco
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
	_corda_prego.visible = foco != CORDA and GameState.aparelho_montado(CORDA)  # sem corda: só a marca de fita no prego
	_corda_giro.visible = false
	_corda_costas.visible = false

	# Esteira: no centro (foco) ou à direita.
	var nome_esteira := _n("treadmill_l%d_idle" % ne) if foco == ESTEIRA else _n("treadmill_l%d_side" % ne)
	var chave_e := "centro" if foco == ESTEIRA else "lado_direito"
	_esteira.definir(nome_esteira)
	_esteira.position = UiTema.pos(nome_esteira, chave_e)
	_esteira.z_index = int(_esteira.position.y)
	_esteira.parar(0)
	_esteira.visible = GameState.aparelho_montado(ESTEIRA)  # sem esteira: só a marca de fita no chão
	_corrida = 0.0

	_aplicar_arte(PERA, foco)
	_aplicar_arte(BONECO, foco)
	_pose_repouso()
	_atualizar_marcas()


# Lutador parado conforme o foco.
func _pose_repouso() -> void:
	var foco := GameState.foco
	_corda_giro.visible = false
	_corda_costas.visible = false
	match foco:
		SACO, PERA, BONECO:  # a pera e o boneco usam o fighter_idle/punch no ponto do saco (303,272)
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
	_lampada.visible = not tubos
	for t in _tubos:
		t.visible = tubos


## Pera (Boxe) e boneco (Jiu-jitsu): só existem na carreira da arte e depois de comprados. No foco ficam no centro
## (em pé / sentado); fora dele, a pera na parede e o boneco deitado no canto. Aparelho de outra arte: nada é desenhado.
func _aplicar_arte(id: String, foco: String) -> void:
	var a: AnimSprite = _pera if id == PERA else _boneco
	var base := "speed_bag" if id == PERA else "grappling_dummy"
	var existe := GameState.estado_aparelho(id) == "owned" or (_chegando == id)
	a.visible = existe
	if not existe:
		return
	var n := GameState.nivel_visual(id)
	if foco == id:
		var nome := "%s_l%d_idle" % [base, n]
		a.definir(nome)
		a.position = UiTema.pos(nome, "centro")
		a.z_index = int(UiTema.sprite(nome).get("sort_y", a.position.y))
		if id == PERA:
			a.tocar([0, 1], 2.0, true)  # balanço leve
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_clique_em(event.position + position)
		accept_event()


func _clique_em(p: Vector2) -> void:
	if ALVO.has_point(p):
		_pos_clique = p
		GameState.clicar()
		return
	# Clique em aparelho lateral só troca o foco (não gera treino). Fase 5: inclui o aparelho da arte, se existir.
	for ap in GameState.aparelhos_da_carreira():
		var id := str(ap.id)
		if not GameState.aparelho_montado(id):
			# Marca de fita de um aparelho que falta: nada de treino nem troca de foco, só aponta a compra.
			if _marcas.has(id) and _marcas[id].fita.visible and Rect2(_marcas[id].rect).has_point(p):
				sfx.foco()
				marca_clicada.emit(id)
				return
		elif id != GameState.foco and _area_lateral(id).has_point(p):
			GameState.definir_foco(id)
			sfx.foco()
			return


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
	return _esteira


func _area_lateral(id: String) -> Rect2:
	var s: AnimSprite = _anim_do(id)
	var tam := UiTema.tamanho_quadro(s.nome_sprite)
	return Rect2(s.position - UiTema.pivo(s.nome_sprite), tam)


# --- Juice do clique ---

func _ao_clicar(ganho: float, critico: bool, aparelho: String, atributo: String, texto: String) -> void:
	_terminar_chegada()
	var p := _pos_clique
	_pos_clique = PONTO_PADRAO
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
	var x := clampf(p.x + dx, AREA.position.x + 60.0, AREA.end.x - 60.0)
	var y := clampf(p.y - 6.0, AREA.position.y + 40.0, AREA.end.y - 8.0)
	_ordem += 1
	# Mais recente por cima; crítico sempre acima dos normais (z fica abaixo do cursor, 4000).
	n.definir_z(Z_NUMEROS + (1000 if critico else 0) + _ordem % 900)
	if critico:
		n.iniciar("+%s %s!" % [NumberFormat.fmt(ganho), nome], UiTema.R3, true, texto, Vector2(x, y - 4.0), 0.85, 34.0)
	else:
		n.iniciar("+%s %s" % [NumberFormat.fmt(ganho), nome], UiTema.cor_atributo(atributo).lerp(UiTema.WHITE, 0.55 if atributo == "strength" else 0.25),
			false, "", Vector2(x, y), 0.55, 30.0)
	_afastar_antigos(n, critico)


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
	_terminar_chegada()
	_acc_m = 0.0
	_socos_m += 1
	var n := _pegar_numero()
	var dx := float([-26, 26, -12, 12][_desvio_auto % 4])
	_desvio_auto += 1
	var x := clampf(PONTO_PADRAO.x + dx, AREA.position.x + 60.0, AREA.end.x - 60.0)
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
			_pera.definir("speed_bag_l%d_hit" % np_)
			_pera.tocar([0, 1, 2, 3, 4], 18.0, false, _pera_repouso)
			_impacto(_ponto_impacto(_pera.nome_sprite, "speed_bag", Vector2(325, 218)), critico)
		BONECO:
			# O boneco amassa, tomba e volta (3 quadros a 12 fps). Sem pose de grappling nesta fase: o lutador soca.
			var nd_ := GameState.nivel_visual(BONECO)
			_lutador.definir(_f("fighter_punch"))
			_lutador.tocar([1, 2, 3], 18.0, false, _pose_repouso)
			_boneco.definir("grappling_dummy_l%d_hit" % nd_)
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


## O saco reage ao golpe (só o visual): jab = o balanço de sempre; uppercut = pula para cima; lateral = vai para o lado e volta
## com folga. `critico` exagera. A corrente do saco segue. Se o layout mudar no meio (troca de foco), o balanço é cancelado.
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
	_pera.definir("speed_bag_l%d_idle" % GameState.nivel_visual(PERA))
	_pera.tocar([0, 1], 2.0, true)


func _boneco_repouso() -> void:
	_boneco.definir("grappling_dummy_l%d_idle" % GameState.nivel_visual(BONECO))
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
			PERA, BONECO:
				dy = -60 if GameState.foco == aparelho else 48  # em foco: acima do aparelho; senão logo abaixo do descanso
		_mostrar_texto(alvo.position + Vector2(0, dy), str(ups[nivel - 1].get("name", "")).to_upper(), UiTema.Y1)
	_critico_fx(alvo.position + Vector2(0, 30 if aparelho == SACO else (-30 if aparelho in [PERA, BONECO] and GameState.foco == aparelho else -10)))


func _mostrar_texto(p: Vector2, texto: String, cor: Color) -> void:
	var n := _pegar_numero()
	n.iniciar(texto, cor, false, "", Vector2(clampf(p.x, AREA.position.x + 80.0, AREA.end.x - 80.0), maxf(p.y, 60.0)), 1.1, 18.0)


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
	_mostrar_texto(_lutador.position + Vector2(0, -74), str(GameState.luva_equipada().get("name", "")).to_upper(), UiTema.Y1)


# Nome do sprite do lutador com a luva equipada ("fighter_idle" + "_glove_l1").
func _f(base: String) -> String:
	return UiTema.com_luva(base)


func _ids_geradores() -> Array:
	var ids: Array = []
	for g in GameState.dados.geradores:
		ids.append(g.id)
	for g in GameState.lutas.geradores_pagos:
		ids.append(g.id)
	return ids


func _ao_carreira() -> void:
	if _montado:
		_cancelar_chegada()
		_chegada_pendente = false
		_local_anterior = GameState.local_id
		_aplicar_layout()
		_atualizar_pessoas(false)


## Luz da sala: lâmpada da garagem (crítico: balança; de vez em quando pisca) ou tubo da direita da academia (falha).
func _piscar_luz(forte: bool) -> void:
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
	_cancelar_chegada()
	_aplicar_layout()
	_atualizar_pessoas(false)
	if antes != "gym" and local == "gym":
		_chegada_pendente = true
		if not GameState.escolha_arte_pendente():
			_festa_academia()


func _ao_arte(arte: String) -> void:
	if not _montado:
		return
	_cancelar_chegada()
	_aplicar_layout()  # a marca de fita (e a plaquinha) do aparelho da arte aparecem; sem arte, somem
	if arte != "" and _chegada_pendente:
		_festa_academia()


func _festa_academia() -> void:
	_chegada_pendente = false
	_mundo.modulate = Color(2.4, 2.4, 2.4)
	_mundo.create_tween().tween_property(_mundo, "modulate", Color.WHITE, 0.4)
	_tocar_chegada(_fx_poeira_chegada, Vector2(336, 240), 6)
	_tremer(2, 0.14)
	sfx.queda()
	var n := _pegar_numero()
	_ordem += 1
	n.definir_z(Z_NUMEROS + 1000 + _ordem % 900)
	n.iniciar(UiTema.txt("move_arrived", "BEM-VINDO À BOA ESQUINA!"), UiTema.Y1, true, "", Vector2(336, 140), 2.0, 12.0)


# --- Fase 4b: marcas de fita, plaquinhas e a chegada dos aparelhos ---

## Uma marca de fita (+ sombra pontilhada com cadeado) por aparelho que tem `unlock`. A plaquinha de papelão é
## montada depois, conforme o texto do estado (`textos_trancado`).
func _montar_marcas() -> void:
	var por_id: Dictionary = UiTema.manifest().get("by_data_id", {})
	for ap in GameState.dados.todos_aparelhos():  # Fase 5: inclui pera e boneco (só aparecem na carreira da arte)
		var u: Dictionary = ap.get("unlock", {})
		if u.is_empty():
			continue
		var m: Dictionary = por_id.get(str(u.get("id", "")), {})
		if m.is_empty():
			continue
		var mp: Array = m.mark_pos
		var pos_marca := Vector2(float(mp[0]), float(mp[1]))
		var nome_fita := str(m.floor_mark)
		var nome_fantasma := str(m.ghost)
		var fita := _novo_anim(nome_fita, "", int(UiTema.sprite(nome_fita).get("z", -30)))
		fita.position = pos_marca
		var fantasma := _novo_anim(nome_fantasma, "", int(UiTema.sprite(nome_fantasma).get("z", -29)))
		fantasma.position = pos_marca
		var area_fita := Rect2(pos_marca - UiTema.pivo(nome_fita), UiTema.tamanho_quadro(nome_fita))
		_marcas[str(ap.id)] = {"fita": fita, "fantasma": fantasma, "placa": null, "extras": [], "chave": "",
			"rect": area_fita, "area_fita": area_fita, "m": m}
	_atualizar_marcas()


## Marca visível = aparelho ainda não montado (ou caindo agora, antes do impacto). A plaquinha acompanha o texto.
func _atualizar_marcas() -> void:
	for id in _marcas:
		var d: Dictionary = _marcas[id]
		var estado := GameState.estado_aparelho(id)  # "absent" (aparelho de outra arte): não desenha nada
		var mostrar: bool = (estado != "owned" and estado != "absent") or (_chegando == id and not _impactou)
		d.fita.visible = mostrar
		d.fantasma.visible = mostrar
		if mostrar:
			_montar_placa(id)
		else:
			_limpar_placa(id)


func _limpar_placa(id: String) -> void:
	var d: Dictionary = _marcas[id]
	if d.placa != null and is_instance_valid(d.placa):
		d.placa.queue_free()
	for e in d.extras:
		if is_instance_valid(e):
			e.queue_free()
	d.placa = null
	d.extras = []
	d.chave = ""
	d.rect = d.area_fita


## Plaquinha de papelão: 9-slice do tamanho do texto (margens 5/4/5/5), texto 1x em br0 sem sombra, centrado,
## uma linha por parte (a fonte não tem travessão: quebra no " — "). No chão fica em pé sobre um tijolo; na parede,
## colada com dois pedaços de fita acima do prego.
func _montar_placa(id: String) -> void:
	var d: Dictionary = _marcas[id]
	var t: Dictionary = GameState.textos_trancado(id)
	if t.is_empty():
		return  # já montado (a chegada está em andamento): fica a plaquinha que estava
	var texto := str(t.floor_mark).to_upper()
	if texto == str(d.chave) and d.placa != null:
		return
	_limpar_placa(id)
	d.chave = texto
	var sinal: Dictionary = d.m.get("sign", {})
	var parede := str(sinal.get("mode", "chao")) == "parede"
	var linhas: Array[String] = []
	var partes := texto.split(" — ", false)
	if partes.size() >= 2:
		linhas.append(partes[0].strip_edges())
		var resto := partes[1].strip_edges()
		var cortar := resto.rfind(" ")
		if parede and str(t.after) != "" and cortar > 0:
			# Na parede não cabe "DEPOIS DA ESTEIRA" numa linha só: 3 linhas (CORDA / DEPOIS DA / ESTEIRA).
			linhas.append(resto.substr(0, cortar))
			linhas.append(resto.substr(cortar + 1))
		else:
			linhas.append(resto)
	else:
		linhas.append(texto.replace(" — ", " - "))
	var larg := 0.0
	for l in linhas:
		larg = maxf(larg, UiTema.largura_visivel(l))
	var w := int(ceil(larg)) + 10
	var h := 4 + linhas.size() * 7 + (linhas.size() - 1) * 2 + 5
	var raiz := Node2D.new()
	_mundo.add_child(raiz)
	UiTema.nine_patch(raiz, "sign_cardboard", Rect2(0, 0, w, h))
	for i in linhas.size():
		var rot := UiTema.rotulo(raiz, linhas[i], BR0, 5, 4 + i * 9 - 2, 0, HORIZONTAL_ALIGNMENT_CENTER, false)
		rot.size = Vector2(w - 10, 12)
	var extras: Array = []
	if parede:
		if sinal.has("top_center"):
			# Pera (Fase 5): plaquinha centrada em x, logo abaixo da marca (manifest: top_center).
			var tc: Array = sinal.top_center
			raiz.position = Vector2(floorf(float(tc[0]) - w / 2.0), float(tc[1]))
		else:
			var tl: Array = sinal.get("top_left", [340, 37])
			raiz.position = Vector2(float(tl[0]), float(tl[1]))
		raiz.z_index = -20
		for dx in [2, w - 3]:
			var fita := _novo_anim(str(sinal.get("tape", "sign_tape_bit")), "", -19)
			fita.position = raiz.position + Vector2(dx, 1)
			extras.append(fita)
	else:
		var bc: Array = sinal.get("bottom_center", [445, 257])
		raiz.position = Vector2(floorf(float(bc[0]) - w / 2.0), float(bc[1]) - h)
		raiz.z_index = int(bc[1])
		var tj: Array = sinal.get("brick_pos", bc)
		var tijolo := _novo_anim(str(sinal.get("brick", "sign_brick")), "", int(bc[1]) + 1)
		tijolo.position = Vector2(float(tj[0]), float(tj[1]))
		extras.append(tijolo)
	d.placa = raiz
	d.extras = extras
	d.rect = Rect2(d.area_fita).merge(Rect2(raiz.position, Vector2(w, h)))


## Aparelho comprado: ele cai (esteira) ou é pendurado (corda), a marca some no quadro de impacto, sai poeira ou
## brilho, e só depois o layout leva o foco para ele. Um clique durante a queda encerra a chegada na hora.
func _ao_aparelho_comprado(id: String) -> void:
	if not _montado:
		return
	_terminar_chegada()
	var u: Dictionary = GameState.desbloqueio(id)
	var m: Dictionary = UiTema.manifest().get("by_data_id", {}).get(str(u.get("id", "")), {})
	var alvo: AnimSprite = _anim_do(id) if id in [ESTEIRA, CORDA, PERA, BONECO] else null
	if alvo == null or m.is_empty():
		return
	var fx_nome := str(m.get("arrive", {}).get("fx", ""))
	# 4b: os deslocamentos da queda estão no sprite do efeito; Fase 5: no próprio bloco `arrive.drop` do manifest.
	var drop_data = m.get("arrive", {}).get("drop", UiTema.sprite(fx_nome).get("drop", {}))
	# Esteira e corda trazem em `arrive.drop` só um texto ("ver sprites.fx_...drop"): nesse caso vale o `drop` do sprite do efeito.
	if not drop_data is Dictionary:
		drop_data = UiTema.sprite(fx_nome).get("drop", {})
	var drop: Dictionary = drop_data if drop_data is Dictionary else {}
	var desloc: Array = drop.get("offsets_y", [0])
	var passo := 1.0 / maxf(1.0, float(drop.get("fps", 24)))
	var base: Vector2
	if id == ESTEIRA:
		var nome := _n("treadmill_l%d_side" % GameState.nivel_visual(ESTEIRA))
		alvo.definir(nome)
		alvo.parar(0)
		base = UiTema.pos(nome, "lado_direito")
		alvo.z_index = int(base.y)
	elif id == PERA:
		var nome := _n("speed_bag_l%d_wall" % GameState.nivel_visual(PERA))  # a plataforma cai presa na parede
		alvo.definir(nome)
		alvo.parar(0)
		base = UiTema.pos(nome, "parede")
		alvo.z_index = int(UiTema.sprite(nome).get("z", -40))
	elif id == BONECO:
		var nome := _n("grappling_dummy_l%d_rest" % GameState.nivel_visual(BONECO))  # o tatame com o boneco cai no canto
		alvo.definir(nome)
		alvo.parar(0)
		base = UiTema.pos(nome, "canto")
		alvo.z_index = int(UiTema.sprite(nome).get("sort_y", 270))
	else:
		var nome := _n("rope_l%d_idle" % GameState.nivel_visual(CORDA))
		alvo.definir(nome)
		alvo.parar(0)
		base = UiTema.pos(nome, "prego")
	var impacto := 0
	for i in desloc.size():
		if float(desloc[i]) >= 0.0:
			impacto = i
			break
	_chegando = id
	_impactou = false
	alvo.position = base + Vector2(0, float(desloc[0]))
	alvo.visible = true
	var tw := create_tween()
	_tween_chegada = tw
	for i in desloc.size():
		var dy := float(desloc[i])
		tw.tween_callback(func() -> void: alvo.position = base + Vector2(0, dy))
		if i == impacto:
			tw.tween_callback(_impacto_chegada.bind(id, m, int(drop.get("shake_px", 0))))
		tw.tween_interval(passo)
	if id == PERA:
		tw.tween_interval(0.5)  # a pera balança (6 quadros a 12 fps) antes de ir para o foco
	tw.tween_callback(_terminar_chegada)


func _impacto_chegada(id: String, m: Dictionary, tremida: int) -> void:
	_impactou = true
	_atualizar_marcas()
	var fxp: Array = m.get("arrive", {}).get("fx_pos", [336, 240])
	var p := Vector2(float(fxp[0]), float(fxp[1]))
	if id == ESTEIRA:
		_tocar_chegada(_fx_poeira_chegada, p, 6)
		_tocar_chegada(_fx_brilho_chegada, Vector2(p.x, 226.0), 5)
		sfx.queda()
	elif id == BONECO:
		_tocar_chegada(_fx_poeira_pequena, p, 6)
		sfx.queda()
	elif id == PERA:
		_tocar_chegada(_fx_brilho_chegada, p, 5)
		sfx.compra()
		var swing := _n("speed_bag_l%d_wall_swing" % GameState.nivel_visual(PERA))
		if not UiTema.sprite(swing).is_empty():
			_pera.definir(swing)
			_pera.tocar([0, 1, 2, 3, 4, 5], 12.0, false, func() -> void: _pera.definir(_n("speed_bag_l%d_wall" % GameState.nivel_visual(PERA))))
	else:
		_tocar_chegada(_fx_brilho_chegada, p, 5)
		sfx.compra()
	if tremida > 0:
		_tremer(tremida, 0.08)


func _tocar_chegada(a: AnimSprite, p: Vector2, quadros: int) -> void:
	a.position = p
	a.visible = true
	var seq: Array = []
	for i in quadros:
		seq.append(i)
	a.tocar(seq, 12.0, false, func() -> void: a.visible = false)


## Fim da chegada (natural ou por clique): o layout põe o aparelho novo no foco, ele brilha e o letreiro aparece.
func _terminar_chegada() -> void:
	if _chegando == "":
		return
	var id := _chegando
	if _tween_chegada != null and _tween_chegada.is_valid():
		_tween_chegada.kill()
	_chegando = ""
	_impactou = true
	_aplicar_layout()
	var alvo: Node2D = _esteira if id == ESTEIRA else (_lutador if GameState.foco == CORDA else _corda_prego)
	if id == PERA or id == BONECO:
		alvo = _anim_do(id)
	alvo.modulate = Color(2.5, 2.5, 2.5)
	alvo.create_tween().tween_property(alvo, "modulate", Color.WHITE, 0.45)
	var nome := GameState.nome_curto_aparelho(id).to_upper()
	_mostrar_texto(Vector2(336, 150), UiTema.txt("unlock_arrived", "CHEGOU: {nome}!", {"nome": nome}), UiTema.Y1)


## Novo save ou NOVA CARREIRA no meio da queda: tudo volta ao estado do GameState sem festa.
func _cancelar_chegada() -> void:
	if _tween_chegada != null and _tween_chegada.is_valid():
		_tween_chegada.kill()
	_chegando = ""
	_impactou = false


# --- Quadro a quadro ---

func _process(delta: float) -> void:
	# Tremida: pixel inteiro, decai até zero.
	if _shake_t > 0.0:
		_shake_t -= delta
		var amp := 0
		if _shake_t > 0.0:
			amp = int(ceil(float(_shake_amp) * _shake_t / _shake_dur))
		var o := Vector2.ZERO
		if amp > 0:
			o = Vector2(_rng.randi_range(-amp, amp), _rng.randi_range(-amp, amp))
		_mundo.position = -AREA.position + o
	elif _mundo.position != -AREA.position:
		_mundo.position = -AREA.position

	# Esteira: corre enquanto houver cliques recentes.
	if _corrida > 0.0:
		_corrida -= delta
		if _corrida <= 0.0 and GameState.foco == ESTEIRA:
			_pose_repouso()

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

	_seta.visible = dica_ativa
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
			dur: float, subida: float, alfa: float = 1.0) -> void:
		ativo = true
		_t = 0.0
		_dur = dur
		_subida = subida
		_alfa = alfa
		_origem = origem
		_principal.text = texto
		_principal.add_theme_color_override("font_color", cor)
		self.grande = grande
		_principal.scale = Vector2(2, 2) if grande else Vector2.ONE
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
		_raiz.modulate.a = _alfa * (1.0 if p < 0.65 else 1.0 - (p - 0.65) / 0.35)


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
