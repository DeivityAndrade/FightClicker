"""Simulacao da Fase 5 (academia de bairro + Boxe e Jiu-jitsu) do Fightclicker.

Reaproveita tools/sim/fase4b_sim.py (aparelhos que chegam, assistido), que reaproveita fase4_sim.py
(arvore, Metronomo, revanche, tempo morto), fase3_sim.py (luta, previa, motivo) e fase2_sim.py.

O que entra (design docs/fases/fase5-design.md):
  - o cinturao nao encerra mais a carreira: libera o botao MUDAR (preco em $). Mudar da o
    multiplicador global de treino e as 2 lutas da academia (so para quem se mudou). Toda carreira
    comeca na garagem;
  - arte da carreira (Boxe / Jiu-jitsu): escolhida na 1a chegada a academia e, depois, no inicio de
    cada carreira. Cada arte tem: aparelho assinatura (4o foco, compra com Treino depois da esteira,
    treina os 3 atributos numa proporcao), regra de curva, 2 tecnicas (melhorias do aparelho) e um
    traco de luta;
  - aba ESTILO da arvore (1 no por arte).

Os valores vem de data/ (locations, arts, training, opponents, skill_tree). PROPOSTA_5 so e usada se esses arquivos faltarem
(ou com SIM_PROPOSTA=1).
Variaveis de ambiente para testar alavancas:
  SIM_MOVE="1000,2.0"          (preco da mudanca em $, multiplicador de treino da academia)
  SIM_BOXE="0.5"               (bonus do Boxe no clique manual)
  SIM_JJ="0.5,0.15,3.0"        (Jiu-jitsu: bonus inicial, ganho por minuto, teto)
  SIM_G1="F,A,R" SIM_G2="F,A,R" (atributos dos adversarios da academia)
  SIM_RET="480"                (robo: aposenta depois de N s seguidos no vermelho na academia)
  SIM_N, SIM_CARREIRAS, SIM_PROC, SIM_PERFIS, SIM_N_23B (como nos outros)

Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase5_sim.py [secao ...]
Secoes: precos, curvas, identidade, b23, carreiras, controle, assistido, tudo (padrao).
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
import fase3_sim as f3  # noqa: E402
import fase4_sim as f4  # noqa: E402
import fase4b_sim as f4b  # noqa: E402

APAR = f3.APAR          # ("punching_bag", "jump_rope", "treadmill")
ATTR = f3.ATTR          # ("strength", "agility", "endurance")
BAG = "punching_bag"

PROPOSTA_5 = {
    "move": {"id": "move_gym", "cost": 1000, "training_mult": 2.0},
    "arts": {
        "boxing": {"apparatus": "speed_bag",
                   "rule": {"type": "manual_click_bonus", "value": 0.5},
                   "fight": {"damage_mult": 1.10, "taken_mult": 1.0}},
        "bjj": {"apparatus": "grappling_dummy",
                "rule": {"type": "crew_time_bonus", "start": 0.2, "per_minute": 0.12, "cap": 1.0},
                "fight": {"damage_mult": 1.0, "taken_mult": 0.90}},
    },
    # split na ordem (forca, agilidade, resistencia)
    "apparatus": {
        "speed_bag": {"split": (0.40, 0.45, 0.15),
                      "unlock": {"id": "unlock_speed_bag", "cost": 2500, "requires": "treadmill"},
                      "upgrades": [{"id": "tech_boxing_1", "cost": 1500, "multiplier": 3},
                                   {"id": "tech_boxing_2", "cost": 15000, "multiplier": 5}]},
        "grappling_dummy": {"split": (0.25, 0.15, 0.60),
                            "unlock": {"id": "unlock_grappling_dummy", "cost": 2500, "requires": "treadmill"},
                            "upgrades": [{"id": "tech_bjj_1", "cost": 1500, "multiplier": 3},
                                         {"id": "tech_bjj_2", "cost": 15000, "multiplier": 5}]},
    },
    "opponents_gym": [
        {"id": "opp_gym_1", "strength": 260000, "agility": 100000, "endurance": 1100000,
         "prize_money": 2500, "prize_fame": 120, "belt": False, "location": "gym"},
        {"id": "opp_gym_2", "strength": 500000, "agility": 1000000, "endurance": 2000000,
         "prize_money": 6000, "prize_fame": 200, "belt": False, "location": "gym"},
    ],
    # aba ESTILO: 1 no por arte. value = o efeito da regra da arte fica x(1 + value) (Boxe: +50% -> +75%;
    # Jiu-jitsu: +12%/min ate +100% -> +18%/min ate +150%)
    "style_nodes": [
        {"id": "style_boxing", "branch": "style", "requires": "", "requires_art": "boxing", "cost": 1200,
         "effect": {"type": "art_rule_bonus", "value": 0.5}},
        {"id": "style_bjj", "branch": "style", "requires": "", "requires_art": "bjj", "cost": 1200,
         "effect": {"type": "art_rule_bonus", "value": 0.5}},
    ],
}
CTRL_CAUT = os.environ.get("SIM_CTRL_CAUT", "1") == "1"   # controle: espera o verde contra todos
RET_GYM = float(os.environ.get("SIM_RET", "480"))   # robo aposenta apos 8 min seguidos no vermelho na academia
T_MAX5 = 90 * 60


def _proposta_dos_dados(R, treino, tree):
    """Monta o mesmo dicionario do PROPOSTA_5 a partir de data/ (locations, arts, training, opponents, skill_tree).
    Devolve (P, fontes). Se data/locations.json ou data/arts.json nao existir, devolve a PROPOSTA_5 embutida."""
    loc = f3.ler("locations.json", None)[0]
    arts = f3.ler("arts.json", None)[0]
    if loc is None or arts is None or os.environ.get("SIM_PROPOSTA") == "1":
        P = json.loads(json.dumps(PROPOSTA_5))
        for ap in P["apparatus"].values():
            ap["split"] = tuple(ap["split"])
        return P, ["PROPOSTA_5 embutida (sem data/locations.json e data/arts.json)"]
    gym = next(l for l in loc["locations"] if l.get("move"))
    P = {"move": {"id": gym["move"]["id"], "cost": gym["move"]["cost"], "training_mult": gym["training_mult"]},
         "arts": {}, "apparatus": {}, "opponents_gym": [], "style_nodes": []}
    for a in arts["arts"]:
        P["arts"][a["id"]] = {"apparatus": a["apparatus"], "rule": dict(a["rule"]), "fight": dict(a.get("fight", {}))}
    for ap in treino["apparatus"]:
        if ap.get("art"):
            sp = ap["split"]
            P["apparatus"][ap["id"]] = {
                "split": (sp["strength"], sp["agility"], sp["endurance"]),
                "unlock": {"id": ap["unlock"]["id"], "cost": ap["unlock"]["cost"], "requires": ap["unlock"].get("requires", "")},
                "upgrades": [{"id": u["id"], "cost": u["cost"], "multiplier": u["multiplier"]} for u in ap["upgrades"]]}
    P["opponents_gym"] = [o for o in R.opp if o.get("location", "garage") != "garage"]
    P["style_nodes"] = [n for n in tree["nodes"] if n.get("requires_art")]
    return P, ["data/locations.json", "data/arts.json", "aparelhos de arte de data/training.json",
               "adversarios da academia de data/opponents.json", "nos ESTILO de data/skill_tree.json"]


def carregar_5(quieto=False):
    dados = f4b.carregar_4b(quieto=True)
    R, treino, gens, shop, career, tree, unlocks, assist = dados
    P, fontes = _proposta_dos_dados(R, treino, tree)
    # os simuladores anteriores so conhecem a garagem: tira dos dados o que e da academia/artes
    treino = dict(treino)
    treino["apparatus"] = [a for a in treino["apparatus"] if not a.get("art")]
    ids_arte = set(P["apparatus"])
    unlocks = [u for u in unlocks if u["apparatus"] not in ids_arte]
    if os.environ.get("SIM_MOVE"):
        c, m = os.environ["SIM_MOVE"].split(",")
        P["move"]["cost"], P["move"]["training_mult"] = float(c), float(m)
    if os.environ.get("SIM_BOXE"):
        P["arts"]["boxing"]["rule"]["value"] = float(os.environ["SIM_BOXE"])
    if os.environ.get("SIM_JJ"):
        s, r, cap = (float(x) for x in os.environ["SIM_JJ"].split(","))
        P["arts"]["bjj"]["rule"].update(start=s, per_minute=r, cap=cap)
    P["opponents_gym"] = [dict(o) for o in P["opponents_gym"]]
    for i, var in enumerate(("SIM_G1", "SIM_G2")):
        if os.environ.get(var):
            F, A, Rr = (float(x) for x in os.environ[var].split(","))
            P["opponents_gym"][i].update(strength=F, agility=A, endurance=Rr)
    # adversarios: a escada de hoje + os 2 da academia (so lutam depois da mudanca)
    garagem = [o for o in R.opp if o.get("location", "garage") == "garage"]
    opps = {"opponents": garagem + P["opponents_gym"]}
    R5 = f3.Regras({"combat": R.c, "tactics": [R.tac[t] for t in R.tac_ids], "risk": R.risk, "reason": R.reason}, opps)
    tree5 = {"branches": tree.get("branches", []), "nodes": list(tree["nodes"])}
    if not quieto:
        print("Fontes 5: %s" % ", ".join(fontes))
        print("Fase 5: mudanca $%d, x%.2f; Boxe +%.0f%% clique manual; Jiu-jitsu %s; G1 %s; G2 %s; aposenta na academia apos %ds no vermelho" % (
            P["move"]["cost"], P["move"]["training_mult"], 100 * P["arts"]["boxing"]["rule"]["value"],
            P["arts"]["bjj"]["rule"], tuple(P["opponents_gym"][0][k] for k in ("strength", "agility", "endurance")),
            tuple(P["opponents_gym"][1][k] for k in ("strength", "agility", "endurance")), RET_GYM))
    return (R5, treino, gens, shop, career, tree5, unlocks, assist, P)


def regras_arte(R, arte_cfg):
    """Traco de luta: multiplica damage_mult/taken_mult de TODAS as taticas do jogador."""
    if arte_cfg is None:
        return R
    f = arte_cfg["fight"]
    R2 = copy.copy(R)
    R2.tac = {}
    for t, d in R.tac.items():
        d2 = dict(d)
        d2["damage_mult"] = d["damage_mult"] * f.get("damage_mult", 1.0)
        d2["taken_mult"] = d["taken_mult"] * f.get("taken_mult", 1.0)
        R2.tac[t] = d2
    return R2


class Carreira5(f4b.Carreira4b):
    def __init__(self, R, treino, gens, shop, career, cps, estr, semente, bonus, unlocks, assist, P,
                 arte=None, arte_chegada=None, belt_ends=False, cauteloso_gym=False, ret_gym=RET_GYM,
                 style_bonus=None, **kw):
        super().__init__(R, treino, gens, shop, career, cps, estr, semente, bonus, list(unlocks), assist, **kw)
        self.R_base = R
        self.P = P
        self.belt_ends = belt_ends            # True = jogo da 4b (cinturao encerra; para comparar)
        self.cauteloso_gym = cauteloso_gym
        self.ret_gym = ret_gym
        self.style_bonus = style_bonus or {}  # {"boxing": 0.25, "bjj": 1.0} dos nos comprados
        self.mudou = False
        self.loc = 1.0
        self.arte = None
        self.sig = None
        self.split = None
        self.t_arte0 = 0.0
        self.arte_chegada = arte_chegada      # arte escolhida na 1a chegada (None = ja tinha arte)
        self.t_belt = None
        self.t_move = None
        self.t_g = {}
        self.morto_pre = 0.0
        self.boxe_f = 1.0
        if arte:
            self.definir_arte(arte)

    # --- arte
    def definir_arte(self, arte):
        cfg = self.P["arts"][arte]
        self.arte = arte
        self.t_arte0 = self.t
        self.R = regras_arte(self.R_base, cfg)
        self.sig = cfg["apparatus"]
        apc = self.P["apparatus"][self.sig]
        self.split = apc["split"]
        self.ups[self.sig] = apc["upgrades"]
        self.nivel[self.sig] = 0
        self.tempo_foco[self.sig] = 0.0
        u = dict(apc["unlock"]); u["apparatus"] = self.sig
        self.unlocks.append(u)
        if cfg["rule"]["type"] == "manual_click_bonus":
            self.boxe_f = 1.0 + cfg["rule"]["value"] * (1.0 + self.style_bonus.get("boxing", 0.0))

    def jj_bonus(self):
        if self.arte != "bjj":
            return 0.0
        r = self.P["arts"]["bjj"]["rule"]
        m = 1.0 + self.style_bonus.get("bjj", 0.0)      # no da aba ESTILO: a curva inteira x(1 + value)
        return m * min(r["cap"], r["start"] + r["per_minute"] * (self.t - self.t_arte0) / 60.0)

    def aps(self):
        return APAR + ((self.sig,) if self.sig else ())

    def fator_equipe(self):
        return self.loc * (1.0 + self.jj_bonus())

    # --- economia
    def passivo(self):
        return f4.Carreira4.passivo(self) * self.fator_equipe()

    def clique_s(self, a):
        ass = 1.0 / self.assist_cfg["interval"] if (self.usa_shift and self.metro == 0 and self.cps == 0) else 0.0
        return (self.cps * self.boxe_f + self.metro_s() + ass) * self.por_soco(a) * self.loc

    def clique_jogador_s(self, a):
        return self.cps_agora() * self.por_soco(a) * self.boxe_f * self.loc

    def clique_medio(self):
        w = self.pesos()
        return sum(self.clique_s(a) * w.get(a, 0.0) for a in self.aps())

    def somar(self, a, g):
        if a == self.sig:
            for i in range(3):
                self.attr[i] += g * self.split[i]
        else:
            self.attr[APAR.index(a)] += g

    def pesos(self):
        if not self.sig:
            return f4b.Carreira4b.pesos(self)
        tot = sum(self.tempo_foco.values()) + 20.0
        w = {a: (self.tempo_foco.get(a, 0.0) + (20.0 if a == BAG else 0.0)) / tot for a in self.aps()}
        for a in w:
            if a not in self.owned:
                w[a] = 0.0
        s = sum(w.values()) or 1.0
        return {a: v / s for a, v in w.items()}

    def foco(self):
        a = f4b.Carreira4b.foco(self)
        if self.sig and self.sig in self.owned and a == BAG and not (self.t < self.teste_ate):
            if self.mult_ap(self.sig) >= self.mult_ap(BAG):
                return self.sig
        return a

    # --- compras
    def tentar_mudar(self):
        if self.cinturao and not self.mudou and not self.belt_ends:
            mv = self.P["move"]
            if self.dinheiro + 1e-9 >= mv["cost"]:
                self.dinheiro -= mv["cost"]
                self.mudou = True
                self.loc = mv["training_mult"]
                self.t_move = self.t
                self.eventos.append((self.t, "MUDA academia"))
                self.fechar_trechos()
                self.morto_pre = self.morto_max
                self.morto_max = 0.0
                if self.arte is None and self.arte_chegada:
                    self.definir_arte(self.arte_chegada)
                    self.eventos.append((self.t, "ARTE " + self.arte_chegada))

    def comprar_garagem(self):
        u = self.proximo_unlock()
        if self.deseja(u):
            if self.saldo + 1e-9 < u["cost"]:
                return
            self.saldo -= u["cost"]
            self.owned.add(u["apparatus"])
            self.t_ap[u["apparatus"]] = self.t
            self.eventos.append((self.t, u["id"]))
            self.teste_ap, self.teste_ate = u["apparatus"], self.t + f4b.TESTE_S
        # 1a tecnica: prioridade logo depois do aparelho da arte
        if self.sig and self.sig in self.owned and self.nivel[self.sig] == 0:
            c = float(self.ups[self.sig][0]["cost"])
            if self.saldo + 1e-9 < c:
                return
            self.saldo -= c
            self.nivel[self.sig] = 1
            self.eventos.append((self.t, "tecnica 1"))
        q0 = dict(self.qtd)
        n0 = dict(self.nivel)
        if self.clique_medio() + self.passivo() <= 0:
            return
        self._garagem_f3()
        for gid in self.qtd:
            if q0[gid] == 0 and self.qtd[gid] > 0:
                self.marca("1o " + gid)
        if sum(self.nivel.values()) > 0 and sum(n0.values()) == 0:
            self.marca("1a melhoria")

    def _garagem_f3(self):
        """f3.Carreira.comprar_garagem com o fator da equipe e o 4o aparelho (identica sem arte e na garagem)."""
        fe = self.fator_equipe()
        while True:
            w = self.pesos()
            renda = self.clique_medio() + self.passivo()
            melhor = None
            for g in self.gens:
                c = f2.custo_gerador(g, self.qtd[g["id"]])
                ganho = float(g["production"]) * fe
                nota = max(0.0, c - self.saldo) / renda + c / ganho
                if melhor is None or nota < melhor[0]:
                    melhor = (nota, "gen", g["id"], c)
            for a in self.aps():
                if w.get(a, 0.0) < 0.05 or self.nivel[a] >= len(self.ups[a]):
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
        """f4 comprar_loja + fator da equipe no Nelson + guarda do preco da mudanca (identica sem arte/garagem)."""
        fe = self.fator_equipe()
        guarda = self.P["move"]["cost"] if (self.cinturao and not self.mudou and not self.belt_ends) else 0.0
        while True:
            livre = self.dinheiro - guarda
            ops = []
            for g in self.pgens:
                c = f2.custo_gerador(g, self.pqtd[g["id"]])
                ops.append((g["production"] * (1 + self.b["passive_bonus"]) * fe / c, "pgen", g["id"], c))
            if self.luva < len(self.luvas):
                L = self.luvas[self.luva]
                ganho = self.clique_medio() * (L["click_multiplier"] - 1)
                ops.append((ganho / L["cost"], "luva", L["id"], float(L["cost"])))
            if self.metro < len(self.metro_niveis):
                M = self.metro_niveis[self.metro]
                novo = 1.0 / M["interval"]
                w = self.pesos()
                ganho = sum(self.por_soco(a) * w.get(a, 0.0) for a in self.aps()) * (novo - self.metro_s())
                ops.append((ganho / M["cost"], "metro", M["id"], float(M["cost"])))
            if not ops:
                return
            ops.sort(reverse=True)
            _, tipo, id_, c = ops[0]
            if livre + 1e-9 < c:
                cabe = [o for o in ops if o[3] <= livre + 1e-9]
                if not (self.perigoso and cabe):
                    return
                _, tipo, id_, c = cabe[0]
            self.dinheiro -= c
            if tipo == "pgen":
                self.pqtd[id_] += 1
                if self.pqtd[id_] == 1:
                    self.eventos.append((self.t, "1o " + id_))
            elif tipo == "luva":
                self.luva += 1
                self.eventos.append((self.t, id_))
            else:
                self.metro += 1
                self.metro_compras.append(self.t)
                self.eventos.append((self.t, id_))

    # --- luta
    def talvez_lutar(self):
        if self.vitorias >= len(self.R.opp) or self.fim:
            self.perigoso = False
            return
        o = self.R.opp[self.vitorias]
        if o.get("location") == "gym" and not self.mudou:
            self.perigoso = False          # depois do cinturao, antes de mudar: nao ha luta
            return
        if self.belt_ends and self.cinturao:
            self.perigoso = False
            return
        if self.t - self.ult_check_t < self.olhar:
            return
        self.ult_check_t = self.t
        jog = tuple(self.attr)
        adv = self.adv()
        even = self.R.risk["even_min"]
        easy = self.R.risk["easy_min"]
        lim = easy if self.limiar == "facil" else even
        cc = self.cauteloso_contra
        killer = (o["id"] in cc) if isinstance(cc, (set, frozenset, list, tuple)) else (cc == o["id"])
        if self.cauteloso_gym and o.get("location") == "gym":
            killer = True
        self.e_revanche = o["id"] == getattr(self, "ultimo_algoz", None)
        if killer:
            lim = easy
        passa_lim = any(self.R.passa(jog, adv, t, 100, lim) for t in self.R.tac_ids)
        if lim == even:
            self.perigoso = not passa_lim
        else:
            self.perigoso = not passa_lim and not any(self.R.passa(jog, adv, t, 100, even) for t in self.R.tac_ids)
        if killer and passa_lim and self.t_verde_killer is None and o["id"] == getattr(self, "ultimo_algoz", None):
            self.t_verde_killer = self.t
        if not passa_lim:
            if self.paciencia is None or self.t - self.t_ult_vit < self.paciencia:
                return
        tat, ps = self.R.melhor_tatica(jog, adv, 100)
        p = ps[tat]
        r = self.R.lutar(jog, adv, tat, self.rng.randrange(1 << 31))
        dur = 5.0 + self.R.tela(r)
        self.lutas.append({"t": self.t, "opp": o["id"], "p": p, "tat": tat, "win": r["win"], "attr": jog,
                           "tela": self.R.tela(r)})
        g = self.passivo() * dur
        self.saldo += g
        self.somar(self.foco(), g)
        self.t += dur
        self.fechar_trechos()
        if r["win"]:
            self.vitorias += 1
            self.t_ult_vit = self.t
            ganho = o["prize_money"] * (1 + self.b["money_bonus"])
            self.dinheiro += ganho
            self.dinheiro_total += ganho
            self.fama += int(math.floor(o["prize_fame"] * (1 + self.b["fame_bonus"]) + 0.5))
            if self.e_revanche:
                self.t_revanche = self.t
            self.eventos.append((self.t, "VENCE " + o["id"]))
            if o.get("belt"):
                self.cinturao = True
                self.t_belt = self.t
                if self.belt_ends:
                    self.fim = ("cinturao", self.t)
            if o.get("location") == "gym":
                self.t_g[o["id"]] = self.t
                if self.vitorias >= len(self.R.opp):
                    self.fim = ("topo", self.t)      # venceu a academia inteira: aposenta
            self.perigoso = False
        else:
            self.fim = ("derrota", self.t, o["id"], jog, tat)
            self.eventos.append((self.t, "PERDE " + o["id"]))

    # --- laco
    def rodar(self):
        dt = self.dt
        cfg = self.assist_cfg
        while self.t < self.t_max and not self.fim:
            self.tentar_mudar()
            self.comprar_garagem()
            self.comprar_loja()
            a = self.foco()
            cj = self.cps_agora()
            ps = self.por_soco(a)
            gc = cj * ps * dt * self.boxe_f * self.loc
            gm = self.metro_s() * ps * dt * self.loc
            ga = 0.0
            if cj > 0:
                self.ocioso = 0.0
            else:
                self.ocioso += dt
            ativo = self.usa_shift and self.metro == 0 and cj == 0 and self.ocioso >= cfg["still_seconds"]
            if ativo:
                self.acc += dt
                while self.acc >= cfg["interval"] - 1e-9:
                    self.acc -= cfg["interval"]
                    ga += ps * self.loc
                    self.n_assist += 1
            else:
                self.acc = cfg["interval"] - cfg["first_delay"]
            g = gc + gm + ga + self.passivo() * dt
            self.treino_clique += gc
            self.treino_metro += gm
            self.treino_assist += ga
            self.saldo += g
            self.somar(a, g)
            self.tempo_foco[a] += dt
            self.t += dt
            ap = getattr(self, "aposenta_vermelho", None)
            if ap and self.perigoso and self.verm >= ap and self.pote() > 0:
                self.fechar_trechos()
                self.fim = ("aposentou", self.t)
                break
            if self.mudou and self.perigoso and self.verm >= self.ret_gym:
                self.fechar_trechos()
                self.fim = ("aposentou", self.t)
                break
            if self.perigoso:
                self.verm += dt
                if self.dinheiro + 1e-9 < self.menor_preco_loja():
                    self.morto += dt
                else:
                    self.morto_max = max(self.morto_max, self.morto)
                    self.morto = 0.0
            else:
                self.fechar_trechos()
            t0 = self.t
            self.talvez_lutar()
            if self.t != t0:
                self.acc = cfg["interval"] - cfg["first_delay"]
        self.fechar_trechos()
        if not self.fim:
            self.fim = ("parado", self.t)
        return self

    def morto_total(self):
        return max(self.morto_pre, self.morto_max) if self.mudou else self.morto_max

    def morto_gym(self):
        return self.morto_max if self.mudou else None


# ---------------------------------------------------------------- arvore com a aba ESTILO
def arvore_disponivel(tree, artes_livres, arte_robo):
    """Nos da aba ESTILO so existem com a arte desbloqueada; o robo so compra o da(s) arte(s) que joga."""
    nodes = []
    for n in tree["nodes"]:
        ra = n.get("requires_art")
        if ra and (ra not in artes_livres or ra not in arte_robo):
            continue
        nodes.append(n)
    return {"nodes": nodes}


def style_de(tree, comprados):
    out = {}
    for n in tree["nodes"]:
        if n["id"] in comprados and n.get("requires_art"):
            out[n["requires_art"]] = out.get(n["requires_art"], 0.0) + n["effect"]["value"]
    return out


def ordem_5():
    o = list(f4.PROPOSTA["ordem_dica"])
    i = o.index("career_crowd") + 1
    return o[:i] + ["style_boxing", "style_bjj"] + o[i:]


# ---------------------------------------------------------------- sequencia de carreiras
DADOS = None


def _init(quieto=True):
    global DADOS
    DADOS = carregar_5(quieto=quieto)
    f4.DADOS = DADOS[:6]
    f4b.DADOS = DADOS[:8]


def arte_da_carreira(politica, n_com_arte):
    """politica: 'boxing', 'bjj', 'alterna_b' (comeca Boxe), 'alterna_j' (comeca Jiu-jitsu)."""
    if politica in ("boxing", "bjj"):
        return politica
    seq = ("boxing", "bjj") if politica == "alterna_b" else ("bjj", "boxing")
    return seq[n_com_arte % 2]


def sequencia(args):
    (cps, metronomo, regra, semente, K, estilo, ritmo_nome, shift, t_max, politica, modo) = args
    R, treino, gens, shop, career, tree, unlocks, assist, P = DADOS
    ritmo = {"const": f4b.ritmo_constante(cps), "misto": f4b.ritmo_misto(cps)}[ritmo_nome]
    belt_ends = modo == "4b"
    comprados, legado = set(), 0
    killer, dica = None, None
    algozes = set()
    artes_livres = set()
    n_com_arte = 0
    t_acum = 0.0
    out = []
    tree_base = {"nodes": [nn for nn in tree["nodes"] if not nn.get("requires_art")]}
    for k in range(1, K + 1):
        b = f4.bonus_de(tree_base, comprados)
        if not metronomo:
            b["metronome_start"] = 0
        estr = "tipico"
        if "ate_algoz" in estilo and killer:
            ik = next(i for i, o in enumerate(R.opp) if o["id"] == killer)
            caut = set(algozes) | {o["id"] for o in R.opp[:ik + 1]}
        else:
            caut = set(algozes)
        arte = arte_da_carreira(politica, n_com_arte) if artes_livres else None
        chegada = None if artes_livres else arte_da_carreira(politica, 0)
        c = Carreira5(R, treino, gens, shop, career, cps, estr, semente * 100 + k, b, unlocks, assist, P,
                      arte=arte, arte_chegada=chegada, belt_ends=belt_ends,
                      cauteloso_gym=("caut_gym" in estilo), style_bonus=style_de(tree, comprados),
                      regra_ap="asap", k=k, ritmo=ritmo, usa_shift=shift, limiar="equilibrado",
                      dica=dica, cauteloso_contra=caut, metronomo=metronomo, t_max=t_max)
        c.ultimo_algoz = killer
        c.rodar()
        if c.arte:
            n_com_arte += 1
        primeira = (not artes_livres) and c.mudou
        if c.mudou:
            artes_livres |= {"boxing", "bjj"}
        ganho = c.legado_ganho()
        legado += ganho
        vit_t = {}
        for t, e in c.eventos:
            if e.startswith("VENCE "):
                vit_t[e[6:]] = t
        t_ini = t_acum
        t_acum += c.fim[1] + f4.OVERHEAD
        rec = {"k": k, "fim": c.fim[0], "t": c.fim[1], "opp": c.fim[2] if c.fim[0] == "derrota" else None,
               "arte": c.arte, "primeira_chegada": primeira, "t_belt": c.t_belt, "t_move": c.t_move,
               "t_g": dict(c.t_g), "vit_t": vit_t, "morto": c.morto_total(), "morto_gym": c.morto_gym(),
               "verm": c.verm_max, "ganho": ganho, "nos_antes": len(comprados), "t_ini": t_ini, "t_fim": t_acum,
               "t_ap": dict(c.t_ap), "ev": list(c.eventos), "revanche": c.t_revanche, "killer_antes": killer,
               "treino_clique": c.treino_clique, "treino_metro": c.treino_metro, "treino_assist": c.treino_assist,
               "attr_fim": tuple(c.attr), "mudou": c.mudou,
               "lutas": [(l["opp"], l["win"], round(l["p"], 2), round(l["t"])) for l in c.lutas]}
        if c.fim[0] == "derrota":
            _, t, opp, jog, tat = c.fim
            o = next(x for x in R.opp if x["id"] == opp)
            attr, _, _ = c.R.motivo(jog, (o["strength"], o["agility"], o["endurance"]), tat, 100)
            dica = attr
            killer = opp
            algozes.add(opp)
        else:
            killer = None
        arte_robo = {"boxing", "bjj"} if politica.startswith("alterna") else {politica}
        tr = arvore_disponivel(tree, artes_livres, arte_robo)
        comprados, legado = f4.comprar_nos(tr, comprados, legado, regra, ordem_5())
        rec["nos_depois"] = len(comprados)
        rec["comprados"] = sorted(comprados)
        out.append(rec)
    return out


def rodar_perfis(perfis, n, K):
    tarefas = []
    for p in perfis:
        for s in range(n):
            tarefas.append((p["cps"], p.get("metro", True), p.get("regra", "dica"), 1000 + s, K,
                            p.get("estilo", "memoria ate_algoz"), p.get("ritmo", "const"), p.get("shift", False),
                            p.get("t_max", T_MAX5), p.get("arte", "boxing"), p.get("modo", "5")))
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    with Pool(proc, initializer=_init) as pool:
        res = pool.map(sequencia, tarefas, chunksize=1)
    out, i = {}, 0
    for p in perfis:
        out[p["nome"]] = res[i:i + n]
        i += n
    return out


med = f4.mediana
pct = f4.pct
mm = f4.mm


def filtra(perfis):
    so = os.environ.get("SIM_PERFIS")
    if so:
        perfis = [p for p in perfis if any(s in p["nome"] for s in so.split(";"))]
    return perfis


def fk(x):
    return f4.fmtk(x)


# ---------------------------------------------------------------- secoes
def sec_precos():
    R, treino, gens, shop, career, tree, unlocks, assist, P = DADOS
    print("\n## Numeros da Fase 5")
    mv = P["move"]
    print("- mudanca: $%d, treino x%.2f" % (mv["cost"], mv["training_mult"]))
    for a, cfg in P["arts"].items():
        ap = P["apparatus"][cfg["apparatus"]]
        print("- %s: regra %s; luta %s; aparelho %s split %s, unlock %d, tecnicas %s" % (
            a, cfg["rule"], cfg["fight"], cfg["apparatus"], ap["split"], ap["unlock"]["cost"],
            [(u["cost"], u["multiplier"]) for u in ap["upgrades"]]))
    r = P["arts"]["bjj"]["rule"]
    print("  Jiu-jitsu por minuto de arte: " + ", ".join("%d min +%.0f%%" % (m, 100 * min(r["cap"], r["start"] + r["per_minute"] * m))
                                                        for m in (0, 5, 10, 15, 20, 30)))
    for o in P["opponents_gym"]:
        print("- %s: F %s A %s R %s; $%d; fama %d" % (o["id"], f3.k(o["strength"]), f3.k(o["agility"]), f3.k(o["endurance"]),
                                                       o["prize_money"], o["prize_fame"]))
    lpf, bb = career["legacy_per_fame"], career["belt_legacy_bonus"]
    fama = [10, 30, 60, 100] + [o["prize_fame"] for o in P["opponents_gym"]]
    acum = [sum(fama[:i + 1]) for i in range(len(fama))]
    print("- pote (sem nos) por vitorias: %s" % [math.floor(f * lpf) + (bb if i >= 3 else 0) for i, f in enumerate(acum)])
    print("  aposentar com cinturao: %d; + G1: %d; + G2: %d" % tuple(
        math.floor((math.floor(acum[i] * lpf) + bb) * 1.5) for i in (3, 4, 5)))
    print("  derrota no G1 (com cinturao): %d; no G2: %d" % tuple((math.floor(acum[i] * lpf) + bb) // 2 for i in (3, 4)))


def sec_identidade(n):
    """A carreira 1 tem que ser igual a da 4b ate o cinturao (criterio 12)."""
    perfis = []
    for cps in (5, 4, 3):
        perfis.append({"nome": "5 %d/s" % cps, "cps": cps, "modo": "5"})
    res = rodar_perfis(perfis, n, 1)
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    tarefas = [(cps, True, "dica", 1000 + s, 1, "memoria ate_algoz", "asap", "const", False, f4.T_MAX)
               for cps in (5, 4, 3) for s in range(n)]
    with Pool(proc, initializer=_init) as pool:
        base = pool.map(_seq_4b, tarefas, chunksize=1)
    print("\n## Identidade da carreira 1 contra o fase4b_sim original (%d jogadores; tudo ate o cinturao ou a derrota)" % n)
    for j, cps in enumerate((5, 4, 3)):
        b = res["5 %d/s" % cps]
        a = base[j * n:(j + 1) * n]
        iguais = 0
        for sa, sb in zip(a, b):
            ra, rb = sa[0], sb[0]
            lim = ra["t"]
            la = ra["lutas"]
            lb = [l for l in rb["lutas"] if l[3] <= lim + 1e-6]
            if la == lb and abs((rb["t_belt"] or rb["t"]) - ra["t"]) < 1e-6:
                iguais += 1
        print("- %d/s: %d de %d carreiras 1 identicas (mesmas lutas, mesmos tempos, mesma chance)" % (cps, iguais, len(a)))


def _seq_4b(args):
    return f4b.sequencia(args)


def sec_b23(n):
    perfis = [{"nome": "5/s", "cps": 5}, {"nome": "4/s", "cps": 4}]
    res = rodar_perfis(perfis, n, 1)
    print("\n## 23b: cinturao na 1a carreira (%d jogadores)" % n)
    print("| perfil | cinturao na 1a | mais cedo | derrotas no Dudu | 1a derrota (mediana) |")
    print("|---|---|---|---|---|")
    for nome, seqs in res.items():
        c1 = [s[0]["t_belt"] for s in seqs if s[0]["t_belt"]]
        dud = sum(1 for s in seqs if s[0]["opp"] == "opp_warmup")
        d1 = [s[0]["t"] for s in seqs if s[0]["fim"] == "derrota" and not s[0]["t_belt"]]
        print("| %s | %.1f%% | %s | %d | %s |" % (nome, 100 * len(c1) / len(seqs), mm(min(c1)) if c1 else "-", dud, mm(med(d1))))


def resumo_seq(nome, seqs, K):
    """Metricas por jogador de uma sequencia de carreiras da Fase 5."""
    linhas = {}
    kb, kc, tc, tb, tm, g1k, g2k, g1t, g2t, kc1, kc2, d14, mg, arv = ([] for _ in range(14))
    mesma_g2 = 0
    n_cheg = 0
    for s in seqs:
        ch = next((r for r in s if r["primeira_chegada"]), None)
        kb.append(next((r["k"] for r in s if r["t_belt"]), 99))
        if ch is None:
            kc.append(99)
            g1k.append(99); g2k.append(99)
            continue
        n_cheg += 1
        kc.append(ch["k"])
        tc.append(ch["t_ini"] + ch["t_move"])          # tempo de jogo total ate a 1a chegada
        tb.append(ch["t_belt"])
        tm.append(ch["t_move"] - ch["t_belt"])
        d14.append(ch["t_fim"])                            # comeca a carreira seguinte (com a outra arte)
        r1 = next((r for r in s if "opp_gym_1" in r["t_g"]), None)
        r2 = next((r for r in s if "opp_gym_2" in r["t_g"]), None)
        g1k.append(r1["k"] - ch["k"] if r1 else 99)
        g2k.append(r2["k"] - ch["k"] if r2 else 99)
        if r1:
            g1t.append(r1["t_g"]["opp_gym_1"])
        if r2:
            g2t.append(r2["t_g"]["opp_gym_2"])
            if r2["k"] == ch["k"]:
                mesma_g2 += 1
    for s in seqs:
        for r in s:
            if r["morto_gym"] is not None:
                mg.append(r["morto_gym"])
    ntot = len(DADOS[5]["nodes"])
    return {"kb": kb, "kc": kc, "tc": tc, "tm": tm, "g1k": g1k, "g2k": g2k, "g1t": g1t, "g2t": g2t,
            "mesma_g2": mesma_g2, "n_cheg": n_cheg, "d14": d14, "mg": mg}


def sec_carreiras(n, K):
    perfis = []
    for cps in (5, 4, 3):
        perfis.append({"nome": "Boxe %d/s" % cps, "cps": cps, "arte": "boxing"})
        perfis.append({"nome": "Jiu-jitsu %d/s" % cps, "cps": cps, "arte": "bjj"})
    perfis.append({"nome": "Boxe 4/s, so luta no VERDE na academia", "cps": 4, "arte": "boxing", "estilo": "memoria ate_algoz caut_gym"})
    perfis.append({"nome": "Jiu-jitsu 4/s, so luta no VERDE na academia", "cps": 4, "arte": "bjj", "estilo": "memoria ate_algoz caut_gym"})
    perfis.append({"nome": "alterna (Boxe 1o) 4/s", "cps": 4, "arte": "alterna_b"})
    perfis.append({"nome": "alterna (Boxe 1o) 5/s", "cps": 5, "arte": "alterna_b"})
    perfis.append({"nome": "4b (base) 5/s", "cps": 5, "modo": "4b"})
    perfis.append({"nome": "4b (base) 4/s", "cps": 4, "modo": "4b"})
    perfis.append({"nome": "4b (base) 3/s", "cps": 3, "modo": "4b"})
    perfis = filtra(perfis)
    res = rodar_perfis(perfis, n, K)
    print("\n## Carreiras em sequencia (%d jogadores por perfil, %d carreiras; L1; arvore 'dica' + ESTILO)" % (n, K))
    print("| perfil | cinturao: carreira (med; p10-p90) | 1a chegada: carreira (med; p10-p90) | tempo de jogo ate a 1a chegada (med; p90) | cinturao->mudanca (med; pior) | G1: carreiras depois da chegada (med; p90) / min na carreira | G2: carreiras depois (med; p10-p90) / min | G2 na mesma carreira | criterio 14: inicio da carreira seguinte (med; p90) | tempo morto na academia (med; p90; pior) |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    det = {}
    for nome, seqs in res.items():
        r = resumo_seq(nome, seqs, K)
        det[nome] = seqs
        if "4b" in nome:
            print("| %s | %s (%s-%s) | - | - | - | - | - | - | - | - |" % (nome, fk(med(r["kb"])), fk(pct(r["kb"], .1)), fk(pct(r["kb"], .9))))
            continue
        print("| %s | %s (%s-%s) | %s (%s-%s) | %s; %s | %s; %s | %s (%s) / %s | %s (%s-%s) / %s | %d de %d (%.0f%%) | %s; %s | %s; %s; %s |" % (
            nome, fk(med(r["kb"])), fk(pct(r["kb"], .1)), fk(pct(r["kb"], .9)),
            fk(med(r["kc"])), fk(pct(r["kc"], .1)), fk(pct(r["kc"], .9)),
            mm(med(r["tc"])), mm(pct(r["tc"], .9)), mm(med(r["tm"])), mm(max(r["tm"]) if r["tm"] else None),
            fk(med(r["g1k"])), fk(pct(r["g1k"], .9)), mm(med(r["g1t"])),
            fk(med(r["g2k"])), fk(pct(r["g2k"], .1)), fk(pct(r["g2k"], .9)), mm(med(r["g2t"])),
            r["mesma_g2"], r["n_cheg"], 100.0 * r["mesma_g2"] / max(1, r["n_cheg"]),
            mm(med(r["d14"])), mm(pct(r["d14"], .9)),
            mm(med(r["mg"])), mm(pct(r["mg"], .9)), mm(max(r["mg"]) if r["mg"] else None)))
    # tempo ate o cinturao nas carreiras com arte (criterio 10)
    print("\n### Criterio 10: carreiras COM arte desde o minuto 0 (depois da 1a chegada)")
    print("| perfil | carreiras | cinturao (de n) | tempo ate o cinturao (med; p10-p90) | mudanca (med) | G1 vencido (de n; med) | G2 vencido (de n; med) | como acabam |")
    print("|---|---|---|---|---|---|---|---|")
    for nome, seqs in det.items():
        if "4b" in nome:
            continue
        rs = [r for s in seqs for r in s if r["arte"] and not r["primeira_chegada"]]
        tb = [r["t_belt"] for r in rs if r["t_belt"]]
        tmv = [r["t_move"] for r in rs if r["t_move"]]
        g1 = [r["t_g"]["opp_gym_1"] for r in rs if "opp_gym_1" in r["t_g"]]
        g2 = [r["t_g"]["opp_gym_2"] for r in rs if "opp_gym_2" in r["t_g"]]
        fins = {}
        for r in rs:
            kk = ("perde " + r["opp"].replace("opp_", "")) if r["fim"] == "derrota" else r["fim"]
            fins[kk] = fins.get(kk, 0) + 1
        print("| %s | %d | %d | %s (%s-%s) | %s | %d; %s | %d; %s | %s |" % (
            nome, len(rs), len(tb), mm(med(tb)), mm(pct(tb, .1)), mm(pct(tb, .9)), mm(med(tmv)),
            len(g1), mm(med(g1)), len(g2), mm(med(g2)), ", ".join("%s %d" % kv for kv in sorted(fins.items()))))
    print("\n### Carreira da 1a chegada (sem arte ate a mudanca): como acaba")
    print("| perfil | chegadas | cinturao (med) | mudanca->G1 (med; de n) | G1->G2 (med; de n) | como acaba |")
    print("|---|---|---|---|---|---|")
    for nome, seqs in det.items():
        if "4b" in nome:
            continue
        rs = [r for s in seqs for r in s if r["primeira_chegada"]]
        fins = {}
        for r in rs:
            kk = ("perde " + r["opp"].replace("opp_", "")) if r["fim"] == "derrota" else r["fim"]
            fins[kk] = fins.get(kk, 0) + 1
        a = [r["t_g"]["opp_gym_1"] - r["t_move"] for r in rs if "opp_gym_1" in r["t_g"]]
        b2 = [r["t_g"]["opp_gym_2"] - r["t_g"]["opp_gym_1"] for r in rs if "opp_gym_2" in r["t_g"]]
        print("| %s | %d | %s | %s; %d | %s; %d | %s |" % (nome, len(rs), mm(med([r["t_belt"] for r in rs])), mm(med(a)), len(a),
              mm(med(b2)), len(b2), ", ".join("%s %d" % kv for kv in sorted(fins.items()))))
    # regressoes F4/4b: tempo morto carreiras 1-4 e arvore
    print("\n### Regressoes: tempo morto por carreira (maior trecho; mediana / p90 / pior) e arvore")
    print("| perfil | carreira 1 | carreira 2 | carreira 3 | carreira 4 | arvore CORPO+CARREIRA fecha (med; p10-p90) | Legado medio por carreira (carreiras 2-8) |")
    print("|---|---|---|---|---|---|---|")
    base_ids = {nn["id"] for nn in DADOS[5]["nodes"] if not nn.get("requires_art")}
    for nome, seqs in det.items():
        cel = []
        for k in range(min(4, K)):
            mo = [s[k]["morto"] for s in seqs]
            cel.append("%s / %s / %s" % (mm(med(mo)), mm(pct(mo, .9)), mm(max(mo))))
        arv = [next((r["k"] for r in s if base_ids <= set(r["comprados"])), 99) for s in seqs]
        lg = med([sum(r["ganho"] for r in s[1:]) / max(1, len(s) - 1) for s in seqs])
        print("| %s | %s | %s (%s-%s) | %s |" % (nome, " | ".join(cel), fk(med(arv)), fk(pct(arv, .1)), fk(pct(arv, .9)), round(lg)))
    return det


def sec_controle(n):
    """Mesma carreira, mesmos nos, as duas artes desde o minuto 0 (criterio 10 controlado)."""
    R, treino, gens, shop, career, tree, unlocks, assist, P = DADOS
    nos_tip = {"body_jab", "career_purse", "body_muscle_memory", "career_scouting", "body_crew", "career_crowd"}
    if os.environ.get("SIM_CTRL_NOS") == "todos":
        nos_tip = {nn["id"] for nn in tree["nodes"] if not nn.get("requires_art")}
    casos = []
    for cps in (5, 4, 3):
        for arte in ("boxing", "bjj", None):
            casos.append((cps, arte, nos_tip, False))
    casos.append((0, "boxing", nos_tip, True))
    casos.append((0, "bjj", nos_tip, True))
    tarefas = [(cps, arte, sorted(nos), shift, 2000 + s) for (cps, arte, nos, shift) in casos for s in range(n)]
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    with Pool(proc, initializer=_init) as pool:
        res = pool.map(_controle_um, tarefas, chunksize=1)
    print("\n## Controle: 1 carreira com arte desde o minuto 0, nos %s (%d jogadores)" % (sorted(nos_tip), n))
    print("| perfil | cinturao (de n) | tempo ate o cinturao (med; p10-p90) | G1 (de n; med) | G2 (de n; med) | treino aos 10 min (med) | 5 min depois de mudar: mao/s / Metronomo/s / equipe/s (treino total) | como acaba |")
    print("|---|---|---|---|---|---|---|---|")
    i = 0
    tabela = {}
    for (cps, arte, nos, shift) in casos:
        rs = res[i:i + n]
        i += n
        tb = [r["t_belt"] for r in rs if r["t_belt"]]
        g1 = [r["g1"] for r in rs if r["g1"]]
        g2 = [r["g2"] for r in rs if r["g2"]]
        fins = {}
        for r in rs:
            fins[r["fim"]] = fins.get(r["fim"], 0) + 1
        nome = "%s %s/s%s" % ({"boxing": "Boxe", "bjj": "Jiu-jitsu", None: "sem arte"}[arte], cps, " (so assistido)" if shift else "")
        tabela[nome] = med(tb)
        sn = [r["snap"] for r in rs if r["snap"]]
        snt = ("%s / %s / %s (total %s)" % tuple(f3.k(med([x[i] for x in sn])) for i in range(4))) if sn else "-"
        print("| %s | %d | %s (%s-%s) | %d; %s | %d; %s | %s | %s | %s |" % (
            nome, len(tb), mm(med(tb)), mm(pct(tb, .1)), mm(pct(tb, .9)), len(g1), mm(med(g1)), len(g2), mm(med(g2)),
            f3.k(med([r["tr15"] for r in rs])), snt, ", ".join("%s %d" % kv for kv in sorted(fins.items()))))
    for cps in (5, 4, 3):
        b, j = tabela.get("Boxe %d/s" % cps), tabela.get("Jiu-jitsu %d/s" % cps)
        if b and j:
            print("- %d/s: Boxe %s, Jiu-jitsu %s -> diferenca %.1f%% (%s na frente)" % (
                cps, mm(b), mm(j), 100 * abs(b - j) / min(b, j), "Boxe" if b < j else "Jiu-jitsu"))


def _controle_um(args):
    cps, arte, nos, shift, semente = args
    R, treino, gens, shop, career, tree, unlocks, assist, P = DADOS
    b = f4.bonus_de(tree, set(nos))
    ids = {o["id"] for o in R.opp}
    sb = {"boxing": 0.5, "bjj": 0.5} if os.environ.get("SIM_CTRL_STYLE") == "1" else None
    c = Carreira5(R, treino, gens, shop, career, cps, "tipico", semente, b, unlocks, assist, P, arte=arte,
                  style_bonus=sb, regra_ap="asap", k=3, ritmo=f4b.ritmo_constante(cps), usa_shift=shift, limiar="equilibrado",
                  cauteloso_contra=(ids if CTRL_CAUT else set()), t_max=(150 * 60 if cps == 0 else T_MAX5))
    c.ultimo_algoz = None
    tr15 = None
    c.t_max = 600
    c.rodar()
    if c.fim and c.fim[0] == "parado" and c.t >= 600 - 1e-6:
        c.fim = None
    tr15 = sum(c.attr)
    tfim = (150 * 60 if cps == 0 else T_MAX5)
    snap = None
    while not c.fim and c.t < tfim - 1e-6:
        c.t_max = min(tfim, c.t + 30) if c.t_move is None else min(tfim, c.t_move + 300)
        c.rodar()
        if c.fim and c.fim[0] == "parado" and c.t < tfim - 1e-6:
            c.fim = None
        if c.t_move is not None and snap is None and c.t >= c.t_move + 300 - 1e-6:
            a = c.foco()
            snap = (c.clique_jogador_s(a), c.metro_s() * c.por_soco(a) * c.loc, c.passivo(), sum(c.attr))
            c.t_max = tfim
            c.rodar()
    return {"t_belt": c.t_belt, "g1": c.t_g.get("opp_gym_1"), "g2": c.t_g.get("opp_gym_2"), "snap": snap,
            "fim": (c.fim[2].replace("opp_", "perde ") if c.fim[0] == "derrota" else c.fim[0]), "tr15": tr15}


def sec_curvas():
    R, treino, gens, shop, career, tree, unlocks, assist, P = DADOS
    nos = {"body_jab", "career_purse", "body_muscle_memory", "career_scouting", "body_crew", "career_crowd"}
    if os.environ.get("SIM_CURVA_NOS") == "todos":
        nos = {nn["id"] for nn in tree["nodes"] if not nn.get("requires_art")}
    casos = [("sem arte, 1a chegada com Boxe, 5/s", 5, None, "boxing"),
             ("sem arte, 1a chegada com Jiu-jitsu, 5/s", 5, None, "bjj"),
             ("Boxe desde o minuto 0, 5/s", 5, "boxing", None),
             ("Jiu-jitsu desde o minuto 0, 5/s", 5, "bjj", None),
             ("Boxe desde o minuto 0, 3/s", 3, "boxing", None),
             ("Jiu-jitsu desde o minuto 0, 3/s", 3, "bjj", None)]
    for nome, cps, arte, cheg in casos:
        b = f4.bonus_de(tree, nos)
        c = Carreira5(R, treino, gens, shop, career, cps, "tipico", 4242, b, unlocks, assist, P, arte=arte,
                      arte_chegada=cheg, regra_ap="asap", k=3, ritmo=f4b.ritmo_constante(cps), limiar="equilibrado",
                      cauteloso_contra=set(), t_max=T_MAX5)
        c.ultimo_algoz = None
        marcos = [300, 600, 900, 1200, 1500, 1800, 2400, 3000]
        fotos = []
        while marcos and not c.fim:
            c.t_max = marcos.pop(0)
            c.rodar()
            if c.fim and c.fim[0] == "parado":
                c.fim = None
            w = c.pesos()
            a = c.foco()
            fotos.append((c.t, c.clique_jogador_s(a), c.metro_s() * c.por_soco(a) * c.loc, c.passivo(), tuple(c.attr),
                          c.vitorias, c.mudou, c.jj_bonus()))
        print("\n### Curva: %s (semente 4242, nos %d)" % (nome, len(nos)))
        print("| min | mao/s | Metronomo/s | equipe/s | Forca | Agilidade | Resistencia | vitorias | academia | bonus JJ |")
        print("|---|---|---|---|---|---|---|---|---|---|")
        for t, jg, mt, pa, at, v, mu, jj in fotos:
            print("| %d | %s | %s | %s | %s | %s | %s | %d | %s | %s |" % (
                round(t / 60), f3.k(jg), f3.k(mt), f3.k(pa), f3.k(at[0]), f3.k(at[1]), f3.k(at[2]), v,
                "sim" if mu else "-", ("+%.0f%%" % (100 * jj)) if c.arte == "bjj" else "-"))
        print("Marcos: " + "; ".join("%s %s" % (mm(t), e) for t, e in c.eventos
                                     if not e.startswith("melhoria") and not e.startswith("1o ")))
        print("Fim: %s" % (c.fim,) if not c.fim or c.fim[0] != "derrota" else "Fim: derrota %s aos %s" % (c.fim[2], mm(c.fim[1])))


def sec_assistido(n):
    perfis = filtra([
        {"nome": "so assistido, Boxe", "cps": 0, "shift": True, "arte": "boxing", "t_max": 150 * 60},
        {"nome": "so assistido, Jiu-jitsu", "cps": 0, "shift": True, "arte": "bjj", "t_max": 150 * 60},
    ])
    res = rodar_perfis(perfis, n, 6)
    print("\n## So assistido (%d jogadores, 6 carreiras, limite 150 min por carreira)" % n)
    print("| perfil | cinturao: carreira (med) | 1a chegada (med) | tempo ate o cinturao nas carreiras com arte (med) | G1 vencido (carreiras) | G2 vencido (carreiras) |")
    print("|---|---|---|---|---|---|")
    for nome, seqs in res.items():
        kb = [next((r["k"] for r in s if r["t_belt"]), 99) for s in seqs]
        kc = [next((r["k"] for r in s if r["primeira_chegada"]), 99) for s in seqs]
        tb = [r["t_belt"] for s in seqs for r in s if r["arte"] and not r["primeira_chegada"] and r["t_belt"]]
        g1 = sum(1 for s in seqs for r in s if "opp_gym_1" in r["t_g"])
        g2 = sum(1 for s in seqs for r in s if "opp_gym_2" in r["t_g"])
        print("| %s | %s | %s | %s (%d) | %d | %d |" % (nome, fk(med(kb)), fk(med(kc)), mm(med(tb)), len(tb), g1, g2))


def main():
    _init(quieto=False)
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    n = int(os.environ.get("SIM_N", "32"))
    K = int(os.environ.get("SIM_CARREIRAS", "8"))
    if tudo or "precos" in secs:
        sec_precos()
    if tudo or "curvas" in secs:
        sec_curvas()
    if tudo or "identidade" in secs:
        sec_identidade(int(os.environ.get("SIM_N_ID", "64")))
    if tudo or "b23" in secs:
        sec_b23(int(os.environ.get("SIM_N_23B", "400")))
    if tudo or "controle" in secs:
        sec_controle(int(os.environ.get("SIM_N_CTRL", "48")))
    if tudo or "assistido" in secs:
        sec_assistido(int(os.environ.get("SIM_N_ASS", "12")))
    if tudo or "carreiras" in secs:
        sec_carreiras(n, K)


if __name__ == "__main__":
    main()
