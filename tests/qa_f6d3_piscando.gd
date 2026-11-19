extends SceneTree
## QA 6d3: luta REAL (frames renderizados, tempo real) com discipulo de visual bem diferente; conta quadros com a folha padrao.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d3_piscando.gd (APPDATA temporario)
const LOOK := {"skin": "skin_5", "hair_color": "blond", "hair_style": "bun", "shorts_color": "purple", "top": "tank",
	"top_color": "yellow", "headband": "band", "headband_color": "red", "socks": "on"}
var gs: Node
var falhas := 0
func ok(c: bool, n: String) -> void:
	if not c: falhas += 1
	print("PASS  " if c else "FAIL  ", n)
func _initialize() -> void:
	gs = root.get_node("GameState")
	var DV: GDScript = load("res://ui/disc_visual.gd")
	await process_frame
	gs.inicializar("user://test/qa6d3pisc/", "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	while gs.numero_carreira() < 2:
		gs.aposentar(); gs.receber_discipulo(); gs.sucessao_tela_aberta(); gs.confirmar_discipulo(); gs.sucessao_terminou()
	gs.discipulo = {"name": "T", "look": LOOK.duplicate(), "campaign": 2}
	for ganha in [true, false]:
		gs.treino = 500.0
		gs.atributos = {"strength": 1000.0 if ganha else 0.0, "agility": 100.0 if ganha else 0.0, "endurance": 700.0 if ganha else 0.0}
		var d := {}
		for semente in range(1, 300):
			gs.rng.seed = semente
			var info: Dictionary = gs.lutar()
			if info.is_empty(): break
			if bool(info.result.win) == ganha and (bool(info.result.ko) or not ganha):
				d = gs.luta_atual(); break
			gs.aguardar_motivo(); gs.luta = {}
		ok(not d.is_empty(), "luta achada ganha=%s" % ganha)
		var tela: Control = load("res://ui/tela_luta.gd").new()
		root.add_child(tela)
		await process_frame
		tela.iniciar(d)
		var spr = tela._l[0].spr
		var quadros := 0
		var errados := 0
		var poses := {}
		var t0 := Time.get_ticks_msec()
		while not tela.finalizada and Time.get_ticks_msec() - t0 < 120000:
			await RenderingServer.frame_post_draw
			var cam: String = DV.nome_em_camadas(spr.nome_sprite)
			if cam != "":
				quadros += 1
				poses[spr.nome_sprite] = true
				var esp: Texture2D = DV.textura(cam, gs.visual_lutador(), gs.simbolo_no_lutador())
				if spr.texture != esp:
					errados += 1
					print("   quadro errado: ", spr.nome_sprite)
		print("ganha=", ganha, " quadros renderizados=", quadros, " poses=", poses.size(), " errados=", errados, " finalizada=", tela.finalizada)
		ok(errados == 0 and quadros > 50, "0 quadros com boneco padrao (ganha=%s)" % ganha)
		tela.encerrar(); tela.queue_free()
		await process_frame
		gs.luta = {}
		await create_timer(1.6).timeout
	print("FALHAS ", falhas)
	quit(1 if falhas > 0 else 0)
