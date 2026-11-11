# Visão do jogo — "Fightclicker" (nome de trabalho)

Fonte da verdade: `PROMPT.md`, **com as mudanças aprovadas pelo dono** registradas em "Decisões do dono" abaixo. Onde houver conflito, a decisão do dono vale sobre o PROMPT.
Atualizado em 2026-11-05: sala de treino em pixel art, progressão de locais, carreira por run (derrota encerra a carreira) e árvore de habilidades.
**Atualizado em 2026-11-11:** calendário com luta obrigatória no dia, árvore grande escondida, Honra, linhagem de discípulos e mentores, 1º lutador fixo, história costurada na carreira (`docs/direcao-narrativa.md`), pós-jogo, clique sempre gostoso, caixa de aparelho. Ver "Decisões do dono (2026-11-11)". Onde este texto antigo conflitar com essa seção, ela vale.

## Em uma frase
Um incremental **ativo** em pixel art em que cada carreira começa socando um saco remendado no fundo de uma garagem; você sobe de local a cada cinturão, decide quando arriscar a próxima luta, e cada carreira encerrada deixa Legado para a próxima geração da linhagem chegar mais longe.

## Decisões do dono (2026-11-05)
1. **Estética arcade em pixel art**, gênero de gestão de treino (Punch Club é a referência de gênero). Arte, personagens, nomes, layout e locais **100% originais**.
2. **Tela principal = a sala de treino do lutador**, uma salinha quadrada com aparelhos.
3. **Progressão de locais:** começa num fundo de garagem e troca de lugar conforme sobe (academia, e assim por diante).
4. **Um aparelho por arte marcial**, e o jogador **escolhe** a arte que quer usar.
5. **Clique estilo incremental clássico:** um alvo grande no meio da tela, e **todo clique mostra número na tela**.
6. **"Não deve ser um jogo tão fácil."**
7. **Perder uma luta encerra a carreira (a run).** O jogador começa uma nova e, com o que ganhou, compra melhorias permanentes, numa **árvore de habilidades**.
8. **O jogador pode se aposentar** (o funcionamento é definido aqui, abaixo).
9. Plano da Fase 1 **aprovado**; nome de trabalho Fightclicker até a Fase 8 do novo roadmap (Narrativa e absurdo); números com 3 dígitos significativos e ponto decimal.

### O que isso muda no PROMPT
| PROMPT | Antes | Agora |
|---|---|---|
| §5.6 Lutas | "Derrota não deve frustrar: ganha um pouco de dinheiro" | Derrota **encerra a carreira**, mas sempre rende Legado e mostra quanto faltou. Deve doer, não humilhar. |
| §5.8 Prestígio | Aposentar só após o título da camada final | Aposentar **a qualquer momento entre lutas**. A carreira também termina na derrota. |
| §5.8 Bônus de Legado | "bônus permanentes comprados com Legado" | Os bônus formam uma **árvore de habilidades**. |
| §5.3 Clique | ações de treino ligadas aos atributos | mesmo conceito, mas com **alvo central grande** e número em todo clique |

O resto do PROMPT continua valendo, inclusive §5.10: nada de decadência, fome ou energia que bloqueia. A derrota é o único "custo", e ela é sempre uma escolha de risco do jogador, nunca um timer.
*(2026-11-11)* Com o calendário, a luta tem **dia marcado e obrigatório**, mas continua sendo escolha: no dia o jogador decide **lutar ou passar o posto** (aposentar). Nenhuma luta começa sem ele apertar.

## Decisões do dono (2026-11-11)
Fonte: `docs/propostas/feedback-2026-11-11.md` (respostas e 2ª leva) e `docs/direcao-narrativa.md` (direção narrativa do dono, que manda sobre `docs/narrativa.md`).
1. **Calendário com luta obrigatória no dia.** Cada campanha tem datas de luta. Para conviver com "derrota encerra a carreira":
   - "faltam X dias" e o risco da próxima luta sempre visíveis; avisos a 3 dias e a 1 dia;
   - lutar antes da data é livre; aposentar entre lutas continua possível a qualquer momento;
   - no dia, o relógio **e o treino** param, a prévia abre e o jogador escolhe **Lutar** ou **Passar o posto** (100% do Legado); a luta nunca começa sozinha;
   - o relógio só anda com o jogo aberto, na sala; offline nunca pula para o dia de uma luta.
2. **Árvore grande, escondida.** Um mapa único que se revela, **no lugar das 3 abas**, com os 12 nós atuais no centro (ninguém perde Legado). Fica atrás de um botão, como no Fortune Mill: a sala é o jogo, a árvore abre com um clique. Paga com Legado.
3. **Honra.** Moeda ganha **só ao se aposentar**, gasta numa **árvore do hall**, pequena e separada. O hall é o **mural da escola**: todo lutador entra; bônus e Honra só para quem saiu por vontade.
4. **Linhagem de discípulos e mentores.** Cada carreira é uma **campanha** como representante da escola. Ao perder ou sair, o lutador **passa o posto** ao próximo discípulo e vira mentor. Personalização **só visual** (nome, pele, cabelo, calção).
5. **1º lutador fixo.** A Carreira 1 é sempre o mesmo personagem (nome, visual e gesto da equipe). A personalização começa no **2º discípulo**. O 1º lutador é mentor, se afasta discretamente e volta como **último adversário** (não é vilão).
6. **História costurada na carreira**, contada quase toda por narração passiva (comentários curtos, cenário, fotos), com poucas cenas curtas e puláveis. Toda fala toca um **som de voz por letra** (original nosso). Arcos ligados a marcos do jogo (`docs/roadmap.md`).
7. **Pós-jogo:** a história termina; depois vêm um **modo infinito** e uma **torre** de combates.
8. **O clique sempre tem que dar prazer** e o late game **nunca fica parado**: sempre existe uma próxima coisa a fazer.
9. **Caixa de aparelho.** Toda carreira começa só com o saco. Aparelhos comprados chegam numa **caixa** que o jogador abre com cliques; a caixa é também a resposta da história para "por que recomprar": a escola encomenda o equipamento de cada novo discípulo.
10. **Cada arte luta diferente** (golpes, animações, ritmo) e **cada liga tem sua arena**.
11. **Rival** deixa de ser o chefe do mundial: começa menosprezando a escola e termina em respeito.
12. **Todo discípulo começa na garagem.** Sai o nó "começar na academia".

## Pilares
1. **Todo soco pesa.** Todo clique mostra número, o aparelho balança, a tela treme, o som bate. O clique perde espaço para a renda passiva com o tempo, mas nunca vira inútil. *(2026-11-11)* O clique é a mecânica essencial e **sempre dá prazer**, também no late game.
2. **Ver o número crescer, e ver a sala crescer.** Renda passiva visível e constante; aparelhos melhoram, gente aparece treinando, o lutador troca de local.
3. **Arriscar ou passar o posto.** A decisão central da carreira: lutar mais uma (mais Legado se vencer, fim da carreira se perder) ou se aposentar com o que tem. A luta prova o treino. *(2026-11-11)* Com o calendário, a decisão chega com data: no dia, lutar ou passar o posto.
4. **Difícil, mas justo.** O jogo não é fácil: a primeira carreira provavelmente termina em derrota. Mas a derrota sempre explica o porquê e sempre deixa algo para a próxima carreira.
5. **Linhagem, não reset.** Toda carreira encerrada vira mentor da próxima. O discípulo começa mais forte e pode testar outra arte marcial. *(2026-11-11)* A escola guarda o que aprendeu; cada discípulo constrói a própria trajetória. O que acontece na história (garagem salva, mentores, fotos) não recomeça.
6. *(2026-11-11)* **Sempre há uma próxima coisa.** Luta com data, caixa para abrir, nó para comprar, evento para pegar. Nunca tempo morto longo, nem no fim.

## A tela principal: sala de treino com alvo central
- **O centro da tela é o alvo de clique.** O lutador e o **aparelho em foco** ficam no centro da sala, grandes, com área de clique generosa. É o "botão no meio da tela" do incremental clássico, só que é um saco de pancada que balança.
- **O alvo nunca muda de lugar.** Trocar de foco troca o aparelho que está no centro (o lutador vai até ele), mas o ponto de clique continua no mesmo lugar da tela, para a mão do jogador não precisar caçar o alvo.
- **Todo clique mostra número flutuando** a partir do ponto clicado (ex.: `+12 Força`). Críticos e bônus aparecem maiores e de outra cor.
- **Os outros aparelhos ficam visíveis em volta**, na própria sala. Clicar num deles (ou num botão de foco no painel) muda o foco.
- **A renda passiva aparece na sala:** geradores (parceiro de treino, treinador, alunos…) são pessoas treinando nos aparelhos de volta. Mais compras, mais movimento (limite só de desenho; o número continua crescendo). **Nunca** bloqueia compras.
- **Upgrades de equipamento melhoram o aparelho na tela** (saco remendado vira saco de couro).
- Interface em painéis em volta da sala, sem cobrir o alvo central. Composição exata: Diretor de Arte (`docs/arte/direcao-visual.md`) + UI/UX.

## Aparelho ↔ atributo ↔ arte marcial

### Aparelhos básicos (todo lutador tem, desde a garagem)
| Aparelho | Atributo | Na garagem | No fim absurdo |
|---|---|---|---|
| Saco de pancada | **Força** | saco remendado com fita, pendurado numa viga | um meteoro acorrentado |
| Corda de pular | **Agilidade** | corda de varal, marcas de giz no chão | corda que deixa rastro de luz |
| Esteira | **Resistência** | esteira velha e enferrujada que range | esteira que gira o chão inteiro da sala |

3 aparelhos porque são 3 atributos (PROMPT §5.2). **Foco de treino = aparelho no centro.** A renda passiva vai para o foco atual, como no PROMPT.

### Aparelho da arte marcial (um por arte)
| Arte | Aparelho assinatura | Curva da arte (PROMPT §5.7) |
|---|---|---|
| Boxe | saco de velocidade (pera) | clique forte, jogo ativo |
| Muay Thai | saco longo de chute | crítico e combos |
| Jiu-jitsu | boneco de grappling no tatame | escala com tempo/renda passiva |
| Judô/Wrestling | boneco de arremesso | bônus percentuais sobre atributos |

- Proposta (números com o Designer): o aparelho da arte é um **4º foco** que treina os 3 atributos numa proporção típica da arte e é onde ficam as **técnicas** dela.
- Só o aparelho da arte escolhida aparece na sala. Esteira e corda não são artes, por isso os aparelhos básicos ficam para os atributos e cada arte ganha o seu.

### Aparelhos não são geradores
- **Aparelho** = onde o clique acontece + upgrades de equipamento (multiplicadores).
- **Gerador** = quem produz treino sozinho (PROMPT §5.4), mostrado treinando na sala.
- Separar "o que eu clico" de "o que produz sozinho" deixa o loop claro.

### Quando escolher a arte
**Recomendação:**
- **Primeira carreira:** a escolha acontece **ao se mudar da garagem para a academia de bairro**. Na garagem ele só sabe bater; arte se aprende numa academia. Mudança de local + escolha de arte = um marco forte, o jogo "vira outro".
- **A partir daí, a arte fica desbloqueada para sempre:** nas carreiras seguintes o discípulo escolhe a arte **logo no início**, ensinado pelo mentor. Com runs curtas, ninguém precisa esperar a academia toda vez.
- Outras artes se desbloqueiam pela árvore de habilidades.
- Por que não no minuto zero da primeira carreira: escolha às cegas. Depois de 15 minutos o jogador já sabe se gosta de clicar (Boxe) ou de deixar rodar (Jiu-jitsu).

## A carreira (run), a derrota e a aposentadoria

### Como funciona
- Cada carreira começa **na garagem**, do zero (com os bônus da árvore).
- O jogador treina e **escolhe quando lutar**. Não existe timer obrigando a lutar. Mas dinheiro só vem de lutas, e o custo de crescer é exponencial: ficar só treinando fica lento. Essa é a pressão.
  - *(substituído em 2026-11-11)* Agora cada luta tem **data no calendário da campanha**. Pode lutar antes; no dia, luta ou passa o posto. A pressão passa a ser a data, sempre visível e avisada.
- **Antes de cada luta, uma prévia:** atributos do adversário ao lado dos seus e um indicador de risco (fácil / equilibrado / perigoso). Perder tem que ser consequência de um risco que o jogador viu, nunca uma surpresa.
- **Vencer:** dinheiro, fama, avanço na escada, cinturões, e o Legado acumulado da carreira sobe.
- **Perder:** a carreira termina. Tela de fim de carreira mostra o que faltou ("faltaram 120 de Resistência", "ele te derrubou no 2º round"), o Legado ganho e o atalho para a árvore.
- **Aposentar:** botão disponível **entre lutas, a qualquer momento**. Encerra a carreira com **Legado cheio** e um bônus pequeno de "saída por cima".

### Derrota x aposentadoria (proposta, números finais com o Designer)
| Fim da carreira | Legado recebido | Sensação |
|---|---|---|
| Aposentadoria voluntária | **100%** do Legado acumulado (+ bônus se acabou de ganhar um cinturão) | "saí por cima" |
| Derrota | **50%** do Legado acumulado | "doeu, mas não foi à toa" |

- O Legado acumulado cresce com vitórias, cinturões e fama da carreira. Cada luta vencida aumenta o pote; a próxima luta põe metade dele em risco. Esse é o "arriscar ou pendurar as luvas".
- Aposentar cedo demais rende pouco (o pote é pequeno). Ninguém ganha nada perdendo de propósito: aposentar é sempre melhor que perder.
- Nas duas saídas o lutador **vira mentor** do próximo. A linhagem não depende de vencer.
- *(2026-11-11)* Só a aposentadoria rende **Honra** e bônus no mural. Aposentar no dia da luta (no lugar de lutar) conta como aposentadoria.

### O que se perde e o que se mantém
| Perde no fim da carreira | Mantém para sempre |
|---|---|
| Treino, atributos, dinheiro, fama | Legado não gasto e nós comprados na árvore |
| Geradores e upgrades de aparelho | Artes marciais desbloqueadas |
| Local de treino (volta para a garagem) | Locais já alcançados ficam registrados (para a árvore e conquistas) |
| Posição na escada e cinturões da carreira | Recordes (melhor carreira), conquistas, histórico da linhagem |

- ~~Um nó caro da árvore pode permitir **começar já na academia de bairro**, mais tarde.~~ *(retirado em 2026-11-11: todo discípulo começa na garagem)*
- A garagem guarda marcas dos mentores anteriores (foto na parede, o saco velho dele): detalhe de narrativa, não sistema.
- *(2026-11-11)* Corda, esteira e aparelho da arte são recomprados a cada carreira e chegam **numa caixa**. Garagem salva, mentores, fotos e o mural ficam para sempre.

### Árvore de habilidades (meta-progressão)
- Comprada com **Legado**, entre carreiras. Ramos sugeridos (conteúdo com o Designer):
  - **Corpo:** bônus de atributos e de clique.
  - **Carreira:** mais dinheiro por luta, mais Legado, prévia de luta mais detalhada.
  - **Linhagem:** desbloquear artes, começar com geradores, começar num local melhor, segunda arte (híbridos).
- Primeiros nós baratos o bastante para a **primeira derrota já comprar algo**. Senão, a primeira derrota vira só castigo.
- *(2026-11-11)* A árvore vira **um mapa grande que se revela**, no lugar das abas, **escondido atrás de um botão** (Fase 5.4). As ideias do ramo Linhagem se espalham: personalização e mural nas Fases 6b–6c, segunda arte na Fase 9. Ao lado dela, a **árvore do hall**, paga com Honra (Fase 6c).

### Meta de dificuldade ("não tão fácil")
- A **primeira carreira** deve terminar em derrota para a maioria dos jogadores, em **10–15 minutos** (derrota cedo custa pouco tempo).
- O **cinturão amador** deve sair entre a **2ª e a 4ª carreira**.
- Adversários têm perfis diferentes (forte, rápido, resistente): treinar só um atributo perde. A escolha de foco importa.
- Curva de custos mais apertada que um incremental "relaxado": o jogador precisa escolher o que comprar, não comprar tudo.
- Nunca difícil por esconder informação: a prévia e a tela de fim de carreira sempre explicam.

## Progressão de locais (espinha visual do incremental)
A cada cinturão, o lutador pode **se mudar** para um lugar melhor dentro da carreira. É o maior marco visual: cenário novo, aparelhos em versão nova, tom um degrau acima.

### Escada de locais (6)
| # | Local | Como libera | Camada (PROMPT §5.9) | Tom |
|---|---|---|---|---|
| 1 | **Fundo de garagem** | início de toda carreira | 1. Treino | pé no chão, melancólico: lâmpada fraca, carro velho coberto, saco remendado |
| 2 | **Academia de bairro** | cinturão amador | 2. Carreira de lutas | realista: ringue pequeno, pôsteres desbotados, outros lutadores |
| 3 | **Centro de treinamento** | cinturão regional | 3. Gestão da academia | profissional: galpão, logos de patrocinadores, alunos |
| 4 | **Complexo de elite** | cinturão nacional | 3. Gestão da academia | luxo caricato: arena própria, holofotes, equipe enorme |
| 5 | **Templo na montanha** | cinturão mundial | 4. Linhagem e legado | lendário: mestres milenares, torneios secretos, um urso como parceiro de treino |
| 6 | **Dojo no fim da realidade** | topo dos torneios secretos | 4. Linhagem e legado | absurdo: sala flutuando no vazio, soco que racha o cenário |

- Um local por degrau da escada do PROMPT (amador → regional → nacional → mundial) e mais dois para o fim absurdo. Menos deixa o jogador tempo demais no mesmo cenário; mais custa arte demais.
- Na prática, os locais 5 e 6 só serão alcançados por discípulos com árvore avançada: o absurdo cresce junto com a linhagem.
- *(2026-11-11)* Cada liga tem também sua **arena de luta**. O **último adversário da história** (o 1º lutador) fica no topo dos torneios secretos, depois do mundial.

### Regras da mudança
- **Libera por cinturão e custa dinheiro.** Decisão boa: "mudo agora ou compro mais geradores?".
- **Mudar nunca tira nada dentro da carreira.** Só dá: multiplicador global, mais espaço para gente treinando, nova linha de upgrades de aparelho.
- **Entre mudanças, a sala evolui aos poucos** (aparelhos melhorados, mais gente).

## Público
- Fãs de incrementais que gostam de jogo ativo (Cookie Clicker, Antimatter Dimensions, Realm Grinder).
- Fãs de roguelites com meta-progressão ("mais uma run").
- Fãs de pixel art e de jogos de gestão de treino.
- Quem não quer reflexo: a habilidade está nas escolhas (foco, tática, compras, quando lutar, quando se aposentar).

## O que torna este jogo diferente
- **O lugar conta a história:** da garagem ao dojo fora da realidade, o cenário cresce com o expoente.
- **"Arriscar ou pendurar as luvas":** incremental com a tensão de uma run, sem timer e sem energia.
- **Arte marcial muda a curva de crescimento**, não só a aparência.
- **Prestígio com história:** toda carreira encerrada vira o mentor que fala com você.
- ~~**Rival recorrente** que pode encerrar suas primeiras carreiras e é o chefe final do título mundial.~~ *(2026-11-11)* **Rival recorrente** que despreza a escola e aprende a respeitá-la.
- *(2026-11-11)* **O último adversário é o seu primeiro lutador**, que continuou treinando longe. Não é vingança: é o primeiro mestre testando o que a linhagem aprendeu.

## O que nunca faremos
- Decadência de atributos, fome ou energia que bloqueia o jogador.
- ~~Timer que força a lutar. Lutar é sempre escolha.~~ *(trocado em 2026-11-11, decisão do dono)* Luta que começa sem o jogador decidir, ou data que chega sem aviso. No dia, lutar ou passar o posto é sempre escolha dele.
- Tempo morto longo no late game, ou clique que vira inútil.
- Derrota sem explicação ou sem recompensa nenhuma.
- Limite de espaço na sala que impeça comprar algo (limite só de desenho).
- Lutas decididas por reflexo ou combos de teclado.
- Diálogo longo ou que não dá para pular.
- Copiar nomes, personagens, arte, layout ou estrutura de Punch Club ou de qualquer outro jogo.
- Monetização agressiva ou timers pagos.
- Adiantar sistemas de fases futuras.

## Roadmap
Ver `docs/roadmap.md`.

## Assumido pelo estúdio (2026-11-05), dono pode revisar
O dono pediu para seguir as recomendações do Diretor nas perguntas abertas. Vale até ele dizer o contrário:
1. **Escolha da arte (1ª carreira):** na mudança da garagem para a academia de bairro. Depois disso, no início de cada carreira.
2. **Legado:** derrota rende **50%** do Legado acumulado e aposentadoria rende **100%** (números finais com o Designer).
3. **Aposentar:** a qualquer momento entre lutas.
4. **Escada de 6 locais** aprovada. Local final: **Dojo no fim da realidade** (escolha do Diretor). Mantém a mesma "caixa" da sala (regra da direção visual), é o "soco que distorce a realidade" do PROMPT e fecha a linhagem num dojo de mestres. Vulcão e Lua seriam só cenário, sem ligação com a história.
5. **Mudar de local** custa dinheiro, além do cinturão.
6. **Primeiras artes:** Boxe, Muay Thai e Jiu-jitsu (Judô/Wrestling depois).
7. **Meta de dificuldade:** a primeira carreira termina em derrota em 10–15 min, e o cinturão amador sai entre a 2ª e a 4ª carreira. É uma proposta, a ser validada jogando.
8. **Legado** é contado na Fase 3 e só ganha onde ser gasto na Fase 4 (árvore).

### Decisão do Diretor para a Fase 2 (moeda da garagem)
- Os itens da garagem (geradores de gente do bairro e melhorias de aparelho) custam **Treino**, agora e depois. Cada treino ganho soma ao atributo em foco **e** ao saldo de Treino. Gastar o saldo nunca reduz atributo.
- **Dinheiro** entra na Fase 3, vindo das lutas, e compra o que dinheiro compra: gente que cobra, coisa de loja e mudança de local. Detalhe em `docs/fases/fase2-escopo.md`.

### Assumido pelo estúdio para a Fase 3 (2026-11-05), dono pode revisar
O dono delegou e não pôde testar a Fase 2 nem aprovar o plano da Fase 3. Vale até ele dizer o contrário:
9. **A garagem continua paga em Treino** para sempre. O dinheiro vem **só das lutas**.
10. **A tremida continua em todo clique**, leve. A opção de desligar fica para a Fase 9.
11. As demais decisões da Fase 3 (o que o dinheiro compra, 4 adversários, derrota sem dinheiro, sem clique na luta, pontos no limite de tempo etc.) estão em `docs/fases/fase3-escopo.md`, "Decisões para o dono revisar".

### Decisões do dono para a Fase 4 (2026-11-05)
12. **Auto-clique aprovado** (`docs/propostas/auto-clique.md`, opção A nas 3 perguntas): **Metrônomo** na LOJA, pago em dinheiro, com níveis. Dá socos de verdade pelo caminho do clique (aparelho × luva, crítico, número), sem tremida de tela, mais devagar que uma pessoa, e não funciona na luta. Mais o nó **Memória muscular** na árvore: toda carreira começa com o Metrônomo nível 1. Os dois entram na Fase 4.
13. **Fase 4 aberta por ordem do dono**, antes de ele jogar a Fase 3.

### Assumido pelo estúdio para a Fase 4 (2026-11-05), dono pode revisar
14. **Dificuldade da Fase 3 (critérios 22–24): opção A**, "está bom". O Seu Muralha não muda, e tudo é medido de novo com a árvore na Fase 4.
15. A árvore só abre **entre carreiras** (pela tela de fim) e não tem reembolso. As demais decisões estão em `docs/fases/fase4-escopo.md`, "Decisões para o dono revisar".

## Perguntas abertas para o dono
*(2026-11-11)* 4 perguntas sobre a Fase 5.1 (ordem e caixa de aparelho) e a lista de pendências estão em `docs/propostas/feedback-2026-11-11.md`, seção 6.
