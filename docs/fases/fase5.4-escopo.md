# Fase 5.4 — Árvore grande: escopo

Dono: Diretor de Jogo. Data: 2026-11-13. Branch `fase-5.4` (sobre 5.3, 5.2 e 5.1, ainda fora da `main`).
Li: `PROMPT.md`, `docs/visao.md`, `docs/roadmap.md` (5.4), `docs/propostas/feedback-2026-11-11.md` (itens 7 e 17 e as respostas do dono), as seções "fica para a 5.4" de `fase5-revisao.md`, `fase5.2-revisao.md` e `fase5.3-revisao.md`, `data/skill_tree.json` e `ui/janela_arvore.gd`.
**Status: aprovado pelo dono antes de ver o plano ("pode seguir").** Ele não pode testar agora. O que ele precisa validar quando jogar está na seção 7.

## 1. Objetivo e sensação
- Trocar as 3 abas (CORPO, CARREIRA, ESTILO) por **um mapa grande que vai se revelando** a cada compra. O mapa fica **escondido atrás de um botão** na sala e tem os 12 nós atuais no centro.
- Sensação: *"comprei um nó e apareceram mais três; sempre tem um pedacinho novo para comprar"*. Abrir a árvore precisa ser como espiar um mapa do tesouro, e fechar precisa ser rápido para voltar ao saco.
- Referência de **gênero** (não de visual): mapas grandes de nós baratos que revelam os vizinhos, com regiões que se ajudam. Moldura, ícones, nomes e formato são 100% nossos.

## 2. Decisões do Diretor (o que ficou em aberto no plano)
1. **A árvore abre a qualquer hora, também durante a campanha.** Pelo botão da sala e pela tela de fim de campanha. Não abre na luta, no dia da luta, na escolha da arte nem com a caixa no meio da abertura.
   - **Tudo o que se compra vale a partir da próxima campanha.** O cartão do nó diz isso. A regra é uma só, não deixa nada para explorar no meio da campanha e não mexe no 23b (1ª carreira sem árvore).
   - O relógio da campanha **para** com a árvore aberta (regra das janelas da 5.3).
2. **Como fica "escondida":** um botão pequeno no canto da sala, fora do alvo de clique. Ele **brilha** quando existe um nó à vista que o Legado já paga. Sem brilho, o botão fica quieto, para não puxar o olho do saco.
3. **Como o mapa se revela:**
   - **Comprado:** aceso.
   - **À vista:** vizinho de um comprado. Mostra nome, efeito e preço, e pode ser comprado.
   - **Escondido:** o resto não aparece. O nome de uma região aparece quando o 1º nó dela fica à vista.
   - Regiões com trava: a **Academia** só aparece depois que algum discípulo chegou à academia; as regiões de **Boxe** e **Jiu-jitsu** só aparecem com a arte liberada (como o ESTILO hoje).
4. **Navegação simples:** arrastar o mapa e usar a roda do mouse para rolar. **Sem zoom** nesta fase. Ao abrir, o mapa centraliza no último nó comprado (ou no centro, na 1ª vez).
5. **Migração de save:** os nós comprados mantêm o mesmo id e o mesmo efeito, e ficam no centro. Os vizinhos deles já abrem **à vista**. O Legado fica igual, sem reembolso e sem cobrança. Se o Designer mudar o preço de um nó (`style_bjj`, `body_crew_2`), quem já comprou continua com ele.
6. **"Clique com a equipe":** o Grito da equipe **continua na LOJA**, e a árvore ganha um nó que **reforça o Grito** (mais segundos de equipe por clique). O Designer define o número. Duas compras com o mesmo efeito confundiriam o jogador.
7. **Nome do ramo:** "CARREIRA" vira **"CAMPANHA"** (ou o equivalente que o Roteirista achar melhor). Os ids `career_*` **não mudam**, para não quebrar o save.

## 3. O que entra

### 3.1 O mapa
- **Cerca de 35 a 40 nós.** A maioria é pequena e barata (+% curto). Poucos nós grandes ("marcos") com efeito novo.
- **Centro = os 12 nós atuais**, com os mesmos ids e efeitos, agrupados em CORPO, CAMPANHA e ESTILO.
- **Regiões em volta** (sugestão de tamanho, o Designer fecha):
  - **Garagem** (~6): saco, corda, esteira, gente do bairro. Aqui fica o nó **"começa com a corda montada"**.
  - **Academia** (~5): aparelhos da academia, prêmios da liga, dinheiro.
  - **Boxe** (~4) e **Jiu-jitsu** (~4): um ramo curto por arte, saindo do nó de ESTILO dela.
  - **Campanha** (~4): Legado, prévia, dinheiro, e o nó **"+1 dia de preparo"**.
  - **Ligações** (~3–4): nós entre duas regiões que ajudam as duas (ex.: Garagem + Jiu-jitsu = equipe; Academia + Boxe = clique). O nó do **Grito** fica numa ligação.
- **Primeiro nó de cada região barato.** A 1ª derrota continua comprando pelo menos 1 nó.

### 3.2 Nós obrigatórios
| Nó | Efeito | Observação |
|---|---|---|
| **Corda montada** | A campanha começa com a corda já no lugar, sem caixa | Resposta do dono. O saco continua sendo o único aparelho fixo da garagem; a esteira continua chegando na caixa |
| **+1 dia de preparo** | Cada luta da campanha ganha +1 dia de folga | 1 nó só, longe do centro. O Designer mede o efeito nas datas |
| **Grito mais alto** | Reforça o Grito da equipe | Só vale se o Grito for comprado na LOJA. O cartão avisa |
| **12 atuais** | Iguais aos de hoje | Só os preços de `style_bjj` e `body_crew_2` (e outros, se precisar) podem mudar, para o balanço |

Ficam fora da árvore: "começar na academia" (retirado em 11/11) e qualquer nó de Honra, personalização ou segunda arte.

### 3.3 Balanço (Designer, com simulação pesada)
Todas as medidas usam a **sequência de campanhas** (Carreira 1, 2, 3...) com a árvore comprada pelo robô.
- **A árvore fecha só entre a 5ª e a 8ª campanha** (hoje fecha na 4ª), nos perfis 3, 4 e 5/s, nas duas artes. "Fechar" = todos os nós que o perfil consegue ver estão comprados.
- **Boxe x Jiu-jitsu até o cinturão da academia (Kid): diferença ≤ 10%** a 3, 4 e 5/s, com **amostra grande (≥ 400 jogadores por perfil e por arte)**. Alavancas: preço de `style_bjj`, `body_crew_2` e dos ramos de arte.
- **Kid por perfil e por arte:** tabela 3/4/5/s x Boxe/Jiu-jitsu. Metas: Kid em 1–2 campanhas (mediana); a 3/s o Jiu-jitsu não fica atrás do Boxe; a 5/s o Boxe não abre mais de 0,3 campanha de vantagem.
- **Kid menos fácil para quem espera o verde** (hoje vence 79–98% na chegada). Alavanca: **F/A/R do Kid**. **A data do Kid não muda.** Meta de partida: o robô que espera o verde vence o Kid na 1ª tentativa em **no máximo 70%** das vezes. O Designer pode propor outra meta, com o motivo escrito.
- **Não pode piorar:** 23b (2.000 jogadores, ≤ 25% ±2, ninguém antes de 19:30, ≤ 1% antes de 20:00); 1ª derrota da carreira 1 em 10–15 min; cinturão amador entre a 2ª e a 4ª campanha; tempo morto da carreira 1 a 3/s ≤ 10:32 (p90); academia ≤ 10:00.
- **Refazer a tabela fixa de late game** (clique ≥ X% da renda no fim do conteúdo), agora com a árvore cheia.
- O efeito do **+1 dia** e da **corda montada** aparece numa linha própria da tabela "luta no dia x antes" (5.3).
- Número mudado sem pedido vai na linha **"mudei sem pedido"** no topo da seção.

### 3.4 Botão e janela
- Botão da árvore na sala, com brilho quando há compra possível.
- O botão ÁRVORE da tela de fim de campanha abre **o mesmo mapa**. O botão NOVA CAMPANHA continua lá.
- Comprar = 1 clique, sem confirmação (como hoje), com som e um "acender" do nó e dos vizinhos que aparecem.
- Cartão ao passar o mouse: nome, efeito, preço e "VALE NA PRÓXIMA CAMPANHA".
- Legado sempre visível no topo do mapa.

### 3.5 Save
- Versão nova do save, com migração (seção 2, decisão 5). Testes com save isolado. O save real do dono não é tocado.

## 4. O que fica de fora
- Honra, mural/hall e árvore do hall → **6c**.
- Personalização e "receber novo discípulo" → **6b**.
- História, diálogo, voz e cenas → **6a+**.
- Região e nós do **Muay Thai** → **7b**. Regiões do centro de treinamento em diante → **8a+**.
- Segunda arte (híbridos) → **9**.
- Zoom no mapa, mapa animado, som novo → **13 (Polimento)**, se pedirem.
- Reembolso ou "resetar a árvore" → não entra (sem pedido).
- Metrônomo/Shift → só se o dono pedir.

## 5. Critérios de aceite
1. A sala não mostra mais a árvore em abas. Um botão abre o mapa por cima da sala, que fecha com 1 clique ou Esc. Ele abre durante a campanha e na tela de fim.
2. O botão brilha **só** quando existe um nó à vista que o Legado paga (teste automático).
3. O mapa tem **35–40 nós**, com os 12 atuais no centro, as regiões Garagem, Academia, Boxe, Jiu-jitsu e Campanha e pelo menos 3 nós de ligação.
4. Comprar um nó revela os vizinhos na hora. Regiões com trava (Academia, artes) não aparecem antes da hora.
5. Nós em `data/skill_tree.json` (posição, vizinhos, região, preço, efeito). Mudar um número muda o jogo sem mexer em código.
6. **Corda montada:** a campanha seguinte começa com a corda no lugar, sem caixa. **+1 dia:** todas as datas da campanha seguinte têm +1 dia. **Grito mais alto:** o Grito rende mais quando comprado.
7. O que se compra no meio da campanha só vale na próxima, e o cartão diz isso.
8. Com o mapa aberto, o relógio, a equipe e o clique não andam.
9. O ramo aparece como **CAMPANHA** (ou o nome aprovado pelo Roteirista), sem "CARREIRA" sobrando na árvore.
10. **Save antigo** abre com os nós comprados acesos no centro, os vizinhos à vista e o Legado igual.
11. **Simulação (no `fase5.4-design.md`, conferida pelo QA rodando o simulador):**
    - a árvore fecha entre a 5ª e a 8ª campanha (3/4/5/s, Boxe e Jiu-jitsu);
    - Boxe x Jiu-jitsu até o Kid ≤ 10%, com ≥ 400 jogadores por perfil e arte;
    - tabela do Kid por perfil e arte dentro das metas da 3.3;
    - quem espera o verde vence o Kid na 1ª tentativa em ≤ 70%;
    - as metas que "não podem piorar" (3.3) continuam de pé;
    - a 1ª derrota compra pelo menos 1 nó.
12. Mapa, botão, cartão e tela de fim com `ui_audit` em **0 problemas** (skill `alinhamento-ui`; os nós do mapa declarados como posição livre).
13. `tools/run_tests.ps1` passa inteiro e os testes não tocam o save real.

## 6. Riscos de design
- **Mapa grande de nós pequenos vira planilha.** Muito "+5%" seguido cansa. Proteção: um marco (efeito novo e visível) a cada 3–4 nós de caminho, e o primeiro nó de cada região sempre visível e barato.
- **Árvore escondida demais.** Se o jogador esquecer que ela existe, o Legado fica parado. Proteção: o brilho do botão e o atalho na tela de fim.
- **Comprar no meio da campanha e "não ver nada".** Pode frustrar. Proteção: o cartão diz "vale na próxima campanha". Se o dono estranhar, a troca para "vale na hora" fica para outra fase, com nova medição.
- **Corda montada tira o "chegou equipamento".** O dono pediu. A esteira e o aparelho da arte continuam na caixa, então o momento não some.
- **+1 dia afrouxa o calendário.** 6 lutas x 1 dia pode baratear demais as datas. O Designer mede, e o nó fica caro e longe do centro.
- **Fechar só na 5ª–8ª campanha e ter 35–40 nós puxam para lados opostos.** Mais nós = mais Legado no total. O Designer acerta pelo preço, não cortando nós.
- **Kid mais forte pode empurrar quem clica pouco para 3 campanhas.** Por isso a tabela por perfil e a mediana de 1–2 continuam como trava.
- **Mapa livre e o verificador de alinhamento.** Os nós não formam fileiras. O UI/UX declara a intenção (`ui_align`) de cada parte para o verificador não acusar falso problema, nem esconder um problema real (texto cortado, cartão fora da tela).
- **Arte demais.** 25 ícones novos é muito. Os nós pequenos usam **1 ícone por tipo de efeito**, e só os marcos ganham ícone próprio.

## 7. O que o dono valida quando jogar
1. O botão escondido: dá para achar quando precisa? O brilho chama sem incomodar?
2. Abrir o mapa e comprar: dá a sensação de "apareceram mais coisas"? Dá vontade de voltar depois?
3. Arrastar e rolar o mapa: fica confortável sem zoom?
4. "Vale na próxima campanha" ao comprar no meio: incomoda ou faz sentido?
5. **Corda montada:** gostou de começar com ela? Sentiu falta da caixa da corda?
6. **+1 dia de preparo:** fez diferença?
7. O nome **CAMPANHA** no lugar de CARREIRA.
8. O **Kid** ficou mais justo (menos fácil para quem espera o verde)?
9. O save dele abriu com tudo o que já tinha comprado.

## 8. Quem entrega o quê
| Papel | Entrega |
|---|---|
| **Designer** | `fase5.4-design.md`: lista dos ~35–40 nós (região, vizinhos, preço, efeito), regras de revelação e trava, números de corda montada, +1 dia e Grito mais alto, novos F/A/R do Kid, preços de `style_bjj`/`body_crew_2`. **Simulação pesada:** robô que compra a árvore, sequência de campanhas a 3/4/5/s nas duas artes com ≥ 400 jogadores, árvore fechando na 5ª–8ª, Kid por perfil e arte, metas que não podem piorar, tabela de late game. Linha "mudei sem pedido" |
| **Roteirista** | Nome do ramo CAMPANHA, nomes e frases curtas dos nós novos (tom pé no chão, garagem e academia), nomes das regiões, texto do cartão ("vale na próxima campanha") |
| **Diretor de Arte** | Moldura do mapa, fundo por região, peças do nó (pequeno, marco, ligação, à vista, comprado), linhas entre nós, botão da árvore com brilho, 1 ícone por tipo de efeito e ícones dos marcos |
| **Programador** | Mapa em `data/skill_tree.json` (posições e vizinhos), revelação, travas por região, efeitos novos (corda montada, +1 dia, Grito mais alto), "vale na próxima campanha", migração do save, simulador com robô comprando a árvore, testes com save isolado |
| **UI/UX** | Janela do mapa por cima da sala (arrastar, rolar, centralizar), botão com brilho, cartão do nó, animação de compra e revelação, botão ÁRVORE da tela de fim apontando para o mapa; skill `alinhamento-ui` até **0 problemas** |
| **QA** | `fase5.4-qa.md` contra os 13 critérios, rodando o simulador por conta própria, migração de save antigo (com nós comprados), regressão da 5.1–5.3 |

## Resumo para o Produtor
A 5.4 troca as 3 abas por **um mapa grande que se revela**, com ~35–40 nós, os 12 atuais no centro, regiões Garagem, Academia, Boxe, Jiu-jitsu e Campanha, e ligações entre elas. Fica **escondido atrás de um botão** na sala, que brilha quando dá para comprar.
Decidi: a árvore abre a qualquer hora (fora da luta e do dia da luta), e o que se compra vale na próxima campanha. O save antigo mantém tudo, e os nós comprados ficam no centro.
Entram os nós pedidos (**corda montada**, **+1 dia de preparo**, **Grito mais alto**), o ramo vira **CAMPANHA** e o balanço obrigatório volta: árvore fechando na 5ª–8ª campanha, Boxe x Jiu-jitsu ≤ 10% com amostra grande e Kid menos fácil (F/A/R, nunca a data).
O dono já aprovou seguir. Quando puder jogar, ele valida os 9 pontos da seção 7.

## Decisões do Diretor (design 5.4)
Data: 2026-11-13. Li o `fase5.4-design.md` inteiro. Estas decisões **substituem** os trechos correspondentes da 3.3 e do critério 11.

### D1. Kid na 1ª tentativa: meta nova (aceita, com trava)
- **Fica o Kid ×1,5** (6.900.000 / 12.075.000 / 31.050.000). A data não muda.
- A meta "≤ 70% em todo perfil" sai. O motivo do Designer procede: com a data fixa, a 1ª tentativa vira um degrau por velocidade de clique, e nenhum F/A/R chega a 70% sem jogar o JJ 3/s para 3 campanhas.
- **Meta nova** (robô que espera o verde, ≥ 400 por perfil e arte):
  1. média dos 6 perfis **≤ 80%** (hoje 79%);
  2. **nenhum perfil abaixo de 50%** (hoje o menor é JJ 3/s, 56%);
  3. mediana de campanhas até o Kid **1–2** em todos os perfis, e **p90 ≤ 4**.
- Fica registrado: o 4/s continua vencendo 92–96%. Não é para resolver agora. A alavanca certa (força do Jiu-jitsu na academia ou uma arte que não dependa da equipe) entra quando uma fase mexer nas artes. O dono decide jogando (seção 7, ponto 8).

### D2. Jiu-jitsu a 3/s atrás do Boxe: aceito, com teto
- A meta "JJ não fica atrás" passa a valer **na mediana** (hoje 1 × 1, fecha).
- **Tetos novos** para o JJ 3/s, que o QA confere:
  - média de campanhas até o Kid **≤ 2,2** (hoje 2,07);
  - tempo de jogo acumulado até o 1º Kid **no máximo 25% depois** do Boxe 3/s (hoje 21,5%).
- Motivo: a 1ª tentativa acontece sem nenhum nó de arte (a compra vale na campanha seguinte), então a árvore não consegue corrigir isso. Baixar o Kid para ×1,4 melhora o JJ 3/s (média 1,81), mas deixa o Kid fácil de novo (média de 88% na 1ª tentativa). O pedido do dono foi deixar o Kid menos fácil, e isso pesa mais.
- Perder o Kid não trava nada: rende Legado e a próxima campanha vem mais forte. Não é uma mecânica anti-incremental.

### D3. Mudanças sem pedido
| Mudança | Decisão | Condição |
|---|---|---|
| `body_crew_2` 900 → 800 | **aceita** | o escopo libera o preço |
| `career_good_loser` 800 → 700 | **aceita** | está dentro do "e outros, se precisar" |
| Nó com `requires_art` só vale jogando aquela arte (também nos efeitos genéricos) | **aceita** | é a regra do ESTILO. **Todo** nó dos ramos de arte mostra "SÓ VALE JOGANDO DE {arte}" no cartão, inclusive `box_footwork` e `bjj_breath` |
| A entrada de cada ramo de arte (`box_counter`, `bjj_guard`) é raiz e aparece quando a arte é liberada | **aceita** | cumpre o "1º nó de cada região barato" (200 contra os 1.200 do ESTILO). Continua ligada ao ESTILO no desenho |
| Nós novos de fama (`camp_sponsor`, `gym_league`) e de Legado (`camp_diary` +15%) | **aceitos** | entraram no orçamento e a árvore fecha na 6ª–7ª. **Teto:** `camp_diary` é o **único** multiplicador de Legado da 5.4. Outro só com pedido |
- Correção de documento: a linha "Mudei sem pedido" do design diz "nenhum" e depois lista mudanças. O Designer reescreve essa linha listando as 5 mudanças acima.
- **Nenhum número muda** por causa destas decisões.

### Resumo para o Produtor (decisões do design)
- O Kid fica ×1,5. A meta de "≤ 70% na 1ª tentativa" vira: **média ≤ 80%, nenhum perfil abaixo de 50%, mediana 1–2 campanhas**. Hoje fecha (79%, menor 56%).
- O Jiu-jitsu lento empata com o Boxe na mediana, mas às vezes precisa de uma campanha a mais. Aceitei com teto (média ≤ 2,2, até 25% mais tempo). A alternativa seria o Kid fácil de novo.
- As 5 mudanças que o Designer fez sem pedido foram aceitas. O multiplicador de Legado tem teto de 1 nó nesta fase.
- Quando jogar, o dono diz se o Kid ficou justo (ponto 8 da seção 7).
