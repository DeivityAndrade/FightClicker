# Fase 7a2 (Artista de Personagens): monta docs/arte/fase7a2-personagens-manifest.md (e a cópia fase7a2-poses-manifest.md)
# com as entradas das folhas do Choque e da Panfletagem, no formato da 7a1 (lido por tools/art/manifest_7a2.py do Diretor de Arte).
# Uso: python tools/art/doc_manifest_7a2.py <tmp>/out_j <tmp>/out   (pastas gravadas por make_golpes_jogador.gd e make_sprites_fase7a2.gd)
# Não grava o manifest.
import json, os, sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
J, O = sys.argv[1], sys.argv[2]
GL = ["", "_glove_l1", "_glove_l2", "_glove_l3", "_glove_l4"]
SPAR = ["spar_box_idle", "spar_box_push", "spar_box_counter", "spar_box_guard", "spar_box_recoil",
        "spar_jj_take", "spar_jj_grip", "spar_jj_pull", "spar_jj_release", "spar_jj_yanked"]
FLYER = ["flyer_idle", "flyer_give", "flyer_miss"]
LOOP = {"spar_box_idle", "spar_box_guard", "spar_jj_grip", "spar_jj_pull", "spar_jj_release", "flyer_idle"}
NOTA = {
    "spar_box_idle": "Choque Boxe parado (guarda, respiração).",
    "spar_box_push": "Choque Boxe, cada clique: jab curto que empurra. Reação dele: spar_partner_box_recoil.",
    "spar_box_counter": "Choque Boxe, clique na PAUSA dele (x2): direto de trás com o quadril. Reação dele: spar_partner_box_recoil.",
    "spar_box_guard": "Choque Boxe, segurando (guarda fechada): loop enquanto segura; anula a rajada.",
    "spar_box_recoil": "Choque Boxe: empurrado para trás (ele empurrou / ENCOSTOU em você).",
    "spar_jj_take": "Choque JJ: da guarda para a pegada (gola + manga). Tocar AO CONTRÁRIO ao soltar.",
    "spar_jj_grip": "Choque JJ parado com a pegada (respira).",
    "spar_jj_pull": "Choque JJ segurando = puxa (loop enquanto segura).",
    "spar_jj_release": "Choque JJ solto (recupera o fôlego), perto dele.",
    "spar_jj_yanked": "Choque JJ: segurou na PUXADA FORTE dele e foi puxado meio passo.",
    "flyer_idle": "Panfletagem parado: maço de panfletos no peito, mãos nuas (as 5 luvas dão o mesmo corpo).",
    "flyer_give": "Panfletagem ACEITOU: tira um panfleto e estende para a frente (hit_frame = panfleto na mão estendida; soltar o ui_flyer_fly daí).",
    "flyer_miss": "Panfletagem NÃO, VALEU: oferece, a pessoa recusa, recolhe e dá de ombros.",
}

gm = json.load(open(os.path.join(J, "golpes_manifest.json"), encoding="utf-8"))
cam = json.load(open(os.path.join(J, "disciple", "camadas_golpes.json"), encoding="utf-8"))
mg = json.load(open(os.path.join(O, "manifest_7a2.json"), encoding="utf-8"))

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
    out = {k: e[k] for k in ["action", "facing", "fps", "frame_size", "frames", "loop", "pivot"] if k in e}
    out.update({"file": lay["body"], "palette_swap": "disciple_palette", "same_as": flat_id, "who": "discipulo",
                "layers": lay, "head_anchor": ha, "anchors": an,
                "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de %s; montar na ordem de "
                        "layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo "
                        "(folha não espelhada)." % flat_id})
    return out


for nm in SPAR:
    for g in GL:
        k = "fight_player_%s%s_disc" % (nm, g)
        e = dict(gm[k])
        e["loop"] = nm in LOOP
        e["who"] = "discipulo"
        e["note"] = "Fase 7a2: " + NOTA[nm]
        S[k] = e
        S[k + "_layered"] = layered(k, "fight_player_" + nm, g, e, "side")
for nm in FLYER:
    for g in GL:
        k = "fighter_%s%s_disc" % (nm, g)
        e = dict(gm[k])
        e.pop("positions", None)
        e["loop"] = nm in LOOP
        e["action"] = nm
        e["who"] = "discipulo"
        e["hit_point"] = None
        e.pop("hit_point")
        if nm == "flyer_give":
            e["hand_flyer"] = [15, -41]   # mão estendida com o panfleto no hit_frame (relativo ao pivô)
        else:
            e.pop("hit_frame", None)
        e["note"] = "Fase 7a2: " + NOTA[nm] + " Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
        S[k] = e
        S[k + "_layered"] = layered(k, "fighter_" + nm, g, e, "34")
for k, e in mg.items():
    e = dict(e)
    nota = e.pop("_nota", "")
    e["note"] = "Fase 7a2: " + nota + (" Virado para a ESQUERDA (o pivô continua 56,98)." if k.startswith("spar_partner") else
                                       " Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).")
    e["who"] = "parceiro" if k.startswith("spar_partner") else "pedestre"
    S[k] = e

for k, e in S.items():
    f = e["file"].replace("res://", "")
    assert os.path.exists(os.path.join(ROOT, f)), "falta " + f

PARC = {"box": ["idle", "push", "recoil", "warn", "burst", "pause", "feint"],
        "jj": ["take", "grip", "pull", "yanked", "warn", "yank", "pause", "feint"]}
TIPOS = ["estudante", "senhora", "trabalhador", "moca"]
DICA = {"estudante": "pockets", "senhora": "crossed", "trabalhador": "hurry", "moca": "phone"}
LAYOUT = {
    "spar": {
        "player_actions": {"box": {"idle": "fight_player_spar_box_idle", "click": "fight_player_spar_box_push",
                                   "counter": "fight_player_spar_box_counter", "guard": "fight_player_spar_box_guard",
                                   "pushed": "fight_player_spar_box_recoil"},
                           "jj": {"take": "fight_player_spar_jj_take", "release": "fight_player_spar_jj_take (ao contrário)",
                                  "grip": "fight_player_spar_jj_grip", "hold": "fight_player_spar_jj_pull",
                                  "free": "fight_player_spar_jj_release", "yanked": "fight_player_spar_jj_yanked"}},
        "player_sheet_note": "Ids sem o sufixo: o jogo acrescenta a luva (_glove_lN) e _disc / _disc_layered como nas ações da luta.",
        "partner_actions": {a: {n: "spar_partner_%s_%s" % (a, n) for n in PARC[a]} for a in PARC},
        "partner_states": {"box": {"base": "idle (e push de vez em quando = base_push)", "warn": "warn (segurar o último quadro)",
                                   "burst": "burst (loop 1,5 s)", "pause": "pause (loop)", "feint": "feint (segurar o último quadro)",
                                   "pushed": "recoil", "reset": "idle"},
                           "jj": {"base": "grip / pull", "warn": "warn", "burst": "yank (segurar o último quadro)",
                                  "pause": "pause", "feint": "feint", "pushed": "yanked", "reset": "take ao contrário + take"}},
        "draw_order": "Boxe: quem bate por cima (como na luta). JJ: o discípulo por cima (as luvas dele ficam na gola do parceiro).",
    },
    "flyers": {
        "fighter_actions": {"idle": "fighter_flyer_idle", "give": "fighter_flyer_give", "miss": "fighter_flyer_miss"},
        "pedestrian_types": TIPOS,
        "pedestrian_actions": {t: {"walk": "ped_%s_walk" % t, "no": "ped_%s_%s" % (t, DICA[t]), "tell": "ped_%s_tell" % t,
                                   "false": "ped_%s_false" % t, "refuse": "ped_%s_refuse" % t, "accepted": "ped_%s_flyer" % t}
                               for t in TIPOS},
        "pedestrian_frame": [48, 76], "pedestrian_pivot": [24, 71], "pedestrian_pivot_flipped": [23, 71],
        "pedestrian_head_top": -67,
        "pedestrian_note": ("Quem quer: walk -> tell (quadros 0-2 uma vez, 3-5 em loop enquanto durar o tell_s) -> walk; clicou "
                            "certo: flyer até sair. Quem não quer: a folha 'no' do tipo a travessia toda (fone, braço cruzado, "
                            "pressa, celular). Sinal falso: walk -> false -> walk. Clicou errado: refuse -> volta ao que fazia. "
                            "O ? (ui_tell_mark) fica em y = pés - 71."),
    },
}

linhas = []
for k in sorted(S):
    e = S[k]
    if k.endswith("_layered"):
        continue
    hit = "-"
    if "hit_frame" in e and "hit_point" in e:
        hit = "%s / %s" % (e["hit_frame"], [round(v, 1) for v in e["hit_point"]])
    elif "hand_flyer" in e:
        hit = "%s / mão %s" % (e["hit_frame"], e["hand_flyer"])
    linhas.append("| `%s` | %dx%d | %d | %s | %s | %s | %s |" % (k, e["frame_size"][0], e["frame_size"][1], e["frames"], e["pivot"],
                  e["fps"], "sim" if e.get("loop") else "não", hit))

doc = """# Fase 7a2: personagens do Treino fora de hora (entradas para o manifest)

Artista de Personagens. Registrado pelo `tools/art/manifest_7a2.py` do Diretor de Arte (bloco `sprites` e `minigame_layout` abaixo).
PNG em `assets/sprites/fight/` e `assets/sprites/disciple/` (discípulo, com camadas e as 5 luvas), `assets/sprites/characters/`
(discípulo com os panfletos) e `assets/sprites/minigame/` (parceiro e passantes). Nenhum arquivo antigo foi sobrescrito.

## Como foi gerado (dá para rodar de novo)
Poses em dados em `tools/art/golpes_7a2.json` (autoria: `python tools/art/poses_7a2.py`, que também trava a mão no alcance do braço).
Numa pasta temporária com `project.godot` vazio (nunca no projeto):
```
FC_LUTADOR=disc FC_CAMADAS=1 FC_GOLPES=E:/Fightclicker/tools/art/golpes_7a2.json godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_golpes_jogador.gd -- <tmp>/out_j
godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_sprites_fase7a2.gd -- <tmp>/out_j <tmp>/out <pranchas>
python tools/art/doc_manifest_7a2.py <tmp>/out_j <tmp>/out
```
Mudança pequena em `make_golpes_jogador.gd`: chave `prop` nas poses da garagem (maço / panfleto na mão, atrás dos dedos). Nada que já
existia muda de resultado.

## Contrato
- Choque: os dois de pé nos pivôs da luta (`minigame_layout.spar`: 296 e 346, pés em y 318), quadro 112x104, pivô (56,98). O parceiro
  é um aluno da Raízes (um pouco mais alto e magro que o discípulo): capacete azul, regata e luva verde no Boxe; quimono azul com faixa
  branca e mãos nuas no Jiu-jitsu. Folhas dele já viradas para a esquerda.
- Panfletagem: discípulo em 3/4 da sala (48x72, pivô 22,67) em `fighter_spot`; passantes em perfil na escala da sala, quadro
  **48x76, pivô (24,71)** (o 48x72 cortava a cabeça no andar), pés em y 300. 4 tipos, cada um com o seu jeito de "não quero".
- Osmar: as folhas de hoje (`coach_idle` / `coach_idle_gym`), sem animação nova (o design não pede).

## Pedidos ao Programador / UI/UX
1. Ordem de desenho no Choque: Boxe como na luta (quem bate por cima); JJ com o discípulo por cima.
2. Estados do parceiro e do discípulo: ver `minigame_layout.spar.partner_states` e `player_actions`. Avisos (`warn`, `feint`) e a
   puxada forte (`jj_yank`) seguram o último quadro até o padrão acabar.
3. `spar_jj_take` tocado ao contrário = soltar (não há folha própria).
4. Passantes: espelhar a folha para quem anda para a esquerda; a folha `tell` repete os quadros 3-5 enquanto durar o `tell_s`.
5. Panfleto voando: sai de `hand_flyer` do `fighter_flyer_give` no `hit_frame`.

## Tabela (folhas planas; cada `*_disc` tem também a `_layered`)
| id | quadro | quadros | pivô | fps | loop | hit (quadro / ponto) |
|---|---|---|---|---|---|---|
""" + "\n".join(linhas) + """

## Entradas completas para `sprites` (%d chaves)
```json
%s
```

## minigame_layout (acrescentar)
```json
%s
```
""" % (len(S), json.dumps(S, ensure_ascii=False, indent=1), json.dumps(LAYOUT, ensure_ascii=False, indent=1))
for nome in ["fase7a2-personagens-manifest.md", "fase7a2-poses-manifest.md"]:
    open(os.path.join(ROOT, "docs", "arte", nome), "w", encoding="utf-8", newline="\n").write(doc)
print("ok: %d chaves" % len(S))
