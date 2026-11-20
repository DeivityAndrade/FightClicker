# Fase 7a2 — Treino fora de hora: design

Designer de Jogo, 2026-11-19. Base: `fase7a-escopo.md` (§4, §6, §7 e **§8, decisões do dono**, que valem sobre o resto),
o pedido do Produtor de hoje e `fase7a1-textos.md` (o bônus do Choque se chama **AQUECIDO**, nunca "embalo").
Dados já gravados: **`data/minigames.json`** (arquivo novo; todos os números desta fase). Simulador: **`tools/sim/fase7a2_sim.py`**
(roda em cima do `fase7a1_sim.py`, a campanha de hoje). Nenhuma lógica escrita.

## 0. Em uma frase
De vez em quando o seu Osmar chama para um treino depois do expediente. Um balão com **IR**; quem ignora não perde nada; quem vai
joga 30 s de **Choque** (cabo de guerra de sparring, do jeito da sua arte: Boxe por cliques, Jiu-jitsu segurando e soltando) ou de
**Panfletagem** (entregar panfletos da Raízes na rua para quem dá sinal de interesse). O Choque dá treino nos atributos da arte e,
vencendo, **AQUECIDO** na próxima luta; a Panfletagem dá **FAMA**. Na parede aparece um recorte de jornal sobre um vulto mascarado.

## 1. Regras fixas (do dono) e como o design as cumpre
| Regra | Como fica |
|---|---|
| Ignorar não custa nada | O balão some sozinho depois de 2 dias (60 s de sala). Nenhuma fala, aviso ou perda. O convite **não usa nenhum sorteio do jogo** e **não mexe nas falas**: a campanha que ignora é idêntica à de antes (§9). |
| Ir não custa nada | Do IR até a volta: relógio da campanha parado (nenhum dia gasto), **equipe produzindo** (só a equipe; §6.1). |
| 20 a 40 s, SAIR a qualquer hora | Contagem 2 s + jogo 30 s + prêmio ~3 s = **35 s**. SAIR leva o prêmio do que já fez (piso incluído). |
| ~1 convite a cada 3–4 min de sala | **240 s de sala** (8 dias) entre um convite e o próximo; o 1º aos 300 s (10 dias). Os 4 min (e não 3) e o 1º mais tarde vêm da medida do teto (§8). |
| Teto de 10% somando tudo | Medido no simulador (§8): todos os convites com nota máxima. |
| Prêmios diferentes | Choque = treino da arte + AQUECIDO; Panfletagem = FAMA. |

## 2. O convite do seu Osmar
### 2.1 Relógio do convite
- `room_s` = segundos de **sala ativa** (`sala_ativa()`) **com o Osmar desenhado no local** (`coach_presence` do `escola.json`:
  garagem sempre; academia só depois do marco `cena_primeira_academia`). Não anda em janela, luta, cena, fala travada, fim, sucessão,
  dia da luta, nem no minigame.
- 1º convite da campanha: `room_s ≥ first_after_s` (**300 s**).
- Próximo: `next_at = room_s_do_aparecimento + interval_s` (**240 s**), aceito ou não. Depois de jogar, no mínimo
  `min_after_return_s` (**60 s**) de sala antes do próximo: `next_at = max(next_at, room_s_da_volta + 60)`.
- Convite visível por `visible_s` (**60 s de sala = 2 dias**). Passou disso: some sozinho, sem som e sem fala ("ignorado").
- **Não acumula:** no máximo 1 aberto. Se `next_at` chega com outro aberto, nada acontece até ele fechar.

### 2.2 Quando o balão pode aparecer (todas verdadeiras)
1. `room_s ≥ next_at` e nenhum convite aberto;
2. sala ativa, Osmar desenhado, **sem balão de fala** de ninguém na tela, sem gesto de calçar, sem abertura, sem saída do John em curso,
   sem caixa abrindo (espera o fim dela);
3. existe pelo menos um minigame **elegível** (§2.4).
Se 2 ou 3 falham, o convite espera (não pula) e aparece no 1º quadro em que tudo vale.

### 2.3 O que fecha o convite aberto
| Situação | O que acontece |
|---|---|
| Passou `visible_s` de sala | some ("ignorado"); `next_at` não muda |
| Janela, luta, cena, fala do Osmar começando | **fica escondido** e o tempo dele para (não conta sala); volta igual depois. Fala sempre ganha do convite: o convite nunca adia nem cancela uma fala |
| Chegou o **dia da luta** | fecha ("ignorado") |
| **MUDAR** de local | fecha em silêncio ("ignorado"); `room_s` e `next_at` seguem (mudar não gera convite extra) |
| Fim da campanha, sucessão, nova campanha | tudo zera (§7) |
| Clicou **IR** (ou no Osmar com o balão aberto) | o convite é consumido, salva na hora e abre a tela do minigame |

### 2.4 Elegibilidade e qual minigame o Osmar chama
| Minigame | Elegível quando |
|---|---|
| **Choque** (`spar`) | com arte escolhida (`arte_id != ""`) |
| **Panfletagem** (`flyers`) | marco `garage_saved` presente (a escola já tem nome: a ficha diz RAÍZES FIGHT CLUB) |

Escolha (`choice: "alternate"`, sem sorteio):
1. Só um elegível → esse.
2. **AQUECIDO guardado** → Panfletagem (o prêmio único do Choque já está na mão; é o "o que está em falta").
3. 1º convite da campanha → Choque.
4. Senão, o contrário do **último oferecido** (aceito ou não).

Por que alternar e não sortear: o jogador aprende o ritmo ("agora é a panfletagem"), dá para planejar, o teste é exato e não gasta
sorteio. A regra 2 é o "em falta": ninguém recebe um Choque que não pode dar AQUECIDO de novo.

### 2.5 Quem vê o quê, por carreira
| Momento | Convites |
|---|---|
| 1ª carreira (John), antes do 1º cinturão | **nenhum** (sem arte e sem nome da escola): o tutorial de 10–15 min fica igual |
| 1ª carreira depois do cinturão, ainda na garagem | só Panfletagem |
| Com arte: da escolha da arte na 1ª carreira em diante; nas campanhas seguintes, desde o começo (garagem e academia) | Choque e Panfletagem alternando |

### 2.6 Choque sem arte: **não aparece** (decisão)
- O Choque é "o treino da arte": a variante (Boxe ou Jiu-jitsu) é a arte, e o prêmio vai pela divisão do aparelho da arte. Sem arte
  não há variante nem aparelho.
- Sem arte = 1ª carreira, que é o tutorial de 10–15 min com meta medida desde a fase 3. Um convite ali muda o ritmo do tutorial.
- Uma 3ª variante custaria arte e testes a mais (sprites, ui_audit) para uns 3 minutos de jogo, só uma vez na vida do save.
- O vazio é coberto: depois do cinturão da 1ª carreira já existe a Panfletagem, e a arte chega com a mudança para a academia.

## 3. Choque (sparring)
### 3.1 A tela e a regra
- Uma barra horizontal de **−1** (ele te encostou) a **+1** (você encostou ele), marcador começa no meio (0). É um cabo de guerra.
- Dura **30 s** fixos (`duration_s`), depois de 2 s de contagem. Encostar numa ponta = **1 ponto** daquele lado; a barra volta ao
  meio e os dois param `reset_s` (**1,0 s**).
- **VENCEU** = no fim (ou no SAIR) você tem **≥ 3 pontos** (`points_goal`) **e mais pontos que ele**.
- O adversário de treino é um aluno/sparring genérico (não é o próximo adversário da escada); ele **empurra sempre** um pouco
  (`base_push`) e de tempos em tempos faz um **padrão**, sempre com aviso antes:

| Padrão | Aviso (na tela) | O que ele faz | O que o jogador deve fazer |
|---|---|---|---|
| **Rajada** (Boxe) / **puxada forte** (JJ) | `warn_s` (1,0 → 0,6 s): ombro recua + "!" vermelho | empurra `burst_push` por **1,5 s** | **Boxe: segurar** (guarda). **JJ: soltar**. Feito isso, a rajada **não empurra nada** (`read_mult` 0) |
| **Pausa** | `pause_warn_s` (0,6 → 0,5 s): ele baixa a guarda / respira, ícone branco | **não empurra** por `pause_s` (1,4 → 1,2 s) | **contragolpe**: Boxe clica, JJ segura; vale **×2** (`counter_mult`) |
| **Finta** | igual ao da rajada, mas **na metade do aviso o "!" vira branco** e ele abaixa o ombro | não empurra por `feint_pause_s` (0,9 → 0,8 s) | não guardar à toa: quem leu a troca contragolpeia; quem segurou a guarda perde a janela |

Entre um padrão e outro: espera sorteada entre `gap_min` e `gap_max` (pelo `_rng_treino`, §6.4).

### 3.2 Variante **Boxe** (cliques)
| Ação | Efeito |
|---|---|
| **Clique** (ou espaço) | empurra `push_per_click` × força (**0,10** da barra com fôlego cheio; ×2 na pausa) |
| **Segurar** ≥ `hold_is_guard_s` (0,20 s) | **guarda**: não empurra; anula a rajada. O aperto que abriu a guarda já contou como clique |
| **Fôlego** (barra pequena) | cada clique gasta **0,07**; recupera **0,30/s** sempre. Força do clique = `0,15 + 0,85 × fôlego` |

Ritmo que não cansa: 0,30 / 0,07 ≈ **4,3 cliques/s**. A 9 cliques/s o fôlego zera em ~3 s e cada clique cai para ~18% da força:
empurra menos que um jogador calmo a 4/s. A melhor jogada é ritmo firme e **guardar fôlego para a pausa**.

### 3.3 Variante **Jiu-jitsu** (segurar e soltar)
| Ação | Efeito |
|---|---|
| **Segurar** o botão (ou espaço) | puxa `pull_per_s` × força (**0,65/s** com fôlego cheio; ×2 na pausa) |
| **Soltar** | não puxa; o fôlego volta. Solto na puxada forte dele, ele **não puxa nada** |
| **Fôlego** | segurando gasta **0,20/s** (**×2** se segurar durante a puxada forte dele); solto volta **0,40/s**. Força = `0,15 + 0,85 × fôlego` |

Segurar o tempo todo zera o fôlego em 5 s e perde. O ritmo bom é segurar ~2/3 do tempo, soltar na puxada forte e segurar firme na pausa.

### 3.4 Dificuldade (nível = índice da escada: 0 Dudu … 5 Kid; escada completa = 5)
| Nível | base_push | burst_push | warn_s | pause_s | pause_warn_s | finta_pause_s | gap (s) | pesos rajada / pausa / finta |
|---|---|---|---|---|---|---|---|---|
| 0 | 0,15 | 0,80 | 1,00 | 1,40 | 0,60 | 0,90 | 2,0–3,5 | 0,50 / 0,40 / 0,10 |
| 1 | 0,18 | 0,86 | 0,92 | 1,35 | 0,60 | 0,90 | 1,9–3,3 | 0,50 / 0,37 / 0,13 |
| 2 | 0,205 | 0,92 | 0,84 | 1,30 | 0,55 | 0,85 | 1,7–3,0 | 0,48 / 0,35 / 0,17 |
| 3 | 0,23 | 0,98 | 0,76 | 1,25 | 0,50 | 0,80 | 1,5–2,8 | 0,47 / 0,33 / 0,20 |
| 4 | 0,255 | 1,04 | 0,68 | 1,20 | 0,50 | 0,80 | 1,4–2,6 | 0,46 / 0,31 / 0,23 |
| 5 | 0,28 | 1,10 | 0,60 | 1,20 | 0,50 | 0,80 | 1,2–2,4 | 0,45 / 0,30 / 0,25 |

O aviso nunca fica abaixo de 0,5 s (dá para reagir). Sobe a pressão, encurta o aviso e aumenta as fintas.

### 3.5 Medido (`fase7a2_sim.py choque`, 400 partidas por célula): pontos / VENCEU / prêmio em % do máximo
Perfis: **parado** (não faz nada), **afobado** (9 cliques/s ou segura sempre, não lê nada), **distraído** (4/s, lê 30% dos avisos),
**médio** (4,5/s, lê 60%, 30% das fintas), **bom** (4,3/s, lê 90%, 70% das fintas), **perfeito**.

| Boxe | nível 0 | nível 2 | nível 3 | nível 5 |
|---|---|---|---|---|
| parado | 0 / 0% / 25% | 0 / 0% / 25% | 0 / 0% / 25% | 0 / 0% / 25% |
| afobado | 1,5 / 6% / 61% | 1,0 / 1% / 50% | 0,5 / 0% / 38% | 0,5 / 0% / 37% |
| distraído | 3,8 / 92% / 98% | 2,8 / 62% / 89% | 2,5 / 50% / 84% | 2,1 / 35% / 76% |
| médio | 3,3 / 77% / 94% | 2,8 / 56% / 88% | 2,5 / 48% / 85% | 2,2 / 37% / 78% |
| bom | 4,0 / 98% / 99% | 3,4 / 85% / 96% | 3,2 / 78% / 95% | 2,8 / 65% / 91% |
| perfeito | 4,2 / 99% / 100% | 3,5 / 87% / 97% | 3,3 / 82% / 96% | 3,0 / 77% / 94% |

| Jiu-jitsu | nível 0 | nível 2 | nível 3 | nível 5 |
|---|---|---|---|---|
| parado | 0 / 0% / 25% | 0 / 0% / 25% | 0 / 0% / 25% | 0 / 0% / 25% |
| afobado | 1,0 / 0% / 50% | 0,5 / 0% / 37% | 0,5 / 0% / 37% | 0,5 / 0% / 37% |
| distraído | 2,3 / 42% / 77% | 1,4 / 16% / 59% | 1,2 / 10% / 54% | 0,9 / 7% / 48% |
| médio | 3,5 / 81% / 93% | 2,4 / 50% / 80% | 2,2 / 41% / 77% | 1,9 / 27% / 69% |
| bom | 4,1 / 96% / 99% | 3,2 / 78% / 93% | 2,9 / 68% / 90% | 2,7 / 55% / 86% |
| perfeito | 4,1 / 99% / 100% | 3,4 / 85% / 96% | 3,2 / 79% / 94% | 3,0 / 69% / 91% |

Leitura: as três camadas pesam. **Afobado perde** para quem clica com calma (fôlego). Quem lê os avisos vence bem mais (bom × médio:
+28 pontos de VENCEU no nível 5). O nível 0 é fácil de propósito; no Kid, vencer pede ler o aviso. O Boxe "distraído" vai bem
porque 4 cliques/s é o ritmo certo: no Boxe, **acertar o ritmo** já é metade do jogo; no JJ, **soltar na hora** pesa mais.

## 4. Panfletagem da escola
### 4.1 A tela e a regra
- Rua do bairro de noite, luz de poste; o lutador parado na calçada com o maço de panfletos da Raízes. Pessoas atravessam a tela
  (`cross_s` **4,5 s**), uma a cada `spawn_s` em média (intervalo sorteado exponencial pelo `_rng_treino`).
- Uma parte quer o panfleto (`interested`). Quem quer **dá um sinal** no meio da travessia, por `tell_s`: para de leve, vira o rosto
  para o cartaz/o lutador, "?" pequeno. Quem não quer: fone, celular, passo apressado, braço cruzado.
- **Sinal falso** (`false_tell`, nível ≥ 1): alguém sem interesse olha de relance e desvia; o sinal começa e **some na metade**
  (45% do `tell_s`), terminando em cara fechada.
- **Clicar** em alguém dando o sinal de verdade = **ACEITOU** (+1). Mão ocupada `give_cooldown_s` (0,35 s).
- **Errar** (clicar em quem não quer, ou fora do sinal) = "NÃO, VALEU": **−0,5** (`miss_penalty`, nunca abaixo de 0) e mão ocupada
  `miss_cooldown_s` (0,8 s). É o "custa pouco": um erro custa meio panfleto.
- 30 s fixos + 2 s de contagem. Meta (`goal`): **10 aceitos** = prêmio cheio.

### 4.2 Dificuldade (mesmo nível da escada)
| Nível | spawn_s | interessados | tell_s | sinal falso |
|---|---|---|---|---|
| 0 | 0,85 | 42% | 1,8 | 0% |
| 1 | 0,80 | 40% | 1,6 | 5% |
| 2 | 0,75 | 38% | 1,5 | 10% |
| 3 | 0,70 | 36% | 1,4 | 15% |
| 4 | 0,68 | 35% | 1,3 | 20% |
| 5 | 0,65 | 34% | 1,2 | 25% |
(~16 interessados passam em 30 s em todos os níveis; muda quanto tempo o sinal dura e quantos sinais mentem.)

### 4.3 Medido (`fase7a2_sim.py panfleto`, 400 partidas): aceitos líquidos / erros / prêmio em % do máximo
| Perfil | nível 0 | nível 3 | nível 5 |
|---|---|---|---|
| parado | 0 / 0 / 25% | 0 / 0 / 25% | 0 / 0 / 25% |
| afobado (clica em todo mundo sem ler) | 0,1 / 14,5 / 26% | 0 / 17,1 / 25% | 0 / 18,2 / 25% |
| distraído | 3,9 / 0,4 / 54% | 3,3 / 1,3 / 50% | 3,0 / 1,9 / 48% |
| médio | 7,5 / 0,4 / 79% | 7,2 / 1,1 / 78% | 6,9 / 1,5 / 76% |
| bom | 10,7 / 0,2 / 94% | 10,8 / 0,4 / 94% | 10,7 / 0,6 / 94% |
| perfeito | 12,2 / 0 / 97% | 12,6 / 0 / 98% | 12,7 / 0 / 98% |
Clicar em todo mundo não paga (cada erro tira meio ponto): **ler o sinal é o jogo**. Um erro de vez em quando quase não pesa.

### 4.4 Prêmio: FAMA (decisão) — e por que não o discípulo melhor
**Escolho só FAMA.**
- FAMA já existe, aparece na hora (contador do HUD) e tem destino claro: o pote do Legado (`legacy_per_fame` 2). É o prêmio
  "de mundo" certo para divulgar a escola, e é **diferente** do prêmio do Choque (treino agora × Legado depois): o jogador escolhe
  conforme a necessidade (perto de aposentar, a FAMA vale mais).
- "Discípulo um pouco melhor" pediria um **conceito novo** (atributo de discípulo, que hoje é só visual), um campo que atravessa a
  sucessão no save (v14 com migração), repetiria o nó do hall "Vaquinha da escola" (`start_training`) e o prêmio só seria visto
  uma campanha depois. Na 1ª carreira (John) nem existe sucessão próxima. Fica registrado como ideia para a fase da escola, se o dono quiser.

## 5. Prêmios, piso e teto
### 5.1 Choque: treino da arte
```
ref     = producao_total() + 3 × por_clique()            # Treino/s de quem clica 3 vezes por segundo (reward_ref)
nota    = 0,25 + 0,75 × min(1, pontos / 3)                # piso 0,25 só por ir
treino  = 20 × ref × nota                                 # max_seconds 20
```
- Entra de uma vez no fim (ou no SAIR): **saldo de Treino + atributos pela divisão do aparelho da arte** (Boxe: pera 40/45/15;
  JJ: boneco 25/15/60; `data/training.json`), igual a um ganho no aparelho da arte (não usa o foco atual).
- Piso: 5 s de `ref` (jogando nada). Teto: 20 s de `ref` (3 pontos; pontos a mais não somam). Somado à equipe, que produziu os
  ~38 s fora com o relógio parado, quem joga bem volta com uns 35–45 s de produção da sala sem gastar nenhum dia. O número é
  pequeno de propósito: é o que cabe no teto de 10% (§8). Alavanca, se o dono quiser mais: `max_seconds`.
- Mostrado grande: "+N FORÇA  +N AGILIDADE  +N RESISTÊNCIA".

### 5.2 AQUECIDO (vencer o Choque)
- Vencer guarda **AQUECIDO** para a **próxima luta oficial** (qualquer luta da escada). Na luta: **atributos do jogador × 1,03** (`attr_bonus`)
  nos quatro lugares onde a conta é feita: prévia, risco do HUD, `chance_detalhada` e o motor. **Mesma conta nos quatro: a prévia
  continua honesta** (é só um número maior entrando no mesmo cálculo).
- É gasto quando a luta **começa** (ganhe ou perca). Não soma: vencer de novo com ele guardado não dá outro (e o Osmar chama a
  Panfletagem, §2.4). Some no fim da campanha. Sem próxima luta (escada completa) o Choque não dá AQUECIDO ("SEM LUTA MARCADA").
- Prévia: 1 linha "AQUECIDO: +3% NOS ATRIBUTOS (+N NA CHANCE)", com N = chance com − chance sem (a prévia calcula as duas), e a
  chance principal já com ele. Sala: um ícone pequeno perto do HUD da luta.
- Por que +3% nos atributos e não algo da passiva (embalo inicial, pegada adiantada): funciona igual nas duas artes, a prévia não muda
  de forma, cabe na conta que já existe e o tamanho é fácil de medir (§5.4).

### 5.3 Panfletagem: FAMA
```
fama_max = max(5, 0,25 × prize_fame do próximo adversário)      # escada completa: o último (Kid)
nota     = 0,25 + 0,75 × min(1, aceitos_líquidos / 10)
fama     = max(1, arredonda(fama_max × nota))
```
| Próximo adversário | Dudu | Brutão | Dinho | Muralha | Tonhão | Kid |
|---|---|---|---|---|---|---|
| FAMA da luta | 10 | 30 | 60 | 100 | 120 | 200 |
| Panfletagem: piso / teto | 1 / 5 | 2 / 8 | 4 / 15 | 6 / 25 | 8 / 30 | 13 / 50 |
Um panfleto perfeito vale 1/4 da FAMA da próxima luta; o piso é 1/16.

### 5.4 Tamanho do AQUECIDO
`fase7a2_sim.py aquecido`: estados do robô de 0,55 a 1,15 do total do adversário, melhor tática, 200 lutas por ponto.
Ganho médio na chance, em pontos (entre parênteses, o maior ganho visto):
| Arte | Adversário | vermelho (<40%) | amarelo (40–90%) | verde (≥90%) |
|---|---|---|---|---|
| Boxe | Muralha | +7,1 (+19,5) | +9,1 (+21,5) | +0,6 |
| Boxe | Tonhão | +5,4 (+13,5) | +8,6 (+19,5) | +0,6 |
| Boxe | Kid | +4,9 (+32) | +12,0 (+21) | +0,6 |
| JJ | Muralha | +6,2 (+20) | +6,5 (+16) | +0,4 |
| JJ | Tonhão | +5,3 (+14) | +5,9 (+13,5) | +0,7 |
| JJ | Kid | +6,0 (+23) | +6,6 (+14) | +0,4 |

+3% nos atributos é pouco em número, mas a luta é íngreme: na faixa amarela vira **+6 a +12 pontos de chance**; no verde quase não
muda. O AQUECIDO ajuda **justo quando a luta está apertada**, que é quando o jogador vai querer o Choque. Por isso a prévia mostra
o "+N NA CHANCE": é o número que o jogador sente. Começou em +6%; caiu para +3% porque sozinho ele comia ~3 pontos do teto de 10%.

## 6. Regras de estado (para o Programador)
### 6.1 O que anda durante o minigame
| Coisa | Durante o minigame |
|---|---|
| Relógio da campanha (`segundos_campanha`), dia, avisos | **parado** |
| Equipe (`producao_total()`, com todos os bônus) | **produz**, entra pelo `_ganhar` como hoje (vai para o foco atual) |
| Metrônomo, assistido, luva dourada, FRENESI, bônus do Jiu-jitsu por tempo, tempo morto | parados (são da sala) |
| `room_s` do convite | parado |
| Autosave | normal |
Em código: um estado novo "treino fora" que faz `sala_ativa()` dar falso e, no `tick`, soma só `producao_total() × delta`.

### 6.2 SAIR, fechar o jogo e prêmio
- **IR**: o convite é consumido (`open = ""`, `next_at` recalculado) e **salva na hora**. Se o jogo fechar no meio, ao abrir está na
  sala, sem prêmio e sem convite (= ignorado). Nada duplica.
- **Fim ou SAIR**: calcula o prêmio com o que já foi feito, aplica tudo de uma vez (treino/atributos ou FAMA; AQUECIDO se venceu),
  salva na hora e mostra a tela de prêmio. SAIR antes de começar a contagem ainda dá o piso (a pessoa foi).
- A tela de prêmio não tem tempo mínimo: VOLTAR fecha.

### 6.3 Mudança de local, cena e luta
- MUDAR com convite aberto: fecha em silêncio. MUDAR não é possível de dentro do minigame (tela própria).
- O minigame só abre da sala; nada interrompe o minigame (nenhuma cena, fala ou luta nasce fora da sala). Falas que quiserem sair
  esperam a volta, como hoje com as janelas.
- O minigame **nunca decide luta** e não mexe em escada, calendário, preço, Legado, Honra.

### 6.4 Sorteios
- O minigame e o convite **não chamam** `rng`, `_rng_evento`, `_rng_fala`, `_rng_sucessao`. Usam um `_rng_treino` próprio
  (`randomize()` ao abrir cada minigame; não vai para o save). O convite é **determinístico** (só relógio e regras).

## 7. Save (continua v13, sem migração)
Um campo novo **opcional** em `career`: `training_invite` (Dictionary). Falta o campo (save antigo) = valores padrão.
| Campo | Tipo | Padrão | O que é |
|---|---|---|---|
| `room_s` | float ≥ 0 | 0 | segundos de sala (com o Osmar) desta campanha |
| `next_at` | float ≥ 0 | 300 (`first_after_s`) | quando o próximo convite pode aparecer |
| `open` | "" \| "spar" \| "flyers" | "" | convite aberto agora |
| `open_since` | float | 0 | `room_s` em que o aberto apareceu |
| `last` | "" \| "spar" \| "flyers" | "" | último oferecido (alternância) |
| `warm` | bool | false | AQUECIDO guardado |
- Validação: número inválido → padrão; `open`/`last` fora da lista → ""; `warm` só vale com arte e escada não completa.
- Zera na **nova campanha** e na sucessão (é da campanha). Não entra em `permanente`.
- Marco novo (já existe o mecanismo `escola.milestones`): `black_cat_rumor_heard` (§10).
- É tudo o que precisa: o dia do último convite (`open_since`), se está aberto (`open`) e o AQUECIDO. Por isso **não vira v14**.

## 8. Teto de 10% (simulador)
### 8.1 O que é "acelerar a campanha" (definição)
A campanha anda em **dias** (30 s de sala = 1 dia; a luta tem data). O dono decidiu que, fora da sala, o relógio para e a equipe
produz. Então "somando tudo" o que o convite dá é: **a produção da equipe nos ~38 s fora + o prêmio + o AQUECIDO + a FAMA**, tudo
sem gastar dia. A medida certa é em **tempo de sala (dias de campanha)**: quanto antes, em dias, o jogador chega à mesma vitória.
Também mostro o **tempo real** (o relógio do jogador, com o minigame dentro), que é a outra face: ir **gasta** minutos de verdade.

Medida (igual ao "teto do hall" da 6c2): `fase7a2_sim.py forca`, sem calendário, robô que só luta no verde, derrota não encerra,
árvore vazia, 48 jogadores por linha, a arte desde o começo (o caso das campanhas 2+). Políticas: **nenhum** (ignora tudo),
**todos_max** (vai em todos com nota máxima: Choque 3 pontos e VENCEU sempre, Panfletagem 10+), **todos_med** (Choque 2 pontos,
Panfletagem 7), **todos_piso** (vai e não faz nada), **so_choque_max**.

### 8.2 Resultado (mediana, min:s; "sala" = dias de campanha)
| Perfil | Política | Muralha (cinturão): real / sala | Tonhão: real / sala | Kid: real / sala | Ganho em dias: Muralha / Tonhão / **Kid** | Tempo real no Kid |
|---|---|---|---|---|---|---|
| Boxe 4/s | nenhum | 21:18 / 21:18 | 30:18 / 30:18 | 47:53 / 47:53 | — | — |
| Boxe 4/s | todos_max | 22:31 / 19:59 | 32:35 / 28:47 | 52:27 / 46:07 | 6,2% / 5,0% / **3,7%** | −9,5% |
| Boxe 4/s | todos_piso | 22:58 / 20:26 | 33:09 / 29:21 | 54:02 / 47:04 | 4,1% / 3,1% / 1,7% | −12,9% |
| Boxe 3/s | nenhum | 25:18 / 25:18 | 35:58 / 35:58 | 58:24 / 58:24 | — | — |
| Boxe 3/s | todos_max | 26:08 / 22:58 | 37:46 / 33:20 | 63:18 / 55:04 | **9,2%** / 7,3% / **5,7%** | −8,4% |
| Boxe 3/s | todos_piso | 27:09 / 23:59 | 39:50 / 34:46 | 64:54 / 56:40 | 5,2% / 3,3% / 3,0% | −11,1% |
| JJ 4/s | nenhum | 20:18 / 20:18 | 27:19 / 27:19 | 58:00 / 58:00 | — | — |
| JJ 4/s | todos_max | 21:02 / 18:30 | 28:25 / 25:15 | 63:00 / 54:46 | 8,9% / 7,6% / **5,6%** | −8,6% |
| JJ 4/s | todos_piso | 21:32 / 19:00 | 29:00 / 25:50 | 64:27 / 56:13 | 6,4% / 5,4% / 3,1% | −11,1% |
| JJ 3/s | nenhum | 21:23 / 21:23 | 30:20 / 30:20 | 68:02 / 68:02 | — | — |
| JJ 3/s | todos_max | 22:33 / 20:01 | 31:37 / 27:49 | 74:10 / 64:40 | 6,4% / 8,3% / **4,9%** | −9,0% |
| JJ 3/s | todos_piso | 22:46 / 20:14 | 32:31 / 28:43 | 75:16 / 65:46 | 5,4% / 5,3% / 3,3% | −10,6% |
(todos_med fica entre os dois: Kid +2,7% a +4,9% em dias. so_choque_max: Kid +3,4% a +5,2% em dias, tempo real −0,2% a −1,7%.)

**Teto cumprido:** indo em todos com nota máxima, a campanha inteira (até o Kid) fica **3,7% a 5,7% mais curta em dias**, e
nenhum trecho passa de **9,2%** (Boxe 3/s até o cinturão, o pior caso; o começo da campanha é onde a equipe pesa mais).
**Ir nunca custa dia:** até quem vai e não faz nada ganha 1,7% a 6,4% em dias.
**Em tempo real ir custa** 8–13% (são ~38 s fora a cada 4 min, sem a mão no saco). É o preço de escolher jogar: quem quer
correr ignora, quem está apertado com a data vai. Por isso o minigame não vira obrigação em nenhum dos dois eixos.

### 8.3 Como cheguei nos números (para quem mexer depois)
| Tentativa | Ganho em dias, pior trecho | O que mudou |
|---|---|---|
| Choque 90 s, AQUECIDO +6%, convite a cada 210 s | ~15% | proposta inicial |
| 30 s, +4%, a cada 240 s | ~13% (Muralha, JJ) | intervalo no máximo pedido (4 min) |
| idem + bônus do JJ por tempo só com sala (como no jogo) | ~11% | correção do simulador |
| 25 s, +3%, 1º aos 240 s | 11,2% (Boxe 3/s) | |
| **20 s, +3%, 1º aos 300 s** | **9,2%** | **final** |
O que mais pesa é a **equipe produzindo com o relógio parado** (regra do dono): sozinha ela já dá 2–6% em dias. O resto do teto
(~4 pontos) é dividido entre o prêmio do Choque e o AQUECIDO. Alavancas em `data/minigames.json`: `spar.reward.max_seconds`,
`spar.warm.attr_bonus`, `invite.interval_s`, `invite.first_after_s`.

### 8.4 Campanha de verdade (calendário, Legado, hall)
`fase7a2_sim.py campanha`: robô padrão da 7a1 (calendário, passa o posto no vermelho do dia, árvore, Honra e hall), 60 jogadores
por perfil × 8 campanhas. Aqui o tempo é **real** (com o minigame dentro).
| Perfil | 1º Kid (mediana) nenhum → todos_max / todos_piso | Campanhas até o Kid (média) nenhum → todos_max | Legado em 8 campanhas | Minutos no minigame (8 campanhas) | FAMA da panfletagem |
|---|---|---|---|---|---|
| Boxe 4/s | 40:52 → 42:16 / 42:26 | 1,12 → 1,07 | 20.473 → 21.334 (+4%) | 7,5 | 129 |
| JJ 4/s | 41:45 → 42:50 / 43:18 | 1,08 → 1,13 | 20.477 → 21.527 (+5%) | 7,5 | 143 |
| Boxe 3/s | 45:53 → 47:45 / 48:18 | 1,25 → 1,20 | 19.102 → 20.678 (+8%) | 8,9 | 212 |
| JJ 3/s | 46:08 → 48:12 / 48:31 | 1,27 → 1,23 | 20.048 → 21.466 (+7%) | 8,7 | 210 |
- Cinturão e 1ª carreira: **iguais** em todas as políticas (29:42 / 13:56 a 4/s; 32:47 / 15:26 a 3/s): o tutorial não é tocado.
- Em tempo real, ir em tudo deixa o 1º Kid **2,6% a 4,5% mais tarde** (mediana): o calendário manda e cada convite custa ~38 s.
  Em troca, a FAMA da Panfletagem soma **+4% a +8% de Legado** em 8 campanhas (efeito entre carreiras, pequeno).
- ~11 a 14 convites por 8 campanhas (cerca de 1,5 por campanha): Choque ~9, Panfletagem 3–5.
- Conclusão: em nenhuma medida "ir em tudo" passa de 10% de vantagem. **O minigame é um passeio que não atrapalha a data, não uma
  obrigação.**

### 8.5 D1 da revisão: quem guarda o AQUECIDO e luta mais cedo (2026-11-20)
Pedido do Diretor: o robô do teto só luta no verde, e assim o AQUECIDO quase não pesa. Mede-se um jogador que usa o AQUECIDO para
**lutar antes do verde**. Duas políticas novas no `fase7a2_sim.py` (vão em todos os convites com nota máxima e, **só com o AQUECIDO
guardado**, lutam com a chance já com o bônus ≥ limite): **cedo_max** (≥ 75%) e **cedo50_max** (≥ 50%). Sem o AQUECIDO, esperam o
verde como antes. A seção `campanha` ganhou o 1º Kid **em dias** (tempo real menos os minutos de minigame).

**a) Campanha de verdade** (`campanha`: calendário, a derrota encerra a campanha; 60 × 8): 1º Kid comparado com "nenhum"
| Perfil | todos_max: dias med / média | cedo_max: dias med / média | cedo50_max: dias med / média | Campanhas até o Kid: nenhum / todos / cedo / cedo50 |
|---|---|---|---|---|
| Boxe 4/s | +1,2% / +2,9% | +2,0% / −2,9% | +0,8% / −16,7% | 1,12 / 1,07 / 1,23 / 1,73 |
| JJ 4/s | +1,9% / −0,5% | +2,1% / −14,8% | −71,8% / −47,9% | 1,08 / 1,13 / 1,58 / 2,63 |
| Boxe 3/s | +0,9% / +3,9% | +1,0% / −1,7% | +1,7% / −10,8% | 1,25 / 1,20 / 1,38 / 1,75 |
| JJ 3/s | +0,6% / +2,2% | +1,4% / −7,2% | −72,4% / −45,6% | 1,27 / 1,23 / 1,57 / 3,03 |
Lutar cedo com o AQUECIDO **não acelera**: no melhor caso +2,1% em dias (mediana) e, na média, **atrasa** (perde mais e recomeça
a campanha). Com 50% é um desastre. Em tempo real, todas as políticas ficam 2,5% a 4,5% mais lentas na mediana.

**b) Medida de força** (`forca`: sem calendário e **derrota sem custo**, só repete depois), ganho no Kid em dias:
| Perfil | todos_max | cedo_max | cedo50_max | cedo_max com AQUECIDO **0** (controle) | cedo50_max com AQUECIDO 0 |
|---|---|---|---|---|---|
| Boxe 4/s | +3,7% | +4,8% | +4,8% | +3,6% | +4,1% |
| Boxe 3/s | +5,7% | +7,6% | +7,5% | +6,4% | +6,7% |
| JJ 4/s | +5,6% | **+11,1%** | **+16,4%** | +9,3% | **+15,6%** |
| JJ 3/s | +4,9% | **+10,3%** | **+16,8%** | +8,6% | **+14,8%** |
Aqui o "cedo" passa de 10% no Jiu-jitsu, mas o **controle com o AQUECIDO zerado dá quase o mesmo** (+8,6% a +15,6%): o ganho vem
de **lutar no amarelo sem a derrota custar nada** (essa medida deixa repetir), não do bônus. O AQUECIDO em si soma só **+1 a +2
pontos** sobre o mesmo jogo. Com `attr_bonus` 0,02 (testado) o "cedo" fica igual (+10,0% a +15,6%), o que confirma.

**Decisão: `attr_bonus` fica 0,03.** No jogo de verdade a derrota tem preço (a campanha acaba), e aí lutar cedo com o AQUECIDO dá no
máximo +2,1% em dias e piora a média. Baixar para 0,02 não muda o "cedo" e só deixa o bônus sem graça.

## 9. "Ignorar todos dá o mesmo resultado de antes da 7a2"
- **No simulador** (`fase7a2_sim.py ident`): a política "nenhum" contra o jogo da 7a1 sem convite, mesmas sementes: **80 de 80 sequências
  idênticas** (fim, tempo, vitórias, Legado e cada luta), Boxe 4/s e JJ 3/s × 8 campanhas.
- **No jogo** (critério 8 do escopo): `tools/refatoracao/foto.gd` na main e na 7a2 tem de sair **igual**. O robô da foto nunca clica
  em IR. Para isso:
  1. o convite não usa sorteio nenhum do jogo e não mexe em fala, gesto, `_ocioso` ou foco;
  2. a fala do boato do Gato Preto só sai **dentro** da Panfletagem (§10), nunca na sala;
  3. o recorte de jornal é só um objeto com hover (não fala, não conta ocioso);
  4. a **única diferença permitida** no save é o campo `career.training_invite` (e o marco `black_cat_rumor_heard`, que só nasce
     jogando): o `foto.gd` passa a apagar `career.training_invite` antes do hash (uma linha, comentada). Nada mais pode mudar.

## 10. Gato Preto: só a semente
| Peça | Quando aparece | Como |
|---|---|---|
| **Recorte de jornal** na parede | a partir da **campanha 2** (1º discípulo), com o marco `garage_saved`; na academia, depois do marco da cena (como a foto antiga) | objeto parado ao lado da foto/mural; hover com a manchete (ex.: "VULTO MASCARADO ASSUSTA LADRÃO PERTO DA BORRACHARIA") |
| **Boato do Osmar** | **uma vez na vida do save**, na abertura da 1ª Panfletagem jogada com o recorte já visível | 1 balão do Osmar na rua de noite antes da contagem (2 linhas, minúsculas), grava o marco `black_cat_rumor_heard` |
Por que o boato fica na Panfletagem: é rua de noite, o território do Gato Preto, e assim o boato nunca disputa vaga com as falas da
sala (quem ignora os convites tem o jogo idêntico). Nada do Gato Preto mexe em economia. Sem minigame dele nesta fase (Ronda Noturna
fica para perto da 8a).

## 11. Contrato de dados (`data/minigames.json`, gravado)
| Bloco | Campos |
|---|---|
| `invite` | `first_after_s` 300, `interval_s` 240, `visible_s` 60, `min_after_return_s` 60, `choice` "alternate", `kinds.spar/flyers` (`requires_art`, `requires_milestone`). `overhead_s` é só do simulador |
| `level` | `source` "ladder_index", `max` 5 |
| `reward_ref` | `ref_clicks_per_s` 3 |
| `spar` | `countdown_s` 2, `duration_s` 30, `points_goal` 3, `reset_s` 1, `counter_mult` 2, `read_mult` 0, `hold_is_guard_s` 0,2; `variants.boxing` (`push_per_click`, `breath_cost_per_click`, `breath_recover_per_s`, `weak_min`), `variants.bjj` (`pull_per_s`, `breath_drain_per_s`, `breath_recover_per_s`, `weak_min`, `burst_hold_drain_mult`); `levels[6]`; `reward` (`max_seconds` 20, `floor` 0,25); `warm.attr_bonus` 0,03 |
| `flyers` | `countdown_s`, `duration_s` 30, `goal` 10, `give_cooldown_s`, `miss_cooldown_s`, `miss_penalty`, `cross_s`, `levels[6]`, `reward` (`fame_share` 0,25, `min_fame` 5, `floor` 0,25) |
| `black_cat_seed` | `clipping` (`requires_milestone`, `min_campaign` 2, `spot_by_location`, `requires_milestone_by_location`, `object_text`), `rumor` (`where` "flyers_intro", `text_key`, `milestone`) |
Validação (padrão da casa): número fora da faixa → recorta (tempos 0,1–120 s; frações 0–1; `levels` com menos de 6 linhas repete a
última); arquivo ausente → **sem convites** (o jogo segue igual à 7a1).

Chaves de texto novas (`data/ui_texts.json`, Roteirista): nomes dos dois minigames e do treino; 2–3 falas do convite por minigame
(no balão, curtas); IR; SAIR; VOLTAR; contagem; PONTO!/ENCOSTOU; "VENCEU!"; "AQUECIDO" (já existe `bonus_warm_name`) e a linha da
prévia `warm_preview_line` ("AQUECIDO: +{pct}% NOS ATRIBUTOS (+{n} NA CHANCE)"); "SEM LUTA MARCADA"; dicas de 1 linha dos controles
(Boxe: "CLIQUE PARA EMPURRAR. SEGURE NA RAJADA."; JJ: "SEGURE PARA PUXAR. SOLTE QUANDO ELE PUXAR."; Panfletagem: "ENTREGUE PARA
QUEM OLHAR O CARTAZ."); "ACEITOU!", "NÃO, VALEU"; tela de prêmio ("+{n} FAMA", "+{n} {ATRIBUTO}"); `black_cat_clipping` (hover);
`black_cat_rumor` (fala).

## 12. Critérios de aceite (testáveis)
1. **Frequência:** com a sala ativa e o Osmar presente, o 1º convite aparece aos 300 s de sala e os seguintes a cada 240 s do anterior
   (±1 quadro); ignorado, some aos 60 s de sala. Teste headless com `tick` simulado.
2. **Nunca aparece** com janela, luta, cena, fala na tela, gesto, abertura, saída do John, caixa abrindo, fim, sucessão, no dia da luta,
   sem Osmar desenhado (academia antes da cena), nem na 1ª carreira antes do cinturão. Convite aberto fica escondido nesses casos
   e o tempo dele para.
3. **Fecha** no dia da luta e no MUDAR (sem som, sem fala). Nunca há 2 abertos.
4. **Escolha:** sem arte → só Panfletagem; sem `garage_saved` → só Choque; AQUECIDO guardado → Panfletagem; 1º da campanha → Choque;
   senão alterna o último oferecido.
5. **Ignorar não custa nada:** foto (`foto.gd`, que ignora os convites) **idêntica** à da main, apagando só `career.training_invite`.
6. **Ir nunca custa:** do IR até a volta, `segundos_campanha` não muda e o Treino sobe exatamente `producao_total() × tempo` (fora o prêmio).
7. **Duração:** 2 s + 30 s + tela de prêmio; SAIR funciona em qualquer momento e dá pelo menos o piso (> 0).
8. **Prêmio exato:** Choque = `20 × ref × nota` dividido pelo aparelho da arte; Panfletagem = fórmula da §5.3 (teste com pontos 0, 1, 3, 5
   e aceitos 0, 5, 10, 12 em níveis 0 e 5).
9. **AQUECIDO:** vencer guarda; a prévia mostra a linha e a chance com atributos ×1,03; a chance mostrada = a do motor (mesma função);
   é gasto ao começar a luta; não soma; some na nova campanha; sem próxima luta não é dado.
10. **Choque:** clicar a 9/s rende menos que a 4/s (fôlego); guarda/soltar na rajada zera o empurrão dela; clique/segurar na pausa vale ×2;
    a finta troca o sinal na metade do aviso; 6 níveis lidos do JSON.
11. **Panfletagem:** clicar no sinal = +1; erro = −0,5 (nunca < 0) e 0,8 s de mão ocupada; sinal falso some na metade.
12. **Fechar no meio** do minigame: ao reabrir, sala, sem prêmio, convite consumido; nada em dobro. Save antigo (cópia do save do dono,
    sem `training_invite`) abre sem erro, com os padrões.
13. **Teto:** QA roda `fase7a2_sim.py forca campanha ident` (com as políticas `cedo_max`/`cedo50_max` da §8.5) (Python do Blender, `-I`) e confere a §8 e a §9: nenhum trecho com
    ganho acima de 10% em dias de campanha; ignorar = 80/80 idênticas. Se mudar algum número de `data/minigames.json`, rodar de novo.
14. **Gato Preto:** recorte só da campanha 2 em diante com `garage_saved`; boato só na abertura da 1ª Panfletagem com o recorte visível,
    uma vez; nada muda na economia.
15. `tools/run_tests.ps1` verde (save de teste em APPDATA temporário; janelas com `--position 1950,40`); `ui_audit` com **0 problemas**
    incluindo: balão do convite nos dois locais (Choque e Panfletagem), tela do Choque Boxe e JJ (começo, aviso de rajada, pausa,
    finta, prêmio com AQUECIDO), Panfletagem (começo, sinal, erro, prêmio), prévia com a linha AQUECIDO, recorte na parede.

## 13. Quem faz o quê
### Roteirista
Nome do treino e dos dois minigames; 2–3 falas do convite por minigame (balão curto do Osmar, minúsculas, 2 linhas no máximo);
textos de tela da §11 (curtos, fonte 5x7); manchete do recorte e o boato do Osmar sobre o vulto (sem citar Batman; o nome "Gato
Preto" pode ou não aparecer, a decidir); "AQUECIDO" já é a palavra (nunca "embalo").
### Diretor de Arte
Mockup das duas telas antes de tudo: cenário "depois do expediente" do Choque (fundos da academia/praça à noite, luz de poste) e a
rua da Panfletagem (mesma noite, calçada, poste, cartaz da Raízes com o "R de raiz"); barra do cabo de guerra, fôlego, ícones de
aviso (rajada "!" vermelho, pausa branco, finta que vira branco), "x2"; o recorte de jornal (objeto 1×, legível no hover, sem
logotipo de herói); ícone do AQUECIDO (HUD e prévia); balão do convite com IR.
### Artista de Personagens (skill `padrao-personagem`)
Lutador e parceiro de treino no Choque, em pé frente a frente, por arte: Boxe (empurrar/socar, guarda, recuar o ombro = aviso,
baixar a guarda = pausa, finta); JJ (pegada na gola, puxar, soltar, puxada forte = aviso). 3–5 tipos de pedestre com variações de
sinal (interessado: para e olha; sem interesse: celular, fone, pressa, braço cruzado; sinal falso: olha e desvia) e o lutador
entregando o panfleto. Osmar no canto das duas telas (pose de treinador, sem animação nova obrigatória).
### Programador
1. Ler `data/minigames.json` (classe de dados com validação; ausente = sem convites).
2. Estado do convite num módulo novo `scripts/estado/treino_fora.gd` (repasses de uma linha em `game_state.gd`, mapa atualizado):
   relógio `room_s`, regras das §2.1–2.4, fechar nos casos da §2.3, `ir()`, `sair(resultado)`, prêmio (§5), AQUECIDO.
3. Estado "treino fora" no `tick`: relógio parado e equipe produzindo (§6.1); `sala_ativa()` falso.
4. AQUECIDO na prévia, no risco do HUD, em `chance_detalhada` e no motor (atributos ×1,03; mesma função nos quatro); gasto em `lutar()`.
5. Save: `career.training_invite` opcional (§7), sem versão nova; zera na nova campanha; `foto.gd` apaga o campo antes do hash.
6. Lógica pura dos minigames (barra, fôlego, padrões, pontos; pedestres, sinais, erros) em scripts sem tela, testáveis headless com
   `_rng_treino` semeado no teste. A referência das contas é `jogar_choque`/`jogar_panfleto` do `fase7a2_sim.py`.
7. Testes dos critérios 1–12 e 14 com save de teste.
### UI/UX
Balão do convite (pequeno, perto do Osmar, IR; nunca em cima do balão de fala; some sem animação chamativa); tela do Choque
(barra, marcador, fôlego, avisos, pontos dos dois, tempo, SAIR, dica de controle na 1ª vez) e da Panfletagem (rua, pedestres
clicáveis com área generosa, contador, SAIR); tela de prêmio grande; linha do AQUECIDO na prévia e ícone na sala; juice do clique
(tremida curta na barra, "x2" na pausa, "ENCOSTOU!"). Skill `alinhamento-ui` com **0 problemas**, estados da §12.15 no `ui_audit`.
### QA
Critérios da §12 (e 7–14 do escopo), com a §8 como referência (`fase7a2_sim.py tudo`); jogar 3 Choques por arte e 3 Panfletagens em
níveis diferentes, conferindo que ler o aviso e não afobar faz diferença; testar fechar no meio e o save antigo do dono (cópia).

## 14. Resumo
- **Convite do seu Osmar:** balão com IR na sala, a cada **240 s de sala** (8 dias; o 1º aos 300 s), visível 60 s (2 dias), nunca em
  fala/janela/luta/cena/dia da luta, fecha no MUDAR e no dia da luta, não acumula, não usa sorteio. Alterna Choque e Panfletagem
  (AQUECIDO guardado → Panfletagem). Nada na 1ª carreira antes do cinturão.
- **Choque** (só com arte): cabo de guerra de 30 s; 3 pontos e mais que ele = VENCEU. Ele empurra sempre e faz **rajada** (aviso
  1,0→0,6 s), **pausa** (vale ×2) e **finta** (o aviso muda na metade). Boxe: clicar (fôlego: ~4,3/s é o ritmo; 9/s rende menos) e
  segurar na rajada. JJ: segurar para puxar, soltar na puxada forte. 6 níveis pelo índice da escada. Medido: afobado perde, quem lê
  avisos vence 55–77% no Kid, médio 27–37%.
- **Prêmio do Choque:** `20 s × (equipe/s + 3 cliques/s) × (0,25 + 0,75 × pontos/3)` nos atributos da arte; vencer dá **AQUECIDO:
  atributos ×1,03 na próxima luta** (na prévia com "+N NA CHANCE"; +6 a +12 pontos quando a luta está amarela). Prévia honesta: mesma conta.
- **Panfletagem** (com a escola já com nome): 30 s, clicar em quem dá o sinal de interesse; erro custa meio panfleto e 0,8 s.
  Prêmio: **FAMA** = até 1/4 da FAMA da próxima luta (5 a 50), piso 1/16. Escolhi só FAMA (o "discípulo melhor" pediria conceito
  novo e save v14).
- **Gato Preto:** recorte de jornal na parede a partir da campanha 2 (com `garage_saved`); boato do Osmar uma vez, na abertura da
  1ª Panfletagem com o recorte visível. Nada de economia.
- **Teto (dias de campanha, que é o que o convite poupa):** ir em tudo com nota máxima = campanha **3,7–5,7% mais curta**; pior
  trecho **9,2%**. Ir e não fazer nada ainda ganha 1,7–6,4%. Em tempo real ir custa ~3–13% (é o preço de jogar o minigame).
- **Ignorar = igual a antes:** 80/80 sequências idênticas no simulador; no jogo, foto igual apagando só `career.training_invite`.
- **Save v13** com 1 campo opcional (`career.training_invite`) e 1 marco novo; sem migração. Dados em `data/minigames.json`.
