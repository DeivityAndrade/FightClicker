extends SceneTree
## Regressão: a corda tem que girar a cada clique, mesmo depois de algo reposicionar o lutador no meio de um giro
## (compra, troca de luva, atualização da sala, gesto). Antes, o fim do giro se perdia e _corda_girando ficava preso em true.
## Roda: godot --headless --path . --script res://tests/test_corda_clique.gd   (save só em user://test/autoload/)

var gs: Node
var cena: Control
var sala
var ok_n := 0
var falhas: Array = []


func chk(c: bool, nome: String) -> void:
	if c:
		ok_n += 1
		print("PASS  ", nome)
	else:
		falhas.append(nome)
		print("FAIL  ", nome)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func girando() -> bool:
	return sala._lutador.esta_tocando() and sala._lutador.nome_sprite.begins_with("fighter_rope")


func clicar_corda() -> void:
	sala._reagir("jump_rope", false)
	await frames(2)


func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	await frames(10)
	gs.apagar_save()
	gs.pular_abertura()
	gs.risco_hud_ativo = false
	# Corda montada pelo nó da árvore (começa a carreira já com ela), sem caixa.
	gs.permanente["skill_nodes"] = ["gar_rope"]
	gs.aposentar()
	gs.nova_carreira()
	await frames(10)
	var fl = cena.get_node("Fluxo")
	if fl.cartao != null:
		fl.fechar_cartao_aberto()
	await frames(5)
	sala = cena.find_child("Sala", true, false)
	chk(sala != null, "Sala existe")
	chk(gs.aparelho_montado("jump_rope"), "corda montada")
	chk(gs.definir_foco("jump_rope") or gs.foco == "jump_rope", "foco na corda")
	await frames(5)
	# 1) clique normal gira
	await clicar_corda()
	chk(girando(), "1º clique: a corda gira")
	await create_timer(1.0).timeout
	chk(not sala._corda_girando, "sem cliques: a corda assenta")
	# 2) interrupção no meio do giro (atualização da sala) e depois novo clique
	await clicar_corda()
	chk(girando(), "clique antes da interrupção: gira")
	sala._aplicar_layout()
	await frames(2)
	await create_timer(1.0).timeout
	await clicar_corda()
	chk(girando(), "depois de atualizar a sala no meio do giro: o clique gira de novo")
	await create_timer(1.0).timeout
	# 3) interrupção pela troca de luva
	await clicar_corda()
	sala._ao_luva(1, "_glove_l1")
	await create_timer(1.0).timeout
	await clicar_corda()
	chk(girando(), "depois de trocar a luva no meio do giro: o clique gira de novo")
	# 4) cliques seguidos mantêm o giro
	for i in 6:
		await clicar_corda()
		await create_timer(0.15).timeout
	chk(girando(), "cliques seguidos: a corda continua girando")
	print("RESULTADO: %d ok, %d falhas" % [ok_n, falhas.size()])
	for f in falhas:
		print("  FALHOU: ", f)
	gs.apagar_save()
	for p in cena.find_children("*", "AudioStreamPlayer", true, false):
		(p as AudioStreamPlayer).stop()
	cena.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(1 if falhas.size() > 0 else 0)
