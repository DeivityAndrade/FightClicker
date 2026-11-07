# Fase 2 — Treino na garagem: revisão do Diretor

Data: 2026-11-05. Base: `fase2-escopo.md`, `fase2-design.md`, `fase2-textos.md`, `fase2-api.md`, `fase2-qa.md`, `docs/visao.md`, `docs/roadmap.md`, `README.md`, código (`scripts/`, `ui/`, `scenes/`, `data/`) e screenshots da UI (`scratchpad\ui2\shots\`) e do QA (`scratchpad\qa2\r1080_*`, `real_*`).

## Veredito
**Aprovado, com 2 ajustes pequenos recomendados (não bloqueiam).** Pode ir para o dono.
- **24 de 24 critérios.** O QA deu 23 OK. O 24º falhava só por um teste de texto (BUG-1), que foi corrigido. A bateria `tools/run_tests.ps1` passa inteira: 446 checks, a cena e o guarda do save real.
- Os 6 bugs do QA foram corrigidos: texto do efeito, sobreposição dos números (o crítico coberto caiu de 59% para 2–8% dos quadros a 10 cliques/s), nome no MÁXIMO, sobra de teste antigo, maiúsculas e README.
- Conferi no código: número mais recente por cima, crítico sempre acima dos normais e empurrão dos números antigos (`ui/sala.gd`, `_mostrar_numero` / `_afastar_antigos`). O efeito vem de `ui_texts.json` (`GameState.texto_efeito_melhoria`).
- Os 2 ajustes estão em "O que mudar antes de mostrar". Dá para mostrar sem eles, avisando o dono.

## O que ficou bom
- **A garagem tem alma.** Lâmpada fraca, carro coberto de lona, saco com fita, giz no chão, portão de enrolar. É pé no chão e meio melancólico, como pede o tom. A identidade é própria: nada lembra Punch Club.
- **O alvo central funciona.** O ponto de clique não muda com o foco. Teclas 1/2/3, botões e clique no aparelho lateral trocam o foco na hora, e o clique lateral não gera treino (não dá para "trapacear" clicando em tudo).
- **O juice está completo:** número em todo clique (101 de 101 a 10 cliques/s), golpe do lutador, saco que balança, faísca, tremida de pixel inteiro, 4 sons de soco que não se repetem em seguida, lâmpada que pisca no crítico. O crítico (`+9 FORÇA!` em 2x, com "PEGOU DE JEITO!") é o melhor momento da tela.
- **Cursor = luva**, a mesma da mão do lutador, achatada quando o botão está apertado.
- **A sala ganha vida:** vizinho e tio entram com poeira e brilho. O saco, a corda e a esteira trocam de sprite na primeira melhoria. O limite de desenho segura 250 unidades sem lotar a sala.
- **Nada adiantado.** Não aparece `$`, fama, Legado, luta, aposentar nem próximo local. As falas de mentor e rival ficaram só no documento. O crítico não usa Agilidade.
- **Moeda única bem resolvida.** Gastar nunca mexe em atributo (20 mil ações aleatórias provam). O HUD separa saldo e atributos. E "saldo na tela ≥ preço" é exatamente "pode comprar" (o saldo é truncado e o custo tem 3 dígitos exatos).
- **Dados fora do código** (`training.json`, `generators.json`, `ui_texts.json`). O simulador do Designer bate com o jogo jogado pela UI. O save v2 já vem agrupado em `career`, e a migração v1→v2 está testada, inclusive com saves estranhos.
- **Os riscos herdados da Fase 1 foram tratados:** `viewport` com escala inteira e fonte 5x7 legível em 1280x720, F11 para tela cheia, depuração escondida no F12 e só em build de debug.

## Desvios da visão
### Pilar 1, "Todo soco pesa": cumprido nesta fase, com 3 ressalvas
- **O peso é só sensorial por enquanto.** Força, Agilidade e Resistência ainda não fazem nada. É o combinado (o efeito vem na Fase 3), mas é o motivo de o pilar ainda não estar "provado".
- **O clique para de crescer cedo.** Com as duas melhorias do aparelho (~5 min), o clique fica em 15 (crítico 45) até o fim da fase. Aos 15 min o passivo empata com o clique (99–115%). Pela regra o clique "nunca vira inútil", e ele não vira: parar de clicar ainda custa ~50% da renda. Mas, depois dos 10 min, o jogador clica por prazer e não por progresso. Isso é "fim de conteúdo" da Fase 2, não defeito.
- **Legibilidade em rajada.** O `+N FORÇA` vermelho claro sobre o saco vermelho tem pouco contraste (dá para ler pelo contorno). A 10 cliques/s a sala treme quase sem parar. Não incomoda nas capturas, mas é a pergunta 2 do escopo para o dono.

### Pilar "Não tão fácil": aceito para a Fase 2, mas não está provado
O escopo já dizia: o começo tem que ser rápido e generoso, e a dificuldade vale para a carreira inteira. Avalio cada caso:
- **8 cliques/s chega no tio aos ~3:40** (meta de 5–8 min). Aceito. Num jogo ativo, quem clica muito tem que ser premiado. Não dá para o mesmo preço servir 3 e 8 cliques/s sem punir alguém.
- **3 cliques/s chega no tio aos ~8:40**, um pouco além da meta, quando compra a melhoria primeiro. Aceito. É jogador lento e quase dentro da faixa.
- **Rodízio de foco dá passivo alto (até 194% do clique aos 10 min)**, e o jogador impulsivo também (144–157%). É o único caso que olho com cuidado. O motivo: as melhorias multiplicam só o clique do aparelho em foco, então quem troca de foco clica "mais fraco" e o passivo pesa mais. **Não é problema na Fase 2** (ninguém sai prejudicado e a renda total é parecida). Na Fase 3 vira vantagem de design: quem treinou os 3 atributos chega mais preparado contra adversários de perfis diferentes. Não mexer agora.
- **O que de fato falta para "não tão fácil":** risco. Hoje não existe decisão que dê para errar. Comprar errado só atrasa. Isso é da Fase 3 (lutar ou pendurar as luvas) e não se resolve com preço de garagem.
- **Conclusão:** nenhum número muda antes da Fase 3. Os preços da garagem só serão revistos quando o ritmo de luta existir (ver riscos).

### Desvios menores (encontrados na revisão)
1. **Foco na corda, parado:** o lutador fica no centro sem a corda na mão. A corda some do prego e só aparece durante o clique (`_pose_repouso` esconde `_corda_giro`). Na captura `r1080_e_foco_jump_rope.png` não dá para ver que ele "está na corda" até clicar. Fere de leve o critério 6 ("lutador no aparelho certo"). Saco e esteira estão corretos.
2. **Efeito da melhoria mostra só o próximo multiplicador.** Com a fita comprada, a próxima melhoria diz "X5 POR CLIQUE: SACO", mas o clique vai de 3 para 15. Está correto (×5 sobre o atual), mas um jogador pode esperar 5. Fica para a Fase 9 ou para quando a loja crescer.
3. **Screenshots antigos.** `06_meio_de_jogo.png` e `07_critico.png` ainda mostram "X5 POR CLIQUE NO SACO" e dicas em caixa mista, de antes do BUG-1/BUG-5. `rajada_criticos.png` já está no formato novo. **Não usar 06 e 07 na apresentação ao dono.**

## O que mudar antes de mostrar ao dono
- **(Recomendado, UI, ~minutos)** Desvio 1: mostrar a corda na mão do lutador parado quando o foco é a corda (um quadro de repouso do `rope_l*_swing` ou do sprite do prego junto do lutador).
- **(Recomendado, UI)** Se for barato: clarear um pouco o `+N FORÇA` normal ou dar mais contorno sobre o saco. Se não for, deixar para a Fase 9.
- **(Obrigatório, Produtor)** Tirar capturas novas para a apresentação, ou usar só as do formato atual.
- **(Obrigatório, Produtor)** Dizer ao dono, com todas as letras, que **arte e som são placeholder**: sprites gerados por código em `tools/art`, sons sintetizados por `tools/sfx/make_sfx.gd`. Eles parecem finais, e é por isso que precisa avisar.

## Riscos herdados para a Fase 3 (Lutas e fim de carreira)
### Tratar na Fase 3
- **R1. Mudança de regra: "foco fixo é ótimo" → "um atributo só perde".** Na Fase 2 o melhor é ficar no saco. Na Fase 3 a visão quer adversários de perfis diferentes. A **primeira luta e a prévia** têm que ensinar isso: risco claro e "faltaram 120 de Resistência". Senão o jogador que aprendeu a garagem se sente enganado.
- **R2. Atributos e adversários na mesma escala.** Aos 10 min um jogador tem ~20K–90K de treino total, quase todo num atributo. O Designer da Fase 3 precisa calibrar os adversários amadores sobre **essa curva** (3, 5 e 8 cliques/s, foco fixo e rodízio) e mirar na meta da visão: a 1ª carreira acaba em derrota em 10–15 min.
- **R3. "Fim de conteúdo" aos ~10–15 min.** A garagem esgota as melhorias. A Fase 3 precisa dar o próximo objetivo exatamente aí: a luta e os itens pagos em dinheiro (gerador que cobra, equipamento de loja). Não inventar melhoria de Treino nova para tapar o buraco.
- **R4. Preços da garagem revistos com as lutas.** Tio cedo a 8 cliques/s, passivo alto no rodízio, `growth` 1.25 versus 1.3: decidir com o ritmo de luta na mão, tudo em `data/`.
- **R5. Fim de carreira apaga a garagem.** Geradores, melhorias, saldo e atributos se perdem (`docs/visao.md`). Precisa de save v3 com `career` separado do permanente (Legado). Se o permanente for para outro arquivo, **o guarda dos testes precisa olhar esse arquivo também** (risco anotado na Fase 1).
- **R6. Clique durante a luta.** Se entrar, é um boost pequeno e opcional (PROMPT §5.6). Não pode virar reflexo nem obrigação, e deve reaproveitar o juice que já existe.
- **R7. Troca de luva.** A luva de loja (Fase 3 em diante) tem que trocar ao mesmo tempo o cursor e a mão do lutador. Hoje a luva é fixa. O `manifest.json` já liga as duas à mesma arte: manter assim.
- **R8. Perguntas do escopo ainda sem resposta do dono:** (1) comprar com Treino na garagem, para sempre; (2) tremida em todo clique. A (1) precisa estar confirmada **antes** do design da Fase 3, porque define o que o dinheiro compra.

### Pode ficar para depois
- Opção de desligar a tremida, volume e sons a mais para corda e esteira (hoje 2 cada): **Fase 9**.
- Teste de sessão longa em tempo de relógio (vazamento de memória em horas de jogo), o aviso "ObjectDB leaked" nos scripts de QA e o DPI de 125% (risco da Fase 1, ainda não testado): **Fase 9**. Peço que o QA da Fase 3 teste o DPI de 125% de passagem, se for barato.
- F12 em build exportado (hoje só testado em debug): conferir no primeiro export, no máximo na **Fase 10**.
- Janela em 1080p com escala x2 e faixas largas: já tem F11. Menu de resolução na **Fase 9**.
- Texto do efeito mostrando o multiplicador total: **Fase 9**.

## Como o dono testa (uns 5 minutos)
Antes de começar: **a arte e o som são provisórios**, feitos pelo estúdio por código. O que vale julgar agora é o ritmo e a sensação do clique, não o acabamento.

1. Abra o Godot 4.7.2, abra o projeto `E:\Fightclicker\project.godot` e aperte **F5**. Abre direto na garagem.
2. **Primeiros 10 segundos, sem ler este roteiro:** você acha onde clicar? (Tem uma seta amarela e o rodapé "CLIQUE NO SACO PARA TREINAR".) Esse é o critério que só uma pessoa consegue testar.
3. **Clique no saco por 1 minuto, num ritmo normal.** Observe:
   - todo clique mostra `+1 FORÇA`, o lutador soca, o saco balança e a tela treme 1 pixel;
   - o som varia um pouco a cada soco;
   - mais ou menos 1 em cada 10 cliques é **crítico**: número grande, dourado, com "!" e uma frase ("NA MOSCA!");
   - o cursor é a luva do lutador.
4. **Com 60 de Treino, clique em CHAMAR no "Vizinho da casa 12".** Um rapaz entra na sala, e o "/s" do topo e o "AUTO" de baixo sobem.
5. **Com 300, clique em MELHORAR em "Fita nova no saco".** O saco troca de visual, e o "POR CLIQUE" vai de 1 para 3.
6. **Sem mexer o mouse, aperte 2 e depois 3**, e continue clicando no mesmo lugar. O lutador vai para a corda e depois para a esteira. Agilidade e Resistência passam a subir, e a renda passiva também passa a ir para o foco atual. Aperte 1 para voltar ao saco.
7. **Atalho para ver o resto (cerca de 1 min):** aperte **F12**, clique em "SALDO x1000" e compre o "Tio aposentado" e as melhorias dos 3 aparelhos. Depois clique algumas vezes em "+10 DE CADA GERADOR" e veja a sala encher até um limite, sem travar a compra. O painel do F12 cobre a sala de propósito: ele é só para teste.
8. **F11** liga e desliga a tela cheia (fica maior e nítida).
9. Feche pelo **X**, aperte F5 de novo e confira que tudo voltou igual.
10. Para recomeçar limpo depois do atalho: F12 → "APAGAR SAVE" → "CONFIRMAR".
11. (Opcional, 10 min) Jogue do zero sem o F12. Clicando num ritmo normal, o tio deve sair entre 5 e 8 minutos.

**Perguntas para o dono responder depois de testar:**
- Comprar tudo da garagem com Treino (e o dinheiro só chegar com as lutas): ok?
- A tremida em todo clique: ok, ou prefere só no crítico?
- O som cansou em 5 minutos?
- O ritmo pareceu fácil demais, certo ou lento demais?

## Resumo para o Produtor
A Fase 2 está aprovada: 24 de 24 critérios, os 6 bugs do QA corrigidos e a bateria de testes passando inteira.
A garagem tem tom e identidade próprios, o clique tem juice completo e nada das fases futuras aparece na tela.
Antes de mostrar, recomendo um ajuste pequeno da UI: a corda tem que aparecer na mão do lutador quando ele está parado com foco na corda. Também é preciso avisar o dono que arte e som são placeholder, e não usar as capturas antigas 06 e 07.
O "não tão fácil" ainda não está provado, porque a garagem não tem risco. Fica para a Fase 3, que também tem que ensinar que treinar um atributo só perde.
Antes do design da Fase 3, o dono precisa confirmar se a garagem continua sendo paga em Treino.
