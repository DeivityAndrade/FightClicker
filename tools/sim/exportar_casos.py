"""Exporta casos de referencia do simulador Python para o teste do GDScript.

Gera tests/data/fase3_casos.json com:
  - "exatos": luta com SORTEIOS EXPLICITOS (a mesma lista de numeros e consumida pelo Python e pelo
    GDScript, 3 por ataque: esquiva, critico, variacao). O GDScript tem que dar a mesma luta golpe a golpe.
  - "estatisticas": chance de vitoria (N sementes) e rotulo de estados fixos; o GDScript usa outro
    gerador de numeros, entao compara dentro de uma tolerancia.
  - "motivos": atributo decisivo (e faltas) de estados com decisivo claro.
  - "explicacoes": kind (luck|missing) e atributo do motivo pos-QA (design 16, fase3_sim.explicar) em estados
    claros (azar com chance >= 0.97; faltaram com decisivo claro). Estatistica depende do RNG: nao exportada.

Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/exportar_casos.py
Os dados vem de data/*.json (os mesmos que o jogo le).
"""
import json
import os
import random
import sys
import types

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import fase3_sim as f3  # noqa: E402

R, _treino, _gens, _shop, _career = f3.carregar()


class Gravador(random.Random):
    """random.Random que lembra os numeros sorteados."""

    ultimo = None

    def __init__(self, semente=None):
        super().__init__(semente)
        self.sorteados = []
        Gravador.ultimo = self

    def random(self):
        x = super().random()
        self.sorteados.append(x)
        return x


f3.random = types.SimpleNamespace(Random=Gravador, randrange=random.randrange)


def estados(n, semente):
    rng = random.Random(semente)
    saida = []
    for _ in range(n):
        o = R.opp[rng.randrange(len(R.opp))]
        adv = (o["strength"], o["agility"], o["endurance"])
        tot = sum(adv) * 2.718281828 ** rng.uniform(-1.9, 1.8)
        w = [rng.random() ** 2 for _ in range(3)]
        s = sum(w) or 1.0
        jog = tuple(tot * x / s for x in w)
        saida.append((jog, adv, R.tac_ids[rng.randrange(len(R.tac_ids))]))
    return saida


def caso_exato(jog, adv, tat, semente):
    r = R.lutar(jog, adv, tat, semente, registro=True)
    sorteios = list(Gravador.ultimo.sorteados)
    ev = [[e["t"], e["who"], e["type"], bool(e.get("counter", False)), e.get("damage", 0.0), e.get("life_after", 0.0)]
          for e in r["ev"]]
    return {
        "player": list(jog), "opponent": list(adv), "tactic": tat, "draws": sorteios,
        "win": r["win"], "ko": r["ko"], "t_ko": r["t_ko"] if r["t_ko"] is not None else -1.0,
        "t_end": r["t"], "pct_player": r["pct"][0], "pct_opponent": r["pct"][1],
        "vmax": list(r["vmax"]), "events": ev, "counts": r["cont"],
    }


def main():
    saida = {"exatos": [], "estatisticas": [], "motivos": [], "explicacoes": []}
    for i, (jog, adv, tat) in enumerate(estados(80, 11)):
        saida["exatos"].append(caso_exato(jog, adv, tat, 1000 + i))
    # casos extremos: jogador zerado, tempo esgotado (Muralha), contra-golpe, K.O. cedo
    zero = (0.0, 0.0, 0.0)
    for tat in R.tac_ids:
        for o in R.opp:
            adv = (o["strength"], o["agility"], o["endurance"])
            saida["exatos"].append(caso_exato(zero, adv, tat, 7))
            saida["exatos"].append(caso_exato((o["strength"], o["agility"], o["endurance"]), adv, tat, 9))

    for jog, adv, tat in estados(14, 23):
        p = R.chance(jog, adv, tat, 1000)
        saida["estatisticas"].append({"player": list(jog), "opponent": list(adv), "tactic": tat, "chance": p,
                                      "label": R.rotulo(p)})

    # Motivo: so estados onde o decisivo e claro (menor falta < 80% da segunda menor, ambas existindo)
    rng = random.Random(5)
    tent = 0
    while len(saida["motivos"]) < 8 and tent < 400:
        tent += 1
        jog, adv, tat = estados(1, rng.randrange(10 ** 6))[0]
        p = R.chance(jog, adv, tat)
        if not (0.15 <= p < 0.85):
            continue
        attr, falta, faltas = R.motivo(jog, adv, tat)
        vals = sorted(f for f, _ in faltas if f is not None)
        if len(vals) < 2 or vals[0] > 0.8 * vals[1]:
            continue
        saida["motivos"].append({"player": list(jog), "opponent": list(adv), "tactic": tat, "attribute": attr,
                                 "faltaram": falta, "chance": p})

    # Explicacoes pos-QA (design 16): so o que independe do gerador de numeros (kind e atributo).
    rng = random.Random(77)
    tent = 0
    n_luck = n_miss = 0
    while (n_luck < 4 or n_miss < 8) and tent < 3000:
        tent += 1
        jog, adv, tat = estados(1, rng.randrange(10 ** 6))[0]
        p = R.chance(jog, adv, tat)
        if p >= 0.97 and n_luck < 4:
            e = f3.explicar(R, jog, adv, tat, 1)
            saida["explicacoes"].append({"player": list(jog), "opponent": list(adv), "tactic": tat,
                                         "kind": e["kind"], "attribute": e["attribute"], "chance": p})
            n_luck += 1
        elif 0.15 <= p < 0.85 and n_miss < 8:
            falt = [(f3.falta_para_v2(R, jog, adv, tat, i), i) for i in (2, 0, 1)]
            vals = sorted(f for f, _ in falt if f is not None)
            if len(vals) < 2 or vals[0] > 0.8 * vals[1]:
                continue
            e = f3.explicar(R, jog, adv, tat, 1)
            saida["explicacoes"].append({"player": list(jog), "opponent": list(adv), "tactic": tat,
                                         "kind": e["kind"], "attribute": e["attribute"], "chance": p})
            n_miss += 1

    destino = os.path.join(f3.RAIZ, "tests", "data", "fase3_casos.json")
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    with open(destino, "w", encoding="utf-8") as f:
        json.dump(saida, f, ensure_ascii=False)
    print("gravado %s: %d exatos, %d estatisticas, %d motivos, %d explicacoes" % (
        destino, len(saida["exatos"]), len(saida["estatisticas"]), len(saida["motivos"]), len(saida["explicacoes"])))


if __name__ == "__main__":
    main()
