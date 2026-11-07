# Fase 3 — Lutas e fim de carreira: escopo

Dono: Diretor de Jogo. Versão 1 (2026-11-05).
Base: `PROMPT.md`, `docs/visao.md` (decisões do dono + "Assumido pelo estúdio"), `docs/roadmap.md`, `docs/fases/fase2-escopo.md`, `fase2-design.md`, `fase2-api.md`, `fase2-revisao.md` (riscos R1–R8), `docs/arte/direcao-visual.md`, `docs/narrativa.md` e o código atual (`scripts/game_state.gd`, `scripts/save_store.gd`, `tests/test_real_save_guard.gd`).

**Aviso de processo:** o dono está trabalhando e delegou as decisões ao estúdio. Este plano vai ser implementado **sem a aprovação prévia dele**. Por isso o escopo é conservador: uma escada só, uma arena só, o mínimo de coisas pagas em dinheiro e nada das Fases 4+. Tudo o que é decisão de design que ele pode querer mudar está em "Decisões para o dono revisar", no fim. Os números ficam em `data/`, então mudar de ideia não exige refazer código.

## Objetivo
Dar sentido aos atributos: o jogador escolhe quando lutar, vê a prévia com o risco, escolhe a tática e assiste a uma luta curta decidida pelos números. Vencer traz dinheiro, fama e Legado em jogo. Perder encerra a carreira, explica o motivo e manda o jogador de volta para a garagem com o Legado guardado.

## Sensação
- **Antes da luta:** "dá para encarar ou é cedo?". A prévia mostra os atributos dele e os seus lado a lado, e o risco aparece na cor.
- **Durante a luta:** "meu treino está batendo nele". Socos, esquivas, críticos e a barra de vida caindo, em poucos segundos.
- **Na vitória:** "valeu a pena". O dinheiro cai e o Legado em jogo sobe. Dá vontade de arriscar a próxima ou de pendurar as luvas.
- **Na derrota:** "doeu, mas eu sei o que faltou". Nunca "o jogo me roubou".
- **Tom:** luta clandestina de bairro, valendo pouco dinheiro. Pé no chão, meio melancólico, com o humor seco da garagem. Nada de glamour ainda.

## Respostas assumidas pelo estúdio (dono pode revisar)
Registradas em `docs/visao.md`, "Assumido pelo estúdio":
1. **A garagem continua paga em Treino**, para sempre. O dinheiro vem **só das lutas** e compra só o que se compra com dinheiro (lista abaixo).
2. **A tremida continua em todo clique**, leve. A opção de desligar fica para a Fase 9.

## O que entra

### 1. Escada amadora (1ª camada)
- **4 adversários em ordem fixa.** Cada vitória libera o próximo. O 4º é a luta pelo **cinturão amador**.
- **Perfis diferentes**, para que treinar um atributo só perca (risco R1):
  1. **Aquecimento:** equilibrado e fraco. É a luta que ensina a tela. Dá para vencer com treino só de garagem nos primeiros minutos.
  2. **Forte:** muita Força. Pune quem não tem Resistência.
  3. **Rápido:** muita Agilidade, esquiva e acerta crítico. Pune quem só tem Força e não acerta nele.
  4. **Resistente (cinturão):** muita vida. Pune quem não tem dano, e é o mais forte dos quatro.
- Ordem e números com o Designer. A regra é que **nenhum foco único** vença os 4 com a mesma eficiência, e que os perfis sejam visíveis na prévia.
- **Nome, apelido e uma linha de descrição** para cada um (Roteirista). Sem diálogo, sem rival (Fase 8).
- Depois do cinturão **não há mais lutas nesta fase**. A tela mostra "Academia de bairro liberada", com o aviso de que a mudança chega numa versão futura (Fase 5). Aposentar passa a ser a jogada natural.

### 2. Efeito dos atributos (só na luta)
- **Força:** dano. **Agilidade:** chance de crítico e de esquiva. **Resistência:** vida e redução de dano (PROMPT §5.2).
- Fórmulas com o Designer, em `data/`. Precisam ser **legíveis** para que a tela de fim consiga dizer "faltaram N de X".
- Na garagem nada muda: o clique e o crítico de clique continuam como na Fase 2.

### 3. Prévia da luta (ELE x VOCÊ)
- O botão **LUTAR!** fica sempre disponível entre lutas e abre a prévia: nome e perfil dele, os 3 atributos dele ao lado dos seus e o **indicador de risco** (fácil / equilibrado / perigoso, nas cores verde / amarelo / vermelho).
- Destaque no atributo em que ele está mais à frente de você ("ele é muito mais forte").
- Mostra o que está em jogo: prêmio em dinheiro e fama se vencer; "perder encerra a carreira e você leva só metade do Legado".
- **A tática é escolhida na prévia, e o risco se recalcula na hora** ao trocar de tática. Assim o jogador vê o efeito da escolha.
- Botões: **LUTAR** e **VOLTAR A TREINAR**. Voltar é grátis e não custa nada.
- O risco tem que ser **honesto** (ver critérios). A prévia mostra os números dos atributos e o rótulo de risco, **sem a porcentagem exata** de vitória (a prévia mais detalhada é um nó da árvore, Fase 4).

### 4. Escolha tática
- **Agressivo / Defensivo / Contra-ataque**, como modificadores simples (por exemplo: mais dano e menos defesa; menos dano e mais redução; mais esquiva e dano extra depois de uma esquiva).
- Regra de design: **cada tática é a melhor escolha contra pelo menos um adversário da escada**. Nenhuma tática domina as outras.
- Uma linha de texto por tática dizendo o que ela faz, sem jargão.

### 5. Simulação automática
- Resolvida pelos números, sem reflexo e sem input do jogador. Dura de **8 a 20 segundos**.
- Tem limite de tempo, e luta nunca fica infinita. Se o tempo acabar, **vence quem tiver mais % de vida** (pontos). Empate exato fica com o Designer, desde que a regra seja clara e esteja escrita na tela de fim.
- A luta usa um **sorteio com semente**, definido quando a luta começa. O mesmo estado e a mesma semente dão o mesmo resultado (para teste e contra truque de fechar o jogo).
- **Fechar o jogo no meio da luta não salva da derrota:** o resultado já fica decidido e salvo quando a luta começa. Ao reabrir, o jogo vai para o resultado.
- Os rounds, se existirem, são só um marcador de tempo ("caiu no 2º round"). Não é um sistema novo.

### 6. Tela da luta (arena)
- **Uma arena só** para as 4 lutas, por exemplo um pátio ou galpão de bairro à noite. Local e arte com o Diretor de Arte: mesma resolução (640x360), mesma paleta e mesmas regras. Identidade própria.
- **Barras de vida** dos dois, nomes e a tática escolhida.
- **Impacto visual:** número de dano flutuando (crítico maior, em `r3`, com "!"), "ESQUIVOU" na esquiva, tremida leve em golpe forte, traços de impacto e som de soco (aproveitar o juice da Fase 2).
- **Animações acompanham a simulação** (lutador e adversários articulados em partes, como na garagem): golpe, esquiva, recebeu golpe, crítico, queda (K.O.) e vitória. Imagem parada não serve.
- **A luva do jogador na luta é a mesma da garagem e do cursor** (risco R7).
- 4 adversários com silhueta e cor distintas. Placeholder feito pelo estúdio vale.

### 7. Vitória
- Rende **dinheiro** e **fama**, e aumenta o **Legado em jogo** (o pote da carreira).
- O cinturão amador dá um bônus de Legado em jogo e marca a carreira.
- Volta para a garagem com um resumo curto (ganhos e próximo adversário).
- Fama nesta fase só **conta**: aparece no HUD e entra no Legado. Fama que desbloqueia coisas (patrocínio) é da Fase 6.

### 8. Derrota = fim da carreira
- **Tela de fim de carreira**, que sempre mostra:
  - quem venceu e quando ("caiu no 2º round", "perdeu por pontos");
  - **o motivo principal em número**, comparando os atributos ("faltaram 120 de Resistência: ele tirou 60% da sua vida em 4 golpes");
  - **uma dica de ação** ("treine na esteira") que bate com o motivo;
  - resumo da carreira: vitórias, dinheiro e fama ganhos, tempo de jogo;
  - **Legado ganho = 50% do pote**, e o Legado total guardado.
- Botão **NOVA CARREIRA**: volta para a garagem do zero (treino, atributos, geradores, melhorias, dinheiro, fama e escada zerados). O Legado fica. O contador sobe ("Carreira 2").
- **Derrota não dá dinheiro** (o dinheiro se perderia junto com a carreira). O "não frustrar" do PROMPT vem da explicação e do Legado.
- O Legado **ainda não tem onde ser gasto** (a árvore é a Fase 4). A tela diz isso com uma frase curta e honesta, sem botão desativado.

### 9. Aposentar
- Botão **APOSENTAR**, disponível **entre lutas, a qualquer momento** (nunca durante a luta nem na prévia).
- Antes de confirmar mostra o que você leva: **100% do pote**, mais o bônus de "saída por cima" se o cinturão amador foi conquistado nesta carreira. Também avisa que tudo da carreira se perde.
- Aposentar com o pote zerado é permitido: a confirmação diz "você leva 0 de Legado".
- Depois mostra a mesma tela de fim, no modo "saiu por cima", com o botão NOVA CARREIRA.
- Regra fixa: **aposentar sempre rende mais que perder.**

### 10. Dinheiro: o que ele compra nesta fase (o mínimo)
Resolve o "fim de conteúdo" dos 10–15 min (R3) sem inventar melhoria de Treino nova. São só **dois itens**, no painel direito, numa seção "LOJA" separada da garagem:
1. **Um gerador pago** (gente que cobra, por exemplo um treinador de bairro que cobra por hora). Custa dinheiro, com custo exponencial, e produz Treino/s. Aparece treinando na sala como os outros.
2. **Uma linha de luva de loja** (1 ou 2 níveis): multiplica o treino **por clique em todos os aparelhos**. **Troca ao mesmo tempo o sprite do cursor, da mão na garagem e da mão na luta.** Pelo menos 1 sprite de luva novo.
- Mais nada custa dinheiro na Fase 3. A mudança de local não aparece para compra (Fase 5).
- O primeiro item da loja tem que caber no prêmio de **1 ou 2 vitórias**. A decisão interessante é "compro a luva ou o treinador?".

### 11. HUD e telas
- Agora aparecem: **dinheiro** (`y1`), **fama** (`p`), **Legado em jogo** (`p2`), **próxima luta** (nome e risco atual) e **Carreira N**. Os botões **LUTAR!** e **APOSENTAR** ficam na barra de baixo, como no mockup.
- Prévia, fim de carreira e confirmação de aposentar abrem como janela central sobre a sala escurecida (direção visual §2).
- O que não é desta fase continua sem aparecer: árvore, artes, 4º foco e botão de mudar de local.

### 12. Dados, save e testes
- Adversários, táticas, fórmulas de luta, prêmios, Legado, loja e risco ficam em `data/` (JSON), fora do código.
- **Save v3** com dois blocos: `career` (tudo que se perde) e `permanent` (Legado total, número da carreira atual, recordes simples como melhor carreira em vitórias e cinturões ganhos). Também guarda a luta em andamento (semente e adversário).
- **Recomendação:** um arquivo só, para o guarda do save real continuar valendo sem mudança. Se o Programador separar em dois arquivos, **o guarda `test_real_save_guard.gd` tem que fotografar os dois** (R5).
- Migração v2 → v3: a carreira da Fase 2 vira a "Carreira 1" sem perder nada, e o bloco permanente começa zerado.
- O Designer pode **reajustar os preços da garagem** em `data/` para casar com o ritmo das lutas (R4). Sem novos itens de Treino.
- **Testes automáticos novos:** luta determinística com semente; luta sempre termina dentro do limite; derrota zera `career` e mantém `permanent`; Legado na derrota = 50% e na aposentadoria = 100% (+ bônus); aposentar nunca rende menos que perder; prêmio só na vitória; compra em dinheiro desconta e recusa sem saldo; luva muda o clique dos 3 aparelhos; fechar no meio da luta mantém o resultado; migração v2→v3; calibração do risco (abaixo); o guarda do save real continua passando.

## O que fica de fora (e onde entra)
| Item | Fase |
|---|---|
| Árvore de habilidades e gasto de Legado | Fase 4 |
| Prévia mais detalhada (porcentagem de vitória, golpes) | Fase 4 (nó da árvore) |
| Mudança de local, academia de bairro, escolha de arte, 4º foco, técnicas | Fase 5 |
| Mais itens de loja (luvas novas, bandagem, tênis, dieta/suplementos), mais geradores pagos | Fase 5 em diante |
| Escadas regional e nacional, fama que desbloqueia, patrocínio | Fase 6 |
| Escada mundial, segunda arte | Fase 7 |
| Rival, mentor, falas antes das lutas, histórico da linhagem com tela própria, foto do mentor com significado | Fase 8 |
| Clique durante a luta (boost pequeno opcional) | Fase 9, se o dono quiser (ver decisões) |
| Acelerar ou pular a animação da luta | Fase 9 (a luta é curta de propósito) |
| Lesão e cansaço depois de luta difícil | Sem fase. Só se o dono pedir tensão extra, e sempre se recuperando sozinho |
| Revanche contra quem te venceu | Fase 4 (critério do protótipo: vencer na carreira seguinte) |
| Progresso offline, conquistas, opções (desligar tremida, volume) | Fase 9 |
| Nome do lutador escolhido pelo jogador | aberto, sem fase |

## Critérios de aceite (verificáveis)

**Lutar e prévia**
1. Desde o minuto 0, o botão LUTAR! abre a prévia em 1 clique, com os 3 atributos dele e os seus lado a lado, o risco colorido, o prêmio e o aviso "perder encerra a carreira".
2. Trocar de tática na prévia muda o risco **na hora** quando a mudança passa de um limite. O QA acha pelo menos um adversário em que trocar a tática muda o rótulo.
3. **Risco honesto.** Com 500 lutas simuladas por rótulo (estados variados, sementes diferentes): "fácil" vence em ≥ 85%, "equilibrado" fica entre 40% e 85%, "perigoso" vence em < 40%. Teste automático e tabela no `fase3-design.md`.
4. Voltar da prévia não custa nada e não muda nenhum valor.

**A luta**
5. Toda luta dura entre **8 e 20 segundos** de tela e sempre termina (10.000 lutas simuladas, nenhuma passa do limite).
6. Mesma semente e mesmo estado dão o mesmo resultado, golpe por golpe (teste automático).
7. Durante a luta aparecem, ligados ao que a simulação decidiu: barras de vida caindo, número de dano, crítico destacado, "ESQUIVOU", queda no K.O. e pose de vitória. O QA confere 3 lutas quadro a quadro contra o registro da simulação.
8. A luva que aparece nas mãos na luta é a mesma do cursor e da garagem, inclusive depois de comprar a luva de loja.
9. **Nenhum foco único vence a escada inteira.** Na simulação do Designer, o jogador "só saco" perde para um adversário que o jogador "treino equilibrado" vence com o mesmo treino total.
10. **Cada tática é a melhor contra pelo menos 1 dos 4 adversários** (simulação do Designer).
11. Fechar o jogo pelo X no meio da luta e reabrir mostra o **mesmo resultado**. Não dá para escapar da derrota.

**Vitória, derrota e aposentadoria**
12. Vitória: dinheiro, fama e Legado em jogo sobem no valor do `data/`, o próximo adversário é liberado e o HUD mostra tudo na hora.
13. Derrota: a tela de fim mostra **o motivo principal com número**, a dica de ação, o resumo da carreira e o Legado ganho (= 50% do pote, conferido em teste).
14. **O jogador entende por que perdeu.** Em 10 derrotas variadas do QA, a frase de motivo aponta o atributo que de fato decidiu a luta (o que mais mudaria o resultado se tivesse mais), e a dica bate com o motivo. 10 de 10.
15. Da tela de fim até estar clicando de novo na garagem: **no máximo 2 cliques e 10 segundos**. Volta como "Carreira N+1", tudo da carreira zerado e o Legado total intacto.
16. APOSENTAR aparece só entre lutas. Antes de confirmar, mostra quanto vai levar. Leva 100% (+ bônus com cinturão). Em todo estado testado, aposentar rende mais que perder.
17. Depois do cinturão: LUTAR! não abre mais adversários, e a tela mostra o cinturão conquistado e "Academia de bairro liberada (em breve)". Nada de mudança de local fica clicável.

**Dinheiro e loja**
18. O primeiro item da loja dá para comprar com o prêmio de **no máximo 2 vitórias**.
19. A luva de loja multiplica o clique dos 3 aparelhos e troca o cursor, a mão na garagem e a mão na luta **no mesmo instante**.
20. O gerador pago aparece treinando na sala na 1ª compra. Comprar com dinheiro nunca mexe em Treino nem em atributo, e sem dinheiro a compra é recusada.

**Metas de tempo ("não tão fácil", com simulação do Designer + QA jogando)**
21. **1ª vitória entre 2 e 5 minutos** para quem clica a 4–5 cliques/s e luta quando o risco diz "fácil" ou "equilibrado".
22. **A 1ª carreira termina em derrota entre 10 e 15 minutos** para o jogador típico (4–5 cliques/s, foco fixo no saco, luta quando o risco diz "equilibrado"). Vale também para 3 e 8 cliques/s com folga de ±3 min.
23. **O cinturão é possível sem árvore**, mas pede jogo bom: um jogador que treina os 3 atributos, escolhe a tática certa e só luta em "fácil" ou "equilibrado" conquista o cinturão numa carreira de **25 a 40 minutos**. O jogador típico do critério 22 não chega lá na 1ª carreira.
24. Na 2ª carreira, seguindo a dica da tela de fim, o jogador **vence o adversário que o derrotou** (simulação + QA uma vez jogando).

**Dados, save, saúde**
25. Mudar o prêmio ou um atributo de adversário em `data/` e reabrir muda o jogo sem mexer em código.
26. Um save v2 da Fase 2 abre como Carreira 1, com tudo mantido, e o bloco permanente zerado.
27. Fechar e reabrir em qualquer ponto (garagem, prévia, luta, tela de fim, confirmação de aposentar) volta a um estado coerente, sem duplicar nem perder Legado.
28. `tools/run_tests.ps1` passa inteiro (antigos e novos), e o **guarda do save real** cobre todos os arquivos de save que existirem.
29. Uma sessão de 30 minutos com pelo menos 2 carreiras completas e nenhum erro no console. Na Fase 2 nada de luta aparecia na tela; agora o que **não** pode aparecer é árvore, artes e mudança de local clicável.
30. (De passagem, se for barato) a tela da luta lê bem em 1280x720, 1920x1080 e no DPI de 125%.

## Riscos de design
- **R1. "Foco fixo era ótimo, agora perde."** O jogador que aprendeu a garagem pode se sentir enganado. Mitigação: o 1º adversário é ganhável com foco fixo; o 2º já mostra na prévia "ele é muito mais forte que a sua Resistência"; a tela de fim dá número e dica. A lição chega antes do castigo.
- **R2. Calibração na curva real.** Aos 10 min o jogador tem entre 20K e 90K de treino total. Os adversários precisam ser medidos sobre essa curva (3, 5 e 8 cliques/s; foco fixo e rodízio). O Designer deve estender `tools/sim/` e mostrar as tabelas no design.
- **R3. Aleatoriedade parecer injustiça.** Crítico e esquiva podem virar lutas "certas". Mitigação: o risco honesto (critério 3) e o motivo na tela de fim. Se a variação for grande demais, diminuir o peso do sorteio, não esconder.
- **R4. Derrota frustrar demais sem árvore.** Na Fase 3 o Legado ainda não compra nada, então a 1ª derrota pode parecer só castigo. Mitigação: a tela de fim diz que o Legado fica guardado e serve para a próxima versão, e a Fase 4 vem logo em seguida. O relatório ao dono diz isso com todas as letras.
- **R5. Balanço da Fase 3 vai mudar na Fase 4.** Os bônus da árvore vão facilitar o cinturão (meta da visão: 2ª a 4ª carreira com árvore). Os números da Fase 3 são provisórios e ficam todos em `data/`.
- **R6. Jogador paciente "zera" a escada sem risco**, treinando 40 min antes de lutar. Aceito: não existe timer. A pressão vem do dinheiro, que só sai da luta, e do custo exponencial. Não punir quem espera.
- **R7. Escopo de arte.** Arena, 4 adversários articulados e animações de golpe, esquiva, queda e vitória são o maior custo da fase. Placeholder do estúdio vale. Se apertar, reaproveitar o rig do lutador com cores e acessórios diferentes. Nunca imagem parada.
- **R8. Luta longa demais cansa** em carreiras repetidas. Por isso o limite de 8–20 s. Se o QA achar arrastado, encurtar antes de pensar em botão de pular.
- **R9. Mockup adiantando fases** (próximo local, artes). Regra: não aparecem clicáveis.

## Decisões para o dono revisar
Tudo abaixo foi **assumido pelo estúdio** porque o dono não pode aprovar agora. Nada aqui é difícil de mudar: são números em `data/` ou regras pequenas.
1. **Garagem paga em Treino para sempre; dinheiro só das lutas.** (resposta assumida da Fase 2)
2. **Tremida em todo clique**, leve. (resposta assumida da Fase 2)
3. **O dinheiro compra só 2 coisas nesta fase:** 1 gerador pago e 1 linha de luva de loja.
4. **Escada de 4 adversários** (aquecimento, forte, rápido, resistente/cinturão). Depois do cinturão não há mais lutas até a Fase 5/6.
5. **Derrota não dá dinheiro**, só 50% do Legado (o PROMPT antigo dava "um pouco de dinheiro"; com a carreira encerrada, dinheiro não serviria).
6. **Sem clique durante a luta** nesta fase (o PROMPT diz "opcional"). Fica para a Fase 9, se o dono quiser.
7. **Luta no limite de tempo é decidida por pontos** (mais % de vida vence).
8. **Fechar o jogo no meio da luta não evita a derrota.**
9. **Pode se aposentar com 0 vitórias** (leva 0 de Legado, com aviso).
10. **Bônus de "saída por cima" só com o cinturão** (o valor fica com o Designer).
11. **A prévia mostra os atributos exatos e o rótulo de risco, mas não a porcentagem.** A porcentagem fica para um nó da árvore.
12. **Metas de tempo:** 1ª vitória em 2–5 min, 1ª carreira termina em derrota em 10–15 min, cinturão possível sem árvore em 25–40 min só com jogo bom.

## Resumo para o Produtor
A Fase 3 traz a luta: escada amadora de 4 adversários com perfis diferentes, prévia ELE x VOCÊ com risco honesto, tática que muda o risco, luta automática de 8–20 s com barras de vida e animação, e o cinturão no topo.
Derrota encerra a carreira, explica com número o que faltou e guarda 50% do Legado. APOSENTAR entre lutas guarda 100%, e a nova carreira volta para a garagem.
O dinheiro compra só o mínimo: 1 gerador pago e 1 luva de loja, que troca cursor e mão. Save v3 separa carreira de permanente, e o guarda de testes tem que cobrir o novo formato.
Como o dono não aprovou antes, 12 decisões ficaram marcadas para ele revisar. O Legado ainda não tem onde gastar (Fase 4), e isso precisa ser dito a ele com clareza.
