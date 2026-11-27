extends RefCounted
## Estados do ui_audit.gd: Ronda 2a2 (o chefe Apagão). Esconderijo com o chefe trancado (lenda, os 3 do beco, cinturão), aberto, vencido e
## raro; a ficha do chefe; a prévia (com e sem SUSTO); a entrada com o letreiro; a luta na arena_apagao; o apagão (quadro escuro); o prêmio
## normal e o raro; o menu com o cartaz; a personalização com o FIO DESENCAPADO; e o B16 (o capuz e o convite do Osmar juntos).
## Usa o auditor `au` e os ajudantes de `estados_ronda2a.gd` (`au._ronda2a`). O relógio do GameState fica pausado: a lógica anda por `tick()`.

const NOMES := [
	"r2b_esc_trancado_lenda", "r2b_esc_trancado_bandidos", "r2b_esc_trancado_cinturao", "r2b_esc_aberto", "r2b_esc_revanche",
	"r2b_esc_vencido", "r2b_esc_raro", "r2b_ficha_chefe",
	"r2b_previa_susto", "r2b_previa_perdido", "r2b_entrada", "r2b_luta_arena", "r2b_apagao",
	"r2b_premio_normal", "r2b_premio_raro", "r2b_menu_cartaz", "r2b_personalizacao", "r2b_capuz_convite",
]
const BANDIDOS := ["tire", "bike", "gate"]
const CHEFE := "apagao"

var au


func _init(auditor) -> void:
	au = auditor


func _alguma() -> bool:
	for n in NOMES:
		if au._quer(n):
			return true
	return false


func _quer(lista: Array) -> bool:
	for n in lista:
		if au._quer(n):
			return true
	return false


func _fluxo() -> Node:
	return au._cena.get_node("Fluxo")


func _a() -> Object:
	return au._ronda2a


func _nivel(i: int) -> int:
	return int(au.gs.ronda_cfg.niveis[i])


func _ficha(venceu: int, perdeu: int, camp: int, desafio: bool) -> Dictionary:
	return {"won": venceu, "lost": perdeu, "first_win_campaign": camp, "challenge": desafio}


## Linhagem pronta para o chefe: lenda `lenda`, `bandidos` vencidos (com ou sem o desafio deles), `cinturoes`, a ficha do chefe (ou nada).
func _montar(lenda: int, bandidos: int = 3, cinturoes: int = 1, chefe: Dictionary = {}, desafios: bool = false) -> void:
	au._ronda._montar("garage", lenda)
	au.gs._gravar_marco("regional_league_opened", {}, false)
	au.gs.permanente["regional_belts"] = cinturoes
	var alley := {}
	for i in bandidos:
		alley[BANDIDOS[i]] = _ficha(1, 0, 5 + i, desafios)
	var bc: Dictionary = au.gs.permanente["black_cat"]
	bc["alley"] = alley
	if not chefe.is_empty():
		bc["boss"] = {CHEFE: chefe}
	au.gs._ronda.atualizar_visivel()


func _fim() -> void:
	_a()._fim()


func _rodar_fase_ronda2a2() -> void:
	if not _alguma():
		return
	await _esconderijos()
	await _noite()
	await _premios()
	await _menu()
	await _personalizacao()
	await _capuz_convite()
	_fim()


# ---------------------------------------------------------------------------------------------
# Esconderijo
# ---------------------------------------------------------------------------------------------

func _esconderijos() -> void:
	var lv := _nivel(4)  # lenda do nível 5 (a do chefe)
	var casos := [
		["r2b_esc_trancado_lenda", lv - 1, 3, 1, {}, false, "legend"],
		["r2b_esc_trancado_bandidos", lv, 2, 1, {}, false, "bandits"],
		["r2b_esc_trancado_cinturao", lv, 3, 0, {}, false, "belt"],
		["r2b_esc_aberto", lv, 3, 1, {}, false, ""],
		["r2b_esc_revanche", lv, 3, 1, _ficha(0, 1, 0, false), false, ""],
		["r2b_esc_vencido", lv, 3, 1, _ficha(1, 0, 9, false), false, ""],
		["r2b_esc_raro", lv, 3, 1, _ficha(1, 0, 9, true), true, ""],
	]
	for c in casos:
		if not au._quer(c[0]):
			continue
		_montar(int(c[1]), int(c[2]), int(c[3]), c[4], bool(c[5]))
		au._exigir(au.gs.chefe_falta() == str(c[6]), c[0], "o que falta para o chefe: '%s' (esperado '%s')" % [au.gs.chefe_falta(), str(c[6])])
		var j = await _a()._esconderijo(c[0])
		var e: Dictionary = au.gs.esconderijo()
		match c[0]:
			"r2b_esc_trancado_lenda", "r2b_esc_trancado_cinturao":
				var achou := false
				for k in e.board:
					if str(k.get("night", "")) == "boss" and bool(k.get("locked", false)):
						achou = true
				au._exigir(achou, c[0], "o quadro tem o cartão do chefe trancado")
				au._exigir(str(e.boss.missing_text) != "", c[0], "a ficha do chefe diz o que falta: %s" % str(e.boss.missing_text))
			"r2b_esc_trancado_bandidos":
				au._exigir(str(e.boss.missing_text) == au.gs.texto_ui("dossier_missing_bandits", ""), c[0], "a ficha diz VENÇA OS 3 DO BECO: %s" % str(e.boss.missing_text))
			"r2b_esc_aberto", "r2b_esc_revanche":
				au._exigir(bool(e.boss.open), c[0], "o chefe está aberto")
			"r2b_esc_vencido":
				au._exigir(str((e.trophies[0] as Dictionary).state) == "normal", c[0], "a prateleira tem o capacete normal no lugar 1")
			"r2b_esc_raro":
				au._exigir(str((e.trophies[0] as Dictionary).state) == "rare", c[0], "a prateleira tem o capacete raro no lugar 1")
		await au._ver(c[0])
		if c[0] == "r2b_esc_vencido" and j != null:
			j.ficha_pedida.emit(CHEFE)
			await au._esperar(0.5)
			au._exigir(_fluxo().janela != null and au._eh(_fluxo().janela, "JanelaFicha"), c[0], "LER abre a ficha do chefe")
			if au._quer("r2b_ficha_chefe"):
				await au._ver("r2b_ficha_chefe")
			if _fluxo().janela != null and au._eh(_fluxo().janela, "JanelaFicha"):
				_fluxo().janela.fechar_pedido.emit()
				await au._esperar(0.3)
		_fim()
	if au._quer("r2b_ficha_chefe") and not au._quer("r2b_esc_vencido"):
		_montar(_nivel(4), 3, 1, _ficha(1, 0, 9, true), true)
		var j2 = await _a()._esconderijo("r2b_ficha_chefe")
		if j2 != null:
			j2.ficha_pedida.emit(CHEFE)
			await au._esperar(0.5)
			au._exigir(_fluxo().janela != null and au._eh(_fluxo().janela, "JanelaFicha"), "r2b_ficha_chefe", "LER abre a ficha do chefe")
			await au._ver("r2b_ficha_chefe")
		_fim()


# ---------------------------------------------------------------------------------------------
# A noite do chefe
# ---------------------------------------------------------------------------------------------

## Entra pelo IR do chefe e deixa a aproximação acabada do jeito pedido ("scare" | "seen"); anda até a prévia.
func _ate_a_previa(nome: String, como: String) -> void:
	var t = await _a()._entrar(CHEFE, nome)
	au._exigir(t != null and bool(au.gs.briga_estado().get("boss", true)) or t != null, nome, "o IR do chefe abre a aproximação")
	var j: RondaLogica = au.gs.ronda_jogo()
	if j != null:
		j.sustos = 1 if como == "scare" else 0
		j.vistos = 1 if como == "seen" else 0
		j.fase = "fim"
	au.gs.tick(0.01)
	await _a()._ate_previa()


func _lutar(nome: String, como: String, blackout: Dictionary = {}, venceu_na_certa: bool = true) -> Node:
	await _ate_a_previa(nome, como)
	var jp = _fluxo().janela
	au._exigir(jp != null and au._eh(jp, "JanelaPreviaBriga"), nome, "a aproximação do chefe acaba na prévia")
	if venceu_na_certa:
		au.gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	else:
		au.gs.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
	var tat := str(au.gs.lutas.taticas[0].id)
	var info: Dictionary = au.gs.briga_lutar(tat)
	au._exigir(not info.is_empty() and bool(info.get("boss", false)), nome, "LUTAR devolve a luta do chefe")
	if not blackout.is_empty():
		info["blackout"] = blackout  # só a apresentação: para o quadro escuro cair dentro de uma luta curta de teste
	if jp != null:
		jp.queue_free()
		_fluxo().janela = null
	var tl = _fluxo().tela
	_fluxo().ronda.visible = false
	tl.iniciar(info)
	await au._esperar(0.3)
	return tl


func _noite() -> void:
	if au._quer("r2b_previa_susto") or au._quer("r2b_previa_perdido"):
		for q in [["r2b_previa_susto", "scare"], ["r2b_previa_perdido", "seen"]]:
			if not au._quer(q[0]):
				continue
			_montar(_nivel(4), 3, 1)
			await _ate_a_previa(q[0], q[1])
			var jp = _fluxo().janela
			au._exigir(jp != null and au._eh(jp, "JanelaPreviaBriga"), q[0], "a prévia do chefe abre")
			if jp != null and au._eh(jp, "JanelaPreviaBriga"):
				var txt := str(jp._desafio.text)
				if q[1] == "scare":
					au._exigir(txt.contains("%"), q[0], "com SUSTO a prévia mostra a chance do desafio: %s" % txt)
				else:
					au._exigir(txt == au.gs.texto_ui("alley_ch_lost", "").to_upper(), q[0], "sem SUSTO: DESAFIO: PERDIDO (sem %%): %s" % txt)
			await au._ver(q[0])
			if jp != null:
				jp.sair_pedido.emit()
				await au._esperar(0.4)
			_fim()
	if _quer(["r2b_entrada", "r2b_luta_arena"]):
		_montar(_nivel(4), 3, 1)
		var tl = await _lutar("r2b_entrada", "scare")
		if au._quer("r2b_entrada"):
			au._exigir(tl._pre == "letreiro", "r2b_entrada", "a entrada do chefe começa pelo letreiro (%s)" % tl._pre)
			au._exigir(tl._banner.visible and tl._banner.text == au.gs.texto_ui("alley_apagao_entrance", "").to_upper(), "r2b_entrada", "o letreiro diz O APAGÃO (%s)" % tl._banner.text)
			await au._esperar(0.4)
			await au._ver("r2b_entrada")
		# o clique pula o letreiro
		tl._clique_geral()
		au._exigir(tl._pre == "", "r2b_entrada", "o clique pula o letreiro")
		if _quer(["r2b_luta_arena"]):
			await au._esperar(2.6)
			au._exigir(tl._arena_pre == "arena_apagao", "r2b_luta_arena", "a luta usa a arena_apagao (%s)" % tl._arena_pre)
			au._exigir(tl._l[1].spr.nome_sprite.begins_with("opp_alley_apagao"), "r2b_luta_arena", "o chefe usa a folha opp_alley_apagao (%s)" % tl._l[1].spr.nome_sprite)
			au._exigir(tl._fx_choque != null, "r2b_luta_arena", "o choque do Apagão existe na luta do chefe")
			if tl._fx_choque != null:
				tl._choque((tl._l[1].base as Vector2) + Vector2(-48, -64))  # o arco do golpe forte no hit_point do heavy
			await au._ver("r2b_luta_arena")
		_fim()
	if au._quer("r2b_apagao"):
		_montar(_nivel(4), 3, 1)
		# luta curta de teste: o apagão cai logo no começo e dura 5 s, para a captura pegar o quadro escuro
		var tl2 = await _lutar("r2b_apagao", "seen", {"t": 0.3, "dark_s": 5.0})
		tl2._clique_geral()
		await au._esperar(2.9)
		au._exigir(tl2._escuro != null and tl2._escuro.color.a > 0.3, "r2b_apagao", "o véu do apagão está acima dos lutadores")
		au._exigir(str(tl2._bg_spr.texture.resource_path).ends_with("arena_apagao_dark_bg.png"), "r2b_apagao", "o fundo é o escuro (%s)" % str(tl2._bg_spr.texture.resource_path))
		au._exigir(not tl2._lampada.visible, "r2b_apagao", "a arandela está apagada")
		await au._ver("r2b_apagao")
		_fim()


# ---------------------------------------------------------------------------------------------
# Prêmio
# ---------------------------------------------------------------------------------------------

func _premio(raro: bool) -> Dictionary:
	var p: Dictionary = _a()._premio_base(true)
	p["boss"] = true
	p["bandit"] = CHEFE
	p["title"] = _t("alley_boss_prize_title", "O BECO ACENDEU")
	p["dossier_new"] = true
	p["clipping_new"] = true
	p["dossier_line"] = _t("alley_dossier_new", "FICHA NOVA NO DOSSIÊ")
	p["clipping_line"] = _t("alley_clipping_new", "RECORTE NA PAREDE")
	p["headline"] = _t("alley_apagao_headline", "")
	p["trophy_new"] = "rare" if raro else "normal"
	p["trophy_line"] = _t("alley_trophy_new", "")
	p["trophy_rare_line"] = _t("alley_trophy_rare", "") if raro else ""
	p["press_title_new"] = true
	p["press_title"] = _t("press_title_apagao", "")
	p["press_title_line"] = _t("alley_press_title_new", "", {"titulo": au.gs.texto_ui("press_title_apagao", "")})
	p["poster_new"] = true
	p["poster_line"] = _t("alley_poster_new", "")
	p["legend_gain"] = 4
	# o chefe só abre na lenda 64 (nível 5): o prêmio real sai sempre no nível máximo
	p["legend"] = 68
	p["level_before"] = 5
	p["level"] = 5
	p["max_level"] = true
	p["scares_total"] = 23
	if raro:
		p["challenge_done"] = true
		p["challenge_ever"] = true
		p["style_unlocked"] = "live_wire"
		p["challenge_line"] = _t("alley_challenge_cleared", "DESAFIO CUMPRIDO")
		p["style_text"] = _t("alley_style_unlocked", "", {"estilo": au.gs.texto_ui("disc_opt_shorts_color_live_wire", "FIO DESENCAPADO")})
	return p


func _premios() -> void:
	for q in [["r2b_premio_normal", false], ["r2b_premio_raro", true]]:
		if not au._quer(q[0]):
			continue
		_montar(_nivel(4), 3, 1, _ficha(1, 0, 9, q[1]), q[1])
		var p := _premio(q[1])
		await au._abrir()
		au._estado = q[0]
		au.gs.set_process(false)
		_fluxo()._abrir_premio_briga(p)
		await au._esperar(0.9)
		var j = _fluxo().janela
		au._exigir(j != null and au._eh(j, "JanelaPremioBriga"), q[0], "a janela do prêmio do chefe abre")
		if j != null:
			au._exigir(Rect2(0, 0, 640, 360).encloses(j.painel.get_global_rect()), q[0], "a janela cabe na tela")
		await au._ver(q[0])
		_fim()


# ---------------------------------------------------------------------------------------------
# Menu, personalização e B16
# ---------------------------------------------------------------------------------------------

func _menu() -> void:
	if not au._quer("r2b_menu_cartaz"):
		return
	var todas: Array = au._menu._todas()
	au._exigir("apagao" in todas, "r2b_menu_cartaz", "a camada apagao está no parede.json")
	var m = await au._menu._menu(true, todas)
	await au._ver("r2b_menu_cartaz")
	var _m = m


func _personalizacao() -> void:
	if not au._quer("r2b_personalizacao"):
		return
	au._f6b1_fim("Tati Gancho", true)
	au.gs.permanente["black_cat"] = {"legend": 80, "shown_level": 5, "scares": 10, "rounds": 10, "open_campaign": 3,
		"alley": {"tire": _ficha(1, 0, 5, true), "bike": _ficha(1, 0, 6, true), "gate": _ficha(1, 0, 7, true)},
		"boss": {CHEFE: _ficha(1, 0, 9, true)}}
	await au._abrir()
	au._estado = "r2b_personalizacao"
	au._exigir(au.gs.receber_discipulo() and au.gs.sucessao_estado() == "creating", "r2b_personalizacao", "a sucessão abre na criação (%s)" % au.gs.sucessao_estado())
	var tela: Node = await au._f6b1_janela_criar()
	au._exigir(tela != null, "r2b_personalizacao", "a tela de criação abre")
	var ids: Array = au.gs.disciples.opcoes_ativas("shorts_color")
	au._exigir(ids.size() > 0 and ids.back() == "live_wire", "r2b_personalizacao", "o FIO DESENCAPADO é o último da lista do calção (%s)" % str(ids))
	au.gs.definir_rascunho("shorts_color", "live_wire")
	await au._esperar(0.6)
	var dourado := 0
	for c in tela._campos:
		var g: TextureRect = c.gato
		if g.visible and g.texture == load("res://assets/sprites/ui/icon_region_black_cat_9_gold.png"):
			dourado += 1
	au._exigir(dourado == 1, "r2b_personalizacao", "o calção raro mostra o gato dourado (%d)" % dourado)
	await au._ver("r2b_personalizacao")
	_fim()


## B16: o capuz no prego e o balão do convite do Osmar na mesma tela, sem um cobrir o outro.
func _capuz_convite() -> void:
	if not au._quer("r2b_capuz_convite"):
		return
	_montar(_nivel(4), 3, 1)
	au.gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	au.gs.permanente["last_art"] = "boxing"
	au.gs.arte_id = "boxing"
	au.gs._atualizar_traco()
	au.gs.convite = {"room_s": 400.0, "next_at": 640.0, "open": "spar", "open_since": 395.0, "last": "spar", "warm": false}
	au.gs._convite_local = au.gs.local_id
	au.gs.baloes_escondidos = false
	await au._abrir()
	await au._esperar(0.6)
	au._estado = "r2b_capuz_convite"
	var sala: Node = au._cena.get_node("Sala")
	au._exigir(sala._capuz != null and sala._capuz.visible, "r2b_capuz_convite", "o capuz está no prego")
	var conv: Node = au._cena._convite
	au._exigir(conv.ativo(), "r2b_capuz_convite", "o balão do convite do Osmar está na tela")
	if conv.ativo() and sala._capuz.visible:
		var rc: Rect2 = sala._capuz_rect
		var rb: Rect2 = conv.retangulo_total()
		au._exigir(not rc.intersects(rb), "r2b_capuz_convite", "o balão não cobre o capuz: %s x %s" % [au._fmt(rb), au._fmt(rc)])
		au._exigir(Rect2(0, 0, 640, 360).encloses(rc) and Rect2(0, 0, 640, 360).encloses(rb), "r2b_capuz_convite", "os dois cabem na tela")
	await au._ver("r2b_capuz_convite")
	_fim()


## Texto do jogo em MAIÚSCULAS (o mesmo que UiTema.txt; o auditor carrega antes do UiTema, por isso não o usa).
func _t(chave: String, padrao: String = "", vars: Dictionary = {}) -> String:
	return au.gs.preencher(au.gs.texto_ui(chave, padrao), vars).to_upper()
