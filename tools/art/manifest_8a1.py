# Fase 8a1 (Diretor de Arte): registra no manifest a arte da Liga Regional do Vale (arena regional, cartaz da liga, Cinturão
# do Vale, ícones das passivas dos adversários, sinais, fx da guarda, plaquinha do James). Rodar depois do make_arte_fase8a1.gd:
#   python tools/art/manifest_8a1.py
# Lê tools/art/fase8a1_sprites.json (gravado pelo gerador) e só acrescenta/atualiza as chaves desta fase.
# Mantém o formato do arquivo (tab, CRLF, UTF-8). Rodar de novo não muda nada.
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
META = os.path.join(ROOT, "tools", "art", "fase8a1_sprites.json")
GEN = "Gerador: tools/art/make_arte_fase8a1.gd (+ manifest_8a1.py). direcao-visual.md §34, docs/arte/fase8a1-manifest.md."

NOTES = {
    "arena_regional_bg": ("Fase 8a1: arena da LIGA REGIONAL DO VALE, CLUBE FERROVIÁRIO à noite. Tijolo, janelas em arco, nome do clube pintado, "
                          "relógio de estação, placa AO VIVO, arquibancada de madeira com torcida, treliça com 4 refletores e a faixa da liga, "
                          "câmera da TV VALE à direita, mesa dos juízes à esquerda e o RINGUE: lona de y 262 (x 151..489) a y 342 (x 104..536), "
                          "saia com AUTOPEÇAS VALE FORTE até y 357, postes (azul à esquerda = você, vermelho à direita = ele, brancos na frente), "
                          "3 cordas (azul/branca/vermelha) atrás e dos lados; sem corda na frente (a câmera é a da TV). Pés em y 318, chão livre "
                          "x 200..440, y 0..45 ink liso. Luz já aplicada. Sem lâmpada (não existe arena_regional_lamp)."),
    "arena_regional_crowd_back": ("Fase 8a1: o público do Ginásio Alvorada (mesmas figuras) com paleta de noite da torcida do Vale, já recortado "
                                  "onde o ringue, a mesa e a câmera ficam na frente. 0 parado, 1 vibrando. Mesmo pos e anim das outras arenas."),
    "arena_regional_crowd_front": ("Fase 8a1: silhuetas da frente nos cantos (boné e bandeira verdes) e um câmera de mão da TV no canto direito "
                                   "(luz vermelha pisca entre os quadros). Nunca cobre x 138..502."),
    "arena_regional_ropes_side": ("Fase 8a1 (opcional): as cordas LATERAIS e os 2 postes da frente, por cima dos lutadores (z 40, abaixo do "
                                  "público da frente). Os mesmos pixels do fundo: ligada ou não, a luta parada fica igual; na ENTRADA NO RINGUE o "
                                  "lutador passa por trás delas (parece entrar entre as cordas). 0 px em x 200..440 (conferido no gerador)."),
    "arena_regional_spot": ("Fase 8a1 (opcional): facho de luz em dither (y2) que segue quem entra no ringue. Pivô nos pés (48,258): position = "
                            "pés do lutador. z -55 (acima do público de trás, atrás dos lutadores). 2 quadros a 8 fps (tremida de refletor)."),
    "fx_guard_clink": ("Fase 8a1: golpe batendo na GUARDA FECHADA do James no 1º round (evento guard: true): estalo de aço no hit_point, no lugar "
                       "do fx_fight_hit. 3 quadros a 18 fps, sem loop, pivô no meio."),
    "belt_regional_raised": ("Fase 8a1: o Cinturão do Vale ERGUIDO acima da cabeça, em escala de corpo (40x22). Pivô (20,15) = meio das mãos: "
                             "position = base do lutador + (hand_front + hand_back)/2 do quadro de fight_player_victory. Pegadas (15,15) e "
                             "(25,15), 10 px como as luvas. A placa (13x14) fica EM CIMA das luvas e a tira passa reta entre elas, caindo "
                             "só nas pontas: não cobre o rosto. 3 quadros: 0 parado, 1 e 2 o brilho passa (6 fps, loop)."),
    "belt_regional_big": ("Fase 8a1: Cinturão do Vale grande para a tela de fim/conquista (como o belt_amateur_big). Couro preto com costura, "
                          "placa de ouro com esmalte azul (dois morros e o vale) e VALE, 4 plaquinhas laterais. 0 parado, 1-2 brilho (loop)."),
    "icon_belt_regional": "Fase 8a1: Cinturão do Vale 16x16 (resumo, carreira com cinturão, summary.belts). Tira preta + placa de ouro.",
    "icon_belt_regional_9": "Fase 8a1: Cinturão do Vale 9x9 (prévia 'SE VENCER', mural, HUD).",
    "wall_poster_league_regional_gym": ("Fase 8a1: cartaz da LIGA REGIONAL DO VALE na parede da academia, em cima da porta "
                                        "(layout.gym_league_poster_spot), a partir do marco regional_league_opened. 38x54. LIGA / DO VALE / foto "
                                        "do James em 2 tons / JAMES. Texto inteiro no hover (objects.regional_poster) ou no zoom."),
    "ui_poster_league_regional_zoom": ("Fase 8a1 (opcional): o cartaz grande para a dica/janela (112x148): LIGA REGIONAL DO VALE, foto, CAMPEÃO: "
                                       "JAMES BLINDADO, \"O QUE A BALA NÃO FURA\", CLUBE FERROVIÁRIO. Pode ampliar 2x inteiro."),
    "adv_iron_chin": "Fase 8a1: passiva do adversário QUEIXO DE FERRO (16x16): bigorna de aço com faísca, no escudinho de borda vermelha (= dele). Prévia.",
    "adv_iron_chin_9": "Fase 8a1: QUEIXO DE FERRO 9x9 (ao lado da vida dele, prévia, motivo).",
    "adv_wide_base": "Fase 8a1: passiva do adversário BASE LARGA (16x16): base aberta com os pés em 2 blocos de cimento.",
    "adv_wide_base_9": "Fase 8a1: BASE LARGA 9x9.",
    "adv_slippery": "Fase 8a1: passiva do adversário ENSABOADO (16x16): barra de sabão com bolhas.",
    "adv_slippery_9": "Fase 8a1: ENSABOADO 9x9.",
    "adv_blindado": "Fase 8a1: passiva do adversário BLINDADO (16x16): chapa de aço com rebites e faixa vermelha (guarda fechada no 1º round).",
    "adv_blindado_9": "Fase 8a1: BLINDADO 9x9 (aceso ao lado da vida dele enquanto t < 5,33 s).",
    "adv_blindado_open": "Fase 8a1: BLINDADO depois da guarda abrir (16x16): as 2 metades da chapa afastadas, cinza. Trocar junto com A GUARDA ABRIU.",
    "adv_blindado_open_9": "Fase 8a1: BLINDADO aberto 9x9 (ao lado da vida dele depois de 5,33 s).",
    "ui_banner_opp_iron_chin": "Fase 8a1: sinal AGUENTOU! (fight_opp_block_adv_iron_chin). Letreiro pequeno, branco/aço com sombra r1 (dele). 2x sobre a cabeça dele.",
    "ui_banner_opp_wide_base": "Fase 8a1: sinal NÃO CAIU (fight_opp_block_adv_wide_base). 2x sobre a cabeça dele.",
    "ui_banner_opp_slippery": "Fase 8a1: sinal ESCAPOU! (fight_opp_block_adv_slippery). 2x sobre a cabeça dele.",
    "ui_banner_guard_closed": "Fase 8a1 (opcional): GUARDA FECHADA no começo da luta contra o James. Pode ser texto.",
    "ui_banner_guard_open": "Fase 8a1: A GUARDA ABRIU (fight_guard_open) aos 5,33 s. Ouro com sombra aço (boa notícia sua). Pequeno, 1x ou 2x sobre ele.",
    "ui_balloon_tag_steel": ("Fase 8a1: plaquinha do nome do JAMES no balão (aço escuro st0, texto branco). Mesmo 9-slice das outras; o azul é do "
                             "discípulo. by_data_id.speech_bubble.tag_by_speaker.rival = steel."),
}

EXTRA = {
    "arena_regional_bg": {"pos": [0, 0], "layer": "fundo", "z": -100},
    "arena_regional_crowd_back": {"pos": [0, 180], "layer": "fundo", "z": -60, "loop": True,
                                  "anim": {"idle": [0], "cheer": [1, 0, 1, 0]}},
    "arena_regional_crowd_front": {"pos": [0, 312], "layer": "frente", "z": 50, "loop": True,
                                   "anim": {"idle": [0], "cheer": [1, 0, 1, 0]}},
    "arena_regional_ropes_side": {"pos": [0, 196], "layer": "frente", "z": 40},
    "arena_regional_spot": {"layer": "frente_do_fundo", "z": -55, "loop": True},
    "fx_guard_clink": {"loop": False},
    "belt_regional_big": {"loop": True},
    "belt_regional_raised": {"loop": True, "grips": [[15, 15], [25, 15]]},
    "ui_balloon_tag_steel": {"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 2}, "text_color": "white"},
}


def main():
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    meta = json.load(open(META, encoding="utf-8"))
    S, B, LY, FL = m["sprites"], m["by_data_id"], m["layout"], m["fight_layout"]
    for sid, d in meta.items():
        e = {"file": "res://assets/sprites/" + d["rel"], "frame_size": d["frame_size"], "frames": d["frames"],
             "fps": d["fps"], "pivot": d["pivot"]}
        e.update(EXTRA.get(sid, {}))
        e["note"] = NOTES.get(sid, "") + " " + GEN
        S[sid] = e
    # arena por liga (league_regional.json fight_arena)
    FL["arenas"]["arena_regional"] = {
        "lugar": "Liga Regional do Vale, Clube Ferroviário (noite, ringue)",
        "lamp": False,
        "ring_canvas": {"top_y": 262, "top_x": [151, 489], "bottom_y": 342, "bottom_x": [104, 536], "skirt_bottom_y": 357},
        "ground_free_x": [200, 440],
        "ropes_overlay": "arena_regional_ropes_side",
        "entrance": {
            "spot": "arena_regional_spot",
            "player_path": [[-30, 318], [90, 318], [122, 318], [190, 318], [296, 318]],
            "rope_x": 118,
            "note": ("Sugestão (UI/UX + Artista, a 'entrada no ringue' do dono): o lutador vem da esquerda pela torcida (pés atrás do público "
                     "da frente), o facho segue os pés; em x ~118 passa entre as cordas (pose curta do Artista: tronco abaixado; a camada "
                     "ropes_side por cima dá o efeito sem recorte); dentro, braço para a torcida (gesture/victory 1 quadro) e anda até 296. "
                     "O adversário já espera em 346 (o James pode fazer o gesto de desprezo ali). ~2,5 s, pulável com clique."),
        },
        "belt_raise": {"sprite": "belt_regional_raised", "pose": "victory",
                       "note": "Pivô do cinturão (20,15) no meio de hand_front/hand_back do quadro de vitória; pisca o brilho (anim 0,1,2) e o público toca cheer."},
    }
    # cartaz na academia (marco da abertura da liga)
    LY["gym_league_poster_spot"] = [412, 54]
    LY["gym_league_poster_spot_info"] = {
        "anchor": "canto de cima à esquerda", "size": [38, 54], "layer": "wall", "z": -45,
        "object_text": "regional_poster", "location": "gym", "sprite": "wall_poster_league_regional_gym",
        "click_rect": [412, 54, 38, 54], "requires_milestone": "regional_league_opened", "zoom": "ui_poster_league_regional_zoom",
        "_nota": ("Fase 8a1: em cima da porta da academia, entre o relógio de rounds (até x 395) e o pilar (x 468); abaixo do tubo (até y 44), "
                  "acima do batente da porta (y 117). Só parede lisa embaixo (conferido no gerador: 0 px de outra coisa). Longe do recorte "
                  "do vulto (340,60) e das luvas penduradas."),
    }
    # cinturão do Vale (mesma forma do belt_amateur)
    B["belt_regional"] = {"icon": "icon_belt_regional", "icon_9": "icon_belt_regional_9", "big": "belt_regional_big",
                          "raised": "belt_regional_raised"}
    # passivas dos adversários: previa().opp_passive_icon = id; _9 ao lado da vida dele
    B["opp_passives"] = {
        "adv_iron_chin": {"icon": "adv_iron_chin", "icon_9": "adv_iron_chin_9", "signal": "ui_banner_opp_iron_chin"},
        "adv_wide_base": {"icon": "adv_wide_base", "icon_9": "adv_wide_base_9", "signal": "ui_banner_opp_wide_base"},
        "adv_slippery": {"icon": "adv_slippery", "icon_9": "adv_slippery_9", "signal": "ui_banner_opp_slippery"},
        "adv_blindado": {"icon": "adv_blindado", "icon_9": "adv_blindado_9", "icon_open": "adv_blindado_open",
                         "icon_open_9": "adv_blindado_open_9", "signal_closed": "ui_banner_guard_closed",
                         "signal_open": "ui_banner_guard_open", "hit_fx": "fx_guard_clink"},
        "hud": {"icon_pos": [346, 17], "note": "Ícone 9x9 dentro da ponta esquerda da vida dele (x 346, y 17), sempre. Posição final: UI/UX."},
        "signal_pos": "acima da cabeça dele (head_point do adversário, -14 px), 2x, sobe 10 px em 0,6 s como o número de dano",
        "note": ("Fase 8a1: escudinho de borda vermelha = passiva DELE (as suas não têm borda). Sinais em branco/aço com sombra r1; "
                 "A GUARDA ABRIU em ouro. Blindado: número de dano cinza (g2) e 1x enquanto guard = true (regra do UI/UX)."),
    }
    # plaquinha do James no balão (pedido do Diretor de Cutscenes)
    sb = B["speech_bubble"]
    sb["tag_by_speaker"]["rival"] = "steel"
    sb["tag_by_color"]["steel"] = "ui_balloon_tag_steel"
    sb["tag_text_color"]["steel"] = "white"
    # moldura do retrato do James: a dourada que já existe (dono do cinturão, como o Muralha)
    B["opp_james_portrait_frame"] = {
        "frame": "ui_portrait_frame_gold",
        "note": ("Fase 8a1 (Diretor de Arte): o James usa a moldura DOURADA de sempre (dono do cinturão, como o Seu Muralha); sem "
                 "moldura nova. O retrato é portrait_opp_james (Artista de Personagens)."),
    }
    B["_nota_fase8a1_arte"] = ("Fase 8a1 (Diretor de Arte): fight_layout.arenas.arena_regional, layout.gym_league_poster_spot, belt_regional, "
                               "opp_passives, speech_bubble steel, opp_james_portrait_frame. direcao-visual.md §34, docs/arte/fase8a1-manifest.md.")
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    if out == raw:
        print("manifest: 8a1 já aplicada")
        return
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: 8a1 aplicada (%d sprites)" % len(meta))


if __name__ == "__main__":
    main()
