# Ronda Noturna do Gato Preto (Diretor de Arte): registra no manifest a arte da Ronda (rua da borracharia à noite + as 4
# camadas da lenda, props, HUD, letreiros, ícone da LENDA), o capuz no prego nos 3 locais, os recortes do Gato Preto por
# nível (pequeno + zoom) e a região GATO PRETO do mapa (ícones, plaquinha, ladrilho, anel "noite", nó lacrado, 3 nós).
# Rodar depois do make_arte_ronda.gd:
#   python tools/art/manifest_ronda.py
# Lê tools/art/ronda_sprites.json (gravado pelo gerador) e só acrescenta/atualiza as chaves desta fase; não apaga nada de
# ninguém (o Artista de Personagens registra o vulto e os ladrões com o script dele, em qualquer ordem). Mantém o formato
# (tab, CRLF, UTF-8). Rodar de novo não muda nada. Detalhes: docs/arte/ronda-manifest.md, direcao-visual.md §36.
import copy
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
META = os.path.join(ROOT, "tools", "art", "ronda_sprites.json")
GEN = "Gerador: tools/art/make_arte_ronda.gd (+ manifest_ronda.py). direcao-visual.md §36, docs/arte/ronda-manifest.md."

# ---- contrato (igual às constantes do gerador: mudar nos dois)
HOOD_SPOT = [352, 95]          # pivô = cabeça do prego; o mesmo nos 3 locais
HOOD_PIVOT = [8, 1]
HOOD_SIZE = [16, 22]
WALK_Y, BASE_Y, THIEF_Y, CURB_Y, TRACK_Y, HUD_H = 196, 262, 314, 330, 206, 36
OCC = {
    "tire": {"start": 26, "end": 146, "thief": [192, THIEF_Y], "land": [166, THIEF_Y], "prop": [212, 314], "prop_sprite": "ronda_prop_tire",
             "prop_rule": "no chão, à direita do ladrão, enquanto ele trabalha; no SUSTO voa (o ladrão larga o estepe)",
             "walk_on": "capa do muro do terreno baldio", "light": [196, 308]},
    "bike": {"start": 256, "end": 346, "thief": [392, THIEF_Y], "land": [366, THIEF_Y], "prop": [408, 288], "prop_sprite": "ronda_prop_pliers",
             "prop_rule": "na mão do ladrão (a folha do Artista desenha a mão; este prop é só o que voa no SUSTO). A bicicleta é do fundo",
             "walk_on": "marquise da borracharia", "light": [400, 306]},
    "gate": {"start": 494, "end": 546, "thief": [592, THIEF_Y], "land": [566, THIEF_Y], "prop": [606, 282], "prop_sprite": "ronda_prop_crowbar",
             "prop_rule": "na mão do ladrão, forçando o portão; no SUSTO voa", "walk_on": "capa do muro verde da casa 15", "light": [590, 306]},
}
LAYERS = {"graffiti": "ronda_layer_graffiti", "banner": "ronda_layer_banner", "kid_ears": "ronda_layer_kid_ears",
          "whole_street": "ronda_layer_whole_street"}

NOTES = {
    "ronda_bg": ("Ronda: a rua da borracharia à noite (640x360 em 0,0). Da esquerda para a direita: muro do terreno baldio (trecho 1), "
                 "borracharia de chapa com letreiro BORRACHARIA 24H, marquise de concreto (trecho 2) e porta 07, sobrado ocre com a "
                 "janela de cima acesa e a bicicleta encostada, muro verde da casa 15 (trecho 3), pilar com luminária e portão. Lua "
                 "cheia em cima à direita (pose do telhado). Cada ladrão fica numa poça de luz; o vulto anda na sombra do alto, com "
                 "meio-tom atrás. Camadas da lenda por cima: minigame_layout.ronda.layers."),
    "ronda_layer_graffiti": "Ronda, nível 2: pichação do gato (estêncil creme com a faixa nos olhos e o GP vermelho) no muro do terreno. 640x360 em 0,0.",
    "ronda_layer_banner": "Ronda, nível 3: faixa de pano VALEU, GATO PRETO pendurada na chapa da borracharia (atrás do trecho 2). 640x360 em 0,0.",
    "ronda_layer_kid_ears": "Ronda, nível 4: criança na janela de cima do sobrado com orelhinhas de papelão e a faixa vermelha, acenando; desenho colado no vidro. 640x360 em 0,0.",
    "ronda_layer_whole_street": ("Ronda, nível 5: o bairro inteiro com o gato desenhado: bandeirinhas com o capuz, gatos de giz na calçada, "
                                 "adesivo no poste, gato na caixa d'água, orelhas na janela da casa 15, GP no portão. 640x360 em 0,0."),
    "ronda_prop_tire": "Ronda, ocorrência tire: o estepe (roda com pneu). Pivô = meio da base, no chão. No SUSTO voa e cai (o UI/UX anima: arco + giro em quadros não; só deslocamento inteiro).",
    "ronda_prop_pliers": "Ronda, ocorrência bike: o alicate que o moleque larga no SUSTO. Pivô no meio.",
    "ronda_prop_crowbar": "Ronda, ocorrência gate: o pé de cabra que o sujeito larga no SUSTO. Pivô no meio.",
    "hood_on_nail": ("Ronda: o CAPUZ NO PREGO da garagem (16x22; pivô 8,1 = cabeça do prego). Capuz preto pendurado pela nuca, orelhas "
                     "largas e baixas costuradas, abertura do rosto, a faixa vermelha (a da folha do vulto) enrolada no prego com as pontas caindo. "
                     "Luz da lâmpada pela esquerda. Quadro 0 = parado; 1 = hover (contorno creme). Parado: sem brilho, sem som, sem anim."),
    "hood_on_nail_gym": "Ronda: o capuz no prego da academia (e do centro): o mesmo desenho com a luz fria de cima. Quadros iguais ao hood_on_nail.",
    "icon_legend": "Ronda: ícone 9x9 da LENDA (lua cheia com o capuz de orelhas na frente). HUD da Ronda, tela de prêmio, janela da árvore.",
    "icon_legend_16": "Ronda: ícone 16x16 da LENDA (o mesmo desenho maior). Topo da tela da Ronda e do prêmio.",
    "ui_legend_pip": "Ronda: bolinha do nível da lenda (7x7; pivô no meio): 0 apagada, 1 acesa (lua), 2 acendendo (1 quadro, na subida de nível). 5 com passo 9.",
    "ui_ronda_track": "Ronda: moldura da barra de distância (9-slice 8x6: 1,1,1,1), embaixo da capa do muro, de start-4 a end+4 do trecho (minigame_layout.ronda).",
    "ui_ronda_fill": "Ronda: enchimento da barra (4x4 repetido): 0 = andando (azul da noite), 1 = PERTO (ouro).",
    "ui_ronda_zone": "Ronda: zona do SUSTO na barra (4x4 repetido de 0,8 até o fim, por baixo do enchimento): 0 parada, 1 piscando com o PERTO (6 fps).",
    "ui_thief_warn": ("Ronda: aviso em cima da cabeça do ladrão (13x14; pivô 6,13 = ponta de baixo): 0 = AVISO começando (? cinza), "
                      "1 = AVISO (? branco), 2 = OLHANDO (! branco no balão vermelho). Forma e cor mudam juntas. Aviso falso = 0,1 e some."),
    "ui_banner_scare": "Ronda: letreiro SUSTO! (receita do K.O.!: ouro, contorno ink, sombra de fonte azul-marinho b0). 2x no jogo em (320,118), com a tremida do K.O.",
    "ui_banner_scare_near": "Ronda: SUSTO! pequeno piscando em cima do vulto quando ele está PERTO (2 quadros: aceso / apagado, 6 fps). Pivô no meio; 50 px acima dos pés.",
    "ui_banner_escaped": "Ronda: ESCAPOU (cinza, fonte 2x, sem tremida): falha leve.",
    "icon_ronda_16": "Ronda: o capuz em 16x16 (título da tela de prêmio, linha do relatório).",
    "icon_occurrence": "Ronda: ícone 9x9 das OCORRÊNCIAS (o estepe solto): contador da tela de prêmio e os 3 sustos no HUD.",
    "icon_region_black_cat": "Ronda: ícone 16x16 da região GATO PRETO (telhado de telha à noite, a lua e o vulto na cumeeira).",
    "icon_region_black_cat_9": "Ronda: ícone 9x9 da região GATO PRETO (plaquinha do nome da região).",
    "ui_map_region_label_black_cat": "Ronda: plaquinha da região GATO PRETO (9-slice 16x13, faixa da noite b1 com o ponto da lua).",
    "map_tile_black_cat_region": "Ronda: ladrilho 32x32 da região GATO PRETO (telhado de telha capa-canal à noite, azul-marinho).",
    "map_node_s_owned_night": "Ronda: anel 'noite' do nó pequeno comprado da região GATO PRETO (troca de cor do anel azul: marinho + brilho creme).",
    "map_node_b_owned_night": "Ronda: anel 'noite' do marco comprado da região GATO PRETO.",
    "map_node_s_sealed": ("Ronda (D7 do design): nó pequeno LACRADO (vizinho de nó comprado com a trava black_cat:N fechada): o 'faltando' "
                          "com um lacre cinza do capuz no meio. Sem ícone e sem preço; o texto PRECISA DA LENDA NÍVEL N vai no cartão."),
    "map_node_b_sealed": "Ronda (D7): marco LACRADO (o mesmo lacre, maior).",
    "skill_black_cat_roof": "Ronda: nó Atalho pelos telhados (2 Tios no começo): o desenho de skill_crew_regulars com o carimbo do gato no canto.",
    "skill_black_cat_watch": "Ronda: nó O bairro de olho (+2 dias na liga): o calendário de skill_prep_day com +2 e o carimbo do gato.",
    "skill_black_cat_thanks": "Ronda: nó O bairro agradece (equipe +40%): o desenho de skill_body_crew com o carimbo do gato.",
}
for lv in range(1, 6):
    NOTES["wall_clipping_black_cat_l%d" % lv] = ("Ronda: recorte do Gato Preto na GARAGEM, lenda nível %d (23x28, mesmo ponto do da 7a2: "
                                                "clipping_spot). Manchete curta 3x5 legível em 1x e foto do que o bairro conta neste nível. "
                                                "O texto inteiro vai no hover (clipping_text_by_level)." % lv)
    NOTES["wall_clipping_black_cat_gym_l%d" % lv] = ("Ronda: recorte do Gato Preto na ACADEMIA (e no CENTRO), lenda nível %d (23x28, papel "
                                                    "mais claro da luz fria; gym_clipping_spot / center_clipping_black_cat_spot)." % lv)
    NOTES["ui_clipping_black_cat_zoom_l%d" % lv] = ("Ronda: o recorte grande do hover/prêmio, lenda nível %d (128x96): CORREIO DA ESQUINA, "
                                                   "chamada + título, foto e colunas. É a 1ª peça a cortar (escopo §9)." % lv)


def main():
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    meta = json.load(open(META, encoding="utf-8"))
    S, B, LY = m["sprites"], m["by_data_id"], m["layout"]
    for sid, d in meta.items():
        e = {"file": "res://assets/sprites/" + d["rel"], "frame_size": d["frame_size"], "frames": d["frames"],
             "fps": d["fps"], "pivot": d["pivot"], "note": NOTES.get(sid, "") + " " + GEN}
        if sid == "ronda_bg" or sid.startswith("ronda_layer_"):
            e.update({"pos": [0, 0], "layer": "fundo", "z": -100 if sid == "ronda_bg" else -90})
        elif sid == "hood_on_nail":
            e.update({"pos": HOOD_SPOT, "point": "hood_spot", "layer": "wall", "z": -44, "anim": {"idle": [0], "hover": [1]}})
        elif sid == "hood_on_nail_gym":
            e.update({"pos": HOOD_SPOT, "point": "gym_hood_spot", "layer": "wall", "z": -44, "anim": {"idle": [0], "hover": [1]}})
        elif sid.startswith("wall_clipping_black_cat_gym_l"):
            e.update({"pos": [340, 60], "point": "gym_clipping_spot", "layer": "wall", "z": -45})
        elif sid.startswith("wall_clipping_black_cat_l"):
            e.update({"pos": [304, 100], "point": "clipping_spot", "layer": "wall", "z": -45})
        elif sid == "ui_ronda_track" or sid == "ui_map_region_label_black_cat":
            e["nine_slice"] = {"left": 1, "top": 1, "right": 1, "bottom": 1} if sid == "ui_ronda_track" else {"left": 4, "top": 1, "right": 1, "bottom": 1}
        elif sid == "ui_legend_pip":
            e["anim"] = {"off": [0], "on": [1], "light": [2, 1]}
        elif sid == "ui_thief_warn":
            e["anim"] = {"warn_start": [0], "warn": [1], "look": [2], "fake": [0, 1, 0]}
        elif sid == "ui_banner_scare_near" or sid == "ui_ronda_zone":
            e["loop"] = True
        S[sid] = e
    # o centro usa os arquivos da academia (mesma luz fria)
    S["hood_on_nail_center"] = dict(copy.deepcopy(S["hood_on_nail_gym"]), point="center_hood_spot",
                                    note="Ronda: no centro usa o mesmo arquivo de hood_on_nail_gym (mesma luz fria). " + GEN)
    for lv in range(1, 6):
        S["wall_clipping_black_cat_center_l%d" % lv] = dict(copy.deepcopy(S["wall_clipping_black_cat_gym_l%d" % lv]),
                                                            point="center_clipping_black_cat_spot",
                                                            note="Ronda: no centro usa o arquivo da academia (nível %d). %s" % (lv, GEN))
    # ---- pontos da sala
    for key, loc, spr in (("hood_spot", "garage", "hood_on_nail"), ("gym_hood_spot", "gym", "hood_on_nail_gym"),
                          ("center_hood_spot", "center", "hood_on_nail_center")):
        LY[key] = list(HOOD_SPOT)
        LY[key + "_info"] = {
            "location": loc, "sprite": spr, "anchor": "pivô = cabeça do prego (8,1)", "size": HOOD_SIZE, "layer": "wall", "z": -44,
            "frames": {"idle": 0, "hover": 1}, "object_text": "hood_hover",
            "click_rect": [HOOD_SPOT[0] - HOOD_PIVOT[0] - 2, HOOD_SPOT[1] - 1, HOOD_SIZE[0] + 4, HOOD_SIZE[1] + 2],
            "when": "GameState.capuz_visivel() != '' (ronda.json hood); sem clique (hover e clique desligados) quando capuz_info().clickable é falso, mas continua desenhado",
            "_nota": ("Ronda (Diretor de Arte): o mesmo prego nos 3 locais, na parede lisa entre a corrente do saco (x 335) e a porta "
                      "(garagem) / o relógio de rounds (academia e centro), logo ao lado do recorte do vulto: o capuz e o jornal contam "
                      "a mesma história. Fora da zona do alvo (y < 150), dos cards da esquerda e do painel fixado. Conferido no gerador "
                      "contra o manifest e a ocupação conhecida, e colado nas capturas do ui_audit com a sala cheia "
                      "(docs/arte/mockups/ronda_capuz_*.png): 0 problemas. Ninguém da equipe chega a y 117 (as cabeças mais altas "
                      "ficam em y ~183)."),
        }
    clip_note = ("Ronda: a partir da lenda nível 1 troca o sprite pelo do nível (sprite_by_level[n]); o hover usa "
                 "clipping_text_by_level do ronda.json e o zoom zoom_by_level[n]. Mesmo ponto e tamanho em todos os níveis.")
    LY["clipping_spot_info"]["sprite_by_level"] = ["wall_clipping_black_cat"] + ["wall_clipping_black_cat_l%d" % lv for lv in range(1, 6)]
    LY["clipping_spot_info"]["zoom_by_level"] = ["ui_clipping_black_cat_zoom"] + ["ui_clipping_black_cat_zoom_l%d" % lv for lv in range(1, 6)]
    LY["clipping_spot_info"]["level_rule"] = clip_note
    LY["gym_clipping_spot_info"]["sprite_by_level"] = ["wall_clipping_black_cat_gym"] + ["wall_clipping_black_cat_gym_l%d" % lv for lv in range(1, 6)]
    LY["gym_clipping_spot_info"]["zoom_by_level"] = LY["clipping_spot_info"]["zoom_by_level"]
    LY["gym_clipping_spot_info"]["level_rule"] = clip_note
    LY["center_clipping_black_cat_spot_info"] = {
        "location": "center", "anchor": "canto de cima à esquerda", "size": [23, 28], "layer": "wall", "z": -45,
        "object_text": "black_cat_clipping", "click_rect": [340, 60, 23, 28],
        "sprite_by_level": ["wall_clipping_black_cat_center"] + ["wall_clipping_black_cat_center_l%d" % lv for lv in range(1, 6)],
        "zoom_by_level": LY["clipping_spot_info"]["zoom_by_level"], "level_rule": clip_note,
    }
    # ---- tela da Ronda
    occ = copy.deepcopy(OCC)
    m.setdefault("minigame_layout", {})["ronda"] = {
        "_nota": ("Ronda (Diretor de Arte): contrato da tela 'Estátua no telhado' (1x, 640x360). Posições de HUD são sugestão (a final é "
                  "do UI/UX); pés, trechos, luz e faixas livres são do cenário e valem para o Artista. Mockups: docs/arte/mockups/ronda_*.png. "
                  "Mudar aqui e nas constantes do make_arte_ronda.gd juntos."),
        "bg": "ronda_bg",
        "layers": LAYERS,
        "layers_rule": "desenhar por cima do ronda_bg, na ordem de street_layers_by_level do ronda.json (cumulativas); todas em 0,0, z -90",
        "hud_band": [0, 0, 640, HUD_H],
        "bottom_band": [0, CURB_Y + 6, 640, 360 - CURB_Y - 6],
        "walk_y": WALK_Y,
        "facade_base_y": BASE_Y,
        "thief_feet_y": THIEF_Y,
        "track": {"y": TRACK_Y, "h": 6, "x_from": "start - 4", "x_to": "end + 4", "zone_from": 0.8,
                  "sprites": {"frame": "ui_ronda_track", "fill": "ui_ronda_fill", "zone": "ui_ronda_zone"}},
        "occurrences": occ,
        "occurrence_order": ["tire", "bike", "gate"],
        "vulto": {"feet": "x = lerp(start, end, distancia), y = walk_y", "facing": "direita (anda para a direita)",
                  "frame_hint": "agachado ~46 px de altura (gente em pé ~64); o dublê do gerador é 52x50 com os pés em (26,49)",
                  "intro": "entre trechos (intro_s 0,8): corte para o começo do próximo trecho com o pulo/pouso do Artista",
                  "scare": "SUSTO: arco de (end, walk_y) até land; a capa cai reta (nunca abre em asa)"},
        "thief": {"facing_working": "direita (de costas para o vulto)", "facing_look": "esquerda (espelhar)",
                  "frame_hint": "como os pedestres da Panfletagem (48x76, pés em 24,71)", "warn_anchor": "x do ladrão + 2, y = thief_feet_y - 70 (pivô de baixo do ui_thief_warn)"},
        "near_banner": {"sprite": "ui_banner_scare_near", "anchor": "x do vulto, walk_y - 50"},
        "scare_banner": {"sprite": "ui_banner_scare", "pos": [320, 118], "scale": 2},
        "escaped_banner": {"sprite": "ui_banner_escaped", "anchor": "x do ladrão, thief_feet_y - 90"},
        "dust": "fx_dust_fall (o que já existe) nos pés do vulto em land e do ladrão quando cai sentado",
        "rooftop_pose": {"feet": [552, 114], "moon": [552, 70], "moon_r": 24,
                         "rule": "pose no telhado com a lua (tela de prêmio ou fim da ronda): o vulto em pé na cumeeira da casa 15, a silhueta dele cobre a lua"},
        "hud_suggestion": {"legend_icon": [8, 8], "legend_label": [28, 8], "legend_pips": [28, 18], "pip_step": 9,
                           "occurrence_box": [252, 4, 136, 22], "timer_box": [586, 4, 48, 18], "exit_button": [8, 334, 48, 18],
                           "tip_center": [340, 343]},
        "light_rule": "cada ladrão numa poça de luz (poste, arandela, luminária do pilar); o vulto anda na sombra do alto, com meio-tom atrás (parede da casa de fundos, chapa da borracharia, casa 15)",
    }
    # ---- dados
    B["black_cat"] = {
        "hood": {"garage": "hood_on_nail", "gym": "hood_on_nail_gym", "center": "hood_on_nail_center",
                 "points": {"garage": "hood_spot", "gym": "gym_hood_spot", "center": "center_hood_spot"}},
        "legend_icon": "icon_legend", "legend_icon_16": "icon_legend_16", "legend_pip": "ui_legend_pip",
        "occurrence_icon": "icon_occurrence", "reward_icon": "icon_ronda_16",
        "clipping_by_level": {"garage": LY["clipping_spot_info"]["sprite_by_level"], "gym": LY["gym_clipping_spot_info"]["sprite_by_level"],
                              "center": LY["center_clipping_black_cat_spot_info"]["sprite_by_level"],
                              "zoom": LY["clipping_spot_info"]["zoom_by_level"]},
        "street_layers": LAYERS,
        "color_rule": "cor da Ronda = NOITE: azul-marinho b0/b1 + o creme da lua; ouro só no PERTO/SUSTO (conquista sua). Nunca o roxo do Legado nem o azul vivo do Jiu-jitsu.",
        "note": "Ronda (Diretor de Arte). direcao-visual.md §36, docs/arte/ronda-manifest.md.",
    }
    sm = B["skill_map"]
    sm["node"]["tone_by_branch_or_region"]["black_cat"] = "night"
    sm["node"]["small"]["owned_by_tone"]["night"] = "map_node_s_owned_night"
    sm["node"]["big"]["owned_by_tone"]["night"] = "map_node_b_owned_night"
    # conserto da 8a2: o manifest_8a2.py procurava a chave 'milestone' e o anel aço do marco nunca entrou em 'big'
    sm["node"]["big"]["owned_by_tone"]["steel"] = "map_node_b_owned_steel"
    sm["node"]["small"]["sealed"] = "map_node_s_sealed"
    sm["node"]["big"]["sealed"] = "map_node_b_sealed"
    sm["node"]["sealed_rule"] = ("Ronda (D7): estado 'sealed' (só nós com trava black_cat:N): desenhar o sealed no lugar do missing, sem "
                                 "ícone e sem preço; cartão com node_sealed (PRECISA DA LENDA NÍVEL {n}).")
    sm["region_label"]["sprites"]["black_cat"] = "ui_map_region_label_black_cat"
    sm["region_icons"]["black_cat"] = "icon_region_black_cat"
    sm.setdefault("region_tiles", {})["black_cat"] = "map_tile_black_cat_region"
    for nid, icon in (("cat_rooftop", "skill_black_cat_roof"), ("cat_watch", "skill_black_cat_watch"), ("cat_thanks", "skill_black_cat_thanks")):
        sm["icon_by_node"][nid] = icon
    B["_nota_ronda_arte"] = ("Ronda (Diretor de Arte): by_data_id.black_cat, skill_map (tom night, região black_cat, sealed, anel aço do "
                             "marco), layout hood_spot/gym_hood_spot/center_hood_spot, recortes por nível, minigame_layout.ronda. "
                             "direcao-visual.md §36, docs/arte/ronda-manifest.md.")
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    if out == raw:
        print("manifest: ronda já aplicada")
        return
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: ronda aplicada (%d sprites + 6 atalhos do centro)" % len(meta))


if __name__ == "__main__":
    main()
