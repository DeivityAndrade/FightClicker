"""Ronda 2a2 (Artista de Personagens): mescla tools/art/ronda2a2_manifest.json no assets/sprites/manifest.json
e acrescenta a camada 'apagao' ao assets/sprites/menu/parede.json.

Uso (da raiz do repo):  python tools/art/manifest_ronda2a2.py
- sprites e by_data_id: só chaves NOVAS (se já existir, troca pela nova: rodar de novo dá o mesmo arquivo);
- by_data_id.alley_fight: acrescenta bandits.apagao e arenas.apagao (o resto fica igual);
- by_data_id.disciple_palette: acrescenta a opção shorts_color 'live_wire' (no fim da lista) e leg.map.live_wire = blue;
- parede.json: camada 'apagao' no fim da lista (por cima das outras), requires black_cat_boss_won.
Formato preservado: JSON com tab, ensure_ascii False, ordem das chaves e o fim do arquivo como estava.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MAN = os.path.join(ROOT, "assets", "sprites", "manifest.json")
FRAG = os.path.join(ROOT, "tools", "art", "ronda2a2_manifest.json")
PAREDE = os.path.join(ROOT, "assets", "sprites", "menu", "parede.json")


def load(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def save(p, d, fim):
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(d, indent="\t", ensure_ascii=False) + fim)


def fim_de(p):
    """Mantém o fim do arquivo como estava (o manifest termina com quebra de linha; o parede.json não)."""
    with open(p, encoding="utf-8") as f:
        return "\n" if f.read().endswith("\n") else ""


def main():
    m = load(MAN)
    fr = load(FRAG)
    for k, v in fr["sprites"].items():
        m["sprites"][k] = v
    for k, v in fr["by_data_id"].items():
        m["by_data_id"][k] = v
    af = m["by_data_id"]["alley_fight"]
    for sec, vals in fr["alley_fight_add"].items():
        af.setdefault(sec, {})
        af[sec].update(vals)
    af["_nota"] = ("Ronda 2a1: mapa da briga da noite. bandits.<id do data/ronda.json> -> by_data_id do adversário; vulto -> "
                   "by_data_id.vulto_fight; arena = prefixo das camadas. Ronda 2a2: bandits.apagao = o chefe (opp_alley_apagao) e "
                   "arenas.<id> = arena própria de quem tem (apagao -> arena_apagao); sem entrada em arenas, vale 'arena'.")
    pal = m["by_data_id"]["disciple_palette"]
    for field, opts in fr["disciple_palette_add"]["options"].items():
        lst = pal["options"][field]
        for o in opts:
            lst[:] = [x for x in lst if x.get("id") != o["id"]] + [o]
    pal["school_symbol_source"]["leg"]["map"].update(fr["disciple_palette_add"]["school_symbol_source_leg_map"])
    save(MAN, m, fim_de(MAN))

    p = load(PAREDE)
    p["layers"] = [l for l in p["layers"] if l.get("id") != "apagao"]
    p["layers"].append({
        "file": "res://assets/sprites/menu/menu_item_apagao.png",
        "id": "apagao",
        "note": "cartaz PROCURA-SE do Apagão, rasgado, \"O VULTO QUE RELIGOU A LUZ\" (o chefe da Ronda 2a vencido). Canto livre de baixo à direita; luz do menu já pintada. Gerador: tools/art/make_sprites_ronda2a2.gd (confere a folga).",
        "pos": [444, 276],
        "requires": {"black_cat_boss_won": "apagao"},
        "size": [57, 69],
    })
    save(PAREDE, p, fim_de(PAREDE))
    print("ok: %d sprites, %d by_data_id; parede com %d camadas" % (len(fr["sprites"]), len(fr["by_data_id"]), len(p["layers"])))


if __name__ == "__main__":
    main()
