# Fase 5.3 — Calendário da campanha: design

Dono: Designer de Jogo. Data: 2026-11-12. Branch: `fase-5.3`.
Base: `docs/fases/fase5.3-escopo.md` (aprovado de antemão), `fase5.2-design.md`, `fase5.2-revisao.md` (seções 1 e 5).
Simulador: `tools/sim/fase5_sim.py`, seções novas `b23c` (23b com calendário, 2.000 jogadores) e `f53` (calendário + as tabelas da 5.2). Tudo lido de `data/`. Rodar:
`"C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase5_sim.py b23c f53`
(`SIM_CAL=0` desliga o calendário e roda o jogo da 5.2, para comparar.)

**Os números deste documento já estão em `data/`** (lista na seção 7.4).

---

## 1. Calendário

### 1.1 Relógio e dia
- `segundos_campanha` (float, por carreira) anda **só quando a sala está ativa** (seção 2), sempre junto com a equipe.
- `dia = 1 + floor(segundos_campanha / seconds_per_day)`. A carreira começa no **Dia 1**.
- **`seconds_per_day` = 30.** Uma campanha dura 23–31 dias na mediana (p90: 40–54). Com 30 s, "Faltam 3 dias" = 1,5 min (dá para gastar o que tem) e "Falta 1 dia" = 30 s (curto o bastante para ninguém ficar esperando a faixa).

### 1.2 Data de cada luta
**`data = dia_da_última_luta + prep_days(próximo adversário)`.** No começo da carreira, `dia_da_última_luta = 1`.
- Lutar antes é livre: a data seguinte conta **do dia em que a luta aconteceu**. Derrota encerra a carreira (como hoje).
- `Faltam N dias = data − dia`. **O dia chega** quando `dia ≥ data`, isto é, quando `segundos_campanha = (data − 1) × 30`. O relógio **trava exatamente aí** e não passa nem 1 quadro do dia.
- Uma luta no meio de um dia (ex.: dia 7,6) conta a partir do dia 7: a folga efetiva fica entre `prep − 1` e `prep` dias. É de propósito: conta inteira, igual ao que o HUD mostra.
- **Tonhão** conta do dia do cinturão (a mudança já é automática ao fechar a vitória). É a mesma regra, sem exceção.

| # | id | Adversário | **`prep_days`** | Em sala | Verde (robô paciente, dias depois da luta anterior; med / p90) | Papel da data |
|---|---|---|---|---|---|---|
| 1 | `opp_warmup` | Dudu | **12** | 6:00 | carreira 1: 6–8 / 7–9 | folgada: ninguém chega no dia |
| 2 | `opp_strong` | Brutão | **13** | 6:30 | carreira 1: 9–12 / 10–12 | folgada (cabe o p90 da carreira 1 a 3/s) |
| 3 | `opp_fast` | Dinho | **10** | 5:00 | carreira 1: 16–20 / 17–22 | **a parede da campanha 1**: o jogador chega amarelo (5/s) ou vermelho (3–4/s) e decide |
| 4 | `opp_tank` | Muralha | **16** | 8:00 | carreira 1: 15–19 / 16–20 | quem passou do Dinho tem chance real de cinturão |
| 5 | `opp_gym_1` | Tonhão | **24** | 12:00 | chegada: 8–11 / 10–21 | **1ª da academia, a mais folgada**: cobre escolher a arte, abrir a L3 e comprar o Grito |
| 6 | `opp_gym_2` | Kid | **16** | 8:00 | chegada: 8–13 / 10–16 | o chefe; folga do tamanho do Jiu-jitsu a 3/s (ver 6.5) |

Curva esperada (carreira 1, 4/s, robô paciente): Dia 1 começa → Dudu ~Dia 8 (3:30) → Brutão ~Dia 18 (8:30) → **data do Dinho Dia 28 (13:30)**, que chega no vermelho em 9 de 10 jogadores: passa o posto (100%) ou arrisca. A 5/s, parte chega no Dinho amarelo e luta; quem vence pega o Muralha até 16 dias depois. Da carreira 2 em diante (com árvore) quase tudo é vencido antes da data.

### 1.3 Depois do Kid
- Não há próxima luta: `fight_day = −1`. O HUD troca a data por **"Campanha completa"** e o relógio **some** (o dia para de contar; `segundos_campanha` congela).
- Passar o posto continua no botão de sempre (100% + bônus do cinturão). O texto `no_more_fights_gym` passa a falar em campanha (seção 8).

---

## 2. Quando o relógio anda e quando para

**Regra única (anti-abuso):** existe **uma** condição e **tudo** que gera treino ou passa o dia depende dela. Nenhum sistema pode olhar outra condição.

`sala_ativa() = fim.is_empty() and luta.is_empty() and not escolha_arte_pendente() and not modal_aberto and not no_dia_da_luta()`

Com `sala_ativa()` falso, param **juntos**: relógio da campanha, equipe (`producao_total` não entra), Metrônomo, assistido (Shift), clique (mão e Espaço), luva dourada (a espera, o tempo visível **e** o FRENESI que sobra), bolsa, relógio do Jiu-jitsu (`arte_segundos`), tempo morto e a dica de passar o posto. O selo de risco pode continuar calculando (é só leitura).

**Isso muda uma coisa de hoje:** hoje a equipe treina na luta, na prévia, na vitória, na escolha da arte e no cartão de início. **Passa a não treinar.** É o que fecha a brecha "abro a prévia e a equipe treina sem o dia passar". O simulador já roda assim (a equipe não ganha na luta) em todas as medidas da seção 6; o efeito sozinho é pequeno (a luta dura 5–20 s e a equipe é 1–8% do treino de quem clica).

| Tela / estado | Relógio e equipe | Por quê |
|---|---|---|
| Sala livre (garagem ou academia) | **andam** | é o jogo |
| Painel TREINO / LOJA (abas, rolagem, hover, compra) | **andam** | é parte da sala, não cobre o alvo |
| Painel de atributos, caixa de informação, dica, toasts | **andam** | sala |
| Caixa de equipamento sendo aberta | **andam** | sala (a mão está na caixa, a equipe segue) |
| Luva dourada / bolsa visível | **andam** | sala |
| Faixa de aviso (3 dias, 1 dia) | **andam** | não é janela, não bloqueia o clique |
| Jogo sem foco ou minimizado | **andam** | regra do dono; o Shift solta como hoje |
| Depuração F12 (só build de debug) | **andam** | não é modal; ganha botões de dia (7.3) |
| Prévia aberta pelo LUTAR! | **param** | janela |
| Prévia do dia da luta | **param** | o dia |
| Confirmação de Passar o posto | **param** | janela |
| Luta (arena) | **param** | luta |
| Vitória / cinturão | **param** | janela |
| Escolha da arte | **param** | janela (`escolha_arte_pendente`) |
| Cartão de início ("o que você trouxe") | **param** | hoje só pausa o Metrônomo; passa a pausar tudo (fecha com 1 clique) |
| Fim de carreira / campanha e Árvore | **param** | já é congelado hoje (`fim` pendente) |
| Jogo fechado | **param** | sem progresso offline (fase 13; ver 3.5) |
| Qualquer janela futura (opções etc.) | **param** | toda janela abre por `Fluxo._abrir` → `definir_modal(true)` |

**Teste automático (critério 6):** para cada estado "param", abrir o estado, rodar `tick(10 s)` e conferir que `segundos_campanha`, `treino`, atributos, `_acc_metronomo`, `frenesi_restante` e `arte_segundos` não mudaram; para cada "andam", que relógio e equipe andaram juntos (10 s de relógio = 10 s de `producao_total`).

---

## 3. O dia da luta

### 3.1 O que acontece
1. `segundos_campanha` chega em `(data − 1) × 30` → `no_dia_da_luta()` fica verdadeiro e o relógio trava ali.
2. Fecha o que estiver aberto **sem perder nada**: o cartão de início fecha; a LOJA/TREINO não tem estado; a luva dourada visível congela e volta depois da luta.
3. Abre a **prévia do dia**: a mesma prévia de hoje (risco, tática, motivo), com 2 botões: **LUTAR** e **PASSAR O POSTO**. Sem "voltar a treinar", sem X, Esc não fecha.
4. Toca o som do aviso de 1 dia. Se a janela do jogo está sem foco: `DisplayServer.window_request_attention()` (o ícone pisca na barra de tarefas).
5. O jogo espera o tempo que for. Nenhuma luta começa sozinha (critério 3: 10 min parado e nada muda).

| No dia | O que acontece |
|---|---|
| Relógio da campanha | **para** |
| Clique e Espaço | **param** |
| Equipe, Metrônomo, assistido | **param** |
| Luva dourada (espera, visível, FRENESI) e bolsa | **congelam**; voltam depois da luta |
| Caixas fechadas | **ficam fechadas** (sem clique); nada se perde |
| LOJA / TREINO | **fechadas** pela prévia. A luta usa só os atributos, então comprar no dia não mudaria a luta. O dinheiro e o treino ficam para depois |

### 3.2 As duas saídas
- **LUTAR:** igual a hoje (tática, `lutar()`). Vitória → a próxima data conta deste dia. Derrota → fim de carreira (50% do Legado, como hoje).
- **PASSAR O POSTO:** abre a confirmação de aposentar com o texto novo. **Confirmar** = `aposentar()` de hoje: 100% do pote + bônus do cinturão (critério 4). **Cancelar** volta para a **prévia do dia**, não para a sala.
- Contra o clique sem querer: a confirmação é obrigatória, o foco padrão fica no botão de cancelar (como hoje) e os 2 botões da prévia não ficam colados (UI/UX decide o espaço).
- Passar o posto no dia conta como aposentadoria para tudo (Honra da 6c inclusive). Com o pote em 0 o botão continua lá e a confirmação mostra "VOCÊ LEVA 0 DE LEGADO" (texto de hoje).

### 3.3 Fora do dia
- **LUTAR!** abre a prévia de sempre a qualquer hora (com VOLTAR A TREINAR).
- O botão **APOSENTAR** vira **PASSAR O POSTO**, com a mesma regra e a mesma confirmação.

### 3.4 Avisos
| Quando | O quê | Dado |
|---|---|---|
| `Faltam N dias` vira **3** | faixa, sem som, ~3 s | `calendar.warn_days` = 3 |
| `Faltam N dias` vira **1** | faixa **+ som** (o alerta que já existe); o ícone pisca se estiver sem foco | `calendar.warn_sound_days` = 1 |
| O dia chega | prévia do dia (3.1) | — |
- Cada aviso dispara **uma vez** por data. Se o jogador luta antes, não dispara. Ao reabrir o jogo com `Faltam ≤ 3`, a faixa aparece uma vez.
- O HUD mostra **sempre**: `Faltam N dias · {nome}` + o selo de risco que já existe. Com 1 dia: `Falta 1 dia`. No dia: `Hoje · {nome}`.
- Critério 2 ("ver as duas faixas em ≤ 1 campanha"): na campanha 1, a 3–4/s, 9 em 10 jogadores chegam no dia do Dinho, então as duas faixas aparecem antes dele. A 5/s parte deles luta antes; o QA usa os botões de dia da depuração (7.3).

### 3.5 Para a fase 13 (offline)
`calendar.offline_stops_at_fight_day = true`: o ganho offline **nunca** passa de `(data − 1) × 30 − segundos_campanha`. O jogo nunca pula para o dia de uma luta, nem abre direto nele por causa do offline. Nesta fase o campo só existe e é validado (bool).

---

## 4. A dica de aposentar da academia: **muda**
Hoje: "APOSENTAR AGORA LEVA {n} DE LEGADO" depois de 300 s seguidos com o adversário da academia PERIGOSO (`gym_retire_hint_seconds`).
- **O problema com o calendário:** ela repete o que a data já diz e aparece numa hora arbitrária (5 min), que nada tem a ver com o dia.
- **Agora:** aparece quando **`Faltam ≤ retire_hint_days` (3)**, a próxima luta está **PERIGOSA** (vermelho) **e** o pote é > 0, **na garagem e na academia**. O texto novo é do Roteirista ("PASSAR O POSTO AGORA LEVA {n} DE LEGADO").
- Na prática ela vira a 2ª linha do aviso de 3 dias, só para quem está no vermelho. Quem está verde ou amarelo não vê.
- `gym_retire_hint_seconds` sai de uso. O Programador remove a leitura; o campo pode ficar no JSON sem efeito.

---

## 5. Save v9

### 5.1 Campos novos (`state.career`)
| Campo | Tipo | Padrão / inválido | O que é |
|---|---|---|---|
| `campaign_seconds` | float ≥ 0 | 0 | relógio da campanha |
| `fight_day` | int | `dia + prep(próximo)`; −1 sem próxima luta | data da próxima luta (dia da campanha) |
- `fight_day` é **gravado**, não recalculado de `data/`: se uma folga mudar numa versão nova, a data que o jogador já viu não pula.
- `fight_day` inválido (≤ 0 e ≠ −1, ou > dia + 999) → recalcula com a folga cheia a partir do dia atual.
- Ao vencer: `fight_day = dia + prep(próximo)`, ou −1 depois do Kid. Nova carreira: `campaign_seconds = 0`, `fight_day = 1 + prep(Dudu)`.
- Save aberto com `dia ≥ fight_day` (fechou o jogo no dia): abre direto na prévia do dia.

### 5.2 Migração `_migrar_8_para_9`
| Save v8 | Resultado |
|---|---|
| Carreira em andamento, com próxima luta | `campaign_seconds = 0` (Dia 1), `fight_day = 1 + prep(próximo adversário)`: **folga cheia** a partir do dia em que o save é aberto |
| Kid já vencido (escada completa na academia) | `fight_day = −1` → "Campanha completa" |
| Tela de fim pendente | `campaign_seconds = 0`, `fight_day = 1 + prep(Dudu)` (a nova carreira zera de qualquer jeito) |
| Luta pendente (fechou no meio da luta) | como "em andamento"; ao concluir, a data seguinte conta do Dia 1 |
- **Nada mais muda:** caixas, luvas, Grito, Metrônomo, Legado, árvore, arte e local seguem iguais (critério 13).
- Os testes de migração usam a pasta de save de teste, nunca o save real.

---

## 6. Simulação

### 6.1 O que mudou no simulador (registrado)
- **Relógio:** `clk` anda só nos passos de sala; a luta não anda o relógio. **A equipe não treina na luta** (antes ganhava `equipe/s × duração`) e o FRENESI não corre na luta.
- **Robô novo (padrão), pedido no escopo:**
  - **antes da data:** olha a prévia a cada 30 s e luta **só no verde** (≥ 90%), contra qualquer adversário;
  - **no dia:** decide na hora. Amarelo ou verde → luta. Vermelho → **passa o posto** se o pote > 0 (senão luta);
  - passar o posto no vermelho ensina o robô como uma derrota (na carreira seguinte ele é cauteloso com aquele adversário);
  - sai a regra antiga "aposenta depois de 8 min no vermelho na academia": quem decide agora é o dia.
- **Variante "apressado"** (`SIM_ANTES=amarelo`): antes da data luta no amarelo (o robô da 5.2, que só espera o verde contra o 1º adversário e contra quem já o derrubou). Os dois robôs cercam o jogador real: o paciente espera o verde, o apressado arrisca no amarelo.
- Outras alavancas: `SIM_DIA=luta` (no dia luta sempre), `SIM_CAL=0` (jogo da 5.2), `SIM_PREP="12,13,10,16,24,16"`, `SIM_CAL_SPD=30`.

### 6.2 Critérios (robô paciente, salvo indicação)
| Critério | Meta | **Agora** | Situação |
|---|---|---|---|
| 8. 23b, 2.000 jogadores: cinturão na 1ª | ≤ 25% (±2) | **26,4% / 0,2%** (5/s / 4/s); apressado 16,6% / 0,2% | **fecha** (dentro dos ±2) |
| 8. 23b: mais cedo / antes de 20:00 | ≥ 19:30 / ≤ 1% | **20:44** (p1 21:00); apressado 20:15 (p1 20:45); **0** antes de 20:00 | **fecha**, sem a alavanca de $300K |
| 9. Tempo morto, carreira 1, 3/s (p90) | ≤ 10:32 (desejável ≤ 10:00) | **6:00** (era 10:32); 4/s 5:30; 5/s 7:43 só na garagem | **fecha, e fecha o desejável** |
| 9. Tempo morto, academia (p90) | ≤ 10:00 | 4:00–6:30 | **fecha** |
| 9. 1ª derrota / fim da carreira 1 (5/s; 4/s) | 10–15 min | 1ª derrota **13:39 / 14:09**; fim da carreira 1 (derrota ou passou o posto) **13:39 / 14:09**; apressado 13:14 / 13:56 | **fecha** |
| 10. Kid (carreiras depois da chegada, mediana) | 1–2 | **paciente: 0** (79–98% vencem na carreira da chegada); **apressado: 1** (42–52% na chegada) | **ver 6.5** |
| 10. Jiu-jitsu 3/s × Boxe 3/s no Kid | não depois do Boxe | mediana **0 × 0** (paciente) e **1 × 1** (apressado); média 0,06 × 0,02 e 0,81 × 0,75 (2–3 jogadores em 48) | **fecha na mediana**; a média empata dentro do ruído |
| 10. Clique no fim do conteúdo | ≥ 25% da renda | **54–72%** (pior 54%) | **fecha** |
| 11. Lutas no dia × antes | 4–5/s: maioria antes; 3/s: ≤ 1 em 4 no dia em vermelho | 96–97% antes; vermelho no dia **2,3%** das lutas a 3/s | **fecha** (6.3) |
| Regressão: árvore fecha | 5ª–8ª | **4ª** em todos (paciente); 4ª–5ª (apressado) | **uma carreira antes** (6.6) |
| "Próxima coisa" (p90) | ≤ 10:00 | garagem ≤ 4:33; academia ≤ 4:56 | **fecha** |

### 6.3 Lutas antes da data × no dia (critério 11)
`f53`, 48 jogadores × 8 carreiras por perfil, todas as lutas.
| Perfil | Lutas | Antes da data | No dia | No dia: verde / amarelo / vermelho | **Vermelho no dia / lutas** | Passou o posto no dia | Derrotas no dia / derrotas |
|---|---|---|---|---|---|---|---|
| Boxe 5/s | 2.092 | 96% | 4% | 3 / 60 / 11 | 0,5% | 11 | 31 / 73 |
| Jiu-jitsu 5/s | 2.122 | 97% | 3% | 3 / 53 / 18 | 0,8% | 18 | 29 / 65 |
| Boxe 4/s | 2.024 | 97% | 3% | 5 / 6 / 43 | 2,1% | 43 | 5 / 52 |
| Jiu-jitsu 4/s | 2.057 | 97% | 3% | 5 / 6 / 43 | 2,1% | 43 | 5 / 48 |
| Boxe 3/s | 2.082 | 97% | 3% | 3 / 4 / 48 | 2,3% | 48 | 3 / 37 |
| Jiu-jitsu 3/s | 2.051 | 96% | 4% | 20 / 6 / 48 | 2,3% | 48 | 5 / 51 |
| *Apressado 3/s (Boxe; JJ)* | 1.897; 1.902 | 96%; 95% | 4%; 5% | 10/20/45; 21/24/47 | 2,4%; 2,5% | 45; 47 | 13/154; 17/156 |

**Onde o dia acontece** (% das lutas com aquele adversário que foram no dia; entre parênteses, no vermelho):
| Perfil | Dudu | Brutão | Dinho | Muralha | Tonhão | Kid |
|---|---|---|---|---|---|---|
| 5/s (Boxe; JJ) | 0% | 0% | 13% (2%) | 5% (1%) | 0% | 3% (0%); 2% (2%) |
| 4/s | 0% | 0% | 14% (12%) | 0% | 0% | 0% |
| 3/s (Boxe; JJ) | 0% | 1% | 14% (13%) | 0% | 0% | 0%; 6% (0%) |

- **Leitura:** o dia é raro no geral (3–4% das lutas) e fica concentrado onde deve: no **Dinho da campanha 1**, que é 1 luta por jogador. Na campanha 1, a 3–4/s, 9 em 10 jogadores chegam no dia do Dinho no vermelho; a 5/s, parte chega no amarelo e luta. Da campanha 2 em diante, com a árvore, quase tudo é vencido antes.
- **Mudei a meta de partida?** Não. "Maioria antes" e "≤ 1 em 4 no vermelho" fecham com folga. Escrevo o motivo de não apertar mais: com o robô paciente o tempo até o verde é quase fixo por perfil (p25–p75 em 1–2 dias), então qualquer data mais curta vira um **corte por velocidade de clique** e pega primeiro o Jiu-jitsu (6.5). A data só serve de parede onde a parede já existia (Dinho/Muralha na campanha 1).
- **Risco "data folgada demais não serve":** ela serve na campanha 1 (é o novo fim dela, no lugar do "esperar no vermelho até perder") e para quem joga mais devagar que o robô ou fica AFK. Para quem joga bem nas campanhas seguintes, a data é só um relógio à vista. É o que o escopo pede ("quem joga bem chega verde").

### 6.4 23b com 2.000 jogadores (critério 8)
`b23c`, carreira 1, 2.000 jogadores por perfil.
| Robô / perfil | Cinturão na 1ª | Mais cedo | p1 | Antes de 19:30 | Antes de 20:00 | Fim da carreira 1 (med; p10–p90) | 1ª derrota (med) | Passou o posto na carreira 1 | Derrotas no Dudu |
|---|---|---|---|---|---|---|---|---|---|
| Paciente 5/s | **26,4%** | **20:44** | 21:00 | 0 | 0 | 13:39 (12:26–21:39) | 13:39 | 510 | 49 (2,5%) |
| Paciente 4/s | 0,2% | 22:58 | — | 0 | 0 | 14:09 (13:26–14:56) | 14:09 | 1.718 | 70 |
| Paciente 3/s (só referência) | 0% | — | — | 0 | 0 | 15:26 (14:26–15:56) | — | 1.891 | 75 |
| Apressado 5/s | 16,6% | 20:15 | 20:45 | 0 | 0 | 13:14 (8:14–21:16) | 13:14 | 569 | 49 |
| Apressado 4/s | 0,2% | 22:58 | — | 0 | 0 | 13:56 (12:56–14:56) | 9:44 (poucas) | 1.648 | 70 |
| *5.2 (sem calendário, 2.000)* | *26,6% / 26,2%* | *19:48* | — | — | *> 0* | — | *13:14 / 14:44* | — | — |
- **26,4% fica dentro de 25 ± 2.** O 4/s quase não pega mais o cinturão na 1ª (0,2%, era 26,2%): a 4/s o Dinho chega no dia no vermelho em 9 de 10 jogadores. É o efeito pedido ("a data é a parede"), mas deixa a meta do 23b sendo cumprida só pelo 5/s.
- O mais cedo **subiu de 19:48 para 20:44**: ninguém mais pega o cinturão por sorte no amarelo cedo. A alavanca da melhoria 3 a $300K **não precisou**.
- Derrotas no Dudu: 2,5–3,5% (5.2: 2,2–3,2%), todas no verde (azar).

### 6.5 Kid: a folga não consegue segurar o chefe sem punir o Jiu-jitsu
| Folga do Kid (dias) | Kid na carreira da chegada (Boxe 5/s / JJ 5/s / Boxe 3/s / **JJ 3/s**) | Kid, carreiras depois da chegada, JJ 3/s (med; média) |
|---|---|---|
| 8 | 69% / 21% / 2% / **0%** | **nunca** (2% chegam lá) |
| 10 | 75% / 69% / 42% / **8%** | 3; 3,23 (Boxe 3/s: 1; 0,98) |
| **16 (escolhido)** | 88% / 79% / 98% / **94%** | **0; 0,06** (Boxe: 0; 0,02) |
| 999 (sem data) | 94% / 96% / 98% / 94% | 0 |
- **Por que o Kid ficou fácil para o robô paciente:** não é o calendário. Na 5.2 o robô lutava no **primeiro amarelo** (40%) e aposentava depois de 8 min no vermelho; é isso que deixava o Kid em "1 carreira depois da chegada". Um jogador que espera o verde já vencia o Kid na chegada na 5.2 (o verde vem 8–13 dias = 4–6,5 min depois do Tonhão). O robô apressado, com o calendário, dá **mediana 1** e 42–52% na chegada (igual à 5.2: 25–46%).
- **Por que não apertei a data:** o Jiu-jitsu leva 2–3 dias a mais que o Boxe para ficar verde no Kid (a curva dele cresce com o tempo de arte), em todas as carreiras. Uma data abaixo de ~15 dias trava o Jiu-jitsu a 3/s **para sempre** (com 8 dias: 0 de 48 vencem em 8 carreiras). O critério 6 da 5.2 (Jiu-jitsu a 3/s no Kid) é obrigatório.
- **Recomendo:** aceitar nesta fase (o critério 10 fecha na mediana com o robô apressado e "Kid na 1ª ou 2ª carreira" fecha com os dois). Se o dono achar o Kid fácil (ponto 4 da validação), a alavanca é o **Kid**, não a data: subir F/A/R do Kid na 5.4 junto com a árvore grande e remedir o Jiu-jitsu a 3/s.

### 6.6 Árvore fecha uma carreira antes
- Paciente: 4ª carreira em todos os perfis (5.2: 5ª; Boxe 5/s 4ª). Apressado: 4ª–5ª.
- Causa: **passar o posto no dia vale 100%** e substitui a derrota (50%) no fim da campanha 1 (a 3–4/s, 43–45 de 48 jogadores passam o posto no Dinho). O Legado da campanha 1 dobra.
- É consequência direta da regra central do escopo ("passar o posto sempre é melhor que perder"). Não mexi: a árvore é refeita na 5.4 e a meta "5ª–8ª" entra na remedição de lá.

### 6.7 AFK: quanto perde quem deixa o jogo aberto e sai
Medida: a cada 30 s de sala de todas as campanhas, quanto falta para a data; um AFK de L minutos que começa ali perde `max(0, L − falta)` de equipe + Metrônomo (o jogo para no dia).
| Perfil | Falta até a data (med; p10) | AFK 10 min perde | AFK 30 min | AFK 60 min |
|---|---|---|---|---|
| 5/s | 5:30; 3:00 | 4,2–4,4 min (43%) | 24 min (81%) | 54 min (90%) |
| 4/s | 5:30; 3:00 | 4,3–4,4 min (44%) | 24 min (81%) | 54 min (90%) |
| 3/s | 5:00–5:30; 2:30 | 4,5–4,7 min (46%) | 25 min (82%) | 55 min (91%) |
- **Em jogo ativo, isso vale pouco:** equipe + Metrônomo são 19% (Boxe 5/s) a 34% (Jiu-jitsu 3/s) do treino de quem clica. Um AFK de 10 min perde o equivalente a **0,8–1,6 min de jogo ativo**; um de 30 min, **4,6–8,3 min**. Nada que já tinha se perde: atributos, dinheiro, caixas e a data ficam onde estavam.
- **Não subi a folga por causa do AFK.** Folga maior só empurra a data; o AFK longo para do mesmo jeito (com 60 min, perde 90% com qualquer folga do tamanho de uma campanha). E folga maior apaga a parede da campanha 1. As proteções são as do escopo: data sempre à vista, faixa com som a 1 dia, ícone piscando e o jogo esperando sem perder nada.

### 6.8 O que eu testei e não serve (23b com 400 jogadores, 5/s / 4/s)
| Folgas (Dudu, Brutão, Dinho, Muralha) | Cinturão na 1ª | Fim da carreira 1 (med) | Por que não |
|---|---|---|---|
| 8, 10, 14, 16 | 48% / 4,5% | 15:09 / 8:43 | Dudu e Brutão curtos demais: 3/s perde para o Dudu (22%) |
| 6, 8, 12, 14 | 0% / 0% | 7:13 / 3:13 | idem, pior |
| 12, 14, 12, 14 | 10% / 0% | 14:40 / 15:39 | 4/s acaba depois de 15 min |
| 12, 13, 12, 15 | 26,5% / 0,2% | 14:39 / 15:39 | idem |
| 12, 13, 11, 15 | 20% / 0% | 14:09 / 15:09 | 4/s 9 s acima de 15 min |
| 12, 13, 10, 12 | 0% / 0% | 13:39 / 14:09 | ninguém mais pega o cinturão na 1ª |
| **12, 13, 10, 16** | **25,0% / 0,8%** | **13:39 / 13:56** | **escolhido** (2.000 jogadores: 26,4% / 0,2%) |
| 12, 13, 10, 18–20 | 37–38% / 3,5–6,5% | 13:26 / 13:56 | passa de 25% |
- O Brutão não mexe em nada (é vencido antes da data em 99% dos casos): 13 ou 14 dá o mesmo resultado.
- **Alavanca da melhoria 3 a $300K: não precisou.** O cinturão mais cedo subiu de 19:48 (5.2, 2.000 jogadores) para 20:44 (paciente) e 20:15 (apressado).

---

## 7. Contrato de dados (para o Programador)

### 7.1 `data/career.json`
```json
"calendar": { "seconds_per_day": 30, "warn_days": 3, "warn_sound_days": 1, "retire_hint_days": 3,
              "offline_stops_at_fight_day": true }
```
| Campo | Tipo | Padrão se faltar | Faixa |
|---|---|---|---|
| `seconds_per_day` | float | **0 = sem calendário** (o jogo da 5.2: sem data, sem dia, HUD como hoje) | 0 ou 5–3600 |
| `warn_days` | int | 3 | 0–30 (0 = sem faixa) |
| `warn_sound_days` | int | 1 | 0–30 |
| `retire_hint_days` | int | 3 | 0–30 (0 = sem dica) |
| `offline_stops_at_fight_day` | bool | true | — (lido na fase 13) |
- `gym_retire_hint_seconds`: sai de uso (seção 4).

### 7.2 `data/opponents.json` → `prep_days` (int, por adversário)
`opp_warmup` 12, `opp_strong` 13, `opp_fast` 10, `opp_tank` 16, `opp_gym_1` 24, `opp_gym_2` 16.
- Faixa 1–999. Ausente ou inválido → **14** com aviso (nunca 0: data no dia da luta anterior é proibida).
- Mudar o número muda o jogo sem código (critério 7).

### 7.3 Estado, sinais e depuração
- `GameState`: `segundos_campanha: float`, `fight_day: int`; `dia_campanha() -> int`; `dias_para_luta() -> int` (−1 sem data); `no_dia_da_luta() -> bool`; `sala_ativa() -> bool` (seção 2, **a única** condição de tick); `campanha_completa() -> bool`.
- `lutar()` e `aposentar()` funcionam no dia (é o único jeito de sair dele). `aposentar()` no dia = Passar o posto.
- Sinais novos: `dia_mudou(dia: int)`, `aviso_data(dias: int)` (3 e 1), `dia_da_luta_chegou()`, `campanha_completa_mudou()`.
- Depuração F12 (build de debug): **+1 dia**, **ir para a véspera** (`Faltam 1`) e **ir para o dia**. Para o QA testar avisos, dia e os 10 min parado sem esperar.

### 7.4 Tudo o que mudou em `data/` nesta fase
| Arquivo | Campo | Antes | Agora | Motivo |
|---|---|---|---|---|
| `career.json` | `calendar` | — | `seconds_per_day` 30, `warn_days` 3, `warn_sound_days` 1, `retire_hint_days` 3, `offline_stops_at_fight_day` true | escopo 3.1, 3.3, 3.5 |
| `opponents.json` | `prep_days` (6 adversários) | — | 12, 13, 10, 16, 24, 16 | escopo 3.4, 3.5 |
| `career.json` | `gym_retire_hint_seconds` | 300 (em uso) | 300 (**sem uso**) | seção 4 |

**Mudei sem pedido:** nenhum número de balanço. A única regra nova fora do texto do escopo é a da seção 2 (a equipe deixa de treinar na luta e nas janelas), que é a consequência direta da regra anti-abuso.

### 7.5 Testes
- Novos (pasta de save de teste): relógio só anda com `sala_ativa()` (cada linha da tabela 2); dia chega no instante certo e trava; 10 min (simulados) parado no dia = nada muda e nenhuma luta começa; Lutar antes → `fight_day = dia + prep`; Passar o posto no dia = Legado de `aposentar()`; avisos 3 e 1 disparam uma vez; save v8 → v9 nos 4 casos de 5.2; `seconds_per_day` 0 = jogo sem calendário; `prep_days` lido do JSON (mudar o número muda a data).
- Os testes de luta/economia que usam tempo de luta com a equipe treinando podem precisar de ajuste (a equipe não treina mais na luta).

---

## 8. Chaves para o Roteirista (tom pé no chão, frases curtas)
Limites aproximados; o UI/UX confirma no `ui_audit`.
| Chave (`ui_texts.json`) | O que é | Exemplo provisório | Limite |
|---|---|---|---|
| `hud_fight_date` | HUD, faltam N dias | `FALTAM {n} DIAS · {nome}` | ≤ 28 |
| `hud_fight_date_one` | HUD, falta 1 dia | `FALTA 1 DIA · {nome}` | ≤ 28 |
| `hud_fight_today` | HUD, no dia | `HOJE · {nome}` | ≤ 28 |
| `hud_campaign_day` | dia da campanha (se couber) | `DIA {n}` | ≤ 10 |
| `hud_campaign_complete` | depois do Kid | `CAMPANHA COMPLETA` | ≤ 28 |
| `warn_3_days` | faixa de 3 dias | `Faltam 3 dias para {nome}.` | ≤ 36 |
| `warn_1_day` | faixa + som de 1 dia | `Amanhã: {nome}. Gaste o que tiver.` | ≤ 36 |
| `retire_hint` (substitui `gym_retire_hint`) | 2ª linha no vermelho com ≤ 3 dias | `PASSAR O POSTO AGORA LEVA {n} DE LEGADO` | ≤ 40 |
| `enrolled_toast` | começo da carreira e depois de cada vitória | `A escola te inscreveu: {nome} em {n} dias.` | ≤ 40 |
| `fight_day_title` | título da prévia do dia | `DIA DA LUTA` | ≤ 20 |
| `fight_day_line` | linha da prévia do dia | `{nome} te espera. Lutar ou passar o posto?` | ≤ 44 |
| `fight_day_fight` | botão | `LUTAR` | ≤ 12 |
| `fight_day_pass` | botão | `PASSAR O POSTO` | ≤ 16 |
| `retire_button` | botão da barra (hoje APOSENTAR) | `PASSAR O POSTO` | ≤ 16 |
| `retire_confirm_title` / `retire_yes` / `retire_no` | confirmação | `PASSAR O POSTO?` / `PASSAR` / `VOLTAR` | como hoje |
| `retire_title` / `retire_line` / `retire_line_belt` | tela de saída | Roteirista decide se fala em "posto" | como hoje |
| `end_title_campaign` | fim (derrota ou passou o posto) | `CAMPANHA ENCERRADA` | ≤ 24 |
| `new_career_button` / `tree_new_career` | botão | `NOVA CAMPANHA` | ≤ 16 |
| `sum_title` | resumo | `RESUMO DA CAMPANHA {n}` (Roteirista decide se "carreira" fica) | como hoje |
| `sum_days` (novo, opcional) | linha do resumo | `DIAS DE CAMPANHA` | ≤ 18 |
| `no_more_fights_gym` | depois do Kid | `CAMPANHA COMPLETA. PASSAR O POSTO VALE MAIS.` | ≤ 44 |
- Não usar "receber novo discípulo" (6b).

---

## Resumo
- **Dia = 30 s de sala.** Datas em dias depois da luta anterior: **Dudu 12, Brutão 13, Dinho 10, Muralha 16, Tonhão 24 (a mais folgada), Kid 16.** Depois do Kid: "Campanha completa", sem relógio.
- **Uma condição só (`sala_ativa`) liga relógio, equipe, Metrônomo, clique e luva dourada.** Anda na sala, na LOJA, sem foco e minimizado; para em toda janela, na luta, na arte, no cartão e no dia. A equipe deixa de treinar na luta e nas janelas.
- **No dia:** tudo para, a prévia abre com LUTAR e PASSAR O POSTO (confirmação, 100% do Legado), não fecha, ícone pisca. Avisos a 3 dias (faixa) e 1 dia (faixa + som).
- **Dica de aposentar da academia: muda** para "≤ 3 dias e vermelho", na garagem e na academia.
- **Save v9:** `campaign_seconds`, `fight_day`; save antigo ganha a folga cheia; depois do Kid abre "Campanha completa".
- **Números:** 96–97% das lutas antes da data; vermelho no dia 2,3% a 3/s; tempo morto da carreira 1 a 3/s **6:00** (era 10:32); 23b com 2.000: **26,4%**, mais cedo **20:44**, ninguém antes de 20:00 (sem a alavanca de $300K); 1ª derrota **13:39 / 14:09**; clique no fim 54–72%.
- **Para o Diretor decidir:** o Kid na carreira da chegada sobe para 79–98% com o robô paciente (6.5; a alavanca é o Kid na 5.4, não a data) e a árvore fecha uma carreira antes (6.6, efeito do 100% no dia).

## Decisões do Diretor (design 5.3)
Data: 2026-11-12. **Veredito: design aprovado sem mudança de números.** Pode ir para implementação.

1. **Kid fácil para quem espera o verde (6.5): aceito.** Esperar o verde é jogar bem, e a meta da fase é "quem joga bem chega verde". O critério 10 fecha na mediana com o robô apressado. A folga do Kid fica em **16**. Não se mexe na data para endurecer o chefe (travaria o Jiu-jitsu a 3/s). Se o dono achar o Kid fácil (ponto 4 da validação), a alavanca é **F/A/R do Kid na 5.4**, remedindo o Jiu-jitsu a 3/s.
2. **Árvore fecha na 4ª carreira (6.6): aceito nesta fase.** É efeito direto da regra central (passar o posto vale 100%). Nada de baixar o Legado do "passar o posto" nem mexer em custos agora. A meta "5ª–8ª" vai para a remedição da **5.4**, que refaz a árvore. Fica registrado como pendência obrigatória de lá.
3. **4/s quase sem cinturão na 1ª (0,2%): aceito.** O 25% é teto, não piso. A parede do Dinho na campanha 1 é o que o escopo pediu ("a data é a parede"). Quem a 4/s não pega o cinturão passa o posto com 100% e volta mais forte. O 23b fecha pelo 5/s, que é o perfil que corria risco de passar do teto. Sem alavanca nova.
4. **Fim da carreira 1 a 3/s em 15:26: aceito.** A meta de 10–15 min vale para 4/s e 5/s (13:39 e 14:09, dentro). O 3/s é referência, fica 26 s acima e termina por **escolha** (passar o posto com 100%), não por derrota. Não encurtar o Dinho por isso (6.8: piora o resto).
5. **Equipe para na luta e nas janelas: aceito.** É a regra anti-abuso do escopo (3.3) levada ao fim: uma condição só (`sala_ativa`). O efeito é pequeno (1–8% do treino) e fecha a brecha. Ressalva para a UI/UX: o cartão de início precisa fechar com 1 clique ou Espaço, senão vira tempo parado sem querer.
6. **Dica de passar o posto (≤ 3 dias, vermelho, pote > 0, garagem e academia): aceito.** Liga a dica à data em vez de um tempo arbitrário. `gym_retire_hint_seconds` fica sem uso no JSON.

**Para o QA conferir além dos 15 critérios:** a tabela da seção 2 inteira (cada estado "param" e "andam"), a dica só aparecer no vermelho com ≤ 3 dias, e o "Cancelar" da confirmação no dia voltar para a prévia do dia.
