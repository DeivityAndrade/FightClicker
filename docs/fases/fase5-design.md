# Fase 5 — Academia de bairro e artes marciais: design

Dono: Designer de Jogo. Versão 1 (2026-11-06).
Base: `docs/fases/fase5-escopo.md` (inclusive **"Respostas do dono"**, que prevalecem), `fase4b-design.md`, `fase4-design.md`, `fase3-design.md`, `fase2-design.md`, `data/*.json` e `scripts/game_state.gd` (save v5).
Simulação: `tools/sim/fase5_sim.py` (novo; importa `fase4b_sim.py`, `fase4_sim.py`, `fase3_sim.py` e `fase2_sim.py`). Os valores deste documento estão no bloco `PROPOSTA_5` do simulador.
Dados propostos: `data/proposta_fase5/*.json`. **Nada em `data/` nem em `scripts/` foi alterado.** A seção 11 diz o que entra em cada JSON.

**Decisões do dono aplicadas aqui**
1. Academia **por carreira**, paga em **$**. Toda carreira começa na garagem.
2. Artes: **Boxe e Jiu-jitsu**.
3. A arte **vale a carreira inteira**. Sem troca no meio, sem reembolso.
4. **2 lutas novas** na academia, depois do Seu Muralha.

**O que não muda:** a carreira 1 inteira até o cinturão (provado semente a semente, seção 10.2), os 4 adversários da garagem, o motor da luta, os limiares de risco, o motivo da derrota, a LOJA, o Metrônomo, o assistido, os aparelhos da 4b e os nós CORPO/CARREIRA. Nada da Fase 6 ou posterior entra.

**Nota de nome:** o pedido do Produtor fala em "saco pesado" para o Boxe. O escopo (seção D) diz **saco de velocidade (pera)**, e a garagem já tem um saco pesado. Segui o escopo: o aparelho do Boxe é a **pera**.

---

## 1. Recursos: de onde vem, para onde vai (o que muda)

| Recurso | Bloco do save | Entra por | Sai por | Na tela |
|---|---|---|---|---|
| **Local** (`location`) | `career` | MUDAR (cinturão + $1.000) | NOVA CARREIRA (volta para `garage`) | sala, HUD "ACADEMIA: TREINO x2" |
| **Arte da carreira** (`art`) | `career` | janela de arte (1ª chegada ou início de carreira) | NOVA CARREIRA (escolhe de novo) | HUD da arte, prévia (traço), 4º foco |
| **Tempo de arte** (`art_seconds`) | `career` | corre junto com `play_seconds` desde a escolha | NOVA CARREIRA | HUD do Jiu-jitsu ("EQUIPE +48%") |
| **Artes desbloqueadas** | `permanent` | 1ª chegada à academia | nunca | janela de arte, aba ESTILO |
| **Última arte** | `permanent` | toda escolha de arte | — | vem marcada na janela (R6) |
| Dinheiro ($) | `career` | lutas (agora 6) | LOJA, **e a MUDANÇA** | como antes |
| Treino | `career` | clique, auto-soco, equipe (agora × local × arte) | garagem/academia: geradores, melhorias, aparelhos **e o aparelho da arte e as técnicas** | como antes |
| Fama e Legado | `career` → `permanent` | lutas (agora 6) | árvore (agora com a aba ESTILO) | como antes |

## 2. A mudança para a academia

### 2.1 Números
| Campo | Valor | Onde |
|---|---|---|
| id | `move_gym` | `data/locations.json` → `locations[gym].move` |
| Preço | **$1.000** (`cost`, `currency: "money"`) | idem |
| Condição | cinturão amador **nesta carreira** (`requires: "belt"`) | idem |
| Multiplicador global de treino | **×2,0** (`training_mult`) | `locations[gym].training_mult` (garagem = 1,0) |
| Sprites dos aparelhos | sufixo `_gym` (`apparatus_suffix`) | `locations[gym]` |

**Por que $1.000 e ×2:**
- $1.000 é **exatamente o prêmio base do Seu Muralha**. Quem ganha o cinturão sempre pode mudar na hora (com a Bolsa negociada sobram $500). O preço testa a vontade, não a paciência: depois do cinturão **não existe outra fonte de dinheiro na garagem** (as lutas acabaram). Um preço maior que o prêmio criaria carreiras presas.
- A decisão real não é "mudo ou compro um Nelson" (isso seria uma armadilha, ver 2.3). É **"mudo e arrisco, ou aposento agora com o cinturão"**: aposentar com o cinturão rende 750 de Legado sem nós; mudar e perder no 1º da academia rende 250 (metade do pote, seção 7.3). Mudar e vencer os dois rende até 1.710.
- ×2 é o que faz "o jogo virar outro" logo na chegada: o treino por segundo dobra no mesmo instante (a 5/s com Boxe, de ~1,9K/s para ~3,8K/s; seção 10.4), e o Tonhão cai 4 a 5 min depois da mudança. Não testei outros multiplicadores com 48 jogadores. A alavanca é `SIM_MOVE` no simulador.

### 2.2 Regras (para o Programador)
```
pode_mudar()   = career.location == "garage" e cinturao e dinheiro >= move.cost e não acoes_bloqueadas()
mudar():         dinheiro -= move.cost ; career.location = "gym" ; salvar() na hora
                 se permanent.arts_unlocked está vazio:
                     permanent.arts_unlocked = todos os ids de arts.json
                     abrir a janela de arte (1ª chegada, seção 3.1)
mult_local()   = locations[career.location].training_mult
```
- **Mudar nunca tira nada:** geradores, melhorias, aparelhos, luva, Metrônomo, Treino, atributos, Fama e Legado em jogo ficam iguais. Só o $ cai, uma vez.
- **O multiplicador vale para todo treino** (seção 5.1): clique manual, auto-soco (Metrônomo e assistido) e equipe. Não vale para preços, dinheiro, Fama ou Legado.
- **Aparelhos na versão da academia:** troca de sprite pelo sufixo `apparatus_suffix` (`punching_bag_gym`, `treadmill_gym`, `jump_rope_gym`). Mesmas melhorias, mesmos números. A marca de fita do aparelho que ainda não foi comprado continua existindo na academia.
- **NOVA CARREIRA** (derrota ou aposentadoria): `location = "garage"`, `art = ""`, `art_seconds = 0`.
- **Botão MUDAR:** aparece no lugar do aviso "ACADEMIA DE BAIRRO LIBERADA (EM BREVE)" (vitória do cinturão e bloco PRÓXIMA LUTA). Antes do cinturão, não existe. Com o cinturão, mostra o preço e fica apagado sem o dinheiro (não acontece no jogo normal, só em save editado ou migrado; ver 9.3).
- **HUD antes de mudar:** "PRÓXIMA: MUDE PARA A ACADEMIA" (`hud_next_move`) no lugar do nome do próximo adversário.

### 2.3 Reserva da mudança (anti-armadilha)
Enquanto `cinturao` e `location == "garage"`: uma compra na LOJA que deixaria `dinheiro < move.cost` é **recusada**, e o item mostra "GUARDE $1.000 PARA A MUDANÇA" (`move_reserve`). Sem isso, um jogador que compra um Nelson de $839 depois do cinturão fica sem academia até o fim da carreira (não há mais luta para ganhar dinheiro). Depois de mudar, a LOJA volta ao normal.

## 3. Escolha da arte

### 3.1 1ª vez (chegada à academia)
- Logo depois de `mudar()`, se `arts_unlocked` estava vazio: janela "QUE TIPO DE LUTADOR VOCÊ QUER SER?" com as 2 artes lado a lado. Cada cartão: ícone do aparelho, nome, `tagline` (1 frase de tom), a regra em número curto (`rule_text`) e o traço de luta (`fight_text`). Botão ESCOLHER em cada cartão.
- **1 clique** escolhe: `career.art = id`, `career.art_seconds = 0`, `permanent.last_art = id`, save na hora.
- **Não fecha sem escolher** (não tem X). Enquanto aberta, conta como `modal_aberto` (sem clique, sem Metrônomo, sem assistido, e `art_seconds` não anda).
- Nessa carreira, o aparelho da arte aparece **já na academia** como marca de fita (a esteira já está montada em quase todas; se não estiver, a plaquinha diz "DEPOIS DA ESTEIRA").

### 3.2 Carreiras seguintes
- Com `arts_unlocked` não vazio, NOVA CARREIRA abre a janela de arte **antes** do cartão "O QUE VOCÊ TROUXE". Subtítulo "CARREIRA {n}: ESCOLHA A ARTE". A arte de `permanent.last_art` vem **marcada** (borda e "ÚLTIMA: BOXE"): o jogador que não quer mudar dá 1 clique em ESCOLHER nela.
- Escolha **obrigatória**. Não existe "sem arte" depois da 1ª academia.
- A arte vale desde o minuto 0, **na garagem**: regra de curva, traço de luta e a marca de fita do aparelho da arte (o mentor ensinou). Só o multiplicador ×2 espera a mudança.
- **Não há troca dentro da carreira.** Nenhuma tela oferece isso.
- Sem arte (antes da 1ª academia): não há janela, não há marca, não há HUD de arte. A carreira é a de hoje.

### 3.3 Save antigo e casos de borda
- Fechar o jogo com a janela aberta: ao reabrir, `art == ""` com `arts_unlocked` não vazio e a carreira viva → a janela abre de novo antes de tudo.
- Na 1ª chegada, o mesmo vale: `location == "gym"` e `art == ""` → janela.

## 4. O aparelho de cada arte (4º foco, padrão da 4b)

### 4.1 Tabela
| Arte | id do aparelho | id do desbloqueio | Preço (Treino) | Pede | Força / Agilidade / Resistência | Plaquinha |
|---|---|---|---|---|---|---|
| Boxe | `speed_bag` (pera de velocidade) | `unlock_speed_bag` | **2.500** | `treadmill` | **40% / 45% / 15%** | "PERA — 2.5K TREINO" |
| Jiu-jitsu | `grappling_dummy` (boneco de grappling) | `unlock_grappling_dummy` | **2.500** | `treadmill` | **25% / 15% / 60%** | "BONECO — 2.5K TREINO" |

- Mesmo padrão da 4b: marca de fita no chão com plaquinha, compra com **Treino** na aba TREINO (1 clique em COMPRAR), chegada com poeira, foco vai para ele, **zera em NOVA CARREIRA**. Pede só a esteira, então pode sair antes ou depois da corda.
- **Só o aparelho da arte da carreira existe** (`art` do aparelho == `career.art`). Sem arte, nenhum dos dois aparece (nem marca, nem botão de foco, nem linha na aba).
- **Treina os 3 atributos:** cada soco (clique ou auto) e cada segundo de equipe com ele em foco vai inteiro para o saldo de Treino e é dividido nos atributos pelo `split`:
```
ganho = (mesma conta de hoje, com o aparelho em foco)
treino        += ganho
atributo[x]   += ganho × split[x]       para x em força, agilidade, resistência  (split soma 1,0)
```
- A pera é a arte de quem bate: Força e Agilidade juntas. O boneco é a de quem aguenta: Resistência e um pouco de Força. Com as duas técnicas, o aparelho da arte chega a ×15, igual ao saco no máximo. O valor dele não é treinar mais, é **treinar três coisas de uma vez** (o jogador não precisa ficar alternando com a prévia).
- **Por que 2.500:** na carreira com arte (a 3ª, 4ª...), com os nós de sempre, o robô a 5/s compra a esteira aos 0:21, a corda aos 0:50 e a pera aos 1:33. A corda nunca atrasa (ela pede a esteira, não a pera), e o aparelho fica sempre antes do Brutão. Não testei outros preços com 48 jogadores (alavanca no `PROPOSTA_5`).

### 4.2 As técnicas (2 por arte)
São as melhorias do aparelho da arte: mesma linha da aba TREINO, pagas em Treino, compradas em ordem, mesmo código de hoje (`upgrades`).
| Arte | id | Nome provisório | Preço (Treino) | Efeito |
|---|---|---|---|---|
| Boxe | `tech_boxing_1` | Jab duplo | **1.500** | pera ×3 |
| Boxe | `tech_boxing_2` | Pêndulo | **15.000** | pera ×5 (total ×15) |
| Jiu-jitsu | `tech_bjj_1` | Guarda fechada | **1.500** | boneco ×3 |
| Jiu-jitsu | `tech_bjj_2` | Raspagem | **15.000** | boneco ×5 (total ×15) |

- Os mesmos ×3 e ×5 do saco, para o aparelho da arte valer o saco no máximo. Preços mais altos que os do saco (300 / 5.000) porque elas chegam numa carreira com nós e porque a 1ª técnica vem logo atrás do aparelho (o robô junta para ela).
- Ícones das técnicas: o Diretor de Arte (seção 13).

### 4.3 Foco, teclado e dica de fim
- Botão de foco: o 4º da fileira, mesmo tamanho; tecla **4**. Rótulo `focus_label` ("BOXE / PERA", "JIU-JITSU / BONECO") e a linha `focus_split` ("FOR 40% · AGI 45% · RES 15%").
- `definir_foco` recusa o aparelho da arte quando ele não está montado ou quando a arte é outra.
- **Dica de fim com aparelho não comprado (4b §5):** continua olhando só os aparelhos que têm `attribute` (saco, esteira, corda). O aparelho da arte não entra nessa conta.

## 5. Regras de curva das artes

### 5.1 Fórmulas (todas)
```
mult_local      = locations[career.location].training_mult                 (garagem 1,0 ; academia 2,0)
estilo(arte)    = Σ effect.value dos nós comprados com requires_art == arte   (0 ou 0,5)

bonus_boxe      = arts[boxing].rule.value × (1 + estilo(boxing))            (0,50 ; com o nó 0,75)
                  só se career.art == "boxing", senão 0
t_min           = career.art_seconds / 60
bonus_jj        = (1 + estilo(bjj)) × min(cap, start + per_minute × t_min)  (0,20 → 1,00 aos 6:40 ; com o nó 0,30 → 1,50)
                  só se career.art == "bjj", senão 0

por_clique_manual = base × mult_aparelho(foco) × mult_luva × mult_clique(árvore) × mult_local × (1 + bonus_boxe)
por_auto_soco     = base × mult_aparelho(foco) × mult_luva × mult_clique(árvore) × mult_local        (Metrônomo e assistido)
equipe_s          = (Σ geradores + Σ pagos) × (1 + B.passive_bonus) × mult_local × (1 + bonus_jj)
```
- O crítico continua `crit_multiplier` × o valor do soco (manual ou auto).
- `art_seconds` anda **junto com `play_seconds`** (mesmo relógio, inclusive durante a luta), mas só depois da escolha e não anda com a janela de arte aberta.
- Nada disso muda preço, dinheiro, Fama ou Legado.

### 5.2 Números
| Arte | Regra | Campo | Valor | Com o nó ESTILO |
|---|---|---|---|---|
| Boxe | `manual_click_bonus` | `value` | **+50%** no clique do jogador (mouse ou Espaço). **Não** vale no Metrônomo nem no assistido | +75% |
| Jiu-jitsu | `crew_time_bonus` | `start` / `per_minute` / `cap` | **começa em +20%, sobe 12 pontos por minuto de arte, teto +100% (aos 6:40)** | começa em +30%, +18/min, teto +150% (também aos 6:40) |

| min de arte | 0 | 2 | 4 | 6 | 6:40 em diante |
|---|---|---|---|---|---|
| bônus do Jiu-jitsu | +20% | +44% | +68% | +92% | **+100%** |
| com o nó ESTILO | +30% | +66% | +102% | +138% | **+150%** |

- **O Boxe é a arte de quem clica**; o Jiu-jitsu é a de quem monta equipe e deixa o tempo trabalhar. Nenhum dos dois corta nada do jogo de hoje (R4): o Jiu-jitsu não mexe no clique e o Boxe não mexe na equipe.
- **HUD da arte** (pequeno, perto do foco): "BOXE: +50% NO SEU CLIQUE" (fixo) ou "JIU-JITSU: EQUIPE +48%" (atualiza 1 vez por segundo; com "(MÁX.)" no teto).
- **Por que esses números** (seção 10.4): testei Boxe +40/+45/+50% e Jiu-jitsu com começo 0/+20/+25/+50%, 10–15 pontos por minuto e teto +100/+125/+150/+200/+250/+300%. Com teto acima de +100%, o Jiu-jitsu rendia ~40% mais treino por segundo na academia e vencia o Kid com o dobro de frequência do Boxe. Com começo +50%, ele passava o Boxe também a 5/s. Com começo 0, o Kid caía na carreira da chegada em 29% dos Jiu-jitsu a 5/s (limite 25%). Com o Boxe a +45%, o Boxe a 4/s levava 3 carreiras para o Kid. O par **+50% / "+20%, +12 por minuto até +100%"** é o que fecha tudo junto (seção 10).

## 6. Traço de luta (prévia)

### 6.1 Números e regra
| Arte | Campo (`arts[].fight`) | Valor | Texto da prévia (`fight_text`) |
|---|---|---|---|
| Boxe | `damage_mult` | **×1,10** no dano que o jogador causa | "BOXE: +10% DE DANO" |
| Jiu-jitsu | `taken_mult` | **×0,90** no dano que o jogador recebe | "JIU-JITSU: −10% DE DANO RECEBIDO" |

```
tática_efetiva(t) = cópia de t com
    damage_mult = t.damage_mult × arte.fight.damage_mult
    taken_mult  = t.taken_mult  × arte.fight.taken_mult          (sem arte: 1,0 e 1,0)
```
- Vale para as 3 táticas, na luta **e** na prévia (chance, rótulo, %, motivo da derrota, "espere ficar verde"): a mesma função monta a tática. Assim o teste de risco honesto continua passando sem mudança (critério 8).
- A prévia mostra a linha `fight_text` abaixo da tática, só com arte. Sem animação nova.
- Os dois traços valem quase o mesmo (10% de dano contra 10% de dano recebido). O Boxe ajuda mais contra quem aguenta (Muralha, Tonhão); o Jiu-jitsu ajuda mais contra quem bate (Brutão, Kid).

## 7. As 2 lutas da academia

### 7.1 Tabela
| Ordem | id | Nome provisório | Perfil | Força | Agilidade | Resistência | $ | Fama |
|---|---|---|---|---|---|---|---|---|
| 5 | `opp_gym_1` | Tonhão do Tatame | RESISTENTE | **260K** | **100K** | **1,1M** | **2.500** | **120** |
| 6 | `opp_gym_2` | Kid Navalha (teto da fase) | RÁPIDO | **500K** | **1,0M** | **2,0M** | **6.000** | **200** |

Para comparar: Seu Muralha 78K / 58K / 490K, $1.000, 100 de Fama.

### 7.2 Regras
- Entram no fim de `opponents.json` com **`"location": "gym"`**: só luta quem se mudou. Na garagem, depois do cinturão, o bloco PRÓXIMA LUTA mostra o MUDAR (seção 2.2), nunca o Tonhão.
- `belt` continua só no Muralha. **O cinturão passa a ser `indice_escada > índice do adversário com belt`** (hoje é `indice_escada == nº de adversários`, regra B7, e quebraria com 6 adversários).
- Vencer o Kid: fim da escada. O bloco mostra "VOCÊ VENCEU A ACADEMIA. APOSENTAR VALE MAIS." (`no_more_fights_gym`).
- Prêmios, Fama, Legado, revanche, "espere ficar verde" e a alavanca L1 funcionam como com os outros 4 (são regras por adversário).
- **Por que esses perfis:** o Tonhão é o "muro de resistência" (pede Força e Resistência; o boneco e o saco treinam isso); o Kid é o "muro de agilidade" (1,0M de Agilidade; a pera e a corda treinam isso). Assim cada arte tem um adversário onde o aparelho dela ajuda mais, e o Jiu-jitsu, que rende mais na academia, encontra no teto um adversário que pede o que o Boxe treina.
- Dinheiro: $2.500 e $6.000 compram 1 a 2 Profs. Nelson cada (o 7º custa $1.342, o 8º $2.147). É o que dá uso ao dinheiro na academia sem item novo de LOJA.

### 7.3 Legado (sem nós; `legacy_per_fame` 2, bônus do cinturão 100)
| Momento | Pote | Aposentar | Derrota |
|---|---|---|---|
| Cinturão (hoje) | 500 | **750** | — |
| + Tonhão | 740 | **1.110** | no Tonhão: 250 |
| + Kid | 1.140 | **1.710** | no Kid: 370 |

Com a Torcida da rua (+50% de Fama) e o Saber cair, os valores sobem como hoje. **A derrota na academia custa caro** (perde metade do pote, inclusive o bônus do cinturão). É a decisão "mudo e arrisco ou aposento", e a prévia já mostra "PERDER ENCERRA A CARREIRA ({n}% DO LEGADO)".

## 8. Aba ESTILO da árvore
| id | Ramo | Pede | Custo (Legado) | Efeito | Nome provisório |
|---|---|---|---|---|---|
| `style_boxing` | `style` | arte `boxing` desbloqueada | **1.200** | `art_rule_bonus` **0,5**: o bônus do Boxe fica ×1,5 (+50% → **+75%**) | Mão de sino |
| `style_bjj` | `style` | arte `bjj` desbloqueada | **1.200** | `art_rule_bonus` **0,5**: a curva do Jiu-jitsu fica ×1,5 (começa em +30%, +18/min, teto **+150%**) | Pressão de quem tem tempo |

- Ramo novo `style` ("ESTILO") com `requires_arts_unlocked: true`: a aba **só aparece** com `arts_unlocked` não vazio. As abas CORPO e CARREIRA não mudam.
- Nó com `requires_art`: só pode ser comprado com essa arte em `arts_unlocked` (hoje as duas desbloqueiam juntas). O efeito vale **só nas carreiras jogadas com essa arte** (o texto da aba diz "SÓ VALE JOGANDO DE BOXE", `tree_style_art_only`).
- Os dois nós são simétricos de propósito (×1,5 no efeito da arte). Com +25 pontos fixos no Boxe e +50 pontos só no teto do Jiu-jitsu (versão testada antes), o Boxe ganhava o nó no começo da carreira e o Jiu-jitsu só depois de alguns minutos, e o cinturão abria 17–22% entre as artes.
- **Por que 1.200:** é o Legado de **uma carreira de academia** (aposentar depois do Tonhão: 1.110 sem nós, ~1.600 com a Torcida). O nó chega 1 a 2 carreiras depois da 1ª chegada, junto com o 2º da academia, e não antes dos nós de 500–900 que já existem.
- Ordem do robô "dica" (para o simulador): `body_jab`, `career_purse`, `body_muscle_memory`, `career_scouting`, `body_crew`, `career_crowd`, **`style_<arte>`**, `body_heavy_hands`, `career_purse_2`, `body_crew_2`, `career_good_loser`.

## 9. Save v6

### 9.1 Formato (o que muda em relação à v5)
```json
{ "version": 6, "saved_at_unix": 1730000000,
  "state": {
    "career":    { "...todos os campos da v5...": "",
                   "location": "garage", "art": "", "art_seconds": 0.0 },
    "permanent": { "...todos os campos da v5...": "",
                   "arts_unlocked": [], "last_art": "" },
    "ending":    { "...igual...", "summary": { "...": "", "art": "" } } } }
```
| Campo | Tipo | Leitura (validação) |
|---|---|---|
| `career.location` | id de `locations.json` | inexistente → `default_location` (com aviso) |
| `career.art` | id de `arts.json` ou `""` | inexistente → `""` (com aviso); arte fora de `arts_unlocked` → `""` (com aviso) |
| `career.art_seconds` | número ≥ 0 | inválido → 0 |
| `permanent.arts_unlocked` | lista de ids | ignora inexistente/repetido (com aviso) |
| `permanent.last_art` | id ou `""` | inexistente → `""` |
| `ending.summary.art` | id ou `""` | ausente → `""` |

**Consistência (na leitura, com aviso, sem tirar nada do jogador):**
- `indice_escada` passou do 1º adversário da academia e `location == "garage"` → `location = "gym"` (save editado).
- `apparatus_owned` com aparelho de outra arte (ou com arte vazia) → tira o aparelho e zera as técnicas dele. O Treino não volta (dado ruim de save editado).
- `focus` no aparelho da arte que saiu → `default_focus`.
- Carreira viva com `art == ""` e `arts_unlocked` não vazio → abre a janela de arte (3.3).

### 9.2 Momentos de salvar (novos)
| Ação | Num único save |
|---|---|
| MUDAR | `money −= cost`, `location = "gym"` e, na 1ª vez, `arts_unlocked = [todas]` |
| Escolher arte | `art = id`, `art_seconds = 0`, `last_art = id` |
| Comprar aparelho da arte / técnica | como na 4b (Treino, `apparatus_owned`, `focus`, `upgrades`) |
| NOVA CARREIRA | como na 4b + `location = "garage"`, `art = ""`, `art_seconds = 0` (a janela de arte vem logo depois) |
| Fim de carreira | como hoje + `ending.summary.art` |
| Autosave | `art_seconds` vai junto (já é salvo a cada 30 s com `play_seconds`) |

### 9.3 Migração `_migrar_5_para_6`
```
v6.career    = v5.career + { location: "garage", art: "", art_seconds: 0 }
v6.permanent = v5.permanent + { arts_unlocked: [], last_art: "" }
v6.ending    = v5.ending                 (summary.art ausente vale "")
se v5.career.belt == true e v5.career.money < 1000:  v6.career.money = 1000
```
- A carreira em andamento continua **na garagem e sem arte**, com tudo o que tinha (foco, aparelhos, melhorias, luta pendente). Quem já tem o cinturão vê o botão MUDAR (`indice_escada == 4` aponta para o Tonhão, que pede a academia).
- **O "dinheiro mínimo" de 1.000** é uma constante da migração (`MIGRACAO_V6_DINHEIRO_MUDANCA := 1000`, o preço da mudança na v6): na v5 o jogador com cinturão pode ter gastado o prêmio depois do cinturão, quando ainda não existia mudança. Sem isso ele ficaria sem academia até aposentar. A migração não lê `data/`.
- `SaveStore.MIGRACOES[5] = "_migrar_5_para_6"`, `VERSAO_ATUAL = 6`. Cadeia v0 → v6. O guarda do save real continua cobrindo tudo (testes em pasta própria).

## 10. Simulação e balanço

### 10.1 O robô (regras declaradas)
`tools/sim/fase5_sim.py` (seções `precos curvas identidade b23 controle assistido carreiras`). Luta, prévia, motivo, árvore, Metrônomo, LOJA, assistido, aparelhos da 4b e tempo morto vêm dos simuladores anteriores **sem mudança**. O que é novo:
- **O cinturão não encerra a carreira.** O robô muda na hora (o prêmio do Muralha sempre paga) e respeita a reserva da LOJA (2.3).
- **Arte:** política por perfil: "sempre Boxe", "sempre Jiu-jitsu" ou "alterna" (começa no Boxe). Na 1ª chegada, escolhe a arte da política. Da carreira seguinte em diante, escolhe no minuto 0.
- **Aparelho da arte:** prioridade logo depois da corda (o robô junta Treino para ele) e, depois, para a 1ª técnica. A 2ª técnica entra no cálculo normal de melhorias. O foco padrão passa do saco para o aparelho da arte quando o multiplicador dele é ≥ o do saco.
- **Equipe valorizada:** o robô avalia os geradores e o Nelson com o fator `mult_local × (1 + bonus_jj)`. Assim o Jiu-jitsu compra mais equipe, como um jogador faria.
- **Lutas da academia:** iguais às outras (luta no amarelo; contra quem já o derrotou, espera o verde; alavanca L1). **Aposenta depois de 8 min seguidos no vermelho na academia**: é o jogador que vê o Kid vermelho e leva o Legado. Variante "só luta no VERDE na academia": espera o verde contra os 2 da casa.
- **Árvore:** regra "dica", com o nó ESTILO da arte que ele joga logo depois da Torcida da rua (seção 8). O nó só existe depois da 1ª chegada.
- **Amostras:** 48 jogadores × 8 carreiras por perfil; 400 × 1 carreira no 23b; 64 na identidade; 24 no controle; 12 × 6 carreiras no só-assistido. O robô olha a prévia a cada 30 s, então os tempos andam em degraus de 30 s.

Rodar:
```
"C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase5_sim.py tudo
SIM_N=48 SIM_CARREIRAS=8 ... carreiras            (números deste documento)
SIM_MOVE="1000,2.0" SIM_BOXE="0.5" SIM_JJ="0.2,0.12,1.0" SIM_G1="F,A,R" SIM_G2="F,A,R" SIM_RET="480"
```

### 10.2 Carreira 1 = a de hoje (critério 12)
- **64 de 64 carreiras 1 idênticas às do `fase4b_sim.py` original, a 5, 4 e 3 cliques/s:** as mesmas lutas, nos mesmos segundos, com a mesma chance. Sem arte e na garagem, todos os fatores novos valem exatamente 1,0.
- **23b (400 jogadores):** cinturão na 1ª carreira em **17,0% a 5/s e 24,2% a 4/s**; o mais cedo foi aos **23:51**. Igual à 4b. Com a meta de ≤ 20% / ≤ 25% / nunca antes de 20:00, **fecha**, com a mesma margem curta a 4/s.
- 1ª derrota (mediana): 12:14 (5/s) e 14:14 (4/s). Igual à 4b.

### 10.3 Carreiras em sequência (48 jogadores, 8 carreiras)
| perfil | cinturão: carreira (med; p10–p90) | 1ª chegada: carreira | jogo até a 1ª chegada (med; p90) | Tonhão vencido na carreira da chegada | Kid: carreiras depois da chegada (med; p10–p90) | Kid na carreira da chegada | início da carreira seguinte (crit. 14; med; p90) | tempo morto na academia (med; p90) |
|---|---|---|---|---|---|---|---|---|
| Boxe 5/s | 2 (1–3) | 2 (1–3) | 28:40; 47:56 | 29 de 48 | **1 (0–3)** | **19%** | 41:06; 55:39 | 5:30; 7:32 |
| Jiu-jitsu 5/s | 2 (1–3) | 2 (1–3) | 28:40; 47:56 | 29 de 48 | **1 (0–3)** | **15%** | 41:37; 56:04 | 4:30; 7:01 |
| Boxe 4/s | 2 (1–3) | 2 (1–3) | 32:08; 53:57 | 32 de 48 | **2 (1–4)** | 2% | 45:45; 66:11 | 6:00; 8:00 |
| Jiu-jitsu 4/s | 2 (1–3) | 2 (1–3) | 32:08; 53:57 | 29 de 48 | **2 (1–3)** | 0% | 46:15; 66:08 | 4:30; 8:00 |
| Boxe 3/s | 2 (1–3) | 2 (1–3) | 57:13; 63:29 | 23 de 48 | **4 (2–7)** | 0% | 64:11; 75:41 | 7:31; 8:00 |
| Jiu-jitsu 3/s | 2 (1–3) | 2 (1–3) | 57:13; 63:29 | 19 de 48 | **1 (1–3)** | 2% | 61:21; 75:41 | 5:00; 8:00 |
| Boxe 4/s, só luta no VERDE na academia | 2 (1–3) | 2 (1–3) | 32:08; 53:57 | 47 de 48 | 1 (0–2) | **40%** | 50:42; 67:11 | 5:30; 8:00 |
| Jiu-jitsu 4/s, só luta no VERDE na academia | 2 (1–3) | 2 (1–3) | 32:08; 53:57 | 47 de 48 | 0 (0–1) | **81%** | 49:42; 71:04 | 4:30; 7:01 |
| alterna (Boxe 1º), 4/s | 2 (1–3) | 2 (1–3) | 32:08; 53:57 | 32 de 48 | 3 (1–5) | 2% | 45:45; 66:11 | 6:01; 8:00 |
| alterna (Boxe 1º), 5/s | 2 (1–3) | 2 (1–3) | 28:40; 47:56 | 29 de 48 | 1 (0–3) | 19% | 41:06; 55:39 | 5:31; 7:32 |

**A carreira da 1ª chegada** (sem arte até mudar): cinturão aos 18:45 (5/s), 20:46 (4/s) e 24:46 (3/s). A mudança vem no mesmo segundo do cinturão, e o Tonhão cai **4 a 5 min depois da mudança**. Como ela acaba, a 5/s com Boxe (de 48): 13 aposentam, 19 perdem no Tonhão, 7 perdem no Kid e 9 vencem tudo. A 4/s, a maioria aposenta depois do Tonhão (29–31 de 48), e ~1 em cada 3 perde no Tonhão lutando no amarelo.

### 10.4 Boxe x Jiu-jitsu (critério 10)
**Carreiras com arte desde o minuto 0 (na sequência, depois da 1ª chegada; 269–283 carreiras por linha):**
| ritmo | Boxe: até o cinturão (med; p10–p90) | Jiu-jitsu | diferença | quem sai na frente | Kid vencido aos (med) Boxe / Jiu-jitsu |
|---|---|---|---|---|---|
| 5/s | 8:25 (7:55–11:54) | 8:55 (8:25–11:55) | **5,9%** | **Boxe** | 18:23 / 17:25 |
| 4/s | 8:55 (8:55–11:54) | 9:25 (8:55–12:55) | **5,6%** | Boxe | 18:54 / 17:55 |
| 3/s | 11:54 (10:55–14:25) | 10:51 (9:55–14:25) | **9,7%** | **Jiu-jitsu** | 22:54 / 19:55 |

**Controle** (a mesma carreira, com os 6 nós de uma 3ª carreira típica e um robô que espera o verde contra todos; 24 jogadores):
| perfil | até o cinturão | Tonhão | Kid | 5 min depois de mudar: mão / Metrônomo / equipe por s |
|---|---|---|---|---|
| sem arte 5/s | 14:50 | 20:20 | 31:58 | 1,44K / 411 / 966 |
| Boxe 5/s | 11:55 | 15:55 | 24:24 | 2,16K / 411 / 1,21K |
| Jiu-jitsu 5/s | 11:55 | 15:25 | 23:26 | 1,44K / 411 / 2,43K |
| Boxe 4/s | 12:55 | 17:25 | 26:54 | 1,72K / 411 / 1,19K |
| Jiu-jitsu 4/s | 12:55 | 16:55 | 25:26 | 1,15K / 411 / 2,38K |
| Boxe 3/s | 14:55 | 20:25 | não (aposenta) | 1,29K / 411 / 966 |
| Jiu-jitsu 3/s | 14:25 | 18:55 | 27:57 | 864 / 411 / 2,38K |
| **Boxe, só assistido** | **33:57** | 43:57 | não | 0 / 411 / 912 |
| **Jiu-jitsu, só assistido** | **19:25** | 24:56 | não | 0 / 205 / 2,02K |

- **Nenhuma arte domina:** a diferença até o cinturão fica em ≤ 10% em todos os ritmos. O Boxe sai na frente a 5/s (e a 4/s, por pouco); o Jiu-jitsu sai na frente a 3/s e no só-assistido (19:25 contra 33:57 no controle; 18:25 contra 30:57 nas 6 carreiras do perfil só-assistido). É o que o critério 10 pede.
- **Muda como se joga, não quanto se ganha:** na academia, a 5/s, o Boxe tira 57% do treino da mão, e o Jiu-jitsu tira 57% da equipe.
- Qualquer arte é ~20% mais rápida que jogar sem arte (14:50 → 11:55 no controle). É o "degrau acima" da fase, e ele só existe depois da 1ª chegada.
- Na chegada, o treino por segundo **dobra no mesmo instante** (×2 do local). No controle a 5/s com Boxe, ele passa de ~1,9K/s para ~3,8K/s.

### 10.5 Regressões das metas da Fase 4 / 4b e critérios da Fase 5
| Meta | 4b (antes) | **Fase 5 (depois)** | Situação |
|---|---|---|---|
| F4 22: 1ª derrota em 10–15 min (mediana) | 12:14 / 14:14 | **12:14 / 14:14** (idêntica) | **fecha** |
| F4 23a: cinturão entre a 2ª e a 4ª carreira | 2 (1–3) | **2 (1–3)** em todos os perfis | **fecha** |
| F4 23b: cinturão na 1ª ≤ 20% a 5/s, ≤ 25% a 4/s, nunca antes de 20:00 | 17,0% / 24,2%; 23:51 | **17,0% / 24,2%; 23:51** | **fecha** (margem curta a 4/s, igual à 4b) |
| F4 24: carreira 1 com mediana ≤ 10 e p90 ≤ 13 | 5:30–6:00; 11:01 / 12:32 | **5:30–6:00; 11:01 / 12:32** | **fecha** |
| F4 24: carreiras 2–4 com p90 ≤ 10 | ≤ 7:00 | **≤ 8:00** (5/s e 4/s; 3/s com 8:01) | **fecha** (sobe 1 min porque agora a academia conta) |
| F4 8: árvore CORPO+CARREIRA fecha entre a 5ª e a 8ª carreira | 6 | **5–6** (4/s e 5/s); 4 na variante "só no verde" | **fecha** no típico, no limite (ver 10.7) |
| F5 9: 1ª chegada entre a 2ª e a 4ª carreira | — | mediana **2** (p10 1, p90 3) | **fecha** (os ~20% que chegam na carreira 1 são os do 23b) |
| F5 10: cinturão a ≤ 15% entre as artes; Boxe na frente a 5/s; Jiu-jitsu no só-assistido | — | 5,9% / 5,6% / 9,7%; sim; sim | **fecha** |
| F5 11: Kid 1–2 carreiras depois da chegada (mediana), na mesma carreira em ≤ 25% | — | 1 / 1 (5/s), 2 / 2 (4/s); na mesma carreira 19% / 15% / 2% / 0% | **fecha** a 4–5/s (ver 10.7: Boxe a 3/s e o jogador paciente) |
| F5 13: tempo morto na academia com p90 ≤ 10 | — | **7:01–8:00** | **fecha** (depende da regra "aposenta com 8 min no vermelho"; ver 10.7) |
| F5 14: de um save novo até começar a carreira seguinte com a outra arte em ≤ 90 min (4–5/s) | — | mediana **41–46 min**, p90 **56–66 min** | **fecha** |

### 10.6 Tempo morto por carreira (maior trecho; mediana / p90 / pior)
| perfil | carreira 1 | carreira 2 | carreira 3 | carreira 4 |
|---|---|---|---|---|
| 4b (base) 5/s | 5:30 / 11:01 / 11:01 | 6:00 / 6:00 / 11:01 | 5:30 / 6:00 / 6:00 | 5:00 / 5:30 / 6:00 |
| Boxe 5/s | 5:30 / 11:01 / 11:01 | 6:00 / 8:00 / 11:01 | 6:00 / 7:01 / 8:00 | 6:01 / 7:01 / 7:01 |
| Jiu-jitsu 5/s | 5:30 / 11:01 / 11:01 | 6:00 / 8:00 / 11:01 | 6:00 / 7:01 / 8:00 | 6:00 / 6:31 / 7:01 |
| 4b (base) 4/s | 6:00 / 12:32 / 12:32 | 7:00 / 7:00 / 7:00 | 5:30 / 7:00 / 7:00 | 5:30 / 6:00 / 6:30 |
| Boxe 4/s | 6:00 / 12:32 / 12:32 | 7:00 / 8:00 / 8:00 | 7:00 / 8:00 / 8:00 | 6:31 / 7:31 / 8:00 |
| Jiu-jitsu 4/s | 6:00 / 12:32 / 12:32 | 7:00 / 8:00 / 8:00 | 6:31 / 7:32 / 8:00 | 6:31 / 7:32 / 7:32 |
| Boxe 3/s | 7:00 / 14:33 / 14:33 | 8:01 / 8:01 / 14:33 | 8:00 / 8:01 / 8:01 | 7:32 / 8:00 / 8:01 |
| Jiu-jitsu 3/s | 7:00 / 14:33 / 14:33 | 8:01 / 8:01 / 14:33 | 7:32 / 8:01 / 8:01 | 6:31 / 7:32 / 8:01 |

Legado médio por carreira (carreiras 2–8): ~750 na 4b; **1.200–1.450** na Fase 5 (as carreiras da academia rendem mais).

### 10.7 O que não fecha ou fecha no limite (honesto)
1. **O tempo morto na academia depende de o jogador aposentar.** Na academia, a LOJA só tem o Nelson, e as lutas são a única fonte de $. Com o Kid vermelho, quase todo minuto vermelho é tempo morto. O p90 de 8:00 vem da regra do robô "aposenta depois de 8 min seguidos no vermelho na academia". Um jogador que espera 15 min tem 15 min de tempo morto. **Recomendo** ao UI/UX uma dica no bloco PRÓXIMA LUTA para quando o adversário da academia está PERIGOSO há ≥ 5 min: "APOSENTAR AGORA LEVA {n} DE LEGADO". Seria uma chave nova; não está no escopo e pede o "sim" do Diretor.
2. **O jogador paciente vence a academia na própria carreira da chegada.** Na variante "só luta no VERDE na academia", o Kid cai na carreira da chegada em **40% (Boxe) e 81% (Jiu-jitsu)**. Quem nunca luta no amarelo também nunca passa 8 min seguidos no vermelho, então não aposenta, e o Jiu-jitsu cresce com o tempo. O critério 11 vale para o típico. Endurecer o Kid para cortar isso (testei +10% em tudo) empurra o típico de 4/s para 3 carreiras. Decisão do Diretor: aceitar (é a recompensa da paciência, e a 1ª chegada já é a 2ª carreira) ou trocar a métrica.
3. **O Boxe a 3/s leva 4 carreiras (2–7) para vencer o Kid; o Jiu-jitsu a 3/s leva 1.** É a regra das artes funcionando (quem clica pouco deve jogar de Jiu-jitsu), mas o lento de Boxe fica fora da faixa de 1–2. O critério 11 não separa perfil; a 4–5/s ele fecha.
4. **Derrota no Tonhão na carreira da chegada:** ~1 em cada 3 jogadores que lutam no amarelo perde no Tonhão e leva só metade do pote (inclusive do bônus do cinturão). A prévia já avisa, e é a decisão "mudo e arrisco, ou aposento" (2.1). Se o Diretor achar pesado, a alavanca é `opp_gym_1` −15% em tudo. No teste, com ele assim, o Tonhão cai em ~3 min, mas o Kid some da carreira da chegada.
5. **A árvore fecha mais cedo** (5–6 contra 6) e, na variante "só no verde", na **4ª** carreira, fora da meta F4 8. O Legado por carreira quase dobra. As alavancas são o preço dos nós ESTILO (1.200) e a Fama da academia (120 / 200).

## 11. Contrato de dados

### 11.1 `data/locations.json` (novo) — proposta em `data/proposta_fase5/locations.json`
| Campo | Tipo / faixa | Padrão | Validação |
|---|---|---|---|
| `default_location` | id | `garage` | inexistente → 1º da lista, com aviso |
| `locations[].id` | texto único | — | repetido: ignora o 2º, com aviso |
| `training_mult` | número > 0 | 1,0 | ≤ 0 ou inválido → 1,0, com aviso |
| `apparatus_suffix` | texto | `""` | sprite ausente → usa o da garagem (sem aviso) |
| `move.cost` | número ≥ 0 | — | inválido → o local não pode ser comprado, com aviso |
| `move.currency` | `"money"` | `"money"` | outro valor → `"money"`, com aviso (só $ nesta fase) |
| `move.requires` | `"belt"` | `"belt"` | outro valor → `"belt"`, com aviso |
| `name`, `ambience`, `move_button`, `move_description` | texto | — | Roteirista |

### 11.2 `data/arts.json` (novo) — proposta em `data/proposta_fase5/arts.json`
| Campo | Tipo / faixa | Validação |
|---|---|---|
| `arts[].id` | texto único | repetido: ignora o 2º |
| `apparatus` | id de aparelho com `art` igual | inexistente → arte sem aparelho, com aviso |
| `rule.type` | `manual_click_bonus` ou `crew_time_bonus` | outro → arte sem regra, com aviso |
| `rule.value` | 0..5 | recorta |
| `rule.start` / `per_minute` / `cap` | 0..10 / 0..1 / 0..10 | recorta; `start > cap` → `start = cap` |
| `fight.damage_mult` / `taken_mult` | 0,5..2,0 | recorta; ausente 1,0 |
| `name`, `tagline`, `rule_text`, `fight_text`, `icon` | texto | Roteirista / Arte |

### 11.3 `data/training.json` — proposta em `data/proposta_fase5/training_apparatus.json`
- 2 aparelhos novos no fim de `apparatus` (`speed_bag`, `grappling_dummy`), com o bloco `unlock` da 4b, `upgrades` (as técnicas) e dois campos novos:
  - `art`: id da arte. Aparelho com `art` só existe quando `career.art == art`.
  - `split`: `{strength, agility, endurance}` no lugar de `attribute`. Soma diferente de 1 → normaliza, com aviso. Aparelho sem `attribute` e sem `split` → ignorado, com aviso.
- Os 3 de hoje **não mudam**. `default_focus` continua `punching_bag`. Aparelho com `art` nunca pode ser `default_focus`.

### 11.4 `data/opponents.json` — proposta em `data/proposta_fase5/opponents_gym.json`
- 2 entradas novas no fim, com o campo novo `location` (`"gym"`). Ausente = `"garage"` (os 4 de hoje). Um adversário de `gym` antes de um de `garage` na lista → aviso (a escada fica travada na garagem).

### 11.5 `data/skill_tree.json` — proposta em `data/proposta_fase5/skill_tree_style.json`
- Ramo `style` com `requires_arts_unlocked`, nós com `requires_art` e o tipo de efeito novo `art_rule_bonus`. Os 10 nós de hoje não mudam.

### 11.6 `data/ui_texts.json` — proposta em `data/proposta_fase5/ui_texts_fase5.json`
Chaves novas: `move_*`, `hud_next_move`, `hud_location_mult`, `no_more_fights_gym`, `art_*`, `hud_art_*`, `focus_split`, `career_card_art`, `sum_art`, `tree_branch_style`, `tree_short_style_*`, `tree_style_art_only`. Trocadas: `belt_unlock` (sai o "EM BREVE") e `belt_hint` (sai o "NÃO HÁ MAIS LUTAS NESTA VERSÃO").

Mudar preço da mudança, multiplicador, regras das artes, técnicas, aparelhos e adversários nesses JSON muda o jogo sem mexer em código (critério 16).

## 12. Testes automáticos que este design pede
| Teste | Confere |
|---|---|
| Mudança | sem cinturão: `pode_mudar` false; com cinturão e $999: false; com $1.000: true, desconta 1.000 uma vez, `location = gym`, geradores/melhorias/luva/Metrônomo/atributos iguais; treino por clique, por auto-soco e equipe ×2 (lido de `training_mult`) |
| Reserva | com cinturão na garagem, compra na LOJA que deixaria < $1.000 é recusada; depois de mudar, aceita |
| NOVA CARREIRA | após derrota e após aposentadoria: `location = garage`, `art = ""`, `art_seconds = 0`, aparelho da arte fora de `apparatus_owned` |
| 1ª chegada | `arts_unlocked` vazio → mudar preenche com as 2 e pede a arte; reabrir sem escolher pede de novo |
| Escolha | da 2ª em diante, a janela vem antes do cartão de início, com `last_art` marcada; não existe função de troca com a carreira viva |
| Boxe | 1.000 cliques manuais: treino = 1,5 × sem arte (±crítico); 1.000 auto-socos (Metrônomo e assistido): igual a sem arte; na academia ×2 por cima |
| Jiu-jitsu | equipe com `art_seconds` 0 / 240 / 400 / 3.600: × 1,20 / 1,68 / 2,00 / 2,00; com o nó: 1,30 / 2,02 / 2,50 / 2,50; o clique não muda |
| Aparelho da arte | só aparece com a arte certa; compra pede a esteira; desconta 2.500; split certo nos atributos; técnicas ×3 e ×5; zera na NOVA CARREIRA |
| Traço | prévia e luta com a mesma tática efetiva; teste de risco honesto passa com Boxe e com Jiu-jitsu |
| Escada | Tonhão não luta na garagem; cinturão = passou do Muralha (com 6 adversários); vencer o Kid → sem mais lutas |
| ESTILO | aba some sem artes; nó só compra com a arte desbloqueada; efeito só na arte dele |
| Dados | mudar `move.cost`, `training_mult`, `rule.*`, `fight.*`, `unlock.cost`, `split` e os atributos dos adversários em JSON de teste muda o jogo |
| Save v6 | v5 com carreira (e com cinturão e $0) → v6 na garagem, sem arte, com MUDAR e $1.000; v0 → v6 em cadeia; validações de 9.1 |
| Guarda do save real | continua passando |

## 13. Para o Roteirista e para a Arte

### 13.1 Roteirista (nomes e textos; tudo provisório)
- **Local:** `locations[gym]` `name` ("Academia do bairro"), `ambience`, `move_button`, `move_description`.
- **Artes:** `arts[]` `name`, `tagline` (1 frase de tom cada), `rule_text`, `fight_text`.
- **Aparelhos:** `speed_bag` e `grappling_dummy`: `name`, `focus_label`, `first_hint`, `crit_texts` (5 cada), `unlock.name` / `description` / `arrives_as`.
- **Técnicas:** `tech_boxing_1` (Jab duplo), `tech_boxing_2` (Pêndulo), `tech_bjj_1` (Guarda fechada), `tech_bjj_2` (Raspagem): `name`, `description`.
- **Adversários:** `opp_gym_1` (Tonhão do Tatame, veterano da casa, RESISTENTE) e `opp_gym_2` (Kid Navalha, campeão da academia, RÁPIDO): `name`, `description`, `entry`, `wins_line`, `loses_line`.
- **Árvore:** `style_boxing` (Mão de sino), `style_bjj` (Pressão de quem tem tempo): `name`, `description`, `effect_text`.
- **Chaves de `ui_texts.json`:** a lista de 11.6 (rascunhos em `data/proposta_fase5/ui_texts_fase5.json`). Atenção às larguras: "GUARDE $1.000 PARA A MUDANÇA" no botão da LOJA e "JIU-JITSU: EQUIPE +100% (MÁX.)" perto do foco passam pela `alinhamento-ui`.

### 13.2 Diretor de Arte (placeholder do estúdio vale, menos a sala)
| Item | Quantos | Observação |
|---|---|---|
| **Sala da academia de bairro** | 1 | marco visual da fase; mesma "caixa" da garagem, mesmas posições de aparelho; espelho trincado, pôster desbotado, tatame gasto num canto |
| Versão academia dos 3 aparelhos | 3 (`punching_bag_gym`, `treadmill_gym`, `jump_rope_gym`) | mesmos tamanhos e encaixes; com os `visual_level` de hoje |
| Pera de velocidade (`speed_bag`) | 1 + `visual_level` 1 | plataforma na parede; com marca de fita, silhueta com cadeado e versão na garagem (carreiras seguintes) |
| Boneco de grappling (`grappling_dummy`) | 1 + `visual_level` 1 | no chão, sobre um pedaço de tatame; marca de fita, silhueta, versão na garagem |
| Ícones das 4 técnicas | 4 | mesmo tamanho dos ícones de melhoria |
| Ícones das artes (`art_boxing`, `art_bjj`) | 2 | para a janela de arte, o HUD e o cartão de início |
| Nós da aba ESTILO | 2 (`skill_style_boxing`, `skill_style_bjj`) | mesmo padrão dos nós de hoje |
| Botão MUDAR | 1 | no lugar do aviso do cinturão; estados aceso / apagado |

### 13.3 Artista de Personagens
- **Só os 2 adversários da academia**, no padrão `padrao-personagem`: Tonhão do Tatame (pesado, quimono velho de faixa roxa, perfil RESISTENTE) e Kid Navalha (magro, boxeador, perfil RÁPIDO). O lutador não muda de visual por arte nesta fase.

## Resumo
- **Mudança:** depois do cinturão, MUDAR custa **$1.000** (o prêmio base do Muralha, então sempre dá para pagar). Ela dá **treino ×2** em tudo, aparelhos com visual de academia e as 2 lutas da casa. Vale só para a carreira em que foi feita. A LOJA guarda os $1.000 até a mudança (anti-armadilha).
- **Artes:** na 1ª chegada, uma janela com 1 clique, e as 2 artes ficam liberadas para sempre. Depois disso, a escolha vem no início de toda carreira, com a última marcada, e não troca dentro da carreira.
  - **Boxe:** +50% no clique manual (não vale no Metrônomo nem no assistido), +10% de dano.
  - **Jiu-jitsu:** a equipe começa com +20% e sobe 12 pontos por minuto até +100% (aos 6:40); −10% de dano recebido.
- **Aparelho da arte:** pera (40/45/15) e boneco de grappling (25/15/60), **2.500 de Treino** depois da esteira, no padrão da 4b. As técnicas são ×3 (1.500) e ×5 (15.000).
- **Lutas da academia:** Tonhão do Tatame (260K / 100K / 1,1M; $2.500; 120 de Fama) e Kid Navalha (500K / 1,0M / 2,0M; $6.000; 200 de Fama). Aba **ESTILO** com 1 nó por arte (**1.200** de Legado, efeito da arte ×1,5).
- **Save v6:** `career.location`, `career.art` e `career.art_seconds`; `permanent.arts_unlocked` e `permanent.last_art`. A migração deixa a carreira na garagem e sem arte, e garante $1.000 a quem já tem o cinturão.
- **Números-chave:** carreira 1 idêntica (64/64); 23b 17,0% / 24,2%; 1ª chegada na 2ª carreira (mediana), ~29 min de jogo a 5/s e ~32 min a 4/s. Até o cinturão com arte, Boxe x Jiu-jitsu: 8:25 x 8:55 (5/s), 8:55 x 9:25 (4/s), 11:54 x 10:51 (3/s). Kid 1 carreira depois da chegada (5/s) e 2 (4/s). Kid na carreira da chegada: 19% / 15%. Tempo morto na academia com p90 ≤ 8:00. Critério 14 em 41–46 min.
- **O que não fecha ou fecha no limite:** o tempo morto na academia depende de o jogador aposentar (recomendo uma dica nova); o jogador "só no verde" vence o Kid na carreira da chegada (40–81%); o Boxe a 3/s leva 4 carreiras para o Kid; ~1 em 3 perde no Tonhão na carreira da chegada; a árvore fecha 1 carreira mais cedo.

## Decisões do Diretor (design Fase 5)
Os números deste documento ficam como estão. O texto completo está no fim de `fase5-escopo.md`.

1. **Tempo morto (10.7.1): aceito; a dica entra.** Chave `gym_retire_hint` ("APOSENTAR AGORA LEVA {n} DE LEGADO") no bloco PRÓXIMA LUTA, com o adversário da academia PERIGOSO há ≥ 5 min; mesmo cálculo de Legado da prévia; `alinhamento-ui`. Critério 13 reescrito no escopo (vale com o robô de 8 min e a dica aos 5 min).
2. **"Só no verde" vence o Kid na chegada (10.7.2): aceito.** Critério 11 passa a valer para o perfil que luta no amarelo.
3. **Boxe a 3/s, 4 carreiras (10.7.3): aceito.** Critério 11 passa a valer a 4–5/s para as duas artes; a 3/s, só o Jiu-jitsu precisa ficar em 1–2. As `tagline` da janela de arte (Roteirista) indicam, sem número, que o Boxe é de quem clica e o Jiu-jitsu de quem monta equipe.
4. **Derrota no Tonhão (10.7.4): aceito, sem mudar o Tonhão.** Alavanca guardada: `opp_gym_1` −15% se o dono achar pesado no teste.
5. **Árvore fecha mais cedo (10.7.5): aceito.** Critério F4 8 passa a valer para o perfil típico (4–5/s, luta no amarelo), com ESTILO contando.
6. **Reserva da LOJA (2.3): aceita**, com o motivo sempre escrito no botão.
7. **Pera para o Boxe: correto** (escopo D; silhueta diferente do saco pesado).

Pronto para o Produtor mostrar ao dono.
