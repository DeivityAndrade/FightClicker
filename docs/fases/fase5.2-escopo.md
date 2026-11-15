# Fase 5.2 — Clique sem teto: escopo

Dono: Diretor de Jogo. Data: 2026-11-12. Branch: `fase-5.2` (sobre a `fase-5.1`, ainda não integrada na `main`).
Base: `PROMPT.md`, `docs/roadmap.md` (5.2), `docs/propostas/feedback-2026-11-11.md` (itens 5, 11, 12, 16), `fase5-revisao.md` (decisões 1 e 2, "O que fica para depois") e `fase5.1-revisao.md` (seções 4 e 5).
Conferi: `data/shop.json` tem as luvas L1 e L2 (×2 cada, em $), e `data/training.json` tem o `golden_event` (×7 por 6 s, a cada 60–100 s). A **arte da luva L3 já existe completa**: sala, luta (todas as poses, golpes e quedas), ícone, cursor e luva pendurada. Falta só a arte da L4.

**Status: aprovado de antemão pelo dono** ("pode continuar", "valido tudo depois"). O que ele precisa conferir jogando está na seção 7.

## 1. Objetivo e sensação
- **Objetivo:** o clique nunca para de crescer e sempre paga, inclusive para quem vive da equipe. A academia ganha luvas novas para gastar o dinheiro, e os adversários sobem junto.
- **Sensação:** "comprei a luva nova e senti na mão"; "mesmo com a equipe forte, clicar ainda vale a pena"; "a luva dourada também serve para quem não clica muito".

## 2. O que entra

### 2.1 Luvas L3 e L4 em $ (item 12)
- 2 níveis novos na LOJA, pagos em **Dinheiro**, para gastar os $1.500 da chegada e os prêmios da academia. A L3 usa a arte que já existe; a L4 é a única arte nova da fase.
- Teto do clique mais alto. O multiplicador de cada luva quem decide é o Designer, em `data/shop.json`.
- **Tonhão e Kid sobem junto**, só pelo `data/`. A regra da Fase 5 continua: a dificuldade fica nos adversários, nunca cortando o clique.
- **L3 e L4 chegam na caixa**, como as L1 e L2 desde a 5.1: 3 cliques, perto do lutador, nunca some. Se o dono pedir a luva instantânea (pergunta 4 da 5.1), vale para as 4 luvas com a mesma troca de dado.
- Nomes e descrições ficam com o Roteirista. O tom continua pé no chão: é luva de academia, nada de luva mágica ainda.

### 2.2 Luva dourada da equipe (item 11)
- Variante do evento dourado que paga em **renda da equipe**: pegou, ganha de uma vez **30–45 s de renda passiva** (o valor exato fica com o Designer). Nome de trabalho: "Bolsa da torcida". O nome final é do Roteirista.
- Vive no **mesmo bloco `golden_event`** de `data/training.json`: a chance de cada variante, o valor e o visual diferente ficam todos em dado.
- Visual diferente da luva ×7, para o jogador saber o que vai ganhar antes de clicar. Usa a mesma regra de aparecer e sumir.
- Quem ignora não fica para trás, igual à luva ×7.

### 2.3 Clique que cresce com a equipe (item 16)
- **Uma** melhoria de clique (ou nó de efeito equivalente na LOJA da academia) que soma ao clique uma fração da renda da equipe por segundo. A forma e os números ficam com o Designer.
- É ela que mantém o clique vivo quando a equipe fica grande. Nada de sistema novo além dela.

### 2.4 Medida de late game (item 16, pilar do roadmap)
O Designer define o X e o simulador mede, a 3, 4 e 5 cliques/s:
- **Valor do clique:** no fim do conteúdo de hoje (Kid vencido, academia completa), **1 clique vale ≥ X% da renda por segundo**. Proposta de partida: X = 10%. O Designer pode mudar, com o motivo escrito.
- **Tempo morto:** ≤ 10 min seguidos (p90), medido também no fim da academia, e não só no começo da carreira.
- **Próxima coisa:** em qualquer momento da carreira existe algo comprável ou lutável em ≤ 10 min (p90).
- O resultado vira uma tabela fixa no `fase5.2-design.md`, para ser refeita em toda fase daqui em diante.

### 2.5 Metrônomo e Shift (item 5): só se os números pedirem
- Só mexe se a medida da 2.4 ou o tempo morto da carreira 1 mostrarem que precisa, ou se o dono disser que estão fracos depois de jogar a 5.1.
- Se mexer, é só número em `data/` (custo e intervalo), na linha "mudei sem pedido" do design.

### 2.6 Remedições obrigatórias
- **Jiu-jitsu a 3/s:** vence o Kid em 1–2 carreiras (mediana) e nunca depois do Boxe no mesmo perfil (dívida da Fase 5).
- **23b:** ≤ 25% (com tolerância de 2 pontos de ruído) e ninguém antes de 20:00, com 400 jogadores.
- **Tempo morto da carreira 1 a 3–4/s:** o p90 da 5.1 chegou a 11:31–13:32. Meta: p90 ≤ 10 min.
- **Robô x Dudu:** na 5.1 o robô do simulador perde mais para o Dudu. Descobrir se o motivo é o robô (decide mal) ou o jogo (3 s a menos de treino aos 3:00 por causa da caixa). Se for o jogo, corrigir por número; se for o robô, corrigir o robô e registrar.

### 2.7 Desvios de UI da 5.1 (opcionais, entram só se forem baratos)
Cada um vale no máximo meio dia do UI/UX. Se passar disso, fica para quando a tela for mexida de novo.
- **Um destaque só na loja:** hoje o mais barato tem contorno amarelo e o aparelho novo tem contorno laranja. Fica um destaque.
- **Contador "0/4"** das melhorias com folga embaixo do ícone.
- **Texto flutuante grande** ("+3 RESISTÊNCIA!", "A ESTEIRA GEMEU!") menor ou mais curto, sem cobrir metade da sala. O número de todo clique continua.
- Só entram depois de confirmar que o dono não respondeu o contrário no roteiro da 5.1.

## 3. O que fica de fora
- Calendário, datas, dia da luta → **5.3**.
- Árvore grande, nós novos de Legado (inclusive "clique com equipe" na árvore) → **5.4**. Nesta fase, o clique com equipe fica na **LOJA**.
- Qualquer fala, 1º lutador, treinador → **6a**.
- Luva com efeito de luta, arena da academia, golpes por arte → **7a**.
- Luvas além da L4, luva "absurda" → junto com os locais novos (**8a** em diante).
- Sons novos e passe de animação → **13 Polimento** (a caixa e a luva dourada usam os sons que já existem).
- Offline → **13**.

## 4. Critérios de aceite
1. **L3 e L4 na LOJA**, pagas em $, chegam na caixa (3 cliques) e mudam o visual: a L3 com a arte que existe, a L4 com a arte nova, na sala, na luta e no cursor.
2. Logo depois de chegar na academia (com os $1.500), o jogador **compra a L3 em ≤ 5 min** e sente a diferença no número do clique (pelo menos o dobro de antes).
3. **Luva dourada da equipe** aparece, paga 30–45 s de renda da equipe (valor em `data/`) e tem visual diferente da ×7. Mudar a chance ou o valor em `data/` muda o jogo sem mexer em código.
4. **Valor do clique no fim do conteúdo** ≥ X% da renda/s a 3, 4 e 5 cliques/s (X do Designer, partida 10%).
5. **Tempo morto ≤ 10 min (p90)** em todos os perfis, na carreira 1 **e** no fim da academia. A carreira 1 a 3–4/s cai do p90 de 11:31–13:32 para ≤ 10:00.
6. **OBRIGATÓRIO:** a 3/s, o **Jiu-jitsu vence o Kid em 1–2 carreiras** (mediana) e **nunca depois do Boxe** no mesmo perfil.
7. **23b:** ≤ 25% (tolerância de 2 pontos) e cinturão **nunca antes de 20:00**, com 400 jogadores.
8. Metas que seguem de pé: 1ª derrota da carreira 1 em 10–15 min; Boxe × Jiu-jitsu até o cinturão ≤ 10%; Kid em 1–2 carreiras a 4–5/s nas duas artes.
9. **Robô x Dudu:** causa explicada no design e taxa de derrota para o Dudu de volta ao nível da Fase 5 (ou a diferença justificada).
10. Save migra sem perder nada; quem já tem L2 vê a L3 disponível; caixa de luva fechada de save antigo continua.
11. Telas mexidas (LOJA, caixa, luva dourada e os desvios da 2.7, se entrarem) com `ui_audit` em **0 problemas**.
12. `tools/run_tests.ps1` passa inteiro e os testes não tocam o save real.

## 5. Riscos de design
- **Clique forte demais fura o 23b:** a luva nova mais a ×7 levam o cinturão para antes de 20:00. Proteção: o critério 7 trava. As alavancas são o preço da L3/L4 e o Tonhão/Kid, não cortar o clique.
- **Clique com equipe faz o Boxe e o Jiu-jitsu ficarem iguais:** se ele for forte demais, o Jiu-jitsu perde a identidade de "arte da equipe"; se for fraco, o Kid não fecha. O Designer mede as duas artes nos 3 perfis.
- **Luva da equipe vira a obrigatória:** se 30–45 s de renda passarem a valer mais que o ×7 para todo mundo, a ×7 some da cabeça. Ela tem que ser a melhor só para quem clica pouco.
- **Kid mais forte castiga quem clica pouco:** subir o Kid para casar com a L4 pode atrasar o perfil 3/s. O critério 6 é obrigatório e manda nessa conta.
- **Mexer em tudo ao mesmo tempo:** são luva, evento, melhoria e adversários juntos. O Designer simula uma mudança por vez e escreve qual mexeu em quê.
- **Escopo inchar pela 2.7:** ela é opcional e tem limite de tempo.

## 6. Perguntas abertas (não travam; o dono responde jogando)
- Quanto tempo de renda a luva da equipe deve pagar: 30 s ou 45 s? O Designer propõe e o dono sente.
- Chance de cada variante da luva dourada: meio a meio, ou a da equipe aparece mais para quem clica pouco? Recomendo **chance fixa em `data/`**, sem ler o jogador nesta fase.

## 7. O que o dono valida quando jogar
1. A L3 e a L4 dão sensação de "agora sim, o clique cresceu"?
2. Os preços em $ fazem sentido com o que a academia paga?
3. O Tonhão e o Kid ficaram justos com as luvas novas, ou ficaram fáceis ou difíceis demais?
4. A luva dourada da equipe: dá para saber de longe qual luva é qual? Ela ajuda quem "fica só upando a equipe"?
5. Com a equipe grande, clicar ainda dá prazer?
6. Metrônomo e Shift estão bons ou ainda parecem fracos?
7. Jogando de Jiu-jitsu clicando pouco, o Kid cai em 1–2 carreiras?
8. A arte da L4.
9. Se a 2.7 entrar: um destaque só na loja, "0/4" com folga e texto flutuante menor.

## 8. Quem entrega o quê
| Papel | Entrega |
|---|---|
| **Designer** (Opus) | `fase5.2-design.md`: preço e multiplicador da L3/L4, Tonhão e Kid novos, luva da equipe (valor, chance e regras), melhoria de clique com equipe, X da medida de late game, tabela de late game, remedições (critérios 5–9) com 400 jogadores no 23b, investigação robô x Dudu, linha "mudei sem pedido" |
| **Roteirista** (Sonnet) | Nomes e descrições da L3/L4, da luva da equipe e da melhoria de clique com equipe (tom pé no chão) |
| **Diretor de Arte** (Fable) | Arte da L4 (sala, ícone, cursor, luva pendurada) seguindo a L3; visual da luva dourada da equipe; conferir se a L3 que existe está no padrão atual |
| **Artista de Personagens** (Fable) | Lutador com L4 em todas as poses da sala e da luta (skill `padrao-personagem`), igual ao conjunto da L3 |
| **Programador** (Sonnet) | Luvas L3/L4 na LOJA com caixa, variante no `golden_event`, melhoria de clique com equipe, migração de save, simulador atualizado, testes com save isolado |
| **UI/UX** (Sonnet) | LOJA com as luvas novas, luva dourada da equipe na sala, desvios da 2.7 se couberem; skill `alinhamento-ui` até **0 problemas** |
| **QA** (Sonnet) | `fase5.2-qa.md` contra os 12 critérios, simulador rodado pelo próprio QA (23b com 400), regressão da 5.1 (caixa, hierarquia) |

## Resumo para o Produtor
A 5.2 tira o teto do clique: luvas L3 e L4 em $ (a arte da L3 já existe e só falta a da L4), chegando na caixa, com o Tonhão e o Kid subindo junto pelo `data/`.
Para quem vive da equipe, entram a luva dourada que paga 30–45 s de renda da equipe (mesmo bloco `golden_event`) e uma melhoria de clique que cresce com a equipe. Metrônomo e Shift só mudam se os números pedirem.
Critério obrigatório: a 3/s, o Jiu-jitsu vence o Kid em 1–2 carreiras e nunca depois do Boxe. Também refazemos o 23b com 400 jogadores, o tempo morto da carreira 1 (p90 ≤ 10 min) e a conta do robô contra o Dudu.
Os 3 desvios de UI da 5.1 entram só se forem baratos. O dono valida os 9 pontos da seção 7 quando jogar.

---

## Decisões do Diretor (design 5.2)

Data: 2026-11-12. O detalhe está no fim de `fase5.2-design.md`. **Nenhum número muda.**

| # | Ponto | Decisão | Efeito nos critérios desta fase |
|---|---|---|---|
| 1 | Tempo morto da carreira 1 a 3/s, p90 10:32 | Aceito. O Dinho fica ×1,4 (o ×1,45 empurraria a 1ª derrota a 4/s para 15:14) | Critério 5: carreira 1 ≤ 10:00 a 4–5/s e **≤ 10:32 a 3/s**. Academia ≤ 10:00. Remedir na 5.3 |
| 2 | Boxe × Jiu-jitsu até o cinturão, 20–27% | Opção **(a)**: aceito agora e corrijo na 5.4 com a árvore | Critério 8 (essa parte) medido pelo **controle** com os mesmos nós. **Na 5.4 vira obrigatório:** ≤ 10% na sequência, a 3/4/5 por s |
| 3 | Árvore do Boxe a 5/s fecha na 4ª carreira | Aceito (a mediana geral é 5) | Remedir na 5.4 |
| 4 | Kid na carreira da chegada a 5/s, 44–46% | Aceito. A meta antiga de ≤ 35% sai | Vale só "Kid em 1–2 carreiras (mediana) a 4–5/s". O dono confere no item 3 da seção 7 |
| 5 | O que mudou sem pedido: Dinho ×1,4 e melhoria 3 a $250K | Aceito | **Condição:** se o 23b do QA tiver cinturão **antes de 20:00**, a melhoria 3 vai para **$300.000** e o Designer remede os critérios 5, 7 e 8 |

Na 5.4 entram estes pontos: equilíbrio Boxe × Jiu-jitsu na sequência (custo do `style_bjj` e do `body_crew_2`) e a carreira em que a árvore fecha.
