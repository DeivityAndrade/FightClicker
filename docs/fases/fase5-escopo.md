# Fase 5 — Academia de bairro e artes marciais: escopo

Dono: Diretor de Jogo. Versão 1 (2026-11-06).
Base: `PROMPT.md` (§5.7, §5.9), `docs/visao.md` (decisões do dono e "assumido pelo estúdio" 1, 5 e 6), `docs/roadmap.md` (Fase 5), `docs/narrativa.md`, `fase4-revisao.md` (riscos R6 a R10), `fase4b-escopo.md` e `fase4b-revisao.md` (com as respostas do dono), `data/` (`opponents.json`, `shop.json`, `skill_tree.json`, `career.json`).

**Quando:** depois que o dono aprovar a 4b. Antes de começar, as dívidas de dados da Fase 4 (R10) precisam estar fechadas: a tabela do simulador **com** a L1 e a sessão de 40 min jogada.

## Objetivo
O cinturão amador deixa de ser o fim do jogo e passa a ser a porta de saída da garagem. O lutador se muda para a academia de bairro, aprende uma arte marcial, e a partir daí cada carreira começa com uma escolha de estilo que muda a forma de jogar.

## Sensação
- **Ao ganhar o cinturão:** "agora posso sair daqui". A mudança aparece como uma compra cara e desejada, não como uma tela automática.
- **Ao chegar na academia:** "o jogo virou outro". Sala nova, o mesmo saco em versão melhor, gente diferente, e logo a pergunta: "que tipo de lutador você quer ser?"
- **Nas carreiras seguintes:** "desta vez eu vou de Jiu-jitsu". A escolha no começo da carreira vira o "testar outra build" de roguelite.
- **Tom:** realista, com calor humano (narrativa, local 2): mensalidade atrasada, pôster desbotado, espelho trincado. Um degrau acima da garagem, sem ser profissional ainda.

## Decisões do Diretor (o dono pode revisar; as 4 perguntas estão no fim)

### A. A mudança para a academia
- **Libera com o cinturão amador e custa dinheiro ($).** É a regra já assumida na visão (item 5). Nem Fama nem Legado: a Fama ainda não compra nada e o Legado é da árvore, entre carreiras.
- **Preço na ordem do prêmio do Seu Muralha ($1.000),** fechado pelo Designer. A decisão tem que ser real: "mudo agora ou compro mais um Nelson/luva?".
- **Vale por carreira.** Toda carreira começa na garagem (visão: "local de treino volta para a garagem"). Começar já na academia é um nó do ramo Linhagem, **Fase 7**.
- **Mudar nunca tira nada:** geradores, melhorias, aparelhos comprados, luva e Metrônomo vão junto. A mudança dá:
  - um **multiplicador global de treino** (número do Designer);
  - os aparelhos básicos na **versão da academia** (troca de sprite; mesmas melhorias);
  - o acesso às **2 lutas da academia** (seção D).
- Botão MUDAR para a academia aparece no lugar do aviso atual "liberado, chega na Fase 5".

### B. Quais artes entram
- **2 artes: Boxe e Jiu-jitsu.** São os dois polos do PROMPT §5.7: o Boxe premia o clique, o Jiu-jitsu premia a renda passiva. A diferença se sente sem ler número.
- **Muay Thai fica para a Fase 6.** O efeito dele (crítico e combos) fica perto do Boxe, e o orçamento de arte vai para as 2 lutas da academia (risco R8 da Fase 4).
- **Hoje o lutador não tem arte.** O saco, as luvas e o "boxe de rua" da garagem continuam sendo o básico de todo mundo. O Boxe como arte é algo a mais.

### C. Como se escolhe a arte
- **1ª vez:** na chegada à academia (visão, assumido 1). Uma janela simples com as 2 artes, cada uma com o aparelho assinatura, 1 frase de tom e o efeito em número curto.
- **Ao chegar na academia pela 1ª vez, as 2 artes ficam desbloqueadas para sempre** (save `permanent`).
- **Da carreira seguinte em diante:** a escolha acontece no início de toda carreira, antes do cartão "O QUE VOCÊ TROUXE". Pode escolher "sem arte" até a 1ª academia; depois disso a escolha é obrigatória e rápida (1 clique).
- **Vale por carreira e não volta atrás dentro dela.** Trocar de arte = nova carreira. É o que dá peso à escolha (roguelite) e evita "troco de arte antes de cada luta". Sem reembolso, sem respec.

### D. O que cada arte muda
Cada arte mexe em **três coisas, só três**, e todas aparecem na tela:
1. **Aparelho assinatura** = 4º foco (visão): Boxe = saco de velocidade (pera), Jiu-jitsu = boneco de grappling no tatame. Treina os 3 atributos numa proporção da arte (Designer).
2. **Uma regra de curva**, um número em `data/`:
   - **Boxe:** + treino por clique manual (não vale para Metrônomo nem modo assistido: é a arte de quem clica).
   - **Jiu-jitsu:** + treino/s da equipe, e o bônus cresce com o tempo de carreira até um teto (o "escala com o tempo" do PROMPT).
3. **Duas técnicas**, que são as melhorias do aparelho assinatura (mesma linha da aba TREINO, pagas em Treino). Ex.: Boxe "Jab duplo", Jiu-jitsu "Guarda fechada". Nomes do Roteirista, efeitos do Designer.
- **Estilo de luta:** **um traço pequeno por arte na luta** (ex.: Boxe bate um pouco mais forte, Jiu-jitsu toma um pouco menos de dano), mostrado na prévia. A luta continua resolvida pelos números; a cor de risco continua honesta. Sem animação nova de luta.
- **Nenhuma arte domina:** com o jogador típico (4–5/s), as duas chegam ao cinturão em tempos parecidos. A diferença está em **como** se joga, não em quanto se ganha.

### E. Encaixe com a compra de aparelhos da 4b
- O aparelho assinatura segue **o mesmo padrão da 4b**: marca de fita no chão com plaquinha de preço, compra com **Treino** na aba TREINO, chegada com poeira, foco vai para ele, **zera a cada carreira**.
- **Ordem:** saco → esteira → corda continua. O aparelho da arte pode ser comprado **depois da esteira** (em paralelo à corda), para o Boxe não esperar demais. Preço do Designer.
- **Na 1ª carreira com arte** (a da 1ª academia) a marca aparece já na academia. Nas carreiras seguintes, a marca aparece **na garagem** desde o minuto 0: o mentor ensinou.
- Só o aparelho da arte escolhida existe na sala. Sem arte, não há marca.

### F. As 2 lutas da academia
- Sem lutas novas, a academia seria uma sala bonita sem nada para fazer: o dinheiro só vem de luta. Por isso entram **2 adversários "da casa"**, depois do Seu Muralha, só para quem se mudou.
- O 2º é o **teto da fase** (como o Muralha foi na Fase 4) e deve sair 1 a 2 carreiras depois da 1ª chegada à academia.
- Rendem dinheiro, Fama e Legado como os outros. A **escada regional** (e o centro de treinamento) continua na **Fase 6**. É a pergunta 4.

### G. Árvore
- A janela está cheia (R6). Entra uma **aba ESTILO** (as abas CORPO/CARREIRA continuam como estão), com **1 nó por arte** que reforça a regra de curva dela. Preços na faixa que o Legado da academia paga.
- Sem nó de "desbloquear arte" (elas se desbloqueiam na 1ª academia) e sem nó de Linhagem.

### H. O que vai para a academia sem mudar
- Metrônomo e botão SEGURAR: **o mesmo prop**, só reposicionado na prateleira da academia (R9). Versão nova por local: Fase 8.
- Gente do bairro e o Prof. Nelson: os mesmos sprites, agora na academia. Gerador novo só na Fase 6.

## O que entra (lista curta)
1. Botão MUDAR (cinturão + $), cena da academia de bairro, multiplicador global.
2. Aparelhos básicos na versão da academia (troca de sprite).
3. Janela de escolha da arte (1ª academia e início de carreira).
4. Boxe e Jiu-jitsu: aparelho assinatura, regra de curva, 2 técnicas, traço de luta.
5. 2 adversários da academia.
6. Aba ESTILO na árvore com 2 nós.
7. Save v6: `career` ganha local atual e arte da carreira; `permanent` ganha artes desbloqueadas. Migração v5 → v6: a carreira em andamento continua na garagem, sem arte; quem já tem o cinturão vê o botão MUDAR.
8. Simulador e metas refeitos (Designer).

## O que fica de fora (e onde entra)
| Item | Fase |
|---|---|
| Muay Thai | 6 |
| Judô/Wrestling | 7 ou depois |
| Segunda arte / híbridos (MMA) | 7 |
| Escada regional, centro de treinamento (local 3) | 6 |
| Geradores novos, patrocínio, Fama gastável | 6 |
| Nó "começa na academia" e outros "começa com X" | 7 (Linhagem) |
| Trocar de arte no meio da carreira | sem fase (decidido aqui: não) |
| Animações de luta por arte | 9 (polimento), se fizer falta |
| Metrônomo com visual por local | 8 |
| Mentor e rival falando na academia | 8 |
| 3º nível de melhoria dos aparelhos básicos | 6 |

## Critérios de aceite (verificáveis)

**Mudança**
1. Antes do cinturão, o botão MUDAR não existe. Com o cinturão, ele aparece com o preço, e fica apagado sem o dinheiro.
2. Ao mudar: sala nova, aparelhos na versão da academia, geradores, melhorias, luva e Metrônomo intactos, o $ descontado uma vez só, e o treino por segundo e por clique sobem pelo multiplicador do `data/`.
3. NOVA CARREIRA (derrota ou aposentadoria) volta para a garagem.

**Arte**
4. Na 1ª chegada à academia, a janela de arte abre, a escolha leva 1 clique e as 2 artes ficam desbloqueadas no save.
5. Da carreira seguinte em diante, a escolha aparece no início, antes do cartão de início. Não há como trocar de arte dentro da carreira.
6. O aparelho da arte aparece como marca de fita, só pode ser comprado depois da esteira, custa Treino, chega com efeito e zera na NOVA CARREIRA. O da outra arte não aparece.
7. A regra de curva funciona como escrito: o bônus do Boxe vale no clique manual e **não** no Metrônomo nem no assistido; o do Jiu-jitsu vale na equipe e cresce até o teto.
8. A prévia mostra o traço de luta da arte, e o teste de risco honesto continua passando.

**Balanço (simulador, 400 jogadores, 4–5/s e 3/s)**
9. A 1ª chegada à academia acontece entre a **2ª e a 4ª carreira** (a meta do cinturão não muda), e o 23b da 4b continua valendo.
10. **Nenhuma arte domina:** com o típico, a mediana até o cinturão com Boxe e com Jiu-jitsu fica a **≤ 15%** uma da outra. No perfil "só assistido", o Jiu-jitsu sai na frente; no 5/s, o Boxe.
11. O 2º adversário da academia sai em **1 a 2 carreiras** depois da 1ª chegada (mediana), nunca na mesma carreira para mais de 25%.
12. As metas da Fase 4/4b para quem ainda não tem arte (1ª derrota em 10–15 min, tempo morto, revanche) **não mudam**: a carreira 1 é igual à de hoje.
13. Tempo morto na academia ≤ 10 min (p90).
14. Um jogador consegue, a partir de um save novo, chegar à academia, escolher uma arte e começar a carreira seguinte com a outra arte em **≤ 90 min** a 4–5/s.

**Save, dados e saúde**
15. Save v5 com carreira em andamento abre na v6 sem perder nada. Cadeia v0 → v6 funciona. O guarda do save real cobre tudo.
16. Mudar preço da mudança, multiplicador, regras das artes, técnicas e adversários em `data/` muda o jogo sem mexer em código.
17. `tools/run_tests.ps1` passa inteiro.
18. O verificador de alinhamento dá **0 problemas** na garagem e na academia, com e sem arte, com o aparelho da arte trancado e comprado, na janela de arte e na aba ESTILO.
19. Sessão de 40 min com 3 carreiras (uma chegando à academia), sem erro no console.

## Arte (lista enxuta, por causa do R8)
- Diretor de Arte: academia de bairro (sala quadrada, mesma "caixa" da garagem), versão academia dos 3 aparelhos, pera e boneco de grappling (cada um com marca de fita), ícones das técnicas, nós da aba ESTILO.
- Artista de Personagens: **só os 2 adversários da academia**, no padrão `padrao-personagem`. O lutador não muda de visual por arte nesta fase.
- Placeholder do estúdio vale para tudo, menos a sala da academia, que é o marco visual da fase.

## Riscos de design
- **R1. A 1ª arte chega tarde.** A 1ª escolha só vem com o cinturão (carreira 2–4, ~25 min dentro da carreira). Quem não chega ao cinturão nunca vê arte. É coerente com a visão, mas é o ponto a observar com o dono.
- **R2. O balanço inteiro muda** (R7 da Fase 4). O cinturão vira meio, as carreiras ficam mais longas e o Legado passa a pagar a aba ESTILO. O Designer refaz tudo, e a carreira 1 (sem arte) não pode mudar.
- **R3. Uma arte dominar.** Se o Boxe vencer em tudo (o robô típico clica muito), o Jiu-jitsu vira armadilha. Mitigação: critério 10.
- **R4. O Boxe ensinar a não usar o Metrônomo** ou o Jiu-jitsu ensinar a não clicar. Mitigação: as regras somam ao jogo atual, nunca cortam (o Jiu-jitsu não reduz o clique).
- **R5. Tamanho.** Sala nova, 2 artes, 2 adversários, aba nova e save. Se crescer, sai nesta ordem: traço de luta → aba ESTILO → 2ª técnica de cada arte. Os critérios de mudança, escolha e balanço não saem.
- **R6. A tela de escolha no início da carreira cansar.** Mitigação: 1 clique, já vem marcada a arte da carreira anterior.

## Perguntas para o dono
1. **A academia vale por carreira ou para sempre?** **Recomendo por carreira, paga em dinheiro:** toda carreira começa na garagem e se muda depois do cinturão. Para sempre, a garagem vira só o tutorial, e o marco da mudança acontece uma vez na vida do save. "Começar na academia" pode ser um nó caro na Fase 7.
2. **Quais artes agora?** **Recomendo Boxe e Jiu-jitsu** (clique x renda passiva, os dois extremos). Muay Thai vai para a Fase 6. A alternativa é as três já agora, mas aí as 2 lutas da academia ficam sem arte.
3. **A escolha da arte vale a carreira inteira, sem troca?** **Recomendo que sim:** escolhe no início (a 1ª vez, na chegada à academia), e trocar só na próxima carreira. Assim cada carreira tem uma identidade, e "testar a outra arte" é motivo para mais uma carreira.
4. **A academia ganha 2 lutas novas nesta fase?** **Recomendo que sim:** 2 adversários da casa, depois do Seu Muralha. Sem eles, a academia é uma sala onde não se ganha dinheiro, e a escolha da arte não é testada em luta. A escada regional continua na Fase 6.

## Resumo para o Produtor
A Fase 5 transforma o cinturão amador numa mudança: com ele e cerca de $1.000, o lutador sai da garagem para a academia de bairro, que vale só para aquela carreira. Na 1ª chegada, ele escolhe uma arte (Boxe ou Jiu-jitsu). Daí em diante, escolhe no começo de cada carreira, sem trocar no meio.
Cada arte traz um aparelho assinatura (comprado com Treino, como a esteira e a corda da 4b), uma regra de curva (Boxe = clique, Jiu-jitsu = equipe), 2 técnicas e um traço pequeno de luta. Entram também 2 lutas na academia e uma aba ESTILO na árvore.
Ficam de fora: Muay Thai, regional e local 3 (Fase 6), começar na academia e segunda arte (Fase 7).
São 4 perguntas ao dono: academia por carreira, quais artes, escolha fixa na carreira e as 2 lutas novas. Para todas recomendo "sim" à proposta.

## Respostas do dono (2026-11-06)
1. Academia **por carreira**, paga em $ (toda carreira começa na garagem).
2. Artes: **Boxe e Jiu-jitsu** (Muay Thai na Fase 6).
3. A arte **vale a carreira inteira**, sem troca no meio.
4. **Sim, 2 lutas novas** na academia (escada regional na Fase 6).

## Decisões do Diretor (design Fase 5)
Sobre os 5 pontos que não fecham (design §10.7) e 2 pontos ligados. Nenhuma mudança de número pedida ao Designer.

1. **Tempo morto na academia depende de aposentar: aceito, e a dica entra no escopo.** Chave nova `gym_retire_hint` no bloco PRÓXIMA LUTA: "APOSENTAR AGORA LEVA {n} DE LEGADO", quando o adversário da academia está PERIGOSO há ≥ 5 min. Só texto, usa o mesmo cálculo de Legado da prévia; passa pela `alinhamento-ui`. Não é sistema novo, é o empurrão que faz o critério 13 valer para gente de verdade.
   - **Critério 13 passa a ser:** "Tempo morto na academia ≤ 10 min (p90) com o robô que aposenta após 8 min seguidos no vermelho, e a dica de aposentar aparece aos 5 min de PERIGOSO na academia."
2. **Jogador "só no verde" vence o Kid na carreira da chegada (40% Boxe / 81% Jiu-jitsu): aceito.** É a recompensa da paciência, e o jogador paciente já pagou em tempo. As artes ficam desbloqueadas de qualquer jeito, e "testar a outra arte" e o nó ESTILO seguem dando motivo para a próxima carreira. Endurecer o Kid estragaria o típico.
3. **Boxe a 3/s leva 4 carreiras para o Kid: aceito.** É a identidade das artes (quem clica pouco deve jogar de Jiu-jitsu). Condição: a janela de arte tem que deixar isso claro sem número. O Roteirista escreve as `tagline` com essa leitura (Boxe = "para quem bate muito", Jiu-jitsu = "para quem deixa a equipe trabalhar"), sem citar cliques por segundo.
   - **Critério 11 passa a ser:** "O 2º adversário da academia sai em 1 a 2 carreiras depois da 1ª chegada (mediana) **a 4–5/s, para as duas artes, no perfil que luta no amarelo**; nesse perfil, nunca na mesma carreira para mais de 25%. A 3/s, o Jiu-jitsu fica em 1–2 carreiras (o Boxe a 3/s pode passar disso)."
4. **~1 em 3 perde no Tonhão na carreira da chegada: aceito, sem mudar o Tonhão.** Quem perde lutou no amarelo com o aviso "PERDER ENCERRA A CARREIRA" na prévia, e a mudança já deu o ganho permanente (as 2 artes). Perder faz parte do ciclo desde a garagem. Se o dono achar pesado no teste, a alavanca é `opp_gym_1` −15% (no `data/`, sem código).
5. **A árvore fecha mais cedo (5–6; 4 no "só no verde"): aceito.** O típico continua dentro de 5ª–8ª. A Fase 6 traz nós novos, então árvore cheia antes não vira beco.
   - **Critério F4 8 passa a ser:** "árvore CORPO+CARREIRA+ESTILO fecha entre a 5ª e a 8ª carreira no perfil típico (4–5/s, luta no amarelo)."
6. **Reserva de $1.000 na LOJA: aceita.** Não é anti-incremental: só vale entre o cinturão e a mudança, quando não existe mais fonte de dinheiro, e evita uma carreira presa. O botão tem que dizer o motivo ("GUARDE $1.000 PARA A MUDANÇA"), nunca só ficar apagado.
7. **Pera para o Boxe: correto.** É o que o escopo (D) pede, e a garagem já tem o saco pesado. Aparelho novo tem que ter silhueta nova.

**Plano pronto para mostrar ao dono.**

## Aprovação do dono (2026-11-06)
Plano da Fase 5 aprovado ("pode sim"), com os nomes do Roteirista (fase5-textos.md) e as decisões do Diretor.

## Rebalanceamento pós-PRs (2026-11-11)
Registrado pelo Designer a pedido do Produtor. Números e simulação: `fase5-design.md`, seção "Rebalanceamento pós-PRs".

**Escolha do dono: o meio-termo** (nem a versão do PR, nem a 1ª proposta do Designer). O clique continua sendo a coisa mais forte do jogo e o teto de clique sobe.
- **Luva dourada:** ×7, por menos tempo que os 12 s do PR. O intervalo entre luvas fica.
- **Melhorias novas de clique** (saco, esteira, corda e técnicas das artes): ×3, com preço alto.
- **A dificuldade se segura nos adversários da academia**, não enfraquecendo o clique. Tonhão e Kid podem subir e, se não houver outro jeito, o Seu Muralha também. Sempre com simulação.

**Metas que passam a valer** (as 3 decisões do Diretor ficam aceitas com elas):
| Critério | Meta nova | Antes |
|---|---|---|
| 23b: cinturão na 1ª carreira | **≤ 25% a 4/s e a 5/s**; nunca antes de 20:00 | ≤ 20% a 5/s, ≤ 25% a 4/s |
| F4 22: 1ª derrota (mediana) | 10–15 min | igual |
| Critério 11: Kid na mesma carreira da chegada | **≤ 35% a 5/s** | ≤ 25% |
| Critério 10: Boxe × Jiu-jitsu até o cinturão | **≤ 10%** | ≤ 15% |
| F4 8: árvore fecha | 5ª–8ª carreira | igual |
| 4b 24: clique × assistido | **≥ 6×** | ≥ 8× |

Também muda o que a decisão 4 da seção anterior dizia ("sem mudar o Tonhão") e a trava da 4b sobre não mexer em adversários: nesta rodada, por escolha do dono, Tonhão, Kid e Muralha foram recalibrados no simulador.
