extends RefCounted
## Estados do ui_audit.gd: Fases 5.2 e 5.3. Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).


var au


func _init(auditor) -> void:
	au = auditor


func _rodar_fase52() -> void:
	var alguma := false
	for n in au.ESTADOS_TODOS:
		if str(n).begins_with("f52_") and au._quer(n):
			alguma = true
	if not alguma:
		return

	# --- LOJA: L3 comprável, L4 sem dinheiro, L4 com a L3 ainda na caixa ---
	if au._quer("f52_loja_l3_compravel"):
		au._novo_jogo()
		au.gs.nivel_luva = 2
		au.gs.dinheiro = 1500.0
		await au._abrir_loja()
		au._exigir(au.gs.pode_comprar_luva() and str(au.gs.proxima_luva().id) == "glove_l3", "f52_loja_l3_compravel", "a L3 esta a venda")
		await au._ver("f52_loja_l3_compravel")
	if au._quer("f52_loja_l4_sem_dinheiro"):
		au._novo_jogo()
		au.gs.nivel_luva = 3
		au.gs.dinheiro = 300.0
		await au._abrir_loja()
		au._exigir(str(au.gs.proxima_luva().id) == "glove_l4" and not au.gs.pode_comprar_luva(), "f52_loja_l4_sem_dinheiro", "a L4 esta a venda sem dinheiro")
		await au._ver("f52_loja_l4_sem_dinheiro")
	if au._quer("f52_loja_l4_na_caixa") or au._quer("f52_caixa_l3"):
		au._novo_jogo()
		au.gs.nivel_luva = 2
		au.gs.dinheiro = 6000.0
		await au._abrir()
		au._exigir(au.gs.comprar_luva(), "f52_caixa_l3", "comprar a L3")
		await au._esperar(0.8)
		au._exigir(au.gs.tem_caixa("glove_l3") and au._cena.get_node("Sala")._caixas.has("glove_l3"), "f52_caixa_l3", "a caixa da L3 esta na sala")
		await au._ver("f52_caixa_l3")
		au._cena.get_node("PainelLoja")._tab["loja"].botao.pressed.emit()
		await au._esperar(0.2)
		au._exigir(au.gs.luva_em_caixa() and not au.gs.pode_comprar_luva(), "f52_loja_l4_na_caixa", "L4 so depois de abrir a caixa da L3")
		await au._ver("f52_loja_l4_na_caixa")
	if au._quer("f52_caixa_l4"):
		au._novo_jogo()
		au.gs.nivel_luva = 3
		au.gs.dinheiro = 6000.0
		await au._abrir()
		au._exigir(au.gs.comprar_luva(), "f52_caixa_l4", "comprar a L4")
		await au._esperar(0.8)
		au._exigir(au.gs.tem_caixa("glove_l4") and au._cena.get_node("Sala")._caixas.has("glove_l4"), "f52_caixa_l4", "a caixa da L4 esta na sala")
		await au._ver("f52_caixa_l4")

	# --- LOJA: Grito da equipe ---
	if au._quer("f52_loja_grito_compravel") or au._quer("f52_loja_grito_hover") or au._quer("f52_loja_grito_comprado"):
		au._novo_jogo()
		au.gs.nivel_luva = 4
		au.gs.dinheiro = 2000.0
		var painel: Node = await au._abrir_loja(true)
		au._exigir(au.gs.pode_comprar_crew_click(), "f52_loja_grito_compravel", "o Grito esta comprável")
		await au._ver("f52_loja_grito_compravel")
		if au._quer("f52_loja_grito_hover"):
			painel._sobre("c")
			await au._esperar(0.1)
			await au._ver("f52_loja_grito_hover")
			painel._sobre("")
		painel._comprar_crew()
		await au._esperar(0.5)
		au._exigir(au.gs.crew_click_comprado and painel._crew.botao.disabled, "f52_loja_grito_comprado", "comprado: botao apagado")
		await au._ver("f52_loja_grito_comprado")
	if au._quer("f52_loja_grito_sem_dinheiro"):
		au._novo_jogo()
		au.gs.nivel_luva = 4
		au.gs.dinheiro = 90.0
		await au._abrir_loja(true)
		au._exigir(not au.gs.pode_comprar_crew_click(), "f52_loja_grito_sem_dinheiro", "sem dinheiro")
		await au._ver("f52_loja_grito_sem_dinheiro")

	# --- Evento dourado: luva x7 e bolsa da torcida ---
	if au._quer("f52_evento_luva") or au._quer("f52_evento_bolsa") or au._quer("f52_bolsa_hover") or au._quer("f52_bolsa_toast"):
		for tipo in ["frenzy", "crew"]:
			var nome_ev := "f52_evento_luva" if tipo == "frenzy" else "f52_evento_bolsa"
			if not (au._quer(nome_ev) or (tipo == "crew" and (au._quer("f52_bolsa_hover") or au._quer("f52_bolsa_toast")))):
				continue
			au._novo_jogo()
			await au._abrir()
			var sala: Node = au._cena.get_node("Sala")
			au.gs.frenesi_restante = 0.0
			au.gs.evento_dourado_tipo = tipo
			au.gs.evento_dourado_restante = 10.0
			au.gs.evento_dourado.emit(10.0)
			await au._esperar(0.3)
			var esperado: String = au.gs.dados.golden_crew_sprite if tipo == "crew" else au.gs.dados.golden_frenzy_sprite
			au._exigir(sala._evento_spr.nome_sprite == esperado, nome_ev, "sprite do evento: " + sala._evento_spr.nome_sprite)
			await au._ver(nome_ev)
			var centro: Vector2 = sala._evento_rect.get_center()
			if tipo == "crew":
				if au._quer("f52_bolsa_hover"):
					sala._hover_em(centro)
					await au._esperar(0.1)
					au._exigir(au._dica_inst().visible, "f52_bolsa_hover", "a bolsa da dica no hover")
					await au._ver("f52_bolsa_hover")
					sala._sair_hover()
				var treino0: float = au.gs.treino
				sala._clique_em(centro)
				await au._esperar(0.35)
				au._exigir(au.gs.frenesi_restante <= 0.0 and au.gs.treino > treino0, "f52_bolsa_toast", "a bolsa paga e nao liga o FRENESI (fren %s treino %s->%s restante %s tipo %s)" % [au.gs.frenesi_restante, treino0, au.gs.treino, au.gs.evento_dourado_restante, au.gs.evento_dourado_tipo])
				await au._ver("f52_bolsa_toast")
			else:
				sala._clique_em(centro)
				await au._esperar(0.2)
				au._exigir(au.gs.frenesi_restante > 0.0, nome_ev, "a luva x7 liga o FRENESI")

	# --- Luva L4 na sala e na luta ---
	if au._quer("f52_l4_sala"):
		au._novo_jogo()
		au.gs.nivel_luva = 4
		await au._abrir()
		var sala5: Node = au._cena.get_node("Sala")
		for i in 3:
			au.gs.clicar()
			await au._esperar(0.08)
		au._exigir(str(sala5._lutador.nome_sprite).ends_with("_glove_l4") or au.gs.sufixo_luva() == "_glove_l4", "f52_l4_sala", "lutador com a L4: " + str(sala5._lutador.nome_sprite))
		await au._ver("f52_l4_sala")
	if au._quer("f52_l4_luta"):
		var achada = au._achar_luta(true, true)
		au._novo_jogo()
		au.gs.nivel_luva = 4
		au.gs.atributos = achada.atr
		await au._abrir()
		au.gs.rng.seed = int(achada.k)
		var fluxo: Node = au._cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await au._esperar(0.3)
		fluxo.janela.lutar_pedido.emit()
		await au._esperar(0.25)
		fluxo.tela._clock = 5.0
		await au._esperar(0.3)
		await au._ver("f52_l4_luta")

	# --- Os 3 desvios da 5.1 ---
	if au._quer("f52_destaque_unico"):
		au._novo_jogo()
		au.gs.treino = 5000.0
		await au._abrir()
		var loja: Node = au._cena.get_node("PainelLoja")
		var vistos := 0
		for r in loja.find_children("*", "ReferenceRect", true, false):
			if (r as Control).is_visible_in_tree():
				vistos += 1
		au._exigir(vistos <= 1, "f52_destaque_unico", "no maximo 1 contorno de destaque visivel (achei %d)" % vistos)
		await au._ver("f52_destaque_unico")
	if au._quer("f52_contador"):
		au._novo_jogo()
		await au._abrir()
		await au._ver("f52_contador")
	if au._quer("f52_critico_menor"):
		au._novo_jogo()
		await au._abrir()
		var sala6: Node = au._cena.get_node("Sala")
		sala6._pos_clique = Vector2(336, 232)
		au.gs.clicou.emit(1500.0, true, "punching_bag", "endurance", "A ESTEIRA GEMEU!")
		await au._esperar(0.2)
		await au._ver("f52_critico_menor")



# ---------------------------------------------------------------------------------------------
# Fase 5.3: calendário da campanha (folhinha no HUD, faixas de aviso, prévia do dia, PASSAR O POSTO, retrato por luva)
# ---------------------------------------------------------------------------------------------

## Garagem com a data da próxima luta daqui a `dias` dias e o risco do HUD forçado (o recálculo periódico fica desligado).
## `idx` escolhe o adversário (0 Dudu, 1 Brutão...). Chamar ANTES de `_abrir()`.
func _calendario53(dias: int, risco: String, idx: int = 0) -> void:
	au._novo_jogo()
	au.gs.indice_escada = idx
	au.gs.risco_hud_ativo = false
	var spd: float = au.gs._segundos_por_dia()
	au.gs.fight_day = 30
	au.gs.segundos_campanha = float(30 - dias - 1) * spd + 1.0
	au.gs._definir_risco_hud(str(au.gs.proximo_adversario().id), risco)


func _rodar_fase53() -> void:
	var alguma := false
	for n in au.ESTADOS_TODOS:
		if str(n).begins_with("f53_") and au._quer(n):
			alguma = true
	if not alguma:
		return
	var fl: Node

	# --- HUD: a folhinha em cada cor de risco, 12 dias (a linha mais larga), 1 dia, nome longo ---
	for par in [["f53_hud_facil", 11, "easy"], ["f53_hud_equilibrado", 5, "even"], ["f53_hud_perigoso", 4, "hard"],
			["f53_hud_12_dias", 12, "easy"], ["f53_hud_1_dia", 1, "hard"]]:
		if au._quer(par[0]):
			_calendario53(par[1], par[2])
			await au._abrir()
			au._exigir(au.gs.dias_para_luta() == par[1], par[0], "dias para a luta %d" % au.gs.dias_para_luta())
			await au._ver(par[0])
	if au._quer("f53_hud_nome_longo"):
		_calendario53(8, "even", 1)  # Brutão do Posto: o nome passa da linha 2 e é abreviado
		await au._abrir()
		await au._ver("f53_hud_nome_longo")
	if au._quer("f53_hud_dia_virou"):
		_calendario53(6, "easy")
		await au._abrir()
		au.gs.dia_mudou.emit(au.gs.dia_campanha())
		await au._esperar(0.12)  # a folha arrancada no meio da animação
		await au._ver("f53_hud_dia_virou")
	if au._quer("f53_hud_completa"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", au.gs.lutas.adversarios.size())
		await au._abrir()
		au._exigir(au.gs.campanha_completa(), "f53_hud_completa", "campanha completa")
		await au._ver("f53_hud_completa")

	# --- Dica de passar o posto (<= 3 dias, vermelho, pote > 0): versão longa e versão curta ---
	if au._quer("f53_dica_posto"):
		_calendario53(2, "hard")
		au.gs.fama = 200
		await au._abrir()
		au._exigir(bool(au.gs.dica_aposentar().show), "f53_dica_posto", "a dica deveria estar no ar")
		await au._ver("f53_dica_posto")
	if au._quer("f53_dica_posto_curta"):
		_calendario53(2, "hard")
		au.gs.fama = 200000
		await au._abrir()
		au._exigir(bool(au.gs.dica_aposentar().show), "f53_dica_posto_curta", "a dica deveria estar no ar")
		await au._ver("f53_dica_posto_curta")

	# --- Faixas de aviso: 3 dias (calma) e 1 dia (urgente, 2 quadros) ---
	if au._quer("f53_aviso_3_dias"):
		_calendario53(3, "even")
		await au._abrir()
		au.gs.aviso_data.emit(3)
		await au._esperar(0.45)
		var faixa3: Control = au._cena.find_children("*", "FaixaAviso", true, false)[0]
		au._exigir(faixa3.visible and not faixa3.urgente, "f53_aviso_3_dias", "faixa de 3 dias visível e calma")
		await au._ver("f53_aviso_3_dias")
	if au._quer("f53_aviso_1_dia_a") or au._quer("f53_aviso_1_dia_b"):
		_calendario53(1, "hard")
		await au._abrir()
		au.gs.aviso_data.emit(1)
		await au._esperar(0.3)
		var faixa1: Control = au._cena.find_children("*", "FaixaAviso", true, false)[0]
		au._exigir(faixa1.visible and faixa1.urgente, "f53_aviso_1_dia_a", "faixa de 1 dia visível e urgente")
		await au._ver("f53_aviso_1_dia_a")
		await au._esperar(0.5)  # 2 fps: o outro quadro
		await au._ver("f53_aviso_1_dia_b")
		faixa1.esconder()
	if au._quer("f53_aviso_nome_longo"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0)
		au.gs.risco_hud_ativo = false
		au.gs.fight_day = 30
		au.gs.segundos_campanha = 28.0 * au.gs._segundos_por_dia() + 1.0
		await au._abrir()
		au.gs.aviso_data.emit(1)  # Tonhão do Tatame: o nome mais longo
		await au._esperar(0.3)
		await au._ver("f53_aviso_nome_longo")

	# --- O dia da luta: a prévia abre sozinha, sem X nem Esc; PASSAR O POSTO pede confirmação e VOLTAR devolve a prévia ---
	if au._quer("f53_dia_previa") or au._quer("f53_hud_hoje") or au._quer("f53_dia_loja_fechada") or au._quer("f53_dia_passar_confirma") \
			or au._quer("f53_dia_voltar"):
		_calendario53(0, "hard")
		au.gs.fama = 200
		await au._abrir()
		fl = au._cena.get_node("Fluxo")
		# A LOJA aberta antes do dia fecha (a aba volta para o TREINO).
		au._cena.get_node("PainelLoja")._trocar_aba("loja")
		await au._esperar(0.9)
		au._exigir(au.gs.no_dia_da_luta() and not au.gs.sala_ativa(), "f53_dia_previa", "no dia a sala está parada")
		au._exigir(au._eh(fl.janela, "JanelaPrevia") and fl.janela.dia_da_luta, "f53_dia_previa", "a prévia do dia abriu sozinha")
		if au._eh(fl.janela, "JanelaPrevia"):
			await au._ver("f53_dia_previa")
			# Esc não fecha a prévia do dia.
			var esc := InputEventKey.new()
			esc.keycode = KEY_ESCAPE
			esc.pressed = true
			fl._unhandled_key_input(esc)
			await au._esperar(0.2)
			au._exigir(au._eh(fl.janela, "JanelaPrevia"), "f53_dia_previa", "Esc não pode fechar a prévia do dia")
			# A folhinha do HUD (hoje) e a LOJA fechada, com a prévia escondida só para a captura.
			fl.janela.visible = false
			var loja: Node = au._cena.get_node("PainelLoja")
			au._exigir(loja._tab["loja"].botao.disabled and loja._aba == "treino", "f53_dia_loja_fechada", "LOJA fechada no dia")
			await au._ver("f53_hud_hoje")
			fl.janela.visible = true
			if au._quer("f53_dia_passar_confirma") or au._quer("f53_dia_voltar"):
				fl.janela.passar_pedido.emit()
				await au._esperar(0.4)
				au._exigir(au._eh(fl.janela, "JanelaAposentar"), "f53_dia_passar_confirma", "PASSAR O POSTO abre a confirmação")
				await au._ver("f53_dia_passar_confirma")
				if au._eh(fl.janela, "JanelaAposentar"):
					fl.janela.cancelou.emit()  # VOLTAR
					await au._esperar(0.5)
					au._exigir(au._eh(fl.janela, "JanelaPrevia") and fl.janela.dia_da_luta, "f53_dia_voltar", "VOLTAR devolve a prévia do dia")
					await au._ver("f53_dia_voltar")
	# B1 da QA 5.3: dia da luta + fita da revanche + linha da arte (janela mais alta): a folhinha "HOJE" não pode tocar o retrato.
	if au._quer("f53_dia_previa_revanche_arte"):
		_calendario53(0, "hard")
		au.gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		au.gs.permanente["last_art"] = "boxing"
		au.gs.arte_id = "boxing"
		au.gs._atualizar_traco()
		au.gs.permanente["revenge_opponent"] = str(au.gs.proximo_adversario().id)
		au.gs.fama = 200
		await au._abrir()
		fl = au._cena.get_node("Fluxo")
		await au._esperar(0.9)
		var ok_prev: bool = au._eh(fl.janela, "JanelaPrevia") and fl.janela.dia_da_luta
		au._exigir(ok_prev, "f53_dia_previa_revanche_arte", "a prévia do dia abriu")
		if ok_prev:
			au._exigir(bool(au.gs.previa().get("revenge", false)) and str(au.gs.previa().get("art_fight_text", "")) != "",
				"f53_dia_previa_revanche_arte", "o estado deveria ter revanche e traço da arte")
			var folhinha: Control = null
			var quadros: Array = []
			for n in fl.janela.find_children("*", "TextureRect", true, false):
				var tr: TextureRect = n as TextureRect
				if tr.get_child_count() > 0 and tr.get_node_or_null("Cabecalho") != null:
					folhinha = tr
				elif tr.texture != null and tr.get_child_count() == 1 and tr.get_child(0) is TextureRect \
						and tr.size.x >= 30.0 and tr.size.x <= 40.0 and tr.size.y >= 30.0 and tr.size.y <= 40.0:
					quadros.append(tr)
			au._exigir(folhinha != null and quadros.size() == 2, "f53_dia_previa_revanche_arte", "achou a folhinha e os 2 retratos")
			if folhinha != null:
				for q in quadros:
					au._exigir(not folhinha.get_global_rect().intersects(q.get_global_rect()), "f53_dia_previa_revanche_arte",
						"a folhinha HOJE toca o retrato %s" % str(q.get_global_rect()))
		await au._ver("f53_dia_previa_revanche_arte")
	if au._quer("f53_dia_previa_tonhao"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0)
		au.gs.risco_hud_ativo = false
		au.gs.fight_day = 40
		au.gs.segundos_campanha = 39.0 * au.gs._segundos_por_dia()
		await au._abrir()
		fl = au._cena.get_node("Fluxo")
		await au._esperar(0.9)
		au._exigir(au._eh(fl.janela, "JanelaPrevia") and fl.janela.dia_da_luta, "f53_dia_previa_tonhao", "a prévia do dia abriu")
		await au._ver("f53_dia_previa_tonhao")

	# --- Fim de campanha: derrota (CAMPANHA ENCERRADA / NOVA CAMPANHA) e passar o posto depois do Kid (selo) ---
	if au._quer("f53_fim_campanha_encerrada"):
		au._derrota_pendente([], 12)
		await au._abrir()
		await au._esperar(0.9)
		await au._ver("f53_fim_campanha_encerrada")
	if au._quer("f53_fim_selo_completa"):
		au._novo_jogo()
		au.gs.indice_escada = au.gs.lutas.adversarios.size()
		au.gs.cinturao = true
		au.gs.fama = 340
		au.gs.aposentar()
		await au._abrir()
		await au._esperar(0.9)
		await au._ver("f53_fim_selo_completa")

	# --- Retrato do jogador com a luva equipada (L1 a L4) na prévia, e L4 no topo da luta ---
	for n in [1, 2, 3, 4]:
		var nome_r := "f53_retrato_l%d" % n
		if au._quer(nome_r):
			au._novo_jogo()
			au.gs.nivel_luva = n
			await au._abrir()
			au._exigir(("portrait_player" + au.gs.sufixo_luva()) == "portrait_player_glove_l%d" % n, nome_r, "retrato da luva L%d: %s" % [n, ("portrait_player" + au.gs.sufixo_luva())])
			au._cena.get_node("Fluxo").abrir_previa()
			await au._esperar(0.4)
			await au._ver(nome_r)
	if au._quer("f53_retrato_luta_l4"):
		var achada53 = au._achar_luta(true, true)
		au._novo_jogo()
		au.gs.nivel_luva = 4
		au.gs.atributos = achada53.atr
		await au._abrir()
		au.gs.rng.seed = int(achada53.k)
		fl = au._cena.get_node("Fluxo")
		fl.abrir_previa()
		await au._esperar(0.3)
		fl.janela.lutar_pedido.emit()
		await au._esperar(0.5)
		await au._ver("f53_retrato_luta_l4")

	# --- Grito da equipe visível na LOJA sem rolar ---
	if au._quer("f53_loja_grito_sem_rolar"):
		au._novo_jogo()
		au.gs.nivel_luva = 4
		au.gs.dinheiro = 2000.0
		var painel53: Node = await au._abrir_loja(false)
		var janela_loja: Control = painel53._janela_loja
		var cartao: Control = painel53._crew.cartao
		var dentro: bool = cartao.get_global_rect().end.y <= janela_loja.get_global_rect().end.y + 0.01 \
			and cartao.get_global_rect().position.y >= janela_loja.get_global_rect().position.y - 0.01
		au._exigir(dentro and au.gs.pode_comprar_crew_click(), "f53_loja_grito_sem_rolar", "o cartão do Grito inteiro à vista, sem rolar")
		await au._ver("f53_loja_grito_sem_rolar")
	au.gs.risco_hud_ativo = true
