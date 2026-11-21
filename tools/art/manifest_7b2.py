# Fase 7b2 (Diretor de Arte): registra no manifest a arte da 2ª passiva (cadeado e meta no cartão, ícones das 2ªs passivas,
# carga do Contragolpista, letreiros). Rodar depois do make_arte_fase7b2.gd:  python tools/art/manifest_7b2.py
# Lê os tamanhos/pivôs de tools/art/fase7b2_sprites.json (gravado pelo gerador) e só acrescenta/atualiza as chaves desta fase.
# Mantém o formato do arquivo (tab, CRLF, UTF-8). Rodar de novo não muda nada.
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
META = os.path.join(ROOT, "tools", "art", "fase7b2_sprites.json")
GEN = "Gerador: tools/art/make_arte_fase7b2.gd (+ manifest_7b2.py). direcao-visual.md §33."

NOTES = {
    "ui_passive_lock": "Cadeado da 2ª opção do cartão da arte (9x12, pivô no meio). Fica à direita do nome enquanto a meta não bate.",
    "ui_passive_progress_bar": "Moldura 9-slice (8x6, cantos de 2 px) da barra da meta '{n}/{m}' da 2ª passiva (mesma medida da ui_grip_bar).",
    "ui_passive_progress_fill": "Enchimento 4x4 repetido na horizontal dentro da moldura (área interna 4 px). Largura = interior × n/m.",
    "ui_passive_progress_tick": "Divisória 1x4 (ink) em cada 1/m da barra (m = unlock.count; hoje 3 → 2 divisórias).",
    "ui_passive_goal_pip": "Estrelinha da meta (alternativa à barra, boa para m ≤ 5): 1 por vitória pela 1ª passiva, passo 9 px.",
    "passive_counter_punch": "Ícone da 2ª passiva do Boxe, Contragolpista (16x16): luva em guarda alta + seta que desce e volta (esquiva e contragolpe). Cartão da arte, prévia, tela de fim.",
    "passive_counter_punch_9": "Contragolpista 9x9: linha da prévia, motivo da derrota, HUD.",
    "passive_counter_punch_locked": "Contragolpista trancado (cinza + cadeado), para a 2ª opção antes da meta.",
    "passive_top_control": "Ícone da 2ª passiva do Jiu-jitsu, Por cima (16x16): seta azul pressionando quem está deitado no tatame. Cartão, prévia, fim.",
    "passive_top_control_9": "Por cima 9x9: prévia, motivo e HUD (estado 'no chão'; com ele de pé, o UI/UX apaga o ícone ou mostra LEVANTOU).",
    "passive_top_control_locked": "Por cima trancado (cinza + cadeado).",
    "passive_thai_clinch": "Ícone da 2ª passiva do Muay Thai, Clinch (16x16): braços fechando atrás da nuca dele (faixa laranja no pulso) e o joelho subindo. Cartão, prévia, fim.",
    "passive_thai_clinch_9": "Clinch 9x9: prévia, motivo e HUD (aceso enquanto clinch = true).",
    "passive_thai_clinch_locked": "Clinch trancado (cinza + cadeado).",
    "ui_charge_pip": "Carga do Contragolpista (losango 9x9; o embalo da 1ª é bolinha 7x7). 3 com passo 11 px ao lado da SUA vida. Evento charge 0–3 = quantos acesos.",
    "icon_charge": "Carga 9x9 (um losango aceso) para a linha da prévia e o motivo da derrota do Contragolpista.",
    "ui_banner_counter_ko": "Letreiro K.O. NO CONTRAGOLPE! (fight_counter_ko) em 2 linhas (quebra automática do gerador), sombra vermelha r1 do Boxe. No centro da arena (320,118), 2x inteiro, mesma entrada do K.O.! (tremida de 2 px). Troca o K.O.! quando finish = counter_ko.",
    "ui_banner_ground_stop": "Letreiro O JUIZ PAROU! (fight_ground_stop), sombra azul b1 do Jiu-jitsu, (320,118) 2x. Troca o FINALIZOU! quando finish = ground_stop.",
    "ui_banner_knee_ko": "Letreiro JOELHADA! (fight_knee_ko), sombra laranja br1 do Muay Thai, (320,118) 2x. Troca o K.O.! quando finish = knee_ko.",
    "ui_banner_charge_full": "Letreiro pequeno CARGA! (fight_charge_full), fonte 2x, sombra r1. Pisca com as 3 cargas cheias (como PERNA CHEIA!). Se o UI/UX preferir texto, pode ignorar.",
    "ui_banner_stood_up": "Letreiro pequeno LEVANTOU (fight_stood_up), fonte 2x, sombra b1. Quando ele levanta no Por cima. Opcional (pode ser texto).",
    "ui_banner_clinch": "Letreiro pequeno CLINCH! (fight_clinch), fonte 2x, sombra br1. Quando prende. Opcional (pode ser texto).",
}

EXTRA = {
    "ui_passive_lock": {"frames_note": "0 trancado (cinza), 1 clarão (1 quadro ~0,08 s ao bater a meta), 2 aberto (ouro; depois some em fade e a opção acende)."},
    "ui_passive_progress_bar": {"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 2}},
    "ui_passive_progress_fill": {"frames_note": "0 enchendo (ouro y0), 1 cheia (y1 claro) quando n ≥ m."},
    "ui_passive_goal_pip": {"frames_note": "0 falta, 1 feita (ouro), 2 acendendo (clarão de 1 quadro, depois 1)."},
    "ui_charge_pip": {"frames_note": "0 vazia, 1 carregada, 2 acendendo (clarão de 1 quadro ~0,08 s, depois 1), 3 cheia (alternar 1/3 a 6 fps com CARGA!)."},
}


def main():
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    meta = json.load(open(META, encoding="utf-8"))
    S, B = m["sprites"], m["by_data_id"]
    for sid, d in meta.items():
        e = {"file": "res://assets/sprites/" + d["rel"], "frame_size": d["frame_size"], "frames": d["frames"],
             "fps": d["fps"], "pivot": d["pivot"]}
        e.update(EXTRA.get(sid, {}))
        e["note"] = NOTES.get(sid, "") + " " + GEN
        S[sid] = e
    for art, p2 in [("boxing", "counter_punch"), ("bjj", "top_control"), ("muay_thai", "thai_clinch")]:
        B[art]["passive_2_icon"] = "passive_" + p2
        B[art]["passive_2_icon_9"] = "passive_%s_9" % p2
        B[art]["passive_2_icon_locked"] = "passive_%s_locked" % p2
    B["passive_2_card"] = {
        "lock": "ui_passive_lock", "bar": "ui_passive_progress_bar", "fill": "ui_passive_progress_fill",
        "tick": "ui_passive_progress_tick", "goal_pip": "ui_passive_goal_pip", "goal_pip_step_px": 9,
        "icons": {"counter_punch": "passive_counter_punch", "top_control": "passive_top_control", "thai_clinch": "passive_thai_clinch"},
        "mockup": "docs/arte/mockups/fase7b2_cartao_x2.png",
        "note": ("Fase 7b2: 2ª opção do cartão da arte. Trancada: ícone _locked, nome em g1, linha '{n}/{m} {fim}' em y1 (texto pela fonte "
                 "do tema), barra (ou estrelas) embaixo e o cadeado (quadro 0) à direita. Meta batida: cadeado 0→1→2 e some; ícone "
                 "colorido. Posição e medida finais são do UI/UX."),
    }
    B["counter_hud"] = {"pip": "ui_charge_pip", "count": 3, "step_px": 11, "icon": "icon_charge", "banner_full": "ui_banner_charge_full",
                        "note": "Fase 7b2: 3 losangos ao lado da SUA vida (sugestão: abaixo dela, a partir de x 50, y 35). Acende conforme o evento charge."}
    B["passive_2_banners"] = {
        "counter_ko": "ui_banner_counter_ko", "ground_stop": "ui_banner_ground_stop", "knee_ko": "ui_banner_knee_ko",
        "small": {"charge_full": "ui_banner_charge_full", "stood_up": "ui_banner_stood_up", "clinch": "ui_banner_clinch"},
        "banner_pos": [320, 118], "banner_scale": 2,
        "note": "Fase 7b2: o letreiro do fim pelo finish (counter_ko/ground_stop/knee_ko); mesma entrada do K.O.!. Pivô no meio do PNG.",
    }
    B["_nota_fase7b2_arte"] = ("Fase 7b2 (Diretor de Arte): passive_2_card, counter_hud, passive_2_banners, boxing/bjj/muay_thai.passive_2_icon*. "
                               "direcao-visual.md §33, docs/arte/fase7b2-manifest.md.")
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    if out == raw:
        print("manifest: 7b2 já aplicada")
        return
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: 7b2 aplicada (%d sprites)" % len(meta))


if __name__ == "__main__":
    main()
