# Fase 8a1 (Artista de Personagens): autoria das poses de ASSINATURA da liga regional -> tools/art/golpes_8a1_adv.json.
# As poses são DADOS (quadros-chave no formato do golpes.json); o rig comum (make_sprites_elenco.gd, modo "regional") desenha.
# Rodar: python tools/art/poses_8a1.py   (grava só o JSON; não mexe em mais nada)
# Cada reação tem "who" = quem usa (os outros adversários não ganham essa folha).
#   shake_head   Zé Bigorna  (Queixo de ferro: "AGUENTOU!")  leva no queixo, a cabeça vai e volta, sacode e bate no queixo
#   plant_feet   Tião Estaca (Base larga: "NÃO CAIU")        a queda trava: os pés NÃO saem do lugar, o quadril afunda e as
#                                                             mãos empurram as costas de quem tentou; poeira no pé
#   slip_clinch  Rony Sabão  (Ensaboado: "ESCAPOU!")         pego pela nuca, afunda, gira e escorrega para trás com bolhas
#   guard        James       (Blindado, 1º round)            guarda fechada: as duas luvas na frente do rosto, cotovelo colado
#   block        James       (substitui o block do rig)       a guarda fechada aguenta o soco (mesmos 3 quadros do block)
#   idle         James       (substitui o idle do rig)        peito estufado, queixo erguido, mãos baixas
#   scorn        James       (gesto de desprezo)              olha a luva, tira um fiapo e dá um peteleco para trás
# Geometria: espaço do jogador (pivô entre os pés, virado à DIREITA, y negativo para cima), ANTES da escala do corpo.
# "fx" = efeito desenhado por cima do quadro (texto, não interpola): "bolha:x,y,r;poeira:x,y" (mesmo espaço da pose).
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


R = {}

# ------------------------------------------------------------------ Zé Bigorna: sacode a cabeça (Queixo de ferro)
# A guarda dele é baixa (confia no queixo). 0-1 o queixo leva e a cabeça vai para trás; 2 volta grogue; 3-5 sacode
# (a cabeça vai e vem 2 px com giro de 10 graus, o ombro acompanha 1 px); 6 bate a luva da frente no próprio queixo e
# sorri; 7-9 volta para a guarda baixa.
BG = P(hf=[16, -46], hb=[11, -49])
R["shake_head"] = anim(10, 12.0, [
    KP(0, P(BG, hip=[-1, -37], top=[-2, -60], head=[-2, -70], hrot=-14.0, face="pain", hf=[14, -45], hb=[9, -48])),
    KP(1, P(BG, hip=[-2, -37], top=[-3, -60], head=[-4, -69], hrot=-18.0, face="pain", hf=[13, -44], hb=[8, -47]), "out"),
    KP(2, P(BG, hip=[-1, -37], top=[1, -61], head=[4, -71], hrot=0.0, face="ko")),
    KP(3, P(BG, top=[3, -61], head=[8, -71], hrot=14.0, face="ko")),
    KP(4, P(BG, top=[1, -61], head=[2, -71], hrot=-14.0, face="tired")),
    KP(5, P(BG, top=[3, -61], head=[7, -71], hrot=9.0, face="normal")),
    KP(6, P(BG, head=[5, -71], hrot=0.0, face="joy", hf=[13, -63], pf=[-0.6, 1]), "out", hold=1),
    KP(8, P(BG, face="joy")),
    KP(9, P(BG)),
], ["opp_reg_1"], "Queixo de ferro: leva no queixo, a cabeça vai para trás e volta, sacode duas vezes e bate a luva no queixo, rindo. Toca no lugar do K.O. de embalo que não entrou (AGUENTOU!) e quando o embalo do jogador chega a 5.")

# ------------------------------------------------------------------ Tião Estaca: pés plantados (Base larga)
# Os pés NÃO se mexem em nenhum quadro (a base dele já é larga na guarda). 0 guarda; 1-2 quem tentou a queda puxa: o
# quadril afunda 7 px, o tronco vai por cima e as duas mãos apertam as costas/ombros de quem está embaixo; poeira sai dos
# pés no impacto; 3-4 segura; 5-7 levanta devagar, sem dar um passo.
GE = P()
EMP = P(GE, hip=[-2, -30], top=[7, -53], head=[11, -63], hrot=18.0, face="grit", hf=[23, -43], hb=[19, -45],
        pf=[0.6, 1], pb=[0.6, 1], kf=[1, -0.3], kb=[1, -0.3])
R["plant_feet"] = anim(9, 10.0, [
    KP(0, P(GE)),
    KP(1, P(EMP, fx="poeira:16,-1;poeira:-4,-1"), "out"),
    KP(2, P(EMP, hip=[-2, -31], fx="poeira:18,-2;poeira:-6,-2")),
    KP(3, P(EMP, hip=[-2, -31], top=[6, -54], head=[10, -64])),
    KP(4, P(EMP, hip=[-2, -31], top=[6, -54], head=[10, -64])),
    KP(6, P(GE, hip=[-1, -34], top=[4, -58], head=[8, -68], hrot=8.0, face="normal", hf=[19, -54], hb=[14, -56])),
    KP(8, P(GE)),
], ["opp_reg_2"], "Base larga: a queda trava no meio. Os pés ficam exatamente no mesmo lugar do 1º ao último quadro; o quadril afunda, ele pesa por cima e empurra quem tentou. Toca no lugar do fall quando a queda não entrou (NÃO CAIU).")

# ------------------------------------------------------------------ Rony Sabão: desliza do clinch (Ensaboado)
# 0 pego pela nuca (igual ao held_clinch); 1 puxado para baixo; 2 afunda e gira, as luvas empurram o peito de quem
# segura, saem bolhas da nuca; 3-5 escorrega 10 px para trás (o corpo todo, os pés deslizam no chão), sorrindo;
# 6-9 volta para a guarda no lugar de sempre.
HELD = P(hip=[0, -37], top=[4, -60], head=[8, -70], hf=[14, -56], hb=[10, -58], face="pain", shoeb="ball")
R["slip_clinch"] = anim(10, 14.0, [
    KP(0, P(HELD)),
    KP(1, P(HELD, hip=[-1, -36], top=[8, -56], head=[14, -63], hrot=25.0, hf=[19, -59], hb=[16, -61]), "out"),
    KP(2, P(HELD, hip=[-3, -33], top=[3, -54], head=[9, -61], hrot=12.0, face="normal", hf=[21, -55], hb=[17, -57],
            fx="bolha:16,-64,2;bolha:12,-69,1;bolha:20,-60,1")),
    KP(3, P(HELD, hip=[-9, -34], top=[-5, -55], head=[0, -63], hrot=4.0, face="joy", hf=[8, -55], hb=[4, -57],
            toef=[9, -1], toeb=[-9, -1], fx="bolha:15,-62,2;bolha:9,-70,2;bolha:21,-66,1"), "out"),
    KP(4, P(HELD, hip=[-12, -35], top=[-9, -58], head=[-5, -67], hrot=0.0, face="joy", hf=[4, -58], hb=[-1, -60],
            toef=[5, -1], toeb=[-13, -1], shoeb="flat", fx="bolha:13,-66,1;bolha:7,-73,2;bolha:19,-71,1"), "out"),
    KP(5, P(BASE, hip=[-10, -37], top=[-8, -61], head=[-5, -71], hf=[6, -59], hb=[2, -61], face="joy",
            toef=[5, -1], toeb=[-13, -1], fx="bolha:6,-77,1;bolha:12,-72,1")),
    KP(7, P(BASE, hip=[-4, -37], top=[-2, -61], head=[1, -71], hf=[12, -59], hb=[8, -61], toef=[11, -1], toeb=[-7, -1])),
    KP(9, P(BASE)),
], ["opp_reg_3"], "Ensaboado: o clinch começa (pego pela nuca), ele afunda, gira e escorrega 10 px para trás com bolhas saindo da nuca, e volta para a guarda. Toca no lugar do held_clinch quando o clinch não pegou (ESCAPOU!). Termina no pivô de sempre.")

# ------------------------------------------------------------------ James Blindado: guarda fechada, bloqueio e desprezo
# Guarda fechada: as duas luvas coladas na frente do queixo e da boca (os olhos aparecem por cima), cotovelos colados no
# tronco, queixo guardado. Respira 1 px nos ombros.
GF = P(hip=[-1, -37], top=[1, -61], head=[4, -70], hf=[13, -62], hb=[11, -64], far_glove_front=True,
       pf=[-0.1, 1], pb=[-0.1, 1], tw=0.5)
R["guard"] = anim(4, 6.0, [
    KP(0, P(GF)),
    KP(1, P(GF, top=[1, -62], head=[4, -71], hf=[13, -63], hb=[11, -65])),
    KP(2, P(GF)),
    KP(3, P(GF, hip=[-1, -36], top=[1, -60], head=[4, -69], hf=[13, -61], hb=[11, -63])),
], ["opp_james"], "Blindado (1º round): guarda fechada em repouso, no lugar do idle enquanto a guarda vale (t < 5,33 s); também J0 e fim da apresentação.", loop=True)
R["block"] = anim(3, 14.0, [
    KP(0, P(GF, hf=[12, -62], hb=[10, -64])),
    KP(1, P(GF, hip=[-3, -37], top=[-2, -61], head=[1, -70], hf=[9, -62], hb=[7, -64], face="pain"), "out"),
    KP(2, P(GF, hip=[-2, -37], top=[0, -61], head=[3, -70], hf=[11, -62], hb=[9, -64])),
], ["opp_james"], "Blindado: o soco bate na guarda fechada e ele recua 2 px sem abrir as luvas (mesmos 3 quadros do block do rig).")

# IDLE do James (pedido do Diretor de Cutscenes, fase8a1-cutscene-james.md §5): peito estufado, queixo erguido, olha por
# cima; mãos baixas e relaxadas (não leva a escola a sério). Respira pelo peito (sobe 1 px), o queixo nunca baixa.
SOLTA = P(hip=[0, -37], top=[1, -62], head=[3, -73], hrot=-6.0, hf=[12, -44], hb=[6, -46], pf=[-0.2, 1], pb=[-0.2, 1],
          tw=0.2, face="smirk")
R["idle"] = anim(4, 5.0, [
    KP(0, P(SOLTA)),
    KP(1, P(SOLTA, top=[1, -63], head=[3, -74], hf=[12, -45], hb=[6, -47])),
    KP(2, P(SOLTA)),
    KP(3, P(SOLTA, hip=[0, -36], top=[1, -61], head=[3, -72], hf=[12, -43], hb=[6, -45])),
], ["opp_james"], "James (substitui o idle do rig): peito estufado, queixo erguido, mãos baixas. Na luta, depois do 1º round (antes dele: guard).", loop=True)

# GESTO DE DESPREZO (scorn; animação principal do dono; 6 quadros a 7 fps = 0,86 s; pico no 4º quadro, índice 3):
# 0 idle; 1 ergue a luva da frente e olha para ela (o queixo desce para a luva, como quem acha um fiapo); 2 a luva de trás
# "pega o fiapo" na luva da frente; 3 PICO: peteleco/abano curto da luva de trás para TRÁS e para baixo (para longe do
# adversário, espantando a escola como poeira); 4 segue o abano e já volta o queixo para cima; 5 idle com o meio sorriso.
OLHA = P(SOLTA, head=[4, -71], hrot=10.0, hf=[13, -53], pf=[-0.5, 1], face="sneer")
R["scorn"] = anim(6, 7.0, [
    KP(0, P(SOLTA)),
    KP(1, P(OLHA), "out"),
    KP(2, P(OLHA, hb=[11, -55], far_glove_front=True, pb=[0.3, 1])),
    KP(3, P(SOLTA, head=[3, -73], hrot=-8.0, hf=[13, -50], hb=[-9, -47], pb=[-0.6, 1], face="smirk",
            fx="poeira:-14,-50;poeira:-17,-46"), "out"),
    KP(4, P(SOLTA, hrot=-8.0, hf=[12, -46], hb=[-6, -42], pb=[-0.6, 1], face="smirk", fx="poeira:-19,-47")),
    KP(5, P(SOLTA)),
], ["opp_james"], "Gesto de desprezo: olha a própria luva, tira um fiapo e dá um peteleco para trás (para longe do adversário, nunca para ele). 6 quadros a 7 fps; pico (tap_glove) no quadro 3 (o 4º). Nada de dedo apontado.", peak_frame=3)

# CANSADO do James (perdeu por pontos e fala depois, ainda arrogante): ombros caídos (2 px abaixo do normal), guarda baixa na
# cintura, peito arfando (o tronco sobe e desce 2 px, o quadril 1 px), cabeça um pouco mais baixa que no idle mas o queixo
# continua empinado (giro -6). 4 quadros em loop: inspira (0-1), solta (2-3).
def CANS(dy, dh, face):
    t = [2, -58 - dy]
    return P(BASE, hip=[0, -36 - dh], top=t, head=[5, -68 - dy], hrot=-6.0, face=face, tw=0.2,
             sf=[t[0] + 2, t[1] + 5], sb=[t[0] - 2, t[1] + 6], hf=[9, -35 - dh], hb=[3, -37 - dh], pf=[-0.7, 1], pb=[-0.7, 1])
R["tired"] = anim(4, 5.0, [
    KP(0, CANS(0, 0, "tired")),
    KP(1, CANS(2, 1, "tired")),
    KP(2, CANS(1, 1, "smirk")),
    KP(3, CANS(0, 0, "tired")),
], ["opp_james"], "James cansado (substitui o tired do rig): ombros caídos, guarda baixa, peito arfando 2 px, queixo ainda empinado. Loop. Usado quando ele perde por pontos e fala depois da luta.", loop=True)

dados = {"_sobre": "Fase 8a1: poses de assinatura dos adversários da liga regional (rig comum; make_golpes_jogador.gd só expande, make_sprites_elenco.gd regional desenha). Gerado por tools/art/poses_8a1.py.",
         "moves": {}, "reactions": R}
json.dump(dados, open(os.path.join(AQUI, "golpes_8a1_adv.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("ok: golpes_8a1_adv.json (%d reações)" % len(R))
