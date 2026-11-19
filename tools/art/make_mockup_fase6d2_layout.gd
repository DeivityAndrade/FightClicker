extends SceneTree
## Fase 6d2 (Diretor de Arte): PROPOSTA de sala larga de verdade (640x360) e de pontos novos. PLACEHOLDER gerado por código.
## Nada aqui entra no jogo: grava só imagens em docs/arte/mockups/fase6d2_*.png. Proposta: docs/arte/fase6d2-layout.md.
##
## Rodar a partir de uma pasta com um project.godot vazio (não dispara import no projeto):
##   godot --headless --path <pasta_vazia> --quit-after 60 --script E:/Fightclicker/tools/art/make_mockup_fase6d2_layout.gd
##       [-- --saida <pasta>] [--final [--assets <pasta>]]
## --saida: onde vão os mockups (padrão docs/arte/mockups/). --final: grava também os sprites de verdade em assets/sprites
## (ou em --assets, para testar): fundos 640x360, luz do dia, sombra da porta, porta e metade escura da academia e a luz
## nova dos aparelhos que mudaram de ponto. Sempre parte dos originais em tools/art/fonte_6d2/. Manifest: tools/art/manifest_6d2.py.
##
## Como o fundo largo é feito:
## - a parede do fundo cresce para x 70..569 (era 170..469); mesmo ponto de fuga (320,-28), mesma linha do chão (y 220);
## - o miolo da parede de hoje (x 171..469, y 18..219) é colado do garage_bg / gym_bg (porta, carro, prateleira, espelho...
##   ficam onde estão: nenhuma cena e nenhum ponto de parede muda);
## - duas colunas (pilares) escondem as emendas em x 170 e 470; paredes novas, paredes laterais e o chão inteiro são novos;
## - o chão vai até y 329 (a faixa de baixo da opção C começa em 330): 110 px de fundo, contra 70 de hoje.
## Ele também confere os pontos novos (pixels opacos de todos os quadros) e imprime o relatório.

const ROOT := "E:/Fightclicker/"
var OUT := ROOT + "docs/arte/mockups/"
## originais de antes da 6d2 (fundos 384x272 e as peças tiradas deles): o gerador sempre parte daqui, então pode rodar de novo
const FONTE := ROOT + "tools/art/fonte_6d2/"
var FINAL := false
var ASSETS := ROOT + "assets/sprites/"
var L
var MAN := {}

const VPX := 320.0
const VPY := -28.0
const FLOOR_Y := 220
const BW0 := 70
const BW1 := 570
const OLD := Rect2i(128, 18, 384, 272)
const COPY := Rect2i(171, 18, 299, 202)     # miolo da parede de hoje (x 171..469, y 18..219)
const PIL_L := Rect2i(164, 18, 11, 204)     # pilar esquerdo x 164..174 (emenda em 170)
const PIL_R := Rect2i(468, 18, 11, 204)     # pilar direito x 468..478 (emenda em 470)
const STRIP_Y := 330
const PANEL_X := 506                        # painel fixado da opção C (x 506..639)
const ALVO := Rect2i(273, 150, 98, 142)     # x 281..362 + 8 de folga; y 150..291
const LIGHT_C := Vector2(305, 90)
const TUBES := [Vector2i(218, 34), Vector2i(422, 34)]
const TUBES_NEW := [Vector2i(104, 34), Vector2i(536, 34)]

# ------------------------------------------------------------------ PONTOS PROPOSTOS (iguais nas duas salas)
const P_FIGHTER := Vector2i(303, 272)
const P_BAG := Vector2i(336, 183)
const P_BAG_SIDE := Vector2i(258, 160)
const P_ROPE := Vector2i(296, 166)
const P_SB_WALL := Vector2i(436, 46)
const P_COACH := Vector2i(196, 236)          # Osmar: igual
const P_PHOTO := Vector2i(212, 158)          # foto da academia: igual (as folhas do Osmar dependem da distância)
const P_MURAL := Vector2i(176, 128)          # mural: igual
var P := {
	"mentor": Vector2i(132, 254),             # John / último sentado (era 254,252); caixote = +(-16,-20)
	"mentor_2": Vector2i(62, 256),            # 2º mentor de pé (era 150,262)
	"neighbor_1": Vector2i(72, 322),          # era 176,284
	"neighbor_2": Vector2i(126, 322),         # era 220,258
	"neighbor_3": Vector2i(590, 322),         # era 488,286 (só com o painel solto)
	"uncle_1": Vector2i(400, 324),            # era 455,236
	"uncle_2": Vector2i(484, 262),            # era 398,230
	"coach_1": Vector2i(548, 250),            # Prof. Nelson, era 394,280 (só com o painel solto)
	"treadmill_side": Vector2i(466, 324),     # esteira encostada (era 445,267)
	"dummy_rest": Vector2i(192, 318),         # boneco deitado no tatame (era 228,283)
	"box_treadmill": Vector2i(466, 324),      # caixa grande = onde a esteira fica
	"box_art": Vector2i(192, 318),            # caixa da arte = onde o boneco fica (pera usa a pequena no mesmo ponto)
	"box_glove": Vector2i(292, 327),          # na frente do lutador, à esquerda
	"box_rope": Vector2i(348, 327),           # na frente do lutador, à direita
}
const CRATE_OFF := Vector2i(-16, -20)
## 6d3 (bug B1 do QA): na GARAGEM o carro novo fica no fundo à esquerda (x 82..241); quem ficava na frente dele mudou de ponto.
## Na academia continua tudo como na 6d2. pt(local, chave) devolve o ponto certo.
var G6D3 := {
	"coach": Vector2i(52, 258),       # Osmar: encostado na frente do carro (era 196,236)
	"mentor": Vector2i(210, 254),     # John / último sentado: atrás do carro, perto do saco (era 132,254); caixote = +(-16,-20)
	"mentor_2": Vector2i(26, 304),    # 2º mentor de pé: canto da frente à esquerda (era 62,256)
}
func pt(local: String, k: String) -> Vector2i:
	if local == "garagem" and G6D3.has(k):
		return G6D3[k]
	return P_COACH if k == "coach" else P[k]
var CAR_PX := {}
const GPIV := Vector2i(22, 67)
const OLD_P := {
	"mentor": Vector2i(254, 252), "mentor_2": Vector2i(150, 262), "neighbor_1": Vector2i(176, 284),
	"neighbor_2": Vector2i(220, 258), "neighbor_3": Vector2i(488, 286), "uncle_1": Vector2i(455, 236),
	"uncle_2": Vector2i(398, 230), "coach_1": Vector2i(394, 280), "treadmill_side": Vector2i(445, 267),
	"dummy_rest": Vector2i(228, 283), "box_treadmill": Vector2i(445, 268), "box_art": Vector2i(204, 283),
	"box_glove": Vector2i(386, 280), "box_rope": Vector2i(424, 287),
}
const CREW := ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2", "coach_1"]
const M2_LOOK := ["skin_4", "black", "blue"]
const CUR_LOOK := ["skin_1", "copper", "purple"]
# caminhos: porta -> centro (garagem e academia) e saída do mentor (caixote -> porta)
const PATHS := {
	"garagem": [[Vector2i(423, 221), Vector2i(410, 236)], [Vector2i(410, 236), Vector2i(392, 258)], [Vector2i(392, 258), Vector2i(303, 272)], [Vector2i(410, 236), Vector2i(303, 272)]],
	"academia": [[Vector2i(428, 224), Vector2i(400, 246)], [Vector2i(400, 246), Vector2i(352, 262)], [Vector2i(352, 262), Vector2i(303, 272)], [Vector2i(428, 224), Vector2i(303, 272)]],
}

var BG := {}
var REF := {}

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--saida" and i + 1 < args.size():
			OUT = args[i + 1].trim_suffix("/") + "/"
		if args[i] == "--final":
			FINAL = true
		if args[i] == "--assets" and i + 1 < args.size():
			ASSETS = args[i + 1].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	var f := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.READ)
	MAN = JSON.parse_string(f.get_as_text())
	for k in ["garagem", "academia", "garagem_loja"]:
		REF[k] = _load(ROOT + "docs/arte/mockups/fase6d_ref_%s.png" % k)
	BG["garagem"] = build_garage()
	BG["academia"] = build_gym()
	if FINAL:
		write_assets()
	for k in BG:
		BG[k].save_png(OUT + "fase6d2_fundo_%s.png" % k)
		_x2(BG[k]).save_png(OUT + "fase6d2_fundo_%s_x2.png" % k)
	var probs := 0
	for local in ["garagem", "academia"]:
		probs += check(local)
		for equipe in ["cheia", "pequena"]:
			var room := compose(local, equipe)
			for estado in ["fechado", "fixado"]:
				var img: Image = room.duplicate()
				chrome(img, local, equipe, estado == "fixado")
				var nome := "fase6d2_layout_%s_%s_%s" % [local, estado, equipe]
				img.save_png(OUT + nome + ".png")
				_x2(img).save_png(OUT + nome + "_x2.png")
		conferencia(local)
		comparacao(local)
	print("=> %d problema(s)" % probs)
	quit()

# ================================================================== util
func _load(p: String) -> Image:
	var img := Image.load_from_file(p)
	img.convert(Image.FORMAT_RGBA8)
	return img

func _x2(img: Image, k := 2) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func spr(id: String) -> Dictionary:
	return MAN.sprites.get(id, {})

func res_abs(r: String) -> String:
	return ROOT + r.replace("res://", "")

var _cache := {}
func frame_of(id: String, q := 0) -> Image:
	var key := "%s#%d" % [id, q]
	if _cache.has(key):
		return _cache[key]
	var e := spr(id)
	var img := _load(res_abs(str(e.file)))
	var fw := int(e.frame_size[0])
	var fh := int(e.frame_size[1])
	var n := maxi(img.get_width() / fw, 1)
	var out := img.get_region(Rect2i(clampi(q, 0, n - 1) * fw, 0, fw, fh))
	_cache[key] = out
	return out

func nframes(id: String) -> int:
	return int(spr(id).get("frames", 1))

func pivot_of(id: String) -> Vector2i:
	var e := spr(id)
	return Vector2i(int(e.pivot[0]), int(e.pivot[1])) if e.has("pivot") else GPIV

func blend(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func recolor_map(look: Array) -> Dictionary:
	var pb: Dictionary = MAN.by_data_id.disciple_palette
	var m := {}
	var fields := ["skin", "hair_color", "shorts_color"]
	for i in 3:
		var keys: Dictionary = pb["keys"][fields[i]]
		var ramp := {}
		for o in pb.options[fields[i]]:
			if o.id == look[i]:
				ramp = o.ramp
		for slot in keys:
			if ramp.has(slot):
				m[(keys[slot] as String).substr(1).to_lower()] = Color.html(ramp[slot])
	return m

func layered(id: String, q: int, look: Array) -> Image:
	var key := "L%s#%d#%s" % [id, q, str(look)]
	if _cache.has(key):
		return _cache[key]
	var e := spr(id)
	var fw := int(e.frame_size[0])
	var fh := int(e.frame_size[1])
	var lay: Dictionary = e.layers
	var body := _region(res_abs(lay.body), fw, fh, q)
	var head := _region(res_abs(lay.head.short), fw, fh, q)
	var mask := _region(res_abs(lay.front_mask), fw, fh, q)
	var rc := recolor_map(look)
	var out := Image.create_empty(fw, fh, false, Image.FORMAT_RGBA8)
	for y in fh:
		for x in fw:
			var c := body.get_pixel(x, y)
			var hc := head.get_pixel(x, y)
			if hc.a > 0.0:
				c = hc
			if mask.get_pixel(x, y).a > 0.0:
				c = body.get_pixel(x, y)
			if c.a > 0.0:
				var hx := c.to_html(false).to_lower()
				if rc.has(hx):
					c = rc[hx]
			out.set_pixel(x, y, c)
	_cache[key] = out
	return out

func _region(path: String, fw: int, fh: int, q: int) -> Image:
	var img := _load(path)
	var n := maxi(img.get_width() / fw, 1)
	return img.get_region(Rect2i(clampi(q, 0, n - 1) * fw, 0, fw, fh))

func bayer(x: int, y: int) -> float:
	return (float(L.BAYER[y & 3][x & 3]) + 0.5) / 16.0

func floor_hw(y: float) -> float:
	return 250.0 * (y - VPY) / (FLOOR_Y - VPY)

## escala da parede lateral na coluna x (1 = parede do fundo)
func side_s(x: float) -> float:
	return absf(VPX - x) / (VPX - BW0)

## altura na parede lateral (coluna x) de um ponto que na parede do fundo estaria em yb
func side_y(x: float, yb: float) -> float:
	return VPY + (yb - VPY) * side_s(x)

func on_floor(x: int, y: int) -> bool:
	return y >= FLOOR_Y and absf(x + 0.5 - VPX) <= floor_hw(y + 0.5)

# ------------------------------------------------------------------ luz
## Luzes: [centro, raio, ysq, força, offset, max]. O passo é o da luz mais forte (dither Bayer nas bordas das faixas).
func light_area(img: Image, area: Rect2i, lights: Array, min_step: int, skip := Rect2i()) -> void:
	for y in range(maxi(area.position.y, 0), mini(area.end.y, img.get_height())):
		for x in range(maxi(area.position.x, 0), mini(area.end.x, img.get_width())):
			if skip.has_area() and skip.has_point(Vector2i(x, y)):
				continue
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var st := light_step(x, y, lights, min_step)
			if st != 0:
				img.set_pixel(x, y, L.shade(c, st))

func light_step(x: int, y: int, lights: Array, min_step: int) -> int:
	var best := -99
	for lt in lights:
		var cc: Vector2 = lt[0]
		var d := Vector2(x - cc.x, (y - cc.y) * float(lt[2])).length() / float(lt[1])
		var lf: float = float(lt[4]) - d * float(lt[3])
		var base := floorf(lf)
		var fr := clampf((lf - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
		var st := int(base) + (1 if fr > bayer(x, y) else 0)
		st = clampi(st, min_step, int(lt[5]))
		best = maxi(best, st)
	return best

var GARAGE_LIGHTS := [
	[LIGHT_C, 300.0, 1.1, 3.6, 0.9, 1],           # a lâmpada de hoje (mesma conta do garage_bg)
	[Vector2(34, 176), 150.0, 0.9, 1.9, 0.35, 0],  # janela basculante da parede esquerda (dia)
	[Vector2(540, 70), 170.0, 1.0, 2.0, 0.25, 0],  # luminária de obra presa na viga, à direita
]

func gym_step(x: int, y: int) -> int:
	var best := -9.0
	for t: Vector2i in TUBES + TUBES_NEW:
		var d := Vector2(x - t.x, (y - t.y - 30) * 0.8).length() / 260.0
		best = maxf(best, 0.95 - d * 1.9)
	best -= clampf(float(y - 250) / 120.0, 0.0, 0.35)
	var base := floorf(best)
	var fr := clampf((best - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
	return clampi(int(base) + (1 if fr > bayer(x, y) else 0), -2, 1)

func gym_light(img: Image, area: Rect2i, skip := Rect2i()) -> void:
	for y in range(maxi(area.position.y, 0), mini(area.end.y, img.get_height())):
		for x in range(maxi(area.position.x, 0), mini(area.end.x, img.get_width())):
			if skip.has_area() and skip.has_point(Vector2i(x, y)):
				continue
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var st := gym_step(x, y)
			if st != 0:
				img.set_pixel(x, y, L.shade(c, st))

func paste_old(img: Image, old: Image, r: Rect2i) -> void:
	img.blit_rect(old, r, r.position)

# ================================================================== GARAGEM LARGA
func build_garage() -> Image:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	var rng := RandomNumberGenerator.new()
	rng.seed = 6402
	garage_back_wall(img, rng)
	garage_side_walls(img, rng)
	garage_floor(img, rng)
	garage_beam(img)
	garage_props(img, rng)
	light_area(img, Rect2i(0, 0, 640, 360), GARAGE_LIGHTS, -3)
	var pre: Image = img.duplicate()
	var old := _load(FONTE + "garage_bg.png")
	var full_old: Image = L.blank(640, 360)
	full_old.blit_rect(old, Rect2i(Vector2i.ZERO, old.get_size()), OLD.position)
	paste_old(img, full_old, COPY)
	# 6d3: o carrinho de 384 px (que não lia como carro) sai; ali volta a parede nova, e o carro grande entra por cima
	img.blit_rect(pre, OLD_CAR, OLD_CAR.position)
	garage_after_light(img)
	for pr: Rect2i in [PIL_L, PIL_R]:
		garage_pillar(img, pr)
	garage_car(img)
	return img

# ================================================================== 6d3: carro velho grande, pneus, geladeira
## Pedido do dono (6d3): carro maior e legível (rodas, janelas, faróis, carroceria), pneus com cara de pneu, geladeira com
## personalidade, sem a escada e sem o ralo (o "retângulo preto"). O carro é sedã antigo de lado, frente para a esquerda,
## com a lona cinza-azulada (a cor da 6d2) cobrindo a metade de trás; a frente fica à mostra.
## Fica ATRÁS de todo mundo (é fundo): x 82..239, y 167..229, longe da zona do alvo (x 273..370).
const OLD_CAR := Rect2i(176, 170, 104, 50)    # onde estava o carro de antes (só parede: y 170..219)
const CAR_X0 := 84
const CAR_X1 := 232
const CAR_G := 227                             # pneus tocam o chão aqui
const CAR_WF := Vector2(112, 216)              # roda da frente
const CAR_WR := Vector2(204, 216)              # roda de trás

func car_top(x: int) -> int:
	if x < 128:
		return 191
	if x < 146:
		return int(round(lerpf(190, 171, float(x - 128) / 18.0)))
	if x <= 192:
		return 171
	if x <= 208:
		return int(round(lerpf(171, 190, float(x - 192) / 16.0)))
	return 191

func garage_car(img: Image) -> void:
	# sombra no chão (passos de rampa, sem alpha): miolo 2 passos, borda 1 passo em dither
	for y in range(219, 232):
		for x in range(70, 252):
			var d := Vector2((x + 0.5 - 132.0) / 66.0, (y + 0.5 - 226.0) / 5.0).length()
			if d > 1.0 or not on_floor(x, y):
				continue
			var n := -2 if d < 0.7 else (-1 if bayer(x, y) > (d - 0.7) / 0.3 * 0.8 else 0)
			if n != 0:
				img.set_pixel(x, y, L.shade(img.get_pixel(x, y), n))
	var c: Image = L.blank(640, 360)
	# ---- lataria (lado), azul desbotado
	for y in range(191, 220):
		var xa := CAR_X0 + 1
		var xb := CAR_X1
		if y <= 192:
			xa += 2
			xb -= 1
		if y >= 218:
			xa += 1
			xb -= 1
		var tone := "b2"
		if y <= 192:
			tone = "b3"
		elif y >= 211:
			tone = "b1"
		L.R(c, xa, y, xb - xa + 1, 1, tone)
	L.R(c, CAR_X0 + 1, 219, CAR_X1 - CAR_X0 - 1, 1, "b0")
	# cabine
	for y in range(171, 191):
		var xa := 999
		var xb := -1
		for x in range(126, 212):
			if car_top(x) <= y:
				xa = mini(xa, x)
				xb = maxi(xb, x)
		L.R(c, xa, y, xb - xa + 1, 1, "b3" if y <= 172 else "b2")
	# vidros escuros com reflexo em diagonal; coluna do meio
	for y in range(175, 189):
		var xa := 999
		var xb := -1
		for x in range(126, 212):
			if car_top(x) <= y - 4:
				xa = mini(xa, x)
				xb = maxi(xb, x)
		for x in range(xa + 1, xb):
			if x >= 165 and x <= 169:
				continue
			var t := (x + (y - 175)) % 22
			L.P(c, x, y, "st3" if t < 2 else ("st1" if t < 4 else "b0"))
	L.R(c, 130, 189, 78, 1, "b1")
	# frisos e portas
	L.R(c, CAR_X0 + 2, 199, CAR_X1 - CAR_X0 - 3, 1, "st3")
	L.R(c, CAR_X0 + 2, 200, CAR_X1 - CAR_X0 - 3, 1, "st1")
	for sx: int in [129, 167]:
		L.R(c, sx, 191 if sx == 129 else 175, 1, (215 - 191) if sx == 129 else (215 - 175), "b0")
	L.R(c, 154, 195, 4, 1, "st3"); L.P(c, 154, 196, "st1")
	L.R(c, 192, 195, 4, 1, "st3"); L.P(c, 192, 196, "st1")
	L.R(c, 130, 185, 3, 3, "b1"); L.P(c, 130, 185, "b3")                       # retrovisor
	L.line(c, 100, 190, 96, 172, "st2")                                       # antena
	L.R(c, 86, 191, 30, 1, "b3")                                              # brilho do capô
	# farol, pisca, para-choques cromados
	L.R(c, CAR_X0, 194, 3, 4, "y1"); L.R(c, CAR_X0, 195, 2, 2, "y2"); L.R(c, CAR_X0, 198, 2, 2, "y0")
	L.R(c, CAR_X0 - 3, 204, 8, 5, "st2"); L.R(c, CAR_X0 - 3, 204, 8, 1, "st3"); L.R(c, CAR_X0 - 3, 208, 8, 1, "st0")
	# traseira (a face virada para o centro, que a perspectiva mostra): lanterna e para-choque
	L.R(c, CAR_X1 + 1, 192, 5, 27, "b1"); L.R(c, CAR_X1 + 1, 219, 5, 1, "b0")
	L.R(c, CAR_X1 + 1, 196, 4, 5, "r2"); L.R(c, CAR_X1 + 1, 196, 4, 1, "r3"); L.R(c, CAR_X1 + 1, 200, 4, 1, "r1")
	L.R(c, CAR_X1 - 3, 204, 10, 5, "st2"); L.R(c, CAR_X1 - 3, 204, 10, 1, "st3"); L.R(c, CAR_X1 - 3, 208, 10, 1, "st0")
	# ferrugem no estribo
	for p: Vector2i in [Vector2i(96, 216), Vector2i(98, 217), Vector2i(97, 218), Vector2i(132, 217), Vector2i(134, 216),
			Vector2i(176, 218), Vector2i(179, 217), Vector2i(222, 216), Vector2i(224, 217)]:
		L.P(c, p.x, p.y, "br1")
	L.P(c, 133, 218, "br2"); L.P(c, 223, 218, "br2")
	# caixas de roda (escuras) e rodas
	for w: Vector2 in [CAR_WF, CAR_WR]:
		for y in range(int(w.y) - 15, 220):
			for x in range(int(w.x) - 15, int(w.x) + 16):
				var d := Vector2(x + 0.5 - w.x, y + 0.5 - w.y).length()
				if d <= 14.0:
					L.P(c, x, y, "d1")
				elif d <= 15.0 and c.get_pixel(x, y).a > 0.0:
					L.P(c, x, y, "b1")
		car_wheel(c, w, w == CAR_WR)
	# fundo escuro do carro entre as rodas (esconde a sapata do pilar e "assenta" o carro no chão)
	for x in range(CAR_X0 + 4, CAR_X1 + 2):
		for y in range(220, 224):
			if c.get_pixel(x, y).a == 0.0:
				L.P(c, x, y, "d1" if y < 222 else "ink")
	# 6d3 (pedido do dono): a lona volta, na cor e no caimento da garagem da 6d2 (pano cinza-azulado, rampa st), cobrindo a
	# metade de trás: teto de trás, vidro de trás e porta-malas, caindo pelo lado até cobrir o alto da roda de trás. A frente
	# (farol, roda, para-choque, porta da frente) fica à mostra. Borda da frente em diagonal com rolo claro, dobras verticais
	# irregulares, barra ondulada e uma corda amarrada.
	car_tarp(c)
	c = car_squeeze(c)
	light_area(c, Rect2i(60, 160, 190, 75), GARAGE_LIGHTS, -1)
	var o: Image = L.outlined(c.get_region(Rect2i(60, 160, 190, 75)))
	blend(img, o, 59, 159)
	CAR_PX.clear()
	for yy in o.get_height():
		for xx in o.get_width():
			if o.get_pixel(xx, yy).a > 0.0:
				CAR_PX[Vector2i(59 + xx, 159 + yy)] = true

## 6d3 (bug B1): o carro encolhe 25 px no miolo das portas (tira 12 colunas da porta da frente e 13 da de trás; frente, rodas,
## traseira e lona ficam inteiras) e anda 5 px para a esquerda: fica em x 75..211, entre o John sentado (agora à esquerda do
## nariz) e o Osmar. Valores finais: tira 36 colunas e anda 11 px (x 69..194). Os pontos estão em G6D3.
const CAR_CUTS := [[172, 19], [136, 17]]     # [x inicial, largura], da direita para a esquerda
const CAR_SHIFT := -11

func car_squeeze(c: Image) -> Image:
	var src: Image = c
	for cut: Array in CAR_CUTS:
		var x0: int = cut[0]
		var w: int = cut[1]
		var out: Image = L.blank(640, 360)
		out.blit_rect(src, Rect2i(0, 0, x0, 360), Vector2i.ZERO)
		out.blit_rect(src, Rect2i(x0 + w, 0, 640 - x0 - w, 360), Vector2i(x0, 0))
		src = out
	var moved: Image = L.blank(640, 360)
	moved.blit_rect(src, Rect2i(0, 0, 640, 360), Vector2i(CAR_SHIFT, 0))
	return moved

const TARP_X0 := 150
const TARP_FOLDS := [171, 186, 199, 213, 226]

func tarp_hem(x: int) -> int:
	var h := 212 if x >= 176 else int(round(lerpf(203, 212, float(x - TARP_X0) / 26.0)))
	if x > CAR_X1:
		h = 214
	return h + (1 if sin(float(x) * 0.55) > 0.35 else 0)

func car_tarp(c: Image) -> void:
	for x in range(TARP_X0, 242):
		var top := (car_top(x) if x <= CAR_X1 else 191) - 1
		if x > 196 and x < 214:
			top += 1                                  # o pano afunda no vidro de trás
		var hem := tarp_hem(x)
		for y in range(top, hem + 1):
			var xl := float(TARP_X0) + float(y - 170) * 0.5
			var dx := float(x) - xl
			if dx < 0.0:
				# sombra do pano na lataria, logo à frente da borda
				if dx >= -2.0 and c.get_pixel(x, y).a > 0.0:
					c.set_pixel(x, y, L.shade(c.get_pixel(x, y), -1))
				continue
			var tone := "st2"
			if y > 201 and bayer(x, y) < float(y - 201) / 9.0:
				tone = "st1"                           # o pano pende: embaixo mais escuro (volume)
			if dx < 1.0:
				tone = "st1"
			elif dx < 2.5:
				tone = "st3"                           # rolo da borda da frente
			elif y <= top + 1:
				tone = "st3"
			elif y >= hem:
				tone = "st0"
			elif y >= hem - 3:
				tone = "st1"
			else:
				for fx: int in TARP_FOLDS:
					var fxx := fx + (y - top) / 8
					if x == fxx:
						tone = "st1"
					elif x == fxx - 1 and y < hem - 4:
						tone = "st3"
			c.set_pixel(x, y, L.col(tone))
	# corda amarrada em volta, com o nó
	for x in range(158, 242):
		var yy := 199 + (1 if x > 200 else 0)
		if c.get_pixel(x, yy).a > 0.0 and x >= int(TARP_X0 + (yy - 170) * 0.5) + 3:
			L.P(c, x, yy, "br3" if x % 3 else "br2")
	L.R(c, 216, 198, 3, 3, "br2"); L.P(c, 217, 198, "br3"); L.P(c, 215, 201, "br2"); L.P(c, 219, 202, "br2")

## pneu com calota: banda escura, ranhuras, lateral com brilho em cima, calota cromada (a de trás meio murcha)
func car_wheel(c: Image, w: Vector2, flat: bool) -> void:
	var r := 11.0
	for y in range(int(w.y) - 12, CAR_G + 1):
		for x in range(int(w.x) - 13, int(w.x) + 14):
			var v := Vector2(x + 0.5 - w.x, y + 0.5 - w.y)
			if flat and v.y > 7.0:
				v.y = 7.0 + (v.y - 7.0) * 1.6
				v.x *= 0.92
			var d := v.length()
			if d > r or y > CAR_G:
				continue
			var tone := "d1"
			if d > r - 1.5:
				tone = "ink" if (x + y) % 3 == 0 else "d1"      # banda com ranhura
			elif d > r - 3.5:
				tone = "d2" if v.y < -2.0 and v.x > -6.0 else "d1"
				if v.y < -6.0 and v.x > 0.0:
					tone = "g0"
			elif d > 6.5:
				tone = "d2"
			elif d > 5.0:
				tone = "st1"
			elif d > 1.6:
				tone = "st2" if v.x + v.y > 0.0 else "st3"
			else:
				tone = "st0"
			L.P(c, x, y, tone)
	for a in 4:
		var p := w + Vector2.from_angle(a * PI / 2.0 + PI / 4.0) * 3.4
		L.P(c, int(p.x), int(p.y), "st1")

## pilha de pneus deitados, vista um pouco de cima (ponto de fuga em y -28): banda com ranhuras, brilho da luminária
func tire_stack(img: Image, cx: int, base: int, n: int) -> void:
	var rx := 18.0
	var ry := 4.0
	for i in n:
		var t := float(base - 4 - 8 - i * 9)          # centro da elipse de cima deste pneu
		var sx := (i % 2) * 2 - 1                      # pneus um pouco desencontrados
		for x in range(-18, 19):
			var nx := (x + 0.5) / rx
			if absf(nx) > 1.0:
				continue
			var e := sqrt(1.0 - nx * nx) * ry
			var ya := int(round(t + e))
			var yb := int(round(t + 8.0 + e))
			for y in range(ya, yb + 1):
				var k := y - ya
				var tone := "d2"
				if k == 0:
					tone = "d2"
				elif k <= 2:
					tone = ("g1" if k == 1 and nx > 0.05 and nx < 0.45 else "g0") if nx > -0.35 and nx < 0.7 else "d2"
				elif k >= 7:
					tone = "ink"
				elif k == 6:
					tone = "d1"
				if absf(nx) > 0.82 and tone != "ink":
					tone = "d1"
				# ranhuras da banda: traços em zigue-zague, mais juntos nas bordas (é um cilindro)
				var u := asin(clampf(nx, -1.0, 1.0)) * 7.0
				if k >= 3 and k <= 5 and int(floor(u + (0.5 if k == 4 else 0.0))) % 2 == 0 and absf(nx) < 0.9:
					tone = "ink" if tone == "d1" else "d1"
				L.P(img, cx + sx + x, y, tone)
	# face de cima do pneu do topo: lateral, furo, letras
	var tt := float(base - 4 - 8 - (n - 1) * 9)
	var sx2 := ((n - 1) % 2) * 2 - 1
	L.ellipse(img, cx + sx2, tt, rx, ry, "d2")
	L.ring(img, cx + sx2, tt, rx, ry, 1.0, "d1")
	for x in range(-16, 17):
		var nx := (x + 0.5) / rx
		var e := sqrt(maxf(1.0 - nx * nx, 0.0)) * ry
		if nx > -0.5 and nx < 0.8:
			L.P(img, cx + sx2 + x, int(round(tt - e)) + 1, "g0")
	L.ellipse(img, cx + sx2, tt + 0.5, 10.0, 2.4, "ink")
	L.ring(img, cx + sx2, tt + 0.5, 11.0, 3.0, 1.0, "d1")
	for x in range(-6, 7, 3):
		L.R(img, cx + sx2 + x, int(tt) + 3, 2, 1, "g1")

## pneu em pé (com a roda de aço), encostado na pilha
func tire_standing(img: Image, cx: float, cy: float) -> void:
	for y in range(int(cy) - 12, int(cy) + 12):
		for x in range(int(cx) - 11, int(cx) + 12):
			var v := Vector2((x + 0.5 - cx) / 10.0, (y + 0.5 - cy) / 11.0)
			var d := v.length()
			if d > 1.0:
				continue
			var tone := "d1"
			if d > 0.88:
				tone = "ink" if (x + y) % 2 == 0 else "d1"
			elif d > 0.62:
				tone = "g0" if v.y < -0.35 and v.x > -0.2 else "d2"
			elif d > 0.55:
				tone = "d1"
			elif d > 0.22:
				tone = "st2" if v.x - v.y > 0.1 else "st1"
			else:
				tone = "st0"
			L.P(img, x, y, tone)
	for a in 5:
		var p := Vector2(cx, cy) + Vector2.from_angle(a * TAU / 5.0) * Vector2(4.0, 4.4)
		L.P(img, int(p.x), int(p.y), "ink")

## geladeira velha: lado e tampo à mostra (perspectiva), cromado, ímãs, bilhete, foto, rádio de madeira em cima
func fridge(img: Image) -> void:
	var fx := 488
	var fw := 30
	var top := 148
	var bot := 221
	# lado esquerdo (vai para a parede, encolhe)
	for i in 5:
		var x := fx - 5 + i
		var ya := top - 3 + int(round(i * 0.6))
		var yb := bot - 5 + i
		L.R(img, x, ya, 1, yb - ya + 1, "g3" if i >= 3 else "g2")
	# tampo
	for k in 3:
		L.R(img, fx - 4 + k * 2, top - 3 + k, fw - 1, 1, "white")
	# frente
	L.R(img, fx, top, fw, bot - top + 1, "cream")
	L.R(img, fx, top, fw, 1, "white"); L.R(img, fx, top, 1, bot - top - 9, "white")
	L.R(img, fx + fw - 2, top + 1, 2, bot - top - 9, "g3")
	# contorno e cantos arredondados de cima
	L.R(img, fx - 6, top - 4, 1, bot - top - 1, "ink")
	L.line(img, fx - 6, top - 4, fx - 5 + fw, top - 4, "ink")
	L.line(img, fx + fw - 1 + 1, top - 3, fx + fw, bot, "ink")
	L.R(img, fx - 5, bot + 1, fw + 5, 1, "ink")
	L.P(img, fx + fw - 1, top, "g3"); L.P(img, fx, top, "g3")
	# portas: congelador / geladeira
	L.R(img, fx, 171, fw, 1, "g2"); L.R(img, fx, 172, fw, 1, "white")
	L.R(img, fx + 27, 152, 2, 3, "g2"); L.R(img, fx + 27, 174, 2, 3, "g2")         # dobradiças
	# puxadores cromados (alavanca antiga)
	for hy: Array in [[156, 12], [176, 22]]:
		L.R(img, fx + 3, hy[0], 3, hy[1], "st2")
		L.R(img, fx + 3, hy[0], 1, hy[1], "st3")
		L.R(img, fx + 5, hy[0], 1, hy[1], "st1")
		L.P(img, fx + 3, hy[0], "white")
	# plaquinha da marca
	L.R(img, fx + 11, 155, 12, 3, "st2"); L.R(img, fx + 11, 155, 12, 1, "st3"); L.P(img, fx + 12, 156, "r2")
	# bilhete (lista) com ímã vermelho
	L.R(img, fx + 11, 180, 10, 13, "white")
	for ly: Array in [[183, 7], [186, 5], [189, 7], [191, 4]]:
		L.R(img, fx + 12, ly[0], ly[1], 1, "g2")
	L.R(img, fx + 15, 179, 3, 2, "r2"); L.P(img, fx + 15, 179, "r3")
	# foto com ímã amarelo
	L.R(img, fx + 17, 196, 9, 10, "white")
	L.R(img, fx + 18, 197, 7, 6, "b1"); L.R(img, fx + 18, 201, 7, 2, "gr1"); L.P(img, fx + 21, 199, "sk1"); L.P(img, fx + 21, 200, "r1")
	L.R(img, fx + 21, 195, 2, 2, "y1")
	# ímãs soltos
	L.R(img, fx + 9, 199, 2, 2, "gr2"); L.R(img, fx + 12, 203, 2, 2, "b2"); L.P(img, fx + 9, 199, "gr3")
	# ferrugem e amassado embaixo, à esquerda
	for p: Vector2i in [Vector2i(1, 205), Vector2i(2, 206), Vector2i(1, 207), Vector2i(3, 208), Vector2i(2, 209)]:
		L.P(img, fx + p.x, p.y, "br2")
	L.P(img, fx + 2, 207, "br1")
	# grade do rodapé e pés
	L.R(img, fx, 212, fw, 7, "d2")
	for x in range(fx + 2, fx + fw - 2, 2):
		L.R(img, x, 213, 1, 5, "st1")
	L.R(img, fx + 1, 219, 4, 2, "d1"); L.R(img, fx + fw - 5, 219, 4, 2, "d1")
	# rádio de madeira em cima (antena torta)
	var rr: Image = L.blank(15, 9)
	L.R(rr, 0, 1, 15, 8, "br2"); L.R(rr, 0, 1, 15, 1, "br3")
	for x in range(2, 8, 2):
		for y in range(3, 8, 2):
			L.P(rr, x, y, "br0")
	L.R(rr, 10, 3, 3, 3, "y1"); L.P(rr, 11, 4, "br0"); L.R(rr, 3, 0, 9, 1, "st1")
	L.stamp(img, rr, 485, top - 12)
	L.line(img, 498, top - 13, 505, top - 26, "st2")

func garage_back_wall(img: Image, rng: RandomNumberGenerator) -> void:
	L.R(img, BW0, 18, BW1 - BW0, FLOOR_Y - 18, "g1")
	var row := 0
	var y := FLOOR_Y - 10
	while y > 8:
		var off := 0 if row % 2 == 0 else 10
		var x := 170 - off - 20 * 6
		while x < BW1:
			var x0 := maxi(x, BW0)
			var x1 := mini(x + 20, BW1)
			if x1 > x0:
				var tone := "g1"
				var r := rng.randf()
				if r < 0.12:
					tone = "g0"
				elif r > 0.92:
					tone = "g2"
				L.R(img, x0, y, x1 - x0, 10, tone)
				if tone == "g2":
					L.R(img, x0, y, x1 - x0, 1, "g3")
				L.R(img, x0, y + 9, x1 - x0, 1, "g0")
				if x + 19 < BW1 and x + 19 >= BW0:
					L.R(img, x + 19, y, 1, 10, "g0")
				for i in 3:
					L.P(img, rng.randi_range(x0, x1 - 1), rng.randi_range(y + 1, y + 8), "g0")
			x += 20
		y -= 10
		row += 1
	# umidade na base (escurece com dither)
	for yy in range(FLOOR_Y - 18, FLOOR_Y):
		for xx in range(BW0, BW1):
			var t := float(yy - (FLOOR_Y - 18)) / 18.0
			if bayer(xx, yy) < t * 0.7:
				img.set_pixel(xx, yy, L.shade(img.get_pixel(xx, yy), -1))

func garage_side_walls(img: Image, rng: RandomNumberGenerator) -> void:
	for side: int in [0, 1]:
		var xa := 0 if side == 0 else BW1
		var xb := BW0 if side == 0 else 640
		for xx in range(xa, xb):
			var yb := int(round(side_y(xx + 0.5, FLOOR_Y)))
			L.R(img, xx, 18, 1, mini(yb, 360) - 18, "g0")
			# fiadas de bloco em perspectiva + juntas verticais alternadas
			var band := 0
			var yr := FLOOR_Y - 10
			while yr > -60:
				var ya := int(round(side_y(xx + 0.5, yr)))
				if ya >= 18 and ya < 360:
					L.P(img, xx, ya, "d2")
				var period := 21 if side == 0 else 21
				var d := absi(xx - (BW0 if side == 0 else BW1))
				if (d + (band % 2) * 10) % period == 0 and d > 2:
					var yb2 := int(round(side_y(xx + 0.5, yr + 10)))
					L.R(img, xx, maxi(ya, 18), 1, maxi(yb2 - maxi(ya, 18), 0), "d2")
				yr -= 10
				band += 1
			if rng.randf() < 0.3:
				L.P(img, xx, rng.randi_range(30, maxi(yb - 4, 31)), "g1")
		L.line(img, BW0 if side == 0 else BW1 - 1, 18, BW0 if side == 0 else BW1 - 1, FLOOR_Y, "d1")

func garage_floor(img: Image, rng: RandomNumberGenerator) -> void:
	for y in range(FLOOR_Y, 360):
		var hw := floor_hw(y + 0.5)
		var a := int(round(VPX - hw))
		var b := int(round(VPX + hw))
		L.R(img, a, y, b - a, 1, "g2")
	for i in 3600:
		var yy := rng.randi_range(FLOOR_Y + 1, 359)
		var hw := floor_hw(yy + 0.5)
		L.P(img, rng.randi_range(int(VPX - hw), int(VPX + hw)), yy, "g1" if i % 3 else "g3")
	# juntas de dilatação: as 3 de hoje (x 245, 320, 395 na parede) e mais 4 nas alas novas
	for bx: int in [95, 170, 245, 320, 395, 470, 545]:
		var fx := VPX + (bx - VPX) * (360.0 - VPY) / (FLOOR_Y - VPY)
		L.line(img, bx, FLOOR_Y, int(fx), 360, "g1")
	for yj: int in [248, 292]:
		var hw := floor_hw(yj)
		L.R(img, int(VPX - hw), yj, int(2 * hw), 1, "g1")
	for y in range(FLOOR_Y, FLOOR_Y + 3):
		var hw := floor_hw(y)
		L.R(img, int(VPX - hw), y, int(2 * hw), 1, "g1")
	var hw0 := floor_hw(FLOOR_Y)
	L.R(img, int(VPX - hw0), FLOOR_Y, int(2 * hw0), 1, "d2")
	# manchas de óleo (longe dos pontos de gente) e um ralo
	# 6d3: a mancha de óleo da direita tinha um miolo chapado g0 que lia como buraco; agora é só o dither, mais claro
	L.ellipse_dither(img, 530, 300, 26, 6, "g1")
	L.ellipse_dither(img, 536, 301, 12, 3, "g0", 1)
	L.ellipse_dither(img, 120, 236, 22, 4, "g1", 1)
	L.ellipse_dither(img, 268, 318, 10, 2, "g1")
	# 6d3: o ralo (14x5 em 388,290) saiu: no jogo lia como um "retângulo preto solto"
	# giz: as marcas da corda (do lado esquerdo do alvo, onde o lutador pula) e um círculo de treino
	for i in 2:
		var cx := 236 + i * 20
		L.line(img, cx, 286, cx + 7, 291, "cream")
		L.line(img, cx + 7, 286, cx, 291, "cream")
	# 6d3: o círculo de giz (120,292) e o risco claro (20,312) saíram: soltos no chão, não diziam nada

func garage_beam(img: Image) -> void:
	L.R(img, BW0, 25, BW1 - BW0, 7, "br1")
	L.R(img, BW0, 25, BW1 - BW0, 1, "br2")
	L.R(img, BW0, 31, BW1 - BW0, 1, "br0")
	L.R(img, BW0, 32, BW1 - BW0, 1, "ink")
	for i in 24:
		L.R(img, BW0 + 4 + i * 21, 27 + (i % 3), 7 + (i % 4), 1, "br0")
	# a viga entra nas paredes laterais (em perspectiva)
	for side: int in [0, 1]:
		var xa := 0 if side == 0 else BW1
		var xb := BW0 if side == 0 else 640
		for xx in range(xa, xb):
			var y0 := int(round(side_y(xx + 0.5, 25)))
			var y1 := int(round(side_y(xx + 0.5, 33)))
			L.R(img, xx, maxi(y0, 18), 1, maxi(y1 - maxi(y0, 18), 0), "br0")

func garage_props(img: Image, rng: RandomNumberGenerator) -> void:
	# ---- ala esquerda: chapa de ferramentas + bancada de trabalho
	var pb := Rect2i(84, 116, 70, 44)
	L.R(img, pb.position.x - 1, pb.position.y - 1, pb.size.x + 2, pb.size.y + 2, "ink")
	L.R(img, pb.position.x, pb.position.y, pb.size.x, pb.size.y, "br3")
	L.R(img, pb.position.x, pb.position.y, pb.size.x, 1, "y0")
	for yy in range(pb.position.y + 3, pb.end.y - 1, 4):
		for xx in range(pb.position.x + 3, pb.end.x - 1, 4):
			L.P(img, xx, yy, "br1")
	# ferramentas penduradas (silhuetas): martelo, chave inglesa, serrote, alicate, trena
	L.R(img, 90, 122, 3, 20, "br1"); L.R(img, 86, 120, 11, 5, "st1"); L.R(img, 86, 120, 11, 1, "st2")
	L.R(img, 104, 121, 3, 22, "st1"); L.ellipse(img, 105.5, 121, 4, 3, "st1"); L.P(img, 105, 119, "br3"); L.P(img, 106, 120, "br3")
	L.trap(img, 122, 146, 114, 130, 114, 124, "st2"); L.R(img, 114, 122, 6, 6, "br1"); L.line(img, 115, 146, 124, 146, "st0")
	L.line(img, 133, 122, 137, 140, "r1"); L.line(img, 141, 122, 137, 140, "r1"); L.R(img, 136, 140, 3, 4, "st1")
	L.ellipse(img, 147, 130, 4, 4, "y0"); L.ellipse(img, 147, 130, 1.5, 1.5, "ink"); L.R(img, 146, 134, 2, 3, "y0")
	# 6d3: a bancada (com morsa, caixa de ferramentas, lata, balde e aro) saiu: o carro grande estaciona na frente desta parede
	# ---- parede esquerda: janela basculante alta (vidro canelado, grade), luz do dia
	for xx in range(14, 58):
		var top := int(round(side_y(xx + 0.5, 124)))
		var bot := int(round(side_y(xx + 0.5, 158)))
		L.R(img, xx, top, 1, bot - top, "b3")
		if xx % 2 == 0:
			L.R(img, xx, top + 2, 1, bot - top - 4, "white")
		if xx % 9 == 0:
			L.R(img, xx, top, 1, bot - top, "st0")
		L.P(img, xx, top, "ink"); L.P(img, xx, top + 1, "st1"); L.P(img, xx, bot, "ink"); L.P(img, xx, bot - 1, "st1")
		L.P(img, xx, (top + bot) / 2, "st0")
		var sill := int(round(side_y(xx + 0.5, 160)))
		L.P(img, xx, sill, "g2"); L.P(img, xx, sill + 1, "d2")
	for yy in range(int(side_y(14, 124)), int(side_y(14, 158)) + 1):
		L.P(img, 13, yy, "ink"); L.P(img, 58, yy, "ink")
	# cano de água descendo a parede esquerda
	for yy in range(18, int(side_y(60, FLOOR_Y)) + 1):
		L.P(img, 62, yy, "st1"); L.P(img, 63, yy, "st2"); L.P(img, 64, yy, "ink")
	for yy: int in [60, 120, 180]:
		L.R(img, 61, yy, 4, 2, "st0")
	# ---- ala direita: geladeira velha, pilha de pneus, mangueira, relógio de luz
	L.ring(img, 551, 112, 9, 8, 2, "gr1"); L.ring(img, 551, 112, 6, 5, 1, "gr2"); L.R(img, 550, 102, 2, 3, "st1")
	L.R(img, 494, 96, 18, 22, "ink"); L.R(img, 495, 97, 16, 20, "st1"); L.R(img, 497, 99, 12, 7, "st3"); L.R(img, 498, 101, 10, 3, "d1")
	L.R(img, 502, 117, 2, 26, "st0")
	# 6d3: geladeira refeita, pneus de verdade (pilha + um em pé com roda), escada removida (parede direita fica limpa)
	fridge(img)
	# sombra de contato da pilha no chão
	L.ellipse(img, 544, 221, 21, 3, "d1")
	tire_stack(img, 544, 222, 4)
	tire_standing(img, 531.0, 211.0)

func garage_after_light(img: Image) -> void:
	# luz do dia por baixo da porta (a mesma do garage_bg), agora no chão novo
	for yy in range(FLOOR_Y, FLOOR_Y + 16):
		var t := float(yy - FLOOR_Y) / 16.0
		var xl := int(lerpf(382, 372, t))
		var xr := int(lerpf(463, 474, t))
		for xx in range(xl, xr):
			if bayer(xx, yy) > t * 1.1:
				img.set_pixel(xx, yy, L.shade(img.get_pixel(xx, yy), 1))
	# mancha de luz da janela no chão da esquerda
	for yy in range(232, 300):
		for xx in range(0, 150):
			var d := Vector2((xx - 54) / 70.0, (yy - 262) / 26.0).length()
			if d < 1.0 and bayer(xx, yy) > 0.35 + d * 0.6 and on_floor(xx, yy):
				img.set_pixel(xx, yy, L.shade(img.get_pixel(xx, yy), 1))

func garage_pillar(img: Image, r: Rect2i) -> void:
	var x0 := r.position.x
	var w := r.size.x
	L.R(img, x0, 18, w, FLOOR_Y + 2 - 18, "ink")
	L.R(img, x0 + 1, 18, w - 2, FLOOR_Y + 1 - 18, "g1")
	L.R(img, x0 + 1, 18, 2, FLOOR_Y + 1 - 18, "g2")
	L.R(img, x0 + w - 3, 18, 2, FLOOR_Y + 1 - 18, "g0")
	for yy in range(24, FLOOR_Y, 23):
		L.R(img, x0 + 3, yy, w - 6, 1, "g0")
	# sapata no chão
	L.R(img, x0 - 1, FLOOR_Y - 4, w + 2, 7, "ink")
	L.R(img, x0, FLOOR_Y - 3, w, 5, "g2"); L.R(img, x0, FLOOR_Y - 3, w, 1, "g3")
	var pr := Rect2i(x0 - 1, 18, w + 2, FLOOR_Y + 4 - 18)
	light_area(img, pr, GARAGE_LIGHTS, -3)

# ================================================================== ACADEMIA LARGA
const WAIN_Y := 150

func build_gym() -> Image:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	var rng := RandomNumberGenerator.new()
	rng.seed = 6405
	gym_back_wall(img, rng)
	gym_side_walls(img, rng)
	gym_floor(img, rng)
	gym_beam(img)
	gym_props(img, rng)
	gym_light(img, Rect2i(0, 0, 640, 360))
	var old := _load(FONTE + "gym_bg.png")
	var full_old: Image = L.blank(640, 360)
	full_old.blit_rect(old, Rect2i(Vector2i.ZERO, old.get_size()), OLD.position)
	paste_old(img, full_old, COPY)
	# pés do banco e a sombra dele passam da linha do chão
	paste_old(img, full_old, Rect2i(174, 220, 72, 3))
	gym_fix_6d3(img)
	for t: Vector2i in TUBES_NEW:
		blend(img, tube_sprite(), t.x - 24, t.y)
	for pr: Rect2i in [PIL_L, PIL_R]:
		gym_pillar(img, pr)
	return img

## 6d3 (varredura): o nome pintado perdia pixels ao acaso e "BOA" lia "BOR"; o espelho tinha uma estrela de trincas com
## anel e fita em X que, do tamanho dele, lia como teia/vidro estourado. Agora: nome inteiro (o descascado fica só na borda
## de baixo das letras) e espelho limpo com reflexo em diagonal e UMA trinca curta no canto de cima, com um pedaço de fita.
func gym_fix_6d3(img: Image) -> void:
	var lay: Image = L.blank(640, 360)
	var nm: Image = L.blank(80, 18)
	L.text_center(nm, "ACADEMIA", 40, 0, "gr1")
	L.text_center(nm, "BOA ESQUINA", 40, 9, "r1")
	for y in 18:
		for x in 80:
			if nm.get_pixel(x, y).a > 0.0 and (y == 6 or y == 15) and (x * 7 + y) % 5 == 0:
				nm.set_pixel(x, y, L.C["g3"])
	L.blit(lay, nm, 257, 35)
	var mx := 266
	var my := 55
	var mw := 62
	var mh := 90
	L.R(lay, mx, my, mw, mh, "g3")
	L.R(lay, mx, my + mh - 30, mw, 30, "g2")
	L.dither(lay, mx, my + mh - 34, mw, 4, "g2")
	L.R(lay, mx, my + mh - 30, mw, 1, "cream")
	for i in 3:
		L.line(lay, mx + 8 + i * 6, my + mh - 32, mx + 34 + i * 6, my + 2, "white" if i != 1 else "cream")
	L.line(lay, mx + 48, my + 40, mx + 60, my + 20, "white")
	# uma trinca curta no canto de cima à direita, presa com um pedaço de fita
	var h := Vector2i(mx + mw - 6, my + 5)
	for r: Array in [[-14, 10], [-6, 16], [-16, 2]]:
		L.line(lay, h.x, h.y, h.x + int(r[0]), h.y + int(r[1]), "g1")
	L.R(lay, h.x - 3, h.y - 2, 7, 3, "cream"); L.R(lay, h.x - 3, h.y, 7, 1, "g3")
	for y in range(30, 150):
		for x in range(250, 345):
			var c := lay.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var st := gym_step_old(x, y)
			img.set_pixel(x, y, L.shade(c, st) if st != 0 else c)

func gym_back_wall(img: Image, rng: RandomNumberGenerator) -> void:
	L.R(img, BW0, 18, BW1 - BW0, WAIN_Y - 18, "cream")
	L.R(img, BW0, WAIN_Y, BW1 - BW0, FLOOR_Y - WAIN_Y, "gr1")
	L.R(img, BW0, WAIN_Y - 3, BW1 - BW0, 2, "white")
	L.R(img, BW0, WAIN_Y - 1, BW1 - BW0, 1, "g3")
	L.R(img, BW0, WAIN_Y, BW1 - BW0, 1, "gr0")
	L.R(img, BW0, FLOOR_Y - 6, BW1 - BW0, 6, "gr0")
	L.R(img, BW0, FLOOR_Y - 6, BW1 - BW0, 1, "gr2")
	for i in 420:
		L.P(img, rng.randi_range(BW0, BW1 - 1), rng.randi_range(34, WAIN_Y - 4), "g3")
	for i in 200:
		L.P(img, rng.randi_range(BW0, BW1 - 1), rng.randi_range(WAIN_Y + 2, FLOOR_Y - 8), "gr0" if i % 3 else "gr2")
	for i in 22:
		var px := rng.randi_range(BW0 + 4, BW1 - 14)
		var w := rng.randi_range(3, 9)
		var h := rng.randi_range(2, 6)
		var yy := WAIN_Y + rng.randi_range(1, 5)
		L.R(img, px, yy, w, h, "g3")
		L.R(img, px, yy + h, w, 1, "g2")
		L.R(img, px + w, yy, 1, h, "gr0")
	for c: Vector2i in [Vector2i(96, 70), Vector2i(150, 104), Vector2i(500, 60), Vector2i(548, 118)]:
		L.ellipse(img, c.x, c.y, 4, 2, "g3"); L.P(img, c.x - 2, c.y + 2, "g2"); L.P(img, c.x + 3, c.y - 1, "g2")
	var cr := [[560, 40], [556, 52], [559, 63], [553, 74], [555, 86]]
	for i in cr.size() - 1:
		L.line(img, cr[i][0], cr[i][1], cr[i + 1][0], cr[i + 1][1], "g1")
		L.line(img, cr[i][0] + 1, cr[i][1], cr[i + 1][0] + 1, cr[i + 1][1], "white")

func gym_side_walls(img: Image, rng: RandomNumberGenerator) -> void:
	for side: int in [0, 1]:
		var xa := 0 if side == 0 else BW1
		var xb := BW0 if side == 0 else 640
		for xx in range(xa, xb):
			var yb := mini(int(round(side_y(xx + 0.5, FLOOR_Y))), 360)
			var yw := int(round(side_y(xx + 0.5, WAIN_Y)))
			var yr := int(round(side_y(xx + 0.5, FLOOR_Y - 6)))
			L.R(img, xx, 18, 1, maxi(yw - 18, 0), "g3")
			L.R(img, xx, yw - 2, 1, 2, "cream")
			L.R(img, xx, yw, 1, maxi(yb - yw, 0), "gr0")
			L.R(img, xx, yr, 1, maxi(yb - yr, 0), "d2")
			if (xx % 7) == 0:
				L.P(img, xx, rng.randi_range(30, maxi(yw - 6, 31)), "g2")
		L.line(img, BW0 if side == 0 else BW1 - 1, 18, BW0 if side == 0 else BW1 - 1, FLOOR_Y, "g2")

func gym_floor(img: Image, rng: RandomNumberGenerator) -> void:
	var rows := [FLOOR_Y, 229, 240, 253, 269, 290, 316, 360]
	var cw := 37.5
	for r in rows.size() - 1:
		for yy in range(rows[r], rows[r + 1]):
			var hw := floor_hw(yy + 0.5)
			var s := hw / 250.0
			for k in range(-6, 16):
				var bxa := 170.0 + cw * k
				var xa := VPX + (bxa - VPX) * s
				var xb := VPX + (bxa + cw - VPX) * s
				xa = maxf(xa, VPX - hw)
				xb = minf(xb, VPX + hw)
				if xb <= xa:
					continue
				var tone := "d2" if (r + k) % 2 == 0 else "g0"
				# tatame azul gasto: 3 colunas x 2 fileiras na frente, à esquerda do alvo (boneco em 192,318)
				if r >= 5 and k >= -1 and k <= 1:
					tone = "b1" if (r + k) % 2 == 0 else "b2"
				L.R(img, int(round(xa)), yy, int(round(xb)) - int(round(xa)), 1, tone)
	for k in range(-6, 17):
		var bx := 170.0 + cw * k
		if bx < BW0 - 1 or bx > BW1 + 1:
			pass
		var fx := VPX + (bx - VPX) * (360.0 - VPY) / (FLOOR_Y - VPY)
		L.line(img, int(bx), FLOOR_Y, int(fx), 360, "d1")
	for r in range(1, rows.size() - 1):
		var hw := floor_hw(rows[r])
		L.R(img, int(VPX - hw), rows[r], int(2 * hw), 1, "d1")
	# limpa o que a linha passou fora do chão (paredes laterais)
	for y in range(FLOOR_Y, 360):
		var hw := floor_hw(y + 0.5)
		for x in range(0, 640):
			if absf(x + 0.5 - VPX) > hw:
				var yb := side_y(x + 0.5, FLOOR_Y)
				if y >= int(round(yb)):
					pass
	# textura da borracha
	for i in 1800:
		var yy := rng.randi_range(FLOOR_Y + 1, 359)
		var hw := floor_hw(yy + 0.5)
		var xx := rng.randi_range(int(VPX - hw), int(VPX + hw))
		var c := img.get_pixel(clampi(xx, 0, 639), yy)
		if c.a > 0.0:
			L.P(img, xx, yy, L.shade(c, -1 if i % 3 else 1))
	# tatame: borda de cima clara, desgaste e rasgo remendado
	var y0 := 290
	var s0 := floor_hw(y0) / 250.0
	var txa := VPX + (170.0 + cw * -1 - VPX) * s0
	var txb := VPX + (170.0 + cw * 2 - VPX) * s0
	L.R(img, int(txa), y0, int(txb - txa), 1, "b3")
	for i in 160:
		var yy := rng.randi_range(292, 340)
		var s := floor_hw(yy) / 250.0
		var xl := VPX + (170.0 + cw * -1 - VPX) * s
		var xr := VPX + (170.0 + cw * 2 - VPX) * s
		var xx := rng.randi_range(int(xl) + 1, int(xr) - 2)
		var c := img.get_pixel(xx, yy)
		if c.to_html(false) == L.C.b1.to_html(false) or c.to_html(false) == L.C.b2.to_html(false):
			img.set_pixel(xx, yy, L.C["g1"] if i % 4 == 0 else L.shade(c, -1))
	L.line(img, 96, 300, 104, 305, "cream"); L.line(img, 104, 300, 96, 305, "cream"); L.line(img, 97, 300, 105, 305, "g3")
	# rodapé na base da parede
	for y in range(FLOOR_Y, FLOOR_Y + 3):
		var hw := floor_hw(y)
		L.R(img, int(VPX - hw), y, int(2 * hw), 1, "d1")
	L.R(img, BW0, FLOOR_Y, BW1 - BW0, 1, "ink")
	L.ellipse_dither(img, 336, 262, 16, 3, "d1")


func gym_ring(img: Image) -> void:
	# plataforma: tampo de lona (cream/g3) de y 268 até 300, frente (avental azul) de 300 a 316
	var top_y := 270
	var front_y := 302
	var x_left_top := 566
	var x_left_bot := 548
	for yy in range(top_y, front_y):
		var t := float(yy - top_y) / float(front_y - top_y)
		var xl := int(lerpf(x_left_top, x_left_bot, t))
		L.R(img, xl, yy, 640 - xl, 1, "cream" if (yy / 2) % 6 else "g3")
	for yy in range(front_y, front_y + 16):
		L.R(img, x_left_bot, yy, 640 - x_left_bot, 1, "b1" if yy < front_y + 14 else "b0")
	L.R(img, x_left_bot, front_y, 640 - x_left_bot, 1, "b2")
	for i in 6:
		L.R(img, x_left_bot + 6 + i * 16, front_y + 4, 8, 1, "b2")
	L.line(img, x_left_top, top_y, x_left_bot, front_y, "ink")
	L.line(img, x_left_top - 1, top_y, x_left_bot - 1, front_y + 15, "ink")
	L.R(img, x_left_bot - 1, front_y + 16, 640 - x_left_bot + 1, 1, "ink")
	# poste do canto (estofado vermelho) e 3 cordas: para a direita e para o fundo
	var px := x_left_bot + 4
	L.R(img, px - 3, 214, 8, front_y - 214 + 1, "ink")
	L.R(img, px - 2, 215, 6, front_y - 215, "st1")
	L.R(img, px - 3, 222, 8, 40, "ink"); L.R(img, px - 2, 223, 6, 38, "r1"); L.R(img, px - 2, 223, 2, 38, "r2")
	for i in 3:
		var ry := 228 + i * 14
		L.R(img, px + 5, ry, 640 - px - 5, 2, ["r2", "white", "b2"][i])
		L.R(img, px + 5, ry + 2, 640 - px - 5, 1, "ink")
		L.line(img, px + 3, ry, 600, ry - 42 + i * 4, ["r2", "white", "b2"][i])
		L.line(img, px + 3, ry + 1, 600, ry - 41 + i * 4, "ink")

func gym_beam(img: Image) -> void:
	L.R(img, BW0, 18, BW1 - BW0, 6, "g3")
	L.R(img, BW0, 24, BW1 - BW0, 8, "st1")
	L.R(img, BW0, 24, BW1 - BW0, 1, "st3")
	L.R(img, BW0, 25, BW1 - BW0, 1, "st2")
	L.R(img, BW0, 30, BW1 - BW0, 1, "st0")
	L.R(img, BW0, 31, BW1 - BW0, 1, "ink")
	for i in range(BW0 + 4, BW1, 18):
		L.P(img, i, 27, "st3"); L.P(img, i, 28, "st0")

func gym_props(img: Image, rng: RandomNumberGenerator) -> void:
	# ---- ala esquerda: quadro branco da semana (rabiscos ilegíveis) e suporte de halteres
	L.R(img, 82, 116, 72, 30, "ink"); L.R(img, 83, 117, 70, 28, "st2"); L.R(img, 84, 118, 68, 26, "white")
	for i in 5:
		L.R(img, 87, 121 + i * 5, 8, 1, "b1")
		var w := rng.randi_range(12, 40)
		L.R(img, 98, 121 + i * 5, w, 1, ["g2", "r1", "g2", "gr1", "g2"][i])
	L.R(img, 84, 144, 68, 2, "st1"); L.R(img, 120, 143, 6, 2, "r2"); L.R(img, 128, 143, 6, 2, "b1")
	# suporte de halteres (2 andares) encostado no barrado
	L.R(img, 80, 186, 76, 4, "ink"); L.R(img, 81, 187, 74, 2, "st2")
	L.R(img, 80, 203, 76, 4, "ink"); L.R(img, 81, 204, 74, 2, "st2")
	L.R(img, 82, 186, 3, 36, "st0"); L.R(img, 151, 186, 3, 36, "st0")
	var cols := ["r1", "b1", "gr0", "y0", "d1", "r1"]
	for i in 6:
		for lv in 2:
			var hx := 87 + i * 11
			var hy := 180 + lv * 17
			var sz := 3 + (i % 3)
			L.R(img, hx, hy + 3, 9, 2, "st3")
			L.R(img, hx - 1, hy + 4 - sz, 3, sz * 2 - 1, "ink"); L.R(img, hx + 7, hy + 4 - sz, 3, sz * 2 - 1, "ink")
			L.R(img, hx, hy + 5 - sz, 1, sz * 2 - 3, cols[i]); L.R(img, hx + 8, hy + 5 - sz, 1, sz * 2 - 3, cols[i])
	# kettlebell e medicine ball no chão, junto do suporte
	L.ellipse(img, 70, 228, 6, 6, "ink"); L.ellipse(img, 70, 228, 5, 5, "d1"); L.ring(img, 70, 220, 3, 3, 1, "ink"); L.P(img, 68, 226, "g0")
	L.ellipse(img, 160, 226, 7, 6, "ink"); L.ellipse(img, 160, 226, 6, 5, "br1"); L.R(img, 154, 226, 12, 1, "br0"); L.P(img, 158, 223, "br2")
	# ---- parede esquerda: duas janelas altas com grade (luz da rua)
	for wi in 2:
		var xa := 10 + wi * 30
		for xx in range(xa, xa + 22):
			var top := int(round(side_y(xx + 0.5, 112)))
			var bot := int(round(side_y(xx + 0.5, 146)))
			L.R(img, xx, top, 1, bot - top, "b2")
			L.P(img, xx, top + 1, "b3"); L.P(img, xx, top + 2, "b3")
			if xx % 5 == 0:
				L.R(img, xx, top, 1, bot - top, "st0")
			L.P(img, xx, top, "ink"); L.P(img, xx, bot, "ink"); L.P(img, xx, (top + bot) / 2, "st0")
			L.P(img, xx, bot + 1, "white")
		for yy in range(int(side_y(xa, 112)), int(side_y(xa, 146)) + 1):
			L.P(img, xa - 1, yy, "ink")
		for yy in range(int(side_y(xa + 22, 112)), int(side_y(xa + 22, 146)) + 1):
			L.P(img, xa + 22, yy, "ink")
	# ---- ala direita: armários de aço, bebedouro, balança
	for i in 3:
		var ax := 480 + i * 17
		L.R(img, ax, 128, 17, 94, "ink")
		L.R(img, ax + 1, 129, 15, 92, "st1"); L.R(img, ax + 1, 129, 15, 1, "st3"); L.R(img, ax + 1, 129, 1, 92, "st2")
		for v in 3:
			L.R(img, ax + 4, 134 + v * 3, 9, 1, "st0")
		L.R(img, ax + 12, 170, 2, 7, "st3")
		if i == 1:
			L.R(img, ax + 11, 177, 4, 4, "y0"); L.P(img, ax + 12, 176, "st3")
		if i == 2:
			L.R(img, ax + 4, 186, 8, 10, "r2"); L.R(img, ax + 5, 188, 6, 1, "white")
	L.R(img, 536, 166, 26, 56, "ink"); L.R(img, 537, 178, 24, 43, "white"); L.R(img, 557, 178, 4, 43, "g3")
	L.R(img, 541, 186, 16, 6, "st1"); L.R(img, 547, 184, 4, 2, "st3"); L.R(img, 540, 218, 4, 3, "d1"); L.R(img, 554, 218, 4, 3, "d1")
	L.ellipse(img, 549, 171, 10, 6, "b3"); L.ellipse(img, 549, 169, 7, 3, "white"); L.R(img, 546, 163, 6, 3, "b2")
	# árvore de anilhas no canto do fundo à direita (anilhas de frente, penduradas nos pinos dos dois lados)
	L.R(img, 575, 176, 4, 54, "ink"); L.R(img, 576, 176, 2, 53, "st2")
	L.R(img, 562, 228, 30, 4, "ink"); L.R(img, 563, 229, 28, 2, "st1")
	for i in 3:
		var ay := 190 + i * 14
		var rr := 8 - i
		for sx: int in [-1, 1]:
			var cx := 577 + sx * (rr + 3)
			L.ellipse(img, cx, ay, rr + 1, rr + 1, "ink")
			L.ellipse(img, cx, ay, rr, rr, ["d1", "d2", "r0"][i])
			L.ring(img, cx, ay, rr - 2, rr - 2, 1, "g0")
			L.ellipse(img, cx, ay, 1.5, 1.5, "ink")
			L.P(img, cx - rr + 2, ay - 2, "g1")
	# ---- parede direita: espaldar (barras de madeira) em perspectiva
	for rail: int in [586, 608]:
		var y0 := int(side_y(rail, 70))
		var y1 := int(side_y(rail, FLOOR_Y))
		L.R(img, rail, y0, 3, y1 - y0, "br1"); L.R(img, rail, y0, 1, y1 - y0, "br2"); L.R(img, rail + 3, y0, 1, y1 - y0, "ink")
	for k in 13:
		var yb := 80.0 + k * 11
		L.line(img, 586, int(side_y(586, yb)), 611, int(side_y(611, yb)), "br3")
		L.line(img, 586, int(side_y(586, yb)) + 1, 611, int(side_y(611, yb)) + 1, "br0")

func tube_sprite() -> Image:
	var img: Image = L.blank(48, 10)
	L.R(img, 6, 0, 1, 4, "d2"); L.R(img, 41, 0, 1, 4, "d2")
	L.R(img, 1, 4, 46, 4, "ink")
	L.R(img, 2, 5, 44, 2, "st2")
	L.R(img, 2, 5, 44, 1, "st3")
	L.R(img, 3, 7, 42, 2, "ink")
	L.R(img, 4, 7, 40, 2, "white")
	L.R(img, 4, 8, 40, 1, "b3")
	return img

func gym_pillar(img: Image, r: Rect2i) -> void:
	var x0 := r.position.x
	var w := r.size.x
	L.R(img, x0, 18, w, FLOOR_Y + 1 - 18, "ink")
	L.R(img, x0 + 1, 18, w - 2, WAIN_Y - 18, "cream")
	L.R(img, x0 + 1, 18, 2, WAIN_Y - 18, "white")
	L.R(img, x0 + w - 3, 18, 2, WAIN_Y - 18, "g3")
	L.R(img, x0 + 1, WAIN_Y - 3, w - 2, 2, "white")
	L.R(img, x0 + 1, WAIN_Y, w - 2, FLOOR_Y - WAIN_Y, "gr1")
	L.R(img, x0 + 1, WAIN_Y, 2, FLOOR_Y - WAIN_Y, "gr2")
	L.R(img, x0 + w - 3, WAIN_Y, 2, FLOOR_Y - WAIN_Y, "gr0")
	L.R(img, x0 + 1, FLOOR_Y - 6, w - 2, 6, "gr0"); L.R(img, x0 + 1, FLOOR_Y - 6, w - 2, 1, "gr2")
	L.R(img, x0 + 4, WAIN_Y + 4, 3, 4, "g3")
	gym_light(img, Rect2i(x0, 18, w, FLOOR_Y + 1 - 18))

# ================================================================== CENA (sprites nos pontos)
## item = {name, img, at (canto sup. esq.), y (ordem), shadow (pos dos pés ou null), kind}
func item_spr(name: String, id: String, pos: Vector2i, sort_y: float, kind: String, q := 0, shadow := false) -> Dictionary:
	return {"name": name, "img": frame_of(id, q), "at": pos - pivot_of(id), "y": sort_y, "shadow": pos if shadow else null,
		"kind": kind, "id": id, "pos": pos}

func item_img(name: String, img: Image, pos: Vector2i, kind: String, piv := GPIV, shadow := true, sort_y := -1.0) -> Dictionary:
	return {"name": name, "img": img, "at": pos - piv, "y": float(pos.y) if sort_y < 0 else sort_y, "shadow": pos if shadow else null,
		"kind": kind, "id": "", "pos": pos}

func sfx(local: String) -> String:
	return "_gym" if local == "academia" else ""

## cheia = fim de jogo naquela sala (tudo comprado, equipe máxima, John no caixote, 2º mentor, mural com 8+ fotos)
## pequena = começo (garagem: 1ª carreira com a esteira e a luva na caixa; academia: acabou de chegar, boneco e luva na caixa)
func cast(local: String, equipe: String) -> Array:
	var s := sfx(local)
	var it := []
	it.append(item_spr("saco", "bag_l0_idle" + s, P_BAG, 253.0, "alvo"))
	it.append(item_img("lutador", layered("fighter_idle_disc_layered", 0, CUR_LOOK), P_FIGHTER, "alvo"))
	var coach_id := "coach_idle_gym" if local == "academia" else "coach_idle"
	it.append(item_img("osmar", frame_of(coach_id, 0), pt(local, "coach"), "gente"))
	if equipe == "cheia":
		var m: Vector2i = pt(local, "mentor")
		it.append({"name": "caixote", "img": frame_of("garage_crate" + s), "at": m + CRATE_OFF - Vector2i(0, 0), "y": float(m.y - 2),
			"shadow": null, "kind": "objeto", "id": "garage_crate" + s, "pos": m + CRATE_OFF})
		it.append(item_img("john_sentado", frame_of("john_sit_rest", 0), m, "gente"))
		it.append(item_img("mentor_2", layered("disciple_stand_bare", 0, M2_LOOK), pt(local, "mentor_2"), "gente"))
		for id in CREW:
			it.append(item_spr(id, id, P[id], float(P[id].y), "gente", 0, true))
		it.append(item_spr("esteira", "treadmill_l1_side" + s if spr("treadmill_l1_side" + s).size() > 0 else "treadmill_l0_side" + s,
			P.treadmill_side, float(P.treadmill_side.y), "aparelho"))
		it.append(item_spr("corda", "rope_l0_idle" + s, P_ROPE, 206.0, "aparelho"))
		if local == "academia":
			it.append(item_spr("boneco", "grappling_dummy_l0_rest" + s, P.dummy_rest, float(P.dummy_rest.y) - 12.0, "aparelho"))
		else:
			it.append(item_spr("pera", "speed_bag_l0_wall" + s, P_SB_WALL, 40.0, "parede"))
	else:
		if local == "academia":
			var m: Vector2i = P.mentor
			it.append({"name": "caixote", "img": frame_of("garage_crate" + s), "at": m + CRATE_OFF, "y": float(m.y - 2),
				"shadow": null, "kind": "objeto", "id": "garage_crate" + s, "pos": m + CRATE_OFF})
			it.append(item_img("john_sentado", frame_of("john_sit_rest", 0), m, "gente"))
			it.append(item_spr("esteira", "treadmill_l0_side" + s, P.treadmill_side, float(P.treadmill_side.y), "aparelho"))
			it.append(item_spr("caixa_art", "box_big", P.box_art, float(P.box_art.y), "caixa"))
			it.append(item_spr("caixa_glove", "box_small", P.box_glove, float(P.box_glove.y), "caixa"))
			for id in ["neighbor_1", "uncle_1", "coach_1"]:
				it.append(item_spr(id, id, P[id], float(P[id].y), "gente", 0, true))
		else:
			it.append(item_spr("caixa_treadmill", "box_big", P.box_treadmill, float(P.box_treadmill.y), "caixa"))
			it.append(item_spr("caixa_glove", "box_small", P.box_glove, float(P.box_glove.y), "caixa"))
			for id in ["neighbor_1", "uncle_1"]:
				it.append(item_spr(id, id, P[id], float(P[id].y), "gente", 0, true))
	return it

func compose(local: String, equipe: String) -> Image:
	var s := sfx(local)
	var im: Image = BG[local].duplicate()
	# parede: mural, foto, parede da memória (garagem salva), metrônomo, luvas penduradas
	blend(im, frame_of("wall_mural" + s, 3 if equipe == "cheia" else 0), P_MURAL.x, P_MURAL.y)
	if local == "academia":
		blend(im, frame_of("wall_photo_old_gym", 1), P_PHOTO.x, P_PHOTO.y)
	else:
		if equipe == "cheia":
			for k in ["wall_photo_team", "wall_form_named", "wall_photo_old", "wall_clipping", "wall_school_symbol"]:
				var e := spr(k)
				blend(im, frame_of(k), int(e.pos[0]), int(e.pos[1]))
		else:
			for k in ["wall_notice_debt", "wall_form_blank", "wall_photo_old"]:
				var e := spr(k)
				blend(im, frame_of(k), int(e.pos[0]), int(e.pos[1]))
	var mt := "metronome_l2" if equipe == "cheia" else ""
	if mt != "":
		blend(im, frame_of(mt), 240 - 9, 118 - 25)
	if local == "garagem":
		blend(im, frame_of("lamp"), 300 - 14, 32)
	# corrente do saco
	var t: Image = frame_of("bag_chain_tile")
	var y := 33
	while y < P_BAG.y:
		blend(im, t.get_region(Rect2i(0, 0, t.get_width(), mini(6, P_BAG.y - y))), P_BAG.x - 1, y)
		y += 6
	var items := cast(local, equipe)
	if equipe == "cheia":
		items.append(item_spr("luvas_penduradas", "garage_hung_gloves_old", Vector2i(335, 186), 254.0, "parede"))
	items.sort_custom(func(a, b): return a.y < b.y)
	var fs := spr("floor_shadow")
	for it in items:
		if it.shadow != null:
			blend(im, frame_of("floor_shadow"), it.shadow.x - int(fs.pivot[0]), it.shadow.y - 1 - int(fs.pivot[1]))
		blend(im, it.img, it.at.x, it.at.y)
	return im

# ================================================================== moldura da opção C (HUD, miniaturas, faixa, painel)
func put(img: Image, nome: String, x: int, y: int) -> void:
	var s := _load(ROOT + "assets/sprites/ui/" + nome + ".png")
	blend(img, s, x, y)

func crop(img: Image, k: String, r: Rect2i, x: int, y: int) -> void:
	img.blit_rect(REF[k], r, Vector2i(x, y))

func plate(img: Image, x: int, y: int, w: int, h: int, bg := "d1") -> void:
	L.R(img, x + 1, y + h, w, 1, "ink")
	L.R(img, x + w, y + 1, 1, h, "ink")
	L.panel(img, x, y, w, h, bg, "d2", "ink")

func outline(img: Image, x: int, y: int, w: int, h: int, c) -> void:
	L.R(img, x, y, w, 1, c); L.R(img, x, y + h - 1, w, 1, c); L.R(img, x, y, 1, h, c); L.R(img, x + w - 1, y, 1, h, c)

func arrow(img: Image, x: int, y: int, dir: String, c := "g2") -> void:
	for i in 3:
		if dir == "l":
			L.R(img, x + i, y + 2 - i, 1, 1 + i * 2, c)
		else:
			L.R(img, x + 2 - i, y + 2 - i, 1, 1 + i * 2, c)

func badge(img: Image, x: int, y: int, n: int, bg := "gr2") -> void:
	L.R(img, x, y, 9, 11, "ink")
	L.R(img, x + 1, y + 1, 7, 9, bg)
	L.text_center(img, str(n), x + 5, y + 2, "ink")

func tab(img: Image, x: int, y: int, w: int, h: int, dir: String, ativo: bool, buy := 0) -> void:
	plate(img, x, y, w, h, "d2" if ativo else "d1")
	if buy > 0:
		outline(img, x + 1, y + 1, w - 2, h - 2, "y2")
	var cy := y + 4
	for n in ["icon_neighbor", "icon_money_16"]:
		put(img, n, x + (w - 16) / 2, cy)
		cy += 19
	arrow(img, x + w / 2 - 1, y + h - 9, dir, "white" if ativo else "g2")
	if buy > 0:
		badge(img, x - 3 if x > 320 else x + w - 6, y - 5, buy)

func _lock(img: Image, x: int, y: int, c := "y1") -> void:
	L.R(img, x + 2, y, 3, 1, c); L.R(img, x + 1, y + 1, 1, 3, c); L.R(img, x + 5, y + 1, 1, 3, c)
	L.R(img, x, y + 4, 7, 6, "ink"); L.R(img, x + 1, y + 5, 5, 4, c); L.P(img, x + 3, y + 6, "ink")

func focus_button(img: Image, x: int, y: int, w: int, nome: String, estado: String) -> void:
	match estado:
		"ativo":
			L.button(img, x, y, w, 20, "r1", "")
			put(img, "icon_strength", x + 5, y + 5)
			L.text(img, nome, x + 18, y + 6, "white", 1, "r0")
		"tem":
			L.button(img, x, y, w, 20, "d2", "")
			L.text(img, nome, x + 18, y + 6, "white", 1, "ink")
		"compra":
			L.button(img, x, y, w, 20, "d2", "")
			outline(img, x, y, w, 20, "gr3")
			_lock(img, x + 6, y + 4)
			L.text(img, nome, x + 18, y + 6, "white", 1, "ink")
		_:
			L.button(img, x, y, w, 20, "d1", "")
			_lock(img, x + 6, y + 4, "g1")
			L.text(img, nome, x + 18, y + 6, "g1", 1, "ink")

const R_HUD := Rect2i(0, 0, 640, 18)
const R_CAL := Rect2i(5, 130, 119, 45)
const R_MAPA := Rect2i(132, 22, 22, 22)
const R_DIR := Rect2i(512, 18, 128, 272)

func chrome(img: Image, local: String, equipe: String, fixado: bool) -> void:
	var ref_k := local
	crop(img, ref_k, R_HUD, 0, 0)
	plate(img, 2, 20, 110, 41)
	var icons := ["icon_strength", "icon_agility", "icon_endurance"]
	var cores := ["r2", "b3", "y0"]
	var vals := [317, 60, 200] if local == "garagem" else [1240, 860, 990]
	for i in 3:
		var yy := 24 + i * 12
		put(img, icons[i], 6, yy)
		L.bar(img, 18, yy + 2, 56, 5, [0.55, 0.12, 0.36][i], cores[i])
		L.text_right(img, str(vals[i]), 107, yy + 1, "white", 1, "ink")
	crop(img, ref_k, R_MAPA, 116, 20)
	plate(img, 2, 64, 123, 49)
	crop(img, ref_k, R_CAL, 4, 66)
	L.R(img, 0, STRIP_Y - 1, 640, 1, "ink")
	L.panel(img, 0, STRIP_Y, 640, 30, "d1", "d2", "ink")
	var w: int = L.text(img, "+1" if local == "garagem" else "+3", 6, 338, "gr3", 2, "ink")
	L.text(img, "/CLIQUE", 6 + w + 3, 345, "g2", 1, "ink")
	var focos := []
	if local == "garagem":
		focos = [["SACO", "ativo"], ["ESTEIRA", "tem" if equipe == "cheia" else "compra"], ["CORDA", "tem" if equipe == "cheia" else "trancado"]]
		if equipe == "cheia":
			focos.append(["PERA", "tem"])
	else:
		focos = [["SACO", "ativo"], ["ESTEIRA", "tem"], ["CORDA", "tem" if equipe == "cheia" else "compra"], ["BONECO", "tem" if equipe == "cheia" else "trancado"]]
	var fx := 92
	for f in focos:
		focus_button(img, fx, 335, 86, f[0], f[1])
		fx += 90
	L.button(img, 508, 333, 102, 24, "r2", "LUTAR!", "white", 2)
	L.button(img, 614, 333, 24, 24, "p1", "")
	put(img, "icon_pass_post", 618, 336)
	if not fixado:
		tab(img, 616, 120, 24, 56, "l", false, 2)
		return
	plate(img, 506, 18, 136, 296)
	crop(img, "garagem_loja" if local == "garagem" else local, R_DIR, 510, 20)
	L.button(img, 512, 296, 124, 15, "p0", "FIXADO")
	tab(img, 484, 120, 24, 56, "r", true)

# ================================================================== conferência
var OCC := {}   # nome -> {px: Dictionary, rect: Rect2i, kind, sort}

func occ_of(local: String, name: String) -> Dictionary:
	return OCC[local].get(name, {})

func add_occ(local: String, name: String, srcs: Array, kind: String, sort_y: float) -> void:
	var px := {}
	var r := Rect2i()
	var first := true
	for s in srcs:
		var im: Image = s[0]
		var at: Vector2i = s[1]
		var ur := im.get_used_rect()
		if ur.has_area():
			var rr := Rect2i(ur.position + at, ur.size)
			r = rr if first else r.merge(rr)
			first = false
		for yy in range(ur.position.y, ur.end.y):
			for xx in range(ur.position.x, ur.end.x):
				if im.get_pixel(xx, yy).a > 0.0:
					px[Vector2i(xx, yy) + at] = true
	OCC[local][name] = {"px": px, "rect": r, "kind": kind, "sort": sort_y}

func frames_at(id: String, pos: Vector2i) -> Array:
	var out := []
	for q in nframes(id):
		out.append([frame_of(id, q), pos - pivot_of(id)])
	return out

func build_occ(local: String) -> void:
	OCC[local] = {}
	var s := sfx(local)
	var coach_id := "coach_idle_gym" if local == "academia" else "coach_idle"
	add_occ(local, "lutador", (func():
		var a := []
		for q in 4:
			a.append([layered("fighter_idle_disc_layered", q, CUR_LOOK), P_FIGHTER - GPIV])
		return a).call(), "alvo", 272.0)
	add_occ(local, "saco_centro", frames_at("bag_l0_idle" + s, P_BAG), "alvo", 253.0)
	add_occ(local, "saco_de_lado", frames_at("bag_l0_side" + s, P_BAG_SIDE), "aparelho", 236.0)
	add_occ(local, "corda_gancho", frames_at("rope_l0_idle" + s, P_ROPE), "aparelho", 206.0)
	add_occ(local, "osmar", frames_at(coach_id, pt(local, "coach")), "gente", float(pt(local, "coach").y))
	var m: Vector2i = pt(local, "mentor")
	add_occ(local, "john_sentado", frames_at("john_sit_rest", m), "gente", float(m.y))
	var a2 := []
	for q in 4:
		a2.append([layered("disciple_sit_rest", q, M2_LOOK), m - GPIV])
	add_occ(local, "ultimo_sentado", a2, "gente", float(m.y))
	add_occ(local, "caixote", [[frame_of("garage_crate" + s), m + CRATE_OFF - Vector2i(16, 20) + Vector2i(16, 20)]], "objeto", float(m.y - 2))
	var a3 := []
	for q in 4:
		a3.append([layered("disciple_stand_bare", q, M2_LOOK), pt(local, "mentor_2") - GPIV])
	add_occ(local, "mentor_2", a3, "gente", float(pt(local, "mentor_2").y))
	for id in CREW:
		add_occ(local, id, frames_at(id, P[id]), "gente", float(P[id].y))
	add_occ(local, "esteira_encostada", frames_at("treadmill_l0_side" + s, P.treadmill_side), "aparelho", float(P.treadmill_side.y))
	add_occ(local, "boneco_descanso", frames_at("grappling_dummy_l0_rest" + s, P.dummy_rest), "aparelho", float(P.dummy_rest.y) - 12.0)
	add_occ(local, "pera_parede", frames_at("speed_bag_l0_wall" + s, P_SB_WALL), "parede", 40.0)
	add_occ(local, "caixa_esteira", frames_at("box_big", P.box_treadmill), "caixa", float(P.box_treadmill.y))
	add_occ(local, "caixa_arte_grande", frames_at("box_big", P.box_art), "caixa", float(P.box_art.y))
	add_occ(local, "caixa_arte_pequena", frames_at("box_small", P.box_art), "caixa", float(P.box_art.y))
	add_occ(local, "caixa_luva", frames_at("box_small", P.box_glove), "caixa", float(P.box_glove.y))
	add_occ(local, "caixa_corda", frames_at("box_small", P.box_rope), "caixa", float(P.box_rope.y))
	add_occ(local, "mural", [[frame_of("wall_mural" + s, 3), P_MURAL]], "parede", -45.0)
	if local == "academia":
		add_occ(local, "foto", [[frame_of("wall_photo_old_gym", 1), P_PHOTO]], "parede", -40.0)

## pares que nunca aparecem juntos (o mesmo lugar em momentos diferentes)
func exclusivo(a: String, b: String) -> bool:
	var grupos := [["john_sentado", "ultimo_sentado"], ["esteira_encostada", "caixa_esteira"],
		["boneco_descanso", "caixa_arte_grande", "caixa_arte_pequena"], ["caixa_arte_grande", "caixa_arte_pequena"],
		["john_sentado", "caixote"], ["ultimo_sentado", "caixote"]]
	for g in grupos:
		if a in g and b in g:
			return true
	return false

func head_box(name: String) -> Rect2i:
	var o := occ_of(CUR_LOCAL, name)
	if o.is_empty():
		return Rect2i()
	var r: Rect2i = o.rect
	if name in ["john_sentado", "ultimo_sentado"]:
		var mm: Vector2i = pt(CUR_LOCAL, "mentor")
		return Rect2i(mm.x - 6, mm.y - 57, 14, 14)
	return Rect2i(r.position.x + r.size.x / 2 - 7, r.position.y, 14, 14)

var CUR_LOCAL := ""
var REPORT := {}

func path_rects(local: String) -> Array:
	var out := []
	for pth in PATHS[local]:
		var a := Vector2(pth[0])
		var b := Vector2(pth[1])
		for i in 31:
			var p := a.lerp(b, i / 30.0)
			out.append(Rect2i(int(p.x) - 12, int(p.y) - 66, 24, 66))
	return out

func check(local: String) -> int:
	CUR_LOCAL = local
	build_occ(local)
	var occ: Dictionary = OCC[local]
	var probs := []
	var avisos := []
	var keys := occ.keys()
	print("==== %s" % local)
	for k in keys:
		var r: Rect2i = occ[k].rect
		print("  %-20s x %3d..%3d  y %3d..%3d" % [k, r.position.x, r.end.x - 1, r.position.y, r.end.y - 1])
	# 1) sobreposição de pixels entre tudo (menos o alvo com ele mesmo e os exclusivos)
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			var a: String = keys[i]
			var b: String = keys[j]
			if exclusivo(a, b):
				continue
			if occ[a].kind == "alvo" and occ[b].kind == "alvo":
				continue
			var ra: Rect2i = occ[a].rect
			var rb: Rect2i = occ[b].rect
			if not ra.intersects(rb):
				continue
			var inter := ra.intersection(rb)
			var n := 0
			for yy in range(inter.position.y, inter.end.y):
				for xx in range(inter.position.x, inter.end.x):
					var v := Vector2i(xx, yy)
					if occ[a].px.has(v) and occ[b].px.has(v):
						n += 1
			if n > 0:
				var msg := "%s x %s: %d px" % [a, b, n]
				# a pera da parede, o saco de lado e a corda são do fundo do jeito de hoje (não mudaram)
				if (a in ["saco_de_lado", "corda_gancho", "pera_parede"]) and (b in ["saco_de_lado", "corda_gancho", "pera_parede"]):
					avisos.append(msg + " (igual a hoje)")
				else:
					probs.append(msg)
	# 2) faixa do alvo
	for k in keys:
		if occ[k].kind == "alvo" or k in ["corda_gancho", "saco_de_lado"]:
			continue
		if (occ[k].rect as Rect2i).intersects(ALVO):
			var n := 0
			for v in occ[k].px:
				if ALVO.has_point(v):
					n += 1
			if n > 0:
				probs.append("%s entra na zona do alvo: %d px" % [k, n])
	# 3) caminho da porta até o centro
	var prs := path_rects(local)
	for k in keys:
		if occ[k].kind in ["alvo", "parede"] or k in ["saco_de_lado", "corda_gancho"]:
			continue
		var hit := false
		for pr in prs:
			if (occ[k].rect as Rect2i).intersects(pr):
				var inter: Rect2i = (occ[k].rect as Rect2i).intersection(pr)
				for yy in range(inter.position.y, inter.end.y):
					for xx in range(inter.position.x, inter.end.x):
						if occ[k].px.has(Vector2i(xx, yy)):
							hit = true
							break
					if hit:
						break
			if hit:
				break
		if hit:
			probs.append("%s no caminho da porta" % k)
	# 4) com o painel fixado (x >= 506): o que precisa ficar à vista
	for k in keys:
		var r: Rect2i = occ[k].rect
		if r.end.x - 1 >= PANEL_X:
			var essencial: bool = occ[k].kind == "caixa" or k in ["osmar", "john_sentado", "ultimo_sentado", "mentor_2", "mural", "foto", "caixote"]
			var n := 0
			for v in occ[k].px:
				if v.x >= PANEL_X:
					n += 1
			var tot: int = occ[k].px.size()
			var msg := "%s: %d de %d px atrás do painel fixado" % [k, n, tot]
			if essencial:
				probs.append(msg)
			else:
				avisos.append(msg)
	# 5) faixa de baixo e chão
	for k in keys:
		var r: Rect2i = occ[k].rect
		if r.end.y > STRIP_Y:
			probs.append("%s passa da faixa de baixo (y %d)" % [k, r.end.y - 1])
	# 6) balão do Osmar (154x36 acima da cabeça) não cobre cabeça
	var hb := {}
	for k in keys:
		if occ[k].kind == "gente" or k == "lutador":
			hb[k] = head_box(k)
	var pc := pt(local, "coach")
	var ob := Rect2i(clampi(pc.x + 1 - 77, 4, 640 - 158), pc.y - 63 - 6 - 3 - 26 - 6, 154, 36)
	# 7) 6d3: ninguém (gente, caixote, caixas) na frente do carro da garagem
	if local == "garagem":
		for k in keys:
			if occ[k].kind in ["parede", "alvo"] or k in ["saco_de_lado", "corda_gancho"]:
				continue
			var n := 0
			for v in occ[k].px:
				if CAR_PX.has(v):
					n += 1
			if n > 0:
				probs.append("%s na frente do carro: %d px" % [k, n])
	for k in hb:
		if k == "osmar":
			continue
		if ob.intersects(hb[k]):
			probs.append("balão do Osmar cobre a cabeça de %s" % k)
	print("  balão do Osmar: %s" % str(ob))
	for a in avisos:
		print("  AVISO " + a)
	for p in probs:
		print("  PROBLEMA " + p)
	REPORT[local] = {"probs": probs, "avisos": avisos, "balao": ob}
	return probs.size()

func dashed(img: Image, r: Rect2i, c: String) -> void:
	for x in range(r.position.x, r.end.x):
		if x % 4 < 2:
			L.P(img, x, r.position.y, c)
			L.P(img, x, r.end.y - 1, c)
	for y in range(r.position.y, r.end.y):
		if y % 4 < 2:
			L.P(img, r.position.x, y, c)
			L.P(img, r.end.x - 1, y, c)

func conferencia(local: String) -> void:
	CUR_LOCAL = local
	var im: Image = compose(local, "cheia")
	# caixas e boneco/esteira por cima (os dois estados), só em contorno
	for k in ["caixa_esteira", "caixa_arte_grande", "caixa_luva", "caixa_corda", "boneco_descanso", "ultimo_sentado"]:
		dashed(im, OCC[local][k].rect, "y1")
	dashed(im, ALVO, "r3")
	for pr in [PATHS[local]]:
		for pth in pr:
			var a := Vector2(pth[0])
			var b := Vector2(pth[1])
			for i in 81:
				var p := a.lerp(b, i / 80.0)
				for sx in [-12, 12]:
					if i % 4 < 2:
						L.P(im, int(p.x) + sx, int(p.y), "gr3")
				L.P(im, int(p.x), int(p.y), "gr3")
	for y in range(18, STRIP_Y):
		if y % 4 < 2:
			L.P(im, PANEL_X, y, "b3")
	var ob: Rect2i = REPORT[local].balao
	dashed(im, ob, "white")
	for k in OCC[local]:
		if OCC[local][k].kind == "gente" or k == "lutador":
			dashed(im, head_box(k), "p2")
	# régua das fileiras
	for yy: int in [256, 322]:
		for x in range(0, 640, 3):
			L.P(im, x, yy, "y2")
	var big := _x2(im)
	var lab: Image = L.blank(1280, 40)
	L.R(lab, 0, 0, 1280, 40, "d1")
	L.text(lab, "CONFERENCIA %s: VERMELHO = ZONA DO ALVO; VERDE = CAMINHO DA PORTA (24 PX); AZUL = BORDA DO PAINEL FIXADO (X 506);" % local.to_upper(), 8, 6, "white", 1, "ink")
	L.text(lab, "AMARELO = CAIXAS / BONECO / ULTIMO SENTADO (OUTROS MOMENTOS); ROXO = CABECAS; BRANCO = BALAO DO OSMAR; RISCO AMARELO = FILEIRAS (Y 256 E 322)", 8, 18, "white", 1, "ink")
	var probs: Array = REPORT[local].probs
	L.text(lab, "PROBLEMAS: %d" % probs.size(), 8, 30, "gr3" if probs.is_empty() else "r3", 1, "ink")
	var out: Image = L.blank(1280, 760)
	out.blit_rect(lab, Rect2i(0, 0, 1280, 40), Vector2i.ZERO)
	out.blit_rect(big, Rect2i(0, 0, 1280, 720), Vector2i(0, 40))
	out.save_png(OUT + "fase6d2_layout_%s_conferencia_x2.png" % local)

func comparacao(local: String) -> void:
	var antes_f := _load(ROOT + "docs/arte/mockups/fase6d_tela_c_%s_fechado.png" % local)
	var antes_a := _load(ROOT + "docs/arte/mockups/fase6d_tela_c_%s_aberto.png" % local)
	var dep_f := _load(OUT + "fase6d2_layout_%s_fechado_cheia.png" % local)
	var dep_a := _load(OUT + "fase6d2_layout_%s_fixado_cheia.png" % local)
	var pad := 8
	var lab := 14
	var img: Image = L.blank(pad * 3 + 1280, pad * 3 + 2 * (lab + 360))
	L.R(img, 0, 0, img.get_width(), img.get_height(), "d1")
	var cells := [["ANTES (6D, SALA SO ESTICADA)  PAINEL FECHADO", antes_f, pad, pad],
		["DEPOIS (6D2)  PAINEL FECHADO", dep_f, pad * 2 + 640, pad],
		["ANTES  PAINEL ABERTO", antes_a, pad, pad * 2 + lab + 360],
		["DEPOIS  PAINEL FIXADO", dep_a, pad * 2 + 640, pad * 2 + lab + 360]]
	for c in cells:
		L.text(img, c[0], c[2], c[3] + 3, "white", 1, "ink")
		img.blit_rect(c[1], Rect2i(0, 0, 640, 360), Vector2i(c[2], c[3] + lab))
	img.save_png(OUT + "fase6d2_layout_%s_comparacao.png" % local)


# ================================================================== --final: sprites de verdade em assets/sprites
## Grava os 2 fundos 640x360 e refaz, sobre o chão novo, as peças que eram recortadas do fundo antigo
## (luz do dia, sombra da porta, metade escura e porta da academia) e a luz pintada dos aparelhos que mudaram de ponto.
## O manifest é atualizado por tools/art/manifest_6d2.py.
func write_assets() -> void:
	var og := _canvas(_load(FONTE + "garage_bg.png"))
	var oy := _canvas(_load(FONTE + "gym_bg.png"))
	var ng: Image = BG["garagem"]
	var ny: Image = BG["academia"]
	ng.save_png(ASSETS + "garage/garage_bg.png")
	ny.save_png(ASSETS + "gym/gym_bg.png")
	# luz do dia da garagem (3 quadros, 170x70 -> 170x90 com a ponta esmaecendo no chão novo)
	var gd_old := _frames(_load(FONTE + "garage_daylight.png"), 170, 70)
	var gd_new := []
	for q in gd_old.size():
		gd_new.append(derive_daylight(gd_old[q], Vector2i(308, 220), og, ng, 90))
	_strip(gd_new).save_png(ASSETS + "garage/garage_daylight.png")
	# sombra da porta, assada sobre a luz (0 sobre a luz 0; 1..3 sobre a luz 2)
	var sh_old := _frames(_load(FONTE + "garage_door_shadow.png"), 64, 32)
	var sh_new := []
	for q in sh_old.size():
		var li := 0 if q == 0 else 2
		var base_old: Image = og.duplicate()
		blend(base_old, gd_old[li], 308, 220)
		var base_new: Image = ng.duplicate()
		blend(base_new, gd_new[li], 308, 220)
		sh_new.append(derive(sh_old[q], Vector2i(374, 214), base_old, base_new))
	_strip(sh_new).save_png(ASSETS + "garage/garage_door_shadow.png")
	# luz do dia da academia (2 quadros, 146x70 -> 146x90)
	var yd_old := _frames(_load(FONTE + "gym_daylight.png"), 146, 70)
	var yd_new := []
	for q in yd_old.size():
		yd_new.append(derive_daylight(yd_old[q], Vector2i(330, 220), oy, ny, 90))
	_strip(yd_new).save_png(ASSETS + "gym/gym_daylight.png")
	# porta da academia: as linhas de baixo eram chão
	var door_old := _frames(_load(FONTE + "gym_door.png"), 60, 108)
	var oy_dark := half_dark_apply(oy)
	var ny_dark := half_dark_apply(ny)
	var door_new := []
	for q in door_old.size():
		if q >= 3:
			door_new.append(derive(door_old[q], Vector2i(401, 116), oy_dark, ny_dark))
		else:
			door_new.append(derive(door_old[q], Vector2i(401, 116), oy, ny))
	_strip(door_new).save_png(ASSETS + "gym/gym_door.png")
	# metade escura: agora 640x360 em (0,0), furo na porta
	half_dark(ny).save_png(ASSETS + "gym/gym_half_dark.png")
	# aparelhos com luz pintada que mudaram de ponto: [id, pasta, ponto antigo, ponto novo, pivô, luz, passo mínimo]
	var rel := [["treadmill_l0_side", "equipment", Vector2i(445, 267), P.treadmill_side, Vector2i(43, 41), "garage", -2],
		["treadmill_l1_side", "equipment", Vector2i(445, 267), P.treadmill_side, Vector2i(43, 41), "garage", -2],
		["treadmill_l0_side_gym", "equipment", Vector2i(445, 267), P.treadmill_side, Vector2i(43, 41), "gym", 0],
		["treadmill_l1_side_gym", "equipment", Vector2i(445, 267), P.treadmill_side, Vector2i(43, 41), "gym", 0],
		["grappling_dummy_l0_rest", "equipment", Vector2i(228, 283), P.dummy_rest, Vector2i(32, 27), "garage", -1],
		["grappling_dummy_l1_rest", "equipment", Vector2i(228, 283), P.dummy_rest, Vector2i(32, 27), "garage", -1],
		["grappling_dummy_l0_rest_gym", "equipment", Vector2i(228, 283), P.dummy_rest, Vector2i(32, 27), "gym", 0],
		["grappling_dummy_l1_rest_gym", "equipment", Vector2i(228, 283), P.dummy_rest, Vector2i(32, 27), "gym", 0],
		["garage_crate_gym", "garage", Vector2i(238, 232), P.mentor + CRATE_OFF, Vector2i.ZERO, "gym", 0]]
	for r in rel:
		var src := _load(FONTE + str(r[0]) + ".png")
		var tl_old: Vector2i = r[2] - r[4]
		var tl_new: Vector2i = r[3] - r[4]
		relight(src, tl_old, tl_new, str(r[5]), int(r[6])).save_png(ASSETS + str(r[1]) + "/" + str(r[0]) + ".png")
	_cache.clear()
	print("final: fundos, luz do dia, sombra da porta, porta e metade escura da academia e 9 aparelhos gravados em " + ASSETS)

func _canvas(old: Image) -> Image:
	var c: Image = L.blank(640, 360)
	c.blit_rect(old, Rect2i(Vector2i.ZERO, old.get_size()), OLD.position)
	return c

func _frames(sheet: Image, fw: int, fh: int) -> Array:
	var out := []
	for q in sheet.get_width() / fw:
		out.append(sheet.get_region(Rect2i(q * fw, 0, fw, fh)))
	return out

func _strip(frames: Array) -> Image:
	var fw: int = frames[0].get_width()
	var s: Image = L.blank(fw * frames.size(), frames[0].get_height())
	for i in frames.size():
		s.blit_rect(frames[i], Rect2i(0, 0, fw, frames[i].get_height()), Vector2i(i * fw, 0))
	return s

## passo na rampa que leva a cor b à cor p (99 se não estão na mesma rampa)
func ramp_delta(b: Color, p: Color) -> int:
	if b.a == 0.0:
		return 99
	if b.to_html(false) == p.to_html(false):
		return 0
	for n: int in [1, -1, 2, -2, 3, -3]:
		if L.shade(b, n).to_html(false) == p.to_html(false):
			return n
	return 99

## Refaz um sprite que era "o fundo com N passos de luz": mesmo N por pixel, agora sobre o fundo novo.
## Pixel que não vem do fundo (desenho da porta, contorno) fica igual.
func derive(old: Image, at: Vector2i, base_old: Image, base_new: Image) -> Image:
	var out: Image = old.duplicate()
	for y in old.get_height():
		for x in old.get_width():
			var p := old.get_pixel(x, y)
			var sx := x + at.x
			var sy := y + at.y
			if p.a == 0.0 or sx < 0 or sy < 0 or sx >= 640 or sy >= 360:
				continue
			var n := ramp_delta(base_old.get_pixel(sx, sy), p)
			if n != 99:
				out.set_pixel(x, y, L.shade(base_new.get_pixel(sx, sy), n))
	return out

## Luz do dia: deriva os 70 px de hoje e, se o quadro chegava na borda de baixo da sala antiga (y 289), continua o trapézio
## mais 20 px esmaecendo em dither (antes a faixa de baixo escondia o corte; agora o chão continua).
func derive_daylight(old: Image, at: Vector2i, base_old: Image, base_new: Image, new_h: int) -> Image:
	var d := derive(old, at, base_old, base_new)
	var out: Image = L.blank(old.get_width(), new_h)
	out.blit_rect(d, Rect2i(0, 0, d.get_width(), d.get_height()), Vector2i.ZERO)
	var h := old.get_height()
	var last := _row_span(old, h - 1)
	var prev := _row_span(old, h - 21)
	if last.x < 0 or prev.x < 0:
		return out
	var dl := float(last.x - prev.x) / 20.0
	var dr := float(last.y - prev.y) / 20.0
	for y in range(h, new_h):
		var k := y - (h - 1)
		var xl := int(round(last.x + dl * k))
		var xr := int(round(last.y + dr * k))
		var t := float(k) / float(new_h - h + 1)
		for x in range(maxi(xl, 0), mini(xr + 1, old.get_width())):
			var sx := x + at.x
			var sy := y + at.y
			if bayer(sx, sy) > t * 1.05 and on_floor(sx, sy):
				out.set_pixel(x, y, L.shade(base_new.get_pixel(sx, sy), 1))
	return out

func _row_span(img: Image, y: int) -> Vector2i:
	var a := -1
	var b := -1
	for x in img.get_width():
		if img.get_pixel(x, y).a > 0.0:
			if a < 0:
				a = x
			b = x
	return Vector2i(a, b)

func _hd_step(x: int, y: int) -> int:
	if x >= 340:
		return -1
	if x >= 300 and bayer(x, y) < float(x - 300 + 1) / 41.0:
		return -1
	return 0

func half_dark_apply(img: Image) -> Image:
	var out: Image = img.duplicate()
	for y in 360:
		for x in 640:
			if _hd_step(x, y) != 0:
				out.set_pixel(x, y, L.shade(img.get_pixel(x, y), -1))
	return out

func half_dark(bg: Image) -> Image:
	var out: Image = L.blank(640, 360)
	var furo := Rect2i(401, 116, 60, 108)
	for y in 360:
		for x in 640:
			if furo.has_point(Vector2i(x, y)):
				continue
			if _hd_step(x, y) != 0:
				out.set_pixel(x, y, L.shade(bg.get_pixel(x, y), -1))
	return out

## Passo de luz antigo (a conta que pintou o sprite) e novo (sala larga) por pixel; aplica a diferença.
func relight(src: Image, tl_old: Vector2i, tl_new: Vector2i, kind: String, min_step: int) -> Image:
	var out: Image = src.duplicate()
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var a: int
			var b: int
			if kind == "garage":
				a = light_step(x + tl_old.x, y + tl_old.y, [GARAGE_LIGHTS[0]], min_step)
				b = light_step(x + tl_new.x, y + tl_new.y, GARAGE_LIGHTS, min_step)
			else:
				a = mini(gym_step_old(x + tl_old.x, y + tl_old.y), 0)
				b = mini(gym_step(x + tl_new.x, y + tl_new.y), 0)
			if b != a:
				out.set_pixel(x, y, L.shade(c, b - a))
	return out

func gym_step_old(x: int, y: int) -> int:
	var best := -9.0
	for t: Vector2i in TUBES:
		var d := Vector2(x - t.x, (y - t.y - 30) * 0.8).length() / 260.0
		best = maxf(best, 0.95 - d * 1.9)
	best -= clampf(float(y - 250) / 120.0, 0.0, 0.35)
	var base := floorf(best)
	var fr := clampf((best - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
	return clampi(int(base) + (1 if fr > bayer(x, y) else 0), -2, 1)
