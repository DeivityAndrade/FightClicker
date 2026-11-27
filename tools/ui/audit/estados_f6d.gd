extends RefCounted
## Estados do ui_audit.gd: Fase 6d (balão de descrição colado ao cursor; números do treino por atributo).
## Roda com o auditor `au` (núcleo em tools/ui/ui_audit.gd).

const TELA := Rect2(0, 0, 640, 360)

var au


func _init(auditor) -> void:
	au = auditor


func _a6d() -> bool:
	for n in au.ESTADOS_TODOS:
		if str(n).begins_with("f6d_") and au._quer(n):
			return true
	return false


## Distância do cursor até o retângulo (0 = o cursor está dentro dele).
func _dist(r: Rect2, p: Vector2) -> float:
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return q.distance_to(p)


## O balão (Dica) está aberto, dentro da tela, fora do item apontado e perto do cursor.
func _checar_balao(nome: String, alvo: Rect2, cursor: Vector2) -> void:
	var d = au._dica_inst()
	au._exigir(d != null and d.visible, nome, "o balão de descrição deveria estar visível")
	if d == null or not d.visible:
		return
	var r: Rect2 = d.retangulo()
	au._exigir(TELA.encloses(r), nome, "o balão saiu da tela: %s" % str(r))
	au._exigir(not r.intersects(alvo), nome, "o balão cobre o item apontado: balão %s, item %s" % [str(r), str(alvo)])
	au._exigir(_dist(r, cursor) <= 40.0, nome, "o balão ficou longe do cursor (%.0f px)" % _dist(r, cursor))
	au._exigir(str(d.texto_atual()) != "", nome, "o balão está sem texto")


func _loja_hover(painel: Node, chave: String, item: Dictionary, nome: String) -> void:
	var inst = au._dica_inst()
	var b: Control = item.botao
	var cursor := b.get_global_rect().get_center()
	inst.ancora_fixa = cursor
	painel._sobre(chave)
	await au._esperar(0.1)  # o balão tem até 0,15 s: aqui já tem de estar na tela
	_checar_balao(nome, b.get_global_rect(), cursor)  # o item apontado é o botão (o cursor está nele)
	await au._ver(nome)
	painel._sobre("")
	au._exigir(not inst.visible, nome, "o balão deveria sumir ao tirar o mouse")
	inst.ancora_fixa = Vector2(-1, -1)


## Números por atributo vivos na sala: [{texto, escala}] do mais alto para o mais baixo na tela.
func _numeros_vivos(sala: Node) -> Array:
	var r: Array = []
	for n in sala._numeros:
		if n.ativo:
			r.append({"texto": str(n._principal.text), "escala": float(n._principal.scale.x), "y": float(n._raiz.position.y), "x": float(n._raiz.position.x), "ret": n.retangulo(),
				"cor": n._principal.get_theme_color("font_color")})
	return r


func _rodar_fase6d() -> void:
	if not _a6d():
		return
	# --- Balão da loja e das melhorias: no lado de dentro da tela, colado ao cursor, sem cobrir o cartão ---
	if au._quer("f6d_balao_melhoria") or au._quer("f6d_balao_melhoria_baixo") or au._quer("f6d_balao_gerador"):
		au._novo_jogo()
		au.gs.treino = 99999.0
		await au._abrir()
		var p: Node = au._cena.get_node("PainelLoja")
		if au._quer("f6d_balao_gerador"):
			await _loja_hover(p, "g:" + str(au.gs.dados.geradores[0].id), p._gens[au.gs.dados.geradores[0].id], "f6d_balao_gerador")
		if au._quer("f6d_balao_melhoria"):
			await _loja_hover(p, "u:punching_bag", p._ups["punching_bag"], "f6d_balao_melhoria")
		if au._quer("f6d_balao_melhoria_baixo"):
			var ult: String = str(au.gs.dados.aparelhos[au.gs.dados.aparelhos.size() - 1].id)
			au.gs.niveis_melhoria[ult] = 0
			await _loja_hover(p, "u:" + ult, p._ups[ult], "f6d_balao_melhoria_baixo")
	if au._quer("f6d_balao_loja") or au._quer("f6d_balao_loja_metronomo"):
		au._novo_jogo()
		au.gs.dinheiro = 5000.0
		var p2: Node = await au._abrir_loja(true)
		if au._quer("f6d_balao_loja"):
			var g0: Dictionary = au.gs.lutas.geradores_pagos[0]
			await _loja_hover(p2, "p:" + str(g0.id), p2._pagos[g0.id], "f6d_balao_loja")
		if au._quer("f6d_balao_loja_metronomo"):
			await _loja_hover(p2, "m", p2._metro, "f6d_balao_loja_metronomo")
	# --- Regra de posição nos cantos da tela (balão grande, cursor encostado na borda) ---
	if au._quer("f6d_balao_cantos"):
		au._novo_jogo()
		await au._abrir()
		var inst = au._dica_inst()
		var texto := "TITULO DA MELHORIA\nDESCRICAO COMPRIDA QUE PRECISA QUEBRAR EM VARIAS LINHAS PARA CABER NO BALAO\nCUSTO: 1.234 TREINO"
		for c in [Vector2(4, 4), Vector2(636, 4), Vector2(4, 356), Vector2(636, 356), Vector2(320, 180)]:
			inst.ancora_fixa = c
			inst.mostrar(texto)
			var r: Rect2 = inst.retangulo()
			au._exigir(TELA.encloses(r), "f6d_balao_cantos", "cursor em %s: balão fora da tela %s" % [str(c), str(r)])
			au._exigir(not r.has_point(c), "f6d_balao_cantos", "balão em cima do cursor em %s" % str(c))
		inst.ancora_fixa = Vector2(630, 180)
		inst.mostrar(texto)
		await au._esperar(0.1)
		await au._ver("f6d_balao_cantos")
		au._sem_dica()
	# --- Balão do mapa da árvore (mesma regra de posição) ---
	if au._quer("f6d_balao_mapa"):
		au._novo_jogo()
		au._f54_f6a._com_nos54(["body_jab", "career_purse"], 30)
		var j: Node = await au._f54_f6a._abrir_arvore()
		var id := "gar_tape"
		j.ir_para(id)
		await au._esperar(0.2)
		j.mostrar_cartao(id)
		await au._esperar(0.1)
		var d: Dictionary = j._vis[id]
		var centro: Vector2 = d.centro - Vector2(j._cam) + j.VP.position
		var alvo_no := Rect2(centro - Vector2(d.raio, d.raio), Vector2(d.raio, d.raio) * 2.0)
		var cr := Rect2(j._cartao.position, j._cartao.size)
		au._exigir(j.VP.encloses(cr), "f6d_balao_mapa", "o cartão do nó saiu da janela do mapa: %s" % str(cr))
		au._exigir(not cr.intersects(alvo_no), "f6d_balao_mapa", "o cartão cobre o nó apontado")
		au._exigir(_dist(cr, centro) <= 24.0, "f6d_balao_mapa", "o cartão ficou longe do nó (%.0f px)" % _dist(cr, centro))
		await au._ver("f6d_balao_mapa")
	# --- Balão do hall ---
	if au._quer("f6d_balao_hall"):
		au._f6c2._fim_6c2(2, 40, ["hall_box"])
		await au._abrir()
		await au._esperar(0.3)
		var flh: Node = au._cena.get_node("Fluxo")
		flh.janela.mural_pedido.emit()
		await au._esperar(0.45)
		var janela: Node = flh.janela
		var linha: Control = janela.find_child("No_hall_fund", true, false)
		au._exigir(linha != null, "f6d_balao_hall", "há um nó do hall para apontar")
		if linha != null:
			var cursor := linha.get_global_rect().position + Vector2(40, 8)  # o mouse sobre o nome do nó
			au._dica_inst().ancora_fixa = cursor
			(linha.get_node("Hover") as Control).mouse_entered.emit()
			await au._esperar(0.1)
			_checar_balao("f6d_balao_hall", linha.get_global_rect(), cursor)
			await au._ver("f6d_balao_hall")
			(linha.get_node("Hover") as Control).mouse_exited.emit()
			au._exigir(not au._dica_inst().visible, "f6d_balao_hall", "o balão deveria sumir ao tirar o mouse")
			au._dica_inst().ancora_fixa = Vector2(-1, -1)
	# --- Números do treino por atributo ---
	if au._quer("f6d_numeros_bjj") or au._quer("f6d_numeros_bjj_critico") or au._quer("f6d_numeros_pera"):
		for q in [["f6d_numeros_bjj", "bjj", "grappling_dummy", false], ["f6d_numeros_bjj_critico", "bjj", "grappling_dummy", true],
				["f6d_numeros_pera", "boxing", "speed_bag", false]]:
			if not au._quer(q[0]):
				continue
			au._novo_jogo()
			au._academia(q[1], ["treadmill", "jump_rope", q[2]], 3000.0, q[2])
			au.gs.dados.crit_chance = 1.0 if q[3] else 0.0
			au.gs.dados.base_training = 100.0  # ganho alto: as 3 fatias aparecem com valor na tela
			await au._abrir()
			await au._esperar(0.3)
			var sala: Node = au._cena.get_node("Sala")
			var esperado: Array = sala.ganhos_por_atributo(100.0, q[2])
			au._exigir(esperado.size() == 3, q[0], "o aparelho treina 3 atributos (%d)" % esperado.size())
			au.gs.clicar()
			await au._esperar(0.12)
			var vivos := _numeros_vivos(sala)
			au._exigir(vivos.size() == esperado.size(), q[0], "um número por atributo que subiu: %d números para %d atributos" % [vivos.size(), esperado.size()])
			au._exigir(vivos.size() <= 3, q[0], "no máximo 3 números por clique")
			# 6d3: nome completo do atributo (nada de FOR/AGI/RES), e o número cabe na sala sem passar da borda
			var nomes: Array = []
			for a in esperado:
				nomes.append(str(au.gs.dados.atributo_info(a.atributo).get("name", a.atributo)).to_upper())
			for v in vivos:
				var achou := false
				for nm in nomes:
					achou = achou or str(v.texto).contains(" " + str(nm))
				au._exigir(achou, q[0], "o número leva o nome completo do atributo: '%s'" % v.texto)
				au._exigir((v.ret as Rect2).position.x >= 0.0 and (v.ret as Rect2).end.x <= 640.0, q[0], "o número cabe na sala: %s" % str((v.ret as Rect2)))
			var cores := {}
			for v in vivos:
				cores[str(v.cor)] = true
			au._exigir(cores.size() >= (2 if q[3] else 3), q[0], "cada atributo tem a sua cor (%d cores)" % cores.size())
			var maior_escala := 0.0
			var menor_escala := 99.0
			for v in vivos:
				maior_escala = maxf(maior_escala, float(v.escala))
				menor_escala = minf(menor_escala, float(v.escala))
			au._exigir(maior_escala == (2.0 if q[3] else 1.0) and menor_escala == 1.0, q[0], "P1a: só o crítico é grande (maior %.1fx, menor %.1fx)" % [maior_escala, menor_escala])
			await au._ver(q[0])
			au.gs.dados.crit_chance = 0.0
	if au._quer("f6d_numeros_um_atributo"):
		au._novo_jogo()
		au.gs.dados.crit_chance = 0.0
		await au._abrir()
		await au._esperar(0.3)
		var sala1: Node = au._cena.get_node("Sala")
		au.gs.clicar()
		await au._esperar(0.12)
		var v1 := _numeros_vivos(sala1)
		au._exigir(v1.size() == 1 and float(v1[0].escala) == 1.0, "f6d_numeros_um_atributo", "aparelho de um atributo: 1 número normal (%d)" % v1.size())
		au._exigir(str(v1[0].texto).ends_with("FORÇA"), "f6d_numeros_um_atributo", "nome completo: '%s'" % v1[0].texto)
		await au._ver("f6d_numeros_um_atributo")
		# 6d3: o crítico também leva o nome inteiro e cabe na sala
		au.gs.dados.crit_chance = 1.0
		await au._esperar(1.0)
		au.gs.clicar()
		await au._esperar(0.12)
		var vc := _numeros_vivos(sala1)
		var tem_crit := false
		for v in vc:
			if str(v.texto).ends_with("FORÇA!"):
				tem_crit = true
				au._exigir((v.ret as Rect2).position.x >= 0.0 and (v.ret as Rect2).end.x <= 640.0, "f6d_numeros_um_atributo", "o crítico cabe na sala: %s" % str((v.ret as Rect2)))
		au._exigir(tem_crit, "f6d_numeros_um_atributo", "crítico com o nome completo (+N FORÇA!)")
		au.gs.dados.crit_chance = 0.0
