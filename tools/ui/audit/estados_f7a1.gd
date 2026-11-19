extends RefCounted
## Estados do ui_audit.gd: Fase 7a1 (cada arte luta do seu jeito): prévia com a passiva de cada arte e tática (cartão ao lado da
## janela), luta de Boxe com embalo e cansado, luta de Jiu-jitsu com pegada, no chão e com o FINALIZOU!, a arena da liga, a tela
## de fim com a nota da passiva e "fim depois de derrota com a arena visível" (pendência 5.4/B2).
## Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).

const TATICAS := ["aggressive", "defensive", "counter"]
const NOMES := [
	"f7a1_previa_boxing_aggressive", "f7a1_previa_boxing_defensive", "f7a1_previa_boxing_counter",
	"f7a1_previa_bjj_aggressive", "f7a1_previa_bjj_defensive", "f7a1_previa_bjj_counter", "f7a1_previa_bjj_kid",
	"f7a1_luta_boxe_embalo", "f7a1_luta_boxe_cansado", "f7a1_luta_boxe_defensivo", "f7a1_luta_boxe_ko",
	"f7a1_luta_jj_pegada", "f7a1_luta_jj_chao", "f7a1_luta_jj_finalizou", "f7a1_luta_jj_finalizou_letreiro",
	"f7a1_arena_borracharia", "f7a1_arena_liga", "f7a1_fim_derrota_arena", "f7a1_fim_nota_boxe", "f7a1_fim_nota_jj",
]

var au


func _init(auditor) -> void:
	au = auditor


func _alguma() -> bool:
	for n in NOMES:
		if au._quer(n):
			return true
	return false


func _adv(i: int) -> Dictionary:
	return au.gs.lutas.adversarios[i]


func _atr(opp: Dictionary, f: Array) -> Dictionary:
	return {"strength": opp.strength * f[0], "agility": opp.agility * f[1], "endurance": opp.endurance * f[2]}


## Procura uma luta (arte e tática já postas no motor) contra o adversário `idx` em que `pred(res)` vale.
## Devolve {atr, k} ou {} (a semente k reproduz a luta: gs.rng.seed = k).
func _buscar(idx: int, tat: String, pred: Callable, fatores: Array = []) -> Dictionary:
	var opp := _adv(idx)
	var lista: Array = fatores if not fatores.is_empty() else [[1.0, 1.0, 1.0], [1.2, 1.2, 1.2], [0.9, 0.9, 0.9], [1.5, 0.8, 1.5],
		[0.8, 1.5, 0.8], [1.2, 1.5, 1.0], [1.0, 1.0, 1.5], [1.5, 1.0, 1.0]]
	for f in lista:
		var atr := _atr(opp, f)
		for k in range(1, 400):
			var r := RandomNumberGenerator.new()
			r.seed = k
			var res: Dictionary = au.gs.motor.lutar([atr.strength, atr.agility, atr.endurance],
				[opp.strength, opp.agility, opp.endurance], tat, int(r.randi()), true)
			if bool(pred.call(res)):
				return {"atr": atr, "k": k}
	return {}


func _ganhou_por(res: Dictionary, finish: String) -> bool:
	return bool(res.win) and str(res.finish) == finish


## Coloca a carreira na academia com a arte, abre a tela e começa a luta com a tática; devolve a TelaLuta ou null.
func _lutar_com(arte: String, idx: int, tat: String, achada: Dictionary) -> Node:
	if achada.is_empty():
		au._problema("AUDIT", "estado " + au._estado, "não achei uma luta com a passiva pedida (arte %s, tática %s)" % [arte, tat])
		return null
	au._novo_jogo()
	au._academia(arte, ["treadmill", "jump_rope"], 800.0, "punching_bag", 4 + (idx - 4))
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


func _ir_para(tela: Node, t: float, espera: float = 0.7) -> void:
	tela._clock = t
	await au._esperar(espera)


func _rodar_fase7a1() -> void:
	if not _alguma():
		return
	# --- Prévia: a passiva de cada arte e de cada tática (o cartão ao lado da janela muda com a tática) ---
	for arte in ["boxing", "bjj"]:
		var primeiro := true
		var linhas := {}
		for t in TATICAS:
			var nome := "f7a1_previa_%s_%s" % [arte, t]
			if not au._quer(nome):
				continue
			if primeiro:
				au._novo_jogo()
				au._academia(arte, ["treadmill", "jump_rope"], 800.0)
				var opp := _adv(4)
				au.gs.atributos = _atr(opp, [0.9, 0.9, 0.9])
				await au._abrir()
				au._cena.get_node("Fluxo").abrir_previa()
				await au._esperar(0.5)
				primeiro = false
			var j: Node = au._cena.get_node("Fluxo").janela
			j._rotulo_tatica[t].botao.pressed.emit()
			await au._esperar(0.5)
			var cartao: Node = j._cartao
			au._exigir(cartao != null, nome, "a prévia com arte deveria ter o cartão da passiva")
			if cartao != null:
				var bloco: Dictionary = j._dados.passive_tactics[t]
				au._exigir(str(bloco.get("line", "")) != "" and str(bloco.get("share", "")) != "", nome, "o bloco da tática tem linha e N EM 10")
				linhas[t] = str(bloco.line)
				au._exigir(cartao.get_global_rect().end.x <= 640.0 and cartao.get_global_rect().end.y <= 360.0, nome, "o cartão cabe na tela")
			await au._ver(nome)
		if linhas.size() > 1 and arte == "boxing":
			au._exigir(linhas.values().size() == 1 or linhas.get("aggressive", "x") != linhas.get("defensive", "x"), "f7a1_previa_boxing",
				"a linha do Boxe muda com a tática (Agressivo x Defensivo)")
	if au._quer("f7a1_previa_bjj_kid"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0, "punching_bag", 5)
		au.gs.atributos = _atr(_adv(5), [0.9, 0.9, 0.9])
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.5)
		await au._ver("f7a1_previa_bjj_kid")

	# --- Boxe: embalo, cansado, defensivo (não cansa), K.O. pela passiva ---
	if au._quer("f7a1_luta_boxe_embalo") or au._quer("f7a1_luta_boxe_ko"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0)
		var a1 := _buscar(4, "aggressive", func(r: Dictionary) -> bool: return _ganhou_por(r, "knockout") and int(r.streak_peak) >= 4)
		var tela1 := await _lutar_com("boxing", 4, "aggressive", a1)
		if tela1 != null:
			var res1: Dictionary = au.gs.luta.result
			au._estado = "f7a1_luta_boxe_embalo"
			au._exigir(str(tela1.luta.arena) == "arena_league", "f7a1_luta_boxe_embalo", "Tonhão luta na arena da liga")
			await _ir_para(tela1, float(res1.t_ko) - 0.05)
			au._exigir(tela1._pips.size() == 5 and tela1._embalo_atual >= 2, "f7a1_luta_boxe_embalo",
				"as bolinhas de embalo acendem (embalo %d)" % tela1._embalo_atual)
			await au._ver("f7a1_luta_boxe_embalo")
			if au._quer("f7a1_luta_boxe_ko"):
				await _ir_para(tela1, float(res1.t_end) + 1.0)
				await au._ver("f7a1_luta_boxe_ko")
	if au._quer("f7a1_luta_boxe_cansado"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0)
		var a2 := _buscar(4, "aggressive", func(r: Dictionary) -> bool: return float(r.t_end) >= 14.0 and not bool(r.ko))
		var tela2 := await _lutar_com("boxing", 4, "aggressive", a2)
		if tela2 != null:
			au._estado = "f7a1_luta_boxe_cansado"
			await _ir_para(tela2, 12.5)
			au._exigir(tela2._cansado and tela2._rot_cansado != null and tela2._rot_cansado.visible, "f7a1_luta_boxe_cansado", "CANSADO aparece no 3º round")
			await au._ver("f7a1_luta_boxe_cansado")
	if au._quer("f7a1_luta_boxe_defensivo"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0)
		var a3 := _buscar(4, "defensive", func(r: Dictionary) -> bool: return float(r.t_end) >= 14.0)
		var tela3 := await _lutar_com("boxing", 4, "defensive", a3)
		if tela3 != null:
			au._estado = "f7a1_luta_boxe_defensivo"
			await _ir_para(tela3, 12.5)
			au._exigir(not tela3._cansado and not tela3._rot_cansado.visible, "f7a1_luta_boxe_defensivo", "o Defensivo não cansa")
			await au._ver("f7a1_luta_boxe_defensivo")

	# --- Jiu-jitsu: pegada, chão, finalização ---
	if au._quer("f7a1_luta_jj_pegada") or au._quer("f7a1_luta_jj_chao"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0)
		var a4 := _buscar(4, "defensive", func(r: Dictionary) -> bool:
			if float(r.t_end) < 10.0:
				return false
			for e in r.events:
				if int(e.who) == 0 and str(e.type) != "dodge" and float(e.grip) >= 0.5 and float(e.t) < 7.0:
					return true
			return false)
		var tela4 := await _lutar_com("bjj", 4, "defensive", a4)
		if tela4 != null:
			var cheia := float(tela4.luta.grip_full_at)
			# O especial dos cliques no Jiu-jitsu nunca usa animação de boxe: clinch_push em pé, ground_pressure no chão.
			au._exigir(tela4._golpe_especial({"phase": "standing"})[0] == "clinch_push" and tela4._golpe_especial({"phase": "standing"})[1] == "hit_clinch",
				"f7a1_luta_jj_chao", "o especial em pé do JJ é clinch_push / hit_clinch")
			au._exigir(tela4._golpe_especial({"phase": "ground"})[0] == "ground_pressure", "f7a1_luta_jj_chao", "o especial no chão do JJ é ground_pressure")
			au._estado = "f7a1_luta_jj_chao"
			au._exigir(str(tela4.luta.arena) == "arena_league", "f7a1_luta_jj_chao", "Tonhão luta na arena da liga")
			await _ir_para(tela4, cheia - 0.8)
			au._exigir(tela4._grip_fill != null and tela4._grip_fill.visible, "f7a1_luta_jj_chao", "a barra de pegada enche")
			au._exigir(tela4._fase_visual == "ground", "f7a1_luta_jj_chao", "depois da queda a luta está no chão")
			await au._ver("f7a1_luta_jj_chao")
			await _ir_para(tela4, cheia + 0.25)
			au._exigir(tela4._grip_cheia, "f7a1_luta_jj_pegada", "PEGADA! quando a barra enche")
			await au._ver("f7a1_luta_jj_pegada")
	if au._quer("f7a1_luta_jj_finalizou") or au._quer("f7a1_luta_jj_finalizou_letreiro"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0)
		var a5 := _buscar(4, "defensive", func(r: Dictionary) -> bool: return _ganhou_por(r, "submission"))
		var tela5 := await _lutar_com("bjj", 4, "defensive", a5)
		if tela5 != null:
			var res5: Dictionary = au.gs.luta.result
			au._estado = "f7a1_luta_jj_finalizou"
			await _ir_para(tela5, float(res5.t_ko) + 0.2)
			await au._ver("f7a1_luta_jj_finalizou")
			await _ir_para(tela5, float(res5.t_ko) + 0.6, 0.15)  # o letreiro entra em t_ko + 0,5; a janela VENCEU só em t_end + 1,5
			au._exigir(tela5._banner_sub_img.visible or tela5._banner.visible, "f7a1_luta_jj_finalizou_letreiro", "o letreiro FINALIZOU! aparece")
			await au._ver("f7a1_luta_jj_finalizou_letreiro")

	# --- Arena: amadores na borracharia ---
	if au._quer("f7a1_arena_borracharia"):
		var achada: Dictionary = au._achar_luta(true, true)
		au._novo_jogo()
		au.gs.atributos = achada.atr
		await au._abrir()
		au.gs.rng.seed = int(achada.k)
		var fluxo: Node = au._cena.get_node("Fluxo")
		fluxo.abrir_previa()
		await au._esperar(0.3)
		fluxo.janela.lutar_pedido.emit()
		await au._esperar(0.3)
		au._exigir(str(fluxo.tela.luta.arena) == "arena", "f7a1_arena_borracharia", "amador luta na borracharia")
		await au._ver("f7a1_arena_borracharia")
	if au._quer("f7a1_arena_liga"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0)
		var a6 := _buscar(5, "aggressive", func(r: Dictionary) -> bool: return float(r.t_end) >= 8.0)
		var tela6 := await _lutar_com("boxing", 5, "aggressive", a6)
		if tela6 != null:
			au._estado = "f7a1_arena_liga"
			au._exigir(str(tela6.luta.arena) == "arena_league", "f7a1_arena_liga", "o Kid luta na arena da liga")
			await _ir_para(tela6, 4.0)
			await au._ver("f7a1_arena_liga")

	# --- Fim: derrota com a arena visível por baixo (5.4/B2) e a nota da passiva ---
	if au._quer("f7a1_fim_derrota_arena") or au._quer("f7a1_fim_nota_boxe"):
		au._novo_jogo()
		au._academia("boxing", ["treadmill", "jump_rope"], 800.0)
		var a7 := _buscar(4, "aggressive", func(r: Dictionary) -> bool:
			return not bool(r.win) and float(r.opp_counter_damage) >= 0.2 * float(r.life_max[0]), [[0.8, 0.8, 0.8], [0.7, 0.7, 0.7], [0.9, 0.9, 0.9], [0.8, 0.5, 0.8]])
		if a7.is_empty():
			a7 = _buscar(4, "aggressive", func(r: Dictionary) -> bool: return not bool(r.win), [[0.8, 0.8, 0.8], [0.6, 0.6, 0.6]])
		await _fim_de_derrota("boxing", 4, "aggressive", a7, "f7a1_fim_derrota_arena", "f7a1_fim_nota_boxe")
	if au._quer("f7a1_fim_nota_jj"):
		au._novo_jogo()
		au._academia("bjj", ["treadmill", "jump_rope"], 800.0)
		var a8 := _buscar(4, "defensive", func(r: Dictionary) -> bool: return not bool(r.win), [[0.8, 0.8, 0.8], [0.7, 0.7, 0.7], [0.6, 0.6, 0.6]])
		await _fim_de_derrota("bjj", 4, "defensive", a8, "", "f7a1_fim_nota_jj")


## Luta perdida até o fim pela tela de verdade: a tela de fim abre COM A ARENA ainda visível por baixo.
func _fim_de_derrota(arte: String, idx: int, tat: String, achada: Dictionary, nome_arena: String, nome_nota: String) -> void:
	var tela := await _lutar_com(arte, idx, tat, achada)
	if tela == null:
		return
	au.gs.aguardar_motivo()
	tela._clock = tela._fim_total + 0.1
	await au._esperar(1.0)
	var fluxo: Node = au._cena.get_node("Fluxo")
	au._estado = nome_nota
	au._exigir(str(fluxo.janela.get_script().get_global_name()) == "JanelaFim" and tela.visible, nome_nota, "a tela de fim abre com a arena visível por baixo")
	var t: Dictionary = au.gs.textos_fim()
	if nome_arena != "" and au._quer(nome_arena):
		await au._ver(nome_arena)
	if au._quer(nome_nota):
		au._exigir(str(t.get("passive_note", "")) != "" or nome_arena != "", nome_nota, "a derrota traz a nota da passiva (passive_note)")
		await au._ver(nome_nota)
