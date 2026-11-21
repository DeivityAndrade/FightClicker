extends SceneTree
## Fase 7b (Diretor de Arte): prancha do carro comprido de volta (sedã de 2 portas da 1ª rodada da 6d3) com a lona cinza no
## estilo da 6d2. PLACEHOLDER gerado por código.
##   godot --headless --path <pasta_vazia> --script E:/Fightclicker/tools/art/make_mockup_fase7b_carro.gd -- \
##       <garage_bg_antes.png> <garagem_cheia_antes.png> <garagem_cheia_depois.png>
## ANTES = garage_bg e captura da 6d3 (sedã encurtado, 126 px); DEPOIS = assets/sprites/garage/garage_bg.png, a sala com TODOS
## os pontos (docs/arte/mockups/fase6d2_layout_garagem_fechado_cheia.png, do gerador) e a captura nova do jogo (ui_audit,
## estado f6d2_garagem_cheia; nesse estado o mentor sentado não aparece). Grava docs/arte/mockups/fase7b_carro_comprido.png.

const ROOT := "E:/Fightclicker/"
var L

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var a := OS.get_cmdline_user_args()
	var antes := _load(a[0])
	var dep := _load(ROOT + "assets/sprites/garage/garage_bg.png")
	var cheia_a := _load(a[1])
	var cheia_d := _load(a[2])
	var r := Rect2i(50, 150, 200, 90)
	var k := 3
	var pad := 8
	var lab := 14
	var todos := _load(ROOT + "docs/arte/mockups/fase6d2_layout_garagem_fechado_cheia.png")
	var W := pad * 4 + 640 * 3
	var H := pad * 3 + lab * 2 + r.size.y * k + 360
	var img: Image = L.blank(W, H)
	L.R(img, 0, 0, W, H, "d1")
	var tops := [["ANTES (6D3): SEDA ENCURTADO, 126 PX, LONA CLARA EM PLACA", antes],
		["DEPOIS (7B): SEDA COMPRIDO DE 2 PORTAS, ~160 PX, LONA CINZA COMO NA 6D2", dep]]
	for i in 2:
		var x := pad + i * (r.size.x * k + pad)
		L.text(img, tops[i][0], x, pad + 3, "gr3" if i == 1 else "white", 1, "ink")
		var c: Image = (tops[i][1] as Image).get_region(r)
		c.resize(r.size.x * k, r.size.y * k, Image.INTERPOLATE_NEAREST)
		img.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, pad + lab))
	var bots := [["ANTES, NO JOGO (1X): MENTOR SENTADO 210,254", cheia_a],
		["DEPOIS, TODOS OS PONTOS (1X): MENTOR SENTADO 232,270", todos],
		["DEPOIS, NO JOGO (1X, CAPTURA DO UI_AUDIT)", cheia_d]]
	var y := pad * 2 + lab + r.size.y * k
	for i in 3:
		var x := pad + i * (640 + pad)
		L.text(img, bots[i][0], x, y + 3, "white" if i == 0 else "y1", 1, "ink")
		img.blit_rect(bots[i][1], Rect2i(0, 0, 640, 360), Vector2i(x, y + lab))
	img.save_png(ROOT + "docs/arte/mockups/fase7b_carro_comprido.png")
	print("ok ", img.get_size())
	quit()

func _load(p: String) -> Image:
	var i := Image.load_from_file(p)
	i.convert(Image.FORMAT_RGBA8)
	if i.get_width() == 1280:
		i.resize(640, 360, Image.INTERPOLATE_NEAREST)   # captura do ui_audit (2x) volta para 1x
	return i
