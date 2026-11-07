# Fase 3 — Lutas e fim de carreira: revisão do Diretor

Dono: Diretor de Jogo. Versão 1 (2026-11-05).
Base: `PROMPT.md`, `docs/visao.md`, `docs/roadmap.md`, `fase3-escopo.md`, `fase3-design.md` (com §16), `fase3-textos.md`, `fase3-api.md`, `fase3-qa.md`, código de `scripts/` e `ui/`, `data/*.json`, screenshots de `scratchpad\ui3\shots\` e `scratchpad\qa3\shots\`.
Estado: bugs B1–B7 do QA corrigidos; `tools/run_tests.ps1` passa inteiro (924 checks + cena + guarda do save real).

## 1. Veredito

**APROVADO para mostrar ao dono.** Há 2 ajustes pequenos que podem ir junto, mas nenhum deles impede o teste (seção 5).

- Critérios: 26 de 30 OK. Os critérios 22, 23 e 24 (metas de tempo) ficam **PARCIAIS e aceitos como estão**. Quem decide é o dono, depois de jogar (seção 4). O critério 30 também fica PARCIAL, porque não houve como testar DPI 125%. Vai para a Fase 9 ou para a máquina do dono.
- A fase entrega o que prometeu: a luta dá sentido aos atributos, a derrota explica o motivo com número e a aposentadoria funciona. Nada das Fases 4+ entrou.

## 2. O que ficou bom

- **Risco honesto de verdade.** Fácil vence 99%, equilibrado 69% e perigoso 2% (QA, 1.500 lutas por rótulo). O jogador pode confiar na cor. É a base do pilar "Difícil, mas justo".
- **A tática muda o risco na hora**, nos 4 adversários, e cada tática é a melhor contra pelo menos um. A escolha é real, não enfeite.
- **Foco único perde.** O "só saco" precisa de 1,6 a 1,9 vez mais treino que o equilibrado. A lição da garagem ("treine os três") chega pela prévia ("ELE É MUITO MAIS FORTE") antes do castigo.
- **A derrota se explica.** "FALTARAM 2.69K DE RESISTÊNCIA PRA AGUENTAR" + uma estatística do que se viu + a dica de aparelho. Com a §16 do design, a derrota por azar numa luta FÁCIL diz que foi azar ("ERA PRA SER SUA. DEU AZAR.") e não culpa o treino. Isso é exatamente o "doeu, mas eu sei o que faltou".
- **A luta é curta e legível**, de 8 a 19 s. Tem crítico vermelho com "!", ESQUIVOU, contra-golpe, bloqueio, grogue, K.O. e pontos, tudo ligado à simulação com desvio de até 6 ms. A arena da borracharia tem identidade própria e o tom de bairro. O rig articulado foi respeitado, com a mesma luva no cursor, na garagem e na luta (46 de 46 sprites).
- **Não dá para fugir da derrota fechando o jogo**, e o Legado não duplica. O save v3 separa carreira e permanente, e a migração da Fase 2 funciona.
- **Do fim à garagem em 1 clique.** A Carreira 2 começa em menos de 1 segundo.
- **Tom certo.** Dudu Alongado, Brutão do Posto, Dinho Pulga e Seu Muralha são pé no chão, com humor seco e sem humilhar. "O BAIRRO VIU. UNS QUINZE." é a voz do jogo.
- **Loja mínima e útil.** O Prof. Nelson sai com 1 vitória e a luva de lona com 2. A luva dobra o clique aos ~9 min, justo quando a garagem da Fase 2 "acabava".

## 3. Desvios da visão (pelos pilares)

### "Todo soco pesa"
- Na garagem, nada mudou: clique com número, tremida e som. Bom.
- **Na luta o jogador só assiste** (decisão 6 do escopo). Em 8 a 19 s isso funciona, mas é a maior troca do pilar nesta fase. Fica para o dono decidir se quer o clique opcional na luta (Fase 9).
- **O clique em LUTAR! tem um engasgo que entrega o resultado.** Quem resolveu o B5 passou a calcular o motivo **só quando a luta vai ser derrota** (`scripts/game_state.gd:535-536`). O clique em LUTAR! trava ~100–200 ms aqui, e pode passar de 0,5 s num PC fraco. Isso acontece **só nas derrotas que não são azar**. Um jogador atento aprende que "travou = vou perder", e a tensão da luta some. É pequeno, mas mexe no pilar "A luta prova o treino". Ver a seção 5.

### "A luta prova o treino"
- Cumprido no essencial: o resultado vem dos números, o risco é visível e o motivo bate com o atributo decisivo em 28 de 28 casos.
- **Ressalva: "equilibrado" quer dizer cara ou coroa.** Na primeira vez, o jogador típico luta com ~50% de chance. A prévia não mente, mas a mensagem do jogo ("lute quando estiver amarelo") empurra para derrotas que são metade sorte. A dica da tela de fim diz qual aparelho treinar, mas não diz "espere ficar verde". Foi por isso que o QA, seguindo a dica, perdeu de novo 2 de 2 na 2ª carreira. É o critério 5 do protótipo, que fecha na Fase 4.

### "Não tão fácil"
- Cumprido, e às vezes de um jeito chato. A dificuldade vem mais da **espera** que da escolha. O típico "só saco" que passa do Dinho fica 20 a 40 min diante do Seu Muralha em "perigoso", sem nada para comprar com dinheiro depois da luva de couro. A partida do QA durou 63,7 min, com ~40 min parado. Não é anti-incremental: não há timer e o número sobe. Mas é **tempo morto**, o risco a vigiar na Fase 4.
- O Legado ainda não compra nada (R4). A tela diz isso com honestidade ("VAI SERVIR NA PRÓXIMA VERSÃO"), mas a 1ª derrota hoje é só castigo com explicação. O dono precisa saber disso antes de testar.

### Pequenos desvios (não bloqueiam)
- O bônus de "saída por cima" ficou em +50% do pote (25 de 75). A visão falava em "bônus pequeno". Está na decisão 10.
- A tela de vitória diz "+2 LEGADO" (Legado **em jogo**), e na leitura rápida parece Legado total. A linha de baixo explica. Texto para a Fase 4, quando o Legado total ganha tela própria.
- Os screenshots `15_cinturao.png` (+$909, +90 de fama) e `fix_fim_legado.png` (fama 0 e Legado +2) foram montados com estado artificial. Os números não batem com `data/`. O código está coerente (o ganho e o resumo saem do mesmo `fama`), e o QA conferiu o cinturão real com +$1.00K, +100 de fama e +30 de Legado. Não é bug, mas não usar esses dois screenshots no relatório ao dono.

## 4. Critérios 22–24: decisão do Diretor

**Decisão: aceitar como está e deixar o dono decidir depois de testar. Não ajustar o Seu Muralha agora.**

Por quê:
1. **O ajuste proposto ataca o sintoma errado.** O problema que o QA viu é tempo morto: 40 min parado diante do Muralha. Subir a Resistência dele de 490K para 560–600K e a Agilidade de 58K para 70K **aumenta** essa espera para quem não troca de foco. Também não ajuda o critério 22, porque as derrotas de 10–15 min acontecem no Dinho, não no Muralha.
2. **O ajuste piora o que importa para a próxima fase.** O jogo bom a 3 cliques/s passa de 40 min (critério 23). Seguir a dica contra o Muralha cai abaixo de 5 de 17 (critério 24), e o critério 24 é o critério 5 do protótipo, que a Fase 4 precisa fechar.
3. **A Fase 4 vai mexer no balanço de qualquer jeito** (R5 do escopo). A árvore dá bônus, e a meta da visão é "cinturão entre a 2ª e a 4ª carreira **com árvore**". Afinar o Muralha duas vezes é retrabalho.
4. **O "típico" do simulador é um robô** que nunca troca de foco, mesmo com a prévia dizendo "ELE AGUENTA MUITO MAIS". Gente de verdade reage, e as medianas (12:44 a 5 cliques/s, 14:14 a 4/s) já caem dentro da meta.
5. **A meta de 10–15 min é uma proposta do estúdio** (visão, "Assumido" nº 7), "a ser validada jogando". O dono nunca jogou. Quem valida é ele.

O que o Produtor manda agora: **nada para o Designer nem para o Programador sobre 22–24.**
Pergunta para o dono depois do teste, com 3 respostas possíveis (cada uma é 1–2 números em `data/opponents.json` + rodar `fase3_sim.py carreiras dica`):
- **A. "Está bom":** fica como está e é medido de novo com a árvore na Fase 4.
- **B. "O cinturão saiu fácil / quero mais pressão":** a proposta do Designer, `opp_tank.endurance` 490000 → 580000 e `opp_tank.agility` 58000 → 70000.
- **C. "Fiquei esperando demais no Seu Muralha":** `opp_tank.endurance` 490000 → 420000, com menos espera. O cinturão fica um pouco mais acessível ao típico.

Pedido ao Designer **para a Fase 4** (não agora): medir no simulador o **tempo morto**, ou seja, minutos seguidos com o próximo adversário em "perigoso" e nada comprável com dinheiro. Meta proposta: nunca mais de 10 min seguidos para o jogador típico, já contando a árvore.

## 5. Ajustes antes de mostrar ao dono (pequenos, não bloqueiam)

| # | Dono | O quê | Por quê |
|---|---|---|---|
| 1 | Programador | **O tempo do clique em LUTAR! não pode depender do resultado.** Opções, do mais simples ao melhor: calcular o motivo em toda luta (e descartar na vitória); ou calcular em segundo plano durante a animação, como era antes, mas sem travar o quadro (em fatias ou em `Thread`). O motivo precisa continuar salvo antes da tela de fim. | O engasgo só nas derrotas entrega o resultado (seção 3) |
| 2 | Programador | **Atualizar o `README.md`**: ainda diz "Fase atual: Fase 2". Incluir LUTAR!, APOSENTAR, LOJA, o save v3 e o simulador `fase3_sim.py`. | É o primeiro arquivo que o dono abre |

Se o item 1 não couber agora, ele vira o primeiro item da Fase 4. O item 2 é de 10 minutos e deve ir.

## 6. Riscos para a Fase 4 (árvore inicial, fecha o protótipo)

1. **Preço dos nós contra o Legado real.** Uma derrota típica rende de 1 a 10 de Legado. Cinturão + aposentar rende 75. Se os nós custarem 1 a 4, uma aposentadoria com cinturão compra a árvore inteira de uma vez. Os preços precisam crescer (8 a 12 nós) e ser medidos contra essas três rendas: 1ª derrota, derrota no Dinho e cinturão.
2. **Critério 5 do protótipo ("vence quem o derrotou").** Hoje: Dinho 4 de 5 no simulador, Muralha 5 de 17, QA jogando 0 de 2. A Fase 4 precisa fechar isso com o 1º nó **e** com a mensagem certa. Sugestão para o escopo: a dica da tela de fim ganhar "lute quando ficar verde" e o HUD mostrar "VOCÊ PERDEU PRA ELE" no adversário que derrotou o jogador. A revanche estava prevista para a Fase 4.
3. **Balanço em dobro.** Os números da Fase 3 são provisórios. A Fase 4 precisa rodar de novo os critérios 21–24 **com a árvore**. A meta passa a ser a da visão: 1ª carreira termina em 10–15 min e o cinturão sai entre a 2ª e a 4ª carreira.
4. **Tempo morto diante do Seu Muralha** (seção 3). Nós de "mais dinheiro por luta" ou de clique encurtam a espera. Medir (seção 4).
5. **Save v4.** Os nós comprados entram no bloco `permanent`. Precisa de migração v3 → v4 e o guarda do save real tem que continuar cobrindo tudo.
6. **Escopo.** Só os ramos Corpo e Carreira. A "prévia detalhada" (porcentagem) é um nó previsto. Linhagem, artes e começar na academia ficam para as Fases 5 e 7. A tela de fim ganha o atalho para a árvore (visão), e a frase "VAI SERVIR NA PRÓXIMA VERSÃO" sai.
7. **Processo.** O dono não aprovou nada desde a Fase 2. A Fase 4 fecha o protótipo e depende da resposta dele sobre a dificuldade (seção 4). **Recomendação forte: não abrir a Fase 4 antes do dono jogar a Fase 3.**

## 7. Como o dono testa (~10 min)

Antes de começar: abra o Godot 4.7.2, importe `E:\Fightclicker\project.godot` e aperte **F5**. Se você tinha um save da Fase 2, ele vira a "Carreira 1" com tudo mantido. Para começar limpo: **F12 → APAGAR SAVE → CONFIRMAR**.

**Parte 1: a primeira luta (3 min)**
1. Clique no saco por uns 20 s. Aperte **LUTAR!** (canto inferior direito) e veja a prévia: ELE x VOCÊ, o risco colorido e o prêmio.
2. Clique nas 3 táticas e veja o risco mudar. Clique em **VOLTAR A TREINAR**: não custa nada.
3. Para não esperar: **F12 → "+10 DE CADA GERADOR"** 2 vezes e F12 de novo para fechar. Treine ~1 min alternando as teclas **1, 2 e 3** (saco, corda, esteira) até o Dudu ficar **FÁCIL** (verde). Lute com **CONTRA-ATAQUE**.
4. Veja a luta (8 a 19 s) e o prêmio. Na aba **LOJA** (painel direito), contrate o **Prof. Nelson** ($50) e veja ele aparecer na sala.

**Parte 2: a derrota (2 min)**
5. Abra **LUTAR!** logo em seguida contra o **Brutão do Posto** (vai estar PERIGOSO, vermelho) e lute assim mesmo.
6. Leia a tela de **FIM DE CARREIRA**: quem venceu e quando, o "FALTARAM ...", a dica e o Legado ganho (+1). Clique em **NOVA CARREIRA**: você volta como "Carreira 2", com tudo zerado e o Legado guardado.

**Parte 3: o cinturão e a aposentadoria (5 min, com atalho)**
7. **F12 → "+10 DE CADA GERADOR" umas 30 vezes** (~2.700 de treino por segundo). Feche o F12.
8. Troque de aparelho (1, 2, 3) a cada ~20 s para subir os três atributos. Lute cada vez que a prévia ficar **verde**. Táticas sugeridas: Dudu e Brutão em contra-ataque, Dinho em defensivo, Seu Muralha em agressivo.
9. Depois de vencer o Seu Muralha, veja a tela **CINTURÃO AMADOR** e "ACADEMIA DE BAIRRO LIBERADA (EM BREVE)". O LUTAR! fica desligado.
10. Aperte **APOSENTAR**. A confirmação mostra "VOCÊ LEVA 75 DE LEGADO" (com +25 pelo cinturão). Confirme e veja a tela "saiu por cima".

**Opcional (15 min, sem F12):** comece uma carreira nova e jogue do seu jeito, lutando quando achar que dá. É o único jeito de responder à pergunta da seção 4 ("difícil demais, fácil demais ou espera demais?").

**O que é provisório (placeholder):**
- Toda a arte (arena da borracharia, os 4 adversários, Prof. Nelson, luvas, cinturão) e os sons são do estúdio.
- **O Legado ainda não compra nada.** A árvore é a Fase 4.
- "Academia de bairro" é só aviso: a mudança de local é a Fase 5.
- As falas dos adversários existem, mas não aparecem (Fase 8).
- Todos os números (adversários, prêmios, Legado, loja) são provisórios e ficam em `data/`.
- O painel do F12 é só para teste e não existe no jogo final.

## 8. Decisões para o dono revisar (prioridade)

1. **Dificuldade (critérios 22–24):** respostas A, B ou C da seção 4, depois de jogar. É a que mais pesa na Fase 4.
2. **Derrota sem dinheiro e Legado pequeno** (decisões 5 e 12). Uma derrota típica rende 1 a 10 de Legado. Ele aceita que a 1ª derrota, por enquanto, só explica?
3. **Sem clique durante a luta** (decisão 6). Assistir 8 a 19 s está bom, ou ele quer um clique opcional (Fase 9)?
4. **O dinheiro compra só 2 coisas** (decisão 3). No fim da escada sobra dinheiro sem uso. Ele quer mais loja já na Fase 4 ou pode esperar a Fase 5?
5. **Bônus de saída por cima = +50% com cinturão** (decisão 10). A visão dizia "pequeno".
6. **Prévia sem porcentagem** (decisão 11). A porcentagem vira nó da árvore na Fase 4.
7. **Escada de 4 e nada depois do cinturão** (decisão 4).
8. Menor prioridade, todas são um número ou uma regra simples: garagem paga em Treino (1), tremida em todo clique (2), pontos no limite de tempo com empate para ele (7), fechar o jogo não evita a derrota (8), aposentar com 0 de Legado (9).

## Resumo para o Produtor

A Fase 3 está **aprovada para o dono testar**. A luta é curta e legível, o risco é honesto, a tática importa e a derrota explica com número o que faltou. Antes de mostrar, vale corrigir 2 coisas pequenas: o engasgo no LUTAR! que entrega a derrota e o README, que ainda fala da Fase 2.
As metas de tempo 22–24 ficam como estão, **sem mexer no Seu Muralha agora**. O problema real é a espera longa diante dele, não a dificuldade, e a árvore da Fase 4 muda o balanço de qualquer jeito. O dono escolhe A, B ou C depois de jogar.
Diga ao dono que o Legado ainda não compra nada e que o teste de 10 min usa o F12 ("+10 DE CADA GERADOR") para chegar ao cinturão.
Recomendação forte: **não abrir a Fase 4 sem ele jogar a Fase 3**, porque o preço da árvore depende da resposta dele.
