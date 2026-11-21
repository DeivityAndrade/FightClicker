# Fase 7b (Diretor de Arte): o sedã comprido de 2 portas volta à garagem (pedido do dono), com a lona cinza no estilo da 6d2.
# O carro fica em x 66..226 (y 167..229); o mentor sentado da GARAGEM sai da frente dele: 210,254 -> 232,270 (caixote 216,250).
# Osmar (52,258) e 2º mentor (26,304) não mudam. Os pontos da academia (gym_*) não mudam.
# Rodar depois do make_mockup_fase6d2_layout.gd -- --final:  python tools/art/manifest_7b.py
# Mantém o formato do arquivo (tab, CRLF, UTF-8). Rodar de novo não muda nada.
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")

SEAT = [232, 270]
CRATE = [SEAT[0] - 16, SEAT[1] - 20]
N_7B = ("7b: o sedã comprido de 2 portas voltou (x 66..226, lona cinza no estilo da 6d2 na metade de trás). O mentor sentado "
        "foi o único ponto que mudou: 210,254 -> 232,270 (caixote 216,250). Mais à direita o saco de lado (lado_esquerdo "
        "258,160) bateria na cabeça dele, por isso ele desce 16 px. A luz pintada das folhas ainda é a do ponto antigo.")

NOTE_BG = ("Fase 6d2/6d3/7b: garagem larga (tela inteira, 640x360 em 0,0). Parede do fundo x 70..569, chão até y 329 (a faixa de baixo "
           "da tela começa em 330), mesmo ponto de fuga (320,-28). O miolo x 171..469 é a garagem de antes (porta, prateleira, "
           "pôster, gancho da corda em 296,166); pilares em x 164..174 e 468..478. Peças: janela basculante e cano (parede esquerda), "
           "chapa de ferramentas (ala esquerda), CARRO VELHO (7b: sedã azul comprido de 2 portas, de lado, x 66..226, y 167..229, "
           "lona cinza-ardósia no estilo da 6d2 (cúpula com brilho pontilhado, faixa clara no ombro, dobras e corda laranja) "
           "cobrindo a metade de trás até o alto da roda de trás; pintado no fundo, atrás de todo mundo), geladeira com rádio em "
           "cima, pilha de pneus + pneu em pé, relógio de luz e mangueira (ala direita). Saíram na 6d3: escada, bancada, ralo, "
           "círculo de giz e o miolo chapado da mancha de óleo. Luz: a lâmpada de sempre + janela à esquerda + luminária de obra "
           "à direita. Gerador: tools/art/make_mockup_fase6d2_layout.gd -- --final.")


def main():
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    S = m["sprites"]
    B = m["by_data_id"]
    L = m["layout"]
    S["garage_bg"]["note"] = NOTE_BG
    L["mentor_spot"] = SEAT
    B["mentor_spot"]["pos"] = SEAT
    B["mentor_spot"]["crate"]["pos"] = CRATE
    B["mentor_spot"]["crate"]["sort_y"] = SEAT[1] - 4
    B["mentor_spot"]["occupies"] = [CRATE[0], SEAT[1] - 56, 33, 58]
    B["mentor_spot"]["note_7b"] = N_7B
    S["garage_crate"]["pos"] = CRATE
    S["garage_crate"]["sort_y"] = SEAT[1] - 4
    S["garage_crate"]["note_7b"] = N_7B
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    if out == raw:
        print("manifest: 7b já aplicada")
        return
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: 7b aplicada")


if __name__ == "__main__":
    main()
