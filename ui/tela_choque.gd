class_name TelaChoque
extends TelaTreino
## Fase 7a2: tela do Choque (sparring em cabo de guerra), variantes Boxe (cliques) e Jiu-jitsu (segurar e soltar).
## Barra do cabo de guerra com a agulha, avisos de RAJADA/PUXADA, pausa (ELE ABRIU!) e finta no corpo do parceiro, fôlego, X2,
## pontos dos dois, tempo, SAIR e a dica de controle. Só lê `ChoqueLogica.estado()`; manda `apertar()` / `soltar()`.
## Boxe: clique (ou Espaço) empurra, segurar vira guarda. Jiu-jitsu: segurar puxa, soltar na puxada forte dele.
## Poses do Artista de Personagens (manifest: minigame_layout.spar.player_actions / partner_actions): discípulo com camadas e luvas,
## parceiro já virado para a esquerda. Boxe: quem bate fica por cima; Jiu-jitsu: o discípulo por cima.

const PIP_X := 9.0

var _arte := "boxing"  # "boxing" | "bjj" | "muay_thai" (7b1: no Muay Thai a tela reusa o parceiro e os efeitos do Boxe)
var _jog: AnimSprite
var _par: AnimSprite
var _osmar: AnimSprite
var _pos_j := Vector2(296, 318)
var _pos_p := Vector2(346, 318)
var _barra_no: Node2D  # trilho, agulha e X2: treme com o clique (a tremida curta da barra)
var _trilho_pos := Vector2(190, 28)
var _agulha: AnimSprite
var _x2: AnimSprite
var _x2_som := false
var _agulha_pulso := 0.0
var _aviso_ico: AnimSprite
var _aviso_txt: Label
var _pip_v: Array[TextureRect] = []
var _pip_e: Array[TextureRect] = []
var _num_v: Label
var _num_e: Label
var _pontos_v := -1
var _pontos_e := -1
var _folego_grupo: Control
var _folego_fill: TextureRect
var _folego_rot: Label
var _folego_frame := -1
var _folego_larg := -1
var _toque_dir: AnimSprite
var _toque_esq: AnimSprite
var _chave_j := ""  # estado atual de cada lutador (a folha só reinicia quando o estado muda)
var _chave_p := ""
var _trans_j := ""  # pose passageira do discípulo (soco, contragolpe, tombo...) e quanto falta para ela acabar
var _trans_j_t := 0.0
var _trans_p := ""
var _trans_p_t := 0.0
var _segurava := false
var _fase_ant := ""
# 7b1 (Muay Thai): faixa da batida (a esquerda da barra) e os 3 degraus do combo (a direita)
var _faixa: FaixaBatida
var _degraus: Array[ColorRect] = []
var _combo_ant := -1


func _chave_layout() -> String:
	return "spar"


func _nome_fundo() -> String:
	return "spar_bg"


func _titulo() -> String:
	return UiTema.txt("spar_name_" + _arte if _arte in ["bjj", "muay_thai"] else "spar_name_boxing", "CHOQUE")


func _dica_texto() -> String:
	return UiTema.txt("spar_tip_" + _arte if _arte in ["bjj", "muay_thai"] else "spar_tip_boxing", "")


func abrir(info_: Dictionary) -> void:
	var arte_do_jogo := str(info_.get("art", GameState.arte_id))
	_arte = arte_do_jogo if arte_do_jogo in ["bjj", "muay_thai"] else "boxing"
	super.abrir(info_)


# ---------------------------------------------------------------- mundo
func _montar_mundo() -> void:
	var L := layout()
	_pos_j = Vector2(float(L.get("player_x", 296)), float(L.get("feet_y", 318)))
	_pos_p = Vector2(float(L.get("partner_x", 346)), float(L.get("feet_y", 318)))
	# O Osmar fica lá atrás, na porta dos fundos (escala da sala, bem menor que a dupla: é a perspectiva).
	var cs: Array = L.get("coach_spot", [150, 262])
	var po := Vector2(float(cs[0]), float(cs[1]))
	_sombra("floor_shadow", po, int(po.y) - 1)
	_osmar = AnimSprite.new()
	_osmar.position = po
	_osmar.z_index = int(po.y)
	_mundo.add_child(_osmar)
	_tocar_loop(_osmar, "coach_idle", 3.0)
	# A dupla: pés em y 318, jogador em x 296 e parceiro em x 346 (iguais à luta).
	_sombra("fight_shadow", _pos_j, 5)
	_sombra("fight_shadow", _pos_p, 5)
	_jog = AnimSprite.new()
	_jog.position = _pos_j
	_jog.z_index = 318
	_mundo.add_child(_jog)
	_par = AnimSprite.new()
	_par.position = _pos_p
	_par.z_index = 318
	_mundo.add_child(_par)
	_atualizar_poses(jogo.estado() if jogo != null else {})
	# Aviso no corpo do parceiro: o jogador aprende a olhar o ombro dele, não a barra.
	_aviso_ico = AnimSprite.new()
	_aviso_ico.position = Vector2(_pos_p.x, 212)
	_aviso_ico.z_index = 600
	_aviso_ico.visible = false
	_mundo.add_child(_aviso_ico)
	_aviso_txt = UiTema.rotulo(_mundo, "", UiTema.R3, _pos_p.x - 60.0, 212.0 - 26.0, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	_aviso_txt.size = Vector2(120, 12)
	_aviso_txt.z_index = 600
	_aviso_txt.visible = false


## Folha do discípulo para uma ação do manifest (`player_actions`), com a luva equipada e as camadas do visual dele.
## As folhas do Choque só existem em "_disc": sem discípulo (a 1ª carreira, John) usa a mesma folha sem o visual dele.
func _folha_jogador(acao: String) -> String:
	var mapa: Dictionary = layout().get("player_actions", {}).get({"bjj": "jj", "muay_thai": "mt"}.get(_arte, "box"), {})
	var base := str(mapa.get(acao, mapa.get("kick", "") if acao == "counter" else "")).split(" ")[0]
	var por_luva := base + GameState.sufixo_luva() + "_disc"
	for nome in [UiTema.com_luva(base), por_luva, base + "_disc"]:
		if _existe(nome):
			return nome
	return ""


func _folha_parceiro(acao: String) -> String:
	var mapa: Dictionary = layout().get("partner_actions", {}).get("jj" if _arte == "bjj" else "box", {})
	var nome := str(mapa.get(acao, "")).split(" ")[0]
	return nome if _existe(nome) else ""


## Toca a folha (uma vez e segura o último quadro, ou em loop). Sem a folha, não faz nada.
func _tocar_folha(spr: AnimSprite, nome: String, em_loop: bool) -> void:
	if nome == "" or not _existe(nome):
		return
	spr.definir(nome)
	var n := int(UiTema.sprite(nome).get("frames", 1))
	var seq: Array = []
	for i in n:
		seq.append(i)
	spr.tocar(seq, float(UiTema.sprite(nome).get("fps", 8.0)), em_loop)
	UiTema.aplicar_visual_disc(spr)


# ---------------------------------------------------------------- HUD
func _montar_hud() -> void:
	var L := layout()
	# Barra do cabo de guerra: esquerda = você (azul), direita = ele (vermelho). Fica num Node2D (a barra treme sozinha).
	var tt: Rect2 = retangulo(L.get("tug_track", [190, 28, 260, 16]))
	_trilho_pos = tt.position
	_barra_no = Node2D.new()
	UiTema.alinhar(_barra_no, "ignore")
	_hud.add_child(_barra_no)
	var trilho := Sprite2D.new()
	trilho.centered = false
	trilho.texture = UiTema.textura("ui_tug_track")
	trilho.position = tt.position
	_barra_no.add_child(trilho)
	_agulha = AnimSprite.new()
	_agulha.definir("ui_tug_marker")
	_agulha.z_index = 2
	_barra_no.add_child(_agulha)
	_x2 = AnimSprite.new()
	_x2.definir("ui_counter_x2")
	_x2.tocar([0, 1], 8.0, true)
	_x2.z_index = 3
	_x2.visible = false
	_barra_no.add_child(_x2)
	_toque_dir = _novo_toque()
	_toque_esq = _novo_toque()
	_toque_esq.scale = Vector2(-1, 1)
	# Pontos: VOCÊ n ●○○ ........ ○○○ n ELE
	var P: Dictionary = L.get("points", {})
	var yl := float(P.get("you_label", [190, 8])[1]) - 2.0  # o glifo (2 px abaixo do topo do rótulo) fica na altura das bolinhas
	var xl := float(P.get("you_label", [190, 8])[0])
	UiTema.rotulo(_hud, UiTema.txt("preview_you", "VOCÊ"), UiTema.B3, xl, yl)
	_num_v = UiTema.rotulo(_hud, "0", UiTema.WHITE, xl + UiTema.largura(UiTema.txt("preview_you", "VOCÊ")) + 4.0, yl)
	var py := float(P.get("you_pips", [228, 8])[1])
	for i in 3:
		_pip_v.append(imagem_quadro(_hud, "ui_point_pip", 0, float(P.get("you_pips", [228, 8])[0]) + PIP_X * float(i), py))
	var xr := float(P.get("him_label_right", [450, 8])[0])
	var ele := UiTema.txt("preview_him", "ELE")
	var lw := UiTema.largura(ele)
	UiTema.rotulo(_hud, ele, UiTema.R3, roundf(xr - lw), yl)
	_num_e = UiTema.rotulo(_hud, "0", UiTema.WHITE, 0, yl, 12.0, HORIZONTAL_ALIGNMENT_RIGHT)
	_num_e.position.x = roundf(xr - lw - 4.0 - 12.0)
	for i in 3:
		_pip_e.append(imagem_quadro(_hud, "ui_point_pip", 0, float(P.get("him_pips", [392, 8])[0]) + PIP_X * float(i), py))
	# Fôlego (só o seu): ícone, moldura com enchimento e o rótulo.
	var B: Dictionary = L.get("breath", {})
	var bi: Array = B.get("icon", [190, 49])
	var bb: Rect2 = retangulo(B.get("bar", [202, 50, 96, 6]))
	var bl: Array = B.get("label", [302, 49])
	UiTema.textura_rect(_hud, "icon_breath", float(bi[0]), float(bi[1]))
	_folego_grupo = Control.new()
	_folego_grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_folego_grupo.position = bb.position
	_folego_grupo.size = bb.size
	UiTema.alinhar(_folego_grupo, "ignore")  # moldura + enchimento por dentro dela: o verificador não cobra o encaixe
	_hud.add_child(_folego_grupo)
	UiTema.nine_patch(_folego_grupo, "ui_breath_bar", Rect2(Vector2.ZERO, bb.size))
	_folego_fill = imagem_quadro(_folego_grupo, "ui_breath_fill", 0, 1, 1)
	_folego_fill.stretch_mode = TextureRect.STRETCH_TILE
	_folego_fill.size = Vector2(bb.size.x - 2.0, 4.0)
	_folego_rot = UiTema.rotulo(_hud, UiTema.txt("spar_breath", "FÔLEGO"), UiTema.G3, float(bl[0]), float(bl[1]) - 1.0)
	if _arte == "muay_thai":
		_montar_hud_muay_thai(tt)


## 7b1: faixa da batida na esquerda (as batidas chegam da direita e a zona do "no tempo" fica a 30 px do começo) e os 3 degraus
## do combo na direita (1, 2 e CHUTE), na altura da barra. O jogador clica olhando a faixa; o resto da tela é igual ao Boxe.
func _montar_hud_muay_thai(trilho: Rect2) -> void:
	var v: Dictionary = GameState.minigames.spar.get("variants", {}).get("muay_thai", {})
	var y := trilho.position.y + 1.0  # 14 px de altura, no meio da barra (28..44)
	var alt := trilho.size.y - 2.0
	UiTema.rotulo(_hud, UiTema.txt("spar_beat_label", "BATIDA"), UiTema.G3, FaixaBatida.X, y - 10.0)
	_faixa = FaixaBatida.new()
	_faixa.position = Vector2(FaixaBatida.X, y)
	_faixa.size = Vector2(FaixaBatida.LARG, alt)
	_faixa.beat_s = float(v.get("beat_s", 0.5))
	_faixa.janela_s = float(v.get("window_s", 0.12))
	UiTema.alinhar(_faixa, "ignore")  # desenho livre dentro da faixa
	_hud.add_child(_faixa)
	var larg := 36.0
	var passo := larg + 4.0
	var x0 := 630.0 - (passo * 3.0 - 4.0)
	UiTema.rotulo(_hud, UiTema.txt("spar_combo_label", "COMBO"), UiTema.G3, x0, y - 10.0)
	var kick_txt := UiTema.txt("spar_beat_kick", "CHUTE!").replace("!", "")
	for i in 3:
		var q := ColorRect.new()
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		q.position = Vector2(x0 + passo * float(i), y)
		q.size = Vector2(larg, alt)
		q.color = UiTema.D1
		q.set_meta("ui_align", "ignore")
		_hud.add_child(q)
		UiTema.rotulo_centrado(q, Rect2(0, 0, larg, alt), kick_txt if i == 2 else str(i + 1), UiTema.G2, 1, false, "center")
		_degraus.append(q)


func _novo_toque() -> AnimSprite:
	var t := AnimSprite.new()
	t.definir("ui_tug_touch")
	t.z_index = 4
	t.visible = false
	_barra_no.add_child(t)
	return t


# ---------------------------------------------------------------- quadro a quadro
func _atualizar(e: Dictionary, delta: float) -> void:
	if e.is_empty():
		return
	_agulha_pulso = maxf(_agulha_pulso - delta, 0.0)
	# Agulha: de x 8 (ele te encostou) a x 251 (você encostou ele), em pixel inteiro.
	var range_x: Array = layout().get("tug_marker_x", [8, 251])
	var b := clampf(float(e.barra), -1.0, 1.0)
	var mx := roundf(_trilho_pos.x + float(range_x[0]) + (b + 1.0) * 0.5 * (float(range_x[1]) - float(range_x[0])))
	var my := float(layout().get("tug_marker_pivot_y", 36))
	_agulha.position = Vector2(mx, my)
	var contra := bool(e.x2)
	var quadro_agulha := 2 if contra else (1 if _agulha_pulso > 0.0 or (_arte == "bjj" and bool(e.segurando) and str(e.fase) == "jogando") else 0)
	_agulha.parar(quadro_agulha)
	# X2: enquanto a pausa vale, ao lado da agulha dentro da barra (acima dela bateria no cartão do tempo).
	_x2.visible = contra
	if contra:
		_x2.position = Vector2(mx + (17.0 if b < 0.45 else -17.0), my + 5.0)
		if not _x2_som:
			_x2_som = true
			sfx.foco()
	else:
		_x2_som = false
	_atualizar_pontos(e)
	_atualizar_folego(e)
	_atualizar_aviso(e)
	_atualizar_poses(e)
	if _faixa != null:
		_atualizar_muay_thai(e, delta)


func _atualizar_pontos(e: Dictionary) -> void:
	var pv := int(e.pontos)
	var pe := int(e.pontos_dele)
	if pv == _pontos_v and pe == _pontos_e:
		return
	_pontos_v = pv
	_pontos_e = pe
	for i in 3:
		_pip_v[i].texture = quadro("ui_point_pip", 1 if i < pv else 0)
		_pip_e[i].texture = quadro("ui_point_pip", 2 if i < pe else 0)
	_num_v.text = str(pv)
	_num_e.text = str(pe)


func _atualizar_folego(e: Dictionary) -> void:
	var f := clampf(float(e.folego), 0.0, 1.0)
	var inner := _folego_grupo.size.x - 2.0
	var larg := int(roundf(inner * f))
	var fr := 0 if f > 0.5 else (1 if f > 0.25 else 2)
	if fr != _folego_frame:
		_folego_frame = fr
		_folego_fill.texture = quadro("ui_breath_fill", fr)
		_folego_rot.add_theme_color_override("font_color", UiTema.R3 if fr == 2 else UiTema.G3)
	if larg != _folego_larg:
		_folego_larg = larg
		_folego_fill.size.x = float(larg)
		_folego_fill.visible = larg > 0


## 7b1: faixa da batida (ritmo) e degraus do combo.
func _atualizar_muay_thai(e: Dictionary, delta: float) -> void:
	_faixa.estado = e
	_faixa.passo(delta)
	var combo := int(e.get("combo", 0))
	if combo != _combo_ant:
		_combo_ant = combo
		for i in _degraus.size():
			var aceso := i < combo
			var q := _degraus[i]
			q.color = UiTema.BR2 if aceso else (UiTema.D2 if i == 2 and combo == 2 else UiTema.D1)  # 2 degraus acesos: o CHUTE fica "armado"
			for l in q.get_children():
				if l is Label:
					(l as Label).add_theme_color_override("font_color", UiTema.WHITE if aceso or (i == 2 and combo == 2) else UiTema.G2)


## Aviso acima do parceiro: rajada (estrela vermelha), pausa (balão branco) e finta (começa vermelho e vira branco na metade).
func _atualizar_aviso(e: Dictionary) -> void:
	var aviso := str(e.momento) == "aviso" and str(e.fase) == "jogando"
	_aviso_ico.visible = aviso
	_aviso_txt.visible = aviso
	if not aviso:
		return
	var padrao := str(e.padrao)
	var frac := float(e.aviso_frac)
	if padrao == "burst":
		_tocar_loop(_aviso_ico, "ui_warn_burst", 6.0)
		_aviso_txt.text = UiTema.txt("spar_warn_pull" if _arte == "bjj" else "spar_warn_burst", "RAJADA!")
		_aviso_txt.add_theme_color_override("font_color", UiTema.R3)
	elif padrao == "pause":
		_tocar_loop(_aviso_ico, "ui_warn_pause", 6.0)
		_aviso_txt.text = UiTema.txt("spar_warn_pause", "ELE ABRIU!")
		_aviso_txt.add_theme_color_override("font_color", UiTema.WHITE)
	else:
		# Finta: 0 = rajada, 1 = o meio da troca (1 quadro curto), 2 = pausa. O texto continua o da rajada: é a mentira dela.
		if _aviso_ico.nome_sprite != "ui_warn_feint":
			_aviso_ico.definir("ui_warn_feint")
		var q := 0 if frac < 0.5 else (1 if frac < 0.58 else 2)
		_aviso_ico.parar(q)
		_aviso_txt.text = UiTema.txt("spar_warn_pull" if _arte == "bjj" else "spar_warn_burst", "RAJADA!")
		_aviso_txt.add_theme_color_override("font_color", UiTema.R3 if q == 0 else UiTema.WHITE)


## Estados dos dois lutadores (mapa `partner_states` do manifest). Poses passageiras (soco, contragolpe, tombo) vencem o estado base.
func _atualizar_poses(e: Dictionary) -> void:
	var delta := get_process_delta_time()
	_trans_j_t = maxf(_trans_j_t - delta, 0.0)
	_trans_p_t = maxf(_trans_p_t - delta, 0.0)
	var fase := str(e.get("fase", "contagem"))
	var jogando := fase == "jogando"
	var padrao := str(e.get("padrao", ""))
	var momento := str(e.get("momento", ""))
	var seg := bool(e.get("segurando", false))
	var chave_j := ""
	var chave_p := ""
	var loop_j := true
	var loop_p := true
	if _arte == "bjj":
		if not jogando:
			chave_j = "take"
			chave_p = "take"
			loop_j = false
			loop_p = false
		else:
			chave_j = "hold" if seg else "grip"
			chave_p = "pull" if seg else "grip"
			if _segurava and not seg:
				_trans_j = "free"
				_trans_j_t = 0.3
			if momento == "ativo" and padrao == "burst":
				chave_p = "yank"
				loop_p = false
			elif padrao == "pause" or (padrao == "feint" and momento == "ativo"):
				chave_p = "pause"
			elif momento == "aviso":
				chave_p = "feint" if padrao == "feint" and float(e.get("aviso_frac", 0.0)) >= 0.5 else "warn"
				loop_p = false
		_segurava = seg
	else:
		chave_j = "guard" if bool(e.get("guarda", false)) else "idle"
		chave_p = "idle"
		if jogando:
			if momento == "ativo" and padrao == "burst":
				chave_p = "burst"
			elif padrao == "pause" or (padrao == "feint" and momento == "ativo"):
				chave_p = "pause"
			elif momento == "aviso":
				chave_p = "feint" if padrao == "feint" and float(e.get("aviso_frac", 0.0)) >= 0.5 else "warn"
				loop_p = false
	if _trans_j_t > 0.0:
		chave_j = _trans_j
		loop_j = false
	if _trans_p_t > 0.0:
		chave_p = _trans_p
		loop_p = false
	if chave_j != _chave_j:
		_chave_j = chave_j
		_tocar_folha(_jog, _folha_jogador(chave_j), loop_j)
	if chave_p != _chave_p:
		_chave_p = chave_p
		_tocar_folha(_par, _folha_parceiro(chave_p), loop_p)
	UiTema.aplicar_visual_disc(_jog)
	# Ordem de desenho: Boxe, quem bate fica por cima (como na luta); Jiu-jitsu, o discípulo por cima (luvas na gola dele).
	if _arte == "bjj":
		_jog.z_index = 320
		_par.z_index = 318
	else:
		var ele_bate := chave_p == "burst" or _trans_p == "push"
		_jog.z_index = 318 if ele_bate else 320
		_par.z_index = 320 if ele_bate else 318


## Pose passageira do discípulo (soco, contragolpe, tombo...) por `dur` segundos.
func _trans_jogador(chave: String, dur: float) -> void:
	_trans_j = chave
	_trans_j_t = dur
	_chave_j = ""  # força a troca no próximo quadro (mesmo repetindo o soco)


func _trans_parceiro(chave: String, dur: float) -> void:
	_trans_p = chave
	_trans_p_t = dur
	_chave_p = ""


# ---------------------------------------------------------------- entradas
func _ao_clique_mundo(_p: Vector2) -> void:
	_apertar()


func _ao_tecla(event: InputEventKey) -> void:
	if event.echo:
		return
	if event.pressed:
		_apertar()
	else:
		_ao_soltar()


func _apertar() -> void:
	if jogo != null and janela == null:
		jogo.apertar()


func _ao_soltar() -> void:
	if jogo != null:
		jogo.soltar()  # Boxe: acaba a guarda. Jiu-jitsu: solta (e anula a puxada forte dele)


# ---------------------------------------------------------------- eventos (juice)
func _evento(ev: String, _e: Dictionary) -> void:
	match ev:
		"clique", "no_tempo", "fora_do_tempo":  # 7b1: no Muay Thai o clique é no tempo ou fora do tempo
			if _arte != "bjj":
				_trans_jogador("click", 0.3)
			_agulha_pulso = 0.06
			_tremer_barra(1)
			_tremer(1, 0.05)
			sfx.golpe_luta(false)
			if _faixa != null:
				var no_tempo := ev == "no_tempo"
				_faixa.marcar(no_tempo, float(_e.get("tempo", 0.0)))
				_flutuar(UiTema.txt("spar_beat_on", "NO TEMPO!") if no_tempo else UiTema.txt("spar_beat_off", "FORA DO TEMPO"),
					UiTema.GR3 if no_tempo else UiTema.R3, Vector2(238.0, 250.0), 1, 12.0, 0.6)
		"chute":  # 7b1: 3º clique no tempo (o empurrão forte)
			if _faixa != null:
				_faixa.marcar(true, float(_e.get("tempo", 0.0)))
				_piscar(UiTema.BR2, 0.3, 0.2)
				_flutuar(UiTema.txt("spar_beat_kick", "CHUTE!"), UiTema.Y2, Vector2(250.0, 226.0), 2, 16.0, 0.8)
				for q in _degraus:
					q.color = UiTema.Y1
				get_tree().create_timer(0.3).timeout.connect(func() -> void: _combo_ant = -1)
			_trans_jogador("kick", 0.45)
			_trans_parceiro("recoil", 0.4)
			_agulha_pulso = 0.1
			_tremer_barra(2)
			_tremer(2, 0.1)
			sfx.golpe_luta(true)
		"contragolpe":
			_trans_jogador("counter", 0.4)
			_trans_parceiro("recoil" if _arte != "bjj" else "yanked", 0.4)
			_agulha_pulso = 0.1
			_tremer_barra(2)
			_tremer(2, 0.1)
			sfx.golpe_luta(true)
		"ponto_jogador":
			_trans_parceiro("recoil" if _arte != "bjj" else "yanked", 0.5)
			_piscar(UiTema.Y2, 0.35)
			_tremer(3, 0.16)
			_estalo(_toque_dir, Vector2(_trilho_pos.x + 252.0, _trilho_pos.y + 8.0))
			_flutuar(UiTema.txt("spar_point_you", "ENCOSTOU!"), UiTema.Y2, Vector2(320.0, 62.0), 2, 6.0, 1.0)  # no céu escuro, sob o fôlego: nunca cai na placa da parede
			sfx.golpe_luta(true)
			sfx.moeda()
		"ponto_dele":
			_trans_jogador("pushed" if _arte != "bjj" else "yanked", 0.5)
			_piscar(UiTema.R2, 0.3)
			_tremer(2, 0.14)
			_estalo(_toque_esq, Vector2(_trilho_pos.x + 8.0, _trilho_pos.y + 8.0))
			_flutuar(UiTema.txt("spar_point_him", "ELE ENCOSTOU"), UiTema.R3, Vector2(320.0, 68.0), 1, 6.0, 1.0)
			sfx.golpe_luta(true, true)
		"aviso_burst", "aviso_feint":
			sfx.esquiva()
		"aviso_pause":
			sfx.foco()
		"inicio_burst":
			_tremer(1, 0.08)
		"fim":
			if not bool(jogo.saiu):
				sfx.sino_fim()


func _estalo(t: AnimSprite, p: Vector2) -> void:
	t.position = p
	t.visible = true
	t.tocar([0, 1, 2], 16.0, false, func() -> void: t.visible = false)


## Tremida curta só da barra (1 a 2 px, 2 quadros): a barra "sente" o clique sem tremer o HUD inteiro.
func _tremer_barra(px: int) -> void:
	var tw := create_tween()
	tw.tween_callback(func() -> void: _barra_no.position = Vector2(0, px))
	tw.tween_interval(0.03)
	tw.tween_callback(func() -> void: _barra_no.position = Vector2(0, -px if px > 1 else 0))
	tw.tween_interval(0.03)
	tw.tween_callback(func() -> void: _barra_no.position = Vector2.ZERO)


# ---------------------------------------------------------------- faixa da batida (Muay Thai, 7b1)
## Faixa de ritmo: as batidas (marcas brancas) chegam da direita para a zona do "no tempo" (a janela de clique); a marca que ja foi
## usada fica verde e a borda pisca verde (no tempo) ou vermelha (fora do tempo). So desenha o `estado()` do ChoqueLogica.
class FaixaBatida extends Control:
	const X := 10.0
	const LARG := 170.0
	const ZONA_X := 40.0  # centro da zona (px dentro da faixa)
	const VELOC := 100.0  # px por segundo (a janela de 0,12 s vira 12 px para cada lado)

	var beat_s := 0.5
	var janela_s := 0.12
	var estado: Dictionary = {}
	var _usadas := {}
	var _flash := 0.0
	var _flash_ok := true

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func passo(delta: float) -> void:
		_flash = maxf(_flash - delta, 0.0)
		queue_redraw()

	func marcar(no_tempo: bool, tempo: float) -> void:
		_flash = 0.18
		_flash_ok = no_tempo
		if no_tempo:
			_usadas[int(round(tempo / beat_s))] = true

	func _draw() -> void:
		var alt := size.y
		draw_rect(Rect2(0, 0, size.x, alt), UiTema.D1)
		var borda := UiTema.D2
		if _flash > 0.0:
			borda = UiTema.GR3 if _flash_ok else UiTema.R3
		var jw := roundf(janela_s * VELOC)
		var na_janela := bool(estado.get("na_janela", false))
		draw_rect(Rect2(ZONA_X - jw, 1, jw * 2.0 + 1.0, alt - 2.0), UiTema.Y0 if na_janela else UiTema.D2)
		draw_rect(Rect2(ZONA_X, 1, 1, alt - 2.0), UiTema.CREAM)  # a linha da batida certa
		var fase := str(estado.get("fase", "contagem"))
		if fase != "fim":
			var tempo := float(estado.get("tempo", 0.0)) if fase == "jogando" else 0.0
			var j0 := maxi(1, int(floor(tempo / beat_s)))
			for j in range(j0, j0 + 5):
				var d := float(j) * beat_s - tempo
				var x := ZONA_X + roundf(d * VELOC)
				if d < -0.25 or x > size.x - 4.0:
					continue
				var passou := d < -janela_s
				var cor := UiTema.GR3 if _usadas.has(j) else (UiTema.G1 if passou else UiTema.WHITE)
				draw_rect(Rect2(x - 1.0, 3, 3, alt - 6.0), cor)
		draw_rect(Rect2(0, 0, size.x, 1), borda)
		draw_rect(Rect2(0, alt - 1.0, size.x, 1), borda)
		draw_rect(Rect2(0, 0, 1, alt), borda)
		draw_rect(Rect2(size.x - 1.0, 0, 1, alt), borda)
