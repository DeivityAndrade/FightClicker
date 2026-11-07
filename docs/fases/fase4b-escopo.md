# Fase 4b — Aparelhos que chegam e modo assistido: escopo

Dono: Diretor de Jogo. Versão 2 (2026-11-06: entra o modo assistido do Shift, seção 11).
Origem: duas ideias do dono.
- "Começa só com o saco e, com o tempo, compra a corda e a esteira, em sequência; entra no ícone que já existe na loja dos três."
- "Com o Shift, liga um autoclique bem menos eficiente que clicar, pensando em quem tem tendinite. Com o Metrônomo comprado, não precisa mais do Shift, e a gente vai upando."
Base: `PROMPT.md`, `docs/visao.md`, `docs/roadmap.md`, `fase2-design.md` (aparelhos, foco, melhorias, aba TREINO paga em Treino), `fase3-design.md` (§2 escada, §7 motivo e dica, §13.2 e §13.7), `fase4-escopo.md`, `fase4-design.md` (§9) e `data/` (`training.json`, `opponents.json`, `shop.json`, `skill_tree.json`).

**Quando:** depois que o dono aprovar a Fase 4. Esta fase **não muda nada do que a Fase 4 entrega** (árvore, Metrônomo, revanche, dica do verde, metas). Ela só mexe no começo da carreira.

## Objetivo
A garagem começa com um aparelho só e ganha os outros dois nos primeiros minutos de cada carreira, comprando com Treino. O começo fica mais simples de entender, e a sala cresce na frente do jogador.
Junto entra um **modo assistido**, ligado com um toque no Shift. Quem não pode clicar muito continua progredindo, só que bem mais devagar que clicando. Ele vira o "nível 0" do Metrônomo.

## Sensação
- **Minuto 0:** "é só eu e o saco". Uma escolha só: bater. Ninguém se perde.
- **Ao comprar o 2º aparelho:** "a garagem está virando academia". O aparelho chega com festa e o lugar vazio da sala é preenchido.
- **Ao comprar o 3º:** "agora tenho tudo pra treinar direito". É aí que o jogador aprende que um atributo só não vence.
- **Nas carreiras seguintes:** é um ritual rápido. Os dois aparelhos chegam em 1 ou 2 minutos, porque o jogador já começa mais forte.
- **Com a mão cansada:** "posso descansar a mão sem largar o jogo". Um toque no Shift e o lutador continua no ritmo, devagar. Quando a mão volta, o clique volta a mandar.
- **Tom:** pé no chão. O aparelho chega como uma coisa de bairro: arrastado da casa do vizinho ou trazido do ferro-velho. Os textos são do Roteirista.

## O que os dados mostram (e muda a ordem)
A ideia funciona. Mas a ordem "corda e depois esteira" bate contra os números da Fase 3:
- **A Resistência (esteira) é o atributo que decide quase toda a escada.** O Brutão pune quem tem pouca Resistência (`fase3-design.md` §2). Contra o Dinho, a melhor dupla é Força + Resistência: 57,5K de treino para chegar a 40%, contra 107K de Força + Agilidade (§13.2). O motivo da derrota do só-saco contra o Dinho dá **Resistência** (§13.7), e a revanche de 95% da Fase 4 segue a dica "esteira".
- **A Agilidade (corda) pesa mais no Seu Muralha** (o QA viu "faltaram 29,5K de Agilidade") e no perfil equilibrado do fim da escada.
- Por isso, a regra do pedido ("corda antes do Dinho, esteira antes do Seu Muralha") **não pode valer**. Se a esteira chegar só depois do Dinho, a dica da derrota mais comum aponta para um aparelho que o jogador não tem, e a revanche da Fase 4 quebra.

**Recomendação do Diretor: saco → esteira → corda.** Pela história também faz sentido: o Brutão bate forte, então primeiro se aprende a aguentar. A agilidade é coisa de quem já está mais adiante.
Se o dono preferir manter **saco → corda → esteira**, a fase funciona do mesmo jeito, com uma condição fixa: **os dois aparelhos precisam estar comprados antes da luta com o Brutão** (ver critérios 8 e 9). Essa condição vale para as duas ordens. A ordem é a pergunta 1.

No resto do documento: **2º aparelho** = o primeiro a ser liberado e **3º aparelho** = o último. Pela recomendação, esteira e corda.

## O que entra

### 1. Desbloqueio em sequência
- Toda carreira nova começa só com o **saco**, que continua sendo o foco padrão.
- O 2º aparelho pode ser comprado desde o minuto 0. O 3º só pode ser comprado depois do 2º: ele aparece com o preço, mas trancado, com a frase "DEPOIS DA ESTEIRA".
- Comprou, o aparelho vale até o fim da carreira. Sem desgaste e sem manutenção.
- As melhorias de um aparelho (fita/óleo/corda sem nó etc.) só aparecem depois que ele é comprado.

### 2. Moeda e lugar: **Treino, na aba TREINO** (decisão do Diretor)
- **Onde:** na seção MELHORIAS da aba TREINO, onde já estão os ícones dos três aparelhos (o "ícone da loja dos três" de que o dono falou). A linha do aparelho trancado mostra o ícone em silhueta com cadeado, o nome, o preço e o botão COMPRAR. Depois da compra, a linha vira as melhorias normais do aparelho.
- **Por que Treino:**
  - É a regra da Fase 2: o que é da garagem custa Treino. O dinheiro é para a LOJA (Nelson, luvas, Metrônomo).
  - O Treino o jogador sempre tem. O dinheiro só vem de vitória, e até o Dudu é zero. Se custasse dinheiro, a esteira só chegaria depois do Dudu ($50) e iria disputar com o Nelson e a luva, que são o coração da economia da Fase 3. Isso também mexeria na definição de tempo morto da Fase 4 (que olha os preços da LOJA).
  - É uma decisão de verdade e pequena: "compro a esteira agora ou a areia peneirada?".
- **Por que não marco de luta** (ex.: vencer o Dudu libera a corda): é de graça e sem escolha, deixa o 1º minuto sem nada para fazer além do saco e prende o aparelho à escada. Se o jogador perde no Dudu, nunca vê a esteira, e a dica dele é justamente Resistência.
- **Preço (o Designer fecha os números):** **fixo**, em `data/training.json`, como o nível 0 da linha do aparelho.
  - Ordem de grandeza: o 2º aparelho sai **entre a fita (300) e o Dudu**, ~1:30–2:30 a 4–5 cliques/s. O 3º sai **antes do Brutão**, ~5–7 min.
  - Na 1ª carreira, o custo somado deve atrasar a curva em **no máximo ~1 min**.

### 3. Na sala (garagem)
- **No lugar de cada aparelho que falta, aparece uma marca no chão:** contorno de fita crepe no lugar exato onde ele vai ficar, com uma plaquinha de papelão escrita à mão com o preço ("ESTEIRA — 1,2K TREINO"). Nada de caixa fechada, que daria a ideia de algo já comprado.
- **Clicar na marca** não dá treino e não troca o foco. Abre a aba TREINO e faz a linha de compra piscar.
- **Ao comprar:** o aparelho chega com juice (cai ou desliza para o lugar, poeira, som, tremida leve), a marca some e o **foco vai para o aparelho novo**, que passa para o centro. O jogador já testa a compra no próximo clique.

### 4. Botão de foco
- O botão de foco trancado continua na mesma fileira e no mesmo tamanho dos outros: ícone em silhueta, cadeado e preço. O 3º mostra "DEPOIS DA ESTEIRA" no lugar do preço até o 2º ser comprado.
- Clicar nele faz o mesmo que clicar na marca do chão (abre a aba e pisca a linha). **A compra acontece num lugar só**, para manter a coisa simples.
- O teclado e os atalhos de foco (se houver) pulam os aparelhos trancados.

### 5. Ajustes nos textos já existentes
- **Painel de atributos:** o atributo de aparelho trancado continua aparecendo (os 10% gerais da Fase 3 fazem ele valer algo na luta), com uma linha "COMPRE A ESTEIRA PARA TREINAR".
- **Dica da tela de fim:** se o atributo decisivo for de um aparelho que o jogador não tinha, a dica diz para comprar o aparelho cedo na próxima carreira (texto do Roteirista). O cálculo do motivo **não muda**.
- **Prévia:** sem mudança. "ELE É MUITO MAIS RÁPIDO" continua honesto mesmo sem a corda.

### 6. Vale por carreira (zera em NOVA CARREIRA)
- **Recomendação:** os aparelhos **zeram** a cada carreira, como a garagem e a loja. A carreira é uma corrida que recomeça do zero, e é isso que dá sentido ao "começa só com o saco". Se o desbloqueio fosse permanente, a ideia aconteceria **uma vez na vida do save** (10 minutos da 1ª carreira) e não acrescentaria nada.
- O ritual não cansa porque as carreiras seguintes já começam mais fortes (Jab de base, Garagem animada) e compram os dois aparelhos em 1–2 min.
- **Sem nó "começa com a esteira" na árvore.** "Começar com X" é ramo Linhagem, que é proibido até a Fase 7 (a Fase 4 já vetou começar com gerador, luva ou dinheiro). Se as carreiras longas mostrarem que o ritual cansa, esse nó entra na Fase 7. Até lá, se precisar, a correção é baixar o preço em `data/`.
- Permanente ou por carreira é a pergunta 2.

### 7. Save v5
- O bloco `career` ganha **os aparelhos comprados** (lista de ids; o saco está sempre presente).
- **Migração v4 → v5:** a carreira em andamento fica com **os três aparelhos liberados** (quem já tem não perde nada, nem foco, nem melhoria). A partir da próxima NOVA CARREIRA, vale a regra nova. Save novo, sem arquivo: só o saco.
- O bloco `permanent` ganha a **preferência do modo assistido** (ligado/desligado). Na migração, ela começa desligada.
- Foco salvo num aparelho que não está comprado (save estragado) volta para o saco.
- A cadeia v0 → v5 funciona, e o guarda do save real continua cobrindo tudo.

### 8. Balanço refeito (Designer, no `fase4_sim.py`)
- O robô compra os aparelhos com uma regra simples e declarada (sugestão: o 2º assim que der, o 3º assim que der depois da areia peneirada). Reportar também a variante "compra só quando a prévia pedir".
- O robô "lê a prévia" só pode alternar para um aparelho que já comprou.
- **Metas da Fase 4 que precisam ser medidas de novo** (nenhuma pode sair da faixa):
  - 1ª derrota em 10–15 min (mediana, 4–5/s);
  - cinturão entre a 2ª e a 4ª carreira; 23b: cinturão na 1ª carreira em ≤ 20% dos casos e nunca antes de 20 min;
  - tempo morto: carreiras 2–4 com p90 ≤ 10 min; carreira 1 com mediana ≤ 10 e p90 ≤ 13 min;
  - revanche (com a L1, contados separados): **Dinho ≥ 80% e Muralha ≥ 60%**, a mesma meta do critério 25 da Fase 4 (esclarecido na revisão, B5);
  - protótipo em ~20 min (aceitável até 25);
  - árvore completa entre a 5ª e a 8ª carreira.
- **Metas antigas que podem ser afetadas:** 1ª melhoria ≤ 3:00 e tio em 5–8 min (Fase 2); 1ª vitória em 2–5 min (Fase 3).
- O que eu espero: pouca mudança. O robô típico já treina só no saco até o Brutão. O risco está no Treino gasto, que atrasa a areia e o tio, e no jogador lento (3/s).
- Pode mexer: preços dos dois aparelhos. **Não pode mexer:** adversários, limiares de risco, árvore e Metrônomo. Se fechar só mexendo neles, o Designer volta ao Diretor antes.

### 9. Arte (Diretor de Arte; placeholder do estúdio vale)
- Marca de fita crepe no chão para os dois aparelhos, no tamanho de cada um, e a plaquinha de papelão.
- Ícone de silhueta com cadeado para cada aparelho (botão de foco e linha da aba TREINO).
- Efeito curto de chegada (poeira e queda), reaproveitando partículas que já existem, se houver.
- **Nada de personagem novo.** O Artista de Personagens não entra nesta fase.

### 10. UI (Designer UI/UX)
- Linha de compra do aparelho na seção MELHORIAS, botão de foco trancado e piscada da linha.
- Passa pela skill `alinhamento-ui` até **0 problemas**: o botão trancado com preço cabe no mesmo tamanho dos outros, a fileira continua igual e o texto não é cortado.

### 11. Modo assistido (Shift): o "nível 0" do Metrônomo
É um requisito de **acessibilidade** (tendinite e mão cansada), não um item de economia. Por isso tem de ser simples e não pode virar um bônus que todo mundo liga.

**Decisões do Diretor** (partem da recomendação do Produtor, com dois ajustes, marcados com ★):
1. **Liga e desliga com um toque no Shift.** Segurar também liga, e o modo continua ligado depois de soltar: ninguém precisa ficar segurando a tecla (segurar é justamente o que machuca). Cada aperto alterna uma vez. A repetição automática da tecla presa não conta.
   - Na tela, um **indicador pequeno e clicável** perto do foco ("ASSISTIDO: SHIFT"). Clicar nele também liga e desliga, então quem só usa o mouse também tem acesso.
2. **De graça e desde o minuto 0 de toda carreira.** Ritmo **mais lento que o Metrônomo nível 1** (que é 1 soco a cada 2 s). Ponto de partida: **1 soco a cada 3 s**, e o Designer ajusta, sem nunca ficar igual ou mais rápido que o nível 1.
3. **Segue as mesmas regras do auto-soco do Metrônomo** (`fase4-escopo.md` §5): passa pelo caminho do clique (aparelho em foco × melhorias × luva, crítico), número menor, sem tremida, som baixo, o lutador faz o jab do rig. **Não funciona** na luta, na prévia, na tela de fim, na árvore nem com o cartão de início aberto.
4. ★ **Só soca com a mão parada:** se o jogador clicou (ou apertou Espaço) há menos de **1 s**, o modo assistido espera. É ajuda para quem descansa a mão, **não soma** com o clique.
   - Sem essa regra, todo jogador ligaria o Shift e clicaria por cima. Isso seria um Metrônomo grátis no minuto 0, mexeria em todas as metas da Fase 4 e deixaria a Memória muscular sem graça.
   - Com essa regra, o jogador que clica sem parar (o robô típico) **não ganha nada**, e o balanço da Fase 4 fica igual.
5. **Com o Metrônomo comprado, o modo assistido some** (não empilha). O Metrônomo já soca sozinho, sem Shift, e soma com o clique, como na Fase 4. O indicador passa a dizer que o Metrônomo está tocando.
   - Os níveis do Metrônomo são o "ir upando" de que o dono falou. Na LOJA, o item mostra o modo assistido como o nível atual ("AGORA: 1 SOCO A CADA 3 S, SÓ COM SHIFT").
   - Com a Memória muscular, a carreira já começa com o Metrônomo, e o modo assistido nem aparece.
6. ★ **A escolha fica guardada como preferência**, no bloco `permanent` do save: quem ligou não precisa ligar de novo a cada carreira ou ao reabrir o jogo. Save novo começa com ele desligado.
7. **Fica para a Fase 9 (opções):** trocar a tecla, opção no menu e o modo assistido no progresso offline (ele não conta offline).

**O que o Designer simula** (no `fase4_sim.py`, junto da seção 8):
- **Perfil "só assistido":** não clica nunca, liga o Shift no minuto 0, compra geradores, aparelhos e loja pela regra do robô, e compra o Metrônomo quando puder. Reportar quando vence o Dudu, o Brutão e o Dinho (ou onde trava) e o tempo morto. **Não é meta de dificuldade**, é para o dono saber como fica a experiência dessa pessoa. Única exigência: ela vence pelo menos o Dudu sem clicar (critério 24).
- **Perfil "misto":** clica 4/s em blocos de 2 min e descansa 1 min com o assistido. Mostra o quanto o descanso custa.
- **Conferir que o típico (4–5/s, sem parar) dá exatamente o mesmo resultado da Fase 4** com o modo assistido ligado (a regra da mão parada zera o efeito).
- **Eficiência:** o treino de clique do típico (4–5/s) precisa ser **≥ 8×** o do "só assistido" antes do Metrônomo (com 1 soco a cada 3 s dá ~12–15×).

## O que fica de fora (e onde entra)
| Item | Fase |
|---|---|
| Nó da árvore "começa com a esteira/corda" | Fase 7 (Linhagem), só se fizer falta |
| Aparelhos em versão nova na academia de bairro | Fase 5 |
| Aparelho assinatura da arte marcial (pode usar o mesmo padrão de "marca no chão") | Fase 5 |
| Mais aparelhos ou um 3º nível de melhoria | Fase 5 em diante |
| Aparelho comprado com dinheiro ou ganho por vitória | sem fase (decidido aqui: Treino) |
| Garagem com marcas dos mentores anteriores | Fase 8 |
| Progresso offline (inclusive modo assistido e Metrônomo) | Fase 9 |
| Trocar a tecla do modo assistido, opção no menu, outras opções de acessibilidade | Fase 9 |
| Nó da árvore que melhora o modo assistido | sem fase (o "upar" é o Metrônomo) |

## Critérios de aceite (verificáveis)

**Desbloqueio**
1. Save novo e toda NOVA CARREIRA: só o saco está montado. O foco é o saco, e a sala mostra as duas marcas de fita com a plaquinha de preço.
2. O 2º aparelho pode ser comprado desde o minuto 0. O 3º aparece com o preço e "DEPOIS DA [2º]" e **recusa a compra** até o 2º ser comprado.
3. A compra custa 1 clique na aba TREINO, desconta o Treino exato do `data/`, nunca deixa o saldo negativo e **não reduz nenhum atributo**.
4. Ao comprar: o aparelho aparece na sala com efeito de chegada, a marca some, o foco vai para ele e o próximo clique treina o atributo novo.
5. Clicar na marca do chão ou no botão de foco trancado não dá treino, não troca o foco e abre a aba TREINO com a linha de compra piscando.
6. Aparelho trancado não aparece como foco possível em lugar nenhum. As melhorias dele só aparecem depois da compra.
7. NOVA CARREIRA volta a trancar os dois aparelhos (depois de derrota e de aposentadoria).

**Tempo (simulador + QA jogando, 1ª carreira, sem nós)**
8. A 4–5 cliques/s, o 2º aparelho é comprado em **≤ 3 min** e o 3º **antes da luta com o Brutão** em ≥ 90% das carreiras (mediana ≤ 8 min).
9. O lento (3/s) tem os dois aparelhos antes da luta com o Dinho em ≥ 90% das carreiras.
10. Da 2ª carreira em diante, com os nós que a derrota típica compra, os dois aparelhos chegam em **≤ 2 min na mediana e no p90, a 4–5/s**. Lento (3/s): **p90 ≤ 2:30**. Quem não ganhou nós (ex.: perdeu no Dudu) leva **no máximo o tempo da 1ª carreira**. (Texto revisto na revisão, B4.)

**Metas que não podem quebrar** (refeitas no `fase4_sim.py` e no QA)
11. Todas as metas da seção 8 continuam na faixa: critérios 22, 23, 23b, 24, 25, 26 e 8 da Fase 4, 1ª melhoria ≤ 3:00 e tio em 5–8 min, e 1ª vitória em 2–5 min. A tabela antes/depois vai no `fase4b-design.md`.
12. A dica da tela de fim nunca manda treinar num aparelho sem dizer como consegui-lo. Se o decisivo for de um aparelho não comprado, o texto manda comprar.

**Save, dados e saúde**
13. Um save v4 com carreira em andamento abre na v5 com os 3 aparelhos, o foco, as melhorias e o Treino intactos. A próxima NOVA CARREIRA começa só com o saco. A cadeia v0 → v5 funciona.
14. Fechar e reabrir logo depois de comprar um aparelho volta com ele comprado e o Treino descontado uma vez só.
15. Mudar o preço de um aparelho em `data/` muda o jogo sem mexer em código.
16. `tools/run_tests.ps1` passa inteiro. Testes antigos que assumem os 3 aparelhos no minuto 0 são ajustados para comprar ou liberar antes, sem perder o que conferiam. O guarda do save real cobre tudo.
17. O verificador de alinhamento (`tools/ui/ui_audit.gd`) dá **0 problemas** com 1, 2 e 3 aparelhos comprados.
18. Uma sessão de 30 min com 2 carreiras, sem erro no console.

**Modo assistido (Shift)**
19. Um toque no Shift liga, outro desliga. Segurar o Shift por 5 s alterna **uma vez só**, e o modo continua ligado depois de soltar. Clicar no indicador faz o mesmo. O indicador sempre mostra o estado certo.
20. Ligado, sem clicar, o lutador dá 1 auto-soco a cada **X s** do `data/` (X > intervalo do Metrônomo nível 1), pelo caminho do clique: com a luva de lona o treino dobra, o crítico sai na taxa do clique (conferido em 1.000 socos) e o treino vai para o atributo em foco. Sem tremida, número menor e som mais baixo.
21. **Mão parada:** clicando 4–5 vezes por segundo com o modo ligado, o QA conta **0 auto-socos** do modo assistido. Ao parar de clicar, o 1º auto-soco sai depois de 1 s ou mais.
22. Com o Metrônomo nível 1 ou mais (comprado ou pela Memória muscular), o modo assistido não soca. Só o Metrônomo soca, no ritmo dele, e o Shift não muda nada no treino.
23. Não soca na luta, na prévia, na tela de fim, na árvore nem com o cartão de início aberto: o QA conta 0 auto-socos em 5 lutas com o modo ligado.
24. O simulador mostra o perfil "só assistido" vencendo pelo menos o Dudu sem clicar, com a tabela de marcos no `fase4b-design.md`. O típico (4–5/s) rende **≥ 8×** mais treino de clique que ele antes do Metrônomo.
25. O resultado do robô típico da Fase 4 (4–5/s, sem parar) é **igual** com o modo ligado e desligado.
26. A preferência sobrevive a NOVA CARREIRA e a fechar e reabrir o jogo. Save novo e migração v4 → v5 começam com ela desligada.
27. Mudar o intervalo do modo assistido ou a janela de "mão parada" em `data/` muda o jogo sem mexer em código.

## Riscos de design
- **R1. Ordem errada quebra a revanche.** Se o aparelho da Resistência chegar tarde, a derrota típica (Dinho) aponta para algo que o jogador não tinha. Mitigação: a recomendação da ordem e a regra "os dois antes do Brutão" (critério 8).
- **R2. Compra sem valor visível.** Comprar um aparelho não sobe nenhum número na hora, diferente de uma melhoria. Mitigação: chegada com juice, foco automático no aparelho novo e a prévia do Brutão/Dinho mostrando que ele importa.
- **R3. Ritual repetido cansa.** Na 6ª carreira, comprar os dois de novo pode virar burocracia. Mitigação: preço fixo e baixo, que as carreiras fortes pagam em segundos. Se cansar, o nó da Fase 7.
- **R4. Atraso na curva do lento (3/s).** O Treino gasto atrasa a areia e o tio. Mitigação: critério 9 e preço ajustável.
- **R5. Mexer depois do QA da Fase 4.** Fase 4 aprovada é a base. A 4b mexe em foco, sala, save e testes que a Fase 4 acabou de fechar. Mitigação: começar só depois da aprovação da Fase 4 e rodar a bateria de testes inteira (critério 16).
- **R6. Tamanho.** Parece pequena, mas toca em sala, botões, aba, save, dica e simulador. Se crescer, o que sai primeiro é o efeito de chegada caprichado (fica uma troca simples de sprite), não o critério de tempo. As duas partes (aparelhos e modo assistido) são **independentes**: podem ser feitas em paralelo, e se uma atrasar a outra é entregue sozinha.
- **R7. O modo assistido ensinar "não precisa clicar".** É o mesmo risco R4 da Fase 4. Mitigação: ritmo abaixo do Metrônomo 1, regra da mão parada (não soma com o clique) e critério 24 (≥ 8×). Quem clica sempre ganha mais. Quem não pode clicar não fica de fora.
- **R8. Assistido fraco demais para quem precisa dele.** Com 1 soco a cada 3 s, quem não clica vai devagar e pode travar no Brutão ou no Dinho. É aceito: o pedido do dono é "bem menos eficiente". A tabela do perfil "só assistido" vai para o dono, e o ritmo é um número em `data/`. Se ele achar pesado demais, ajusta depois de ver.
- **R9. Shift em conflito com outras teclas.** Hoje Espaço treina, F11 é tela cheia e F12 é depuração, e nada usa o Shift. O Programador confere que Shift + clique e Shift + Espaço não fazem nada estranho.

## Perguntas para o dono
1. **Ordem dos aparelhos:** a sua ideia foi "corda e depois esteira". Os números mostram que a esteira (Resistência) é o que mais decide as lutas contra o Brutão e o Dinho. **Recomendo saco → esteira → corda.** Se preferir a sua ordem, funciona também, mas os dois aparelhos ficam baratos o bastante para chegar antes do Brutão.
2. **Zera a cada carreira ou é para sempre?** **Recomendo zerar**: toda carreira começa só com o saco e compra os dois em poucos minutos. Para sempre, a novidade acontece uma vez só, na 1ª carreira, e some.

## Resumo para o Produtor
A ideia do dono vira uma Fase 4b pequena, depois da aprovação da Fase 4. Cada carreira começa só com o saco, e os outros dois aparelhos são comprados **com Treino, na aba TREINO** (no ícone dos três que ele citou). A sala mostra uma marca de fita crepe com o preço no lugar de cada um, e o botão de foco aparece trancado com cadeado e preço.
Os dados da Fase 3 mostram que a esteira (Resistência) decide as lutas do Brutão e do Dinho. Por isso recomendo a ordem **saco → esteira → corda**, com os dois aparelhos comprados antes do Brutão. Na ordem do dono, a dica da derrota mais comum apontaria para um aparelho que o jogador ainda não tem.
Recomendo que zere a cada carreira, sem nó na árvore (isso seria Linhagem, da Fase 7). O Designer refaz as metas da Fase 4 no simulador, e saves com carreira em andamento ficam com os 3 aparelhos.
Entra também o **modo assistido**: um toque no Shift (ou clique no indicador) liga e desliga, sem precisar segurar. É de graça e soca devagar (1 a cada 3 s) pelo caminho do clique, só quando a mão está parada, então nunca soma com o clique. Com o Metrônomo comprado ele some, e os níveis do Metrônomo são o "upar". Trocar a tecla fica para as opções da Fase 9.
Duas perguntas ao dono: a ordem e se zera ou é para sempre. O modo assistido vai como decisão do Diretor para ele revisar.

---

## Respostas do dono (2026-11-06) — valem sobre o texto acima
1. **Ordem dos aparelhos:** saco → **esteira** → **corda** (recomendação do Diretor aceita).
2. **Aparelhos zeram a cada carreira** (só a árvore é permanente).
3. **Modo assistido: só segurando o Shift.** Não é liga/desliga: soca enquanto o Shift estiver pressionado e para ao soltar. Motivo do dono: depois que compra o Metrônomo a pessoa para de usar o Shift, e segurar ajuda a não "quebrar" o jogo. Remover o toque-para-ligar, a preferência salva em `permanent` e o indicador de "ligado" (pode haver uma dica "SEGURE SHIFT: TREINO ASSISTIDO" e um indicador enquanto estiver ativo, e o botão clicável para quem só usa mouse vira "segurar o botão"). As demais regras do Diretor (mais lento que o Metrônomo nível 1, só com a mão parada há 1 s, não funciona na luta/prévia/fim/árvore/cartão, some com o Metrônomo comprado) continuam.

---

## Decisão do Diretor (23b) — 2026-11-06
**Aceito, com a meta reescrita.** O 23b da 4b passa a ser:
- cinturão na 1ª carreira **≤ 20% a 5 cliques/s** e **≤ 25% a 4 cliques/s** (400 jogadores);
- **nunca antes de 20:00** (sem mudança);
- mediana do cinturão continua **na 2ª carreira** (23a, sem mudança).

Por quê:
- O objetivo do 23b é "a 1ª carreira quase sempre termina em derrota e ensina a árvore". Com 75% a 4/s e 83% a 5/s perdendo, isso continua valendo.
- A causa é boa: o jogador para de perder "à toa" no Dudu (34 → 4 de 400) porque comprou a esteira. Punir isso seria remar contra a fase.
- Quem leva o cinturão na 1ª o faz tarde (≥ 23:51, típico ≥ 27 min) e numa luta apertada (~45%): sensação de façanha, não de jogo fácil.
- As alternativas pioram o jogo: preço dos aparelhos é ruído; Muralha mais resistente quebra o tempo morto (critério 24), que pesa mais para o jogador.

Trava: se uma fase futura levar o 4/s acima de 25%, o 5/s acima de 20% ou o mais cedo para antes de 20:00, volta ao Diretor (regra D1 continua). O critério 11 desta fase usa esta meta nova.

---

## Decisões do Diretor na revisão — 2026-11-06
**B4 (critério 10): aceito o texto do Designer, sem mudar número.** O critério 10 acima já está reescrito.
- Medido: 5/s 1:05 / 1:20 (mediana / p90), 4/s 1:18 / 1:36, 3/s p90 2:21. Pior caso 2:45 (5/s) e 4:42 (3/s): é quem perdeu no Dudu sem nós, e a carreira 2 dele é igual à 1ª.
- A intenção do critério ("nas carreiras seguintes é um ritual rápido") vale para quem ganhou alguma coisa na carreira anterior. Quem não ganhou nada não tem por que ser mais rápido que na 1ª.
- Baratear a corda (~1.100) para fechar o 3/s em 2:00 mexeria nos critérios 8 e 9 e no 23b, que está com margem curta. Não vale o risco.
- Trava: se uma fase futura levar o p90 de 4–5/s acima de 2:00 ou o de 3/s acima de 2:30, volta ao Diretor.

**B5 (revanche): o texto da seção 8 estava errado, os números não.** A meta é a do critério 25 da Fase 4: **Dinho ≥ 80% e Muralha ≥ 60%**, com a L1. A 4b dá Dinho 92–93% e Muralha 79–94%, melhor que a Fase 4 (Muralha 74–89%). Corrigido na seção 8.
