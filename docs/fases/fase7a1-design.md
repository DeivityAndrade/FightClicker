# Fase 7a1 — Cada arte luta do seu jeito: design

Designer de Jogo, 2026-11-19. Base: `fase7a-escopo.md` (§3, §7 e **§8, decisões do dono**, que valem sobre o resto).
Simulador: `tools/sim/fase7a1_sim.py` (referência do motor; roda em cima do `fase6c2_sim.py`, a campanha de hoje).
Dados já gravados: `data/arts.json` (bloco novo `passive`), `data/moves.json` (estilos `bjj` e `ground_bottom`),
`data/locations.json` (`fight_arena`). O que só pode mudar junto com o código está na §15.2.

## 0. A ideia em uma frase por arte
| | **Boxe — Mão rápida** | **Jiu-jitsu — Finalização** | **Sem arte** |
|---|---|---|---|
| Jeito de ganhar | **na frente e cedo**: cada acerto seguido aumenta o **embalo**; com ele abaixo da metade da vida *e* mais machucado que você, cada acerto pode ser **K.O.** | **aguentar e fechar**: a **pegada** enche com o tempo; cheia, e com ele abaixo de 60% da vida, cada acerto pode **finalizar**, mesmo perdendo nos pontos | igual a hoje |
| Ritmo | 25% mais golpes nos rounds 1 e 2 (até 56% mais com AGILIDADE alta), cada um 12% mais fraco; **cansa no 3º** | 20% menos golpes, cada um 20% mais forte | igual |
| Atributo que faz a passiva | **AGILIDADE** (velocidade dos socos e chance de K.O.) | **RESISTÊNCIA** (pegada) e **FORÇA** (fechar) | — |
| Tática que combina | **Agressivo** (K.O. ×1,5, mas ele contragolpeia quando você erra) | **Defensivo** (pegada ×1,5) | — |
| Contra quem brilha | adversário lento (Tonhão, Muralha, Brutão) | adversário fraco de FORÇA (Kid, Muralha, Tonhão) | — |

Boxe é a arte de **quem está ganhando** (acaba a luta antes do 3º round); Jiu-jitsu é a arte de **quem aguenta**
(vira luta difícil no fim). Essa é a diferença que o jogador sente e que o testador reconhece só olhando.

## 1. Regras gerais do motor (`scripts/luta.gd`)
1. **Sem arte = código de hoje, intocado.** O motor ganha `passiva: Dictionary` (vazio = sem arte) no lugar de `traco`.
   Com `passiva` vazia, `rodar()` segue o laço atual, com **3 sorteios por ataque**: a foto (`tools/refatoracao/foto.gd`)
   sai igual à da main até a escolha da arte. Com arte, `rodar()` chama um laço novo, `_rodar_arte()`.
2. **Com arte: 4 sorteios por ataque, de qualquer lado** (normal ou contragolpe), sempre nesta ordem:
   `r_esq, r_crit, r_var, r_arte`. `r_arte` só é usado no acerto do jogador (K.O. ou finalização); nos outros é sorteado e descartado.
3. A passiva entra em `preparar()` (números fixos da luta) e em `_rodar_arte()`. **Prévia, risco do HUD, robô de teste,
   motivo da derrota e a luta usam a mesma função** (`chance`, `passa`, `rodar`): a prévia continua honesta por construção.
4. Os traços de hoje (**Boxe +10% de dano**, **Jiu-jitsu −10% de dano recebido**) **saem**. Quem passa a valer é a passiva
   (§2, §3). O total de cada arte fica **igual ou um pouco mais fraco** que o traço (medido na §12.1).
5. Todos os números vêm de `data/arts.json → arts[].passive`. Nada é constante no código.

### 1.1 Números que a passiva lê (efetivos, como hoje)
`ef = efetivos(x)` (cru + 10% do total). Fatores de comparação, sempre `clamp(2·meu/(meu+dele), min, max)`
(1,0 = empate; 2,0 = ele não tem nada):

| Fator | Arte | Conta | min–max |
|---|---|---|---|
| `fa` (agilidade, no K.O.) | Boxe | `2·Agi_j / (Agi_j + Agi_a)` | 0,4–1,6 |
| `fs` (agilidade, na velocidade) | Boxe | a mesma conta | 0,80–1,25 |
| `fr` (resistência contra a força dele) | Jiu-jitsu | `2·Res_j / (Res_j + For_a)` | 0,5–2,0 |
| `ff` (força contra a força dele) | Jiu-jitsu | `2·For_j / (For_j + For_a)` | 0,25–2,0 |

`extra` = soma dos nós `art_fight_bonus` ativos da arte (Contragolpe / Base firme), §6.2.

### 1.2 Laço `_rodar_arte` (igual ao `RegrasArte._lutar_arte` do simulador)
```
P = passiva; tp = P.tactics[tática] (ou {}); est = estado_passiva(jog, adv, tática)
tj = tática do jogador com damage_mult × P.damage_mult e taken_mult × P.taken_mult
ta = NEUTRA; se Boxe: ta.counter_mult = tp.opponent_counter (0 se não houver)
num, vmax, primeiro, prox: como hoje (prox do 2º = first_attack + attack_interval/2)
iv_j = attack_interval × P.interval_mult;  se Boxe: iv_j /= clamp(fa_bruto, speed_agility_min, speed_agility_max)
iv_cansado = attack_interval × (tp.tired_interval_mult ou P.tired_interval_mult);  t_cansa = (tired_from_round−1) × round_length
embalo = 0
laço (mesma escolha de evento de hoje: menor tempo; contragolpe antes; jogador antes):
  se ataque normal do jogador: prox[0] += (iv_cansado se Boxe e t ≥ t_cansa − 1e-9, senão iv_j)
  se ataque normal do adversário: prox[1] += attack_interval
  sorteia r_esq, r_crit, r_var, r_arte (4, sempre)
  esquiva (só ataque normal): se quem = jogador e Boxe → embalo = 0; agenda contragolpe se tac[alvo].counter_mult > 0; continue
  dano como hoje (crítico, contragolpe, variação); aplica
  se a vida do alvo zerou → fim "damage" (K.O. por dano, como hoje)
  senão, se quem = jogador:
    Boxe: embalo = min(streak_max, embalo + (streak_per_counter se contragolpe, senão streak_per_hit))
          se vida_dele ≤ ko_life_max × vmax_dele e (need_ahead = 0 ou vida_dele% ≤ sua_vida%):
              tentativas += 1; se r_arte < embalo × est.ko_per_streak → fim "knockout"
    JJ:   se t ≥ est.grip_full_at − 1e-9 e vida_dele ≤ sub_life_max × vmax_dele e (need_ahead = 0 ou ...):
              tentativas += 1; se r_arte < est.sub_chance → fim "submission"
fim por passiva: ko = true, t_ko = t, t_end = max(t, min_ko_time), round = floor(t/round_length)+1, vence o jogador
fim no tempo: como hoje (pontos)
```

## 2. Boxe — "Mão rápida"
### 2.1 Fórmulas
| Regra | Fórmula | Valor |
|---|---|---|
| Dano por golpe | tática.damage_mult × `damage_mult` | ×0,88 |
| Intervalo do jogador (rounds 1–2) | `attack_interval × interval_mult / clamp(2·Agi_j/(Agi_j+Agi_a), speed_agility_min, speed_agility_max)` | 1,8 × 0,80 = **1,44 s** com agilidade igual; de **1,80 s** (ele bem mais ágil, fator 0,80) a **1,15 s** (você bem mais ágil, fator 1,25) |
| **Cansaço** a partir do round `tired_from_round` (t ≥ 2 × 5,333 = **10,67 s**) | `attack_interval × tired_interval_mult` | 1,8 × 1,10 = **1,98 s** (Defensivo: ×1,00 = 1,80 s) |
| **Embalo** | +`streak_per_hit` (1) por acerto seu (Contra-ataque: +2 no contragolpe); **zera** quando ele esquiva um ataque seu; teto `streak_max` | 0–5 |
| Chance de K.O. por golpe | `p = embalo × ko_por_embalo`, com `ko_por_embalo = min(ko_cap, 5 × 0,02 × fa × ko_mult_tática × (1+extra)) / 5` | embalo 5, fa 1,0: **10%**; Agressivo: **15%**; fa 1,6 + Agressivo: **24%** |
| Quando pode dar K.O. | depois de um acerto seu que não derrubou por dano, **se** vida dele ≤ `ko_life_max` (50%) **e** vida dele % ≤ sua vida % (`need_ahead = 1`) | — |
| K.O. | sorteio `r_arte < p` → fim por **nocaute** (vence o jogador) | — |

Ordem dentro do acerto do jogador: aplica o dano → se a vida dele zerou, é K.O. por dano (como hoje) → senão, soma o embalo →
testa o portão (50% e "na frente") → testa `r_arte`.

O adversário continua com o intervalo de hoje (1,8 s) e nunca usa a passiva (passiva de adversário é 8a).

### 2.2 Números por tática (Boxe)
| Tática | O que muda na passiva | Efeito na luta |
|---|---|---|
| **Agressivo** | K.O. ×1,5; **ele ganha contragolpe** (`opponent_counter` 0,8): toda vez que ele esquiva um ataque seu, responde 0,5 s depois com um golpe de 80% (mesma fila de contragolpe de hoje; é o `counter_mult` da tática **dele**) | acaba cedo, mas cada erro seu vira soco dele; contra adversário ágil (Dinho, Kid) é arriscado |
| **Defensivo** | K.O. ×0,75; **não cansa** (intervalo do 3º round 1,80 s) | luta longa e segura; ganha mais por pontos |
| **Contra-ataque** | contragolpe seu vale **+2** de embalo | esquivar e responder enche o embalo rápido |

## 3. Jiu-jitsu — "Finalização"
### 3.1 Fórmulas
| Regra | Fórmula | Valor |
|---|---|---|
| Dano por golpe | tática.damage_mult × `damage_mult` | ×1,20 |
| Intervalo do jogador | `attack_interval × interval_mult` | 1,8 × 1,25 = **2,25 s** |
| **Pegada** (0–100%) | enche linear com o tempo: `pegada(t) = min(1, t / t_cheia)` | — |
| Velocidade da pegada (por round) | `taxa = min(grip_rate_max, grip_per_round × fr × grip_mult_tática × (1+extra))` | 0,5 × fr × tática; teto **1,0/round** |
| Pegada cheia em | `t_cheia = round_length / taxa` | fr 1,0 e Contra-ataque: 10,67 s (fim do 2º round); Defensivo: 7,1 s; nunca antes de 5,33 s |
| Chance de finalizar por golpe | `p_fin = min(sub_cap, sub_base × ff)` | 0,30 × ff: ff 1,0 → **30%**; ff 1,5 → **45%**; teto 60% |
| Quando pode finalizar | acerto seu que não derrubou por dano, **se** `t ≥ t_cheia` **e** vida dele ≤ `sub_life_max` (60%). **Não precisa estar na frente** (`need_ahead = 0`) | — |
| Finalização | sorteio `r_arte < p_fin` → fim por **finalização** (vence o jogador) | — |

A pegada **não depende de sorte nem de dano**: é uma conta fixa do estado (atributos e tática). Por isso a prévia mostra o round
exato em que ela enche (§7). "Cada round sobrevivido enche a barra" vira: **cada round enche 50% × fr** (×1,5 no Defensivo).

### 3.2 Números por tática (Jiu-jitsu)
| Tática | Pegada | Efeito na luta |
|---|---|---|
| **Defensivo** | ×1,5 (com fr 1,0: cheia aos **7,1 s**, no 2º round) | guarda fechada, aguenta e chega à finalização mais cedo: a tática da arte |
| **Contra-ataque** | ×1,0 (cheia aos 10,7 s) | neutro |
| **Agressivo** | ×0,75 (cheia aos **14,2 s**, quase no gongo) | ganha por dano, quase não finaliza |

## 4. Os traços de hoje: trocados
| | Hoje | 7a1 |
|---|---|---|
| Boxe | +10% de dano | Mão rápida (dano ×0,88, ritmo pela AGILIDADE, embalo, K.O., cansaço) |
| Jiu-jitsu | −10% de dano recebido | Finalização (dano ×1,20, ritmo lento, pegada, finalização) |
| `arts[].fight` | lido pelo motor | **apagado** quando o código novo entrar (§15.2) |

Por que trocar e não somar: somando, as duas artes ficam mais fortes que hoje (o escopo proíbe). Trocando, o total fica igual
(Boxe) ou um pouco abaixo (Jiu-jitsu) no verde, e a diferença vira **jeito de lutar** (§12.1).

## 5. Táticas × arte (resumo para a tela e para o QA)
| Tática | Sem arte | Boxe | Jiu-jitsu |
|---|---|---|---|
| Agressivo | bate +35%, defende pior | **K.O. ×1,5**, mas **ele contragolpeia** quando esquiva | pegada ×0,75 (finaliza tarde ou nunca) |
| Defensivo | −15% dos dois lados, sem crítico dele | K.O. ×0,75, **não cansa** | **pegada ×1,5** |
| Contra-ataque | esquiva ×2 e responde | contragolpe dá **+2 de embalo** | neutro |

O que o robô da simulação escolheu (a tática de maior chance na prévia), lutas com arte, 200 jogadores × 10 campanhas:

| Perfil | Agressivo (uso; vitórias pela passiva) | Defensivo | Contra-ataque |
|---|---|---|---|
| Boxe 4/s | 62%; 36% por K.O. | 34%; 7% | 4%; 16% |
| Boxe 3/s | 62%; 36% | 35%; 5% | 3%; 26% |
| JJ 4/s | 79%; 26% por finalização | 18%; 25% | 3%; 6% |
| JJ 3/s | 76%; 30% | 20%; 22% | 3%; 4% |

O robô só olha a chance. Um jogador que quer **ver** a arte escolhe a tática da arte (Boxe Agressivo, JJ Defensivo) pagando poucos
pontos de chance; a prévia mostra os dois números (§7.3), e é escolha dele.

## 6. Foco de treino e nós da árvore
### 6.1 Foco ideal (medido: divisão F/A/R que chega ao verde com o menor total, em % do total do adversário)
3 melhores divisões F/A/R (de 10 em 10%) e o total que precisam (× total dele). Menor = melhor.

| Arte | Muralha | Tonhão | Kid |
|---|---|---|---|
| Sem arte | 40/20/40 → 0,79 · 30/20/50 → 0,79 · 50/20/30 → 0,82 | 30/20/50 → 0,83 · 30/10/60 → 0,84 · 40/10/50 → 0,84 | 30/30/40 → 0,85 · 40/30/30 → 0,86 · 20/30/50 → 0,87 |
| Boxe | 40/20/40 → 0,76 · 30/20/50 → 0,77 · 50/20/30 → 0,79 | 30/20/50 → 0,81 · 40/20/40 → 0,81 · 50/20/30 → 0,83 | 30/30/40 → 0,87 · 40/30/30 → 0,89 · **30/40/30** → 0,89 |
| Jiu-jitsu | 40/20/40 → 0,77 · 30/20/50 → 0,78 · 50/20/30 → 0,80 | **40/30/30** → 0,81 · 40/20/40 → 0,83 · 50/20/30 → 0,83 | 30/30/40 → 0,85 · 40/30/30 → 0,85 · 30/20/50 → 0,86 |

O "certo" muda pouco no verde (o verde é decidido pelo dano e pela vida), mas muda **muito no amarelo**, onde a campanha se
decide no dia da luta. Exemplo medido (chance com a melhor tática, 200 lutas, contra o Kid, total = 0,9 × o dele):

| Divisão F/A/R | Sem arte | Boxe | Jiu-jitsu |
|---|---|---|---|
| 1/1/1 | 98% | 98% | 97% |
| 2/1/1 (muita FORÇA) | 83% | **78%** | **88%** |
| 1/2/1 (muita AGILIDADE) | 55% | **82%** | **56%** (tática Contra-ataque 78%) |
| 1/1/2 (muita RESISTÊNCIA) | 85% | **78%** | **96%** |

Leitura para o jogador (vai para a dica da janela de escolha da arte e do mentor, pelo Roteirista):
- **Boxe:** AGILIDADE deixa de ser "só para esquivar": ela acelera os socos (até 1,15 s) e multiplica a chance de K.O. O boxeador
  que só treina FORÇA ou RESISTÊNCIA fica pior que sem arte contra o Kid. O aparelho do Boxe (pera: 45% AGI) já é o certo.
- **Jiu-jitsu:** RESISTÊNCIA enche a pegada (e segura até ela encher); FORÇA fecha. Contra o Tonhão, mais FORÇA (40/30/30).
  O boneco de agarrar (60% RES, 25% FOR) é o certo; o saco (FORÇA) passa a valer na finalização.
- Sem arte: nada muda.

### 6.2 Nós da árvore
| Nó | Hoje | 7a1 |
|---|---|---|
| `box_counter` **Contragolpe** (raiz do ramo Boxe, 200) | +10% de dano | **chance de K.O. +50%** (`art_fight_bonus` 0,5: `ko_por_embalo × 1,5`) |
| `bjj_guard` **Base firme** (raiz do ramo JJ, 200) | −10% de dano recebido | **pegada enche 50% mais rápido** (`art_fight_bonus` 0,5: `taxa × 1,5`, respeitando o teto de 1,0/round) |
| `style_boxing` / `style_bjj` (ESTILO, 1.200) e os outros nós de arte | treino (clique / equipe) | **ficam como estão** (são da economia, não da luta) |

Força dos nós (total para o amarelo / verde, média das 4 divisões × 5 adversários; menor = mais forte):

| | sem nó | com o nó | ganho no verde |
|---|---|---|---|
| Boxe antigo (+10% → +21% dano) | 0,683 / 0,823 | 0,663 / 0,797 | 3,2% |
| Jiu-jitsu antigo (−10% → −19% recebido) | 0,680 / 0,813 | 0,660 / 0,785 | 3,4% |
| Boxe 7a1 (K.O. ×1,5) | 0,686 / 0,820 | 0,678 / 0,815 | 0,6% |
| Jiu-jitsu 7a1 (pegada ×1,5) | 0,641 / 0,822 | 0,624 / 0,811 | 1,3% |

Os nós novos pesam menos na chance e mais no **jeito** (Contragolpe: chance de K.O. ×1,5, o nocaute chega antes;
Base firme: com Contra-ataque e fr 1,0, a pegada enche aos 7,1 s em vez de 10,7 s). Custo 200: continua uma compra barata e visível. Se o dono quiser que pesem como antes,
a alavanca é o `value` (1,0 = ×2), sem código novo.

## 7. Prévia honesta
### 7.1 A conta
- `preparar()` calcula `estado_passiva(jog, adv, tática)` (determinístico; mesma função da luta):
  - Boxe: `{kind: "fast_hands", agi_factor: fa, interval: iv_j, ko_max: 5 × ko_por_embalo, tired_at: 10,67, tired_round: 3, opp_counter}`;
  - Jiu-jitsu: `{kind: "submission", grip_full_at: t_cheia, grip_round: floor(t_cheia/5,333)+1, grip_in_time: t_cheia ≤ 16, sub_chance: p_fin}`.
- A chance continua `chance()` (200 sementes, fixas). Na mesma passada, conta também **quantas vitórias vieram da passiva**
  (`finish` = knockout/submission). Função nova `chance_detalhada(jog, adv, tat) -> {chance, wins, wins_passive}`;
  `chance()` passa a chamar ela (o resultado de `chance()` não muda).

### 7.2 O que a prévia mostra (1 linha, só com arte; campos novos em `previa()`)
| Campo | Boxe | Jiu-jitsu |
|---|---|---|
| `passive_name` | MÃO RÁPIDA | FINALIZAÇÃO |
| `passive_line` (tática escolhida) | `SOCO A CADA {s} S · K.O. ATÉ {ko}% POR GOLPE COM EMBALO 5 · CANSA NO 3º ROUND` (Defensivo: `NÃO CANSA`; Agressivo acrescenta `ELE CONTRAGOLPEIA`) | `PEGADA CHEIA NO {r}º ROUND · {p}% POR GOLPE PARA FINALIZAR` (se não enche a tempo: `A PEGADA NÃO ENCHE ANTES DO GONGO`) |
| `passive_state` (para o desenho) | `{streak_max: 5, ko_max, interval}` → 5 bolinhas de embalo apagadas + o número | `{grip_full_at, grip_round}` → barra dos 3 rounds com a marca de onde enche |
| `passive_share` | `{n} EM 10 VITÓRIAS POR K.O.` (de `wins_passive/wins`, arredondado) | `{n} EM 10 VITÓRIAS POR FINALIZAÇÃO` |
Os textos finais são do Roteirista (chaves na §15.3). Ao trocar de tática na prévia, a linha muda junto (cada tática tem o seu estado).

### 7.3 Exemplos de prévia (números do motor, 200 lutas)
| Luta | Arte · tática | Chance | Linha da passiva |
|---|---|---|---|
| Tonhão, você 0,9× (2/1/1) | Boxe · Agressivo | 98% | K.O. ATÉ 20% POR GOLPE · SOCO A CADA 1,15 S · CANSA NO 3º ROUND · ELE CONTRAGOLPEIA · 4 EM 10 VITÓRIAS POR K.O. |
| | Boxe · Defensivo | 95% | K.O. ATÉ 10% · NÃO CANSA · 4 EM 10 POR K.O. |
| | JJ · Defensivo | 90% | PEGADA CHEIA NO 2º ROUND (6,7 S) · 40% POR GOLPE · 9 EM 10 POR FINALIZAÇÃO |
| | JJ · Agressivo | 88% | PEGADA CHEIA NO 3º ROUND (13,4 S) · 40% · 0 EM 10 POR FINALIZAÇÃO |
| Kid, você 0,9× (1/2/1, muita AGI) | Boxe · Agressivo | 82% | K.O. ATÉ 18% · SOCO A CADA 1,18 S · 6 EM 10 POR K.O. |
| | JJ · Contra-ataque | 78% | PEGADA CHEIA NO 2º ROUND (9,4 S) · 34% · 9 EM 10 POR FINALIZAÇÃO |
| Kid, você 0,9× (1/1/1) | JJ · Defensivo | 78% | PEGADA CHEIA NO 2º ROUND (5,7 S) · 37% · 8 EM 10 POR FINALIZAÇÃO |
| | JJ · Agressivo | 97% | PEGADA CHEIA NO 3º ROUND (11,4 S) · 37% · 3 EM 10 POR FINALIZAÇÃO |
A escolha fica clara na prévia: no Jiu-jitsu o Agressivo costuma ganhar mais por dano, e o Defensivo leva quase toda vitória para a
finalização. O jogador vê os dois números e escolhe.

### 7.4 Medida (critério 2): 1.000 lutas por adversário e arte
Estado = atributos reais do robô na hora das lutas × 0,6..1,4 (para cobrir todo o verde/amarelo/vermelho), tática sorteada,
semente real aleatória. "Mostrada" = `chance()` de 200 sementes; "real" = a luta.
| Arte | Adversário | Chance mostrada (média) | Vitória real | Diferença | Como acabou (dano / K.O. passiva / finalização / pontos / perdeu) | Tela |
|---|---|---|---|---|---|---|
| Boxe | Dudu | 85,3% | 85,0% | −0,3 | 815 / 35 / 0 / 0 / 150 | 8,0–11,1 s |
| Boxe | Brutão | 80,9% | 80,9% | 0,0 | 790 / 19 / 0 / 0 / 191 | 8,0–12,9 s |
| Boxe | Dinho | 75,1% | 75,0% | −0,1 | 730 / 20 / 0 / 0 / 250 | 8,0–17,4 s |
| Boxe | Muralha | 77,9% | 78,3% | +0,4 | 434 / 252 / 0 / 203 / 111 | 8,0–19,0 s |
| Boxe | Tonhão | 78,6% | 78,4% | −0,2 | 371 / 314 / 0 / 221 / 94 | 8,0–19,0 s |
| Boxe | Kid | 65,6% | 66,2% | +0,6 | 268 / 231 / 0 / 335 / 166 | 8,0–19,0 s |
| JJ | Dudu | 89,4% | 89,4% | 0,0 | 894 / 0 / 0 / 0 / 106 | 8,0–12,9 s |
| JJ | Brutão | 83,9% | 83,3% | −0,6 | 833 / 0 / 0 / 0 / 167 | 8,0–10,7 s |
| JJ | Dinho | 84,3% | 84,5% | +0,2 | 791 / 0 / 49 / 12 / 148 | 8,0–19,0 s |
| JJ | Muralha | 85,4% | 85,0% | −0,4 | 434 / 0 / 362 / 161 / 43 | 8,0–19,0 s |
| JJ | Tonhão | 77,3% | 77,2% | −0,1 | 278 / 0 / 397 / 262 / 63 | 8,0–19,0 s |
| JJ | Kid | 66,3% | 67,3% | +1,0 | 121 / 0 / 420 / 358 / 101 | 8,0–19,0 s |

**Critério 2 fecha: pior diferença 1,0 ponto** (meta ±5). É honesta por construção (a prévia roda o mesmo motor), e a medida
confirma. Contra Dudu e Brutão (lutas curtas, decididas por dano) a passiva quase não aparece; ela aparece da Muralha em diante.
Duração: **8,0–19,0 s** em todas (critério 4).

## 8. A luta na tela (dados para a UI e a arte; tudo só visual)
### 8.1 Campos novos (resultado e eventos de `rodar`/`luta_atual`)
| Onde | Campo | Valor |
|---|---|---|
| resultado | `finish` | `"damage"` (vida zerou, qualquer lado) · `"knockout"` (Boxe) · `"submission"` (JJ) · `"points"` |
| resultado | `streak_peak`, `attempts`, `opp_counter_damage`, `grip_full_at` (−1 sem JJ), `tired_at` (−1 sem Boxe) | para a tela e o motivo |
| evento | `streak` | embalo depois do evento (Boxe) |
| evento | `grip` | pegada no instante (JJ, 0–1) |
| evento | `tired` | true se o jogador de Boxe já está cansado |
| evento | `finish` | `""` · `"knockout"` · `"submission"` no último evento |
| evento (montado em `_montar_info_luta`) | `phase` | `"standing"` · `"ground"` (§10.2) |
`_resultado_salvo()` ganha `finish` (campo opcional; save antigo sem ele = `"damage"` se `ko`, senão `"points"`).

### 8.2 O que o jogador vê
| | Boxe | Jiu-jitsu |
|---|---|---|
| HUD | **embalo**: 5 bolinhas ao lado da sua vida, acendem a cada acerto, apagam quando ele esquiva; "CANSADO" no 3º round (pose `tired` entre os golpes) | **pegada**: barra fina sob a sua vida, enche com o tempo; ao encher, pisca "PEGADA!" |
| Final | letreiro **K.O.** de hoje; no nocaute pela passiva, o número do embalo junto ("EMBALO 5") | letreiro novo **FINALIZOU!** e o adversário bate no chão (`tap_out`) |
| Rounds | mais golpes nos rounds 1–2 (1,15–1,80 s, pela AGILIDADE), mais lentos no 3º (1,98 s) | menos golpes (2,25 s), queda e chão |

Duração: igual a hoje, `tela = 1,5 + t_fim + 1,5`, com K.O./finalização respeitando `min_ko_time` (5 s): **8 a 19 s** (medido, §12).

## 9. Motivo da derrota explicando a passiva
O motivo de hoje fica (atributo, falta, estatística, dica, tática melhor: já usam a passiva, porque usam `chance`/`passa`).
Entra **1 linha extra** `passive_note` quando a passiva pesou, tirada da própria luta (sem simulação nova). A 1ª que valer, nesta ordem:

| Arte | Id | Quando | Texto provisório (Roteirista) | Dica |
|---|---|---|---|---|
| Boxe | `boxing_counter` | tática Agressivo e `opp_counter_damage ≥ 20%` da sua vida máxima | OS CONTRAGOLPES DELE TIRARAM {n}% DA SUA VIDA | "NO AGRESSIVO, CADA ERRO SEU VIRA SOCO DELE" |
| Boxe | `boxing_tired` | perdeu com `t_fim ≥ tired_at` (chegou cansado ao 3º round) e tática ≠ Defensivo | VOCÊ CANSOU NO 3º ROUND | "O DEFENSIVO GUARDA O FÔLEGO" |
| Boxe | `boxing_streak` | `streak_peak ≤ 2` | ELE CORTOU SEU EMBALO (NO MÁXIMO {n}) | "AGILIDADE SEGURA O EMBALO" |
| JJ | `bjj_grip_late` | perdeu antes da pegada encher (`t_fim < grip_full_at` ou pegada não enche em 16 s) | A PEGADA ENCHERIA NO {r}º ROUND. VOCÊ CAIU ANTES | "RESISTÊNCIA (OU DEFENSIVO) ENCHE A PEGADA ANTES" |
| JJ | `bjj_escaped` | pegada cheia, `attempts ≥ 1`, sem finalizar | A PEGADA ENCHEU, MAS ELE ESCAPOU {n} VEZES | "FORÇA FECHA A FINALIZAÇÃO" |
| JJ | `bjj_never_hurt` | pegada cheia, `attempts = 0` | A PEGADA ENCHEU, MAS ELE NUNCA BAIXOU DE 60% | "MAIS FORÇA PARA CANSAR ELE" |
Formato no `motivo`: `{"passive_note": {"id", "n", "r"}}` ({} se nenhuma). A tela de fim mostra abaixo da estatística.

## 10. Golpes por estilo (`data/moves.json`, já gravado)
### 10.1 Estilo do jogador
`gs.golpes.disponiveis(estilo)`: **`bjj`** com Jiu-jitsu; **`boxing`** com Boxe e sem arte (como hoje). Kinds novos no
`MovesData.KINDS`: `takedown` e `submission` (até o código entrar, o jogo avisa no console que ignorou esses 2 golpes).

| id | nome | anim | kinds | phase | reação de quem apanha |
|---|---|---|---|---|---|
| `clinch_push` | Empurrão no clinch | `clinch_push` | jab, crit, counter | standing | `hit_clinch` |
| `takedown` | Queda (pega a perna) | `takedown` | takedown | standing | `fall` |
| `ground_pressure` | Pressão no chão | `ground_pressure` | jab, crit, counter | ground | `ground_hit` |
| `submission` | Finalização | `submission` | submission | ground | `tap_out` |
| `ground_punch` (estilo `ground_bottom`) | Soco de baixo | `ground_punch` | jab, crit, counter | ground | `ground_top_hit` |

### 10.2 Regra de fases (só Jiu-jitsu; em `_montar_info_luta`)
1. Começa `standing`: acertos do jogador → `clinch_push`; do adversário → golpes do estilo dele (boxe).
2. O **1º acerto do jogador com `grip ≥ ground_at_grip` (0,5)** vira `takedown` (kind forçado) e a luta passa a `ground`.
3. Em `ground`: acertos do jogador → `ground_pressure`; acertos do adversário → `ground_punch` (estilo `ground_bottom`);
   esquiva no chão = sem golpe novo (a tela mostra `ground_top_idle` / `ground_bottom_idle` mexendo).
4. O acerto com `finish = "submission"` usa `submission` + reação `tap_out` e o letreiro "FINALIZOU!".
5. Fim por pontos ou K.O. por dano no chão: os dois voltam ao `idle` em pé antes do resultado.
Fallback de arte (regra de hoje do `moves.json`): sprite que não existe → golpe antigo (jab/heavy) e reação `hit`.

## 11. Arena da liga da academia
- `data/locations.json`: `fight_arena` por local (`garage` → `"arena"` = borracharia de hoje; `gym` → `"arena_league"`).
  A arena da luta é a do local do **adversário** (`opp.location`, padrão `garage`): Tonhão e Kid lutam na nova; os 4 amadores
  continuam na borracharia, inclusive para quem já se mudou.
- O que a arte precisa saber (mesmo contrato da arena de hoje, `fight_layout` do manifest):
  - fundo **640×360**, faixa **y 0..45 escura e lisa** (o HUD fica ali); chão onde os pés ficam em **y 318** (pivôs 296 e 346);
  - camadas com os mesmos nomes e prefixo novo: `arena_league_bg` (640×360), `arena_league_crowd_back` (640×100, 2 quadros),
    `arena_league_crowd_front` (640×48, 2 quadros), `arena_league_lamp` (opcional; sem ela, nada no lugar);
  - espaço livre no chão para os **dois deitados** (Jiu-jitsu): faixa de ~150 px entre x 250 e 400, sem objeto na frente dos pés;
  - de dia (sábado), mais clara que a borracharia, mas com o mesmo contraste para os números e os letreiros brancos;
  - o letreiro novo "FINALIZOU!" e o K.O. precisam ler bem nas duas arenas.
- Nome do lugar: Roteirista.

## 12. Balanço medido (`tools/sim/fase7a1_sim.py`)
### 12.1 Força de cada arte na luta (limiar)
Total de atributos (em × total do adversário) para chegar ao **amarelo (40%) / verde (90%)** com a melhor tática;
média de 4 divisões (1/1/1, 2/1/1, 1/2/1, 1/1/2) e 5 adversários (Brutão, Dinho, Muralha, Tonhão, Kid). Menor = mais forte.
| | Sem arte | Boxe antigo (+10%) | JJ antigo (−10%) | **Boxe 7a1** | **JJ 7a1** |
|---|---|---|---|---|---|
| Média (amarelo / verde) | 0,702 / 0,848 | 0,683 / 0,823 | 0,680 / 0,813 | **0,686 / 0,820** | **0,641 / 0,822** |
| Tonhão | 0,748 / 0,891 | 0,732 / 0,867 | 0,730 / 0,863 | 0,724 / 0,846 | 0,668 / 0,870 |
| Kid | 0,838 / 0,926 | 0,813 / 0,896 | 0,810 / 0,884 | 0,818 / 0,914 | 0,726 / 0,913 |

- **Boxe 7a1 = Boxe de hoje** na média (amarelo +0,4%, verde −0,4%). Mais forte contra os lentos (Tonhão, Muralha), mais fraco contra
  o Kid se o jogador não treinar AGILIDADE.
- **Jiu-jitsu 7a1:** no verde igual ou um pouco mais fraco que hoje (0,822 × 0,813); no **amarelo bem mais forte** (0,641 × 0,680):
  é a arte que **vira luta difícil** pela finalização. Isso é o que fecha a nota "Jiu-jitsu 1 campanha atrás" (§12.2) e é o jeito
  da arte, não um bônus escondido: a prévia mostra a chance real (§7.4).
- O azar contra o JJ é limitado pelo portão de 60% da vida dele: quem está muito atrás (0,7×) só finaliza se tiver muita FORÇA
  (ex.: Kid 0,7× 2/1/1, Defensivo: 52%; 1/2/1: 0–16%).

### 12.2 Campanha (robô padrão da 6c2, hall normal, 200 jogadores por perfil × 10 campanhas)
Rodar: `SIM_N7=200 python -I tools/sim/fase7a1_sim.py campanha` (7a1) e o mesmo com `SIM_PASSIVA=0` (hoje). "Tempo até o 1º Kid"
= tempo de jogo acumulado, contando campanhas perdidas e trocas (90 s cada).

| Perfil | Campanhas até o Kid (méd; p90; média) | Kid na 1ª tentativa | Tempo até o 1º Kid: mediana / **média** / p90 | Vitórias com arte: dano / K.O. passiva / finalização / pontos | Tonhão: vitórias pela passiva |
|---|---|---|---|---|---|
| **Hoje** Boxe 4/s | 1; 1; 1,07 | 96,5% | 40:45 / 43:21 / 53:13 | 9.936 / 0 / 0 / 277 | 0% |
| **Hoje** JJ 4/s | 1; 1; 1,21 | 95,0% | 41:49 / 46:53 / 57:38 | 8.142 / 0 / 0 / 1.876 | 0% |
| **Hoje** Boxe 3/s | 1; 2; 1,19 | 88,0% | 45:44 / 50:56 / 69:47 | 9.790 / 0 / 0 / 354 | 0% |
| **Hoje** JJ 3/s | 1; 4; **1,91** | 78,0% | 47:07 / **64:56** / 106:34 | 7.979 / 0 / 0 / 2.158 | 0% |
| **7a1** Boxe 4/s | 1; 2; 1,14 | 92,5% | 41:04 / 44:57 / 57:41 | 7.321 / 2.620 / 0 / 293 | 52% por K.O. |
| **7a1** JJ 4/s | 1; 3; 1,25 | 91,0% | 41:47 / 47:33 / 76:25 | 7.173 / 0 / 2.613 / 434 | **50% por finalização** |
| **7a1** Boxe 3/s | 1; 3; 1,43 | 78,5% | 46:18 / 56:19 / 85:53 | 7.173 / 2.504 / 0 / 309 | 58% por K.O. |
| **7a1** JJ 3/s | 1; 3; **1,56** | 80,0% | 46:33 / **58:15** / 92:28 | 6.876 / 0 / 2.808 / 514 | **60% por finalização** |

**Boxe × Jiu-jitsu (critério 6, meta ≤ 15%):**
| | Hoje | 7a1 |
|---|---|---|
| 4/s: tempo até o Kid (mediana / média) | 2,6% / 8,1% | **1,8% / 5,8%** |
| 4/s: Kid na 1ª tentativa | 96,5 × 95,0 (1,5 ponto) | **92,5 × 91,0 (1,5 ponto)** |
| 3/s: tempo até o Kid (mediana / média) | 3,0% / **27,5%** | **0,5% / 3,4%** |
| 3/s: Kid na 1ª tentativa | 88,0 × 78,0 (**10 pontos**, 13%) | **78,5 × 80,0 (1,5 ponto)** |
| 3/s: campanhas até o Kid (média) | 1,19 × **1,91** | **1,43 × 1,56** |
| 3/s: passou o posto no Kid antes de lutar | 1 × **50** | 10 × 8 |
Tudo dentro de 15%. A única folga grande é o p90 do JJ 4/s (76:25 × 57:41): 1 em 10 jogadores de JJ rápido leva uma campanha a
mais; a média segue a 5,8%. **Nenhuma é a certa**: o JJ deixou de ficar "1 campanha atrás" a 3/s (média 1,91 → 1,56; 50 → 8 passagens
de posto no Kid), e o Boxe ficou um pouco mais exigente contra o Kid (ágil) para quem não treina AGILIDADE (o robô treina FORÇA).

Outros números da campanha (7a1): vitória nas lutas com arte 98–99% (o robô espera o verde); tela da luta **8,0–19,0 s**
(mediana 8,0–9,3 s); **Tonhão vencido pela finalização em 50–60% das vitórias** do JJ (critério 1 pede ≥ 1 em 3).

### 12.3 Metas da visão
| Meta | Hoje | 7a1 |
|---|---|---|
| 1ª carreira 10–15 min (sem arte) | 13:56 (4/s) · 15:26 (3/s) | **igual** (a 1ª carreira não tem arte; foto igual) |
| Cinturão amador entre a 2ª e a 4ª carreira | mediana 2 | **mediana 2** |
| Tempo morto ≤ 10 min | economia | **sem mudança**: a 7a1 não mexe em treino, preço nem calendário |
| 5.4 D1: Kid na 1ª tentativa, média ≤ 80%, nenhum perfil < 50%, mediana 1–2, p90 ≤ 4 | 89% (4 perfis), menor 78%, med 1, p90 ≤ 4 | **85,5%**, menor 78,5%, med 1, p90 ≤ 3 |
| 5.4 D2: JJ 3/s média de campanhas ≤ 2,2 e tempo ≤ 25% depois do Boxe 3/s | 1,91 e 27,5% na média (mediana 3,0%) | **1,56 e 3,4%** na média (mediana 0,5%) |

## 13. Registro: Kid fácil a 4 cliques/s
Nota da 5.4: "a 4/s o Kid continua fácil (92–96% na 1ª tentativa)". Medido agora (200 jogadores, robô que espera o verde):

| Kid na 1ª tentativa | Boxe 4/s | JJ 4/s | Boxe 3/s | JJ 3/s | Média |
|---|---|---|---|---|---|
| Hoje (traços) | 96,5% | 95,0% | 88,0% | 78,0% | 89,4% |
| **7a1** | **92,5%** | **91,0%** | 78,5% | 80,0% | **85,5%** |
| 7a1 + Kid ×1,15 (só teste) | 85,0% | 84,0% | 72,5% | 67,0% | 77,1% |

- **Melhorou, não resolveu.** A 4/s caiu de ~96% para ~92%: o Kid ágil pune o boxeador que não treina AGILIDADE e o portão da
  finalização obriga o JJ a cansar o Kid. Mas a 4/s o jogador chega ao verde antes da data, e no verde a chance é ≥ 90% por definição
  (prévia honesta). Enquanto o robô esperar o verde, "Kid na 1ª tentativa" a 4/s fica perto de 90%.
- **A alavanca "Kid mais forte" não serve**: Kid ×1,15 leva a média a 77%, mas o **Boxe 3/s quebra** (2,40 campanhas até o Kid,
  161 passagens de posto, tempo +68% contra o JJ 3/s). Não recomendo.
- **Recomendação:** registrar e deixar para a **8a**, com a passiva própria do Kid (decisão 2 do dono): "estilo que neutraliza a arte"
  (ex.: o Kid corta o embalo e escapa da pegada) deixa a luta dele difícil **para quem chega no limite**, sem mexer em quem treina
  mais devagar. Nenhum número do Kid muda na 7a1.

## 14. Save
**Continua v13, sem migração.** A arte já está no save; a passiva, os golpes e a arena vêm de `data/`. O único campo novo é
`career.fight.result.finish` (opcional; save antigo sem ele vale `"damage"` se `ko`, senão `"points"`). Uma luta pendente gravada
antes da 7a1 por quem tem arte é recalculada com a passiva nova: o aviso de hoje ("a luta salva não bate") já cobre, e vale o
**resultado salvo**.

## 15. Contrato de dados
### 15.1 `data/arts.json → arts[].passive` (gravado)
| Campo | Boxe | JJ | O que é |
|---|---|---|---|
| `type` | `fast_hands` | `submission` | qual passiva |
| `damage_mult`, `taken_mult` | 0,88 / 1,0 | 1,20 / 1,0 | multiplicam a tática do jogador (substituem o traço) |
| `interval_mult` | 0,80 | 1,25 | × `attack_interval` (só o jogador) |
| `speed_agility_min/max` | 0,80 / 1,25 | — | Boxe: o intervalo é dividido por `clamp(2·Agi_j/(Agi_j+Agi_a), min, max)` (rounds 1–2) |
| `need_ahead` | 1 | 0 | 1 = só com a vida % dele ≤ a sua |
| `tired_from_round`, `tired_interval_mult` | 3 / 1,10 | — | cansaço |
| `streak_max`, `streak_per_hit` | 5 / 1 | — | embalo |
| `ko_life_max`, `ko_per_streak`, `ko_agility_min/max`, `ko_cap` | 0,50 / 0,02 / 0,4–1,6 / 0,5 | — | K.O. |
| `grip_per_round`, `grip_endurance_min/max`, `grip_rate_max` | — | 0,5 / 0,5–2,0 / 1,0 | pegada |
| `ground_at_grip` | — | 0,5 | só visual: queda |
| `sub_life_max`, `sub_base`, `sub_strength_min/max`, `sub_cap` | — | 0,60 / 0,30 / 0,25–2,0 / 0,6 | finalização |
| `tactics.aggressive` | `ko_mult` 1,5, `opponent_counter` 0,8 | `grip_mult` 0,75 | |
| `tactics.defensive` | `ko_mult` 0,75, `tired_interval_mult` 1,0 | `grip_mult` 1,5 | |
| `tactics.counter` | `streak_per_counter` 2 | `grip_mult` 1,0 | |
Campo que falta = neutro (mult 1, extra 0). Validação no `GymData`: recortar como os outros (`interval_mult` 0,5–2,0; chances 0–1).

### 15.2 Trocas que entram **junto com o código** (não antes: o jogo de hoje leria errado)
| Arquivo | Troca |
|---|---|
| `data/arts.json` | apagar `fight`; `fight_text` vira o texto da passiva (Roteirista) |
| `data/skill_tree.json` | `box_counter`: `effect.value` 0,1 → **0,5**, `effect_text` "BOXE: CHANCE DE K.O. +{pct}%"; `bjj_guard`: 0,1 → **0,5**, "JIU-JITSU: PEGADA ENCHE {pct}% MAIS RÁPIDO" |
| `scripts/moves_data.gd` | `KINDS` += `takedown`, `submission`; ler `phase` |

### 15.3 Chaves de texto novas (`data/ui_texts.json`; textos do Roteirista)
`passive_boxing_name`, `passive_bjj_name`, `passive_boxing_line`, `passive_boxing_line_defensive`, `passive_boxing_counter_warn`,
`passive_bjj_line`, `passive_bjj_line_late`, `passive_share_boxing`, `passive_share_bjj`, `fight_streak`, `fight_tired`,
`fight_grip_full`, `fight_submission` ("FINALIZOU!"), `reason_passive_boxing_counter`, `reason_passive_boxing_tired`,
`reason_passive_boxing_streak`, `reason_passive_bjj_grip_late`, `reason_passive_bjj_escaped`, `reason_passive_bjj_never_hurt`,
`tip_passive_*` (uma por nota), e os textos da janela de escolha da arte (`fight_text` das duas artes).

## 16. Quem faz o quê
### Programador
1. `scripts/luta.gd`: `passiva` no lugar de `traco`; `estado_passiva()`; `_rodar_arte()` (§2–§3; referência linha a linha:
   `RegrasArte._lutar_arte` em `tools/sim/fase7a1_sim.py`); `chance_detalhada()`; campos novos de resultado e evento (§8.1).
   Sem arte: o laço de hoje intacto.
2. `scripts/estado/academia_artes.gd`: `_atualizar_traco()` vira `_atualizar_passiva()` (lê `passive` + `extra` dos nós).
3. `scripts/estado/luta.gd`: `previa()` com `passive_*` (§7.2); `_montar_info_luta()` com o estilo do jogador por arte e as fases (§10.2);
   `_resultado_salvo()` com `finish`; `_calcular_motivo()` com `passive_note` (§9).
4. `GymData` lê e valida `passive`; `MovesData` com `KINDS` novos e `phase`; arena por local (`fight_arena`).
5. `textos.gd`: `texto_passiva(id)` no lugar de `texto_traco_luta` (janela de escolha, prévia); textos dos 2 nós.
6. Trocas da §15.2. `docs/codigo/mapa.md` atualizado.
7. Testes (save de teste): (a) **foto** igual à main sem arte; (b) casos exatos Python × GDScript com arte (4 sorteios; estender
   `tools/sim/exportar_casos.py` com `fase7a1_sim.RegrasArte`); (c) chance com arte dentro da tolerância; (d) a pegada enche no
   `t_cheia` da prévia; (e) `passive_note` de cada id em luta montada; (f) arena: amador na borracharia, Tonhão/Kid na liga.
### UI/UX
Linha da passiva na prévia (nome + linha + embalo/pegada + "N EM 10 VITÓRIAS"), também ao trocar de tática; HUD da luta
(5 bolinhas de embalo, "CANSADO", barra de pegada, "PEGADA!"); letreiro "FINALIZOU!"; `passive_note` na tela de fim;
cartões da janela de escolha da arte; arena nova; estados novos no `ui_audit` (prévia de cada arte, luta na liga,
"fim depois de derrota com a arena visível" — pendência 5.4/B2 —, FINALIZOU!). Skill `alinhamento-ui`, **0 problemas**.
### Diretor de Arte
Mockup e depois a arena `arena_league_*` (§11); letreiro "FINALIZOU!" (mesma família do K.O.); bolinha de embalo e barra de
pegada (ícones 1× do HUD).
### Artista de Personagens (skill `padrao-personagem`)
Jogador de Jiu-jitsu: `clinch_push`, `takedown`, `ground_top_idle`, `ground_pressure`, `submission`. Adversários (os 6, no rig
comum): `hit_clinch`, `fall`, `ground_bottom_idle`, `ground_hit`, `ground_punch`, `tap_out`; jogador por cima: `ground_top_hit`.
Corte, se apertar (escopo §9): (1) `ground_pressure`/`ground_hit` viram 1 pose cada; (2) `submission`/`tap_out` sem animação
própria, só a pose e o letreiro. **Não se corta:** `takedown`/`fall` e o "FINALIZOU!".
### Roteirista
Nomes finais das passivas (Mão rápida / Finalização são provisórios), as chaves da §15.3, o nome da arena, a dica de foco por arte
(§6.1) e a fala opcional do mentor sobre estilo. Atenção: **"embalo"** também é o nome do bônus do minigame da 7a2 (decisão do dono);
escolher se fica um só nome ou se o do minigame muda.
### QA
Critérios 1–6, 13, 14 do escopo, usando as tabelas da §7.4 e da §12 como referência (rodar `fase7a1_sim.py honesta campanha`).

## 17. Resumo
- **Boxe, Mão rápida:** socos 25% mais rápidos nos rounds 1–2 (até 1,15 s com AGILIDADE alta), 12% mais fracos; **embalo** de 0 a 5
  (sobe a cada acerto, zera quando ele esquiva); com ele abaixo de 50% e mais machucado que você, cada acerto pode ser **K.O.**
  (embalo × 2% × fator de AGILIDADE; Agressivo ×1,5). **Cansa no 3º round** (1,98 s; Defensivo não cansa). Agressivo arrisca
  **contragolpe** dele (80%) a cada erro.
- **Jiu-jitsu, Finalização:** socos 25% mais lentos, 20% mais fortes; **pegada** enche 50% por round × fator de RESISTÊNCIA
  (contra a FORÇA dele) × tática (Defensivo ×1,5); cheia e com ele abaixo de 60%, cada acerto finaliza com 30% × fator de FORÇA.
  Não precisa estar na frente: é a arte que vira luta difícil.
- **Traços +10%/−10% saem.** Contragolpe e Base firme viram reforço da passiva (K.O. ×1,5; pegada ×1,5).
- **Sem arte, nada muda** (motor intocado, 3 sorteios; 2.000 de 2.000 lutas iguais no simulador; foto igual).
- **Prévia honesta:** 1 linha com a passiva e o embalo/pegada; pior diferença medida **1,0 ponto** (meta ±5).
- **Balanço:** Boxe × JJ dentro de 15% em tudo (3/s: tempo 0,5% mediana e 3,4% média, Kid 78,5 × 80,0%); o JJ 3/s deixou de ficar
  1 campanha atrás (1,91 → 1,56); Tonhão finalizado em 50–60% das vitórias do JJ; lutas de 8 a 19 s; Kid a 4/s de 96% para 92%
  (registrado; resto para a 8a).
- **Save continua v13**, sem migração (só `finish` opcional no resultado da luta).
