"""Simulacao da Fase 7b1 (Muay Thai): passiva Canela, regra de treino "clique com picos", saco de chute, Choque do Muay Thai
(combo no tempo), balanco das 3 artes e teto de 10% em dias de campanha.

Design: docs/fases/fase7b1-design.md. Valores: data/arts.json (muay_thai: rule + passive), data/training.json (kick_bag),
data/skill_tree.json (regiao muay_thai), data/minigames.json (spar.variants.muay_thai).
Reaproveita fase7a1_sim.py (motor das artes e campanha) e fase7a2_sim.py (convite, Choque, teto). Boxe, Jiu-jitsu e "sem arte"
NAO mudam: este arquivo so ACRESCENTA o ramo "shin" (secao ident confere).

Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/sim/fase7b1_sim.py [secao ...]
Secoes: ident, luta, previa, limiar, foco, honesta, campanha, forca, choque, teto, tudo (padrao).
  campanha = robo padrao da 7a1 (calendario, Legado, hall), 3 artes. O Muay Thai entra "como se" estivesse liberado na 1a chegada
             (mesma comparacao da 7a1); no jogo ele so chega depois do 1o Kid.
  forca    = sem calendario, so luta no verde, derrota nao encerra (a medida do teto da 7a2): tempo ate o Kid por arte.
  teto     = fase7a2 'forca' com o Muay Thai (Choque com o premio do Muay Thai), politicas nenhum / todos_max / todos_piso / cedo_max.
Alavancas: SIM_PMT="k=v,tatica.k=v" (passiva), SIM_RMT="chance_add,mult_add" (regra de treino), SIM_N7B (jogadores da campanha;
padrao 200), SIM_K7B (campanhas; padrao 10), SIM_NF (jogadores da forca/teto; padrao 48), SIM_NH (lutas da honesta; padrao 1000),
SIM_NM (partidas do Choque; padrao 400), SIM_ARTES7B (artes da campanha/forca; padrao "boxing,bjj,muay_thai").
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
import fase3_sim as f3  # noqa: E402
import fase4_sim as f4  # noqa: E402
import fase4b_sim as f4b  # noqa: E402
import fase5_sim as f5  # noqa: E402
import fase6c2_sim as f6  # noqa: E402
import fase7a1_sim as f7  # noqa: E402
import fase7a2_sim as f72  # noqa: E402

med = f4.mediana
pct = f4.pct
mm = f4.mm

PROPOSTA_MT = {
    "type": "shin",
    "damage_mult": 1.0, "taken_mult": 1.0, "interval_mult": 1.0, "need_ahead": 0,
    "marks_max": 3, "mark_per_kick": 1.0, "mark_strength_min": 0.5, "mark_strength_max": 2.0, "mark_cap": 1.0,
    "slow_per_mark": 0.10,
    "crit_per_mark": 0.06, "crit_agility_min": 0.5, "crit_agility_max": 1.6, "crit_cap": 0.6,
    "spin_life_max": 0.60, "spin_ko": 0.6, "limp_from_marks": 2,
    "tactics": {
        "aggressive": {"mark_mult": 1.5, "opponent_counter": 0.6},
        "defensive": {"mark_mult": 0.75, "slow_mult": 1.5},
        "counter": {"marks_per_counter": 1},
    },
}
RULE_MT = {"type": "click_crit_bonus", "chance_add": 0.10, "mult_add": 1.5}


def _ler_json(nome):
    with open(os.path.join(f2.RAIZ, "data", nome), encoding="utf-8") as fh:
        return json.load(fh)


def carregar_mt():
    P = copy.deepcopy(PROPOSTA_MT)
    R = dict(RULE_MT)
    try:
        for a in _ler_json("arts.json")["arts"]:
            if a["id"] == "muay_thai":
                if a.get("passive", {}).get("type") == "shin":
                    P = copy.deepcopy(a["passive"])
                if a.get("rule", {}).get("type") == "click_crit_bonus":
                    R = dict(a["rule"])
    except (OSError, KeyError, ValueError):
        pass
    f7._sobrescrever(P, "SIM_PMT")
    if os.environ.get("SIM_RMT"):
        c, m = (float(x) for x in os.environ["SIM_RMT"].split(","))
        R.update(chance_add=c, mult_add=m)
    return P, R


PMT, RULE_MT = carregar_mt()
f7.PASSIVAS["muay_thai"] = PMT
CLK = _ler_json("training.json")["click"]
MT = "muay_thai"
ARTES = os.environ.get("SIM_ARTES7B", "boxing,bjj,muay_thai").split(",")
NOME = {"boxing": "Boxe", "bjj": "Jiu-jitsu", "muay_thai": "Muay Thai", None: "sem arte"}
PASSIVA_FIM = ("nocaute", "finalizacao", "chute_rodado")


def _clamp(x, a, b):
    return a if x < a else (b if x > b else x)


# =================================================================== motor: ramo "shin" (Canela)
_estado_velho = f7.RegrasArte.estado_passiva
_lutar_arte_velho = f7.RegrasArte._lutar_arte


def estado_passiva(self, jog, adv, tatica):
    P = self.pas
    if P is None or P["type"] != "shin":
        return _estado_velho(self, jog, adv, tatica)
    ej, ea = self.efetivos(jog), self.efetivos(adv)
    tp = P["tactics"].get(tatica, {})
    fm = _clamp(2.0 * ej[0] / (ej[0] + ea[2]), P["mark_strength_min"], P["mark_strength_max"]) if ej[0] + ea[2] > 0 else 1.0
    ganho = min(P["mark_cap"], P["mark_per_kick"] * fm * tp.get("mark_mult", 1.0) * (1.0 + self.extra))
    mmax = int(P["marks_max"])
    chutes = int(math.ceil(mmax / ganho - 1e-9)) if ganho > 0 else 99
    fa = _clamp(2.0 * ej[1] / (ej[1] + ea[1]), P["crit_agility_min"], P["crit_agility_max"]) if ej[1] + ea[1] > 0 else 1.0
    n1 = self.golpe(ej, ea, self.NEUTRA, self.NEUTRA)[1]          # critico do jogador contra ele (so depende da AGILIDADE)
    cpm = P["crit_per_mark"] * fa
    cheio = max(n1, min(P["crit_cap"], n1 + mmax * cpm))
    sko = min(1.0, P["spin_ko"] * tp.get("spin_mult", 1.0))
    return {"kind": "shin", "str_factor": fm, "mark_gain": ganho, "kicks_to_full": chutes, "marks_max": mmax,
            "agi_factor": fa, "crit_now": n1, "crit_per_mark": cpm, "crit_full": cheio,
            "slow_full": P["slow_per_mark"] * tp.get("slow_mult", 1.0) * mmax, "spin_ko": sko, "spin_chance": cheio * sko,
            "opp_counter": tp.get("opponent_counter", 0.0), "marks_per_counter": tp.get("marks_per_counter", 0.0)}


def _lutar_arte(self, jog, adv, tatica, semente, registro):
    if self.pas["type"] != "shin":
        return _lutar_arte_velho(self, jog, adv, tatica, semente, registro)
    return _lutar_shin(self, jog, adv, tatica, semente, registro)


def _lutar_shin(self, jog, adv, tatica, semente, registro, sorteios=None):
    """Laco da Canela. Mesma escolha de evento e mesmos 4 sorteios por ataque (r_esq, r_crit, r_var, r_arte) do _lutar_arte."""
    c = self.c
    P = self.pas
    tp = P["tactics"].get(tatica, {})
    est = self.estado_passiva(jog, adv, tatica)
    rng = random.Random(semente)
    fila = list(sorteios) if sorteios is not None else None
    ef = (self.efetivos(jog), self.efetivos(adv))
    tj = dict(self.tac[tatica])
    tj["damage_mult"] = tj["damage_mult"] * P["damage_mult"]
    tj["taken_mult"] = tj["taken_mult"] * P["taken_mult"]
    ta = dict(self.NEUTRA)
    ta["counter_mult"] = tp.get("opponent_counter", 0.0)
    tac = (tj, ta)
    vmax = (self.vida(ef[0]), self.vida(ef[1]))
    vida = [vmax[0], vmax[1]]
    num = (self.golpe(ef[0], ef[1], tj, ta), self.golpe(ef[1], ef[0], ta, tj))
    primeiro = 0 if ef[0][1] >= ef[1][1] else 1
    base = c["attack_interval"]
    iv_j = base * P["interval_mult"]
    mmax = int(P["marks_max"])
    ganho = est["mark_gain"]
    por_contra = float(tp.get("marks_per_counter", 0.0))
    lento = P["slow_per_mark"] * tp.get("slow_mult", 1.0)
    cpm = est["crit_per_mark"]
    ccap = P["crit_cap"]
    spin_vida = P["spin_life_max"]
    sko = est["spin_ko"]
    frente = f7.FRENTE and P.get("need_ahead", 0) >= 0.5
    prox = [0.0, 0.0]
    prox[primeiro] = c["first_attack"]
    prox[1 - primeiro] = c["first_attack"] + base / 2
    contra = []
    cont = {"atq": [0, 0], "acertos": [0, 0], "esquivas": [0, 0], "crits": [0, 0],
            "dano": [0.0, 0.0], "contras": [0, 0], "maior": [0.0, 0.0], "dano_contra": [0.0, 0.0]}
    ev = []
    limite = c["time_limit"]
    spread = c["damage_spread"]
    cm = c["crit_multiplier"]
    perna = 0.0
    cheia_em = -1.0
    tentativas = 0
    rodados = 0
    while True:
        cands = [(prox[0], 1, 0), (prox[1], 1, 1)] + [(tc, 0, qc) for (tc, qc) in contra]
        t, tipo, quem = min(cands)
        eh_contra = tipo == 0
        if t > limite + 1e-9:
            break
        marcas = min(mmax, int(math.floor(perna + 1e-9)))
        if eh_contra:
            contra.remove((t, quem))
        elif quem == 0:
            prox[0] += iv_j
        else:
            prox[1] += base * (1.0 + lento * marcas)      # mancando: ele ataca mais devagar
        alvo = 1 - quem
        dano, crit, esq, _ = num[quem]
        if fila is not None:
            r_esq, r_crit, r_var, r_arte = fila[0], fila[1], fila[2], fila[3]
            del fila[:4]
        else:
            r_esq = rng.random(); r_crit = rng.random(); r_var = rng.random(); r_arte = rng.random()
        cont["atq"][quem] += 1
        if not eh_contra and r_esq < esq:
            cont["esquivas"][alvo] += 1
            if tac[alvo]["counter_mult"] > 0 and t + c["counter_delay"] <= limite + 1e-9:
                contra.append((t + c["counter_delay"], alvo))
            if registro:
                ev.append({"t": round(t, 3), "who": quem, "type": "dodge", "marks": marcas})
            continue
        if quem == 0:
            crit = max(crit, min(ccap, crit + marcas * cpm))   # cada marca: + crit_per_mark x fator de AGILIDADE
        e_crit = r_crit < crit
        d = dano * ((1 + (cm - 1) * (1 - tac[alvo]["crit_guard"])) if e_crit else 1.0)
        if eh_contra:
            d *= tac[quem]["counter_mult"]
            cont["dano_contra"][quem] += d * (1 + spread * (2 * r_var - 1))
        d *= 1 + spread * (2 * r_var - 1)
        vida[alvo] -= d
        cont["acertos"][quem] += 1
        cont["dano"][quem] += d
        if e_crit:
            cont["crits"][quem] += 1
        if eh_contra:
            cont["contras"][quem] += 1
        metodo = None
        golpe = ""
        if quem == 0:
            golpe = "spin" if (e_crit and marcas >= mmax) else ("crit" if e_crit else "kick")
        if vida[alvo] <= 1e-9 * vmax[alvo]:
            metodo = "dano" if quem == 0 else "dano_dele"
        elif quem == 0:
            if golpe == "spin":
                rodados += 1
                if vida[1] <= spin_vida * vmax[1] and (not frente or vida[1] * vmax[0] <= vida[0] * vmax[1]):
                    tentativas += 1
                    if r_arte < sko:
                        metodo = "chute_rodado"
            elif golpe == "kick":
                g = max(ganho, por_contra) if eh_contra else ganho
                perna = min(float(mmax), perna + g)
                if perna >= mmax - 1e-9 and cheia_em < 0:
                    cheia_em = t
        if registro:
            ev.append({"t": round(t, 3), "who": quem, "type": "crit" if e_crit else "hit", "counter": eh_contra,
                       "damage": d, "life_after": max(0.0, vida[alvo]), "marks": min(mmax, int(math.floor(perna + 1e-9))),
                       "move": golpe, "finish": metodo or ""})
        if metodo:
            win = quem == 0
            return {"win": win, "ko": True, "t_ko": t, "t": max(t, c["min_ko_time"]), "cont": cont, "ev": ev,
                    "pct": (max(0.0, vida[0]) / vmax[0], max(0.0, vida[1]) / vmax[1]), "vmax": vmax,
                    "metodo": metodo, "embalo_pico": 0, "tentativas": tentativas, "est": est,
                    "marcas_pico": min(mmax, int(math.floor(perna + 1e-9))), "cheia_em": cheia_em, "rodados": rodados,
                    **self._log(adv, tatica, jog, win, metodo, max(t, c["min_ko_time"]), semente)}
    p0, p1 = vida[0] / vmax[0], vida[1] / vmax[1]
    return {"win": p0 > p1, "ko": False, "t_ko": None, "t": limite, "cont": cont, "ev": ev, "pct": (p0, p1),
            "vmax": vmax, "metodo": "pontos", "embalo_pico": 0, "tentativas": tentativas, "est": est,
            "marcas_pico": min(mmax, int(math.floor(perna + 1e-9))), "cheia_em": cheia_em, "rodados": rodados,
            **self._log(adv, tatica, jog, p0 > p1, "pontos", limite, semente)}


def chance_detalhada(R, jog, adv, tatica, n=None):
    """chance() + vitorias pela passiva + quando a perna enche (mediana das lutas em que encheu) - o que a previa mostra."""
    n = n or R.risk["samples"]
    w = wp = 0
    cheias = []
    for s in range(1, n + 1):
        r = R.lutar(jog, adv, tatica, s)
        if r["win"]:
            w += 1
            wp += r["metodo"] in PASSIVA_FIM
        if r.get("cheia_em", -1) >= 0:
            cheias.append(r["cheia_em"])
    return {"chance": w / n, "wins": w, "wins_passive": wp, "n": n, "full_share": len(cheias) / n,
            "full_at": med(cheias) if cheias else -1.0}


f7.RegrasArte.estado_passiva = estado_passiva
f7.RegrasArte._lutar_arte = _lutar_arte


# =================================================================== economia: regra "clique com picos" e o Muay Thai na campanha
def mt_crit(style=0.0):
    """(chance, multiplicador) do critico do clique MANUAL com o Muay Thai."""
    return CLK["crit_chance"] + RULE_MT["chance_add"], CLK["crit_multiplier"] + RULE_MT["mult_add"] * (1.0 + style)


def mt_fator_clique(style=0.0):
    """Treino medio do clique manual com o Muay Thai / sem arte (o 'boxe_f' equivalente)."""
    ch, m = mt_crit(style)
    base = 1 + CLK["crit_chance"] * (CLK["crit_multiplier"] - 1)
    return (1 + ch * (m - 1)) / base


_def_arte_velho = f5.Carreira5.definir_arte


def definir_arte(self, arte):
    _def_arte_velho(self, arte)
    if self.P["arts"][arte]["rule"]["type"] == "click_crit_bonus":
        self.boxe_f = mt_fator_clique(self.style_bonus.get(arte, 0.0))


_adc_velho = f5.arte_da_carreira


def arte_da_carreira(politica, n_com_arte):
    return politica if politica == MT else _adc_velho(politica, n_com_arte)


_trava_velho = f5.trava_ok


def trava_ok(n, flags):
    """Medida: o Muay Thai como se estivesse liberado junto com as outras (regiao aberta com qualquer arte liberada)."""
    if n.get("lock", "") == "art:" + MT:
        return bool(flags["arts"])
    return _trava_velho(n, flags)


f5.Carreira5.definir_arte = definir_arte
f5.arte_da_carreira = arte_da_carreira
f5.trava_ok = trava_ok


# =================================================================== utilidades
def _proc():
    return int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))


def _R():
    return f5.DADOS[0]


def _adv(R0, oid):
    o = next(x for x in R0.opp if x["id"] == oid)
    return (o["strength"], o["agility"], o["endurance"])


def _regras(arte, extra=0.0):
    R0 = _R()
    return R0 if arte is None else f7.regras_arte7(R0, {}, extra, arte)


# =================================================================== ident: Boxe, Jiu-jitsu e sem arte iguais a 7a1
def sec_ident():
    """O motor com o ramo novo da as MESMAS lutas que o fase7a1_sim (Boxe, JJ, sem arte): mesmo resultado, tempo, vida e sorteios."""
    R0 = _R()
    rng = random.Random(5)
    tot = {a: 0 for a in ("sem", "boxing", "bjj")}
    iguais = dict(tot)
    for i in range(3000):
        o = R0.opp[rng.randrange(len(R0.opp))]
        adv = (o["strength"], o["agility"], o["endurance"])
        jog = tuple(sum(adv) * rng.random() for _ in range(3))
        tat = R0.tac_ids[rng.randrange(3)]
        for a in ("sem", "boxing", "bjj"):
            R = R0 if a == "sem" else f7.regras_arte7(R0, {}, (0.5 if i % 2 else 0.0), a)
            x = R.lutar(jog, adv, tat, i)
            if a == "sem":
                y = f3.Regras.lutar(R0, jog, adv, tat, i)
            else:
                y = _lutar_arte_velho(R, jog, adv, tat, i, False)
            tot[a] += 1
            iguais[a] += (x["win"], x["t"], x["pct"]) == (y["win"], y["t"], y["pct"]) and (a == "sem" or x["metodo"] == y["metodo"])
    print("\n## Identidade: lutas iguais ao motor da 7a1 (3.000 por caso): " + "; ".join(
        "%s %d de %d" % (NOME.get(a if a != "sem" else None), iguais[a], tot[a]) for a in tot))


# =================================================================== luta isolada e previa
def _linha_previa(R, jog, adv, tat, n=200):
    d = chance_detalhada(R, jog, adv, tat, n)
    e = R.estado_passiva(jog, adv, tat)
    return d, e


def sec_luta():
    R0 = _R()
    print("\n## Luta isolada: chance (200 sementes) AGR / DEF / CON, por arte. Muay Thai: chutes para encher, perna cheia (mediana, "
          "%% das lutas), critico cheio, chute rodado por golpe, vitorias pelo chute rodado")
    print("| adversario | estado (F/A/R) | sem arte | Boxe | JJ | Muay Thai | MT (Agressivo): chutes; cheia em; critico agora -> cheio; rodado/golpe; N em 10 |")
    print("|---|---|---|---|---|---|---|")
    for oid in ("opp_tank", "opp_gym_1", "opp_gym_2"):
        adv = _adv(R0, oid)
        for esc in (0.7, 0.9, 1.1):
            for div in ((1, 1, 1), (2, 1, 1), (1, 2, 1), (1, 1, 2), (2, 2, 1)):
                s = sum(div)
                jog = tuple(esc * sum(adv) * x / s for x in div)
                cel = []
                for a in (None, "boxing", "bjj", MT):
                    R = _regras(a)
                    cel.append("/".join("%.0f" % (100 * R.chance(jog, adv, t, 200)) for t in R.tac_ids))
                R = _regras(MT)
                d, e = _linha_previa(R, jog, adv, "aggressive")
                ext = "%d; %.1f s (%.0f%%); %.0f%% -> %.0f%%; %.0f%%; %d" % (
                    e["kicks_to_full"], d["full_at"], 100 * d["full_share"], 100 * e["crit_now"], 100 * e["crit_full"],
                    100 * e["spin_chance"], round(10.0 * d["wins_passive"] / max(1, d["wins"])))
                print("| %s | %.1fx %d/%d/%d | %s | %s |" % (f5.OPP_CURTO.get(oid), esc, *div, " | ".join(cel), ext))


def sec_previa():
    """Exemplos de previa (as 3 taticas) para o design."""
    R0 = _R()
    R = _regras(MT)
    print("\n## Previa do Muay Thai: chance; chutes para encher; perna cheia (mediana; %% das lutas que enchem); round; critico cheio; "
          "rodado por golpe; N em 10 vitorias pelo chute rodado; duracao da tela (min-max)")
    print("| luta | tatica | chance | chutes | cheia em | round | critico agora -> cheio | rodado/golpe | N em 10 | ele mais lento | tela |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for oid, esc, div in (("opp_gym_1", 0.9, (2, 1, 1)), ("opp_gym_1", 0.9, (1, 1, 1)), ("opp_gym_2", 0.9, (1, 1, 1)),
                          ("opp_gym_2", 0.9, (2, 2, 1)), ("opp_gym_2", 0.9, (1, 1, 2)), ("opp_tank", 0.8, (1, 1, 1))):
        adv = _adv(R0, oid)
        jog = tuple(esc * sum(adv) * x / sum(div) for x in div)
        for tat in R.tac_ids:
            d, e = _linha_previa(R, jog, adv, tat)
            telas = [R.lutar(jog, adv, tat, s)["t"] + 3.0 for s in range(1, 201)]
            rd = int(math.floor(d["full_at"] / R.c["round_length"] + 1e-9)) + 1 if d["full_at"] >= 0 else 0
            print("| %s %.1fx %d/%d/%d | %s | %.0f%% | %d | %.1f s (%.0f%%) | %d | %.0f%% -> %.0f%% | %.0f%% | %d | +%.0f%% | %.1f-%.1f s |" % (
                f5.OPP_CURTO.get(oid), esc, *div, tat, 100 * d["chance"], e["kicks_to_full"], d["full_at"], 100 * d["full_share"], rd,
                100 * e["crit_now"], 100 * e["crit_full"], 100 * e["spin_chance"],
                round(10.0 * d["wins_passive"] / max(1, d["wins"])), 100 * e["slow_full"], min(telas), max(telas)))


# =================================================================== limiar e foco (3 artes)
def _limiar_um(args):
    arte, oid, div, alvo = args
    R = _regras(arte)
    adv = _adv(_R(), oid)
    s = sum(div)

    def ok(m):
        jog = tuple(m * sum(adv) * x / s for x in div)
        return any(R.passa(jog, adv, t, 200, alvo) for t in R.tac_ids)
    lo, hi = 0.05, 4.0
    for _ in range(14):
        m = (lo + hi) / 2
        if ok(m):
            hi = m
        else:
            lo = m
    return arte, oid, div, alvo, hi


def sec_limiar():
    artes = [None, "boxing", "bjj", MT]
    divs = [(1, 1, 1), (2, 1, 1), (1, 2, 1), (1, 1, 2)]
    opps = ["opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
    tarefas = [(a, o, d, al) for o in opps for d in divs for al in (0.4, 0.9) for a in artes]
    with Pool(_proc(), initializer=f7._init7) as pool:
        res = pool.map(_limiar_um, tarefas, chunksize=4)
    tab = {(a, o, d, al): v for a, o, d, al, v in res}
    print("\n## Limiar: total (x total do adversario) para o AMARELO (40%) / VERDE (90%), melhor tatica, 200 sementes. Menor = mais forte")
    print("| adversario | divisao | sem arte | Boxe | JJ | Muay Thai |")
    print("|---|---|---|---|---|---|")
    soma = {a: [0.0, 0.0, 0] for a in artes}
    for o in opps:
        for d in divs:
            cel = []
            for a in artes:
                x, y = tab[(a, o, d, 0.4)], tab[(a, o, d, 0.9)]
                cel.append("%.2f / %.2f" % (x, y))
                soma[a][0] += x; soma[a][1] += y; soma[a][2] += 1
            print("| %s | %d/%d/%d | %s |" % (f5.OPP_CURTO.get(o), *d, " | ".join(cel)))
    print("| **media** | | %s |" % " | ".join("%.3f / %.3f" % (soma[a][0] / soma[a][2], soma[a][1] / soma[a][2]) for a in artes))
    for o in opps:
        print("- %s (media das 4 divisoes): %s" % (f5.OPP_CURTO.get(o), "; ".join(
            "%s %.3f / %.3f" % (NOME[a], sum(tab[(a, o, d, 0.4)] for d in divs) / 4, sum(tab[(a, o, d, 0.9)] for d in divs) / 4)
            for a in artes)))


def _amarelo_um(args):
    arte, oid, div = args
    R = _regras(arte)
    adv = _adv(_R(), oid)
    jog = tuple(0.9 * sum(adv) * x / sum(div) for x in div)
    ps = {t: R.chance(jog, adv, t, 200) for t in R.tac_ids}
    b = max(R.tac_ids, key=lambda t: ps[t])
    return arte, oid, div, ps[b], b


def sec_foco():
    tarefas = [(MT, o, 0) for o in ("opp_tank", "opp_gym_1", "opp_gym_2")]
    with Pool(_proc(), initializer=f7._init7) as pool:
        res = pool.map(f7._melhor_div, tarefas, chunksize=1)
    print("\n## Foco ideal do Muay Thai: divisao F/A/R que chega ao VERDE com o MENOR total (x total dele); 3 melhores")
    print("| adversario | 1a | 2a | 3a |")
    print("|---|---|---|---|")
    for arte, oid, top in res:
        print("| %s | %s |" % (f5.OPP_CURTO.get(oid), " | ".join(
            "%.0f/%.0f/%.0f -> %.2fx" % (100 * d[0], 100 * d[1], 100 * d[2], m) for m, d in top)))
    divs = [(1, 1, 1), (2, 1, 1), (1, 2, 1), (1, 1, 2), (2, 2, 1)]
    tarefas = [(a, o, d) for o in ("opp_gym_1", "opp_gym_2") for d in divs for a in (None, "boxing", "bjj", MT)]
    with Pool(_proc(), initializer=f7._init7) as pool:
        res = pool.map(_amarelo_um, tarefas, chunksize=2)
    tab = {(a, o, d): (p, b) for a, o, d, p, b in res}
    print("\n## Amarelo: chance com a melhor tatica, total = 0,9 x o dele, por divisao F/A/R")
    print("| adversario | divisao | sem arte | Boxe | JJ | Muay Thai |")
    print("|---|---|---|---|---|---|")
    for o in ("opp_gym_1", "opp_gym_2"):
        for d in divs:
            print("| %s | %d/%d/%d | %s |" % (f5.OPP_CURTO.get(o), *d, " | ".join(
                "%.0f%% (%s)" % (100 * tab[(a, o, d)][0], tab[(a, o, d)][1][:3]) for a in (None, "boxing", "bjj", MT))))


# =================================================================== previa honesta
def _estados_um(args):
    return f7.sequencia7(args)


def _honesta_um(args):
    arte, opp_id, estados, nh, semente = args
    R0 = _R()
    adv = _adv(R0, opp_id)
    rng = random.Random(semente)
    R = _regras(arte)
    soma_p, soma_w, met, durs, bins = 0.0, 0, {}, [], {}
    for i in range(nh):
        base = estados[rng.randrange(len(estados))]
        esc = 0.6 + 0.8 * rng.random()
        jog = tuple(x * esc for x in base)
        tat = R.tac_ids[rng.randrange(3)]
        p = R.chance(jog, adv, tat, R.risk["samples"])
        r = R.lutar(jog, adv, tat, rng.randrange(1 << 31) + 100000)
        soma_p += p
        soma_w += r["win"]
        b = min(4, int(p * 5))
        bins.setdefault(b, [0, 0.0, 0])
        bins[b][0] += 1; bins[b][1] += p; bins[b][2] += r["win"]
        k = r["metodo"] if r["win"] or r["metodo"] == "dano_dele" else "perdeu_pontos"
        met[k] = met.get(k, 0) + 1
        durs.append(r["t"] + 3.0)
    return arte, opp_id, nh, soma_p / nh, soma_w / nh, met, durs, bins


def sec_honesta(nh):
    n, K = int(os.environ.get("SIM_NEST", "24")), 8
    tarefas = [(cps, 1000 + s, K, "padrao", MT, "normal", f5.T_MAX5) for cps in (5, 4, 3) for s in range(n)]
    with Pool(_proc(), initializer=f7._init7) as pool:
        seqs = pool.map(_estados_um, tarefas, chunksize=1)
    est = {}
    for s in seqs:
        for r in s:
            if r["arte"] == MT:
                for l in r["lutas7"]:
                    est.setdefault(l[0], []).append(l[2])
    tarefas = [(MT, opp, lst, nh, 77) for opp, lst in sorted(est.items())]
    with Pool(_proc(), initializer=f7._init7) as pool:
        res = pool.map(_honesta_um, tarefas, chunksize=1)
    print("\n## Previa honesta, Muay Thai (%d lutas por adversario; estado = atributos reais do robo x 0,6..1,4; tatica sorteada)" % nh)
    print("| adversario | chance mostrada | vitoria real | diferenca | pior faixa (mostrada x real, n) | vitorias: dano / chute rodado / pontos | derrotas: dano dele / pontos | tela |")
    print("|---|---|---|---|---|---|---|---|")
    for arte, opp, n_, mp, mw, met, durs, bins in sorted(res, key=lambda x: [o["id"] for o in _R().opp].index(x[1])):
        pior = max(((b[1] / b[0], b[2] / b[0], b[0]) for b in bins.values() if b[0] >= 50), key=lambda x: abs(x[0] - x[1]),
                   default=(0, 0, 0))
        print("| %s | %.1f%% | %.1f%% | %+.1f | %.0f%% x %.0f%% (%d) | %d / %d / %d | %d / %d | %.1f-%.1f s |" % (
            f5.OPP_CURTO.get(opp, opp), 100 * mp, 100 * mw, 100 * (mw - mp), 100 * pior[0], 100 * pior[1], pior[2],
            met.get("dano", 0), met.get("chute_rodado", 0), met.get("pontos", 0), met.get("dano_dele", 0),
            met.get("perdeu_pontos", 0), min(durs), max(durs)))


# =================================================================== campanha (3 artes)
def sec_campanha(n, K):
    perfis = [{"nome": "%s %d/s" % (NOME[a], cps), "cps": cps, "arte": a} for cps in (4, 3) for a in ARTES]
    res = f7.rodar7(perfis, n, K)
    print("\n## Campanha (robo padrao da 7a1, hall normal; %d jogadores x %d campanhas). Muay Thai como se liberado na 1a chegada" % (n, K))
    print("| perfil | campanhas ate o Kid (med; p90; media) | Kid na 1a tentativa | tempo ate o 1o Kid: mediana / media / p90 | "
          "vitorias com arte: dano / passiva / pontos | Tonhao: pela passiva | tela (med; min-max) | cinturao (camp. med) | carreira 1 (med) |")
    print("|---|---|---|---|---|---|---|---|---|")
    T = {}
    for nome, seqs in res.items():
        ks = [f7.kid7(s) for s in seqs]
        camp = [x["camp"] for x in ks]
        tent = [x["tent"] for x in ks if x["tent"] is not None]
        tac = [x["t_acum"] for x in ks if x["t_acum"] is not None]
        lut = [l for s in seqs for r in s if r["arte"] for l in r["lutas7"]]
        vit = [l for l in lut if l[3]]
        met = {}
        for l in vit:
            k = "passiva" if l[4] in PASSIVA_FIM else l[4]
            met[k] = met.get(k, 0) + 1
        ton = [l for l in vit if l[0] == "opp_gym_1"]
        ton_p = sum(1 for l in ton if l[4] in PASSIVA_FIM)
        telas = [l[5] + 3.0 for s in seqs for r in s for l in r["lutas7"]]
        kb = [next((r["k"] for r in s if r["t_belt"]), 99) for s in seqs]
        f1 = [s[0]["t"] for s in seqs if not s[0]["t_belt"]]
        T[nome] = {"med": med(tac), "media": sum(tac) / max(1, len(tac)), "p90": pct(tac, .9), "tent": sum(tent) / max(1, len(tent)),
                   "camp": sum(min(c, 9) for c in camp) / len(camp)}
        print("| %s | %s; %s; %.2f | %.1f%% | %s / %s / %s | %d / %d / %d | %.0f%% (%d de %d) | %.1f (%.1f-%.1f) | %s | %s |" % (
            nome, f4.fmtk(med(camp)), f4.fmtk(pct(camp, .9)), T[nome]["camp"], 100 * T[nome]["tent"], mm(med(tac)),
            mm(T[nome]["media"]), mm(T[nome]["p90"]), met.get("dano", 0), met.get("passiva", 0), met.get("pontos", 0),
            100.0 * ton_p / max(1, len(ton)), ton_p, len(ton), med(telas), min(telas), max(telas), f4.fmtk(med(kb)),
            mm(med(f1)) if f1 else "-"))
    for nome, seqs in res.items():
        lut = [l for s in seqs for r in s if r["arte"] for l in r["lutas7"]]
        cel = []
        for t in ("aggressive", "defensive", "counter"):
            lt = [l for l in lut if l[1] == t]
            vt = [l for l in lt if l[3]]
            pp = sum(1 for l in vt if l[4] in PASSIVA_FIM)
            cel.append("%s %.0f%% (vitoria %.0f%%, pela passiva %.0f%%)" % (t[:3], 100.0 * len(lt) / max(1, len(lut)),
                                                                           100.0 * len(vt) / max(1, len(lt)), 100.0 * pp / max(1, len(vt))))
        print("- %s: tatica do robo: %s" % (nome, "; ".join(cel)))
    for cps in (4, 3):
        nomes = ["%s %d/s" % (NOME[a], cps) for a in ARTES]
        nomes = [x for x in nomes if x in T]
        for i in range(len(nomes)):
            for j in range(i + 1, len(nomes)):
                a, b = T[nomes[i]], T[nomes[j]]
                print("- %s x %s: tempo ate o Kid mediana %+.1f%%, media %+.1f%%; Kid na 1a %.1f x %.1f; campanhas %.2f x %.2f" % (
                    nomes[i], nomes[j], 100 * (b["med"] / a["med"] - 1), 100 * (b["media"] / a["media"] - 1),
                    100 * a["tent"], 100 * b["tent"], a["camp"], b["camp"]))
    return res


# =================================================================== forca (sem calendario) e teto
def sec_forca_teto(n, pols, titulo):
    alvos = (("opp_tank", "Muralha"), ("opp_gym_1", "Tonhao"), ("opp_gym_2", "Kid"))
    print("\n## %s (fase7a2 'forca': sem calendario, so luta no verde, derrota nao encerra; %d jogadores; arvore vazia)" % (titulo, n))
    print("| arte cps | politica | Muralha: real / sala | Tonhao: real / sala | Kid: real / sala | ganho em DIAS: Muralha / Tonhao / Kid | tempo real no Kid |")
    print("|---|---|---|---|---|---|---|")
    out = {}
    for arte in ARTES:
        for cps in (4, 3):
            tarefas = [(cps, 5000 + s, arte, pol) for pol in pols for s in range(n)]
            with Pool(_proc(), initializer=f72._init72) as pool:
                res = pool.map(f72.forca72, tarefas, chunksize=1)
            T = {}
            for j, pol in enumerate(pols):
                rs = res[j * n:(j + 1) * n]
                T[pol] = {o: (med([r[0][o][0] for r in rs if o in r[0]]), med([r[0][o][1] for r in rs if o in r[0]])) for o, _ in alvos}
            out[(arte, cps)] = T
            for pol in pols:
                g = ["%.1f%%" % (100 * (1 - T[pol][o][1] / T["nenhum"][o][1])) for o, _ in alvos]
                print("| %s %d/s | %s | %s | %s | %+.1f%% |" % (
                    NOME[arte], cps, pol, " | ".join("%s / %s" % (mm(T[pol][o][0]), mm(T[pol][o][1])) for o, _ in alvos),
                    " / ".join(g), 100 * (1 - T[pol]["opp_gym_2"][0] / T["nenhum"]["opp_gym_2"][0])))
    if "nenhum" in pols:
        print("\nTempo ate o Kid (sala, mediana, 'nenhum') entre as artes:")
        for cps in (4, 3):
            v = {a: out[(a, cps)]["nenhum"]["opp_gym_2"][1] for a in ARTES if (a, cps) in out}
            print("- %d/s: %s" % (cps, "; ".join("%s %s" % (NOME[a], mm(x)) for a, x in v.items())) + " -> " + "; ".join(
                "%s/%s %+.1f%%" % (NOME[a][:3], NOME[b][:3], 100 * (v[b] / v[a] - 1)) for a in v for b in v if a < b))
    return out


# =================================================================== Choque do Muay Thai (combo no tempo)
PERFIS_MT = {
    # segue: clica na batida (erro de tempo ~ N(0, sigma)); cps: quem nao segue a batida clica nesse ritmo (fase aleatoria)
    "parado":    {"segue": False, "cps": 0.0, "sigma": 0.0, "le": 0.0, "finta": 0.0, "reacao": 0.5},
    "afobado":   {"segue": False, "cps": 9.0, "sigma": 0.0, "le": 0.0, "finta": 0.0, "reacao": 0.5},
    "sem_ritmo": {"segue": False, "cps": 4.0, "sigma": 0.0, "le": 0.3, "finta": 0.1, "reacao": 0.5},
    "distraido": {"segue": True, "cps": 0.0, "sigma": 0.15, "le": 0.3, "finta": 0.1, "reacao": 0.5},
    "medio":     {"segue": True, "cps": 0.0, "sigma": 0.10, "le": 0.6, "finta": 0.3, "reacao": 0.40},
    "bom":       {"segue": True, "cps": 0.0, "sigma": 0.07, "le": 0.9, "finta": 0.7, "reacao": 0.30},
    "perfeito":  {"segue": True, "cps": 0.0, "sigma": 0.03, "le": 1.0, "finta": 1.0, "reacao": 0.25},
}
DT = 0.02


def jogar_choque_mt(nivel, perfil, semente):
    S = f72.MG["spar"]
    V = S["variants"][MT]
    L = S["levels"][nivel]
    P = PERFIS_MT[perfil]
    rng = random.Random(semente)
    rot = f72.roteiro_choque(nivel, rng)
    dec = [(rng.random() < P["le"], rng.random() < P["finta"]) for _ in rot]
    x, F = 0.0, 1.0
    meus = dele = 0
    congelado = 0.0
    combo = 0
    usadas = set()
    chutes = no_tempo = fora = 0
    t = 0.0
    beat = V["beat_s"]
    dur = S["duration_s"]
    # proximo clique
    if P["segue"]:
        kb = 1
        prox = kb * beat + rng.gauss(0.0, P["sigma"])
    elif P["cps"] > 0:
        prox = rng.random() / P["cps"]
    else:
        prox = 1e18
    while t < dur - 1e-9:
        fase = None
        k_atual = -1
        for k, (tipo, a, i, f) in enumerate(rot):
            if a <= t < f:
                k_atual = k
                fase = ("aviso" if t < i else "ativo", tipo, a, i, f)
                break
        empurra = L["base_push"]
        pausa = rajada = False
        if fase and fase[0] == "ativo":
            if fase[1] == "burst":
                rajada = True
                empurra = L["burst_push"]
            else:
                pausa = True
                empurra = 0.0
        guarda = False
        if fase:
            est, tipo, a, i, f = fase
            le, lf = dec[k_atual]
            visto = t >= a + P["reacao"]
            if tipo == "burst" and le and visto:
                guarda = True
            if tipo == "feint":
                if lf and t >= a + L["warn_s"] * 0.5 + P["reacao"]:
                    guarda = False
                elif le and visto:
                    guarda = t < a + L["warn_s"] + L["burst_s"]
        if congelado > 0:
            congelado -= DT
            t += DT
            while prox <= t and prox < 1e17:              # cliques durante o congelamento: ignorados (como no jogo)
                if P["segue"]:
                    kb += 1
                    prox = kb * beat + rng.gauss(0.0, P["sigma"])
                else:
                    prox += 1.0 / P["cps"]
            continue
        F = min(1.0, F + V["breath_recover_per_s"] * DT)
        while prox <= t + DT and prox < 1e17:
            tc = prox
            if P["segue"]:
                kb += 1
                prox = kb * beat + rng.gauss(0.0, P["sigma"])
            else:
                prox += 1.0 / P["cps"]
            if guarda:
                continue                                  # segurando a guarda: nao clica
            forca = V["weak_min"] + (1 - V["weak_min"]) * F
            mult = S["counter_mult"] if pausa else 1.0
            kn = int(round(tc / beat))
            if kn >= 1 and abs(tc - kn * beat) <= V["window_s"] and kn not in usadas:
                usadas.add(kn)
                combo += 1
                no_tempo += 1
                if combo >= V["combo_kick"]:
                    x += V["push_kick"] * forca * mult
                    F = max(0.0, F - V["breath_cost_per_click"] - V["breath_cost_kick"])
                    combo = 0
                    chutes += 1
                else:
                    x += V["push_on_beat"] * forca * mult
                    F = max(0.0, F - V["breath_cost_per_click"])
            else:
                fora += 1
                combo = 0
                x += V["push_off_beat"] * forca * mult
                F = max(0.0, F - V["breath_cost_per_click"])
        if rajada and guarda:
            empurra *= S["read_mult"]
        x -= empurra * DT
        if x >= 1.0:
            meus += 1; x = 0.0; congelado = S["reset_s"]; combo = 0
        elif x <= -1.0:
            dele += 1; x = 0.0; congelado = S["reset_s"]; combo = 0
        t += DT
    venceu = meus >= S["points_goal"] and meus > dele
    return meus, dele, venceu, chutes, no_tempo, fora


def _choque_mt_um(args):
    nivel, perfil, n = args
    r = [jogar_choque_mt(nivel, perfil, 7000 + s) for s in range(n)]
    return nivel, perfil, r


def sec_choque(n):
    tarefas = [(lv, p, n) for lv in (0, 2, 3, 5) for p in PERFIS_MT]
    with Pool(_proc()) as pool:
        res = pool.map(_choque_mt_um, tarefas, chunksize=1)
    print("\n## Choque do Muay Thai: pontos / pontos dele / VENCEU / premio (%% do maximo) / chutes por partida, %d partidas" % n)
    print("| perfil | nivel 0 | nivel 2 | nivel 3 | nivel 5 |")
    print("|---|---|---|---|---|")
    for p in PERFIS_MT:
        cel = []
        for lv in (0, 2, 3, 5):
            r = next(x[2] for x in res if x[0] == lv and x[1] == p)
            m = len(r)
            cel.append("%.1f / %.1f / %.0f%% / %.0f%% / %.1f" % (
                sum(x[0] for x in r) / m, sum(x[1] for x in r) / m, 100 * sum(x[2] for x in r) / m,
                100 * sum(f72.nota_choque(x[0]) for x in r) / m, sum(x[3] for x in r) / m))
        print("| %s | %s |" % (p, " | ".join(cel)))


def main():
    f7._init7(quieto=True)
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    print("Muay Thai: regra %s (clique manual x%.3f; com ESTILO 0,5 x%.3f; 0,75 x%.3f); passiva %s" % (
        RULE_MT, mt_fator_clique(0), mt_fator_clique(0.5), mt_fator_clique(0.75), json.dumps(PMT, ensure_ascii=False)))
    if tudo or "ident" in secs:
        sec_ident()
    if tudo or "luta" in secs:
        sec_luta()
    if tudo or "previa" in secs:
        sec_previa()
    if tudo or "limiar" in secs:
        sec_limiar()
    if tudo or "foco" in secs:
        sec_foco()
    if tudo or "honesta" in secs:
        sec_honesta(int(os.environ.get("SIM_NH", "1000")))
    if tudo or "choque" in secs:
        sec_choque(int(os.environ.get("SIM_NM", "400")))
    nf = int(os.environ.get("SIM_NF", "48"))
    if tudo or "forca" in secs:
        sec_forca_teto(nf, ["nenhum"], "Forca: tempo ate cada vitoria por arte")
    if tudo or "teto" in secs:
        global ARTES
        velho = ARTES
        ARTES = os.environ.get("SIM_ARTES_TETO", MT).split(",")
        sec_forca_teto(nf, os.environ.get("SIM_CONVF", "nenhum,todos_max,todos_piso,cedo_max").split(","), "Teto de 10% com o Muay Thai")
        ARTES = velho
    if tudo or "campanha" in secs:
        sec_campanha(int(os.environ.get("SIM_N7B", "200")), int(os.environ.get("SIM_K7B", "10")))


if __name__ == "__main__":
    main()
