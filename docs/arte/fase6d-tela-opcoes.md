# Fase 6d, item 4: tela principal maior (3 opções para o dono escolher)

Diretor de Arte, 2026-11-18. Só mockup: nada disto está no jogo. Pedido do testador: "melhorar a tela inicial, talvez aumentar
ela, às vezes deixar só a tela da academia, e as coisas que aparecem não ficarem numa aba própria".

## Como olhar
- **Prancha para decidir (1x, todas lado a lado, com a zona do alvo tracejada):**
  `docs/arte/mockups/fase6d_tela_comparacao_garagem.png` e `fase6d_tela_comparacao_academia.png`.
  Primeira linha = a tela de hoje. Depois A, B e C, cada uma **fechada** (esquerda) e **com um painel aberto** (direita).
- Cada tela solta, em 640x360 e em 2x (`_x2`): `docs/arte/mockups/fase6d_tela_<a|b|c>_<garagem|academia>_<fechado|aberto>.png`.
- Gerador: `tools/art/make_mockup_fase6d_tela.gd` (como rodar está no topo do arquivo). Base: capturas do `ui_audit`
  (`f6c2_mural_garagem`, `garagem_loja`, `f6c1_academia_cheia`), guardadas em 1x como `mockups/fase6d_ref_*.png`.

## O que é igual nas três
- **A sala ocupa a tela inteira (640x360).** A sala de hoje (384x272) **não sai do lugar**: continua em x 128, y 18, e o alvo
  continua em x 281..362. O que cresce é o fundo: as paredes laterais e o chão continuam em perspectiva (mesmo ponto de fuga
  320,-28) até as bordas. Vantagem grande: **nenhuma posição do manifest muda** (aparelhos, equipe, caixas, mentores, cenas).
- Tudo que fica por cima é **plaqueta flutuante**: painel `d1` com chanfro e sombra dura de 1 px, como os de hoje. Os cartões da
  loja e da equipe são **os mesmos de hoje, na mesma largura (128)**: nenhum texto muda de largura.
- **Zona do alvo protegida:** x 273..370 (o alvo + 8 px de folga), y 150..291 (do número do clique até o pé da sala). Fechado,
  nenhum painel encosta nela nas três opções (conferido na prancha). Aberto, também não: as gavetas param em x 484 ou x 180.
- **"Dá para comprar" sem texto:** aba ou ícone ganha contorno `col_buyable` (y2) e um selo com o número de coisas compráveis
  (verde = Treino, ouro = Dinheiro). É o que impede a loja escondida de virar loja esquecida.
- Os dois botões que hoje moram dentro da sala saem dela: o do **mapa** (132,22) vai para junto da próxima luta; o chip do
  **treino assistido** (faixa y 273..290) fica onde está, porque é da sala.
- Texto novo só na fonte 5x7 em 1x ou 2x: "+1 POR CLIQUE", "/CLIQUE", "FIXAR ABERTO", "LOJA", "TREINO", nomes dos focos.
  O maior nome de foco hoje ("ESTEIRA") ocupa 60 dos 86 px do botão compacto.

## Opção A: gavetas
Arquivos: `fase6d_tela_a_*`.
- **Sempre visível:** HUD de cima (igual ao de hoje), próxima luta + risco (canto de cima à esquerda), botão do mapa, LUTAR e
  Passar o posto (canto de baixo à direita, como hoje), uma plaqueta "SACO / +1 POR CLIQUE" (canto de baixo à esquerda) e 2 abas
  de borda: atributos (esquerda, os 3 ícones) e treino+loja (direita, com o selo de compráveis).
- **Como abre:** clique na aba = a gaveta desliza da borda (0,15 s). A da direita é a coluna de hoje inteira (com as abas TREINO e
  LOJA dentro); a da esquerda é o painel de atributos + próxima luta. A plaqueta do foco abre uma gaveta de baixo com os focos.
  **Fecham sozinhas:** clique na sala ou 2 s com o mouse fora. Trocar de aparelho também dá clicando nele na sala (já existe).
- **Cliques numa compra comum:** +1 (abrir a gaveta). Várias compras seguidas na mesma abertura: +1 no total. Trocar de foco
  pela gaveta: +1 (pela sala: 0).
- **Risco de esconder:** médio-alto. Atributos ficam escondidos (o jogador decide a luta olhando eles; o risco PERIGOSO continua
  à vista). Trocar de foco fica menos óbvio. Gaveta que fecha sozinha irrita quem está lendo um cartão.
- **Trabalho:** médio-grande. 3 gavetas (2 laterais + a de baixo) com animação, fechamento automático e abas com selo;
  reposicionar próxima luta e mapa; ajustar o `ui_audit` (estados da loja, foco e dica).

## Opção B: HUD mínimo
Arquivos: `fase6d_tela_b_*`.
- **Sempre visível:** Treino em 2x + treino/s + dinheiro (canto de cima à esquerda), próxima luta + risco (canto de cima à
  direita), LUTAR (canto de baixo à direita) e uma barra de 6 ícones (canto de baixo à esquerda): foco, atributos, equipe,
  loja, mapa, passar o posto. Nome, local, Fama e Legado saem da tela (vão para o pop-up de atributos).
- **Como abre:** clique no ícone = pop-up **preso ao ícone** (com rabicho), na metade esquerda da tela, longe do alvo. Fica aberto
  até o X, um clique fora ou ESC. Atalhos de teclado sugeridos: A, E, L, M.
- **Cliques numa compra comum:** +1 (abrir o pop-up); com atalho de teclado, 0 clique a mais. A loja e a equipe viram 2 pop-ups
  separados: quem compra das duas no mesmo minuto gasta +2.
- **Risco de esconder:** alto. Atributos, equipe, melhorias, Fama, Legado e nome do lutador somem; o jogador novo precisa aprender
  6 ícones sem texto (a dica perto do cursor do item 2 ajuda). O pop-up aberto cobre o lado esquerdo da sala (a equipe).
  É a sala mais limpa das três.
- **Trabalho:** grande. HUD novo, barra de ícones, janela-pop-up ancorada, dividir a coluna da direita em pop-ups, mover nome,
  Fama e Legado, atalhos; quase todos os estados de tela principal do `ui_audit` mudam.

## Opção C: híbrido
Arquivos: `fase6d_tela_c_*`.
- **Sempre visível:** HUD de cima (igual ao de hoje), atributos em miniatura (ícone + barra + número, 110x41), mapa, próxima luta
  + risco, e uma **faixa fina embaixo (30 px)** com por clique, os focos em uma linha (20 px), LUTAR e Passar o posto.
  Só a coluna da direita (equipe, melhorias, loja) sai da tela, numa aba de borda com selo de compráveis.
- **Como abre:** clique na aba = o painel entra pela direita (0,15 s), com as abas TREINO e LOJA de hoje dentro e um botão
  **FIXAR ABERTO**. Fixado, fica igual ao de hoje; solto, fecha com clique na sala.
- **Cliques numa compra comum:** 0 com o painel fixado (igual a hoje); +1 com ele solto. Foco: 0 (sempre na faixa).
- **Risco de esconder:** baixo. O que decide a luta (atributos, data, risco, foco) fica sempre à vista; só o que é compra se
  esconde, e o selo avisa quando tem coisa para comprar.
- **Trabalho:** médio. Uma gaveta só (a da direita) com fixar; faixa de baixo refeita; botões de foco e LUTAR compactos
  (sprites novos `ui_button_focus_*` de 20 px e `ui_button_fight_*` de 102x24, que eu faço); bloco de atributos compacto.

## Trabalho comum às três (o fundo largo)
- **Fundos 640x360 da garagem e da academia.** No mockup as bordas são a sala de hoje repetida em perspectiva: dá para ver a
  janela da academia repetida, as marcas de giz repetidas e emendas verticais nas paredes. Isso é placeholder de mockup. Para o
  jogo, eu redesenho os dois fundos largos por código (como os outros), com peças próprias nas paredes novas; a versão final
  pede pixel artist humano. O espaço novo também serve para os aparelhos das próximas artes (um por arte).
- **Cenas que saem pela borda da sala.** Hoje quem sai andando pela esquerda some atrás do painel (x < 128). Com a sala larga,
  o discípulo, o John e quem chega ficariam visíveis andando até x 0. Precisa de ponto de saída novo (porta) ou de andar até a
  borda da tela; vale para chegada, saída do John (garagem e academia) e primeira sucessão. Conferir com o Diretor de Cutscenes.
- O retângulo útil do balão (`balao.gd`, 132..507) pode crescer para a tela toda.
- `ui_audit`: os estados da tela principal mudam de lugar; a regra das 0 pendências continua.
- Para o "às vezes deixar só a sala": nas três dá para ter um modo **só a sala** (tecla ou botão de olho) que esconde tudo menos o
  Treino e o LUTAR. Na C isso é quase o estado fechado.

## Recomendação: C (híbrido)
É a que entrega o pedido (sala na tela toda, loja e equipe por cima e não numa coluna própria) com o menor risco: nada que
decide a luta some, a compra comum custa 0 clique com o painel fixado e 1 com ele solto, e o trabalho é o menor das três
(uma gaveta só, mesmos cartões). De quebra eu pegaria da B os atalhos de teclado (L = loja, E = equipe) e o modo "só a sala".
A cabe se o dono quiser a sala ainda mais limpa; B é a mais bonita parada e a mais cara, e esconde demais para quem está começando.
Sugestão de corte: os fundos largos + a opção escolhida vão juntos numa **6d2**, porque o fundo largo mexe com as cenas.
