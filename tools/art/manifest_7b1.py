# Fase 7b1 (Diretor de Arte): registra no manifest a arte do Muay Thai (saco comprido, ícones, HUD das marcas, letreiros,
# região MUAY THAI da árvore). Rodar depois do make_arte_fase7b1.gd:  python tools/art/manifest_7b1.py
# Lê os tamanhos/pivôs de tools/art/fase7b1_sprites.json (gravado pelo gerador) e só acrescenta/atualiza as chaves desta fase.
# Mantém o formato do arquivo (tab, CRLF, UTF-8). Rodar de novo não muda nada.
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
META = os.path.join(ROOT, "tools", "art", "fase7b1_sprites.json")
GEN = "Gerador: tools/art/make_arte_fase7b1.gd (+ manifest_7b1.py). direcao-visual.md §32."

L0 = "Saco comprido de lona cor de couro cru, cintas creme e remendo de fita prata (nível visual 0)"
L1 = "Saco comprido de vinil preto com faixas laranja e as 3 marquinhas (nível visual 1: 'Chute baixo')"

NOTES = {
    "kick_bag_l0_idle": L0 + ". No CENTRO (foco = saco de chute): pendurado BAIXO no gancho (336,190), corrente bag_chain_tile de y 33 até o pivô; corpo y 200..267 (4 px acima do chão do lutador). Pivô = gancho. Ordenar como y 266 (o lutador em 303,272 fica na frente).",
    "kick_bag_l0_hit": L0 + ". Reação ao clique: o pé do saco vai 5 px para a direita e afunda na altura da canela (0), volta (1, 2), assenta (3); depois _idle. Efeito em fx_pos.",
    "kick_bag_l1_idle": L1 + ". Mesmo ponto e contrato do kick_bag_l0_idle.",
    "kick_bag_l1_hit": L1 + ". Mesma reação do kick_bag_l0_hit.",
    "kick_bag_l0_rest": L0 + ". DESCANSO (foco em outro aparelho): deitado de lado no chão no canto da frente à esquerda (slot 'art' 192,318, o mesmo do boneco), tiras e corrente enrolada à esquerda; luz da garagem pintada. Ordenar como y 306.",
    "kick_bag_l0_rest_gym": L0 + ". Descanso na academia (em cima do tatame da frente, luz dos tubos).",
    "kick_bag_l1_rest": L1 + ". Descanso na garagem (luz pintada).",
    "kick_bag_l1_rest_gym": L1 + ". Descanso na academia (luz dos tubos).",
    "icon_kick_bag": "Saco comprido 16x16 (LOJA, cartão de compra, linha de treino).",
    "icon_kick_bag_locked": "Silhueta do saco comprido com cadeado cinza (trancado ou sem Treino).",
    "icon_kick_bag_locked_buyable": "Silhueta do saco comprido com cadeado dourado (dá para comprar agora).",
    "art_muay_thai": "Ícone da arte Muay Thai 16x16: perna no chute de frente (calção laranja, faixa no tornozelo, sola para a frente) com riscos. Janela de arte, cartão, resumo.",
    "art_muay_thai_9": "Muay Thai 9x9: HUD da arte (art_hud) e botão de foco do saco comprido.",
    "art_card_muay_thai": "Ilustração do cartão do Muay Thai (72x56): o saco comprido balançando depois do chute e a canela chegando, fundo de couro escuro.",
    "ui_art_card_header_muay_thai": "Faixa do nome da arte no alto do cartão (Muay Thai = laranja de couro, br1/br2/br0). Nome 2x branco com sombra ink, art_muay_thai à esquerda.",
    "ui_shin_mark": "Marca na perna DELE (HUD do Muay Thai): canela virada para a esquerda com o hematoma. 3 lado a lado, passo 12 px, ao lado da vida dele (posição final do UI/UX). Na prévia: 3 apagadas.",
    "icon_shin": "Perna marcada 9x9: linha da passiva na prévia e motivo da derrota do Muay Thai.",
    "ui_banner_spin_kick": "Letreiro CHUTE RODADO! (texto final do Roteirista, fight_spin_kick) no centro da arena em (320,118), ampliado 2x inteiro como o K.O.! e o FINALIZOU! (~430 px). Mesma receita (amarelo y1/y0, contorno ink); sombra laranja br1 (cor do Muay Thai). Mesma entrada do K.O. (tremida de 2 px).",
    "ui_banner_marks_full": "Letreiro pequeno PERNA CHEIA! (fight_marks_full), fonte 2x, mesma receita. Para piscar junto das 3 marcas cheias (1x no HUD ou 2x perto do adversário: decisão do UI/UX). Se o UI/UX preferir texto, pode ignorar.",
    "icon_region_muay_thai": "Região MUAY THAI 16x16: o mongkol (cordão trançado da cabeça) em cima da corda da região. Também é o ícone provisório dos marcos da região.",
    "icon_region_muay_thai_9": "Região MUAY THAI 9x9 (plaquinha ui_map_region_label_muay_thai).",
    "skill_style_muay_thai": "Nó style_muay_thai 'Canela de ferro': canela de aço estalando (estrela de crítico).",
    "skill_shin_kick": "Nó mt_shin 'Chute na coxa': perna dele com 3 marcas e o risco do chute chegando.",
    "skill_thai_oil": "Nó mt_oil 'Óleo de massagem': frasco âmbar com rótulo e gota.",
    "skill_thai_rope": "Nó mt_rope 'Corda na ponta do pé': corda de pular passando sob o pé na ponta.",
    "map_tile_muay_thai": "Ladrilho 32x32 da região MUAY THAI: corda de cânhamo trançada (br0..br3), emenda nas 4 direções.",
    "map_node_s_owned_orange": "Nó pequeno comprado, anel laranja (br2/br3) do Muay Thai + tachinha.",
    "map_node_b_owned_orange": "Marco comprado, anel laranja (br2/br3) do Muay Thai + tachinha.",
    "ui_map_region_label_muay_thai": "Plaquinha da região MUAY THAI (9-slice 16x13, faixa laranja).",
}

EXTRA = {
    "kick_bag_l0_idle": {"loop": True, "positions": {"centro": [336, 190]}, "sort_y": 266},
    "kick_bag_l1_idle": {"loop": True, "positions": {"centro": [336, 190]}, "sort_y": 266},
    "kick_bag_l0_hit": {"loop": False, "positions": {"centro": [336, 190]}, "sort_y": 266, "hit_point": [326, 250]},
    "kick_bag_l1_hit": {"loop": False, "positions": {"centro": [336, 190]}, "sort_y": 266, "hit_point": [326, 250]},
    "kick_bag_l0_rest": {"positions": {"canto": [192, 318]}, "sort_y": 306},
    "kick_bag_l1_rest": {"positions": {"canto": [192, 318]}, "sort_y": 306},
    "kick_bag_l0_rest_gym": {"positions": {"canto": [192, 318]}, "sort_y": 306},
    "kick_bag_l1_rest_gym": {"positions": {"canto": [192, 318]}, "sort_y": 306},
    "ui_shin_mark": {"frames_note": "0 apagada, 1 acesa (marcou), 2 acendendo (clarão de 1 quadro ~0,08 s, depois 1), 3 cheia (alternar 1/3 a 6 fps com PERNA CHEIA!)."},
    "ui_map_region_label_muay_thai": {"nine_slice": {"left": 4, "top": 1, "right": 1, "bottom": 1}},
    "ui_art_card_header_muay_thai": {"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 3}, "text_color": "white"},
}

FOCUS_NOTE = ("Fase 7b1: o lutador usa fighter_punch até existir a pose de chute baixo no saco (Artista de Personagens; contato da "
              "canela em hit_point 326,250, no gasto da lona). Saco do Muay Thai, só com a arte muay_thai.")

POSES_DOC = os.path.join(ROOT, "docs", "arte", "fase7b1-poses-manifest.md")
KICK_NOTE = ("Fase 7b1: no foco do saco comprido o lutador usa fighter_low_kick (quadro 64x72, pivô 22,67 em foco_saco 303,272; "
             "chute baixo inteiro a cada clique, canela no saco em 326,250 no hit_frame). Saco do Muay Thai, só com a arte muay_thai.")


def json_block(text, title):
    """bloco ```json logo depois do título dado (documento do Artista de Personagens)"""
    i = text.index(title)
    a = text.index("```json", i) + len("```json")
    b = text.index("```", a)
    return json.loads(text[a:b])


def poses():
    """Poses do Muay Thai do Artista de Personagens (docs/arte/fase7b1-poses-manifest.md, gerado por doc_manifest_7b1.py).
    Sem o documento, devolve vazio (a arte do Diretor de Arte entra sozinha)."""
    if not os.path.exists(POSES_DOC):
        return {}, {}, {}
    doc = open(POSES_DOC, "rb").read().decode("utf-8")
    sprites = json_block(doc, "## Entradas completas para `sprites`")
    acts = json_block(doc, "## by_data_id (ações novas)")
    spar = json_block(doc, "## minigame_layout.spar.player_actions.mt")
    for k, v in sprites.items():
        f = v["file"].replace("res://", "")
        assert os.path.exists(os.path.join(ROOT, f)), "falta o PNG de " + k + ": " + f
        for lay in (v.get("layers") or {}).values():
            for lv in (lay.values() if isinstance(lay, dict) else [lay]):
                if isinstance(lv, str) and lv.startswith("res://"):
                    assert os.path.exists(os.path.join(ROOT, lv.replace("res://", ""))), "falta a camada de " + k + ": " + lv
    return sprites, acts, spar


def main():
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    meta = json.load(open(META, encoding="utf-8"))
    S, B, Lay = m["sprites"], m["by_data_id"], m["layout"]
    for sid, d in meta.items():
        e = {"file": "res://assets/sprites/" + d["rel"], "frame_size": d["frame_size"], "frames": d["frames"],
             "fps": d["fps"], "pivot": d["pivot"]}
        e.update(EXTRA.get(sid, {}))
        e["note"] = NOTES.get(sid, "") + " " + GEN
        S[sid] = e
    B["kick_bag"] = {"art": "muay_thai", "idle": "kick_bag_lN_idle", "click": "kick_bag_lN_hit", "side": "kick_bag_lN_rest",
                     "side_pos": "canto", "fighter": "fighter_punch", "fighter_pos": [303, 272], "fx": "fx_impact",
                     "fx_pos": [326, 250], "icon": "icon_kick_bag", "focus_icon": "art_muay_thai_9",
                     "focus_button": "ui_button_focus_art", "foco": "foco_saco_comprido", "chain_from_y": 33,
                     "placeholder_note": FOCUS_NOTE,
                     "gym_suffix_note": "Na academia: side = kick_bag_lN_rest_gym. idle/hit são os mesmos (sem luz pintada)."}
    base = B["unlock_grappling_dummy"]
    B["unlock_kick_bag"] = {
        "apparatus": "kick_bag", "requires": "treadmill", "icon_locked": "icon_kick_bag_locked",
        "icon_locked_buyable": "icon_kick_bag_locked_buyable", "focus_button": base["focus_button"], "card": base["card"],
        "card_flash": base["card_flash"],
        "arrive": {"sprite": "kick_bag_l0_rest", "drop": {"offsets_y": [-18, -8, -2, 0, 1, 0], "fps": 24.0, "shake_px": 1, "shake_frames": 2},
                   "fx": "fx_arrive_dust_small", "fx_pos": [192, 318],
                   "note": "Sai da caixa grande e cai deitado no canto (como o boneco): desenhar kick_bag_l0_rest deslocado pelos offsets; no 0, fx_arrive_dust_small e tremida de 1 px. Na academia, sufixo _gym."},
        "text_keys": base["text_keys"], "box": {"sprite": "box_big", "pos": [192, 318]}, "room_before_box": "nothing"}
    box = B["box"]
    box["sprite_by_item"]["kick_bag"] = "box_big"
    box["slot_by_item"]["kick_bag"] = "art"
    B["muay_thai"] = {"icon": "art_muay_thai", "icon_9": "art_muay_thai_9", "card_art": "art_card_muay_thai",
                      "card_header": "ui_art_card_header_muay_thai", "apparatus": "kick_bag", "color": "br2"}
    B["art_hud"]["icons"]["muay_thai"] = "art_muay_thai_9"
    B["shin_hud"] = {"mark": "ui_shin_mark", "count": 3, "step_px": 12, "icon": "icon_shin", "banner_full": "ui_banner_marks_full",
                     "banner_spin_kick": "ui_banner_spin_kick", "banner_pos": [320, 118], "banner_scale": 2,
                     "note": "Fase 7b1: 3 marcas ao lado da vida DELE (UI/UX decide o ponto; sugestão: abaixo da barra dele, alinhadas à direita em x 594, y 31). Acende 1 por marca inteira (quadro 2 por 1 quadro, depois 1). Cheias: alternar 1/3 a 6 fps e PERNA CHEIA!. O adversário mancando é animação (limp) do Artista de Personagens."}
    Lay["foco_saco_comprido"] = {"saco": "bag_lN_side em lado_esquerdo", "corda": "rope_lN_idle no prego",
                                 "esteira": "treadmill_lN_side em lado_direito", "saco_comprido": "kick_bag_lN_idle/hit em centro (336,190)",
                                 "lutador": "fighter_idle/punch em foco_saco (303,272)"}
    sm = B["skill_map"]
    sm["world"]["tiles"]["muay_thai"] = "map_tile_muay_thai"
    sm["node"]["tone_by_branch_or_region"]["muay_thai"] = "orange"
    sm["node"]["small"]["owned_by_tone"]["orange"] = "map_node_s_owned_orange"
    sm["node"]["big"]["owned_by_tone"]["orange"] = "map_node_b_owned_orange"
    if "muay_thai" not in sm["node"]["region_order"]:
        sm["node"]["region_order"].append("muay_thai")
    sm["region_label"]["sprites"]["muay_thai"] = "ui_map_region_label_muay_thai"
    sm["region_icons"]["muay_thai"] = "icon_region_muay_thai"
    sm["icon_by_node"].update({"style_muay_thai": "skill_style_muay_thai", "mt_shin": "skill_shin_kick",
                               "mt_oil": "skill_thai_oil", "mt_rope": "skill_thai_rope"})
    sm["icon_by_effect"]["art_rule_bonus"]["muay_thai"] = "skill_style_muay_thai"
    sm["icon_by_effect"]["art_fight_bonus"]["muay_thai"] = "skill_shin_kick"
    sm["milestone_icons"]["mt_shin"] = "skill_shin_kick"
    sm["_nota_7b1"] = ("Fase 7b1: região MUAY THAI = corda trançada (map_tile_muay_thai), anel laranja. A lista de ladrilhos de "
                       "ui/janela_mapa.gd (_pintar_fundo) precisa ganhar 'muay_thai' (UI/UX/Programador).")
    pose_sprites, pose_acts, pose_spar = poses()
    if pose_sprites:
        for k, v in pose_sprites.items():
            S[k] = v
        B["player_fight"]["actions"].update(pose_acts["player_fight.actions (acrescentar)"])
        for opp, a in pose_acts["opp_*.actions (acrescentar)"].items():
            B[opp]["actions"].update(a)
        B["kick_bag"]["fighter"] = "fighter_low_kick"
        B["kick_bag"]["placeholder_note"] = KICK_NOTE
        Lay["foco_saco_comprido"]["lutador"] = "fighter_idle em foco_saco (303,272); clique = fighter_low_kick (64x72, mesmo pivô)"
        m["minigame_layout"]["spar"]["player_actions"]["mt"] = pose_spar
        B["_nota_fase7b1_poses"] = ("Fase 7b1 (Artista de Personagens): golpes do Muay Thai (mt_idle, low_kick, knee, thai_clinch, "
                                    "spin_kick), reações dos adversários (hit_leg, limp, limp_heavy, held_clinch, hit_spin, fall_spin), "
                                    "Choque (spar_mt_*) e o chute no saco. docs/arte/fase7b1-poses-manifest.md.")
    B["_nota_fase7b1_arte"] = ("Fase 7b1 (Diretor de Arte): kick_bag, unlock_kick_bag, box (kick_bag), muay_thai, art_hud.icons, "
                               "shin_hud, layout.foco_saco_comprido, skill_map (região muay_thai). direcao-visual.md §32.")
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    if out == raw:
        print("manifest: 7b1 já aplicada")
        return
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: 7b1 aplicada (%d sprites)" % len(meta))


if __name__ == "__main__":
    main()
