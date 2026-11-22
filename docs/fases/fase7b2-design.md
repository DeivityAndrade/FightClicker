# Fase 7b2 — Segundo caminho (a 2ª passiva das 3 artes): design

Designer de Jogo, 2026-11-21. Base: `fase7b-escopo.md` (§4, §6, §7 critérios 9–14 e **"Decisões do dono (2026-11-20)"**: meta M1,
5 vitórias pela passiva (o dono reduziu para **3** em 2026-11-21) somando a linhagem; a passiva é escolhida no começo da carreira e vale a carreira inteira; direções Boxe
"Contragolpista", Jiu-jitsu "Por cima", Muay Thai "Clinch"). Padrão seguido: `fase7a1-design.md` e `fase7b1-design.md`.
Simulador: `tools/sim/fase7b2_sim.py` (roda em cima do `fase7b1_sim.py`; **só acrescenta** 3 ramos novos no motor).
Dados gravados: `data/arts.json → arts[].passive_2` (as 3 passivas novas e a meta). Casos exatos: `tests/data/fase7b2_casos.json`.
Nomes e textos são provisórios: **[ROT]** marca o que o Roteirista troca.

## 0. A ideia em uma frase
| Arte | 1ª passiva (não muda) | **2ª passiva (nova)** | Atributo da 2ª | Tática da 2ª |
|---|---|---|---|---|
| Boxe | Mão rápida: pressiona, embalo, K.O. cedo, cansa no 3º | **Contragolpista [ROT]**: guarda alta, esquiva mais; cada esquiva vira contragolpe e **carga** (0–3); no **3º round** o golpe com carga pode ser K.O. Não cansa | AGILIDADE (esquiva) + RESISTÊNCIA (chegar inteiro ao 3º e pesar o K.O.) | **Contra-ataque** (1ª: Agressivo) |
| Jiu-jitsu | Finalização: aguenta, a pegada enche com o tempo, finaliza | **Por cima [ROT]**: cada acerto em pé pode **derrubar** já no 1º round; por cima bate mais rápido e apanha pouco; ele pode levantar; com ele ≤ 50% **o juiz para a luta** | **FORÇA** (derruba e segura; 1ª: RESISTÊNCIA) | **Agressivo** (1ª: Defensivo) |
| Muay Thai | Canela: marca a perna, ele manca, chute rodado | **Clinch [ROT]**: com ele ≤ 80%, o acerto pode **prender no clinch** por 3,5 s: ele não esquiva, a joelhada tem crítico alto e ele bate fraco; a RESISTÊNCIA dele solta; joelhada crítica com ele ≤ 40% derruba | FORÇA + **RESISTÊNCIA** (prende e segura; 1ª: FORÇA + AGILIDADE) | **Defensivo** ou Agressivo (1ª: Contra-ataque / Agressivo) |

A 2ª passiva **substitui** a 1ª (nunca soma). Cada uma muda **outra coisa** na luta: o Contragolpista muda a sua defesa e o
fim da luta (vence tarde); o Por cima muda **onde** a luta acontece (no chão desde o 1º round); o Clinch muda a **distância**
(colados, sem esquiva). Nenhuma passa a ser "a 1ª melhorada" (§7.3).

## 1. Regras gerais do motor (`scripts/luta.gd`)
1. **Sem arte e com a 1ª passiva: nada muda.** Os 3 tipos novos (`counter_punch`, `top_control`, `thai_clinch`) são ramos novos
   em `_rodar_arte()`. Medido: `fase7b2_sim.py ident` dá **3.000 de 3.000 lutas idênticas** ao motor da 7b1 (sem arte, Boxe, JJ, MT).
2. Mesmos **4 sorteios por ataque, de qualquer lado e na mesma ordem** (`r_esq, r_crit, r_var, r_arte`). **Novo:** nos ramos
   `top_control` e `thai_clinch`, o `r_arte` do **ataque normal dele** também é usado (levantar / soltar o clinch), e é lido **antes**
   de resolver o ataque. No `counter_punch` o `r_arte` dele continua sorteado e descartado.
3. Prévia, risco do HUD, robô, motivo da derrota e a luta usam a mesma função (`chance`, `passa`, `rodar`): a prévia continua
   honesta por construção (§8).
4. Qual passiva vale na luta: `career.art_passive` (1 ou 2, §10). `_academia._atualizar_passiva()` põe no motor `arts[arte].passive`
   (1) ou `arts[arte].passive_2` (2). O `extra` dos nós de arte (`art_fight_bonus`, raiz de cada região) vale para as duas (§6).
5. Todos os números vêm de `data/arts.json → arts[].passive_2`. Nada é constante no código. Campo que falta = neutro (mult 1, extra 0).

Fatores, como na 7a1: `F(meu, dele, min, max) = clamp(2·meu/(meu+dele), min, max)` sobre os **efetivos** (cru + 10% do total).
`tp = passive_2.tactics[tática]` (ou `{}`). A tática do jogador recebe `damage_mult × P.damage_mult` e `taken_mult × P.taken_mult`;
a do adversário é a NEUTRA. Laço, escolha de evento, crítico, contragolpe, variação, K.O. por dano e fim por pontos: **iguais a
hoje**. Fim pela passiva: `ko = true`, `t_ko = t`, `t_end = max(t, min_ko_time)`, vence o jogador.

## 2. Boxe — Contragolpista (`counter_punch`)
### 2.1 Estado fixo (prévia)
```
fa   = F(Agi_j, Agi_a, dodge_agility_min 0,5, dodge_agility_max 1,0)
esq0 = esquiva de hoje do jogador contra o ataque normal dele (golpe(ele → você) com a tática do jogador)
esq  = min(dodge_cap 0,75, esq0 + dodge_add × fa × tp.dodge_mult)           # "VOCÊ ESQUIVA x%"
fr   = F(Res_j, For_a, ko_endurance_min 0,5, ko_endurance_max 2,0)             # quem aguenta, pesa o K.O.
ko_max = min(ko_cap, charge_max × ko_per_charge × fr × tp.ko_mult × (1 + extra)) ;  ko_per_charge_ef = ko_max / charge_max
counter_mult = max(tática.counter_mult, P.counter_mult)                       # SEMPRE responde a esquiva
ko_from = (ko_from_round − 1) × round_length                                  # 10,67 s
```
### 2.2 Laço (igual ao `_lutar_contra` do simulador)
```
carga = 0; rounds_vistos = 0
a cada evento (antes dos sorteios): rd = floor(t / round_length); se rd > rounds_vistos: carga = min(3, carga + charge_per_round × (rd − rounds_vistos))
ataque normal dele, esquivado por você (r_esq < esq): carga = min(3, carga + tp.charge_per_dodge); agenda o seu contragolpe (0,5 s)
seu contragolpe: dano × counter_mult × counter_power (1,3)
acerto seu que não derrubou, t ≥ ko_from, carga > 0, vida dele ≤ ko_life_max (60%):
    attempts += 1; r_arte < carga × ko_per_charge_ef × (1 se contragolpe, senão hit_ko_mult 0,5) → fim "counter_ko"
ritmo: attack_interval × interval_mult (1,8 s) a luta toda — não cansa
```
### 2.3 Números
| Regra | Valor |
|---|---|
| Dano / dano recebido | **×0,80 / ×0,90** (guarda alta; os contragolpes compensam) |
| Esquiva a mais | **+8% × fa** (fa até 1,0: não cresce além da agilidade igual) |
| Carga | 0–3: **+1 a cada round que começa** (2º e 3º) e **+1 por esquiva** (+2 no Contra-ataque) |
| Contragolpe | sempre que você esquiva (mesmo fora do Contra-ataque), ×1,3 |
| K.O. | só do **3º round**, com ele ≤ 60%: carga × 7% × fr por contragolpe (metade em acerto normal); carga 3 e fr 1,0 = **21%**; teto 60% |
| Táticas | **Contra-ataque**: carga +2 por esquiva (e a esquiva ×2 da tática); **Defensivo**: K.O. ×0,75 (crítico dele não entra); **Agressivo**: esquiva a mais ×0,5 e K.O. ×0,5 ("no Agressivo você não espera") |

## 3. Jiu-jitsu — Por cima (`top_control`)
### 3.1 Estado fixo
```
ft  = F(For_j, Agi_a, td_strength_min 0,5, td_strength_max 1,3)              # sua FORÇA contra a AGILIDADE dele
td  = min(td_cap 0,8, td_base 0,30 × ft × tp.td_mult × (1 + extra))           # queda por acerto em pé
fe  = F(Agi_a, For_j, escape_agility_min 0,5, escape_agility_max 2,0)        # a AGILIDADE dele contra a sua FORÇA
esc = min(escape_cap 0,6, escape_base 0,20 × fe × tp.escape_mult)            # ele levanta, por ataque dele
```
### 3.2 Laço (`_lutar_cima`)
```
chao = false
seu ritmo: attack_interval × interval_mult (1,25 → 2,25 s) em pé; × top_interval_mult (0,8 → 1,8 s) por cima
ataque normal DELE com chao: ANTES de resolver, r_arte < esc → chao = false, levantou += 1 (o ataque sai em pé)
por cima: seu dano × top_damage_mult (1,0); esquiva dele × bottom_dodge_mult (0,5); dano dele × bottom_damage_mult (0,6)
acerto seu que não derrubou:
   em pé:   r_arte < td → chao = true, quedas += 1 (golpe "takedown"; queda_em = t na 1ª)
   por cima: se vida dele ≤ stop_life_max (50%): attempts += 1; r_arte < stop_chance (35%) → fim "ground_stop"
```
### 3.3 Números
| Regra | Valor |
|---|---|
| Dano por golpe | **×1,15** (JJ da 1ª: ×1,20) |
| Queda | 30% × ft por acerto em pé (ft 1,0–1,3) × tática; Agressivo ×1,5 → **45–58%**: quase sempre **no 1º round** |
| Por cima | você 1,8 s por golpe (em pé 2,25 s); ele esquiva metade e bate **×0,6** |
| Ele levanta | 20% × fe por ataque dele (Kid ágil: 15–19%; Muralha/Tonhão: 12–14%; Defensivo: metade) |
| Juiz para | por cima, com ele ≤ 50%: **35% por acerto** |
| Táticas | **Agressivo**: queda ×1,5; **Defensivo**: queda ×1,0 e ele levanta ×0,5 (controle); **Contra-ataque**: neutro |
Não finaliza (não há pegada): a vitória "pela passiva" é o juiz parar a luta por cima.

## 4. Muay Thai — Clinch (`thai_clinch`)
### 4.1 Estado fixo
```
fs  = F(For_j, For_a, 0,5, 2,0)                                               # sua FORÇA contra a FORÇA dele
ent = min(clinch_cap 0,8, clinch_base 0,30 × fs × tp.clinch_mult × (1 + extra))   # prender, por acerto
fe  = F(Res_a, Res_j, 0,5, 2,0)                                               # a RESISTÊNCIA dele contra a sua
esc = min(escape_cap 0,8, escape_base 0,25 × fe × tp.escape_mult)            # soltar, por ataque dele
crit_now  = crítico normal do jogador contra ele
knee_crit = max(crit_now, min(crit_cap 0,6, crit_now + clinch_crit_add 0,30))
knee_ko   = min(1, P.knee_ko 0,5 × tp.knee_mult);   knee_dmg = P.knee_damage_mult × tp.knee_damage_mult
```
### 4.2 Laço (`_lutar_clinch`)
```
preso_ate = −1; preso = t < preso_ate (lido no começo de cada evento)
seu ritmo: attack_interval (1,8 s); preso: × clinch_interval_mult (0,75 → 1,35 s)
ataque normal DELE preso: ANTES de resolver, r_arte < esc → solta (preso_ate = t; soltou += 1)
preso: você → esquiva dele 0, crítico = knee_crit, dano × knee_dmg; ele → dano × clinch_taken_mult (0,6)
acerto seu que não derrubou:
   preso e crítico (joelhada) e vida dele ≤ knee_life_max (40%): attempts += 1; r_arte < knee_ko → fim "knee_ko"
   solto e vida dele ≤ clinch_life_max (80%): r_arte < ent → preso_ate = t + clinch_s (3,5 s), clinches += 1 (golpe "clinch")
```
### 4.3 Números
| Regra | Valor |
|---|---|
| Dano por golpe | **×0,86** (Canela: ×0,88) |
| Prender | com ele ≤ 80%: 30% × fs por acerto × tática; Defensivo ×1,5 (**~45–60%**), Agressivo ×0,5 |
| No clinch (3,5 s) | ele **não esquiva**; você joelha a cada 1,35 s com **crítico +30%** (teto 60%); ele bate **×0,6** |
| Soltar | 25% × fe por ataque dele (Kid e Tonhão, RES altíssima: ~35%) |
| Joelhada que derruba | crítico no clinch, ele ≤ 40%: 50% (Agressivo 65%) |
| Táticas | **Defensivo**: prende ×1,5, solta ×0,6, joelhada ×1,4 de dano ("segura e joelha"); **Agressivo**: prende ×0,5, derruba ×1,3; **Contra-ataque**: neutro |
Sem marcas e sem chute rodado: o adversário **não manca** (é o que separa as duas passivas na tela).

## 5. Táticas × passiva (resumo para a tela e o QA)
| Tática | Mão rápida | **Contragolpista** | Finalização | **Por cima** | Canela | **Clinch** |
|---|---|---|---|---|---|---|
| Agressivo | **K.O. ×1,5**, ele contragolpeia | esquiva extra ×0,5, K.O. ×0,5 | pegada ×0,75 | **queda ×1,5** | marca ×1,5, ele contragolpeia | prende ×0,5, derruba ×1,3 |
| Defensivo | K.O. ×0,75, não cansa | K.O. ×0,75 | **pegada ×1,5** | ele levanta ×0,5 | marca ×0,75, lentidão ×1,5 | **prende ×1,5, solta ×0,6, joelhada ×1,4** |
| Contra-ataque | contragolpe +2 de embalo | **+2 de carga por esquiva** | neutro | neutro | **contragolpe marca** | neutro |

Tática que o robô escolheu (maior chance na prévia; no empate perto de 100% ele fica no Agressivo), lutas com arte, campanha §14:
| | Agressivo | Defensivo | Contra-ataque |
|---|---|---|---|
| Mão rápida / **Contragolpista** | 62% / **69%** | 34% / **23%** | 4% / **8%** |
| Finalização / **Por cima** | 79% / **74%** | 18% / **22%** | 3% / **3%** |
| Canela / **Clinch** | 56% / **48%** | 38% / **50%** | 6% / **2%** |
O robô só olha a chance. Quem quer **ver** a passiva escolhe a tática dela pagando poucos pontos: o Contragolpista no
Contra-ataque leva **5–6 de cada 10 vitórias** ao K.O. no contragolpe (§8.2); no Agressivo, 0–1.

## 6. Nós da árvore (nenhum muda de custo nem de valor)
O `art_fight_bonus` da raiz de cada região (0,5) reforça a passiva que estiver ativa:
| Nó | 1ª passiva (hoje) | **2ª passiva** | Texto da 2ª (`effect_text_2`, **[ROT]**) |
|---|---|---|---|
| `box_counter` (200) | K.O. ×1,5 | **K.O. do contragolpe ×1,5** (`ko_max × (1+extra)`) | "CONTRAGOLPISTA: K.O. +{pct}%" |
| `bjj_guard` (200) | pegada ×1,5 | **queda ×1,5** (`td × (1+extra)`) | "POR CIMA: DERRUBA {pct}% MAIS" |
| `mt_shin` (200) | marca ×1,5 | **prende ×1,5** (`ent × (1+extra)`) | "CLINCH: PRENDE {pct}% MAIS" |
Campo novo opcional no nó: `effect_text_2` (texto quando a 2ª passiva está escolhida; sem ele, o texto de hoje). Os nós ESTILO e os
pequenos são de treino: não mudam. A regra de treino e o aparelho da arte **não mudam** com a passiva.

## 7. Foco certo e escolha real (critério 10)
### 7.1 Amarelo (onde a campanha se decide): chance com a melhor tática (e qual), total = 0,9 × o dele (`fase7b2_sim.py foco`)
A/D/C = Agressivo / Defensivo / Contra-ataque. Em negrito, o que muda entre as duas passivas da mesma arte.
| Adversário | F/A/R | Mão rápida | **Contragolpista** | Finalização | **Por cima** | Canela | **Clinch** |
|---|---|---|---|---|---|---|---|
| Tonhão | 1/1/1 | 98% A | 96% **C** | 96% C | 100% A | 93% A | 92% C |
| | 2/1/1 | 98% A | 91% **C** | 94% C | **100% A** | 95% C | 88% **D** |
| | 1/2/1 | 88% C | 92% C | 92% C | 98% C | 88% C | 87% C |
| | 1/1/2 | 100% A | 94% A | 94% A | 100% A | 96% A | 88% A |
| | 1/2/2 | 93% C | 92% C | 94% C | 98% A | 92% C | 82% C |
| Kid | 1/1/1 | 98% A | 94% A | 97% A | 100% A | 98% A | 93% A |
| | 2/1/1 (FORÇA) | 78% A | 74% A | 88% D | **96% A** | 84% A | **89% D** |
| | 1/2/1 (AGILIDADE) | 82% A | 68% C | 78% C | 88% A | **80% A** | **57% C** |
| | 1/1/2 (RESISTÊNCIA) | 78% A | 74% A | **96% A** | 99% A | 84% A | 70% A |
| | 2/2/1 (FOR + AGI) | 88% A | 73% C | 78% D | 96% A | **87% A** | 76% D |
| | 2/1/2 (FOR + RES) | 79% A | **82% A** | 98% A | 98% A | 88% A | **86% D** |
| | 1/2/2 (AGI + RES) | **92% A** | 83% A | 83% A | 94% A | 88% A | 72% A |
Contra o Muralha a tabela é a mesma em forma (está na saída do simulador).

### 7.2 Foco ideal: as 3 divisões F/A/R que chegam ao verde (90%) com o menor total (× o total dele; `fase7b2_sim.py ideal`)
| | Muralha | Tonhão | Kid | Amarelo (40%) contra o Kid |
|---|---|---|---|---|
| Mão rápida | 40/20/40 0,76 | 30/20/50 0,81 | 30/30/40 0,87 · 30/40/30 0,89 | **30/40/30** 0,78 · 40/40/20 0,79 |
| **Contragolpista** | 40/20/40 0,80 | 40/20/40 0,82 | 30/30/40 0,85 · 20/30/50 0,89 | 30/40/30 0,76 · **20/40/40** 0,78 · 40/10/50 0,78 |
| Finalização | 40/20/40 0,77 | 40/30/30 0,81 | 30/30/40 0,85 | 60/10/30 0,62 · 30/10/60 0,68 |
| **Por cima** | 40/20/40 **0,67** | 40/20/40 **0,70** | **40/20/40** 0,82 · 50/20/30 0,84 | 50/10/40 0,67 |
| Canela | 40/20/40 0,77 | 50/20/30 0,80 | 30/30/40 0,85 | **20/40/40** 0,69 · 30/40/30 0,71 |
| **Clinch** | 40/20/40 0,81 | **40/10/50** 0,84 · 60/10/30 0,84 | 50/30/20 0,87 | **60/10/30** 0,73 · 50/10/40 0,73 |

### 7.3 Escolha real (critério 10): cada 2ª pede outro foco **ou** outra tática
| Arte | 1ª passiva | 2ª passiva | O que muda |
|---|---|---|---|
| Boxe | AGILIDADE, **Agressivo** (K.O. ×1,5) | AGILIDADE + **RESISTÊNCIA**, **Contra-ataque** (carga ×2; contra Muralha e Tonhão é a melhor tática em quase toda divisão) | **tática** (e um pouco de foco: o Contragolpista quer chegar inteiro ao 3º round; no Kid 2/1/2 ele é o melhor do Boxe, 82% × 79%) |
| Jiu-jitsu | **RESISTÊNCIA** (1/1/2: 96% no Kid), **Defensivo** (pegada) | **FORÇA** (2/1/1: 96% × 88%), **Agressivo** (queda ×1,5) | **foco e tática** |
| Muay Thai | FORÇA + **AGILIDADE**, Contra-ataque / Agressivo (1/2/1: 80%) | FORÇA + **RESISTÊNCIA**, **Defensivo** (2/1/1: 89% D × 84% A; 2/1/2: 86% D) — com AGILIDADE cai para 57% | **foco e tática** (o Clinch é a única passiva do jogo que quer o Defensivo para atacar) |

### 7.4 Nenhuma 2ª passiva é a 1ª melhorada (critério 11): limiar, total para o amarelo / verde (média de 4 divisões; menor = mais forte)
| Adversário | Mão rápida | **Contragolpista** | Finalização | **Por cima** | Canela | **Clinch** |
|---|---|---|---|---|---|---|
| Brutão | 0,636 / 0,872 | 0,672 / **0,887** pior | 0,669 / 0,875 | 0,572 / 0,814 | 0,686 / 0,943 | 0,691 / **0,948** pior |
| Dinho | 0,541 / 0,657 | 0,507 / 0,629 | 0,476 / 0,619 | 0,487 / **0,631** pior | 0,509 / 0,630 | 0,451 / 0,600 |
| Muralha | 0,709 / 0,811 | 0,691 / **0,850** pior | 0,664 / 0,835 | 0,614 / 0,752 | 0,653 / 0,831 | 0,744 / **0,871** pior |
| Tonhão | 0,724 / 0,846 | 0,693 / **0,867** pior | 0,668 / 0,870 | 0,619 / 0,775 | 0,644 / 0,865 | 0,756 / **0,904** pior |
| Kid | 0,818 / 0,914 | 0,813 / **0,937** pior | 0,726 / 0,913 | 0,719 / 0,854 | 0,770 / 0,910 | 0,822 / **0,943** pior |
| **Média** | 0,686 / 0,820 | 0,675 / 0,834 | 0,641 / 0,822 | 0,602 / 0,765 | 0,652 / 0,836 | 0,693 / 0,853 |
- **Contragolpista**: mais forte no amarelo (vira a luta tarde), **mais fraco no verde contra todos**. Pede para chegar ao 3º round.
- **Clinch**: melhor só contra o **Dinho** (ágil: no clinch ele não esquiva); pior contra os de RESISTÊNCIA alta (Muralha, Tonhão, Kid
  soltam). É o oposto da Canela, que brilha contra quem aguenta.
- **Por cima**: pior só contra o **Dinho** (ágil: levanta e esquiva). É a mais forte das seis **nesta medida**, porque a média das 4
  divisões dá FORÇA de sobra; no lutador que o robô treina (o boneco do JJ puxa RESISTÊNCIA: 37/15/48 contra o Kid) ela empata com a
  Finalização (§14.2) e a campanha dela é a mais lenta a 3/s. Ver o risco na §14.4.

## 8. Prévia honesta (critério 12)
### 8.1 A conta
- `estado_passiva(jog, adv, tática)` devolve, além de `kind`: Contragolpista `{agi_factor, dodge_now, dodge, dodge_add, end_factor,
  charge_max, charge_per_dodge, ko_max, ko_per_charge, ko_from, ko_round, counter_power, counter_mult}`; Por cima `{str_factor, td_chance,
  opp_agi_factor, escape, stop_life, stop_chance, top_damage_mult, bottom_damage_mult}`; Clinch `{str_factor, clinch_chance,
  opp_end_factor, escape, clinch_life, clinch_s, crit_now, knee_crit, knee_ko, knee_life, knee_chance, knee_damage_mult}`.
- `chance_detalhada()` (as mesmas 200 sementes) conta também: `wins_passive` (fim = `counter_ko` / `ground_stop` / `knee_ko`);
  Contragolpista `charge_med` (mediana da carga máxima); Por cima e Clinch `share` (em quantas lutas derrubou / prendeu) e `at`
  (mediana do 1º instante; −1 se nunca). `chance()` não muda.
### 8.2 A linha da prévia (por tática em `passive_tactics`; textos **[ROT]**)
| Passiva | `passive_line` | Exemplo (Kid, você 0,9×, 1/1/1) |
|---|---|---|
| Contragolpista | `VOCÊ ESQUIVA {d}% · CADA ESQUIVA CARREGA (+{c}) · NO 3º ROUND, K.O. ATÉ {k}% POR GOLPE` (Agressivo: `passive_..._line_aggressive` "NO AGRESSIVO VOCÊ NÃO ESPERA") | Contra-ataque: esquiva 13% → 21%, K.O. até 26%, 78%, **5 em 10** por K.O. no contragolpe; Agressivo: 94%, 1 em 10 |
| Por cima | `DERRUBA {p}% POR ACERTO (NO {r}º ROUND) · ELE LEVANTA {e}% · ABAIXO DE 50% O JUIZ PARA ({s}%)`; se `share < 0,5`: `_line_late` "SÓ DERRUBA EM {x} DE 10 LUTAS" | Agressivo: queda 48%, 1º round (98% das lutas), levanta 19%, 100%, 5 em 10 pelo juiz |
| Clinch | `ABAIXO DE 80% PRENDE {p}% POR ACERTO (NO {r}º ROUND) · NO CLINCH: JOELHADA {k}% DE CRÍTICO · ELE SOLTA {e}%`; se `share < 0,5`: `_line_late` | Defensivo: prende 56%, 2º round (100% das lutas), solta 19%, joelhada 38%, 90% |
`passive_share` = `{n} EM 10 VITÓRIAS POR {FIM}` (K.O. NO CONTRAGOLPE / O JUIZ PAROU / JOELHADA **[ROT]**).
### 8.3 Medida (critério 12): 1.000 lutas por adversário (`fase7b2_sim.py honesta`)
Estado = atributos reais do robô com a 2ª passiva × 0,6..1,4, tática sorteada, semente real aleatória. A 1ª passiva não mudou: vale a
medida da 7a1 (§7.4, pior 1,0) e da 7b1 (§6.3, pior 1,2).
| Passiva | Dudu | Brutão | Dinho | Muralha | Tonhão | Kid |
|---|---|---|---|---|---|---|
| Contragolpista (mostrada → real) | 85,9 → 87,0 | 84,9 → 83,5 | 78,5 → 79,9 | 81,2 → 81,9 | 80,2 → **82,4 (+2,2)** | 70,6 → 70,9 |
| Por cima | 85,8 → 83,9 | 82,7 → 82,5 | 84,7 → 83,1 | 85,6 → 85,6 | 78,4 → 77,6 | 66,8 → 66,1 |
| Clinch | 82,5 → 82,2 | 83,1 → 83,3 | 73,0 → 72,3 | 77,3 → 76,9 | 77,6 → 77,7 | 64,4 → 63,5 |
**Pior diferença 2,2 pontos** (meta ±5). Vitórias pela passiva (de 1.000 lutas) contra Muralha / Tonhão / Kid: Contragolpista 109 / 152 /
173; Por cima 351 / 340 / 274; Clinch 167 / 192 / 131. Contra os amadores a luta acaba por dano antes. **Tela: 8,0–19,0 s** nas três
(critério de luta curta). O Contragolpista com K.O. só sai depois de 10,7 s (tela ≥ 14 s nessas lutas).

## 9. A meta (M1) e o progresso (critério 9)
### 9.1 Regra
- **Conta** (`permanent.passive_wins[arte] += 1`): luta da escada (inclusive revanche) **vencida**, numa carreira com a arte e com a
  **1ª passiva**, que terminou pela 1ª passiva: Boxe `finish == "knockout"` (K.O. de embalo), Jiu-jitsu `"submission"`, Muay Thai
  `"spin_kick"`. O `finish` exigido vem de `passive_2.unlock.finish` (dado, não código).
- **Não conta**: vitória por dano ou por pontos; vitória com a 2ª passiva; derrota; minigame; 1ª carreira (sem arte).
- Soma a linhagem inteira (todas as carreiras, todos os lutadores). Grava no mesmo `salvar()` de `concluir_luta`.
- Ao chegar a `count` (**3**): `passives_unlocked += arte`, marco `passive2_<arte>_unlocked`, sinal `permanente_mudou`. Na tela de fim
  da luta (ou da carreira), 1 linha **[ROT]** ("NOVO JEITO DE LUTAR: {NOME}. ESCOLHA NA PRÓXIMA CARREIRA"); fala curta do mentor da
  vez, opcional, uma vez. Sem aviso insistente. A carreira atual não muda.
- Vitórias pela 2ª passiva (`counter_ko`, `ground_stop`, `knee_ko`) ficam só nos números da carreira (não liberam nada).
- O Muay Thai só existe depois do 1º Kid (7b1); a meta dele começa a contar a partir daí.
### 9.2 Progresso visível (critério 9)
Cartão da arte: "{n}/3 K.O. DE EMBALO" / "{n}/3 FINALIZAÇÕES" / "{n}/3 CHUTES RODADOS" **[ROT]** sob a 2ª opção com cadeado;
`n = min(passive_wins[arte], count)`. Teste com lutas montadas: 2 vitórias por `knockout` + 2 por dano = "2/3" e cadeado; a 3ª por
`knockout` libera.
### 9.3 Quanto tempo leva (meta **N = 3**, decisão do dono de 2026-11-21; campanhas **com a arte**, contando a da chegada à academia)
Medido de novo com N = 3 na Fase 8a1 (tarefa D4; `SIM_META_TAT=1 fase7b2_sim.py campanha`, 100 jogadores × 8 campanhas):
| | Vitórias pela 1ª passiva por campanha (4/s · 3/s) | Robô que **busca a meta** (tática da passiva se a chance cair ≤ 5 pontos): mediana; p90; nunca em 8 (4/s · 3/s) |
|---|---|---|
| Boxe (K.O. de embalo) | 1,66 · 1,55 | **3; 4; 0 · 3; 4; 1** |
| Jiu-jitsu (finalização) | 2,09 · 2,11 | **2; 3; 0 · 2; 3; 0** |
| Muay Thai (chute rodado) | 1,35 · 1,24 | **3; 4; 0 · 3; 5; 1** |
Com N = 3 dá **2–3 campanhas com a arte** para quem joga a passiva (o Muay Thai fica em 3 na mediana: não precisa de meta por arte).
O robô padrão, que só olha a chance, leva cerca de 1 campanha a mais (revisão da 7b2, R4). Buscar a meta **não custa tempo**: o tempo
até o Kid desse robô fica a 2,1% entre as artes na mediana (4/s) e 1,1% (3/s).
O `count` está no dado (`passive_2.unlock.count`). **Decisão do dono (2026-11-21): N = 3** → cerca de 2 campanhas com a arte.

## 10. Save
**Continua v13** (só campos opcionais; save antigo abre igual, sem migração):
| Onde | Campo | Valor | Validação |
|---|---|---|---|
| `permanent` | `passive_wins` | `{art_id: int}` — vitórias pela 1ª passiva, somando a linhagem | inteiro ≥ 0; arte que não existe sai; ausente = `{}` |
| `permanent` | `passives_unlocked` | `[art_id]` — artes com a 2ª passiva liberada | só ids de `arts.json` com `passive_2`; ausente = `[]`; **também** libera se `passive_wins[arte] ≥ count` (conserto ao carregar) |
| `permanent` | `last_passive` | `{art_id: 1\|2}` — para deixar marcado no cartão a última escolha | 2 só se liberada; senão 1 |
| `career` | `art_passive` | `1 \| 2` | ausente = 1; 2 sem a arte liberada = 1 (com aviso de carga) |
| `career.fight.result` | `finish` | ganha `"counter_ko"`, `"ground_stop"`, `"knee_ko"` | aceito só com a passiva do tipo certo |
| marcos | `passive2_<art>_unlocked` | marco novo (1 por arte) | para a linha da tela de fim e a fala do mentor saírem uma vez |
Save antigo: `passive_wins` começa em 0 (o save não guarda o histórico de como cada luta acabou). Ninguém perde nada; só não ganha
o que lutou antes da 7b2. A foto (`foto.gd`) sem arte sai igual à main.

## 11. A luta na tela (tudo só visual; dados para a UI e a arte)
### 11.1 Campos novos (resultado e eventos, só com a 2ª passiva)
| Passiva | Resultado | Evento | `luta_atual().passive` |
|---|---|---|---|
| Contragolpista | `finish "counter_ko"`, `charge_peak`, `attempts`, `opp_counter_damage` (0) | `charge` (0–3 depois do evento) | `"counter_punch"` |
| Por cima | `finish "ground_stop"`, `takedowns`, `stood_up`, `takedown_at` (−1), `attempts` | `ground` (bool depois do evento), `move` `"takedown"`/`"ground"`/`""` | `"top_control"` |
| Clinch | `finish "knee_ko"`, `clinches`, `released`, `clinch_at` (−1), `knees`, `attempts` | `clinch` (bool depois do evento), `move` `"clinch"`/`"knee"`/`"hit"` | `"thai_clinch"` |
### 11.2 O que se vê (o testador diz qual passiva é só olhando — critério 10)
| | 1ª passiva | **2ª passiva** |
|---|---|---|
| Boxe | socos rápidos, embalo (5 bolinhas), K.O. cedo, cansado no 3º | **guarda alta** entre os golpes (pose `block` no lugar do idle), muitas **esquivas** ("ESQUIVOU") seguidas de **contragolpe** (`uppercut`/`heavy`), **3 pips de carga** ao lado da sua vida; o fim vem no 3º round: letreiro **"K.O. NO CONTRAGOLPE!" [ROT]** |
| Jiu-jitsu | em pé até a pegada encher, queda no meio da luta, **bate no chão** (`tap_out`), "FINALIZOU!" | **queda no 1º round** (`takedown`/`fall`), a luta quase toda no chão com `ground_pressure`; quando ele levanta, texto pequeno "LEVANTOU" **[ROT]** e os dois de pé; o fim: letreiro **"O JUIZ PAROU!" [ROT]** sem `tap_out` |
| Muay Thai | chute baixo, **ele manca**, marcas, chute rodado | **sem marcas e sem mancar**; os dois **colados** (`thai_clinch` + `held_clinch`) por 3,5 s com **joelhadas** (`knee`); ao soltar, voltam à distância; o fim: letreiro **"JOELHADA!" [ROT]** e a queda do K.O. |
### 11.3 Golpes (`moves.json`) — reaproveitados
| Passiva | Golpe por evento |
|---|---|
| Contragolpista | acerto normal: `jab`/`hook`/`body_shot`; contragolpe: `uppercut`/`heavy`; fim: `uppercut` + queda do K.O. Idle = `block` |
| Por cima | em pé: `clinch_push`; queda: `takedown` (kind `takedown`, reação `fall`); por cima: `ground_pressure` (ele: `ground_punch` do estilo `ground_bottom`); levantou: os dois voltam ao idle em pé; fim: `ground_pressure` + letreiro (reação `ground_hit`) |
| Clinch | solto: `low_kick`/`knee` (sem marcar); prende: `thai_clinch` (reação `held_clinch`); preso: `knee` (reação `held_clinch`); fim: `knee` + queda do K.O. |
Kinds novos em `MovesData.KINDS`: `counter_ko`, `ground_stop`, `knee_ko` (só para escolher o golpe do último evento; fallback de sempre).

Nomes no simulador → no jogo: `carga_pico`→`charge_peak`, `quedas`→`takedowns`, `levantou`→`stood_up`, `queda_em`→`takedown_at`,
`clinches`, `soltou`→`released`, `clinch_em`→`clinch_at`, `joelhadas`→`knees`, `tentativas`→`attempts`; método `contragolpe_ko`/`por_cima`/`joelhada`
→ `finish` `counter_ko`/`ground_stop`/`knee_ko` (o `fase7b2_casos.json` já usa os nomes do jogo no `finish`). Evento: `charge`, `ground`
ou `clinch` (bool, no índice 7 da lista do caso), `move`.

## 12. Motivo da derrota (1 linha, sem simulação nova; a 1ª que valer, nesta ordem)
| Passiva | Id | Quando | Texto provisório **[ROT]** | Dica **[ROT]** |
|---|---|---|---|---|
| Contragolpista | `cp_early` | perdeu antes do 3º round (`t_fim < ko_from`) | VOCÊ CAIU ANTES DO 3º ROUND | "RESISTÊNCIA PARA CHEGAR INTEIRO AO 3º" |
| | `cp_held` | `attempts ≥ 1`, sem K.O. | ELE AGUENTOU {n} CONTRAGOLPES | "NO CONTRA-ATAQUE CADA ESQUIVA VALE 2 DE CARGA" |
| | `cp_never_hurt` | chegou ao 3º, `attempts = 0` | ELE NUNCA BAIXOU DE 60% | "MAIS FORÇA PARA CANSAR ELE" |
| Por cima | `tc_no_takedown` | `takedowns = 0` | VOCÊ NÃO CONSEGUIU DERRUBAR | "FORÇA DERRUBA. O AGRESSIVO DERRUBA MAIS" |
| | `tc_stood_up` | `stood_up ≥ 2` | ELE LEVANTOU {n} VEZES | "FORÇA SEGURA. O DEFENSIVO NÃO DEIXA ELE LEVANTAR" |
| | `tc_never_hurt` | por cima e `attempts = 0` | ELE NUNCA BAIXOU DE 50% | "MAIS FORÇA PARA CASTIGAR" |
| Clinch | `cl_never` | `clinches = 0` | VOCÊ NÃO PRENDEU NO CLINCH | "FORÇA PRENDE. O DEFENSIVO PRENDE MAIS" |
| | `cl_released` | `released ≥ 2` | ELE SOLTOU DO CLINCH {n} VEZES | "RESISTÊNCIA SEGURA O CLINCH" |
| | `cl_held` | `attempts ≥ 1`, sem queda | ELE AGUENTOU {n} JOELHADAS | "NO AGRESSIVO A JOELHADA DERRUBA MAIS" |
Formato igual à 7a1: `motivo.passive_note = {id, n, r}`.

## 13. Escolha da passiva (cartão da arte)
- O cartão de cada arte ganha **2 opções** (1ª e 2ª passiva: nome + 1 linha `fight_text`). A 2ª aparece **com cadeado** e o progresso
  `{n}/3 {VITÓRIAS PELA 1ª}` **[ROT]** (ex.: "2/3 K.O. DE EMBALO", "1/3 FINALIZAÇÕES", "0/3 CHUTES RODADOS") até a meta.
- Escolher a arte escolhe a passiva marcada (padrão: `last_passive[arte]`, se liberada; senão a 1ª). Vale a carreira inteira.
- Liberada a meta, o cadeado sai; a escolha muda só na **próxima** carreira (a atual não muda).
- Artes sem `passive_2` (nenhuma, hoje) mostram 1 opção, como antes.

## 14. Balanço (critério 11)
### 14.1 Campanha (critério 11; `fase7b2_sim.py campanha`, robô padrão da 7a1, calendário, Legado, hall; 200 jogadores × 10 campanhas)
Toda arte entra "como se" liberada na 1ª chegada à academia (a mesma comparação da 7a1/7b1). A 1ª passiva dá **os mesmos números da
7a1/7b1** (motor idêntico, mesmas sementes): confere.
| Combinação | Kid na 1ª (4/s · 3/s) | Tempo até o 1º Kid, 4/s: mediana / média / p90 | 3/s: mediana / média / p90 | Vitórias: dano / passiva / pontos (4/s) | Tonhão / Kid pela passiva | Tela |
|---|---|---|---|---|---|---|
| Boxe Mão rápida | 92,5% · 78,5% | 41:04 / 44:57 / 57:41 | 46:18 / 56:19 / 85:53 | 7.321 / 2.620 / 293 | 52% / 53% | 8,0–19,0 s |
| **Boxe Contragolpista** | 92,0% · 84,5% | 40:51 / 44:51 / 61:16 | 45:56 / 52:23 / 71:54 | 9.036 / 556 / 605 | 13% / 12% | 8,0–19,0 s |
| Jiu-jitsu Finalização | 91,0% · 80,0% | 41:47 / 47:33 / 76:25 | 46:33 / 58:15 / 92:28 | 7.173 / 2.613 / 434 | 50% / 76% | 8,0–19,0 s |
| **Jiu-jitsu Por cima** | 94,5% · 75,0% | 41:49 / 46:30 / 57:22 | 46:30 / 62:34 / 103:46 | 6.859 / 2.326 / 760 | 51% / 55% | 8,0–19,0 s |
| Muay Thai Canela | 93,0% · 75,5% | 41:22 / 45:04 / 56:45 | 46:23 / 57:19 / 92:10 | 7.705 / 1.812 / 558 | 47% / 30% | 8,0–19,0 s |
| **Muay Thai Clinch** | 90,0% · 87,5% | 40:49 / 45:01 / 62:42 | 45:52 / 51:55 / 71:49 | 7.896 / 965 / 1.129 | 23% / 20% | 8,0–19,0 s |
| **Diferença entre as 6** | — | **mediana 2,4%** · média 6,0% | **mediana 1,5%** · média **20,5%** | | | |
- **Mediana: as seis a no máximo 2,4% (4/s) e 1,5% (3/s)** uma da outra — a meta de ficar bem perto (≤ 1–2%) está cumprida a 3/s e
  quase a 4/s. Cinturão: mediana de 2 campanhas em todas; a 1ª carreira não tem arte (13:56 / 15:26, iguais).
- **Média a 4/s: 6,0%** (o maior é a Finalização, igual à 7a1).
- **Média a 3/s: 20,5%, passa dos 15%.** É a cauda (1 em 10 jogadores que leva campanhas a mais): o Por cima (62:34) fica 7,4% atrás da
  Finalização, e o Contragolpista (52:23) e o Clinch (51:55) ficam 7–9% **à frente** das suas 1ªs. As três 1ªs passivas já tinham média
  56–58 a 3/s. Dentro de cada arte a diferença fica em **7–10%**.
- O que **não** mexe na média: tirei 10–15% de força do Contragolpista e do Clinch (dano ×0,78 / ×0,83) e a média deles não andou
  (52:44, 51:56); dei 30% a mais de chance de parar a luta ao Por cima e a dele também não andou (62:37). A cauda vem de quem chega ao Kid
  no amarelo baixo no dia da luta, e é ruído de 1 em 10 jogadores (a 7b1 mediu ~2% de oscilação entre rodadas na média, com cauda menor).
### 14.2 Robô contra o Kid: chance (melhor tática) nos atributos reais do robô × 0,7 / 0,8 / 0,9 / 1,0 (`fase7b2_sim.py robo`)
| | Muralha | Tonhão | Kid |
|---|---|---|---|
| Mão rápida | 34 / 67 / 89 / 99 | 31 / 61 / 86 / 99 | 2 / 23 / 68 / 96 |
| **Contragolpista** | 37 / 66 / 88 / 97 | 41 / 67 / 88 / 98 | 15 / 37 / 72 / 98 |
| Finalização | 64 / 81 / 94 / 100 | 52 / 71 / 92 / 99 | 28 / 53 / 80 / 95 |
| **Por cima** | 69 / 86 / 97 / 100 | 54 / 85 / 97 / 99 | 30 / 54 / 78 / 94 |
| Canela | 30 / 57 / 83 / 96 | 32 / 60 / 85 / 96 | 15 / 40 / 74 / 94 |
| **Clinch** | 24 / 51 / 79 / 95 | 21 / 47 / 75 / 93 | 15 / 42 / 79 / 96 |
Robô contra o Kid: Boxe 40/26/34, JJ 37/15/48, MT 46/21/33 (F/A/R). O robô treina igual com as duas passivas (o aparelho é o mesmo).
### 14.3 Como cheguei (só as 2ªs mudam)
| Versão | Contragolpista | Por cima | Clinch | 3/s média (B2 / J2 / M2) |
|---|---|---|---|---|
| 1ª | dano 0,85, K.O. 12%/carga, esquiva +12% | dano 1,0, por cima ×1,10, para ≤ 35% (50%) | dano 0,92, prende ≤ 80% | 50:28 / 67:02 / 50:27 (60 jog.) |
| 2ª | — | dano 1,20, por cima ×1,0, para ≤ 50% (30%), ele levanta 20% | dano 0,88 | — / 64:14 / — (60 jog.) |
| 3ª | K.O. 8%, esquiva +10% | dano 1,15, FORÇA até ×1,3 (tirar o excesso de quem treina FORÇA), levanta 25% | — | 51:31 / 62:12 / 51:51 |
| **final** | **dano 0,80, K.O. 7%, esquiva +8%** | **levanta 20%, para 35%** | **dano 0,86** | **52:23 / 62:34 / 51:55** |
### 14.4 Riscos e alavancas (para o QA e a revisão)
- **Por cima forte para quem treina FORÇA:** no foco ideal ele chega ao verde do Tonhão com 0,70× (Finalização 0,81×) e ao do Kid com
  0,82× (0,85×). Alavanca: `td_strength_max` (1,3 → 1,1) ou `top_interval_mult` (0,8 → 0,9). Não mexi mais porque, com o lutador que o
  robô treina, ele já é o mais lento a 3/s.
- **Contragolpista quase não vence pela passiva no robô** (12–13% contra Tonhão e Kid), porque o robô fica no Agressivo no empate. Na
  mão do jogador, no Contra-ataque, ele leva 5–6 de cada 10 vitórias ao K.O. no contragolpe (§8.2). O QA testa com o Contra-ataque.

## 15. Arte nova (pouca) e animações reaproveitadas
| Quem | Novo | Reaproveitado |
|---|---|---|
| Diretor de Arte | cadeado e barra de progresso no cartão; 3 ícones de passiva (`passive_counter_punch`, `passive_top_control`, `passive_thai_clinch`); pip de carga (HUD, 1×); 3 letreiros na família do K.O. ("K.O. NO CONTRAGOLPE!", "O JUIZ PAROU!", "JOELHADA!") | — |
| Artista de Personagens | **nada obrigatório**. Opcional (primeiro a cortar): idle "guarda alta" do boxeador (sem ele, `block`) | `block`, `dodge`, `jab`, `hook`, `body_shot`, `uppercut`, `heavy`; `clinch_push`, `takedown`, `fall`, `ground_top_idle`, `ground_pressure`, `ground_bottom_idle`, `ground_hit`, `ground_punch`; `low_kick`, `knee`, `thai_clinch`, `held_clinch`; quedas do K.O. |
Arena: nada muda (o chão do Por cima usa a faixa de 150 px da 7a1).

## 16. Contrato de dados
### 16.1 `data/arts.json → arts[].passive_2` (gravado)
Mesmo formato do `passive` (§14 da 7b1), mais:
| Campo | Valor | O que é |
|---|---|---|
| `unlock` | `{type: "passive_wins", count: 3, finish: "knockout" \| "submission" \| "spin_kick"}` | a meta M1 (finish = como a 1ª passiva vence) |
| `name`, `fight_text`, `icon` | provisórios **[ROT]** | cartão e prévia |
| `type` | `counter_punch` / `top_control` / `thai_clinch` | ramo do motor |
| números | §2.3, §3.3, §4.3 (a tabela inteira está no arquivo) | — |
Validação no `GymData`: recortar como os outros (chances 0–1; `charge_max` 1–5 inteiro; `clinch_s` 0,5–8; mults 0–3); `passive_2` inválido
= arte sem 2ª passiva (aviso no console). `GymData.REGRAS`/tipos de passiva += os 3 tipos.
### 16.2 Chaves de texto novas (`data/ui_texts.json`; Roteirista)
`passive_counter_punch_name`, `passive_counter_punch_line`, `passive_counter_punch_line_aggressive`, `passive_share_counter_punch`,
`passive_top_control_name`, `passive_top_control_line`, `passive_top_control_line_late`, `passive_share_top_control`,
`passive_thai_clinch_name`, `passive_thai_clinch_line`, `passive_thai_clinch_line_late`, `passive_share_thai_clinch`,
`fight_charge_full` ("CARGA!"), `fight_counter_ko`, `fight_stood_up` ("LEVANTOU"), `fight_ground_stop`, `fight_clinch` ("CLINCH!"),
`fight_knee_ko`, `reason_passive_cp_*`, `reason_passive_tc_*`, `reason_passive_cl_*`, `tip_passive_*`, `art_card_passive_locked`,
`art_card_passive_progress` ("{n}/{m} {fim}"), `passive_finish_knockout/submission/spin_kick` ("K.O. DE EMBALO" etc.),
`passive2_unlocked_line` (tela de fim) e a fala opcional do mentor por arte (`passive2_<art>_unlocked`, primeira a cortar).

## 17. Quem faz o quê
### Programador
1. `scripts/luta.gd`: os 3 ramos (referência linha a linha: `_lutar_contra`, `_lutar_cima`, `_lutar_clinch` em `tools/sim/fase7b2_sim.py`);
   `estado_passiva()` dos 3; `chance_detalhada()` com os números da prévia (§8); `nota_passiva()` (§12); campos da §11.1.
2. `GymData` lê e valida `passive_2`; `MovesData.KINDS` += 3.
3. `academia_artes`: `escolher_arte(arte, passiva)`, `_atualizar_passiva()` pela `career.art_passive`; meta: contar em `concluir_luta`
   (mesmo `salvar()`), liberar, marco, sinal `permanente_mudou`; funções para a tela: `progresso_passiva(arte) -> {n, m, finish, liberada}`.
4. Save (§10), prévia e textos (§8), luta na tela (§11), motivo (§12). `docs/codigo/mapa.md` atualizado.
5. Testes (save de teste, APPDATA temporário): (a) foto sem arte igual à main; (b) casos exatos `fase7b2_casos.json`; (c) 1ª passiva
   igual à 7b1 (casos 7a1/7b1 passam); (d) meta com lutas montadas: 2 vitórias pela 1ª = 2/3 e cadeado; a 3ª libera; vitória por dano
   não conta; vitória com a 2ª não conta; (e) save antigo sem os campos abre com 0/3; (f) `passive_note` de cada id.
### UI/UX
Cartão com 2 passivas, cadeado e progresso; linha da prévia das 3 novas nas 3 táticas; HUD (pips de carga; chão/de pé; clinch);
3 letreiros; linha da meta batida na tela de fim. `alinhamento-ui` com **0 problemas**.
### Roteirista
Tudo marcado **[ROT]** e as chaves da §16.2.
### QA
Critérios 9–14. Referências: §8 (prévia), §9 (meta), §14 (balanço). Rodar `fase7b2_sim.py ident honesta campanha`.

## 18. Resumo
- **Contragolpista (Boxe):** dano ×0,80, recebe ×0,90, esquiva +8%; toda esquiva vira contragolpe ×1,3 e +1 de carga (+2 no
  Contra-ataque), e cada round que começa dá +1; no 3º round, com ele ≤ 60%, K.O. até 21% por contragolpe (× fator de RESISTÊNCIA). Não
  cansa. Tática: Contra-ataque.
- **Por cima (JJ):** dano ×1,15; cada acerto em pé derruba (30% × FORÇA contra a AGILIDADE dele; Agressivo ×1,5 → quase sempre no 1º
  round); por cima ele esquiva metade e bate ×0,6; ele levanta 20% × fator por ataque; com ele ≤ 50% o juiz para (35% por acerto).
  Foco FORÇA, tática Agressivo.
- **Clinch (MT):** dano ×0,86; com ele ≤ 80% prende (30% × FORÇA contra FORÇA; Defensivo ×1,5) por 3,5 s: ele não esquiva, você joelha a
  cada 1,35 s com +30% de crítico, ele bate ×0,6 e solta 25% × RESISTÊNCIA dele; joelhada crítica com ele ≤ 40% derruba (50%). Foco
  FORÇA + RESISTÊNCIA, tática Defensivo. Sem marcas, sem mancar.
- **Meta:** 3 vitórias pela 1ª passiva (decisão do dono, 2026-11-21; era 5) (K.O. de embalo / finalização / chute rodado), somando a linhagem → ~2 campanhas com a arte.
- **Simulação:** 1ª passiva idêntica à 7b1 (3.000/3.000); prévia honesta pior **2,2 pontos**; tela **8–19 s**; tempo até o Kid a
  ≤ **2,4% na mediana** entre as 6; média 6,0% a 4/s e **20,5% a 3/s** (cauda; §14.1). Cada 2ª é pior que a 1ª em pelo menos 1
  adversário. Save **v13** com campos opcionais.
- **Arte nova:** só cadeado/progresso, 3 ícones, pip de carga e 3 letreiros. Nenhuma animação obrigatória.

**Decisões do dono (2026-11-21, "pode ser como vc recomenda"):** (1) meta **N = 3** vitórias pela 1ª passiva (`unlock.count` = 3
nas 3 artes), ~2 campanhas com a arte. (2) O equilíbrio entre as 6 combinações é medido **pela mediana** (≤ 2,4% a 4/s, 1,5% a 3/s),
como na 7b1; a cauda da média do Por cima a 3/s fica aceita e o Por cima não é fortalecido.
