extends RefCounted
## Estados do ui_audit.gd: Fases 5.4 e 6a. Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).


var au


func _init(auditor) -> void:
	au = auditor


func _abrir_arvore() -> Node:
	await au._abrir()
	var fluxo: Node = au._cena.get_node("Fluxo")
	fluxo.abrir_arvore()
	await au._esperar(0.5)
	return fluxo.janela


func _mapa() -> Node:
	return au._cena.get_node("Fluxo").janela


## Nós comprados + Legado + último nó, com a foto da campanha igual (ativos = todos) ou vazia (comprado nesta campanha).
func _com_nos54(ids: Array, legado: int, ativos: bool = true) -> void:
	au.gs.permanente["skill_nodes"] = ids.duplicate()
	au.gs.permanente["legacy_total"] = legado
	au.gs.permanente["tree_last_node"] = str(ids.back()) if not ids.is_empty() else ""
	au.gs.nos_ativos_ids = ids.duplicate() if ativos else []
	au.gs._recalcular_bonus()


func _todos_os_nos() -> Array:
	var r: Array = []
	for n in au.gs.lutas.arvore:
		r.append(str(n.id))
	return r


func _meio54() -> Array:
	return ["body_jab", "career_purse", "body_crew", "body_muscle_memory", "gar_tape", "gar_radio", "camp_poster",
		"career_scouting", "career_crowd"]


func _rodar_fase54() -> void:
	# --- Mapa: começo, meio e completo ---
	if au._quer("f54_mapa_inicio"):
		au._novo_jogo()
		_com_nos54([], 30)
		await _abrir_arvore()
		au._exigir(_mapa() != null and au._eh(_mapa(), "JanelaMapa"), "f54_mapa_inicio", "o botão da sala deveria abrir o mapa")
		await au._ver("f54_mapa_inicio")
	if au._quer("f54_mapa_meio"):
		au._novo_jogo()
		au._garagem_arte("boxing", [], 800.0)
		_com_nos54(_meio54(), 400)
		await _abrir_arvore()
		await au._ver("f54_mapa_meio")
	if au._quer("f54_mapa_completo") or au._quer("f54_mapa_completo_noroeste") or au._quer("f54_mapa_completo_sudeste"):
		au._novo_jogo()
		au._garagem_arte("boxing", [], 800.0)
		au.gs.crew_click_comprado = true
		_com_nos54(_todos_os_nos(), 0)
		var j: Node = await _abrir_arvore()
		if au._quer("f54_mapa_completo"):
			await au._ver("f54_mapa_completo")
		if au._quer("f54_mapa_completo_noroeste"):
			j.mover_camera(Vector2i(-9999, -9999))
			await au._esperar(0.2)
			await au._ver("f54_mapa_completo_noroeste")
		if au._quer("f54_mapa_completo_sudeste"):
			j.mover_camera(Vector2i(9999, 9999))
			await au._esperar(0.2)
			await au._ver("f54_mapa_completo_sudeste")

	# --- Cartão do nó em cada estado ---
	for def in [
			["f54_cartao_compravel", "gar_rope", 400, true],
			["f54_cartao_sem_legado", "body_heavy_hands", 100, true],
			["f54_cartao_arte", "box_counter", 400, true],
			["f54_cartao_grito_sem_loja", "link_shout", 600, true],
			["f54_cartao_comprado", "gar_tape", 400, false],
			["f54_cartao_ativo", "gar_tape", 400, true]]:
		if not au._quer(def[0]):
			continue
		au._novo_jogo()
		au._garagem_arte("boxing", [], 800.0)
		var nos := _meio54()
		if def[1] == "link_shout":
			nos = nos + ["gar_rope"]
		_com_nos54(nos, int(def[2]), bool(def[3]))
		var j: Node = await _abrir_arvore()
		j.ir_para(str(def[1]))
		await au._esperar(0.2)
		j.mostrar_cartao(str(def[1]))
		await au._esperar(0.2)
		au._exigir(j.cartao_aberto() == str(def[1]), str(def[0]), "o cartão de %s deveria estar aberto" % str(def[1]))
		await au._ver(str(def[0]))

	# --- Comprar: o nó acende, os vizinhos aparecem, a neblina recua ---
	if au._quer("f54_revelacao") or au._quer("f54_revelacao_fim"):
		au._novo_jogo()
		_com_nos54(["body_jab", "career_purse"], 30)
		var j: Node = await _abrir_arvore()
		j.ir_para("gar_tape")
		await au._esperar(0.2)
		var antes: int = au.gs.legado_disponivel()
		j.clicar_no("gar_tape")
		await au._esperar(0.12)
		au._exigir(au.gs.legado_disponivel() == antes - 15 and au.gs.estado_mapa("gar_tape") == "owned", "f54_revelacao",
			"clicar no nó à vista deveria comprar (Legado %d -> %d)" % [antes, au.gs.legado_disponivel()])
		await au._ver("f54_revelacao")
		await au._esperar(1.1)
		au._exigir("gar_rope" in j.nos_desenhados() and "gar_radio" in j.nos_desenhados(), "f54_revelacao_fim", "os vizinhos deveriam ter aparecido")
		au._exigir(j.fog_nivel_em("gar_rope") == 0, "f54_revelacao_fim", "a neblina deveria ter recuado em volta do nó novo")
		await au._ver("f54_revelacao_fim")

	# --- Botão da sala: normal, brilhando, com dica, na academia ---
	if au._quer("f54_botao_normal"):
		au._novo_jogo()
		_com_nos54([], 0)
		await au._abrir()
		var b: Node = au._cena.get_node("BotaoMapa")
		au._estado = "f54_botao_normal"
		au._exigir(not au.gs.ha_no_compravel() and not b.brilhando(), au._estado, "sem nó à vista que o Legado pague o botão fica quieto")
		await au._ver("f54_botao_normal")
	if au._quer("f54_botao_brilho") or au._quer("f54_botao_hover"):
		au._novo_jogo()
		_com_nos54([], 30)
		await au._abrir()
		var b: Node = au._cena.get_node("BotaoMapa")
		au._estado = "f54_botao_brilho"
		au._exigir(au.gs.ha_no_compravel() and b.brilhando(), au._estado, "com nó à vista que o Legado paga o botão brilha")
		if au._quer("f54_botao_brilho"):
			await au._ver("f54_botao_brilho")
		if au._quer("f54_botao_hover"):
			au._dica_em(b.texto_dica(), Vector2(143, 33))
			await au._esperar(0.2)
			await au._ver("f54_botao_hover")
			au._sem_dica()
	if au._quer("f54_botao_gym"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill"], 800.0)
		_com_nos54(["body_jab"], 20)
		await au._abrir()
		var b: Node = au._cena.get_node("BotaoMapa")
		au._exigir(b.position == Vector2(118, 22) and b.size == Vector2(22, 22), "f54_botao_gym", "6d2: botão em (118,22) 22x22, ao lado dos atributos")
		await au._ver("f54_botao_gym")

	# --- Tela de fim: o botão ÁRVORE com o ícone, o mapa por ele e a volta ---
	if au._quer("f54_fim_botao") or au._quer("f54_mapa_do_fim") or au._quer("f54_fim_volta"):
		au._derrota_pendente([], 30)
		_com_nos54([], 30)
		au.gs.fim["legacy_total"] = 30
		await au._abrir()
		await au._esperar(0.9)
		var fl: Node = au._cena.get_node("Fluxo")
		if au._quer("f54_fim_botao"):
			await au._ver("f54_fim_botao")
		if au._quer("f54_mapa_do_fim") or au._quer("f54_fim_volta"):
			fl.janela.arvore_pedido.emit()
			await au._esperar(0.5)
			au._exigir(au._eh(fl.janela, "JanelaMapa"), "f54_mapa_do_fim", "o botão ÁRVORE do fim deveria abrir o mesmo mapa")
			if au._quer("f54_mapa_do_fim"):
				await au._ver("f54_mapa_do_fim")
			if au._quer("f54_fim_volta"):
				fl.janela.clicar_no("body_jab")
				await au._esperar(1.0)
				fl.janela.fechar_pedido.emit()
				await au._esperar(0.9)
				au._exigir(au._eh(fl.janela, "JanelaFim") and au.gs.tem_fim_pendente(), "f54_fim_volta", "fechar o mapa volta para a tela de fim")
				await au._ver("f54_fim_volta")

	# --- Save antigo (v9, os 12 nós de sempre): abre com eles comprados no centro e os vizinhos à vista ---
	if au._quer("f54_save_antigo"):
		au._fechar_cena()
		au.gs.definir_assistido(false)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(au.PASTA_SAVE))
		var velhos := ["body_jab", "body_muscle_memory", "body_heavy_hands", "body_crew", "body_crew_2", "career_purse",
			"career_scouting", "career_purse_2", "career_crowd", "career_good_loser", "style_boxing", "style_bjj"]
		var doc := {"version": 9, "saved_at_unix": 1730000000, "state": {"career": {"training": 5.0, "art": "boxing"},
			"permanent": {"legacy_total": 60, "career_number": 4, "skill_nodes": velhos, "arts_unlocked": ["boxing", "bjj"], "last_art": "boxing"},
			"ending": null}}
		var f := FileAccess.open(au.PASTA_SAVE + "save.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(doc))
		f.close()
		au.gs.inicializar(au.PASTA_SAVE, au.CONFIG)
		au.gs.autosave_ativo = false
		au._exigir(au.gs.estado_mapa("body_jab") == "owned" and au.gs.estado_mapa("style_boxing") == "owned" and au.gs.legado_disponivel() == 60,
			"f54_save_antigo", "migração: nós e Legado iguais")
		au._exigir(au.gs.estado_mapa("gar_tape") == "visible" and au.gs.estado_mapa("box_counter") == "visible", "f54_save_antigo",
			"migração: os vizinhos dos nós antigos abrem à vista")
		await au._abrir()
		var fl: Node = au._cena.get_node("Fluxo")
		fl.abrir_arvore()
		await au._esperar(0.5)
		au._exigir(au._eh(fl.janela, "JanelaMapa"), "f54_save_antigo", "o mapa deveria abrir com o save migrado")
		await au._ver("f54_save_antigo")
		au.gs.apagar_save()


# ---------------------------------------------------------------------------------------------
# Fase 6a: abertura, balão de fala, Osmar, parede da memória, gesto, discípulo e selo da garagem salva
# ---------------------------------------------------------------------------------------------

## Campanha do 1º lutador (John Bullet): sem sufixo _disc, com gesto.
func _john() -> void:
	au.gs.permanente["career_number"] = 1
	au.gs.escola["first_fighter_campaign"] = 1


## Faz a abertura voltar a "pendente" (como num save que nunca a viu).
func _abertura_pendente() -> void:
	au.gs.escola["milestones"].erase("prologue_seen")
	au.gs._reiniciar_falas()


## Espera o balão `id` aparecer (até 12 s).
func _esperar_fala(id: String) -> bool:
	for i in 240:
		if au._balao().ativo() and str(au._balao().id) == id:
			return true
		await au._esperar(0.05)
	return false


func _rodar_fase6a() -> void:
	# --- Segurar ESC: o anel enche e o chip acende; ao completar, a abertura acaba ---
	if au._quer("f6a_esc_chip"):
		au._novo_jogo()
		_john()
		_abertura_pendente()
		await au._abrir()
		au._estado = "f6a_esc_chip"
		au._exigir(au.gs.abertura_estado() == "playing", au._estado, "a abertura deveria estar tocando")
		var chip: Node = null
		for c in au._cena.get_children():
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("pular_abertura.gd"):
				chip = c
		au._exigir(chip != null and chip.visible, au._estado, "o chip esc: pular deveria aparecer durante a abertura")
		au._tecla(KEY_ESCAPE, true)
		await au._esperar(0.3)
		au._exigir(chip != null and chip._anel.frame >= 3 and chip._anel.frame <= 7, au._estado, "o anel deveria estar enchendo (quadro %d)" % chip._anel.frame)
		await au._ver("f6a_esc_chip")
		await au._esperar(0.4)
		au._exigir(au.gs.abertura_estado() == "over", au._estado, "segurar ESC 0,5 s deveria pular a abertura")
		au._exigir(not au.gs.tem_balao() and not au._balao().ativo(), au._estado, "pular deveria fechar o balão")
		au._tecla(KEY_ESCAPE, false)
		await au._esperar(0.1)
		au._exigir(not chip.visible, au._estado, "o chip some depois da abertura")

	# --- Abertura batida a batida (o saco vale em t = 0; ninguém anda) ---
	if au._quer("f6a_abertura_gesto") or au._quer("f6a_abertura_b1") or au._quer("f6a_abertura_b4") or au._quer("f6a_abertura_fim"):
		au._novo_jogo()
		_john()
		_abertura_pendente()
		await au._abrir()
		au._estado = "f6a_abertura_gesto"
		au._exigir(au.gs.abertura_estado() == "playing" and au.gs.marco("prologue_seen"), au._estado, "marco prologue_seen gravado em t = 0")
		await au._ver("f6a_abertura_gesto")
		for n in range(1, 5):
			var id := "open_%d" % n
			var nome_n := "f6a_abertura_b%d" % n
			var achou: bool = await _esperar_fala(id)
			au._exigir(achou, nome_n, "o balão %s deveria aparecer" % id)
			await au._esperar(0.25)
			au._balao().completar()
			await au._esperar(0.1)
			au._checar_balao(nome_n, "coach" if n <= 2 else "first")
			if au._quer(nome_n):
				await au._ver(nome_n)
		for i in 120:
			if au.gs.abertura_estado() == "over":
				break
			await au._esperar(0.1)
		au._exigir(au.gs.abertura_estado() == "over", "f6a_abertura_fim", "a abertura deveria acabar em até 20 s")
		await au._esperar(0.2)
		await au._ver("f6a_abertura_fim")

	# --- Balões do John e do Osmar na garagem ---
	if au._quer("f6a_osmar_1l") or au._quer("f6a_osmar_2l") or au._quer("f6a_osmar_borda") or au._quer("f6a_john_1l") or au._quer("f6a_john_2l") \
			or au._quer("f6a_john_corda") or au._quer("f6a_pergunta"):
		au._novo_jogo()
		_john()
		await au._abrir()
		await au._falar("coach", "chegou outro aviso, john.")
		au._checar_balao("f6a_osmar_1l", "coach")
		await au._ver("f6a_osmar_1l")
		await au._falar("coach", "o aviso saiu da parede.\nainda é nossa, viu?")
		au._checar_balao("f6a_osmar_2l", "coach")
		await au._ver("f6a_osmar_2l")
		await au._falar("coach", "abcdefghijklmnopqrstuvwxyz\nabcdefghijklmnopqrstuvwxyz")
		au._checar_balao("f6a_osmar_borda", "coach")
		await au._ver("f6a_osmar_borda")
		await au._falar("first", "vou botar um nome ali.")
		au._checar_balao("f6a_john_1l", "first")
		await au._ver("f6a_john_1l")
		await au._falar("first", "o muralha riu da ficha:\nescola: nenhuma.")
		au._checar_balao("f6a_john_2l", "first")
		await au._ver("f6a_john_2l")
		await au._falar("first", "tem pergunta, osmar?")
		await au._ver("f6a_pergunta")
		au._balao().fechar_agora()
		au.gs.aparelhos_montados_ids = ["punching_bag", "jump_rope"]
		au.gs.definir_foco("jump_rope")
		await au._esperar(0.3)
		await au._falar("first", "o muralha riu da ficha:\nescola: nenhuma.")
		au._checar_balao("f6a_john_corda", "first")
		await au._ver("f6a_john_corda")

	# --- Balão do John seguindo a cabeça em todos os focos (esteira, saco) ---
	if au._quer("f6a_john_esteira"):
		au._novo_jogo()
		_john()
		await au._abrir()
		au.gs.aparelhos_montados_ids = ["punching_bag", "jump_rope", "treadmill"]
		var sala_e: Node = au._cena.get_node("Sala")
		for foco_t in ["treadmill", "punching_bag"]:
			au.gs.definir_foco(foco_t)
			await au._esperar(0.3)
			await au._falar("first", "o muralha riu da ficha:\nescola: nenhuma.")
			au._checar_balao("f6a_john_esteira", "first")
			var cab: Vector2 = sala_e.ponto_cabeca("first")
			var rt: Rect2 = au._balao().retangulo_total()
			au._estado = "f6a_john_esteira"
			# o balão sobe até y<=178 (regra da zona do alvo); na horizontal ele tem de ficar sobre a cabeça do John
			au._exigir(absf(rt.get_center().x - cab.x) < 6.0,
				"f6a_john_esteira", "o rabicho não aponta para a cabeça (%s): balão %s, cabeça %s" % [foco_t, au._fmt(rt), str(cab)])
			if foco_t == "treadmill":
				await au._ver("f6a_john_esteira")
			au._balao().fechar_agora()

	# --- Balões na academia ---
	if au._quer("f6a_gym_sem_osmar") or au._quer("f6a_gym_john"):
		au._novo_jogo()
		_john()
		au._academia("boxing", ["treadmill", "jump_rope"], 3000.0)
		await au._abrir()
		await au._esperar(2.0)  # tempo de sobra para qualquer fala de chegada tocar
		au._exigir(not (au._balao().ativo() and au._balao().speaker == "coach"), "f6a_gym_sem_osmar", "o Osmar não fala na academia (balão: %s)" % str(au._balao().id))
		await au._ver("f6a_gym_sem_osmar")
		await au._falar("first", "o muralha riu da ficha:\nescola: nenhuma.")
		au._checar_balao("f6a_gym_john", "first")
		await au._ver("f6a_gym_john")

	# --- Parede da memória: antes, recorte, depois; hovers ---
	if au._quer("f6a_parede_antes") or au._quer("f6a_hover_ficha") or au._quer("f6a_hover_aviso"):
		au._novo_jogo()
		_john()
		await au._abrir()
		var sala: Node = au._cena.get_node("Sala")
		au._estado = "f6a_parede_antes"
		au._exigir(sala._parede.notice_debt.sprite.visible and not sala._parede.photo_team.sprite.visible, au._estado, "antes: aviso na parede, sem foto da equipe")
		au._exigir(sala._parede.form.sprite.nome_sprite == "wall_form_blank" and not sala._parede.clipping.sprite.visible, au._estado, "antes: ficha em branco, sem recorte")
		au._exigir(sala._osmar.visible and sala._osmar.position == Vector2(196, 236), au._estado, "Osmar no ponto dele na garagem")
		await au._ver("f6a_parede_antes")
		if au._quer("f6a_hover_ficha"):
			au._dica_inst().ancora_fixa = Vector2(240, 96)
			sala._hover_em(Vector2(212, 70))
			await au._esperar(0.1)
			au._exigir(au._dica_inst().texto_atual() == "ESCOLA: NENHUMA", "f6a_hover_ficha", "dica da ficha: %s" % au._dica_inst().texto_atual())
			await au._ver("f6a_hover_ficha")
			au._sem_dica()
		if au._quer("f6a_hover_aviso"):
			au._dica_inst().ancora_fixa = Vector2(230, 96)
			sala._hover_em(Vector2(185, 60))
			await au._esperar(0.1)
			au._exigir(au._dica_inst().texto_atual().begins_with("AVISO DE COBRANÇA"), "f6a_hover_aviso", "dica do aviso: %s" % au._dica_inst().texto_atual())
			await au._ver("f6a_hover_aviso")
			au._sem_dica()
	if au._quer("f6a_parede_recorte"):
		au._novo_jogo()
		_john()
		au.gs._gravar_marco("first_school_win", {}, false)
		await au._abrir()
		au._estado = "f6a_parede_recorte"
		au._exigir(au._cena.get_node("Sala")._parede.clipping.sprite.visible, au._estado, "o recorte aparece depois da 1ª vitória da escola")
		await au._ver("f6a_parede_recorte")
	if au._quer("f6a_parede_depois") or au._quer("f6a_hover_ficha_depois"):
		au._novo_jogo()
		_john()
		au.gs._gravar_marco("first_school_win", {}, false)
		au.gs._gravar_marco("garage_saved", {"opponent": "x", "by_first": false}, false)
		au.gs._gravar_marco("garage_saved_seen", {}, false)
		await au._abrir()
		var sala2: Node = au._cena.get_node("Sala")
		au._estado = "f6a_parede_depois"
		au._exigir(not sala2._parede.notice_debt.sprite.visible and sala2._parede.photo_team.sprite.visible and sala2._parede.school_symbol.sprite.visible,
			au._estado, "depois: aviso saiu; foto da equipe e símbolo aparecem")
		au._exigir(sala2._parede.form.sprite.nome_sprite == "wall_form_named", au._estado, "depois: ficha com o nome da escola")
		await au._ver("f6a_parede_depois")
		if au._quer("f6a_hover_ficha_depois"):
			au._dica_inst().ancora_fixa = Vector2(240, 96)
			sala2._hover_em(Vector2(212, 70))
			await au._esperar(0.1)
			au._exigir(au._dica_inst().texto_atual() == "ESCOLA: RAÍZES FIGHT CLUB", "f6a_hover_ficha_depois", "dica da ficha depois: %s" % au._dica_inst().texto_atual())
			await au._ver("f6a_hover_ficha_depois")
			au._sem_dica()

	# --- Gesto na sala: completo (luva nova) e curto (sala parada); clique cancela ---
	if au._quer("f6a_gesto_sala") or au._quer("f6a_gesto_curto") or au._quer("f6a_gesto_cancela"):
		au._novo_jogo()
		_john()
		await au._abrir()
		await au._esperar(2.5)
		var sala3: Node = au._cena.get_node("Sala")
		au._exigir(not au.gs.pedir_gesto("glove", 1).is_empty(), "f6a_gesto_sala", "o gesto de calçar a luva deveria ser aceito")
		await au._esperar(0.3 + 0.5)
		au._exigir(sala3._gesto_sprite == "fighter_gesture", "f6a_gesto_sala", "a sala deveria estar tocando fighter_gesture (%s)" % sala3._gesto_sprite)
		await au._ver("f6a_gesto_sala")
		await au._esperar(1.0)
		au._exigir(sala3._gesto_sprite == "", "f6a_gesto_sala", "o gesto completo acaba em ~1,2 s")
		if au._quer("f6a_gesto_curto"):
			au.gs._gesto = {}
			au._exigir(not au.gs.pedir_gesto("idle").is_empty(), "f6a_gesto_curto", "o gesto curto da sala parada deveria ser aceito")
			await au._esperar(0.25)
			au._exigir(sala3._gesto_sprite == "fighter_gesture_short", "f6a_gesto_curto", "a sala deveria estar tocando fighter_gesture_short (%s)" % sala3._gesto_sprite)
			await au._ver("f6a_gesto_curto")
			await au._esperar(0.6)
		if au._quer("f6a_gesto_cancela"):
			au.gs._gesto = {}
			au.gs.pedir_gesto("idle")
			await au._esperar(0.2)
			au._exigir(sala3._gesto_sprite != "", "f6a_gesto_cancela", "o gesto deveria estar tocando antes do clique")
			sala3.treinar_pelo_teclado()
			au._exigir(sala3._gesto_sprite == "" and not sala3._gesto.ativo(), "f6a_gesto_cancela", "o clique no saco cancela o gesto no mesmo quadro")
			await au._ver("f6a_gesto_cancela")

	# --- Luta do John: gesto na entrada e na vitória ---
	if au._quer("f6a_gesto_luta") or au._quer("f6a_gesto_vitoria"):
		var achada = au._achar_luta(true, true)
		au._novo_jogo()
		_john()
		au.gs.atributos = achada.atr
		await au._abrir()
		au.gs.rng.seed = int(achada.k)
		var fluxo: Node = au._cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await au._esperar(0.3)
		fluxo.janela.lutar_pedido.emit()
		await au._esperar(0.85)
		var tela: Node = fluxo.tela
		au._estado = "f6a_gesto_luta"
		au._exigir(tela._gesto_nome.begins_with("fight_player_gesture"), au._estado, "a entrada da luta do John tem o gesto (%s)" % tela._gesto_nome)
		await au._ver("f6a_gesto_luta")
		if au._quer("f6a_gesto_vitoria"):
			var res: Dictionary = au.gs.luta.result
			tela._clock = float(res.t_end) + 2.0
			await au._esperar(0.45)
			await au._ver("f6a_gesto_vitoria")

	# --- Discípulo padrão (campanha 2 em diante): folhas _disc, nunca faz o gesto ---
	if au._quer("f6a_discipulo_garagem") or au._quer("f6a_discipulo_previa") or au._quer("f6a_discipulo_luta"):
		var achada2 = au._achar_luta(true, true)
		au._novo_jogo()
		au.gs.atributos = achada2.atr
		await au._abrir()
		var sala4: Node = au._cena.get_node("Sala")
		au._estado = "f6a_discipulo_garagem"
		au._exigir(au.gs.lutador_atual() == "disciple", au._estado, "campanha 2 é do discípulo")
		au._exigir(sala4._lutador.nome_sprite.ends_with("_disc"), au._estado, "a sala usa a folha _disc: %s" % sala4._lutador.nome_sprite)
		au._exigir(au.gs.pedir_gesto("opening").is_empty() and au.gs.pedir_gesto("fight_intro").is_empty(), au._estado, "o discípulo nunca faz o gesto")
		await au._ver("f6a_discipulo_garagem")
		au.gs.rng.seed = int(achada2.k)
		var fl: Node = au._cena.get_node("Fluxo")
		fl.abrir_previa()
		await au._esperar(0.3)
		await au._ver("f6a_discipulo_previa")
		fl.janela.lutar_pedido.emit()
		await au._esperar(1.0)
		au._estado = "f6a_discipulo_luta"
		au._exigir(fl.tela._l[0].spr.nome_sprite.ends_with("_disc") and fl.tela._l[0].spr.texture != null, au._estado, "a luta usa a folha _disc: %s" % fl.tela._l[0].spr.nome_sprite)
		au._exigir(fl.tela._gesto_nome == "", au._estado, "sem gesto na luta do discípulo")
		await au._ver("f6a_discipulo_luta")

	# --- Vitória do cinturão: selo da garagem salva (e sem selo quando o marco já existe) ---
	if au._quer("f6a_vitoria_selo"):
		au._novo_jogo()
		_john()
		au.gs.indice_escada = 3
		au.gs.fama = 150
		au.gs.atributos = {"strength": 5.0e7, "agility": 5.0e7, "endurance": 5.0e7}
		au.gs.rng.seed = 7
		au.gs.lutar()
		await au._abrir()
		await au._esperar(1.0)
		au._estado = "f6a_vitoria_selo"
		var jv: Node = au._cena.get_node("Fluxo").janela
		au._exigir(jv != null and jv.get_script() != null and str(jv.get_script().resource_path).ends_with("janela_vitoria.gd"), au._estado, "a vitória do cinturão deveria estar aberta")
		au._exigir(au.gs.marco("garage_saved"), au._estado, "o cinturão deveria gravar o marco garage_saved")
		await au._ver("f6a_vitoria_selo")
	if au._quer("f6a_vitoria_sem_selo"):
		au._novo_jogo()
		_john()
		au.gs._gravar_marco("garage_saved", {}, false)
		au.gs.indice_escada = 3
		au.gs.fama = 150
		au.gs.atributos = {"strength": 5.0e7, "agility": 5.0e7, "endurance": 5.0e7}
		au.gs.rng.seed = 7
		au.gs.lutar()
		await au._abrir()
		await au._esperar(1.0)
		await au._ver("f6a_vitoria_sem_selo")


# ---------------------------------------------------------------------------------------------
# Fase 6b1: passar o posto (cena, tela de criação, chegada curta, John mentor, nome no lugar de "Carreira N")
# ---------------------------------------------------------------------------------------------
