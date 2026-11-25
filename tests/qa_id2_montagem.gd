extends SceneTree
## QA ID2: junta recortes numa folha (um PNG): -- saida img1 img2 ...
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var imgs: Array[Image] = []
	for i in range(1, a.size()):
		imgs.append(Image.load_from_file(a[i]))
	var h := 0
	var w := 0
	for im in imgs:
		h += im.get_height()
		w = maxi(w, im.get_width())
	var s := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var y := 0
	for im in imgs:
		s.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, y))
		y += im.get_height()
	s.save_png(a[0])
	quit(0)
