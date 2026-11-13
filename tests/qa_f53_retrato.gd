extends SceneTree
## QA 5.3: retrato do jogador por luva (L0-L4) na prévia, na luta e na tela de fim. Monta uma folha em OUT.
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa53/"

var gs: Node
var cena: Control
var fluxo


func frames(n: int) -> void:
	for i in n:
		await process_frame


func esperar(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await process_frame


func nj(j) -> String:
	if j == null:
		return ""
	var sc = j.get_script()
	return str(sc.get_global_name()) if sc != null else ""


func recorte(r: Rect2i) -> Image:
	var img: Image = root.get_texture().get_image()
	return img.get_region(r)


func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	fluxo = cena.get_node("Fluxo")
	await frames(10)
	gs.apagar_save()
	gs.dados.crit_chance = 0.0
	var folha := Image.create(3 * 70, 5 * 60, false, Image.FORMAT_RGBA8)
	folha.fill(Color.BLACK)
	for n in [0, 1, 2, 3, 4]:
		gs.nivel_luva = n
		gs.luva_mudou.emit(n, gs.sufixo_luva())
		gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
		gs.fama = 50
		await frames(3)
		print("L", n, " retrato=", "portrait_player" + gs.sufixo_luva())
		fluxo.abrir_previa()
		await esperar(0.6)
		folha.blit_rect(recorte(Rect2i(425, 25, 60, 50)), Rect2i(0, 0, 60, 50), Vector2i(0, n * 60))
		fluxo._lutar()
		await esperar(0.8)
		folha.blit_rect(recorte(Rect2i(0, 0, 60, 50)), Rect2i(0, 0, 60, 50), Vector2i(70, n * 60))
		Engine.time_scale = 30.0
		var t0 := Time.get_ticks_msec()
		while nj(fluxo.janela) != "JanelaVitoria" and Time.get_ticks_msec() - t0 < 30000:
			await process_frame
		Engine.time_scale = 1.0
		fluxo._fechar_vitoria({"belt": false})
		await frames(5)
		gs.aposentar()
		await esperar(1.2)
		root.get_texture().get_image().save_png(OUT + "fim_l%d.png" % n)
		print("  fim janela=", nj(fluxo.janela))
		gs.nova_carreira()
		await esperar(0.6)
		if fluxo.cartao != null:
			fluxo.fechar_cartao_aberto()
		await frames(5)
	folha.save_png(OUT + "folha_retratos.png")
	quit(0)
