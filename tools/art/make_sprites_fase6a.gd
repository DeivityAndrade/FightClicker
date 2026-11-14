extends SceneTree
## Fase 6a — Prólogo e voz. Artista de Personagens.
## Gera: (1) o GESTO de assinatura do 1º lutador ("fecho e dois toques", docs/cutscenes/gesto-assinatura.md), garagem e
## luta, completo e curto, com as 5 luvas; (2) o TREINADOR original da garagem (parado, olhar para o lado, falar, apontar);
## (3) gesto_manifest.json com as entradas prontas para assets/sprites/manifest.json; (4) folhas de contato e os quadros
## das cenas na garagem real (para virar GIF com o ffmpeg).
## O corpo, os rostos "bite"/"smile" e a fita do fecho estão em personagem_lib.gd (identidade("primeiro"), strap_tip).
## As folhas de sempre do 1º lutador e as do discípulo padrão saem de make_sprites_jogador.gd + make_golpes_jogador.gd
## (FC_LUTADOR=disc para o discípulo).
## Rodar headless a partir de uma pasta temporária com um project.godot vazio (nunca no projeto):
##   godot --headless --path <pasta_tmp> --script <repo>/tools/art/make_sprites_fase6a.gd -- <saida> <sprites_do_lutador>
##   <saida>              = onde gravar characters/, fight/, gesto_manifest.json, mock/ (contato e seq_*)
##   <sprites_do_lutador> = pasta com characters/ e fight/ do 1º lutador e do discípulo JÁ gerados (para os mockups);
##                          o que faltar vem de assets/sprites.

var ROOT := OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else "E:/Fightclicker/"

const GLOVES := {
	"": {"name": "Luva velha", "style": "old", "ramp": ["r0", "r1", "r2"]},
	"_glove_l1": {"name": "Luva de lona", "style": "lona", "ramp": ["br3", "cream", "white"]},
	"_glove_l2": {"name": "Luva de couro", "style": "couro", "ramp": ["r0", "br1", "br2"]},
	"_glove_l3": {"name": "Luva de marca", "style": "marca", "ramp": ["d1", "d2", "g0"]},
	"_glove_l4": {"name": "Luva de competição", "style": "campeao", "ramp": ["b1", "b2", "b3"]},
}
const FW := 112
const FH := 104
const FPIV := Vector2(56, 98)
const GPIV := Vector2(22, 67)
const BITE_FRAME := 1
const TAP_FRAMES := [5, 7]
const LIGHT_C := Vector2(305, 90)   # lâmpada da garagem (a mesma de make_sprites_elenco.gd)
## Ponto do treinador na garagem (pivô = entre os pés). Encostado no carro velho, virado para o centro.
## Fora da faixa do lutador e do alvo (x 281..362). Ver mock/posicao_treinador_x1.png (saco de lado e caixa da corda).
const TRAINER_POS := Vector2(196, 236)   # decisão do Produtor: encostado no carro, livre do saco de lado, do neighbor_2 e da caixa da corda
const ALT_POS := Vector2(236, 238)       # ponto pedido antes (colide com o saco de lado, neighbor_2 e a caixa da corda)

var L
var P
var M: Dictionary
var out_dir := ""
var spr_dir := ""
var report: Array = []
var entradas := {}
var cache := {}
var tpos := TRAINER_POS   # ponto do treinador no mockup (conferência de posição)
var foco := "saco"

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================ GESTO — luta (perfil, virado à direita)
## 0 guarda · 1 luva da frente sobe à boca (rosto bite, fita presa nos dentes) · 2 puxa (cabeça recua 1 px, cotovelo
## desce 2 px, fita esticada) · 3 solta, luva desce · 4 punho recua 3 px · 5 1º toque · 6 separa 2 px · 7 2º toque.
## Mão da frente = a do jab (hf), a mesma que bate no saco. Pés parados o gesto inteiro.
func fight_gesture() -> Array:
	var base := {"hip": V(0, -37), "top": V(2, -61), "toef": V(15, -1), "toeb": V(-3, -1), "head": V(5, -71)}
	var q := [
		{"hf": V(16, -59), "hb": V(12, -61)},
		{"head": V(6, -70), "face": "bite", "hf": V(18, -70), "hb": V(11, -57), "pf": V(0.3, 1.0), "gkf": "up", "strap": 2},
		{"head": V(5, -70), "face": "bite", "top": V(2, -60), "hf": V(19, -68), "hb": V(11, -57), "pf": V(0.3, 1.0), "gkf": "up", "strap": 3},
		{"hf": V(18, -62), "hb": V(11, -57)},
		{"hf": V(20, -65), "hb": V(15, -52), "far_glove_front": true},
		{"hf": V(17, -59), "hb": V(15, -52), "far_glove_front": true, "tap": true},
		{"hf": V(19, -62), "hb": V(15, -52), "far_glove_front": true},
		{"hf": V(17, -59), "hb": V(15, -52), "far_glove_front": true, "tap": true},
	]
	var out := []
	for d in q:
		var p := base.duplicate()
		p.merge(d, true)
		out.append(p)
	return out

# ================================================================ GESTO — garagem (3/4, virado à direita)
## Mesmos 8 tempos. A mão da DIREITA da tela (a que soca o saco) vai à boca e depois bate na outra, que vem para a
## frente do peito. Cotovelo do braço que morde abre para fora (IK com o comprimento do braço constante).
func garage_gesture() -> Array:
	var base := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47),
		"hl": V(-8, -50), "hr": V(10, -51), "el": V(-9, -40), "er": V(10, -40), "toel": V(-1, 0), "toer": V(10, 0)}
	var q := [
		{},
		{"head": V(2, -56), "face": "bite", "hr": V(12, -57), "er": null, "pr": V(1.0, 0.7), "strap": 2},
		{"head": V(1, -56), "face": "bite", "top": V(1, -49), "hr": V(13, -55), "er": null, "pr": V(1.0, 0.9), "strap": 3},
		{"hr": V(11, -49), "er": null, "pr": V(1.0, 0.8), "gkr": ""},
		{"hl": V(0, -44), "el": null, "pl": V(-1.0, 0.6), "hr": V(10, -53), "er": null, "pr": V(1.0, 0.8), "gkr": "up"},
		{"hl": V(0, -44), "el": null, "pl": V(-1.0, 0.6), "hr": V(5, -49), "er": null, "pr": V(1.0, 0.9), "gkr": "up", "tap": true},
		{"hl": V(0, -44), "el": null, "pl": V(-1.0, 0.6), "hr": V(7, -51), "er": null, "pr": V(1.0, 0.9), "gkr": "up"},
		{"hl": V(0, -44), "el": null, "pl": V(-1.0, 0.6), "hr": V(5, -49), "er": null, "pr": V(1.0, 0.9), "gkr": "up", "tap": true},
	]
	var out := []
	for d in q:
		var p := base.duplicate()
		for k in d:
			if d[k] == null:
				p.erase(k)
			else:
				p[k] = d[k]
		out.append(p)
	return out

func with_strap(p: Dictionary, b: Dictionary, view: String) -> Dictionary:
	var n: int = p.get("strap", 0)
	if n <= 0:
		return p
	var mo: Vector2 = P.mouth_offset(b, view)
	p["end"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hd: Vector2 = ctx.hd
		var hand: Vector2 = ctx.hf if view == "side" else ctx.hr
		# dente da frente: 2 px à frente do canto da boca (rosto bite); punho da luva "up": 4 px abaixo e 4 à esquerda
		var tooth := (hd + mo + V(2, 0)).round()
		var cuff := (hand + V(-4, 4)).round()
		lib.strap_tip(b, tooth, cuff, n)
	return p

func make_build(suffix: String) -> Dictionary:
	var g: Dictionary = GLOVES[suffix]
	var o: Dictionary = P.identidade("primeiro")
	o.merge({"glove": g.style, "glove_ramp": g.ramp}, true)
	return P.build(o)

func gen_gesture(b: Dictionary, suffix: String) -> Dictionary:
	var ff := []
	var fh := []
	var i := 0
	for p0 in fight_gesture():
		var p: Dictionary = with_strap((p0 as Dictionary).duplicate(), b, "side")
		ff.append(P.fight_frame(b, p, "fight_player_gesture%s[%d]" % [suffix, i], Vector2i(FW, FH), FPIV))
		var hfp: Vector2 = FPIV + p.hf
		if P.ids[int(hfp.y) * FW + int(hfp.x)] != P.NEAR_GLOVE:
			report.append("AVISO fight_player_gesture%s[%d]: mão da frente fora da luva" % [suffix, i])
		fh.append({"hand_front": [p.hf.x, p.hf.y], "hand_back": [p.hb.x, p.hb.y]})
		i += 1
	var gf := []
	var gh := []
	i = 0
	for p0 in garage_gesture():
		var p: Dictionary = with_strap((p0 as Dictionary).duplicate(), b, "34")
		gf.append(P.garage_frame(b, p, "fighter_gesture%s[%d]" % [suffix, i]))
		gh.append({"hand_front": [p.hr.x, p.hr.y], "hand_back": [p.hl.x, p.hl.y]})
		i += 1
	return {"fight": ff, "fight_hands": fh, "garage": gf, "garage_hands": gh}

func tap_point(h: Dictionary) -> Array:
	# contato = meio do caminho entre as duas luvas
	return [roundi((float(h.hand_front[0]) + float(h.hand_back[0])) * 0.5), roundi((float(h.hand_front[1]) + float(h.hand_back[1])) * 0.5)]

func save_gesture(g: Dictionary, suffix: String) -> void:
	var luva: String = GLOVES[suffix].name
	for view in ["garage", "fight"]:
		var frames: Array = g[view]
		var hands: Array = g[view + "_hands"]
		var sub := "characters/" if view == "garage" else "fight/"
		var nome := "fighter_gesture" if view == "garage" else "fight_player_gesture"
		var fs := [48, 72] if view == "garage" else [FW, FH]
		var piv := [22, 67] if view == "garage" else [56, 98]
		for curta in [false, true]:
			var fr: Array = frames.slice(4) if curta else frames
			var hd: Array = hands.slice(4) if curta else hands
			var id := nome + ("_short" if curta else "") + suffix
			P.strip(fr).save_png(out_dir + sub + id + ".png")
			var taps: Array = [1, 3] if curta else TAP_FRAMES
			var e := {
				"file": "res://assets/sprites/" + sub + id + ".png",
				"frame_size": fs, "frames": fr.size(), "fps": 9, "pivot": piv, "loop": false, "facing": "direita",
				"action": "gesture_short" if curta else "gesture",
				"bite_frame": -1 if curta else BITE_FRAME, "tap_frames": taps,
				"tap_points": [tap_point(hd[taps[0]]), tap_point(hd[taps[1]])],
				"hands": hd,
				"who": "primeiro",
				"head_anchor": [1, -65] if view == "garage" else [5, -80],
			}
			if view == "garage":
				e["positions"] = {"foco_saco": [303, 272], "foco_corda": [336, 272]}
			if curta:
				e["frames_note"] = "Gesto CURTO de John Bullet (1º lutador) (só os dois toques, %s): 0 punho recua, 1 1º TOQUE, 2 separa, 3 2º TOQUE. tap_frames = quadros do som tap_glove e da faísca (tap_points, relativos ao pivô). Intervalo entre os toques: 2 quadros a 9 fps = 0,22 s. Depois volta para a guarda (idle). Qualquer clique cancela no mesmo quadro." % luva
			else:
				e["frames_note"] = "Gesto de assinatura de John Bullet (1º lutador), \"fecho e dois toques\" (%s): 0 guarda, 1 luva da frente na boca (MORDE: som strap_rip começa aqui, bite_frame), 2 puxa o fecho (fita esticada), 3 solta e baixa, 4 punho recua, 5 1º TOQUE, 6 separa, 7 2º TOQUE. tap_frames = som tap_glove + faísca em tap_points (relativos ao pivô). 8 quadros a 9 fps = 0,89 s. Só o 1º lutador faz (nunca o discípulo). Qualquer clique cancela no mesmo quadro e volta para a guarda." % luva
			entradas[id] = e

# ================================================================ TREINADOR original
## Velho, um pouco curvado, barriga, careca no alto com coroa de cabelo branco, bigodão branco e sobrancelhas grossas
## brancas. Camisa polo cinza-azulada desbotada, calça marrom com cinto, sapato preto velho, TOALHA no ombro (branca
## com listra azul) — o detalhe dele, que nenhum ajudante tem. Pele mais escura e marcada.
const TRAINER_HEAD_34 := [
	"....SSsss....",
	"..SSsssllls..",
	".SSssssllllS.",
	".SSsssssssss.",
	"HHSsssslllll.",
	"HHSsbbbsslbbb",
	"HHESsesssles.",
	"HEsSssssslll.",
	".HESssssssss.",
	".HSssooooSss.",
	"..SsooooooS..",
	"...SSsssss...",
	".....SSSs....",
]
const TRAINER_FACES_34 := {
	"normal": {},
	"talk_a": {11: "...SSsxxss...", 12: ".....SSSs...."},
	"talk_b": {11: "...SSsxss....", 12: ".....SSSs...."},
}

func trainer_build(look := false) -> Dictionary:
	var head: Array = TRAINER_HEAD_34
	var faces: Dictionary = TRAINER_FACES_34
	if look:
		head = _mirror_rows(head)
		var f2 := {}
		for k in faces:
			var d := {}
			for r in faces[k]:
				d[r] = _mirror_row(faces[k][r], 13)
			f2[k] = d
		faces = f2
	var b: Dictionary = P.build({"head_34": head, "faces_34": faces, "head_anchor_34": Vector2i(6, 6),
		"hair": ["g2", "g3"], "brow": "white", "mustache": "white", "skin": ["sk0", "sk1", "sk2"],
		"top": "tshirt", "shirt": ["st1", "st2", "st3"], "sleeve_t": 0.5, "trim": "white",
		"bottom": "pants", "shorts": ["g0", "g1", "g2"], "band": "d1", "belt": ["d1", "d2", "d2", "g3"],
		"shoes": ["br0", "br0", "br1", "br2", "ink"], "glove": "fist",
		"belly": 3.5, "shoulder": 0.96, "hip_w": 1.05,
		"head_legend_extra": {"o": "white"}})
	return b

func _mirror_row(r: String, w: int) -> String:
	var s := r
	while s.length() < w:
		s += "."
	var o := ""
	for i in range(s.length() - 1, -1, -1):
		o += s[i]
	return o

func _mirror_rows(rows: Array) -> Array:
	var w := 0
	for r in rows:
		w = maxi(w, (r as String).length())
	var out := []
	for r in rows:
		out.append(_mirror_row(r, w))
	return out

## Toalha no ombro direito da tela: dobra por cima do ombro e cai na frente do peito (por cima do tronco, por baixo do
## braço esquerdo). Branca, sombra creme, listra azul perto da ponta.
func towel_hook() -> Callable:
	return func(lib, O: Vector2, ctx: Dictionary) -> void:
		var s: Vector2 = ctx.sr
		var x0 := int(round(s.x)) - 2
		var y0 := int(round(s.y)) - 1
		for yy in range(0, 10):
			for xx in range(0, 3):
				var c := "white" if xx < 2 else "cream"
				if yy == 0 and xx == 2:
					continue
				if yy >= 7 and yy <= 7:
					c = "b2"
				if yy == 9 and xx == 0:
					c = "cream"
				lib.put(x0 + xx - (1 if yy < 2 else 0), y0 + yy, c, 35)

## Dedo indicador esticado (apontar): 3 px de pele saindo do punho na direção do antebraço.
func finger_hook() -> Callable:
	return func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hr: Vector2 = ctx.hr
		var d: Vector2 = (hr - (ctx.elr as Vector2)).normalized()
		for k in range(2, 5):
			var p := (hr + d * float(k) + V(0, -1)).round()
			lib.put(int(p.x), int(p.y), "sk1" if k < 4 else "sk0", 75)

func tpose(o := {}) -> Dictionary:
	# encostado no carro: quadril 1 px à frente, peito 1 px para trás (apoiado), cabeça um pouco à frente (velho)
	var p := {"hip": V(1, -30), "top": V(0, -48), "head": V(1, -55), "sl": V(-6, -45), "sr": V(7, -45),
		"toel": V(-2, 0), "toer": V(9, 0), "kl": V(0.5, 0), "kr": V(0.6, 0), "gkl": "", "gkr": ""}
	for k in o:
		p[k] = o[k]
	return p

## Braços cruzados na barriga: as mãos somem embaixo do braço (sem luva); os antebraços se cruzam.
func crossed(dy: int) -> Dictionary:
	return {"hl": V(4, -39 + dy), "el": V(-7, -37 + dy), "hr": V(-4, -41 + dy), "er": V(8, -37 + dy)}

func shifted(p: Dictionary, dy: int) -> Dictionary:
	for k in ["hip", "top", "head", "sl", "sr"]:
		p[k] = (p[k] as Vector2) + V(0, dy)
	return p

func trainer_poses(kind: String) -> Array:
	var out := []
	var dys := [0, 0, 1, 1]
	match kind:
		"idle", "look":   # braços cruzados, respiração lenta (ombros e cabeça 1 px)
			for i in 4:
				var p := shifted(tpose(crossed(dys[i])), dys[i])
				p["hands_hidden"] = true
				out.append(p)
		"talk":   # um braço cruzado, a outra mão aberta na altura do peito acompanhando a fala; boca abre e fecha
			var hand := [V(13, -44), V(13, -47), V(14, -45), V(13, -46)]
			var faces := ["talk_a", "normal", "talk_b", "talk_a"]
			var hy := [0, -1, 0, 0]
			for i in 4:
				var p := tpose({"hl": V(5, -39), "el": V(-6, -37), "hr": hand[i], "pr": V(0.6, 1.0), "face": faces[i]})
				p["head"] = (p["head"] as Vector2) + V(0, hy[i])
				p["half_hidden"] = true
				out.append(p)
		"point":  # 0 levanta a mão, 1 aponta para a frente (para o centro da sala), 2-3 sacode o dedo falando; outra mão na cintura
			var hand := [V(13, -45), V(19, -49), V(19, -50), V(19, -49)]
			var faces := ["normal", "talk_a", "normal", "talk_b"]
			for i in 4:
				var p := tpose({"hl": V(-8, -31), "el": V(-11, -38), "hr": hand[i], "pr": V(0.2, 1.0), "face": faces[i],
					"head": V(2, -55)})
				if i > 0:
					p["finger"] = true
				out.append(p)
	return out

func gen_trainer(kind: String) -> Array:
	var b := trainer_build(kind == "look")
	var bh := trainer_build(kind == "look")
	bh["glove"] = "none"
	var frames := []
	var i := 0
	for p in trainer_poses(kind):
		var hooks := [towel_hook()]
		if p.get("finger", false):
			hooks.append(finger_hook())
		p["after_torso"] = hooks[0]
		if hooks.size() > 1:
			p["end"] = hooks[1]
		var use: Dictionary = bh if p.get("hands_hidden", false) else b
		if p.get("half_hidden", false):
			# mão esquerda some embaixo do braço; a direita (que fala) é punho/mão aberta
			use = b
			p["hl_hidden"] = true
		var im: Image = P.garage_frame(use, p, "coach_%s[%d]" % [kind, i], Vector2i(48, 72), GPIV)
		var tl := TRAINER_POS - GPIV
		L.light(im, Rect2i(0, 0, im.get_width(), im.get_height()), LIGHT_C - tl, 300.0, 1.1, 3.6, -1, 1, 0.9)
		frames.append(im)
		i += 1
	return frames

func save_trainer() -> Dictionary:
	var notes := {
		"idle": ["parado: braços cruzados, respiração lenta (loop). Estado normal na garagem.", 3, true],
		"look": ["olhar para o lado: a cabeça vira para a parede de trás/porta (loop no mesmo ritmo do idle). Usar por 1-3 s e voltar ao idle.", 3, true],
		"talk": ["falar: um braço cruzado, a outra mão acompanha a fala, boca abre e fecha (loop enquanto o balão escreve).", 6, true],
		"point": ["apontar/gesticular: 0 levanta a mão, 1 aponta para o centro da sala, 2-3 sacode o dedo (tocar 0-3 uma vez e repetir 1-3 enquanto fala). Outra mão na cintura.", 6, false],
	}
	var all := {}
	for k in notes:
		var fr := gen_trainer(k)
		all[k] = fr
		var id: String = "coach_" + str(k)
		P.strip(fr).save_png(out_dir + "characters/" + id + ".png")
		entradas[id] = {
			"file": "res://assets/sprites/characters/" + id + ".png",
			"frame_size": [48, 72], "frames": 4, "fps": notes[k][1], "pivot": [22, 67], "loop": notes[k][2],
			"pos": [TRAINER_POS.x, TRAINER_POS.y], "facing": "direita", "who": "treinador", "head_anchor": [1, -63],
			"note": "Osmar Brandão, o treinador original (Fase 6a), " + notes[k][0] + " Ponto fixo na garagem, encostado no carro velho (decisão do Produtor, 196,236); nunca cobre o alvo nem o lutador. Luz já aplicada para este ponto (para outro ponto, gerar de novo). Sombra: floor_shadow nos pés. head_anchor = ponto logo acima da cabeça, relativo ao pivô (onde o rabicho do balão aponta).",
		}
	return all

# ================================================================ leitura de folhas (mockups)
func spr(id: String) -> Dictionary:
	if entradas.has(id):
		return entradas[id]
	return M.sprites[id]

func folha(id: String) -> Array:
	if cache.has(id):
		return cache[id]
	var e := spr(id)
	var rel: String = (e.file as String).replace("res://assets/sprites/", "")
	var path := out_dir + rel
	if not FileAccess.file_exists(path):
		path = spr_dir + rel
	if not FileAccess.file_exists(path):
		path = ROOT + "assets/sprites/" + rel
	var fr: Array = P.frames_of(path, int(e.frame_size[0]))
	cache[id] = fr
	return fr

func por(dst: Image, id: String, quadro: int, pos: Vector2) -> void:
	var e := spr(id)
	var fr := folha(id)
	P.paste(dst, fr[clampi(quadro, 0, fr.size() - 1)], int(pos.x) - int(e.pivot[0]), int(pos.y) - int(e.pivot[1]))

func pos_de(id: String, chave: String) -> Vector2:
	var e := spr(id)
	if chave == "":
		return Vector2(float(e.pos[0]), float(e.pos[1]))
	return Vector2(float(e.positions[chave][0]), float(e.positions[chave][1]))

func corrente(dst: Image, x: int, y_fim: int) -> void:
	var t: Image = folha("bag_chain_tile")[0]
	var y := 33
	while y < y_fim:
		P.paste(dst, t.get_region(Rect2i(0, 0, 4, mini(6, y_fim - y))), x - 1, y)
		y += 6

## Garagem real: fundo, corda no prego, esteira de lado, saco no centro; equipe opcional; treinador; lutador.
func garagem(lut_id: String, lut_q: int, tr_id: String, tr_q: int, crew := false, bag_q := 0) -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	por(im, "garage_bg", 0, Vector2(128, 18))
	por(im, "lamp", 0, Vector2(300, 32))
	por(im, "rope_l0_idle", 0, pos_de("rope_l0_idle", "prego"))
	por(im, "treadmill_l0_side", 0, pos_de("treadmill_l0_side", "lado_direito"))
	if foco == "corda":
		var ps := pos_de("bag_l0_side", "lado_esquerdo")
		corrente(im, int(ps.x) - 1, int(ps.y))
		por(im, "bag_l0_side", 0, ps)
	var items := []
	if crew:
		for hid in ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2", "coach_1"]:
			items.append([pos_de(hid, "").y, hid, 0, pos_de(hid, "")])
	items.append([tpos.y, tr_id, tr_q, tpos])
	items.sort_custom(func(a, b): return a[0] < b[0])
	var pb := pos_de("bag_l0_idle", "centro")
	if foco == "saco":
		corrente(im, int(pb.x) - 1, int(pb.y))
	var centro_feito := false
	for it in items:
		if it[0] > 272.0 and not centro_feito:
			_centro(im, lut_id, lut_q, bag_q)
			centro_feito = true
		por(im, "floor_shadow", 0, (it[3] as Vector2) + V(0, -1))
		por(im, it[1], it[2], it[3])
	if not centro_feito:
		_centro(im, lut_id, lut_q, bag_q)
	return im

func _centro(im: Image, lut_id: String, lut_q: int, bag_q: int) -> void:
	var pf := pos_de("fighter_idle", "foco_saco")
	if foco == "saco":
		por(im, "bag_l0_idle", bag_q, pos_de("bag_l0_idle", "centro"))
	else:
		pf = pos_de("fighter_idle", "foco_corda")
	por(im, "floor_shadow", 0, pf + V(0, -1))
	por(im, lut_id, lut_q, pf)

func faisca(im: Image, p: Vector2, k: int) -> void:
	# faísca simples do toque (só no mockup; o FX do jogo é do Programador/Diretor de Arte)
	var c := "y2" if k == 0 else "y1"
	var r := 2 + k
	for d in [V(1, 0), V(-1, 0), V(0, 1), V(0, -1)]:
		for s in range(1, r + 1):
			var q: Vector2 = (p + d * s).round()
			if q.x >= 0 and q.y >= 0 and q.x < im.get_width() and q.y < im.get_height():
				im.set_pixel(int(q.x), int(q.y), L.col(c))

# ================================================================ folhas de contato
func xadrez(dst: Image, x: int, y: int, w: int, h: int, cell: int) -> void:
	for yy in range(0, h, cell):
		for xx in range(0, w, cell):
			var c = "g1" if ((xx / cell + yy / cell) % 2 == 0) else "g0"
			L.R(dst, x + xx, y + yy, mini(cell, w - xx), mini(cell, h - yy), c)

## linhas: [titulo, nota, frames(Array), recorte Rect2i, etiquetas(Array)]
func contato(linhas: Array, titulo: String, S: int, path: String) -> void:
	var gap := 6 + S
	var W := 560
	var H := 40
	for r in linhas:
		var cr: Rect2i = r[3]
		var n: int = (r[2] as Array).size()
		W = maxi(W, 16 + n * (cr.size.x * S + gap) + 24 + n * (cr.size.x + 3))
		H += 22 + cr.size.y * S + 14
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, titulo, 10, 8, "y1", 2 if S > 1 else 1, "ink")
	var y := 34
	for r in linhas:
		var cr: Rect2i = r[3]
		L.text(out, r[0], 10, y, "cream", 1, "ink")
		L.text(out, r[1], 14 + L.text_w(r[0], 1), y, "g2", 1, "ink")
		y += 14
		var x := 10
		var fr: Array = r[2]
		for i in fr.size():
			xadrez(out, x, y, cr.size.x * S, cr.size.y * S, 4 * S)
			P.paste(out, P.scaled((fr[i] as Image).get_region(cr), S), x, y)
			var lab: Array = r[4]
			L.text(out, str(lab[i]) if i < lab.size() else str(i), x + 2, y + 2, "white", 1, "ink")
			x += cr.size.x * S + gap
		x += 16
		for i in fr.size():
			L.R(out, x, y, cr.size.x, cr.size.y, "g1")
			P.paste(out, (fr[i] as Image).get_region(cr), x, y)
			x += cr.size.x + 3
		y += cr.size.y * S + 14
	out.save_png(path)

func rostos() -> Array:
	# cabeças soltas (1º lutador nas duas vistas, discípulo e treinador), recortadas dos quadros
	var bp := make_build("")
	var bd: Dictionary = P.build(P.identidade("disc"))
	var out := []
	for face in ["normal", "bite", "smile", "joy", "pain"]:
		P.canvas(20, 20)
		P.pmap(P.HEAD, P.head_rows(bp, "side", face), P.head_legend(bp), V(10, 10), bp.head_anchor_side)
		out.append(P.finish())
	for face in ["normal", "bite", "smile", "effort"]:
		P.canvas(20, 20)
		P.pmap(P.HEAD, P.head_rows(bp, "34", face), P.head_legend(bp), V(10, 10), bp.head_anchor_34)
		out.append(P.finish())
	P.canvas(20, 20)
	P.pmap(P.HEAD, P.head_rows(bd, "side", "normal"), P.head_legend(bd), V(10, 10), bd.head_anchor_side)
	out.append(P.finish())
	P.canvas(20, 20)
	P.pmap(P.HEAD, P.head_rows(bd, "34", "normal"), P.head_legend(bd), V(10, 10), bd.head_anchor_34)
	out.append(P.finish())
	var bt := trainer_build()
	for face in ["normal", "talk_a", "talk_b"]:
		P.canvas(20, 20)
		P.pmap(P.HEAD, P.head_rows(bt, "34", face), P.head_legend(bt), V(10, 10), bt.head_anchor_34)
		out.append(P.finish())
	return out

# ================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0].trim_suffix("/") + "/"
	spr_dir = (args[1].trim_suffix("/") + "/") if args.size() > 1 else ROOT + "assets/sprites/"
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	M = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	for d in ["characters", "fight", "mock"]:
		DirAccess.make_dir_recursive_absolute(out_dir + d)
	var gest := {}
	for suffix in GLOVES:
		var g := gen_gesture(make_build(suffix), suffix)
		save_gesture(g, suffix)
		gest[suffix] = g
	var tr := save_trainer()
	var f := FileAccess.open(out_dir + "gesto_manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(entradas, "\t"))
	f.close()
	# ---- folhas de contato
	var cg := Rect2i(0, 0, 48, 72)
	var cf := Rect2i(20, 14, 72, 88)
	var lab8 := ["0", "1 MORDE", "2 PUXA", "3", "4", "5 TOC", "6", "7 TOC"]
	var linhas := [
		["fighter_gesture (garagem)", "8 quadros a 9 fps; bite_frame 1, tap_frames [5,7]; curta = quadros 4-7", gest[""].garage, cg, lab8],
		["fight_player_gesture (luta)", "8 quadros a 9 fps; mesmos tempos", gest[""].fight, cf, lab8],
	]
	for suffix in GLOVES:
		if suffix == "":
			continue
		linhas.append(["luva %s" % GLOVES[suffix].name, "quadros 1, 2, 5 (garagem e luta)",
			[gest[suffix].garage[1], gest[suffix].garage[2], gest[suffix].garage[5]], cg, ["1", "2", "5"]])
		linhas.append(["", "", [gest[suffix].fight[1], gest[suffix].fight[2], gest[suffix].fight[5]], cf, ["1", "2", "5"]])
	for k in ["idle", "look", "talk", "point"]:
		linhas.append(["coach_" + k, str(entradas["coach_" + k].fps) + " fps", tr[k], cg, []])
	var rs := rostos()
	linhas.append(["rostos", "1o lutador perfil: normal bite smile joy pain | 3/4: normal bite smile effort | discipulo perfil, 3/4 | treinador: normal, fala a, fala b", rs, Rect2i(0, 0, 20, 20), []])
	contato(linhas, "FASE 6A - 1o LUTADOR, GESTO E TREINADOR (3x; a direita, 1x)", 3, out_dir + "mock/contato_x3.png")
	contato(linhas, "FASE 6A (1x)", 1, out_dir + "mock/contato_x1.png")
	# ---- antes x depois e discípulo (folhas do lutador)
	var cmp := []
	for id in ["fighter_idle", "fighter_punch", "fighter_run", "fighter_hook"]:
		var a: Array = P.frames_of(ROOT + "assets/sprites/characters/" + id + ".png", 48)
		var dp: Array = P.frames_of(spr_dir + "characters/" + id + ".png", 48)
		var dd: Array = P.frames_of(spr_dir + "characters/" + id + "_disc.png", 48)
		cmp.append([id + " ANTES", "", a, cg, []])
		cmp.append([id + " 1o LUTADOR", "", dp, cg, []])
		cmp.append([id + " DISCIPULO (_disc)", "", dd, cg, []])
	for id in ["fight_player_idle", "fight_player_jab", "fight_player_victory", "fight_player_ko"]:
		var a: Array = P.frames_of(ROOT + "assets/sprites/fight/" + id + ".png", FW)
		var dp: Array = P.frames_of(spr_dir + "fight/" + id + ".png", FW)
		var dd: Array = P.frames_of(spr_dir + "fight/" + id + "_disc.png", FW)
		cmp.append([id + " ANTES", "", a, Rect2i(8, 8, 96, 96), []])
		cmp.append([id + " 1o LUTADOR", "", dp, Rect2i(8, 8, 96, 96), []])
		cmp.append([id + " DISCIPULO (_disc)", "", dd, Rect2i(8, 8, 96, 96), []])
	contato(cmp, "FASE 6A - LUTADOR ANTES x 1o LUTADOR x DISCIPULO PADRAO (3x; a direita, 1x)", 3, out_dir + "mock/antes_depois_x3.png")
	contato(cmp, "FASE 6A - ANTES x 1o LUTADOR x DISCIPULO (1x)", 1, out_dir + "mock/antes_depois_x1.png")
	# ---- cenas na garagem real (quadros 640x360 -> GIF)
	_cena("gesto_garagem", 9.0, 30, func(k: int) -> Image:
		var q := k - 6
		var lid := "fighter_gesture" if q >= 0 and q < 8 else "fighter_idle"
		var im := garagem(lid, q if lid == "fighter_gesture" else (k / 3) % 4, "coach_idle", (k / 3) % 4)
		if lid == "fighter_gesture" and q in TAP_FRAMES:
			faisca(im, pos_de("fighter_idle", "foco_saco") + _v(entradas.fighter_gesture.tap_points[TAP_FRAMES.find(q)]), 0)
		return im)
	_cena("treinador", 6.0, 48, func(k: int) -> Image:
		var seqs := [["coach_idle", 12], ["coach_look", 9], ["coach_talk", 12], ["coach_point", 15]]
		var acc := 0
		for s in seqs:
			if k < acc + s[1]:
				var kk: int = k - acc
				var q := kk % 4 if s[0] != "coach_point" else (kk if kk < 4 else 1 + (kk - 4) % 3)
				if s[0] == "coach_idle" or s[0] == "coach_look":
					q = (kk / 2) % 4
				return garagem("fighter_idle", (k / 2) % 4, s[0], q, true)
			acc += s[1]
		return garagem("fighter_idle", 0, "coach_idle", 0, true))
	# ---- conferência do ponto do treinador: pedido (236,238) x alternativa, foco no saco (equipe cheia) e na corda
	var conf := []
	for c in [[TRAINER_POS, "saco"], [TRAINER_POS, "corda"], [ALT_POS, "saco"], [ALT_POS, "corda"]]:
		tpos = c[0]
		foco = c[1]
		var im := garagem("fighter_idle", 0, "coach_idle", 0, true)
		var reg: Image = im.get_region(Rect2i(128, 18, 384, 272))
		L.text(reg, "treinador (%d,%d) - foco %s" % [int(tpos.x), int(tpos.y), foco], 4, 4, "y1", 1, "ink")
		conf.append(reg)
	tpos = TRAINER_POS
	foco = "saco"
	var cim: Image = L.blank(384 * 2 + 4, 272 * 2 + 4)
	L.R(cim, 0, 0, cim.get_width(), cim.get_height(), "ink")
	for i in 4:
		P.paste(cim, conf[i], (i % 2) * 388, (i / 2) * 276)
	cim.save_png(out_dir + "mock/posicao_treinador_x1.png")
	var fl := FileAccess.open(out_dir + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		fl.store_line(l)
	fl.store_line("---- conferência")
	for l in report:
		fl.store_line(l)
	fl.close()
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	for l in report:
		print(l)
	print("ok: %d entradas" % entradas.size())
	quit()

func _v(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))

func _cena(nome: String, fps: float, n: int, quadro: Callable) -> void:
	var d := out_dir + "mock/seq_" + nome + "/"
	DirAccess.make_dir_recursive_absolute(d)
	for k in n:
		var im: Image = quadro.call(k)
		im.get_region(Rect2i(128, 18, 384, 272)).save_png(d + "%03d.png" % k)
