extends RefCounted
## Estados do ui_audit.gd: Fase 7b2 (2ª passiva das 3 artes): escolha da arte com as 2 opções de passiva (cadeado + "N/3", liberada,
## selecionada), prévia de cada 2ª passiva, HUD da luta (3 losangos de carga do Contragolpista, sinal NO CHÃO / CLINCH), os 3 letreiros
## do fim (K.O. NO CONTRAGOLPE! / O JUIZ PAROU! / JOELHADA!), os sinais pequenos (CARGA!, LEVANTOU, CLINCH!) e o fim da luta
## (meta "N/3" e o aviso único NOVO JEITO DE LUTAR). Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).

const OURO := Color("fff3c4")  # UiTema.Y2 (o auditor carrega antes dos autoloads: não referencia UiTema)
const TODAS := ["boxing", "bjj", "muay_thai"]
const NOMES := [
	"f7b2_arte_0de3", "f7b2_arte_2de3", "f7b2_arte_liberada", "f7b2_arte_selecionada",
	"f7b2_previa_boxe_counter", "f7b2_previa_boxe_aggressive", "f7b2_previa_jj_defensive", "f7b2_previa_jj_tarde",
	"f7b2_previa_mt_aggressive", "f7b2_previa_mt_tarde",
	"f7b2_luta_carga_0", "f7b2_luta_carga_1", "f7b2_luta_carga_2", "f7b2_luta_carga_3", "f7b2_luta_cp_ko_liga", "f7b2_luta_cp_ko_borracharia",
	"f7b2_luta_jj_chao", "f7b2_luta_jj_levantou", "f7b2_luta_jj_juiz",
	"f7b2_luta_mt_clinch", "f7b2_luta_mt_joelhada",
	"f7b2_fim_meta", "f7b2_fim_libera",
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


func _rodar_fase7b2() -> void:
	if not _alguma():
		return
	await _escolha()
	await _previas()
	await _lutas()
	await _fim()


# ---------------------------------------------------------------------------------------------
# Montagem
# ---------------------------------------------------------------------------------------------

func _adv(i: int) -> Dictionary:
	return au.gs.lutas.adversarios[i]


func _atr(opp: Dictionary, f: Array) -> Dictionary:
	return {"strength": opp.strength * f[0], "agility": opp.agility * f[1], "endurance": opp.endurance * f[2]}


func _aparelhos(arte: String) -> Array:
	return ["treadmill", "jump_rope", "kick_bag"] if arte == "muay_thai" else ["treadmill", "jump_rope"]


## Academia com a arte, as 3 artes liberadas e a 2ª passiva da arte posta no motor (antes de _abrir()).
func _montar(arte: String, idx: int, passiva: int = 2) -> void:
	au._novo_jogo()
	au._academia(arte, _aparelhos(arte), 800.0, "kick_bag" if arte == "muay_thai" else "punching_bag", idx)
	au.gs.permanente["arts_unlocked"] = TODAS.duplicate()
	au.gs.permanente["passive_wins"] = {arte: 3}
	au.gs.permanente["passives_unlocked"] = [arte]
	au.gs.permanente["last_passive"] = {arte: passiva}
	au.gs.passiva_carreira = passiva
	au.gs._academia._atualizar_passiva()


## Procura uma luta (arte e passiva já postas no motor) contra o adversário `idx` em que `pred(res)` vale: {atr, k} ou {}.
func _buscar(idx: int, tat: String, pred: Callable, fatores: Array = []) -> Dictionary:
	var opp := _adv(idx)
	var lista: Array = fatores if not fatores.is_empty() else [[1.0, 1.0, 1.0], [1.2, 1.2, 1.2], [0.9, 0.9, 0.9], [1.5, 0.8, 1.5],
		[0.8, 1.5, 0.8], [1.2, 1.5, 1.0], [1.0, 1.0, 1.5], [1.5, 1.0, 1.0], [1.5, 1.5, 1.0], [2.0, 2.0, 1.0], [0.8, 0.8, 0.8], [1.1, 1.1, 1.1]]
	for f in lista:
		var atr := _atr(opp, f)
		for k in range(1, 700):
			var r := RandomNumberGenerator.new()
			r.seed = k
			var res: Dictionary = au.gs.motor.lutar([atr.strength, atr.agility, atr.endurance],
				[opp.strength, opp.agility, opp.endurance], tat, int(r.randi()), true)
			if bool(pred.call(res)):
				return {"atr": atr, "k": k}
	return {}


func _por(res: Dictionary, finish: String) -> bool:
	return bool(res.win) and str(res.finish) == finish


## Abre a tela, a prévia e começa a luta (a tática já vai no motor); devolve a TelaLuta ou null.
func _lutar(arte: String, idx: int, tat: String, achada: Dictionary) -> Node:
	if achada.is_empty():
		au._problema("AUDIT", "estado " + au._estado, "não achei uma luta de %s com o que o estado pede (adversário %d, tática %s)" % [arte, idx, tat])
		return null
	_montar(arte, idx)
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
func _ir_para(tela: Node, t: float, espera: float = 0.3) -> void:
	tela.set_process(true)
	tela._clock = t
	await au._esperar(0.12)
	tela.set_process(false)
	await au._esperar(espera)


## Instante do 1º evento que cumpre `pred(e)` (ou -1).
func _t_evento(luta: Dictionary, pred: Callable) -> float:
	for e in luta.events:
		if bool(pred.call(e)):
			return float(e.t)
	return -1.0


## Prova de verdade (B1 do QA 7b2): na imagem renderizada, todo pixel opaco do letreiro tem de aparecer com a cor dele; se um número de
## dano estiver por cima, os pixels dele mudam de cor. (Um sentinela de z não pegava o bug: a ordem real dos números não segue o z_index.)
func _letreiro_acima_dos_numeros(tela: Node, banner: Sprite2D, nome: String) -> void:
	if banner == null:
		return
	await au._esperar(0.2)
	await au.process_frame
	await RenderingServer.frame_post_draw
	var img: Image = au.root.get_texture().get_image()
	var tex_img: Image = banner.texture.get_image()
	var tam := Vector2(tex_img.get_width(), tex_img.get_height())
	var k := float(img.get_width()) / 640.0
	var total := 0
	var errados := 0
	for yy in int(tam.y):
		for xx in int(tam.x):
			var c := tex_img.get_pixel(xx, yy)
			if c.a < 0.99:
				continue
			var p := banner.global_position + (Vector2(xx, yy) + Vector2(0.5, 0.5) - tam / 2.0) * banner.global_scale
			var cor := img.get_pixel(clampi(int(p.x * k), 0, img.get_width() - 1), clampi(int(p.y * k), 0, img.get_height() - 1))
			total += 1
			if absf(cor.r - c.r) + absf(cor.g - c.g) + absf(cor.b - c.b) > 0.12:
				errados += 1
	# Caixa inteira (buracos e vãos das letras também): nada flutuante pode estar visível dentro dela. Prova por diferença de pixels:
	# a imagem como está x a imagem com números, combo, CARGA! e sinais escondidos; se diferirem dentro da caixa, tem texto flutuante lá.
	var caixa := Rect2(banner.global_position - tam * banner.global_scale / 2.0, tam * banner.global_scale)
	var escondidos: Array = []
	for nn in tela._numeros:
		if nn._raiz.visible:
			escondidos.append(nn._raiz)
	for extra in [tela._rotulo_combo, tela._letreiro_carga]:
		if extra != null and extra.visible:
			escondidos.append(extra)
	for sp in tela._sinais.values():
		if sp.visible:
			escondidos.append(sp)
	var antes: Array = []
	for no in escondidos:
		antes.append(no.visible)
		no.visible = false
	await au.process_frame
	await RenderingServer.frame_post_draw
	var img_b: Image = au.root.get_texture().get_image()
	await au.process_frame
	await RenderingServer.frame_post_draw
	var img_b2: Image = au.root.get_texture().get_image()  # 2ª imagem sem os textos: o que muda entre as duas é animação do cenário (lâmpada), não texto
	for i in escondidos.size():
		escondidos[i].visible = antes[i]
	var difs := 0
	for yy in range(int(caixa.position.y * k), int(caixa.end.y * k)):
		for xx in range(int(caixa.position.x * k), int(caixa.end.x * k)):
			var ca := img.get_pixel(xx, yy)
			var cb := img_b.get_pixel(xx, yy)
			var cb2 := img_b2.get_pixel(xx, yy)
			if absf(cb.r - cb2.r) + absf(cb.g - cb2.g) + absf(cb.b - cb2.b) > 0.05:
				continue
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.05:
				difs += 1
	print("CAIXA ", nome, " pixels de texto flutuante na caixa do letreiro: ", difs)
	au._exigir(difs <= 4, nome, "texto flutuante (número de dano, combo, CARGA!, sinal) visível dentro da caixa do letreiro: %d pixels" % difs)
	print("LETREIRO ", nome, " pixels opacos ", total, " cobertos ", errados)
	au._exigir(total > 100 and errados <= 2, nome, "o letreiro fica por cima dos números de dano (%d de %d pixels cobertos)" % [errados, total])


# ---------------------------------------------------------------------------------------------
# Escolha da arte: 2 opções por cartão
# ---------------------------------------------------------------------------------------------

func _preparar_escolha(vitorias: Dictionary, liberadas: Array, ultima_passiva: Dictionary) -> void:
	au._novo_jogo()
	au.gs.permanente["arts_unlocked"] = TODAS.duplicate()
	au.gs.permanente["last_art"] = "boxing"
	au.gs.permanente["career_number"] = 4
	au.gs.permanente["passive_wins"] = vitorias.duplicate()
	au.gs.permanente["passives_unlocked"] = liberadas.duplicate()
	au.gs.permanente["last_passive"] = ultima_passiva.duplicate()


func _abrir_escolha(nome: String) -> Node:
	await au._abrir()
	await au._esperar(0.5)
	au._estado = nome
	var fj: Node = au._cena.get_node("Fluxo").janela
	au._exigir(fj != null and fj.has_method("_escolher"), nome, "a janela da escolha de arte abre")
	if fj == null or not fj.has_method("_escolher"):
		return null
	au._exigir(fj._cartoes.size() == 3, nome, "são 3 cartões (%d)" % fj._cartoes.size())
	for c in fj._cartoes:
		var r: Rect2 = c.rect
		au._exigir(Rect2(0, 0, 640, 360).encloses(r), nome, "o cartão %s cabe na tela: %s" % [c.id, au._fmt(r)])
		var opcoes: Array = fj._opcoes.get(c.id, [])
		au._exigir(opcoes.size() == 2, nome, "o cartão %s tem 2 opções de passiva (%d)" % [c.id, opcoes.size()])
		for o in opcoes:
			var caixa := Rect2((o.borda as Control).position, (o.borda as Control).size)
			au._exigir(Rect2(Vector2.ZERO, r.size).encloses(caixa), nome, "a caixa da passiva %d de %s cabe no cartão" % [int(o.n), c.id])
			if o.texto != null:
				var alt := (o.texto as Label).get_combined_minimum_size().y
				au._exigir(alt <= 32.5, nome, "o texto da passiva %d de %s cabe em 3 linhas (%.0f px)" % [int(o.n), c.id, alt])
				au._exigir((o.texto as Label).get_line_count() <= 3, nome, "o texto da passiva %d de %s tem no máximo 3 linhas (%d)" % [int(o.n), c.id, (o.texto as Label).get_line_count()])
	return fj


func _escolha() -> void:
	if au._quer("f7b2_arte_0de3"):
		_preparar_escolha({}, [], {})
		var f0: Node = await _abrir_escolha("f7b2_arte_0de3")
		if f0 != null:
			for c in f0._cartoes:
				var o2: Dictionary = f0._opcoes[c.id][1]
				au._exigir(bool(o2.trancada), au._estado, "a 2ª passiva de %s começa trancada" % c.id)
				au._exigir(int(f0._sel[c.id]) == 1, au._estado, "a 1ª passiva vem marcada em %s" % c.id)
		await au._ver("f7b2_arte_0de3")
	if au._quer("f7b2_arte_2de3"):
		_preparar_escolha({"boxing": 2, "bjj": 1, "muay_thai": 2}, [], {})
		var f1: Node = await _abrir_escolha("f7b2_arte_2de3")
		if f1 != null:
			# Clicar na opção trancada não marca nada (o cadeado treme).
			var antes := int(f1._sel["boxing"])
			(f1._opcoes["boxing"][1].botao as Button).pressed.emit()
			await au._esperar(0.3)
			au._exigir(int(f1._sel["boxing"]) == antes, au._estado, "a opção trancada não se deixa marcar")
		await au._ver("f7b2_arte_2de3")
	if au._quer("f7b2_arte_liberada"):
		# Jiu-jitsu com a meta batida (3/3): cadeado fora, a 2ª passiva pode ser marcada; as outras seguem trancadas.
		_preparar_escolha({"boxing": 2, "bjj": 3, "muay_thai": 0}, ["bjj"], {})
		var f2: Node = await _abrir_escolha("f7b2_arte_liberada")
		if f2 != null:
			var o_bjj: Dictionary = f2._opcoes["bjj"][1]
			au._exigir(not bool(o_bjj.trancada), au._estado, "a 2ª passiva do Jiu-jitsu está liberada")
			au._exigir(int(f2._sel["bjj"]) == 1, au._estado, "liberada, mas a marcada continua a 1ª até o jogador mudar")
		await au._ver("f7b2_arte_liberada")
	if au._quer("f7b2_arte_selecionada"):
		_preparar_escolha({"boxing": 3, "bjj": 3, "muay_thai": 1}, ["boxing", "bjj"], {"bjj": 2})
		var f3: Node = await _abrir_escolha("f7b2_arte_selecionada")
		if f3 != null:
			au._exigir(int(f3._sel["bjj"]) == 2, au._estado, "a última passiva (2ª) vem marcada no Jiu-jitsu")
			# Marca a 2ª do Boxe: a borda dourada muda de lugar e a marcada vale ao escolher.
			(f3._opcoes["boxing"][1].botao as Button).pressed.emit()
			await au._esperar(0.2)
			au._exigir(int(f3._sel["boxing"]) == 2, au._estado, "o clique na 2ª passiva do Boxe a marca")
			au._exigir((f3._opcoes["boxing"][1].borda as ColorRect).color == OURO and (f3._opcoes["boxing"][0].borda as ColorRect).color != OURO,
				au._estado, "a marcada tem a borda dourada e a outra não")
			await au._ver("f7b2_arte_selecionada")
			f3._escolher("boxing")
			await au._esperar(0.1)
			au._exigir(au.gs.arte_id == "boxing" and au.gs.passiva_carreira == 2, au._estado, "escolher o Boxe com a 2ª marcada vale a carreira (passiva %d)" % au.gs.passiva_carreira)


# ---------------------------------------------------------------------------------------------
# Prévia: a linha da 2ª passiva
# ---------------------------------------------------------------------------------------------

func _abrir_previa(arte: String, idx: int, tat: String, fatores: Array) -> Node:
	_montar(arte, idx)
	au.gs.atributos = _atr(_adv(idx), fatores)
	au.gs.definir_tatica(tat)
	await au._abrir()
	au._cena.get_node("Fluxo").abrir_previa()
	await au._esperar(0.5)
	return au._cena.get_node("Fluxo").janela


func _conferir_previa(nome: String, j: Node, tipo: String) -> void:
	au._estado = nome
	var cartao: Node = j._cartao
	au._exigir(cartao != null, nome, "a prévia com a 2ª passiva deveria ter o cartão")
	if cartao == null:
		return
	au._exigir(int(j._dados.get("art_passive", 0)) == 2, nome, "a prévia é da 2ª passiva")
	var bloco: Dictionary = j._dados.passive_tactics[str(j._tatica)] if j._dados.passive_tactics.has(str(j._tatica)) else j._dados.passive_tactics.values()[0]
	au._exigir(str(bloco.get("kind", "")) == tipo, nome, "o bloco é do tipo %s (%s)" % [tipo, str(bloco.get("kind", ""))])
	au._exigir(cartao.get_global_rect().end.x <= 640.0 and cartao.get_global_rect().end.y <= 360.0, nome, "o cartão cabe na tela: %s" % au._fmt(cartao.get_global_rect()))
	var lr: Label = cartao.linha_rotulo
	var ind: Control = cartao.indicador
	au._exigir(lr != null and ind != null, nome, "o cartão expõe a linha e o indicador")
	if lr != null and ind != null:
		var fim_texto: float = lr.get_global_rect().position.y + lr.get_combined_minimum_size().y
		au._exigir(fim_texto <= ind.get_global_rect().position.y + 0.5, nome,
			"o texto da linha passa sobre o indicador (termina em y %.1f, o indicador começa em %.1f)" % [fim_texto, ind.get_global_rect().position.y])
		au._exigir(ind.get_global_rect().end.y <= cartao.get_global_rect().end.y, nome, "o indicador cabe no cartão")
		au._exigir(lr.get_line_count() >= 1, nome, "a linha quebra em linhas sem cortar (%d linhas)" % lr.get_line_count())


func _previas() -> void:
	if not _quer_prefixo("f7b2_previa_"):
		return
	var jogos := [
		["f7b2_previa_boxe_counter", "boxing", 4, "counter", [1.0, 1.0, 1.0], "counter_punch"],
		["f7b2_previa_boxe_aggressive", "boxing", 4, "aggressive", [1.0, 1.0, 1.0], "counter_punch"],
		["f7b2_previa_jj_defensive", "bjj", 4, "defensive", [1.0, 1.0, 1.0], "top_control"],
		["f7b2_previa_jj_tarde", "bjj", 5, "defensive", [0.6, 0.7, 0.7], "top_control"],
		["f7b2_previa_mt_aggressive", "muay_thai", 4, "aggressive", [1.0, 1.0, 1.0], "thai_clinch"],
		["f7b2_previa_mt_tarde", "muay_thai", 5, "defensive", [0.6, 0.7, 0.7], "thai_clinch"],
	]
	for jg in jogos:
		var nome: String = jg[0]
		if not au._quer(nome):
			continue
		var j: Node = await _abrir_previa(str(jg[1]), int(jg[2]), str(jg[3]), jg[4])
		_conferir_previa(nome, j, str(jg[5]))
		await au._ver(nome)


# ---------------------------------------------------------------------------------------------
# Luta: carga, chão, clinch e os letreiros
# ---------------------------------------------------------------------------------------------

func _lutas() -> void:
	# --- Contragolpista: carga 0..3, K.O. NO CONTRAGOLPE! na liga e na borracharia ---
	if _quer_prefixo("f7b2_luta_carga_") or au._quer("f7b2_luta_cp_ko_liga"):
		_montar("boxing", 4)
		var a1 := _buscar(4, "counter", func(r: Dictionary) -> bool: return _por(r, "counter_ko") and int(r.get("charge_peak", 0)) >= 3)
		var tela1 := await _lutar("boxing", 4, "counter", a1)
		if tela1 != null:
			var luta: Dictionary = tela1.luta
			au._estado = "f7b2_luta_cp_ko_liga"
			au._exigir(str(luta.passive) == "counter_punch" and int(luta.art_passive) == 2, au._estado, "a luta é do Contragolpista (%s/%s)" % [str(luta.passive), str(luta.art_passive)])
			au._exigir(tela1._cargas_hud.size() == 3, au._estado, "o HUD tem os 3 losangos de carga (%d)" % tela1._cargas_hud.size())
			au._exigir(str(luta.arena) == "arena_league", au._estado, "Tonhão luta na arena da liga")
			au._exigir(tela1._idle_da_arte(0) == "block", au._estado, "a guarda alta é a pose de repouso (%s)" % tela1._idle_da_arte(0))
			var t_c1 := _t_evento(luta, func(e: Dictionary) -> bool: return int(e.charge) >= 1)
			var c_c1 := 1
			for e in luta.events:
				if float(e.t) == t_c1:
					c_c1 = int(e.charge)  # com o Contra-ataque a 1ª esquiva já vale 2 de carga
			var t_c2 := _t_evento(luta, func(e: Dictionary) -> bool: return int(e.charge) >= 2)
			var t_c3 := _t_evento(luta, func(e: Dictionary) -> bool: return int(e.charge) >= 3)
			if au._quer("f7b2_luta_carga_0"):
				au._estado = "f7b2_luta_carga_0"
				await _ir_para(tela1, maxf(0.3, t_c1 - 0.3))
				au._exigir(tela1._carga_atual == 0, au._estado, "sem carga (%d)" % tela1._carga_atual)
				await au._ver("f7b2_luta_carga_0")
			if au._quer("f7b2_luta_carga_1"):
				au._estado = "f7b2_luta_carga_1"
				await _ir_para(tela1, t_c1 + 0.15)
				au._exigir(tela1._carga_atual == c_c1, au._estado, "a 1ª esquiva acende %d carga(s) (%d)" % [c_c1, tela1._carga_atual])
				await au._ver("f7b2_luta_carga_1")
			if au._quer("f7b2_luta_carga_2"):
				au._estado = "f7b2_luta_carga_2"
				await _ir_para(tela1, t_c2 + 0.15)
				au._exigir(tela1._carga_atual == 2, au._estado, "2 cargas acesas (%d)" % tela1._carga_atual)
				await au._ver("f7b2_luta_carga_2")
			if au._quer("f7b2_luta_carga_3"):
				au._estado = "f7b2_luta_carga_3"
				await _ir_para(tela1, t_c3 + 0.2)
				au._exigir(tela1._carga_atual == 3 and tela1._carga_cheia, au._estado, "3 cargas, cheia (%d)" % tela1._carga_atual)
				au._exigir(tela1._letreiro_carga != null and tela1._letreiro_carga.visible, au._estado, "o sinal CARGA! aparece")
				await au._ver("f7b2_luta_carga_3")
			if au._quer("f7b2_luta_cp_ko_liga"):
				au._estado = "f7b2_luta_cp_ko_liga"
				var res1: Dictionary = au.gs.luta.result
				await _ir_para(tela1, float(res1.t_ko) + 0.1, 0.1)
				await _ir_para(tela1, float(res1.t_ko) + 0.9, 0.1)
				var b1: Sprite2D = tela1._banners_fim.get("counter_ko")
				au._exigir(b1 != null and b1.visible, au._estado, "o letreiro K.O. NO CONTRAGOLPE! aparece")
				au._exigir(not tela1._banner_ko.visible, au._estado, "no contragolpe o K.O.! comum não aparece")
				await _letreiro_acima_dos_numeros(tela1, b1, au._estado)
				await au._ver("f7b2_luta_cp_ko_liga")
	if au._quer("f7b2_luta_cp_ko_borracharia"):
		_montar("boxing", 3)
		var a2 := _buscar(3, "counter", func(r: Dictionary) -> bool: return _por(r, "counter_ko"))
		var tela2 := await _lutar("boxing", 3, "counter", a2)
		if tela2 != null:
			au._estado = "f7b2_luta_cp_ko_borracharia"
			au._exigir(str(tela2.luta.arena) == "arena", au._estado, "Muralha luta na borracharia")
			var res2: Dictionary = au.gs.luta.result
			await _ir_para(tela2, float(res2.t_ko) + 0.1, 0.1)
			await _ir_para(tela2, float(res2.t_ko) + 0.9, 0.1)
			var b2: Sprite2D = tela2._banners_fim.get("counter_ko")
			au._exigir(b2 != null and b2.visible, au._estado, "o letreiro K.O. NO CONTRAGOLPE! aparece na borracharia")
			await _letreiro_acima_dos_numeros(tela2, b2, au._estado)
			await au._ver("f7b2_luta_cp_ko_borracharia")
	# --- Por cima: no chão, LEVANTOU, O JUIZ PAROU! ---
	if au._quer("f7b2_luta_jj_chao") or au._quer("f7b2_luta_jj_juiz"):
		_montar("bjj", 4)
		var a3 := _buscar(4, "aggressive", func(r: Dictionary) -> bool: return _por(r, "ground_stop"))
		var tela3 := await _lutar("bjj", 4, "aggressive", a3)
		if tela3 != null:
			var luta3: Dictionary = tela3.luta
			au._estado = "f7b2_luta_jj_chao"
			au._exigir(str(luta3.passive) == "top_control", au._estado, "a luta é do Por cima (%s)" % str(luta3.passive))
			au._exigir(tela3._sinal_icone != null, au._estado, "o HUD tem o sinal NO CHÃO")
			if au._quer("f7b2_luta_jj_chao"):
				var t_g := _t_evento(luta3, func(e: Dictionary) -> bool: return bool(e.ground))
				await _ir_para(tela3, t_g + 0.9)
				au._exigir(tela3._sinal_aceso and tela3._fase_visual == "ground", au._estado, "no chão: sinal aceso e fase visual de chão")
				await au._ver("f7b2_luta_jj_chao")
			if au._quer("f7b2_luta_jj_juiz"):
				au._estado = "f7b2_luta_jj_juiz"
				var res3: Dictionary = au.gs.luta.result
				await _ir_para(tela3, float(res3.t_ko) + 0.1, 0.1)
				await _ir_para(tela3, float(res3.t_ko) + 0.9, 0.1)
				var b3: Sprite2D = tela3._banners_fim.get("ground_stop")
				au._exigir(b3 != null and b3.visible, au._estado, "o letreiro O JUIZ PAROU! aparece")
				au._exigir(not tela3._banner_sub_img.visible and not tela3._banner_ko.visible, au._estado, "sem FINALIZOU! nem K.O.! no juiz")
				await _letreiro_acima_dos_numeros(tela3, b3, au._estado)
				await au._ver("f7b2_luta_jj_juiz")
	if au._quer("f7b2_luta_jj_levantou"):
		_montar("bjj", 4)
		var a4 := _buscar(4, "defensive", func(r: Dictionary) -> bool: return int(r.get("stood_up", 0)) >= 1 and int(r.get("takedowns", 0)) >= 1)
		if a4.is_empty():
			a4 = _buscar(5, "defensive", func(r: Dictionary) -> bool: return int(r.get("stood_up", 0)) >= 1 and int(r.get("takedowns", 0)) >= 1)
		var tela4 := await _lutar("bjj", 5 if a4.is_empty() else 4, "defensive", a4)
		if tela4 != null:
			au._estado = "f7b2_luta_jj_levantou"
			var evs: Array = tela4.luta.events
			var t_l := -1.0
			var estava := false
			for e in evs:
				if estava and not bool(e.ground):
					t_l = float(e.t)
					break
				estava = bool(e.ground)
			au._exigir(t_l > 0.0, au._estado, "a luta tem um momento em que ele levanta")
			if t_l > 0.0:
				await _ir_para(tela4, t_l + 0.2, 0.15)
				var sp: Sprite2D = tela4._sinais.get("stood_up")
				au._exigir(sp != null and sp.visible, au._estado, "o sinal LEVANTOU aparece")
				au._exigir(not tela4._sinal_aceso, au._estado, "de pé: o sinal fixo apaga")
				await au._ver("f7b2_luta_jj_levantou")
	# --- Clinch: preso e JOELHADA! ---
	if au._quer("f7b2_luta_mt_clinch") or au._quer("f7b2_luta_mt_joelhada"):
		_montar("muay_thai", 3)
		var a5 := _buscar(3, "aggressive", func(r: Dictionary) -> bool: return _por(r, "knee_ko"))
		var tela5 := await _lutar("muay_thai", 3, "aggressive", a5)
		if tela5 != null:
			var luta5: Dictionary = tela5.luta
			au._estado = "f7b2_luta_mt_clinch"
			au._exigir(str(luta5.passive) == "thai_clinch", au._estado, "a luta é do Clinch (%s)" % str(luta5.passive))
			au._exigir(tela5._sinal_icone != null, au._estado, "o HUD tem o sinal CLINCH")
			if au._quer("f7b2_luta_mt_clinch"):
				var t_k := _t_evento(luta5, func(e: Dictionary) -> bool: return bool(e.clinch))
				await _ir_para(tela5, t_k + 0.25, 0.2)
				au._exigir(tela5._sinal_aceso, au._estado, "preso: o sinal CLINCH acende")
				var sc: Sprite2D = tela5._sinais.get("clinch")
				au._exigir(sc != null and sc.visible, au._estado, "o sinal pequeno CLINCH! aparece")
				await au._ver("f7b2_luta_mt_clinch")
			if au._quer("f7b2_luta_mt_joelhada"):
				au._estado = "f7b2_luta_mt_joelhada"
				var res5: Dictionary = au.gs.luta.result
				await _ir_para(tela5, float(res5.t_ko) + 0.1, 0.1)
				await _ir_para(tela5, float(res5.t_ko) + 0.9, 0.1)
				var b5: Sprite2D = tela5._banners_fim.get("knee_ko")
				au._exigir(b5 != null and b5.visible, au._estado, "o letreiro JOELHADA! aparece")
				au._exigir(not tela5._banner_ko.visible, au._estado, "na joelhada o K.O.! comum não aparece")
				await _letreiro_acima_dos_numeros(tela5, b5, au._estado)
				await au._ver("f7b2_luta_mt_joelhada")


# ---------------------------------------------------------------------------------------------
# Fim da luta: a meta e o aviso único
# ---------------------------------------------------------------------------------------------

## Vitória pela 1ª passiva do Boxe (K.O. de embalo) com `vitorias` já contadas; abre a janela de vitória com o resumo real.
func _vitoria_boxe(nome: String, vitorias: int) -> void:
	_montar("boxing", 4, 1)
	au.gs.permanente["passive_wins"] = {"boxing": vitorias}
	au.gs.permanente["passives_unlocked"] = []
	au.gs.permanente["last_passive"] = {"boxing": 1}
	var achada := _buscar(4, "aggressive", func(r: Dictionary) -> bool: return _por(r, "knockout"))
	if achada.is_empty():
		au._problema("AUDIT", "estado " + nome, "não achei uma vitória por K.O. de embalo do Boxe")
		return
	au.gs.atributos = achada.atr.duplicate()
	au.gs.definir_tatica("aggressive")
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
	var meta: Dictionary = resumo.get("passive_goal", {})
	au._exigir(not meta.is_empty(), nome, "a vitória pelo K.O. de embalo conta para a meta")
	if vitorias >= 2:
		au._exigir(str(resumo.get("passive2_unlocked", "")) == "boxing" and str(resumo.get("passive2_line", "")) != "", nome,
			"a 3ª vitória libera o Contragolpista e traz o aviso único")
	if vitorias < 2 and jv != null and jv.has_method("_texto_meta"):
		au._exigir(str(jv._texto_meta(resumo)).begins_with("%d/3" % (vitorias + 1)), nome, "a vitória mostra a meta %d/3 (%s)" % [vitorias + 1, str(jv._texto_meta(resumo))])
	await au._ver(nome)


func _fim() -> void:
	if au._quer("f7b2_fim_meta"):
		await _vitoria_boxe("f7b2_fim_meta", 0)
	if au._quer("f7b2_fim_libera"):
		await _vitoria_boxe("f7b2_fim_libera", 2)
