extends SceneTree
## Fase 6d3 (Diretor de Arte): prancha do símbolo aprovado (R de raiz) aplicado no jogo. PLACEHOLDER gerado por código.
## Usa os arquivos de assets/sprites e as capturas do verificador (1280x720) depois de make_arte_fase6d3_simbolo.gd:
##   godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tools/ui/ui_audit.gd -- --estados todos --saida <pasta>
##   godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_mockup_fase6d3_simbolo_aplicado.gd -- <pasta>
## Grava docs/arte/mockups/fase6d3_simbolo_aplicado.png.

const ROOT := "E:/Fightclicker/"
var L

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var sd: String = OS.get_cmdline_user_args()[0].trim_suffix("/") + "/"
	var W := 1300
	var img: Image = L.blank(W, 1600)
	L.R(img, 0, 0, W, 1600, "d1")
	L.text(img, "SIMBOLO DA ESCOLA APLICADO: R DE RAIZ (PROPOSTA D). CAPTURAS DO JOGO EM 1280X720 (2X DA BASE)", 8, 6, "white", 1, "ink")
	var x := 8
	var y := 24
	# os 4 tamanhos x8 / x4
	L.text(img, "UI: 5, 9, 16 E 32 (X8, X8, X8, X4)", x, y + 2, "y1", 1, "ink")
	var xx := x
	for n in [5, 9, 16, 32]:
		var s := _load(ROOT + "assets/sprites/ui/school_symbol_%d.png" % n)
		var k := 4 if n == 32 else 8
		var b: Image = L.blank(n * k + 8, n * k + 8)
		L.R(b, 0, 0, b.get_width(), b.get_height(), "white")
		var sc: Image = s.duplicate()
		sc.resize(n * k, n * k, Image.INTERPOLATE_NEAREST)
		b.blend_rect(sc, Rect2i(Vector2i.ZERO, sc.get_size()), Vector2i(4, 4))
		img.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(xx, y + 14))
		xx += b.get_width() + 8
	# caixas (etiqueta) x3
	var bb := _load(ROOT + "assets/sprites/box/box_big.png").get_region(Rect2i(0, 0, 76, 62))
	var bs := _load(ROOT + "assets/sprites/box/box_small.png").get_region(Rect2i(0, 0, 48, 42))
	L.text(img, "CAIXA DA ESCOLA (X3)", xx + 10, y + 2, "y1", 1, "ink")
	put(img, bb, 3, xx + 10, y + 14)
	put(img, bs, 3, xx + 10 + 76 * 3 + 8, y + 14 + 60)
	y += 14 + 160 + 16
	var cells := [
		["GARAGEM SALVA: PAREDE", "f6a_parede_depois", Rect2i(620, 40, 200, 170)],
		["PEITO NA GARAGEM", "f6c2_simbolo_peito", Rect2i(80, 360, 600, 200)],
		["LUTA (PERFIL: NAS COSTAS)", "f6c2_simbolo_luta", Rect2i(540, 460, 220, 190)],
		["CRIACAO DO DISCIPULO", "f6b2_criar_cheio", Rect2i(116, 128, 182, 204)],
		["SELO GARAGEM SALVA", "f6a_vitoria_selo", Rect2i(820, 275, 140, 130)],
		["MURAL", "f6c2_tela_mural_9", Rect2i(60, 110, 800, 300)],
		["CENA (FOLHA VIRADA PARA A ESQUERDA)", "f6c1_saida_gym_J3", Rect2i(0, 300, 1280, 360)],
	]
	var cx := x
	var rowh := 0
	for c in cells:
		var r: Rect2i = c[2]
		if cx + r.size.x > W - 8:
			cx = x
			y += rowh + 22
			rowh = 0
		var sh := _load(sd + c[1] + ".png")
		L.text(img, c[0], cx, y + 2, "y1", 1, "ink")
		var reg := sh.get_region(r)
		img.blit_rect(reg, Rect2i(Vector2i.ZERO, reg.get_size()), Vector2i(cx, y + 14))
		cx += r.size.x + 10
		rowh = maxi(rowh, r.size.y + 14)
	img.crop(W, y + rowh + 10)
	img.save_png(ROOT + "docs/arte/mockups/fase6d3_simbolo_aplicado.png")
	print("ok ", img.get_size())
	quit()

func _load(p: String) -> Image:
	var i := Image.load_from_file(p)
	i.convert(Image.FORMAT_RGBA8)
	return i

func put(dst: Image, src: Image, k: int, x: int, y: int) -> void:
	var s: Image = src.duplicate()
	s.resize(src.get_width() * k, src.get_height() * k, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(x, y))
