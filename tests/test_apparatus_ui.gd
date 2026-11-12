extends "res://tests/test_base.gd"
## Compra real com a sala conectada: valida a caixa da escola (Fase 5.1), nao apenas o saldo e o save.

var gs: Node


func rodar_testes() -> void:
	gs = root.get_node("GameState")
	await _testar_chegadas("garage", "")
	await _testar_chegadas("gym", "")
	await _testar_chegadas("garage", "boxing")
	await _testar_chegadas("garage", "bjj")


func _testar_chegadas(local: String, arte: String) -> void:
	gs.inicializar(pasta_limpa("chegadas_%s_%s" % [local, arte]), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.local_id = local
	gs.arte_id = arte
	gs.treino = 1000000.0
	var sala: Control = load("res://ui/sala.gd").new()
	root.add_child(sala)
	await process_frame
	var aparelhos := ["treadmill", "jump_rope"]
	if arte != "":
		aparelhos.append("speed_bag" if arte == "boxing" else "grappling_dummy")
	for id in aparelhos:
		var contexto := "%s/%s/%s" % [local, arte, id]
		checar(gs.comprar_aparelho(id), contexto + ": compra aceita")
		checar(sala._caixas.has(id), contexto + ": a caixa chegou na sala")
		checar(sala._marcas[id].fita.visible, contexto + ": a marca fica embaixo da caixa")
		checar(not gs.aparelho_montado(id), contexto + ": aparelho ainda na caixa")
		await create_timer(0.4).timeout
		for i in 3:
			checar(sala.caixa_liberada(), contexto + ": caixa liberada para clique")
			sala._clique_em(sala._caixas[id].area().get_center())
			await create_timer(0.1).timeout
		await create_timer(1.3).timeout
		checar(not sala._caixas.has(id), contexto + ": a caixa vazia sumiu")
		checar_igual(gs.foco, id, contexto + ": foco no aparelho aberto")
		checar(not sala._marcas[id].fita.visible, contexto + ": marca de compra oculta")
		checar(not gs.clicar().is_empty(), contexto + ": permite treinar depois da chegada")
		var saldo: float = gs.treino
		checar(not gs.comprar_aparelho(id), contexto + ": nao compra duas vezes")
		checar_igual(gs.treino, saldo, contexto + ": recusa nao desconta treino")
	# Atualizacao dos personagens tambem continua funcionando depois das compras.
	checar(gs.comprar_gerador("neighbor_kid"), "compra de equipe depois dos aparelhos")
	checar(sala._pessoas["neighbor_kid"][0].sprite.visible, "vizinho aparece na sala")
	for p in sala.find_children("*", "AudioStreamPlayer", true, false):
		(p as AudioStreamPlayer).stop()
	sala.queue_free()
	await process_frame
	await create_timer(0.25).timeout
