# Fase 7a2 (Diretor de Arte): registra no manifest os cenários dos minigames, as peças de HUD, a peça do convite,
# o ícone do AQUECIDO e o recorte de jornal do vigilante (pontos clipping_spot / gym_clipping_spot).
# Rodar depois do make_arte_fase7a2.gd:  python tools/art/manifest_7a2.py
# Também registra as folhas do Artista de Personagens, se o documento dele existir
# (docs/arte/fase7a2-personagens-manifest.md, mesmo formato da 7a1: bloco ```json depois de
# "## Entradas completas para `sprites`" e, opcional, depois de "## minigame_layout (acrescentar)").
# Só acrescenta/atualiza as chaves desta lista: lê o manifest na hora de gravar e não mexe nas entradas de outros agentes.
# Mantém o formato do arquivo (tab, CRLF, UTF-8). Rodar de novo não muda nada.
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
GEN = "Gerador: tools/art/make_arte_fase7a2.gd (+ manifest_7a2.py)."
PERSONAGENS_DOC = os.path.join(ROOT, "docs", "arte", "fase7a2-personagens-manifest.md")


def spr(file, fw, fh, frames=1, fps=0.0, pivot=(0, 0), **extra):
    d = {"file": "res://assets/sprites/" + file, "frame_size": [fw, fh], "frames": frames, "fps": fps, "pivot": list(pivot)}
    d.update(extra)
    return d


SPRITES = {
    # --- cenários
    "spar_bg": spr("minigame/spar_bg.png", 640, 360, pos=[0, 0], layer="fundo", z=-100, note=(
        "Fase 7a2: cenário do CHOQUE, fundos da Academia Boa Esquina depois do expediente. Parede de trás (reboco creme e "
        "barrado verde) com a porta dos FUNDOS aberta e acesa, janela gradeada, ar-condicionado, alambrado da praça à direita, "
        "poste com braço iluminando um tatame de EVA velho no meio. y 0..71 é céu escuro: o HUD fica ali. Pés dos dois "
        "lutadores em y 318 (x 296 e 346, como na luta); o Osmar fica lá atrás, na porta (150,262, escala da sala). "
        "Centro x 200..440 sem objeto na frente. Luz já aplicada. " + GEN)),
    "flyers_bg": spr("minigame/flyers_bg.png", 640, 360, pos=[0, 0], layer="fundo", z=-100, note=(
        "Fase 7a2: cenário da PANFLETAGEM, a rua do bairro na mesma noite. Muro com lambe-lambes e o cartaz da escola "
        "(R de raiz, RAÍZES, AULA) em (26,168) 36x48, padaria fechada, LANCHES DA NENA aceso, casa 27 com portão, ponto de "
        "ônibus; dois postes (x 104 e 494) e um lambe-lambe pequeno no poste da esquerda. Calçada de y 262 a 330 (meio-fio "
        "330, asfalto embaixo). Pedestres com pés em y 300 atravessam a tela inteira; o lutador fica na frente à esquerda "
        "(70,324) e o Osmar no canto direito (604,326). y 0..40 escuro para o HUD. " + GEN)),
    # --- Choque: barra, marcador, pontos, fôlego, avisos
    "ui_tug_track": spr("ui/ui_tug_track.png", 260, 16, note=(
        "Fase 7a2: barra do cabo de guerra (tamanho fixo 260x16; sugestão: x 190, y 28, centrada). Esquerda = o seu lado "
        "(azul), direita = o lado dele (vermelho), ponta de cada lado é a 'parede' onde encosta. Marcador de x 8 (-1, ele te "
        "encostou) a x 251 (+1, você encostou ele), relativo à barra; marcas em 1/4, meio e 3/4. " + GEN)),
    "ui_tug_marker": spr("ui/ui_tug_marker.png", 11, 22, 3, pivot=(5, 11), frames_note=(
        "0 normal, 1 empurrado (claro: 1 quadro na tremida do clique), 2 contragolpe (ouro com brilho branco, enquanto vale o X2)."),
        note=("Fase 7a2: agulha do cabo de guerra; pivô no meio da barra (y da barra + 8). Mover em px inteiros. " + GEN)),
    "ui_tug_touch": spr("ui/ui_tug_touch.png", 24, 24, 3, 16.0, pivot=(12, 12), loop=False, note=(
        "Fase 7a2: estalo do ENCOSTOU na ponta da barra (3 quadros a ~16 fps, depois some). Mesmo estalo, pequeno, para "
        "ELE ENCOSTOU na ponta esquerda. " + GEN)),
    "ui_point_pip": spr("ui/ui_point_pip.png", 7, 7, 3, pivot=(3, 3), frames_note="0 vazia, 1 ponto seu (ouro), 2 ponto dele (vermelho).",
        note=("Fase 7a2: bolinhas dos pontos (meta 3 = points_goal), passo 9 px, ao lado de VOCÊ e de ELE; o número fica "
              "ao lado para quem passar de 3. " + GEN)),
    "ui_breath_bar": spr("ui/ui_breath_bar.png", 8, 6, nine_slice={"left": 1, "top": 1, "right": 1, "bottom": 1}, note=(
        "Fase 7a2: moldura do FÔLEGO (9-slice 1 px; dentro 4 px). Sugestão: 96 de largura, embaixo da barra à esquerda, com o "
        "icon_breath antes e o texto FÔLEGO depois. Só o seu fôlego aparece. " + GEN)),
    "ui_breath_fill": spr("ui/ui_breath_fill.png", 4, 4, 3, tile="horizontal", frames_note=(
        "0 descansado (verde, fôlego > 50%), 1 meio (amarelo, 25..50%), 2 no fim (vermelho, < 25%: a força do clique já caiu)."),
        note=("Fase 7a2: enchimento do fôlego, 4x4 repetido na horizontal (corte no fim). " + GEN)),
    "icon_breath": spr("ui/icon_breath.png", 9, 9, note="Fase 7a2: FÔLEGO, três linhas de ar. " + GEN),
    "ui_warn_burst": spr("ui/ui_warn_burst.png", 17, 17, 2, 6.0, pivot=(8, 16), loop=True, note=(
        "Fase 7a2: aviso de RAJADA (Boxe) / PUXADA (JJ): estrela pontuda VERMELHA com ! branco, acima da cabeça do parceiro "
        "(pivô embaixo; sugestão: x do parceiro, y 212). Os 2 quadros pulsam durante o warn_s. Texto RAJADA!/PUXADA! acima. " + GEN)),
    "ui_warn_pause": spr("ui/ui_warn_pause.png", 17, 17, 2, 6.0, pivot=(8, 16), loop=True, note=(
        "Fase 7a2: aviso de PAUSA (ELE ABRIU!): balão REDONDO BRANCO com ! escuro. Forma e cor diferentes da rajada: lê sem "
        "depender de cor. Mesmo ponto do ui_warn_burst. " + GEN)),
    "ui_warn_feint": spr("ui/ui_warn_feint.png", 17, 17, 3, 0.0, pivot=(8, 16), loop=False, frames_note=(
        "0 = igual à rajada; 1 = o meio da troca (1 quadro, ~0,08 s); 2 = igual à pausa. Trocar 0->1->2 na metade do aviso."),
        note=("Fase 7a2: FINTA, o ! vermelho que vira branco. " + GEN)),
    "ui_counter_x2": spr("ui/ui_counter_x2.png", 19, 13, 2, 8.0, pivot=(9, 12), loop=True, note=(
        "Fase 7a2: X2 do contragolpe, em cima do marcador enquanto a pausa vale (piscar 0/1) e no clique que pegou a janela. " + GEN)),
    # --- AQUECIDO e ícones dos minigames
    "icon_warm": spr("ui/icon_warm.png", 9, 9, note=(
        "Fase 7a2: AQUECIDO (chama laranja de miolo claro), na linha da prévia (warm_preview_line) e ao lado do risco no HUD. " + GEN)),
    "icon_warm_16": spr("ui/icon_warm_16.png", 16, 16, note="Fase 7a2: AQUECIDO em 16x16 (tela de prêmio do Choque). " + GEN),
    "icon_spar_16": spr("ui/icon_spar_16.png", 16, 16, note=(
        "Fase 7a2: CHOQUE (luva vermelha e luva azul frente a frente com estalo): tela de prêmio, título. " + GEN)),
    "icon_flyers_16": spr("ui/icon_flyers_16.png", 16, 16, note=(
        "Fase 7a2: PANFLETAGEM (maço em leque com o R da escola): tela de prêmio, título. " + GEN)),
    # --- convite
    "ui_invite_go": spr("ui/ui_invite_go.png", 14, 13, 3, nine_slice={"left": 3, "top": 3, "right": 3, "bottom": 4},
        frames_note="0 normal, 1 hover, 2 apertado (desce 1 px).", text_color="ink", note=(
        "Fase 7a2: botão IR dentro do balão do convite (o balão é o ui_balloon de sempre, com a etiqueta ouro do Osmar). "
        "Sugestão: 22x13, à direita do texto, alinhado com a 2ª linha (by + 8); largura do balão = texto + 5 + 4 + 22 + 5. "
        "Texto IR em ink. Ouro (y0) = a cor do Osmar. Mockup: fase7a2_convite_x2.png. " + GEN)),
    # --- Panfletagem
    "icon_flyer": spr("ui/icon_flyer.png", 9, 9, note="Fase 7a2: panfleto da escola 9x9 no contador {n} DE {goal}. " + GEN),
    "ui_flyer_fly": spr("ui/ui_flyer_fly.png", 9, 7, 3, 12.0, pivot=(4, 3), loop=True, note=(
        "Fase 7a2: panfleto voando da mão do lutador até quem aceitou (girando 0-1-2; ~0,25 s de voo em px inteiros). " + GEN)),
    "ui_tell_mark": spr("ui/ui_tell_mark.png", 7, 11, 3, 0.0, pivot=(3, 10), loop=False, frames_note=(
        "0 aparecendo (1 quadro), 1 cheio (enquanto dura o tell_s), 2 sumindo (dither; o sinal falso termina assim na metade)."),
        note=("Fase 7a2: ? pequeno do sinal, acima da cabeça de quem olha o cartaz (head_anchor da folha do pedestre - 4). " + GEN)),
    # --- recorte do vigilante
    "wall_clipping_black_cat": spr("garage/wall_clipping_black_cat.png", 23, 28, pos=[304, 100], point="clipping_spot",
        layer="wall", z=-45, note=(
        "Fase 7a2: RECORTE DE JORNAL do vulto mascarado (semente do Gato Preto; o nome não aparece). Manchete VULTO legível "
        "em 1x, foto granulada com a silhueta pequena do vigilante (capuz com orelhas costuradas, faixa nos olhos com as "
        "pontas voando, capa de lona caindo), colunas, borda picotada e fita. Garagem, à direita do pôster SOCO, embaixo da "
        "lâmpada (luz já aplicada). Hover: black_cat_clipping. Sem logotipo de herói. " + GEN)),
    "wall_clipping_black_cat_gym": spr("gym/wall_clipping_black_cat_gym.png", 23, 28, pos=[340, 60], point="gym_clipping_spot",
        layer="wall", z=-45, note=(
        "Fase 7a2: o mesmo recorte na academia (papel mais claro, luz dos tubos), entre o espelho e o relógio de rounds, "
        "embaixo do letreiro. " + GEN)),
    "ui_clipping_black_cat_zoom": spr("ui/ui_clipping_black_cat_zoom.png", 100, 84, note=(
        "Fase 7a2 (OPCIONAL): o recorte grande para a dica do hover (CORREIO DA ESQUINA / VULTO / MASCARADO e a foto do "
        "vigilante agachado no telhado). A frase inteira continua no texto black_cat_clipping. Se a dica for só texto, não usar. " + GEN)),
}

CLIP_INFO = {
    "anchor": "canto de cima à esquerda", "size": [23, 28], "layer": "wall", "z": -45, "object_text": "black_cat_clipping",
}
LAYOUT = {
    "clipping_spot": [304, 100],
    "clipping_spot_info": dict(CLIP_INFO, location="garage", sprite="wall_clipping_black_cat", click_rect=[304, 100, 23, 28],
        when="data/minigames.json black_cat_seed.clipping (campanha >= 2 e garage_saved)", _nota=(
        "Fase 7a2: à direita do pôster SOCO (até x 298), embaixo da lâmpada (até y 80), 9 px antes da corrente do saco no "
        "centro (x 335) e longe da parede da memória (x 176..256), do metrônomo, da corda no gancho (296,166) e da zona do alvo "
        "(x 273..370 só de y 150 para baixo). Conferido no gerador (conferência do recorte: 0).")),
    "gym_clipping_spot": [340, 60],
    "gym_clipping_spot_info": dict(CLIP_INFO, location="gym", sprite="wall_clipping_black_cat_gym", click_rect=[340, 60, 23, 28],
        requires_milestone="cena_primeira_academia", _nota=(
        "Fase 7a2: entre o espelho (até x 330) e o relógio de rounds (x 372), embaixo do letreiro (até y 52); 4 px depois da "
        "corrente do saco no centro (x 335). Fora da corrente do saco de lado (x 257), do Osmar, da foto e do mural.")),
}

MINIGAME_LAYOUT = {
    "_nota": ("Fase 7a2: contrato das telas dos minigames (1x, 640x360). Os cenários são minigame/spar_bg e minigame/flyers_bg. "
              "Posições de HUD são sugestão (a final é do UI/UX); pés e faixas livres são do cenário e valem para o Artista. "
              "Mockups: docs/arte/mockups/fase7a2_*.png. Mudar aqui e nas constantes do make_arte_fase7a2.gd juntos."),
    "spar": {
        "bg": "spar_bg", "hud_band": [0, 0, 640, 72], "feet_y": 318, "player_x": 296, "partner_x": 346,
        "coach_spot": [150, 262], "coach_note": "Osmar lá atrás, na porta dos fundos (escala da sala, pivô nos pés).",
        "ground_free_x": [200, 440], "mat": {"top_y": 280, "bottom_y": 344},
        "tug_track": [190, 28, 260, 16], "tug_marker_x": [8, 251], "tug_marker_pivot_y": 36,
        "breath": {"icon": [190, 49], "bar": [202, 50, 96, 6], "label": [302, 49]},
        "points": {"you_label": [190, 8], "you_pips": [228, 8], "him_label_right": [450, 8], "him_pips": [392, 8], "pip_step": 9},
        "timer_box": [296, 4, 48, 18], "warn_anchor": "x do parceiro, y 212 (pivô de baixo do ícone); texto 26 px acima",
        "exit_button": [8, 334, 48, 18], "tip_center": [320, 343],
    },
    "flyers": {
        "bg": "flyers_bg", "hud_band": [0, 0, 640, 40], "walk_feet_y": 300, "walk_x": [-30, 670],
        "fighter_spot": [70, 324], "coach_spot": [604, 326], "poster_rect": [26, 168, 36, 48],
        "click_band_x": [110, 600], "click_note": "Área de clique generosa: o quadro inteiro da folha do pedestre + 6 px.",
        "counter_box": [264, 4, 112, 20], "timer_box": [584, 4, 48, 18], "exit_button": [8, 334, 48, 18], "tip_center": [320, 343],
    },
}


def json_block(text, title):
    i = text.index(title)
    a = text.index("```json", i) + len("```json")
    b = text.index("```", a)
    return json.loads(text[a:b])


def personagens():
    if not os.path.exists(PERSONAGENS_DOC):
        return {}, {}
    doc = open(PERSONAGENS_DOC, "rb").read().decode("utf-8")
    sprites = json_block(doc, "## Entradas completas para `sprites`")
    extra = {}
    if "## minigame_layout (acrescentar)" in doc:
        extra = json_block(doc, "## minigame_layout (acrescentar)")
    for k, v in sprites.items():
        f = v["file"].replace("res://", "")
        assert os.path.exists(os.path.join(ROOT, f)), "falta o PNG de " + k + ": " + f
    return sprites, extra


def main():
    for k, v in SPRITES.items():
        f = v["file"].replace("res://", "")
        assert os.path.exists(os.path.join(ROOT, f)), "falta o PNG de " + k + ": " + f
    p_sprites, p_layout = personagens()
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    S = m["sprites"]
    for k, v in SPRITES.items():
        S[k] = v
    for k, v in p_sprites.items():
        S[k] = v
    m["layout"].update(LAYOUT)
    ml = json.loads(json.dumps(MINIGAME_LAYOUT))
    for scr, d in p_layout.items():
        ml.setdefault(scr, {}).update(d)
    m["minigame_layout"] = ml
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    if out == raw:
        print("manifest: 7a2 já aplicada")
        return
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: 7a2 aplicada (%d da arte + %d do Artista de Personagens%s)" % (
        len(SPRITES), len(p_sprites), "" if os.path.exists(PERSONAGENS_DOC) else "; documento dele ainda não existe"))


if __name__ == "__main__":
    main()
