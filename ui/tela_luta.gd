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
var _tween_combo: Tween
var _congelar_id := 0
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


func _ready() -> void:
	position = Vector2.ZERO
	size = TELA
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_rng.randomize()
	sfx = Sfx.new()
	add_child(sfx)
	visible = false


# --- Montagem (depende do adversário e da luva equipada) ---

func _montar(opp_id: String) -> void:
	for c in get_children():
		if c != sfx:
			c.queue_free()
	_l.clear()
	_fx.clear()
	_fx_i.clear()
	_numeros.clear()
	_barras.clear()
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

	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = UiTema.textura("arena_bg")
	bg.z_index = -100
	_mundo.add_child(bg)
	_lampada = _anim("arena_lamp", UiTema.pos("arena_lamp"), -50)
	_publico_tras = _anim("arena_crowd_back", UiTema.pos("arena_crowd_back"), -60)
	_publico_tras.tocar([0, 1], 2.0, true)
	_publico_frente = _anim("arena_crowd_front", UiTema.pos("arena_crowd_front"), 50)
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
	# Letreiros: o Label ocupa a largura da tela e centraliza o texto (ver `_posicionar_banner`).
	_banner = UiTema.rotulo(self, "", UiTema.Y2, 0, 100, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	_banner.visible = false
	UiTema.alinhar(_banner, "center_h")
	_banner_sub = UiTema.rotulo(self, "", UiTema.WHITE, 0, 140, 0, HORIZONTAL_ALIGNMENT_CENTER, false, true)
	_banner_sub.size = Vector2(TELA.x, 12.0)
	_banner_sub.visible = false
	UiTema.alinhar(_banner_sub, "center_h")


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
	_l_definir(l, i, "idle")
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
	UiTema.textura_rect(quadro_j, "portrait_player", 2, 2)  # o retrato fica dentro da moldura
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
	_rotulo_combo.modulate.a = 0.0

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

	var eventos: Array = luta.events
	for e in eventos:
		_agendar_evento(e)

	# O motivo da derrota NÃO é lido aqui: o GameState o calcula em segundo plano e a tela de fim o lê ao abrir.

	var perdedor := int(luta.loser)
	var grogue: Dictionary = luta.grogue
	var t_end := float(res.t_end)
	if bool(res.ko) and perdedor >= 0:
		var vencedor := 1 - perdedor
		var t_ko := float(res.t_ko)
		if not grogue.is_empty():
			_cue(float(grogue.from) + 0.3, func() -> void: _estado(perdedor, "tired"))
			_cue(float(grogue.from) + 0.25, func() -> void: _estado(vencedor, "guard"))
			_cue(float(grogue.to), func() -> void: _cair(perdedor))
		else:
			_cue(t_ko + 0.06, func() -> void: _cair(perdedor))
		var t_queda := (float(grogue.to) if not grogue.is_empty() else t_ko + 0.06)
		var fps_ko := float(UiTema.sprite(_nome(perdedor, "ko")).get("fps", 10.0))
		_cue(t_queda + 3.0 / fps_ko, func() -> void: _chao(perdedor))
		_cue(t_queda + 3.0 / fps_ko + 0.5, func() -> void: _estado(vencedor, "victory"))
		_cue(t_queda + 3.0 / fps_ko + 0.45, func() -> void:
			if bool(res.win):
				sfx.vitoria()
			else:
				sfx.derrota())
		_cue(t_queda + 3.0 / fps_ko + 0.2, func() -> void: sfx.sino_fim())
		_t_parada = t_ko
	else:
		# Fim por pontos: "TEMPO!", sino, o vencedor comemora e o outro cansa.
		var vencedor := 0 if bool(res.win) else 1
		_cue(t_end, func() -> void:
			sfx.sino_fim()
			_texto_banner(UiTema.txt("fight_time", "TEMPO!"), UiTema.Y2, 2))
		_cue(t_end + 0.35, func() -> void:
			_estado(vencedor, "victory")
			_estado(1 - vencedor, "tired")
			_texto_sub(UiTema.txt("fight_points", "POR PONTOS"), UiTema.CREAM)
			sfx.publico()
			_publico_cheer(false)
			if bool(res.win):
				sfx.vitoria()
			else:
				sfx.derrota())
		_t_parada = t_end


func _cue(t: float, fn: Callable) -> void:
	_cues.append({"t": t, "seq": _cues.size(), "fn": fn})
	_cues.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.t < b.t or (a.t == b.t and a.seq < b.seq))


func _agendar_evento(e: Dictionary) -> void:
	var quem := int(e.who)
	var alvo := int(e.target)
	var t := float(e.t)
	# Golpe da luta (data/moves.json): usa o sprite do golpe se ele existir; senão, o jab/heavy de sempre.
	var anim := _anim_do_golpe(quem, e)
	e["anim_usada"] = anim
	e["reacao_usada"] = _reacao_do_golpe(alvo, e, anim)
	var s := UiTema.sprite(_nome(quem, anim))
	var antes := float(int(s.get("hit_frame", 1))) / maxf(float(s.get("fps", 12.0)), 1.0)
	# O golpe sai `hit_frame / fps` antes: o contato cai exatamente em `t`.
	_cue(t - antes, func() -> void: _tocar(quem, anim))
	if str(e.kind) == "dodge" or str(e.type) == "dodge":
		var sd := UiTema.sprite(_nome(alvo, "dodge"))
		var um_quadro := 1.0 / maxf(float(sd.get("fps", 14.0)), 1.0)
		_cue(t - um_quadro, func() -> void: _tocar(alvo, "dodge"))
		_cue(t, func() -> void: _esquivou(e))
	else:
		_cue(t, func() -> void: _acertou(e))


# --- Golpes: sprite do golpe escolhido, com volta ao jab/heavy (e ao `hit`) quando a arte ainda não existe ---

func _existe_anim(i: int, acao: String) -> bool:
	return not UiTema.sprite(_nome(i, acao)).is_empty()


func _anim_do_golpe(quem: int, e: Dictionary) -> String:
	var ma := str(e.get("move_anim", ""))
	if ma != "" and _existe_anim(quem, ma):
		return ma
	return str(e.attack_anim)


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
	spr.z_index = Z_ATACANTE if (acao in GameState.golpes.anims_de_ataque()) else Z_LUTADOR
	_ajustar_sombra(i)
	var frames := spr.hframes
	var seq: Array = []
	for q in frames:
		seq.append(q)
	var fps := float(UiTema.sprite(spr.nome_sprite).get("fps", 12.0))
	if acao == "ko":
		spr.tocar(seq, fps, false)
	else:
		spr.tocar(seq, fps, false, func() -> void: _repouso(i))


# Volta para a pose do estado atual: idle (respira), tired (cansado, com suor), guard (guarda no lugar),
# victory (comemora). `ko` fica no último quadro.
func _repouso(i: int) -> void:
	var l: Dictionary = _l[i]
	var spr: AnimSprite = l.spr
	spr.z_index = Z_LUTADOR
	match str(l.estado):
		"ko":
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
			spr.definir(_nome(i, "idle"))
			spr.tocar([0, 1, 2, 3], float(UiTema.sprite(spr.nome_sprite).get("fps", 6.0)), true)
	_ajustar_sombra(i)
	_atualizar_suor(i)


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
	var cansado := str(l.estado) == "tired"
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
	var bloqueado := bool(e.blocked)
	var spr_a := UiTema.sprite(_nome(quem, str(e.get("anim_usada", e.attack_anim))))
	var hp := _vetor(spr_a.get("hit_point", [31, -61]))
	var base_a: Vector2 = _l[quem].base
	var contato := base_a + hp

	# Reação de quem apanha (no K.O. sem grogue a queda assume).
	var ko := bool(e.ko)
	if not ko or not luta.grogue.is_empty():
		_tocar(alvo, str(e.get("reacao_usada", e.defender_anim)))
		_flash_lutador(alvo)
	if bloqueado:
		var sb := UiTema.sprite(_nome(alvo, "block"))
		var mao := _vetor((sb.get("hands", [{"hand_front": [10, -67]}]) as Array)[1].get("hand_front", [10, -67]))
		_tocar_fx("fx_block", (_l[alvo].base as Vector2) + mao, alvo == 1)
	else:
		_tocar_fx("fx_fight_hit", contato, quem == 1)
		if tipo == "crit":
			_tocar_fx("fx_fight_crit", contato, quem == 1)

	# Número flutuante: sai do ponto de contato e sobe.
	_numero_de_dano(float(e.damage), tipo, bloqueado, Vector2(contato.x, contato.y - 6.0))

	# Barra de vida de quem apanhou.
	var pct := clampf(float(e.life_pct_after), 0.0, 1.0)
	_barras[alvo].definir(pct, true)
	_l[alvo].vida = pct

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
	elif ko:
		_tremer(2, 0.2)
	if ko:
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
	spr.definir(_nome(i, "ko"))
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
	_tocar_fx("fx_dust_fall", (l.base as Vector2) + Vector2(-14.0 * float(l.dir), 0), i == 1)
	_tremer(2, 0.3)
	_flash_tela(0.4)
	sfx.queda()
	sfx.publico(-10.0)
	_lampada.tocar([1, 0, 1, 0], 8.0)
	_publico_cheer(true)
	_banner_ko_mostrar()
	var est: AnimSprite = l["estrelas"]
	var ko_cab := _vetor(UiTema.manifest().get("fight_layout", {}).get("ko_head_point", [-36, -12]))
	est.position = (l.base as Vector2) + Vector2(ko_cab.x * float(l.dir), ko_cab.y) * float(l.escala)
	est.visible = true
	est.tocar([0, 1, 2, 3, 4, 5], 10.0, true)


func _banner_ko_mostrar() -> void:
	_banner_ko.visible = true
	_banner_ko.scale = Vector2(3, 3)
	_banner_ko.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_banner_ko, "modulate:a", 1.0, 0.08)
	tw.tween_callback(func() -> void: _banner_ko.scale = Vector2(2, 2)).set_delay(0.09)
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
	_t += delta
	_clock += delta
	while _idx < _cues.size() and float(_cues[_idx].t) <= _clock:
		var fn: Callable = _cues[_idx].fn
		_idx += 1
		fn.call()
	_atualizar_relogio(maxf(_clock, 0.0))

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


func _finalizar() -> void:
	finalizada = true
	ativa = false
	var resumo := GameState.concluir_luta()  # aplica o resultado UMA vez e salva
	terminou.emit(resumo)


## Esconde a arena e libera os recursos (chamado pelo Fluxo ao voltar para a garagem).
func encerrar() -> void:
	Engine.time_scale = 1.0
	ativa = false
	visible = false
	for c in get_children():
		if c != sfx:
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
