# Fase 5.2 — Clique sem teto: design

Dono: Designer de Jogo. Data: 2026-11-12. Branch: `fase-5.2`.
Base: `docs/fases/fase5.2-escopo.md` (aprovado de antemão), `fase5-design.md` (R8), `fase5.1-design.md`, `fase5.1-revisao.md` (seções 4 e 5).
Simulador: `tools/sim/fase5_sim.py` (seção nova `f52`; tudo lido de `data/`). Rodar:
`"C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase5_sim.py precos b23 controle carreiras f52`

**Todos os números deste documento já estão em `data/`** (lista completa na seção 8.4). Os nomes e textos que estão lá são provisórios: o Roteirista troca.

---

## 1. Luvas L3 e L4 (em $, na caixa)

| id | Nome provisório | Custo | `click_multiplier` | Luva total (×) | Quando o jogador compra |
|---|---|---|---|---|---|
| `glove_l1` | Luva de lona | $120 | ×2 | ×2 | garagem (não muda) |
| `glove_l2` | Luva de couro | $500 | ×2 | ×4 | garagem (não muda) |
| **`glove_l3`** | Luva de marca | **$1.200** | **×2** | **×8** | **na chegada à academia**, com os $1.500 que sobram da mudança |
| **`glove_l4`** | Luva de competição | **$2.500** | **×2** | **×16** | **depois do Tonhão** ($2.500 do prêmio + os $300 que sobraram) |

**Fórmula (não muda):** `por_clique = base × aparelho × luva_total × (1 + árvore) × local × (1 + Boxe) [+ clique com a equipe, seção 3]`, com `luva_total = Π click_multiplier das luvas abertas`. O Metrônomo e o assistido também usam a luva (como hoje).

**Por que esses números**
- **×2 cada:** o critério 2 pede "pelo menos o dobro" no número do clique. ×2 dobra exatamente o número da barra de baixo; ×3 em cada luva obrigaria o Kid a subir ×9 e afastaria o Jiu-jitsu (a luva só ajuda o clique). Com ×2 + ×2 a academia ganha ×4 no clique e no Metrônomo.
- **$1.200:** cabe nos $1.500 da chegada (critério 2: L3 em ≤ 5 min; o robô compra em 0:00–0:04, p90 ≤ 3:00 quando prefere um nível de Metrônomo antes). Na garagem ela não cabe: sem árvore a garagem paga $1.000 no total; mesmo com `career_purse_2` (+100%) sobram ~$850 depois de L1, L2 e Metrônomo.
- **$2.500:** quem chegou sem nós de dinheiro tem $300 + $2.500 do Tonhão = $2.800, então compra logo depois de vencê-lo. Com `career_purse` (+50%) o Tonhão paga $3.750 e sobra para o Metrônomo.

**Caixa (regras da 5.1, sem exceção):** L3 e L4 chegam na caixa do slot `glove` (3 cliques, perto do lutador, nunca some); a próxima luva só fica à venda com a anterior aberta; `glove_level` conta as luvas compradas. Nenhum campo novo: o código já lê a lista `gloves.levels` inteira e `box.applies_to.glove` continua valendo para as 4 (se o dono pedir a luva instantânea, é `"glove": false`).

**Caixas por carreira:** até 7 (esteira, corda, aparelho da arte, 4 luvas); juntas no máximo 3 (como na 5.1).

---

## 2. Bolsa da torcida (variante da luva dourada)

### 2.1 Como funciona
- Mesmo relógio da luva ×7: aparece a cada `wait_min`–`wait_max` (60–100 s), fica `visible_seconds` (7 s) e some se ninguém clicar. **No instante em que aparece**, sorteia a variante: com chance `crew_chance` é a bolsa, senão é a ×7. O jogador vê qual é antes de clicar (sprite diferente, `crew_sprite`).
- Clicou na bolsa: ganha **de uma vez**
  `bolsa = max(crew_seconds × renda_sem_mão, crew_floor_clicks × por_clique())`
  `renda_sem_mão = producao_total() + socos_por_segundo_metronomo() × por_auto_soco()` (equipe/s + AUTO/s, como o HUD mostra; sem crítico, sem FRENESI).
- O treino da bolsa entra **igual ao da equipe**: no saldo de Treino e no atributo do aparelho em foco. Número flutuante grande e toast `golden_crew_toast`. Não liga o FRENESI, não conta crítico.
- Com luta ou janela aberta: o relógio espera (igual à ×7). A bolsa nunca acumula: perdeu, perdeu.

### 2.2 Números
| Campo (`golden_event`) | Valor | Por quê |
|---|---|---|
| `crew_chance` | **0,5** | meio a meio (opção do escopo, seção 6). Com 0,4 e a garagem nova o 23b a 5/s foi a 29% e o cinturão mais cedo a 19:50; 0,5 tira metade do FRENESI de quem clica muito sem mudar a frequência da luva |
| `crew_seconds` | **45** | o topo da faixa 30–45 s: com 30 s a bolsa nunca vale mais que a ×7, nem para quem não clica com o Metrônomo ligado |
| `crew_floor_clicks` | **40** | no começo da garagem a equipe é quase zero; o piso garante que a bolsa sempre paga algo visível (40 cliques ≈ 13 s de mão a 3/s) |
| `frenzy_sprite` / `crew_sprite` | `event_golden_glove` / `event_golden_crew` | visual de cada variante em dado (o Diretor de Arte entrega o novo) |

### 2.3 Quem prefere qual (por que ela não vira a obrigatória)
Valor de cada uma, em treino: `×7 = 6 s × 6 × (mão/s + 1,2 × AUTO/s)`; `bolsa = 45 × (equipe/s + AUTO/s)`.
**A bolsa só ganha quando `mão/s < 1,25 × equipe/s + 0,05 × AUTO/s`**, isto é, para quem quase não clica.
| Momento (robô, no Kid) | mão/s | equipe/s | AUTO/s | ×7 vale | bolsa vale | Melhor |
|---|---|---|---|---|---|---|
| Jiu-jitsu 3/s | ~49K | ~5,5K | ~21,6K | ~2,7M | ~1,2M | ×7 (2,2×) |
| Boxe 5/s | ~124K | ~1,8K | ~27K | ~5,6M | ~1,3M | ×7 (4×) |
| Só assistido / parado (mão 0) | 0 | ~2,3K | ~2,2K | ~0,1M | ~0,2M | **bolsa** (2×) |
Quem ignora as duas não fica para trás: a bolsa dá ~3–5% do treino da carreira (tabela 7.5) e a ×7, ~+17% no clique de quem pega 80%.

---

## 3. Clique com a equipe (LOJA, em $)

**Uma** melhoria, um nível, por carreira (some na NOVA CARREIRA, como luvas e Metrônomo).
| id | Nome provisório | Custo | Efeito |
|---|---|---|---|
| `crew_click` | Grito da equipe | **$1.500** | **cada clique da sua mão soma `crew_share` (1,0) × equipe/s** — "cada clique vale +1 s da sua equipe" |

**Fórmula exata (game_state):**
`por_clique() = _base_soco() × (1 + bonus_arte_clique()) + (crew_share × producao_total() se comprou)`
- Entra antes do crítico e do FRENESI (o clique inteiro critica e multiplica, como hoje).
- **Só a mão** (clique e Espaço). `por_auto_soco()` (Metrônomo e assistido) **não** ganha: o Metrônomo já é forte e o assistido tem que ficar ≥ 6× abaixo do clique.
- A barra de baixo ("por clique") passa a mostrar o valor com a equipe: o número cresce sozinho quando a equipe cresce.
- **Sem teto.** A curva é linear na equipe de propósito: é ela que segura o clique quando a equipe ficar grande (5.4). O que impede abuso é ser só da mão.

**Por que 1,0 e $1.500**
- Hoje a equipe é pequena perto do clique (no Kid: Boxe 1,8K/s contra 20K por clique). Com 1,0 a melhoria vale **~+8% no clique do Boxe e ~+40% no do Jiu-jitsu** (equipe 5,5K/s): é o que mantém o Jiu-jitsu, "a arte da equipe", na frente do Boxe a 3/s (critério 6). Com 0,5 ela era quase invisível.
- $1.500: sem nós de dinheiro, é a compra depois da L4 (o Kid paga); com `career_purse` cabe junto com a L3 na chegada ($2.750 − $1.200). O robô compra em 100% das carreiras que vencem o Kid.
- Na garagem não cabe (mesma conta da L3).

---

## 4. Adversários e mudanças de número

### 4.1 Tonhão e Kid (pedido do escopo)
| Adversário | F / A / R antes | **Agora** | Fator |
|---|---|---|---|
| `opp_gym_1` Tonhão do Tatame | 390K / 150K / 1,65M | **975K / 375K / 4,125M** | ×2,5 |
| `opp_gym_2` Kid Navalha | 1,15M / 2,3M / 4,6M | **4,6M / 8,05M / 20,7M** | ×4 (A ×3,5, R ×4,5) |
Prêmios e Fama não mudam ($2.500/120 e $6.000/200).
- **Tonhão ×2,5:** a L3 chega antes dele (×2) e a melhoria 3 dos aparelhos agora vem da garagem (4.2).
- **Kid ×4:** com ×5 o Jiu-jitsu a 3/s ficava atrás do Boxe (média 1,94 × 1,35 carreira); com ×3 o Kid caía na carreira da chegada em 50% a 5/s.
- **Kid com menos Agilidade e mais Resistência** (×3,5 / ×4,5 em vez de ×4 / ×4): com ×4 uniforme, a 3/s, o Jiu-jitsu chegava em média 1,31 carreira contra 1,21 do Boxe; com a troca, 1,31 contra 1,38. A pera treina Agilidade e o boneco, Resistência; o Kid continua "RÁPIDO" (A 8M) e corta igual.

### 4.2 Mudei sem pedido (garagem), para fechar o critério 5
Mudei sem pedido: **Dinho Pulga ×1,4** (20K/110K/6K → **28K / 154K / 8,4K**) e **melhoria 3 de saco, esteira e corda $400K → $250K** (`bag_leather`, `treadmill_motor`, `rope_beads`; ×3 igual). Motivo: o tempo morto da carreira 1 a 3–4/s (seção 7.3).
- A causa do tempo morto longo: a 3/s, o robô vence o Dinho no amarelo (41–44%) por sorte aos ~14 min, gasta os $800 na hora e fica **14 min no vermelho e sem dinheiro** diante do Muralha, sem nada para comprar entre a melhoria de 5K e a de 400K.
- **$250K** põe uma compra de Treino no meio dessa parede (a "próxima coisa" cai de 12:40 para ~6:45 no p90 a 3/s). **Dinho ×1,4** faz o robô chegar mais forte no Muralha e divide a parede em duas (o prêmio do Dinho cai no meio).
- **O que eu testei e não serve:** Metrônomo mais rápido ou mais barato (−30 s no máximo); Muralha mais forte junto com a melhoria barata (a parede volta); só a melhoria barata ($100K–$200K: cinturão aos 16:51–18:22, fura o "nunca antes de 20:00"); Dinho ×1,6–2,0 (1ª derrota a 4/s vai para 16–18 min).
- Efeito na academia: a melhoria 3 deixa de ser "a 1ª compra grande da academia" (R8 da Fase 5); quem chega lá agora compra L3, Grito da equipe, técnica 3 e melhoria 4. O Tonhão subiu ×2,5 por isso.

### 4.3 Metrônomo e Shift: **não mexi**
Os números não pedem. O Metrônomo L1 a 1,0 s e L2 a 0,75 s tiraram no máximo 30 s do p90 da carreira 1 (13:32 → 13:02) e o assistido não pesa em quem clica 3–4/s. A pergunta 6 do escopo continua com o dono (se ele achar fraco jogando, a alavanca é `interval` de `metronome_l1`/`l2` em `shop.json`).

---

## 5. Medida de late game

### 5.1 Definições (valem para toda fase daqui em diante)
- **Fim do conteúdo:** o instante em que o jogador vence o último adversário que existe (hoje, o Kid).
- **Valor do clique:** `por_clique()` (sem crítico, sem FRENESI, com o Grito da equipe se comprado).
- **Renda/s:** `renda_sem_mão` = equipe/s + AUTO/s (o que entra sem a mão). A mão fica fora para a medida não depender de quantos cliques/s o jogador dá.
- **Tempo morto:** maior trecho com a próxima luta no vermelho **e** sem dinheiro para nada da LOJA (definição da Fase 4, `morto`). Medido na carreira 1 e na academia (todas as carreiras).
- **Próxima coisa:** maior trecho sem nenhum destes: compra na LOJA, aparelho, melhoria/técnica, caixa aberta ou luta. A equipe (Vizinho, Tio) não conta porque está sempre à venda.

### 5.2 X = 25% (a proposta de partida era 10%)
**1 clique ≥ 25% da renda/s no fim do conteúdo**, a 3, 4 e 5 cliques/s, nas duas artes.
- **Por que dá para garantir:** com o Grito da equipe (`crew_share` 1,0), 1 clique ≥ equipe/s; e 1 clique ≥ 1 auto-soco, enquanto o Metrônomo dá no máximo 2,5 autos/s (L5, 0,4 s). Logo `renda/s ≤ 3,5 × clique` e **o clique vale sempre ≥ 28,6%** da renda. 25% deixa 3,6 pontos de folga.
- **Por que não 10%:** 10% passaria com folga mesmo sem a melhoria nova (hoje o pior caso, Jiu-jitsu sem o Grito, é 14%). Uma meta que nunca acende não protege nada; 25% quebra se alguém, numa fase futura, acelerar o Metrônomo além de 0,4 s, tirar o Grito ou der bônus de equipe que não passe pelo clique.
- A 3/s, 25% significa que a mão rende pelo menos ~0,9× a renda sem a mão (3 × 0,25 × 1,2 de crítico): **clicar continua sendo metade do jogo** para quem clica pouco.

### 5.3 Tabela fixa (refazer em toda fase)
`fase5_sim.py f52`, 48 jogadores × 8 carreiras por perfil (3/s: 96), robô pega 80% das luvas douradas. "Morto" e "próxima coisa": maior trecho, mediana / p90.
| Perfil | 1 clique / renda (med; pior) | Mão / equipe / AUTO por s, no Kid (med) | Morto carreira 1 | Morto academia | Próxima coisa: garagem (carr. 1) | Próxima coisa: academia | Meta |
|---|---|---|---|---|---|---|---|
| Boxe 5/s | **72%; 71%** | 123K / 1,7K / 27K | 5:00 / **8:01** | 3:00 / **4:30** | 4:02 / **4:43** | 2:03 / **3:24** | fecha |
| Jiu-jitsu 5/s | **58%; 54%** | 73K / 5,5K / 17K | 5:00 / **8:01** | 3:30 / **5:00** | 4:02 / **4:43** | 1:47 / **3:28** | fecha |
| Boxe 4/s | **72%; 71%** | 99K / 1,7K / 27K | 6:00 / **9:01** | 3:30 / **5:00** | 4:57 / **5:16** | 2:31 / **3:53** | fecha |
| Jiu-jitsu 4/s | **60%; 52%** | 78K / 5,5K / 22K | 6:00 / **9:01** | 4:00 / **5:31** | 4:57 / **5:16** | 2:00 / **4:00** | fecha |
| Boxe 3/s | **72%; 62%** | 74K / 1,6K / 27K | 6:30 / **10:32** | 4:00 / **5:31** | 5:29 / **6:44** | 2:55 / **4:40** | **morto da carreira 1: 32 s acima** |
| Jiu-jitsu 3/s | **58%; 52%** | 49K / 5,5K / 22K | 6:30 / **10:32** | 5:01 / **7:00** | 5:29 / **6:44** | 2:40 / **4:37** | **morto da carreira 1: 32 s acima** |
| **Meta** | **≥ 25%** | — | **p90 ≤ 10:00** | **p90 ≤ 10:00** | **p90 ≤ 10:00** | **p90 ≤ 10:00** | |
Com 400 jogadores na carreira 1 (seção 7.3) o p90 a 3/s também dá 10:32. O "pior" do clique é sempre ≥ 52%, o dobro de X.

---

## 6. Robô x Dudu: **é o robô**

| | Derrotas no Dudu (400 jogadores, 5/s / 4/s) | Lutas no Dudu com chance < 90% |
|---|---|---|
| Fase 5 (sem caixa) | 3 / 10 | 2 / 3 |
| 5.1 (com caixa), robô antigo | 13 / 29 | 30 / 89 |
| 5.1 (com caixa), **robô corrigido** | **6 / 8** | 0 |
| **5.2 final** (Dinho ×1,4, bolsa), robô corrigido | **9 / 13** | 0 (todas as derrotas com chance ≥ 90%) |

- **O que acontece:** o robô olha a prévia a cada 30 s e luta no **primeiro olhar com chance ≥ 40%** (amarelo). A chance do Dudu sobe de 40% para 98% em poucas dezenas de segundos. Com a caixa, ele chega a cada olhar com ~3–6 s a menos de treino, e muitos olhares que eram 98–100% viram 89% ou 43–52%. Das 29 derrotas a 4/s, 9 foram com 43–52% e 11 com 89%.
- **Para o jogador real não muda nada:** o Dudu fica verde 3–6 s mais tarde, e a tela diz "ESPERE FICAR VERDE".
- **Correção (no robô, registrada):** contra o **1º adversário da carreira** o robô só luta no verde (`SIM_DUDU_VERDE=1`, padrão). Com isso as derrotas no Dudu voltam ao nível da Fase 5 (9 e 13 em 400 contra 3 e 10: diferença dentro do ruído, ~±3, e todas são o azar dos 2–3% que sobram no verde). Nenhum número do jogo mudou por causa do Dudu.
- Efeito colateral medido: a 3/s o robô passa a lutar com o Dudu aos ~4:15 em vez de ~1:45 (ele ficava ~2,5 min no amarelo). Não muda a 1ª derrota a 4–5/s.

---

## 7. Remedições (direto de `data/`)

Tudo com os números da seção 8.4. 23b e carreira 1: 400 jogadores; sequência: 48 jogadores × 8 carreiras (3/s: 96); controle: 48.

### 7.1 Critérios
| Critério | Meta | **Agora** | Situação |
|---|---|---|---|
| 2. L3 logo depois de chegar | ≤ 5 min, clique ≥ 2× | robô compra em 0:00–0:04 (p90 ≤ 3:00); clique ×2 | **fecha** |
| 4. Clique no fim do conteúdo | ≥ X = 25% | 52–72% (pior caso 52%) | **fecha** |
| 5. Tempo morto, carreira 1 (p90) | ≤ 10:00 | **8:01 / 9:01 / 10:32** (5/4/3 por s); era 10:01 / 11:31 / 13:32 | **fecha a 4–5/s; 3/s fica 32 s acima** (7.3) |
| 5. Tempo morto, academia (p90) | ≤ 10:00 | 4:30–7:01 | **fecha** |
| "Próxima coisa" (p90) | ≤ 10:00 | garagem ≤ 6:44 (era 12:40 a 3/s); academia ≤ 4:40 | **fecha** |
| **6. Jiu-jitsu 3/s no Kid (OBRIGATÓRIO)** | 1–2 carreiras (mediana), nunca depois do Boxe | **mediana 1 × 1**; média 1,31 × 1,38; Kid em ≤ 1 carreira 64% × 62% (96 jogadores) | **fecha** |
| 7. 23b | ≤ 25% (±2), nunca antes de 20:00 | **25,5% / 24,8%**; mais cedo **20:20** / 22:51 | **fecha** |
| 8. 1ª derrota da carreira 1 | 10–15 min | **13:14 / 14:44** | **fecha** |
| 8. Kid a 4–5/s | 1–2 carreiras | mediana **1** nas duas artes | **fecha** |
| 8. Boxe × Jiu-jitsu até o cinturão | ≤ 10% | sequência: **20,5% / 27,0% / 25,7%** (Jiu-jitsu na frente); controle (mesmos nós): 0,1% / 3,8% / 12,3% | **não fecha** (7.4) |
| Regressão: árvore fecha | 5ª–8ª | 5 (Boxe 5/s: **4**, p10 4) | **no limite; Boxe 5/s uma carreira antes** |
| Regressão: clique × assistido | ≥ 6× | 6,0× (4/s), 7,5× (5/s): o Grito não vale para o assistido | **fecha** |
| 9. Robô × Dudu | nível da Fase 5 | 9 / 13 em 400 (Fase 5: 3 / 10) | **fecha** (seção 6) |

### 7.2 Uma mudança por vez (o que mexeu em quê, carreira 1, 400 jogadores, 5/4/3 por s)
| Passo | 23b | Mais cedo | 1ª derrota | Morto p90 | Próxima coisa p90 |
|---|---|---|---|---|---|
| 5.1 (robô antigo) | 26,0% / 22,0% | 20:25 | 11:14 / 12:44 | 10:01 / 11:31 / 13:32 | — |
| + robô corrigido (Dudu) | 26,2% / 24,0% | 20:25 | 11:14 / 12:44 | 9:31 / 11:31 / 13:32 | 9:13 / 10:48 / 12:40 |
| + bolsa 0,33 | 25,2% / 25,0% | 20:48 | igual | 10:01 / 11:32 / 13:32 | 9:31 / 10:52 / 12:28 |
| + bolsa 0,5 | 22,5% / 24,2% | 20:50 | igual | igual | igual |
| + melhoria 3 a $150K (sem Dinho) | 28,8% / 25,5% | **16:51** | igual | 8:00 / 8:01 / 9:31 | ≤ 4:12 |
| + melhoria 3 a $250K (sem Dinho) | 23,5% / 24,0% | **18:48** | igual | 8:31 / 10:01 / 11:32 | ≤ 7:46 |
| + Dinho ×1,6 (sem melhoria) | 25,0% / 22,0% | 21:52 | 14:44 / **16:14** | 8:31 / 9:32 / 11:02 | ≤ 11:10 |
| **Final: bolsa 0,5 + $250K + Dinho ×1,4** | **25,5% / 24,8%** | **20:20** | **13:14 / 14:44** | **8:01 / 9:01 / 10:32** | **4:43 / 5:24 / 6:40** |
As linhas "melhoria 3" e "Dinho ×1,6" foram medidas com a bolsa 0,33. Metrônomo mais rápido (L1 1,0 s, L2 0,75 s) e mais barato ($50/$100): no máximo −30 s no p90; não entrou.

### 7.3 O que sobra no tempo morto a 3/s (32 s)
Três metas puxam em sentidos opostos: tudo o que encurta a parede do Muralha para quem clica 3/s também adianta o cinturão de quem clica 5/s com sorte (meta "nunca antes de 20:00") ou atrasa a 1ª derrota a 4/s (meta "até 15 min"). Com Dinho ×1,45 o 3/s fecha (10:02), mas a 1ª derrota a 4/s vai para 15:14; com Dinho ×1,4 é o inverso. Os valores andam em degraus de 30 s (o intervalo em que o robô olha a prévia). **Recomendo aceitar 10:32 a 3/s** (era 13:32); se o Diretor preferir fechar o 5 e soltar a 1ª derrota, é só `opp_fast` 29.000 / 159.500 / 8.700.

### 7.4 Boxe × Jiu-jitsu até o cinturão: não fecha, e a causa é a academia nova
| Teste (sequência, 32 jogadores, cinturão nas carreiras com arte, 5/4/3 por s) | Diferença |
|---|---|
| Garagem nova + academia da 5.1 | **1,1% / 5,5% / 10,1%** (fecha) |
| Garagem da 5.1 + academia nova | 16,2% / 23,0% / 33,7% (Jiu-jitsu na frente) |
| Final | 20,5% / 27,0% / 25,7% |
| Sem o nó ESTILO do Jiu-jitsu | 11,8% / 18,5% / 17,3% |
| Nó ESTILO do Boxe 1,0 (era 0,5) | 7,1% / 14,5% / 18,5% |
| L3 a $2.100 (fora do alcance da garagem) | igual (e o Jiu-jitsu a 3/s cai para 3 carreiras no Kid: descartado) |
| Rampa do Jiu-jitsu mais lenta / teto 1,0 | quase igual (6:52–6:55 contra 6:25) |
- **O que eu sei:** não é a garagem nova, nem a bolsa, nem o robô do Dudu. Com a academia nova o Kid cai mais (mediana 1 carreira), o Legado entra mais rápido (Jiu-jitsu ~1.750 por carreira contra ~1.520 do Boxe) e o Jiu-jitsu compra cedo os nós que multiplicam a equipe (`style_bjj`, `body_crew_2`), que pesam muito na garagem. No controle, com os mesmos nós para as duas artes, a diferença é 0,1% / 3,8% / 12,3%.
- **O que eu não fiz:** mexer na árvore (é da 5.4) ou enfraquecer o Jiu-jitsu (o critério 6 é obrigatório e hoje fecha por pouco: 1,31 × 1,38).
- **Opções para o Diretor:** (a) aceitar nesta fase, medindo pelo controle, e corrigir na 5.4 junto com a árvore grande (custo dos nós de equipe e do `style_bjj`); (b) eu sigo investigando nesta fase (mais 1 rodada, sem prazo garantido); (c) subir o Boxe na garagem (`style_boxing` 1,0 fecha a 5/s, não a 3–4/s) e remedir o critério 6.

### 7.5 Outros números
- **Kid na carreira da chegada:** 44–46% a 5/s, 29–33% a 4/s, 25–27% a 3/s (Fase 5: 32% a 5/s, meta antiga ≤ 35%). Com o Kid ×5 a 5/s cai para 29–44%, mas o critério 6 quebra.
- **Bolsa:** 3–5 por carreira; dá 3,1–5,6% do treino da carreira (mais no Jiu-jitsu e a 3/s, como deve).
- **Grito da equipe:** comprado em 99–100% das carreiras que vencem o Kid.
- **Curva no Kid** (mediana, por s): Boxe 5/s mão 123K, Metrônomo 27K, equipe 1,7K; Jiu-jitsu 3/s mão 49K, Metrônomo 22K, equipe 5,5K.
- **Controle** (1 carreira com arte, nós típicos, 5/s): cinturão 9:54 (Boxe) / 9:55 (Jiu-jitsu); Tonhão 13:22 / 12:55; Kid 17:51 / 18:25.

---

## 8. Contrato de dados (para o Programador)

### 8.1 `data/shop.json`
```json
"gloves": { "levels": [ "...L1 e L2 iguais...",
  { "id": "glove_l3", "cost": 1200, "click_multiplier": 2, "sprite_suffix": "_glove_l3", "name": "...", "description": "..." },
  { "id": "glove_l4", "cost": 2500, "click_multiplier": 2, "sprite_suffix": "_glove_l4", "name": "...", "description": "..." } ] },
"crew_click": { "id": "crew_click", "cost": 1500, "crew_share": 1.0, "icon": "icon_crew_click",
                "name": "...", "description": "...", "appears_as": "..." }
```
- `crew_click` ausente → a melhoria não existe (loja sem a linha). `cost` > 0, `crew_share` em [0, 100]; inválido → aviso e melhoria desligada.

### 8.2 `data/training.json` → `golden_event` (campos novos; os 5 antigos não mudam)
| Campo | Tipo | Padrão se faltar | Faixa |
|---|---|---|---|
| `crew_chance` | float | **0,0** (sem bolsa: o jogo da 5.1) | 0–1 |
| `crew_seconds` | float | 45 | 1–3600 |
| `crew_floor_clicks` | float | 40 | 0–100000 |
| `frenzy_sprite` | string | `event_golden_glove` | sprite do manifest |
| `crew_sprite` | string | `event_golden_crew` | sprite do manifest; se faltar o arquivo, usa o da ×7 com aviso |
Padrão 0,0 de propósito: sem o campo, nada muda. Mudar a chance ou o valor em `data/` muda o jogo sem código (critério 3).

### 8.3 Estado, sinais e save
- `GameState`: `evento_dourado_tipo: String` (`"frenzy"` | `"crew"`, sorteado ao aparecer), `valor_bolsa() -> float` (para a UI mostrar no hover), `pegar_evento_dourado()` passa a ramificar; sinal novo `bolsa_paga(ganho: float)`. O sinal `evento_dourado(duracao)` ganha o tipo (ou um `evento_dourado_tipo()` para a sala escolher o sprite).
- `renda_sem_mao() -> float` = `producao_total() + socos_por_segundo_metronomo() × por_auto_soco()` (público: a medida de late game e os testes usam).
- Grito da equipe: `crew_click_comprado: bool` na carreira; `pode_comprar_crew_click()`, `comprar_crew_click()`; entra em `menor_preco_loja()` enquanto não comprado.
- **Save v8:** `career.crew_click: bool` (ausente/inválido → `false`). `_migrar_7_para_8`: `career += { crew_click: false }`. `glove_level` já é validado contra `luvas.size()` (agora 4): save com L2 vê a L3 à venda; caixa de luva fechada de save antigo continua (critério 10). O evento dourado não vai no save (como hoje).

### 8.4 Tudo o que mudou em `data/` nesta fase
| Arquivo | Campo | Antes | Agora | Motivo |
|---|---|---|---|---|
| `shop.json` | `gloves.levels` | L1, L2 | + `glove_l3` $1.200 ×2, `glove_l4` $2.500 ×2 | escopo 2.1 |
| `shop.json` | `crew_click` | — | $1.500, `crew_share` 1,0 | escopo 2.3 |
| `training.json` | `golden_event` | 5 campos | + `crew_chance` 0,5, `crew_seconds` 45, `crew_floor_clicks` 40, `frenzy_sprite`, `crew_sprite` | escopo 2.2 |
| `opponents.json` | Tonhão F/A/R | 390K/150K/1,65M | 975K/375K/4,125M | escopo 2.1 |
| `opponents.json` | Kid F/A/R | 1,15M/2,3M/4,6M | 4,6M/8,05M/20,7M | escopo 2.1 + critério 6 |
| `opponents.json` | Dinho F/A/R | 20K/110K/6K | 28K/154K/8,4K | **mudei sem pedido** — critério 5 |
| `training.json` | `bag_leather`, `treadmill_motor`, `rope_beads` custo | 400.000 | 250.000 | **mudei sem pedido** — critério 5 |
Nomes e descrições novos em `shop.json` estão marcados "Provisório (Roteirista)".

### 8.5 Testes que travam valores e **vão falhar até serem atualizados**
- `tests/test_fight_data.gd:48–50` e `:89`: `luvas.size()` agora é **4**.
- `tests/test_fase5.gd:112` e `:115`: Tonhão `[975000, 375000, 4125000, 2500, 120]`, Kid `[4600000, 8050000, 20700000, 6000, 200]`.
- `tests/test_data.gd` (melhorias 3 e 4): `[250000, 3, 4000000, 3]`.
- `tests/data/fase3_casos.json` (gerado por `tools/sim/exportar_casos.py`): regerar se algum caso usa o Dinho.
- Testes novos: bolsa paga `max(45 × renda_sem_mao, 40 × por_clique)` e cai no atributo do foco; `crew_chance` 0 nunca sorteia bolsa e 1 sempre; Grito soma `crew_share × producao_total()` no clique e **não** no auto-soco; L3/L4 em caixa; save v7 → v8; tudo em pasta de save de teste.

---

## 9. Para o Roteirista e para a arte

### 9.1 Chaves para o Roteirista (tom pé no chão)
| Chave / campo | O que é | Limite |
|---|---|---|
| `shop.json → glove_l3.name / description` | luva de academia com marca (a arte já existe: escura, "Luva de marca") | nome ≤ 18, descrição ≤ 48 |
| `shop.json → glove_l4.name / description` | a melhor luva do bairro; ainda luva de academia, nada mágico | nome ≤ 18, descrição ≤ 48 |
| `shop.json → crew_click.name / description` | a equipe grita e o seu soco pega o embalo; efeito "+1 s da equipe por clique" | nome ≤ 18, descrição ≤ 48 |
| `ui_texts → shop_crew_click_effect` | efeito na LOJA, ex.: `CLIQUE +{n} (1 S DA EQUIPE)` | ≤ 28 |
| `ui_texts → golden_crew_hover` | hover da bolsa na sala: `{nome}: +{n} DE TREINO` | ≤ 32 |
| `ui_texts → golden_crew_toast` | ao pegar: ex.: `A TORCIDA PASSOU O CHAPÉU! +{n}` | ≤ 32 |
| `ui_texts → golden_crew_name` | nome final da "Bolsa da torcida" | ≤ 18 |
| `ui_texts → box_label / box_stamp` | sub-chaves `glove_l3`, `glove_l4` | como na 5.1 |

### 9.2 Lista de arte
| Item | Quem | O que entregar (padrão = conjunto da L3) |
|---|---|---|
| Luva L4 na sala | Artista de Personagens | `fighter_idle/punch/punch_b/hook/uppercut/rope/run_glove_l4` |
| Luva L4 na luta | Artista de Personagens | `fight_player_{idle,jab,hook,uppercut,heavy,body_shot,block,dodge,hit,hit_head,hit_body,hit_up,tired,ko,ko_back,ko_knees,victory}_glove_l4` (17 folhas, como a L3) |
| Luva L4 na UI | Diretor de Arte | `icon_glove_l4`, `cursor_glove_l4` (+ `_normal_x2/_pressed_x2/_normal_x3/_pressed_x3`), `art_hung_glove_l4`, `equipment/glove_l4`; `manifest.json → glove_l4` e `glove_shop.levels` |
| Bolsa da torcida | Diretor de Arte | `event_golden_crew`: mesmo tamanho e brilho da `event_golden_glove`, silhueta diferente (sacola/chapéu de moedas da torcida), legível de longe; usa os sons que já existem |
| Grito da equipe | Diretor de Arte | `icon_crew_click` (ícone da LOJA, mesmo tamanho dos outros) |
| Conferência | Diretor de Arte | a L3 que existe está no padrão atual (5.1)? |

---

## Resumo
- **Luvas:** L3 $1.200 ×2 (compra na chegada) e L4 $2.500 ×2 (depois do Tonhão); luva total ×16; na caixa, regras da 5.1.
- **Bolsa da torcida:** metade das luvas douradas (`crew_chance` 0,5); paga `max(45 s × (equipe/s + AUTO/s), 40 cliques)`. Só vale mais que a ×7 para quem quase não clica.
- **Grito da equipe:** $1.500, cada clique da mão soma 1 s da equipe (`crew_share` 1,0), sem teto, não vale para Metrônomo nem assistido.
- **Adversários:** Tonhão ×2,5 (975K/375K/4,125M); Kid ×4 com menos Agilidade (4,6M/8,05M/20,7M). **Mudei sem pedido:** Dinho ×1,4 e melhoria 3 dos aparelhos $250K, para o tempo morto da carreira 1.
- **X = 25%** (garantido pela fórmula: ≥ 28,6%); hoje 52–72%.
- **Fecha:** critério 6 (Jiu-jitsu 3/s no Kid: 1 × 1 carreira, média 1,31 × 1,38), 23b (25,5% / 24,8%, mais cedo 20:20), 1ª derrota (13:14 / 14:44), tempo morto da academia e "próxima coisa" (≤ 7:01 e ≤ 6:44), Dudu (é o robô; corrigido).
- **Não fecha:** tempo morto da carreira 1 a 3/s (10:32, era 13:32); Boxe × Jiu-jitsu até o cinturão na sequência (20–27%, causa isolada na academia nova, 7.4); árvore do Boxe 5/s fecha na 4ª. Metrônomo e Shift não mudaram.

---

## Decisões do Diretor (design 5.2)

Data: 2026-11-12. **Nenhum número muda.** O design vai para o Programador como está.

1. **Tempo morto da carreira 1 a 3/s (p90 10:32): aceito.**
   - Caiu 3 min (13:32 → 10:32), e os 32 s são um degrau do robô, que olha a prévia a cada 30 s.
   - Dinho ×1,45 troca uma meta furada por outra (1ª derrota a 4/s em 15:14). Fica o ×1,4.
   - Nesta fase, o critério 5 vale **≤ 10:00 a 4–5/s e ≤ 10:32 a 3/s, só na carreira 1**. Na academia continua ≤ 10:00.
   - Remedir na 5.3: o calendário muda o ritmo da carreira 1 de qualquer jeito.
2. **Boxe × Jiu-jitsu até o cinturão (20–27%): opção (a).** Aceito nesta fase e corrijo na 5.4.
   - Não à (c): o `style_boxing` 1,0 só fecha a 5/s e mexe no critério 6, que é obrigatório e fecha por pouco (1,31 × 1,38).
   - Não à (b): a causa já está isolada (nós de equipe do Jiu-jitsu + academia nova). Mais uma rodada sem prazo não muda a decisão.
   - Nesta fase o critério 8 é medido pelo **controle** (mesmos nós): 0,1% / 3,8% / 12,3%. Os 12,3% a 3/s ficam registrados como ruído aceito.
   - **Vira critério obrigatório da 5.4:** na sequência, Boxe × Jiu-jitsu até o cinturão ≤ 10% a 3, 4 e 5/s. As alavancas são o custo do `style_bjj` e do `body_crew_2`, não o Kid.
3. **Árvore fecha na 4ª carreira com Boxe a 5/s: aceito.** A mediana geral é 5 (dentro da meta). O Boxe a 5/s é o perfil mais eficiente, e a árvore é refeita na 5.4. Também vira um ponto a remedir na 5.4.
4. **Kid na carreira da chegada a 5/s (44–46%): aceito.** A meta antiga de ≤ 35% sai. Fica a do critério 8: Kid em 1–2 carreiras (mediana) a 4–5/s, que fecha.
   - Quem clica 5/s e compra a L4 merece ter metade das chances de vencer o chefe na 1ª tentativa. O Kid ×5 quebraria o critério 6.
   - Esse ponto entra no item 3 da validação do dono ("o Kid ficou fácil?").
5. **O que mudou sem pedido: aceito**, porque são só números em `data/` e cumprem a regra da 2.5.
   - **Dinho ×1,4** (28K / 154K / 8,4K): a 1ª derrota continua em 10–15 min (13:14 / 14:44).
   - **Melhoria 3 a $250K**: a "próxima coisa" da garagem sai de 12:40 para 6:44. A nota R8 da Fase 5 ("a melhoria 3 é a 1ª compra grande da academia") deixa de valer. Agora são a L3 e o Grito.
   - **Condição:** o cinturão mais cedo ficou em 20:20, só 20 s acima do limite. Se no 23b do QA (400 jogadores) **alguém chegar antes de 20:00**, o Designer sobe `bag_leather`, `treadmill_motor` e `rope_beads` para **$300.000**, mantém o Dinho ×1,4 e remede os critérios 5, 7 e 8.
6. **Robô × Dudu:** a correção do robô (`SIM_DUDU_VERDE=1`) está aceita. Na diferença que sobra (9/13 contra 3/10), as derrotas são todas com chance ≥ 90%, então é azar e não jogo.
