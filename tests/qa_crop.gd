extends SceneTree
## Recorta e amplia (vizinho mais proximo) um PNG: -- entrada x y w h escala saida
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	var r := Rect2i(int(a[1]), int(a[2]), int(a[3]), int(a[4]))
	var c := img.get_region(r)
	var s := int(a[5])
	c.resize(r.size.x * s, r.size.y * s, Image.INTERPOLATE_NEAREST)
	c.save_png(a[6])
	quit(0)
