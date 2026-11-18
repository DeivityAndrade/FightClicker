extends RefCounted
## Estados do ui_audit.gd: Fase 6c2. Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).


var au


func _init(auditor) -> void:
	au = auditor


const NOMES_6C2 := ["Teo", "Duda", "Kaue", "Lia", "Rui", "Nina", "Beto", "Zeca", "Maya", "Caio"]
const NOMES_LONGOS_6C2 := ["Maximiliano Jr", "Bartolomeuzin", "Ana Clara Luiza", "Joao Pedro Neto", "Fernanda Cruz", "Wellington Jr", "Gabriela Lima", "Rodrigo Alves"]
const SKINS_6C2 := ["skin_1", "skin_2", "skin_3", "skin_4", "skin_5"]
const CORTES_6C2 := ["short", "buzz", "volume", "bun"]
const PARTES_6C2 := ["tank", "tee", "none"]
const CORES_PARTE_6C2 := ["white", "black", "gray", "blue", "green", "yellow"]


func _a6c2() -> bool:
	for n in au.ESTADOS_TODOS:
		if str(n).begins_with("f6c2_") and au._quer(n):
			return true
	return false


## Roster com `n` entradas (o John e depois discipulos de todo tipo de fim: com selo, passou o posto, parou em, desconhecido, cinturao).
func _roster_6c2(n: int, nomes: Array = NOMES_6C2) -> void:
	var lista: Array = [{"campaign": 1, "kind": "first", "name": "John Bullet", "look": null, "end": "retire", "wins": 4, "belt": true,
		"art": "", "opponent": "", "legacy_gained": 100, "honor": 15}]
	var opp: String = str(au.gs.lutas.adversarios[1].id)
	for i in range(1, n):
		var look = au._look_6b2({"skin": SKINS_6C2[i % 5], "hair_style": CORTES_6C2[i % 4], "top": PARTES_6C2[i % 3],
			"top_color": CORES_PARTE_6C2[i % 6], "headband_color": ["red", "white", "yellow", "green"][i % 4]})
		var e := {"campaign": i + 1, "kind": "disciple", "name": str(nomes[(i - 1) % nomes.size()]), "look": look, "end": "retire", "wins": 3,
			"belt": false, "art": "boxing" if i % 2 == 0 else "bjj", "opponent": "", "legacy_gained": 10, "honor": 6}
		match i % 5:
			1:
				e["end"] = "defeat"
				e["wins"] = 2
				e["honor"] = 0
				e["opponent"] = opp
			2:
				e["wins"] = 0
				e["honor"] = 0
				e["art"] = ""
			3:
				e["end"] = "unknown"
				e["wins"] = -1
				e["honor"] = 0
			4:
				e["wins"] = 4
				e["belt"] = true
				e["honor"] = 15
		lista.append(e)
	au.gs.escola["roster"] = lista
	au.gs.escola["mentors"] = ["first"]


## Janela do mural aberta pelo Fluxo (da sala, a qualquer hora). Devolve a janela.
func _abrir_mural_6c2(nome: String) -> Node:
	var fl: Node = au._cena.get_node("Fluxo")
	fl.abrir_mural()
	await au._esperar(0.45)
	au._exigir(fl.janela != null and str(fl.janela.get_script().resource_path).ends_with("janela_mural.gd"), nome, "a janela do mural abriu")
	return fl.janela


## Tela de fim pendente: sai com `vitorias` (cinturao a partir de 4). O saldo e os nos do hall sao ajustados depois.
func _fim_6c2(vitorias: int, saldo: int, nos: Array = []) -> void:
	au._novo_jogo()
	_roster_6c2(4)
	au.gs.indice_escada = vitorias
	au.gs.cinturao = vitorias >= 4
	au.gs.aposentar()
	au.gs.escola["honor"] = saldo
	au.gs.escola["hall_nodes"] = nos.duplicate()


func _rodar_fase6c2() -> void:
	if not _a6c2():
		return
	# --- Mural na parede: garagem (quadro por roster) e academia, hover do mural e da foto reta ---
	if au._quer("f6c2_mural_garagem") or au._quer("f6c2_mural_garagem_hover"):
		au._novo_jogo()
		_roster_6c2(5)
		await au._abrir()
		var sala: Node = au._cena.get_node("Sala")
		au._exigir(sala._mural.visible and sala._mural_rect.size != Vector2.ZERO, "f6c2_mural_garagem", "o mural aparece na garagem")
		await au._ver("f6c2_mural_garagem")
		if au._quer("f6c2_mural_garagem_hover"):
			var tip: String = sala._texto_parede(sala._mural_rect.get_center())
			au._exigir(tip != "", "f6c2_mural_garagem_hover", "o hover do mural tem texto")
			au._dica_em(tip, sala._mural_rect.get_center() + Vector2(0, 30))
			await au._esperar(0.3)
			await au._ver("f6c2_mural_garagem_hover")
			au._sem_dica()
	if au._quer("f6c2_mural_academia") or au._quer("f6c2_foto_academia_hover") or au._quer("f6c2_mural_academia_hover"):
		au._novo_jogo()
		_roster_6c2(9)
		au.gs._gravar_marco("cena_primeira_academia", {}, false)
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0, "punching_bag", 4)
		await au._abrir()
		var sala2: Node = au._cena.get_node("Sala")
		au._exigir(sala2._mural.visible, "f6c2_mural_academia", "o mural aparece na academia")
		var foto: Dictionary = sala2._parede.get("photo_old_gym", {})
		au._exigir(not foto.is_empty() and foto.sprite.visible and foto.sprite.frame == 0, "f6c2_mural_academia", "a foto reta da academia aparece (quadro 0)")
		await au._ver("f6c2_mural_academia")
		if au._quer("f6c2_mural_academia_hover"):
			var tm: String = sala2._texto_parede(sala2._mural_rect.get_center())
			au._dica_em(tm, sala2._mural_rect.get_center() + Vector2(0, 30))
			await au._esperar(0.3)
			await au._ver("f6c2_mural_academia_hover")
			au._sem_dica()
		if au._quer("f6c2_foto_academia_hover"):
			var pf := Vector2(221, 168)
			var tf: String = sala2._texto_parede(pf)
			au._exigir(tf != "", "f6c2_foto_academia_hover", "o hover old_photo_gym tem texto")
			au._dica_em(tf, pf + Vector2(10, 30))
			await au._esperar(0.3)
			await au._ver("f6c2_foto_academia_hover")
			au._sem_dica()
	if au._quer("f6c2_tela_mural_vazio"):
		au._novo_jogo()
		au.gs.escola["roster"] = []
		await au._abrir()
		await _abrir_mural_6c2("f6c2_tela_mural_vazio")
		await au._ver("f6c2_tela_mural_vazio")
	# --- Tela do mural: 1, 4, 9, nomes longos, 30 (paginas) ---
	for q in [["f6c2_tela_mural_1", 1, false], ["f6c2_tela_mural_4", 4, false], ["f6c2_tela_mural_9", 9, false],
			["f6c2_tela_mural_nomes_longos", 9, true], ["f6c2_tela_mural_30", 30, false]]:
		if au._quer(q[0]) or (q[0] == "f6c2_tela_mural_30" and au._quer("f6c2_tela_mural_30_ultima")):
			au._novo_jogo()
			_roster_6c2(int(q[1]), NOMES_LONGOS_6C2 if bool(q[2]) else NOMES_6C2)
			if int(q[1]) >= 4:
				au.gs._gravar_marco("cena_saida_primeiro_mentor", {}, false)
			au.gs.escola["honor"] = 37
			await au._abrir()
			var jm: Node = await _abrir_mural_6c2(q[0])
			if au._quer(q[0]):
				await au._ver(q[0])
			if q[0] == "f6c2_tela_mural_30" and au._quer("f6c2_tela_mural_30_ultima"):
				jm._ir_para(99)
				await au._esperar(0.4)
				await au._ver("f6c2_tela_mural_30_ultima")
	# --- Confirmacao de sair: com e sem Honra ---
	for q in [["f6c2_aposentar_honra", 3, false], ["f6c2_aposentar_honra_cinturao", 4, true], ["f6c2_aposentar_sem_honra", 0, false]]:
		if au._quer(q[0]):
			au._novo_jogo()
			_roster_6c2(3)
			au.gs.indice_escada = int(q[1])
			au.gs.cinturao = bool(q[2])
			await au._abrir()
			au._cena.get_node("Fluxo").abrir_aposentar()
			await au._esperar(0.4)
			await au._ver(q[0])
	# --- Tela de fim com Honra (1 e 2 digitos), sem Honra, e derrota com o botao MURAL ---
	if au._quer("f6c2_fim_honra_1"):
		_fim_6c2(1, 1)
		await au._abrir()
		await au._esperar(0.3)
		await au._ver("f6c2_fim_honra_1")
	if au._quer("f6c2_fim_honra_27"):
		# Pior caso de altura: Kid vencido, cinturao, arte e a dica extra.
		_fim_6c2(6, 27)
		await au._abrir()
		await au._esperar(1.2)
		await au._ver("f6c2_fim_honra_27")
	if au._quer("f6c2_fim_sem_honra"):
		_fim_6c2(0, 0)
		await au._abrir()
		await au._esperar(0.3)
		await au._ver("f6c2_fim_sem_honra")
	if au._quer("f6c2_fim_derrota_mural"):
		au._novo_jogo()
		_roster_6c2(4)
		if au._preparar_azar():
			await au._abrir()
			await au._esperar(0.3)
			au._exigir(au._cena.get_node("Fluxo").janela != null, "f6c2_fim_derrota_mural", "a tela de derrota abriu")
			await au._ver("f6c2_fim_derrota_mural")
	# --- Hall: nada, metade, tudo comprado (dentro da tela de fim) e fechado (da sala) ---
	for q in [["f6c2_hall_nada", 0, []], ["f6c2_hall_meio", 40, ["hall_box", "hall_fund", "hall_notes"]],
			["f6c2_hall_tudo", 7, ["hall_box", "hall_fund", "hall_notes", "hall_crew", "hall_glove", "hall_wall"]]]:
		if au._quer(q[0]):
			_fim_6c2(2, int(q[1]), q[2])
			await au._abrir()
			await au._esperar(0.3)
			var fl: Node = au._cena.get_node("Fluxo")
			fl.janela.mural_pedido.emit()
			await au._esperar(0.45)
			au._exigir(str(fl.janela.get_script().resource_path).ends_with("janela_mural.gd"), q[0], "o botao MURAL abriu o mural")
			await au._ver(q[0])
	if au._quer("f6c2_hall_comprado"):
		_fim_6c2(2, 40, ["hall_box"])
		await au._abrir()
		await au._esperar(0.3)
		var flc: Node = au._cena.get_node("Fluxo")
		flc.janela.mural_pedido.emit()
		await au._esperar(0.45)
		var antes: int = au.gs.honra()
		var b: Button = flc.janela.find_child("Comprar", true, false)
		au._exigir(b != null, "f6c2_hall_comprado", "ha um no para comprar")
		if b != null:
			b.pressed.emit()
			await au._esperar(0.45)
			au._exigir(au.gs.honra() < antes, "f6c2_hall_comprado", "a compra desconta a Honra (%d -> %d)" % [antes, au.gs.honra()])
		await au._ver("f6c2_hall_comprado")
	if au._quer("f6c2_hall_fechado"):
		au._novo_jogo()
		_roster_6c2(4)
		au.gs.escola["honor"] = 40
		au.gs.escola["hall_nodes"] = ["hall_box"]
		await au._abrir()
		await _abrir_mural_6c2("f6c2_hall_fechado")
		await au._ver("f6c2_hall_fechado")
	# --- Previa com a linha FALTA ---
	if au._quer("f6c2_previa_falta"):
		au._novo_jogo()
		au.gs.escola["hall_nodes"] = ["hall_notes"]
		au.gs.indice_escada = 1
		au.gs.atributos = {"strength": 120.0, "agility": 40.0, "endurance": 100.0}
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.3)
		au.gs.aguardar_falta()
		await au._esperar(0.4)
		var jp: Node = au._cena.get_node("Fluxo").janela
		au._exigir(jp != null and jp._falta != null and jp._falta.text != "", "f6c2_previa_falta", "a linha FALTA aparece")
		await au._ver("f6c2_previa_falta")
	if au._quer("f6c2_previa_falta_max"):
		# Revanche + arte (traco de luta) + Caderninho: o pior caso de altura da previa.
		au._novo_jogo()
		au._com_nos(["body_jab", "career_purse"], 40)
		au.gs.escola["hall_nodes"] = ["hall_notes"]
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", 5)
		au.gs.permanente["revenge_opponent"] = "opp_gym_2"
		au.gs.atributos = {"strength": 3.0e4, "agility": 5.0e4, "endurance": 9.0e4}
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.3)
		au.gs.aguardar_falta()
		await au._esperar(0.4)
		await au._ver("f6c2_previa_falta_max")
	# --- Cartao de inicio com a linha do mural ---
	if au._quer("f6c2_cartao_mural"):
		au._novo_jogo()
		_roster_6c2(4)
		await au._abrir()
		var flk: Node = au._cena.get_node("Fluxo")
		flk._mostrar_cartao(flk._com_mural({}))
		await au._esperar(0.3)
		await au._ver("f6c2_cartao_mural")
	# --- Falas dos mentores: John e discipulo sentado, ancoradas na cabeca dele ---
	if au._quer("f6c2_balao_mentor_john"):
		au._f6b2_jogo(au._look_6b2(), au.LOOK_MENTOR_6B2)
		await au._abrir()
		await au._esperar(0.4)
		var sala3: Node = au._cena.get_node("Sala")
		au._exigir(sala3.mentor_visivel() and sala3.fala_do_mentor("first"), "f6c2_balao_mentor_john", "o John esta no caixote e fala como mentor")
		await au._falar("first", "foi mais longe que eu\nna garagem. bom.", "ml_t1")
		au._checar_balao("f6c2_balao_mentor_john", "first")
		await au._ver("f6c2_balao_mentor_john")
		au._balao().fechar_agora()
	if au._quer("f6c2_balao_mentor_last"):
		au._f6b2_jogo(au._look_6b2(), au.LOOK_MENTOR_6B2)
		au.gs.escola["mentors"] = []
		au.gs._gravar_marco("cena_saida_primeiro_mentor", {}, false)
		await au._abrir()
		await au._esperar(0.4)
		var sala4: Node = au._cena.get_node("Sala")
		au._exigir(sala4.mentor_visivel() and sala4._mentor_quem == "last", "f6c2_balao_mentor_last", "o ultimo que passou o posto esta no caixote")
		await au._falar("last", "esse ai me derrubou.\nagora ele sabe.", "ml_t2")
		au._checar_balao("f6c2_balao_mentor_last", "last")
		await au._ver("f6c2_balao_mentor_last")
		au._balao().fechar_agora()
	# --- Simbolo da escola: peito (com parte de cima), perna (sem), luta ---
	for q in [["f6c2_simbolo_peito", "tee"], ["f6c2_simbolo_perna", "none"]]:
		if au._quer(q[0]):
			au._f6b2_jogo(au._look_6b2({"top": q[1], "top_color": "white"}), au.LOOK_MENTOR_6B2, true)
			au._exigir(au.gs.simbolo_no_lutador(), q[0], "o discipulo mostra o simbolo (cinturao no roster)")
			var lk: Dictionary = au.gs.visual_lutador()
			var dv: GDScript = load("res://ui/disc_visual.gd")
			var sem: Image = dv.textura("fighter_idle_disc_layered", lk, false).get_image()
			var com: Image = dv.textura("fighter_idle_disc_layered", lk, true).get_image()
			au._exigir(sem.get_data() != com.get_data(), q[0], "a textura com simbolo difere da sem simbolo (%s)" % q[1])
			await au._abrir()
			await au._esperar(0.5)
			await au._ver(q[0])
	if au._quer("f6c2_simbolo_luta"):
		await au._f6b2_luta("f6c2_simbolo_luta", au._look_6b2({"top": "tank", "top_color": "white"}), true)
