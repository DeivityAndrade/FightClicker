# Ronda 2a do Gato Preto, subfase 2a1 (brigas de beco): design

Designer de Jogo, 2026-11-25. Base: `ronda2a-escopo.md` (com as **Decisões do dono**: estilos só na personalização do próximo
discípulo; nada de poder na 2a; o supervilão fica para a 2a2), `ronda-design.md` (Ronda 1), `ronda-revisao.md` (D2, D3),
`ronda2-ideias.md`, `fase8a1-design.md` (passivas de adversário), `docs/codigo/mapa.md` e o motor `scripts/luta.gd`.
Simulador: `tools/sim/ronda2a_sim.py` (novo; roda em cima do `ronda_sim.py` e do `fase7a2_sim.py`, **só acrescenta**).
Dados: `data/ronda.json → nights.alley` (bloco novo) e 3 opções novas em `data/disciples.json`.
**[ROT]** = nome ou texto provisório (o Roteirista entra depois deste documento).

## 0. A ideia em uma frase
Quando a lenda chega ao **nível 3** e a linhagem já venceu o Kid, o capuz no prego passa a levar ao **Esconderijo**. Lá o jogador
escolhe a noite: o SUSTO de sempre ou **a briga com o próximo bandido**. A briga é uma **aproximação curta** (a "Estátua no telhado"
com 1 ocorrência, ~8 s) e depois uma **luta no motor de sempre**, com tática e prévia honesta. Vencer põe a **ficha** do bandido no
Dossiê e um **recorte** na parede. O **desafio** de cada bandido dá **1 estilo** para a personalização do próximo discípulo. Nada
disso mexe em número nenhum do jogo.

| Peça | O que é |
|---|---|
| Noite `alley` (`kind` `alley_fight`) | 3 bandidos fixos, em ordem, 1 por noite |
| Esconderijo | tela única: parede do Dossiê, prateleira de troféus (vazia na 2a1, com os lugares marcados), quadro ESTA NOITE |
| Dossiê | 1 ficha por bandido (silhueta + o que falta enquanto não venceu) |
| Recorte | 1 por bandido vencido, ao lado do recorte do Gato Preto, nos 3 locais |
| Estilos | 3 opções novas da tela de personalização (faixa, bandagem, calção), marcadas com o gato |

## 1. Regras fixas e como o design as cumpre
| Regra (escopo §2) | Como fica |
|---|---|
| Opcional, relógio parado | A briga roda dentro de `ronda_ativa` (igual à Ronda 1): `sala_ativa()` falso e o `tick` só passa a lógica da noite. Nem equipe, nem relógio, nem convite, nem capuz andam |
| Não é luta da carreira | Não usa `luta`, `concluir_luta`, `indice_escada`, FAMA, Legado, dias, AQUECIDO nem a meta da 2ª passiva. O resultado vive só em `permanent.black_cat` |
| Atributos crus e a arte do discípulo | `jog = _luta._atributos_cru()` (sem o ×1,03 do AQUECIDO, que **não é gasto**); a passiva da arte (1ª ou 2ª, a da carreira) com o extra dos nós, exatamente como `_academia._atualizar_passiva()` já deixa no motor. Sem arte (só a 1ª carreira, que nunca vê a Ronda): o laço sem arte |
| Sorteio próprio | A semente da luta sai do `_rng_ronda` (`randi()` depois de sortear os ciclos da aproximação). Nunca `rng`, `_rng_evento`, `_rng_fala`, `_rng_sucessao`, `_rng_treino` |
| Sem código novo no motor | Cada bandido é `[F, A, R, passiva]` com uma passiva que **já existe** (mesmo `id`, mesmos números da liga). `lutar()`, `chance_detalhada()`, `estado_passiva()` e `nota_adversario()` servem como estão |
| Prévia honesta | A chance mostrada é a do motor (200 sementes, `risk.samples`), a mesma conta da liga. A chance do desafio sai das **mesmas** 200 lutas |
| Tom sujo, sem sangue | K.O. = "APAGOU!" ou "SAIU TONTO E FUGIU"; derrota = o vulto "foge mancando". Nada de sangue nem gente caída depois |
| Vulto sem rosto e sem nome | A luta usa a folha do vulto (traje como camada) e o nome do lutador do lado esquerdo é "???" [ROT]; nenhum texto diz quem é |

## 2. Quando a briga abre e como se escolhe a noite
### 2.1 Destrave (o marco confirmado)
`nights.alley.requires = {legend_level: 3, milestone: "regional_league_opened"}`. As duas juntas:
- **lenda nível 3** (lenda ≥ 30, a mesma trava do nó `cat_watch`);
- **marco `regional_league_opened`**: já existe (8a1), é gravado na 1ª vitória da linhagem sobre o Kid e reaplicado ao carregar
  saves antigos. É o "ter entrado na liga regional" do escopo. Não precisa de campo novo.

Abaixo disso, nada muda: o capuz leva direto ao SUSTO, como hoje. Medido (§4.3): as brigas abrem na **campanha 3–5** (mediana 4)
de quem joga a Ronda.

### 2.2 O capuz e o Esconderijo
- Com a `alley` fechada: igual à Ronda 1.
- Com a `alley` aberta (`hood.hideout_from = "alley"`): o clique no capuz abre o **Esconderijo**. O prego continua guardando
  `open = "scare"` (só diz que há capuz). A escolha da noite acontece no clique e **não vai para o save**.
- **VOLTAR** no Esconderijo sem escolher = o capuz continua no prego, nada gravado.
- O Esconderijo **não** abre sem capuz: o prego vazio não é clicável (regra da Ronda 1: o capuz não chama atenção). Ver P1.

### 2.3 O quadro ESTA NOITE (no Esconderijo)
| Cartão | Mostra | Botão |
|---|---|---|
| SUSTO | "RONDA NO BAIRRO" [ROT], a lenda e o nível | IR → a Ronda 1, igual a hoje |
| Próximo bandido (só 1: o 1º ainda não vencido) | retrato, apelido, perfil (FORTE/RÁPIDO/RESISTENTE), ícone e nome da passiva dele, o **desafio** em 1 linha, a marca **REVANCHE** se já perdeu dele | IR → a briga |
| Bandido vencido **sem** o desafio | cartão menor "DESAFIO" com o mesmo bandido (§5); vencer de novo sem cumprir só dá lenda | IR → a briga |
| Bandido vencido **com** o desafio | não volta ao quadro (vive no Dossiê) | — |
| Todos os 3 vencidos | o cartão do bandido vira "O BECO ESTÁ QUIETO. POR ENQUANTO." [ROT] (a 2a2 põe o chefe aqui) | — |

A chance de vencer **não** aparece no quadro: ela aparece na prévia, depois da aproximação (§3.3), com o lutador e a tática da hora.

## 3. A noite de briga
### 3.1 Linha do tempo (≤ ~45 s)
| Passo | Tempo | O que acontece |
|---|---|---|
| Contagem | 2 s (`countdown_s`) | instrução de 1 linha (a mesma da Ronda) + o desafio da noite em letra menor |
| Aproximação | até 8 s (`approach_s`, depois da contagem, com o `intro_s` 0,8 dentro) | `RondaLogica` com **1 ocorrência**: a do bandido (`bandits[i].approach`). Mesmas regras e tempos da Ronda 1 |
| Fim da aproximação | — | **SUSTO** (pegou de surpresa), **VISTO** (ele se vira) ou **TEMPO** (acabou o tempo: ele se vira). Os três levam à luta. Ser visto **não** cancela a luta |
| Prévia | o jogador decide (sem relógio) | chance de vencer e do desafio por tática (§3.3); escolhe a tática e LUTAR |
| Luta | ≤ 19 s (`time_limit` 16 + entrada/saída 3) | `tela_luta` com a arena do beco; o resultado já está gravado (§3.4) |
| Prêmio | ~3 s | ficha nova, recorte, estilo (se o desafio saiu), lenda |
Medido (§4.4): contagem + aproximação = **10 s**; com a prévia (~5–10 s de decisão) e a luta, **35–45 s**. Dentro dos ~60 s.

### 3.2 A aproximação (por bandido; dados em `bandits[i].approach`)
Mesmo formato das ocorrências da `scare`. São **mais alertas** que os ladrões da Ronda 1 e o tempo é curto (8 s): quem para demais
perde o SUSTO por TEMPO.
| Bandido | `gap` (s) | `warn_s` | `look_s` | AVISO falso | SUSTO: atento / médio / distraído |
|---|---|---|---|---|---|
| `tire` | 1,2–2,2 | 0,45 | 1,6 | 30% | 73 / 60 / 41% |
| `bike` | 1,2–2,0 | 0,50 | 1,0 | 0% | 95 / 73 / 21% |
| `gate` | 1,4–2,4 | 0,50 | 1,8 | 40% | 90 / 79 / 60% |
(Robôs do `ronda_sim.py`: reação 0,25 / 0,40 / 0,55 s, percebem 95 / 80 / 50% dos avisos. `ronda2a_sim.py aprox`.)

- **SAIR na aproximação:** o capuz **continua no prego**, nada é gravado, nenhuma lenda (diferente da Ronda 1, onde SAIR dá o piso).
  É o "SAIR não custa o capuz" do escopo. Fechar o jogo na aproximação = o mesmo.
- Na aproximação valem o HUD da Ronda, a barra de distância, o PERTO e a dica nova "SOLTE E CLIQUE!" (§7).

### 3.3 A prévia da noite
É a `janela_previa` de sempre, com o bandido no lugar do adversário:
- os 3 botões de tática, **chance de vencer** (do motor, 200 sementes) e a linha da passiva dele (`opp_passive_*`, como na liga);
- **linha nova: CHANCE DO DESAFIO: N%** por tática, contada nas **mesmas 200 lutas** (vitórias que cumprem a condição, §5).
  No `tire` (desafio de surpresa) a linha diz só FEITO ✓ (se houve SUSTO) ou PERDIDO (se não houve), sem porcentagem;
- a passiva da sua arte, como na liga (`passive_line`, `passive_state`).
**Escolher tentar ou não o desafio** (escopo §3.4) é escolher a tática: a que dá mais desafio quase nunca é a que dá mais vitória
(ex.: AGRESSIVO derruba mais cedo e perde mais). Não há botão "tentar": o desafio sempre conta, e a prévia mostra o preço de cada
tática. O prêmio raro custa mais porque pede a tática mais arriscada.

### 3.4 LUTAR: quando grava (critério 11)
No clique em LUTAR, numa gravação só:
1. sorteia a semente (`_rng_ronda`) e roda `lutar(jog, bandido, tática, semente, true)`;
2. aplica tudo o que a noite dá (§3.5 e §6) em `permanent.black_cat`;
3. esvazia o prego (`capuz.open = ""`, `next_at = hood_s + interval_s`);
4. `salvar()`.
Só então a tela da luta mostra o que já está decidido. **Fechar durante a luta ou o prêmio:** ao abrir, a sala já tem a ficha, o
recorte e o estilo; nada sai em dobro, nada se perde e não há como "rolar de novo". Fechar **antes** do LUTAR (aproximação ou prévia)
= nada aconteceu, o capuz continua no prego.

### 3.5 Lenda, contadores e penalidade
- **Lenda da noite de briga** = `floor` 1 + `per_scare` 1 (se SUSTO na aproximação) + `win` 2 (se venceu) → **1 a 4**. Nunca passa
  da melhor ronda de SUSTO (5), então brigar **nunca** acelera a região GATO PRETO (que é a única coisa da Ronda com poder).
- `rounds` +1 (toda noite que chega ao LUTAR); `scares` +1 se houve SUSTO na aproximação (continua valendo `scares ≤ 3 × rounds`).
- **Perder (penalidade pequena):** o vulto foge mancando ("SAIU MANCANDO" [ROT]), sem ficha, sem recorte, sem estilo; lenda = 1 (+1
  se houve SUSTO); o capuz é gasto como em qualquer noite e volta no **próximo relógio** (240 s de sala). O bandido ganha a marca
  **REVANCHE** no quadro (`lost ≥ 1` e `won = 0`). A lenda nunca cai e nada do Dossiê some. Carreira, Legado, FAMA, dias e
  AQUECIDO não mudam (a noite nem os lê para gravar).
- **Vencer:** ficha no Dossiê, recorte e o próximo bandido abre (no próximo capuz). Desafio cumprido: o estilo.

### 3.6 Arena e apresentação
- Arena `arena_alley` (nova, Diretor de Arte): beco à noite, chuva, lixo, poste piscando. `arena_da_luta` não muda: a tela da noite
  pede a arena pelo `kind`.
- Entrada curta (sem letreiro grande: o letreiro de entrada é do chefe, na 2a2), K.O. com letreiro, tremida e queda (os de hoje).
- Sinais da passiva dele (AGUENTOU!, NÃO CAIU, GUARDA FECHADA...) vêm da 8a1 sem mudança.
- Texto de K.O.: "APAGOU!" (`alley_ko_banner`) e, por pontos, "SAIU TONTO E FUGIU" (`alley_points_win`) [ROT].

## 4. Os 3 bandidos
### 4.1 Tabela (os corpos são os 3 ladrões da Ronda 1, agora com folha de luta)
| id | Corpo (Ronda 1) | Nome / apelido [ROT] | Perfil | Força | Agilidade | Resistência | Soma | Passiva (já existe) | Desafio |
|---|---|---|---|---|---|---|---|---|---|
| `tire` | baixinho largo, gorro verde | "Zeca Estepe" / O CHAVE DE RODA | FORTE | 85M | 40M | 215M | 340M | `adv_wide_base` (Base larga, do Tião Estaca): trava a queda do Por cima | **PEGUE DE SURPRESA**: SUSTO na aproximação **e** vença |
| `bike` | magrelo comprido, boné para trás | "Fio" / O BRAÇO DE ALICATE | RÁPIDO | 80M | 200M | 120M | 400M | `adv_blindado` (guarda fechada, do James): dano nele ×0,6 no 1º round | **NÃO DEIXE FUGIR**: vença por K.O./finalização até o fim do **2º round** |
| `gate` | barrigudo careca de bigodão | "Seu Pé de Cabra" / O PORTEIRO | RESISTENTE | 140M | 100M | 420M | 660M | `adv_iron_chin` (Queixo de ferro, do Zé Bigorna): trava o K.O. de embalo da Mão rápida | **SEM UM ARRANHÃO**: vença com **60%** da vida ou mais |
(M = milhão. Para comparar: Kid 50M, Bigorna 120M, Estaca 200M, Sabão 320M, James 560M de soma.)

Por que estas passivas: cada uma **trava um jeito de lutar** (Por cima, todos no 1º round, Mão rápida), como na liga, então cada arte
tem um bandido "dela" mais chato. A `adv_slippery` (Ensaboado) fica livre para o supervilão da 2a2 (§11), e nenhuma passiva se
repete entre os 4 da Ronda 2a. As passivas viajam como na liga (4º item do array). Os números das passivas são **idênticos** aos da
liga (mesmas linhas de prévia e de motivo).

### 4.2 Por que estes atributos
- O jogador luta com o discípulo da campanha. Na campanha os atributos crescem muito de uma noite para a outra, então "vencível"
  depende de **até onde a campanha chega**. Calibrei cada bandido entre os degraus da liga: o `tire` fica entre o Estaca e o Sabão, o
  `bike` acima do Sabão (com a guarda) e o `gate` acima do James em soma, mas sem a guarda dele.
- O teto do 1º bandido segue a meta do escopo: **vencível por volta da campanha 6–7** de quem joga a Ronda; os outros depois.
- O supervilão (2a2) fica um degrau acima do `gate` e é medido no instante em que o discípulo ganha o cinturão regional (§11).

### 4.3 Curva medida (`ronda2a_sim.py curva`)
Robô padrão da Ronda (8a2: calendário, Legado, hall, centro; olha a cada 5 s), perfil médio na Ronda, vai em todo capuz, 12
jogadores × 11 campanhas por linha, 6 combinações × 4 e 3 cliques/s. "Vencível" = alguma noite da campanha com ≥ 50% na melhor
tática. O robô briga quando a prévia dá ≥ 50%; senão faz o SUSTO.

| Combinação | cps | Brigas abrem (campanha) | Vencível 1ª vez: tire / bike / gate | 1ª vitória: tire / bike / gate | Chance na briga vencida | Desafio feito na 1ª vitória (de 12) |
|---|---|---|---|---|---|---|
| Boxe Mão rápida | 4 | 3 | 5 / 6 / 8 | 5 / 6 / 8 | 80% / 100% / 100% | 5 / 4 / 7 |
| Boxe Mão rápida | 3 | 5 | 7 / 8 / 8 | 8 / 8 / 8 | 94% / 94% / 94% | 7 / 4 / 3 |
| Boxe Contragolpista | 4 | 4 | 5 / 6 / 9 | 6 / 6 / 9 | 86% / 90% / 98% | 6 / 6 / 11 |
| Boxe Contragolpista | 3 | 3 | 6 / 7 / 8 | 6 / 7 / 9 | 77% / 89% / 100% | 6 / 0 / 7 de 10 |
| JJ Finalização | 4 | 4 | 6 / 6 / 7 | 6 / 6 / 7 | 68% / 76% / 100% | 7 / 3 / 9 |
| JJ Finalização | 3 | 5 | 7 / 7 / 8 | 7 / 7 / 8 | 78% / 92% / 100% | 3 / 2 / 10 de 11 |
| JJ Por cima | 4 | 5 | 6 / 6 / 7 | 6 / 7 / 7 | 95% / 96% / 100% | 7 / 3 / 10 |
| JJ Por cima | 3 | 5 | 8 / 8 / 9 | 8 / 8 / 9 | 90% / 92% / 100% | 6 / 3 de 11 / 9 de 11 |
| MT Canela | 4 | 4 | 7 / 7 / 9 | 7 / 7 / 9 | 88% / 90% / 100% | 6 / 2 / 6 de 11 |
| MT Canela | 3 | 3 | 7 / 7 / 8 | 7 / 7 / 8 | 86% / 85% / 90% | 6 / 3 / 3 de 9 |
| MT Clinch | 4 | 4 | 7 / 7 / 8 | 7 / 8 / 8 | 91% / 96% / 98% | 9 / 5 / 4 de 10 |
| MT Clinch | 3 | 4 | 9 / 9 / 9 | 9 / 9 / 9 | 90% / 98% / 100% | 7 / 0 / 6 de 11 |
| **Todas (mediana; p25–p75)** | | **4** | **6 (5–8) / 7 (5–8) / 8 (7–10)** | **6 (5–8) / 7 (5–8) / 8 (7–10)** | | **52% / 24% / 64%** |

Leitura:
- **Meta cumprida:** o 1º bandido fica vencível na **campanha 6** (mediana; metade entre 5 e 8), o 2º na **7** e o 3º na **8**. As
  brigas abrem na campanha **4**: quem joga a Ronda vê o `tire` e perde dele (ou desiste pela prévia) por ~2 campanhas. É o "difícil
  de propósito".
- O robô vence na **1ª tentativa** em todas as linhas (mediana): ele só briga com ≥ 50%, e de um capuz para o outro (240 s de sala) o
  discípulo cresce muito. Um jogador que tenta no amarelo perde algumas vezes (REVANCHE), e é esse o uso da marca.
- Nenhuma arte fica de fora: o pior caso (MT Clinch 3/s) chega aos 3 na campanha 9.
- **Desafios:** o 1º (surpresa) sai em ~metade das 1ªs vitórias; o 2º (K.O. até o 2º round contra a guarda) é o mais difícil
  (24%, mostrado 8–28% na prévia); o 3º (60% da vida) é fácil para o Jiu-jitsu (finaliza sem apanhar) e médio para o resto (64% no
  geral). Quem não pega na 1ª tem o cartão DESAFIO (§5). Ver a pergunta P2 sobre o 3º.

### 4.4 Duração da noite
Aproximação (`aprox`, 2.000 noites por perfil): SUSTO / VISTO / TEMPO.
| Bandido | Atento | Médio | Distraído |
|---|---|---|---|
| `tire` | 73 / 3 / 23% | 60 / 18 / 21% | 41 / 48 / 11% |
| `bike` | 95 / 5 / 0% | 73 / 27 / 0% | 21 / 66 / 13% |
| `gate` | 90 / 3 / 7% | 79 / 14 / 7% | 60 / 36 / 4% |
- Contagem + aproximação: **10 s** no máximo (8,8 s de mediana para o distraído, que é visto antes).
- Luta: 3 s de entrada/saída + até 16 s (K.O. a partir de 5 s). Prêmio ~3 s. Com ~5–10 s de prévia, a noite fica em **35–45 s**.
- O `tire` é o desafio de surpresa, por isso tem o AVISO mais curto e o tempo apertado: até o atento perde o SUSTO em ~1 de 4.

## 5. Os desafios (condição exata, mensurável no resultado)
| Bandido | Tipo (`challenge.type`) | Condição | De onde vem |
|---|---|---|---|
| `tire` | `surprise` | a aproximação terminou em **SUSTO** e `res.win` | `RondaLogica.sustos == 1` + resultado |
| `bike` | `early_finish`, `max_round` 2 | `res.win` e `res.ko` e `res.round ≤ 2` | `round = floor(t_ko / round_length) + 1` (já vem no resultado) |
| `gate` | `clean_win`, `min_life` 0,6 | `res.win` e `res.pct_player ≥ 0,6` | já vem no resultado |
- A prévia conta a chance do desafio nas mesmas 200 lutas da chance de vencer (`surprise`: sem porcentagem, só FEITO/PERDIDO).
- Desafio feito uma vez fica feito (`challenge: true` na ficha). Vencer de novo não existe na 2a1 (o bandido sai do quadro). **Quem
  vence sem o desafio perde o estilo de vez?** Não: o cartão do bandido vencido sem desafio volta ao quadro como **"DESAFIO"** (só
  a briga do desafio, com o mesmo bandido). Vencer de novo sem cumprir não dá nada além da lenda. Assim o estilo raro continua
  alcançável e custa mais noites.
- Medido na 1ª vitória (§4.3): surpresa **52%**, K.O. até o 2º round **24%**, 60% da vida **64%** (Jiu-jitsu ~85%, Boxe Mão
  rápida 3/s 25%). Alavancas: `approach` do `tire`, `max_round`, `min_life`.

## 6. Prêmios (só visual e lore)
### 6.1 Dossiê (parede do Esconderijo): os campos de cada ficha
| Campo | Dado | Antes de vencer |
|---|---|---|
| Retrato | `dossier.portrait` (folha do bandido, quadro parado) | silhueta escura |
| Nome e apelido | `name`, `nickname` [ROT] | "???" |
| Ficha corrida (1 linha, o que fazia no bairro) | `dossier.rap_sheet` [ROT] | — |
| Perfil e passiva | `profile` + ícone/nome da passiva (os da liga) | perfil só |
| Manchete do dia seguinte | `dossier.headline` [ROT] | — |
| Testemunha (1 frase) | `dossier.witness` [ROT]. Regra: nunca diz quem é o vulto | — |
| Carimbo | "VENCIDO NA {n}ª CAMPANHA" (`first_win_campaign`; **sem nome do discípulo**) | o que falta: "PRECISA DA LENDA 3" / "VENÇA O {anterior} PRIMEIRO" |
| Desafio | o texto do desafio e um selo do gato quando feito; o estilo ganho em miniatura | o texto do desafio em cinza |
| Revanche | carimbo "REVANCHE" enquanto `lost ≥ 1` e `won = 0` | — |
Uma 4ª ficha fica como silhueta "???" com "PRECISA DA LENDA 5" (o lugar do chefe da 2a2), para o jogador saber que há mais.

### 6.2 Recortes
- Cada bandido vencido prega **1 recorte** ao lado do recorte do Gato Preto, nos 3 locais (pontos novos `alley_clipping_spot`,
  `gym_alley_clipping_spot`, `center_alley_clipping_spot`, Diretor de Arte, conferidos com equipe máxima). São 0 a 3 papéis
  empilhados; o hover mostra a manchete do mais recente (`clipping`) [ROT].
- O recorte de nível da lenda (Ronda 1) não muda.

### 6.3 Estilos (opções da tela de personalização que já existe)
| Estilo (id) | Bandido | Peça | Campo e opção em `disciples.json` | Cores |
|---|---|---|---|---|
| `night_band` | `tire` | **Faixa da noite**: preta com a borda âmbar | `headband_color` → `night` | `ink`, `y0` |
| `night_wraps` | `bike` | **Bandagem**: canelas enfaixadas em creme | `socks` → `night_wraps` (cores fixas) | `g2`, `cream`, `g1` |
| `night_shorts` | `gate` | **Calção escuro**: quase preto com o cós âmbar | `shorts_color` → `night` | `ink`, `d1`, `d2`, `y0` |
- Por que estas peças: são as 3 que a tela e o `DiscVisual` já desenham (cor da faixa, meião, calção). **Nenhuma arte nova.** A única
  mudança de código é a bandagem: `socks` hoje só copia cores de outro campo (`source`); a opção `night_wraps` traz `colors` próprios
  (o `DiscVisual` usa `colors` quando a opção não tem `source`).
- **Só na personalização do próximo discípulo** (decisão do dono). Nada muda no discípulo atual; não há troca no Esconderijo.
- Regras das 3 opções (já gravadas assim no `disciples.json`):
  - `"enabled": false` + `"requires": "black_cat_style:<id>"` + `"mark": "cat"`;
  - **nunca entram no sorteio do rascunho** (`sortear`, `sortear_nome` e o "evitar repetir"), mesmo liberadas. Assim o
    `_rng_sucessao` sorteia igual com ou sem estilos (critério 2);
  - na tela aparecem **no fim da lista** do campo, com o gato, **só quando liberadas** (travadas não aparecem; o Dossiê mostra a
    miniatura do que falta);
  - `ligar_todas_as_opcoes()` (teste da 6b2) não liga opções com `requires`;
  - look salvo com uma opção `night` sem o estilo liberado (save sujo) = volta ao padrão do campo, com aviso.
- O visual do vulto (traje sobre o discípulo) usa a paleta do discípulo, então o calção escuro e a bandagem aparecem na luta da noite.
  A faixa fica escondida pelo capuz (como a faixa de sempre).

### 6.4 Onde fica no save (v13, só campo opcional, sem migração)
`permanent.black_cat` ganha **um** campo opcional:
`alley: {"<bandido>": {"won": int ≥ 0, "lost": int ≥ 0, "first_win_campaign": int ≥ 0, "challenge": bool}}`
- Ausente = nenhuma briga. Grava só bandidos com `won + lost > 0`.
- **Estilos liberados = derivados**: `black_cat_style:<style.id>` vale se a ficha do bandido daquele estilo tem `challenge: true`.
  Não há lista separada (nada para ficar inconsistente).
- Validação: números ruins/negativos = 0; gigantes = teto 1e9; `challenge: true` com `won = 0` = false (aviso); bandido fora da
  ordem (o 2º vencido sem o 1º) = mantém (já foi ganho; só em save sujo, com aviso); id desconhecido = ignorado com aviso;
  `first_win_campaign` > campanha atual = campanha atual.
- `rounds`/`scares`/`legend` já existem e só somam. `foto.gd` já apaga `permanent.black_cat` inteiro (Ronda 1): nada a mudar lá.
- A cópia do save do dono abre igual (o campo não existe nele).

## 7. D2 da Ronda: "SOLTE E CLIQUE!"
- **Quando:** `estado().perto` verdadeiro **e** o botão segurado sem parar há **0,6 s** (`nights.scare.hold_hint_s`) desde que
  ficou perto (inclusive parado no fim do muro, distância 1). Some ao soltar, no SUSTO, no VISTO ou no fim.
- Vale na Ronda 1 e na aproximação da briga (a `alley` usa os tempos da `scare`).
- **Só texto** (`hint_release_click`, [ROT]: "SOLTE E CLIQUE!"), piscando no lugar do sinal PERTO. Não mexe na lógica, no sorteio nem
  no resultado. A UI mede o tempo (ou `RondaLogica.estado()` ganha `segurando_perto_s`, sem efeito na regra).
- Por que 0,6 s: o robô médio solta e aperta em ~0,4 s; quem passou de 0,6 s segurando perto quase sempre é quem não entendeu.

## 8. Teto de 10%, medido com tudo junto (D3 da Ronda; critério 3)
### 8.1 Como medi (`ronda2a_sim.py teto` e `campanha`, uma corrida só)
A carreira do simulador (`Carreira2a`) é a da Ronda (8a2 + região GATO PRETO) **com** o convite da 7a2 (Choque, Panfletagem,
AQUECIDO, a equipe produzindo com o relógio parado) **e** a noite da 2a (cada capuz: SUSTO ou briga). Tudo no mesmo laço, nada de
soma à mão. Prova de base: com a 7a2 em "nenhum" e a 2a desligada, a carreira é a do `ronda_sim.py` (secção `ident`).
- **Forca (o pior caso):** uma campanha sem calendário, robô que só luta no verde (olha a cada 5 s), derrota sem custo, árvore de
  antes cheia, hall cheio, CENTRO cheio ou vazio. Variantes: `base` (nada), `so_7a2` (7a2 nota máxima), `so_regiao` (os 3 nós do
  gato), `tudo_max` (7a2 nota máxima + região), `tudo_piso` (vai em tudo sem fazer nada + região). Tempo de **sala** (dias) até
  cada vitória, de Muralha a James. A 2a congela o jogo e não dá prêmio de economia: soma **0** aqui por construção (e o robô da
  corrida da campanha briga de verdade).
- **Campanha de verdade:** "nada" (sem 7a2, sem Ronda) × "tudo" (7a2 nota máxima + Ronda perfil atento + brigas da 2a), mesmas
  sementes, tempo de sala até o Kid e o James nas campanhas 6–10.
- `ident` (6 jogadores × 8 campanhas, 2 combinações): **12 de 12 iguais**, 635 lutas. A corrida junta parte exatamente da Ronda.

### 8.2 Resultado da forca com o ×1,4 de hoje (12 jogadores por linha, 6 combinações × 4 e 3/s × CENTRO cheio e vazio)
Pior trecho de cada linha (o maior ganho entre Muralha, Kid, Bigorna, Estaca, Sabão e James):
| Combinação | cps | `so_7a2` (C1 / C0) | `so_regiao` (C1 / C0) | **`tudo_max`** (C1 / C0) |
|---|---|---|---|---|
| Boxe Mão rápida | 4 | 3,2 / 4,4% | 10,2 / 7,3% | **10,2 / 9,9%** |
| Boxe Mão rápida | 3 | 3,9 / 3,0% | 3,1 / 6,7% | 6,6 / 6,7% |
| Boxe Contragolpista | 4 | 3,7 / 5,2% | 9,6 / 6,5% | 9,6 / 9,2% |
| Boxe Contragolpista | 3 | 5,1 / 3,3% | 6,1 / 5,9% | 8,0 / 6,1% |
| JJ Finalização | 4 | 4,4 / 4,7% | 7,7 / 6,6% | 9,6 / 9,9% |
| JJ Finalização | 3 | 5,0 / 4,2% | 7,5 / 9,0% | 9,1 / **10,8%** |
| JJ Por cima | 4 | 3,8 / 3,7% | 4,9 / 6,8% | 8,4 / **10,9%** |
| JJ Por cima | 3 | 5,1 / 4,5% | 6,6 / 11,5% | **11,1 / 11,5%** |
| MT Canela | 4 | 4,4 / 2,5% | 3,5 / 8,3% | 6,5 / 8,3% |
| MT Canela | 3 | 3,8 / 3,2% | 6,8 / 6,9% | 6,8 / 6,9% |
| MT Clinch | 4 | 4,6 / 4,0% | 5,2 / 5,4% | 7,6 / 7,1% |
| MT Clinch | 3 | 6,1 / 3,0% | 5,7 / 3,7% | 7,7 / 6,5% |
(`tudo_piso` fica entre `so_regiao` e `tudo_max`. Com 12 jogadores, ±1–2 pontos são ruído.)

**Passou de 10%** nas linhas do Jiu-jitsu 3/s e no Boxe Mão rápida 4/s. Remedi essas linhas com **24 jogadores** e o corte do
×1,4 (D3 da Ronda: o primeiro a encolher):
| Combinação | cps | CENTRO | `tudo_max` ×1,40 | ×1,25 | ×1,20 | `so_regiao` ×1,40 → ×1,25 |
|---|---|---|---|---|---|---|
| JJ Por cima | 4 | 1 / 0 | 9,1 / **10,4%** | 7,2 / 7,8% | 6,6 / 8,0% | 7,5 / 8,6 → 5,2 / 6,8% |
| JJ Por cima | 3 | 1 / 0 | **11,2 / 11,0%** | **9,2** / 8,9% | 8,1 / 7,6% | 9,6 / 9,4 → 8,1 / 8,1% |
| JJ Finalização | 4 | 1 / 0 | 9,0 / 9,7% | 7,8 / 8,4% | 6,6 / 7,9% | 7,8 / 6,6 → 5,3 / 5,9% |
| JJ Finalização | 3 | 1 / 0 | **10,7 / 11,1%** | **9,2** / 8,8% | 8,7 / 8,2% | 8,7 / 9,6 → 8,5 / 7,6% |
| Boxe Mão rápida | 4 | 1 / 0 | **10,3** / 9,4% | 6,6 / 7,3% | 5,6 / 7,3% | 9,0 / 7,3 → 4,6 / 5,5% |
| Boxe Mão rápida | 3 | 1 / 0 | 5,3 / 5,4% | 5,4 / 4,6% | 4,5 / 4,7% | 2,4 / 4,9 → 3,1 / 2,2% |

**Pior caso com o ×1,4: 11,2%** (JJ Por cima 3/s, CENTRO cheio, no James). **Com ×1,25: 9,2%.**

### 8.3 Leitura e o corte proposto
- **A 2a1 soma 0.** Ela congela o jogo, não dá prêmio de economia e dá no máximo a mesma lenda do SUSTO (a região nunca chega antes
  por causa dela). O que passa de 10% é a **soma de duas coisas que já existem**: a 7a2 (3–6% sozinha, sempre) e a região GATO PRETO
  (até ~9,6% sozinha), que a Ronda mediu separadas. Juntas elas passam do teto em 4 das 24 linhas. É exatamente o risco do D3.
- **Corte (aplicado nos dados):** `cat_thanks` de **+40% para +25%** (equipe ×1,25), `data/ronda.json`. Pior trecho com tudo junto:
  **9,2%**. As outras linhas já estavam abaixo de 10% com o ×1,4 e só caem com o corte. Os 2 Tios (`cat_rooftop`) e os +2 dias
  (`cat_watch`) ficam como estão; o 1º pesa na Muralha e o 2º não aparece sem calendário.
- **O que o dono perde:** quem fecha a região chega ao James ~1 ponto mais tarde do que hoje (o "temperinho" fica ~2% em vez de ~3%;
  a própria Ronda já tinha mostrado que o +25% dava "James ~2,5% antes, Muralha no máximo 8,8%"). Precisa da aprovação do dono, porque
  muda um número aprovado na Ronda 1 (P3). O texto do nó (`effect_text` com `{pct}`) se ajusta sozinho; o `ronda_casos.json`
  precisa ser regerado (`ronda_sim.py exportar`) pelo Programador.
- **Campanha de verdade** (7 jogadores × 10 campanhas, 12 linhas): a mediana do tempo de sala até o Kid nas campanhas 6–10 fica entre
  **−19% e +14%**, e até o James entre **−9% e +15%**, com sinais trocados entre linhas vizinhas (ex.: MT Canela 4/s −19% no Kid). Com
  7 jogadores e o calendário, "tudo" e "nada" seguem linhagens diferentes (outros Legados, outras compras, outro 1º James) e a
  diferença é dominada pelo ruído, como na Ronda 1 (§8.1 de lá: ±4% já era ruído com 7). A régua do teto é a forca (mesma regra da
  6c2, da 7a2 e da Ronda). Remedição com **21 jogadores**, já com o corte (+25%), nas 2 linhas mais altas do Kid:
  | Combinação | cps | Kid (campanhas 6–10): nada → tudo | James: nada → tudo | 1º James (campanha) |
  |---|---|---|---|---|
  | Boxe Mão rápida | 3 | 8:44 → 7:53 (**+9,8%**) | 31:42 → 28:56 (+8,7%) | 8 → 7 |
  | Boxe Contragolpista | 3 | 8:55 → 8:09 (+8,5%) | 30:51 → 29:41 (+3,8%) | 8 → 7 |
  Na mediana das campanhas 6–10 fica abaixo de 10%, mas **perto** (é a soma da 7a2 inteira, com a FAMA virando Legado, com a região).
  Uma campanha isolada ainda varia muito (até 25% com 21 jogadores: o calendário põe a luta um dia antes ou depois). **Risco para
  o Diretor:** se a 8b mexer em equipe ou Legado, esta corrida tem de ser refeita (`SIM_NR=21 ronda2a_sim.py campanha`), e o próximo
  corte seria o +20% (forca 8,7%).
- **Clique × renda:** a região mais fraca só aproxima o clique da renda; continua muito longe do limite de 25%.

## 9. Contrato de dados e API
### 9.1 `data/ronda.json` (já gravado nesta entrega)
| Bloco | Campos novos |
|---|---|
| `night_order` | `["scare", "alley"]` |
| `hood` | `hideout_from` "alley" (com a noite disponível, o capuz abre o Esconderijo) |
| `nights.scare` | `hold_hint_s` 0,6 (D2) |
| `skill_tree.nodes.cat_thanks` | `effect.value` 0,4 → **0,25** (corte do §8.3; aguarda o dono, P3) |
| `nights.alley` | `id`, `kind` "alley_fight", `name`, `tip`, `requires` {`legend_level` 3, `milestone` "regional_league_opened"}, `countdown_s` 2, `approach_s` 8, `prize_s` 3, `legend` {`floor` 1, `per_scare` 1, `win` 2}, `bandits[]` |
| `bandits[]` | `id`, `approach` {formato de ocorrência: `id`, `name`, `spot`, `gap_min`, `gap_max`, `warn_s`, `look_s`, `fake_warn`}, `name`, `nickname`, `profile`, `strength`, `agility`, `endurance`, `passive` (mesmo formato do `league_regional.json`), `challenge` {`type` surprise\|early_finish\|clean_win, `max_round` \| `min_life`, `text`}, `dossier` {`portrait`, `rap_sheet`, `headline`, `witness`}, `clipping`, `style` {`id`, `field`, `option`} |
Validação (`RondaData`): `kind` `alley_fight` entra em `KINDS`; `requires` com as 2 chaves (chave desconhecida = noite indisponível,
com aviso); atributos > 0; `passive` validada como na liga (`FightData`), passiva inválida = sem passiva, com aviso; `challenge.type`
fora da lista = sem desafio (e sem estilo), com aviso; `style.field/option` precisa existir no `disciples.json` com `requires`
igual a `black_cat_style:<id>`; `approach` validada como as ocorrências. Hoje (antes do código) a `alley` sai com o aviso de `kind`
desconhecido e o `requires` não vazio já a deixa indisponível: o jogo segue igual.

### 9.2 `data/disciples.json` (já gravado)
3 opções (`headband_color.night`, `socks.night_wraps`, `shorts_color.night`) com `enabled: false`, `requires`, `mark: "cat"`, cores
só de tokens da paleta. Regras no §6.3.

### 9.3 Estado e API (módulo `scripts/estado/ronda.gd`; repasses em GameState)
| Função | Devolve |
|---|---|
| `briga_aberta()` | `nights.alley` disponível (§2.1) |
| `esconderijo()` | `{board: [{night "scare"\|"alley", bandit, name, nickname, profile, passive {id, name, icon}, challenge_text, revenge, challenge_only}], dossier: [{bandit, known, won, lost, first_win_campaign, challenge, style {id, field, option}, portrait, name, nickname, rap_sheet, headline, witness, missing_text}], trophies: [] (2a2), legend: lenda()}` |
| `ronda_ir(noite = "", bandido = "")` | sem argumento = como hoje. Com `alley`: `{night "alley", kind "alley_fight", bandit, countdown_s, approach_s, challenge {type, text}, ...}`; põe `ronda_ativa = "alley"` e cria a `RondaLogica` de 1 ocorrência |
| `briga_previa()` | depois do fim da aproximação: o mesmo dicionário de `previa()` (você × bandido, `risks`, `opp_passive_*`, `passive_*`) + `challenge {type, text, by_tactic {t: pct}, done (só surprise)}`, `approach {result "scare"\|"seen"\|"time"}` |
| `briga_lutar(tatica)` | aplica e salva (§3.4); devolve o dicionário de `lutar()` da liga (eventos, `opp_passive`, `finish`...) + `night_prize {win, legend_gain, challenge_done, style_unlocked, dossier_new, clipping_new, revenge}` |
| `ronda_concluir()` | na `alley` só vale como SAIR da aproximação: **não grava nada** e devolve `{left: true}` |
| `estilo_liberado(id)` | `black_cat_style:<id>` |
| sinais | `ronda_mudou("alley")`, `lenda_mudou` (se subiu), `dossie_mudou()` (novo) |
- `previa()`/`lutar()` da carreira não mudam. A noite chama o motor com o array do bandido (`[F, A, R, passive]`), a mesma montagem
  de `_array_adversario`.
- A `RondaLogica` não muda (1 ocorrência já funciona: a noite acaba quando a última ocorrência acaba).

### 9.4 Chaves de texto (Roteirista, `ui_texts.json`)
`night_alley_name`, `night_alley_tip`, `hideout_title`, `hideout_board_title` (ESTA NOITE), `hideout_scare_card`, `hideout_quiet`,
`hideout_back`, `alley_<id>_name|nick|rap|headline|witness|clipping` (×3), `alley_occ_<id>` (×3), `alley_ch_surprise|early|clean`,
`alley_ch_done`, `alley_ch_lost`, `challenge_chance_line` (CHANCE DO DESAFIO: {n}%), `alley_ko_banner` (APAGOU!),
`alley_points_win`, `alley_lose_line` (SAIU MANCANDO), `alley_prize_title`, `alley_style_unlocked`, `revenge_mark`,
`dossier_missing_legend`, `dossier_missing_prev`, `dossier_won_stamp` (VENCIDO NA {n}ª CAMPANHA), `fighter_name_hidden` (???),
`hint_release_click` (SOLTE E CLIQUE!), `disc_opt_headband_color_night`, `disc_opt_socks_night_wraps`, `disc_opt_shorts_color_night`.
Busca por sangue/blood, batman/morcego/gotham = 0.

## 10. Critérios de aceite (2a1), ligados ao escopo §6
| # | Critério | Escopo |
|---|---|---|
| A1 | `foto.gd` de uma campanha inteira com o capuz nunca usado é **idêntica** à da main 626c70a (os campos novos ficam dentro de `permanent.black_cat`, que a foto já apaga) | 1 |
| A2 | Teste roteirizado: a mesma campanha com a Ronda e as brigas abertas, jogada (a) só com SUSTO e (b) indo em todas as brigas (vencendo e perdendo), sai com o save igual campo a campo (dias, treino, dinheiro, FAMA, Legado, lutas, `rng`), tirando só `permanent.black_cat` e `career.black_cat_hood`. Inclui a sucessão seguinte com os 3 estilos liberados: o rascunho sorteado é o mesmo | 2, 10 |
| A3 | `ronda2a_sim.py teto` (tudo junto, uma corrida) mostra o pior trecho ≤ 10% com os dados da fase: `cat_thanks` 0,25 → **9,2%** (§8). O jogo usa o valor do `ronda.json` (teste: equipe ×1,25 com o nó) | 3 |
| A4 | Perder a briga: carreira segue, Legado/FAMA/dias/AQUECIDO iguais, lenda +1 (+1 com SUSTO), capuz volta em 240 s de sala, REVANCHE no quadro; nada do Dossiê some | 4 |
| A5 | Destrave: save com lenda 29 ou sem o marco `regional_league_opened` → o capuz leva ao SUSTO; save com lenda 30 e o marco → Esconderijo; o 2º bandido só aparece com o 1º vencido; o 3º só com o 2º | 5 |
| A6 | A chance da prévia é a do motor (teste: `briga_previa()` = `chance_detalhada` com o array do bandido) e bate com `tests/data/ronda2a_casos.json`; a luta usa só `_rng_ronda` (os outros 5 sorteios iguais antes e depois de uma noite) | 6 |
| A7 | Contagem + aproximação ≤ 10 s; noite inteira ≤ ~45 s; SAIR na aproximação deixa o capuz no prego e não grava | 7 |
| A8 | K.O. com letreiro, tremida e queda; busca por sangue/blood = 0; o vulto nunca mostra o rosto nem o nome | 8 |
| A9 | busca por batman/morcego/gotham = 0 | 9 |
| A10 | Ficha, recorte e estilo aparecem no lugar certo e persistem entre discípulos; os estilos só aparecem liberados, no fim da lista, com o gato, e só na personalização do próximo discípulo | 10 |
| A11 | Save v13: fechar na aproximação/prévia = nada; fechar na luta/prêmio = prêmio já gravado, uma vez só; saves sujos do §6.4 carregam com aviso; a cópia do save do dono abre | 11 |
| A12 | `tools/run_tests.ps1` verde, save de teste, `--position 1950,40`, um Godot por vez | 12 |
| A13 | `ui_audit --estrito` com 0 problemas no Esconderijo (vazio e cheio), quadro, aproximação (com a dica D2), prévia da noite, luta, prêmio normal e com estilo, personalização com os estilos; placar de `ignore` ≤ 15 | 13 |
| A14 | D2: quem segura perto por 0,6 s vê "SOLTE E CLIQUE!"; soltar apaga; nada muda no resultado (casos do `ronda_casos.json` iguais) | 3.6 |

## 11. Ideias para a 2a2: o Apagão (decisão do dono: vilão B, v2)
Só ideia, para a 2a2 partir dela. Mockup: `docs/arte/mockups/ronda2a_apagao_v2.png`.
- **Quem é:** o eletricista que corta a luz do bairro. Bateria de carro nas costas, coroa de cabos, braços compridos, luvas de
  borracha gigantes. Golpes: choque à distância e o "apagão" (puxa uma alavanca e o beco escurece).
- **Passiva:** `adv_slippery` (Ensaboado, do Rony Sabão): "quem agarra leva choque e solta". Trava o Clinch (como na liga); é a
  única passiva de adversário que nenhum bandido usa.
- **Atributos de partida (medidos, ver abaixo):** RÁPIDO de braço comprido, 130M / 260M / 380M (770M), a calibrar na 2a2 para a
  meta do escopo (30–50% com o discípulo que acabou de vencer o James).
  Sonda (`curva` com `SIM_CHEFE="130e6,260e6,380e6"`, 12 × 12 linhas, prévia no instante da vitória sobre o James):
  | Escala | Atributos | Chance (mediana; p25–p75) | Desafio "antes do apagão" (K.O. até o 2º round) |
  |---|---|---|---|
  | 0,8× | 104M / 208M / 304M (616M) | **52%** (39–61%) | 13% |
  | 1,0× | 130M / 260M / 380M (770M) | 15% (1–20%) | 0% |
  | 1,2× | 156M / 312M / 456M | 1% | 0% |
  **Proposta para a 2a2: ~0,85× = 110M / 220M / 325M (655M) → ~40%**, na faixa de 30–50%. Fica do tamanho do `gate` em soma, mas
  quem chega nele já venceu os 3 bandidos e o James; a diferença é a passiva e o desafio.
- **O apagão como mecânica, sem código novo:** não cabe. Escurecer a tela não muda nenhum número do motor, e mudar a chance pelo
  escuro seria código novo (e quebraria a prévia honesta). Fica **só apresentação**: no fim do 2º round ele puxa a alavanca, o beco
  apaga por ~1 s (só a luz da bateria e os olhos do vulto acesos) e a luz volta. Se o dono quiser o apagão com peso, a saída sem
  código é dar a ele a **guarda** (`adv_blindado`) no lugar do Ensaboado e apresentar a guarda como "no escuro você não acerta
  direito" (o 1º round, com a luz apagada, é a guarda fechada). Mas a guarda já é do `bike` e do James. Recomendo manter o
  Ensaboado e o apagão só visual.
- **Desafio do chefe (a versão rara do troféu):** "ANTES DO APAGÃO": vença por K.O./finalização até o fim do 2º round
  (`early_finish`, `max_round` 2), antes de ele puxar a alavanca. Medido na sonda: **~13%** por tentativa na escala 0,8× (menos na
  0,85×), dentro do "raro ≤ 20%" do escopo.
- **Troféu:** o capacete com a lâmpada quebrada; raro: o mesmo com a lâmpada acesa (dourada).

## 12. Quem faz o quê
### Programador
1. `RondaData`: `kind` `alley_fight`, `requires` com `legend_level` e `milestone`, `bandits`, `hold_hint_s`, `hideout_from`.
2. Estado (`scripts/estado/ronda.gd`): Esconderijo, `ronda_ir(noite, bandido)`, aproximação com 1 ocorrência, `briga_previa`,
   `briga_lutar` com a gravação única (§3.4), lenda e contadores (§3.5), `permanent.black_cat.alley` (§6.4) e validação.
3. Estilos: `DisciplesData` (opções com `requires` fora do sorteio, liberadas só pelo estilo; `ligar_todas_as_opcoes` as pula; look
   sujo volta ao padrão), `DiscVisual` (meião com `colors` próprios).
4. Testes do §10 (A1, A2, A4–A7, A10, A11, A14) e `tests/data/ronda2a_casos.json` (lutas com semente fixa contra os 3 bandidos, nas
   6 combinações, para conferir motor = simulador). `docs/codigo/mapa.md` atualizado.
### UI/UX
Esconderijo (parede do Dossiê, prateleira vazia com 4 lugares, quadro ESTA NOITE), tela da noite (contagem com o desafio, aproximação
com a dica D2), prévia com a linha do desafio, luta na arena do beco com o nome "???", prêmio (ficha, recorte, estilo), recortes na
sala, marca do gato na personalização. `alinhamento-ui` até 0 problemas (A13) e as telas novas sem `ignore`.
### Roteirista
As chaves do §9.4: nomes e apelidos (de bairro, exagerados sem ser super-heróis), fichas corridas, manchetes que sobem um tom a cada
bandido, testemunhas (nunca dizem quem é o vulto), desafios em 1 linha, letreiros sem violência.
### Diretor de Arte / Artista de Personagens
Arena `arena_alley`, Esconderijo (parede, prateleira, quadro), 3 recortes pequenos + pontos `*alley_clipping_spot`, retratos do Dossiê
e silhueta, os 3 ladrões com folha de luta (guarda, golpe, levar golpe, queda "apagou", fuga tonta), o vulto lutando (amostra antes,
escopo §5). Ícone do gato para as opções de estilo.
### QA
§10, com `ronda2a_sim.py tudo` como referência de números.

## 13. Decisões do Designer (revisar com o dono)
| # | Decisão | Por quê | Alternativa |
|---|---|---|---|
| D1 | Destrave = lenda 3 + marco `regional_league_opened` | o marco já existe e já é a "entrada na liga" | lenda 3 só |
| D2 | Bandidos com passivas da liga (Base larga, Guarda, Queixo) e a Ensaboado guardada para o Apagão | nenhuma passiva repete entre os 4, cada arte tem um bandido chato | repetir passivas |
| D3 | Ser visto não custa nada além do desafio do 1º e da lenda +1 | escopo: ser visto não cancela; nada de poder na aproximação (a prévia continua honesta) | SUSTO dar vantagem na luta (seria número novo) |
| D4 | Gravar tudo no LUTAR | fechar no meio nunca duplica nem permite rolar de novo | gravar no fim da animação |
| D5 | Briga dá lenda 1–4 (nunca mais que o SUSTO) | brigar não acelera a região GATO PRETO (o único poder da Ronda) | lenda maior para quem briga |
| D6 | Estilos travados não aparecem na personalização | a tela não muda de tamanho nem ganha estado "travado"; o Dossiê mostra o que falta | aparecer com cadeado |
| D7 | Vencido sem desafio volta ao quadro como "DESAFIO" | o estilo continua alcançável, e custa mais noites | o estilo perdido para sempre |

## 14. Perguntas ao dono
- **P1. Ver o próximo bandido só pelo capuz?** O Esconderijo só abre pelo capuz (1 a cada ~4 min de sala). **Recomendo** assim
  (o capuz continua o único caminho para a noite). Alternativa: o capuz vazio no prego abre o Esconderijo só para olhar.
- **P2. Os desafios.** Surpresa (1º), K.O. até o 2º round (2º), vencer com 60% de vida (3º). **Recomendo** estes; o Jiu-jitsu acha o
  3º fácil (finaliza sem apanhar) e o Boxe acha o 2º difícil: cada arte tem o seu desafio "fácil". Se o dono quiser o 3º mais raro,
  a alavanca é `min_life` (0,6 → 0,7), a medir.
- **P3. Corte do "Bairro agradece" (D3 da Ronda).** Com tudo junto o pior trecho era 11,2%. **Recomendo** baixar a equipe de +40%
  para **+25%** (já nos dados; pior trecho 9,2%). Alternativa: +20% (pior 8,7%). Sem corte, o critério 3 do escopo não passa.

## Resumo
- **Brigas de beco:** abrem com a lenda 3 e o marco `regional_league_opened` (campanha ~4). O capuz passa a levar ao Esconderijo,
  onde se escolhe SUSTO ou o próximo bandido. Noite = aproximação de 1 ocorrência (≤ 8 s) + luta no motor com prévia honesta e a
  chance do desafio, tudo gravado no LUTAR. ~35–45 s. Perder só gasta o capuz (lenda +1, REVANCHE).
- **Bandidos:** Zeca Estepe 85M/40M/215M (Base larga), Fio 80M/200M/120M (Guarda), Seu Pé de Cabra 140M/100M/420M (Queixo de
  ferro) [ROT]. Vencíveis nas campanhas **6 / 7 / 8** (mediana); o robô vence cada um na 1ª tentativa em que a prévia dá ≥ 50%.
- **Desafios → estilos:** surpresa → faixa da noite; K.O. até o 2º round → bandagem; 60% da vida → calção escuro. Feitos em
  52 / 24 / 64% das 1ªs vitórias; quem perde volta pelo cartão DESAFIO. Estilos só no próximo discípulo, fora do sorteio.
- **Lore:** Dossiê (retrato, apelido, ficha corrida, manchete, testemunha, carimbo da campanha), 1 recorte por bandido nos 3 locais.
  Save v13 com um campo só: `permanent.black_cat.alley`.
- **D2:** "SOLTE E CLIQUE!" com 0,6 s segurando perto.
- **Teto com tudo junto (7a2 + região + 2a, uma corrida):** a 2a soma 0, mas a 7a2 e a região juntas chegavam a **11,2%**. Corte
  aplicado: o "Bairro agradece" de +40% para **+25%** → pior trecho **9,2%** (aguarda o dono, P3).
- **2a2 (ideia):** Apagão com o Ensaboado, ~110M/220M/325M para ~40% no dia do cinturão regional, desafio "antes do apagão"
  (~13%), apagão só como apresentação.
