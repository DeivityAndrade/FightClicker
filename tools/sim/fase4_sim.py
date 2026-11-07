"""Simulacao da Fase 4 (Arvore de habilidades inicial + Metronomo) do Fightclicker.

Reaproveita tools/sim/fase3_sim.py (luta, previa, motivo, garagem, loja) e acrescenta:
  - a arvore (nos comprados com Legado entre carreiras) e seus bonus;
  - o Metronomo (item com niveis na LOJA: socos de verdade pelo caminho do clique);
  - carreiras em sequencia (o robo compra nos entre carreiras);
  - medicao de tempo morto (design fase4 secao 9).

Os valores propostos pelo design (docs/fases/fase4-design.md) estao em PROPOSTA, logo abaixo.
Enquanto data/ nao tiver os campos novos, o simulador usa PROPOSTA por cima dos JSON atuais.
Quando o Programador criar data/skill_tree.json e o bloco "metronome" em data/shop.json, eles
passam a valer (o que estiver no JSON ganha de PROPOSTA).

Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase4_sim.py [secao ...]
Secoes: precos, metronomo, curvas, revanche, carreiras, exemplos, tudo (padrao).
Variaveis: SIM_N (jogadores por perfil, padrao 24), SIM_CARREIRAS (padrao 8), SIM_N_REV (revanche, padrao 120),
  SIM_PROC (processos), SIM_PERFIS (filtro por nome, separado por ";"),
  SIM_OPP ("opp_fast.prize_money=800;opp_tank.endurance=430000") e SIM_TANK/SIM_FAST para testar alavancas.
Numeros do design: SIM_N=32 SIM_CARREIRAS=8 ... carreiras revanche
"""
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

RAIZ = f2.RAIZ
APAR = f3.APAR
ATTR = f3.ATTR

# ---------------------------------------------------------------- proposta do design (secoes 3 a 6)
PROPOSTA = {
    # Legado reescalado x10 (design secao 2). Proporcoes da Fase 3 intactas.
    "career": {"legacy_per_fame": 2.0, "belt_legacy_bonus": 100,
               "defeat_share": 0.5, "retire_share": 1.0, "retire_belt_bonus_share": 0.5},
    # Arvore: ramo, pre-requisito, custo (Legado x10), efeito {campo: valor somado}
    "skill_tree": {"nodes": [
        {"id": "body_jab",           "branch": "body",   "requires": "",                   "cost": 10,  "effect": {"click_bonus": 1.0}},
        {"id": "body_muscle_memory", "branch": "body",   "requires": "body_jab",           "cost": 30,  "effect": {"metronome_start": 1}},
        {"id": "body_heavy_hands",   "branch": "body",   "requires": "body_muscle_memory", "cost": 500, "effect": {"click_bonus": 0.5}},
        {"id": "body_crew",          "branch": "body",   "requires": "body_jab",           "cost": 150, "effect": {"passive_bonus": 0.5}},
        {"id": "body_crew_2",        "branch": "body",   "requires": "body_crew",          "cost": 900, "effect": {"passive_bonus": 0.5}},
        {"id": "career_purse",       "branch": "career", "requires": "",                   "cost": 10,  "effect": {"money_bonus": 0.5}},
        {"id": "career_scouting",    "branch": "career", "requires": "career_purse",       "cost": 25,  "effect": {"preview_percent": 1}},
        {"id": "career_purse_2",     "branch": "career", "requires": "career_scouting",    "cost": 500, "effect": {"money_bonus": 0.5}},
        {"id": "career_crowd",       "branch": "career", "requires": "career_purse",       "cost": 250, "effect": {"fame_bonus": 0.5}},
        {"id": "career_good_loser",  "branch": "career", "requires": "career_crowd",       "cost": 800, "effect": {"defeat_share_bonus": 0.25}},
    ]},
    # Ordem sugerida pelo Designer (robo "dica")
    "ordem_dica": ["body_jab", "career_purse", "body_muscle_memory", "career_scouting", "body_crew",
                   "career_crowd", "body_heavy_hands", "career_purse_2", "body_crew_2", "career_good_loser"],
    # Metronomo (LOJA, dinheiro). interval = segundos entre socos.
    "metronome": {"id": "metronome", "levels": [
        {"id": "metronome_l1", "cost": 80, "interval": 2.0},
        {"id": "metronome_l2", "cost": 150, "interval": 1.0},
        {"id": "metronome_l3", "cost": 300, "interval": 0.7},
    ]},
    # Ajustes da Fase 3 (design secao 10). {} = nada muda.
    "opponents": {"opp_fast": {"prize_money": 800}},
    "shop": {},
}

T_MAX = 60 * 60          # carreira parada ha 60 min sem fim: o robo aposenta
OVERHEAD = 60.0          # tela de fim + arvore + cartao, por troca de carreira (s), para o prototipo


def carregar(proposta=PROPOSTA, quieto=False):
    fights, a = f3.ler("fights.json", f3.PADRAO_FIGHTS)
    opps, b = f3.ler("opponents.json", f3.PADRAO_OPPONENTS)
    shop, c = f3.ler("shop.json", f3.PADRAO_SHOP)
    career, d = f3.ler("career.json", f3.PADRAO_CAREER)
    treino, e = f2.ler("training.json", f2.PADRAO_TREINO)
    gens, g = f2.ler("generators.json", f2.PADRAO_GERADORES)
    tree_p = os.path.join(RAIZ, "data", "skill_tree.json")
    fontes = [a, b, c, d, e, g]
    opps = json.loads(json.dumps(opps))
    shop = json.loads(json.dumps(shop))
    # proposta por cima do que ainda nao existe em data/
    if "metronome" not in shop:
        shop["metronome"] = proposta["metronome"]
        fontes.append("metronome da PROPOSTA")
    for gid, campos in proposta.get("shop", {}).items():
        for gg in shop["paid_generators"]:
            if gg["id"] == gid:
                gg.update(campos)
        for L in shop["gloves"]["levels"]:
            if L["id"] == gid:
                L.update(campos)
    for oid, campos in proposta.get("opponents", {}).items():
        for o in opps["opponents"]:
            if o["id"] == oid:
                o.update(campos)
    if os.environ.get("SIM_TANK"):
        F, A, Rr = (float(x) for x in os.environ["SIM_TANK"].split(","))
        for o in opps["opponents"]:
            if o["id"] == "opp_tank":
                o.update(strength=F, agility=A, endurance=Rr)
        fontes.append("opp_tank=%s" % os.environ["SIM_TANK"])
    if os.environ.get("SIM_OPP"):
        for item in os.environ["SIM_OPP"].split(";"):
            chave, v = item.split("=")
            oid, campo = chave.split(".")
            for o in opps["opponents"]:
                if o["id"] == oid:
                    o[campo] = float(v)
        fontes.append("SIM_OPP=%s" % os.environ["SIM_OPP"])
    if os.environ.get("SIM_FAST"):
        F, A, Rr = (float(x) for x in os.environ["SIM_FAST"].split(","))
        for o in opps["opponents"]:
            if o["id"] == "opp_fast":
                o.update(strength=F, agility=A, endurance=Rr)
        fontes.append("opp_fast=%s" % os.environ["SIM_FAST"])
    if os.path.exists(tree_p):
        with open(tree_p, encoding="utf-8") as f:
            tree = json.load(f)
        fontes.append("data/skill_tree.json")
    else:
        tree = proposta["skill_tree"]
        fontes.append("skill_tree da PROPOSTA")
    if career.get("legacy_per_fame", 0) < proposta["career"]["legacy_per_fame"]:
        career = dict(proposta["career"])
        fontes.append("career x10 da PROPOSTA")
    if not quieto:
        print("Fontes: %s" % ", ".join(fontes))
    return f3.Regras(fights, opps), treino, gens, shop, career, tree


# ---------------------------------------------------------------- bonus da arvore
def bonus_de(tree, comprados):
    b = {"click_bonus": 0.0, "passive_bonus": 0.0, "money_bonus": 0.0, "fame_bonus": 0.0,
         "metronome_start": 0, "preview_percent": 0, "defeat_share_bonus": 0.0}
    for n in tree["nodes"]:
        if n["id"] in comprados:
            ef = n["effect"]
            if "type" in ef:  # formato do data/skill_tree.json (design secao 10)
                ef = {ef["type"]: ef["value"]}
            for kk, v in ef.items():
                if kk == "metronome_start":
                    b[kk] = max(b[kk], int(v))
                else:
                    b[kk] += v
    return b


def disponiveis(tree, comprados, legado):
    out = []
    for n in tree["nodes"]:
        if n["id"] in comprados:
            continue
        if n["requires"] and n["requires"] not in comprados:
            continue
        if n["cost"] <= legado:
            out.append(n)
    return out


def comprar_nos(tree, comprados, legado, regra, ordem):
    comprados = set(comprados)
    while True:
        ops = disponiveis(tree, comprados, legado)
        if not ops:
            return comprados, legado
        if regra == "barato":
            n = min(ops, key=lambda x: (x["cost"], x["id"]))
        else:
            ids = [x["id"] for x in ops]
            n = None
            for oid in ordem:
                if oid in ids:
                    n = next(x for x in ops if x["id"] == oid)
                    break
        comprados.add(n["id"])
        legado -= n["cost"]


# ---------------------------------------------------------------- carreira com bonus e Metronomo
class Carreira4(f3.Carreira):
    def __init__(self, R, treino, gens, shop, career, cps, estr, semente, bonus, limiar="equilibrado",
                 dica=None, cauteloso_contra=None, metronomo=True, t_max=T_MAX, paciencia=None):
        super().__init__(R, treino, gens, shop, career, cps, estr, semente, limiar, dica=dica, t_max=t_max,
                         paciencia=paciencia, cauteloso_contra=cauteloso_contra)
        self.b = bonus
        self.metro_niveis = shop["metronome"]["levels"] if metronomo else []
        self.metro = min(bonus["metronome_start"], len(self.metro_niveis))
        self.metro_compras = []
        self.morto = 0.0          # trecho atual de tempo morto (perigoso + nada cabe na loja)
        self.morto_max = 0.0
        self.verm = 0.0           # trecho atual em perigoso, sem olhar a loja (R7)
        self.verm_max = 0.0
        self.perigoso = False
        self.t_revanche = None
        self.t_verde_killer = None
        self.dinheiro_total = 0.0

    # --- economia
    def metro_s(self):
        return 1.0 / self.metro_niveis[self.metro - 1]["interval"] if self.metro > 0 else 0.0

    def por_soco(self, a):
        return self.base * self.mult_ap(a) * self.mult_luva() * self.media_crit * (1 + self.b["click_bonus"])

    def clique_s(self, a):
        return (self.cps + self.metro_s()) * self.por_soco(a)

    def clique_jogador_s(self, a):
        return self.cps * self.por_soco(a)

    def passivo(self):
        return super().passivo() * (1 + self.b["passive_bonus"])

    def menor_preco_loja(self):
        ps = [f2.custo_gerador(g, self.pqtd[g["id"]]) for g in self.pgens]
        if self.luva < len(self.luvas):
            ps.append(float(self.luvas[self.luva]["cost"]))
        if self.metro < len(self.metro_niveis):
            ps.append(float(self.metro_niveis[self.metro]["cost"]))
        return min(ps)

    def comprar_loja(self):
        while True:
            ops = []
            for g in self.pgens:
                c = f2.custo_gerador(g, self.pqtd[g["id"]])
                ops.append((g["production"] * (1 + self.b["passive_bonus"]) / c, "pgen", g["id"], c))
            if self.luva < len(self.luvas):
                L = self.luvas[self.luva]
                ganho = self.clique_medio() * (L["click_multiplier"] - 1)
                ops.append((ganho / L["cost"], "luva", L["id"], float(L["cost"])))
            if self.metro < len(self.metro_niveis):
                M = self.metro_niveis[self.metro]
                novo = 1.0 / M["interval"]
                w = self.pesos()
                ganho = sum(self.por_soco(a) * w[a] for a in APAR) * (novo - self.metro_s())
                ops.append((ganho / M["cost"], "metro", M["id"], float(M["cost"])))
            if not ops:
                return
            ops.sort(reverse=True)
            _, tipo, id_, c = ops[0]
            if self.dinheiro + 1e-9 < c:
                # parado no vermelho, nao fica juntando: compra o melhor que cabe (design 9.1)
                cabe = [o for o in ops if o[3] <= self.dinheiro + 1e-9]
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

    # --- foco: 'dica' alterna saco e o aparelho da dica (Fase 3), 'saco' fixo.
    # reage=True: no vermelho, se a previa mostra "ELE E MUITO MAIS ..." (razao >= 2), alterna saco e esse aparelho.
    def foco(self):
        """Robo tipico da Fase 4 (design 9.1):
        - contra quem o derrotou na carreira anterior, alterna saco e o aparelho da dica da tela de fim;
        - depois da 1a vitoria, se o proximo esta PERIGOSO e a previa mostra "ELE E MUITO MAIS ..." num
          atributo que nao e Forca, alterna saco e esse aparelho (le a previa);
        - senao, saco."""
        if self.estr in ("tipico", "tipico_fase3"):
            if self.vitorias >= len(self.R.opp):
                return "punching_bag"
            o = self.R.opp[self.vitorias]
            if self.dica and o["id"] == getattr(self, "ultimo_algoz", None):
                par = ["punching_bag", APAR[ATTR.index(self.dica)]]
                if par[1] == par[0]:
                    par[1] = "treadmill"
                return par[int(self.t // 60) % 2]
            if self.estr == "tipico" and self.perigoso and self.vitorias >= 1:
                adv = self.adv()
                raz = [adv[i] / max(1.0, self.attr[i]) for i in range(3)]
                ordem = (2, 0, 1)
                i = max(ordem, key=lambda j: (raz[j], -ordem.index(j)))
                if raz[i] >= 2.0 and i != 0:
                    return ("punching_bag", APAR[i])[int(self.t // 60) % 2]
            return "punching_bag"
        return super().foco()

    def pesos(self):
        if self.estr in ("tipico", "tipico_fase3"):
            tot = sum(self.tempo_foco.values()) + 20.0
            return {a: (self.tempo_foco[a] + (20.0 if a == "punching_bag" else 0.0)) / tot for a in APAR}
        return super().pesos()

    # --- luta (igual a Fase 3 + bonus de dinheiro/fama + rotulo para o tempo morto)
    def talvez_lutar(self):
        if self.vitorias >= len(self.R.opp) or self.fim:
            self.perigoso = False
            return
        if self.t - self.ult_check_t < self.olhar:
            return
        self.ult_check_t = self.t
        jog = tuple(self.attr)
        adv = self.adv()
        o = self.R.opp[self.vitorias]
        even = self.R.risk["even_min"]
        easy = self.R.risk["easy_min"]
        lim = easy if self.limiar == "facil" else even
        cc = self.cauteloso_contra
        killer = (o["id"] in cc) if isinstance(cc, (set, frozenset, list, tuple)) else (cc == o["id"])
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
        self.attr[APAR.index(self.foco())] += g
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
                self.fim = ("cinturao", self.t)
            self.perigoso = False
        else:
            self.fim = ("derrota", self.t, o["id"], jog, tat)
            self.eventos.append((self.t, "PERDE " + o["id"]))

    def fechar_trechos(self):
        self.morto_max = max(self.morto_max, self.morto)
        self.verm_max = max(self.verm_max, self.verm)
        self.morto = 0.0
        self.verm = 0.0

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
            ap = getattr(self, "aposenta_vermelho", None)
            if ap and self.perigoso and self.verm >= ap and self.pote() > 0:
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
            self.talvez_lutar()
        self.fechar_trechos()
        if not self.fim:
            self.fim = ("parado", self.t)
        return self

    def pote(self):
        c = self.career
        return math.floor(self.fama * c["legacy_per_fame"] + 1e-9) + (c["belt_legacy_bonus"] if self.cinturao else 0)

    def legado_ganho(self):
        c = self.career
        pote = self.pote()
        if self.fim[0] == "derrota":
            return math.floor(pote * (c["defeat_share"] + self.b["defeat_share_bonus"]) + 1e-9)
        bonus = math.floor(pote * c["retire_belt_bonus_share"] + 1e-9) if self.cinturao else 0
        return math.floor(pote * c["retire_share"] + 1e-9) + bonus


# ---------------------------------------------------------------- sequencia de carreiras
def sequencia(args):
    """Um jogador jogando K carreiras seguidas. Devolve lista de dicts (uma por carreira)."""
    (cps, metronomo, regra, semente, K, estilo) = args
    R, treino, gens, shop, career, tree = DADOS
    comprados, legado = set(), 0
    killer, dica = None, None
    algozes = set()
    out = []
    for k in range(1, K + 1):
        b = bonus_de(tree, comprados)
        if not metronomo:
            b["metronome_start"] = 0
        estr = "tipico_fase3" if "fase3" in estilo else "tipico"
        if "cauteloso" in estilo and k >= 2:
            caut = {o["id"] for o in R.opp}
        elif "ate_algoz" in estilo and killer:
            # alavanca L1 (secao 11): "ESPERE FICAR VERDE" tambem contra quem vem antes do algoz na escada
            ik = next(i for i, o in enumerate(R.opp) if o["id"] == killer)
            caut = set(algozes) | {o["id"] for o in R.opp[:ik + 1]}
        elif "memoria" in estilo:
            caut = set(algozes)
        else:
            caut = {killer} if killer else set()
        c = Carreira4(R, treino, gens, shop, career, cps, estr, semente * 100 + k, b, "equilibrado",
                      dica=dica, cauteloso_contra=caut, metronomo=metronomo)
        c.ultimo_algoz = killer
        c.reage = "reage" in estilo
        if "aposenta" in estilo:
            c.aposenta_vermelho = 600.0
        c.rodar()
        ganho = c.legado_ganho()
        legado += ganho
        rec = {"k": k, "fim": c.fim[0], "t": c.fim[1], "opp": c.fim[2] if c.fim[0] == "derrota" else None,
               "killer_antes": killer, "revanche": c.t_revanche, "verde_killer": c.t_verde_killer,
               "morto": c.morto_max, "verm": c.verm_max, "ganho": ganho, "nos_antes": len(comprados),
               "metro": c.metro, "metro_compras": c.metro_compras, "vit": c.vitorias,
               "lutas": [(l["opp"], l["win"], round(l["p"], 2), round(l["t"])) for l in c.lutas],
               "dinheiro": c.dinheiro_total, "dica": dica}
        if c.fim[0] == "derrota":
            _, t, opp, jog, tat = c.fim
            o = next(x for x in R.opp if x["id"] == opp)
            attr, _, _ = R.motivo(jog, (o["strength"], o["agility"], o["endurance"]), tat, 100)
            dica = attr
            killer = opp
            algozes.add(opp)
        else:
            killer = None
        rec["dica_nova"] = dica
        comprados, legado = comprar_nos(tree, comprados, legado, regra, PROPOSTA["ordem_dica"])
        rec["nos_depois"] = len(comprados)
        rec["comprados"] = sorted(comprados)
        rec["legado_sobra"] = legado
        out.append(rec)
    return out


DADOS = None


def _init(quieto=True):
    global DADOS
    DADOS = carregar(quieto=quieto)


def rodar_perfis(perfis, n, K):
    tarefas = []
    for p in perfis:
        for s in range(n):
            tarefas.append((p["cps"], p["metro"], p["regra"], 1000 + s, K, p.get("estilo", "")))
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    with Pool(proc, initializer=_init) as pool:
        res = pool.map(sequencia, tarefas, chunksize=1)
    out = {}
    i = 0
    for p in perfis:
        out[p["nome"]] = res[i:i + n]
        i += n
    return out


def mediana(v):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    return v[len(v) // 2]


def pct(v, q):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    return v[min(len(v) - 1, int(q * len(v)))]


def mm(x):
    return "-" if x is None else f2.mmss(x)


# ---------------------------------------------------------------- secoes
def sec_precos(tree, career):
    print("\n## Precos dos nos x Legado (escala x10)")
    lpf, bb = career["legacy_per_fame"], career["belt_legacy_bonus"]
    fama = [0, 10, 40, 100, 200]
    pote = [math.floor(f * lpf) + (bb if i == 4 else 0) for i, f in enumerate(fama)]
    print("Pote por vitorias: %s; derrota no Brutao %d, no Dinho %d, no Muralha %d; cinturao+aposentar %d" % (
        pote, pote[1] // 2, pote[2] // 2, pote[3] // 2, pote[4] + pote[4] // 2))
    tot = sum(n["cost"] for n in tree["nodes"])
    cint = pote[4] + pote[4] // 2
    print("Custo total: %d; cinturao compra %.0f%%" % (tot, 100 * cint / tot))
    print("| id | ramo | requer | custo | efeito |")
    print("|---|---|---|---|---|")
    for n in tree["nodes"]:
        print("| %s | %s | %s | %d | %s |" % (n["id"], n["branch"], n["requires"] or "-", n["cost"], n["effect"]))
    # o que cada renda compra (regra 'barato')
    for nome, L in (("derrota no Brutao", pote[1] // 2), ("derrota no Dinho", pote[2] // 2),
                    ("derrota no Muralha", pote[3] // 2), ("cinturao+aposentar", cint)):
        c, sobra = comprar_nos(tree, set(), L, "barato", [])
        c2, sobra2 = comprar_nos(tree, set(), L, "dica", PROPOSTA["ordem_dica"])
        print("- %s (%d): barato compra %s (sobra %d); dica compra %s (sobra %d)" % (
            nome, L, sorted(c), sobra, sorted(c2), sobra2))


def sec_metronomo(R, treino, gens, shop, career, tree):
    print("\n## Metronomo: niveis e criterio 15 (treino de clique por segundo, mesmo aparelho/luva)")
    M = shop["metronome"]["levels"]
    print("| nivel | custo | intervalo | socos/s |")
    print("|---|---|---|---|")
    for i, L in enumerate(M):
        print("| %d | $%d | %.1f s | %.2f |" % (i + 1, L["cost"], L["interval"], 1 / L["interval"]))
    rmax = 1 / M[-1]["interval"]
    print("Ritmo maximo: %.2f socos/s" % rmax)
    for cps in (3, 4, 5):
        print("- %d cliques/s + Metronomo maximo: %.2f socos/s contra %.2f de quem so usa o Metronomo -> %.2fx" % (
            cps, cps + rmax, rmax, (cps + rmax) / rmax))


def sec_carreiras(n, K):
    perfis = [
        {"nome": "tipico 5/s, Metronomo, dica", "cps": 5, "metro": True, "regra": "dica", "estilo": "memoria"},
        {"nome": "tipico 4/s, Metronomo, dica", "cps": 4, "metro": True, "regra": "dica", "estilo": "memoria"},
        {"nome": "lento 3/s, Metronomo, dica", "cps": 3, "metro": True, "regra": "dica", "estilo": "memoria"},
        {"nome": "tipico 5/s, Metronomo, barato", "cps": 5, "metro": True, "regra": "barato", "estilo": "memoria"},
        {"nome": "tipico 4/s, Metronomo, barato", "cps": 4, "metro": True, "regra": "barato", "estilo": "memoria"},
        {"nome": "tipico 5/s, SEM Metronomo, dica", "cps": 5, "metro": False, "regra": "dica", "estilo": "memoria"},
        {"nome": "tipico 4/s, SEM Metronomo, dica", "cps": 4, "metro": False, "regra": "dica", "estilo": "memoria"},
        {"nome": "lento 3/s, SEM Metronomo, dica", "cps": 3, "metro": False, "regra": "dica", "estilo": "memoria"},
        {"nome": "tipico 5/s, Metronomo, dica, nao le a previa (robo da Fase 3)", "cps": 5, "metro": True, "regra": "dica", "estilo": "memoria fase3"},
        {"nome": "cauteloso 5/s, Metronomo, dica", "cps": 5, "metro": True, "regra": "dica", "estilo": "cauteloso"},
        {"nome": "cauteloso 4/s, Metronomo, dica", "cps": 4, "metro": True, "regra": "dica", "estilo": "cauteloso"},
        {"nome": "cauteloso 3/s, Metronomo, dica", "cps": 3, "metro": True, "regra": "dica", "estilo": "cauteloso"},
        {"nome": "tipico 5/s, Metronomo, dica, aposenta apos 10 min no vermelho", "cps": 5, "metro": True, "regra": "dica", "estilo": "memoria aposenta"},
        {"nome": "tipico 4/s, Metronomo, dica, aposenta apos 10 min no vermelho", "cps": 4, "metro": True, "regra": "dica", "estilo": "memoria aposenta"},
        {"nome": "tipico 5/s, Metronomo, dica, so a ultima derrota no verde", "cps": 5, "metro": True, "regra": "dica", "estilo": ""},
    ]
    so = os.environ.get("SIM_PERFIS")
    if so:
        perfis = [p for p in perfis if any(s in p["nome"] for s in so.split(";"))]
    res = rodar_perfis(perfis, n, K)
    print("\n## Carreiras em sequencia (%d jogadores por perfil, %d carreiras cada)" % (n, K))
    print("Robo tipico (design 9.1): treina no saco; depois da 1a vitoria, no vermelho, segue o destaque da previa;")
    print("contra o algoz da carreira anterior alterna saco e o aparelho da dica e so luta no VERDE; contra quem ja o")
    print("derrotou tambem espera o verde; contra os outros luta no amarelo. Cinturao: aposenta. %d min sem fim: aposenta." % (T_MAX // 60))
    print("\n### Resumo por perfil")
    print("ATENCAO: as colunas de revanche desta tabela sao SEM a alavanca L1 (referencia). O jogo aprovado (D2) usa L1;")
    print("a revanche que vale para o criterio 25 esta na secao revanche, perfis com alavanca L1.")
    print("| perfil | 1a derrota (mediana) | 1a carreira acaba em | cinturao: carreira (mediana; p10-p90) | cinturao na 1a antes de 40 min | revanche Dinho (2a carr., sem L1 - referencia) | revanche Muralha (2a carr., SEM L1 - referencia; o jogo aprovado usa L1: ver secao revanche) | arvore fecha na carreira (mediana; p10-p90) | prototipo itens 1-5 (mediana; p90) |")
    print("|---|---|---|---|---|---|---|---|---|")
    detalhes = {}
    for nome, seqs in res.items():
        d1 = [s[0]["t"] for s in seqs if s[0]["fim"] == "derrota"]
        fim1 = {}
        for s in seqs:
            kk = s[0]["opp"] or s[0]["fim"]
            fim1[kk] = fim1.get(kk, 0) + 1
        cint = []
        cint1_cedo = 0
        cint1_t = []
        for s in seqs:
            ck = next((r["k"] for r in s if r["fim"] == "cinturao"), None)
            cint.append(ck if ck else 99)
            if s[0]["fim"] == "cinturao" and s[0]["t"] < 40 * 60:
                cint1_cedo += 1
                cint1_t.append(s[0]["t"])
        rev = {"opp_fast": [0, 0], "opp_tank": [0, 0], "opp_strong": [0, 0], "opp_warmup": [0, 0]}
        proto = []
        for s in seqs:
            if s[0]["fim"] == "derrota" and len(s) > 1:
                kil = s[0]["opp"]
                rev[kil][1] += 1
                if s[1]["revanche"] is not None:
                    rev[kil][0] += 1
                    proto.append(s[0]["t"] + OVERHEAD + s[1]["revanche"])
                else:
                    proto.append(None)
        arv = []
        ntot = len(DADOS[5]["nodes"])
        for s in seqs:
            kk = next((r["k"] for r in s if r["nos_depois"] == ntot), None)
            arv.append(kk if kk else 99)
        p_ok = [x for x in proto if x is not None]
        fim1s = ", ".join("%s %d" % (kk.replace("opp_", ""), v) for kk, v in sorted(fim1.items()))
        print("| %s | %s | %s | %s (%s-%s) | %s | %d de %d | %d de %d | %s (%s-%s) | %s (%s); %d de %d fecham |" % (
            nome, mm(mediana(d1)), fim1s, fmtk(mediana(cint)), fmtk(pct(cint, .1)), fmtk(pct(cint, .9)),
            "%d de %d%s" % (cint1_cedo, len(seqs), (" (de %s a %s)" % (mm(min(cint1_t)), mm(max(cint1_t)))) if cint1_t else ""), rev["opp_fast"][0], rev["opp_fast"][1], rev["opp_tank"][0], rev["opp_tank"][1],
            fmtk(mediana(arv)), fmtk(pct(arv, .1)), fmtk(pct(arv, .9)),
            mm_p(mediana(proto_sem_none(proto))), mm_p(pct(proto_sem_none(proto), .9)), len(p_ok), len(proto)))
        detalhes[nome] = seqs
    print("\n### Tempo morto por carreira (maior trecho seguido; mediana / p90 / pior) e fim de cada carreira")
    print("Tempo morto = perigoso + na garagem + nada da LOJA cabe no dinheiro. 'Vermelho' = so perigoso (R7).")
    print("| perfil | carreira | tempo morto: mediana / p90 / pior | > 10 min | vermelho: mediana / p90 / pior | duracao (mediana) | fins | nos antes (mediana) | Metronomo no fim (mediana) |")
    print("|---|---|---|---|---|---|---|---|---|")
    for nome, seqs in detalhes.items():
        for k in range(K):
            rs = [s[k] for s in seqs]
            mo = [r["morto"] for r in rs]
            ve = [r["verm"] for r in rs]
            fins = {}
            for r in rs:
                kk = ("perde " + r["opp"].replace("opp_", "")) if r["fim"] == "derrota" else r["fim"]
                fins[kk] = fins.get(kk, 0) + 1
            print("| %s | %d | %s / %s / %s | %d | %s / %s / %s | %s | %s | %s | %s |" % (
                nome, k + 1, mm(mediana(mo)), mm(pct(mo, .9)), mm(max(mo)), sum(1 for x in mo if x > 600),
                mm(mediana(ve)), mm(pct(ve, .9)), mm(max(ve)), mm(mediana([r["t"] for r in rs])),
                ", ".join("%s %d" % (a, b) for a, b in sorted(fins.items())),
                fmtk(mediana([r["nos_antes"] for r in rs])), fmtk(mediana([r["metro"] for r in rs]))))
    return detalhes


def mm_p(x):
    return "nao fecha" if x is not None and x >= 1e8 else mm(x)


def proto_sem_none(v):
    return [x if x is not None else 1e9 for x in v]


def fmtk(x):
    if x is None:
        return "-"
    if x >= 99:
        return "nunca"
    if x >= 1e8:
        return "nao"
    return str(x)


def exemplo(seqs, i=0):
    s = seqs[i]
    for r in s:
        print("  carreira %d: %s aos %s; lutas %s; legado +%d; nos %d -> %d; Metronomo %d; morto %s; dica %s" % (
            r["k"], r["fim"] + ((" " + r["opp"]) if r["opp"] else ""), mm(r["t"]),
            " ".join("%s%s(%d%%,%s)" % (o.replace("opp_", ""), "+" if w else "x", round(100 * p), mm(t)) for o, w, p, t in r["lutas"]),
            r["ganho"], r["nos_antes"], r["nos_depois"], r["metro"], mm(r["morto"]), r["dica_nova"]))


def sec_revanche(n):
    """Criterio 25: 2a carreira, com os nos comprados com o Legado da 1a derrota, esperando o verde contra o algoz.
    Muitas sementes, so 2 carreiras. Conta separado por algoz."""
    perfis = [
        {"nome": "tipico 5/s (memoria)", "cps": 5, "metro": True, "regra": "dica", "estilo": "memoria"},
        {"nome": "tipico 4/s (memoria)", "cps": 4, "metro": True, "regra": "dica", "estilo": "memoria"},
        {"nome": "cauteloso 5/s", "cps": 5, "metro": True, "regra": "dica", "estilo": "cauteloso"},
        {"nome": "cauteloso 4/s", "cps": 4, "metro": True, "regra": "dica", "estilo": "cauteloso"},
        {"nome": "lento 3/s (memoria)", "cps": 3, "metro": True, "regra": "dica", "estilo": "memoria"},
        {"nome": "tipico 5/s, alavanca L1 (verde ate o algoz)", "cps": 5, "metro": True, "regra": "dica", "estilo": "memoria ate_algoz"},
        {"nome": "tipico 4/s, alavanca L1 (verde ate o algoz)", "cps": 4, "metro": True, "regra": "dica", "estilo": "memoria ate_algoz"},
        {"nome": "cauteloso 3/s", "cps": 3, "metro": True, "regra": "dica", "estilo": "cauteloso"},
    ]
    res = rodar_perfis(perfis, n, 2)
    print("\n## Criterio 25: revanche na 2a carreira (%d jogadores por perfil)" % n)
    print("| perfil | algoz | casos | venceu o algoz | quando (mediana) | o que deu errado nos outros | prototipo itens 1-5 (mediana; p90) |")
    print("|---|---|---|---|---|---|---|")
    for nome, seqs in res.items():
        grupos = {}
        for s in seqs:
            if s[0]["fim"] != "derrota":
                continue
            grupos.setdefault(s[0]["opp"], []).append(s)
        for opp in ("opp_warmup", "opp_strong", "opp_fast", "opp_tank"):
            g = grupos.get(opp, [])
            if not g:
                continue
            ok = [s for s in g if s[1]["revanche"] is not None]
            erros = {}
            for s in g:
                if s[1]["revanche"] is None:
                    kk = ("perdeu p/ " + s[1]["opp"].replace("opp_", "")) if s[1]["fim"] == "derrota" else s[1]["fim"]
                    erros[kk] = erros.get(kk, 0) + 1
            proto = [s[0]["t"] + OVERHEAD + s[1]["revanche"] if s[1]["revanche"] is not None else 1e9 for s in g]
            print("| %s | %s | %d | %d (%d%%) | %s | %s | %s (%s) |" % (
                nome, opp.replace("opp_", ""), len(g), len(ok), round(100 * len(ok) / len(g)),
                mm(mediana([s[1]["revanche"] for s in ok])),
                ", ".join("%s %d" % (a, b) for a, b in sorted(erros.items())) or "-",
                mm_p(mediana(proto)), mm_p(pct(proto, .9))))


def sec_curvas():
    R, treino, gens, shop, career, tree = DADOS
    casos = [("1a carreira (sem nos)", set()),
             ("2a carreira (body_jab + career_purse)", {"body_jab", "career_purse"}),
             ("arvore completa", {n["id"] for n in tree["nodes"]})]
    for cps in (5, 3):
        for nome, nos in casos:
            b = bonus_de(tree, nos)
            c = Carreira4(R, treino, gens, shop, career, cps, "tipico", 4242, b, "equilibrado",
                          cauteloso_contra=({o["id"] for o in R.opp} if nos else set()))
            c.ultimo_algoz = None
            c.reage = True
            marcos = [60, 180, 300, 600, 900, 1200, 1800]
            linhas = []
            while c.t < c.t_max and not c.fim and marcos:
                c.comprar_garagem(); c.comprar_loja()
                a = c.foco()
                g = (c.clique_s(a) + c.passivo()) * c.dt
                c.saldo += g; c.attr[APAR.index(a)] += g; c.tempo_foco[a] += c.dt
                c.t += c.dt
                while marcos and c.t >= marcos[0]:
                    m = marcos.pop(0)
                    w = c.pesos()
                    jog = sum(c.clique_jogador_s(x) * w[x] for x in APAR)
                    met = sum(c.metro_s() * c.por_soco(x) * w[x] for x in APAR)
                    linhas.append((m, jog, met, c.passivo(), sum(c.attr), c.vitorias, c.pqtd["gen_paid_1"], c.luva, c.metro))
                c.talvez_lutar()
            print("\n### Curva: %s, %d cliques/s (semente 4242)" % (nome, cps))
            print("| min | clique do jogador/s | Metronomo/s | passivo/s | treino total | vitorias | Prof. Nelson | luva | Metronomo |")
            print("|---|---|---|---|---|---|---|---|---|")
            for m, jg, mt, pa, tot, v, nel, lv, me in linhas:
                print("| %d | %s | %s | %s | %s | %d | %d | %d | %d |" % (m // 60, f3.k(jg), f3.k(mt), f3.k(pa), f3.k(tot), v, nel, lv, me))
            print("Marcos: " + "; ".join("%s %s" % (mm(t), e) for t, e in c.eventos))


def main():
    _init(quieto=False)
    R, treino, gens, shop, career, tree = DADOS
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    n = int(os.environ.get("SIM_N", "24"))
    K = int(os.environ.get("SIM_CARREIRAS", "8"))
    if tudo or "precos" in secs:
        sec_precos(tree, career)
    if tudo or "metronomo" in secs:
        sec_metronomo(R, treino, gens, shop, career, tree)
    if tudo or "curvas" in secs:
        sec_curvas()
    if tudo or "revanche" in secs:
        sec_revanche(int(os.environ.get("SIM_N_REV", "120")))
    if tudo or "carreiras" in secs:
        det = sec_carreiras(n, K)
        if "exemplos" in secs or tudo:
            for nome, seqs in det.items():
                print("\nExemplo: %s" % nome)
                exemplo(seqs, 0)
                exemplo(seqs, 1)


if __name__ == "__main__":
    main()
