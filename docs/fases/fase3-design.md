# Fase 3 — Lutas e fim de carreira: design

Dono: Designer de Jogo. Versão 1 (2026-11-05).
Base: `docs/fases/fase3-escopo.md` (30 critérios), `docs/visao.md`, `docs/roadmap.md`, `fase2-design.md`, `fase2-api.md`, `fase2-revisao.md`, `data/*.json`, `scripts/` (contrato da Fase 2).
Textos: `docs/fases/fase3-textos.md` (Roteirista). Arte: `assets/sprites/manifest.json` (Diretor de Arte). Os ids daqui são os mesmos de lá.
Simulação de referência: `tools/sim/fase3_sim.py` (reaproveita `tools/sim/fase2_sim.py`). **A luta do simulador é a especificação**: em caso de dúvida, vale o que o simulador faz.

Regras que não mudam: a garagem continua paga em **Treino** (preços da Fase 2 **sem mudança**); o dinheiro vem só de vitórias e compra só a LOJA; nada da Fase 4+ entra.

---

## 1. Recursos: de onde vem, para onde vai

| Recurso | Bloco do save | Entra por | Sai por | Formato na tela |
|---|---|---|---|---|
| Treino, Força, Agilidade, Resistência | `career` | como na Fase 2 (clique, geradores, **Prof. Nelson**) | Treino: compras da garagem. Atributos: nunca | TRUNCAR |
| **Dinheiro** (`money`) | `career` | prêmio de vitória | compra na LOJA | `$ 120`, TRUNCAR |
| **Fama** (`fame`) | `career` | prêmio de vitória | nada (só conta) | inteiro |
| **Legado em jogo** (pote) | derivado de `career` | cresce com a fama e com o cinturão | vira Legado no fim da carreira | inteiro |
| **Legado total** (`legacy_total`) | `permanent` | fim de carreira (derrota 50%, aposentadoria 100% + bônus) | nada nesta fase (árvore = Fase 4) | inteiro |

- Derrota **não** dá dinheiro. Dinheiro, fama e pote se perdem no fim da carreira (o pote vira Legado antes).
- Comprar na LOJA **nunca** mexe em Treino nem em atributo.

## 2. Escada amadora

Ordem fixa. `ladder_index` (0..4) = quantas vitórias a carreira tem. Índice 4 = cinturão conquistado, sem mais lutas.

| # | id | Nome (Roteirista) | Força | Agilidade | Resistência | Perfil na prévia | Prêmio $ | Fama | Melhor tática |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `opp_warmup` | Dudu Alongado | **1.20K** | **100** | **800** | EQUILIBRADO | **50** | **10** | contra-ataque |
| 2 | `opp_strong` | Brutão do Posto | **27.0K** | **1.40K** | **5.40K** | FORTE | **150** | **30** | contra-ataque |
| 3 | `opp_fast` | Dinho Pulga | **20.0K** | **110K** | **6.00K** | RÁPIDO | **400** | **60** | defensivo |
| 4 | `opp_tank` | Seu Muralha (cinturão) | **78.0K** | **58.0K** | **490K** | RESISTENTE | **1.00K** | **100** | agressivo |

Leitura dos perfis (o que pune):
- **Dudu:** fraco e lento. Ensina a tela. O só-saco vence com ~3.1K de Força (≈3 min a 5 cliques/s), quem treina os 3 vence com ~2K.
- **Brutão:** soco que derruba quem não tem vida. Pune Resistência baixa: até o seu soco derrubá-lo primeiro, ele te derruba com 1 golpe. É lento, então quem tem Agilidade esquiva e devolve (contra-ataque).
- **Dinho:** esquiva e crítico. Pune quem só tem Força: o soco do só-saco erra muito e o crítico dele derruba. Defender os críticos (defensivo) é a resposta.
- **Seu Muralha:** muita vida e muita redução. Pune quem não tem dano e arrasta a luta para os pontos. Agressivo fura a guarda dele.

"Perfil na prévia" e o destaque "ELE É MUITO MAIS ..." (seção 6.4) vêm dos números, não de um campo: a UI usa `profile` do JSON só como rótulo.

## 3. Atributos de luta (efetivos)

O corpo é um só: **10% de todo o seu treino conta em cada atributo** na luta.
```
T            = forca + agilidade + resistencia          (atributos crus, os da garagem)
geral        = general_share × T                        (general_share = 0.10)
F_ef = forca + geral ;  A_ef = agilidade + geral ;  R_ef = resistencia + geral
```
Vale para os dois lados (o adversário também usa os números crus do JSON + 10% do total dele).
Por quê: sem isso, quem tem 0 em um atributo vira caso extremo (0 de vida extra, 0 de agilidade) e a luta deixa de depender do treino. Com isso, foco único ainda perde (critério 9, seção 13.3), mas o resultado sobe de forma contínua com o treino.
A prévia e a tela mostram os **atributos crus** (os que o jogador treinou). Os efetivos são só da conta.

## 4. A luta (simulação)

### 4.1 Números de cada lutador
```
vida_max = life_base + life_per_endurance × R_ef                       (100 + 5 × R_ef)
bruto    = damage_base + damage_per_strength × F_ef(atacante)          (10 + F_ef)
reducao  = reduction_max × R_ef(defensor) / (R_ef(defensor) + F_ef(atacante))     (0 a 50%)
reducao  = reducao × (1 − pierce(tática do atacante))
dano     = bruto × (1 − reducao) × damage_mult(tática do atacante) × taken_mult(tática do defensor)

v        = (A_ef(atacante) − A_ef(defensor)) / (A_ef(atacante) + A_ef(defensor))       (vantagem de agilidade, −1 a 1; 0 se a soma for 0)
critico  = crit_base + crit_gain × max(0, v)                            (5% a 55%)
esquiva  = min(dodge_cap, (dodge_base + dodge_gain × max(0, −v)) × dodge_mult(defensor) + dodge_bonus(defensor))   (3% a 75%)
```
- **Agilidade só conta quando você é mais ágil que ele.** Ágeis iguais: 5% de crítico e 3% de esquiva (só para dar ritmo). Quem é mais ágil acerta mais crítico; quem é menos ágil leva mais esquiva. Isso deixa as lutas entre parecidos quase sem sorte, e as lutas contra o Dinho cheias de sorte (é o perfil dele).
- Os números `dano`, `critico` e `esquiva` são calculados **uma vez** no início da luta, para os dois lados.

| Campo (`data/fights.json` → `combat`) | Valor | Por quê |
|---|---|---|
| `general_share` | **0.10** | seção 3 |
| `life_base` / `life_per_endurance` | **100 / 5** | 5 de vida por ponto: Resistência vale tanto quanto Força no "quantos golpes aguento" |
| `damage_base` / `damage_per_strength` | **10 / 1** | dano = Força, fácil de ler |
| `reduction_max` | **0.5** | Resistência igual à Força dele corta 25% |
| `crit_base` / `crit_gain` / `crit_multiplier` | **0.05 / 0.50 / 2.0** | crítico dobra |
| `dodge_base` / `dodge_gain` / `dodge_cap` | **0.03 / 0.50 / 0.75** | |
| `damage_spread` | **0.15** | cada golpe varia ±15% |

### 4.2 Linha do tempo
```
first_attack   = 0.9 s   (quem tem A_ef maior ataca primeiro; empate: o jogador)
o outro        = 0.9 + attack_interval/2 = 1.8 s
attack_interval= 1.8 s   (cada lado ataca a cada 1.8 s: 0.9, 2.7, 4.5 ... e 1.8, 3.6, 5.4 ...)
counter_delay  = 0.5 s   (contra-golpe sai 0.5 s depois da esquiva, se a tática for contra-ataque)
time_limit     = 16 s    (nenhum evento depois de 16.0 s)
min_ko_time    = 5.0 s
round_length   = 6 s     (só marcador: round = floor(t_ko / 6) + 1 → 1º, 2º ou 3º round)
intro_seconds  = 1.5 s   (nomes + "LUTEM!" antes do t = 0)
outro_seconds  = 1.5 s   (queda/"TEMPO!" e pose de vitória)
```
Ordem dos eventos: o de **menor tempo** primeiro; no empate, **contra-golpe antes de ataque normal**; depois **jogador antes do adversário**. É a ordenação por tupla `(tempo, 0 se contra-golpe senão 1, 0 se jogador senão 1)`.

### 4.3 Um ataque (ordem fixa dos sorteios)
Para **todo** ataque, normal ou contra-golpe, sortear **3 números na ordem**, mesmo que não sejam usados: `r_esq`, `r_crit`, `r_var` (`randf()` em [0,1)).
```
se não for contra-golpe e r_esq < esquiva(defensor):
     ESQUIVA. Se a tática do defensor tem counter_mult > 0 e t + 0.5 ≤ 16: agenda contra-golpe do defensor em t + 0.5.
senão:
     critico = r_crit < critico(atacante)
     d = dano × (1 + (crit_multiplier − 1) × (1 − crit_guard(defensor)))  se critico, senão dano
     se contra-golpe: d = d × counter_mult(tática do atacante)
     d = d × (1 + damage_spread × (2 × r_var − 1))
     vida(defensor) −= d
     se vida(defensor) ≤ 1e-9 × vida_max(defensor): K.O., a luta acaba neste evento.
```
- **Contra-golpe não pode ser esquivado** e não gera outro contra-golpe.
- O adversário não tem tática (neutro: todos os multiplicadores 1, bônus 0).

### 4.4 K.O. cedo: "grogue" (garante os 8 s)
Não existe teto de dano por golpe: o Brutão derruba de 1 golpe quem não tem vida, e isso é o que ensina a Resistência.
Para a luta nunca durar menos de 8 s de tela: **o resultado é decidido no golpe do K.O.** (`t_ko`), mas se `t_ko < min_ko_time` quem caiu **fica grogue** (animação `tired`, cambaleando, sem atacar) até `t = 5.0 s` e só então cai (`ko`). O vencedor fica em guarda. Nada de sorteio acontece depois do K.O.
```
t_fim = max(t_ko, min_ko_time)            (com K.O.)
t_fim = time_limit                         (sem K.O.)
tela  = intro_seconds + t_fim + outro_seconds      → entre 8.0 s e 19.0 s
```

### 4.5 Fim no tempo (pontos)
Sem K.O. até 16 s: vence quem tem **maior % de vida** (`vida / vida_max`).
**Empate exato: vence o adversário** ("quem defende o lugar fica com ele"). Texto novo para o Roteirista: `time_rule_tie` = "EMPATE EXATO: FICA COM ELE". Com dano em float isso praticamente não acontece, mas a regra está escrita.

### 4.6 Semente e resultado decidido no começo
- Ao apertar LUTAR: `seed = rng.randi()` (o RNG do jogo), a luta é **simulada inteira na hora** com `RandomNumberGenerator.seed = seed` e o resultado + registro vão para o save **antes** da animação começar (seção 12.3).
- Mesmo estado (atributos crus dos dois, tática) + mesma semente = mesma luta, golpe a golpe. É o teste do critério 6.
- O simulador Python e o GDScript têm geradores diferentes: a igualdade golpe a golpe vale dentro do jogo; as **estatísticas** (taxas, rótulos, durações) têm que bater com as tabelas daqui. O Programador deve portar `Regras.lutar` linha a linha.

### 4.7 Registro da luta (para a tela e o QA)
Cada evento: `{t, who: 0 jogador | 1 adversário, type: "hit" | "crit" | "dodge", counter: bool, damage, life_after}`. Mais o resumo `{win, ko, t_ko, t_end, round, pct_player, pct_opponent, counts}` com `counts = {attacks, hits, dodges, crits, damage, counters}` por lado.
Mapeamento para a arte (`manifest.json`, ações `fight_*`): ataque normal = `jab`, crítico e contra-golpe = `heavy` (o `hit_frame` da folha cai no `t` do evento: a animação começa `hit_frame / fps` antes), quem leva = `hit` (com tática defensiva: `block`), esquiva = `dodge` de quem esquivou, grogue = `tired`, K.O. = `ko`, vencedor = `victory`. Número flutuante: `damage` arredondado (ARREDONDAR); crítico maior, em `r3`, com "!".

## 5. Táticas

Escolhida na prévia; o risco recalcula na hora. Fica guardada como "última tática" (`career.tactic`); padrão `defensive`.

| id | Botão | `damage_mult` | `taken_mult` | `pierce` | `dodge_mult` | `counter_mult` | `crit_guard` | Em palavras |
|---|---|---|---|---|---|---|---|---|
| `aggressive` | AGRESSIVO | **1.35** | **1.25** | **0.5** | 1 | 0 | 0 | +35% de dano e fura metade da defesa dele; você apanha 25% mais |
| `defensive` | DEFENSIVO | **0.85** | **0.85** | 0 | 1 | 0 | **1.0** | −15% de dano dos dois lados e **o crítico dele vira golpe normal** |
| `counter` | CONTRA-ATAQUE | **0.90** | 1 | 0 | **2.0** | **1.0** | 0 | sua esquiva dobra e cada esquiva devolve um golpe que não dá para esquivar; −10% de dano |

- Cada uma mira um canal: agressivo = **redução dele** (bom contra muita Resistência), defensivo = **crítico dele** (bom contra muita Agilidade), contra-ataque = **sua esquiva** (bom contra quem é mais lento que você).
- Critério 10, melhor tática por adversário (perfil equilibrado, seção 13.2): Dudu e Brutão → contra-ataque; Dinho → defensivo; Seu Muralha → agressivo. Cada tática é a melhor contra pelo menos 1.
- Critério 2: trocar a tática muda o rótulo em todos os 4 (ex.: equilibrado 1/3 com 25.3K contra o Brutão: contra-ataque 65% EQUILIBRADO, defensivo 18% PERIGOSO).
- Sugestão de texto ao Roteirista (as dicas atuais servem): o defensivo pode dizer "Fecha a guarda. O crítico dele não entra."

## 6. Prévia e risco

### 6.1 Chance estimada (Monte Carlo com sementes fixas)
```
chance(estado, adversario, tatica) = vitórias / N   com N = risk.samples = 200 lutas, sementes 1, 2, ..., 200
```
- Sementes **fixas**: o rótulo não pisca entre recálculos com o mesmo estado; e a luta real usa outra semente (seção 4.6), então a prévia não "sabe" o resultado.
- Custo: 200 lutas × ~20 eventos ≈ 4.000 passos (milissegundos). A prévia calcula as 3 táticas ao abrir (600 lutas) e só a escolhida a cada troca. O HUD ("PRÓXIMA: nome + risco") recalcula com a última tática **no máximo 1 vez por segundo** e só se algum atributo mudou.
- Pode parar cedo quando o rótulo já está decidido (o simulador faz isso em `Regras.passa`); o rótulo tem que sair igual ao da conta completa.

### 6.2 Rótulo
| Rótulo | Regra | Cor | Texto |
|---|---|---|---|
| FÁCIL | chance ≥ **0.90** | verde | `risk_easy` |
| EQUILIBRADO | 0.40 ≤ chance < 0.90 | amarelo | `risk_even` |
| PERIGOSO | chance < **0.40** | vermelho | `risk_hard` |

O limiar do fácil é 0.90 (e não 0.85) para dar folga ao erro da amostra de 200: um estado que a prévia chama de fácil vence, de verdade, pelo menos ~86% (tabela 13.4). A porcentagem **não** aparece (Fase 4).

### 6.3 O que a prévia mostra
Nome, descrição, perfil, os 3 atributos crus dele × os seus, rótulo de risco da tática selecionada, as 3 táticas com a dica, prêmio (`stake_win` com $ e fama; o 4º mostra `stake_belt`), `stake_lose`, `time_rule`, LUTAR e VOLTAR A TREINAR (não muda nada).

### 6.4 Destaque "ELE É MUITO MAIS ..."
```
para cada atributo X: razao(X) = X_cru(dele) / max(1, X_cru(seu))
destaque = o X de maior razao, se razao ≥ 2  →  lead_strength / lead_agility / lead_endurance
(se nenhuma razão ≥ 2, sem destaque; empate: Resistência, Força, Agilidade)
```

## 7. Motivo da derrota e dica

**Atualizado pela seção 16 (pós-QA): azar, teto da busca e validade das estatísticas.** Calculado quando a luta é derrota (durante a animação ou ao reabrir; nunca muda para o mesmo bloco `fight`). Usa a mesma estimativa da prévia (200 sementes fixas) e a tática usada.
```
T = soma dos atributos crus do jogador
falta(X) = menor n tal que chance(com X + n) ≥ 0.90        para X em (Resistência, Força, Agilidade), nesta ordem
           busca binária, 14 passos, em [0, 16 × T + 1000]; se nem 16 × T + 1000 bastar: falta(X) não existe
decisivo = X de MENOR falta(X)   (empate: o primeiro da ordem)
se nenhum falta(X) existe:  Δ = max(10, 0.25 × T);  decisivo = X de maior chance(com X + Δ)
faltaram = falta(decisivo), arredondado para cima com teto3
```
- É a definição do critério 14 ("o que mais mudaria o resultado se tivesse mais"), medida com o mesmo motor: o atributo que **com menos treino** deixa essa luta fácil.
- "Faltaram N" = quanto a mais daquele atributo deixaria **essa luta FÁCIL**. É a mesma linguagem da prévia.
- Custo: até 3 × 15 × 200 = 9.000 lutas (fração de segundo). Calcular durante a animação (ela dura ≥ 8 s). **Não precisa ser salvo**: é determinístico a partir do bloco `fight` e é recalculado ao reabrir.
- Primeira versão usava "maior chance com +25% do total"; foi trocada porque, quando dois atributos levam a 99%, o desempate virava sorte da amostra (2 erros em 20 na conferência).

Frase (modelos do Roteirista, `fase3-textos.md` §6):
| Decisivo | Se `faltaram` existe | Senão (número do registro da luta) |
|---|---|---|
| Resistência | `reason_endurance` modelo 2: FALTARAM {n} DE RESISTÊNCIA PARA FICAR EM PÉ | modelo 1: ELE TIROU {n}% DA SUA VIDA EM {k} GOLPES (`n` = 100 × dano dele ÷ sua vida máx., `k` = acertos dele) |
| Força | `reason_strength` modelo 2: FALTARAM {n} DE FORÇA PARA ABRIR A GUARDA | modelo 1: ELE BATIA {n}% MAIS FORTE (`n` = 100 × (% da vida por acerto dele ÷ % por acerto seu − 1)) |
| Agilidade | `reason_agility` modelo 2 adaptado: FALTARAM {n} DE AGILIDADE (texto novo, Roteirista) | modelo 1: ELE ESQUIVOU {n}% DOS SEUS GOLPES (`n` = esquivas dele ÷ seus ataques normais) ou modelo 2: ELE ACERTOU {n} CRÍTICOS. VOCÊ, {k} |

- A tela mostra **as duas linhas**: o "faltaram" (ação) e uma estatística do registro (o que se viu na luta), para o jogador ligar o número ao que assistiu.
- Dica: `tip_<decisivo>` (variação sorteada pela semente da luta, para ser estável ao reabrir).
- Linha extra `tip_tactic` **só se** outra tática tinha chance ≥ chance usada + **0.25**. Nunca substitui a dica do atributo.
- "Quem e quando": K.O. → `end_who_ko` com o round de `t_ko`; tempo → `end_who_points`.
- Conferência no simulador (13.6): o decisivo com 200 sementes fixas bate com o decisivo medido com 2.000 sementes novas.

## 8. Vitória, Legado e aposentadoria

### 8.1 Vitória
```
money += prize_money ; fame += prize_fame ; ladder_index += 1 ; wins_total += 1
se o adversário tem belt: belt = true  (sem mais lutas: tela "CINTURÃO AMADOR", belt_unlock, belt_hint)
```
Volta para a garagem com `victory_gain` e `victory_next`. Nenhum valor da garagem muda.

### 8.2 Legado
```
pote (Legado em jogo) = floor(fame × legacy_per_fame) + (belt_legacy_bonus se belt)       legacy_per_fame = 0.2, belt_legacy_bonus = 10
derrota      → legado_ganho = floor(pote × defeat_share)                                   defeat_share = 0.5
aposentadoria→ legado_ganho = floor(pote × retire_share) + (floor(pote × retire_belt_bonus_share) se belt)   1.0 e 0.5
legacy_total += legado_ganho
```
O pote é **derivado** (não é salvo): não tem como duplicar.

| Vitórias na carreira | Fama | Pote | Perde a próxima | Aposenta |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 (aviso `retire_confirm_zero`) |
| 1 (Dudu) | 10 | 2 | 1 | 2 |
| 2 (+ Brutão) | 40 | 8 | 4 | 8 |
| 3 (+ Dinho) | 100 | 20 | 10 | 20 |
| 4 (cinturão) | 200 | 40 + 10 = **50** | — (não há próxima) | **50 + 25 = 75** (`retire_confirm_bonus` +25) |

- **Aposentar rende mais que perder** sempre que o pote > 0 (100% contra 50%, arredondado para baixo). Com pote 0 os dois dão 0: é o único empate, e a confirmação já diz "você leva 0". O teste do critério 16 confere `aposentar > perder` para pote ≥ 1 e `aposentar ≥ perder` sempre.
- Os números são pequenos de propósito: a Fase 4 vai dar preço aos nós (o 1º nó deve custar ~1–4, para a 1ª derrota típica, que leva 1 a 4, já comprar algo).
- A derrota com 0 vitórias rende 0. É raro (Dudu é ganho antes de 4 min em ~95% das carreiras) e é honesto: não houve carreira.

### 8.3 Aposentar
- Botão só **entre lutas** (garagem, sem prévia aberta, sem luta em andamento, sem tela de fim). Também disponível depois do cinturão.
- Confirmação: `retire_confirm_take` com o `legado_ganho`, `retire_confirm_bonus` se belt, `retire_confirm_lose`.
- Depois: mesma tela de fim, modo "saiu por cima", botão NOVA CARREIRA.

### 8.4 Nova carreira
Zera todo o `career` (treino, atributos, foco padrão, geradores, melhorias, dinheiro, fama, escada, cinturão, Prof. Nelson, luva → luva velha, tática padrão, tempo). `permanent.career_number += 1`. Legado total intacto. 1 clique (NOVA CARREIRA) e já está na garagem.

### 8.5 Recordes (`permanent`)
`legacy_total`, `career_number`, `careers_finished`, `best_wins` (máximo de vitórias numa carreira), `belts_won` (quantas carreiras ganharam o cinturão). Atualizados no fim de cada carreira, no mesmo save que soma o Legado.

## 9. LOJA (dinheiro)

### 9.1 Gerador pago: `gen_paid_1` (Prof. Nelson)
```
custo(n) = teto3(base_cost × growth^n)        (mesma teto3 da Fase 2)
produz Treino/s como os geradores da garagem (vai para o foco, entra em producao_total)
```
| id | `base_cost` ($) | `growth` | `production` (Treino/s) | `draw_thresholds` |
|---|---|---|---|---|
| `gen_paid_1` | **50** | **1.6** | **25** | [1, 4] |

Custos: $50, $80, $128, $205, $328, $525... 1 vitória (Dudu, $50) paga o 1º (critério 18). Quando entra, quase quadruplica a renda passiva da hora (~7/s → ~32/s).

### 9.2 Luvas de loja: `glove_shop`
Nível comprado em ordem. Cada nível **multiplica o treino por clique dos 3 aparelhos** (por cima das melhorias do aparelho) e troca **na mesma hora** cursor, mão na garagem e mão na luta (`sprite_suffix` do manifest).
```
por_clique(foco) = base_training × mult_aparelho(foco) × mult_luva
mult_luva        = produto de click_multiplier dos níveis comprados (1 com a luva velha)
```
| id | Nome (Roteirista) | `cost` ($) | `click_multiplier` | Clique depois (saco no máximo) |
|---|---|---|---|---|
| `glove_l1` | Luva de lona | **120** | **2** | 15 → 30 (crítico 90) |
| `glove_l2` | Luva de couro | **500** | **2** | 30 → 60 (crítico 180) |
| `glove_l3` | Luva de marca | — | — | **fica fora da Fase 3** (ver abaixo) |

- **glove_l3:** o Roteirista marcou como opcional e o escopo pede 1 ou 2 níveis. Todo o dinheiro de uma carreira antes do cinturão é $600, e o do cinturão ($1.000) chega quando não há mais lutas: uma 3ª luva não teria uso. A arte (`fight_player_*_glove_l3`) fica guardada para a Fase 5 (mais itens de loja). Não entra em `data/shop.json`.
- Decisão "luva ou treinador?": com $150 do Brutão, a lona ($120) dobra o clique; 2 Nelsons ($80 + $128) dão +50/s. Com 5 cliques/s e saco no máximo, a lona dá +90/s: melhor para quem clica, o Nelson para quem clica pouco ou troca muito de foco. Com $400 do Dinho: couro ($500, precisa de sobra) ou mais Nelsons.
- O 1º item (Nelson, $50) cabe no prêmio de 1 vitória; a luva de lona, no de 2 (critério 18).

## 10. HUD

| Lugar | Valor | Formato |
|---|---|---|
| `hud_money` | `money` | `$ ` + TRUNCAR |
| `hud_fame` | `fame` | inteiro |
| `hud_legacy_run` | pote (8.2) | inteiro |
| `hud_career` | `permanent.career_number` | "CARREIRA {n}" |
| `hud_next_fight` | nome do adversário de `ladder_index` + rótulo (6.1, última tática) | cor do rótulo; depois do cinturão: `no_more_fights` |
| LOJA | custo, quantidade/nível, efeito ("+25/S", "x2 POR CLIQUE") | custo exato; `shop_no_money` em `r2` |

## 11. Contrato de dados (`data/`, JSON)

Regras da Fase 2 valem: campo faltando, tipo errado ou fora da faixa → padrão desta seção + `push_warning`; campo desconhecido ignorado; id vazio/repetido ignorado; ordem das listas = ordem na tela. Nomes e textos vêm do Roteirista (podem morar no mesmo objeto, como na Fase 2, ou em `ui_texts.json`).

### `data/fights.json` (novo)
```json
{
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
		"intro_seconds": 1.5, "outro_seconds": 1.5
	},
	"tactics": [
		{ "id": "aggressive", "damage_mult": 1.35, "taken_mult": 1.25, "pierce": 0.5, "dodge_mult": 1.0, "dodge_bonus": 0.0, "counter_mult": 0.0, "crit_guard": 0.0 },
		{ "id": "defensive",  "damage_mult": 0.85, "taken_mult": 0.85, "pierce": 0.0, "dodge_mult": 1.0, "dodge_bonus": 0.0, "counter_mult": 0.0, "crit_guard": 1.0 },
		{ "id": "counter",    "damage_mult": 0.90, "taken_mult": 1.0,  "pierce": 0.0, "dodge_mult": 2.0, "dodge_bonus": 0.0, "counter_mult": 1.0, "crit_guard": 0.0 }
	],
	"default_tactic": "defensive",
	"risk": { "samples": 200, "easy_min": 0.90, "even_min": 0.40, "hud_refresh_seconds": 1.0 },
	"reason": { "delta_share": 0.25, "delta_min": 10, "target": 0.90, "search_steps": 14,
	            "search_max_share": 16.0, "tactic_tip_gap": 0.25, "lead_ratio": 2.0 }
}
```
| Campo | Faixa válida | Padrão |
|---|---|---|
| números de `combat` | ≥ 0 e finitos; `time_limit` > `min_ko_time` > 0; `attack_interval` > 0; chances e `general_share` em [0,1] | os do bloco acima |
| `tactics[].*_mult` | ≥ 0 | 1 (`counter_mult`: 0) |
| `tactics[].pierce`, `crit_guard`, `dodge_bonus` | 0 a 1 | 0 |
| `default_tactic` | um id de `tactics` | `defensive` |
| `risk.samples` | inteiro 20 a 2000 | 200 |
| `risk.easy_min` > `risk.even_min` | 0 a 1 | 0.90 / 0.40 |

### `data/opponents.json` (novo)
```json
{
	"opponents": [
		{ "id": "opp_warmup", "strength": 1200,  "agility": 100,    "endurance": 800,    "prize_money": 50,   "prize_fame": 10,  "belt": false, "profile": "EQUILIBRADO" },
		{ "id": "opp_strong", "strength": 27000, "agility": 1400,   "endurance": 5400,   "prize_money": 150,  "prize_fame": 30,  "belt": false, "profile": "FORTE" },
		{ "id": "opp_fast",   "strength": 20000, "agility": 110000, "endurance": 6000,   "prize_money": 400,  "prize_fame": 60,  "belt": false, "profile": "RÁPIDO" },
		{ "id": "opp_tank",   "strength": 78000, "agility": 58000,  "endurance": 490000, "prize_money": 1000, "prize_fame": 100, "belt": true,  "profile": "RESISTENTE" }
	]
}
```
Atributos ≥ 0 finitos; prêmios ≥ 0. A ordem da lista é a ordem da escada. Critério 25: mudar um número aqui e reabrir muda o jogo.

### `data/shop.json` (novo)
```json
{
	"paid_generators": [
		{ "id": "gen_paid_1", "base_cost": 50, "growth": 1.6, "production": 25, "draw_thresholds": [1, 4] }
	],
	"gloves": {
		"id": "glove_shop",
		"levels": [
			{ "id": "glove_l1", "cost": 120, "click_multiplier": 2 },
			{ "id": "glove_l2", "cost": 500, "click_multiplier": 2 }
		]
	}
}
```
Mesmas faixas de `generators.json`; `click_multiplier` ≥ 1; `cost` > 0. A luva velha (`glove_old`) não é item: é o nível 0.

### `data/career.json` (novo)
```json
{ "legacy_per_fame": 0.2, "belt_legacy_bonus": 10, "defeat_share": 0.5, "retire_share": 1.0, "retire_belt_bonus_share": 0.5 }
```
Validação: `defeat_share` < `retire_share` (senão, padrão com aviso: a regra "aposentar rende mais" não pode quebrar por dado).

### Arquivos que não mudam
`training.json`, `generators.json`, `config.json`: valores da Fase 2. **Sem reajuste de preço da garagem** (R4): com as lutas e a loja o ritmo fechou sem mexer neles (seção 13).

## 12. Save v3

Um arquivo só (`user://save.json`), como recomendado: o guarda `test_real_save_guard.gd` continua valendo sem mudança.

### 12.1 Formato
```json
{
	"version": 3,
	"saved_at_unix": 1730000000,
	"state": {
		"career": {
			"training": 1234.5,
			"attributes": { "strength": 900.0, "agility": 200.0, "endurance": 134.5 },
			"focus": "punching_bag",
			"generators": { "neighbor_kid": 12, "retired_uncle": 3 },
			"upgrades": { "punching_bag": 2, "jump_rope": 0, "treadmill": 1 },
			"paid_generators": { "gen_paid_1": 2 },
			"glove_level": 1,
			"money": 30.0,
			"fame": 40,
			"ladder_index": 2,
			"belt": false,
			"tactic": "counter",
			"play_seconds": 742.0,
			"money_earned": 200.0,
			"fight": null
		},
		"permanent": {
			"legacy_total": 14,
			"career_number": 3,
			"careers_finished": 2,
			"best_wins": 3,
			"belts_won": 0
		},
		"ending": null
	}
}
```
- `career.fight` (luta em andamento): `{ "opponent": "opp_fast", "tactic": "defensive", "seed": 123456, "player": {"strength":..,"agility":..,"endurance":..}, "result": {win, ko, t_ko, t_end, round, pct_player, pct_opponent} }`. O registro de eventos e o motivo **não** são salvos: é recalculado de `player` + adversário + tática + semente (determinístico).
- `ending` (tela de fim pendente): `{ "kind": "defeat" | "retire", "career_number", "legacy_gained", "opponent", "result", "reason", "summary": {wins, belts, fame, money_earned, play_seconds} }`.
- `play_seconds`: tempo de jogo da carreira (soma de `delta` com o jogo aberto). `money_earned`: soma dos prêmios.

### 12.2 Leitura (validação)
Campos da Fase 2 como antes. Novos: números ≥ 0 finitos (senão 0); `glove_level` recortado em 0..níveis; `ladder_index` em 0..nº de adversários; `belt` só pode ser true se `ladder_index` == nº de adversários; `tactic` inválida → `default_tactic`; `fight` com adversário inexistente → descartado (com aviso, sem dar vitória nem derrota); `permanent.career_number` ≥ 1.

### 12.3 Momentos de salvar (ninguém escapa da derrota e nada duplica)
| Ação | O que acontece, **num único save** |
|---|---|
| Apertar LUTAR | simula tudo, grava `career.fight` com o resultado. Só depois começa a animação |
| Fim da animação de **vitória** (ou reabrir com `fight` salvo e `win`) | aplica prêmio (8.1), `fight = null` |
| Fim da animação de **derrota** (ou reabrir com `fight` e derrota) | `legacy_total += legado_ganho`, recordes, `ending = {...}`, `fight = null` |
| Confirmar APOSENTAR | `legacy_total += legado_ganho`, recordes, `ending = {...}` |
| NOVA CARREIRA | `career` = carreira nova, `career_number += 1`, `ending = null` |

- Reabrir com `fight` salvo: pula a animação e vai direto para o resultado (critério 11).
- Reabrir com `ending`: mostra a tela de fim (o Legado já foi somado; não soma de novo). Enquanto `ending` existe, a garagem não aceita clique nem compra.
- Reabrir com a prévia ou a confirmação de aposentar abertas: elas não são salvas; volta para a garagem (não mudaram nada).

### 12.4 Migração `_migrar_2_para_3`
```
v2: { version 2, saved_at_unix T, state: { career: {...Fase 2...} } }
v3: { version 3, saved_at_unix T, state: {
        career: { ...os 5 campos da Fase 2 copiados..., paid_generators: {}, glove_level: 0, money: 0, fame: 0,
                  ladder_index: 0, belt: false, tactic: "defensive", play_seconds: 0, money_earned: 0, fight: null },
        permanent: { legacy_total: 0, career_number: 1, careers_finished: 0, best_wins: 0, belts_won: 0 },
        ending: null } }
```
`SaveStore.MIGRACOES[2] = "_migrar_2_para_3"`, `VERSAO_ATUAL = 3`. A cadeia v0 → v1 → v2 → v3 continua.

## 13. Simulação e curva

`tools/sim/fase3_sim.py` lê os JSON da seção 11 quando existirem (senão usa os valores daqui), e a garagem de `training.json` e `generators.json` com as regras do `fase2_sim.py`. Seções: `limiares taticas foco duracao risco carreiras curvas motivo dica` (sem argumento: tudo).

### 13.1 Jogadores simulados
- Clicam C cliques/s sem parar (3, 4, 5, 8), crítico de clique pela média. Param de clicar só na prévia (5 s) e na luta (tela); o passivo continua.
- Garagem: compra "melhor" da Fase 2 (melhoria ponderada pelo tempo de foco em cada aparelho). LOJA: compra o item de maior ganho por dinheiro e junta para ele.
- **Olham a prévia a cada 30 s** (entre compras), lutam com a tática de maior chance (a prévia mostra o rótulo de cada uma).
- `saco` / `corda` / `esteira`: foco fixo. `rodizio`: troca a cada 60 s. `bom`: a cada 30 s treina o atributo que mais sobe a chance contra o próximo adversário (o que a prévia e a tela de fim ensinam).
- "luta quando": `equilibrado` = luta com chance ≥ 40%; `facil` = só com ≥ 90%. `impaciente 5 min`: se ficar 5 min sem poder lutar (perigoso), luta assim mesmo.
- `dica` (critério 24): 2ª carreira alternando 60 s entre o saco e o aparelho da dica da 1ª derrota.

### 13.2 Onde cada perfil vira "equilibrado" e "fácil"
Treino total (soma dos 3 atributos crus) em que a melhor tática chega a 40% / 90%:

| perfil | Dudu | Brutão | Dinho | Seu Muralha |
|---|---|---|---|---|
| só Força | 3.10K / 3.32K | 47.8K / 47.8K | 104K / 145K | 866K / 974K |
| só Agilidade | 3.30K / 5.90K | 52.8K / 100K | 177K / 222K | 802K / 1.46M |
| só Resistência | 3.10K / 3.16K | 45.3K / 47.8K | 100K / 130K | 798K / 893K |
| **equilibrado 1/3** | **1.57K / 1.96K** | **23.3K / 28.2K** | **67.8K / 83.1K** | **452K / 528K** |
| Força + Resistência | 1.95K / 2.28K | 28.4K / 33.4K | 57.5K / 80.7K | 509K / 580K |
| Força + Agilidade | 1.84K / 2.73K | 21.7K / 53.6K | 107K / 145K | 545K / 760K |
| Agilidade + Resistência | 2.00K / 2.66K | 29.1K / 38.8K | 108K / 122K | 547K / 736K |

Qualquer foco único precisa de **1.6x a 1.9x** mais treino que o equilibrado para o mesmo "fácil": não existe foco único bom (critério 9, R1). Dois atributos ficam no meio; Força + Resistência é o melhor contra o Dinho (por isso a dica "esteira" funciona para o só-saco).

Melhor tática (perfil equilibrado; treino para chegar a fácil com cada uma; menor = melhor), critério 10:
| adversário | agressivo | defensivo | contra-ataque | melhor |
|---|---|---|---|---|
| Dudu | 2.32K | 2.33K | **1.96K** | contra-ataque |
| Brutão | 31.1K | 32.7K | **28.2K** | contra-ataque |
| Dinho | 92.1K | **83.1K** | 99.6K | defensivo |
| Seu Muralha | **528K** | 574K | 538K | agressivo |

Chance com cada tática no ponto em que a melhor dá 65% (critério 2: a tática muda o rótulo nos 4):
| adversário | treino | agressivo | defensivo | contra-ataque |
|---|---|---|---|---|
| Dudu | 1.73K | 24% | 4% | **62%** |
| Brutão | 25.3K | 30% | 18% | **65%** |
| Dinho | 75.2K | 49% | **67%** | 36% |
| Seu Muralha | 489K | **63%** | 16% | 58% |

### 13.3 Critério 9 (mesmo treino total, melhor tática de cada um)
| adversário | treino total | só Força | equilibrado 1/3 |
|---|---|---|---|
| Dudu | 1.96K | 1% | 83% |
| Brutão | 28.2K | 5% | 83% |
| Dinho | 83.1K | 25% | 91% |
| Seu Muralha | 528K | 1% | 90% |

### 13.4 Risco honesto (critério 3)
Estados variados (adversário aleatório, treino de 0,15x a 6x o dele, divisão aleatória dos atributos, tática aleatória); rótulo pela prévia (sementes 1..200); resultado com semente nova.
| rótulo | lutas | taxa real | meta | chance média prevista |
|---|---|---|---|---|
| fácil | 500 | **99.8%** | ≥ 85% | 99.7% |
| equilibrado | 500 | **69.4%** | 40–85% | 68.3% |
| perigoso | 500 | **1.4%** | < 40% | 2.4% |

Pior caso (só estados na beira das faixas, 300 lutas cada): fácil com prévia 90–93% → **91.7%**; equilibrado 40–45% → 41.0%; equilibrado 85–90% → 85.0%; perigoso 35–40% → 40.7%. Mesmo na beira, o fácil passa de 85% e o perigoso fica em ~40%. O teste automático deve repetir a tabela de cima (500 por rótulo).
Cuidado do teste: a estimativa de **um** estado pode errar alguns pontos (ex.: no simulador, um estado do Seu Muralha com prévia 90% venceu 23 de 30). A garantia é por rótulo, em muitos estados, que é o que o critério pede.

### 13.5 Duração (critério 5)
| amostra | tela mín. | p10 | mediana | p90 | tela máx. | K.O. |
|---|---|---|---|---|---|---|
| 10.000 lutas de estados variados (muitas desiguais) | 8.0 s | 8.0 s | 8.0 s | 17.9 s | 19.0 s | 91% |
| 600 lutas disputadas (prévia 30–95%) | 8.0 s | 8.0 s | 10.2 s | 19.0 s | 19.0 s | 78% |

Mediana por adversário (disputadas): Dudu 10.7 s, Brutão 8.0 s (soco que derruba + grogue), Dinho 10.2 s, Seu Muralha 19.0 s (vai aos pontos: é o perfil dele). **Nenhuma luta sai de 8–19 s, por construção** (4.4); o teste dos 10.000 confere.

### 13.6 Carreiras (30 por linha)
Até a 1ª luta, carreiras do mesmo jogador são idênticas (só a semente da luta muda), por isso "1ª vitória" tem um valor só.

| jogador | cliques/s | luta quando | 1ª vitória | termina em derrota | derrota (mediana; p10–p90) | derrota em 10–15 min | perdeu para | cinturão | cinturão em |
|---|---|---|---|---|---|---|---|---|---|
| saco | 3 | equilibrado | 4:01 | 77% | 16:14 (4:14–57:52) | 0% (50% aos 16:14, dentro da folga ±3) | Dinho 15, Muralha 5, Dudu 3 | 23% | 57:52 |
| **saco** | **4** | **equilibrado** | **3:31** | 70% | 14:14 (14:14–51:20) | **40%** | Dinho 12, Muralha 8, Dudu 1 | 30% | 51:21 |
| **saco** | **5** | **equilibrado** | **3:00** | 67% | 12:44 (12:44–48:53) | **37%** | Dinho 11, Muralha 8, Dudu 1 | 33% | 48:52 |
| saco | 8 | equilibrado | 2:00 | 77% | 9:14 (2:13–37:21) | 0% (50% aos 9:14, dentro da folga ±3) | Dinho 15, Muralha 5, Dudu 3 | 23% | 37:20 |
| saco, impaciente 5 min | 3 | equilibrado | 4:01 | **100%** | 9:44 | 0% (90% aos 9:44) | Brutão 27, Dudu 3 | 0% | — |
| saco, impaciente 5 min | 4 | equilibrado | 3:31 | **100%** | 9:14 | 0% (97% aos 9:14) | Brutão 29, Dudu 1 | 0% | — |
| saco, impaciente 5 min | 5 | equilibrado | 3:00 | **100%** | 8:44 (8:44–12:44) | 7% | Brutão 26, Dinho 2, Muralha 1, Dudu 1 | 0% | — |
| saco, impaciente 5 min | 8 | equilibrado | 2:00 | **100%** | 9:14 (9:14–14:44) | 40% | Dinho 15, Muralha 12, Dudu 3 | 0% | — |
| corda | 5 | equilibrado | 3:00 | 97% | 3:21 | 0% | Dudu 19, Brutão 9 | 3% | 46:00 |
| esteira | 5 | equilibrado | 3:00 | 63% | 12:55 | 40% | Dinho 12, Muralha 7 | 37% | 46:00 |
| rodízio | 5 | equilibrado | 2:30 | 87% | 2:49 (2:44–30:57) | 3% | Dudu 14, Brutão 7, Muralha 4 | 13% | 30:57 |
| rodízio | 5 | fácil | 3:00 | 23% | 34:57 | 0% | Muralha 6, Brutão 1 | **77%** | 34:58 |
| **bom** | 3 | fácil | 3:31 | 37% | 40:28 | — | Muralha 7, Brutão 2, Dudu 2 | **63%** | **40:29** |
| **bom** | 4 | fácil | 3:00 | 30% | 36:28 | — | Muralha 7, Brutão 1, Dudu 1 | **70%** | **36:28** |
| **bom** | 5 | fácil | 3:00 | 30% | 33:58 | — | Muralha 7, Brutão 1, Dinho 1 | **70%** | **33:58** |
| **bom** | 8 | fácil | 2:30 | 37% | 26:26 | — | Muralha 6, Dinho 2, Brutão 1, Dudu 2 | **63%** | **26:26** |
| bom | 5 | equilibrado | 2:30 | 87% | 7:14 | 17% | Brutão 9, Dudu 6, Muralha 6, Dinho 5 | 13% | 30:27 |

Curvas (uma semente):
| min | saco 5/s: treino total | saco 5/s: clique/s · passivo/s | bom 5/s: treino total (F / A / R) | bom 5/s: clique/s · passivo/s |
|---|---|---|---|---|
| 1 | 498 | 18 · 2 | 449 (209 / 240 / 0) | 11 · 2 |
| 3 | 3.42K | 18 · 7 | 2.80K (821 / 954 / 1.02K) | 18 · 9 |
| 5 | 13.0K | 90 · 51 | 8.41K (3.29K / 2.51K / 2.59K) | 40 · 34 |
| 10 | 66.7K | 180 · 105 | 54.3K (18.1K / 15.4K / 20.8K) | 180 · 87 |
| 15 | 154K | 180 · 132 | 138K (43.8K / 48.0K / 46.9K) | 180 · 131 |
| 20 | 252K | 180 · 158 | 234K (82.0K / 77.1K / 75.7K) | 180 · 150 |
| 30 | 461K | 180 · 177 | 441K (143K / 159K / 137K) | 180 · 177 |

- **Saco 5/s:** fita 0:53, **vence Dudu aos 3:00 (fácil)**, Prof. Nelson 3:13, areia 4:07, vence Brutão 9:01 (fácil, 52.5K de Força), luva de lona 9:14, **Dinho aos 12:31 com prévia 51% (equilibrado)**: metade das carreiras acaba aí. Quem passa fica com o Seu Muralha em "perigoso" até ~48 min.
- **Bom 5/s:** vence Dudu 3:00, Brutão 8:31, Dinho 12:01 (todos fáceis), **cinturão aos 33:34** com 177K / 159K / 181K e agressivo.
- O clique continua importante: aos 30 min ainda é ~50% da renda (180/s de clique contra 177/s de passivo); a luva de lona dobra o clique aos ~9 min, que é exatamente quando a garagem da Fase 2 "acabava" (R3).
- O dinheiro sobra no fim ($430 parados esperando o couro de $500 no saco 5/s): a decisão "luva ou treinador" acontece de verdade só com o prêmio do Brutão. Aceito; a Fase 5 traz mais loja.

### 13.7 Motivo da derrota (critério 14)
20 derrotas de estados variados (prévia de 20% a 90%). "Jogo" = regra da seção 7 com as 200 sementes fixas; "conferência" = mesma regra com 1.000 sementes novas. "Faltam" = quanto de Resistência / Força / Agilidade a mais deixaria a luta fácil.

| adversário | F / A / R | tática | prévia | decisivo (jogo) | decisivo (conferência) | faltam R / F / A (jogo) | faltam R / F / A (conferência) |
|---|---|---|---|---|---|---|---|
| Dinho | 11.4K / 16.0K / 42.8K | defensivo | 34% | Força | Força | 24.1K / 11.7K / 26.9K | 17.6K / 8.81K / 26.4K |
| Dudu | 739 / 228 / 718 | contra-ataque | 23% | Agilidade | Agilidade | 524 / 537 / 310 | 519 / 519 / 382 |
| Dinho | 53.2K / 4.79K / 32.3K | contra-ataque | 86% | Força | Resistência | 1.67K / 1.23K / 1.94K | 2.82K / 2.82K / 4.23K |
| Brutão | 33.4K / 3.44K / 92 | defensivo | 24% | Resistência | Resistência | 1.40K / 13.9K / 13.5K | 1.73K / 14.4K / 14.4K |
| Dinho | 27.0K / 53.8K / 18.0K | agressivo | 66% | Força | Força | 9.76K / 5.22K / 23.2K | 9.28K / 6.18K / 23.2K |
| Dinho | 55.2K / 10.6K / 5.88K | defensivo | 21% | Resistência | Resistência | 15.2K / 58.6K / 54.7K | 13.4K / 58.3K / 53.8K |
| Dinho | 73.2K / 1.32K / 6.04K | agressivo | 34% | Resistência | Resistência | 22.0K / 128K / 55.5K | 21.4K / 123K / 54.2K |
| Dinho | 4.82K / 132K / 7.86K | agressivo | 42% | Força | Força | 8.21K / 7.07K / 35.2K | 9.06K / 6.79K / 29.4K |
| Dudu | 1.16K / 586 / 388 | defensivo | 55% | Resistência | Resistência | 189 / 413 / 629 | 206 / 379 / 792 |
| Brutão | 21.7K / 29.3K / 595 | agressivo | 65% | Resistência | Resistência | 1.46K / 7.73K / 15.9K | 1.61K / 8.08K / 16.1K |
| Brutão | 2.84K / 61.5K / 1.38K | agressivo | 66% | Resistência | Resistência | 5.53K / 7.33K / 42.2K | 6.17K / 7.20K / 40.1K |
| Seu Muralha | 66.5K / 201K / 208K | contra-ataque | 39% | Força | Força | 113K / 66.1K / 123K | 119K / 74.5K / 141K |
| Brutão | 4.65K / 19.7K / 7.91K | agressivo | 34% | Resistência | Resistência | 7.74K / 9.16K / 30.4K | 7.58K / 9.60K / 26.7K |
| Brutão | 13.0K / 8.18K / 2.96K | contra-ataque | 42% | Resistência | Resistência | 7.40K / 11.7K / 12.3K | 6.43K / 11.3K / 10.2K |
| Dinho | 47.7K / 35.9K / 17.3K | agressivo | 78% | Resistência | Resistência | 5.22K / 16.6K / 8.67K | 6.31K / 15.7K / 14.1K |
| Seu Muralha | 271K / 3.65K / 260K | defensivo | 60% | Agilidade | Agilidade | 61.7K / 61.7K / 30.3K | 58.5K / 58.5K / 41.8K |
| Dinho | 67.4K / 869 / 4.19K | defensivo | 34% | Resistência | Resistência | 14.4K / 55.5K / 42.1K | 13.6K / 57.8K / 48.7K |
| Dudu | 107 / 539 / 1.08K | contra-ataque | 20% | Força | Força | 789 / 345 / 726 | 870 / 365 / 701 |
| Dudu | 442 / 1.00K / 764 | agressivo | 65% | Força | Força | 306 / 249 / 1.04K | 320 / 249 / 924 |
| Dinho | 15.7K / 3.29K / 52.0K | defensivo | 66% | Força | Força | 13.2K / 6.66K / 15.7K | 12.2K / 6.66K / 11.1K |

**Concordância: 19 de 20.** O caso que difere é um quase-empate (prévia 86%: qualquer atributo resolve com ~1–3% do treino). Nesses casos qualquer um dos dois é verdade, e a frase continua certa sobre o número.
Para o só-saco típico, o motivo contra o Dinho é **Resistência** ("faltaram ~11K de Resistência", dica esteira); contra o Seu Muralha é **Resistência ou Agilidade** conforme o estado (~27–42K; o QA viu "faltaram 29,5K de Agilidade"). Ver 16.8.

### 13.8 Critério 24 (2ª carreira seguindo a dica)
Jogador típico (5/s). Na 2ª carreira alterna saco e o aparelho da dica a cada 60 s, luta em "equilibrado" com os outros e **só enfrenta quem o derrotou quando estiver fácil**.

| 1ª carreira perdeu para | dica | 2ª carreira venceu esse adversário | quando (mediana) |
|---|---|---|---|
| Dudu | Resistência | 1 de 1 | 3:00 |
| Brutão | Resistência | 1 de 1 | 8:31 |
| **Dinho** (o caso típico) | Resistência | **4 de 5** | **11:31** (antes: perdeu aos 12:44) |
| Seu Muralha | Resistência | 5 de 17 | 36:04 |

Contra o Dinho (onde a 1ª carreira típica acaba) a dica funciona: vence mais cedo do que tinha perdido. Contra o Seu Muralha não basta seguir a dica sozinha: com só Força + Resistência, o "fácil" contra ele chega só com ~580K (~41 min), e quem luta em equilibrado pelo caminho perde antes. Quem chega ao Seu Muralha com só Força aprende na tela de fim "Resistência", mas o jogo bom pede os 3.

### 13.9 Metas: o que fecha e o que não fecha (honesto)
| Meta | Resultado | Situação |
|---|---|---|
| 1ª vitória 2–5 min (4–5 cliques/s, fácil ou equilibrado) | 3:00–3:31 para quem treina saco, esteira ou os 3 | **fecha**, com a exceção (1) |
| 1ª carreira termina em derrota em 10–15 min (típico) | 37–40% acabam no Dinho aos 12:44–14:14; o resto fica preso no Seu Muralha | **fecha pela metade** (2) |
| Cinturão sem árvore em 25–40 min só com jogo bom | bom 4–5/s: 34–36 min (70%); 3/s: 40:29; 8/s: 26:26 | **fecha** (3/s no limite) |
| O típico não chega ao cinturão na 1ª carreira | nenhum típico antes de 48 min; 33% entre 48 e 51 min se esperar parado | **fecha dentro da meta de tempo** (3) |
| Nenhum foco único vence a escada com a mesma eficiência | 1.6–1.9x mais treino para o mesmo fácil | **fecha** |
| Cada tática é a melhor contra ≥ 1 | contra-ataque 2, defensivo 1, agressivo 1 | **fecha** (5) |
| Risco honesto | 99.8 / 69.4 / 1.4%; na beira 91.7 / 41–85 / 40.7% | **fecha** |
| Duração 8–20 s | 8.0–19.0 s sempre | **fecha** |
| 1º item da loja com ≤ 2 vitórias | Nelson com 1, lona com 2 | **fecha** |
| Motivo aponta o atributo decisivo (10 de 10) | 19 de 20 na conferência; o erro é um quase-empate | **fecha na prática** (o QA deve escolher derrotas com prévia < 85%) |
| 2ª carreira, seguindo a dica, vence quem derrotou | Dinho 4 de 5 (11:31); Seu Muralha 5 de 17 | **fecha no caso típico (Dinho)**, não no Seu Muralha |

1. **Quem luta em "equilibrado" treinando muita Agilidade cedo** (corda, rodízio) perde o Dudu ~50% das vezes aos 2:30–3:20. A prévia foi honesta (40–45%), mas é a 1ª luta. Contra o Dudu a Agilidade sozinha rende pouco (só dá crítico). Mitigação sem número: o UI/UX destaca o amarelo na 1ª prévia ("PODE PERDER"). Se o QA achar ruim, a alavanca é a Agilidade do Dudu (100 → 0) ou o `crit_gain`.
2. **"Luta quando diz equilibrado" quer dizer ~50% de chance na primeira vez.** Para o só-saco, Dudu e Brutão pulam de perigoso para fácil quase de uma vez (ele quase não perde ali) e o Dinho é o portão. Quem passa do Dinho (~60%) não tem mais luta "equilibrada" só com Força até ~48 min. Na prática, um jogador parado 20+ min troca de foco (a prévia diz "ELE AGUENTA MUITO MAIS") ou luta no perigoso. O modelo **impaciente** (luta depois de 5 min sem opção) termina em derrota em **100%** das carreiras, mediana **8:44–9:44** (no Brutão, perigoso). Ou seja: quase todo típico termina entre ~9 e ~15 min, mas não 80% dentro de 10–15. Não achei números que façam as duas coisas (típico perde em 10–15 e o bom ganha em 25–40) sem mentir no risco ou sem dar vantagem ao foco único. Fica para o QA jogando e para o dono.
3. Se o típico esperar 48+ min sem trocar de foco, ganha o cinturão 1 em 3 vezes. Aceito (R6: não punir quem espera). Ele leva ~1.4x o tempo do bom.
4. 8 cliques/s: cinturão aos 26 min e Dinho aos ~9 min. Como na Fase 2: quem clica muito é premiado.
5. As margens das táticas no perfil equilibrado são pequenas em treino (4–10%), mas grandes em chance no limiar (Dinho: 67% defensivo × 36% contra-ataque). Ótimo para o critério 2, discreto para o 10.
6. O simulador clica sem parar e olha a prévia a cada 30 s. Gente de verdade é mais lenta: os tempos reais tendem a ser um pouco maiores.
7. Legado: números pequenos e provisórios, pensados para a Fase 4 dar preço aos nós.

## 14. Testes automáticos que este design pede
| Teste | Confere |
|---|---|
| Fórmulas | estado conhecido → vida, dano, redução, crítico, esquiva iguais aos da seção 4.1 (ex.: jogador 0/0/0 → vida 100; Dudu efetivo 1.41K / 310 / 1.01K, vida 5.15K) |
| Determinismo | mesma semente + mesmo estado → mesma lista de eventos, golpe a golpe (critério 6) |
| Limite | 10.000 lutas de estados variados: `8 ≤ tela ≤ 19` e nenhum evento depois de 16 s |
| Grogue | K.O. antes de 5 s → `t_end = 5.0`, mesmo vencedor |
| Pontos e empate | % de vida igual no tempo → vence o adversário |
| Risco | 500 lutas por rótulo (estados variados, sementes novas): fácil ≥ 85%, equilibrado 40–85%, perigoso < 40% |
| Tática muda o rótulo | equilibrado 1/3 com 25.3K contra o Brutão: contra-ataque EQUILIBRADO, defensivo PERIGOSO |
| Prêmio | só na vitória: `money`, `fame`, `ladder_index` sobem com os valores do JSON; derrota não dá dinheiro |
| Legado | tabela 8.2 inteira; derrota = floor(50%); aposentar = 100% (+50% com cinturão); aposentar > perder para pote ≥ 1 e ≥ sempre |
| Fim de carreira | derrota zera `career`, mantém `permanent`; NOVA CARREIRA soma 1 em `career_number` |
| Fechar no meio | `fight` salvo → recarregar aplica o mesmo resultado uma vez só; `ending` salvo → Legado não duplica |
| Loja | Nelson custa 50, 80, 128...; compra desconta dinheiro e recusa sem saldo; não mexe em Treino/atributo; luva x2 nos 3 aparelhos |
| Migração | save v2 → v3: carreira igual, `career_number` 1, Legado 0; v0 → v3 em cadeia |
| Dados | mudar `prize_money` ou um atributo de adversário num JSON de teste muda o jogo; campo inválido usa padrão com aviso |
| Motivo | casos da tabela 13.7 → mesmo atributo decisivo (o "faltaram" pode diferir alguns % por causa do gerador do Godot); 10 derrotas do QA conferidas com 1.000 sementes |
| Guarda do save real | continua passando (um arquivo só) |

## 15. Ids novos (contrato)
Adversários `opp_warmup`, `opp_strong`, `opp_fast`, `opp_tank`; táticas `aggressive`, `defensive`, `counter`; gerador pago `gen_paid_1`; linha de luvas `glove_shop` com `glove_l1`, `glove_l2` (`glove_l3` reservado para a Fase 5; `glove_old` = nível 0).
Arquivos novos: `data/fights.json`, `data/opponents.json`, `data/shop.json`, `data/career.json`. Campos de save novos: seção 12.1.
Pedidos ao Roteirista: `time_rule_tie` ("EMPATE EXATO: FICA COM ELE"), um "FALTARAM {n} DE AGILIDADE ..." para `reason_agility`, dica do defensivo citando o crítico.
Pedido ao UI/UX: ações de luta conforme 4.7 (jab, heavy no crítico e no contra-golpe, block no defensivo, tired no grogue); destaque do amarelo na 1ª prévia.

## 16. Correções pós-QA (B2, B3, B4) e estado das metas 22–24

Origem: `fase3-qa.md` §5 (B2, B3, B4) e §4 (critérios 22–24). Esta seção **substitui** as partes da seção 7 que conflitarem com ela. Nada em `data/` ou `scripts/` foi alterado pelo Designer: o Programador implementa, o Roteirista escreve os textos novos.

### 16.1 Ordem de decisão do motivo (nova)
Calculado como antes (derrota, mesma estimativa de 200 sementes fixas, tática usada). Novo campo `reason.kind` no motivo salvo.
```
p = chance(jog, adv, tática usada)            (já calculada hoje em _calcular_motivo como "usada")
1) se p ≥ reason.luck_min (0.90)              → kind = "luck"     (B3; não roda a busca do "faltaram")
2) senão, busca do faltaram com o teto novo   → kind = "missing"  (B2; caso normal)
3) se nenhum atributo resolve nem no teto     → kind = "far" ou "far_plain" (segurança; não ocorreu na simulação)
```
A 2ª linha (estatística) passa a ser escolhida pela regra de validade de 16.4 em **todos** os casos; ela nunca mais vira a linha principal.

### 16.2 B2: "FALTARAM" sempre que possível
Teto da busca binária de `falta(X)` (seção 7):
```
T     = soma dos atributos crus do jogador
T_adv = soma dos atributos crus do adversário
hi    = max(search_max_share × T + 1000,  search_opp_share × T_adv)       search_max_share = 16, search_opp_share = 4
```
- Por quê 4 × T_adv: partindo de zero, o foco único mais caro precisa de 1,4× a 2,3× o total do adversário para o "fácil" (tabela 13.2: só Agilidade contra o Seu Muralha = 1,46M para T_adv 626K). 4× cobre todos com folga.
- Mesmos 14 passos (o custo não muda; a precisão fica em hi / 16.384, menos que o arredondamento `teto3` na prática).
- "FALTARAM 47.5K DE RESISTÊNCIA" com T = 500 é honesto e informativo: o jogador vê que lutou cedo demais. Não precisa de frase extra.
- **Fallback** (só se nem o teto novo resolve; não aconteceu em 239 derrotas simuladas):
  - `razão = T_adv / max(1, T)`; se `razão ≥ reason.far_min_ratio` (2.0): `reason_far` com `{n}` = `floor(razão)` (ex.: "ELE TINHA 12X O SEU TREINO").
  - senão: `reason_far_plain` (sem número).
  - O atributo da dica continua sendo escolhido pela regra do Δ da seção 7.

### 16.3 B3: derrota por azar numa luta FÁCIL
- Regra: `p ≥ reason.luck_min` (0.90, o mesmo limiar do rótulo FÁCIL da tática usada). Com isso, toda derrota em luta que a prévia chamou de FÁCIL é azar, e nenhuma outra é (a prévia chamou de FÁCIL exatamente quando `p ≥ 0.90`).
- Por quê não "faltaram pequeno": com `p ≥ 0.90` o "faltaram" é sempre ~0 por definição (a luta já era fácil); o "3 de Resistência" do QA era só o resíduo da busca. Em EQUILIBRADO (40–89%) o "faltaram" é verdadeiro (ex.: prévia 86%, "faltaram 1.23K de Força" deixaria a luta fácil), então continua.
- Texto: linha principal `reason_luck` (lista; variação = `seed % tamanho`). Estatística de 16.4 com a ordem de azar. Dica: `tip_luck` (lista; variação = `seed % 3`), **nunca** `tip_<atributo>`. `tip_tactic` não aparece (impossível com `p ≥ 0.90`, mas o código deve forçar vazio).
- Campos salvos: `kind = "luck"`, `attribute = ""`, `faltaram = -1`. A busca do faltaram não roda (economiza as ~9.000 lutas; ajuda o B5).

### 16.4 B4: quando cada estatística vale
Cada modelo só é usado se passar no teste. Senão tenta o próximo da ordem.

| kind | fórmula (registro da luta) | válido se | texto |
|---|---|---|---|
| `life_taken` | `n = round(100 × min(dano dele, sua vida máx) / sua vida máx)`, `k` = acertos dele | `n ≥ stat_life_min_pct` (10) | `reason_endurance[2]` (já existe) |
| `stronger` | `r = (dano médio por acerto dele / sua vida máx) ÷ (seu dano médio por acerto / vida máx dele)`; sem acertos: o golpe calculado (como hoje); `n = round(100 × (r − 1))` | `stat_stronger_min_ratio (1.2) ≤ r < stat_stronger_x_ratio (2.0)` → n de 20 a 99 | `reason_strength[2]` (já existe) |
| `stronger_x` | `n = floor(r)` | `2.0 ≤ r < stat_stronger_cap_ratio (10)` → n de 2 a 9 | `stat_stronger_x` (novo) |
| `stronger_cap` | `n = stat_stronger_cap_ratio` (10) | `r ≥ 10` | `stat_stronger_cap` (novo) |
| `crits` | `n` = críticos dele, `k` = seus | `n ≥ stat_crits_min (2)` e `n > k` | `reason_agility[3]` (já existe) |
| `dodged` | `a` = seus ataques normais (sem contra-golpe); `n = round(100 × esquivas dele / a)` | `a ≥ stat_dodge_min_attacks (3)` e `n ≥ stat_dodge_min_pct (20)` | `reason_agility[2]` (já existe) |
| `points` | `n` = % da sua vida no gongo, `k` = % da dele | sempre (só em derrota por pontos) | `stat_points` (novo) |
| `luck_odds` | `n = round(100 × (1 − p))` | `n ≥ 1` (só no azar) | `stat_luck_odds` (novo) |
| `luck_rare` | — | `n < 1` (só no azar) | `stat_luck_rare` (novo) |

Ordem por motivo (a 1ª válida ganha):
| motivo | ordem | último recurso (sempre válido) |
|---|---|---|
| Resistência | life_taken, stronger*, crits, dodged | K.O.: `life_taken` (é sempre 100%); pontos: `points` |
| Força | stronger*, life_taken, crits, dodged | idem |
| Agilidade | crits, dodged, life_taken, stronger* | idem |
| Azar | crits, dodged | `luck_odds` / `luck_rare` |

`stronger*` = a faixa de `r` decide entre `stronger`, `stronger_x` e `stronger_cap`; com `r < 1.2` não vale e passa para o próximo.
- Isso elimina "BATIA 0% MAIS FORTE" (r < 1.2 é pulado) e "20982% MAIS FORTE" (r ≥ 2 vira "VALIA 2..9 DOS SEUS"; r ≥ 10 vira "MAIS DE 10").
- "ESQUIVOU 0%" também some (mínimo 20%, com pelo menos 3 ataques).
- `stat` salvo: `{kind, n, k}` com os kinds novos. `textos_fim` monta o texto por `kind`.
- Save antigo (fim salvo antes da correção com `stronger` e `n < 20` ou `n ≥ 100`): `textos_fim` mostra a estatística vazia. Não precisa recalcular.

### 16.5 Parâmetros novos em `data/fights.json` → `reason`
| campo | valor | uso |
|---|---|---|
| `search_opp_share` | 4.0 | B2: teto da busca ≥ 4 × T_adv |
| `luck_min` | 0.90 | B3: chance da tática usada ≥ isto → azar (manter = `risk.easy_min`) |
| `far_min_ratio` | 2.0 | B2 fallback: mostra "{n}X O SEU TREINO" só se a razão ≥ 2 |
| `stat_life_min_pct` | 10 | B4 |
| `stat_stronger_min_ratio` | 1.2 | B4 |
| `stat_stronger_x_ratio` | 2.0 | B4 |
| `stat_stronger_cap_ratio` | 10.0 | B4 (também é o `{n}` do `stat_stronger_cap`) |
| `stat_dodge_min_pct` | 20 | B4 |
| `stat_dodge_min_attacks` | 3 | B4 |
| `stat_crits_min` | 2 | B4 (hoje fixo no código como `>= 2`) |

Campos que ficam: `delta_share`, `delta_min`, `target`, `search_steps`, `search_max_share`, `tactic_tip_gap`, `lead_ratio`. Campo ausente usa o valor da tabela com aviso (padrão da seção 11).

### 16.6 Textos novos (`data/ui_texts.json`, pedido ao Roteirista)
Tom e caixa iguais às chaves `reason_*` / `tip_*` atuais. Os textos entre aspas são rascunho do Designer.
| chave | tipo | placeholders | rascunho / intenção |
|---|---|---|---|
| `reason_luck` | lista (2–3) | — | "ERA PRA SER SUA. DEU AZAR." Honesto: a prévia dizia fácil e o treino estava certo |
| `tip_luck` | lista (3) | — | Não culpa atributo nem treino. Ex.: "O TREINO ESTAVA CERTO. REPITA O CAMINHO" |
| `stat_stronger_x` | texto | `{n}` (2–9) | "CADA SOCO DELE VALIA {n} DOS SEUS" |
| `stat_stronger_cap` | texto | `{n}` (= 10) | "CADA SOCO DELE VALIA MAIS DE {n} DOS SEUS" |
| `stat_points` | texto | `{n}`, `{k}` (%) | "NO GONGO: VOCÊ COM {n}% DA VIDA, ELE COM {k}%" |
| `stat_luck_odds` | texto | `{n}` (1–10) | "ISSO ACONTECE EM {n} DE CADA 100 LUTAS" (singular: `{n}` = 1 lê bem como está) |
| `stat_luck_rare` | texto | — | "ISSO QUASE NUNCA ACONTECE" |
| `reason_far` | texto | `{n}` (≥ 2) | "ELE TINHA {n}X O SEU TREINO" (segurança, quase nunca aparece) |
| `reason_far_plain` | texto | — | "TREINE MUITO MAIS ANTES DE ENCARAR ELE" |

Chaves existentes sem mudança de sentido: `reason_strength[2]` passa a valer só para 20–99%; `reason_agility[2]` só para ≥ 20%.

### 16.7 Validação no simulador
`tools/sim/fase3_sim.py explica` (funções `falta_para_v2`, `stat_valida`, `explicar`; parâmetros em `PADRAO_POS_QA` quando o JSON ainda não tiver). Derrotas reais: carreiras de 8 perfis × 12 sementes (saco, saco impaciente 4/s e 8/s, corda, esteira, rodízio, bom em fácil e em equilibrado), lutas "cedo demais" (T de 50 a 8K, só Força / só Agilidade / 1/3, os 4 adversários), 60 estados variados e 40 derrotas com prévia alta.

| resultado (239 derrotas) | valor |
|---|---|
| motivo `missing` (FALTARAM) | 197 |
| motivo `luck` | 42 (todas com p ≥ 0.90; nenhuma luta com p ≥ 0.90 ficou sem `luck`) |
| motivo `far` / `far_plain` | **0** |
| FALTARAM que a regra antiga (16 × T + 1000) não achava | **48** (B2 resolvido) |
| estatística 0%, fora da faixa ou absurda | **0** |
| estatísticas usadas | life_taken 164, stronger_cap 22, luck_odds 16, dodged 13, crits 11, stronger_x 9, luck_rare 4 |

Exemplos: "FALTARAM 10.6K DE RESISTÊNCIA / ELE TIROU 100% DA SUA VIDA EM 3 GOLPES" (saco 5/s, prévia 54%); "FALTARAM 1.93K DE FORÇA / CADA SOCO DELE VALIA MAIS DE 10 DOS SEUS" (cedo demais, prévia 0%); "ERA PRA SER SUA. DEU AZAR. / ISSO ACONTECE EM 9 DE CADA 100 LUTAS" (prévia 91%); "ERA PRA SER SUA. DEU AZAR. / ELE ACERTOU 2 CRÍTICOS. VOCÊ, 0" (prévia 100%).
Nota: em carreira, 3 de 68 derrotas foram azar (o bot luta com a prévia de 100 sementes; na de 200 deu ≥ 90%).

Testes automáticos que isto pede (adicionar à seção 14):
| teste | confere |
|---|---|
| Azar | estado com p ≥ 0.90 e semente que perde → `kind = "luck"`, dica de `tip_luck`, sem `tip_tactic` |
| Teto novo | só Força com T = 500 contra o Brutão → `kind = "missing"` com faltaram > 16 × T + 1000 |
| Estatística | casos do QA (Dinho com prévia 56% decisivo Força; Brutão T = 8.6K só Agilidade) → nunca `stronger` com n < 20 ou ≥ 100; `stronger_cap` com n = 10 |
| Último recurso | K.O. → sempre há estatística; derrota por pontos sem outra válida → `points` |

### 16.8 Metas de tempo: estado dos critérios 22–24 (para o Diretor e o dono)
Nenhum número foi mudado. Estado medido pelo QA (simulador + partidas):

| critério | estado | o que fecha | o que não fecha |
|---|---|---|---|
| 22. 1ª carreira típica termina em derrota em 10–15 min | **PARCIAL** | medianas 12:44 (5/s), 14:14 (4/s); 3/s e 8/s dentro da folga ±3 min | só 37–40% das carreiras "saco" acabam em 10–15 min; 25–33% atravessam a escada (cinturão aos 37–58 min); o impaciente perde aos ~9 min; QA jogando: 63,7 min |
| 23. Cinturão em 25–40 min só com jogo bom; típico não chega na 1ª | **PARCIAL** | jogo bom: 26:26 (8/s) a 40:29 (3/s) | o típico que espera parado ganha o cinturão em 20–33% das carreiras (37–58 min) |
| 24. 2ª carreira seguindo a dica vence quem derrotou | **PARCIAL** | Dinho 4 de 5 (o caso típico), Brutão e Dudu 1 de 1 | Seu Muralha 5 de 17; QA jogando: 0 de 2 (lutou em "equilibrado") |

Observação do QA: contra o Seu Muralha a dica do só-saco saiu "Agilidade", não "Resistência" como dizia 13.7. As duas são verdade conforme o estado; o texto da 13.7 fica corrigido para "Resistência ou Agilidade".

Alavancas (todas em `data/`, sem código). Efeito esperado, a confirmar no simulador antes de mudar:
| alavanca | arquivo / campo | efeito em 22 | em 23 | em 24 |
|---|---|---|---|---|
| Resistência do Seu Muralha (490K) | `opponents.json` `opp_tank.endurance` | subir (ex. 600K) tira o "cinturão por espera" do típico; descer encurta a espera | subir empurra o jogo bom para perto de 40 min (3/s passa do limite) | subir piora o 5 de 17 |
| Agilidade do Seu Muralha (58K) | `opp_tank.agility` | subir pune quem chega só com Força + Resistência (o "saco" que esperou) | afeta menos o jogo bom (que tem os 3) | piora seguir a dica só de Resistência |
| Dinho (20K / 110K / 6K) | `opp_fast.*` | é o portão do típico: subir a Agilidade faz mais "saco" perder aos 12–15 min (sobe a % em 10–15) | pouco efeito no bom (Dinho fácil aos ~12 min) | contra o Dinho seguir a dica já funciona; não mexer muito |
| Limiar do "equilibrado" (0.40) | `fights.json` `risk.even_min` | **não mexer para isso**: muda o rótulo honesto (critério 3) | — | — |
| Prêmio do Dinho ($400) e preço da luva de couro ($500) | `opponents.json` `opp_fast.prize_money`, `shop.json` `glove_l2.cost` | couro mais caro = típico mais lento antes do Muralha (mais tempo preso, menos cinturão) | o bom também perde ~1–3 min | neutro |
| Produção do Prof. Nelson (25/s, x1.6) | `shop.json` `gen_paid_1.production`, `growth` | menos passivo = mais tempo até o Muralha | idem para o bom | neutro |

Recomendação do Designer: se o dono quiser fechar 22/23 juntos, começar só pelo Seu Muralha (`endurance` 490K → 560–600K, `agility` 58K → 70K) e rodar `fase3_sim.py carreiras dica`. Se o jogo bom 3/s passar de 40 min, aceitar (folga) ou devolver 20K de Resistência. A decisão é do Diretor/dono; nada foi alterado.

## Resumo
- **Correções pós-QA (seção 16):** derrota com prévia FÁCIL (p ≥ 0.90) vira "ERA PRA SER SUA. DEU AZAR." com dica que não culpa atributo; teto da busca do "faltaram" vira `max(16 × T + 1000, 4 × total do adversário)`, e o "FALTARAM" aparece em todas as 197 derrotas não-azar simuladas (48 que antes não tinham); estatística só com faixas válidas (`stronger` 20–99%, "VALIA {n} DOS SEUS" de 2 a 9, "MAIS DE 10", esquiva ≥ 20%, vida ≥ 10%) e fallback que sempre existe. 10 campos novos em `fights.json` `reason`, 9 chaves de texto novas. Critérios 22–24 seguem PARCIAL; alavancas em 16.8.
- **Luta:** atributo de luta = cru + 10% do treino total. Vida `100 + 5×R`, dano `10 + F`, redução `50% × R/(R+F)`. Agilidade só conta quando é maior que a dele (crítico 5–55% x2, esquiva 3–75%). Cada lado ataca a cada 1.8 s, limite 16 s, pontos por % de vida (empate fica com ele). K.O. antes de 5 s vira "grogue", então toda luta tem 8–19 s de tela. Resultado decidido e salvo ao apertar LUTAR.
- **Táticas:** agressivo (+35% de dano, fura 50% da defesa, apanha +25%) contra o Seu Muralha; defensivo (−15%/−15%, anula o crítico dele) contra o Dinho; contra-ataque (esquiva x2, devolve golpe certeiro) contra Dudu e Brutão.
- **Escada:** Dudu 1.2K/100/800 ($50, 10 de fama), Brutão 27K/1.4K/5.4K ($150, 30), Dinho 20K/110K/6K ($400, 60), Seu Muralha 78K/58K/490K ($1.000, 100, cinturão).
- **Risco:** 200 lutas com sementes fixas; fácil ≥ 90%, perigoso < 40%. Medido: 99.8% / 69.4% / 1.4%.
- **Legado:** pote = fama × 0.2 (+10 com cinturão). Derrota 50%, aposentadoria 100% (+50% com cinturão). Carreira típica perde levando 1 a 10; cinturão + aposentadoria = 75.
- **Loja:** Prof. Nelson $50 (x1.6, +25 Treino/s); luva de lona $120 (x2 no clique), de couro $500 (x2). Garagem sem mudança de preço.
- **Metas:** 1ª vitória aos 3:00–3:31; jogo bom ganha o cinturão em 34–36 min (3/s: 40 min; 8/s: 26 min); risco e duração fecham. **Não fecha inteiro:** o típico que só luta em "equilibrado" perde em 10–15 min em ~40% das carreiras (o resto fica preso no Seu Muralha; o impaciente perde aos ~9 min). Quem treina muita Agilidade e luta em equilibrado perde o Dudu ~50% das vezes.
