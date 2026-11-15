# Fase 5.3 — Calendário da campanha: escopo

Dono: Diretor de Jogo. Data: 2026-11-12. Branch: `fase-5.3` (sobre a 5.2 e a 5.1, ainda não integradas na `main`).
Base: `PROMPT.md`, `docs/roadmap.md` (5.3), `docs/visao.md` (decisões de 2026-11-11, item 1), `docs/propostas/feedback-2026-11-11.md` (item 1, seção 2.1 e respostas do dono), `docs/direcao-narrativa.md` (4.1, campanha e "passar o posto") e `fase5.2-revisao.md` (seção 5, "5.3").

**Status: aprovado de antemão pelo dono** ("pode seguir"; ele não pode testar agora). O que ele confere jogando está na seção 7.

## 1. Objetivo e sensação
- **Objetivo:** cada carreira vira uma **campanha com calendário**. As lutas têm data, a data está sempre à vista e, no dia, o jogador escolhe **Lutar** ou **Passar o posto**.
- **Sensação:** "a escola me inscreveu, tenho X dias para chegar pronto"; "eu vi a data chegando e decidi". Nunca "o relógio me matou".

## 2. Regra central (calendário obrigatório x derrota encerra a carreira)
- **A data é obrigatória, a luta não.** No dia, o jogo para e espera. As duas saídas são escolha do jogador: lutar (arrisca) ou passar o posto (100% do Legado).
- **Passar o posto sempre é melhor que perder.** Aposentar no dia conta como aposentadoria (vale para a Honra da 6c).
- **Nada acontece sem o jogador apertar.** Nenhuma luta começa sozinha, nenhuma data chega sem aviso.

## 3. O que entra

### 3.1 Dias no HUD
- Um contador de **dia da campanha** que anda na sala. Segundos por dia em `data/`.
- **Cada luta tem data.** A próxima aparece sempre no HUD: "Faltam 4 dias · Dinho Pulga" com o **risco da prévia ao lado** (a cor que já existe).
- **Avisos:** faixa a **3 dias**; faixa + som (som que já existe) a **1 dia**.
- A prévia continua abrindo a qualquer hora, como hoje.

### 3.2 O dia da luta
- O **relógio e o treino param**: clique, equipe, Metrônomo e luva dourada. Nada de preparo de graça no dia.
- A **prévia abre sozinha** com 2 botões: **Lutar** (com a escolha de tática de sempre) e **Passar o posto** (aposentar, 100% do Legado, com confirmação).
- A prévia do dia **não fecha para voltar a treinar**. O jogo fica esperando o tempo que for.
- **Lutar antes da data é livre.** A data seguinte conta a partir do dia em que a luta aconteceu.
- O botão de aposentar fora do dia continua igual (a qualquer momento entre lutas), só com o texto novo.

### 3.3 O relógio
- **Só anda com o jogo aberto e na sala.**
- **Para** com janela aberta por cima da sala (prévia, árvore, fim de carreira, opções), na luta e na escolha da arte.
- **Regra anti-abuso:** o relógio para **onde a equipe para**. Se a equipe continua treinando com alguma janela aberta, o relógio também anda nessa janela. Não pode existir "abro uma janela e treino sem o dia passar". O Programador confere janela por janela e o Designer escreve a lista.
- **Jogo aberto em outra janela do Windows** (sem foco, minimizado): conta como aberto. Relógio e equipe andam juntos, como hoje. Se o dia chegar assim, o jogo para e espera. Se for barato, o ícone da barra de tarefas pisca.
- **Nunca pula para o dia de uma luta**, nem no futuro offline (fase 13). Fica escrito no `data/` e no design para a fase 13 respeitar.

### 3.4 As 6 lutas
- As 4 amadoras (Dudu, Brutão, Dinho, Muralha) **e as 2 da academia** (Tonhão, Kid) têm data.
- **Entre ligas:** depois do cinturão e da mudança, a 1ª data da academia é **mais folgada**.
- **Depois do Kid** não há próxima luta: o HUD mostra "Campanha completa" e o relógio some. Passar o posto continua ali.
- A **dica atual de aposentar da academia** (5 min de PERIGOSO) pode ficar repetida com o aviso de data. O Designer decide se ela fica, muda ou sai.

### 3.5 Balanço
O Designer define em `data/` os **segundos por dia** e a **folga de cada luta** (em dias). As metas da Fase 5 e da 5.2 não podem piorar:
- **Quem joga bem chega verde na data;** quem foca errado chega amarelo ou vermelho e decide.
- **1ª carreira termina em 10–15 min** (1ª derrota), nos perfis de sempre.
- **23b com 2.000 jogadores**, meta nova: cinturão na 1ª carreira em **≤ 25% (±2)**, **ninguém antes de 19:30**, **no máximo 1% antes de 20:00**. Se o mais cedo cair abaixo de 19:30, a alavanca combinada é a melhoria 3 a **$300K**.
- **Tempo morto da carreira 1 a 3/s:** não pode piorar (**≤ 10:32**, p90). Desejável: voltar a ≤ 10:00.
- Seguem de pé: academia ≤ 10:00 de tempo morto; Kid em 1–2 carreiras (mediana); Jiu-jitsu a 3/s não depois do Boxe; clique no fim do conteúdo ≥ X% da renda (tabela fixa da 5.2).
- **Medida nova:** por perfil (3, 4 e 5/s), quantas lutas acontecem **no dia** x **antes**, e com que risco. Meta de partida: a 4–5/s a maioria luta antes da data; a 3/s, no máximo 1 em 4 lutas chega no dia em vermelho. O Designer pode mudar, com o motivo escrito.
- O simulador ganha o relógio e uma regra de robô para "lutar antes / esperar a data / passar o posto". A mudança do robô fica registrada.

### 3.6 Pendências da 5.2
- **B1 — retrato da luta com a L4:** o retratinho no topo da luta passa a seguir a luva (L1–L4). Tarefa pequena.
- **Grito da equipe sobe na LOJA:** o card fica visível sem rolar quando é comprável.
- **Metrônomo/Shift: fica de fora.** O dono não respondeu. Se ele pedir, é só número em `shop.json`, numa fase seguinte.

### 3.7 Save
- **Versão nova do save**, com dia da campanha e data da próxima luta.
- **Carreira em andamento** num save antigo: a próxima luta ganha a **folga cheia** a partir do dia em que o save foi aberto. Ninguém abre o jogo e cai direto no dia da luta.
- Save já depois do Kid: "Campanha completa", sem data.
- Nada se perde: caixas fechadas, luvas, Grito, Legado e árvore seguem iguais.

### 3.8 Textos de campanha
Só texto, sem fala nem cena (essas são da 6a/6b):
- "Aposentar" vira **"Passar o posto"** onde for o botão e a confirmação.
- Fim de carreira passa a falar em **campanha** ("Campanha encerrada", "Nova campanha"). O Roteirista decide onde cabe sem confundir.
- Datas e avisos no tom pé no chão ("A escola te inscreveu", "Faltam 3 dias"). "Receber novo discípulo" fica para a 6b, junto com a personalização.

## 4. O que fica de fora
- Árvore grande e nó "+1 dia de preparo" → **5.4**.
- Diálogo, som de voz, treinador falando → **6a**.
- Cena de sucessão, personalização, "receber novo discípulo" → **6b**.
- Honra e mural → **6c**.
- Progresso offline → **13** (já sabendo que nunca pula datas).
- Metrônomo/Shift → só se o dono pedir.
- Som novo para os avisos → **13** (usa os sons que já existem).

## 5. Critérios de aceite
1. A próxima luta e "Faltam X dias" aparecem **sempre** na sala, com o risco ao lado. As 6 lutas têm data, inclusive Tonhão e Kid.
2. Faixa a 3 dias; faixa + som a 1 dia. Dá para ver as duas em ≤ 1 campanha normal.
3. No dia: relógio, clique, equipe, Metrônomo e luva dourada param, e a prévia abre com **Lutar** e **Passar o posto**. Deixado parado **10 min**, o jogo continua esperando e nenhuma luta começa.
4. **Passar o posto** no dia dá **100% do Legado** (igual ao aposentar de hoje).
5. Lutar antes da data funciona a qualquer hora; a data seguinte conta do dia da luta.
6. O relógio **não anda** na luta, na escolha da arte e nas janelas listadas pelo Designer; em nenhuma delas a equipe treina com o dia parado (teste automático cobre).
7. Segundos por dia e folga de cada luta estão em `data/`. Mudar o número muda o jogo sem mexer em código.
8. **23b com 2.000 jogadores:** ≤ 25% (±2), ninguém antes de 19:30, ≤ 1% antes de 20:00.
9. **Tempo morto da carreira 1 a 3/s ≤ 10:32** (p90); academia ≤ 10:00; 1ª derrota da carreira 1 em 10–15 min.
10. Metas de pé da 5.2 conferidas: Kid em 1–2 carreiras, Jiu-jitsu a 3/s não atrás do Boxe, clique no fim do conteúdo ≥ X%.
11. Tabela "luta no dia x antes" por perfil no `fase5.3-design.md`, dentro da meta da 3.5.
12. Retrato da luta segue a luva (L1–L4); Grito da equipe visível sem rolar quando comprável.
13. Save antigo com carreira no meio abre com a folga cheia e sem perder nada; save depois do Kid abre como "Campanha completa".
14. Telas mexidas (HUD, faixas, prévia do dia, LOJA, fim de carreira) com `ui_audit` em **0 problemas**.
15. `tools/run_tests.ps1` passa inteiro e os testes não tocam o save real.

## 6. Riscos de design
- **Quem está AFK ou em outra janela volta e acha o jogo parado.** É o risco principal: hoje a equipe rende parada; com o calendário, o dia trava tudo. Proteções: o aviso de 1 dia tem som; a data fica sempre à vista; o jogo para e **espera**, sem perder nada que já tinha; o ícone pisca se for barato. O Designer mede quanto tempo de equipe o AFK "perde" por campanha e, se for muito, a alavanca é **folga maior**, nunca luta automática.
- **Data apertada demais vira castigo.** Se o jogador que joga bem chega amarelo, o calendário vira "relógio que mata". Por isso a meta "quem joga bem chega verde" e a tabela do critério 11.
- **Data folgada demais não serve para nada.** Se ninguém nunca chega na data, a fase não mudou o jogo. A tabela mostra isso também.
- **Abuso de janela:** abrir uma janela para treinar sem o dia passar. Fechado pela regra da 3.3 e pelo critério 6.
- **Calendário mexe em tudo do balanço:** 23b, tempo morto e 1ª derrota. O Designer mexe um número por vez e escreve o efeito.
- **Botões trocados no dia:** "Passar o posto" ao lado de "Lutar" pode ser apertado sem querer. Confirmação obrigatória no Passar o posto.
- **Texto novo confunde quem já joga:** "Passar o posto" no lugar de "Aposentar" precisa ser entendido de primeira. O Roteirista testa a frase curta.

## 7. O que o dono valida quando jogar
1. "Faltam X dias" e o risco ao lado: dá para ver sem procurar?
2. Os avisos de 3 dias e de 1 dia chegam a tempo, sem irritar?
3. No dia: ficou claro que é "lutar ou passar o posto"? Alguma vez pareceu que o jogo decidiu por ele?
4. O tamanho do dia e a folga entre lutas: sobra tempo, falta tempo ou está bom?
5. Deixar o jogo aberto em outra janela e voltar parado no dia: incomodou?
6. Os textos "campanha" e "passar o posto" fazem sentido?
7. O retrato da luta com a L4 e o Grito da equipe mais à vista na LOJA.
8. (Ainda em aberto da 5.2) Metrônomo e Shift continuam fracos?

## 8. Quem entrega o quê
| Papel | Entrega |
|---|---|
| **Designer** (Opus) | `fase5.3-design.md`: segundos por dia, folga de cada luta (inclusive a 1ª da academia), lista de janelas que param o relógio, destino da dica de aposentar da academia, robô do simulador, remedições (critérios 8–11) com 2.000 jogadores no 23b, tabela "no dia x antes", linha "mudei sem pedido" |
| **Roteirista** (Sonnet) | Textos do HUD, avisos, prévia do dia, "Passar o posto", "Campanha encerrada/completa", "Nova campanha" (tom pé no chão, frases curtas) |
| **Diretor de Arte** (Fable) | Calendário no HUD e faixa de aviso (3 dias e 1 dia) |
| **Artista de Personagens** (Fable) | Retrato da luta com as luvas L1–L4 (B1), skill `padrao-personagem` |
| **Programador** (Sonnet) | Relógio, datas em `data/`, parada no dia, regra anti-abuso, save novo com migração, simulador com relógio, testes com save isolado |
| **UI/UX** (Sonnet) | HUD com data e risco, faixas, prévia do dia com 2 botões e confirmação, Grito mais acima na LOJA, retrato ligado à luva; skill `alinhamento-ui` até **0 problemas** |
| **QA** (Sonnet) | `fase5.3-qa.md` contra os 15 critérios, simulador rodado pelo próprio QA (23b com 2.000), teste de 10 min parado no dia, migração de save antigo, regressão da 5.1/5.2 |

## Resumo para o Produtor
A 5.3 transforma a carreira numa campanha com calendário: as 6 lutas têm data, "faltam X dias" e o risco ficam sempre à vista, com avisos a 3 dias e a 1 dia.
No dia, o relógio e o treino param e a prévia abre com **Lutar** ou **Passar o posto** (100% do Legado). A luta nunca começa sozinha, lutar antes é livre e o relógio só anda com o jogo aberto, na sala, sem brecha para treinar com o dia parado.
O balanço não pode piorar: 23b com 2.000 jogadores (≤ 25%, ninguém antes de 19:30) e tempo morto da carreira 1 a 3/s ≤ 10:32. Entram também o retrato com a luva certa e o Grito mais à vista na LOJA. Metrônomo/Shift ficam de fora até o dono responder.
O maior risco é quem está AFK voltar e achar o jogo parado no dia. A proteção é aviso com som, data sempre visível e, se precisar, folga maior. Luta automática nunca. O dono valida os 8 pontos da seção 7.

## Decisões do Diretor (design 5.3)
Data: 2026-11-12. Sobre `fase5.3-design.md` (6.5, 6.6 e simulação). **Design aprovado sem mudança de números.**
1. **Kid fácil para quem espera o verde (79–98% na chegada): aceito.** Folga do Kid fica 16. Se o dono achar fácil, a alavanca é F/A/R do Kid na **5.4**, nunca a data.
2. **Árvore fecha na 4ª carreira: aceito nesta fase.** Efeito do 100% no "passar o posto". A meta "5ª–8ª" vira pendência obrigatória da remedição da **5.4**.
3. **4/s com 0,2% de cinturão na 1ª: aceito.** 25% é teto; a parede do Dinho é o efeito pedido. O 23b fecha pelo 5/s (26,4%).
4. **Fim da carreira 1 a 3/s em 15:26: aceito.** 3/s é referência; termina por escolha (passar o posto), 4/s e 5/s estão em 10–15 min.
5. **Equipe para na luta e nas janelas: aceito.** É a regra anti-abuso da 3.3. Cartão de início fecha com 1 clique ou Espaço.
6. **Dica de passar o posto a ≤ 3 dias e no vermelho (garagem e academia): aceito.**
- Risco aceito e anotado para a validação do dono (ponto 4 da seção 7): campanha 1 a 3–4/s termina quase sempre no Dinho, por escolha.
