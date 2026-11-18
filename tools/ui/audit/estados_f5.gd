extends RefCounted
## Estados do ui_audit.gd: Fases 5 e 5.1. Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).


var au


func _init(auditor) -> void:
	au = auditor


func _rodar_fase5() -> void:
	var nomes: Array = au.ESTADOS_TODOS.filter(func(n: String) -> bool: return n.begins_with("f5_"))
	var alguma := false
	for n in nomes:
		if au._quer(n):
			alguma = true
	if not alguma:
		return
	var forte := {"strength": 5.0e6, "agility": 5.0e6, "endurance": 5.0e6}

	# --- MUDAR: cartão em cada estado ---
	if au._quer("f5_mudar_travado"):
		au._novo_jogo()
		au.gs.indice_escada = 2
		await au._abrir()
		au._estado = "f5_mudar_travado"
		au._exigir(au.gs.estado_mudanca() == "locked" and au._botao_mudar() == null, au._estado, "sem cinturão o botão MUDAR não existe")
		await au._ver("f5_mudar_travado")
	if au._quer("f5_mudar_sem_dinheiro"):
		au._novo_jogo()
		au.gs.indice_escada = 4
		au.gs.cinturao = true
		au.gs.dinheiro = 300.0
		await au._abrir()
		au._estado = "f5_mudar_sem_dinheiro"
		au._exigir(au.gs.estado_mudanca() == "missing" and au._botao_mudar() != null and au._botao_mudar().disabled, au._estado, "MUDAR apagado sem dinheiro")
		await au._ver("f5_mudar_sem_dinheiro")
	if au._quer("f5_mudar_pronto") or au._quer("f5_arte_primeira") or au._quer("f5_academia_chegada") or au._quer("f5_academia_boxe"):
		au._novo_jogo()
		au.gs.indice_escada = 4
		au.gs.cinturao = true
		au.gs.dinheiro = 1000.0
		await au._abrir()
		au._estado = "f5_mudar_pronto"
		au._exigir(au.gs.estado_mudanca() == "ready" and au._botao_mudar() != null and not au._botao_mudar().disabled, au._estado, "MUDAR aceso com $1.000")
		au._exigir(au.gs.estado_escada() == "move", au._estado, "estado_escada deveria ser move")
		await au._ver("f5_mudar_pronto")
		var fl: Node = au._cena.get_node("Fluxo")
		au._botao_mudar().pressed.emit()
		await au._esperar(0.4)
		await au._pular_cena_academia()
		au._estado = "f5_mudar_fluxo"
		au._exigir(au.gs.local_id == "gym" and au.gs.dinheiro == 0.0, au._estado, "MUDAR deveria levar à academia e cobrar $1.000")
		au._exigir(fl.janela != null and fl.janela.has_method("_escolher") and au.gs.modal_aberto, au._estado, "a 1ª chegada deveria abrir a janela de arte")
		if au._quer("f5_arte_primeira"):
			await au._ver("f5_arte_primeira")
		# nada mais é possível enquanto a escolha está pendente
		au._exigir(au.gs.clicar().is_empty() and not au.gs.pode_lutar(), au._estado, "com a escolha pendente o clique e a luta ficam travados")
		fl.janela._escolher("boxing")
		await au._esperar(0.7)
		au._exigir(au.gs.arte_id == "boxing" and fl.janela == null and not au.gs.modal_aberto, au._estado, "escolher a arte fecha a janela e solta o modal")
		await au._ver("f5_academia_chegada")
		await au._esperar(1.0)
		await au._ver("f5_academia_boxe")
	if au._quer("f5_arte_ultima"):
		au._novo_jogo()
		au.gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		au.gs.permanente["last_art"] = "boxing"
		au.gs.permanente["career_number"] = 3
		await au._abrir()
		await au._esperar(0.4)
		au._estado = "f5_arte_ultima"
		var fj: Node = au._cena.get_node("Fluxo").janela
		au._exigir(fj != null and fj.has_method("_escolher"), au._estado, "ao abrir com a escolha pendente a janela deveria abrir")
		await au._ver("f5_arte_ultima")

	# --- Academia com cada arte, 4 botões de foco ---
	if au._quer("f5_gym_boxe_marca"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 3000.0)
		await au._abrir()
		au._estado = "f5_gym_boxe_marca"
		au._exigir(au.gs.estado_aparelho("speed_bag") == "buyable" and au.gs.estado_aparelho("grappling_dummy") == "absent", au._estado, "pera comprável, boneco ausente")
		au._exigir(au._marca_visivel("speed_bag") and not au._marca_visivel("grappling_dummy"), au._estado, "só a marca da pera")
		au._cena._apontar_compra("speed_bag")
		await au._esperar(0.3)
		await au._ver("f5_gym_boxe_marca")
	if au._quer("f5_gym_boneco_foco"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope", "grappling_dummy"], 3000.0, "grappling_dummy")
		au.gs.niveis_melhoria["grappling_dummy"] = 1
		await au._abrir()
		await au._esperar(0.3)
		au._exigir(not au._marca_visivel("grappling_dummy") and not au._marca_visivel("speed_bag"), "f5_gym_boneco_foco", "sem marcas")
		await au._ver("f5_gym_boneco_foco")
	if au._quer("f5_gym_pera_foco") or au._quer("f5_gym_pera_clique"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope", "speed_bag"], 3000.0, "speed_bag")
		await au._abrir()
		await au._esperar(0.3)
		await au._ver("f5_gym_pera_foco")
		if au._quer("f5_gym_pera_clique"):
			au.gs.clicar()
			await au._esperar(0.12)
			await au._ver("f5_gym_pera_clique")
	if au._quer("f5_gym_descanso"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope", "speed_bag"], 3000.0, "punching_bag")
		await au._abrir()
		await au._esperar(0.3)
		await au._ver("f5_gym_descanso")
	if au._quer("f5_garagem_boneco_marca"):
		au._novo_jogo()
		au._garagem_arte("bjj", ["treadmill"], 3000.0, "treadmill")
		await au._abrir()
		au._estado = "f5_garagem_boneco_marca"
		au._exigir(au._marca_visivel("grappling_dummy") and not au._marca_visivel("speed_bag"), au._estado, "só a marca do boneco")
		au._cena._apontar_compra("grappling_dummy")
		await au._esperar(0.3)
		await au._ver("f5_garagem_boneco_marca")
	if au._quer("f5_garagem_boneco_depois"):
		au._novo_jogo()
		au._garagem_arte("bjj", [], 0.0)
		await au._abrir()
		await au._ver("f5_garagem_boneco_depois")
	if au._quer("f5_garagem_pera_marca"):
		au._novo_jogo()
		au._garagem_arte("boxing", ["treadmill"], 3000.0, "treadmill")
		await au._abrir()
		await au._ver("f5_garagem_pera_marca")
	# Fase 5.1: a chegada com poeira acabou; comprar gera uma caixa e 3 cliques abrem (detalhes nos estados f51_caixa_*).
	if au._quer("f5_chegada_pera"):
		au._novo_jogo()
		au._garagem_arte("boxing", ["treadmill"], 3000.0, "treadmill")
		await au._abrir()
		var sala: Node = au._cena.get_node("Sala")
		au._exigir(au.gs.comprar_aparelho("speed_bag") and au.gs.estado_aparelho("speed_bag") == "boxed", "f5_chegada_pera", "comprar a pera cria a caixa")
		await au._esperar(0.5)
		await au._ver("f5_chegada_pera")
		for i in 3:
			au.gs.bater_caixa("speed_bag")
		await au._esperar(1.4)
		au._exigir(au.gs.foco == "speed_bag" and sala._pera.visible, "f5_chegada_pera", "depois da caixa a pera fica no foco")
	if au._quer("f5_chegada_boneco"):
		au._novo_jogo()
		au._garagem_arte("bjj", ["treadmill"], 3000.0, "treadmill")
		await au._abrir()
		var sala: Node = au._cena.get_node("Sala")
		au._exigir(au.gs.comprar_aparelho("grappling_dummy") and au.gs.estado_aparelho("grappling_dummy") == "boxed", "f5_chegada_boneco", "comprar o boneco cria a caixa")
		await au._esperar(0.5)
		await au._ver("f5_chegada_boneco")
		for i in 3:
			au.gs.bater_caixa("grappling_dummy")
		await au._esperar(1.4)
		au._exigir(au.gs.foco == "grappling_dummy", "f5_chegada_boneco", "depois da caixa o boneco fica no foco")
	if au._quer("f5_chip_jj_max"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0)
		au.gs.arte_segundos = 900.0
		await au._abrir()
		await au._esperar(1.2)
		au._exigir(not au._cena.get_node("BarraBaixo")._chip.visible, "f5_chip_jj_max", "Fase 5.1: o chip da arte saiu da tela (vai na dica do local)")
		await au._ver("f5_chip_jj_max")
	if au._quer("f5_teclas_arte"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope", "speed_bag"], 800.0, "punching_bag")
		await au._abrir()
		au._estado = "f5_teclas_arte"
		au._tecla(KEY_4, true)
		au._tecla(KEY_4, false)
		await au._esperar(0.2)
		au._exigir(au.gs.foco == "speed_bag", au._estado, "a tecla 4 deveria focar a pera")
		await au._ver("f5_teclas_arte")

	# --- LOJA: reserva da mudança ---
	if au._quer("f5_loja_reserva"):
		au._novo_jogo()
		au.gs.indice_escada = 4
		au.gs.cinturao = true
		au.gs.dinheiro = 1100.0
		await au._abrir()
		au._cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await au._esperar(0.3)
		au._estado = "f5_loja_reserva"
		au._exigir(au.gs.reserva_mudanca() > 0.0 and au.gs.loja_estado(900.0) == "reserve", au._estado, "a reserva da mudança deveria recusar o item")
		await au._ver("f5_loja_reserva")
	# --- Dica de aposentar, escada ---
	if au._quer("f5_dica_aposentar"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0)
		au.gs.atributos = {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
		au.gs.fama = 200
		await au._abrir()
		au.gs.segundos_campanha = float(au.gs.fight_day - 3) * au.gs._segundos_por_dia()  # Fase 5.3: faltam 2 dias
		await au._esperar(1.3)
		au._estado = "f5_dica_aposentar"
		au._exigir(bool(au.gs.dica_aposentar().show), au._estado, "a dica deveria estar no ar (perigo_gym 400 s)")
		await au._ver("f5_dica_aposentar")
	if au._quer("f5_escada_fim"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", au.gs.lutas.adversarios.size())
		await au._abrir()
		au._exigir(au.gs.estado_escada() == "end", "f5_escada_fim", "escada completa = end")
		await au._ver("f5_escada_fim")

	# --- Prévia e luta com os adversários da academia ---
	if au._quer("f5_previa_tonhao") or au._quer("f5_luta_tonhao"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0)
		au.gs.atributos = forte.duplicate()
		await au._abrir()
		var fluxo: Node = au._cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await au._esperar(0.5)
		au._exigir(str(au.gs.previa().get("art_fight_text", "")) != "", "f5_previa_tonhao", "a prévia deveria trazer o traço da arte")
		await au._ver("f5_previa_tonhao")
		if au._quer("f5_luta_tonhao"):
			fluxo.janela.lutar_pedido.emit()
			await au._esperar(0.3)
			await au._ver("f5_luta_tonhao")
	if au._quer("f5_previa_kid"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", 5)
		au.gs.atributos = forte.duplicate()
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.5)
		await au._ver("f5_previa_kid")
	if au._quer("f5_previa_kid_revanche"):
		au._novo_jogo()
		au._com_nos(["body_jab", "career_purse"], 40)
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", 5)
		au.gs.permanente["revenge_opponent"] = "opp_gym_2"
		au.gs.atributos = {"strength": 3.0e5, "agility": 5.0e5, "endurance": 9.0e5}
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.5)
		await au._ver("f5_previa_kid_revanche")

	# --- Vitória do cinturão com MUDAR ---
	if au._quer("f5_vitoria_cinturao_mudar"):
		au._novo_jogo()
		au.gs.indice_escada = 3
		au.gs.fama = 150
		au.gs.atributos = {"strength": 5.0e7, "agility": 5.0e7, "endurance": 5.0e7}
		au.gs.rng.seed = 7
		au.gs.lutar()
		await au._abrir()
		await au._esperar(0.7)
		await au._ver("f5_vitoria_cinturao_mudar")

	# --- Tela de fim: dica extra e ARTE no resumo ---
	if au._quer("f5_fim_dica_extra"):
		au._derrota_pendente([], 12)
		au.gs.arte_id = "boxing"
		au.gs.fim.summary["art"] = "boxing"
		au.gs.fim["opponent"] = "opp_gym_1"
		await au._abrir()
		await au._esperar(0.9)
		au._exigir(str(au.gs.textos_fim(au.gs.fim).get("tip_extra", "")) != "", "f5_fim_dica_extra", "textos_fim() sem tip_extra na derrota da academia")
		await au._ver("f5_fim_dica_extra")
	if au._quer("f5_fim_aposentou_cinturao"):
		au._novo_jogo()
		au.gs.indice_escada = 4
		au.gs.cinturao = true
		au.gs.fama = 340
		au.gs.aposentar()
		await au._abrir()
		await au._esperar(0.9)
		au._exigir(str(au.gs.textos_fim(au.gs.fim).get("tip_extra", "")) != "", "f5_fim_aposentou_cinturao", "tip_move_belt esperada")
		await au._ver("f5_fim_aposentou_cinturao")

	# --- NOVA CARREIRA volta para a garagem; a janela de arte vem antes do cartão ---
	if au._quer("f5_nova_carreira") or au._quer("f5_nova_carreira_cartao"):
		au._derrota_pendente(au.NOS_MISTA, 40)
		au.gs.local_id = "gym"
		au.gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		au.gs.permanente["last_art"] = "bjj"
		await au._abrir()
		await au._esperar(0.9)
		var fl: Node = au._cena.get_node("Fluxo")
		au.gs.nova_carreira()
		await au._esperar(0.7)
		au._estado = "f5_nova_carreira"
		au._exigir(au.gs.local_id == "garage" and au.gs.arte_id == "", au._estado, "NOVA CARREIRA volta para a garagem sem arte")
		au._exigir(fl.janela != null and fl.janela.has_method("_escolher") and fl.cartao == null, au._estado, "a janela de arte vem antes do cartão")
		await au._ver("f5_nova_carreira")
		fl.janela._escolher("bjj")
		await au._esperar(0.9)
		au._exigir(fl.janela == null and fl.cartao != null, au._estado, "depois da escolha o cartão aparece")
		await au._ver("f5_nova_carreira_cartao")


# ---------------------------------------------------------------------------------------------
# Fase 5.1: garagem clara (3 niveis de leitura), marcas sem texto, caixa da escola, corda no gancho, previa com respiro
# ---------------------------------------------------------------------------------------------

func _rodar_fase51() -> void:
	var nomes: Array = au.ESTADOS_TODOS.filter(func(n: String) -> bool: return n.begins_with("f51_"))
	var alguma := false
	for n in nomes:
		if au._quer(n):
			alguma = true
	if not alguma:
		return

	# --- Os 3 niveis: garagem e hovers dos itens escondidos ---
	if au._quer("f51_garagem") or au._quer("f51_hover_fama") or au._quer("f51_hover_legado") or au._quer("f51_hover_local") \
			or au._quer("f51_hover_proxima") or au._quer("f51_hover_teclas") or au._quer("f51_hover_atributo") or au._quer("f51_hover_assist"):
		au._novo_jogo()
		au.gs.fama = 12
		au.gs.dinheiro = 80.0
		await au._abrir()
		au._estado = "f51_garagem"
		au._exigir(not au._dica_inst().visible, au._estado, "sem hover nao existe dica na tela")
		await au._ver("f51_garagem")
		var hud: Node = au._cena.get_node("Hud")
		if au._quer("f51_hover_fama"):
			au._dica_em(au.gs.texto_ui("hint_fame") + "\n12", Vector2(520, 24))
			await au._esperar(0.1)
			await au._ver("f51_hover_fama")
			au._sem_dica()
		if au._quer("f51_hover_legado"):
			au._dica_em(au.gs.texto_ui("hint_legacy") + "\n" + str(au.gs.legado_em_jogo()), Vector2(480, 24))
			await au._esperar(0.1)
			await au._ver("f51_hover_legado")
			au._sem_dica()
		if au._quer("f51_hover_local"):
			au._dica_em(hud.texto_dica_local(), Vector2(380, 24))
			await au._esperar(0.1)
			await au._ver("f51_hover_local")
			au._sem_dica()
		if au._quer("f51_hover_proxima"):
			var bloco: Node = au._cena.get_node("PainelAtributos").find_children("*", "BlocoProxima", true, false)[0]
			au._dica_em(bloco._texto_premio(), Vector2(20, 130))
			await au._esperar(0.1)
			await au._ver("f51_hover_proxima")
			au._sem_dica()
		if au._quer("f51_hover_teclas"):
			au._dica_em(au.gs.texto_ui("hint_keys"), Vector2(250, 290))
			await au._esperar(0.1)
			await au._ver("f51_hover_teclas")
			au._sem_dica()
		if au._quer("f51_hover_atributo"):
			au._cena.get_node("PainelAtributos").mostrar_info({"titulo": "Agilidade", "texto": "Esquiva e velocidade.", "extra": "Compre a corda para treinar"})
			await au._esperar(0.1)
			await au._ver("f51_hover_atributo")
			au._cena.get_node("PainelAtributos").mostrar_info({})
		if au._quer("f51_hover_assist"):
			au._dica_em(au.gs.texto_ui("hint_assist"), Vector2(300, 250))
			await au._esperar(0.1)
			await au._ver("f51_hover_assist")
			au._sem_dica()
	if au._quer("f51_gym"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope", "speed_bag"], 3000.0, "speed_bag")
		au.gs.fama = 40
		au.gs.dinheiro = 400.0
		await au._abrir()
		await au._esperar(0.3)
		await au._ver("f51_gym")

	# --- Marcas de fita sem texto: normal, acesa (hover) e trancada ---
	if au._quer("f51_marcas") or au._quer("f51_marca_hover") or au._quer("f51_marca_trancada") or au._quer("f51_loja_trancado") or au._quer("f51_hover_foco"):
		au._novo_jogo()
		au.gs.treino = 700.0
		await au._abrir()
		au._estado = "f51_marcas"
		var sala: Node = au._cena.get_node("Sala")
		au._exigir(sala._marcas["treadmill"].fita.nome_sprite == "tape_mark_treadmill", au._estado, "esteira comprável: marca normal")
		au._exigir(sala._marcas["jump_rope"].fita.nome_sprite == "tape_mark_rope_dim" and sala._marcas["jump_rope"].cadeado.visible, au._estado,
			"corda trancada: marca _dim com cadeado")
		await au._ver("f51_marcas")
		if au._quer("f51_marca_hover"):
			sala._hover_em(Vector2(445, 267))
			au._dica_em(sala._texto_marca("treadmill"), Vector2(430, 200))
			au._exigir(sala._marcas["treadmill"].fita.nome_sprite == "tape_mark_treadmill_hi", "f51_marca_hover", "o mouse acende a marca _hi")
			await au._esperar(0.1)
			await au._ver("f51_marca_hover")
			sala._sair_hover()
			au._sem_dica()
		if au._quer("f51_marca_trancada"):
			sala._hover_em(Vector2(296, 166))
			au._dica_em(sala._texto_marca("jump_rope"), Vector2(250, 120))
			await au._esperar(0.1)
			await au._ver("f51_marca_trancada")
			sala._sair_hover()
			au._sem_dica()
		if au._quer("f51_loja_trancado"):
			var loja: Node = au._cena.get_node("PainelLoja")
			au._dica_em(loja._texto_recolhido("jump_rope"), Vector2(400, 150))
			await au._esperar(0.1)
			await au._ver("f51_loja_trancado")
			au._sem_dica()
		if au._quer("f51_hover_foco"):
			au._dica_em(au._cena.get_node("BarraBaixo")._texto_foco("jump_rope"), Vector2(300, 250))
			await au._esperar(0.1)
			await au._ver("f51_hover_foco")
			au._sem_dica()

	# --- A caixa: 0, 1 e 2 cliques, abrindo ---
	if au._quer("f51_caixa_0") or au._quer("f51_caixa_1") or au._quer("f51_caixa_2") or au._quer("f51_caixa_abrindo") or au._quer("f51_caixa_hover") \
			or au._quer("f51_caixa_aberta"):
		au._novo_jogo()
		au.gs.treino = 3000.0
		for g in au.gs.dados.geradores:
			au.gs.geradores[g.id] = 0  # sem renda passiva: o saldo de Treino só mexe se o clique da caixa treinar
		await au._abrir()
		au._estado = "f51_caixa_0"
		var sala: Node = au._cena.get_node("Sala")
		au._exigir(au.gs.comprar_aparelho("treadmill"), au._estado, "comprar a esteira deveria criar a caixa")
		await au._esperar(0.6)
		au._exigir(au.gs.tem_caixa("treadmill") and sala._caixas.has("treadmill") and not au.gs.aparelho_montado("treadmill"), au._estado,
			"a caixa da esteira deveria estar na sala e o aparelho nao montado")
		await au._ver("f51_caixa_0")
		var tr0: float = au.gs.treino
		if au._quer("f51_caixa_hover"):
			sala._hover_em(Vector2(445, 250))
			await au._esperar(0.1)
			au._exigir(au._dica_inst().visible, "f51_caixa_hover", "a caixa da a dica no hover")
			await au._ver("f51_caixa_hover")
			sala._sair_hover()
		sala._clique_em(Vector2(445, 250))  # clique de mouse na caixa
		await au._esperar(0.3)
		au._exigir(au.gs.cliques_faltando("treadmill") == 2 and au.gs.treino == tr0, "f51_caixa_1", "1 clique: faltam 2 e o clique nao treina")
		await au._ver("f51_caixa_1")
		sala._clique_em(Vector2(445, 250))
		await au._esperar(0.3)
		au._exigir(au.gs.cliques_faltando("treadmill") == 1, "f51_caixa_2", "2 cliques: falta 1")
		await au._ver("f51_caixa_2")
		sala._clique_em(Vector2(445, 250))
		await au._esperar(0.12)
		au._exigir(au.gs.aparelho_montado("treadmill") and au.gs.foco == "treadmill" and not au.gs.tem_caixa("treadmill"), "f51_caixa_abrindo",
			"3 cliques abrem: aparelho montado e foco nele")
		await au._ver("f51_caixa_abrindo")
		await au._esperar(1.3)
		au._exigir(not sala._caixas.has("treadmill") or not is_instance_valid(sala._caixas["treadmill"]) or sala._caixas["treadmill"].is_queued_for_deletion(),
			"f51_caixa_aberta", "a caixa vazia some em ate 1,5 s")
		await au._ver("f51_caixa_aberta")
	if au._quer("f51_caixas_varias") or au._quer("f51_caixa_luva") or au._quer("f51_corda_gancho") or au._quer("f51_caixa_sem_espaco") or au._quer("f51_caixa_janela"):
		au._novo_jogo()
		au.gs.treino = 6000.0
		au.gs.dinheiro = 400.0
		au.gs.aparelhos_montados_ids = ["punching_bag", "treadmill"]
		await au._abrir()
		var sala2: Node = au._cena.get_node("Sala")
		au._exigir(au.gs.comprar_aparelho("jump_rope"), "f51_caixas_varias", "comprar a corda")
		au._exigir(au.gs.comprar_luva(), "f51_caixas_varias", "comprar a luva")
		await au._esperar(0.7)
		au._estado = "f51_caixas_varias"
		au._exigir(au.gs.caixas().size() == 2 and sala2._caixas.size() == 2, au._estado, "duas caixas lado a lado")
		var r1: Rect2 = sala2._caixas["jump_rope"].area()
		var r2: Rect2 = sala2._caixas["glove_l1"].area()
		au._exigir(not r1.intersects(r2), au._estado, "caixas nao se sobrepoem")
		var alvo := Rect2(312, 182, 48, 90)
		au._exigir(not r1.grow(8.0).intersects(alvo) and not r2.grow(8.0).intersects(alvo), au._estado, "caixas a 8 px ou mais do alvo")
		await au._ver("f51_caixas_varias")
		if au._quer("f51_caixa_sem_espaco"):
			au._tecla(KEY_SPACE, true)
			au._tecla(KEY_SPACE, false)
			await au._esperar(0.2)
			au._exigir(au.gs.cliques_faltando("jump_rope") == 3 and au.gs.cliques_faltando("glove_l1") == 3, "f51_caixa_sem_espaco", "Espaco nunca bate em caixa")
		if au._quer("f51_caixa_janela"):
			sala2.janela_aberta = true
			sala2._clique_em(sala2._caixas["jump_rope"].area().get_center())
			au._exigir(au.gs.cliques_faltando("jump_rope") == 3, "f51_caixa_janela", "com janela aberta o clique nao vai para a caixa")
			sala2.janela_aberta = false
		if au._quer("f51_caixa_luva") or au._quer("f51_corda_gancho"):
			var pl: Vector2 = sala2._caixas["glove_l1"].area().get_center()
			var pc: Vector2 = sala2._caixas["jump_rope"].area().get_center()
			for i in 2:
				sala2._clique_em(pl)
				await au._esperar(0.2)
			await au._ver("f51_caixa_luva")
			sala2._clique_em(pl)
			await au._esperar(0.25)
			au._exigir(au.gs.luvas_abertas() == 1 and not au.gs.tem_caixa("glove_l1"), "f51_caixa_luva", "3 cliques abrem a luva")
			await au._ver("f51_caixa_luva_aberta")
			for i in 3:
				sala2._clique_em(pc)
				await au._esperar(0.2)
			await au._esperar(1.4)
			au._exigir(au.gs.aparelho_montado("jump_rope") and au.gs.foco == "jump_rope", "f51_corda_gancho", "corda montada e em foco")
			au.gs.definir_foco("punching_bag")
			await au._esperar(0.3)
			au._exigir(sala2._corda_prego.visible and sala2._corda_prego.position == Vector2(296, 166), "f51_corda_gancho",
				"corda pendurada no gancho (296,166): %s" % str(sala2._corda_prego.position))
			await au._ver("f51_corda_gancho")
	if au._quer("f51_caixa_persiste"):
		au._novo_jogo()
		au.gs.treino = 3000.0
		await au._abrir()
		au.gs.comprar_aparelho("treadmill")
		au.gs.bater_caixa("treadmill")
		au.gs.bater_caixa("treadmill")
		await au._esperar(0.3)
		var snap: Dictionary = au.gs.para_save()
		await au._abrir()  # recarrega a cena
		au.gs.aplicar_save(snap.duplicate(true))
		await au._esperar(0.5)
		au._estado = "f51_caixa_persiste"
		var sala3: Node = au._cena.get_node("Sala")
		au._exigir(sala3._caixas.has("treadmill") and sala3._caixas["treadmill"].batidas == 2, au._estado, "a caixa com 2 cliques volta igual")
		await au._ver("f51_caixa_persiste")

	# --- As 3 animacoes novas na sala: soco no saco, corrida na esteira, equipe ---
	if au._quer("f51_anim_saco") or au._quer("f51_anim_esteira"):
		au._novo_jogo()
		au._com_aparelhos(["treadmill"], 3000.0, "punching_bag")
		await au._abrir()
		var sala4: Node = au._cena.get_node("Sala")
		if au._quer("f51_anim_saco"):
			for i in 5:
				au.gs.clicar()
				await au._esperar(0.09)
				au._exigir(sala4._lutador.nome_sprite.begins_with("fighter_"), "f51_anim_saco", "o lutador toca um golpe do combo: " + sala4._lutador.nome_sprite)
				if i == 4:
					await au._ver("f51_anim_saco")
		if au._quer("f51_anim_esteira"):
			au.gs.definir_foco("treadmill")
			await au._esperar(0.3)
			au.gs.clicar()
			await au._esperar(0.15)
			au._exigir(sala4._lutador.nome_sprite.begins_with("fighter_run") and sala4._esteira.esta_tocando(), "f51_anim_esteira", "lutador e esteira correm juntos")
			await au._ver("f51_anim_esteira")

	# --- Previa com respiro ---
	if au._quer("f51_previa"):
		au._novo_jogo()
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.6)
		await au._ver("f51_previa")


# ---------------------------------------------------------------------------------------------
# Fase 5.2: luvas L3/L4 e Grito da equipe na LOJA, evento dourado por tipo (luva x7 / bolsa), 3 desvios da 5.1
# ---------------------------------------------------------------------------------------------
