# Ronda 2a do Gato Preto, subfase 2a2 (o chefe Apagão): design

Designer de Jogo, 2026-11-26. Base: `ronda2a-escopo.md` (§3.2, §3.3, §5, §6 e as **Decisões do dono**: Apagão v2, `adv_slippery`,
troféu do capacete com a lanterna quebrada, só visual e lore), `ronda2a-design.md` (§11, ideias para a 2a2, e a Decisão do dono:
`cat_thanks` 0,2), `ronda2a1-revisao.md` (D5 e D7), `ronda2a-contrato.md` (API da 2a1), `ronda2a-textos.md` (textos do Apagão já
gravados), `docs/arte/tema-c-spec.md` §4 (parede do menu).
Simulador: `tools/sim/ronda2a_sim.py`, com 2 secções novas (`chefe` e `aprox_chefe`). Só acrescentei código; as secções da 2a1
rodam iguais.
Dados: `data/ronda.json → nights.alley.boss` (bloco novo) e 1 opção nova em `data/disciples.json` (`shorts_color.live_wire`).
**[ROT]** = texto novo para o Roteirista. Os textos do Apagão que já existem não mudam.

**Revisão de 2026-11-26, com as decisões do dono:** Apagão mais forte, que cai 1–2 campanhas depois de abrir (§3); o capuz a cada
**300 s**, com os limiares da lenda reajustados (§2.2); estilo raro FIO DESENCAPADO (§6.2); o desafio com a surpresa mantido (§3.3);
e o teto medido de novo (§7).

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
| `legend_level` 5 | nível da lenda ≥ 5 (lenda ≥ **64** com os limiares novos do §2.2; era 80) | `permanent.black_cat.legend` (já existe) |
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

### 2.2 Menos noites: o capuz a cada 300 s (decisão do dono, 2026-11-26)
**A regra.** `hood.interval_s` vai de 240 para **300** (5 min de sala). O resto continua igual e vale para o SUSTO, as brigas e o
chefe, porque o capuz é um só:
- o 1º capuz da campanha continua aos **180 s** (`first_after_s`);
- o relógio continua sendo o `capuz.hood_s`, que só anda com a sala ativa e fica parado fora da sala (janela, luta, cena, fala, treino
  fora, Ronda, dia da luta);
- o capuz **não acumula**: o próximo é marcado na volta (`next_at = hood_s da volta + 300`), e com o capuz no prego o relógio não
  junta outro.

**Quantas noites cabem.** No robô que vai em toda noite, cabem **~6–8 por campanha** (eram ~8–10), cerca de 0,8× das noites. Na
mesma corrida de `ronda_sim.py lenda` (Boxe Mão rápida 4/s, 24 jogadores), as noites por campanha da 3ª à 12ª ficam assim:
- com 240 s: 9 8 10 6 1 9 8 9 8 8;
- com 300 s: 7 6 8 5 1 7 6 7 7 6.

**O ritmo da lenda.** Com 0,8× das noites e a mesma lenda por noite, os limiares também passam a **0,8×**: `legend.levels` vai de
1/12/30/52/80 para **1/10/24/42/64**. O nível 3 (as brigas e o nó `cat_watch`) e o nível 5 (o chefe e o nó `cat_thanks`) chegam na
**mesma campanha de antes**. Nível no fim das campanhas 3, 4, 5, 6 e 7 (mediana, `ronda_sim.py lenda`):
| Perfil na Ronda | 240 s, 12/30/52/80 (hoje) | 300 s, limiares de hoje | **300 s, 10/24/42/64 (proposta)** |
|---|---|---|---|
| Atento | 3 · 4 · 5 · 5 · 5 | 3 · 4 · 5 · 5 · 5 | **3 · 4 · 5 · 5 · 5** |
| Médio | 3 · 4 · 5 · 5 · 5 | 2 · 3 · 5 · 5 · 5 (o nível 3 atrasa 1 campanha) | **3 · 4 · 5 · 5 · 5** |
| Distraído | 2 · 3 · 4 · 5 · 5 | 2 · 3 · 4 · 4 · 4 (o nível 5 só na campanha 10) | **2 · 3 · 4 · 5 · 5** |
| Piso (só vai e sai) | 1 · 2 · 2 · 2 · 2 | 1 · 2 · 2 · 2 · 2 | 1 · 2 · 2 · 2 · 3 (1 campanha antes no nível 3) |
- **Região GATO PRETO:** os nós são travados por nível (1, 3 e 5), então abrem na mesma campanha de hoje. O custo em Legado não muda.
- **Brigas:** abrem com o nível 3, na mesma campanha. Os bandidos ficam como estão; a curva medida está no §3.4.
- **Save antigo:** a lenda já gravada nunca cai. Com os limiares novos, quem tinha lenda 25 (nível 2) passa ao nível 3 na carga, e o
  `shown_level` mostra a subida uma vez, no próximo prêmio da Ronda. Nada se perde.
- **Convite do Osmar (7a2):** o convite continua aos 300 s e a cada 240 s. Com o capuz a cada 300 s, os dois deixam de ficar sempre
  2 min afastados (Ronda §3.1): às vezes aparecem juntos. Cada um continua com o seu clique, e nenhum esconde o outro. Basta o UI/UX
  conferir uma captura com os dois na tela (B16).

**O que muda no jogo e nos testes**
| Onde | Muda |
|---|---|
| `data/ronda.json` | `hood.interval_s` 300; `legend.levels` [1, 10, 24, 42, 64] (gravados) |
| Save | **nada no formato**. `career.black_cat_hood {hood_s, next_at, open}` continua igual. Um save salvo com `next_at` calculado pelo 240 vale como está: só o próximo capuz depois desse usa o 300 |
| `foto.gd` / "quem não joga" (critério 1) | **igual**. A foto apaga `career.black_cat_hood` e `permanent.black_cat`. Quem nunca clica no capuz não sente a mudança (o capuz não mexe em nada fora desses campos) |
| "Quem briga = quem só faz SUSTO" (critério 2) | igual (as duas corridas usam o mesmo relógio) |
| Testes com 240 escrito à mão | `tests/test_ronda.gd` (linhas ~343–369) e `tests/test_ronda2a.gd` (~408, 461, 465) passam a ler `interval_s` do `ronda.json` |
| Testes e casos com os limiares | os testes que usam lenda 12/29/30/52/80 (níveis 1–5; ex. `test_ronda.gd` ~360–373 e ~492) passam a ler `legend.levels`. **Regerar** `tests/data/ronda_casos.json` (`ronda_sim.py exportar`: ele grava `levels`, `nivel` e `rondas`, que dependem dos limiares e do intervalo) e `ronda2a_casos.json` (`ronda2a_sim.py exportar`, por causa do chefe novo) |
| Textos | nenhum: "PRECISA DA LENDA {n}" usa o nível, não a lenda |
| UI | nenhuma tela nova; a captura do B16 |

## 3. Atributos e passiva
| id | Nome / apelido (já gravados) | Perfil | Força | Agilidade | Resistência | Soma | Passiva | Desafio |
|---|---|---|---|---|---|---|---|---|
| `apagao` | NÉLSON VOLT / O APAGÃO | RÁPIDO | **420M** | **840M** | **1,24B** | **2,5B** | `adv_slippery` (Ensaboado, do Rony Sabão): o Clinch não prende. Na tela, "quem agarra leva choque e solta" | **ANTES DO APAGÃO**: SUSTO na aproximação **e** vitória por K.O. ou finalização até o fim do **round 2** (`surprise_early`, `max_round` 2; §3.3) |
(Para comparar: James 560M e `gate` 660M de soma. O Apagão tem ~3,8× a soma do `gate`.) A passiva é a da liga com os mesmos números
(`thai_clinch`: `clinch_base` 0,3, `clinch_cap` 0,3, `escape_base` 2,0) e as mesmas linhas de prévia. Só o sinal na tela muda de
cara: faísca em vez de sabão (Diretor de Arte; o id e o texto `opp_passive_*` continuam os da liga).

### 3.1 A meta (decisão do dono, 2026-11-26)
A 1ª versão deste design (105M/210M/310M, 40% na prévia no dia do 1º cinturão) caía na **1ª noite** em que o chefe abria, com 100% na
prévia, porque quem tem os 3 requisitos já venceu o `gate` e cresce muito de um capuz para o outro. O dono pediu um Apagão **mais forte,
mas não demais**:
- o jogador mediano **não** o vence na 1ª noite em que ele abre;
- ele vence **1 a 2 campanhas depois** de abrir, por volta da **campanha 9–10**, depois de algumas noites;
- a prévia continua honesta: nas noites em que ele ainda é forte demais, ela mostra a chance baixa, e o jogador escolhe tentar
  (e ganhar a REVANCHE) ou esperar.
Isso substitui a meta "30–50% no dia do cinturão" do escopo §3.2. Com os números novos, nesse dia a prévia dá ~0%, e o jogador vê o
chefe como uma parede que vai cair mais adiante.

### 3.2 Como cheguei aos números (`ronda2a_sim.py chefe`, já com o capuz a 300 s e os limiares novos do §2.2)
Robô padrão da 2a1 (8a2 com calendário, Legado, hall e centro; perfil médio na Ronda; vai em todo capuz). Ele briga com os bandidos e
com o chefe só quando a prévia dá ≥ 50%; nas outras noites faz o SUSTO. Cada escala tem o seu robô do chefe na **mesma** carreira
(a noite do chefe não mexe em nada da carreira, porque a lenda já está no nível máximo). Foram 12 jogadores × 14 campanhas por linha,
12 linhas (6 combinações × 4 e 3 cliques/s), 144 linhagens por escala.

**Sondas** (8 jogadores × 14 campanhas; a escala é sobre 105M/210M/310M). As colunas 3×–8× vieram da rodada com as travas extras no Jiu-jitsu, e as de 9×–20× da rodada com a passiva da liga; nos pontos que as duas mediram (4× e 6×), deram o mesmo.
| Escala | 3× | 4× | **5×** | 6× | 8× | 9× | 13× | 20× |
|---|---|---|---|---|---|---|---|---|
| Linhagens que vencem até a campanha 14 | 95 de 96 | 92 | 79 | 56 | 39 | 35 | 29 | 18 |
| Vence na 1ª noite aberta | 49% | 35% | 25% | 23–29% | 15% | 14% | 0% | 0% |
O Jiu-jitsu cresce mais rápido no fim da campanha e vence até o chefe 13× na campanha 7–10; o Boxe e o Muay Thai param nos 6×. Por
isso a escala certa está entre 4× e 5×. Testei também travar a Finalização e o Por cima no Ensaboado (só dados): não mudou nada
mensurável, porque a vantagem do Jiu-jitsu é de economia, não de passiva. Voltei à passiva da liga.

**Medida final** (12 jogadores × 14 campanhas por linha, 144 linhagens por escala; as escalas são sobre 525M/1,05B/1,55B; "nunca" =
não venceu até a 14ª campanha):
| Escala | Atributos | 1ª vitória (só quem venceu) | 1ª vitória com todos (mediana; p25–p75) | **(a) Campanhas entre abrir e vencer** (mediana; p25–p75) | Noites abertas até vencer (mediana; p25–p75) | **(b) Vence na 1ª noite aberta** | **(c) Linha mais lenta** | **(d) Nunca** | Desafio por tentativa |
|---|---|---|---|---|---|---|---|---|---|
| 1,0× | 525M / 1,05B / 1,55B | 10 | 11 (8–13) | **1** (0–4) | 9 (1–26) | 29% | 13 (3 linhas com 12–13) | 24 (17%) | 13% |
| 0,95× | 499M / 998M / 1,472B | 9 | 10 (8–13) | **1** (0–3) | 8 (1–18) | 30% | 13 (MT Canela 3/s; mais 2 linhas com 12) | 19 (13%) | 13% |
| 0,92× | 483M / 966M / 1,426B | 9 | 10 (7–12) | 0 (0–2) | 3 (1–17) | 32% | 13 (MT Canela 3/s) | 15 (10,4%) | 12% |
| 0,9× | 472M / 945M / 1,395B | 9 | 9 (7–12) | 0 (0–2) | 2 (1–12) | 32% | 13 (MT Canela 3/s) | 16 (11%) | 13% |
| **0,8×** | **420M / 840M / 1,24B** | **8** | **8 (7–10)** | **0** (0–1) | **2** (1–9) | **34%** | **11** (MT Clinch 3/s) | **6 (4%)** | **13%** |
(1,0×, 0,9× e 0,8× na mesma corrida; 0,95× e 0,92× numa segunda corrida, com as mesmas sementes.)

1ª vitória por linha (mediana de quem venceu), na ordem 1,0× / 0,95× / 0,92× / 0,9× / 0,8×:
| Combinação | 4/s | 3/s |
|---|---|---|
| Boxe Mão rápida | 8 / 8 / 8 / 8 / 8 | 13 / 11 / 11 / 10 / 9 |
| Boxe Contragolpista | 8 / 9 / 9 / 9 / 8 | 12 / 12 / 11 / 11 / 10 |
| JJ Finalização | 7 / 7 / 7 / 7 / 7 | 8 / 8 / 8 / 8 / 8 |
| JJ Por cima | 7 / 7 / 7 / 7 / 7 | 9 / 9 / 9 / 9 / 9 |
| MT Canela | 12 / 10 / 10 / 10 / 10 | 13 / 13 / 13 / 13 / 10 |
| MT Clinch | 12 / 11 / 10 / 10 / 9 | 12 / 12 / 11 / 11 / 11 |

**Os 4 critérios do Produtor** (2026-11-26): (a) a mediana vence 1 campanha depois de abrir, e nunca na mesma noite; (b) ≤ 35% vencem
na 1ª noite aberta; (c) as artes mais lentas vencem até a campanha 11; (d) ≤ 10% nunca vencem até a 14ª.
| Escala | (a) | (b) | (c) | (d) | Cumpre |
|---|---|---|---|---|---|
| 1,0× | ✓ (1) | ✓ 29% | ✗ (13) | ✗ 17% | 2 de 4 |
| 0,95× | ✓ (1) | ✓ 30% | ✗ (13) | ✗ 13% | 2 de 4 |
| 0,92× | ✗ (0) | ✓ 32% | ✗ (13) | ✗ 10,4% | 1 de 4 |
| 0,9× | ✗ (0) | ✓ 32% | ✗ (13) | ✗ 11% | 1 de 4 |
| **0,8×** | **✗ (0)**: na mesma campanha, mas na **2ª** noite aberta (mediana) | **✓ 34%** | **✓ (11)** | **✓ 4%** | **3 de 4** |

**Nenhuma escala cumpre os 4.** O (a) e o (c)/(d) puxam para lados opostos: a mediana só passa para a campanha seguinte quando o chefe é
forte o bastante para virar parede para o Muay Thai Canela a 3/s (campanha 13 em todas as escalas de 0,9× a 1,0×). Essa linha só desce
para 10 com 0,8×.

**Escolha: 0,8× = 420M / 840M / 1,24B (soma 2,5B, ~3,8× a soma do `gate`)**, a mais perto: cumpre (b), (c) e (d). **Falha no (a)**: a
mediana vence na mesma campanha em que ele abre. Mesmo assim, ela **não vence na noite em que ele abre**: vence na 2ª noite aberta
(mediana; p75 na 9ª), e 66% não vencem na 1ª noite. Em números: abre na campanha 8 (7–10) e a 1ª vitória sai na campanha **8** (7–10).

### 3.2.1 Leitura e risco
- **Quem vence na 1ª noite (34%) é quase todo Jiu-jitsu:** as 4 linhas do JJ vencem nas campanhas 7–9 em qualquer escala. A economia
  do Jiu-jitsu (a equipe cresce com o tempo) passa do chefe antes, e a passiva dele não segura isso (§3.2).
- **A margem do (b) é curta:** 34% contra o limite de 35%. Com 12 jogadores, ±2–3 pontos são ruído. Se o QA ou o teto pedirem mais
  folga no (b), a alavanca é subir a escala, e aí o (c) volta a falhar primeiro no MT Canela 3/s.
- **A prévia continua honesta.** Na noite em que ele abre, a mediana é 4% (p25–p75 0–98%: é bimodal, o Jiu-jitsu já passou dele e o
  resto ainda não). Quem tenta no vermelho perde, fica com a REVANCHE e não perde nada (§4.2).
- **A medida antiga (no dia do 1º cinturão) dá 0%** em todas as linhas. Nesse dia a linhagem ainda não pode ir (falta o 3º bandido).

### 3.3 O desafio "ANTES DO APAGÃO" (`surprise_early`): por que juntar surpresa e K.O. cedo
- **O problema do K.O. até o round 2 sozinho (`early_finish`):** quando o robô vence o chefe, a prévia mostra ~100% de vitória (ele só
  briga com ≥ 50%, e de um capuz para o outro o discípulo passa do chefe). Com essa folga, o K.O. sai no round 1. Na 1ª versão
  (`early_finish` puro), o desafio saiu em 99% das 1ªs vitórias. Na versão forte, a prévia ainda dá 57% de K.O. cedo na noite da
  1ª vitória (mediana). O "≤ 20% por tentativa" só valeria no papel.
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
- **Chance por tentativa** (medida final, 0,8×, §3.2): **13%** por tentativa jogando de verdade (547 noites do chefe; depois da
  vitória, o robô volta pelo cartão DESAFIO com a tática de maior chance de desafio, sempre com ≥ 50% de vitória). O raro saiu em 70
  das 138 linhagens que venceram, na **3ª tentativa** (mediana, campanha 10). Outras 68 venceram e ainda não o tinham na 14ª campanha.
  Na 1ª vitória, o raro sai junto em 11%. O teto prático é o SUSTO do perfil: **≤ 20%** até para o atento. Isso cumpre o "raro ≤ 20% por
  tentativa" e mantém a P2 que o dono aprovou.
- **Prévia honesta:** sem SUSTO, a prévia diz "DESAFIO: PERDIDO" antes do LUTAR, e o jogador sabe que aquela noite é só pela vitória.
  Com SUSTO, ela mostra CHANCE DO DESAFIO: N% por tática.
- **Alavancas:** `approach` (`look_s` e `gap` mexem mais) e `max_round`. Se o dono preferir o desafio só com o K.O. cedo, basta trocar
  `type` para `early_finish` no `ronda.json` (e o texto). Mas aí o raro vem quase sempre com a 1ª vitória.

### 3.4 Os bandidos com o capuz a 300 s (sem mudança nos números)
Rodei o `ronda2a_sim.py curva` com o capuz a 300 s e os limiares novos (mesmo robô da 2a1, 12 × 12 por linha), para comparar com o
§4.3 da 2a1, que usava 240 s:
| Medida (todas as linhas, mediana; p25–p75) | 2a1 (240 s) | **2a2 (300 s, 10/24/42/64)** |
|---|---|---|
| Brigas abrem (campanha) | 4 | **4** |
| Vencível 1ª vez: `tire` / `bike` / `gate` | 6 (5–8) / 7 (5–8) / 8 (7–10) | **6 (5–8) / 7 (5–8) / 8 (7–9)** |
| 1ª vitória: `tire` / `bike` / `gate` | 6 (5–8) / 7 (5–8) / 8 (7–10) | **6 (5–8) / 7 (6–8) / 8 (7–10)** |
| Desafio feito na 1ª vitória | 52% / 24% / 64% | 52% / 28% / 70% |
Fica igual dentro do ruído de 12 jogadores. A meta da 2a1 ("o 1º bandido vencível por volta da campanha 6–7") continua cumprida, e os
atributos e as aproximações dos bandidos **não mudam**. Com menos noites, o robô ainda vence cada bandido na 1ª tentativa (ele só
briga com ≥ 50%), porque o discípulo cresce entre dois capuzes de 300 s como crescia entre dois de 240 s.

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
  relógio (**300 s** de sala, §2.2). O chefe ganha a marca REVANCHE (`lost ≥ 1` e `won = 0`). Nada cai, nada some. Carreira, Legado, FAMA, dias e
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
| | **Estilo raro** `live_wire`: calção **FIO DESENCAPADO** [ROT], amarelo com o cós e as dobras pretos e o R azul, marcado com o gato dourado | personalização do **próximo discípulo** (fim da lista de cor do calção) | derivado: `challenge` |
- Escolhi a troca no mesmo lugar porque o escopo fala em "versão rara do troféu": a prateleira mostra **1 capacete por chefe**, que
  melhora. Sobram 3 lugares para os chefes dos próximos capítulos (o jogador vê que há mais).
- Desafio feito na 1ª vitória = os prêmios das duas linhas na mesma tela, numa gravação só.

### 6.2 O estilo raro (só cor): FIO DESENCAPADO (escolha do dono, amostra `docs/arte/mockups/ronda2a2_amostra.png`)
| Estilo (id) | Campo e opção em `disciples.json` | Cores na ordem dos slots `dark, mid, light, band` | Marca |
|---|---|---|---|
| `live_wire` | `shorts_color` → `live_wire` | `d1` #2a2233 (dobras pretas), `y0` #e0a040, `y1` #f5d26b, `d1` #2a2233 (cós preto) | `mark: "cat"` e `rare: true` (gato dourado) |
- É o calção amarelo de fio de alta-tensão, com o cós e as dobras pretos, como na amostra do Diretor de Arte. O `deep` (`ink`) fica só no
  manifest, como nas outras cores. O **R da coxa fica azul**: `school_symbol_source.leg.map.live_wire = blue` no manifest (Diretor de
  Arte/Programador, junto da paleta `disciple_palette`). Não se confunde com o `yellow` de hoje (`br2` nas dobras, sem cós preto) nem
  com o `night` do Seu Pé de Cabra (quase preto).
- **Regras da 2a1, todas iguais:** `enabled: false`, `requires: "black_cat_style:live_wire"`; nunca entra no sorteio do rascunho;
  aparece só liberada, no fim da lista do calção (depois do `night`); `ligar_todas_as_opcoes()` a pula; look sujo com `live_wire` sem o
  estilo = volta ao padrão.
- `rare: true` é campo novo e opcional: só troca o gato da marca pelo gato dourado. Quem não conhece o campo, ignora.
- O calção aparece em todo look (diferente da camisa, que some com o peito nu) e também na luta da noite, porque o traje do vulto usa a
  paleta do discípulo.
- `estilo_liberado("live_wire")` sai da ficha do chefe (`boss.apagao.challenge`), não de um bandido. Esse é o único ponto em que a
  regra "estilo = ficha com `challenge`" passa a olhar também o `boss`.

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

## 7. Teto de 10% (critério 3, D5 da revisão), com o capuz a 300 s
- **A 2a2 soma 0 por construção.** A noite do chefe congela o jogo como a briga e dá lenda de 1 a 4. A lenda 5 já é o nível máximo
  antes de o chefe abrir, então essa lenda não abre nada. Os prêmios são só ficha, troféu, título, cartaz e cor.
- **O capuz a 300 s não muda a régua.** A régua do teto é a forca (6c2, 7a2, Ronda, 2a1): uma campanha com tudo comprado, a região
  GATO PRETO inteira incluída. Ela mede quanto a região ajuda **depois de aberta**, e não quando ela abre. Com menos noites, a região
  abriria mais tarde e ajudaria menos ao longo da linhagem, mas os limiares 0,8× (§2.2) a fazem abrir na mesma campanha de antes. Assim, o
  ganho máximo é o mesmo de hoje.
- **Medido** (`SIM_THANKS=0.25 SIM_TETO_VARS="so_regiao,tudo_max,tudo_max_eq0.25,so_regiao_eq0.25" ronda2a_sim.py teto`, com os dados
  da 2a2, 24 jogadores, 6 combinações × 4 e 3/s × CENTRO cheio e vazio, numa corrida só):
  | `cat_thanks` | Pior trecho `tudo_max` | Pior `so_regiao` | Onde |
  |---|---|---|---|
  | **+20% (hoje, escolha do dono)** | **8,8%** | 8,8% | Boxe Contragolpista 4/s, CENTRO cheio, Muralha |
  | +25% | **9,2%** | 8,5% | JJ Finalização 3/s, CENTRO cheio, Bigorna (e JJ Por cima 3/s, 9,2%) |
  Pior trecho por linha, `tudo_max` com +20% / +25% (CENTRO cheio · vazio):
  | Combinação | 4/s | 3/s |
  |---|---|---|
  | Boxe Mão rápida | 5,6 / 6,6% · 7,3 / 7,3% | 4,5 / 5,4% · 4,7 / 4,6% |
  | Boxe Contragolpista | 8,8 / 7,9% · 5,8 / 6,7% | 6,5 / 6,2% · 7,2 / 6,2% |
  | JJ Finalização | 6,6 / 7,8% · 7,9 / 8,4% | 8,7 / **9,2%** · 8,2 / 8,8% |
  | JJ Por cima | 6,6 / 7,2% · 8,0 / 7,8% | 8,1 / **9,2%** · 7,6 / 8,9% |
  | MT Canela | 4,7 / 4,7% · 6,6 / 6,2% | 6,2 / 6,1% · 5,6 / 6,6% |
  | MT Clinch | 6,1 / 6,1% · 6,2 / 6,6% | 6,9 / 6,9% · 5,3 / 6,2% |
- **O corte de +20% ainda faz sentido?** Os dois passam: +20% dá 8,8% e +25% dá 9,2%, com tudo junto. O capuz a 300 s **não abre margem
  nova** (a forca não vê o ritmo das noites), então a conta é a mesma de quando o dono escolheu o +20%. **Recomendo manter +20%** (está
  nos dados): sobra 1,2 ponto para a 8b, que vai mexer em equipe ou Legado (D5 da revisão). Voltar a +25% é possível, mas deixa só 0,8
  ponto (pergunta P3).
- A secção `aprox` dos 3 bandidos sai idêntica à da 2a1. As secções novas do simulador só acrescentam.

## 8. Contrato de dados e API
### 8.1 `data/ronda.json → nights.alley.boss` (já gravado)
| Campo | Valor | Para quê |
|---|---|---|
| `id` | `apagao` | chave no save e nos ids de arte |
| `requires` | `{legend_level 5, all_bandits true, regional_belts_min 1}` | §2 |
| `approach` | `{id apagao, name alley_occ_apagao, spot beco_poste, gap_min 0,8, gap_max 1,2, warn_s 0,35, look_s 1,9, fake_warn 0,3}` | aproximação (formato das ocorrências; §3.3) |
| `name`, `nickname`, `profile` | `alley_apagao_name`, `alley_apagao_nick`, RÁPIDO | |
| `strength`, `agility`, `endurance` | 420.000.000 / 840.000.000 / 1.240.000.000 | §3 |
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
| `style` | `{id live_wire, field shorts_color, option live_wire}` | estilo raro |
Validação (`RondaData`): `boss` ausente = 2a1 igual a hoje (a ficha "??? LENDA 5" continua). Atributos > 0, `passive` como na liga,
`challenge.type` da lista (senão sem desafio, sem raro e sem estilo, com aviso), `style.field/option` precisa existir no
`disciples.json` com `requires` igual a `black_cat_style:<id>`, `trophy.slot` de 0 a 3, `blackout.after_round` ≥ 1.

### 8.2 `data/disciples.json` (já gravado)
`shorts_color.live_wire`: `enabled: false`, `requires: "black_cat_style:live_wire"`, `mark: "cat"`, `rare: true`, cores e tokens do §6.2.

### 8.3 Estado e API (módulo `scripts/estado/briga_beco.gd`; o Programador decide se o chefe vira um módulo irmão)
| Função | Mudança |
|---|---|
| `chefe_aberto() -> bool` | nova: §2 |
| `esconderijo()` | `boss` passa a ser `{id, known, won, lost, first_win_campaign, challenge, open, missing_text, portrait, name, nickname, rap_sheet, headline, witness, clipping, press_title, profile, passive {id, name, icon}, challenge_text, stamp, revenge}` ("???" e textos vazios enquanto não venceu, como no `dossie()`). `trophies`: lista de 4 lugares `[{slot, id, state "empty"\|"normal"\|"rare", sprite, name}]` |
| `quadro_noite()` | cartão `{night "boss", boss "apagao", locked, missing_text, ...os campos do cartão de bandido}` (§2.1). `challenge_only` vale para o chefe |
| `ronda_ir("alley", "apagao")` | aceita o id do chefe (só com `chefe_aberto()`; senão `{}`). Devolve o dicionário da briga com `boss: true`, `entrance_banner`, `entrance_s`, `arena "arena_apagao"` e `blackout` |
| desafio `surprise_early` | `_cumpriu()`: aproximação = SUSTO **e** `win` **e** `ko` **e** `round ≤ max_round`. Prévia: `done` = false e `by_tactic` vazio sem SUSTO (linha "DESAFIO: PERDIDO"); com SUSTO, `by_tactic` = a contagem do `early_finish` nas mesmas 200 lutas. `RondaData` aceita o tipo novo (lista de `challenge.type`) |
| `briga_previa()` / `briga_lutar(t)` | iguais, com o chefe no lugar do bandido. O retorno da luta ganha `boss: true`, `entrance_banner`, `entrance_s`, `blackout {t, dark_s}` (o `t` só vem se `t_end > t`; senão `{}`). `night_prize` ganha `boss: true`, `trophy_new` (`"" \| "normal" \| "rare"`), `press_title_new` (bool), `poster_new` (bool) e as linhas `trophy_line`, `press_title_line`, `poster_line` |
| `estilo_liberado("live_wire")` | olha `boss.apagao.challenge` |
| `parede_menu()` | requisito `black_cat_boss_won` (§6.3) |
| sinais | os da 2a1 (`dossie_mudou`, `lenda_mudou`, `permanente_mudou`) |

### 8.4 Chaves de texto novas [ROT]
`alley_occ_apagao` e `alley_occ_apagao_anon` (topo da aproximação), `alley_apagao_anon` (prévia, antes de vencer),
`alley_apagao_entrance` (letreiro, ex. "O APAGÃO"), `alley_ch_apagao` (ex. "ANTES DO APAGÃO: SURPRESA E K.O. ATÉ O 2º ROUND"; o
"2º" acompanha o `max_round`), `hideout_kind_boss` (CHEFE), `dossier_missing_bandits` (VENÇA OS 3 DO BECO), `dossier_missing_belt` (PRECISA DO CINTURÃO
DO VALE), `trophy_apagao_name` (ex. CAPACETE DA LANTERNA QUEBRADA), `trophy_apagao_rare_name` (ex. CAPACETE ACESO),
`alley_boss_prize_title` (ex. O BECO ACENDEU), `alley_trophy_new`, `alley_trophy_rare`, `alley_press_title_new` (TÍTULO DA IMPRENSA:
{titulo}), `alley_poster_new` (CARTAZ NA PAREDE DO MENU), `disc_opt_shorts_color_live_wire` (FIO DESENCAPADO). Já existem e não mudam:
`alley_apagao_name|nick|rap|headline|witness|clipping` e `press_title_apagao`. Busca por sangue/blood e batman/morcego/gotham = 0.

## 9. Critérios de aceite (2a2), ligados ao escopo §6
| # | Critério | Escopo |
|---|---|---|
| B1 | `foto.gd` de uma campanha inteira com o capuz nunca usado é **idêntica** à da main de hoje. O `boss` fica dentro de `permanent.black_cat`, e a camada nova do menu não grava nada | 1 |
| B2 | Teste roteirizado: a mesma campanha jogada (a) só com SUSTO e (b) com o chefe (perdendo e vencendo, com e sem desafio) sai com o save igual campo a campo, tirando só `permanent.black_cat` e `career.black_cat_hood`. Inclui a sucessão seguinte com `live_wire` liberado: o rascunho sorteado é o mesmo. Nenhum `school.milestones` novo | 2, 10 |
| B3 | `ronda2a_sim.py teto` com os dados da 2a2: pior trecho = **8,8% ≤ 10%** (o mesmo da 2a1, porque a 2a2 soma 0). Resultado registrado no §7 | 3 |
| B4 | Perder do chefe: carreira segue; Legado, FAMA, dias e AQUECIDO iguais; lenda +1 (+1 com SUSTO); capuz volta em 300 s de sala; REVANCHE no cartão; nada do Dossiê e da prateleira some | 4 |
| B5 | Destrave, com um save por caso: (a) lenda 63 com os 3 bandidos e o cinturão → chefe trancado "PRECISA DA LENDA 5"; (b) lenda 64, 2 bandidos e cinturão → "VENÇA OS 3 DO BECO"; (c) lenda 64, 3 bandidos e `regional_belts` 0 → "PRECISA DO CINTURÃO DO VALE"; (d) tudo junto → cartão do chefe com IR. Em (a)–(c), `ronda_ir("alley","apagao")` devolve `{}` | 5 |
| B6 | A chance da prévia é a do motor (`briga_previa()` = `chance_detalhada` com o array do chefe) e bate com os casos do Apagão em `tests/data/ronda2a_casos.json` (regerar com `ronda2a_sim.py exportar`, que passa a incluir o chefe). No simulador (`ronda2a_sim.py chefe`, 12 × 14 por linha), os critérios do Produtor (§3.2): ≤ 35% vencem na 1ª noite aberta (34%), as artes mais lentas vencem até a campanha 11 e ≤ 10% nunca vencem até a 14ª (4%). O (a) falha, como aprovado: a mediana vence na mesma campanha, mas na 2ª noite aberta. O desafio fica em **≤ 20%** por tentativa: 13% jogando de verdade e SUSTO ≤ 20% em todos os perfis (§3.2–3.3). Sem SUSTO, a prévia mostra "DESAFIO: PERDIDO". A luta usa só o `_rng_ronda` | 6 |
| B7 | O apagão é só visual: a mesma luta (semente fixa) dá os mesmos eventos e o mesmo resultado com `blackout` presente e ausente; ele só aparece quando `t_end > 10,67 s`; uma luta vencida até o round 2 nunca mostra o apagão | 6 |
| B8 | Noite do chefe inteira (aproximação, prévia, entrada, luta animada e prêmio) cronometrada em ≤ ~60 s (D6 da revisão vale aqui também); SAIR na aproximação não gasta o capuz | 7 |
| B9 | Letreiro de entrada, K.O. com letreiro, tremida e queda; busca por sangue/blood = 0; o vulto nunca mostra o rosto nem o nome; o chefe é silhueta e "???" em todo lugar até ser vencido (D7g) | 8 |
| B10 | Busca por batman/morcego/gotham = 0; o dono aprovou a amostra do Apagão v2 e da arena antes do elenco (D7f) | 9 |
| B11 | Vitória: ficha, capacete normal no lugar 1, título na ficha e cartaz no menu (com save; sem save, não). Desafio: o capacete vira o raro **no mesmo lugar** e o calção FIO DESENCAPADO aparece no fim da lista de cor do calção, com o gato dourado e o R azul, só na personalização do próximo discípulo. Tudo persiste entre discípulos. O estilo não muda nenhum número (B2) | 10 |
| B12 | Save v13: fechar na aproximação ou prévia = nada; fechar na luta ou prêmio = prêmio gravado uma vez só; saves sujos do §6.4 carregam com aviso; a cópia do save do dono abre | 11 |
| B13 | `tools/run_tests.ps1` verde, com save de teste, `--position 1950,40` e um Godot por vez | 12 |
| B14 | `ui_audit --estrito` com 0 problemas, cobrindo: o Esconderijo com o chefe trancado, aberto, vencido e raro (prateleira com 1 capacete normal e com o raro); o quadro com o cartão do chefe e o DESAFIO do chefe; a prévia do chefe; a entrada com letreiro; a luta na `arena_apagao`; o apagão (quadro escuro); o prêmio normal e o raro; o menu com o cartaz; a personalização com o FIO DESENCAPADO. Placar de `ignore` ≤ 15, e as telas novas sem `ignore` | 13 |
| B15 | Capuz a 300 s (§2.2): o 1º aos 180 s de sala, o seguinte 300 s depois da volta, nos 3 locais, para o SUSTO, a briga e o chefe; o relógio não anda fora da sala e não acumula. Um save com `next_at` antigo (feito com 240) carrega e usa o valor gravado. `test_ronda.gd` e `test_ronda2a.gd` leem o intervalo do `ronda.json` | pedido do dono |
| B16 | Limiares 1/10/24/42/64: `nivel_de()` bate com o `ronda_casos.json` regerado; lenda 24 = nível 3 (brigas e `cat_watch`), lenda 64 = nível 5 (chefe e `cat_thanks`); save antigo com lenda 25 carrega no nível 3 e mostra a subida uma vez. Uma captura com o capuz e o convite do Osmar juntos na tela, sem nada encoberto (`ui_audit` 0) | 5, 13 |

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
| E2 | Estilo raro = calção FIO DESENCAPADO (`shorts_color.live_wire`) | **escolha do dono** sobre a amostra do Diretor de Arte; lê em 1x e aparece em todo look | — |
| E3 | Cartaz no menu vem com a **vitória** (não com o raro) | escopo §3.3; o menu mostra o que o jogador viveu | cartaz só com o raro |
| E4 | Requisito novo do menu em `permanent.black_cat` em vez de marco da escola | marco novo mudaria a foto de quem briga (critério 2) | marco `black_cat_boss_won` |
| E5 | O chefe não ganha papel novo na sala | os 3 pontos da sala são dos bandidos; o lugar do chefe é o menu e a prateleira | 4º recorte nos 3 locais (arte em 3 lugares) |
| E6 | Desafio = SUSTO **e** K.O. até o round 2 (`surprise_early`) | com o K.O. cedo sozinho, o raro sai em ~99% das 1ªs vitórias. A surpresa não fica fácil com o crescimento: 13% por tentativa (P2, aprovada pelo dono) | só o K.O. até o round 2 (`early_finish`), como na proposta da 2a1 |
| E7 | Atributos 420M/840M/1,24B (4× a 1ª versão) | dos 4 critérios do Produtor, é a escala que cumpre mais: (b) 34%, (c) campanha 11 e (d) 4%. Falha no (a): vence na mesma campanha, mas na 2ª noite aberta | 0,95× sobre 525M (499M/998M/1,472B): cumpre (a) e (b), mas o MT Canela 3/s só vence na campanha 13 e 13% nunca vencem |

## 12. Perguntas ao dono
- **P1 (respondida em 2026-11-26, ajustada pelo Produtor).** O dono pediu um Apagão "mais forte, mas não tanto". Medi 1,0×, 0,95×,
  0,92×, 0,9× e 0,8× contra os 4 critérios do Produtor (§3.2). Nenhuma escala cumpre os 4. Ficou **0,8× = 420M/840M/1,24B**, que cumpre
  (b) 34%, (c) linha mais lenta na campanha 11 e (d) 4% nunca vencem. **Falha no (a):** a mediana vence na mesma campanha em que ele abre,
  mas na **2ª** noite aberta, não na 1ª. Para cumprir o (a), seria preciso 0,95× ou mais, e aí o MT Canela 3/s volta para a campanha 13.
- **P2 (mantida pelo dono).** O desafio "ANTES DO APAGÃO" pede a surpresa e o K.O. até o round 2: 13% por tentativa.
- **P3 (decidida pelo Produtor):** o "Bairro agradece" fica em **+20%** (escolha do dono). Com o capuz a 300 s e os limiares 0,8×, o
  teto com tudo junto é 8,8%.

## Resumo
- **Destrave:** lenda 5, os 3 bandidos vencidos e `permanent.regional_belts ≥ 1`. Antes disso, a ficha e o cartão mostram o que falta,
  um requisito por vez.
- **Capuz a 300 s** (era 240), para o SUSTO, as brigas e o chefe. O 1º capuz continua aos 180 s, não acumula e fica parado fora da sala.
  Cabem ~6–8 noites por campanha (eram ~8–10). **Limiares da lenda 1/10/24/42/64** (eram 1/12/30/52/80): o nível 3 e o nível 5, a região
  e as brigas chegam na mesma campanha de antes. O save não muda de formato, e a foto de quem não joga continua igual.
- **Bandidos:** sem mudança. Abrem na campanha 4 e são vencidos nas campanhas 6 / 7 / 8, como na 2a1.
- **Apagão: 420M / 840M / 1,24B** (soma 2,5B), RÁPIDO, `adv_slippery` da liga. Abre na campanha 8 (7–10). A 1ª vitória sai na
  campanha 8 (7–10), na **2ª noite aberta** (mediana; p75 na 9ª). **34%** vencem na 1ª noite aberta, quase todos do Jiu-jitsu. A arte
  mais lenta vence na campanha 11, e só **4%** não vencem até a 14ª. Dos 4 critérios do Produtor, só o (a) falha (§3.2).
- **Desafio "ANTES DO APAGÃO" = SUSTO e K.O. até o round 2** (`surprise_early`): **13% por tentativa** (≤ 20%). O raro sai, em mediana,
  na 3ª tentativa.
- **Apagão:** 1 s de escuro na virada do round 2 para o 3, só visual.
- **Prêmios:** a vitória dá a ficha, o capacete no lugar 1 da prateleira, o título "O VULTO QUE RELIGOU A LUZ" e o cartaz no menu. O
  desafio dá o capacete aceso e o calção **FIO DESENCAPADO** (`shorts_color.live_wire`: amarelo, cós e dobras pretos, R azul), só no
  próximo discípulo.
- **Save v13:** 1 campo opcional, `permanent.black_cat.boss.apagao {won, lost, first_win_campaign, challenge}`.
- **Teto com tudo junto:** a 2a2 soma 0. Com +20% (mantido), o pior trecho é **8,8%**.
