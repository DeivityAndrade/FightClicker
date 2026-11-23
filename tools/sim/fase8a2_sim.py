"""Simulacao da Fase 8a2 (Centro de treinamento, local 3).

Design: docs/fases/fase8a2-design.md. Valores: data/center.json (gerador que so existe no centro, 5a melhoria dos aparelhos,
patrocinio pequeno, regiao CENTRO da arvore) e data/locations.json (local "center": preco da mudanca e multiplicador).
Roda em cima do fase8a1_sim.py; so ACRESCENTA (nenhum arquivo antigo e editado; os remendos ficam aqui):
  1. depois de vencer o James (escada inteira = "topo"), o robo paga a mudanca e fica SIM_STINT s (padrao 900) no centro,
     comprando (alunos, 5a melhoria, LOJA). Sem luta nova. Depois passa o posto (o fim continua "topo");
  2. patrocinio: so com a linhagem ja tendo 1 cinturao regional; quando a fama da campanha chega a fame_at_least o robo assina
     na hora; cada vitoria DEPOIS paga floor(premio_base x prize_share + 0,5) a mais;
  3. regiao CENTRO da arvore (trava "center"): so aparece depois da 1a mudanca da linhagem; o robo compra o no mais barato que
     cabe (regra de sempre).
SIM_CENTRO=0 (ou sem data/center.json) = robo da 8a1, byte a byte.

Rodar:  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/sim/fase8a2_sim.py [secao ...]
Secoes: sonda (estado ao vencer o James, sem o centro), ident (nada muda ate o 1o cinturao regional), centro (estadia no centro:
tempo morto, compras, clique x renda, dinheiro), legado (Legado que sobra por campanha, com e sem a regiao CENTRO), exportar
(tests/data/fase8a2_casos.json), tudo (= ident centro legado exportar).
Alavancas: SIM_N8 (jogadores; 48), SIM_K8 (campanhas; 10), SIM_CPS ("4,3"), SIM_COMBOS (como na 7b2), SIM_STINT (s no centro),
SIM_CTR="custo,mult" (mudanca), SIM_ALUNO="base,cresc,prod", SIM_UP5="basico,arte" (custo da 5a melhoria), SIM_SP="fama,parte",
SIM_CTR_NOS="ctr_door=5000;..." (custo dos nos).
"""
import copy
import json
import math
import os
import sys
from multiprocessing import Pool

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import fase2_sim as f2  # noqa: E402
import fase4_sim as f4  # noqa: E402
import fase5_sim as f5  # noqa: E402
import fase6c2_sim as f6  # noqa: E402
import fase8a1_sim as f8  # noqa: E402

med, pct, mm = f4.mediana, f4.pct, f4.mm
RAIZ = f2.RAIZ


# =================================================================== dados
def carregar_centro():
    p = os.path.join(RAIZ, "data", "center.json")
    if not os.path.exists(p):
        return None, None
    with open(p, encoding="utf-8") as fh:
        C = json.load(fh)
    with open(os.path.join(RAIZ, "data", "locations.json"), encoding="utf-8") as fh:
        L = json.load(fh)
    loc = copy.deepcopy(next(x for x in L["locations"] if x["id"] == C["location"]))
    if os.environ.get("SIM_CTR"):
        c, m = os.environ["SIM_CTR"].split(",")
        loc["move"]["cost"], loc["training_mult"] = float(c), float(m)
    g = C["generators"][0]
    if os.environ.get("SIM_ALUNO"):
        b, cr, pr = (float(x) for x in os.environ["SIM_ALUNO"].split(","))
        g.update(base_cost=b, growth=cr, production=pr)
    if os.environ.get("SIM_UP5"):
        cb, ca = (float(x) for x in os.environ["SIM_UP5"].split(","))
        for u in C["apparatus_upgrades"]:
            u["cost"] = ca if u["apparatus"] in ("speed_bag", "grappling_dummy", "kick_bag") else cb
    if os.environ.get("SIM_SP"):
        fa, pa = os.environ["SIM_SP"].split(",")
        C["sponsor"].update(fame_at_least=float(fa), prize_share=float(pa))
    if os.environ.get("SIM_CTR_NOS"):
        for item in os.environ["SIM_CTR_NOS"].split(";"):
            i, v = item.split("=")
            next(n for n in C["skill_tree"]["nodes"] if n["id"] == i)["cost"] = int(v)
    return C, loc


C, LOC = carregar_centro()
ON = C is not None and os.environ.get("SIM_CENTRO", "1") == "1"
STINT = float(os.environ.get("SIM_STINT", "900"))
GEN = C["generators"][0] if C else None
UP5 = {u["apparatus"]: u for u in C["apparatus_upgrades"]} if C else {}
SP = C["sponsor"] if C else None
NOS = C["skill_tree"]["nodes"] if C else []
NOS_IDS = [n["id"] for n in NOS]

# estado da LINHAGEM (um jogador por vez em cada processo; zera no comeco de cada jogador)
_ST = {}


def _zerar_linhagem():
    _ST.clear()
    _ST.update({"centro": False, "cint": 0, "estadias": [], "legado": [], "sem_dinheiro": 0, "patroc": []})


_zerar_linhagem()


def ligar(on):
    global ON
    ON = bool(on) and C is not None


# =================================================================== remendos (so valem com ON)
_rodar_orig = f6.Carreira6.rodar          # = Carreira5.rodar (o laco de sempre)
_tl8 = f6.Carreira6.talvez_lutar          # = _talvez8 do fase8a1_sim
_g3_orig = f5.Carreira5._garagem_f3
_loja_orig = f5.Carreira5.comprar_loja
_trava_orig = f5.trava_ok
_mapa_orig = f5.mapa_de
_comprar_mapa_orig = f5.comprar_mapa


def _no_centro(self):
    return getattr(self, "ctr_t0", None) is not None


def _g3(self):
    if not _no_centro(self):
        return _g3_orig(self)
    q0, n0 = self.qtd.get(GEN["id"], 0), dict(self.nivel)
    _g3_orig(self)
    for _ in range(self.qtd.get(GEN["id"], 0) - q0):
        self.ctr_ev.append((self.t, "aluno"))
    for a in self.nivel:
        if self.nivel[a] > n0.get(a, 0):
            self.ctr_ev.append((self.t, "up5 " + a if self.nivel[a] == len(self.ups[a]) and a in UP5 else "up " + a))


def _loja(self):
    if not _no_centro(self):
        return _loja_orig(self)
    p0 = dict(self.pqtd)
    _loja_orig(self)
    for g in self.pqtd:
        for _ in range(self.pqtd[g] - p0[g]):
            self.ctr_ev.append((self.t, "loja " + g))


def _talvez(self):
    v0 = self.vitorias
    _tl8(self)
    if not ON or self.vitorias <= v0:
        return
    o = self.R.opp[v0]
    sp = getattr(self, "sp", "")
    if sp == "signed":
        bon = math.floor(o["prize_money"] * SP["prize_share"] + 0.5)
        self.dinheiro += bon
        self.dinheiro_total += bon
        self.sp_total = getattr(self, "sp_total", 0) + bon
    elif sp == "" and _ST["cint"] >= SP["requires_regional_belts"] and self.fama >= SP["fame_at_least"]:
        self.sp = "signed"                     # o robo assina assim que o envelope aparece (depois desta vitoria)
        self.sp_em = o["id"]


def _rodar(self):
    _rodar_orig(self)
    if not ON or not self.fim or self.fim[0] != "topo" or "opp_james" not in [o["id"] for o in self.R.opp[:self.vitorias]]:
        return self
    _ST["patroc"].append((self.k, getattr(self, "sp_em", None), getattr(self, "sp_total", 0)))
    _ST["cint"] += 1
    custo = float(LOC["move"]["cost"])
    if self.dinheiro + 1e-9 < custo:
        _ST["sem_dinheiro"] += 1
        return self
    primeira = not _ST["centro"]
    _ST["centro"] = True
    din0 = self.dinheiro
    self.dinheiro -= custo
    self.loc = float(LOC["training_mult"]) * (1.0 + self.b.get("gym_training_bonus", 0.0))
    self.gens = list(self.gens) + [GEN]
    self.qtd[GEN["id"]] = 0
    for a in list(self.ups):
        if a in UP5:
            self.ups[a] = list(self.ups[a]) + [UP5[a]]
    self.ctr_t0, self.ctr_ev = self.t, []
    a0 = self.foco()
    clique0, renda0 = self.valor_clique(a0), self.renda_sem_mao(a0)
    total0 = self.cps * clique0 * self.media_crit + renda0
    saldo0 = self.saldo
    amostras = {}
    marcas = [60, 120, 300, 600, STINT - 10]

    self.fim = None
    self.t_max = self.t + STINT
    # amostras a 1, 2, 5, 10 e 15 min: o laco nao tem gancho por passo; usa o comprar_garagem (chamado todo passo)
    cg = self.comprar_garagem

    def cg_amostra():
        cg()
        dt = self.t - self.ctr_t0
        while marcas and dt >= marcas[0]:
            a = self.foco()
            amostras[marcas.pop(0)] = (self.valor_clique(a), self.renda_sem_mao(a), self.qtd[GEN["id"]],
                                      self.cps * self.valor_clique(a) * self.media_crit + self.renda_sem_mao(a),
                                      self.passivo())
    self.comprar_garagem = cg_amostra
    _rodar_orig(self)
    del self.comprar_garagem
    ev = self.ctr_ev
    ts = [0.0] + [t - self.ctr_t0 for t, _ in ev]
    nao_equipe = [0.0] + [t - self.ctr_t0 for t, e in ev if e != "aluno"]
    up5 = [t - self.ctr_t0 for t, e in ev if e.startswith("up5")]
    fim_up5 = max(up5) if up5 else None
    def maior_gap(lst, ate):
        lst = sorted(x for x in lst if x <= ate) + [ate]
        return max((b - a) for a, b in zip(lst, lst[1:])) if len(lst) > 1 else ate
    _ST["estadias"].append({
        "k": self.k, "primeira": primeira, "din_antes": din0, "saldo0": saldo0, "total0": total0,
        "clique0": clique0, "renda0": renda0,
        "p1": (ts[1] if len(ts) > 1 else None), "p1_ne": (nao_equipe[1] if len(nao_equipe) > 1 else None),
        "gap10": maior_gap(ts, 600.0), "gap10_ne": maior_gap(nao_equipe, 600.0),
        "up5_n": len(up5), "up5_fim": fim_up5, "alunos": self.qtd[GEN["id"]], "amostras": amostras,
        "arte": self.arte, "sp_total": getattr(self, "sp_total", 0)})
    self.fim = ("topo", self.t)
    return self


def _trava(n, flags):
    if n.get("lock") == "center":
        return ON and _ST["centro"]
    return _trava_orig(n, flags)


def _mapa(tree):
    m = _mapa_orig(tree)
    if m is None or not ON:
        return m
    for n in NOS:
        n2 = dict(n)
        n2["neighbors"] = [v for v in n["neighbors"] if v in m or v in NOS_IDS]
        m[n["id"]] = n2
    return m


def _comprar_mapa(mapa, comprados, legado, flags, artes_robo):
    c, l = _comprar_mapa_orig(mapa, comprados, legado, flags, artes_robo)
    _ST["legado"].append((l, sum(1 for i in NOS_IDS if i in c), _ST["centro"]))
    return c, l


f6.Carreira6.rodar = _rodar
f6.Carreira6.talvez_lutar = _talvez
f5.Carreira5._garagem_f3 = _g3
f5.Carreira5.comprar_loja = _loja
f5.trava_ok = _trava
f5.mapa_de = _mapa
f5.comprar_mapa = _comprar_mapa


def seq(args):
    """Um jogador (sequencia da 8a1) com a linhagem do centro. Devolve (recs, estadias, legado_por_campanha, extra)."""
    _zerar_linhagem()
    recs = f8.sequencia8(args)
    leg = list(_ST["legado"])
    for r, (l, nn, ctr) in zip(recs, leg):
        r["legado_sobra"], r["nos_ctr"], r["centro_aberto"] = l, nn, ctr
    return recs, list(_ST["estadias"]), {"sem_dinheiro": _ST["sem_dinheiro"], "patroc": list(_ST["patroc"])}


def _init_w(arte, k, on):
    ligar(on)
    f8._init_combo8(arte, k)


def rodar_combo(arte, k, cps, n, K, on=True):
    tarefas = [(cps, 1000 + s, K, "padrao", arte, "normal", f5.T_MAX5) for s in range(n)]
    with Pool(f8._proc(), initializer=_init_w, initargs=(arte, k, on)) as pool:
        return pool.map(seq, tarefas, chunksize=1)


def _cps_l():
    return tuple(int(x) for x in os.environ.get("SIM_CPS", "4,3").split(","))


# =================================================================== sonda
def sec_sonda(n, K):
    print("\n## Sonda: estado do robo no instante em que vence o James (8a1, sem o centro; mediana)")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            res = []
            for recs, est, _ in rodar_combo(a, k, cps, n, K, on=True):
                res += [e for e in est]
            if not res:
                print("- %s %s %d/s: ninguem venceu o James" % (a, k, cps))
                continue
            print("- %s %s %d/s (n%d): saldo %.3g; treino/s total %.3g (1 clique %.3g, sem a mao %.3g); $ ao vencer %.3g" % (
                f8.NOME[a], f8.NOME_P[(a, k)], cps, len(res), med([e["saldo0"] for e in res]), med([e["total0"] for e in res]),
                med([e["clique0"] for e in res]), med([e["renda0"] for e in res]), med([e["din_antes"] for e in res])), flush=True)


# =================================================================== ident: nada muda ate o 1o cinturao regional
CAMPOS = ("fim", "wins", "belt", "legado", "lutas", "reg53", "vit_t", "honra", "arte")


def _ident_um(args):
    (a, k, cps, s, K) = args
    out = []
    for on in (False, True):
        ligar(on)
        f8._init_combo8(a, k)
        recs, _, _ = seq((cps, 1000 + s, K, "padrao", a, "normal", f5.T_MAX5))
        out.append(recs)
    ligar(True)
    r0, r1 = out
    kj = next((r["k"] for r in r0 if "opp_james" in r["vit_t"]), None)
    ate = kj if kj is not None else K
    ok = True
    for x, y in zip(r0[:ate], r1[:ate]):
        if any(x[c] != y[c] for c in CAMPOS):
            ok = False
        if x["k"] < ate and x["t"] != y["t"]:
            ok = False
    lutas = sum(len(x["lutas"]) for x in r0[:ate])
    depois = sum(1 for x, y in zip(r0[ate:], r1[ate:]) if any(x[c] != y[c] for c in CAMPOS))
    return ok, lutas, kj, depois, len(r0) - ate


def sec_ident(n, K):
    print("\n## Ident: com e sem o centro, as campanhas ate a do 1o cinturao regional (inclusive, ate a vitoria) sao iguais")
    print("| combinacao | cps | jogadores iguais | lutas comparadas | campanha do 1o James (med) | campanhas depois que mudaram |")
    print("|---|---|---|---|---|---|")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            with Pool(f8._proc(), initializer=_init_w, initargs=(a, k, True)) as pool:
                res = pool.map(_ident_um, [(a, k, cps, s, K) for s in range(n)], chunksize=1)
            print("| %s %s | %d/s | %d de %d | %d | %s | %d de %d |" % (
                f8.NOME[a], f8.NOME_P[(a, k)], cps, sum(1 for r in res if r[0]), len(res), sum(r[1] for r in res),
                f4.fmtk(med([r[2] if r[2] else 99 for r in res])), sum(r[3] for r in res), sum(r[4] for r in res)), flush=True)


# =================================================================== centro: a estadia depois do James
def sec_centro(n, K, cache=None):
    print("\n## Centro: estadia de %d s depois do James (todas as estadias; 1a = a 1a mudanca da linhagem)" % STINT)
    print("| combinacao | cps | estadias (1as) | $ ao vencer o James (min) | 1a compra (med; p90) | 1a compra sem ser aluno (med; p90) | "
          "maior intervalo sem compra nos 10 min (med; p90; max) | idem sem contar alunos (p90; max) | 5as melhorias: quantas / ultima (med; p90) | "
          "alunos em 5 / 10 / 15 min (med) | treino/s x chegada aos 10 min | 1 clique / renda sem a mao: chegada, 10 min, 15 min (med; min) |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|")
    T = {}
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            res = rodar_combo(a, k, cps, n, K, on=True)
            T[(a, k, cps)] = res
            es = [e for _, est, _ in res for e in est]
            if not es:
                continue
            sem = sum(x["sem_dinheiro"] for _, _, x in res)
            am = lambda m, i: [e["amostras"][m][i] for e in es if m in e["amostras"]]  # noqa: E731
            r10 = [e["amostras"][600][3] / e["total0"] for e in es if 600 in e["amostras"] and e["total0"] > 0]
            share = lambda m: [x / y for x, y in zip(am(m, 0), am(m, 1)) if y > 0]  # noqa: E731
            s0 = [e["clique0"] / e["renda0"] for e in es if e["renda0"] > 0]
            print("| %s %s | %d/s | %d (%d)%s | %.3g | %s; %s | %s; %s | %s; %s; %s | %s; %s | %d / %s; %s | %s / %s / %s | x%.2f | "
                  "%.0f%%, %.0f%%, %.0f%% (min %.0f%%) |" % (
                      f8.NOME[a], f8.NOME_P[(a, k)], cps, len(es), sum(1 for e in es if e["primeira"]),
                      (" sem $: %d" % sem) if sem else "", min(e["din_antes"] for e in es),
                      mm(med([e["p1"] for e in es])), mm(pct([e["p1"] for e in es], .9)),
                      mm(med([e["p1_ne"] for e in es])), mm(pct([e["p1_ne"] for e in es], .9)),
                      mm(med([e["gap10"] for e in es])), mm(pct([e["gap10"] for e in es], .9)), mm(max(e["gap10"] for e in es)),
                      mm(pct([e["gap10_ne"] for e in es], .9)), mm(max(e["gap10_ne"] for e in es)),
                      med([e["up5_n"] for e in es]), mm(med([e["up5_fim"] for e in es])), mm(pct([e["up5_fim"] for e in es], .9)),
                      f4.fmtk(med(am(300, 2))), f4.fmtk(med(am(600, 2))), f4.fmtk(med(am(STINT - 10, 2))),
                      med(r10) or 0, 100 * (med(s0) or 0), 100 * (med(share(600)) or 0), 100 * (med(share(STINT - 10)) or 0),
                      100 * min(share(STINT - 10) or [0])), flush=True)
            pats = [p for _, _, x in res for p in x["patroc"] if p[1]]
            if pats:
                emq = {}
                for p in pats:
                    emq[p[1]] = emq.get(p[1], 0) + 1
                print("  - patrocinio (campanhas com James vencido e contrato): %d; assinou depois de %s; bonus total med $%s" % (
                    len(pats), ", ".join("%s %d" % (f5.OPP_CURTO.get(i, i), q) for i, q in sorted(emq.items(), key=lambda kv: -kv[1])),
                    "%.0f" % med([p[2] for p in pats])), flush=True)
    return T


# =================================================================== legado: o que sobra por campanha
def sec_legado(n, K, T=None):
    print("\n## Legado que sobra depois das compras da arvore, por campanha (mediana), com e sem o centro; e quando a regiao CENTRO fecha")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l()[:1]:
            com = T[(a, k, cps)] if T and (a, k, cps) in T else rodar_combo(a, k, cps, n, K, on=True)
            sem = rodar_combo(a, k, cps, n, K, on=False)

            def linha(res):
                por = {}
                for recs, _, _ in res:
                    for r in recs:
                        por.setdefault(r["k"], []).append(r.get("legado_sobra", 0))
                return " ".join("%d" % med(por[i]) for i in sorted(por))
            fecha, abre = [], []
            for recs, _, _ in com:
                ab = next((r["k"] for r in recs if r.get("centro_aberto")), None)
                fe = next((r["k"] for r in recs if r.get("nos_ctr") == len(NOS)), None)
                abre.append(ab if ab else 99)
                fecha.append((fe - ab) if (fe and ab) else 99)
            print("- %s %s %d/s: sobra com o centro: %s | sem: %s | 1a mudanca (campanha med) %s; campanhas da 1a mudanca ate a regiao "
                  "fechar (med; p90) %s; %s" % (f8.NOME[a], f8.NOME_P[(a, k)], cps, linha(com), linha(sem),
                                                f4.fmtk(med(abre)), f4.fmtk(med(fecha)), f4.fmtk(pct(fecha, .9))), flush=True)


# =================================================================== exportar: contas exatas para o teste do Godot
def sec_exportar():
    casos = {"_doc": "Fase 8a2: contas exatas do centro (gerado por tools/sim/fase8a2_sim.py exportar). custo_aluno[n] = "
                     "Economia.custo_gerador(base, growth, n); mult_centro[i] = training_mult x (1 + gym_training_bonus) com o "
                     "bonus da lista; patrocinio[id] = floor(prize_money x prize_share + 0,5).",
             "move": {"cost": LOC["move"]["cost"], "training_mult": LOC["training_mult"]},
             "custo_aluno": [f2.custo_gerador(GEN, i) for i in range(41)],
             "mult_centro": [[b, float(LOC["training_mult"]) * (1.0 + b)] for b in (0.0, 0.25, 0.5)],
             "patrocinio": {}, "nos": {n["id"]: n["cost"] for n in NOS}}
    with open(os.path.join(RAIZ, "data", "opponents.json"), encoding="utf-8") as fh:
        opps = json.load(fh)["opponents"] + f8.REG
    for o in opps:
        casos["patrocinio"][o["id"]] = math.floor(o["prize_money"] * SP["prize_share"] + 0.5)
    destino = os.path.join(RAIZ, "tests", "data", "fase8a2_casos.json")
    with open(destino, "w", encoding="utf-8") as fh:
        json.dump(casos, fh, ensure_ascii=False, indent=1)
    print("gravado %s" % destino)


def main():
    f8._init8(quieto=True)
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    n, K = int(os.environ.get("SIM_N8", "48")), int(os.environ.get("SIM_K8", "10"))
    print("Centro: %s; mudanca $%g x%g; aluno %s; 5a melhoria %s; patrocinio %s; nos %s" % (
        "LIGADO" if ON else "DESLIGADO", LOC["move"]["cost"], LOC["training_mult"],
        (GEN["base_cost"], GEN["growth"], GEN["production"]), sorted(set(u["cost"] for u in UP5.values())),
        (SP["fame_at_least"], SP["prize_share"]), [(x["id"], x["cost"]) for x in NOS]), flush=True)
    if "sonda" in secs:
        sec_sonda(int(os.environ.get("SIM_N8", "24")), K)
    if tudo or "ident" in secs:
        sec_ident(int(os.environ.get("SIM_NI", "24")), K)
    T = None
    if tudo or "centro" in secs:
        T = sec_centro(n, K)
    if tudo or "legado" in secs:
        sec_legado(n, K, T)
    if tudo or "exportar" in secs:
        sec_exportar()


if __name__ == "__main__":
    main()
