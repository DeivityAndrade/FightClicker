# Fase 7a2 (Artista de Personagens): autoria das poses do "Treino fora de hora" -> tools/art/golpes_7a2.json.
# As poses são DADOS (quadros-chave no formato do golpes.json); este script só evita digitar o mesmo dicionário 200 vezes.
# Rodar: python tools/art/poses_7a2.py   (grava tools/art/golpes_7a2.json; não mexe em mais nada)
# Seções do JSON:
#   moves / reactions  -> discípulo no Choque (make_golpes_jogador.gd com FC_LUTADOR=disc FC_CAMADAS=1 FC_GOLPES=...)
#   garage             -> discípulo entregando panfleto (3/4, mesmo gerador; chave "prop" = maço/panfleto na mão)
#   parceiro           -> parceiro de treino (make_sprites_fase7a2.gd; usa também moves/reactions com o corpo dele)
#   pedestres          -> passantes da Panfletagem (make_sprites_fase7a2.gd; escala da sala, quadro 48x72)
import json, os, copy

AQUI = os.path.dirname(os.path.abspath(__file__))

# ------------------------------------------------------------------ LUTA (perfil, 112x104, pivô 56,98, virado à direita)
BASE = {"hip": [0, -37], "top": [2, -61], "head": [5, -71], "hrot": 0.0, "tw": 0.3,
        "hf": [14, -58], "hb": [5, -61], "pf": [-0.4, 1], "pb": [-0.3, 1], "far_glove_front": False,
        "shoef": "flat", "shoeb": "flat", "toef": [15, -1], "toeb": [-3, -1], "kf": [1, 0.15], "kb": [1, 0.15],
        "face": "normal"}


def K(at, ease="inout", **o):
    k = copy.deepcopy(BASE)
    k.update(o)
    k["at"] = at
    k["ease"] = ease
    return k


def G(base, **o):
    d = copy.deepcopy(base)
    d.update(o)
    return d


def anim(n, fps, keys, hit=0, ideia="", **extra):
    g = {"_ideia": ideia, "n": n, "fps": fps, "hit_frame": hit, "keys": keys}
    g.update(extra)
    return g


# ---- poses de referência (sem at/ease)
def P(**o):
    d = copy.deepcopy(BASE)
    d.update(o)
    return d


GUARDA = P()
# Boxe
GUARDA_ALTA = P(hip=[-1, -37], top=[0, -61], head=[3, -69], hf=[12, -65], hb=[10, -66], far_glove_front=True,
                pf=[-0.2, 1], pb=[-0.2, 1], tw=0.2)
AVISO = P(hip=[-3, -37], top=[-4, -61], head=[-1, -70], tw=-1.2, hf=[11, -60], hb=[-6, -57], toeb=[-5, -1])
FINTA_BAIXA = P(hip=[1, -36], top=[5, -58], head=[8, -67], tw=0.6, hf=[17, -56], hb=[9, -58], shoeb="ball", toeb=[-2, -1])
PAUSA = P(hip=[0, -36], top=[2, -60], head=[5, -69], hf=[13, -47], hb=[5, -48], face="tired", pf=[-0.6, 0.4], pb=[-0.6, 0.4])
# Jiu-jitsu: as mãos na gola/manga dele (os dois a 50 px; o peito dele fica ~38 px à frente do meu pivô)
PEGADA = P(hip=[2, -35], top=[10, -58], head=[13, -67], tw=0.8, hf=[35, -61], hb=[32, -50], pf=[-0.2, 1], pb=[0.1, 1],
           toef=[17, -1], toeb=[-6, -1], kf=[1, 0.25], kb=[1, 0.25])
PUXA = G(PEGADA, hip=[-1, -35], top=[5, -59], head=[8, -69], tw=0.4, hf=[32, -60], hb=[30, -50], toeb=[-7, -1])
PUXA2 = G(PUXA, hip=[-2, -34], top=[3, -58], head=[6, -68], hf=[31, -60], hb=[29, -49])
SOLTO = G(PEGADA, hip=[1, -36], top=[7, -59], head=[10, -69], tw=0.5, hf=[21, -52], hb=[15, -53], pf=[-0.5, 0.8], pb=[-0.5, 0.8],
          face="tired")
AVISO_JJ = G(PEGADA, hip=[0, -33], top=[7, -56], head=[10, -66], hf=[34, -60], hb=[31, -49], toeb=[-8, -1], shoeb="ball",
             kf=[1, 0.4], kb=[1, 0.4])
PUXADA = G(PEGADA, hip=[-4, -35], top=[-1, -59], head=[2, -69], tw=0.2, hf=[25, -58], hb=[22, -49], toeb=[-10, -1])
PUXADO = G(PEGADA, hip=[5, -35], top=[15, -57], head=[18, -66], hf=[39, -60], hb=[36, -50], shoeb="ball", toeb=[-2, -1],
           face="pain")
PUXADO2 = G(PUXADO, hip=[7, -35], top=[17, -57], head=[20, -66], toef=[22, -1], hf=[40, -60], hb=[37, -50])
PAUSA_JJ = G(PEGADA, hip=[1, -36], top=[8, -59], head=[11, -69], hf=[34, -60], hb=[16, -47], pb=[-0.6, 0.5], face="tired")
FINTA_JJ = G(PEGADA, hip=[1, -36], top=[9, -58], head=[12, -68], hf=[33, -60], hb=[29, -51])


def KP(at, pose, ease="inout"):
    k = copy.deepcopy(pose)
    k["at"] = at
    k["ease"] = ease
    return k


def respira(pose, n=4, dy=1):
    """Respiração: ombros/cabeça sobem 1 px (nunca o corpo todo)."""
    up = G(pose, top=[pose["top"][0], pose["top"][1] - dy], head=[pose["head"][0], pose["head"][1] - dy],
           hf=[pose["hf"][0], pose["hf"][1] - dy], hb=[pose["hb"][0], pose["hb"][1] - dy])
    return [KP(0, pose), KP(1, up), KP(2, up), KP(3, pose)][:n]


moves = {
    "spar_box_push": anim(6, 16.0, [
        KP(0, GUARDA),
        KP(1, G(GUARDA, hip=[-1, -36], top=[1, -61], head=[4, -71], hf=[12, -59], tw=0.2), "out"),
        KP(2, G(GUARDA, hip=[3, -37], top=[9, -61], head=[11, -70], tw=1.2, hf=[34, -60], hb=[10, -62], shoeb="ball", toeb=[0, -1]), "in"),
        KP(3, G(GUARDA, hip=[3, -37], top=[9, -61], head=[11, -70], tw=1.2, hf=[35, -60], hb=[10, -62], shoeb="ball", toeb=[0, -1]), "out"),
        KP(5, GUARDA)], hit=2, lag={"hf": 0.3, "head": 0.15},
        ideia="Choque Boxe, 1 clique: jab curto que empurra (antecipação de 1 quadro, contato no 2, volta à guarda)."),
    "spar_box_counter": anim(7, 16.0, [
        KP(0, G(GUARDA, sb=[-0.2, -59.2], sf=[3.7, -57.8])),
        KP(1, G(GUARDA, hip=[-1, -36], top=[0, -60], head=[3, -70], tw=-0.3, sb=[-2.0, -58.5], sf=[1.8, -57.0]), "out"),
        KP(3, G(GUARDA, hip=[3, -37], top=[9, -60], head=[11, -69], tw=2.0, hb=[35, -60], hf=[12, -60], shoeb="ball",
                toeb=[1, -1], far_glove_front=True, sb=[12, -59], sf=[7, -57]), "in"),
        KP(4, G(GUARDA, hip=[3, -37], top=[9, -60], head=[11, -69], tw=2.0, hb=[36, -60], hf=[12, -60], shoeb="ball",
                toeb=[1, -1], far_glove_front=True, sb=[12, -59], sf=[7, -57]), "out"),
        KP(6, G(GUARDA, sb=[-0.2, -59.2], sf=[3.7, -57.8]))], hit=3, hit_hand="hb", hit_point=[35.0, -60.0], lag={"hb": 0.3, "head": 0.15},
        ideia="Choque Boxe, contragolpe na pausa (x2): direto de trás com o quadril inteiro girando."),
}

reactions = {
    "spar_box_idle": anim(4, 6.0, respira(GUARDA), loop=True, ideia="Choque Boxe parado (guarda, respiração)."),
    "spar_box_guard": anim(2, 4.0, [KP(0, GUARDA_ALTA), KP(1, G(GUARDA_ALTA, top=[0, -62], head=[3, -70], hf=[12, -66], hb=[10, -67]))],
                           loop=True, ideia="Choque Boxe, segurando = guarda fechada (luvas na frente do rosto, cotovelos colados)."),
    "spar_box_recoil": anim(6, 14.0, [
        KP(0, GUARDA),
        KP(1, G(GUARDA, hip=[-3, -36], top=[-6, -60], head=[-4, -69], hf=[10, -60], hb=[2, -62], face="pain"), "out"),
        KP(2, G(GUARDA, hip=[-5, -36], top=[-7, -60], head=[-5, -70], hf=[9, -60], hb=[1, -62], toeb=[-7, -1], shoeb="ball", face="pain")),
        KP(3, G(GUARDA, hip=[-4, -36], top=[-5, -60], head=[-3, -70], hf=[10, -60], hb=[2, -62], toeb=[-7, -1], face="pain")),
        KP(5, G(GUARDA, toeb=[-5, -1]))], ideia="Empurrado para trás (encostaram em você): recua meio passo e volta."),
    "spar_jj_take": anim(4, 12.0, [KP(0, GUARDA), KP(3, PEGADA, "out")],
                         ideia="Choque JJ: da guarda à pegada (gola + manga). Tocar AO CONTRÁRIO = soltar."),
    "spar_jj_grip": anim(4, 5.0, [KP(0, PEGADA), KP(1, G(PEGADA, top=[10, -59], head=[13, -68])),
                                  KP(2, G(PEGADA, top=[10, -59], head=[13, -68])), KP(3, PEGADA)],
                         loop=True, ideia="Choque JJ parado com a pegada (respira)."),
    "spar_jj_pull": anim(4, 8.0, [KP(0, PUXA), KP(1, PUXA2), KP(2, PUXA), KP(3, PUXA2)], loop=True,
                         ideia="Choque JJ segurando = puxa (quadril para trás, cotovelos dobram, puxões curtos)."),
    "spar_jj_release": anim(4, 5.0, [KP(0, SOLTO), KP(1, G(SOLTO, top=[7, -60], head=[10, -70])),
                                     KP(2, G(SOLTO, top=[7, -60], head=[10, -70])), KP(3, SOLTO)], loop=True,
                            ideia="Choque JJ solto: mãos fora da gola, recuperando o fôlego (perto, pronto para pegar de novo)."),
    "spar_jj_yanked": anim(6, 14.0, [KP(0, PEGADA), KP(1, PUXADO, "out"), KP(2, PUXADO2), KP(3, PUXADO2), KP(5, PEGADA)],
                           ideia="Puxado para a frente (segurou na puxada forte dele): tropeça meio passo e volta."),
}

# ------------------------------------------------------------------ PARCEIRO (só o que é dele; o resto usa moves/reactions)
parceiro = {
    "box_warn": anim(3, 10.0, [KP(0, GUARDA), KP(2, AVISO, "out")], ideia="AVISO da rajada: ombro de trás recua, luva armada. Segurar o último quadro."),
    "box_burst": anim(6, 12.0, [
        KP(0, G(GUARDA, hip=[2, -37], top=[6, -61], head=[8, -70], tw=1.0, hf=[34, -61], hb=[6, -62], shoeb="ball", toeb=[-1, -1])),
        KP(1, G(GUARDA, hip=[1, -37], top=[4, -61], head=[7, -70], tw=0.8, hf=[18, -60], hb=[13, -61])),
        KP(2, G(GUARDA, hip=[3, -37], top=[8, -60], head=[10, -69], tw=1.8, hf=[11, -60], hb=[34, -60], far_glove_front=True, shoeb="ball", toeb=[0, -1])),
        KP(3, G(GUARDA, hip=[1, -37], top=[4, -61], head=[7, -70], tw=0.8, hf=[16, -60], hb=[14, -61])),
        KP(4, G(GUARDA, hip=[2, -36], top=[7, -59], head=[9, -68], tw=1.2, hf=[33, -52], hb=[7, -61], shoeb="ball", toeb=[-1, -1])),
        KP(5, G(GUARDA, hip=[1, -37], top=[4, -61], head=[7, -70], tw=0.8, hf=[17, -59], hb=[10, -62]))],
        loop=True, ideia="RAJADA (1,5 s): jab, direto, jab na linha da cintura, em loop."),
    "box_pause": anim(4, 5.0, [KP(0, PAUSA), KP(1, G(PAUSA, top=[2, -61], head=[5, -70])), KP(2, G(PAUSA, top=[2, -61], head=[5, -70])), KP(3, PAUSA)],
                      loop=True, ideia="PAUSA: guarda baixa, respira de boca aberta (janela do contragolpe)."),
    "box_feint": anim(6, 12.0, [KP(0, GUARDA), KP(2, AVISO, "out"), KP(4, FINTA_BAIXA, "inout"), KP(5, FINTA_BAIXA)],
                      ideia="FINTA: começa igual ao aviso e, na metade, abaixa o ombro e solta a guarda (sem soco)."),
    "jj_warn": anim(3, 10.0, [KP(0, PEGADA), KP(2, AVISO_JJ, "out")], ideia="AVISO da puxada forte: afunda o quadril, carrega os cotovelos."),
    "jj_yank": anim(6, 12.0, [KP(0, AVISO_JJ), KP(2, PUXADA, "in"), KP(3, PUXADA), KP(5, G(PUXADA, hip=[-3, -35], top=[0, -59], head=[3, -69]))],
                    ideia="PUXADA FORTE: arranca para trás com o corpo todo e meio passo; segurar o último quadro até acabar."),
    "jj_pause": anim(4, 5.0, [KP(0, PAUSA_JJ), KP(1, G(PAUSA_JJ, top=[8, -60], head=[11, -70])),
                              KP(2, G(PAUSA_JJ, top=[8, -60], head=[11, -70])), KP(3, PAUSA_JJ)], loop=True,
                     ideia="PAUSA: solta a manga, só a gola presa, ombros caídos (janela do contragolpe)."),
    "jj_feint": anim(6, 12.0, [KP(0, PEGADA), KP(2, AVISO_JJ, "out"), KP(4, FINTA_JJ), KP(5, FINTA_JJ)],
                     ideia="FINTA: afunda como na puxada forte e, na metade, sobe de novo sem puxar."),
}

# ------------------------------------------------------------------ GARAGEM 3/4: discípulo com os panfletos (lista de quadros)
GB = {"hip": [0, -31], "top": [1, -50], "head": [1, -57], "sl": [-7, -47], "sr": [8, -47], "toel": [-2, 0], "toer": [9, 0],
      "hl": [-3, -40], "hr": [9, -27], "stl": "open", "str": "open", "pl": [-0.6, 1], "pr": [0.4, 1], "prop": "stack"}


def GF(**o):
    d = copy.deepcopy(GB)
    d.update(o)
    return d


garage = {
    "flyer_idle": {"_ideia": "Panfletagem parado: maço de panfletos no peito (mão de perto), a outra solta; respira.",
                   "fps": 5.0, "hit_frame": 0, "hit_hand": "hr", "pivot": [22, 67], "foco_saco": [0, 0], "loop": True,
                   "frames": [GF(), GF(top=[1, -51], head=[1, -58], sl=[-7, -48], sr=[8, -48], hl=[-3, -41]),
                              GF(top=[1, -51], head=[1, -58], sl=[-7, -48], sr=[8, -48], hl=[-3, -41]), GF()]},
    "flyer_give": {"_ideia": "ACEITOU: tira um panfleto do maço e estende para a frente (contato no 3); volta.",
                   "fps": 12.0, "hit_frame": 3, "hit_hand": "hr", "pivot": [22, 67], "foco_saco": [0, 0],
                   "frames": [GF(),
                              GF(hr=[0, -40], pr=[1, 0.6]),
                              GF(hr=[8, -43], prop="give", tw=0.2, top=[2, -50], head=[2, -57]),
                              GF(hr=[15, -41], prop="give", tw=0.4, top=[3, -50], head=[3, -57], sr=[9, -47], hip=[1, -31]),
                              GF(hr=[15, -41], prop="stack", tw=0.4, top=[3, -50], head=[3, -57], sr=[9, -47], hip=[1, -31]),
                              GF(hr=[11, -33])]},
    "flyer_miss": {"_ideia": "NÃO, VALEU: oferece, a pessoa recusa, recolhe o braço e dá de ombros.",
                   "fps": 10.0, "hit_frame": 0, "hit_hand": "hr", "pivot": [22, 67], "foco_saco": [0, 0],
                   "frames": [GF(hr=[15, -41], prop="give", tw=0.4, top=[3, -50], head=[3, -57], sr=[9, -47], hip=[1, -31]),
                              GF(hr=[15, -41], prop="give", tw=0.4, top=[3, -50], head=[3, -57], sr=[9, -47], hip=[1, -31]),
                              GF(hr=[8, -39], prop="give", head=[1, -56]),
                              GF(hr=[11, -35], prop="give", sl=[-7, -49], sr=[8, -49], top=[1, -51], head=[1, -57], face="effort"),
                              GF(hr=[2, -40], prop="give"),
                              GF()]},
}

# ------------------------------------------------------------------ PEDESTRES (perfil na escala da sala, 48x76, pivô 24,71)
# Ciclo de andar de 8 quadros (contato, desce, passagem, sobe; e o espelho). y do quadril sobe e desce 2 px.
PB = {"hip": [0, -31], "top": [2, -50], "head": [4, -58], "hrot": 0.0, "tw": 0.0, "hf": [1, -29], "hb": [1, -29],
      "pf": [-1, 0.2], "pb": [-1, 0.2], "far_glove_front": False, "shoef": "flat", "shoeb": "flat", "toef": [4, 0], "toeb": [-2, 0],
      "kf": [1, 0.1], "kb": [1, 0.1], "face": "normal", "view": "side"}
CICLO = [  # hip_y, toef, shoef, toeb, shoeb, hf, hb
    (-30, [10, 0], "flat", [-7, 0], "ball", [-4, -30], [6, -31]),
    (-29, [7, 0], "flat", [-9, -1], "ball", [-2, -29], [4, -30]),
    (-31, [2, 0], "flat", [3, -4], "flat", [1, -29], [1, -29]),
    (-32, [-3, 0], "ball", [8, -3], "flat", [4, -30], [-2, -29]),
    (-30, [-7, 0], "ball", [10, 0], "flat", [6, -31], [-4, -30]),
    (-29, [-9, -1], "ball", [7, 0], "flat", [4, -30], [-2, -29]),
    (-31, [3, -4], "flat", [2, 0], "flat", [1, -29], [1, -29]),
    (-32, [8, -3], "flat", [-3, 0], "ball", [-2, -29], [4, -30]),
]


def passo(i, k=1.0, lean=0.0, arms=1.0, **o):
    hy, tf, sf, tb, sb, hf, hb = CICLO[i % 8]
    d = copy.deepcopy(PB)
    d.update({"hip": [0, hy], "top": [2 + lean, hy - 19.5], "head": [4 + lean * 1.6, hy - 28],
              "toef": [tf[0] * k, tf[1]], "shoef": sf, "toeb": [tb[0] * k, tb[1]], "shoeb": sb,
              "hf": [1 + (hf[0] - 1) * arms, hf[1]], "hb": [1 + (hb[0] - 1) * arms, hb[1]]})
    d.update(o)
    return d


PARADO = dict(copy.deepcopy(PB), hip=[0, -31], top=[2, -50.5], head=[4, -59], toef=[5, 0], toeb=[-3, 0])
# 3/4 (garage_frame) virado para a câmera/direita
P34 = {"view": "34", "hip": [0, -31], "top": [1, -50], "head": [1, -57], "sl": [-7, -47], "sr": [8, -47], "toel": [-2, 0], "toer": [8, 0],
       "hl": [-8, -28], "hr": [9, -28], "stl": "open", "str": "open", "pl": [-0.2, 1], "pr": [0.2, 1], "face": "normal"}


def Q(**o):
    d = copy.deepcopy(P34)
    d.update(o)
    return d


MAO_PANFLETO = {"hf": [7, -40], "pf": [-0.4, 1], "prop": "flyer"}
pedestres = {
    "walk": {"fps": 10.0, "loop": True, "frames": [passo(i) for i in range(8)],
             "_ideia": "Andar normal (8 quadros). Virar a folha para quem anda para a esquerda."},
    "hurry": {"fps": 15.0, "loop": True, "frames": [passo(i, k=1.2, lean=2.5, arms=1.3) for i in range(8)],
              "_ideia": "SEM INTERESSE (pressa): passada longa, tronco à frente, braços balançando forte."},
    "phone": {"fps": 9.0, "loop": True, "frames": [passo(i, k=0.8, head=[5, -57 - (CICLO[i][0] + 31)], hf=[8, -42], pf=[-0.5, 1], prop="phone")
                                                    for i in range(8)],
              "_ideia": "SEM INTERESSE (celular): mão de perto segurando o celular na altura do peito, cabeça baixa, passo curto."},
    "pockets": {"fps": 10.0, "loop": True, "hands": "none", "frames": [passo(i, hf=[3, -32], hb=[0, -32], pf=[-1, 0.5], pb=[-1, 0.5], prop="headphones")
                                                                        for i in range(8)],
                "_ideia": "SEM INTERESSE (fone): fone de ouvido, mãos no bolso."},
    "crossed": {"fps": 10.0, "loop": True, "hands": "none", "frames": [passo(i, hf=[0, -40], hb=[2, -38], pf=[1, 0.6], pb=[1, 0.6]) for i in range(8)],
                "_ideia": "SEM INTERESSE (braço cruzado): braços cruzados no peito, cara séria."},
    "tell": {"fps": 8.0, "frames": [passo(1, k=0.7), PARADO, Q(), Q(hr=[11, -38], pr=[0.3, 1], head=[2, -57]),
                                    Q(hr=[11, -39], pr=[0.3, 1], head=[2, -58], top=[1, -51]), Q(hr=[11, -38], pr=[0.3, 1], head=[2, -57])],
             "_ideia": "SINAL (interessado): diminui, para, vira para a câmera e estende a mão aberta. Quadros 3-5 em loop enquanto durar o sinal."},
    "false": {"fps": 9.0, "frames": [passo(1, k=0.7), PARADO, Q(), dict(copy.deepcopy(PARADO), face="pain"),
                                     passo(0, k=1.2, lean=1.5, face="pain"), passo(1, k=1.2, lean=1.5, face="pain"), passo(2, k=1.2, lean=1.5, face="pain")],
              "_ideia": "SINAL FALSO: diminui, olha de relance (vira), desvia de cara fechada e acelera."},
    "refuse": {"fps": 10.0, "frames": [passo(1, k=0.7), dict(copy.deepcopy(PARADO), hf=[6, -38], pf=[-0.4, 1], face="pain"),
                                       dict(copy.deepcopy(PARADO), hf=[10, -45], pf=[-0.4, 1], face="pain"),
                                       dict(copy.deepcopy(PARADO), hf=[10, -43], pf=[-0.4, 1], face="pain"),
                                       dict(copy.deepcopy(PARADO), hf=[3, -32])],
               "_ideia": "NÃO, VALEU (clicou errado): para, levanta a mão espalmada, baixa e segue."},
    "flyer": {"fps": 10.0, "loop": True, "frames": [passo(i, **MAO_PANFLETO, head=[5, -58 - (CICLO[i][0] + 31)]) for i in range(8)],
              "_ideia": "ACEITOU: segue andando com o panfleto na mão, olhando para ele."},
}

dados = {
    "_sobre": "Fase 7a2 (Treino fora de hora): poses em dados. moves/reactions/garage = discípulo (make_golpes_jogador.gd com "
              "FC_GOLPES=este arquivo, FC_LUTADOR=disc FC_CAMADAS=1); parceiro e pedestres = make_sprites_fase7a2.gd. "
              "Autoria em tools/art/poses_7a2.py. Choque: os dois de pé nos pivôs da luta (50 px), cada um virado para o outro. "
              "Pedestres: perfil na escala da sala (braço 10+10,5), view 34 = quadro desenhado em 3/4 (virou para a câmera).",
    "moves": moves, "reactions": reactions, "garage": garage, "parceiro": parceiro, "pedestres": pedestres,
}
with open(os.path.join(AQUI, "golpes_7a2.json"), "w", encoding="utf-8") as f:
    json.dump(dados, f, ensure_ascii=False, indent=1)
print("ok golpes_7a2.json")


# ------------------------------------------------------------------ conferência de alcance (braço do discípulo 12+13 = 25 px)
def _ombros(q):
    import math
    hx, hy = q["hip"]; tx, ty = q["top"]
    dx, dy = tx - hx, ty - hy
    n = math.hypot(dx, dy); dx, dy = dx / n, dy / n
    fx, fy = -dy, dx
    sf = q.get("sf", [tx + fx * 2 - dx * 3, ty + fy * 2 - dy * 3])
    sb = q.get("sb", [tx - fx * 2 - dx * 2, ty - fy * 2 - dy * 2])
    return sf, sb


def confere_alcance(nome, keys, lim=25.0):
    import math
    ruins = []
    for k in keys:
        if k.get("view") == "34" or "hip" not in k:
            continue
        sf, sb = _ombros(k)
        for m, s in (("hf", sf), ("hb", sb)):
            d = math.hypot(k[m][0] - s[0], k[m][1] - s[1])
            if d > lim + 0.05:
                ruins.append("%s quadro-chave %s: %s a %.1f px (máx %.1f)" % (nome, k.get("at", "?"), m, d, lim))
    return ruins


def trava(keys, lim):
    import math
    for k in keys:
        if k.get("view") == "34" or "hip" not in k:
            continue
        sf, sb = _ombros(k)
        for m, sh in (("hf", sf), ("hb", sb)):
            dx, dy = k[m][0] - sh[0], k[m][1] - sh[1]
            d = math.hypot(dx, dy)
            if d > lim - 0.2:
                f = (lim - 0.2) / d
                k[m] = [round(sh[0] + dx * f, 2), round(sh[1] + dy * f, 2)]


for _k in parceiro["box_burst"]["keys"]:   # o direto da rajada gira o ombro de trás para a frente (como o contragolpe)
    _sf, _sb = _ombros(_k)
    _k["sf"], _k["sb"] = [round(v, 2) for v in _sf], [round(v, 2) for v in _sb]
    if _k["at"] == 2:
        _k["sf"], _k["sb"] = [9, -57], [13, -59]
for sec in (moves, reactions, parceiro):
    for g in sec.values():
        trava(g.get("keys", []), 25.0)
for g in pedestres.values():
    trava(g["frames"], 20.5)
for sec in (moves,):
    for g in sec.values():
        if "hit_hand" in g:
            k = [kk for kk in g["keys"] if kk["at"] == g["hit_frame"]][0]
            g["hit_point"] = [float(k[g["hit_hand"]][0]), float(k[g["hit_hand"]][1])]
with open(os.path.join(AQUI, "golpes_7a2.json"), "w", encoding="utf-8") as f:
    json.dump(dados, f, ensure_ascii=False, indent=1)
_r = []
for sec in (moves, reactions, parceiro):
    for nm, g in sec.items():
        _r += confere_alcance(nm, g.get("keys", g.get("frames", [])))
for nm, g in pedestres.items():
    _r += confere_alcance("ped_" + nm, g["frames"], 20.5)
for l in _r:
    print("ALCANCE", l)
