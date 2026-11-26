extends RefCounted
## Estados do ui_audit.gd: Ronda 2a1 (brigas de beco do Gato Preto). Esconderijo travado e aberto (capuz com a briga aberta), o quadro com
## cada tipo de cartão (SUSTO, BRIGA, REVANCHE, DESAFIO, quieto), o Dossiê vazio / no meio / cheio e a ficha, a aproximação com a dica
## "SOLTE E CLIQUE!", a prévia da noite, a luta no beco (com e sem os estilos), o prêmio (vitória, derrota, desafio cumprido) e a personalização
## com os estilos liberados. Usa o auditor `au` e o `_montar` da Ronda. Relógio do GameState pausado: a lógica anda por `tick()`/`passo()`.

const NOMES := [
	"r2a_esc_travado", "r2a_esc_aberto", "r2a_quadro_briga", "r2a_quadro_revanche", "r2a_quadro_desafio", "r2a_quadro_quieto",
	"r2a_dossie_vazio", "r2a_dossie_meio", "r2a_dossie_cheio", "r2a_dossie_ficha",
	"r2a_aprox_contagem", "r2a_aprox_dica", "r2a_previa", "r2a_previa_gate", "r2a_luta_beco", "r2a_luta_beco_estilos", "r2a_luta_beco_fim",
	"r2a_premio_vitoria", "r2a_premio_derrota", "r2a_premio_desafio", "r2a_premio_nivel", "r2a_personalizacao",
	"r2a_sala_1_garage", "r2a_sala_2_garage", "r2a_sala_3_garage", "r2a_sala_1_gym", "r2a_sala_2_gym", "r2a_sala_3_gym",
	"r2a_sala_1_center", "r2a_sala_2_center", "r2a_sala_3_center", "r2a_sala_hover",
	"r2a_aprox_nome_oculto", "r2a_aprox_nome_aberto", "r2a_previa_nome_aberto", "r2a_dossie_desafio_feito", "r2a_dossie_sem_desafio",
]
const BANDIDOS := ["tire", "bike", "gate"]
const V := {"won": 1, "lost": 0, "first_win_campaign": 6}

var au


func _init(auditor) -> void:
	au = auditor


func _alguma() -> bool:
	for n in NOMES:
		if au._quer(n):
			return true
	return false


func _fluxo() -> Node:
	return au._cena.get_node("Fluxo")


func _sala() -> Node:
	return au._cena.get_node("Sala")


func _ficha(venceu: int, perdeu: int, camp: int, desafio: bool) -> Dictionary:
	return {"won": venceu, "lost": perdeu, "first_win_campaign": camp, "challenge": desafio}


## Briga aberta (lenda 30 + o marco da liga) com as fichas `alley` pedidas e o capuz no prego. `lenda` 12 = travada.
func _montar(lenda: int, alley: Dictionary = {}) -> void:
	au._ronda._montar("garage", lenda)
	au.gs._gravar_marco("regional_league_opened", {}, false)
	if lenda > 0:
		au.gs.permanente["black_cat"]["alley"] = alley.duplicate(true)
	au.gs._ronda.atualizar_visivel()


func _fim() -> void:
	au.gs.set_process(true)
	au.gs.baloes_escondidos = false


## Abre o Esconderijo pelo clique do capuz (o caminho real).
func _esconderijo(nome: String) -> Node:
	await au._abrir()
	au._estado = nome
	var info: Dictionary = au.gs.capuz_info()
	au._exigir(bool(info.get("clickable", false)) and bool(info.get("hideout", false)), nome, "o capuz está clicável e leva ao Esconderijo (%s)" % str(info))
	_sala().capuz_clicado.emit()
	await au._esperar(0.6)
	var j = _fluxo().janela
	au._exigir(j != null and au._eh(j, "TelaEsconderijo"), nome, "o clique no capuz abre o Esconderijo")
	return j


func _rodar_fase_ronda2a() -> void:
	if not _alguma():
		return
	await _esconderijos()
	await _sala_recortes()
	await _nomes()
	await _noite()
	await _premios()
	await _personalizacao()
	_fim()


# ---------------------------------------------------------------------------------------------
# Esconderijo, quadro e Dossiê
# ---------------------------------------------------------------------------------------------

func _esconderijos() -> void:
	if au._quer("r2a_esc_travado"):
		_montar(12)  # lenda 2: a briga fechada; o Esconderijo só abre aqui por abrir_esconderijo (o capuz leva ao SUSTO)
		await au._abrir()
		au._estado = "r2a_esc_travado"
		au._exigir(not bool(au.gs.capuz_info().get("hideout", true)), "r2a_esc_travado", "briga fechada: o capuz leva direto ao SUSTO")
		_fluxo().abrir_esconderijo()
		await au._esperar(0.6)
		au._exigir(_fluxo().janela != null and au._eh(_fluxo().janela, "TelaEsconderijo"), "r2a_esc_travado", "o Esconderijo trancado abre")
		await au._ver("r2a_esc_travado")
	if au._quer("r2a_esc_aberto") or au._quer("r2a_dossie_vazio") or au._quer("r2a_quadro_briga"):
		_montar(30)
		var j = await _esconderijo("r2a_esc_aberto")
		await au._ver("r2a_esc_aberto")
		for n in ["r2a_dossie_vazio", "r2a_quadro_briga"]:
			if au._quer(n):
				await au._ver(n)  # a mesma tela, conferida pelos nomes dos estados pedidos (briga nova + dossiê todo fechado)
		if j != null:
			j.voltar_pedido.emit()
			await au._esperar(0.3)
			au._exigir(_fluxo().janela == null and au.gs.capuz_visivel() == "scare", "r2a_esc_aberto", "VOLTAR fecha o Esconderijo e o capuz continua no prego")
	if au._quer("r2a_quadro_revanche"):
		_montar(30, {"tire": _ficha(0, 2, 0, false)})
		await _esconderijo("r2a_quadro_revanche")
		await au._ver("r2a_quadro_revanche")
	if au._quer("r2a_quadro_desafio") or au._quer("r2a_dossie_meio"):
		_montar(30, {"tire": _ficha(1, 0, 5, false), "bike": _ficha(0, 1, 0, false)})
		await _esconderijo("r2a_quadro_desafio")
		await au._ver("r2a_quadro_desafio")
		if au._quer("r2a_dossie_meio"):
			await au._ver("r2a_dossie_meio")
	if au._quer("r2a_quadro_quieto") or au._quer("r2a_dossie_cheio") or au._quer("r2a_dossie_ficha"):
		_montar(30, {"tire": _ficha(1, 0, 5, true), "bike": _ficha(1, 1, 6, false), "gate": _ficha(1, 0, 7, false)})
		var j2 = await _esconderijo("r2a_quadro_quieto")
		await au._ver("r2a_quadro_quieto")
		if au._quer("r2a_dossie_cheio"):
			await au._ver("r2a_dossie_cheio")
		if au._quer("r2a_dossie_ficha") and j2 != null:
			j2.ficha_pedida.emit("gate")
			await au._esperar(0.5)
			au._exigir(_fluxo().janela != null and au._eh(_fluxo().janela, "JanelaFicha"), "r2a_dossie_ficha", "LER abre a ficha")
			await au._ver("r2a_dossie_ficha")
			if _fluxo().janela != null and au._eh(_fluxo().janela, "JanelaFicha"):
				_fluxo().janela.fechar_pedido.emit()
				await au._esperar(0.3)
				au._exigir(_fluxo().janela != null and au._eh(_fluxo().janela, "TelaEsconderijo"), "r2a_dossie_ficha", "FECHAR devolve o Esconderijo")


# ---------------------------------------------------------------------------------------------
# B1: recortes dos bandidos vencidos na parede; B2: nome escondido/revelado; B3: Dossiê feito x por fazer
# ---------------------------------------------------------------------------------------------

func _sala_recortes() -> void:
	var casos: Array = []
	for local in ["garage", "gym", "center"]:
		for n in [1, 2, 3]:
			casos.append(["r2a_sala_%d_%s" % [n, local], local, n, false])
	casos.append(["r2a_sala_hover", "garage", 3, true])
	for c in casos:
		if not au._quer(c[0]):
			continue
		au._ronda._montar(c[1], 30)
		var alley := {}
		for i in int(c[2]):
			alley[BANDIDOS[i]] = _ficha(1, 0, 5 + i, false)
		au.gs.permanente["black_cat"]["alley"] = alley
		au.gs._ronda.atualizar_visivel()
		await au._abrir()
		await au._esperar(0.3)
		au._estado = c[0]
		var sala = _sala()
		var vis := 0
		for bid in sala._beco_recortes:
			if sala._beco_recortes[bid].visible:
				vis += 1
		au._exigir(vis == int(c[2]), c[0], "%d recortes de bandido na parede (%d)" % [int(c[2]), vis])
		au._exigir(sala._beco_rect.size != Vector2.ZERO, c[0], "a área do hover existe")
		var centro: Vector2 = sala._beco_recortes[BANDIDOS[int(c[2]) - 1]].position + Vector2(7, 9)
		var tip: String = sala._texto_parede(centro)
		au._exigir(tip != "" and tip.contains(_t("alley_%s_clipping" % BANDIDOS[int(c[2]) - 1]).substr(0, 10)), c[0], "o hover traz a manchete do último vencido: %s" % tip)
		if c[3]:
			au._dica_inst().ancora_fixa = centro
			sala._hover_em(centro)
			await au._esperar(0.5)
		await au._ver(c[0])
		if c[3]:
			au._dica_inst().ancora_fixa = Vector2(-1, -1)
			sala._hover_em(Vector2(5, 5))
		_fim()


func _nomes() -> void:
	if au._quer("r2a_aprox_nome_aberto") or au._quer("r2a_previa_nome_aberto") or au._quer("r2a_aprox_nome_oculto"):
		var ficha := {"tire": _ficha(1, 0, 5, false)}
		if au._quer("r2a_aprox_nome_oculto"):
			_montar(30)
			var t0 = await _entrar("tire", "r2a_aprox_nome_oculto")
			_tick(2.2)
			await au._esperar(0.3)
			au._exigir(t0 != null and t0._rotulo_ocorrencia.text == _t("alley_occ_tire_anon"), "r2a_aprox_nome_oculto", "o HUD usa o nome escondido (%s)" % t0._rotulo_ocorrencia.text)
			await au._ver("r2a_aprox_nome_oculto")
			_fim()
		if au._quer("r2a_aprox_nome_aberto"):
			_montar(30, ficha)
			var t1 = await _entrar("tire", "r2a_aprox_nome_aberto")
			_tick(2.2)
			await au._esperar(0.3)
			au._exigir(t1 != null and t1._rotulo_ocorrencia.text == _t("alley_occ_tire"), "r2a_aprox_nome_aberto", "depois de vencer o HUD mostra o nome (%s)" % t1._rotulo_ocorrencia.text)
			await au._ver("r2a_aprox_nome_aberto")
			_fim()
		if au._quer("r2a_previa_nome_aberto"):
			_montar(30, ficha)
			await _entrar("tire", "r2a_previa_nome_aberto")
			await _ate_previa()
			await au._ver("r2a_previa_nome_aberto")
			_fim()
	for q in [["r2a_dossie_desafio_feito", true], ["r2a_dossie_sem_desafio", false]]:
		if not au._quer(q[0]):
			continue
		_montar(30, {"tire": _ficha(1, 0, 5, q[1]), "bike": _ficha(1, 0, 6, q[1]), "gate": _ficha(1, 0, 7, q[1])})
		await _esconderijo(q[0])
		await au._ver(q[0])
		_fim()


# ---------------------------------------------------------------------------------------------
# A noite de briga
# ---------------------------------------------------------------------------------------------

func _entrar(bandido: String, nome: String) -> Node:
	var j = await _esconderijo(nome)
	au.gs.set_process(false)
	if j != null:
		j.ir_pedido.emit("alley", bandido)
	await au._esperar(0.4)
	var t = _fluxo().ronda
	au._exigir(t != null and au.gs.ronda_ativa == "alley", nome, "IR abre a aproximação da briga")
	return t


## Anda a noite `s` segundos pelo tick do jogo.
func _tick(s: float) -> void:
	for _i in int(round(s * 20.0)):
		au.gs.tick(0.05)


func _noite() -> void:
	var quer := false
	for n in ["r2a_aprox_contagem", "r2a_aprox_dica", "r2a_previa", "r2a_previa_gate", "r2a_luta_beco", "r2a_luta_beco_estilos", "r2a_luta_beco_fim"]:
		quer = quer or au._quer(n)
	if not quer:
		return
	if au._quer("r2a_aprox_contagem"):
		_montar(30)
		var t = await _entrar("tire", "r2a_aprox_contagem")
		await au._esperar(0.3)
		au._exigir(t != null and t._desafio != null and t._desafio.visible, "r2a_aprox_contagem", "o desafio da noite aparece na contagem")
		await au._ver("r2a_aprox_contagem")
		_fim()
	if au._quer("r2a_aprox_dica"):
		_montar(30)
		var t2 = await _entrar("tire", "r2a_aprox_dica")
		# o jogo sorteia os ciclos (randomize); o estado troca por um jogo sem sorteio para ser sempre igual
		au.gs._ronda_jogo = RondaLogica.new(au.gs.ronda_cfg.cfg_aproximacao("tire"), null)
		var j = au.gs.ronda_jogo()
		_tick(2.1)
		# anda até o fim do muro e segue segurando (a dica pede 0,6 s perto)
		for _i in 3000:
			var e: Dictionary = j.estado()
			if bool(e.perto) and float(e.segurando_perto_s) >= 0.7:
				break
			j.passo(1.0 / 60.0, e.ladrao == "trabalha" or bool(e.perto), false)
		await au._esperar(0.25)
		var e2: Dictionary = j.estado()
		au._exigir(bool(e2.get("dica_soltar", false)), "r2a_aprox_dica", "segurou perto por 0,6 s: dica_soltar (estado %s)" % str(e2))
		au._exigir(t2._dica_soltar.visible, "r2a_aprox_dica", "SOLTE E CLIQUE! aparece no lugar do sinal PERTO")
		au._exigir(not t2._perto.visible, "r2a_aprox_dica", "o sinal PERTO some enquanto a dica pisca")
		t2._dica_soltar.modulate.a = 1.0
		await au._ver("r2a_aprox_dica")
		_fim()
	if au._quer("r2a_previa") or au._quer("r2a_previa_gate") or au._quer("r2a_luta_beco") or au._quer("r2a_luta_beco_estilos") or au._quer("r2a_luta_beco_fim"):
		for q in [["r2a_previa", "tire", {}], ["r2a_previa_gate", "gate", {"tire": _ficha(1, 0, 5, true), "bike": _ficha(1, 0, 6, true), "gate": _ficha(0, 1, 0, false)}]]:
			if not au._quer(q[0]):
				continue
			_montar(30, q[2])
			var t3 = await _entrar(q[1], q[0])
			await _ate_previa()
			var jp = _fluxo().janela
			au._exigir(jp != null and au._eh(jp, "JanelaPreviaBriga"), q[0], "a aproximação acaba na prévia da noite")
			if jp != null and au._eh(jp, "JanelaPreviaBriga"):
				au._exigir(_t("challenge_chance_line", "", {"n": 1}) != "" and jp._desafio.text != "", q[0], "a linha do desafio tem texto: %s" % jp._desafio.text)
			await au._ver(q[0])
			if t3 != null and jp != null:
				jp.sair_pedido.emit()
				await au._esperar(0.4)
				au._exigir(au.gs.ronda_ativa == "" and _fluxo().ronda == null and au.gs.capuz_visivel() == "scare", q[0], "SAIR na prévia: a sala volta e o capuz fica no prego")
			_fim()
		var luta_estados := ["r2a_luta_beco", "r2a_luta_beco_estilos", "r2a_luta_beco_fim"]
		for nome in luta_estados:
			if not au._quer(nome):
				continue
			_montar(30, {"tire": _ficha(1, 0, 5, false)} if nome == "r2a_luta_beco_estilos" else {})
			var t4 = await _entrar("tire" if nome != "r2a_luta_beco_estilos" else "tire", nome)
			if nome == "r2a_luta_beco_estilos":
				au.gs.discipulo = {"name": "Tati Gancho", "look": _look_estilos(), "campaign": 2}
			await _ate_previa()
			var jp2 = _fluxo().janela
			au.gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}  # vitória certa (só a luta de teste)
			if jp2 != null and au._eh(jp2, "JanelaPreviaBriga"):
				jp2.lutar_pedido.emit(str(au.gs.lutas.taticas[0].id))
			await au._esperar(0.3)
			var tl = _fluxo().tela
			au._exigir(tl != null and tl.visible and tl._alley, nome, "LUTAR abre a arena do beco")
			au._exigir(au.gs.luta.is_empty(), nome, "a luta da noite não passa por GameState.luta")
			if nome == "r2a_luta_beco_fim":
				for _i in 400:
					if _fluxo().janela != null and au._eh(_fluxo().janela, "JanelaPremioBriga"):
						break
					await au._esperar(0.1)
				au._exigir(_fluxo().janela != null and au._eh(_fluxo().janela, "JanelaPremioBriga"), nome, "no fim da luta abre o prêmio da noite")
				await au._esperar(0.6)
				await au._ver(nome)
				if _fluxo().janela != null and au._eh(_fluxo().janela, "JanelaPremioBriga"):
					_fluxo().janela.voltar_pedido.emit()
					await au._esperar(0.4)
					au._exigir(au.gs.ronda_ativa == "" and _fluxo().ronda == null and not _fluxo().tela.visible and au.gs.sala_ativa(), nome, "VOLTAR devolve a sala")
			else:
				await au._esperar(3.0)
				au._exigir(tl._l[0].spr.nome_sprite.begins_with("fight_vulto_"), nome, "o lutador da esquerda é o vulto (%s)" % tl._l[0].spr.nome_sprite)
				au._exigir(tl._l[1].spr.nome_sprite.begins_with("opp_alley_tire"), nome, "o bandido usa a folha opp_alley_tire (%s)" % tl._l[1].spr.nome_sprite)
				await au._ver(nome)
			_fim()


func _look_estilos() -> Dictionary:
	var l: Dictionary = au.gs.disciples.look_padrao.duplicate()
	l["headband"] = "band"
	l["headband_color"] = "night"
	l["shorts_color"] = "night"
	l["socks"] = "night_wraps"
	return l


## Anda a aproximação até a prévia abrir (a tela da Ronda espera o letreiro e avisa o Fluxo).
func _ate_previa() -> void:
	for _i in 400:
		if str(au.gs.briga_estado().get("fase", "")) == "previa":
			break
		au.gs.tick(0.05)
	for _i in 60:
		if _fluxo().janela != null and au._eh(_fluxo().janela, "JanelaPreviaBriga"):
			break
		await au._esperar(0.1)
	await au._esperar(0.4)


# ---------------------------------------------------------------------------------------------
# Prêmio (montado direto: o resultado real é sorteado; aqui o que conta é o desenho de cada caso)
# ---------------------------------------------------------------------------------------------

func _premio_base(venceu: bool) -> Dictionary:
	return {"night": "alley", "bandit": "tire", "win": venceu, "ko": venceu, "finish": "damage", "round": 1, "approach": "scare", "scare": true,
		"legend_gain": 4 if venceu else 2, "legend": 36, "level_before": 3, "level": 3, "level_up": false, "level_up_line": "", "max_level": false,
		"next_level_at": 52, "challenge_done": false, "challenge_ever": false, "style_unlocked": "", "style": {}, "style_text": "",
		"dossier_new": false, "clipping_new": false, "revenge": not venceu,
		"title": _t("alley_prize_title", "BRIGA GANHA") if venceu else _t("alley_lose_title", "NOITE PERDIDA"),
		"line": _t("alley_win_line", "") if venceu else _t("alley_lose_line", "SAIU MANCANDO"),
		"sub": "" if venceu else _t("alley_lose_sub", ""),
		"headline": "", "clipping_text": "", "dossier_line": "", "clipping_line": "", "challenge_line": ""}


func _com_premio(nome: String, p: Dictionary) -> void:
	_montar(30)
	await au._abrir()
	au._estado = nome
	au.gs.set_process(false)
	_fluxo()._abrir_premio_briga(p)
	await au._esperar(0.9)
	var j = _fluxo().janela
	au._exigir(j != null and au._eh(j, "JanelaPremioBriga"), nome, "a janela do prêmio da briga abre")
	if j != null:
		au._exigir(Rect2(0, 0, 640, 360).encloses(j.painel.get_global_rect()), nome, "a janela cabe na tela")
	await au._ver(nome)
	_fim()


func _premios() -> void:
	if au._quer("r2a_premio_vitoria"):
		var p := _premio_base(true)
		p["dossier_new"] = true
		p["clipping_new"] = true
		p["dossier_line"] = _t("alley_dossier_new", "FICHA NOVA NO DOSSIÊ")
		p["clipping_line"] = _t("alley_clipping_new", "RECORTE NA PAREDE")
		p["headline"] = _t("alley_tire_headline", "GATO PRETO APAGA O CHAVE DE RODA. ESTEPES DORMEM EM PAZ")
		await _com_premio("r2a_premio_vitoria", p)
	if au._quer("r2a_premio_derrota"):
		await _com_premio("r2a_premio_derrota", _premio_base(false))
	if au._quer("r2a_premio_desafio"):
		var p2 := _premio_base(true)
		p2["challenge_done"] = true
		p2["challenge_ever"] = true
		p2["dossier_new"] = true
		p2["clipping_new"] = true
		p2["style_unlocked"] = "night_band"
		p2["challenge_line"] = _t("alley_challenge_cleared", "DESAFIO CUMPRIDO")
		p2["style_text"] = _t("alley_style_unlocked", "ESTILO NOVO: {estilo}", {"estilo": _t("disc_opt_headband_color_night", "FAIXA DA NOITE")})
		p2["dossier_line"] = _t("alley_dossier_new", "FICHA NOVA NO DOSSIÊ")
		p2["clipping_line"] = _t("alley_clipping_new", "RECORTE NA PAREDE")
		p2["headline"] = _t("alley_tire_headline", "GATO PRETO APAGA O CHAVE DE RODA. ESTEPES DORMEM EM PAZ")
		await _com_premio("r2a_premio_desafio", p2)
	if au._quer("r2a_premio_nivel"):
		var p3 := _premio_base(true)
		p3["level_up"] = true
		p3["level"] = 4
		p3["level_up_line"] = "A LENDA CRESCEU NO BECO"
		await _com_premio("r2a_premio_nivel", p3)


# ---------------------------------------------------------------------------------------------
# Personalização com os estilos liberados
# ---------------------------------------------------------------------------------------------

func _personalizacao() -> void:
	if not au._quer("r2a_personalizacao"):
		return
	au._f6b1_fim("Tati Gancho", true)
	au.gs.permanente["black_cat"] = {"legend": 40, "shown_level": 3, "scares": 10, "rounds": 10, "open_campaign": 3,
		"alley": {"tire": _ficha(1, 0, 5, true), "bike": _ficha(1, 0, 6, true), "gate": _ficha(1, 0, 7, true)}}
	await au._abrir()
	au._estado = "r2a_personalizacao"
	au._exigir(au.gs.receber_discipulo() and au.gs.sucessao_estado() == "creating", "r2a_personalizacao", "a sucessão abre na criação (%s)" % au.gs.sucessao_estado())
	var tela: Node = await au._f6b1_janela_criar()
	au._exigir(tela != null, "r2a_personalizacao", "a tela de criação abre")
	for campo in ["headband_color", "shorts_color", "socks"]:
		var ids: Array = au.gs.disciples.opcoes_ativas(campo)
		au._exigir(ids.size() > 0 and ids.back() in ["night", "night_wraps"], "r2a_personalizacao", "o estilo de %s é o último da lista (%s)" % [campo, str(ids)])
	au.gs.definir_rascunho("headband", "band")
	au.gs.definir_rascunho("headband_color", "night")
	au.gs.definir_rascunho("shorts_color", "night")
	au.gs.definir_rascunho("socks", "night_wraps")
	await au._esperar(0.6)
	var marcadas := 0
	for c in tela._campos:
		if (c.gato as Control).visible:
			marcadas += 1
	au._exigir(marcadas == 3, "r2a_personalizacao", "as 3 opções de estilo mostram o gato (%d)" % marcadas)
	await au._ver("r2a_personalizacao")
	_fim()


## Texto do jogo em MAIÚSCULAS (o mesmo que UiTema.txt; o auditor carrega antes do UiTema, por isso não o usa).
func _t(chave: String, padrao: String = "", vars: Dictionary = {}) -> String:
	return au.gs.preencher(au.gs.texto_ui(chave, padrao), vars).to_upper()
