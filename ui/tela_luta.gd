class_name TelaLuta
extends Control
## Tela da luta (arena única). Recebe a luta já decidida e salva pelo GameState (`GameState.lutar()`) e ANIMA a
## lista de eventos: cada golpe começa `hit_frame / fps` antes do instante `t` do evento, para o contato cair
## exatamente no `t` (barra de vida, número, impacto e som saem nesse instante). Nada aqui sorteia ou calcula
## resultado. No fim chama `GameState.concluir_luta()` UMA vez e emite `terminou(resumo)`.
##
## Ordem de desenho (manifest.fight_layout): arena, lâmpada, público de trás, sombras, lutadores, efeitos,
## público da frente; o HUD (barras, retratos, relógio) fica por cima e não treme.

signal terminou(resumo: Dictionary)

const TELA := Vector2(640, 360)
const POOL_FX := 4
const POOL_NUMEROS := 16
const Z_LUTADOR := 318
const Z_ATACANTE := 320
const ESTRELAS_DELAY := 0.0

var ativa := false
var finalizada := false
var luta: Dictionary = {}
var sfx: Sfx

var _clock := -1.5
var _cues: Array = []  # {t, seq, fn}
var _idx := 0
var _fim_total := 0.0
var _t_parada := -1.0  # K.O.: o relógio da luta para no t do K.O.

var _mundo: Node2D
var _lampada: AnimSprite
var _publico_tras: AnimSprite
var _publico_frente: AnimSprite
var _l: Array = []  # 2 lutadores (Dictionary)
var _fx: Dictionary = {}  # nome -> Array[AnimSprite]
var _fx_i: Dictionary = {}
var _numeros: Array = []
var _barras: Array = []
var _flash: ColorRect
var _banner: Label
var _banner_sub: Label
var _banner_fundo: ColorRect
var _banner_ko: Sprite2D
var _rotulo_round: Label
# Novidades da luta: combo (golpes seguidos do jogador sem ser acertado), congelamento no impacto e câmera lenta no K.O.
var _combo := 0
var _rotulo_combo: Label
# Barra de ESPECIAL (só visual, nunca muda o resultado da luta): cada golpe que entra enche a barra; levar soco esvazia metade;
# na barra cheia o golpe seguinte vira o SUPER UPPERCUT, com efeitos. O cálculo é feito antes da luta, na ordem dos eventos.
var _esp_fundo: ColorRect
var _esp_cheio: ColorRect
var _esp_rotulo: Label
var _tween_esp: Tween
var _tween_combo: Tween
var _congelar_id := 0
# Queda do K.O. conforme o golpe final (só visual): "ko" (desaba), "ko_back" (golpe forte: é lançado para trás e cai de costas)
# ou "ko_knees" (soco no estômago: ajoelha e tomba para a frente). Vale para o jogador e para qualquer adversário que tenha a arte.
var _ko_nome := "ko"
static var forcar_ko := ""  # só para gravações e testes: força a queda ("ko_back" | "ko_knees"), se a arte existir
var _rotulo_tempo: Label
var _rng := RandomNumberGenerator.new()
var _shake_t := 0.0
var _shake_dur := 0.1
var _shake_amp := 1
var _ultimo_publico := -10.0
var _t := 0.0
var _opp_id := ""
var _escala_opp := 1.0
var _eventos_vistos := 0
var _ordem_numeros := 0
var _gesto: Gesto  # Fase 6a: gesto do John na entrada e na vitória
var _gesto_nome := ""
# Fase 7a1: passiva da arte (só visual). Boxe: embalo (5 bolinhas) e cansaço; Jiu-jitsu: barra de pegada e fase no chão.
var _passiva := ""  # "" | "fast_hands" | "submission"
var _pips: Array = []
var _embalo_atual := 0
var _marcas := 0  # 7b1 (Muay Thai): marcas na perna dele depois do último golpe mostrado (0-3); com 2+ ele manca (limp)
var _marcas_hud: Array = []  # 7b1: as 3 marcas (ui_shin_mark) ao lado da vida dele
var _marcas_acesas := 0
var _marcas_cheias := false
var _tween_marcas: Tween
var _letreiro_cheia: TextureRect  # PERNA CHEIA! (7b1), abaixo das marcas
var _banner_spin: Sprite2D  # CHUTE RODADO! no meio da arena (7b1)
var _cansado := false
var _rot_cansado: Control
var _grip_fill: TextureRect
var _grip_larg := 0.0
var _grip_cheia := false
var _fase_visual := "standing"  # "standing" | "ground" (as animações de chão só entram se as folhas existirem)
var _banner_sub_img: Sprite2D
var _bloqueio_ate := -10.0  # fim da queda (takedown + fall) em andamento: o próximo golpe espera


func _ready() -> void:
	position = Vector2.ZERO
	size = TELA
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_rng.randomize()
	sfx = Sfx.new()
	add_child(sfx)
	visible = false
	_gesto = Gesto.new()
	add_child(_gesto)
	GameState.gesto_cancelado.connect(_ao_gesto_cancelado)


# --- Montagem (depende do adversário e da luva equipada) ---

func _montar(opp_id: String) -> void:
	for c in get_children():
		if c != sfx and c != _gesto:
			c.queue_free()
	_l.clear()
	_fx.clear()
	_fx_i.clear()
	_numeros.clear()
	_barras.clear()
	_pips.clear()
	_embalo_atual = 0
	_marcas = 0
	_marcas_hud.clear()
	_marcas_acesas = 0
	_marcas_cheias = false
	_letreiro_cheia = null
	_banner_spin = null
	_cansado = false
	_rot_cansado = null
	_grip_fill = null
	_grip_cheia = false
	_fase_visual = "standing"
	_bloqueio_ate = -10.0
	_passiva = str(luta.get("passive", ""))
	_opp_id = opp_id
	var by: Dictionary = UiTema.manifest().get("by_data_id", {})
	var lay: Dictionary = UiTema.manifest().get("fight_layout", {})
	_escala_opp = float(by.get(opp_id, {}).get("scale", 1.0))

	var fundo := ColorRect.new()
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.color = UiTema.INK
	fundo.size = TELA
	add_child(fundo)

	_mundo = Node2D.new()
	_mundo.z_index = 100  # fica acima do ColorRect (os z negativos da arena não somem)
	UiTema.alinhar(_mundo, "ignore")  # arena, lutadores, efeitos e números flutuantes: posição livre de propósito
	add_child(_mundo)

	# Cenário (7a1): prefixo da arena da luta ("arena" = borracharia, "arena_league" = ginásio da liga). Camada que não existe
	# no manifest cai na borracharia; a liga não tem lâmpada (de dia): o nó existe, mas invisível.
	var pre := str(luta.get("arena", "arena"))
	if UiTema.sprite(pre + "_bg").is_empty():
		pre = "arena"
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = UiTema.textura(pre + "_bg")
	bg.z_index = -100
	_mundo.add_child(bg)
	var nome_lamp := pre + "_lamp" if not UiTema.sprite(pre + "_lamp").is_empty() else "arena_lamp"
	_lampada = _anim(nome_lamp, UiTema.pos(nome_lamp), -50)
	_lampada.visible = pre == "arena" or nome_lamp == pre + "_lamp"
	var nome_tras := _camada(pre, "crowd_back")
	var nome_frente := _camada(pre, "crowd_front")
	_publico_tras = _anim(nome_tras, UiTema.pos(nome_tras), -60)
	_publico_tras.tocar([0, 1], 2.0, true)
	_publico_frente = _anim(nome_frente, UiTema.pos(nome_frente), 50)
	_publico_frente.tocar([0, 1], 2.0, true)

	var pos_j := _vetor(lay.get("player_pos", [296, 318]))
	var pos_o := _vetor(lay.get("opponent_pos", [346, 318]))
	_l.append(_novo_lutador(0, pos_j, 1.0))
	_l.append(_novo_lutador(1, pos_o, _escala_opp))

	for nome in ["fx_fight_hit", "fx_fight_crit", "fx_whoosh", "fx_block", "fx_dust_fall"]:
		var lista: Array = []
		for i in POOL_FX:
			var a := _anim(nome, Vector2.ZERO, 400)
			a.visible = false
			lista.append(a)
		_fx[nome] = lista
		_fx_i[nome] = 0
	for i in 2:
		var suor := _anim("fx_sweat", Vector2.ZERO, 410)
		suor.visible = false
		_l[i]["suor"] = suor
		var estrelas := _anim("fx_ko_stars", Vector2.ZERO, 410)
		estrelas.visible = false
		_l[i]["estrelas"] = estrelas
	for i in 2:
		_repouso(i)  # os dois respiram (idle em loop) até o primeiro golpe
	for i in POOL_NUMEROS:
		_numeros.append(Sala.Numero.new(_mundo))

	_banner_ko = Sprite2D.new()
	_banner_ko.texture = UiTema.textura("ui_banner_ko")
	_banner_ko.position = Vector2(320, 118)
	_banner_ko.scale = Vector2(2, 2)
	_banner_ko.z_index = 950
	_banner_ko.visible = false
	_mundo.add_child(_banner_ko)

	_banner_spin = Sprite2D.new()  # 7b1: o fim pelo chute rodado troca o K.O.! por este letreiro
	_banner_spin.texture = UiTema.textura("ui_banner_spin_kick")
	_banner_spin.position = Vector2(320, 118)
	_banner_spin.scale = Vector2(2, 2)
	_banner_spin.z_index = 950
	_banner_spin.visible = false
	_mundo.add_child(_banner_spin)

	_banner_sub_img = Sprite2D.new()
	_banner_sub_img.texture = UiTema.textura("ui_banner_submission")
	_banner_sub_img.position = Vector2(320, 118)
	_banner_sub_img.scale = Vector2(2, 2)
	_banner_sub_img.z_index = 950
	_banner_sub_img.visible = false
	_mundo.add_child(_banner_sub_img)

	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = TELA
	add_child(_flash)

	_montar_hud(opp_id, lay, by)

	# Letreiros do meio da arena (fora do mundo: a tremida não os desloca)
	_banner_fundo = ColorRect.new()
	_banner_fundo.color = Color(0.05, 0.04, 0.08, 0.72)
	_banner_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_fundo.visible = false
	add_child(_banner_fundo)
	_banner_fundo.set_meta("ui_pos", "center_h")
	_banner_fundo.z_index = 1090  # B2 (QA 7b1): os letreiros do meio ficam acima dos numeros de dano (mundo z 100 + 900..1000)
	# Letreiros: o Label ocupa a largura da tela e centraliza o texto (ver `_posicionar_banner`).
	_banner = UiTema.rotulo(self, "", UiTema.Y2, 0, 100, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	_banner.visible = false
	UiTema.alinhar(_banner, "center_h")
	_banner.z_index = 1100
	_banner_sub = UiTema.rotulo(self, "", UiTema.WHITE, 0, 140, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	_banner_sub.size = Vector2(TELA.x, 12.0)
	_banner_sub.visible = false
	UiTema.alinhar(_banner_sub, "center_h")
	_banner_sub.z_index = 1100


## Camada do cenário com o prefixo da arena; se faltar no manifest, a da borracharia.
func _camada(pre: String, camada: String) -> String:
	var nome := "%s_%s" % [pre, camada]
	return nome if not UiTema.sprite(nome).is_empty() else "arena_" + camada


func _vetor(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func _anim(nome: String, p: Vector2, z: int) -> AnimSprite:
	var a := AnimSprite.new()
	a.definir(nome)
	a.position = p
	a.z_index = z
	_mundo.add_child(a)
	return a


func _novo_lutador(i: int, base: Vector2, escala: float) -> Dictionary:
	var sombra := Sprite2D.new()
	sombra.centered = false
	sombra.texture = UiTema.textura("fight_shadow")
	sombra.offset = -UiTema.pivo("fight_shadow")
	sombra.position = base + Vector2(0, -1)
	sombra.z_index = 5
	_mundo.add_child(sombra)
	var spr := AnimSprite.new()
	spr.position = base
	spr.z_index = Z_LUTADOR
	_mundo.add_child(spr)
	var l := {"spr": spr, "sombra": sombra, "base": base, "escala": escala, "dir": 1 if i == 0 else -1,
		"estado": "idle", "vida": 1.0}
	_l_definir(l, i, _idle_da_arte(i))
	return l


# Nome do sprite da ação `acao` do lutador i (a luva do jogador vem do sufixo da luva equipada).
func _nome(i: int, acao: String) -> String:
	var by: Dictionary = UiTema.manifest().get("by_data_id", {})
	if i == 0:
		return UiTema.com_luva(str(by.get("player_fight", {}).get("actions", {}).get(acao, "fight_player_" + acao)))
	return str(by.get(_opp_id, {}).get("actions", {}).get(acao, _opp_id + "_" + acao))


func _l_definir(l: Dictionary, i: int, acao: String) -> void:
	l.spr.definir(_nome(i, acao))


# --- HUD (barras, retratos, nomes, relógio) ---

func _montar_hud(opp_id: String, lay: Dictionary, by: Dictionary) -> void:
	var hud := Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.size = TELA
	hud.z_index = 500
	add_child(hud)
	var faixa: Array = lay.get("hud_band", [0, 0, 640, 46])
	UiTema.painel(hud, "ui_panel", Rect2(float(faixa[0]), float(faixa[1]), float(faixa[2]), float(faixa[3])))

	# Jogador (esquerda)
	var pf: Array = lay.get("player_portrait_frame", [6, 6])
	var quadro_j := UiTema.textura_rect(hud, "ui_portrait_frame", float(pf[0]), float(pf[1]))
	UiTema.textura_rect(quadro_j, UiTema.nome_retrato_jogador(), 2, 2).texture = UiTema.textura_disc(UiTema.nome_retrato_jogador())  # o retrato fica dentro da moldura
	var pn: Array = lay.get("player_name", [46, 6])
	UiTema.rotulo(hud, UiTema.txt("preview_you", "VOCÊ"), UiTema.WHITE, float(pn[0]), float(pn[1]))
	var bj: Array = lay.get("player_hp_bar", [46, 16, 236, 12])
	_barras.append(Barra.new(self, hud, Rect2(float(bj[0]), float(bj[1]), float(bj[2]), float(bj[3])), 0))
	var pt: Array = lay.get("player_tactic", [46, 32])
	var tid := str(luta.get("tactic", GameState.tatica))
	var info_t: Dictionary = by.get(tid, {})
	var nome_t := str(GameState.lutas.tatica(tid).get("name", tid)).to_upper()
	UiTema.textura_rect(hud, str(info_t.get("icon_9", "icon_tactic_" + tid + "_9")), float(pt[0]), float(pt[1]) - 1)
	UiTema.rotulo(hud, nome_t, _cor_tatica(str(info_t.get("color", "white"))), float(pt[0]) + 12, float(pt[1]))
	_rotulo_combo = UiTema.rotulo(hud, "", UiTema.Y1, float(pt[0]), float(pt[1]) + 13.0)
	_rotulo_combo.scale = Vector2(2, 2)  # o combo precisa ser lido no meio da luta
	_rotulo_combo.position.y += 9.0
	_esp_fundo = ColorRect.new()
	_esp_fundo.color = Color(0.05, 0.04, 0.09, 0.85)
	_esp_fundo.position = Vector2(float(pt[0]), float(pt[1]) + 12.0)
	_esp_fundo.size = Vector2(110, 6)
	hud.add_child(_esp_fundo)
	_esp_cheio = ColorRect.new()
	_esp_cheio.color = UiTema.Y1
	_esp_cheio.position = Vector2(1, 1)
	_esp_cheio.size = Vector2(0, 4)
	_esp_fundo.add_child(_esp_cheio)
	_esp_rotulo = UiTema.rotulo(hud, "", UiTema.Y1, float(pt[0]) + 114.0, float(pt[1]) + 10.0)
	_rotulo_combo.modulate.a = 0.0
	_montar_hud_passiva(hud, float(pt[1]))

	# Adversário (direita, espelhado)
	var info_o: Dictionary = by.get(opp_id, {})
	var of: Array = lay.get("opponent_portrait_frame", [598, 6])
	var quadro_o := UiTema.textura_rect(hud, str(info_o.get("portrait_frame", "ui_portrait_frame")), float(of[0]), float(of[1]))
	var ret := UiTema.textura_rect(quadro_o, str(info_o.get("portrait", "")), 2, 2)
	ret.flip_h = true
	var opp: Dictionary = GameState.lutas.adversario(opp_id)
	var on: Array = lay.get("opponent_name_right", [594, 6])
	var nome_o := str(opp.get("name", opp_id)).to_upper()
	var l_nome := UiTema.rotulo(hud, nome_o, UiTema.WHITE, 0, float(on[1]))
	l_nome.position.x = roundf(float(on[0]) - UiTema.largura(nome_o))
	var bo: Array = lay.get("opponent_hp_bar", [358, 16, 236, 12])
	_barras.append(Barra.new(self, hud, Rect2(float(bo[0]), float(bo[1]), float(bo[2]), float(bo[3])), 1))
	var po: Array = lay.get("opponent_profile_right", [594, 32])
	var perfil := str(opp.get("profile", "")).to_upper()
	var l_perf := UiTema.rotulo(hud, perfil, _cor_tatica(str(info_o.get("color", "white"))), 0, float(po[1]))
	l_perf.position.x = roundf(float(po[0]) - UiTema.largura(perfil))

	# Relógio
	var tb: Array = lay.get("timer_box", [292, 4, 56, 32])
	UiTema.painel(hud, "ui_card", Rect2(float(tb[0]), float(tb[1]), float(tb[2]), float(tb[3])))
	# Round (7 px) + 3 px + tempo 2x (14 px) = 24 px, centralizados na área útil do cartão (3 px de borda).
	var area_rel := UiTema.area_nove("ui_card", Vector2(float(tb[2]), float(tb[3])))
	var y0 := float(tb[1]) + area_rel.position.y + roundf((area_rel.size.y - 24.0) / 2.0)
	var col := Rect2(float(tb[0]), 0.0, float(tb[2]), 0.0)
	_rotulo_round = UiTema.rotulo_centrado(hud, Rect2(col.position.x, y0, col.size.x, 7.0), "", UiTema.G3, 1, false, "center_h")
	_rotulo_tempo = UiTema.rotulo_centrado(hud, Rect2(col.position.x, y0 + 10.0, col.size.x, 14.0), "0:16", UiTema.Y1, 2, false,
		"center_h")


## HUD da passiva (7a1), na fileira da tática, à direita do nome dela (x 140..282). Boxe: CANSADO (ícone + texto, só no 3º round)
## e as 5 bolinhas de embalo coladas na ponta da barra de vida. Jiu-jitsu: ícone da pegada + barra fina que enche com o tempo.
func _montar_hud_passiva(hud: Control, y_tatica: float) -> void:
	if _passiva == "fast_hands":
		var n := 5
		var x0 := 282.0 - (9.0 * float(n) - 2.0)
		for i in n:
			_pips.append(CartaoPassiva.bolinha(hud, x0 + 9.0 * float(i), y_tatica + 1.0, 0))
		var texto := UiTema.txt("fight_tired", "CANSADO")
		var tem_icone := not UiTema.sprite("icon_tired").is_empty()
		var grupo := UiTema.largura_visivel(texto) + (12.0 if tem_icone else 0.0)
		_rot_cansado = Control.new()
		_rot_cansado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rot_cansado.position = Vector2(roundf(x0 - 8.0 - grupo), y_tatica)
		_rot_cansado.size = Vector2(grupo, 9)
		_rot_cansado.visible = false
		hud.add_child(_rot_cansado)
		if tem_icone:
			UiTema.textura_rect(_rot_cansado, "icon_tired", 0, 0)
		UiTema.rotulo(_rot_cansado, texto, UiTema.Y1, 12.0 if tem_icone else 0.0, 1)
	elif _passiva == "shin":
		_montar_marcas(hud, y_tatica)
	elif _passiva == "submission":
		_grip_larg = 128.0
		if not UiTema.sprite("icon_grip").is_empty():
			UiTema.textura_rect(hud, "icon_grip", 140, y_tatica - 1.0)
		CartaoPassiva.barra(hud, 151.0, y_tatica + 1.0, _grip_larg + 2.0)
		_grip_fill = CartaoPassiva.enchimento(hud, 152.0, y_tatica + 2.0, 0.0, 0)
		_grip_fill.visible = false


## HUD do Muay Thai (7b1): ícone da perna + 3 marcas ao lado da vida DELE, coladas no começo da barra dele (x 358), na fileira do perfil.
## Cada marca inteira acende (quadro 1, com 1 quadro de clarão); cheias, piscam e o letreiro PERNA CHEIA! aparece logo abaixo.
func _montar_marcas(hud: Control, y_tatica: float) -> void:
	var lay: Dictionary = UiTema.manifest().get("fight_layout", {})
	var bo: Array = lay.get("opponent_hp_bar", [358, 16, 236, 12])
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("shin_hud", {})
	var n := int(luta.get("marks_max", info.get("count", 3)))
	var passo := float(info.get("step_px", 12))
	var x0 := float(bo[0])
	UiTema.textura_rect(hud, str(info.get("icon", "icon_shin")), x0, y_tatica)
	for i in n:
		_marcas_hud.append(CartaoPassiva.marca_perna(hud, x0 + 13.0 + passo * float(i), y_tatica - 1.0, 0))
	_letreiro_cheia = UiTema.textura_rect(hud, str(info.get("banner_full", "ui_banner_marks_full")), x0, y_tatica + 13.0)
	_letreiro_cheia.visible = false


func _cor_tatica(nome_cor: String) -> Color:
	match nome_cor:
		"r2":
			return UiTema.R2
		"y1":
			return UiTema.Y1
		"b3", "b2":
			return UiTema.B3
		"gr2":
			return UiTema.GR3
	return UiTema.cor_nome(nome_cor, UiTema.WHITE)  # p1 (Tonhão), st2 (Kid): cores novas da Fase 5


# --- Início da luta ---

## Começa a animação da luta decidida (formato de `GameState.lutar()`).
func iniciar(dados: Dictionary) -> void:
	luta = dados
	finalizada = false
	_montar(str(dados.opponent))
	_clock = -float(dados.intro_seconds)
	_idx = 0
	_cues.clear()
	_t_parada = -1.0
	_shake_t = 0.0
	_eventos_vistos = 0
	var res: Dictionary = dados.result
	var t_end: float = float(res.t_end)
	_fim_total = t_end + float(dados.outro_seconds)
	_barras[0].definir(1.0, false)
	_barras[1].definir(1.0, false)
	visible = true
	ativa = true
	modulate = Color.WHITE
	_agendar_tudo()
	_atualizar_relogio(0.0)
	_gesto_luta(GameState.pedir_gesto("fight_intro"))  # só o John (o discípulo recebe {}); cabe nos 1,5 s da entrada
	_mundo.position = Vector2.ZERO


func _agendar_tudo() -> void:
	var intro := float(luta.intro_seconds)
	var res: Dictionary = luta.result
	_combo = 0
	# Abertura: "1º ROUND", depois "LUTEM!" com o sino.
	_cue(-intro + 0.05, func() -> void:
		_texto_banner(UiTema.txt("fight_round", "{n}º ROUND", {"n": 1}), UiTema.WHITE, 2)
		sfx.publico(-16.0))
	_cue(-0.7, func() -> void:
		sfx.sino_inicio()
		_texto_banner(UiTema.txt("fight_start", "LUTEM!"), UiTema.Y2, 3)
		_publico_cheer(false))
	_cue(0.15, func() -> void: _esconder_banner())
	# 2º e 3º rounds: sino e faixa no começo de cada round (só se a luta ainda estiver de pé).
	var dur_round := float(GameState.lutas.combate.round_length)
	var fim_real := float(res.t_ko) if bool(res.ko) else float(res.t_end)
	for r in [2, 3]:
		var t_round := dur_round * float(r - 1)
		if t_round < fim_real - 0.4:
			_cue(t_round, func() -> void:
				sfx.sino_inicio()
				_texto_banner(UiTema.txt("fight_round", "{n}º ROUND", {"n": r}), UiTema.WHITE, 2))
			_cue(t_round + 0.9, func() -> void: _esconder_banner())

	# 7a1: cansaço do Boxe (só se a tática cansa: o Defensivo guarda o fôlego) e pegada cheia do Jiu-jitsu.
	var tired_at := float(luta.get("tired_at", -1.0))
	if _passiva == "fast_hands" and tired_at >= 0.0 and tired_at < fim_real - 0.4 and bool(luta.get("tires", false)):
		_cue(tired_at, func() -> void: _ficar_cansado())
	var grip_at := float(luta.get("grip_full_at", -1.0))
	if _passiva == "submission" and grip_at > 0.0 and grip_at < fim_real - 0.2:
		_cue(grip_at, func() -> void: _pegada_cheia())

	var eventos: Array = luta.events
	var cont := 0  # barra de especial, na ordem em que os golpes acontecem
	for e in eventos:
		e["barra_apos"] = -1
		if str(e.type) == "dodge" or bool(e.get("blocked", false)):
			continue
		if int(e.who) == 0:
			cont += 1
			if cont >= GameState.lutas.golpes_especial and _golpe_especial(e)[0] != "" and not bool(e.ko):
				e["especial"] = true
				cont = 0
		else:
			cont /= 2
		e["barra_apos"] = cont
	for e in eventos:
		_agendar_evento(e)
	_ko_nome = "ko"
	for e in eventos:
		if bool(e.get("ko", false)):
			_ko_nome = _queda_do_golpe(int(e.target), e)

	# O motivo da derrota NÃO é lido aqui: o GameState o calcula em segundo plano e a tela de fim o lê ao abrir.

	var perdedor := int(luta.loser)
	var grogue: Dictionary = luta.grogue
	var t_end := float(res.t_end)
	if bool(res.ko) and perdedor >= 0:
		var vencedor := 1 - perdedor
		var t_ko := float(res.t_ko)
		if str(res.get("finish", "")) == "submission":
			_agendar_finalizacao(perdedor, vencedor, t_ko)
			_t_parada = t_ko
			return
		if not grogue.is_empty():
			_cue(float(grogue.from) + 0.3, func() -> void: _estado(perdedor, "tired"))
			_cue(float(grogue.from) + 0.25, func() -> void: _estado(vencedor, "guard"))
			_cue(float(grogue.to), func() -> void: _cair(perdedor))
		else:
			_cue(t_ko + 0.06, func() -> void: _cair(perdedor))
		_cue(t_ko + 0.05, func() -> void: _sair_do_chao(perdedor))
		var t_queda := (float(grogue.to) if not grogue.is_empty() else t_ko + 0.06)
		var spr_ko := UiTema.sprite(_nome(perdedor, _ko_nome))
		var fps_ko := float(spr_ko.get("fps", 10.0))
		var t_chao := t_queda + float(spr_ko.get("ground_frame", 3)) / fps_ko  # quadro em que o corpo bate no chão
		_cue(t_chao, func() -> void: _chao(perdedor))
		_cue(t_chao + 0.5, func() -> void: _comemorar(vencedor))
		_cue(t_chao + 0.45, func() -> void:
			if bool(res.win):
				sfx.vitoria()
			else:
				sfx.derrota())
		_cue(t_chao + 0.2, func() -> void: sfx.sino_fim())
		_t_parada = t_ko
	else:
		# Fim por pontos: "TEMPO!", sino, o vencedor comemora e o outro cansa.
		var vencedor := 0 if bool(res.win) else 1
		_cue(t_end, func() -> void:
			_sair_do_chao(-1)
			sfx.sino_fim()
			_texto_banner(UiTema.txt("fight_time", "TEMPO!"), UiTema.Y2, 2))
		_cue(t_end + 0.35, func() -> void:
			_comemorar(vencedor)
			_estado(1 - vencedor, "tired")
			_texto_sub(UiTema.txt("fight_points", "POR PONTOS"), UiTema.CREAM)
			sfx.publico()
			_publico_cheer(false)
			if bool(res.win):
				sfx.vitoria()
			else:
				sfx.derrota())
		_t_parada = t_end


## Fim por finalização (Jiu-jitsu): o golpe submission já foi agendado como evento; o adversário bate no chão (tap_out, que
## segura o último quadro), o letreiro FINALIZOU! entra e a torcida vibra. Sem as folhas, ele só cansa e o jogador comemora.
func _agendar_finalizacao(perdedor: int, vencedor: int, t_ko: float) -> void:
	_cue(t_ko + 0.5, func() -> void:
		if str(_l[perdedor].estado) != "preso":
			_estado(perdedor, "tired")
			_estado(vencedor, "victory")
		_banner_finalizou())
	_cue(t_ko + 0.65, func() -> void: sfx.sino_fim())
	_cue(t_ko + 1.0, func() -> void: _comemorar_finalizacao())


func _comemorar_finalizacao() -> void:
	sfx.publico()
	_publico_cheer(false)
	if bool(luta.result.win):
		sfx.vitoria()
	else:
		sfx.derrota()


func _banner_finalizou() -> void:
	_tremer(2, 0.3)
	_flash_tela(0.4)
	_lampada.tocar([1, 0, 1, 0], 8.0)
	_publico_cheer(true)
	sfx.queda()
	if not UiTema.sprite("ui_banner_submission").is_empty():
		_banner_sub_img.visible = true
		_banner_sub_img.scale = Vector2(3, 3)
		_banner_sub_img.modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_banner_sub_img, "modulate:a", 1.0, 0.08)
		tw.tween_callback(func() -> void: _banner_sub_img.scale = Vector2(2, 2)).set_delay(0.09)
	else:
		_texto_banner(UiTema.txt("fight_submission", "FINALIZOU!"), UiTema.Y2, 3)


## Fim em pé: se a luta estava no chão, os dois voltam ao idle em pé (não há folha de "levantar": corte seco combinado).
## exceto = lutador que não deve ser tocado (o que vai cair); -1 = nenhum.
func _sair_do_chao(exceto: int) -> void:
	if _fase_visual != "ground":
		return
	_fase_visual = "standing"
	for i in 2:
		if i != exceto and str(_l[i].estado) == "idle":
			_repouso(i)


func _ficar_cansado() -> void:
	_cansado = true
	if _rot_cansado != null:
		_rot_cansado.visible = true
		_rot_cansado.modulate = Color(2, 2, 2)
		_rot_cansado.create_tween().tween_property(_rot_cansado, "modulate", Color.WHITE, 0.3)
	_repouso(0)


## Pegada cheia: o número PEGADA! sobe da cabeça do jogador e a barra pisca (o quadro 1 é a barra cheia).
func _pegada_cheia() -> void:
	_grip_cheia = true
	var n := _pegar_numero()
	_ordem_numeros += 1
	n.definir_z(940 + _ordem_numeros % 40)
	n.iniciar(UiTema.txt("fight_grip_full", "PEGADA!"), UiTema.Y2, true, "", _ponto_cabeca(0) + Vector2(0, -14), 0.9, 18.0)
	Sala.afastar(_numeros, n, true)
	sfx.publico(-12.0)


## Embalo do Boxe: acende as bolinhas até n (a nova pisca) e apaga todas quando ele esquiva (n = 0).
func _hud_embalo(n: int) -> void:
	if _pips.is_empty() or n == _embalo_atual:
		return
	var subiu := n > _embalo_atual
	_embalo_atual = n
	for i in _pips.size():
		var b: Control = _pips[i]
		if i < n:
			if subiu and i == n - 1:
				CartaoPassiva.definir_bolinha(b, 2)
				var tw := create_tween()
				tw.tween_interval(0.08)
				tw.tween_callback(func() -> void:
					if is_instance_valid(b):
						CartaoPassiva.definir_bolinha(b, 1))
			else:
				CartaoPassiva.definir_bolinha(b, 1)
		else:
			CartaoPassiva.definir_bolinha(b, 0)


## Marcas da perna do Muay Thai: acende até `n` (a nova pisca 1 quadro) e, na perna cheia, as 3 piscam (quadro 1/3) com o letreiro.
func _hud_marcas(n: int) -> void:
	if _marcas_hud.is_empty() or n == _marcas_acesas:
		return
	var subiu := n > _marcas_acesas
	_marcas_acesas = n
	var cheia := n >= _marcas_hud.size()
	for i in _marcas_hud.size():
		var m: Control = _marcas_hud[i]
		if i < n:
			if subiu and i == n - 1 and not cheia:
				CartaoPassiva.definir_marca_perna(m, 2)
				var tw := create_tween()
				tw.tween_interval(0.08)
				tw.tween_callback(func() -> void:
					if is_instance_valid(m):
						CartaoPassiva.definir_marca_perna(m, 1))
			else:
				CartaoPassiva.definir_marca_perna(m, 1)
		else:
			CartaoPassiva.definir_marca_perna(m, 0)
	if cheia and not _marcas_cheias:
		_marcas_cheias = true
		_perna_cheia()
	elif not cheia:
		_marcas_cheias = false
		if _tween_marcas != null and _tween_marcas.is_valid():
			_tween_marcas.kill()
		if _letreiro_cheia != null:
			_letreiro_cheia.visible = false


## Perna cheia: as marcas alternam entre o quadro 1 e o 3 (6 quadros por segundo) e o letreiro PERNA CHEIA! entra (pop) e fica.
func _perna_cheia() -> void:
	if _tween_marcas != null and _tween_marcas.is_valid():
		_tween_marcas.kill()
	_tween_marcas = create_tween().set_loops()
	_tween_marcas.tween_callback(func() -> void: _quadro_marcas(3))
	_tween_marcas.tween_interval(1.0 / 6.0)
	_tween_marcas.tween_callback(func() -> void: _quadro_marcas(1))
	_tween_marcas.tween_interval(1.0 / 6.0)
	if _letreiro_cheia != null and not UiTema.sprite("ui_banner_marks_full").is_empty():
		_letreiro_cheia.visible = true
		_letreiro_cheia.modulate = Color(2, 2, 2)
		create_tween().tween_property(_letreiro_cheia, "modulate", Color.WHITE, 0.3)
	else:
		_numero_aviso(UiTema.txt("fight_marks_full", "PERNA CHEIA!"), UiTema.BR3)
	sfx.publico(-12.0)
	_flash_tela(0.2)


func _quadro_marcas(q: int) -> void:
	for m in _marcas_hud:
		if is_instance_valid(m):
			CartaoPassiva.definir_marca_perna(m, q)


## Aviso de texto curto que sobe da cabeça do adversário (quando o letreiro desenhado não existe).
func _numero_aviso(texto: String, cor: Color) -> void:
	var n := _pegar_numero()
	_ordem_numeros += 1
	n.definir_z(940 + _ordem_numeros % 40)
	n.iniciar(texto, cor, true, "", _ponto_cabeca(1) + Vector2(0, -14), 0.9, 18.0)
	Sala.afastar(_numeros, n, true)


## Vitória: se o jogador é o John, entra o gesto curto (0,15-0,59 s) e a pose de braços erguidos vem logo depois.
func _comemorar(vencedor: int) -> void:
	if vencedor == 0:
		var plano := GameState.pedir_gesto("victory")
		if not plano.is_empty():
			_l[0].estado = "victory"  # o fim do gesto (ou o clique) cai direto na pose
			_gesto_luta(plano)
			return
	_estado(vencedor, "victory")


## Toca o plano do gesto no lutador 0. {} = nada (discípulo, ou sem folha).
func _gesto_luta(plano: Dictionary) -> void:
	if plano.is_empty():
		return
	_gesto.iniciar(plano, {
		"comecar": _gesto_luta_comecar,
		"rip": func() -> void: sfx.strap_rip(),
		"toque": func(_n: int) -> void: sfx.tap_glove(),
		"fim": _gesto_luta_fim,
	})


func _gesto_luta_comecar(plano: Dictionary) -> void:
	var nome := UiTema.com_luva("fight_player_gesture_short" if str(plano.version) == "short" else "fight_player_gesture")
	if UiTema.sprite(nome).is_empty() or _l.is_empty() or str(_l[0].estado) == "ko":
		return
	_gesto_nome = nome
	var spr: AnimSprite = _l[0].spr
	spr.definir(nome)
	var seq: Array = []
	for q in spr.hframes:
		seq.append(q)
	spr.tocar(seq, float(UiTema.sprite(nome).get("fps", 9.0)), false)


func _gesto_luta_fim() -> void:
	if _gesto_nome != "" and not _l.is_empty():
		_gesto_nome = ""
		_repouso(0)


func _ao_gesto_cancelado() -> void:
	_gesto.cancelar()
	sfx.cortar_rip()
	if _gesto_nome != "" and not _l.is_empty():
		_gesto_nome = ""
		_repouso(0)


func _cue(t: float, fn: Callable) -> void:
	_cues.append({"t": t, "seq": _cues.size(), "fn": fn})
	_cues.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.t < b.t or (a.t == b.t and a.seq < b.seq))


func _agendar_evento(e: Dictionary) -> void:
	var quem := int(e.who)
	var alvo := int(e.target)
	var t_real := float(e.t)
	var chao := str(e.get("phase", "standing")) == "ground" and _pose_chao_ok()
	var eh_esquiva := str(e.kind) == "dodge" or str(e.type) == "dodge"
	# No chão (Jiu-jitsu) a esquiva não tem golpe novo: os dois ficam nas poses paradas de chão e só aparece o aviso.
	if chao and eh_esquiva:
		var t_e := t_real + _espera_da_queda(t_real - 0.1)
		_cue(t_e, func() -> void: _esquivou(e))
		return
	# Golpe da luta (data/moves.json): usa o sprite do golpe se ele existir; senão, o jab/heavy de sempre.
	var anim := _anim_do_golpe(quem, e)
	var especial := bool(e.get("especial", false))
	if especial:
		var esp := _golpe_especial(e)
		anim = esp[0]
		e["move_anim"] = esp[0]
		e["defender_move_anim"] = esp[1]
	e["anim_usada"] = anim
	var reacao := _reacao_do_golpe(alvo, e, anim)
	if chao and not _existe_anim(alvo, reacao) or (chao and reacao in ["block", "hit", "dodge"]):
		# No chão a defesa nunca é uma pose em pé: usa a reação de chão (ou a pose parada de chão).
		var cand: Array = ["ground_top_hit", "ground_top_idle"] if alvo == 0 else ["ground_hit", "ground_bottom_idle"]
		for c in cand:
			if _existe_anim(alvo, c):
				reacao = c
				break
	e["reacao_usada"] = reacao
	var s := UiTema.sprite(_nome(quem, anim))
	var antes := float(int(s.get("hit_frame", 1))) / maxf(float(s.get("fps", 12.0)), 1.0)
	# A queda (takedown + fall) não é cortada: o golpe seguinte só começa quando ela termina. O tempo total da luta não muda;
	# só a apresentação espera.
	var d := _espera_da_queda(t_real - antes)
	var t := t_real + d
	if d > 0.0:
		_bloqueio_ate = t - antes + 0.45
	# O golpe sai `hit_frame / fps` antes: o contato cai exatamente em `t`.
	_cue(t - antes, func() -> void: _tocar(quem, anim))
	if str(e.kind) == "takedown":
		var fall_len := 0.0
		var sf := UiTema.sprite(_nome(alvo, reacao))
		if not sf.is_empty():
			fall_len = float(int(sf.get("frames", 1))) / maxf(float(sf.get("fps", 12.0)), 1.0)
		var tk_len := float(int(s.get("frames", 1))) / maxf(float(s.get("fps", 12.0)), 1.0)
		_bloqueio_ate = (t - antes) + maxf(tk_len, antes + fall_len)
	if especial:
		_cue(t - antes - 0.35, func() -> void: _preparar_especial())
		_cue(t + 0.9, func() -> void: _esconder_banner())
	if eh_esquiva:
		var sd := UiTema.sprite(_nome(alvo, "dodge"))
		var um_quadro := 1.0 / maxf(float(sd.get("fps", 14.0)), 1.0)
		_cue(t - um_quadro, func() -> void: _tocar(alvo, "dodge"))
		_cue(t, func() -> void: _esquivou(e))
	else:
		_cue(t, func() -> void: _acertou(e))


## Golpe do especial dos cliques: [animação, reação]. Boxe e sem arte: uppercut / hit_up. Jiu-jitsu nunca usa animação de boxe:
## em pé é o clinch_push (reação hit_clinch) e no chão é o ground_pressure (reação ground_hit). ["", ""] se a folha não existe.
func _golpe_especial(e: Dictionary) -> Array:
	if _passiva == "shin":  # 7b1 (lição A1 da 7a1): o Muay Thai nunca usa o uppercut (golpe de boxe); o especial é o chute rodado
		if _existe_anim(0, "spin_kick"):
			return ["spin_kick", "hit_spin"]
		return ["knee", "hit_body"] if _existe_anim(0, "knee") else ["", ""]
	if _passiva != "submission":
		return ["uppercut", "hit_up"] if _existe_anim(0, "uppercut") else ["", ""]
	if str(e.get("phase", "standing")) == "ground" and _pose_chao_ok() and _existe_anim(0, "ground_pressure"):
		return ["ground_pressure", "ground_hit"]
	return ["clinch_push", "hit_clinch"] if _existe_anim(0, "clinch_push") else ["", ""]


## Segundos que um golpe que começaria em `inicio` precisa esperar para não cortar a queda em andamento (0 se não há queda).
func _espera_da_queda(inicio: float) -> float:
	return maxf(0.0, _bloqueio_ate - inicio)


# --- Golpes: sprite do golpe escolhido, com volta ao jab/heavy (e ao `hit`) quando a arte ainda não existe ---

func _existe_anim(i: int, acao: String) -> bool:
	return not UiTema.sprite(_nome(i, acao)).is_empty()


func _anim_do_golpe(quem: int, e: Dictionary) -> String:
	var ma := str(e.get("move_anim", ""))
	if ma != "" and _existe_anim(quem, ma):
		return ma
	return str(e.attack_anim)


## Queda do K.O. pelo golpe que derrubou: golpe forte (crítico, contra-ataque, uppercut, direto) = lançado para trás; soco no
## estômago = queda para a frente (ajoelha e tomba); golpe normal (jab, gancho) = alterna entre a queda para a frente e a de
## sempre, de forma fixa para a mesma luta (pelo instante do golpe), para as lutas não acabarem sempre iguais.
func _queda_do_golpe(alvo: int, e: Dictionary) -> String:
	var anim := str(e.get("anim_usada", e.get("attack_anim", "")))
	var nome := "ko"
	if anim == "spin_kick" or str(e.get("finish", "")) == "spin_kick":
		nome = "fall_spin"  # 7b1: chute rodado final; sem a folha, a queda de sempre (volta para "ko" no fim da função)
	elif anim in ["uppercut", "heavy"] or str(e.get("kind", "")) in ["crit", "counter"]:
		nome = "ko_back"
	elif anim == "body_shot" or int(round(float(e.get("t", 0.0)) * 100.0)) % 2 == 0:
		nome = "ko_knees"
	if forcar_ko != "":
		nome = forcar_ko
	return nome if _existe_anim(alvo, nome) else "ko"


## Reação específica do golpe (queixo, cabeça, barriga) só quando o atacante FEZ esse golpe (o sprite dele existe); se ele caiu
## no jab/heavy de sempre, quem apanha também usa o `hit` de sempre (senão reagiria a um golpe que não viu).
func _reacao_do_golpe(alvo: int, e: Dictionary, anim_usada: String) -> String:
	var r := str(e.get("defender_move_anim", ""))
	if r != "" and anim_usada == str(e.get("move_anim", "")) and _existe_anim(alvo, r):
		return r
	return str(e.defender_anim)


# --- Ações dos lutadores ---

func _tocar(i: int, acao: String) -> void:
	var l: Dictionary = _l[i]
	if str(l.estado) == "ko":
		return
	var spr: AnimSprite = l.spr
	spr.definir(_nome(i, acao))
	spr.z_index = Z_ATACANTE if (acao in GameState.golpes.anims_de_ataque()) else _z_repouso(i)
	_ajustar_sombra(i)
	var frames := spr.hframes
	var seq: Array = []
	for q in frames:
		seq.append(q)
	var fps := float(UiTema.sprite(spr.nome_sprite).get("fps", 12.0))
	if acao == "ko":
		spr.tocar(seq, fps, false)
	elif acao in ["submission", "tap_out"] and _existe_anim(i, acao):
		l.estado = "preso"  # finalização: segura o último quadro, como o ko
		spr.tocar(seq, fps, false)
	else:
		spr.tocar(seq, fps, false, func() -> void: _repouso(i))


# Volta para a pose do estado atual: idle (respira), tired (cansado, com suor), guard (guarda no lugar),
# victory (comemora). `ko` fica no último quadro.
func _repouso(i: int) -> void:
	var l: Dictionary = _l[i]
	var spr: AnimSprite = l.spr
	spr.z_index = _z_repouso(i)
	match str(l.estado):
		"ko", "preso":
			return
		"victory":
			spr.definir(_nome(i, "victory"))
			spr.tocar([0, 1, 2, 3], float(UiTema.sprite(spr.nome_sprite).get("fps", 8.0)), true)
		"tired":
			spr.definir(_nome(i, "tired"))
			spr.tocar([0, 1, 2, 3], float(UiTema.sprite(spr.nome_sprite).get("fps", 6.0)), true)
		"guard":
			spr.definir(_nome(i, "block"))
			spr.parar(2)
		_:
			var pose := _idle_da_arte(i)
			if _fase_visual == "ground" and _pose_chao_ok():
				pose = "ground_top_idle" if i == 0 else "ground_bottom_idle"  # no chão o repouso é a pose de chão
			elif i == 0 and _cansado and _existe_anim(0, "tired"):
				pose = "tired"  # Boxe cansado no 3º round: a pose cansada entre os golpes
			spr.definir(_nome(i, pose))
			spr.tocar([0, 1, 2, 3], float(UiTema.sprite(spr.nome_sprite).get("fps", 6.0)), true)
	_ajustar_sombra(i)
	_atualizar_suor(i)


## Pose de repouso em pé. Muay Thai (7b1): o jogador fica na guarda tailandesa (mt_idle) e o adversário manca com 2 marcas
## (limp) ou 3 (limp_heavy; sem ela, limp). Sem a folha nova, o idle de sempre.
func _idle_da_arte(i: int) -> String:
	if _passiva != "shin":
		return "idle"
	if i == 0:
		return "mt_idle" if _existe_anim(0, "mt_idle") else "idle"
	var desde := int(luta.get("limp_from_marks", 2))
	if _marcas >= int(luta.get("marks_max", 3)) and _existe_anim(1, "limp_heavy"):
		return "limp_heavy"
	if _marcas >= desde and _existe_anim(1, "limp"):
		return "limp"
	return "idle"


## As folhas de chão existem para os dois lutadores? Sem elas a luta continua em pé (jab, esquiva e idle de sempre).
func _pose_chao_ok() -> bool:
	return _existe_anim(0, "ground_top_idle") and _existe_anim(1, "ground_bottom_idle")


## Ordem de desenho parado: em pé como sempre (z 318); no chão o jogador (montado) fica acima do adversário (z 319).
## Quem ataca continua por cima (z 320), inclusive o ground_punch do adversário.
func _z_repouso(i: int) -> int:
	return Z_LUTADOR + (1 if i == 0 and _fase_visual == "ground" and _pose_chao_ok() else 0)


func _estado(i: int, novo: String) -> void:
	_l[i].estado = novo
	_repouso(i)


func _ajustar_sombra(i: int) -> void:
	var l: Dictionary = _l[i]
	var base: Vector2 = l.base
	var desloc := 0.0
	if str(l.estado) == "ko":
		desloc = -12.0 * float(l.dir)  # o corpo deitado fica atrás
	l.sombra.position = base + Vector2(desloc, -1)


func _atualizar_suor(i: int) -> void:
	var l: Dictionary = _l[i]
	var suor: AnimSprite = l["suor"]
	var cansado := str(l.estado) == "tired" or (i == 0 and _cansado and str(l.estado) == "idle" and _fase_visual == "standing")
	suor.visible = cansado
	if cansado:
		var cab := _ponto_cabeca(i)
		suor.position = cab + Vector2(0, -4)
		suor.tocar([0, 1, 2, 3], 8.0, true)


# Cabeça (relativa ao pivô, lutador virado para a direita, escala 1) -> posição na arena.
func _ponto_cabeca(i: int) -> Vector2:
	var lay: Dictionary = UiTema.manifest().get("fight_layout", {})
	var h := _vetor(lay.get("head_point", [4, -80]))
	var l: Dictionary = _l[i]
	return (l.base as Vector2) + Vector2(h.x * float(l.dir), h.y) * float(l.escala)


func _acertou(e: Dictionary) -> void:
	var quem := int(e.who)
	var alvo := int(e.target)
	var tipo := str(e.kind)
	var forte := tipo == "crit" or tipo == "counter"
	_marcas = int(e.get("marks", _marcas))  # 7b1: antes da reação, para o repouso dele já mancar
	var bloqueado := bool(e.blocked)
	var spr_a := UiTema.sprite(_nome(quem, str(e.get("anim_usada", e.attack_anim))))
	var hp := _vetor(spr_a.get("hit_point", [31, -61]))
	var base_a: Vector2 = _l[quem].base
	var contato := base_a + hp

	# Reação de quem apanha (no K.O. sem grogue a queda assume; na finalização o tap_out é a reação).
	var ko := bool(e.ko)
	var finalizou := str(e.get("finish", "")) == "submission"
	if not ko or not luta.grogue.is_empty() or finalizou:
		_tocar(alvo, str(e.get("reacao_usada", e.defender_anim)))
		_flash_lutador(alvo)
	if bloqueado and not (str(e.get("phase", "standing")) == "ground" and _pose_chao_ok()):
		var sb := UiTema.sprite(_nome(alvo, "block"))
		var mao := _vetor((sb.get("hands", [{"hand_front": [10, -67]}]) as Array)[1].get("hand_front", [10, -67]))
		_tocar_fx("fx_block", (_l[alvo].base as Vector2) + mao, alvo == 1)
	else:
		_tocar_fx("fx_fight_hit", contato, quem == 1)
		if tipo == "crit":
			_tocar_fx("fx_fight_crit", contato, quem == 1)

	_hud_embalo(int(e.get("streak", 0)))
	if _passiva == "shin":
		_hud_marcas(int(e.get("marks", _marcas_acesas)))
	_fase_visual = str(e.get("phase_after", _fase_visual))  # a queda leva os dois ao chão (as poses de repouso mudam)

	# Número flutuante: sai do ponto de contato e sobe.
	_numero_de_dano(float(e.damage), tipo, bloqueado, Vector2(contato.x, contato.y - 6.0))

	# Barra de vida de quem apanhou.
	var pct := clampf(float(e.life_pct_after), 0.0, 1.0)
	_barras[alvo].definir(pct, true)
	_l[alvo].vida = pct

	# Barra de especial: o número já foi calculado antes da luta (o especial esvazia a barra com um estouro).
	if bool(e.get("especial", false)):
		_estourar_especial(contato)
	elif int(e.get("barra_apos", -1)) >= 0:
		_esp_definir(int(e.barra_apos))

	# Combo: golpes seguidos do jogador sem apanhar no meio (esquiva ou bloqueio do adversário quebram a sequência).
	if quem == 0 and not bloqueado:
		_combo += 1
		_mostrar_combo()
	elif quem == 1 and not bloqueado:
		_combo = 0

	# Som, tremida, flash, lâmpada e torcida: mais forte conforme o golpe.
	if bloqueado:
		sfx.bloqueio()
	sfx.golpe_luta(forte, bloqueado)
	if tipo == "crit":
		_tremer(2, 0.2)
		_flash_tela(0.32)
		_lampada.tocar([1, 0, 1, 0], 10.0)
		_publico_cheer(true)
		_congelar(0.07, 0.05)  # o impacto "pesa": os dois lutadores congelam um instante
	elif tipo == "counter":
		_tremer(1, 0.14)
		_flash_tela(0.2)
		_lampada.tocar([1, 0, 1, 0], 10.0)
		_publico_cheer(true)
		_congelar(0.06, 0.05)
	elif ko and not finalizou:
		_tremer(2, 0.2)
	if ko and not finalizou:
		_congelar(1.1, 0.3)  # K.O. em câmera lenta


## Congela (ou desacelera) o jogo por `duracao_real` segundos de relógio real. Vale o efeito mais recente.
func _congelar(duracao_real: float, escala: float) -> void:
	_congelar_id += 1
	var meu := _congelar_id
	Engine.time_scale = escala
	await get_tree().create_timer(duracao_real, true, false, true).timeout  # o último `true` ignora o time_scale
	if meu == _congelar_id:
		Engine.time_scale = 1.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _esp_definir(n: int) -> void:
	if _esp_cheio == null:
		return
	var alvo_w := roundf(108.0 * clampf(float(n) / float(GameState.lutas.golpes_especial), 0.0, 1.0))
	if _tween_esp != null and _tween_esp.is_valid():
		_tween_esp.kill()
	_esp_cheio.modulate = Color.WHITE
	_esp_cheio.color = UiTema.Y1 if n < GameState.lutas.golpes_especial - 1 else UiTema.Y2
	_tween_esp = create_tween()
	_tween_esp.tween_property(_esp_cheio, "size:x", alvo_w, 0.12)
	_esp_rotulo.text = ""


## Um golpe antes do especial: a barra enche inteira e pisca, o lutador brilha e aparece o aviso.
func _preparar_especial() -> void:
	if _esp_cheio == null:
		return
	if _tween_esp != null and _tween_esp.is_valid():
		_tween_esp.kill()
	_esp_cheio.size.x = 108.0
	_esp_cheio.color = UiTema.Y2
	_esp_rotulo.text = UiTema.txt("fight_special", "SUPER!").to_upper()
	_tween_esp = create_tween().set_loops()
	_tween_esp.tween_property(_esp_cheio, "modulate", Color(2, 2, 2), 0.1)
	_tween_esp.tween_property(_esp_cheio, "modulate", Color.WHITE, 0.1)
	var spr: AnimSprite = _l[0].spr
	spr.modulate = Color(1.7, 1.45, 0.6)
	spr.create_tween().tween_property(spr, "modulate", Color.WHITE, 0.6)
	if _passiva == "submission":
		_texto_banner(UiTema.txt("fight_special_banner_bjj", "SUPER PEGADA!"), UiTema.Y2, 2)
	elif _passiva == "shin":
		_texto_banner(UiTema.txt("fight_special_banner_muay_thai", "SUPER CHUTE RODADO!"), UiTema.BR3, 2)
	else:
		_texto_banner(UiTema.txt("fight_special_banner", "SUPER UPPERCUT!"), UiTema.Y2, 2)
	sfx.publico()
	_publico_cheer(false)


func _estourar_especial(contato: Vector2) -> void:
	_tocar_fx("fx_fight_crit", contato, false)
	_tocar_fx("fx_fight_crit", contato + Vector2(0, -8), false)
	_tremer(4, 0.32)
	_flash_tela(0.7)
	_lampada.tocar([1, 0, 1, 0, 1, 0], 12.0)
	_publico_cheer(true)
	_congelar(0.14, 0.04)
	_esp_definir(0)


func _mostrar_combo() -> void:
	if _combo < 2 or _rotulo_combo == null:
		return
	_rotulo_combo.text = UiTema.txt("fight_combo", "COMBO X{n}", {"n": _combo}).to_upper()
	_rotulo_combo.modulate.a = 1.0
	if _tween_combo != null and _tween_combo.is_valid():
		_tween_combo.kill()
	_tween_combo = create_tween()
	_tween_combo.tween_interval(1.2)
	_tween_combo.tween_property(_rotulo_combo, "modulate:a", 0.0, 0.3)


## Número de dano que sobe do ponto de contato. O mais recente fica por cima e os que estavam embaixo dele são
## empurrados para cima (a mesma solução da garagem), para dois golpes seguidos no mesmo ponto não se encavalarem.
func _numero_de_dano(dano: float, tipo: String, bloqueado: bool, origem: Vector2) -> void:
	var forte := tipo == "crit" or tipo == "counter"
	var n := _pegar_numero()
	_ordem_numeros += 1
	n.definir_z(900 + (50 if forte else 0) + _ordem_numeros % 40)
	if tipo == "crit":
		n.iniciar(UiTema.txt("fight_crit", "{n}!", {"n": NumberFormat.fmt(dano)}), UiTema.R3, true, "", origem + Vector2(0, -6), 0.8, 24.0)
	elif tipo == "counter":
		n.iniciar(UiTema.txt("fight_crit", "{n}!", {"n": NumberFormat.fmt(dano)}), UiTema.B3, true, "", origem + Vector2(0, -6), 0.8, 24.0)
	else:
		n.iniciar(NumberFormat.fmt(dano), UiTema.G3 if bloqueado else UiTema.Y1, false, "", origem, 0.6, 20.0)
	Sala.afastar(_numeros, n, true)  # na arena o recém-chegado empurra todos (crítico ou não)


func _esquivou(e: Dictionary) -> void:
	var alvo := int(e.target)
	if int(e.who) == 0:
		_combo = 0  # o soco do jogador foi esquivado: acaba o combo
	_hud_embalo(int(e.get("streak", 0)))
	if str(e.get("phase", "standing")) == "ground" and _pose_chao_ok():
		var baixo := (_l[alvo].base as Vector2) + Vector2(0, -26)
		var ng := _pegar_numero()
		_ordem_numeros += 1
		ng.definir_z(930 + _ordem_numeros % 40)
		ng.iniciar(UiTema.txt("fight_dodge", "ESQUIVOU"), UiTema.CREAM, false, "", baixo, 0.7, 14.0)
		Sala.afastar(_numeros, ng, true)
		sfx.esquiva()
		return
	var cab := _ponto_cabeca(alvo)
	# Vento do soco que passou (desenhado para o soco do adversário; espelha quando é o adversário que esquiva).
	_tocar_fx("fx_whoosh", cab + Vector2(-8.0 * float(_l[alvo].dir), 6.0), alvo == 1)
	var n := _pegar_numero()
	_ordem_numeros += 1
	n.definir_z(930 + _ordem_numeros % 40)
	n.iniciar(UiTema.txt("fight_dodge", "ESQUIVOU"), UiTema.CREAM, false, "", cab + Vector2(0, -8), 0.7, 14.0)
	Sala.afastar(_numeros, n, true)
	sfx.esquiva()


func _cair(i: int) -> void:
	var l: Dictionary = _l[i]
	l.estado = "ko"
	var spr: AnimSprite = l.spr
	spr.definir(_nome(i, _ko_nome))
	spr.z_index = Z_LUTADOR
	var fps := float(UiTema.sprite(spr.nome_sprite).get("fps", 10.0))
	var seq: Array = []
	for q in spr.hframes:
		seq.append(q)
	spr.tocar(seq, fps, false)
	_ajustar_sombra(i)
	l["suor"].visible = false


# Quadro 3 do ko = o corpo bate no chão: poeira, tremida, letreiro K.O., estrelinhas e torcida.
func _chao(i: int) -> void:
	var l: Dictionary = _l[i]
	var frente := _ko_nome == "ko_knees"  # tomba para a frente: poeira e estrelas do outro lado
	_tocar_fx("fx_dust_fall", (l.base as Vector2) + Vector2((14.0 if frente else -14.0) * float(l.dir), 0), i == 1)
	_tremer(2, 0.3)
	_flash_tela(0.4)
	sfx.queda()
	sfx.publico(-10.0)
	_lampada.tocar([1, 0, 1, 0], 8.0)
	_publico_cheer(true)
	_banner_ko_mostrar(str(luta.result.get("finish", "")) == "spin_kick")
	var est: AnimSprite = l["estrelas"]
	var ko_cab := _vetor(UiTema.manifest().get("fight_layout", {}).get("ko_head_point", [-36, -12]))
	if frente:
		ko_cab = Vector2(38, -12)
	elif _ko_nome == "ko_back":
		ko_cab = Vector2(-42, -12)
	est.position = (l.base as Vector2) + Vector2(ko_cab.x * float(l.dir), ko_cab.y) * float(l.escala)
	est.visible = true
	est.tocar([0, 1, 2, 3, 4, 5], 10.0, true)


## O letreiro do fim: K.O.! (ou CHUTE RODADO! quando o chute rodado derrubou: o mesmo pop e a mesma tremida).
func _banner_ko_mostrar(rodado: bool = false) -> void:
	var b := _banner_spin if rodado and not UiTema.sprite("ui_banner_spin_kick").is_empty() else _banner_ko
	b.visible = true
	b.scale = Vector2(3, 3)
	b.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(b, "modulate:a", 1.0, 0.08)
	tw.tween_callback(func() -> void: b.scale = Vector2(2, 2)).set_delay(0.09)
	_tremer(2, 0.3)


# --- Efeitos ---

func _tocar_fx(nome: String, p: Vector2, espelhar: bool) -> void:
	var lista: Array = _fx[nome]
	var i: int = int(_fx_i[nome])
	_fx_i[nome] = (i + 1) % lista.size()
	var a: AnimSprite = lista[i]
	a.definir(nome)
	a.flip_h = espelhar
	var s := UiTema.sprite(nome)
	var fw := float((s.get("frame_size", [32, 32]) as Array)[0])
	var pv := UiTema.pivo(nome)
	a.offset.x = -(fw - pv.x) if espelhar else -pv.x
	a.position = p
	a.visible = true
	var seq: Array = []
	for q in a.hframes:
		seq.append(q)
	a.tocar(seq, float(s.get("fps", 15.0)), false, func() -> void: a.visible = false)


func _pegar_numero() -> Sala.Numero:
	var melhor: Sala.Numero = _numeros[0]
	for n in _numeros:
		if not n.ativo:
			return n
		if n.progresso() > melhor.progresso():
			melhor = n
	return melhor


func _tremer(amp: int, dur: float) -> void:
	if _shake_t <= 0.0 or amp >= _shake_amp:
		_shake_amp = amp
		_shake_dur = dur
		_shake_t = dur


func _flash_tela(forca: float) -> void:
	_flash.color = Color(1, 1, 1, forca)
	create_tween().tween_property(_flash, "color:a", 0.0, 0.14)


func _flash_lutador(i: int) -> void:
	var spr: AnimSprite = _l[i].spr
	spr.modulate = Color(2.2, 2.2, 2.2)
	spr.create_tween().tween_property(spr, "modulate", Color.WHITE, 0.14)


func _publico_cheer(com_som: bool) -> void:
	_publico_tras.tocar([1, 0, 1, 0, 1, 0], 9.0, false, func() -> void: _publico_tras.tocar([0, 1], 2.0, true))
	_publico_frente.tocar([1, 0, 1, 0, 1, 0], 9.0, false, func() -> void: _publico_frente.tocar([0, 1], 2.0, true))
	if com_som and _clock - _ultimo_publico > 1.2:
		_ultimo_publico = _clock
		sfx.publico()


# Letreiros centrais (escala inteira; o "pop" é 1 tamanho acima por 2 quadros).
func _texto_banner(texto: String, cor: Color, escala: int) -> void:
	_banner.visible = true
	_banner.text = texto
	_banner.add_theme_color_override("font_color", cor)
	_posicionar_banner(escala + 1, 146.0 - escala * 4)
	_fundo_banner(texto, escala)
	var tw := create_tween()
	tw.tween_callback(func() -> void: _posicionar_banner(escala, 148.0 - escala * 3)).set_delay(0.07)


# Letreiro na escala dada: ocupa a largura da tela (em unidades do próprio rótulo) e se centraliza sozinho.
func _posicionar_banner(escala: int, y: float) -> void:
	_banner.scale = Vector2(escala, escala)
	_banner.size = Vector2(TELA.x / escala, 12.0)
	_banner.position = Vector2(UiTema.folga_centro(escala), y)


# Faixa escura atrás do letreiro (abaixo da placa da arena, nunca sobre ela).
func _fundo_banner(texto: String, escala: int) -> void:
	var w := roundf(UiTema.largura(texto) * escala) + 24.0
	var h := 8.0 * escala + 10.0
	_banner_fundo.size = Vector2(w, h)
	_banner_fundo.position = Vector2(roundf(320.0 - w / 2.0), 148.0 - escala * 3 - 5.0)
	_banner_fundo.visible = true


func _texto_sub(texto: String, cor: Color) -> void:
	_banner_sub.visible = true
	_banner_sub.text = texto
	_banner_sub.add_theme_color_override("font_color", cor)
	_banner_sub.position = Vector2(0.0, 178.0)  # o rótulo ocupa a largura toda e centraliza o texto


func _esconder_banner() -> void:
	_banner.visible = false
	_banner_fundo.visible = false


# --- Relógio e laço ---

func _atualizar_relogio(t: float) -> void:
	var limite := float(GameState.lutas.combate.time_limit)
	var tt := clampf(t if _t_parada < 0.0 else minf(t, _t_parada), 0.0, limite)
	var resta := int(ceil(limite - tt))
	_rotulo_tempo.text = "%d:%02d" % [resta / 60, resta % 60]
	var rd := mini(3, int(floor(tt / float(GameState.lutas.combate.round_length))) + 1)
	_rotulo_round.text = UiTema.txt("fight_round", "{n}º ROUND", {"n": rd})  # os rótulos se centralizam sozinhos


func tempo() -> float:
	return _clock


func _process(delta: float) -> void:
	if not ativa:
		return
	if _l.size() > 0 and _l[0].get("spr", null) != null:
		UiTema.aplicar_visual_disc(_l[0].spr)  # Fase 6b1: o visual escolhido do discípulo
	_t += delta
	_clock += delta
	while _idx < _cues.size() and float(_cues[_idx].t) <= _clock:
		var fn: Callable = _cues[_idx].fn
		_idx += 1
		fn.call()
	_atualizar_relogio(maxf(_clock, 0.0))
	_atualizar_pegada()

	if _shake_t > 0.0:
		_shake_t -= delta
		var amp := 0
		if _shake_t > 0.0:
			amp = int(ceil(float(_shake_amp) * _shake_t / _shake_dur))
		_mundo.position = Vector2(_rng.randi_range(-amp, amp), _rng.randi_range(-amp, amp)) if amp > 0 else Vector2.ZERO
	elif _mundo.position != Vector2.ZERO:
		_mundo.position = Vector2.ZERO

	# Os números novos sobem mais rápido que os velhos e alcançariam quem está acima: confere todo quadro (barato).
	var recente: Sala.Numero = null
	for n in _numeros:
		if n.ativo:
			n.passo(delta)
			if n.ativo and (recente == null or n.progresso() < recente.progresso()):
				recente = n
	if recente != null:
		Sala.afastar(_numeros, recente, true)
	for b in _barras:
		b.passo(_t)

	if _clock >= _fim_total and not finalizada:
		_finalizar()


## Barra de pegada (Jiu-jitsu): enche com o tempo da luta até grip_full_at; cheia, pisca entre os dois quadros.
func _atualizar_pegada() -> void:
	if _grip_fill == null:
		return
	var tt := maxf(_clock, 0.0)
	if _t_parada >= 0.0:
		tt = minf(tt, _t_parada)
	var cheia := float(luta.get("grip_full_at", -1.0))
	var f := clampf(tt / cheia, 0.0, 1.0) if cheia > 0.0 else 0.0
	var w := roundf(_grip_larg * f)
	_grip_fill.visible = w >= 1.0
	_grip_fill.size.x = maxf(w, 1.0)
	if f >= 1.0 and _grip_cheia:
		CartaoPassiva.definir_enchimento(_grip_fill, int(_t * 6.0) % 2)


func _finalizar() -> void:
	finalizada = true
	ativa = false
	var resumo := GameState.concluir_luta()  # aplica o resultado UMA vez e salva
	terminou.emit(resumo)


## Esconde a arena e libera os recursos (chamado pelo Fluxo ao voltar para a garagem).
func encerrar() -> void:
	_gesto.cancelar()
	_gesto_nome = ""
	Engine.time_scale = 1.0
	ativa = false
	visible = false
	for c in get_children():
		if c != sfx and c != _gesto:
			c.queue_free()


# --- Barra de vida: moldura + rastro (mostra o tamanho do golpe) + preenchimento ---

class Barra extends RefCounted:
	var dono: Node
	var lado := 0  # 0 = enche da esquerda (jogador); 1 = da direita (adversário)
	var x := 0.0
	var largura := 232.0
	var pct := 1.0
	var _fill: NinePatchRect
	var _trail: NinePatchRect
	var _tw_fill: Tween
	var _tw_trail: Tween
	var _w_fill := 232.0
	var _w_trail := 232.0
	var _baixa := false

	func _init(dono_: Node, pai: Control, r: Rect2, lado_: int) -> void:
		dono = dono_
		lado = lado_
		x = r.position.x + 2.0
		largura = r.size.x - 4.0
		UiTema.nine_patch(pai, "ui_hp_frame", r)
		_trail = UiTema.nine_patch(pai, "ui_hp_trail", Rect2(x, r.position.y + 2, largura, 8))
		_fill = UiTema.nine_patch(pai, "ui_hp_fill", Rect2(x, r.position.y + 2, largura, 8))
		_w_fill = largura
		_w_trail = largura

	func _aplicar(no: NinePatchRect, w: float) -> void:
		no.visible = w >= 2.0
		no.size.x = maxf(w, 2.0)
		no.position.x = x if lado == 0 else x + largura - no.size.x

	func definir(p: float, animar: bool) -> void:
		pct = clampf(p, 0.0, 1.0)
		var alvo := roundf(largura * pct)
		if not animar:
			_w_fill = alvo
			_w_trail = alvo
			_aplicar(_fill, alvo)
			_aplicar(_trail, alvo)
			return
		if _tw_fill != null and _tw_fill.is_valid():
			_tw_fill.kill()
		if _tw_trail != null and _tw_trail.is_valid():
			_tw_trail.kill()
		_tw_fill = dono.create_tween()
		_tw_fill.tween_method(func(w: float) -> void:
			_w_fill = w
			_aplicar(_fill, roundf(w)), _w_fill, alvo, 0.12)
		# O rastro fica 0.4 s onde estava e depois encolhe.
		_tw_trail = dono.create_tween()
		_tw_trail.tween_interval(0.4)
		_tw_trail.tween_method(func(w: float) -> void:
			_w_trail = w
			_aplicar(_trail, roundf(w)), _w_trail, alvo, 0.3)
		var baixa := pct <= 0.25
		if baixa != _baixa:
			_baixa = baixa
			_fill.texture = UiTema.textura("ui_hp_fill_low" if baixa else "ui_hp_fill")

	# Vida baixa (<= 25%) pisca.
	func passo(t: float) -> void:
		if _baixa:
			_fill.modulate.a = 1.0 if int(t * 6.0) % 2 == 0 else 0.55
		else:
			_fill.modulate.a = 1.0
