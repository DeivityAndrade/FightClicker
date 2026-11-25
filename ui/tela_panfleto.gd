class_name TelaPanfleto
extends TelaTreino
## Fase 7a2: tela da Panfletagem. Rua do bairro de noite, o lutador parado na calçada com o maço de panfletos da Raízes e as
## pessoas atravessando a tela. Quem quer o panfleto dá um sinal ("?") no meio da travessia; quem não quer passa de fone, celular
## ou braço cruzado; o sinal falso some na metade. Clicar em quem dá o sinal = ACEITOU!; errar = NÃO, VALEU (custa meio panfleto e a
## mão ocupada). Só lê `PanfletoLogica.pessoas()` / `estado()` e manda `clicar(id)`.
## Poses do Artista de Personagens (manifest: minigame_layout.flyers): discípulo `fighter_flyer_idle/give/miss` e 4 passantes
## (`pedestrian_actions`: anda, sem interesse, sinal, sinal falso, "não, valeu" e andando com o panfleto), quadro 48x76, pivô (24,71).

const FAIXA_Y := Vector2(292.0, 308.0)  # pés: y 300 no centro da calçada, com uma pequena variação de altura por pessoa
const ACERTO := Vector2(30.0, 44.0)  # meia largura e meia altura da área de clique (o quadro 48x76 + 6 px de folga)
const TEMPO_BOATO := 4.5

var _jog: AnimSprite
var _osmar: AnimSprite
var _vivos: Dictionary = {}  # id -> {no, sombra, marca, estado_marca, t_marca}
var _contador: Control
var _cont_caixa := Rect2()
var _cont_icone: TextureRect
var _cont_rotulo: Label
var _cont_texto := ""
var _boato: BalaoConvite
var _boato_t := 0.0
var _acao_t := 0.0  # tempo da pose passageira do discípulo (entregar / errar)
var _acao := ""
var _ultimo_aceitos := -1


func _chave_layout() -> String:
	return "flyers"


func _nome_fundo() -> String:
	return "flyers_bg"


func _titulo() -> String:
	return UiTema.txt("flyers_name", "PANFLETAGEM")


func _dica_texto() -> String:
	return UiTema.txt("flyers_tip", "")


func _caixa_do_tempo() -> Array:
	return [584, 4, 48, 18]


# ---------------------------------------------------------------- mundo
func _montar_mundo() -> void:
	var L := layout()
	var fs: Array = L.get("fighter_spot", [70, 324])
	var cs: Array = L.get("coach_spot", [604, 326])
	var pj := Vector2(float(fs[0]), float(fs[1]))
	var po := Vector2(float(cs[0]), float(cs[1]))
	_sombra("floor_shadow", po, int(po.y) - 1)
	_osmar = AnimSprite.new()
	_osmar.position = po
	_osmar.z_index = int(po.y)
	_mundo.add_child(_osmar)
	_tocar_loop(_osmar, "coach_idle", 3.0)
	_sombra("fight_shadow", pj, 5)
	_jog = AnimSprite.new()
	_jog.position = pj
	_jog.z_index = int(pj.y)
	_mundo.add_child(_jog)
	_pose_jogador("idle")


## Folha do discípulo (idle, give, miss) com a luva e o visual dele; sem a folha "_disc" (John), a mesma sem o visual.
func _folha_jogador(acao: String) -> String:
	var mapa: Dictionary = layout().get("fighter_actions", {})
	var base := str(mapa.get(acao, "fighter_flyer_" + acao))
	for nome in [UiTema.com_luva(base), base + GameState.sufixo_luva() + "_disc", base + "_disc"]:
		if _existe(nome):
			return nome
	return ""


var _chave_jog := ""


func _pose_jogador(acao: String) -> void:
	if acao == _chave_jog:
		UiTema.aplicar_visual_disc(_jog)
		return
	_chave_jog = acao
	var nome := _folha_jogador(acao)
	if nome == "":
		return
	_jog.definir(nome)
	var n := int(UiTema.sprite(nome).get("frames", 1))
	var seq: Array = []
	for i in n:
		seq.append(i)
	_jog.tocar(seq, float(UiTema.sprite(nome).get("fps", 8.0)), acao == "idle")
	UiTema.aplicar_visual_disc(_jog)


## Pose passageira do discípulo: entregar (give) ou errar (miss); volta ao idle sozinho.
func _fazer(acao: String, dur: float) -> void:
	_acao = acao
	_acao_t = dur
	_chave_jog = ""


# ---------------------------------------------------------------- HUD
func _montar_hud() -> void:
	var L := layout()
	# Contador "N DE 10": o cartão do manifest, com o maço (ícone) e o texto num grupo só, no meio dele.
	_cont_caixa = retangulo(L.get("counter_box", [264, 4, 112, 20]))
	UiTema.painel(_hud, "c_cartao", Rect2(_cont_caixa.position, _cont_caixa.size + Vector2(0, 2)))  # +2: a sombra do cartão
	_contador = Control.new()
	_contador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTema.alinhar(_contador, "center_h")
	_hud.add_child(_contador)
	_cont_icone = UiTema.textura_rect(_contador, "icon_flyer", 0, 0)
	_cont_rotulo = UiTema.rotulo(_contador, "", UiTema.INK, 12, 0)
	_reposicionar_contador("0")


## O grupo (maço + texto) cresce com o número: largura par e centro igual ao do cartão (x 320), recalculado a cada texto novo.
func _reposicionar_contador(texto: String) -> void:
	var gw := 12.0 + UiTema.largura_visivel(texto)
	if int(gw) % 2 != 0:
		gw += 1.0
	var area := UiTema.area_nove("c_cartao", _cont_caixa.size + Vector2(0, 2))
	_contador.size = Vector2(gw, 9)
	_contador.position = Vector2(_cont_caixa.position.x + roundf(_cont_caixa.size.x / 2.0 - gw / 2.0),
		_cont_caixa.position.y + area.position.y + roundf((area.size.y - 9.0) / 2.0))
	_cont_icone.position = Vector2.ZERO
	_cont_rotulo.position = Vector2(12, 0)


# ---------------------------------------------------------------- boato do Osmar (uma vez na vida do save)
func _ao_info() -> void:
	var texto := str(info.get("rumor_text", ""))
	if texto == "" or _boato != null:
		return
	_boato = BalaoConvite.new()
	add_child(_boato)
	var cs: Array = layout().get("coach_spot", [604, 326])
	var cabeca := Vector2(float(cs[0]) + 1.0, float(cs[1]) - 63.0)
	if not _boato.mostrar("rumor", texto, cabeca, [], false):
		_boato.queue_free()
		_boato = null
		return
	_boato_t = TEMPO_BOATO
	_boato.z_index = 600


# ---------------------------------------------------------------- quadro a quadro
func _atualizar(e: Dictionary, delta: float) -> void:
	if e.is_empty():
		return
	_acao_t = maxf(_acao_t - delta, 0.0)
	_pose_jogador(_acao if _acao_t > 0.0 else "idle")
	if _boato != null:
		_boato_t -= delta
		if _boato_t <= 0.0:
			_boato.queue_free()
			_boato = null
	var aceitos := int(e.aceitos)
	var texto := UiTema.txt("flyers_count", "{n} DE {goal}", {"n": aceitos, "goal": int(e.meta)})
	if texto != _cont_texto:
		_cont_texto = texto
		_cont_rotulo.text = texto
		_reposicionar_contador(texto)
		if _ultimo_aceitos >= 0 and aceitos > _ultimo_aceitos:
			_cont_rotulo.modulate = Color(1.8, 1.8, 1.8)
			_cont_rotulo.create_tween().tween_property(_cont_rotulo, "modulate", Color.WHITE, 0.3)
		_ultimo_aceitos = aceitos
	_atualizar_pessoas(delta)


func _atualizar_pessoas(delta: float) -> void:
	var lista: Array = jogo.pessoas()
	var ids := {}
	var w: Array = layout().get("walk_x", [-30, 670])
	for p in lista:
		var id := int(p.id)
		ids[id] = true
		if not _vivos.has(id):
			_vivos[id] = _nova_pessoa(int(p.tipo), id)
		var v: Dictionary = _vivos[id]
		var x := roundf(lerpf(float(w[0]), float(w[1]), float(p.x)))
		var y := roundf(lerpf(FAIXA_Y.x, FAIXA_Y.y, float(p.faixa)))
		var no: AnimSprite = v.no
		no.position = Vector2(x, y)
		no.z_index = int(y)
		var sombra: Sprite2D = v.sombra
		sombra.position = Vector2(x, y - 1.0)
		sombra.z_index = int(y) - 1
		_tocar_pessoa(v, _estado_pessoa(v, p))
		_atualizar_sinal(v, p, x, y, delta)
	for id in _vivos.keys():
		if not ids.has(id):
			_apagar_pessoa(int(id))


func _nova_pessoa(tipo: int, id: int) -> Dictionary:
	var tipos: Array = layout().get("pedestrian_types", ["estudante", "senhora", "trabalhador", "moca"])
	var nome_tipo := str(tipos[tipo % tipos.size()])
	var no := AnimSprite.new()
	_mundo.add_child(no)
	var sombra := Sprite2D.new()
	sombra.texture = UiTema.textura("floor_shadow")
	_mundo.add_child(sombra)
	var marca := AnimSprite.new()
	marca.definir("ui_tell_mark")
	marca.visible = false
	marca.z_index = 700
	_mundo.add_child(marca)
	# A lógica só mostra quem quer depois do sinal: antes dele, a maioria passa de fone, celular ou braço cruzado (a folha "sem interesse",
	# só enfeite fixo por pessoa) e o resto anda normal. Quem dá o sinal troca para o "?" de qualquer jeito.
	var sem_interesse := (id * 7 + tipo) % 3 != 0
	return {"no": no, "sombra": sombra, "marca": marca, "estado": "", "t": 0.0, "chave": "", "tipo": nome_tipo, "sem": sem_interesse}


func _folha_pessoa(v: Dictionary, acao: String) -> String:
	var mapa: Dictionary = layout().get("pedestrian_actions", {}).get(str(v.tipo), {})
	return str(mapa.get(acao, ""))


## Folha da pessoa por estado: walk / no (sem interesse) / tell (quadros 0-2 uma vez, 3-5 em loop) / false / refuse / accepted.
func _estado_pessoa(v: Dictionary, p: Dictionary) -> String:
	if bool(p.aceitou):
		return "accepted"
	if bool(p.resolvida):
		return "refuse"
	var sinal := str(p.sinal)
	if sinal == "interesse":
		return "tell"
	if sinal == "falso":
		return "false"
	return "no" if bool(v.sem) else "walk"


func _tocar_pessoa(v: Dictionary, chave: String) -> void:
	if chave == str(v.chave):
		return
	v.chave = chave
	var nome := _folha_pessoa(v, chave)
	if nome == "" or not _existe(nome):
		return
	var no: AnimSprite = v.no
	no.definir(nome)
	var n := int(UiTema.sprite(nome).get("frames", 1))
	var fps := float(UiTema.sprite(nome).get("fps", 10.0))
	var seq: Array = []
	if chave == "tell" and n >= 6:
		seq = [0, 1, 2]
		for i in 8:
			seq.append_array([3, 4, 5])
		no.tocar(seq, fps, false)
		return
	for i in n:
		seq.append(i)
	no.tocar(seq, fps, chave in ["walk", "no", "accepted"])


func _apagar_pessoa(id: int) -> void:
	var v: Dictionary = _vivos[id]
	for k in ["no", "sombra", "marca"]:
		(v[k] as Node).queue_free()
	_vivos.erase(id)


## O "?": quadro 0 ao nascer, 1 enquanto dura o sinal, 2 (dither) ao sumir. O sinal falso termina no quadro 2 e vira cara fechada.
func _atualizar_sinal(v: Dictionary, p: Dictionary, x: float, y: float, delta: float) -> void:
	var marca: AnimSprite = v.marca
	var sinal := str(p.sinal)
	var estado := str(v.estado)
	v.t = float(v.t) + delta
	if (sinal == "interesse" or sinal == "falso") and not bool(p.resolvida):
		if estado != "cheio":
			v.estado = "cheio"
			v.t = 0.0
		marca.visible = true
		marca.parar(0 if float(v.t) < 0.07 else 1)
	else:
		if estado == "cheio":
			v.estado = "fim" if bool(p.resolvida) else "some"
			v.t = 0.0
			estado = str(v.estado)
		if estado == "some" and float(v.t) < 0.25:
			marca.visible = true
			marca.parar(2)
		else:
			marca.visible = false
	marca.position = Vector2(x, y - 71.0)


# ---------------------------------------------------------------- entradas
func _ao_clique_mundo(p: Vector2) -> void:
	if jogo == null or janela != null or str(jogo.estado().fase) != "jogando":
		return
	# Quem está na frente (mais perto da tela) leva o clique; a área é o quadro da folha + 6 px.
	var alvo := -1
	var melhor := -INF
	var w: Array = layout().get("walk_x", [-30, 670])
	for q in jogo.pessoas():
		var x := lerpf(float(w[0]), float(w[1]), float(q.x))
		var y := lerpf(FAIXA_Y.x, FAIXA_Y.y, float(q.faixa))
		var r := Rect2(x - ACERTO.x, y - 71.0 - 6.0, ACERTO.x * 2.0, ACERTO.y * 2.0)
		if r.has_point(p) and y > melhor:
			melhor = y
			alvo = int(q.id)
	if alvo < 0 and (p.y < 40.0 or p.y > 334.0):
		return  # clique no HUD ou na faixa de baixo não conta como errar a rua
	var res: String = jogo.clicar(alvo)
	var onde := p
	var v = _vivos.get(alvo)
	if v != null:
		onde = (v.no as AnimSprite).position
	match res:
		"aceitou":
			_fazer("give", 0.5)
			_entregar(onde)
			_flutuar(UiTema.txt("flyers_accepted", "ACEITOU!"), UiTema.GR3, onde + Vector2(0, -92), 1, 14.0, 0.9)
			_fala("flyers_took", UiTema.CREAM, onde + Vector2(0, -80))
			_tremer(1, 0.06)
			sfx.moeda()
		"erro":
			_fazer("miss", 0.6)
			_flutuar(UiTema.txt("flyers_refused", "NÃO, VALEU"), UiTema.G3, onde + (Vector2(0, -92) if v != null else Vector2(0, -14)), 1, 12.0, 0.9)
			if v != null:
				_fala("flyers_ignored", UiTema.G2, onde + Vector2(0, -80))
			sfx.bloqueio()


## Fala curta de quem aceitou ou recusou (a lista do Roteirista; sorteio só enfeite, nunca o do jogo).
func _fala(chave: String, cor: Color, p: Vector2) -> void:
	var lista: Array = GameState.lista_ui(chave)
	if lista.is_empty():
		return
	_flutuar(str(lista[_rng.randi() % lista.size()]).to_upper(), cor, p, 1, 10.0, 0.9)


## O panfleto sai da mão do lutador e voa até a pessoa.
func _entregar(destino: Vector2) -> void:
	var mao: Array = UiTema.sprite(_jog.nome_sprite).get("hand_flyer", [15, -41])  # relativo ao pivô, do `give`
	var ini := _jog.position + Vector2(float(mao[0]), float(mao[1]))
	var fim := destino + Vector2(0, -42.0)
	var f := AnimSprite.new()
	f.definir("ui_flyer_fly")
	f.position = ini
	f.z_index = 800
	_mundo.add_child(f)
	f.tocar([0, 1, 2], 12.0, true)
	var tw := f.create_tween()
	tw.tween_method(func(t: float) -> void:
		var q := ini.lerp(fim, t)
		f.position = Vector2(roundf(q.x), roundf(q.y - 14.0 * sin(t * PI))), 0.0, 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(f.queue_free)


func _evento(ev: String, _e: Dictionary) -> void:
	if ev == "fim" and not bool(jogo.saiu):
		sfx.sino_fim()
