"""Simulacao da Ronda 2a1 do Gato Preto (brigas de beco) e a MEDIDA DO TETO COM TUDO JUNTO (D3 da Ronda).

Design: docs/fases/ronda2a-design.md. Valores: data/ronda.json -> nights.alley. Roda em cima do ronda_sim.py (que ja traz a
8a2 + a Ronda 1 com a regiao GATO PRETO) e do fase7a2_sim.py (convite do Osmar: Choque, Panfletagem, AQUECIDO). So ACRESCENTA:
  1. uma carreira (Carreira2a) = Carreira7a2 (convites da 7a2) + a noite: a cada capuz (180 s de sala, depois +240) o robo
     escolhe SUSTO (Ronda 1) ou briga (2a). A briga congela o jogo (nada de tempo, treino ou dinheiro): so muda a LENDA da noite
     e o Dossie. Com o convite em "nenhum" e a 2a desligada, a carreira e a do ronda_sim (secao ident prova);
  2. os bandidos lutam no motor de sempre (f8: passiva de adversario por travas, registrada em f8.PAS), com os atributos crus.

Rodar:  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/sim/ronda2a_sim.py [secao ...]
Secoes:
  aprox    aproximacao (1 ocorrencia): SUSTO / VISTO / TEMPO por perfil e duracao da noite inteira (com a luta na tela);
  curva    campanhas com a Ronda (robo medio, sem 7a2): quando cada bandido fica vencivel (>= 50% na melhor tatica, numa noite
           da campanha), quando o robo vence (briga so com >= SIM_LIM2A, padrao 0,5), chance na 1a tentativa, desafios;
  teto     TETO com tudo junto, forca (como a 'forca' da Ronda e da 7a2): uma campanha sem calendario, arvore de antes +
           CENTRO + hall cheios; variantes: base (nada) x 7a2 (todos_max / todos_piso) x regiao GATO PRETO (3 nos) x 2a;
  campanha campanha de verdade (calendario, Legado, hall, centro), 'nada' (sem 7a2, sem Ronda) x 'tudo' (7a2 todos_max +
           Ronda atento + 2a com brigas), numa corrida so; tempo de SALA ate o Kid e o James por campanha;
  ident    com a 7a2 em 'nenhum' e a 2a desligada a Carreira2a == ronda_sim (mesmas sementes);
  exportar tests/data/ronda2a_casos.json (lutas exatas contra os 3 bandidos, para o teste do Godot);
  tudo     = aprox curva teto campanha.
Alavancas: SIM_BAND="tire=F,A,R;bike=...;gate=..." (atributos), SIM_LIM2A (chance minima para o robo brigar; 0,5),
SIM_NC (jogadores por combinacao na curva; 12), SIM_KC (campanhas; 12), SIM_NF (forca; 24), SIM_NR (campanha; 7),
SIM_KR (campanhas; 10), SIM_CPS ("4,3"), SIM_COMBOS (como na 7b2), SIM_CAT_NOS (como no ronda_sim: custo:valor dos nos),
SIM_NA (partidas da aprox por perfil; 2000), SIM_CH (sementes da chance; 200 = a previa).
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
os.environ.setdefault("SIM_OLHAR", "5")
import ronda_sim as rs  # noqa: E402  (traz a 8a2 e a Ronda 1; remenda a carreira)
import fase7a2_sim as f72  # noqa: E402
import fase4_sim as f4  # noqa: E402
import fase5_sim as f5  # noqa: E402
import fase6c2_sim as f6  # noqa: E402
import fase8a1_sim as f8  # noqa: E402

med, pct, mm = f4.mediana, f4.pct, f4.mm
D = rs.D
A2 = D["nights"]["alley"]
SCARE = D["nights"]["scare"]
BANDS = [dict(b) for b in A2["bandits"]]
if os.environ.get("SIM_BAND"):
    for item in os.environ["SIM_BAND"].split(";"):
        i, v = item.split("=")
        F, A, R = (float(x) for x in v.split(","))
        next(b for b in BANDS if b["id"] == i).update(strength=F, agility=A, endurance=R)
BIDS = [b["id"] for b in BANDS]
for b in BANDS:
    f8.PAS[(b["strength"], b["agility"], b["endurance"])] = b["passive"]
LIM = float(os.environ.get("SIM_LIM2A", "0.5"))
CHEFE = []   # SIM_CHEFE="F,A,R": Apagao (2a2, so ideia) com a passiva do Rony Sabao (ensaboado), em 0,8 / 1 / 1,2 / 1,4 x
if os.environ.get("SIM_CHEFE"):
    _cf = [float(x) for x in os.environ["SIM_CHEFE"].split(",")]
    _pv = {"id": "adv_slippery", "locks": {"thai_clinch": {"clinch_base": 0.3, "clinch_cap": 0.3, "escape_base": 2.0}}}
    for _m in (0.8, 1.0, 1.2, 1.4):
        _c = {"id": "boss%.1f" % _m, "strength": _cf[0] * _m, "agility": _cf[1] * _m, "endurance": _cf[2] * _m, "passive": _pv,
              "challenge": {"type": "early_finish", "max_round": 2}}
        CHEFE.append(_c)
        f8.PAS[(_c["strength"], _c["agility"], _c["endurance"])] = _pv
NCH = int(os.environ.get("SIM_CH", "200"))
IDX_KID = None


def adv_de(b):
    return (b["strength"], b["agility"], b["endurance"])


def cfg_aprox(b):
    """A aproximacao: a mesma logica da noite 'scare' com 1 ocorrencia (bandits[i].approach) e night_s = approach_s."""
    c = copy.deepcopy(SCARE)
    c["occurrences"] = [copy.deepcopy(b["approach"])]
    c["night_s"] = A2["approach_s"]
    c["countdown_s"] = A2["countdown_s"]
    return c


def desafio(b, r, susto):
    ch = b["challenge"]
    if not r["win"]:
        return False
    if ch["type"] == "surprise":
        return bool(susto)
    if ch["type"] == "early_finish":
        rc = RL
        return bool(r["ko"]) and r["t_ko"] is not None and int(math.floor(r["t_ko"] / rc + 1e-9)) + 1 <= ch["max_round"]
    if ch["type"] == "clean_win":
        return r["pct"][0] >= ch["min_life"] - 1e-9
    return False


RL = None


def melhor(R, jog, b, n=None):
    """Previa da noite: chance de vencer e do desafio por tatica (mesmas sementes 1..n da chance()). Devolve (tatica, chance,
    chance do desafio sem a parte da aproximacao, todas)."""
    n = n or NCH
    adv = adv_de(b)
    out = {}
    for t in R.tac_ids:
        w = d = 0
        for s in range(1, n + 1):
            r = R.lutar(jog, adv, t, s)
            if r["win"]:
                w += 1
                d += desafio(b, r, True)
        out[t] = (w / n, d / n)
    bt = max(R.tac_ids, key=lambda t: (out[t][0], out[t][1]))
    return bt, out[bt][0], out[bt][1], out


# =================================================================== aproximacao
def _aprox_um(args):
    bid, perfil, s = args
    b = next(x for x in BANDS if x["id"] == bid)
    sustos, _, dur, vistos = rs.jogar_robo(perfil, 70000 + s, cfg_aprox(b))
    return sustos, vistos, dur - rs.PREMIO_S


def sec_aprox(n):
    print("\n## Aproximacao (1 ocorrencia, ate %.0f s): SUSTO / VISTO / TEMPO por perfil; %d partidas" % (A2["approach_s"], n))
    print("| bandido | perfil | SUSTO | VISTO | TEMPO | duracao (contagem + aproximacao): med (p90; max) |")
    print("|---|---|---|---|---|---|")
    AP = {}
    with Pool(f8._proc()) as pool:
        for b in BANDS:
            for perfil in ("atento", "medio", "distraido"):
                res = pool.map(_aprox_um, [(b["id"], perfil, s) for s in range(n)], chunksize=50)
                su = sum(r[0] for r in res) / n
                vi = sum(r[1] for r in res) / n
                AP[(b["id"], perfil)] = su
                print("| %s | %s | %.0f%% | %.0f%% | %.0f%% | %.1f s (%.1f; %.1f) |" % (
                    b["id"], perfil, 100 * su, 100 * vi, 100 * (1 - su - vi), med([r[2] for r in res]),
                    pct([r[2] for r in res], .9), max(r[2] for r in res)), flush=True)
    return AP


# =================================================================== a carreira com a noite (7a2 + Ronda + 2a)
_L = {}                       # linhagem do Gato Preto na 2a: kid, vencidos, estatisticas
CFG = {"briga": False, "perfil": "medio", "curva": False}
APROX_P = {}                  # bandido -> chance de SUSTO na aproximacao (perfil da Ronda)


def _zerar_l(semente):
    _L.clear()
    _L.update({"kid": False, "won": [], "noites": [], "rng": random.Random(semente * 31 + 7), "brigas": [],
               "vis": {}})


_zerar_l(0)


class Carreira2a(f72.Carreira7a2):
    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        self.n_prox = rs.HOOD["first_after_s"]
        self.lenda_c = 0              # lenda ganha nesta campanha (contada aqui; corrige a do ronda_sim no fim)
        self.n_noites = 0

    def _jogar(self, tipo):
        if tipo == "flyers" and IDX_KID is not None and self.vitorias > IDX_KID:
            v = self.vitorias           # jogo (8a1): a FAMA da Panfletagem fica limitada ao Kid
            self.vitorias = IDX_KID
            try:
                return f72.Carreira7a2._jogar(self, tipo)
            finally:
                self.vitorias = v
        return f72.Carreira7a2._jogar(self, tipo)

    def _noite(self):
        """Uma noite (o capuz apareceu e o robo foi na hora). Relogio parado: so lenda e Dossie."""
        self.n_noites += 1
        rng = _L["rng"]
        lenda_agora = rs._ST["lenda"] + self.lenda_c
        aberta = _L["kid"] and rs.nivel(lenda_agora) >= A2["requires"]["legend_level"]
        jog = tuple(self.attr)
        if CFG["curva"] and _L["kid"] and self.arte:
            linha = {"k": self.k, "clk": self.clk, "aberta": aberta}
            for b in BANDS:
                bt, p, pd, _ = melhor(self.R, jog, b, 100)
                linha[b["id"]] = (p, pd, bt)
            _L["noites"].append(linha)
        prox = next((b for b in BANDS if b["id"] not in _L["won"]), None)
        if CFG["briga"] and aberta and prox is not None and self.arte:
            bt, p, pd, _ = melhor(self.R, jog, prox)
            if p >= LIM:
                susto = rng.random() < APROX_P.get(prox["id"], 0.0)
                r = self.R.lutar(jog, adv_de(prox), bt, rng.randrange(1 << 30) + 1000)
                g = A2["legend"]["floor"] + (A2["legend"]["per_scare"] if susto else 0) + (A2["legend"]["win"] if r["win"] else 0)
                self.lenda_c += g
                _L["brigas"].append({"k": self.k, "b": prox["id"], "p": p, "pd": pd, "win": r["win"],
                                     "ch": desafio(prox, r, susto), "tentativa": sum(1 for x in _L["brigas"] if x["b"] == prox["id"]) + 1,
                                     "tat": bt})
                if r["win"]:
                    _L["won"].append(prox["id"])
                return
        self.lenda_c += rng.choice(rs.LENDA_POR_RONDA) if rs.LENDA_POR_RONDA else 1

    def talvez_lutar(self):
        if rs.ON and self.k >= rs.K0 and f5.CAL["on"] and not self.fim and self.clk >= self.n_prox - 1e-9:
            self.n_prox += rs.HOOD["interval_s"]
            if CFG["briga"] or CFG["curva"]:
                self._noite()
        jam = "opp_james" in self.t_g
        jog0 = tuple(self.attr)
        r = f72.Carreira7a2.talvez_lutar(self)
        if not _L["kid"] and "opp_gym_2" in self.t_g:
            _L["kid"] = True
        if CHEFE and CFG["curva"] and not jam and "opp_james" in self.t_g and self.arte:
            # 2a2 (ideia): chance contra o Apagao com o discipulo que ACABOU de ganhar o cinturao regional
            _L.setdefault("chefe", []).append((self.k, [melhor(self.R, jog0, dict(c), 100)[1:3] for c in CHEFE]))
        return r


ORIG = f6.Carreira6
_rodar_base = f6.Carreira6.rodar


def _rodar2a(self):
    r = _rodar_base(self)
    if getattr(self, "_c2a", False):
        return r
    self._c2a = True
    if (CFG["briga"] or CFG["curva"]) and rs._ST["rondas"] and rs._ST["rondas"][-1][0] == self.k:
        # a lenda da campanha passa a ser a contada noite a noite (SUSTO ou briga)
        k, n, g = rs._ST["rondas"][-1]
        rs._ST["lenda"] += self.lenda_c - g
        rs._ST["rondas"][-1] = (k, n, self.lenda_c)
        kk, lv, le = rs._ST["nivel"][-1]
        rs._ST["nivel"][-1] = (kk, rs.nivel(rs._ST["lenda"]), rs._ST["lenda"])
    self.sala_vit = {o: v[1] for o, v in self.vt72.items()}
    return r


Carreira2a.rodar = _rodar2a


def _init_w(arte, k, ronda_on, perfil, pol, briga, curva):
    global IDX_KID, RL
    rs._init_w(arte, k, ronda_on, perfil)
    f72.POLITICA = pol
    f6.Carreira6 = Carreira2a
    CFG.update(briga=briga, curva=curva, perfil=perfil)
    R0 = f5.DADOS[0]
    IDX_KID = next(i for i, o in enumerate(R0.opp) if o["id"] == "opp_gym_2")
    RL = R0.c["round_length"]
    APROX_P.clear()
    if PERFIS_OK(perfil):
        for b in BANDS:
            APROX_P[b["id"]] = sum(rs.jogar_robo(perfil, 91000 + s, cfg_aprox(b))[0] for s in range(300)) / 300.0


def PERFIS_OK(p):
    return rs.PERFIS.get(p) is not None


def seq(args):
    """Um jogador: (cps, semente, K, ..., arte, ...). Devolve (recs, linhagem da 2a)."""
    _zerar_l(args[1])
    f72.JA_CINTO[0] = False
    sala = []
    velho = f6.Carreira6.rodar

    def rodar_e_guardar(self):
        x = velho(self)
        sala.append(dict(getattr(self, "sala_vit", {})))
        return x
    f6.Carreira6.rodar = rodar_e_guardar
    try:
        recs = rs.seq(args)
    finally:
        f6.Carreira6.rodar = velho
    for r, s in zip(recs, sala):
        r["sala_vit"] = s
    return recs, {"noites": list(_L["noites"]), "brigas": list(_L["brigas"]), "won": list(_L["won"]), "chefe": list(_L.get("chefe", []))}


def rodar_combo(arte, k, cps, n, K, ronda_on=True, perfil="medio", pol="nenhum", briga=False, curva=False):
    tarefas = [(cps, 1000 + s, K, "padrao", arte, "normal", f5.T_MAX5) for s in range(n)]
    with Pool(f8._proc(), initializer=_init_w, initargs=(arte, k, ronda_on, perfil, pol, briga, curva)) as pool:
        return pool.map(seq, tarefas, chunksize=1)


def _cps_l():
    return tuple(int(x) for x in os.environ.get("SIM_CPS", "4,3").split(","))


# =================================================================== curva de dificuldade
def sec_curva(n, K):
    print("\n## Curva: robo medio na Ronda (vai em todo capuz), sem 7a2; %d jogadores x %d campanhas por linha. Bandidos %s" % (
        n, K, ", ".join("%s %.0fM/%.0fM/%.0fM (%s)" % (b["id"], b["strength"] / 1e6, b["agility"] / 1e6, b["endurance"] / 1e6,
                                              b["passive"]["id"]) for b in BANDS)))
    print("Vencivel = alguma noite da campanha com >= 50%% na melhor tatica. Robo briga so com >= %.0f%% (senao SUSTO)." % (100 * LIM))
    print("| combinacao | cps | brigas abrem (campanha, med) | vencivel 1a vez: %s | 1a vitoria: %s | tentativas ate vencer (med) | "
          "chance na briga vencida (med) | desafio: chance mostrada (med) / feito na 1a vitoria |" % (
              " / ".join(BIDS), " / ".join(BIDS)))
    print("|---|---|---|---|---|---|---|---|")
    TOT = {b: {"venc": [], "win": [], "ch": []} for b in BIDS}
    CH, CHD = [[] for _ in CHEFE], [[] for _ in CHEFE]
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            res = rodar_combo(a, k, cps, n, K, perfil="medio", briga=True, curva=True)
            abre, venc, win, tent, pv, pdv, chf = [], {b: [] for b in BIDS}, {b: [] for b in BIDS}, {b: [] for b in BIDS}, \
                {b: [] for b in BIDS}, {b: [] for b in BIDS}, {b: [] for b in BIDS}
            for recs, L in res:
                for _, lst in L.get("chefe", []):
                    for i, (p_, pd_) in enumerate(lst):
                        CH[i].append(p_)
                        CHD[i].append(pd_)
                ab = next((x["k"] for x in L["noites"] if x["aberta"]), 99)
                abre.append(ab)
                for b in BIDS:
                    venc[b].append(next((x["k"] for x in L["noites"] if x[b][0] >= 0.5), 99))
                    w = next((x for x in L["brigas"] if x["b"] == b and x["win"]), None)
                    win[b].append(w["k"] if w else 99)
                    if w:
                        tent[b].append(w["tentativa"])
                        pv[b].append(w["p"])
                        pdv[b].append(w["pd"])
                        chf[b].append(1 if w["ch"] else 0)
            for b in BIDS:
                TOT[b]["venc"] += venc[b]
                TOT[b]["win"] += win[b]
                TOT[b]["ch"] += chf[b]
            print("| %s %s | %d/s | %s | %s | %s | %s | %s | %s |" % (
                f8.NOME[a], f8.NOME_P[(a, k)], cps, f4.fmtk(med(abre)),
                " / ".join(f4.fmtk(med(venc[b])) for b in BIDS), " / ".join(f4.fmtk(med(win[b])) for b in BIDS),
                " / ".join(f4.fmtk(med(tent[b])) if tent[b] else "-" for b in BIDS),
                " / ".join("%.0f%%" % (100 * med(pv[b])) if pv[b] else "-" for b in BIDS),
                " / ".join(("%.0f%% / %d de %d" % (100 * med(pdv[b]), sum(chf[b]), len(chf[b]))) if pdv[b] else "-" for b in BIDS)),
                flush=True)
    if CHEFE:
        print("- Apagao (2a2, ideia) com o discipulo no instante em que vence o James: chance (med; p25-p75) por escala: " + "; ".join(
            "%.1fx %s: %.0f%% (%.0f-%.0f), desafio %.0f%%" % (m, "/".join("%.0fM" % (CHEFE[i][x] / 1e6) for x in ("strength", "agility", "endurance")),
            100 * med(CH[i]), 100 * pct(CH[i], .25), 100 * pct(CH[i], .75), 100 * med(CHD[i])) for i, m in enumerate((0.8, 1.0, 1.2, 1.4)) if CH[i]))
    print("- todas as linhas: vencivel 1a vez (med; p25-p75) %s; 1a vitoria (med; p25-p75) %s; desafio feito na 1a vitoria %s" % (
        " / ".join("%s %s (%s-%s)" % (b, f4.fmtk(med(TOT[b]["venc"])), f4.fmtk(pct(TOT[b]["venc"], .25)), f4.fmtk(pct(TOT[b]["venc"], .75))) for b in BIDS),
        " / ".join("%s %s (%s-%s)" % (b, f4.fmtk(med(TOT[b]["win"])), f4.fmtk(pct(TOT[b]["win"], .25)), f4.fmtk(pct(TOT[b]["win"], .75))) for b in BIDS),
        " / ".join("%s %.0f%%" % (b, 100 * sum(TOT[b]["ch"]) / max(1, len(TOT[b]["ch"]))) for b in BIDS)))


# =================================================================== teto: forca com tudo junto
VARS = [  # nome, politica da 7a2, nos da regiao
    ("base", "nenhum", []),
    ("so_7a2", "todos_max", []),
    ("so_regiao", "nenhum", ["cat_rooftop", "cat_watch", "cat_thanks"]),
    ("tudo_max", "todos_max", ["cat_rooftop", "cat_watch", "cat_thanks"]),
    ("tudo_piso", "todos_piso", ["cat_rooftop", "cat_watch", "cat_thanks"]),
]
if os.environ.get("SIM_THANKS"):     # proposta de corte do x1,4 (D3 da Ronda): SIM_THANKS="0.25,0.2" mede tudo_max e so_regiao com outro valor
    for _v in os.environ["SIM_THANKS"].split(","):
        VARS.append(("tudo_max_eq%s" % _v, "todos_max", ["cat_rooftop", "cat_watch", "cat_thanks:%s" % _v]))
        VARS.append(("so_regiao_eq%s" % _v, "nenhum", ["cat_rooftop", "cat_watch", "cat_thanks:%s" % _v]))
if os.environ.get("SIM_TETO_VARS"):  # so estas variantes (a 'base' fica sempre)
    _q = set(os.environ["SIM_TETO_VARS"].split(",")) | {"base"}
    VARS = [v for v in VARS if v[0] in _q]
ALVOS = ("opp_tank", "opp_gym_2", "opp_reg_1", "opp_reg_2", "opp_reg_3", "opp_james")


def _forca_um(args):
    (cps, semente, vi, arte, ctr) = args
    nome, pol, nos = VARS[vi]
    R, treino, gens, shop, career, tree, unlocks, assist, P = f5.DADOS
    on = f5.CAL["on"]
    f5.CAL["on"] = False
    f72.POLITICA = pol
    f72.JA_CINTO[0] = True
    mapa = f5.mapa_de(tree)
    comprados = set(i for i, n in mapa.items() if n.get("requires_art", "") in ("", arte) and i not in rs.NOS_IDS)
    if not ctr:
        comprados -= {i for i in comprados if i.startswith("ctr_")}
    vals = {}
    for x in nos:
        i, _, v = x.partition(":")
        comprados.add(i)
        if v:
            vals[i] = float(v)
    if vals:
        mapa = {i: (dict(n, effect=dict(n["effect"], value=vals[i])) if i in vals else n) for i, n in mapa.items()}
    b = f5.bonus54(mapa, comprados, arte)
    he = f6.efeitos_hall(set(f6.HALL_CHEIO_IDS), 999)
    c = Carreira2a(R, treino, gens, shop, career, cps, "tipico", semente, b, unlocks, assist, P,
                   arte=arte, arte_chegada=None, belt_ends=False, style_bonus=b["art_rule_bonus"], regra_ap="asap", k=8,
                   ret_gym=1e18, ritmo=f6.f4b.ritmo_constante(cps), usa_shift=False, limiar="facil", dica=None,
                   cauteloso_contra=set(), metronomo=True, t_max=6 * 3600, hall=he, sem_derrota=True)
    c.olhar = rs.OLHAR_F
    c._ronda_contada = True
    c._c2a = True
    c.curva8 = []
    c.rodar()
    f5.CAL["on"] = on
    return {o: v[1] for o, v in c.vt72.items()}, {o: v[0] for o, v in c.vt72.items()}


def sec_teto(n):
    ctrs = [int(x) for x in os.environ.get("SIM_CTR_F", "1,0").split(",")]
    print("\n## TETO com tudo junto (forca): uma campanha sem calendario, robo so luta no VERDE (olha a cada %.0f s), derrota sem custo, "
          "arvore de antes cheia, hall cheio, CENTRO cheio (1) ou vazio (0); %d jogadores. Tempo de SALA (dias) ate cada vitoria "
          "(mediana) e ganho contra 'base'. A 2a (brigas) congela o jogo e nao da premio de economia: soma 0 aqui por construcao." % (rs.OLHAR_F, n))
    print("| combinacao | cps | CENTRO | variante | Muralha | Kid | Bigorna | Estaca | Sabao | James | ganho: Muralha / Kid / Big / Est / Sab / James | pior |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|")
    pior_g = (0.0, "")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            for ctr in ctrs:
                tarefas = [(cps, 7000 + s, vi, a, ctr) for vi in range(len(VARS)) for s in range(n)]
                with Pool(f8._proc(), initializer=_init_w, initargs=(a, k, True, "medio", "nenhum", False, False)) as pool:
                    res = pool.map(_forca_um, tarefas, chunksize=2)
                T = {}
                for vi, (nome, _, _) in enumerate(VARS):
                    rr = res[vi * n:(vi + 1) * n]
                    T[nome] = {o: med([r[0][o] for r in rr if o in r[0]]) for o in ALVOS}
                for nome, _, _ in VARS:
                    t = T[nome]
                    g = [100 * (1 - t[o] / T["base"][o]) if t[o] and T["base"][o] else 0.0 for o in ALVOS]
                    pior = max(g)
                    if nome != "base" and pior > pior_g[0]:
                        pior_g = (pior, "%s %s %d/s CENTRO %d %s %s" % (f8.NOME[a], f8.NOME_P[(a, k)], cps, ctr, nome,
                                                                         ALVOS[g.index(pior)]))
                    print("| %s %s | %d/s | %d | %s | %s | %s | %s | %s | %s | %s | %s | %.1f%% |" % (
                        f8.NOME[a], f8.NOME_P[(a, k)], cps, ctr, nome, *[mm(t[o]) for o in ALVOS],
                        " / ".join("%.1f%%" % x for x in g), pior), flush=True)
    print("- PIOR TRECHO de todas as variantes: %.1f%% (%s)" % pior_g)


# =================================================================== campanha de verdade: nada x tudo
def sec_campanha(n, K):
    print("\n## Campanha de verdade (calendario, Legado, hall, centro; robo olha a cada 5 s), %d jogadores x %d campanhas. "
          "'nada' = sem 7a2 e sem Ronda; 'tudo' = 7a2 todos_max + Ronda (perfil atento) + 2a (brigas com >= %.0f%%), numa corrida so. "
          "Tempo de SALA ate a vitoria (mediana das campanhas 6-%d em que venceu)" % (n, K, 100 * LIM, K))
    print("| combinacao | cps | Kid: nada -> tudo (dif) | James: nada -> tudo (dif) | pior campanha (Kid; James) | 1o James (campanha med) nada -> tudo | brigas vencidas no fim (med) |")
    print("|---|---|---|---|---|---|---|")
    pior = (0.0, "")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            nada = rodar_combo(a, k, cps, n, K, ronda_on=False, perfil="medio", pol="nenhum", briga=False)
            tudo = rodar_combo(a, k, cps, n, K, ronda_on=True, perfil="atento", pol="todos_max", briga=True)

            def tempos(res, ks, o):
                return [r["sala_vit"][o] for recs, _ in res for r in recs if r["k"] in ks and o in r.get("sala_vit", {})]
            ks = range(6, K + 1)
            out = []
            for o in ("opp_gym_2", "opp_james"):
                a0, a1 = med(tempos(nada, ks, o)), med(tempos(tudo, ks, o))
                out.append((a0, a1))
            pk = pj = 0.0
            for i in ks:
                for j, o in enumerate(("opp_gym_2", "opp_james")):
                    x0, x1 = med(tempos(nada, [i], o)), med(tempos(tudo, [i], o))
                    if x0 and x1:
                        g = 1 - x1 / x0
                        if j == 0:
                            pk = max(pk, g)
                        else:
                            pj = max(pj, g)
            for g, nm in ((pk, "Kid"), (pj, "James")):
                if g > pior[0]:
                    pior = (g, "%s %s %d/s %s" % (f8.NOME[a], f8.NOME_P[(a, k)], cps, nm))
            j0 = [next((r["k"] for r in recs if "opp_james" in r["vit_t"]), 99) for recs, _ in nada]
            j1 = [next((r["k"] for r in recs if "opp_james" in r["vit_t"]), 99) for recs, _ in tudo]
            bw = [len(L["won"]) for _, L in tudo]
            print("| %s %s | %d/s | %s -> %s (%+.1f%%) | %s -> %s (%+.1f%%) | %.1f%%; %.1f%% | %s -> %s | %s |" % (
                f8.NOME[a], f8.NOME_P[(a, k)], cps, mm(out[0][0]), mm(out[0][1]),
                100 * (1 - out[0][1] / out[0][0]) if out[0][0] and out[0][1] else 0,
                mm(out[1][0]), mm(out[1][1]), 100 * (1 - out[1][1] / out[1][0]) if out[1][0] and out[1][1] else 0,
                100 * pk, 100 * pj, f4.fmtk(med(j0)), f4.fmtk(med(j1)), f4.fmtk(med(bw))), flush=True)
    print("- pior campanha (ganho positivo = mais cedo): %.1f%% (%s)" % (100 * pior[0], pior[1]))


# =================================================================== ident
def _ident_um(args):
    a, k, cps, s, K = args
    f6.Carreira6 = ORIG
    rs._init_w(a, k, True, "medio")
    r0 = rs.seq((cps, 1000 + s, K, "padrao", a, "normal", f5.T_MAX5))
    _init_w(a, k, True, "medio", "nenhum", False, False)
    r1, _ = seq((cps, 1000 + s, K, "padrao", a, "normal", f5.T_MAX5))
    f6.Carreira6 = ORIG
    return all(all(x[c] == y[c] for c in rs.CAMPOS) for x, y in zip(r0, r1)), sum(len(x["lutas"]) for x in r0)


def sec_ident(n, K):
    print("\n## Ident: Carreira2a com a 7a2 em 'nenhum' e sem briga == ronda_sim (mesmas sementes)")
    for (a, k) in f8.COMBOS[:2]:
        with Pool(f8._proc()) as pool:
            res = pool.map(_ident_um, [(a, k, 4, s, K) for s in range(n)], chunksize=1)
        print("- %s %s 4/s: %d de %d iguais; %d lutas" % (f8.NOME[a], f8.NOME_P[(a, k)], sum(r[0] for r in res), n, sum(r[1] for r in res)))


# =================================================================== exportar: casos exatos para o teste do Godot
def sec_exportar():
    """tests/data/ronda2a_casos.json: lutas contra os 3 bandidos (sem arte e nas 6 combinacoes, nos extras 0 e 0,5) com SORTEIOS
    EXPLICITOS (a mesma lista de numeros e consumida pelo Python e pelo GDScript, golpe a golpe). Mesmo formato do fase8a1_casos.json."""
    import types
    global RL
    RL = f5.DADOS[0].c["round_length"]
    G = f8.f7c.Gravador
    shim = types.SimpleNamespace(Random=G)
    velhos = (f8.f3.random, f8.f7.random, f8.f7b.random)
    f8.f3.random = f8.f7.random = f8.f7b.random = shim
    f8.f7c.RNG = G
    fim = {"dano": "damage", "dano_dele": "damage", "pontos": "points", "nocaute": "knockout", "finalizacao": "submission",
           "chute_rodado": "spin_kick"}
    fim.update(f8.f7c.FINISH_JOGO)
    casos = []
    rng = random.Random(2101)
    try:
        for b in BANDS:
            adv = adv_de(b)
            for (a, k) in [(None, 0)] + f8.COMBOS:
                for extra in ((0.0,) if a is None else (0.0, 0.5)):
                    R = f8.regras(a, k, extra)
                    for i in range(3):
                        m = rng.uniform(0.6, 1.4)
                        w = [rng.random() + 0.3 for _ in range(3)]
                        sw = sum(w)
                        jog = tuple(sum(adv) * m * x / sw for x in w)
                        tat = R.tac_ids[i % 3]
                        semente = 9000 + len(casos)
                        r = R.lutar(jog, adv, tat, semente, registro=True)
                        est = R.estado_passiva(jog, adv, tat) if a else {}
                        ev = [[e["t"], e["who"], e["type"], bool(e.get("counter", False)), e.get("damage", 0.0),
                               e.get("life_after", 0.0)] for e in r["ev"]]
                        casos.append({"player": list(jog), "opponent_id": b["id"], "opponent": list(adv), "tactic": tat, "art": a or "",
                                      "passive": k, "extra": extra, "draws": list(G.ultimo.sorteados), "win": r["win"], "ko": r["ko"],
                                      "t_ko": r["t_ko"] if r["t_ko"] is not None else -1.0, "t_end": r["t"], "pct_player": r["pct"][0],
                                      "pct_opponent": r["pct"][1], "vmax": list(r["vmax"]), "events": ev,
                                      "finish": fim[r.get("metodo", ("dano" if r["win"] else "dano_dele") if r["ko"] else "pontos")],
                                      "chance_200": R.chance(jog, adv, tat, 200),
                                      "challenge": {"type": b["challenge"]["type"], "done": bool(desafio(b, r, True)) if b["challenge"]["type"] != "surprise" else bool(r["win"])},
                                      "est": {kk: v for kk, v in est.items() if isinstance(v, (int, float, bool, str))}})
    finally:
        f8.f3.random, f8.f7.random, f8.f7b.random = velhos
        f8.f7c.RNG = random.Random
    destino = os.path.join(f8.f7b.f2.RAIZ, "tests", "data", "ronda2a_casos.json")
    with open(destino, "w", encoding="utf-8") as fh:
        json.dump({"_doc": "Ronda 2a1: lutas contra os 3 bandidos (sem arte e 6 combinacoes, extras 0 e 0,5). draws = todos os sorteios na "
                           "ordem; chance_200 = previa do Python (sementes 1..200); challenge.done = o desafio cumprido naquela luta "
                           "(surprise: so a vitoria, o SUSTO vem da aproximacao). Gerado por tools/sim/ronda2a_sim.py exportar.",
                   "bandidos": [{k: b[k] for k in ("id", "strength", "agility", "endurance", "passive", "challenge")} for b in BANDS],
                   "exatos": casos}, fh, ensure_ascii=False)
    fins = {}
    for c in casos:
        fins[c["finish"]] = fins.get(c["finish"], 0) + 1
    print("gravado %s: %d casos; fins %s" % (destino, len(casos), sorted(fins.items())))


def main():
    f8._init8(quieto=True)
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    print("Ronda 2a: bandidos %s; aproximacao %.0f s; lenda %s; robo briga com >= %.0f%%" % (
        [(b["id"], b["strength"], b["agility"], b["endurance"], b["passive"]["id"], b["challenge"]["type"]) for b in BANDS],
        A2["approach_s"], {x: A2["legend"][x] for x in ("floor", "per_scare", "win")}, 100 * LIM), flush=True)
    if tudo or "aprox" in secs:
        sec_aprox(int(os.environ.get("SIM_NA", "2000")))
    if "ident" in secs:
        sec_ident(int(os.environ.get("SIM_NI", "6")), int(os.environ.get("SIM_KI", "8")))
    if tudo or "curva" in secs:
        sec_curva(int(os.environ.get("SIM_NC", "12")), int(os.environ.get("SIM_KC", "12")))
    if tudo or "teto" in secs:
        sec_teto(int(os.environ.get("SIM_NF", "24")))
    if tudo or "campanha" in secs:
        sec_campanha(int(os.environ.get("SIM_NR", "7")), int(os.environ.get("SIM_KR", "10")))
    if "exportar" in secs:  # fora do "tudo": regera o arquivo de casos do teste
        sec_exportar()


if __name__ == "__main__":
    main()
