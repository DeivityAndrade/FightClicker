extends RefCounted
## Estados do ui_audit.gd: Fases 6b2 e 6c1. Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).


var au


func _init(auditor) -> void:
	au = auditor


func _rodar_fase6b2() -> void:
	# --- Tela de criação: 10 linhas em 2 colunas, linhas apagadas, nome longo, visual cheio ---
	if au._quer("f6b2_criar") or au._quer("f6b2_criar_apagadas") or au._quer("f6b2_criar_nome14") or au._quer("f6b2_criar_cheio") or au._quer("f6b2_mentor2_chegada"):
		au._f6b1_fim("Tati Gancho", true)
		await au._abrir()
		await au._esperar(0.5)
		au._exigir(au.gs.receber_discipulo() and au.gs.sucessao_estado() == "creating", "f6b2_criar", "a sucessão abre na criação (%s)" % au.gs.sucessao_estado())
		var t: Node = await au._f6b1_janela_criar()
		au._exigir(t != null, "f6b2_criar", "a tela de criação deveria abrir")
		await au._esperar(0.6)
		if t == null:
			return
		var linhas: Array = au.gs.linhas_tela_criacao()
		au._exigir(linhas.size() == 10 and t._campos.size() == 9, "f6b2_criar", "10 linhas (nome + 9) na tela: %d / %d" % [linhas.size(), t._campos.size()])
		au._exigir(t._janela.size.x > 500.0 and t._janela.size.x <= 600.0, "f6b2_criar", "a janela tem 2 colunas: %s" % str(t._janela.size))
		for c in t._campos:
			if str(c.kind) == "text":
				for id in au.gs.disciples.opcoes_ativas(str(c.campo)):
					var nome_op: String = _tema().txt("disc_opt_%s_%s" % [c.campo, id])
					au._exigir(_tema().largura_visivel(nome_op) <= t.LARG_VALOR - 8.0, "f6b2_criar", "'%s' cabe ao lado das setas (%.0f px)" % [nome_op, _tema().largura_visivel(nome_op)])
		await au._ver("f6b2_criar")
		if au._quer("f6b2_criar_apagadas"):
			au.gs.definir_rascunho("top_color", "green")
			au.gs.definir_rascunho("headband_color", "blue")
			au.gs.definir_rascunho("top", "none")
			au.gs.definir_rascunho("headband", "none")
			await au._esperar(0.3)
			var ap := {}
			for l in au.gs.linhas_tela_criacao():
				ap[str(l.field)] = bool(l.apagada)
			au._exigir(bool(ap.get("top_color")) and bool(ap.get("headband_color")), "f6b2_criar_apagadas", "as linhas de cor ficam apagadas com a peça em SEM")
			t._trocar("top_color", 1)
			au._exigir(str(au.gs.rascunho().look.top_color) == "green", "f6b2_criar_apagadas", "a seta da linha apagada não faz nada")
			await au._ver("f6b2_criar_apagadas")
			au.gs.definir_rascunho("top", "tank")
			await au._esperar(0.3)
			au._exigir(str(au.gs.rascunho().look.top_color) == "green", "f6b2_criar_apagadas", "ligando a peça, a cor guardada volta")
		if au._quer("f6b2_criar_nome14"):
			au.gs.definir_rascunho("name", "MMMMMMMMMMMMMMMMMM")
			au.gs.definir_rascunho("top", "tee")
			au.gs.definir_rascunho("hair_style", "bun")
			await au._esperar(0.3)
			au._exigir(t._nome.text.length() == 14, "f6b2_criar_nome14", "o nome corta em 14 letras (%d)" % t._nome.text.length())
			await au._ver("f6b2_criar_nome14")
		if au._quer("f6b2_criar_cheio"):
			for campo in au._look_6b2():
				au.gs.definir_rascunho(str(campo), str(au._look_6b2()[campo]))
			await au._esperar(0.3)
			await au._ver("f6b2_criar_cheio")
		# A chegada curta com o 2º mentor: quem acabou de passar o posto já está parado no canto, olhando.
		if au._quer("f6b2_mentor2_chegada"):
			au.gs.definir_rascunho("name", "Zeca Chave")
			t._confirmar()
			au._exigir(au.gs.sucessao_estado() == "arriving", "f6b2_mentor2_chegada", "CONFIRMAR leva à chegada curta (%s)" % au.gs.sucessao_estado())
			var sala_c: Node = au._cena.get_node("Sala")
			await au._esperar(0.9)
			au._exigir(sala_c.mentor2_visivel() and sala_c.mentor_visivel(), "f6b2_mentor2_chegada", "na chegada o 2º mentor e o John estão na sala")
			await au._ver("f6b2_mentor2_chegada")
			await au._esperar(0.6)
			await au._ver("f6b2_mentor2_chegada_b")
			for i in 40:
				if au.gs.sucessao_estado() == "none":
					break
				await au._esperar(0.1)
			au._exigir(sala_c.mentor2_visivel(), "f6b2_mentor2_chegada", "depois da chegada o 2º mentor continua no canto")

	# --- Os 4 cortes, na garagem, com o visual cheio ---
	if au._quer("f6b2_cortes"):
		au._f6b2_jogo(au._look_6b2({"hair_style": "buzz"}))
		await au._abrir()
		await au._esperar(0.5)
		for estilo in ["buzz", "short", "volume", "bun"]:
			au.gs.discipulo.look["hair_style"] = estilo
			await au._esperar(0.35)
			await au._ver("f6b2_cortes_" + estilo)

	# --- Partes de cima (regata, camiseta, sem) e cores, na garagem ---
	if au._quer("f6b2_partes"):
		au._f6b2_jogo(au._look_6b2({"top": "tank", "headband": "none", "socks": "none"}))
		await au._abrir()
		await au._esperar(0.5)
		for caso in [["tank", "gray"], ["tee", "gray"], ["tank", "black"], ["tee", "yellow"], ["none", "gray"]]:
			au.gs.discipulo.look["top"] = caso[0]
			au.gs.discipulo.look["top_color"] = caso[1]
			await au._esperar(0.35)
			await au._ver("f6b2_partes_%s_%s" % caso)

	# --- Faixa (cores) e meião (cor do calção) ---
	if au._quer("f6b2_faixa_meiao"):
		au._f6b2_jogo(au._look_6b2({"hair_style": "short", "top": "none", "headband": "band", "headband_color": "red", "socks": "on"}))
		await au._abrir()
		await au._esperar(0.5)
		for caso in [["red", "blue", "on"], ["white", "blue", "on"], ["green", "yellow", "on"], ["black", "purple", "on"], ["red", "green", "none"]]:
			au.gs.discipulo.look["headband_color"] = caso[0]
			au.gs.discipulo.look["shorts_color"] = caso[1]
			au.gs.discipulo.look["socks"] = caso[2]
			await au._esperar(0.35)
			await au._ver("f6b2_faixa_meiao_%s_%s_%s" % caso)

	# --- Visual cheio na luta ---
	if au._quer("f6b2_luta_cheio"):
		await au._f6b2_luta("f6b2_luta_cheio", au._look_6b2())
	if au._quer("f6b2_luta_regata"):
		await au._f6b2_luta("f6b2_luta_regata", au._look_6b2({"top": "tank", "top_color": "black", "hair_style": "volume", "headband_color": "red", "socks": "none", "skin": "skin_1"}))

	# --- Segundo mentor ---
	if au._quer("f6b2_mentor2") or au._quer("f6b2_mentor2_dica") or au._quer("f6b2_mentor2_balao_osmar") or au._quer("f6b2_mentor2_balao_john"):
		au._f6b2_jogo(au._look_6b2(), au.LOOK_MENTOR_6B2)
		for g in au.gs.dados.geradores:
			au.gs.geradores[g.id] = 10  # garagem cheia
		await au._abrir()
		await au._esperar(0.6)
		var sala_m: Node = au._cena.get_node("Sala")
		au._estado = "f6b2_mentor2"
		au._exigir(sala_m.mentor2_visivel(), au._estado, "o 2º mentor está na garagem")
		au._exigir(sala_m._mentor2.position == sala_m.ponto_mentor2(), au._estado, "pés em mentor_2_spot: %s" % str(sala_m._mentor2.position))
		au._exigir(sala_m._mentor2.nome_sprite == "disciple_stand_bare" and sala_m._mentor2.texture != null, au._estado, "pose stand_bare virada para o saco: %s" % sala_m._mentor2.nome_sprite)
		au._exigir(sala_m._mentor2.texture != _tema().textura("disciple_stand_bare"), au._estado, "ele usa o visual guardado no roster (camadas e cores)")
		await au._ver("f6b2_mentor2")
		if au._quer("f6b2_mentor2_dica"):
			sala_m._hover_em(Vector2(62, 240))  # 6d2: o 2º mentor ficou em (62,256)
			await au._esperar(0.1)
			var di: Control = au._dica_inst()
			var rd := Rect2(di.position, di.size)
			au._exigir(au.UTIL_6A.encloses(rd), "f6b2_mentor2_dica", "a dica fica dentro da sala: %s" % au._fmt(rd))
			au._exigir(not rd.intersects(au.NO_COVER_6A), "f6b2_mentor2_dica", "a dica não cobre o alvo: %s" % au._fmt(rd))
			var cab: Array = [sala_m.cabeca_mentor2(), sala_m.ponto_cabeca("coach"), sala_m.ponto_cabeca("first"), sala_m.cabeca_mentor()]
			for h in cab:
				au._exigir(not rd.intersects(Rect2(h.x - 9.0, h.y, 18.0, 18.0)), "f6b2_mentor2_dica", "a dica cobre a cabeça de alguém: %s x %s" % [au._fmt(rd), str(h)])
			au._exigir(rd.end.y <= sala_m.cabeca_mentor2().y, "f6b2_mentor2_dica", "a dica fica acima da cabeça do 2º mentor: %s" % au._fmt(rd))
			au._exigir(au._dica_inst().texto_atual() == "BETO CRUZ: JÁ PASSOU O POSTO.", "f6b2_mentor2_dica", "dica do 2º mentor: %s" % au._dica_inst().texto_atual())
			await au._ver("f6b2_mentor2_dica")
			sala_m._hover_em(Vector2(500, 120))
			au._exigir(au._dica_inst().texto_atual() == "", "f6b2_mentor2_dica", "a dica some ao sair de cima dele")
			au._sem_dica()
		if au._quer("f6b2_mentor2_balao_osmar"):
			await au._falar("coach", "chegou outro aviso, john.\nainda é nossa, viu?")
			au._checar_balao("f6b2_mentor2_balao_osmar", "coach")
			await au._ver("f6b2_mentor2_balao_osmar")
			au._balao().fechar_agora()
			await au._esperar(0.2)
		if au._quer("f6b2_mentor2_balao_john"):
			var cu2: Node = au._cena_ui()
			cu2._falar({"ator": "first", "line": "t", "text": "vamos ver sua guarda.", "seconds": 4.0})
			await au._esperar(0.2)
			au._balao().completar()
			await au._esperar(0.1)
			au._exigir(au._balao().ativo(), "f6b2_mentor2_balao_john", "o balão do John sentado deveria aparecer")
			au._checar_balao_6b1("f6b2_mentor2_balao_john", "first")
			await au._ver("f6b2_mentor2_balao_john")
			au._balao().fechar_agora()

	# --- Na cena grande (primeira_sucessao) ele não aparece ---
	if au._quer("f6b2_mentor2_cena"):
		au._f6b1_fim("Tati Gancho")
		await au._abrir()
		await au._esperar(0.6)
		var sala_g: Node = au._cena.get_node("Sala")
		au.gs.receber_discipulo()
		await au._esperar(1.2)
		au._exigir(not sala_g.mentor2_visivel(), "f6b2_mentor2_cena", "durante a cena grande o 2º mentor não aparece")
		await au._ver("f6b2_mentor2_cena")


## UiTema só carrega depois dos autoloads: o verificador a pega pelo caminho, na hora de usar.
func _tema() -> GDScript:
	return load("res://ui/ui_tema.gd")

# ---------------------------------------------------------------------------------------------
# Fase 6c1: casa nova
# ---------------------------------------------------------------------------------------------

## Carreira 3 (John sentado, ultimo em pe) com o cinturao e dinheiro: pronto para MUDAR.
func _f6c1_preparar() -> void:
	au._novo_jogo()
	while au.gs.numero_carreira() < 3:
		au.gs.aposentar()
		au.gs.receber_discipulo()
		au.gs.sucessao_tela_aberta()
		au.gs.confirmar_discipulo()
		au.gs.sucessao_terminou()
	au.gs.indice_escada = 4
	au.gs.cinturao = true
	au.gs.dinheiro = 1.0e6


func _rodar_fase6c1() -> void:
	if not (au._quer("f6c1_chegada_cena") or au._quer("f6c1_chegada_2x") or au._quer("f6c1_academia_cheia") or au._quer("f6c1_saida")):
		return
	_f6c1_preparar()
	await au._abrir()
	await au._esperar(0.5)
	au._exigir(au.gs.mudar(), "f6c1_chegada_cena", "MUDAR para a academia")
	await au._esperar(3.2)
	var cu: Node = au._cena_ui()
	au._exigir(au.gs.cena_sala == "primeira_academia" and cu._botao.visible, "f6c1_chegada_cena", "a cena toca com o botao PULAR (%s)" % au.gs.cena_sala)
	await au._ver("f6c1_chegada_cena")
	await au._esperar(2.7)  # A4: corte para 2x
	await au._ver("f6c1_chegada_2x")
	cu.player.pular()
	await au._esperar(0.9)
	var fl: Node = au._cena.get_node("Fluxo")
	if fl.janela != null and fl.janela.has_method("_escolher"):
		fl.janela._escolher(au.gs.academia.ids_artes()[0])
	await au._esperar(2.0)
	au._estado = "f6c1_academia_cheia"
	var sala: Node = au._cena.get_node("Sala")
	au._exigir(au.gs.cena_sala == "" and sala._osmar.visible and sala.mentor_visivel() and sala.mentor2_visivel() and sala._caixote.visible, au._estado, "academia: Osmar, John no caixote e o ultimo em pe")
	await au._ver("f6c1_academia_cheia")
	# Saida do John: 1a vitoria na academia arma, o 1o momento calmo toca.
	au.gs._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
	var t := 0.0
	while not au.gs.saida_tocando() and t < 25.0:
		await au._esperar(0.25)
		t += 0.25
	au._estado = "f6c1_saida"
	au._exigir(au.gs.saida_tocando() and not cu._botao.visible, au._estado, "a saida toca sem botao PULAR e sem prender o controle")
	await au._esperar(6.0)
	await au._ver("f6c1_saida")

const F6C1_QUADROS := [["J1", 0.8], ["J2", 2.2], ["J3", 1.9], ["J4", 1.1], ["J5", 4.8], ["J6", 2.2], ["J7", 2.5]]


func _f6c1_algum(prefixo: String) -> bool:
	for q in F6C1_QUADROS:
		if au._quer(prefixo + q[0]):
			return true
	return false


## Osmar e os mentores com balao na academia; a saida do John quadro a quadro na academia e na garagem.
func _rodar_fase6c1_extra() -> void:
	var quer_gym := _f6c1_algum("f6c1_saida_gym_")
	var quer_gar := _f6c1_algum("f6c1_saida_gar_")
	var quer_bal = au._quer("f6c1_academia_balao_osmar") or au._quer("f6c1_academia_balao_john")
	if not (quer_gym or quer_gar or quer_bal):
		return
	if quer_bal or quer_gym:
		_f6c1_preparar()
		await au._abrir()
		await au._esperar(0.5)
		au.gs.mudar()
		await au._esperar(0.4)
		await au._pular_cena_academia()
		var fl: Node = au._cena.get_node("Fluxo")
		if fl.janela != null and fl.janela.has_method("_escolher"):
			fl.janela._escolher(au.gs.academia.ids_artes()[0])
		await au._esperar(1.5)
		var sala: Node = au._cena.get_node("Sala")
		if au._quer("f6c1_academia_balao_osmar"):
			await au._falar("coach", "agora sim. essa parede e nossa.")
			au._checar_balao("f6c1_academia_balao_osmar", "coach")
			await au._ver("f6c1_academia_balao_osmar")
			au._balao().fechar_agora()
			await au._esperar(0.2)
		if au._quer("f6c1_academia_balao_john"):
			var cu: Node = au._cena_ui()
			cu._falar({"ator": "first", "line": "t", "text": "vamos ver sua guarda.", "seconds": 4.0})
			await au._esperar(0.2)
			au._balao().completar()
			await au._esperar(0.1)
			au._exigir(sala.mentor_visivel(), "f6c1_academia_balao_john", "John no caixote da academia")
			await au._ver("f6c1_academia_balao_john")
			au._balao().fechar_agora()
			await au._esperar(0.2)
		if quer_gym:
			await _f6c1_saida_quadros("f6c1_saida_gym_")
	if quer_gar:
		_f6c1_preparar()
		await au._abrir()
		await au._esperar(0.6)
		await _f6c1_saida_quadros("f6c1_saida_gar_")


func _f6c1_saida_quadros(prefixo: String) -> void:
	au._estado = prefixo + "J1"
	au.gs._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
	var t := 0.0
	while not au.gs.saida_tocando() and t < 25.0:
		await au._esperar(0.25)
		t += 0.25
	au._exigir(au.gs.saida_tocando(), au._estado, "a saida foi pedida")
	var sala: Node = au._cena.get_node("Sala")
	for q in F6C1_QUADROS:
		await au._esperar(float(q[1]))
		au._estado = prefixo + str(q[0])
		if au._quer(au._estado):
			if str(q[0]) in ["J4", "J5"]:
				if au._balao().ativo():
					au._balao().completar()
					await au._esperar(0.1)
					au._checar_balao_6b1(au._estado, str(au._balao().speaker))
			await au._ver(au._estado)
	t = 0.0
	while au.gs.saida_tocando() and t < 6.0:
		await au._esperar(0.25)
		t += 0.25
	au._exigir(not au.gs.saida_tocando() and sala._mentor_quem == "last" and not sala.mentor2_visivel(), au._estado, "depois da saida o ultimo senta e o ponto em pe fica vazio")

# ---------------------------------------------------------------------------------------------
# Fase 6c2: mural, Honra, hall, falas dos mentores e simbolo da escola
# ---------------------------------------------------------------------------------------------
