extends "res://tests/test_base.gd"
## Fase 8a2 (centro de treinamento): mudança (custo, requisito, reserva), multiplicador, Alunos da Raízes, 5ª melhoria, patrocínio,
## região CENTRO da árvore, falas do Osmar, save antigo/sujo e "nada muda até o 1º Cinturão do Vale". Referência: tools/sim/fase8a2_sim.py
## e docs/fases/fase8a2-design.md. Casos exatos: tests/data/fase8a2_casos.json. Tudo em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")
const CASOS := "res://tests/data/fase8a2_casos.json"

var casos: Dictionary


func rodar_testes() -> void:
	casos = JSON.parse_string(ler(CASOS))
	_teste_dados_e_casos()
	_teste_mudanca_e_reserva()
	_teste_chegada()
	_teste_alunos()
	_teste_melhoria_5()
	_teste_patrocinio()
	_teste_arvore()
	_teste_saves()
	_teste_nada_muda_antes_do_vale()
	_teste_dialogos()
	_teste_fala_unica_do_centro()
	_teste_oferta_so_depois_da_campanha_do_vale()


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.rng.seed = 4242
	gs.pular_abertura()
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	gs.escolher_arte("boxing", 1)
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


## Campanha completa na academia (depois do James), pronta para o MUDAR do centro.
func _no_vale(gs: Node, dinheiro: float = 25000.0) -> void:
	gs.indice_escada = gs.lutas.adversarios.size()
	gs.cinturao = true
	gs.local_id = "gym"
	gs.permanente["regional_belts"] = 1
	gs.permanente["first_regional_belt_campaign"] = gs.numero_carreira()
	gs.dinheiro = dinheiro
	gs.fight_day = -1


func _teste_dados_e_casos() -> void:
	var gs := _novo("f8a2_dados")
	checar(gs.centro.ativo and gs.centro.local == "center", "center.json lido")
	checar_igual(gs.academia.destino_mudanca("garage").id, "gym", "destino da garagem = academia")
	checar_igual(gs.academia.destino_mudanca("gym").id, "center", "destino da academia = centro")
	checar(gs.academia.destino_mudanca("center").is_empty(), "do centro nao ha destino")
	checar_igual(str(gs.academia.local("center").move.requires), "regional_belt", "centro pede o cinturao do Vale")
	checar_igual(gs.academia.local("center").move.cost, float(casos.move.cost), "custo da mudanca (casos)")
	checar_igual(gs.academia.local("center").training_mult, float(casos.move.training_mult), "multiplicador x4 (casos)")
	var al: Dictionary = gs.centro.gerador("center_students")
	var ok := true
	for n in casos.custo_aluno.size():
		ok = ok and Economia.custo_gerador(al.base_cost, al.growth, n) == float(casos.custo_aluno[n])
	checar(ok, "custo dos alunos 0..%d bate com os casos" % (casos.custo_aluno.size() - 1))
	checar_igual(al.production, 500.0, "aluno produz 500")
	# multiplicador do centro com 0 / 0,25 / 0,5 de bonus (Ventilador e Piso de borracha valem no centro)
	gs.local_id = "center"
	ok = true
	for par in casos.mult_centro:
		gs._bonus["gym_training_bonus"] = float(par[0])
		ok = ok and absf(gs.mult_local() - float(par[1])) < 1.0e-9
	checar(ok, "mult do centro com 0/0,25/0,5 de bonus (casos)")
	gs._bonus["gym_training_bonus"] = 0.0
	# nos
	for id in casos.nos:
		checar_igual(gs.lutas.no_da_arvore(str(id)).get("cost", -1), int(casos.nos[id]), "custo do no %s" % id)
	_liberar(gs)


func _teste_mudanca_e_reserva() -> void:
	var gs := _novo("f8a2_mudanca")
	# academia com o cinturao amador e SEM o do Vale: botao trancado e reserva 0 (o jogo continua o da 8a1)
	gs.local_id = "gym"
	gs.cinturao = true
	gs.indice_escada = 7
	gs.dinheiro = 100000.0
	checar_igual(gs.estado_mudanca(), "locked", "sem o cinturao do Vale o MUDAR do centro nao aparece")
	checar_igual(gs.reserva_mudanca(), 0.0, "reserva da LOJA = 0 antes do James")
	checar_igual(gs.loja_estado(99000.0), "ok", "LOJA gasta livremente antes do James")
	checar(not gs.pode_mudar() and not gs.mudar(), "mudar() recusa sem o cinturao")
	# garagem: segue como antes (academia por $1.000 com o cinturao amador)
	gs.local_id = "garage"
	gs.indice_escada = 4
	checar_igual(gs.mudanca().get("location", ""), "gym", "garagem: o destino segue sendo a academia")
	checar_igual(gs.reserva_mudanca(), 1000.0, "garagem com cinturao: reserva de $1.000 como na 8a1")
	# depois do James
	gs.local_id = "gym"
	_no_vale(gs, 24999.0)
	checar_igual(gs.estado_mudanca(), "missing", "com o cinturao e sem $25.000: apagado")
	checar_igual(gs.reserva_mudanca(), 25000.0, "depois do James a LOJA reserva $25.000")
	gs.dinheiro = 25050.0
	checar_igual(gs.loja_estado(100.0), "reserve", "compra que deixaria menos de $25.000: reserva")
	gs.dinheiro = 25100.0
	checar_igual(gs.loja_estado(100.0), "ok", "compra que deixa exatamente $25.000: ok")
	var m: Dictionary = gs.mudanca()
	checar(m.location == "center" and m.cost == 25000.0 and m.mult == 4.0, "cartao da mudanca: centro, 25.000, x4")
	checar(str(m.title) != "" and str(m.title) != str(gs.texto_ui("move_title")), "cartao usa move_title_center")
	checar(str(m.no_fights_text) != "" and str(m.arrived_text) != "" and str(m.hud_next_text) != "", "textos do centro no cartao")
	gs.dinheiro = 25000.0
	checar_igual(gs.estado_mudanca(), "ready", "com os dois: pronto")
	checar(gs.mudar(), "mudar() leva ao centro")
	checar(gs.local_id == "center" and gs.dinheiro == 0.0, "no centro e sem o dinheiro")
	checar(gs.mudanca().is_empty() and gs.estado_mudanca() == "none", "no centro nao ha mudanca")
	checar_igual(gs.reserva_mudanca(), 0.0, "no centro nao ha reserva")
	checar(gs.no_centro() and gs.em_academia(), "no_centro()/em_academia()")
	checar_igual(gs.mult_local(), 4.0, "treino x4 no centro")
	_liberar(gs)


func _teste_chegada() -> void:
	var gs := _novo("f8a2_chegada")
	_no_vale(gs)
	gs.geradores["neighbor_kid"] = 7
	gs.niveis_melhoria["punching_bag"] = 2
	gs.treino = 123456.0
	gs.mudar()
	checar(gs.marco("center_arrival"), "marco center_arrival gravado")
	checar(bool(gs.permanente.get("center_reached", false)), "permanent.center_reached ligado na 1a mudanca")
	checar(gs._gatilhos_quadro.any(func(g: Dictionary) -> bool: return g.id == "center_arrival"), "gatilho center_arrival disparado")
	checar(gs.cena_sala == "", "o centro nao toca cena")
	checar(gs.geradores["neighbor_kid"] == 7 and gs.niveis_melhoria["punching_bag"] == 2 and gs.treino == 123456.0, "mudar nunca tira nada")
	var salvo: Dictionary = gs.para_save()
	checar(salvo.career.location == "center" and salvo.permanent.center_reached == true, "o save leva o centro e center_reached")
	# a fala do Osmar: 1a = unica; depois as que se revezam
	var d: DialogosData = gs.dialogos
	checar(d.erros.is_empty(), "dialogos validam sem erros: %s" % str(d.erros))
	checar(not d.linha("cl_primeiro_centro").is_empty() and not d.linha("cl_centro_volta_1").is_empty(), "falas do centro existem")
	checar(gs.sufixo_aparelhos() == "_center", "sufixo dos aparelhos no centro")
	_liberar(gs)


func _teste_alunos() -> void:
	var gs := _novo("f8a2_alunos")
	_no_vale(gs)
	gs.treino = 1.0e12
	checar(not gs.pode_comprar_gerador("center_students") and not gs.comprar_gerador("center_students"), "na academia nao compra aluno")
	checar(gs.geradores_do_local().all(func(g: Dictionary) -> bool: return g.id != "center_students"), "aba EQUIPE da academia sem alunos")
	gs.mudar()
	checar(gs.geradores_do_local().any(func(g: Dictionary) -> bool: return g.id == "center_students"), "aba EQUIPE do centro tem os alunos")
	var antes: float = gs.producao_total()
	checar_igual(gs.custo_gerador("center_students"), 2000000.0, "1o aluno custa 2M")
	var t0: float = gs.treino
	checar(gs.comprar_gerador("center_students"), "compra o 1o aluno")
	checar_igual(t0 - gs.treino, 2000000.0, "gastou 2M de Treino")
	checar_igual(gs.custo_gerador("center_students"), 2500000.0, "2o aluno custa 2,5M")
	var esperado: float = 500.0 * gs._loja._fator_equipe()
	checar(absf((gs.producao_total() - antes) - esperado) < 1.0e-6 * esperado, "1 aluno = 500 x fator da equipe (x4 do centro)")
	checar_igual(gs.pessoas_desenhadas("center_students"), 1, "1 pessoa desenhada")
	gs.geradores["center_students"] = 25
	checar_igual(gs.pessoas_desenhadas("center_students"), 4, "25 alunos = 4 pessoas")
	# o save leva a quantidade; fora do centro ela nao produz
	var estado: Dictionary = gs.para_save()
	checar_igual(int(estado.career.generators.center_students), 25, "save: alunos")
	gs.aplicar_save(estado)
	checar_igual(gs.quantidade_gerador("center_students"), 25, "carga: alunos voltam")
	_liberar(gs)


func _teste_melhoria_5() -> void:
	var gs := _novo("f8a2_melhoria")
	_no_vale(gs)
	var ids := {"punching_bag": "bag_center", "treadmill": "treadmill_center", "jump_rope": "rope_center"}
	checar_igual(gs.melhorias_do_aparelho("punching_bag").size(), 4, "academia: 4 melhorias")
	gs.niveis_melhoria["punching_bag"] = 4
	checar(gs.proxima_melhoria("punching_bag").is_empty(), "academia: linha completa depois da 4a (sem aviso da 5a)")
	gs.mudar()
	checar_igual(gs.melhorias_do_aparelho("punching_bag").size(), 5, "centro: 5 melhorias")
	var m: Dictionary = gs.proxima_melhoria("punching_bag")
	checar(str(m.id) == "bag_center" and float(m.cost) == 150000000.0 and float(m.multiplier) == 3.0, "5a do saco: 150M, x3")
	var mult4: float = gs.multiplicador_aparelho("punching_bag")
	gs.treino = 1.0e12
	checar(gs.comprar_melhoria("punching_bag"), "compra a 5a")
	checar_igual(gs.multiplicador_aparelho("punching_bag"), mult4 * 3.0, "x3 a mais no aparelho")
	checar(gs.proxima_melhoria("punching_bag").is_empty(), "depois da 5a a linha acabou")
	var nao_ok := false
	for ap in gs.dados.todos_aparelhos():
		if ap.id in ids or ap.art != "":
			continue
	checar(not nao_ok, "aparelhos de sempre ok")
	# melhoria de arte (pera do Boxe): 250M
	var pera: Dictionary = gs.centro.melhorias_do("speed_bag")[0]
	checar(float(pera.cost) == 250000000.0, "5a da pera: 250M")
	# nivel 5 fora do centro volta a 4 com aviso
	var estado: Dictionary = gs.para_save()
	estado.career.location = "gym"
	gs.aplicar_save(estado)
	checar_igual(gs.niveis_melhoria["punching_bag"], 4, "save sujo: nivel 5 fora do centro volta a 4")
	checar(gs.avisos.any(func(a: String) -> bool: return a.contains("centro")), "aviso do nivel 5 fora do centro")
	_liberar(gs)


func _teste_patrocinio() -> void:
	var gs := _novo("f8a2_patro")
	gs.permanente["regional_belts"] = 0
	checar(gs.patrocinio().is_empty(), "sem Cinturao do Vale na linhagem: sem patrocinio")
	gs.permanente["regional_belts"] = 1
	gs.fama = 199
	checar(not gs._centro.avaliar_oferta() and gs.patrocinio().state == "", "fama 199: sem oferta")
	gs.fama = 200
	checar(gs._centro.avaliar_oferta() and gs.patrocinio().state == "offered", "fama 200: envelope")
	checar(gs.patrocinio().short_name == "VALE FORTE" and gs.patrocinio().bonus_line.contains("VALE FORTE"), "marca curta na linha da vitoria")
	for id in casos.patrocinio:
		gs.patrocinio_estado = "signed"
		checar_igual(gs._centro.bonus_vitoria(gs.lutas.adversario(str(id))), int(casos.patrocinio[id]), "bonus do patrocinio %s" % id)
	gs.patrocinio_estado = "offered"
	checar_igual(gs._centro.bonus_vitoria(gs.lutas.adversario("opp_james")), 0, "envelope nao assinado nao paga")
	checar(gs.assinar_patrocinio() and gs.patrocinio_estado == "signed", "ASSINAR")
	checar(not gs.assinar_patrocinio(), "assinar de novo nao faz nada")
	checar_igual(gs.para_save().career.sponsor, "signed", "save: sponsor signed")
	# nova carreira zera (1 por campanha)
	gs._carreira._zerar_carreira()
	checar_igual(gs.patrocinio_estado, "", "nova campanha: patrocinio volta a vazio")
	_liberar(gs)
	# fluxo real de vitorias: a vitoria que oferece nao paga; depois de assinar, paga
	var g2 := _novo("f8a2_patro2")
	g2.permanente["regional_belts"] = 1
	g2.indice_escada = 4
	g2.local_id = "gym"
	g2.cinturao = true
	g2.fama = 150
	g2.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	var din0: float = g2.dinheiro
	g2.fight_day = 1
	g2.segundos_campanha = 1.0e9
	g2.lutar()
	var r1: Dictionary = g2.concluir_luta()
	checar(bool(r1.win) and g2.patrocinio_estado == "offered" and not r1.has("sponsor_money"), "a vitoria que passa de 200 de fama oferece, sem pagar")
	checar_igual(g2.dinheiro - din0, float(r1.money), "dinheiro = so o premio")
	g2.assinar_patrocinio()
	g2.fight_day = 1
	g2.segundos_campanha = 1.0e9
	var opp: Dictionary = g2.proximo_adversario()
	var din1: float = g2.dinheiro
	g2.lutar()
	var r2: Dictionary = g2.concluir_luta()
	var b: int = int(floor(float(opp.prize_money) * 0.5 + 0.5))
	checar(bool(r2.win) and int(r2.sponsor_money) == b, "vitoria assinada traz sponsor_money = %d" % b)
	checar(absf((g2.dinheiro - din1) - (float(r2.money) + b)) < 1.0e-6, "o dinheiro soma premio + bonus")
	_liberar(g2)
	# ignorar = o mesmo save, campo a campo (menos o proprio campo sponsor), depois de uma campanha roteirizada
	var sa := _campanha_roteirizada("f8a2_ign_a", false)
	var sb := _campanha_roteirizada("f8a2_ign_b", true)
	sb.career.erase("sponsor")
	sa.career.erase("sponsor")
	for s in [sa, sb]:
		s.career.erase("play_seconds")
	checar(JSON.stringify(sa) == JSON.stringify(sb), "patrocinio ignorado = o mesmo jogo, campo a campo")


func _campanha_roteirizada(nome: String, com_patrocinio: bool) -> Dictionary:
	var gs := _novo(nome)
	gs.permanente["regional_belts"] = 1
	if not com_patrocinio:
		gs.centro.patrocinio = {}
	gs.indice_escada = 5
	gs.local_id = "gym"
	gs.cinturao = true
	gs.fama = 100
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	for i in 5:
		gs.fight_day = 1
		gs.segundos_campanha = 1.0e9
		if gs.proximo_adversario().is_empty():
			break
		gs.lutar()
		gs.concluir_luta()
	var r := {}
	r["state"] = gs.para_save()
	var offered: bool = gs.patrocinio_estado == "offered"
	r["state"].career["_oferta"] = offered
	if com_patrocinio:
		checar(offered, "a campanha roteirizada recebeu o envelope")
	var estado: Dictionary = r.state
	estado.career.erase("_oferta")
	_liberar(gs)
	return estado


func _teste_arvore() -> void:
	var gs := _novo("f8a2_arvore")
	gs.permanente["legacy_total"] = 30000
	checar_igual(gs.estado_mapa("ctr_door"), "hidden", "regiao CENTRO escondida antes da 1a mudanca")
	checar(not gs.arvore_mapa_info().regions.filter(func(r: Dictionary) -> bool: return r.id == "center")[0].open, "regiao CENTRO fechada")
	gs.permanente["center_reached"] = true
	checar_igual(gs.estado_mapa("ctr_door"), "visible", "com center_reached a raiz aparece")
	checar_igual(gs.estado_mapa("ctr_schedule"), "hidden", "os outros esperam a raiz")
	gs.permanente["legacy_total"] = 22000
	checar(gs.comprar_no("ctr_door") and gs.comprar_no("ctr_schedule") and gs.comprar_no("ctr_floor"), "compra os 3 nos (5.000 + 7.000 + 10.000)")
	checar_igual(int(gs.permanente.legacy_total), 0, "gastou 22.000")
	var b: Dictionary = gs._arvore.bonus_de(["ctr_door", "ctr_schedule", "ctr_floor"])
	checar(b.click_bonus == 0.5 and b.prep_days_bonus == 1.0 and b.gym_training_bonus == 0.25, "efeitos: clique +50%, +1 dia, piso +25%")
	# o mapa de 8a1 nao mudou: nos antigos com os mesmos ids e custos
	checar_igual(gs.lutas.no_da_arvore("gym_fan").cost, 700, "no antigo intacto")
	_liberar(gs)


func _teste_saves() -> void:
	var gs := _novo("f8a2_saves")
	var base: Dictionary = gs.para_save()
	# center sem o cinturao do Vale volta para a academia
	var e: Dictionary = base.duplicate(true)
	e.career.location = "center"
	e.career.ladder_index = 6
	e.career.generators["center_students"] = 5
	gs.aplicar_save(e)
	checar_igual(gs.local_id, "gym", "save no centro sem cinturao: volta para a academia")
	checar(gs.quantidade_gerador("center_students") == 0, "alunos zerados")
	checar(gs.avisos.any(func(a: String) -> bool: return a.contains("centro")), "aviso do centro sem cinturao")
	# alunos fora do centro = 0
	e = base.duplicate(true)
	e.career.location = "gym"
	e.career.generators["center_students"] = 9
	gs.aplicar_save(e)
	checar_igual(gs.quantidade_gerador("center_students"), 0, "alunos fora do centro = 0")
	# patrocinio sem cinturao na linhagem
	e = base.duplicate(true)
	e.career["sponsor"] = "signed"
	gs.aplicar_save(e)
	checar_igual(gs.patrocinio_estado, "", "sponsor signed sem cinturao do Vale = vazio")
	e = base.duplicate(true)
	e.career["sponsor"] = "lixo"
	gs.aplicar_save(e)
	checar_igual(gs.patrocinio_estado, "", "sponsor ruim = vazio")
	# no ctr_* sem center_reached liga o campo
	e = base.duplicate(true)
	e.permanent["skill_nodes"] = ["ctr_door"]
	e.career.erase("active_nodes")
	gs.aplicar_save(e)
	checar(bool(gs.permanente.get("center_reached", false)), "no ctr_door sem center_reached: liga o campo")
	# save sem os campos novos nao os grava
	e = base.duplicate(true)
	gs.aplicar_save(e)
	var s2: Dictionary = gs.para_save()
	checar(not s2.career.has("sponsor") and not s2.permanent.has("center_reached"), "campos opcionais so gravam quando usados")
	checar(not s2.career.generators.has("center_students"), "alunos so gravam quando comprados")
	# save antigo da 8a1 parado depois do James (academia, campanha completa): MUDAR disponivel; sem dinheiro, apagado
	e = base.duplicate(true)
	e.career.location = "gym"
	e.career.ladder_index = 10
	e.career.belt = true
	e.career.money = 40000.0
	e.career.fight_day = -1
	e.permanent["regional_belts"] = 1
	e.permanent["first_regional_belt_campaign"] = 1
	gs.aplicar_save(e)
	checar_igual(gs.estado_mudanca(), "ready", "save antigo parado depois do James: MUDAR do centro pronto")
	e.career.money = 3000.0
	gs.aplicar_save(e)
	checar_igual(gs.estado_mudanca(), "missing", "sem $25.000: apagado nesta campanha (D11)")
	_liberar(gs)


func _teste_nada_muda_antes_do_vale() -> void:
	var gs := _novo("f8a2_ident")
	var off := _novo("f8a2_ident_off")
	off.centro = CentroData.new()  # sem center.json: o jogo da 8a1
	for g in [gs, off]:
		g.indice_escada = 5
		g.local_id = "gym"
		g.cinturao = true
		g.fama = 150
		g.dinheiro = 99999.0
		g.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	for i in 4:  # Kid + liga ate o Sabao: nenhum Cinturao do Vale
		for g in [gs, off]:
			g.fight_day = 1
			g.segundos_campanha = 1.0e9
			g.lutar()
			g.concluir_luta()
	checar(gs.fama >= 200 and gs.patrocinio_estado == "" and gs.patrocinio().is_empty(), "fama >= 200 sem cinturao do Vale: nada de envelope")
	checar_igual(gs.reserva_mudanca(), 0.0, "reserva 0 ate o James")
	var a: Dictionary = gs.para_save()
	var b: Dictionary = off.para_save()
	for s in [a, b]:
		s.career.erase("play_seconds")
	checar(JSON.stringify(a) == JSON.stringify(b), "ate o James o save e igual ao do jogo sem o centro")
	checar(gs.estado_mudanca() == "locked" and gs.mudanca().state == "locked", "academia: MUDAR trancado")
	var escondidos := true
	for n in gs.arvore_mapa():
		if str(n.region) == "center":
			escondidos = escondidos and n.state == "hidden"
	checar(escondidos, "nos do CENTRO escondidos")
	_liberar(gs)
	_liberar(off)


func _teste_dialogos() -> void:
	var d := DialogosData.carregar()
	checar(d.erros.is_empty(), "DialogosData.carregar() sem erros: %s" % str(d.erros))
	checar(not d.gatilho("center_arrival").is_empty(), "gatilho center_arrival existe")
	for chave in ["old_photo_center", "regional_poster_won", "regional_poster_sponsor", "regional_clipping"]:
		checar(d.texto_objeto(chave) != "", "objeto %s tem texto" % chave)
	var gs := _novo("f8a2_recorte")
	checar(gs.recorte_do_vale().is_empty(), "antes do 1o Cinturao do Vale nao ha recorte")
	gs.permanente["first_regional_belt_campaign"] = gs.numero_carreira()
	var r: Dictionary = gs.recorte_do_vale()
	checar(not r.is_empty() and str(r.name) != "" and r.poster.text.contains(str(r.name).to_upper()), "recorte do Vale: cartaz com o nome do discipulo")
	checar(r.poster.sponsor_line == "" and r.brand == "", "sem contrato: sem marca no cartaz")
	gs.permanente["regional_belts"] = 1
	gs.patrocinio_estado = "signed"
	r = gs.recorte_do_vale()
	checar(r.poster.sponsor_line.contains("VALE FORTE") and r.brand == "sponsor_vale", "com contrato: marca no cartaz")
	checar(r.clipping.title != "" and r.clipping.footer != "", "recorte emoldurado tem titulo e rodape")
	_liberar(gs)


## B1 da QA: a fala unica de chegada nao pode ser engolida pelo intervalo de 60 s depois da fala do cinturao (prioridade 9).
func _teste_fala_unica_do_centro() -> void:
	for espera in [3.0, 30.0]:
		var gs := _novo("f8a2_fala_%d" % int(espera))
		gs.local_id = "gym"
		gs.cinturao = true
		gs._escola._gravar_marco(gs._casa._marco_da_chegada(), {}, false)
		gs._academia_rearmada = true
		for l in gs.dialogos.linhas:
			var id := str(l.id)
			if id.begins_with("cl_arte") or id == "cl_primeira_academia" or id == "cl_liga_regional":
				gs.escola["lines_seen"][id] = gs.numero_carreira()
		gs.indice_escada = 6
		gs.atributos = {"strength": 1.0e14, "agility": 1.0e14, "endurance": 1.0e14}
		var falas: Array = []
		gs.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: falas.append(id))
		for i in 4:
			gs.fight_day = gs.dia_campanha()
			gs.segundos_campanha = 1.0e9
			gs.lutar()
			gs.concluir_luta()
			for j in 50:
				gs.tick(0.1)
		for i in int(espera * 10.0):
			gs.tick(0.1)
		gs.dinheiro = maxf(gs.dinheiro, 25000.0)
		gs.mudar()
		for i in 1500:
			gs.tick(0.1)
		checar(falas.count("cl_primeiro_centro") == 1, "mudando %.0f s depois do cinturao a fala unica do centro toca (%s)" % [espera, str(falas)])
		_liberar(gs)


## Revisão do Diretor: o envelope não aparece na campanha do 1º Cinturão do Vale (nem ao recarregar), só nas seguintes.
func _teste_oferta_so_depois_da_campanha_do_vale() -> void:
	var gs := _novo("f8a2_oferta_camp")
	_no_vale(gs)  # first_regional_belt_campaign = campanha atual
	gs.fama = 500
	checar(not gs._centro.avaliar_oferta() and gs.patrocinio_estado == "", "na campanha do cinturao: sem oferta")
	var estado: Dictionary = gs.para_save()
	gs.aplicar_save(estado)
	checar_igual(gs.patrocinio_estado, "", "recarregar o save da campanha do cinturao: sem oferta")
	gs.permanente["career_number"] = 2
	gs.permanente["first_regional_belt_campaign"] = 1
	checar(gs._centro.avaliar_oferta() and gs.patrocinio_estado == "offered", "campanha seguinte: oferta")
	_liberar(gs)
