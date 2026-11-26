# Ronda 2a1 (Artista de Personagens): poses novas dos BANDIDOS DO BECO -> tools/art/golpes_ronda2a_adv.json.
# As poses são DADOS (quadros-chave no formato do golpes.json / golpes_8a1_adv.json); o rig comum
# (make_sprites_elenco.gd, modo "alley") desenha. Rodar: python tools/art/poses_ronda2a.py (grava só o JSON).
#   daze_flee   os 3 bandidos   "SAIU TONTO E FUGIU" (vitória do vulto por pontos): tonto, de costas para a fuga, ele
#                               recua cambaleando em loop; a tela leva o x para a DIREITA (para longe do vulto). Ninguém
#                               fica no chão, sem sangue: a cabeça balança, o olho é um "x" e os braços caem moles.
# Geometria: espaço do jogador (pivô entre os pés, virado à DIREITA, y negativo para cima), ANTES da escala do corpo.
# No jogo o adversário é espelhado: andar para -x aqui = fugir para a direita da tela.
import json, os, copy

AQUI = os.path.dirname(os.path.abspath(__file__))

BASE = {"hip": [0, -37], "top": [2, -61], "head": [5, -71], "hrot": 0.0, "tw": 0.3,
        "hf": [16, -59], "hb": [12, -61], "pf": [-0.4, 1], "pb": [-0.3, 1], "far_glove_front": False,
        "shoef": "flat", "shoeb": "flat", "toef": [15, -1], "toeb": [-3, -1], "kf": [1, 0.15], "kb": [1, 0.15],
        "face": "normal", "fx": ""}


def P(base=None, **o):
    d = copy.deepcopy(base if base is not None else BASE)
    d.update(o)
    return d


def KP(at, pose, ease="inout", hold=0):
    k = copy.deepcopy(pose)
    k["at"] = at
    k["ease"] = ease
    if hold:
        k["hold"] = hold
    return k


def anim(n, fps, keys, who, ideia, **extra):
    g = {"_ideia": ideia, "who": who, "n": n, "fps": fps, "hit_frame": 0, "keys": keys}
    g.update(extra)
    return g


QUEM = ["opp_alley_tire", "opp_alley_bike", "opp_alley_gate"]
R = {}

# ------------------------------------------------------------------ fuga tonta (6 q, loop, 9 fps)
# Ciclo de passo para TRÁS (o pé de trás recua, o da frente arrasta), o tronco jogado para trás e balançando de um
# lado para o outro, a cabeça mole (giro de -12 a +12 graus), os braços pendurados e a guarda aberta. O quadril sobe
# 1 px na passagem. Peso: o tronco chega antes do pé (cambaleia), e o pé de trás pisa para segurar a queda.
MOLE = P(face="ko", tw=0.1, pf=[0.2, 1], pb=[0.1, 1])
R["daze_flee"] = anim(6, 9.0, [
    KP(0, P(MOLE, hip=[-1, -36], top=[-4, -60], head=[-3, -70], hrot=-12.0, hf=[6, -40], hb=[0, -43],
            toef=[12, -1], toeb=[-7, -1], shoeb="ball", kf=[1, 0.1], kb=[1, 0.3])),
    KP(1, P(MOLE, hip=[-2, -37], top=[-6, -61], head=[-6, -71], hrot=-4.0, hf=[4, -42], hb=[-2, -45],
            toef=[9, -4], shoef="ball", toeb=[-8, -1], kf=[1, -0.2], kb=[1, 0.2])),
    KP(2, P(MOLE, hip=[-3, -36], top=[-4, -60], head=[-2, -70], hrot=8.0, hf=[5, -39], hb=[-1, -42],
            toef=[5, -1], toeb=[-9, -1], kf=[1, 0.2], kb=[1, 0.2])),
    KP(3, P(MOLE, hip=[-2, -36], top=[-3, -60], head=[-1, -70], hrot=12.0, hf=[7, -41], hb=[1, -44],
            toef=[11, -1], toeb=[-6, -3], shoeb="ball", kf=[1, 0.2], kb=[1, -0.2])),
    KP(4, P(MOLE, hip=[-3, -37], top=[-7, -61], head=[-7, -71], hrot=3.0, hf=[3, -43], hb=[-3, -46],
            toef=[8, -1], toeb=[-11, -1], kf=[1, 0.1], kb=[1, 0.3])),
    KP(5, P(MOLE, hip=[-2, -36], top=[-5, -60], head=[-4, -70], hrot=-8.0, hf=[5, -40], hb=[-1, -43],
            toef=[13, -3], shoef="ball", toeb=[-7, -1], kf=[1, -0.2], kb=[1, 0.2])),
], QUEM, "SAIU TONTO E FUGIU (vitória do vulto por pontos): tonto, olho em x, recua cambaleando em loop; a tela leva o x para a direita. Sem sangue, ninguém no chão.", loop=True)

saida = {"_sobre": "Ronda 2a1: poses novas dos bandidos do beco (rig comum; make_golpes_jogador.gd só expande, make_sprites_elenco.gd alley desenha). Gerado por tools/art/poses_ronda2a.py.",
         "moves": {}, "reactions": R}
with open(os.path.join(AQUI, "golpes_ronda2a_adv.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump(saida, f, ensure_ascii=False, indent="\t")
print("ok: golpes_ronda2a_adv.json")
