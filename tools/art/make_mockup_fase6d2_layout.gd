extends SceneTree
## Fase 6d2 (Diretor de Arte): PROPOSTA de sala larga de verdade (640x360) e de pontos novos. PLACEHOLDER gerado por código.
## Nada aqui entra no jogo: grava só imagens em docs/arte/mockups/fase6d2_*.png. Proposta: docs/arte/fase6d2-layout.md.
##
## Rodar a partir de uma pasta com um project.godot vazio (não dispara import no projeto):
##   godot --headless --path <pasta_vazia> --quit-after 60 --script E:/Fightclicker/tools/art/make_mockup_fase6d2_layout.gd
##       [-- --saida <pasta>]      (sem --saida grava em docs/arte/mockups/)
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
	DirAccess.make_dir_recursive_absolute(OUT)
	var f := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.READ)
	MAN = JSON.parse_string(f.get_as_text())
	for k in ["garagem", "academia", "garagem_loja"]:
		REF[k] = _load(ROOT + "docs/arte/mockups/fase6d_ref_%s.png" % k)
	BG["garagem"] = build_garage()
	BG["academia"] = build_gym()
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
	var old := _load(ROOT + "assets/sprites/garage/garage_bg.png")
	var full_old: Image = L.blank(640, 360)
	full_old.blit_rect(old, Rect2i(Vector2i.ZERO, old.get_size()), OLD.position)
	paste_old(img, full_old, COPY)
	# o carro e a sombra dele passam da linha do chão: cola também esse pedaço do chão de hoje
	paste_old(img, full_old, Rect2i(176, 220, 104, 11))
	garage_after_light(img)
	for pr: Rect2i in [PIL_L, PIL_R]:
		garage_pillar(img, pr)
	return img

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
	L.ellipse_dither(img, 530, 300, 26, 6, "g0")
	L.ellipse(img, 536, 301, 10, 2.5, "g0")
	L.ellipse_dither(img, 120, 236, 22, 4, "g1", 1)
	L.ellipse_dither(img, 268, 318, 10, 2, "g1")
	L.R(img, 388, 290, 14, 5, "d2")
	for i in 4:
		L.R(img, 389 + i * 3, 291, 2, 3, "ink")
	L.R(img, 388, 290, 14, 1, "g0")
	# giz: as marcas da corda (do lado esquerdo do alvo, onde o lutador pula) e um círculo de treino
	for i in 2:
		var cx := 236 + i * 20
		L.line(img, cx, 286, cx + 7, 291, "cream")
		L.line(img, cx + 7, 286, cx, 291, "cream")
	L.ring(img, 120, 292, 13, 4, 1, "cream")
	L.dither(img, 20, 312, 18, 2, "g3")

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
	# bancada
	L.R(img, 74, 178, 88, 5, "ink")
	L.R(img, 75, 179, 86, 3, "br2"); L.R(img, 75, 179, 86, 1, "br3")
	L.R(img, 78, 183, 4, 39, "br1"); L.R(img, 154, 183, 4, 39, "br1")
	L.R(img, 78, 204, 80, 3, "br1"); L.R(img, 78, 204, 80, 1, "br2")
	L.R(img, 77, 183, 1, 39, "ink"); L.R(img, 158, 183, 1, 39, "ink")
	# morsa na ponta esquerda e coisas em cima
	L.R(img, 78, 170, 14, 8, "st1"); L.R(img, 78, 170, 14, 1, "st3"); L.R(img, 76, 173, 3, 3, "st0"); L.R(img, 84, 166, 2, 4, "st0")
	var tb: Image = L.blank(22, 11)
	L.R(tb, 0, 2, 22, 9, "r1"); L.R(tb, 0, 2, 22, 1, "r2"); L.R(tb, 7, 0, 8, 2, "d1"); L.R(tb, 0, 6, 22, 1, "r0")
	L.stamp(img, tb, 122, 167)
	var lata: Image = L.blank(8, 9)
	L.R(lata, 0, 0, 8, 9, "b1"); L.R(lata, 0, 0, 8, 1, "b2"); L.R(lata, 0, 3, 8, 3, "cream")
	L.stamp(img, lata, 100, 169)
	# embaixo da bancada: balde e pneu de bicicleta encostado
	var balde: Image = L.blank(12, 12)
	L.trap(balde, 0, 11, 0, 11, 1, 10, "st2"); L.R(balde, 0, 0, 12, 1, "st3"); L.R(balde, 2, 4, 8, 1, "st1")
	L.stamp(img, balde, 86, 209)
	L.ring(img, 132, 211, 9, 9, 2, "d1"); L.ring(img, 132, 211, 7, 7, 1, "g0"); L.P(img, 132, 211, "st2")
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
	var gx := 484
	L.R(img, gx - 1, 147, 34, 76, "ink")
	L.R(img, gx, 148, 32, 74, "cream"); L.R(img, gx, 148, 32, 2, "white"); L.R(img, gx + 28, 150, 4, 72, "g3")
	L.R(img, gx, 176, 32, 1, "g2"); L.R(img, gx, 177, 32, 1, "g3")
	L.R(img, gx + 25, 156, 2, 14, "st1"); L.R(img, gx + 25, 182, 2, 18, "st1")
	L.R(img, gx + 5, 156, 4, 4, "r2"); L.R(img, gx + 12, 158, 3, 3, "gr2"); L.R(img, gx + 7, 186, 9, 11, "white"); L.R(img, gx + 8, 188, 7, 1, "g2"); L.R(img, gx + 8, 190, 6, 1, "g2")
	L.P(img, gx + 11, 186, "r1")
	L.R(img, gx + 2, 218, 4, 4, "d1"); L.R(img, gx + 26, 218, 4, 4, "d1")
	for i in 4:
		var ty := 208 - i * 9
		L.ellipse(img, 543, ty + 4, 19, 5, "ink")
		L.ellipse(img, 543, ty + 3, 18, 4, "d1")
		L.ellipse(img, 543, ty + 2, 9, 2, "g0")
		L.R(img, 525, ty + 3, 37, 1, "d2")
	L.ring(img, 551, 112, 9, 8, 2, "gr1"); L.ring(img, 551, 112, 6, 5, 1, "gr2"); L.R(img, 550, 102, 2, 3, "st1")
	L.R(img, 494, 96, 18, 22, "ink"); L.R(img, 495, 97, 16, 20, "st1"); L.R(img, 497, 99, 12, 7, "st3"); L.R(img, 498, 101, 10, 3, "d1")
	L.R(img, 502, 117, 2, 30, "st0")
	# ---- parede direita: escada de alumínio encostada
	var ladder := [[598, 300, 588, 120], [628, 312, 616, 128]]
	for rail in ladder:
		L.line(img, rail[0], rail[1], rail[2], rail[3], "st3")
		L.line(img, rail[0] + 1, rail[1], rail[2] + 1, rail[3], "st1")
	for i in 9:
		var t := float(i + 1) / 10.0
		var ax := int(lerpf(598, 588, t))
		var ay := int(lerpf(300, 120, t))
		var bx := int(lerpf(628, 616, t))
		var by := int(lerpf(312, 128, t))
		L.line(img, ax, ay, bx, by, "st2")

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
	var old := _load(ROOT + "assets/sprites/gym/gym_bg.png")
	var full_old: Image = L.blank(640, 360)
	full_old.blit_rect(old, Rect2i(Vector2i.ZERO, old.get_size()), OLD.position)
	paste_old(img, full_old, COPY)
	# pés do banco e a sombra dele passam da linha do chão
	paste_old(img, full_old, Rect2i(174, 220, 72, 3))
	for t: Vector2i in TUBES_NEW:
		blend(img, tube_sprite(), t.x - 24, t.y)
	for pr: Rect2i in [PIL_L, PIL_R]:
		gym_pillar(img, pr)
	return img

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
	it.append(item_img("osmar", frame_of(coach_id, 0), P_COACH, "gente"))
	if equipe == "cheia":
		var m: Vector2i = P.mentor
		it.append({"name": "caixote", "img": frame_of("garage_crate" + s), "at": m + CRATE_OFF - Vector2i(0, 0), "y": float(m.y - 2),
			"shadow": null, "kind": "objeto", "id": "garage_crate" + s, "pos": m + CRATE_OFF})
		it.append(item_img("john_sentado", frame_of("john_sit_rest", 0), m, "gente"))
		it.append(item_img("mentor_2", layered("disciple_stand_bare", 0, M2_LOOK), P.mentor_2, "gente"))
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
	add_occ(local, "osmar", frames_at(coach_id, P_COACH), "gente", float(P_COACH.y))
	var m: Vector2i = P.mentor
	add_occ(local, "john_sentado", frames_at("john_sit_rest", m), "gente", float(m.y))
	var a2 := []
	for q in 4:
		a2.append([layered("disciple_sit_rest", q, M2_LOOK), m - GPIV])
	add_occ(local, "ultimo_sentado", a2, "gente", float(m.y))
	add_occ(local, "caixote", [[frame_of("garage_crate" + s), m + CRATE_OFF - Vector2i(16, 20) + Vector2i(16, 20)]], "objeto", float(m.y - 2))
	var a3 := []
	for q in 4:
		a3.append([layered("disciple_stand_bare", q, M2_LOOK), P.mentor_2 - GPIV])
	add_occ(local, "mentor_2", a3, "gente", float(P.mentor_2.y))
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
		var mm: Vector2i = P.mentor
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
	var ob := Rect2i(clampi(P_COACH.x + 1 - 77, 4, 640 - 158), P_COACH.y - 63 - 6 - 3 - 26 - 6, 154, 36)
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
