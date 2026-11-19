# Fase 7a1 (Diretor de Arte): registra no manifest a arena da liga, o letreiro FINALIZOU! e as peças do HUD da passiva.
# Rodar depois do make_arte_fase7a1.gd:  python tools/art/manifest_7a1.py
# Também registra as poses de Jiu-jitsu do Artista de Personagens (docs/arte/fase7a1-poses-manifest.md).
# Só acrescenta/atualiza as chaves desta lista: lê o manifest na hora de gravar e não mexe nas entradas de outros agentes.
# Mantém o formato do arquivo (tab, CRLF, UTF-8). Rodar de novo não muda nada.
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PATH = os.path.join(ROOT, "assets", "sprites", "manifest.json")
GEN = "Gerador: tools/art/make_arte_fase7a1.gd (+ manifest_7a1.py)."


def spr(file, fw, fh, frames=1, fps=0.0, pivot=(0, 0), **extra):
    d = {"file": "res://assets/sprites/" + file, "frame_size": [fw, fh], "frames": frames, "fps": fps, "pivot": list(pivot)}
    d.update(extra)
    return d


SPRITES = {
    "arena_league_bg": spr("fight/arena_league_bg.png", 640, 360, pos=[0, 0], layer="fundo", z=-100, note=(
        "Fase 7a1: arena da LIGA DA ACADEMIA (Tonhão e Kid lutam aqui; os amadores continuam na borracharia, arena_bg). "
        "Quadra coberta do bairro num sábado de manhã: treliça do telhado, janelões basculantes com sol, placar, faixa da liga, "
        "arquibancada de concreto com gente sentada, placas de patrocinador da vizinhança, quadra de madeira e o tatame oficial "
        "(azul, borda vermelha) de y 272 a 350, x 112..528 embaixo. Pés em y 318; chão livre para os dois deitados (x ~200..440). "
        "y 0..45 é ink liso: o HUD fica ali. Luz já aplicada. Sem lâmpada (é de dia): não existe arena_league_lamp. "
        "Faixa: GINÁSIO ALVORADA (nome do Roteirista; const FAIXA do gerador). Opção A aprovada pelo dono. " + GEN)),
    "arena_league_crowd_back": spr("fight/arena_league_crowd_back.png", 640, 100, 2, 4.0, pos=[0, 180], layer="fundo", z=-60,
        loop=True, anim={"idle": [0], "cheer": [1, 0, 1, 0]}, note=(
        "Fase 7a1: público de dia na frente da mureta (pés em y≈268), roupa colorida, crianças, bandeirinhas azuis. 0 parado, "
        "1 vibrando (braços para cima, bandeira, celular). Tocar 'cheer' no golpe forte, crítico, K.O. e FINALIZOU!. " + GEN)),
    "arena_league_crowd_front": spr("fight/arena_league_crowd_front.png", 640, 48, 2, 4.0, pos=[0, 312], layer="frente", z=50,
        loop=True, anim={"idle": [0], "cheer": [1, 0, 1, 0]}, note=(
        "Fase 7a1: público na frente da câmera, só nos cantos de baixo (x 0..137 e 503..640; nunca cobre o centro). Silhueta "
        "escura com boné vermelho e, no quadro 1, uma bandeira. " + GEN)),
    "ui_banner_submission": spr("ui/ui_banner_submission.png", 161, 40, pivot=(80, 20), note=(
        "Fase 7a1: letreiro FINALIZOU! no centro da arena quando o Jiu-jitsu finaliza (mesma receita do ui_banner_ko: amarelo "
        "y1/y0, contorno ink, sombra de 1 px de fonte; a sombra é azul b1, a cor do Jiu-jitsu). Fonte 3x (o K.O.! é 4x) para "
        "caber: no jogo, ampliar 2x inteiro como o K.O. (322 px). Mesma entrada do K.O. (tremida de 2 px). " + GEN)),
    "ui_streak_pip": spr("ui/ui_streak_pip.png", 7, 7, 3, pivot=(3, 3), frames_note="0 apagada, 1 acesa, 2 acendendo (clarão de 1 quadro, ~0,08 s, depois 1).",
        note=("Fase 7a1: bolinha do EMBALO do Boxe (5 lado a lado, passo sugerido 9 px = 43 px). Vermelho do Boxe. Acende a cada "
              "acerto, apagam todas quando ele esquiva. Na prévia: 5 apagadas + o número. " + GEN)),
    "icon_tired": spr("ui/icon_tired.png", 9, 9, note=(
        "Fase 7a1: CANSADO (Boxe no 3º round): gota de suor 9x9, ao lado do texto CANSADO no HUD. " + GEN)),
    "icon_grip": spr("ui/icon_grip.png", 9, 9, note=(
        "Fase 7a1: PEGADA (Jiu-jitsu): mão fechando na gola do quimono, 9x9, na ponta da barra de pegada. " + GEN)),
    "ui_grip_bar": spr("ui/ui_grip_bar.png", 8, 6, nine_slice={"left": 1, "top": 1, "right": 1, "bottom": 1}, note=(
        "Fase 7a1: moldura da barra fina da PEGADA (9-slice 1 px; altura 6: dentro 4 px). Sugestão: sob a sua vida, x 46..281, "
        "y 29..34 (posição final do UI/UX). " + GEN)),
    "ui_grip_fill": spr("ui/ui_grip_fill.png", 4, 4, 2, tile="horizontal", frames_note="0 enchendo (azul do Jiu-jitsu), 1 cheia (mais clara; alternar 0/1 a 6 fps enquanto pisca PEGADA!).",
        note=("Fase 7a1: enchimento da barra da PEGADA, 4x4, repetir na horizontal dentro da moldura (corte no fim). " + GEN)),
    "ui_grip_tick": spr("ui/ui_grip_tick.png", 1, 4, note=(
        "Fase 7a1: marca de round dentro da barra da pegada (em 1/3 e 2/3: os 3 rounds), por cima do enchimento. " + GEN)),
    "ui_grip_mark": spr("ui/ui_grip_mark.png", 7, 5, pivot=(3, 4), note=(
        "Fase 7a1: setinha amarela 'a pegada enche aqui' em cima da barra dos 3 rounds na prévia (passive_state.grip_full_at). " + GEN)),
}

ARENA_NOTE = {
    "_nota": ("Fase 7a1: arenas por local (data/locations.json fight_arena). Mesmo contrato e mesmas posições: troca só o prefixo "
              "das camadas (<prefixo>_bg, _crowd_back, _crowd_front, _lamp opcional)."),
    "arena": {"lugar": "borracharia (amadores)", "lamp": True},
    "arena_league": {"lugar": "liga da academia (Tonhão, Kid)", "lamp": False, "mat_rect_bottom": [112, 528, 350], "mat_top_y": 272,
                     "ground_free_x": [200, 440]},
}


POSES_DOC = os.path.join(ROOT, "docs", "arte", "fase7a1-poses-manifest.md")


def json_block(text, title):
    """bloco ```json logo depois do título dado (documento do Artista de Personagens)"""
    i = text.index(title)
    a = text.index("```json", i) + len("```json")
    b = text.index("```", a)
    return json.loads(text[a:b])


def poses():
    """Poses de Jiu-jitsu do Artista de Personagens (7a1): 96 folhas + ações novas em by_data_id."""
    doc = open(POSES_DOC, "rb").read().decode("utf-8")
    sprites = json_block(doc, "## Entradas completas para `sprites`")
    acts = json_block(doc, "## by_data_id (ações novas)")
    for k, v in sprites.items():
        f = v["file"].replace("res://", "")
        assert os.path.exists(os.path.join(ROOT, f)), "falta o PNG de " + k + ": " + f
        for lay in (v.get("layers") or {}).values():
            if isinstance(lay, str) and lay.startswith("res://"):
                assert os.path.exists(os.path.join(ROOT, lay.replace("res://", ""))), "falta a camada de " + k + ": " + lay
    return sprites, acts


def main():
    pose_sprites, pose_acts = poses()
    raw = open(PATH, "rb").read().decode("utf-8")
    m = json.loads(raw)
    S = m["sprites"]
    for k, v in SPRITES.items():
        S[k] = v
    for k, v in pose_sprites.items():
        S[k] = v
    B = m["by_data_id"]
    B["player_fight"]["actions"].update(pose_acts["player_fight.actions (acrescentar)"])
    for opp, a in pose_acts["opp_*.actions (acrescentar)"].items():
        B[opp]["actions"].update(a)
    m["fight_layout"]["arenas"] = ARENA_NOTE
    out = json.dumps(m, indent="\t", ensure_ascii=False).replace("\n", "\r\n") + "\r\n"
    if out == raw:
        print("manifest: 7a1 já aplicada")
        return
    open(PATH, "wb").write(out.encode("utf-8"))
    print("manifest: 7a1 aplicada (%d da arte + %d poses)" % (len(SPRITES), len(pose_sprites)))


if __name__ == "__main__":
    main()
