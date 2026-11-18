extends RefCounted
## Estados do ui_audit.gd: Fase 6b1. Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).


var au


func _init(auditor) -> void:
	au = auditor


## Espera até `seg` segundos depois de `t0` (ms), sem esperar se já passou.
func _ate(t0: int, seg: float) -> void:
	var falta := seg - float(Time.get_ticks_msec() - t0) / 1000.0
	if falta > 0.0:
		await au._esperar(falta)


func _f6b1_ui_apagada() -> bool:
	var cu: Node = au._cena_ui()
	for n in cu.alvos:
		if is_instance_valid(n) and (n as CanvasItem).visible and (n as CanvasItem).modulate.a > 0.05 and not au._eh(n, "FaixaAviso"):
			return false
	return true


func _rodar_fase6b1() -> void:
	# --- Os quadros-chave S1..S10 da primeira sucessão (tempos do data/cutscenes/primeira_sucessao.json) ---
	var quer_cena = au._quer("f6b1_s1") or au._quer("f6b1_s2") or au._quer("f6b1_s3") or au._quer("f6b1_s4") or au._quer("f6b1_s5") \
		or au._quer("f6b1_s6") or au._quer("f6b1_s7") or au._quer("f6b1_s8") or au._quer("f6b1_s9") or au._quer("f6b1_s10")
	if quer_cena:
		au._f6b1_fim("Tati Gancho")
		await au._abrir()
		await au._esperar(0.6)
		var cu: Node = au._cena_ui()
		var sala: Node = au._cena.get_node("Sala")
		var t0 := Time.get_ticks_msec()
		au._exigir(au.gs.receber_discipulo(), "f6b1_s1", "RECEBER NOVO DISCÍPULO deveria começar a sucessão")
		au._exigir(au.gs.sucessao_estado() == "scene_1", "f6b1_s1", "estado scene_1 (%s)" % au.gs.sucessao_estado())
		await _ate(t0, 1.15)
		au._exigir(_f6b1_ui_apagada(), "f6b1_s1", "a interface deveria estar apagada em S1")
		au._exigir(cu._barras.visible and sala.cena.ator_visivel("first") and not sala._lutador.visible, "f6b1_s1", "faixas pretas, John em cena e o lutador da sala escondido")
		await au._ver("f6b1_s1")
		await _ate(t0, 2.5)
		await au._ver("f6b1_s2")
		await _ate(t0, 4.3)
		au._exigir(sala._cam_escala == 2, "f6b1_s3", "o corte de perto é 2x (%d) t=%.2f i=%d" % [sala._cam_escala, cu.player._t, cu.player._i])
		await au._ver("f6b1_s3")
		await _ate(t0, 7.9)
		au._exigir(sala._cam_escala == 1, "f6b1_s4", "volta ao 1x em S4")
		await au._ver("f6b1_s4")
		var tela: Node = await au._f6b1_janela_criar()
		au._exigir(tela != null and au.gs.sucessao_estado() == "creating", "f6b1_s5", "a tela de criação deveria abrir (%s)" % au.gs.sucessao_estado())
		await au._esperar(0.5)
		await au._ver("f6b1_s5")
		if tela != null:
			tela._confirmar()
		au._exigir(au.gs.sucessao_estado() == "scene_2", "f6b1_s6", "CONFIRMAR leva a scene_2 (%s)" % au.gs.sucessao_estado())
		var t1 := Time.get_ticks_msec()
		await _ate(t1, 0.8)
		await au._ver("f6b1_s6")
		await _ate(t1, 1.9)
		await au._ver("f6b1_s7")
		await _ate(t1, 4.3)
		au._exigir(au._balao().ativo(), "f6b1_s8", "o balão 'vamos ver sua guarda.' deveria estar na tela")
		au._checar_balao_6b1("f6b1_s8", "first")
		await au._ver("f6b1_s8")
		await _ate(t1, 5.3)
		await au._ver("f6b1_s9")
		for i in 40:
			if au.gs.sucessao_estado() == "none":
				break
			await au._esperar(0.1)
		au._exigir(au.gs.sucessao_estado() == "none", "f6b1_s10", "o controle volta em ~6 s (%s)" % au.gs.sucessao_estado())
		await au._esperar(0.5)
		au._exigir(sala.mentor_visivel() and not sala.cena.ator_visivel("first"), "f6b1_s10", "o John sentado agora é o mentor da sala")
		au._cena.get_node("Fluxo").fechar_cartao_aberto()  # o clique que fecha o cartão "o que você trouxe" não treina
		await au._esperar(0.3)
		au.gs.clicar()
		await au._esperar(0.45)
		au._exigir(au._balao().ativo() and str(au._balao().id) == "cena_suc_isso", "f6b1_s10", "o balão 'isso.' deveria aparecer")
		au._checar_balao_6b1("f6b1_s10", "first")
		await au._ver("f6b1_s10")
		await au._esperar(4.0)
		au._exigir(not _f6b1_ui_apagada(), "f6b1_s10", "a interface voltou")

	# --- Captura da cena a cada 0,5 s (a captura leva ~0,3 s: a série fica em ~0,8 s) ---
	if au._quer("f6b1_linha"):
		au._f6b1_fim("Tati Gancho")
		await au._abrir()
		await au._esperar(0.4)
		var t2 := Time.get_ticks_msec()
		au.gs.receber_discipulo()
		var k := 0
		for i in 40:
			await _ate(t2, 0.5 * float(i))
			if au._eh(au._cena.get_node("Fluxo").janela, "TelaCriarDiscipulo"):
				break
			await au._ver("f6b1_linha_a%02d" % k)
			k += 1
		var tela2: Node = await au._f6b1_janela_criar()
		if tela2 != null:
			tela2._confirmar()
		var t3 := Time.get_ticks_msec()
		var k2 := 0
		for i in 14:
			await _ate(t3, 0.5 * float(i))
			if au.gs.sucessao_estado() == "none":
				break
			await au._ver("f6b1_linha_b%02d" % k2)
			k2 += 1

	# --- Tela de criação (sucessão seguinte: abre direto) ---
	if au._quer("f6b1_criar") or au._quer("f6b1_criar_nome14") or au._quer("f6b1_criar_cores") or au._quer("f6b1_criar_vazio") or au._quer("f6b1_chegada"):
		au._f6b1_fim("Tati Gancho", true)
		await au._abrir()
		await au._esperar(0.5)
		au._exigir(au.gs.receber_discipulo() and au.gs.sucessao_estado() == "creating", "f6b1_criar", "a sucessão seguinte abre direto na criação (%s)" % au.gs.sucessao_estado())
		var tela3: Node = await au._f6b1_janela_criar()
		au._exigir(tela3 != null, "f6b1_criar", "a tela de criação deveria abrir")
		await au._esperar(0.6)
		au._exigir(tela3 != null and tela3._nome.text != "", "f6b1_criar", "o nome já vem sorteado")
		await au._ver("f6b1_criar")
		if au._quer("f6b1_criar_nome14") and tela3 != null:
			au.gs.definir_rascunho("name", "MMMMMMMMMMMMMMMMMM")
			await au._esperar(0.2)
			au._exigir(tela3._nome.text.length() == 14, "f6b1_criar_nome14", "o nome corta em 14 letras (%d)" % tela3._nome.text.length())
			tela3._nome.text = "A1B2C3D4E5F6G7H8I9J0"
			tela3._ao_digitar(tela3._nome.text)
			au._exigir(tela3._nome.text == "ABCDEFGHIJ", "f6b1_criar_nome14", "colar com números filtra antes de cortar (%s)" % tela3._nome.text)
			au.gs.definir_rascunho("name", "MMMMMMMMMMMMMMMMMM")
			await au._esperar(0.1)
			await au._ver("f6b1_criar_nome14")
		if au._quer("f6b1_criar_cores") and tela3 != null:
			au.gs.definir_rascunho("skin", "skin_5")
			au.gs.definir_rascunho("hair_color", "platinum")
			au.gs.definir_rascunho("shorts_color", "white")
			await au._esperar(0.2)
			await au._ver("f6b1_criar_cores")
			au.gs.definir_rascunho("skin", "skin_1")
			au.gs.definir_rascunho("hair_color", "black")
			au.gs.definir_rascunho("shorts_color", "purple")
			await au._esperar(0.2)
			await au._ver("f6b1_criar_cores")
		if au._quer("f6b1_criar_vazio") and tela3 != null:
			tela3._nome.text = ""
			tela3._ao_digitar("")
			tela3._confirmar()
			await au._esperar(0.3)
			au._exigir(au.gs.sucessao_estado() == "creating" and tela3._nome.text != "", "f6b1_criar_vazio", "nome vazio não confirma e o campo volta a um nome sorteado")
			await au._ver("f6b1_criar_vazio")
		if au._quer("f6b1_chegada") and tela3 != null:
			var nome_final := "Zeca Chave"
			au.gs.definir_rascunho("name", nome_final)
			tela3._confirmar()
			au._exigir(au.gs.sucessao_estado() == "arriving", "f6b1_chegada", "CONFIRMAR leva à chegada curta (%s)" % au.gs.sucessao_estado())
			await au._esperar(1.4)
			await au._ver("f6b1_chegada")
			for i in 40:
				if au.gs.sucessao_estado() == "none":
					break
				await au._esperar(0.1)
			au._exigir(au.gs.sucessao_estado() == "none" and au.gs.nome_lutador() == nome_final, "f6b1_chegada", "a chegada acaba sozinha e o discípulo tem o nome escolhido (%s)" % au.gs.nome_lutador())
			await au._esperar(0.5)
			au._exigir(au._cena.get_node("Sala").mentor_visivel(), "f6b1_chegada", "o John segue sentado depois da chegada")

	# --- Abrir o jogo com a criação em andamento (save): tela sobre a garagem escurecida, sem tocar a cena ---
	if au._quer("f6b1_save_criacao"):
		au._f6b1_fim("Tati Gancho", true)
		await au._abrir()
		await au._esperar(0.4)
		au.gs.receber_discipulo()
		await au._esperar(0.3)
		var snap: Dictionary = au.gs.para_save()
		au.gs.aplicar_save(snap.duplicate(true))
		await au._abrir()
		await au._esperar(1.0)
		au._exigir(au.gs.sucessao_estado() == "creating", "f6b1_save_criacao", "o save abre na criação (%s)" % au.gs.sucessao_estado())
		var t6: Node = await au._f6b1_janela_criar()
		au._exigir(t6 != null, "f6b1_save_criacao", "a tela de criação deveria abrir")
		await au._ver("f6b1_save_criacao")

	# --- John mentor sentado no caixote, balão e toques ---
	if au._quer("f6b1_mentor_sentado") or au._quer("f6b1_mentor_balao") or au._quer("f6b1_mentor_balao_isso") or au._quer("f6b1_mentor_toques"):
		au._novo_jogo()
		au.gs.escola["mentors"] = ["first"]
		au.gs.discipulo = {"name": "Tati Gancho", "look": au.gs.disciples.look_padrao.duplicate(), "campaign": 2}
		await au._abrir()
		await au._esperar(0.6)
		var sala_m: Node = au._cena.get_node("Sala")
		au._exigir(sala_m.mentor_visivel() and sala_m._caixote.visible, "f6b1_mentor_sentado", "John sentado no caixote em mentor_spot")
		au._exigir(sala_m._mentor.position == Vector2(254, 252), "f6b1_mentor_sentado", "pés do mentor em mentor_spot: %s" % str(sala_m._mentor.position))
		await au._ver("f6b1_mentor_sentado")
		var cu2: Node = au._cena_ui()
		for caso in [["f6b1_mentor_balao", "vamos ver sua guarda."], ["f6b1_mentor_balao_isso", "isso."]]:
			if au._quer(caso[0]):
				cu2._falar({"ator": "first", "line": "t", "text": caso[1], "seconds": 4.0})
				await au._esperar(0.2)
				au._balao().completar()
				await au._esperar(0.1)
				au._exigir(au._balao().ativo(), caso[0], "o balão do John sentado deveria aparecer")
				au._checar_balao_6b1(caso[0], "first")
				await au._ver(caso[0])
				au._balao().fechar_agora()
		if au._quer("f6b1_mentor_toques"):
			var plano := {"momento": "win_return", "version": "short", "start": 0.0, "duration": 0.44, "taps": [0.11, 0.33],
				"tap_sound": "tap_fist", "anim": "mentor_first_taps", "guard": 0.0, "cena": "", "com_fala": false}
			au.gs.toques_mentor_pedidos.emit(plano)
			await au._esperar(0.2)
			au._exigir(sala_m._mentor_pose == "taps", "f6b1_mentor_toques", "o John faz os toques (%s)" % sala_m._mentor_pose)
			await au._ver("f6b1_mentor_toques")
			await au._esperar(0.5)
			au._exigir(sala_m._mentor_pose == "rest", "f6b1_mentor_toques", "depois dos toques volta ao sit_rest")
			au.gs.toques_mentor_pedidos.emit(plano)
			await au._esperar(0.05)
			au.gs.toques_mentor_cancelados.emit()
			au._exigir(sala_m._mentor_pose == "rest", "f6b1_mentor_toques", "cancelar volta ao sit_rest na hora")

	# --- Tela de fim com o botão novo; nome de 14 letras no resumo e no HUD ---
	if au._quer("f6b1_fim_botao") or au._quer("f6b1_fim_nome14"):
		au._f6b1_fim("Tati Gancho")
		await au._abrir()
		await au._esperar(0.9)
		var fim_j: Node = au._cena.get_node("Fluxo").janela
		var bt: Button = fim_j.painel.get_node_or_null("BotaoNovoDiscipulo")
		au._exigir(bt != null, "f6b1_fim_botao", "o botão RECEBER NOVO DISCÍPULO deveria existir")
		if bt != null:
			au._exigir(au._texto_botao(bt) in ["RECEBER NOVO DISCÍPULO", "NOVO DISCÍPULO"], "f6b1_fim_botao", "texto do botão: %s" % au._texto_botao(bt))
		await au._ver("f6b1_fim_botao")
		if au._quer("f6b1_fim_nome14"):
			au._f6b1_fim("MMMMMMMMMMMMMM")
			await au._abrir()
			await au._esperar(0.9)
			await au._ver("f6b1_fim_nome14")
	if au._quer("f6b1_hud_nome14"):
		au._novo_jogo()
		au.gs.discipulo = {"name": "MMMMMMMMMMMMMM", "look": au.gs.disciples.look_padrao.duplicate(), "campaign": 2}
		await au._abrir()
		await au._esperar(0.6)
		await au._ver("f6b1_hud_nome14")

	# --- Cartão "o que você trouxe" e escolha da arte com o nome ---
	if au._quer("f6b1_cartao"):
		au._novo_jogo()
		au.gs.discipulo = {"name": "MMMMMMMMMMMMMM", "look": au.gs.disciples.look_padrao.duplicate(), "campaign": 2}
		au._com_nos(au.NOS_MISTA, 40)
		await au._abrir()
		await au._esperar(0.5)
		au._cena.get_node("Fluxo")._ao_nova_carreira_iniciada(au.gs.cartao_inicio())
		await au._esperar(0.5)
		await au._ver("f6b1_cartao")
	if au._quer("f6b1_arte"):
		au._f6b1_fim("Tati Gancho")
		au.gs.local_id = "gym"
		au.gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		await au._abrir()
		await au._esperar(0.6)
		au.gs.nova_carreira()
		await au._esperar(0.8)
		au._exigir(au._cena.get_node("Fluxo").janela != null, "f6b1_arte", "a janela de arte deveria estar aberta")
		await au._ver("f6b1_arte")

	# --- Luva inicial: o cartão diz "o par do John" ---
	if au._quer("f6b1_luva_hover"):
		au._novo_jogo()
		au.gs.discipulo = {"name": "Tati Gancho", "look": au.gs.disciples.look_padrao.duplicate(), "campaign": 2}
		await au._abrir()
		await au._abrir_loja()
		var loja: Node = au._cena.get_node("PainelLoja")
		loja._sobre("la")
		await au._esperar(0.2)
		au._exigir(au.gs.descricao_luva_inicial().begins_with("O par do John"), "f6b1_luva_hover", "descrição da luva inicial: %s" % au.gs.descricao_luva_inicial())
		await au._ver("f6b1_luva_hover")


## PULAR: o anel enche com ESC/ESPAÇO segurado, o botão pula até a tela de criação e, depois dela, até o fim (estado final em ~0,3 s).
func _rodar_fase6b1_pular() -> void:
	if not (au._quer("f6b1_pular_anel") or au._quer("f6b1_pular")):
		return
	au._f6b1_fim("Tati Gancho")
	await au._abrir()
	await au._esperar(0.5)
	var cu: Node = au._cena_ui()
	var sala: Node = au._cena.get_node("Sala")
	au.gs.receber_discipulo()
	await au._esperar(1.0)
	au._exigir(cu._botao.visible and cu._chip.visible, "f6b1_pular_anel", "o botão PULAR e a dica 'SEGURE ESC: PULAR' aparecem durante a cena")
	cu.player.ler_teclado = false
	cu.player.segurar_pular(true, 0.25)  # metade dos 0,5 s
	await au._esperar(0.1)
	au._exigir(cu._atlas.region.position.x == 44.0, "f6b1_pular_anel", "o anel está na metade (quadro %d)" % int(cu._atlas.region.position.x / 11.0))
	await au._ver("f6b1_pular_anel")
	cu.player.segurar_pular(false, 0.0)
	cu.player.ler_teclado = true
	if au._quer("f6b1_pular"):
		cu._botao.pressed.emit()  # PULAR até a tela de criação
		await au._esperar(0.5)
		var tela: Node = await au._f6b1_janela_criar()
		au._exigir(tela != null and au.gs.sucessao_estado() == "creating", "f6b1_pular", "PULAR leva direto à tela de criação (%s)" % au.gs.sucessao_estado())
		au._exigir(not cu._botao.visible, "f6b1_pular", "na tela de criação não se pula")
		au._exigir(not cu.player.pular(), "f6b1_pular", "pular() na tela de criação não faz nada")
		tela._confirmar()
		await au._esperar(1.0)
		cu._botao.pressed.emit()  # PULAR a parte 2: estado final em ~0,3 s
		await au._esperar(0.7)
		au._exigir(au.gs.sucessao_estado() == "none", "f6b1_pular", "depois de pular a parte 2 o controle volta (%s)" % au.gs.sucessao_estado())
		au._exigir(sala.mentor_visivel() and sala._caixote.visible and sala._lutador.visible, "f6b1_pular", "estado final: John sentado no caixote e o discípulo de guarda")
		await au._esperar(0.5)
		au._cena.get_node("Fluxo").fechar_cartao_aberto()
		await au._ver("f6b1_pular")



# ---------------------------------------------------------------------------------------------
# Fase 6b2: cara de lutador. Tela de criação em 2 colunas, 4 cortes, partes de cima, faixa e meião, segundo mentor parado.
# ---------------------------------------------------------------------------------------------
