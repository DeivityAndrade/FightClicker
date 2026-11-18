extends SceneTree
## QA 6d: mural (busto), retrato do HUD da luta e da previa, com varios visuais. Estado montado direto (como qa_f6c2_balao).
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_mural.gd   (APPDATA temporario!)
const CONFIG := "res://data/config.json"
const L := [
	{"skin": "skin_1", "hair_color": "black", "hair_style": "buzz", "shorts_color": "green", "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_5", "hair_color": "blond", "hair_style": "bun", "shorts_color": "blue", "top": "tank", "top_color": "white", "headband": "band", "headband_color": "red", "socks": "on"},
	{"skin": "skin_1", "hair_color": "platinum", "hair_style": "volume", "shorts_color": "black", "top": "tee", "top_color": "black", "headband": "band", "headband_color": "black", "socks": "on"},
	{"skin": "skin_5", "hair_color": "black", "hair_style": "short", "shorts_color": "white", "top": "tee", "top_color": "white", "headband": "band", "headband_color": "white", "socks": "on"},
	{"skin": "skin_3", "hair_color": "copper", "hair_style": "bun", "shorts_color": "purple", "top": "none", "top_color": "white", "headband": "band", "headband_color": "yellow", "socks": "on"},
	{"skin": "skin_2", "hair_color": "dark_brown", "hair_style": "volume", "shorts_color": "yellow", "top": "tank", "top_color": "yellow", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_4", "hair_color": "brown", "hair_style": "buzz", "shorts_color": "green", "top": "tee", "top_color": "green", "headband": "band", "headband_color": "green", "socks": "on"},
]
var gs: Node
var cena: Node
var out := ""

func esperar(s: float) -> void:
	await create_timer(s).timeout

func cap() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6d_qa_"
	await process_frame
	gs.inicializar("user://test/qa6dm/", CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	var roster: Array = [{"campaign": 1, "kind": "first", "name": "John Bullet", "look": null, "end": "retire", "wins": 3, "belt": true, "art": "", "opponent": "", "legacy_gained": 0, "honor": 15}]
	for i in L.size():
		roster.append({"campaign": i + 2, "kind": "disciple", "name": "Disc %d" % (i + 1), "look": L[i].duplicate(), "end": "retire" if i % 2 == 0 else "defeat", "wins": 2, "belt": false, "art": "", "opponent": "opp_tank", "legacy_gained": 0, "honor": 3})
	gs.escola["roster"] = roster
	gs.escola["mentors"] = []
	gs.discipulo = {"name": "Atual", "look": L[2].duplicate(), "campaign": 9}
	gs.permanente = {"legacy_total": 12, "career_number": 9, "careers_finished": 8, "best_wins": 3, "belts_won": 1, "arts_unlocked": ["boxing", "bjj"], "last_art": "boxing"}
	gs._gravar_marco("garage_saved", {"campaign": 2}, false)  # simbolo da escola a partir da campanha 2
	gs._gravar_marco("cena_saida_primeiro_mentor", {}, false)
	gs.arte_id = "boxing"
	gs._recalcular_bonus()
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.8)
	var fl: Node = cena.get_node("Fluxo")
	print("simbolo_no_lutador=", gs.simbolo_no_lutador(), " campanha_do_simbolo=", gs.campanha_do_simbolo())
	fl.abrir_mural()
	await esperar(0.8)
	var img: Image = await cap()
	img.save_png(out + "mural_0.png")
	var j: Node = fl.janela
	print("janela: ", j)
	if j != null:
		for b in j.find_children("*", "Button", true, false):
			var t := ""
			for l in b.find_children("*", "Label", true, false):
				t += str(l.text)
			print("botao: '", t, "' ", b.name)
		# pagina 2
		for b in j.find_children("*", "Button", true, false):
			var t2 := ""
			for l in b.find_children("*", "Label", true, false):
				t2 += str(l.text)
			if t2 == ">" or t2.to_lower().contains("próx") or t2.to_lower().contains("prox") or b.name.to_lower().contains("prox") or b.name.to_lower().contains("next"):
				b.pressed.emit()
				break
		await esperar(0.5)
		var img2: Image = await cap()
		img2.save_png(out + "mural_1.png")
	fl._fechar_mural()
	await esperar(0.4)
	# retratos: previa + luta para cada visual
	var portr: Array = []
	for i in L.size():
		gs.discipulo = {"name": "Atual", "look": L[i].duplicate(), "campaign": 9}
		gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
		if fl.janela != null:
			fl._fechar()
		fl.abrir_previa()
		await esperar(0.5)
		var ip: Image = await cap()
		var rp := ip.get_region(Rect2i(436, 34, 38, 40))
		rp.resize(38 * 4, 40 * 4, Image.INTERPOLATE_NEAREST)
		if fl.janela != null:
			fl.janela.lutar_pedido.emit()
			await esperar(1.2)
			var il: Image = await cap()
			var rl := il.get_region(Rect2i(0, 0, 40, 30))
			rl.resize(40 * 4, 30 * 4, Image.INTERPOLATE_NEAREST)
			portr.append([rp, rl])
			# espera a luta acabar e fecha
			var tl: Node = fl.tela
			var t := 0.0
			while tl.visible and t < 30.0:
				await esperar(0.2)
				t += 0.2
				if not gs.luta.is_empty() and tl._clock > float(gs.luta.result.t_end) + 0.5:
					break
			await esperar(1.2)
			var g := 0
			while fl.janela != null and g < 6:
				g += 1
				if fl.janela.has_signal("continuar_pedido"):
					fl.janela.continuar_pedido.emit()
				await esperar(0.5)
	var W := 160 + 4
	var s := Image.create(W * portr.size(), 160 + 120, false, Image.FORMAT_RGBA8)
	s.fill(Color(0.1, 0.1, 0.1))
	for i in portr.size():
		s.blit_rect(portr[i][0], Rect2i(0, 0, 152, 160), Vector2i(i * W, 0))
		s.blit_rect(portr[i][1], Rect2i(0, 0, 160, 120), Vector2i(i * W, 160))
	s.save_png(out + "retratos.png")
	print("FIM")
	quit(0)
