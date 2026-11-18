extends "res://tests/test_base.gd"
## Fase 6c1 (Casa nova): RASCUNHO NAO RODADO. Cena da 1a chegada a academia (uma vez so, relogio parado, fechar no meio),
## Osmar, foto e mentores por local, saida do John (dois caminhos, interrupcoes, fechar no meio) e balanco inalterado.
## Destino: E:\Fightclicker\tests\test_fase6c1.gd. Tudo em pastas de user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")

const CENA_ACADEMIA := "cena_primeira_academia"
const CENA_SAIDA := "cena_saida_primeiro_mentor"
const VITORIA := "disciple_gym_win"


func _novo(nome: String, pasta: String = "") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta if pasta != "" else pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _tickar(gs: Node, segundos: float, passo: float = 0.1) -> void:
	for i in int(round(segundos / passo)):
		gs.tick(passo)


func _passar_o_posto(gs: Node) -> void:
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()


# Discipulo jogando na Carreira `carreira` (2 = so o John no roster), John sentado na garagem.
func _com_mentor(nome: String, carreira: int = 2) -> Node:
	var gs := _novo(nome)
	while gs.numero_carreira() < carreira:
		_passar_o_posto(gs)
	_tickar(gs, 0.5)
	return gs


func _vencer(gs: Node) -> Dictionary:
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	gs.lutar()
	return gs.concluir_luta()


func _chegar(g: Node) -> bool:
	g.cinturao = true
	g.dinheiro = 1.0e9
	return g.mudar()


# O que a interface faz depois da cena: devolve o relogio e escolhe a arte.
func _assentar(g: Node) -> void:
	g.cena_sala_terminou()
	if g.escolha_arte_pendente():
		g.escolher_arte(g.academia.ids_artes()[0])


func _espiar_saida(g: Node) -> Dictionary:
	var v := {"pedidos": 0, "interrompidas": 0}
	g.saida_mentor_pedida.connect(func() -> void: v.pedidos += 1)
	g.saida_mentor_interrompida.connect(func() -> void: v.interrompidas += 1)
	return v


# Discipulo na Carreira `carreira`, na garagem, com a saida devida (marco da vitoria).
func _saida_devida(nome: String, carreira: int = 2) -> Node:
	var g := _com_mentor(nome, carreira)
	g._gravar_marco(VITORIA, {"opponent": "x"}, false)
	return g


func _ids_falas(g: Node) -> Array:
	var ids: Array = []
	g.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: ids.append(id))
	return ids


func rodar_testes() -> void:
	_teste_dados()
	_teste_validador()
	_teste_cena_academia()
	_teste_cena_academia_save()
	_teste_save_antigo()
	_teste_cena_no_player()
	_teste_elenco()
	_teste_osmar_e_foto()
	_teste_mentores_por_local()
	_teste_saida_por_vitoria()
	_teste_saida_pela_reserva()
	_teste_saida_interrupcoes()
	_teste_saida_fechar_no_meio()
	_teste_depois_da_saida()
	_teste_comentario_da_arte()
	_teste_balanco()
	_teste_sons()


func _teste_dados() -> void:
	var gs := _novo("f6c1_dados")
	checar_igual(SaveStore.VERSAO_ATUAL, 13, "save continua v12 (sem migracao nova)")
	checar(not gs.escola_cfg.is_empty(), "data/escola.json carregado")
	checar_igual(str(gs.escola_cfg.gym_arrival.milestone), CENA_ACADEMIA, "marco da cena da academia")
	checar_igual(float(gs.escola_cfg.gym_arrival.max_locked_seconds), 15.0, "teto de 15 s da cena da academia")
	checar_igual(int(gs.escola_cfg.mentor_leave.reserve_campaign_offset), 3, "reserva da saida: F + 3")
	checar_igual(gs.disciples.toques.get("locations", []), ["garage", "gym"], "toques do John valem na garagem e na academia")
	checar(gs.disciples.mentores_cfg.spots_by_location.has("gym"), "pontos da academia nos dados dos mentores")
	checar(not gs.marco(CENA_ACADEMIA) and not gs.marco(CENA_SAIDA) and not gs.marco(VITORIA), "save novo: nenhum marco da 6c1")
	_liberar(gs)


func _teste_validador() -> void:
	var v := CenaValidador.novo()
	for id in ["primeira_academia", "saida_primeiro_mentor"]:
		var r := v.validar_id(id)
		checar_igual(r.erros, [], "cena %s: 0 erros do validador" % id)
	var a := v.validar_id("primeira_academia")
	checar(a.tempo_preso <= 15.0 + 1.0e-6, "primeira_academia: tempo preso %.2f s <= 15 s" % a.tempo_preso)
	checar_igual(a.pendencias, [], "primeira_academia: 0 pendências (papéis conferidos contra John, discípulo e fallback)")
	var s := v.validar_id("saida_primeiro_mentor")
	checar(s.tempo_preso <= 1.0e-6, "saida_primeiro_mentor: 0 s presos")
	checar_igual(s.pendencias, [], "saida_primeiro_mentor: 0 pendências")
	var dd := CenaDados.novo()
	checar_igual([dd.folha_da_pose("first_fighter", "stand").get("sprite", ""), dd.folha_da_pose("current_player", "stand").get("sprite", ""), dd.folha_da_pose("helper_2", "stand").get("sprite", "")], ["john_sit_rest", "disciple_sit_rest", "helper_stand"], "stand: mentor vai direto para sentado, vizinho fica em pé")


func _teste_cena_academia() -> void:
	var g := _novo("f6c1_cena")  # campanha do John
	var pedidos: Array = []
	var arte_pedida := [0]
	g.cena_sala_pedida.connect(func(id: String) -> void: pedidos.append(id))
	g.escolha_arte_pedida.connect(func(_a: bool) -> void: arte_pedida[0] += 1)
	_tickar(g, 5.0)
	checar(_chegar(g), "MUDAR para a academia")
	checar_igual(g.cena_sala, "primeira_academia", "a chegada poe o estado cena_sala")
	checar(g.marco(CENA_ACADEMIA), "marco gravado na mudanca")
	checar_igual(pedidos, ["primeira_academia"], "sinal cena_sala_pedida emitido uma vez")
	checar_igual(arte_pedida[0], 0, "a escolha da arte nao abre durante a cena")
	checar(not g.escolha_arte_pendente() and not g.sala_ativa() and g.acoes_bloqueadas(), "cena: sem sala ativa, sem arte pendente, acoes bloqueadas")
	var antes := [g.tempo_jogo, g.segundos_campanha, g.dinheiro, g.treino, g.arte_segundos]
	_tickar(g, 6.0)
	g.clicar()
	checar_igual([g.tempo_jogo, g.segundos_campanha, g.dinheiro, g.treino, g.arte_segundos], antes, "relogio, treino e ouro parados durante a cena (clique nao vale)")
	g.cena_sala_terminou()
	checar_igual(g.cena_sala, "", "fim da cena devolve o estado")
	checar_igual(arte_pedida[0], 1, "a escolha da arte abre depois da cena")
	checar(g.escolha_arte_pendente(), "arte pendente depois da cena")
	g.cena_sala_terminou()
	checar_igual(arte_pedida[0], 1, "terminar de novo nao faz nada")
	g.escolher_arte(g.academia.ids_artes()[0])
	_tickar(g, 2.0)
	checar(g.sala_ativa() and g.arte_segundos > antes[4], "relogio volta depois da cena e da arte")
	g.aposentar()
	g.nova_carreira()
	if g.escolha_arte_pendente():
		g.escolher_arte(g.academia.ids_artes()[0])
	checar(_chegar(g), "MUDAR de novo (campanha seguinte)")
	checar(g.cena_sala == "" and pedidos.size() == 1, "chegada seguinte: sem cena (uma vez so)")
	_liberar(g)
	var t := _novo("f6c1_cena_trava")
	_chegar(t)
	_tickar(t, 31.0, 0.5)
	checar_igual(t.cena_sala, "", "trava de seguranca solta o relogio (30 s sem aviso)")
	_liberar(t)


func _teste_cena_academia_save() -> void:
	var g := _novo("f6c1_meio")
	_chegar(g)
	g.salvar()
	var pasta: String = g.store.pasta
	var g2 := _novo("f6c1_meio", pasta)
	var pedidos: Array = []
	g2.cena_sala_pedida.connect(func(id: String) -> void: pedidos.append(id))
	var falas := _ids_falas(g2)
	checar(g2.marco(CENA_ACADEMIA) and g2.local_id == "gym", "save no meio da cena: marco e academia")
	checar_igual(g2.cena_sala, "", "ao abrir, a cena nao volta a tocar")
	checar(pedidos.is_empty(), "nenhum cena_sala_pedida na carga")
	checar(g2.escolha_arte_pendente(), "a janela da arte abre como hoje na carga (arte pendente)")
	checar(g2.coach_presente() and not g2.foto_antiga().is_empty(), "academia no estado final: Osmar e foto")
	g2.escolher_arte(g2.academia.ids_artes()[0])
	_tickar(g2, 4.0)
	checar_igual(falas, ["cl_primeira_academia"], "rearme: a cl_primeira_academia volta depois de fechar o jogo no meio")
	_tickar(g2, 200.0, 0.5)
	checar_igual(falas.count("cl_primeira_academia"), 1, "a unica nunca repete")
	g2.salvar()
	var g3 := _novo("f6c1_meio", pasta)
	var f3 := _ids_falas(g3)
	if g3.escolha_arte_pendente():
		g3.escolher_arte(g3.academia.ids_artes()[0])
	_tickar(g3, 80.0, 0.5)
	checar(not f3.has("cl_primeira_academia"), "depois de dita, nao volta na carga seguinte")
	_liberar(g)
	_liberar(g2)
	_liberar(g3)
	var h := _novo("f6c1_fala")
	var fh := _ids_falas(h)
	_tickar(h, 70.0, 0.5)
	_chegar(h)
	_tickar(h, 5.0)
	checar(fh.is_empty(), "durante a cena: nenhuma fala")
	_assentar(h)
	_tickar(h, 1.0)
	checar(fh.is_empty(), "antes da calma de 2 s: nenhuma fala")
	_tickar(h, 3.0)
	checar_igual(fh, ["cl_primeira_academia"], "1o momento calmo: cl_primeira_academia")
	_liberar(h)


func _teste_save_antigo() -> void:
	var g := _novo("f6c1_antigo")
	_chegar(g)
	_assentar(g)
	g.escola.milestones.erase(CENA_ACADEMIA)
	g.salvar()
	var pasta: String = g.store.pasta
	var g2 := _novo("f6c1_antigo", pasta)
	var pedidos: Array = []
	g2.cena_sala_pedida.connect(func(id: String) -> void: pedidos.append(id))
	var falas := _ids_falas(g2)
	checar(g2.local_id == "gym" and not g2.marco(CENA_ACADEMIA) and g2.cena_sala == "", "save antigo aberto na academia: sem cena na carga")
	checar(not g2.coach_presente() and g2.foto_antiga().is_empty() and g2.mentores_na_sala().is_empty(), "...e a academia fica como na 6b2 (sem Osmar, foto e mentores)")
	_tickar(g2, 120.0, 0.5)
	checar(falas.is_empty() and pedidos.is_empty(), "...sem balao do Osmar sem personagem")
	g2.local_id = "garage"
	checar(_chegar(g2), "proxima chegada pelo MUDAR")
	checar(g2.cena_sala == "primeira_academia" and pedidos == ["primeira_academia"], "a cena toca no proximo MUDAR")
	_assentar(g2)
	_tickar(g2, 4.0)
	checar_igual(falas, ["cl_primeira_academia"], "e a cl_primeira_academia sai uma vez")
	_liberar(g)
	_liberar(g2)


func _teste_cena_no_player() -> void:
	var g := _novo("f6c1_player")
	var p := CenaPlayer.new(g)
	_chegar(g)
	checar(p.iniciar("primeira_academia"), "o player inicia a primeira_academia")
	checar(g.cena_sala == "primeira_academia", "relogio parado enquanto toca")
	var t := 0.0
	while g.cena_sala != "" and t < 30.0:
		p.avancar(0.05)
		t += 0.05
	checar(t <= 15.0 + 1.0e-6 and g.cena_sala == "", "devolveu o controle em %.2f s (<= 15 s)" % t)
	checar("helper" in p._elenco.ausentes, "sem esteira comprada, o ajudante nao entra")
	checar_igual(p._elenco.personagens.get("box", ""), "helper_2", "campanha do John: um vizinho carrega a caixa")
	checar_igual(p._elenco.personagens.get("fighter", ""), "first_fighter", "campanha do John: current_player vira first_fighter")
	p.free()
	_liberar(g)
	var h := _novo("f6c1_player_esteira")
	h.aparelhos_montados_ids.append("treadmill")
	var q := CenaPlayer.new(h)
	_chegar(h)
	q.iniciar("primeira_academia")
	checar(not ("helper" in q._elenco.ausentes), "com esteira comprada, o ajudante entra")
	q.pular()
	checar(h.cena_sala == "" and not q.ativa, "PULAR: academia montada, relogio de volta")
	q.free()
	_liberar(h)


func _teste_elenco() -> void:
	var j := _novo("f6c1_elenco_john")
	var e: Dictionary = j.elenco_primeira_academia()
	checar_igual([e.fighter, e.box], ["first", "neighbor"], "Carreira 1: John joga, vizinho carrega a caixa")
	_liberar(j)
	var d := _com_mentor("f6c1_elenco_disc")
	e = d.elenco_primeira_academia()
	checar_igual([e.fighter, e.box], ["disciple", "first"], "John na escola: ele carrega a caixa")
	var p := CenaPlayer.new(d)
	_chegar(d)
	p.iniciar("primeira_academia")
	checar_igual(p._elenco.personagens.get("box", ""), "first_fighter", "o ator do caixote e o John")
	p.free()
	_liberar(d)
	var s := _com_mentor("f6c1_elenco_ultimo", 3)
	s._gravar_marco(CENA_SAIDA, {}, false)
	s.escola.mentors.erase("first")
	e = s.elenco_primeira_academia()
	checar_igual(e.box, "last_passed", "depois da saida, o ultimo que passou o posto carrega")
	checar(not e.box_look.is_empty(), "...com o look gravado")
	_liberar(s)
	var n := _com_mentor("f6c1_elenco_vazio", 2)
	n._gravar_marco(CENA_SAIDA, {}, false)
	n.escola.mentors.erase("first")
	checar_igual(n.elenco_primeira_academia().box, "neighbor", "depois da saida na Carreira 2: vizinho")
	_liberar(n)


func _teste_osmar_e_foto() -> void:
	var g := _novo("f6c1_osmar")
	checar(g.coach_presente() and g.ponto_do_coach() == [196, 236], "garagem: Osmar no ponto de sempre")
	checar_igual(g.foto_antiga().get("object_text", ""), "old_photo", "garagem: foto antiga com o texto de sempre")
	checar(not g.foto_antiga().get("tilted", true), "garagem: foto reta")
	_chegar(g)
	_tickar(g, 1.0)
	checar(g.coach_presente(), "academia com o marco: Osmar desenhado")
	var f: Dictionary = g.foto_antiga()
	checar(not f.is_empty() and not f.tilted and f.object_text == "old_photo_gym", "academia com o marco: foto reta (o Osmar desentorta) com texto proprio")
	_liberar(g)
	var s := _novo("f6c1_osmar_sem")
	s.local_id = "gym"
	checar(not s.coach_presente() and s.ponto_do_coach().is_empty() and s.foto_antiga().is_empty(), "academia sem o marco: sem Osmar e sem foto")
	var falas := _ids_falas(s)
	s.disparar_gatilho("big_purchase", {"what": "apparatus", "item": "treadmill"})
	s._t_real += 100.0
	_tickar(s, 5.0)
	checar(falas.is_empty(), "so fala quem esta desenhado")
	_liberar(s)


func _teste_mentores_por_local() -> void:
	var g := _com_mentor("f6c1_mentores_c2", 2)
	var m: Array = g.mentores_na_sala()
	checar(m.size() == 1 and m[0].id == "first" and m[0].role == "seat" and m[0].spot == "mentor_spot", "garagem, Carreira 2: so o John sentado")
	checar(g.assento_visivel(), "garagem: caixote desenhado")
	_chegar(g)
	_tickar(g, 1.0)
	m = g.mentores_na_sala()
	checar(m.size() == 1 and m[0].id == "first" and m[0].spot == "gym_mentor_spot", "academia com o marco: John no gym_mentor_spot")
	checar(g.assento_visivel() and g.mentor_sentado(), "academia: caixote desenhado e John sentado (toques valem)")
	_liberar(g)
	var h := _com_mentor("f6c1_mentores_c3", 3)
	m = h.mentores_na_sala()
	checar(m.size() == 2 and m[1].id == "last" and m[1].role == "stand" and m[1].spot == "mentor_2_spot" and m[1].pose == "stand_bare", "garagem, Carreira 3: o ultimo em pe")
	checar(not h.segundo_mentor().is_empty(), "segundo_mentor() devolve quem esta em pe")
	_chegar(h)
	checar(h.segundo_mentor().is_empty(), "na cena da academia o 2o mentor fica escondido")
	h.cena_sala_terminou()
	m = h.mentores_na_sala()
	checar(m.size() == 2 and m[1].spot == "gym_mentor_2_spot", "depois da cena o 2o mentor ja esta no ponto dele")
	checar(not h.segundo_mentor().is_empty(), "...e aparece")
	_liberar(h)
	var j := _novo("f6c1_mentores_john")
	checar(j.mentores_na_sala().is_empty(), "campanha do John: ninguem na sala")
	_liberar(j)


func _teste_saida_por_vitoria() -> void:
	var g := _com_mentor("f6c1_saida_a")
	var v := _espiar_saida(g)
	checar(not g.saida_devida(), "Carreira 2, sem vitoria na academia: saida nao devida")
	_tickar(g, 10.0)
	checar_igual(v.pedidos, 0, "sem gatilho, nada acontece")
	_vencer(g)
	checar(not g.marco(VITORIA), "vitoria na garagem nao arma a saida")
	_chegar(g)
	_assentar(g)
	_tickar(g, 5.0)
	checar_igual(v.pedidos, 0, "academia sem vitoria: nada")
	_vencer(g)
	checar(g.marco(VITORIA) and g.dados_marco(VITORIA).opponent != "", "1a vitoria na academia: marco com o adversario")
	checar(g.saida_devida(), "saida devida")
	_tickar(g, 12.0)
	checar_igual(v.pedidos, 1, "saida pedida no 1o momento calmo")
	checar(g.marco(CENA_SAIDA) and not ("first" in g.escola.mentors), "marco da saida gravado e o John fora da escola desde o comeco")
	checar(g.saida_tocando(), "saida tocando")
	checar(g.sala_ativa() and not g.acoes_bloqueadas(), "0 s presos: sala ativa e acoes liberadas durante a saida")
	var s1: float = g.arte_segundos
	_tickar(g, 1.0)
	checar(g.arte_segundos > s1, "o relogio anda durante a saida")
	var p := CenaPlayer.new(g)
	checar(p.iniciar("saida_primeiro_mentor"), "o player inicia a saida")
	checar(p._elenco.personagens.get("first", "") == "first_fighter" and not ("first" in p._elenco.ausentes), "o John existe na cena")
	var t := 0.0
	while p.ativa and t < 40.0:
		p.avancar(0.05)
		t += 0.05
	checar(not p.ativa and t <= 14.5, "a saida acaba sozinha em %.2f s (<= 14 s)" % t)
	checar(not g.saida_tocando(), "o jogo sabe que ela terminou")
	_tickar(g, 200.0, 0.5)
	checar_igual(v.pedidos, 1, "a saida nunca toca duas vezes")
	checar(not g.saida_devida() and g.mentores_na_sala().is_empty(), "sem John; Carreira 2: ninguem sentado")
	p.free()
	_liberar(g)


func _teste_saida_pela_reserva() -> void:
	var g := _com_mentor("f6c1_reserva", 3)
	var v := _espiar_saida(g)
	_tickar(g, 10.0)
	checar_igual(v.pedidos, 0, "Carreira 3, sem academia: John fica")
	_passar_o_posto(g)
	checar_igual(g.numero_carreira(), 4, "Carreira 4")
	checar(g.saida_devida(), "Carreira 4: saida devida pela reserva")
	_tickar(g, 4.0)
	checar_igual(v.pedidos, 1, "sai no comeco da Carreira 4, na garagem")
	var m: Array = g.mentores_na_sala()
	checar(m.size() == 1 and m[0].id == "last" and m[0].role == "seat" and m[0].pose == "sit_rest", "o ultimo que passou o posto vai para o caixote")
	checar(g.segundo_mentor().is_empty(), "ponto de pe vazio")
	_liberar(g)


func _teste_saida_interrupcoes() -> void:
	var g := _saida_devida("f6c1_int_janela")
	var v := _espiar_saida(g)
	_tickar(g, 3.0)
	checar(g.saida_tocando() and v.pedidos == 1, "saida tocando")
	g.definir_modal(true)
	_tickar(g, 0.1)
	checar(v.interrompidas == 1 and not g.saida_tocando(), "janela interrompe na hora")
	checar(g.marco(CENA_SAIDA) and not ("first" in g.escola.mentors), "o estado final ja valia (marco e John fora)")
	g.definir_modal(false)
	_tickar(g, 100.0, 0.5)
	checar_igual(v.pedidos, 1, "e a saida nao recomeca")
	_liberar(g)
	var l := _saida_devida("f6c1_int_luta")
	var vl := _espiar_saida(l)
	_tickar(l, 3.0)
	l.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	l.lutar()
	checar(vl.interrompidas == 1 and not l.saida_tocando(), "comecar luta interrompe")
	l.concluir_luta()
	_liberar(l)
	var m := _saida_devida("f6c1_int_mudar")
	var vm := _espiar_saida(m)
	_tickar(m, 3.0)
	_chegar(m)
	checar(vm.interrompidas == 1 and not m.saida_tocando(), "MUDAR interrompe")
	checar(m.cena_sala == "primeira_academia", "e a chegada a academia toca depois")
	_liberar(m)
	var f := _saida_devida("f6c1_int_fim")
	var vf := _espiar_saida(f)
	_tickar(f, 3.0)
	f.aposentar()
	checar(vf.interrompidas == 1 and not f.saida_tocando(), "tela de fim interrompe")
	f._saida_tocando = true
	f.receber_discipulo()
	checar(vf.interrompidas == 2 and not f.saida_tocando(), "RECEBER interrompe")
	_liberar(f)
	var p := _saida_devida("f6c1_int_player")
	var cancelou := [0]
	var pl := CenaPlayer.new(p)
	pl.baloes_cancelados.connect(func() -> void: cancelou[0] += 1)
	_tickar(p, 3.0)
	pl.iniciar("saida_primeiro_mentor")
	for i in 40:
		pl.avancar(0.05)
	p.definir_modal(true)
	_tickar(p, 0.1)
	checar(not pl.ativa and cancelou[0] == 1, "player: interrupcao termina a cena e fecha os baloes")
	pl.free()
	_liberar(p)


func _teste_saida_fechar_no_meio() -> void:
	var g := _saida_devida("f6c1_saida_meio")
	_tickar(g, 3.0)
	checar(g.saida_tocando(), "saida tocando")
	var pasta: String = g.store.pasta
	g.salvar()
	var g2 := _novo("f6c1_saida_meio", pasta)
	var v := _espiar_saida(g2)
	checar(g2.marco(CENA_SAIDA) and not ("first" in g2.escola.mentors), "ao abrir: marco e John fora")
	checar(not g2.saida_tocando() and not g2.saida_devida(), "a acao nao existe no save e nunca toca de novo")
	_tickar(g2, 100.0, 0.5)
	checar_igual(v.pedidos, 0, "nenhum pedido de saida depois de abrir")
	checar(g2.mentores_na_sala().is_empty() and g2.assento_visivel(), "Carreira 2: caixote vazio, ninguem sentado")
	_liberar(g)
	_liberar(g2)
	var h := _saida_devida("f6c1_saida_meio3", 3)
	_tickar(h, 4.0)
	h.salvar()
	var h2 := _novo("f6c1_saida_meio3", h.store.pasta)
	var m: Array = h2.mentores_na_sala()
	checar(m.size() == 1 and m[0].id == "last" and m[0].role == "seat", "Carreira 3: ao abrir, o ultimo ja esta sentado")
	_liberar(h)
	_liberar(h2)


func _teste_depois_da_saida() -> void:
	var g := _saida_devida("f6c1_depois", 3)
	_tickar(g, 4.0)
	g.saida_terminou()
	var planos: Array = []
	g.toques_mentor_pedidos.connect(func(pl: Dictionary) -> void: planos.append(pl))
	g.clicar()
	_tickar(g, 70.0, 0.5)
	g.clicar()
	checar(planos.is_empty(), "depois da saida ninguem faz os toques")
	checar(not g.mentor_sentado(), "mentor_sentado() e so o John")
	_liberar(g)
	var h := _com_mentor("f6c1_toques_gym", 2)
	_chegar(h)
	_assentar(h)
	var planos2: Array = []
	h.toques_mentor_pedidos.connect(func(pl: Dictionary) -> void: planos2.append(pl))
	_tickar(h, 3.0)
	h.mentor_cumprimentou = false
	h.clicar()
	checar_igual(planos2.size(), 1, "na academia (depois da cena) o John faz os toques do 1o clique")
	_liberar(h)


func _teste_comentario_da_arte() -> void:
	# Na 1a academia, a cl_primeira_academia gasta o intervalo de 60 s; o comentário da arte chega depois e espera na vaga.
	var g := _novo("f6c1_arte")
	var falas := _ids_falas(g)
	_tickar(g, 70.0, 0.5)
	_chegar(g)
	_assentar(g)
	_tickar(g, 4.0)
	checar_igual(falas, ["cl_primeira_academia"], "1a academia: a fala da chegada sai primeiro")
	_tickar(g, 62.0, 0.5)
	var arte := falas.filter(func(i: String) -> bool: return i.begins_with("cl_arte_"))
	checar_igual(arte.size(), 1, "o comentário da arte sai (não se perde no intervalo de 60 s)")
	_tickar(g, 300.0, 0.5)
	checar_igual(falas.filter(func(i: String) -> bool: return i.begins_with("cl_arte_")).size(), 1, "e só uma vez por campanha")
	_liberar(g)


func _teste_balanco() -> void:
	var a := _novo("f6c1_bal_a")
	var b := _novo("f6c1_bal_b")
	for g in [a, b]:
		g.cinturao = true
		g.dinheiro = 1.0e9
		_tickar(g, 5.0)
		g.mudar()
	_tickar(a, 14.0)
	for g in [a, b]:
		_assentar(g)
	for g in [a, b]:
		for i in 300:
			if i % 3 == 0:
				g.clicar()
			g.tick(0.1)
	checar_igual([a.segundos_campanha, a.treino, a.dinheiro, a.dia_campanha(), a.fight_day, a.arte_segundos],
		[b.segundos_campanha, b.treino, b.dinheiro, b.dia_campanha(), b.fight_day, b.arte_segundos], "cena tocada = cena pulada: relogio, treino, ouro, dia e arte iguais")
	_liberar(a)
	_liberar(b)
	var c := _com_mentor("f6c1_bal_c")
	var d := _com_mentor("f6c1_bal_d")
	c._gravar_marco(VITORIA, {"opponent": "x"}, false)
	d._gravar_marco(CENA_SAIDA, {}, false)
	var v := _espiar_saida(c)
	for g in [c, d]:
		g.lutas.calendario["seconds_per_day"] = 60.0
		for i in 600:
			if i % 3 == 0:
				g.clicar()
			g.tick(0.1)
	checar_igual(v.pedidos, 1, "(a campanha C teve a saida)")
	checar_igual([c.segundos_campanha, c.treino, c.dinheiro, c.dia_campanha(), c.fight_day],
		[d.segundos_campanha, d.treino, d.dinheiro, d.dia_campanha(), d.fight_day], "campanha com saida no meio = sem saida (relogio, treino, ouro, dia, luta)")
	_liberar(c)
	_liberar(d)


func _teste_sons() -> void:
	for id in ["gym_door_open", "gym_door_close", "metal_bump", "crate_down", "nail_knock", "frame_scrape", "tube_start"]:
		checar(FileAccess.file_exists("res://assets/sfx/%s.wav" % id), "som novo existe: " + id)
