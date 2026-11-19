# Fase 6d3 (Diretor de Arte): atualiza só a nota do garage_bg no manifest (carro novo, pneus, geladeira; sem escada, bancada e ralo).
# Nenhum ponto, tamanho ou pivô muda. Rodar depois do make_mockup_fase6d2_layout.gd -- --final:  python tools/art/manifest_6d3.py
# Mantém o formato do arquivo (tab, CRLF, UTF-8). Rodar de novo não muda nada.
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")

NOTE = ("Fase 6d2/6d3: garagem larga (tela inteira, 640x360 em 0,0). Parede do fundo x 70..569, chão até y 329 (a faixa de baixo "
        "da tela começa em 330), mesmo ponto de fuga (320,-28). O miolo x 171..469 é a garagem de antes (porta, prateleira, "
        "pôster, gancho da corda em 296,166); pilares em x 164..174 e 468..478. Peças: janela basculante e cano (parede esquerda), "
        "chapa de ferramentas (ala esquerda), CARRO VELHO (6d3: sedã azul de lado, x 69..194, y 167..229, lona cinza-azulada (cor da 6d2) cobrindo a metade de trás até o alto da roda de trás, "
        "pintado no fundo, atrás de todo mundo), geladeira com rádio em cima, pilha de pneus + pneu em pé, relógio de luz e "
        "mangueira (ala direita). Saíram na 6d3: escada, bancada, ralo, círculo de giz e o miolo chapado da mancha de óleo. Luz: a lâmpada de sempre + janela à esquerda + "
        "luminária de obra à direita. Gerador: tools/art/make_mockup_fase6d2_layout.gd -- --final.")


def main():
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    S = m["sprites"]
    S["garage_bg"]["note"] = NOTE
    S["wall_school_symbol"]["note"] = (
        "Arco 1: SÍMBOLO DA ESCOLA pintado na parede. 6d3: emblema a estêncil na tinta azul da escola (b1/b2, a mesma do "
        "school_symbol_*): disco com a lâmpada em creme dentro e as raízes descendo para fora, 2 escorridos, tinta que afunda no "
        "rejunte. Antes era o school_symbol_16 em 2x amarelo vivo e lia como borrão aceso. Aparece quando a garagem é salva. "
        "Recortado sobre o garage_bg deste ponto (não mover). Gerador: tools/art/make_arte_fase6d3.gd.")
    # símbolo da escola aprovado (6d3): o R de raiz (proposta D, docs/arte/fase6d3-simbolo.md)
    R = "o R de raiz (um R de traço grosso com as pernas virando raízes; aprovado pelo dono na 6d3, proposta D)"
    for n in (5, 9, 16, 32):
        S["school_symbol_%d" % n]["note"] = ("SÍMBOLO DA ESCOLA Raízes Fight Club (%dx%d): %s, em tinta de carimbo azul b1 + b2. "
                                             "Gerador: tools/art/make_arte_fase6d3_simbolo.gd. Pintado na parede: wall_school_symbol." % (n, n, R))
    B = m["by_data_id"]
    for k in ("school_symbol",):
        B[k]["design"] = "Raízes Fight Club: " + R
    B["box"]["symbol"]["design"] = "Raízes Fight Club: " + R
    B["garage_saved_seal"]["_nota"] = B["garage_saved_seal"]["_nota"].replace("(a lâmpada com raízes)", "(o R de raiz, 6d3)")
    S["seal_garage_saved"]["note"] = S["seal_garage_saved"]["note"].replace("(a lâmpada)", "(o R de raiz, 6d3)")
    B["disciple_layers"]["school_symbol_note"] = (
        "Fase 6c2/6d3: <base>_disc_symbol_chest.png e _symbol_leg.png em todas as poses, folhas _left e retrato 32x32. "
        "6d3: o desenho é o R de raiz (3/4 = school_symbol_5; perfil e coxa = R em 3x5), desenhado por personagem_lib.gd e "
        "aplicado por tools/art/make_arte_fase6d3_simbolo.gd, que desvira o carimbo nas folhas viradas (o R não é simétrico).")
    S["wall_school_symbol"]["note"] = (
        "Arco 1: SÍMBOLO DA ESCOLA pintado na parede: " + R + ", o school_symbol_16 em 2x na tinta azul b1 com realce creme, "
        "tinta que afunda no rejunte, 2 escorridos. Aparece quando a garagem é salva. Recortado sobre o garage_bg deste ponto "
        "(não mover). Gerador: tools/art/make_arte_fase6d3_simbolo.gd.")
    S["ui_mural_seal"]["note_6d3"] = "6d3: o miolo da roseta é o R de raiz (school_symbol_9)."
    S["wall_mural"]["note_6d3"] = "6d3: a plaquinha da escola mostra o R de raiz (school_symbol_9). Igual no wall_mural_gym."
    S["box_big"]["note_6d3"] = "6d3: a etiqueta mostra o R de raiz (school_symbol_9)."
    S["box_small"]["note_6d3"] = "6d3: a etiqueta mostra o R de raiz (school_symbol_5)."
    # bug B1 (QA 6d3): ninguém na frente do carro da garagem. Só pontos da GARAGEM; os da academia (gym_*) não mudam.
    L = m["layout"]
    COACH, SEAT, CRATE, STAND = [52, 258], [210, 254], [194, 234], [26, 304]
    N_B1 = ("6d3 (bug B1): mudou para não ficar na frente do carro (sedã em x 69..194). Osmar 196,236 -> 52,258 (encostado na "
            "frente do carro); sentado 132,254 -> 210,254 (caixote 194,234, logo atrás do carro, perto do saco); 2º mentor "
            "62,256 -> 26,304. A luz pintada das folhas ainda é a do ponto antigo.")
    B["coach_point"]["pos"] = COACH
    B["coach_point"]["note_6d3"] = N_B1
    B["original_trainer"]["pos"] = COACH
    B["original_trainer"]["note_6d3"] = N_B1
    for k in ("coach_idle", "coach_look", "coach_talk", "coach_point"):
        S[k]["pos"] = COACH
    L["mentor_spot"] = SEAT
    B["mentor_spot"]["pos"] = SEAT
    B["mentor_spot"]["crate"]["pos"] = CRATE
    B["mentor_spot"]["occupies"] = [194, 198, 33, 58]
    B["mentor_spot"]["note_6d3"] = N_B1
    S["garage_crate"]["pos"] = CRATE
    L["mentor_2_spot"] = STAND
    B["mentor_2_spot"]["pos"] = STAND
    B["mentor_2_spot"]["head_anchor_abs"] = [STAND[0] + 1, STAND[1] - 65]
    B["mentor_2_spot"]["sort_y"] = STAND[1] + 6
    B["mentor_2_spot"]["note_6d3"] = N_B1
    L["mentor_2_spot_info"]["head_anchor_abs"] = [STAND[0] + 1, STAND[1] - 65]
    L["mentor_2_spot_info"]["occupies"] = [14, 239, 25, 67]
    L["mentor_2_spot_info"]["sort_y"] = STAND[1] + 6
    S["lamp"]["note_6d3"] = ("6d3: saiu o anel de pontinhos laranja em volta da lâmpada (lia como faísca/borrão); o brilho "
                             "fica só na luz do garage_bg. Mesmos quadros, tamanho e pivô. Gerador: tools/art/make_arte_fase6d3.gd.")
    S["gym_bg"]["note_6d3"] = ("6d3: nome pintado inteiro (BOA lia BOR) e espelho limpo com uma trinca curta no canto de cima "
                               "(a estrela de trincas lia como teia). Gerador: make_mockup_fase6d2_layout.gd, gym_fix_6d3.")
    S["arena_bg"]["note_6d3"] = ("6d3: as 18 manchas redondas marrons da chapa viraram ferrugem escorrendo pelos vales; o 07 da "
                                 "porta sem o dither por cima (lia 0T); os anéis tracejados das lâmpadas viraram brilho em "
                                 "dither. Gerador: tools/art/make_arte_fase6d3.gd (cópia fiel do make_arena da Fase 3).")
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    if out == raw:
        print("manifest: 6d3 já aplicada")
        return
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: 6d3 aplicada")


if __name__ == "__main__":
    main()
