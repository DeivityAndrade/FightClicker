# Fase 8a1 — Liga regional: design

Designer de Jogo, 2026-11-21. Base: `fase8a-escopo.md` (§3, §6, §7 critérios 1–10, 17, 18 e **"Decisões do dono (2026-11-21)"**:
a passiva do adversário trava **um jeito de lutar**, não uma arte; o James aparece só no cartaz, na apresentação e numa fala depois;
perdendo ele continua arrogante). Padrão seguido: `fase7b1-design.md` e `fase7b2-design.md`.
Simulador: `tools/sim/fase8a1_sim.py` (roda em cima do `fase7b2_sim.py`; **só acrescenta**: a escada cresce, as travas e a guarda).
Dados gravados: `data/league_regional.json` (liga, 4 adversários, prêmios, dias, passivas). Casos exatos: `tests/data/fase8a1_casos.json`.
Textos e nomes: `docs/fases/fase8a1-textos.md` (Roteirista, rascunho). **[ROT]** marca o que ainda é provisório.

## 0. A ideia em uma frase
Depois do Kid, a escada continua com **4 lutas regionais** saindo da academia, na arena regional. Cada um dos 3 primeiros trava
**um** dos 6 jeitos de lutar (de artes diferentes); o James, no topo, fecha a guarda no 1º round contra qualquer jeito.
| Ordem | id | Nome [ROT] | Perfil | Passiva (id) | Trava | Escapa quem |
|---|---|---|---|---|---|---|
| 7 | `opp_reg_1` | Zé Bigorna | RESISTENTE | QUEIXO DE FERRO (`adv_iron_chin`) | **Mão rápida** (Boxe 1ª): o K.O. de embalo não entra | Contragolpista, e as 4 de JJ/MT |
| 8 | `opp_reg_2` | Tião Estaca | FORTE | BASE LARGA (`adv_wide_base`) | **Por cima** (JJ 2ª): a queda entra 4× menos | Finalização, e as 4 de Boxe/MT |
| 9 | `opp_reg_3` | Rony Sabão | RÁPIDO | ENSABOADO (`adv_slippery`) | **Clinch** (MT 2ª): prende 3× menos e solta 2× mais | Canela, e as 4 de Boxe/JJ |
| 10 | `opp_james` | James Blindado | RESISTENTE | BLINDADO (`adv_blindado`) | **todos, só no 1º round**: dano nele ×0,6 até 5,33 s | ninguém trava; quem vence tarde sofre menos |
Mantive o "quem trava quem" do Roteirista. Cada jeito é travado **no máximo uma vez**, os 3 são de **artes diferentes**, e em cada arte
o outro jeito passa livre: a 2ª passiva da 7b2 vira resposta contra o Bigorna, e a 1ª vira resposta contra o Estaca e o Sabão.

## 1. Onde a liga entra
### 1.1 Escada e calendário
- A escada em memória passa a ser `opponents.json` (os 6 de hoje, **sem mudança**) **+** `league_regional.json → opponents` (4),
  nessa ordem. O índice só cresce: `indice_escada` 6 = Bigorna, 9 = James, 10 = escada completa ("CAMPANHA COMPLETA").
- **Por que um arquivo à parte** (o escopo falava em `opponents.json`): os 6 de hoje e os simuladores antigos continuam lendo o mesmo
  arquivo de sempre, intocado, e a foto "até o Kid" não tem como mudar. Para o jogo é a mesma escada. Se o Programador preferir
  juntar tudo no `opponents.json`, pode; os valores são os mesmos.
- Todos lutam **da academia** (`location: "gym"`). Não há mudança de local na 8a1.
- **Dias de preparo** (regra da 5.3, contados da luta anterior): Bigorna **16**, Estaca **16**, Sabão **16**, James **20**
  (8, 8, 8 e 10 min de sala). A liga inteira cabe em ~34 min de sala depois do Kid. O nó `prep_days_bonus` vale aqui também.
- **Antes do Kid nada muda.** Vencer o Kid deixa de encerrar a escada: o HUD mostra `PRÓXIMA LUTA REGIONAL: {d} DIAS` **[ROT]**
  no lugar de "CAMPANHA COMPLETA", que só volta depois do James.
- **Save antigo depois do Kid** (`indice_escada == 6`, que hoje é "completa"): abre com a liga aberta e a **folga cheia**:
  `fight_day = dia_atual + 16` (mesma regra da 5.3 para save sem data).
- Perder para um regional encerra a carreira como hoje (Legado ×0,5). Passar o posto no vermelho do dia também, como hoje.

### 1.2 Arena
`league_regional.json → fight_arena: "arena_regional"`. Regra: `arena_da_luta(id)` = a `fight_arena` da liga do adversário, se ele tiver
`league`; senão a do local (como hoje). Os 6 de hoje continuam nas arenas deles (critério 10).

## 2. Passiva do adversário: regras do motor (`scripts/luta.gd`)
1. Campo novo no motor: `passiva_adv` (Dictionary; vazio = nenhuma). Quem põe: `_luta` ao preparar a luta/prévia/risco/motivo, com o
   `passive` do adversário. **Os 6 de hoje não têm `passive`: o motor é exatamente o de hoje** (medido, §9.1).
2. **Travas (`locks`)**: `{tipo_da_passiva_do_jogador: {campo: mult}}`. Ao montar a luta, se `locks` tem o `type` da passiva do
   jogador, o motor usa **uma cópia** da passiva com `campo × mult` (antes de qualquer conta; o `extra` dos nós entra depois, como hoje).
   Sem arte, ou com um tipo que não está em `locks`: nada muda. É só dado: dá para mudar quem trava quem sem mexer no código.
3. **Guarda (`guard`)**: `{rounds, taken_mult}`. Em **todos os 7 laços** (sem arte, Mão rápida, Finalização, Canela, Contragolpista,
   Por cima, Clinch), logo **depois** da variação do dano e **antes** de tirar a vida:
   `se alvo == adversário e t < rounds × round_length: d ×= taken_mult`. Vale para golpe normal, crítico e contragolpe.
4. **Nenhum sorteio novo, nenhuma mudança de ordem.** As travas mudam só números; a guarda só multiplica o dano.
5. Prévia, risco do HUD, robô, motivo e luta usam a mesma função: **a prévia continua honesta por construção** (§7).

### 2.1 Os números (`data/league_regional.json → opponents[].passive`)
| Passiva | Campo | Valor | Efeito |
|---|---|---|---|
| QUEIXO DE FERRO | `locks.fast_hands.ko_per_streak`, `ko_cap` | **×0 / ×0** | o K.O. de embalo **nunca** sai contra ele. O embalo ainda sobe e os socos rápidos ainda batem: a Mão rápida vence por dano ou pontos |
| BASE LARGA | `locks.top_control.td_base`, `td_cap` | **×0,25 / ×0,25** | queda por acerto em pé: 45–58% no Agressivo vira 11–15% |
| ENSABOADO | `locks.thai_clinch.clinch_base`, `clinch_cap`, `escape_base` | **×0,3 / ×0,3 / ×2** | prende ~3× menos (Defensivo 45–60% → 14–18%) e solta 2× mais (teto do `escape_cap` de hoje, 0,8) |
| BLINDADO | `guard.rounds`, `guard.taken_mult` | **1 / 0,6** | no 1º round (até 5,33 s) todo dano nele ×0,6 |

### 2.2 Por que cada uma trava UM jeito
- Queixo de ferro só mexe no K.O. de embalo (`fast_hands`). O Contragolpista (`counter_punch`) nocauteia por **contragolpe** e não
  tem trava: é a resposta do Boxe.
- Base larga só mexe na queda do Por cima (`top_control`). A Finalização não derruba (a pegada enche em pé) e passa livre.
- Ensaboado só mexe no clinch (`thai_clinch`). A Canela marca a perna de longe e passa livre.
- Blindado não trava jeito nenhum: corta o começo da luta de todos. Pesa mais em quem decide cedo (Mão rápida, Por cima) e menos em
  quem vence tarde (Contragolpista, Finalização, Canela). "Paciência" é o recado.

## 3. Como a passiva aparece
### 3.1 Prévia (1 linha, abaixo da linha da sua passiva; textos do Roteirista)
`previa()` ganha, só contra adversário com `passive`:
| Chave | Valor |
|---|---|
| `opp_passive_id` | `adv_iron_chin` etc. |
| `opp_passive_name` | "QUEIXO DE FERRO" **[ROT]** |
| `opp_passive_line` | a linha do Roteirista (`opp_passive_<id>_line`) |
| `opp_passive_hits` | `true` se `locks` tem o tipo da **sua** passiva, ou se é `guard` |
| `opp_passive_hits_text` | `ATRAPALHA: {jeito}` (ex.: "ATRAPALHA: K.O. DE EMBALO") ou "NÃO ATRAPALHA O SEU JEITO" **[ROT]**; guarda: "ATRAPALHA: TODOS NO 1º ROUND" |
| `opp_passive_icon` | `adv_iron_chin` / `adv_wide_base` / `adv_slippery` / `adv_blindado` |
A chance mostrada **já vem com a passiva** (é a mesma conta). `passive_state` e `passive_tactics` já vêm com a trava (ex.: contra o
Estaca o "DERRUBA {p}%" mostra 12%, não 48%). Sem arte: a linha aparece igual, com "NÃO ATRAPALHA O SEU JEITO" (ou a guarda).

### 3.2 Sinal na luta (o mesmo sorteio, só visual)
O motor marca o evento em que **a passiva dele mudou o resultado** (`opp_block: true` no evento; `opp_blocks` no resultado). Como o
sorteio é o mesmo, a regra é exata: "sem a trava este `r_arte` teria dado certo, com ela não deu".
| Passiva | Quando marca `opp_block` (acerto seu que não derrubou por dano) | O que se vê [arte/ROT] |
|---|---|---|
| Queixo de ferro | tentativa de K.O. de embalo (ele ≤ 50%, você à frente) com `r_arte < embalo × ko_per_streak_sem_trava` | ele sacode a cabeça e fica de pé: "AGUENTOU!" |
| Base larga | em pé, `td_com ≤ r_arte < td_sem` | a queda trava no meio, ele não sai do lugar: "NÃO CAIU" |
| Ensaboado | solto, ele ≤ 80%, `ent_com ≤ r_arte < ent_sem` | o clinch começa e ele desliza para fora: "ESCAPOU!" (e o "SOLTOU" de hoje sai 2× mais) |
| Blindado | todo acerto seu nele com `t < 5,33 s` (`guard: true` no evento) | guarda fechada (pose `block` dele no 1º round), número de dano cinza e menor; aos 5,33 s, texto pequeno "A GUARDA ABRIU" |
`*_sem_trava` = o mesmo número do `estado_passiva` calculado **sem** `passiva_adv` (o motor já sabe calcular; é só chamar duas vezes no
preparo). Ícone da passiva dele ao lado da vida dele, sempre (critério da tela).
Quanto aparece: §9.4 (na combinação travada, o sinal sai em quase toda luta).

### 3.3 Motivo da derrota (1 linha, sem simulação nova)
`motivo.opp_note = {id, n}` quando a passiva dele **pesou**:
| Passiva | Quando | `n` | Texto (Roteirista, `reason_opp_<id>`) | Dica (`tip_opp_<id>`) |
|---|---|---|---|---|
| Queixo de ferro | perdeu e `opp_blocks ≥ 1` | blocks | ELE NÃO CAIU NO EMBALO | TENTE OUTRO JEITO: ESPERE O CONTRAGOLPE |
| Base larga | perdeu e `opp_blocks ≥ 1` | blocks | A QUEDA NÃO ENTROU: ELE PLANTOU OS PÉS | A FINALIZAÇÃO AINDA PEGA. OU TREINE MAIS FORÇA |
| Ensaboado | perdeu e `opp_blocks ≥ 1` (ou `released ≥ 2`) | blocks | VOCÊ NÃO PRENDEU: ELE ESCORREGOU | O CHUTE RODADO NÃO PRECISA DE ABRAÇO |
| Blindado | perdeu contra ele (sempre pesa) | % da vida dele que a guarda segurou (`guard_absorbed`) | O 1º ROUND NÃO PASSOU PELA GUARDA | SEGURE O FÔLEGO E ESPERE A GUARDA ABRIR |
`guard_absorbed = Σ d × (1/taken_mult − 1) / vida_max_dele` nos acertos do 1º round. Regra de tela: com `opp_note`, ela ocupa a linha
da passiva (a `passive_note` da sua arte não aparece nessa derrota), para continuar 1 linha só.

## 4. Os 4 adversários (`data/league_regional.json`, valores meus)
| id | F / A / R | Total (× Kid) | Prêmio $ | Fama | Dias | Passiva |
|---|---|---|---|---|---|---|
| `opp_reg_1` Zé Bigorna | 28M / 12M / 80M | 120M (×2,4) | 9.000 | 260 | 16 | queixo de ferro |
| `opp_reg_2` Tião Estaca | 50M / 25M / 125M | 200M (×4) | 12.000 | 300 | 16 | base larga |
| `opp_reg_3` Rony Sabão | 64M / 160M / 96M | 320M (×6,4) | 16.000 | 340 | 16 | ensaboado |
| `opp_james` James Blindado | 60M / 200M / 300M | 560M (×11) | 30.000 | 500 | 20 | blindado; `regional_belt: true` |
Kid = 6,9M / 12,1M / 31,1M (50M). Como cheguei aos perfis (§10.3): o Estaca é "forte" mas sem punir a Finalização (que é a saída
dele); o James é ágil e resistente, com pouca força, para não ser o muro do Jiu-jitsu e do Muay Thai (que sofrem com FORÇA e
RESISTÊNCIA altas) e cobrar do Boxe a AGILIDADE de que ele vive.

**Escala**: os números ficam entre 10⁷ e 10⁹. O `NumFormat` já mostra "560M"/"1.2B"; nada novo.

## 5. James Blindado (Arco 4, 1ª metade)
- Luta sempre igual (não estuda a escola na 8a). Passiva Blindado (§2.1). É a 10ª luta; vencer dá o **cinturão regional**.
- **Falas** (textos no `fase8a1-textos.md` §3, [ROT]). Nada trava o loop: tudo na caixa de diálogo, pulável.
  | Momento | Quando | Situação (escolhida pelo placar da escola, `escola.rival`) |
  |---|---|---|
  | Abertura da liga | 1ª vez que a linhagem vence o Kid (marco `regional_league_opened`; save antigo: ao carregar com `indice_escada ≥ 6`) | cartaz na parede + 1 fala do Osmar (uma vez na linhagem) |
  | Apresentação | ao apertar LUTAR contra o James, **1 vez por campanha** | `met == 0` → "primeira" (3 falas); `met ≥ 3` → "muitas"; `school_wins ≥ 1` → "escola já ganhou"; senão "revanche" (2 falas). ≤ 15 s, pulável |
  | Depois da luta | na tela de fim da luta, **1 vez por campanha** | resultado real (ele venceu / perdeu) × (`met == 1` / `school_wins` antes ≥ 1 / `met ≥ 3`) |
- Placar (`escola.rival`): `met` (+1 a cada luta da escola contra ele), `school_wins`, `james_wins`. Grava no mesmo `salvar()` da luta.
- Ele **não** aparece na sala nem fora da liga.

## 6. Prêmios, cinturão e Legado
- **Dinheiro e fama** da tabela §4 (os nós de dinheiro/fama valem, como hoje).
- **Cinturão regional** = a escada passou do James (como o amador é "a escada passou do Muralha"). Não precisa de campo novo na
  carreira: `cinturao_regional() = indice_escada > índice(opp_james)`. A tela de fim da carreira mostra o cinturão regional e
  "CENTRO DE TREINAMENTO LIBERADO" / "A MUDANÇA CHEGA NA PRÓXIMA VERSÃO" **[ROT]**. `summary.belts` conta os dois cinturões.
- **Legado**: o pote continua `fama × 2 + 100 se cinturão amador` (sem bônus novo pelo regional, para não explodir). A fama regional
  (até 1.400 por campanha) entra no pote normalmente. Medido na §10.2.
- **Honra**: a lista `per_win` já repete o último valor (7) além da 6ª vitória: +7 por luta regional vencida. O hall continua com
  190 de custo total; nada muda nos números travados.
- Linhagem: `permanent.regional_belts` (quantos) e `permanent.first_regional_belt_campaign` (para o recorte da 8a2).

## 7. Prévia honesta (critério 6)
Por construção (mesma função). Medida: §9.3.

## 8. Save (continua **v13**; só campos opcionais)
| Onde | Campo | Valor | Validação |
|---|---|---|---|
| `career` | `ladder_index` (já existe) | agora vai até 10 | 0..tamanho da escada; save antigo com 6 abre na liga com folga cheia |
| `career` | `rival_spoke` | `{before: bool, after: bool}` | ausente = falso; zera em `_zerar_carreira` |
| `career.fight.result` | `opp_blocks`, `guard_absorbed` | int ≥ 0 / 0..1 | opcionais (só contra regional) |
| `permanent` | `regional_belts` | int ≥ 0 | ausente = 0 |
| `permanent` | `first_regional_belt_campaign` | int ≥ 0 | 0 = nunca |
| `escola` | `rival` | `{met, school_wins, james_wins}` (int ≥ 0) | ausente = zeros; `school_wins + james_wins ≤ met` (senão corrige `met`) |
| `escola.roster[]` | `regional_belt` | bool | ausente = falso |
| marcos | `regional_league_opened`, `regional_belt_first` | marcos novos | para a fala do Osmar e o cartaz saírem uma vez |
**Cuidado (Programador):** hoje há código que trata "escada completa" como "venceu o Kid" (ex.: `liberar_ao_carregar` do Muay Thai usa
"escada atual além do Kid"; `best_wins`). Com a escada maior, troque por "índice > índice(opp_gym_2)". A foto até o Kid não muda.

## 9. Medidas (simulador)
### 9.1 Nada muda até o Kid (critério 1)
`fase8a1_sim.py ident`: 3.000 lutas contra os 6 de hoje × (sem arte + 6 combinações), com travas e guarda ligadas: **21.000 de 21.000
idênticas** ao motor da 7b2. Os 6 de hoje não têm `passive`. No jogo: `foto.gd` igual à main até a vitória contra o Kid.

### 9.2 Trava de verdade (critério 4) e nunca imbatível (critério 5)
Treino de referência = **mediana dos atributos que os robôs daquela combinação tinham ao lutar com aquele adversário** (3, 4 e 5
cliques/s; `fase8a1_sim.py trava saida`). A trava é medida a ×0,85 desse treino (luta ainda disputada); a saída, a ×1,0.
| Adversário | Combinação travada | Chance com / sem a passiva, na tática do jeito | Melhor tática com / sem | Perde | As outras 5 combinações | Melhor tática no treino mediano (×1,0) |
|---|---|---|---|---|---|---|
| Bigorna | Mão rápida | Agressivo 62% / 76% | 62% / 76% | **−15** | 0 (nenhuma perde) | Mão rápida 98% A |
| Estaca | Por cima | Agressivo 20% / 60% | 20% / 60% | **−41** | 0 | Por cima 88% A |
| Sabão | Clinch | Defensivo 38% / 82% | 38% / 82% | **−44** | 0 | Clinch 87% D |
| James | (todas, 1º round) | — | Mão rápida 12/34, Contragolpista 30/42, Finalização 46/56, Por cima 37/48, Canela 36/40, Clinch 19/38 | −5 a −22 | — | 80–94% |
**N = 15** (proposta do escopo) cumprido nas três travas. Em cada arte o outro jeito não perde nada contra o mesmo adversário.

Nunca imbatível: melhor tática no treino mediano (×1,0) **da própria combinação**, e entre parênteses no treino mediano de **todos** os
robôs (a mesma pessoa com qualquer combinação):
| | Mão rápida | Contragolpista | Finalização | Por cima | Canela | Clinch |
|---|---|---|---|---|---|---|
| Bigorna | 98% A (93%) | 92% C (82%) | 86% A (82%) | 98% A (99%) | 90% A (92%) | 90% D (73%) |
| Estaca | 94% A (92%) | 88% C (69%) | 86% A (78%) | 88% A (66%) | 88% A (86%) | 84% D (58%) |
| Sabão | 94% D (46%) | 92% A (64%) | 88% A (86%) | 90% A (82%) | 86% D (64%) | 87% D (48%) |
| James | 94% A (40%) | 91% A (58%) | 88% A (88%) | 90% A (90%) | 80% A (68%) | 81% D (81%) |
**Todas ≥ 80%** no treino da combinação (critério: ≥ 50%). Os números baixos entre parênteses são de propósito: com o treino "de outra
arte" a luta fica difícil (ex.: o Sabão contra quem treina como o Jiu-jitsu), e o foco certo resolve.
**Sem arte:** a 1ª carreira nunca chega à academia com o Kid vencido (0 lutas regionais sem arte nas simulações: a arte entra na
chegada à academia). Mesmo que chegasse, no treino mediano a chance seria Bigorna 76%, Estaca 56%, Sabão 60%, James 66% sem passiva
nenhuma a favor, e a carreira 1 inteira dura ~14 min.

### 9.3 Prévia honesta (critério 6; `fase8a1_sim.py honesta`)
1.000 lutas por adversário e combinação; estado = atributos reais do robô ao lutar com ele × 0,6..1,4; tática sorteada; semente real.
| Adversário | Mostrada (média das 6) | Real | Diferença | Pior combinação |
|---|---|---|---|---|
| Bigorna | 60,0% | 59,9% | −0,1 | Clinch −1,0 |
| Estaca | 57,9% | 58,6% | +0,7 | Contragolpista +2,8 |
| Sabão | 60,1% | 60,8% | +0,7 | Finalização +1,8 |
| James | 55,3% | 55,4% | +0,1 | Clinch −1,1 |
**Pior média por adversário: 0,7 ponto; pior combinação isolada: 2,8** (meta ±5). Como acabam as vitórias (de 1.000): o K.O. de embalo
contra o Bigorna é **0** (a trava); Por cima contra o Estaca derruba pouco e vence por pontos (324) mais que pelo juiz (132); o Clinch
contra o Sabão quase só vence por dano (510) e a joelhada some (35).

### 9.4 Sinal visível (critério 3; `fase8a1_sim.py sinal`, 400 lutas por tática, na combinação travada)
| Adversário | Tática do jeito | Lutas com ≥ 1 sinal (×0,85 / ×1,0) | Sinais por luta | Derrotas com a linha do motivo |
|---|---|---|---|---|
| Bigorna (AGUENTOU!) | Agressivo / Contra-ataque | 35% / 53% · 26% / 53% | 0,5–0,8 | 0–16% |
| Estaca (NÃO CAIU) | Agressivo | 82% / 82% | 2,0–2,2 | 93% |
| Sabão (ESCAPOU!) | Defensivo | 80% / 77% | 1,4–1,5 | 87–90% |
O Bigorna é o mais discreto: o K.O. de embalo só é tentado com ele ≤ 50% e você na frente, e aí quase sempre você já está ganhando
(por isso a linha do motivo quase não sai: quando você perde, a trava não chegou a agir). Reforço **só visual** (sem motor): contra o
Bigorna, quando o seu embalo chega a 5, ele faz a pose de assinatura (sacode a cabeça e bate no queixo). Assim o sinal aparece em
quase toda luta da Mão rápida, e o "AGUENTOU!" fica para quando ele de fato segurou o K.O. O Blindado se vê sempre (guarda fechada no
1º round, dano cinza e menor, "A GUARDA ABRIU").

### 9.5 Duração (critério 9)
Tela **8,0–19,0 s** em todas as combinações e nos 4 regionais (honesta e campanha). Contragolpista contra o James: 10,7–19,0 s.

## 10. Balanço (critério 8; `fase8a1_sim.py campanha`)
Robô padrão da 7a1/7b2 (calendário, Legado, hall; maior chance; antes da data só luta no verde, no dia luta no amarelo e passa o posto
no vermelho), 72 jogadores × 8 campanhas por combinação. Toda arte entra "como se" liberada na 1ª chegada (a comparação de sempre).
### 10.1 Tempo até o 1º cinturão regional
| Combinação | 1º Kid (4/s) | **1º James, 4/s: mediana** / média / p90 | Campanhas do 1º Kid ao 1º James, 4/s (med; p90) | **3/s: mediana** / média | 3/s (med) | Nunca em 8 (4/s · 3/s) |
|---|---|---|---|---|---|---|
| Boxe Mão rápida | 40:52 | **165:37** / 169:16 / 203:19 | 3; 5 | **189:54** / 188:04 | 4 | 1 · 6 de 72 |
| Boxe Contragolpista | 40:45 | **173:42** / 176:55 / 220:14 | 3; 6 | **209:30** / 209:02 | 4 | 4 · 9 |
| JJ Finalização | 41:19 | **189:40** / 187:20 / 227:00 | 4; 5 | **205:18** / 204:30 | 4 | 4 · 10 |
| JJ Por cima | 41:49 | **163:05** / 165:22 / 207:13 | 3; 5 | **186:18** / 187:47 | 4 | 3 · 9 |
| MT Canela | 41:22 | **170:58** / 173:44 / 216:45 | 3; 6 | **206:44** / 204:41 | 5 | 7 · 14 |
| MT Clinch | 40:28 | **183:04** / 184:44 / 220:33 | 4; 6 | **208:28** / 210:53 | 4 | 5 · 11 |
| **Diferença entre as 6** | — | **mediana 16,3%** · média 13,3% | | **mediana 12,5%** · média 12,3% | | |
- **Ritmo (critério 8):** o 1º cinturão regional vem **3–4 campanhas depois do 1º Kid** na mediana (4/s), 4 a 3/s (a Canela a 3/s dá 5).
  Ninguém ganha na mesma campanha do 1º Kid, e só 4 de 864 jogadores na seguinte: a liga pede a árvore e, para quem quer, a 2ª passiva.
- **Equilíbrio:** a 3/s as seis ficam a **12,5%** (mediana) — dentro dos 15%. A 4/s ficam a **16,3%**: a única fora é a **Finalização**
  (189:40), que já era a mais lenta antes da liga (média até o Kid 47:33 na 7b2, a maior das 6) e aqui perde mais Legado em
  derrotas no amarelo antes da liga (Legado mediano da 2ª campanha 830, contra 1.710–2.490 das outras). Sem ela, as outras 5 ficam a
  12,3% a 4/s. Com 72 jogadores a mediana oscila ~±3%; ver a alavanca na §10.4.
- **Onde cada uma empaca** (carreiras que acabaram antes do James): Mão rápida no Sabão (passa o posto) e no Bigorna; Por cima no
  **Estaca** (passa o posto 78 vezes: a trava); Clinch no **Sabão** (66: a trava) e no Bigorna; Finalização no **James** e no Estaca;
  Canela no Sabão e no Bigorna. Cada um tem o seu muro, e nenhum é o mesmo para todos.
### 10.2 Metas de pé
| Meta | Medido |
|---|---|
| Tempo morto ≤ 10 min, contando a liga | p90 **7:54–9:47** (o maior é a Finalização) |
| 1 clique ≥ 25% da renda/s no fim | ao vencer o James: **69–88%** (mediana), mínimo 52% |
| Luta 8–20 s | 8,0–19,0 s |
| 1ª carreira, cinturão amador, Kid | iguais à 7b2 (o 1º Kid sai em 40:28–41:49 a 4/s, como na tabela da 7b2) |
| Legado por campanha (mediana, campanhas 1→8) | sem a liga: 80 · 1.710 · 2.490 · 3.270 · 3.760 · 3.760 …; **com a liga**: 80 · 1.710 · 3.390 · 5.823 · 6.630 · 13.420 … (Mão rápida 4/s) |
| Árvore cheia (campanha, mediana) | sem a liga **6**; com a liga **5–6** |
**O Legado não explode a árvore:** ela fecha no máximo 1 campanha mais cedo, e as compras continuam uma por vez (o robô compra o mais
barato que cabe). O que muda é o **depois**: uma campanha com o cinturão regional rende ~13.400 de Legado (sem a liga, ~3.800), e com a
árvore cheia esse Legado fica sem destino até a 8a2. **Recado para a 8a2:** a região CENTRO deve custar na escala de 1–2 campanhas
regionais (~15–25 mil no total), ou o Legado sobra. Não mexi na fama dos regionais por isso: o Legado alto é o prêmio de quem chegou.
A Honra sobe +7 por vitória regional (lista `per_win`); o hall continua custando 190 no total e fecha como hoje.
### 10.3 Como cheguei (só a liga muda)
| Versão | Bigorna | Estaca | Sabão | James | Travas / guarda | 4/s mediana (diferença) |
|---|---|---|---|---|---|---|
| 1ª | 18/18/84 | 90/20/90 | 64/160/96 | 110/110/340 | queixo ×0,2, base ×0,2, sabão ×0,2, guarda 0,5 | 161–193 (19,8%): MT e Finalização presos no Estaca e no James |
| 2ª | — | 70/20/110 | — | 140/140/280 | — | 163–193 (18,5%): força alta no James travou JJ e MT |
| 3ª | 24/10/86 | 60/20/120 | — | 110/130/320 | queixo ×0, base ×0,25, guarda 0,6 | 160–195 (22%) |
| 4ª | — | — | — | 80/180/300 | — | 162–193 (19,2%) |
| **final** | **28/12/80** | **50/25/125** | **64/160/96** | **60/200/300** | **sabão ×0,3** | **163–190 (16,3%); 3/s 12,5%** |
Lição: o Jiu-jitsu e o Muay Thai sofrem com FORÇA e RESISTÊNCIA altas do adversário (pegada, finalização, clinch e marcas dependem
disso); o Boxe sofre com AGILIDADE alta. Por isso o James (o último) é ágil e de pouca força, e o Estaca (que não deve punir a
Finalização) tem menos força do que o nome sugere.
### 10.4 Alavancas (para o QA e a revisão)
- **Finalização a 4/s:** `opp_james.strength` 60M → 45M ou `guard.taken_mult` 0,6 → 0,65 (a guarda atrasa a finalização, que só entra
  com ele ≤ 60%). Não mexi mais porque a 3/s ela já está no meio do grupo e a cauda vem de antes da liga.
- **Trava fraca demais/forte demais:** só dado (`locks`). Base larga ×0,25 e Ensaboado ×0,3 tiram ~40 pontos na tática do jeito; o
  Queixo ×0 tira 15 (o K.O. de embalo é a parte menor das vitórias da Mão rápida).

## 11. Contrato de dados
### 11.1 `data/league_regional.json` (gravado)
| Campo | Onde | O que é |
|---|---|---|
| `id`, `after`, `location`, `fight_arena` | topo | liga `regional`, abre depois de `opp_gym_2`, luta da `gym`, arena `arena_regional` |
| `opponents[]` | lista | mesmos campos de `opponents.json` (`id, name, description, entry, wins_line, loses_line, strength, agility, endurance, prize_money, prize_fame, prep_days, belt, profile, location`) + `league`, `regional_belt` (só James) e `passive` |
| `passive.id` | adversário | `adv_iron_chin` / `adv_wide_base` / `adv_slippery` / `adv_blindado` (ícone, textos) |
| `passive.locks` | adversário | `{type: {campo: mult}}`; tipos válidos = os 6 de `arts.json`; campo tem que existir na passiva; mult 0–5 |
| `passive.guard` | adversário | `{rounds: 1–3 (int), taken_mult: 0–1}` |
Validação (`FightData`): arquivo ausente = sem liga (a escada é a de hoje). Adversário inválido sai com aviso; `passive` inválida = sem
passiva (aviso). Nome, descrição e falas faltando: texto padrão (como hoje).
### 11.2 Chaves de texto novas (`data/ui_texts.json`; Roteirista)
`league_regional_next` ("PRÓXIMA LUTA REGIONAL: {d} DIAS"), `league_regional_invite_*`, `arena_regional_name`, `opp_passive_<id>_name`,
`opp_passive_<id>_line`, `opp_passive_hits` ("ATRAPALHA: {jeito}"), `opp_passive_misses` ("NÃO ATRAPALHA O SEU JEITO"),
`opp_passive_guard_hits`, `fight_opp_block_<id>` ("AGUENTOU!", "NÃO CAIU", "ESCAPOU!"), `fight_guard_open` ("A GUARDA ABRIU"),
`reason_opp_<id>`, `tip_opp_<id>`, `belt_regional_*`, as falas do James (`rival_james_<momento>_<situação>_<n>`) e do Osmar.
`{jeito}` = o nome do jeito travado ("K.O. DE EMBALO", "POR CIMA", "CLINCH") = `passive_finish_*`/nome da passiva da 7b2.

## 12. Quem faz o quê
### Programador
1. Escada = `opponents.json` + liga (§1.1); calendário, HUD da data, save antigo pós-Kid com folga cheia; "escada completa" só depois do
   James; troca dos testes "além do Kid" (§8).
2. `scripts/luta.gd`: `passiva_adv`, travas (§2, item 2) e guarda nos 7 laços (§2, item 3); `opp_block`/`opp_blocks`, `guard`,
   `guard_absorbed` (§3.2); `estado_passiva` com e sem a trava. Referência linha a linha: `aplicar_travas`, `_com_adv` e a linha da
   guarda em `tools/sim/fase8a1_sim.py` (`_remendar`); `_blk_box`, `_blk_cima`, `_blk_clinch` = a regra do sinal.
3. `previa()` com as chaves da §3.1; `motivo.opp_note` (§3.3); `arena_da_luta` pela liga (§1.2).
4. James: placar `escola.rival`, escolha da fala (§5), marcos, `rival_spoke`; cinturão regional (§6) e campos de linhagem.
5. Save §8 (v13). `docs/codigo/mapa.md` atualizado.
6. Testes (save de teste, APPDATA temporário, `--position 1950,40`, um Godot por vez): (a) foto igual à main até o Kid; (b) casos exatos
   `tests/data/fase8a1_casos.json` (sem arte + 6 combinações × 4 regionais; `draws`, eventos, fim, `chance_200`); (c) os casos 7a1/7b1/7b2
   continuam passando; (d) save antigo com `indice_escada = 6` abre com a liga e folga cheia; (e) falas do James: 1º encontro, revanche,
   escola já ganhou, 3+; (f) `opp_note` de cada passiva; (g) a escada termina no James.
### UI/UX
Linha da passiva dele na prévia (3 táticas), ícone ao lado da vida dele, sinais da §3.2, HUD da data regional, tela de fim com o cinturão
regional, cartaz na academia. `alinhamento-ui` com **0 problemas** (estados do critério 18).
### Roteirista
Já entregou o rascunho (`fase8a1-textos.md`). Ajuste: o Queixo de ferro trava o K.O. **inteiro** (×0), então "SEGURA O K.O. DE EMBALO"
está certo; o Ensaboado também **solta mais** do clinch (cabe na linha "ESCORREGA DO ABRAÇO"). Chaves da §11.2.
### Diretor de Arte
Arena regional (`arena_regional`, mockup antes), cartaz da liga, cinturão regional, 4 ícones de passiva (podem sair por código).
### Artista de Personagens
James (guarda fechada = pose do 1º round, gesto de desprezo, retrato) e os 3 regionais no rig comum, com 1 pose de assinatura cada
(Bigorna: sacode a cabeça; Estaca: pés plantados na queda; Sabão: desliza do clinch).
### Diretor de Cutscenes
Apresentação do James na caixa de diálogo (≤ 15 s, pulável), sem cena nova.
### QA
Critérios 1–10, 17, 18. Referências: §9 e §10. Rodar `fase8a1_sim.py ident trava saida honesta campanha sinal`.

## 13. Tarefas de balanço da 7b2 (D3, D4, D5)
### D3 — prévia otimista contra o Brutão e o Dudu
- **Não existe "fator de amador" no motor.** O amador luta com as mesmas contas de todo mundo; o que a prévia tem de especial são as
  **200 sementes fixas** (1..200).
- Medi no simulador (`fase8a1_sim.py d3`, 1.000 lutas por caso, estados reais do robô × 0,6..1,4, as 7 combinações): a diferença vai de
  **−0,9 a +2,2** contra o Dudu e o Brutão, quase sempre com a prévia **pessimista** (real acima da mostrada), e trocar as sementes
  (5001..5200) dá o mesmo. No Python não há viés.
- O viés que o QA viu (−2 a −3, prévia otimista) foi medido **no jogo**, com o gerador do Godot e estados de divisão aleatória (o
  Brutão tem F 27.000 / A 1.400: divisões extremas saturam fácil). A causa provável é o conjunto fixo de 200 sementes do gerador do
  Godot contra aquele perfil, não uma regra do motor.
- **Recomendação: não mudar nada.** Está dentro de ±5 e qualquer conserto (sementes por adversário ou 400 amostras) muda a prévia dos
  amadores em ~1–3 pontos para um lado ou outro, o que pede o dono. Se o dono quiser, a opção barata é somar um deslocamento por
  adversário às sementes (`semente = i + 1000 × índice`), sem custo de CPU. A prévia dos amadores hoje **não muda** (±0).
### D4 — meta de 3 com o robô que busca a meta (`SIM_META_TAT=1 fase7b2_sim.py campanha`, N = 3, 100 jogadores × 8 campanhas)
| Arte (1ª passiva) | 4/s: campanhas com a arte até a meta (med; p90; nunca em 8) | 3/s |
|---|---|---|
| Boxe (K.O. de embalo) | **3**; 4; 0 | **3**; 4; 1 |
| Jiu-jitsu (finalização) | **2**; 3; 0 | **2**; 3; 0 |
| Muay Thai (chute rodado) | **3**; 4; 0 | **3**; 5; 1 |
O Muay Thai **não passa de 3** na mediana (a régua da revisão da 7b2): **não precisa de meta por arte**. Buscar a meta não custa tempo
(o 1º Kid desse robô fica a 2,1% entre as artes na mediana a 4/s, 1,1% a 3/s). No jogo o Muay Thai só existe depois do 1º Kid, então as
3 campanhas dele começam a contar dali.
### D5 — limpeza do `fase7b2-design.md`
Feita: a §9.3 agora traz a medida com N = 3 (a tabela acima) e não fala mais em "5" como decisão. Os outros "5" (§13, §16.1, §17) já
estavam em 3.
### D6 — cauda do Por cima a 3/s
Não mexi (só se os testadores reclamarem). Na liga, o Por cima é uma das duas mais rápidas (163:05 a 4/s, 186:18 a 3/s).

## 14. Perguntas ao dono
1. **Equilíbrio a 4 cliques/s:** a 3/s as 6 combinações ficam a 12,5% (mediana); a 4/s ficam a **16,3%**, por causa da Finalização
   (que já era a mais lenta antes da liga). **Recomendo aceitar** como está e deixar o teste dizer; se incomodar, a alavanca é só dado
   (força do James 60M → 45M, §10.4). A alternativa é eu ajustar agora, mas cada rodada mexe nas outras 5 e o ganho fica perto do
   ruído da simulação (±3%).
2. **Queixo de ferro trava o K.O. de embalo inteiro (×0):** é a trava mais clara de ler ("ele não cai no embalo"), mas é também a mais
   discreta na luta (o sinal sai em 1 de cada 2 ou 3 lutas, mais a pose quando o embalo enche). **Recomendo assim**; a outra opção é
   ×0,2 (ainda cai às vezes, mais sinais "AGUENTOU!", trava menor: −10 pontos, abaixo dos 15 do critério).

## 15. Resumo
- **Liga regional** depois do Kid: 4 lutas da academia, na arena regional, com 16/16/16/20 dias de preparo. Escada = os 6 de hoje +
  `data/league_regional.json`. "CAMPANHA COMPLETA" só depois do James. Save **v13** (campos opcionais).
- **Adversários:** Zé Bigorna 120M (Queixo de ferro: K.O. de embalo ×0), Tião Estaca 200M (Base larga: queda do Por cima ×0,25), Rony
  Sabão 320M (Ensaboado: clinch ×0,3, solta ×2), James Blindado 560M (guarda: dano nele ×0,6 no 1º round). Prêmios $9k/12k/16k/30k e
  fama 260/300/340/500.
- **Passivas como dado:** travas = multiplicadores na passiva do jogador por tipo; guarda = 1 linha nos 7 laços. Sem sorteio novo;
  contra os 6 de hoje, 21.000 de 21.000 lutas iguais.
- **Medidas:** trava −15 / −41 / −44 pontos na combinação travada, 0 nas outras; melhor tática ≥ 80% no treino mediano de cada
  combinação; prévia honesta a 0,7 ponto por adversário (pior 2,8); tela 8–19 s; 1º cinturão regional 3–4 campanhas depois do 1º Kid;
  6 combinações a 16,3% (4/s) e 12,5% (3/s) na mediana; tempo morto p90 ≤ 9:47; 1 clique 69–88% da renda/s.
- **D3:** sem fator de amador; no Python não há viés; recomendo não mudar. **D4:** meta de 3 leva 2–3 campanhas com a arte (MT 3),
  sem meta por arte. **D5:** feito.

## Decisões do dono (2026-11-21)
"aprovo" — as duas perguntas seguem a recomendação do Designer:
1. Os 16,3% de diferença a 4 cliques/s (Finalização, a mais lenta) ficam aceitos; o teste do dono decide. Se incomodar, a alavanca é só
   dado (FORÇA do James 60M → 45M).
2. Queixo de ferro trava o K.O. de embalo por completo (×0).
