extends SceneTree
## Empilha folhas de sprite sobre fundo liso claro, ampliadas (vizinho mais proximo): -- saida escala arquivo1 arquivo2 ...
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var s := int(a[1])
	var imgs: Array = []
	var w := 0
	var h := 0
	for i in range(2, a.size()):
		var im := Image.load_from_file(a[i])
		im.convert(Image.FORMAT_RGBA8)
		imgs.append(im)
		w = max(w, im.get_width())
		h += im.get_height() + 2
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.78, 0.9, 0.78))
	var y := 0
	for im in imgs:
		out.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(0, y))
		y += im.get_height() + 2
	out.resize(w * s, h * s, Image.INTERPOLATE_NEAREST)
	out.save_png(a[0])
	quit(0)
