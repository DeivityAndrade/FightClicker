extends SceneTree
## Fase 7a2 "Treino fora de hora" (Artista de Personagens, skill padrao-personagem): parceiro de treino do Choque (Boxe e
## Jiu-jitsu) e os passantes da Panfletagem, por personagem_lib.gd, com as poses em dados de tools/art/golpes_7a2.json
## (autoria: tools/art/poses_7a2.py). Monta também as pranchas com o discípulo (gerado antes por make_golpes_jogador.gd).
## Rodar headless a partir de uma pasta temporária com project.godot vazio (nunca no projeto):
##   FC_LUTADOR=disc FC_CAMADAS=1 FC_GOLPES=E:/Fightclicker/tools/art/golpes_7a2.json godot --headless --path <tmp> \
##       --script E:/Fightclicker/tools/art/make_golpes_jogador.gd -- <tmp>/out_j
##   godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_sprites_fase7a2.gd -- <tmp>/out_j <tmp>/out <pranchas>
## Passantes: quadro 48x76, pivô (24,71) (a cabeça do andar encostava no topo do 48x72).
## Escreve em <tmp>/out: minigame/*.png, manifest_7a2.json (entradas prontas) e relatorio.txt; em <pranchas>: os PNG da prancha.
## Lê (só leitura) assets/sprites/manifest.json e assets/sprites/characters/coach_idle*.png. Não grava nada no projeto.

const ROOT := "E:/Fightclicker/"
const FW := 112
const FH := 104
const PW := 48          # passantes: quadro da sala
const PH := 76
const PPIV := Vector2(24, 71)
const POS_J := Vector2i(296, 318)
const POS_O := Vector2i(346, 318)

var L
var P
var D: Dictionary
var J := ""
var OUT := ""
var PR := ""
var report: Array = []
var entradas := {}
var folhas := {}        # id -> Array[Image]

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================ cabeças (dados, desenhadas à mão)
## Parceiro do Boxe: capacete de treino azul da Raízes (G/g/w) cobrindo topo, orelha e bochecha; rosto aberto.
const HEAD_CAPACETE := [
	"....GGGGGG....",
	"..GGgggwwGGG..",
	".GGggggwwgGGG.",
	".GgggggggggGG.",
	"GggggggGGsll..",
	"GgggggGGsbbbl.",
	"GgwggGGssesl..",
	"GgwggGGssssl..",
	".GgggGGssssll.",
	".GGgGssssssss.",
	"..GGSsssssss..",
	"...GSssssmSs..",
	"...GGSsssss...",
	"....GSSSss....",
]
## Parceiro do Jiu-jitsu: cabelo raspado dos lados com topo crespo curto, barba rala (u).
const HEAD_JJ := [
	"....HhHhHH....",
	"..HhHhhHhHHH..",
	".HHhhhhhhhHHH.",
	".HHHHHHHHHHHs.",
	"HHHHHHHsssll..",
	"HHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	".HHEEssssssll.",
	".HHHsssssssss.",
	"..HuSsssssss..",
	"...uuSsssmSu..",
	"....uuussuu...",
	".....uuuuu....",
]
## Passantes (perfil 14x14, âncora 7,7 / 3/4 13x13, âncora 6,6): só o cabelo muda em relação ao HEAD_SIDE/HEAD_34.
const SIDE_COQUE := [
	"....HHHHHH....",
	".hhHHHhhHHHH..",
	"hhhHHhhhhHHHH.",
	"hhHHHHHHHHHHH.",
	"HHHHHHHsssll..",
	"HHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	".HHEEssssssll.",
	".HHHsssssssss.",
	"..HSssssssss..",
	"...SSssssmSs..",
	"....SSsssss...",
	".....SSSss....",
]
const H34_COQUE := [
	"hh.HHHHHHH...",
	"hhHHHhhhHHHH.",
	"HhHHhhhhhHHHH",
	"HHHHHHHHHHHHs",
	"HHHHsslllllll",
	"HHHSsbbsslbbl",
	"HHESsesssles.",
	"HEsSssssslll.",
	".HESssssssss.",
	".HSsssssssSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]
const SIDE_BONE := [
	"....CCCCCC....",
	"..CCcccccCCC..",
	".CCccccccccCC.",
	".CCCCCCCCCkkkk",
	"HHHHHHHsssll..",
	"HHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	".HHEEssssssll.",
	".HHHsssssssss.",
	"..HuSsssssss..",
	"...uuSsssmSs..",
	"....uuuSsss...",
	".....SSSss....",
]
const H34_BONE := [
	"...CCCCCCC...",
	".CCcccccCCCC.",
	"CCcccccccccCC",
	"CCCCCCCkkkkkk",
	"HHHHsslllllll",
	"HHHSsbbsslbbl",
	"HHESsesssles.",
	"HEsSssssslll.",
	".HESssssssss.",
	".HuSsssssssu.",
	"..uussmmmuu..",
	"...uuuuuuu...",
	".....SSSs....",
]
const SIDE_RABO := [
	"....HHHHHH....",
	"..HHHHhhHHHH..",
	".HHHHhhhhHHHH.",
	"hHHHHHHHHHHHH.",
	"hHHHHHHsssll..",
	"HHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	"hHHEEssssssll.",
	"hhHHsssssssss.",
	"h.HSssssssss..",
	"h..SSssssmSs..",
	"....SSsssss...",
	".....SSSss....",
]
const H34_RABO := [
	"...HHHHHHH...",
	".HHHHhhhHHHH.",
	"HHHHhhhhhHHHH",
	"HHHHHHHHHHHHs",
	"HHHHsslllllll",
	"HHHSsbbsslbbl",
	"HHESsesssles.",
	"HEsSssssslll.",
	"hHESssssssss.",
	"hHSsssssssSs.",
	"h.SsssmmmSs..",
	"h..SSsssss...",
	".....SSSs....",
]

func transfer_faces(base: Array, faces: Dictionary, custom: Array) -> Dictionary:
	var out := {}
	var face_chars := ["s", "S", "l", "e", "b", "m", "x", "E", "u", "o"]
	for f in faces:
		var ov: Dictionary = faces[f]
		var nd := {}
		for k in ov:
			var pr: String = base[int(k)]
			var fr: String = ov[k]
			var cr: String = custom[int(k)]
			var nr := ""
			for i in cr.length():
				var c := cr[i]
				if i < pr.length() and i < fr.length() and pr[i] != fr[i] and c in face_chars:
					c = fr[i]
				nr += c
			nd[int(k)] = nr
		out[f] = nd
	return out

# ================================================================ corpos
func parceiro_build(arte: String) -> Dictionary:
	# Aluno da Raízes, um pouco mais alto e mais magro que o discípulo (braço e perna +5%), ombro estreito.
	var o := {"lu": 12.6, "lf": 13.6, "lt": 18.3, "ls": 17.3, "shoulder": 1.0, "hip_w": 0.92,
		"arm_r": [2.8, 2.0, 2.2, 1.6], "leg_r": [3.9, 2.8, 2.5, 1.5],
		"hair": ["d1", "d2"], "brow": "ink", "skin": ["br1", "br2", "br3"]}
	if arte == "box":
		o.merge({"head_side": HEAD_CAPACETE, "head_legend_extra": {"G": "b0", "g": "b1", "w": "b2"},
			"top": "tank", "shirt": ["g1", "g2", "g3"], "shorts": ["r0", "r1", "r2"], "band": "white", "shorts_t": 0.45,
			"shoes": ["d1", "d2", "g0", "white", "g1"],
			"glove": "plain", "glove_ramp": ["gr0", "gr1", "gr2"]}, true)
	else:
		o.merge({"head_side": HEAD_JJ, "stubble": "br0",
			"top": "tshirt", "shirt": ["b0", "b1", "b2"], "sleeve_long": true, "shirt_detail": "gi", "neck_v": 0.2,
			"sleeve_add": 1.2, "sleeve_add_fore": 0.9,
			"bottom": "pants", "shorts": ["b0", "b1", "b2"], "band": "white", "pants_add": 1.2, "pants_shin_t": 0.84,
			"belt": ["g3", "white", "white", "g3"],
			"shoes": ["br1", "br2", "br3", "br3", "br1"],
			"shoe_maps": {"flat": {"rows": ["..DMM......", "..DMMM.....", ".DMMMMLL...", "DMMMMMMMMLw", ".DDD..DDDDD"], "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0), "ang": 0.0},
				"ball": {"rows": [".DM........", ".DMM.......", "..DMMM.....", "...DMMMLL..", "....DDMMMLw", "......DDDDD"], "toe": Vector2i(10, 5), "ankle": Vector2i(2, 0), "ang": 0.0}},
			"glove": "fist"}, true)
	o["faces_side"] = transfer_faces(P.HEAD_SIDE, P.FACES_SIDE, o.head_side)
	return P.build(o)

const TIPOS := ["estudante", "senhora", "trabalhador", "moca"]
const DICA := {"estudante": "pockets", "senhora": "crossed", "trabalhador": "hurry", "moca": "phone"}
const NOMES_TIPO := {"estudante": "ESTUDANTE (fone)", "senhora": "DONA DA FEIRA (braco cruzado)",
	"trabalhador": "TRABALHADOR (pressa)", "moca": "MOCA DA ACADEMIA (celular)"}

func pedestre_build(t: String) -> Dictionary:
	var o := {"lu": 10.0, "lf": 10.5, "lt": 15.0, "ls": 14.0, "glu": 10.0, "glf": 10.5, "glt": 14.2, "gls": 13.2,
		"arm_r": [2.4, 1.8, 1.9, 1.4], "leg_r": [3.3, 2.5, 2.3, 1.4], "shoulder": 0.82, "hip_w": 0.86, "glove": "open"}
	match t:
		"estudante":   # moletom vermelho, jeans, tênis branco, mochila
			o.merge({"hair": ["ink", "d2"], "brow": "ink", "skin": ["br1", "br2", "br3"],
				"top": "tshirt", "shirt": ["r0", "r1", "r2"], "sleeve_long": true,
				"bottom": "pants", "shorts": ["b0", "b1", "b2"], "band": "b0", "shoes": ["g1", "g3", "white", "white", "g2"]}, true)
		"senhora":     # coque grisalho, casaquinho roxo, saia/calça marrom, sapato
			o.merge({"head_side": SIDE_COQUE, "head_34": H34_COQUE, "hair": ["g2", "g3"], "brow": "g1", "skin": ["sk0", "sk1", "sk2"],
				"top": "tshirt", "shirt": ["p0", "p1", "p2"], "sleeve_long": true, "belly": 1.5, "hip_w": 1.0, "shoulder": 0.78,
				"bottom": "pants", "shorts": ["br0", "br1", "br2"], "band": "br0", "shoes": ["d1", "d2", "g0", "g1", "d2"]}, true)
		"trabalhador": # boné azul, uniforme cinza com friso amarelo, calça escura, bota
			o.merge({"head_side": SIDE_BONE, "head_34": H34_BONE, "cap": ["b0", "b1", "b2"], "stubble": "br0",
				"hair": ["d1", "d2"], "brow": "ink", "skin": ["sk1", "sk2", "y2"],
				"top": "tshirt", "shirt": ["st0", "st1", "st2"], "sleeve_t": 0.5, "trim": "y0", "shoulder": 0.92,
				"bottom": "pants", "shorts": ["d1", "d2", "g0"], "band": "d1", "shoes": ["br0", "br1", "br2", "br2", "d1"]}, true)
		"moca":        # rabo de cavalo, jaqueta verde, legging, tênis com detalhe vermelho
			o.merge({"head_side": SIDE_RABO, "head_34": H34_RABO, "hair": ["br0", "br1"], "brow": "br0", "skin": ["sk0", "sk1", "sk2"],
				"top": "tshirt", "shirt": ["gr0", "gr1", "gr2"], "sleeve_long": true, "shoulder": 0.76, "hip_w": 0.9,
				"bottom": "pants", "shorts": ["d1", "d2", "g0"], "band": "d1", "shoes": ["g1", "g3", "white", "r2", "g2"]}, true)
	if t == "moca" or t == "senhora":
		o["skin"] = ["br1", "br2", "br3"] if t == "moca" else ["sk0", "sk1", "sk2"]
	var hs: Array = o.get("head_side", P.HEAD_SIDE)
	o["faces_side"] = transfer_faces(P.HEAD_SIDE, P.FACES_SIDE, hs)
	o["faces_34"] = {"normal": {}}
	return P.build(o)

# ================================================================ quadros-chave -> quadros (cópia de make_golpes_jogador.expandir)
func suave(u: float, modo: String) -> float:
	match modo:
		"in":
			return u * u
		"out":
			return 1.0 - (1.0 - u) * (1.0 - u)
		"inout":
			return u * u * (3.0 - 2.0 * u)
	return u

func u_parte(lin: float, modo: String, lag: float) -> float:
	var l := lin
	if lag > 0.0:
		if modo == "out":
			l = clampf(lin * (1.0 + lag), 0.0, 1.0)
		else:
			l = clampf((lin - lag) / (1.0 - lag), 0.0, 1.0)
	return suave(l, modo)

func expandir(g: Dictionary) -> Array:
	if not g.has("keys"):
		return g.frames
	var keys: Array = g.keys
	var frames := []
	for i in int(g.n):
		var k0: Dictionary = keys[0]
		for kk in keys:
			if float(kk.at) <= float(i):
				k0 = kk
		var k1: Dictionary = k0
		for kk in keys:
			if float(kk.at) > float(k0.at):
				k1 = kk
				break
		var lin := 0.0
		if k1 != k0:
			lin = (float(i) - float(k0.at)) / (float(k1.at) - float(k0.at))
		var lags: Dictionary = g.get("lag", {})
		var q := {}
		for key in k0:
			if key in ["at", "ease", "hold"]:
				continue
			var a: Variant = k0[key]
			var b: Variant = k1.get(key, a)
			var u := u_parte(lin, str(k1.get("ease", "inout")), float(lags.get(key, 0.0)))
			if a is Array and b is Array and (a as Array).size() == 2:
				q[key] = [lerpf(float(a[0]), float(b[0]), u), lerpf(float(a[1]), float(b[1]), u)]
			elif (a is float or a is int) and (b is float or b is int):
				q[key] = lerpf(float(a), float(b), u)
			else:
				q[key] = a
		frames.append(q)
	return frames

func pose(q: Dictionary) -> Dictionary:
	var p := {}
	for k in q:
		if (k as String).begins_with("_") or k in ["view", "prop"]:
			continue
		var v: Variant = q[k]
		p[k] = Vector2(float(v[0]), float(v[1])) if (v is Array and (v as Array).size() == 2) else v
	return p

# ================================================================ adereços dos passantes
func px(lib, x: float, y: float, c: String, id: int) -> void:
	lib.put(int(round(x)), int(round(y)), c, id)

func adereco(q: Dictionary, p: Dictionary, t: String) -> void:
	var prop: String = q.get("prop", "")
	var mochila := t == "estudante"
	var lado := q.get("view", "side") as String
	if mochila and lado == "side":
		p["after_torso"] = func(lib, _O: Vector2, ctx: Dictionary) -> void:
			# mochila nas costas (atrás do braço de trás não: atrás do tronco, na frente do braço de trás)
			var hip: Vector2 = ctx.hip
			var top: Vector2 = ctx.top
			var dn: Vector2 = (top - hip).normalized()
			var fr: Vector2 = ctx.fr
			for ti in range(6, 17):
				for s in range(4, 9):
					var c := "b1" if s < 8 else "b0"
					if ti == 16 or s == 4:
						c = "b2" if ti == 16 else "b0"
					var pt: Vector2 = hip + dn * float(ti) - fr * float(s)
					if lib.ids[int(round(pt.y)) * lib.cw + int(round(pt.x))] == 0:
						px(lib, pt.x, pt.y, c, 29)
	if prop == "":
		return
	p["end"] = func(lib, _O: Vector2, ctx: Dictionary) -> void:
		match prop:
			"phone":       # celular na mão, tela acesa virada para o rosto
				var h: Vector2 = ctx.hf
				for yy in range(-4, 1):
					px(lib, h.x + 1, h.y + yy, "d1", 75)
					px(lib, h.x + 2, h.y + yy, "b3" if yy > -4 and yy < 0 else "d1", 75)
			"headphones":  # arco por cima da cabeça + concha na orelha
				var hd: Vector2 = ctx.hd
				for d in [V(-3, -6), V(-2, -7), V(-1, -8), V(0, -8), V(1, -8), V(2, -7), V(-4, -5), V(-4, -4), V(-4, -3)]:
					px(lib, hd.x + d.x, hd.y + d.y, "g2", 75)
				for d in [V(-5, -1), V(-4, -1), V(-5, 0), V(-4, 0), V(-5, 1), V(-4, 1)]:
					px(lib, hd.x + d.x, hd.y + d.y, "r1" if d.x == -5 else "r2", 75)
			"flyer":       # o panfleto da Raízes na mão
				var h: Vector2 = ctx.hf
				for yy in range(-5, 1):
					for xx in range(0, 4):
						var ix := int(round(h.x)) + xx
						var iy := int(round(h.y)) + yy
						if ix < 0 or iy < 0 or ix >= lib.cw or iy >= lib.ch:
							continue
						if lib.ids[iy * lib.cw + ix] == lib.NEAR_GLOVE and xx < 2:
							continue
						var c := "white"
						if xx == 3 or yy == 0:
							c = "cream"
						if xx == 1 and yy >= -4 and yy <= -2:
							c = "b1"
						lib.put(ix, iy, c, 74)

# ================================================================ geração
func gera_parceiro(arte: String, nome: String, g: Dictionary) -> Array:
	var b := parceiro_build(arte)
	var frames := []
	var i := 0
	for q in expandir(g):
		var im: Image = P.fight_frame(b, pose(q), "spar_partner_%s_%s[%d]" % [arte, nome, i], Vector2i(FW, FH), V(55, 98))
		im.flip_x()
		frames.append(im)
		i += 1
	return frames

func gera_pedestre(t: String, nome: String, g: Dictionary) -> Array:
	var b := pedestre_build(t)
	if g.get("hands", "") == "none":
		b.glove = "none"
	var frames := []
	var i := 0
	for q in g.frames:
		var p := pose(q)
		adereco(q, p, t)
		var tag := "ped_%s_%s[%d]" % [t, nome, i]
		var im: Image
		if q.get("view", "side") == "34":
			b.glove = "open"
			im = P.garage_frame(b, p, tag, Vector2i(PW, PH), PPIV)
		else:
			im = P.fight_frame(b, p, tag, Vector2i(PW, PH), PPIV)
		if g.get("hands", "") == "none":
			b.glove = "none"
		frames.append(im)
		i += 1
	return frames

func confere(id: String, frames: Array) -> void:
	for i in frames.size():
		var im: Image = frames[i]
		var w := im.get_width()
		var h := im.get_height()
		for y in h:
			for x in [0, w - 1]:
				if im.get_pixel(x, y).a > 0.0:
					report.append("AVISO %s[%d]: pixel na borda (x %d)" % [id, i, x])
					return
		for x in w:
			if im.get_pixel(x, 0).a > 0.0:
				report.append("AVISO %s[%d]: pixel na borda de cima" % [id, i])
				return

func grava(id: String, frames: Array, fs: Vector2i, piv: Array, fps: float, loop: bool, facing: String, nota: String, extra := {}) -> void:
	confere(id, frames)
	DirAccess.make_dir_recursive_absolute(OUT + "minigame")
	P.strip(frames).save_png(OUT + "minigame/%s.png" % id)
	folhas[id] = frames
	var e := {"file": "res://assets/sprites/minigame/%s.png" % id, "frame_size": [fs.x, fs.y], "frames": frames.size(),
		"fps": fps, "pivot": piv, "loop": loop, "facing": facing, "_nota": nota}
	e.merge(extra, true)
	entradas[id] = e

# ================================================================ pranchas
func load_abs(p: String) -> Image:
	var img := Image.load_from_file(p)
	img.convert(Image.FORMAT_RGBA8)
	return img

func quadros(path: String, fw: int, fh: int) -> Array:
	var img := load_abs(path)
	var out := []
	for i in maxi(img.get_width() / fw, 1):
		out.append(img.get_region(Rect2i(i * fw, 0, fw, fh)))
	return out

func fundo_noite(w: int, h: int, chao: int) -> Image:
	var im := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c: Color = L.col("d1") if y < chao else L.col("d2")
			if y < chao and (x / 4 + y / 4) % 9 == 0:
				c = L.col("b0")
			if y == chao:
				c = L.col("g0")
			im.set_pixel(x, y, c)
	return im

func blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))

func texto(dst: Image, s: String, x: int, y: int, c := "y1") -> void:
	L.text(dst, s, x, y, c)

func escala(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

## Uma fileira: cada célula = recorte da arena com o discípulo (296) e o parceiro (346), quadro a quadro.
func linha_choque(rot: String, disc: Array, parc: Array) -> Image:
	var n := maxi(disc.size(), parc.size())
	var cw := 120
	var chh := 96
	var row := Image.create_empty(cw * n, chh + 9, false, Image.FORMAT_RGBA8)
	row.fill(L.col("ink"))
	texto(row, rot, 1, 1)
	var bg := load_abs(ROOT + "assets/sprites/minigame/spar_bg.png")
	for i in n:
		var cel := bg.get_region(Rect2i(POS_J.x - 35, POS_J.y - 84, cw, chh))   # cenário real do Choque (Diretor de Arte)
		var a: Image = disc[mini(i, disc.size() - 1)]
		var b: Image = parc[mini(i, parc.size() - 1)]
		# pivôs: discípulo em x 35, parceiro em x 85 (50 px), chão em y 84
		blit(cel, a, 35 - 56, 84 - 98)
		blit(cel, b, 85 - 56, 84 - 98)
		blit(row, cel, i * cw, 9)
	return row

func empilha(rows: Array, gap := 2) -> Image:
	var w := 0
	var h := 0
	for r in rows:
		w = maxi(w, (r as Image).get_width())
		h += (r as Image).get_height() + gap
	var im := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	im.fill(L.col("ink"))
	var y := 0
	for r in rows:
		blit(im, r, 0, y)
		y += (r as Image).get_height() + gap
	return im

func disc(nome: String) -> Array:
	return quadros(J + "fight/fight_player_%s_disc.png" % nome, FW, FH)

func prancha_choque() -> void:
	var box := [
		["BOXE parado x parado", "spar_box_idle", "spar_partner_box_idle"],
		["clique: EMPURRA x ele recua", "spar_box_push", "spar_partner_box_recoil"],
		["ele empurra (base) x voce recua", "spar_box_recoil", "spar_partner_box_push"],
		["AVISO rajada (ombro recua) x guarda", "spar_box_guard", "spar_partner_box_warn"],
		["RAJADA x GUARDA fechada", "spar_box_guard", "spar_partner_box_burst"],
		["PAUSA (guarda baixa) x CONTRAGOLPE x2", "spar_box_counter", "spar_partner_box_pause"],
		["FINTA (aviso que vira) x parado", "spar_box_idle", "spar_partner_box_feint"],
	]
	var jj := [
		["JIU-JITSU pegar (soltar = ao contrario)", "spar_jj_take", "spar_partner_jj_take"],
		["pegada parada x pegada", "spar_jj_grip", "spar_partner_jj_grip"],
		["SEGURA = puxa x ele segura", "spar_jj_pull", "spar_partner_jj_grip"],
		["solto (folego) x ele puxa", "spar_jj_release", "spar_partner_jj_pull"],
		["AVISO puxada forte x pegada", "spar_jj_grip", "spar_partner_jj_warn"],
		["PUXADA FORTE x voce SOLTOU (certo)", "spar_jj_release", "spar_partner_jj_yank"],
		["PUXADA FORTE x voce segurou (puxado)", "spar_jj_yanked", "spar_partner_jj_yank"],
		["PAUSA x voce puxa x2", "spar_jj_pull", "spar_partner_jj_pause"],
		["FINTA x pegada", "spar_jj_grip", "spar_partner_jj_feint"],
	]
	var rows := []
	for r in box + jj:
		rows.append(linha_choque(r[0], disc(r[1]), folhas[r[2]]))
	var im := empilha(rows)
	im.save_png(PR + "fase7a2_poses_choque_x1.png")
	escala(im, 2).save_png(PR + "fase7a2_poses_choque_x2.png")
	# zoom 3x de um quadro de cada (encaixe das pegadas e da rajada)
	var zrows := []
	for r in [["contato do empurrao", "spar_box_push", 2, "spar_partner_box_recoil", 1], ["rajada x guarda", "spar_box_guard", 0, "spar_partner_box_burst", 2],
			["pegada (gola + manga)", "spar_jj_grip", 0, "spar_partner_jj_grip", 0], ["puxada forte", "spar_jj_yanked", 2, "spar_partner_jj_yank", 3]]:
		zrows.append(linha_choque(r[0], [disc(r[1])[r[2]]], [folhas[r[3]][r[4]]]))
	var z := Image.create_empty(120 * 4 + 6, 105, false, Image.FORMAT_RGBA8)
	z.fill(L.col("ink"))
	for i in zrows.size():
		blit(z, zrows[i], i * 122, 0)
	escala(z, 3).save_png(PR + "fase7a2_poses_choque_zoom_x3.png")

func prancha_panfleto() -> void:
	var rows := []
	var cw := 52
	# discípulo + Osmar
	var fl := []
	for nm in ["flyer_idle", "flyer_give", "flyer_miss"]:
		fl.append([nm, quadros(J + "characters/fighter_%s_disc.png" % nm, 48, 72)])
	var osm := quadros(ROOT + "assets/sprites/characters/coach_idle.png", 48, 72)
	var row0 := Image.create_empty(cw * 20, 90, false, Image.FORMAT_RGBA8)
	row0.fill(L.col("ink"))
	texto(row0, "DISCIPULO: PARADO / ENTREGA (ACEITOU) / NAO, VALEU     OSMAR (folha de hoje, sem animacao nova)", 1, 1)
	var x := 0
	for f in fl:
		for q in f[1]:
			var cel := fundo_noite(cw, 80, 74)
			blit(cel, q, 26 - 22, 74 - 67)
			blit(row0, cel, x, 10)
			x += cw
		x += 4
	for q in osm:
		var cel := fundo_noite(cw, 80, 74)
		blit(cel, q, 26 - 22, 74 - 67)
		blit(row0, cel, x, 10)
		x += cw
	rows.append(row0)
	for t in TIPOS:
		for nm in ["walk", DICA[t], "tell", "false", "refuse", "flyer"]:
			var id := "ped_%s_%s" % [t, nm]
			var fr: Array = folhas[id]
			var r := Image.create_empty(cw * 8, 90, false, Image.FORMAT_RGBA8)
			r.fill(L.col("ink"))
			var rot: String = {"walk": "ANDA", "tell": "SINAL (interessado)", "false": "SINAL FALSO", "refuse": "NAO, VALEU", "flyer": "ACEITOU (com o panfleto)"}.get(nm, "SEM INTERESSE")
			texto(r, NOMES_TIPO[t] + " - " + rot, 1, 1)
			for i in fr.size():
				var cel := fundo_noite(cw, 80, 74)
				blit(cel, fr[i], 26 - 24, 74 - 71)
				blit(r, cel, i * cw, 10)
			rows.append(r)
	var im := empilha(rows)
	im.save_png(PR + "fase7a2_poses_panfletagem_x1.png")
	escala(im, 2).save_png(PR + "fase7a2_poses_panfletagem_x2.png")
	# cena: rua com o discípulo no meio e os 4 passantes em momentos diferentes (1x e 3x)
	var cena := fundo_noite(320, 96, 88)
	blit(cena, fl[1][1][3], 150 - 22, 88 - 67 - 4)
	blit(cena, folhas["ped_moca_phone"][2], 40 - 24, 88 - 71)
	blit(cena, folhas["ped_senhora_tell"][4], 105 - 24, 88 - 71 + 2)
	var tr: Image = (folhas["ped_trabalhador_hurry"][5] as Image).duplicate()
	tr.flip_x()
	blit(cena, tr, 215 - 23, 88 - 71)
	var es: Image = (folhas["ped_estudante_pockets"][1] as Image).duplicate()
	es.flip_x()
	blit(cena, es, 270 - 23, 88 - 71)
	blit(cena, osm[0], 300 - 22, 88 - 67 - 2)
	cena.save_png(PR + "fase7a2_poses_panfletagem_tira_x1.png")
	escala(cena, 3).save_png(PR + "fase7a2_poses_panfletagem_tira_x3.png")
	# tela inteira no cenário real (minigame_layout.flyers: pés dos pedestres y 300, lutador 70,324, Osmar 604,326)
	var fb := load_abs(ROOT + "assets/sprites/minigame/flyers_bg.png")
	var pe := [["ped_estudante_pockets", 3, 170, false], ["ped_senhora_tell", 4, 262, false], ["ped_moca_phone", 5, 360, true],
		["ped_trabalhador_hurry", 2, 455, true], ["ped_estudante_flyer", 1, 540, false]]
	for e in pe:
		var pim: Image = (folhas[e[0]][e[1]] as Image).duplicate()
		var pxv := 24
		if e[3]:
			pim.flip_x()
			pxv = 23
		blit(fb, pim, int(e[2]) - pxv, 300 - 71)
	blit(fb, osm[0], 604 - 22, 326 - 67)
	blit(fb, fl[1][1][3], 70 - 22, 324 - 67)
	fb.save_png(PR + "fase7a2_poses_panfletagem_tela_x1.png")
	escala(fb, 2).save_png(PR + "fase7a2_poses_panfletagem_tela_x2.png")
	# Choque inteiro no cenário real (Osmar na porta, 150,262)
	var sb := load_abs(ROOT + "assets/sprites/minigame/spar_bg.png")
	blit(sb, osm[0], 150 - 22, 262 - 67)
	var pa: Image = folhas["spar_partner_box_warn"][2]
	blit(sb, disc("spar_box_guard")[0], POS_J.x - 56, POS_J.y - 98)
	blit(sb, pa, POS_O.x - 56, POS_O.y - 98)
	sb.save_png(PR + "fase7a2_poses_choque_tela_x1.png")
	escala(sb, 2).save_png(PR + "fase7a2_poses_choque_tela_x2.png")

# ================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	J = args[0].trim_suffix("/") + "/"
	OUT = args[1].trim_suffix("/") + "/"
	PR = args[2].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.make_dir_recursive_absolute(PR)
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	D = JSON.parse_string(FileAccess.get_file_as_string(base + "/golpes_7a2.json"))
	# ---- parceiro: o que ele divide com o discípulo + o que é só dele
	var box_comum := {"idle": "spar_box_idle", "push": "spar_box_push", "recoil": "spar_box_recoil"}
	var jj_comum := {"take": "spar_jj_take", "grip": "spar_jj_grip", "pull": "spar_jj_pull", "yanked": "spar_jj_yanked"}
	for arte in ["box", "jj"]:
		var comum: Dictionary = box_comum if arte == "box" else jj_comum
		var lista := {}
		for nm in comum:
			var src: String = comum[nm]
			lista[nm] = D.moves[src] if D.moves.has(src) else D.reactions[src]
		for nm in D.parceiro:
			if (nm as String).begins_with(arte + "_"):
				lista[(nm as String).substr(arte.length() + 1)] = D.parceiro[nm]
		for nm in lista:
			var g: Dictionary = lista[nm]
			var id := "spar_partner_%s_%s" % [arte, nm]
			var extra := {"action": nm}
			if nm == "push":
				var fq: Dictionary = expandir(g)[int(g.hit_frame)]
				extra["hit_frame"] = int(g.hit_frame)
				extra["hit_point"] = [-float(fq.hf[0]), float(fq.hf[1])]
			grava(id, gera_parceiro(arte, nm, g), Vector2i(FW, FH), [56, 98], float(g.fps), bool(g.get("loop", false)), "esquerda",
				str(g.get("_ideia", "")), extra)
	# ---- passantes
	for t in TIPOS:
		for nm in ["walk", DICA[t], "tell", "false", "refuse", "flyer"]:
			var g: Dictionary = D.pedestres[nm]
			var extra := {}
			if nm == "tell":
				extra["tell_loop"] = [3, 5]
			grava("ped_%s_%s" % [t, nm], gera_pedestre(t, nm, g), Vector2i(PW, PH), [24, 71], float(g.fps), bool(g.get("loop", false)),
				"direita", str(g.get("_ideia", "")), extra)
	prancha_choque()
	prancha_panfleto()
	var f := FileAccess.open(OUT + "manifest_7a2.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(entradas, "\t"))
	f.close()
	var r := FileAccess.open(OUT + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		r.store_line(l)
	r.store_line("---- conferência")
	for l in report:
		r.store_line(l)
	r.close()
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	for l in report:
		print(l)
	print("ok: %d folhas" % entradas.size())
	quit()
