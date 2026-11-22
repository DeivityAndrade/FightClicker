"""Simulacao da Fase 8a1 (Liga regional): 4 lutas depois do Kid (3 adversarios que travam UM jeito de lutar + James Blindado),
passivas dos adversarios, cinturao regional, balanco das 6 combinacoes ate o cinturao regional, previa honesta e D3/D4.

Design: docs/fases/fase8a1-design.md. Valores: data/league_regional.json (adversarios, premios, dias, passivas). Roda em cima do
fase7b2_sim.py (que ja traz 7a1 + 7b1 + 7b2). So ACRESCENTA:
  1. os 4 adversarios regionais no fim da escada (location gym; o indice so cresce);
  2. passiva do adversario: "locks" = multiplicadores em campos da passiva do JOGADOR, por tipo (so contra ele);
                            "guard"  = dano NELE x taken_mult enquanto t < rounds x round_length (James);
  3. a guarda entra nos 7 lacos (sem arte, Mao rapida/Finalizacao, Canela, Contragolpista, Por cima, Clinch) por uma linha
     acrescentada logo depois da variacao do dano (o codigo antigo nao e editado: o laco e recompilado com a linha a mais).
Contra os 6 adversarios de hoje nada muda (secao ident: lutas identicas). Mesmos sorteios, mesma ordem.

Rodar:  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/sim/fase8a1_sim.py [secao ...]
Secoes: ident, curva, limiar, trava, saida, sinal, previa, honesta, campanha, d3, exportar, tudo (= ident trava saida previa honesta campanha).
SIM_CACHE8=arquivo guarda os estados reais do robo nas lutas regionais (trava, saida, sinal, honesta, limiar); SIM_SEM_LIGA=1 = escada de hoje.
Alavancas: SIM_REG="opp_reg_1=F,A,R;..." (atributos), SIM_LOCK="opp_reg_1.fast_hands.ko_per_streak=0.2;..." (travas),
SIM_GUARD="rounds,taken_mult" (James), SIM_PAS8=0 (adversarios sem passiva: linha de base), SIM_N8 (jogadores; 120),
SIM_K8 (campanhas; 10), SIM_NH (lutas da honesta; 1000), SIM_CPS ("4,3"), SIM_COMBOS (como na 7b2).
"""
import copy
import inspect
import json
import math
import os
import random
import re
import sys
import textwrap
import types
from multiprocessing import Pool

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import fase3_sim as f3  # noqa: E402
import fase4_sim as f4  # noqa: E402
import fase5_sim as f5  # noqa: E402
import fase6c2_sim as f6  # noqa: E402
import fase7a1_sim as f7  # noqa: E402
import fase7b1_sim as f7b  # noqa: E402
import fase7b2_sim as f7c  # noqa: E402

med = f4.mediana
pct = f4.pct
mm = f4.mm
NOME, NOME_P = f7c.NOME, f7c.NOME_P
COMBOS = f7c.COMBOS
FIM1, FIM2 = f7c.FIM1, f7c.FIM2
PAS_ON = os.environ.get("SIM_PAS8", "1") == "1"
VELHOS = ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
CURTO = {"opp_reg_1": "Bigorna", "opp_reg_2": "Estaca", "opp_reg_3": "Sabao", "opp_james": "James"}
f5.OPP_CURTO.update(CURTO)
TIPO_DA = {("boxing", 1): "fast_hands", ("boxing", 2): "counter_punch", ("bjj", 1): "submission", ("bjj", 2): "top_control",
           ("muay_thai", 1): "shin", ("muay_thai", 2): "thai_clinch"}


# =================================================================== dados da liga
def carregar_liga():
    with open(os.path.join(f7b.f2.RAIZ, "data", "league_regional.json"), encoding="utf-8") as fh:
        L = json.load(fh)
    ops = [dict(o) for o in L["opponents"]]
    if os.environ.get("SIM_REG"):
        for item in os.environ["SIM_REG"].split(";"):
            i, v = item.split("=")
            F, A, R = (float(x) for x in v.split(","))
            next(o for o in ops if o["id"] == i).update(strength=F, agility=A, endurance=R)
    for o in ops:
        o["passive"] = copy.deepcopy(o.get("passive", {}))
    if os.environ.get("SIM_LOCK"):
        for item in os.environ["SIM_LOCK"].split(";"):
            k, v = item.split("=")
            i, tipo, campo = k.split(".")
            next(o for o in ops if o["id"] == i)["passive"].setdefault("locks", {}).setdefault(tipo, {})[campo] = float(v)
    if os.environ.get("SIM_GUARD"):
        r, m = (float(x) for x in os.environ["SIM_GUARD"].split(","))
        next(o for o in ops if "guard" in o["passive"])["passive"]["guard"] = {"rounds": r, "taken_mult": m}
    if os.environ.get("SIM_PRIZE"):
        for item in os.environ["SIM_PRIZE"].split(";"):
            i, v = item.split("=")
            mo, fa = v.split(",")
            next(o for o in ops if o["id"] == i).update(prize_money=float(mo), prize_fame=float(fa))
    return L, ops


LIGA, REG = carregar_liga()
REG_IDS = [o["id"] for o in REG]
PAS = {(o["strength"], o["agility"], o["endurance"]): o["passive"] for o in REG} if PAS_ON else {}


# =================================================================== a linha da guarda nos 7 lacos (recompila, sem editar)
_LINHA = re.compile(r"^(\s*)d \*= 1 \+ spread \* \(2 \* r_var - 1\)\n", re.M)


def _remendar(mod, fn):
    src = textwrap.dedent(inspect.getsource(fn))
    novo, n = _LINHA.subn(lambda m: m.group(0) + (
        "%sif alvo == 1 and t < self.guard_t:\n%s    d *= self.guard_m\n%sif self.blk8 is not None:\n%s    self.blk8(self, locals())\n"
        % ((m.group(1),) * 4)), src)
    assert n == 1, (fn.__name__, n)
    ns = {}
    exec(compile(novo, "<8a1:%s>" % fn.__name__, "exec"), mod.__dict__, ns)
    return ns[fn.__name__]


ORIG = {"f3": f3.Regras.lutar, "7a1": f7b._lutar_arte_velho, "shin": f7b._lutar_shin, "contra": f7c._lutar_contra,
        "cima": f7c._lutar_cima, "clinch": f7c._lutar_clinch}
f3.Regras.guard_t = -1.0
f3.Regras.guard_m = 1.0
f3.Regras.blk8 = None          # so na medida do sinal (secao sinal): conta o que a trava segurou
f3.Regras.lutar = _remendar(f3, ORIG["f3"])
f7b._lutar_arte_velho = _remendar(f7, ORIG["7a1"])
f7b._lutar_shin = _remendar(f7b, ORIG["shin"])
f7c._lutar_contra = _remendar(f7c, ORIG["contra"])
f7c._lutar_cima = _remendar(f7c, ORIG["cima"])
f7c._lutar_clinch = _remendar(f7c, ORIG["clinch"])


# =================================================================== passiva do adversario (mesma conta na previa e na luta)
def aplicar_travas(P, pv):
    """Copia da passiva do jogador com as travas do adversario (campo x mult). Sem trava para o tipo: a mesma."""
    if P is None or not pv.get("locks", {}).get(P["type"]):
        return P
    P2 = copy.deepcopy(P)
    for campo, m in pv["locks"][P["type"]].items():
        P2[campo] = P2[campo] * m
    return P2


def _com_adv(self, adv):
    pv = PAS.get(tuple(adv))
    if pv is None or self.__dict__.get("_ja8"):
        return self
    cache = self.__dict__.setdefault("_c8", {})
    k = (id(self.pas), id(pv))
    R2 = cache.get(k)
    if R2 is None:
        R2 = copy.copy(self)
        R2._c8 = {}
        R2.pas = aplicar_travas(self.pas, pv)
        g = pv.get("guard")
        if g:
            R2.guard_t = g["rounds"] * self.c["round_length"]
            R2.guard_m = g["taken_mult"]
        R2._sem = self
        R2._ja8 = True
        cache[k] = R2
    return R2


_lutar_ra = f7.RegrasArte.lutar
_estado_ra = f7.RegrasArte.estado_passiva


def lutar8(self, jog, adv, tatica, semente, registro=False):
    R2 = _com_adv(self, adv)
    if not MEDIR or R2 is self or not R2.pas:
        return _lutar_ra(R2, jog, adv, tatica, semente, registro)
    R2.n_blk = 0
    R2.blk8 = _BLK.get(R2.pas["type"])
    R2.sem8 = _estado_ra(self, jog, adv, tatica)
    try:
        r = _lutar_ra(R2, jog, adv, tatica, semente, registro)
    finally:
        R2.blk8 = None
    r["bloqueios"] = R2.n_blk
    return r


MEDIR = False


def _mult_trava(P, P2):
    for campo in ("ko_per_streak", "td_base", "clinch_base"):
        if campo in P and P[campo] > 0:
            return P2[campo] / P[campo]
    return 1.0


def _blk_box(self, L):
    """Mao rapida: tentativa de K.O. de embalo que a trava segurou (o mesmo sorteio derrubaria sem ela)."""
    if L["quem"] != 0 or L["vida"][1] <= 1e-9 * L["vmax"][1]:
        return
    e = min(L["embalo_max"], L["embalo"] + (L["por_contra"] if L["eh_contra"] else L["por_acerto"]))
    v = L["vida"]
    vm = L["vmax"]
    if v[1] <= L["ko_vida"] * vm[1] and (not L["frente"] or v[1] * vm[0] <= v[0] * vm[1]):
        if e * L["ko_passo"] <= L["r_arte"] < e * self.sem8["ko_per_streak"]:
            self.n_blk += 1


def _blk_cima(self, L):
    if L["quem"] != 0 or L["chao"] or L["vida"][1] <= 1e-9 * L["vmax"][1]:
        return
    if L["td"] <= L["r_arte"] < self.sem8["td_chance"]:
        self.n_blk += 1


def _blk_clinch(self, L):
    if L["quem"] != 0 or L["preso"] or L["vida"][1] <= 1e-9 * L["vmax"][1]:
        return
    if L["vida"][1] <= L["cl_vida"] * L["vmax"][1] and L["ent"] <= L["r_arte"] < self.sem8["clinch_chance"]:
        self.n_blk += 1


def _blk_7a1(self, L):
    if L.get("box"):
        _blk_box(self, L)


_BLK = {"fast_hands": _blk_7a1, "top_control": _blk_cima, "thai_clinch": _blk_clinch}


def estado8(self, jog, adv, tatica):
    R2 = _com_adv(self, adv)
    return _estado_ra(R2, jog, adv, tatica)


f7.RegrasArte.lutar = lutar8
f7.RegrasArte.estado_passiva = estado8


def sem_passiva_adv(R):
    """Regras iguais, mas o adversario regional luta sem a passiva (para medir quanto a trava tira)."""
    R2 = copy.copy(R)
    R2._c8 = {}
    R2.__class__ = _SemAdv
    return R2


class _SemAdv(f7.RegrasArte):
    def lutar(self, jog, adv, tatica, semente, registro=False):
        return _lutar_ra(self, jog, adv, tatica, semente, registro)

    def estado_passiva(self, jog, adv, tatica):
        return _estado_ra(self, jog, adv, tatica)


# =================================================================== a escada cresce (depois do _init7)
def _init8(quieto=True):
    f7._init7(quieto=quieto)
    R = f5.DADOS[0]
    if os.environ.get("SIM_SEM_LIGA") == "1":
        return
    if not any(o["id"] == REG_IDS[0] for o in R.opp):
        R.opp = list(R.opp) + [dict(o) for o in REG]
    for o in REG:
        f5.CAL["prep"][o["id"]] = int(o["prep_days"])


def _init_combo8(arte, k):
    _init8(True)
    f7c.usar(arte, k)


def _R():
    return f5.DADOS[0]


def _adv(oid):
    o = next(x for x in _R().opp if x["id"] == oid)
    return (o["strength"], o["agility"], o["endurance"])


def _proc():
    return int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))


def regras(arte, k, extra=0.0):
    if arte is None:
        return _R()
    return f7c.regras(arte, k, extra)


# =================================================================== campanha (robo padrao, com a curva depois do Kid)
CURVA = []


def _t_rodar(self):
    self.curva8 = []
    return _rodar_velho(self)


_rodar_velho = f6.Carreira6.rodar
_tl_velho = f6.Carreira6.talvez_lutar


def _talvez8(self):
    tk = self.t_g.get("opp_gym_2")
    if tk is not None:
        prox = getattr(self, "_c8_prox", None)
        if prox is None:
            self._c8_prox = prox = tk
        if self.t >= prox:
            self.curva8.append((round(self.t - tk), sum(self.attr), tuple(self.attr)))
            self._c8_prox = prox + 60.0
    return _tl_velho(self)


f6.Carreira6.talvez_lutar = _talvez8


def sequencia8(args):
    out = []
    velho = f6.Carreira6.rodar

    def rodar_e_guardar(self):
        self.curva8 = []
        f7.LOG.clear()
        velho(self)
        out.append((list(f7.LOG), list(self.curva8), self.dinheiro_total, self.fama, self.snap_kid))
    f6.Carreira6.rodar = rodar_e_guardar
    try:
        seq = f6.sequencia6(args)
    finally:
        f6.Carreira6.rodar = velho
    for rec, (lutas, cv, din, fama, snap) in zip(seq, out):
        rec["snap"] = snap
        rec["lutas7"] = lutas
        rec["curva8"] = cv
        rec["din"] = din
        rec["fama"] = fama
    return seq


def rodar_combo(arte, k, cps, n, K):
    tarefas = [(cps, 1000 + s, K, "padrao", arte, "normal", f5.T_MAX5) for s in range(n)]
    with Pool(_proc(), initializer=_init_combo8, initargs=(arte, k)) as pool:
        return pool.map(sequencia8, tarefas, chunksize=1)


def marcos(s):
    """Por jogador: campanha (contando a da chegada) e tempo acumulado do 1o Kid e do 1o James; campanhas entre eles."""
    ch = next((r for r in s if r["primeira_chegada"]), None)
    rk = next((r for r in s if "opp_gym_2" in r["vit_t"]), None)
    rj = next((r for r in s if "opp_james" in r["vit_t"]), None)
    out = {"kid_c": 99, "kid_t": None, "jam_c": 99, "jam_t": None, "entre": 99}
    if ch and rk:
        out["kid_c"] = rk["k"] - ch["k"] + 1
        out["kid_t"] = rk["t_ini"] + rk["vit_t"]["opp_gym_2"]
    if ch and rj:
        out["jam_c"] = rj["k"] - ch["k"] + 1
        out["jam_t"] = rj["t_ini"] + rj["vit_t"]["opp_james"]
        if rk:
            out["entre"] = rj["k"] - rk["k"]            # 0 = na mesma campanha do 1o Kid
    return out


def resumo(arte, k, seqs, K):
    ms = [marcos(s) for s in seqs]
    jt = [m["jam_t"] for m in ms if m["jam_t"] is not None]
    kt = [m["kid_t"] for m in ms if m["kid_t"] is not None]
    entre = [m["entre"] for m in ms]
    lut = [l for s in seqs for r in s if r["arte"] for l in r["lutas7"]]
    telas = [l[5] + 3.0 for l in lut if l[0] in REG_IDS]
    vit = {o: [0, 0] for o in REG_IDS}
    for l in lut:
        if l[0] in REG_IDS:
            vit[l[0]][0] += 1
            vit[l[0]][1] += l[3]
    fins = {}
    for s in seqs:
        for r in s:
            if "opp_james" in r["vit_t"]:
                break
            if r["fim"] in ("derrota", "passou") and r["opp"] in REG_IDS:
                kk = r["fim"][0] + ":" + CURTO[r["opp"]]
                fins[kk] = fins.get(kk, 0) + 1
    morto = [r["morto"] for s in seqs for r in s if r.get("mudou")]
    arv = [next((r["k"] for r in s if r.get("arvore_cheia")), 99) for s in seqs]
    snaps = [r["snap"] for s in seqs for r in s if r.get("snap") and "opp_james" in r["vit_t"]]
    clique = [x[0] / x[1] for x in snaps if x[1] > 0]
    leg = {}
    for s in seqs:
        for r in s:
            leg.setdefault(r["k"], []).append(r["legado"])
    return {"clique": (med(clique), min(clique)) if clique else (0, 0), "legado": [med(leg[i]) for i in sorted(leg)],
            "jam_med": med(jt) if jt else None, "jam_media": sum(jt) / max(1, len(jt)), "jam_p90": pct(jt, .9) if jt else None,
            "kid_med": med(kt) if kt else None, "nunca": sum(1 for m in ms if m["jam_t"] is None),
            "entre_med": med(entre), "entre_p90": pct(entre, .9), "entre": entre,
            "tela": (min(telas), max(telas)) if telas else (0, 0), "vit": vit, "fins": fins,
            "morto_p90": pct(morto, .9) if morto else 0, "arv_med": med(arv), "n": len(seqs)}


def sec_campanha(n, K):
    print("\n## Campanha 8a1 (robo padrao 7a1/7b2, calendario, Legado, hall; %d jogadores x %d campanhas). Toda arte 'como se' "
          "liberada na 1a chegada" % (n, K))
    print("| combinacao | cps | 1o Kid (med) | 1o cinturao regional: mediana / media / p90 | campanhas do 1o Kid ao 1o James (med; p90; "
          "distribuicao 0/1/2/3/4/5+) | nunca em %d | lutas regionais: vitorias / lutas (Bigorna, Estaca, Sabao, James) | "
          "fim das carreiras antes do James | tela | morto p90 | arvore cheia (campanha med) |" % K)
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    T = {}
    for cps in tuple(int(x) for x in os.environ.get("SIM_CPS", "4,3").split(",")):
        for (a, k) in COMBOS:
            seqs = rodar_combo(a, k, cps, n, K)
            x = resumo(a, k, seqs, K)
            T[(a, k, cps)] = x
            dist = [sum(1 for e in x["entre"] if e == i) for i in range(5)] + [sum(1 for e in x["entre"] if 5 <= e < 99)]
            print("| %s %s | %d/s | %s | %s / %s / %s | %s; %s; %s | %d | %s | %s | %.1f-%.1f s | %s | %s |" % (
                NOME[a], NOME_P[(a, k)], cps, mm(x["kid_med"]), mm(x["jam_med"]), mm(x["jam_media"]), mm(x["jam_p90"]),
                f4.fmtk(x["entre_med"]), f4.fmtk(x["entre_p90"]), "/".join(str(d) for d in dist), x["nunca"],
                ", ".join("%d/%d" % (x["vit"][o][1], x["vit"][o][0]) for o in REG_IDS),
                ", ".join("%s %d" % kv for kv in sorted(x["fins"].items(), key=lambda kv: -kv[1])[:5]),
                x["tela"][0], x["tela"][1], mm(x["morto_p90"]), f4.fmtk(x["arv_med"])), flush=True)
            print("  - 1 clique / renda sem a mao por s, ao vencer o James: med %.0f%% (min %.0f%%); Legado por campanha (med): %s" % (
                100 * x["clique"][0], 100 * x["clique"][1], " ".join("%d" % v for v in x["legado"])), flush=True)
    for cps in (4, 3):
        vs = [(ak, T[(ak[0], ak[1], cps)]) for ak in COMBOS if (ak[0], ak[1], cps) in T and T[(ak[0], ak[1], cps)]["jam_med"]]
        if not vs:
            continue
        meds = [v["jam_med"] for _, v in vs]
        medias = [v["jam_media"] for _, v in vs]
        print("- %d/s: 1o cinturao regional, mediana %s a %s (%.1f%%); media %s a %s (%.1f%%)" % (
            cps, mm(min(meds)), mm(max(meds)), 100 * (max(meds) / min(meds) - 1), mm(min(medias)), mm(max(medias)),
            100 * (max(medias) / min(medias) - 1)))
    return T


# =================================================================== curva: treino depois do 1o Kid (para escolher os atributos)
def sec_curva(n, K):
    print("\n## Curva: total de atributos (F+A+R) do robo X minutos depois de vencer o Kid, por campanha (mediana)")
    for (a, k) in COMBOS[:1] + COMBOS[2:3] + COMBOS[4:5]:
        for cps in (4,):
            seqs = rodar_combo(a, k, cps, n, K)
            por = {}
            for s in seqs:
                i = 0
                for r in s:
                    if not r.get("curva8"):
                        continue
                    i += 1
                    for (dt, tot, _) in r["curva8"]:
                        por.setdefault((i, dt // 60), []).append(tot)
            print("- %s %s %d/s:" % (NOME[a], NOME_P[(a, k)], cps))
            for i in range(1, 6):
                cel = []
                for m in (0, 2, 5, 8, 10, 15, 20, 30, 45):
                    v = por.get((i, m))
                    cel.append("%d min %.3g (n%d)" % (m, med(v), len(v)) if v else "%d min -" % m)
                print("  - Kid n%d: %s" % (i, "; ".join(cel)))


# =================================================================== ident: os 6 de hoje iguais (motor e previa)
def sec_ident():
    R0 = _R()
    rng = random.Random(81)
    tot = iguais = 0
    for i in range(3000):
        oid = VELHOS[rng.randrange(6)]
        adv = _adv(oid)
        jog = tuple(sum(adv) * rng.random() for _ in range(3))
        tat = R0.tac_ids[rng.randrange(3)]
        for (a, k) in [(None, 0)] + COMBOS:
            if a is None:
                x = R0.lutar(jog, adv, tat, i)
                y = ORIG["f3"](R0, jog, adv, tat, i)
            else:
                R = regras(a, k, 0.5 if i % 2 else 0.0)
                x = R.lutar(jog, adv, tat, i)
                fn = {"fast_hands": ORIG["7a1"], "submission": ORIG["7a1"], "shin": ORIG["shin"], "counter_punch": ORIG["contra"],
                      "top_control": ORIG["cima"], "thai_clinch": ORIG["clinch"]}[R.pas["type"]]
                y = fn(R, jog, adv, tat, i, False)
            tot += 1
            iguais += (x["win"], x["t"], x["pct"]) == (y["win"], y["t"], y["pct"])
    print("\n## Identidade: contra os 6 de hoje, lutas iguais ao motor da 7b2 (sem arte + 6 combinacoes, guarda e travas "
          "ligadas): %d de %d" % (iguais, tot))


# =================================================================== estados reais do robo na hora das lutas regionais
def estados_reg(arte, k, n=24, K=8, cps_l=(5, 4, 3)):
    est = {}
    for cps in cps_l:
        for s in rodar_combo(arte, k, cps, n, K):
            for r in s:
                if r["arte"] == arte:
                    for l in r["lutas7"]:
                        if l[0] in REG_IDS or l[0] == "opp_gym_2":
                            est.setdefault(l[0], []).append(l[2])
    return est


def _med_vetor(lst):
    return tuple(med([x[i] for x in lst]) for i in range(3))


# =================================================================== trava: quanto cada passiva tira de cada combinacao
def _trava_um(args):
    arte, k, oid, jog = args
    R = regras(arte, k)
    R0 = sem_passiva_adv(R)
    adv = _adv(oid)
    com = {t: R.chance(jog, adv, t, 200) for t in R.tac_ids}
    sem = {t: R0.chance(jog, adv, t, 200) for t in R.tac_ids}
    return arte, k, oid, com, sem


def sec_trava(cache=None):
    """Estado de referencia = 'treino mediano do degrau' da combinacao: mediana (por atributo) dos atributos que os robos DAQUELA
    combinacao (3/4/5 cliques/s) tinham ao lutar contra aquele adversario, x ESC (0,85: um pouco abaixo de onde o robo luta,
    a luta ainda e disputada). Chance com a passiva dele e sem ela, nas 3 taticas."""
    esc = float(os.environ.get("SIM_ESC8", "0.85"))
    est = carregar_estados(cache)
    tarefas = []
    for o in REG_IDS:
        for (a, k) in COMBOS:
            lst = _estados_de(est, a, k, o)
            if lst:
                tarefas.append((a, k, o, tuple(esc * v for v in _med_vetor(lst))))
    with Pool(_proc(), initializer=_init8) as pool:
        res = pool.map(_trava_um, tarefas, chunksize=1)
    print("\n## Trava: chance COM a passiva dele / SEM, no treino mediano da combinacao naquele degrau x %.2f" % esc)
    print("| adversario | combinacao | treino (x o total dele) | Agressivo com / sem | Defensivo com / sem | Contra-ataque com / sem | melhor com | melhor sem | perde |")
    print("|---|---|---|---|---|---|---|---|---|")
    ref = {(a, k, o): j for a, k, o, j in tarefas}
    for (a, k, o, com, sem) in sorted(res, key=lambda x: (REG_IDS.index(x[2]), COMBOS.index((x[0], x[1])))):
        bc, bs = max(com.values()), max(sem.values())
        j = ref[(a, k, o)]
        print("| %s | %s %s | %.2f (%.0f/%.0f/%.0f) | %s | %.0f%% | %.0f%% | %+.0f |" % (
            CURTO[o], NOME[a], NOME_P[(a, k)], sum(j) / sum(_adv(o)), *(100 * x / sum(j) for x in j),
            " | ".join("%.0f%% / %.0f%%" % (100 * com[t], 100 * sem[t]) for t in ("aggressive", "defensive", "counter")),
            100 * bc, 100 * bs, 100 * (bc - bs)))
    return ref


def carregar_estados(cache=None):
    cache = cache or os.environ.get("SIM_CACHE8", "")
    if cache and os.path.exists(cache):
        with open(cache, encoding="utf-8") as fh:
            return {tuple(kk.split("|")[:2]) + (kk.split("|")[2],): v for kk, v in json.load(fh).items()}
    est = {}
    for (a, k) in COMBOS:
        e = estados_reg(a, k, n=int(os.environ.get("SIM_NEST", "24")), K=int(os.environ.get("SIM_KEST", "8")))
        for o, lst in e.items():
            est[(a, str(k), o)] = lst
    if cache:
        with open(cache, "w", encoding="utf-8") as fh:
            json.dump({"|".join(kk): v for kk, v in est.items()}, fh)
    return est


def _estados_de(est, a, k, o):
    return est.get((a, str(k), o), [])


# =================================================================== nunca imbativel: melhor tatica >= 50% no treino mediano
def sec_saida(cache=None):
    """Para cada adversario e combinacao: chance com a MELHOR tatica no treino mediano (x1,0) que os robos daquela combinacao
    tinham ao lutar com ele, e no treino mediano de todos (a mesma pessoa)."""
    est = carregar_estados(cache)
    tarefas = []
    for o in REG_IDS:
        todos = [x for ak in COMBOS for x in _estados_de(est, ak[0], ak[1], o)]
        if not todos:
            continue
        geral = _med_vetor(todos)
        for (a, k) in COMBOS:
            prop = _estados_de(est, a, k, o)
            tarefas.append((a, k, o, geral, _med_vetor(prop) if prop else geral, len(prop)))
    with Pool(_proc(), initializer=_init8) as pool:
        res = pool.map(_saida_um, tarefas, chunksize=1)
    print("\n## Nunca imbativel (criterio 5): melhor tatica no treino mediano daquele degrau (todos os robos / os da combinacao)")
    print("| adversario | " + " | ".join("%s %s" % (NOME[a], NOME_P[(a, k)]) for a, k in COMBOS) + " |")
    print("|---|" + "---|" * len(COMBOS))
    tab = {(a, k, o): v for a, k, o, v in res}
    for o in REG_IDS:
        cel = []
        for (a, k) in COMBOS:
            v = tab.get((a, k, o))
            cel.append("%.0f%% %s / %.0f%% %s" % (100 * v[0], v[1][:3], 100 * v[2], v[3][:3]) if v else "-")
        print("| %s | %s |" % (CURTO[o], " | ".join(cel)))
    # sem arte: Carreira 1 nao chega
    R0 = _R()
    for o in REG_IDS:
        todos = [x for ak in COMBOS for x in _estados_de(est, ak[0], ak[1], o)]
        if todos:
            g = _med_vetor(todos)
            p = max(R0.chance(g, _adv(o), t, 200) for t in R0.tac_ids)
            print("- sem arte, no mesmo treino mediano: %s %.0f%%" % (CURTO[o], 100 * p))


def _saida_um(args):
    a, k, o, geral, prop, n = args
    R = regras(a, k)
    adv = _adv(o)
    pg = {t: R.chance(geral, adv, t, 200) for t in R.tac_ids}
    pp = {t: R.chance(prop, adv, t, 200) for t in R.tac_ids}
    bg = max(pg, key=pg.get)
    bp = max(pp, key=pp.get)
    return a, k, o, (pg[bg], bg, pp[bp], bp)


# =================================================================== limiar: quanto treino (x o total dele) cada combinacao precisa
def _lim_um(args):
    a, k, o, dire, alvo, com = args
    R = regras(a, k)
    if not com:
        R = sem_passiva_adv(R)
    adv = _adv(o)
    tot = sum(adv)

    def ok(m):
        jog = tuple(m * tot * x for x in dire)
        return any(R.passa(jog, adv, t, 100, alvo) for t in R.tac_ids)
    lo, hi = 0.2, 4.0
    for _ in range(11):
        m = (lo + hi) / 2
        if ok(m):
            hi = m
        else:
            lo = m
    return a, k, o, alvo, com, hi


def sec_limiar(cache=None):
    """Direcao do treino = media das proporcoes F/A/R que o robo da combinacao tinha ao lutar com AQUELE adversario (ou com o
    Kid, se nunca chegou). Limiar = total (x o total dele) para a melhor tatica chegar a 50% e a 90%. Menor = mais facil."""
    est = carregar_estados(cache)
    tarefas = []
    dirs = {}
    for (a, k) in COMBOS:
        for o in REG_IDS:
            lst = _estados_de(est, a, k, o) or _estados_de(est, a, k, "opp_gym_2")
            d = tuple(sum(x[i] / sum(x) for x in lst) / len(lst) for i in range(3))
            dirs[(a, k, o)] = d
            for alvo in (0.5, 0.9):
                for com in (True, False):
                    tarefas.append((a, k, o, d, alvo, com))
    with Pool(_proc(), initializer=_init8) as pool:
        res = pool.map(_lim_um, tarefas, chunksize=2)
    tab = {(a, k, o, al, c): v for a, k, o, al, c, v in res}
    print("\n## Limiar (x total dele) para 50%% / 90%% com a passiva dele [sem a passiva], direcao de treino do robo da combinacao")
    print("| adversario | " + " | ".join("%s %s" % (NOME[a], NOME_P[(a, k)]) for a, k in COMBOS) + " | max/min (50%) |")
    print("|---|" + "---|" * (len(COMBOS) + 1))
    for o in REG_IDS:
        cel = ["%.2f / %.2f [%.2f]" % (tab[(a, k, o, 0.5, True)], tab[(a, k, o, 0.9, True)], tab[(a, k, o, 0.5, False)]) for a, k in COMBOS]
        v = [tab[(a, k, o, 0.5, True)] for a, k in COMBOS]
        print("| %s (%.3g) | %s | %.2f |" % (CURTO[o], sum(_adv(o)), " | ".join(cel), max(v) / min(v)))
    for (a, k) in COMBOS:
        print("- direcao %s %s: %s" % (NOME[a], NOME_P[(a, k)], ", ".join("%s %.2f/%.2f/%.2f" % (CURTO[o], *dirs[(a, k, o)]) for o in REG_IDS)))


# =================================================================== previa honesta (os 4 regionais, 6 combinacoes)
def _honesta_um(args):
    arte, k, opp_id, estados, nh, semente = args
    R = regras(arte, k)
    adv = _adv(opp_id)
    rng = random.Random(semente)
    soma_p, soma_w, met, durs = 0.0, 0, {}, []
    for i in range(nh):
        base = estados[rng.randrange(len(estados))]
        esc = 0.6 + 0.8 * rng.random()
        jog = tuple(x * esc for x in base)
        tat = R.tac_ids[rng.randrange(3)]
        p = R.chance(jog, adv, tat, R.risk["samples"])
        r = R.lutar(jog, adv, tat, rng.randrange(1 << 31) + 100000)
        soma_p += p
        soma_w += r["win"]
        kk = r["metodo"] if r["win"] or r["metodo"] == "dano_dele" else "perdeu_pontos"
        met[kk] = met.get(kk, 0) + 1
        durs.append(r["t"] + 3.0)
    return arte, k, opp_id, soma_p / nh, soma_w / nh, met, min(durs), max(durs)


def sec_honesta(nh, cache=None):
    est = carregar_estados(cache)
    print("\n## Previa honesta, liga regional (%d lutas por adversario e combinacao; atributos reais do robo x 0,6..1,4; tatica sorteada)" % nh)
    print("| combinacao | adversario | mostrada | real | diferenca | vitorias: dano / passiva / pontos | derrotas: dano dele / pontos | tela |")
    print("|---|---|---|---|---|---|---|---|")
    tarefas = []
    for (a, k) in COMBOS:
        for o in REG_IDS:
            lst = _estados_de(est, a, k, o) or [x for ak in COMBOS for x in _estados_de(est, ak[0], ak[1], o)]
            if lst:
                tarefas.append((a, k, o, lst, nh, 88))
    res = []
    for (a, k) in COMBOS:
        with Pool(_proc(), initializer=_init_combo8, initargs=(a, k)) as pool:
            res += pool.map(_honesta_um, [t for t in tarefas if t[:2] == (a, k)], chunksize=1)
    pior = 0.0
    por_opp = {}
    for (a, k, o, mp, mw, met, d0, d1) in res:
        pior = max(pior, abs(mw - mp))
        por_opp.setdefault(o, []).append((mp, mw))
        fim = FIM1[a] if k == 1 else FIM2[a]
        print("| %s %s | %s | %.1f%% | %.1f%% | %+.1f | %d / %d / %d | %d / %d | %.1f-%.1f s |" % (
            NOME[a], NOME_P[(a, k)], CURTO[o], 100 * mp, 100 * mw, 100 * (mw - mp), met.get("dano", 0),
            met.get(fim, 0), met.get("pontos", 0), met.get("dano_dele", 0), met.get("perdeu_pontos", 0), d0, d1), flush=True)
    for o in REG_IDS:
        v = por_opp.get(o, [])
        if v:
            print("- %s, media das 6: mostrada %.1f%%, real %.1f%% (%+.1f)" % (
                CURTO[o], 100 * sum(x[0] for x in v) / len(v), 100 * sum(x[1] for x in v) / len(v),
                100 * (sum(x[1] for x in v) - sum(x[0] for x in v)) / len(v)))
    print("- pior combinacao isolada: %.1f pontos" % (100 * pior))


# =================================================================== D3: previa otimista contra Dudu e Brutao
def _d3_um(args):
    arte, k, opp_id, estados, nh, semente, modo = args
    R = regras(arte, k)
    adv = _adv(opp_id)
    rng = random.Random(semente)
    sp = sw = 0.0
    for i in range(nh):
        base = estados[rng.randrange(len(estados))]
        esc = 0.6 + 0.8 * rng.random()
        jog = tuple(x * esc for x in base)
        tat = R.tac_ids[rng.randrange(3)]
        if modo == "previa":
            p = R.chance(jog, adv, tat, R.risk["samples"])
        else:                                       # mesma conta com outras 200 sementes (o ruido das sementes fixas)
            p = sum(R.lutar(jog, adv, tat, 5000 + s)["win"] for s in range(200)) / 200.0
        r = R.lutar(jog, adv, tat, rng.randrange(1 << 31) + 100000)
        sp += p
        sw += r["win"]
    return arte, k, opp_id, modo, sp / nh, sw / nh


def sec_d3(nh):
    print("\n## D3: previa contra Dudu e Brutao (%d lutas; estados reais x 0,6..1,4). 'previa' = sementes 1..200 (as do jogo); "
          "'outras' = sementes 5001..5200" % nh)
    tarefas = []
    for (a, k) in [(None, 0)] + COMBOS:
        est = {}
        if a is None:
            seqs = rodar_combo("boxing", 1, 4, 24, 4)
            for s in seqs:
                for r in s:
                    if not r["arte"]:
                        for l in r["lutas7"]:
                            est.setdefault(l[0], []).append(l[2])
        else:
            for cps in (4, 3):
                for s in rodar_combo(a, k, cps, 16, 6):
                    for r in s:
                        if r["arte"] == a:
                            for l in r["lutas7"]:
                                est.setdefault(l[0], []).append(l[2])
        for o in ("opp_warmup", "opp_strong"):
            if est.get(o):
                for modo in ("previa", "outras"):
                    tarefas.append((a, k, o, est[o], nh, 77, modo))
    with Pool(_proc(), initializer=_init8) as pool:
        res = pool.map(_d3_um, tarefas, chunksize=1)
    print("| combinacao | adversario | previa: mostrada / real (dif) | outras sementes: mostrada / real (dif) |")
    print("|---|---|---|---|")
    tab = {(a, k, o, m): (p, w) for a, k, o, m, p, w in res}
    for (a, k) in [(None, 0)] + COMBOS:
        for o in ("opp_warmup", "opp_strong"):
            if (a, k, o, "previa") in tab:
                p1, w1 = tab[(a, k, o, "previa")]
                p2, w2 = tab[(a, k, o, "outras")]
                print("| %s | %s | %.1f%% / %.1f%% (%+.1f) | %.1f%% / %.1f%% (%+.1f) |" % (
                    "sem arte" if a is None else "%s %s" % (NOME[a], NOME_P[(a, k)]), f5.OPP_CURTO[o],
                    100 * p1, 100 * w1, 100 * (w1 - p1), 100 * p2, 100 * w2, 100 * (w2 - p2)))


# =================================================================== previa: exemplos da linha da passiva dele
def sec_previa(cache=None):
    est = carregar_estados(cache)
    print("\n## Previa: no treino mediano de quem luta com ele (todos os robos x 0,9): chance por tatica e o que a passiva dele faz")
    for o in REG_IDS:
        todos = [x for ak in COMBOS for x in _estados_de(est, ak[0], ak[1], o)]
        if not todos:
            continue
        jog = tuple(0.9 * v for v in _med_vetor(todos))
        adv = _adv(o)
        for (a, k) in COMBOS:
            R = regras(a, k)
            e = R.estado_passiva(jog, adv, "aggressive")
            e0 = sem_passiva_adv(R).estado_passiva(jog, adv, "aggressive")
            dif = {kk: (e0[kk], e[kk]) for kk in e if isinstance(e[kk], float) and abs(e[kk] - e0.get(kk, e[kk])) > 1e-9}
            telas = [R.lutar(jog, adv, "aggressive", s)["t"] + 3.0 for s in range(1, 201)]
            print("- %s x %s %s: chance A/D/C %s; muda na previa (sem -> com): %s; tela %.1f-%.1f s" % (
                CURTO[o], NOME[a], NOME_P[(a, k)], "/".join("%.0f" % (100 * R.chance(jog, adv, t, 200)) for t in R.tac_ids),
                ", ".join("%s %.3f -> %.3f" % (kk, v[0], v[1]) for kk, v in dif.items()) or "nada", min(telas), max(telas)))


# =================================================================== exportar casos exatos
class _Shim(types.SimpleNamespace):
    pass


def sec_exportar():
    G = f7c.Gravador
    shim = _Shim(Random=G)
    velhos = (f3.random, f7.random, f7b.random)
    f3.random = f7.random = f7b.random = shim
    f7c.RNG = G
    fim = {"dano": "damage", "dano_dele": "damage", "pontos": "points", "nocaute": "knockout", "finalizacao": "submission",
           "chute_rodado": "spin_kick"}
    fim.update(f7c.FINISH_JOGO)
    casos = []
    rng = random.Random(81)
    try:
        for o in REG_IDS:
            adv = _adv(o)
            for (a, k) in [(None, 0)] + COMBOS:
                for extra in ((0.0,) if a is None else (0.0, 0.5)):
                    R = regras(a, k, extra)
                    for i in range(6):
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
                        c = {"player": list(jog), "opponent_id": o, "opponent": list(adv), "tactic": tat, "art": a or "",
                             "passive": k, "extra": extra, "draws": list(G.ultimo.sorteados), "win": r["win"], "ko": r["ko"],
                             "t_ko": r["t_ko"] if r["t_ko"] is not None else -1.0, "t_end": r["t"], "pct_player": r["pct"][0],
                             "pct_opponent": r["pct"][1], "vmax": list(r["vmax"]), "events": ev,
                             "finish": fim[r.get("metodo", ("dano" if r["win"] else "dano_dele") if r["ko"] else "pontos")],
                             "chance_200": R.chance(jog, adv, tat, 200),
                             "est": {kk: v for kk, v in est.items() if isinstance(v, (int, float, bool, str))}}
                        casos.append(c)
    finally:
        f3.random, f7.random, f7b.random = velhos
        f7c.RNG = random.Random
    destino = os.path.join(f7b.f2.RAIZ, "tests", "data", "fase8a1_casos.json")
    with open(destino, "w", encoding="utf-8") as fh:
        json.dump({"_doc": "Fase 8a1: lutas contra os 4 regionais (sem arte e 6 combinacoes, nos 0 e 0,5). draws = todos os "
                           "sorteios na ordem; chance_200 = previa (sementes 1..200). Gerado por tools/sim/fase8a1_sim.py exportar.",
                   "exatos": casos}, fh, ensure_ascii=False)
    fins = {}
    for c in casos:
        fins[c["finish"]] = fins.get(c["finish"], 0) + 1
    print("gravado %s: %d casos; fins %s" % (destino, len(casos), sorted(fins.items())))


# =================================================================== sinal: quantas lutas mostram a trava (criterio 3)
TRAVA_DE = {"opp_reg_1": ("boxing", 1), "opp_reg_2": ("bjj", 2), "opp_reg_3": ("muay_thai", 2)}


def _sinal_um(args):
    global MEDIR
    MEDIR = True
    a, k, o, jog, nh = args
    R = regras(a, k)
    adv = _adv(o)
    out = {}
    for t in R.tac_ids:
        n1 = soma = perdeu = perdeu_sinal = vit = 0
        for s in range(nh):
            r = R.lutar(jog, adv, t, 300000 + s)
            b = r.get("bloqueios", 0)
            soma += b
            n1 += b >= 1
            vit += r["win"]
            if not r["win"]:
                perdeu += 1
                perdeu_sinal += b >= 1
        out[t] = (n1 / nh, soma / nh, vit / nh, perdeu_sinal / max(1, perdeu))
    return a, k, o, out


def sec_sinal(cache=None):
    est = carregar_estados(cache)
    tarefas = []
    for o, (a, k) in TRAVA_DE.items():
        lst = _estados_de(est, a, k, o)
        for esc in (0.85, 1.0):
            tarefas.append((a, k, o, tuple(esc * v for v in _med_vetor(lst)), 400))
    with Pool(_proc(), initializer=_init8) as pool:
        res = pool.map(_sinal_um, tarefas, chunksize=1)
    print("\n## Sinal da trava (criterio 3): na combinacao travada, treino mediano x 0,85 e x 1,0; 400 lutas por tatica")
    print("| adversario | combinacao | treino | tatica | lutas com >= 1 sinal | sinais por luta | vitoria | derrotas com o sinal (linha do motivo) |")
    print("|---|---|---|---|---|---|---|---|")
    for i, (a, k, o, out) in enumerate(res):
        for t, (p1, m, v, ps) in out.items():
            print("| %s | %s %s | x%s | %s | %.0f%% | %.1f | %.0f%% | %.0f%% |" % (
                CURTO[o], NOME[a], NOME_P[(a, k)], "0,85" if i % 2 == 0 else "1,0", t[:3], 100 * p1, m, 100 * v, 100 * ps))


def main():
    _init8(quieto=True)
    if "sinal" in sys.argv[1:]:
        sec_sinal()
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    print("Liga: %s" % json.dumps([(o["id"], o["strength"], o["agility"], o["endurance"], o["prize_money"], o["prize_fame"],
                                     o["prep_days"], o["passive"]) for o in REG], ensure_ascii=False))
    if tudo or "ident" in secs:
        sec_ident()
    if "curva" in secs:
        sec_curva(int(os.environ.get("SIM_N8", "48")), int(os.environ.get("SIM_K8", "6")))
    if "limiar" in secs:
        sec_limiar()
    if tudo or "trava" in secs:
        sec_trava()
    if tudo or "saida" in secs:
        sec_saida()
    if tudo or "previa" in secs:
        sec_previa()
    if tudo or "honesta" in secs:
        sec_honesta(int(os.environ.get("SIM_NH", "1000")))
    if tudo or "campanha" in secs:
        sec_campanha(int(os.environ.get("SIM_N8", "120")), int(os.environ.get("SIM_K8", "10")))
    if "d3" in secs:
        sec_d3(int(os.environ.get("SIM_NH", "1000")))
    if "exportar" in secs:
        sec_exportar()


if __name__ == "__main__":
    main()
