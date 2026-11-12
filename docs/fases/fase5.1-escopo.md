# Fase 5.1 — Garagem clara + caixa: escopo

Dono: Diretor de Jogo. Data: 2026-11-11. Branch: `fase-5.1`.
Base: `PROMPT.md`, `docs/roadmap.md` (5.1), `docs/propostas/feedback-2026-11-11.md` (itens 3, 6, 9, 10, 18 e respostas da 3ª rodada), `docs/fases/fase5-revisao.md` ("O que fica para depois"), `docs/fases/fase5-qa.md`, capturas em `%APPDATA%\Godot\app_userdata\Fightclicker\ui_audit_saida\`.

**Status: aprovado de antemão pelo dono** ("valido tudo depois"). O que ele precisa conferir jogando está na seção 7.

## 1. Objetivo e sensação
- **Objetivo:** a sala volta a ser o jogo. O olho cai no lutador, no aparelho e no número do clique; o resto aparece quando é útil. Equipamento novo chega numa caixa que o jogador abre com as próprias mãos.
- **Sensação:** "a tela respira e eu sei para onde olhar"; "chegou coisa nova, deixa eu abrir".

## 2. Diagnóstico (capturas `f5_garagem_boneco_depois.png`, `f5_gym_pera_foco.png`, `b4_tres_aparelhos.png`, `f5_previa_tonhao.png`)
- **Tudo tem o mesmo peso:** mesma fonte, mesmo tamanho, mesmo branco em atributos, loja, HUD, foco e dicas. Nada diz "isto é o principal".
- **Sala coberta de placas:** 3 plaquinhas laranja ("CORDA DEPOIS DA ESTEIRA", "BONECO DEPOIS DA ESTEIRA", "ESTEIRA 500 TREINO") + "SEGURE SHIFT" + "SEGURAR" + chip da arte, todos em cima da cena.
- **Informação repetida:** custo da esteira aparece na sala, na loja e no foco de treino. "Compre a corda" aparece em atributos e na sala.
- **Texto de cenário** (descrição do local) ocupa 1/4 da coluna esquerda o tempo todo.
- **HUD com 6 itens iguais:** Fama e Legado em jogo disputam com Treino, que é a moeda do minuto a minuto.
- **Prévia:** blocos colados (atributos, risco, tática, prêmio, aviso), sem respiro entre eles.

## 3. O que entra

### 3.1 Garagem clara (item 9) — vale para garagem e academia
**Três níveis de leitura:**
| Nível | O que é | Onde |
|---|---|---|
| 1. Sempre visível, grande | Sala com lutador e aparelho em foco; **Treino e +X/s**; **valor por clique**; botão LUTAR com a cor do risco | centro e topo |
| 2. Visível, discreto | Próxima luta (nome + risco), atributos com barra, foco de treino, a **compra mais barata disponível** destacada na loja, Dinheiro | colunas, tamanho médio, texto secundário apagado |
| 3. Sob demanda | Descrição do local, Fama, Legado em jogo, dicas de teclas (Shift, 1–4, F11), custos e detalhes de itens bloqueados, prêmio da luta | hover/dica, ou painel que abre |

**Hierarquia de tipo e cor** (o UI/UX fecha os valores; o Diretor de Arte aprova):
- No máximo **3 tamanhos** de texto: número-herói (Treino, por clique), título de bloco, texto comum.
- **Uma cor de destaque por moeda**, sempre a mesma em todo lugar: Treino, Dinheiro, Fama, Legado. Atributos mantêm as cores que já têm.
- **Texto secundário em baixo contraste** (rótulos, "CADA", descrições). Branco cheio só para o que é nível 1 e 2.
- Item comprável brilha; item que não dá para comprar fica apagado, sem cor de alerta vermelha no preço.

**O que sai da sala e do HUD:**
- Sai da sala: as plaquinhas de "depois da esteira" e de preço. Fica só a **marca de fita no chão/parede** (sem texto). O detalhe vai para a dica ao passar o mouse.
- Sai da sala: "SEGURE SHIFT" e "SEGURAR" fixos. Vira dica curta que aparece nas primeiras vezes e depois só no hover do botão.
- Sai da coluna esquerda: a descrição do local (vai para dica no nome do local, no HUD).
- Sai do HUD fixo: Fama e Legado em jogo como itens do mesmo tamanho. Ficam menores ou num grupo que abre (decisão do UI/UX, desde que continuem achados em 1 clique/hover).
- Itens bloqueados da loja ("CORDA — DEPOIS DA ESTEIRA"): 1 linha só, recolhidos.
- Nenhum número ou sistema some do jogo: só muda de nível.

### 3.2 Prévia com respiro (item 10)
- Espaçamento claro entre os blocos: quem é quem / atributos / risco / tática / prêmio e aviso / botões.
- Risco e LUTAR são o que mais pesa. Aviso "perder encerra a carreira" continua visível (é honestidade, não enfeite).
- Partir do que o Matheus já limpou. Sem mudar regra nem número.

### 3.3 Corda (item 3 + QA da Fase 5)
- Corda pendurada mais baixa, na altura de quem alcança (gancho/prego na parede, não no teto), na garagem e na academia.
- Corrigir os **2 quadros de repouso tortos** do giro (`fase5-qa.md`).

### 3.4 Caixa de equipamento (item 18 + respostas do dono)
- **Toda carreira começa só com o saco.** Vale também para cada nova carreira; nenhuma exceção nesta fase.
- **Chegam na caixa:** aparelhos novos (corda, esteira, aparelho da arte) e **luvas**. **Melhorias de aparelho continuam instantâneas.**
- Comprou → aparece uma **caixa** no lugar do aparelho (luva: caixa perto do lutador). Substitui a "chegada com poeira" de hoje.
- **3 cliques** para abrir, tremida maior a cada clique (racha, racha, abre), o item aparece com um "tchan" e o foco vai para ele (como hoje).
- Nunca abre sozinha, nunca some, sem prazo. Várias caixas podem esperar ao mesmo tempo.
- Clicar na caixa **não** gasta o clique de treino (o clique vai para a caixa) — o Designer confirma se perde muito Treino; se perder, a caixa fica fora do caminho do alvo central.
- Caixa fechada não treina (o aparelho ainda não existe). Save guarda caixas fechadas.
- **História sem texto:** a escola encomenda o equipamento de cada novo discípulo. A caixa tem etiqueta/remetente da escola. Nenhuma fala (fala só na 6a).

### 3.5 Top 3 animações
O dono não disse quais. Escolho as 3 mais vistas (validar com ele):
1. **Soco no saco + balanço do saco** (é o clique; precisa de peso e retorno).
2. **Corrida na esteira** (passo e esteira rolando em sincronia).
3. **Equipe treinando na sala** (Vizinho e Tio: ciclo mais vivo, menos rígido).
A abertura da caixa é animação nova da fase, não conta nas 3.

## 4. O que fica de fora
- Luvas L3/L4, teto do clique, luva que paga a equipe, Metrônomo/Shift, Jiu-jitsu no Kid → **5.2**.
- Calendário, datas, dia da luta → **5.3**.
- Árvore grande e o nó "corda já montada" → **5.4**.
- Qualquer fala, nome do 1º lutador, treinador → **6a**.
- Arena nova, golpes por arte → **7a**.
- Passe geral de animação e sons novos → **13 Polimento** (só o "tchan" e o rachar da caixa entram aqui, se o som já existir no projeto; senão, placeholder).
- Nenhum número de balanço muda, exceto o que a caixa exigir (seção 6).

## 5. Critérios de aceite
1. Mostrando a garagem por **5 s** a alguém que não conhece o jogo, ele aponta: onde clicar, quanto Treino tem e onde lutar.
2. Na sala não existe **nenhum texto fixo** sobre a cena (marcas sem texto; dicas só no hover ou nas primeiras vezes).
3. No máximo **3 tamanhos** de texto na garagem; cada moeda com **uma** cor, igual no HUD, na loja e nos preços.
4. Fama, Legado em jogo, descrição do local e teclas continuam achados em **≤ 1 hover ou 1 clique**.
5. Prévia: nenhum bloco encostado no outro; `ui_audit` em **0 problemas** em todas as telas mexidas (garagem, academia, loja, prévia, caixa).
6. Corda: pendurada na altura nova nas duas salas; os 6 quadros do giro sem quadro torto (captura de cada um).
7. Caixa: comprar corda, esteira, aparelho da arte e luva gera caixa; **3 cliques** abrem; ela não some com o tempo, nem ao trocar de foco, nem ao salvar e reabrir o jogo, nem ao lutar.
8. Nova carreira começa com **só o saco**, inclusive depois de aposentar na academia.
9. Melhorias de aparelho continuam **instantâneas** (sem caixa).
10. Metas da Fase 5 seguem de pé no simulador, com a caixa: 1ª derrota da carreira 1 em **10–15 min**; cinturão nunca antes de **20:00**; tempo morto **≤ 10 min**.
11. Save v6 → v7 (ou o número que vier) migra sem perder nada; aparelho já comprado num save antigo continua montado (não vira caixa).
12. `tools/run_tests.ps1` passa inteiro; testes não tocam o save real.

## 6. Riscos de design
- **Esconder demais:** o jogador para de achar Fama ou o prêmio. Proteção: critério 4 e o dono valida.
- **Caixa vira tarefa:** se cada compra pedir 3 cliques fora do alvo, vira burocracia. Proteção: só aparelho e luva (poucas por carreira); o QA conta quantas caixas aparecem numa carreira (meta: ≤ 6).
- **Começo de carreira travado:** sem corda e esteira no minuto 0, Agilidade e Resistência atrasam. Hoje já é assim (Fase 4b); a caixa só soma 3 cliques. Designer confere no simulador.
- **Caixa na frente do alvo:** clicar no saco não pode abrir a caixa por engano, nem o contrário.
- **Animação da caixa longa demais:** abrir tem que levar < 1,5 s do 3º clique até o item no lugar.
- **Cor por moeda brigar com cor por atributo** (ex.: Força vermelha x preço). O Diretor de Arte fecha a paleta antes do UI/UX aplicar.

## 7. O que o dono valida quando jogar
1. A garagem ficou clara? Sabe para onde olhar sem ler tudo?
2. Faltou alguma informação que ele usava (Fama, prêmio, descrição do local)?
3. A caixa: 3 cliques estão bons? A tremida e o "tchan" dão vontade de abrir?
4. Luva vir na caixa ficou bom ou ele prefere a luva instantânea?
5. As 3 animações escolhidas (saco, esteira, equipe) eram as que ele achava mais fracas? Se não, quais são as próximas 3.
6. A corda na altura nova e o giro sem quadro torto.
7. A prévia está confortável de ler?

## 8. Quem entrega o quê
| Papel | Entrega |
|---|---|
| **Designer** (Fable) | `fase5.1-design.md`: regra da caixa (estados, o que gera caixa, clique da caixa x clique de treino, várias caixas, save), migração de save, simulação com a caixa (critério 10), tabela "o que vai para cada nível" junto com o UI/UX |
| **Diretor de Arte** (Fable) | Paleta da hierarquia (cor por moeda, texto secundário), caixa em 3 estados (fechada, rachada, aberta) + lascas e etiqueta da escola, marcas sem texto, corda na altura nova nas 2 salas |
| **Artista de Personagens** (Fable) | 2 quadros de repouso da corda, soco no saco, corrida na esteira, ciclo da equipe (skill `padrao-personagem`) |
| **UI/UX** | Garagem e academia nos 3 níveis, tamanhos e cores aplicados, dicas de hover, prévia com respiro, caixa clicável com tremida crescente; skill `alinhamento-ui` até **0 problemas** |
| **Programador** | Estado das caixas em `GameState` + save, compra gerando caixa, abertura em 3 cliques, nova carreira só com o saco, migração, testes (save de teste isolado) |
| **Roteirista** | Etiqueta/remetente da caixa (curto, sem fala), textos das dicas de hover que substituem as plaquinhas |
| **QA** | `fase5.1-qa.md` contra os 12 critérios, contagem de caixas por carreira, regressão da Fase 5 |

## Resumo para o Produtor
A 5.1 limpa a garagem em 3 níveis (o principal grande, o útil discreto, o resto no hover), com 3 tamanhos de texto e uma cor por moeda; a sala perde todas as plaquinhas.
A prévia ganha respiro, a corda desce para a parede e os 2 quadros tortos são corrigidos.
Entra a caixa: aparelhos e luvas chegam numa caixa da escola que abre em 3 cliques e nunca some; melhorias seguem instantâneas e toda carreira começa só com o saco.
Top 3 animações escolhidas por mim (saco, esteira, equipe): o dono confirma ao jogar, junto com os outros 6 pontos da seção 7.
