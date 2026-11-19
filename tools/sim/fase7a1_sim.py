"""Simulacao da Fase 7a1 (Cada arte luta do seu jeito): passivas de luta do Boxe e do Jiu-jitsu.

Design: docs/fases/fase7a1-design.md. Reaproveita fase6c2_sim.py (campanha atual: calendario, academia, artes, arvore
grande, Honra e hall) e troca SO a luta de quem tem arte. Sem arte a luta e a de fase3_sim.Regras.lutar (identica).

O motor daqui e a REFERENCIA do GDScript (scripts/luta.gd): mesma ordem de sorteios e mesmas contas.
  - sem arte: 3 sorteios por ataque (r_esq, r_crit, r_var), igual a hoje;
  - com arte: 4 sorteios por ataque, de QUALQUER lado (r_esq, r_crit, r_var, r_arte). r_arte so e usado no acerto do jogador.

Valores: data/arts.json -> arts[].passive (campo "type"). Sem esse campo, usa PROPOSTA abaixo.
Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/sim/fase7a1_sim.py [secao ...]
Secoes: ident, luta, limiar, foco, honesta, campanha, tudo (padrao). Resultados de referencia: docs/fases/fase7a1-design.md §7.4 e §12.
Alavancas: SIM_PASSIVA=0 (usa os tracos antigos +10%/-10%: linha de base), SIM_PBOX="k=v,k=v" e SIM_PJJ="k=v,..."
(sobrescrevem campos da passiva), SIM_N7 (jogadores por perfil, campanha), SIM_K7 (campanhas), SIM_NH (lutas da honesta),
SIM_FRENTE=0 (ignora need_ahead), SIM_NO_ARTE (value dos nos Contragolpe/Base firme; padrao 0.5), SIM_MODOS (modos extras do limiar).
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

med = f4.mediana
pct = f4.pct
mm = f4.mm
PASSIVA_ON = os.environ.get("SIM_PASSIVA", "1") == "1"
FRENTE = os.environ.get("SIM_FRENTE", "1") == "1"   # passiva so com ele mais machucado (vida %) que voce

PROPOSTA = {
    "boxing": {
        "type": "fast_hands",
        "damage_mult": 0.88, "taken_mult": 1.0, "need_ahead": 1, "speed_agility_min": 0.80, "speed_agility_max": 1.25,
        "interval_mult": 0.80,
        "tired_from_round": 3, "tired_interval_mult": 1.10,
        "streak_max": 5, "streak_per_hit": 1,
        "ko_life_max": 0.50, "ko_per_streak": 0.02, "ko_agility_min": 0.4, "ko_agility_max": 1.6, "ko_cap": 0.5,
        "tactics": {
            "aggressive": {"ko_mult": 1.5, "opponent_counter": 0.8},
            "defensive": {"ko_mult": 0.75, "tired_interval_mult": 1.0},
            "counter": {"streak_per_counter": 2},
        },
    },
    "bjj": {
        "type": "submission",
        "damage_mult": 1.20, "taken_mult": 1.0, "need_ahead": 0,
        "interval_mult": 1.25,
        "grip_per_round": 0.5, "grip_endurance_min": 0.5, "grip_endurance_max": 2.0, "grip_rate_max": 1.0,
        "sub_life_max": 0.60, "sub_base": 0.30, "sub_strength_min": 0.25, "sub_strength_max": 2.0, "sub_cap": 0.6,
        "tactics": {
            "aggressive": {"grip_mult": 0.75},
            "defensive": {"grip_mult": 1.5},
            "counter": {"grip_mult": 1.0},
        },
    },
}


def _sobrescrever(d, env):
    s = os.environ.get(env, "")
    for par in [x for x in s.split(",") if x.strip()]:
        k, v = par.split("=")
        if "." in k:
            t, campo = k.split(".", 1)
            d["tactics"].setdefault(t, {})[campo] = float(v)
        else:
            d[k] = float(v)
    return d


def carregar_passivas():
    out = copy.deepcopy(PROPOSTA)
    try:
        with open(os.path.join(f2.RAIZ, "data", "arts.json"), encoding="utf-8") as fh:
            arts = json.load(fh)["arts"]
        for a in arts:
            f = a.get("passive", {})
            if f.get("type"):
                out[a["id"]] = copy.deepcopy(f)
    except (OSError, KeyError, ValueError):
        pass
    _sobrescrever(out["boxing"], "SIM_PBOX")
    _sobrescrever(out["bjj"], "SIM_PJJ")
    return out


PASSIVAS = carregar_passivas()
LOG = []          # lutas de verdade do robo (semente grande), por carreira: (opp_id, tatica, attr, resultado)


def _clamp(x, a, b):
    return a if x < a else (b if x > b else x)


class RegrasArte(f3.Regras):
    """Regras da luta com a passiva da arte do jogador. arte=None: identica a f3.Regras."""
    arte = None
    pas = None
    extra = 0.0          # soma dos nos art_fight_bonus da arte (Contragolpe / Base firme)
    traco = (1.0, 1.0)   # SIM_PASSIVA=0: traco antigo (dano, recebido)

    @classmethod
    def de(cls, R):
        r = copy.copy(R)
        r.__class__ = cls
        return r

    def com_arte(self, arte, extra):
        r = copy.copy(self)
        r.arte, r.extra = arte, extra
        r.pas = PASSIVAS.get(arte) if (arte and PASSIVA_ON) else None
        if arte and not PASSIVA_ON:     # linha de base: tracos de hoje (5.4)
            r.pas = None
            dm = 1.10 * (1.0 + extra) if arte == "boxing" else 1.0
            tm = 0.90 * max(0.0, 1.0 - extra) if arte == "bjj" else 1.0
            r.tac = {}
            for t, d in self.tac.items():
                d2 = dict(d)
                d2["damage_mult"] = d["damage_mult"] * dm
                d2["taken_mult"] = d["taken_mult"] * tm
                r.tac[t] = d2
        return r

    # ------------------------------------------------------------ numeros fixos da luta (preparar)
    def estado_passiva(self, jog, adv, tatica):
        """O que a previa mostra (deterministico). Boxe: fator de agilidade, K.O. maximo por golpe, round do cansaco.
        Jiu-jitsu: tempo e round em que a pegada enche, chance de finalizar por golpe."""
        P = self.pas
        if P is None:
            return {}
        c = self.c
        ej, ea = self.efetivos(jog), self.efetivos(adv)
        tp = P["tactics"].get(tatica, {})
        if P["type"] == "fast_hands":
            fa = _clamp(2.0 * ej[1] / (ej[1] + ea[1]), P["ko_agility_min"], P["ko_agility_max"]) if ej[1] + ea[1] > 0 else 1.0
            pmax = min(P["ko_cap"], P["streak_max"] * P["ko_per_streak"] * fa * tp.get("ko_mult", 1.0) * (1.0 + self.extra))
            fa_bruto = 2.0 * ej[1] / (ej[1] + ea[1]) if ej[1] + ea[1] > 0 else 1.0
            return {"kind": "fast_hands", "agi_raw": fa_bruto, "agi_factor": fa, "ko_max": pmax, "ko_per_streak": pmax / P["streak_max"],
                    "tired_at": (P["tired_from_round"] - 1) * c["round_length"], "tired_round": P["tired_from_round"],
                    "opp_counter": tp.get("opponent_counter", 0.0)}
        fr = _clamp(2.0 * ej[2] / (ej[2] + ea[0]), P["grip_endurance_min"], P["grip_endurance_max"]) if ej[2] + ea[0] > 0 else 1.0
        taxa = min(P["grip_rate_max"], P["grip_per_round"] * fr * tp.get("grip_mult", 1.0) * (1.0 + self.extra))
        t_cheia = c["round_length"] / taxa
        ff = _clamp(2.0 * ej[0] / (ej[0] + ea[0]), P["sub_strength_min"], P["sub_strength_max"]) if ej[0] + ea[0] > 0 else 1.0
        return {"kind": "submission", "grip_rate": taxa, "grip_full_at": t_cheia,
                "grip_round": int(math.floor(t_cheia / c["round_length"] + 1e-9)) + 1,
                "grip_in_time": t_cheia <= c["time_limit"] + 1e-9,
                "end_factor": fr, "str_factor": ff, "sub_chance": min(P["sub_cap"], P["sub_base"] * ff)}

    def lutar(self, jog, adv, tatica, semente, registro=False):
        if self.pas is None:
            r = f3.Regras.lutar(self, jog, adv, tatica, semente, registro)
            r["metodo"] = ("dano" if r["win"] else "dano_dele") if r["ko"] else "pontos"
            if semente >= 100000:
                LOG.append((self._opp_id(adv), tatica, tuple(jog), r["win"], r["metodo"], r["t"]))
            return r
        return self._lutar_arte(jog, adv, tatica, semente, registro)

    def _opp_id(self, adv):
        for o in self.opp:
            if (o["strength"], o["agility"], o["endurance"]) == tuple(adv):
                return o["id"]
        return "?"

    def _lutar_arte(self, jog, adv, tatica, semente, registro):
        c = self.c
        P = self.pas
        tp = P["tactics"].get(tatica, {})
        box = P["type"] == "fast_hands"
        frente = FRENTE and P.get("need_ahead", 1) >= 0.5
        est = self.estado_passiva(jog, adv, tatica)
        rng = random.Random(semente)
        ef = (self.efetivos(jog), self.efetivos(adv))
        tj = dict(self.tac[tatica])
        tj["damage_mult"] = tj["damage_mult"] * P["damage_mult"]
        tj["taken_mult"] = tj["taken_mult"] * P["taken_mult"]
        ta = dict(self.NEUTRA)
        if box:
            ta["counter_mult"] = tp.get("opponent_counter", 0.0)
        tac = (tj, ta)
        vmax = (self.vida(ef[0]), self.vida(ef[1]))
        vida = [vmax[0], vmax[1]]
        num = (self.golpe(ef[0], ef[1], tj, ta), self.golpe(ef[1], ef[0], ta, tj))
        primeiro = 0 if ef[0][1] >= ef[1][1] else 1
        base = c["attack_interval"]
        iv_j = base * P["interval_mult"]
        if box and P.get("speed_agility_max", 1.0) > 1.0:   # Mao rapida: mais AGILIDADE, socos mais rapidos (rounds 1-2)
            iv_j = iv_j / _clamp(est["agi_raw"], P.get("speed_agility_min", 1.0), P["speed_agility_max"])
        if box:
            iv_cans = base * tp.get("tired_interval_mult", P["tired_interval_mult"])
            t_cansa = est["tired_at"]
            ko_passo = est["ko_per_streak"]
            embalo_max = int(P["streak_max"])
            por_acerto = int(P["streak_per_hit"])
            por_contra = int(tp.get("streak_per_counter", P["streak_per_hit"]))
            ko_vida = P["ko_life_max"]
        else:
            t_cheia = est["grip_full_at"]
            p_fin = est["sub_chance"]
            sub_vida = P.get("sub_life_max", 1.0)
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
        embalo = 0
        embalo_pico = 0
        tentativas = 0
        while True:
            cands = [(prox[0], 1, 0), (prox[1], 1, 1)] + [(tc, 0, qc) for (tc, qc) in contra]
            t, tipo, quem = min(cands)
            eh_contra = tipo == 0
            if t > limite + 1e-9:
                break
            if eh_contra:
                contra.remove((t, quem))
            elif quem == 0:
                prox[0] += (iv_cans if (box and t >= t_cansa - 1e-9) else iv_j)
            else:
                prox[1] += base
            alvo = 1 - quem
            dano, crit, esq, _ = num[quem]
            r_esq = rng.random(); r_crit = rng.random(); r_var = rng.random(); r_arte = rng.random()
            cont["atq"][quem] += 1
            if not eh_contra and r_esq < esq:
                cont["esquivas"][alvo] += 1
                if box and quem == 0:
                    embalo = 0
                if tac[alvo]["counter_mult"] > 0 and t + c["counter_delay"] <= limite + 1e-9:
                    contra.append((t + c["counter_delay"], alvo))
                if registro:
                    ev.append({"t": round(t, 3), "who": quem, "type": "dodge", "streak": embalo})
                continue
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
            if vida[alvo] <= 1e-9 * vmax[alvo]:
                metodo = "dano" if quem == 0 else "dano_dele"
            elif quem == 0:
                if box:
                    embalo = min(embalo_max, embalo + (por_contra if eh_contra else por_acerto))
                    embalo_pico = max(embalo_pico, embalo)
                    if vida[1] <= ko_vida * vmax[1] and (not frente or vida[1] * vmax[0] <= vida[0] * vmax[1]):
                        tentativas += 1
                        if r_arte < embalo * ko_passo:
                            metodo = "nocaute"
                elif t >= t_cheia - 1e-9 and vida[1] <= sub_vida * vmax[1] and (not frente or vida[1] * vmax[0] <= vida[0] * vmax[1]):
                    tentativas += 1
                    if r_arte < p_fin:
                        metodo = "finalizacao"
            if registro:
                ev.append({"t": round(t, 3), "who": quem, "type": "crit" if e_crit else "hit", "counter": eh_contra,
                           "damage": d, "life_after": max(0.0, vida[alvo]), "streak": embalo, "finish": metodo or ""})
            if metodo:
                win = quem == 0
                return {"win": win, "ko": True, "t_ko": t, "t": max(t, c["min_ko_time"]), "cont": cont, "ev": ev,
                        "pct": (max(0.0, vida[0]) / vmax[0], max(0.0, vida[1]) / vmax[1]), "vmax": vmax,
                        "metodo": metodo, "embalo_pico": embalo_pico, "tentativas": tentativas, "est": est,
                        **self._log(adv, tatica, jog, win, metodo, max(t, c["min_ko_time"]), semente)}
        p0, p1 = vida[0] / vmax[0], vida[1] / vmax[1]
        return {"win": p0 > p1, "ko": False, "t_ko": None, "t": limite, "cont": cont, "ev": ev, "pct": (p0, p1),
                "vmax": vmax, "metodo": "pontos", "embalo_pico": embalo_pico, "tentativas": tentativas, "est": est,
                **self._log(adv, tatica, jog, p0 > p1, "pontos", limite, semente)}

    def _log(self, adv, tatica, jog, win, metodo, t, semente):
        if semente >= 100000:
            LOG.append((self._opp_id(adv), tatica, tuple(jog), win, metodo, t))
        return {}


def regras_arte7(R, arte_cfg, extra=0.0, arte=None):
    if arte_cfg is None:
        return R
    if not isinstance(R, RegrasArte):
        R = RegrasArte.de(R)
    return R.com_arte(arte, extra)


def _init7(quieto=True):
    f5._init(quieto=quieto)
    d = list(f5.DADOS)
    d[0] = RegrasArte.de(d[0])
    if PASSIVA_ON:   # 7a1: Contragolpe / Base firme reforcam a passiva (valor do design; SIM_NO_ARTE muda)
        v = float(os.environ.get("SIM_NO_ARTE", "0.5"))
        tree = dict(d[5])
        tree["nodes"] = [dict(n, effect=dict(n["effect"], value=v)) if n.get("effect", {}).get("type") == "art_fight_bonus" else n
                         for n in d[5]["nodes"]]
        d[5] = tree
    f5.DADOS = tuple(d)
    f5.regras_arte = regras_arte7


# ---------------------------------------------------------------- campanha (copia da sequencia6 + log das lutas)
def sequencia7(args):
    LOG.clear()
    out = []
    velho = f6.Carreira6.rodar

    def rodar_e_guardar(self):
        LOG.clear()
        velho(self)
        out.append(list(LOG))
    f6.Carreira6.rodar = rodar_e_guardar
    try:
        seq = f6.sequencia6(args)
    finally:
        f6.Carreira6.rodar = velho
    for rec, lutas in zip(seq, out):
        rec["lutas7"] = lutas
    return seq


def rodar7(perfis, n, K):
    tarefas = []
    for p in perfis:
        for s in range(n):
            tarefas.append((p["cps"], 1000 + s, K, p.get("pol", "padrao"), p.get("arte", "boxing"),
                            p.get("hall", "normal"), p.get("t_max", f5.T_MAX5)))
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    with Pool(proc, initializer=_init7) as pool:
        res = pool.map(sequencia7, tarefas, chunksize=1)
    out, i = {}, 0
    for p in perfis:
        out[p["nome"]] = res[i:i + n]
        i += n
    return out


def kid7(s):
    """Campanhas ate o Kid (contando a da chegada), Kid na 1a tentativa, tempo acumulado ate o 1o Kid."""
    ch = next((r for r in s if r["primeira_chegada"]), None)
    rk = next((r for r in s if "opp_gym_2" in r["vit_t"]), None)
    out = {"camp": 99, "t_acum": None, "tent": None}
    if ch and rk:
        out["camp"] = rk["k"] - ch["k"] + 1
        out["t_acum"] = rk["t_ini"] + rk["vit_t"]["opp_gym_2"]
    for r in s:
        kl = [l for l in r["lutas"] if l[0] == "opp_gym_2"]
        if kl:
            out["tent"] = kl[0][1]
            break
    return out


def sec_campanha(n, K):
    perfis = [{"nome": "%s %d/s" % (nm, cps), "cps": cps, "arte": a}
              for cps in (4, 3) for nm, a in (("Boxe", "boxing"), ("Jiu-jitsu", "bjj"))]
    res = rodar7(perfis, n, K)
    print("\n## Campanha (%s; %d jogadores por perfil x %d campanhas; robo padrao da 6c2, hall normal)" % (
        "PASSIVAS 7a1" if PASSIVA_ON else "LINHA DE BASE (tracos +10%/-10%)", n, K))
    print("| perfil | campanhas ate o Kid (med; p90; media) | Kid na 1a tentativa | tempo acumulado ate o 1o Kid (med) | "
          "vitorias com arte: K.O. por dano / nocaute / finalizacao / pontos | lutas com arte: vitoria (%) | "
          "Tonhao: finalizacao entre as vitorias | tela da luta (med; min-max) | cinturao amador: campanha (med) | campanha 1: fim (med) |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    T = {}
    for nome, seqs in res.items():
        ks = [kid7(s) for s in seqs]
        camp = [x["camp"] for x in ks]
        tent = [x["tent"] for x in ks if x["tent"] is not None]
        tac = [x["t_acum"] for x in ks if x["t_acum"] is not None]
        lut = [l for s in seqs for r in s if r["arte"] for l in r["lutas7"]]
        vit = [l for l in lut if l[3]]
        met = {}
        for l in vit:
            met[l[4]] = met.get(l[4], 0) + 1
        ton = [l for l in vit if l[0] == "opp_gym_1"]
        ton_f = sum(1 for l in ton if l[4] in ("finalizacao", "nocaute"))
        telas = [l[5] + 3.0 for s in seqs for r in s for l in r["lutas7"]]
        kb = [next((r["k"] for r in s if r["t_belt"]), 99) for s in seqs]
        f1 = [s[0]["t"] for s in seqs if not s[0]["t_belt"]]
        T[nome] = {"tac_media": sum(tac) / max(1, len(tac)), "tac_p90": pct(tac, .9), "nunca": sum(1 for x in ks if x["t_acum"] is None),
                   "tac": med(tac), "tent": sum(tent) / max(1, len(tent)), "media": sum(min(c, 9) for c in camp) / len(camp),
                   "win": sum(1 for l in lut if l[3]) / max(1, len(lut))}
        print("| %s | %s; %s; %.2f | %.1f%% (%d) | %s | %s | %.1f%% (%d) | %s | %.1f-%.1f s (med %.1f) | %s | %s |" % (
            nome, f4.fmtk(med(camp)), f4.fmtk(pct(camp, .9)), T[nome]["media"], 100 * T[nome]["tent"], len(tent), mm(med(tac)),
            " / ".join("%d" % met.get(m, 0) for m in ("dano", "nocaute", "finalizacao", "pontos")),
            100 * T[nome]["win"], len(lut),
            "%.0f%% (%d de %d)" % (100.0 * ton_f / max(1, len(ton)), ton_f, len(ton)),
            min(telas), max(telas), med(telas), f4.fmtk(med(kb)), mm(med(f1)) if f1 else "-"))
    for nome, seqs in res.items():
        lut = [l for s in seqs for r in s if r["arte"] for l in r["lutas7"]]
        cel = []
        for t in ("aggressive", "defensive", "counter"):
            lt = [l for l in lut if l[1] == t]
            vt = [l for l in lt if l[3]]
            pas_ = sum(1 for l in vt if l[4] in ("nocaute", "finalizacao"))
            cel.append("%s %.0f%% (vitoria %.0f%%, pela passiva %.0f%%)" % (t, 100.0 * len(lt) / max(1, len(lut)),
                                                                           100.0 * len(vt) / max(1, len(lt)), 100.0 * pas_ / max(1, len(vt))))
        print("- %s: tatica escolhida pelo robo nas lutas com arte: %s" % (nome, "; ".join(cel)))
    for nome, seqs in res.items():
        p1, pas, ok = [], 0, 0
        for s in seqs:
            for r in s:
                kl = [l for l in r["lutas"] if l[0] == "opp_gym_2"]
                if r["fim"] == "passou" and r["opp"] == "opp_gym_2" and not kl:
                    pas += 1
                if kl:
                    p1.append(kl[0][2])
                    ok += kl[0][1]
                    break
        print("- %s: 1a luta contra o Kid: chance (med %.0f%%; p10 %.0f%%); no amarelo (<90%%) %.0f%%; venceu %.0f%%; passou o posto no Kid antes da 1a luta: %d" % (
            nome, 100 * med(p1), 100 * pct(p1, .1), 100.0 * sum(1 for p in p1 if p < 0.9) / max(1, len(p1)),
            100.0 * ok / max(1, len(p1)), pas))
    for cps in (4, 3):
        b, j = T.get("Boxe %d/s" % cps), T.get("Jiu-jitsu %d/s" % cps)
        if b and j and b["tac"] and j["tac"]:
            print("- %d/s: tempo ate o 1o Kid (media; p90; nunca venceu em %d campanhas) Boxe %s; %s; %d x Jiu-jitsu %s; %s; %d -> media %.1f%%, p90 %.1f%%" % (
                cps, K, mm(b["tac_media"]), mm(b["tac_p90"]), b["nunca"], mm(j["tac_media"]), mm(j["tac_p90"]), j["nunca"],
                f5._dif(b["tac_media"], j["tac_media"]), f5._dif(b["tac_p90"], j["tac_p90"])))
            print("- %d/s: tempo ate o 1o Kid Boxe %s x Jiu-jitsu %s -> %.1f%%; Kid na 1a tentativa %.0f%% x %.0f%% -> %.1f pontos; "
                  "media de campanhas %.2f x %.2f; vitoria nas lutas com arte %.0f%% x %.0f%%" % (
                      cps, mm(b["tac"]), mm(j["tac"]), f5._dif(b["tac"], j["tac"]), 100 * b["tent"], 100 * j["tent"],
                      100 * abs(b["tent"] - j["tent"]), b["media"], j["media"], 100 * b["win"], 100 * j["win"]))
    return res


# ---------------------------------------------------------------- luta isolada
def _R():
    return f5.DADOS[0]


def estados_da_campanha(n=48, K=8):
    """Estados reais (atributos na hora da luta) do robo, por arte e adversario."""
    perfis = [{"nome": a + str(cps), "cps": cps, "arte": a} for a in ("boxing", "bjj") for cps in (5, 4, 3)]
    res = rodar7(perfis, n, K)
    est = {}
    for nome, seqs in res.items():
        arte = "boxing" if nome.startswith("boxing") else "bjj"
        for s in seqs:
            for r in s:
                if r["arte"] != arte:
                    continue
                for l in r["lutas7"]:
                    est.setdefault((arte, l[0]), []).append(l[2])
    return est


def _honesta_um(args):
    arte, opp_id, estados, nh, semente = args
    R0 = _R()
    o = next(x for x in R0.opp if x["id"] == opp_id)
    adv = (o["strength"], o["agility"], o["endurance"])
    rng = random.Random(semente)
    R = regras_arte7(R0, {"fight": {}}, 0.0, arte)
    soma_p, soma_w, bins, met, durs = 0.0, 0, {}, {}, []
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
        met[r["metodo"]] = met.get(r["metodo"], 0) + 1
        durs.append(r["t"] + 3.0)
    return arte, opp_id, nh, soma_p / nh, soma_w / nh, bins, met, durs


def sec_honesta(nh):
    est = estados_da_campanha(int(os.environ.get("SIM_NEST", "24")), 8)
    tarefas = []
    for (arte, opp), lst in sorted(est.items()):
        tarefas.append((arte, opp, lst, nh, 77))
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    with Pool(proc, initializer=_init7) as pool:
        res = pool.map(_honesta_um, tarefas, chunksize=1)
    print("\n## Previa honesta (%d lutas por adversario e arte; estado = atributos reais do robo x 0,6..1,4; tatica sorteada)" % nh)
    print("| arte | adversario | chance mostrada (media) | vitoria real | diferenca (pontos) | pior faixa (mostrada x real, n) | fim: dano / nocaute / finalizacao / pontos / perdeu | tela (min-max) |")
    print("|---|---|---|---|---|---|---|---|")
    for arte, opp, n, mp, mw, bins, met, durs in res:
        pior = max(((b[1] / b[0], b[2] / b[0], b[0]) for b in bins.values() if b[0] >= 50), key=lambda x: abs(x[0] - x[1]),
                   default=(0, 0, 0))
        perdeu = met.get("dano_dele", 0) + sum(0 for _ in [])
        print("| %s | %s | %.1f%% | %.1f%% | %+.1f | %.0f%% x %.0f%% (%d) | %d / %d / %d / %d / ko dele %d | %.1f-%.1f s |" % (
            arte, f5.OPP_CURTO.get(opp, opp), 100 * mp, 100 * mw, 100 * (mw - mp), 100 * pior[0], 100 * pior[1], pior[2],
            met.get("dano", 0), met.get("nocaute", 0), met.get("finalizacao", 0), met.get("pontos", 0), perdeu,
            min(durs), max(durs)))


def sec_luta():
    """Mesmo estado, as tres opcoes (sem arte / Boxe / Jiu-jitsu): chance por tatica, como termina, duracao."""
    R0 = _R()
    print("\n## Luta isolada: chance (200 sementes) por tatica, sem arte x tracos antigos x passivas")
    print("Estados: atributos totais T divididos F/A/R; adversario Tonhao e Kid. Colunas: AGR / DEF / CON.")
    print("| adversario | estado (F/A/R) | sem arte | Boxe +10% (antigo) | Jiu-jitsu -10% (antigo) | Boxe 7a1 | Jiu-jitsu 7a1 | Boxe: nocaute nas vitorias | JJ: finalizacao nas vitorias; pegada cheia |")
    print("|---|---|---|---|---|---|---|---|---|")
    global PASSIVA_ON
    for oid in ("opp_gym_1", "opp_gym_2"):
        o = next(x for x in R0.opp if x["id"] == oid)
        adv = (o["strength"], o["agility"], o["endurance"])
        tot_a = sum(adv)
        for esc in (0.7, 0.9, 1.1):
            for div in ((1, 1, 1), (2, 1, 1), (1, 2, 1), (1, 1, 2)):
                s = sum(div)
                jog = tuple(esc * tot_a * x / s for x in div)
                linha = []
                velho = PASSIVA_ON
                PASSIVA_ON = False
                rb_b = regras_arte7(R0, {}, 0.0, "boxing")
                rb_j = regras_arte7(R0, {}, 0.0, "bjj")
                PASSIVA_ON = velho
                rn_b = regras_arte7(R0, {}, 0.0, "boxing")
                rn_j = regras_arte7(R0, {}, 0.0, "bjj")
                for R in (R0, rb_b, rb_j, rn_b, rn_j):
                    linha.append("/".join("%.0f" % (100 * R.chance(jog, adv, t, 200)) for t in R.tac_ids))
                extra = []
                for R in (rn_b, rn_j):
                    ws = [R.lutar(jog, adv, "defensive" if R.arte == "bjj" else "aggressive", s) for s in range(1, 201)]
                    v = [w for w in ws if w["win"]]
                    m = "nocaute" if R.arte == "boxing" else "finalizacao"
                    extra.append("%.0f%%" % (100.0 * sum(1 for w in v if w["metodo"] == m) / max(1, len(v))))
                e = rn_j.estado_passiva(jog, adv, "defensive")
                extra[1] += "; %.1f s (round %d), %.0f%%/golpe" % (e["grip_full_at"], e["grip_round"], 100 * e["sub_chance"])
                print("| %s | %.1fx %s | %s | %s | %s | %s | %s | %s | %s |" % (
                    f5.OPP_CURTO.get(oid), esc, "%d/%d/%d" % div, *linha, *extra))


def _melhor_div(args):
    arte, oid, chave = args
    R0 = _R()
    o = next(x for x in R0.opp if x["id"] == oid)
    adv = (o["strength"], o["agility"], o["endurance"])
    R = R0 if arte is None else regras_arte7(R0, {}, 0.0, arte)
    # menor total (em x do total dele) que chega a 90% com a melhor tatica, para cada divisao de 10 em 10%
    out = []
    for f in range(0, 11):
        for a in range(0, 11 - f):
            r = 10 - f - a
            div = (f / 10, a / 10, r / 10)
            lo, hi = 0.2, 3.0
            def ok(m):
                jog = tuple(m * sum(adv) * x for x in div)
                return any(R.passa(jog, adv, t, 100, 0.9) for t in R.tac_ids)
            if not ok(hi):
                continue
            for _ in range(10):
                m = (lo + hi) / 2
                if ok(m):
                    hi = m
                else:
                    lo = m
            out.append((hi, div))
    out.sort()
    return arte, oid, out[:3]


def sec_foco():
    tarefas = [(a, oid, 0) for a in (None, "boxing", "bjj") for oid in ("opp_tank", "opp_gym_1", "opp_gym_2")]
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    with Pool(proc, initializer=_init7) as pool:
        res = pool.map(_melhor_div, tarefas, chunksize=1)
    print("\n## Foco ideal: divisao F/A/R que chega ao VERDE (90%%) com o MENOR total (x total do adversario); 3 melhores")
    print("| arte | adversario | 1a | 2a | 3a |")
    print("|---|---|---|---|---|")
    for arte, oid, top in res:
        print("| %s | %s | %s |" % (arte or "sem arte", f5.OPP_CURTO.get(oid),
                                    " | ".join("%.0f/%.0f/%.0f -> %.2fx" % (100 * d[0], 100 * d[1], 100 * d[2], m) for m, d in top)))


def _limiar_um(args):
    modo, oid, div, alvo = args
    global PASSIVA_ON
    R0 = _R()
    o = next(x for x in R0.opp if x["id"] == oid)
    adv = (o["strength"], o["agility"], o["endurance"])
    if modo == "sem":
        R = R0
    else:
        partes = modo.split(":")
        arte, ver = partes[0], partes[1]
        PASSIVA_ON = ver == "novo"
        R = regras_arte7(R0, {}, float(partes[2]) if len(partes) > 2 else 0.0, arte)
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
    return modo, oid, div, alvo, hi


def sec_limiar():
    """Total de atributos (x total do adversario) que chega a 40% (amarelo) e a 90% (verde) com a melhor tatica."""
    modos = ["sem", "boxing:velho", "bjj:velho", "boxing:novo", "bjj:novo"] + os.environ.get("SIM_MODOS", "").split()
    divs = [(1, 1, 1), (2, 1, 1), (1, 2, 1), (1, 1, 2)]
    opps = ["opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
    tarefas = [(m, o, d, a) for o in opps for d in divs for a in (0.4, 0.9) for m in modos]
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    with Pool(proc, initializer=_init7) as pool:
        res = pool.map(_limiar_um, tarefas, chunksize=4)
    tab = {(m, o, d, a): v for m, o, d, a, v in res}
    print("\n## Limiar: total de atributos (x total do adversario) para o AMARELO (40%) / VERDE (90%), melhor tatica, 200 sementes")
    print("| adversario | divisao F/A/R | sem arte | Boxe antigo | JJ antigo | Boxe 7a1 | JJ 7a1 |")
    print("|---|---|---|---|---|---|---|")
    soma = {m: [0.0, 0.0, 0] for m in modos}
    for o in opps:
        for d in divs:
            cel = []
            for m in modos:
                a, b = tab[(m, o, d, 0.4)], tab[(m, o, d, 0.9)]
                cel.append("%.2f / %.2f" % (a, b))
                soma[m][0] += a; soma[m][1] += b; soma[m][2] += 1
            print("| %s | %d/%d/%d | %s |" % (f5.OPP_CURTO.get(o), *d, " | ".join(cel)))
    print("| **media** | | %s |" % " | ".join("%.3f / %.3f" % (soma[m][0] / soma[m][2], soma[m][1] / soma[m][2]) for m in modos))
    for o in ("opp_gym_1", "opp_gym_2"):
        print("- %s (media das 4 divisoes): %s" % (f5.OPP_CURTO.get(o), "; ".join(
            "%s %.3f / %.3f" % (m, sum(tab[(m, o, d, 0.4)] for d in divs) / 4, sum(tab[(m, o, d, 0.9)] for d in divs) / 4) for m in modos)))


def sec_ident():
    """Sem arte, RegrasArte.lutar == f3.Regras.lutar (mesmo resultado, mesmos sorteios)."""
    R0 = _R()
    rng = random.Random(5)
    iguais = 0
    for i in range(2000):
        o = R0.opp[rng.randrange(len(R0.opp))]
        adv = (o["strength"], o["agility"], o["endurance"])
        jog = tuple(sum(adv) * rng.random() for _ in range(3))
        tat = R0.tac_ids[rng.randrange(3)]
        a = f3.Regras.lutar(R0, jog, adv, tat, i)
        b = R0.lutar(jog, adv, tat, i)
        iguais += (a["win"], a["t"], a["pct"]) == (b["win"], b["t"], b["pct"])
    print("\n## Identidade sem arte: %d de 2000 lutas iguais a fase3_sim" % iguais)


def main():
    _init7(quieto=True)
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    print("Passivas: %s" % ("LIGADAS" if PASSIVA_ON else "DESLIGADAS (tracos antigos)"))
    print(json.dumps(PASSIVAS, ensure_ascii=False))
    if tudo or "ident" in secs:
        sec_ident()
    if tudo or "luta" in secs:
        sec_luta()
    if tudo or "limiar" in secs:
        sec_limiar()
    if tudo or "foco" in secs:
        sec_foco()
    if tudo or "honesta" in secs:
        sec_honesta(int(os.environ.get("SIM_NH", "1000")))
    if tudo or "campanha" in secs:
        sec_campanha(int(os.environ.get("SIM_N7", "200")), int(os.environ.get("SIM_K7", "10")))


if __name__ == "__main__":
    main()
