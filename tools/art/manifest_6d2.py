# Fase 6d2 (Diretor de Arte): aplica no manifest a sala larga e os pontos novos (docs/arte/fase6d2-layout.md).
# Rodar uma vez, depois do `make_mockup_fase6d2_layout.gd -- --final`:  python tools/art/manifest_6d2.py
# Mexe só nas chaves desta fase e mantém o formato do arquivo (tab, CRLF, UTF-8). Rodar de novo não muda nada.
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")

MENTOR = [132, 254]
CRATE = [116, 234]          # canto de cima à esquerda (pés + (-16,-20))
MENTOR_2 = [62, 256]
PEOPLE = {"neighbor_1": [72, 322], "neighbor_2": [126, 322], "neighbor_3": [590, 322],
          "uncle_1": [400, 324], "uncle_2": [484, 262], "coach_1": [548, 250]}
TREADMILL = [466, 324]
DUMMY = [192, 318]
BOXES = {"treadmill": [466, 324], "jump_rope": [348, 327], "art": [192, 318], "glove": [292, 327]}
DUFFEL = [146, 244]
UNUSED = "Sem uso desde a 6d2: aparelho não comprado não aparece na sala (antes da caixa, nada; com a caixa, só a caixa)."


def main():
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    S = m["sprites"]
    L = m["layout"]
    B = m["by_data_id"]

    # fundos 640x360 e área da sala
    m["room_rect"] = [0, 18, 640, 312]
    S["garage_bg"].update({"frame_size": [640, 360], "pos": [0, 0], "note":
        "Fase 6d2: garagem larga (tela inteira, 640x360 em 0,0). Parede do fundo x 70..569, chão até y 329 (a faixa de baixo "
        "da tela começa em 330), mesmo ponto de fuga (320,-28). O miolo x 171..469 é a garagem de antes (porta, carro, "
        "prateleira, pôster, gancho da corda em 296,166); pilares em x 164..174 e 468..478. Novos: janela basculante e cano "
        "(parede esquerda), chapa de ferramentas e bancada (ala esquerda), geladeira, pneus, relógio de luz e mangueira (ala "
        "direita), escada (parede direita). Luz: a lâmpada de sempre + janela à esquerda + luminária de obra à direita. "
        "Gerador: tools/art/make_mockup_fase6d2_layout.gd -- --final."})
    S["gym_bg"].update({"frame_size": [640, 360], "pos": [0, 0], "note":
        "Fase 6d2: academia larga (tela inteira, 640x360 em 0,0). Parede do fundo x 70..569, chão até y 329, mesmo ponto de "
        "fuga. O miolo x 171..469 é a academia de antes (nome, espelho, pôsteres, prateleira com o Metrônomo em 240,118, "
        "quadro, banco, relógio de round, luvas, extintor, porta); pilares em x 164..174 e 468..478. Novos: 2 janelas altas "
        "(parede esquerda), quadro branco, suporte de halteres, kettlebell e medicine ball (ala esquerda), armários, bebedouro "
        "e árvore de anilhas (ala direita), espaldar (parede direita), tatame na frente à esquerda (embaixo do boneco). "
        "4 tubos: os 2 de sempre (sprite gym_tube) e 2 novos pintados no fundo (x 104 e 536)."})
    S["garage_daylight"]["frame_size"] = [170, 90]
    S["garage_daylight"]["note_6d2"] = ("Fase 6d2: refeita sobre o chão novo (mesmos passos de luz por pixel); 90 px de altura: "
                                       "o quadro cheio continua 20 px abaixo de y 289, esmaecendo em dither.")
    S["garage_door_shadow"]["note_6d2"] = "Fase 6d2: refeita sobre o chão novo e a luz do dia nova (mesmo desenho)."
    S["gym_daylight"]["frame_size"] = [146, 90]
    S["gym_daylight"]["note_6d2"] = S["garage_daylight"]["note_6d2"]
    S["gym_door"]["note_6d2"] = "Fase 6d2: as linhas de baixo (chão) refeitas sobre o chão novo; a porta não mudou."
    S["gym_half_dark"].update({"frame_size": [640, 360], "pos": [0, 0]})
    S["gym_half_dark"]["note_6d2"] = ("Fase 6d2: agora 640x360 em (0,0): o gym_bg novo -1 de x 340 em diante, dither de x 300 "
                                     "a 339, furo na porta (401,116,60,108). O tubo novo da direita (x 536) escurece junto.")

    # pessoas
    for k, p in PEOPLE.items():
        S[k]["pos"] = p
        S[k]["note_6d2"] = "Fase 6d2: ponto novo (sala larga). A luz pintada ainda é a do ponto antigo: pedir folha nova ao Artista de Personagens."
    g = B["gym"]
    g["people_pos"] = dict(PEOPLE, note="Fase 6d2: os mesmos pontos da garagem (sala larga). Vizinhos 1 e 2 na frente à "
                           "esquerda, tio 1 na frente à direita do alvo, tio 2 no fundo à direita da porta; vizinho 3 e Prof. "
                           "Nelson no canto direito (x >= 506), atrás do painel quando ele está fixado (aprovado pelo dono).")

    # mentores e caixote
    occ_seat = [116, 198, 33, 57]
    L["mentor_spot"] = MENTOR
    L["gym_mentor_spot"] = MENTOR
    L["gym_mentor_spot_info"]["crate"]["pos"] = CRATE
    L["gym_mentor_spot_info"]["occupies"] = occ_seat
    L["gym_mentor_spot_info"]["_nota"] = ("Fase 6d2: pés de quem senta no caixote = (132,254), em frente ao suporte de halteres, "
                                          "longe do alvo. O mesmo ponto da garagem.")
    ms = B["mentor_spot"]
    ms["pos"] = MENTOR
    ms["crate"]["pos"] = CRATE
    ms["occupies"] = occ_seat
    ms["note_6d2"] = "Fase 6d2: (132,254), em frente à bancada, à esquerda do Osmar (era 254,252, colado na folga do alvo)."
    for key in ["mentor_2_spot", "gym_mentor_2_spot"]:
        L[key] = MENTOR_2
        L[key + "_info"]["head_anchor_abs"] = [63, 191]
        L[key + "_info"]["occupies"] = [50, 191, 25, 67]
    m2 = B["mentor_2_spot"]
    m2["pos"] = MENTOR_2
    m2["head_anchor_abs"] = [63, 191]
    m2["occupies"] = [50, 191, 25, 67]
    m2["note_6d2"] = "Fase 6d2: (62,256), junto da parede esquerda, embaixo da janela (era 150,262)."
    for k in ["garage_crate", "garage_crate_gym"]:
        S[k]["pos"] = CRATE
    S["garage_crate_gym"]["note_6d2"] = "Fase 6d2: ponto novo; a luz dos tubos no ponto novo dá a mesma do antigo (arquivo igual)."
    for k in ["john_point_spot", "john_sit_down", "john_sit_rest", "mentor_first_taps"]:
        S[k]["pos"] = MENTOR
    S["john_duffel"]["pos"] = DUFFEL
    B["gym_arrival_scene"]["crate"]["pos"] = CRATE
    B["gym_arrival_scene"]["duffel"]["pos"] = DUFFEL
    B["gym_arrival_scene"]["half_dark"]["pos"] = [0, 0]
    B["gym_arrival_scene"]["half_dark"]["note_6d2"] = "Fase 6d2: 640x360 em (0,0) (era 384x272 em 128,18). Furo na porta igual."

    # aparelhos de descanso
    for lv in ["l0", "l1"]:
        for suf in ["", "_gym"]:
            for kind in ["idle", "side"]:
                k = "treadmill_%s_%s%s" % (lv, kind, suf)
                if k in S and "lado_direito" in S[k].get("positions", {}):
                    S[k]["positions"]["lado_direito"] = TREADMILL
            k = "grappling_dummy_%s_rest%s" % (lv, suf)
            if k in S:
                S[k]["positions"]["canto"] = DUMMY
                S[k]["note_6d2"] = "Fase 6d2: em cima do tatame da frente à esquerda; luz conferida para o ponto novo."
            k = "treadmill_%s_side%s" % (lv, suf)
            if k in S:
                S[k]["note_6d2"] = "Fase 6d2: encostada na frente à direita, fora do caminho da porta; luz refeita para o ponto novo."
    S["fx_arrive_dust"]["positions"]["lado_direito"] = TREADMILL
    S["fx_arrive_dust_small"]["positions"]["canto"] = DUMMY

    # caixas
    bs = L["box_slots"]
    for k, p in BOXES.items():
        bs[k] = p
    bs["_nota"] = ("Fase 6d2: pivô da caixa (meio da base, no chão), igual na garagem e na academia. A grande da esteira e a da "
                   "arte ficam onde o aparelho vai morar (esteira 466,324; boneco 192,318; a pera usa a pequena no mesmo ponto). "
                   "Luva e corda (pequenas) logo abaixo dos pés do lutador (292,327 e 348,327), fora da zona do alvo (y até 291). "
                   "Antes de comprar não há nada na sala; com a compra aparece só a caixa; abrindo, o aparelho.")

    # aparelho não comprado = invisível
    for u in ["unlock_treadmill", "unlock_jump_rope", "unlock_speed_bag", "unlock_grappling_dummy"]:
        e = B[u]
        for k in ["floor_mark", "ghost", "ghost_dim", "mark_states", "mark_pos", "lock", "lock_pos", "sign", "mark_note_fase51"]:
            e.pop(k, None)
        e["room_before_box"] = "nothing"
        e["note_6d2"] = UNUSED
    B["unlock_treadmill"]["box"]["pos"] = BOXES["treadmill"]
    B["unlock_treadmill"]["arrive"]["fx_pos"] = TREADMILL
    B["unlock_treadmill"]["arrive"]["extra"] = "fx_arrive_sparkle (opcional, pivô em 466,283)"
    B["unlock_jump_rope"]["box"]["pos"] = BOXES["jump_rope"]
    B["unlock_speed_bag"]["box"]["pos"] = BOXES["art"]
    B["unlock_grappling_dummy"]["box"]["pos"] = BOXES["art"]
    B["unlock_grappling_dummy"]["arrive"]["fx_pos"] = DUMMY
    for k in list(S.keys()):
        if k.startswith("tape_mark_") or k.startswith("ghost_") or k == "mark_padlock":
            S[k]["unused_since"] = "6d2"

    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: 6d2 aplicada")


if __name__ == "__main__":
    main()
