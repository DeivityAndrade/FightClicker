# Proposta: auto-clique ("algo que clica por você")

Dono: Diretor de Jogo. Versão 1 (2026-11-05). Status: **proposta para o dono decidir**. Nada aqui foi aprovado nem implementado.
Base: `PROMPT.md` (§5.3, §5.4, §5.10), `docs/visao.md` (pilares e decisões do dono), `docs/roadmap.md`, `fase2-design.md`, `fase3-design.md`, `fase3-revisao.md`, `data/training.json`, `data/generators.json`, `data/shop.json`.

## 1. A ideia do dono
"Algo para comprar, para o player não ficar clicando direto. Uma coisa que clica por você a cada X segundos, e quanto mais upa, mais cliques dá."

O problema que ele aponta é real, e a revisão da Fase 3 mediu esse problema:
- Uma carreira típica que passa do Dinho fica **20 a 40 min** diante do Seu Muralha. Na partida do QA foram ~40 min de espera.
- Hoje, nesse tempo, o jogo pede **clique sem parar**: o clique (até 60 por soco com saco no máximo e luva de couro) vale mais que toda a renda passiva. Quem para de clicar perde mais da metade da renda.
- Com runs que recomeçam do zero, o jogador **repete o clique da garagem em toda carreira**. Isso cansa a mão, e cansaço de mão não é dificuldade.

## 2. O que é diferente dos geradores que já existem

| | Gerador (Vizinho, Tio, Prof. Nelson) | Auto-clique |
|---|---|---|
| O que produz | Treino/s **fixo** (1, 8, 25 por unidade) | **cliques de verdade** no alvo central |
| Escala com | só com mais unidades | melhorias do aparelho (×3, ×5), luva (×2, ×2) e tudo que vier depois para o clique |
| Crítico | não | sim, sorteado como o clique do jogador |
| Na tela | gente treinando em volta, número no HUD ("+x/s") | o **lutador** solta o soco sozinho, com a luva equipada, o saco balança e o número sai do alvo |
| Fantasia | "contratei alguém" | "meu lutador pegou ritmo" |

**Veredito: agrega, não duplica, desde que siga uma regra:** o auto-clique precisa passar **pelo mesmo caminho do clique do jogador** (mesmo `por_clique` do aparelho em foco × luva, mesmo sorteio de crítico, mesmo número flutuante). Se virar "mais X de Treino/s", é um 4º gerador com outro nome, e aí duplica.

Por que agrega:
- **É a ponte do PROMPT §5.3, pelo outro lado.** O PROMPT quer que o clique perca espaço para o passivo sem virar inútil, e sugere converter passivo em clique. O auto-clique faz o contrário: converte **investimento em clique** em renda passiva. A luva e as melhorias do aparelho continuam valendo mesmo com a mão parada.
- **Cria a escolha "luva ou metrônomo"** (ver nome abaixo): a luva multiplica cada soco, o auto-clique dá mais socos. Os dois se multiplicam, então nenhum vira lixo.
- **Resolve o cansaço sem tirar a decisão.** O jogador ainda escolhe foco, tática e quando lutar. Ele só deixa de ser obrigado a martelar o mouse por 40 min.

O que ele **não** resolve (para ninguém vender errado ao dono): o auto-clique **não cura o tempo morto** diante do Seu Muralha. A espera continua se o adversário pedir 3x mais treino do que o jogador tem. Ele torna a espera menos cansativa e um pouco mais curta. Quem resolve a espera é o balanço da Fase 4 com a árvore (risco 4 da `fase3-revisao.md`).

## 3. Regras de design que valem em qualquer opção
1. **Mesmo caminho do clique** (seção 2): aparelho em foco, luva, crítico, número. Vai para o atributo em foco, como tudo.
2. **O soco do jogador continua sendo o mais pesado na tela.** O auto-soco tem número menor, sem tremida de tela e som mais baixo. Tremida e número grande são só do clique do jogador. É o pilar "Todo soco pesa".
3. **Clicar sempre rende bem mais que não clicar** enquanto o clique for o centro do jogo (todo o protótipo). O ritmo do auto-clique fica bem abaixo do ritmo de uma pessoa (3 a 5 cliques/s). O Designer define os números e prova na simulação.
4. **Soma, não substitui.** O auto-soco acontece junto com os cliques do jogador. Não bloqueia o alvo, não pausa quando o jogador clica.
5. **Rig articulado** (regra do dono): quem soca é o lutador, com a mesma luva do cursor e das mãos. É a animação de jab que já existe, não uma imagem nova.
6. **Fica fora da luta.** Na luta não há clique (decisão 6 da Fase 3).
7. **Offline** (Fase 9): conta como renda passiva, com crítico pela média, dentro dos ~25% do PROMPT. Não decidir agora.
8. Nada de energia, combustível ou desgaste. Comprou, funciona para sempre na carreira (§5.10).

## 4. Opções

### (a) Aba TREINO da garagem, pago em Treino
Níveis comprados com Treino que diminuem o intervalo e/ou dão mais socos por vez.
- **Loop:** concorre com Vizinho, Tio e melhorias de aparelho. Fica disponível desde o minuto zero de toda carreira.
- **"Todo soco pesa":** risco alto. Os primeiros minutos da 1ª carreira são onde o jogador aprende que o clique importa. Um auto-clique barato ali ensina o contrário.
- **"Não tão fácil":** neutro. É mais uma compra em Treino, e Treino nunca falta para comprar algo (os geradores são infinitos).
- **Tempo morto:** pouco efeito. Treino já tem onde ser gasto durante a espera.
- **Duplicação:** é a opção que **mais parece gerador**: mesma aba, mesma moeda, mesmo "+/s" na cabeça do jogador.
- **Veredito:** não recomendo.

### (b) LOJA, pago em dinheiro
Item com níveis comprados com dinheiro. Cada nível acelera o ritmo.
- **Nome provisório: "Metrônomo".** Um metrônomo de feira na prateleira da garagem. A cada tique, o lutador solta um jab sozinho. Subir de nível = subir o andamento. É pé no chão, é original e escala bem pelo cenário (mais tarde vira o rádio da academia, o tambor do templo... só visual, Fases 5 e 8).
- **Loop:** chega depois da 1ª vitória (~3 min), quando a mão começa a cansar. Concorre com o Prof. Nelson e com as luvas pelo dinheiro, que é escasso (todo o dinheiro antes do cinturão é $600, e as duas luvas custam $620). É uma decisão de verdade: luva (cada soco vale mais), Nelson (passivo fixo) ou Metrônomo (mais socos, que crescem com a luva).
- **"Todo soco pesa":** bom. O primeiro trecho da carreira continua 100% manual, e o auto-soco aparece como recompensa por lutar.
- **"Não tão fácil":** precisa de cuidado. É renda nova, então o Designer recalibra junto com a árvore (o balanço já vai ser refeito na Fase 4).
- **Tempo morto:** ajuda na fase mais cansativa (Dinho e Seu Muralha), que é onde o jogador já tem dinheiro.
- **Extra:** responde à decisão 4 da Fase 3 ("o dinheiro compra só 2 coisas").
- **Veredito:** recomendo como entrada principal.

### (c) Nó da árvore de Legado (permanente)
Um nó dá um auto-clique inicial, e nós seguintes o melhoram entre carreiras.
- **Loop:** ataca o ponto mais repetitivo do jogo, o começo de toda carreira, que recomeça do zero. É a cara do pilar "Linhagem, não reset": "meu mentor me deixou o ritmo".
- **"Todo soco pesa":** bom, se ficar pequeno. Na 2ª carreira em diante o jogador já sabe que o clique importa.
- **"Não tão fácil":** o mais perigoso das três. Um bônus permanente que cresce acumula carreira após carreira. Precisa de teto claro.
- **Tempo morto:** pouco efeito sozinho (é pequeno no começo da run, quando não há espera).
- **Risco de escopo:** "começar com algo" é do ramo Linhagem, que o roadmap pôs na Fase 7. Um único nó no ramo Corpo ("bônus de clique") cabe na Fase 4. Uma linha inteira de nós de auto-clique, não.
- **Veredito:** recomendo como complemento: **um nó** só, que conversa com o item da loja.

## 5. Recomendação

**Combinação (b) + um nó de (c), nesta forma:**
- **"Metrônomo"** (nome provisório, Roteirista confirma): item com níveis na **LOJA**, pago em **dinheiro**. Cada nível acelera o ritmo do auto-soco. Segue as 8 regras da seção 3.
- **"Memória muscular"** (nome provisório): **1 nó** do ramo Corpo da árvore. Toda carreira começa com o Metrônomo no nível 1. Conta dentro dos 8 a 12 nós da Fase 4, não soma nós.
- **A opção (a) fica descartada** (duplica os geradores e mexe nos minutos em que o jogador aprende o clique).

**Fase: entra na Fase 4 (árvore), como parte dela.** Não criar uma "Fase 3.5". Por quê:
1. **O dono ainda não jogou a Fase 3.** Uma 3.5 seria mais uma fase sem validação, e a recomendação forte da revisão continua: o dono joga antes de abrir qualquer coisa.
2. **O balanço vai ser refeito uma vez, na Fase 4**, com a árvore. Colocar renda nova antes obriga a balancear duas vezes.
3. **Os problemas que o Metrônomo ajuda estão na lista de riscos da Fase 4:** cansaço e tempo morto diante do Seu Muralha, dinheiro com pouco uso. E o nó "Memória muscular" precisa da árvore para existir.
4. **É pequeno.** É uma linha a mais numa loja que já existe, usando um caminho de clique que já existe e uma animação de jab que já existe. Não é um sistema novo de verdade.

Proteção contra inflar: se o escopo da Fase 4 passar do tamanho, o Metrônomo é o **primeiro item a ir para uma 4b**, antes de cortar nós da árvore. A árvore fecha o protótipo, e o Metrônomo não.

**Fase 5 em diante (só registrar, não fazer agora):** novas versões visuais do Metrônomo a cada local, e talvez um nó de Linhagem que melhora o ritmo inicial (Fase 7).

## 6. Perguntas para o dono (no máximo 3)

1. **Onde ele vive?**
   - A. Loja (dinheiro) + 1 nó na árvore. **Recomendação do Diretor.**
   - B. Só na loja.
   - C. Na garagem, pago em Treino.
   - D. Só na árvore (permanente).
2. **Quanto ele pode substituir a sua mão?**
   - A. "Ajudante": no protótipo, clicar sempre rende bem mais que deixar só o Metrônomo. O auto-clique só ganha a frente bem mais tarde (locais 3 em diante). **Recomendação do Diretor:** é o "clique perde relevância aos poucos" do PROMPT, sem matar o clique.
   - B. "Pode clicar por mim de verdade" desde cedo: dá para jogar quase sem clicar. Fica mais relaxado, mas briga com o "jogo ativo" e com o "não tão fácil".
3. **Quando entra?**
   - A. Junto com a árvore, na Fase 4, e é o primeiro item a sair se a fase ficar grande. **Recomendação do Diretor.**
   - B. Antes, numa Fase 3.5 pequena (atrasa a árvore e obriga a balancear duas vezes).
   - C. Depois, na Fase 5, junto com a loja maior da academia de bairro.

## Resumo para o Produtor
A ideia do dono é boa e **não duplica os geradores**, desde que o auto-clique dê cliques de verdade: número, crítico, animação do lutador com a luva, e crescendo com as melhorias de clique e a luva. Isso mantém a luva valendo mesmo com a mão parada. Se virar "+X Treino/s", vira um gerador repetido.
Recomendação: o **"Metrônomo"**, comprado em dinheiro na LOJA, com níveis que aceleram o ritmo, mais **1 nó "Memória muscular"** na árvore, para começar toda carreira com ele. Entra **na Fase 4**, junto com a árvore, sem Fase 3.5. Se a fase ficar grande, é o primeiro corte.
Regra de ouro: o soco do jogador continua sendo o mais pesado na tela (só ele faz a tela tremer), e clicar sempre rende bem mais que não clicar no protótipo. Isso ajuda no cansaço, mas não cura sozinho a espera diante do Seu Muralha: quem cura é o balanço da Fase 4.
Três perguntas ao dono: onde ele vive, quanto pode substituir a mão e quando entra.
