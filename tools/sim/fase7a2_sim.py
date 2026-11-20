"""Simulacao da Fase 7a2 (Treino fora de hora): Choque (Boxe/JJ), Panfletagem, AQUECIDO e o teto de 10% na campanha.

Design: docs/fases/fase7a2-design.md. Valores: data/minigames.json. Reaproveita fase7a1_sim.py (campanha com arte,
passivas, calendario, arvore, Honra e hall) e so ACRESCENTA o convite do seu Osmar.

Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/sim/fase7a2_sim.py [secao ...]
Secoes: choque, panfleto, aquecido, forca, ident, campanha, tudo (padrao).
  forca    = MEDIDA DO TETO (como o 'teto' da 6c2): sem calendario, robo so luta no verde, derrota nao encerra; tempo real e
             tempo de sala (dias) ate cada vitoria, por politica de convite.
  campanha = campanha de verdade (calendario, Legado, hall), tempo real ate o 1o Kid, cinturao e 1a carreira.
  ident    = ignorar todos os convites == jogo da 7a1 (mesmas sementes).
Politicas: nenhum (ignora tudo), todos_max (vai em todos, nota maxima: Choque 3 pontos e VENCEU, Panfletagem 10+), todos_med
(Choque 2 pontos, Panfletagem 7), todos_piso (vai e nao faz nada), so_choque_max, so_panf_max.
  cedo_max / cedo50_max (D1): como todos_max, mas com o AQUECIDO guardado luta com a chance (com o bonus) >= 75% / 50%.
Alavancas: SIM_N72 (jogadores por perfil na campanha; padrao 120), SIM_K72 (campanhas; padrao 8), SIM_NM (partidas por
perfil de minigame; padrao 400), SIM_NF (jogadores da forca; padrao 40), SIM_CONV / SIM_CONVF (politicas da campanha / forca),
SIM_ARTES (forca: "boxing,bjj"), SIM_WARM (AQUECIDO), SIM_SPARMAX (premio maximo do Choque, s), SIM_INTERVAL (s entre convites).
Resultados de referencia: docs/fases/fase7a2-design.md §3.5, §4.3, §5.4, §8 e §9.
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
import fase4_sim as f4  # noqa: E402
import fase4b_sim as f4b  # noqa: E402
import fase5_sim as f5  # noqa: E402
import fase6c2_sim as f6  # noqa: E402
import fase7a1_sim as f7  # noqa: E402

med = f4.mediana
pct = f4.pct
mm = f4.mm


def carregar():
    with open(os.path.join(f2.RAIZ, "data", "minigames.json"), encoding="utf-8") as fh:
        return json.load(fh)


MG = carregar()
if os.environ.get("SIM_WARM"):
    MG["spar"]["warm"]["attr_bonus"] = float(os.environ["SIM_WARM"])
if os.environ.get("SIM_SPARMAX"):
    MG["spar"]["reward"]["max_seconds"] = float(os.environ["SIM_SPARMAX"])
if os.environ.get("SIM_FIRST"):
    MG["invite"]["first_after_s"] = float(os.environ["SIM_FIRST"])
if os.environ.get("SIM_INTERVAL"):
    MG["invite"]["interval_s"] = float(os.environ["SIM_INTERVAL"])
DT = 0.02


# =================================================================== Choque
def roteiro_choque(nivel, rng):
    """Lista de padroes (tipo, t_aviso, t_ini, t_fim). tipo: burst | pause | feint. O aviso vai de t_aviso a t_ini."""
    L = MG["spar"]["levels"][nivel]
    t = rng.uniform(L["gap_min"], L["gap_max"])
    out = []
    dur = MG["spar"]["duration_s"]
    pesos = [("burst", L["w_burst"]), ("pause", L["w_pause"]), ("feint", L["w_feint"])]
    tot = sum(w for _, w in pesos)
    while t < dur:
        r = rng.random() * tot
        tipo = "burst"
        for k, w in pesos:
            if r < w:
                tipo = k
                break
            r -= w
        if tipo == "burst":
            a, i, f = t, t + L["warn_s"], t + L["warn_s"] + L["burst_s"]
        elif tipo == "pause":
            a, i, f = t, t + L["pause_warn_s"], t + L["pause_warn_s"] + L["pause_s"]
        else:
            a, i, f = t, t + L["warn_s"], t + L["warn_s"] + L["feint_pause_s"]
        out.append((tipo, a, i, f))
        t = f + rng.uniform(L["gap_min"], L["gap_max"])
    return out


# perfis de jogador do Choque: cps normal, cps na pausa, le o aviso da rajada, le a finta, reacao (s), segura (JJ: fracao)
PERFIS_CHOQUE = {
    "parado":   {"cps": 0.0, "cps_pausa": 0.0, "le": 0.0, "finta": 0.0, "reacao": 0.5, "duty": 0.0},
    "afobado":  {"cps": 9.0, "cps_pausa": 9.0, "le": 0.0, "finta": 0.0, "reacao": 0.5, "duty": 1.0},
    "distraido": {"cps": 4.0, "cps_pausa": 4.0, "le": 0.3, "finta": 0.1, "reacao": 0.5, "duty": 0.75},
    "medio":    {"cps": 4.5, "cps_pausa": 6.0, "le": 0.6, "finta": 0.3, "reacao": 0.40, "duty": 0.70},
    "bom":      {"cps": 4.3, "cps_pausa": 7.0, "le": 0.9, "finta": 0.7, "reacao": 0.30, "duty": 0.65},
    "perfeito": {"cps": 4.3, "cps_pausa": 8.0, "le": 1.0, "finta": 1.0, "reacao": 0.25, "duty": 0.62},
}


def jogar_choque(arte, nivel, perfil, semente, sair_em=None):
    S = MG["spar"]
    V = S["variants"][arte]
    L = S["levels"][nivel]
    P = PERFIS_CHOQUE[perfil]
    rng = random.Random(semente)
    rot = roteiro_choque(nivel, rng)
    # decisoes do jogador por padrao (sorteadas antes, para nao misturar com o tempo)
    dec = []
    for tipo, a, i, f in rot:
        le = rng.random() < P["le"]
        lf = rng.random() < P["finta"]
        dec.append((le, lf))
    x, F = 0.0, 1.0
    meus, dele = 0, 0
    congelado = 0.0
    t = 0.0
    prox_clique = rng.random() / max(P["cps"], 1e-9) if P["cps"] > 0 else 1e18
    dur = S["duration_s"] if sair_em is None else min(S["duration_s"], sair_em)
    ciclo = 3.0  # JJ: segura duty x ciclo, solta o resto
    while t < dur - 1e-9:
        # padrao atual
        fase, guarda_alvo, k_atual = None, False, -1
        for k, (tipo, a, i, f) in enumerate(rot):
            if a <= t < f:
                k_atual = k
                fase = ("aviso" if t < i else "ativo", tipo, a, i, f)
                break
        empurra = L["base_push"]
        pausa = False
        rajada = False
        if fase:
            est, tipo, a, i, f = fase
            if est == "ativo":
                if tipo == "burst":
                    rajada = True
                    empurra = L["burst_push"]
                else:
                    pausa = True
                    empurra = 0.0
        # o que o jogador faz agora
        guarda = False   # Boxe: segura (guarda). JJ: solta.
        ritmo = P["cps"]
        if fase:
            est, tipo, a, i, f = fase
            le, lf = dec[k_atual]
            visto = t >= a + P["reacao"]
            if tipo == "burst" and le and visto:
                guarda = True
            if tipo == "feint":
                if lf and t >= a + L["warn_s"] * 0.5 + P["reacao"]:
                    guarda = False      # leu a finta: fica pronto para a pausa
                elif le and visto:
                    guarda = True       # caiu na finta: guarda a toa
                    if est == "ativo":
                        guarda = t < a + L["warn_s"] + L["burst_s"]   # segura o tempo de uma rajada
            if pausa and t >= i + (0.0 if (tipo == "pause" and le) or (tipo == "feint" and lf) else P["reacao"]):
                ritmo = P["cps_pausa"]
        if congelado > 0:
            congelado -= DT
            t += DT
            continue
        if arte == "boxing":
            F = min(1.0, F + V["breath_recover_per_s"] * DT)
            if not guarda and ritmo > 0:
                while prox_clique <= t + DT and prox_clique < 1e17:
                    forca = V["weak_min"] + (1 - V["weak_min"]) * F
                    x += V["push_per_click"] * forca * (S["counter_mult"] if pausa else 1.0)
                    F = max(0.0, F - V["breath_cost_per_click"])
                    prox_clique += 1.0 / ritmo
            else:
                prox_clique = t + DT + (1.0 / ritmo if ritmo > 0 else 1e18)
            if rajada and guarda:
                empurra *= S["read_mult"]
        else:
            segura = P["duty"] > 0 and not guarda and ((t % ciclo) < P["duty"] * ciclo or (pausa and P["duty"] < 1.0 and P["le"] > 0) or P["duty"] >= 1.0)
            if pausa and P["duty"] > 0 and not guarda:
                segura = True
            if segura:
                forca = V["weak_min"] + (1 - V["weak_min"]) * F
                x += V["pull_per_s"] * forca * (S["counter_mult"] if pausa else 1.0) * DT
                F = max(0.0, F - V["breath_drain_per_s"] * (V["burst_hold_drain_mult"] if rajada else 1.0) * DT)
            else:
                F = min(1.0, F + V["breath_recover_per_s"] * DT)
            if rajada and not segura:
                empurra *= S["read_mult"]
        x -= empurra * DT
        if x >= 1.0:
            meus += 1
            x = 0.0
            congelado = S["reset_s"]
        elif x <= -1.0:
            dele += 1
            x = 0.0
            congelado = S["reset_s"]
        t += DT
    venceu = meus >= S["points_goal"] and meus > dele
    return meus, dele, venceu


def nota_choque(meus):
    R = MG["spar"]["reward"]
    return R["floor"] + (1 - R["floor"]) * min(1.0, meus / MG["spar"]["points_goal"])


def _choque_um(args):
    arte, nivel, perfil, n = args
    pts, deles, vit = [], [], 0
    for s in range(n):
        m, d, v = jogar_choque(arte, nivel, perfil, 7000 + s)
        pts.append(m); deles.append(d); vit += v
    return arte, nivel, perfil, pts, deles, vit / n


def sec_choque(n):
    tarefas = [(a, lv, p, n) for a in ("boxing", "bjj") for lv in range(6) for p in PERFIS_CHOQUE]
    with Pool(_proc()) as pool:
        res = pool.map(_choque_um, tarefas, chunksize=1)
    print("\n## Choque: pontos (media) / pontos dele (media) / VENCEU (%%) / premio (%% do maximo), %d partidas por celula" % n)
    for arte in ("boxing", "bjj"):
        print("\n### %s" % arte)
        print("| perfil | " + " | ".join("nivel %d" % lv for lv in range(6)) + " |")
        print("|---|" + "---|" * 6)
        for p in PERFIS_CHOQUE:
            cel = []
            for a, lv, pp, pts, deles, v in res:
                if a == arte and pp == p:
                    nota = sum(nota_choque(x) for x in pts) / len(pts)
                    cel.append("%.1f / %.1f / %.0f%% / %.0f%%" % (sum(pts) / len(pts), sum(deles) / len(deles), 100 * v, 100 * nota))
            print("| %s | %s |" % (p, " | ".join(cel)))


# =================================================================== Panfletagem
PERFIS_PANF = {
    "parado":   {"le": 0.0, "erra": 0.0, "reacao": 0.6, "atencao": 0.0},
    "afobado":  {"le": 0.0, "erra": 1.0, "reacao": 0.35, "atencao": 1.0, "todos": True},   # clica em todo mundo
    "distraido": {"le": 0.5, "erra": 0.10, "reacao": 0.6, "atencao": 0.6},
    "medio":    {"le": 0.75, "erra": 0.10, "reacao": 0.5, "atencao": 0.8},
    "bom":      {"le": 0.92, "erra": 0.04, "reacao": 0.4, "atencao": 0.95},
    "perfeito": {"le": 1.0, "erra": 0.0, "reacao": 0.3, "atencao": 1.0},
}


def jogar_panfleto(nivel, perfil, semente):
    F = MG["flyers"]
    L = F["levels"][nivel]
    P = PERFIS_PANF[perfil]
    rng = random.Random(semente)
    dur = F["duration_s"]
    # pessoas: (t_entra, interessado, t_sinal_ini, t_sinal_fim, sinal_falso)
    pessoas = []
    t = rng.expovariate(1.0 / L["spawn_s"])
    while t < dur:
        inter = rng.random() < L["interested"]
        falso = (not inter) and rng.random() < L["false_tell"]
        meio = t + F["cross_s"] * rng.uniform(0.25, 0.55)
        ts = (meio, meio + (L["tell_s"] if inter else L["tell_s"] * 0.45))
        pessoas.append((t, inter, ts[0], ts[1], falso))
        t += rng.expovariate(1.0 / L["spawn_s"])
    # o jogador: a cada pessoa que da sinal (verdadeiro ou falso), decide se clica
    livre = 0.0
    aceitos, erros = 0, 0
    eventos = []
    for (te, inter, s0, s1, falso) in pessoas:
        if P.get("todos"):   # clica em todo mundo, numa hora qualquer da travessia, sem ler o sinal
            tc = te + F["cross_s"] * rng.uniform(0.1, 0.9)
            eventos.append((tc, inter and s0 <= tc <= s1))
            continue
        if not (inter or falso):
            if P["erra"] > 0 and rng.random() < P["erra"] * 0.25:   # clique a toa em quem nem deu sinal
                eventos.append((te + F["cross_s"] * rng.uniform(0.2, 0.8), False))
            continue
        if rng.random() > P["atencao"]:
            continue
        if inter:
            if rng.random() < P["le"]:
                eventos.append((s0 + P["reacao"], True if s0 + P["reacao"] <= s1 else False))
        else:  # sinal falso: quem le mal clica
            if rng.random() < P["erra"] + (1 - P["le"]) * 0.5:
                eventos.append((s0 + P["reacao"], False))
    eventos.sort()
    for (tc, ok) in eventos:
        if tc >= dur:
            continue
        if tc < livre:
            continue  # mao ocupada: perde a chance
        if ok:
            aceitos += 1
            livre = tc + F["give_cooldown_s"]
        else:
            erros += 1
            livre = tc + F["miss_cooldown_s"]
    pontos = max(0.0, aceitos - F["miss_penalty"] * erros)
    return pontos, erros, len([p for p in pessoas if p[1]])


def nota_panf(aceitos):
    R = MG["flyers"]["reward"]
    return R["floor"] + (1 - R["floor"]) * min(1.0, aceitos / MG["flyers"]["goal"])


def fama_panf(prize_fame_prox, aceitos):
    R = MG["flyers"]["reward"]
    return max(1, int(math.floor(max(R["min_fame"], R["fame_share"] * prize_fame_prox) * nota_panf(aceitos) + 0.5)))


def sec_panfleto(n):
    print("\n## Panfletagem: aceitos (media) / erros (media) / interessados que passaram / premio (%% do maximo), %d partidas" % n)
    print("| perfil | " + " | ".join("nivel %d" % lv for lv in range(6)) + " |")
    print("|---|" + "---|" * 6)
    for p in PERFIS_PANF:
        cel = []
        for lv in range(6):
            r = [jogar_panfleto(lv, p, 9000 + s) for s in range(n)]
            a = [x[0] for x in r]
            cel.append("%.1f / %.1f / %.1f / %.0f%%" % (sum(a) / n, sum(x[1] for x in r) / n, sum(x[2] for x in r) / n,
                                                     100 * sum(nota_panf(x) for x in a) / n))
        print("| %s | %s |" % (p, " | ".join(cel)))
    R0 = f5.DADOS[0] if f5.DADOS else None
    if R0:
        print("\nFAMA maxima por panfletagem (proximo adversario): " + ", ".join(
            "%s %d (piso %d)" % (f5.OPP_CURTO.get(o["id"], o["id"]), fama_panf(o["prize_fame"], 99), fama_panf(o["prize_fame"], 0))
            for o in R0.opp))


# =================================================================== AQUECIDO
def sec_aquecido():
    """Quanto o AQUECIDO muda a chance: estados reais do robo x 0,7..1,3, chance com e sem (motor 7a1)."""
    f7._init7(quieto=True)
    R0 = f5.DADOS[0]
    b = MG["spar"]["warm"]["attr_bonus"]
    rng = random.Random(3)
    print("\n## AQUECIDO (+%.0f%% nos atributos na luta): chance antes -> depois (melhor tatica, 200 sementes)" % (100 * b))
    print("| arte | adversario | faixa da chance sem | n | ganho medio (pontos) | ganho maximo |")
    print("|---|---|---|---|---|---|")
    for arte in ("boxing", "bjj"):
        R = f7.regras_arte7(R0, {"fight": {}}, 0.0, arte)
        for oid in ("opp_gym_1", "opp_gym_2", "opp_tank"):
            o = next(x for x in R0.opp if x["id"] == oid)
            adv = (o["strength"], o["agility"], o["endurance"])
            faixas = {}
            for i in range(160):
                esc = 0.55 + 0.6 * rng.random()
                div = [rng.uniform(0.6, 1.4) for _ in range(3)]
                s = sum(div)
                jog = tuple(esc * sum(adv) * d / s for d in div)
                p0 = max(R.chance(jog, adv, t, 200) for t in R.tac_ids)
                p1 = max(R.chance(tuple(x * (1 + b) for x in jog), adv, t, 200) for t in R.tac_ids)
                fx = "vermelho (<40%)" if p0 < 0.4 else ("amarelo (40-90%)" if p0 < 0.9 else "verde (>=90%)")
                faixas.setdefault(fx, []).append(p1 - p0)
            for fx in ("vermelho (<40%)", "amarelo (40-90%)", "verde (>=90%)"):
                g = faixas.get(fx, [])
                if g:
                    print("| %s | %s | %s | %d | %+.1f | %+.1f |" % (arte, f5.OPP_CURTO.get(oid), fx, len(g), 100 * sum(g) / len(g), 100 * max(g)))


# =================================================================== campanha (convites)
POLITICA = os.environ.get("SIM_POL72", "nenhum")
JA_CINTO = [False]
CONV = {"n": 0}


def _proc():
    return int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))


_Carreira6_orig = f6.Carreira6


class Carreira7a2(_Carreira6_orig):
    """Carreira da 6c2/7a1 + convite do seu Osmar. politica: nenhum | todos_max | todos_med | todos_piso | so_choque_max | so_panf_max."""

    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        I = MG["invite"]
        self.pol = POLITICA
        self.inv_s = 0.0                     # segundos de sala (relogio do convite)
        self.inv_prox = I["first_after_s"]
        self.inv_aberto = None               # (tipo, t_sala_aparece)
        self.inv_ult = None
        self.quente = False
        self.n_conv = {"spar": 0, "flyers": 0, "ignorado": 0}
        self.ganho_choque = 0.0
        self.ganho_equipe_mg = 0.0
        self.fama_panf = 0
        self.t_mg = 0.0
        self.n_quente_usado = 0
        self.lutas72 = []
        self.vt72 = {}

    def definir_arte(self, arte):
        _Carreira6_orig.definir_arte(self, arte)
        self.t_mg_arte0 = getattr(self, "t_mg", 0.0)

    def jj_bonus(self):
        """Jogo: o bonus do Jiu-jitsu anda com arte_segundos (so sala). O minigame nao conta."""
        if self.arte != "bjj":
            return 0.0
        r = self.P["arts"]["bjj"]["rule"]
        m = 1.0 + self.style_bonus.get("bjj", 0.0)
        sala = (self.t - self.t_arte0) - (getattr(self, "t_mg", 0.0) - getattr(self, "t_mg_arte0", 0.0))
        return m * min(r["cap"], r["start"] + r["per_minute"] * sala / 60.0)

    def _nivel(self):
        return min(MG["level"]["max"], self.vitorias)

    def _elegiveis(self):
        out = []
        if self.arte:
            out.append("spar")
        if JA_CINTO[0] or self.cinturao:
            out.append("flyers")
        return out

    def _escolher(self, eleg):
        if len(eleg) == 1:
            return eleg[0]
        if self.quente:
            return "flyers"
        if self.inv_ult is None:
            return "spar"
        return "flyers" if self.inv_ult == "spar" else "spar"

    def _perfil(self):
        return {"todos_max": "max", "todos_med": "med", "todos_piso": "piso", "so_choque_max": "max", "so_panf_max": "max",
                "cedo_max": "max", "cedo50_max": "max"}.get(self.pol)

    def _aceita(self, tipo):
        if self.pol == "nenhum":
            return False
        if self.pol == "so_choque_max":
            return tipo == "spar"
        if self.pol == "so_panf_max":
            return tipo == "flyers"
        return True

    def _passo_convite(self):
        I = MG["invite"]
        if self.cinturao:
            JA_CINTO[0] = True
        data = self.data_prox()
        if self.fim or (data is not None and self.dia() >= data):
            self.inv_aberto = None
            return
        self.inv_s += self.dt
        if self.inv_aberto and self.inv_s >= self.inv_aberto[1] + I["visible_s"]:
            self.inv_aberto = None
            self.n_conv["ignorado"] += 1
        if self.inv_aberto is None and self.inv_s >= self.inv_prox:
            eleg = self._elegiveis()
            if not eleg:
                return
            tipo = self._escolher(eleg)
            self.inv_aberto = (tipo, self.inv_s)
            self.inv_ult = tipo
            self.inv_prox = self.inv_s + I["interval_s"]
            if self._aceita(tipo):
                self._jogar(tipo)
                self.inv_aberto = None
                self.inv_prox = max(self.inv_prox, self.inv_s + I["min_after_return_s"])

    def _jogar(self, tipo):
        I = MG["invite"]
        perfil = self._perfil()
        a = self.foco()
        dur = (MG["spar"] if tipo == "spar" else MG["flyers"])["duration_s"] + MG["spar"]["countdown_s"] + I["overhead_s"]
        # equipe produz o tempo todo fora da sala (relogio parado)
        ge = self.passivo() * dur
        self.saldo += ge
        self.somar(a, ge)
        self.ganho_equipe_mg += ge
        self.t += dur
        self.t_mg += dur
        self.fechar_trechos()
        self.n_conv[tipo] += 1
        if tipo == "spar":
            pts = {"max": 3, "med": 2, "piso": 0}[perfil]
            ref = self.passivo() + MG["reward_ref"]["ref_clicks_per_s"] * self.valor_clique(a)
            g = MG["spar"]["reward"]["max_seconds"] * ref * nota_choque(pts)
            self.saldo += g
            if self.sig:
                self.somar(self.sig, g)      # divisao do aparelho da arte (saldo ja somado acima)
            else:
                self.somar(a, g)
            self.ganho_choque += g
            if pts >= MG["spar"]["points_goal"] and not self.quente:
                self.quente = True
        else:
            ac = {"max": 99, "med": 7, "piso": 0}[perfil]
            i = min(self.vitorias, len(self.R.opp) - 1)
            f = fama_panf(self.R.opp[i]["prize_fame"], ac)
            self.fama += f
            self.fama_panf += f

    def talvez_lutar(self):
        self._passo_convite()
        v0, n0 = self.vitorias, len(self.lutas)
        base = sum(self.attr)
        if not self.quente:
            _Carreira6_orig.talvez_lutar(self)
        else:
            b = MG["spar"]["warm"]["attr_bonus"]
            orig = list(self.attr)
            esc = [x * (1 + b) for x in orig]
            self.attr = esc
            # D1: com o AQUECIDO guardado, quem joga "cedo" luta com a chance (ja com o bonus) acima de CEDO, nao so no verde
            cedo = {"cedo_max": 0.75, "cedo50_max": 0.50}.get(self.pol)
            risk = self.R.risk
            velho_easy = risk["easy_min"]
            if cedo is not None:
                risk["easy_min"] = cedo
            try:
                _Carreira6_orig.talvez_lutar(self)
            finally:
                risk["easy_min"] = velho_easy
                self.attr = [o + (x - e) for o, x, e in zip(orig, self.attr, esc)]
            if len(self.lutas) > n0:
                self.quente = False
                self.n_quente_usado += 1
        if len(self.lutas) > n0:
            l = self.lutas[-1]
            self.lutas72.append((l["opp"], base, l["p"], l["win"]))
        if self.vitorias > v0:
            o = self.R.opp[self.vitorias - 1]["id"]
            self.vt72[o] = (self.t, self.t - self.t_mg)


def forca72(args):
    """Como f6.forca: sem calendario, robo so luta no VERDE, derrota nao encerra. Tempo real e tempo de sala ate cada vitoria."""
    (cps, semente, arte, pol) = args
    global POLITICA
    POLITICA = pol
    JA_CINTO[0] = True
    R, treino, gens, shop, career, tree, unlocks, assist, P = f5.DADOS
    on = f5.CAL["on"]
    f5.CAL["on"] = False
    mapa = f5.mapa_de(tree)
    b = f5.bonus54(mapa, set(), arte)
    he = f6.efeitos_hall(set(), 0)
    c = Carreira7a2(R, treino, gens, shop, career, cps, "tipico", semente, b, unlocks, assist, P,
                    arte=arte, arte_chegada=None, belt_ends=False, style_bonus=b["art_rule_bonus"], regra_ap="asap", k=5,
                    ret_gym=1e18, ritmo=f4b.ritmo_constante(cps), usa_shift=False, limiar="facil", dica=None,
                    cauteloso_contra=set(), metronomo=True, t_max=6 * 3600, hall=he, sem_derrota=True)
    c.rodar()
    f5.CAL["on"] = on
    return dict(c.vt72), c.t_mg, c.ganho_choque, c.ganho_equipe_mg


def sec_forca(n):
    pols = os.environ.get("SIM_CONVF", "nenhum,todos_max,todos_med,todos_piso,so_choque_max").split(",")
    alvos = (("opp_tank", "Muralha"), ("opp_gym_1", "Tonhao"), ("opp_gym_2", "Kid"))
    print("\n## Forca de treino (sem calendario, robo so luta no VERDE, derrota nao encerra; %d jogadores; arvore vazia, sem hall)" % n)
    print("Tempo real = relogio do jogador (inclui o minigame). Tempo de sala = dias de campanha (o minigame para o relogio).")
    print("| arte cps | politica | Muralha: real / sala | Tonhao: real / sala | Kid: real / sala | aceleracao no Kid: real / sala |")
    print("|---|---|---|---|---|---|")
    for arte in os.environ.get("SIM_ARTES", "boxing,bjj").split(","):
        for cps in (4, 3):
            tarefas = [(cps, 5000 + s, arte, pol) for pol in pols for s in range(n)]
            with Pool(_proc(), initializer=_init72) as pool:
                res = pool.map(forca72, tarefas, chunksize=1)
            T = {}
            for j, pol in enumerate(pols):
                rs = res[j * n:(j + 1) * n]
                T[pol] = {o: (med([r[0][o][0] for r in rs if o in r[0]]), med([r[0][o][1] for r in rs if o in r[0]])) for o, _ in alvos}
            for pol in pols:
                k = T[pol]["opp_gym_2"]
                k0 = T["nenhum"]["opp_gym_2"]
                print("| %s %d/s | %s | %s | %s | %s | %+.1f%% / %+.1f%% |" % (
                    arte, cps, pol, *["%s / %s" % (mm(T[pol][o][0]), mm(T[pol][o][1])) for o, _ in alvos],
                    100 * (1 - k[0] / k0[0]), 100 * (1 - k[1] / k0[1])))


def _init72(quieto=True):
    f7._init7(quieto=quieto)
    f6.Carreira6 = Carreira7a2


def sequencia72(args):
    pol = args[-1]
    global POLITICA
    POLITICA = pol
    JA_CINTO[0] = False
    extra = []
    velho = Carreira7a2.rodar

    def rodar_e_guardar(self):
        velho(self)
        extra.append({"n_conv": dict(self.n_conv), "choque": self.ganho_choque, "equipe_mg": self.ganho_equipe_mg,
                      "fama_panf": self.fama_panf, "t_mg": self.t_mg, "quente_usado": self.n_quente_usado,
                      "fama": self.fama, "inv_s": self.inv_s, "lutas72": list(self.lutas72),
                      "vt72": dict(self.vt72)})
        return self
    Carreira7a2.rodar = rodar_e_guardar
    try:
        seq = f7.sequencia7(args[:-1])
    finally:
        Carreira7a2.rodar = velho
    for rec, e in zip(seq, extra):
        rec["mg"] = e
    return seq


def rodar72(perfis, n, K, pols):
    tarefas = []
    for pol in pols:
        for p in perfis:
            for s in range(n):
                tarefas.append((p["cps"], 1000 + s, K, "padrao", p["arte"], "normal", f5.T_MAX5, pol))
    with Pool(_proc(), initializer=_init72) as pool:
        res = pool.map(sequencia72, tarefas, chunksize=1)
    out, i = {}, 0
    for pol in pols:
        for p in perfis:
            out[(pol, p["nome"])] = res[i:i + n]
            i += n
    return out


def _metr(seqs):
    ks = [f7.kid7(s) for s in seqs]
    tac = [x["t_acum"] for x in ks if x["t_acum"] is not None]
    belt = []
    for s in seqs:
        r = next((r for r in s if r["t_belt"]), None)
        if r:
            belt.append(r["t_ini"] + r["t_belt"])
    c1 = [s[0]["t"] for s in seqs]
    tot = [s[-1]["t_fim"] for s in seqs]
    legado = [sum(r["legado"] for r in s) for s in seqs]
    mg = [r["mg"] for s in seqs for r in s]
    camp = [x["camp"] for x in ks]
    sala = []   # 1o Kid em tempo de sala (dias): tempo real acumulado menos os minutos de minigame ate ali
    for sq in seqs:
        mg_ant = 0.0
        for r in sq:
            v = r["mg"]["vt72"].get("opp_gym_2")
            if v and "opp_gym_2" in r["vit_t"]:
                sala.append(r["t_ini"] - mg_ant + v[1])
                break
            mg_ant += r["mg"]["t_mg"]
    return {"kid_sala": med(sala), "kid_sala_media": sum(sala) / max(1, len(sala)), "kid_med": med(tac), "kid_media": sum(tac) / max(1, len(tac)), "kid_n": len(tac), "belt_med": med(belt),
            "belt_media": sum(belt) / max(1, len(belt)), "c1": med(c1), "legado": sum(legado) / len(legado),
            "camp_media": sum(min(c, 9) for c in camp) / len(camp),
            "spar": sum(m["n_conv"]["spar"] for m in mg) / len(seqs), "flyers": sum(m["n_conv"]["flyers"] for m in mg) / len(seqs),
            "ign": sum(m["n_conv"]["ignorado"] for m in mg) / len(seqs), "t_mg": sum(m["t_mg"] for m in mg) / len(seqs),
            "fama_panf": sum(m["fama_panf"] for m in mg) / len(seqs), "fama": sum(m["fama"] for m in mg) / len(seqs),
            "quente": sum(m["quente_usado"] for m in mg) / len(seqs), "inv_s": sum(m["inv_s"] for m in mg) / len(seqs),
            "choque": sum(m["choque"] for m in mg) / len(seqs)}


def sec_campanha(n, K):
    pols = os.environ.get("SIM_CONV", "nenhum,todos_max,todos_med,todos_piso,so_choque_max,so_panf_max").split(",")
    perfis = [{"nome": "%s %d/s" % (nm, cps), "cps": cps, "arte": a}
              for cps in (4, 3) for nm, a in (("Boxe", "boxing"), ("Jiu-jitsu", "bjj"))]
    res = rodar72(perfis, n, K, pols)
    print("\n## Campanha com convites (%d jogadores por perfil x %d campanhas; robo padrao da 7a1; tempo = tempo de jogo real, "
          "incluindo o minigame)" % (n, K))
    print("| perfil | politica | 1o Kid: mediana / media | cinturao: mediana | 1a carreira (med) | campanhas ate o Kid (media) | "
          "Legado (soma K) | convites por sequencia: Choque / Panf. / ignorados | min no minigame | FAMA da panfletagem | AQUECIDO usado |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    M = {}
    for (pol, nome), seqs in res.items():
        M[(pol, nome)] = m = _metr(seqs)
        print("| %s | %s | %s / %s | %s | %s | %.2f | %.0f | %.1f / %.1f / %.1f | %.1f | %.0f | %.1f |" % (
            nome, pol, mm(m["kid_med"]), mm(m["kid_media"]), mm(m["belt_med"]), mm(m["c1"]), m["camp_media"], m["legado"],
            m["spar"], m["flyers"], m["ign"], m["t_mg"] / 60.0, m["fama_panf"], m["quente"]))
    print("\n### Aceleracao contra 'nenhum' (positivo = mais rapido). Teto do dono: 10%")
    print("| perfil | politica | 1o Kid (mediana) | 1o Kid (media) | cinturao (mediana) | 1a carreira | 1o Kid em DIAS (mediana / media) |")
    print("|---|---|---|---|---|---|---|")
    for (pol, nome), m in M.items():
        if pol == "nenhum":
            continue
        b = M[("nenhum", nome)]
        print("| %s | %s | %+.1f%% | %+.1f%% | %+.1f%% | %+.1f%% | %+.1f%% / %+.1f%% |" % (
            nome, pol, 100 * (1 - m["kid_med"] / b["kid_med"]), 100 * (1 - m["kid_media"] / b["kid_media"]),
            100 * (1 - m["belt_med"] / b["belt_med"]), 100 * (1 - m["c1"] / b["c1"]),
            100 * (1 - m["kid_sala"] / b["kid_sala"]), 100 * (1 - m["kid_sala_media"] / b["kid_sala_media"])))
    return res


def sec_ident(n, K):
    """Convites todos ignorados x jogo da 7a1 (sem convite): sequencias identicas."""
    perfis = [{"nome": "Boxe 4/s", "cps": 4, "arte": "boxing"}, {"nome": "Jiu-jitsu 3/s", "cps": 3, "arte": "bjj"}]
    a = rodar72(perfis, n, K, ["nenhum"])
    tarefas = [(p["cps"], 1000 + s, K, "padrao", p["arte"], "normal", f5.T_MAX5) for p in perfis for s in range(n)]
    with Pool(_proc(), initializer=f7._init7) as pool:
        b = pool.map(f7.sequencia7, tarefas, chunksize=1)
    sa = [s for p in perfis for s in a[("nenhum", p["nome"])]]
    iguais = 0
    for x, y in zip(sa, b):
        cx = [(r["fim"], round(r["t"], 6), r["wins"], r["legado"], r["lutas"]) for r in x]
        cy = [(r["fim"], round(r["t"], 6), r["wins"], r["legado"], r["lutas"]) for r in y]
        iguais += cx == cy
    print("\n## Ignorar todos os convites = jogo sem 7a2: %d de %d sequencias identicas (fim, tempo, vitorias, Legado, lutas)" % (iguais, len(sa)))


def main():
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    f7._init7(quieto=True)
    nm = int(os.environ.get("SIM_NM", "400"))
    if tudo or "choque" in secs:
        sec_choque(nm)
    if tudo or "panfleto" in secs:
        sec_panfleto(nm)
    if tudo or "aquecido" in secs:
        sec_aquecido()
    n, K = int(os.environ.get("SIM_N72", "120")), int(os.environ.get("SIM_K72", "8"))
    if tudo or "forca" in secs:
        sec_forca(int(os.environ.get("SIM_NF", "40")))
    if tudo or "ident" in secs:
        sec_ident(min(n, 40), K)
    if tudo or "campanha" in secs:
        sec_campanha(n, K)


if __name__ == "__main__":
    main()
