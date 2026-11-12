extends SceneTree
## Gera TODAS as folhas do lutador do jogador no padrão novo (personagem_lib.gd), garagem + luta,
## com as 4 luvas (velha, _glove_l1, _glove_l2, _glove_l3) e o retrato 32x32.
## Rodar headless a partir de uma pasta temporária com um project.godot vazio (nunca no projeto):
##   godot --headless --path <pasta_tmp> --script E:/Fightclicker/tools/art/make_sprites_jogador.gd -- <saida> <antigos>
##   <saida>   = pasta onde gravar characters/*.png, fight/*.png e relatorio.txt
##   <antigos> = pasta com as folhas antigas (backup), usada só na folha de contato antes/depois
## Lê (só leitura): assets/sprites/manifest.json (quadros, fps, pivô, hit_point e MÃOS por quadro).
## Escreve: <saida>/... e docs/arte/mockups/jogador_completo_x3.png.
## O manifest NÃO é alterado: as mãos de cada quadro saem dele e viram alvo do IK.

var ROOT := OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else "E:/Fightclicker/"
var MANIFEST := ROOT + "assets/sprites/manifest.json"
var MOCK := ROOT + "docs/arte/mockups/jogador_completo_x3.png"
const FW := 112
const FH := 104

const GLOVES := {
	"": {"name": "Luva velha", "style": "old", "ramp": ["r0", "r1", "r2"]},
	"_glove_l1": {"name": "Luva de lona", "style": "lona", "ramp": ["br3", "cream", "white"]},
	"_glove_l2": {"name": "Luva de couro", "style": "couro", "ramp": ["r0", "br1", "br2"]},
	"_glove_l3": {"name": "Luva de marca", "style": "marca", "ramp": ["d1", "d2", "g0"]},
}
const FIGHT_ACTIONS := ["idle", "jab", "heavy", "hit", "dodge", "block", "tired", "victory", "ko"]
const GARAGE := ["fighter_idle", "fighter_punch", "fighter_rope", "fighter_run"]

var L
var P
var M: Dictionary
var out_dir := ""
var old_dir := ""
var report: Array = []

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================ poses de LUTA (perfil, virado à direita)
## Só corpo/pés/rosto: as mãos (hf/hb) entram do manifest.
func fpose(o := {}) -> Dictionary:
	var p := {"hip": V(0, -37), "top": V(2, -61), "toef": V(15, -1), "toeb": V(-3, -1)}
	for k in o:
		p[k] = o[k]
	return p

func fight_poses(action: String) -> Array:
	match action:
		"idle":   # respiração: ombros/cabeça 1 px, joelhos acompanham
			return [fpose({"head": V(5, -71)}),
				fpose({"top": V(2, -62), "head": V(5, -72)}),
				fpose({"hip": V(0, -36), "top": V(2, -60), "head": V(5, -70)}),
				fpose({"hip": V(0, -36), "top": V(2, -61), "head": V(5, -71)})]
		"jab":    # 0 antecipa, 1 CONTATO (tronco gira, calcanhar de trás sobe), 2 recolhe (sem cotovelo em V), 3 volta
			return [fpose({"hip": V(0, -36), "top": V(1, -61), "head": V(4, -71), "sf": V(3, -58), "sb": V(-1, -59), "gkf": "up"}),
				fpose({"hip": V(1, -37), "top": V(5, -61), "head": V(7, -70), "sf": V(6.5, -60), "sb": V(2, -59), "shoeb": "ball", "tw": 1.2, "gkf": "side"}),
				fpose({"hip": V(1, -37), "top": V(3, -61), "head": V(5, -71), "sf": V(4, -58.5), "sb": V(1, -59), "shoeb": "ball", "tw": 0.4,
					"pf": V(-0.6, 1.0), "gkf": "side"}),
				fpose({"top": V(3, -61), "head": V(5, -71), "sf": V(5, -58), "sb": V(0, -59)})]
		"heavy":  # direto de trás com o corpo: 0 carrega, 1 gira, 2 CONTATO, 3 segura, 4 volta
			return [fpose({"hip": V(-1, -36), "top": V(-2, -60), "head": V(1, -70)}),
				fpose({"hip": V(1, -37), "top": V(4, -61), "head": V(7, -71), "tw": 1.0, "shoeb": "ball"}),
				fpose({"hip": V(3, -37), "top": V(8, -60), "head": V(11, -70), "tw": 2.0, "shoeb": "ball", "sb": V(12, -59), "sf": V(7, -57), "gkb": "side"}),
				fpose({"hip": V(3, -37), "top": V(7, -60), "head": V(10, -70), "tw": 1.6, "shoeb": "ball", "sb": V(10, -59), "sf": V(6, -57), "gkb": "side"}),
				fpose({"hip": V(1, -37), "top": V(3, -61), "head": V(6, -71), "tw": 0.4})]
		"hit":    # 0 cabeça vai para trás (dor), 1 recua, 2 recupera
			return [fpose({"hip": V(-1, -37), "top": V(-3, -60), "head": V(-2, -69), "face": "pain"}),
				fpose({"hip": V(-2, -36), "top": V(-3, -60), "head": V(0, -70), "face": "pain"}),
				fpose({"hip": V(0, -37), "top": V(1, -61), "head": V(4, -71)})]
		"dodge":  # para trás e para baixo; pés no lugar, joelhos dobram
			return [fpose({"hip": V(-1, -36), "top": V(-3, -59)}),
				fpose({"hip": V(-3, -33), "top": V(-8, -55)}),
				fpose({"hip": V(-3, -34), "top": V(-7, -56)}),
				fpose({"hip": V(-1, -36), "top": V(0, -60)})]
		"block":  # guarda fechada na frente do rosto; 1 = empurrado 2 px
			return [fpose({"head": V(5, -70), "far_glove_front": true}),
				fpose({"hip": V(-2, -37), "top": V(0, -61), "head": V(3, -70), "far_glove_front": true}),
				fpose({"hip": V(-1, -37), "top": V(1, -61), "head": V(4, -70), "far_glove_front": true})]
		"tired":  # guarda baixa, corpo curvado, boca aberta, respiração funda
			return [fpose({"hip": V(0, -36), "top": V(3, -59), "head": V(7, -68), "face": "tired"}),
				fpose({"hip": V(0, -35), "top": V(3, -58), "head": V(7, -67), "face": "tired"}),
				fpose({"hip": V(0, -35), "top": V(3, -58), "head": V(7, -66), "face": "tired"}),
				fpose({"hip": V(0, -36), "top": V(3, -59), "head": V(7, -67), "face": "tired"})]
		"victory":  # braços para cima (ombros sobem junto), pulinho na ponta dos pés
			var up := {"top": V(1, -61), "head": V(7, -72), "sf": V(5, -59), "sb": V(0, -61), "face": "joy", "pf": V(-1, 0.1), "pb": V(-1, 0.1)}
			var f1 := up.duplicate()
			f1.merge({"hip": V(0, -39), "top": V(1, -63), "head": V(7, -74), "sf": V(5, -61), "sb": V(0, -63), "shoef": "ball", "shoeb": "ball"}, true)
			var f3 := up.duplicate()
			f3.merge({"head": V(7, -71)}, true)
			return [fpose(up), fpose(f1), fpose(up), fpose(f3)]
		"ko":     # 0 cambaleia, 1 joelhos cedem, 2 cai de costas (cabeça e luvas giram com o corpo), 3 bate, 4 assenta
			var dn := V(-0.64, -0.77)
			return [fpose({"hip": V(-1, -36), "top": V(-2, -60), "face": "ko", "toef": V(14, -1), "pf": V(-1, 0.3), "pb": V(-1, 0.3)}),
				fpose({"hip": V(-2, -28), "top": V(-3, -52), "face": "ko", "shoeb": "ball", "kf": V(1, 0), "kb": V(1, 0.1), "pf": V(-1, 0.3), "pb": V(-1, 0.3)}),
				fpose({"hip": V(-8, -17), "top": V(-8, -17) + dn * 24.0, "face": "ko", "hrot_auto": true,
					"toef": V(17, -1), "toeb": V(8, -1), "shoeb": "ball", "kf": V(0.4, -1), "kb": V(0.4, -1), "pf": V(0, -1), "pb": V(0, -1)}),
				fpose({"hip": V(0, -7), "top": V(-24, -7), "head": V(-34, -8), "hrot": -90.0, "face": "ko",
					"toef": V(30, -1), "toeb": V(36, -1), "kf": V(0, -1), "kb": V(0, -1), "pf": V(0, -1), "pb": V(0, -1)}),
				fpose({"hip": V(0, -6), "top": V(-24, -6), "head": V(-34, -7), "hrot": -90.0, "face": "ko",
					"toef": V(32, -1), "toeb": V(37, -12), "shoeb": "up", "kf": V(0, -1), "kb": V(0, -1), "pf": V(0, -1), "pb": V(0, -1)})]
	return []

# ================================================================ poses da GARAGEM (3/4, virado à direita)
func gpose(o := {}) -> Dictionary:
	var p := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47),
		"hl": V(-8, -50), "hr": V(10, -51), "el": V(-9, -40), "er": V(10, -40), "toel": V(-1, 0), "toer": V(10, 0)}
	for k in o:
		p[k] = o[k]
	return p

## Tira chaves da pose (ex.: "er" para o IK achar o cotovelo com o comprimento do braço constante).
func _sem(p: Dictionary, chaves: Array) -> Dictionary:
	for k in chaves:
		p.erase(k)
	return p

func garage_poses(id: String) -> Array:
	match id:
		"fighter_idle":   # luvas na altura do queixo (boca livre), joelhos participam da respiração
			var out := []
			var dys := [0, 0, 1, 1]
			var gd := [0, 1, 1, 0]
			for i in 4:
				var d: int = dys[i]
				var g: int = gd[i]
				out.append(gpose({"hip": V(0, -31 + d), "top": V(1, -50 + d), "head": V(1, -57 + d), "sl": V(-7, -47 + d), "sr": V(8, -47 + d),
					"hl": V(-8, -50 + g), "hr": V(10, -51 + g), "el": V(-9, -40 + d), "er": V(10, -40 + d)}))
			return out
		"fighter_punch":  # jab da mão da frente. 0 guarda, 1 antecipa, 2 CONTATO no saco (hit_point), 3 volta. A sala toca 1-2-3.
			# Fase 5.1: o corpo inteiro participa. 1 = peso no pé de trás, ombro da frente recolhe, tronco gira para trás;
			# 2 = quadril e tronco avançam 3 px, queixo atrás do ombro, calcanhar de trás sobe (ponta fixa), braço em IK com
			# encurtamento de 3/4 (fs) em vez de cotovelo fixo (antes: braço de cima com 2 px); 3 = recolhe passando 1 px da guarda.
			return [gpose(),
				gpose({"hip": V(-1, -30), "top": V(-1, -49), "head": V(-1, -56), "sl": V(-9, -46), "sr": V(6, -46),
					"hl": V(-9, -49), "hr": V(7, -48), "el": V(-10, -39), "er": V(8, -39), "tw": -0.5}),
				_sem(gpose({"hip": V(2, -30), "top": V(4, -49), "head": V(5, -55), "sl": V(-4, -47), "sr": V(11, -48), "face": "effort",
					"hl": V(-5, -49), "hr": V(20, -50), "el": V(-7, -39.5), "fs": 0.56, "pr": V(0.2, 1), "shoel": "34ball", "tw": 1.2,
					"gkr": "side", "kl": V(1, 0), "kr": V(1, 0)}), ["er"]),
				gpose({"hip": V(0, -30), "top": V(1, -49), "head": V(1, -56), "sr": V(9, -47), "hr": V(13, -50), "er": V(11, -42), "gkr": "diag",
					"hl": V(-8, -49), "el": V(-9, -39)})]
		"fighter_rope":   # mãos = pontas da corda (rope_lN_swing); 0 corda em cima, 1 agacha, 2 pés sobem 3 px, 3 aterrissa
			var base := {"sl": V(-8, -46), "sr": V(8, -46), "toel": V(-2, 0), "toer": V(7, 0), "gkl": "", "gkr": "",
				"pl": V(-1, 0.4), "pr": V(1, 0.4), "kl": V(0.4, 0), "kr": V(0.6, 0)}
			var f := []
			var data := [
				{"hl": V(-13, -27), "hr": V(12, -27)},
				{"hip": V(0, -28), "top": V(1, -47), "head": V(1, -54), "sl": V(-8, -43), "sr": V(8, -43), "hl": V(-11, -23), "hr": V(12, -23)},
				{"toel": V(-2, -3), "toer": V(7, -3), "shoel": "34ball", "shoer": "34ball", "hl": V(-11, -26), "hr": V(10, -26)},
				{"toel": V(-2, -1), "toer": V(7, -1), "hl": V(-12, -26), "hr": V(11, -27)},
			]
			for dd in data:
				var p := base.duplicate()
				p.merge(dd, true)
				var g := gpose(p)
				g.erase("el")
				g.erase("er")
				f.append(g)
			return f
		"fighter_run":    # corrida de boxeador na esteira (espelhada no fim). Quadro 0 também é o "parado em cima da esteira".
			# Fase 5.1: ciclo de 4 poses de verdade. 0 = pé direito CHEGA na frente (corpo baixo, perna de trás empurrando na ponta),
			# 1 = PASSAGEM (corpo 2 px mais alto, joelho de trás sobe à frente), 2 e 3 = o mesmo com a outra perna. Tronco inclinado
			# 3 px à frente; os braços bombeiam CONTRA as pernas (antes ficavam parados na guarda, tampando a boca); luvas na
			# altura do peito, rosto livre. O pé de apoio recua 5 px por quadro, no sentido da lona.
			var rb := {"gkl": "", "gkr": "", "kl": V(1, -0.2), "kr": V(1, -0.2)}
			var lo := {"hip": V(1, -29.5), "top": V(4, -48), "head": V(5, -55), "sl": V(-4, -45.5), "sr": V(10, -45)}
			var hi := {"hip": V(1, -31), "top": V(4, -50), "head": V(5, -57), "sl": V(-4, -47.5), "sr": V(10, -47)}
			var fr := [
				[lo, {"toer": V(11, 0), "toel": V(-6, -2), "shoel": "34ball", "hl": V(4, -44), "el": V(-1.5, -38.5), "hr": V(11, -41), "er": V(5.5, -38)}],
				[hi, {"toer": V(6, 0), "toel": V(7, -8), "shoel": "34ball", "kl": V(1, -0.3), "hl": V(1, -43), "el": V(-5, -38.5), "hr": V(13, -43), "er": V(9, -38.5)}],
				[lo, {"toel": V(9, 0), "toer": V(-2, -2), "shoer": "34ball", "hl": V(-2, -40), "el": V(-8, -38), "hr": V(15, -45), "er": V(11, -38.5)}],
				[hi, {"toel": V(4, 0), "toer": V(11, -8), "shoer": "34ball", "kr": V(1, -0.3), "hl": V(2, -43), "el": V(-4, -38.5), "hr": V(12, -43), "er": V(8.5, -38)}],
			]
			var f := []
			for dd in fr:
				var p := rb.duplicate()
				p.merge(dd[0], true)
				p.merge(dd[1], true)
				f.append(gpose(p))
			return f
	return []

# ================================================================ geração
func spr(id: String) -> Dictionary:
	return M.sprites[id]

func v2(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))

func make_build(suffix: String) -> Dictionary:
	var g: Dictionary = GLOVES[suffix]
	return P.build({"glove": g.style, "glove_ramp": g.ramp})

func gen_fight(b: Dictionary, action: String, suffix: String) -> Array:
	var id := "fight_player_" + action + suffix
	var e := spr(id)
	var hands: Array = e.hands
	var poses := fight_poses(action)
	var piv := v2(e.pivot)
	var fs := Vector2i(int(e.frame_size[0]), int(e.frame_size[1]))
	if poses.size() != int(e.frames) or hands.size() != int(e.frames):
		report.append("DIVERGÊNCIA %s: %d poses, %d mãos, manifest %d quadros" % [id, poses.size(), hands.size(), int(e.frames)])
	var frames := []
	for i in poses.size():
		var p: Dictionary = poses[i].duplicate()
		p["hf"] = v2(hands[i].hand_front)
		p["hb"] = v2(hands[i].hand_back)
		var im: Image = P.fight_frame(b, p, "%s[%d]" % [id, i], fs, piv)
		# conferência: o pixel do ponto da mão é luva?
		var hfp: Vector2 = piv + p.hf
		var idf: int = P.ids[int(hfp.y) * fs.x + int(hfp.x)]
		if idf != P.NEAR_GLOVE:
			report.append("AVISO %s[%d]: mão da frente %s não cai na luva (id %d)" % [id, i, str(p.hf), idf])
		frames.append(im)
	if e.has("hit_point"):
		var hf: int = int(e.hit_frame)
		var hp := v2(e.hit_point)
		var hv := v2(hands[hf].hand_front)
		var hb := v2(hands[hf].hand_back)
		if hp.distance_to(hv) > 0.5 and hp.distance_to(hb) > 0.5:
			report.append("AVISO %s: hit_point %s não coincide com nenhuma mão do quadro %d" % [id, str(hp), hf])
	return frames

func gen_garage(b: Dictionary, sid: String) -> Array:
	var frames := []
	var i := 0
	for p in garage_poses(sid):
		var im: Image = P.garage_frame(b, p, "%s[%d]" % [sid, i])
		if sid == "fighter_run":
			im.flip_x()
		frames.append(im)
		i += 1
	return frames

func save_sheet(rel: String, id: String, frames: Array) -> void:
	var e := spr(id)
	var s: Image = P.strip(frames)
	var want := Vector2i(int(e.frame_size[0]) * int(e.frames), int(e.frame_size[1]))
	if s.get_size() != want or frames.size() != int(e.frames):
		report.append("DIVERGÊNCIA %s: folha %s, manifest pede %s (%d quadros)" % [id, str(s.get_size()), str(want), int(e.frames)])
	s.save_png(out_dir + rel)

func make_portrait(b: Dictionary) -> Image:
	var p := fpose({"head": V(5, -71), "hf": V(16, -55), "hb": V(12, -53)})
	var fr: Image = P.fight_frame(b, p, "retrato")
	var hc := V(56, 98) + V(5, -71)
	var crop: Image = fr.get_region(Rect2i(int(hc.x) - 15, int(hc.y) - 13, 32, 32))
	var bg: Image = L.blank(32, 32)
	L.R(bg, 0, 0, 32, 32, "d1")
	L.dither(bg, 0, 18, 32, 6, "b0")
	L.R(bg, 0, 24, 32, 8, "b0")
	L.dither(bg, 0, 28, 32, 4, "b1", 1)
	bg.blend_rect(crop, Rect2i(0, 0, 32, 32), Vector2i.ZERO)
	return bg

# ================================================================ folha de contato antes/depois
func checker(dst: Image, x: int, y: int, w: int, h: int, cell: int) -> void:
	for yy in range(0, h, cell):
		for xx in range(0, w, cell):
			var c = "g1" if ((xx / cell + yy / cell) % 2 == 0) else "g0"
			L.R(dst, x + xx, y + yy, mini(cell, w - xx), mini(cell, h - yy), c)

func contact_sheet(rows: Array, glove_rows: Array) -> void:
	# rows: [titulo, nota, antigos(Array), novos(Array), recorte Rect2i]
	var S := 3
	var gap := 10
	var W := 0
	var H := 70
	for r in rows:
		var cr: Rect2i = r[4]
		W = maxi(W, 120 + (r[3] as Array).size() * (cr.size.x * S + gap) + 30 + (r[3] as Array).size() * (cr.size.x + 3))
		H += 26 + 2 * (cr.size.y * S + 8) + 14
	H += 40
	for gr in glove_rows:
		var cr: Rect2i = gr[2]
		H += cr.size.y * S + 30
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "LUTADOR DO JOGADOR - TODAS AS ACOES, ANTES x DEPOIS (3x; a direita, 1x)", 14, 12, "y1", 2, "ink")
	L.text(out, "Gerado por tools/art/make_sprites_jogador.gd + personagem_lib.gd. Mesmos quadros, fps, pivo, hit_frame/hit_point e maos do manifest.", 14, 38, "g3", 1, "ink")
	var y := 58
	for r in rows:
		var cr: Rect2i = r[4]
		L.text(out, r[0], 14, y, "cream", 2, "ink")
		L.text(out, r[1], 14 + L.text_w(r[0], 2) + 10, y + 4, "g2", 1, "ink")
		y += 24
		for row in 2:
			var fr: Array = r[2] if row == 0 else r[3]
			L.text(out, "ANTES" if row == 0 else "DEPOIS", 14, y + cr.size.y * S / 2 - 6, "r3" if row == 0 else "gr3", 2, "ink")
			var x := 120
			for i in fr.size():
				checker(out, x, y, cr.size.x * S, cr.size.y * S, 12)
				var reg: Image = (fr[i] as Image).get_region(cr)
				P.paste(out, P.scaled(reg, S), x, y)
				L.text(out, str(i), x + 3, y + 3, "white", 1, "ink")
				x += cr.size.x * S + gap
			x += 20
			for i in fr.size():
				L.R(out, x, y, cr.size.x, cr.size.y, "g1")
				P.paste(out, (fr[i] as Image).get_region(cr), x, y)
				x += cr.size.x + 3
			y += cr.size.y * S + 8
		y += 14
	L.text(out, "AS 4 LUVAS (velha, lona, couro, marca) - mesmas cores/detalhes da loja e do cursor", 14, y, "y1", 2, "ink")
	y += 30
	for gr in glove_rows:
		var cr: Rect2i = gr[2]
		L.text(out, gr[0], 14, y + 10, "cream", 1, "ink")
		var x := 120
		for im in gr[1]:
			checker(out, x, y, cr.size.x * S, cr.size.y * S, 12)
			P.paste(out, P.scaled((im as Image).get_region(cr), S), x, y)
			x += cr.size.x * S + gap
		y += cr.size.y * S + 30
	out.save_png(MOCK)

# ================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0].trim_suffix("/") + "/"
	old_dir = args[1].trim_suffix("/") + "/"
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	M = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	DirAccess.make_dir_recursive_absolute(out_dir + "fight")
	DirAccess.make_dir_recursive_absolute(out_dir + "characters")
	var newf := {}
	for suffix in GLOVES:
		var b := make_build(suffix)
		for a in FIGHT_ACTIONS:
			var id: String = "fight_player_" + a + suffix
			var fr := gen_fight(b, a, suffix)
			save_sheet("fight/" + id + ".png", id, fr)
			newf[id] = fr
		for sid in GARAGE:
			var id: String = sid + suffix
			var fr := gen_garage(b, sid)
			save_sheet("characters/" + id + ".png", id, fr)
			newf[id] = fr
		if suffix == "":
			make_portrait(b).save_png(out_dir + "fight/portrait_player.png")
	# folha de contato
	var rows := []
	var crop_f := Rect2i(8, 8, 96, 96)
	var crop_g := Rect2i(0, 0, 48, 72)
	for sid in GARAGE:
		var e := spr(sid)
		rows.append([sid, "%d quadros, %s fps" % [int(e.frames), str(e.fps)], P.frames_of(old_dir + "characters/" + sid + ".png", 48), newf[sid], crop_g])
	for a in FIGHT_ACTIONS:
		var id: String = "fight_player_" + a
		var e := spr(id)
		var nt := "%d quadros, %s fps" % [int(e.frames), str(e.fps)]
		if e.has("hit_frame"):
			nt += ", hit_frame %d" % int(e.hit_frame)
		rows.append([id, nt, P.frames_of(old_dir + "fight/" + id + ".png", FW), newf[id], crop_f])
	var glove_rows := []
	for pair in [["fight_player_idle", 0], ["fight_player_jab", 1], ["fight_player_ko", 4], ["fighter_punch", 2], ["fighter_rope", 1]]:
		var ims := []
		for suffix in GLOVES:
			ims.append(newf[pair[0] + suffix][pair[1]])
		glove_rows.append(["%s [%d]" % [pair[0], pair[1]], ims, crop_g if (pair[0] as String).begins_with("fighter_") else crop_f])
	contact_sheet(rows, glove_rows)
	var f := FileAccess.open(out_dir + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		f.store_line(l)
	f.store_line("---- conferência")
	for l in report:
		f.store_line(l)
	f.close()
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	for l in report:
		print(l)
	print("ok: %d folhas" % newf.size())
	quit()
