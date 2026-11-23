# Fase 8a2 (Diretor de Arte): registra no manifest a arte do CENTRO DE TREINAMENTO RAÍZES (sala larga, LED, aparelhos _center,
# recorte do Vale emoldurado e preso no cartaz, cartaz vencido, patrocínio Autopeças Vale Forte, envelope, região CENTRO do mapa,
# ícone dos alunos) e os pontos da sala do centro. Rodar depois do make_arte_fase8a2.gd (e do manifest_8a2_personagens.py):
#   python tools/art/manifest_8a2.py
# Lê tools/art/fase8a2_sprites.json (gravado pelo gerador) e só acrescenta/atualiza as chaves desta fase. Mantém o formato
# (tab, CRLF, UTF-8). Rodar de novo não muda nada. Detalhes: docs/arte/fase8a2-manifest.md, direcao-visual.md §35.
import copy
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
META = os.path.join(ROOT, "tools", "art", "fase8a2_sprites.json")
GEN = "Gerador: tools/art/make_arte_fase8a2.gd (+ manifest_8a2.py). direcao-visual.md §35, docs/arte/fase8a2-manifest.md."

# pontos (iguais aos do gerador)
STUDENT_POS = {"student_1": [390, 250], "student_2": [436, 257], "student_3": [530, 316], "student_4": [24, 300]}
CLIP_FRAMED = [78, 96]
PHOTO = [120, 104]
ENVELOPE = [250, 302]
LEDS = {"led_1": [118, 46], "led_2": [230, 40], "led_3": [392, 40], "led_4": [522, 46]}

MATERIAL = {
    "bag": "saco de competição: couro azul-marinho da escola com faixas brancas (l1); couro vinho (l0)",
    "rope": "corda de rolamento: cabo azul com punhos pretos (l1); cabo preto com punhos amarelos (l0)",
    "treadmill": "esteira com painel: grafite com painel azul (l1); grafite com faixas amarelas (l0)",
    "speed_bag": "plataforma de pera: madeira clara e pera de couro caramelo",
    "grappling_dummy": "boneco de competição: couro vermelho com alças pretas e tatame vermelho (l1); lona grafite (l0)",
    "kick_bag": "saco de lona dupla: lona crua com alças de couro (l1); lona verde-oliva (l0)",
}
COPY_KEYS = ("positions", "loop", "sort_y", "sort_y_offset", "layer", "z", "anim", "hit_frame", "facing", "frames_note", "tick_frames")

NOTES = {
    "center_bg": ("Fase 8a2: CENTRO DE TREINAMENTO RAÍZES, sala larga no padrão da 6d2 (640x360 em 0,0; parede do fundo x 70..569 até y 220; "
                  "chão até y 329; pilares de aço x 164..174 e 468..478; ponto de fuga 320,-28; viga y 26..33 com os ganchos em x 258 e "
                  "336). Concreto pintado de branco em blocos, barrado azul da escola (y 150..219), treliça e pé-direito alto, 2 janelões "
                  "no fundo e 2 nas paredes laterais (dia), R da escola pintado, prateleira do Metrônomo (240,118), cortiça do mural "
                  "(176,128), espelho inteiro, relógio de round, porta de vidro dupla (401,116,60,104), vitrine de troféus com os 2 "
                  "cinturões, bebedouro, caixotes de pliometria, piso de borracha com placas, tatame vermelho na frente à esquerda "
                  "e fita de área de treino em volta do alvo. Os 4 painéis de LED já estão acesos no fundo. Luz já aplicada."),
    "center_led": ("Fase 8a2: painel de LED pendurado (40x8). O fundo já tem os 4 acesos: o sprite só serve para a falha opcional "
                   "(quadro 1 = apagado), como o gym_tube. Pivô = meio de cima. by_data_id.center.light_positions."),
    "wall_clipping_regional_framed": ("Fase 8a2 (D10): o recorte do jornal do Vale EMOLDURADO na parede do centro (36x36): moldura preta com "
                                      "filete de ouro, vidro com reflexo, plaquinha de latão; manchete RAÍZES legível em 1x, foto granulada do "
                                      "discípulo com o cinturão erguido, colunas. Ponto layout.center_clipping_spot. Hover: objects.regional_clipping."),
    "ui_clipping_regional_zoom": ("Fase 8a2 (opcional): o recorte grande para a dica/janela (124x92): CORREIO DA ESQUINA / ESCOLA DE GARAGEM / "
                                  "DERRUBA O BLINDADO, foto e colunas. O resto do texto (Roteirista) vai no hover."),
    "wall_poster_league_regional_won_gym": ("Fase 8a2: o cartaz da liga na academia depois do 1º Cinturão do Vale da linhagem (42x58, mesmo "
                                            "canto do de 8a1: 412,54). Adesivo do R em cima da cara do James e o recorte do jornal preso com "
                                            "fita no canto de baixo, passando um pouco da borda. Quadro 0 = sem patrocínio; quadro 1 = com a "
                                            "marca Vale Forte no canto de cima (contrato assinado). Só parede lisa embaixo (conferido)."),
    "ui_poster_league_regional_won_zoom": ("Fase 8a2 (opcional): o zoom do cartaz vencido (124x160): o de 8a1 + adesivo + recorte; quadro 1 com a marca."),
    "sponsor_vale": ("Fase 8a2: marca do patrocinador AUTOPEÇAS VALE FORTE (original): selo 20x20, engrenagem amarela com os dois morros "
                     "do Vale dentro, sobre preto. center.json sponsor.brand_sprite. Janela do contrato e cartão."),
    "sponsor_vale_wide": "Fase 8a2: selo + VALE FORTE (5x7, amarelo y1 sobre preto), para o título da janela do contrato.",
    "sponsor_vale_9": "Fase 8a2: marca 9x9 (engrenagem) para a linha PATROCÍNIO VALE FORTE: +$n da tela de vitória.",
    "sponsor_vale_patch": ("Fase 8a2: a marca no CALÇÃO do lutador (5x3, etiqueta amarela sem contorno). Sobreposição pequena, só com o "
                           "contrato assinado, nesta campanha. Ponto: anchors[q].hip do quadro + (-2,+3) (pivô do patch = meio de cima), "
                           "na frente do calção; quadros virados: espelhar o x. Vale nas folhas *_disc_layered da sala e da luta. É a 1ª "
                           "peça a cortar (escopo §9)."),
    "sponsor_envelope": ("Fase 8a2: envelope PROPOSTA no chão (16x11; pivô = meio da base). Com career.sponsor == 'offered' fica na sala até "
                         "o fim da campanha, nos 3 locais, no mesmo ponto (layout.sponsor_envelope_spot = 250,302: à esquerda dos pés do "
                         "lutador, entre o tatame e a caixa da luva). 0 parado; 1,2 brilho (tocar [0,0,0,1,2,1] a 4 fps, de vez em quando). "
                         "Camada do chão (abaixo das pessoas). Clique abre o contrato."),
    "icon_region_center": "Fase 8a2: ícone 16x16 da região CENTRO do mapa da árvore (fachada do centro com o R na empena).",
    "icon_region_center_9": "Fase 8a2: ícone 9x9 da região CENTRO (plaquinha do nome da região). Também é o icon_location_center do HUD.",
    "ui_map_region_label_center": "Fase 8a2: plaquinha da região CENTRO (9-slice 16x13, faixa azul da escola).",
    "map_tile_center_region": ("Fase 8a2: ladrilho 32x32 da região CENTRO (piso de borracha). Chave própria: 'map_tile_center' já é a cortiça "
                               "do miolo (body/career/style) em janela_mapa.gd. Ver by_data_id.skill_map.region_tiles."),
    "map_node_s_owned_steel": "Fase 8a2: anel 'aço' do nó pequeno comprado da região CENTRO (troca de cor do anel azul).",
    "map_node_b_owned_steel": "Fase 8a2: anel 'aço' do marco comprado da região CENTRO (troca de cor do anel azul).",
    "icon_students": "Fase 8a2: retrato 16x16 dos ALUNOS DA RAÍZES para o painel EQUIPE (recorte do student_1, como o icon_neighbor).",
}

# folhas do centro que reaproveitam o arquivo da academia (a luz do centro é a mesma luz fria; sem arquivo novo)
ALIASES = {
    "coach_idle_center": ("coach_idle_gym", {}),
    "coach_talk_center": ("coach_talk_gym", {}),
    "garage_crate_center": ("garage_crate_gym", {"point": "center_mentor_spot"}),
    "wall_mural_center": ("wall_mural_gym", {"point": "center_mural_spot"}),
    "wall_photo_old_center": ("wall_photo_old_gym", {"pos": PHOTO, "point": "center_photo_spot"}),
    "wall_clipping_black_cat_center": ("wall_clipping_black_cat_gym", {"point": "center_clipping_black_cat_spot"}),
    "icon_location_center": ("icon_region_center_9", {}),
}


def main():
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    meta = json.load(open(META, encoding="utf-8"))
    S, B, LY = m["sprites"], m["by_data_id"], m["layout"]
    for sid, d in meta.items():
        e = {"file": "res://assets/sprites/" + d["rel"], "frame_size": d["frame_size"], "frames": d["frames"],
             "fps": d["fps"], "pivot": d["pivot"]}
        src = d.get("from")
        if src:
            for k in COPY_KEYS:
                if k in S[src]:
                    e[k] = copy.deepcopy(S[src][k])
            base = sid.split("_l")[0]
            e["note"] = ("Fase 8a2: versão do CENTRO de %s (sufixo _center do locations.json): mesma forma, quadros, pivô, pontos e "
                         "anim; material novo (%s). %s" % (src, MATERIAL.get(base, ""), GEN))
        else:
            e["note"] = NOTES.get(sid, "") + " " + GEN
        if sid == "center_bg":
            e.update({"pos": [0, 0], "layer": "fundo", "z": -100})
        elif sid == "center_led":
            e.update({"positions": LEDS, "layer": "frente_do_fundo", "z": -50, "anim": {"idle": [0], "flicker": [1, 0, 1, 0]}})
        elif sid == "wall_clipping_regional_framed":
            e.update({"pos": CLIP_FRAMED, "point": "center_clipping_spot", "layer": "wall", "z": -45})
        elif sid == "wall_poster_league_regional_won_gym":
            e.update({"pos": [412, 54], "point": "gym_league_poster_spot", "layer": "wall", "z": -45,
                      "anim": {"won": [0], "won_sponsor": [1]}})
        elif sid == "sponsor_envelope":
            e.update({"pos": ENVELOPE, "layer": "floor", "loop": True, "anim": {"idle": [0], "shine": [0, 0, 0, 1, 2, 1]}})
        elif sid == "ui_poster_league_regional_won_zoom":
            e["anim"] = {"won": [0], "won_sponsor": [1]}
        elif sid == "ui_map_region_label_center":
            e["nine_slice"] = {"left": 4, "top": 1, "right": 1, "bottom": 1}
        S[sid] = e
    for sid, (src, extra) in ALIASES.items():
        e = copy.deepcopy(S[src])
        e.update(copy.deepcopy(extra))
        e["note"] = "Fase 8a2: no centro usa o mesmo arquivo de %s (mesma luz fria). %s" % (src, GEN)
        S[sid] = e
    # alunos: pontos conferidos na sala do centro (a luz pintada não depende do ponto)
    for sid, p in STUDENT_POS.items():
        if sid in S:
            S[sid]["pos"] = list(p)
            S[sid]["pos_note"] = ("Fase 8a2 (Diretor de Arte): ponto na sala do centro, conferido pixel a pixel com todos os quadros "
                                  "(0 sobreposição, fora da zona do alvo). student_3 fica atrás do painel fixado (como o vizinho 3 e o Nelson).")
    # pontos da sala do centro
    LY["center_coach_spot"] = [196, 236]
    LY["center_mentor_spot"] = [132, 254]
    LY["center_mentor_2_spot"] = [62, 256]
    LY["center_mural_spot"] = [176, 128]
    LY["center_clipping_black_cat_spot"] = [340, 60]
    LY["center_photo_spot"] = PHOTO
    LY["center_photo_spot_info"] = {
        "location": "center", "sprite": "wall_photo_old_center", "frame_in_game": 1, "anchor": "canto de cima à esquerda",
        "size": [18, 21], "layer": "wall", "z": -45, "object_text": "old_photo_center", "click_rect": PHOTO + [18, 21],
        "_nota": ("Fase 8a2: a foto da garagem pendurada TORTA de propósito (quadro 1) no canto da memória da ala esquerda, ao lado do "
                  "recorte emoldurado. Desde a 1ª chegada, sem condição. Parede lisa embaixo (conferido). Fora do balão do Osmar."),
    }
    LY["center_clipping_spot"] = CLIP_FRAMED
    LY["center_clipping_spot_info"] = {
        "location": "center", "sprite": "wall_clipping_regional_framed", "anchor": "canto de cima à esquerda", "size": [36, 36],
        "layer": "wall", "z": -45, "object_text": "regional_clipping", "click_rect": CLIP_FRAMED + [36, 36],
        "zoom": "ui_clipping_regional_zoom", "when": "permanent.first_regional_belt_campaign > 0 (sempre verdade no centro)",
        "_nota": "Fase 8a2 (D10): o recorte emoldurado, à esquerda da foto torta, embaixo do janelão da ala esquerda. Parede lisa embaixo.",
    }
    LY["sponsor_envelope_spot"] = ENVELOPE
    LY["sponsor_envelope_spot_info"] = {
        "locations": ["garage", "gym", "center"], "sprite": "sponsor_envelope", "pivot": "meio da base",
        "click_rect": [ENVELOPE[0] - 10, ENVELOPE[1] - 13, 20, 15], "sort_y": ENVELOPE[1] - 30, "when": "career.sponsor == 'offered'",
        "_nota": ("Fase 8a2: mesmo ponto nos 3 locais; chão livre conferido na garagem (7b), na academia e no centro; 0 px de pessoa, caixa "
                  "ou aparelho em cima no centro cheio. Desenhar na camada do chão (sort_y baixo): quem passa fica por cima."),
    }
    LY["gym_league_poster_spot_info"]["sprite_won"] = "wall_poster_league_regional_won_gym"
    LY["gym_league_poster_spot_info"]["won_rule"] = (
        "Fase 8a2: com permanent.first_regional_belt_campaign > 0, trocar pelo wall_poster_league_regional_won_gym (42x58, mesmo canto; "
        "quadro 1 com career.sponsor == 'signed'), object_text regional_poster_won (+ regional_poster_sponsor), zoom "
        "ui_poster_league_regional_won_zoom, click_rect [412,54,42,58].")
    # local
    B["center"] = {
        "bg": "center_bg", "light": "center_led", "light_positions": LEDS, "no_lamp": True,
        "icon": "icon_location_center", "suffix": "_center",
        "sprite_rule": ("nome do sprite + _center (bag_l1_idle -> bag_l1_idle_center); sem _center no manifest = usa o da garagem. "
                        "Os 6 aparelhos têm _center em TODAS as folhas (inclusive pera/boneco/saco comprido no foco: idle e hit, que hoje "
                        "a sala chama sem sufixo; passar por UiTema.com_local também ali). Osmar, caixote, mural, foto e recorte do vulto "
                        "têm entradas _center que apontam para os arquivos da academia."),
        "fighter": copy.deepcopy(B["gym"]["fighter"]),
        "metronome": {"pos": [240, 118], "note": "Mesmo ponto: a prateleira de aço do centro foi desenhada para ele."},
        "people_pos": copy.deepcopy(B["gym"]["people_pos"]),
        "students_pos": STUDENT_POS,
        "points": {"coach": "center_coach_spot", "mentor": "center_mentor_spot", "mentor_2": "center_mentor_2_spot",
                   "mural": "center_mural_spot", "photo": "center_photo_spot", "clipping": "center_clipping_spot",
                   "black_cat_clipping": "center_clipping_black_cat_spot", "envelope": "sponsor_envelope_spot",
                   "rope_hook": "layout.rope_hook (igual)", "box_slots": "layout.box_slots (iguais)"},
        "chain": "bag_chain_tile (o mesmo): os ganchos da viga do centro estão em x 336 e 258, a corrente começa em y 33.",
        "no_scenes": "Sem cena no centro (design §1.2): a porta existe, mas nenhum caminho de cena precisa ficar livre.",
        "move_arrive": "Ao mudar: corte seco para center_bg + sprites _center (como a academia). Nenhuma caixa nova.",
        "note": ("Fase 8a2 (Diretor de Arte): os mesmos pontos da academia (6d2) para Osmar, mentores, equipe antiga, aparelhos, caixas, "
                 "corda no gancho, pera na parede e Metrônomo. Novos: alunos, canto da memória (recorte emoldurado + foto torta), envelope. "
                 "Conferência pixel a pixel no gerador: 0 problemas. direcao-visual.md §35."),
    }
    cs = B.setdefault("center_students", {})
    cs["icon"] = "icon_students"
    B["sponsor_vale"] = {
        "logo": "sponsor_vale", "wide": "sponsor_vale_wide", "icon_9": "sponsor_vale_9", "shorts_patch": "sponsor_vale_patch",
        "envelope": "sponsor_envelope", "envelope_spot": "sponsor_envelope_spot", "poster_frame": 1,
        "shorts_rule": ("anchors[q].hip + (-2,+3) com o pivô do patch (2,0); espelhar o x quando a folha está virada; desenhar por cima "
                        "do calção e embaixo do front_mask (luva/braço da frente). Só com career.sponsor == 'signed'."),
        "note": "Fase 8a2: Autopeças Vale Forte (short_name VALE FORTE), a mesma marca da saia do ringue da 8a1.",
    }
    sm = B["skill_map"]
    sm["node"]["tone_by_branch_or_region"]["center"] = "steel"
    for k, kk in (("small", "s"), ("milestone", "b")):
        if k in sm["node"] and "owned_by_tone" in sm["node"][k]:
            sm["node"][k]["owned_by_tone"]["steel"] = "map_node_%s_owned_steel" % kk
    sm["region_label"]["sprites"]["center"] = "ui_map_region_label_center"
    sm["region_icons"]["center"] = "icon_region_center"
    sm["region_tiles"] = {
        "center": "map_tile_center_region",
        "_nota": ("Fase 8a2: a região nova se chama 'center', mas em janela_mapa.gd a chave de ladrilho 'center' já é o miolo "
                  "(body/career/style). Usar map_tile_center_region para a região CENTRO, e não deixar o miolo virar parede quando a "
                  "região CENTRO está fechada (aberta.get('center') hoje confunde os dois). Ver fase8a2-manifest.md."),
    }
    B["_nota_fase8a2_arte"] = ("Fase 8a2 (Diretor de Arte): by_data_id.center, center_students.icon, sponsor_vale, skill_map (steel, "
                               "região CENTRO), layout center_*, sponsor_envelope_spot, cartaz vencido. direcao-visual.md §35, "
                               "docs/arte/fase8a2-manifest.md.")
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    if out == raw:
        print("manifest: 8a2 já aplicada")
        return
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: 8a2 aplicada (%d sprites + %d atalhos)" % (len(meta), len(ALIASES)))


if __name__ == "__main__":
    main()
