# Fase 8a2 — Centro de treinamento (local 3): design

Designer de Jogo, 2026-11-22. Base: `fase8a-escopo.md` (§4, §6, critérios 11–18, custo de arte da 8a2 e **"Decisões do dono
(2026-11-21)"**: o centro fica na 8a2 **sem luta nova** até a 8b; patrocínio **pequeno**), `fase8a1-design.md` (§10.2: uma campanha com o
Cinturão do Vale rende ~13.400 de Legado e a árvore fica cheia; a região CENTRO deve custar ~15–25 mil), `fase8a1-revisao.md`.
Padrão seguido: a mudança garagem → academia (`locations.json`, `academia_artes.mudar()`), a sala larga da 6d2 e a liga da 8a1
(conteúdo novo num arquivo à parte).
Simulador: `tools/sim/fase8a2_sim.py` (roda em cima do `fase8a1_sim.py`; **só acrescenta**). Dados gravados: `data/center.json` (novo) e
o local `center` em `data/locations.json`. Contas exatas: `tests/data/fase8a2_casos.json`.
**[ROT]** = nome ou texto provisório (o Roteirista entra depois deste documento).

## 0. A ideia em uma frase
Quem ganha o **Cinturão do Vale** (vence o James) pode **MUDAR** para o centro de treinamento: sala nova e larga, treino ×4, uma 5ª
melhoria em cada aparelho e os **Alunos da Raízes** treinando ao fundo. Não há luta nova lá (a campanha fica completa, como hoje
depois do James): o centro é o **prêmio visível** do cinturão, e passar o posto continua sendo a jogada natural. Para a linhagem que
já tem um Cinturão do Vale, um **patrocinador local** oferece contrato uma vez por campanha, e a árvore ganha a região **CENTRO**.

| Peça | Quando aparece | O que faz |
|---|---|---|
| MUDAR para o centro | na campanha em que o James foi vencido | $25.000 → local `center`, treino ×4 |
| Alunos da Raízes | só no centro | gerador de Treino novo (2M, ×1,25, 500/s) |
| 5ª melhoria dos aparelhos | só no centro | ×3 em cada aparelho (150M nos básicos, 250M no da arte) |
| Fala de chegada | 1ª mudança da linhagem (depois, frases curtas que se revezam) | só a fala do Osmar, sem cena |
| Recorte e cartaz mudado | a partir do 1º Cinturão do Vale da linhagem | só cenário |
| Patrocínio | campanhas seguintes, com a fama da campanha ≥ 200 | +50% do prêmio base em $ por vitória, marca no calção e no cartaz |
| Região CENTRO da árvore | depois da 1ª mudança | 3 nós, 22.000 de Legado no total |

**Nada disso existe antes do 1º Cinturão do Vale da linhagem.** Por isso o jogo até lá é o da 8a1, luta por luta (§8).

## 1. A mudança para o centro
### 1.1 Regra
- O local novo vai em `data/locations.json`: `{"id": "center", "training_mult": 4.0, "apparatus_suffix": "_center", "move": {"id":
  "move_center", "cost": 25000, "currency": "money", "requires": "regional_belt"}}`, com o nome e o texto do botão **[ROT]** (gravado).
- **Destino do MUDAR** = o próximo local da lista depois do atual. Da garagem vai para a academia, como hoje. Da academia vai para o
  centro. Do centro não há destino (o botão some).
- **Requisito por local:** `requires: "belt"` (academia) = `gs.cinturao`, como hoje. `requires: "regional_belt"` (centro) =
  `cinturao_regional()` (a escada passou do James, 8a1 §6). Sem o requisito o estado é `"locked"` e o botão **não aparece**
  (critério 11). Com o requisito e sem o dinheiro: `"missing"` (apagado). Com os dois: `"ready"`.
- **Reserva da LOJA** (`reserva_mudanca`) só vale quando o requisito **do destino** já está cumprido. Na academia, com o cinturão amador
  e sem o do Vale, a reserva é **0** (hoje ela seria 25.000, e isso mudaria o jogo antes do James). Depois do James a LOJA não gasta
  abaixo de $25.000 até o jogador mudar.
- **Preço $25.000:** é menor que o prêmio base do James ($30.000, sem nó nenhum). A vitória sobre o James sempre paga a mudança,
  e não existe o caso "venci o James mas não tenho como mudar" (no centro não há luta, então não há outra fonte de dinheiro). Medido:
  o menor saldo ao vencer o James foi $91.300 (§7.1).
- **Multiplicador ×4,0** (a academia é ×2,0; cada local dobra o anterior). O Ventilador novo (`gym_training_bonus`) já vale fora da
  garagem, então vale no centro também (o código de hoje faz `m × (1 + bônus)` em todo local com `m ≠ 1`). Com o nó novo Piso de
  borracha (§5), o centro vai a ×6,0 e a academia a ×3,0. Conta: `mult_local = training_mult × (1 + Σ gym_training_bonus)`.
- **Mudar nunca tira nada** (regra de sempre): geradores, melhorias, aparelhos, luva, Metrônomo, Treino, atributos, caixas e dinheiro
  (menos o preço) ficam. Todos os aparelhos montados trocam para a versão `_center` do sprite na hora, sem caixa.
- **Depois de mudar:** a escada já está completa (HUD "CAMPANHA COMPLETA", como hoje depois do James). Não há luta, prévia nem data.
  O convite do Osmar e o AQUECIDO acabam com a escada, como hoje.
- **Todo discípulo começa na garagem** (`_zerar_carreira` volta para `garage`, como hoje). O centro é por campanha, como a academia.

### 1.2 Chegada (sem cena)
- `mudar()` para o centro grava o marco `center_arrival` no mesmo `salvar()` da mudança e dispara o gatilho `center_arrival`
  (o Osmar fala). **Não toca cena** (`_cena_da_chegada()` só vale para a academia).
- **Fala:** 1ª chegada da linhagem = 1 fala única do Osmar (`cl_primeiro_centro`, `repeat: once`) [ROT]; chegadas seguintes = 1 de
  2–3 falas curtas que se revezam (`repeat: rest`, grupo `centro_volta`), como a academia faz hoje. Sugestão: "pendura a foto ali.\ntorta
  mesmo, que é pra lembrar." **[ROT]**
- **Detalhe da garagem:** a **foto torta** da garagem aparece pendurada de novo na parede do centro (o mesmo sprite, em ponto próprio).
  Ela está lá desde a 1ª chegada, sem condição.
- `permanent.center_reached = true` na 1ª mudança (abre a região CENTRO da árvore, §5).

## 2. Alunos da Raízes (gerador novo, só no centro)
| id | Nome [ROT] | Custo base | Crescimento | Produção (Treino/s por unidade, antes dos bônus) | Desenho |
|---|---|---|---|---|---|
| `center_students` | Alunos da Raízes | 2.000.000 | ×1,25 | 500 | 1, 5, 12, 25 unidades = 1 a 4 pessoas na sala |
- **Custo:** `custo(n) = teto3(2.000.000 × 1,25^n)` (a mesma `Economia.custo_gerador` dos outros). Tabela exata em `fase8a2_casos.json`.
- **Produção:** entra na equipe como os outros geradores de Treino: `500 × qtd × (1 + passive_bonus) × mult_local × Honra × bônus da
  arte` (a mesma conta do Vizinho e do Tio). Ele **só existe no centro**: fora dele não aparece na aba EQUIPE e não pode ser comprado.
  Como a carreira termina no centro, a quantidade zera com o resto na nova carreira.
- **Por que 2M e 500:** ao chegar, o robô tem ~10–70M de Treino guardado, então o 1º aluno sai na hora (o "presente de chegada"). Cada
  aluno vale ~9 mil Treino/s no centro (Boxe), o que **dobra a equipe** com o 1º. O Vizinho e o Tio já estão em 50–60 unidades, e o
  próximo custa 16M–110M para dar ~9 Treino/s: a equipe tinha parado de crescer. Os alunos devolvem o sentido da aba EQUIPE.
- **Ritmo medido** (§7.1): ~15 alunos aos 5 min, ~23 aos 10, ~26 aos 15. O preço sobe 1,25× por aluno, então ele perde a graça sozinho
  perto de 25, sem teto.

## 3. Aparelhos no centro
### 3.1 Versão nova (visual)
`apparatus_suffix: "_center"`: os 3 básicos (saco, corda, esteira) e os 3 de arte (pera, boneco, saco de chute) têm sprite próprio no
centro. Os de arte podem reaproveitar o da academia com material novo (escopo §9). A caixa de aparelho continua valendo como hoje (a
esteira, a corda e o aparelho da arte, se ainda não foram comprados, chegam na caixa também no centro).

### 3.2 A 5ª melhoria (números)
Cada aparelho ganha **uma** melhoria a mais, que **só aparece e só pode ser comprada no centro**, depois da 4ª:
| Aparelho | id | Nome [ROT] | Custo (Treino) | Efeito |
|---|---|---|---|---|
| Saco | `bag_center` | Saco de competição | 150M | ×3 |
| Esteira | `treadmill_center` | Esteira com painel | 150M | ×3 |
| Corda | `rope_center` | Corda de rolamento | 150M | ×3 |
| Pera (Boxe) | `tech_boxing_center` | Plataforma de pera | 250M | ×3 |
| Boneco (Jiu-jitsu) | `tech_bjj_center` | Boneco de competição | 250M | ×3 |
| Saco de chute (Muay Thai) | `tech_mt_center` | Saco de lona dupla | 250M | ×3 |
- Regra: a 5ª melhoria tem `location: "center"`. Na academia o cartão do aparelho fica como hoje depois da 4ª (sem a 5ª e sem aviso).
  No centro ela aparece como a próxima. **Precisa da 4ª comprada** (é a próxima da lista).
- **Por que ×3 e esse preço:** ×3 é o mesmo salto das melhorias 1, 3 e 4. A 4ª custa 4M/6M, e o robô chega ao centro com tudo comprado.
  150M/250M é ~2–6 min de renda no centro: a 1ª sai entre 1 e 3 min, e a última por volta de 4–6 min. Assim a chegada tem compra
  em sequência, e não tudo no 1º segundo.
- **Save:** `career.upgrade_levels[aparelho]` passa a aceitar 5. Nível 5 fora do centro (save sujo) volta a 4, com aviso.

## 4. Patrocínio (versão pequena)
### 4.1 Regra
| Campo (`center.json → sponsor`) | Valor | O que é |
|---|---|---|
| `requires_regional_belts` | 1 | só existe se a linhagem já tem 1 Cinturão do Vale (`permanent.regional_belts ≥ 1`) |
| `fame_at_least` | 200 | a fama **da campanha** (`gs.fama`, já com os nós) chegou a 200 |
| `prize_share` | 0,5 | bônus por vitória = `floor(prize_money_base × 0,5 + 0,5)` |
| `name` / `brand_sprite` | Auto Peças Vale **[ROT]** / `sponsor_vale` | um patrocinador só na 8a2 |
- **Estados** (`career.sponsor`): `""` → `"offered"` → `"signed"`. Zera em `_zerar_carreira` (1 vez por campanha).
- **Quando oferece:** em `concluir_luta`, depois de somar a fama da vitória (no mesmo `salvar()`), e ao carregar o save: se o estado é
  `""`, a linhagem tem o cinturão do Vale e `fama ≥ 200` → `"offered"`. Na prática: depois do Dinho Pulga com os nós de fama (×2), ou
  depois do Seu Muralha sem eles (10+30+60+100 = 200).
- **A oferta não some:** com `"offered"`, um envelope (PROPOSTA) fica na sala até o fim da campanha. Clicar abre o contrato com
  **ASSINAR** e **AGORA NÃO**. AGORA NÃO só fecha a janela: o envelope continua lá. Ignorar não custa nada e não muda nada (nem
  sorteio, nem economia, nem a ordem de nada).
- **Assinado:** cada vitória **depois** da assinatura paga `bônus = floor(prize_money × 0,5 + 0,5)` a mais em dinheiro (prêmio base do
  adversário, **sem** os nós de dinheiro, para a linha ficar fácil de ler). Não é retroativo. A tela de vitória mostra a linha
  `PATROCÍNIO {MARCA}: +${n}` **[ROT]**. A marca aparece no calção do lutador (nesta campanha) e no cartaz da liga na academia.
- **Quanto vale** (prêmio base × 0,5): Muralha 1.250, Tonhão 1.250, Kid 3.000, Bigorna 4.500, Estaca 6.000, Sabão 8.000, James 15.000.
  Assinando depois do Dinho, a campanha inteira dá **+$39.250**, ~17% a mais de dinheiro (com os nós de dinheiro, os prêmios dão ~$234 mil).
  É pequeno de propósito: no fim da campanha o dinheiro só compra o Prof. Nelson, e no começo ajuda nas luvas e no Metrônomo.
- **Não mexe:** na fama, no Legado, na Honra, na luta e na prévia. É o 1º uso da fama fora do Legado (escopo §4), só como gatilho.

### 4.2 Por que só depois do 1º cinturão do Vale
É o que deixa a foto igual até o cinturão (critério 13: "ignorar dá o mesmo jogo"; aqui, até lá, nem há o que ignorar) e é coerente
com a história: o patrocinador aparece depois que o recorte de jornal sai com o nome da escola.

## 5. Região CENTRO da árvore
Trava nova `"center"`: aberta com `permanent.center_reached` (1ª mudança da linhagem). Nenhum nó antigo muda (critério 15).
| id | Tipo | Pos | Custo | Efeito (tipo que já existe) | Texto [ROT] |
|---|---|---|---|---|---|
| `ctr_door` (raiz) | pequeno | [12, −3] | **5.000** | `click_bonus` +0,5 | +50% TREINO POR CLIQUE |
| `ctr_schedule` | marco | [14, −4] | **7.000** | `prep_days_bonus` +1 | +1 DIA DE PREPARO ANTES DE CADA LUTA |
| `ctr_floor` | marco | [13, −6] | **10.000** | `gym_training_bonus` +0,25 | TREINO NA ACADEMIA E NO CENTRO +25% |
| **Total** | | | **22.000** | | |
- **Só tipos de efeito que já existem:** o motor de bônus não muda. O código novo é só a trava `"center"` em `trava_aberta()` e no mapa.
- `ctr_door` é raiz (aparece sozinha quando a trava abre) e tem `gym_league` como vizinho só para a linha do mapa; os outros 2 são
  vizinhos dela. O mapa precisa caber até x = 14 (hoje vai a 11).
- **O que cada um vale na campanha seguinte** (medido no robô, §7.3): o clique é ~80% do Treino no fim da campanha, e +0,5 sobre os
  ~+3,0 de hoje dá ~+12% de Treino; o dia de preparo dá +1 dia em cada uma das 10 lutas; o Piso leva a academia de ×2,5 a ×3,0
  (+20% em toda a fase da academia, que é a maior parte da campanha). Nenhum é "+1%".
- **Por que 22.000:** a 8a1 mediu ~13.400 de Legado por campanha com o Cinturão do Vale e a árvore cheia. 22.000 fecha em ~2 campanhas
  regionais (§7.3), dentro da faixa pedida (15–25 mil). Depois disso o Legado volta a sobrar até a 8b, e isso fica registrado.

## 6. Arco 4 no cenário
- **Condição:** `permanent.first_regional_belt_campaign > 0` (8a1 já grava). Vale na academia e no centro, em todas as campanhas
  seguintes, e já na volta da tela de fim da campanha do 1º cinturão.
- **Cartaz mudado (academia):** o cartaz da liga (8a1, em cima da porta) troca para a versão "vencido": **adesivo do R** em cima da cara
  do James e o **recorte de jornal** preso com fita no canto do cartaz. Hover: "RAÍZES LEVA O CINTURÃO DO VALE" + o nome do discípulo
  daquela campanha (do `escola.roster`, campanha `first_regional_belt_campaign`) **[ROT]**. Com o patrocínio assinado, a marca aparece
  num canto do cartaz (a mesma peça com uma camada a mais).
- **Recorte (centro):** o mesmo recorte, emoldurado, na parede do centro, ao lado da foto torta.
- O recorte do Gato Preto (7a2) continua onde está. Os dois são objetos de hover, sem fala e sem tirar o controle do jogador.

## 7. Medidas (simulador `tools/sim/fase8a2_sim.py`)
Robô padrão da 8a1 (calendário, Legado, hall, 72→48 jogadores × 10 campanhas por combinação). Depois de vencer o James ele paga a
mudança e fica **15 min** no centro comprando (o que achar melhor, como na academia); depois passa o posto. Com o patrocínio, ele assina
assim que o envelope aparece. Na árvore compra o nó mais barato que cabe (regra de sempre).

### 7.1 Estadia no centro (critério 16: tempo morto, e o clique)
`fase8a2_sim.py centro`, 48 jogadores × 10 campanhas, todas as estadias (2.124 estadias, das quais 560 são a 1ª mudança da linhagem):
| Combinação | cps | $ ao vencer o James (mín.) | 1ª compra sem ser aluno (med; p90) | Maior intervalo sem compra nos 10 min (med; p90; máx) | 5ªs melhorias: última (med; p90) | Alunos aos 5 / 10 / 15 min | Treino/s aos 10 min × chegada | 1 clique ÷ renda sem a mão: chegada → 15 min (mín.) |
|---|---|---|---|---|---|---|---|---|
| Boxe Mão rápida | 4 | 112k | 2:19; 2:58 | 2:20; 2:56; 4:17 | 3:43; 5:48 | 17 / 24 / 27 | ×5,0 | 87% → 108% (90%) |
| Boxe Mão rápida | 3 | 112k | 2:53; 3:43 | 2:57; 3:43; 4:44 | 4:50; 6:43 | 13 / 22 / 25 | ×4,9 | 87% → 107% (90%) |
| Boxe Contragolpista | 4 | 112k | 2:17; 2:57 | 2:18; 2:59; 5:17 | 3:45; 5:41 | 17 / 24 / 27 | ×5,0 | 87% → 108% (75%) |
| Boxe Contragolpista | 3 | 112k | 2:53; 3:42 | 3:00; 3:45; 4:46 | 4:49; 6:43 | 13 / 22 / 25 | ×4,8 | 87% → 107% (89%) |
| JJ Finalização | 4 | 91k | 0:53; 1:15 | 1:29; 1:44; 2:28 | 2:38; 4:21 | 25 / 29 / 31 | ×11,8 | 75% → 123% (74%) |
| JJ Finalização | 3 | 112k | 1:03; 1:28 | 1:24; 1:37; 2:13 | 3:27; 5:10 | 23 / 27 / 30 | ×11,1 | 75% → 122% (74%) |
| JJ Por cima | 4 | 92k | 0:56; 1:15 | 1:29; 1:42; 2:42 | 2:37; 5:14 | 25 / 29 / 31 | ×11,8 | 75% → 123% (74%) |
| JJ Por cima | 3 | 92k | 1:05; 1:27 | 1:24; 1:42; 2:25 | 3:23; 5:13 | 23 / 27 / 30 | ×11,2 | 75% → 123% (76%) |
| MT Canela | 4 | 92k | 2:29; 3:23 | 2:31; 3:20; 5:31 | 4:24; 7:16 | 15 / 23 / 25 | ×5,3 | 69% → 94% (67%) |
| MT Canela | 3 | 112k | 2:48; 3:46 | 3:04; 4:01; 4:49 | 5:26; 8:21 | 13 / 21 / 24 | ×5,0 | 69% → 94% (82%) |
| MT Clinch | 4 | 112k | 2:01; 2:39 | 2:21; 3:06; 5:46 | 3:57; 5:56 | 17 / 24 / 26 | ×5,4 | 69% → 94% (67%) |
| MT Clinch | 3 | 112k | 2:26; 3:09 | 2:54; 3:47; 5:11 | 5:12; 7:23 | 14 / 21 / 24 | ×5,1 | 69% → 94% (84%) |
- **Tempo morto no centro (critério 16):** o pior intervalo sem compra nenhuma nos 10 primeiros minutos é **5:46** (p90 ≤ 4:01). A 1ª
  compra (um aluno) sai no 1º segundo em todas as estadias, porque o Treino guardado já paga. Sem contar os alunos (a régua da 5.2,
  em que a equipe "está sempre à venda"), a 1ª melhoria nova sai em ~1–3 min e a última em ~3–5 min (p90 ≤ 8:21). Depois disso só
  sobram alunos cada vez mais caros, e a jogada natural é passar o posto. Esse "vazio" no fim é de propósito: na 8a2 o centro é a volta
  da vitória, não uma fase nova.
- **Curva (Boxe Mão rápida, 4/s, mediana):** na chegada o Treino/s quase dobra (×4 contra ×2,5 da academia com o Ventilador). Aos
  5 min são 17 alunos e 1–2 melhorias novas; aos 10 min, 24 alunos e ×5 o Treino/s da chegada; aos 15 min, 27 alunos. No Jiu-jitsu os
  alunos rendem mais, porque o bônus da equipe da arte multiplica: ×11–12 aos 10 min.
- **Clique x renda:** 1 clique vale **67% a 123%** da renda/s sem a mão no fim da estadia (o mínimo, entre todas as estadias, é 67%; a
  meta é ≥ 25%). O clique perde terreno no Jiu-jitsu e no Muay Thai e ganha no Boxe (as melhorias ×3 multiplicam o clique), mas nunca
  chega perto do limite.
- **Dinheiro:** o menor saldo ao vencer o James foi **$91.300**, e a mudança custa $25.000. Nenhuma das 2.124 estadias ficou sem mudar.

### 7.2 Patrocínio
- Nas campanhas com o James vencido e a linhagem já com cinturão, o robô assinou **sempre depois do Dinho Pulga** (fama 200 com os nós
  de fama) e levou **+$39.000** na mediana da campanha (Muralha, Tonhão, Kid e os 4 regionais; são $39.250 se vencer todos).
- Efeito: ~17% a mais de dinheiro na campanha, que sai quase todo em Prof. Nelson, e ele rende pouco no fim. É o "pequeno" que o dono
  pediu: o contrato se vê (calção, cartaz, linha na vitória) e não mexe no ritmo.

### 7.3 Legado (a região CENTRO absorve o que sobrava)
`fase8a2_sim.py legado` (4/s): Legado que sobra **depois** das compras da árvore, mediana por campanha. As campanhas 1–4 são iguais nas
duas versões (0 · 140–160 · 160–250 · 270–380). A tabela mostra as campanhas 5 a 10:
| Combinação | Com o centro (5 → 10) | Sem o centro, 8a1 (5 → 10) | 1ª mudança (campanha) | Da 1ª mudança até fechar a região (med; p90) |
|---|---|---|---|---|
| Boxe Mão rápida | 1.604 · 4.860 · 6.265 · 17.477 · 28.280 · 41.700 | 3.052 · 15.024 · 28.044 · 40.345 · 52.897 · 64.760 | 6 | 1; 2 |
| Boxe Contragolpista | 960 · 3.920 · 5.962 · 13.590 · 24.822 · 34.535 | 3.352 · 14.395 · 25.674 · 30.760 · 43.612 · 55.395 | 6 | 1; 2 |
| JJ Finalização | 720 · 4.160 · 4.175 · 13.477 · 20.678 · 32.383 | 830 · 11.250 · 22.590 · 33.545 · 41.020 · 53.242 | 6 | 1; 3 |
| JJ Por cima | 1.190 · 3.575 · 8.250 · 16.360 · 26.457 · 38.680 | 2.155 · 11.622 · 24.940 · 37.763 · 49.518 · 58.428 | 6 | 1; 2 |
| MT Canela | 640 · 2.535 · 5.124 · 8.544 · 15.241 · 22.474 | 1.440 · 7.827 · 16.203 · 26.678 · 32.721 · 44.254 | 6 | 1; 3 |
| MT Clinch | 670 · 1.800 · 5.390 · 14.270 · 26.562 · 35.332 | 1.240 · 9.771 · 22.850 · 35.237 · 39.862 · 50.305 | 6 | 1; 2 |
- A 1ª mudança acontece na **campanha 6** (mediana; é a do 1º James). A região CENTRO **fecha na campanha seguinte** (p90: 2–3 depois). As
  compras continuam uma por vez (5.000, depois 7.000, depois 10.000). Nas campanhas 6–7, o Legado parado cai de ~8–28 mil para ~2–8 mil.
- **Recado para a 8b:** depois da região CENTRO o Legado volta a juntar (~10–13 mil por campanha regional), e na campanha 10 sobram ~22–42
  mil. Na 8a2 isso não é problema (não há o que comprar e nada quebra), mas a 8b precisa de um destino para ele. Não adiantei nada aqui.
- Com a região comprada, as campanhas seguintes ficam mais curtas (clique +12%, academia +20%, +1 dia por luta). Isso só vale depois do
  1º Cinturão do Vale, e é o prêmio esperado de quem chegou lá.

## 8. Nada muda até o 1º Cinturão do Vale (prova)
- **Por construção:** tudo da 8a2 depende de `cinturao_regional()` (mudança), de `permanent.regional_belts ≥ 1` (patrocínio,
  recorte, cartaz) ou de `permanent.center_reached` (árvore, fala). Antes do 1º Cinturão do Vale nenhuma dessas condições é verdadeira.
  O conteúdo novo mora em `data/center.json`, e os arquivos antigos (`generators.json`, `training.json`, `skill_tree.json`) não mudaram.
  A reserva da LOJA na academia continua 0 (§1.1), e o patrocínio não usa sorteio.
- **Simulador (`fase8a2_sim.py ident`):** o mesmo jogador com e sem o centro, 24 jogadores × 10 campanhas × 6 combinações × 3 e 4
  cliques/s. As campanhas **até a do 1º James** (inclusive, até a vitória) são iguais em tudo: fim, vitórias, lutas (adversário,
  vitória, chance, instante), calendário, Legado, Honra e arte. São **288 de 288 jogadores iguais, com 12.497 lutas comparadas.** Nas
  campanhas depois dela, 1.040 de 1.042 mudam: é o centro agindo (patrocínio e árvore).
- **No jogo:** `foto.gd` igual à main, e o `qa_f8a1_ident.gd` (37.800 lutas) passa com o `center.json` presente (§11, testes a e b).

## 9. Save (continua **v13**; só campos opcionais)
| Onde | Campo | Valor | Validação |
|---|---|---|---|
| `career` | `location` (já existe) | agora aceita `"center"` | `"center"` sem `cinturao_regional()` (escada antes do fim) volta para `"gym"`, com aviso |
| `career` | `generators.center_students` (dicionário que já existe) | int ≥ 0 | fora do centro (save sujo) = 0, com aviso |
| `career` | `upgrade_levels[aparelho]` (já existe) | agora até 5 | 5 fora do centro = 4, com aviso |
| `career` | `sponsor` | `""` \| `"offered"` \| `"signed"` | ausente = `""`; grava **só quando ≠ ""**; `"signed"`/`"offered"` sem `regional_belts ≥ 1` = `""` |
| `permanent` | `center_reached` | bool | ausente = falso; grava **só quando verdadeiro**; `nodes` com `ctr_*` e `center_reached` falso = liga o `center_reached` (o nó só se compra lá) |
| `permanent` | `nodes` (já existe) | aceita `ctr_door`, `ctr_schedule`, `ctr_floor` | id desconhecido sai, como hoje |
| marcos | `center_arrival` | marco novo | fala da 1ª chegada sai uma vez |
- **Save antigo da 8a1 parado depois do James** (na academia, "CAMPANHA COMPLETA"): abre com o MUDAR do centro disponível. Se ele já
  gastou o dinheiro e tem menos de $25.000, o botão fica apagado nesta campanha (decisão D6), e o próximo discípulo chega lá normalmente.
- A cópia do save do dono abre sem erro (ele não tem o Cinturão do Vale ainda: nada aparece).
- `tools/refatoracao/foto.gd`: os campos só são gravados quando usados, então a foto da main não muda. Por segurança, a foto tira
  `career.sponsor` e `permanent.center_reached` do texto, como já faz com os campos da 8a1.

## 10. Contrato de dados
### 10.1 `data/center.json` (gravado; arquivo ausente = jogo da 8a1)
| Campo | O que é |
|---|---|
| `location` | `"center"`: o local em `locations.json` a que o conteúdo pertence |
| `generators[]` | mesmos campos de `generators.json` (`id, base_cost, growth, production, draw_thresholds, name, description, appears_as`) + `location` |
| `apparatus_upgrades[]` | `{apparatus, id, location, cost, multiplier, visual_level, name, description}`: entra no **fim** da lista `upgrades` do aparelho; `apparatus` tem que existir em `training.json`; inválido sai com aviso |
| `sponsor` | `{id, requires_regional_belts (int ≥ 0), fame_at_least (≥ 0), prize_share (0–5), name, brand_sprite, offer_title, offer_line, accept_button, close_button, win_line}` |
| `skill_tree.region` | `{id: "center", name, lock: "center", icon}`: vai para `regions` |
| `skill_tree.nodes[]` | mesmo formato de `skill_tree.json → nodes`; entram **depois** dos nós de hoje; vizinho que não existe sai |
**Por que um arquivo à parte** (o mesmo motivo da liga na 8a1): `generators.json`, `training.json` e `skill_tree.json` continuam
intocados. Os simuladores antigos e a foto continuam lendo os mesmos arquivos de sempre, e "nada muda até o cinturão" fica provado
por construção (sem `center.json`, o jogo é o da 8a1). Para o jogo é tudo uma lista só. Se o Programador preferir juntar nos arquivos de
sempre, pode: os valores são os mesmos (os simuladores antigos precisariam ignorar `location: "center"`).
### 10.2 `data/locations.json` (gravado)
Local `center` (§1.1). `GymData` passa a aceitar `move.requires` `"belt"` ou `"regional_belt"` (hoje força `"belt"`, com aviso) e
`destino_mudanca()` passa a ser "o próximo local depois do atual".
### 10.3 API nova (repasses em GameState; módulo sugerido `scripts/estado/centro.gd`)
| Função | Devolve |
|---|---|
| `no_centro()` | `local_id == "center"` |
| `mudanca()` / `estado_mudanca()` (já existem) | passam a olhar o destino do local atual e o requisito dele |
| `patrocinio()` | `{state, name, brand, bonus_line, offer_title, offer_line, accept, close}` (`{}` se o patrocínio não existe na linhagem) |
| `assinar_patrocinio()` | `"offered"` → `"signed"`, salva, emite `patrocinio_mudou` |
| `recorte_do_vale()` | `{text, name, campaign}` ou `{}` (antes do 1º cinturão) |
| resumo da vitória | ganha `sponsor_money` (int, só com `"signed"`) |
| sinais | `patrocinio_mudou(state)`; `local_mudou("center")` já existe |
### 10.4 Chaves de texto novas (`ui_texts.json` / `dialogos.json`; Roteirista)
Nome e `ambience` do centro, `move_description` do centro, nome/descrição dos alunos e das 6 melhorias, textos do contrato
(`offer_*`, `win_line`), `sponsor_envelope` (rótulo do envelope), hover do cartaz vencido e do recorte (`objects.regional_poster_won`,
`objects.regional_clipping`), nomes e descrições dos 3 nós, falas `cl_primeiro_centro` e `cl_centro_volta_1..3`, `region_center`.

## 11. Quem faz o quê
### Programador
1. `GymData`: local `center`, `requires` por local, `destino_mudanca()` pelo local atual; `reserva_mudanca` só com o requisito do destino
   cumprido (§1.1). `mudar()` para o centro: sem cena, marco e gatilho `center_arrival`, `permanent.center_reached`.
2. Ler `data/center.json`: gerador só no centro; 5ª melhoria com `location`; patrocínio (§4); região e nós da árvore com a trava
   `"center"` (`trava_aberta`, mapa até x = 14).
3. Patrocínio em `concluir_luta` (oferta e bônus no mesmo `salvar()`), ao carregar, `_zerar_carreira`; `sponsor_money` no resumo.
4. Save §9 (v13). Foto §9. `docs/codigo/mapa.md` atualizado (módulo novo).
5. Testes (save de teste, APPDATA temporário, `--position 1950,40`, um Godot por vez): (a) foto igual à main; (b) o `qa_f8a1_ident.gd`
   (tarefa E6 da revisão 8a1) com o `center.json` presente: lutas idênticas até o James; (c) casos exatos `tests/data/fase8a2_casos.json`
   (custo dos alunos 0–40, multiplicador com 0 / 0,25 / 0,5 de bônus, bônus do patrocínio por adversário, custo dos nós); (d) sem o
   cinturão do Vale o MUDAR da academia não aparece e a reserva é 0; (e) o patrocínio ignorado = o mesmo save, campo a campo, que sem
   patrocínio, depois de uma campanha roteirizada; (f) a região CENTRO só aparece com `center_reached`; (g) saves sujos da §9.
### UI/UX
MUDAR do centro (mesmo padrão do da academia), a sala do centro (vazia e com equipe máxima), os alunos na sala, a 5ª melhoria no cartão
do aparelho, o envelope e a janela do contrato, a linha do patrocínio na vitória, a marca no calção, a região CENTRO no mapa da árvore,
o cartaz vencido e o recorte. `alinhamento-ui` com **0 problemas** (estados do critério 18 da 8a2).
### Roteirista
Nome do centro, dos alunos, do patrocinador e das 6 melhorias; fala da 1ª chegada e 2–3 de volta; texto do recorte, do contrato e da
linha da vitória; nomes e descrições dos 3 nós (§10.4). Tom: o Osmar orgulhoso mas pé no chão; o patrocinador é comércio do bairro
que cresceu junto com a escola.
### Diretor de Arte
Centro de treinamento (sala larga, padrão 6d2, mockup antes), com os pontos do Osmar, dos mentores, da equipe antiga, dos alunos, do
envelope, da foto torta e do recorte; aparelhos `_center` (os de arte podem reaproveitar com material novo); cartaz vencido (adesivo do R
+ recorte + camada da marca); marca `sponsor_vale` (cartaz e calção); ícone `region_center` e ícones dos nós (podem reaproveitar os de
hoje, como os nós da academia fazem).
### Artista de Personagens
Alunos da Raízes (camisa preta com o R, 1 pose em ciclo curto, 2 paletas de pele/cabelo para 4 pessoas não parecerem clones) e o calção
com a marca (a primeira peça a cortar, escopo §9).
### QA
Critérios 11–18 da 8a2. Referências: §7 e §8. Rodar `fase8a2_sim.py ident centro legado`.

## Decisões do Designer (revisar com o dono)
| # | Decisão | Por quê | Alternativa |
|---|---|---|---|
| D1 | O conteúdo do centro fica num arquivo à parte (`data/center.json`) | os arquivos antigos ficam intocados, e "nada muda até o cinturão" fica provado por construção; é o mesmo padrão da liga na 8a1 | espalhar em `generators.json`, `training.json` e `skill_tree.json` (os simuladores antigos teriam de filtrar) |
| D2 | A mudança custa **$25.000**, menos que o prêmio base do James | no centro não há como ganhar dinheiro, então o cinturão sempre paga a mudança | preço maior ($60–100 mil), que exigiria reservar dinheiro durante a liga e mudaria o jogo antes do cinturão |
| D3 | Treino **×4** (o dobro da academia); o Ventilador e o nó novo valem na academia e no centro | é o mesmo salto da garagem para a academia; na 8a2 isso só pesa na sala (não há luta) | ×3 (números menores para a 8b) |
| D4 | "Aparelhos novos" = versão visual `_center` + **uma 5ª melhoria ×3** em cada aparelho, só no centro | dá compras em sequência na chegada, sem aparelho novo para desenhar | um 7º aparelho só do centro (mais arte e mais código) |
| D5 | O patrocínio só aparece para a linhagem que já tem **1 Cinturão do Vale**, com a fama da campanha ≥ 200 | nada muda antes do cinturão, e a história fecha (o recorte sai antes do patrocinador) | oferecer desde a 1ª vez que a fama passa de 200 (mudaria as campanhas antes do cinturão) |
| D6 | O bônus é **50% do prêmio base** por vitória depois de assinar; o envelope **fica** até o fim da campanha (AGORA NÃO não perde) | lê fácil ("metade da bolsa a mais"), ninguém perde por fechar a janela, e não há janela no meio do jogo | janela única depois da vitória (recusou, perdeu), ou bônus fixo em $ |
| D7 | Nenhum nó da árvore mexe no patrocínio | no fim da campanha o dinheiro vale pouco, e seria um nó de "+1%" | nó "Contrato renovado" (+50% do bônus) |
| D8 | A região CENTRO tem **3 nós (22.000)**, todos com tipos de efeito que já existem (clique +50%, +1 dia, academia e centro +25%) | fecha em ~2 campanhas regionais, sem código de efeito novo | 4 nós (~25 mil), com um efeito novo |
| D9 | Na chegada sai 1 fala única na 1ª mudança e 2–3 que se revezam nas seguintes, sem cena | é como a academia faz hoje; o escopo pede só "1 fala curta" | só a fala única, e nada nas chegadas seguintes |
| D10 | O recorte vai **preso no cartaz da liga** (na academia, com o adesivo do R) e emoldurado no centro | não confunde com o recorte do Gato Preto (7a2) e usa a mesma peça nos dois lugares | recorte solto em outra parede |
| D11 | Um save antigo da 8a1 parado depois do James com menos de $25.000 não muda nesta campanha | é uma regra só, sem exceção no código, e o próximo discípulo chega lá | mudança grátis para save antigo |
| D12 | O texto do Ventilador ("TREINO NA ACADEMIA") fica como está, embora o efeito já valha no centro | o efeito não muda (critério 15); trocar o texto é com o Roteirista | trocar para "FORA DA GARAGEM" |

## Resumo
- **Mudança:** com o Cinturão do Vale, MUDAR leva ao centro por **$25.000** (o prêmio do James sempre paga). O treino vai a **×4** (×6
  com o Ventilador e o nó novo). Não há luta nova: a campanha fica completa, e passar o posto é a jogada natural. Na chegada sai 1 fala do
  Osmar e a foto torta aparece na parede, sem cena. Todo discípulo começa na garagem.
- **No centro:** os **Alunos da Raízes** (2M, ×1,25, 500 Treino/s; o 1º sai na hora e dobra a equipe) e uma **5ª melhoria ×3** em cada
  aparelho (150M / 250M). Tempo morto no centro: o pior intervalo nos 10 primeiros minutos é **5:46**, e as melhorias novas saem em ~1–5
  min. 1 clique vale **67–123%** da renda/s.
- **Patrocínio pequeno:** depois do 1º cinturão da linhagem, com a fama da campanha ≥ 200 (na prática depois do Dinho), um envelope oferece
  **+50% do prêmio base** por vitória (~+$39 mil por campanha, ~17% do dinheiro), com a marca no calção e no cartaz. Ignorar não muda nada.
- **Árvore:** região **CENTRO** com 3 nós (**5.000 + 7.000 + 10.000 = 22.000**), aberta na 1ª mudança e fechada na campanha seguinte.
  Depois o Legado volta a sobrar (recado para a 8b).
- **Arco 4:** a partir do 1º Cinturão do Vale, o cartaz da liga ganha o adesivo do R e o recorte de jornal, e o recorte aparece
  emoldurado no centro.
- **Nada muda até o 1º Cinturão do Vale:** no simulador, 288 de 288 jogadores e 12.497 lutas idênticas. O save continua **v13**, só com
  campos opcionais (`career.sponsor`, `permanent.center_reached`, nível 5, local `center`, alunos).
