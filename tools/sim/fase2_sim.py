"""Simulacao da Fase 2 (Treino na garagem) do Fightclicker.

Le os valores de data/training.json e data/generators.json (se existirem);
senao usa os valores do design (docs/fases/fase2-design.md, secao "Dados").

Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase2_sim.py

Jogador modelado:
  - clica C cliques/s o tempo todo (3, 5 ou 8);
  - compra "melhor": entre tudo que existe, escolhe a opcao de menor
    nota = (tempo ate poder pagar) + (custo / ganho em treino/s) e junta para ela;
  - compra "barato": sempre a opcao mais barata (jogador impulsivo);
  - foco "fixo": sempre no saco (so as melhorias do saco valem);
  - foco "rodizio": troca o foco a cada 60 s (saco -> corda -> esteira),
    entao cada melhoria de aparelho vale 1/3 do tempo.
Clique em valor esperado (critico entra pela media). Ao final, rodadas com
sorteio de critico para ver a variacao dos marcos.
"""
import json
import math
import os
import random

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

PADRAO_TREINO = {
    "click": {"base_training": 1, "crit_chance": 0.10, "crit_multiplier": 3},
    "apparatus": [
        {"id": "punching_bag", "upgrades": [
            {"id": "bag_patch", "cost": 300, "multiplier": 3},
            {"id": "bag_sand", "cost": 5000, "multiplier": 5}]},
        {"id": "jump_rope", "upgrades": [
            {"id": "rope_laundry", "cost": 300, "multiplier": 3},
            {"id": "rope_handles", "cost": 5000, "multiplier": 5}]},
        {"id": "treadmill", "upgrades": [
            {"id": "treadmill_oil", "cost": 300, "multiplier": 3},
            {"id": "treadmill_belt", "cost": 5000, "multiplier": 5}]},
    ],
}
PADRAO_GERADORES = {"generators": [
    {"id": "neighbor_kid", "base_cost": 60, "growth": 1.25, "production": 1},
    {"id": "retired_uncle", "base_cost": 2500, "growth": 1.25, "production": 8},
]}

MARCOS = [60, 180, 300, 480, 600, 900]


def ler(nome, padrao):
    p = os.path.join(RAIZ, "data", nome)
    if os.path.exists(p):
        with open(p, encoding="utf-8") as f:
            return json.load(f), "data/" + nome
    return padrao, "valores padrao do design"


def teto3(x):
    """Arredonda para CIMA mantendo 3 digitos significativos (inteiro abaixo de 1000)."""
    if x <= 0:
        return 0.0
    x = x * (1 - 1e-9)  # tolera erro de float (60.0000000001 -> 60)
    if x < 1000:
        return float(math.ceil(x))
    e = int(math.floor(math.log10(x))) - 2
    f = 10.0 ** e
    return math.ceil(x / f) * f


def custo_gerador(g, n):
    return teto3(g["base_cost"] * g["growth"] ** n)


def _melhor(melhor, op, saldo, renda, estrategia):
    custo, ganho = op[2], op[3]
    if estrategia == "barato":
        nota = custo
    else:
        nota = max(0.0, custo - saldo) / renda + custo / ganho
    if melhor is None or nota < melhor[0]:
        return (nota, op)
    return melhor


def simular(cps, modo, treino, geradores, t_max=15 * 60, dt=0.05, sorteio=None,
            estrategia="melhor"):
    clk = treino["click"]
    media_crit = 1 + clk["crit_chance"] * (clk["crit_multiplier"] - 1)
    aps = [a["id"] for a in treino["apparatus"]]
    ups = {a["id"]: a["upgrades"] for a in treino["apparatus"]}
    nivel = {a: 0 for a in aps}
    gens = geradores["generators"]
    qtd = {g["id"]: 0 for g in gens}
    saldo = 0.0
    tot_clique = 0.0
    tot_passivo = 0.0
    eventos = []
    fotos = {}

    def mult(a):
        m = 1
        for i in range(nivel[a]):
            m *= ups[a][i]["multiplier"]
        return m

    def foco(t):
        return aps[0] if modo == "fixo" else aps[int(t // 60) % 3]

    def clique_s(a):
        return cps * clk["base_training"] * mult(a) * media_crit

    def clique_medio():
        if modo == "fixo":
            return clique_s(aps[0])
        return sum(clique_s(a) for a in aps) / 3

    def passivo():
        return sum(g["production"] * qtd[g["id"]] for g in gens)

    def escolher():
        renda = clique_medio() + passivo()
        melhor = None
        for g in gens:
            op = ("gen", g["id"], custo_gerador(g, qtd[g["id"]]), float(g["production"]), None)
            melhor = _melhor(melhor, op, saldo, renda, estrategia)
        for a in aps:
            if modo == "fixo" and a != aps[0]:
                continue
            if nivel[a] < len(ups[a]):
                u = ups[a][nivel[a]]
                ganho = clique_s(a) * (u["multiplier"] - 1)
                if modo == "rodizio":
                    ganho /= 3
                op = ("up", u["id"], float(u["cost"]), ganho, a)
                melhor = _melhor(melhor, op, saldo, renda, estrategia)
        return melhor[1]

    rng = random.Random(sorteio) if sorteio is not None else None
    acum = 0.0
    alvo = escolher()
    passo = 0
    t = 0.0
    while t <= t_max + 1e-9:
        while saldo >= alvo[2]:
            saldo -= alvo[2]
            if alvo[0] == "gen":
                qtd[alvo[1]] += 1
                if qtd[alvo[1]] == 1:
                    eventos.append((t, "1o " + alvo[1]))
            else:
                nivel[alvo[4]] += 1
                eventos.append((t, alvo[1]))
            alvo = escolher()
        if rng is None:
            gc = clique_s(foco(t)) * dt
        else:
            acum += cps * dt
            gc = 0.0
            while acum >= 1 - 1e-9:
                acum -= 1
                v = clk["base_training"] * mult(foco(t))
                if rng.random() < clk["crit_chance"]:
                    v *= clk["crit_multiplier"]
                gc += v
        gp = passivo() * dt
        saldo += gc + gp
        tot_clique += gc
        tot_passivo += gp
        for m in MARCOS:
            if m not in fotos and t >= m - 1e-9:
                fotos[m] = {"clique_s": clique_medio(), "passivo_s": passivo(),
                            "qtd": dict(qtd), "niveis": dict(nivel),
                            "tot_clique": tot_clique, "tot_passivo": tot_passivo}
        passo += 1
        t = passo * dt
    return eventos, fotos


def fmt(x):
    """Igual ao NumberFormat em modo TRUNCAR (o usado para saldos)."""
    if x < 1000:
        return "%d" % math.floor(x + 1e-9)
    for i, s in enumerate(["K", "M", "B", "T"], start=1):
        if x < 1000 ** (i + 1):
            m = x / 1000 ** i
            casas = 2 if m < 10 else (1 if m < 100 else 0)
            f = 10 ** casas
            return ("%." + str(casas) + "f%s") % (math.floor(m * f + 1e-9) / f, s)
    return "%.2e" % x


def mmss(t):
    s = int(round(t))
    return "%d:%02d" % (s // 60, s % 60)


def main():
    treino, ft = ler("training.json", PADRAO_TREINO)
    geradores, fg = ler("generators.json", PADRAO_GERADORES)
    print("Fontes: %s, %s" % (ft, fg))
    ids = tuple(g["id"] for g in geradores["generators"])
    casos = [(m, c, "melhor") for m in ["fixo", "rodizio"] for c in [3, 5, 8]]
    casos += [("fixo", c, "barato") for c in [3, 5, 8]]
    for modo, cps, estr in casos:
        ev, fotos = simular(cps, modo, treino, geradores, estrategia=estr)
        print("\n=== %d cliques/s, foco %s, compra %s ===" % (cps, modo, estr))
        print("Marcos: " + "; ".join("%s %s" % (mmss(t), e) for t, e in ev))
        print("| min | clique/s | passivo/s | passivo/clique | %s | %s | niveis saco/corda/esteira"
              " | treino total | %% do total vindo do passivo |" % ids)
        print("|---|---|---|---|---|---|---|---|---|")
        for m in MARCOS:
            f = fotos[m]
            g = list(f["qtd"].values())
            n = list(f["niveis"].values())
            tot = f["tot_clique"] + f["tot_passivo"]
            print("| %d | %s | %s | %d%% | %d | %d | %d/%d/%d | %s | %d%% |" % (
                m // 60, fmt(f["clique_s"]), fmt(f["passivo_s"]),
                round(100 * f["passivo_s"] / f["clique_s"]), g[0], g[1],
                n[0], n[1], n[2], fmt(tot), round(100 * f["tot_passivo"] / tot)))
    print("\n=== Variacao com sorteio de critico (foco fixo, compra melhor, 30 sementes) ===")
    for cps in [3, 4, 5, 8]:
        marcos = {}
        for s in range(30):
            ev, _ = simular(cps, "fixo", treino, geradores, sorteio=s, dt=0.1)
            for t, e in ev:
                marcos.setdefault(e, []).append(t)
        print("-- %d cliques/s" % cps)
        for e, ts in marcos.items():
            print("   %-22s min %s  max %s" % (e, mmss(min(ts)), mmss(max(ts))))


if __name__ == "__main__":
    main()
