extends RefCounted
## Estados do ui_audit.gd: Fase 8a1 (liga regional): prévia com a passiva dele (cada regional, as 3 táticas, "atrapalha" e "não atrapalha"),
## HUD da data regional, arena regional com a entrada no ringue e os letreiros das 3 artes, os sinais da passiva dele (AGUENTOU!, NÃO CAIU,
## ESCAPOU!, GUARDA FECHADA, golpe na guarda, A GUARDA ABRIU), as poses de assinatura, a apresentação do James nas 4 situações (balão com a
## maior fala, tempo <= 15 s) e a fala de depois (ele venceu / perdeu por K.O. / perdeu por pontos), a vitória com o convite da liga e o
## Cinturão do Vale (janela e cinturão erguido na luta), a derrota com a nota da passiva dele, a aposentadoria com o cinturão regional e o
## cartaz da liga na academia (com zoom). Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).

const TODAS := ["boxing", "bjj", "muay_thai"]
const NOMES := [
	"f8a1_previa_bigorna_aggressive", "f8a1_previa_bigorna_counter", "f8a1_previa_bigorna_defensive",
	"f8a1_previa_estaca_aggressive", "f8a1_previa_estaca_counter", "f8a1_previa_estaca_defensive",
	"f8a1_previa_sabao_aggressive", "f8a1_previa_sabao_counter", "f8a1_previa_sabao_defensive",
	"f8a1_previa_james_aggressive", "f8a1_previa_james_counter", "f8a1_previa_james_defensive",
	"f8a1_previa_nao_atrapalha", "f8a1_previa_sem_arte",
	"f8a1_hud_liga_12", "f8a1_hud_liga_1", "f8a1_hud_liga_hoje", "f8a1_hud_liga_james", "f8a1_hud_liga_completa",
	"f8a1_entrada_fora", "f8a1_entrada_cordas", "f8a1_entrada_braco",
	"f8a1_arena_boxe_ko", "f8a1_arena_jj_finalizou", "f8a1_arena_mt_rodado",
	"f8a1_luta_aguentou", "f8a1_luta_bigorna_pose", "f8a1_luta_nao_caiu", "f8a1_luta_escapou",
	"f8a1_luta_guarda_fechada", "f8a1_luta_guarda_clink", "f8a1_luta_guarda_abriu",
	"f8a1_james_first_1", "f8a1_james_first_2", "f8a1_james_first_3", "f8a1_james_revenge", "f8a1_james_school_won", "f8a1_james_many",
	"f8a1_james_scorn", "f8a1_james_pular", "f8a1_james_depois_venceu", "f8a1_james_depois_ko", "f8a1_james_depois_pontos",
	"f8a1_fim_kid_liga", "f8a1_fim_cinturao_vale", "f8a1_luta_cinturao_erguido", "f8a1_fim_retire_regional",
	"f8a1_fim_derrota_bigorna", "f8a1_fim_derrota_estaca", "f8a1_fim_derrota_sabao", "f8a1_fim_derrota_james",
	"f8a1_cartaz_antes", "f8a1_cartaz", "f8a1_cartaz_zoom",
]
const ZONA_CABECA := Rect2(282, 222, 36, 38)  # = TelaLuta.ZONA_CABECA_JOGADOR (o verificador compila antes dos autoloads)

var au


func _init(auditor) -> void:
	au = auditor


func _alguma() -> bool:
	for n in NOMES:
		if au._quer(n):
			return true
	return false


func _quer_prefixo(p: String) -> bool:
	for n in NOMES:
		if n.begins_with(p) and au._quer(n):
			return true
	return false


func _rodar_fase8a1() -> void:
	if not _alguma():
		return
	await _previas()
	await _huds()
	await _entrada_e_arena()
	await _sinais()
	await _james()
	await _fins()
	await _cartaz()


# ---------------------------------------------------------------------------------------------
# Montagem e busca de lutas
# ---------------------------------------------------------------------------------------------

func _adv(i: int) -> Dictionary:
	return au.gs.lutas.adversarios[i]


func _atr(opp: Dictionary, f: Array) -> Dictionary:
	return {"strength": opp.strength * f[0], "agility": opp.agility * f[1], "endurance": opp.endurance * f[2]}


func _aparelhos(arte: String) -> Array:
	return ["treadmill", "jump_rope", "kick_bag"] if arte == "muay_thai" else ["treadmill", "jump_rope"]


## Academia com a arte e a passiva da arte (1 ou 2) postas no motor, na liga regional (índice 6..9). Antes de _abrir().
func _montar(arte: String, idx: int, passiva: int = 1) -> void:
	au._novo_jogo()
	au._academia(arte, _aparelhos(arte), 800.0, "kick_bag" if arte == "muay_thai" else "punching_bag", idx)
	au.gs.permanente["arts_unlocked"] = TODAS.duplicate()
	au.gs.permanente["passive_wins"] = {arte: 3}
	au.gs.permanente["passives_unlocked"] = [arte]
	au.gs.permanente["last_passive"] = {arte: passiva}
	au.gs.passiva_carreira = passiva
	au.gs._academia._atualizar_passiva()
	au.gs.risco_hud_ativo = false


func _arr_adv(idx: int) -> Array:
	var o := _adv(idx)
	var a: Array = [o.strength, o.agility, o.endurance]
	if not (o.get("passive", {}) as Dictionary).is_empty():
		a.append(o.passive)
	return a


## Procura uma luta (arte e passiva já postas no motor) contra o regional `idx` em que `pred(res)` vale: {atr, k} ou {}.
func _buscar(idx: int, tat: String, pred: Callable, fatores: Array = []) -> Dictionary:
	var opp := _adv(idx)
	var lista: Array = fatores if not fatores.is_empty() else [[1.0, 1.0, 1.0], [1.2, 1.2, 1.2], [0.9, 0.9, 0.9], [1.5, 0.8, 1.5],
		[0.8, 1.5, 0.8], [1.2, 1.5, 1.0], [1.0, 1.0, 1.5], [1.5, 1.0, 1.0], [1.5, 1.5, 1.0], [2.0, 2.0, 1.0], [0.8, 0.8, 0.8], [1.1, 1.1, 1.1],
		[0.6, 0.6, 0.6], [0.4, 0.4, 0.4], [3.0, 3.0, 3.0]]
	for f in lista:
		var atr := _atr(opp, f)
		for k in range(1, 400):
			var r := RandomNumberGenerator.new()
			r.seed = k
			var res: Dictionary = au.gs.motor.lutar([atr.strength, atr.agility, atr.endurance], _arr_adv(idx), tat, int(r.randi()), true)
			if bool(pred.call(res)):
				return {"atr": atr, "k": k}
	return {}


func _por(res: Dictionary, finish: String) -> bool:
	return bool(res.win) and str(res.finish) == finish


## Abre a tela, a prévia e começa a luta (tática no motor); devolve a TelaLuta (ainda na entrada no ringue) ou null.
func _lutar(arte: String, idx: int, tat: String, achada: Dictionary, passiva: int = 1) -> Node:
	if achada.is_empty():
		au._problema("AUDIT", "estado " + au._estado, "não achei uma luta de %s com o que o estado pede (adversário %d, tática %s)" % [arte, idx, tat])
		return null
	_montar(arte, idx, passiva)
	au.gs.atributos = achada.atr.duplicate()
	au.gs.definir_tatica(tat)
	await au._abrir()
	au.gs.rng.seed = int(achada.k)
	var fluxo: Node = au._cena.get_node("Fluxo")
	fluxo.abrir_previa()
	await au._esperar(0.3)
	fluxo.janela.lutar_pedido.emit()
	await au._esperar(0.25)
	return fluxo.tela


## Pula a entrada no ringue e a apresentação: o relógio da luta anda.
func _pular_pre(tela: Node) -> void:
	if tela._pre == "entrada":
		tela._finalizar_entrada()
	if tela._pre == "falas":
		tela._encerrar_falas()
	await au._esperar(0.1)


## Pula a luta para o instante t e CONGELA o relógio dela (os efeitos terminam, o quadro fica parado para a captura).
func _ir_para(tela: Node, t: float, espera: float = 0.3) -> void:
	tela.set_process(true)
	tela._clock = t
	await au._esperar(0.12)
	tela.set_process(false)
	await au._esperar(espera)


func _t_evento(luta: Dictionary, pred: Callable) -> float:
	for e in luta.events:
		if bool(pred.call(e)):
			return float(e.t)
	return -1.0


# ---------------------------------------------------------------------------------------------
# Prévia: o cartão da passiva dele
# ---------------------------------------------------------------------------------------------

func _abrir_previa(arte: String, idx: int, tat: String, fatores: Array, passiva: int = 1) -> Node:
	if arte == "":
		au._novo_jogo()
		au._academia("boxing", _aparelhos("boxing"), 800.0, "punching_bag", idx)
		au.gs.permanente["arts_unlocked"] = []
		au.gs.arte_id = ""
		au.gs._atualizar_traco()
	else:
		_montar(arte, idx, passiva)
	au.gs.atributos = _atr(_adv(idx), fatores)
	au.gs.definir_tatica(tat)
	await au._abrir()
	au._cena.get_node("Fluxo").abrir_previa()
	await au._esperar(0.5)
	return au._cena.get_node("Fluxo").janela


func _conferir_previa(nome: String, j: Node, atrapalha: Variant) -> void:
	au._estado = nome
	var card: Node = j._cartao_adv
	au._exigir(card != null, nome, "a prévia contra o regional deveria ter o cartão da passiva dele")
	if card == null:
		return
	var r: Rect2 = card.get_global_rect()
	au._exigir(Rect2(0, 0, 640, 360).encloses(r), nome, "o cartão dele cabe na tela: %s" % au._fmt(r))
	au._exigir(r.end.x <= 152.0 + 0.5, nome, "o cartão dele não toca a janela (termina em x %.1f)" % r.end.x)
	au._exigir(str(j._dados.get("opp_passive_name", "")) != "" and str(j._dados.get("opp_passive_line", "")) != "", nome, "a prévia traz o nome e a linha da passiva dele")
	au._exigir(card.linha_rotulo != null and card.linha_rotulo.get_line_count() >= 1 and card.hits_rotulo != null, nome, "o cartão tem a linha e o 'atrapalha'")
	if atrapalha != null:
		au._exigir(bool(j._dados.get("opp_passive_hits", false)) == bool(atrapalha), nome,
			"atrapalha = %s (a prévia diz %s)" % [str(atrapalha), str(j._dados.get("opp_passive_hits", false))])


func _previas() -> void:
	if not _quer_prefixo("f8a1_previa_"):
		return
	# Cada regional contra a combinação que ele trava, nas 3 táticas.
	var casos := [["bigorna", 6, "boxing", 1], ["estaca", 7, "bjj", 2], ["sabao", 8, "muay_thai", 2], ["james", 9, "boxing", 1]]
	for c in casos:
		for tat in ["aggressive", "counter", "defensive"]:
			var nome := "f8a1_previa_%s_%s" % [c[0], tat]
			if not au._quer(nome):
				continue
			var j: Node = await _abrir_previa(str(c[2]), int(c[1]), tat, [1.0, 1.0, 1.0], int(c[3]))
			_conferir_previa(nome, j, true)
			await au._ver(nome)
	if au._quer("f8a1_previa_nao_atrapalha"):
		# Boxe Contragolpista contra o Bigorna: a passiva dele não trava o jeito dela ("NÃO ATRAPALHA O SEU JEITO").
		var j2: Node = await _abrir_previa("boxing", 6, "counter", [1.0, 1.0, 1.0], 2)
		_conferir_previa("f8a1_previa_nao_atrapalha", j2, false)
		await au._ver("f8a1_previa_nao_atrapalha")
	if au._quer("f8a1_previa_sem_arte"):
		var j3: Node = await _abrir_previa("", 7, "aggressive", [1.0, 1.0, 1.0])
		_conferir_previa("f8a1_previa_sem_arte", j3, null)
		await au._ver("f8a1_previa_sem_arte")


# ---------------------------------------------------------------------------------------------
# HUD: a data da liga regional
# ---------------------------------------------------------------------------------------------

func _hud_liga(nome: String, dias: int, idx: int, risco: String) -> void:
	au._estado = nome
	au._novo_jogo()
	au.gs.indice_escada = idx
	au.gs.risco_hud_ativo = false
	au.gs.local_id = "gym"
	au.gs.cinturao = true
	au.gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	au.gs.arte_id = "boxing"
	au.gs._atualizar_traco()
	var spd: float = au.gs._segundos_por_dia()
	au.gs.fight_day = 30
	au.gs.segundos_campanha = float(30 - dias - 1) * spd + 1.0
	au.gs._definir_risco_hud(str(au.gs.proximo_adversario().id), risco)
	await au._abrir()
	au._exigir(au.gs.dias_para_luta() == dias, nome, "dias para a luta %d (esperava %d)" % [au.gs.dias_para_luta(), dias])
	var bloco: Node = au._cena.find_child("*BlocoProxima*", true, false)
	if bloco == null:
		for c in au._cena.find_children("*", "Control", true, false):
			if c.get_script() != null and str(c.get_script().get_global_name()) == "BlocoProxima":
				bloco = c
				break
	au._exigir(bloco != null, nome, "o bloco da próxima luta existe")
	if bloco != null and dias >= 1:
		au._exigir(bloco._premio.visible and bloco._premio.text.begins_with("LIGA REGIONAL"), nome,
			"o HUD mostra o nome da liga abaixo da placa (%s)" % str(bloco._premio.text))
		au._exigir(not bloco._premio.text.contains("DIA"), nome, "o número de dias não se repete (%s)" % str(bloco._premio.text))
	await au._esperar(0.4)
	await au._ver(nome)


func _huds() -> void:
	if au._quer("f8a1_hud_liga_12"):
		await _hud_liga("f8a1_hud_liga_12", 12, 6, "easy")
	if au._quer("f8a1_hud_liga_1"):
		await _hud_liga("f8a1_hud_liga_1", 1, 7, "even")
	if au._quer("f8a1_hud_liga_hoje"):
		await _hud_liga("f8a1_hud_liga_hoje", 0, 8, "hard")
	if au._quer("f8a1_hud_liga_james"):
		await _hud_liga("f8a1_hud_liga_james", 9, 9, "hard")
	if au._quer("f8a1_hud_liga_completa"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", au.gs.lutas.adversarios.size())
		await au._abrir()
		au._exigir(au.gs.campanha_completa() and au.gs.cinturao_regional(), "f8a1_hud_liga_completa", "campanha completa depois do James, com o cinturão do Vale")
		await au._ver("f8a1_hud_liga_completa")


# ---------------------------------------------------------------------------------------------
# Entrada no ringue e arena regional com os letreiros das 3 artes
# ---------------------------------------------------------------------------------------------

## Põe a entrada no instante t (relógio parado) e deixa o quadro para a captura.
func _ir_pre(tela: Node, t: float) -> void:
	tela._pre_t = t - 0.03
	tela.set_process(true)
	await au._esperar(0.06)
	tela.set_process(false)
	await au._esperar(0.2)


func _entrada_e_arena() -> void:
	if _quer_prefixo("f8a1_entrada_"):
		var tela: Node = await _lutar("boxing", 6, "aggressive", _buscar(6, "aggressive", func(r: Dictionary) -> bool: return bool(r.win)))
		if tela != null:
			au._estado = "f8a1_entrada_fora"
			au._exigir(tela._pre == "entrada", au._estado, "a luta na arena regional começa pela entrada no ringue (%s)" % str(tela._pre))
			au._exigir(str(tela.luta.arena) == "arena_regional", au._estado, "a luta é na arena regional (%s)" % str(tela.luta.arena))
			au._exigir(tela._ropes_side != null and tela._facho != null, au._estado, "as camadas opcionais da arena (cordas, facho) existem")
			if au._quer("f8a1_entrada_fora"):
				await _ir_pre(tela, 0.55)
				au._exigir(tela._facho.visible and tela._l[0].spr.position.x < 118.0, au._estado, "o facho segue o jogador, ainda fora das cordas (x %.0f)" % tela._l[0].spr.position.x)
				await au._ver("f8a1_entrada_fora")
			if au._quer("f8a1_entrada_cordas"):
				au._estado = "f8a1_entrada_cordas"
				await _ir_pre(tela, 1.55)
				au._exigir(tela._l[0].spr.position.x > 118.0 and tela._l[0].spr.position.x < 200.0, au._estado, "entre as cordas (x %.0f)" % tela._l[0].spr.position.x)
				await au._ver("f8a1_entrada_cordas")
			if au._quer("f8a1_entrada_braco"):
				au._estado = "f8a1_entrada_braco"
				await _ir_pre(tela, 2.15)
				au._exigir(str(tela._l[0].estado) == "victory", au._estado, "no fim da entrada ele ergue o braço (%s)" % str(tela._l[0].estado))
				await au._ver("f8a1_entrada_braco")
			# Clicar pula a entrada e a luta começa.
			tela._clique_geral()
			await au._esperar(0.2)
			au._exigir(tela._pre == "" and tela._l[0].spr.position == tela._l[0].base, "f8a1_entrada_braco", "o clique pula a entrada: ele está no lugar")
	# Letreiros das 3 artes na arena regional (K.O., FINALIZOU!, CHUTE RODADO!).
	var artes := [["f8a1_arena_boxe_ko", "boxing", 1, "aggressive", "knockout"], ["f8a1_arena_jj_finalizou", "bjj", 1, "aggressive", "submission"],
		["f8a1_arena_mt_rodado", "muay_thai", 1, "aggressive", "spin_kick"]]
	for a in artes:
		var nome: String = a[0]
		if not au._quer(nome):
			continue
		var achada := {}
		var idx_ok := 6
		_montar(str(a[1]), 6, int(a[2]))
		for idx in [6, 7, 8, 9]:
			_montar(str(a[1]), idx, int(a[2]))
			var f := str(a[4])
			achada = _buscar(idx, str(a[3]), func(r: Dictionary) -> bool: return bool(r.win) and (bool(r.ko) if f == "knockout" else str(r.finish) == f))
			if not achada.is_empty():
				idx_ok = idx
				break
		var t2: Node = await _lutar(str(a[1]), idx_ok, str(a[3]), achada, int(a[2]))
		if t2 != null:
			au._estado = nome
			await _pular_pre(t2)
			var res: Dictionary = au.gs.luta.result
			await _ir_para(t2, float(res.t_ko) + 0.1, 0.1)
			await _ir_para(t2, float(res.t_ko) + 0.9, 0.1)
			var banner: Sprite2D = t2._banner_ko
			if str(a[4]) == "submission":
				banner = t2._banner_sub_img
			elif str(a[4]) == "spin_kick":
				banner = t2._banner_spin
			au._exigir(banner != null and banner.visible, nome, "o letreiro %s aparece na arena regional" % str(a[4]))
			au._exigir(str(t2.luta.arena) == "arena_regional", nome, "a luta é na arena regional")
			await au._f7b2._letreiro_acima_dos_numeros(t2, banner, nome)
			await au._ver(nome)


# ---------------------------------------------------------------------------------------------
# Sinais da passiva dele na luta
# ---------------------------------------------------------------------------------------------

func _sinais() -> void:
	# AGUENTOU! (Bigorna x Mão rápida) e a pose de assinatura quando o embalo chega a 5.
	if au._quer("f8a1_luta_aguentou") or au._quer("f8a1_luta_bigorna_pose"):
		_montar("boxing", 6, 1)
		var a1 := _buscar(6, "aggressive", func(r: Dictionary) -> bool: return int(r.get("opp_blocks", 0)) >= 1 and bool(r.win))
		var t1: Node = await _lutar("boxing", 6, "aggressive", a1, 1)
		if t1 != null:
			await _pular_pre(t1)
			var luta: Dictionary = t1.luta
			au._estado = "f8a1_luta_aguentou"
			au._exigir(t1._opp_icone != null and t1._opp_icone.visible, au._estado, "o ícone da passiva dele fica ao lado da vida dele")
			au._exigir(str(luta.opp_passive.id) == "adv_iron_chin", au._estado, "a passiva dele é o Queixo de ferro")
			# Os dois momentos em ordem de tempo (o relógio só anda para a frente).
			var tb := _t_evento(luta, func(e: Dictionary) -> bool: return bool(e.get("opp_block", false)))
			var t5 := _t_evento(luta, func(e: Dictionary) -> bool: return int(e.get("streak", 0)) >= 5 and int(e.who) == 0)
			au._exigir(tb > 0.0, au._estado, "a luta tem um golpe que a trava segurou")
			var ordem: Array = [["aguentou", tb], ["pose", t5]]
			ordem.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) < float(b[1]))
			for par in ordem:
				if float(par[1]) <= 0.0:
					continue
				if str(par[0]) == "aguentou" and au._quer("f8a1_luta_aguentou"):
					au._estado = "f8a1_luta_aguentou"
					await _ir_para(t1, float(par[1]) + 0.2)
					var sp: Sprite2D = t1._opp_sinais.get("block")
					au._exigir(sp != null and sp.visible, au._estado, "o sinal AGUENTOU! aparece sobre a cabeça dele")
					au._exigir(str(t1._l[1].spr.nome_sprite) == "opp_reg_1_shake_head", au._estado, "ele faz a pose de assinatura (%s)" % str(t1._l[1].spr.nome_sprite))
					await au._ver("f8a1_luta_aguentou")
				elif str(par[0]) == "pose" and au._quer("f8a1_luta_bigorna_pose"):
					au._estado = "f8a1_luta_bigorna_pose"
					await _ir_para(t1, float(par[1]) + 0.25)
					au._exigir(str(t1._l[1].spr.nome_sprite) == "opp_reg_1_shake_head", au._estado, "com o embalo em 5 ele sacode a cabeça (%s)" % str(t1._l[1].spr.nome_sprite))
					await au._ver("f8a1_luta_bigorna_pose")
	# NÃO CAIU (Estaca x Por cima).
	if au._quer("f8a1_luta_nao_caiu"):
		_montar("bjj", 7, 2)
		var a2 := _buscar(7, "aggressive", func(r: Dictionary) -> bool: return int(r.get("opp_blocks", 0)) >= 1 and bool(r.win))
		var t2: Node = await _lutar("bjj", 7, "aggressive", a2, 2)
		if t2 != null:
			await _pular_pre(t2)
			au._estado = "f8a1_luta_nao_caiu"
			var tb2 := _t_evento(t2.luta, func(e: Dictionary) -> bool: return bool(e.get("opp_block", false)))
			await _ir_para(t2, tb2 + 0.2)
			var sp2: Sprite2D = t2._opp_sinais.get("block")
			au._exigir(sp2 != null and sp2.visible, au._estado, "o sinal NÃO CAIU aparece")
			au._exigir(str(t2._l[1].spr.nome_sprite) == "opp_reg_2_plant_feet", au._estado, "ele planta os pés (%s)" % str(t2._l[1].spr.nome_sprite))
			await au._ver("f8a1_luta_nao_caiu")
	# ESCAPOU! (Sabão x Clinch).
	if au._quer("f8a1_luta_escapou"):
		_montar("muay_thai", 8, 2)
		var a3 := _buscar(8, "defensive", func(r: Dictionary) -> bool: return int(r.get("opp_blocks", 0)) >= 1 and bool(r.win))
		var t3: Node = await _lutar("muay_thai", 8, "defensive", a3, 2)
		if t3 != null:
			await _pular_pre(t3)
			au._estado = "f8a1_luta_escapou"
			var tb3 := _t_evento(t3.luta, func(e: Dictionary) -> bool: return bool(e.get("opp_block", false)))
			await _ir_para(t3, tb3 + 0.2)
			var sp3: Sprite2D = t3._opp_sinais.get("block")
			au._exigir(sp3 != null and sp3.visible, au._estado, "o sinal ESCAPOU! aparece")
			au._exigir(str(t3._l[1].spr.nome_sprite) == "opp_reg_3_slip_clinch", au._estado, "ele desliza do clinch (%s)" % str(t3._l[1].spr.nome_sprite))
			await au._ver("f8a1_luta_escapou")
	# James: guarda fechada, golpe na guarda e A GUARDA ABRIU.
	if _quer_prefixo("f8a1_luta_guarda_"):
		_montar("boxing", 9, 1)
		var a4 := _buscar(9, "aggressive", func(r: Dictionary) -> bool: return bool(r.win))
		var t4: Node = await _lutar("boxing", 9, "aggressive", a4, 1)
		if t4 != null:
			await _pular_pre(t4)
			var luta4: Dictionary = t4.luta
			au._estado = "f8a1_luta_guarda_fechada"
			au._exigir(str(luta4.opp_passive.id) == "adv_blindado" and float(luta4.opp_passive.guard_until) > 5.0, au._estado, "a passiva dele é o Blindado (guarda até 5,33 s)")
			if au._quer("f8a1_luta_guarda_fechada"):
				await _ir_para(t4, 0.45)
				au._exigir(t4._guarda_fechada and str(t4._l[1].spr.nome_sprite) == "opp_james_guard", au._estado, "no 1º round ele fica na guarda fechada (%s)" % str(t4._l[1].spr.nome_sprite))
				var sc: Sprite2D = t4._opp_sinais.get("closed")
				au._exigir(sc != null and sc.visible, au._estado, "o sinal GUARDA FECHADA aparece")
				await au._ver("f8a1_luta_guarda_fechada")
			if au._quer("f8a1_luta_guarda_clink"):
				au._estado = "f8a1_luta_guarda_clink"
				var tg := _t_evento(luta4, func(e: Dictionary) -> bool: return bool(e.get("guard", false)))
				au._exigir(tg > 0.0, au._estado, "a luta tem golpe na guarda fechada")
				t4.set_process(true)
				t4._clock = tg + 0.02
				await au.process_frame
				await au.process_frame
				t4.set_process(false)
				var clink := false
				for a in t4._fx["fx_guard_clink"]:
					if bool(a.visible):
						clink = true
						a.set_process(false)  # congela a faísca num quadro para a captura
				au._exigir(clink, au._estado, "a faísca de aço (fx_guard_clink) aparece no golpe")
				au._exigir(str(t4._l[1].spr.nome_sprite) == "opp_james_block", au._estado, "ele reage com a guarda (%s)" % str(t4._l[1].spr.nome_sprite))
				await au._ver("f8a1_luta_guarda_clink")
			if au._quer("f8a1_luta_guarda_abriu"):
				au._estado = "f8a1_luta_guarda_abriu"
				await _ir_para(t4, float(luta4.opp_passive.guard_until) + 0.3)
				var so: Sprite2D = t4._opp_sinais.get("open")
				au._exigir(not t4._guarda_fechada, au._estado, "a guarda abriu")
				au._exigir(so != null and so.visible, au._estado, "o sinal A GUARDA ABRIU aparece")
				au._exigir(str(t4._l[1].spr.nome_sprite) != "opp_james_guard", au._estado, "ele sai da guarda fechada (%s)" % str(t4._l[1].spr.nome_sprite))
				await au._ver("f8a1_luta_guarda_abriu")


# ---------------------------------------------------------------------------------------------
# James: apresentação (4 situações) e fala de depois
# ---------------------------------------------------------------------------------------------

func _conferir_balao(nome: String, tela: Node) -> void:
	var b: Node = tela._balao
	au._exigir(b.ativo(), nome, "o balão do James está na tela")
	if not b.ativo():
		return
	var r: Rect2 = b.retangulo_total()
	au._exigir(Rect2(0, 0, 640, 360).encloses(r), nome, "o balão cabe na tela: %s" % au._fmt(r))
	au._exigir(r.position.y >= 46.0, nome, "o balão não cobre o HUD (topo em y %.0f)" % r.position.y)
	au._exigir(not r.intersects(ZONA_CABECA), nome, "o balão não cobre a cabeça do jogador: %s" % au._fmt(r))
	au._exigir(str(b.speaker) == "rival", nome, "quem fala é o rival (%s)" % str(b.speaker))
	# Balão e letreiro/sinal nunca se sobrepõem (caixa contra caixa).
	var caixas: Dictionary = {}
	for k in tela._opp_sinais:
		caixas["sinal " + str(k)] = tela._opp_sinais[k]
	caixas["K.O."] = tela._banner_ko
	caixas["spin"] = tela._banner_spin
	caixas["finalizou"] = tela._banner_sub_img
	for k in tela._banners_fim:
		caixas["fim " + str(k)] = tela._banners_fim[k]
	for k in caixas:
		var sp: Sprite2D = caixas[k]
		if sp != null and sp.visible and sp.modulate.a > 0.05:
			var tam: Vector2 = sp.texture.get_size() * sp.global_scale
			var rs := Rect2(sp.global_position - tam / 2.0, tam)
			au._exigir(not rs.intersects(r), nome, "o balão se sobrepõe ao letreiro/sinal %s: %s x %s" % [str(k), au._fmt(rs), au._fmt(r)])
	for lb in [tela._banner, tela._banner_sub]:
		if lb.visible and lb.text != "" and lb.modulate.a > 0.05:
			au._exigir(not Rect2(lb.global_position, lb.get_combined_minimum_size() * lb.scale).intersects(r), nome, "o balão se sobrepõe ao texto de letreiro \"%s\"" % lb.text)


## Abre a luta contra o James com o placar `rival` e devolve a TelaLuta (a entrada no ringue já rodando).
func _abrir_james(rival: Dictionary, arte: String = "boxing") -> Node:
	var a := _buscar(9, "aggressive", func(r: Dictionary) -> bool: return bool(r.win)) if arte == "boxing" else {}
	if a.is_empty():
		a = {"atr": _atr(_adv(9), [1.2, 1.2, 1.2]), "k": 5}
	_montar(arte, 9, 1)
	au.gs.escola["rival"] = rival.duplicate()
	au.gs.atributos = a.atr.duplicate()
	au.gs.definir_tatica("aggressive")
	await au._abrir()
	au.gs.rng.seed = int(a.k)
	var fluxo: Node = au._cena.get_node("Fluxo")
	fluxo.abrir_previa()
	await au._esperar(0.3)
	fluxo.janela.lutar_pedido.emit()
	await au._esperar(0.2)
	return fluxo.tela


## Deixa a apresentação rodar sozinha (sem clicar) e captura a fala completa nos índices pedidos e o gesto de desprezo. Mede o tempo do
## LUTAR ao sino.
func _percorrer(prefixo: String, tela: Node, capturar: Dictionary, esperadas: int, nome_scorn: String = "") -> void:
	var ultimo := ""
	var vistas := 0
	var guarda := 0.0
	var scorn := false
	while (tela._pre == "entrada" or tela._pre == "falas") and guarda < 40.0:
		await au._esperar(0.05)
		guarda += 0.05
		if tela._pre != "falas":
			continue
		if not scorn and str(tela._l[1].spr.nome_sprite) == "opp_james_scorn" and tela._l[1].spr.frame >= 3:
			scorn = true
			if nome_scorn != "" and au._quer(nome_scorn):
				au._estado = nome_scorn
				_conferir_balao(au._estado, tela)
				await au._ver(nome_scorn)
		if tela._balao.ativo() and tela._balao.texto_completo() and tela._balao.id != ultimo:
			ultimo = tela._balao.id
			vistas += 1
			if capturar.has(vistas):
				au._estado = str(capturar[vistas])
				_conferir_balao(au._estado, tela)
				await au._ver(str(capturar[vistas]))
	var total: float = tela._t + 0.8  # o sino toca 0,8 s depois do fim da apresentação (a entrada normal de 1,5 s)
	au._estado = prefixo
	au._exigir(vistas == esperadas, prefixo, "tocaram %d falas (esperava %d)" % [vistas, esperadas])
	au._exigir(scorn, prefixo, "o gesto de desprezo saiu (1 vez por apresentação)")
	au._exigir(total <= 15.0, prefixo, "do LUTAR ao sino: %.1f s (limite 15 s)" % total)
	print("TEMPO ", prefixo, " LUTAR->sino %.1f s, %d falas" % [total, vistas])
	au._exigir(tela._guarda_fechada and str(tela._l[1].spr.nome_sprite) == "opp_james_guard", prefixo, "ele termina de volta na guarda fechada (%s)" % str(tela._l[1].spr.nome_sprite))


func _james() -> void:
	if not (_quer_prefixo("f8a1_james_") or au._quer("f8a1_james_pular")):
		return
	var situacoes := [
		["f8a1_james_first_1", {"met": 0, "school_wins": 0, "james_wins": 0}, {1: "f8a1_james_first_1", 2: "f8a1_james_first_2", 3: "f8a1_james_first_3"}, 3],
		["f8a1_james_revenge", {"met": 1, "school_wins": 0, "james_wins": 1}, {2: "f8a1_james_revenge"}, 2],
		["f8a1_james_school_won", {"met": 2, "school_wins": 1, "james_wins": 1}, {1: "f8a1_james_school_won"}, 2],
		["f8a1_james_many", {"met": 3, "school_wins": 1, "james_wins": 2}, {1: "f8a1_james_many"}, 2],
	]
	for s in situacoes:
		var pedidos := false
		for v in (s[2] as Dictionary).values():
			pedidos = pedidos or au._quer(str(v))
		if au._quer("f8a1_james_scorn") and str(s[0]) == "f8a1_james_first_1":
			pedidos = true
		if not pedidos:
			continue
		var tela: Node = await _abrir_james(s[1])
		if tela == null:
			continue
		au._estado = str(s[0])
		au._exigir(not (tela.luta.get("intro_falas", []) as Array).is_empty(), au._estado, "a luta traz a apresentação (intro_falas)")
		var caps: Dictionary = {}
		for k in s[2]:
			if au._quer(str(s[2][k])):
				caps[k] = s[2][k]
		await _percorrer(str(s[0]), tela, caps, int(s[3]), "f8a1_james_scorn" if str(s[0]) == "f8a1_james_first_1" else "")
	# Apresentação 1º encontro: passando as falas pelo clique e pelo PULAR (a luta segue).
	if au._quer("f8a1_james_first_1") or au._quer("f8a1_james_first_2") or au._quer("f8a1_james_first_3"):
		var t2: Node = await _abrir_james({"met": 0, "school_wins": 0, "james_wins": 0})
		var inicio := 0.0
		while t2._pre == "entrada" and inicio < 6.0:
			t2._clique_geral()  # o clique pula a entrada
			await au._esperar(0.1)
			inicio += 0.1
		au._estado = "f8a1_james_first_1"
		au._exigir(t2._pre == "falas", au._estado, "depois da entrada segue a apresentação (%s)" % str(t2._pre))
		await au._esperar(0.2)
		var antes: String = t2._balao.id
		au._exigir(t2._balao.ativo() and not t2._balao.texto_completo(), au._estado, "a fala está sendo escrita")
		t2._clique_geral()  # 1º toque completa a fala
		await au._esperar(0.3)
		au._exigir(t2._balao.texto_completo(), au._estado, "o 1º toque completa a fala")
		t2._clique_geral()  # 2º toque passa para a próxima
		await au._esperar(1.0)
		au._exigir(t2._balao.ativo() and t2._balao.id != antes, au._estado, "o 2º toque passa para a próxima fala (%s)" % str(t2._balao.id))
		t2._botao_pular.pressed.emit()  # PULAR encerra a apresentação
		await au._esperar(0.3)
		au._exigir(t2._pre == "" and not t2._balao.ativo(), au._estado, "PULAR encerra a apresentação")
		au._exigir(t2._clock < 0.0 and t2._guarda_fechada, au._estado, "a luta segue: ele na guarda fechada, relógio na entrada normal")
	if au._quer("f8a1_james_pular"):
		var t3: Node = await _abrir_james({"met": 0, "school_wins": 0, "james_wins": 0})
		t3._clique_geral()
		await au._esperar(0.8)
		au._estado = "f8a1_james_pular"
		au._exigir(t3._pre == "falas" and t3._botao_pular.visible and t3._chip_pular.visible, au._estado, "durante a apresentação aparecem o PULAR com anel e a dica ESC")
		await au._ver("f8a1_james_pular")
		t3._esc_segurando = true  # ESC segurado 0,5 s
		await au._esperar(0.7)
		au._exigir(t3._pre == "", au._estado, "ESC segurado 0,5 s encerra a apresentação")
	# Fala de depois.
	if _quer_prefixo("f8a1_james_depois_"):
		await _depois("f8a1_james_depois_venceu", false, false)
		await _depois("f8a1_james_depois_ko", true, true)
		await _depois("f8a1_james_depois_pontos", true, false)


## Fala de depois do James. `ele_perdeu`: o jogador vence; `ko`: por K.O. (ou por pontos).
func _depois(nome: String, ele_perdeu: bool, ko: bool) -> void:
	if not au._quer(nome):
		return
	_montar("boxing", 9, 1)
	var f: Callable = func(r: Dictionary) -> bool:
		if ele_perdeu:
			return bool(r.win) and bool(r.ko) == ko
		return not bool(r.win)
	var achada := _buscar(9, "aggressive", f, [[1.2, 1.2, 1.2], [1.0, 1.0, 1.0], [0.6, 0.6, 0.6], [0.4, 0.4, 0.4], [1.5, 1.5, 1.5], [3.0, 3.0, 3.0], [0.9, 0.9, 0.9]])
	var tela: Node = await _lutar("boxing", 9, "aggressive", achada, 1)
	if tela == null:
		return
	au._estado = nome
	await _pular_pre(tela)
	var luta: Dictionary = tela.luta
	au._exigir(str(luta.get("outro_line", "")) != "" and not (luta.get("outro_fala", {}) as Dictionary).is_empty(), nome, "a luta traz a fala de depois (outro_fala)")
	tela.set_process(true)
	tela._clock = float(tela._fim_total) + 0.05
	await au._esperar(0.4)
	var guarda := 0.0
	while not (tela._balao.ativo() and tela._balao.texto_completo()) and guarda < 8.0:
		await au._esperar(0.1)
		guarda += 0.1
	au._exigir(tela._outro == 1, nome, "a fala de depois toca antes da janela de fim (estado %d)" % int(tela._outro))
	au._exigir(au._cena.get_node("Fluxo").janela == null, nome, "nenhuma janela por cima enquanto ele fala")
	_conferir_balao(nome, tela)
	print("JAMES_POSE ", nome, " ", tela._l[1].spr.nome_sprite, " frame ", tela._l[1].spr.frame, " estado ", tela._l[1].estado)
	if nome == "f8a1_james_depois_pontos":
		au._exigir(str(tela._l[1].spr.nome_sprite) == "opp_james_tired", nome, "perdeu por pontos: ele fica cansado (tired) (%s)" % str(tela._l[1].spr.nome_sprite))
	var r2: Rect2 = tela._balao.retangulo_total()
	au._exigir(not r2.intersects(Rect2(262, 226, 70, 96)), nome, "o balão não cobre o jogador: %s" % au._fmt(r2))
	await au._ver(nome)


# ---------------------------------------------------------------------------------------------
# Fim: convite da liga, Cinturão do Vale, cinturão erguido, aposentadoria, derrotas
# ---------------------------------------------------------------------------------------------

## Vitória real contra `idx` com a arte e a passiva dadas; abre a janela de vitória. Devolve a janela ou null.
func _vitoria(nome: String, arte: String, idx: int, passiva: int, tat: String) -> Node:
	_montar(arte, idx, passiva)
	var achada := _buscar(idx, tat, func(r: Dictionary) -> bool: return bool(r.win))
	if achada.is_empty():
		au._problema("AUDIT", "estado " + nome, "não achei uma vitória contra o adversário %d" % idx)
		return null
	au.gs.atributos = achada.atr.duplicate()
	au.gs.definir_tatica(tat)
	au.gs.rng.seed = int(achada.k)
	au.gs.lutar()
	var resumo: Dictionary = au.gs.concluir_luta()
	await au._abrir()
	au._estado = nome
	au._exigir(bool(resumo.get("win", false)), nome, "a luta montada é uma vitória")
	var fluxo: Node = au._cena.get_node("Fluxo")
	fluxo._fechar_tudo()
	fluxo._abrir_vitoria(resumo, false)
	await au._esperar(1.0)
	var jv: Node = fluxo.janela
	au._exigir(jv != null and jv.get_script() != null and str(jv.get_script().resource_path).ends_with("janela_vitoria.gd"), nome, "a janela de vitória abre")
	return jv


func _fins() -> void:
	if au._quer("f8a1_fim_kid_liga"):
		var jk: Node = await _vitoria("f8a1_fim_kid_liga", "boxing", 5, 1, "aggressive")
		if jk != null:
			au._exigir(au.gs.marco("regional_league_opened"), au._estado, "vencer o Kid abre a liga (marco)")
			await au._ver("f8a1_fim_kid_liga")
	if au._quer("f8a1_fim_cinturao_vale"):
		var jc: Node = await _vitoria("f8a1_fim_cinturao_vale", "boxing", 9, 1, "aggressive")
		if jc != null:
			au._exigir(au.gs.cinturao_regional(), au._estado, "vencer o James dá o Cinturão do Vale")
			await au._ver("f8a1_fim_cinturao_vale")
	if au._quer("f8a1_luta_cinturao_erguido"):
		_montar("boxing", 9, 1)
		var ac := _buscar(9, "aggressive", func(r: Dictionary) -> bool: return bool(r.win) and not bool(r.ko))
		if ac.is_empty():
			ac = _buscar(9, "aggressive", func(r: Dictionary) -> bool: return bool(r.win))
		var te: Node = await _lutar("boxing", 9, "aggressive", ac, 1)
		if te != null:
			au._estado = "f8a1_luta_cinturao_erguido"
			await _pular_pre(te)
			var res: Dictionary = au.gs.luta.result
						# Luta REAL (relógio andando): espera o cinturão subir e deixa a animação rodar um pouco.
			var espera := 0.0
			while not (te._cinturao != null and te._cinturao.visible) and espera < 60.0 and te._outro == 0:
				await au._esperar(0.1)
				espera += 0.1
			await au._esperar(0.45)
			print("BELT ", te._cinturao, " ativo ", te._cinturao_ativo, " estado ", te._l[0].estado, " win ", te.luta.result.get("win"), " clock ", te._clock, " fim ", te._fim_total)
			au._exigir(te._cinturao != null and te._cinturao.visible, au._estado, "o Cinturão do Vale aparece erguido nas luvas")
			if te._cinturao != null and te._cinturao.visible:
				# Segurado: o meio das pegadas do cinturão (pivô) cai no meio das luvas do quadro de vitória.
				var fr: int = te._l[0].spr.frame
				var mp: Dictionary = {}
				var folha: Dictionary = te._info_folha_mao()
				var hm: Array = folha.get("hands", [])
				if hm.size() > 0:
					mp = hm[clampi(fr, 0, hm.size() - 1)]
				var base: Vector2 = te._l[0].base
				var luva_a: Vector2 = base + Vector2(float(mp.get("hand_front", [9, -83])[0]), float(mp.get("hand_front", [9, -83])[1]))
				var luva_b: Vector2 = base + Vector2(float(mp.get("hand_back", [-1, -82])[0]), float(mp.get("hand_back", [-1, -82])[1]))
				var meio := (luva_a + luva_b) / 2.0
				au._exigir(te._cinturao.global_position.distance_to(meio) <= 4.0, au._estado, "o cinturão não está nas luvas: pivô %s, meio das luvas %s" % [str(te._cinturao.global_position), str(meio)])
				au._exigir(te._cinturao.global_scale == Vector2.ONE, au._estado, "o cinturão está em tamanho de jogo (1x)")
				if te._balao.ativo():
					_conferir_balao(au._estado, te)
			au._exigir(str(te._l[0].estado) == "victory", au._estado, "o jogador está na pose de vitória (%s)" % str(te._l[0].estado))
			await au._ver("f8a1_luta_cinturao_erguido")
	if au._quer("f8a1_fim_retire_regional"):
		au._novo_jogo()
		au.gs.indice_escada = au.gs.lutas.adversarios.size()
		au.gs.cinturao = true
		au.gs.fama = 900
		au.gs.aposentar()
		await au._abrir()
		await au._esperar(0.9)
		au._estado = "f8a1_fim_retire_regional"
		au._exigir(au.gs.cinturao_regional(), au._estado, "a escada passou do James")
		await au._ver("f8a1_fim_retire_regional")
	for par in [["f8a1_fim_derrota_bigorna", 6, "boxing", 1, "aggressive"], ["f8a1_fim_derrota_estaca", 7, "bjj", 2, "aggressive"],
			["f8a1_fim_derrota_sabao", 8, "muay_thai", 2, "defensive"], ["f8a1_fim_derrota_james", 9, "boxing", 1, "aggressive"]]:
		var nome: String = par[0]
		if not au._quer(nome):
			continue
		_montar(str(par[2]), int(par[1]), int(par[3]))
		var idx := int(par[1])
		var f: Callable = func(r: Dictionary) -> bool:
			return (not bool(r.win)) and (idx == 9 or int(r.get("opp_blocks", 0)) >= 1)
		var achada := _buscar(idx, str(par[4]), f, [[1.0, 1.0, 1.0], [0.9, 0.9, 0.9], [0.8, 0.8, 0.8], [1.1, 1.1, 1.1], [0.6, 0.6, 0.6], [1.2, 1.2, 1.2], [0.5, 0.5, 0.5]])
		if achada.is_empty():
			au._problema("AUDIT", "estado " + nome, "não achei uma derrota com a passiva dele pesando (adversário %d)" % idx)
			continue
		au.gs.atributos = achada.atr.duplicate()
		au.gs.definir_tatica(str(par[4]))
		au.gs.rng.seed = int(achada.k)
		au.gs.lutar()
		au.gs.aguardar_motivo()
		au.gs.concluir_luta()
		await au._abrir()
		await au._esperar(0.9)
		au._estado = nome
		var tx: Dictionary = au.gs.textos_fim()
		au._exigir(str(tx.get("opp_note", "")) != "", nome, "a derrota traz a linha da passiva dele (opp_note)")
		await au._ver(nome)


# ---------------------------------------------------------------------------------------------
# Cartaz da liga na academia (e o zoom)
# ---------------------------------------------------------------------------------------------

func _cartaz() -> void:
	if not _quer_prefixo("f8a1_cartaz"):
		return
	if au._quer("f8a1_cartaz_antes"):
		au._novo_jogo()
		au._academia("boxing", _aparelhos("boxing"), 800.0, "punching_bag", 5)
		await au._abrir()
		var sala0: Node = au._cena.get_node("Sala")
		au._exigir(not sala0._cartaz.visible, "f8a1_cartaz_antes", "sem o marco o cartaz não aparece")
		await au._ver("f8a1_cartaz_antes")
	if au._quer("f8a1_cartaz") or au._quer("f8a1_cartaz_zoom"):
		au._novo_jogo()
		au._academia("boxing", _aparelhos("boxing"), 800.0, "punching_bag", 6)
		au.gs._escola._gravar_marco("regional_league_opened", {}, false)
		await au._abrir()
		var sala: Node = au._cena.get_node("Sala")
		au._estado = "f8a1_cartaz"
		au._exigir(sala._cartaz.visible and sala._cartaz_rect.size != Vector2.ZERO, au._estado, "depois do marco o cartaz aparece na parede da academia")
		if au._quer("f8a1_cartaz"):
			await au._ver("f8a1_cartaz")
		if au._quer("f8a1_cartaz_zoom"):
			au._estado = "f8a1_cartaz_zoom"
			var c: Vector2 = sala._cartaz_rect.get_center()
			sala._hover_em(c)
			await au._esperar(0.5)
			au._exigir(sala._cartaz_zoom != null and sala._cartaz_zoom.visible, au._estado, "com o mouse em cima aparece o cartaz grande")
			if sala._cartaz_zoom != null:
				var rz: Rect2 = sala._cartaz_zoom.get_global_rect()
				au._exigir(Rect2(0, 0, 640, 360).encloses(rz), au._estado, "o zoom cabe na tela: %s" % au._fmt(rz))
				au._exigir(not rz.intersects(Rect2(310, 180, 52, 94)), au._estado, "o zoom não cobre a zona do alvo: %s" % au._fmt(rz))
			await au._ver("f8a1_cartaz_zoom")
