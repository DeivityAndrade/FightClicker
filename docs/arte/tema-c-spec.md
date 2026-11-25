# Tema C (cartaz de luta): spec das peças finais

Diretor de Arte, 2026-11-25. Direção C escolhida pelo dono. Este arquivo diz **o que cada PNG é, onde vai e como esticar**.
Quem aplica no jogo é o UI/UX (`ui/`, `scenes/`). Eu não mexi em nenhum dos dois.

- **Gerador:** `tools/art/make_tema_c.gd` (headless; o comando está no cabeçalho). Ele grava as PNGs, o `parede.json`, o
  `manifest_tema_c.json` e as pranchas, **mede** o centro do texto em cada peça e o contraste e confere a parede. Última rodada:
  **0 avisos**.
- **Peças da UI:** `assets/sprites/ui/tema_c/c_*.png`. As entradas prontas para o manifest (arquivo, tamanho e `nine_slice`) estão em
  `assets/sprites/ui/tema_c/manifest_tema_c.json`: é só copiar para `assets/sprites/manifest.json -> sprites`.
- **Menu:** `assets/sprites/menu/menu_*.png` + `assets/sprites/menu/parede.json` (as camadas da parede com o marco de cada uma).
- **Pranchas de conferência** (montadas pelo gerador **com as PNGs gravadas**, do jeito que o jogo vai montar):
  `docs/arte/mockups/identidade/tema_c_final_{menu_vazio,menu_meio,menu_cheio,sala,janela}.png` (1x), `tema_c_final_prancha.png`
  (as 3 paredes e a sala lado a lado) e `tema_c_final_pecas_x2.png` (todas as peças esticadas no tamanho de uso, em 2x só para ver).
- As PNGs novas ainda **não têm `.import`**: o Godot cria quando o projeto for aberto (filtro nearest, como o resto, pelo padrão do projeto).

## 1. Regras que valem em tudo
1. **Tudo em 1x**, no mesmo pixel da UI. Nada ampliado 2x (nem a parede do menu). O texto 2x/3x é a fonte 5x7 em escala inteira.
2. **Paleta fechada** (`direcao-visual.md` §3). Nenhuma peça usa alfa parcial: sombra e escuro são pixel `ink` cheio, em dither quando
   precisa de meio-tom.
3. **Sombra dura RETA para baixo** (0, 2) nos botões e no LUTAR!, (0, 3) na janela, (0, 4) no logo. Nada puxa para o lado. A sombra
   fica **dentro do rect** do controle (o 9-slice já tem as linhas dela), então o centro do texto é medido na **face**, sem a sombra.
4. **Texto centrado** pela regra do jogo: `x = floor((largura da área - largura visível) / 2)` dentro da área de conteúdo do 9-slice.
   As margens de conteúdo da tabela do §3 já deixam a face com margem igual dos dois lados (diferença de no máximo 1 px, que vem
   de largura ímpar em botão par; o verificador aceita).
5. **Contraste:** texto 1x pede **4,5:1**, texto 2x ou maior pede **3:1**. **Nunca `white`/`cream` sobre `r2`** (3,7:1 e 2,8:1):
   texto claro vai sobre **`r1`**, com 1 px de sombra `ink` (0, 1). O `r2` é só fundo, faixa, listra e carimbo.
6. **9-slice:** use `NinePatchRect`/`StyleBoxTexture` com `axis_stretch` em **TILE** (o papel e o asfalto têm grão; esticado, o grão
   borra). As peças marcadas "altura fixa" têm diagonal na borda: só esticam na horizontal.

## 2. Tokens de cor
| Token | Hex | Uso |
|---|---|---|
| `ink` | #14101a | contorno, sombra dura, fio da faixa, texto sobre papel |
| `d1` (asfalto) | #2a2233 | faixa do HUD, botão normal |
| `d2` | #3d3346 | grão do asfalto, luz do botão normal, botão desabilitado, sombra de item na parede |
| `cream` (papel) | #d9cdb4 | barra de baixo, janela, cartão, etiqueta, chapa do LUTAR!, botão de papel, texto sobre escuro |
| `white` | #f2ece0 | filete de luz do papel (1 px em cima) |
| `g3` | #b8b0aa | grão do papel, rótulo do HUD, papel desabilitado |
| `r1` | #9c2a2a | botão em foco, corpo do título da janela, **texto do LUTAR!**, sombra do botão normal |
| `r2` | #d4473a | faixa diagonal, listras, separador do HUD, carimbo PERIGOSO, luz do título |
| `r0` | #5a1a22 | luz de dentro do botão apertado |
| `b1` / `b0` | #2f4a78 / #1f2a44 | carimbo Raízes |
| `y2` | #fff3c4 | chapa do LUTAR! em hover |

**Texto sobre ESCURO** (asfalto `d1`, chip `ink`, botão `d1`/`r1`):
| Papel | Cor | Contraste |
|---|---|---|
| texto 1 | `cream` #d9cdb4 | 9,7:1 em d1; 4,8:1 em r1 (com sombra ink) |
| rótulo | `g3` #b8b0aa | 7,1:1 |
| Treino | `gr3` #a6d86a | 9,2:1 |
| Dinheiro | `y1` #f5d26b | 10,4:1 |
| Fama | `f2` #f59ac0 | 7,5:1 |
| Legado | `p2` #b07ad8 | 4,8:1 |
| desabilitado | `g2` #8f8890 sobre `d2` | 3,5:1 (estado travado, fora da regra) |

**Texto sobre CLARO** (papel `cream`: barra de baixo, janela, cartão, etiqueta do local, botão de papel): o **segundo jogo**.
| Papel | Cor | Contraste |
|---|---|---|
| texto 1 | `ink` #14101a | 11,9:1 |
| texto 2 | `g0` #4a4552 | 7,0:1 |
| Treino 1x | `gr0` #1f3d33 | 7,5:1 |
| Treino 2x (ex.: "+1" da barra) | `gr1` #2f6b4a | 4,0:1 (só 2x ou maior) |
| Dinheiro | `br1` #6b3f2a | 5,6:1 |
| Fama | `f0` #7a2a52 | 5,9:1 |
| Legado | `p0` #4a2f6b | 7,0:1 |
| destaque vermelho | `r1` #9c2a2a | 4,8:1 (nunca `r2`: 2,8:1) |
| desabilitado | `g1` #6b6570 sobre `g3` | (estado travado, fora da regra) |

Sugestão para o `ui_tema.gd`: manter `COL_TREINO/COL_MONEY/COL_FAME/COL_LEGACY` como estão (escuro) e criar o par
`COL_*_CLARO` (gr0, br1, f0, p0) + `COL_TEXT_CLARO = INK`, `COL_TEXT_CLARO_2 = G0`. Constantes que faltam hoje no `ui_tema.gd`:
`R0`, `B0`, `B1`, `GR0`, `GR1`, `F0`.

## 3. Peças da UI (`assets/sprites/ui/tema_c/`)
Margens no formato **L T R B** (esquerda, cima, direita, baixo). "Conteúdo" = `content_margin` do `StyleBoxTexture` (igual às margens
da textura, salvo onde diz).

| Peça | Tamanho | 9-slice L T R B | Modo | Conteúdo / texto | Vai em |
|---|---|---|---|---|---|
| `c_hud_faixa` | 16x21 | 0 1 0 3 | ladrilho | área útil 18 px; as 3 de baixo são fio `ink`, fio `r1` e sombra em dither (ficam por cima da sala) | `hud.gd`: `_fundo` passa de `ui_panel` 640x18 para esta peça em **640x21** (o HUD continua 18) |
| `c_hud_sep` | 9x18 | — | fixo | separador diagonal (r2 + fio creme); centro óptico em x=4 | `hud.gd` `_reposicionar`: um entre TREINO e DINHEIRO e um entre DINHEIRO e o nome da carreira, no meio do vão (vão de 10 px) |
| `c_hud_etiqueta` | 24x18 | 7 1 1 1 | ladrilho, **altura fixa 18** | texto `ink` a 10 px da diagonal; Fama `f0`, Legado `p0`; separador interno = fio `r2` 1x10 | `hud.gd`: atrás de `_local` + Fama + Legado, de `_area_local.position.x - 10` até 640 |
| `c_barra` | 16x30 | 0 3 0 0 | ladrilho | papel; borda ink de 2 em cima + filete white | `barra_baixo.gd`: `_fundo` (`ui_panel`) 640x30 |
| `c_barra_faixa` | 160x30 | — | fixo | faixa diagonal vermelha com listras | `barra_baixo.gd`: TextureRect em **(480, 0)** da barra, por cima do fundo e por baixo do LUTAR!/POSTO |
| `c_lutar_normal/hover/pressed/disabled` | 102x24 | 8 2 8 4 (pressed: **8 4 8 2**) | fixo (= rect LUTAR) | "LUTAR!" **2x em `r1`** com sombra `ink` (0,1); desabilitado `g1` sem sombra | `barra_baixo.gd`: `botao_estilizado(..., "c_lutar")` (troca o prefixo `ui_button_fight`); a cor do texto sai de `Y2` para `R1` |
| `c_btn_normal` | 12x16 | 2 2 2 4 | ladrilho | asfalto `d1`, sombra `r1`; texto `cream` | botão padrão (estado normal) em `ui_tema.aplicar_estilo_botao`; aparelho comprável/sem foco na barra |
| `c_btn_foco` | 12x16 | 2 2 2 4 | ladrilho | `r1`, luz `r2`, sombra `ink`; texto `cream` + sombra ink (0,1) | **hover** de todo botão; foco ativo da barra (no lugar de `ui_button_focus_*`); botão principal da janela (CONTINUAR, OK) |
| `c_btn_apertado` | 12x16 | 2 **4** 2 **2** | ladrilho | face 2 px mais baixa, sem sombra; texto `cream` (desce junto) | `pressed` de todo botão |
| `c_btn_desabilitado` | 12x16 | 2 2 2 4 | ladrilho | `d2`, sem sombra; texto `g2` | `disabled`; aparelho trancado na barra |
| `c_btn_papel_normal` | 12x16 | 2 2 2 4 | ladrilho | papel `cream`, sombra `r1`; texto `ink` | botões secundários **sobre fundo escuro** (menu, FECHAR, VER LUTA); hover/apertado = `c_btn_foco`/`c_btn_apertado` |
| `c_btn_papel_desabilitado` | 12x16 | 2 2 2 4 | ladrilho | `g3`, borda `g1`, sem sombra; texto `g1` | desabilitado do botão de papel |
| `c_janela` | 22x25 | 3 3 3 6 | ladrilho | papel, borda ink de 2, sombra ink de 3 | `janela_base.gd` `moldura()`: no lugar de `ui_window`; **rect +3 px de altura** (a sombra) |
| `c_cartao` | 12x14 | 2 2 2 4 | ladrilho | papel, borda 1, sombra 2 | painéis pequenos da sala (`painel_atributos.gd`, `painel_proxima.gd`, aba da direita, cartões); rect +2 px |
| `c_janela_titulo` | 27x16 | 2 1 10 2 | ladrilho, **altura fixa 16** | texto 1x `cream` + sombra ink; centrado na parte reta | `janela_base.gd` `faixa_titulo()` (escala 1), no lugar de `ui_window_title_*` |
| `c_janela_titulo_g` | 34x30 | 2 1 16 2 | ladrilho, **altura fixa 30** | texto 2x (ou 3x) `cream` + sombra ink | `faixa_titulo()` com escala 2/3 (VITÓRIA!, DERROTA, FIM DE CARREIRA) |
| `c_chip` | 8x13 | 2 2 2 2 | ladrilho, altura 13 | `ink` com luz `d2`; texto `cream` | subtítulo do menu, "FALTAM N DIAS", PRÓXIMO, avisos curtos |
| `c_etiqueta` | 12x12 | 5 1 1 2 | ladrilho, **altura fixa 12** | etiqueta de preço (furo à esquerda); texto `ink` | NOVO, RECORDE, preço; a face lida vai do furo (x+4) à borda direita |
| `c_carimbo_perigoso` | 72x16 | — | fixo | palavra inteira, moldura falhada | risco "difícil/perigoso" (`selo_risco`, `cartao_adversario.gd`) |
| `c_carimbo_moldura` | 12x12 | 4 4 4 4 | ladrilho | moldura dupla `r2` falhada; texto `r2` por cima (é carimbo: fica fora da regra de contraste) | outros selos (FÁCIL, PAREJO, REVANCHE) |
| `c_carimbo_raizes` / `_p` | 40x40 / 24x24 | — | fixo | carimbo redondo azul com o R da escola | janela de vitória (canto do título), mural, garagem salva |

**O que muda no `ui_tema.gd`** (sugestão; o código é do UI/UX): `aplicar_estilo_botao` passa a usar `c_btn_normal` (normal),
`c_btn_foco` (hover), `c_btn_apertado` (pressed), `c_btn_desabilitado` (disabled), e as cores de fonte `CREAM` (e `G2` desabilitado).
Um `estilo_base = "c_btn_papel_normal"` troca o jogo para o de papel (fonte `INK`). Os `ui_button_focus_<atributo>` viram todos
`c_btn_foco`: o atributo fica no **ícone** (a cor do tema é uma só, o vermelho).
Medidas que **não mudam**: HUD 18 de área útil, barra 30, focos 86x20 a cada 90 a partir de x 92, LUTAR 102x24 em (507, 3),
POSTO 22x22, botões do menu 152x22 a cada 28.

**Medidas do gerador** (margem esq/dir e cima/baixo do texto na face): foco 86x20 "SACO" 31/32 e 5/6; menu 152x22 "CONTINUAR" 50/51 e
6/7; LUTAR! 17/16 e 4/4 nos 4 estados; título 16 "VITÓRIA" 35/36 e 3/3; título 30 2x "VITÓRIA!" 32/32 e 6/7; chip 7/7 e 3/3;
etiqueta 16/17 e 2/2; PERIGOSO 13/14 e 4/5. Na sala montada: SACO/ESTEIRA/CORDA (com ícone) 25/25, 18/18, 23/23; "?" 5/6.

## 4. Menu: parede de cartazes que enche com o save
**Sem spoiler:** a parede mostra só o que o jogador já viveu. Save novo ou sem save: só as camadas "sempre". Cada marco da história
acrescenta um item. A lista abaixo é a mesma do `assets/sprites/menu/parede.json` (que o jogo deve ler: ordem, arquivo, posição,
condição).

Montagem, de trás para frente: `menu_parede.png` em (0,0) → as camadas **na ordem da tabela** → a faixa → o logo → subtítulo e botões.
As posições são do canto de cima à esquerda da PNG (que já inclui a fita, o prego e a sombra de 1 px de cada item). A **luz já está
pintada** em cada PNG (a lâmpada fica escondida atrás da faixa e acende o eixo; os lados ficam um passo mais escuros na rampa): os
itens só funcionam na posição deles. Mudou a posição? Rode o gerador de novo.

| # | Camada (`menu_item_*.png`) | Posição | Aparece quando | Campo do save |
|---|---|---|---|---|
| 1 | `soco` (cartaz SOCO da garagem) | (22, 126) | sempre | — |
| 2 | `luta_sabado` (cartaz genérico LUTA / SÁBADO 20H) | (567, 126) | sempre | — |
| 3 | `luvas_velhas` (as luvas velhas do mentor no prego, no eixo) | (295, 288) | sempre | — |
| 4 | `aluga_se` (papel ALUGA-SE com tirinhas; rua) | (46, 288) | sempre | — |
| 5 | `recorte_vitoria` (recorte GARAGEM: a 1ª vitória) | (88, 132) | 1ª vitória | `GameState.marco("first_school_win")` |
| 6 | `raizes` (quadro RAÍZES com o carimbo) | (26, 204) | garagem salva | `marco("garage_saved")` |
| 7 | `foto_equipe` (polaroide: treinador, o 1º lutador, o discípulo) | (152, 136) | 1ª sucessão | `marco("cena_primeira_sucessao")` |
| 8 | `foto_antiga` (foto antiga do treinador, em sépia) | (436, 140) | chegada à academia | `marco("cena_primeira_academia")` |
| 9 | `faixas_john` (as faixas de mão do 1º lutador, etiqueta JB) | (164, 214) | saída do 1º lutador | `marco("cena_saida_primeiro_mentor")` |
| 10 | `liga` (cartaz LIGA DO VALE / JAMES) | (489, 122) | liga aberta | `marco("regional_league_opened")` |
| 11 | `liga_campeoes` (tira CAMPEÕES colada sobre o cartaz da Liga) | (487, 172) | 1º cinturão do Vale | `marco("regional_belt_first")` |
| 12 | `recorte_vale` (recorte emoldurado DERRUBA, o cinturão) | (560, 212) | chegada ao centro | `marco("center_arrival")` |
| 13 | `recorte_vulto` (recorte VULTO: o vulto de capuz no telhado) | (508, 222) | ouviu o boato | `marco("black_cat_rumor_heard")` |
| 14 | `capuz` (o capuz no prego) | (104, 214) | fez a 1ª Ronda | `GameState.lenda().rounds >= 1` (`permanent.black_cat.rounds`) |

- Os marcos estão em `school.milestones` do save (`escola_falas.gd marco(id)`); não há campo novo. O menu precisa do save **carregado**
  para ler; se o fluxo abrir o menu antes, basta ler o JSON do save e olhar `school.milestones` e `permanent.black_cat.rounds`.
- A 11 só aparece com a 10 (o cinturão do Vale sempre vem depois de a liga abrir); se por algum motivo vier sozinha, desenhar mesmo
  assim (ela cobre o lugar do cartaz e lê como "tira colada").
- **Conferido pelo gerador:** nenhum item sai da área livre (abaixo da faixa, acima do piso), entra na coluna dos botões (x 226..413,
  y 156..283), cobre a versão ou encosta noutro item (2 px de folga), em qualquer combinação. O canto de baixo à direita e o
  meio de baixo dos lados ficam livres de propósito: lugar para os marcos das próximas fases (Ronda 2, torneio).
- Pranchas: `tema_c_final_menu_vazio.png` (save novo), `_meio.png` (até a liga aberta) e `_cheio.png` (todos os marcos).

### Faixa, logo e botões do menu
| Peça | Tamanho | Onde / como |
|---|---|---|
| `menu_faixa_moldura.png` | 16x88 | ladrilho horizontal em (0, 26), 640 de largura: filetes creme/ink em cima e embaixo, 2 linhas de sombra em dither; o meio é transparente |
| `menu_faixa_listras.png` | 16x76 | ladrilho em (0, 30), 640x76, por baixo da moldura: `r2` com listras `r1` em diagonal. **Scroll:** a região da textura anda **-1 px em x a cada 80 ms** (as listras correm para a direita), passo inteiro, período 16 |
| `menu_logo.png` | 358x40 | em **(148, 47)**; o centro dos pixels visíveis fica em x = 320,0 (o itálico já está compensado). **Provisório** (ver §7) |
| `menu_logo_flash.png` | 358x40 | mesmo lugar; 1 quadro no impacto |
| `menu_logo_mascara.png` | 358x40 | mesmo lugar; só as letras (branco). Para o brilho do loop: faixa diagonal `y1 → white → y2` de 4+2 px, recortada por esta máscara |
| `menu_logo_velocidade.png` | 356x8 | linhas `r3` acima do título caindo: em logo + (1, -11), só no quadro "título cai" |
| `menu_lascas.png` | 387x14 | em (127, 73): lascas creme dos dois lados, quadros IMPACTO e 1º tremor |
| `menu_seta.png` | 6x9 | seta do foco: esquerda em (botão.x - 11, botão.y + 6); direita = `flip_h` em (botão.fim + 5, botão.y + 6) |
| `menu_faixa_entra_30/65.png` | 640x88 | em (0, 26): a faixa entrando com a ponta cortada e o fio de luz `white` |
| subtítulo | — | `c_chip` com largura `largura visível + 14`, 13 de altura, centrado em x = 320, y = 103 (cobre o filete de baixo) |
| botões | 152x22 | x 244, y 164 + 28·i; CONTINUAR em `c_btn_foco` (texto `cream`), os outros em `c_btn_papel_normal` (texto `ink`) |
| versão | — | `g2`, alinhada à direita em x 634, y 349 |

### Tempos da animação (os mesmos do menu v2; agora com as PNGs)
**INTRO, 1 vez ao abrir o menu (860 ms):**
| ms | dura | o quê | peças |
|---|---|---|---|
| 0 | 120 | cena escura, sem UI | parede + camadas, com um `ink` por cima (dither 75% ou alfa 0,75) |
| 120 | 50 | a faixa entra 30% | `menu_faixa_entra_30` |
| 170 | 50 | a faixa entra 65% | `menu_faixa_entra_65` |
| 220 | 60 | faixa completa | moldura + listras paradas |
| 280 | 50 | o título cai: 16 px acima do lugar, com as linhas de velocidade | `menu_logo` em y 31 + `menu_logo_velocidade` |
| 330 | 60 | **IMPACTO:** flash, tudo (faixa + logo) desce 3 px, lascas | `menu_logo_flash`, `menu_lascas`, nó pai em (0, +3) |
| 390 | 50 | tremor (-2, +1) | `menu_logo`, `menu_lascas` |
| 440 | 50 | tremor (+1, -1) | `menu_logo` |
| 490 | 90 | repouso; o subtítulo aparece | chip |
| 580 | 4x40 | os botões entram um a um, subindo 6 px (posição inteira) | botões |
| 740 | 120 | pronto; a versão aparece | — |

**LOOP, enquanto o menu está aberto (3840 ms = 48 x 80 ms):** listras correm 1 px a cada 80 ms (3 voltas de 16 px); o brilho passa
pelo logo nos quadros 0..7 (640 ms) e para 3,2 s; as setas do foco balançam 1 px para dentro a cada 320 ms. Com "reduzir movimento"
(se existir): sem tremor, sem brilho e listras paradas. Tremor e entradas em **posição inteira** (a regra do alinhamento vale no meio
da animação). Referência quadro a quadro: `mockups/identidade/menu_c_anim/tempos.txt`.

## 5. Onde cada peça vai na UI atual (resumo para o UI/UX)
- **`ui/hud.gd`:** `_fundo` → `c_hud_faixa` 640x21. Os 2 separadores `c_hud_sep` no meio dos vãos entre os grupos (o `_reposicionar`
  já calcula os x). Fundo da direita → `c_hud_etiqueta` atrás de local + Fama + Legado; Fama e Legado ali usam `f0` e `p0`, o local `ink`.
  O emblema de nós (`ui_legacy_nodes_badge`) pode virar `c_chip` com texto `p2`.
- **`ui/barra_baixo.gd`:** `_fundo` → `c_barra`; `c_barra_faixa` em (480, 0); focos com `c_btn_foco` (ativo), `c_btn_normal`
  (comprável, texto `y1`), `c_btn_desabilitado` (trancado, texto `g2`); "+N" em `gr1` 2x e "/CLIQUE" em `g0`; dica "CLIQUE NO SACO"
  em `ink`; `?` e SEGURAR em `c_btn_normal` nos tamanhos de hoje; LUTAR! → `c_lutar_*` com texto `r1` 2x; POSTO em `c_btn_normal` 22x22 com o ícone.
- **`ui/janela_base.gd`:** `moldura()` → `c_janela` (rect +3 de altura); `faixa_titulo()` → `c_janela_titulo` (escala 1) ou
  `c_janela_titulo_g` (escala 2/3), largura livre, encostada em (moldura.x + 2, moldura.y + 2); embaixo do título, `divisor` `ink` de
  2 px na largura da janela; `botao_texto()` → `c_btn_foco` no principal e `c_btn_papel_normal` nos outros; o escurecer atrás continua
  o `ui_dim_dither`. Texto da janela no **segundo jogo** (sobre claro).
- **Botões em geral (`ui_tema.gd`):** ver o fim do §3.
- **Carimbos:** `c_carimbo_perigoso` e `c_carimbo_moldura` no selo de risco; `c_carimbo_raizes` na vitória e no mural.
- Balão, calendário, cartão da mudança, selo de risco 16 px, telas cheias, mapa e retratos: ver **§6 (ID3)**. A dica (tooltip)
  continua sem peça própria: use `c_chip` (texto `cream`).

## 6. ID3: as peças que faltavam
- **Gerador:** `tools/art/make_tema_c_id3.gd` (irmão: herda os ajudantes do `make_tema_c.gd` e só troca o `_main`). Mesmo comando
  do cabeçalho, trocando o nome do script. Última rodada: **0 avisos**. O `make_tema_c.gd` agora **junta** o `manifest_tema_c.json`
  (cada gerador só reescreve as entradas dele; as 25 do ID2 ficaram idênticas).
- **Prancha:** `docs/arte/mockups/identidade/tema_c_pecas_id3_x2.png` (montada com as PNGs gravadas, no tamanho de uso, 2x só para ver).
- Tudo em 1x, paleta fechada, sem alfa parcial, sombra dura reta para baixo (regras do §1). Texto: **segundo jogo** (escuro sobre
  papel) em tudo que é papel.

### 6.1 Peça antiga → peça C
| Antiga (`assets/sprites/ui/…`) | Nova (`ui/tema_c/…`) | Quem usa hoje | O que muda no uso |
|---|---|---|---|
| `ui_balloon` | `c_balao` | `balao.gd`, `balao_convite.gd` | mesmo rect (17/26 de altura). A sombra agora é só a última **linha** (antes: linha + coluna): o corpo é simétrico em w |
| `ui_balloon_tail` / `_l` / `_r` | `c_balao_rabicho` / `_e` / `_d` | idem | mesmos 7x6, mesma ponta (`tip_offset` c [3,5], l [0,5], r [6,5]), mesma regra (linha 0 em by + h - 2) |
| `ui_balloon_next` | `c_balao_seta` | `balao.gd` (modo cena) | mesmos 2 quadros 5x4 a 2 fps, mesma posição |
| `ui_balloon_tag_<cor>` (7 cores) | `c_balao_placa_<cor>` (red, gold, blue, green, purple, gray, steel) | `balao.gd`, `balao_convite.gd` | 8x10, 9-slice 2/2/2/2, texto em (3,2). **Largura nova: `largura_visivel(nome) + 7`** (ver 6.3) |
| `ui_countdown_plate_easy/even/hard/today/done` | `c_contagem_easy/even/hard/today/done` | `bloco_proxima.gd` (+ `by_data_id.campaign_calendar.hud`) | rect **116x28** (face 26 + sombra 2); a folhinha (`ui_calendar_page`) e o texto em x 35 ficam |
| `ui_move_card` / `_ready` / `_dim` | `c_mudanca` / `c_mudanca_pronto` / `c_mudanca_apagado` | `bloco_proxima.gd` | rect **+2 px de altura** (sombra); texto `ink` nos três |
| `ui_risk_*` + `icon_risk_*` (13 px, `UiTema.selo_risco`) e `selo_carimbo` | `c_selo_risco_perigoso` / `_equilibrado` / `_facil` (fixos) e `…_base` (9-slice) | `janela_previa.gd` (prévia do cinturão), `bloco_proxima.gd`, `cartao_adversario.gd` | **16 px** de altura (face 14 + sombra 2), ícone já pintado. `hard`→perigoso, `even`→equilibrado, `easy`→facil. O carimbo (`c_carimbo_*`) fica para o que é carimbo (mural, vitória) |
| `ui_panel` (faixa do HUD da luta, 640x46) | `c_faixa_tela` | `tela_luta.gd` (`hud_band`) | rect **640x49** (46 + fio ink, fio r1 e sombra em dither por cima da arena); nomes `cream` |
| `ui_window` como tela inteira, fundo sem cenário | `c_tela_fundo` (640x360) ou `c_tela_asfalto` (ladrilho) | `tela_criar_discipulo.gd` (atrás da janela); qualquer tela cheia sem cenário | a janela continua `c_janela`; minigames com cenário (`spar_bg`, `flyers_bg`, `ronda_bg`) **não** trocam o cenário |
| `ui_card` (caixas do HUD dos minigames e da luta) | `c_cartao` (já existia, ID2) | `tela_luta.gd`, `tela_treino.gd`, `tela_panfleto.gd`, `tela_ronda.gd` | rect +2 px; texto no segundo jogo |
| `ui_card_dim` | `c_cartao_apagado` | `tela_criar_discipulo.gd` (prévia e caixas de valor) | rect +2 px; texto **`ink`** (antes era claro sobre escuro) |
| `ui_hp_frame` | `c_vida_moldura` | `tela_luta.gd` (`Barra`) | mesmo rect (236x12), mesma área (2 px de margem, 8 de altura) |
| `ui_hp_fill` / `ui_hp_fill_low` / `ui_hp_trail` | `c_vida_cheia` / `c_vida_baixa` / `c_vida_rastro` | idem | 18x8, 9-slice 1/0/1/0 (ladrilho: a hachura tem período 16 = miolo) |
| `ui_portrait_frame` / `_gold` | `c_retrato_moldura` / `c_retrato_moldura_ouro` | `tela_luta.gd`, `janela_previa.gd`, `janela_vitoria.gd`, `janela_fim.gd` | mesmos 36x36, furo 32x32 em (2,2) |
| `ui_mural_portrait_frame` / `_first` | `c_mural_moldura` / `c_mural_moldura_primeiro` | `janela_mural.gd` | mesmos 62x66, furo 56x60 em (3,3) |
| `ui_mural_portrait_bg` | `c_mural_fundo` | `janela_mural.gd` | mesmos 56x60 |
| `ui_map_frame` | `c_mapa_moldura` | `janela_mapa.gd` | 24x24, 9-slice 5, miolo vazio |
| `ui_map_topbar` | `c_mapa_topo` | `janela_mapa.gd` | mesmas margens 1/1/1/2; texto `cream` |
| `ui_map_card` | `c_mapa_ficha` | `janela_mapa.gd` (cartão do nó) | margens **3/3/3/5** (antes 2/2/2/2), rect +2 px; texto passa a **`ink`/`g0`** (antes claro sobre d1) |
| `ui_map_card_next` | `c_mapa_ficha_proxima` | `janela_mapa.gd` | mesmas margens 1/1/1/1; texto `cream` |
| `ui_map_region_label_<rid>` (8 regiões) | `c_mapa_aba_<rid>` | `janela_mapa.gd` | mesmas margens 5/2/2/2, ícone em (5,2), texto em (17,3) passa a **`ink`** |
| `ui_map_price_ok` / `_missing` | `c_mapa_preco_ok` / `c_mapa_preco_falta` | `janela_mapa.gd` | mesmas margens 2/2/2/1; número `p0` (ok) e `g3` (falta) |
| `ui_map_close_normal/hover/pressed` | `c_mapa_fechar_normal/hover/pressed` | `janela_mapa.gd`, `janela_mural.gd` | mesmos 16x16 em (616,7) |
| `ui_map_viewport_edge` | — (fica) | `janela_mapa.gd` | já é fio ink + sombra pontilhada: serve no tema C |
| `ui_honor_chip`, `ui_mural_seal`, barras e marcadores dos minigames (`ui_tug_*`, `ui_breath_*`, `ui_point_pip`, `ui_ronda_*`, `ui_legend_pip`, `ui_warn_*`), faixas `ui_banner_*`, `ui_skip_ring` | — (ficam) | telas de luta e minigames | peças de jogo, não de moldura; ficam para uma passada própria se o dono quiser |

### 6.2 Margens do 9-slice e cores de texto (contraste medido pelo gerador)
| Peça | Tamanho | 9-slice L T R B | Texto | Contraste |
|---|---|---|---|---|
| `c_balao` | 16x16 | 5 5 5 5 | `ink`, topo da maiúscula em by + 5, bloco centrado em w | 11,9:1 |
| `c_balao_rabicho` / `_e` / `_d` | 7x6 | fixo | — | — |
| `c_balao_seta` | 10x4 (2 quadros 5x4) | fixo | — | — |
| `c_balao_placa_red` | 8x10 | 2 2 2 2 | minúsculas `white` (`tag_text_color` = white, como hoje) | 6,4:1 (r1) |
| `c_balao_placa_gold` / `blue` / `green` / `purple` / `gray` | 8x10 | 2 2 2 2 | `ink` | 12,8 / 9,3 / 11,3 / 5,9 / 8,8:1 |
| `c_balao_placa_steel` | 8x10 | 2 2 2 2 | `white` | 8,4:1 (st0) |
| `c_contagem_easy/even/hard` | 16x18 | 5 2 2 4 | linha 1 `ink`, linha 2 `g0` | 11,9:1 e 5,9:1 |
| `c_contagem_today` (corpo r1) | 16x18 | 5 2 2 4 | linha 1 `y2`, linha 2 `cream` | 6,8:1 e 4,8:1 |
| `c_contagem_done` (faixa b1) | 16x18 | 5 2 2 4 | as duas `br1` (cor do dinheiro no claro) | 5,6:1 |
| `c_mudanca`, `c_mudanca_pronto` | 26x22 | 5 5 5 7 | `ink`; preço `br1` | 11,9:1; 5,6:1 |
| `c_mudanca_apagado` | 26x22 | 5 5 5 7 | `ink` nas duas linhas (o `br1` dá 4,1:1 no g3: não usar) | 8,8:1 |
| `c_selo_risco_perigoso` | 68x16 | fixo | (pintado) `cream` + sombra ink | 4,8:1 |
| `c_selo_risco_equilibrado` | 84x16 | fixo | (pintado) `ink` | 12,8:1 |
| `c_selo_risco_facil` | 50x16 | fixo | (pintado) `ink` | 11,3:1 |
| `c_selo_risco_*_base` | 24x16 | 16 3 3 5 | o mesmo do fixo; área do texto = de x 16 até w - 3, face 14 (texto `ycap` = y + 3) | idem |
| `c_tela_fundo` | 640x360 | fixo | — (fundo) | — |
| `c_tela_asfalto` | 16x16 | ladrilho inteiro | `cream` / `g3` por cima | 9,7 / 7,1:1 |
| `c_faixa_tela` | 16x20 | 0 1 0 3 | `cream` (nomes), rótulos `g3` | 9,7:1 |
| `c_vida_moldura` | 16x12 | 2 2 2 2 | — | — |
| `c_vida_cheia` / `_baixa` / `_rastro` | 18x8 | 1 0 1 0 | — | — |
| `c_retrato_moldura` / `_ouro` | 36x36 | fixo | — | — |
| `c_mural_moldura` / `_primeiro` | 62x66 | fixo | — | — |
| `c_mural_fundo` | 56x60 | fixo | — | — |
| `c_mapa_moldura` | 24x24 | 5 5 5 5 (miolo vazio) | — | — |
| `c_mapa_topo` | 16x20 | 1 1 1 2 | `cream`; Legado `p2` | 9,7:1; 4,8:1 |
| `c_mapa_ficha` | 16x18 | 3 3 3 5 | nome `ink`, efeito `g0`, preço `p0` | 11,9 / 5,9 / 7,0:1 |
| `c_mapa_ficha_proxima` | 16x13 | 1 1 1 1 | `cream` | 7,0:1 (p0) |
| `c_mapa_aba_<rid>` | 16x13 | 5 2 2 2 | `ink` | 11,9:1 |
| `c_mapa_preco_ok` | 12x11 | 2 2 2 1 | `p0` | 7,0:1 |
| `c_mapa_preco_falta` | 12x11 | 2 2 2 1 | `g3` (nunca vermelho) | 5,6:1 (d2) |
| `c_mapa_fechar_*` | 16x16 | fixo | (X pintado) | 11,9 / 4,8:1 |
| `c_cartao_apagado` | 12x14 | 2 2 2 4 | `ink` | 8,8:1 |

Cores das faixas das abas do mapa (tiradas das plaquinhas antigas, a cor do anel): garage `g2` (o giz `g3` sumia no papel), gym `gr2`,
boxing `r2`, bjj `b2`, muay_thai `br2`, campaign `y0`, center `b2`, black_cat `b1`. Faixas da placa do calendário: easy `gr2`,
even `y0`, hard `r2`, today `y1` (corpo r1), done `b1`.

### 6.3 Pedidos de código (para o UI/UX; eu não mexi em `ui/`)
1. **Plaquinha do nome:** largura `UiTema.largura_visivel(nome) + 7` em vez de `nome x 6 + 6`. Com a regra antiga, a folga da direita
   variava de 2 a 4 px (as minúsculas têm larguras diferentes); com a nova fica 2/2 em todos os nomes medidos (téo, osmar, james, zé,
   john). A ponta da direita da placa é serrilhada (fita rasgada): a face lida termina em w - 2.
2. **Balão:** o bloco de texto já pode ser centrado no w inteiro (a sombra da direita saiu). Topo da maiúscula continua em by + 5.
3. **Selo de risco:** `selo_risco()` passa a pôr o PNG fixo `c_selo_risco_<nome>` (16 px); para outra palavra, `…_base` em 9-slice
   com o texto centrado na área de x 16 até w - 3. Medido: 5/5 px dos lados e 3/4 em cima/embaixo nos três.
4. **Retângulos que ganham a sombra:** placa do calendário 116x28, cartão da mudança, `c_mapa_ficha`, `c_cartao_apagado` (+2 px);
   faixa do HUD da luta 640x49 (+3, por cima da arena).
5. Depois de aplicar, rodar a skill `alinhamento-ui` como sempre (o verificador é a palavra final no jogo).

## 7. O que é placeholder (precisa de pixel artist)
- **Logo:** ainda é a fonte 5x7 ampliada 5x, em negrito e itálico. O final é um logotipo desenhado à mão (letra de cartaz própria,
  com acentos), no mesmo retângulo (358x40, centro em x 320) para trocar sem mexer no layout.
- **Itens da parede:** desenhos simples por código, de 30 a 64 px. À mão ganhariam papel amassado, tinta de serigrafia falhada, fotos
  com rosto, o couro das luvas com costura, o pano do capuz com volume. Os tamanhos e as posições ficam: cada item é uma PNG.
- **Grão do papel e do asfalto:** fórmula em dither. À mão: fibra de papel, cola de lambe-lambe, asfalto com pedrisco.
- **Faixa entrando:** a ponta é um corte reto com fio de luz; o final pede a ponta rasgada e 2 a 3 quadros a mais.
- A luz da parede é por passos de rampa com borda em dither (certa para pixel art), mas o cone é geométrico.
- **Peças da ID3:** o fundo de tela cheia é asfalto em fórmula com duas faixas geométricas; à mão ganharia faixa de cartaz rasgada,
  marcas de rua de verdade e sujeira. Molduras de retrato e do mural são filetes simples (cabem 2 a 3 px); um artista pode trocar por
  papel de foto com fita, no mesmo tamanho e com o mesmo furo. A serrilha da plaquinha do nome e a orelha da ficha do mapa são o mínimo
  em 1 px. Todas as peças são uma PNG cada, com o tamanho e as margens da §6: troca direta.
