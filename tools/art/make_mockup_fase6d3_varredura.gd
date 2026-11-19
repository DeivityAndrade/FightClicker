extends SceneTree
## Fase 6d3 (Diretor de Arte): prancha ANTES/DEPOIS da varredura de arte. PLACEHOLDER gerado por código.
## Usa as capturas do verificador de telas (1280x720) de antes e de depois das correções:
##   godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tools/ui/ui_audit.gd
##       -- --estados <lista> --saida <pasta>        (uma vez antes, uma vez depois, com APPDATA temporário)
##   godot --headless --path <pasta_vazia> --script E:/Fightclicker/tools/art/make_mockup_fase6d3_varredura.gd
##       -- <pasta_antes> <pasta_depois>
## Grava docs/arte/mockups/fase6d3_varredura_antes_depois.png (telas reduzidas a 640x360) e
## fase6d3_varredura_detalhes.png (recortes ampliados das peças trocadas).

const ROOT := "E:/Fightclicker/"
const MK := ROOT + "docs/arte/mockups/"
var L

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var a := OS.get_cmdline_user_args()
	var da: String = a[0].trim_suffix("/") + "/"
	var dd: String = a[1].trim_suffix("/") + "/"
	var telas := [["f6d2_garagem_cheia", "GARAGEM CHEIA"], ["f6d2_academia_cheia", "ACADEMIA CHEIA"],
		["luta_meio", "LUTA"], ["f6a_parede_depois", "GARAGEM SALVA (SIMBOLO NA PAREDE)"]]
	var pad := 8
	var lab := 14
	var W := pad * 3 + 1280
	var H := pad + telas.size() * (lab + 360 + pad)
	var img: Image = L.blank(W, H)
	L.R(img, 0, 0, W, H, "d1")
	var y := pad
	for t in telas:
		for i in 2:
			var s := _load((da if i == 0 else dd) + t[0] + ".png")
			s.resize(640, 360, Image.INTERPOLATE_NEAREST)
			var x := pad + i * (640 + pad)
			L.text(img, ("ANTES  " if i == 0 else "DEPOIS  ") + t[1], x, y + 3, "white" if i == 0 else "gr3", 1, "ink")
			img.blit_rect(s, Rect2i(0, 0, 640, 360), Vector2i(x, y + lab))
		y += lab + 360 + pad
	img.save_png(MK + "fase6d3_varredura_antes_depois.png")
	# detalhes (recortes das capturas em 1280x720, ampliados 2x)
	var det := [["f6a_parede_depois", Rect2i(560, 40, 300, 200), "SIMBOLO DA ESCOLA E LAMPADA"],
		["f6d2_academia_cheia", Rect2i(500, 60, 200, 240), "NOME E ESPELHO DA ACADEMIA"],
		["luta_meio", Rect2i(360, 120, 720, 340), "CHAPA DA ARENA, 07, LAMPADAS"],
		["f6d2_garagem_cheia", Rect2i(150, 320, 820, 340), "CARRO SEM LONA, GIZ E OLEO NO CHAO"]]
	var Hd := pad
	for d in det:
		Hd += lab + d[1].size.y + pad
	var W2 := pad * 3 + 2 * 820
	var im2: Image = L.blank(W2, Hd)
	L.R(im2, 0, 0, W2, Hd, "d1")
	y = pad
	for d in det:
		var r: Rect2i = d[1]
		for i in 2:
			var s := _load((da if i == 0 else dd) + d[0] + ".png").get_region(r)
			var x := pad + i * (820 + pad)
			L.text(im2, ("ANTES  " if i == 0 else "DEPOIS  ") + d[2], x, y + 3, "white" if i == 0 else "gr3", 1, "ink")
			im2.blit_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(x, y + lab))
		y += lab + r.size.y + pad
	im2.save_png(MK + "fase6d3_varredura_detalhes.png")
	print("prancha: ", MK, "fase6d3_varredura_antes_depois.png e _detalhes.png")
	quit()

func _load(p: String) -> Image:
	var i := Image.load_from_file(p)
	i.convert(Image.FORMAT_RGBA8)
	return i
