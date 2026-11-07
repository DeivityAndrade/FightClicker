"""Simulacao da Fase 3 (Lutas e fim de carreira) do Fightclicker.

Le data/fights.json, data/opponents.json, data/shop.json e data/career.json quando
existirem; senao usa os valores do design (docs/fases/fase3-design.md, secao "Dados").
A garagem (clique, geradores, melhorias) vem de data/training.json e data/generators.json,
com as mesmas regras de tools/sim/fase2_sim.py (importado daqui).

Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase3_sim.py [secao ...]
Secoes: limiares, duracao, risco, taticas, foco, carreiras, motivo, dica, explica (pos-QA), tudo (padrao).

A luta aqui e a REFERENCIA do design: o GDScript precisa dar o mesmo resultado
para o mesmo estado e a mesma semente (mesma ordem de sorteios, ver design secao 4).
O gerador de numeros do Python nao e o do Godot, entao a igualdade golpe a golpe
vale dentro de cada linguagem; as estatisticas e os rotulos e que tem que bater.
"""
import json
import math
import os
import random
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import fase2_sim as f2  # noqa: E402

RAIZ = f2.RAIZ

# ---------------------------------------------------------------- dados padrao
PADRAO_FIGHTS = {
    "combat": {
        "general_share": 0.10,
        "life_base": 100, "life_per_endurance": 5,
        "damage_base": 10, "damage_per_strength": 1,
        "reduction_max": 0.5,
        "crit_base": 0.05, "crit_gain": 0.50, "crit_multiplier": 2.0,
        "dodge_base": 0.03, "dodge_gain": 0.50, "dodge_cap": 0.75,
        "damage_spread": 0.15,
        "first_attack": 0.9, "attack_interval": 1.8, "counter_delay": 0.5,
        "time_limit": 16.0, "min_ko_time": 5.0, "round_length": 6.0,
        "intro_seconds": 1.5, "outro_seconds": 1.5,
    },
    "tactics": [
        {"id": "aggressive", "damage_mult": 1.35, "taken_mult": 1.25, "pierce": 0.5,
         "dodge_mult": 1.0, "dodge_bonus": 0.0, "counter_mult": 0.0, "crit_guard": 0.0},
        {"id": "defensive", "damage_mult": 0.85, "taken_mult": 0.85, "pierce": 0.0,
         "dodge_mult": 1.0, "dodge_bonus": 0.0, "counter_mult": 0.0, "crit_guard": 1.0},
        {"id": "counter", "damage_mult": 0.90, "taken_mult": 1.0, "pierce": 0.0,
         "dodge_mult": 2.0, "dodge_bonus": 0.0, "counter_mult": 1.0, "crit_guard": 0.0},
    ],
    "default_tactic": "defensive",
    "risk": {"samples": 200, "easy_min": 0.90, "even_min": 0.40},
    "reason": {"delta_share": 0.25, "delta_min": 10, "target": 0.90, "search_steps": 14,
               "search_max_share": 16.0, "tactic_tip_gap": 0.25},
}
PADRAO_OPPONENTS = {"opponents": [
    {"id": "opp_warmup", "strength": 1200, "agility": 100, "endurance": 800,
     "prize_money": 50, "prize_fame": 10, "belt": False},
    {"id": "opp_strong", "strength": 27000, "agility": 1400, "endurance": 5400,
     "prize_money": 150, "prize_fame": 30, "belt": False},
    {"id": "opp_fast", "strength": 20000, "agility": 110000, "endurance": 6000,
     "prize_money": 400, "prize_fame": 60, "belt": False},
    {"id": "opp_tank", "strength": 78000, "agility": 58000, "endurance": 490000,
     "prize_money": 1000, "prize_fame": 100, "belt": True},
]}
PADRAO_SHOP = {
    "paid_generators": [
        {"id": "gen_paid_1", "base_cost": 50, "growth": 1.6, "production": 25, "draw_thresholds": [1, 4]},
    ],
    "gloves": {"id": "glove_shop", "levels": [
        {"id": "glove_l1", "cost": 120, "click_multiplier": 2},
        {"id": "glove_l2", "cost": 500, "click_multiplier": 2},
    ]},
}
PADRAO_CAREER = {
    "legacy_per_fame": 0.2, "belt_legacy_bonus": 10,
    "defeat_share": 0.5, "retire_share": 1.0, "retire_belt_bonus_share": 0.5,
}

ATTR = ("strength", "agility", "endurance")
APAR = ("punching_bag", "jump_rope", "treadmill")


def ler(nome, padrao):
    p = os.path.join(RAIZ, "data", nome)
    if os.path.exists(p):
        with open(p, encoding="utf-8") as f:
            return json.load(f), "data/" + nome
    return padrao, "padrao do design"


# ---------------------------------------------------------------- luta
class Regras:
    def __init__(self, fights, opponents):
        self.c = dict(PADRAO_FIGHTS["combat"])
        self.c.update(fights.get("combat", {}))
        self.tac = {t["id"]: t for t in fights.get("tactics", PADRAO_FIGHTS["tactics"])}
        self.tac_ids = [t["id"] for t in fights.get("tactics", PADRAO_FIGHTS["tactics"])]
        self.risk = dict(PADRAO_FIGHTS["risk"]); self.risk.update(fights.get("risk", {}))
        self.reason = dict(PADRAO_FIGHTS["reason"]); self.reason.update(fights.get("reason", {}))
        self.opp = opponents["opponents"]

    def efetivos(self, x):
        g = self.c["general_share"] * (x[0] + x[1] + x[2])
        return (x[0] + g, x[1] + g, x[2] + g)

    def vida(self, ef):
        return self.c["life_base"] + self.c["life_per_endurance"] * ef[2]

    def golpe(self, at, df, ta, td):
        """Numeros de um golpe de 'at' em 'df' (atributos efetivos). Ver design 4.3."""
        c = self.c
        bruto = c["damage_base"] + c["damage_per_strength"] * at[0]
        den = df[2] + at[0]
        red = c["reduction_max"] * df[2] / den if den > 0 else 0.0
        red *= 1 - ta["pierce"]
        dano = bruto * (1 - red) * ta["damage_mult"] * td["taken_mult"]
        soma = at[1] + df[1]
        v = (at[1] - df[1]) / soma if soma > 0 else 0.0   # vantagem de agilidade do atacante, -1..1
        crit = c["crit_base"] + c["crit_gain"] * max(0.0, v)
        esq = min(c["dodge_cap"], (c["dodge_base"] + c["dodge_gain"] * max(0.0, -v)) * td.get("dodge_mult", 1.0)
                  + td["dodge_bonus"])
        return dano, crit, esq, red

    NEUTRA = {"damage_mult": 1.0, "taken_mult": 1.0, "pierce": 0.0, "dodge_mult": 1.0, "dodge_bonus": 0.0,
              "counter_mult": 0.0, "crit_guard": 0.0}

    def lutar(self, jog, adv, tatica, semente, registro=False):
        """Uma luta completa. jog/adv = (forca, agilidade, resistencia) crus.
        Ordem dos sorteios por ataque (fixa, o GDScript tem que seguir): esquiva, critico, variacao."""
        c = self.c
        rng = random.Random(semente)
        ef = (self.efetivos(jog), self.efetivos(adv))
        tac = (self.tac[tatica], self.NEUTRA)
        vmax = (self.vida(ef[0]), self.vida(ef[1]))
        vida = [vmax[0], vmax[1]]
        num = (self.golpe(ef[0], ef[1], tac[0], tac[1]), self.golpe(ef[1], ef[0], tac[1], tac[0]))
        primeiro = 0 if ef[0][1] >= ef[1][1] else 1
        prox = [0.0, 0.0]
        prox[primeiro] = c["first_attack"]
        prox[1 - primeiro] = c["first_attack"] + c["attack_interval"] / 2
        contra = []  # (tempo, quem)
        cont = {"atq": [0, 0], "acertos": [0, 0], "esquivas": [0, 0], "crits": [0, 0],
                "dano": [0.0, 0.0], "contras": [0, 0], "maior": [0.0, 0.0]}
        ev = []
        limite = c["time_limit"]
        spread = c["damage_spread"]
        cm = c["crit_multiplier"]
        while True:
            # proximo evento: menor tempo; no empate, contra-golpe antes de ataque normal; depois jogador (0)
            cands = [(prox[0], 1, 0), (prox[1], 1, 1)] + [(tc, 0, qc) for (tc, qc) in contra]
            t, tipo, quem = min(cands)
            eh_contra = tipo == 0
            if t > limite + 1e-9:
                break
            if eh_contra:
                contra.remove((t, quem))
            else:
                prox[quem] += c["attack_interval"]
            alvo = 1 - quem
            dano, crit, esq, _ = num[quem]
            r_esq = rng.random(); r_crit = rng.random(); r_var = rng.random()
            cont["atq"][quem] += 1
            if not eh_contra and r_esq < esq:
                cont["esquivas"][alvo] += 1
                if tac[alvo]["counter_mult"] > 0 and t + c["counter_delay"] <= limite + 1e-9:
                    contra.append((t + c["counter_delay"], alvo))
                if registro:
                    ev.append({"t": round(t, 3), "who": quem, "type": "dodge"})
                continue
            e_crit = r_crit < crit
            d = dano * ((1 + (cm - 1) * (1 - tac[alvo]["crit_guard"])) if e_crit else 1.0)
            if eh_contra:
                d *= tac[quem]["counter_mult"]
            d *= 1 + spread * (2 * r_var - 1)
            vida[alvo] -= d
            cont["acertos"][quem] += 1
            cont["dano"][quem] += d
            cont["maior"][quem] = max(cont["maior"][quem], d / vmax[alvo])
            if e_crit:
                cont["crits"][quem] += 1
            if eh_contra:
                cont["contras"][quem] += 1
            if registro:
                ev.append({"t": round(t, 3), "who": quem, "type": "crit" if e_crit else "hit",
                           "counter": eh_contra, "damage": d, "life_after": max(0.0, vida[alvo])})
            if vida[alvo] <= 1e-9 * vmax[alvo]:
                # K.O. decidido aqui; na tela ele cambaleia (grogue) ate min_ko_time e cai
                return {"win": alvo == 1, "ko": True, "t_ko": t, "t": max(t, c["min_ko_time"]), "cont": cont,
                        "ev": ev, "pct": (max(0.0, vida[0]) / vmax[0], max(0.0, vida[1]) / vmax[1]), "vmax": vmax}
        p0, p1 = vida[0] / vmax[0], vida[1] / vmax[1]
        # empate exato no tempo: vence o adversario (design 4.6)
        return {"win": p0 > p1, "ko": False, "t_ko": None, "t": limite, "cont": cont, "ev": ev,
                "pct": (p0, p1), "vmax": vmax}

    def tela(self, r):
        return self.c["intro_seconds"] + r["t"] + self.c["outro_seconds"]

    def chance(self, jog, adv, tatica, n=None):
        n = n or self.risk["samples"]
        w = 0
        for s in range(1, n + 1):
            if self.lutar(jog, adv, tatica, s)["win"]:
                w += 1
        return w / n

    def passa(self, jog, adv, tatica, n, limiar):
        """Mesmo resultado que chance(...) >= limiar, parando cedo quando ja se sabe."""
        precisa = math.ceil(limiar * n - 1e-9)
        w = 0
        for s in range(1, n + 1):
            if self.lutar(jog, adv, tatica, s)["win"]:
                w += 1
                if w >= precisa:
                    return True
            elif w + (n - s) < precisa:
                return False
        return w >= precisa

    def rotulo(self, p):
        if p >= self.risk["easy_min"]:
            return "facil"
        if p >= self.risk["even_min"]:
            return "equilibrado"
        return "perigoso"

    def melhor_tatica(self, jog, adv, n=None):
        ps = {t: self.chance(jog, adv, t, n) for t in self.tac_ids}
        b = max(self.tac_ids, key=lambda t: ps[t])
        return b, ps

    def falta_para(self, jog, adv, tatica, i, n=None, alvo=None, passos=None):
        """Menor quantidade extra do atributo i que deixa a luta 'facil' (None se nem 16x o total basta)."""
        rs = self.reason
        alvo = rs["target"] if alvo is None else alvo
        passos = rs["search_steps"] if passos is None else passos
        tot = jog[0] + jog[1] + jog[2]
        def p_com(extra):
            x = list(jog); x[i] += extra
            return self.chance(tuple(x), adv, tatica, n)
        hi = rs["search_max_share"] * tot + 1000
        if p_com(hi) < alvo:
            return None
        lo = 0.0
        for _ in range(passos):
            m = (lo + hi) / 2
            if p_com(m) >= alvo:
                hi = m
            else:
                lo = m
        return hi

    def motivo(self, jog, adv, tatica, n=None):
        """Atributo decisivo = o que precisa de MENOS a mais para a luta ficar facil (design secao 7).
        Se nenhum chega la, o de maior chance com +Delta. Empate: resistencia, forca, agilidade."""
        rs = self.reason
        faltas = []
        for i in (2, 0, 1):
            faltas.append((self.falta_para(jog, adv, tatica, i, n), i))
        com = [(f, i) for f, i in faltas if f is not None]
        if com:
            f, i = min(com, key=lambda x: x[0])
            return ATTR[i], f, faltas
        tot = jog[0] + jog[1] + jog[2]
        delta = max(rs["delta_min"], rs["delta_share"] * tot)
        ganhos = []
        for i in (2, 0, 1):
            x = list(jog); x[i] += delta
            ganhos.append((self.chance(tuple(x), adv, tatica, n), i))
        return ATTR[max(ganhos, key=lambda g: g[0])[1]], None, faltas


# ---------------------------------------------------------------- carreira
class Carreira:
    def __init__(self, regras, treino, geradores, shop, career, cps, estrategia, semente,
                 limiar="equilibrado", dica=None, dt=0.1, t_max=60 * 60, olhar=None, paciencia=None, cauteloso_contra=None):
        self.R = regras
        self.cps = cps
        self.estr = estrategia
        self.limiar = limiar
        self.dica = dica
        self.dt = dt
        self.t_max = t_max
        self.rng = random.Random(semente)
        clk = treino["click"]
        self.media_crit = 1 + clk["crit_chance"] * (clk["crit_multiplier"] - 1)
        self.base = clk["base_training"]
        self.ups = {a["id"]: a["upgrades"] for a in treino["apparatus"]}
        self.gens = geradores["generators"]
        self.pgens = shop["paid_generators"]
        self.luvas = shop["gloves"]["levels"]
        self.career = career
        self.nivel = {a: 0 for a in APAR}
        self.qtd = {g["id"]: 0 for g in self.gens}
        self.pqtd = {g["id"]: 0 for g in self.pgens}
        self.luva = 0
        self.saldo = 0.0
        self.attr = [0.0, 0.0, 0.0]
        self.dinheiro = 0.0
        self.fama = 0
        self.vitorias = 0
        self.cinturao = False
        self.t = 0.0
        self.tempo_foco = {a: 0.0 for a in APAR}
        self.eventos = []
        self.fim = None
        self.ult_check_tot = 0.0
        self.ult_check_t = -999
        self.ult_foco_t = -999
        self.foco_atual = "punching_bag"
        self.lutas = []
        self.paciencia = paciencia  # segundos parado em 'perigoso' antes de lutar assim mesmo (None = nunca)
        self.t_ult_vit = 0.0
        self.cauteloso_contra = cauteloso_contra  # id do adversario que so enfrenta em 'facil' (aprendeu a licao)
        # de quantos em quantos segundos o jogador olha a previa (design 9.1)
        self.olhar = olhar if olhar is not None else float(os.environ.get("SIM_OLHAR", "30"))

    # --- economia
    def mult_ap(self, a):
        m = 1.0
        for i in range(self.nivel[a]):
            m *= self.ups[a][i]["multiplier"]
        return m

    def mult_luva(self):
        m = 1.0
        for i in range(self.luva):
            m *= self.luvas[i]["click_multiplier"]
        return m

    def clique_s(self, a):
        return self.cps * self.base * self.mult_ap(a) * self.mult_luva() * self.media_crit

    def passivo(self):
        p = sum(g["production"] * self.qtd[g["id"]] for g in self.gens)
        p += sum(g["production"] * self.pqtd[g["id"]] for g in self.pgens)
        return p

    def pesos(self):
        if self.estr in ("saco", "corda", "esteira"):
            alvo = {"saco": "punching_bag", "corda": "jump_rope", "esteira": "treadmill"}[self.estr]
            return {a: (1.0 if a == alvo else 0.0) for a in APAR}
        tot = sum(self.tempo_foco.values()) + 60.0
        return {a: (self.tempo_foco[a] + 20.0) / tot for a in APAR}

    def clique_medio(self):
        w = self.pesos()
        return sum(self.clique_s(a) * w[a] for a in APAR)

    def comprar_garagem(self):
        while True:
            w = self.pesos()
            renda = self.clique_medio() + self.passivo()
            melhor = None
            for g in self.gens:
                c = f2.custo_gerador(g, self.qtd[g["id"]])
                ganho = float(g["production"])
                nota = max(0.0, c - self.saldo) / renda + c / ganho
                if melhor is None or nota < melhor[0]:
                    melhor = (nota, "gen", g["id"], c)
            for a in APAR:
                if w[a] < 0.05 or self.nivel[a] >= len(self.ups[a]):
                    continue
                u = self.ups[a][self.nivel[a]]
                ganho = self.clique_s(a) * (u["multiplier"] - 1) * w[a]
                c = float(u["cost"])
                nota = max(0.0, c - self.saldo) / renda + c / ganho
                if nota < melhor[0]:
                    melhor = (nota, "up", a, c)
            _, tipo, id_, c = melhor
            if self.saldo + 1e-9 < c:
                return
            self.saldo -= c
            if tipo == "gen":
                self.qtd[id_] += 1
            else:
                self.nivel[id_] += 1
                self.eventos.append((self.t, "melhoria " + id_))

    def comprar_loja(self):
        while True:
            ops = []
            for g in self.pgens:
                c = f2.custo_gerador(g, self.pqtd[g["id"]])
                ops.append((g["production"] / c, "pgen", g["id"], c))
            if self.luva < len(self.luvas):
                L = self.luvas[self.luva]
                ganho = self.clique_medio() * (L["click_multiplier"] - 1)
                ops.append((ganho / L["cost"], "luva", L["id"], float(L["cost"])))
            if not ops:
                return
            ops.sort(reverse=True)
            _, tipo, id_, c = ops[0]
            if self.dinheiro + 1e-9 < c:
                return
            self.dinheiro -= c
            if tipo == "pgen":
                self.pqtd[id_] += 1
                if self.pqtd[id_] == 1:
                    self.eventos.append((self.t, "1o " + id_))
            else:
                self.luva += 1
                self.eventos.append((self.t, id_))

    # --- foco
    def foco(self):
        e = self.estr
        if e == "saco":
            return "punching_bag"
        if e == "corda":
            return "jump_rope"
        if e == "esteira":
            return "treadmill"
        if e == "rodizio":
            return APAR[int(self.t // 60) % 3]
        if e == "dica":
            par = ["punching_bag", APAR[ATTR.index(self.dica)]]
            if par[1] == par[0]:
                par[1] = "treadmill"
            return par[int(self.t // 60) % 2]
        if e == "bom":
            if self.t - self.ult_foco_t >= 30:
                self.ult_foco_t = self.t
                self.foco_atual = self.foco_bom()
            return self.foco_atual
        raise ValueError(e)

    def foco_bom(self):
        """Treina o atributo que mais sobe a chance contra o proximo adversario."""
        if self.vitorias >= len(self.R.opp):
            return self.foco_atual
        adv = self.adv()
        tot = sum(self.attr)
        delta = max(50.0, 0.15 * tot)
        res = []
        for i in range(3):
            x = list(self.attr); x[i] += delta
            _, ps = self.R.melhor_tatica(tuple(x), adv, 40)
            res.append((max(ps.values()), -self.attr[i], i))
        res.sort(reverse=True)
        if res[0][0] - res[-1][0] < 0.02:  # nada muda: equilibra
            i = min(range(3), key=lambda k: self.attr[k])
        else:
            i = res[0][2]
        return APAR[i]

    def adv(self):
        o = self.R.opp[self.vitorias]
        return (o["strength"], o["agility"], o["endurance"])

    # --- luta
    def talvez_lutar(self):
        if self.vitorias >= len(self.R.opp) or self.fim:
            return
        tot = sum(self.attr)
        if self.t - self.ult_check_t < self.olhar:
            return
        self.ult_check_tot, self.ult_check_t = tot, self.t
        jog = tuple(self.attr)
        adv = self.adv()
        lim = self.R.risk["easy_min"] if self.limiar == "facil" else self.R.risk["even_min"]
        if self.cauteloso_contra == self.R.opp[self.vitorias]["id"]:
            lim = self.R.risk["easy_min"]
        if not any(self.R.passa(jog, adv, t, 100, lim) for t in self.R.tac_ids):
            if self.paciencia is None or self.t - self.t_ult_vit < self.paciencia:
                return
        tat, ps = self.R.melhor_tatica(jog, adv, 100)
        p = ps[tat]
        r = self.R.lutar(jog, adv, tat, self.rng.randrange(1 << 31))
        dur = 5.0 + self.R.tela(r)  # 5 s lendo a previa
        o = self.R.opp[self.vitorias]
        self.lutas.append({"t": self.t, "opp": o["id"], "p": p, "tat": tat, "win": r["win"],
                           "attr": jog, "tela": self.R.tela(r)})
        # passivo continua durante previa e luta; clique para
        g = self.passivo() * dur
        self.saldo += g
        self.attr[APAR.index(self.foco())] += g
        self.t += dur
        if r["win"]:
            self.vitorias += 1
            self.t_ult_vit = self.t
            self.dinheiro += o["prize_money"]
            self.fama += o["prize_fame"]
            self.eventos.append((self.t, "VENCE " + o["id"]))
            if o.get("belt"):
                self.cinturao = True
                self.fim = ("cinturao", self.t)
        else:
            self.fim = ("derrota", self.t, o["id"], jog, tat)
            self.eventos.append((self.t, "PERDE " + o["id"]))

    def rodar(self):
        dt = self.dt
        while self.t < self.t_max and not self.fim:
            self.comprar_garagem()
            self.comprar_loja()
            a = self.foco()
            g = (self.clique_s(a) + self.passivo()) * dt
            self.saldo += g
            self.attr[APAR.index(a)] += g
            self.tempo_foco[a] += dt
            self.t += dt
            self.talvez_lutar()
        return self

    def pote(self):
        c = self.career
        return math.floor(self.fama * c["legacy_per_fame"]) + (c["belt_legacy_bonus"] if self.cinturao else 0)


def legado(career, pote, cinturao, saida):
    if saida == "derrota":
        return math.floor(pote * career["defeat_share"])
    bonus = math.floor(pote * career["retire_belt_bonus_share"]) if cinturao else 0
    return math.floor(pote * career["retire_share"]) + bonus


# ---------------------------------------------------------------- relatorios
def carregar():
    fights, a = ler("fights.json", PADRAO_FIGHTS)
    opps, b = ler("opponents.json", PADRAO_OPPONENTS)
    shop, c = ler("shop.json", PADRAO_SHOP)
    career, d = ler("career.json", PADRAO_CAREER)
    treino, e = f2.ler("training.json", f2.PADRAO_TREINO)
    gens, g = f2.ler("generators.json", f2.PADRAO_GERADORES)
    print("Fontes: %s" % ", ".join([a, b, c, d, e, g]))
    return Regras(fights, opps), treino, gens, shop, career


def k(x):
    if x is None:
        return "-"
    return f2.fmt(x)


def cruzamento(R, adv, w, tat, alvo, n=120):
    def p(t):
        jog = tuple(t * x for x in w)
        if tat:
            return R.chance(jog, adv, tat, n)
        return max(R.melhor_tatica(jog, adv, n)[1].values())
    lo, hi = 50.0, 5e6
    if p(hi) < alvo:
        return None
    if p(lo) >= alvo:
        return lo
    for _ in range(16):
        m = (lo * hi) ** 0.5
        if p(m) >= alvo:
            hi = m
        else:
            lo = m
    return hi


PERFIS = [("so Forca", (1, 0, 0)), ("so Agilidade", (0, 1, 0)), ("so Resistencia", (0, 0, 1)),
          ("equilibrado 1/3", (1 / 3, 1 / 3, 1 / 3)), ("Forca+Resist.", (.5, 0, .5)),
          ("Forca+Agil.", (.5, .5, 0)), ("Agil.+Resist.", (0, .5, .5))]


def sec_limiares(R):
    print("\n## Treino total (soma dos 3 atributos) para cada perfil chegar a 'equilibrado' (>=40%) / 'facil' (>=90%), melhor tatica")
    print("| perfil | " + " | ".join(o["id"] for o in R.opp) + " |")
    print("|---|" + "---|" * len(R.opp))
    for nome, w in PERFIS:
        cel = []
        for o in R.opp:
            adv = (o["strength"], o["agility"], o["endurance"])
            cel.append("%s / %s" % (k(cruzamento(R, adv, w, None, 0.4)), k(cruzamento(R, adv, w, None, 0.9))))
        print("| %s | %s |" % (nome, " | ".join(cel)))


def sec_taticas(R):
    print("\n## Melhor tatica por adversario (treino total em que o perfil equilibrado chega a 'facil' com cada tatica; menor = melhor)")
    print("| adversario | " + " | ".join(R.tac_ids) + " | melhor |")
    print("|---|" + "---|" * (len(R.tac_ids) + 1))
    w = (1 / 3, 1 / 3, 1 / 3)
    for o in R.opp:
        adv = (o["strength"], o["agility"], o["endurance"])
        vals = {t: cruzamento(R, adv, w, t, 0.9) for t in R.tac_ids}
        b = min(R.tac_ids, key=lambda t: vals[t] if vals[t] else 1e99)
        print("| %s | %s | **%s** |" % (o["id"], " | ".join(k(vals[t]) for t in R.tac_ids), b))
    print("\n## Chance de vitoria por tatica, perfil equilibrado, no treino total em que a melhor tatica da 65%")
    print("| adversario | treino total | " + " | ".join(R.tac_ids) + " |")
    print("|---|---|" + "---|" * len(R.tac_ids))
    for o in R.opp:
        adv = (o["strength"], o["agility"], o["endurance"])
        t65 = cruzamento(R, adv, w, None, 0.65, 200)
        jog = tuple(t65 * x for x in w)
        _, ps = R.melhor_tatica(jog, adv, 400)
        print("| %s | %s | %s |" % (o["id"], k(t65), " | ".join("%d%%" % round(100 * ps[t]) for t in R.tac_ids)))


def estados_variados(R, rng, n):
    """Estados de jogador variados em volta de cada adversario."""
    out = []
    for _ in range(n):
        o = R.opp[rng.randrange(len(R.opp))]
        adv = (o["strength"], o["agility"], o["endurance"])
        tadv = sum(adv)
        tot = tadv * math.exp(rng.uniform(math.log(0.15), math.log(6)))
        w = [rng.random() ** 2 for _ in range(3)]
        s = sum(w)
        jog = tuple(tot * x / s for x in w)
        tat = R.tac_ids[rng.randrange(len(R.tac_ids))]
        out.append((jog, adv, tat))
    return out


def sec_risco(R):
    print("\n## Calibracao do risco (criterio 3): rotulo pela previa (sementes 1..%d), resultado com sementes novas"
          % R.risk["samples"])
    rng = random.Random(2026)
    alvo = 500
    caixas = {"facil": [], "equilibrado": [], "perigoso": []}
    tent = 0
    while min(len(v) for v in caixas.values()) < alvo and tent < 60000:
        tent += 1
        jog, adv, tat = estados_variados(R, rng, 1)[0]
        p = R.chance(jog, adv, tat)
        lab = R.rotulo(p)
        if len(caixas[lab]) >= alvo:
            continue
        r = R.lutar(jog, adv, tat, rng.randrange(10 ** 6, 2 ** 31))
        caixas[lab].append((p, r["win"]))
    print("| rotulo | lutas | vitorias | taxa real | meta | chance media prevista |")
    print("|---|---|---|---|---|---|")
    metas = {"facil": ">= 85%", "equilibrado": "40% a 85%", "perigoso": "< 40%"}
    for lab, v in caixas.items():
        w = sum(1 for _, x in v if x)
        print("| %s | %d | %d | %.1f%% | %s | %.1f%% |" % (lab, len(v), w, 100 * w / max(1, len(v)), metas[lab],
                                                       100 * sum(p for p, _ in v) / max(1, len(v))))
    # pior caso: so estados no limite de cada faixa
    print("\nPior caso (estados escolhidos so na beira das faixas):")
    beira = {"facil (previa 90-93%)": (0.90, 0.93), "equilibrado baixo (40-45%)": (0.40, 0.45),
             "equilibrado alto (85-90%)": (0.85, 0.90), "perigoso alto (35-40%)": (0.35, 0.40)}
    res = {b: [0, 0] for b in beira}
    tent = 0
    while min(v[1] for v in res.values()) < 300 and tent < 200000:
        tent += 1
        jog, adv, tat = estados_variados(R, rng, 1)[0]
        p = R.chance(jog, adv, tat)
        for b, (lo, hi) in beira.items():
            if lo <= p < hi and res[b][1] < 300:
                r = R.lutar(jog, adv, tat, rng.randrange(10 ** 6, 2 ** 31))
                res[b][0] += r["win"]; res[b][1] += 1
    print("| faixa da previa | lutas | taxa real |")
    print("|---|---|---|")
    for b, (w, n) in res.items():
        print("| %s | %d | %.1f%% |" % (b, n, 100 * w / max(1, n)))


def sec_duracao(R):
    print("\n## Duracao (criterio 5): 10.000 lutas de estados variados")
    rng = random.Random(77)
    ts, ko, maxev = [], 0, 0
    for jog, adv, tat in estados_variados(R, rng, 10000):
        r = R.lutar(jog, adv, tat, rng.randrange(2 ** 31))
        ts.append(R.tela(r))
        ko += r["ko"]
    ts.sort()
    print("| lutas | tela min | p10 | mediana | p90 | tela max | terminam por K.O. | no limite de tempo |")
    print("|---|---|---|---|---|---|---|---|")
    n = len(ts)
    print("| %d | %.1f s | %.1f s | %.1f s | %.1f s | %.1f s | %d%% | %d%% |" % (
        n, ts[0], ts[n // 10], ts[n // 2], ts[9 * n // 10], ts[-1], round(100 * ko / n), round(100 * (n - ko) / n)))


def sec_foco(R):
    print("\n## Criterio 9: mesmo treino total, 'so saco' x 'equilibrado' (melhor tatica de cada um)")
    print("| adversario | treino total | so Forca | equilibrado 1/3 |")
    print("|---|---|---|---|")
    for o in R.opp:
        adv = (o["strength"], o["agility"], o["endurance"])
        t = cruzamento(R, adv, (1 / 3, 1 / 3, 1 / 3), None, 0.9)
        if t is None:
            continue
        ps = max(R.melhor_tatica((t, 0, 0), adv, 300)[1].values())
        pb = max(R.melhor_tatica((t / 3, t / 3, t / 3), adv, 300)[1].values())
        print("| %s | %s | %d%% | %d%% |" % (o["id"], k(t), round(100 * ps), round(100 * pb)))


def resumo_carreiras(cs):
    fins = {"derrota": [], "cinturao": [], "sem_fim": 0}
    vence1 = []
    perde_para = {}
    for c in cs:
        for l in c.lutas:
            if l["win"] and l["opp"] == c.R.opp[0]["id"]:
                vence1.append(l["t"])
                break
        if c.fim is None:
            fins["sem_fim"] += 1
        elif c.fim[0] == "derrota":
            fins["derrota"].append(c.fim[1])
            perde_para[c.fim[2]] = perde_para.get(c.fim[2], 0) + 1
        else:
            fins["cinturao"].append(c.fim[1])
    return fins, vence1, perde_para


def med(v):
    if not v:
        return "-"
    v = sorted(v)
    return f2.mmss(v[len(v) // 2])


def faixa(v):
    if not v:
        return "-"
    v = sorted(v)
    return "%s-%s" % (f2.mmss(v[len(v) // 10]), f2.mmss(v[(9 * len(v)) // 10]))


def sec_carreiras(R, treino, gens, shop, career, n=int(os.environ.get("SIM_N", "40"))):
    print("\n## Carreiras simuladas (%d por linha; luta com a melhor tatica da previa)" % n)
    print("| jogador | cliques/s | luta quando | 1a vitoria (mediana; p10-p90) | fim por derrota | derrota: mediana (p10-p90) | % derrota em 10-15 min | perdeu para | cinturao | cinturao: mediana (p10-p90) | sem fim em 60 min |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    casos = [("saco", c, "equilibrado") for c in (3, 4, 5, 8)]
    casos += [("saco", c, "equilibrado", 300) for c in (3, 4, 5, 8)]
    casos += [("corda", 5, "equilibrado"), ("esteira", 5, "equilibrado"), ("rodizio", 5, "equilibrado"),
              ("rodizio", 5, "facil")]
    casos += [("bom", c, "facil") for c in (3, 4, 5, 8)]
    casos += [("bom", 5, "equilibrado")]
    exemplos = {}
    for caso in casos:
        estr, cps, lim = caso[:3]
        pac = caso[3] if len(caso) > 3 else None
        cs = [Carreira(R, treino, gens, shop, career, cps, estr, 1000 + s, lim, paciencia=pac).rodar() for s in range(n)]
        exemplos[caso] = cs[0]
        fins, v1, pp = resumo_carreiras(cs)
        d = fins["derrota"]
        em = sum(1 for x in d if 600 <= x <= 900)
        pps = ", ".join("%s %d" % (o.replace("opp_", ""), q) for o, q in sorted(pp.items()))
        print("| %s%s | %d | %s | %s (%s) | %d%% | %s (%s) | %d%% | %s | %d%% | %s (%s) | %d%% |" % (
            estr, " (impaciente %d min)" % (pac // 60) if pac else "", cps, lim, med(v1), faixa(v1), round(100 * len(d) / n), med(d), faixa(d),
            round(100 * em / n), pps or "-", round(100 * len(fins["cinturao"]) / n), med(fins["cinturao"]),
            faixa(fins["cinturao"]), round(100 * fins["sem_fim"] / n)))
    return exemplos


def foto(c, R):
    print("Marcos: " + "; ".join("%s %s" % (f2.mmss(t), e) for t, e in c.eventos))
    for l in c.lutas:
        print("  luta %s %s: previa %d%% (%s), tatica %s, atributos F/A/R %s/%s/%s -> %s, %.1f s de tela" % (
            f2.mmss(l["t"]), l["opp"], round(100 * l["p"]), R.rotulo(l["p"]), l["tat"],
            k(l["attr"][0]), k(l["attr"][1]), k(l["attr"][2]), "VENCEU" if l["win"] else "PERDEU", l["tela"]))


def curva(R, treino, gens, shop, career, estr, cps, lim, semente=1000):
    c = Carreira(R, treino, gens, shop, career, cps, estr, semente, lim)
    marcos = [60, 120, 180, 300, 480, 600, 900, 1200, 1500, 1800, 2400]
    linhas = []
    dt = c.dt
    while c.t < c.t_max and not c.fim:
        c.comprar_garagem(); c.comprar_loja()
        a = c.foco()
        g = (c.clique_s(a) + c.passivo()) * dt
        c.saldo += g; c.attr[APAR.index(a)] += g; c.tempo_foco[a] += dt
        c.t += dt
        while marcos and c.t >= marcos[0]:
            m = marcos.pop(0)
            linhas.append((m, c.clique_medio(), c.passivo(), sum(c.attr), tuple(c.attr), c.dinheiro, c.vitorias,
                           dict(c.pqtd), c.luva))
        c.talvez_lutar()
    print("\n### Curva: %s, %d cliques/s, luta em '%s' (semente %d)" % (estr, cps, lim, semente))
    print("| min | clique/s | passivo/s | treino total | F / A / R | $ em caixa | vitorias | Prof. Nelson | luva |")
    print("|---|---|---|---|---|---|---|---|---|")
    for m, cl, pa, tot, at, din, v, pq, lv in linhas:
        print("| %d | %s | %s | %s | %s / %s / %s | %d | %d | %d | %d |" % (
            m // 60, k(cl), k(pa), k(tot), k(at[0]), k(at[1]), k(at[2]), din, v, list(pq.values())[0], lv))
    foto(c, R)


def sec_motivo(R, treino, gens, shop, career, n=20):
    print("\n## Motivo da derrota (criterio 14): %d derrotas de estados variados (previa 20-90%%)" % n)
    print("Decisivo pelo jogo (200 sementes fixas) x conferencia (1000 sementes novas). Faltam = R / F / A para 'facil'.")
    print("| adversario | F / A / R | tatica | previa | decisivo (jogo) | decisivo (conferencia) | faltam (jogo) | faltam (conferencia) |")
    print("|---|---|---|---|---|---|---|---|")
    rng = random.Random(31)
    ok = vistos = 0
    while vistos < n:
        jog, adv, tat = estados_variados(R, rng, 1)[0]
        p = R.chance(jog, adv, tat)
        if not (0.2 <= p < 0.9):
            continue
        if R.lutar(jog, adv, tat, rng.randrange(10 ** 6, 2 ** 31))["win"]:
            continue
        vistos += 1
        a1, falta, faltas = R.motivo(jog, adv, tat)
        # conferencia: 1000 sementes novas, mesma regra
        def chance_nova(x):
            return sum(R.lutar(tuple(x), adv, tat, 10 ** 6 + q)["win"] for q in range(1000)) / 1000
        f2s = []
        tot = sum(jog)
        for i in (2, 0, 1):
            hi = R.reason["search_max_share"] * tot + 1000
            x = list(jog); x[i] += hi
            if chance_nova(x) < 0.9:
                f2s.append((None, i)); continue
            lo = 0.0
            for _ in range(10):
                m = (lo + hi) / 2
                x = list(jog); x[i] += m
                if chance_nova(x) >= 0.9:
                    hi = m
                else:
                    lo = m
            f2s.append((hi, i))
        com = [(f, i) for f, i in f2s if f is not None]
        a2 = ATTR[min(com, key=lambda x: x[0])[1]] if com else "-"
        ok += a1 == a2
        oid = next(o["id"] for o in R.opp if (o["strength"], o["agility"], o["endurance"]) == adv)
        print("| %s | %s / %s / %s | %s | %d%% | %s | %s | %s | %s |" % (
            oid, k(jog[0]), k(jog[1]), k(jog[2]), tat, round(100 * p), a1, a2,
            " / ".join(k(f) for f, _ in faltas), " / ".join(k(f) for f, _ in f2s)))
    print("Concordancia: %d de %d" % (ok, vistos))


def sec_dica(R, treino, gens, shop, career, n=30):
    print("\n## Criterio 24: 2a carreira seguindo a dica da 1a (jogador tipico, 5 cliques/s)")
    print("| 1a carreira perdeu para | dica | 2a carreira: venceu esse adversario | 2a carreira: tempo ate vence-lo (mediana) |")
    print("|---|---|---|---|")
    agrup = {}
    for s in range(n):
        c1 = Carreira(R, treino, gens, shop, career, 5, "saco", 7000 + s, "equilibrado").rodar()
        if not c1.fim or c1.fim[0] != "derrota":
            continue
        _, t, opp, jog, tat = c1.fim
        o = next(x for x in R.opp if x["id"] == opp)
        attr, _, _ = R.motivo(jog, (o["strength"], o["agility"], o["endurance"]), tat, 100)
        c2 = Carreira(R, treino, gens, shop, career, 5, "dica", 8000 + s, "equilibrado", dica=attr,
                      cauteloso_contra=opp).rodar()
        venceu = [l for l in c2.lutas if l["opp"] == opp and l["win"]]
        agrup.setdefault((opp, attr), []).append(venceu[0]["t"] if venceu else None)
    for (opp, attr), v in sorted(agrup.items()):
        ok = [x for x in v if x is not None]
        print("| %s | %s | %d de %d | %s |" % (opp, attr, len(ok), len(v), med(ok)))


# ---------------------------------------------------------------- correcoes pos-QA (B2, B3, B4)
# Parametros novos de data/fights.json "reason" (design secao 16). Padrao aqui se o JSON ainda nao tiver.
PADRAO_POS_QA = {
    "search_opp_share": 4.0,        # B2: teto da busca tambem >= 4 x total do adversario
    "luck_min": 0.90,               # B3: chance da tatica usada >= isto -> derrota "por azar"
    "far_min_ratio": 2.0,           # B2 fallback: "ELE TINHA {n}X O SEU TREINO" so se a razao >= 2
    "stat_life_min_pct": 10,        # B4: "TIROU {n}% DA SUA VIDA" so com n >= 10
    "stat_stronger_min_ratio": 1.2,  # B4: "BATIA {n}% MAIS FORTE" so com razao >= 1.2 (n >= 20)
    "stat_stronger_x_ratio": 2.0,   # B4: razao >= 2 -> "CADA SOCO DELE VALIA {n} DOS SEUS"
    "stat_stronger_cap_ratio": 10.0,  # B4: razao >= 10 -> "... MAIS DE {n} DOS SEUS" (n = 10)
    "stat_dodge_min_pct": 20,       # B4: "ESQUIVOU {n}%" so com n >= 20 ...
    "stat_dodge_min_attacks": 3,    # ... e pelo menos 3 ataques normais seus
    "stat_crits_min": 2,            # B4: "ACERTOU {n} CRITICOS" so com n >= 2 e mais que os seus
}

ORDEM_STAT = {
    "endurance": ("life_taken", "stronger", "crits", "dodged"),
    "strength": ("stronger", "life_taken", "crits", "dodged"),
    "agility": ("crits", "dodged", "life_taken", "stronger"),
    "luck": ("crits", "dodged"),
}


def rp(R, campo):
    return R.reason.get(campo, PADRAO_POS_QA[campo])


def falta_para_v2(R, jog, adv, tatica, i):
    """Igual a falta_para, com teto hi = max(16 x T + 1000, 4 x total do adversario) (B2)."""
    rs = R.reason
    n = R.risk["samples"]
    alvo = rs["target"]
    tot = sum(jog)
    hi = max(rs["search_max_share"] * tot + 1000, rp(R, "search_opp_share") * sum(adv))
    def ok(extra):
        x = list(jog); x[i] += extra
        return R.passa(tuple(x), adv, tatica, n, alvo)
    if not ok(hi):
        return None
    lo = 0.0
    for _ in range(rs["search_steps"]):
        m = (lo + hi) / 2
        if ok(m):
            hi = m
        else:
            lo = m
    return hi


def stat_valida(R, kind, r, jog, adv, tatica):
    """Devolve (kind_final, n, k) se a estatistica e valida para esta luta, senao None (B4)."""
    c = r["cont"]
    vmax = r["vmax"]
    if kind == "life_taken":
        n = round(100 * min(c["dano"][1], vmax[0]) / vmax[0])
        return ("life_taken", n, c["acertos"][1]) if n >= rp(R, "stat_life_min_pct") else None
    if kind == "stronger":
        ef = (R.efetivos(jog), R.efetivos(adv))
        tac = (R.tac[tatica], R.NEUTRA)
        d_dele = c["dano"][1] / c["acertos"][1] if c["acertos"][1] else R.golpe(ef[1], ef[0], tac[1], tac[0])[0]
        d_meu = c["dano"][0] / c["acertos"][0] if c["acertos"][0] else R.golpe(ef[0], ef[1], tac[0], tac[1])[0]
        razao = (d_dele / vmax[0]) / (d_meu / vmax[1])
        if razao < rp(R, "stat_stronger_min_ratio"):
            return None
        cap = rp(R, "stat_stronger_cap_ratio")
        if razao >= cap:
            return ("stronger_cap", int(cap), 0)
        if razao >= rp(R, "stat_stronger_x_ratio"):
            return ("stronger_x", int(math.floor(razao)), 0)
        return ("stronger", round(100 * (razao - 1)), 0)
    if kind == "crits":
        n, kk = c["crits"][1], c["crits"][0]
        return ("crits", n, kk) if n >= rp(R, "stat_crits_min") and n > kk else None
    if kind == "dodged":
        atq = c["atq"][0] - c["contras"][0]
        if atq < rp(R, "stat_dodge_min_attacks"):
            return None
        n = round(100 * c["esquivas"][1] / atq)
        return ("dodged", n, 0) if n >= rp(R, "stat_dodge_min_pct") else None
    return None


def explicar(R, jog, adv, tatica, semente):
    """Motivo completo da derrota com as regras pos-QA (design secao 16). Devolve dict."""
    r = R.lutar(jog, adv, tatica, semente)
    p = R.chance(jog, adv, tatica)
    out = {"p": p, "ko": r["ko"]}
    if p >= rp(R, "luck_min"):
        out.update(kind="luck", attribute="", faltaram=None)
    else:
        faltas = [(falta_para_v2(R, jog, adv, tatica, i), i) for i in (2, 0, 1)]
        com = [(f, i) for f, i in faltas if f is not None]
        if com:
            f, i = min(com, key=lambda x: x[0])
            out.update(kind="missing", attribute=ATTR[i], faltaram=f)
        else:
            a, _, _ = R.motivo(jog, adv, tatica)  # Delta (regra antiga) so para escolher o atributo
            razao = sum(adv) / max(1.0, sum(jog))
            out.update(kind="far" if razao >= rp(R, "far_min_ratio") else "far_plain", attribute=a,
                       faltaram=None, far_n=razao)
    chave = "luck" if out["kind"] == "luck" else out["attribute"]
    st = None
    for kd in ORDEM_STAT[chave]:
        st = stat_valida(R, kd, r, jog, adv, tatica)
        if st:
            break
    if not st:
        if chave == "luck":
            n = round(100 * (1 - p))
            st = ("luck_odds", n, 0) if n >= 1 else ("luck_rare", 0, 0)
        elif r["ko"]:
            st = ("life_taken", 100, r["cont"]["acertos"][1])  # nunca acontece: K.O. sempre e 100%
        else:
            st = ("points", round(100 * r["pct"][0]), round(100 * r["pct"][1]))
    out["stat"] = st
    return out


def frase(e):
    k_, n, kk = e["stat"]
    stat = {"life_taken": "ELE TIROU %d%% DA SUA VIDA EM %d GOLPES" % (n, kk),
            "stronger": "ELE BATIA %d%% MAIS FORTE" % n,
            "stronger_x": "CADA SOCO DELE VALIA %d DOS SEUS" % n,
            "stronger_cap": "CADA SOCO DELE VALIA MAIS DE %d DOS SEUS" % n,
            "crits": "ELE ACERTOU %d CRITICOS. VOCE, %d" % (n, kk),
            "dodged": "ELE ESQUIVOU %d%% DOS SEUS GOLPES" % n,
            "points": "NO GONGO: VOCE COM %d%% DA VIDA, ELE COM %d%%" % (n, kk),
            "luck_odds": "ISSO ACONTECE EM %d DE CADA 100 LUTAS" % n,
            "luck_rare": "ISSO QUASE NUNCA ACONTECE"}[k_]
    if e["kind"] == "luck":
        prin = "ERA PRA SER SUA. DEU AZAR."
    elif e["kind"] == "missing":
        prin = "FALTARAM %s DE %s" % (k(e["faltaram"]), e["attribute"].upper())
    elif e["kind"] == "far":
        prin = "ELE TINHA %.0fX O SEU TREINO" % e["far_n"]
    else:
        prin = "TREINE MUITO MAIS ANTES DE ENCARAR ELE"
    return prin + " / " + stat


def derrotas_reais(R, treino, gens, shop, career, n_carr):
    """Derrotas que a simulacao produz de verdade: carreiras de varios perfis + lutas cedo demais + estados variados."""
    out = []  # (origem, jog, adv, tat, semente)
    casos = [("saco", 5, "equilibrado", None), ("saco", 4, "equilibrado", 300), ("saco", 8, "equilibrado", 300),
             ("corda", 5, "equilibrado", None), ("rodizio", 5, "equilibrado", None), ("bom", 5, "equilibrado", None),
             ("bom", 5, "facil", None), ("esteira", 5, "equilibrado", None)]
    for estr, cps, lim, pac in casos:
        for s in range(n_carr):
            c = Carreira(R, treino, gens, shop, career, cps, estr, 5000 + s, lim, paciencia=pac, t_max=45 * 60)
            # a carreira guarda so o resultado; refaz a luta final com a mesma sequencia de sementes
            c.rodar()
            if c.fim and c.fim[0] == "derrota":
                _, _, opp, jog, tat = c.fim
                o = next(x for x in R.opp if x["id"] == opp)
                adv = (o["strength"], o["agility"], o["endurance"])
                # semente que perde: procura a 1a que perde (a da carreira nao foi guardada)
                sem = next(q for q in range(10 ** 6, 10 ** 6 + 100000) if not R.lutar(jog, adv, tat, q)["win"])
                out.append(("carreira %s %d/s%s" % (estr, cps, " impaciente" if pac else ""), jog, adv, tat, sem))
    # cedo demais: so-saco aos 30 s a 3 min contra cada adversario (o caso do B2)
    for o in R.opp:
        adv = (o["strength"], o["agility"], o["endurance"])
        for T in (50, 150, 500, 1500, 3000, 8000):
            for w in ((1, 0, 0), (0, 1, 0), (1 / 3, 1 / 3, 1 / 3)):
                jog = tuple(T * x for x in w)
                tat = R.melhor_tatica(jog, adv, 50)[0]
                sem = next((q for q in range(10 ** 6, 10 ** 6 + 2000) if not R.lutar(jog, adv, tat, q)["win"]), None)
                if sem is not None:
                    out.append(("cedo demais", jog, adv, tat, sem))
    # estados variados (todos os rotulos), derrota com semente nova
    rng = random.Random(4242)
    vistos = 0
    while vistos < 60:
        jog, adv, tat = estados_variados(R, rng, 1)[0]
        sem = rng.randrange(10 ** 6, 2 ** 31)
        if R.lutar(jog, adv, tat, sem)["win"]:
            continue
        vistos += 1
        out.append(("estado variado", jog, adv, tat, sem))
    return out


def derrotas_faceis(R, n=40):
    """Derrotas raras em lutas que a previa chamava de FACIL (o caso do B3)."""
    rng = random.Random(99)
    out = []
    tent = 0
    while len(out) < n and tent < 400000:
        tent += 1
        jog, adv, tat = estados_variados(R, rng, 1)[0]
        p = R.chance(jog, adv, tat, 60)
        if p < 0.85:
            continue
        for q in range(10 ** 6, 10 ** 6 + 400):
            if not R.lutar(jog, adv, tat, q)["win"]:
                out.append(("previa alta", jog, adv, tat, q))
                break
    return out


def sec_explica(R, treino, gens, shop, career):
    n_carr = int(os.environ.get("SIM_N_EXPLICA", "12"))
    print("\n## Correcoes pos-QA: motivo da derrota em derrotas reais (B2, B3, B4)")
    casos = derrotas_reais(R, treino, gens, shop, career, n_carr) + derrotas_faceis(R)
    cont = {}
    probs = []
    exemplos = {}
    por_kind = {}
    antes_sem = 0  # derrotas em que a regra antiga (teto 16 x T + 1000) nao achava o FALTARAM
    for origem, jog, adv, tat, sem in casos:
        e = explicar(R, jog, adv, tat, sem)
        if e["kind"] == "missing" and e["faltaram"] > R.reason["search_max_share"] * sum(jog) + 1000:
            antes_sem += 1
        kd, n, kk = e["stat"]
        chave = (origem, e["kind"])
        cont[chave] = cont.get(chave, 0) + 1
        por_kind[kd] = por_kind.get(kd, 0) + 1
        exemplos.setdefault(kd, (origem, e))
        exemplos.setdefault("motivo_" + e["kind"], (origem, e))
        # verificacoes
        if e["kind"] == "luck" and e["p"] < rp(R, "luck_min"):
            probs.append(("azar sem previa facil", origem, e))
        if e["kind"] != "luck" and e["p"] >= rp(R, "luck_min"):
            probs.append(("previa facil sem azar", origem, e))
        if e["kind"] in ("far", "far_plain"):
            probs.append(("sem FALTARAM", origem, e))
        if kd in ("stronger", "dodged", "life_taken") and n <= 0:
            probs.append(("estatistica 0", origem, e))
        if kd == "stronger" and not (20 <= n < 100):
            probs.append(("stronger fora da faixa", origem, e))
        if kd == "stronger_x" and not (2 <= n < 10):
            probs.append(("stronger_x fora da faixa", origem, e))
        if kd == "dodged" and n > 100:
            probs.append(("esquiva > 100%", origem, e))
    print("| origem | motivo | derrotas |")
    print("|---|---|---|")
    for (o, kd), q in sorted(cont.items()):
        print("| %s | %s | %d |" % (o, kd, q))
    print("\nEstatistica usada (2a linha):")
    print("| kind | derrotas | exemplo |")
    print("|---|---|---|")
    for kd, q in sorted(por_kind.items(), key=lambda x: -x[1]):
        o, e = exemplos[kd]
        print("| %s | %d | %s (%s, previa %d%%) |" % (kd, q, frase(e), o, round(100 * e["p"])))
    print("\nExemplo de cada motivo:")
    for kd in ("missing", "luck", "far", "far_plain"):
        if "motivo_" + kd in exemplos:
            o, e = exemplos["motivo_" + kd]
            print("- %s: %s (%s, previa %d%%)" % (kd, frase(e), o, round(100 * e["p"])))
    print("\nTotal: %d derrotas; problemas: %d; sem FALTARAM pela regra antiga e com FALTARAM agora: %d" % (len(casos), len(probs), antes_sem))
    for tipo, o, e in probs[:20]:
        print("  PROBLEMA %s: %s | %s | previa %d%%" % (tipo, o, frase(e), round(100 * e["p"])))


def main():
    R, treino, gens, shop, career = carregar()
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    if tudo or "limiares" in secs:
        sec_limiares(R)
    if tudo or "taticas" in secs:
        sec_taticas(R)
    if tudo or "foco" in secs:
        sec_foco(R)
    if tudo or "duracao" in secs:
        sec_duracao(R)
    if tudo or "risco" in secs:
        sec_risco(R)
    if tudo or "carreiras" in secs:
        sec_carreiras(R, treino, gens, shop, career)
    if tudo or "curvas" in secs:
        for estr, cps, lim in [("saco", 5, "equilibrado"), ("saco", 4, "equilibrado"), ("bom", 5, "facil"),
                               ("bom", 4, "facil")]:
            curva(R, treino, gens, shop, career, estr, cps, lim)
    if tudo or "motivo" in secs:
        sec_motivo(R, treino, gens, shop, career)
    if tudo or "dica" in secs:
        sec_dica(R, treino, gens, shop, career)
    if tudo or "explica" in secs:
        sec_explica(R, treino, gens, shop, career)


if __name__ == "__main__":
    main()
