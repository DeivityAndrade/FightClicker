# Fase 7b1 (Artista de Personagens): monta docs/arte/fase7b1-poses-manifest.md com as entradas das folhas do Muay Thai, no
# formato da 7a1 (blocos ```json lidos por tools/art/manifest_7b1.py, que grava o manifest).
# Uso: python tools/art/doc_manifest_7b1.py <tmp>/out_j <tmp>/out_o   (pastas gravadas por make_golpes_jogador.gd e
#      make_sprites_elenco.gd reacoes). Não grava o manifest.
import json, os, sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
J, O = sys.argv[1], sys.argv[2]
GL = ["", "_glove_l1", "_glove_l2", "_glove_l3", "_glove_l4"]
LUTA = ["mt_idle", "low_kick", "knee", "thai_clinch", "spin_kick"]
CHOQUE = ["spar_mt_push", "spar_mt_kick", "spar_mt_guard"]
LOOP = {"mt_idle", "spar_mt_guard"}
NOTA = {
    "mt_idle": "Guarda tailandesa (idle da luta com Muay Thai): luvas na testa, cotovelos fechados, pé da frente leve; o "
               "calcanhar da frente sobe e desce no ritmo. Começo e fim de todos os golpes do Muay Thai.",
    "low_kick": "Chute baixo (perna de trás na coxa da frente dele). hit_point = canela. Reação dele: hit_leg.",
    "knee": "Joelhada (joelho de trás na barriga, com passo para dentro; o corpo desliza até 13 px e volta). Reação: hit_body.",
    "thai_clinch": "Clinch tailandês (dois corpos): pega a nuca no hit_frame 2 (a reação held_clinch começa aqui e termina "
                   "junto), puxa para baixo e dá a joelhada no quadro 5 (bom quadro para o número/impacto extra). Reação: held_clinch.",
    "spin_kick": "Chute rodado (perna de trás no rosto) com passo de 12 px para a frente dentro do quadro (o pivô não muda; o "
                 "passo volta no fim). Contato segura 3 quadros. Reação: fall_spin (derrubou) ou hit_spin (aguentou).",
    "spar_mt_push": "Choque Muay Thai, clique fora do tempo: empurrão curto com as duas mãos. Reação do parceiro: "
                    "spar_partner_box_recoil.",
    "spar_mt_kick": "Choque Muay Thai, 3º clique no tempo = CHUTE: teep (sola do pé da frente na barriga). Reação do parceiro: "
                    "spar_partner_box_recoil.",
    "spar_mt_guard": "Choque Muay Thai, segurando: guarda fechada com a canela levantada (loop).",
}
NOTA_ADV = {
    "hit_leg": "Fase 7b1: levou o chute baixo na coxa da frente (o joelho dobra, o pé sai do chão, o tronco desaba e volta). "
               "Reação ao low_kick; começar no hit_frame do golpe.",
    "limp": "Fase 7b1: MANCANDO (idle com 2 marcas): peso no pé de trás, a perna da frente dobrada na ponta, guarda mais baixa. Loop.",
    "limp_heavy": "Fase 7b1: mancando mais torto (idle com 3 marcas): a mão da frente segura a coxa, o pé da frente sai do chão. Loop.",
    "held_clinch": "Fase 7b1: preso no clinch tailandês (começa no hit_frame 2 do thai_clinch e termina junto): puxado pela "
                   "nuca, a joelhada acerta no quadro 3, é solto e volta à guarda.",
    "hit_spin": "Fase 7b1: levou o chute rodado e NÃO caiu: a cabeça vira, o corpo torce, volta mancando para a guarda.",
    "fall_spin": "Fase 7b1: queda pelo chute rodado (K.O.): a cabeça vira, os joelhos cedem, depois o tronco, cai de costas e "
                 "fica (segurar o último quadro, como o ko). ground_frame = quadro em que bate no chão.",
}

gm = json.load(open(os.path.join(J, "golpes_manifest.json"), encoding="utf-8"))
cam = json.load(open(os.path.join(J, "disciple", "camadas_golpes.json"), encoding="utf-8"))
adv = json.load(open(os.path.join(O, "reacoes_adv_manifest.json"), encoding="utf-8"))
S = {}


def head_extra(base, view):
    an = cam[base]["anchors"]
    boxes = [a["head_box"] for a in an if a.get("head_box")]
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[0] + b[2] for b in boxes); y1 = max(b[1] + b[3] for b in boxes)
    for a in an:
        a["head_box_max"] = [x0, y0, x1 - x0, y1 - y0]
        a.setdefault("flipped", False)
    h = an[0]["head"]
    return an, [h[0], h[1] - (11 if view == "side" else 10)]


def layered(flat_id, base, gsuf, e, view):
    d = "res://assets/sprites/disciple/"
    an, ha = head_extra(base, view)
    lay = {"body": d + base + gsuf + "_disc_body.png",
           "top": {"tank": d + base + "_disc_top_tank.png", "tee": d + base + "_disc_top_tee.png"},
           "socks": d + base + "_disc_socks.png",
           "school_symbol": {"chest": d + base + "_disc_symbol_chest.png", "leg": d + base + "_disc_symbol_leg.png"},
           "head": {c: d + base + "_disc_head_%s.png" % c for c in ["short", "buzz", "volume", "bun"]},
           "band": d + base + "_disc_band.png", "front_mask": d + base + "_disc_front.png",
           "order": ["body", "top", "socks", "school_symbol", "head", "band", "front_mask"]}
    out = {k: e[k] for k in ["action", "facing", "fps", "frame_size", "frames", "loop", "pivot", "hit_frame", "hit_point", "positions"] if k in e}
    out.update({"file": lay["body"], "palette_swap": "disciple_palette", "same_as": flat_id, "who": "discipulo",
                "layers": lay, "head_anchor": ha, "anchors": an,
                "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de %s; montar na ordem de "
                        "layers.order e trocar as cores-chave (by_data_id.disciple_palette)." % flat_id})
    return out


for nm in LUTA + CHOQUE:
    for g in GL:
        k = "fight_player_%s%s_disc" % (nm, g)
        e = dict(gm[k])
        e["loop"] = nm in LOOP
        e["who"] = "discipulo"
        e["note"] = "Fase 7b1: " + NOTA[nm]
        S[k] = e
        S[k + "_layered"] = layered(k, "fight_player_" + nm, g, e, "side")
for g in GL:
    k = "fighter_low_kick%s_disc" % g
    e = dict(gm[k])
    e["frame_size"] = [int(v) for v in e["frame_size"]]
    e["pivot"] = [int(v) for v in e["pivot"]]
    e["hit_frame"] = int(e["hit_frame"])
    e["positions"] = {"foco_saco": [303, 272]}
    e["action"] = "low_kick"
    e["who"] = "discipulo"
    e["note"] = ("Fase 7b1: chute baixo no SACO COMPRIDO (kick_bag), tocado inteiro a cada clique, no lugar do fighter_punch. "
                 "Quadro 64x72 (o pé passa dos 48 px), pivô (22,67) igual ao do fighter_punch em foco_saco (303,272); "
                 "hit_point = canela no gasto da lona (326,250): disparar kick_bag_lN_hit, impacto e número no hit_frame.")
    S[k] = e
    S[k + "_layered"] = layered(k, "fighter_low_kick", g, e, "34")
for k, e in adv["sprites"].items():
    e = dict(e)
    e["frame_size"] = [int(v) for v in e["frame_size"]]
    e["pivot"] = [int(v) for v in e["pivot"]]
    e["note"] = NOTA_ADV[e["action"]]
    if e["action"] in ("limp", "limp_heavy"):
        e["loop"] = True
    S[k] = e

for k, e in S.items():
    f = e["file"].replace("res://", "")
    assert os.path.exists(os.path.join(ROOT, f)), "falta " + f

ACTS = {"player_fight.actions (acrescentar)": {nm: "fight_player_" + nm for nm in LUTA},
        "opp_*.actions (acrescentar)": adv["actions"]}
SPAR = {"idle": "fight_player_mt_idle", "click": "fight_player_spar_mt_push", "kick": "fight_player_spar_mt_kick",
        "guard": "fight_player_spar_mt_guard", "pushed": "fight_player_spar_box_recoil"}

linhas = []
for k in sorted(S):
    e = S[k]
    if k.endswith("_layered"):
        continue
    hit = "-"
    if "hit_frame" in e and "hit_point" in e:
        hit = "%s / %s" % (e["hit_frame"], [round(float(v), 1) for v in e["hit_point"]])
    elif "ground_frame" in e:
        hit = "chão %s" % e["ground_frame"]
    linhas.append("| `%s` | %dx%d | %d | %s | %s | %s | %s |" % (k, e["frame_size"][0], e["frame_size"][1], e["frames"], e["pivot"],
                  e["fps"], "sim" if e.get("loop") else "não", hit))

doc = """# Fase 7b1: poses do Muay Thai (entradas para o manifest)

Artista de Personagens. Registrado pelo `tools/art/manifest_7b1.py` (blocos `sprites` e `by_data_id` abaixo).
PNG em `assets/sprites/fight/`, `assets/sprites/disciple/` (discípulo, com camadas e as 5 luvas), `assets/sprites/characters/`
(chute no saco) e `assets/sprites/opponents/<id>/`. Nenhum arquivo antigo foi sobrescrito.

## Como foi gerado (dá para rodar de novo)
Poses em dados em `tools/art/golpes_7b1.json` e `golpes_7b1_adv.json` (autoria: `python tools/art/poses_7b1.py`).
Numa pasta temporária com `project.godot` vazio (nunca no projeto), `<repo>` = esta pasta:
```
FC_LUTADOR=disc FC_CAMADAS=1 FC_GOLPES=<repo>/tools/art/golpes_7b1.json godot --headless --path <tmp> --script <repo>/tools/art/make_golpes_jogador.gd -- <tmp>/out_j
FC_GOLPES=<repo>/tools/art/golpes_7b1_adv.json godot --headless --path <tmp> --script <repo>/tools/art/make_golpes_jogador.gd -- <tmp>/out_a nada
FIGHTCLICKER_ROOT=<repo>/ godot --headless --path <tmp> --script <repo>/tools/art/make_sprites_elenco.gd -- <tmp>/out_o <tmp>/old reacoes <tmp>/out_a/reacoes_expandidas.json
godot --headless --path <tmp> --script <repo>/tools/art/make_mockup_fase7b1_poses.gd -- <repo> <tmp>/out_j <tmp>/out_o <pranchas>
python tools/art/doc_manifest_7b1.py <tmp>/out_j <tmp>/out_o
python tools/art/manifest_7b1.py
```
Mudanças pequenas nos geradores (chaves novas e opcionais; sem elas o resultado é o mesmo de antes):
- `personagem_lib.gd`: `angf`/`angb` (luta) e `angl`/`angr` (garagem) giram o tênis (pé esticado no chute); `legs_swap` = chute
  com a perna de trás (o quadril girou: a perna que chuta sai do quadril da frente e é desenhada na frente do corpo).
- `make_golpes_jogador.gd`: `hit_key` no golpe = contato que não é a luva (canela, joelho, sola); `frame_size` nos golpes da
  garagem (o chute no saco usa 64x72).

## Contrato
- Luta: quadro 112x104, pivô (56,98), pivôs da arena 296/346 **sem mudança**. O passo do chute rodado (12 px) e da joelhada
  (13 px) é desenhado dentro do quadro e volta no fim.
- Ordem de desenho: quem ataca por cima (como hoje). No clinch, o discípulo por cima.
- Reação do adversário começa no `hit_frame` do golpe (como hoje). `held_clinch` termina junto com o `thai_clinch`;
  `fall_spin` segura o último quadro (como o `ko`).
- Treino: `fighter_low_kick` é **64x72** (o resto do treino é 48x72), mesmo pivô (22,67) em `foco_saco` (303,272).

## Pedidos ao Programador (não mexi em ui/ nem scripts/)
1. **Idle do Muay Thai:** com a arte `muay_thai`, o repouso do jogador na luta é `mt_idle` (guarda tailandesa), não `idle`.
   Todos os golpes do Muay Thai começam e terminam nessa guarda.
2. **Golpes** (`moves.json`, estilo `muay_thai`): `low_kick`, `knee`, `thai_clinch`, `spin_kick` = ações novas de `player_fight`.
   Reações: `hit_leg`, `hit_body` (já existe), `held_clinch`, `fall_spin`.
3. **Chute rodado sem derrubar:** o design manda `fall_spin` em todo rodado; mas `fall_spin` termina deitado. Fiz também
   `hit_spin` (torce e volta à guarda mancando): usar `hit_spin` quando o rodado **não** derruba e `fall_spin` só no K.O.
4. **Mancando:** idle do adversário com 2 marcas = `limp`; com 3 = `limp_heavy` (sem ela, `limp`).
5. **Saco comprido:** no foco `kick_bag`, o lutador usa `fighter_low_kick` (quadro 64x72) no lugar do `fighter_punch`
   (`by_data_id.kick_bag.fighter`). hit em (326,250).
6. **Choque do Muay Thai:** `minigame_layout.spar.player_actions.mt` (abaixo). O parceiro reaproveita as folhas do Boxe.
7. Só discípulo (`*_disc` + `_layered`), como na 7a1: a 1ª carreira não tem arte.

## Tabela (folhas planas; cada `*_disc` tem também a `_layered`)
| id | quadro | quadros | pivô | fps | loop | hit (quadro / ponto) |
|---|---|---|---|---|---|---|
""" + "\n".join(linhas) + """

## by_data_id (ações novas)
```json
%s
```

## minigame_layout.spar.player_actions.mt (acrescentar)
```json
%s
```

## Entradas completas para `sprites` (%d chaves)
```json
%s
```
""" % (json.dumps(ACTS, ensure_ascii=False, indent=1), json.dumps(SPAR, ensure_ascii=False, indent=1), len(S),
       json.dumps(S, ensure_ascii=False, indent=1))
open(os.path.join(ROOT, "docs", "arte", "fase7b1-poses-manifest.md"), "w", encoding="utf-8", newline="\n").write(doc)
print("ok: %d chaves" % len(S))
