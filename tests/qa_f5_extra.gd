extends "res://tests/test_base.gd"
## QA Fase 5: cenarios extras para quebrar (nao e test_*: o run_tests nao pega). Saves so em user://test/.

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _belt(nome: String, dinheiro: float = 1000.0) -> Node:
	var gs = _novo(nome)
	gs.indice_escada = 4
	gs.cinturao = true
	gs.fama = 200
	gs.dinheiro = dinheiro
	return gs


func _recarregar(gs: Node) -> Node:
	var g2: Node = GameStateScript.new()
	g2.inicializar(gs.store.pasta, "res://data/config.json")
	g2.autosave_ativo = false
	return g2


func rodar_testes() -> void:
	# 1. MUDAR sem dinheiro / durante luta / na tela de fim / duas vezes
	var gs = _belt("q1", 999.99)
	checar(not gs.mudar(), "MUDAR com $999.99 recusa")
	gs.dinheiro = 1000.0
	gs.fim = {"kind": "retire"}
	checar(not gs.mudar(), "MUDAR na tela de fim recusa")
	gs.fim = {}
	gs.luta = {"x": 1}
	checar(not gs.mudar(), "MUDAR em luta recusa")
	gs.luta = {}
	checar(gs.mudar(), "MUDAR ok")
	checar(not gs.mudar(), "MUDAR 2x recusa")
	checar_igual(gs.dinheiro, 0.0, "dinheiro 0 apos mudar")
	# 2. fechar com a escolha pendente e reabrir
	var g2 = _recarregar(gs)
	checar(g2.escolha_arte_pendente() and g2.local_id == "gym", "reabrir: academia e escolha pendente")
	checar(g2.acoes_bloqueadas() and not g2.pode_lutar() and not g2.pode_aposentar(), "pendente bloqueia lutar/aposentar")
	var r = g2.clicar()
	checar(r.is_empty() or float(r.get("ganho", 0)) == 0.0 or g2.treino == 0.0, "clique bloqueado com escolha pendente (treino=%s)" % g2.treino)
	checar(not g2.escolher_arte("muay_thai"), "arte inexistente recusa")
	checar(not g2.escolher_arte(""), "arte vazia recusa")
	checar(g2.escolher_arte("boxing"), "escolhe boxe")
	checar(not g2.escolher_arte("bjj"), "troca no meio da carreira recusa")
	checar_igual(g2.arte_id, "boxing", "continua boxe")
	var g2b = _recarregar(g2)
	checar_igual([g2b.arte_id, g2b.escolha_arte_pendente()], ["boxing", false], "reabrir apos escolha mantem arte")
	_liberar(g2b)
	# 3. tick com pendente nao avanca relogio da arte?
	var g3 = _belt("q3")
	g3.mudar()
	var t0: float = g3.tempo_jogo
	for i in 100:
		g3.tick(0.1)
	checar(g3.arte_segundos == 0.0, "relogio da arte nao anda com escolha pendente (tempo_jogo anda: %s -> %s, ver R3)" % [t0, g3.tempo_jogo])
	g3.escolher_arte("bjj")
	for i in 600:
		g3.tick(0.1)
	print("INFO bjj apos 60s: segundos=%s bonus=%s hud=%s" % [g3.arte_segundos, g3.bonus_arte_equipe(), g3.texto_hud_arte()])
	g3.arte_segundos = 1.0e9
	checar_igual(g3.bonus_arte_equipe(), 1.0, "bjj teto 100% com tempo enorme")
	checar(g3.arte_no_teto(), "arte_no_teto")
	g3.arte_segundos = 1.0e308
	checar(is_finite(g3.bonus_arte_equipe()), "bjj finito com 1e308")
	g3.arte_segundos = 0.0
	# 4. boxe nao vale no auto/metronomo
	var g4 = _belt("q4", 50000.0)
	g4.mudar()
	g4.escolher_arte("boxing")
	var pc: float = g4.por_clique()
	var pa: float = g4.por_auto_soco()
	g4.nivel_metronomo = 1
	print("INFO boxe: por_clique=%s por_auto_soco=%s mult_local=%s" % [pc, pa, g4.mult_local()])
	var g4b = _belt("q4b", 50000.0)
	g4b.mudar()
	g4b.escolher_arte("bjj")
	checar_igual(g4b.por_auto_soco(), pa, "por_auto_soco igual boxe x bjj (sem bonus de boxe)")
	# 5. LOJA: reserva com cada item
	var g5 = _belt("q5", 1100.0)
	var itens := {}
	checar_igual(g5.loja_estado(100.0), "ok", "loja 100 com 1100: ok")
	checar_igual(g5.loja_estado(101.0), "reserve", "loja 101 com 1100: reserve")
	checar_igual(g5.loja_estado(1200.0), "money", "loja 1200: money")
	g5.dinheiro = 1000.0
	var luva_ok = g5.comprar_luva()
	var nel_ok = g5.comprar_gerador_pago("gen_paid_1")
	var met_ok = g5.comprar_metronomo()
	checar(not luva_ok and not nel_ok and not met_ok, "com $1000 exatos nada da loja compra (luva=%s nelson=%s metr=%s)" % [luva_ok, nel_ok, met_ok])
	checar_igual(g5.dinheiro, 1000.0, "dinheiro intacto")
	g5.dinheiro = 1000.0 + g5.custo_gerador_pago("gen_paid_1")
	checar(g5.comprar_gerador_pago("gen_paid_1"), "Nelson com folga compra")
	checar_igual(g5.dinheiro, 1000.0, "sobra exatamente 1000")
	checar(g5.pode_mudar(), "ainda da para mudar")
	# depois de mudar, reserva cai a 0
	g5.mudar()
	checar_igual(g5.reserva_mudanca(), 0.0, "reserva 0 na academia")
	# reserva sem cinturao = 0
	var g5b = _novo("q5b")
	g5b.dinheiro = 130.0
	checar_igual(g5b.reserva_mudanca(), 0.0, "sem cinturao nao ha reserva")
	# 6. aparelhos de outra arte
	var g6 = _belt("q6", 5000.0)
	g6.mudar()
	g6.escolher_arte("boxing")
	g6.treino = 1.0e9
	checar_igual(g6.estado_aparelho("grappling_dummy"), "absent", "boneco ausente no boxe")
	checar(not g6.comprar_aparelho("grappling_dummy"), "nao compra boneco no boxe")
	checar(not g6.definir_foco("grappling_dummy"), "foco no boneco recusa no boxe")
	checar(not g6.definir_foco("speed_bag"), "foco na pera recusa sem comprar")
	g6.comprar_aparelho("treadmill")
	checar(g6.comprar_aparelho("speed_bag"), "compra pera apos esteira")
	checar(g6.definir_foco("speed_bag"), "foco na pera")
	var d: Dictionary = g6.clicar()
	print("INFO clique pera: ", d)
	# 7. NOVA CARREIRA apos derrota / aposentadoria volta a garagem
	var g7 = _belt("q7", 5000.0)
	g7.mudar()
	g7.escolher_arte("bjj")
	var f: Dictionary = g7.aposentar()
	checar(not f.is_empty(), "aposenta na academia")
	checar(g7.nova_carreira(), "nova carreira")
	checar_igual([g7.local_id, g7.arte_id, g7.escolha_arte_pendente(), g7.dinheiro], ["garage", "", true, 0.0], "pos-aposentadoria: garagem, sem arte, escolha pendente")
	checar(g7.mudanca().state == "locked", "MUDAR travado na carreira nova")
	g7.escolher_arte("boxing")
	checar_igual(g7.aparelhos_da_carreira().size(), 4, "4 aparelhos com arte")
	checar_igual(g7.estado_aparelho("speed_bag"), "locked", "pera trancada ate esteira")
	# derrota: forcar luta perdida
	var g7b = _belt("q7b", 5000.0)
	g7b.mudar()
	g7b.escolher_arte("boxing")
	var l = g7b.lutar()
	print("INFO lutar na academia sem treino: ", l.keys())
	var res = g7b.concluir_luta()
	print("INFO resultado: win=", g7b.luta_atual().get("win", "?"), " fim=", g7b.fim.get("kind", "-"))
	if not g7b.fim.is_empty():
		g7b.nova_carreira()
		checar_igual([g7b.local_id, g7b.arte_id, g7b.escolha_arte_pendente()], ["garage", "", true], "pos-derrota: garagem, sem arte, pendente")
	# 8. dica de aposentar (300 s PERIGOSO)
	var g8 = _belt("q8", 1000.0)
	g8.mudar()
	g8.escolher_arte("boxing")
	g8.risco_hud_ativo = true
	g8.atributos = {"strength": 100.0, "agility": 100.0, "endurance": 100.0}
	var tt = 0.0
	var visto = -1.0
	for i in 4000:
		g8.tick(0.1)
		tt += 0.1
		if visto < 0.0 and g8.dica_aposentar().show:
			visto = tt
	print("INFO dica_aposentar visivel em t=%s (esperado ~300) texto=%s" % [visto, g8.dica_aposentar().text])
	checar(visto >= 299.0 and visto <= 302.0, "dica de aposentar aos 300 s")
	# 9. migracao v5 com cinturao e < $1.000
	var base := '{"version": 5, "saved_at_unix": 1730000000, "state": {"career": {"metronome_level": 0, "apparatus_owned": ["punching_bag"], '
	base += '"training": 5000, "attributes": {"strength": 900, "agility": 200, "endurance": 134}, "focus": "punching_bag", "generators": {}, '
	base += '"upgrades": {}, "paid_generators": {}, "glove_level": 0, "money": %s, "fame": 200, "ladder_index": 4, "belt": true, '
	base += '"tactic": "counter", "play_seconds": 1800, "money_earned": 2000, "fight": null}, '
	base += '"permanent": {"legacy_total": 0, "career_number": 2, "careers_finished": 1, "best_wins": 4, "belts_won": 1, "skill_nodes": [], "revenge_opponent": ""}, "ending": null}}'
	for m in ["0", "500", "999", "999.5", "1000", "1000.5"]:
		var p := pasta_limpa("q9_" + m.replace(".", "_"))
		escrever(p + "save.json", base % m)
		var g9: Node = GameStateScript.new()
		g9.inicializar(p, "res://data/config.json")
		g9.autosave_ativo = false
		print("INFO v5 belt money=%s -> %s estado=%s" % [m, g9.dinheiro, g9.estado_mudanca()])
		_liberar(g9)
	# 10. save corrompido: valores bizarros
	var p10 := pasta_limpa("q10")
	escrever(p10 + "save.json", '{"version": 6, "state": {"career": {"location": 5, "art": ["x"], "art_seconds": 1e999, "money": -50, "ladder_index": 99, "belt": "yes"}, "permanent": {"arts_unlocked": "boxing", "last_art": 7}}}')
	var g10: Node = GameStateScript.new()
	g10.inicializar(p10, "res://data/config.json")
	g10.autosave_ativo = false
	print("INFO corrompido: local=%s arte=%s seg=%s din=%s idx=%s belt=%s unl=%s avisos=%s" % [g10.local_id, g10.arte_id, g10.arte_segundos, g10.dinheiro, g10.indice_escada, g10.cinturao, g10.artes_liberadas(), g10.avisos])
	g10.tick(0.1)
	checar(is_finite(g10.por_clique()) and is_finite(g10.producao_total()), "corrompido: numeros finitos")
	_liberar(g10)
	# save vazio / lixo
	var p11 := pasta_limpa("q11")
	escrever(p11 + "save.json", "lixo{{")
	var g11: Node = GameStateScript.new()
	g11.inicializar(p11, "res://data/config.json")
	checar_igual(g11.local_id, "garage", "save ilegivel: novo jogo")
	_liberar(g11)
	# 11. academia sem arte liberada (save editado local=gym, sem arts)
	var p12 := pasta_limpa("q12")
	escrever(p12 + "save.json", '{"version": 6, "state": {"career": {"location": "gym", "ladder_index": 4, "belt": true}, "permanent": {}}}')
	var g12: Node = GameStateScript.new()
	g12.inicializar(p12, "res://data/config.json")
	g12.autosave_ativo = false
	print("INFO gym sem artes: local=%s liberadas=%s pendente=%s estado_escada=%s" % [g12.local_id, g12.artes_liberadas(), g12.escolha_arte_pendente(), g12.estado_escada()])
	_liberar(g12)
	# 12. muitas compras seguidas / valores extremos
	var g13 = _belt("q13", 1.0e300)
	g13.mudar()
	g13.escolher_arte("bjj")
	g13.treino = 1.0e300
	for i in 3000:
		g13.comprar_gerador("neighbor_kid")
	g13.tick(1.0)
	checar(is_finite(g13.treino) and is_finite(g13.producao_total()), "compras extremas: finito (treino=%s prod=%s)" % [g13.treino, g13.producao_total()])
	_liberar(g13)
	_liberar(gs)
	_liberar(g2)
	_liberar(g3)
	_liberar(g4)
	_liberar(g4b)
	_liberar(g5)
	_liberar(g5b)
	_liberar(g6)
	_liberar(g7)
	_liberar(g7b)
	_liberar(g8)
