extends SceneTree
## QA 6d: o discipulo montado em cada aparelho (saco, corda, esteira; academia: pera, boneco) na garagem e na academia.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_aparelhos.gd -- look=N  (APPDATA temporario!)
const CONFIG := "res://data/config.json"
const L := [
	{},
	{"skin": "skin_1", "hair_color": "black", "hair_style": "buzz", "shorts_color": "green", "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_5", "hair_color": "blond", "hair_style": "bun", "shorts_color": "blue", "top": "tank", "top_color": "white", "headband": "band", "headband_color": "red", "socks": "on"},
	{"skin": "skin_1", "hair_color": "platinum", "hair_style": "volume", "shorts_color": "black", "top": "tee", "top_color": "black", "headband": "band", "headband_color": "black", "socks": "on"},
	{"skin": "skin_5", "hair_color": "black", "hair_style": "short", "shorts_color": "white", "top": "tee", "top_color": "white", "headband": "band", "headband_color": "white", "socks": "on"},
]
var gs: Node
var cena: Node
var out := ""
var li := 2

func esperar(s: float) -> void:
	await create_timer(s).timeout

func cap() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func fechar() -> void:
	if cena != null:
		for p in cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		cena.queue_free()
		cena = null
		await process_frame

func montar(local: String) -> void:
	await fechar()
	gs.inicializar("user://test/qa6da_" + local + "/", CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	gs.escola["mentors"] = ["first"]
	gs.discipulo = {"name": "Teste", "look": L[li].duplicate(), "campaign": 3}
	gs.permanente = {"legacy_total": 12, "career_number": 3, "careers_finished": 2, "best_wins": 3, "belts_won": 1, "arts_unlocked": ["boxing", "bjj"], "last_art": "boxing"}
	gs.atributos = {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
	gs.treino = 1.0e6
	gs.dinheiro = 1.0e9
	if local == "gym":
		gs.local_id = "gym"
		gs.cinturao = true
		gs.indice_escada = 4
		gs._gravar_marco("cena_primeira_academia", {}, false)
		gs.arte_id = "boxing"
	gs.arte_id = "boxing"
	for ap in ["treadmill", "jump_rope", "speed_bag", "grappling_dummy"]:
		if not gs.aparelho_montado(ap):
			gs._aparelhos._montar_aparelho(ap)
	gs._recalcular_bonus()
	gs.modal_aberto = false
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.9)

func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6d_qa_aparelhos_"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("look="):
			li = int(a.substr(5))
	await process_frame
	for local in ["garage", "gym"]:
		await montar(local)
		var focos: Array = ["punching_bag", "treadmill", "jump_rope"] if local == "garage" else ["punching_bag", "treadmill", "jump_rope", "speed_bag", "grappling_dummy"]
		var Q: Array = []
		for foco in focos:
			if not gs.definir_foco(foco):
				print("foco indisponivel: ", foco)
				continue
			await esperar(0.7)
			for i in 6:
				gs.clicar()
				var img: Image = await cap()
				var r := img.get_region(Rect2i(200, 140, 200, 150))
				r.resize(400, 300, Image.INTERPOLATE_NEAREST)
				Q.append(r)
				await esperar(0.13)
		var cols := 6
		var rows := int(ceil(Q.size() / float(cols)))
		var s := Image.create(400 * cols, 300 * rows, false, Image.FORMAT_RGBA8)
		for i in Q.size():
			s.blit_rect(Q[i], Rect2i(0, 0, 400, 300), Vector2i((i % cols) * 400, (i / cols) * 300))
		s.save_png(out + "%s_look%d.png" % [local, li])
		print("salvo ", local, " quadros ", Q.size())
	await fechar()
	quit(0)
