extends SceneTree
## Fase 6d3 (Diretor de Arte): prancha do carro com a lona de volta. PLACEHOLDER gerado por código.
##   godot --headless --path <pasta_vazia> --script E:/Fightclicker/tools/art/make_mockup_fase6d3_carro_lona.gd -- <garage_bg_sem_lona.png>
## ANTES 6D2 = docs/arte/mockups/fase6d2_fundo_garagem.png; SEM LONA = o garage_bg da 1ª rodada da 6d3 (passado no argumento);
## DEPOIS = assets/sprites/garage/garage_bg.png; TAMANHO REAL = docs/arte/mockups/fase6d3_garagem_cheia.png.
## Grava docs/arte/mockups/fase6d3_carro_lona.png.

const ROOT := "E:/Fightclicker/"
var L

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var a := OS.get_cmdline_user_args()
	var antes := _load(ROOT + "docs/arte/mockups/fase6d2_fundo_garagem.png")
	var sem := _load(a[0])
	var dep := _load(ROOT + "assets/sprites/garage/garage_bg.png")
	var cheia := _load(ROOT + "docs/arte/mockups/fase6d3_garagem_cheia.png")
	var r := Rect2i(60, 150, 200, 85)
	var k := 3
	var pad := 8
	var lab := 14
	var W := pad * 4 + 3 * r.size.x * k
	var H := pad * 3 + lab * 2 + r.size.y * k + 360
	var img: Image = L.blank(W, H)
	L.R(img, 0, 0, W, H, "d1")
	var cells := [["ANTES (6D2): CARRO PEQUENO COM LONA", antes], ["6D3 1A RODADA: SEDA SEM LONA", sem], ["DEPOIS: SEDA COM A LONA DE VOLTA", dep]]
	for i in 3:
		var x := pad + i * (r.size.x * k + pad)
		L.text(img, cells[i][0], x, pad + 3, "gr3" if i == 2 else "white", 1, "ink")
		var c: Image = cells[i][1].get_region(r)
		c.resize(r.size.x * k, r.size.y * k, Image.INTERPOLATE_NEAREST)
		img.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, pad + lab))
	var y := pad * 2 + lab + r.size.y * k
	L.text(img, "TAMANHO REAL (1X, SALA CHEIA)", pad, y + 3, "y1", 1, "ink")
	img.blit_rect(cheia, Rect2i(0, 0, 640, 360), Vector2i(pad, y + lab))
	img.save_png(ROOT + "docs/arte/mockups/fase6d3_carro_lona.png")
	print("ok ", img.get_size())
	quit()

func _load(p: String) -> Image:
	var i := Image.load_from_file(p)
	i.convert(Image.FORMAT_RGBA8)
	return i
