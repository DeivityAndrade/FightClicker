extends SceneTree
## Fase 8a2 (Artista de Personagens): ALUNOS DA RAÍZES, o gerador que só existe no centro de treinamento.
## 4 pessoas (1, 5, 12 e 25 unidades = 1 a 4 pessoas na sala), cada uma com UM ciclo curto de treino em 4 quadros,
## no MESMO rig, tamanho de quadro (48x72), pivô (22,67) e proporção da equipe de hoje (vizinhos, tios, Prof. Nelson):
## personagem_lib.gd, vista 3/4 (garage_frame). Personalidade = rosto, cabelo, cor de pele, calção e o exercício;
## o corpo fica dentro do normal (regra do dono: nada de proporção exagerada). Padrão: .claude/skills/padrao-personagem.
## Todos usam a camisa PRETA da escola com o R de raiz no peito (o 5x5 aprovado na 6d3, personagem_lib SYMBOL "34"),
## em tinta amarela y1 (regra da 6c2: carimbo azul só em peça branca/amarela; tinta amarela nas outras).
## O R não é simétrico: nas folhas viradas para a esquerda o carimbo é desvirado no lugar (regra da 6d3).
##
## Rodar headless de uma pasta temporária com project.godot vazio (nunca no projeto), APPDATA temporário:
##   godot --headless --max-fps 30 --path <tmp> --script <repo>/tools/art/make_sprites_fase8a2.gd -- <repo> <saida> [<mockup.png>]
## Grava <saida>/characters/student_N_idle.png, <saida>/fase8a2_personagens.json (entradas do manifest, lidas por
## tools/art/manifest_8a2_personagens.py), <saida>/seq/ (quadros na sala, para conferir o ciclo) e, se pedido, a folha
## de conferência. Não lê nem grava o manifest do projeto, salvo a leitura das folhas do lutador e do vizinho (comparação).

const FW := 48
const FH := 72
const PIV := Vector2(22, 67)
const STUDENTS := ["student_1", "student_2", "student_3", "student_4"]
## Pontos PROPOSTOS na sala larga (o Diretor de Arte confirma no layout do centro). Ao fundo, longe do alvo central
## (lutador em 303..336,272) e dos aparelhos do centro. facing = para onde olham depois do espelho.
const POS := {"student_1": Vector2(150, 258), "student_2": Vector2(232, 254), "student_3": Vector2(438, 254), "student_4": Vector2(500, 260)}
const FACING := {"student_1": "direita", "student_2": "esquerda", "student_3": "esquerda", "student_4": "direita"}
const FPS := {"student_1": 7.0, "student_2": 8.0, "student_3": 8.0, "student_4": 6.0}
const NOTE := {
	"student_1": "Aluno da Raízes (1ª pessoa, com 1): sombra (jab, pêndulo, direto), degradê, calção cinza.",
	"student_2": "Aluna da Raízes (2ª pessoa, com 5): pula corda (a corda passa por cima, na frente, embaixo do pé e atrás), rabo de cavalo, calção azul-marinho.",
	"student_3": "Aluno da Raízes (3ª pessoa, com 12): corrida no lugar com joelho alto, cabelo raspado, calção preto.",
	"student_4": "Aluna da Raízes (4ª pessoa, com 25): joelhada de Muay Thai puxando a nuca imaginária, coque afro, calção vinho.",
}

var L
var P
var report: Array = []

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================ cabeças 3/4 (dados desenhados à mão)
## Mesmo rosto do HEAD_34 (olho, sobrancelha, boca nos mesmos pixels); só o cabelo muda. pad = [colunas, linhas] a mais
## à esquerda/em cima em relação ao HEAD_34 (a âncora anda junto: o rosto fica no mesmo ponto do pescoço).
## H/h = cabelo escuro/claro; T = elástico do cabelo (head_legend_extra).
const H34_DEGRADE := [   # topo curto penteado, lados raspados (pele aparece)
	"...HHHHHHH...",
	".HHHhhhhhHHH.",
	"HHHhhhhhhhHHH",
	"HHHHHHHHHHHHs",
	"SHHSsslllllll",
	"SSHSsbbsslbbl",
	"SSESsesssles.",
	"SEsSssssslll.",
	".SESssssssss.",
	".SSsssssssSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]
const H34_RABO := [   # cabelo preso atrás, rabo de cavalo caindo na nuca (2 colunas a mais atrás)
	".....HHHHHHH...",
	"...HHHhhhhhHHH.",
	"..HHHhhhhhhhHHH",
	".THHHHHHHHHHHHs",
	"HhHHHHsslllllll",
	"hHHHHSsbbsslbbl",
	"HHHHESsesssles.",
	".HHEsSssssslll.",
	".H.HESssssssss.",
	"...HSsssssssSs.",
	"....SsssmmmSs..",
	".....SSsssss...",
	".......SSSs....",
]
const H34_RASPADO := [   # máquina zero: crânio de cabelo curtinho com a pele aparecendo (o "buzz" do discípulo)
	".............",
	"...HHHHHHH...",
	".HHHSHHHSHHH.",
	"HHHHHHHSHHSls",
	"HHHSsslllllll",
	"HHSSsbbsslbbl",
	"HSESsesssles.",
	"HEsSssssslll.",
	".SESssssssss.",
	".SSsssssssSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]
const H34_COQUE := [   # coque afro alto, atrás (3 linhas e 1 coluna a mais), elástico na base
	".HHHH.........",
	"HhhhhHH.......",
	"HhhhhhH.......",
	".HTTTHHHHHH...",
	"..HHHhhhhhHHH.",
	".HHHhhhhhhhHHH",
	".HHHHHHHHHHHHs",
	".HHHHsslllllll",
	".HHHSsbbsslbbl",
	".HHESsesssles.",
	".HEsSssssslll.",
	"..HESssssssss.",
	"..HSsssssssSs.",
	"...SsssmmmSs..",
	"....SSsssss...",
	"......SSSs....",
]

## Tênis (mesma legenda do SHOE_34 da lib; D/M/L/w/c).
func build(sid: String) -> Dictionary:
	var preta := ["d1", "d2", "g0"]   # camisa preta da escola (sombra, base, luz)
	var o := {}
	match sid:
		"student_1":   # homem, pele média, degradê; camiseta; calção cinza; tênis branco
			o = {"head_34": H34_DEGRADE, "hair": ["ink", "d2"], "brow": "ink", "skin": ["sk0", "sk1", "sk2"],
				"top": "tshirt", "sleeve_t": 0.42, "shorts": ["g0", "g1", "g2"], "band": "d2",
				"shoes": ["g2", "g3", "white", "d2", "g1"], "glove": "fist", "shoulder": 1.0, "hip_w": 0.95,
				"g_arm_r": [2.4, 1.9, 2.1, 1.6], "g_leg_r": [3.3, 2.5, 2.4, 1.4]}
		"student_2":   # mulher, pele clara, rabo de cavalo castanho; regata; calção azul-marinho; tênis rosa
			o = {"head_34": H34_RABO, "head_anchor_34": Vector2i(8, 6), "hair": ["br1", "br2"], "brow": "br1",
				"skin": ["sk1", "sk2", "y2"], "head_legend_extra": {"T": "f1"},
				"top": "tank", "shorts": ["b0", "b1", "b2"], "band": "b2",
				"shoes": ["g2", "g3", "white", "f1", "g1"], "glove": "fist", "shoulder": 0.9, "hip_w": 0.98,
				"g_arm_r": [2.2, 1.7, 1.9, 1.4], "g_leg_r": [3.3, 2.4, 2.3, 1.4]}
		"student_3":   # homem, pele escura, raspado; camiseta; calção preto; tênis vermelho
			o = {"head_34": H34_RASPADO, "hair": ["ink", "d2"], "brow": "ink", "skin": ["br0", "sk0", "sk1"],
				"top": "tshirt", "sleeve_t": 0.42, "shorts": ["ink", "d1", "d2"], "band": "g0",
				"shoes": ["r0", "r1", "r2", "white", "g1"], "glove": "fist", "shoulder": 0.97, "hip_w": 0.93,
				"g_arm_r": [2.4, 1.9, 2.1, 1.6], "g_leg_r": [3.3, 2.5, 2.4, 1.4]}
		"student_4":   # mulher, pele média-escura, coque afro; regata; calção de Muay Thai vinho com cós claro; descalça? não: tênis
			o = {"head_34": H34_COQUE, "head_anchor_34": Vector2i(7, 9), "hair": ["ink", "d2"], "brow": "ink",
				"skin": ["br0", "sk0", "sk1"], "head_legend_extra": {"T": "y0"},
				"top": "tank", "shorts": ["r0", "r1", "r2"], "band": "white", "shorts_t": 0.36,
				"shoes": ["g1", "g2", "g3", "y0", "d2"], "glove": "fist", "shoulder": 0.92, "hip_w": 1.0,
				"g_arm_r": [2.2, 1.7, 1.9, 1.4], "g_leg_r": [3.4, 2.5, 2.3, 1.4]}
	o["shirt"] = preta
	o["school_symbol"] = "chest"
	o["tank_neck"] = 0.86
	var b: Dictionary = P.build(o)
	var pad := Vector2i(0, 0)
	match sid:
		"student_2": pad = Vector2i(2, 0)
		"student_4": pad = Vector2i(1, 3)
	b["faces_34"] = P._cut_faces(P.HEAD_34, P.FACES_34, b.head_34, pad.x, pad.y)
	return b

# ================================================================ poses (relativas ao pivô, virado à direita)
func gpose(o := {}) -> Dictionary:
	var p := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47),
		"hl": V(-8, -50), "hr": V(10, -51), "el": V(-9, -40), "er": V(10, -40), "toel": V(-1, 0), "toer": V(10, 0)}
	for k in o:
		p[k] = o[k]
	return p

func sem(p: Dictionary, chaves: Array) -> Dictionary:
	for k in chaves:
		p.erase(k)
	return p

## Desloca o corpo (pulo). feet = os pés vão junto.
func shifted(p: Dictionary, dy: float, feet: bool) -> Dictionary:
	var q := p.duplicate()
	for k in ["hip", "top", "head", "sl", "sr", "hl", "hr", "el", "er"]:
		if q.has(k):
			q[k] = (q[k] as Vector2) + V(0, dy)
	if feet:
		for k in ["toel", "toer"]:
			q[k] = (q[k] as Vector2) + V(0, dy)
	return q

func poses(sid: String) -> Array:
	match sid:
		"student_1":   # sombra: 0 guarda, 1 JAB com o corpo, 2 pêndulo (afunda e sai da linha, antecipa), 3 DIRETO de trás girando o quadril (o pé de trás sobe na ponta)
			return [
				gpose({"hip": V(-1, -30.5), "top": V(0, -49.5), "head": V(0, -56.5), "sl": V(-8, -46.5), "sr": V(7, -46.5),
					"hl": V(-7, -50), "el": V(-10, -40), "hr": V(10, -51), "er": V(10, -40.5), "tw": -0.2, "kl": V(1, 0), "kr": V(1, 0)}),
				sem(gpose({"hip": V(1, -30), "top": V(3, -49), "head": V(4, -55.5), "sl": V(-5, -47), "sr": V(10, -48), "face": "effort",
					"hl": V(-6, -51), "el": V(-8, -41), "hr": V(21, -49), "fs": 0.62, "pr": V(0.2, 1), "shoel": "34ball", "tw": 1.0,
					"gkr": "", "kl": V(1, 0), "kr": V(1, 0)}), ["er"]),
				gpose({"hip": V(-1, -28.5), "top": V(-2, -47), "head": V(-3, -54), "sl": V(-10, -44), "sr": V(5, -44.5),
					"hl": V(-9, -48), "el": V(-12, -38), "hr": V(7, -49), "er": V(7, -38.5), "tw": -0.7, "kl": V(1, 0), "kr": V(1, 0)}),
				sem(gpose({"hip": V(2, -30), "top": V(4, -49.5), "head": V(4, -56), "sl": V(1, -47), "sr": V(8, -48.5), "face": "effort", "tw": 1.6,
					"hl": V(20, -47), "pl": V(0, 1), "hr": V(10, -51), "er": V(10, -41.5), "shoel": "34ball", "gkl": "",
					"kl": V(1, 0), "kr": V(1, 0)}), ["el"]),
			]
		"student_2":   # corda: 0 pousa (amassa 1,5 px, corda por cima), 1 sobe (corda na frente, nos joelhos), 2 no alto (corda
			# embaixo do pé), 3 desce (corda atrás, subindo). Cotovelos colados nas costelas, antebraços abertos para os lados
			# (as mãos giram o punho na altura do quadril): braço e antebraço com o mesmo comprimento em todos os quadros.
			var ar := gpose({"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47),
				"el": V(-9, -38), "hl": V(-17, -32.5), "er": V(10, -38), "hr": V(18, -32.5), "gkl": "", "gkr": "",
				"toel": V(-1, 0), "toer": V(8, 0), "kl": V(1, 0), "kr": V(1, 0)})
			var f0 := shifted(ar, 1.5, false)
			f0["rope"] = "over"
			var f1 := shifted(ar, -2.0, true)
			f1.merge({"shoel": "34ball", "shoer": "34ball", "rope": "front_low"}, true)
			var f2 := shifted(ar, -2.5, true)
			f2.merge({"shoel": "34ball", "shoer": "34ball", "rope": "under", "hl": V(-17, -34.5), "hr": V(18, -34.5)}, true)
			var f3 := shifted(ar, -2.0, true)
			f3.merge({"shoel": "34ball", "shoer": "34ball", "rope": "back"}, true)
			return [f0, f1, f2, f3]
		"student_3":   # corrida no lugar com joelho alto: 0 joelho esquerdo (da tela) em cima, braço direito à frente (punho no
			# queixo) e o esquerdo atrás; 1 troca (pés perto do chão, corpo 2 px mais baixo, braços passando pela cintura);
			# 2 joelho direito em cima, braços trocados; 3 troca de novo. Cotovelo sempre a 90 graus (comprimentos fixos).
			var base := {"kl": V(1, 0), "kr": V(1, 0), "gkl": "", "gkr": ""}
			var a0 := gpose({"hip": V(0, -32), "top": V(1, -51), "head": V(1, -58), "sl": V(-7, -48), "sr": V(8, -48.5),
				"toel": V(2, -12), "shoel": "34ball", "toer": V(9, 0), "shoer": "34ball",
				"el": V(-10, -39.5), "hl": V(-13, -31), "er": V(11, -40), "hr": V(9, -49)})
			var a1 := gpose({"hip": V(0, -30), "top": V(1, -49), "head": V(1, -56), "sl": V(-7, -46), "sr": V(8, -46),
				"toel": V(-1, -1), "shoel": "34ball", "toer": V(9, 0), "shoer": "34", "face": "effort",
				"el": V(-9, -37.5), "hl": V(-5, -31), "er": V(10, -37.5), "hr": V(13, -31)})
			var a2 := gpose({"hip": V(0, -32), "top": V(1, -51), "head": V(1, -58), "sl": V(-7, -48.5), "sr": V(8, -48),
				"toel": V(-1, 0), "shoel": "34ball", "toer": V(12, -12), "shoer": "34ball",
				"el": V(-9, -39.5), "hl": V(-6, -48), "er": V(11, -39.5), "hr": V(14, -31)})
			var a3 := gpose({"hip": V(0, -30), "top": V(1, -49), "head": V(1, -56), "sl": V(-7, -46), "sr": V(8, -46),
				"toel": V(-1, 0), "shoel": "34", "toer": V(10, -1), "shoer": "34ball", "face": "effort",
				"el": V(-9, -37.5), "hl": V(-5, -31), "er": V(10, -37.5), "hr": V(13, -31)})
			for p in [a0, a1, a2, a3]:
				(p as Dictionary).merge(base, true)
			return [a0, a1, a2, a3]
		"student_4":   # joelhada (Muay Thai): 0 guarda alta, 1 as mãos sobem e agarram a nuca imaginária (antecipa, quadril
			# recua), 2 JOELHADA: puxa as mãos para baixo, o quadril vai à frente e o joelho direito sobe até a cintura,
			# na ponta do pé de apoio; 3 o pé volta ao chão e a guarda volta (passa 1 px do ponto)
			var g := gpose({"hip": V(0, -30.5), "top": V(1, -49.5), "head": V(1, -56.5), "sl": V(-7, -46.5), "sr": V(8, -46.5),
				"hl": V(-6, -51), "el": V(-9, -41), "hr": V(10, -52), "er": V(10, -41.5), "toel": V(-2, 0), "toer": V(10, 0),
				"kl": V(1, 0), "kr": V(1, 0)})
			var ag := sem(gpose({"hip": V(-1, -30.5), "top": V(0, -49.5), "head": V(0, -56.5), "sl": V(-8, -46.5), "sr": V(7, -46.5),
				"hl": V(8, -58), "pl": V(-0.2, 1), "hr": V(16, -57), "pr": V(0.3, 1), "gkl": "", "gkr": "",
				"toel": V(-2, 0), "toer": V(10, 0), "kl": V(1, 0), "kr": V(1, 0), "tw": -0.3}), ["el", "er"])
			var jo := sem(gpose({"hip": V(1, -31), "top": V(1, -50), "head": V(2, -56), "sl": V(-6, -47.5), "sr": V(9, -47.5),
				"hl": V(9, -45), "pl": V(-0.2, 1), "hr": V(17, -45), "pr": V(0.3, 1), "gkl": "", "gkr": "", "face": "effort",
				"toel": V(-2, 0), "shoel": "34ball", "toer": V(13, -16), "shoer": "34ball", "kl": V(1, 0), "kr": V(1, -0.4), "tw": 0.8}), ["el", "er"])
			var rec := gpose({"hip": V(0, -30), "top": V(1, -49), "head": V(1, -56), "sl": V(-7, -46), "sr": V(8, -46),
				"hl": V(-6, -50), "el": V(-9, -40), "hr": V(11, -50), "er": V(10, -40), "toel": V(-2, 0), "toer": V(11, 0),
				"kl": V(1, 0), "kr": V(1, 0)})
			return [g, ag, jo, rec]
	return []

# ================================================================ corda (student_2)
## Corda = curva entre as duas mãos (Bézier quadrática), desenhada no quadro já pronto (1 px, sem contorno).
## "over"/"back" = atrás do corpo (só pinta pixel vazio); "front_low"/"under" = na frente.
func draw_rope(im: Image, p: Dictionary) -> void:
	if not p.has("rope"):
		return
	var a: Vector2 = PIV + (p.hl as Vector2) + V(-1, 1)
	var c: Vector2 = PIV + (p.hr as Vector2) + V(1, 1)
	var apex := 0.0
	var front := true
	match p.rope:
		"over": apex = PIV.y - 66.0; front = false
		"front_low": apex = PIV.y - 11.0
		"under": apex = PIV.y + 1.0
		"back": apex = PIV.y - 47.0; front = false
	var ctrl := V((a.x + c.x) * 0.5, 2.0 * apex - 0.5 * (a.y + c.y))
	# a corda sai das mãos e abre para os lados (não passa reto por dentro do corpo)
	var spread := 3.0 if p.rope in ["over", "under"] else 2.0
	var col_r: Color = L.col("st3")
	var col_d: Color = L.col("st1")
	var last := Vector2i(-99, -99)
	for i in 121:
		var t := float(i) / 120.0
		var q := a.lerp(ctrl, t).lerp(ctrl.lerp(c, t), t)
		q.x += sin(t * PI) * 0.0 + (t - 0.5) * 2.0 * spread * sin(t * PI)
		var pp := Vector2i(int(floor(q.x)), int(floor(q.y)))
		if pp == last or pp.x < 0 or pp.y < 0 or pp.x >= FW or pp.y >= FH:
			continue
		last = pp
		if not front and im.get_pixel(pp.x, pp.y).a > 0.0:
			continue
		im.set_pixel(pp.x, pp.y, col_r if not front or p.rope == "under" or (i % 9) != 0 else col_d)
	# cabos (2 px de cabo vermelho na mão, saindo para baixo)
	for h in [a, c]:
		for k in 2:
			var x := int(h.x)
			var y := int(h.y) + 1 + k
			if x >= 0 and y < FH:
				im.set_pixel(x, y, L.col("r1" if k == 0 else "r2"))

# ================================================================ R da escola
const SYM_KEY := "304a78"   # k_sy1 (estampa)
const SYM_KEY_D := "1f2a45"  # k_sy0 (sombra de contato sobre a estampa)

## Desenha o quadro com e sem o R; troca a cor-chave por tinta amarela e, se o quadro vai ser espelhado, desvira o R.
func frame_with_symbol(b: Dictionary, p: Dictionary, tag: String, left: bool) -> Image:
	var com: Image = P.garage_frame(b, p, tag, Vector2i(FW, FH), PIV)
	b["school_symbol"] = ""
	var sem_r: Image = P.garage_frame(b, p, tag + " (sem R)", Vector2i(FW, FH), PIV)
	b["school_symbol"] = "chest"
	var pts := []
	for y in FH:
		for x in FW:
			var hx := com.get_pixel(x, y).to_html(false)
			if hx == SYM_KEY or hx == SYM_KEY_D:
				pts.append([Vector2i(x, y), "y1" if hx == SYM_KEY else "y0"])
	var out: Image = sem_r
	if left:
		out.flip_x()
	if pts.is_empty():
		report.append("AVISO %s: o R não apareceu" % tag)
		return out
	var x0 := 999
	var x1 := -1
	for e in pts:
		x0 = mini(x0, (e[0] as Vector2i).x)
		x1 = maxi(x1, (e[0] as Vector2i).x)
	for e in pts:
		var q: Vector2i = e[0]
		var nx := q.x
		if left:
			# espelhado = (FW-1-x); desvirado no lugar = mesma caixa, ordem original das colunas
			nx = (FW - 1 - x1) + (q.x - x0)
		var under := out.get_pixel(nx, q.y)
		# só pinta onde é camisa (no espelho o braço pode estar na frente de outra coluna)
		if under.a > 0.0 and under.to_html(false) in [L.col("d1").to_html(false), L.col("d2").to_html(false), L.col("g0").to_html(false), L.col("ink").to_html(false)]:
			if under == L.col("ink") and not _inside(out, nx, q.y):
				continue
			out.set_pixel(nx, q.y, L.col(e[1]))
	report.append("%s: R com %d px (%s)" % [tag, pts.size(), "desvirado" if left else "direto"])
	return out

func _inside(im: Image, x: int, y: int) -> bool:
	# ink de contorno de silhueta tem vizinho transparente; ink de dentro (sombra) não
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q: Vector2i = Vector2i(x, y) + d
		if q.x < 0 or q.y < 0 or q.x >= FW or q.y >= FH or im.get_pixel(q.x, q.y).a == 0.0:
			return false
	return true

# ================================================================ luz
## A sala do centro ainda não tem a luz final; a luz pintada aqui é a da sala larga (a mesma conta dos ajudantes na 6d2,
## lâmpadas/tubos de cima): cabeça e tronco no tom da rampa, pernas 1 tom abaixo, emenda de 2 linhas em xadrez no fim
## do calção. Igual em todos os quadros e pontos (não depende do ponto: dá para mover o aluno sem gerar de novo).
func luz(im: Image, p: Dictionary, left: bool) -> void:
	var y_perna := int(round(PIV.y + (p.hip as Vector2).y)) + 7
	for y in range(y_perna, FH):
		for x in FW:
			var c := im.get_pixel(x, y)
			if c.a == 0.0:
				continue
			if y < y_perna + 2 and (x + y) % 2 == 0:
				continue
			im.set_pixel(x, y, L.shade(c, -1))

func gen(sid: String) -> Array:
	var b := build(sid)
	var left: bool = FACING[sid] == "esquerda"
	var out := []
	var ps := poses(sid)
	for i in ps.size():
		var p: Dictionary = ps[i]
		var im := frame_with_symbol(b, p, "%s[%d]" % [sid, i], left)
		if p.has("rope"):
			if left:
				im.flip_x()
			draw_rope(im, p)
			if left:
				im.flip_x()
		luz(im, p, left)
		_check_bounds(im, sid, i)
		out.append(im)
	return out

func _check_bounds(im: Image, id: String, i: int) -> void:
	for y in FH:
		for x in FW:
			if im.get_pixel(x, y).a > 0.0 and (x == 0 or y == 0 or x == FW - 1 or y == FH - 1):
				report.append("AVISO %s[%d]: pixel na borda do quadro (%d,%d)" % [id, i, x, y])
				return

# ================================================================ folha de conferência
func _load(p: String) -> Image:
	var im := Image.load_from_file(p)
	im.convert(Image.FORMAT_RGBA8)
	return im

func scaled(im: Image, k: int) -> Image:
	var r: Image = im.duplicate()
	r.resize(im.get_width() * k, im.get_height() * k, Image.INTERPOLATE_NEAREST)
	return r

func fr_of(sheet: Image, q: int) -> Image:
	return sheet.get_region(Rect2i(q * FW, 0, FW, FH))

func checker(dst: Image, x: int, y: int, w: int, h: int, cell: int) -> void:
	for yy in range(0, h, cell):
		for xx in range(0, w, cell):
			L.R(dst, x + xx, y + yy, mini(cell, w - xx), mini(cell, h - yy), "g1" if ((xx / cell + yy / cell) % 2 == 0) else "g0")

func room(repo: String, sheets: Dictionary, q: int, n: int) -> Image:
	var im := _load(repo + "docs/arte/mockups/fase6d2_fundo_academia.png")
	var sh := _load(repo + "assets/sprites/garage/floor_shadow.png")
	var people := []
	for k in n:
		people.append([STUDENTS[k], POS[STUDENTS[k]], PIV, sheets[STUDENTS[k]], q])
	# lutador no ponto do saco e a equipe antiga nos pontos dela (comparação de tamanho)
	people.append(["fighter", V(303, 272), V(22, 67), _load(repo + "assets/sprites/characters/fighter_idle.png"), 0])
	people.append(["neighbor_1", V(72, 322), V(22, 67), _load(repo + "assets/sprites/characters/neighbor_1_idle.png"), q])
	people.append(["uncle_1", V(400, 324), V(25, 67), _load(repo + "assets/sprites/characters/uncle_1_idle.png"), q])
	people.sort_custom(func(a, b): return (a[1] as Vector2).y < (b[1] as Vector2).y)
	for e in people:
		var pos := Vector2i(e[1])
		im.blend_rect(sh, Rect2i(Vector2i.ZERO, sh.get_size()), pos - Vector2i(16, 5))
		var f := fr_of(e[3], e[4])
		im.blend_rect(f, Rect2i(Vector2i.ZERO, f.get_size()), pos - Vector2i(e[2]))
	return im

func mockup(repo: String, sheets: Dictionary, path: String) -> void:
	var W := 1296
	var out: Image = L.blank(W, 1500)
	out.fill(L.col("d1"))
	var y := 6
	L.text(out, "FASE 8A2 - ALUNOS DA RAIZES (student_1..4)  48x72, pivo (22,67), 4 quadros  -  fundo: sala larga da academia (o centro ainda nao tem fundo)", 6, y, "white")
	y += 12
	# 1) sala em 1x, 4 alunos, os 4 quadros (1x lado a lado)
	L.text(out, "1x NA SALA (quadros 0-3, com 4 alunos, o lutador no saco e a equipe antiga)", 6, y, "y1")
	y += 10
	var crop := Rect2i(0, 168, 640, 164)
	for q in 4:
		var r := room(repo, sheets, q, 4).get_region(crop)
		out.blit_rect(r, Rect2i(Vector2i.ZERO, r.get_size()), Vector2i(6 + (q % 2) * 644, y + (q / 2) * 168))
	y += 168 * 2 + 6
	# 2) sala em 2x (quadro 0)
	L.text(out, "2x NA SALA (quadro 0)", 6, y, "y1")
	y += 10
	var r2 := scaled(room(repo, sheets, 0, 4).get_region(Rect2i(0, 180, 640, 150)), 2)
	out.blit_rect(r2, Rect2i(Vector2i.ZERO, r2.get_size()), Vector2i(6, y))
	y += 300 + 8
	# 3) ciclos em 4x sobre xadrez + lutador e vizinho na mesma escala
	L.text(out, "4x: CICLOS (0-3)  |  LUTADOR (fighter_idle) e VIZINHO para comparar a proporcao", 6, y, "y1")
	y += 10
	var crop2 := Rect2i(6, 0, 36, 70)
	var x := 6
	var yy := y
	for sid in STUDENTS:
		for q in 4:
			checker(out, x, yy, crop2.size.x * 3, crop2.size.y * 3, 9)
			var f := scaled(fr_of(sheets[sid], q).get_region(crop2), 3)
			out.blend_rect(f, Rect2i(Vector2i.ZERO, f.get_size()), Vector2i(x, yy))
			x += crop2.size.x * 3 + 2
		x += 10
		if sid == "student_2":
			x = 6
			yy += crop2.size.y * 3 + 6
	# comparação
	var fx := 6 + (crop2.size.x * 3 + 2) * 8 + 30
	for e in [["fighter_idle", 0], ["neighbor_1_idle", 0]]:
		var sh := _load(repo + "assets/sprites/characters/%s.png" % e[0])
		checker(out, fx, y, crop2.size.x * 3, crop2.size.y * 3, 9)
		var f := scaled(fr_of(sh, 0).get_region(crop2), 3)
		out.blend_rect(f, Rect2i(Vector2i.ZERO, f.get_size()), Vector2i(fx, y))
		L.text(out, str(e[0]).replace("_idle", ""), fx + 2, y + crop2.size.y * 3 + 2, "white")
		fx += crop2.size.x * 3 + 6
	# alunos e lutador lado a lado 3x (quadro 0) para a linha dos olhos / altura
	var bx := 6 + (crop2.size.x * 3 + 2) * 8 + 30
	var by := y + crop2.size.y * 3 + 16
	L.text(out, "LADO A LADO 1x (quadro 0)", bx, by, "y1")
	by += 10
	var strip: Image = L.blank(FW * 6, FH)
	var fsheet := _load(repo + "assets/sprites/characters/fighter_idle.png")
	strip.blit_rect(fr_of(fsheet, 0), Rect2i(0, 0, FW, FH), Vector2i(0, 0))
	for k in 4:
		strip.blit_rect(fr_of(sheets[STUDENTS[k]], 0), Rect2i(0, 0, FW, FH), Vector2i(FW * (k + 1), 0))
	strip.blit_rect(fr_of(_load(repo + "assets/sprites/characters/neighbor_1_idle.png"), 0), Rect2i(0, 0, FW, FH), Vector2i(FW * 5, 0))
	L.R(out, bx, by, FW * 6, FH, "g1")
	out.blend_rect(strip, Rect2i(0, 0, FW * 6, FH), Vector2i(bx, by))
	var big := scaled(strip, 2)
	L.R(out, bx, by + FH + 6, FW * 12, FH * 2, "g1")
	out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(bx, by + FH + 6))
	y = yy + crop2.size.y * 3 + 8
	var labels := ["1 SOMBRA (jab, pendulo, direto)", "2 CORDA (por cima, frente, sob o pe, atras)", "3 CORRIDA NO LUGAR (joelho alto)", "4 JOELHADA (Muay Thai)"]
	for k in 4:
		L.text(out, labels[k], 6, y + k * 10, "white")
	y += 46
	out.crop(W, y)
	out.save_png(path)

# ================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var repo: String = args[0].replace("\\", "/").trim_suffix("/") + "/"
	var out_dir: String = args[1].replace("\\", "/").trim_suffix("/") + "/"
	L = load(repo + "tools/art/pixel_lib.gd").new()
	P = load(repo + "tools/art/personagem_lib.gd").new(L)
	P.use_keys()
	var sheets := {}
	var entradas := {}
	DirAccess.make_dir_recursive_absolute(out_dir + "characters")
	DirAccess.make_dir_recursive_absolute(out_dir + "seq")
	for sid in STUDENTS:
		var fr := gen(sid)
		var s: Image = P.strip(fr)
		s.save_png(out_dir + "characters/%s_idle.png" % sid)
		sheets[sid] = s
		entradas[sid] = {"file": "res://assets/sprites/characters/%s_idle.png" % sid, "frame_size": [FW, FH], "frames": fr.size(),
			"fps": FPS[sid], "pivot": [int(PIV.x), int(PIV.y)], "loop": true, "pos": [int(POS[sid].x), int(POS[sid].y)],
			"facing": FACING[sid], "note": NOTE[sid]}
	var by := {"center_students": {"people": STUDENTS.duplicate(),
		"_nota": "pessoa i aparece se GameState.pessoas_desenhadas('center_students') > i (draw_thresholds 1, 5, 12, 25). Cada uma com floor_shadow nos pés. pos = proposta do Artista de Personagens; o Diretor de Arte confirma no layout do centro (a luz pintada não depende do ponto). O ícone (icon) fica com o Diretor de Arte."}}
	var f := FileAccess.open(out_dir + "fase8a2_personagens.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"sprites": entradas, "by_data_id": by}, "\t"))
	f.close()
	if args.size() > 2:
		mockup(repo, sheets, args[2])
		for q in 4:
			room(repo, sheets, q, 4).save_png(out_dir + "seq/sala_%d.png" % q)
	var rf := FileAccess.open(out_dir + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		rf.store_line(l)
	rf.store_line("---- conferência")
	for l in report:
		rf.store_line(l)
	rf.close()
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	for l in report:
		if (l as String).begins_with("AVISO"):
			print(l)
	print("ok 8a2: %d alunos" % sheets.size())
	quit()
