# QA da ID2 (tema C na sala)

Branch `identidade-visual`, sem commit. Testes próprios: `tests/qa_id2_nivel.gd` (mede o contador 0/4) e `tests/qa_id2_montagem.gd` (junta recortes).

## Resumo
| Item | Resultado |
|---|---|
| `tools/run_tests.ps1` (headless, APPDATA temporário) | OK: "TODOS OS TESTES PASSARAM", 0 falhas, guarda do save real OK |
| Mecânica intacta (`foto.gd` HEAD x worktree) | OK: SHA-256 idêntico (`20387E62...110D2C`) |
| `ui_audit --estrito` em `f12` e `garagem_treino` | 0 achados |
| `ui_audit --estrito` em `f54_save_antigo` | 2 achados (`janela_mapa.gd`, tela do mapa = ID3; arquivo não foi tocado na ID2) |
| Olho nas capturas da sala e das faixas | 2 bugs reais da ID2 + 2 menores |
| Veredito | NÃO pronto para PR (B1 e B2) |

## Bugs

### B1 (média): contador "0/4" / "0/5" das MELHORIAS apertado e baixo contraste
- Onde: `ui/painel_loja.gd` linha 463, `UiTema.rotulo(c, "", COL_TEXT_2, 4, 18, 18, CENTER)`. Aparece em `garagem_treino.png` e `f8a2_centro_cheia_mt.png`.
- O que vi (recorte 4x): o texto começa em x=4 do cartão (medido: rótulo 18 px, texto 18 px, sem folga nenhuma), encostado no filete da borda esquerda do cartão e no botão MELHORAR logo abaixo (1 a 2 px). Não passa por cima da borda de verdade, mas está colado nela, como o Produtor viu. O rótulo também fica fora da linha do texto das outras peças (X3: SACO começa em x=26) e o ícone é mais estreito que o contador.
- Contraste: `COL_TEXT_2` = G2 (#8f8890) sobre o cartão D2 (#3d3346) dá 3,46:1, abaixo do 4,5:1 do critério 3.
- Fragilidade: o rótulo tem `autowrap` ligado com largura 18 (o tamanho do texto). Qualquer dígito a mais quebra em 2 linhas (o próprio `size` medido já vem 18x23).
- Por que o verificador não pegou:
  1. O rótulo não declara `ui_align`/`ui_indent`. O `ui_indent=card` só é posto em cartões de altura `ALTURA_CARTAO_LOJA` (painel_loja.gd linha 414); o cartão de melhoria tem 44 px e fica sem a regra.
  2. A regra `CLIPPED` só compara a largura do texto com a do rótulo (18 = 18, passa) e com o pai (dentro, passa).
  3. Não existe regra de folga mínima entre o texto e a borda do cartão, nem entre o texto e o botão vizinho. Um texto que encosta passa.
- Quem corrige: UI/UX corrige a tela (dar folga: rótulo com x >= 8 e largura do texto + 4, sem `autowrap`, e cor com 4,5:1 ou fundo mais escuro sob o contador). Programador corrige a regra do verificador (ver R1).

### B2 (média): selos EQUILIBRADO e FÁCIL ilegíveis no bloco da luta
- Onde: `UiTema.selo_carimbo` (`ui/ui_tema.gd` linha 552). Aparece em `f53_aviso_3_dias.png`, `f53_hud_equilibrado.png`, `f53_hud_facil.png`, `f53_hud_nome_longo.png`.
- O que vi (recorte 2x e 4x): a moldura dupla tracejada tem só 12 px de altura (`c.size = Vector2(w, 12)`), então o traço de baixo e o de cima cortam as letras. O texto aparece escuro e com o contorno por cima ("EQUILIBRADO" vira uma tira riscada; o acento de FÁCIL some). Largura = texto + 11, sem folga lateral. PERIGOSO usa o sprite pronto de 16 px e fica limpo, então a diferença é visível.
- Por que o verificador não pegou: o texto é filho da moldura (`NinePatch`) e cabe nas dimensões dela; não há regra de texto contra o traço da moldura nem de contraste em peça de nine-patch.
- Quem corrige: UI/UX (moldura com 16 px de altura, como o PERIGOSO, ou sprites prontos para FÁCIL/EQUILIBRADO). Programador: regra R2.

### B3 (baixa, já existia antes da ID2): painel F12 fica atrás dos cartazes da parede
- `f12.png`: os sprites da parede (cartaz, folha, quadro, cortiça, x z_index = sort_y) são desenhados por cima do painel DEPURAÇÃO e escondem os botões "+10 DE CADA GERADOR" e "SALVAR". O `DebugOverlay` em `scenes/garagem.tscn` não tem `z_index`. O título "DEPURAÇÃO" também encosta no ícone da foto à esquerda (x=134 do overlay). O verificador deu 0 achados.
- Só aparece em build de debug. Não bloqueia a PR. Quem corrige: UI/UX (`z_index` acima da sala, por exemplo 1900 como a `cena_ui`).

### B4 (baixa): `f54_save_antigo` reprova no `--estrito`
- `IGNORE_SEM_MOTIVO` + `IGNORE_PROIBIDO` em `Fluxo/.../janela_mapa.gd`: um `@Control` com `ui_align=ignore` sem motivo que engole os preços "15", "20", "150" (rótulos de texto fixo). É tela do mapa, escopo da ID3, e a ID2 não mexeu nesse arquivo. Placar de ignore: 12 de 15 (11 com motivo).
- Quem corrige: UI/UX na ID3. Não bloqueia a ID2, mas a ID2 não pode ser dada como "0 problemas em todas as telas".

## Regras novas pedidas para o verificador (Programador)
- R1: texto dinâmico dentro de um cartão (Label sem `ui_align=center`) deve ter pelo menos 4 px de folga até a borda esquerda e direita do cartão e 2 px até o botão vizinho; reprovar com `TXT_COLADO`. Aplicar `ui_indent` por padrão a qualquer cartão `ui_card`, não só ao de altura da loja.
- R2: texto dentro de moldura (`nine_patch`/carimbo) deve caber na área interna da moldura (largura e altura, descontada a borda); acusar `TXT_NA_MOLDURA`.
- R3: contraste mínimo 4,5:1 entre `font_color` e a cor do fundo do cartão para textos que não estão desabilitados (o 0/4 em G2 sobre D2 daria 3,46).

## Checagem a olho (cap_full)
Vistos: sala nos 3 locais (garagem, academia, centro `f8a2_*`), faixas de aviso (1 e 3 dias, nome longo), faixa assistido (`b4_assist_pulso`), balões/dicas de hover (`f6d_balao_loja`, `f6d_balao_melhoria`, `f6d_balao_cantos`), loja (`garagem_loja`), dica de texto fixo (`garagem_dica`), HUD com 12, 8, 5, 4, 3 e 1 dia, campanha completa, `f12`, `f54_save_antigo`, `ronda_contagem` (Ronda mantém o tema antigo: é ID3).
- Faixa de aviso (vermelha) e faixa de baixo (creme) legíveis; números do HUD (TREINO, dinheiro, FAMA/Legado) se leem de imediato nos 3 locais. FRENESI: o texto existe em `data/ui_texts.json`, mas não achei captura dedicada em `cap_full`; fica como lacuna (ver riscos).
- Balões de hover: texto de 3 a 4 px da borda, aceitável. `f6d_balao_cantos`: o balão chega a 2 px da borda direita da tela (clamp correto, mas apertado).
- Sem mistura feia de tema antigo e novo na sala. A tela do mapa e a Ronda seguem no tema antigo, como previsto (ID3).
- Textos desabilitados (MELHORAR cinza, CHAMAR cinza, LUTAR! cinza sobre creme) têm contraste baixo; é "desabilitado", mas o LUTAR! cinza sobre creme fica difícil de ler.

## Riscos
- Critério 3 (contraste 4,5:1 contra o ponto mais claro do cenário) não foi medido por pixel; só estimei os tokens (WHITE/D1 12,98; G2/D2 3,46; G2/D1 4,43, no limite). Recomendo medição automática em ID3.
- Lacunas de captura: FRENESI sem captura dedicada.
- O `f12` só deu 0 achados porque a regra não cobre z-order.

## Veredito
Não está pronto para PR. Mecânica e testes automáticos estão OK (foto idêntica, suíte verde), mas B1 e B2 são defeitos visuais que o verificador deixou passar. Voltam para UI/UX (tela) e Programador (regras R1 a R3). B3 e B4 podem ir para a ID3.
