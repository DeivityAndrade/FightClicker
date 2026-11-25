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
# Fase 7b2: 2ª passiva. Contragolpista: 3 losangos de carga; Por cima: sinal "NO CHÃO"/"EM PÉ"; Clinch: sinal aceso enquanto preso.
var _area_letreiro := Rect2()  # área do letreiro de fim na tela (vazia = sem letreiro): nada flutua nela enquanto ele está lá
var _cargas_hud: Array = []
var _carga_atual := 0
var _carga_cheia := false
var _tween_carga: Tween
var _letreiro_carga: TextureRect  # CARGA! (opcional), abaixo da fileira da tática
var _banners_fim: Dictionary = {}  # finish (counter_ko | ground_stop | knee_ko) -> letreiro do fim (Sprite2D)
var _sinais: Dictionary = {}  # stood_up | clinch -> sinal pequeno (Sprite2D) que sobe da cabeça dele
var _sinal_icone: TextureRect  # Por cima / Clinch: ícone do sinal fixo do HUD
var _sinal_rotulo: Label
var _sinal_textos: Array = []  # [apagado, aceso]
var _sinal_aceso := false
var _cansado := false
var _rot_cansado: Control
var _grip_fill: TextureRect
var _grip_larg := 0.0
var _grip_cheia := false
var _fase_visual := "standing"  # "standing" | "ground" (as animações de chão só entram se as folhas existirem)
var _banner_sub_img: Sprite2D
var _bloqueio_ate := -10.0  # fim da queda (takedown + fall) em andamento: o próximo golpe espera
# Fase 8a1: passiva DELE (ícone ao lado da vida, sinais AGUENTOU!/NÃO CAIU/ESCAPOU!/GUARDA FECHADA/A GUARDA ABRIU, guarda do Blindado),
# entrada no ringue da arena regional, apresentação do James e fala de depois (balão), cinturão erguido. Tudo só visual.
const ZSINAL_OPP := 1500  # dentro do mundo: acima dos números de dano (até ~1100) e abaixo dos letreiros de fim (3000)
const PULAR_BOTAO := Rect2(570, 334, 62, 18)
const ESPERA_ENTRE_FALAS := 0.3
const ZONA_CABECA_JOGADOR := Rect2(282, 222, 36, 38)  # o balão nunca cobre a cabeça do jogador
const ZONA_CORPO_JOGADOR := Rect2(262, 226, 70, 96)  # nem o corpo dele (fala de depois com o James no chão)
var _opp_pass: Dictionary = {}  # luta.opp_passive ({} = sem passiva)
var _opp_icone: TextureRect
var _opp_sinais: Dictionary = {}  # block | closed | open -> Sprite2D
var _tween_sinais: Dictionary = {}
var _guarda_fechada := false  # James no 1º round: pose guard no lugar do idle
var _streak_ant := 0
var _balao: Balao
var _pre := ""  # "" | "entrada" | "falas"  (o relógio da luta fica parado em -intro_seconds enquanto dura)
var _pre_t := 0.0
var _gesto_pendente := false
var _ap_falas: Array = []  # [{id, speaker, text}] (apresentação do James antes; fala de depois no fim)
var _ap_i := 0
var _ap_espera := -1.0
var _ap_tipo := ""  # "intro" | "outro"
var _ap_t_completo := -10.0
var _scorn_em := -1.0
var _scorn_feito := false
var _ap_scorn_palavra := ""
var _outro := 0  # fala de depois do James: 0 = não começou, 1 = tocando, 2 = feita (ou não há)
var _botao_pular: Button
var _chip_pular: Label
var _anel_pular: TextureRect
var _atlas_pular: AtlasTexture
var _esc_t := 0.0
var _esc_segurando := false
var _ropes_side: Sprite2D
var _facho: AnimSprite
var _cinturao: AnimSprite
var _cinturao_ativo := false


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
	_balao = Balao.new()
	_balao.name = "Balao"
	_balao.modo_cena = true
	add_child(_balao)
	_balao.fechou.connect(_ao_balao_fechou)
	_balao.falando.connect(func(_q: String, sim: bool) -> void:
		if not sim:
			_ap_t_completo = float(Time.get_ticks_msec()) / 1000.0)
	GameState.gesto_cancelado.connect(_ao_gesto_cancelado)


# --- Montagem (depende do adversário e da luva equipada) ---

func _montar(opp_id: String) -> void:
	for c in get_children():
		if c != sfx and c != _gesto and c != _balao:
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
	_cargas_hud.clear()
	_carga_atual = 0
	_carga_cheia = false
	_letreiro_carga = null
	_banners_fim.clear()
	_sinais.clear()
	_sinal_icone = null
	_sinal_rotulo = null
	_sinal_aceso = false
	_area_letreiro = Rect2()
	_cansado = false
	_rot_cansado = null
	_grip_fill = null
	_grip_cheia = false
	_fase_visual = "standing"
	_bloqueio_ate = -10.0
	_passiva = str(luta.get("passive", ""))
	_opp_id = opp_id
	_balao.fechar_agora(false)
	_opp_pass = luta.get("opp_passive", {}) if luta.get("opp_passive", {}) is Dictionary else {}
	_opp_icone = null
	_opp_sinais.clear()
	_tween_sinais.clear()
	_guarda_fechada = str(_opp_pass.get("id", "")) == "adv_blindado"
	_streak_ant = 0
	_pre = ""
	_pre_t = 0.0
	_gesto_pendente = false
	_ap_falas = []
	_ap_i = 0
	_ap_espera = -1.0
	_ap_tipo = ""
	_scorn_em = -1.0
	_outro = 0
	_botao_pular = null
	_chip_pular = null
	_ropes_side = null
	_facho = null
	_cinturao = null
	_cinturao_ativo = false
	_esc_t = 0.0
	_esc_segurando = false
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
	UiTema.alinhar_motivo(_mundo, "ignore", "arena, lutadores, efeitos e números flutuantes: posição livre de propósito")
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
	# 8a1: camadas opcionais da arena regional: as cordas laterais por cima dos lutadores e o facho da entrada no ringue.
	var nome_cordas := pre + "_ropes_side"
	if not UiTema.sprite(nome_cordas).is_empty():
		_ropes_side = Sprite2D.new()
		_ropes_side.centered = false
		_ropes_side.texture = UiTema.textura(nome_cordas)
		_ropes_side.position = UiTema.pos(nome_cordas)
		_ropes_side.z_index = 330  # acima dos lutadores (318/320) e abaixo dos efeitos (400); 0 px no meio, então só vale na entrada
		_ropes_side.set_meta("ui_align", "ignore")
		_mundo.add_child(_ropes_side)
	var nome_facho := pre + "_spot"
	if not UiTema.sprite(nome_facho).is_empty():
		_facho = _anim(nome_facho, Vector2.ZERO, -55)
		_facho.visible = false

	var pos_j := _vetor(lay.get("player_pos", [296, 318]))
	var pos_o := _vetor(lay.get("opponent_pos", [346, 318]))
	_l.append(_novo_lutador(0, pos_j, 1.0))
	_l.append(_novo_lutador(1, pos_o, _escala_opp))

	for nome in ["fx_fight_hit", "fx_fight_crit", "fx_whoosh", "fx_block", "fx_dust_fall", "fx_guard_clink"]:
		if UiTema.sprite(nome).is_empty():
			continue
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

	_montar_letreiros_2()
	_montar_sinais_adversario()
	_montar_cinturao_erguido(opp_id)

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
	_montar_pular()


## Camada do cenário com o prefixo da arena; se faltar no manifest, a da borracharia.
func _camada(pre: String, camada: String) -> String:
	var nome := "%s_%s" % [pre, camada]
	return nome if not UiTema.sprite(nome).is_empty() else "arena_" + camada


func _vetor(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


## 7b2: os 3 letreiros do fim (K.O. NO CONTRAGOLPE! / O JUIZ PAROU! / JOELHADA!, 2x no meio da arena) e os sinais pequenos
## (LEVANTOU, CLINCH!). z 1000 dentro do mundo: acima dos números de dano (que vão até 100 + 989), como o fix B2 da 7b1.
## B1 (QA 7b2): 1000 ainda ficava atrás dos números de dano (o verificador provou com um sentinela); 3000 fica acima de tudo da luta.
const ZLETREIRO := 3000


func _montar_letreiros_2() -> void:
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("passive_2_banners", {})
	var pos: Array = info.get("banner_pos", [320, 118])
	for finish in ["counter_ko", "ground_stop", "knee_ko"]:
		var nome := str(info.get(finish, ""))
		if nome == "" or UiTema.sprite(nome).is_empty():
			continue
		var b := Sprite2D.new()
		b.texture = UiTema.textura(nome)
		b.position = Vector2(float(pos[0]), float(pos[1]))
		b.scale = Vector2(2, 2)
		b.z_index = ZLETREIRO
		b.visible = false
		b.set_meta("ui_align", "ignore")
		_mundo.add_child(b)
		_banners_fim[finish] = b
	var pequenos: Dictionary = info.get("small", {})
	for chave in ["stood_up", "clinch"]:
		var nome2 := str(pequenos.get(chave, ""))
		if nome2 == "" or UiTema.sprite(nome2).is_empty():
			continue
		var sp := Sprite2D.new()
		sp.texture = UiTema.textura(nome2)
		sp.z_index = ZLETREIRO - 1500
		sp.visible = false
		sp.set_meta("ui_align", "ignore")
		_mundo.add_child(sp)
		_sinais[chave] = sp


## Nome do ícone 9x9 da passiva dele (aberta = a chapa aberta do Blindado depois dos 5,33 s).
func _icone_passiva_adv(aberta: bool) -> String:
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("opp_passives", {}).get(str(_opp_pass.get("id", "")), {})
	if aberta and str(info.get("icon_open_9", "")) != "":
		return str(info.get("icon_open_9", ""))
	return str(info.get("icon_9", ""))


## 8a1: os sinais pequenos da passiva DELE (sprite 1x já desenhado em tamanho de letreiro; pivô no meio), sobre a cabeça dele.
func _montar_sinais_adversario() -> void:
	if _opp_pass.is_empty():
		return
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("opp_passives", {}).get(str(_opp_pass.get("id", "")), {})
	var nomes := {"block": str(info.get("signal", "")), "closed": str(info.get("signal_closed", "")), "open": str(info.get("signal_open", ""))}
	for chave in nomes:
		var nome := str(nomes[chave])
		if nome == "" or UiTema.sprite(nome).is_empty():
			continue
		var sp := Sprite2D.new()
		sp.texture = UiTema.textura(nome)
		sp.z_index = ZSINAL_OPP
		sp.visible = false
		sp.set_meta("ui_align", "ignore")
		_mundo.add_child(sp)
		_opp_sinais[chave] = sp


## 8a1: o cinturão do Vale erguido nas luvas da vitória (só contra o dono do cinturão regional, e só se o jogador vencer).
func _montar_cinturao_erguido(opp_id: String) -> void:
	var opp: Dictionary = GameState.lutas.adversario(opp_id)
	if not bool(opp.get("regional_belt", false)) or UiTema.sprite("belt_regional_raised").is_empty():
		return
	_cinturao = AnimSprite.new()
	_cinturao.definir("belt_regional_raised")
	_cinturao.z_index = 405
	_cinturao.visible = false
	_cinturao.set_meta("ui_align", "ignore")
	_mundo.add_child(_cinturao)


## 8a1: botão PULAR com anel (o mesmo da cena) + a dica "SEGURE ESC: PULAR"; só aparecem na apresentação e na fala de depois.
func _montar_pular() -> void:
	_botao_pular = UiTema.botao(self, PULAR_BOTAO)
	_botao_pular.z_index = 2450
	_botao_pular.visible = false
	_botao_pular.add_theme_color_override("font_color", UiTema.WHITE)
	var rotulo := UiTema.botao_conteudo(_botao_pular, UiTema.txt("skip_button", "PULAR"), UiTema.WHITE, 1, "ui_skip_ring", 4.0)
	rotulo.name = "Texto"
	_anel_pular = _botao_pular.get_meta("icone") as TextureRect
	_atlas_pular = AtlasTexture.new()
	_atlas_pular.atlas = UiTema.textura("ui_skip_ring")
	_atlas_pular.region = Rect2(0, 0, 11, 11)
	_anel_pular.texture = _atlas_pular
	_anel_pular.size = Vector2(11, 11)  # a folha tem 9 quadros lado a lado: o rótulo do ícone é 1 quadro (11x11), não a folha inteira
	_botao_pular.pressed.connect(_encerrar_falas)
	var txt := UiTema.txt("skip_chip", "SEGURE ESC: PULAR")
	var lw := UiTema.largura_visivel(txt)
	_chip_pular = UiTema.rotulo(self, txt, UiTema.G2, PULAR_BOTAO.position.x - 8.0 - lw, UiTema.y_texto(PULAR_BOTAO))
	_chip_pular.z_index = 2450
	_chip_pular.visible = false


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
	# 8a1: ícone 9x9 da passiva DELE ao lado da vida dele (sempre); o Blindado troca para a chapa aberta aos 5,33 s.
	if not _opp_pass.is_empty():
		var info_p: Dictionary = by.get("opp_passives", {})
		var ic := _icone_passiva_adv(false)
		var posi: Array = info_p.get("hud", {}).get("icon_pos", [346, 17])
		posi = [maxf(float(posi[0]), 348.0), posi[1]]  # fora do cartão do relógio (que termina em x 348)
		if ic != "" and not UiTema.sprite(ic).is_empty():
			_opp_icone = UiTema.textura_rect(hud, ic, float(posi[0]), float(posi[1]))
			_opp_icone.name = "IconePassivaAdversario"

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
	elif _passiva == "counter_punch":
		_montar_cargas(hud, y_tatica)
	elif _passiva == "top_control":
		_montar_sinal_fixo(hud, y_tatica, "passive_top_control_9",
			[UiTema.txt("fight_hud_standing", "EM PÉ"), UiTema.txt("fight_hud_ground", "NO CHÃO")])
	elif _passiva == "thai_clinch":
		_montar_sinal_fixo(hud, y_tatica, "passive_thai_clinch_9", [UiTema.txt("fight_hud_apart", "SOLTO"), UiTema.txt("fight_hud_clinch", "CLINCH")])
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


## HUD do Contragolpista (7b2): 3 losangos (passo 11; sem ícone ao lado: ele também é um losango e viraria 4 cargas) na fileira da tática, coladas na ponta da barra de vida DELA
## (x 282), no mesmo lugar das 5 bolinhas do Boxe. Cada esquiva acende (quadro 1, com 1 quadro de clarão); com 3 piscam e aparece CARGA!.
func _montar_cargas(hud: Control, y_tatica: float) -> void:
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("counter_hud", {})
	var n := int(luta.get("charge_max", info.get("count", 3)))
	var passo := float(info.get("step_px", 11))
	var x0 := 282.0 - (passo * float(n) - 2.0)
	var rot := UiTema.txt("fight_hud_charge", "CARGA")
	UiTema.rotulo(hud, rot, UiTema.G3, roundf(x0 - 6.0 - UiTema.largura_visivel(rot)), y_tatica + 1.0)
	for i in n:
		_cargas_hud.append(CartaoPassiva.pip_carga(hud, x0 + passo * float(i), y_tatica, 0))
	var nome := str(info.get("banner_full", "ui_banner_charge_full"))
	if not UiTema.sprite(nome).is_empty():
		_letreiro_carga = UiTema.textura_rect(hud, nome, 282.0 - 70.0, y_tatica + 17.0)
		_letreiro_carga.visible = false


## Sinal fixo do HUD (Por cima: EM PÉ / NO CHÃO; Clinch: SOLTO / CLINCH): ícone 9x9 + texto, o grupo colado na ponta (x 282).
## Apagado até acontecer; aceso (branco, com clarão) enquanto durar.
func _montar_sinal_fixo(hud: Control, y_tatica: float, icone: String, textos: Array) -> void:
	_sinal_textos = textos
	var larg := 0.0
	for t in textos:
		larg = maxf(larg, UiTema.largura_visivel(str(t)))
	var x0 := 282.0 - (larg + 12.0)
	_sinal_icone = UiTema.textura_rect(hud, icone, x0, y_tatica - 1.0)
	_sinal_rotulo = UiTema.rotulo(hud, str(textos[0]), UiTema.G2, x0 + 12.0, y_tatica)
	_sinal_icone.modulate = Color(1, 1, 1, 0.45)


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
	_iniciar_pre(dados)
	if _pre == "":
		_soltar_gesto()


## O gesto do John na entrada (só ele; o discípulo recebe {}); cabe nos 1,5 s da entrada. Com a entrada no ringue, vem depois dela.
func _soltar_gesto() -> void:
	_gesto_luta(GameState.pedir_gesto("fight_intro"))


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

	# 8a1: o Blindado fecha a guarda (sinal GUARDA FECHADA logo depois do LUTEM!) e abre aos 5,33 s (A GUARDA ABRIU).
	var guarda_ate := float(_opp_pass.get("guard_until", 0.0))
	if guarda_ate > 0.0:
		_cue(0.25, func() -> void: _sinal_adversario("closed"))
		if guarda_ate < fim_real - 0.3:
			_cue(guarda_ate, func() -> void: _abrir_guarda())

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
		if str(res.get("finish", "")) in ["submission", "ground_stop"]:  # 7b2: o juiz para a luta no chão, sem queda do K.O.
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
		if str(luta.result.get("finish", "")) == "ground_stop":
			pass  # 7b2: ele fica no chão e o jogador por cima; só o letreiro entra
		elif str(_l[perdedor].estado) != "preso":
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
	if str(luta.result.get("finish", "")) == "ground_stop":
		_banner_fim_mostrar("ground_stop", UiTema.txt("fight_ground_stop", "O JUIZ PAROU!"))
		return
	if not UiTema.sprite("ui_banner_submission").is_empty():
		_limpar_area_do_letreiro(_banner_sub_img)
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
	if _bloqueado(_ponto_cabeca(0) + Vector2(0, -14)):
		return
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
	if _bloqueado(_ponto_cabeca(1) + Vector2(0, -14)):
		return
	var n := _pegar_numero()
	_ordem_numeros += 1
	n.definir_z(940 + _ordem_numeros % 40)
	n.iniciar(texto, cor, true, "", _ponto_cabeca(1) + Vector2(0, -14), 0.9, 18.0)
	Sala.afastar(_numeros, n, true)


## Vitória: se o jogador é o John, entra o gesto curto (0,15-0,59 s) e a pose de braços erguidos vem logo depois.
func _comemorar(vencedor: int) -> void:
	_cinturao_ativo = vencedor == 0 and bool(luta.result.get("win", false)) and _cinturao != null
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
	if alvo == 1 and not chao and not _opp_pass.is_empty():
		reacao = _reacao_passiva_adv(e, reacao)
	if quem == 0:
		_streak_ant = int(e.get("streak", 0))
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


## 8a1: a reação dele quando a passiva dele agiu: guarda fechada do James = block; golpe que a trava segurou (AGUENTOU!/NÃO CAIU/ESCAPOU!)
## = a pose de assinatura; Bigorna: o embalo do jogador chega a 5 = sacode a cabeça e bate no queixo (só visual).
func _reacao_passiva_adv(e: Dictionary, reacao: String) -> String:
	if bool(e.get("guard", false)) and _existe_anim(1, "block"):
		return "block"
	if bool(e.get("opp_block", false)) and _existe_anim(1, "signature"):
		return "signature"
	if str(_opp_pass.get("id", "")) == "adv_iron_chin" and int(e.get("streak", 0)) >= 5 and _streak_ant < 5 and int(e.who) == 0 \
			and _existe_anim(1, "signature") and not bool(e.get("ko", false)):
		return "signature"
	return reacao


## Golpe do especial dos cliques: [animação, reação]. Boxe e sem arte: uppercut / hit_up. Jiu-jitsu nunca usa animação de boxe:
## em pé é o clinch_push (reação hit_clinch) e no chão é o ground_pressure (reação ground_hit). ["", ""] se a folha não existe.
func _golpe_especial(e: Dictionary) -> Array:
	if _passiva == "shin" or _passiva == "thai_clinch":  # 7b1 (lição A1 da 7a1): o Muay Thai nunca usa o uppercut (golpe de boxe); o especial é o chute rodado
		if _existe_anim(0, "spin_kick"):
			return ["spin_kick", "hit_spin"]
		return ["knee", "hit_body"] if _existe_anim(0, "knee") else ["", ""]
	if _passiva != "submission" and _passiva != "top_control":
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
	if i == 0 and _cinturao != null and str(l.estado) != "victory":
		_cinturao.visible = false
	match str(l.estado):
		"ko", "preso":
			return
		"victory":
			spr.definir(_nome(i, "victory"))
			spr.tocar([0, 1, 2, 3], float(UiTema.sprite(spr.nome_sprite).get("fps", 8.0)), true)
			if i == 0:
				_erguer_cinturao()
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
			if pose == "block":
				spr.parar(2)  # guarda alta parada (como o "guard")
			else:
				spr.tocar([0, 1, 2, 3], float(UiTema.sprite(spr.nome_sprite).get("fps", 6.0)), true)
	_ajustar_sombra(i)
	_atualizar_suor(i)


## Pose de repouso em pé. Muay Thai (7b1): o jogador fica na guarda tailandesa (mt_idle) e o adversário manca com 2 marcas
## (limp) ou 3 (limp_heavy; sem ela, limp). Sem a folha nova, o idle de sempre.
func _idle_da_arte(i: int) -> String:
	if i == 1 and _guarda_fechada and _existe_anim(1, "guard"):
		return "guard"  # 8a1: o Blindado no 1º round: guarda fechada no lugar do idle
	if _passiva == "counter_punch" and i == 0 and _existe_anim(0, "block"):
		return "block"  # 7b2: guarda alta entre os golpes (a 2ª passiva do Boxe se vê só pela pose)
	if _passiva == "thai_clinch":
		return "mt_idle" if i == 0 and _existe_anim(0, "mt_idle") else "idle"  # sem marcas e sem mancar
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
	var guarda := alvo == 1 and bool(e.get("guard", false))  # 8a1: acerto na guarda fechada do James (1º round)
	var spr_a := UiTema.sprite(_nome(quem, str(e.get("anim_usada", e.attack_anim))))
	var hp := _vetor(spr_a.get("hit_point", [31, -61]))
	var base_a: Vector2 = _l[quem].base
	var contato := base_a + hp

	# Reação de quem apanha (no K.O. sem grogue a queda assume; na finalização o tap_out é a reação).
	var ko := bool(e.ko)
	var finalizou := str(e.get("finish", "")) in ["submission", "ground_stop"]
	if not ko or not luta.grogue.is_empty() or finalizou:
		_tocar(alvo, str(e.get("reacao_usada", e.defender_anim)))
		_flash_lutador(alvo)
	if bloqueado and not (str(e.get("phase", "standing")) == "ground" and _pose_chao_ok()):
		var sb := UiTema.sprite(_nome(alvo, "block"))
		var mao := _vetor((sb.get("hands", [{"hand_front": [10, -67]}]) as Array)[1].get("hand_front", [10, -67]))
		_tocar_fx("fx_block", (_l[alvo].base as Vector2) + mao, alvo == 1)
	elif guarda and _fx.has("fx_guard_clink") and not (str(e.get("phase", "standing")) == "ground" and _pose_chao_ok()):
		_tocar_fx("fx_guard_clink", contato, quem == 1)  # o golpe bate na guarda: faísca de aço no lugar do impacto
		if tipo == "crit":
			_tocar_fx("fx_fight_crit", contato, quem == 1)
	else:
		_tocar_fx("fx_fight_hit", contato, quem == 1)
		if tipo == "crit":
			_tocar_fx("fx_fight_crit", contato, quem == 1)

	_hud_embalo(int(e.get("streak", 0)))
	_hud_passiva2(e)
	if _passiva == "shin":
		_hud_marcas(int(e.get("marks", _marcas_acesas)))
	_fase_visual = str(e.get("phase_after", _fase_visual))  # a queda leva os dois ao chão (as poses de repouso mudam)

	# Número flutuante: sai do ponto de contato e sobe.
	_numero_de_dano(float(e.damage), tipo, bloqueado, Vector2(contato.x, contato.y - 6.0), guarda)
	if alvo == 1 and bool(e.get("opp_block", false)):
		_sinal_adversario("block")  # a passiva dele segurou: AGUENTOU! / NÃO CAIU / ESCAPOU!

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
	if bloqueado or guarda:
		sfx.bloqueio()
	sfx.golpe_luta(forte, bloqueado or guarda)
	if alvo == 1 and bool(e.get("opp_block", false)):
		_tremer(1, 0.1)
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
	if _combo < 2 or _rotulo_combo == null or _area_letreiro.size != Vector2.ZERO:
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
func _numero_de_dano(dano: float, tipo: String, bloqueado: bool, origem: Vector2, guarda: bool = false) -> void:
	var forte := tipo == "crit" or tipo == "counter"
	if _bloqueado(origem):
		return
	var n := _pegar_numero()
	_ordem_numeros += 1
	n.definir_z(900 + (50 if forte and not guarda else 0) + _ordem_numeros % 40)
	if guarda:
		# 8a1: contra a guarda fechada o número é cinza e pequeno (1x) mesmo no crítico: o dano que passou é menor, e se vê.
		var txt_g := UiTema.txt("fight_crit", "{n}!", {"n": NumberFormat.fmt(dano)}) if forte else NumberFormat.fmt(dano)
		n.iniciar(txt_g, UiTema.G2, false, "", origem, 0.6, 20.0)
	elif tipo == "crit":
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
	_hud_passiva2(e)
	if str(e.get("phase", "standing")) == "ground" and _pose_chao_ok():
		var baixo := (_l[alvo].base as Vector2) + Vector2(0, -26)
		if _bloqueado(baixo):
			sfx.esquiva()
			return
		var ng := _pegar_numero()
		_ordem_numeros += 1
		ng.definir_z(930 + _ordem_numeros % 40)
		ng.iniciar(UiTema.txt("fight_dodge", "ESQUIVOU"), UiTema.CREAM, false, "", baixo, 0.7, 14.0)
		Sala.afastar(_numeros, ng, true)
		sfx.esquiva()
		return
	var cab := _ponto_cabeca(alvo)
	if _bloqueado(cab + Vector2(0, -8)):
		sfx.esquiva()
		return
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
	_banner_ko_mostrar(str(luta.result.get("finish", "")))
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
func _banner_ko_mostrar(finish: String = "") -> void:
	if _banners_fim.has(finish):  # 7b2: K.O. NO CONTRAGOLPE! / JOELHADA!
		_banner_fim_mostrar(finish, "")
		return
	var rodado := finish == "spin_kick"
	var b := _banner_spin if rodado and not UiTema.sprite("ui_banner_spin_kick").is_empty() else _banner_ko
	_limpar_area_do_letreiro(b)
	b.visible = true
	b.scale = Vector2(3, 3)
	b.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(b, "modulate:a", 1.0, 0.08)
	tw.tween_callback(func() -> void: b.scale = Vector2(2, 2)).set_delay(0.09)
	_tremer(2, 0.3)


## Número novo que nasceria dentro (ou logo embaixo) da área do letreiro de fim: não nasce (o letreiro tem que ler limpo).
func _bloqueado(p: Vector2) -> bool:
	return _area_letreiro.size != Vector2.ZERO and _area_letreiro.grow(32.0).has_point(p)


## Um letreiro de fim entrou: marca a área dele e apaga (fade de 0,15 s) os números de dano, o combo, o CARGA! e os sinais que
## estiverem nela. `b` = o sprite do letreiro (já na escala final, 2x).
func _limpar_area_do_letreiro(b: Sprite2D) -> void:
	var tam := b.texture.get_size() * 2.0
	_area_letreiro = Rect2(b.position - tam / 2.0, tam)
	var area := _area_letreiro.grow(8.0)
	for n in _numeros:
		# O número ainda sobe (`_subida` px): vale o caminho inteiro dele, não só onde ele está agora.
		var r: Rect2 = n.retangulo()
		var caminho := Rect2(r.position.x, r.position.y - n._subida, r.size.x, r.size.y + n._subida)
		if n.ativo and caminho.intersects(area):
			var gen: int = n._gen
			var tw := create_tween().set_ignore_time_scale(true)
			tw.tween_method(func(p: float) -> void: n.sumir_com(p, gen), 0.0, 1.0, 0.15)
	# Textos fixos do mundo que passam por baixo do letreiro: combo (HUD, só o texto que invade a área), CARGA! e os sinais.
	var extras: Array = []
	if _rotulo_combo != null:
		var rc := Rect2(_rotulo_combo.global_position, _rotulo_combo.get_combined_minimum_size() * _rotulo_combo.scale)
		if rc.intersects(area):
			if _tween_combo != null and _tween_combo.is_valid():
				_tween_combo.kill()
			extras.append(_rotulo_combo)
	if _letreiro_carga != null and Rect2(_letreiro_carga.global_position, _letreiro_carga.size).intersects(area):
		extras.append(_letreiro_carga)
	for sp in _sinais.values():
		if sp.visible:
			extras.append(sp)
	for x in extras:
		var no: CanvasItem = x
		var tw2 := create_tween().set_ignore_time_scale(true)
		tw2.tween_property(no, "modulate:a", 0.0, 0.15)
		tw2.tween_callback(no.hide)  # some de vez (outro tween de modulate, como o do CARGA!, não pode trazê-lo de volta)


## Letreiro do fim da 2ª passiva: mesma entrada do K.O.! (pop 3x -> 2x, tremida de 2 px). Sem a folha, o texto do tema.
func _banner_fim_mostrar(finish: String, texto: String) -> void:
	if not _banners_fim.has(finish):
		_texto_banner(texto if texto != "" else UiTema.txt("fight_" + finish, finish.to_upper()), UiTema.Y2, 3)
		return
	var b: Sprite2D = _banners_fim[finish]
	_limpar_area_do_letreiro(b)
	b.visible = true
	b.scale = Vector2(3, 3)
	b.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(b, "modulate:a", 1.0, 0.08)
	tw.tween_callback(func() -> void: b.scale = Vector2(2, 2)).set_delay(0.09)
	_tremer(2, 0.3)


## 7b2: o que o evento diz da 2ª passiva (carga, chão, clinch) vai para o HUD.
func _hud_passiva2(e: Dictionary) -> void:
	match _passiva:
		"counter_punch":
			_hud_carga(int(e.get("charge", _carga_atual)))
		"top_control":
			_hud_sinal(bool(e.get("ground", _sinal_aceso)), "stood_up")
		"thai_clinch":
			_hud_sinal(bool(e.get("clinch", _sinal_aceso)), "clinch")


## Carga do Contragolpista: acende os losangos até `n` (o novo pisca 1 quadro); com a carga cheia os 3 piscam (quadros 1/3) e CARGA!
## aparece. A carga volta a 0 depois do contragolpe: tudo apaga.
func _hud_carga(n: int) -> void:
	if _cargas_hud.is_empty() or n == _carga_atual:
		return
	var subiu := n > _carga_atual
	_carga_atual = n
	var cheia := n >= _cargas_hud.size()
	if _tween_carga != null and _tween_carga.is_valid():
		_tween_carga.kill()
	for i in _cargas_hud.size():
		var b: Control = _cargas_hud[i]
		if i < n:
			if subiu and i == n - 1 and not cheia:
				CartaoPassiva.definir_pip_carga(b, 2)
				var tw := create_tween()
				tw.tween_interval(0.08)
				tw.tween_callback(func() -> void:
					if is_instance_valid(b):
						CartaoPassiva.definir_pip_carga(b, 1))
			else:
				CartaoPassiva.definir_pip_carga(b, 1)
		else:
			CartaoPassiva.definir_pip_carga(b, 0)
	if cheia and not _carga_cheia:
		_carga_cheia = true
		_tween_carga = create_tween().set_loops()
		_tween_carga.tween_callback(func() -> void: _quadro_cargas(3))
		_tween_carga.tween_interval(1.0 / 6.0)
		_tween_carga.tween_callback(func() -> void: _quadro_cargas(1))
		_tween_carga.tween_interval(1.0 / 6.0)
		if _letreiro_carga != null:
			_letreiro_carga.visible = true
			_letreiro_carga.modulate = Color(2, 2, 2)
			create_tween().tween_property(_letreiro_carga, "modulate", Color.WHITE, 0.3)
		else:
			_numero_aviso(UiTema.txt("fight_charge_full", "CARGA!"), UiTema.Y1)
		sfx.publico(-12.0)
		_flash_tela(0.2)
	elif not cheia:
		_carga_cheia = false
		if _letreiro_carga != null:
			_letreiro_carga.visible = false


func _quadro_cargas(q: int) -> void:
	for b in _cargas_hud:
		if is_instance_valid(b):
			CartaoPassiva.definir_pip_carga(b, q)


## Sinal fixo do Por cima (NO CHÃO) e do Clinch (CLINCH). Ao acender no Clinch aparece o sinal CLINCH!; no Por cima, ao ele levantar,
## aparece LEVANTOU. `sinal` = qual sinal pequeno mostrar na mudança de estado.
func _hud_sinal(aceso: bool, sinal: String) -> void:
	if _sinal_icone == null or aceso == _sinal_aceso:
		return
	var antes := _sinal_aceso
	_sinal_aceso = aceso
	_sinal_icone.modulate = Color.WHITE if aceso else Color(1, 1, 1, 0.45)
	_sinal_rotulo.text = str(_sinal_textos[1 if aceso else 0])
	_sinal_rotulo.add_theme_color_override("font_color", UiTema.WHITE if aceso else UiTema.G2)
	_sinal_rotulo.modulate = Color(2, 2, 2)
	_sinal_rotulo.create_tween().tween_property(_sinal_rotulo, "modulate", Color.WHITE, 0.25)
	if (sinal == "clinch" and aceso) or (sinal == "stood_up" and antes and not aceso):
		_sinal_pequeno(sinal)


## Sinal pequeno que sobe da cabeça dele (LEVANTOU / CLINCH!). Sem a folha, um número de aviso de texto.
func _sinal_pequeno(chave: String) -> void:
	var texto := UiTema.txt("fight_" + chave, chave.to_upper())
	if not _sinais.has(chave):
		_numero_aviso(texto, UiTema.WHITE)
		return
	var sp: Sprite2D = _sinais[chave]
	var p := _ponto_cabeca(1) + Vector2(0, -22)
	sp.position = Vector2(roundf(p.x), roundf(p.y))
	sp.visible = true
	sp.modulate = Color(1.6, 1.6, 1.6, 1.0)
	var tw := create_tween()
	tw.tween_property(sp, "modulate", Color.WHITE, 0.15)
	tw.tween_interval(0.7)
	tw.tween_property(sp, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: sp.visible = false)


# --- 8a1: passiva dele (sinais e guarda), cinturão erguido ---

## Sinal pequeno sobre a cabeça dele (1x, pivô no meio, 10 px para cima em 0,6 s). Os números de dano que estiverem na área somem
## (o sinal lê limpo, como os letreiros do fim). Sem a imagem, um número de aviso de texto.
func _sinal_adversario(chave: String) -> void:
	if _pre != "" or _outro != 0:
		return
	var sp: Sprite2D = _opp_sinais.get(chave)
	if sp == null:
		var texto := str(_opp_pass.get("block_text", "")) if chave == "block" else \
			str(_opp_pass.get("guard_closed_text" if chave == "closed" else "guard_open_text", ""))
		if texto != "":
			_numero_aviso(texto, UiTema.WHITE)
		return
	var tam := sp.texture.get_size()
	var p := _ponto_cabeca(1) + Vector2(0, -14)
	var origem := Vector2(roundf(p.x), roundf(p.y))
	sp.position = origem
	_limpar_numeros_em(Rect2(origem - tam / 2.0 - Vector2(0, 10), tam + Vector2(0, 10)).grow(6.0))
	sp.visible = true
	sp.modulate = Color(1.7, 1.7, 1.7, 1.0)
	if _tween_sinais.has(chave) and (_tween_sinais[chave] as Tween).is_valid():
		(_tween_sinais[chave] as Tween).kill()
	var tw := create_tween()
	_tween_sinais[chave] = tw
	tw.tween_property(sp, "modulate", Color.WHITE, 0.12)
	tw.parallel().tween_property(sp, "position:y", origem.y - 10.0, 0.6)
	tw.tween_interval(0.35)
	tw.tween_property(sp, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void: sp.visible = false)


## Apaga (0,15 s) os números de dano que passam pela área `area`.
func _limpar_numeros_em(area: Rect2) -> void:
	for n in _numeros:
		var r: Rect2 = n.retangulo()
		var caminho := Rect2(r.position.x, r.position.y - n._subida, r.size.x, r.size.y + n._subida)
		if n.ativo and caminho.intersects(area):
			var gen: int = n._gen
			var tw := create_tween().set_ignore_time_scale(true)
			tw.tween_method(func(p: float) -> void: n.sumir_com(p, gen), 0.0, 1.0, 0.15)


## Aos 5,33 s a guarda do James abre: ele volta ao idle, a chapa do ícone abre e aparece A GUARDA ABRIU (ouro).
func _abrir_guarda() -> void:
	if not _guarda_fechada:
		return
	_guarda_fechada = false
	if str(_l[1].estado) == "idle":
		_repouso(1)
	var aberto := _icone_passiva_adv(true)
	if _opp_icone != null and aberto != "" and not UiTema.sprite(aberto).is_empty():
		_opp_icone.texture = UiTema.textura(aberto)
		_opp_icone.modulate = Color(2, 2, 2)
		_opp_icone.create_tween().tween_property(_opp_icone, "modulate", Color.WHITE, 0.3)
	_sinal_adversario("open")
	_publico_cheer(false)
	sfx.publico(-14.0)


## O cinturão do Vale nas luvas da vitória (anim 0,1,2 a 6 fps; a torcida vibra). Segue as mãos quadro a quadro.
func _erguer_cinturao() -> void:
	if _cinturao == null or not _cinturao_ativo:
		return
	var primeira := not _cinturao.visible
	_cinturao.visible = true
	if primeira:
		_cinturao.tocar([0, 1, 2], 6.0, true)
		_publico_cheer(true)
	_seguir_cinturao()


## Dados da folha do jogador no quadro atual (as mãos), para o verificador conferir o cinturão nas luvas.
func _info_folha_mao() -> Dictionary:
	return UiTema.sprite((_l[0].spr as AnimSprite).nome_sprite)


func _seguir_cinturao() -> void:
	if _cinturao == null or not _cinturao.visible or _l.is_empty():
		return
	var spr: AnimSprite = _l[0].spr
	var hs: Array = UiTema.sprite(spr.nome_sprite).get("hands", [])
	var h := Vector2(4, -83)
	if hs.size() > 0:
		var m: Dictionary = hs[clampi(spr.frame, 0, hs.size() - 1)]
		var a := _vetor(m.get("hand_front", [9, -83]))
		var b := _vetor(m.get("hand_back", [-1, -82]))
		h = (a + b) / 2.0
	# Segurado nas LUVAS (1x): o pivô do cinturão (40,14) é o meio das duas pegadas e vai para o meio das mãos do quadro de vitória.
	# As pegadas do cinturão ficam mais afastadas que as luvas: ele pode encostar no topo da cabeça, mas nunca flutua solto.
	_cinturao.position = (_l[0].base as Vector2) + h


# --- 8a1: entrada no ringue, apresentação do James e fala de depois (o relógio da luta fica parado em -intro_seconds) ---

const ENTRADA_SEGMENTOS := [1.0, 0.35, 0.3, 0.35]  # s de cada trecho do caminho (soma 2,0)
const ENTRADA_ERGUE := 0.4  # braço para a torcida
var _entrada_fator := 1.0  # 1,0 = 2,4 s; com a apresentação do James vai a 0,5 (1,2 s) para o total ficar longe dos 15 s
const PALAVRA_DESPREZO := {"rival_james_intro_first_2": "fofo.", "rival_james_intro_revenge_2": "nenhuma.",
	"rival_james_intro_school_won_1": "mania.", "rival_james_intro_many_1": "cartaz."}
static var pular_entrada := false  # só para testes: sem a entrada no ringue


func _info_entrada() -> Dictionary:
	return UiTema.manifest().get("fight_layout", {}).get("arenas", {}).get(str(luta.get("arena", "")), {}).get("entrance", {})


func _iniciar_pre(dados: Dictionary) -> void:
	var entrada := _info_entrada()
	_ap_falas = (dados.get("intro_falas", []) as Array).duplicate() if dados.get("intro_falas", []) is Array else []
	_entrada_fator = 0.5 if not _ap_falas.is_empty() else 1.0
	if not entrada.is_empty() and not pular_entrada and (entrada.get("player_path", []) as Array).size() >= 2:
		_pre = "entrada"
		_pre_t = 0.0
		sfx.publico(-16.0)
		if _facho != null:
			_facho.visible = true
			_facho.tocar([0, 1], 8.0, true)
		_aplicar_entrada(0.0)
	elif not _ap_falas.is_empty():
		_iniciar_falas("intro")


## Posição do jogador a `t` segundos da entrada: anda pelo caminho do manifest (trechos de tempo fixo).
func _pos_entrada(t: float) -> Vector2:
	var caminho: Array = _info_entrada().get("player_path", [])
	var acum := 0.0
	for i in ENTRADA_SEGMENTOS.size():
		var d := float(ENTRADA_SEGMENTOS[i])
		if t <= acum + d or i == ENTRADA_SEGMENTOS.size() - 1:
			var a := _vetor(caminho[mini(i, caminho.size() - 1)])
			var b := _vetor(caminho[mini(i + 1, caminho.size() - 1)])
			return a.lerp(b, clampf((t - acum) / d, 0.0, 1.0))
		acum += d
	return _vetor(caminho[caminho.size() - 1])


func _aplicar_entrada(t_real: float) -> void:
	var t := t_real / _entrada_fator
	var p := _pos_entrada(t)
	var rope_x := float(_info_entrada().get("rope_x", 118))
	var balanco := 0.0 if t >= 2.0 else -roundf(absf(sin(t * 9.0)) * 2.0)  # passo: um quique de 2 px
	var q := Vector2(roundf(p.x), roundf(p.y + balanco))
	var l: Dictionary = _l[0]
	l.spr.position = q
	l.sombra.position = Vector2(roundf(p.x), roundf(p.y)) + Vector2(0, -1)
	l.spr.z_index = 49 if p.x < rope_x else Z_LUTADOR  # atrás do público da frente até passar entre as cordas
	if _facho != null:
		_facho.position = Vector2(roundf(p.x), roundf(p.y))


func _passo_pre(delta: float) -> void:
	if _pre == "entrada":
		_pre_t += delta
		var dur := 0.0
		for d in ENTRADA_SEGMENTOS:
			dur += float(d)
		dur *= _entrada_fator
		_aplicar_entrada(minf(_pre_t, dur))
		if _pre_t >= dur and str(_l[0].estado) != "victory":
			_estado(0, "victory")  # braço para a torcida (a pose de vitória, sem cinturão)
			_l[0].spr.z_index = Z_LUTADOR
			_publico_cheer(false)
			sfx.publico(-12.0)
		if _pre_t >= dur + ENTRADA_ERGUE * _entrada_fator:
			_finalizar_entrada()
	elif _pre == "falas":
		_passo_falas(delta)


## Termina a entrada (ou pula com o clique): o jogador já está no lugar dele; segue a apresentação (James) ou a luta.
func _finalizar_entrada() -> void:
	if _pre != "entrada":
		return
	_l[0].estado = "idle"
	_l[0].spr.position = _l[0].base
	_l[0].sombra.position = (_l[0].base as Vector2) + Vector2(0, -1)
	_repouso(0)
	if _facho != null:
		_facho.visible = false
	_pre = ""
	if not _ap_falas.is_empty():
		_iniciar_falas("intro")
	else:
		_soltar_gesto()


func _falando_apresentacao() -> bool:
	return _pre == "falas" or _outro == 1


func _iniciar_falas(tipo: String) -> void:
	_ap_tipo = tipo
	_ap_i = 0
	_ap_espera = 0.0
	_scorn_em = -1.0
	_scorn_feito = false
	_mostrar_pular(true)
	if tipo == "intro":
		_pre = "falas"
		_guarda_fechada = false  # J1: sai da guarda para o idle e olha a plateia
		if str(_l[1].estado) == "idle":
			_repouso(1)
	else:
		_outro = 1


func _mostrar_pular(sim: bool) -> void:
	if _botao_pular != null:
		_botao_pular.visible = sim
		_chip_pular.visible = sim
	if not sim:
		_esc_t = 0.0
		_esc_segurando = false
		if _atlas_pular != null:
			_atlas_pular.region = Rect2(0, 0, 11, 11)


func _passo_falas(delta: float) -> void:
	if _ap_espera >= 0.0:
		_ap_espera -= delta
		if _ap_espera < 0.0:
			_ap_espera = -1.0
			_proxima_fala()
	if _scorn_em >= 0.0 and not _scorn_feito:
		_scorn_em -= delta
		if _scorn_em <= 0.0:
			_scorn_feito = true
			_gesto_desprezo()


func _proxima_fala() -> void:
	if _ap_i >= _ap_falas.size():
		_fim_falas()
		return
	var f: Dictionary = _ap_falas[_ap_i]
	_ap_i += 1
	_balao.modo_cena = true
	# De pé (apresentação, venceu, perdeu por pontos) o balão só evita a cabeça do jogador; com ele no chão, o corpo todo.
	_balao.zona = ZONA_CORPO_JOGADOR if (_ap_tipo == "outro" and bool(luta.result.get("win", false)) and bool(luta.result.get("ko", false))) else ZONA_CABECA_JOGADOR
	var texto := str(f.get("text", ""))
	if not _balao.mostrar(str(f.get("id", "")), str(f.get("speaker", "rival")), texto, _cabeca_da_fala(), 46.0, []):
		_ap_espera = 0.0  # não coube sem cobrir alguém: pula a fala
		return
	# O gesto de desprezo: 1 vez por apresentação, quando aparece a palavra-gatilho; na fala de depois, se ele venceu, nas últimas 0,9 s.
	var palavra := str(PALAVRA_DESPREZO.get(str(f.get("id", "")), ""))
	if _ap_tipo == "intro" and palavra != "" and not _scorn_feito:
		var idx := texto.replace("\n", "").find(palavra)
		_scorn_em = 0.06 + (_balao.tempo_letra(maxi(idx, 0)) if idx >= 0 else 1.0)
	elif _ap_tipo == "outro" and not bool(luta.result.get("win", false)):
		_scorn_em = maxf(0.3, _balao.duracao() - 0.9)


## Onde o balão prende: a cabeça dele de pé; no chão (K.O./finalização), o ponto da cabeça caída (ko_head_point, espelhado).
func _cabeca_da_fala() -> Vector2:
	if _ap_tipo == "outro" and bool(luta.result.get("win", false)) and bool(luta.result.get("ko", false)):
		var l: Dictionary = _l[1]
		var ko_cab := _vetor(UiTema.manifest().get("fight_layout", {}).get("ko_head_point", [-36, -12]))
		if _ko_nome == "ko_knees":
			ko_cab = Vector2(38, -12)
		elif _ko_nome == "ko_back":
			ko_cab = Vector2(-42, -12)
		var p := (l.base as Vector2) + Vector2(ko_cab.x * float(l.dir), ko_cab.y - 6.0) * float(l.escala)
		p.x = maxf(p.x, ZONA_CORPO_JOGADOR.end.x + 22.0)  # caído de frente para o jogador: o rabicho aponta para o corpo dele, à direita do jogador
		return p
	return _ponto_cabeca(1)


func _gesto_desprezo() -> void:
	if not _existe_anim(1, "scorn") or str(_l[1].estado) == "ko":
		return
	_tocar(1, "scorn")
	var s := UiTema.sprite(_nome(1, "scorn"))
	var pico := float(int(s.get("peak_frame", 3))) / maxf(float(s.get("fps", 7.0)), 1.0)
	get_tree().create_timer(pico).timeout.connect(func() -> void:
		if is_instance_valid(self) and ativa:
			sfx.tap_glove())


func _ao_balao_fechou(id: String, _quem: String) -> void:
	if not id.begins_with("rival_james") or not _falando_apresentacao():
		return
	_ap_espera = ESPERA_ENTRE_FALAS


func _fim_falas() -> void:
	_ap_espera = -1.0
	_scorn_em = -1.0
	_mostrar_pular(false)
	if _ap_tipo == "intro":
		_pre = ""
		_guarda_fechada = str(_opp_pass.get("id", "")) == "adv_blindado"  # J3: volta à guarda fechada, a passiva anunciada sem texto
		if str(_l[1].estado) == "idle":
			_repouso(1)
		_soltar_gesto()
	elif _ap_tipo == "outro":
		_outro = 2


## PULAR (botão, ESC segurado 0,5 s): encerra a apresentação na hora. Ninguém pula a luta por aqui.
func _encerrar_falas() -> void:
	if not _falando_apresentacao():
		return
	_ap_falas = []
	_balao.fechar_agora(false)
	_fim_falas()


func _clique_fala() -> void:
	if not _balao.ativo():
		return
	if not _balao.texto_completo():
		_balao.completar()  # 1º toque: completa a fala (sem blip)
		return
	var agora := float(Time.get_ticks_msec()) / 1000.0
	if agora - _ap_t_completo >= float(GameState.dialogos.typing.get("click_guard", 0.15)):
		_balao.fechar_agora(true)  # 2º toque: próxima fala


func _iniciar_outro() -> void:
	var f: Variant = luta.get("outro_fala", {})
	if not (f is Dictionary) or (f as Dictionary).is_empty() or str((f as Dictionary).get("text", "")) == "":
		_outro = 2
		return
	_apagar_letreiros_do_fim()
	for sp in _opp_sinais.values():  # nada da guarda (nem sinal nenhum) por cima da fala de depois
		(sp as Sprite2D).visible = false
	for tw in _tween_sinais.values():
		if (tw as Tween).is_valid():
			(tw as Tween).kill()
	_ap_falas = [f]
	_iniciar_falas("outro")


## Os letreiros do fim (K.O.!, FINALIZOU!, TEMPO!...) saem (0,2 s) quando o balão do James entra: nada cobre a fala.
func _apagar_letreiros_do_fim() -> void:
	var nos: Array = [_banner_ko, _banner_spin, _banner_sub_img, _banner, _banner_sub, _banner_fundo]
	nos.append_array(_banners_fim.values())
	for n in nos:
		var c := n as CanvasItem
		if c != null and is_instance_valid(c) and c.visible:
			var tw := create_tween()
			tw.tween_property(c, "modulate:a", 0.0, 0.2)
			tw.tween_callback(c.hide)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_clique_geral()
		accept_event()


func _clique_geral() -> void:
	if _pre == "entrada":
		_finalizar_entrada()
	elif _falando_apresentacao():
		_clique_fala()


func _input(event: InputEvent) -> void:
	if not ativa or not visible or not (event is InputEventKey):
		return
	var ek := event as InputEventKey
	if ek.keycode == KEY_SPACE and ek.pressed and not ek.echo and (_pre != "" or _falando_apresentacao()):
		_clique_geral()
		get_viewport().set_input_as_handled()
	elif ek.keycode == KEY_ESCAPE and (_pre != "" or _falando_apresentacao()):
		if ek.pressed and not ek.echo:
			_esc_segurando = true
			_esc_t = 0.0
		elif not ek.pressed:
			_esc_segurando = false
			_esc_t = 0.0
			if _atlas_pular != null:
				_atlas_pular.region = Rect2(0, 0, 11, 11)
		get_viewport().set_input_as_handled()


func _tick_esc(delta: float) -> void:
	if not _esc_segurando:
		return
	_esc_t += delta
	var alvo := 0.5
	if _atlas_pular != null:
		_atlas_pular.region = Rect2(11.0 * float(clampi(int(round(8.0 * _esc_t / alvo)), 0, 8)), 0, 11, 11)
	if _esc_t >= alvo:
		_esc_segurando = false
		_esc_t = 0.0
		if _pre == "entrada":
			_finalizar_entrada()
		_encerrar_falas()

# --- Efeitos ---

func _tocar_fx(nome: String, p: Vector2, espelhar: bool) -> void:
	if not _fx.has(nome):
		return
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
	_tick_esc(delta)
	if _pre != "":
		# 8a1: entrada no ringue / apresentação do James: o relógio da luta espera (a tela segue viva: barras, números, tremida).
		_passo_pre(delta)
		_seguir_cinturao()
		for b in _barras:
			b.passo(_t)
		return
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

	_seguir_cinturao()
	if _clock >= _fim_total and not finalizada:
		# 8a1: a fala de depois do James toca aqui, antes da janela de fim (o balão some quando uma janela abre).
		if _outro == 0:
			_iniciar_outro()
		if _outro == 1:
			_passo_falas(delta)
		if _outro == 2:
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
	_mostrar_pular(false)
	var resumo := GameState.concluir_luta()  # aplica o resultado UMA vez e salva
	terminou.emit(resumo)


## Esconde a arena e libera os recursos (chamado pelo Fluxo ao voltar para a garagem).
func encerrar() -> void:
	_balao.fechar_agora(false)
	_pre = ""
	_outro = 2
	_gesto.cancelar()
	_gesto_nome = ""
	Engine.time_scale = 1.0
	ativa = false
	visible = false
	for c in get_children():
		if c != sfx and c != _gesto and c != _balao:
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
