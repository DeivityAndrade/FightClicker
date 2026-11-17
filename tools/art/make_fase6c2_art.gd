extends SceneTree

# Gera placeholder do símbolo da escola e mockup dos 6 estados do mural (fase 6c2).
# Rodar: godot --headless --path <tmp_com_project.godot> --quit-after 5 --script E:/Fightclicker/tools/art/make_fase6c2_art.gd

const INK = Color("#14101a")
const R2 = Color("#d4473a")
const Y0 = Color("#e0a040")
const BR1 = Color("#6b3f2a")
const G2 = Color("#8f8890")
const CREAM = Color("#d9cdb4")
const WHITE = Color("#f2ece0")

func _init():
	var root = "E:/Fightclicker/.claude/worktrees/wonderful-bun-9781c6"
	_make_symbol(root)
	_make_mural(root)
	print("OK: symbol + mural generated")
	quit()

func _make_symbol(root: String):
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Contorno ink nas bordas
	for i in range(12):
		img.set_pixel(i, 0, INK)
		img.set_pixel(i, 11, INK)
		img.set_pixel(0, i, INK)
		img.set_pixel(11, i, INK)
	# Três ramos convergindo (raiz estilizada / triângulo invertido aberto)
	# Ramo esquerdo (r2)
	for y in range(1, 9):
		var x = 1 + (y * 3) / 8
		img.set_pixel(x, y, R2)
		img.set_pixel(x + 1, y, R2)
	# Ramo direito (r2)
	for y in range(1, 9):
		var x = 10 - (y * 3) / 8
		img.set_pixel(x, y, R2)
		img.set_pixel(x - 1, y, R2)
	# Caule central (y0)
	for y in range(3, 11):
		img.set_pixel(5, y, Y0)
		img.set_pixel(6, y, Y0)
	# Ponto de convergência
	img.set_pixel(5, 9, R2)
	img.set_pixel(6, 9, R2)
	img.set_pixel(5, 10, Y0)
	img.set_pixel(6, 10, Y0)
	# Arco superior conectando os ramos
	for x in range(3, 9):
		img.set_pixel(x, 2, R2)
	var path = root + "/assets/sprites/ui/school_symbol.png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("  symbol -> ", path)

func _make_mural(root: String):
	var panel_w = 32
	var panels = 6
	var w = panel_w * panels
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var states = ["empty", "john_only", "john_left", "with_disciple", "symbol_unlocked", "mural_upgraded"]
	for idx in range(panels):
		var ox = idx * panel_w
		var state = states[idx]
		# Parede: cream até y=40, depois g2 (chão/barrado)
		for yy in range(h):
			for xx in range(panel_w):
				var c = CREAM if yy < 40 else G2
				img.set_pixel(ox + xx, yy, c)
		# Divisória entre painéis
		if idx > 0:
			for yy in range(h):
				img.set_pixel(ox, yy, INK)
		# Pregos sempre visíveis
		img.set_pixel(ox + 8, 6, INK)
		img.set_pixel(ox + 23, 6, INK)
		match state:
			"empty":
				pass
			"john_only":
				_draw_photo(img, ox, 6, 10, 10, 12)
				_draw_plaque(img, ox, 5, 24, 22, 6)
			"john_left":
				_draw_photo(img, ox, 6, 10, 10, 12)
				_draw_plaque(img, ox, 5, 24, 22, 6)
				# Espaço vazio pontilhado à direita
				for yy in range(10, 22):
					if yy % 2 == 0:
						img.set_pixel(ox + 20, yy, INK)
						img.set_pixel(ox + 27, yy, INK)
				for xx in range(20, 28):
					if xx % 2 == 0:
						img.set_pixel(ox + xx, 10, INK)
						img.set_pixel(ox + xx, 21, INK)
			"with_disciple":
				_draw_photo(img, ox, 4, 10, 10, 12)
				_draw_plaque(img, ox, 3, 24, 12, 6)
				_draw_plaque(img, ox, 17, 24, 12, 6)
			"symbol_unlocked":
				_draw_photo(img, ox, 6, 8, 10, 12)
				_draw_plaque(img, ox, 5, 22, 22, 6)
				_draw_mini_symbol(img, ox, 13, 32)
			"mural_upgraded":
				_draw_photo(img, ox, 5, 4, 8, 9)
				_draw_plaque(img, ox, 3, 14, 12, 6)
				_draw_plaque(img, ox, 17, 14, 12, 6)
				_draw_mini_symbol(img, ox, 13, 32)
	var path = root + "/docs/arte/mockups/fase6c2_mural_states.png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("  mural -> ", path)

func _draw_photo(img: Image, ox: int, px: int, py: int, pw: int, ph: int):
	for yy in range(py, py + ph):
		for xx in range(px, px + pw):
			img.set_pixel(ox + xx, yy, BR1)
	for yy in range(py + 1, py + ph - 1):
		for xx in range(px + 1, px + pw - 1):
			img.set_pixel(ox + xx, yy, WHITE)

func _draw_plaque(img: Image, ox: int, px: int, py: int, pw: int, ph: int):
	for yy in range(py, py + ph):
		for xx in range(px, px + pw):
			img.set_pixel(ox + xx, yy, BR1)
	# Linha de texto placeholder em y0
	var ty = py + ph / 2
	for xx in range(px + 2, px + pw - 2):
		img.set_pixel(ox + xx, ty, Y0)

func _draw_mini_symbol(img: Image, ox: int, sx: int, sy: int):
	for dy in range(6):
		for dx in range(6):
			var c = R2 if (dx + dy) % 3 == 0 else Y0
			img.set_pixel(ox + sx + dx, sy + dy, c)