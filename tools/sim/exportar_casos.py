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
import fase7a1_sim as f7  # noqa: E402  (7a1: passivas de Boxe e Jiu-jitsu; escreve tests/data/fase7a1_casos.json)

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
f7.random = f3.random


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


FINISH = {"dano": "damage", "dano_dele": "damage", "nocaute": "knockout", "finalizacao": "submission", "pontos": "points"}


def caso_arte(jog, adv, tat, semente, arte, extra):
    """Luta com a passiva da arte (4 sorteios por ataque: esquiva, critico, variacao, arte)."""
    RA = f7.regras_arte7(R, {"fight": {}}, extra, arte)
    r = RA.lutar(jog, adv, tat, semente, registro=True)
    sorteios = list(Gravador.ultimo.sorteados)
    ev = [[e["t"], e["who"], e["type"], bool(e.get("counter", False)), e.get("damage", 0.0), e.get("life_after", 0.0),
           e.get("streak", 0), e.get("finish", "")] for e in r["ev"]]
    est = RA.estado_passiva(jog, adv, tat)
    return {
        "player": list(jog), "opponent": list(adv), "tactic": tat, "art": arte, "extra": extra, "draws": sorteios,
        "win": r["win"], "ko": r["ko"], "t_ko": r["t_ko"] if r["t_ko"] is not None else -1.0,
        "t_end": r["t"], "pct_player": r["pct"][0], "pct_opponent": r["pct"][1], "vmax": list(r["vmax"]),
        "events": ev, "counts": r["cont"], "finish": FINISH[r["metodo"]], "streak_peak": r["embalo_pico"],
        "attempts": r["tentativas"], "opp_counter_damage": r["cont"]["dano_contra"][1],
        "est": {k: v for k, v in est.items() if isinstance(v, (int, float, bool, str))},
    }


def exportar_7a1():
    casos = []
    n = 0
    for arte in ("boxing", "bjj"):
        for extra in (0.0, 0.5):
            for i, (jog, adv, tat) in enumerate(estados(90, 41 + n)):
                casos.append(caso_arte(jog, adv, tat, 5000 + n * 1000 + i, arte, extra))
            n += 1
    # estados fortes (jogador na frente e com vida dele baixa): garantem K.O. e finalizacao pela passiva
    rng = random.Random(99)
    for arte in ("boxing", "bjj"):
        for tat in R.tac_ids:
            for k in range(14):
                o = R.opp[rng.randrange(len(R.opp))]
                adv = (o["strength"], o["agility"], o["endurance"])
                m = rng.uniform(0.7, 1.4)
                w = [rng.random() + 0.3 for _ in range(3)]
                s = sum(w)
                jog = tuple(sum(adv) * m * x / s for x in w)
                casos.append(caso_arte(jog, adv, tat, 9000 + k, arte, 0.5 if k % 2 else 0.0))
    destino = os.path.join(f3.RAIZ, "tests", "data", "fase7a1_casos.json")
    with open(destino, "w", encoding="utf-8") as f:
        json.dump({"exatos": casos}, f, ensure_ascii=False)
    fins = {}
    for c in casos:
        fins[(c["art"], c["finish"])] = fins.get((c["art"], c["finish"]), 0) + 1
    print("gravado %s: %d casos com arte; fins: %s" % (destino, len(casos), sorted(fins.items())))


def exportar_7b1():
    """7b1: casos exatos do Muay Thai (passiva shin, Canela) em tests/data/fase7b1_casos.json. Importa fase7b1_sim so aqui:
    o ramo novo nao muda Boxe, Jiu-jitsu nem 'sem arte' (fase7b1_sim.py ident), entao fase7a1_casos.json sai igual."""
    import fase7b1_sim as f7b  # noqa: E402
    f7b.random = f3.random
    fim = dict(FINISH, chute_rodado="spin_kick")
    casos = []

    def caso(jog, adv, tat, semente, extra):
        RA = f7.regras_arte7(R, {"fight": {}}, extra, "muay_thai")
        r = RA.lutar(jog, adv, tat, semente, registro=True)
        sorteios = list(Gravador.ultimo.sorteados)
        ev = [[e["t"], e["who"], e["type"], bool(e.get("counter", False)), e.get("damage", 0.0), e.get("life_after", 0.0),
               e.get("marks", 0), e.get("move", ""), e.get("finish", "")] for e in r["ev"]]
        est = RA.estado_passiva(jog, adv, tat)
        return {
            "player": list(jog), "opponent": list(adv), "tactic": tat, "art": "muay_thai", "extra": extra, "draws": sorteios,
            "win": r["win"], "ko": r["ko"], "t_ko": r["t_ko"] if r["t_ko"] is not None else -1.0,
            "t_end": r["t"], "pct_player": r["pct"][0], "pct_opponent": r["pct"][1], "vmax": list(r["vmax"]),
            "events": ev, "counts": r["cont"], "finish": fim[r["metodo"]], "marks_peak": r["marcas_pico"],
            "marks_full_at": r["cheia_em"], "attempts": r["tentativas"], "spins": r["rodados"],
            "opp_counter_damage": r["cont"]["dano_contra"][1],
            "est": {k: v for k, v in est.items() if isinstance(v, (int, float, bool, str))},
        }
    for extra in (0.0, 0.5):
        for i, (jog, adv, tat) in enumerate(estados(90, 71 + int(extra * 2))):
            casos.append(caso(jog, adv, tat, 7000 + int(extra * 2) * 1000 + i, extra))
    rng = random.Random(77)
    for tat in R.tac_ids:
        for k in range(20):
            o = R.opp[3 + rng.randrange(len(R.opp) - 3)]
            adv = (o["strength"], o["agility"], o["endurance"])
            m = rng.uniform(0.75, 1.3)
            w = [rng.random() + 0.3 for _ in range(3)]
            s = sum(w)
            jog = tuple(sum(adv) * m * x / s for x in w)
            casos.append(caso(jog, adv, tat, 9500 + k, 0.5 if k % 2 else 0.0))
    destino = os.path.join(f3.RAIZ, "tests", "data", "fase7b1_casos.json")
    with open(destino, "w", encoding="utf-8") as f:
        json.dump({"exatos": casos}, f, ensure_ascii=False)
    fins = {}
    for c in casos:
        fins[c["finish"]] = fins.get(c["finish"], 0) + 1
    print("gravado %s: %d casos do Muay Thai; fins: %s" % (destino, len(casos), sorted(fins.items())))


if __name__ == "__main__":
    main()
    exportar_7a1()
    exportar_7b1()
