# Fase 7b1 (Artista de Personagens): autoria das poses do Muay Thai -> tools/art/golpes_7b1.json e golpes_7b1_adv.json.
# As poses são DADOS (quadros-chave no formato do golpes.json); este script só evita digitar o mesmo dicionário 300 vezes.
# Rodar: python tools/art/poses_7b1.py   (grava os dois JSON; não mexe em mais nada)
#   golpes_7b1.json      -> discípulo: guarda tailandesa, chute baixo, joelhada, clinch, chute rodado (luta), Choque do Muay Thai
#                           e o chute baixo no saco comprido (garagem/academia, 3/4)
#   golpes_7b1_adv.json  -> adversários (rig comum): acerto na perna, mancando, preso no clinch, rodado sem cair, queda do rodado
# Geometria (espaço do jogador, pivô entre os pés, y para cima negativo): o adversário fica 50 px à frente (346 - 296).
#   coxa da frente dele ~(+40, -24); barriga ~(+42, -45); queixo ~(+44, -73) (Tonhão: +44, -75, direcao-visual §32).
# Contato que não é luva: chave "hc" no quadro (canela, joelho, sola) + "hit_key": "hc" no golpe.
# Pé esticado: "angb"/"angf" (luta) e "angl"/"angr" (garagem) giram o tênis em graus (negativo = ponta para cima).
import json, os, copy

AQUI = os.path.dirname(os.path.abspath(__file__))

# ------------------------------------------------------------------ LUTA (perfil, 112x104, pivô 56,98, virado à direita)
BASE = {"hip": [0, -37], "top": [2, -61], "head": [5, -71], "hrot": 0.0, "tw": 0.3,
        "hf": [14, -58], "hb": [5, -61], "pf": [-0.4, 1], "pb": [-0.3, 1], "far_glove_front": False,
        "shoef": "flat", "shoeb": "flat", "toef": [15, -1], "toeb": [-3, -1], "kf": [1, 0.15], "kb": [1, 0.15],
        "angf": 0.0, "angb": 0.0, "dx": 0.0, "hc": [0, 0], "legs_swap": False, "face": "normal"}


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


def anim(n, fps, keys, hit=0, ideia="", **extra):
    g = {"_ideia": ideia, "n": n, "fps": fps, "hit_frame": hit, "keys": keys}
    g.update(extra)
    return g


# ---- guarda tailandesa: alta e de frente, peso no pé de trás, pé da frente leve (na ponta), luvas na testa, cotovelos fechados
GUARDA = P(hip=[-1, -38], top=[0, -62], head=[3, -72], tw=0.6, hf=[12, -68], hb=[9, -70], far_glove_front=True,
           pf=[-0.1, 1], pb=[-0.1, 1], toef=[13, -1], shoef="ball", toeb=[-5, -1], kf=[1, 0.1], kb=[1, 0.1])
# respiração/ritmo: o calcanhar da frente sobe e desce, o corpo quica 1 px
G1 = P(GUARDA, toef=[13, -2], kf=[1, -0.1], top=[0, -63], head=[3, -73], hf=[12, -69], hb=[9, -71])
G2 = P(GUARDA, hip=[-1, -37], top=[0, -61], head=[3, -71], hf=[12, -67], hb=[9, -69])

# ---- CHUTE BAIXO (perna de trás na coxa da frente dele)
LK_PASSO = P(GUARDA, hip=[3, -37], top=[3, -61], head=[6, -71], tw=0.2, toef=[20, -1], shoef="flat", shoeb="ball",
             toeb=[-3, -1], hf=[19, -65], hb=[6, -62])
LK_ARMA = P(LK_PASSO, hip=[8, -38], top=[5, -62], head=[8, -72], tw=-0.4, shoef="ball", toeb=[10, -16], shoeb="flat",
            angb=40.0, kb=[1, -0.4], hf=[23, -64], hb=[2, -52], pb=[0.4, 1], legs_swap=True)
LK_CONTATO = P(LK_ARMA, hip=[13, -37], top=[7, -61], head=[9, -71], tw=-0.8, toeb=[51, -21], angb=-10.0, kb=[1, 0.3],
               hf=[25, -62], hb=[1, -48], hc=[37, -24], face="normal")
LK_PASSA = P(LK_CONTATO, hip=[12, -37], top=[6, -61], head=[8, -71], toeb=[49, -15], angb=0.0, hb=[1, -49])
LK_VOLTA = P(LK_ARMA, hip=[6, -38], top=[4, -62], head=[7, -72], toeb=[8, -14], angb=50.0, hb=[4, -58], hf=[16, -66])
LK_POUSA = P(GUARDA, hip=[1, -37], top=[1, -61], head=[4, -71], toef=[17, -1], shoef="flat", toeb=[-4, -1])

# ---- JOELHADA (joelho de trás na barriga dele, com passo e as mãos nos ombros dele)
KN_ARMA = P(GUARDA, hip=[-2, -37], top=[1, -61], head=[4, -71], tw=0.6, hf=[22, -66], hb=[19, -67], far_glove_front=False,
            shoeb="ball", toeb=[-3, -1], pf=[-0.2, 1], pb=[-0.2, 1])
KN_SOBE = P(KN_ARMA, dx=6.0, hip=[4, -38], top=[3, -62], head=[6, -72], toeb=[10, -16], shoeb="flat", angb=60.0,
            kb=[1, -0.5], hf=[26, -64], hb=[23, -64], shoef="ball", toef=[13, -1], legs_swap=True)
KN_CONTATO = P(KN_SOBE, dx=13.0, hip=[7, -39], top=[3, -62], head=[6, -72], tw=0.2, toeb=[17, -24], angb=75.0,
               kb=[1, -0.6], hf=[28, -60], hb=[25, -61], toef=[12, -3], hc=[23, -45], face="normal")
KN_SEGURA = P(KN_CONTATO, hip=[7, -39], toeb=[17, -23], hf=[28, -59], hb=[25, -60])
KN_DESCE = P(KN_SOBE, dx=8.0, toeb=[6, -6], angb=20.0, toef=[13, -1], hf=[22, -64], hb=[19, -65])
KN_POUSA = P(GUARDA, dx=3.0, hip=[-1, -37], top=[0, -61], head=[3, -71], toeb=[-4, -1], shoeb="ball")

# ---- CLINCH TAILANDÊS (as duas mãos atrás da cabeça dele, puxa para baixo, joelho no peito)
CL_ESTICA = P(GUARDA, dx=4.0, hip=[2, -37], top=[7, -61], head=[10, -71], tw=0.9, hf=[30, -68], hb=[28, -69],
              far_glove_front=False, shoeb="ball", toeb=[-3, -1], pf=[-0.2, -1], pb=[-0.2, -1])
CL_PEGA = P(CL_ESTICA, dx=8.0, hip=[4, -37], top=[11, -60], head=[14, -70], tw=1.2, hf=[34, -66], hb=[32, -68])
CL_PUXA = P(CL_PEGA, dx=9.0, hip=[3, -38], top=[8, -61], head=[11, -71], tw=1.0, hf=[27, -58], hb=[25, -60],
            pf=[0, -1], pb=[0, -1])
CL_ARMA = P(CL_PUXA, toeb=[8, -14], shoeb="flat", angb=55.0, kb=[1, -0.5], shoef="ball", toef=[14, -1], legs_swap=True)
CL_JOELHO = P(CL_ARMA, dx=10.0, hip=[5, -39], top=[8, -62], head=[11, -72], toeb=[15, -28], angb=80.0, kb=[1, -0.8],
              hf=[25, -55], hb=[23, -57], hc=[22, -49])
CL_SEGURA = P(CL_JOELHO, toeb=[15, -27], hf=[25, -56], hb=[23, -58])
CL_DESCE = P(CL_PUXA, dx=9.0, toeb=[4, -4], angb=20.0, shoeb="ball", legs_swap=True)
CL_SOLTA = P(GUARDA, dx=4.0, hip=[0, -37], top=[3, -61], head=[6, -71], hf=[22, -62], hb=[19, -64], far_glove_front=False,
             toeb=[-5, -1])

# ---- CHUTE RODADO (perna de trás alta no rosto, com passo de ~12 px dentro do quadro; o pé de apoio planta e gira)
SK_PASSO = P(GUARDA, hip=[3, -37], top=[4, -61], head=[7, -71], tw=0.3, toef=[25, -1], shoef="flat", shoeb="ball",
             toeb=[-2, -1], hf=[17, -66], hb=[10, -66])
SK_ARMA = P(GUARDA, dx=8.0, hip=[4, -39], top=[1, -62], head=[4, -72], tw=-0.5, toef=[17, -1], shoef="ball",
            toeb=[10, -26], shoeb="flat", angb=20.0, kb=[1, -1], hf=[12, -68], hb=[-2, -50], pb=[0.5, 1],
            far_glove_front=False, legs_swap=True)
SK_SOBE = P(SK_ARMA, dx=11.0, hip=[7, -40], top=[0, -62], head=[3, -72], tw=-0.9, toef=[14, -1], toeb=[33, -56],
            angb=-60.0, kb=[1, -0.3], hb=[-8, -44])
SK_CONTATO = P(SK_SOBE, dx=12.0, hip=[8, -40], top=[-1, -62], head=[2, -72], hrot=-8.0, tw=-1.2, toef=[13, -1],
               toeb=[32, -74], angb=-85.0, kb=[1, 0.2], hf=[8, -68], hb=[-11, -42], hc=[31, -72])
SK_PASSA = P(SK_CONTATO, dx=12.0, hip=[8, -40], top=[0, -62], head=[3, -72], hrot=-4.0, tw=-1.6, toeb=[33, -52],
             angb=-30.0, kb=[1, 0.6], hb=[-9, -46])
SK_GIRA = P(SK_PASSA, dx=12.0, hip=[7, -38], top=[4, -61], head=[7, -71], hrot=0.0, tw=-1.4, toeb=[22, -12],
            angb=30.0, kb=[1, 0.3], hf=[10, -67], hb=[2, -60], face="normal")
SK_POUSA = P(GUARDA, dx=10.0, hip=[4, -37], top=[5, -61], head=[8, -71], tw=-0.6, toef=[15, -1], shoef="flat",
             toeb=[12, -1], shoeb="ball", hf=[13, -67], hb=[10, -68])
SK_RECUA = P(GUARDA, dx=5.0, toeb=[-2, -1], shoeb="ball")

moves = {
    "mt_idle": anim(4, 5.0, [KP(0, GUARDA), KP(1, G1), KP(2, GUARDA), KP(3, G2)], 0,
                    "Guarda tailandesa (idle da luta com Muay Thai): de pé e de frente, luvas na altura da testa, cotovelos "
                    "fechados, peso atrás e o pé da frente leve na ponta; no ritmo, o calcanhar da frente sobe e desce."),
    "low_kick": anim(9, 16.0, [
        KP(0, GUARDA),
        KP(1, LK_PASSO, "out"),
        KP(2, LK_ARMA, "inout"),
        KP(4, LK_CONTATO, "in", hold=1),
        KP(5, LK_PASSA, "out"),
        KP(6, LK_VOLTA, "inout"),
        KP(7, LK_POUSA, "inout"),
        KP(8, GUARDA, "inout"),
    ], 4, "Chute baixo (perna de trás na coxa da frente dele): 0 guarda, 1 passo do pé da frente para fora, 2 gira o quadril e "
          "o joelho de trás sobe, 3 a perna varre, 4 CONTATO da canela na coxa (segura 1 quadro; braço de trás desce para "
          "girar), 6 o joelho volta, 7 pousa, 8 guarda.", hit_key="hc",
         lag={"toeb": 0.25, "angb": 0.25, "hb": 0.15, "top": 0.05}),
    "knee": anim(9, 14.0, [
        KP(0, GUARDA),
        KP(1, KN_ARMA, "out"),
        KP(2, KN_SOBE, "inout"),
        KP(3, KN_CONTATO, "in", hold=1),
        KP(4, KN_SEGURA, "out"),
        KP(5, KN_DESCE, "inout"),
        KP(6, KN_POUSA, "inout"),
        KP(7, GUARDA, "inout"),
    ], 3, "Joelhada (joelho de trás na barriga dele): 0 guarda, 1 as mãos vão aos ombros dele, 2 passo para dentro e o joelho "
          "sobe, 3 CONTATO (quadril para a frente, tronco para trás, na ponta do pé de apoio; segura), 5 o joelho desce, "
          "6-8 volta à guarda.", hit_key="hc", lag={"toeb": 0.2, "angb": 0.2}),
    "thai_clinch": anim(10, 12.0, [
        KP(0, GUARDA),
        KP(1, CL_ESTICA, "out"),
        KP(2, CL_PEGA, "in"),
        KP(3, CL_PUXA, "inout"),
        KP(4, CL_ARMA, "inout"),
        KP(5, CL_JOELHO, "in"),
        KP(6, CL_SEGURA, "out"),
        KP(7, CL_DESCE, "inout"),
        KP(8, CL_SOLTA, "inout"),
        KP(9, GUARDA, "inout"),
    ], 2, "Clinch tailandês (dois corpos): 0 guarda, 1 entra e estica as mãos, 2 PEGA atrás da cabeça dele (hit: a reação "
          "held_clinch começa aqui), 3 puxa a cabeça para baixo, 4 arma o joelho, 5 JOELHO no peito dele, 6 segura, 7 desce, "
          "8 solta e recua, 9 guarda.", hit_key="hf_hit"),
    "spin_kick": anim(11, 14.0, [
        KP(0, GUARDA),
        KP(1, SK_PASSO, "out"),
        KP(2, SK_ARMA, "inout"),
        KP(3, SK_SOBE, "in"),
        KP(4, SK_CONTATO, "in", hold=2),
        KP(5, SK_PASSA, "out"),
        KP(6, SK_GIRA, "inout"),
        KP(7, SK_POUSA, "inout"),
        KP(9, SK_RECUA, "inout"),
        KP(10, GUARDA, "inout"),
    ], 4, "Chute rodado (perna de trás no rosto, direcao-visual §32): 0 guarda, 1 o pé da frente dá um passo de 10 px, 2 o "
          "corpo vai junto (dx), o pé de apoio planta e gira e o joelho de trás sobe, 3 a perna sobe esticada, 4 CONTATO do "
          "peito do pé no queixo (tronco jogado para trás, braço de trás varre para baixo; segura 2 quadros), 5 passa do alvo, "
          "6 o corpo termina o giro e a perna desce cruzada, 7 pousa na frente, 8-9 recua o passo, 10 guarda.", hit_key="hc",
         lag={"toeb": 0.2, "angb": 0.2, "hb": 0.1}),
    # ---- Choque do Muay Thai (parceiro = o do Boxe, a 50 px; peito dele ~ +36)
    "spar_mt_push": anim(6, 16.0, [
        KP(0, GUARDA),
        KP(1, P(GUARDA, hip=[-2, -37], top=[-1, -61], head=[2, -71], hf=[16, -62], hb=[13, -63], far_glove_front=False), "out"),
        KP(2, P(GUARDA, hip=[4, -37], top=[11, -60], head=[14, -70], tw=1.3, hf=[35, -57], hb=[32, -59], far_glove_front=False,
                pf=[-0.3, 1], pb=[-0.3, 1], shoeb="ball", toeb=[-1, -1], shoef="flat", toef=[17, -1]), "in"),
        KP(3, P(GUARDA, hip=[4, -37], top=[11, -60], head=[14, -70], tw=1.3, hf=[36, -57], hb=[33, -59], far_glove_front=False,
                pf=[-0.3, 1], pb=[-0.3, 1], shoeb="ball", toeb=[-1, -1], shoef="flat", toef=[17, -1]), "out"),
        KP(5, GUARDA),
    ], 2, "Choque Muay Thai, clique fora do tempo: empurrão curto com as duas mãos no peito dele. Reação: spar_partner_box_recoil.",
         hit_key="hf"),
    "spar_mt_kick": anim(7, 16.0, [
        KP(0, GUARDA),
        KP(1, P(GUARDA, hip=[-2, -38], top=[-3, -62], head=[0, -72], toef=[12, -14], shoef="flat", angf=60.0, kf=[1, -0.6]), "out"),
        KP(3, P(GUARDA, hip=[3, -39], top=[-3, -62], head=[0, -72], tw=0.2, toef=[37, -47], shoef="up", angf=0.0,
                kf=[1, -0.3], toeb=[-4, -1], hf=[10, -67], hb=[6, -68], hc=[35, -42]), "in", hold=1),
        KP(4, P(GUARDA, hip=[2, -39], top=[-3, -62], head=[0, -72], tw=0.2, toef=[34, -46], shoef="up", angf=0.0,
                kf=[1, -0.3], toeb=[-4, -1], hf=[10, -67], hb=[6, -68], hc=[33, -42]), "out"),
        KP(5, P(GUARDA, hip=[-1, -38], top=[-2, -62], head=[1, -72], toef=[14, -12], shoef="flat", angf=50.0, kf=[1, -0.6]), "inout"),
        KP(6, GUARDA),
    ], 3, "Choque Muay Thai, 3º clique no tempo = CHUTE: teep (chute de empurrar com a sola do pé da frente na barriga dele), "
          "tronco para trás. Reação: spar_partner_box_recoil (empurra muito mais).", hit_key="hc", lag={"toef": 0.2}),
}
reactions = {
    "spar_mt_guard": anim(2, 4.0, [
        KP(0, P(GUARDA, hip=[-2, -38], top=[-1, -62], head=[2, -71], hf=[11, -67], hb=[8, -69], toef=[11, -18], shoef="flat",
                angf=70.0, kf=[1, -0.9])),
        KP(1, P(GUARDA, hip=[-2, -37], top=[-1, -61], head=[2, -70], hf=[11, -66], hb=[8, -68], toef=[11, -17], shoef="flat",
                angf=70.0, kf=[1, -0.9])),
    ], 0, "Choque Muay Thai, segurando: guarda fechada com a canela levantada (bloqueio de canela), loop.", loop=True),
}
# mt_idle é parada em loop: vai como reação (sem contato), igual ao ground_top_idle da 7a1
reactions["mt_idle"] = moves.pop("mt_idle")
reactions["mt_idle"]["loop"] = True

# ------------------------------------------------------------------ TREINO (saco comprido, 3/4, quadro 64x72, pivô 22,67)
# Contato da canela no saco em (326,250) = pivô do lutador (303,272) + (23,-22). Chuta com a perna da esquerda da tela (a de
# trás) depois de um passo curto do corpo (dx). O pé passa na frente do saco (o lutador é desenhado na frente).
GB = {"hip": [0, -31], "top": [1, -50], "head": [1, -57], "sl": [-7, -47], "sr": [8, -47],
      "hl": [-8, -50], "hr": [10, -51], "toel": [-1, 0], "toer": [10, 0]}


def GP(**o):
    d = copy.deepcopy(GB)
    d.update(o)
    return d


garage = {
    "low_kick": {
        "_ideia": "Chute baixo no saco comprido (6 quadros, tocado inteiro a cada clique): 0 guarda, 1 passo e o joelho de trás "
                  "sobe, 2 CONTATO da canela no saco (326,250), 3 segura, 4 o joelho volta, 5 guarda. Quadro 64x72 (o pé passa "
                  "dos 48 px); pivô (22,67) igual ao fighter_punch.",
        "fps": 18.0, "hit_frame": 2, "hit_hand": "hc", "pivot": [22, 67], "foco_saco": [303, 272], "frame_size": [64, 72],
        "frames": [
            GP(hc=[0, 0]),
            GP(dx=2, hip=[2, -32], top=[1, -51], head=[1, -58], sl=[-6, -48], sr=[9, -48], hl=[-4, -51], hr=[12, -52],
               toer=[13, 0], toel=[6, -12], angl=40, kl=[0.6, -0.4], hc=[0, 0]),
            GP(dx=4, hip=[4, -32], top=[0, -51], head=[0, -58], sl=[-7, -48], sr=[7, -48], hl=[-9, -42], hr=[11, -53],
               toer=[11, 0], shoer="34ball", toel=[30, -16], angl=0, kl=[0.6, -0.5], tw=-0.6, hc=[19, -22]),
            GP(dx=4, hip=[4, -32], top=[0, -51], head=[0, -58], sl=[-7, -48], sr=[7, -48], hl=[-9, -43], hr=[11, -53],
               toer=[11, 0], shoer="34ball", toel=[29, -14], angl=10, kl=[0.6, -0.5], tw=-0.6, hc=[19, -21]),
            GP(dx=2, hip=[2, -32], top=[1, -51], head=[1, -58], sl=[-6, -48], sr=[9, -48], hl=[-5, -50], hr=[12, -52],
               toer=[13, 0], toel=[7, -10], angl=40, kl=[0.6, -0.4], hc=[0, 0]),
            GP(hc=[0, 0]),
        ],
    },
}

# ------------------------------------------------------------------ ADVERSÁRIOS (desenhados virados à direita; o gerador espelha)
# Mesma pose-base do rig comum (make_sprites_elenco.gd fpose + personalidade). A perna da FRENTE dele é a "f" (toef).
AB = {"hip": [0, -37], "top": [2.0, -61.0], "tw": 0.3, "hf": [14.0, -58.0], "hb": [5.0, -60.9], "far_glove_front": False,
      "shoeb": "flat", "shoef": "flat", "face": "normal", "pf": [-0.4, 1], "pb": [-0.3, 1], "hrot": 0.0,
      "toef": [15, -1], "toeb": [-3, -1], "kf": [1, 0.15], "kb": [1, 0.15], "angf": 0.0, "angb": 0.0}


def A(base=None, **o):
    d = copy.deepcopy(base if base is not None else AB)
    d.update(o)
    return d


# acerto na perna: a perna da frente dobra para dentro e o pé sai do chão, o quadril cai daquele lado, o tronco desaba para a frente
HL_DOBRA = A(hip=[-2, -33], top=[3, -57], head=[6, -67], hrot=10.0, toef=[10, -4], shoef="ball", kf=[1, 0.6],
             hf=[11, -50], hb=[3, -52], face="pain", pf=[0.2, 1], pb=[0.2, 1])
HL_FUNDO = A(HL_DOBRA, hip=[-3, -31], top=[3, -55], head=[6, -65], hrot=14.0, toef=[9, -2], hf=[10, -44], hb=[2, -48])
# mancando: o peso todo no pé de trás, a perna da frente dobrada e só a ponta no chão, guarda mais baixa
LIMP = A(hip=[-3, -35], top=[-1, -59], head=[2, -69], hrot=6.0, tw=0.1, toef=[10, -3], shoef="ball", kf=[1, 0.6],
         toeb=[-5, -1], hf=[12, -47], hb=[3, -55], face="tired", pf=[-0.2, 1], pb=[-0.2, 1])
LIMP_B = A(LIMP, hip=[-3, -34], top=[-1, -58], head=[2, -68], toef=[11, -1], hf=[12, -46], hb=[3, -54], face="pain")
# com 3 marcas: a mão da frente segura a coxa machucada, o pé da frente sai do chão, o tronco curva sobre a perna
LIMP2 = A(LIMP, hip=[-4, -34], top=[3, -57], head=[7, -66], hrot=14.0, toef=[8, -5], kf=[1, 0.9], hf=[8, -29], hb=[4, -51],
          pf=[0.4, 1], face="pain")
LIMP2_B = A(LIMP2, hip=[-4, -33], top=[3, -56], head=[7, -65], toef=[9, -3], hf=[8, -28], hb=[4, -50])
# preso no clinch: a cabeça vai para baixo e para a frente (para o peito do jogador), as mãos empurram os braços dele
HC_PEGO = A(hip=[0, -37], top=[4, -60], head=[8, -70], face="pain", hf=[14, -56], hb=[10, -58])
HC_PUXADO = A(hip=[-1, -36], top=[9, -55], head=[16, -61], hrot=30.0, face="pain", hf=[15, -50], hb=[13, -52],
              pf=[0.2, 1], pb=[0.2, 1], shoeb="ball", toeb=[-2, -1])
HC_BAIXO = A(HC_PUXADO, hip=[-1, -35], top=[10, -53], head=[17, -58], hrot=38.0, hf=[15, -47], hb=[13, -49])
HC_JOELHO = A(HC_BAIXO, hip=[-3, -36], top=[8, -56], head=[14, -63], hrot=20.0, hf=[11, -45], hb=[8, -47], face="ko")
HC_SOLTO = A(hip=[-2, -36], top=[2, -59], head=[6, -68], hrot=12.0, face="pain", hf=[11, -52], hb=[4, -55])
# rodado no rosto: a cabeça vira para trás, o corpo torce e os braços abrem
SP_ACERTA = A(hip=[-2, -37], top=[-5, -60], head=[-3, -71], hrot=-35.0, tw=-1.0, face="ko", hf=[4, -65], hb=[-6, -62],
              pf=[-0.4, -1], pb=[-0.4, -1], toef=[15, -1], shoef="ball", toeb=[-4, -1])
SP_TORCE = A(SP_ACERTA, hip=[-4, -35], top=[-10, -57], head=[-9, -67], hrot=-50.0, tw=-1.5, hf=[-2, -62], hb=[-14, -56],
             kf=[1, 0.6], kb=[1, 0.6], toef=[13, -2], toeb=[-6, -1])

adv = {
    "hit_leg": anim(7, 14.0, [
        KP(0, AB),
        KP(1, HL_DOBRA, "in"),
        KP(2, HL_FUNDO, "out"),
        KP(3, HL_FUNDO, "inout"),
        KP(5, A(LIMP, face="pain"), "inout"),
        KP(6, AB, "inout"),
    ], 0, "Levou o chute baixo na coxa da frente: o joelho da frente dobra e o pé sai do chão, o quadril cai, o tronco "
          "desaba para a frente e a guarda desce; depois apoia o pé de volta.", lag={"hf": 0.12, "hb": 0.12, "hrot": 0.1}),
    "limp": anim(4, 4.0, [KP(0, LIMP), KP(1, LIMP), KP(2, LIMP_B), KP(3, LIMP_B)], 0,
                 "Mancando (idle com 2 marcas): o peso todo no pé de trás, a perna da frente dobrada e só a ponta no chão; "
                 "a cada passo do ritmo ele testa a perna e faz careta.", loop=True),
    "limp_heavy": anim(4, 4.0, [KP(0, LIMP2), KP(1, LIMP2), KP(2, LIMP2_B), KP(3, LIMP2_B)], 0,
                       "Mancando mais torto (idle com 3 marcas): o pé da frente quase não encosta, o tronco cai para trás.",
                       loop=True),
    "held_clinch": anim(9, 12.0, [
        KP(0, HC_PEGO),
        KP(1, HC_PUXADO, "out"),
        KP(2, HC_BAIXO, "inout"),
        KP(3, HC_JOELHO, "in"),
        KP(4, HC_JOELHO, "out"),
        KP(5, HC_BAIXO, "inout"),
        KP(6, HC_SOLTO, "out"),
        KP(8, AB, "inout"),
    ], 0, "Preso no clinch (começa no hit_frame 2 do thai_clinch e termina junto): 0 pego pela nuca, 1-2 puxado para baixo e "
          "para a frente, 3 o joelho acerta (cabeça sobe), 5 puxado de novo, 6 solto, 8 guarda.", lag={"hf": 0.1, "hb": 0.1}),
    "hit_spin": anim(8, 12.0, [
        KP(0, SP_ACERTA, "in"),
        KP(1, SP_TORCE, "out"),
        KP(3, SP_TORCE, "inout"),
        KP(5, A(LIMP, face="pain"), "inout"),
        KP(7, AB, "inout"),
    ], 0, "Levou o chute rodado e NÃO caiu: a cabeça vira para trás, o corpo torce, os joelhos tremem e ele volta à guarda "
          "mancando."),
}
# queda do rodado: a cabeça vira, os joelhos cedem primeiro, depois o tronco, e termina de lado no chão (deitado igual ao ko_back)
FALL_CHAO = A(hip=[-7, -7], top=[-31, -7], tw=0.3, hf=[-16.0, -10.5], hb=[-44.0, -6.0], shoeb="flat", shoef="flat", face="ko",
              hrot=-90.0, head=[-41, -8], toef=[23, -1], toeb=[29, -1], kf=[0, -1], kb=[0, -1], lying=True)
adv["fall_spin"] = anim(10, 12.0, [
    KP(0, SP_ACERTA, "in"),
    KP(1, SP_TORCE, "out"),
    KP(2, A(SP_TORCE, hip=[-4, -28], top=[-9, -51], head=[-8, -61], hrot=-55.0, toef=[12, -1], toeb=[-7, -1], kf=[1, 1],
            kb=[1, 1], shoef="flat", hf=[0, -48], hb=[-12, -44]), "in"),
    KP(3, A(SP_TORCE, hip=[-5, -18], top=[-14, -40], head=[-15, -50], hrot=-60.0, toef=[10, -1], toeb=[-8, -1], kf=[1, 0.4],
            kb=[1, 0.4], shoef="ball", shoeb="ball", hf=[-6, -33], hb=[-18, -30], lying=True), "in"),
    KP(4, A(SP_TORCE, hip=[-6, -11], top=[-24, -22], head=[-29, -28], hrot=-75.0, toef=[14, -2], toeb=[4, -3], kf=[0.5, -1],
            kb=[0.5, -1], shoef="ball", shoeb="ball", hf=[-14, -16], hb=[-32, -12], lying=True), "in"),
    KP(5, FALL_CHAO, "in"),
    KP(6, A(FALL_CHAO, hip=[-7, -9], top=[-31, -9], head=[-41, -10], toef=[23, -4], toeb=[29, -5], hf=[-16, -13], hb=[-44, -8]), "out"),
    KP(7, FALL_CHAO, "in"),
    KP(9, A(FALL_CHAO, shoeb="up", toef=[25, -1], toeb=[30, -12]), "inout"),
], 0, "Queda pelo chute rodado (K.O.): a cabeça vira com o chute, o corpo torce, os joelhos cedem primeiro, depois o tronco, e "
      "ele cai de costas, quica e fica (segurar o último quadro, como o ko). Chão no quadro 5.", ground_frame=5)

# tirar as chaves que o rig do adversário não usa (hc, dx) e manter o resto
for g in adv.values():
    for k in g["keys"]:
        k.pop("hc", None)

# quadro de contato do clinch = mão da frente na nuca dele
moves["thai_clinch"]["hit_key"] = "hf"

out = {"_sobre": "Fase 7b1 (Muay Thai). Gerado por tools/art/poses_7b1.py; mesmo formato do golpes.json (ver _sobre lá). "
                 "hc = ponto de contato que não é luva (hit_key); angf/angb/angl/angr giram o pé; dx = o corpo todo desliza.",
       "moves": moves, "reactions": reactions, "garage": garage}
json.dump(out, open(os.path.join(AQUI, "golpes_7b1.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
json.dump({"_sobre": "Fase 7b1: reações dos adversários (rig comum; make_golpes_jogador.gd só expande, make_sprites_elenco.gd "
                     "reacoes desenha). Gerado por tools/art/poses_7b1.py.", "moves": {}, "reactions": adv},
          open(os.path.join(AQUI, "golpes_7b1_adv.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("ok: golpes_7b1.json (%d golpes, %d paradas, %d treino) e golpes_7b1_adv.json (%d reações)" % (
    len(moves), len(reactions), len(garage), len(adv)))
