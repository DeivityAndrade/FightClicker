# Ronda Noturna do Gato Preto: design

Designer de Jogo, 2026-11-22. Base: `ronda-escopo.md` inteiro, com as **Decisões do dono (2026-11-22)** (minigame A "Estátua no
telhado"; a Ronda congela o jogo; o vulto é o discípulo da vez; abre na campanha seguinte ao boato; entra pelo capuz no prego; a
lenda abre uma **região pequena na árvore**; a tela fica pronta para um futuro **tipo de noite**) e o complemento do Produtor (ajuda
de **conveniência e ritmo**, com teto, sem mexer na chance de luta). Também: `fase7a2-design.md` (convite, teto de 9,2%, "ignorar =
foto igual"), `fase7a2-textos.md`, `fase8a2-design.md` e `fase8a2-revisao.md` (R1: Legado sobrando; região CENTRO como modelo).
Simulador: `tools/sim/ronda_sim.py` (roda em cima do `fase8a2_sim.py`; **só acrescenta**). Dados: `data/ronda.json` (novo).
Contas exatas: `tests/data/ronda_casos.json`. **[ROT]** = nome ou texto provisório (o Roteirista entra depois deste documento).

## 0. A ideia em uma frase
De vez em quando aparece um **capuz preto no prego** da sala. Quem clica sai de noite por ~30 s, **anda agachado pelo muro
segurando o botão, vira estátua quando o ladrão olha e, chegando perto, clica para o SUSTO!** Cada ronda aumenta a **LENDA do Gato
Preto**, que é da linhagem e só cresce. A lenda troca a manchete do recorte na parede e abre, aos poucos, a região **GATO PRETO** da
árvore: 3 ajudas pequenas de ritmo, compradas com Legado.

| Peça | Quando aparece | O que faz |
|---|---|---|
| Capuz no prego | da campanha seguinte ao boato do Osmar em diante; 1º aos 6 dias de sala, depois 8 dias depois de cada ronda | abre a Ronda (só se o jogador clicar) |
| Ronda "Estátua no telhado" | ao clicar no capuz | 3 ocorrências, ~30 s, congela o jogo |
| LENDA | no fim (ou no SAIR) de cada ronda | 1 por ir + 1 por SUSTO + 1 se fez os 3; 5 níveis |
| Recorte da parede | já existe (7a2) | a manchete muda a cada nível; o nome GATO PRETO só a partir do nível 1 |
| Região GATO PRETO | a partir do nível 1 da lenda | 3 nós (3.000 + 6.000 + 9.000 de Legado), cada um preso a um nível da lenda |

## 0.1 A ajuda, em linguagem simples (para o dono)
Quem joga a Ronda abre três ajudas pequenas na árvore. Nenhuma deixa o lutador mais forte na luta. Elas só tiram a espera:
1. **Atalho pelos telhados** (lenda nível 1, 3.000 de Legado): **a campanha já começa com 2 Tios aposentados na equipe.** O começo
   de cada campanha, que é a parte mais parada, anda um pouco mais rápido.
2. **O bairro de olho** (lenda nível 3, 6.000): **+2 dias de preparo em cada luta da liga regional** (as 4 depois do Kid). É folga:
   não precisa lutar mais cedo, só dá mais tempo para treinar antes da data.
3. **O bairro agradece** (lenda nível 5, 9.000): **a equipe rende +40%** (gente do bairro que veio treinar junto). Soma no bônus de
   equipe que a árvore já dá (+225% com tudo comprado), então a equipe fica ~12% mais forte, e a equipe é só uma parte da renda.

Medido no simulador (§8): quem joga a Ronda e compra a região chega ao James **cerca de 3% antes** (de 1% a 6%,
conforme a arte), e ao Kid **até 7,5% antes**, numa campanha com a região e o CENTRO já fechados. Antes disso,
nas campanhas em que o Legado tem de escolher entre o gato e o CENTRO, os dois se compensam e o ganho fica perto de zero (§8.2). A chance de cada luta não muda. Quem não joga a Ronda **nunca fica travado**: a escada, os dois
cinturões, o centro e toda a árvore de antes estão lá do mesmo jeito, e o James chega no mesmo tempo de hoje.

## 1. Regras fixas (do dono e do escopo) e como o design as cumpre
| Regra | Como fica |
|---|---|
| Tela própria, sempre opcional, nunca abre sozinha | Só o clique no capuz abre a Ronda. O capuz não fala, não pisca, não toca som e não some (§3) |
| Não trava nada e não é obrigação | Ir não custa dia nem treino (o jogo congela, §6.1). Não ir não perde nada: o capuz espera no prego |
| 25 a 40 s, SAIR a qualquer hora, piso > 0 | Contagem 2 s + ronda até 34 s + prêmio ~3 s. Medido: **25–32 s** (§4.4). SAIR leva 1 de lenda mais os SUSTOS já feitos |
| Congela o jogo | Relógio da campanha, equipe, Metrônomo, luva dourada, caixas, relógio do convite e do capuz: tudo parado (§6.1) |
| Sorteio próprio | `_rng_ronda`; nunca `rng`, `_rng_evento`, `_rng_fala`, `_rng_sucessao` nem `_rng_treino` (§6.3) |
| Lenda da linhagem, só cresce | `permanent.black_cat.legend`; nada a diminui (§5) |
| Região pequena, com teto, sem quebrar | 3 nós com valor fixo (não crescem com a lenda e não somam com outro nó igual), sem efeito na chance de luta (§5, §7) |
| Quem não joga não fica travado nem atrás no essencial | Nada da escada, dos cinturões, do centro e da árvore de antes depende da Ronda (§8) |
| Mesma foto até a compra do 1º nó | A Ronda congela tudo e a lenda só muda textos; a 1ª diferença possível é o efeito do 1º nó comprado (§8) |
| Pronta para outro tipo de noite | O capuz carrega um **tipo de noite** (`nights` no `ronda.json`); hoje só existe `scare` (§10) |

## 2. Quando a Ronda abre
- **Regra:** a Ronda existe para a linhagem a partir da campanha `C + campaigns_after_rumor` (1), em que `C` é a campanha gravada
  no marco `black_cat_rumor_heard` (o `_gravar_marco` da 7a2 já grava `{"campaign": n}`). Trava extra de segurança:
  `min_campaign` 3 (o boato só sai da campanha 2 em diante, então a 1ª carreira, a do John, nunca vê o capuz).
- **Save antigo** com o marco **sem** o campo `campaign` (ou com número inválido): abre já na campanha atual.
- **Sem o marco** (quem nunca jogou a Panfletagem com o recorte na parede): a Ronda não abre. É a decisão do dono (pergunta 4 do
  escopo). Ver a pergunta P1 no fim.
- Vale nos 3 locais (garagem, academia, centro). A rua da Ronda é **sempre a do bairro** (a borracharia), qualquer que seja o local.
- Depois da escada completa (James vencido, ou no centro) o capuz continua aparecendo: não há luta para atrapalhar.

## 3. O capuz no prego
### 3.1 Relógio
| Campo (`ronda.json → hood`) | Valor | O que é |
|---|---|---|
| `first_after_s` | **180** | 1º capuz da campanha aos 180 s de sala (6 dias) |
| `interval_s` | **240** | o próximo, 240 s de sala (8 dias) depois da **volta** da ronda anterior |
- `hood_s` = segundos de **sala ativa** (`sala_ativa()`) desta campanha. Diferente do convite, **não precisa do Osmar desenhado**: o
  capuz é do discípulo. Não anda em janela, luta, cena, fala travada, fim, sucessão, treino fora, Ronda e dia da luta.
- **Não acumula:** com o capuz no prego, `hood_s` continua contando, mas o próximo só é marcado na volta da ronda
  (`next_at = hood_s_da_volta + 240`). Assim existe no máximo 1, e quem deixa o capuz parado não "perde" rondas: elas simplesmente
  não existem.
- **Por que 180 e 240:** o convite do Osmar aparece aos 300 s e a cada 240 s. Com o capuz aos 180 s e o mesmo intervalo, quem vai
  em tudo na hora vê os dois sempre com **2 min de distância**: nunca juntos na tela. São ~8 a 9 capuzes por campanha (medido,
  §5.3), cerca de 1 a cada 4 min de sala, como o escopo propôs.

### 3.2 Quando ele pode aparecer (todas verdadeiras)
1. a Ronda está aberta para a linhagem (§2) e `hood_s ≥ next_at` e o prego está vazio;
2. sala ativa, sem balão de fala de ninguém, sem gesto de calçar, sem abertura, sem saída do John, sem caixa abrindo;
3. não é o dia da luta; nenhuma janela aberta.
Se 2 ou 3 falham, ele espera e aparece no 1º quadro em que tudo vale. Se a condição volta a falhar **com ele já no prego** (abriu
uma janela, chegou o dia da luta, começou uma fala), ele **continua no prego** mas fica sem clique (hover e clique desligados)
até a condição voltar. Não some e não muda nada no relógio.

### 3.3 O objeto
- Capuz preto com as orelhas costuradas, pendurado num prego, no ponto `hood_spot` / `gym_hood_spot` / `center_hood_spot` (Diretor
  de Arte; conferido com a equipe máxima no `ui_audit`). Parado: sem fala, sem balão, sem brilho, sem som.
- Hover: **"SAIR DE NOITE?"** (`hood_hover`) **[ROT]**. Clique: abre a Ronda.
- MUDAR de local com o capuz no prego: o capuz vai junto (aparece no prego do local novo, mesmo estado).

## 4. O minigame "Estátua no telhado"
### 4.1 A tela e a regra
- Rua da borracharia à noite, vista de cima do muro. O vulto (o discípulo da vez com o traje) começa na ponta do muro; o ladrão
  trabalha de costas no fim dele. **Uma barra de distância** (0 a 1) no muro mostra quanto falta.
- **Segurar** (botão do mouse ou espaço) = o vulto avança agachado (`advance_per_s` **0,25**: 4 s segurando do começo ao fim).
- **Soltar** = congela (estátua). Parado, ele nunca é visto.
- **O ladrão** faz um ciclo: **TRABALHA** (de costas, um tempo sorteado) → **AVISO** (para de mexer, a cabeça começa a virar, um
  "?" pequeno) → **OLHANDO** (vira para trás) → TRABALHA de novo.
- **VISTO:** andar durante o OLHANDO, depois de `grace_s` **0,2 s** de tolerância. O ladrão grita, larga nada e foge correndo
  (**ESCAPOU** [ROT]). A ocorrência acaba sem SUSTO e vem a próxima. **Não há outro castigo** (falha leve).
- **PERTO:** com a distância ≥ `scare_zone` **0,8**, o vulto fica "perto" (letreiro piscando **SUSTO!**, sinal do HUD). O próximo
  **apertar** (depois de soltar) é o **SUSTO**: o vulto salta do muro com a capa, o ladrão cai de bunda, larga o estepe e foge.
  - SUSTO com o ladrão de costas (TRABALHA **ou AVISO**) vale. SUSTO no OLHANDO (depois da tolerância) = VISTO.
  - Quem segura direto até o fim do muro (distância 1) fica parado lá: segurar no fim não mexe e não é visto. Precisa soltar e apertar.
- **Instrução (1 linha, na contagem) [ROT]:** "SEGURE PARA ANDAR. SOLTE QUANDO ELE OLHAR. PERTO, CLIQUE!"
- A ronda acaba quando as 3 ocorrências acabam (SUSTO ou VISTO) ou em `night_s` **34 s** (as que faltam ficam sem SUSTO). SAIR a
  qualquer hora.

### 4.2 Tempos
| Campo (`nights.scare`) | Valor | O que é |
|---|---|---|
| `countdown_s` | 2,0 | contagem (com a instrução) |
| `night_s` | 34,0 | limite da ronda depois da contagem |
| `intro_s` | 0,8 | por ocorrência: o vulto chega no muro; segurar ainda não anda |
| `advance_per_s` | 0,25 | distância por segundo segurando |
| `scare_zone` | 0,8 | a partir daqui o apertar é o SUSTO |
| `grace_s` | 0,2 | tolerância no começo do OLHANDO |
| `scare_anim_s` / `seen_anim_s` | 1,6 / 1,2 | SUSTO (salto, queda, fuga) / ESCAPOU, antes da próxima ocorrência |

### 4.3 As 3 ocorrências (sempre nesta ordem)
| id | Onde [ROT] | Trabalha (s, sorteado) | AVISO (s) | OLHANDO (s) | AVISO falso | Ideia |
|---|---|---|---|---|---|---|
| `tire` | ladrão de estepe na borracharia | 2,2–3,4 | 0,8 | 1,2 | 0% | a de aprender: calma e aviso longo |
| `bike` | moleque mexendo numa bicicleta | 1,5–2,5 | 0,6 | 1,0 | 0% | nervoso: olha muito, mas pouco tempo |
| `gate` | sujeito forçando um portão | 1,8–3,0 | 0,6 | 1,4 | **30%** | desconfiado: às vezes faz o AVISO e volta a trabalhar sem olhar |
- Os ciclos de cada ocorrência são sorteados **na criação da ronda** (lista de `[tempo de trabalho, aviso falso]`), com `_rng_ronda`.
  O teste do Godot injeta a lista (§11.3).
- **Sem dificuldade por nível:** a ronda é a mesma no nível 0 e no 5. O que muda com a lenda é a rua (§5.2), não a regra. É um
  passeio, não uma escada.

### 4.4 Medido (`ronda_sim.py mini`, 2.000 rondas por perfil)
Robô com atraso de percepção (`react`) e uma chance de perceber o AVISO (se não percebe, só reage quando ele já está olhando).
Duração total = contagem + ronda + 3 s de tela de prêmio.

| Perfil | Reação; vê o AVISO | 0 / 1 / 2 / 3 SUSTOS | Lenda por ronda (média) | VISTO (média) | Duração total: med (p10; p90; máx) |
|---|---|---|---|---|---|
| atento | 0,25 s; 95% | 0% / 0% / 8% / 92% | 4,83 | 0,09 | 0:29 (0:27; 0:29; 0:31) |
| médio | 0,40 s; 80% | 0% / 5% / 33% / 62% | 4,20 | 0,43 | 0:28 (0:25; 0:30; 0:31) |
| distraído | 0,55 s; 50% | 6% / 33% / 42% / 19% | 2,93 | 1,26 | 0:26 (0:23; 0:30; 0:32) |
| só o piso (SAIR na hora) | — | 100% / 0 / 0 / 0 | 1,00 | 0 | 0:03 |
- **Legível e com SUSTO garantido (critério 6):** até o distraído (0,55 s de reação, percebe só metade dos avisos) faz pelo menos 1
  SUSTO em **94%** das rondas. O médio faz os 3 em 62%.
- **Curta (critério 5):** **23–32 s** no total, dentro dos 25–40 s do escopo (o distraído às vezes termina antes porque foi visto
  mais vezes e a ocorrência acaba na hora). Quem sai na hora fica com o piso (1 de lenda) em ~3 s.
- **Tem habilidade:** quem joga bem (atento) ganha 4,8 por ronda; quem joga mal, 2,9; quem só vai, 1. A Ronda recompensa jogar, mas
  nunca castiga.

### 4.5 Juice do SUSTO (UI/UX; critério 7)
Letreiro **SUSTO!** grande, tremida da tela (a mesma do K.O.), o ladrão caindo de bunda com o objeto voando, poeira, e o som do
golpe crítico reaproveitado. ESCAPOU: letreiro menor, cinza, sem tremida (falha leve).

## 5. A LENDA do Gato Preto
### 5.1 Quanto cada ronda dá
`lenda_da_ronda = floor (1) + per_scare (1) × SUSTOS + clean_bonus (1, só com os 3 SUSTOS)` → **1 a 5** por ronda.
- **Só ir já dá 1** (piso > 0). SAIR leva `1 + SUSTOS feitos` (o bônus de 3 só com os 3 feitos).
- **Fechar o jogo no meio:** nada (a lenda só entra no fim ou no SAIR, numa gravação só; §6.2).
- Também soma: `permanent.black_cat.scares` (SUSTOS da linhagem, o contador "OCORRÊNCIAS: N" [ROT]) e `rounds` (rondas feitas).

### 5.2 Os 5 níveis
| Nível | Lenda total | Recorte na parede (hover) | Na rua da Ronda | Abre na árvore |
|---|---|---|---|---|
| 0 | 0 | o de hoje (VULTO MASCARADO...) | rua normal | — |
| 1 | **1** (a 1ª ronda) | o jornal **dá o nome: GATO PRETO** [ROT] | — | a região GATO PRETO e o nó **Atalho pelos telhados** |
| 2 | **12** | manchete exagerada [ROT] | pichação do gato no muro da borracharia | — |
| 3 | **30** | mais exagerada [ROT] | + faixa "VALEU, GATO PRETO" [ROT] | **O bairro de olho** |
| 4 | **52** | mais exagerada [ROT] | + criança com orelhinhas de gato na janela | — |
| 5 | **80** | absurda (ex.: "GATO PRETO PARA ÔNIBUS COM UMA MÃO") [ROT] | + o bairro inteiro com o gato desenhado | **O bairro agradece** |
- Textos: `black_cat_clipping` (nível 0, já existe) e `black_cat_clipping_1..5` (Roteirista). Camadas da rua:
  `street_layers_by_level` no `ronda.json` (Diretor de Arte).
- **Subiu de nível:** a tela de prêmio mostra o letreiro **A LENDA CRESCEU** [ROT] e o recorte novo em grande (o "jornal do dia
  seguinte"). O recorte da parede já está trocado quando o jogador volta para a sala. `shown_level` guarda o último nível mostrado,
  para o aviso sair uma vez só (mesmo se o jogo fechar na tela de prêmio).
- **Depois do 5:** a Ronda continua igual, com "OCORRÊNCIAS: N" no prêmio, sem prêmio novo (escopo §4).

### 5.3 Ritmo medido (`ronda_sim.py lenda`, 4/s, 8 jogadores por linha, a Ronda aberta na campanha 3; mediana no fim de cada campanha)
| Perfil | Combinação | Rondas por campanha (3 → 12) | Nível no fim das campanhas 3 · 4 · 5 · 6 | Lenda na campanha 12 |
|---|---|---|---|---|
| atento | Boxe Mão rápida | 9 9 8 9 9 9 9 8 8 8 | 3 · 5 · 5 · 5 | 388 |
| médio | Boxe Mão rápida | 9 9 8 9 9 9 9 8 8 8 | 3 · 4 · 5 · 5 | 343 |
| médio | JJ Finalização | 8 7 9 10 9 9 8 7 8 7 | 3 · 4 · 5 · 5 | 313 |
| médio | MT Canela | 10 4 11 10 11 10 9 9 9 9 | 3 · 4 · 5 · 5 | 363 |
| distraído | Boxe Mão rápida | (as mesmas) | 2 · 3 · 4 · 5 | 225 |
| só o piso | Boxe Mão rápida | (as mesmas) | 1 · 2 · 2 · 3 (o 4 na campanha 9) | 76 |
(Níveis contados com os limiares finais 1 / 12 / 30 / 52 / 80 sobre a lenda medida. Lenda no fim das campanhas 3 · 4 · 5: atento
45 · 86 · 114; médio 39 · 72 · 102; distraído 28 · 47 · 70; piso 9 · 18 · 24.)
- Indo em todas as rondas, o nível 5 chega na **2ª ou 3ª campanha de Ronda** (atento e médio), como o escopo pede. Quem joga mal
  chega em 4; quem vai e sai na hora (só o piso) chega lá pela 9ª. Ninguém chega no 5 de uma vez.
- ~8 a 10 rondas por campanha (o centro do 8a2 conta: a estadia de 15 min tem capuz também).

## 6. Regras de estado (para o Programador)
### 6.1 O que anda durante a Ronda
| Coisa | Durante a Ronda |
|---|---|
| Relógio da campanha, dia, avisos, data da luta | **parado** |
| Equipe, Metrônomo, assistido, luva dourada, FRENESI, bônus do Jiu-jitsu por tempo, caixas, tempo morto | **parados** (diferente do treino fora da 7a2: aqui **nem a equipe produz**) |
| `hood_s` do capuz e `room_s` do convite | parados |
| Autosave | normal (grava o capuz ainda no prego e nenhuma lenda; §6.2) |
Em código: um estado novo `ronda_ativa` ("" ou o id da noite) faz `sala_ativa()` dar falso e, no `tick`, **não soma nada**: só passa
o tempo do minigame (`_ronda_jogo.passo(delta, ...)`). A UI não chama `passo` (mesmo padrão da 7a2).

### 6.2 IR, SAIR, fechar o jogo
- **IR** (clique no capuz): **não grava nada**. O capuz continua `open` no save. Abre a tela.
- **Fim ou SAIR:** calcula a lenda (§5.1), soma em `permanent.black_cat`, esvazia o prego (`open = ""`), marca
  `next_at = hood_s + interval_s` e **salva tudo numa gravação só**. Depois mostra o prêmio. VOLTAR devolve a sala.
- **Fechar no meio:** ao abrir, está na sala com o capuz no prego e a lenda de antes. Como o jogo estava congelado, nada mais
  mudou: não ganha, não perde, nada sai em dobro.
- Trava de segurança: 120 s na tela de prêmio sem VOLTAR devolvem a sala (igual à 7a2).

### 6.3 Sorteio
`_rng_ronda` próprio (`randomize()` ao abrir cada ronda; não vai para o save). Ele só sorteia os ciclos do ladrão. O capuz é
**determinístico** (só relógio e regras). A Ronda nunca toca `rng`, `_rng_evento`, `_rng_fala`, `_rng_sucessao` ou `_rng_treino`.

### 6.4 Nova campanha, sucessão, mudança
- `career.black_cat_hood` zera em `_zerar_carreira` (`hood_s` 0, `next_at` 180, prego vazio). A lenda é da linhagem e fica.
- MUDAR: o capuz vai junto (§3.3); `hood_s` continua.
- O capuz nunca abre a Ronda durante MUDAR, cena ou luta (a Ronda só abre da sala).

## 7. A região GATO PRETO da árvore
### 7.1 Os nós (`ronda.json → skill_tree`)
| id | Pos | Trava | Custo (Legado) | Efeito | Texto [ROT] | Teto |
|---|---|---|---|---|---|---|
| `cat_rooftop` (raiz) | [13, 3] | `black_cat:1` | **3.000** | `start_generator` 2 × `retired_uncle` (tipo que já existe) | COMEÇA A CAMPANHA COM 2 TIOS NA EQUIPE | o jogo usa `max(atual, 2)`: não soma com nada; não cresce |
| `cat_watch` | [14, 5] | `black_cat:3` | **6.000** | `league_prep_days_bonus` +2 (**novo**) | +2 DIAS DE PREPARO NAS LUTAS DA LIGA | só nas 4 lutas da liga regional; valor fixo |
| `cat_thanks` | [12, 5] | `black_cat:5` | **9.000** | `passive_bonus` +0,4 (tipo que já existe) | +40% TREINO/S DA EQUIPE | soma no mesmo bônus de equipe dos outros nós (+2,25 com a árvore cheia): a equipe vai de ×3,25 para ×3,65 (+12,3%); não cresce |
| **Total** | | | **18.000** | | | |
- A região (`{id: "black_cat", name: "GATO PRETO", lock: "black_cat:1", icon: "region_black_cat"}`) só aparece com a lenda no
  nível 1. `cat_rooftop` liga no mapa com `camp_extra_day` [11, 3] (só a linha do desenho). O mapa já vai até x = 14 (8a2).
- **Nó com a lenda baixa (decisão D7):** vizinho de nó comprado mas com a trava fechada aparece **lacrado** (silhueta, sem preço) com
  "PRECISA DA LENDA NÍVEL {n}" [ROT], para o jogador saber o que a Ronda abre. Hoje um nó de trava fechada fica escondido; o estado
  novo `"sealed"` vale **só** para travas `black_cat:N` (os nós de sempre não mudam).

### 7.2 Por que estes efeitos (a diretriz do Produtor)
| Pedido | Como fica |
|---|---|
| Conveniência e ritmo, não poder bruto | começar com equipe (o começo da campanha é a parte mais parada) e folga no calendário da liga; o único bônus de rendimento é pequeno e só na equipe |
| Nada que mude a chance de luta | nenhum dos 3 mexe em atributo, tática, passiva, AQUECIDO ou prévia. A folga só dá mais dias para treinar antes da data |
| Sem multiplicador grande de treino ou clique | o clique não ganha nada; a equipe ganha +12,3% sobre o que já tem (é ~1/5 da renda no fim da campanha). Os 2 Tios valem no começo e somem no meio |
| Teto em cada um | os 3 são fixos, não crescem com a lenda e não somam com outro nó do mesmo tipo |
| Ajuda real ("chega ao James alguns % antes") | James **~1% a ~6% antes** (mediana ~3%), Kid **~0% a 7,5%**, a Muralha no máximo 9,6% (§8.0) |
Descartei: **mais lenda por ronda / capuz mais frequente** (depois do nível 5 não vale nada, e antes dele só encurta a própria Ronda);
**fama a mais contra quem a linhagem já venceu** (vira Legado, que já sobra: não ajuda ninguém); **leitura extra na prévia** (a prévia
já mostra chance, falta e passiva dele; não achei informação nova que não fosse poder); **começar com dinheiro** (medido: $250 já
compra Prof. Nelson e luva no 1º segundo e adianta a Muralha em 26% e o Kid em 17%; é aos saltos e forte demais); **3 Tios** em vez de 2, ou equipe +50%
(a Muralha passa de 10% no Boxe Contragolpista com o resto).

### 7.3 Custos e o Legado que sobrava (R1 da 8a2)
- 3.000 / 6.000 / 9.000: o nó mais barato da região é mais caro que qualquer nó da árvore de antes (o maior é 1.800). O robô que
  compra "o mais barato que cabe" fecha a árvore de antes primeiro e só depois entra no GATO PRETO, misturando com o CENTRO
  (5.000 / 7.000 / 10.000). **A região nunca disputa Legado com a árvore de antes.** Com o CENTRO ela disputa: os dois são extras
  de quem já fechou a árvore, e o jogador escolhe a ordem (no robô, o mais barato primeiro).
- **Destino do Legado:** junto com o CENTRO, são 40.000 para gastar nas campanhas 5–10. Medido (§8.1): na campanha 10 o Legado
  parado cai de 6,6–20,9 mil (sem a região) para 2,4–8,3 mil (com ela).

## 8. Não quebra (medidas)
### 8.0 Teto: força de treino (`ronda_sim.py forca`)
Como o "teto do hall" da 6c2 e a "força" da 7a2: uma campanha sem calendário, robô que só luta no verde (olha a cada 5 s),
derrota sem custo, **árvore de antes e CENTRO cheios, hall cheio** (a linhagem em que a região existe), 12 jogadores por linha.
Ganho = quanto antes chega à vitória (minuto mediano), **com os 3 nós** contra **sem** a região. Na calibração rodei duas versões
vizinhas da final (ambas com 2 Tios e +2 dias na liga): equipe **+25%** e **+50%**. A final (**+40%**) foi medida nos dois piores
casos da calibração.
| Combinação | cps | Sem: Muralha / Kid / James | +25%: ganho Muralha / Kid / James | +50%: ganho Muralha / Kid / James | **Final +40%** | 1 clique ÷ renda no Kid (sem → +50%) |
|---|---|---|---|---|---|---|
| Boxe Mão rápida | 4 | 3:35 / 6:18 / 21:06 | 4,9% / 0,5% / 2,0% | 9,0% / 5,0% / 2,0% | | 87% → 88% |
| Boxe Mão rápida | 3 | 3:50 / 7:11 / 25:11 | 4,5% / −1,2% / 0,1% | 3,4% / 2,0% / 2,0% | | 87% → 88% |
| Boxe Contragolpista | 4 | 3:41 / 6:43 / 21:54 | 8,8% / 6,3% / 2,3% | 10,4% / 8,9% / 3,5% | **9,6% / 7,5% / 2,3%** | 87% → 88% |
| Boxe Contragolpista | 3 | 3:54 / 7:33 / 25:47 | 3,4% / 1,2% / 2,5% | 6,5% / 6,1% / 3,2% | | 87% → 88% |
| JJ Finalização | 4 | 3:00 / 5:47 / 19:09 | 5,6% / 4,3% / 4,3% | 7,7% / 4,3% / 6,7% | | 75% → 78% |
| JJ Finalização | 3 | 3:09 / 6:16 / 22:27 | 8,2% / 4,9% / 4,8% | 8,7% / 5,0% / 6,3% | | 75% → 78% |
| JJ Por cima | 4 | 2:56 / 5:42 / 18:48 | 2,4% / 3,3% / 2,8% | 5,4% / 5,3% / 5,4% | **4,9% / 3,6% / 4,5%** | 75% → 78% |
| JJ Por cima | 3 | 3:00 / 6:06 / 22:11 | 3,6% / 3,0% / 3,6% | 6,1% / 6,0% / 6,8% | | 75% → 78% |
| MT Canela | 4 | 3:42 / 7:25 / 24:14 | 0,9% / 2,4% / −0,3% | 3,9% / 5,8% / 3,0% | | 69% → 70% |
| MT Canela | 3 | 4:03 / 7:58 / 28:47 | 6,8% / 1,0% / 2,2% | 3,3% / 2,0% / 3,0% | | 69% → 70% |
| MT Clinch | 4 | 3:43 / 7:25 / 23:41 | 4,2% / 2,3% / 1,1% | 6,5% / 6,8% / 1,9% | | 69% → 70% |
| MT Clinch | 3 | 4:00 / 7:55 / 28:01 | 3,7% / 1,1% / 2,5% | 4,2% / 1,3% / 3,4% | | 69% → 70% |
(12 jogadores por linha: diferenças de 1–2 pontos são ruído; por isso um valor negativo aparece em 2 linhas do +25%.)
Só os nós, separados (Boxe Mão rápida 4/s): 2 Tios = 6,7% / 3,8% / 1,0%; equipe +25% = 5,0% / 1,7% / 2,2%; equipe +50% = 5,5% / 2,4% /
2,4%; +2 dias na liga = 0 (sem calendário não há data). Descartados na calibração: 3 Tios (JJ 6,5% / 3,1% / 1,1% sozinho) e
**$250 no começo (26% / 17% / 5% sozinho)**.
- **Teto cumprido:** com +40% o pior trecho é a Muralha do Boxe Contragolpista 4/s (**9,6%**, são 21 s de 3:41). Pelas duas vizinhas,
  o Kid fica entre **~0% e 7,5%** e o James entre **~1% e ~6%** (mediana perto de **3%**). A +50% a Muralha passava de 10% (10,4%):
  por isso a final é +40%. O +2 dias da liga não aparece aqui (sem calendário): é folga, não força.
- **Clique x renda:** 1 clique continua valendo **69% a 88%** da renda/s sem a mão no Kid (sobe 1 a 3 pontos, porque a equipe cresce
  um pouco). Muito longe do limite de 25%.
- **Por que o robô olha a cada 5 s (e não a cada 30 s, o padrão dos simuladores antigos):** com 30 s, toda vitória cai numa grade
  de 30 s. Qualquer ajuda que adiante o verde da Muralha em ~10 s faz a luta cair na volta anterior da grade, e o atraso empurra
  todas as lutas seguintes. Medido (Boxe Mão rápida 4/s): com 30 s os **2 Tios sozinhos** dão 14% / 16% / 7% (Muralha / Kid / James), e
  com 5 s dão 6,7% / 3,8% / 1,0%. O ganho de verdade é o segundo: são ~10–20 s no começo da campanha. Um jogador olha a chance o tempo
  todo, e a prévia mostra a cor na hora. Fica registrado: **a régua de 30 s exagera qualquer ajuda de começo de campanha** (vale para
  quem medir de novo a 7a2 ou a 8a2).
- A tabela vem de `ronda_sim.py forca` com `SIM_VAR` (alavanca documentada no simulador); a corrida padrão (`forca` sem `SIM_VAR`)
  mede cada nó separado e os 3 juntos com os valores do `ronda.json`.

### 8.1 Campanha de verdade (`ronda_sim.py ajuda`)
Robô padrão da 8a2 (calendário, Legado, Honra, hall, centro), olhando a cada 5 s (`SIM_OLHAR=5`, §8.0), 7 jogadores × 10 campanhas, 4/s. "Joga" = vai em todas as rondas com o perfil médio
(a Ronda aberta na campanha 3); "não joga" = nunca clica no capuz (lenda 0, região nunca aparece = o robô da 8a2). Mesmas sementes.
Tempo de jogo até a vitória sobre o Kid e o James **dentro de cada campanha** (mediana das campanhas 6–10 em que venceu).
| Combinação | 1ª compra GATO PRETO (campanha, med) | Os 3 nós (campanha, med) | 1º James (campanha, med) não joga → joga | Kid, campanhas 6–10 | James, campanhas 6–10 | Legado parado na campanha 10 | 1 clique ÷ renda no Kid |
|---|---|---|---|---|---|---|---|
| Boxe Mão rápida | 5 | 10 | 8 → 8 | 7:06 → 7:19 (+2,9%) | 25:20 → 25:19 (−0,1%) | 20.877 → 8.326 | 87% → 87% |
| JJ Finalização | 6 | 9 | 7 → 6 | 6:25 → 6:25 (0%) | 22:52 → 23:46 (+3,9%) | 18.467 → 5.705 | 75% → 75% |
| MT Canela | 8 | depois da 10 | 9 → 9 | 9:21 → 8:58 (−4,0%) | 31:11 → 31:26 (+0,8%) | 6.599 → 2.406 | 69% → 69% |
(Com 7 jogadores, ±4% é ruído. Sinal + = mais tarde.)

### 8.2 Leitura
- **Nas campanhas 6–10 o ganho é quase zero, e isso é esperado:** é a janela em que o GATO PRETO e o CENTRO disputam o mesmo Legado.
  O robô compra o mais barato primeiro (3.000 do Atalho antes dos 5.000 do CENTRO), então quem joga a Ronda tem os nós do gato
  **no lugar** de alguns nós do CENTRO por 1 a 3 campanhas. Os dois trocam entre si e o resultado empata (−4% a +4%).
- **O ganho de verdade vem depois que as duas regiões fecham** (campanha ~9–10 em diante): é o §8.0, o James ~3% antes (1% a 6%).
  É o "temperinho" pedido: real, pequeno e de quem joga muito.
- **Quem não joga não perde nada:** o 1º James sai na mesma campanha, e o tempo até o Kid e o James é o do robô da 8a2.
- **O Legado parado cai de 6,6–20,9 mil para 2,4–8,3 mil na campanha 10** (R1 da 8a2): a região dá destino ao que sobrava.
- Clique x renda não muda (69% a 87%).

### 8.3 Teto de 10%
- **A Ronda em si soma 0:** ela congela tudo e não dá prêmio de economia. O teto dos minigames da 7a2 continua **9,2%** (o pior
  trecho, começo da campanha com a árvore vazia), sem medir de novo.
- **A região é o único ganho de quem joga a Ronda**, e ela só existe nas campanhas em que a árvore de antes já está cheia (lenda
  nível 1 + 3.000 de Legado: campanha ~5 em diante). Nessas campanhas o ganho medido da região é de no máximo **9,6%** (Muralha), **7,5%** (Kid) e **~6%** (James), §8.0. Somado ao ganho da 7a2 na
  campanha de verdade (+0,6% a +2,1% em dias no Kid, `fase7a2-design.md` §8.5a), fica abaixo de 10% em todo trecho medido.

## 9. "Nada muda para quem não joga" e "a mesma foto até o 1º nó"
- **Por construção:**
  1. sem o marco do boato, nada da Ronda existe (nem campo no save);
  2. o capuz é um objeto de hover: não fala, não conta como ocioso, não disputa vaga com falas e não usa sorteio. Ele não mexe no
     relógio do convite, no foco nem no `_ocioso`;
  3. a Ronda congela tudo e não chama nenhum sorteio do jogo; a lenda só troca o texto do recorte e as camadas da rua da Ronda;
  4. a região só aparece com lenda ≥ 1, e os efeitos só valem **da campanha seguinte à compra** em diante (como todo nó).
- **Logo:** quem nunca joga tem o jogo da 8a2, e quem joga todas as rondas tem **o mesmo jogo** (dias, treino, dinheiro, FAMA,
  Legado, lutas) até o fim da campanha em que comprou o 1º nó do GATO PRETO.
- **No simulador** (das mesmas corridas do §8.1): joga x não joga, **21 de 21 jogadores iguais** em tudo (fim, vitórias, cada luta,
  calendário, Legado, Honra, arte e tempo) até o fim da campanha da 1ª compra, com **917 lutas comparadas**. Depois dela, mudam
  (é a região agindo).
- **No jogo (critérios 1 e 2 do escopo, com a mudança do dono):**
  - (a) `foto.gd` igual à main: o robô da foto nunca joga a Panfletagem, então nem o capuz existe. Por segurança, a foto apaga
    `career.black_cat_hood` e `permanent.black_cat` antes do hash (uma linha comentada cada, como `training_invite`).
  - (b) Teste roteirizado: a mesma campanha (com o marco do boato e a Ronda aberta) jogada **sem** ir e **indo em todas** as rondas,
    sem comprar nó: o save sai igual campo a campo, tirando só `permanent.black_cat` e `career.black_cat_hood`.
  - (c) Com o 1º nó comprado, a diferença começa na campanha seguinte (ex.: 2 Tios no 1º segundo). É a única diferença permitida.

## 10. Gancho para o futuro "tipo de noite" (lutas contra bandidos, só preparado)
- **Nos dados:** `ronda.json → nights` é um dicionário de tipos de noite e `night_order` é a ordem. Cada tipo tem `id`, `kind` (qual
  lógica e qual cena rodam), `requires` (quando fica disponível; `{}` = sempre), tempos, ocorrências e a regra `legend` própria. Hoje
  só existe `scare` (`kind: "stealth_scare"`).
- **No capuz:** o prego guarda **qual noite** ele traz (`career.black_cat_hood.open = "scare"`, e não só um "sim"). `hood.night_choice`
  (`first_available`) escolhe o tipo quando o capuz aparece. Uma noite nova só precisa de outra regra de escolha (ex.: alternar),
  sem mudar o save.
- **Na tela:** a tela da Ronda é uma moldura (HUD da LENDA, SAIR, contagem, tela de prêmio, camadas da rua) com uma **área de jogo**
  que recebe a lógica pelo `kind`. O prêmio lê só `{night, lenda_ganha, sustos, ...}`. Uma noite de luta entra com outra lógica e
  outra área de jogo, e reaproveita o resto.
- **No código:** `RondaLogica` (a de hoje) é uma das lógicas; `ronda_ir()` cria a lógica pelo `kind` (`stealth_scare` →
  `RondaLogica`; `kind` desconhecido → o capuz não aparece, com aviso). **Nenhuma luta contra bandido, nenhum `kind` novo e nenhum
  texto dela entram nesta fase.**

## 11. Save (continua **v13**; só campos opcionais, sem migração)
| Onde | Campo | Valor | Validação |
|---|---|---|---|
| `permanent` | `black_cat` | `{legend: int ≥ 0, shown_level: 0–5, scares: int ≥ 0, rounds: int ≥ 0, open_campaign: int ≥ 0}` | ausente = tudo 0; grava **só quando `rounds > 0` ou `open_campaign > 0`**; número ruim/negativo = 0; gigante = teto 1e9; `shown_level` > nível da lenda = o nível da lenda; `scares` > 3 × `rounds` = 3 × `rounds` |
| `career` | `black_cat_hood` | `{hood_s: float ≥ 0, next_at: float ≥ 0, open: "" \| id de noite}` | ausente = `{0, 180, ""}`; grava **só com a Ronda aberta na linhagem**; `open` fora de `nights` (ou a Ronda fechada) = ""; número ruim = padrão |
| `permanent` | `nodes` (já existe) | aceita `cat_rooftop`, `cat_watch`, `cat_thanks` | nó `cat_*` com a lenda abaixo da trava: **fica** (já foi pago) e vale; a lenda nunca cai, então só acontece em save sujo, com aviso |
| marco | `black_cat_rumor_heard` (já existe, 7a2) | `{campaign: n}` | sem `campaign` = a Ronda abre já |
- `open_campaign` é gravado quando a Ronda abre pela 1ª vez (`C + 1`), para não depender do marco depois.
- A cópia do save do dono abre sem erro (ele tem ou não o marco; em qualquer caso os campos novos são opcionais).
- Save sujo (tipos trocados, negativos, gigantes, `open` = "fight", lenda texto): carrega com os padrões acima e aviso.

## 12. Contrato de dados e API
### 12.1 `data/ronda.json` (gravado; arquivo ausente = jogo da 8a2)
| Bloco | Campos |
|---|---|
| `opening` | `requires_milestone` "black_cat_rumor_heard", `campaigns_after_rumor` 1, `min_campaign` 3 |
| `hood` | `first_after_s` 180, `interval_s` 240, `spot_by_location` {garage: `hood_spot`, gym: `gym_hood_spot`, center: `center_hood_spot`}, `hover_text` "hood_hover", `night_choice` "first_available" |
| `night_order` | `["scare"]` |
| `nights.scare` | `id`, `kind` "stealth_scare", `name`, `tip` (chaves de texto), `requires` {}, `countdown_s`, `night_s`, `intro_s`, `advance_per_s`, `scare_zone`, `grace_s`, `scare_anim_s`, `seen_anim_s`, `occurrences[]` {`id`, `spot`, `gap_min`, `gap_max`, `warn_s`, `look_s`, `fake_warn`}, `legend` {`floor`, `per_scare`, `clean_bonus`} |
| `legend` | `levels` [1, 12, 30, 52, 80], `clipping_text_by_level` (6 chaves), `street_layers_by_level` (6 listas) |
| `skill_tree` | `region` + `nodes[]` (mesmo formato do `skill_tree.json`, como o `center.json`); entram depois dos nós de hoje e dos do centro |
Validação (`RondaData`, `scripts/ronda_data.gd`): números fora da faixa voltam ao padrão com aviso; `gap_min > gap_max` troca;
`fake_warn` em 0–1; `levels` crescente; tipo de noite sem `kind` conhecido sai com aviso.

### 12.2 Efeito novo da árvore (`FightData.TIPOS_EFEITO` += 1)
| Tipo | Onde entra | Conta |
|---|---|---|
| `league_prep_days_bonus` | `calendario.gd` (dias de preparo do adversário) | `prep_days + prep_days_bonus + (league_prep_days_bonus se o adversário tem league)` |
| `start_generator` (já existe) | idem | `max(atual, valor)` (já é assim) |

### 12.3 Estado e API (módulo novo `scripts/estado/ronda.gd`, var `_ronda`; lógica pura `scripts/minigame_ronda.gd`, `RondaLogica`)
| Função (repasse em GameState) | Devolve |
|---|---|
| `ronda_aberta()` | a Ronda existe para a linhagem nesta campanha (§2) |
| `capuz_visivel()` | `""` ou o id da noite no prego (e clicável agora) |
| `capuz_info()` | `{night, spot [x, y], hover_text, clickable}` ou `{}` |
| `ronda_ir()` | `{night, kind, tip, countdown_s, night_s, level, legend, layers, occurrences: [id...]}`; põe `ronda_ativa` |
| `ronda_jogo()` | a lógica (`RondaLogica`) |
| `ronda_concluir()` | aplica e salva; `{night, scares, seen, done, legend_gain, legend, level_before, level, level_up, clean, left, scares_total, clipping_text}` |
| `ronda_voltar()` | devolve a sala |
| `lenda()` | `{legend, level, next_level_at, max_level, scares, rounds}` |
| `recorte_gato_preto()` (já existe) | `object_text` passa a ser o do nível da lenda (`clipping_text_by_level`) |
| `arvore.trava_aberta("black_cat:N")` | nível da lenda ≥ N |
| `estado_mapa(id)` | ganha `"sealed"` só para nós `black_cat:N` lacrados (§7.1) |
| sinais | `capuz_mudou(night)`, `ronda_mudou(estado)`, `lenda_mudou(level)` |

`RondaLogica`: `_init(cfg, rng, ciclos = [])`, `passo(dt, segurando, apertou)` (o `tick` chama; os testes também), `apertar()` /
`soltar()` (a UI chama; guardam o botão para o próximo `passo`), `estado()` → `{fase "contagem"|"jogando"|"fim", contagem, restante,
ocorrencia (0–2), id, oc_fase "intro"|"jogando"|"susto"|"visto", distancia 0–1, perto, ladrao "trabalha"|"aviso"|"olhando",
ladrao_frac, sustos, vistos, segurando}`, `pegar_eventos()` (`aviso`, `aviso_falso`, `olhou`, `susto`, `visto`, `proxima`, `fim`,
`fim_tempo`), `resultado()` → `{sustos, vistos, feitas, lenda}`. Ordem dentro do `passo`: ladrão anda → apertar perto (SUSTO ou
VISTO) → segurar anda e checa VISTO (o mesmo de `ronda_sim.py`, classe `Ronda`).

### 12.4 Chaves de texto (Roteirista; `ui_texts.json`)
`hood_hover`, `night_scare_name`, `night_scare_tip` (a linha de instrução), `scare_banner` (SUSTO!), `seen_banner` (ESCAPOU),
`near_hint` (PERTO), `ronda_reward_title`, `ronda_reward_legend` (+{n} LENDA), `ronda_reward_clean` (RONDA LIMPA), `ronda_level_up`
(A LENDA CRESCEU), `ronda_count` (OCORRÊNCIAS: {n}), `legend_label` (LENDA), `black_cat_clipping_1..5`, nomes das 3 ocorrências,
`region_black_cat`, nomes/descrições/`effect_text` dos 3 nós, `node_sealed` (PRECISA DA LENDA NÍVEL {n}). Regra: o nome GATO PRETO
só aparece com nível ≥ 1 (o hover do capuz e a instrução não dizem o nome).

### 12.5 Casos exatos (`tests/data/ronda_casos.json`, gerado por `ronda_sim.py exportar`)
`minigame` (6 roteiros com ciclos fixos e dt = 1/16: parado, segura sempre, estátua perfeita, SUSTO no aviso, SUSTO olhando,
mexer na tolerância → sustos, vistos, lenda, eventos), `lenda_da_ronda[0..3]`, `nivel[0..80]`, `rondas[sala_s]`, `nos`.

## 13. Quem faz o quê
### Programador
1. `RondaData` + `data/ronda.json`; módulo `scripts/estado/ronda.gd` com repasses no `game_state.gd`; `RondaLogica`
   (`scripts/minigame_ronda.gd`), sem tela; `docs/codigo/mapa.md` atualizado.
2. Abertura (§2), capuz e relógio (§3), estado `ronda_ativa` que congela o `tick` (§6.1), IR/concluir/voltar com gravação única (§6.2),
   `_rng_ronda` (§6.3), `_zerar_carreira` (§6.4).
3. Lenda e níveis (§5), `recorte_gato_preto()` pelo nível; região e nós do `ronda.json` na árvore (`FightData`, como o `center.json`),
   travas `black_cat:N`, estado `"sealed"`; os 2 efeitos novos (§12.2).
4. Save §11 (v13), `foto.gd` apagando os 2 campos novos.
5. Testes (APPDATA temporário, `--position 1950,40`, um Godot por vez): (a) foto igual à main; (b) o teste roteirizado do §9 (ir em
   todas = não ir, sem comprar nó); (c) casos exatos do `ronda_casos.json`; (d) o capuz nunca aparece em janela/luta/cena/fala/dia da
   luta, nunca acumula e nunca abre sozinho; (e) fechar no meio da Ronda (save antes do concluir) não ganha nem perde; (f) a 1ª
   carreira e quem não tem o marco nunca veem o capuz; (g) `cat_watch` muda só a data das lutas da liga; `cat_rooftop` dá 2 Tios só
   no começo; (h) saves sujos do §11; (i) `ronda_sim.py` e o jogo dão o mesmo nível para lenda 0–80.
### UI/UX
Tela da Ronda (moldura + área de jogo do `kind`, HUD da LENDA, barra de distância, sinal PERTO, contagem com a instrução, SAIR),
juice do SUSTO (§4.5) e do ESCAPOU, tela de prêmio (com e sem subida de nível, recorte grande, OCORRÊNCIAS), hover do capuz,
região GATO PRETO e o nó lacrado no mapa. `alinhamento-ui` com **0 problemas** nos estados do critério 12 do escopo.
### Roteirista
As chaves do §12.4: as 5 manchetes (subindo para o absurdo, sempre a partir de algo pequeno e verdadeiro: o estepe, a bicicleta, o
portão), a linha de instrução, os letreiros, o hover do capuz, os textos do prêmio e os 3 nós (nomes que soem como o bairro
agradecendo, não como superpoder). Busca por batman/morcego/gotham sem resultado.
### Diretor de Arte
Cenário da Ronda (rua da borracharia à noite, vista do muro, 3 pontos de ocorrência; **mockup antes**), camadas da lenda
(`graffiti`, `banner`, `kid_ears`, `whole_street`), 5 recortes novos (parede pequeno + hover grande; o grande é o 1º a sair), o
capuz no prego nos 3 locais (pontos conferidos com equipe máxima), ícone da LENDA, HUD da tela, ícone `region_black_cat` e os 3
ícones dos nós (podem reaproveitar desenhos de hoje com uma orelha de gato). A silhueta do recorte de hoje (7×8 px) é ajustada à
folha nova do vulto.
### Artista de Personagens (skill `padrao-personagem`)
**Regra do dono:** o corpo pode ser diferente, até na proporção, mas com o **acabamento e o estilo do jogo** (sombreamento, encaixes,
paleta, leitura em 1x), com capricho.
1. **Primeiro a amostra do vulto**, para o dono aprovar: 1 folha com 1 pose (espreitar parado) e 1 animação (avançar agachado),
   vestida no discípulo da vez. Traje original: capuz com orelhas largas e baixas, faixa da escola nos olhos com as pontas voando,
   capa de lona caindo reta (nunca aberta em asa), sem símbolo no peito e sem cinto de utilidades.
2. Aprovada a amostra: o resto do vulto (congelar, SUSTO com o salto e a capa, pose no telhado com a lua), provado em 3 discípulos
   de corpos e cabelos diferentes.
3. Os ladrões (trabalhar de costas, AVISO, olhar, cair de bunda e fugir; 2–3 paletas e cabeças). Ladrão de corpo diferente (o
   magrelo comprido, o baixinho largo) também passa por amostra.
Top 3 do dono: SUSTO, ladrão caindo, pose no telhado. Ordem de corte do escopo §9 (as camadas viram recortes, 1 ladrão com paletas,
a pose no telhado vira quadro parado). Não se corta: o traje, o AVISO do ladrão e o SUSTO com juice.
### QA
Critérios 1–12 do escopo, com o critério 2 lido como "a mesma foto até a compra do 1º nó" (decisão do dono). Referências: §4.4,
§5.3, §8 e §9. Rodar `ronda_sim.py tudo`.

## 14. Decisões do Designer (revisar com o dono)
| # | Decisão | Por quê | Alternativa |
|---|---|---|---|
| D1 | A lenda de cada ronda é 1 + SUSTOS + 1 se fez os 3 (1 a 5) | lê fácil, só ir já dá 1, e quem joga bem anda ~4× mais rápido que quem só vai | lenda por tempo escondido |
| D2 | Níveis em 1 / 12 / 30 / 52 / 80 | o nome GATO PRETO sai na 1ª ronda; o 5 chega na 2ª–3ª campanha de Ronda | níveis mais caros (a região demoraria mais) |
| D3 | Capuz aos 180 s e a cada 240 s depois da volta, sem precisar do Osmar | ~1 a cada 4 min, sempre 2 min longe do convite; o capuz é do discípulo, não do Osmar | o mesmo relógio do convite |
| D4 | A Ronda não fica mais difícil com a lenda | é passeio; o que cresce é a história | dificuldade por nível |
| D5 | Região com 3 nós (18.000), cada um preso a um nível (1, 3, 5) | a Ronda tem motivo até o nível 5, e o custo começa acima da árvore de antes (nunca disputa o essencial) | todos no nível 1 |
| D6 | Ajudas: 2 Tios no começo, +2 dias só na liga, equipe +40% | duas tiram espera (começo da campanha e calendário da liga) e uma é um bônus pequeno de equipe, para a ajuda chegar até o James; nada mexe na luta | começar com dinheiro (testei: $250 já pula a Muralha 26% mais cedo, é forte demais e aos saltos) |
| D7 | Nó `black_cat:N` lacrado fica à vista com "PRECISA DA LENDA NÍVEL N" | mostra o que a Ronda abre; só vale para essa região | esconder como os outros |
| D8 | IR não grava; o fim/SAIR grava tudo numa vez | fechar no meio = nada aconteceu (o jogo estava congelado) | gravar o capuz consumido no IR (aí fechar no meio perderia a ronda) |
| D9 | O capuz continua depois do James e no centro | não há luta para atrapalhar e o centro também é do bairro | só até o James |

## 15. Perguntas ao dono
**P1. Quem nunca joga a Panfletagem nunca vê a Ronda.** O capuz só abre depois do boato do Osmar, que só sai dentro da Panfletagem
(decisão aprovada). Quem ignora os convites do Osmar nunca descobre o Gato Preto nem a região. **Recomendo** manter a regra e
acrescentar uma rede: se até o fim da campanha 4 o boato não saiu, o capuz aparece mesmo assim a partir da campanha 5 (o recorte
já está na parede desde a 2). Não muda nada para quem não clica, e a foto continua igual (o robô da foto nunca clica no capuz).

**P2. O tamanho do "temperinho".** A região escolhida é: **2 Tios no começo da campanha, +2 dias de preparo nas lutas da liga e a
equipe +40%**. Medido: o James chega **~3% antes** (1% a 6%), o Kid até 7,5% antes, e o pior trecho (a Muralha) fica em 9,6%, logo
abaixo do teto de 10%. **Recomendo** este tamanho. Se o dono quiser mais leve: a equipe **+25%** dá o James ~2,5% antes e a
Muralha no máximo 8,8%.
Detalhe que o dono deve saber: o ganho só aparece depois que o GATO PRETO **e** o CENTRO estão fechados (campanha ~9–10). Antes, os
dois disputam o mesmo Legado e se compensam. Se o dono quiser que a ajuda chegue mais cedo, a saída é baratear a região (ex.: 1.500 /
3.000 / 5.000), e aí ela passa a competir com o fim da árvore de antes; **não recomendo**.

## Resumo
- **Ronda:** capuz no prego da campanha seguinte ao boato em diante (1º aos 6 dias de sala, depois a cada 8 dias, sem acumular, não
  some). Clicou: ~30 s de "Estátua no telhado" (segura para andar, solta quando o ladrão olha, clica perto para o SUSTO), 3 ocorrências,
  falha leve, SAIR a qualquer hora. O jogo congela: ir não custa nem rende dia, treino ou dinheiro. Medido: 23–32 s; até o jogador
  distraído faz 1 SUSTO em 94% das rondas.
- **LENDA:** 1 por ir + 1 por SUSTO + 1 com os 3 (1 a 5 por ronda); níveis 1 / 12 / 30 / 52 / 80; o nome GATO PRETO na 1ª ronda e
  o nível 5 na 2ª–3ª campanha de Ronda. Muda o recorte nos 3 locais e as camadas da rua.
- **Região GATO PRETO (18.000 de Legado):** Atalho pelos telhados (nível 1, 3.000: começa com 2 Tios), O bairro de olho (nível 3, 6.000:
  +2 dias nas lutas da liga), O bairro agradece (nível 5, 9.000: equipe +40%). Valores fixos, nada na chance de luta, só um tipo de
  efeito novo (`league_prep_days_bonus`). Ganho: James ~3% antes, Kid até 7,5%, pior trecho 9,6%. Junto com o CENTRO, dá destino a
  ~40 mil de Legado.
- **Sem quebrar:** quem não joga tem o jogo da 8a2; quem joga tem o mesmo jogo até a compra do 1º nó. Save v13 só com
  `permanent.black_cat` e `career.black_cat_hood` opcionais. O capuz carrega um tipo de noite (`nights` no `ronda.json`), pronto para
  a futura luta contra bandidos.

## Decisões do dono (2026-11-23)
"sim aprovo" — as duas perguntas seguem a recomendação do Designer:
1. Rede de segurança: se o boato não saiu até a campanha 4, o capuz aparece a partir da campanha 5.
2. Tamanho da ajuda da região GATO PRETO: 2 Tios, +2 dias de preparo na liga, equipe +40%.
