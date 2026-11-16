# Fase 6c — Um lugar nosso: escopo

Dono: Diretor de Jogo. Data: 2026-11-15. Branch `fase-6c` (sobre a main, com a 6b fechada).
Li: `PROMPT.md`, `docs/roadmap.md` (6c), `docs/visao.md` (decisões de 2026-11-11), `docs/direcao-narrativa.md` (manda), `docs/cutscenes/ideia-do-dono.md`, `cenas-curtas.md` (§1 e §2), `formato-dados.md`, `docs/narrativa.md`, `fase6a-revisao.md` (B1), `fase6b-escopo.md`, `fase6b1-design.md` (§3.4, `school.roster`), `fase6b1-api.md`, `fase6b2-revisao.md` (§5, "fica para a 6c") e `data/career.json`, `data/dialogos.json`.
O dono disse que o feedback agora vem dos testadores. Decidi o que é decisão de jogo. Para o dono ficam só os pontos que mudam a história dele (§10), cada um com uma recomendação. Nenhum deles trava o começo.

## 1. Objetivo e sensação
- A escola ganha **casa nova** (a academia, com a foto antiga torta na parede), o John **segue o caminho dele** sem drama, e a escola passa a **lembrar de quem passou por ela** (mural, Honra, mentores que comentam recordes).
- Sensação: *"esse lugar agora é nosso; o John foi viver a vida dele; cada lutador que eu formei ficou na parede, e quem saiu por cima deixou alguma coisa pra escola"*.
- É o fim do Arco 2 e o começo do Arco 3 ("Mais longe que eu").

## 2. A divisão
A 6c tem duas metades de natureza diferente: uma de **cena e arte** (academia, saída do John) e uma de **economia e tela** (Honra, mural, árvore do hall). Juntas são grandes demais para uma entrega só. Divido como a 6b:

| Parte | Nome | O que o testador joga no fim dela |
|---|---|---|
| **6c1** | Casa nova | A cena da 1ª chegada à academia, o Osmar e os mentores na academia, a `cl_primeira_academia`, os comentários da arte e a **saída discreta do John**, com o último que passou o posto indo para o caixote. |
| **6c2** | Mais longe que eu | O **mural da escola** com um retrato por lutador, a **Honra** (só ao sair por vontade), a **árvore do hall**, o bônus pequeno do retrato de quem saiu, as **falas dos mentores** (recorde e revanche) e o **símbolo da escola** no peito. |

Por que essa ordem:
- A 6c1 não mexe em número nenhum. Fecha o Arco 2 e testa a saída do John antes de o mural existir.
- A 6c2 concentra toda a economia nova num lugar só, com a simulação de balanço focada nela.
- O mural da 6c2 já mostra o John como "foi seguir o rumo dele", porque a saída existe desde a 6c1.
- Os testadores jogam a 6c1 antes de a 6c2 começar.

## 3. Decisões do Diretor
1. **Cena da academia = `cenas-curtas.md` §1**, ≈ 13 s presos, máximo 15 s. Toca **uma vez na vida do save**, na 1ª chegada da escola à Academia Boa Esquina (qualquer lutador, inclusive o John na Carreira 1), depois da mudança e **antes** da escolha da arte. Save que já esteve na academia: toca na **próxima** chegada.
2. **Quem carrega a caixa na cena:** o mentor que está no caixote (o John, se ainda estiver; senão o último que passou o posto); sem mentor (Carreira 1), um vizinho da equipe. O Diretor de Cutscenes resolve isso com `versions` ou atores condicionais, sem segunda cena.
3. **A foto antiga acompanha a escola:** fica na parede do local onde o discípulo está treinando (garagem ou academia). A garagem não fica "abandonada" (`direcao-narrativa.md` §4.2).
4. **`cl_primeira_academia`** ("a garagem vai junto, / mesmo sem a lâmpada.") toca **na academia**, no 1º momento calmo depois da cena e da escolha da arte. A trava `location: garage` sai dessa fala. As `cl_academia_volta_*` continuam esperando por ela.
5. **Osmar na academia** (6c1): passa a aparecer e falar lá, num ponto próprio. As falas que só fazem sentido na garagem (lâmpada, aviso) continuam presas à garagem. O Designer marca fala por fala.
6. **Comentários da arte** (`cl_arte_*`, hoje desligados) entram na 6c1: o Osmar comenta a arte escolhida sem tratar nenhuma como "a certa".
7. **Mentores na academia seguem a regra do dono da garagem:** enquanto o John estiver, o John e o último que passou o posto; depois, só o último. Dois pontos novos na academia (`gym_mentor_spot` e `gym_mentor_2_spot`), com as mesmas regras de folga da garagem. Os toques do John valem nos dois lugares.
8. **Gatilho da saída do John (decisão minha, confirmada pelo dono em §10):** dispara no **1º momento calmo na sala depois da 1ª vitória de um discípulo (Carreira 2 em diante) na academia**. Reserva: **início da Carreira 4**, se isso vier antes. O que vier primeiro. Assim:
   - funciona com Carreira 1 curta (o John já é mentor desde a Carreira 2);
   - não exige perder de propósito, nem vencer rápido;
   - não cai em cima da cena da academia nem da escolha da arte.
9. **A saída é ação no cenário** (`cenas-curtas.md` §2, ≈ 12 s): jogador no controle o tempo todo, sem barras, sem câmera 2x, sem gesto, balões passivos. Falas `saida_rumo` ("Vou procurar meu rumo. Cuidem bem disso aqui.") e `saida_resposta` (Osmar: "Vê se manda notícia."). Se o jogador abrir janela, luta ou trocar de local no meio, termina na hora com o John já fora. Marco `cena_saida_primeiro_mentor` gravado no começo.
10. **Depois da saída:** o último que passou o posto **anda até o caixote e senta** (fim da ação, ≈ 2 s). O `mentor_2_spot` esvazia. Na Carreira 2, se o John sair, o caixote fica vazio até o fim da campanha (o próximo mentor senta lá). O John não aparece mais em sala nenhuma, e nenhum objeto dele fica para trás.
11. **Honra (6c2), o papel dela:** é a recompensa por **sair por cima com algo conquistado**. Não substitui o Legado nem compete com ele.
    - Vem **só da saída por vontade**, inclusive passar o posto no dia da luta (`fase5.3-escopo.md`).
    - Cresce com o que a campanha conquistou (vitórias, cinturão). **Sair com 0 vitórias dá 0 de Honra**, para não virar fazenda de "sair no primeiro dia".
    - Gasta-se **só na árvore do hall**. Nunca compra nó de Legado, nem o contrário.
    - Aparece na tela de fim e no mural. **Não vai para o HUD da sala**, que continua limpa.
12. **Bônus do retrato:** cada retrato de quem saiu por vontade ganha um selo e dá um **bônus pequeno e permanente, com teto** (a quantidade de retratos que conta tem limite). Derrota entra no mural igual, com retrato e recorde, sem selo e sem bônus. Nunca humilha: o texto diz quem venceu ele, como recorde, não como vergonha.
13. **Árvore do hall: pequena e fechada.** 5 a 6 nós numa lista fixa dentro da janela do mural, sem mapa nem névoa. Compra só **entre campanhas**, como a árvore de Legado (decisão da Fase 4). O mural em si abre **a qualquer hora**, na sala, para consulta.
14. **Tipos de nó permitidos:** conforto (ex.: caixa de aparelho com menos cliques, prévia mais detalhada), começo de campanha (ex.: um pouco de Treino inicial) e números pequenos com teto. **Proibido:** qualquer coisa que torne a derrota melhor que a saída, efeito direto forte na luta, ou moeda nova dentro da moeda nova.
15. **Mural é um objeto na parede** (garagem e academia, junto da foto), clicável, que abre a janela "MURAL DA ESCOLA". Um retrato por entrada de `school.roster`, em ordem, com o John primeiro. Os retratos são gerados das camadas da cabeça do discípulo (o mesmo `look`), sem desenho novo por lutador.
16. **Falas dos mentores (6c2)**, faladas por quem está no caixote (o John enquanto estiver, depois o último):
    - **recorde:** o discípulo passa o melhor `wins` da escola ("Daqui pra frente, você vai ter que contar pra gente como é.");
    - **revanche:** o discípulo vence o `opponent` que derrubou um mentor da lista;
    - **mais longe que eu:** o discípulo passa o `wins` do mentor que está na sala.
    Cada uma toca **uma vez por campanha**, no máximo, e sempre pelo dado real (`roster`). Com o espaçamento das falas do Osmar.
17. **Voz dos mentores:** um timbre de mentor com variação por lutador (dados), original. O John mantém o dele.
18. **Símbolo da escola (6c2):** aparece no discípulo **depois que a escola ganha o 1º cinturão amador** (a ficha já diz "RAÍZES FIGHT CLUB" desde a 6a). Vai no peito liso da parte de cima. Sem parte de cima, vai na perna do calção (o Diretor de Arte confirma o lugar). O John **nunca** usa: as folhas dele não mudam, e isso prepara o "ele olha o símbolo no discípulo" do reencontro (fase 11).
19. **Pose própria do 2º mentor:** só entra (6c1) se os testadores da 6b2 não o distinguirem da equipe (pergunta 4 da `fase6b2-revisao.md`). O Produtor confirma antes do design. Depois da saída do John o problema some sozinho, porque ele senta no caixote.
20. **Ordem na chegada à academia** (uma fila só): vitória → mudança → cena da academia → escolha da arte (se pendente) → `cl_primeira_academia` no 1º momento calmo. O relógio da campanha **não anda** durante a cena.

## 4. O que entra

### 4.1 Cena "Primeira chegada à academia" (6c1)
- `data/cutscenes/primeira_academia.json`, no player da 6b1, só com passos da vista `room` que já existem. Se precisar de passo novo (ex.: `light` para o tubo acender), o player passa a executá-lo. O formato não muda.
- Palco: `gym_bg` vazio, um tubo aceso e um apagado, porta da rua.
- Quadros 1–4 de `cenas-curtas.md` §1: a equipe entra com saco remendado e caixa; o ajudante bate a esteira na porta (2x) e passa de lado no fim; corte 2x na parede; o Osmar pendura a foto, recua e **entorta** a foto; "Agora sim." (`acad_agora_sim`); o tubo acende e a interface volta.
- **Pular:** academia montada, foto na parede, escolha da arte aberta, em ≤ 0,3 s.
- **Chegadas seguintes:** sem cena, como hoje.

### 4.2 Osmar, mentores e foto na academia (6c1)
- Pontos novos no manifest: `gym_coach_spot`, `gym_mentor_spot` (caixote ou banco da academia), `gym_mentor_2_spot`, `gym_photo_spot` e, na 6c2, `mural_spot` na garagem e na academia.
- Regras de folga iguais às da garagem: fora da faixa do alvo, da `no_cover`, do caminho da porta e dos pontos da equipe. O balão não cobre cabeça.

### 4.3 Saída do John (6c1)
- `data/cutscenes/saida_primeiro_mentor.json`, só passos passivos (`move`, `pose`, `say` passivo, `sound`, `prop`), sem `ui hide`, sem `camera`, `max_seconds` sem prender (0 s presos).
- Garagem: ele passa por baixo da porta de enrolar, como sempre. Academia: sai pela porta da rua.
- `grants: mentor_leaves` (já previsto na 6b1). O último que passou o posto vai para o caixote (§3, item 10).

### 4.4 Falas (6c1)
- `cl_primeira_academia` destravada na academia, `cl_arte_*` ligadas e uma seleção das falas do Osmar para a academia.
- `saida_rumo` e `saida_resposta`.

### 4.5 Mural da escola (6c2)
- Objeto na parede, com hover e clique (o padrão da ficha da 6a). A janela fica no meio, com os retratos em fileiras iguais e rolagem quando passar de uma página.
- Cada retrato mostra: nome, campanha, arte, recorde (`wins`, cinturão) e como terminou ("saiu por cima" com selo e Honra / "parou em <adversário>").
- O John aparece primeiro, com o retrato dele. Depois da saída, com a linha "foi seguir o rumo dele".
- O mesmo botão MURAL fica na tela de fim de campanha, ao lado da ÁRVORE, porque é lá que se compra o hall.

### 4.6 Honra e árvore do hall (6c2)
- Honra ganha na saída por vontade, mostrada na tela de fim (+N HONRA) e no retrato. Fórmula e números do Designer em `data/`.
- Árvore do hall com 5–6 nós (§3, itens 13–14), preços em Honra, sem reembolso.
- Bônus do retrato com teto (§3, item 12).

### 4.7 Falas dos mentores (6c2)
- Recorde, revanche e "mais longe que eu" (§3, item 16). O Roteirista escreve 2–3 variações de cada uma. Balão passivo preso ao mentor do caixote.

### 4.8 Símbolo da escola (6c2)
- Desenho do símbolo, original (Diretor de Arte), em 3/4 e perfil, como camada nova aplicada pelo gerador em **todas** as poses do discípulo (garagem, luta, cena, mentor sentado e retrato do mural).
- Gatilho: o marco do 1º cinturão amador da escola.

### 4.9 Save
- **6c1:** os marcos novos (`cena_primeira_academia`, `cena_saida_primeiro_mentor`) entram no formato v12, **sem migração**, se couberem. O Designer confirma. Se não couberem, a migração vai para a v13 já na 6c1.
- **6c2: v12 → v13**, com Honra, nós do hall e campos do mural. **Honra retroativa:** cada entrada do `roster` com `end == "retire"` recebe a Honra pela mesma fórmula (`wins`, `belt`). `wins == -1` (desconhecido) recebe o mínimo de uma saída com 1 vitória. Nada mais muda.

## 5. O que fica de fora
| Item | Fase |
|---|---|
| Lutas diferentes por arte, passivas de luta, arena da academia | 7a |
| Muay Thai | 7b |
| Rival James Blindado em jogo (aparição, falas, luta) | 8a |
| Centro de treinamento e regiões novas da árvore | 8a |
| Vinhetas de adversário (ciborgue, urso, veterano) | 10 |
| Reencontro final, vitória final, foto dos dois no mural | 11 |
| Notícia ou carta do John durante a ausência (nenhuma pista dele) | — (a direção pede que ele não domine a história ausente) |
| Botão "igual ao anterior" na criação | 6c2, só se os testadores da 6b2 acharem a criação cansativa |
| Mais cortes e roupas, tipo de corpo, esparadrapo, opção de desligar blips | 13, se pedirem |
| Progresso offline | 13 |
| Qualquer mudança de Legado, preço, luta, calendário ou árvore de Legado | — |

## 6. Critérios de aceite

### 6c1 — Casa nova
1. **Cena da academia:** na 1ª chegada da escola à academia, a cena toca com ≤ 15 s presos (validador), a foto termina torta na parede e a escolha da arte abre logo depois, se estiver pendente.
2. **Pular:** segurar ESC/ESPAÇO 0,5 s ou clicar em PULAR deixa a academia montada, a foto na parede e a escolha da arte aberta em ≤ 0,3 s.
3. **Toca uma vez só:** o marco é gravado no começo, com salvamento imediato. Pular, perder, fechar o jogo no meio ou chegar de novo com outro discípulo não faz a cena tocar outra vez. Fechando no meio, ao abrir de novo a academia está montada (estado final).
4. **Elenco certo:** com o John jogando (Carreira 1), ele carrega o saco e um vizinho carrega a caixa. Com discípulo e o John mentor, o John carrega a caixa. Depois da saída, quem carrega é o último que passou o posto.
5. **Save antigo** (cópia de teste do save do dono, que já esteve na academia): a cena toca na próxima chegada e a `cl_primeira_academia` toca na academia uma vez.
6. **Osmar na academia:** aparece no ponto dele e fala só falas marcadas para a academia. Nenhum balão sem personagem embaixo.
7. **Mentores na academia:** a regra da garagem vale igual. Com o John: o John e, da Carreira 3 em diante, o último. Depois da saída, só o último, no caixote.
8. **Saída do John:** dispara no 1º momento calmo depois da 1ª vitória de um discípulo na academia, ou no início da Carreira 4, o que vier primeiro. O jogador clica durante a ação inteira e o 1º soco vale. Abrir janela, luta ou trocar de local no meio termina a ação com o John fora. A ação nunca toca duas vezes, nem com o jogo fechado no meio.
9. **Depois da saída:** o John não aparece em sala nenhuma. O último que passou o posto senta no caixote e o `mentor_2_spot` fica vazio. Na Carreira 2, o caixote fica vazio até a próxima sucessão. Ninguém mais faz os toques do John.
10. **Comentários da arte:** o Osmar comenta a arte escolhida, com o espaçamento das outras falas, sem chamar nenhuma de certa.
11. **Balanço inalterado:** a simulação da 6b2 dá os mesmos números. Nenhum segundo de campanha passa durante a cena da academia.

### 6c2 — Mais longe que eu
12. **Mural:** cada entrada de `school.roster` aparece com retrato (das camadas da cabeça), nome, arte, recorde e como terminou, com o John primeiro. Com 30 entradas, a janela rola sem cortar nada.
13. **Honra:** sair por vontade com ≥ 1 vitória dá Honra pela fórmula dos dados. Sair com 0 vitórias dá 0. Perder dá 0. Passar o posto no dia da luta conta como saída.
14. **Árvore do hall:** 5–6 nós, comprados com Honra só entre campanhas. Cada efeito aparece de forma visível na campanha seguinte. Honra e Legado nunca se misturam.
15. **Bônus do retrato:** só quem saiu por vontade dá o bônus, e o efeito para de crescer no teto dos dados.
16. **Falas dos mentores:** recorde, revanche e "mais longe que eu" tocam só quando o dado real acontece, no máximo uma vez cada por campanha, faladas pelo mentor do caixote. Sem mentor na sala, não tocam.
17. **Símbolo:** depois do 1º cinturão amador da escola, todo discípulo mostra o símbolo em todas as poses e no retrato. O John nunca mostra. Antes do cinturão, ninguém mostra.
18. **Save v12 → v13** (cópia de teste do save do dono): preserva Legado, árvore, atributos, calendário, marcos e `roster`. A Honra retroativa sai pela regra da §4.9 e nenhum outro número muda.

### As duas partes
19. **Balanço da 6c2** (medido pelo Designer, §7): com Honra 0, a simulação da 6b2 dá os mesmos números. Com a árvore do hall cheia e o retrato no teto, as metas da visão continuam valendo (1ª carreira 10–15 min e cinturão amador entre a 2ª e a 4ª carreira), e o tempo morto continua ≤ 10 min.
20. **`ui_audit` com 0 problemas** (skill `alinhamento-ui`), incluindo:
    - Osmar e os dois mentores na academia com balão;
    - a saída do John em cada quadro, na garagem e na academia;
    - o mural vazio (só o John), com 1, com 8 e com 30 retratos;
    - a árvore do hall (nada, metade e tudo comprado);
    - "+N HONRA" na tela de fim;
    - discípulo com símbolo, com e sem parte de cima.
21. **Testes passando:** `run_tests` verde, testes novos com **save de teste**, validador sem erro em todo `data/cutscenes/` e janelas de teste com `--position 1950,40`.

## 7. Honra: o que o Designer precisa medir
- **Honra por campanha em 3 jeitos de jogar:**
  - sair depois da 1ª vitória;
  - sair com o cinturão;
  - ir até perder.
  Sair cedo **não pode** render mais Honra por minuto do que ir longe.
- **Quantas saídas compram a árvore do hall inteira.** Proposta: 10 ± 3 saídas com conquista. Menos que isso a árvore some rápido demais; mais vira obrigação.
- **Peso do hall frente ao Legado:** o efeito somado do hall cheio com o retrato no teto fica **≤ 10%** do efeito da árvore de Legado no mesmo ponto do jogo. O Designer mostra a conta.
- **Metas da visão com o hall vazio e com o hall cheio:** a 1ª carreira não muda (Honra começa em 0), e o cinturão amador continua entre a 2ª e a 4ª carreira.
- **Sair continua melhor que perder, mas não dominante:** comparar Legado + Honra de "sair no dia da 2ª luta" contra "lutar e vencer a 2ª luta".
- Entregar em `docs/fases/fase6c-design.md` (seção da 6c2), com a simulação em `tools/sim`.

## 8. Riscos
- **Cena da academia longa demais na hora mais esperada** (o jogador quer ver a academia e escolher a arte). Proteção: ≤ 15 s, pulável e uma vez na vida do save. **Ordem de corte:** (1) o ajudante com a esteira vira só uma batida, (2) o segundo tubo acende sem piscar. **Não se corta:** a foto torta e "Agora sim."
- **A saída do John passar despercebida** (o jogador está clicando). É o efeito desejado, mas ele precisa notar *depois*. Proteção: o caixote vazio ou ocupado por outro, e a linha "foi seguir o rumo dele" no mural da 6c2. Se os testadores não perceberem, o ajuste é o Osmar comentar uma vez na próxima volta à garagem, e não deixar a saída mais dramática.
- **Honra virar a moeda que importa.** Proteção: §3, itens 11–14, o teto do §7 e a compra só entre campanhas.
- **Sala da academia lotada** (Osmar, equipe, dois mentores, foto, mural). Proteção: o mockup de conferência do Diretor de Arte e os pontos fora das zonas proibidas, como na 6b2.
- **Retrato do mural ilegível** em tamanho pequeno. Proteção: o retrato usa a cabeça em 2x, e o Diretor de Arte confere com os 4 cortes e a faixa.
- **6c1 com arte demais** (Osmar pendurando a foto, poses de carregar, academia vazia, mentor sentado com camadas). Se apertar, a pose própria do 2º mentor (§3, item 19) é a primeira a sair.

## 9. Papéis
| Papel | 6c1 | 6c2 |
|---|---|---|
| **Diretor de Cutscenes** (Fable) | Storyboard quadro a quadro e `primeira_academia.json` pela `cenas-curtas.md` §1, com o elenco por estado (§3, item 2). `saida_primeiro_mentor.json` (passivo) na garagem e na academia. Confere pela captura | Confere o John no mural ("foi seguir o rumo dele") e que nenhuma fala de mentor tenha cara de cena |
| **Artista de Personagens** | Osmar: `hang_photo`, passo atrás e ajeitar a foto, parado na academia. Carregar saco e caixa (John, discípulo com camadas e vizinho). Ajudante com a esteira atravessada. John: bolsa, andar, olhar a sala, aceno de cabeça. Discípulo mentor `sit_rest` com todas as camadas. Pose própria do 2º mentor, só se os testadores pedirem. Tudo pela `padrao-personagem` | Camada do símbolo em todas as poses. Retrato do mural gerado da camada da cabeça |
| **Diretor de Arte** | Academia vazia (tubo aceso e tubo apagado), foto torta, esteira velha, caixa e saco remendado como adereços, caixote ou banco na academia. Pontos `gym_*` no mockup com a sala cheia | Símbolo da escola (original, 2 propostas), lugar sem parte de cima. Objeto do mural nas duas paredes, moldura do retrato, selo de "saiu por cima" |
| **Roteirista** | Polir `acad_agora_sim`, `saida_rumo`, `saida_resposta`. Falas do Osmar para a academia e `cl_arte_*`. Arquivo `docs/fases/fase6c-textos.md` | Falas de recorde, revanche e "mais longe que eu" (2–3 cada). Textos do mural e do retrato ("saiu por cima", "parou em...", "foi seguir o rumo dele"). Nomes dos nós do hall. Rótulo "HONRA". **Alinhar `narrativa.md` só depois da resposta do dono (§10)** |
| **Designer** | Fila da chegada. Gatilho da saída nos dados. Quem carrega a caixa. Falas do Osmar por local. Marcos no save. Simulação de não-regressão. Arquivo `docs/fases/fase6c-design.md` | Fórmula da Honra, nós do hall, bônus do retrato e teto, regras das falas de mentor, Honra retroativa, migração v13 e as medidas do §7 |
| **Programador** | Cena da academia no player (e passo `light`, se a cena usar). Saída do John com `mentor_leaves` e troca para o caixote. Osmar e mentores na academia. Foto pelo local. Testes em save de teste. API `docs/fases/fase6c1-api.md` | Honra, árvore do hall, mural (dados), bônus do retrato, gatilhos das falas de mentor, camada do símbolo, save v13 com migração e testes. API `docs/fases/fase6c2-api.md` |
| **UI/UX** | Balões do Osmar e dos mentores na academia, PULAR na cena nova. `alinhamento-ui` com 0 problemas | Janela do MURAL (retratos, rolagem, lista do hall), "+N HONRA" na tela de fim, botão MURAL. `alinhamento-ui` com 0 problemas |
| **QA** | Critérios 1–11, 20, 21, com atenção a 3, 5, 8 e 9 | Critérios 12–21, com atenção a 13, 18 e 19 |

## 10. Perguntas para o dono
Nenhuma trava o começo. A equipe segue a recomendação até ele responder.
1. **Quando o John vai embora?** A direção narrativa deixa o gatilho em aberto. **Recomendo:** depois da 1ª vitória de um discípulo na academia, ou no começo da Carreira 4, o que vier primeiro. Fica longe da cena da academia e funciona para quem joga rápido ou devagar. Alternativa: na própria 1ª chegada de um discípulo à academia (mais simbólico, mas cai em cima da cena e da escolha da arte).
2. **O rival é o campeão mundial?** `docs/narrativa.md` (linha 38) diz que James Blindado "humilha no começo, é o chefe do título mundial". Mas a decisão dele de 2026-11-11 (`visao.md`, item 11, e `roadmap.md`, linhas 151 e 217) diz que o rival **deixa de ser** o chefe do mundial, termina em respeito, e que o campeão mundial é outro personagem. **Recomendo** corrigir a `narrativa.md` para: *"James Blindado entra na 8a, menospreza a escola, passa a se preparar contra ela e termina em respeito. O campeão mundial é outro personagem (fase 9)."* Ninguém edita até ele confirmar. Não afeta a 6c.

## 11. O que os testadores validam
**6c1:**
1. A cena da academia emociona ou atrasa a escolha da arte?
2. Viram a foto torta? Lembraram da garagem?
3. Perceberam que o John foi embora? Quando? Pareceu natural ou triste demais?
4. A academia ficou cheia demais com o Osmar e os mentores?

**6c2:**
5. Entenderam por que quem saiu por vontade tem selo e Honra e quem perdeu não tem?
6. A árvore do hall pareceu valer a pena ou "mais uma árvore"?
7. Reconheceram os seus lutadores no mural?
8. As falas de recorde e revanche apareceram na hora certa?

## Resumo para o Produtor
- A 6c foi dividida em duas partes jogáveis. A **6c1 (Casa nova)** traz a cena da academia com a foto torta, o Osmar e os mentores na academia e a saída discreta do John, com o último que passou o posto indo para o caixote. Não muda número nenhum.
- A **6c2 (Mais longe que eu)** traz o mural da escola, a Honra (só sair por vontade, com conquista), a árvore do hall pequena (5–6 nós), as falas de recorde e revanche dos mentores e o símbolo da escola no peito. Save v12→v13 com Honra retroativa.
- A Honra fica sob teto: o hall cheio vale no máximo 10% da árvore de Legado, e o Designer mede isso antes de implementar.
- **Duas perguntas para o dono, nenhuma trava:** quando o John vai embora (recomendo: depois da 1ª vitória de um discípulo na academia, ou no começo da Carreira 4) e a correção do rival na `narrativa.md` (recomendo alinhar à decisão dele: o rival não é o campeão mundial).
