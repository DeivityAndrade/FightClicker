# Ronda 2a do Gato Preto, subfase 2a2 (o chefe Apagão): design

Designer de Jogo, 2026-11-26. Base: `ronda2a-escopo.md` (§3.2, §3.3, §5, §6 e as **Decisões do dono**: Apagão v2, `adv_slippery`,
troféu do capacete com a lanterna quebrada, só visual e lore), `ronda2a-design.md` (§11, ideias para a 2a2, e a Decisão do dono:
`cat_thanks` 0,2), `ronda2a1-revisao.md` (D5 e D7), `ronda2a-contrato.md` (API da 2a1), `ronda2a-textos.md` (textos do Apagão já
gravados), `docs/arte/tema-c-spec.md` §4 (parede do menu).
Simulador: `tools/sim/ronda2a_sim.py`, com 2 secções novas (`chefe` e `aprox_chefe`). Só acrescentei código; as secções da 2a1
rodam iguais.
Dados: `data/ronda.json → nights.alley.boss` (bloco novo) e 1 opção nova em `data/disciples.json` (`top_color.spark`).
**[ROT]** = texto novo para o Roteirista. Os textos do Apagão que já existem não mudam.

## 0. A ideia em uma frase
Com a **lenda 5**, os **3 bandidos vencidos** e o **Cinturão do Vale** na linhagem, o 4º cartão do quadro ESTA NOITE vira a noite do
**Apagão**. É a mesma noite da briga de beco (aproximação de 1 ocorrência e luta no motor, com a prévia honesta), com arena própria,
letreiro de entrada e o **apagão**, que é só visual. Quem vence ganha a ficha, o troféu, o título da imprensa e o cartaz no menu. Quem
vence **antes do apagão** ganha a versão rara do troféu e 1 estilo raro. Antes do apagão quer dizer: pegar o Apagão de surpresa na
caixa de luz e derrubá-lo até o fim do round 2, antes de ele puxar a alavanca (§3.3). Nada disso mexe em número.

## 1. Regras fixas (as mesmas da 2a1)
| Regra (escopo §2) | Como fica na 2a2 |
|---|---|
| Opcional, relógio parado | A noite do chefe é a noite `alley` (`ronda_ativa = "alley"`), com o mesmo congelamento |
| Não é luta da carreira | Mesma gravação da 2a1 (§3.4 de lá). O resultado vive só em `permanent.black_cat.boss` |
| Atributos crus e a arte do discípulo | Iguais aos da briga (`_atributos_cru()` e a passiva da arte com o extra dos nós) |
| Sorteio próprio | Semente do `_rng_ronda`, igual à briga |
| Sem código novo no motor | O Apagão é `[F, A, R, passiva]` com a `adv_slippery` da liga, com os mesmos números do Rony Sabão |
| Prévia honesta | Mesma `briga_previa()`: chance do motor com 200 sementes e chance do desafio nas mesmas 200 lutas. **O apagão não entra na conta, porque não muda nada** (§5) |
| Sem sangue, vulto sem rosto e sem nome | Como na 2a1. K.O. = "APAGOU!", e aqui a piada é literal |

## 2. Destrave
`nights.alley.boss.requires = {legend_level: 5, all_bandits: true, regional_belts_min: 1}`. As três condições valem juntas:
| Chave | Vale quando | Campo |
|---|---|---|
| `legend_level` 5 | nível da lenda ≥ 5 (lenda ≥ 80) | `permanent.black_cat.legend` (já existe) |
| `all_bandits` true | os 3 bandidos de `bandits` têm `won ≥ 1` (o desafio deles **não** conta) | `permanent.black_cat.alley` (2a1) |
| `regional_belts_min` 1 | a linhagem já ganhou o Cinturão do Vale | `permanent.regional_belts` (8a2; o marco `regional_belt_first` anda junto) |
- Chave desconhecida no `requires` = chefe indisponível, com aviso, como na 2a1.
- O chefe **não** depende do discípulo atual: com o cinturão da linhagem, um discípulo novo também pode ir (e a prévia mostra o
  quanto ele ainda está fraco).
- Antes disso, a ficha do chefe no Dossiê e o cartão do quadro mostram **o que falta**, um requisito por vez, nesta ordem:
  1. "PRECISA DA LENDA 5" (`dossier_missing_legend`, já existe);
  2. "VENÇA OS 3 DO BECO" (`dossier_missing_bandits` [ROT]);
  3. "PRECISA DO CINTURÃO DO VALE" (`dossier_missing_belt` [ROT]).
  É o D7a da revisão: a silhueta "??? LENDA 5" vira a ficha do Apagão (sempre silhueta e "???" até vencer, D7g).

### 2.1 O quadro ESTA NOITE (o D7b da revisão)
| Situação | 2º cartão do quadro (depois do SUSTO) |
|---|---|
| Ainda falta bandido | o próximo bandido (igual à 2a1) |
| 3 bandidos vencidos, chefe trancado | cartão do chefe **trancado**: silhueta, "???" e o texto do que falta. O botão IR fica desligado. Não existe mais o "O BECO ESTÁ QUIETO" aqui |
| Chefe aberto e ainda não vencido | cartão do chefe: retrato em silhueta, "???", perfil RÁPIDO, ícone e nome da passiva, desafio em 1 linha e marca REVANCHE se já perdeu. Tipo: "CHEFE" (`hideout_kind_boss` [ROT]) |
| Chefe vencido sem o desafio | o 2º cartão volta a ser "O BECO ESTÁ QUIETO. POR ENQUANTO." e entra o cartão menor **DESAFIO** do chefe no fim (como o dos bandidos) |
| Chefe vencido com o desafio | "O BECO ESTÁ QUIETO. POR ENQUANTO." e nenhum cartão do chefe |
Os cartões DESAFIO dos bandidos continuam como estão.

## 3. Atributos e passiva
| id | Nome / apelido (já gravados) | Perfil | Força | Agilidade | Resistência | Soma | Passiva | Desafio |
|---|---|---|---|---|---|---|---|---|
| `apagao` | NÉLSON VOLT / O APAGÃO | RÁPIDO | **105M** | **210M** | **310M** | **625M** | `adv_slippery` (Ensaboado, do Rony Sabão): o Clinch não prende. Na tela, "quem agarra leva choque e solta" | **ANTES DO APAGÃO**: SUSTO na aproximação **e** vitória por K.O. ou finalização até o fim do **round 2** (`surprise_early`, `max_round` 2; §3.3) |
(Para comparar: James 560M, `gate` 660M de soma.) A passiva é a da liga com os mesmos números (`thai_clinch`: `clinch_base` 0,3,
`clinch_cap` 0,3, `escape_base` 2,0) e as mesmas linhas de prévia. Só o sinal na tela muda de cara: faísca em vez de sabão
(Diretor de Arte; o id e o texto `opp_passive_*` continuam os da liga).

### 3.1 Como cheguei aos números (`ronda2a_sim.py chefe`, `SIM_BOSS_ESC="1.0,0.95,1.05"`, 12 jogadores × 12 campanhas por linha)
Robô padrão da 2a1 (8a2 com calendário, Legado, hall e centro; perfil médio na Ronda; vai em todo capuz; briga com ≥ 50% na prévia),
sem a 7a2. **Medida A (a meta do escopo):** a prévia contra o chefe com o discípulo no instante em que vence o James pela **1ª vez na
linhagem** (o 1º Cinturão do Vale), com 200 sementes por tática. Cada célula mostra a chance de vencer na melhor tática (mediana e
p25–p75), depois o desafio nessa tática e por fim o desafio na tática que mais o favorece. O desafio é contado **já com o SUSTO**. A
chance real por tentativa é essa vezes a do SUSTO (§3.3).

| Combinação | cps | 1º cinturão (campanha) | Nível da lenda nessa hora | Bandidos vencidos nessa hora | **1,00× (105M/210M/310M)** | 0,95× (100M/200M/294M) | 1,05× (110M/220M/326M) |
|---|---|---|---|---|---|---|---|
| Boxe Mão rápida | 4 | 8 | 5 | 2 | **39% (28–41)** / 21 / 21% | 68% / 50 / 50% | 17% / 8 / 8% |
| Boxe Mão rápida | 3 | 8 | 5 | 2 | **39% (17–41)** / 20 / 20% | 68% / 38 / 38% | 15% / 8 / 8% |
| Boxe Contragolpista | 4 | 9 | 5 | 2 | **48% (42–48)** / 0 / 0% | 56% / 0 / 2% | 41% / 0 / 0% |
| Boxe Contragolpista | 3 | 8 | 5 | 2 | **42% (30–46)** / 0 / 0% | 52% / 0 / 0% | 34% / 0 / 0% |
| JJ Finalização | 4 | 7 | 5 | 2 | **60% (42–61)** / 10 / 10% | 72% / 12 / 12% | 47% / 8 / 8% |
| JJ Finalização | 3 | 8 | 5 | 2 | **53% (50–57)** / 9 / 9% | 67% / 12 / 12% | 41% / 6 / 6% |
| JJ Por cima | 4 | 7 | 5 | 2 | **58% (40–58)** / 6 / 6% | 72% / 12 / 12% | 46% / 2 / 2% |
| JJ Por cima | 3 | 8 | 5 | 2 | **57% (54–60)** / 6 / 6% | 72% / 13 / 13% | 46% / 2 / 2% |
| MT Canela | 4 | 9 | 5 | 2 | **36% (27–46)** / 12 / 14% | 48% / 17 / 17% | 29% / 8 / 12% |
| MT Canela | 3 | 8 | 5 | 2 | **28% (20–38)** / 8 / 13% | 38% / 12 / 15% | 20% / 6 / 9% |
| MT Clinch | 4 | 8 | 5 | 2 | **9% (2–10)** / 0 / 1% | 18% / 0 / 1% | 4% / 0 / 0% |
| MT Clinch | 3 | 8 | 5 | 2 | **2% (2–6)** / 0 / 0% | 8% / 0 / 1% | 2% / 0 / 0% |
| **Todas** | | | | | **40% (p25–p75 21–53%; p10–p90 6–60%)**; desafio máx. 8% (p90 21%) | 55% (33–69%); 12% (p90 41%) | 29% (14–41%); 3% (p90 12%) |

**Escolha: 1,00× = 105M / 210M / 310M (soma 625M)**, ~0,95× da sonda da 2a1. A mediana de 40% fica no meio da faixa de 30–50%. O ponto
de partida (110M/220M/325M, a coluna 1,05×) dá 29%, logo abaixo da faixa. A curva é muito íngreme: ±5% nos atributos movem a mediana
em 11–15 pontos.

### 3.2 Leitura, e o que acontece jogando de verdade
- **Cada arte tem o seu chefe chato, como na liga.** O Ensaboado trava o Clinch: o Muay Thai Clinch fica com 2–9% no dia do cinturão
  (é o Rony Sabão de novo), e o Jiu-jitsu fica com 53–60%. O Contragolpista quase nunca derruba cedo (desafio 0%), mas vence por
  pontos.
- **Na hora do 1º cinturão, a linhagem ainda não pode ir.** Em todas as linhas, o 1º cinturão chega com a lenda 5 e só **2** bandidos
  vencidos. O 3º bandido (`gate`, 660M de soma) cai depois, na mesma campanha.
- **Medida B: o chefe na noite em que ele de fato abre.** É a mesma corrida, com o robô indo ao chefe sempre que a prévia dá ≥ 50%.
  | Escala | Chefe abre (campanha) | Campanhas depois do 1º cinturão | Chance na 1ª noite aberta | 1ª vitória | Derrotas antes | Desafio por tentativa (real) | Raro feito | Vencido sem raro no fim |
  |---|---|---|---|---|---|---|---|---|
  | **1,00×** | **8 (7–9)** | 0 | **100%** (p25–p75 100–100) | campanha 8, 140 de 144 linhagens | 0 | **14%** (789 tentativas) | 109 de 140 (campanha 9, 3ª tentativa) | 31 |
  | 0,95× | 8 (7–9) | 0 | 100% | campanha 8 | 0 | 15% | 113 | 27 |
  | 1,05× | 8 (7–9) | 0 | 100% | campanha 8 | 0 | 14% | 104 | 36 |
- **O que isso quer dizer:** quem tem os 3 requisitos já venceu o `gate` (660M, maior que o chefe em soma), e o discípulo cresce muito
  de um capuz para o outro (240 s de sala no fim da campanha). Por isso **a vitória sobre o chefe sai na 1ª noite**, com 100% na
  prévia, em qualquer escala até ~2×. Na sonda com 3× (330M/660M/975M), a 1ª noite aberta dá 8% e a seguinte já dá 100%. **Nenhum
  número fixo segura o chefe** contra o crescimento de uma campanha, e mexer nisso seria número novo de motor ou de economia, que a
  2a não pode ter. A meta dos 30–50% vale como o escopo pede, no instante do cinturão, e a prévia mostra isso a quem tenta cedo, por
  exemplo um discípulo novo da linhagem com o cinturão. **A dificuldade real do chefe mora no desafio** (§3.3). Ver a pergunta ao dono.

### 3.3 O desafio "ANTES DO APAGÃO" (`surprise_early`): por que juntar surpresa e K.O. cedo
- **O problema do K.O. até o round 2 sozinho (`early_finish`):** na 1ª noite aberta, o desafio dá **100%** na prévia (medida B). Com o
  discípulo 2 a 3 vezes mais forte, o K.O. sai no round 1. Assim, o raro viria junto com a vitória em ~99% das linhagens (medido com
  o `early_finish` puro na 1ª rodada desta simulação: desafio feito em 99% das 1ªs vitórias). O "≤ 20% por tentativa" só valeria no
  papel.
- **A saída sem código de motor:** o desafio passa a pedir também o **SUSTO** na aproximação. A aproximação é de habilidade, não de
  atributo, então **não fica fácil com o crescimento**. Na história, é pegar o Apagão de surpresa na caixa de luz, antes de ele puxar a
  alavanca, e derrubá-lo antes do apagão. O tipo `surprise_early` é `surprise` **e** `early_finish` juntos. Os dois já existem na 2a1.
  Só a regra que junta é nova, e ela fica na lógica de estado, não no motor.
- **A aproximação do chefe** (`aprox_chefe`, 2.000 noites por perfil): `gap` 0,8–1,2 s, `warn_s` 0,35, `look_s` 1,9, AVISO falso 30%. Ele
  trabalha pouco e olha muito, e o 8 s aperta. É a mais difícil do beco:
  | Perfil | SUSTO | VISTO | TEMPO |
  |---|---|---|---|
  | Atento | **20%** | 8% | 72% |
  | Médio | **18%** | 30% | 52% |
  | Distraído | **5%** | 95% | 0% |
  (Os 3 bandidos saem idênticos à 2a1, com 73/60/41, 95/73/21 e 90/79/60%: as secções novas não mexem neles.)
- **Chance por tentativa:**
  - no instante do cinturão (medida A): SUSTO 18% × desafio 8% (p90 21%) ≈ **1,5% (p90 ~4%)**;
  - jogando de verdade (medida B): **14% por tentativa** (789 noites do chefe; o robô volta pelo cartão DESAFIO com a tática de maior
    chance de desafio). O raro sai na **3ª tentativa** (mediana), e 31 de 140 linhagens ainda não o tinham ao fim de 12 campanhas.
  - O teto prático é o SUSTO do perfil: **≤ 20%** até para o atento. Isso cumpre o "raro ≤ 20% por tentativa".
- **Prévia honesta:** sem SUSTO, a prévia diz "DESAFIO: PERDIDO" antes do LUTAR, e o jogador sabe que aquela noite é só pela vitória.
  Com SUSTO, ela mostra CHANCE DO DESAFIO: N% por tática.
- **Alavancas:** `approach` (`look_s` e `gap` mexem mais) e `max_round`. Se o dono preferir o desafio só com o K.O. cedo, basta trocar
  `type` para `early_finish` no `ronda.json` (e o texto). Mas aí o raro vem quase sempre com a 1ª vitória.

## 4. A noite do chefe
### 4.1 Linha do tempo (≤ ~50 s)
| Passo | Tempo | O que muda da briga |
|---|---|---|
| Contagem | 2 s | o desafio "ANTES DO APAGÃO" em letra menor |
| Aproximação | até 8 s | 1 ocorrência (`boss.approach`): o Apagão mexendo na caixa de luz do poste. É a mais alerta do beco (§3.3). SUSTO = lenda +1 e a 1ª metade do desafio. Ser visto não cancela a luta |
| Prévia | o jogador decide | a mesma da briga. Sem SUSTO: "DESAFIO: PERDIDO" (`alley_ch_lost`). Com SUSTO: CHANCE DO DESAFIO: N% por tática |
| Entrada | **1,5 s** (`entrance_s`) | **letreiro de entrada** "O APAGÃO" (`alley_apagao_entrance` [ROT]) com o poste piscando. Só na luta do chefe |
| Luta | ≤ 19 s | arena `arena_apagao` (o beco do poste, com a caixa de luz aberta e fios) |
| Apagão | 1 s, dentro da luta | §5 |
| Prêmio | ~4 s | ficha, troféu, título e cartaz (§6) |
Contagem + aproximação ≤ 10 s, entrada 1,5 s, luta ≤ 19 s, prêmio ~4 s e prévia ~5–10 s: **~40–50 s**, dentro dos ~60 s.

### 4.2 Lenda, contadores, derrota e revanche (iguais aos dos bandidos)
- Lenda da noite = `floor` 1 + `per_scare` 1 (SUSTO) + `win` 2 (vitória): **1 a 4**, o mesmo bloco `nights.alley.legend`. A lenda 5 já
  é o nível máximo, então a lenda do chefe não abre nada.
- `rounds` +1 em toda noite que chega ao LUTAR; `scares` +1 com SUSTO.
- **Perder:** o vulto "SAIU MANCANDO", sem ficha, sem troféu, sem título, sem cartaz e sem estilo. O capuz é gasto e volta no próximo
  relógio (240 s de sala). O chefe ganha a marca REVANCHE (`lost ≥ 1` e `won = 0`). Nada cai, nada some. Carreira, Legado, FAMA, dias e
  AQUECIDO não mudam.
- **Vencer sem o desafio:** ganha os prêmios da vitória (§6) e o chefe volta ao quadro como cartão **DESAFIO**. Vencer de novo sem
  cumprir só dá a lenda. Vencer de novo **cumprindo** dá o raro.
- **SAIR** na aproximação ou na prévia: nada gravado e o capuz continua no prego (igual à 2a1).
- Gravação única no LUTAR (§3.4 da 2a1): fechar no meio da luta ou do prêmio não duplica nem perde nada.

## 5. O apagão (só apresentação)
- **Quando:** na virada do round 2 para o 3 (`t = after_round × round_length` = 2 × 5,33 = **10,67 s** do relógio da luta), **se a luta
  ainda não acabou**.
- **O que se vê:** ele puxa a alavanca da bateria, o beco escurece por **1 s** (`dark_s`) e ficam acesos só a luz da bateria e os olhos
  do vulto. Depois a luz volta, piscando. Os golpes desse segundo continuam acontecendo (os eventos já estão sorteados); a tela só os
  desenha no escuro.
- **O que não muda:** nenhum evento, dano, sorteio, tempo ou chance. A prévia não sabe do apagão, e o `ronda2a_casos.json` do chefe
  bate golpe a golpe com e sem ele.
- **O desafio conversa com ele:** derrubar até o fim do round 2 é, literalmente, derrubar o Apagão **antes** de ele puxar a alavanca.
  Quem cumpre o desafio nunca vê o apagão. Quem vê o apagão já sabe que perdeu o raro, mas ainda pode vencer.
- Dados: `boss.blackout {after_round 2, dark_s 1.0, visual_only true}`. Se o `round_length` mudar, o apagão acompanha.

## 6. Prêmios
### 6.1 O que vem com cada coisa
| Conquista | Prêmio | Onde aparece | De onde sai no save |
|---|---|---|---|
| **Vencer** (1ª vez) | Ficha do chefe no Dossiê (retrato, nome, apelido, ficha corrida, manchete, testemunha da semente da 8b, carimbo "VENCIDO NA {n}ª CAMPANHA") | Esconderijo, 4ª ficha | `boss.apagao.won ≥ 1` |
| | **Troféu**: capacete com a lanterna quebrada | Esconderijo, prateleira, lugar 1 de 4 | `won ≥ 1` |
| | **Título da imprensa** "O VULTO QUE RELIGOU A LUZ" (`press_title_apagao`) | carimbo grande na ficha do chefe e linha no prêmio | `won ≥ 1` |
| | **Cartaz no menu**: o cartaz de "PROCURA-SE" do Apagão rasgado, com a manchete | canto livre de baixo à direita da parede do menu (§6.3) | `won ≥ 1` |
| | Recorte curto `alley_apagao_clipping` | só no prêmio e no hover da ficha. **Não** vira papel novo na parede da sala (os 3 pontos da sala são dos bandidos) | — |
| **Desafio** "ANTES DO APAGÃO" | **Troféu raro**: o mesmo capacete com a lâmpada **acesa** e dourada. Ele **troca** o normal no mesmo lugar da prateleira | Esconderijo | `boss.apagao.challenge` |
| | **Estilo raro** `blackout_spark`: camisa **FAÍSCA** [ROT], azul-claro com o brilho branco, marcado com o gato dourado | personalização do **próximo discípulo** (fim da lista de cor da camisa) | derivado: `challenge` |
- Escolhi a troca no mesmo lugar porque o escopo fala em "versão rara do troféu": a prateleira mostra **1 capacete por chefe**, que
  melhora. Sobram 3 lugares para os chefes dos próximos capítulos (o jogador vê que há mais).
- Desafio feito na 1ª vitória = os prêmios das duas linhas na mesma tela, numa gravação só.

### 6.2 O estilo raro (só cor)
| Estilo (id) | Campo e opção em `disciples.json` | Cores (tokens) | Marca |
|---|---|---|---|
| `blackout_spark` | `top_color` → `spark` | `b2` #4d7bb3, `b3` #8fbbe0, `white` #f2ece0 | `mark: "cat"` e `rare: true` (gato dourado) |
- Por que a camisa: é o único campo de cor do corpo que ainda não tem estilo da noite. Não precisa de arte nova (a camisa já é
  pintada pelas cores do `disciples.json`), e o azul-claro de faísca não se confunde com o `blue` de hoje (`b0`/`b1`/`b2`).
- **Regras da 2a1, todas iguais:** `enabled: false`, `requires: "black_cat_style:blackout_spark"`; nunca entra no sorteio do rascunho;
  aparece só liberada, no fim da lista; `ligar_todas_as_opcoes()` a pula; look sujo com `spark` sem o estilo = volta ao padrão.
- `rare: true` é campo novo e opcional: só troca o gato da marca pelo gato dourado. Quem não conhece o campo, ignora.
- Aviso para a UI: com `top = none` (peito nu) a cor da camisa não aparece. É assim com todas as cores de camisa. A personalização
  já mostra a cor só quando há camisa.
- `estilo_liberado("blackout_spark")` sai da ficha do chefe (`boss.apagao.challenge`), não de um bandido. Esse é o único ponto em que
  a regra "estilo = ficha com `challenge`" passa a olhar também o `boss`.

### 6.3 O cartaz no menu (marco no `parede.json`)
Camada nova, **a última da lista** (por cima das outras):
```
{"id": "apagao", "file": "res://assets/sprites/menu/menu_item_apagao.png",
 "note": "cartaz PROCURA-SE do Apagão, rasgado, com a manchete (o chefe da Ronda 2a vencido)",
 "pos": [~470, ~284], "size": [~52, ~60],
 "requires": {"black_cat_boss_won": "apagao"}}
```
- **Requisito novo** `black_cat_boss_won: "<id>"` = `permanent.black_cat.boss.<id>.won ≥ 1`. É 1 caso a mais no `_requisito_ok()` do
  `menu_opcoes.gd`. O código antigo trata chave desconhecida como "não vale", então o cartaz nunca aparece por engano.
- **Por que não um marco da escola:** gravar um `school.milestones` novo mudaria a foto de quem briga (critério 2). Tudo do Gato Preto
  fica em `permanent.black_cat`, que a foto já apaga.
- A posição e o tamanho são do **Diretor de Arte**, no canto de baixo à direita que o tema C reservou (spec §4). O gerador
  `make_tema_c.gd` confere a folga (sem cobrir a versão, sem entrar na coluna dos botões e 2 px de folga).
- Sem versão rara no menu: o raro vive na prateleira.

### 6.4 Onde fica no save (v13, só campo opcional, sem migração)
`permanent.black_cat` ganha **um** campo opcional, irmão do `alley`:
`boss: {"apagao": {"won": int ≥ 0, "lost": int ≥ 0, "first_win_campaign": int ≥ 0, "challenge": bool}}`
- O formato é o da ficha de bandido, por id de chefe (os chefes dos próximos capítulos entram como chaves novas). Ausente = nunca lutou.
  Grava só com `won + lost > 0`.
- **Tudo é derivado** desses 4 números: ficha, troféu (normal com `won ≥ 1`, raro com `challenge`), título, cartaz e estilo. Não há
  lista de troféus nem de títulos para ficar inconsistente.
- Validação (a mesma do `alley`): número ruim ou negativo = 0; gigante = teto 1e9; `challenge` com `won = 0` = false (aviso); id
  desconhecido = ignorado (aviso); `first_win_campaign` maior que a campanha atual = campanha atual. **Chefe vencido sem os
  requisitos** (save sujo: sem os 3 bandidos ou sem cinturão) = mantém, porque já foi ganho, com aviso.
- A foto (`foto.gd`) já apaga `permanent.black_cat` inteiro: nada muda lá. A cópia do save do dono abre igual (o campo não existe).

## 7. Teto de 10% (critério 3, D5 da revisão)
- **A 2a2 soma 0 por construção.** A noite do chefe congela o jogo como a briga e dá lenda de 1 a 4. A lenda 5 já é o nível máximo
  antes de o chefe abrir, então essa lenda não abre nada. Os prêmios são só ficha, troféu, título, cartaz e cor. Nenhum valor de equipe,
  Legado, região ou economia mudou (`cat_thanks` continua 0,2).
- **Medido** (`SIM_TETO_VARS="so_7a2,so_regiao,tudo_max,tudo_piso" ronda2a_sim.py teto`, 24 jogadores, 6 combinações × 4 e 3/s ×
  CENTRO cheio e vazio, numa corrida só, com os dados da 2a2): **pior trecho = 8,8%** (Boxe Contragolpista 4/s, CENTRO cheio, na
  Muralha, em `so_regiao`; o `tudo_max` mais alto é o mesmo, 8,8%). É o mesmo 8,8% da revisão da 2a1. Margem de 1,2 ponto até o teto.
  | Combinação | `tudo_max` pior trecho (CENTRO 1 / 0) |
  |---|---|
  | Boxe Mão rápida 4 / 3 | 5,6 / 7,3% · 4,5 / 4,7% |
  | Boxe Contragolpista 4 / 3 | **8,8** / 5,8% · 6,5 / 7,2% |
  | JJ Finalização 4 / 3 | 6,6 / 7,9% · 8,7 / 8,2% |
  | JJ Por cima 4 / 3 | 6,6 / 8,0% · 8,1 / 7,6% |
  | MT Canela 4 / 3 | 4,7 / 6,6% · 6,2 / 5,6% |
  | MT Clinch 4 / 3 | 6,1 / 6,2% · 6,9 / 5,3% |
- A secção `aprox` dos 3 bandidos sai idêntica à da 2a1. As secções novas do simulador só acrescentam.

## 8. Contrato de dados e API
### 8.1 `data/ronda.json → nights.alley.boss` (já gravado)
| Campo | Valor | Para quê |
|---|---|---|
| `id` | `apagao` | chave no save e nos ids de arte |
| `requires` | `{legend_level 5, all_bandits true, regional_belts_min 1}` | §2 |
| `approach` | `{id apagao, name alley_occ_apagao, spot beco_poste, gap_min 0,8, gap_max 1,2, warn_s 0,35, look_s 1,9, fake_warn 0,3}` | aproximação (formato das ocorrências; §3.3) |
| `name`, `nickname`, `profile` | `alley_apagao_name`, `alley_apagao_nick`, RÁPIDO | |
| `strength`, `agility`, `endurance` | 105.000.000 / 210.000.000 / 310.000.000 | §3 |
| `passive` | `adv_slippery` (formato da liga) | |
| `challenge` | `{type surprise_early, max_round 2, text alley_ch_apagao}` | §3.3. **Tipo novo** de desafio (lógica de estado, não do motor): `surprise` **e** `early_finish` juntos |
| `dossier` | `portrait alley_apagao_portrait`, `rap_sheet`, `headline`, `witness` (`alley_apagao_*`) | ficha |
| `clipping` | `alley_apagao_clipping` | prêmio e hover |
| `arena` | `arena_apagao` | arena própria (a da briga continua `arena_alley`) |
| `entrance_banner`, `entrance_s` | `alley_apagao_entrance` [ROT], 1,5 | letreiro de entrada |
| `blackout` | `{after_round 2, dark_s 1.0, visual_only true}` | §5 |
| `trophy` | `{id apagao_helmet, slot 0, sprite trophy_apagao, sprite_rare trophy_apagao_rare, name trophy_apagao_name, name_rare trophy_apagao_rare_name}` | prateleira |
| `press_title` | `press_title_apagao` | título |
| `menu_layer` | `apagao` | id da camada do `parede.json` (para o teste conferir) |
| `style` | `{id blackout_spark, field top_color, option spark}` | estilo raro |
Validação (`RondaData`): `boss` ausente = 2a1 igual a hoje (a ficha "??? LENDA 5" continua). Atributos > 0, `passive` como na liga,
`challenge.type` da lista (senão sem desafio, sem raro e sem estilo, com aviso), `style.field/option` precisa existir no
`disciples.json` com `requires` igual a `black_cat_style:<id>`, `trophy.slot` de 0 a 3, `blackout.after_round` ≥ 1.

### 8.2 `data/disciples.json` (já gravado)
`top_color.spark`: `enabled: false`, `requires: "black_cat_style:blackout_spark"`, `mark: "cat"`, `rare: true`, cores e tokens do §6.2.

### 8.3 Estado e API (módulo `scripts/estado/briga_beco.gd`; o Programador decide se o chefe vira um módulo irmão)
| Função | Mudança |
|---|---|
| `chefe_aberto() -> bool` | nova: §2 |
| `esconderijo()` | `boss` passa a ser `{id, known, won, lost, first_win_campaign, challenge, open, missing_text, portrait, name, nickname, rap_sheet, headline, witness, clipping, press_title, profile, passive {id, name, icon}, challenge_text, stamp, revenge}` ("???" e textos vazios enquanto não venceu, como no `dossie()`). `trophies`: lista de 4 lugares `[{slot, id, state "empty"\|"normal"\|"rare", sprite, name}]` |
| `quadro_noite()` | cartão `{night "boss", boss "apagao", locked, missing_text, ...os campos do cartão de bandido}` (§2.1). `challenge_only` vale para o chefe |
| `ronda_ir("alley", "apagao")` | aceita o id do chefe (só com `chefe_aberto()`; senão `{}`). Devolve o dicionário da briga com `boss: true`, `entrance_banner`, `entrance_s`, `arena "arena_apagao"` e `blackout` |
| desafio `surprise_early` | `_cumpriu()`: aproximação = SUSTO **e** `win` **e** `ko` **e** `round ≤ max_round`. Prévia: `done` = false e `by_tactic` vazio sem SUSTO (linha "DESAFIO: PERDIDO"); com SUSTO, `by_tactic` = a contagem do `early_finish` nas mesmas 200 lutas. `RondaData` aceita o tipo novo (lista de `challenge.type`) |
| `briga_previa()` / `briga_lutar(t)` | iguais, com o chefe no lugar do bandido. O retorno da luta ganha `boss: true`, `entrance_banner`, `entrance_s`, `blackout {t, dark_s}` (o `t` só vem se `t_end > t`; senão `{}`). `night_prize` ganha `boss: true`, `trophy_new` (`"" \| "normal" \| "rare"`), `press_title_new` (bool), `poster_new` (bool) e as linhas `trophy_line`, `press_title_line`, `poster_line` |
| `estilo_liberado("blackout_spark")` | olha `boss.apagao.challenge` |
| `parede_menu()` | requisito `black_cat_boss_won` (§6.3) |
| sinais | os da 2a1 (`dossie_mudou`, `lenda_mudou`, `permanente_mudou`) |

### 8.4 Chaves de texto novas [ROT]
`alley_occ_apagao` e `alley_occ_apagao_anon` (topo da aproximação), `alley_apagao_anon` (prévia, antes de vencer),
`alley_apagao_entrance` (letreiro, ex. "O APAGÃO"), `alley_ch_apagao` (ex. "ANTES DO APAGÃO: SURPRESA E K.O. ATÉ O 2º ROUND"; o
"2º" acompanha o `max_round`), `hideout_kind_boss` (CHEFE), `dossier_missing_bandits` (VENÇA OS 3 DO BECO), `dossier_missing_belt` (PRECISA DO CINTURÃO
DO VALE), `trophy_apagao_name` (ex. CAPACETE DA LANTERNA QUEBRADA), `trophy_apagao_rare_name` (ex. CAPACETE ACESO),
`alley_boss_prize_title` (ex. O BECO ACENDEU), `alley_trophy_new`, `alley_trophy_rare`, `alley_press_title_new` (TÍTULO DA IMPRENSA:
{titulo}), `alley_poster_new` (CARTAZ NA PAREDE DO MENU), `disc_opt_top_color_spark` (FAÍSCA). Já existem e não mudam:
`alley_apagao_name|nick|rap|headline|witness|clipping` e `press_title_apagao`. Busca por sangue/blood e batman/morcego/gotham = 0.

## 9. Critérios de aceite (2a2), ligados ao escopo §6
| # | Critério | Escopo |
|---|---|---|
| B1 | `foto.gd` de uma campanha inteira com o capuz nunca usado é **idêntica** à da main de hoje. O `boss` fica dentro de `permanent.black_cat`, e a camada nova do menu não grava nada | 1 |
| B2 | Teste roteirizado: a mesma campanha jogada (a) só com SUSTO e (b) com o chefe (perdendo e vencendo, com e sem desafio) sai com o save igual campo a campo, tirando só `permanent.black_cat` e `career.black_cat_hood`. Inclui a sucessão seguinte com `blackout_spark` liberado: o rascunho sorteado é o mesmo. Nenhum `school.milestones` novo | 2, 10 |
| B3 | `ronda2a_sim.py teto` com os dados da 2a2: pior trecho = **8,8% ≤ 10%** (o mesmo da 2a1, porque a 2a2 soma 0). Resultado registrado no §7 | 3 |
| B4 | Perder do chefe: carreira segue; Legado, FAMA, dias e AQUECIDO iguais; lenda +1 (+1 com SUSTO); capuz volta em 240 s de sala; REVANCHE no cartão; nada do Dossiê e da prateleira some | 4 |
| B5 | Destrave, com um save por caso: (a) lenda 79 com os 3 bandidos e o cinturão → chefe trancado "PRECISA DA LENDA 5"; (b) lenda 80, 2 bandidos e cinturão → "VENÇA OS 3 DO BECO"; (c) lenda 80, 3 bandidos e `regional_belts` 0 → "PRECISA DO CINTURÃO DO VALE"; (d) tudo junto → cartão do chefe com IR. Em (a)–(c), `ronda_ir("alley","apagao")` devolve `{}` | 5 |
| B6 | A chance da prévia é a do motor (`briga_previa()` = `chance_detalhada` com o array do chefe) e bate com os casos do Apagão em `tests/data/ronda2a_casos.json` (regerar com `ronda2a_sim.py exportar`, que passa a incluir o chefe). No simulador (`ronda2a_sim.py chefe`), o discípulo que acabou de ganhar o 1º cinturão tem **40%** de mediana (meta 30–50%), e o desafio fica em **≤ 20%** por tentativa: 14% jogando de verdade e SUSTO ≤ 20% em todos os perfis (§3.1–3.3). Sem SUSTO, a prévia mostra "DESAFIO: PERDIDO". A luta usa só o `_rng_ronda` | 6 |
| B7 | O apagão é só visual: a mesma luta (semente fixa) dá os mesmos eventos e o mesmo resultado com `blackout` presente e ausente; ele só aparece quando `t_end > 10,67 s`; uma luta vencida até o round 2 nunca mostra o apagão | 6 |
| B8 | Noite do chefe inteira (aproximação, prévia, entrada, luta animada e prêmio) cronometrada em ≤ ~60 s (D6 da revisão vale aqui também); SAIR na aproximação não gasta o capuz | 7 |
| B9 | Letreiro de entrada, K.O. com letreiro, tremida e queda; busca por sangue/blood = 0; o vulto nunca mostra o rosto nem o nome; o chefe é silhueta e "???" em todo lugar até ser vencido (D7g) | 8 |
| B10 | Busca por batman/morcego/gotham = 0; o dono aprovou a amostra do Apagão v2 e da arena antes do elenco (D7f) | 9 |
| B11 | Vitória: ficha, capacete normal no lugar 1, título na ficha e cartaz no menu (com save; sem save, não). Desafio: o capacete vira o raro **no mesmo lugar** e a camisa FAÍSCA aparece no fim da lista de cor da camisa, com o gato dourado, só na personalização do próximo discípulo. Tudo persiste entre discípulos. O estilo não muda nenhum número (B2) | 10 |
| B12 | Save v13: fechar na aproximação ou prévia = nada; fechar na luta ou prêmio = prêmio gravado uma vez só; saves sujos do §6.4 carregam com aviso; a cópia do save do dono abre | 11 |
| B13 | `tools/run_tests.ps1` verde, com save de teste, `--position 1950,40` e um Godot por vez | 12 |
| B14 | `ui_audit --estrito` com 0 problemas, cobrindo: o Esconderijo com o chefe trancado, aberto, vencido e raro (prateleira com 1 capacete normal e com o raro); o quadro com o cartão do chefe e o DESAFIO do chefe; a prévia do chefe; a entrada com letreiro; a luta na `arena_apagao`; o apagão (quadro escuro); o prêmio normal e o raro; o menu com o cartaz; a personalização com a FAÍSCA. Placar de `ignore` ≤ 15, e as telas novas sem `ignore` | 13 |

## 10. Quem faz o quê
- **Programador:** `RondaData` (`boss`), destrave (§2), quadro e Esconderijo (§2.1, §8.3), `ronda_ir`/`briga_previa`/`briga_lutar` com o
  chefe, `permanent.black_cat.boss` e a validação, `estilo_liberado` do raro, requisito `black_cat_boss_won` no menu, `exportar` com o
  chefe, testes B1–B8, B11–B13 e o `docs/codigo/mapa.md`.
- **UI/UX:** cartão do chefe (trancado, aberto, DESAFIO), ficha com o carimbo do título, prateleira com 4 lugares (normal, raro e
  vazio), letreiro de entrada, apagão (escurecer 1 s em cima da luta, sem tocar nos eventos), prêmio do chefe, gato dourado na
  personalização. `alinhamento-ui` até 0 (B14).
- **Diretor de Arte / Artista de Personagens:** amostra do Apagão v2 (corpo exagerado) e da arena para o dono **antes** do elenco (D7f);
  folha de luta (guarda, golpe, choque, levar golpe, queda "apagou", fuga), retrato e silhueta; `arena_apagao`; os 2 capacetes;
  `menu_item_apagao.png` com a posição conferida no gerador; o sinal do Ensaboado com cara de faísca; a capa desenhada à mão (D2 da
  revisão) antes desta luta.
- **Roteirista:** as chaves do §8.4.
- **QA:** §9, com `ronda2a_sim.py chefe` e `teto` como referência.

## 11. Decisões do Designer (revisar com o dono)
| # | Decisão | Por quê | Alternativa |
|---|---|---|---|
| E1 | Troféu raro **troca** o normal no mesmo lugar | é a "versão rara" do escopo; 1 capacete por chefe deixa 3 lugares para os próximos | os 2 capacetes lado a lado (gasta 2 dos 4 lugares) |
| E2 | Estilo raro = cor da camisa (FAÍSCA, azul-claro) | único campo de cor sem estilo da noite; sem arte nova | dourado (`y1`/`y2`), mais "lâmpada acesa", mas perto demais do `yellow` |
| E3 | Cartaz no menu vem com a **vitória** (não com o raro) | escopo §3.3; o menu mostra o que o jogador viveu | cartaz só com o raro |
| E4 | Requisito novo do menu em `permanent.black_cat` em vez de marco da escola | marco novo mudaria a foto de quem briga (critério 2) | marco `black_cat_boss_won` |
| E5 | O chefe não ganha papel novo na sala | os 3 pontos da sala são dos bandidos; o lugar do chefe é o menu e a prateleira | 4º recorte nos 3 locais (arte em 3 lugares) |
| E6 | Desafio = SUSTO **e** K.O. até o round 2 (`surprise_early`) | com o K.O. cedo sozinho, o raro sai em ~99% das 1ªs vitórias. A surpresa não fica fácil com o crescimento: 14% por tentativa | só o K.O. até o round 2 (`early_finish`), como na proposta da 2a1 |
| E7 | Atributos 105M/210M/310M (0,95× da sonda da 2a1) | 40% de mediana no 1º cinturão, no meio da meta | 110M/220M/325M (29%, abaixo da meta) |

## 12. Perguntas ao dono
- **P1. A vitória sobre o chefe sai fácil jogando de verdade. Tudo bem?** Os 40% valem para o discípulo do 1º cinturão, mas o chefe
  só abre depois do 3º bandido, que é mais forte que ele. Na 1ª noite aberta, a prévia dá ~100%. Nenhum número fixo muda isso, porque
  o discípulo cresce de um capuz para o outro. **Recomendo aceitar**: o chefe é o fecho da história da 2a, a prévia continua honesta, e
  o difícil de verdade (e raro) é o troféu aceso e a camisa FAÍSCA. Uma vitória difícil de verdade pediria número novo de economia ou
  de motor. Isso fica para a 8b, se o dono quiser.
- **P2. O desafio "ANTES DO APAGÃO" pede a surpresa também (E6).** **Recomendo** assim. Se o dono quiser só o K.O. até o round 2, é 1
  campo no `ronda.json`, mas o raro deixa de ser raro.

## Resumo
- **Destrave:** lenda 5, os 3 bandidos vencidos e `permanent.regional_belts ≥ 1`. Antes disso, a ficha e o cartão mostram o que falta,
  um requisito por vez.
- **Apagão:** 105M / 210M / 310M (625M), RÁPIDO, `adv_slippery`. Com o discípulo do 1º cinturão, a prévia dá **40% de mediana**
  (p25–p75 21–53%). Jogando de verdade, ele só abre depois do 3º bandido e cai na 1ª noite (P1).
- **Desafio "ANTES DO APAGÃO" = SUSTO e K.O. até o round 2** (`surprise_early`). A aproximação é a mais difícil do beco (SUSTO
  20/18/5%), o que dá **14% por tentativa** jogando de verdade (≤ 20%). O raro sai, em mediana, na 3ª tentativa.
- **Apagão:** 1 s de escuro na virada do round 2 para o 3, só visual. Chance, eventos e prévia não mudam.
- **Prêmios:** a vitória dá a ficha, o capacete no lugar 1 da prateleira, o título "O VULTO QUE RELIGOU A LUZ" e o cartaz no menu. O
  desafio dá o capacete aceso, que troca o normal no mesmo lugar, e a camisa FAÍSCA (`top_color.spark`), só no próximo discípulo.
- **Save v13:** 1 campo opcional, `permanent.black_cat.boss.apagao {won, lost, first_win_campaign, challenge}`. Tudo o mais é derivado.
  O menu ganha o requisito `black_cat_boss_won`, sem marco da escola.
- **Teto:** a 2a2 soma 0. Pior trecho com tudo junto = **8,8%**, igual à 2a1.
