"""Simulacao da Fase 7b2 (Segundo caminho): a 2a passiva das 3 artes, a meta que libera (M1) e o balanco das 6 combinacoes.

Design: docs/fases/fase7b2-design.md. Valores: data/arts.json -> arts[].passive_2 (a 2a passiva) e config.json/arts.json
-> passive_2.unlock (meta). Reaproveita fase7b1_sim.py (que ja carrega o 7a1 e o Muay Thai). A 1a passiva NAO muda:
este arquivo so ACRESCENTA 3 ramos novos no motor (secao ident confere).

  Boxe       2a: "counter_punch" (Contragolpista)  - guarda alta, esquiva mais; toda esquiva vira contragolpe e CARGA (0-3);
                                                     do 3o round, acerto com carga pode ser K.O. ("contragolpe_ko"). Nao cansa.
  Jiu-jitsu  2a: "top_control"   (Por cima)        - cada acerto em pe pode DERRUBAR (FORCA x AGILIDADE dele); por cima bate
                                                     mais e apanha menos; ele pode levantar; com ele <= 50%, o juiz para ("por_cima").
  Muay Thai  2a: "thai_clinch"   (Clinch)          - com ele <= 80%, cada acerto pode PRENDER no clinch (FORCA x FORCA dele) por
                                                     3,5 s: ele nao esquiva, joelhada com critico alto; a RESISTENCIA dele solta;
                                                     joelhada critica com ele <= 40% pode derrubar ("joelhada").

Mesmos 4 sorteios por ataque, de qualquer lado e na mesma ordem (r_esq, r_crit, r_var, r_arte). Nos ramos novos r_arte
tambem e lido no ataque DELE (levantar / soltar o clinch), sempre ANTES de resolver o ataque.

Rodar:  python -I tools/sim/fase7b2_sim.py [secao ...]
Secoes: ident, previa, limiar, foco, honesta, campanha, robo, ideal, exportar, tudo (padrao = ident previa limiar foco honesta campanha).
  SIM_META_TAT=1: robo que busca a meta (tatica da passiva se a chance cair <= SIM_META_GAP=0.05). SIM_CPS="4,3". SIM_CACHE=arquivo (robo).
Alavancas: SIM_PB2 / SIM_PJ2 / SIM_PM2 = "k=v,tatica.k=v" (sobrescrevem a 2a passiva), SIM_N7B (jogadores; 200),
SIM_K7B (campanhas; 10), SIM_NH (lutas da honesta; 1000), SIM_COMBOS ("boxing:1,boxing:2,..."; padrao as 6).
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
import fase3_sim as f3  # noqa: E402
import fase4_sim as f4  # noqa: E402
import fase5_sim as f5  # noqa: E402
import fase7a1_sim as f7  # noqa: E402
import fase7b1_sim as f7b  # noqa: E402  (patches: ramo shin, regra do Muay Thai, liberacao como na 7b1)

med = f4.mediana
pct = f4.pct
mm = f4.mm
RNG = random.Random          # o exportador troca por um Random que grava os sorteios

PROPOSTA2 = {
    "boxing": {
        "type": "counter_punch",
        "damage_mult": 0.80, "taken_mult": 0.90, "interval_mult": 1.0, "need_ahead": 0,
        "dodge_add": 0.08, "dodge_agility_min": 0.5, "dodge_agility_max": 1.0,
        "counter_mult": 1.0, "counter_power": 1.3,
        "charge_max": 3, "charge_per_dodge": 1, "charge_per_round": 1,
        "ko_from_round": 3, "ko_life_max": 0.6, "ko_per_charge": 0.07, "ko_endurance_min": 0.5, "ko_endurance_max": 2.0,
        "ko_cap": 0.6, "hit_ko_mult": 0.5,
        "tactics": {
            "aggressive": {"dodge_mult": 0.5, "ko_mult": 0.5},
            "defensive": {"ko_mult": 0.75},
            "counter": {"charge_per_dodge": 2},
        },
    },
    "bjj": {
        "type": "top_control",
        "damage_mult": 1.15, "taken_mult": 1.0, "interval_mult": 1.25, "need_ahead": 0,
        "td_base": 0.30, "td_strength_min": 0.5, "td_strength_max": 1.3, "td_cap": 0.8,
        "top_damage_mult": 1.00, "top_interval_mult": 0.80, "bottom_damage_mult": 0.60, "bottom_dodge_mult": 0.5,
        "escape_base": 0.20, "escape_agility_min": 0.5, "escape_agility_max": 2.0, "escape_cap": 0.6,
        "stop_life_max": 0.50, "stop_chance": 0.35,
        "tactics": {
            "aggressive": {"td_mult": 1.5},
            "defensive": {"td_mult": 1.0, "escape_mult": 0.5},
            "counter": {"td_mult": 1.0},
        },
    },
    "muay_thai": {
        "type": "thai_clinch",
        "damage_mult": 0.86, "taken_mult": 1.0, "interval_mult": 1.0, "need_ahead": 0,
        "clinch_life_max": 0.80, "clinch_base": 0.30, "clinch_strength_min": 0.5, "clinch_strength_max": 2.0, "clinch_cap": 0.8,
        "clinch_s": 3.5, "clinch_interval_mult": 0.75, "clinch_crit_add": 0.30, "crit_cap": 0.6, "clinch_taken_mult": 0.6,
        "knee_damage_mult": 1.0,
        "escape_base": 0.25, "escape_endurance_min": 0.5, "escape_endurance_max": 2.0, "escape_cap": 0.8,
        "knee_life_max": 0.40, "knee_ko": 0.5,
        "tactics": {
            "aggressive": {"clinch_mult": 0.5, "knee_mult": 1.3},
            "defensive": {"clinch_mult": 1.5, "escape_mult": 0.6, "knee_damage_mult": 1.4},
            "counter": {"clinch_mult": 1.0},
        },
    },
}
ENV2 = {"boxing": "SIM_PB2", "bjj": "SIM_PJ2", "muay_thai": "SIM_PM2"}
FIM1 = {"boxing": "nocaute", "bjj": "finalizacao", "muay_thai": "chute_rodado"}          # vitoria pela 1a passiva
FIM2 = {"boxing": "contragolpe_ko", "bjj": "por_cima", "muay_thai": "joelhada"}         # vitoria pela 2a passiva
FINISH_JOGO = {"contragolpe_ko": "counter_ko", "por_cima": "ground_stop", "joelhada": "knee_ko"}
NOME = {"boxing": "Boxe", "bjj": "Jiu-jitsu", "muay_thai": "Muay Thai", None: "sem arte"}
NOME_P = {("boxing", 1): "Mao rapida", ("boxing", 2): "Contragolpista", ("bjj", 1): "Finalizacao", ("bjj", 2): "Por cima",
          ("muay_thai", 1): "Canela", ("muay_thai", 2): "Clinch"}
META_N = 5


def carregar2():
    out = copy.deepcopy(PROPOSTA2)
    meta = META_N
    try:
        for a in f7b._ler_json("arts.json")["arts"]:
            p2 = a.get("passive_2", {})
            if p2.get("type"):
                out[a["id"]] = {k: copy.deepcopy(v) for k, v in p2.items() if k not in ("unlock", "_doc", "name", "fight_text", "icon")}
                meta = int(p2.get("unlock", {}).get("count", meta))
    except (OSError, KeyError, ValueError):
        pass
    for a, env in ENV2.items():
        f7._sobrescrever(out[a], env)
    return out, meta


P2, META_N = carregar2()
P1 = {a: copy.deepcopy(f7.PASSIVAS[a]) for a in ("boxing", "bjj", "muay_thai")}
TIPOS2 = {p["type"] for p in P2.values()}
PASSIVA_FIM = tuple(FIM1.values()) + tuple(FIM2.values())
f7b.PASSIVA_FIM = PASSIVA_FIM


def _clamp(x, a, b):
    return a if x < a else (b if x > b else x)


def _fator(meu, dele, a, b):
    return _clamp(2.0 * meu / (meu + dele), a, b) if meu + dele > 0 else 1.0


# =================================================================== motor: estado fixo da luta (previa)
_estado_7b1 = f7.RegrasArte.estado_passiva
_lutar_7b1 = f7.RegrasArte._lutar_arte


def estado_passiva(self, jog, adv, tatica):
    P = self.pas
    if P is None or P["type"] not in TIPOS2:
        return _estado_7b1(self, jog, adv, tatica)
    ej, ea = self.efetivos(jog), self.efetivos(adv)
    tp = P["tactics"].get(tatica, {})
    c = self.c
    if P["type"] == "counter_punch":
        fa = _fator(ej[1], ea[1], P["dodge_agility_min"], P["dodge_agility_max"])
        tj = self._tj(tatica)
        esq0 = self.golpe(ea, ej, self.NEUTRA, tj)[2]                  # esquiva sua contra ele, sem a passiva
        add = P["dodge_add"] * fa * tp.get("dodge_mult", 1.0)
        esq = min(c["dodge_cap"], esq0 + add)
        fr = _fator(ej[2], ea[0], P["ko_endurance_min"], P["ko_endurance_max"])
        cmax = int(P["charge_max"])
        kmax = min(P["ko_cap"], cmax * P["ko_per_charge"] * fr * tp.get("ko_mult", 1.0) * (1.0 + self.extra))
        return {"kind": "counter_punch", "agi_factor": fa, "dodge_now": esq0, "dodge": esq, "dodge_add": esq - esq0,
                "end_factor": fr, "charge_max": cmax, "charge_per_dodge": int(tp.get("charge_per_dodge", P["charge_per_dodge"])),
                "ko_max": kmax, "ko_per_charge": kmax / cmax, "ko_from": (P["ko_from_round"] - 1) * c["round_length"],
                "ko_round": int(P["ko_from_round"]), "counter_power": P["counter_power"],
                "counter_mult": max(tj["counter_mult"], P["counter_mult"])}
    if P["type"] == "top_control":
        ft = _fator(ej[0], ea[1], P["td_strength_min"], P["td_strength_max"])
        td = min(P["td_cap"], P["td_base"] * ft * tp.get("td_mult", 1.0) * (1.0 + self.extra))
        fe = _fator(ea[1], ej[0], P["escape_agility_min"], P["escape_agility_max"])
        esc = min(P["escape_cap"], P["escape_base"] * fe * tp.get("escape_mult", 1.0))
        return {"kind": "top_control", "str_factor": ft, "td_chance": td, "opp_agi_factor": fe, "escape": esc,
                "stop_life": P["stop_life_max"], "stop_chance": P["stop_chance"],
                "top_damage_mult": P["top_damage_mult"], "bottom_damage_mult": P["bottom_damage_mult"]}
    # thai_clinch
    fs = _fator(ej[0], ea[0], P["clinch_strength_min"], P["clinch_strength_max"])
    ent = min(P["clinch_cap"], P["clinch_base"] * fs * tp.get("clinch_mult", 1.0) * (1.0 + self.extra))
    fe = _fator(ea[2], ej[2], P["escape_endurance_min"], P["escape_endurance_max"])
    esc = min(P["escape_cap"], P["escape_base"] * fe * tp.get("escape_mult", 1.0))
    n1 = self.golpe(ej, ea, self.NEUTRA, self.NEUTRA)[1]
    kc = max(n1, min(P["crit_cap"], n1 + P["clinch_crit_add"]))
    kko = min(1.0, P["knee_ko"] * tp.get("knee_mult", 1.0))
    return {"kind": "thai_clinch", "str_factor": fs, "clinch_chance": ent, "opp_end_factor": fe, "escape": esc,
            "clinch_life": P["clinch_life_max"], "clinch_s": P["clinch_s"], "crit_now": n1, "knee_crit": kc, "knee_ko": kko,
            "knee_life": P["knee_life_max"], "knee_chance": kc * kko,
            "knee_damage_mult": P.get("knee_damage_mult", 1.0) * tp.get("knee_damage_mult", 1.0)}


def _tj(self, tatica):
    P = self.pas
    tj = dict(self.tac[tatica])
    tj["damage_mult"] = tj["damage_mult"] * P["damage_mult"]
    tj["taken_mult"] = tj["taken_mult"] * P["taken_mult"]
    return tj


def _lutar_arte(self, jog, adv, tatica, semente, registro):
    t = self.pas["type"]
    if t == "counter_punch":
        return _lutar_contra(self, jog, adv, tatica, semente, registro)
    if t == "top_control":
        return _lutar_cima(self, jog, adv, tatica, semente, registro)
    if t == "thai_clinch":
        return _lutar_clinch(self, jog, adv, tatica, semente, registro)
    return _lutar_7b1(self, jog, adv, tatica, semente, registro)


def _fim(self, adv, tatica, jog, semente, win, ko, t, vida, vmax, cont, ev, metodo, extra):
    c = self.c
    pc = (max(0.0, vida[0]) / vmax[0], max(0.0, vida[1]) / vmax[1])
    tf = max(t, c["min_ko_time"]) if ko else c["time_limit"]
    r = {"win": win, "ko": ko, "t_ko": t if ko else None, "t": tf, "cont": cont, "ev": ev, "pct": pc, "vmax": vmax,
         "metodo": metodo, "embalo_pico": 0}
    r.update(extra)
    self._log(adv, tatica, jog, win, metodo, tf, semente)
    return r


def _base(self, jog, adv, tatica):
    c = self.c
    ef = (self.efetivos(jog), self.efetivos(adv))
    tj = self._tj(tatica)
    ta = dict(self.NEUTRA)
    vmax = (self.vida(ef[0]), self.vida(ef[1]))
    primeiro = 0 if ef[0][1] >= ef[1][1] else 1
    prox = [0.0, 0.0]
    prox[primeiro] = c["first_attack"]
    prox[1 - primeiro] = c["first_attack"] + c["attack_interval"] / 2
    cont = {"atq": [0, 0], "acertos": [0, 0], "esquivas": [0, 0], "crits": [0, 0],
            "dano": [0.0, 0.0], "contras": [0, 0], "maior": [0.0, 0.0], "dano_contra": [0.0, 0.0]}
    return ef, tj, ta, vmax, prox, cont


# ------------------------------------------------------------------- Boxe 2: Contragolpista
def _lutar_contra(self, jog, adv, tatica, semente, registro):
    """Esquiva sua (contra o ataque normal dele) = esq de hoje + dodge_add x fa x tatica (teto dodge_cap). TODA esquiva sua
    agenda um contragolpe (counter_mult = max(tatica, passiva)) e soma carga. Contragolpe seu bate x counter_power.
    Do round ko_from_round: acerto seu que nao derrubou, com ele <= ko_life_max -> r_arte < carga x ko_per_charge
    (x hit_ko_mult se NAO for contragolpe) -> 'contragolpe_ko'. Nao cansa."""
    c = self.c
    P = self.pas
    tp = P["tactics"].get(tatica, {})
    est = self.estado_passiva(jog, adv, tatica)
    rng = RNG(semente)
    ef, tj, ta, vmax, prox, cont = _base(self, jog, adv, tatica)
    tj["counter_mult"] = est["counter_mult"]
    tac = (tj, ta)
    vida = [vmax[0], vmax[1]]
    num = [list(self.golpe(ef[0], ef[1], tj, ta)), list(self.golpe(ef[1], ef[0], ta, tj))]
    num[1][2] = est["dodge"]                    # a sua esquiva contra ele (com a passiva)
    base = c["attack_interval"]
    iv_j = base * P["interval_mult"]
    cmax = est["charge_max"]
    por_esq = est["charge_per_dodge"]
    kpc = est["ko_per_charge"]
    ko_de = est["ko_from"]
    kvida = P["ko_life_max"]
    hmult = P["hit_ko_mult"]
    pot = P["counter_power"]
    contra = []
    ev = []
    limite, spread, cm = c["time_limit"], c["damage_spread"], c["crit_multiplier"]
    carga = carga_pico = tentativas = 0
    rounds_vistos = 0
    por_round = int(P.get("charge_per_round", 0))
    while True:
        cands = [(prox[0], 1, 0), (prox[1], 1, 1)] + [(tc, 0, qc) for (tc, qc) in contra]
        t, tipo, quem = min(cands)
        eh_contra = tipo == 0
        if t > limite + 1e-9:
            break
        if eh_contra:
            contra.remove((t, quem))
        elif quem == 0:
            prox[0] += iv_j
        else:
            prox[1] += base
        alvo = 1 - quem
        rd = int(math.floor(t / c["round_length"] + 1e-9))      # rounds que ja passaram (0, 1, 2)
        if rd > rounds_vistos:
            carga = min(cmax, carga + por_round * (rd - rounds_vistos))
            carga_pico = max(carga_pico, carga)
            rounds_vistos = rd
        dano, crit, esq, _ = num[quem]
        r_esq = rng.random(); r_crit = rng.random(); r_var = rng.random(); r_arte = rng.random()
        cont["atq"][quem] += 1
        if not eh_contra and r_esq < esq:
            cont["esquivas"][alvo] += 1
            if alvo == 0:
                carga = min(cmax, carga + por_esq)
                carga_pico = max(carga_pico, carga)
            if tac[alvo]["counter_mult"] > 0 and t + c["counter_delay"] <= limite + 1e-9:
                contra.append((t + c["counter_delay"], alvo))
            if registro:
                ev.append({"t": round(t, 3), "who": quem, "type": "dodge", "charge": carga})
            continue
        e_crit = r_crit < crit
        d = dano * ((1 + (cm - 1) * (1 - tac[alvo]["crit_guard"])) if e_crit else 1.0)
        if eh_contra:
            d *= tac[quem]["counter_mult"] * (pot if quem == 0 else 1.0)
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
        elif quem == 0 and t >= ko_de - 1e-9 and carga > 0 and vida[1] <= kvida * vmax[1]:
            tentativas += 1
            if r_arte < carga * kpc * (1.0 if eh_contra else hmult):
                metodo = "contragolpe_ko"
        if registro:
            ev.append({"t": round(t, 3), "who": quem, "type": "crit" if e_crit else "hit", "counter": eh_contra,
                       "damage": d, "life_after": max(0.0, vida[alvo]), "charge": carga, "finish": metodo or ""})
        if metodo:
            return _fim(self, adv, tatica, jog, semente, quem == 0, True, t, vida, vmax, cont, ev, metodo,
                        {"tentativas": tentativas, "est": est, "carga_pico": carga_pico})
    p0, p1 = vida[0] / vmax[0], vida[1] / vmax[1]
    return _fim(self, adv, tatica, jog, semente, p0 > p1, False, limite, vida, vmax, cont, ev, "pontos",
                {"tentativas": tentativas, "est": est, "carga_pico": carga_pico})


# ------------------------------------------------------------------- Jiu-jitsu 2: Por cima
def _lutar_cima(self, jog, adv, tatica, semente, registro):
    """Em pe: acerto seu que nao derrubou por dano -> r_arte < td_chance -> QUEDA (voce por cima).
    Por cima: seu dano x top_damage_mult e seu intervalo x top_interval_mult; o dano dele x bottom_damage_mult e a esquiva
    dele x bottom_dodge_mult. Ataque normal DELE com voce por cima: ANTES de resolver, r_arte < escape -> ele levanta
    (o ataque sai em pe). Acerto seu por cima que nao derrubou, com ele <= stop_life_max: r_arte < stop_chance -> 'por_cima'."""
    c = self.c
    P = self.pas
    est = self.estado_passiva(jog, adv, tatica)
    rng = RNG(semente)
    ef, tj, ta, vmax, prox, cont = _base(self, jog, adv, tatica)
    tac = (tj, ta)
    vida = [vmax[0], vmax[1]]
    pe = (self.golpe(ef[0], ef[1], tj, ta), self.golpe(ef[1], ef[0], ta, tj))
    base = c["attack_interval"]
    iv_pe = base * P["interval_mult"]
    iv_chao = iv_pe * P["top_interval_mult"]
    td, esc = est["td_chance"], est["escape"]
    top_d, bot_d, bot_e = P["top_damage_mult"], P["bottom_damage_mult"], P["bottom_dodge_mult"]
    svida, sch = P["stop_life_max"], P["stop_chance"]
    contra = []
    ev = []
    limite, spread, cm = c["time_limit"], c["damage_spread"], c["crit_multiplier"]
    chao = False
    quedas = levantou = tentativas = 0
    queda_em = -1.0
    t_chao = 0.0
    t_ult = 0.0
    while True:
        cands = [(prox[0], 1, 0), (prox[1], 1, 1)] + [(tc, 0, qc) for (tc, qc) in contra]
        t, tipo, quem = min(cands)
        eh_contra = tipo == 0
        if t > limite + 1e-9:
            break
        if chao:
            t_chao += t - t_ult
        t_ult = t
        if eh_contra:
            contra.remove((t, quem))
        elif quem == 0:
            prox[0] += iv_chao if chao else iv_pe
        else:
            prox[1] += base
        alvo = 1 - quem
        r_esq = rng.random(); r_crit = rng.random(); r_var = rng.random(); r_arte = rng.random()
        if quem == 1 and not eh_contra and chao and r_arte < esc:
            chao = False                                   # ele levantou (o ataque sai em pe)
            levantou += 1
        dano, crit, esq, _ = pe[quem]
        if chao:
            if quem == 0:
                dano *= top_d
                esq *= bot_e
            else:
                dano *= bot_d
        cont["atq"][quem] += 1
        if not eh_contra and r_esq < esq:
            cont["esquivas"][alvo] += 1
            if tac[alvo]["counter_mult"] > 0 and t + c["counter_delay"] <= limite + 1e-9:
                contra.append((t + c["counter_delay"], alvo))
            if registro:
                ev.append({"t": round(t, 3), "who": quem, "type": "dodge", "ground": chao})
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
        golpe = ""
        if vida[alvo] <= 1e-9 * vmax[alvo]:
            metodo = "dano" if quem == 0 else "dano_dele"
        elif quem == 0:
            if chao:
                golpe = "ground"
                if vida[1] <= svida * vmax[1]:
                    tentativas += 1
                    if r_arte < sch:
                        metodo = "por_cima"
            elif r_arte < td:
                golpe = "takedown"
                chao = True
                quedas += 1
                if queda_em < 0:
                    queda_em = t
        if registro:
            ev.append({"t": round(t, 3), "who": quem, "type": "crit" if e_crit else "hit", "counter": eh_contra,
                       "damage": d, "life_after": max(0.0, vida[alvo]), "ground": chao, "move": golpe, "finish": metodo or ""})
        if metodo:
            return _fim(self, adv, tatica, jog, semente, quem == 0, True, t, vida, vmax, cont, ev, metodo,
                        {"tentativas": tentativas, "est": est, "quedas": quedas, "levantou": levantou, "queda_em": queda_em,
                         "t_chao": t_chao})
    p0, p1 = vida[0] / vmax[0], vida[1] / vmax[1]
    if chao:
        t_chao += limite - t_ult
    return _fim(self, adv, tatica, jog, semente, p0 > p1, False, limite, vida, vmax, cont, ev, "pontos",
                {"tentativas": tentativas, "est": est, "quedas": quedas, "levantou": levantou, "queda_em": queda_em,
                 "t_chao": t_chao})


# ------------------------------------------------------------------- Muay Thai 2: Clinch
def _lutar_clinch(self, jog, adv, tatica, semente, registro):
    """Fora do clinch: acerto seu que nao derrubou, com ele <= clinch_life_max -> r_arte < clinch_chance -> PRENDE ate t + clinch_s.
    No clinch (t < preso_ate): ele nao esquiva; seu critico = knee_crit; seu intervalo x clinch_interval_mult; o dano dele
    x clinch_taken_mult. Ataque normal DELE no clinch: ANTES de resolver, r_arte < escape -> solta (o ataque sai fora).
    Acerto CRITICO seu no clinch (joelhada) que nao derrubou, com ele <= knee_life_max -> r_arte < knee_ko -> 'joelhada'."""
    c = self.c
    P = self.pas
    est = self.estado_passiva(jog, adv, tatica)
    rng = RNG(semente)
    ef, tj, ta, vmax, prox, cont = _base(self, jog, adv, tatica)
    tac = (tj, ta)
    vida = [vmax[0], vmax[1]]
    fora_ = (self.golpe(ef[0], ef[1], tj, ta), self.golpe(ef[1], ef[0], ta, tj))
    base = c["attack_interval"]
    iv_j = base * P["interval_mult"]
    iv_cl = iv_j * P["clinch_interval_mult"]
    ent, esc = est["clinch_chance"], est["escape"]
    cl_s, cl_vida = P["clinch_s"], P["clinch_life_max"]
    kc, kko, kvida = est["knee_crit"], est["knee_ko"], P["knee_life_max"]
    ctk = P["clinch_taken_mult"]
    kdm = est["knee_damage_mult"]
    contra = []
    ev = []
    limite, spread, cm = c["time_limit"], c["damage_spread"], c["crit_multiplier"]
    preso_ate = -1.0
    clinches = soltou = tentativas = joelhadas = 0
    clinch_em = -1.0
    while True:
        cands = [(prox[0], 1, 0), (prox[1], 1, 1)] + [(tc, 0, qc) for (tc, qc) in contra]
        t, tipo, quem = min(cands)
        eh_contra = tipo == 0
        if t > limite + 1e-9:
            break
        preso = t < preso_ate - 1e-9
        if eh_contra:
            contra.remove((t, quem))
        elif quem == 0:
            prox[0] += iv_cl if preso else iv_j
        else:
            prox[1] += base
        alvo = 1 - quem
        r_esq = rng.random(); r_crit = rng.random(); r_var = rng.random(); r_arte = rng.random()
        if quem == 1 and not eh_contra and preso and r_arte < esc:
            preso = False
            preso_ate = t
            soltou += 1
        dano, crit, esq, _ = fora_[quem]
        if preso:
            if quem == 0:
                esq = 0.0
                crit = kc
                dano *= kdm
            else:
                dano *= ctk
        cont["atq"][quem] += 1
        if not eh_contra and r_esq < esq:
            cont["esquivas"][alvo] += 1
            if tac[alvo]["counter_mult"] > 0 and t + c["counter_delay"] <= limite + 1e-9:
                contra.append((t + c["counter_delay"], alvo))
            if registro:
                ev.append({"t": round(t, 3), "who": quem, "type": "dodge", "clinch": preso})
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
        golpe = ""
        if quem == 0:
            golpe = ("knee" if preso else "hit")
            if preso and e_crit:
                joelhadas += 1
        if vida[alvo] <= 1e-9 * vmax[alvo]:
            metodo = "dano" if quem == 0 else "dano_dele"
        elif quem == 0:
            if preso:
                if e_crit and vida[1] <= kvida * vmax[1]:
                    tentativas += 1
                    if r_arte < kko:
                        metodo = "joelhada"
            elif vida[1] <= cl_vida * vmax[1] and r_arte < ent:
                golpe = "clinch"
                preso_ate = t + cl_s
                clinches += 1
                if clinch_em < 0:
                    clinch_em = t
        if registro:
            ev.append({"t": round(t, 3), "who": quem, "type": "crit" if e_crit else "hit", "counter": eh_contra,
                       "damage": d, "life_after": max(0.0, vida[alvo]), "clinch": t < preso_ate - 1e-9, "move": golpe,
                       "finish": metodo or ""})
        if metodo:
            return _fim(self, adv, tatica, jog, semente, quem == 0, True, t, vida, vmax, cont, ev, metodo,
                        {"tentativas": tentativas, "est": est, "clinches": clinches, "soltou": soltou, "clinch_em": clinch_em,
                         "joelhadas": joelhadas})
    p0, p1 = vida[0] / vmax[0], vida[1] / vmax[1]
    return _fim(self, adv, tatica, jog, semente, p0 > p1, False, limite, vida, vmax, cont, ev, "pontos",
                {"tentativas": tentativas, "est": est, "clinches": clinches, "soltou": soltou, "clinch_em": clinch_em,
                 "joelhadas": joelhadas})


f7.RegrasArte.estado_passiva = estado_passiva
f7.RegrasArte._lutar_arte = _lutar_arte
f7.RegrasArte._tj = _tj


# =================================================================== robo "busca a meta" (SIM_META_TAT=1)
_melhor_velho = f7.RegrasArte.melhor_tatica


def melhor_tatica_meta(self, jog, adv, n=None):
    """Robo que quer a meta: entre as taticas a ate META_GAP pontos da melhor chance, escolhe a que mais vence PELA passiva
    (as mesmas sementes da previa). Sem arte ou sem SIM_META_TAT: o robo de sempre (maior chance)."""
    if self.pas is None or os.environ.get("SIM_META_TAT", "0") != "1":
        return _melhor_velho(self, jog, adv, n)
    n = n or self.risk["samples"]
    fim = FIM2.get(self.arte) if self.pas["type"] in TIPOS2 else FIM1.get(self.arte)
    ps, pp = {}, {}
    for t in self.tac_ids:
        w = wp = 0
        for s_ in range(1, n + 1):
            r = self.lutar(jog, adv, t, s_)
            w += r["win"]
            wp += r["win"] and r["metodo"] == fim
        ps[t], pp[t] = w / n, wp / n
    b = max(self.tac_ids, key=lambda t: ps[t])
    gap = float(os.environ.get("SIM_META_GAP", "0.05"))
    cands = [t for t in self.tac_ids if ps[t] >= ps[b] - gap - 1e-9]
    return max(cands, key=lambda t: (pp[t], ps[t])), ps


f7.RegrasArte.melhor_tatica = melhor_tatica_meta


# =================================================================== regras por combinacao (arte, passiva 1|2)
def usar(arte, k):
    """Poe no motor a passiva k (1 ou 2) da arte. Vale para o processo inteiro (as campanhas rodam um pool por combinacao)."""
    f7.PASSIVAS[arte] = copy.deepcopy(P1[arte] if k == 1 else P2[arte])


def _R():
    return f5.DADOS[0]


def _adv(R0, oid):
    o = next(x for x in R0.opp if x["id"] == oid)
    return (o["strength"], o["agility"], o["endurance"])


def regras(arte, k, extra=0.0):
    usar(arte, k)
    R = f7.regras_arte7(_R(), {}, extra, arte)
    return R


def chance_detalhada(R, jog, adv, tatica, n=None):
    """O que a previa conta (as mesmas 200 sementes de chance()): vitorias, vitorias pela passiva e, por passiva, o numero
    do desenho (Boxe 2: carga media no 3o round; JJ 2: em quantas lutas derruba e quando; MT 2: em quantas prende e quando)."""
    n = n or R.risk["samples"]
    w = wp = 0
    fim2 = FIM2.get(R.arte) if R.pas and R.pas["type"] in TIPOS2 else FIM1.get(R.arte)
    marca = []
    for s in range(1, n + 1):
        r = R.lutar(jog, adv, tatica, s)
        if r["win"]:
            w += 1
            wp += r["metodo"] == fim2
        if "queda_em" in r and r["queda_em"] >= 0:
            marca.append(r["queda_em"])
        if "clinch_em" in r and r["clinch_em"] >= 0:
            marca.append(r["clinch_em"])
        if "carga_pico" in r:
            marca.append(r["carga_pico"])
    out = {"chance": w / n, "wins": w, "wins_passive": wp, "n": n}
    if R.pas and R.pas["type"] in ("top_control", "thai_clinch"):
        out["share"] = len(marca) / n
        out["at"] = med(marca) if marca else -1.0
    elif R.pas and R.pas["type"] == "counter_punch":
        out["charge_med"] = med(marca) if marca else 0
    return out


# =================================================================== ident: a 1a passiva e "sem arte" iguais a 7b1
def sec_ident():
    R0 = _R()
    rng = random.Random(5)
    tot = {a: 0 for a in ("sem", "boxing", "bjj", "muay_thai")}
    iguais = dict(tot)
    for i in range(3000):
        o = R0.opp[rng.randrange(len(R0.opp))]
        adv = (o["strength"], o["agility"], o["endurance"])
        jog = tuple(sum(adv) * rng.random() for _ in range(3))
        tat = R0.tac_ids[rng.randrange(3)]
        for a in tot:
            if a == "sem":
                x = R0.lutar(jog, adv, tat, i)
                y = f3.Regras.lutar(R0, jog, adv, tat, i)
            else:
                R = regras(a, 1, 0.5 if i % 2 else 0.0)
                x = R.lutar(jog, adv, tat, i)
                y = _lutar_7b1(R, jog, adv, tat, i, False)
            tot[a] += 1
            iguais[a] += (x["win"], x["t"], x["pct"]) == (y["win"], y["t"], y["pct"])
    print("\n## Identidade: 1a passiva e sem arte iguais ao motor da 7b1 (3.000 por caso): " + "; ".join(
        "%s %d de %d" % (a, iguais[a], tot[a]) for a in tot))


# =================================================================== previa (exemplos)
def _linha(R, jog, adv, tat):
    d = chance_detalhada(R, jog, adv, tat)
    e = R.estado_passiva(jog, adv, tat)
    telas = [R.lutar(jog, adv, tat, s)["t"] + 3.0 for s in range(1, 201)]
    return d, e, min(telas), max(telas)


def _desc(arte, e, d):
    if arte == "boxing":
        return "esquiva %.0f%% -> %.0f%%; K.O. ate %.0f%% (carga %d) do %do round; carga med %s" % (
            100 * e["dodge_now"], 100 * e["dodge"], 100 * e["ko_max"], e["charge_max"], e["ko_round"], d.get("charge_med"))
    if arte == "bjj":
        rd = int(d["at"] // 5.3333333) + 1 if d["at"] >= 0 else 0
        return "queda %.0f%%/acerto; derruba em %.0f%% das lutas (med %.1f s, %do round); levanta %.0f%%/ataque; para %.0f%% abaixo de %.0f%%" % (
            100 * e["td_chance"], 100 * d["share"], d["at"], rd, 100 * e["escape"], 100 * e["stop_chance"], 100 * e["stop_life"])
    rd = int(d["at"] // 5.3333333) + 1 if d["at"] >= 0 else 0
    return "prende %.0f%%/acerto (ele <= %.0f%%); prende em %.0f%% das lutas (med %.1f s, %do round); solta %.0f%%/ataque; joelhada crit %.0f%%, derruba %.0f%%" % (
        100 * e["clinch_chance"], 100 * e["clinch_life"], 100 * d["share"], d["at"], rd, 100 * e["escape"],
        100 * e["knee_crit"], 100 * e["knee_ko"])


def sec_previa():
    R0 = _R()
    print("\n## Previa das 2as passivas: chance; descricao da linha; N em 10 vitorias pela passiva; tela")
    print("| arte | luta | tatica | chance | linha | N em 10 | tela |")
    print("|---|---|---|---|---|---|---|")
    for arte in ("boxing", "bjj", "muay_thai"):
        R = regras(arte, 2)
        for oid, esc, div in (("opp_tank", 0.8, (1, 1, 1)), ("opp_gym_1", 0.9, (1, 1, 1)), ("opp_gym_1", 0.9, (2, 1, 1)),
                              ("opp_gym_2", 0.9, (1, 1, 1)), ("opp_gym_2", 0.9, (2, 1, 1)), ("opp_gym_2", 0.9, (1, 2, 2))):
            adv = _adv(R0, oid)
            jog = tuple(esc * sum(adv) * x / sum(div) for x in div)
            for tat in R.tac_ids:
                d, e, a, b = _linha(R, jog, adv, tat)
                print("| %s | %s %.1fx %d/%d/%d | %s | %.0f%% | %s | %d | %.1f-%.1f s |" % (
                    NOME[arte], f5.OPP_CURTO.get(oid), esc, *div, tat[:3], 100 * d["chance"], _desc(arte, e, d),
                    round(10.0 * d["wins_passive"] / max(1, d["wins"])), a, b))


# =================================================================== limiar e foco (6 combinacoes)
COMBOS = [tuple((x.split(":")[0], int(x.split(":")[1]))) for x in os.environ.get(
    "SIM_COMBOS", "boxing:1,boxing:2,bjj:1,bjj:2,muay_thai:1,muay_thai:2").split(",")]


def _limiar_um(args):
    arte, k, oid, div, alvo = args
    R = regras(arte, k)
    adv = _adv(_R(), oid)
    s = sum(div)

    def ok(m):
        jog = tuple(m * sum(adv) * x / s for x in div)
        return any(R.passa(jog, adv, t, 200, alvo) for t in R.tac_ids)
    lo, hi = 0.05, 4.0
    for _ in range(13):
        m = (lo + hi) / 2
        if ok(m):
            hi = m
        else:
            lo = m
    return arte, k, oid, div, alvo, hi


def _proc():
    return int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))


def sec_limiar():
    divs = [(1, 1, 1), (2, 1, 1), (1, 2, 1), (1, 1, 2)]
    opps = ["opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
    tarefas = [(a, k, o, d, al) for o in opps for d in divs for al in (0.4, 0.9) for (a, k) in COMBOS]
    with Pool(_proc(), initializer=f7._init7) as pool:
        res = pool.map(_limiar_um, tarefas, chunksize=4)
    tab = {(a, k, o, d, al): v for a, k, o, d, al, v in res}
    print("\n## Limiar: total (x total dele) para o AMARELO (40%) / VERDE (90%), melhor tatica, media das 4 divisoes. Menor = mais forte")
    print("| adversario | " + " | ".join("%s %s" % (NOME[a], NOME_P[(a, k)]) for a, k in COMBOS) + " |")
    print("|---|" + "---|" * len(COMBOS))
    soma = {ak: [0.0, 0.0] for ak in COMBOS}
    for o in opps:
        cel = []
        for (a, k) in COMBOS:
            x = sum(tab[(a, k, o, d, 0.4)] for d in divs) / 4
            y = sum(tab[(a, k, o, d, 0.9)] for d in divs) / 4
            soma[(a, k)][0] += x / len(opps); soma[(a, k)][1] += y / len(opps)
            cel.append("%.3f / %.3f" % (x, y))
        print("| %s | %s |" % (f5.OPP_CURTO.get(o), " | ".join(cel)))
    print("| **media** | %s |" % " | ".join("%.3f / %.3f" % tuple(soma[ak]) for ak in COMBOS))


def _amarelo_um(args):
    arte, k, oid, div, esc = args
    R = regras(arte, k)
    adv = _adv(_R(), oid)
    jog = tuple(esc * sum(adv) * x / sum(div) for x in div)
    ps = {t: R.chance(jog, adv, t, 200) for t in R.tac_ids}
    b = max(R.tac_ids, key=lambda t: ps[t])
    return arte, k, oid, div, esc, ps, b


DIVS_FOCO = [(1, 1, 1), (2, 1, 1), (1, 2, 1), (1, 1, 2), (2, 2, 1), (2, 1, 2), (1, 2, 2)]


def sec_foco():
    esc = float(os.environ.get("SIM_ESC", "0.9"))
    tarefas = [(a, k, o, d, esc) for o in ("opp_tank", "opp_gym_1", "opp_gym_2") for d in DIVS_FOCO for (a, k) in COMBOS]
    with Pool(_proc(), initializer=f7._init7) as pool:
        res = pool.map(_amarelo_um, tarefas, chunksize=2)
    tab = {(a, k, o, d): (ps, b) for a, k, o, d, _, ps, b in res}
    print("\n## Amarelo: chance com a melhor tatica (e qual), total = %.2f x o dele, por divisao F/A/R" % esc)
    print("| adversario | divisao | " + " | ".join("%s %s" % (NOME[a], NOME_P[(a, k)]) for a, k in COMBOS) + " |")
    print("|---|---|" + "---|" * len(COMBOS))
    for o in ("opp_tank", "opp_gym_1", "opp_gym_2"):
        for d in DIVS_FOCO:
            print("| %s | %d/%d/%d | %s |" % (f5.OPP_CURTO.get(o), *d, " | ".join(
                "%.0f%% %s (A%.0f D%.0f C%.0f)" % (100 * tab[(a, k, o, d)][0][tab[(a, k, o, d)][1]], tab[(a, k, o, d)][1][:3],
                                                 100 * tab[(a, k, o, d)][0]["aggressive"], 100 * tab[(a, k, o, d)][0]["defensive"],
                                                 100 * tab[(a, k, o, d)][0]["counter"]) for a, k in COMBOS)))


def _ideal_um(args):
    arte, k, oid, alvo = args
    usar(arte, k)
    R0 = _R()
    o = next(x for x in R0.opp if x["id"] == oid)
    adv = (o["strength"], o["agility"], o["endurance"])
    R = f7.regras_arte7(R0, {}, 0.0, arte)
    out = []
    for f in range(1, 9):
        for a in range(1, 10 - f):
            r = 10 - f - a
            if r < 1:
                continue
            div = (f / 10, a / 10, r / 10)

            def ok(m):
                jog = tuple(m * sum(adv) * x for x in div)
                return any(R.passa(jog, adv, t, 100, alvo) for t in R.tac_ids)
            lo, hi = 0.3, 2.0
            if not ok(hi):
                continue
            for _ in range(9):
                m = (lo + hi) / 2
                if ok(m):
                    hi = m
                else:
                    lo = m
            out.append((hi, div))
    out.sort()
    return arte, k, oid, alvo, out[:3]


def sec_ideal():
    """Foco ideal: divisao F/A/R (de 10 em 10%, cada uma >= 10%) que chega ao VERDE (e ao AMARELO) com o menor total."""
    tarefas = [(a, k, o, al) for (a, k) in COMBOS for o in ("opp_tank", "opp_gym_1", "opp_gym_2") for al in (0.9, 0.4)]
    with Pool(_proc(), initializer=f7._init7) as pool:
        res = pool.map(_ideal_um, tarefas, chunksize=1)
    for al in (0.9, 0.4):
        print("\n## Foco ideal (%s): 3 melhores divisoes F/A/R e o total que precisam (x total dele). Menor = melhor" % (
            "VERDE 90%" if al == 0.9 else "AMARELO 40%"))
        print("| combinacao | Muralha | Tonhao | Kid |")
        print("|---|---|---|---|")
        for (a, k) in COMBOS:
            cel = []
            for o in ("opp_tank", "opp_gym_1", "opp_gym_2"):
                top = next(x[4] for x in res if x[:4] == (a, k, o, al))
                cel.append(" · ".join("%.0f/%.0f/%.0f %.2f" % (100 * d[0], 100 * d[1], 100 * d[2], m) for m, d in top))
            print("| %s %s | %s |" % (NOME[a], NOME_P[(a, k)], " | ".join(cel)))


# =================================================================== campanha (6 combinacoes)
def _init_combo(arte, k):
    f7._init7(quieto=True)
    usar(arte, k)


def rodar_combo(arte, k, cps, n, K):
    tarefas = [(cps, 1000 + s, K, "padrao", arte, "normal", f5.T_MAX5) for s in range(n)]
    with Pool(_proc(), initializer=_init_combo, initargs=(arte, k)) as pool:
        return pool.map(f7.sequencia7, tarefas, chunksize=1)


def resumo(arte, k, seqs):
    ks = [f7.kid7(s) for s in seqs]
    camp = [x["camp"] for x in ks]
    tent = [x["tent"] for x in ks if x["tent"] is not None]
    tac = [x["t_acum"] for x in ks if x["t_acum"] is not None]
    lut = [l for s in seqs for r in s if r["arte"] for l in r["lutas7"]]
    vit = [l for l in lut if l[3]]
    fim = FIM1[arte] if k == 1 else FIM2[arte]
    met = {}
    for l in vit:
        kk = "passiva" if l[4] == fim else l[4]
        met[kk] = met.get(kk, 0) + 1
    ton = [l for l in vit if l[0] == "opp_gym_1"]
    kid = [l for l in vit if l[0] == "opp_gym_2"]
    telas = [l[5] + 3.0 for s in seqs for r in s for l in r["lutas7"]]
    tacs = {}
    for l in lut:
        tacs[l[1]] = tacs.get(l[1], 0) + 1
    # meta M1 (so faz sentido com a 1a passiva): campanhas COM a arte ate somar META_N vitorias pela 1a passiva
    cm, tm = [], []
    for s in seqs:
        n_, c_ = 0, 0
        for r in s:
            if not r["arte"]:
                continue
            c_ += 1
            antes = n_
            for l in r["lutas7"]:
                if l[3] and l[4] == fim:
                    n_ += 1
                    if n_ >= META_N and antes < META_N:
                        tm.append(r["t_ini"])
                        break
            if n_ >= META_N:
                cm.append(c_)
                break
        else:
            cm.append(99)
    pv = [sum(1 for l in r["lutas7"] if l[3] and l[4] == fim) for s in seqs for r in s if r["arte"]]
    fins = {}
    for s in seqs:                                   # como acabaram as carreiras ate o 1o Kid (derrota/passou: contra quem)
        for r in s:
            if "opp_gym_2" in r["vit_t"]:
                break
            if r["fim"] in ("derrota", "passou"):
                kk = r["fim"][0] + ":" + f5.OPP_CURTO.get(r["opp"], r["opp"])
                fins[kk] = fins.get(kk, 0) + 1
    return {"med": med(tac), "media": sum(tac) / max(1, len(tac)), "p90": pct(tac, .9), "tent": sum(tent) / max(1, len(tent)),
            "camp": sum(min(c, 9) for c in camp) / len(camp), "camp_med": med(camp), "met": met,
            "ton_p": sum(1 for l in ton if l[4] == fim) / max(1, len(ton)), "kid_p": sum(1 for l in kid if l[4] == fim) / max(1, len(kid)),
            "tela": (med(telas), min(telas), max(telas)), "tacs": {t: v / max(1, len(lut)) for t, v in tacs.items()},
            "meta_camp_med": med(cm), "meta_camp_p90": pct(cm, .9), "meta_nunca": sum(1 for x in cm if x >= 99),
            "pv_media": sum(pv) / max(1, len(pv)), "win": len(vit) / max(1, len(lut)), "fins": fins}


def sec_campanha(n, K):
    print("\n## Campanha (robo padrao da 7a1, hall normal; %d jogadores x %d campanhas). Toda arte 'como se' liberada na 1a chegada" % (n, K))
    print("| combinacao | cps | campanhas ate o Kid (med; media) | Kid na 1a | tempo ate o 1o Kid: mediana / media / p90 | vitorias: dano / passiva / pontos | "
          "Tonhao / Kid pela passiva | tatica do robo (A/D/C) | tela (med; min-max) | passiva por campanha | meta %d: campanhas med; p90; nunca |" % META_N)
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    T = {}
    for cps in tuple(int(x) for x in os.environ.get("SIM_CPS", "4,3").split(",")):
        for (a, k) in COMBOS:
            seqs = rodar_combo(a, k, cps, n, K)
            x = resumo(a, k, seqs)
            T[(a, k, cps)] = x
            print("| %s %s | %d/s | %s; %.2f | %.1f%% | %s / %s / %s | %d / %d / %d | %.0f%% / %.0f%% | %s | %.1f (%.1f-%.1f) | %.2f | %s; %s; %d |" % (
                NOME[a], NOME_P[(a, k)], cps, f4.fmtk(x["camp_med"]), x["camp"], 100 * x["tent"], mm(x["med"]), mm(x["media"]),
                mm(x["p90"]), x["met"].get("dano", 0), x["met"].get("passiva", 0), x["met"].get("pontos", 0), 100 * x["ton_p"],
                100 * x["kid_p"], "/".join("%.0f" % (100 * x["tacs"].get(t, 0)) for t in ("aggressive", "defensive", "counter")),
                *x["tela"], x["pv_media"], f4.fmtk(x["meta_camp_med"]), f4.fmtk(x["meta_camp_p90"]), x["meta_nunca"]), flush=True)
            if os.environ.get("SIM_FINS"):
                print("  - carreiras ate o 1o Kid que acabaram em derrota (d) / passou o posto (p): %s" % (
                    ", ".join("%s %d" % kv for kv in sorted(x["fins"].items(), key=lambda kv: -kv[1]))), flush=True)
    for cps in (4, 3):
        vs = [(ak, T[(ak[0], ak[1], cps)]) for ak in COMBOS if (ak[0], ak[1], cps) in T]
        if not vs:
            continue
        meds = [v["med"] for _, v in vs]
        medias = [v["media"] for _, v in vs]
        print("- %d/s: mediana %s a %s (%.1f%%); media %s a %s (%.1f%%)" % (
            cps, mm(min(meds)), mm(max(meds)), 100 * (max(meds) / min(meds) - 1), mm(min(medias)), mm(max(medias)),
            100 * (max(medias) / min(medias) - 1)))
        for (a, k), v in vs:
            print("  - %s %s: mediana %+.1f%% e media %+.1f%% contra a media das 6" % (
                NOME[a], NOME_P[(a, k)], 100 * (v["med"] / (sum(meds) / len(meds)) - 1), 100 * (v["media"] / (sum(medias) / len(medias)) - 1)))
    return T


# =================================================================== previa honesta (2as passivas)
def _estados_combo(arte, k, n=24, K=8):
    est = {}
    for cps in (5, 4, 3):
        for s in rodar_combo(arte, k, cps, n, K):
            for r in s:
                if r["arte"] == arte:
                    for l in r["lutas7"]:
                        est.setdefault(l[0], []).append(l[2])
    return est


def _honesta_um(args):
    arte, k, opp_id, estados, nh, semente = args
    R = regras(arte, k)
    adv = _adv(_R(), opp_id)
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


def sec_honesta(nh):
    print("\n## Previa honesta (%d lutas por adversario; atributos reais do robo x 0,6..1,4; tatica sorteada)" % nh)
    print("| combinacao | adversario | mostrada | real | diferenca | vitorias: dano / passiva / pontos | derrotas: dano dele / pontos | tela |")
    print("|---|---|---|---|---|---|---|---|")
    pior = 0.0
    for (a, k) in COMBOS:
        est = _estados_combo(a, k, n=int(os.environ.get("SIM_NEST", "24")))
        tarefas = [(a, k, o, lst, nh, 77) for o, lst in est.items()]
        with Pool(_proc(), initializer=_init_combo, initargs=(a, k)) as pool:
            res = pool.map(_honesta_um, tarefas, chunksize=1)
        ordem = [o["id"] for o in _R().opp]
        fim = FIM1[a] if k == 1 else FIM2[a]
        for (_, _, o, mp, mw, met, d0, d1) in sorted(res, key=lambda x: ordem.index(x[2])):
            pior = max(pior, abs(mw - mp))
            print("| %s %s | %s | %.1f%% | %.1f%% | %+.1f | %d / %d / %d | %d / %d | %.1f-%.1f s |" % (
                NOME[a], NOME_P[(a, k)], f5.OPP_CURTO.get(o, o), 100 * mp, 100 * mw, 100 * (mw - mp), met.get("dano", 0),
                met.get(fim, 0), met.get("pontos", 0), met.get("dano_dele", 0), met.get("perdeu_pontos", 0), d0, d1), flush=True)
    print("- pior diferenca: %.1f pontos" % (100 * pior))


# =================================================================== robo: chance nos estados reais do robo (atalho de ajuste)
def _robo_um(args):
    arte, k, oid, est, escs = args
    R = regras(arte, k)
    adv = _adv(_R(), oid)
    out = []
    for esc in escs:
        tot = 0.0
        for jog in est:
            j = tuple(x * esc for x in jog)
            tot += max(R.chance(j, adv, t, 100) for t in R.tac_ids)
        out.append(tot / len(est))
    return arte, k, oid, out


def sec_robo():
    """Atributos REAIS do robo na hora da luta (campanha com a 1a passiva; o robo treina igual com as duas, porque o aparelho e
    o mesmo), escalados x0,7..1,0: chance com a melhor tatica, 1a x 2a passiva. Cache em SIM_CACHE (arquivo json)."""
    cache = os.environ.get("SIM_CACHE", "")
    est = {}
    if cache and os.path.exists(cache):
        with open(cache, encoding="utf-8") as fh:
            est = {tuple(k.split("|")): v for k, v in json.load(fh).items()}
    artes = sorted({a for a, _ in COMBOS})
    for a in artes:
        if (a, "opp_gym_2") in est:
            continue
        e = _estados_combo(a, 1, n=12, K=6)
        rng = random.Random(3)
        for o in ("opp_tank", "opp_gym_1", "opp_gym_2"):
            lst = list(e.get(o, []))
            rng.shuffle(lst)
            est[(a, o)] = lst[:40]
    if cache:
        with open(cache, "w", encoding="utf-8") as fh:
            json.dump({"|".join(k): v for k, v in est.items()}, fh)
    escs = [0.7, 0.8, 0.9, 1.0]
    tarefas = [(a, k, o, est[(a, o)], escs) for (a, k) in COMBOS for o in ("opp_tank", "opp_gym_1", "opp_gym_2")]
    with Pool(_proc(), initializer=f7._init7) as pool:
        res = pool.map(_robo_um, tarefas, chunksize=1)
    print("\n## Robo: chance (melhor tatica, 100 sementes) nos atributos reais do robo x 0,7 / 0,8 / 0,9 / 1,0")
    print("| combinacao | Muralha | Tonhao | Kid |")
    print("|---|---|---|---|")
    tab = {(a, k, o): v for a, k, o, v in res}
    for (a, k) in COMBOS:
        print("| %s %s | %s |" % (NOME[a], NOME_P[(a, k)], " | ".join(
            " / ".join("%.0f" % (100 * x) for x in tab[(a, k, o)]) for o in ("opp_tank", "opp_gym_1", "opp_gym_2"))))
    for a in artes:
        for o in ("opp_gym_2",):
            e = est[(a, o)]
            print("- %s, robo contra o Kid: divisao F/A/R %.2f/%.2f/%.2f" % (
                NOME[a], *(sum(x[i] / sum(x) for x in e) / len(e) for i in range(3))))


# =================================================================== exportar casos exatos (GDScript x Python)
class Gravador(random.Random):
    ultimo = None

    def __init__(self, semente=None):
        super().__init__(semente)
        self.sorteados = []
        Gravador.ultimo = self

    def random(self):
        x = super().random()
        self.sorteados.append(x)
        return x


def sec_exportar():
    global RNG
    RNG = Gravador
    R0 = _R()
    fim = {"dano": "damage", "dano_dele": "damage", "pontos": "points"}
    fim.update(FINISH_JOGO)
    casos = []
    rng = random.Random(72)
    for arte in ("boxing", "bjj", "muay_thai"):
        for extra in (0.0, 0.5):
            R = regras(arte, 2, extra)
            for i in range(60):
                o = R0.opp[2 + rng.randrange(len(R0.opp) - 2)]
                adv = (o["strength"], o["agility"], o["endurance"])
                m = rng.uniform(0.7, 1.3)
                w = [rng.random() + 0.3 for _ in range(3)]
                s = sum(w)
                jog = tuple(sum(adv) * m * x / s for x in w)
                tat = R.tac_ids[i % 3]
                semente = 8000 + len(casos)
                r = R.lutar(jog, adv, tat, semente, registro=True)
                est = R.estado_passiva(jog, adv, tat)
                ev = [[e["t"], e["who"], e["type"], bool(e.get("counter", False)), e.get("damage", 0.0), e.get("life_after", 0.0),
                       e.get("charge", 0), bool(e.get("ground", e.get("clinch", False))), e.get("move", ""), e.get("finish", "")]
                      for e in r["ev"]]
                c = {"player": list(jog), "opponent": list(adv), "tactic": tat, "art": arte, "passive": 2, "extra": extra,
                     "draws": list(Gravador.ultimo.sorteados), "win": r["win"], "ko": r["ko"],
                     "t_ko": r["t_ko"] if r["t_ko"] is not None else -1.0, "t_end": r["t"], "pct_player": r["pct"][0],
                     "pct_opponent": r["pct"][1], "vmax": list(r["vmax"]), "events": ev, "counts": r["cont"],
                     "finish": fim[r["metodo"]], "attempts": r["tentativas"],
                     "est": {kk: v for kk, v in est.items() if isinstance(v, (int, float, bool, str))}}
                for kk in ("carga_pico", "quedas", "levantou", "queda_em", "clinches", "soltou", "clinch_em", "joelhadas"):
                    if kk in r:
                        c[kk] = r[kk]
                casos.append(c)
    RNG = random.Random
    destino = os.path.join(f7b.f2.RAIZ, "tests", "data", "fase7b2_casos.json")
    with open(destino, "w", encoding="utf-8") as fh:
        json.dump({"exatos": casos}, fh, ensure_ascii=False)
    fins = {}
    for c in casos:
        fins[(c["art"], c["finish"])] = fins.get((c["art"], c["finish"]), 0) + 1
    print("gravado %s: %d casos; fins: %s" % (destino, len(casos), sorted(fins.items())))


def main():
    f7._init7(quieto=True)
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    print("2as passivas: %s; meta N = %d" % (json.dumps(P2, ensure_ascii=False), META_N))
    if tudo or "ident" in secs:
        sec_ident()
    if tudo or "previa" in secs:
        sec_previa()
    if tudo or "limiar" in secs:
        sec_limiar()
    if tudo or "foco" in secs:
        sec_foco()
    if tudo or "honesta" in secs:
        sec_honesta(int(os.environ.get("SIM_NH", "1000")))
    if tudo or "campanha" in secs:
        sec_campanha(int(os.environ.get("SIM_N7B", "200")), int(os.environ.get("SIM_K7B", "10")))
    if "robo" in secs:
        sec_robo()
    if "ideal" in secs:
        sec_ideal()
    if "exportar" in secs:
        sec_exportar()


if __name__ == "__main__":
    main()
