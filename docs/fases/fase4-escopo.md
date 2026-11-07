# Fase 4 — Árvore de habilidades (inicial): escopo

Dono: Diretor de Jogo. Versão 2 (2026-11-06: decisões D1 e D2 do Diretor, critérios 21, 23 e 24 revistos).
Base: `PROMPT.md`, `CLAUDE.md`, `docs/visao.md`, `docs/roadmap.md` (Fase 4 e critério do protótipo), `fase3-escopo.md`, `fase3-design.md` (§8.2, §9, §13.8, §16.8), `fase3-qa.md`, `fase3-revisao.md` (seção 6, riscos para a Fase 4), `docs/propostas/auto-clique.md` e o código atual (`scripts/game_state.gd`, `scripts/save_store.gd`, `ui/janela_fim.gd`, `data/career.json`, `data/shop.json`, `data/ui_texts.json`).

**Aviso de processo.** O dono mandou seguir para a Fase 4 **sem ter jogado a Fase 3**. As respostas da revisão da Fase 3 foram assumidas pelo estúdio (abaixo). O escopo é conservador: dois ramos, poucos nós, todos os números em `data/`. Se ele mudar de ideia depois de jogar, é número, não código.

## Decisões do dono (2026-11-05)
1. **Aprovou a proposta `docs/propostas/auto-clique.md`, opção A nas três perguntas:**
   - **Metrônomo**: item da LOJA, pago em dinheiro, com níveis. Dá **socos de verdade pelo caminho do clique** (aparelho em foco × luva, crítico, número). Não faz a tela tremer. É **mais devagar que uma pessoa**. **Não funciona na luta.**
   - Nó **Memória muscular** na árvore: toda carreira começa com o Metrônomo no nível 1.
   - Os dois entram na Fase 4.
2. **Mandou abrir a Fase 4.**

## Respostas assumidas da revisão da Fase 3 (dono pode revisar)
- **Dificuldade (critérios 22–24): opção A, "está bom".** O Seu Muralha não muda agora. Tudo é medido de novo com a árvore e o Metrônomo nesta fase.
- **Ajustes 1 e 2 da revisão (engasgo no LUTAR! e README):** já estão feitos no código (o motivo da derrota é calculado em segundo plano, e o README fala da Fase 3). O QA confirma que o tempo do clique em LUTAR! não muda conforme o resultado.
- As outras decisões da Fase 3 continuam como foram assumidas (`fase3-escopo.md`, "Decisões para o dono revisar"). As decisões 2 (Legado pequeno), 4 (o dinheiro compra pouco) e 11 (prévia sem porcentagem) passam a ter resposta nesta fase.

## Objetivo
Dar destino ao Legado. Entre uma carreira e outra o jogador compra nós permanentes numa árvore pequena, vê esses bônus funcionando na carreira seguinte e volta para **vencer quem o derrotou**. Isso fecha o critério de sucesso do protótipo.

## Sensação
- **Na derrota:** a primeira derrota deixa de ser só castigo. "Perdi, mas já sei o que compro." Ela leva direto a uma escolha.
- **Na árvore:** "qual eu pego primeiro?". É uma escolha pequena e legível, com o efeito escrito em número.
- **No começo da carreira seguinte:** "estou mais forte que da última vez". O bônus aparece na tela desde o primeiro clique.
- **Na revanche:** "agora é minha vez". O adversário que te derrubou está marcado, e vencer ele é um momento.
- **Com o Metrônomo:** "meu lutador pegou o ritmo". A mão descansa, mas clicar continua rendendo mais.
- **Tom:** pé no chão. A árvore é o que o lutador anterior ensinou ao próximo. Nada de magia ainda.

## O que entra

### 1. Tela da árvore (entre carreiras)
- **Onde:** janela central sobre a sala escurecida, no mesmo padrão da prévia e da tela de fim.
- **Quando:** abre pela **tela de fim de carreira** (derrota ou aposentadoria), num botão próprio (ex.: "ÁRVORE" / "GASTAR LEGADO") ao lado de NOVA CARREIRA. Da árvore, um botão leva a NOVA CARREIRA.
- **Durante a carreira a árvore não abre.** Comprar no meio da carreira obrigaria a aplicar bônus no meio da run, e a regra é "vale na próxima". Para ver o que já tem, o jogador usa o resumo de bônus da garagem (item 4).
- Mostra o **Legado total disponível**, os nós com nome, efeito em número, preço e estado (comprado / comprável / falta Legado / trancado pelo nó anterior).
- **Comprar = 1 clique**, com efeito visual curto (o nó acende, o Legado desce contando). Sem confirmação extra. Não há reembolso nesta fase.
- Da tela de fim até estar clicando na garagem continua valendo **no máximo 2 cliques** para quem não quer comprar.
- Sai da tela de fim a frase "VAI SERVIR NA PRÓXIMA VERSÃO" (`legacy_note`).

### 2. Os nós: 8 a 12, só ramos Corpo e Carreira
- **Estrutura simples:** duas colunas (ramos), cada uma com uma linha principal e no máximo 1 bifurcação. Um nó só pede o anterior do mesmo ramo. Nada de grafo complicado.
- **Corpo** (atributos e clique). Exemplos para o Designer escolher e numerar:
  - +% de treino por clique (todos ou por aparelho);
  - +% de renda passiva;
  - vida ou redução de dano extra na luta (pequeno);
  - **Memória muscular**: começa toda carreira com o Metrônomo nível 1 (obrigatório, conta dentro dos 8–12).
- **Carreira** (lutas e Legado). Exemplos:
  - +% de dinheiro por vitória (ajuda o tempo morto);
  - +% de fama, ou +% de Legado no pote (com teto, ver riscos);
  - **prévia detalhada**: a prévia mostra a **porcentagem** de vitória ao lado do rótulo (decisão 11 da Fase 3).
- **Proibido nesta fase:** começar com geradores, com dinheiro, com luva ou num local melhor, e desbloquear arte. Isso é ramo Linhagem (Fases 5 e 7).
- Nomes e descrições: Roteirista, no tom do mentor ("o velho te ensinou a fechar a guarda").

### 3. Preços contra o Legado real
Rendas medidas na Fase 3 (`fase3-design.md` §8.2): derrota no Brutão = **1**, derrota no Dinho (o caso típico) = **4**, derrota no Seu Muralha = **10**, cinturão + aposentar = **75**.
- **Primeiros nós baratos:** pelo menos **1 nó custa 1** e pelo menos **2 nós custam ≤ 4**, em ramos diferentes. A 1ª derrota típica compra uma coisa e já escolhe.
- **Preço crescente** dentro de cada ramo.
- **Uma aposentadoria com cinturão (75) não compra mais que ~metade da árvore.** O custo total fica em **≥ 150**.
- **Árvore inteira em 5 a 8 carreiras** de um jogador típico que melhora a cada carreira.
- O Designer pode **reescalar o Legado** (ex.: tudo ×10, para ter preços mais finos), desde que as proporções acima continuem. Se reescalar, a migração do save converte o Legado guardado na mesma escala.

### 4. Bônus visíveis na carreira seguinte
- **Cartão de início de carreira** (1–2 s, some sozinho ou com um clique): "CARREIRA N — O QUE VOCÊ TROUXE:" e a lista dos nós ativos com o efeito em número.
- **Resumo permanente na garagem**: um rótulo pequeno (ex.: "LEGADO: 3 NÓS") que mostra a lista ao passar o mouse. Não cobre o alvo.
- **Cada bônus aparece onde age**:
  - clique: o número flutuante já sai maior, e o painel de atributos mostra o por-clique com o bônus;
  - dinheiro: o prêmio da prévia mostra o valor com o bônus ("$165 (+10%)");
  - prévia detalhada: a porcentagem aparece;
  - Memória muscular: o Metrônomo já está na prateleira e tocando no minuto 0.
- Ajuste de texto que a revisão da Fase 3 pediu: na tela de vitória, "+2 LEGADO" passa a dizer claramente que é **Legado em jogo** (ex.: "+2 LEGADO EM JOGO").

### 5. Metrônomo (LOJA, dinheiro)
- Item com **níveis** na LOJA, comprado em ordem, com custo crescente (3 a 5 níveis nesta fase, números com o Designer). Cada nível acelera o andamento.
- **O 1º nível cabe no prêmio de 1 ou 2 vitórias.** Ele concorre com o Prof. Nelson e com as luvas: é a decisão "luva, treinador ou ritmo?".
- **Regras fixas** (vindas da proposta aprovada):
  1. Cada tique é **um soco de verdade pelo caminho do clique**: aparelho em foco × melhorias × luva, mesmo sorteio de crítico, número flutuante saindo do alvo, treino no atributo em foco.
  2. **O soco do jogador é o mais pesado na tela.** O auto-soco tem número menor, **não faz a tela tremer** e tem som mais baixo.
  3. **Mais devagar que uma pessoa:** no nível máximo da Fase 4 fica em **até 1,5 soco/s** (uma pessoa clica 3 a 5).
  4. **Soma, não substitui:** acontece junto com os cliques do jogador, sem bloquear nem pausar o alvo.
  5. **Quem soca é o lutador**, com o rig articulado e a animação de jab que já existe, usando a mesma luva do cursor e das mãos.
  6. **Não funciona na luta.** Só soca quando a garagem está na tela, sem luta nem tela de fim por cima.
  7. Nada de combustível ou desgaste. Comprou, vale até o fim da carreira. No fim da carreira ele zera, como a loja. Só a Memória muscular devolve o nível 1.
  8. **Offline: não decidir agora** (Fase 9).
- **Na sala:** o Metrônomo é um **objeto** na prateleira da garagem que oscila no andamento. É um ícone ou prop, não um personagem.

### 6. Revanche
- O save guarda **quem encerrou a última carreira** (o adversário da derrota). Se a carreira acabou em aposentadoria, não há marca.
- Na carreira seguinte, esse adversário aparece com a marca **"VOCÊ PERDEU PRA ELE"** no HUD da próxima luta e na prévia.
- **Vencer ele** gera um momento próprio na tela de vitória (ex.: "REVANCHE!", texto do Roteirista), e a marca some.
- A marca vale **só para a última derrota**. Não é um histórico (o histórico da linhagem é da Fase 8).

### 7. Dica "lute quando ficar verde"
- A tela de fim continua com a dica de aparelho e ganha uma 2ª parte de **quando lutar**: "VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE" (Roteirista).
- Isso só vale quando a derrota veio de luta **amarela ou vermelha**. Na derrota por azar (prévia verde, §16.3 da Fase 3) a dica de azar continua sozinha.
- **Na prévia contra o adversário da revanche**, enquanto o risco não estiver verde, aparece uma linha curta: "ESPERE FICAR VERDE".
- **A cor nunca mente:** o rótulo e os limiares de risco da Fase 3 não mudam.

### 8. Save v4
- Bloco `permanent` ganha: **nós comprados**, **adversário da última derrota** (ou vazio) e o Legado (com a reescala, se o Designer usar).
- Bloco `career` ganha: **nível do Metrônomo**, e a marca de que a revanche já foi vencida (se precisar).
- **Migração v3 → v4:** nenhum nó comprado, Legado guardado intacto (ou convertido na escala nova), carreira em andamento intacta, sem marca de revanche. Migração em cadeia v0 → v4 continua funcionando.
- **Os bônus são aplicados no início da carreira e recalculados ao carregar.** Fechar e reabrir não duplica bônus, não perde nó e não devolve Legado.
- O guarda `test_real_save_guard.gd` continua cobrindo todos os arquivos de save.

### 9. Balanço refeito com a árvore e medição de tempo morto
- O Designer estende `tools/sim/` (`fase4_sim.py` ou opção nova no `fase3_sim.py`) com **carreiras em sequência**: o robô compra nós entre carreiras com uma regra simples (o mais barato que puder, e a variante "segue a dica do Designer") e compra o Metrônomo pela regra de compra da loja.
- **Tempo morto**: minutos seguidos em que o próximo adversário está **perigoso**, o jogador está na garagem e **nada da LOJA cabe no dinheiro**. O simulador reporta o maior trecho por carreira.
- Pode mexer em `data/`: preços dos nós, efeitos, Metrônomo, prêmios e, se precisar, os adversários. **Não pode mexer** nos limiares de risco (`risk.easy_min`, `even_min`) nem na honestidade do motivo da derrota.

### 10. Arte nesta fase
O Artista de Personagens está refazendo os sprites de todos os personagens em paralelo. Por isso:
- **A Fase 4 não depende de arte nova de personagem.** O auto-soco usa o rig e o jab que já existem. Se os sprites novos chegarem no meio da fase, eles entram sem mudar nada na lógica.
- **Arte nova permitida, no máximo:** o **ícone ou prop do Metrônomo** (prateleira da garagem e loja), os **ícones dos nós** e a moldura da tela da árvore. Placeholder do estúdio vale.
- A regra do rig vale do mesmo jeito: a luva do auto-soco é a mesma do cursor e da luta.

## O que fica de fora (e onde entra)
| Item | Fase |
|---|---|
| Ramo Linhagem: desbloquear arte, escolher arte no início | Fase 5 |
| Começar com geradores, com dinheiro ou na academia de bairro | Fase 7 (ramo Linhagem) |
| Segunda arte e híbridos | Fase 7 |
| Mudança de local, academia de bairro, artes, aparelho assinatura | Fase 5 |
| Versões visuais do Metrônomo por local (rádio da academia, tambor do templo) | Fases 5 e 8 |
| Nó de Linhagem que melhora o ritmo inicial do Metrônomo | Fase 7 (só se fizer falta) |
| Mais luvas e itens de loja (luva de marca, bandagem, tênis, dieta) | Fase 5 em diante |
| Escadas regional e nacional, patrocínio, fama que desbloqueia | Fase 6 |
| Rival recorrente, mentor que fala, histórico da linhagem, fotos dos mentores na garagem | Fase 8 |
| Reembolso ou redistribuição dos nós da árvore | Fase 9, se o balanço pedir |
| Metrônomo e geradores no progresso offline | Fase 9 |
| Clique opcional durante a luta | Fase 9, se o dono quiser |
| Opção de desligar tremida e volume | Fase 9 |
| Conquistas | Fase 9 |
| Abrir a árvore no meio da carreira | sem fase (só se o dono pedir) |

## Critérios de aceite (verificáveis)

**Árvore**
1. Da tela de fim (derrota ou aposentadoria), **1 clique** abre a árvore, que mostra o Legado disponível e todos os nós com nome, efeito em número, preço e estado.
2. A árvore tem **8 a 12 nós**, só nos ramos Corpo e Carreira, incluindo a **Memória muscular** e a **prévia detalhada**. Nenhum nó de Linhagem, arte ou local aparece, nem trancado.
3. Comprar um nó custa 1 clique, desconta o Legado exato do `data/` e recusa sem saldo ou sem o nó anterior. Comprar nunca deixa o Legado negativo.
4. A árvore **não abre durante a carreira** (nenhum botão na garagem, na prévia ou na luta leva até ela).
5. Sem comprar nada, da tela de fim à garagem continuam bastando **2 cliques no máximo**. Com a árvore no caminho, **no máximo 3 cliques** além das compras.

**Preços (medidos no simulador e no QA)**
6. **A 1ª derrota típica compra algo:** existe nó de preço ≤ Legado da derrota no Brutão, e pelo menos 2 nós, em ramos diferentes, custam ≤ o Legado da derrota no Dinho.
7. **Uma aposentadoria com cinturão compra no máximo ~50% do custo total** da árvore.
8. **O robô típico completa a árvore entre a 5ª e a 8ª carreira.** Nem antes, nem nunca.

**Bônus visíveis**
9. No início de toda carreira com nós comprados aparece o cartão "o que você trouxe", com o efeito de cada nó em número. Ele some sozinho em até 2 s ou com 1 clique, e não bloqueia o alvo depois disso.
10. **Cada nó tem efeito conferível na tela** da carreira seguinte. O QA compra cada nó num save isolado e acha o efeito: número do clique, por-clique do painel, prêmio da prévia, porcentagem da prévia, Metrônomo tocando no minuto 0. 100% dos nós.
11. Teste automático: cada nó muda exatamente o valor que promete, só na carreira seguinte à compra, e fechar e reabrir não duplica o efeito.

**Metrônomo**
12. O Metrônomo está na LOJA, e o 1º nível cabe no prêmio de **no máximo 2 vitórias**. Cada nível acelera o ritmo, e o efeito ("1 SOCO A CADA X S") está escrito no item.
13. Cada auto-soco **passa pelo caminho do clique**: com a luva de lona o treino dele dobra, o crítico acontece na mesma taxa do clique do jogador (conferido em 1.000 socos) e o treino vai para o atributo em foco.
14. O auto-soco **não faz a tela tremer**, mostra número menor que o do jogador, tem som mais baixo e anima o lutador (jab do rig) com a mesma luva do cursor.
15. **Ritmo máximo ≤ 1,5 soco/s.** No simulador, um jogador típico (4–5 cliques/s) com o Metrônomo no máximo ganha **pelo menos 2,5 vezes** o treino de clique de quem não clica e só usa o Metrônomo.
16. **Não soca na luta** nem com a tela de fim aberta (o QA conta 0 auto-socos e 0 treino de Metrônomo durante 10 lutas).
17. O Metrônomo zera em NOVA CARREIRA. Com a Memória muscular, a carreira começa no nível 1, e o próximo nível na loja é o 2.

**Revanche e dica**
18. Depois de uma derrota, na carreira seguinte o adversário que venceu aparece com "VOCÊ PERDEU PRA ELE" no HUD e na prévia. Depois de uma aposentadoria não há marca.
19. Vencer esse adversário mostra o momento de revanche na tela de vitória, uma vez só, e a marca some.
20. Em toda derrota que não é azar, a tela de fim diz para voltar quando a prévia **ficar verde**. Na derrota por azar, só a dica de azar aparece.
21. Na prévia contra o adversário da revanche **e contra todo adversário que vem antes dele na escada** (alavanca L1, decisão D2 abaixo) aparece "ESPERE FICAR VERDE" enquanto o risco não for verde. Contra quem vem depois do algoz, e em carreira sem algoz, a linha não aparece. Os limiares de risco são os da Fase 3, e o teste de risco honesto continua passando (fácil ≥ 85%, equilibrado 40–85%, perigoso < 40%).

**Balanço com a árvore (simulador do Designer + QA jogando)**
22. **1ª carreira** (sem nós), jogador típico: termina em derrota em **10–15 min** na mediana. A meta continua aberta pela metade, como na Fase 3 (opção A). O Designer reporta a tabela de novo com o Metrônomo na loja, e a mediana não pode sair da faixa.
23. **Cinturão entre a 2ª e a 4ª carreira** para o robô típico que compra nós (mediana).
    - **23b (revisto pela decisão D1):** cinturão na **1ª carreira** do típico (4–5 cliques/s) em **no máximo 20%** das carreiras e **nunca antes de 20 min**. Medido hoje: 12–16%, aos 22–27 min. (Antes: "nunca antes de 40 min", que é oposto ao critério 24 por construção, `fase4-design.md` §9.7.)
24. **Tempo morto (revisto pela decisão D1):** maior trecho seguido de tempo morto (definição na seção 9), robô típico 4–5 cliques/s:
    - carreiras 2 a 4: **p90 ≤ 10 min**;
    - carreira 1: **mediana ≤ 10 min** e **p90 ≤ 13 min** (é o ~1/3 que vence o Dinho e espera o Seu Muralha; medido hoje 11:01 a 5/s e 12:32 a 4/s).
    Tabela no `fase4-design.md`.
25. **Revanche no simulador:** na 2ª carreira, com o 1º nó comprado e esperando o verde, o robô típico vence quem o derrotou em **≥ 80%** dos casos, contando separadamente o Dinho e o Seu Muralha. O caso do Muralha precisa subir dos 5 de 17 da Fase 3 para pelo menos 60%.

**Critério de sucesso do protótipo (roadmap; fecha nesta fase)**
26. O QA joga **do zero, sem F12**, a 4–5 cliques/s, e cumpre em sequência, cronometrando:
    1. todo clique mostra número no alvo central;
    2. compra geradores e vê a renda passiva subir e a garagem ganhar gente;
    3. perde uma luta e a tela de fim aponta o atributo certo e manda esperar o verde;
    4. compra pelo menos 1 nó;
    5. na carreira seguinte vê o bônus, chega pelo menos tão longe e **vence quem o derrotou**;
    6. ao fim da 2ª carreira há uma próxima meta visível (um nó comprável ou a ≤ 1 carreira de distância, ou o próximo adversário).
    Meta: itens 1 a 5 em **~20 min de jogo somado**, aceitável até **25 min**. Simulador (mediana do típico) **e** QA uma vez jogando.
27. O "quer jogar mais uma" (item 6) fica para o dono confirmar jogando. O relatório ao dono pergunta isso diretamente.

**Save, dados e saúde**
28. Um save v3 da Fase 3 abre na v4 com a carreira intacta, o Legado guardado intacto (ou convertido na mesma escala) e nenhum nó comprado. A cadeia v0 → v4 funciona.
29. Fechar e reabrir em qualquer ponto (árvore aberta, logo depois de comprar, cartão de início, luta, tela de fim) volta a um estado coerente. Não duplica nem perde Legado ou nó.
30. Mudar o preço ou o efeito de um nó, ou o ritmo ou custo do Metrônomo, em `data/` muda o jogo sem mexer em código.
31. `tools/run_tests.ps1` passa inteiro (testes antigos e novos), e o guarda do save real cobre tudo.
32. Uma sessão de 40 min com pelo menos 3 carreiras, sem erro no console. Não aparece nada de arte marcial, mudança de local clicável ou ramo Linhagem.
33. O tempo do clique em LUTAR! não depende do resultado: o QA mede vitória e derrota e não acha diferença perceptível (regressão do ajuste 1 da revisão da Fase 3).

## Riscos de design
- **R1. Legado com números pequenos demais.** Com rendas de 1, 4, 10 e 75, a escala é grossa. Mitigação: o Designer pode reescalar (×10) com migração. A regra são as proporções, não os números.
- **R2. Bônus que acumula.** "+% de Legado" e "+% de dinheiro" compõem carreira após carreira. Mitigação: efeitos aditivos dentro do nó, teto claro e nada multiplicativo entre nós do mesmo tipo. Medir na sequência de 8 carreiras.
- **R3. A árvore acaba e não há mais nada.** Depois do cinturão não há lutas até a Fase 5, e com a árvore completa o protótipo termina. Aceito: o critério 8 põe esse fim entre a 5ª e a 8ª carreira, e ele precisa ser dito ao dono.
- **R4. O Metrônomo ensinar "não precisa clicar".** Mitigação: só entra depois da 1ª vitória (dinheiro), tem teto de 1,5/s, não faz a tela tremer e tem o critério 15. A Memória muscular põe o nível 1 no minuto 0 só a partir da 2ª carreira, quando o jogador já sabe.
- **R5. O Metrônomo inflar o balanço.** É renda nova em cima de um balanço da Fase 3 que só fecha pela metade. Mitigação: o balanço é refeito **uma vez**, com tudo junto. Se a fase passar do tamanho, **o Metrônomo vai para uma 4b** antes de cortar nós (a Memória muscular vai junto).
- **R6. A revanche ficar fácil demais.** Bônus + espera do verde pode transformar a revanche em formalidade. Isso é aceitável: é o momento "agora eu consigo". Não pode é ficar impossível (critério 25).
- **R7. Tempo morto que o Metrônomo esconde.** Com o Metrônomo comprável, a definição de tempo morto ("nada cabe na loja") fica mais rara, mesmo sem a espera mudar. Mitigação: o Designer reporta também o maior trecho em "perigoso" **sem** contar a loja, só para o Diretor ler.
- **R8. Arte em paralelo.** Os sprites de personagem estão sendo refeitos. Mitigação: nada desta fase pede quadro novo de personagem (seção 10). O QA da Fase 4 confere a luva no auto-soco com os sprites que estiverem no projeto.
- **R9. Processo.** O dono não jogou nada desde a Fase 2. Esta fase fecha o protótipo, e o critério 27 só ele responde.

## Decisões para o dono revisar
1. **Dificuldade da Fase 3: opção A assumida** (fica como está e é medida de novo com a árvore). B ou C continuam possíveis depois de jogar.
2. **A árvore só abre entre carreiras**, pela tela de fim. Não dá para ver nem comprar no meio da carreira (dá para ver o resumo dos bônus na garagem).
3. **Sem reembolso de nós** nesta fase.
4. **Preços:** 1º nó custa o Legado de uma derrota no Brutão. O cinturão compra no máximo metade da árvore. A árvore completa sai em 5–8 carreiras.
5. **O Metrônomo zera a cada carreira** (é loja). Só a Memória muscular devolve o nível 1.
6. **Metrônomo ≤ 1,5 soco/s**, sem tremida, e clicar rende pelo menos 2,5× mais. É o "ajudante" da proposta.
7. **Marca de revanche só para a última derrota**, sem histórico.
8. **"Prévia detalhada" (porcentagem) é um nó comprado**, não vem de graça.
9. **Possível reescala do Legado** (ex.: ×10) se o Designer precisar de preços mais finos. O Legado guardado é convertido junto.

## Decisões do Diretor (2026-11-06, depois do design)
- **D1. Critérios 23b e 24 na 1ª carreira: Dinho paga $800, o Seu Muralha não muda, e os dois critérios foram revistos (acima).**
  - Por quê: "nunca cinturão antes de 40 min" pedia ~28 min no vermelho, e isso é exatamente o "ficar esperando" que o dono não quer. Entre os dois, o tempo de espera pesa mais.
  - "Não tão fácil" continua de pé: o cinturão na 1ª carreira só sai para ~1 em 7 jogadores, depois de uma luta de ~45% no amarelo que a prévia avisou. O jogador arriscou e ganhou, então "a luta prova o treino" vale. Isso não é a escada fácil.
  - Recusadas: Dinho $400 (17 min no vermelho); Muralha 430K (ganha só ~1 min, deixa todas as carreiras mais fáceis e mexe num adversário que a decisão A manteve); "aposentar após 10 min no vermelho" (é um comportamento do robô, não uma regra do jogo, e o jogo não pode forçar isso).
  - A aposentadoria continua sendo a saída para quem empaca (com o Dinho vencido, ela rende 200 de Legado). Nesta fase não entra nenhum texto novo empurrando para ela.
- **D2. Alavanca L1 aprovada.** É só texto na prévia, honesto (a cor não muda e o jogador pode lutar do mesmo jeito) e ensina a mesma lição da derrota. Sem ela, o critério 25 cai para o Muralha (22–32%). Regra exata no `fase4-design.md`, "Decisões do Diretor".

## Resumo para o Produtor
A Fase 4 dá destino ao Legado. Uma árvore de 8–12 nós (Corpo e Carreira) abre pela tela de fim, o 1º nó custa o que rende uma derrota no Brutão e os bônus aparecem na tela desde o 1º clique da carreira seguinte. Entra o **Metrônomo** aprovado pelo dono (loja, em dinheiro, socos de verdade, até 1,5/s, sem tremida, fora da luta) e o nó **Memória muscular**.
Para fechar o protótipo, entram a marca "VOCÊ PERDEU PRA ELE", a dica "lute quando ficar verde" e a meta de vencer o algoz na 2ª carreira em ~20 min de jogo somado (até 25). O balanço é refeito uma vez, com tempo morto ≤ 10 min seguidos medido no simulador.
Save v4 com migração da v3, e nenhuma arte nova de personagem (só os ícones do Metrônomo e da árvore). Dificuldade da Fase 3 assumida como opção A, e o dono precisa saber que ainda não jogou nada disso.
