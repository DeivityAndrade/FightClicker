extends RefCounted
## Estados do ui_audit.gd: Fase 7b1 (Muay Thai): escolha da arte com 3 cartões, prévia da Canela nas 3 táticas, HUD da luta com as
## marcas na perna, PERNA CHEIA!, letreiro CHUTE RODADO! nas duas arenas (borracharia e liga), o saco comprido na sala (foco, descanso,
## caixa), o Choque no compasso (começo, combo, chute, prêmio) e a região MUAY THAI da árvore.
## Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).

const TATICAS := ["aggressive", "defensive", "counter"]
const NOMES := [
	"f7b1_arte_3cartoes",
	"f7b1_previa_mt_aggressive", "f7b1_previa_mt_defensive", "f7b1_previa_mt_counter", "f7b1_previa_mt_tarde",
	"f7b1_luta_mt_marcas", "f7b1_luta_mt_cheia", "f7b1_luta_mt_rodado_liga", "f7b1_luta_mt_rodado_borracharia",
	"f7b1_sala_saco_foco", "f7b1_sala_saco_chute", "f7b1_sala_saco_descanso_gym", "f7b1_sala_saco_caixa",
	"f7b1_choque_mt_comeco", "f7b1_choque_mt_combo", "f7b1_choque_mt_chute", "f7b1_choque_mt_premio",
	"f7b1_arvore_mt",
]

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


func _adv(i: int) -> Dictionary:
	return au.gs.lutas.adversarios[i]


func _atr(opp: Dictionary, f: Array) -> Dictionary:
	return {"strength": opp.strength * f[0], "agility": opp.agility * f[1], "endurance": opp.endurance * f[2]}


## Procura uma luta (arte e tática já postas no motor) contra o adversário `idx` em que `pred(res)` vale: {atr, k} ou {}.
func _buscar(idx: int, tat: String, pred: Callable, fatores: Array = []) -> Dictionary:
	var opp := _adv(idx)
	var lista: Array = fatores if not fatores.is_empty() else [[1.0, 1.0, 1.0], [1.2, 1.2, 1.2], [0.9, 0.9, 0.9], [1.5, 0.8, 1.5],
		[0.8, 1.5, 0.8], [1.2, 1.5, 1.0], [1.0, 1.0, 1.5], [1.5, 1.0, 1.0], [1.5, 1.5, 1.0], [2.0, 2.0, 1.0]]
	for f in lista:
		var atr := _atr(opp, f)
		for k in range(1, 500):
			var r := RandomNumberGenerator.new()
			r.seed = k
			var res: Dictionary = au.gs.motor.lutar([atr.strength, atr.agility, atr.endurance],
				[opp.strength, opp.agility, opp.endurance], tat, int(r.randi()), true)
			if bool(pred.call(res)):
				return {"atr": atr, "k": k}
	return {}


func _ganhou_por(res: Dictionary, finish: String) -> bool:
	return bool(res.win) and str(res.finish) == finish


## Academia com Muay Thai (as 3 artes liberadas), a tela e a luta começadas; devolve a TelaLuta ou null.
func _lutar_mt(idx: int, tat: String, achada: Dictionary) -> Node:
	if achada.is_empty():
		au._problema("AUDIT", "estado " + au._estado, "não achei uma luta de Muay Thai com o que o estado pede (adversário %d, tática %s)" % [idx, tat])
		return null
	au._novo_jogo()
	au._academia("muay_thai", ["treadmill", "jump_rope", "kick_bag"], 800.0, "kick_bag", idx)
	au.gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
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


## Pula a luta para o instante t e CONGELA o relógio dela (os efeitos terminam, o quadro fica parado para a captura).
func _ir_para(tela: Node, t: float, espera: float = 0.35) -> void:
	tela.set_process(true)
	tela._clock = t
	await au._esperar(0.12)
	tela.set_process(false)
	await au._esperar(espera)


func _montar_mt(idx: int, tat: String) -> void:
	au._novo_jogo()
	au._academia("muay_thai", ["treadmill", "jump_rope", "kick_bag"], 800.0, "kick_bag", idx)
	au.gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]


func _rodar_fase7b1() -> void:
	if not _alguma():
		return
	await _escolha_e_previa()
	await _lutas()
	await _sala()
	await _choque()
	await _arvore()


# ---------------------------------------------------------------------------------------------
# Escolha da arte e prévia
# ---------------------------------------------------------------------------------------------

func _escolha_e_previa() -> void:
	if au._quer("f7b1_arte_3cartoes"):
		au._novo_jogo()
		au.gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		au.gs.permanente["last_art"] = "boxing"
		au.gs.permanente["career_number"] = 4
		await au._abrir()
		await au._esperar(0.5)
		au._estado = "f7b1_arte_3cartoes"
		var fj: Node = au._cena.get_node("Fluxo").janela
		au._exigir(fj != null and fj.has_method("_escolher"), au._estado, "a janela da escolha de arte abre")
		if fj != null and fj.has_method("_escolher"):
			au._exigir(fj._cartoes.size() == 3, au._estado, "são 3 cartões (%d)" % fj._cartoes.size())
			for c in fj._cartoes:
				var r: Rect2 = c.rect
				au._exigir(Rect2(0, 0, 640, 360).encloses(r), au._estado, "o cartão %s cabe na tela: %s" % [c.id, au._fmt(r)])
				au._exigir((c.container as Control).get_child_count() > 0, au._estado, "o cartão %s tem conteúdo" % c.id)
		await au._ver("f7b1_arte_3cartoes")
	# --- Prévia: a linha da Canela nas 3 táticas (o cartão ao lado da janela muda com a tática) ---
	var primeiro := true
	for t in TATICAS:
		var nome := "f7b1_previa_mt_%s" % t
		if not au._quer(nome):
			continue
		if primeiro:
			_montar_mt(4, t)
			au.gs.atributos = _atr(_adv(4), [1.0, 1.0, 1.0])
			await au._abrir()
			au._cena.get_node("Fluxo").abrir_previa()
			await au._esperar(0.5)
			primeiro = false
		var j: Node = au._cena.get_node("Fluxo").janela
		j._rotulo_tatica[t].botao.pressed.emit()
		await au._esperar(0.5)
		var cartao: Node = j._cartao
		au._exigir(cartao != null, nome, "a prévia com Muay Thai deveria ter o cartão da passiva")
		if cartao != null:
			var bloco: Dictionary = j._dados.passive_tactics[t]
			au._exigir(str(bloco.get("kind", "")) == "shin", nome, "o bloco é da Canela")
			au._exigir(str(bloco.get("line", "")) != "" and str(bloco.get("share", "")) != "", nome, "o bloco da tática tem linha e N EM 10")
			au._exigir(cartao.get_global_rect().end.x <= 640.0 and cartao.get_global_rect().end.y <= 360.0, nome, "o cartão cabe na tela")
			# B1 (QA 7b1): o texto da linha nao pode passar sobre as marcas, nem o fim do cartao sobrar menos que o conteudo
			var lr: Label = cartao.linha_rotulo
			var ind: Control = cartao.indicador
			au._exigir(lr != null and ind != null, nome, "o cartao da Canela expoe a linha e a fileira das marcas")
			if lr != null and ind != null:
				var fim_texto: float = lr.get_global_rect().position.y + lr.get_combined_minimum_size().y
				au._exigir(fim_texto <= ind.get_global_rect().position.y + 0.5, nome,
					"o texto da linha passa sobre as marcas (texto termina em y %.1f, marcas comecam em %.1f)" % [fim_texto, ind.get_global_rect().position.y])
				var rodape: float = cartao.get_global_rect().end.y
				au._exigir(ind.get_global_rect().end.y <= rodape, nome, "as marcas cabem no cartao")
		await au._ver(nome)
	if au._quer("f7b1_previa_mt_tarde"):
		# Defensivo contra quem aguenta: a perna só enche em menos da metade das lutas (linha "A PERNA SÓ ENCHE EM N DE 10").
		_montar_mt(5, "defensive")
		au.gs.atributos = _atr(_adv(5), [0.7, 0.8, 0.7])
		au.gs.definir_tatica("defensive")
		await au._abrir()
		au._cena.get_node("Fluxo").abrir_previa()
		await au._esperar(0.5)
		var jt: Node = au._cena.get_node("Fluxo").janela
		au._estado = "f7b1_previa_mt_tarde"
		au._exigir(jt._cartao != null, au._estado, "a prévia tem o cartão da passiva")
		await au._ver("f7b1_previa_mt_tarde")


# ---------------------------------------------------------------------------------------------
# Luta: marcas, PERNA CHEIA!, CHUTE RODADO! nas duas arenas
# ---------------------------------------------------------------------------------------------

## Instante do `n`-ésimo golpe do jogador que deixa a perna com `marcas` marcas (ou -1).
func _t_marcas(res: Dictionary, marcas: int) -> float:
	for e in res.events:
		if int(e.who) == 0 and str(e.type) != "dodge" and int(e.get("marks", 0)) >= marcas:
			return float(e.t)
	return -1.0


func _lutas() -> void:
	if au._quer("f7b1_luta_mt_marcas") or au._quer("f7b1_luta_mt_cheia") or au._quer("f7b1_luta_mt_rodado_liga"):
		_montar_mt(4, "counter")
		var a1 := _buscar(4, "counter", func(r: Dictionary) -> bool: return _ganhou_por(r, "spin_kick"))
		var tela1 := await _lutar_mt(4, "counter", a1)
		if tela1 != null:
			var res1: Dictionary = au.gs.luta.result
			au._estado = "f7b1_luta_mt_marcas"
			au._exigir(str(tela1.luta.arena) == "arena_league", au._estado, "Tonhão luta na arena da liga")
			au._exigir(tela1._passiva == "shin" and tela1._marcas_hud.size() == 3, au._estado, "o HUD tem as 3 marcas da perna")
			# O especial dos cliques do Muay Thai nunca é o uppercut do boxe (lição A1 da 7a1).
			var esp: Array = tela1._golpe_especial({"phase": "standing"})
			au._exigir(esp[0] != "uppercut" and esp[1] != "hit_up", au._estado, "o especial do Muay Thai não usa uppercut: %s" % str(esp))
			au._exigir(esp[0] == "spin_kick", au._estado, "o especial do Muay Thai é o chute rodado: %s" % str(esp))
			if au._quer("f7b1_luta_mt_marcas"):
				var t2 := _t_marcas(tela1.luta, 2)
				await _ir_para(tela1, t2 + 0.15)
				au._exigir(tela1._marcas_acesas >= 2, au._estado, "2 marcas acesas (%d)" % tela1._marcas_acesas)
				await au._ver("f7b1_luta_mt_marcas")
			if au._quer("f7b1_luta_mt_cheia"):
				au._estado = "f7b1_luta_mt_cheia"
				var t3 := _t_marcas(tela1.luta, 3)
				await _ir_para(tela1, t3 + 0.2)
				au._exigir(tela1._marcas_cheias, au._estado, "a perna cheia pisca as marcas")
				au._exigir(tela1._letreiro_cheia != null and tela1._letreiro_cheia.visible, au._estado, "o letreiro PERNA CHEIA! aparece")
				await au._ver("f7b1_luta_mt_cheia")
			if au._quer("f7b1_luta_mt_rodado_liga"):
				au._estado = "f7b1_luta_mt_rodado_liga"
				await _ir_para(tela1, float(res1.t_ko) + 0.1, 0.1)
				await _ir_para(tela1, float(res1.t_ko) + 0.9, 0.1)
				au._exigir(tela1._banner_spin.visible, au._estado, "o letreiro CHUTE RODADO! aparece na arena da liga")
				au._exigir(not tela1._banner_ko.visible, au._estado, "no chute rodado o K.O.! não aparece")
				await au._ver("f7b1_luta_mt_rodado_liga")
	if au._quer("f7b1_luta_mt_rodado_borracharia"):
		_montar_mt(3, "counter")
		var a2 := _buscar(3, "counter", func(r: Dictionary) -> bool: return _ganhou_por(r, "spin_kick"))
		var tela2 := await _lutar_mt(3, "counter", a2)
		if tela2 != null:
			var res2: Dictionary = au.gs.luta.result
			au._estado = "f7b1_luta_mt_rodado_borracharia"
			au._exigir(str(tela2.luta.arena) == "arena", au._estado, "Muralha luta na borracharia")
			await _ir_para(tela2, float(res2.t_ko) + 0.1, 0.1)
			await _ir_para(tela2, float(res2.t_ko) + 0.9, 0.1)
			au._exigir(tela2._banner_spin.visible, au._estado, "o letreiro CHUTE RODADO! aparece na borracharia")
			await au._ver("f7b1_luta_mt_rodado_borracharia")


# ---------------------------------------------------------------------------------------------
# Sala: o saco comprido de chute
# ---------------------------------------------------------------------------------------------

func _sala() -> void:
	if au._quer("f7b1_sala_saco_foco") or au._quer("f7b1_sala_saco_chute"):
		au._novo_jogo()
		au._garagem_arte("muay_thai", ["treadmill", "jump_rope", "kick_bag"], 800.0, "kick_bag")
		au.gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		await au._abrir()
		await au._esperar(0.4)
		var sala: Node = au._cena.get_node("Sala")
		au._estado = "f7b1_sala_saco_foco"
		au._exigir(sala._chute.visible and sala._chute.nome_sprite.begins_with("kick_bag_l"), au._estado, "o saco comprido aparece no foco")
		au._exigir(sala._chute.position.distance_to(Vector2(336, 190)) < 1.5, au._estado, "o saco está no gancho do manifest (336,190): %s" % str(sala._chute.position))
		au._exigir(sala._corrente_chute.visible, au._estado, "a corrente do saco comprido aparece")
		if au._quer("f7b1_sala_saco_foco"):
			await au._ver("f7b1_sala_saco_foco")
		if au._quer("f7b1_sala_saco_chute"):
			au._estado = "f7b1_sala_saco_chute"
			au.gs.clicar()
			await au._esperar(0.03)
			au._exigir(sala._chute.nome_sprite.ends_with("_hit") or sala._chute.nome_sprite.ends_with("_idle"), au._estado, "o saco reage ao clique (%s)" % sala._chute.nome_sprite)
			au._exigir(sala._lutador.nome_sprite.contains("low_kick"), au._estado, "o lutador chuta (%s)" % sala._lutador.nome_sprite)
			await au._ver("f7b1_sala_saco_chute")
	if au._quer("f7b1_sala_saco_descanso_gym"):
		_montar_mt(4, "counter")
		au.gs.foco = "punching_bag"
		await au._abrir()
		await au._esperar(0.4)
		var sala2: Node = au._cena.get_node("Sala")
		au._estado = "f7b1_sala_saco_descanso_gym"
		au._exigir(sala2._chute.visible and sala2._chute.nome_sprite.ends_with("_rest_gym"), au._estado, "na academia o saco descansa com a luz dos tubos (%s)" % sala2._chute.nome_sprite)
		au._exigir(not sala2._corrente_chute.visible, au._estado, "deitado, o saco não tem corrente")
		au._exigir(sala2._chute.position.distance_to(Vector2(192, 318)) < 1.5, au._estado, "o saco deitado está no canto (192,318): %s" % str(sala2._chute.position))
		await au._ver("f7b1_sala_saco_descanso_gym")
	if au._quer("f7b1_sala_saco_caixa"):
		au._novo_jogo()
		au._garagem_arte("muay_thai", ["treadmill", "jump_rope"], 4000.0, "punching_bag")
		au.gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		await au._abrir()
		await au._esperar(0.4)
		var sala3: Node = au._cena.get_node("Sala")
		au._estado = "f7b1_sala_saco_caixa"
		au._exigir(au.gs.comprar_aparelho("kick_bag"), au._estado, "compra o saco comprido")
		await au._esperar(0.8)
		au._exigir(sala3._caixas.has("kick_bag") and not sala3._chute.visible, au._estado, "comprou: só a caixa grande, sem o saco")
		if sala3._caixas.has("kick_bag"):
			au._exigir(sala3._caixas["kick_bag"].position.distance_to(Vector2(192, 318)) < 2.0, au._estado,
				"a caixa está no canto (192,318): %s" % str(sala3._caixas["kick_bag"].position))
		await au._ver("f7b1_sala_saco_caixa")


# ---------------------------------------------------------------------------------------------
# Choque do Muay Thai
# ---------------------------------------------------------------------------------------------

func _choque() -> void:
	if not _quer_prefixo("f7b1_choque_mt_"):
		return
	var f7a2 = au._f7a2
	if au._quer("f7b1_choque_mt_comeco"):
		var tela: Node = await f7a2._entrar("f7b1_choque_mt_comeco", "gym", "muay_thai", "spar")
		if tela != null:
			f7a2._checar_hud("f7b1_choque_mt_comeco", tela)
			au._exigir(tela._centro.visible and tela._centro.text == au._txt("mini_ready"), "f7b1_choque_mt_comeco", "a contagem mostra PREPARAR")
			au._exigir(tela._dica.text == au._txt("spar_tip_muay_thai"), "f7b1_choque_mt_comeco", "a dica de controle do Muay Thai")
			au._exigir(tela._faixa != null and tela._degraus.size() == 3, "f7b1_choque_mt_comeco", "a faixa da batida e os 3 degraus do combo")
			await au._ver("f7b1_choque_mt_comeco")
	if au._quer("f7b1_choque_mt_combo") or au._quer("f7b1_choque_mt_chute"):
		var tela2: Node = await f7a2._entrar("f7b1_choque_mt_combo", "gym", "muay_thai", "spar")
		if tela2 != null:
			var j = f7a2._semear_choque(tela2, "muay_thai", 1)
			f7a2._ir(j, 0.0)
			# 2 cliques no tempo (batidas 1 e 2): combo 2, o CHUTE fica armado.
			for k in [1, 2]:
				j.passo(float(k) * 0.5 - j.tempo)
				j.apertar()
				j.soltar()
			await au._esperar(0.1)
			au._estado = "f7b1_choque_mt_combo"
			au._exigir(int(j.estado().combo) == 2, au._estado, "2 cliques no tempo = combo 2 (%d)" % int(j.estado().combo))
			au._exigir(tela2._degraus.size() == 3 and (tela2._degraus[0] as ColorRect).color != Color("2a2233"), au._estado, "os degraus acendem")
			if au._quer("f7b1_choque_mt_combo"):
				await au._ver("f7b1_choque_mt_combo")
			if au._quer("f7b1_choque_mt_chute"):
				au._estado = "f7b1_choque_mt_chute"
				j.passo(1.5 - j.tempo)
				j.apertar()
				j.soltar()
				await au._esperar(0.08)
				au._exigir(int(j.chutes) == 1, au._estado, "o 3º clique no tempo é um CHUTE")
				await au._ver("f7b1_choque_mt_chute")
	if au._quer("f7b1_choque_mt_premio"):
		var tela3: Node = await f7a2._entrar("f7b1_choque_mt_premio", "gym", "muay_thai", "spar")
		if tela3 != null:
			var j3 = f7a2._semear_choque(tela3, "muay_thai", 1)
			f7a2._ir(j3, 29.9)
			j3.barra = 0.0
			j3.pontos = 3
			j3.pontos_dele = 1
			j3.passo(0.5)
			await au._esperar(0.8)
			au._exigir(tela3.janela != null, "f7b1_choque_mt_premio", "a tela de prêmio abre no fim")
			if tela3.janela != null:
				au._exigir(bool(tela3.premio.get("aquecido", false)), "f7b1_choque_mt_premio", "vencer guarda o AQUECIDO")
			await au._ver("f7b1_choque_mt_premio")


# ---------------------------------------------------------------------------------------------
# Árvore: região MUAY THAI
# ---------------------------------------------------------------------------------------------

func _arvore() -> void:
	if not au._quer("f7b1_arvore_mt"):
		return
	au._novo_jogo()
	au._garagem_arte("muay_thai", [], 800.0)
	au.gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	au._f54_f6a._com_nos54(["body_jab", "mt_shin"], 800)
	var j: Node = await au._f54_f6a._abrir_arvore()
	au._estado = "f7b1_arvore_mt"
	au._exigir(au._eh(j, "JanelaMapa"), au._estado, "o mapa abre")
	if au._eh(j, "JanelaMapa"):
		j.ir_para("mt_shin")
		await au._esperar(0.4)
		for id in ["mt_shin", "mt_oil", "mt_rope", "style_muay_thai"]:
			au._exigir(id in j.nos_desenhados(), au._estado, "o nó %s está desenhado" % id)
		au._exigir("muay_thai" in j.placas_desenhadas(), au._estado, "a plaquinha da região MUAY THAI aparece (%s)" % str(j.placas_desenhadas()))
	await au._ver("f7b1_arvore_mt")
