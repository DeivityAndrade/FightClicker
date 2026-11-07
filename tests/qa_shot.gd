extends SceneTree
## QA: abre a cena principal numa janela, espera, tira screenshot e sai.
## Uso: godot --path . --resolution 1280x720 --script res://tests/qa_shot.gd -- <arquivo.png> [frames]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0]
	var frames := int(args[1]) if args.size() > 1 else 90
	var cena: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	for i in frames:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(saida)
	print("shot %s tamanho=%s janela=%s content_scale=%s mode=%s" % [saida, img.get_size(), root.size, root.content_scale_factor, root.content_scale_mode])
	var gs := root.get_node("GameState")
	print("treino=", gs.treino, " avisos=", gs.avisos)
	quit(0)
