extends SceneTree
## Fase 6d3 (Diretor de Arte): prancha ANTES/DEPOIS da garagem (pneus, escada, "retângulo preto", geladeira, carro).
## PLACEHOLDER gerado por código. Quem desenha o fundo é tools/art/make_mockup_fase6d2_layout.gd (funções garage_car,
## tire_stack, tire_standing, fridge); este script só monta a prancha.
##
## Ordem:
##   1) godot --headless --path <pasta_vazia> --quit-after 60 --script E:/Fightclicker/tools/art/make_mockup_fase6d2_layout.gd
##        -- --saida <pasta_tmp> --final            (grava garage_bg e as peças recortadas dele em assets/sprites)
##   2) copiar de <pasta_tmp>: fase6d2_layout_garagem_fechado_cheia.png -> docs/arte/mockups/fase6d3_garagem_cheia.png
##                             fase6d2_layout_garagem_fechado_pequena.png -> docs/arte/mockups/fase6d3_garagem_pequena.png
##   3) godot --headless --path <pasta_vazia> --script E:/Fightclicker/tools/art/make_mockup_fase6d3_garagem.gd
## ANTES = os mockups da 6d2 (docs/arte/mockups/fase6d2_fundo_garagem.png e fase6d2_layout_garagem_fechado_cheia.png).
## DEPOIS = assets/sprites/garage/garage_bg.png e fase6d3_garagem_cheia.png.

const ROOT := "E:/Fightclicker/"
const MK := ROOT + "docs/arte/mockups/"
var L

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var bg_a := _load(MK + "fase6d2_fundo_garagem.png")
	var bg_d := _load(ROOT + "assets/sprites/garage/garage_bg.png")
	var sc_a := _load(MK + "fase6d2_layout_garagem_fechado_cheia.png")
	var sc_d := _load(MK + "fase6d3_garagem_cheia.png")
	var pad := 8
	var lab := 14
	var W := pad * 3 + 1280
	var img: Image = L.blank(W, 1150)
	L.R(img, 0, 0, W, 1150, "d1")
	# linha 1: a sala com a equipe cheia
	cell(img, "ANTES (6D2)  EQUIPE CHEIA", sc_a, pad, pad)
	cell(img, "DEPOIS (6D3)  EQUIPE CHEIA", sc_d, pad * 2 + 640, pad)
	var y := pad * 2 + lab + 360
	# linha 2: carro e ala direita (geladeira + pneus), 2x
	var car := Rect2i(60, 150, 200, 85)
	var right := Rect2i(476, 112, 100, 116)
	var x := pad
	x = pair(img, "CARRO", bg_a, bg_d, car, 2, x, y) + pad
	pair(img, "GELADEIRA E PNEUS", bg_a, bg_d, right, 2, x, y)
	y += lab + right.size.y * 2 + pad
	# linha 3: parede direita (escada) e o "retângulo preto" (ralo)
	var wall := Rect2i(566, 96, 74, 234)
	var drain := Rect2i(366, 276, 56, 30)
	x = pad
	x = pair(img, "PAREDE DIREITA (ESCADA)", bg_a, bg_d, wall, 2, x, y) + pad
	x = pair(img, "RETANGULO PRETO = RALO", bg_a, bg_d, drain, 4, x, y) + pad
	var tx := x
	var notes := [
		"6D3, PEDIDO DO DONO:",
		"- CARRO: SEDA VELHO DE LADO, 126X58 (ERA 96X50),",
		"  RODAS COM CALOTA, VIDROS COM REFLEXO, FAROL,",
		"  LANTERNA, PARA-CHOQUES, FRISO, PORTAS, ANTENA.",
		"  LONA CINZA-AZULADA NA METADE DE TRAS.",
		"  A BANCADA SAIU (FICAVA ATRAS DO CARRO).",
		"- PNEUS: BANDA COM RANHURAS, BRILHO EM CIMA,",
		"  FURO NO DE CIMA E UM EM PE COM RODA DE ACO.",
		"- GELADEIRA: LADO E TAMPO A MOSTRA, PUXADORES",
		"  CROMADOS, MARCA, BILHETE, FOTO, IMAS, GRADE,",
		"  FERRUGEM E UM RADIO DE MADEIRA EM CIMA.",
		"- ESCADA: TIRADA.",
		"- RETANGULO PRETO: ERA O RALO DO CHAO. TIRADO.",
		"",
		"NENHUM PONTO DO MANIFEST MUDOU.",
	]
	var ty := y + lab
	for n in notes:
		L.text(img, n, tx, ty, "white" if not n.begins_with("NENHUM") else "gr3", 1, "ink")
		ty += 12
	var h := y + lab + wall.size.y * 2 + pad
	img.crop(W, h)
	img.save_png(MK + "fase6d3_garagem_antes_depois.png")
	print("prancha: ", MK + "fase6d3_garagem_antes_depois.png", " ", img.get_size())
	quit()

func _load(p: String) -> Image:
	var i := Image.load_from_file(p)
	i.convert(Image.FORMAT_RGBA8)
	return i

func cell(img: Image, titulo: String, src: Image, x: int, y: int) -> void:
	L.text(img, titulo, x, y + 3, "white", 1, "ink")
	img.blit_rect(src, Rect2i(0, 0, 640, 360), Vector2i(x, y + 14))

## antes e depois lado a lado, ampliados k vezes; devolve o x do fim
func pair(img: Image, titulo: String, a: Image, d: Image, r: Rect2i, k: int, x: int, y: int) -> int:
	L.text(img, titulo, x, y + 3, "y1", 1, "ink")
	var w := r.size.x * k
	for i in 2:
		var c: Image = (a if i == 0 else d).get_region(r)
		c.resize(w, r.size.y * k, Image.INTERPOLATE_NEAREST)
		var xx := x + i * (w + 4)
		img.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(xx, y + 14))
		L.R(img, xx, y + 14, 40, 9, "ink")
		L.text(img, "ANTES" if i == 0 else "DEPOIS", xx + 2, y + 15, "white" if i == 0 else "gr3")
	return x + 2 * w + 4
