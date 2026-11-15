class_name CenaUi
extends Control
## Regente da cena de passar o posto (Fase 6b1) na tela: liga o CenaPlayer (que só avisa) à Sala (palco), às faixas pretas, ao
## botão PULAR com anel, ao balão das falas e à tela "RECEBER NOVO DISCÍPULO". A interface apaga ao começar a cena e volta no
## return_control. Não tem regra de jogo: só reage a sinais do GameState e do CenaPlayer e chama funções públicas deles.
## Abrir o jogo no meio da sucessão (save): criação = palco no estado da tela + tela de criação, sem tocar a cena;
## chegada = estado final aplicado sem tocar (design §1.4).

const TELA := Vector2(640, 360)
const JANELA := Rect2(128, 18, 384, 272)  # a janela da cena = a sala
const BOTAO := Rect2(570, 334, 62, 18)

var sala: Sala
var fluxo: Fluxo
var balao: Balao
var alvos: Array = []  # interface que apaga durante a cena (hud, painéis, barra de baixo, botão do mapa, faixas)

var player: CenaPlayer
var _barras: Control
var _botao: Button
var _anel: TextureRect
var _atlas: AtlasTexture
var _chip: Label
var _fala_resta := 0.0
var _fala_id := ""
var _ui_escondida := false
var _tween_ui: Tween
var _tween_barras: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = TELA
	z_index = 1900  # acima da sala e dos painéis, abaixo das janelas (2000), do balão (2400) e do botão PULAR (2450)
	set_meta("ui_align", "ignore")
	_montar_barras()
	_montar_pular()
	player = CenaPlayer.new(GameState)
	add_child(player)
	player.evento.connect(_ao_evento)
	player.estado_aplicado.connect(_ao_estado_aplicado)
	player.tela_pedida.connect(_ao_tela_pedida)
	player.controle_devolvido.connect(_ao_controle_devolvido)
	player.cena_iniciada.connect(_ao_cena_iniciada)
	player.cena_terminada.connect(_ao_cena_terminada)
	player.pular_progresso.connect(_ao_progresso)
	player.reacao_terminada.connect(func(_q: String) -> void: sala.cena.encerrar_reacoes())
	player.reacao_cancelada.connect(func(_q: String) -> void: sala.cena.encerrar_reacoes())
	player.reacoes_descartadas.connect(func() -> void: sala.cena.encerrar_reacoes())
	GameState.sucessao_mudou.connect(_ao_sucessao)
	call_deferred("_abrir_jogo")


# --- Faixas pretas e botão PULAR ---

func _montar_barras() -> void:
	_barras = Control.new()
	_barras.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barras.size = TELA
	_barras.modulate.a = 0.0
	_barras.visible = false
	_barras.set_meta("ui_align", "ignore")
	add_child(_barras)
	# Tudo fora da janela 384x272 da sala (prancha: a cena é uma janela no meio de uma tela preta).
	var j := JANELA
	for r in [Rect2(0, 0, TELA.x, j.position.y), Rect2(0, j.end.y, TELA.x, TELA.y - j.end.y),
			Rect2(0, j.position.y, j.position.x, j.size.y), Rect2(j.end.x, j.position.y, TELA.x - j.end.x, j.size.y)]:
		var c := ColorRect.new()
		c.mouse_filter = Control.MOUSE_FILTER_STOP  # a faixa também segura o clique (nada por baixo é clicável na cena)
		c.color = UiTema.INK
		c.position = r.position
		c.size = r.size
		_barras.add_child(c)


## Botão PULAR com anel (enche enquanto ESC/ESPAÇO é segurado) e a dica "SEGURE ESC: PULAR" ao lado.
func _montar_pular() -> void:
	_botao = UiTema.botao(self, BOTAO)
	_botao.z_index = 600  # acima das faixas (relativo a este nó)
	_botao.visible = false
	_botao.add_theme_color_override("font_color", UiTema.WHITE)
	var rotulo := UiTema.botao_conteudo(_botao, UiTema.txt("skip_button", "PULAR"), UiTema.WHITE, 1, "ui_skip_ring", 4.0)
	rotulo.name = "Texto"
	_anel = _botao.get_meta("icone") as TextureRect
	_atlas = AtlasTexture.new()
	_atlas.atlas = UiTema.textura("ui_skip_ring")
	_atlas.region = Rect2(0, 0, 11, 11)
	_anel.texture = _atlas
	_botao.pressed.connect(func() -> void: player.pular())
	var txt := UiTema.txt("skip_chip", "SEGURE ESC: PULAR")
	var lw := UiTema.largura_visivel(txt)
	_chip = UiTema.rotulo(self, txt, UiTema.G2, BOTAO.position.x - 8.0 - lw, UiTema.y_texto(BOTAO))
	_chip.visible = false
	_chip.z_index = 600


func _ao_progresso(p: float) -> void:
	_atlas.region = Rect2(11.0 * float(clampi(int(round(8.0 * p)), 0, 8)), 0, 11, 11)


# --- Abrir o jogo e começar a cena ---

func _abrir_jogo() -> void:
	match GameState.sucessao_estado():
		"creating":
			var d := player.estado_da_tela(GameState.sucessao_cena())
			if d.is_empty():
				return
			sala.cena.montar(d.palco, d.atores, player.dados.cfg.get("characters", {}), GameState.sucessao_cena())
			sala.cena.aplicar_estado(d.estado)
			_ui(false, 0.0)
			fluxo.abrir_criar_discipulo()
		"arriving":
			player.aplicar_final_sem_tocar(GameState.sucessao_cena())


func _ao_sucessao(estado: String) -> void:
	if player.ativa:
		return  # a cena já está tocando: ela mesma segue (scene_1 -> creating -> scene_2)
	if estado == "scene_1" or (estado == "creating" and not GameState.sucessao_retomada):
		player.iniciar(GameState.sucessao_cena())
	elif estado == "arriving":
		player.iniciar(GameState.sucessao_cena(), "depois_criar")  # saiu na criação: depois do CONFIRMAR toca a chegada curta


func _process(_delta: float) -> void:
	var pode := player.pode_pular()
	_botao.visible = pode
	_chip.visible = pode
	if _fala_resta > 0.0:
		_fala_resta -= _delta
		if _fala_resta <= 0.0 and balao.ativo() and balao.id == _fala_id:
			balao.fechar_agora()


func _ao_cena_iniciada(id: String) -> void:
	sala.cena.montar(player.cena.get("stage", {}), player.cena.get("actors", {}), player.dados.cfg.get("characters", {}), id)


func _ao_estado_aplicado(estado: Dictionary, origem: String) -> void:
	if origem == "inicio":
		return
	sala.cena.aplicar_estado(estado)
	if estado.has("ui"):
		_ui(str(estado.ui) == "show_all", 0.3 if origem == "final" else 0.0)


func _ao_tela_pedida(tela: String, _estado: Dictionary) -> void:
	if tela == "customize_disciple":
		fluxo.abrir_criar_discipulo()


func _ao_controle_devolvido() -> void:
	sala.cena.devolver_controle()
	_ui(true, 0.3)


func _ao_cena_terminada(_pulada: bool) -> void:
	sala.cena.terminar()
	_ui(true, 0.0)


# --- Interface apagando e voltando ---

func _ui(mostrar: bool, seg: float) -> void:
	if mostrar == not _ui_escondida and seg > 0.0:
		return
	_ui_escondida = not mostrar
	if _tween_ui != null and _tween_ui.is_valid():
		_tween_ui.kill()
	if _tween_barras != null and _tween_barras.is_valid():
		_tween_barras.kill()
	_barras.visible = true
	_tween_ui = create_tween().set_parallel(true) if seg > 0.0 else null
	_tween_barras = _tween_ui
	var alvo_a := 1.0 if mostrar else 0.0
	for n in alvos:
		var c := n as CanvasItem
		if c == null or not is_instance_valid(c):
			continue
		if mostrar and not (c is FaixaAviso):
			c.visible = true
		if seg > 0.0:
			_tween_ui.tween_property(c, "modulate:a", alvo_a, seg)
		else:
			c.modulate.a = alvo_a
	if seg > 0.0:
		_tween_ui.tween_property(_barras, "modulate:a", 1.0 - alvo_a, seg)
	else:
		_barras.modulate.a = 1.0 - alvo_a
	var terminar := func() -> void:
		if not mostrar:
			for n in alvos:
				if is_instance_valid(n) and not (n is FaixaAviso):
					(n as CanvasItem).visible = false
		else:
			_barras.visible = false
	if seg > 0.0:
		_tween_ui.chain().tween_callback(terminar)
	else:
		terminar.call()


# --- Falas ---

func _ao_evento(ev: Dictionary) -> void:
	sala.cena.evento(ev)  # palco: poses, passos, adereços, sons, câmera e tremida
	match str(ev.get("tipo", "")):
		"ui":
			_ui(ev.get("hide", null) == null, float(ev.get("seconds", 0.0)))
		"say":
			_falar(ev)


## Balão da cena preso à cabeça de quem fala. Nunca cobre a cabeça de outro personagem (Osmar, discípulo, o próprio John
## sentado): se a linha larga não cabe, o balão quebra em duas linhas (Balao.mostrar).
func _falar(ev: Dictionary) -> void:
	var ator := str(ev.get("ator", ""))
	var evitar: Array = []
	var cabeca: Vector2
	if sala.cena.ator_visivel(ator):
		cabeca = sala.cena.cabeca_do_ator(ator)
		evitar = sala.cena.cabecas_a_evitar(ator)
		if not ("coach" in sala._cena_oculta) and GameState.local_id == "garage" and ator != "coach":
			var o := sala.ponto_cabeca("coach")
			evitar.append(Rect2(o.x - 9.0, o.y, 18.0, 18.0))
		if sala.mentor_visivel():
			var m := sala.cabeca_mentor()
			evitar.append(Rect2(m.x - 9.0, m.y, 18.0, 18.0))
	else:
		# O John já é o mentor da sala (depois do return_control): cabeça dele sentado.
		cabeca = sala.cabeca_mentor() if ator == "first" else sala.ponto_cabeca(ator)
		var o2 := sala.ponto_cabeca("coach")
		evitar.append(Rect2(o2.x - 9.0, o2.y, 18.0, 18.0))
		var l := sala.ponto_cabeca("first")
		evitar.append(Rect2(l.x - 9.0, l.y, 18.0, 18.0))
	_fala_id = "cena_" + str(ev.get("line", ""))
	if balao.mostrar(_fala_id, ator, str(ev.get("text", "")), cabeca, -1.0, evitar):
		_fala_resta = maxf(float(ev.get("seconds", 0.0)), 0.5)
	else:
		_fala_resta = 0.0
