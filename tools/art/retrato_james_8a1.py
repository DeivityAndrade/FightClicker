# Fase 8a1 (Artista de Personagens): retrato do JAMES BLINDADO para a caixa de diálogo, desenhado como DADO (mapa de pixels).
# Busto 3/4 virado para a DIREITA, 48x48 (mostrar em 2x = 96x96), fundo transparente, 3 expressões no mesmo busto:
#   0 "smirk"  meio sorriso de canto, sobrancelha da frente erguida (a fala normal dele)
#   1 "sneer"  desprezo: pálpebras caídas, olha por baixo do nariz, lábio torto (a fala que menospreza a escola)
#   2 "laugh"  riso de deboche, olhos apertados, dentes à mostra (quando ele vence)
# Roupão de luta azul-marinho com debrum dourado e o brasão de escudo no peito (academia tradicional, rica).
# Rodar: python tools/art/retrato_james_8a1.py [pasta_previa]   -> grava tools/art/retrato_james_8a1.json (+ prévia PNG 1x/4x)
# O make_sprites_elenco.gd (modo "regional") lê o JSON e grava assets/sprites/opponents/portrait_opp_james_dialog.png.
import json, os, sys, zlib, struct

AQUI = os.path.dirname(os.path.abspath(__file__))
W = H = 48

LEGEND = {
    "K": "ink",
    "D": "br2", "H": "y0", "h": "y1", "y": "y2",          # cabelo loiro (sombra, base, luz, brilho)
    "S": "sk0", "s": "sk1", "l": "sk2",                   # pele (sombra quente, base, luz)
    "b": "br1", "e": "ink", "w": "cream", "i": "b1",       # sobrancelha, olho, branco do olho, íris
    "m": "br0", "n": "sk0", "T": "white",                   # boca, lábio, dentes
    "r": "b0", "R": "b1", "Q": "b2",                       # roupão (sombra, base, luz)
    "O": "br2", "G": "y0", "g": "y1",                      # debrum e brasão dourados
}

cv = [["."] * W for _ in range(H)]


def put(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        cv[y][x] = c


def span(y, x0, x1, c):
    for x in range(x0, x1 + 1):
        put(x, y, c)


def at(x, y):
    return cv[y][x] if 0 <= x < W and 0 <= y < H else "."


# ------------------------------------------------------------------ silhuetas (linha: x esquerdo, x direito)
HAIR = {1: (27, 32), 2: (23, 34), 3: (20, 35), 4: (18, 36), 5: (16, 36), 6: (15, 36), 7: (14, 35), 8: (13, 35),
        9: (13, 35), 10: (13, 34), 11: (13, 34)}
HEAD = {12: (13, 34), 13: (13, 34), 14: (13, 34), 15: (13, 34), 16: (13, 34), 17: (13, 34), 18: (13, 35), 19: (13, 35),
        20: (13, 35), 21: (13, 35), 22: (13, 35), 23: (13, 34), 24: (14, 34), 25: (14, 34), 26: (15, 34), 27: (16, 34),
        28: (17, 33), 29: (18, 33), 30: (19, 32), 31: (20, 32), 32: (22, 31), 33: (24, 29)}
NECK = {33: (18, 23), 34: (18, 30), 35: (18, 30), 36: (18, 30)}
BODY = {36: (10, 38), 37: (6, 41), 38: (4, 43), 39: (3, 44), 40: (2, 45), 41: (1, 46), 42: (1, 46), 43: (0, 47),
        44: (0, 47), 45: (0, 47), 46: (0, 47), 47: (0, 47)}

# corpo: roupão (base), luz no ombro esquerdo (de onde vem a luz), sombra à direita
for y, (a, b) in BODY.items():
    for x in range(a, b + 1):
        c = "R"
        if x > b - 7 or y > 44 and x > 30:
            c = "r"
        elif x < a + 8 and y < 42:
            c = "Q"
        put(x, y, c)
# pescoço (sombra embaixo do queixo)
for y, (a, b) in NECK.items():
    for x in range(a, b + 1):
        put(x, y, "S" if (x > 25 or y == 33 or y == 34 and x > 22) else "s")
# peito no decote em V do roupão (de 36 até 47), músculo com luz à esquerda
for y in range(36, 48):
    hw = max(0, 6 - (y - 36) // 2)
    cx = 24
    for x in range(cx - hw, cx + hw + 1):
        put(x, y, "l" if x < cx - 2 else ("S" if x > cx + 2 else "s"))
# debrum dourado nas duas lapelas (2 px: luz por fora, sombra por dentro)
for y in range(36, 48):
    hw = max(0, 6 - (y - 36) // 2)
    put(24 - hw - 1, y, "g"); put(24 - hw - 2, y, "G")
    put(24 + hw + 1, y, "G"); put(24 + hw + 2, y, "O")
# linha do peitoral
for x in range(20, 24):
    put(x, 42, "S")
put(24, 43, "S")
# brasão de escudo dourado no peito esquerdo (dele: lado direito da tela, como numa academia de verdade)
SHIELD = ["GgggG", "GgOgG", "GgOgG", ".GgG.", "..G.."]
for j, row in enumerate(SHIELD):
    for i, c in enumerate(row):
        if c != ".":
            put(33 + i, 40 + j, c)

# cabeça: pele com luz à esquerda/em cima e sombra quente à direita e embaixo do queixo
for y, (a, b) in HEAD.items():
    for x in range(a, b + 1):
        c = "s"
        if x >= b - 1 or y >= 30 or (x == b - 2 and y >= 22):
            c = "S"
        elif x <= a + 4 and y < 27:
            c = "l"
        put(x, y, c)

# cabelo: topete loiro que sobe e avança sobre a testa, laterais curtas, brilho em faixa
for y, (a, b) in HAIR.items():
    for x in range(a, b + 1):
        c = "H"
        if y <= 3 or (x > b - 3 and y < 8):
            c = "h"
        if x < a + 2 or y >= 10 and x < 17:
            c = "D"
        put(x, y, c)
for x, y in [(26, 2), (27, 2), (28, 3), (29, 3), (24, 4), (25, 4), (30, 4), (31, 5), (21, 5), (22, 5)]:
    put(x, y, "y")
for x, y in [(23, 6), (24, 6), (25, 7), (28, 6), (29, 7), (30, 7), (18, 7), (19, 8)]:
    put(x, y, "D")   # ondas do topete
# franja: a frente do topete cai sobre a testa (linha 10-12, lado direito) e o resto do cabelo é curto
span(12, 13, 17, "D"); span(13, 13, 16, "D"); span(14, 13, 15, "D")
span(10, 28, 34, "H"); span(11, 30, 34, "H"); put(33, 12, "H"); put(34, 12, "H"); put(31, 11, "D"); put(29, 10, "D")
# costeleta e cabelo atrás da orelha
for y in range(15, 21):
    put(13, y, "D"); put(14, y, "D")
put(15, 15, "D"); put(15, 16, "D")

# orelha (lado esquerdo, 3/4)
for y in range(17, 24):
    put(12, y, "s"); put(13, y, "l" if y < 20 else "s"); put(14, y, "S" if y in (19, 20, 21) else "s")
put(12, 17, "S"); put(12, 23, "S"); put(13, 22, "S")

# ------------------------------------------------------------------ rosto (expressão 0 = base)
def rosto_base():
    # sobrancelhas grossas (perto: 20-25; longe: 29-32)
    span(16, 20, 25, "b"); put(19, 17, "b")
    span(15, 29, 32, "b"); put(33, 16, "b")     # a de longe erguida (meio desdém)
    # olhos: perto 21-24, longe 30-32 (o de longe menor por estar virado)
    span(18, 21, 24, "K"); put(21, 19, "w"); put(22, 19, "i"); put(23, 19, "e"); put(24, 19, "w")
    span(17, 30, 32, "K"); put(30, 18, "w"); put(31, 18, "e"); put(32, 18, "i")
    # nariz: crista com luz, ponta virada para a direita, narina em sombra
    for y in range(19, 25):
        put(28, y, "l")
        put(29, y, "s")
    put(30, 23, "s"); put(31, 24, "S"); put(30, 25, "S"); put(29, 25, "S"); put(27, 25, "S"); put(28, 25, "m")
    # maçã do rosto e sombra lateral
    put(18, 22, "l"); put(19, 22, "l"); put(33, 20, "S"); put(33, 21, "S")
    # boca: meio sorriso de canto (o lado de longe sobe)
    span(28, 23, 28, "m"); put(29, 27, "m"); put(30, 26, "m"); put(24, 29, "n"); put(25, 29, "n"); put(26, 29, "n")
    # queixo forte com covinha
    put(27, 31, "S"); put(27, 32, "S")


def rosto_sneer():
    rosto_base()
    # pálpebras caídas: metade de cima do olho some (olha por baixo do nariz), sobrancelhas baixas e retas
    span(16, 20, 25, "s"); span(15, 29, 32, "s"); put(33, 16, "s"); put(19, 17, "s")
    span(17, 20, 25, "b"); span(16, 29, 33, "b")
    span(18, 21, 24, "b"); span(19, 21, 24, "K"); put(22, 19, "e")
    span(17, 30, 32, "b"); span(18, 30, 32, "K")
    # lábio torto: o canto de longe sobe e mostra a narina franzida
    span(28, 23, 30, "s"); put(29, 27, "s"); put(30, 26, "s")
    span(28, 23, 26, "m"); put(27, 27, "m"); put(28, 27, "m"); put(29, 26, "m"); put(30, 26, "m")
    put(30, 24, "S"); put(31, 23, "S")


def rosto_laugh():
    rosto_base()
    # olhos apertados de riso (arcos), sobrancelhas sobem
    span(16, 20, 25, "s"); put(19, 17, "s"); span(15, 29, 32, "s"); put(33, 16, "s")
    span(15, 20, 25, "b"); span(14, 29, 32, "b")
    span(18, 21, 24, "s"); span(19, 21, 24, "s")
    span(18, 22, 23, "K"); put(21, 19, "K"); put(24, 19, "K")
    span(17, 30, 32, "s"); span(18, 30, 32, "s"); span(17, 30, 31, "K"); put(32, 18, "K")
    # boca aberta: dentes em cima, sombra embaixo
    span(28, 23, 28, "s"); put(29, 27, "s"); put(30, 26, "s"); span(29, 24, 26, "s")
    span(26, 23, 30, "m")
    span(27, 23, 30, "T"); put(22, 27, "m"); put(31, 27, "m")
    span(28, 23, 30, "m"); span(29, 24, 29, "n")


def contorno():
    # contorno ink só na silhueta externa (padrão de personagem)
    out = [row[:] for row in cv]
    for y in range(H):
        for x in range(W):
            if cv[y][x] != ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                v = at(x + dx, y + dy)
                if v != "." and v != "K":
                    out[y][x] = "K"
                    break
    return out


base = [row[:] for row in cv]
frames = []
for fn in (rosto_base, rosto_sneer, rosto_laugh):
    cv = [row[:] for row in base]
    fn()
    # nada pode passar da borda de baixo nem dos lados: corta 1 px para o contorno caber
    m = contorno()
    frames.append(["".join(r) for r in m])

dados = {"_sobre": "Retrato do James Blindado para a caixa de diálogo (Fase 8a1). Gerado por tools/art/retrato_james_8a1.py. 48x48, 3 quadros (smirk, sneer, laugh), virado à direita, fundo transparente. Legenda = nomes da paleta (pixel_lib.gd).",
         "size": [W, H], "faces": ["smirk", "sneer", "laugh"], "legend": LEGEND, "frames": frames}
json.dump(dados, open(os.path.join(AQUI, "retrato_james_8a1.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)


# ------------------------------------------------------------------ prévia (PNG sem dependências)
def pal():
    src = open(os.path.join(AQUI, "pixel_lib.gd"), encoding="utf-8").read()
    import re
    return {k: v for k, v in re.findall(r'"(\w+)": "([0-9a-f]{6})"', src)}


def png(path, rows_rgba, w, h):
    raw = b"".join(b"\x00" + bytes(r) for r in rows_rgba)
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + \
        chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    open(path, "wb").write(data)


if len(sys.argv) > 1:
    P = pal()
    k = 4
    gap = 4
    tw = (W * k + gap) * 3
    th = H * k
    rows = []
    for y in range(th):
        r = []
        for X in range(tw):
            f = X // (W * k + gap)
            xx = X % (W * k + gap)
            if xx >= W * k:
                r += [40, 34, 51, 255]
                continue
            c = frames[f][y // k][xx // k]
            if c == ".":
                r += [61, 51, 70, 255]
            else:
                hx = P[LEGEND[c]]
                r += [int(hx[0:2], 16), int(hx[2:4], 16), int(hx[4:6], 16), 255]
        rows.append(r)
    png(os.path.join(sys.argv[1], "retrato_james_previa_x4.png"), rows, tw, th)
print("ok: retrato_james_8a1.json (%d quadros)" % len(frames))
