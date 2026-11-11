"""Simulacao da Fase 4b (aparelhos que chegam + modo assistido no Shift) do Fightclicker.

Reaproveita tools/sim/fase4_sim.py (arvore, Metronomo, revanche, tempo morto), que reaproveita
fase3_sim.py (luta, previa, motivo, garagem, loja) e fase2_sim.py (custos).

O que entra (design docs/fases/fase4b-design.md):
  - toda carreira comeca so com o saco; esteira e corda sao compradas com Treino (preco fixo,
    a corda pede a esteira). Melhorias de aparelho nao comprado nao existem;
  - modo assistido: so enquanto o Shift esta pressionado, so com a mao parada ha >= still_seconds,
    1 soco a cada `interval` s pelo caminho do clique; some com o Metronomo nivel >= 1.

Valores propostos em PROPOSTA_4B. Se data/training.json tiver "unlock" nos aparelhos e o bloco
"assist", eles ganham da proposta. Variaveis de ambiente para testar alavancas:
  SIM_UNLOCK="750,2000"   (preco da esteira, preco da corda)
  SIM_ASSIST="3.0"        (intervalo do assistido, s)
  SIM_LUVA="7,12,45,90,7" (luva dourada: multiplicador, duracao do FRENESI, espera min, espera max, tempo na sala)
  SIM_PEGA="0.8,1.5"      (robo: fracao das luvas douradas que ele clica, tempo de reacao em s; "0" = ignora a luva)
  SIM_METRO="1.2,0.9,0.65,0.5,0.4"  (intervalos do Metronomo, por nivel; niveis a mais sao cortados)
  SIM_METRO_CUSTO="80,150,300,700,2000"
  SIM_UPS="300:3,5000:5,60000:4,800000:5"   (melhorias dos 3 aparelhos basicos: custo:multiplicador)
  SIM_UPS_ARTE="1500:3,15000:5,150000:4,2000000:5"  (tecnicas dos aparelhos de arte; usado pelo fase5_sim)

Rebalanceamento pos-PRs (2026-11-11): Metronomo (5 niveis), assistido, melhorias (4 niveis) e premio do Muralha
vem direto de data/. A LUVA DOURADA (FRENESI) e modelada aqui: de tempos em tempos ela aparece; o robo clica
nela numa fracao das vezes (SIM_PEGA) e, por `frenzy_seconds`, cliques e auto-socos (Metronomo e assistido)
valem x`frenzy_mult`. A equipe nao muda. Os numeros vem de data/training.json -> "golden_event"; se o bloco
faltar, valem as constantes de scripts/game_state.gd (PADRAO_LUVA).
Os 3 rounds sao so visuais (round_length nao entra no resultado; time_limit continua 16 s): nada a modelar.
  SIM_N, SIM_CARREIRAS, SIM_N_REV, SIM_PROC, SIM_PERFIS (como no fase4_sim)

Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase4b_sim.py [secao ...]
Secoes: precos, inicio, assistido, curvas, carreiras, revanche, tudo (padrao).
Numeros do design: SIM_N=32 SIM_CARREIRAS=8 SIM_N_REV=120 ... tudo
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
import fase4_sim as f4  # noqa: E402

APAR = f3.APAR
ATTR = f3.ATTR
BAG = "punching_bag"

PROPOSTA_4B = {
    # ordem de compra: esteira -> corda (respostas do dono). "requires" = aparelho que precisa estar comprado.
    "unlocks": [
        {"apparatus": "treadmill", "id": "unlock_treadmill", "cost": 500, "requires": ""},
        {"apparatus": "jump_rope", "id": "unlock_jump_rope", "cost": 1500, "requires": "treadmill"},
    ],
    # modo assistido (Shift pressionado). interval > intervalo do Metronomo nivel 1. (data/ ganha: hoje 1,5 s x 1,2 s)
    "assist": {"interval": 3.0, "still_seconds": 1.0, "first_delay": 1.0},
}
# Luva dourada / FRENESI. Padrao = constantes de scripts/game_state.gd (FRENESI_MULT, FRENESI_DURACAO, EVENTO_*).
PADRAO_LUVA = {"wait_min": 45.0, "wait_max": 90.0, "visible_seconds": 7.0, "frenzy_mult": 7.0, "frenzy_seconds": 12.0}
LUVA = dict(PADRAO_LUVA)
# Robo: clica em 80% das luvas, 1,5 s depois de ela aparecer (hipotese declarada; SIM_PEGA muda).
ROBO_LUVA = {"catch": 0.8, "react": 1.5}
TESTE_S = 10.0   # depois de comprar um aparelho o robo clica nele por 10 s (o foco vai para ele)


def carregar_4b(quieto=False):
    dados = f4.carregar(quieto=quieto)
    R, treino, gens, shop, career, tree = dados
    unlocks = json.loads(json.dumps(PROPOSTA_4B["unlocks"]))
    assist = dict(PROPOSTA_4B["assist"])
    fontes = []
    # aparelhos de arte (Fase 5) ficam de fora: quem cuida deles e o fase5_sim
    do_data = [a for a in treino["apparatus"] if isinstance(a.get("unlock"), dict) and not a.get("art")]
    if do_data:
        unlocks = [{"apparatus": a["id"], "id": a["unlock"].get("id", "unlock_" + a["id"]),
                    "cost": float(a["unlock"]["cost"]), "requires": a["unlock"].get("requires", "")} for a in do_data]
        fontes.append("unlock de data/training.json")
    else:
        fontes.append("unlock da PROPOSTA_4B")
    if isinstance(treino.get("assist"), dict):
        assist.update(treino["assist"])
        fontes.append("assist de data/training.json")
    else:
        fontes.append("assist da PROPOSTA_4B")
    if os.environ.get("SIM_UNLOCK"):
        ps = [float(x) for x in os.environ["SIM_UNLOCK"].split(",")]
        for u, p in zip(unlocks, ps):
            u["cost"] = p
        fontes.append("SIM_UNLOCK=%s" % os.environ["SIM_UNLOCK"])
    if os.environ.get("SIM_ASSIST"):
        assist["interval"] = float(os.environ["SIM_ASSIST"])
        fontes.append("SIM_ASSIST=%s" % os.environ["SIM_ASSIST"])
    # --- luva dourada
    LUVA.clear()
    LUVA.update(PADRAO_LUVA)
    if isinstance(treino.get("golden_event"), dict):
        LUVA.update({k: float(v) for k, v in treino["golden_event"].items() if k in PADRAO_LUVA})
        fontes.append("golden_event de data/training.json")
    else:
        fontes.append("luva dourada: constantes de game_state.gd")
    if os.environ.get("SIM_LUVA"):
        m, d, w0, w1, vis = (float(x) for x in os.environ["SIM_LUVA"].split(","))
        LUVA.update(frenzy_mult=m, frenzy_seconds=d, wait_min=w0, wait_max=w1, visible_seconds=vis)
        fontes.append("SIM_LUVA=%s" % os.environ["SIM_LUVA"])
    if os.environ.get("SIM_PEGA"):
        v = [float(x) for x in os.environ["SIM_PEGA"].split(",")]
        ROBO_LUVA["catch"] = v[0]
        if len(v) > 1:
            ROBO_LUVA["react"] = v[1]
        fontes.append("SIM_PEGA=%s" % os.environ["SIM_PEGA"])
    # --- alavancas de teste (nao mexem em data/)
    if os.environ.get("SIM_METRO") or os.environ.get("SIM_METRO_CUSTO"):
        niv = [dict(L) for L in shop["metronome"]["levels"]]
        if os.environ.get("SIM_METRO"):
            iv = [float(x) for x in os.environ["SIM_METRO"].split(",")]
            niv = niv[:len(iv)]
            for L, x in zip(niv, iv):
                L["interval"] = x
        if os.environ.get("SIM_METRO_CUSTO"):
            for L, x in zip(niv, os.environ["SIM_METRO_CUSTO"].split(",")):
                L["cost"] = float(x)
        shop["metronome"]["levels"] = niv
        fontes.append("SIM_METRO*")
    for var, de_arte in (("SIM_UPS", False), ("SIM_UPS_ARTE", True)):
        if os.environ.get(var):
            par = [x.split(":") for x in os.environ[var].split(",")]
            for a in treino["apparatus"]:
                if bool(a.get("art")) == de_arte:
                    a["upgrades"] = [dict(a["upgrades"][min(i, len(a["upgrades"]) - 1)], id="%s_up%d" % (a["id"], i + 1),
                                          cost=float(c), multiplier=float(m)) for i, (c, m) in enumerate(par)]
            fontes.append("%s=%s" % (var, os.environ[var]))
    if not quieto:
        print("Fontes 4b: %s" % ", ".join(fontes))
        print("Precos: %s; assistido: %s" % (", ".join("%s %d" % (u["id"], u["cost"]) for u in unlocks), assist))
        print("Metronomo: %s" % ", ".join("$%d %.2fs" % (L["cost"], L["interval"]) for L in shop["metronome"]["levels"]))
        print("Melhorias do saco: %s" % ", ".join("%d x%g" % (u["cost"], u["multiplier"])
              for u in next(a for a in treino["apparatus"] if a["id"] == BAG)["upgrades"]))
        print("Luva dourada: %s; robo pega %.0f%% (reacao %.1f s) -> clique e auto-soco x%.2f na media" % (
            LUVA, 100 * ROBO_LUVA["catch"], ROBO_LUVA["react"], fren_medio(ROBO_LUVA["catch"])))
    return dados + (unlocks, assist)


def fren_uptime(pega, react=None):
    """Fracao do tempo em FRENESI para quem clica em `pega` das luvas (o relogio da proxima corre durante o FRENESI)."""
    if pega <= 0:
        return 0.0
    react = ROBO_LUVA["react"] if react is None else react
    ciclo = (LUVA["wait_min"] + LUVA["wait_max"]) / 2.0 + pega * react + (1 - pega) * LUVA["visible_seconds"]
    return min(1.0, pega * LUVA["frenzy_seconds"] / ciclo)


def fren_medio(pega, react=None):
    return 1.0 + (LUVA["frenzy_mult"] - 1.0) * fren_uptime(pega, react)


# ---------------------------------------------------------------- ritmos de mao
def ritmo_constante(cps):
    return lambda t: cps


def ritmo_misto(cps=4, bloco=120.0, descanso=60.0):
    """Clica `cps` por `bloco` s e descansa `descanso` s (com o Shift, se o assistido estiver no perfil)."""
    ciclo = bloco + descanso
    return lambda t: cps if (t % ciclo) < bloco else 0


class Carreira4b(f4.Carreira4):
    def __init__(self, R, treino, gens, shop, career, cps, estr, semente, bonus, unlocks, assist,
                 regra_ap="asap", k=1, ritmo=None, usa_shift=False, pega=None, **kw):
        super().__init__(R, treino, gens, shop, career, cps, estr, semente, bonus, **kw)
        # luva dourada (FRENESI): sorteio proprio, nao mexe nos sorteios de luta
        self.pega = ROBO_LUVA["catch"] if pega is None else pega
        self.fren_med = fren_medio(self.pega)
        self.rng_ev = random.Random(semente * 7919 + 17)
        self.fren_rest = 0.0
        self.ev_vis = 0.0
        self.ev_pega = False
        self.ev_wait = self.rng_ev.uniform(LUVA["wait_min"], LUVA["wait_max"])
        self.t_fren = 0.0
        self.n_luvas = 0
        self.unlocks = unlocks
        self.assist_cfg = assist
        self.regra_ap = regra_ap          # "asap", "previa" ou "todos" (Fase 4: os 3 desde o minuto 0)
        self.k = k                        # numero da carreira (o robo da 2a em diante ja sabe)
        self.ritmo = ritmo or ritmo_constante(cps)
        self.usa_shift = usa_shift
        self.owned = set(APAR) if regra_ap == "todos" else {BAG}
        self.t_ap = {}
        self.quer = None
        self.teste_ate = -1.0
        self.teste_ap = None
        self.ocioso = 999.0
        self.acc = assist["interval"] - assist["first_delay"]
        self.n_assist = 0
        self.treino_clique = 0.0          # so a mao do jogador
        self.treino_assist = 0.0
        self.treino_metro = 0.0
        self.t_eventos = {}

    # --- luva dourada
    def por_soco(self, a):
        # valor ESPERADO do soco (com a media do FRENESI): e o que as decisoes de compra usam.
        # O ganho real de cada passo usa fren_passo() no lugar da media (ver rodar()).
        return f4.Carreira4.por_soco(self, a) * self.fren_med

    def fren_passo(self, dt):
        """Avanca o evento dourado em dt e devolve o fator deste passo sobre o soco ESPERADO (1/media ou mult/media)."""
        if self.pega <= 0:
            return 1.0
        m = LUVA["frenzy_mult"] if self.fren_rest > 0 else 1.0
        if self.fren_rest > 0:
            self.fren_rest = max(0.0, self.fren_rest - dt)
            self.t_fren += dt
        if self.ev_vis > 0:
            self.ev_vis -= dt
            if self.ev_vis <= 1e-9:
                self.ev_vis = 0.0
                if self.ev_pega:
                    self.fren_rest = LUVA["frenzy_seconds"]
                    self.n_luvas += 1
                self.ev_wait = self.rng_ev.uniform(LUVA["wait_min"], LUVA["wait_max"])
        else:
            self.ev_wait -= dt
            if self.ev_wait <= 0:
                self.ev_pega = self.rng_ev.random() < self.pega
                self.ev_vis = ROBO_LUVA["react"] if self.ev_pega else LUVA["visible_seconds"]
        return m / self.fren_med

    def fren_luta(self, dur):
        """Luta/previa: o FRENESI continua correndo (e se perde); o relogio da proxima luva espera."""
        self.fren_rest = max(0.0, self.fren_rest - dur)

    # --- mao do jogador agora
    def cps_agora(self):
        return self.ritmo(self.t)

    def assist_rate_nominal(self):
        if not self.usa_shift or self.metro > 0 or self.cps_agora() > 0:
            return 0.0
        return 1.0 / self.assist_cfg["interval"]

    def clique_s(self, a):
        # usado nas decisoes de compra (valor esperado, ritmo nominal do perfil); o ganho real e calculado em rodar()
        ass = 1.0 / self.assist_cfg["interval"] if (self.usa_shift and self.metro == 0 and self.cps == 0) else 0.0
        return (self.cps + self.metro_s() + ass) * self.por_soco(a)

    def clique_jogador_s(self, a):
        return self.cps_agora() * self.por_soco(a)

    def marca(self, nome):
        if nome not in self.t_eventos:
            self.t_eventos[nome] = self.t
            self.eventos.append((self.t, nome))

    # --- aparelhos
    def proximo_unlock(self):
        for u in self.unlocks:
            if u["apparatus"] in self.owned:
                continue
            if u["requires"] and u["requires"] not in self.owned:
                continue
            return u
        return None

    def deseja(self, u):
        if self.regra_ap == "todos" or u is None:
            return False
        if self.regra_ap == "asap":
            if self.k >= 2:
                return self.nivel[BAG] >= 1
            if u["requires"] == "":
                return self.nivel[BAG] >= 1          # 2o aparelho: assim que der depois da fita
            return self.nivel[BAG] >= 2              # 3o: assim que der depois da areia peneirada
        # "previa": so quando a previa (ou a dica da tela de fim) pede um aparelho que ele nao tem
        if self.quer is None or self.quer in self.owned:
            return False
        # compra a cadeia ate o aparelho pedido
        return True

    def comprar_garagem(self):
        u = self.proximo_unlock()
        if self.deseja(u):
            if self.saldo + 1e-9 < u["cost"]:
                return                               # junta para o aparelho (nao compra outra coisa)
            self.saldo -= u["cost"]
            self.owned.add(u["apparatus"])
            self.t_ap[u["apparatus"]] = self.t
            self.eventos.append((self.t, u["id"]))
            self.teste_ap, self.teste_ate = u["apparatus"], self.t + TESTE_S
        q0 = dict(self.qtd)
        n0 = dict(self.nivel)
        if self.clique_medio() + self.passivo() <= 0:
            return                                   # sem renda nenhuma: nada a comprar (nao clica nem usa Shift)
        super().comprar_garagem()
        for gid in self.qtd:
            if q0[gid] == 0 and self.qtd[gid] > 0:
                self.marca("1o " + gid)
        if sum(self.nivel.values()) > 0 and sum(n0.values()) == 0:
            self.marca("1a melhoria")

    def pesos(self):
        w = super().pesos()
        if any(a not in self.owned for a in APAR):
            for a in APAR:
                if a not in self.owned:
                    w[a] = 0.0
            s = sum(w.values()) or 1.0
            w = {a: v / s for a, v in w.items()}
        return w

    def foco(self):
        if self.t < self.teste_ate and self.teste_ap in self.owned:
            return self.teste_ap
        a = super().foco()
        if a not in self.owned:
            self.quer = a
            return BAG
        return a

    # --- laco principal (igual ao da Fase 4 + mao real, assistido e aparelhos)
    def rodar(self):
        dt = self.dt
        cfg = self.assist_cfg
        while self.t < self.t_max and not self.fim:
            self.comprar_garagem()
            self.comprar_loja()
            a = self.foco()
            cj = self.cps_agora()
            ps = self.por_soco(a) * self.fren_passo(dt)
            gc = cj * ps * dt
            gm = self.metro_s() * ps * dt
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
                    ga += ps
                    self.n_assist += 1
            else:
                self.acc = cfg["interval"] - cfg["first_delay"]
            g = gc + gm + ga + self.passivo() * dt
            self.treino_clique += gc
            self.treino_metro += gm
            self.treino_assist += ga
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
            t0 = self.t
            self.talvez_lutar()
            if self.t != t0:
                self.acc = cfg["interval"] - cfg["first_delay"]   # luta: o assistido para e recomeca
                self.fren_luta(self.t - t0)
        self.fechar_trechos()
        if not self.fim:
            self.fim = ("parado", self.t)
        return self


# ---------------------------------------------------------------- sequencia de carreiras
DADOS = None


def _init(quieto=True):
    global DADOS
    DADOS = carregar_4b(quieto=quieto)
    f4.DADOS = DADOS[:6]


def sequencia(args):
    (cps, metronomo, regra, semente, K, estilo, regra_ap, ritmo_nome, shift, t_max) = args
    R, treino, gens, shop, career, tree, unlocks, assist = DADOS
    ritmo = {"const": ritmo_constante(cps), "misto": ritmo_misto(cps)}[ritmo_nome]
    comprados, legado = set(), 0
    killer, dica = None, None
    algozes = set()
    out = []
    for k in range(1, K + 1):
        b = f4.bonus_de(tree, comprados)
        if not metronomo:
            b["metronome_start"] = 0
        estr = "tipico_fase3" if "fase3" in estilo else "tipico"
        if "cauteloso" in estilo and k >= 2:
            caut = {o["id"] for o in R.opp}
        elif "ate_algoz" in estilo and killer:
            ik = next(i for i, o in enumerate(R.opp) if o["id"] == killer)
            caut = set(algozes) | {o["id"] for o in R.opp[:ik + 1]}
        elif "memoria" in estilo:
            caut = set(algozes)
        else:
            caut = {killer} if killer else set()
        c = Carreira4b(R, treino, gens, shop, career, cps, estr, semente * 100 + k, b, unlocks, assist,
                       regra_ap=regra_ap, k=k, ritmo=ritmo, usa_shift=shift, limiar="equilibrado",
                       dica=dica, cauteloso_contra=caut, metronomo=metronomo, t_max=t_max)
        c.ultimo_algoz = killer
        if "aposenta" in estilo:
            c.aposenta_vermelho = 600.0
        # o fim da carreira anterior pediu um aparelho: no modo "previa" ele ja comeca querendo
        if regra_ap == "previa" and dica and dica != "strength":
            c.quer = APAR[ATTR.index(dica)]
        c.rodar()
        ganho = c.legado_ganho()
        legado += ganho
        vit_t = {}
        for t, e in c.eventos:
            if e.startswith("VENCE "):
                vit_t[e[6:]] = t
        lutas_t = {}
        for l in c.lutas:
            lutas_t.setdefault(l["opp"], l["t"])
        rec = {"k": k, "fim": c.fim[0], "t": c.fim[1], "opp": c.fim[2] if c.fim[0] == "derrota" else None,
               "killer_antes": killer, "revanche": c.t_revanche, "morto": c.morto_max, "verm": c.verm_max,
               "ganho": ganho, "nos_antes": len(comprados), "metro": c.metro, "vit": c.vitorias,
               "t_ap": dict(c.t_ap), "vit_t": vit_t, "luta1_t": lutas_t, "ev": dict(c.t_eventos),
               "treino_clique": c.treino_clique, "treino_assist": c.treino_assist, "treino_metro": c.treino_metro,
               "n_assist": c.n_assist, "metro_compras": list(c.metro_compras),
               "lutas": [(l["opp"], l["win"], round(l["p"], 2), round(l["t"])) for l in c.lutas]}
        if c.fim[0] == "derrota":
            _, t, opp, jog, tat = c.fim
            o = next(x for x in R.opp if x["id"] == opp)
            attr, _, _ = R.motivo(jog, (o["strength"], o["agility"], o["endurance"]), tat, 100)
            rec["dica_ap_faltando"] = (attr != "strength" and APAR[ATTR.index(attr)] not in c.owned)
            rec["dica_attr"] = attr
            dica = attr
            killer = opp
            algozes.add(opp)
        else:
            rec["dica_ap_faltando"] = False
            rec["dica_attr"] = None
            killer = None
        comprados, legado = f4.comprar_nos(tree, comprados, legado, regra, f4.PROPOSTA["ordem_dica"])
        rec["nos_depois"] = len(comprados)
        out.append(rec)
    return out


def rodar_perfis(perfis, n, K):
    tarefas = []
    for p in perfis:
        for s in range(n):
            tarefas.append((p["cps"], p.get("metro", True), p.get("regra", "dica"), 1000 + s, K,
                            p.get("estilo", "memoria"), p.get("ap", "asap"), p.get("ritmo", "const"),
                            p.get("shift", False), p.get("t_max", f4.T_MAX)))
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


def mm_ap(t):
    """Tempo ate ter os 2 aparelhos; None -> '-', sentinela 1e9 (nao comprou) -> 'nao'."""
    if t is None:
        return "-"
    if t >= 1e8:
        return "nao"
    return mm(t)


def filtra(perfis):
    so = os.environ.get("SIM_PERFIS")
    if so:
        perfis = [p for p in perfis if any(s in p["nome"] for s in so.split(";"))]
    return perfis


# ---------------------------------------------------------------- secoes
def sec_precos():
    R, treino, gens, shop, career, tree, unlocks, assist = DADOS
    print("\n## Precos dos aparelhos e regras do assistido")
    for u in unlocks:
        print("- %s (%s): %d de Treino; pede '%s'" % (u["id"], u["apparatus"], u["cost"], u["requires"] or "-"))
    clk = treino["click"]
    mc = 1 + clk["crit_chance"] * (clk["crit_multiplier"] - 1)
    L1 = shop["metronome"]["levels"][0]["interval"]
    print("- assistido: 1 soco a cada %.1f s (Metronomo 1: %.1f s); mao parada %.1f s; 1o soco %.1f s depois de ativar" % (
        assist["interval"], L1, assist["still_seconds"], assist["first_delay"]))
    for cps in (3, 4, 5):
        print("  - %d cliques/s rende %.1fx o assistido (mesmo aparelho/luva)" % (cps, cps * assist["interval"]))
    print("  - media do critico %.2f; assistido com saco cru = %.2f treino/s" % (mc, mc / assist["interval"]))


def resumo_inicio(nome, seqs, base=None):
    """Metas do comeco da 1a carreira (Fase 2, Fase 3 e 4b)."""
    c1 = [s[0] for s in seqs]
    def col(f):
        v = [f(r) for r in c1]
        return v
    est = col(lambda r: r["t_ap"].get("treadmill"))
    cor = col(lambda r: r["t_ap"].get("jump_rope"))
    viz = col(lambda r: r["ev"].get("1o neighbor_kid"))
    mel = col(lambda r: r["ev"].get("1a melhoria"))
    tio = col(lambda r: r["ev"].get("1o retired_uncle"))
    dud = col(lambda r: r["vit_t"].get("opp_warmup"))
    bru_luta = col(lambda r: r["luta1_t"].get("opp_strong"))
    din_luta = col(lambda r: r["luta1_t"].get("opp_fast"))
    # os dois antes da luta com o Brutao / Dinho (so conta quem chegou a lutar)
    def antes(luta, r):
        if luta is None:
            return None
        tc = r["t_ap"].get("jump_rope")
        return tc is not None and tc <= luta
    ab = [antes(r["luta1_t"].get("opp_strong"), r) for r in c1]
    ad = [antes(r["luta1_t"].get("opp_fast"), r) for r in c1]
    ab = [x for x in ab if x is not None]
    ad = [x for x in ad if x is not None]
    return {"nome": nome, "viz": med(viz), "mel": med(mel), "tio": med(tio), "tio_p10": pct(tio, .1), "tio_p90": pct(tio, .9),
            "est": med(est), "est_p90": pct(est, .9), "cor": med(cor), "cor_p90": pct(cor, .9),
            "dud": med(dud), "bru": med(bru_luta), "din": med(din_luta),
            "ab": (sum(ab), len(ab)), "ad": (sum(ad), len(ad))}


def sec_inicio(n):
    perfis = filtra([
        {"nome": "Fase 4 (3 aparelhos no minuto 0), 5/s", "cps": 5, "ap": "todos"},
        {"nome": "Fase 4 (3 aparelhos no minuto 0), 4/s", "cps": 4, "ap": "todos"},
        {"nome": "Fase 4 (3 aparelhos no minuto 0), 3/s", "cps": 3, "ap": "todos"},
        {"nome": "4b asap, 5/s", "cps": 5, "ap": "asap"},
        {"nome": "4b asap, 4/s", "cps": 4, "ap": "asap"},
        {"nome": "4b asap, 3/s", "cps": 3, "ap": "asap"},
        {"nome": "4b previa, 5/s", "cps": 5, "ap": "previa"},
        {"nome": "4b previa, 4/s", "cps": 4, "ap": "previa"},
        {"nome": "4b previa, 3/s", "cps": 3, "ap": "previa"},
    ])
    res = rodar_perfis(perfis, n, 1)
    print("\n## Comeco da 1a carreira (%d jogadores por perfil; robo tipico, sem nos)" % n)
    print("| perfil | 1o vizinho | 1a melhoria | tio (med; p10-p90) | esteira (med; p90) | corda (med; p90) | vence Dudu | luta Brutao | luta Dinho | 2 aparelhos antes do Brutao | idem antes do Dinho |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for nome, seqs in res.items():
        r = resumo_inicio(nome, seqs)
        print("| %s | %s | %s | %s (%s-%s) | %s (%s) | %s (%s) | %s | %s | %s | %d de %d | %d de %d |" % (
            nome, mm(r["viz"]), mm(r["mel"]), mm(r["tio"]), mm(r["tio_p10"]), mm(r["tio_p90"]),
            mm(r["est"]), mm(r["est_p90"]), mm(r["cor"]), mm(r["cor_p90"]), mm(r["dud"]), mm(r["bru"]), mm(r["din"]),
            r["ab"][0], r["ab"][1], r["ad"][0], r["ad"][1]))


def sec_carreiras(n, K):
    perfis = filtra([
        {"nome": "Fase 4, tipico 5/s", "cps": 5, "ap": "todos"},
        {"nome": "Fase 4, tipico 4/s", "cps": 4, "ap": "todos"},
        {"nome": "Fase 4, lento 3/s", "cps": 3, "ap": "todos"},
        {"nome": "4b, tipico 5/s", "cps": 5},
        {"nome": "4b, tipico 4/s", "cps": 4},
        {"nome": "4b, lento 3/s", "cps": 3},
        {"nome": "4b, tipico 5/s, Shift sempre (mao parada)", "cps": 5, "shift": True},
        {"nome": "4b previa, tipico 5/s", "cps": 5, "ap": "previa"},
        {"nome": "4b previa, tipico 4/s", "cps": 4, "ap": "previa"},
        {"nome": "4b, misto 4/s (2 min clica, 1 min Shift)", "cps": 4, "ritmo": "misto", "shift": True},
        {"nome": "4b, misto 4/s sem Shift (descansa parado)", "cps": 4, "ritmo": "misto"},
    ])
    res = rodar_perfis(perfis, n, K)
    print("\n## Carreiras em sequencia (%d jogadores por perfil, %d carreiras)" % (n, K))
    print("| perfil | 1a derrota (mediana) | 1a carreira acaba em | cinturao: carreira (med; p10-p90) | cinturao na 1a (n; mais cedo) | arvore fecha (med; p10-p90) | aparelhos nas carreiras 2+ (mediana; p90; pior) | dica aponta aparelho nao comprado | treino total 1a carreira (mediana) |")
    print("|---|---|---|---|---|---|---|---|---|")
    det = {}
    for nome, seqs in res.items():
        d1 = [s[0]["t"] for s in seqs if s[0]["fim"] == "derrota"]
        fim1 = {}
        for s in seqs:
            kk = s[0]["opp"] or s[0]["fim"]
            fim1[kk] = fim1.get(kk, 0) + 1
        cint = [next((r["k"] for r in s if r["fim"] == "cinturao"), 99) for s in seqs]
        c1 = [s[0]["t"] for s in seqs if s[0]["fim"] == "cinturao"]
        ntot = len(DADOS[5]["nodes"])
        arv = [next((r["k"] for r in s if r["nos_depois"] == ntot), 99) for s in seqs]
        ap2 = []
        # Fase 4 ("todos"): os 3 aparelhos ja vem no minuto 0 -> coluna nao se aplica ("-")
        todos = next(p for p in perfis if p["nome"] == nome).get("ap") == "todos"
        for s in ([] if todos else seqs):
            for r in s[1:]:
                if len(r["t_ap"]) == 2:
                    ap2.append(max(r["t_ap"].values()))
                elif r["fim"] != "derrota" or r["t"] > 600:
                    ap2.append(1e9)
        falta = sum(1 for s in seqs for r in s if r["dica_ap_faltando"])
        nder = sum(1 for s in seqs for r in s if r["fim"] == "derrota")
        tot1 = med([s[0]["treino_clique"] + s[0]["treino_assist"] + s[0]["treino_metro"] for s in seqs])
        print("| %s | %s | %s | %s (%s-%s) | %d%s | %s (%s-%s) | %s; %s; %s | %d de %d derrotas | %s |" % (
            nome, mm(med(d1)), ", ".join("%s %d" % (kk.replace("opp_", ""), v) for kk, v in sorted(fim1.items())),
            f4.fmtk(med(cint)), f4.fmtk(pct(cint, .1)), f4.fmtk(pct(cint, .9)),
            len(c1), (" (%s)" % mm(min(c1))) if c1 else "",
            f4.fmtk(med(arv)), f4.fmtk(pct(arv, .1)), f4.fmtk(pct(arv, .9)),
            mm_ap(med(ap2)), mm_ap(pct(ap2, .9)), mm_ap(max(ap2) if ap2 else None),
            falta, nder, f3.k(tot1) if tot1 else "-"))
        det[nome] = seqs
    print("\n### Tempo morto (maior trecho seguido; mediana / p90 / pior; acima de 10 min)")
    print("| perfil | carreira 1 | carreira 2 | carreira 3 | carreira 4 |")
    print("|---|---|---|---|---|")
    for nome, seqs in det.items():
        cel = []
        for k in range(min(4, K)):
            mo = [s[k]["morto"] for s in seqs]
            cel.append("%s / %s / %s (%d)" % (mm(med(mo)), mm(pct(mo, .9)), mm(max(mo)), sum(1 for x in mo if x > 600)))
        print("| %s | %s |" % (nome, " | ".join(cel)))
    return det


def sec_revanche(n):
    perfis = filtra([
        {"nome": "Fase 4, tipico 5/s, L1", "cps": 5, "ap": "todos", "estilo": "memoria ate_algoz"},
        {"nome": "Fase 4, tipico 4/s, L1", "cps": 4, "ap": "todos", "estilo": "memoria ate_algoz"},
        {"nome": "4b, tipico 5/s, L1", "cps": 5, "estilo": "memoria ate_algoz"},
        {"nome": "4b, tipico 4/s, L1", "cps": 4, "estilo": "memoria ate_algoz"},
        {"nome": "4b, lento 3/s, L1", "cps": 3, "estilo": "memoria ate_algoz"},
        {"nome": "4b previa, tipico 4/s, L1", "cps": 4, "ap": "previa", "estilo": "memoria ate_algoz"},
    ])
    res = rodar_perfis(perfis, n, 2)
    print("\n## Revanche na 2a carreira (%d jogadores por perfil, alavanca L1)" % n)
    print("| perfil | algoz | casos | venceu | quando (mediana) | outros | prototipo (mediana; p90) | 1a carreira: derrota (mediana) | cinturao na 1a (de n; mais cedo) |")
    print("|---|---|---|---|---|---|---|---|---|")
    for nome, seqs in res.items():
        d1 = [s[0]["t"] for s in seqs if s[0]["fim"] == "derrota"]
        c1 = [s[0]["t"] for s in seqs if s[0]["fim"] == "cinturao"]
        grupos = {}
        for s in seqs:
            if s[0]["fim"] == "derrota":
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
            proto = [s[0]["t"] + f4.OVERHEAD + s[1]["revanche"] if s[1]["revanche"] is not None else 1e9 for s in g]
            print("| %s | %s | %d | %d (%d%%) | %s | %s | %s (%s) | %s | %d de %d%s |" % (
                nome, opp.replace("opp_", ""), len(g), len(ok), round(100 * len(ok) / len(g)),
                mm(med([s[1]["revanche"] for s in ok])), ", ".join("%s %d" % kv for kv in sorted(erros.items())) or "-",
                f4.mm_p(med(proto)), f4.mm_p(pct(proto, .9)), mm(med(d1)), len(c1), len(seqs),
                (" (%s)" % mm(min(c1))) if c1 else ""))


def sec_assistido(n):
    """Perfil 'so assistido' (nao clica), 'misto' e eficiencia (criterio 24)."""
    T2 = 180 * 60
    perfis = filtra([
        {"nome": "so assistido (nao clica), Metronomo", "cps": 0, "shift": True, "t_max": T2},
        {"nome": "so assistido (nao clica), SEM Metronomo", "cps": 0, "shift": True, "metro": False, "t_max": T2},
        {"nome": "nao clica e nao usa Shift (so geradores)", "cps": 0, "shift": False, "t_max": T2},
    ])
    res = rodar_perfis(perfis, n, 2)
    print("\n## Perfil 'so assistido' (%d jogadores; 2 carreiras; limite %d min por carreira)" % (n, T2 // 60))
    print("| perfil | carreira | esteira | corda | 1o vizinho | fita | vence Dudu | vence Brutao | vence Dinho | Metronomo 1 | como acaba | maior tempo morto (med; p90) | treino do assistido / do Metronomo / passivo ate o fim |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for nome, seqs in res.items():
        for k in range(2):
            rs = [s[k] for s in seqs]
            fins = {}
            for r in rs:
                kk = ("perde " + r["opp"].replace("opp_", "")) if r["fim"] == "derrota" else r["fim"]
                fins[kk] = fins.get(kk, 0) + 1
            def mv(f):
                v = [f(r) for r in rs]
                ok = [x for x in v if x is not None]
                return "%s (%d de %d)" % (mm(med(ok)), len(ok), len(v)) if ok else "nunca"
            ta = med([r["treino_assist"] for r in rs])
            tm = med([r["treino_metro"] for r in rs])
            print("| %s | %d | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s / %s | %s / %s |" % (
                nome, k + 1, mv(lambda r: r["t_ap"].get("treadmill")), mv(lambda r: r["t_ap"].get("jump_rope")),
                mv(lambda r: r["ev"].get("1o neighbor_kid")), mv(lambda r: r["ev"].get("1a melhoria")),
                mv(lambda r: r["vit_t"].get("opp_warmup")), mv(lambda r: r["vit_t"].get("opp_strong")),
                mv(lambda r: r["vit_t"].get("opp_fast")), mv(lambda r: r["metro_compras"][0] if r["metro_compras"] else None),
                ", ".join("%s %d" % kv for kv in sorted(fins.items())),
                mm(med([r["morto"] for r in rs])), mm(pct([r["morto"] for r in rs], .9)),
                f3.k(ta), f3.k(tm)))
    # eficiencia: treino de clique por segundo antes do Metronomo, mesmo estado
    R, treino, gens, shop, career, tree, unlocks, assist = DADOS
    print("\n### Eficiencia (criterio 24): treino de clique por segundo antes do Metronomo")
    clk = treino["click"]
    mc = 1 + clk["crit_chance"] * (clk["crit_multiplier"] - 1)
    for cps in (4, 4.5, 5):
        print("- %.1f cliques/s: %.2f socos/s contra %.3f do assistido -> %.1fx" % (
            cps, cps, 1 / assist["interval"], cps * assist["interval"]))
    # medido na simulacao: treino de clique (jogador) nos primeiros 10 min do tipico x treino do assistido no so assistido
    print("(medido na curva: ver secao curvas)")


def sec_curvas():
    R, treino, gens, shop, career, tree, unlocks, assist = DADOS
    casos = [("1a carreira, 4b, 5/s", 5, "asap", "const", False, set()),
             ("1a carreira, Fase 4, 5/s", 5, "todos", "const", False, set()),
             ("1a carreira, 4b, 3/s", 3, "asap", "const", False, set()),
             ("2a carreira (jab + bolsa), 4b, 5/s", 5, "asap", "const", False, {"body_jab", "career_purse"}),
             ("1a carreira, so assistido", 0, "asap", "const", True, set()),
             ("1a carreira, misto 4/s", 4, "asap", "misto", True, set())]
    for nome, cps, ap, rit, shift, nos in casos:
        b = f4.bonus_de(tree, nos)
        ritmo = ritmo_constante(cps) if rit == "const" else ritmo_misto(cps)
        c = Carreira4b(R, treino, gens, shop, career, cps, "tipico", 4242, b, unlocks, assist, regra_ap=ap,
                       k=2 if nos else 1, ritmo=ritmo, usa_shift=shift, limiar="equilibrado",
                       cauteloso_contra=({o["id"] for o in R.opp} if nos else set()), t_max=(90 * 60 if cps == 0 else f4.T_MAX))
        c.ultimo_algoz = None
        marcos = [60, 120, 180, 300, 600, 900, 1200] + ([1800, 2700, 3600, 5400] if cps == 0 else [])
        fotos = []
        ult = (0.0, 0.0, 0.0)
        # roda passo a passo tirando fotos (reaproveita o laco: t_max curto em fatias)
        while marcos and not c.fim:
            c.t_max = marcos[0]
            c.rodar_fatia()
            if c.t >= marcos[0] - 1e-6:
                m = marcos.pop(0)
                tc, ta, tm = c.treino_clique, c.treino_assist, c.treino_metro
                fotos.append((m, tc, ta, tm, c.passivo(), sum(c.attr), c.vitorias, sorted(c.owned), c.luva, c.metro))
        print("\n### Curva: %s (semente 4242)" % nome)
        print("| min | treino da mao (acum.) | assistido (acum.) | Metronomo (acum.) | passivo/s | treino total | vitorias | aparelhos | luva | Metronomo |")
        print("|---|---|---|---|---|---|---|---|---|---|")
        for m, tc, ta, tm, pa, tot, v, ow, lv, me in fotos:
            print("| %d | %s | %s | %s | %s | %s | %d | %d | %d | %d |" % (m // 60, f3.k(tc), f3.k(ta), f3.k(tm), f3.k(pa), f3.k(tot), v, len(ow), lv, me))
        print("Marcos: " + "; ".join("%s %s" % (mm(t), e) for t, e in c.eventos if not e.startswith("melhoria ") or True))


def _rodar_fatia(self):
    """rodar() sem fechar a carreira quando bate em t_max (para tirar fotos)."""
    fim_antes = self.fim
    dt = self.dt
    cfg = self.assist_cfg
    while self.t < self.t_max - 1e-9 and not self.fim:
        self.comprar_garagem()
        self.comprar_loja()
        a = self.foco()
        cj = self.cps_agora()
        ps = self.por_soco(a) * self.fren_passo(dt)
        gc = cj * ps * dt
        gm = self.metro_s() * ps * dt
        ga = 0.0
        self.ocioso = 0.0 if cj > 0 else self.ocioso + dt
        ativo = self.usa_shift and self.metro == 0 and cj == 0 and self.ocioso >= cfg["still_seconds"]
        if ativo:
            self.acc += dt
            while self.acc >= cfg["interval"] - 1e-9:
                self.acc -= cfg["interval"]
                ga += ps
                self.n_assist += 1
        else:
            self.acc = cfg["interval"] - cfg["first_delay"]
        g = gc + gm + ga + self.passivo() * dt
        self.treino_clique += gc
        self.treino_metro += gm
        self.treino_assist += ga
        self.saldo += g
        self.attr[APAR.index(a)] += g
        self.tempo_foco[a] += dt
        self.t += dt
        if self.perigoso:
            self.verm += dt
        else:
            self.fechar_trechos()
        t0 = self.t
        self.talvez_lutar()
        if self.t != t0:
            self.acc = cfg["interval"] - cfg["first_delay"]
            self.fren_luta(self.t - t0)
    return fim_antes


Carreira4b.rodar_fatia = _rodar_fatia


def main():
    _init(quieto=False)
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    n = int(os.environ.get("SIM_N", "24"))
    K = int(os.environ.get("SIM_CARREIRAS", "8"))
    if tudo or "precos" in secs:
        sec_precos()
    if tudo or "curvas" in secs:
        sec_curvas()
    if tudo or "inicio" in secs:
        sec_inicio(int(os.environ.get("SIM_N_INI", str(max(n, 48)))))
    if tudo or "assistido" in secs:
        sec_assistido(int(os.environ.get("SIM_N_ASS", "16")))
    if tudo or "revanche" in secs:
        sec_revanche(int(os.environ.get("SIM_N_REV", "120")))
    if tudo or "carreiras" in secs:
        sec_carreiras(n, K)


if __name__ == "__main__":
    main()
