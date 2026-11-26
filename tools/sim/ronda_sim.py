"""Simulacao da Ronda Noturna do Gato Preto (minigame "Estatua no telhado", LENDA e a regiao GATO PRETO da arvore).

Design: docs/fases/ronda-design.md. Valores: data/ronda.json. Roda em cima do fase8a2_sim.py; so ACRESCENTA (nenhum arquivo
antigo e editado; os remendos ficam aqui):
  1. a Ronda congela o jogo: nao entra no laco da campanha (nada de tempo, treino ou dinheiro). Ela so conta quantas rondas
     couberam na campanha (relogio do capuz = segundos de sala) e soma a LENDA da linhagem;
  2. a regiao GATO PRETO (trava "black_cat:N" = lenda no nivel N) entra no mapa da arvore; o robo compra o no mais barato que
     cabe (regra de sempre);
  3. efeitos novos: league_prep_days_bonus (+N dias so nas lutas da liga regional) e start_money ($ no comeco da campanha).
     start_generator ja existia.
SIM_RONDA=0 (ou sem data/ronda.json) = robo da 8a2, byte a byte.

Rodar:  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/sim/ronda_sim.py [secao ...]
Secoes: forca (o teto: uma campanha sem calendario, com e sem cada no), mini (o minigame: sustos, lenda, duracao por perfil), lenda (rondas e nivel por campanha), ident (joga x nao joga:
iguais ate a compra do 1o no), ajuda (tempo ate o Kid e o James, campanhas ate o 1o James, Legado, clique x renda, com e sem a
regiao; traz o ident das mesmas corridas), exportar (tests/data/ronda_casos.json), tudo (= mini lenda forca ajuda exportar).
Alavancas: SIM_NR (jogadores; 24), SIM_KR (campanhas; 12), SIM_CPS ("4,3"), SIM_COMBOS (como na 7b2), SIM_NMR (partidas do
mini por perfil; 2000), SIM_PERFIL (perfil do robo na Ronda; "medio"), SIM_RONDA_K0 (campanha em que a Ronda abre; 3),
SIM_CAT_NOS="cat_rooftop=3000:2;..." (custo e valor dos nos), SIM_LVLS="1,12,30,52,80", SIM_NF (jogadores da forca; 24),
SIM_VAR="nome=cat_rooftop:2,cat_watch,cat_thanks:0.5;..." (variantes da forca), SIM_OLHAR_F (s entre olhadas na forca; 5),
SIM_OLHAR (s entre olhadas do robo nas campanhas; aqui o padrao e 5, e nao 30: a grade de 30 s exagera ajuda de comeco de
campanha, ver ronda-design.md §8.0).
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
import fase4_sim as f4  # noqa: E402
import fase5_sim as f5  # noqa: E402
import fase6c2_sim as f6  # noqa: E402
import fase8a1_sim as f8  # noqa: E402
import fase8a2_sim as c8  # noqa: E402

med, pct, mm = f4.mediana, f4.pct, f4.mm
RAIZ = c8.RAIZ


# =================================================================== dados
def carregar():
    p = os.path.join(RAIZ, "data", "ronda.json")
    if not os.path.exists(p):
        return None
    with open(p, encoding="utf-8") as fh:
        D = json.load(fh)
    if os.environ.get("SIM_CAT_NOS"):
        for item in os.environ["SIM_CAT_NOS"].split(";"):
            i, v = item.split("=")
            n = next(x for x in D["skill_tree"]["nodes"] if x["id"] == i)
            c, val = v.split(":")
            n["cost"], n["effect"]["value"] = int(c), (float(val) if "." in val else int(val))
    if os.environ.get("SIM_HOOD_IV"):   # Ronda 2a2: sonda do intervalo do capuz (240 = o da Ronda 1; 300 = o pedido do dono)
        D["hood"]["interval_s"] = float(os.environ["SIM_HOOD_IV"])
    if os.environ.get("SIM_LVLS"):
        D["legend"]["levels"] = [int(x) for x in os.environ["SIM_LVLS"].split(",")]
    return D


D = carregar()
ON = D is not None and os.environ.get("SIM_RONDA", "1") == "1"
NOITE = D["nights"]["scare"] if D else None
LVLS = D["legend"]["levels"] if D else []
HOOD = D["hood"] if D else None
NOS = D["skill_tree"]["nodes"] if D else []
NOS_IDS = [n["id"] for n in NOS]
K0 = int(os.environ.get("SIM_RONDA_K0", "3"))


def nivel(lenda):
    return sum(1 for x in LVLS if lenda >= x)


def rondas_na_campanha(sala_s):
    """Quantas vezes o capuz apareceu (e o robo foi na hora): 1o aos first_after_s de sala, depois interval_s depois da volta.
    A Ronda congela o relogio, entao a volta e no mesmo segundo de sala em que o capuz apareceu."""
    f, iv = HOOD["first_after_s"], HOOD["interval_s"]
    if sala_s < f:
        return 0
    return 1 + int(math.floor((sala_s - f) / iv + 1e-9))


# =================================================================== o minigame (logica pura; o Godot segue a mesma)
class Ronda:
    """Estatua no telhado. passo(dt, segurando, apertou): apertou = borda de descida do botao neste quadro."""

    def __init__(self, cfg, rng=None, ciclos=None):
        self.c = cfg
        self.fase = "contagem"
        self.cont = cfg["countdown_s"]
        self.t = 0.0
        self.i = 0                       # ocorrencia atual
        self.sustos = 0
        self.vistos = 0
        self.eventos = []
        # ciclos[i] = [(gap, falso), ...] sorteados na criacao (o teste do Godot injeta a lista)
        if ciclos is None:
            ciclos = []
            for o in cfg["occurrences"]:
                lst = []
                for _ in range(40):
                    lst.append((rng.uniform(o["gap_min"], o["gap_max"]), rng.random() < o["fake_warn"]))
                ciclos.append(lst)
        self.ciclos = ciclos
        self._nova_ocorrencia()

    def _nova_ocorrencia(self):
        self.oc = "intro"
        self.oc_t = 0.0
        self.dist = 0.0
        self.lad = "trabalha"
        self.lad_t = 0.0
        self.ci = 0
        self.lad_dur = self.ciclos[self.i][0][0] if self.i < len(self.ciclos) else 0.0

    def _ladrao(self, dt):
        o = self.c["occurrences"][self.i]
        self.lad_t += dt
        while self.lad_t >= self.lad_dur - 1e-9:
            self.lad_t -= self.lad_dur
            if self.lad == "trabalha":
                self.lad, self.lad_dur = "aviso", o["warn_s"]
                self.eventos.append(("aviso", self.i, round(self.t, 4)))
            elif self.lad == "aviso":
                if self.ciclos[self.i][self.ci][1]:
                    self.ci += 1
                    self.lad, self.lad_dur = "trabalha", self.ciclos[self.i][self.ci][0]
                    self.eventos.append(("aviso_falso", self.i, round(self.t, 4)))
                else:
                    self.lad, self.lad_dur = "olhando", o["look_s"]
            else:
                self.ci += 1
                self.lad, self.lad_dur = "trabalha", self.ciclos[self.i][self.ci][0]

    def olhando_valendo(self):
        return self.lad == "olhando" and self.lad_t > self.c["grace_s"] + 1e-9

    def passo(self, dt, segurando, apertou):
        if self.fase == "fim":
            return
        if self.fase == "contagem":
            self.cont -= dt
            if self.cont <= 1e-9:
                self.fase = "jogando"
            return
        self.t += dt
        if self.t >= self.c["night_s"] - 1e-9:
            self.fase = "fim"
            self.eventos.append(("fim_tempo", self.i, round(self.t, 4)))
            return
        if self.oc in ("susto", "visto"):
            self.oc_t += dt
            dur = self.c["scare_anim_s"] if self.oc == "susto" else self.c["seen_anim_s"]
            if self.oc_t >= dur - 1e-9:
                self.i += 1
                if self.i >= len(self.c["occurrences"]):
                    self.fase = "fim"
                    self.eventos.append(("fim", self.i, round(self.t, 4)))
                else:
                    self._nova_ocorrencia()
            return
        if self.oc == "intro":
            self.oc_t += dt
            if self.oc_t >= self.c["intro_s"] - 1e-9:
                self.oc = "jogando"
            return
        self._ladrao(dt)
        if apertou and self.dist >= self.c["scare_zone"] - 1e-9:
            if self.olhando_valendo():
                self._visto()
            else:
                self.oc, self.oc_t = "susto", 0.0
                self.sustos += 1
                self.eventos.append(("susto", self.i, round(self.t, 4)))
            return
        if segurando and self.dist < 1.0:
            self.dist = min(1.0, self.dist + self.c["advance_per_s"] * dt)
            if self.olhando_valendo():
                self._visto()

    def _visto(self):
        self.oc, self.oc_t = "visto", 0.0
        self.vistos += 1
        self.eventos.append(("visto", self.i, round(self.t, 4)))

    def lenda(self, saiu=False):
        L = self.c["legend"]
        n = len(self.c["occurrences"])
        v = L["floor"] + L["per_scare"] * self.sustos
        if self.sustos >= n:
            v += L["clean_bonus"]
        return v


PERFIS = {
    # react: atraso de percepcao (s); nota: chance de perceber o AVISO (se nao percebe, so reage ao OLHANDO)
    "atento": {"react": 0.25, "nota": 0.95},
    "medio": {"react": 0.40, "nota": 0.80},
    "distraido": {"react": 0.55, "nota": 0.50},
    "piso": None,
}
DT = 1.0 / 60.0
PREMIO_S = 3.0       # tela de premio (so para a conta da duracao total)


def jogar_robo(perfil, semente, cfg=None):
    cfg = cfg or NOITE
    rng = random.Random(semente)
    rr = random.Random(semente * 7919 + 3)
    R = Ronda(cfg, rng)
    p = PERFIS[perfil]
    if p is None:
        return R.sustos, R.lenda(saiu=True), cfg["countdown_s"] * 0 + PREMIO_S, 0
    hist = []
    segurando = False
    solto_desde = 0.0
    nota_aviso = {}
    passos = 0
    while R.fase != "fim":
        hist.append((R.t, R.i, R.oc, R.lad, R.ci))
        # o que o robo "ve": o estado de react s atras
        atras = int(round(p["react"] / DT))
        vis = hist[-1 - atras] if len(hist) > atras else None
        apertou = False
        quer = False
        if R.fase == "jogando" and R.oc == "jogando" and vis and vis[1] == R.i and vis[2] == "jogando":
            ph = vis[3]
            chave = (vis[1], vis[4])
            if ph == "aviso":
                if chave not in nota_aviso:
                    nota_aviso[chave] = rr.random() < p["nota"]
                if not nota_aviso[chave]:
                    ph = "trabalha"
            quer = ph == "trabalha"
            if R.dist >= cfg["scare_zone"] - 1e-9:
                quer = False
                if not segurando and ph == "trabalha" and R.t - solto_desde >= p["react"] - 1e-9:
                    apertou = True
        if segurando and not quer:
            solto_desde = R.t
        R.passo(DT, quer and not apertou, apertou)
        segurando = quer
        passos += 1
    dur = cfg["countdown_s"] + R.t + PREMIO_S
    return R.sustos, R.lenda(), dur, R.vistos


def _mini_um(args):
    perfil, s = args
    return jogar_robo(perfil, 50000 + s)


def sec_mini(n):
    print("\n## Mini: Estatua no telhado, %d partidas por perfil (robo com atraso de percepcao e chance de ver o aviso)" % n)
    print("| perfil | 0 / 1 / 2 / 3 sustos | lenda por ronda (media) | vistos (media) | duracao total med (p10; p90; max) |")
    print("|---|---|---|---|---|")
    out = {}
    with Pool(c8.f8._proc()) as pool:
        for perfil in ("atento", "medio", "distraido", "piso"):
            res = pool.map(_mini_um, [(perfil, s) for s in range(n)], chunksize=50)
            out[perfil] = res
            dist = [sum(1 for r in res if r[0] == k) / len(res) for k in range(4)]
            print("| %s | %s | %.2f | %.2f | %s (%s; %s; %s) |" % (
                perfil, " / ".join("%.0f%%" % (100 * x) for x in dist), sum(r[1] for r in res) / len(res),
                sum(r[3] for r in res) / len(res), mm(med([r[2] for r in res])), mm(pct([r[2] for r in res], .1)),
                mm(pct([r[2] for r in res], .9)), mm(max(r[2] for r in res))), flush=True)
    return out


# =================================================================== a linhagem (lenda) e a regiao na arvore
_ST = {}
LENDA_POR_RONDA = None    # lista de amostras (perfil do robo), preenchida no _init_w


def _zerar():
    _ST.clear()
    _ST.update({"lenda": 0, "rondas": [], "nivel": [], "comp_cat": []})


_zerar()


def ligar(on):
    global ON
    ON = bool(on) and D is not None


_rodar_ant = f6.Carreira6.rodar
_init_ant = f6.Carreira6.__init__
_trava_ant = f5.trava_ok
_mapa_ant = f5.mapa_de
_comprar_ant = f5.comprar_mapa
_bonus_ant = f5.bonus54
_data_ant = f5.Carreira5.data_prox


def _init6(self, *a, **kw):
    _init_ant(self, *a, **kw)
    if ON and self.b.get("start_money"):
        self.dinheiro += float(self.b["start_money"])


def _rodar(self):
    r = _rodar_ant(self)
    if getattr(self, "_ronda_contada", False):
        return r
    self._ronda_contada = True
    if ON and self.k >= K0 and LENDA_POR_RONDA:
        n = rondas_na_campanha(self.clk)
        rng = random.Random(self.k * 1000003 + int(_ST.get("semente", 0)))
        ganho = sum(rng.choice(LENDA_POR_RONDA) for _ in range(n))
        _ST["lenda"] += ganho
        _ST["rondas"].append((self.k, n, ganho))
    _ST["nivel"].append((self.k, nivel(_ST["lenda"]) if ON else 0, _ST["lenda"]))
    return r


def _trava(n, flags):
    lk = n.get("lock", "")
    if lk.startswith("black_cat:"):
        return ON and nivel(_ST["lenda"]) >= int(lk.split(":")[1])
    return _trava_ant(n, flags)


def _mapa(tree):
    m = _mapa_ant(tree)
    if m is None or not ON:
        return m
    for n in NOS:
        n2 = dict(n)
        n2["neighbors"] = [v for v in n["neighbors"] if v in m or v in NOS_IDS]
        m[n["id"]] = n2
    return m


def _comprar(mapa, comprados, legado, flags, artes_robo):
    antes = set(comprados)
    c, l = _comprar_ant(mapa, comprados, legado, flags, artes_robo)
    novos = [i for i in NOS_IDS if i in c and i not in antes]
    _ST["comp_cat"].append(novos)
    return c, l


def _bonus(mapa, comprados, arte):
    so_novos = {i for i in comprados if i in NOS_IDS}
    b = _bonus_ant(mapa, set(comprados) - so_novos, arte)
    b.setdefault("league_prep_days_bonus", 0)
    b.setdefault("start_money", 0)
    for i in so_novos:
        n = mapa.get(i)
        if n is None:
            continue
        ef = n["effect"]
        if ef["type"] == "start_generator":
            b["start_generator"][ef["target"]] = max(b["start_generator"].get(ef["target"], 0), int(ef["value"]))
        else:
            b[ef["type"]] = b.get(ef["type"], 0) + ef["value"]
    return b


def _data(self):
    d = _data_ant(self)
    if d is None or not ON or not self.b.get("league_prep_days_bonus"):
        return d
    o = self.R.opp[self.vitorias]
    if o.get("league"):
        d += int(self.b["league_prep_days_bonus"])
    return d


f6.Carreira6.__init__ = _init6
f6.Carreira6.rodar = _rodar
f5.trava_ok = _trava
f5.mapa_de = _mapa
f5.comprar_mapa = _comprar
f5.bonus54 = _bonus
f5.Carreira5.data_prox = _data


def seq(args):
    """Um jogador (sequencia da 8a2) com a linhagem do Gato Preto. Devolve (recs, info)."""
    _zerar()
    _ST["semente"] = args[1]
    recs, est, extra = c8.seq(args)
    rondas = {k: (n, g) for k, n, g in _ST["rondas"]}
    niveis = {k: (lv, le) for k, lv, le in _ST["nivel"]}
    for r, novos in zip(recs, _ST["comp_cat"]):
        r["cat_novos"] = novos
    for r in recs:
        r["rondas"], r["lenda_ganho"] = rondas.get(r["k"], (0, 0))
        r["nivel"], r["lenda"] = niveis.get(r["k"], (0, 0))
    return recs


def _init_w(arte, k, on, perfil):
    global LENDA_POR_RONDA
    ligar(on)
    c8._init_w(arte, k, True)
    LENDA_POR_RONDA = [jogar_robo(perfil, 90000 + s)[1] for s in range(400)] if PERFIS.get(perfil) else [1]


def rodar_combo(arte, k, cps, n, K, on=True, perfil="medio"):
    tarefas = [(cps, 1000 + s, K, "padrao", arte, "normal", f5.T_MAX5) for s in range(n)]
    with Pool(f8._proc(), initializer=_init_w, initargs=(arte, k, on, perfil)) as pool:
        return pool.map(seq, tarefas, chunksize=1)


def _cps_l():
    return tuple(int(x) for x in os.environ.get("SIM_CPS", "4,3").split(","))


# =================================================================== lenda: rondas e nivel por campanha
def sec_lenda(n, K):
    print("\n## Lenda: rondas por campanha e nivel da lenda no fim de cada campanha (mediana), por perfil do jogador na Ronda")
    for perfil in ("atento", "medio", "distraido", "piso"):
        for (a, k) in f8.COMBOS[:1]:
            res = rodar_combo(a, k, 4, n, K, on=True, perfil=perfil)
            por = {}
            for recs in res:
                for r in recs:
                    por.setdefault(r["k"], []).append(r)
            print("- %s, %s %s 4/s: rondas %s | nivel %s | lenda %s" % (
                perfil, f8.NOME[a], f8.NOME_P[(a, k)],
                " ".join("%d" % med([r["rondas"] for r in por[i]]) for i in sorted(por)),
                " ".join("%d" % med([r["nivel"] for r in por[i]]) for i in sorted(por)),
                " ".join("%d" % med([r["lenda"] for r in por[i]]) for i in sorted(por))), flush=True)


# =================================================================== ident: joga x nao joga, iguais ate a compra do 1o no
CAMPOS = ("fim", "wins", "belt", "legado", "lutas", "reg53", "vit_t", "honra", "arte", "t")


def _ident_um(args):
    (a, k, cps, s, K) = args
    out = []
    for on in (False, True):
        _init_w(a, k, on, "medio")
        out.append(seq((cps, 1000 + s, K, "padrao", a, "normal", f5.T_MAX5)))
    r0, r1 = out
    kc = next((r["k"] for r in r1 if r.get("cat_novos")), None)   # campanha em cujo FIM o 1o no foi comprado
    ate = kc if kc is not None else K
    ok = all(all(x[c] == y[c] for c in CAMPOS) for x, y in zip(r0[:ate], r1[:ate]))
    lutas = sum(len(x["lutas"]) for x in r0[:ate])
    depois = sum(1 for x, y in zip(r0[ate:], r1[ate:]) if any(x[c] != y[c] for c in CAMPOS))
    return ok, lutas, kc, depois, len(r0) - ate


def sec_ident(n, K):
    print("\n## Ident: quem joga todas as rondas x quem nunca joga; iguais ate a compra do 1o no do GATO PRETO (inclusive a campanha da compra)")
    print("| combinacao | cps | jogadores iguais | lutas comparadas | campanha da 1a compra (med) | campanhas depois que mudaram |")
    print("|---|---|---|---|---|---|")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            with Pool(f8._proc()) as pool:
                res = pool.map(_ident_um, [(a, k, cps, s, K) for s in range(n)], chunksize=1)
            print("| %s %s | %d/s | %d de %d | %d | %s | %d de %d |" % (
                f8.NOME[a], f8.NOME_P[(a, k)], cps, sum(1 for r in res if r[0]), len(res), sum(r[1] for r in res),
                f4.fmtk(med([r[2] if r[2] else 99 for r in res])), sum(r[3] for r in res), sum(r[4] for r in res)), flush=True)


# =================================================================== ajuda: com e sem a regiao
IDENT = []
def _tempos(res, K):
    por = {}
    for recs in res:
        for r in recs:
            por.setdefault(r["k"], []).append(r)
    return por


def _primeiro_james(recs):
    return next((r["k"] for r in recs if "opp_james" in r["vit_t"]), 99)


def sec_ajuda(n, K):
    print("\n## Ajuda: joga todas as rondas (perfil medio) x nunca joga. Tempo de jogo ate vencer o Kid e o James em cada campanha (s, mediana "
          "das campanhas em que venceu), campanhas ate o 1o James, Legado parado e clique x renda no Kid")
    print("| combinacao | cps | campanha da 1a compra GP (med) | campanha com os 3 nos (med) | 1o James (campanha, med; media) sem -> com | "
          "Kid, campanhas 6-%d: sem -> com (dif) | James, campanhas 6-%d: sem -> com (dif) | pior campanha (James; Kid) | "
          "Legado parado na campanha %d sem -> com | clique/renda no Kid: sem -> com (med) |" % (K, K, K))
    print("|---|---|---|---|---|---|---|---|---|---|")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            sem = rodar_combo(a, k, cps, n, K, on=False)
            com = rodar_combo(a, k, cps, n, K, on=True)
            ps, pc = _tempos(sem, K), _tempos(com, K)

            def tempos(por, ks, opp):
                return [r["vit_t"][opp] for i in ks for r in por.get(i, []) if opp in r["vit_t"]]
            ks = range(6, K + 1)
            ks_, kc_ = med(tempos(ps, ks, "opp_gym_2")), med(tempos(pc, ks, "opp_gym_2"))
            js_, jc_ = med(tempos(ps, ks, "opp_james")), med(tempos(pc, ks, "opp_james"))
            pior_j, pior_k = 0.0, 0.0
            for i in ks:
                a1, b1 = med(tempos(ps, [i], "opp_james")), med(tempos(pc, [i], "opp_james"))
                if a1 and b1:
                    pior_j = max(pior_j, 1 - b1 / a1)
                a2, b2 = med(tempos(ps, [i], "opp_gym_2")), med(tempos(pc, [i], "opp_gym_2"))
                if a2 and b2:
                    pior_k = max(pior_k, 1 - b2 / a2)
            c1 = [next((r["k"] for r in recs if r.get("cat_novos")), 99) for recs in com]
            c3 = []
            for recs in com:
                tot = 0
                kk = 99
                for r in recs:
                    tot += len(r.get("cat_novos") or [])
                    if tot >= len(NOS):
                        kk = r["k"]
                        break
                c3.append(kk)
            j_s = [_primeiro_james(r) for r in sem]
            j_c = [_primeiro_james(r) for r in com]
            leg_s = med([recs[-1]["legado_sobra"] for recs in sem])
            leg_c = med([recs[-1]["legado_sobra"] for recs in com])

            def cr(res):
                v = []
                for recs in res:
                    for r in recs:
                        sn = r.get("snap")
                        if r["k"] >= 6 and sn and sn[1] > 0:
                            v.append(sn[0] / sn[1])
                return med(v) or 0
            iguais, lutas_c = 0, 0
            for r0, r1 in zip(sem, com):
                kc = next((r["k"] for r in r1 if r.get("cat_novos")), None)
                ate = kc if kc is not None else K
                if all(all(x[c] == y[c] for c in CAMPOS) for x, y in zip(r0[:ate], r1[:ate])):
                    iguais += 1
                lutas_c += sum(len(x["lutas"]) for x in r0[:ate])
            IDENT.append((a, k, cps, iguais, len(sem), lutas_c))
            print("| %s %s | %d/s | %s | %s | %s; %.2f -> %s; %.2f | %s -> %s (%+.1f%%) | %s -> %s (%+.1f%%) | %.1f%%; %.1f%% | %d -> %d | %.0f%% -> %.0f%% |" % (
                f8.NOME[a], f8.NOME_P[(a, k)], cps, f4.fmtk(med(c1)), f4.fmtk(med(c3)),
                f4.fmtk(med(j_s)), sum(j_s) / len(j_s), f4.fmtk(med(j_c)), sum(j_c) / len(j_c),
                mm(ks_), mm(kc_), 100 * (kc_ / ks_ - 1) if ks_ else 0, mm(js_), mm(jc_), 100 * (jc_ / js_ - 1) if js_ else 0,
                100 * pior_j, 100 * pior_k, leg_s, leg_c, 100 * cr(sem), 100 * cr(com)), flush=True)


# =================================================================== forca: o teto (uma campanha, sem calendario, derrota sem custo)
VARIANTES = {"sem": [], "rooftop": ["cat_rooftop"], "watch": ["cat_watch"], "thanks": ["cat_thanks"],
             "todos": ["cat_rooftop", "cat_watch", "cat_thanks"]}
if os.environ.get("SIM_VAR"):
    # SIM_VAR="nome=cat_rooftop:2,cat_thanks:250;nome2=..." (no:valor; sem valor = o do ronda.json). "sem" fica sempre.
    VARIANTES = {"sem": []}
    for item in os.environ["SIM_VAR"].split(";"):
        nome, nos = item.split("=")
        VARIANTES[nome] = [x for x in nos.split(",") if x]
OLHAR_F = float(os.environ.get("SIM_OLHAR_F", "5"))


def _forca_um(args):
    (cps, semente, var, arte) = args
    R, treino, gens, shop, career, tree, unlocks, assist, P = f5.DADOS
    on = f5.CAL["on"]
    f5.CAL["on"] = False
    mapa = f5.mapa_de(tree)
    comprados = set(i for i, n in mapa.items() if n.get("requires_art", "") in ("", arte) and i not in NOS_IDS)
    vals = {}
    for x in VARIANTES[var]:
        i, _, v = x.partition(":")
        comprados.add(i)
        if v:
            vals[i] = float(v)
    if vals:
        mapa = {i: (dict(n, effect=dict(n["effect"], value=vals[i])) if i in vals else n) for i, n in mapa.items()}
    b = f5.bonus54(mapa, comprados, arte)
    he = f6.efeitos_hall(set(f6.HALL_CHEIO_IDS), 999)
    c = f6.Carreira6(R, treino, gens, shop, career, cps, "tipico", semente, b, unlocks, assist, P,
                     arte=arte, arte_chegada=None, belt_ends=False, style_bonus=b["art_rule_bonus"], regra_ap="asap", k=8,
                     ret_gym=1e18, ritmo=f6.f4b.ritmo_constante(cps), usa_shift=False, limiar="facil", dica=None,
                     cauteloso_contra=set(), metronomo=True, t_max=6 * 3600, hall=he, sem_derrota=True)
    c.olhar = OLHAR_F
    c._ronda_contada = True
    c.curva8 = []
    c.rodar()
    f5.CAL["on"] = on
    vt = {}
    for t, e in c.eventos:
        if e.startswith("VENCE "):
            vt[e[6:]] = t
    sn = c.snap_kid
    return {"vt": vt, "cr": (sn[0] / sn[1]) if sn and sn[1] > 0 else None}


def sec_forca(n):
    print("\n## Forca (teto): uma campanha sem calendario, robo so luta no VERDE, derrota sem custo, arvore de antes + CENTRO cheias, "
          "hall cheio; %d jogadores. Minuto da vitoria (mediana) e ganho contra 'sem'" % n)
    print("| combinacao | cps | variante | Muralha | Kid | James | ganho Muralha / Kid / James | 1 clique / renda no Kid |")
    print("|---|---|---|---|---|---|---|---|")
    for (a, k) in f8.COMBOS:
        for cps in _cps_l():
            tarefas = [(cps, 7000 + s, v, a) for v in VARIANTES for s in range(n)]
            with Pool(f8._proc(), initializer=_init_w, initargs=(a, k, True, "medio")) as pool:
                res = pool.map(_forca_um, tarefas, chunksize=2)
            T = {}
            for j, v in enumerate(VARIANTES):
                rs = res[j * n:(j + 1) * n]
                T[v] = ({o: med([r["vt"][o] for r in rs if o in r["vt"]]) for o in ("opp_tank", "opp_gym_2", "opp_james")},
                        med([r["cr"] for r in rs if r["cr"]]))
            for v in VARIANTES:
                t, cr = T[v]
                g = [100 * (1 - t[o] / T["sem"][0][o]) if t[o] and T["sem"][0][o] else 0 for o in ("opp_tank", "opp_gym_2", "opp_james")]
                print("| %s %s | %d/s | %s | %s | %s | %s | %.1f%% / %.1f%% / %.1f%% | %.0f%% |" % (
                    f8.NOME[a], f8.NOME_P[(a, k)], cps, v, mm(t["opp_tank"]), mm(t["opp_gym_2"]), mm(t["opp_james"]),
                    g[0], g[1], g[2], 100 * (cr or 0)), flush=True)


# =================================================================== exportar: contas exatas para o teste do Godot
def _roteiro(cfg, ciclos, entradas, dt):
    """entradas = lista de (t_ini, t_fim, 'hold') e (t, 'press'); tempo contado do 1o quadro (contagem incluida)."""
    R = Ronda(cfg, ciclos=ciclos)
    t = 0.0
    passos = 0
    while R.fase != "fim" and passos < 100000:
        seg = any(e[2] == "hold" and e[0] - 1e-9 <= t < e[1] - 1e-9 for e in entradas if len(e) == 3)
        ap = any(e[1] == "press" and t - 1e-9 <= e[0] < t + dt - 1e-9 for e in entradas if len(e) == 2)
        R.passo(dt, seg and not ap, ap)
        t += dt
        passos += 1
    return {"sustos": R.sustos, "vistos": R.vistos, "lenda": R.lenda(), "passos": passos, "t_noite": round(R.t, 4),
            "eventos": [list(e) for e in R.eventos]}


def sec_exportar():
    cfg = NOITE
    dt = 1.0 / 16.0
    fixos = [[(2.5, False)] * 40, [(2.0, False)] * 40, [(2.5, True), (2.5, False)] * 20]
    c0 = cfg["countdown_s"]
    i0 = c0 + cfg["intro_s"]
    casos_m = {
        "parado": [],
        "segura_sempre": [(0.0, 99.0, "hold")],
        "estatua_perfeita": [(i0, i0 + 2.5, "hold"), (i0 + 4.5, i0 + 5.5, "hold"), (i0 + 5.75, "press")],
        "susto_no_aviso": [(i0, i0 + 2.5, "hold"), (i0 + 4.5, i0 + 5.5, "hold"), (i0 + 7.2, "press")],
        "susto_olhando": [(i0, i0 + 2.5, "hold"), (i0 + 4.5, i0 + 5.5, "hold"), (i0 + 8.2, "press")],
        "mexe_na_tolerancia": [(i0, i0 + 2.5 + 0.8 + 0.1, "hold")],
    }
    casos = {"_doc": "Ronda (gerado por tools/sim/ronda_sim.py exportar). minigame: RondaLogica com os ciclos injetados (ciclos[i] = "
                     "[[gap, aviso_falso], ...]) e passo(dt, segurando, apertou) com dt = 1/16; entradas = [t_ini, t_fim, 'hold'] ou "
                     "[t, 'press'] em s desde o 1o quadro (contagem incluida). lenda_da_ronda[sustos] (com as 3 ocorrencias); "
                     "nivel[lenda] para lenda 0..80; rondas[sala_s] = capuzes numa campanha com o robo indo na hora.",
             "dt": dt, "ciclos": [[list(x) for x in c] for c in fixos], "minigame": {},
             "lenda_da_ronda": [], "nivel": [nivel(x) for x in range(81)], "levels": LVLS,
             "rondas": {str(s): rondas_na_campanha(s) for s in (0, 179, 180, 419, 420, 659, 660, 900, 1800, 2400, 3600)},
             "nos": {n["id"]: {"cost": n["cost"], "lock": n["lock"], "effect": n["effect"]} for n in NOS}}
    for nome, ent in casos_m.items():
        casos["minigame"][nome] = {"entradas": [list(e) for e in ent], "esperado": _roteiro(cfg, fixos, ent, dt)}
    R = Ronda(cfg, ciclos=fixos)
    for s in range(4):
        R.sustos = s
        casos["lenda_da_ronda"].append(R.lenda())
    destino = os.path.join(RAIZ, "tests", "data", "ronda_casos.json")
    with open(destino, "w", encoding="utf-8") as fh:
        json.dump(casos, fh, ensure_ascii=False, indent=1)
    print("gravado %s" % destino)
    for nome, v in casos["minigame"].items():
        print("  - %s: sustos %d, vistos %d, lenda %d, t_noite %.2f" % (nome, v["esperado"]["sustos"], v["esperado"]["vistos"],
                                                                      v["esperado"]["lenda"], v["esperado"]["t_noite"]))


def main():
    f8._init8(quieto=True)
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    n, K = int(os.environ.get("SIM_NR", "24")), int(os.environ.get("SIM_KR", "12"))
    print("Ronda: %s; capuz %s/%s s; niveis %s; nos %s" % (
        "LIGADA" if ON else "DESLIGADA", HOOD["first_after_s"], HOOD["interval_s"], LVLS,
        [(x["id"], x["cost"], x["lock"], x["effect"]["type"], x["effect"]["value"]) for x in NOS]), flush=True)
    if tudo or "mini" in secs:
        sec_mini(int(os.environ.get("SIM_NMR", "2000")))
    if tudo or "lenda" in secs:
        sec_lenda(int(os.environ.get("SIM_NL", "12")), K)
    if "ident" in secs:
        sec_ident(int(os.environ.get("SIM_NI", "12")), K)
    if tudo or "forca" in secs:
        sec_forca(int(os.environ.get("SIM_NF", "24")))
    if tudo or "ajuda" in secs:
        sec_ajuda(n, K)
        print("\n## Ident (das mesmas corridas da ajuda): joga x nao joga iguais ate a campanha da 1a compra do GATO PRETO (inclusive)")
        for a, k, cps, ig, tot, lt in IDENT:
            print("- %s %s %d/s: %d de %d jogadores iguais; %d lutas comparadas" % (f8.NOME[a], f8.NOME_P[(a, k)], cps, ig, tot, lt))
    if tudo or "exportar" in secs:
        sec_exportar()


if __name__ == "__main__":
    main()
