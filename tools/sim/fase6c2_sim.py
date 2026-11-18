"""Simulacao da Fase 6c2 (Mais longe que eu): Honra, bonus do retrato e arvore do hall.

Reaproveita tools/sim/fase5_sim.py (campanha com calendario, academia, artes, arvore grande de Legado).
Valores: data/hall.json (design docs/fases/fase6c2-design.md). Nada aqui muda o jogo da 6b2/6c1: com o hall
desligado (SIM_HALL=0) a sequencia e identica a do fase5_sim.py (secao 'ident').

O que entra:
  - Honra no fim por vontade (aposentou / passou o posto no dia / topo) com >= min_wins vitorias:
    soma de per_win[0..w-1] + belt_bonus com o cinturao. Derrota = 0.
  - Retrato com selo (Honra > 0): +per_portrait de todo o treino (multiplicativo), ate max_portraits (+ hall_wall).
  - Hall: robo compra o mais barato que cabe, entre campanhas, depois da arvore de Legado.
    box_clicks_minus (caixa abre com menos cliques), start_training (saldo inicial de Treino), preview_detail (so
    informacao: sem efeito no sim), crew_mult (equipe x(1+v)), start_glove (comeca com a luva de lona aberta),
    portrait_cap_plus (teto de retratos).
  - Politicas de saida: padrao (robo da 5.4: passa o posto no vermelho do dia, aposenta no topo), sai1 (aposenta logo
    depois da 1a vitoria), sai_cint (aposenta logo depois do cinturao, sem mudar), ate_perder (nunca passa o posto;
    so sai no topo, porque depois do Kid nao ha luta).

Rodar (nao ha python no PATH):
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I tools/sim/fase6c2_sim.py [secao ...]
Secoes: ident, honra, metas, escolha, teto, tudo (padrao).
Alavancas: SIM_HALL=0 (desliga Honra/hall/retrato), SIM_N6 (jogadores por perfil), SIM_K6 (campanhas),
  SIM_OVH6 (s entre campanhas para Honra/min; padrao 90), SIM_HONRA="1,2,3,4,4,5;5" (per_win;belt),
  SIM_RETRATO="0.02,5", SIM_HALLCUSTO="10,20,30,35,45,50" (formato; os valores finais estao em data/hall.json).
"""
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
import fase5_sim as f5  # noqa: E402

med = f4.mediana
pct = f4.pct
mm = f4.mm
fk = f5.fk
OVH6 = float(os.environ.get("SIM_OVH6", "90"))   # fim + arvore + mural + criacao do discipulo + chegada (s)
HALL_ON = os.environ.get("SIM_HALL", "1") == "1"


def carregar_hall():
    with open(os.path.join(f2.RAIZ, "data", "hall.json"), encoding="utf-8") as fh:
        h = json.load(fh)
    if os.environ.get("SIM_HONRA"):
        pw, bb = os.environ["SIM_HONRA"].split(";")
        h["honor"]["per_win"] = [int(x) for x in pw.split(",")]
        h["honor"]["belt_bonus"] = int(bb)
    if os.environ.get("SIM_RETRATO"):
        p, m = os.environ["SIM_RETRATO"].split(",")
        h["portrait"]["per_portrait"], h["portrait"]["max_portraits"] = float(p), int(m)
    if os.environ.get("SIM_HALLCUSTO"):
        for n, c in zip(h["hall"]["nodes"], os.environ["SIM_HALLCUSTO"].split(",")):
            n["cost"] = int(c)
    return h


HALL = carregar_hall()


def honra(wins, belt, saida_por_vontade=True):
    ho = HALL["honor"]
    if not saida_por_vontade or wins < ho["min_wins"]:
        return 0
    pw = ho["per_win"]
    return sum(pw[min(i, len(pw) - 1)] for i in range(wins)) + (ho["belt_bonus"] if belt else 0)


def efeitos_hall(comprados, n_retratos):
    """{mult_treino, crew, start_training, box_minus, glove, preview, cap, retratos_contam}."""
    e = {"box_clicks_minus": 0, "start_training": 0.0, "preview_detail": 0, "crew_mult": 0.0, "start_glove": 0,
         "portrait_cap_plus": 0}
    for n in HALL["hall"]["nodes"]:
        if n["id"] in comprados:
            t, v = n["effect"]["type"], n["effect"]["value"]
            e[t] = max(e[t], v) if t in ("start_glove", "preview_detail") else e[t] + v
    cap = HALL["portrait"]["max_portraits"] + int(e["portrait_cap_plus"])
    conta = min(n_retratos, cap)
    e["retratos_contam"] = conta
    e["mult_treino"] = 1.0 + HALL["portrait"]["per_portrait"] * conta
    return e


HALL_CHEIO_IDS = [n["id"] for n in HALL["hall"]["nodes"]]
CUSTO_HALL = sum(n["cost"] for n in HALL["hall"]["nodes"])


def comprar_hall(comprados, saldo):
    comprados = set(comprados)
    while True:
        ops = [n for n in HALL["hall"]["nodes"] if n["id"] not in comprados and n["cost"] <= saldo]
        if not ops:
            return comprados, saldo
        n = min(ops, key=lambda x: (x["cost"], x["id"]))
        comprados.add(n["id"])
        saldo -= n["cost"]


# ---------------------------------------------------------------- campanha com hall e politica de saida
class Carreira6(f5.Carreira5):
    def __init__(self, *a, hall=None, alvo_saida=None, sem_derrota=False, **kw):
        self.h = hall or efeitos_hall(set(), 0)
        self.hm = self.h["mult_treino"]
        self.hcrew = 1.0 + self.h["crew_mult"]
        super().__init__(*a, **kw)
        self.alvo_saida = alvo_saida          # None, int (vitorias) ou "cint"
        self.sem_derrota = sem_derrota
        self.n_derrotas_ign = 0
        self.saldo += float(self.h["start_training"])
        if self.h["start_glove"] and self.luva == 0 and self.luvas:
            self.luva = 1                     # luva de lona ja aberta (sem caixa, sem custo)
        self.cx_cliques = max(1.0, (f5.CAIXA["cliques"] if f5.CAIXA else 3) - self.h["box_clicks_minus"])

    def por_soco(self, a):
        return f5.Carreira5.por_soco(self, a) * self.hm

    def passivo(self):
        return f5.Carreira5.passivo(self) * self.hm * self.hcrew

    def _caixas_passo(self):
        if not self.caixas:
            return False
        if self.caixa_fim is None:
            (_, t0) = self.caixas[0]
            if self.t < t0 + f5.CAIXA["espera"]:
                return False
            cps_cx = max(3.0, float(self.cps))
            self.caixa_fim = self.t + f5.CAIXA["reacao"] + self.cx_cliques / cps_cx + f5.CAIXA["anim"]
        if self.t + 1e-9 < self.caixa_fim:
            return True
        (tipo, id_), _ = self.caixas.pop(0)
        self.caixa_fim = None
        if tipo == "ap":
            self.owned.add(id_)
            self.t_ap[id_] = self.t
            self.teste_ap, self.teste_ate = id_, self.t + f4b.TESTE_S
            self.eventos.append((self.t, "abre " + id_))
        else:
            self.luva_fechada -= 1
            self.eventos.append((self.t, "abre " + id_))
        return self._caixas_passo()

    def talvez_lutar(self):
        v0 = self.vitorias
        f5.Carreira5.talvez_lutar(self)
        if self.sem_derrota and self.fim and self.fim[0] == "derrota":
            self.fim = None                   # medida de forca: a derrota nao encerra (tenta de novo depois)
            self.n_derrotas_ign += 1
            self.eventos.pop()
            return
        if self.fim or self.vitorias == v0 or self.alvo_saida is None:
            return
        if (self.alvo_saida == "cint" and self.cinturao) or (isinstance(self.alvo_saida, int) and self.vitorias >= self.alvo_saida):
            self.fechar_trechos()
            self.fim = ("aposentou", self.t)
            self.eventos.append((self.t, "SAI"))


POR_VONTADE = ("aposentou", "passou", "topo")


def sequencia6(args):
    (cps, semente, K, politica, arte_pol, hall_modo, t_max) = args
    R, treino, gens, shop, career, tree, unlocks, assist, P = f5.DADOS
    velho_dia = f5.CAL_DIA
    f5.CAL_DIA = "luta" if politica == "ate_perder" else "passa"
    alvo = {"padrao": None, "ate_perder": None, "sai1": 1, "sai2": 2, "sai_cint": "cint"}[politica]
    ritmo = f4b.ritmo_constante(cps)
    comprados, legado = set(), 0
    killer, dica = None, None
    algozes = set()
    artes_livres = set()
    n_com_arte = 0
    t_acum = 0.0
    out = []
    mapa = f5.mapa_de(tree)
    arte_robo = {"boxing", "bjj"} if arte_pol.startswith("alterna") else {arte_pol}
    chegou_gym = False
    honra_saldo, honra_total, hall, retratos, saidas_honra = 0, 0, set(), 0, 0
    for k in range(1, K + 1):
        caut = set(algozes)
        if killer:
            ik = next(i for i, o in enumerate(R.opp) if o["id"] == killer)
            caut = set(algozes) | {o["id"] for o in R.opp[:ik + 1]}
        arte = f5.arte_da_carreira(arte_pol, n_com_arte) if artes_livres else None
        chegada = None if artes_livres else f5.arte_da_carreira(arte_pol, 0)
        b = f5.bonus54(mapa, comprados, arte or chegada)
        if hall_modo == "cheio":
            he = efeitos_hall(set(HALL_CHEIO_IDS), 999)
        elif hall_modo == "normal" and HALL_ON:
            he = efeitos_hall(hall, retratos)
        else:
            he = efeitos_hall(set(), 0)
        c = Carreira6(R, treino, gens, shop, career, cps, "tipico", semente * 100 + k, b, unlocks, assist, P,
                      arte=arte, arte_chegada=chegada, belt_ends=False, cauteloso_gym=False,
                      style_bonus=b["art_rule_bonus"], regra_ap="asap", k=k, ritmo=ritmo, usa_shift=False,
                      limiar="equilibrado", dica=dica, cauteloso_contra=caut, metronomo=True, t_max=t_max,
                      hall=he, alvo_saida=alvo)
        c.ultimo_algoz = killer
        c.rodar()
        if c.arte:
            n_com_arte += 1
        primeira = (not artes_livres) and c.mudou
        if c.mudou:
            artes_livres |= {"boxing", "bjj"}
            chegou_gym = True
        ganho = c.legado_ganho()
        if b.get("legacy_bonus"):
            ganho = int(math.floor(ganho * (1.0 + b["legacy_bonus"]) + 1e-9))
        legado += ganho
        vontade = c.fim[0] in POR_VONTADE
        h = honra(c.vitorias, c.cinturao, vontade)
        if h > 0:
            saidas_honra += 1
            retratos += 1
        honra_saldo += h
        honra_total += h
        vit_t = {}
        for t, e in c.eventos:
            if e.startswith("VENCE "):
                vit_t[e[6:]] = t
        t_ini = t_acum
        t_acum += c.fim[1] + OVH6
        rec = {"k": k, "fim": c.fim[0], "t": c.fim[1], "opp": c.fim[2] if c.fim[0] in ("derrota", "passou") else None,
               "wins": c.vitorias, "belt": c.cinturao, "honra": h, "legado": ganho, "t_belt": c.t_belt,
               "vit_t": vit_t, "t_ini": t_ini, "t_fim": t_acum, "primeira_chegada": primeira, "mudou": c.mudou,
               "morto": c.morto_total(), "morto_gym": c.morto_gym(), "gaps": c.gaps52(), "arte": c.arte,
               "lutas": [(l["opp"], l["win"], l["p"], l["t"]) for l in c.lutas], "reg53": list(c.reg53),
               "hall_antes": len(hall), "retratos_contam": he["retratos_contam"], "mult": he["mult_treino"],
               "hall_ids_antes": sorted(hall), "saidas_honra": saidas_honra}
        if c.fim[0] in ("derrota", "passou"):
            _, t, opp, jog, tat = c.fim
            o = next(x for x in R.opp if x["id"] == opp)
            if tat is None:
                tat = c.R.melhor_tatica(jog, (o["strength"], o["agility"], o["endurance"]), 100)[0]
            attr, _, _ = c.R.motivo(jog, (o["strength"], o["agility"], o["endurance"]), tat, 100)
            dica = attr
            killer = opp
            algozes.add(opp)
        else:
            killer = None
        flags = {"gym": chegou_gym, "arts": artes_livres}
        comprados, legado = f5.comprar_mapa(mapa, comprados, legado, flags, arte_robo)
        rec["arvore_cheia"] = f5.uteis(mapa, arte_robo) <= comprados
        if HALL_ON and hall_modo == "normal":
            hall, honra_saldo = comprar_hall(hall, honra_saldo)
        rec["hall_depois"] = len(hall)
        rec["honra_total"] = honra_total
        out.append(rec)
    f5.CAL_DIA = velho_dia
    return out


def rodar6(perfis, n, K):
    tarefas = []
    for p in perfis:
        for s in range(n):
            tarefas.append((p["cps"], 1000 + s, K, p.get("pol", "padrao"), p.get("arte", "boxing"),
                            p.get("hall", "normal"), p.get("t_max", f5.T_MAX5)))
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    with Pool(proc, initializer=f5._init) as pool:
        res = pool.map(sequencia6, tarefas, chunksize=1)
    out, i = {}, 0
    for p in perfis:
        out[p["nome"]] = res[i:i + n]
        i += n
    return out


# ---------------------------------------------------------------- medida de forca (teto de 10%)
def forca(args):
    """Uma campanha sem calendario, robo so luta no VERDE e a derrota nao encerra: o tempo ate cada vitoria mede
    so a forca do treino (arvore, hall, retrato). cond: vazia | cheia | cheia+hall | vazia+hall."""
    (cps, semente, cond, arte) = args
    R, treino, gens, shop, career, tree, unlocks, assist, P = f5.DADOS
    on = f5.CAL["on"]
    f5.CAL["on"] = False
    mapa = f5.mapa_de(tree)
    comprados = set(i for i, n in mapa.items() if n.get("requires_art", "") in ("", arte)) if cond.startswith("cheia") else set()
    b = f5.bonus54(mapa, comprados, arte)
    if cond.endswith("+hall"):
        he = efeitos_hall(set(HALL_CHEIO_IDS), 999)
    elif cond.endswith("+retrato"):
        he = efeitos_hall({"hall_wall"}, 999)
    elif cond.endswith("+nos"):
        he = efeitos_hall(set(HALL_CHEIO_IDS), 0)
    else:
        he = efeitos_hall(set(), 0)
    c = Carreira6(R, treino, gens, shop, career, cps, "tipico", semente, b, unlocks, assist, P,
                  arte=arte, arte_chegada=None, belt_ends=False, style_bonus=b["art_rule_bonus"], regra_ap="asap", k=5,
                  ret_gym=1e18,
                  ritmo=f4b.ritmo_constante(cps), usa_shift=False, limiar="facil", dica=None, cauteloso_contra=set(),
                  metronomo=True, t_max=6 * 3600, hall=he, sem_derrota=True)
    c.rodar()
    f5.CAL["on"] = on
    vt = {}
    for t, e in c.eventos:
        if e.startswith("VENCE "):
            vt[e[6:]] = t
    return {"vt": vt, "t_move": c.t_move}


def sec_teto(n):
    print("\n## Teto do hall: forca de treino (sem calendario, robo so luta no VERDE, derrota nao encerra; %d jogadores)" % n)
    print("Condicoes: arvore de Legado vazia/cheia (so nos da arte jogada), hall cheio + retrato no teto (%d retratos, x%.2f)." % (
        HALL["portrait"]["max_portraits"] + 3, efeitos_hall(set(HALL_CHEIO_IDS), 999)["mult_treino"]))
    conds = ["vazia", "cheia", "cheia+hall", "cheia+retrato", "cheia+nos", "vazia+hall"]
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    for arte in ("boxing", "bjj"):
        for cps in (5, 3):
            tarefas = [(cps, 5000 + s, cd, arte) for cd in conds for s in range(n)]
            with Pool(proc, initializer=f5._init) as pool:
                res = pool.map(forca, tarefas, chunksize=1)
            T = {}
            for j, cd in enumerate(conds):
                rs = res[j * n:(j + 1) * n]
                T[cd] = {o: med([r["vt"][o] for r in rs if o in r["vt"]]) for o in ("opp_warmup", "opp_tank", "opp_gym_2")}
            print("\n### %s %d/s: minuto de cada vitoria (mediana)" % (arte, cps))
            print("| condicao | Dudu | Muralha (cinturao) | Kid | Kid alcancado |")
            print("|---|---|---|---|---|")
            for j, cd in enumerate(conds):
                rs = res[j * n:(j + 1) * n]
                print("| %s | %s | %s | %s | %d/%d |" % (cd, mm(T[cd]["opp_warmup"]), mm(T[cd]["opp_tank"]), mm(T[cd]["opp_gym_2"]),
                                                     sum(1 for r in rs if "opp_gym_2" in r["vt"]), n))
            for o, nome in (("opp_tank", "cinturao"), ("opp_gym_2", "Kid")):
                eL = T["vazia"][o] - T["cheia"][o]
                eH = T["cheia"][o] - T["cheia+hall"][o]
                eH0 = T["vazia"][o] - T["vazia+hall"][o]
                eR = T["cheia"][o] - T["cheia+retrato"][o]
                eN = T["cheia"][o] - T["cheia+nos"][o]
                print("- %s: arvore de Legado poupa %s; hall+retrato sobre a arvore cheia poupa %s -> %.1f%% do efeito da arvore "
                      "(so retrato no teto %.1f%%; so os nos %.1f%%; hall sobre a arvore vazia: %s -> %.1f%%)" % (
                          nome, mm(eL), mm(eH), 100 * eH / eL, 100 * eR / eL, 100 * eN / eL, mm(eH0), 100 * eH0 / eL))


# ---------------------------------------------------------------- secoes
def resumo_honra(nome, seqs, K):
    rs = [r for s in seqs for r in s]
    tot_h = sum(r["honra"] for r in rs)
    tot_t = sum(r["t"] + OVH6 for r in rs)
    late = [r for s in seqs for r in s if r["arvore_cheia"] or r["k"] > K // 2]
    lh = sum(r["honra"] for r in late)
    lt = sum(r["t"] + OVH6 for r in late)
    hall_k = [next((r["k"] for r in s if r["hall_depois"] == len(HALL_CHEIO_IDS)), 99) for s in seqs]
    hall_s = [next((r["saidas_honra"] for r in s if r["hall_depois"] == len(HALL_CHEIO_IDS)), 99) for s in seqs]
    fins = {}
    for r in rs:
        fins[r["fim"]] = fins.get(r["fim"], 0) + 1
    hpor = [r["honra"] for r in rs if r["honra"] > 0]
    return {"hmin": tot_h / (tot_t / 60.0), "hmin_late": lh / max(1e-9, lt / 60.0), "hall_k": hall_k, "hall_s": hall_s,
            "fins": fins, "hpor": hpor, "tmin": tot_t / 60.0 / len(seqs), "lmin": sum(r["legado"] for r in rs) / (tot_t / 60.0)}


def sec_honra(n, K):
    perfis = []
    for cps, arte, nm in ((5, "boxing", "Boxe 5/s"), (3, "boxing", "Boxe 3/s"), (5, "bjj", "Jiu-jitsu 5/s"), (3, "bjj", "Jiu-jitsu 3/s")):
        for pol, pn in (("padrao", "padrao"), ("sai1", "sai depois da 1a vitoria"), ("sai_cint", "sai com o cinturao"),
                        ("ate_perder", "ate perder")):
            perfis.append({"nome": "%s, %s" % (nm, pn), "cps": cps, "arte": arte, "pol": pol})
    so = os.environ.get("SIM_PERFIS")
    if so:
        perfis = [p for p in perfis if any(s in p["nome"] for s in so.split(";"))]
    res = rodar6(perfis, n, K)
    print("\n## Honra por jeito de jogar (%d jogadores x %d campanhas; %gs entre campanhas; per_win %s, cinturao +%d; hall %s = %d)" % (
        n, K, OVH6, HALL["honor"]["per_win"], HALL["honor"]["belt_bonus"], [x["cost"] for x in HALL["hall"]["nodes"]], CUSTO_HALL))
    print("| perfil | Honra/min (todas) | Honra/min (metade final) | Legado/min | Honra por saida com Honra (med; p10-p90) | saidas com Honra ate o hall cheio (med; p10-p90) | campanha do hall cheio (med) | fins |")
    print("|---|---|---|---|---|---|---|---|")
    for nome, seqs in res.items():
        r = resumo_honra(nome, seqs, K)
        hp = r["hpor"]
        print("| %s | %.2f | %.2f | %.0f | %s (%s-%s) | %s (%s-%s) | %s | %s |" % (
            nome, r["hmin"], r["hmin_late"], r["lmin"], fk(med(hp)) if hp else "-", fk(pct(hp, .1)) if hp else "-",
            fk(pct(hp, .9)) if hp else "-", fk(med(r["hall_s"])), fk(pct(r["hall_s"], .1)), fk(pct(r["hall_s"], .9)),
            fk(med(r["hall_k"])), ", ".join("%s %d" % kv for kv in sorted(r["fins"].items()))))
    print("\n### Minuto (na campanha) de cada vitoria, politica padrao, campanhas com a arvore de Legado cheia (mediana)")
    for nome, seqs in res.items():
        if not nome.endswith("padrao"):
            continue
        rs = [r for s in seqs for r in s if r["arvore_cheia"]]
        cel = []
        for o in ("opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"):
            v = [r["vit_t"][o] for r in rs if o in r["vit_t"]]
            cel.append("%s %s" % (f5.OPP_CURTO[o], mm(med(v)) if v else "-"))
        print("- %s (%d campanhas): %s" % (nome, len(rs), ", ".join(cel)))
    return res


def metas(res, rotulo):
    print("\n### Metas da visao: %s" % rotulo)
    print("| perfil | campanha 1: fim (med) | 1a derrota da campanha 1 (med) | cinturao na campanha 1 | cinturao amador: campanha (med; p10-p90) | cinturao na 2a-4a (ou antes) | morto campanha 1 (p90) | morto academia (p90) | proxima coisa academia (p90) |")
    print("|---|---|---|---|---|---|---|---|---|")
    for nome, seqs in res.items():
        f1 = [s[0]["t"] for s in seqs if not s[0]["t_belt"]]
        d1 = [s[0]["t"] for s in seqs if s[0]["fim"] == "derrota" and not s[0]["t_belt"]]
        kb = [next((r["k"] for r in s if r["t_belt"]), 99) for s in seqs]
        m1 = [s[0]["morto"] for s in seqs]
        mg = [r["morto_gym"] for s in seqs for r in s if r["morto_gym"] is not None]
        ga = [r["gaps"][1] for s in seqs for r in s if r["gaps"][1] is not None]
        print("| %s | %s | %s | %.1f%% | %s (%s-%s) | %.0f%% | %s | %s | %s |" % (
            nome, mm(med(f1)) if f1 else "-", mm(med(d1)) if d1 else "-", 100.0 * sum(1 for s in seqs if s[0]["t_belt"]) / len(seqs),
            fk(med(kb)), fk(pct(kb, .1)), fk(pct(kb, .9)), 100.0 * sum(1 for x in kb if x <= 4) / len(kb),
            mm(pct(m1, .9)), mm(pct(mg, .9)) if mg else "-", mm(pct(ga, .9)) if ga else "-"))


def sec_metas(n, K):
    base = []
    for cps, arte, nm in ((5, "boxing", "Boxe 5/s"), (4, "boxing", "Boxe 4/s"), (3, "boxing", "Boxe 3/s"),
                          (5, "bjj", "Jiu-jitsu 5/s"), (3, "bjj", "Jiu-jitsu 3/s")):
        base.append({"nome": nm, "cps": cps, "arte": arte})
    for modo, rot in (("vazio", "hall vazio e Honra 0 (= 6b2)"), ("normal", "hall comprado ao longo do jogo (robo padrao)"),
                      ("cheio", "hall cheio e retrato no teto DESDE a campanha 1 (caso extremo, impossivel no jogo)")):
        res = rodar6([dict(p, hall=modo) for p in base], n, K)
        metas(res, rot)
        if modo == "normal":
            print("- hall cheio (campanha, med): " + "; ".join("%s %s" % (nm, fk(med([next((r["k"] for r in s if r["hall_depois"] == len(HALL_CHEIO_IDS)), 99) for s in seqs])))
                                                           for nm, seqs in res.items()))


def sec_ident(n, K):
    """Com o hall desligado, a sequencia do 6c2 (politica padrao) da as mesmas lutas que o fase5_sim.sequencia."""
    proc = int(os.environ.get("SIM_PROC", str(max(1, (os.cpu_count() or 2) - 1))))
    t6 = [(4, 1000 + s, K, "padrao", "boxing", "vazio", f5.T_MAX5) for s in range(n)]
    t5 = [(4, True, "dica", 1000 + s, K, "memoria ate_algoz", "const", False, f5.T_MAX5, "boxing", "5") for s in range(n)]
    with Pool(proc, initializer=f5._init) as pool:
        a = pool.map(sequencia6, t6, chunksize=1)
        b = pool.map(f5.sequencia, t5, chunksize=1)
    iguais = 0
    for sa, sb in zip(a, b):
        la = [[(o, w, round(p, 2), round(t)) for (o, w, p, t) in r["lutas"]] for r in sa]
        lb = [r["lutas"] for r in sb]
        iguais += la == lb
    print("\n## Identidade: hall desligado x fase5_sim (Boxe 4/s, %d jogadores x %d campanhas): %d de %d sequencias identicas" % (n, K, iguais, n))


def sec_escolha(res):
    """Sair no dia da 2a luta x lutar: Legado + Honra (em Legado equivalente pela taxa do teto)."""
    taxa = 0.10 * 16810.0 / CUSTO_HALL
    print("\n## Sair x lutar no dia da 2a luta (Brutao). Taxa maxima: 1 Honra = 10%% x 16.810 / %d = %.1f Legado" % (CUSTO_HALL, taxa))
    car = f5.DADOS[4]
    lpf, bb = car["legacy_per_fame"], car["belt_legacy_bonus"]
    for nome, seqs in res.items():
        if not nome.endswith("padrao"):
            continue
        ps = [l[2] for s in seqs for r in s for l in r["lutas"] if l[0] == "opp_strong"]
        if not ps:
            continue
        print("- %s: chance no momento da 2a luta (med %.0f%%; p10 %.0f%%); lutas no vermelho (<40%%): %.1f%%" % (
            nome, 100 * med(ps), 100 * pct(ps, .1), 100.0 * sum(1 for p in ps if p < 0.40) / len(ps)))
    for fb in (0.0, 1.0, 2.0):
        f1 = int(math.floor(10 * (1 + fb) + 0.5))
        f2_ = f1 + int(math.floor(30 * (1 + fb) + 0.5))
        L1, L2 = math.floor(f1 * lpf), math.floor(f2_ * lpf)
        for h in (0.0, taxa):
            sair = L1 + h * honra(1, False)
            ganhar = L2 + h * honra(2, False)          # vence e sai na hora
            perder = math.floor(L1 * 0.5)
            pstar = (sair - perder) / (ganhar - perder)
            print("  fama x%.0f, Honra a %.1f L: sair %.0f; vencer e sair %.0f; perder %.0f -> lutar vale mais com chance > %.0f%%" % (
                1 + fb, h, sair, ganhar, perder, 100 * pstar))


def main():
    f5._init(quieto=True)
    global HALL
    secs = sys.argv[1:] or ["tudo"]
    tudo = "tudo" in secs
    n = int(os.environ.get("SIM_N6", "200"))
    K = int(os.environ.get("SIM_K6", "24"))
    print("Hall: %s | custo total %d | Honra por vitoria %s + cinturao %d | retrato +%.0f%% ate %d" % (
        [(x["id"], x["cost"]) for x in HALL["hall"]["nodes"]], CUSTO_HALL, HALL["honor"]["per_win"],
        HALL["honor"]["belt_bonus"], 100 * HALL["portrait"]["per_portrait"], HALL["portrait"]["max_portraits"]))
    print("Honra por vitorias (sem / com cinturao): " + ", ".join("%d: %d%s" % (w, honra(w, w >= 4), "" if w < 4 else "") for w in range(0, 7)))
    if tudo or "ident" in secs:
        sec_ident(int(os.environ.get("SIM_N_ID6", "32")), 10)
    res = None
    if tudo or "honra" in secs or "escolha" in secs:
        res = sec_honra(n, K)
    if tudo or "escolha" in secs:
        sec_escolha(res)
    if tudo or "metas" in secs:
        sec_metas(int(os.environ.get("SIM_N_METAS", "200")), 10)
    if tudo or "teto" in secs:
        sec_teto(int(os.environ.get("SIM_N_TETO", "64")))


if __name__ == "__main__":
    main()
