# Identidade visual: 3 direções para o dono escolher

> **Decisão: o dono escolheu C (cartaz de luta) em 2026-11-25.** A recomendação abaixo (B com o C nas telas de luta) fica
> só como registro. Menu v2 da C (composição no eixo, animação da faixa e 3 fundos): ver "Menu C v2" no fim deste arquivo.

Diretor de Arte, 2026-11-25. O ponto de partida é a crítica de que o HUD e a barra dos focos, em marrom-acinzentado,
têm "cara de IA". Isto é só **mockup** (nada em `ui/` ou `scenes/` mudou).
Gerador: `tools/art/make_mockup_identidade.gd` (headless; rodar como diz o cabeçalho). Ele usa a captura real da garagem com a UI
antiga coberta, a rua da Ronda e a fonte 5x7 do projeto (o BMFont, lido direto do `.fnt`).

Imagens em `docs/arte/mockups/identidade/`:
`identidade_{a,b,c}_sala_x2.png`, `identidade_{a,b,c}_janela_x2.png`, `identidade_{a,b,c}_menu_x2.png` e a prancha `identidade_comparativo.png`.

Nas 3 direções valem as mesmas regras:
- As cores da história: o **vermelho da faixa do vulto** (`r1/r2/r3`), o **azul do carimbo Raízes** (`b0/b1/b2`), o **creme** (`cream/white`)
  e o **asfalto** (`ink/d1/d2`). O marrom-acinzentado sai de todo painel.
- As cores dos tokens não mudam (Treino verde, Dinheiro ouro, Fama rosa, Legado roxo).
- Os mesmos retângulos de hoje: HUD com 18 px, barra com 30 px, focos de 86 px a cada 90 px, LUTAR com 102x24.
  Assim dá para trocar a pele sem mexer no layout nem no `ui_audit`.
- O texto de cada botão é centralizado pelo próprio gerador, que mede a largura visível do texto. Ele avisa quando algo não cabe;
  nesta rodada não houve nenhum aviso.

---

## A) Vidro pixelado

Os painéis são "cápsulas" de vidro azul-asfalto que flutuam sobre a sala. Cada uma tem uma borda de luz (branco em cima, `b3` nos lados),
dois filetes diagonais de reflexo e um gelo em dither Bayer (o "fosco" sem blur), além de 1 px de sombra embaixo. O HUD vira duas cápsulas, e
a barra vira uma doca. O LUTAR é um vidro vermelho.

| Papel | Cor | Hex |
|---|---|---|
| Vidro (tinta, alfa 62% no HUD e 88% na janela) | `b0` | #1f2a44 |
| Borda de luz / reflexo | `white` / `b3` | #f2ece0 / #8fbbe0 |
| Botão neutro (vidro azul, alfa 55%) | `b1` | #2f4a78 |
| Botão principal / foco ativo | `r2` (LUTAR) / `r1` (foco) | #d4473a / #9c2a2a |
| Texto 1 / texto 2 | `white` / `cream`, `b3` | #f2ece0 / #d9cdb4, #8fbbe0 |
| Escurecer atrás da janela | `ink` com alfa 55% | #14101a |

**Leitura em 640x360:** o texto branco sobre o vidro fica perto de 12:1 onde a sala é escura. O problema é onde a sala é clara (lâmpada,
cartaz SOCO, porta de enrolar): ali o fundo aparece atrás do texto. Por isso a janela usa alfa 88% e o reflexo nunca passa de 13%.
A borda de luz de 1 px é o que dá a identidade, mas em 1x ela é discreta: na tela pequena a direção A lê como "painel escuro elegante".
**As cores fora da paleta** são o ponto fraco: o alfa mistura a cena com o azul e cria tons que não estão na tabela. É uma exceção
assumida da regra do §3, ou então um shader que arredonda para a paleta (quantização).

**Custo: baixo a médio.** São StyleBox ou NinePatch com alfa (o chanfro de 2 a 3 px numa textura 9-slice pixel-exata), mais uma textura
de reflexo e de gelo repetida por cima. Não precisa de blur nem de shader obrigatório. Mudanças no `ui_tema.gd`: as fábricas
`painel` e `botao` e os estilos de botão. É a mais rápida de pôr no jogo.

## B) Lona e placa de academia

O HUD é uma **lona esticada**: creme com trama em dither, bainha costurada e ilhoses de aço nas pontas. Os grupos do HUD são separados
por **fitas vermelhas**. A barra de baixo é uma **placa pintada** no azul do carimbo Raízes, com parafusos e pinceladas. Os focos são
**fitas** de ponta rasgada: vermelha no ativo, creme no comprável, cinza no trancado. O LUTAR é um **letreiro vermelho pintado** e
parafusado. As janelas são lonas amarradas por cordas, com o título pintado numa fita. No menu, a faixa de lona fica pendurada
sobre a rua.

| Papel | Cor | Hex |
|---|---|---|
| Lona / trama / bainha | `cream` / `g3` / `g2`, `white` | #d9cdb4 / #b8b0aa / #8f8890, #f2ece0 |
| Placa pintada (base / pincelada / luz) | `b1` / `b0` / `b2` | #2f4a78 / #1f2a44 / #4d7bb3 |
| Fita vermelha / letreiro LUTAR | `r2`, luz `r3`, sombra `r1` | #d4473a, #f07a5a, #9c2a2a |
| Ilhós e parafuso | `st1` / `st2` / `st3` | #5a6676 / #7f8c9a / #a9b4bf |
| Corda | `br3` / `br2` / `br1` | #c98a4b / #9a5f36 / #6b3f2a |
| Texto sobre a lona | `ink` / letreiro `b1` | #14101a / #2f4a78 |
| Tokens sobre a lona (passo escuro da mesma rampa) | Treino `gr1`, Dinheiro `br1`, Fama `f0`, Legado `p0` | #2f6b4a, #6b3f2a, #7a2a52, #4a2f6b |

**Leitura em 640x360:** é a mais legível. `ink` sobre creme dá 11,9:1, e o texto branco sobre a placa `b1` dá 7,5:1. Os tokens sobre a
lona ficam entre 4,0:1 (o Treino `gr1`, que é 2x) e 7,0:1. O HUD claro é a coisa mais clara da tela e puxa o olho para cima.
Isso ajuda o número-herói, mas compete um pouco com a sala, e por isso a lona tem a trama baixa e a bainha fina. Cuidado com a fita
vermelha com texto branco em 1x: dá 3,7:1, então leva a sombra `r0` de 1 px (como no mockup) ou usa a base `r1`.

**Custo: médio.** Precisa de 4 NinePatch opacos e dentro da paleta: lona com bainha, placa com parafusos nos cantos, fita de ponta
rasgada e letreiro. O ilhós do meio de uma lona larga é um nó a mais, e as cordas são decoração só nas janelas e no menu. O
`ui_tema` ganha um **2º jogo de cores de token "sobre claro"** (gr1, br1, f0, p0). O trabalho está nisso e em revisar onde os tokens
aparecem sobre a lona.

## C) Cartaz de luta

O HUD é uma tira de **asfalto** com **faixas diagonais** vermelha e creme entre os grupos, e o nome do local vai numa etiqueta de papel
com o canto cortado. A barra de baixo é **papel de cartaz** creme, com borda grossa `ink`. Uma **faixa diagonal vermelha** passa atrás
do LUTAR, que vira uma chapa inclinada com letra de cartaz. Os botões têm **sombra dura** deslocada 2 px. Os carimbos são vermelhos
(PERIGOSO) e azuis (Raízes). Na janela, o título vem em letra de cartaz 3x sobre a faixa vermelha cortada em diagonal. No menu, o logo
é itálico e grosso, sobre uma faixa que atravessa a tela.

| Papel | Cor | Hex |
|---|---|---|
| Papel / envelhecido | `cream` / `g3` | #d9cdb4 / #b8b0aa |
| Asfalto (HUD, botão) | `d1` / `ink` | #2a2233 / #14101a |
| Faixa diagonal / sombra dura | `r2` / `ink` | #d4473a / #14101a |
| Carimbo da escola | `b1` / `b2` | #2f4a78 / #4d7bb3 |
| Carimbo de risco | `r2` | #d4473a |
| Texto: no papel / no asfalto | `ink` / `cream` | #14101a / #d9cdb4 |

**Leitura em 640x360:** o HUD escuro deixa a sala calma e os tokens com as cores de hoje (`gr3` sobre `d1` dá 9,2:1). Com o papel
claro embaixo, os focos ganham peso. A letra de cartaz em 2x e 3x funciona muito bem no menu, no LUTAR e nos títulos. Os pontos
fracos são três. O `r2` sobre creme dá 2,8:1, então o LUTAR precisa da sombra `ink` (como no mockup) e nunca pode ir em 1x. Cada
faixa diagonal gasta 3 a 4 px por separador. E o dither do papel precisa ficar ralo para não sujar o texto.

**Custo: médio a alto.** Os controles do Godot são retângulos. O papel, a sombra dura (`shadow_offset` do StyleBoxFlat) e o carimbo são
baratos. Já as diagonais (separadores do HUD, que mudam de lugar com a largura do texto, a chapa inclinada do LUTAR, o canto do título)
são texturas ou desenho próprio, posicionados por código. A barra clara também pede o jogo de tokens "sobre claro".

---

## Recomendação

**B (lona e placa) como a identidade do jogo, com o C guardado para os momentos de luta.**

- A B é a única em que a UI **pertence ao mundo**: a lona, a fita, a placa parafusada e o letreiro pintado são coisas que existem
  na garagem e na academia, e o azul da placa é o carimbo da Raízes. É isso que tira a "cara de IA". Também é a mais legível e
  fica inteira dentro da paleta, sem exceção.
- O **C** é o que mais impressiona, mas cansa se estiver em toda a tela. A sugestão é usá-lo onde o jogo já é "noite de luta": menu
  principal, prévia da luta, VITÓRIA/K.O. e cartaz do torneio. O menu C pode ser o menu da B sem custo extra de regra.
- O **A** é o que o dono imaginou ("vidro, estilo Apple") e é o mais barato. A minha ressalva é de identidade: vidro translúcido
  é a linguagem de interface mais comum de hoje, então troca um genérico por outro. Ele também quebra a paleta fechada. Se o dono
  preferir o A, recomendo manter as cores da história na tinta do vidro (como está no mockup), subir o alfa nas janelas e usar o
  vidro **só por cima da sala** (HUD, doca, dicas), com as telas de luta no C.

Se o dono quiser misturar, a combinação que dá certo é: **HUD e barra na B, janelas na B, menu e telas de luta no C, dicas (tooltip)
em vidro A**. Isso respeita o pedido de transparência num ponto pequeno, sem custo de legibilidade.

## O que é placeholder (precisa de artista humano)

O logo é a fonte 5x7 ampliada e tratada, e não um logotipo. A versão final pede letras desenhadas à mão (uma fonte de título
própria, 10 a 14 px de altura, com acentos). A trama da lona, o papel envelhecido e as pinceladas são dither por fórmula, e à mão
ganhariam textura de verdade. As cordas são retas, e os ilhoses e parafusos são de 5x5 e 2x2. O fundo da sala é uma captura antiga
com retoque. Os 9-slices finais serão desenhados com os mesmos tamanhos dos mockups (HUD 18 px, barra 30 px, botões 86x20 e 102x24).

---

## Menu C v2 (2026-11-25): composição no eixo, animação da faixa e 3 fundos

Resposta ao comentário do dono sobre `identidade_c_menu_x2.png` ("ficou meio torto", "animação nessa parada vermelha", "fundo mais
bem pensado"). Gerador: `tools/art/make_mockup_identidade_c2.gd` (headless, de uma pasta com `project.godot` vazio, `-- --root <worktree>`).
Imagens em `mockups/identidade/`: `identidade_c_menu_v2_{garagem,arena,cartazes}_x2.png`, prancha `identidade_c_menu_v2_comparativo.png`
(com o v1 ao lado, para comparar) e a animação em `mockups/identidade/menu_c_anim/`.

### Composição (o "torto")
O v1 tinha três eixos brigando: a faixa caía em diagonal, o logo era itálico com sombra para a direita e o lutador estava solto
à esquerda. No v2, tudo fica num **eixo só, x = 320**:
- **Faixa vermelha horizontal** de ponta a ponta (y 26..113: filete creme 3 + ink 1, corpo `r2` y 30..105, ink 2 + creme 3 + ink 1,
  1 px de sombra em dither). A inclinação continua, mas **só por dentro**: listras diagonais `r1` em meio-tom e o itálico do logo.
- **Logo** (FIGHTCLICKER 5x, bold, itálico 1/4) centrado pela **caixa real dos pixels** (o itálico empurra a caixa; o gerador
  centraliza o que se vê): x 149..491, centro 320,0. Sombra dura **reta para baixo** (0,4), contorno `ink`, luz `white` na 1ª linha.
- **Subtítulo** numa etiqueta `ink` em cima do filete de baixo, no eixo.
- **Botões** numa coluna de 152x22, passo 28, a partir de y 164, x 244..395. Sombra dura **reta para baixo** (0,3): nada puxa para
  o lado. O foco (CONTINUAR) é `r1` com texto creme e 1 px de sombra `ink` (creme sobre `r1` = 4,8:1; o branco sobre `r2` de 3,7:1
  não é usado). Os outros são creme com texto `ink` (11,9:1) e sombra `r1`. Duas setas creme espelhadas marcam o foco.
- **A cena tem peso igual dos dois lados**: o que fica à esquerda é espelhado à direita (lutador e saco x treinador; lutador x
  adversário; cartazes x cartazes), com um refletor em cada lado.
- **Medido pelo gerador** (imprime no console): margens esq/dir do texto de cada botão 50/51, 58/59, 65/66 (o 1 px vem de largura
  ímpar em botão par, e a regra aceita); cima/baixo 7/8 (letra de 7 px em botão de 22); subtítulo 7/7 e 3/3; logo no eixo; nenhum
  sprite da cena sai da tela ou entra na coluna dos botões. **0 problemas nos 3 fundos.**

### Os 3 fundos (todos com cenários e sprites reais do jogo)
1. **Garagem à noite** (`garage_bg`): o saco `bag_l1` na corrente e o lutador (`fighter_punch`) batendo, à esquerda; o
   treinador (`coach_idle`, espelhado) de braços cruzados olhando, à direita. Dois cones de luz quente. É o começo da história.
2. **Ginásio Alvorada** (`arena_league_bg`): o lutador e o adversário da liga (`opp_gym_2`) frente a frente no tatame, cada um
   no seu refletor. A faixa GINÁSIO ALVORADA da arena fica acesa logo abaixo do subtítulo e lê como o "local" do cartaz.
3. **Parede de cartazes** (a parede da garagem de perto, montada em 320x180 e ampliada 2x): cartaz SOCO, LIGA DO VALE, recorte
   do jornal do vulto, capuz no prego, quadros da Raízes e, no eixo embaixo dos botões, as luvas velhas do mentor.

**Recomendo a 2 (Ginásio Alvorada).** É a única em que o fundo também é um **cartaz de luta**: dois lutadores frente a frente,
título em cima e o nome do lugar embaixo, que é a composição clássica de cartaz e fecha com a direção C. Ela é simétrica por
natureza, então o menu fica firme sem esforço, e não estraga surpresas (o Ginásio Alvorada é a 1ª arena de liga).
A **1 (garagem)** é a mais afetiva e boa como alternativa, ou como fundo de "Novo jogo". A **3 (cartazes)** é a mais bonita
como ideia, mas mostra o capuz, o recorte do vulto, o rival JAMES e a Raízes: entrega a história logo no menu. Ela também mistura
pixel 2x no fundo com a UI em 1x. Pode servir de menu de "fim de jogo" ou de "jogo zerado", com a parede enchendo conforme o progresso.
Para o menu ficar vivo, os lutadores do fundo rodam o idle deles (6 fps, do manifest), e na garagem o saco balança com o soco.

### Animação da faixa (`menu_c_anim/`)
Prancha com 8 quadros-chave: `menu_c_anim_prancha.png`. Prévia: `menu_c_anim_preview_x2.gif` (intro + 1 volta do loop) e
`menu_c_anim_loop_x2.gif` (só o loop). Quadros 1x em `seq/f000..f061.png`. Tempos quadro a quadro em `tempos.txt` (o comando do
ffmpeg que monta o GIF está no fim dele).

**INTRO, toca 1 vez ao abrir o menu (860 ms):**
| ms | dura | o quê |
|---|---|---|
| 0 | 120 | cena escura (ink 75%), sem UI |
| 120 | 50+50 | a faixa entra da esquerda com a ponta cortada em diagonal e um fio de luz na borda (30%, 65%) |
| 220 | 60 | faixa completa |
| 280 | 50 | o título cai 16 px, com linhas de velocidade `r3` em cima |
| 330 | 60 | **IMPACTO**: o título "bate", com 1 quadro de flash branco (contorno e miolo), tudo desce 3 px e saem lascas creme dos lados |
| 390 | 50+50 | tremor (-2,+1) e depois (+1,-1) |
| 490 | 90 | repouso, e o subtítulo aparece |
| 580 | 4x40 | os botões entram um a um, subindo 6 px |
| 740 | 120 | pronto (versão aparece) |

**LOOP, enquanto o menu estiver aberto (3840 ms = 48 quadros de 80 ms):**
- As listras diagonais da faixa **correm para a direita 1 px a cada 80 ms** (período de 16 px, 1280 ms por volta, 3 voltas no loop).
- Um **brilho** passa pelo logo nos quadros 0..7 (640 ms): faixa diagonal com frente `y2`, miolo `white` e rastro `y1`, só dentro das letras. Depois, 3,2 s de pausa.
- As setas do foco balançam 1 px para dentro a cada 320 ms.
- Respeitar a opção de reduzir movimento, se existir: sem tremor e sem brilho, e as listras paradas.

**Para o programador (sugestão; a cena é do UI/UX):** a faixa é uma textura de 640x88 com a região das listras em `TextureRect`
com `UV offset` ou com um shader de scroll inteiro (1 px por passo, sem subpixel). O logo é um sprite separado (flash = 2º quadro).
A intro é um `AnimationPlayer` com as posições inteiras da tabela acima, e o tremor é um offset no nó pai da faixa e do logo.

### O que é placeholder
O logo ainda é a fonte 5x7 ampliada: a versão final pede um logotipo desenhado à mão (letra de cartaz própria, com acentos).
As listras são dither por fórmula, a luz dos refletores mistura alfa (sai da paleta: na versão final, uma textura de luz em degraus
dentro da paleta) e os cartazes genéricos da opção 3 não têm texto. A animação é a proposta de tempos; quem desenha os quadros
finais da faixa entrando (com a ponta rasgada) é um pixel artist.
