"""Simulacao da Fase 8b1 (Liga nacional): 4 lutas saindo do centro (2 nacionais com trava, o James preparado que ESTUDA a escola
e o campeao nacional), cinturao nacional, balanco das 6 combinacoes, previa honesta e o teto/chefe da Ronda 2a com a liga junto.

Design: docs/fases/fase8b1-design.md. Valores: data/league_national.json. Roda em cima do fase8a2_sim.py (que traz 8a1 + 8a2).
So ACRESCENTA (nenhum arquivo antigo e editado; os remendos ficam aqui):
  1. os 4 nacionais no fim da escada (no simulador com location "gym", para o laco antigo tratar como "depois da academia";
     no jogo eles tem location "center");
  2. a mudanca para o centro acontece NA HORA em que o robo vence o James regional (e nao mais depois da escada completa);
     o robo fica no centro seguindo o calendario dos nacionais (antes da data so luta no VERDE, no dia luta no AMARELO e passa
     o posto no VERMELHO, a regra de sempre);
  3. o James preparado: passiva = guarda + travas do 'study' no tipo da passiva com que a escola o venceu da ultima vez numa
     campanha ANTERIOR (sem isso: so a guarda). Mesma conta da 8a1 (locks + guard): nada novo no motor.
SIM_NAC_ON=0 (ou sem data/league_national.json) = robo da 8a2, byte a byte (o T_MAX sobe para 4 h nos dois).

Rodar:  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/sim/fase8b1_sim.py [secao ...]
Secoes: sonda (crescimento no centro: atributos X min depois de chegar, por campanha), ident (nada muda ate a chegada ao centro),
campanha (balanco: 1o cinturao nacional, campanhas depois do 1o Cinturao do Vale, 6 combinacoes, tempo morto, clique, tela),
estados (guarda os atributos reais do robo nas lutas nacionais em SIM_CACHE8B), trava (quanto cada passiva tira), saida (nunca
imbativel: melhor tatica no treino mediano), honesta (previa x real, 1000 lutas), teto (ronda2a_sim teto com a liga nacional),
chefe (ronda2a_sim chefe com a liga nacional), exportar (tests/data/fase8b1_casos.json).
Alavancas: SIM_NAC="opp_nac_1=F,A,R;..." (atributos), SIM_NAC_DIAS="d1,d2,d3,d4", SIM_NAC_LOCK="opp_nac_1.counter_punch.ko_cap=0.3;..."
(travas; 'study' no James: opp_james_nac.study.shin.spin_ko=0.3), SIM_NAC_GUARD="rounds,mult" (James preparado),
SIM_STUDY ("auto" = a regra; "" = nunca estuda; "own" = sempre o tipo da combinacao), SIM_N8B (jogadores; 48), SIM_K8B
(campanhas; 12), SIM_CPS, SIM_COMBOS.
"""
import copy
import json
import math
import os
import random
import sys
from multiprocessing import Pool

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import fase2_sim as f2  # noqa: E402
import fase4_sim as f4  # noqa: E402
import fase5_sim as f5  # noqa: E402
import fase6c2_sim as f6  # noqa: E402
import fase8a1_sim as f8  # noqa: E402
import fase8a2_sim as f82  # noqa: E402

med, pct, mm = f4.mediana, f4.pct, f4.mm
RAIZ = f2.RAIZ
TIPOS = ["fast_hands", "counter_punch", "submission", "top_control", "shin", "thai_clinch"]
TIPO_DA = f8.TIPO_DA
NOME_T = {"fast_hands": "Mao rapida", "counter_punch": "Contragolpista", "submission": "Finalizacao", "top_control": "Por cima",
          "shin": "Canela", "thai_clinch": "Clinch", "": "nenhum"}


# =================================================================== dados
def carregar_nac():
    p = os.path.join(RAIZ, "data", "league_national.json")
    if not os.path.exists(p):
        return None, []
    with open(p, encoding="utf-8") as fh:
        L = json.load(fh)
    ops = [copy.deepcopy(o) for o in L["opponents"]]
    if os.environ.get("SIM_NAC"):
        for item in os.environ["SIM_NAC"].split(";"):
            i, v = item.split("=")
            F, A, R = (float(x) for x in v.split(","))
            next(o for o in ops if o["id"] == i).update(strength=F, agility=A, endurance=R)
    if os.environ.get("SIM_NAC_DIAS"):
        for o, d in zip(ops, os.environ["SIM_NAC_DIAS"].split(",")):
            o["prep_days"] = int(d)
    if os.environ.get("SIM_NAC_PRIZE"):
        for o, v in zip(ops, os.environ["SIM_NAC_PRIZE"].split(";")):
            mo, fa = v.split(",")
            o["prize_money"], o["prize_fame"] = float(mo), float(fa)
    if os.environ.get("SIM_NAC_LOCK"):
        for item in os.environ["SIM_NAC_LOCK"].split(";"):
            k, v = item.split("=")
            partes = k.split(".")
            o = next(x for x in ops if x["id"] == partes[0])
            if partes[1] == "study":
                o["passive"].setdefault("study", {}).setdefault(partes[2], {})[partes[3]] = float(v)
            else:
                o["passive"].setdefault("locks", {}).setdefault(partes[1], {})[partes[2]] = float(v)
    if os.environ.get("SIM_NAC_GUARD"):
        r, m = (float(x) for x in os.environ["SIM_NAC_GUARD"].split(","))
        next(o for o in ops if "study" in o.get("passive", {}))["passive"]["guard"] = {"rounds": r, "taken_mult": m}
    if os.environ.get("SIM_SONDA") == "1":          # sonda: ninguem vence e a data fica longe (o robo fica no centro)
        for o in ops:
            o.update(strength=1e15, agility=1e15, endurance=1e15, prep_days=int(os.environ.get("SIM_SONDA_DIAS", "100")))
            o["passive"] = {}
    return L, ops


LIGA8, NAC = carregar_nac()
ON8 = bool(NAC) and os.environ.get("SIM_NAC_ON", "1") == "1"
NAC_IDS = [o["id"] for o in NAC]
JN = next((o for o in NAC if "study" in o.get("passive", {})), None)
JN_ID = JN["id"] if JN else None
CHAMP_ID = next((o["id"] for o in NAC if o.get("national_belt")), NAC_IDS[-1] if NAC_IDS else None)
CURTO8 = {"opp_nac_1": "Nac1", "opp_nac_2": "Nac2", "opp_james_nac": "JamesN", "opp_nac_champ": "Campeao"}
f8.CURTO.update(CURTO8)
f5.OPP_CURTO.update(CURTO8)
STUDY_MODE = os.environ.get("SIM_STUDY", "auto")


def _t(o):
    return (o["strength"], o["agility"], o["endurance"])


# passiva efetiva do James preparado por tipo estudado ('' = so a guarda). Dicts fixos (o cache do f8 usa id()).
PV = {}
if JN:
    for tp in [""] + TIPOS:
        pv = {"id": JN["passive"]["id"]}
        if JN["passive"].get("guard"):
            pv["guard"] = dict(JN["passive"]["guard"])
        if tp and tp in JN["passive"].get("study", {}):
            pv["locks"] = {tp: dict(JN["passive"]["study"][tp])}
        PV[tp] = pv
for o in NAC:
    if o is not JN and o.get("passive"):
        f8.PAS[_t(o)] = o["passive"]
if JN:
    f8.PAS[_t(JN)] = PV[""]


def usar_estudo(tp):
    if JN:
        f8.PAS[_t(JN)] = PV.get(tp, PV[""])


# =================================================================== escada: os nacionais depois dos regionais
_init8_orig = f8._init8


def _init8b(quieto=True):
    _init8_orig(quieto)
    R = f5.DADOS[0]
    sem = [o for o in R.opp if o["id"] not in NAC_IDS]
    if not ON8 or os.environ.get("SIM_SEM_LIGA") == "1":
        R.opp = sem
        return
    R.opp = sem + [dict(o, location="gym", league="national") for o in NAC]
    for o in NAC:
        f5.CAL["prep"][o["id"]] = int(o["prep_days"])


f8._init8 = _init8b


def ligar8(on):
    global ON8
    ON8 = bool(on) and bool(NAC)


# linhagem: o que o James estudou (um jogador por vez em cada processo)
_S8 = {}


def _zerar8():
    _S8.clear()
    _S8.update({"last": "", "last_k": 0, "prev": "", "camp": [], "nb": 0})


_zerar8()
_zerar_82 = f82._zerar_linhagem


def _zerar_linhagem8():
    _zerar_82()
    _zerar8()


f82._zerar_linhagem = _zerar_linhagem8


def estudado(k):
    if STUDY_MODE == "":
        return ""
    if STUDY_MODE == "own":
        return _S8.get("own", "")
    if STUDY_MODE in TIPOS:
        return STUDY_MODE
    return _S8["last"] if _S8["last_k"] < k else _S8["prev"]


def _gravar_vitoria_james(self):
    tp = _tipo(self)
    if _S8["last_k"] != self.k:
        _S8["prev"] = _S8["last"]
    _S8["last"], _S8["last_k"] = tp, self.k


# =================================================================== mudanca na hora da vitoria sobre o James
def _mudar_centro(self):
    C, LOC, GEN, UP5 = f82.C, f82.LOC, f82.GEN, f82.UP5
    f82._ST["cint"] += 1
    custo = float(LOC["move"]["cost"])
    if self.dinheiro + 1e-9 < custo:
        f82._ST["sem_dinheiro"] += 1
        self.fim = ("topo", self.t)
        return
    self.dinheiro -= custo
    f82._ST["centro"] = True
    self.loc = float(LOC["training_mult"]) * (1.0 + self.b.get("gym_training_bonus", 0.0))
    self.gens = list(self.gens) + [GEN]
    self.qtd[GEN["id"]] = 0
    for a in list(self.ups):
        if a in UP5:
            self.ups[a] = list(self.ups[a]) + [UP5[a]]
    self.ctr_t0, self.ctr_ev = self.t, []
    self.t_ctr8 = self.t
    self.morto_antes8 = max(self.morto_pre, self.morto_max, self.morto)   # so medida: o morto do centro conta a parte
    self.morto_max = max(self.morto_max, self.morto)
    self.morto_pre, self.morto_max, self.morto = self.morto_antes8, 0.0, 0.0
    self.clk_ctr8 = getattr(self, "clk", 0.0)


_tl82 = f6.Carreira6.talvez_lutar


def _tipo(self):
    return (self.R.pas or {}).get("type", "") if getattr(self.R, "pas", None) else ""


def _talvez8b(self):
    v0 = self.vitorias
    n0 = len(self.lutas)
    if ON8 and JN and not self.fim and v0 < len(self.R.opp) and self.R.opp[v0]["id"] == JN_ID:
        usar_estudo(_tipo(self) if STUDY_MODE == "own" else getattr(self, "estudo8", ""))
    _tl82(self)
    if not ON8:
        return
    for l in self.lutas[n0:]:
        if l["opp"] in NAC_IDS:
            self.nac8.append((l["opp"], l["win"], l["p"], self.t - getattr(self, "t_ctr8", self.t), l["attr"], l["tat"], l["tela"]))
    if self.fim and self.fim[0] == "passou" and self.fim[2] in NAC_IDS:
        self.nac8.append((self.fim[2], None, None, self.t - getattr(self, "t_ctr8", self.t), self.fim[3], None, None))
    if self.vitorias <= v0:
        return
    oid = self.R.opp[v0]["id"]
    if oid in ("opp_james", JN_ID):
        _gravar_vitoria_james(self)
    if oid == "opp_james" and getattr(self, "ctr_t0", None) is None and f82.C is not None:
        _mudar_centro(self)
    if oid == CHAMP_ID:
        _S8["nb"] += 1


f6.Carreira6.talvez_lutar = _talvez8b

_rodar82 = f6.Carreira6.rodar     # = f82._rodar (8a2: move depois da escada completa + estadia)
SONDA_MIN = [0, 2, 5, 8, 10, 15, 20, 25, 30, 40, 50, 60]
_g3_ant = f5.Carreira5._garagem_f3


def _g3_8(self):
    _g3_ant(self)
    t0 = getattr(self, "t_ctr8", None)
    if t0 is not None and SONDA:
        while self.am8_i < len(SONDA_MIN) and self.t - t0 >= 60 * SONDA_MIN[self.am8_i]:
            self.am8.append((SONDA_MIN[self.am8_i], tuple(self.attr)))
            self.am8_i += 1


SONDA = os.environ.get("SIM_SONDA") == "1"
f5.Carreira5._garagem_f3 = _g3_8


def _rodar8b(self):
    if not ON8:
        return _rodar82(self)
    if getattr(self, "_r8b", False):
        return self
    self._r8b = True
    self.nac8 = []
    self.am8, self.am8_i = [], 0
    tp = estudado(self.k)
    self.estudo8 = tp
    f82._rodar_orig(self)
    if STUDY_MODE == "own":
        tp = _tipo(self)
    snap = getattr(self, "snap_kid", None)
    _S8["camp"].append({"k": self.k, "estudo": tp, "nac": list(self.nac8), "t_ctr": getattr(self, "t_ctr8", None),
                        "am": list(self.am8), "fim": self.fim[0], "t_fim": self.fim[1], "snap": snap,
                        "nb": CHAMP_ID in [o["id"] for o in self.R.opp[:self.vitorias]], "morto": self.morto_total(),
                        "morto_ctr": max(self.morto_max, self.morto) if getattr(self, "t_ctr8", None) is not None else None,
                        "morto_antes": getattr(self, "morto_antes8", None)})
    return self


f6.Carreira6.rodar = _rodar8b


def seq(args):
    """Um jogador: a sequencia da 8a2 com a liga nacional. Devolve (recs, campanhas da 8b1)."""
    _S8["own"] = ""
    recs, est, extra = f82.seq(args)
    camp = list(_S8["camp"])
    por_k = {c["k"]: c for c in camp}
    for r in recs:
        r["c8"] = por_k.get(r["k"])
    return recs, camp


def _init_w(arte, k, on):
    ligar8(on)
    f82._init_w(arte, k, True)
    if STUDY_MODE == "own":
        _S8["own"] = TIPO_DA[(arte, k)]


T_MAX = float(os.environ.get("SIM_TMAX8", str(4 * 3600)))
f5.T_MAX5 = T_MAX


def rodar_combo(arte, k, cps, n, K, on=True):
    tarefas = [(cps, 1000 + s, K, "padrao", arte, "normal", T_MAX) for s in range(n)]
    with Pool(f8._proc(), initializer=_init_w, initargs=(arte, k, on)) as pool:
        return pool.map(seq, tarefas, chunksize=1)


def _cps_l():
    return tuple(int(x) for x in os.environ.get("SIM_CPS", "4,3").split(","))


def _adv(oid):
    return f8._adv(oid)


# =================================================================== sonda: quanto o robo cresce no centro
SONDA_OUT = {}


def sec_sonda(n, K):
    print("\n## Sonda: atributos (F+A+R) do robo X min depois de chegar ao centro (mediana), por campanha contada do 1o Cinturao do "
          "Vale (1 = a campanha dele). Nacionais impossiveis e data a 130 dias: o robo so treina.")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            res = rodar_combo(a, k, cps, n, K, on=True)
            por = {}
            dirs = {}
            vet = {}
            for recs, camp in res:
                ks = [c["k"] for c in camp if c["am"]]
                if not ks:
                    continue
                k1 = ks[0]
                for c in camp:
                    if not c["am"]:
                        continue
                    i = c["k"] - k1 + 1
                    for m, at in c["am"]:
                        por.setdefault((min(i, 4), m), []).append(sum(at))
                        vet.setdefault((min(i, 4), m), []).append(at)
                        if m == 20:
                            dirs.setdefault(min(i, 4), []).append(tuple(x / sum(at) for x in at))
            print("- %s %s %d/s:" % (f8.NOME[a], f8.NOME_P[(a, k)], cps))
            for i in range(1, 5):
                cel = ["%d min %.3g" % (m, med(por[(i, m)])) for m in SONDA_MIN if por.get((i, m))]
                d = dirs.get(i)
                dd = (" | F/A/R aos 20 min %.2f/%.2f/%.2f" % tuple(med([x[j] for x in d]) for j in range(3))) if d else ""
                print("  - campanha %s%s (n%d): %s%s" % (i, "+" if i == 4 else "", len(por.get((i, 0), [])), "; ".join(cel), dd),
                      flush=True)
            for (i, m), lst in vet.items():
                SONDA_OUT["%s|%d|%d|%d|%d" % (a, k, cps, i, m)] = _med_vetor(lst)
    if os.environ.get("SIM_SONDA_OUT"):
        with open(os.environ["SIM_SONDA_OUT"], "w", encoding="utf-8") as fh:
            json.dump(SONDA_OUT, fh)


# =================================================================== campanha
def marcos(recs, camp):
    """1o Cinturao do Vale (campanha), 1o cinturao nacional (campanha e tempo acumulado), campanhas entre eles."""
    rv = next((r for r in recs if "opp_james" in r["vit_t"]), None)
    rn = next((r for r in recs if CHAMP_ID in r["vit_t"]), None)
    out = {"vale_k": rv["k"] if rv else 99, "nac_k": rn["k"] if rn else 99, "entre": 99, "nac_t": None}
    if rn:
        out["nac_t"] = rn["t_ini"] + rn["vit_t"][CHAMP_ID]
    if rv and rn:
        out["entre"] = rn["k"] - rv["k"]
    return out


def resumo(res, K):
    ms = [marcos(recs, camp) for recs, camp in res]
    nt = [m["nac_t"] for m in ms if m["nac_t"] is not None]
    entre = [m["entre"] for m in ms if m["vale_k"] < 99]
    lut = [x for _, camp in res for c in camp for x in c["nac"]]
    telas = [x[6] for x in lut if x[6] is not None]
    vit = {o: [0, 0, 0] for o in NAC_IDS}
    ps = {o: [] for o in NAC_IDS}
    for x in lut:
        if x[1] is None:
            vit[x[0]][2] += 1
        else:
            vit[x[0]][0] += 1
            vit[x[0]][1] += x[1]
            ps[x[0]].append(x[2])
    # 1a campanha (contada do 1o Cinturao do Vale) em que a luta foi feita com >= 50% na previa (vencivel) e a 1a vitoria
    venc = {o: [] for o in NAC_IDS}
    win1 = {o: [] for o in NAC_IDS}
    tchega = {o: [] for o in NAC_IDS}
    for (recs, camp), m in zip(res, ms):
        if m["vale_k"] >= 99:
            continue
        for o in NAC_IDS:
            kv = next((c["k"] for c in camp for x in c["nac"] if x[0] == o and x[2] is not None and x[2] >= 0.5), None)
            kw = next((c["k"] for c in camp for x in c["nac"] if x[0] == o and x[1]), None)
            venc[o].append(kv - m["vale_k"] + 1 if kv else 99)
            win1[o].append(kw - m["vale_k"] + 1 if kw else 99)
            tc = [x[3] for c in camp for x in c["nac"] if x[0] == o and x[1] is not None]
            if tc:
                tchega[o].append(tc[0])
    est = {}
    for _, camp in res:
        for c in camp:
            if c["nac"] and c["k"]:
                est.setdefault(c["estudo"], 0)
                est[c["estudo"]] += 1
    morto = [c["morto_ctr"] for _, camp in res for c in camp if c["t_ctr"] is not None]
    morto_a = [c["morto_antes"] for _, camp in res for c in camp if c["t_ctr"] is not None]
    clique = [c["snap"][0] / c["snap"][1] for _, camp in res for c in camp if c["nb"] and c["snap"] and c["snap"][1] > 0]
    fins = {}
    for _, camp in res:
        for c in camp:
            if c["t_ctr"] is None:
                continue
            last = c["nac"][-1] if c["nac"] else None
            if c["nb"]:
                kk = "campeao"
            elif last is None:
                kk = "sem luta"
            elif last[1] is None:
                kk = "p:" + CURTO8[last[0]]
            else:
                kk = "d:" + CURTO8[last[0]]
            fins[kk] = fins.get(kk, 0) + 1
    leg = {}
    for recs, _ in res:
        for r in recs:
            leg.setdefault(r["k"], []).append(r["legado"])
    tcamp = [c["t_fim"] - c["t_ctr"] for _, camp in res for c in camp if c["t_ctr"] is not None]
    return {"nac_med": med(nt) if nt else None, "nac_media": sum(nt) / max(1, len(nt)), "nac_p90": pct(nt, .9) if nt else None,
            "nunca": sum(1 for m in ms if m["nac_t"] is None), "entre": entre, "entre_med": med(entre), "entre_p90": pct(entre, .9),
            "vale_med": med([m["vale_k"] for m in ms]), "tela": (min(telas), max(telas)) if telas else (0, 0), "vit": vit,
            "ps": ps, "venc": venc, "win1": win1, "tchega": tchega, "estudo": est, "morto_p90": pct(morto, .9) if morto else 0,
            "morto_max": max(morto) if morto else 0, "morto_a": pct(morto_a, .9) if morto_a else 0, "clique": (med(clique), min(clique)) if clique else (0, 0), "fins": fins,
            "legado": [med(leg[i]) for i in sorted(leg)], "tcentro": (med(tcamp), pct(tcamp, .9)) if tcamp else (0, 0),
            "n": len(res)}


EST_CAMP = {}


def sec_campanha(n, K):
    print("\n## Campanha 8b1 (robo padrao da 8a2 com a liga nacional: calendario, Legado, hall, centro; %d jogadores x %d campanhas). "
          "Estudo do James: %s" % (n, K, STUDY_MODE))
    print("| combinacao | cps | 1o Vale (campanha med) | 1o cinturao nacional: mediana / media / p90 | campanhas do 1o Vale ao 1o nacional (med; p90; "
          "0/1/2/3/4/5/6+) | nunca em %d | lutas: vitorias / lutas / passou (Nac1, Nac2, JamesN, Campeao) | previa na luta (med) | "
          "fim no centro | tela | morto no centro p90 (max) [antes do centro p90] | tempo no centro (med; p90) |" % K)
    print("|---|---|---|---|---|---|---|---|---|---|---|---|")
    T = {}
    for cps in _cps_l():
        for (a, k) in f8.COMBOS:
            res = rodar_combo(a, k, cps, n, K)
            for _, camp in res:                   # estados reais nas lutas nacionais (para trava/saida/honesta)
                for c in camp:
                    for y in c["nac"]:
                        if y[1] is None:          # so quem lutou (como na 8a1: "ao lutar com ele"); quem passou o posto fica fora
                            continue
                        EST_CAMP.setdefault("%s|%d|%s" % (a, k, y[0]), []).append(list(y[4]))
            x = resumo(res, K)
            T[(a, k, cps)] = x
            dist = [sum(1 for e in x["entre"] if e == i) for i in range(6)] + [sum(1 for e in x["entre"] if 6 <= e < 99)]
            print("| %s %s | %d/s | %s | %s / %s / %s | %s; %s; %s | %d | %s | %s | %s | %.1f-%.1f s | %s (%s) [%s] | %s; %s |" % (
                f8.NOME[a], f8.NOME_P[(a, k)], cps, f4.fmtk(x["vale_med"]), mm(x["nac_med"]), mm(x["nac_media"]), mm(x["nac_p90"]),
                f4.fmtk(x["entre_med"]), f4.fmtk(x["entre_p90"]), "/".join(str(d) for d in dist), x["nunca"],
                ", ".join("%d/%d/%d" % (x["vit"][o][1], x["vit"][o][0], x["vit"][o][2]) for o in NAC_IDS),
                ", ".join("%.0f%%" % (100 * med(x["ps"][o])) if x["ps"][o] else "-" for o in NAC_IDS),
                ", ".join("%s %d" % kv for kv in sorted(x["fins"].items(), key=lambda kv: -kv[1])[:5]),
                x["tela"][0], x["tela"][1], mm(x["morto_p90"]), mm(x["morto_max"]), mm(x["morto_a"]), mm(x["tcentro"][0]), mm(x["tcentro"][1])),
                flush=True)
            print("  - vencivel 1a vez (campanha contada do 1o Vale, med; p75) / 1a vitoria (med; p75): %s" % "; ".join(
                "%s %s;%s / %s;%s" % (CURTO8[o], f4.fmtk(med(x["venc"][o])), f4.fmtk(pct(x["venc"][o], .75)),
                                      f4.fmtk(med(x["win1"][o])), f4.fmtk(pct(x["win1"][o], .75))) for o in NAC_IDS), flush=True)
            print("  - min no centro ate a 1a luta (med): %s; o James estudou: %s; 1 clique / renda sem a mao no cinturao nacional: "
                  "med %.0f%% (min %.0f%%); Legado por campanha (med): %s" % (
                      ", ".join("%s %s" % (CURTO8[o], mm(med(x["tchega"][o])) if x["tchega"][o] else "-") for o in NAC_IDS),
                      ", ".join("%s %d" % (NOME_T[kk], v) for kk, v in sorted(x["estudo"].items())),
                      100 * x["clique"][0], 100 * x["clique"][1], " ".join("%d" % v for v in x["legado"])), flush=True)
    if os.environ.get("SIM_CACHE8B"):
        with open(os.environ["SIM_CACHE8B"], "w", encoding="utf-8") as fh:
            json.dump(EST_CAMP, fh)
    for cps in _cps_l():
        vs = [T[(a, k, cps)] for (a, k) in f8.COMBOS if (a, k, cps) in T and T[(a, k, cps)]["nac_med"]]
        if not vs:
            continue
        meds = [v["nac_med"] for v in vs]
        en = [v["entre_med"] for v in vs]
        print("- %d/s: 1o cinturao nacional, mediana %s a %s (%.1f%%); campanhas do 1o Vale ao 1o nacional (med) %s a %s" % (
            cps, mm(min(meds)), mm(max(meds)), 100 * (max(meds) / min(meds) - 1), min(en), max(en)))
    return T


# =================================================================== ident: nada muda ate a chegada ao centro
CAMPOS = ("fim", "wins", "belt", "legado", "lutas", "reg53", "vit_t", "honra", "arte")


def _ident_um(args):
    (a, k, cps, s, K) = args
    out = []
    for on in (False, True):
        _init_w(a, k, on)
        recs, _ = seq((cps, 1000 + s, K, "padrao", a, "normal", T_MAX))
        out.append(recs)
    r0, r1 = out
    kj = next((r["k"] for r in r0 if "opp_james" in r["vit_t"]), None)
    ate = (kj - 1) if kj is not None else K
    ok = all(all(x[c] == y[c] for c in CAMPOS) for x, y in zip(r0[:ate], r1[:ate]))
    lutas = sum(len(x["lutas"]) for x in r0[:ate])
    if kj is not None:
        x, y = r0[kj - 1], r1[kj - 1]
        ij = next(i for i, l in enumerate(x["lutas"]) if l[0] == "opp_james" and l[1])
        ok = ok and x["lutas"][:ij + 1] == y["lutas"][:ij + 1] and x["vit_t"]["opp_james"] == y["vit_t"]["opp_james"]
        lutas += ij + 1
    depois = sum(1 for x, y in zip(r0[ate:], r1[ate:]) if any(x[c] != y[c] for c in CAMPOS))
    return ok, lutas, kj, depois, len(r0) - ate


def sec_ident(n, K):
    print("\n## Ident: sem e com a liga nacional, tudo igual ate a vitoria sobre o James na campanha do 1o Cinturao do Vale "
          "(a chegada ao centro)")
    print("| combinacao | cps | jogadores iguais | lutas comparadas | campanha do 1o James (med) | campanhas depois que mudaram |")
    print("|---|---|---|---|---|---|")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            with Pool(f8._proc(), initializer=_init_w, initargs=(a, k, True)) as pool:
                res = pool.map(_ident_um, [(a, k, cps, s, K) for s in range(n)], chunksize=1)
            print("| %s %s | %d/s | %d de %d | %d | %s | %d de %d |" % (
                f8.NOME[a], f8.NOME_P[(a, k)], cps, sum(1 for r in res if r[0]), len(res), sum(r[1] for r in res),
                f4.fmtk(med([r[2] if r[2] else 99 for r in res])), sum(r[3] for r in res), sum(r[4] for r in res)), flush=True)


# =================================================================== estados reais nas lutas nacionais (cache)
def carregar_estados():
    cache = os.environ.get("SIM_CACHE8B", "")
    if cache and os.path.exists(cache):
        with open(cache, encoding="utf-8") as fh:
            return {tuple(kk.split("|")): v for kk, v in json.load(fh).items()}
    est = {}
    for (a, k) in f8.COMBOS:
        for cps in (5, 4, 3):
            for recs, camp in rodar_combo(a, k, cps, int(os.environ.get("SIM_NEST", "24")), int(os.environ.get("SIM_KEST", "10"))):
                for c in camp:
                    for x in c["nac"]:
                        est.setdefault((a, str(k), x[0]), []).append(list(x[4]))
                        est.setdefault((a, str(k), x[0] + "@" + c["estudo"]), []).append(list(x[4]))
    if cache:
        with open(cache, "w", encoding="utf-8") as fh:
            json.dump({"|".join(kk): v for kk, v in est.items()}, fh)
    return est


def _med_vetor(lst):
    return tuple(med([x[i] for x in lst]) for i in range(3))


def _estados(est, a, k, o):
    return est.get((a, str(k), o), [])


def _regras_com(a, k, oid, estudo=None):
    R = f8.regras(a, k)
    if oid == JN_ID:
        usar_estudo(TIPO_DA[(a, k)] if estudo is None else estudo)
    return R


def _chances(args):
    a, k, oid, jog, estudo, sem = args
    R = _regras_com(a, k, oid, estudo)
    if sem:
        R = f8.sem_passiva_adv(R)
    adv = _adv(oid)
    return a, k, oid, estudo, sem, {t: R.chance(jog, adv, t, 200) for t in R.tac_ids}


def _init_pool():
    _init8b(True)


def sec_trava():
    """Treino de referencia = mediana dos atributos que os robos da combinacao tinham ao lutar com aquele adversario (x0,85).
    Nac1/Nac2/Campeao: chance com e sem a passiva. James preparado: estudando o SEU jeito x so a guarda x sem passiva."""
    est = carregar_estados()
    esc = float(os.environ.get("SIM_ESC8", "0.85"))
    tarefas = []
    for o in NAC_IDS:
        for (a, k) in f8.COMBOS:
            lst = _estados(est, a, k, o)
            if not lst:
                continue
            jog = tuple(esc * v for v in _med_vetor(lst))
            if o == JN_ID:
                tarefas += [(a, k, o, jog, TIPO_DA[(a, k)], False), (a, k, o, jog, "", False), (a, k, o, jog, "", True)]
            else:
                tarefas += [(a, k, o, jog, None, False), (a, k, o, jog, None, True)]
    with Pool(f8._proc(), initializer=_init_pool) as pool:
        res = pool.map(_chances, tarefas, chunksize=1)
    tab = {(a, k, o, e, s): c for a, k, o, e, s, c in res}
    print("\n## Trava: chance por tatica (A/D/C) no treino mediano da combinacao naquele degrau x %.2f; melhor tatica entre parenteses" % esc)
    print("| adversario | combinacao | com a passiva (A/D/C; melhor) | sem a passiva | perde (melhor) | James: so a guarda (A/D/C; melhor) |")
    print("|---|---|---|---|---|---|")
    for o in NAC_IDS:
        for (a, k) in f8.COMBOS:
            if o == JN_ID:
                c, s, g = tab.get((a, k, o, TIPO_DA[(a, k)], False)), tab.get((a, k, o, "", True)), tab.get((a, k, o, "", False))
            else:
                c, s, g = tab.get((a, k, o, None, False)), tab.get((a, k, o, None, True)), None
            if not c:
                continue
            f = lambda d: "/".join("%.0f" % (100 * d[t]) for t in ("aggressive", "defensive", "counter")) + " (%.0f%%)" % (100 * max(d.values()))  # noqa: E731
            print("| %s | %s %s | %s | %s | %+.0f | %s |" % (CURTO8[o], f8.NOME[a], f8.NOME_P[(a, k)], f(c), f(s),
                                                     100 * (max(c.values()) - max(s.values())), f(g) if g else "-"))


def sec_saida():
    """Nunca imbativel (criterio 4): melhor tatica no treino mediano (x1,0) daquele degrau, da combinacao (e de todos os robos).
    James preparado com o SEU jeito estudado (o pior caso: quem nao mudou de jeito)."""
    est = carregar_estados()
    tarefas = []
    for o in NAC_IDS:
        todos = [x for ak in f8.COMBOS for x in _estados(est, ak[0], ak[1], o)]
        if not todos:
            continue
        g = _med_vetor(todos)
        for (a, k) in f8.COMBOS:
            lst = _estados(est, a, k, o)
            p = _med_vetor(lst) if lst else g
            e = TIPO_DA[(a, k)] if o == JN_ID else None
            tarefas += [(a, k, o + "#p", p, e, False), (a, k, o + "#g", g, e, False)]
    with Pool(f8._proc(), initializer=_init_pool) as pool:
        res = pool.map(_saida_um, tarefas, chunksize=1)
    tab = {(a, k, o): v for a, k, o, v in res}
    print("\n## Nunca imbativel: melhor tatica no treino mediano daquele degrau (da combinacao / de todos os robos)")
    print("| adversario | " + " | ".join("%s %s" % (f8.NOME[a], f8.NOME_P[(a, k)]) for a, k in f8.COMBOS) + " |")
    print("|---|" + "---|" * len(f8.COMBOS))
    for o in NAC_IDS:
        cel = []
        for (a, k) in f8.COMBOS:
            p, g = tab.get((a, k, o + "#p")), tab.get((a, k, o + "#g"))
            cel.append("%.0f%% %s (%.0f%%)" % (100 * p[0], p[1][:3], 100 * g[0]) if p else "-")
        print("| %s | %s |" % (CURTO8[o], " | ".join(cel)))
    for o in NAC_IDS:
        n = {(a, k): len(_estados(est, a, k, o)) for a, k in f8.COMBOS}
        print("- estados %s: %s" % (CURTO8[o], ", ".join("%s%d %d" % (a[:2], k, v) for (a, k), v in n.items())))


def _saida_um(args):
    a, k, oo, jog, estudo, _ = args
    o = oo.split("#")[0]
    R = _regras_com(a, k, o, estudo)
    adv = _adv(o)
    ps = {t: R.chance(jog, adv, t, 200) for t in R.tac_ids}
    bt = max(ps, key=ps.get)
    return a, k, oo, (ps[bt], bt)


def _honesta_um(args):
    a, k, o, estados, nh, semente = args
    R = _regras_com(a, k, o, None)
    adv = _adv(o)
    rng = random.Random(semente)
    sp = sw = 0.0
    durs = []
    for i in range(nh):
        base = estados[rng.randrange(len(estados))]
        e = 0.6 + 0.8 * rng.random()
        jog = tuple(x * e for x in base)
        tat = R.tac_ids[rng.randrange(3)]
        sp += R.chance(jog, adv, tat, R.risk["samples"])
        r = R.lutar(jog, adv, tat, rng.randrange(1 << 31) + 100000)
        sw += r["win"]
        durs.append(R.tela(r))
    return a, k, o, sp / nh, sw / nh, min(durs), max(durs)


def sec_honesta(nh):
    est = carregar_estados()
    tarefas = []
    for o in NAC_IDS:
        for (a, k) in f8.COMBOS:
            lst = _estados(est, a, k, o) or [x for ak in f8.COMBOS for x in _estados(est, ak[0], ak[1], o)]
            if lst:
                tarefas.append((a, k, o, lst, nh, 88))
    with Pool(f8._proc(), initializer=_init_pool) as pool:
        res = pool.map(_honesta_um, tarefas, chunksize=1)
    print("\n## Previa honesta, liga nacional (%d lutas por adversario e combinacao; atributos reais x 0,6..1,4; tatica sorteada; "
          "James com o jeito da combinacao estudado)" % nh)
    print("| adversario | " + " | ".join("%s %s" % (f8.NOME[a], f8.NOME_P[(a, k)]) for a, k in f8.COMBOS) + " | media | tela |")
    print("|---|" + "---|" * (len(f8.COMBOS) + 2))
    tab = {(a, k, o): (p, w, d0, d1) for a, k, o, p, w, d0, d1 in res}
    pior = 0
    for o in NAC_IDS:
        cel, mp, mw, dd = [], [], [], []
        for (a, k) in f8.COMBOS:
            v = tab.get((a, k, o))
            if not v:
                cel.append("-")
                continue
            cel.append("%.1f / %.1f (%+.1f)" % (100 * v[0], 100 * v[1], 100 * (v[1] - v[0])))
            mp.append(v[0])
            mw.append(v[1])
            dd += [v[2], v[3]]
            pior = max(pior, abs(v[1] - v[0]))
        print("| %s | %s | %.1f / %.1f (%+.1f) | %.1f-%.1f s |" % (CURTO8[o], " | ".join(cel), 100 * sum(mp) / len(mp),
                                                               100 * sum(mw) / len(mw), 100 * (sum(mw) - sum(mp)) / len(mp),
                                                               min(dd), max(dd)))
    print("- pior combinacao isolada: %.1f pontos" % (100 * pior))


# =================================================================== exportar casos exatos (mesmo formato da 8a1)
def sec_exportar():
    G = f8.f7c.Gravador
    import types
    shim = types.SimpleNamespace(Random=G)
    velhos = (f8.f3.random, f8.f7.random, f8.f7b.random)
    f8.f3.random = f8.f7.random = f8.f7b.random = shim
    f8.f7c.RNG = G
    fim = {"dano": "damage", "dano_dele": "damage", "pontos": "points", "nocaute": "knockout", "finalizacao": "submission",
           "chute_rodado": "spin_kick"}
    fim.update(f8.f7c.FINISH_JOGO)
    casos = []
    rng = random.Random(8201)
    try:
        for o in NAC_IDS:
            adv = _adv(o)
            for (a, k) in [(None, 0)] + f8.COMBOS:
                estudos = [None] if o != JN_ID else ([""] if a is None else ["", TIPO_DA[(a, k)]])
                for estudo in estudos:
                    for extra in ((0.0,) if a is None else (0.0, 0.5)):
                        R = f8.regras(a, k, extra) if a else f8._R()
                        if o == JN_ID:
                            usar_estudo(estudo or "")
                        for i in range(3):
                            m = rng.uniform(0.6, 1.4)
                            w = [rng.random() + 0.3 for _ in range(3)]
                            s = sum(w)
                            jog = tuple(sum(adv) * m * x / s for x in w)
                            tat = R.tac_ids[i % 3]
                            semente = 9000 + len(casos)
                            r = R.lutar(jog, adv, tat, semente, registro=True)
                            est = R.estado_passiva(jog, adv, tat) if a else {}
                            ev = [[e["t"], e["who"], e["type"], bool(e.get("counter", False)), e.get("damage", 0.0),
                                   e.get("life_after", 0.0)] for e in r["ev"]]
                            casos.append({"player": list(jog), "opponent_id": o, "opponent": list(adv), "tactic": tat, "art": a or "",
                                          "passive": k, "extra": extra, "studied": estudo or "", "draws": list(G.ultimo.sorteados),
                                          "win": r["win"], "ko": r["ko"], "t_ko": r["t_ko"] if r["t_ko"] is not None else -1.0,
                                          "t_end": r["t"], "pct_player": r["pct"][0], "pct_opponent": r["pct"][1],
                                          "vmax": list(r["vmax"]), "events": ev,
                                          "finish": fim[r.get("metodo", ("dano" if r["win"] else "dano_dele") if r["ko"] else "pontos")],
                                          "chance_200": R.chance(jog, adv, tat, 200),
                                          "est": {kk: v for kk, v in est.items() if isinstance(v, (int, float, bool, str))}})
    finally:
        f8.f3.random, f8.f7.random, f8.f7b.random = velhos
        f8.f7c.RNG = random.Random
        usar_estudo("")
    destino = os.path.join(RAIZ, "tests", "data", "fase8b1_casos.json")
    with open(destino, "w", encoding="utf-8") as fh:
        json.dump({"_doc": "Fase 8b1: lutas contra os 4 nacionais (sem arte e 6 combinacoes, nos 0 e 0,5). James preparado: 'studied' = "
                           "o tipo estudado ('' = so a guarda). draws = todos os sorteios na ordem; chance_200 = previa (sementes "
                           "1..200). Gerado por tools/sim/fase8b1_sim.py exportar.", "exatos": casos}, fh, ensure_ascii=False)
    print("gravado %s: %d casos" % (destino, len(casos)))


# =================================================================== teto e chefe da Ronda 2a com a liga nacional junto
def sec_ronda(secs):
    import ronda2a_sim as r2   # importado DEPOIS dos remendos daqui: a Ronda roda em cima da liga nacional
    r2.ALVOS = tuple(r2.ALVOS) + tuple(NAC_IDS)

    def sec_teto8(n):
        """O mesmo teto da 2a (forca: uma campanha sem calendario, so luta no VERDE, sem derrota, arvore/hall/CENTRO cheios),
        agora ate o campeao nacional. Ganho = 1 - tempo de sala da variante / tempo da 'base', por trecho."""
        ctrs = [int(x) for x in os.environ.get("SIM_CTR_F", "1,0").split(",")]
        AL = r2.ALVOS
        print("\n## TETO com tudo junto e a liga nacional (forca; %d jogadores). Ganho por trecho contra 'base'" % n)
        print("| combinacao | cps | CENTRO | variante | " + " | ".join(f8.CURTO.get(o, f5.OPP_CURTO.get(o, o)) for o in AL) + " | pior |")
        print("|---|---|---|---|" + "---|" * (len(AL) + 1))
        pior_g = (0.0, "")
        for (a, k) in f8.COMBOS:
            for cps in r2._cps_l():
                for ctr in ctrs:
                    tarefas = [(cps, 7000 + s, vi, a, ctr) for vi in range(len(r2.VARS)) for s in range(n)]
                    with Pool(f8._proc(), initializer=r2._init_w, initargs=(a, k, True, "medio", "nenhum", False, False)) as pool:
                        res = pool.map(r2._forca_um, tarefas, chunksize=2)
                    T = {}
                    for vi, (nome, _, _) in enumerate(r2.VARS):
                        rr = res[vi * n:(vi + 1) * n]
                        T[nome] = {o: (med([r[0][o] for r in rr if o in r[0]]) if any(o in r[0] for r in rr) else None) for o in AL}
                    for nome, _, _ in r2.VARS:
                        t = T[nome]
                        g = [100 * (1 - t[o] / T["base"][o]) if t[o] and T["base"][o] else 0.0 for o in AL]
                        pior = max(g)
                        if nome != "base" and pior > pior_g[0]:
                            pior_g = (pior, "%s %s %d/s CENTRO %d %s %s" % (f8.NOME[a], f8.NOME_P[(a, k)], cps, ctr, nome, AL[g.index(pior)]))
                        cel = [("%s (%+.1f%%)" % (mm(t[o]), g[i]) if nome != "base" else mm(t[o])) if t[o] else "-" for i, o in enumerate(AL)]
                        print("| %s %s | %d/s | %d | %s | %s | %.1f%% |" % (f8.NOME[a], f8.NOME_P[(a, k)], cps, ctr, nome, " | ".join(cel), pior),
                              flush=True)
        print("- PIOR TRECHO de todas as variantes: %.1f%% (%s)" % pior_g)
    r2.sec_teto = sec_teto8
    f8._init8(quieto=True)
    if "teto" in secs:
        r2.sec_teto(int(os.environ.get("SIM_NF", "24")))
    if "chefe" in secs:
        r2.sec_chefe(int(os.environ.get("SIM_NC", "12")), int(os.environ.get("SIM_KC", "14")))


def main():
    f8._init8(quieto=True)
    secs = sys.argv[1:] or ["campanha"]
    print("Liga nacional %s: %s; estudo %s; T_MAX %.0f min" % (
        "LIGADA" if ON8 else "DESLIGADA",
        json.dumps([(o["id"], o["strength"], o["agility"], o["endurance"], o["prize_money"], o["prize_fame"], o["prep_days"],
                     o.get("passive", {}).get("id")) for o in NAC], ensure_ascii=False), STUDY_MODE, T_MAX / 60), flush=True)
    n, K = int(os.environ.get("SIM_N8B", "48")), int(os.environ.get("SIM_K8B", "12"))
    if "sonda" in secs:
        sec_sonda(int(os.environ.get("SIM_N8B", "16")), int(os.environ.get("SIM_K8B", "10")))
    if "ident" in secs:
        sec_ident(int(os.environ.get("SIM_NI", "24")), int(os.environ.get("SIM_K8B", "10")))
    if "campanha" in secs:
        sec_campanha(n, K)
    if "estados" in secs:
        carregar_estados()
    if "trava" in secs:
        sec_trava()
    if "saida" in secs:
        sec_saida()
    if "honesta" in secs:
        sec_honesta(int(os.environ.get("SIM_NH", "1000")))
    if "exportar" in secs:
        sec_exportar()
    if "teto" in secs or "chefe" in secs:
        sec_ronda(secs)


if __name__ == "__main__":
    main()
