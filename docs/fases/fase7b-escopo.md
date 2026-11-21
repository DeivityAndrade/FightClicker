# Fase 7b — Muay Thai e a 2ª passiva: escopo

Diretor de Jogo, 2026-11-20. Base: `PROMPT.md` §5.7 ("Muay Thai: crítico e combos"), `docs/roadmap.md` (7b), `fase7a-escopo.md`
(§5 e **§8, decisões do dono**), `fase7a1-design.md`, `fase7a1-revisao.md`, `fase7a2-design.md`, `fase7a2-revisao.md`.

## 1. Objetivo e sensação
- **Objetivo:** chega a 3ª arte, o **Muay Thai**, com um jeito próprio de vencer. Depois, cada arte ganha uma **2ª passiva** que o
  jogador libera por meta e escolhe no lugar da 1ª. Com isso, uma arte passa a ter dois jeitos de montar o lutador.
- **Sensação:** "o meu lutador de Muay Thai **quebra a perna** do adversário. Dá para ver o cara mancando, e aí vem o chute
  rodado". Depois, na 7b2: "fiz 5 finalizações e o mestre me ensinou outro jeito de lutar Jiu-jitsu. Nesta campanha vou testar".

## 2. Divisão (a 7b inteira ficaria grande)
| Parte | O que traz | Ordem |
|---|---|---|
| **7b1 — Muay Thai** | a arte, o aparelho, a regra de treino, a passiva, os golpes, a variante do Choque, a região na árvore e a 3ª carta na escolha da arte | **primeiro** |
| **7b2 — Segundo caminho** | a 2ª passiva das 3 artes, liberada por meta e escolhida no começo da carreira | depois da 7b1 aprovada |

**Por que nessa ordem:** a 2ª passiva do Muay Thai só pode ser desenhada depois que a 1ª existe e foi testada. Além disso, a meta
da 7b2 usa as vitórias pela passiva, então o jogador precisa ter jogado a 1ª passiva antes. O custo de arte também fica separado:
os golpes do Muay Thai entram na 7b1, e a 7b2 quase só reaproveita animações.

## 3. 7b1 — Muay Thai
### 3.1 A passiva (o dono escolhe; detalhes e números são do Designer)
Regra para as 3 opções: as contas ficam no motor e a prévia usa a mesma conta, então **a prévia continua honesta**. O "certo"
do foco de treino tem de ser diferente do Boxe (AGILIDADE) e do Jiu-jitsu (RESISTÊNCIA e FORÇA).

| | **A — Canela (recomendo)** | B — Corrente de golpes | C — Clinch tailandês |
|---|---|---|---|
| Ideia | cada chute baixo que acerta deixa uma **marca na perna** dele (até 3–4). Cada marca deixa o adversário **mais lento** e aumenta o **seu crítico**. Com as marcas cheias, o crítico vira **chute rodado**, e o chute rodado pode derrubar | cada 3º acerto seguido vira um golpe de fechamento (joelhada ou chute) com crítico garantido. A corrente quebra quando **ele te acerta** | com a vida dele abaixo de X%, você **prende no clinch** por alguns segundos: ele não esquiva e cada joelhada tem crítico dobrado. A RESISTÊNCIA dele ajuda a escapar |
| Jeito de ganhar | **no meio da luta**: desgasta no 1º round e decide no 2º. Ganha quem bate mais forte, mesmo começando atrás | em rajadas | no fim, de perto |
| Atributo | **FORÇA** marca a perna, **AGILIDADE** faz o crítico | AGILIDADE | FORÇA |
| O que se vê | chute baixo, **adversário mancando** (com as marcas no HUD) e o **chute rodado** com letreiro próprio | 3 golpes e um letreiro de combo | os dois colados e as joelhadas |
| Diferença das outras artes | **muda o adversário**, enquanto o Boxe muda o próprio ritmo e o Jiu-jitsu muda o tempo. É o "crítico" do PROMPT, com cara própria | **parece o embalo do Boxe** (sequência de acertos). Risco de o jogador não ver diferença | **parece o clinch do Jiu-jitsu** (dois corpos colados) e custa mais arte |
| Custo de arte | médio (~10 animações, §3.4) | baixo | alto (luta de dois corpos, como a do JJ) |

**Recomendo A.** É a única das três que um testador reconhece sem ler nada: o adversário começa a mancar. Ela traz o "crítico e
combos" do PROMPT por um caminho que nenhuma outra arte usa. A **C não se perde**: vira a 2ª passiva do Muay Thai na 7b2, e o
clinch já fica desenhado como golpe na 7b1.

Táticas (o Designer fecha os números, no padrão da 7a1): **Agressivo** marca mais rápido e apanha mais. **Defensivo** marca
devagar e fica mais seguro. **Contra-ataque** responde com chute baixo e marca de graça.

### 3.2 A arte fora da luta
- **Regra de treino ("crítico"):** o clique já tem crítico (10%, ×3, `training.json`). O Muay Thai aumenta a chance e/ou o valor
  desse crítico. O Boxe é **clique constante** e o Jiu-jitsu é **equipe com o tempo**, então o Muay Thai fica sendo **clique com
  picos**. O Designer confere que ele não vira "Boxe melhor".
- **Aparelho assinatura:** o **saco comprido de chute**, pendurado baixo, na garagem e na academia, pelo padrão dos aparelhos de arte
  (comprado em caixa, com divisão própria de atributos puxando FORÇA e AGILIDADE). Os textos de crítico (`crit_texts`) são do
  Roteirista.
- **Árvore:** uma região MUAY THAI pequena, no espelho das outras duas: 1 nó de luta (raiz, 200, reforça a passiva), 1 nó ESTILO
  (1.200, reforça a regra) e 2 nós pequenos. A posição no mapa fica com o Designer e o UI/UX. Nenhum nó existente muda.
- **Especial dos cliques na luta:** letreiro e golpe próprios ("CHUTE RODADO!" ou o que o Roteirista achar). Não pode sobrar
  golpe de boxe no Muay Thai (é a lição do A1 da 7a1).

### 3.3 Variante do Choque (minigame da 7a2)
- Mesma tela, mesma barra, o mesmo Osmar e o mesmo prêmio. Muda só o **controle**, que tem de ter a cara da arte, como já
  acontece no Boxe (cliques) e no Jiu-jitsu (segurar e soltar).
- **Proposta: combo no tempo.** Os cliques entram num ritmo marcado na tela. O 3º clique dentro da janela vira **chute** e empurra
  muito mais; fora do tempo, o clique vira um empurrão fraco. Fôlego, rajada, pausa (×2) e finta continuam iguais.
- O Designer mede o teto de 10% em dias de campanha de novo, com o Muay Thai (pior trecho ≤ 10%). Os números de
  `data/minigames.json` que já estão travados não mudam.
- A Panfletagem não muda.

### 3.4 Golpes e custo de arte (Artista de Personagens, skill `padrao-personagem`)
| Quem | Animações | Pode cortar? |
|---|---|---|
| Lutador de Muay Thai | guarda tailandesa (`idle`), **chute baixo**, **joelhada**, **clinch tailandês** (pose de dois corpos), **chute rodado** | o clinch vira uma pose parada |
| Adversários (rig comum) | **acerto na perna**, **mancando** (idle), preso no clinch, queda pelo chute rodado | "mancando" vira o idle com 1 quadro torto; a queda reaproveita a do K.O. |

São cerca de **9 a 10 animações**, contra ~12 do Jiu-jitsu. **Ordem de corte:** (1) "mancando" vira 1 pose; (2) o clinch vira pose
parada, sem ciclo; (3) a queda pelo chute rodado usa a queda do K.O. **Não se corta:** o chute baixo, o adversário mancando
(mesmo que em 1 pose) e o chute rodado. Sem esses três, ninguém reconhece a arte.
No Choque, o lutador de Muay Thai precisa de 2–3 poses (empurrão, chute e guarda). O parceiro de treino reaproveita o do Boxe.

### 3.5 O que muda em cada tela
| Lugar | Muda |
|---|---|
| **Escolha da arte** | passa a ter **3 cartões** (o UI/UX confere se cabem lado a lado na 640×360; se não couberem, usar 3 cartões menores, nunca rolagem). Cada cartão traz o nome, a regra de treino, a passiva em 1 linha e o aparelho |
| **Como o Muay Thai é liberado** | o dono escolhe (pergunta 2). **Recomendo:** na 1ª vitória da escola contra o Kid (fim da liga da academia), o Osmar comenta numa fala curta e a 3ª carta aparece na próxima escolha. Quem já venceu o Kid ganha a arte ao abrir o save |
| **Arena** | **nenhuma arena nova** (a regra é "arena por liga", e liga nova só na 8a). O Diretor de Arte confere que o chute rodado cabe entre os pivôs (296/346) e que o letreiro novo lê bem nas duas arenas |
| **Prévia** | 1 linha da passiva, no padrão da 7a1: nome, **round em que as marcas enchem**, chance de chute rodado por golpe e "N EM 10 VITÓRIAS POR CHUTE RODADO". As marcas aparecem desenhadas. A linha muda junto com a tática |
| **HUD da luta** | contador de marcas na perna dele (3–4 ícones), adversário mancando e letreiro do chute rodado |
| **Motivo da derrota** | 1 linha quando a passiva pesou (ex.: "AS MARCAS NÃO ENCHERAM: FALTOU FORÇA"), sem simulação nova |

### 3.6 Balanço (7b1)
- **Três artes, nenhuma "a certa":** tempo até vencer o Kid com Boxe, Jiu-jitsu e Muay Thai, a 3 e a 4 cliques/s. A diferença entre
  quaisquer duas artes fica **≤ 15%**.
- A 1ª carreira não tem arte, então não muda.
- O Muay Thai não pode virar a escolha óbvia de quem clica muito. Se ele ficar à frente do Boxe a 4/s, o Designer ajusta o Muay
  Thai, **nunca o Boxe**.

## 4. 7b2 — A 2ª passiva
### 4.1 Como funciona (proposta)
- A 2ª passiva é **outro jeito** de lutar a mesma arte. **Não soma com a 1ª: o jogador escolhe uma das duas.** Assim existe escolha
  de verdade e nenhuma arte fica mais forte do que já é. A prévia honesta também fica simples, porque é sempre uma passiva por luta.
- **Quando se escolhe:** junto com a arte, no começo da carreira. O cartão da arte ganha 2 opções, e a 2ª fica com cadeado até a
  meta. A escolha vale para a carreira inteira, como a arte. Escolher luta a luta na prévia fica de fora (pergunta 4).
- **Direção das 2ª passivas** (o Designer fecha, o Roteirista dá nome). Todas reaproveitam animações existentes:

| Arte | 1ª (existe) | 2ª (proposta) | O que se vê | Arte nova |
|---|---|---|---|---|
| Boxe | Mão rápida: pressiona e vence cedo, por K.O., e cansa | **Contragolpista:** espera o erro dele. Cada esquiva sua carrega um contragolpe forte. Não cansa e vence tarde, por pontos ou K.O. no 3º round | guarda alta, esquiva e resposta | quase nenhuma (esquiva e contragolpe já existem) |
| Jiu-jitsu | Finalização: aguenta, enche a pegada e finaliza | **Por cima:** derruba cedo e castiga no chão (pressão e dano). Vence por dano ou pontos e quase não finaliza | queda no 1º round e a luta inteira no chão | quase nenhuma (queda e chão já existem) |
| Muay Thai | Canela: marca a perna e vence no chute rodado | **Clinch tailandês** (opção C da §3.1): de perto, prende, e as joelhadas viram críticos | os dois colados e as joelhadas | só o que a 7b1 deixou de clinch |

Cada 2ª passiva tem de **pedir outro foco de treino** e **combinar com outra tática** que a 1ª. Por exemplo, o Boxe da 1ª
passiva quer o Agressivo, e o Contragolpista quer o Contra-ataque. É essa diferença que dá o "jeito de montar o lutador".

### 4.2 A meta que libera a 2ª passiva (o dono escolhe)
| | Meta | Prós | Contras |
|---|---|---|---|
| **M1 (recomendo)** | **Dominar a 1ª:** vencer N lutas **pela passiva** com a arte (ex.: 5 K.O. de embalo, 5 finalizações, 5 chutes rodados), somando todas as carreiras da linhagem | ensina a 1ª passiva antes de dar a 2ª; dá para ver o progresso ("3/5"); combina com "a linhagem é a história" | quem só vence por dano demora mais. O Designer ajusta o N para cerca de 2 campanhas com a arte |
| M2 | **Cinturão com a arte:** vencer o Kid usando a arte | simples e fácil de entender | mede "chegar longe", não "dominar a arte"; quem tem dificuldade nunca vê |
| M3 | **Meta + Legado:** a meta acende um nó na região da arte, e o jogador compra o nó com Legado | usa a árvore que já existe | duas travas em sequência, mais lento; o nó compete com o resto da árvore |

O progresso aparece no cartão da arte ("3/5 FINALIZAÇÕES") e, ao bater a meta, numa linha na tela de fim ou numa fala curta do
mentor. Nenhum aviso insistente.

### 4.3 O que muda na 7b2
- **Escolha da arte:** o cartão ganha as 2 passivas, a 2ª com cadeado e progresso.
- **Prévia, HUD e motivo da derrota:** cada 2ª passiva tem a sua linha, o seu desenho e as suas notas, no padrão da 7a1.
- **Arena:** nada muda.
- **Balanço:** as 6 combinações (3 artes × 2 passivas) ficam a ≤ 15% entre si no tempo até o Kid. Nenhuma 2ª passiva pode ser
  "a 1ª melhorada". O que vale é o jeito diferente, não a força.
- **Save:** o progresso da meta e as passivas liberadas ficam no `permanente`, e a passiva escolhida fica na carreira. Se der para
  usar campos opcionais, continua v13; se não der, vira v14 com migração simples.

## 5. Fica de fora
| Item | Fase |
|---|---|
| Rival James Blindado, passiva dos adversários, liga, arena e local regionais | 8a |
| Ronda Noturna do vulto mascarado (minigame e fama do Gato Preto) | fase própria, perto da 8a |
| Campeão mundial, segunda arte e híbridos (MMA) | 9 |
| Arena nova (a 7b não traz liga) | 8a |
| Personagem novo para ensinar o Muay Thai (mestre tailandês etc.) | — (só se o dono pedir; a 7b usa o Osmar) |
| Escolher a passiva luta a luta, na prévia | — (só se os testadores pedirem; ver pergunta 4) |
| 3ª passiva por arte, troca de arte no meio da carreira | — |
| Mudança na Panfletagem, no convite do Osmar, no AQUECIDO ou nos números travados do teto de 10% | — |
| Mudança em preço, Legado, Honra, calendário ou escada | — |
| Carro comprido da garagem (pedido anotado do dono) | rodada de arte à parte, quando o Produtor marcar |

## 6. Save
- **7b1:** continua **v13**. A arte e o aparelho vêm de `data/`; liberar o Muay Thai é acrescentar `muay_thai` em
  `permanent.arts_unlocked`, que já existe. Save antigo abre sem erro, e quem já venceu o Kid recebe a arte ao carregar.
- **7b2:** campos opcionais (progresso da meta e passivas liberadas no `permanente`, passiva escolhida na carreira). Se o Designer
  precisar de mais, vira v14 com migração simples.

## 7. Critérios de aceite
### 7b1
1. **Reconhecer a arte olhando:** um testador vê 3 lutas sem HUD de texto (uma de cada arte) e acerta as três. No Muay Thai ele vê
   chute baixo, o adversário mancando e o chute rodado em pelo menos **1 de cada 3 vitórias** contra o Tonhão.
2. **Prévia honesta:** em 1.000 lutas simuladas por adversário com Muay Thai, a vitória real fica a **±5 pontos** da chance mostrada.
   A linha da passiva muda ao trocar de tática.
3. **Nada muda para quem não usa o Muay Thai:** sem arte, a foto (`foto.gd`) é igual à main. Com Boxe e Jiu-jitsu, as lutas e a
   chance são iguais às da 7a2, e a única diferença aceita é a lista de artes liberadas.
4. Luta curta: **8 a 20 s**, inclusive com o chute rodado.
5. **Balanço (§3.6):** as 3 artes ficam a ≤ 15% entre si no tempo até o Kid, a 3 e a 4 cliques/s. As metas da visão continuam valendo
   (1ª carreira 10–15 min, cinturão amador entre a 2ª e a 4ª carreira, tempo morto ≤ 10 min).
6. **Escolha da arte:** os 3 cartões aparecem inteiros, sem corte e sem rolagem. O Muay Thai aparece só depois da meta de liberação
   (pergunta 2), e o save antigo de quem já cumpriu a meta recebe a arte.
7. **Choque do Muay Thai:** clicar no tempo rende claramente mais que clicar afobado (perfis do simulador, como na 7a2), e o teto
   continua ≤ 10% em dias de campanha.
8. **Aparelho e árvore:** o saco de chute chega em caixa e treina pela própria divisão. A região MUAY THAI só aparece com a arte
   liberada, e nenhum nó antigo muda de efeito.
### 7b2
9. A 2ª passiva de cada arte só aparece liberada depois da meta. O progresso aparece no cartão e confere com o que o jogador fez
   (teste com lutas montadas).
10. **Escolha real:** em cada arte, a 2ª passiva pede **outro foco ou outra tática** que a 1ª. O Designer mostra numa tabela do tipo
    da §6.1 da 7a1, e um testador diz qual passiva está ativa só olhando a luta.
11. As 6 combinações ficam a ≤ 15% entre si (tempo até o Kid), e nenhuma 2ª passiva vence a 1ª em todos os adversários.
12. A prévia continua honesta (±5) com as 6 combinações.
### As duas partes
13. `tools/run_tests.ps1` verde, com testes novos usando **save de teste** (APPDATA temporário). Janelas abrem com
    `--position 1950,40`. A cópia do save do dono abre sem erro.
14. `ui_audit` com **0 problemas**. Precisa incluir: 3 cartões na escolha da arte (com cadeado e progresso na 7b2); prévia do Muay
    Thai nas 3 táticas; HUD com as marcas; letreiro do chute rodado nas duas arenas; Choque do Muay Thai (começo, combo, prêmio);
    região MUAY THAI da árvore.

## 8. Quem faz
| Papel | 7b1 | 7b2 |
|---|---|---|
| **Designer** | passiva escolhida (fórmulas, táticas, foco "certo"), regra de treino, divisão do aparelho, nós da árvore, Choque do Muay Thai, simulação (prévia honesta, balanço das 3 artes, teto de 10%) → `fase7b1-design.md` | as 3 passivas novas, a meta (N), progresso, balanço das 6 combinações → `fase7b2-design.md` |
| **Roteirista** | nome da passiva e do chute rodado, letreiro do especial, textos da prévia, do motivo da derrota e do cartão, `crit_texts` do saco de chute, fala do Osmar ao liberar a arte, nomes dos nós | nomes das 3 passivas novas, textos de progresso e de meta batida, 1 fala de mentor por arte (opcional, primeira a cortar) |
| **Diretor de Arte** | saco de chute (garagem e academia), ícones das marcas e da arte, letreiro do chute rodado, ícones dos nós, conferência do alcance do chute nas duas arenas | cadeado e progresso no cartão, ícones das passivas |
| **Artista de Personagens** | §3.4 (lutador e adversários), poses do Choque do Muay Thai | só o que faltar das 2ª passivas (meta: quase nada) |
| **Programador** | Muay Thai em `arts.json`/`moves.json`/`training.json`, passiva no motor e na prévia, liberação da arte, variante do Choque, testes; `docs/codigo/mapa.md` atualizado | passivas novas no motor, meta e progresso, escolha da passiva, save, testes |
| **UI/UX** | 3 cartões, linha da prévia, HUD das marcas, letreiro, Choque do Muay Thai, região da árvore; `alinhamento-ui` com 0 problemas | cartão com 2 passivas, cadeado e progresso, prévia e HUD das passivas novas; `alinhamento-ui` com 0 problemas |
| **QA** | critérios 1–8, 13, 14 | critérios 9–14 |

## 9. Riscos de design
- **Muay Thai virar "Boxe com chute".** As duas artes são de clique. Proteção: a passiva muda o adversário (marcas, mancando) em vez
  do próprio ritmo; a regra de treino é de picos (crítico), não constante; e o foco "certo" é FORÇA com AGILIDADE.
- **O chute rodado parecer sorte.** Proteção: as marcas são visíveis e previsíveis (a prévia mostra o round em que enchem), e o chute
  rodado só pode sair com as marcas cheias.
- **Custo de arte.** São ~10 animações; a ordem de corte está na §3.4. Se mesmo assim apertar, a 7b1 sai com o clinch só como
  pose, e a 2ª passiva do Muay Thai (que depende dele) espera.
- **2ª passiva virar power creep.** Proteção: ela é escolha (uma ou outra, nunca as duas) e o balanço das 6 combinações é medido.
- **Teto de 10% do minigame.** A margem já é curta (9,2%). Proteção: o Choque do Muay Thai usa o mesmo prêmio e o simulador roda
  de novo.
- **Escolha da arte apertada na tela.** 3 cartões em 640×360. Proteção: o UI/UX faz o mockup antes e passa pelo `alinhamento-ui`.

## 10. Perguntas para o dono
1. **Passiva do Muay Thai:** A "Canela" (marca a perna, adversário manca, chute rodado; recomendo), B "Corrente de golpes" ou
   C "Clinch tailandês" (recomendo guardar para a 2ª passiva)?
2. **Quando o Muay Thai fica liberado:** na 1ª vitória contra o Kid (recomendo: a arte nova vira um prêmio) ou já disponível para
   todos na próxima escolha de arte?
3. **Meta da 2ª passiva:** M1 "vencer 5 lutas pela passiva da arte, na linhagem toda" (recomendo), M2 "cinturão com a arte" ou
   M3 "meta + compra com Legado"?
4. **A 2ª passiva é escolhida no começo da carreira** (junto com a arte, vale a carreira toda; recomendo) **ou a cada luta**, na
   prévia, ao lado da tática?
5. As direções das 2ª passivas (Boxe "Contragolpista", Jiu-jitsu "Por cima", Muay Thai "Clinch") combinam com o que você imagina?

## Resumo para o Produtor
- A 7b fica dividida em duas partes. A **7b1** traz o **Muay Thai**: passiva "Canela" (marca a perna, o adversário manca, e o chute
  rodado decide), saco de chute, crítico no clique, variante do Choque, região na árvore e 3ª carta na escolha da arte. A **7b2**
  traz a **2ª passiva** de cada arte, liberada por meta.
- A 2ª passiva **substitui** a 1ª por escolha, nunca soma. Assim cada arte ganha dois jeitos de lutar sem ninguém ficar mais forte.
- Não há arena nova. A prévia continua honesta, as 3 artes ficam a ≤ 15% entre si e o teto do minigame continua ≤ 10%.
- O custo de arte da 7b1 é de ~10 animações, com ordem de corte definida. A 7b2 quase só reaproveita animações. O save continua v13
  na 7b1.
- São 5 perguntas ao dono: passiva do Muay Thai, quando ele é liberado, meta da 2ª passiva, quando a 2ª passiva é escolhida e se as
  direções das 2ª passivas combinam.

## Decisões do dono (2026-11-20) — "Aprovo tudo"
1. Passiva do Muay Thai: **A "Canela"** (chute baixo marca a perna, adversário manca, crítico sobe, chute rodado com as marcas cheias).
2. Muay Thai **liberado na 1ª vitória contra o Kid** (a arte nova é prêmio).
3. Meta da 2ª passiva: **M1** — vencer 5 lutas pela passiva da arte, somando a linhagem, com progresso visível.
4. A 2ª passiva é **escolhida no começo da carreira** e vale a carreira inteira (escolha, não soma).
5. Direções aprovadas: Boxe "Contragolpista", Jiu-jitsu "Por cima", Muay Thai "Clinch".
Ordem: 7b1 (Muay Thai) primeiro, depois 7b2.
