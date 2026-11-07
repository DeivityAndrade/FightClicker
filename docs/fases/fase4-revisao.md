# Fase 4 — Árvore de habilidades: revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-06.
Base: `PROMPT.md`, `docs/visao.md`, `docs/roadmap.md`, `fase4-escopo.md` (v2), `fase4-design.md`, `fase4-api.md`, `fase4-textos.md`, `fase4-qa.md`, `fase4b-escopo.md` (com as respostas do dono), o código (`ui/cartao_inicio.gd`, `ui/janela_fim.gd`, `ui/bloco_proxima.gd`, `ui/debug_overlay.gd`, `scripts/game_state.gd`, `data/*.json`) e as capturas do verificador e do QA.
Situação recebida: `run_tests.ps1` passa, o verificador dá 42 estados e 0 problemas, e os ajustes pós-QA (B1, B2, O1, título do cartão, O3) estão feitos.

## Veredito
**Aprovado.** Pode ir para o dono. Há duas tarefas pequenas antes de entregar (seção 3) e nenhuma delas bloqueia.

## 1. O que ficou bom
- **A derrota agora leva a uma escolha.** A tela de fim diz o atributo, o aparelho e "volte quando a prévia ficar verde". O botão ÁRVORE em destaque fica ao lado de NOVA CARREIRA. É o "perdi, mas já sei o que compro" do escopo.
- **A árvore se lê num olhar.** Duas colunas e um "Y" logo abaixo do 1º nó. Cada nó mostra o efeito em número curto, e os quatro estados (aprendido, comprável, falta X, pede o de cima) dá para distinguir sem ler. O título "O QUE O VELHO TE ENSINOU" acerta o tom pé no chão.
- **Os preços estão certos.** A derrota no Brutão (10) compra 1 nó. A derrota típica no Dinho (40) compra os dois primeiros e deixa uma meta visível (Memória muscular por 30, Olho clínico por 25). O cinturão compra 24% da árvore, e ela fecha na 6ª carreira.
- **O bônus aparece onde age.** O cartão de início dura 1,8 s. O 1º clique mostra "+2", e a prévia mostra "$75 (+50%)" e a porcentagem. A Memória muscular põe o Metrônomo tocando no minuto 0.
- **O Metrônomo está como a proposta aprovada.** É um objeto na prateleira, soca pelo caminho do clique, não treme a tela, tem número menor e som −14 dB, e para em qualquer janela. Clicar rende 3,8 a 4,5 vezes mais que ele, e o pilar "todo soco pesa" continua de pé.
- **A revanche tem o seu momento.** O selo "REVANCHE!" vem com "BRUTÃO DO POSTO NÃO ESPERAVA ESSA." (humor seco, no tom), e a marca "VOCÊ PERDEU PRA ELE" aparece na prévia e no HUD.
- **A cor nunca mente.** Os limiares de risco não mudaram e o teste de risco honesto passa.
- **O save do dono foi respeitado.** O v3 real abre na v4 com o Legado ×10 (18 vira 180), a carreira intacta e o arquivo sem alteração depois dos testes.
- **Os personagens novos (padrão `padrao-personagem`)** deixam a garagem cheia e a luta mais legíveis. A luva bate com a equipada no cursor, na garagem e na luta, e os pés ficam ancorados.
- **Fase do tamanho certo.** Nada de arte marcial, local ou Linhagem vazou. O Metrônomo coube sem precisar ir para a 4b.

## 2. Desvios da visão (nenhum grave)
1. **A revanche contra o Muralha depende da L1.** A linha "ESPERE FICAR VERDE" contra quem vem antes do algoz é honesta (só texto, a cor não muda), mas é o jogo dizendo o que fazer. Se o dono sentir o jogo "mandando", o próximo passo é deixar a linha mais suave, não remover. Hoje fica como está.
2. **A 1ª derrota pode vir em 1 golpe.** Na jogada do QA: "BRUTÃO VENCEU NO 1º ROUND / TIROU 100% DA SUA VIDA EM 1 GOLPE", numa luta lutada no amarelo. É honesto, e a tela explica. Mas é a derrota mais comum do jogo, e a visão pede "doer, não humilhar". Observar com o dono, sem mexer agora.
3. **O protótipo tem fim.** Depois do cinturão não há lutas, e com a árvore completa (6ª carreira) não há o que comprar. Está aceito (R3 do escopo), mas precisa ser dito ao dono antes de ele jogar muito.
4. **O caminho do Muralha é longo.** Cerca de 1 em 6 jogadores perde a 1ª carreira no Muralha, e aí os itens 1 a 5 do protótipo levam 42 a 48 min. Não fere nenhum critério, mas fere o "~20 min" para esse grupo.
5. **O número de dano na luta é pequeno** (fonte de 7 px, some em ~1 s). O juice da luta está abaixo do juice do clique. Fica para o polimento (Fase 9), a não ser que o dono reclame.

## 3. O que fazer antes de mostrar ao dono
1. **README:** ainda diz "Fase atual: Fase 3". Atualizar para a Fase 4 (árvore, Metrônomo, revanche) e copiar o roteiro de teste da seção 6. Dono: Programador.
2. **Tabela principal do `fase4_sim.py` (R2 do QA):** ela calcula a revanche do Muralha **sem** a L1 (22–32%), e quem lê só ela acha que o critério 25 falha. Rotular ou trocar pela versão com a L1. Não muda o jogo. Dono: Designer.
3. Pendência registrada, que não bloqueia: o critério 32 (40 min seguidos) e reabrir com a árvore aberta na janela não foram jogados ao vivo, só cobertos por teste automático. O QA roda os dois em paralelo à entrega ou no começo da 4b.

## 4. O protótipo do roadmap fechou? (itens 1–6)
| Item | Situação | Evidência |
|---|---|---|
| 1. Impacto do clique, número em todo clique | **Fechado** | 4.381 cliques e 0 sem número |
| 2. Geradores, renda passiva e sala ganhando gente | **Fechado** | Vizinho aos 0:59, Nelson aos 3:43, garagem cheia |
| 3. Perde, entende por quê, a carreira acaba | **Fechado** | a tela de fim aponta o atributo e o aparelho e manda esperar o verde |
| 4. Compra ao menos 1 nó | **Fechado** | `body_jab` com o Legado da derrota no Brutão |
| 5. Nova carreira, vai mais longe e vence o algoz | **Fechado** | QA: itens 1 a 5 em ~14:30; simulador: 20:58 a 5/s e 23:28 a 4/s (meta ~20, teto 25). Ressalva: caminho do Muralha (item 4 da seção 2) |
| 6. Quer jogar mais uma | **Aberto: só o dono responde** | o estúdio garante que há uma meta visível no fim da 2ª carreira (nó comprável ou a ≤ 1 carreira) |

**Do lado do estúdio, o protótipo fechou.** Ele só fecha de vez com o "sim" do dono no item 6.

## 5. Riscos para as próximas fases

### Fase 4b (aparelhos que chegam + Shift segurado)
- **R1. As metas da 4b estão no limite.** O tempo morto da carreira 1 está em p90 12:32 a 4/s, contra um teto de 13:00 (28 s de folga). O Treino gasto na esteira e na corda atrasa a areia e o tio. É o número que mais pode estourar. Se estourar, baixar o preço dos aparelhos. Os adversários não mudam.
- **R2. O Shift segurado contra a tendinite.** O dono escolheu "só segurando", e a decisão é dele. Mas segurar uma tecla também cansa a mão. O QA da 4b deve testar 5 min seguidos segurando, e o relatório pergunta ao dono se ficou confortável. O botão "segurar" na tela, para quem só usa o mouse, tem o mesmo problema.
- **R3. Textos desatualizados.** O escopo da 4b ainda fala em "toque liga/desliga", "preferência em `permanent`" e "AGORA: ... SÓ COM SHIFT". O Designer e o Roteirista partem das **respostas do dono** no fim do escopo. O texto da LOJA vira "SEGURE SHIFT". A preferência no save e o critério 26 saem.
- **R4. A 4b mexe no que a Fase 4 acabou de fechar:** foco, sala, aba TREINO, save v5, testes que assumem 3 aparelhos e a dica da tela de fim. Mitigação: rodar a bateria inteira e o verificador com 1, 2 e 3 aparelhos.
- **R5. O que já está certo.** A ordem saco → esteira → corda mantém de pé a dica "esteira" da derrota típica e a revanche de 95%. Com os aparelhos zerando a cada carreira, o ritual se repete em toda carreira. Medir se ele cansa na 5ª ou 6ª carreira.

### Fase 5 (academia de bairro e artes)
- **R6. A janela da árvore está cheia.** São 2 colunas × 3 linhas sem sobra. Os nós de arte (e depois a Linhagem) pedem um desenho novo: aba ou 3ª coluna. Planejar no escopo da Fase 5, não remendar.
- **R7. O balanço inteiro muda.** O cinturão deixa de ser o fim e vira mudança de local. As carreiras ficam mais longas, e o 23b, o tempo morto e a árvore fechando na 6ª precisam ser medidos de novo. O Legado de 750 por cinturão vai pagar também nós de arte. Revisar os preços de 500 a 900 junto.
- **R8. A arte vai ser o gargalo.** Cenário novo, aparelhos em versão nova, 2–3 aparelhos assinatura e possivelmente lutadores novos, tudo no padrão novo de personagem. O Artista de Personagens é uma pessoa só. O escopo da Fase 5 precisa de uma lista de arte enxuta.
- **R9. O Metrônomo e o modo assistido vão para a academia.** O visual por local ficou para as Fases 5 e 8. A Fase 5 decide se o prop muda ou se continua o mesmo, e decide isso no escopo.
- **R10. A dívida de dados.** A tabela do simulador sem a L1 (seção 3) e a sessão de 40 min não jogada precisam estar resolvidas antes do balanço da Fase 5, senão o estúdio mede em cima de dado errado.

## 6. Como o dono testa (~15 min)

**Antes de abrir:** o save está em `%APPDATA%\Godot\app_userdata\Fightclicker\save.json`. Se quiser guardar a carreira atual, copie esse arquivo para outra pasta. Ao abrir, o save antigo vira v4: a carreira continua e o Legado aparece ×10 (18 vira 180).
Abrir: Godot 4.7.2 → `E:\Fightclicker\project.godot` → **F5**.

### Parte A — sem F12, do zero (~12–15 min, é a que importa)
O F12 só entra aqui para apagar o save. Depois, aperte F12 de novo para esconder e não use mais.
1. **F12 → APAGAR SAVE → CONFIRMAR → F12.** O jogo recomeça na garagem.
2. **Clique no saco por 1 min.** Observe: número em todo clique, tela tremendo de leve, **o lutador novo** batendo. Compre o Vizinho e a Fita (aba TREINO). Observe **a gente nova** aparecendo na sala.
3. **Lute contra o Dudu** quando a prévia não estiver vermelha. Observe **a luta com os personagens novos**.
4. **Com o dinheiro, abra a LOJA.** O Metrônomo custa $80. Compre se quiser e observe: o objeto aparece na prateleira balançando, e o lutador soca sozinho, devagar, sem tremer a tela e com número menor. Abra a prévia: ele para.
5. **Siga até perder** (normalmente no Brutão ou no Dinho). A tela de fim diz o atributo, o aparelho e "volte quando a prévia ficar verde".
6. **ÁRVORE.** Compre 1 ou 2 nós (Jab de base e Bolsa negociada custam 10 cada). O Legado desce. Depois, **NOVA CARREIRA**.
7. **Carreira 2:** o cartão "O QUE VOCÊ TROUXE" aparece por ~2 s (clicar nele só fecha o cartão, não treina). O 1º clique mostra "+2" se você comprou o Jab.
8. **Revanche:** o bloco PRÓXIMA e a prévia mostram "VOCÊ PERDEU PRA ELE" e "ESPERE FICAR VERDE". Treine no aparelho da dica até a prévia ficar verde, lute e veja o **"REVANCHE!"**.
9. **Pare e responda:** quer jogar mais uma carreira?

### Parte B — com F12, atalho (~5 min, opcional)
- **"+10 DE CADA GERADOR"** algumas vezes: a renda passiva dispara, os atributos sobem sozinhos e as lutas ficam fáceis. Serve para ver o Seu Muralha, o cinturão, **APOSENTAR**, uma árvore com 750 de Legado (6 nós) e a carreira seguinte com a Memória muscular (o Metrônomo já toca no minuto 0).
- **"SALDO x1000"** multiplica só o Treino (compra a garagem toda), não o dinheiro nem os atributos.
- A Parte B não vale para julgar dificuldade nem ritmo. Ela só mostra o conteúdo.

### O que é placeholder
- Ícones dos nós, prop do Metrônomo e moldura da árvore: feitos pelo estúdio, podem mudar.
- Personagens: **protótipo** aprovado no padrão novo, ainda não é a arte final.
- Sons de impacto (o do Metrônomo é o do clique, mais baixo).
- O "velho" da árvore não tem rosto nem fala (o mentor entra na Fase 8).
- Cinturão sem mudança de local (aparece "liberado, chega na Fase 5").
- Nome do jogo (Fightclicker é nome de trabalho até a Fase 8).

## 7. Decisões para o dono revisar (por prioridade)
1. **Quer jogar mais uma?** (item 6 do protótipo) É a pergunta que fecha a fase.
2. **Dificuldade:** a 1ª carreira acaba em ~12–14 min. Cerca de 1 em 6 jogadores fica até ~10 min esperando o Seu Muralha, e a derrota no Brutão pode vir em 1 golpe. Está bom, mais fácil ou mais difícil?
3. **Metrônomo:** $80 / $150 / $300, de 1 soco a cada 2 s até ~1,4 por segundo. Sentiu como ajudante ou como "não precisa clicar"?
4. **"ESPERE FICAR VERDE" também antes do algoz:** ajuda ou parece o jogo mandando?
5. **O fim do protótipo:** a árvore completa sai na ~6ª carreira, e depois disso não há novidade até a Fase 5. Aceita?
6. Já assumidas, só para confirmar: Legado ×10, o Dinho pagando $800, árvore só entre carreiras e sem reembolso.

## Resumo para o Produtor
A Fase 4 está **aprovada**. Árvore, Metrônomo, revanche e dica do verde funcionam como o escopo pediu: 33 critérios, testes passando e 0 problemas de alinhamento.
Antes de entregar: atualizar o README (ainda diz Fase 3) e rotular a tabela do simulador sem a L1. Nenhum dos dois bloqueia.
O protótipo do roadmap fechou do lado do estúdio (itens 1 a 5 em ~14:30 na jogada do QA e ~21–23 min no simulador). O item 6, "quer jogar mais uma", só o dono responde.
O dono deve jogar a Parte A sem F12 (~15 min) e responder as 5 perguntas da seção 7. Na 4b, o maior risco é o tempo morto da 1ª carreira, que está a 28 s do teto.
