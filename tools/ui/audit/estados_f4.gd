extends RefCounted
## Estados do ui_audit.gd: Fases 4 e 4b. Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).


var au


func _init(auditor) -> void:
	au = auditor


func _rodar_fase4() -> void:
	var adv0: String = str(au.gs.lutas.adversarios[0].id)
	var fracos := {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
	if au._quer("garagem_metronomo"):
		au._novo_jogo()
		au._com_nos(au.NOS_MISTA, 12)
		au.gs.nivel_metronomo = 2
		au.gs.dinheiro = 200.0
		await au._abrir()
		await au._esperar(1.2)  # deixa o Metrônomo dar uns socos (número leve, sem tremida)
		await au._ver("garagem_metronomo")
	if au._quer("garagem_loja_metronomo"):
		au._novo_jogo()
		au.gs.nivel_metronomo = 1
		au.gs.dinheiro = 100.0
		await au._abrir()
		au._cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await au._esperar(0.3)
		await au._ver("garagem_loja_metronomo")
	if au._quer("garagem_loja_metronomo_max"):
		au._novo_jogo()
		au.gs.nivel_metronomo = au.gs.metronomo_niveis()
		au.gs.dinheiro = 5000.0
		await au._abrir()
		au._cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await au._esperar(0.3)
		await au._ver("garagem_loja_metronomo_max")
	if au._quer("garagem_dica_nos"):
		au._novo_jogo()
		au._com_nos(au.NOS_TODOS, 0)
		await au._abrir()
		au._cena.get_node("Hud")._abrir_dica_nos()
		await au._esperar(0.2)
		await au._ver("garagem_dica_nos")
	if au._quer("garagem_revanche"):
		au._novo_jogo()
		au._com_nos(["body_jab", "career_purse"], 40)
		au.gs.permanente["revenge_opponent"] = adv0
		au.gs.atributos = fracos.duplicate()
		await au._abrir()
		au.gs.atualizar_risco_hud()
		await au._esperar(0.3)
		if not bool(au.gs.info_proxima().get("wait_green", false)):
			au._problema("AUDIT", "estado garagem_revanche", "esperava wait_green=true (risco não é verde); ajuste os atributos do estado")
		await au._ver("garagem_revanche")
	if au._quer("cartao_inicio"):
		au._novo_jogo()
		au._com_nos(au.NOS_MISTA, 12)
		await au._abrir()
		au._cena.get_node("Fluxo")._ao_nova_carreira_iniciada(au.gs.cartao_inicio())
		await au._esperar(0.4)
		if not au.gs.modal_aberto:
			au._problema("AUDIT", "estado cartao_inicio", "o cartão deveria ter chamado definir_modal(true)")
		await au._ver("cartao_inicio")
		await au._esperar(1.6)
		if au.gs.modal_aberto:
			au._problema("AUDIT", "estado cartao_inicio", "o cartão sumiu mas o modal continua aberto")
	if au._quer("cartao_clique_fecha"):
		# O cartão aberto: clique no alvo central só fecha o cartão (não treina); o Espaço também só fecha.
		au._novo_jogo()
		au._com_nos(au.NOS_MISTA, 12)
		await au._abrir()
		var fl: Node = au._cena.get_node("Fluxo")
		fl._ao_nova_carreira_iniciada(au.gs.cartao_inicio())
		await au._esperar(0.3)
		var cliques := [0]
		au.gs.clicou.connect(func(_a, _b, _c, _d, _e) -> void: cliques[0] += 1)
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = Vector2(336, 222) * 2.0  # janela 1280x720 = base x2  # alvo central, fora do cartão
		ev.global_position = ev.position
		ev.pressed = true
		Input.parse_input_event(ev)
		await au._esperar(0.2)
		if cliques[0] > 0:
			au._problema("AUDIT", "estado cartao_clique_fecha", "clique no alvo com o cartão aberto treinou")
		if fl.cartao != null:
			au._problema("AUDIT", "estado cartao_clique_fecha", "o clique não fechou o cartão")
		# Espaço com o cartão aberto: só fecha.
		fl._ao_nova_carreira_iniciada(au.gs.cartao_inicio())
		await au._esperar(0.3)
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_SPACE
		tecla.pressed = true
		Input.parse_input_event(tecla)
		await au._esperar(0.2)
		if cliques[0] > 0:
			au._problema("AUDIT", "estado cartao_clique_fecha", "Espaço com o cartão aberto treinou")
		if fl.cartao != null:
			au._problema("AUDIT", "estado cartao_clique_fecha", "o Espaço não fechou o cartão")
		await au._ver("cartao_clique_fecha")
	if au._quer("hud_legado_grande"):
		# HUD no pior caso de largura: números enormes, Legado de 5 dígitos e o emblema de nós ao lado de CARREIRA.
		au._novo_jogo()
		au._com_nos(au.NOS_TODOS, 0)
		au.gs.treino = 987654321012345.0
		au.gs.dinheiro = 98765432101.0
		au.gs.fama = 49950  # Legado em jogo = 99900
		await au._abrir()
		await au._ver("hud_legado_grande")
	if au._quer("previa_revanche"):
		au._novo_jogo()
		au._com_nos(["body_jab", "career_purse"], 40)
		au.gs.permanente["revenge_opponent"] = adv0
		au.gs.atributos = fracos.duplicate()
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.5)
		if au._quer("previa_revanche"):
			await au._ver("previa_revanche")
	if au._quer("previa_revanche_porcentagem"):
		au._novo_jogo()
		au._com_nos(["body_jab", "career_purse", "career_scouting", "career_crowd", "career_good_loser"], 40)
		au.gs.permanente["revenge_opponent"] = adv0
		au.gs.atributos = fracos.duplicate()
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.5)
		await au._ver("previa_revanche_porcentagem")

	# Vitória com revanche (o algoz é o 1º adversário; o jogador é forte e vence)
	if au._quer("vitoria_revanche"):
		au._novo_jogo()
		au._com_nos(["body_jab", "career_purse", "career_crowd"], 0)
		au.gs.permanente["revenge_opponent"] = adv0
		au.gs.atributos = {"strength": 5.0e7, "agility": 5.0e7, "endurance": 5.0e7}
		au.gs.rng.seed = 7
		au.gs.lutar()
		await au._abrir()
		await au._esperar(0.9)
		await au._ver("vitoria_revanche")

	# Tela de fim com a dica do verde (derrota que não é azar) e o botão ÁRVORE com Legado para gastar
	if au._quer("fim_derrota_verde"):
		au._derrota_pendente([], 12)
		au.gs.fim["legacy_total"] = 12
		await au._abrir()
		await au._esperar(0.9)
		var tx: Dictionary = au.gs.textos_fim(au.gs.fim)
		if str(tx.get("wait_green", "")) == "":
			au._problema("AUDIT", "estado fim_derrota_verde", "textos_fim() sem wait_green numa derrota que não é azar")
		await au._ver("fim_derrota_verde")

	# Números de dano na arena: dois golpes no mesmo ponto não podem se encavalar
	if au._quer("luta_numeros"):
		var achada = au._achar_luta(true, true)
		au._novo_jogo()
		au.gs.atributos = achada.atr
		await au._abrir()
		au.gs.rng.seed = int(achada.k)
		var fluxo: Node = au._cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await au._esperar(0.3)
		fluxo.janela.lutar_pedido.emit()
		await au._esperar(0.25)
		var tela: Node = fluxo.tela
		tela._clock = 3.0
		await au._esperar(0.3)
		var p := Vector2(330, 250)
		tela._numero_de_dano(757800.0, "crit", false, p)
		tela._numero_de_dano(2400.0, "hit", false, p)
		tela._numero_de_dano(2500.0, "hit", false, p + Vector2(4, 0))
		tela._numero_de_dano(310.0, "counter", false, p + Vector2(-6, 2))
		await au._esperar(0.05)
		au._estado = "luta_numeros"
		var vivos: Array = []
		for n in tela._numeros:
			if n.ativo:
				vivos.append(n)
		for i in vivos.size():
			for k in range(i + 1, vivos.size()):
				var ra: Rect2 = vivos[i].retangulo()
				var rb: Rect2 = vivos[k].retangulo()
				var inter := ra.grow(1.0).intersection(rb.grow(1.0))  # com o contorno da fonte (1 px por lado)
				if inter.size.x > 0.5 and inter.size.y > 0.5:
					au._problema("OVERLAP_NUM", "números de dano da arena", "%s cobre %s" % [au._fmt(ra), au._fmt(rb)])
		await au._ver("luta_numeros")



# ---------------------------------------------------------------------------------------------
# Fase 4b: marcas de fita, botões de foco trancados, cartão de compra, chegada e treino assistido (Shift)
# ---------------------------------------------------------------------------------------------

func _rodar_fase4b() -> void:
	var nomes_4b: Array = au.ESTADOS_TODOS.filter(func(n: String) -> bool: return n.begins_with("b4_"))
	var alguma := false
	for n in nomes_4b:
		if au._quer(n):
			alguma = true
	if not alguma:
		return
	# --- Começo de carreira: só o saco, duas marcas de fita com a plaquinha ---
	if au._quer("b4_inicio_marcas"):
		au._novo_jogo()
		au._com_aparelhos([], 0.0)
		await au._abrir()
		au._estado = "b4_inicio_marcas"
		au._exigir(au._marca_visivel("treadmill") and au._marca_visivel("jump_rope"), au._estado, "as duas marcas de fita deveriam aparecer")
		au._exigir(not au._cena.get_node("Sala")._esteira.visible, au._estado, "esteira desenhada sem estar comprada")
		au._exigir(not au._cena.get_node("Sala")._corda_prego.visible, au._estado, "corda desenhada sem estar comprada")
		au._exigir(au.gs.estado_aparelho("treadmill") == "missing" and au.gs.estado_aparelho("jump_rope") == "locked", au._estado, "estados esperados: esteira missing, corda locked")
		await au._ver("b4_inicio_marcas")
	if au._quer("b4_esteira_compravel"):
		au._novo_jogo()
		au._com_aparelhos([], 600.0)
		await au._abrir()
		au._estado = "b4_esteira_compravel"
		au._exigir(au.gs.estado_aparelho("treadmill") == "buyable", au._estado, "esteira deveria estar comprável com 600 de Treino")
		await au._ver("b4_esteira_compravel")
	if au._quer("b4_corda_compravel"):
		au._novo_jogo()
		au._com_aparelhos(["treadmill"], 2000.0, "treadmill")
		await au._abrir()
		au._estado = "b4_corda_compravel"
		au._exigir(au.gs.estado_aparelho("jump_rope") == "buyable", au._estado, "corda deveria estar comprável")
		au._exigir(not au._marca_visivel("treadmill") and au._marca_visivel("jump_rope"), au._estado, "marcas: só a da corda")
		await au._ver("b4_corda_compravel")
	if au._quer("b4_corda_sem_treino"):
		au._novo_jogo()
		au._com_aparelhos(["treadmill"], 100.0, "treadmill")
		await au._abrir()
		au._estado = "b4_corda_sem_treino"
		au._exigir(au.gs.estado_aparelho("jump_rope") == "missing", au._estado, "corda deveria estar sem Treino (missing)")
		await au._ver("b4_corda_sem_treino")
	if au._quer("b4_tres_aparelhos"):
		au._novo_jogo()
		au._com_aparelhos(["treadmill", "jump_rope"], 800.0, "jump_rope")
		await au._abrir()
		au._estado = "b4_tres_aparelhos"
		au._exigir(not au._marca_visivel("treadmill") and not au._marca_visivel("jump_rope"), au._estado, "com os 3 aparelhos não sobra marca")
		await au._ver("b4_tres_aparelhos")

	# --- Cartão de compra: piscada ao apontar, informação do aparelho ---
	if au._quer("b4_cartao_destaque"):
		au._novo_jogo()
		au._com_aparelhos([], 600.0)
		await au._abrir()
		au._cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await au._esperar(0.1)
		au._cena._apontar_compra("treadmill")
		au._estado = "b4_cartao_destaque"
		au._exigir(au._cena.get_node("PainelLoja")._aba == "treino", au._estado, "apontar a compra deveria abrir a aba TREINO")
		await au._ver("b4_cartao_destaque")
	if au._quer("b4_info_aparelho"):
		au._novo_jogo()
		au._com_aparelhos([], 600.0)
		await au._abrir()
		au._cena.get_node("PainelLoja")._sobre("a:treadmill")
		await au._esperar(0.1)
		await au._ver("b4_info_aparelho")

		# --- Chegada (Fase 5.1: caixa da escola; 3 cliques abrem) ---
		if au._quer("b4_chegada_esteira_queda") or au._quer("b4_chegada_esteira_poeira"):
			au._novo_jogo()
			au._com_aparelhos([], 600.0)
			await au._abrir()
			var sala: Node = au._cena.get_node("Sala")
			au._exigir(au.gs.comprar_aparelho("treadmill"), "b4_chegada_esteira", "comprar_aparelho(treadmill) recusou com 600 de Treino")
			await au._esperar(0.5)
			au._exigir(au.gs.estado_aparelho("treadmill") == "boxed" and au._marca_visivel("treadmill"), "b4_chegada_esteira", "a caixa chega sobre a marca")
			if au._quer("b4_chegada_esteira_queda"):
				await au._ver("b4_chegada_esteira_queda")
			for i in 3:
				au.gs.bater_caixa("treadmill")
			await au._esperar(0.15)
			if au._quer("b4_chegada_esteira_poeira"):
				await au._ver("b4_chegada_esteira_poeira")
			await au._esperar(1.3)
			au._exigir(au.gs.foco == "treadmill" and sala._esteira.visible and not au._marca_visivel("treadmill"), "b4_chegada_esteira",
				"depois da caixa a esteira fica no foco e visível")
			au._exigir(sala._lutador.nome_sprite.begins_with("fighter_run"), "b4_chegada_esteira", "o lutador deveria estar na esteira")
		if au._quer("b4_chegada_corda"):
			au._novo_jogo()
			au._com_aparelhos(["treadmill"], 2000.0, "treadmill")
			await au._abrir()
			var sala: Node = au._cena.get_node("Sala")
			au._exigir(au.gs.comprar_aparelho("jump_rope"), "b4_chegada_corda", "comprar_aparelho(jump_rope) recusou")
			await au._esperar(0.5)
			await au._ver("b4_chegada_corda")
			for i in 3:
				au.gs.bater_caixa("jump_rope")
			await au._esperar(1.4)
			au._exigir(au.gs.foco == "jump_rope" and not au._marca_visivel("jump_rope"), "b4_chegada_corda",
				"depois da caixa a corda fica no foco e sem marca")

	# --- NOVA CARREIRA: a sala volta a ter só o saco ---
	if au._quer("b4_nova_carreira"):
		au._derrota_pendente([], 12)
		au._com_aparelhos(["treadmill", "jump_rope"], 50.0, "jump_rope")
		await au._abrir()
		var sala: Node = au._cena.get_node("Sala")
		au._exigir(not au._marca_visivel("treadmill"), "b4_nova_carreira", "antes: os 3 aparelhos, sem marca")
		au.gs.nova_carreira()
		await au._esperar(0.7)
		au._estado = "b4_nova_carreira"
		au._exigir(au.gs.aparelhos_montados() == ["punching_bag"], au._estado, "nova carreira deveria deixar só o saco: %s" % str(au.gs.aparelhos_montados()))
		au._exigir(au._marca_visivel("treadmill") and au._marca_visivel("jump_rope"), au._estado, "as duas marcas deveriam voltar")
		au._exigir(not sala._esteira.visible and not sala._corda_prego.visible, au._estado, "esteira e corda não deveriam ser desenhadas")
		await au._ver("b4_nova_carreira")

	# --- Clique na marca / no botão trancado / tecla 2: nada de treino nem troca de foco ---
	if au._quer("b4_clique_marca_e_foco"):
		au._novo_jogo()
		au._com_aparelhos([], 100.0)
		await au._abrir()
		au._estado = "b4_clique_marca_e_foco"
		var cliques := [0]
		au.gs.clicou.connect(func(_a, _b, _c, _d, _e) -> void: cliques[0] += 1)
		var loja: Node = au._cena.get_node("PainelLoja")
		loja._tab["loja"].botao.pressed.emit()
		await au._esperar(0.1)
		au._mouse(Vector2(445, 262), true)  # plaquinha da esteira no chão
		au._mouse(Vector2(445, 262), false)
		await au._esperar(0.2)
		au._exigir(loja._aba == "treino", au._estado, "clique na marca da esteira deveria abrir a aba TREINO")
		au._exigir(au.gs.foco == "punching_bag" and cliques[0] == 0, au._estado, "clique na marca não pode treinar nem trocar o foco")
		loja._tab["loja"].botao.pressed.emit()
		await au._esperar(0.1)
		var barra: Control = au._cena.get_node("BarraBaixo")
		var b2: Control = barra._botoes["treadmill"].botao
		var c2 := b2.get_global_rect().get_center()
		au._mouse(c2, true)
		au._mouse(c2, false)
		await au._esperar(0.2)
		au._exigir(loja._aba == "treino", au._estado, "clique no botão de foco trancado deveria abrir a aba TREINO")
		au._exigir(au.gs.foco == "punching_bag" and cliques[0] == 0, au._estado, "botão trancado não pode treinar nem trocar o foco")
		au._tecla(KEY_2, true)
		au._tecla(KEY_2, false)
		await au._esperar(0.1)
		au._exigir(au.gs.foco == "punching_bag", au._estado, "a tecla 2 não deveria focar um aparelho que não chegou")
		await au._ver("b4_clique_marca_e_foco")

	# --- Treino assistido: chip em cada estado, botão, entradas ---
	if au._quer("b4_assist_dica") or au._quer("b4_assist_esperando") or au._quer("b4_assist_socando") or au._quer("b4_assist_pulso") \
			or au._quer("b4_assist_botao") or au._quer("b4_assist_entradas"):
		au._novo_jogo()
		au._com_aparelhos([], 0.0)
		await au._abrir()
		var faixa: Node = au._cena.get_node("FaixaAssistido")
		if au._quer("b4_assist_dica"):
			au._estado = "b4_assist_dica"
			# Fase 5.1: sem texto fixo. Parado, só o botão (ícone); depois de 5 s sem clicar aparece a dica curta (3 primeiras vezes).
			au._exigir(au.gs.assistido_estado() == "off" and not faixa._chip.visible, au._estado, "sem a dica de primeira vez o chip não aparece")
			faixa._ocioso = 5.5
			await au._esperar(0.3)
			au._exigir(faixa._chip.visible and faixa._chip_texto.text == au._txt("hint_assist_first"), au._estado, "dica curta esperada: %s" % faixa._chip_texto.text)
			await au._ver("b4_assist_dica")
			faixa._dica_t = 0.01
			await au._esperar(0.2)
			au._exigir(not faixa._chip.visible, au._estado, "a dica some sozinha")
		if au._quer("b4_assist_esperando"):
			au._estado = "b4_assist_esperando"
			au.gs.clicar()
			au._tecla(KEY_SHIFT, true)
			await au._esperar(0.05)
			au._exigir(au.gs.assistido_estado() == "waiting", au._estado, "segurando com a mão mexendo deveria ser waiting: " + au.gs.assistido_estado())
			await au._ver("b4_assist_esperando")
		if au._quer("b4_assist_socando") or au._quer("b4_assist_pulso"):
			au._estado = "b4_assist_socando"
			au.gs.clicar()  # mão mexendo em t=0
			au._tecla(KEY_SHIFT, true)
			var socos0: int = au.gs.assist_socos_total
			await au._esperar(1.4)  # clique em t=0: mão parada em 0,6 s, primeiro soco 0,6 s depois (1,2 s); o número dura 0,5 s
			au._exigir(au.gs.assistido_estado() == "active", au._estado, "deveria estar active: %s (segurando gs=%s faixa=%s modal=%s bloq=%s)" % [au.gs.assistido_estado(), au.gs.assistido_segurando(), faixa.segurando(), au.gs.modal_aberto, au.gs.acoes_bloqueadas()])
			au._exigir(au.gs.assist_socos_total > socos0, au._estado, "nenhum auto-soco do assistido em 1,4 s")
			var vivos := 0
			for nn in au._cena.get_node("Sala")._numeros:
				if nn.ativo:
					vivos += 1
			au._exigir(vivos > 0, au._estado, "o auto-soco do assistido deveria mostrar um número flutuante")
			if au._quer("b4_assist_socando"):
				await au._ver("b4_assist_socando")
			if au._quer("b4_assist_pulso"):
				faixa.pulsar(5.0)
				await au._ver("b4_assist_pulso")
				faixa._pulso_t = 0.0
		if au._quer("b4_assist_botao"):
			au._estado = "b4_assist_botao"
			au._tecla(KEY_SHIFT, false)
			await au._esperar(0.1)
			au._exigir(au.gs.assistido_estado() == "off", au._estado, "soltou o Shift: deveria voltar a off")
			au._mouse(au._centro_botao_segurar(), true)
			await au._esperar(0.25)
			au._exigir(au.gs.assistido_segurando(), au._estado, "botão SEGURAR pressionado deveria segurar o assistido")
			await au._ver("b4_assist_botao")
			au._mouse(au._centro_botao_segurar(), false)
			await au._esperar(0.2)
			au._exigir(not au.gs.assistido_segurando(), au._estado, "soltar o botão deveria soltar o assistido")
		if au._quer("b4_assist_entradas"):
			au._estado = "b4_assist_entradas"
			au.gs.definir_assistido(false)
			await au._esperar(0.1)
			au._tecla(KEY_SHIFT, true)
			await au._esperar(0.05)
			au._exigir(au.gs.assistido_segurando(), au._estado, "Shift pressionado deveria segurar")
			au._tecla(KEY_SHIFT, true, true)  # repetição da tecla presa: ignorada
			au._tecla(KEY_SHIFT, false)
			await au._esperar(0.05)
			au._exigir(not au.gs.assistido_segurando(), au._estado, "Shift solto deveria soltar (a repetição não conta)")
			au._tecla(KEY_SHIFT, true)
			await au._esperar(0.05)
			faixa.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)  # alt-tab com o Shift pressionado
			await au._esperar(0.05)
			au._exigir(not au.gs.assistido_segurando() and not faixa.segurando(), au._estado, "perder o foco da janela deveria soltar tudo")
			au._tecla(KEY_SHIFT, false)
			# Os dois Shifts: soltar um com o outro apertado continua segurando; soltar o outro solta.
			au._tecla(KEY_SHIFT, true)
			au._tecla(KEY_SHIFT, true, false, true)
			await au._esperar(0.05)
			au._tecla(KEY_SHIFT, false)
			await au._esperar(0.05)
			au._exigir(au.gs.assistido_segurando(), au._estado, "soltar o Shift esquerdo com o direito apertado: continua segurando")
			au._tecla(KEY_SHIFT, true)
			au._tecla(KEY_SHIFT, false, false, true)
			await au._esperar(0.05)
			au._exigir(au.gs.assistido_segurando(), au._estado, "soltar o Shift direito com o esquerdo apertado: continua segurando")
			au._tecla(KEY_SHIFT, false)
			await au._esperar(0.05)
			au._exigir(not au.gs.assistido_segurando(), au._estado, "os dois Shifts soltos: não deveria segurar")
			au._mouse(au._centro_botao_segurar(), true)
			await au._esperar(0.1)
			au._tecla(KEY_SHIFT, true)
			au._tecla(KEY_SHIFT, false)
			await au._esperar(0.05)
			au._exigir(au.gs.assistido_segurando(), au._estado, "soltar o Shift com o botão ainda apertado: continua segurando")
			au._mouse(au._centro_botao_segurar(), false)
			await au._esperar(0.1)
			au._exigir(not au.gs.assistido_segurando(), au._estado, "tudo solto: não deveria segurar")
			await au._ver("b4_assist_entradas")
		au.gs.definir_assistido(false)
	if au._quer("b4_assist_metronomo"):
		au._novo_jogo()
		au._com_aparelhos([], 0.0)
		au.gs.nivel_metronomo = 1
		await au._abrir()
		au._estado = "b4_assist_metronomo"
		var faixa: Node = au._cena.get_node("FaixaAssistido")
		au._exigir(au.gs.assistido_estado() == "metronome" and faixa._chip_texto.text == au._txt("assist_metronome"), au._estado, "chip METRÔNOMO TOCANDO esperado")
		au._exigir(not faixa._botao.visible, au._estado, "com o Metrônomo o botão SEGURAR some")
		await au._ver("b4_assist_metronomo")

	# --- Tela de fim: dica de comprar o aparelho ---
	for ap_dica in ["treadmill", "jump_rope"]:
		var nome_estado := "b4_fim_dica_esteira" if ap_dica == "treadmill" else "b4_fim_dica_corda"
		if au._quer(nome_estado):
			au._derrota_pendente([], 12)
			au.gs.fim.reason["kind"] = "missing"
			au.gs.fim.reason["attribute"] = "endurance" if ap_dica == "treadmill" else "agility"
			au.gs.fim.reason["unlock_tip"] = ap_dica
			await au._abrir()
			await au._esperar(0.9)
			au._estado = nome_estado
			var dicas: Array = au.gs.lista_ui("tip_unlock_" + ap_dica)
			var dica_fim: String = str(au.gs.textos_fim(au.gs.fim).get("tip", ""))
			au._exigir(dica_fim in dicas, au._estado, "a dica da tela de fim deveria ser de tip_unlock_%s: \"%s\"" % [ap_dica, dica_fim])
			await au._ver(nome_estado)
