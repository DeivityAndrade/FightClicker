# Direção visual — Fightclicker

Dono: Diretor de Arte. Versão 1 (2026-11-05). Base: `PROMPT.md`, `docs/visao.md` (decisões do dono de 2026-11-05).
Mockups desta versão: `docs/arte/mockups/garagem_*.png` e `academia_*.png`, gerados por `tools/art/*.gd`.

> Gênero e linha visual: pixel art arcade de gestão de treino. Punch Club é referência **de gênero**.
> Arte, paleta, personagens, layout e locais são **100% nossos**. Nada copiado nem "redesenhado por cima".

---

## 1. Resolução e escala

| Item | Decisão |
|---|---|
| **Resolução base** | **640 x 360** |
| Janela padrão | 1280 x 720 (escala **2x**) |
| 1920 x 1080 | escala **3x** (inteira, sem borda) |
| 2560 x 1440 / 4K | 4x / 6x |
| Filtro | **Nearest** em tudo (`rendering/textures/canvas_textures/default_texture_filter = Nearest`) |
| Stretch | `display/window/stretch/mode = viewport`, `aspect = keep`, `scale_mode = integer` |
| Snap | `rendering/2d/snap/snap_2d_transforms_to_pixel = true` e `snap_2d_vertices_to_pixel = true` |

**Por que 640x360 e não 320x180:** um incremental vive de números, nomes de geradores e preços.
Em 320x180 cabem uns 50 caracteres por linha e a sala ficaria com uns 150 px de largura: o painel
espremeria a cena ou os textos. Em 640x360 cabem a sala, dois painéis laterais e uma barra de
botões, com fonte 5x7 legível, e o resultado continua "pixelado arcade" porque tudo é desenhado
na grade de 640x360 e ampliado por inteiro. O que dá o ar arcade é a **grade de pixel visível**, a
paleta curta e o contorno escuro, não a resolução mínima.

Regra de ouro: **nada fora da grade**. Sem rotação livre de sprites, sem escala não-inteira, sem
anti-aliasing. Animação = troca de quadros ou deslocamento em pixel inteiro.

## 2. Layout da tela principal (640x360)

```
y 0  ┌──────────────── HUD: $ dinheiro | ⚡ treino +x/s | ★ fama | nome do local ───────────────┐
y 18 ├─ PAINEL ESQ ──┬───────────────── SALA DE TREINO (384x272) ─────────────────┬─ PAINEL DIR ─┤
     │ 0..127        │ 128..511                                                    │ 512..639     │
     │ atributos     │ parede do fundo + chão em leve perspectiva                  │ EQUIPE/ITENS │
     │ legado em jogo│ centro (x=320): lutador + aparelho em foco = ALVO DO CLIQUE │ geradores    │
     │ próxima luta  │ outros aparelhos e gente treinando em volta                 │ melhorias    │
     │ (prévia ELE x │                                                             │ próximo local│
     │  VOCÊ, risco) │                                                             │              │
y 290├───────────────┴─────────────────────────────────────────────────────────────┴──────────────┤
     │ por clique / auto  │  [FOCO 1] [FOCO 2] [FOCO 3] ([FOCO 4 = arte])  │  [ LUTAR! ] [APOSENTAR]│
y 360└──────────────────────────────────────────────────────────────────────────────────────────┘
```

- **O alvo central fica sempre no mesmo ponto da tela** (aparelho em foco em x≈336, y≈190–250;
  lutador ao lado). Trocar o foco troca o aparelho que está no centro, não o lugar do clique (visão).
- Os painéis **nunca** cobrem a sala. Popups (prévia de luta, fim de carreira, mudança de local)
  abrem como janela central por cima, escurecendo a sala com dither 50% de `ink`.
- Números flutuantes saem do ponto clicado e sobem ~24 px em 0,6 s. Normal: `y1` com contorno
  `ink`, fonte 1x. Crítico/bônus: `r3`, fonte **2x**, com "!".
- Cursor do mouse = **a luva equipada** (sprite 10x10 com contorno claro), a mesma que aparece nas
  mãos do lutador.
- Botões: chanfro de 1 px (claro em cima, escuro embaixo), contorno `ink`, sombra de 1 px. Botão
  selecionado/ativo tem a cor do atributo e um sublinhado. Preço que não dá para pagar fica `r2`.
- Cores fixas de atributo em toda a UI: **Força = vermelho (`r1/r2/r3`)**, **Agilidade = azul
  (`b1/b2/b3`)**, **Resistência = amarelo (`y0/y1`)**, **arte marcial = roxo (`p1/p2`)**,
  treino/renda = verde (`gr2/gr3`), dinheiro = amarelo-ouro (`y1`), Legado = roxo (`p2`).
  **Fase 5.1:** tokens de cor e de tamanho no §18 (Fama vira rosa `f2`, Resistência fica só em `y0`, preço sem saldo deixa de ser `r2`).

## 3. Paleta (45 cores, fechada)

Toda cor do jogo sai desta tabela. Sombra e luz **andam na rampa** (nunca escurecer com
multiplicação livre). A UI usa a mesma paleta. Fonte da verdade em código: `tools/art/pixel_lib.gd`
(`PAL_HEX` e `RAMPS`).

| Rampa | Cores (escuro → claro) | Uso |
|---|---|---|
| Neutro | `ink #14101a` · `d1 #2a2233` · `d2 #3d3346` · `g0 #4a4552` · `g1 #6b6570` · `g2 #8f8890` · `g3 #b8b0aa` · `cream #d9cdb4` · `white #f2ece0` | contorno, painéis, concreto, texto |
| Madeira/couro | `br0 #3b2622` · `br1 #6b3f2a` · `br2 #9a5f36` · `br3 #c98a4b` → `y0` `y1` `y2` | viga, prateleira, madeira, ferrugem |
| Luz quente | `y0 #e0a040` · `y1 #f5d26b` · `y2 #fff3c4` | lâmpada, dinheiro, número do clique |
| Vermelho | `r0 #5a1a22` · `r1 #9c2a2a` · `r2 #d4473a` · `r3 #f07a5a` | luva, saco, Força, crítico, perigo |
| Pele | `sk0 #7a4632` · `sk1 #b9744f` · `sk2 #e3a275` | personagens (mais tons de pele entram como rampas extras) |
| Azul | `b0 #1f2a44` · `b1 #2f4a78` · `b2 #4d7bb3` · `b3 #8fbbe0` | calção, ringue, céu, Agilidade |
| Verde | `gr0 #1f3d33` · `gr1 #2f6b4a` · `gr2 #5aa25a` · `gr3 #a6d86a` | barrado da academia, treino/s, "fácil" |
| Aço | `st0 #3a4452` · `st1 #5a6676` · `st2 #7f8c9a` · `st3 #a9b4bf` | porta de garagem, esteira, metal |
| Roxo | `p0 #4a2f6b` · `p1 #7a4fa0` · `p2 #b07ad8` | Legado, arte marcial, (locais absurdos) |
| Rosa (só UI, Fase 5.1) | `f0 #7a2a52` · `f1 #d4558f` · `f2 #f59ac0` | Fama. Não usar em cenário nem em personagem (§18) |

- Fundo de tela e contorno: sempre `ink` (preto arroxeado, nunca #000).
- Locais 5 e 6 (templo, dojo fora da realidade) podem ganhar **uma** rampa nova cada (ex.: dourado
  de templo, ciano "irreal"). Fora isso, a paleta não cresce.

## 4. Perspectiva da sala

**Vista frontal de "caixa de diorama"**: parede do fundo reta e de frente, duas paredes laterais
estreitas em perspectiva e chão em trapézio. **Sem teto visível** (uma viga atravessa o alto da
parede e segura saco, lâmpada e corda). É a leitura mais clara para clicar e a mais barata de
animar: sprites são desenhados de frente / 3/4, sem precisar de versões isométricas.

Geometria fixa (em pixels da base), igual em todos os locais:

| Elemento | Valor |
|---|---|
| Área da sala | x 128..511, y 18..289 (384x272) |
| Ponto de fuga | (320, −28) |
| Parede do fundo | x 170..470, do topo até y 220 (escala 0,78 da moldura) |
| Chão | trapézio de y 220 (x 170..470) a y 289 (x 128..511), ~70 px de profundidade |
| Linha de piso a y | largura = 384·(y+28)/317, centrada em x 320 |
| Viga | y 24..31 |
| "Pés" de quem está no centro | y ≈ 272 |

Profundidade por **ordem de desenho** (quem tem os pés mais embaixo desenha por cima), não por
escala: todo personagem tem o mesmo tamanho em qualquer ponto do chão. Sombra no chão: elipse
achatada (`ink` ou um tom abaixo do piso) com dither nas bordas.

## 5. Regras de desenho

- **Contorno de 1 px `ink`** em todo objeto. **Personagens (revisado em 2026-11-05):** contorno só na
  **silhueta externa**; entre partes do mesmo corpo use sombra de contato, nunca contorno por parte
  (isso deixava riscos pretos no ombro, quadril e joelho). Vale a skill `padrao-personagem`
  (`.claude/skills/padrao-personagem/`), que prevalece sobre esta seção para gente.
- **2 a 3 tons por material** + 1 brilho pontual: base, sombra (rampa −1), luz (rampa +1).
- Luz principal de cada local definida (garagem: lâmpada no alto, ao centro; academia: tubos frios).
  Sombra do lado oposto à luz; a cena recebe um passo de luz em faixas com **dither ordenado 4x4
  (Bayer)** só nas bordas das faixas. A UI nunca recebe luz.
- Dither: só para luz, sombra no chão, umidade, tecido/lona. Nunca em texto.
- Nada de gradiente suave nem cor fora da paleta.

## 6. Tamanhos padrão

| Coisa | Tamanho (px da base) | Observação |
|---|---|---|
| Lutador / pessoas | **~64 de altura**, quadro **44x72** | pés na linha 67 do quadro; ~5,5 cabeças |
| Luva equipada | 10x11 na mão, 10x10 no cursor | mesma arte, mesmo item |
| Aparelho central (saco) | **30x62** + corrente | alvo de clique; área clicável sugerida 48x90 |
| Saco longo (Muay Thai) | 22x112 | |
| Esteira | 86x42 (vista de lado) | |
| Corda de pular | ~16x40 pendurada; ~44x64 em uso (quadros do lutador) | |
| Aparelho de arte no chão (boneco, tatame) | até 64x40 | |
| Ícones de UI | 9x9 (HUD), 16x16 (loja) | |
| Grade de piso/parede | blocos 20x10 (garagem), placas no chão em 10 colunas | |

Um sprite por arquivo PNG, cada um com o quadro do tamanho padrão e o ponto de apoio (pés / gancho)
na mesma coordenada, para trocar a arte depois sem mexer em cena.

## 7. Fonte pixel

- **Padrão do projeto: fonte bitmap própria 5x7** (maiúsculas, números, pontuação e acentos do
  português: Ç Ã Á Â É Ê Í Ó Ô Õ Ú). Já existe desenhada em `tools/art/pixel_lib.gd` (`GLYPHS`) e é
  a dos mockups. É 100% nossa, sem licença para checar, e encaixa na grade de 640x360. **Fase 2:**
  exportada como BMFont (`assets/sprites/font/fightclicker_5x7.fnt` + `_contorno.fnt`), com minúsculas; Godot carrega direto (`font_size = 11`; 22 = 2x).
- **Alternativas livres (SIL OFL 1.1), sem baixar agora:**
  - *Press Start 2P* (CodeMan38) — 8x8, bem arcade, para títulos e números grandes ("LUTAR!", "K.O.").
    Conferir se tem todos os acentos do português antes de adotar.
  - *Silkscreen* (Jason Kottke) — pequena e limpa para rótulos.
  - *Pixelify Sans* — tem acentos e minúsculas, boa para textos longos (diálogos do mentor).
- Tamanhos: texto 1x (7 px de altura), destaque 2x (14 px). Sempre com sombra de 1 px `ink` ou
  contorno `ink` quando estiver sobre a cena.

## 8. Evolução dos locais

A sala é **sempre a mesma caixa** (mesma geometria, mesmo ponto do alvo central). O que muda é o
"material" da caixa, a luz, os aparelhos e quantas pessoas treinam. Isso deixa cada local barato
(um conjunto de peças trocáveis) e a mudança muito visível.

| # | Local | Paredes | Chão | Luz | Aparelhos (versão) | Gente / detalhes |
|---|---|---|---|---|---|---|
| 1 | **Fundo de garagem** | blocos de concreto cinza, umidade na base, viga de madeira | concreto manchado de óleo, juntas | **uma lâmpada pendurada**, quente e fraca, cantos escuros; luz do dia vazando sob a porta | saco remendado com fita, corda de varal, esteira enferrujada | carro coberto com lona, prateleira de latas, pôster rasgado, **foto do mentor anterior** |
| 2 | **Academia de bairro** | pintura creme + barrado verde, tinta descascada, rachadura | placas de borracha | **tubos fluorescentes** frios, luz uniforme; janela alta com grade | saco de couro, corda com cabos, esteira que funciona, **aparelho da arte** | ringue pequeno, espelho, relógio, pôsteres desbotados, banco; treinador e parceiros |
| 3 | **Centro de treinamento** | galpão: chapa metálica, faixas de patrocinador | tatame/emborrachado com faixas pintadas | refletores industriais, mais claro | aparelhos de marca, pera e saco duplos | logos, alunos em fila, quadro de horários |
| 4 | **Complexo de elite** | painéis escuros com LED, vidro | piso polido com reflexo (dither) | holofotes de palco, contraluz colorido | aparelhos "high-tech" caricatos | equipe enorme, câmeras, troféus |
| 5 | **Templo na montanha** | madeira e pedra, portas de correr, montanha ao fundo | tábuas antigas | luz de lanternas e pôr do sol | saco de couro antigo amarrado em corda, tronco de madeira | monges, **um urso parceiro de treino** |
| 6 | **Dojo no fim da realidade** | sala flutuando no vazio, paredes rachando em pixels | tatame que se desfaz nas bordas | luz sem fonte, roxo/ciano | aparelhos absurdos (meteoro acorrentado, corda que deixa rastro, esteira que gira o chão) | estrelas, fragmentos flutuando |

Entre mudanças, dentro do mesmo local, a sala evolui aos poucos: cada upgrade de aparelho troca o
sprite (saco remendado → saco novo → saco de couro), e cada gerador comprado coloca mais gente em
pontos fixos da sala (até um limite de desenho; o número continua subindo).

## 9. Aparelhos por arte e por atributo

Segue a tabela do Diretor de Jogo em `docs/visao.md`. Básicos (todo local) e um aparelho por arte:

| Aparelho | Atributo / arte | Garagem | Academia de bairro | Centro de treinamento | Fim absurdo |
|---|---|---|---|---|---|
| Saco de pancada | Força | saco remendado com fita, corrente | saco de couro com faixa | saco de marca + mola | meteoro acorrentado |
| Corda de pular | Agilidade | corda de varal num prego, marcas de giz | corda com cabos, num gancho | corda de aço com rolamento | corda que deixa rastro de luz |
| Esteira | Resistência | esteira enferrujada, visor apagado | esteira branca, visor verde aceso | esteira de alto rendimento | esteira que gira o chão |
| Pera (saco de velocidade) | **Boxe** | — (arte só a partir da academia) | plataforma de madeira com pera vermelha | pera dupla, plataforma metálica | — |
| Saco longo | **Muay Thai** | — | saco longo preto com faixas vermelhas | saco longo + aparador de chute | — |
| Boneco de grappling no tatame | **Jiu-jitsu** | — | boneco de lona num tatame azul | tatame grande, boneco de couro | — |
| Boneco de arremesso | **Judô/Wrestling** | — | boneco de lona de pé, com pegada | boneco de couro + colchão de queda | — |

Estilo por arte (para os aparelhos e detalhes da sala quando a arte é escolhida):
- **Boxe:** vermelho e madeira, couro, cordas de ringue. Formas redondas.
- **Muay Thai:** preto com faixas vermelhas/douradas, bandagens, formas longas e verticais.
- **Jiu-jitsu:** azul de tatame e lona branca, formas baixas, no chão.
- **Judô/Wrestling:** branco/cru e azul-escuro, lona grossa, formas largas e pesadas.

## 10. Animações mínimas

Toda animação em quadros de pixel inteiro, 8–12 fps (a UI pode ser mais rápida). O lutador é
articulado em partes separadas (cabeça, tronco, braços, pernas, luvas), como já está nos mockups.

| Aparelho / ação | Repouso | No clique / em uso | Quadros |
|---|---|---|---|
| Saco de pancada | balanço leve (±1 px, 1,5 s) | empurra 3–4 px para longe do golpe, volta em 3 quadros com 1 px de sobra; corrente acompanha | 4 |
| Corda de pular | parada no prego | lutador pula: corda faz arco em cima → frente → embaixo (pés sobem 3 px) | 4 |
| Esteira | parada | faixas da lona correm 2 px por quadro, rolos giram, visor pisca | 2–4 (loop) |
| Pera | parada | vai e volta rápido (3 posições) | 3 |
| Saco longo | parado | balanço lateral maior, mais lento que o saco | 4 |
| Boneco de grappling | deitado | lutador por cima, boneco amassa 2 px | 3 |
| Boneco de arremesso | de pé | inclina e volta (sem rotação livre: quadros desenhados) | 4 |
| Lutador parado | respiração (tronco/cabeça ±1 px) | — | 2 |
| Lutador golpe | — | antecipação → golpe (braço da frente estica) → volta | 3 |
| Lâmpada (garagem) | pisca 1 quadro a cada ~8 s; balança quando o saco é atingido forte | — | 2 |
| Tubos (academia) | um tubo falha de vez em quando | — | 2 |
| Número do clique | sobe e some (troca para tom mais escuro no fim) | crítico: escala 2x e tremida de 1 px | — |
| Impacto | 3 a 5 traços brancos no ponto do golpe, 2 quadros | tela treme 1–2 px (só pixel inteiro) | 2 |

## 11. O que é placeholder e o que precisa de artista humano

- **Tudo nos mockups é placeholder gerado por código** (formas, retângulos, elipses e luz
  calculada). Serve para fixar resolução, paleta, layout, tamanhos e clima. Não é a arte final.
- **Precisa de pixel artist humano para a versão final:** o lutador e as pessoas (anatomia, rosto,
  silhueta com personalidade, poses de cada golpe/esquiva/queda/vitória), as animações quadro a
  quadro, os aparelhos com material convincente (couro, lona, metal), o cenário de cada local com
  detalhe narrativo, o rival e o mentor, e os locais 3–6.
- O que pode ficar do código: paleta, grade de layout, a fonte 5x7 (com revisão), molduras de
  painel/botão, sombras, luz em faixas e a montagem da sala por peças.
- Poses atuais: todos usam a mesma guarda de boxe (inclusive quem corre na esteira e o treinador).
  É limitação do placeholder.

## 12. Como gerar os mockups de novo

Os scripts ficam em `tools/art/` (`pixel_lib.gd` + `make_mockup_garage.gd` + `make_mockup_academia.gd`).
Rodar a partir de uma pasta com um `project.godot` vazio (para não disparar import no projeto):

```
godot --headless --path <pasta_temporaria_com_project.godot> --quit-after 5 --script E:/Fightclicker/tools/art/make_mockup_garage.gd
godot --headless --path <pasta_temporaria_com_project.godot> --quit-after 5 --script E:/Fightclicker/tools/art/make_mockup_academia.gd
```

(`--quit-after` garante que o Godot fecha mesmo se o script der erro.) Saída: `*_base.png`
(640x360) e `*_x2.png` (1280x720, nearest) em `docs/arte/mockups/`.

## 13. Sprites da Fase 2 (garagem)

- Gerador: `tools/art/make_sprites_fase2.gd` (usa `pixel_lib.gd`, que agora tem minúsculas e o
  personagem articulado por poses `character()`). Teste da fonte: `tools/art/test_font.gd`.
- Saída: `assets/sprites/{garage,equipment,characters,fx,ui,font}/`, 1x, uma folha por animação
  (quadros lado a lado). `assets/sprites/manifest.json` traz quadro, nº de quadros, fps, pivô,
  posição na sala, 9-slice e a ponte com os ids de `data/` (`by_data_id`).
- Regra de foco: o aparelho em foco vai para o centro (saco em x 336); o saco descansa à esquerda
  (x 258), a esteira à direita (x 445), a corda no prego (352,72).
- Pessoas: pontos fixos com a luz da lâmpada já aplicada (vizinho 1/2/3, tio 1/2).
- Lutador: quadro 48x72 (a guia antiga dizia 44x72; ficou 48 para caber o soco esticado), pés na linha 67.
- Conferência: `docs/arte/mockups/fase2_sala_x2.png` (sala montada só com os sprites e as
  posições do manifest) e `fase2_sprites_x3.png` (folha de contato).

## 14. Fase 3 (lutas, fim de carreira)

Gerador: `tools/art/make_sprites_fase3.gd` (rodar como no §12; **acrescenta** ao `manifest.json`, não apaga a Fase 2).
Se rodar o `make_sprites_fase2.gd` de novo, ele reescreve o manifest só com a Fase 2: rode o da Fase 3 logo depois.
A fonte 5x7 ganhou `º` e `ª` ("2º ROUND").

**Arena (única):** estacionamento de uma borracharia à noite. Galpão de chapa ondulada, placa pintada à mão,
porta de enrolar "07", pneus e tambores, carro com farol aceso, alambrado e poste de sódio. Luz vem de um
refletor de obra pendurado num cabo em cima do "ringue" riscado a giz no asfalto; cantos quase pretos.
Público em silhueta (`arena_crowd_back` atrás, `arena_crowd_front` nos cantos de baixo), 2 quadros (parado / vibrando).
Faixa y 0..45 é céu escuro: o HUD de luta fica ali (`fight_layout` no manifest).

**Vista de luta:** de lado. Jogador à esquerda virado para a direita (pivô 296,318), adversário à direita virado
para a esquerda (346,318). Quadro **112x104 para todos**, pivô (56,98) nos pés. Mesmo rig articulado da garagem
(perna de trás, braço de trás, tronco, perna da frente, cabeça, luva de trás, braço da frente + luva), cada parte
com contorno ink próprio; tamanho do corpo por escala (Dinho 0,92 · Dudu 0,98 · jogador 1,0 · Brutão 1,08 · Muralha 1,12).
9 ações por lutador: idle, jab, heavy, hit, dodge, block, tired, victory, ko (3–5 quadros). O manifest traz
`hit_frame`, `hit_point` e a posição das duas mãos em cada quadro (`hands`), para casar efeito e número com a simulação.

**Adversários** (aparência do Roteirista, `docs/fases/fase3-textos.md`): cada um com silhueta e cor dominante própria
— Dudu Alongado (branco/verde-musgo, meião, faixa mole), Brutão do Posto (o mais largo, boné do posto, macacão azul,
luva com fita isolante vermelha), Dinho Pulga (baixo, moletom azul com capuz, bandana, tênis laranja, cadarço solto,
saltita), Seu Muralha (alto, barriga, bigode grisalho, camiseta amarela, cinturão de pano — o mesmo do ícone).

**Luvas:** velha (r0/r1/r2, fita e punho encardido), lona (bege, fita branca), couro (marrom-avermelhado, costura clara),
marca (preta, listra amarela torta). Cada luva tem: item 12x13, ícone 16x16 da loja, cursor (+ x2/x3), folhas da
garagem e da luta já pintadas (sufixo `_glove_lN`) e a arte "luvas penduradas". Regra: trocar a luva troca tudo pelo
mesmo sufixo (`by_data_id.glove_lN.sprite_suffix`). Conferência: `mockups/fase3_luvas_x3.png`.

**Cores de UI novas:** tática agressivo = vermelho (Força), defensivo = amarelo (Resistência), contra-ataque = azul
(Agilidade), usando os botões de foco já existentes como "selecionado". Risco fácil/equilibrado/perigoso = verde/amarelo/
vermelho, sempre com ícone (✓, =, caveira) além da cor. Dinheiro `y1` ($), fama `p2` (estrela), Legado `p2` (chama roxa
— a chama que passa de um lutador para o próximo). LUTAR! é vermelho (arriscar); APOSENTAR é roxo (Legado).
Fim de carreira: moldura de concreto com fita vermelha; aposentadoria: moldura roxa com cantos dourados.

**Mockups:** `fase3_luta_x2.png` (luta montada + tira de quadros-chave), `fase3_previa_x2.png` (ELE x VOCÊ sobre a
garagem escurecida), `fase3_fim_x2.png` (derrota e aposentadoria), `fase3_sprites_x3.png` (folha de contato).

**Placeholder:** tudo gerado por código. Para a versão final precisa de pixel artist: rostos e expressões (hoje são
2–3 pixels), anatomia e peso de cada adversário, poses de golpe com antecipação e follow-through de verdade (hoje os
golpes são interpolação de pontos), a queda (o quadro "caindo" é rígido), o público com gente desenhada, a arena com
mais história, e o cinturão. As luvas e a UI podem ficar com retoque.

## 15. Fase 4 (árvore de habilidades, Metrônomo, revanche)

Gerador: `tools/art/make_sprites_fase4.gd` (rodar como no §12; **acrescenta** ao `manifest.json`). Se rodar os da Fase 2/3 de novo,
rode o da Fase 4 depois. Nenhuma arte de personagem nesta fase (o auto-soco usa o rig e o jab que já existem).

**Ícones dos nós:** `skill_<id>` 16x16 em cor (cartão de início, resumo da garagem) e `skill_<id>_gray` (trancado). Na árvore, peça
24x24 por estado: `_owned` (moldura acesa na cor do ramo + ✓ verde), `_buyable` (borda verde viva, 2 quadros a 3 fps — verde = "dá
para comprar", como o preço da loja), `_missing` (ícone meio apagado + moeda roxa riscada; preço em r2/r3), `_locked` (cinza + cadeado).
Cor dos ramos: **Corpo = vermelho** (`r1/r2/r3`, efeito em r3), **Carreira = ouro** (`br2/y0/y1`, efeito em y1). Símbolos: jab = luva
com risco de velocidade; Memória muscular = metrônomo com faísca roxa; Mão pesada = punho descendo com estouro; Garagem animada/lotada =
2 / 3 bustos de camiseta verde (renda passiva); Bolsa = saco de dinheiro; Olho de treinador = olho + %; Empresário = maleta com notas;
Torcida = braços erguidos + estrela; Saber cair = chama do Legado pousada num colchonete.

**Tela da árvore:** janela `ui_tree_window` (quadro de madeira com pregos, 9-slice) + título `ui_window_title_retire` (roxo).
Duas colunas `ui_tree_column_body/career` com faixa de cabeçalho na cor do ramo. O "Y" logo abaixo do 1º nó são três peças
empilhadas no mesmo ponto (`ui_tree_fork_stem/left/right_normal|active`), e a ligação do 1º ao 2º nó de cada caminho é
`ui_tree_link_normal|active` (há ladrilhos `ui_tree_link_v/h_*` para outros tamanhos). Linha **ativa = roxo do Legado** com faísca
branca a cada 4 px; normal = cinza. Uma ligação acende quando o nó de baixo dela está comprado. Plaquinhas de preço/estado
`ui_tree_plate_buy/owned/missing/locked`. Geometria recomendada em `manifest.tree_layout` (janela 480x300 em 80,20). Nome longo em
"PEDE: {nome}" passa de 104 px: o UI/UX decide entre nome curto, 2 linhas ou "PEDE O DE CIMA".

**Metrônomo:** prop `garage/metronome_l1|l2|l3` (quadro 18x26, pivô 9,25 no pé), na prateleira da garagem em **(240,118)**, na
frente da caixa de papelão; nível 0 = sem prop. l1 = metrônomo velho de feira (madeira gasta, quina lascada, fita crepe, haste de
lata), l2 = madeira envernizada com peso de latão, l3 = laca preta com frisos dourados. 8 quadros = um vai-e-volta = 2 auto-socos;
quadros 0 e 4 são os extremos e têm o risquinho do "tic". fps = 4 / intervalo (2,0 / 4,0 / 5,7), ou sincronizar pelo acumulador
(fórmula em `by_data_id.metronome.sync`). Ícones da LOJA `icon_metronome_lN` (16x16, pontinhos = nível).

**Revanche:** marca = **esparadrapo em X** com pingo de mertiolate (`icon_revenge` 9x9, `icon_revenge_16`), sobre fita vermelha
9-slice `ui_seal_revenge` com o texto `revenge_mark` do ui_texts. `seal_revenge_mark` traz o texto padrão embutido (só usar se o
texto não mudar). Vitória: `ui_banner_revenge` ("REVANCHE!" 3x sobre estouro vermelho, 2 quadros) e `ui_banner_revenge_burst` (só o
estouro, para escrever o texto do ui_texts por cima).

**Cartão "o que você trouxe":** `ui_career_card` (roxo com cantos dourados, 9-slice), `ui_career_card_title`, `ui_career_card_row`
(ícone 16 + effect_text na cor do ramo). Resumo da garagem: `ui_legacy_nodes_badge`.

**Mockups:** `fase4_arvore_x2.png` (árvore com 3 nós comprados, 1 comprável, 3 faltando Legado e 3 trancados), `fase4_garagem_x2.png`
(garagem com Metrônomo, cartão de início, marca no bloco PRÓXIMA; prateleira ampliada nos 3 níveis, os 8 quadros do pêndulo e o
REVANCHE!), `fase4_sprites_x3.png` (folha de contato).

**Placeholder:** ícones e molduras podem ficar com retoque de um pixel artist (principalmente Mão pesada, Empresário e Saber cair, que
são os menos imediatos em 16 px). O Metrônomo precisa de artista para ter material de verdade (veio da madeira, metal da haste).

## 16. Fase 4b (aparelhos que chegam, modo assistido)

Gerador: `tools/art/make_sprites_fase4b.gd` (rodar como no §12; **acrescenta** ao `manifest.json`). Se rodar os das Fases 2/3/4 de novo,
rode o da 4b depois. Nenhuma arte de personagem.

**Aparelho que falta = fita crepe + plaquinha de papelão** (nunca caixa fechada). Fita = `cream` com borda `g3`, pontas rasgadas.
- Esteira: `garage/tape_mark_treadmill` (trapézio no chão em perspectiva, mesmo pivô e posição da `treadmill_lN_side`, 445,267) +
  `ghost_treadmill` (sombra pontilhada ink 50% com cadeado, opcional). Plaquinha em pé no fundo da marca (base em 445,257) com o
  `sign_brick` na frente.
- Corda: `garage/tape_mark_rope` na **parede**, em volta do prego (352,72), como quadro de ferramentas + `ghost_rope`. Plaquinha colada
  acima do prego, borda esquerda em x 340 (à direita da corrente do saco), com 2 `sign_tape_bit`.
- `sign_cardboard` é 9-slice; texto 1x em `br0`, sem sombra, centrado, 2 linhas (nome / preço). A fonte 5x7 não tem travessão.

**Trancado na UI:** `icon_<aparelho>_locked` (cadeado cinza) e `_locked_buyable` (dourado), 16x16, no cartão da aba TREINO (5,3) e no
botão de foco (2,9). Botão de foco trancado `ui_button_focus_locked_buyable|buyable_pulse|missing|locked` (9-slice 16x17, mesmas margens;
`_full` = 122x34 pronto). Verde = comprável, como no resto do jogo. Cartão de compra `ui_card_unlock` (borda de papelão) e `_flash` (piscada).

**Chegada:** a esteira cai (offsets y -20,-10,-3,0,1,0 a 24 fps) e no impacto some a marca, toca `fx_arrive_dust` (6 quadros, 12 fps)
e a tela treme 1 px. A corda é pendurada (-8,-3,0,1,0) com `fx_arrive_sparkle` (5 quadros, 12 fps). Detalhes em `manifest.by_data_id.unlock_*`.

**Modo assistido:** chip 9-slice `ui_assist_chip_hint|waiting|active|active_pulse|metronome` (altura 13; ícone 9x9 em 3,2, texto em 15,3) com
`icon_key_shift`, `icon_assist_wait`, `icon_assist_active`, `icon_metronome_9`. Botão `ui_button_hold_normal` (tecla de aço) e `_pressed`
(afunda 1 px, verde = assistindo). Sugestão: faixa de baixo da sala, centrada, abaixo dos pés do lutador (`manifest.by_data_id.assist`).

**Mockups:** `fase4b_garagem_x2.png` (começo de carreira + prancha dos estados) e `fase4b_sprites_x3.png` (folha de contato).
**Placeholder:** a fita, o papelão e a poeira podem ficar com retoque. Um pixel artist melhoraria a textura do papelão, a letra "à mão"
(hoje é a fonte 5x7) e a poeira (volume de verdade, não bolinhas pontilhadas).

## 17. Fase 5 (Academia Boa Esquina, Boxe e Jiu-jitsu)

Gerador: `tools/art/make_sprites_fase5.gd` (rodar como no §12; **acrescenta** ao `manifest.json` e relê o arquivo na hora de gravar,
para não apagar o que o Artista de Personagens gravou). Se rodar os das Fases 2/3/4/4b de novo, rode o da Fase 5 depois.
Nenhuma arte de personagem aqui (os 2 adversários da academia são do Artista de Personagens).

**A sala (`gym/gym_bg`, 384x272 em 128,18):** a mesma caixa da garagem, com os mesmos ganchos (336 e 258), o mesmo prego da corda (352,72),
o mesmo ponto do Metrônomo (240,118, na ponta da prateleira) e os mesmos pontos de gente. O degrau acima da garagem se lê por:
- **parede pintada** (creme em cima, barrado verde `gr1` embaixo, tinta descascando na borda, rachaduras) no lugar do bloco de concreto;
- **viga de aço** e **2 tubos frios** (`gym_tube` em 218,34 e 422,34; quadro 1 = tubo falhando) no lugar da lâmpada: luz uniforme,
  clara embaixo dos tubos, caindo só nos cantos e na frente do chão (`gym_step()` no gerador; a mesma luz vai nos sprites `_side/_wall/_rest_gym`);
- **nome pintado à mão** "ACADEMIA / BOA ESQUINA" acima do **espelho trincado** (estrela de trinca, um caco faltando e fita crepe em X);
- **pôsteres desbotados** (LUTA, SÁB), relógio, prateleira com troféu pequeno, quadro de cortiça da **mensalidade** (papel com carimbo vermelho),
  banco com toalha e mochila, relógio de round (3:00, 3 luzes), luvas penduradas, extintor, porta da rua com vidro aramado e plaquinha
  verde, janela alta com grade na parede lateral, halteres;
- **piso de borracha** em xadrez e **tatame azul gasto** no canto da frente à esquerda (com rasgo remendado).
O lugar acima da porta (x 410–462, y 44–98) fica livre de propósito: é onde a pera mora.

**Aparelhos básicos na academia:** sufixo `_gym` no nome do sprite (`bag_l1_idle` → `bag_l1_idle_gym`), mesmos quadros, pivôs, fps e pontos.
Sem `_gym` no manifest = usa o da garagem. Saco: couro marrom com tiras creme (l0) / preto com faixas vermelhas e emblema (l1).
Esteira: branca com visor verde aceso (l0) / faixa verde e chave vermelha (l1). Corda: PVC vermelho com cabos pretos (l0) / aço encapado com
cabos de madeira (l1); a `rope_lN_swing_gym` é a mesma animação recolorida.

**Pera veloz (Boxe):** silhueta oposta à do saco: **haste fina + tábua larga + gota pequena** (o saco é um cilindro gordo numa corrente).
- Foco: `speed_bag_lN_idle/hit` num pedestal em pé, pivô no chão em **(330,274)**, ordenar como y 268 (o lutador, em 303,272, fica na frente).
  A pera fica na altura do soco (y 215–226). O clique tem 5 quadros a 18 fps (vai para trás, bate, volta direita/esquerda, assenta).
- Descanso: `speed_bag_lN_wall(_gym)`, plataforma parafusada na parede acima da porta, pivô no meio de cima da tábua em **(436,46)**.
- l0 = pera remendada com fita, compensado, saco de areia no pé; l1 (Jab duplo) = couro com costura, tábua envernizada, anilha.
- Falta: `tape_mark_speed_bag` (quadro de fita na parede com o contorno a caneta) + `ghost_speed_bag`; plaquinha colada logo abaixo,
  centrada em x 432 a partir de y 102 (na garagem cai na porta de enrolar). Chegada: offsets -8,-3,0,1,0 + `fx_arrive_sparkle` + `speed_bag_l0_wall_swing`.

**Boneco de tatame (Jiu-jitsu):** formas baixas, azul de tatame e lona.
- Foco: `grappling_dummy_lN_idle/hit`, sentado de perfil olhando para o lutador, sobre um pedaço de tatame; pivô no chão em **(338,279)**,
  ordenar como y 266. Clique: amassa 2 px, tomba 2 px, volta (3 quadros, 12 fps). O lutador usa o `fighter_punch` (placeholder: sem pose de grappling nesta fase).
- Descanso: `grappling_dummy_lN_rest(_gym)`, deitado de costas no canto da frente à esquerda, pivô **(228,283)** (na academia, em cima do tatame gasto).
- l0 = lona crua com fita prata num tatame velho; l1 (Guarda fechada) = couro azul com alças e faixa preta, tatame novo.
- Falta: `tape_mark_grappling_dummy` no chão + `ghost_grappling_dummy`; plaquinha em pé no fundo da marca, base em (230,268) com o `sign_brick`.
  Chegada: offsets -18,-8,-2,0,1,0 + `fx_arrive_dust_small` + tremida de 1 px.

**UI da fase:**
- Artes: `art_boxing` (luva vermelha) e `art_bjj` (nó da faixa azul) em 16x16 e `_9`; ilustração do cartão `art_card_<arte>` (72x56).
  Cor de arte marcial continua roxa (botão de foco `ui_button_focus_art`, chip do HUD `ui_art_chip`), e cada arte tem sua cor de faixa:
  Boxe vermelho, Jiu-jitsu azul (`ui_art_card_header_<arte>`).
- Janela de arte: `ui_art_card` / `_hover` / `_last` (borda dourada) + selo `ui_art_tag_last` + botão `ui_button_art_*`. Layout sugerido em
  `manifest.by_data_id.art_window` (janela 420x268 em 110,34; 2 cartões de 190x220).
- Técnicas: `icon_tech_boxing_1|2`, `icon_tech_bjj_1|2` (16x16). Aparelhos: `icon_speed_bag`, `icon_grappling_dummy` + `_locked(_buyable)`.
- MUDAR: `icon_move` (caixa de papelão com fita), botão `ui_button_move_normal|hover|pressed|disabled` (verde = dá para pagar; apagado nunca some)
  e cartão `ui_move_card|_ready|_dim` para o bloco PRÓXIMA. HUD do local: `icon_location_gym` / `icon_location_garage`.
- Árvore: `ui_tree_column_style` (faixa roxa), `icon_branch_style`, abas `ui_tree_tab_normal|active` (se o UI/UX preferir abas), nós
  `skill_style_boxing` (luva + sininho) e `skill_style_bjj` (ampulheta sobre a faixa) com as 4 peças de estado da Fase 4.
- 4 botões de foco: cabem em 372 px com largura 90 e passo 94 (134, 228, 322, 416); "RESISTÊNCIA" não cabe em 90 px: usar "RESIST." ou 2 linhas
  (decisão do UI/UX, passa pela `alinhamento-ui`).

**Onde fica cada um na academia:** lutador, equipe (vizinhos, tios, Prof. Nelson), Metrônomo, corrente e corda nos **mesmos pontos da garagem**
(`manifest.by_data_id.gym`). A sala foi desenhada em volta deles. As pessoas têm a luz da lâmpada pintada: na academia ficam um pouco mais quentes.

**Mockups:** `fase5_academia_x2.png` (academia com Boxe, equipe completa e pera na parede + janela de arte da 1ª chegada),
`fase5_marcas_x2.png` (garagem de uma carreira de Boxe com a marca da pera e o cartão MUDAR; prancha com o boneco em marca/foco/descanso,
pera em foco, as 2 chegadas, MUDAR sem dinheiro, aba ESTILO e ícones), `fase5_sprites_x3.png` (folha de contato).

**Placeholder / precisa de pixel artist:** a sala da academia é o marco da fase e merece um artista: textura de tinta e reboco, o espelho
(reflexo de verdade), os pôsteres com ilustração, o banco e a porta com material. O boneco precisa de anatomia e volume de lona/couro
(hoje é feito de cápsulas), e o lutador precisa de uma pose de grappling por cima dele (Artista de Personagens). A pera pede o couro
brilhante e o borrão de movimento desenhados à mão. Os ícones de técnica (principalmente Guarda fechada e Esquiva e volta) são os menos
imediatos em 16 px. As pessoas deveriam ganhar uma versão com a luz fria da academia.

## 18. Fase 5.1 (garagem clara, caixa da escola, corda no gancho)

Gerador: `tools/art/make_sprites_fase51.gd` (rodar como no §12; **acrescenta** ao `manifest.json` e relê o arquivo na hora de gravar).
**Rodar por último**, depois dos geradores das Fases 2 a 5: ele retoca os dois fundos e corrige as posições da corda.
`-- --teste=<pasta>/` grava tudo numa pasta de teste, sem tocar no projeto. Nenhuma arte de personagem aqui.

### 18.1 Tokens de hierarquia (nomes iguais aos do `docs/fases/fase5.1-design.md` §3)
Cópia em dados: `manifest.json → ui_tokens`.

**Cores**
| Token | Paleta | Hex | Uso |
|---|---|---|---|
| `col_treino` | `gr3` | a6d86a | Treino, +/s, por clique, todo preço em Treino |
| `col_money` | `y1` | f5d26b | Dinheiro e todo preço em $ (sempre com `$` ou a moeda) |
| `col_fame` | `f2` | f59ac0 | Fama (ícone `icon_fame` já recolorido) |
| `col_legacy` | `p2` | b07ad8 | Legado em jogo e permanente |
| `col_text_1` | `white` | f2ece0 | texto principal (níveis 1 e 2) |
| `col_text_2` | `g2` | 8f8890 | rótulos, "cada", descrições, **preço sem saldo** |
| `col_disabled` | `g1` | 6b6570 | item trancado (1 linha) |
| `col_buyable` | `y2` | fff3c4 | contorno de 1 px do comprável mais barato (nunca texto) |
| `col_strength` / `col_agility` / `col_endurance` / `col_art` | `r2` / `b3` / `y0` / `p1` | — | atributos e arte marcial (já existiam) |

Decisões:
- **Treino continua verde e Dinheiro continua ouro** (o Designer sugeriu o contrário). O raio verde, o `+/s` verde e a moeda dourada já
  estão em todos os ícones e na árvore ("verde = dá para comprar com Treino"); trocar custaria refazer ícones sem ganho de leitura.
- **Fama sai do roxo e ganha uma rampa nova, só de UI: `f0 #7a2a52` · `f1 #d4558f` · `f2 #f59ac0`** (rosa de letreiro). Fama e Legado
  eram o mesmo `p2`, e o azul sugerido é a Agilidade. A paleta passa de 42 para **45 cores**; a rampa `f` não entra em cenário nem em personagem.
- **Resistência usa `y0` (âmbar), que já é a cor da barra dela; Dinheiro usa `y1` (ouro claro).** Hoje `ui_tema.cor_atributo("endurance")`
  devolve `Y1`, igual ao dinheiro: é a única linha de atributo que muda (1 passo na mesma rampa). É o par mais próximo da tabela; se o dono
  achar perto demais, o plano B é o Dinheiro em `y2`.
- **Legado (`p2`) e arte marcial (`p1`) seguem na mesma família roxa**, de propósito: os dois são "o que fica". A arte usa `p1` como
  **fundo** (botão, chip); o Legado usa `p2` como **texto**. Nunca escrever número de arte em `p2`.
- **Nenhum preço em vermelho.** Sem saldo = `col_text_2` e ícone da moeda em `g1`. Vermelho é só Força, risco e LUTAR.
- Comprável mais barato: cartão normal + contorno `col_buyable`; pode pulsar alternando com `y1` a 2 fps.

**Tamanhos (no máximo 3, uma fonte só)**
| Token | Fonte | Uso |
|---|---|---|
| `txt_hero` | 5x7 em **2x** (`font_size` 22, 14 px) | saldo de Treino, valor por clique, LUTAR! |
| `txt_title` | 5x7 em 1x, CAIXA ALTA, `col_text_1`, **filete `g0` de 1 px** embaixo | título de bloco |
| `txt_body` | 5x7 em 1x, maiúsculas e minúsculas | todo o resto |

O tamanho maior é a **mesma fonte em escala 2x**, não uma segunda fonte: continua na grade, já tem todos os acentos e o BMFont já carrega.
Uma fonte só de números em 10x14 desenhada à mão (cantos arredondados no 0, 6, 8, 9) deixaria o número-herói mais bonito: fica como pedido
para um pixel artist, não entra agora. Título e texto têm o mesmo tamanho: a diferença é caixa alta, cor e filete.

### 18.2 Corda no gancho
- **Gancho em (296,166)** nas duas salas (`layout.rope_hook`): altura do ombro de quem está encostado na parede; a corda vai de y 166 a 206.
  O desenho original punha o prego em (352,72), perto da viga; o PR do Matheus já tinha descido a posição no manifest para (296,155), mas os
  fundos não tinham gancho ali e ainda mostravam o prego antigo.
- `garage_bg` e `gym_bg` foram **retocados** (não regerados): some o prego antigo; entra um prego grosso e torto com 3 riscos de giz
  (garagem) e uma chapinha de aço com gancho no barrado (academia).
- `rope_lN_idle(_gym)` regeradas com a luz do ponto novo. `tape_mark_rope`, `ghost_rope`, `fx_arrive_sparkle` e `unlock_jump_rope` seguem o gancho.
- `rope_lN_swing`, `rope_lN_swing_back` e `fighter_rope` **não foram tocados** (são do `make_golpes_jogador.gd` / Artista de Personagens).
- Os geradores das Fases 2, 4b e 5 ainda têm o prego em (352,72): se rodarem de novo, rodar o da 5.1 depois.

### 18.3 Marcas sem texto
A plaquinha de papelão saiu da sala (`sign_cardboard`, `sign_brick`, `sign_tape_bit` ficam no projeto, sem uso). A marca diz sozinha
**onde** e **o quê**:
- **Fita** (`tape_mark_<aparelho>`): agora com sombra de 1 px, para ler também na parede creme da academia.
- **Silhueta riscada** (`ghost_<aparelho>`): contorno tracejado branco e ink + miolo pontilhado, sem cadeado. Lê em bloco cinza, chão
  escuro, barrado verde e parede clara. É ela que diz qual aparelho falta.
- Três estados, por sprite (nada de `modulate`):
  | Estado | Sprites | Quando |
  |---|---|---|
  | normal | `tape_mark_X` + `ghost_X` | dá para comprar |
  | aceso | `tape_mark_X_hi` + `ghost_X` | mouse em cima (a dica abre) ou pulso lento de "dá para comprar" |
  | trancado | `tape_mark_X_dim` + `ghost_X_dim` + `mark_padlock` | pede outro aparelho antes |
- Ponto do cadeado: `by_data_id.unlock_*.lock_pos` — corda (296,187), esteira (445,249), pera (436,68), boneco (228,271).
- Mesmos quadros, pivôs e posições de antes (a da corda desceu com o gancho). Com a caixa esperando, a marca fica embaixo dela.

### 18.4 A caixa da escola
- **Dois tamanhos**, 4 quadros cada (0 fechada, 1 racha 1, 2 racha 2, 3 aberta): `box_big` (quadro 76x62, pivô 38,58; corpo 52x41) para
  esteira e boneco; `box_small` (quadro 48x42, pivô 24,38; corpo 28x25) para corda, pera e luvas. Pivô = meio da base, no chão.
- **Uma arte para os dois locais.** A caixa vem da escola, não do lugar, e **não recebe a luz da sala**: é o objeto novo da cena e tem
  que saltar ao olho. Sombra de contato já no quadro.
- Papelão `br3/br2` com tampa `y0`, fita crepe, setas "este lado para cima", carimbo vermelho e **etiqueta branca com o símbolo**.
  Na sala a etiqueta e o carimbo são **ilegíveis de propósito** (nenhum texto fixo sobre a cena). O texto de verdade aparece na dica de
  hover, na etiqueta de papel `ui_box_tag` (9-slice) com o carimbo `ui_box_stamp` (9-slice): layout em `by_data_id.box.tag`.
- **Símbolo da escola: PROVISÓRIO** (`school_symbol_9/16/32`): um frontão de garagem com as ripas do portão, em azul de carimbo. A
  história diz que o símbolo nasce quando a garagem é salva; quando existir, trocar os 3 arquivos e rodar o gerador (ele também está
  pintado dentro das caixas).
- **Lugares** (`layout.box_slots`, iguais na garagem e na academia; seguem a regra do design 1.4, com os tamanhos reais):
  | Slot | Pivô | Caixa | Observação |
  |---|---|---|---|
  | `treadmill` | (445,268) | grande | em cima da marca da esteira |
  | `jump_rope` | (258,244) | pequena | no pé da parede, embaixo do gancho. **Mudou** do (262,288) proposto: ali a caixa grande do boneco encostava nela |
  | `art` | (228,283) | grande (boneco) ou pequena (pera) | canto da frente à esquerda |
  | `glove` | (386,288) | pequena | na frente, à direita do alvo. Era (382,288): 4 px para dar os 8 px de folga |
  Faixa livre do lutador e do alvo: x 281..362. Ordenar por y do pivô, como as pessoas. O Prof. Nelson (394,280) fica **atrás** da caixa
  da luva, que cobre as canelas dele.
- **Parada:** balança 1 px a cada 4 s e pisca o `fx_box_glint` na quina. É isso que chama o clique, sem texto.
- **Cliques** (`by_data_id.box.clicks`):
  | Clique | Quadro depois | Tremida (x, 30 fps) | Efeito |
  |---|---|---|---|
  | 1 | 1 | -1, 1, -1, 0 | `fx_box_chips_1` (5 lascas, 0,36 s) |
  | 2 | 2 | -2, 2, -2, 1, 0 | `fx_box_chips_2` (10 lascas + faísca, 0,43 s) |
  | 3 | 3 | -3, 3, -2, 2, 0 + tela 1 px | `fx_box_burst` (clarão, abas, estrelas, 0,5 s) |
  Os efeitos têm pivô no **meio de cima da caixa** (pos + `top_center_offset` do sprite).
- **Abertura: 1,2 s** do 3º clique ao item assentado (limite 1,5 s): tremida 0–0,15 · estouro 0–0,5 · item aparece 0,15–0,6 · caixa
  aberta some 0,6–0,9 (piscando, sem alpha) · assenta e o foco vai para ele 0,9–1,2. Aparelho de chão sobe de dentro da caixa e pousa;
  corda, pera e luva aparecem direto no lugar com a animação de pendurar que já existe.
- Sons: não há som novo. Sugestão com o que existe: `block.wav`, `hit_heavy.wav`, `punch_crit.wav` + `buy.wav`.

### 18.5 Como a UI convive com a sala
Nenhum texto fixo em cima da cena: saem as plaquinhas, "SEGURE SHIFT", "SEGURAR" e o chip da arte. Na sala só ficam o número do clique
(efeito) e a dica de hover (painel `d1` com borda `ink`, 1ª linha `col_text_1`, 2ª `col_text_2`).
Conferência: `mockups/fase51_garagem_antes_depois_x2.png` (proposta de leitura; quem fecha o layout é o UI/UX, pela `alinhamento-ui`).

### 18.6 Mockups
`fase51_garagem_antes_depois_x2.png` (captura de hoje x os 3 níveis, com a legenda dos tokens), `fase51_caixa_x3.png` (4 estados nos 2
tamanhos, os 3 efeitos quadro a quadro, etiqueta, símbolo e linha do tempo), `fase51_corda_marcas_x2.png` (garagem e academia com as
marcas nos 3 estados, a corda no gancho e as caixas nos lugares, com a equipe cheia), `fase51_sprites_x3.png` (folha de contato).

### 18.7 Placeholder / precisa de pixel artist
- A caixa aguenta retoque: falta textura de papelão (ondulado, amassado de verdade) e os quadros de racha são o mesmo desenho com
  rasgos por cima; um artista faria a caixa deformar. As lascas são quadradinhos com gravidade: falta rotação desenhada.
- O "tchan" é uma estrela de 8 pontas e um anel: funciona, mas é o efeito que mais ganha com animação feita à mão.
- As silhuetas riscadas são o contorno do sprite calculado por código. Servem; à mão ficariam com traço de giz de verdade.
- O gancho da garagem tem 6 pixels. O símbolo da escola é provisório e depende da história.
- A cor da Fama (rampa `f`) foi escolhida para separar das outras 7; vale um olhar humano na tela real, ao lado da Força.

## 19. Fase 5.2 (Bolsa da torcida, Grito da equipe, caixas da L3/L4)
Gerado por código a partir do scratchpad do Diretor de Arte (`art52/make52.gd`, rodado com `--path E:/Fightclicker -- --final`);
o manifest foi relido na hora de gravar e só ganhou as chaves abaixo. A luva L4 (mãos, luta, cursor, `icon_glove_l4`,
`art_hung_glove_l4`, `equipment/glove_l4`) é do Artista de Personagens.

### 19.1 Bolsa da torcida (`event_golden_crew`)
- **Mesmo pacote da luva ×7:** quadro 22x21, pivô (11,10), 3 quadros em loop a 6 fps, o mesmo ouro (fora da paleta de cena de
  propósito: é o evento que salta da sala), o mesmo contorno marrom-escuro e o mesmo brilho em cruz passeando da esquerda para a
  direita. Aparece, flutua e some do mesmo jeito (sala.gd); só troca o sprite (`training.json → golden_event.crew_sprite`).
- **Silhueta oposta, para ler de longe:** a luva é um **cogumelo** (cúpula larga em cima, punho reto creme embaixo); a bolsa é uma
  **pera invertida** (boca franzida em 3 abas e cordão creme em cima, bojo largo embaixo, moeda estampada no meio). O creme do cordão
  é o mesmo do punho da luva: as duas são da mesma família, mas o creme fica embaixo numa e em cima na outra.
- `by_data_id.golden_event` junta as duas variantes (`frenzy_sprite`, `crew_sprite`, anim, fps, área de clique).

### 19.2 Grito da equipe (`icon_crew_click`)
Ícone 16x16 da LOJA (como os outros): megafone **verde** (a cor da equipe nos ícones de Corpo/equipe) gritando para a direita,
com duas ondas de som amarelas sem contorno. `by_data_id.crew_click.icon`.

### 19.3 Caixas da L3 e da L4
`by_data_id.box.sprite_by_item` / `slot_by_item`: `glove_l3` e `glove_l4` = `box_small` no slot `glove` (igual L1 e L2; a L3 não
estava na lista). Etiqueta: `box_label` "LUVA MARCA" / "LUVA TORNEIO" e `box_stamp` "ETIQUETA INTACTA" / "NÃO EMPRESTAR" cabem na
etiqueta de 104 px do padrão 5.1 (conferido no mockup). Conferência da L3: ícone, cursor, luva pendurada e item já existem no padrão
atual; faltava só a caixa.

### 19.4 Mockup e placeholder
`mockups/fase52_bolsa_x3.png`: as duas lado a lado (3 quadros, silhueta, na garagem e na academia em 1x), os ícones da LOJA
(L3, L4, Grito) e as etiquetas das caixas.
Precisa de pixel artist: a bolsa pede volume de tecido de verdade (dobras, peso das moedas puxando o fundo) e um brilho desenhado à
mão; o megafone pede um ângulo de 3/4. Manter 22x21, pivô (11,10) e 3 quadros para trocar só o arquivo.
Nota para o Roteirista: o toast diz "PASSOU O CHAPÉU", mas o objeto é uma bolsa. Ou o texto fala de bolsa/sacola, ou a arte vira
chapéu (perde a silhueta oposta à luva; não recomendo).

## 20. Fase 5.3 (calendário da campanha, Passar o posto, retrato por luva)
Gerador: `tools/art/make_sprites_fase53.gd` (rodar de uma pasta temporária com `project.godot` vazio;
`-- --final` grava no projeto e só acrescenta chaves ao manifest, relendo o arquivo na hora). Retratos por luva:
`tools/art/make_sprites_jogador.gd -- <saida> --so-retratos`. Mockup: `mockups/fase53_calendario_x2.png`.
Dados para a UI: `manifest.json → by_data_id.campaign_calendar`, `pass_post_button`, `player_portrait`. Posições em 1x.

### 20.1 Ideia visual
**Uma folhinha de parede** (argolas, cabeçalho vermelho, picote da folha arrancada) é o símbolo de tudo: o dia anda = folha
arrancada; a data da luta = **dia circulado de caneta vermelha**; campanha completa = folhinha dourada com estrela.
Nenhum relógio de ponteiro, nenhuma contagem em segundos: o jogador pensa em dias.

### 20.2 HUD (nível 2, não grita)
- Fica na coluna da esquerda, no lugar do "PRÓXIMA:" de hoje: plaquinha 9-slice `ui_countdown_plate_<risco>` (7,131) 116x26,
  folhinha `ui_calendar_page` (11,133) com o **dia da campanha** (1x, `d1`), linha 1 "Faltam X dias" (`col_text_1`, x 35, y 136),
  linha 2 o adversário (`col_text_2`, y 146), e embaixo o selo de risco que já existe (35,160).
- A **faixa de 2 px à esquerda da plaquinha tem a cor do risco** (verde/âmbar/vermelho, os mesmos `col_risk_*`); o selo repete
  com ícone, para quem não distingue cor. Nada em `txt_hero`: o número grande da tela continua sendo o Treino.
- Dia da luta: `ui_countdown_plate_today` (fundo `r0`, faixa ouro) + folhinha no quadro 1 (dia circulado). Depois do Kid:
  `ui_countdown_plate_done` + `icon_campaign_complete` e "CAMPANHA / COMPLETA" em `col_money`; sem número, o relógio some.
- Dia virando: `fx_calendar_tear` (4 quadros, 12 fps, uma vez) por cima da folhinha. Sem som novo.

### 20.3 Avisos
| Quando | Sprite | Onde | Comportamento sugerido |
|---|---|---|---|
| 3 dias | `ui_warn_strip_3d` + `icon_calendar` | topo da sala, centrada em x 320, y 22, 18 de altura | desce em 0,2 s, fica ~6 s, sobe |
| 1 dia | `ui_warn_strip_1d` ↔ `_1d_hi` a 2 fps + `icon_calendar_alert` | mesmo lugar | som que já existe ao entrar; fica até a luta ou até clicar |

A de 1 dia é urgente sem ser feia: vermelho da própria paleta, pontas com listras diagonais vermelhas (fita de aviso sem o
amarelo-e-preto de obra), filete dourado, pulso por troca de quadro (sem alpha, sem tremida). Largura = conteúdo + margens;
nenhuma das duas cobre o lutador nem o alvo.

### 20.4 Dia da luta
- A sala fica atrás do **mesmo pontilhado** que já escurece a sala na prévia; o HUD mostra a plaquinha "today".
- A prévia ganha a folhinha grande `ui_day_badge` (40x40) **presa com fita crepe** no canto de cima à esquerda (offset -10,-12),
  por cima da borda: cabeçalho "HOJE" 1x branco, número do dia em `txt_hero` dentro do círculo de caneta.
- Dois botões **diferentes no peso**: **LUTAR!** o vermelho cheio de sempre (`fight_button`); **PASSAR O POSTO** de contorno
  roxo sobre `d1` (`ui_button_pass_*` + `icon_pass_post`, texto `p2`). Roxo = Legado, que é o que ele rende. O contorno deixa a
  escolha clara e diminui o clique sem querer (a confirmação continua obrigatória). Sem botão de voltar a treinar.
- Fora do dia, o botão roxo da sala segue igual e só troca o texto; sugestão: ícone `icon_pass_post` também ali, para a mesma
  ação ter o mesmo desenho. "PASSAR O POSTO" + ícone cabem em 103 px (o botão tem 115).

### 20.5 Retrato da luta por luva (B1)
`portrait_player` (velha) + `portrait_player_glove_l1..l4`: mesmo recorte, fundo e virada; só a luva muda. Regra igual à das
folhas: id = `portrait_player` + sufixo da luva equipada; vale no topo da luta e na prévia (inclusive a do dia).
O `portrait_player` regerado saiu idêntico ao arquivo de antes.

### 20.6 Placeholder / precisa de pixel artist
- A folhinha e a folha arrancada são retângulos girados por código: falta a folha dobrar de verdade e um rasgo desenhado.
- O círculo de caneta é uma elipse com espessura variável; à mão ficaria com traço de marcador (começo e fim sobrepostos).
- O selo da campanha (roseta) e o `icon_pass_post` (luva → estrela) pedem desenho à mão; manter 40x44 e 16x16.
- Números da folhinha usam a fonte 5x7; uma fonte de calendário (números condensados) ficaria melhor e é o mesmo pedido da §18.1.

## 21. Fase 5.4 (árvore grande: o mapa que se revela)
Gerador: `tools/art/make_sprites_fase54.gd` (rodar de uma pasta temporária com `project.godot` vazio; `-- --final` grava no projeto e só
acrescenta chaves ao manifest, relendo o arquivo na hora). Mockup: `mockups/fase54_mapa_x2.png`. Dados para a UI e o Programador:
`manifest.json → by_data_id.skill_map` (tela, regras de pintura, neblina, linhas, estados, posições). Peças do mapa em `assets/sprites/ui/map/`.

### 21.1 Ideia visual
**O quadro de avisos da escola.** No meio, um quadro de **cortiça** com os 12 nós de sempre. Em volta, cada região é um **pedaço de
material pregado na parede**: concreto (Garagem), azulejo verde (Academia), lona vermelha do ringue (Boxe), tatame azul (Jiu-jitsu) e
feltro roxo do mural (Campanha). O que sobra é a parede escura. Nó comprado = **plaquinha pregada com tachinha dourada**; linha acesa =
o **Legado correndo** (roxo, com um pixel branco andando). O resto fica sob **neblina** (ink com nuvem d1 em dither), que recua quando o
nó aparece. Nenhuma região precisa de texto para ser reconhecida: o material diz.

### 21.2 Tela (640x360, por cima da sala)
| Peça | Sprite | Lugar |
|---|---|---|
| Moldura de madeira com pregos (9-slice) | `ui_map_frame` | (0,0) 640x360 |
| Barra do topo | `ui_map_topbar` | (5,5) 630x20 |
| Título | `icon_skill_map` + texto `col_text_1` | ícone (9,7), texto (29,11) |
| Dica "arraste ou use a roda" | texto `col_text_2` | 12 px depois do título, y 11 |
| **Legado** (o número herói desta tela) | `icon_legacy_16` + `txt_hero` `col_legacy` | texto termina em x 610, y 8 |
| Fechar | `ui_map_close_normal/hover/pressed` | (616,7) 16x16 |
| Janela do mapa | recorte | (5,26) 630x329 |
| Borda rebaixada (miolo vazio) | `ui_map_viewport_edge` | (4,25) 632x331, por cima do mapa |

Ordem de desenho do mapa: fundo pintado → linhas → neblina → nós → plaquinhas de região e preços → efeitos → cartão.

### 21.3 Fundo e regiões
- Ladrilhos 32x32 que emendam: `map_tile_wall|center|garage|gym|boxing|bjj|campaign`.
- **Pintura por células de 8x8, feita uma vez ao abrir**: cada célula pega a região do nó mais perto até 44 px; nó de ligação pinta
  xadrez das duas regiões; nada perto = parede. Região trancada (Academia antes do 1º discípulo lá; arte não liberada) = parede.
  Costura de 1 px ink entre materiais, 1 px de luz no topo do recorte e 1 px de sombra na parede embaixo. O recorte sai em degraus de
  8 px, de propósito: parece pedaço cortado e pregado. Código de referência: `region_grid()` / `paint_regions()` no gerador.
- Distância mínima entre centros: **40 px** (nó pequeno) e **52 px** (marco). Pedido ao Designer ao escolher as posições.

### 21.4 Nós (3 tamanhos, 4 estados)
| | Pequeno 24x24 (pivô 12,12) | Marco 38x38 (pivô 19,19) | Ligação 28x24 (pivô 14,12) |
|---|---|---|---|
| Comprado | `map_node_s_owned_<tom>` | `map_node_b_owned_<tom>` | `map_node_link_owned_<a>_<b>` |
| À vista, Legado paga | `map_node_s_buyable` (2 quadros, 2 fps) | `map_node_b_buyable` | `map_node_l_buyable` |
| À vista, sem Legado | `map_node_s_missing` + `map_node_veil` | `map_node_b_missing` + véu | `map_node_l_missing` + véu |
| Escondido | não desenha (`_hidden` com "?" = quadro de partida da revelação) | `map_node_b_hidden` | `map_node_l_hidden` |
| Mouse em cima | `map_node_s_hover` | `map_node_b_hover` | `map_node_l_hover` |

- Forma: **octógono** (plaquinha), diferente dos quadrados da árvore antiga. O marco tem anel duplo e 4 pontas; a ligação tem elos dos
  dois lados e, comprada, o anel cortado na diagonal com as cores das duas regiões (`<a>_<b>` na ordem garage, gym, boxing, bjj, campaign).
- Ícone 16x16 sempre no centro (pivô −8,−8). Comprado leva a tachinha dourada no canto de cima à direita.
- **Tom do anel** (`tone_by_branch_or_region`): Corpo e Boxe = vermelho (`r2/r3`, o Boxe herda a luva); Campanha (ramo e região) = ouro
  (`y0/y1`); Estilo = roxo (`p1/p2`); Garagem = giz (`g3/white`); Academia = verde (`gr2/gr3`); Jiu-jitsu = azul (`b2/b3`).
  O fundo diz a região, o anel diz o ramo: o ouro da Campanha em cima do feltro roxo tem contraste de sobra.
- À vista que o Legado paga = anel `col_buyable` piscando (mesma regra da 5.1). Sem Legado = anel escuro e véu pontilhado no ícone
  (ainda dá para ler o que é). **Preço**: etiqueta 9-slice embaixo de cada nó à vista, `ui_map_price_ok` (p0, número `col_legacy`) ou
  `ui_map_price_missing` (d1, número `col_text_2`). Nunca vermelho. Comprado não mostra preço.

### 21.5 Linhas
Retas de centro a centro em **pixels de Bresenham** (nada de Line2D com antialias nem textura girada):

| Estado | Quando | Desenho |
|---|---|---|
| Acesa | os dois comprados | 2 px (`p2` + `p1`) + sombra ink; 1 pixel branco a cada 8, andando 1 px por quadro a 8 fps |
| À vista | os dois revelados, pelo menos um não comprado | 1 px `g2` + sombra ink |
| Apagada | um lado escondido | 1 px `g0` tracejado 2/2, **antes da neblina** (some aos poucos dentro dela: diz "tem mais ali") |

### 21.6 Neblina e revelação
- `map_fog_25|50|75|100` (32x32, Bayer). Por célula de 8x8, pela distância ao nó revelado mais perto: < 40 px limpa; 40–48 = 25%;
  48–56 = 50%; 56–64 = 75%; além = 100%.
- **Revelar (≤ 0,5 s):** as células em volta do nó novo descem um nível a cada 0,1 s (0,4 s no total) e `fx_map_reveal` (40x40,
  6 quadros, 12 fps) toca no centro: a nuvem com "?" se abre em fiapos e ficam 4 faíscas. O nó aparece no quadro 2.
- **Comprar:** `fx_map_buy` (40x40, 5 quadros, 12 fps): clarão no formato do nó, anel ouro abrindo, faíscas. O anel vira "comprado" no
  quadro 1; no quadro 2 começam as revelações dos vizinhos, todas juntas. Sem alpha e sem som novo (reaproveitar `buy.wav`).

### 21.7 Plaquinhas de região e cartão
- `ui_map_region_label_<região>` (9-slice, 13 px, faixa na cor do anel) + `icon_region_<região>_9` + nome 1x. Aparece quando o 1º
  nó da região fica à vista, uns 30–40 px acima dele, no mundo (anda com o mapa). O centro não tem plaquinha.
- Cartão: `ui_map_card` (d1, igual à dica) com nome / efeito na cor do tipo / preço, e no pé a faixa roxa `ui_map_card_next` com
  `icon_calendar` e "VALE NA PRÓXIMA CAMPANHA". Abre ao lado do nó, sempre inteiro dentro da janela do mapa.

### 21.8 Botão da sala
- `ui_map_button_normal|hover|pressed` 22x22 com `icon_skill_map` (cortiça com 3 tachinhas e barbante). **Lugar: (132,22)**, canto de
  cima à esquerda da sala, na parede lateral (igual na garagem e na academia). Fica longe do alvo (x 281..362), das faixas de aviso
  (centradas em x 320, y 22) e da faixa do assistido (y 273..290). O `debug_overlay` também usa (134,24), mas só aparece em debug.
- Brilho: `ui_map_button_glow` (2 quadros a 2 fps, borda ouro + faísca trocando de canto) **só** quando há nó à vista que o Legado
  paga. Sem compra: peça normal, parada. A hierarquia da 5.1 não muda: é nível 3, sem texto fixo e sem número.
- Dica (hover) padrão: "ÁRVORE" + 2ª linha `col_text_2` com quantos nós dá para comprar.
- Plano B, se o dono não achar o botão: a mesma ação como botão com texto "ÁRVORE" no fim da coluna da esquerda, (7,264) 116x22.
- Na tela de fim, o botão ÁRVORE pode ganhar `icon_skill_map` à esquerda do texto, para as duas portas terem o mesmo desenho.

### 21.9 Ícones
- **Regiões:** `icon_region_garage|gym|boxing|bjj|campaign` (16x16) e `_9` (9x9): fachada com portão de aço, halter no azulejo,
  canto do ringue com 3 cordas, nó da faixa no tatame, folhinha com estrela. Também são o ícone **provisório dos marcos** da região.
- **Nós novos:** `skill_rope_ready` (corda montada: corda pendurada no prego, com brilho), `skill_prep_day` (+1 dia: folhinha com
  "+1"), `skill_shout_loud` (Grito mais alto: o megafone do Grito, maior, com 3 ondas).
- **Nós pequenos usam o ícone do tipo de efeito** (`by_data_id.skill_map.icon_by_effect`), reaproveitando os 12 atuais e os ícones da
  LOJA dos aparelhos. Os nomes dos tipos novos ali são sugestão; vale o que o Designer puser no `skill_tree.json`.
- **2ª passada (feita):** os 6 marcos do `fase5.4-design.md` §9 têm ícone próprio 16x16 em `assets/sprites/ui/`:
  `skill_home_metronome` (gar_metro), `skill_crew_regulars` (gar_crew_start), `skill_coach_notebook` (camp_diary),
  `skill_standing_fan` (gym_fan), `skill_counter_punch` (box_counter), `skill_firm_base` (bjj_guard).
- **Qual ícone cada nó usa:** `skill_map.icon_by_node` (os 39 nós do `skill_tree.json` v2) manda; depois `icon_by_effect`
  (com os nomes reais dos tipos; `art_rule_bonus`/`art_fight_bonus` escolhem pela `requires_art`); por último o campo `icon` do nó.
- **Mapa real conferido** (`mockups/fase54_mapa_real_x2.png`, `skill_map.map_check`): 741 pares, menor distância 57 px, nenhum
  abaixo de 40/52; plaquinhas de região não cobrem nó. Ressalva: as linhas `gar_radio–link_mat` e `gar_rope–link_shout` passam a
  11 px do centro de `body_crew_2` e `body_heavy_hands` (parecem ligadas a eles). Proposta ao Designer: `link_mat` (-6,4) e
  `link_shout` (-6,-4) (folga de 40 px; painel B do mockup).

### 21.10 Placeholder / precisa de pixel artist
- Os ladrilhos são ruído por código: um artista faria cortiça com furos de tachinha, concreto com manchas e tatame com costura.
  A neblina repete a cada 32 px; à mão, ladrilhos de 64 com nuvens desenhadas ficariam bem melhores.
- A borda das regiões em degraus de 8 px é proposital, mas um recorte desenhado (papel rasgado, lona com bainha) daria mais vida.
- `fx_map_reveal` e `fx_map_buy` são anéis e pontos calculados; são os efeitos que mais ganham com animação feita à mão.
- O ícone da corda montada é o mais fraco em 16 px. Manter os tamanhos (24/38/28, ícone 16, ladrilho 32) para trocar só os arquivos.

## 22. Fase 6a (Prólogo e voz: balão, parede da memória, garagem salva)
Gerador: `tools/art/make_cenario_fase6a.gd` (rodar de uma pasta temporária com `project.godot` vazio; `-- --final` grava no projeto e
só acrescenta chaves ao manifest, relendo o arquivo na hora). O `make_sprites_fase6a.gd` é do Artista de Personagens (Téo, Osmar, gesto).
Mockup: `mockups/fase6a_garagem_x2.png`. Dados para a UI: `manifest.json → by_data_id.speech_bubble`, `skip_hold`, `garage_saved_seal`,
`garage_story_wall`, `coach_point`, `school_symbol`. Posições em 1x. Valores do balão: `docs/cutscenes/balao-e-voz.md` (manda).

### 22.1 Fonte 5x7 (conferida antes de tudo)
- Minúsculas acentuadas (á à â ã é ê í ó ô õ ú ç) **existiam**, mas o acento encostava na letra (ã e õ viravam borrão). Agora a marca
  fica 1 linha acima, com 1 linha de folga. O `í` perdeu a bandeirinha (lia como "1"). Entraram `—` e `…` (117 caracteres).
  Mesmo atlas, mesma ordem, mesma métrica (`lineHeight` 12, `base` 9): nenhuma largura de texto muda.
- Maiúsculas `Í Â Ã Ç É` renderizam (RAÍZES, COBRANÇA, CINTURÃO). O acento da maiúscula encosta na letra porque a célula não tem
  mais linhas em cima; lê bem no contexto. Separar exigiria fonte mais alta (mexe em todo o layout): não vale agora.
- A fonte não tem `▼`: a seta é o sprite `ui_balloon_next`.

### 22.2 Balão
| Peça | Tamanho | Regra |
|---|---|---|
| `ui_balloon` | 9-slice 16x16, cantos 5 | cream, contorno ink com canto de 2 px, sombra dura `d1` embaixo e à direita **dentro** do retângulo w x h |
| `ui_balloon_tail` (+ `_l`, `_r`) | 7x6 | linha 0 cream em y = by + h - 2 (apaga o contorno); ponta em by + h + 3. `_l`/`_r` só quando a ponta está a menos de 14/15 px da quina |
| `ui_balloon_tag_<cor>` | 9-slice 8x10 | em (bx + 6, by - 6), largura nome x 6 + 6, nome em minúsculas. **10 px e não 9**: o acento de "téo" precisa de folga. Téo `red` (r2, texto white), Osmar `gold` (y0, texto ink), discípulo `blue` (b3) |
| `ui_balloon_next` | 5x4, 2 quadros | modo cena (6b) |
- Texto ink sem sombra, topo da maiúscula em by + 5, linhas a 9 px; 1 linha = 17, 2 linhas = 26 de altura.
- Na parede creme da academia o balão cream se separa pelo contorno e pela sombra (conferido no mockup).
- **Proposta de regra extra (DC/UI):** o balão não cobre o `head_anchor` de outro personagem na sala. Sem ela, o "desliza" do Téo
  em `foco_saco` (x 154..307, y 175..200) tapa a cabeça do Osmar (197,173); com ela, o balão sobe (x 226..379, y 149..174, ponta em y 178).
- **Segurar ESC** (só na abertura): chip `ui_skip_chip` (apagado) / `_active`, anel `ui_skip_ring` (9 quadros) e tecla `icon_key_esc`;
  altura 16, canto de baixo à direita da sala (direita em 507, base em 285). Texto sugerido: `esc: pular`.

### 22.3 Parede da memória (garagem, Arco 1)
Faixa **x 176..256, y 38..87**: ajuste da proposta do DC (180..262, 56..104), porque abaixo de y 92 está o metrônomo (231..249) e
em y 101 a prateleira. Não encosta no gancho da corda, no pôster, na lâmpada, na corrente (x 335), na pera da parede nem na porta.
| Objeto | Sprite | Pos (canto sup. esq.) | Quando |
|---|---|---|---|
| Aviso de cobrança | `wall_notice_debt` 22x28 | (178,52) | desde o começo até a garagem salva |
| Ficha amassada | `wall_form_blank` → `wall_form_named` 22x24 | (205,62) | sempre; troca quando a garagem é salva |
| Foto antiga (Osmar jovem, torta) | `wall_photo_old` 18x21 | (237,67) | sempre (cobre a fotinho pintada no fundo) |
| Recorte de jornal | `wall_clipping` 20x24 | (236,40) | 1ª vitória da escola |
| Foto da equipe | `wall_photo_team` 26x21 | (176,54) | garagem salva (no lugar do aviso) |
| Símbolo pintado | `wall_school_symbol` 32x40 | (344,38) | garagem salva (alto, à direita da corrente) |
- Nenhum objeto tem texto legível na sala (regra da 5.1). "ESCOLA: NENHUMA" / "ESCOLA: RAÍZES FIGHT CLUB", "AVISO DE COBRANÇA" etc.
  vão na dica de hover (textos do Roteirista). A ficha "depois" tem o rabisco riscado de vermelho e o nome à mão em caneta azul.
- Luz da lâmpada aplicada em cada ponto: não mover para longe. Só na garagem; troca de estado sem animação.
- **Osmar em (196,236)** (decisão do Produtor): balão em cima, sem ajuste (x 132..285, y 138..163), não cobre a parede da memória.
  Os vizinhos 1 e 2 passam na frente das pernas dele com a equipe cheia (ordem por y): aceito.

### 22.4 Símbolo da escola: Raízes Fight Club
A lâmpada da garagem, de pé, plantada: bulbo, soquete, uma linha de chão e raízes embaixo. `school_symbol_5/9/16/32` em tinta de
carimbo azul (b1/b2), como o provisório; `box_big`/`box_small` tiveram a etiqueta retocada (só o símbolo). Na parede, o 16 em 2x:
bulbo em tinta amarela que afunda no rejunte, raízes em tinta marrom, escorridos. O 5x5 é o limite: lê como "lâmpada com raiz" só de perto.

### 22.5 Selo "garagem salva"
O próprio aviso de cobrança, despregado, com o carimbo azul da escola. `seal_garage_saved` 52x54 na tela de vitória do cinturão em
**(418,146)** (à direita das linhas de prêmio), mais uma linha de prêmio `icon_garage_saved` + "GARAGEM SALVA" / "O LUGAR CONTINUA
NOSSO". Entrada: 2 quadros em 2x e depois 1x, tremida de 1 px, som que já existe. `seal_garage_saved_text` (96x64, com fita) e a fita
9-slice `ui_seal_garage_band` servem para espaços maiores.

### 22.6 Placeholder / precisa de pixel artist
- Papéis (aviso, ficha, recorte) são retângulos com riscos: um artista faria o amassado de verdade, a letra à mão e o papel de jornal.
- As fotos têm 5–10 px de gente: o retrato do Osmar jovem e a foto da equipe pedem desenho à mão (mesmos tamanhos).
- O símbolo é o que mais pede mão humana: em 5x5 a raiz é um traço. Manter 5/9/16/32 para trocar só os arquivos.
- O carimbo e a tinta na parede usam falhas por sorteio fixo; à mão ficariam com pressão e borda de carimbo real.
