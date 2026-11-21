# Fase 7b1 — Muay Thai: design

Designer de Jogo, 2026-11-20. Base: `fase7b-escopo.md` (§3, §6, §7 e **"Decisões do dono (2026-11-20)"**, que valem sobre o resto:
passiva A "Canela"; Muay Thai liberado na 1ª vitória contra o Kid).
Simulador: `tools/sim/fase7b1_sim.py` (roda em cima do `fase7a1_sim.py` e do `fase7a2_sim.py`; **só acrescenta** o ramo `shin`).
Dados já gravados: `data/arts.json` (arte `muay_thai`), `data/training.json` (`kick_bag`), `data/moves.json` (estilo `muay_thai`),
`data/skill_tree.json` (região MUAY THAI), `data/minigames.json` (`spar.variants.muay_thai`).
Nomes e textos são provisórios: **[ROT]** marca o que o Roteirista troca.

## 0. A ideia em uma frase
| | Boxe — Mão rápida | Jiu-jitsu — Finalização | **Muay Thai — Canela [ROT]** |
|---|---|---|---|
| Jeito de ganhar | na frente e cedo (embalo → K.O.) | aguentar e fechar (pegada → finalização) | **desgastar e decidir**: cada chute baixo marca a perna dele (0–3). Cada marca deixa ele **mais lento** e sobe o **seu crítico**. Perna cheia: todo crítico vira **chute rodado**, que pode derrubar |
| O que muda | o seu ritmo | o tempo | **o adversário** (manca, ataca mais devagar) |
| Atributo | AGILIDADE | RESISTÊNCIA e FORÇA | **FORÇA** marca a perna, **AGILIDADE** faz o crítico |
| Tática da arte | Agressivo | Defensivo | **Contra-ataque** (resposta = chute baixo que marca de graça) ou **Agressivo** (marca 50% mais rápido, apanha no erro) |
| Regra de treino | clique constante (+50% no clique) | equipe com o tempo | **clique com picos**: crítico do clique 20% e ×4,1 |
| Aparelho | pera | boneco | **saco comprido de chute** (50% FOR, 35% AGI) |

## 1. Regras gerais do motor (`scripts/luta.gd`)
1. **Sem arte, Boxe e Jiu-jitsu: nada muda.** O Muay Thai é um ramo novo dentro de `_rodar_arte()` (passiva `type == "shin"`).
   Medido: `fase7b1_sim.py ident` dá **3.000 de 3.000 lutas idênticas** ao motor da 7a1 em cada caso (sem arte, Boxe, JJ).
2. Mesmos **4 sorteios por ataque**, na mesma ordem (`r_esq, r_crit, r_var, r_arte`). `r_arte` só é usado no chute rodado.
3. Prévia, risco do HUD, robô, motivo da derrota e a luta usam a mesma função: a prévia continua honesta por construção (§6).
4. Todos os números vêm de `data/arts.json → arts[muay_thai].passive`. Nada é constante no código.

### 1.1 Fatores (efetivos, como na 7a1: `clamp(2·meu/(meu+dele), min, max)`)
| Fator | Conta | min–max | Para quê |
|---|---|---|---|
| `fm` (força contra a resistência dele) | `2·For_j / (For_j + Res_a)` | 0,5–2,0 | velocidade das marcas |
| `fa` (agilidade contra a agilidade dele) | `2·Agi_j / (Agi_j + Agi_a)` | 0,5–1,6 | crítico por marca |
`extra` = soma dos nós `art_fight_bonus` ativos do Muay Thai (nó `mt_shin`, §5).

### 1.2 Estado fixo da luta (`estado_passiva`, determinístico)
```
tp = P.tactics[tática] (ou {})
ganho      = min(mark_cap, mark_per_kick × fm × tp.mark_mult(1) × (1 + extra))      # marca por chute baixo
chutes     = ceil(marks_max / ganho)                                                 # chutes para encher
crit_now   = crítico normal do jogador contra ele (o de hoje, só depende da AGILIDADE)
cpm        = crit_per_mark × fa                                                       # crítico a mais por marca
crit_full  = max(crit_now, min(crit_cap, crit_now + marks_max × cpm))
spin_ko    = min(1, P.spin_ko × tp.spin_mult(1))
spin_chance= crit_full × spin_ko                                                      # "rodado por golpe" da prévia
slow_full  = slow_per_mark × tp.slow_mult(1) × marks_max                              # ele mais lento, perna cheia
```

### 1.3 Laço (igual ao `_lutar_shin` do simulador, linha a linha)
```
tj = tática do jogador com damage_mult × P.damage_mult (0,88) e taken_mult × P.taken_mult (1,0)
ta = NEUTRA; ta.counter_mult = tp.opponent_counter (0 se não houver)       # Agressivo: ele contragolpeia quando esquiva
iv_j = attack_interval × P.interval_mult (1,0)
perna = 0.0 (contínua, 0..marks_max); marcas = floor(perna) (inteiro, o que a tela mostra)
laço (mesma escolha de evento de hoje):
  marcas = min(marks_max, floor(perna + 1e-9))                    # lidas ANTES do ataque
  ataque normal do jogador:   prox[0] += iv_j
  ataque normal do adversário: prox[1] += attack_interval × (1 + slow_per_mark × tp.slow_mult × marcas)   # mancando
  sorteia r_esq, r_crit, r_var, r_arte
  esquiva (só ataque normal): agenda contragolpe se tac[alvo].counter_mult > 0; continue
  se quem = jogador: crit = max(crit, min(crit_cap, crit + marcas × cpm))
  dano como hoje (crítico ×2, crit_guard, contragolpe, variação); aplica
  golpe (só jogador) = "spin" se crítico e marcas = marks_max; "crit" se crítico; senão "kick"
  vida do alvo zerou → fim "damage" (como hoje)
  senão, se quem = jogador:
    "spin": spins += 1; se vida_dele ≤ spin_life_max (60%) × vmax_dele:   (need_ahead = 0: não precisa estar na frente)
              attempts += 1; se r_arte < spin_ko → fim "spin_kick" (vence o jogador)
    "kick": perna = min(marks_max, perna + (max(ganho, tp.marks_per_counter) se contragolpe, senão ganho))
            se perna chegou a marks_max pela 1ª vez: marks_full_at = t
fim pela passiva: ko = true, t_ko = t, t_end = max(t, min_ko_time); fim no tempo: pontos, como hoje
```
Pontos que o Programador não pode errar:
- **Só o acerto normal (não crítico) marca a perna.** O crítico antes da perna cheia é joelhada/clinch (visual) e não marca.
- Com a perna cheia, **todo crítico é chute rodado na tela**, derrube ou não (o portão de 60% só decide se pode derrubar).
- A lentidão usa as marcas **inteiras** do momento em que ele ataca (não a perna contínua).
- O crítico do jogador sobe pelas marcas **inteiras**; o do adversário não muda.

## 2. A passiva "Canela" em números
### 2.1 Fórmulas e valores
| Regra | Fórmula | Valor |
|---|---|---|
| Dano por golpe | tática × `damage_mult` | **×0,88** (o mesmo do Boxe; começou em 0,90, §8.3) |
| Ritmo do jogador | `attack_interval × interval_mult` | 1,8 s (igual a hoje) |
| Marcas na perna | `marks_max` | **3** |
| Marca por chute baixo | `min(1, 1,0 × fm × tática × (1+extra))` | fm 1,0: **1 marca por chute** (3 chutes); fm 0,5: 0,5 (6 chutes) |
| Ele mais lento | `+slow_per_mark × marcas` no intervalo dele | **+8% por marca**: perna cheia = 1,8 → **2,23 s** (+24%) |
| Seu crítico | `+crit_per_mark × fa × marcas`, teto `crit_cap` | **+6% × fa por marca**: perna cheia = +18% (fa 1,0), +9% a +29%; teto **60%** |
| Chute rodado | todo crítico com a perna cheia | — |
| Derrubar com o chute rodado | vida dele ≤ `spin_life_max` e `r_arte < spin_ko` | ≤ **60%** da vida e **65%** por chute rodado |
| Manca na tela | marcas ≥ `limp_from_marks` | a partir de **2** marcas (só visual) |

### 2.2 Táticas
| Tática | Na passiva | Na luta |
|---|---|---|
| **Agressivo** | marca ×1,5 (`mark_mult`); **ele contragolpeia** com 60% quando esquiva um ataque seu (`opponent_counter` 0,6) | enche cedo (1º round contra quem tem pouca RESISTÊNCIA), mas cada erro vira soco dele. Bom contra o lento, arriscado contra o ágil |
| **Defensivo** | marca ×0,75; lentidão ×1,5 (**+12% por marca**, perna cheia +36%) | enche tarde (3º round), mas ele quase não ataca no fim. Luta longa, ganha por pontos ou rodado no gongo |
| **Contra-ataque** | o seu contragolpe é **chute baixo e vale no mínimo 1 marca inteira** (`marks_per_counter` 1) | esquiva e responde na coxa: enche no 2º round mesmo com pouca FORÇA. A tática que mais vence pelo chute rodado |

### 2.3 Exemplos (prévia; 200 lutas por linha; `fase7b1_sim.py previa`)
"Cheia em" = mediana das lutas em que a perna encheu (e em quantas encheu). "Rodado/golpe" = `spin_chance`.
| Luta (você × total dele, F/A/R) | Tática | Chance | Chutes | Cheia em (round) | Crítico agora → cheio | Rodado/golpe | N em 10 vitórias pelo rodado |
|---|---|---|---|---|---|---|---|
| Tonhão 0,9× 2/1/1 | Agressivo | 93% | 3 | 6,3 s (89%) · 2º | 20% → 44% | 28% | 4 |
| | Defensivo | 75% | 6 | 13,5 s (73%) · 3º | 20% → 44% | 28% | 4 |
| | Contra-ataque | 95% | 4 | 6,3 s (98%) · 2º | 20% → 44% | 28% | 8 |
| Tonhão 0,9× 1/1/1 | Agressivo | 93% | 4 | 8,1 s (84%) · 2º | 25% → 50% | 32% | 5 |
| | Defensivo | 52% | 7 | 15,3 s (34%) · 3º | 25% → 50% | 32% | 1 |
| | Contra-ataque | 93% | 5 | 8,1 s (98%) · 2º | 25% → 50% | 32% | 8 |
| Kid 0,9× 1/1/1 | Agressivo | 98% | 3 | 4,5 s (100%) · 1º | 8% → 28% | 18% | 5 |
| | Defensivo | 86% | 6 | 11,7 s (92%) · 3º | 8% → 28% | 18% | 3 |
| | Contra-ataque | 82% | 5 | 8,1 s (98%) · 2º | 8% → 28% | 18% | 6 |
| Kid 0,9× 2/2/1 | Agressivo | 87% | 3 | 6,3 s (95%) · 2º | 12% → 32% | 21% | 5 |
| | Contra-ataque | 84% | 4 | 6,3 s (100%) · 2º | 12% → 32% | 21% | 8 |
| Kid 0,9× 1/1/2 | Agressivo | 84% | 4 | 7,2 s (100%) · 2º | 5% → 22% | 14% | 5 |
| | Defensivo | 35% | 7 | 12,6 s (64%) · 3º | 5% → 22% | 14% | 0 |
| Muralha 0,8× 1/1/1 | Agressivo | 86% | 4 | 8,1 s (96%) · 2º | 19% → 42% | 28% | 7 |
| | Defensivo | 20% | 8 | 15,3 s (21%) · 3º | 19% → 42% | 28% | 0 |
| | Contra-ataque | 82% | 6 | 8,1 s (96%) · 2º | 19% → 42% | 28% | 7 |
Tela de todas as linhas: 8,0–19,0 s.

Leitura: o Muay Thai **desgasta no 1º round e decide no 2º**. O Contra-ataque leva 7–8 de cada 10 vitórias para o chute rodado;
o Agressivo enche mais cedo e ganha mais por dano. O Defensivo é a tática "segura" e lenta: perde chance contra quem aguenta muito
(Muralha), e a prévia mostra isso (linha "a perna não enche").

## 3. Foco de treino certo: FORÇA com AGILIDADE
### 3.1 No amarelo (onde a campanha se decide), chance com a melhor tática, total = 0,9 × o dele (`fase7b1_sim.py foco`)
| Adversário | Divisão F/A/R | Sem arte | Boxe | Jiu-jitsu | **Muay Thai** |
|---|---|---|---|---|---|
| Tonhão | 1/1/1 | 94% | 98% | 96% | 93% |
| | 2/1/1 (FORÇA) | 87% | 98% | 94% | **95%** |
| | 1/2/1 (AGILIDADE) | 86% | 88% | 92% | 88% |
| | 1/1/2 (RESISTÊNCIA) | 95% | 100% | 94% | 96% |
| | **2/2/1 (FOR + AGI)** | 90% | 96% | 96% | **96%** |
| Kid | 1/1/1 | 98% | 98% | 97% | 98% |
| | 2/1/1 (FORÇA) | 83% | **78%** | 88% | **84%** |
| | 1/2/1 (AGILIDADE) | 55% | 82% | 78% | **80%** |
| | 1/1/2 (RESISTÊNCIA) | 85% | 78% | **96%** | 84% |
| | **2/2/1 (FOR + AGI)** | 66% | 88% | 78% | **87%** |

- **Muay Thai:** é a única arte que **não perde nada com FORÇA nem com AGILIDADE** contra o Kid (84% e 80%; sem arte 83% e 55%).
  FORÇA marca a perna; AGILIDADE transforma as marcas em crítico. O lutador "FOR + AGI" (2/2/1) é o certo: +21 pontos sobre
  sem arte contra o Kid. RESISTÊNCIA extra não ajuda (84%, igual a sem arte).
- Diferença do **Boxe**: o boxeador que só treina FORÇA cai para 78% contra o Kid; o de Muay Thai fica em 84%.
- Diferença do **Jiu-jitsu**: o JJ quer RESISTÊNCIA (96%); no Muay Thai ela não paga.
- No verde (limiar, §8.1) as três artes ficam iguais: o verde é decidido pelo dano e pela vida.
- Dica para o Roteirista (cartão, mentor): "FORÇA MARCA A PERNA, AGILIDADE FAZ O CRÍTICO".

### 3.2 Aparelho: o saco comprido de chute (`training.json → kick_bag`)
| Campo | Valor | Por quê |
|---|---|---|
| `split` | **FOR 0,50 · AGI 0,35 · RES 0,15** | o "certo" é FOR + AGI puxando FORÇA. Fica longe da pera (40/45/15, AGILIDADE) e do boneco (25/15/60) |
| `unlock` | `unlock_kick_bag`, **2.500**, requer a esteira, chega **em caixa** | o mesmo padrão dos outros aparelhos de arte |
| `upgrades` | `tech_mt_1..4`: 1.500 ×3 · 15.000 ×5 · 600.000 ×3 · 6.000.000 ×3 | os mesmos preços e multiplicadores da pera e do boneco (nenhuma arte compra mais barato) |
| `crit_texts` | provisórios: CANELA! / ESSE ESTALOU! / O SACO DOBROU! / TEP! / MARCOU! **[ROT]** | o Muay Thai vê 2× mais crítico: precisa de pelo menos 5 textos |
| Onde | garagem e academia, como a pera e o boneco (só com a arte Muay Thai) | Diretor de Arte |

## 4. Regra de treino: clique com picos
### 4.1 A regra (`arts[muay_thai].rule`)
`{"type": "click_crit_bonus", "chance_add": 0.10, "mult_add": 1.1}`. Vale só no **clique manual** (o mesmo que recebe o bônus do Boxe:
`clicar()`; o Metrônomo e o assistido usam o crítico de hoje).
| | Sem arte / outras artes | **Muay Thai** | com ESTILO 0,5 | com ESTILO 0,75 (todos os nós) |
|---|---|---|---|---|
| Chance de crítico do clique manual | 10% | **20%** (`crit_chance + chance_add`) | 20% | 20% |
| Multiplicador do crítico | ×3 | **×4,1** (`crit_multiplier + mult_add × (1 + estilo)`) | ×4,65 | ×4,93 |
| Treino médio do clique (÷ sem arte) | 1,00 | **×1,35** | ×1,44 | ×1,49 |
| Boxe, para comparar (`+value × (1+estilo)`) | — | ×1,50 | ×1,75 | ×1,88 |

Contas para o código (`_socar(auto)`, sem mudar a ordem do `rng`: continua **um** `randf()` para o crítico e, se crítico, um `randi()`
para o texto):
```
chance = crit_chance + (rule.chance_add se Muay Thai e não auto, senão 0)
mult   = crit_multiplier + (rule.mult_add × (1 + estilo_arte) se Muay Thai e não auto, senão 0)
critico = rng.randf() < chance;  ganho = por_clique() × (mult se critico senão 1) × frenesi
```
`bonus_arte_clique()` continua 0 no Muay Thai (é só do Boxe). Função nova `bonus_arte_critico() -> {chance, mult}` para a tela.

### 4.2 Por que não vira "Boxe melhor"
- **Na média o Muay Thai treina menos pelo clique que o Boxe** (×1,35 contra ×1,50; com todos os nós ×1,49 contra ×1,88). O que ele
  ganha é a **sensação**: 1 em cada 5 cliques estoura, com número grande e texto do saco.
- Quem clica muito continua mais bem servido pelo Boxe: a 4/s o Muay Thai chega ao Kid **depois** do Boxe (§8.2), nunca antes.
- O que segura o Muay Thai no balanço é a luta (a passiva), não o treino.

## 5. Árvore: região MUAY THAI (`skill_tree.json`, gravado)
No espelho do Boxe e do JJ: raiz de luta (200), ESTILO (1.200) e 2 nós pequenos. Trava `art:muay_thai` (só aparece com a arte
liberada). **Nenhum nó existente muda.** Posição provisória no canto de baixo à direita (entre CAMPANHA e JIU-JITSU; o UI/UX confere).
| id | Região | Tipo | Pos | Vizinhos | Custo | Efeito | Texto (provisório **[ROT]**) |
|---|---|---|---|---|---|---|---|
| `style_muay_thai` | style | milestone, raiz | [4, 4] | mt_shin | **1.200** | `art_rule_bonus` 0,5 → mult do crítico ×4,1 → **×4,65** | Canela de ferro — "MUAY THAI: CRÍTICO DO CLIQUE CRESCE {pct}%" |
| `mt_shin` | muay_thai | milestone, raiz | [6, 5] | style_muay_thai, mt_oil, mt_rope | **200** | `art_fight_bonus` 0,5 → **marca ×1,5** (`extra`) | Chute na coxa — "MUAY THAI: MARCA A PERNA {pct}% MAIS RÁPIDO" |
| `mt_oil` | muay_thai | small | [8, 4] | mt_shin | 400 | `art_rule_bonus` 0,25 | Óleo de massagem — "MUAY THAI: CRÍTICO DO CLIQUE CRESCE {pct}%" |
| `mt_rope` | muay_thai | small | [6, 7] | mt_shin | 300 | `click_bonus` 0,25 | Corda na ponta do pé — "+{pct}% TREINO POR CLIQUE" |
Espelho exato: `box_counter`/`bjj_guard` (200, 0,5), `style_*` (1.200, 0,5), `box_wraps`/`bjj_knot` (400, 0,25), `box_footwork` (300, `click_bonus` 0,25).
Com `mt_shin`: fm 1,0 no Defensivo enche com 3 chutes em vez de 4; fm 0,5 com 4 em vez de 6. Ícones novos: `region_muay_thai`,
`skill_style_muay_thai`, `skill_shin_kick` (Diretor de Arte).

## 6. Prévia honesta
### 6.1 A conta
- `estado_passiva(jog, adv, tática)` para o Muay Thai (§1.2) devolve:
  `{kind: "shin", marks_max, mark_gain, kicks_to_full, str_factor, agi_factor, crit_now, crit_per_mark, crit_full, spin_ko,
  spin_chance, slow_full, opp_counter, marks_per_counter}`.
- `chance_detalhada()` (as mesmas 200 sementes) passa a contar também, **só no Muay Thai**: `full_share` (em quantas das 200 lutas
  a perna encheu) e `full_at` (mediana de `marks_full_at` dessas lutas; −1 se nenhuma). `wins_passive` conta `finish == "spin_kick"`.
  `chance()` não muda.
- Round da perna cheia: `full_round = floor(full_at / round_length) + 1` (1–3).

### 6.2 O que a prévia mostra (1 linha; campos novos em `previa()`, no padrão da 7a1)
| Campo | Muay Thai |
|---|---|
| `passive_name` | CANELA **[ROT]** |
| `passive_line` | `PERNA CHEIA NO {r}º ROUND ({k} CHUTES) · CHUTE RODADO {p}% POR GOLPE · ELE {s}% MAIS LENTO` (Agressivo acrescenta `ELE CONTRAGOLPEIA`; Contra-ataque acrescenta `SEU CONTRAGOLPE MARCA`). Se `full_share < 0,5`: `passive_line_late` = `A PERNA SÓ ENCHE EM {x} DE 10 LUTAS` |
| `passive_state` (desenho) | `{marks_max, kicks_to_full, full_at, full_round, full_share, crit_now, crit_full, spin_chance, slow_full, opp_counter}` → 3 marcas apagadas e o round onde enchem |
| `passive_share` | `{n} EM 10 VITÓRIAS POR CHUTE RODADO` (`round(10 × wins_passive / wins)`) |
| `passive_tactics` | o mesmo bloco por tática (a linha muda ao trocar de tática sem recalcular) |
`r` = `full_round`; `k` = `kicks_to_full`; `p` = `round(100 × spin_chance)`; `s` = `round(100 × slow_full)`; `x` = `round(10 × full_share)`.

### 6.3 Medida (critério 2): 1.000 lutas por adversário (`fase7b1_sim.py honesta`)
Estado = atributos reais do robô de Muay Thai × 0,6..1,4, tática sorteada, semente real aleatória.
| Adversário | Chance mostrada | Vitória real | Diferença | Vitórias: dano / chute rodado / pontos | Derrotas: dano dele / pontos | Tela |
|---|---|---|---|---|---|---|
| Dudu | 83,5% | 84,1% | +0,6 | 841 / 0 / 0 | 159 / 0 | 8,0–12,0 s |
| Brutão | 83,7% | 82,9% | −0,8 | 829 / 0 / 0 | 171 / 0 | 8,0–9,3 s |
| Dinho | 74,9% | 74,2% | −0,7 | 742 / 0 / 0 | 254 / 4 | 8,0–19,0 s |
| Muralha | 77,1% | 78,3% | +1,2 | 460 / 218 / 105 | 122 / 95 | 8,0–19,0 s |
| Tonhão | 75,8% | 74,6% | −1,2 | 377 / 252 / 117 | 109 / 145 | 8,0–19,0 s |
| Kid | 69,3% | 68,4% | −0,9 | 311 / 215 / 158 | 138 / 178 | 8,0–19,0 s |
**Critério 2 fecha: pior diferença 1,2 ponto** (meta ±5). Contra os amadores (Dudu, Brutão, Dinho) a luta acaba por dano antes da
perna encher e de ele cair abaixo de 60%; o chute rodado aparece da Muralha em diante, como o K.O. do Boxe e a finalização do JJ.
**Critério 4: tela 8,0–19,0 s**, com o chute rodado (respeita `min_ko_time` 5 s).

## 7. Choque do Muay Thai: combo no tempo (`minigames.json → spar.variants.muay_thai`, gravado)
Mesma tela, barra, Osmar, níveis, padrões (rajada, pausa ×2, finta), pontos, prêmio e AQUECIDO da 7a2. Muda só o controle.
### 7.1 A regra
| Ação | Efeito |
|---|---|
| **Batida** | a cada `beat_s` = **0,5 s** (120 por minuto) desde o fim da contagem, marcada na tela (pulso/bumbo). Batida *k* no instante `k × 0,5` (k ≥ 1) |
| **Clique no tempo** | a até `window_s` = **0,12 s** de uma batida **ainda não usada** → combo +1 e empurra `push_on_beat` × força (**0,10**, como o clique do Boxe) |
| **3º clique no tempo seguido** (`combo_kick` 3) | vira **CHUTE**: empurra `push_kick` × força (**0,45**), gasta mais fôlego (`breath_cost_kick` +0,15) e o combo volta a 0 |
| **Clique fora do tempo** | empurrão fraco `push_off_beat` (**0,03**) e o **combo zera**. 2º clique na mesma batida = fora do tempo |
| Pular uma batida | **não zera** o combo (só o clique errado zera); um ponto marcado (ou sofrido) zera |
| **Segurar** ≥ 0,20 s | guarda, igual ao Boxe (anula a rajada; o aperto que abriu a guarda conta como clique) |
| Fôlego | 0,07 por clique (+0,15 no chute), volta 0,30/s. Força = `0,15 + 0,85 × fôlego`. Pausa: tudo ×2 (`counter_mult`) |
| Congelado (1 s depois de um ponto) | cliques ignorados; as batidas continuam contando |
No ritmo certo (2 cliques/s, chute a cada 1,5 s) o fôlego gasta 0,24/s e volta 0,30/s: **não cansa**, e o empurrão médio é
(0,10 + 0,10 + 0,45) / 1,5 s = **0,43/s**, o mesmo do Boxe a 4,3 cliques/s. O Muay Thai empurra igual, mas **pelo tempo**, não pela
velocidade.

### 7.2 Medido (`fase7b1_sim.py choque`, 400 partidas): pontos / pontos dele / VENCEU / prêmio (% do máximo) / chutes
Perfis: **parado**; **afobado** (9 cliques/s, não lê nada); **sem ritmo** (4/s fora da batida, lê 30%); **distraído** (na batida com erro
de ~0,15 s, lê 30%); **médio** (erro ~0,10 s, lê 60%, 30% das fintas); **bom** (~0,07 s, 90%, 70%); **perfeito** (~0,03 s).
| Muay Thai | nível 0 | nível 2 | nível 3 | nível 5 |
|---|---|---|---|---|
| parado | 0 / 4,3 / 0% / 25% / 0 | 0 / 5,4 / 0% / 25% / 0 | 0 / 5,9 / 0% / 25% / 0 | 0 / 6,9 / 0% / 25% / 0 |
| afobado (9/s) | 0 / 2,9 / 0% / 25% / 0 | 0 / 3,4 / 0% / 25% / 0 | 0 / 3,9 / 0% / 25% / 0 | 0 / 4,8 / 0% / 25% / 0 |
| sem ritmo (4/s) | 2,0 / 0,2 / 32% / 72% / 0 | 1,1 / 0,7 / 8% / 53% / 0 | 0,9 / 1,6 / 4% / 48% / 0 | 0,7 / 2,1 / 2% / 43% / 0 |
| distraído | 1,2 / 0,8 / 11% / 56% / 4,9 | 0,8 / 1,7 / 4% / 46% / 4,7 | 0,7 / 2,1 / 2% / 42% / 4,5 | 0,5 / 2,7 / 0% / 38% / 4,3 |
| médio | 2,7 / 0,1 / 56% / 85% / 8,6 | 2,0 / 0,5 / 30% / 72% / 8,4 | 1,8 / 0,8 / 24% / 68% / 8,2 | 1,5 / 1,3 / 16% / 61% / 8,0 |
| bom | 4,1 / 0,0 / 96% / 99% / 10,8 | 3,2 / 0,0 / 77% / 93% / 10,9 | 3,0 / 0,1 / 68% / 90% / 10,9 | 2,7 / 0,2 / 58% / 86% / 10,7 |
| perfeito | 4,8 / 0,0 / 100% / 100% / 12,0 | 4,0 / 0,0 / 97% / 99% / 12,2 | 3,9 / 0,0 / 91% / 98% / 12,3 | 3,7 / 0,0 / 88% / 97% / 12,3 |
(O simulador ignora os cliques durante o congelamento de 1 s depois de um ponto, como o jogo.)

- **Clicar no tempo rende muito mais que clicar afobado** (critério 7): o afobado não marca ponto em nível nenhum; o "sem ritmo" a
  4/s fica atrás de quem acompanha a batida a partir do médio.
- Comparado com o Boxe (7a2 §3.5): no Muay Thai **errar o tempo pesa mais** (o distraído vai pior) e **acertar paga mais** (o perfeito
  vai melhor no Kid). É a cara da arte: ritmo e precisão.

### 7.3 Teto de 10% em dias de campanha (critério 7; `fase7b1_sim.py teto`, 48 jogadores, igual à 7a2 §8)
| Perfil | Política | Muralha: real / sala | Tonhão: real / sala | Kid: real / sala | Ganho em dias: Muralha / Tonhão / Kid | Tempo real no Kid |
|---|---|---|---|---|---|---|
| Muay Thai 4/s | nenhum | 22:21 / 22:21 | 32:22 / 32:22 | 51:00 / 51:00 | — | — |
| Muay Thai 4/s | todos_max | 23:43 / 21:11 | 34:45 / 30:19 | 56:01 / 49:03 | 5,3% / 6,3% / **3,8%** | −9,8% |
| Muay Thai 4/s | todos_piso | 24:02 / 21:30 | 35:43 / 31:17 | 57:11 / 50:13 | 3,8% / 3,3% / 1,5% | −12,1% |
| Muay Thai 3/s | nenhum | 26:20 / 26:20 | 37:58 / 37:58 | 61:32 / 61:32 | — | — |
| Muay Thai 3/s | todos_max | 27:26 / 24:16 | 40:25 / 35:21 | 67:31 / 58:39 | **7,9%** / 6,9% / **4,7%** | −9,7% |
| Muay Thai 3/s | todos_piso | 28:10 / 25:00 | 41:25 / 36:21 | 68:57 / 60:05 | 5,1% / 4,2% / 2,3% | −12,1% |
| Muay Thai 4/s | cedo_max | 23:32 / 21:00 | 33:28 / 29:40 | 54:59 / 48:01 | 6,0% / 8,3% / 5,8% | −7,8% |
| Muay Thai 3/s | cedo_max | 26:38 / 23:28 | 38:25 / 33:59 | 65:21 / 57:07 | 10,9% / 10,5% / 7,2% | −6,2% |
- **Teto cumprido:** indo em todos com nota máxima, **pior trecho 7,9%** (Muay Thai 3/s até o cinturão; o pior da 7a2 continua o Boxe 3/s, 9,2%). Nenhum
  número travado do `minigames.json` mudou: o prêmio é o mesmo, e o Muay Thai treina um pouco menos que o Boxe.
- `cedo_max` (guarda o AQUECIDO e luta no amarelo, nesta medida em que **perder não custa nada**) passa de 10% (10,9%), como já
  acontecia com o JJ na 7a2 §8.5 (11,1–16,8%). Lá ficou medido que o ganho vem de lutar no amarelo sem custo, não do minigame, e que
  na campanha de verdade lutar cedo **atrasa**. Vale o mesmo aqui; não mexo em número travado.

## 8. Balanço das 3 artes
### 8.1 Força na luta (limiar: total, em × total dele, para o amarelo 40% / verde 90%, melhor tática, média de 4 divisões)
| | Sem arte | Boxe | Jiu-jitsu | **Muay Thai** |
|---|---|---|---|---|
| **Média (5 adversários)** | 0,702 / 0,848 | 0,686 / 0,820 | 0,641 / 0,822 | **0,652 / 0,836** |
| Brutão | 0,668 / 0,940 | 0,636 / 0,872 | 0,669 / 0,875 | 0,686 / 0,943 |
| Dinho | 0,519 / 0,636 | 0,541 / 0,657 | 0,476 / 0,619 | 0,509 / 0,630 |
| Muralha | 0,738 / 0,848 | 0,709 / 0,811 | 0,664 / 0,834 | 0,653 / 0,831 |
| Tonhão | 0,748 / 0,891 | 0,724 / 0,846 | 0,668 / 0,870 | 0,644 / 0,865 |
| Kid | 0,838 / 0,926 | 0,818 / 0,914 | 0,726 / 0,913 | 0,770 / 0,910 |
O Muay Thai fica entre o Boxe e o JJ: forte no amarelo contra quem aguenta (Muralha, Tonhão: é quem fica abaixo de 60% sem cair) e
**sem vantagem** contra o Brutão (luta curta, decidida por dano, a perna não chega a contar). No verde, empata com os outros.

### 8.2 Tempo até o Kid (critério 5, meta ≤ 15% entre quaisquer duas artes, a 3 e a 4 cliques/s)
**a) Força de treino** (`fase7b1_sim.py forca`: sem calendário, só luta no verde, derrota não encerra; 48 jogadores; árvore vazia):
| Perfil | Muralha | Tonhão | Kid | Kid: diferença para o Boxe |
|---|---|---|---|---|
| Boxe 4/s | 21:18 | 30:18 | 47:53 | — |
| Jiu-jitsu 4/s | 20:18 | 27:19 | 58:00 | +21,1% |
| **Muay Thai 4/s** | 22:21 | 32:22 | **51:00** | +6,5% |
| Boxe 3/s | 25:18 | 35:58 | 58:24 | — |
| Jiu-jitsu 3/s | 21:23 | 30:20 | 68:02 | +16,5% |
| **Muay Thai 3/s** | 26:20 | 37:58 | **61:32** | +5,4% |
Nesta medida (sem calendário, sem derrota) o JJ já ficava 14–21% atrás do Boxe desde a 7a1; para o balanço vale a campanha (b),
onde o calendário e a pegada pesam. O Muay Thai fica **entre os dois**.

**b) Campanha de verdade** (`fase7b1_sim.py campanha`: robô padrão da 7a1, calendário, Legado, hall; 200 jogadores × 10 campanhas).
O Muay Thai entra "como se" estivesse liberado na 1ª chegada à academia (a mesma comparação da 7a1); no jogo ele só chega
depois do 1º Kid, então isto mede a arte, não a liberação. Boxe e JJ são os mesmos números da 7a1 (motor idêntico).
| Perfil | Campanhas até o Kid (méd; p90; média) | Kid na 1ª tentativa | Tempo até o 1º Kid: mediana / média / p90 | Vitórias com arte: dano / passiva / pontos | Tonhão: pela passiva | Tela (med; mín–máx) |
|---|---|---|---|---|---|---|
| Boxe 4/s | 1; 2; 1,14 | 92,5% | 41:04 / 44:57 / 57:41 | 7.321 / 2.620 / 293 | 52% | 8,0 (8,0–19,0) |
| Jiu-jitsu 4/s | 1; 3; 1,25 | 91,0% | 41:47 / 47:33 / 76:25 | 7.173 / 2.613 / 434 | 50% | 8,4 (8,0–19,0) |
| **Muay Thai 4/s** | 1; 1; 1,10 | 93,0% | 41:22 / 45:04 / 56:45 | 7.705 / 1.812 / 558 | **47%** | 8,4 (8,0–19,0) |
| Boxe 3/s | 1; 3; 1,43 | 78,5% | 46:18 / 56:19 / 85:53 | 7.173 / 2.504 / 309 | 58% | 8,3 (8,0–19,0) |
| Jiu-jitsu 3/s | 1; 3; 1,56 | 80,0% | 46:33 / 58:15 / 92:28 | 6.876 / 2.808 / 514 | 60% | 9,3 (8,0–19,0) |
| **Muay Thai 3/s** | 1; 3; 1,44 | 75,5% | 46:23 / 57:19 / 92:10 | 7.735 / 1.585 / 607 | **45%** | 8,6 (8,0–19,0) |
Cinturão: mediana 2 campanhas em todos; 1ª carreira 13:56 (4/s) e 15:26 (3/s), iguais. **Tonhão vencido pelo chute rodado em
45–47% das vitórias** (critério 1 pede pelo menos 1 em 3).

### 8.3 Boxe × Jiu-jitsu × Muay Thai (decisão do dono: "as três mais ou menos na mesma %")
| | Boxe | Jiu-jitsu | **Muay Thai** | MT × Boxe | MT × JJ |
|---|---|---|---|---|---|
| Tempo até o Kid, 4/s, **mediana** | 41:04 | 41:47 | **41:22** | +0,7% | −1,0% |
| Tempo até o Kid, 4/s, **média** | 44:57 | 47:33 | **45:04** | +0,3% | −5,2% |
| Tempo até o Kid, 3/s, **mediana** | 46:18 | 46:33 | **46:23** | +0,2% | −0,4% |
| Tempo até o Kid, 3/s, **média** | 56:19 | 58:15 | **57:19** | +1,8% | −1,6% |
| Kid na 1ª tentativa, 4/s / 3/s | 92,5% / 78,5% | 91,0% / 80,0% | **93,0% / 75,5%** | +0,5 / −3,0 pts | +2,0 / −4,5 pts |
| Total para o **verde** contra o Kid (× o dele, §8.1) | 0,914 | 0,913 | **0,910** | igual | igual |
| Chance contra o Kid no foco certo (total 0,9×, §3.1) | 88% (2/2/1) · 82% (1/2/1) | 96% (1/1/2) · 88% (2/1/1) | **87% (2/2/1)** | −1 pt | −9 pts |
- **Mediana: as três a no máximo 1,0% uma da outra**, a 3 e a 4/s. O Muay Thai fica no meio, entre o Boxe e o JJ.
- **Média:** a 3/s o Muay Thai fica exatamente no meio (+1,8% do Boxe, −1,6% do JJ). A 4/s ele empata com o Boxe (+0,3%) e fica
  5,2% à frente do JJ. Isso não dá para fechar só com o Muay Thai: **o próprio JJ 4/s já é 5,8% mais lento que o Boxe na média**
  (a cauda dele: p90 76:25 × 57:41). Com o Muay Thai no meio exato, ele ficaria ~2,9% de cada um; mais lento que isso ele passaria
  a ficar longe do Boxe. Para fechar os ~2% entre as três, seria preciso mexer no JJ (fora do pedido).
- **Chance contra o Kid:** para chegar ao verde contra o Kid as três pedem o mesmo total (0,91×). No amarelo, Muay Thai e Boxe
  ficam iguais no foco certo (87% e 88%); o JJ com muita RESISTÊNCIA chega a 96% (é o jeito dele: vira a luta difícil, desde a 7a1).
- **Ruído:** com 200 jogadores, a média do tempo até o Kid oscila ~2% entre rodadas (testes abaixo); diferenças menores que isso
  são empate.

Como cheguei (só o Muay Thai muda; Boxe e JJ fixos):
| Versão | Dano | `spin_ko` | `mult_add` | 4/s med / média | 3/s med / média | Kid 1ª 4/s / 3/s | Tonhão pelo rodado |
|---|---|---|---|---|---|---|---|
| 1ª | ×0,90 | 0,65 | 1,3 | 41:21 / 44:12 | 46:23 / 55:23 | 95,0 / 79,5 | 44–48% |
| 2ª | ×0,88 | 0,65 | 1,3 | 41:22 / 44:19 | 46:23 / 55:43 | 94,5 / 77,5 | 46–48% |
| teste | ×0,88 | 0,55 | 1,3 | 41:22 / 44:27 | 46:23 / 56:04 | 94,0 / 77,5 | 40–43% |
| teste | ×0,88 | 0,45 | 1,3 | 41:22 / 44:31 | 46:23 / 56:13 | 94,0 / 77,0 | 35–37% |
| **final** | **×0,88** | **0,65** | **1,1** | **41:22 / 45:04** | **46:23 / 57:19** | **93,0 / 75,5** | **45–47%** |
| teste | ×0,88 | 0,65 | 0,9 | 41:37 / 44:56 | 46:51 / 58:48 | 93,5 / 72,5 | 45–47% |
O `spin_ko` quase não mexe no tempo (o robô espera o verde) e derruba o chute rodado para perto de 1 em 3 vitórias: **ficou 0,65**.
O que mexe é o treino: o crítico do clique passou de ×4,3 para **×4,1** (na média ×1,35 em vez de ×1,38). Com ×3,9 o 3/s passa do JJ.

### 8.4 Metas da visão
| Meta | 7a2 | 7b1 |
|---|---|---|
| 1ª carreira 10–15 min | 13:56 (4/s) · 15:26 (3/s) | **igual**: a 1ª carreira não tem arte, e o Muay Thai só existe depois do Kid |
| Cinturão amador entre a 2ª e a 4ª carreira | mediana 2 | **igual** (Boxe e JJ não mudam; o Muay Thai só chega depois do Kid, que vem depois do cinturão) |
| Tempo morto ≤ 10 min | economia | **sem mudança**: nenhum preço muda; o saco custa o mesmo que a pera |
| Boxe e JJ iguais à 7a2 | — | `ident`: 3.000/3.000 lutas idênticas; a campanha deles muda só se o jogador escolher o Muay Thai |

## 9. Liberação do Muay Thai (decisão 2 do dono)
| Quando | O que acontece |
|---|---|
| 1ª chegada à academia (como hoje) | `arts_unlocked` recebe as artes **sem** campo `unlock` (Boxe e JJ). O Muay Thai fica de fora |
| **1ª vitória contra o Kid** (`arts[muay_thai].unlock = {type: "first_win", opponent: "opp_gym_2"}`), em qualquer carreira | ao concluir a luta vencida, `muay_thai` entra em `permanent.arts_unlocked` (no **mesmo** `salvar()` da luta) e sai o sinal `permanente_mudou`. O Osmar comenta numa fala curta **[ROT]** (chave `muay_thai_unlocked`, uma vez só, marco `muay_thai_unlocked`) na próxima vez que a sala estiver livre. A 3ª carta aparece na **próxima** escolha de arte (a arte da carreira atual não muda) |
| **Save antigo** de quem já venceu o Kid | ao carregar: se `permanent.best_wins ≥ índice do Kid + 1` (= **6**) **ou** a carreira atual tem `indice_escada ≥ 6`, acrescenta `muay_thai` (sem fala repetida se o marco já existir; com o marco ausente, a fala sai uma vez) |
| Quem nunca venceu o Kid | 2 cartões, como hoje. Nenhuma dica de "3ª arte escondida" |
Regra geral (para a 8a reaproveitar): arte com `unlock.type == "first_win"` é liberada pela 1ª vitória contra `unlock.opponent`;
o índice vem da escada (não fixar 6 no código).

## 10. A luta na tela (dados para a UI e a arte; tudo só visual)
### 10.1 Campos novos (resultado e eventos, só com Muay Thai)
| Onde | Campo | Valor |
|---|---|---|
| resultado | `finish` | ganha `"spin_kick"` |
| resultado | `marks_peak` (0–3), `marks_full_at` (−1 se não encheu), `attempts` (rodados com ele ≤ 60%), `spins` (rodados mostrados), `opp_counter_damage` | tela e motivo |
| evento | `marks` | marcas inteiras **depois** do evento (0–3) |
| evento | `move` | `"kick"` · `"crit"` · `"spin"` (só jogador) → golpe do `moves.json` (§10.3) |
| evento | `finish` | `""` · `"spin_kick"` no último |
| `luta_atual()` | `passive` | ganha `"shin"` |

### 10.2 O que o jogador vê
| | Muay Thai |
|---|---|
| HUD | **3 marcas** (ícones de canela/perna) ao lado da vida **dele**, acendem a cada chute baixo que marca. Cheias: piscam "PERNA CHEIA!" **[ROT]** |
| Adversário | a partir de 2 marcas usa o idle **mancando** (`limp`); com 3, mais torto se houver quadro |
| Crítico | antes da perna cheia: joelhada ou clinch (sorteio visual do `moves.json`). Com a perna cheia: **chute rodado** sempre |
| Final | letreiro novo **"CHUTE RODADO!"** **[ROT]** e a queda `fall_spin` (sem ela, a queda do K.O.) |
| Ritmo | igual a hoje (1,8 s); ele vai ficando mais lento (até 2,23 s; Defensivo 2,45 s) |

### 10.3 Golpes (`moves.json`, estilo `muay_thai`, gravado; não pode sobrar golpe de boxe)
| id | anim | kinds | Reação dele | Quando |
|---|---|---|---|---|
| `low_kick` | `low_kick` | jab, counter | `hit_leg` | acerto normal e contragolpe (é o que marca) |
| `knee` | `knee` | crit | `hit_body` | crítico antes da perna cheia |
| `thai_clinch` | `thai_clinch` | crit | `held_clinch` | crítico antes da perna cheia |
| `spin_kick` | `spin_kick` | **spin_kick** (kind novo) | `fall_spin` | todo crítico com a perna cheia (derrube ou não) |
`MovesData.KINDS` += `spin_kick`. Fallback de sempre: sprite que não existe → golpe antigo e reação `hit`. O adversário continua
com os golpes do estilo dele.

## 11. Motivo da derrota (1 linha, sem simulação nova; a 1ª que valer, nesta ordem)
| Id | Quando | Texto provisório **[ROT]** | Dica **[ROT]** |
|---|---|---|---|
| `mt_counter` | Agressivo e `opp_counter_damage ≥ 20%` da sua vida máxima | OS CONTRAGOLPES DELE TIRARAM {n}% DA SUA VIDA | "NO AGRESSIVO, CADA CHUTE ERRADO VIRA SOCO DELE" |
| `mt_marks_late` | perdeu sem a perna cheia (`marks_full_at < 0` ou `t_fim < marks_full_at`) | AS MARCAS NÃO ENCHERAM: FALTOU FORÇA ({n} DE 3) | "FORÇA (OU O CONTRA-ATAQUE) MARCA A PERNA MAIS RÁPIDO" |
| `mt_held` | perna cheia, `attempts ≥ 1`, sem derrubar | ELE AGUENTOU {n} CHUTES RODADOS | "AGILIDADE FAZ MAIS CRÍTICO, E CADA CRÍTICO É UM RODADO" |
| `mt_never_hurt` | perna cheia, `attempts = 0` | A PERNA ENCHEU, MAS ELE NUNCA BAIXOU DE 60% | "MAIS FORÇA PARA CANSAR ELE" |
Formato igual à 7a1: `motivo.passive_note = {id, n, r}`.

## 12. Escolha da arte: 3 cartões
| Cartão | Nome | Regra de treino (`rule_text`) | Passiva (1 linha, `fight_text`) | Aparelho |
|---|---|---|---|---|
| Boxe | (igual) | (igual) | (igual) | Pera |
| Jiu-jitsu | (igual) | (igual) | (igual) | Boneco |
| **Muay Thai** | Muay Thai | `CRÍTICO DO CLIQUE: {chance}% DE CHANCE, x{mult}` → "20% DE CHANCE, x4,1" **[ROT]** | `CANELA: CADA CHUTE BAIXO MARCA A PERNA DELE. PERNA CHEIA, VEM O CHUTE RODADO` **[ROT]** | Saco comprido |
O cartão do Muay Thai só existe com `muay_thai` em `arts_unlocked`. Cabem 3 lado a lado na 640×360 (UI/UX; se não couber, 3
menores, nunca rolagem). `tagline` provisória: "Canela dura, paciência curta. Uma marca por chute." **[ROT]**

## 13. Save
**Continua v13, sem migração.** A arte, o aparelho, os golpes e os nós vêm de `data/`. Muda só:
- `permanent.arts_unlocked` pode ter `muay_thai` (o validador já aceita qualquer id que exista em `arts.json`);
- `career.art` / `permanent.last_art` podem ser `muay_thai`;
- `career.fight.result.finish` pode ser `"spin_kick"` (campo opcional da 7a1);
- marco novo `muay_thai_unlocked` (na lista de marcos que já existe);
- regra de carga da §9 (quem já venceu o Kid recebe a arte).
Nada muda para quem não tem o Muay Thai: a foto (`foto.gd`) **sem arte** sai igual à main.

## 14. Contrato de dados
### 14.1 `data/arts.json → arts[muay_thai]` (gravado)
| Campo | Valor | O que é |
|---|---|---|
| `apparatus` | `kick_bag` | aparelho da arte |
| `unlock` | `{type: "first_win", opponent: "opp_gym_2"}` | **novo**; artes sem `unlock` seguem a regra de hoje |
| `rule` | `{type: "click_crit_bonus", chance_add: 0.10, mult_add: 1.1}` | **tipo novo** (`GymData.REGRAS` += `click_crit_bonus`) |
| `passive.type` | `shin` | **tipo novo** |
| `damage_mult` / `taken_mult` / `interval_mult` / `need_ahead` | 0,88 / 1,0 / 1,0 / 0 | como na 7a1 |
| `marks_max`, `mark_per_kick`, `mark_strength_min/max`, `mark_cap` | 3 / 1,0 / 0,5–2,0 / 1,0 | marcas |
| `slow_per_mark` | 0,08 | lentidão dele por marca |
| `crit_per_mark`, `crit_agility_min/max`, `crit_cap` | 0,06 / 0,5–1,6 / 0,6 | crítico por marca |
| `spin_life_max`, `spin_ko` | 0,60 / 0,65 | chute rodado |
| `limp_from_marks` | 2 | só visual |
| `tactics.aggressive` | `mark_mult` 1,5, `opponent_counter` 0,6 | |
| `tactics.defensive` | `mark_mult` 0,75, `slow_mult` 1,5 | |
| `tactics.counter` | `marks_per_counter` 1 | |
| `rule_text`, `fight_text`, `tagline`, `icon` | provisórios **[ROT]**, `art_muay_thai` | |
Campo que falta = neutro (mult 1, extra 0). Validação no `GymData`: recortar como os outros (chances 0–1, `marks_max` 1–5 inteiro).

### 14.2 Outros arquivos (gravados)
| Arquivo | O quê |
|---|---|
| `data/training.json` | aparelho `kick_bag` (§3.2) |
| `data/moves.json` | estilo `muay_thai` + 4 golpes; kind novo `spin_kick` (§10.3) |
| `data/skill_tree.json` | região `muay_thai` (`lock: art:muay_thai`) + 4 nós (§5) |
| `data/minigames.json` | `spar.variants.muay_thai` (§7). Nenhum número travado mudou |
| `tests/data/fase7b1_casos.json` | casos exatos do Muay Thai (Python × GDScript), gerado por `tools/sim/exportar_casos.py` (que também regrava o `fase7a1_casos.json`, igual). Atenção: o mesmo script regrava o `fase3_casos.json` com uma diferença que já existia antes da 7b1 (estatísticas com o adversário ×1,4); não commitar essa troca sem conferir |

### 14.3 Chaves de texto novas (`data/ui_texts.json`; Roteirista)
`passive_muay_thai_name`, `passive_muay_thai_line`, `passive_muay_thai_line_late`, `passive_muay_thai_counter_warn`,
`passive_muay_thai_counter_marks`, `passive_share_muay_thai`, `fight_marks_full` ("PERNA CHEIA!"), `fight_spin_kick` ("CHUTE RODADO!"),
`reason_passive_mt_counter`, `reason_passive_mt_marks_late`, `reason_passive_mt_held`, `reason_passive_mt_never_hurt`, `tip_passive_mt_*`,
a fala `muay_thai_unlocked` do Osmar, o cartão (`rule_text`, `fight_text`, `tagline`), os `crit_texts` do saco, os nomes dos 4 nós
e do saco, as caixas do Choque do Muay Thai ("NO TEMPO", "CHUTE!", dica da batida).

## 15. Quem faz o quê
### Programador
1. `scripts/luta.gd`: ramo `shin` em `estado_passiva()` e `_rodar_arte()` (referência: `_lutar_shin` em `tools/sim/fase7b1_sim.py`);
   `chance_detalhada()` com `full_share`/`full_at`; campos da §10.1. Boxe, JJ e sem arte intactos.
2. `GymData`: `click_crit_bonus`, passiva `shin`, campo `unlock`. `MovesData.KINDS` += `spin_kick`.
3. `loja_geradores._socar()`: crítico do Muay Thai (§4.1), mesma ordem do `rng`. `bonus_arte_critico()` para a tela.
4. Liberação (§9): 1ª chegada sem as artes com `unlock`; vitória contra o Kid; regra de carga; marco e fala.
5. `previa()` (§6.2), `_montar_info_luta()` (golpes do estilo `muay_thai`, §10.3), motivo (§11).
6. `ChoqueLogica` com o controle `beat` (§7.1; referência `jogar_choque_mt` no simulador).
7. Testes (save de teste): (a) foto sem arte igual à main; (b) casos exatos (`fase7b1_casos.json`); (c) Boxe e JJ iguais à 7a2
   (os casos da 7a1 continuam passando); (d) a liberação nos 3 caminhos da §9; (e) `passive_note` de cada id em luta montada;
   (f) o Choque: clique no tempo × fora do tempo × 3º clique = chute; (g) o crítico do clique manual (20%, ×4,1) e do auto (10%, ×3).
   `docs/codigo/mapa.md` atualizado.
### UI/UX
3 cartões; linha da prévia nas 3 táticas; HUD das 3 marcas e "PERNA CHEIA!"; letreiro do chute rodado nas duas arenas; Choque do
Muay Thai (batida visível, combo de 3 pontos, CHUTE); região MUAY THAI da árvore (posição final). `alinhamento-ui` com 0 problemas.
### Diretor de Arte / Artista de Personagens
Conforme o escopo §3.4 e §8: saco de chute, ícones das marcas, da arte e dos nós, letreiro; lutador (guarda, chute baixo, joelhada,
clinch, chute rodado) e adversários (`hit_leg`, `limp`, `held_clinch`, `fall_spin`); 2–3 poses do Choque.
### Roteirista
Tudo que está marcado **[ROT]** e as chaves da §14.3.
### QA
Critérios 1–8, 13, 14. Referências: §6.3 (prévia), §7 (Choque e teto), §8 (balanço). Rodar `fase7b1_sim.py honesta choque teto campanha`.

## 16. Resumo
- **Canela:** cada chute baixo (acerto normal) marca a perna dele, até **3 marcas** (1 por chute com FORÇA igual à RESISTÊNCIA dele;
  0,5 a 1). Cada marca: ele **+8% mais lento** e o seu crítico **+6% × fator de AGILIDADE**. Perna cheia: todo crítico é **chute
  rodado**; com ele a ≤ 60% da vida, derruba em **65%** das vezes. Dano ×0,88. Agressivo marca ×1,5 e ele contragolpeia (60%);
  Defensivo marca ×0,75 e deixa ele ×1,5 mais lento; Contra-ataque: cada contragolpe vale 1 marca inteira.
- **Foco certo:** FORÇA com AGILIDADE (2/2/1). Saco comprido 50/35/15, 2.500, em caixa, mesmos upgrades da pera.
- **Regra de treino:** clique manual com crítico **20% e ×4,1** (sem arte: 10% e ×3). Na média ×1,35 (o Boxe é ×1,50): picos, não
  "Boxe melhor".
- **Árvore:** `mt_shin` 200 (marca ×1,5), `style_muay_thai` 1.200 (crítico ×4,65), `mt_oil` 400, `mt_rope` 300. Nenhum nó antigo muda.
- **Choque:** batida a cada 0,5 s, janela ±0,12 s, 3º clique no tempo = CHUTE (0,45). Afobado não marca ponto; quem segue a batida vence.
- **Liberação:** 1ª vitória contra o Kid (ou save antigo com `best_wins ≥ 6`). Save continua **v13**.
- **Simulação:** prévia honesta pior **1,2 ponto**; tela 8–19 s; teto do minigame pior **7,9%** em dias; tempo até o Kid
  com as 3 artes a **≤ 1,0% na mediana**; na média o Muay Thai fica a ≤ 1,8% do Boxe e no meio entre Boxe e JJ (a 4/s o JJ já é 5,8%
  mais lento que o Boxe, §8.3); as 3 pedem o mesmo total (0,91×) para o verde contra o Kid; Tonhão pelo chute rodado em 45–47%
  das vitórias; Boxe, JJ e sem arte idênticos (3.000/3.000).
