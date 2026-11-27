extends RefCounted
## Estados do ui_audit.gd: Polimento 1a (números flutuantes: normal pequeno, só o crítico grande, sem sopa).
## Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).

var au


func _init(auditor) -> void:
	au = auditor


func _quer_p1a() -> bool:
	for n in ["p1a_sala_sopa", "p1a_bjj_sopa", "p1a_luta_sopa"]:
		if au._quer(n):
			return true
	return false


## [{texto, escala, grande}] dos números vivos de uma lista de Sala.Numero.
func _vivos(lista: Array) -> Array:
	var r: Array = []
	for n in lista:
		if n.ativo:
			r.append({"texto": str(n._principal.text), "escala": float(n._principal.scale.x), "grande": bool(n.grande)})
	return r


## Regra do P1a: só o crítico (grande) passa de 1x; o resto fica pequeno, e a sopa é limitada.
func _conferir(nome: String, vivos: Array) -> void:
	var normais := 0
	for v in vivos:
		if bool(v.grande):
			au._exigir(float(v.escala) >= 2.0, nome, "crítico deveria sair grande: '%s'" % v.texto)
		else:
			normais += 1
			au._exigir(float(v.escala) <= 1.0, nome, "número normal saiu grande (%.1fx): '%s'" % [float(v.escala), v.texto])
	au._exigir(normais <= load("res://ui/ui_tema.gd").NUM_MAX_NORMAIS, nome, "sopa de números: %d normais vivos (máx %d)" % [normais, load("res://ui/ui_tema.gd").NUM_MAX_NORMAIS])


func _rodar_p1a() -> void:
	if not _quer_p1a():
		return
	# --- Sala: clique rápido + Metrônomo ligado, aparelho de 1 atributo (soco) e de 3 atributos (Jiu-jitsu) ---
	for q in [["p1a_sala_sopa", false], ["p1a_bjj_sopa", true]]:
		if not au._quer(q[0]):
			continue
		au._novo_jogo()
		if q[1]:
			au._academia("bjj", ["treadmill", "jump_rope", "grappling_dummy"], 3000.0, "grappling_dummy")
		au.gs.nivel_metronomo = 3
		au.gs.dados.crit_chance = 0.12
		au.gs.dados.base_training = 100.0
		await au._abrir()
		await au._esperar(0.3)
		var sala: Node = au._cena.get_node("Sala")
		for i in 28:  # ~7 cliques por segundo, com um auto-soco do Metrônomo a cada 2 cliques
			au.gs.clicar()
			if i % 2 == 0:
				au.gs.auto_socar()
			await au._esperar(0.14)
		_conferir(q[0], _vivos(sala._numeros))
		await au._ver(q[0])
		au.gs.dados.crit_chance = 0.0
	# --- Luta: uma saraivada de golpes normais com um crítico no meio ---
	if au._quer("p1a_luta_sopa"):
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
		for i in 14:
			var p := Vector2(300 + (i % 5) * 14, 245 - (i % 3) * 5)
			if i == 7:
				tela._numero_de_dano(757800.0, "crit", false, p)
			else:
				tela._numero_de_dano(2400.0 + i * 37.0, "hit", false, p)
			await au._esperar(0.05)
		var vivos := _vivos(tela._numeros)
		_conferir("p1a_luta_sopa", vivos)
		var tem_crit := false
		for v in vivos:
			tem_crit = tem_crit or bool(v.grande)
		au._exigir(tem_crit, "p1a_luta_sopa", "o crítico não pode sumir no meio da sopa")
		await au._ver("p1a_luta_sopa")
